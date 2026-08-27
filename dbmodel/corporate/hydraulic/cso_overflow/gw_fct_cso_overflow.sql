/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


CREATE OR REPLACE FUNCTION gw_fct_cso_calculation(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*
--modo calculo
SELECT ud.gw_fct_cso_calculation($${"client":{"device":4, "lang":"es_ES", "epsg":25830}, "form":{}, "feature":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{"exploitation":"19","drainzoneId":null,
"calculation":{"active":"true", "sourceTables":"CSO", "mode":"EXECUTION"}, 
"dscenario":{"active":"false"}}}}$$);

--modo calibración
SELECT ud.gw_fct_cso_calculation($${"client":{"device":4, "lang":"es_ES", "epsg":25830}, "form":{}, "feature":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{"exploitation":"19","drainzoneId":null,
"calculation":{"active":"true", "sourceTables":"CSO", "mode":"CALIBRATION"}, 
"dscenario":{"active":"false"}}}}$$);

--modo escenario
SELECT ud.gw_fct_cso_calculation($${"client":{"device":4, "lang":"es_ES", "epsg":25830}, "form":{}, "feature":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{"exploitation":"19","drainzoneId":null, 
"calculation":{"active":"true", "sourceTables":"CSO", "mode":"EXECUTION"},
"dscenario":{"active":"true", "inflowsDscenarioRootName": "M6_CSO"}}}}$$);

-- modo cfactor
SELECT ud.gw_fct_cso_calculation($${"client":{"device":4, "lang":"es_ES", "epsg":25830}, "form":{}, "feature":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{"exploitation":"16","drainzoneId":543833,
"calculation":{"updateInventory":false, "active":"true", "sourceTables":"CSO", "mode":"EXECUTION"}, "dscenario":{"active":"false"}}}}$$);


-- ver resultados

select * from cso_out_vol where rf_name like 'M1%'

select * from temp_cso_inp_rainfall

*/

DECLARE
rec_rainfall record;
rec_drainzone record;
rec record;

v_returncoeff numeric;
v_daily_supply numeric;

i integer = 0;

v_count integer;
v_sql text;

v_tstep numeric;

v_expl_id integer;

v_drainzone_id text;
v_drainzone_array text;

v_filter_macroexpl text;
v_filter_drainzone TEXT;

v_timeseries_list TEXT;
v_inflows_dscenario TEXT;
v_sourcetables TEXT; -- CSO / SWMM

v_dscenario_id integer;
v_dwfscenario_id integer;

v_non_leaked_vol NUMERIC = 0; --
v_leaked_vol NUMERIC = 0; -- volum que sobresurt

v_cur_vol NUMERIC; -- volum actual de l'arqueta
v_last_vol NUMERIC; --volum del pas anterior
v_delta_vol NUMERIC;

v_vol_circ NUMERIC;
v_vol_circ_dep NUMERIC;
v_vol_max_epi NUMERIC;

-- return
v_version TEXT;
v_result JSON;
v_result_info JSON;
v_result_polygon JSON;

v_calib_imperv_area NUMERIC = 0;

v_mode TEXT;
v_filtercal TEXT;
v_residual_pattern NUMERIC = 0;

v_i integer;

v_test TEXT;
v_step_calculation boolean;
v_step_dscenario boolean;
v_macroexpl text;
v_pd80 NUMERIC;
v_update_inventory boolean = FALSE;


BEGIN
	
	SET search_path = "ud", public;

	-- input params
	v_step_calculation := p_data -> 'data' -> 'parameters' -> 'calculation' ->> 'active';
	v_tstep = 10; -- tstep of the timeseries (every 10 mins, 5 mins., etc.)
	v_expl_id := (((p_data ->>'data')::json->>'parameters')::json->>'exploitation')::integer;
	v_drainzone_id := (((p_data ->>'data')::json->>'parameters')::json->>'drainzoneId')::text;
	v_mode:= (p_data ->'data'->'parameters'->'calculation'->>'mode')::text;
	v_sourcetables:= (((p_data ->>'data')::json->>'parameters')::json->>'sourceTables')::text;
	v_update_inventory:= (p_data ->'data'->'parameters'->'calculation'->>'updateInventory')::boolean;

	
	v_step_dscenario := (p_data -> 'data' -> 'parameters' -> 'dscenario' ->> 'active')::boolean;
	v_inflows_dscenario := (p_data ->'data'-> 'parameters' -> 'dscenario' ->> 'inflowsDscenarioRootName')::text;


	-- config variables
	--v_returncoeff = (select value::numeric from config_param_system where "parameter" = 'cso_returncoeff');
	--v_daily_supply = (select value::numeric from config_param_system where "parameter" = 'cso_daily_supply');
	SELECT giswater INTO v_version FROM sys_version ORDER BY id ASC LIMIT 1;

	select concat('M', macroexpl_id) INTO v_macroexpl from exploitation e where expl_id = v_expl_id LIMIT 1;
	
	RAISE NOTICE 'v_drainzone_id %', v_drainzone_id;

	-- filter drainzones
	IF v_drainzone_id IS NOT NULL OR v_drainzone_id !='' THEN
		v_filter_drainzone = 'AND b.drainzone_id IN ('||v_drainzone_id||')';
	ELSE
		v_filter_drainzone = 'AND b.expl_id IN ('||v_expl_id||')';
	END IF;

	RAISE NOTICE 'v_filter_drainzone %', v_filter_drainzone;

	-- get the drainzones of execution according to CURRENT WORKSPACE!
	v_sql = '
	SELECT a.node_id, b.drainzone_id FROM cso_inp_weir a 
	LEFT JOIN drainzone b ON graphconfig->''use''->0->>''nodeParent'' = a.node_id
	WHERE b.drainzone_id IS NOT NULL '||v_filter_drainzone||'';

	RAISE NOTICE 'v_sql %', v_sql;


	EXECUTE 'SELECT count(*) from ('||v_sql||')a' INTO v_count;


	IF v_count = 0 THEN
		return '{"status": "Failed", "message":{"level":1, "text":"No drainzones match with selected expl and/or drainzone"}}'::json;
	ELSE
		EXECUTE 'SELECT string_agg(drainzone_id::text, '', '') FROM ('||v_sql||')a' INTO v_drainzone_array;
	END IF;

	RAISE notice 'Drainzones array: %', v_drainzone_array;

	RAISE notice 'v_sql array: %', v_sql;

	
	-- RAINFALL (from active timeseries from inp_timeseries_value)
	-- =========================================================================
	DROP TABLE IF EXISTS temp_cso_inp_rainfall;

	IF v_mode ='EXECUTION' THEN
	
		CREATE TEMP table temp_cso_inp_rainfall as
		select timser_id as rf_name, 60*v_tstep as rf_length, value as rf_volume, (value*6)::numeric as rf_intensity, "time" as rf_tstep,
		COALESCE ((b.addparam->>'cFactor')::numeric,1) AS c_factor
		from inp_timeseries_value a 
		JOIN inp_timeseries b ON a.timser_id = b.id
		WHERE timser_type = 'Rainfall' AND active AND (addparam IS NULL OR (b.addparam->>'cFactor')::float>0) AND expl_id = v_expl_id ORDER BY 1, 5;
	
		v_filtercal = ' AND c.addparam is null OR (c.addparam->>''cFactor'')::float >0';
		
	ELSIF v_mode = 'CALIBRATION' THEN
	
		create TEMP table temp_cso_inp_rainfall as
		select timser_id as rf_name, 60*v_tstep as rf_length, value as rf_volume, (value*6)::numeric as rf_intensity, "time" as rf_tstep
		from inp_timeseries_value a 
		JOIN inp_timeseries b ON a.timser_id = b.id
		WHERE timser_type = 'Rainfall' AND active AND addparam->>'mode'='CALIBRATION' AND expl_id = v_expl_id ORDER BY 1, 5;
	
		v_filtercal = ' AND c.addparam->>''mode''=''CALIBRATION''';
	
	ELSE
		return '{"status": "Failed", "message":{"level":1, "text":"It is mandatory to select a MODE"}}'::json;
	END IF;
	
	IF (SELECT EXISTS(SELECT 1 FROM temp_cso_inp_rainfall)) IS FALSE THEN
		return '{"status": "Failed", "message":{"level":1, "text":"La expl seleccioanda no tiene lluvias en la inp_timeseries"}}'::json;
	END IF;

	if (select count(*) from temp_cso_inp_rainfall) = 0 then
		raise exception 'no tienes lluvias en la temp_cso_inp_rainfall';
	end if;

	IF v_step_calculation THEN -- INIT CALCULATION PROCESS
		
		-- reset all
		execute 'delete from cso_inp_system_subc where drainzone_id in ('||v_drainzone_array||')';
	
		-- ud data: drainzones, outfalls and its specific features (vret, etc.)
		EXECUTE '
		insert into cso_inp_system_subc (node_id, drainzone_id)
		select node_id, drainzone_id FROM ('||v_sql||')
		on conflict (node_id) do nothing';
	
		IF v_sourcetables = 'CSO' OR v_sourcetables IS NULL THEN
	
			-- PREPARE DATA: water consumption from connecs grouped by dwf thyssen triangles 
			-- ===================================================
			FOR rec IN EXECUTE 'SELECT drainzone_id FROM drainzone WHERE drainzone_id in ('||v_drainzone_array||')'
			LOOP -- INTERSECT w/ connecs FOR EACH selected drainzone TO gain performance
		
				EXECUTE 'UPDATE cso_subc_dwf_all t SET consumption = a.su FROM (
					SELECT c.id, sum(consumo) AS su FROM ws.man_connec_acometida a
					LEFT JOIN ws.connec b USING (connec_id)
					LEFT JOIN cso_subc_dwf_all c ON st_intersects(c.the_geom, b.the_geom)
					WHERE consumo IS NOT NULL AND drainzone_id = '||rec.drainzone_id||'
					GROUP BY id
				)a WHERE t.id = a.id';
			
			END LOOP;
		
			-- update drainzone_id for each dwf triangle taking the drainzone of the triangle's source node_id	
			EXECUTE '
			UPDATE cso_subc_dwf_all t SET drainzone_id = a.drainzone_id FROM (
				SELECT a.id, b.drainzone_id
				FROM cso_subc_dwf_all a
				LEFT JOIN node b USING (node_id)
				WHERE (a.drainzone_id > 0 OR b.drainzone_id >0) 
				AND a.drainzone_id<>b.drainzone_id AND b.drainzone_id > 0 
				AND b.drainzone_id in ('||v_drainzone_array||')
			)a WHERE t.id = a.id;
			';
		
			EXECUTE '
			UPDATE cso_subc_wwf_all t SET drainzone_id = a.drainzone_id FROM (
			SELECT a.id, b.drainzone_id
				FROM cso_subc_wwf_all a
				LEFT JOIN node b USING (node_id)
				WHERE (a.drainzone_id > 0 OR b.drainzone_id >0) 
				AND a.drainzone_id<>b.drainzone_id AND b.drainzone_id > 0 
				AND b.drainzone_id in ('||v_drainzone_array||')
			)a where t.id = a.id';
			
			-- INITIAL DATA: ud NETWORK DATA (cso_inp_system_subc)
			-- ===============================================================================================
			
			EXECUTE '
			update cso_inp_system_subc t set q_max = a.qmax, vret = a.vmax, 
			muni_name = a.muni_name, expl_name = a.expl_name, macroexpl_name = a.macroexpl_name from (
				SELECT a.node_id, a.qmax, a.vmax,
				concat(m.muni_id, '' - '', m.name) AS muni_name,
				concat(e.expl_id, '' - '', e.name) AS expl_name,
				concat(me.macroexpl_id, '' - '', me.name) AS macroexpl_name
				FROM cso_inp_weir a
				JOIN drainzone c ON a.node_id = c.graphconfig::json ->''use''->0 ->>''nodeParent''
				JOIN node b USING (node_id)
				LEFT JOIN ext_municipality m USING (muni_id)
				LEFT JOIN exploitation e ON e.expl_id = b.expl_id
				LEFT JOIN macroexploitation me ON e.macroexpl_id = me.macroexpl_id			
				WHERE b.drainzone_id IN ('||v_drainzone_array||')
			)a where t.node_id = a.node_id 
			';
			
			-- imperv area 
			execute '
			update cso_inp_system_subc t set imperv_area = a.imperv, thyssen_plv_area = a.area_thy, mean_coef_runoff = a.c_val from (
				SELECT drainzone_id, sum(st_area(the_geom) * c_value) as imperv, sum(st_area(the_geom)) as area_thy, sum(st_area(the_geom) * c_value)/sum(st_area(the_geom)) as c_val
				FROM cso_subc_wwf_all group by drainzone_id
			)a where t.drainzone_id = a.drainzone_id and t.drainzone_id in ('||v_drainzone_array||');
			';
			
			-- sum of demand (L/s) from sewage thyssen group by drainzone 
			execute '
			update cso_inp_system_subc s set demand = a.consumo from (
			select drainzone_id, sum(consumption*coalesce(c_calibra,1)) as consumo from cso_subc_dwf_all cntr
			where drainzone_id is not null
			group by drainzone_id)a 
			where s.drainzone_id = a.drainzone_id and s.drainzone_id in ('||v_drainzone_array||')';
	
			EXECUTE '
			UPDATE cso_inp_system_subc set lastupdate_process = ''CSO'' WHERE drainzone_id in ('||v_drainzone_array||')	';

		ELSIF v_sourcetables = 'SWMM' THEN
	
			/*
		
			-- INP_DWF: create a dwfscenario if not exists
			IF (SELECT EXISTS (SELECT idval FROM cat_dwf_scenario WHERE expl_id = v_expl_id)) IS NOT TRUE THEN
	
				INSERT INTO cat_dwf_scenario (idval, expl_id) 
				SELECT concat('PIGSS ', b.name), v_expl_id FROM exploitation a 
				JOIN macroexploitation b USING (macroexpl_id) 
				WHERE a.expl_id = v_expl_id
				RETURNING id INTO v_dwfscenario_id;
		
			END IF;
			
				-- take the data from inp tables and prepare it
			/* needed data:
			 inp_subcatchment (outlet_id*, imperv, curveno, the_geom). *ONLY the outlets that are NODES are going to be taken!
			 inp_dwf (node_id, value, dwfscenario_id)
			 cso_inp_weir (node_id, qmax, vmax)
			 node (node_id, drainzone_id)
			 
			 */
			v_sql = '
			WITH sums AS (
				SELECT 
				n.drainzone_id,
				sum(st_area(the_geom)) AS thyssen_plv_area,
				avg(a.imperv) AS imperv_area,
				avg(a.curveno) AS mean_coef_runof,
				sum(e.value) AS demand
				FROM inp_subcatchment a
				LEFT JOIN node n ON a.outlet_id = n.node_id::text
				LEFT JOIN drainzone b ON b.drainzone_id = n.drainzone_id
				LEFT JOIN inp_dwf e ON a.outlet_id = e.node_id::TEXT
				WHERE e.dwfscenario_id = '||v_dwfscenario_id||'
				GROUP BY n.drainzone_id
			), aliv AS (
				SELECT 
				a.node_id, 
				b.drainzone_id,
				a.qmax AS q_max,
				a.vmax AS vret
				FROM cso_inp_weir a
				LEFT JOIN node b ON a.node_id = b.node_id::TEXT
			)
			SELECT
			aliv.node_id,
			aliv.q_max,
			aliv.vret,
			sums.*
			FROM sums LEFT JOIN aliv USING (drainzone_id)
			WHERE drainzone_id in ('||v_drainzone_array||')	';
		
			-- update cso_inp_system_subc with inp_data
			EXECUTE '
			UPDATE cso_inp_system_subc t SET 
			q_max = a.q_max, 
			vret = a.vret,
			imperv_area = a.imperv_area,
			thyssen_plv_area = a.thyssen_plv_area,
			mean_coef_runoff = a.mean_coef_runoff,
			demand = a.demand 
			FROM ('||v_sql||')a 
			WHERE t.drainzone_id = a.drainzone_id AND a.drainzone_id IN ('||v_drainzone_array||')';
		
			EXECUTE '
			UPDATE cso_inp_system_subc set lastupdate_process = ''SWMM'' WHERE drainzone_id in ('||v_drainzone_array||')';
			
			*/
		
		END IF;

		-- set constant value of RD 665/2023
		EXECUTE 'update cso_inp_system_subc set kb = 1.13 WHERE drainzone_id in ('||v_drainzone_array||')';
	
		-- vret_imperv
		EXECUTE 'update cso_inp_system_subc set vret_imperv = vret/imperv_area where drainzone_id in ('||v_drainzone_array||')';
	
		-- set active drainzones
		EXECUTE 'update cso_inp_system_subc set active = true AND drainzone_id in ('||v_drainzone_array||')';
		
		-- set null to 0
		EXECUTE 'update cso_inp_system_subc set thyssen_plv_area = 1 where thyssen_plv_area is NULL AND drainzone_id in ('||v_drainzone_array||')';
		EXECUTE 'update cso_inp_system_subc set imperv_area = 1 where imperv_area is NULL AND drainzone_id in ('||v_drainzone_array||')';
		EXECUTE 'update cso_inp_system_subc set mean_coef_runoff = 1 where mean_coef_runoff is NULL AND drainzone_id in ('||v_drainzone_array||')';
		EXECUTE 'update cso_inp_system_subc set demand = 0 where demand is NULL AND drainzone_id in ('||v_drainzone_array||')';
		EXECUTE 'update cso_inp_system_subc set vret_imperv = 0 where vret_imperv is NULL AND drainzone_id in ('||v_drainzone_array||')';
		EXECUTE 'update cso_inp_system_subc set q_max = 0 where q_max is NULL AND drainzone_id in ('||v_drainzone_array||')';
		EXECUTE 'update cso_inp_system_subc set vret = 0 where vret is NULL AND drainzone_id in ('||v_drainzone_array||')';
		EXECUTE 'update cso_inp_system_subc set eq_inhab = 0 where eq_inhab is NULL AND drainzone_id in ('||v_drainzone_array||')';
	
		-- START ALGORITHM
		-- ===============
	
		v_timeseries_list = coalesce(v_timeseries_list, '');
		v_drainzone_array = coalesce(v_drainzone_array, '');
	
		-- reset values
		EXECUTE 'DELETE FROM cso_out_vol where drainzone_id in ('||v_drainzone_array||')';
	
		-- Insert ALL values of the selected drainzone + its rainfall
		v_sql = '
		INSERT INTO cso_out_vol (drainzone_id, node_id, rf_name, rf_tstep, rf_volume, rf_intensity)
		SELECT a.drainzone_id, (a.graphconfig::json ->''use''->0 ->>''nodeParent'')::text as node_id, 
		b.timser_id AS rf_name, b."time" AS rf_tstep, b.value as rf_volume, (b.value*6)::numeric as rf_intensity
		FROM drainzone a 
		JOIN inp_timeseries c USING (expl_id)
		JOIN inp_timeseries_value b ON b.timser_id = c.id
		WHERE c.timser_type = ''Rainfall'' AND a.drainzone_id in ('||v_drainzone_array||') '||v_filtercal||' ORDER BY 1, 3, 4 
		ON CONFLICT (drainzone_id, rf_name, rf_tstep) DO NOTHING;
		';
	
		EXECUTE v_sql;
	
		-- for each subcatchment
		FOR rec_drainzone in execute 'select * from cso_inp_system_subc where drainzone_id in ('||v_drainzone_array||') 
		and thyssen_plv_area is not null'
		LOOP
						
			v_last_vol = 0;
			v_cur_vol = 0;
			v_calib_imperv_area = (SELECT calib_imperv_area FROM cso_calibration WHERE drainzone_id = rec_drainzone.drainzone_id);
			
			RAISE NOTICE 'rec_drainzone.kb % rec_drainzone.thyssen_plv_area %', rec_drainzone.kb ,  rec_drainzone.thyssen_plv_area;
			
			-- for each rainfall that have volume:
			FOR rec_rainfall in EXECUTE 'select *, (LEFT(rf_tstep,2)::integer +1)::INTEGER AS hourly from temp_cso_inp_rainfall order by rf_name, rf_tstep'
			LOOP
				
				i = i+1;
				
				RAISE NOTICE '-------------> rainfall: %  - drainzone: % - macroexpl: %   (%) ', rec_rainfall, rec_drainzone.drainzone_id, rec_drainzone.macroexpl_name, i;
									
				EXECUTE 'SELECT factor_'||rec_rainfall.hourly||' FROM inp_pattern_value JOIN inp_pattern USING (pattern_id) WHERE expl_id = '||v_expl_id
				INTO v_residual_pattern;
				
				-- fill table cso_out_vol
				update cso_out_vol
					set 
					vol_residual = round((coalesce(rec_drainzone.demand,1) * 1 *  rec_rainfall.rf_length*v_residual_pattern / 1000)::NUMERIC,3),
					vol_max_epi = round((rec_drainzone.q_max * rec_rainfall.rf_length / 1000)::NUMERIC,3),
					vol_rainfall = round((1000 * rec_drainzone.kb * rec_rainfall.c_factor * rec_rainfall.rf_volume * rec_drainzone.thyssen_plv_area/(1000*1000))::NUMERIC,3)
					where node_id = rec_drainzone.node_id and rf_name = rec_rainfall.rf_name and rf_tstep=rec_rainfall.rf_tstep;
								
				IF v_calib_imperv_area > 0 THEN				
					update cso_out_vol
					set vol_total = round((vol_residual + vol_rainfall)::NUMERIC, 3),
					vol_runoff = round((vol_rainfall * v_calib_imperv_area / rec_drainzone.thyssen_plv_area)::NUMERIC, 3)
					where node_id = rec_drainzone.node_id and rf_name = rec_rainfall.rf_name and rf_tstep=rec_rainfall.rf_tstep;
				ELSE 
					update cso_out_vol
					set vol_total = round((vol_residual + vol_rainfall)::NUMERIC, 3),
					vol_runoff = round((vol_rainfall * rec_drainzone.imperv_area / rec_drainzone.thyssen_plv_area)::NUMERIC, 3)
					where node_id = rec_drainzone.node_id and rf_name = rec_rainfall.rf_name and rf_tstep=rec_rainfall.rf_tstep;		
				END IF;
						
				update cso_out_vol
					set vol_infiltr = round((vol_rainfall - vol_runoff )::NUMERIC, 3),
					vol_circ = round((vol_runoff + vol_residual)::NUMERIC, 3)
					where node_id = rec_drainzone.node_id and rf_name = rec_rainfall.rf_name and rf_tstep=rec_rainfall.rf_tstep; 
												
				-- take into account accumulated volume in dep							
				SELECT vol_circ, vol_max_epi, (vol_circ - vol_max_epi) 
				INTO v_vol_circ, v_vol_max_epi, v_delta_vol
				FROM cso_out_vol where node_id = rec_drainzone.node_id and rf_name = rec_rainfall.rf_name and rf_tstep=rec_rainfall.rf_tstep; 
			
				--RAISE NOTICE 'circ: %, maxQ: %, maxV: %, delta: % ', v_vol_circ, v_vol_max_epi, rec_drainzone.vret, v_delta_vol;
			
				v_cur_vol = GREATEST(v_delta_vol + v_last_vol, 0);		
				
			
				IF v_cur_vol < rec_drainzone.vret THEN
				
					IF v_last_vol = 0 THEN
						v_non_leaked_vol = v_vol_circ;
					ELSE 
						
						v_non_leaked_vol = least((v_last_vol + v_vol_circ),v_vol_max_epi);
					END IF;
				
					IF v_vol_circ > v_vol_max_epi THEN
						v_non_leaked_vol = v_vol_max_epi;
					END IF;
					v_leaked_vol = 0;
				
				elsif v_cur_vol > rec_drainzone.vret THEN
					v_leaked_vol = v_cur_vol - rec_drainzone.vret;
					v_non_leaked_vol = v_vol_max_epi;
					v_cur_vol = rec_drainzone.vret;
					
				end if;	
							
				update cso_out_vol set 
					vol_circ_red = round((v_vol_circ -(v_cur_vol-v_last_vol))::numeric,3),
					vol_circ_dep = round(v_cur_vol::numeric,3),
					vol_non_leaked = round(v_non_leaked_vol::numeric,3),
					vol_leaked = round(v_leaked_vol::numeric,3),
					vol_wwtp = round(v_non_leaked_vol::NUMERIC,3),
					vol_treated = round((vol_infiltr + v_non_leaked_vol)::NUMERIC, 3)
				where node_id = rec_drainzone.node_id and rf_name = rec_rainfall.rf_name and rf_tstep=rec_rainfall.rf_tstep;	
								
				--RAISE NOTICE 'curVol: %, lastVol: %, leak: %, nonLeak: %',  v_cur_vol, v_last_vol, v_leaked_vol, v_non_leaked_vol;
			
				v_last_vol = v_cur_vol;
			END LOOP;
		
			v_calib_imperv_area = 0;
		
		END LOOP;
	
		EXECUTE 'UPDATE cso_out_vol SET lastupdate = now() WHERE drainzone_id IN ('||v_drainzone_array||')';

	END IF; -- FINISH CALCULATION PROCESS
	
	IF v_step_dscenario THEN 

		IF NULLIF(TRIM(v_inflows_dscenario), '') IS NOT NULL THEN -- CREATE inflow dscenario
	
					
			-- delete previous timeseries values. We keep values on inp_timeseries if exists and on inp_dscenario_inflows
			EXECUTE 'DELETE FROM inp_timeseries_value WHERE timser_id in (
				SELECT concat(rf_name, ''_'', node_id)
				FROM cso_out_vol WHERE drainzone_id in ('||v_drainzone_array||')
			)';
			
			-- insert values in inp_timeseries_(value)
			execute '
			INSERT INTO inp_timeseries (id, timser_type, times_type, idval, expl_id, log)
			WITH mec AS (
				SELECT node_id, concat(rf_name, ''_'', node_id) AS lluvia
				FROM cso_out_vol where drainzone_id in ('||v_drainzone_array||')
			)
			SELECT DISTINCT lluvia, ''Inflow_Hydrograph'' AS timser_type, ''RELATIVE'' AS times_type, lluvia AS idval, '||v_expl_id||', ''Created by CSO ALGORTHIM''
			FROM mec
			ON CONFLICT DO NOTHING
			';
			
			-- insert values of inflows into inp_timeseries_values (vol_non_leaked is in m3/10 min and we pass it to m3/s)
			EXECUTE '
			INSERT INTO inp_timeseries_value (timser_id, time, value)
			SELECT concat(rf_name, ''_'', node_id) AS lluvia, rf_tstep, (vol_non_leaked/(60*'||v_tstep||'))
			FROM cso_out_vol WHERE drainzone_id in ('||v_drainzone_array||')
			order by concat(rf_name, ''_'', node_id), to_timestamp(rf_tstep, ''HH24:MI'')
			';
			
			UPDATE inp_timeseries_value SET value=0 WHERE value IS null;
			
			-- create an 10 inflows dscenario for 10 rainfall episodes if not exists
			INSERT INTO cat_dscenario ("name", dscenario_type, expl_id) 
			SELECT concat(v_inflows_dscenario, '_EP', to_char(n, 'FM00')), 'INFLOWS', v_expl_id::integer
			FROM generate_series(1, 10) AS n
			ON CONFLICT DO NOTHING;
			
			execute 'INSERT INTO inp_dscenario_inflows (dscenario_id, node_id, order_id, timser_id, sfactor, base, active)
			SELECT DISTINCT b.dscenario_id, a.node_id, substring(split_part(rf_name, ''_'', 2) from ''[0-9]+'')::int AS order_id,
			concat(rf_name, ''_'', node_id) AS timser_id, 1 AS sfactor, 0 AS base, TRUE
			FROM cso_out_vol a
			LEFT JOIN cat_dscenario b ON split_part(a.rf_name, ''_'', -1) = split_part(b.name, ''_'', -1)
			WHERE drainzone_id IN ('||v_drainzone_array||')
			and b.expl_id = '||v_expl_id||' and rf_name ilike ''%'||v_macroexpl||'%''
			ON CONFLICT (dscenario_id, node_id, order_id) DO NOTHING
			';
			
		END IF;

	END IF; -- FINISH DSENARIO INFLOWS

	-- update inventory fields with the results
	IF v_update_inventory THEN
	
		SELECT pd80 INTO v_pd80 FROM cso_inp_wwtp JOIN node USING (node_id) WHERE expl_id = v_expl_id;

		FOR rec in select * from cso_rpt_object WHERE column_id IS NOT NULL AND parameter_id IS NOT null-- table of mapping between algorithm and inventory addfields
		LOOP
		 	EXECUTE '
		 	UPDATE man_node_'||lower(rec.featurecat_id)||' t SET '||rec.column_id||' = a.'||rec.parameter_id||' FROM (
			 	SELECT a.outfall_id, a.efficiency, b.qmax, b.vmax as vret, round(a.vol_dwf/(3600*24*10), 4) as vol_dwf, '||v_pd80||' as pd80 FROM v_cso_drainzone a
				LEFT JOIN cso_inp_weir b ON a.outfall_id = b.node_id where a.expl_id = '||v_expl_id||'
		 	)a WHERE t.node_id = a.outfall_id';
		END LOOP;

		UPDATE drainzone t SET addparam = a.new_addparam FROM (
		WITH mec AS (
			SELECT drainzone_id, round(thyssen_plv_area, 2) AS thyssen_plv_area, addparam 
				FROM cso_inp_system_subc ciss 
				JOIN drainzone USING (drainzone_id)
				JOIN v_cso_drainzone USING (drainzone_id)
		)
		SELECT drainzone_id,
		jsonb_set(COALESCE(addparam, '{}')::jsonb, '{areaTotal}', to_jsonb(thyssen_plv_area), TRUE) AS new_addparam
		FROM mec
		)a WHERE t.drainzone_id = a.drainzone_id;

		-- areaImperv (imperv_area.v_cso_drainzone)
		UPDATE drainzone t SET addparam = a.new_addparam FROM (
		SELECT drainzone_id,
		jsonb_set(COALESCE(addparam, '{}')::jsonb, '{areaImperv}', to_jsonb(round(cso_inp_system_subc.imperv_area, 2)), true) AS new_addparam
		FROM drainzone
		JOIN cso_inp_system_subc USING (drainzone_id)
		JOIN v_cso_drainzone USING (drainzone_id)
		)a WHERE t.drainzone_id = a.drainzone_id;
	
		-- kmlength
		UPDATE drainzone t SET addparam = a.new_addparam FROM (
			WITH mec AS (
			SELECT drainzone_id, round(sum(st_length(arc.the_geom))::numeric, 2) AS sum_len
			FROM arc
			WHERE drainzone_id IS NOT NULL AND state=1
			GROUP BY drainzone_id
		)
		SELECT mec.drainzone_id, jsonb_set(COALESCE(addparam, '{}')::jsonb, '{kmLength}', to_jsonb(sum_len), TRUE) AS new_addparam FROM mec 
		LEFT JOIN drainzone USING (drainzone_id)
		JOIN v_cso_drainzone USING (drainzone_id)
		)a WHERE t.drainzone_id = a.drainzone_id;
	
		-- connec number
		UPDATE drainzone t SET addparam = a.new_addparam FROM (
		WITH mec AS (
			SELECT drainzone_id, count(*) AS n_connec FROM connec WHERE state=1 GROUP BY drainzone_id
		)
		SELECT mec.drainzone_id, 
		jsonb_set(COALESCE(addparam, '{}')::jsonb, '{connecNumber}', to_jsonb(n_connec), TRUE) AS new_addparam
		FROM mec
		JOIN drainzone USING (drainzone_id)
		JOIN v_cso_drainzone USING (drainzone_id)
		)a WHERE t.drainzone_id = a.drainzone_id;
	
		-- factor calibrado de escorrentía (calib_runoffc.v_cso_drainzone)
		UPDATE drainzone t SET addparam = a.new_addparam FROM (
		WITH mec AS (
		SELECT drainzone_id, 
		 CASE
		    WHEN cc.calib_imperv_area IS NOT NULL THEN (cc.calib_imperv_area / cso.thyssen_plv_area)::numeric(12,3)
		    ELSE cso.mean_coef_runoff::numeric(12,3)
		END AS calib_runoffc,
		addparam
		FROM cso_inp_system_subc cso
		LEFT JOIN cso_calibration cc USING (drainzone_id)
		JOIN drainzone USING (drainzone_id)
		JOIN v_cso_drainzone USING (drainzone_id)
		)
		SELECT drainzone_id,
		jsonb_set(COALESCE(addparam, '{}')::jsonb, '{calibrRunoff}', to_jsonb(calib_runoffc), TRUE) AS new_addparam
		FROM mec
		)a WHERE t.drainzone_id = a.drainzone_id;
	
		-- caudal residual que llega a ese punto, en % (dwf_pd80_percent.v_cso_drainzone)
		UPDATE drainzone t SET addparam = a.new_addparam FROM (
		WITH mec AS (
			SELECT drainzone_id,
				CASE
		            WHEN sum(cov.vol_residual) > sum(cov.vol_runoff) THEN 100::numeric
		            ELSE (sum(cov.vol_residual) / sum(cov.vol_runoff) * 100::numeric)::numeric
		        END AS dwf_p80_percent
		        FROM cso_out_vol cov 
				WHERE vol_residual IS NOT null
				GROUP BY drainzone_id
			)
			SELECT mec.drainzone_id,
		jsonb_set(COALESCE(addparam, '{}')::jsonb, '{dwfFlow}', to_jsonb(round(mec.dwf_p80_percent, 2)), TRUE) AS new_addparam
		FROM mec 
		JOIN drainzone USING (drainzone_id)
		JOIN v_cso_drainzone USING (drainzone_id)
		)a WHERE t.drainzone_id = a.drainzone_id;

		-- caudal residual que sale por el aliviadero en L/s (vol_res/(3600*24*10))
 		UPDATE drainzone t SET addparam = a.new_addparam FROM (
			WITH mec AS (
			 SELECT drainzone_id, round(vol_dwf/(3600*24*10), 4) AS dwf_avg FROM v_cso_drainzone WHERE expl_id = v_expl_id
			 )
		SELECT mec.drainzone_id, jsonb_set(COALESCE(addparam, '{}')::jsonb, '{dwfAvg}', to_jsonb(dwf_avg), TRUE) AS new_addparam FROM mec 
		JOIN drainzone USING (drainzone_id)
		JOIN v_cso_drainzone USING (drainzone_id)
		)a WHERE t.drainzone_id = a.drainzone_id;
	
		--pd80
	 	UPDATE drainzone t SET addparam = a.new_addparam FROM (
	 	WITH mec AS (
			 SELECT drainzone_id, v_pd80 AS pd80 FROM v_cso_drainzone WHERE expl_id = v_expl_id
		)
		SELECT mec.drainzone_id, jsonb_set(COALESCE(addparam, '{}')::jsonb, '{pd80}', to_jsonb(pd80), TRUE) AS new_addparam 
		FROM mec 
		JOIN drainzone USING (drainzone_id)
		JOIN v_cso_drainzone USING (drainzone_id)
		)a WHERE t.drainzone_id = a.drainzone_id;
	
	END IF;
	
	DELETE FROM audit_check_data WHERE fid = 990 AND cur_user = current_user;

	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 1, '------------------------', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 1, ' CSO CALCULATION   ', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 1, '------------------------', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 1, '', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 1, '', current_user;


	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 2, 'CALCULATED DRAINZONES ', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 2, '--------------------------------', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 2, drainzone_id, current_user FROM cso_out_vol WHERE lastupdate=now();
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 2, '', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 2, '', current_user;

	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 3, 'RAINFALLS USED', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 3, '-----------------------', current_user;
	INSERT INTO audit_check_data (fid, criticity, error_message, cur_user) SELECT DISTINCT 990, 3, rf_name, current_user FROM temp_cso_inp_rainfall ORDER BY rf_name;


	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result 
	FROM (SELECT error_message AS message FROM audit_check_data WHERE fid = 990 AND cur_user = current_user ORDER BY criticity asc) row;
	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"geometryType":"", "values":',v_result, '}');

  	--polygon;
	  	SELECT jsonb_agg(features.feature) INTO v_result
	  	FROM (
		    SELECT jsonb_build_object(
		    'type',       'Feature',
		    'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
		    'properties', to_jsonb(row) - 'the_geom'
		    ) AS feature
		    FROM (SELECT drainzone_id AS id, drainzone, NULL AS descript, expl_id, efficiency, the_geom FROM v_cso_drainzone) 
	   	row) features;
	
	  v_result := COALESCE(v_result, '{}'); 
	  v_result_polygon = concat ('{"geometryType":"Polygon", "features":',v_result, '}'); 

	--  Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}, "data":{"info":'||v_result_info||',"polygon":{}}}}')::json, 9997, null, null, null);
            
END;
$function$
;

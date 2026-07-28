/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3110

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_create_dscenario_from_crm(p_data json) 
RETURNS json AS 
$BODY$

/*EXAMPLE

SELECT SCHEMA_NAME.gw_fct_create_dscenario_from_crm($${"client":{"device":4, "lang":"ca_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"name":"212", "descript":"te", "exploitation":"1", "period":"5", "onlyIsWaterBal":"true", "pattern":"3", "demandUnits":"LPS"}, "aux_params":null}}$$);

*/


DECLARE

object_rec record;

v_version text;
v_function_id integer = 3110;
v_result json;
v_result_info json;
v_name text;
v_descript text;
v_period text;
v_crm_name text;
v_error_context text;
v_count integer;
v_total_vol integer;
v_total_hydro integer;
v_count2 integer;
v_projecttype text;
v_fid integer = 403;
v_source_name text;
v_target_name text;
v_action text;
v_querytext text;
v_result_id text = 'empty';
v_scenarioid integer;
v_pattern integer;
v_periodunits text;
v_demandunits text;
v_periodseconds integer;
v_factor float;
v_expl TEXT;
v_onlyiswaterbal boolean;
v_waterbal TEXT;
v_startdate TEXT;
v_enddate TEXT;
v_sql TEXT;
v_tmethod text;
v_tmethod_query TEXT;
v_query_catdscenario TEXT;

v_step integer;
v_queryfinal TEXT;
v_queryhydro TEXT;
v_percent_hydro text;
v_proposed_enddate text;
v_rec_hydro record;
v_query_period text;
v_dma_weight_factor boolean;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	-- SELECT giswater
	SELECT giswater, project_type INTO v_version, v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;

	-- getting input data
	v_step := ((p_data ->>'data')::json->>'parameters')::json->>'step';
	v_name :=  ((p_data ->>'data')::json->>'parameters')::json->>'name';
	v_descript :=  ((p_data ->>'data')::json->>'parameters')::json->>'descript';
	v_period :=  ((p_data ->>'data')::json->>'parameters')::json->>'period';
	v_pattern :=  ((p_data ->>'data')::json->>'parameters')::json->>'pattern';
	v_demandunits :=  ((p_data ->>'data')::json->>'parameters')::json->>'demandUnits';
	v_expl :=  ((p_data ->>'data')::json->>'parameters')::json->>'exploitation'::text;
	v_onlyiswaterbal :=  ((p_data ->>'data')::json->>'parameters')::json->>'onlyIsWaterBal';
	v_tmethod :=  ((p_data ->>'data')::json->>'parameters')::json->>'patternOrDate';
	v_startdate :=  ((p_data ->>'data')::json->>'parameters')::json->>'initDate'::text;
	v_enddate :=  ((p_data ->>'data')::json->>'parameters')::json->>'endDate';
	v_dma_weight_factor :=  ((p_data ->>'data')::json->>'parameters')::json->>'export_weight';


	v_percent_hydro := (SELECT "value" FROM config_param_user WHERE "parameter" = 'epa_dscenario_percent_hydro_threshold' AND "cur_user" = current_user);
	v_percent_hydro = coalesce(v_percent_hydro, '1');

	IF v_expl = '99999' THEN

		EXECUTE 'SELECT string_agg(expl_id::text, '', '') from exploitation WHERE active IS TRUE AND expl_id>0 ' INTO v_expl;

	END IF;


	-- query calc hydro: (enddate)
	v_queryhydro = 'WITH hydro_data AS (
        SELECT
        d.hydrometer_id,
        d.cat_period_id,
        d.billed_volume,
        p.end_date AS p_end_date,
        first_value(d.billed_volume) OVER w AS last_billed_volume,
        first_value(d.cat_period_id) OVER w AS last_cat_period_id,
        first_value(p.end_date) OVER w::date AS last_end_date,
        first_value(p.period_seconds) OVER w AS last_period_seconds
        FROM v_hydrometer_period d
        JOIN v_cat_period p ON d.cat_period_id = p.id
        WINDOW w AS (PARTITION BY d.hydrometer_id ORDER BY p.end_date desc)
    ), hydro_data_calculat AS (
        SELECT DISTINCT
        d.hydrometer_id,
        d.last_billed_volume,
        d.last_cat_period_id,
        d.last_end_date,
        d.last_period_seconds AS p_seconds
        FROM hydro_data d
    ), hydro_data_selected AS (
        SELECT d.*
        FROM hydro_data_calculat d
        JOIN v_hydrometer h ON d.hydrometer_id = h.hydrometer_id
        WHERE h.end_date IS NULL
	), hydro_data_selected_expl AS (
	     SELECT d.*, c.expl_id AS expl_id
	     FROM hydro_data_selected d
	     JOIN v_hydrometer hc ON hc.hydrometer_id = d.hydrometer_id
	     JOIN connec c ON c.customer_code = hc.feature_customer_code
		 WHERE c.expl_id in ('||v_expl||')
	     UNION ALL
	     SELECT d.*, n.expl_id AS expl_id
	     FROM hydro_data_selected d
	     JOIN v_hydrometer erh ON erh.hydrometer_id = d.hydrometer_id
	     JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code
	     JOIN node n ON n.node_id = mn.node_id
	     WHERE n.expl_id in ('||v_expl||')
     ), hydro_estimated_statistic AS (
    	SELECT
        d.*,
        count(*) OVER (ORDER BY d.last_end_date RANGE BETWEEN UNBOUNDED PRECEDING AND ''1 days'' PRECEDING) AS hydro_no_llegits,
        count(*) OVER (PARTITION BY d.last_end_date) AS hydro_day,
        count(*) OVER () AS hydro_total
    	FROM hydro_data_selected_expl as d) ';

	IF v_step = 1 THEN -- set proposal OF enddate

		v_sql = concat(v_queryhydro, ' SELECT max(last_end_date)
    	FROM hydro_estimated_statistic
    	WHERE (100*hydro_no_llegits/hydro_total::float) < '||v_percent_hydro||'');

		execute v_sql INTO v_proposed_enddate;

    	v_proposed_enddate = coalesce(v_proposed_enddate, '1800-01-01');

		EXECUTE '
 		UPDATE temp_sys_function
 		SET descript = REPLACE(descript, split_part(descript, ''>'', 2), ''End Date proposal for '||v_percent_hydro||'% of hydrometers which consum is out of the period: '||v_proposed_enddate::TIMESTAMP||''')
		WHERE id in (3110)';


		v_proposed_enddate = quote_literal(v_proposed_enddate)::date - INTERVAL '1 day';
		v_proposed_enddate = v_proposed_enddate::date;

		UPDATE temp_config_toolbox 
 		SET inputparams = (
 		    SELECT jsonb_agg(
 		        CASE 
 		            WHEN elem->>'widgetname' = 'endDate' 
 		            THEN jsonb_set(elem, '{value}', to_jsonb(v_proposed_enddate::text))
 		            ELSE elem
 		        END
 		    )
 		    FROM jsonb_array_elements(inputparams::jsonb) elem
 		)
 		WHERE id = 3110;
   		RETURN '{"status":"Accepted"}';

	END IF;



	IF v_onlyiswaterbal is true then
		v_waterbal = 'TRUE';
	ELSE
		v_waterbal = 'TRUE, FALSE, NULL';
	END IF;
	
	v_crm_name := (SELECT code FROM v_cat_period WHERE id  = v_period);
	
	IF v_tmethod = '1' then

		v_periodseconds := (SELECT period_seconds FROM v_cat_period WHERE id  = v_period);
	
	ELSIF v_tmethod = '2' THEN --use date INTERVAL
	
		EXECUTE 'SELECT ('||quote_literal(v_enddate)||'::date - '||quote_literal(v_startdate)||'::date) * 24 * 3600' INTO v_periodseconds; -- FROM days to seconds
	
	END IF;

	

	IF v_periodseconds IS NULL THEN
		SELECT value::integer INTO v_periodseconds FROM config_param_system WHERE parameter = 'admin_crm_periodseconds_vdefault';
	END IF;
	
	-- Reset values
	DELETE FROM anl_node WHERE cur_user="current_user"() AND fid=v_fid;
	DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid;	

	-- create log
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"4", "is_process":true, "is_header":"true"}}$$)';
	INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, concat(''));

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"3", "is_process":true, "is_header":"true", "label_id":"3003", "separator_id":"2008"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"2", "is_process":true, "is_header":"true", "label_id":"3002", "separator_id":"2009"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"1", "is_process":true, "is_header":"true", "label_id":"3001", "separator_id":"2009"}}$$)';

	-- inserting on catalog table
	PERFORM setval('SCHEMA_NAME.cat_dscenario_dscenario_id_seq'::regclass,(SELECT max(dscenario_id) FROM cat_dscenario) ,true);

	INSERT INTO cat_dscenario (name, descript, dscenario_type, expl_id, log)
	SELECT v_name, v_descript, 'DEMAND',
	CASE WHEN v_expl ILIKE '%,%' THEN NULL ELSE v_expl::integer END,
	concat('Insert by ',current_user,' on ', substring(now()::text,0,20),'. Input params:{"Target feature":"", "Exploitation":"'||v_expl||'", "Source CRM Period":"',v_crm_name,'", "Source Pattern":"',v_pattern,'", "Demand Units":"',v_demandunits,'"}')
	ON CONFLICT (name) DO NOTHING RETURNING dscenario_id INTO v_scenarioid;


	IF v_tmethod = '1' THEN -- use period_id

		IF v_dma_weight_factor IS TRUE THEN

			v_querytext = 
				'WITH hydros AS (
					SELECT hydrometer_id, c.connec_id AS feature_id, c.dma_id, ''CONNEC'' AS feature_type, c.expl_id
					from v_hydrometer e
						JOIN connec c ON c.customer_code = e.feature_customer_code
					UNION ALL
					SELECT
						hydrometer_id, n.node_id AS feature_id, n.dma_id, ''NODE'' AS feature_type, n.expl_id
					from v_hydrometer erh
						JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code
						JOIN node n ON n.node_id = mn.node_id
				),
				data AS (
					SELECT d.hydrometer_id, h.dma_id, h.feature_id, h.feature_type, h.expl_id, billed_volume
					FROM v_hydrometer_period d
					JOIN hydros h
					ON h.hydrometer_id = d.hydrometer_id
					WHERE d.cat_period_id = '||quote_literal(v_period)||'
				)
				SELECT
					feature_type,
					feature_id,
					billed_volume / SUM(billed_volume) OVER (PARTITION BY data.dma_id) AS demand_weight,
					billed_volume,
					d.pattern_id AS pattern_id,
					hydrometer_id,
					data.expl_id,
					data.dma_id
				FROM data
				JOIN dma d ON d.dma_id = data.dma_id
				WHERE data.dma_id > 0';

		ELSE
			v_querytext = '
			with final_hydros as (
				SELECT h.hydrometer_id, hp.billed_volume, hc.pattern_id
				FROM v_hydrometer_period hp
				JOIN v_hydrometer h ON h.hydrometer_id = hp.hydrometer_id
				JOIN v_cat_hydrometer_category hc ON hc.id = h.category_id
				WHERE hp.cat_period_id = '||quote_literal(v_period)||'
			), aux_data AS (
				SELECT erh.hydrometer_id, c.connec_id AS feature_id, ''CONNEC'' AS feature_type, c.expl_id FROM v_hydrometer erh JOIN connec c ON c.customer_code = erh.feature_customer_code UNION
						SELECT erh.hydrometer_id, n.node_id AS feature_id, ''NODE'' AS feature_type, n.expl_id FROM v_hydrometer erh JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code JOIN node n ON n.node_id = mn.node_id
			)
			SELECT*FROM final_hydros LEFT JOIN aux_data USING (hydrometer_id) where feature_id is not null and expl_id in ('||v_expl||')';
		END IF;

	ELSIF v_tmethod = '2' THEN -- calculate period

		v_query_period = 
		'WITH period_calculat AS (
	        SELECT
				p.id, p.start_date::date, p.end_date::date, p.period_seconds AS p_seconds,
				CASE
					WHEN p.start_date >= '||quote_literal(v_startdate)||'::date THEN p.start_date
					ELSE '||quote_literal(v_startdate)||'
				END::date AS c_start_date,
				CASE
					WHEN p.end_date <= '||quote_literal(v_enddate)||'::date + INTERVAL ''1 day'' THEN p.end_date
						ELSE '||quote_literal(v_enddate)||'
				END::date AS c_end_date
			FROM v_cat_period p
		),
		period_selected AS (
			SELECT
				p.*,
				EXTRACT(EPOCH FROM p.c_end_date::date + INTERVAL ''1 day'') - EXTRACT(EPOCH FROM p.c_start_date) AS c_seconds
			FROM period_calculat p
			WHERE p.end_date >= '||quote_literal(v_startdate)||'
			AND  p.start_date <= '||quote_literal(v_enddate)||'::date + INTERVAL ''1 day''
		),';

		IF v_dma_weight_factor IS TRUE THEN
			v_querytext = v_query_period||
			'hydros AS (
				SELECT erh.hydrometer_id, c.connec_id AS feature_id, c.dma_id, ''CONNEC'' AS feature_type, c.expl_id
				FROM v_hydrometer erh
				JOIN connec c ON c.customer_code = erh.feature_customer_code
				UNION ALL
				SELECT erh.hydrometer_id, n.node_id AS feature_id, n.dma_id, ''NODE'' AS feature_type, n.expl_id
				FROM v_hydrometer erh
				JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code
				JOIN node n ON n.node_id = mn.node_id
			),
			data AS (
				SELECT
					d.hydrometer_id,
					h.dma_id,
					h.feature_id,
					h.feature_type,
					h.expl_id,
					SUM(d.billed_volume * (p.c_seconds / p.p_seconds))::numeric(10,0) AS billed_volume,
					hc.pattern_id
				FROM v_hydrometer_period d
				JOIN v_hydrometer h ON h.hydrometer_id = d.hydrometer_id
				JOIN v_cat_hydrometer_category hc ON hc.id = h.category_id
				JOIN period_selected p ON d.cat_period_id = p.id
				JOIN hydros h ON d.hydrometer_id = h.hydrometer_id
				GROUP BY d.hydrometer_id, h.dma_id, h.feature_id, h.feature_type, h.expl_id, hc.pattern_id
			)
			SELECT
				feature_type,
				feature_id,
				billed_volume / SUM(billed_volume) OVER (PARTITION BY data.dma_id) AS demand_weight,
				billed_volume,
				d.pattern_id AS pattern_id,
				hydrometer_id,
				data.expl_id,
				data.dma_id
			FROM data
			JOIN dma d ON d.dma_id = data.dma_id
			WHERE feature_id IS NOT NULL AND data.dma_id > 0
			AND expl_id IN ('||v_expl||')';

		ELSE

		v_querytext = v_query_period||
		'final_hydros AS  (
			    SELECT
			    d.hydrometer_id,
			    sum(d.billed_volume*(p.c_seconds/p.p_seconds))::numeric(10,0) AS billed_volume, pattern_id
			    FROM v_hydrometer_period d
				JOIN v_hydrometer h ON h.hydrometer_id = d.hydrometer_id
				JOIN v_cat_hydrometer_category hc ON hc.id = h.category_id
			    JOIN period_selected p ON d.cat_period_id = p.id
			    GROUP BY d.hydrometer_id, pattern_id
			), aux_data AS (
				SELECT erh.hydrometer_id, c.connec_id AS feature_id, ''CONNEC'' AS feature_type, c.expl_id FROM v_hydrometer erh JOIN connec c ON erh.feature_customer_code = c.customer_code UNION
				SELECT erh.hydrometer_id, n.node_id AS feature_id, ''NODE'' AS feature_type, n.expl_id FROM v_hydrometer erh JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code JOIN node n ON n.node_id = mn.node_id
			)
				SELECT*FROM final_hydros LEFT JOIN aux_data USING (hydrometer_id) where feature_id is not null and expl_id in ('||v_expl||')';
		END IF;

	END IF;


	IF v_scenarioid IS NULL THEN
		SELECT dscenario_id INTO v_scenarioid FROM cat_dscenario where name = v_name;
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"3696", "function":"'||v_function_id||'", "parameters":{"v_scenarioid":"'||v_scenarioid||'", "v_name":"'||v_name||'"}, "fid":"'||v_fid||'", "criticity":"3", "is_process":true}}$$)';
		
	ELSE

		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4644", "function":"'||v_function_id||'", "parameters":{"v_name":"'||v_name||'", "v_scenarioid":"'||v_scenarioid||'"}, "fid":"'||v_fid||'", "criticity":"4", "is_process":true}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4646", "function":"'||v_function_id||'", "parameters":{"v_crm_name":"'||v_crm_name||'"}, "fid":"'||v_fid||'", "criticity":"4", "is_process":true}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4648", "function":"'||v_function_id||'", "parameters":{"v_pattern":"'||v_pattern||'"}, "fid":"'||v_fid||'", "criticity":"4", "is_process":true}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4650", "function":"'||v_function_id||'", "parameters":{"v_demandunits":"'||v_demandunits||'"}, "fid":"'||v_fid||'", "criticity":"4", "is_process":true}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4652", "function":"'||v_function_id||'", "parameters":{"v_periodseconds":"'||abs(v_periodseconds)||'"}, "fid":"'||v_fid||'", "criticity":"4", "is_process":true}}$$)';
	
		IF (SELECT period_seconds FROM v_cat_period WHERE id  = v_period) IS NULL THEN
			SELECT dscenario_id INTO v_scenarioid FROM cat_dscenario where name = v_name;
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4654", "function":"'||v_function_id||'", "parameters":{"v_periodseconds":"'||v_periodseconds||'"}, "fid":"'||v_fid||'", "criticity":"2", "is_process":true}}$$)';
		END IF;

		-- this factor is calculated assuming period value is on M3
		v_factor = 1000*(SELECT value::json->>v_demandunits FROM config_param_system WHERE parameter = 'epa_units_factor')::float/v_periodseconds::float;		


		-- count hydrometers and total vol grouped by feature_type
		EXECUTE 'SELECT COUNT(hydrometer_id) FROM ('||v_querytext||')' INTO v_total_hydro;

		EXECUTE 'SELECT sum("billed_volume") FROM ('||v_querytext||')' INTO v_total_vol;

		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4656", "function":"'||v_function_id||'", "parameters":{"v_total_hydro":"'||COALESCE(v_total_hydro, 0)||'"}, "fid":"'||v_fid||'", "criticity":"1", "is_process":true}}$$)';

		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4658", "function":"'||v_function_id||'", "parameters":{"v_total_vol":"'||COALESCE(v_total_vol, 0)||'"}, "fid":"'||v_fid||'", "criticity":"1", "is_process":true}}$$)';

		IF v_dma_weight_factor is true then
			EXECUTE 'INSERT INTO inp_dscenario_demand (feature_type, dscenario_id, feature_id, demand, source, pattern_id)
			WITH aux as ('||v_querytext||')
			SELECT  feature_type, '||v_scenarioid||', feature_id,
			demand_weight as volume,
			hydrometer_id as source,
			pattern_id
			FROM aux order by 2';
		ELSE
			EXECUTE 'INSERT INTO inp_dscenario_demand (feature_type, dscenario_id, feature_id, demand, source)
			WITH aux as ('||v_querytext||')
			SELECT  feature_type, '||v_scenarioid||', feature_id,
			'||v_factor||'*billed_volume::numeric as volume,
			hydrometer_id as source
			FROM aux order by 2';
		END IF;

		IF v_dma_weight_factor IS TRUE THEN
			SELECT count(*) INTO v_count2
			FROM (
				SELECT dma_id, sum(demand) AS dma_demand
				FROM (
					SELECT d.demand, c.dma_id
					FROM inp_dscenario_demand d
					JOIN connec c ON c.connec_id = d.feature_id
					WHERE d.dscenario_id = v_scenarioid AND d.feature_type = 'CONNEC'
					UNION ALL
					SELECT d.demand, n.dma_id
					FROM inp_dscenario_demand d
					JOIN node n ON n.node_id = d.feature_id
					WHERE d.dscenario_id = v_scenarioid AND d.feature_type = 'NODE'
				) aux
				GROUP BY dma_id
				HAVING round(sum(demand)::numeric, 4) <> 1
			) invalid_dmas;

			IF v_count2 = 0 THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4676", "function":"'||v_function_id||'", "fid":"'||v_fid||'"}}$$)';
			END IF;
		ELSE
			-- real volume inserted
			SELECT sum(demand)/v_factor INTO v_count2 FROM inp_dscenario_demand WHERE dscenario_id = v_scenarioid;

			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4640", "function":"'||v_function_id||'", "fid":"'||v_fid||'", "parameters":{"volume":"'||COALESCE(v_count2, 0)||'", "percentage":"'||COALESCE((100-100*v_count2::float/v_total_vol::float)::numeric(12,2), 0)||'"}}}$$)';

			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4642", "function":"'||v_function_id||'", "fid":"'||v_fid||'"}}$$)';
		END IF;

		-- update patterns  (1 -> none)
		IF v_dma_weight_factor IS FALSE THEN
			IF v_pattern = 2 THEN -- sector default

				UPDATE inp_dscenario_demand d SET pattern_id = s.pattern_id
				FROM sector s
				JOIN connec c ON s.sector_id = c.sector_id
				JOIN v_hydrometer h ON h.feature_customer_code = c.customer_code
				WHERE d.source = h.hydrometer_id::text
				AND dscenario_id = v_scenarioid;

			ELSIF v_pattern = 3 THEN -- dma default
				-- LO MATEIX PERÒ PER AL PATTERN DE LA DMA
				UPDATE inp_dscenario_demand d SET pattern_id = s.pattern_id
				FROM dma s
				JOIN connec c ON c.dma_id = s.dma_id
				JOIN v_hydrometer h ON h.feature_customer_code = c.customer_code
				WHERE d.source = h.hydrometer_id::text
				AND dscenario_id = v_scenarioid;

			ELSIF v_pattern = 6 THEN -- hydrometer category

				UPDATE inp_dscenario_demand d SET pattern_id = c.pattern_id 
				FROM v_hydrometer h
				JOIN v_cat_hydrometer_category c ON c.id = h.category_id
				WHERE d.source = h.hydrometer_id::text
				AND dscenario_id = v_scenarioid;

			ELSIF v_pattern = 7 THEN -- feature pattern

				-- update wjoins (connec)
				UPDATE inp_dscenario_demand d SET pattern_id = i.pattern_id 
				FROM inp_connec i
				JOIN connec c ON c.connec_id = i.connec_id
				JOIN v_hydrometer h ON h.feature_customer_code = c.customer_code
				WHERE d.source = h.hydrometer_id::text
				AND dscenario_id = v_scenarioid;
				
				-- update netwjoins (node)
				UPDATE inp_dscenario_demand d SET pattern_id = i.pattern_id 
				FROM inp_junction i
				JOIN node n ON n.node_id = i.node_id
				JOIN man_netwjoin mn ON mn.node_id = n.node_id
				JOIN v_hydrometer h ON h.feature_customer_code = mn.customer_code
				WHERE d.source = h.hydrometer_id::text
				AND dscenario_id = v_scenarioid;

			END IF;
			
		END IF;

		IF v_pattern > 1 THEN

			GET DIAGNOSTICS v_count2 = row_count;	
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4660", "function":"'||v_function_id||'", "parameters":{"v_count2":"'||COALESCE(v_count2, 0)||'"}, "fid":"'||v_fid||'", "criticity":"1", "is_process":true}}$$)';
		
			IF v_count > v_count2 THEN

				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4662", "function":"'||v_function_id||'", "parameters":{"v_count":"'||COALESCE((v_count-v_count2), 0)||'"}, "fid":"'||v_fid||'", "criticity":"2", "prefix_id":"1006", "is_process":true}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4664", "function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"2", "is_process":true}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4666", "function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"2", "is_process":true}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4668", "function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"2", "is_process":true}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4670", "function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"2", "is_process":true}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4672", "function":"'||v_function_id||'", "fid":"'||v_fid||'", "criticity":"2", "is_process":true}}$$)';
			END IF;
		END IF;
				

		-- hydro stats

		EXECUTE concat(v_queryhydro, ', aux AS (
    	SELECT DISTINCT last_end_date, hydro_no_llegits, hydro_day,hydro_total,
		(100*hydro_no_llegits/hydro_total::float) AS percentage
		FROM hydro_estimated_statistic
		ORDER BY last_end_date)
		SELECT aux.*, ROW_NUMBER() OVER(PARTITION BY percentage ORDER BY percentage)
		FROM aux WHERE percentage< ', v_percent_hydro, ' ORDER BY ROW_NUMBER() OVER() DESC LIMIT 1')
		INTO v_rec_hydro;


		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4674", "function":"'||v_function_id||'", "parameters":{"v_hydro_no_llegits":"'||COALESCE(v_rec_hydro.hydro_no_llegits, 0)||'", "v_hydro_total":"'||COALESCE(v_rec_hydro.hydro_total, 0)||'", "v_percentage":"'||COALESCE(v_rec_hydro.percentage, 0)||'"}, "fid":"'||v_fid||'", "criticity":"1", "is_process":true}}$$)';

		-- set selector
		INSERT INTO selector_inp_dscenario (dscenario_id,cur_user) VALUES (v_scenarioid, current_user) ON CONFLICT (dscenario_id,cur_user) DO NOTHING;
		
		UPDATE inp_dscenario_demand SET source = concat('HYD ', source) WHERE dscenario_id = v_scenarioid;

		INSERT INTO audit_check_data (fid, result_id, criticity, error_message)	
		VALUES (v_fid, v_result_id, 1, concat(''));
	END IF;
		
	-- insert spacers
	INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 3, concat(''));
	INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 2, concat(''));

	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result 
	FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid order by criticity desc, id asc) row;
	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_result_info := COALESCE(v_result_info, '{}'); 

	-- Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||
			'}}'||
	    '}')::json, 3042, null, null, null); 

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
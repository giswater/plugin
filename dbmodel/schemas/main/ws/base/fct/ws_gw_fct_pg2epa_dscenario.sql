/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2456

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_dscenario (result_id_var character varying)
RETURNS integer AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_pg2epa_dscenario('prognosi')
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"data":{ "resultId":"test_bgeo_b1", "useNetworkGeom":"false"}}$$)

SELECT * FROM SCHEMA_NAME.temp_t_node WHERE node_id = 'VN257816';
*/

DECLARE

arc_rec record;
pump_rec record;
v_node text;
rec record;
record_new_arc record;
n1_geom public.geometry;
n2_geom public.geometry;
p1_geom public.geometry;
p2_geom public.geometry;
angle float;
dist float;
xp1 float;
yp1 float;
xp2 float;
yp2 float;
odd_var float;
pump_order float;
v_old_arc_id varchar(16);
v_addparam json;
rec_version record;

v_demandpriority integer;
v_querytext text;
v_patternmethod integer;
v_userscenario integer[];
v_networkmode integer;
v_deafultpattern text;


BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	RAISE NOTICE 'Starting pg2epa for filling demand scenario';

	IF (SELECT count(*) FROM selector_inp_dscenario WHERE cur_user = current_user) > 0 THEN

		SELECT * INTO rec_version FROM sys_version ORDER BY id DESC LIMIT 1;

		-- assign value for record_new_arc for pump additional
		SELECT * INTO record_new_arc FROM arc LIMIT 1;

		v_networkmode = (SELECT value::integer FROM config_param_user WHERE parameter='inp_options_networkmode' AND cur_user=current_user);
		v_demandpriority = (SELECT value::integer FROM config_param_user WHERE parameter='inp_options_dscenario_priority' AND cur_user=current_user);
		v_patternmethod = (SELECT value::integer FROM config_param_user WHERE parameter='inp_options_patternmethod' AND cur_user=current_user);
		v_userscenario = (SELECT array_agg(dscenario_id) FROM selector_inp_dscenario where cur_user=current_user);
		v_deafultpattern = Coalesce((SELECT value FROM config_param_user WHERE parameter='inp_options_pattern' AND cur_user=current_user),'');

		-- Remove whole base demand
		IF v_demandpriority = 0 THEN

			-- -- for inp_options_networkmode = 1,2,4
			UPDATE temp_t_node SET demand = 0, pattern_id = null;

			-- for inp_options_networkmode = 3
			DELETE FROM temp_t_demand;

		END IF;

		-- insert node demands from dscenario into temp_t_demand
		INSERT INTO temp_t_demand (dscenario_id, feature_id, demand, pattern_id, demand_type, source)
		SELECT dscenario_id, feature_id, d.demand, d.pattern_id, d.demand_type, d.source
		FROM temp_t_node n, inp_dscenario_demand d WHERE n.node_id = d.feature_id::text AND d.demand IS NOT NULL AND d.demand <> 0
		AND dscenario_id IN (SELECT unnest(v_userscenario)) AND n.dma_id IN (SELECT DISTINCT dma_id FROM temp_t_arc);

		-- insert connec demands from dscenario into temp_t_demand linking object which is exported
		IF v_networkmode IN(1,2) THEN

			-- demands for connec related to arcs
			INSERT INTO temp_t_demand (dscenario_id, feature_id, demand, pattern_id, demand_type, source)
			SELECT d.dscenario_id, n.node_id, d.demand * 0.5 AS demand, d.pattern_id, d.demand_type, d.source
			FROM temp_t_arc a
				JOIN ve_inp_connec v ON a.arc_id = v.arc_id::text
				JOIN inp_dscenario_demand d ON d.feature_id = v.connec_id
				JOIN LATERAL (
				    SELECT a.node_1 AS node_id
				    UNION ALL
				    SELECT a.node_2
				) n ON TRUE
			WHERE d.dscenario_id = ANY (v_userscenario)
		  	AND v.pjoint_type = ANY (ARRAY['ARC','CONNEC'])
			AND n.node_id is not null;

			-- demands for connec related to nodes
			INSERT INTO temp_t_demand (dscenario_id, feature_id, demand, pattern_id, demand_type, source)
			SELECT dscenario_id, pjoint_id, d.demand as demand, d.pattern_id, demand_type, source  FROM ve_inp_connec
			JOIN inp_dscenario_demand d ON feature_id = connec_id
			WHERE pjoint_type = 'NODE'
			AND dscenario_id IN (SELECT unnest(v_userscenario));

			IF v_demandpriority = 2 THEN
				-- moving node demands to temp_t_demand (to skip EPANET behaviour)
				INSERT INTO temp_t_demand (dscenario_id, feature_id, demand, pattern_id)
				SELECT DISTINCT ON (node_id) 0, node_id, n.demand, n.pattern_id
				FROM temp_t_node n
				JOIN temp_t_demand ON node_id = feature_id::text
				WHERE n.demand IS NOT NULL AND n.demand <> 0;
			END IF;

		ELSIF v_networkmode = 3 THEN

			-- insertar all connecs
			-- Use the merged vnode mapping if available, otherwise use the original vnode id
			INSERT INTO temp_t_demand (dscenario_id, feature_id, demand, pattern_id, demand_type, source)
			select dscenario_id ,
				COALESCE(m.merged_vnode_id, concat('VN',link_id)) as feature_id,
				dd.demand,
				dd.pattern_id,
				demand_type,
				source
			from inp_dscenario_demand dd
			join temp_t_link l using (feature_id)
			join inp_connec on connec_id = l.feature_id
			LEFT JOIN temp_vnode_mapping m ON m.original_vnode_id = concat('VN',link_id)
			WHERE dscenario_id IN (SELECT unnest(v_userscenario)) and dd.demand IS NOT NULL AND dd.demand <> 0;

			-- update those connecs that is other link_id
			WITH demands AS (
				SELECT feature_id
				FROM temp_t_demand d
				WHERE NOT EXISTS (
					SELECT 1
					FROM temp_t_node
					WHERE node_id = d.feature_id
				)
			)
			UPDATE temp_t_demand d SET feature_id = f.feature_id
			FROM
			(
				SELECT concat('VN',c2.link_id) as feature_id
				FROM temp_t_link c1
				JOIN temp_t_link c2 ON ST_DWithin(c1.the_geom, c2.the_geom, 100)
					AND c1.link_id <> c2.link_id
				JOIN demands d1 ON concat('VN',c1.link_id) = d1.feature_id
					AND concat('VN',c2.link_id) = d1.feature_id
				ORDER BY ST_Distance(c1.the_geom, c2.the_geom) ASC
				LIMIT 1
			) f;


		end if;

		-- remove those demands which for some reason linked node is not exported
		DELETE FROM temp_t_demand WHERE feature_id IN (
			SELECT feature_id FROM temp_t_demand
			WHERE NOT EXISTS (SELECT 1 FROM temp_t_node WHERE node_id = feature_id::text)
		);
		-- pattern
		IF v_patternmethod = 11 THEN -- DEFAULT PATTERN
			UPDATE temp_t_demand SET pattern_id=v_deafultpattern WHERE pattern_id IS NULL;

		ELSIF v_patternmethod = 12 THEN -- SECTOR PATTERN (NODE)
			UPDATE temp_t_demand SET pattern_id=sector.pattern_id FROM node JOIN sector ON sector.sector_id=node.sector_id WHERE temp_t_demand.feature_id=node.node_id::text
			 AND temp_t_demand.pattern_id IS NULL;
			UPDATE temp_t_demand SET pattern_id=sector.pattern_id FROM connec JOIN sector ON sector.sector_id=connec.sector_id WHERE temp_t_demand.feature_id=connec.connec_id::text
			 AND temp_t_demand.pattern_id IS NULL;

		ELSIF v_patternmethod = 13 THEN -- DMA PATTERN (NODE)
			UPDATE temp_t_demand SET pattern_id=dma.pattern_id FROM node JOIN dma ON dma.dma_id=node.dma_id WHERE temp_t_demand.feature_id=node.node_id::text
			 AND temp_t_demand.pattern_id IS NULL;
			UPDATE temp_t_demand SET pattern_id=dma.pattern_id FROM connec JOIN dma ON dma.dma_id=connec.dma_id WHERE temp_t_demand.feature_id=connec.connec_id::text
			 AND temp_t_demand.pattern_id IS NULL;

		ELSIF v_patternmethod = 14 THEN -- FEATURE PATTERN (NODE)
			-- do nothing because values have been moved from feature
		END IF;


		-- set cero where null in order to prevent user's null values on demand table
		UPDATE temp_t_node SET demand=0 WHERE demand IS NULL;

		-- updating values for pipes (when are not trimed)
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_pipe d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET minorloss = d.minorloss FROM inp_dscenario_pipe d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;
		UPDATE temp_t_arc t SET diameter = d.dint FROM inp_dscenario_pipe d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.dint IS NOT NULL;
		UPDATE temp_t_arc t SET roughness = d.roughness FROM inp_dscenario_pipe d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.roughness IS NOT NULL;

		-- updating values for pipes (when are trimed, network mode  = 4)
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_pipe d
		WHERE substring (t.arc_id, 0, (case when position ('P' in t.arc_id) in (0) then 99 else position ('P' in t.arc_id) end)) = d.arc_id::text
		AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET minorloss = d.minorloss FROM inp_dscenario_pipe d
		WHERE substring (t.arc_id, 0, (case when position ('P' in t.arc_id) in (0) then 99 else position ('P' in t.arc_id) end)) = d.arc_id::text
		AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;
		UPDATE temp_t_arc t SET diameter = d.dint FROM inp_dscenario_pipe d
		WHERE substring (t.arc_id, 0, (case when position ('P' in t.arc_id) in (0) then 99 else position ('P' in t.arc_id) end)) = d.arc_id::text
		AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.dint IS NOT NULL;
		UPDATE temp_t_arc t SET roughness = d.roughness FROM inp_dscenario_pipe d
		WHERE substring (t.arc_id, 0, (case when position ('P' in t.arc_id) in (0) then 99 else position ('P' in t.arc_id) end)) = d.arc_id::text
		AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.roughness IS NOT NULL;

		-- updating values for shortpipes
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_shortpipe d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a') AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET minorloss = d.minorloss FROM inp_dscenario_shortpipe d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = jsonb_set(addparam::jsonb, '{to_arc}', to_jsonb(to_arc), true)
		FROM inp_dscenario_shortpipe d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.to_arc IS NOT NULL;

		-- updating values for shortpipes (as junction)
		UPDATE temp_t_node t SET demand = d.demand FROM inp_dscenario_shortpipe d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand IS NOT NULL AND epa_type = 'JUNCTION';
		UPDATE temp_t_node t SET pattern_id = d.demand_pattern_id FROM inp_dscenario_shortpipe d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand_pattern_id IS NOT NULL AND epa_type = 'JUNCTION';

		-- updating values for shortpipes (as reservoir)
		UPDATE temp_t_node t SET elev = d.head FROM inp_dscenario_shortpipe d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.head IS NOT NULL AND epa_type = 'RESERVOIR';
		UPDATE temp_t_node t SET pattern_id = d.pattern_id FROM inp_dscenario_shortpipe d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL AND epa_type = 'RESERVOIR';

		-- updating values for frshortpipes
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_frshortpipe d
		WHERE t.arc_id = d.element_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET minorloss = d.minorloss FROM inp_dscenario_frshortpipe d
		WHERE t.arc_id = d.element_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;

		-- updating values for pumps
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_pump d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a') AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'power',d.power) FROM inp_dscenario_pump d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.power IS NOT NULL AND d.power !='';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_pump d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'speed',d.speed) FROM inp_dscenario_pump d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.speed IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'pattern',d.pattern_id) FROM inp_dscenario_pump d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL;

		-- updating values for frpump (POWERPUMPS)
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = d.element_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL AND p.pump_type = 'POWERPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'power',d.power) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.power IS NOT NULL AND d.power !='' AND p.pump_type = 'POWERPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL AND p.pump_type = 'POWERPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'speed',d.speed) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.speed IS NOT NULL AND p.pump_type = 'POWERPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'pattern',d.pattern_id) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL AND p.pump_type = 'POWERPUMP';

		-- updating values for frpump (HEADPUMPS)
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = concat(d.element_id::text, '_n2a_1') AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL AND p.pump_type = 'HEADPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'power',d.power) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = concat(d.element_id::text, '_n2a_1')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.power IS NOT NULL AND d.power !='' AND p.pump_type = 'HEADPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = concat(d.element_id::text, '_n2a_1')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL AND p.pump_type = 'HEADPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'speed',d.speed) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = concat(d.element_id::text, '_n2a_1')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.speed IS NOT NULL AND p.pump_type = 'HEADPUMP';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'pattern',d.pattern_id) FROM inp_dscenario_frpump d JOIN inp_frpump p ON p.element_id = d.element_id
		WHERE t.arc_id = concat(d.element_id::text, '_n2a_1')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL AND p.pump_type = 'HEADPUMP';

		-- updating values for valves
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_valve d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a') AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'valve_type',d.valve_type) FROM inp_dscenario_valve d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.valve_type IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'setting',d.setting) FROM inp_dscenario_valve d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.setting IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_valve d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'minorloss',d.minorloss) FROM inp_dscenario_valve d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = jsonb_set(addparam::jsonb, '{to_arc}', to_jsonb(to_arc), true)
		FROM inp_dscenario_valve d
		WHERE t.arc_id = concat(d.node_id::text, '_n2a')  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.to_arc IS NOT NULL;

		-- updating values for valves (as junction)
		UPDATE temp_t_node t SET demand = d.demand FROM inp_dscenario_valve d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand IS NOT NULL AND epa_type = 'JUNCTION';
		UPDATE temp_t_node t SET pattern_id = d.demand_pattern_id FROM inp_dscenario_valve d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand_pattern_id IS NOT NULL AND epa_type = 'JUNCTION';

		-- updating values for valves (as reservoir)
		UPDATE temp_t_node t SET elev = d.head FROM inp_dscenario_valve d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.head IS NOT NULL AND epa_type = 'RESERVOIR';
		UPDATE temp_t_node t SET pattern_id = d.pattern_id FROM inp_dscenario_valve d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL AND epa_type = 'RESERVOIR';

		-- updating values for frvalve
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_frvalve d
		WHERE t.arc_id = d.element_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'valve_type',d.valve_type) FROM inp_dscenario_frvalve d
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.valve_type IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'setting',d.setting) FROM inp_dscenario_frvalve d
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.setting IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_frvalve d
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'minorloss',d.minorloss) FROM inp_dscenario_frvalve d
		WHERE t.arc_id = d.element_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;

		-- updating values for reservoir
		UPDATE temp_t_node t SET pattern_id = d.pattern_id FROM inp_dscenario_reservoir d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'head',d.head) FROM inp_dscenario_reservoir d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.head IS NOT NULL;

		-- updating values for tanks
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'initlevel',d.initlevel) FROM inp_dscenario_tank d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.initlevel IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'minlevel',d.minlevel) FROM inp_dscenario_tank d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minlevel IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'maxlevel',d.maxlevel) FROM inp_dscenario_tank d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.maxlevel IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'diameter',d.diameter) FROM inp_dscenario_tank d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.diameter IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'minvol',d.minvol) FROM inp_dscenario_tank d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minvol IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_tank d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'overflow',d.overflow) FROM inp_dscenario_tank d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.overflow IS NOT NULL;

		-- updating values for inlet (as tank)
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'initlevel',d.initlevel) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.initlevel IS NOT NULL AND t.epa_type = 'TANK';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'minlevel',d.minlevel) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minlevel IS NOT NULL AND t.epa_type = 'TANK';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'maxlevel',d.maxlevel) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.maxlevel IS NOT NULL AND t.epa_type = 'TANK';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'diameter',d.diameter) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.diameter IS NOT NULL AND t.epa_type = 'TANK';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'minvol',d.minvol) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minvol IS NOT NULL AND t.epa_type = 'TANK';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL AND t.epa_type = 'TANK';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'overflow',d.overflow) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.overflow IS NOT NULL AND t.epa_type = 'TANK';

		-- updating values for inlet (as reservoir)
		UPDATE temp_t_node t SET pattern_id = d.pattern_id FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL AND t.epa_type = 'RESERVOIR';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'head',d.head) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.head IS NOT NULL AND t.epa_type = 'RESERVOIR';

		-- updating values for inlet (as junction)
		UPDATE temp_t_node t SET demand = d.demand FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand IS NOT NULL AND t.epa_type = 'JUNCTION';
		UPDATE temp_t_node t SET pattern_id = d.demand_pattern_id FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand_pattern_id IS NOT NULL AND t.epa_type = 'JUNCTION';
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'emitter_coeff', d.emitter_coeff) FROM inp_dscenario_inlet d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.emitter_coeff IS NOT NULL AND t.epa_type = 'JUNCTION';

		-- updating values for junction
		UPDATE temp_t_node t SET demand = d.demand FROM inp_dscenario_junction d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand IS NOT NULL;
		UPDATE temp_t_node t SET pattern_id = d.pattern_id FROM inp_dscenario_junction d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL;
		UPDATE temp_t_node t SET addparam = gw_fct_json_object_set_key(addparam::json, 'emitter_coeff', d.emitter_coeff) FROM inp_dscenario_junction d
		WHERE t.node_id = d.node_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.emitter_coeff IS NOT NULL;

		-- updating values for connec
		UPDATE temp_t_node t SET demand = d.demand FROM inp_dscenario_connec d
		WHERE t.node_id = d.connec_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.demand IS NOT NULL;
		UPDATE temp_t_node t SET pattern_id = d.pattern_id FROM inp_dscenario_connec d
		WHERE t.node_id = d.connec_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL;
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_connec d
		WHERE t.arc_id = concat('CO',d.connec_id::text) AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET minorloss = d.minorloss FROM inp_dscenario_connec d
		WHERE t.arc_id = concat('CO',d.connec_id::text) AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;
		UPDATE temp_t_arc t SET diameter = d.custom_dint FROM inp_dscenario_connec d
		WHERE t.arc_id = concat('CO',d.connec_id::text) AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.custom_dint IS NOT NULL;
		UPDATE temp_t_arc t SET length = d.custom_length FROM inp_dscenario_connec d
		WHERE t.arc_id = concat('CO',d.connec_id::text) AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.custom_length IS NOT NULL;
		UPDATE temp_t_arc t SET roughness = d.custom_roughness FROM inp_dscenario_connec d
		WHERE t.arc_id = concat('CO',d.connec_id::text) AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.custom_roughness IS NOT NULL;


		-- updating values for virtualvalve
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_virtualvalve d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'valve_type',d.valve_type) FROM inp_dscenario_virtualvalve d
		WHERE t.arc_id = d.arc_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.valve_type IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'setting',d.setting) FROM inp_dscenario_virtualvalve d
		WHERE t.arc_id = d.arc_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.setting IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_virtualvalve d
		WHERE t.arc_id = d.arc_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'minorloss',d.minorloss) FROM inp_dscenario_virtualvalve d
		WHERE t.arc_id = d.arc_id::text  AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.minorloss IS NOT NULL;

		-- updating values for virtualpump
		UPDATE temp_t_arc t SET status = d.status FROM inp_dscenario_virtualpump d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.status IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'power',d.power) FROM inp_dscenario_virtualpump d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.power IS NOT NULL AND d.power !='';
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'curve_id',d.curve_id) FROM inp_dscenario_virtualpump d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.curve_id IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'power',NULL::TEXT) FROM inp_dscenario_virtualpump d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.power IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'speed',d.speed) FROM inp_dscenario_virtualpump d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.speed IS NOT NULL;
		UPDATE temp_t_arc t SET addparam = gw_fct_json_object_set_key(addparam::json, 'pattern',d.pattern_id) FROM inp_dscenario_virtualpump d
		WHERE t.arc_id = d.arc_id::text AND dscenario_id IN (SELECT unnest(v_userscenario)) AND d.pattern_id IS NOT NULL;

	END IF;

	RETURN 1;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
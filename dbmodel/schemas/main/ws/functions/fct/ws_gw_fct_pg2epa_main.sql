/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2646

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_pg2epa(character varying, boolean, boolean);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_pg2epa(character varying, boolean);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_pg2epa(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_main(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "step":"1"}}$$); -- PRE-PROCESS
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "step":"2"}}$$); -- AUTOREPAIR
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "step":"3"}}$$); -- CHECK DATA
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "step":"4"}}$$); -- STRUCTURE DATA
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "step":"5"}}$$); -- CHECK GRAPH
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "step":"6"}}$$); -- BUILD INP
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "step":"7"}}$$); -- POST-PROCESS

select * from temp_audit_check_data order by 1 asc


select * from t__arc


--fid: 227

*/

DECLARE

v_networkmode integer = 1;
v_return json;
v_input json;
v_result text;
v_onlymandatory_nodarc boolean = false;
v_vnode_trimarcs boolean = false;
v_response integer;
v_message text;
v_setdemand boolean;
v_buildupmode integer;
v_inpoptions json;
v_advancedsettings boolean;
v_file json;
v_body json;
v_onlyexport boolean;
v_checkdata boolean;
v_checknetwork boolean;
v_vdefault boolean;
v_fid integer = 227;
v_error_context text;
v_breakpipes boolean;
v_count integer;
v_step integer=0;
v_autorepair boolean;
v_expl integer = null;
v_sector_0 boolean = false;
v_expl_id integer[];
v_sector_id integer[];
v_network_type integer;
v_epa_maxresults integer;
v_dma_id integer[];
v_flow_units text;
v_quality_units text;
v_userscenario integer[];
v_client_epsg integer;

BEGIN

	-- set search path
	SET search_path = "SCHEMA_NAME", public;

	-- get input data
	v_result = (p_data->>'data')::json->>'resultId';
	v_step = (p_data->>'data')::json->>'step';  -- use network previously defined
	v_input = concat('{"data":{"parameters":{"isEmbebed":true, "verifiedExceptions":true, "resultId":"',v_result,'", "fid":227}}}')::json;

	-- step 0: Manage epa max results variable
	select value into v_epa_maxresults from config_param_user where parameter = 'epa_maxresults_peruser' and cur_user=current_user;

	if (select count(*) from rpt_cat_result where cur_user = current_user) > v_epa_maxresults then
		RETURN ('{"status":"Failed","message":{"level":1, "text":"You have reached the maximum results limit."}}')::json;
	end if;

	-- step 1: preprocess
	IF v_step = 1 THEN

		-- validate QGIS project CRS for INP export (projected CRS required)
		v_client_epsg := (p_data->'client'->>'epsg')::integer;

		IF v_client_epsg IS NULL OR NOT EXISTS (SELECT 1 FROM spatial_ref_sys WHERE srid = v_client_epsg) THEN
			SELECT error_message INTO v_message FROM sys_message WHERE id = 4370;
			RETURN ('{"status":"Failed","message":{"level":1, "text":"'||v_message||'"}}')::json;
		END IF;

		IF gw_fct_is_geographic_srid(v_client_epsg) IS TRUE THEN
			SELECT error_message INTO v_message FROM sys_message WHERE id = 4371;
			RETURN ('{"status":"Failed","message":{"level":1, "text":"'||v_message||'"}}')::json;
		END IF;

		-- check sector selector
		SELECT count(*) INTO v_count FROM selector_sector WHERE cur_user = current_user;
		IF v_count = 0 THEN
			RETURN ('{"status":"Failed","message":{"level":1, "text":"There is no sector selected. Please select at least one"}}')::json;
		END IF;

		-- force only state 1 selector
		DELETE FROM selector_state WHERE cur_user=current_user;
		INSERT INTO selector_state (state_id, cur_user) VALUES (1, current_user);

		-- create temp tables
		PERFORM gw_fct_manage_temp_tables('{"data":{"parameters":{"fid":227, "project_type":"WS", "action":"DROP", "group":"EPAMAIN"}}}');
		PERFORM gw_fct_manage_temp_tables('{"data":{"parameters":{"fid":227, "project_type":"WS", "action":"CREATE", "group":"EPAMAIN"}}}');

		-- getting selectors
		SELECT array_agg(expl_id) INTO v_expl_id FROM selector_expl WHERE expl_id > 0 AND cur_user = current_user;
		SELECT array_agg(sector_id) INTO v_sector_id FROM selector_sector WHERE sector_id > 0 AND cur_user = current_user;
		SELECT value::integer INTO v_network_type FROM config_param_user WHERE parameter = 'inp_options_networkmode' AND cur_user = current_user;
		SELECT value INTO v_flow_units FROM config_param_user WHERE parameter = 'inp_options_units' AND cur_user = current_user;
		SELECT value INTO v_quality_units FROM config_param_user WHERE parameter = 'inp_options_quality_mode' AND cur_user = current_user;

		IF v_quality_units = 'AGE' THEN
			v_quality_units = 'hours';
		ELSIF v_quality_units = 'TRACE' THEN
			v_quality_units = concat(v_quality_units, ' % - ', (SELECT value FROM config_param_user WHERE parameter = 'inp_options_node_id' AND cur_user = current_user));
		ELSIF v_quality_units = 'NONE' THEN
			v_quality_units = NULL;
		ELSIF v_quality_units = 'CHEMICAL mg/L' THEN
			v_quality_units = 'mg/L';
		ELSIF v_quality_units = 'CHEMICAL ug/L' THEN
			v_quality_units = 'ug/L';
		END IF;


		IF v_network_type = 1 THEN
			SELECT array_agg(dma_id) INTO v_dma_id FROM dma WHERE dma_type = 'TRANSMISSION' AND dma_id > 0;
		ELSIF v_network_type = 5 THEN
			IF (SELECT value::integer FROM config_param_user WHERE parameter = 'inp_options_selecteddma' AND cur_user = current_user) IS NOT NULL THEN
				SELECT array_agg(dma_id) INTO v_dma_id FROM dma WHERE dma_id = (SELECT value::integer FROM config_param_user WHERE parameter = 'inp_options_selecteddma' AND cur_user = current_user);
			ELSE
				SELECT error_message INTO v_message FROM sys_message WHERE id = 4360;

				RETURN ('{"status":"Failed","message":{"level":1, "text":"'||v_message||'"}}')::json;
			END IF;
		END IF;

		-- setting selectors
		v_inpoptions = (SELECT (replace (replace (replace (array_to_json(array_agg(json_build_object((t.parameter),(t.value))))::text,'},{', ' , '),'[',''),']',''))::json
			FROM (SELECT parameter, value FROM config_param_user
			JOIN sys_param_user a ON a.id=parameter	WHERE cur_user=current_user AND formname='epaoptions')t);

		DELETE FROM rpt_cat_result WHERE result_id=v_result;
		INSERT INTO rpt_cat_result (result_id, inp_options, status, expl_id, sector_id, network_type, dma_id, flow_units, quality_units)
			VALUES (v_result, v_inpoptions, 1, v_expl_id, v_sector_id, v_network_type, v_dma_id, v_flow_units, v_quality_units);
		DELETE FROM rpt_inp_pattern_value WHERE result_id=v_result;
		DELETE FROM selector_inp_result WHERE cur_user=current_user;
		INSERT INTO selector_inp_result (result_id, cur_user) VALUES (v_result, current_user);

		-- save previous values to set hydrometer selector
		DELETE FROM temp_t_table WHERE fid=435 AND cur_user=current_user;
		INSERT INTO temp_t_table (fid, text_column)
		SELECT 435, (array_agg(id)) FROM v_cat_hydrometer_state;

		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 1/7 - Preprocess workflow...... done succesfully"}}'::json;
		RETURN v_return;

	-- step 2: autorepair epa-type
	ELSIF v_step = 2 THEN

		PERFORM gw_fct_pg2epa_autorepair_epatype($${"client":{"device":4, "infoType":1, "lang":"ES"}}$$);
		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 2/7 - Autorepair epa_type...... done succesfully"}}'::json;
		RETURN v_return;

	-- step 3: check data
	ELSIF v_step = 3 THEN

		PERFORM gw_fct_pg2epa_check_data(v_input);
		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 3/7 - Check according EPA rules...... done succesfully"}}'::json;
		RETURN v_return;

	-- step 4: structure data
	ELSIF v_step = 4 THEN

		-- get user parameteres
		v_networkmode = (SELECT value FROM config_param_user WHERE parameter='inp_options_networkmode' AND cur_user=current_user);
		IF v_networkmode = 1 THEN v_onlymandatory_nodarc = TRUE; END IF;

		v_buildupmode = (SELECT value FROM config_param_user WHERE parameter='inp_options_buildup_mode' AND cur_user=current_user);
		v_advancedsettings = (SELECT value::json->>'status' FROM config_param_user WHERE parameter='inp_options_advancedsettings' AND cur_user=current_user)::boolean;
		v_vdefault = (SELECT value::json->>'status' FROM config_param_user WHERE parameter='inp_options_vdefault' AND cur_user=current_user);
		IF (SELECT count(expl_id) FROM selector_expl WHERE cur_user = current_user) = 1 THEN
			v_expl = (SELECT expl_id FROM selector_expl WHERE cur_user = current_user);
		END IF;

		-- get debug parameters
		v_setdemand = (SELECT value::json->>'setDemand' FROM config_param_user WHERE parameter='inp_options_debug' AND cur_user=current_user)::boolean;
		v_breakpipes = (SELECT (value::json->>'breakPipes')::json->>'status' FROM config_param_user WHERE parameter='inp_options_debug' AND cur_user=current_user)::boolean;

		RAISE NOTICE '4.1 - Fill temp tables';
		PERFORM gw_fct_pg2epa_fill_data(v_result);

		RAISE NOTICE '4.2 - Call gw_fct_pg2epa_nod2arc function';
		PERFORM gw_fct_pg2epa_nod2arc(v_result, v_onlymandatory_nodarc, false);

		RAISE NOTICE '4.3 - Call gw_fct_pg2epa_doublenod2arc';
		PERFORM gw_fct_pg2epa_nod2arc_double(v_result);

		RAISE NOTICE '4.4 - Call gw_fct_pg2epa_flwreg2arc function';
		PERFORM gw_fct_pg2epa_flwreg2arc(v_result);

		RAISE NOTICE '4.5 - manage varcs';
		PERFORM gw_fct_pg2epa_manage_varc(v_result);

		RAISE NOTICE '4.6 - Trim arcs';
		IF v_networkmode IN (3,4) THEN

			IF v_breakpipes THEN
				PERFORM gw_fct_pg2epa_breakpipes(v_result);
			END IF;
			-- execute vnodetrim arcs
			SELECT gw_fct_pg2epa_vnodetrimarcs(v_result) INTO v_response;
		END IF;

		RAISE NOTICE '4.7 - Execute buildup model';
		IF v_buildupmode = 1 THEN
			PERFORM gw_fct_pg2epa_buildup_supply(v_result);

		ELSIF v_buildupmode = 2 THEN
			PERFORM gw_fct_pg2epa_buildup_transport(v_result);
		END IF;

		RAISE NOTICE '4.8 - Set default values';
		IF v_vdefault THEN
			PERFORM gw_fct_pg2epa_vdefault(v_input);
		END IF;

		RAISE NOTICE '4.9 - Set ceros';
		UPDATE temp_t_node SET top_elev = 0 WHERE top_elev IS NULL;
		UPDATE temp_t_node SET addparam = replace (addparam, '""','null');

		RAISE NOTICE '4.10 - Set length > 0.05 when length is 0';
		UPDATE temp_t_arc SET length=0.05 WHERE length=0;

		RAISE NOTICE '4.11 - Set demands & patterns';
		IF v_setdemand THEN
			PERFORM gw_fct_pg2epa_demand(v_result);
		END IF;

		RAISE NOTICE '4.12 - Setting valve status';
		PERFORM gw_fct_pg2epa_valve_status(v_result);


		RAISE NOTICE '4.13 - Profilactic last control';

		-- update diameter when is null USING neighbourg from node_1
		UPDATE temp_t_arc SET diameter = dint FROM (
		SELECT node_1 as n1, diameter dint FROM temp_t_arc UNION SELECT node_2, diameter FROM temp_t_arc
		)t WHERE t.dint IS NOT NULL AND t.n1 = node_1 AND diameter IS NULL;
		UPDATE temp_t_arc SET diameter = dint FROM (
		SELECT node_1 as n1, diameter dint FROM temp_t_arc UNION SELECT node_2, diameter FROM temp_t_arc
		)t WHERE t.dint IS NOT NULL AND t.n1 = node_2 AND diameter IS NULL;

		-- update diameter when is null USING neighbourg from node_2
		UPDATE temp_t_arc SET diameter = dint FROM (
		SELECT node_1 as n2, diameter dint FROM temp_t_arc UNION SELECT node_2, diameter FROM temp_t_arc
		)t WHERE t.dint IS NOT NULL AND t.n2 = node_1 AND diameter IS NULL;
		UPDATE temp_t_arc SET diameter = dint FROM (
		SELECT node_2 as n2, diameter dint FROM temp_t_arc UNION SELECT node_2, diameter FROM temp_t_arc
		)t WHERE t.dint IS NOT NULL AND t.n2 = node_2 AND diameter IS NULL;

		-- update roughness for shortpipes and valves using neighbourg
		update temp_arc t set roughness = rough from (
		select a.arc_id, (avg(a1.roughness))::numeric(12,3) as rough,
		a.epa_type from temp_arc a
		left join temp_arc a1 on (a1.node_1 = a.node_1 or a1.node_2= a.node_1 or a1.node_1 = a.node_2 or a1.node_2= a.node_2)
		where a.epa_type in ('SHORTPIPE', 'VALVE') and a.arc_id != a1.arc_id group by 1,3
		) a where t.arc_id = a.arc_id;

		-- other null values
		UPDATE temp_t_arc SET minorloss = 0 WHERE minorloss IS NULL;

		UPDATE temp_t_arc SET epa_type = 'VIRTUALVALVE' FROM arc WHERE arc.epa_type  ='VIRTUALVALVE' AND arc.arc_id::text = temp_t_arc.arc_id;

		-- for those elements like filter o flowmeter which they do not have the attribute on the inventory table
		UPDATE temp_t_arc SET status = 'OPEN' WHERE status IS NULL OR status = '';

		UPDATE temp_t_node SET dqa_id = 0 WHERE dqa_id IS NULL;
		UPDATE temp_t_arc SET dqa_id = 0 WHERE dqa_id IS NULL;

		UPDATE temp_t_node SET dma_id = 0 WHERE dma_id IS NULL;
		UPDATE temp_t_arc SET dma_id = 0 WHERE dma_id IS NULL;

		UPDATE temp_t_node SET presszone_id = 0 WHERE presszone_id IS NULL;
		UPDATE temp_t_arc SET presszone_id = 0 WHERE presszone_id IS NULL;

		-- remove pattern when breakPipes is enabled
		IF v_breakpipes THEN
			UPDATE temp_t_node n SET pattern_id  = null , demand = 0 FROM temp_table t WHERE n.node_id = concat('VN',t.id);
		END IF;

		RAISE NOTICE '4.14 - Update values for temp table';
		UPDATE temp_t_arc SET result_id  = v_result;
		UPDATE temp_t_node SET result_id  = v_result;

		PERFORM gw_fct_pg2epa_dscenario(v_result);

		-- move patterns used
		INSERT INTO t_rpt_inp_pattern_value (result_id, pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8, 
		factor_9, factor_10, factor_11, factor_12, factor_13, factor_14, factor_15, factor_16, factor_17, factor_18)
		SELECT v_result, pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8,
		factor_9, factor_10, factor_11, factor_12, factor_13, factor_14, factor_15, factor_16, factor_17, factor_18
		FROM inp_pattern_value p
		WHERE pattern_id IN (
			SELECT DISTINCT (pattern_id) FROM temp_t_demand WHERE pattern_id IS NOT NULL
			UNION
			SELECT DISTINCT (pattern_id) FROM temp_t_node WHERE pattern_id IS NOT NULL
		)
		ORDER BY pattern_id, id;

		v_userscenario = (SELECT array_agg(dscenario_id) FROM selector_inp_dscenario where cur_user=current_user);
		DELETE FROM t_rpt_inp_pattern_value WHERE result_id = v_result AND pattern_id IN (
			SELECT DISTINCT (pattern_id)
			FROM inp_dscenario_pattern p
			WHERE p.dscenario_id IN (SELECT unnest(v_userscenario))
		);
		INSERT INTO t_rpt_inp_pattern_value (result_id, pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8, 
		factor_9, factor_10, factor_11, factor_12, factor_13, factor_14, factor_15, factor_16, factor_17, factor_18)
		SELECT v_result, pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8,
		factor_9, factor_10, factor_11, factor_12, factor_13, factor_14, factor_15, factor_16, factor_17, factor_18
		FROM inp_dscenario_pattern_value p
		WHERE p.pattern_id IN (
			SELECT DISTINCT (pattern_id) FROM temp_t_demand WHERE pattern_id IS NOT NULL
			UNION
			SELECT DISTINCT (pattern_id) FROM temp_t_node WHERE pattern_id IS NOT NULL
		)
		AND p.dscenario_id IN (SELECT unnest(v_userscenario))
		ORDER BY pattern_id, id;

		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 4/7 - Structure data...... done succesfully"}}'::json;
		RETURN v_return;

	-- step 5: analyze graph
	ELSIF v_step=5 THEN

		PERFORM gw_fct_pg2epa_check_network(v_input);
		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 5/7 - Graph analysis...... done succesfully"}}'::json;
		RETURN v_return;

	-- step 6: create json return
	ELSIF v_step=6 THEN

		PERFORM gw_fct_pg2epa_check_result(v_input);

		-- deleting arcs without nodes
		UPDATE temp_t_arc t SET epa_type = 'TODELETE' FROM (SELECT a.id FROM temp_t_arc a LEFT JOIN temp_t_node ON node_1=node_id WHERE temp_t_node.node_id is null) a WHERE t.id = a.id;
		UPDATE temp_t_arc t SET epa_type = 'TODELETE' FROM (SELECT a.id FROM temp_t_arc a LEFT JOIN temp_t_node ON node_2=node_id WHERE temp_t_node.node_id is null) a WHERE t.id = a.id;
		DELETE FROM temp_t_arc WHERE epa_type = 'TODELETE';
		UPDATE temp_t_arc SET result_id = v_result WHERE result_id IS NULL;
		UPDATE temp_t_node SET result_id = v_result WHERE result_id IS NULL;

		-- deleting nodes without arcs
		UPDATE temp_t_node t SET epa_type = 'TODELETE' FROM
		(SELECT id FROM temp_t_node LEFT JOIN (SELECT node_1 as node_id FROM temp_t_arc UNION SELECT node_2 FROM temp_t_arc) a USING (node_id) WHERE a.node_id IS NULL) a
		WHERE t.id = a.id;
		DELETE FROM temp_t_node WHERE epa_type = 'TODELETE';

		-- create return
		EXECUTE 'SELECT gw_fct_create_return($${"data":{"parameters":{"fid":2646, "isEmbebed":false}}}$$::json)' INTO v_return;
		SELECT gw_fct_pg2epa_export_inp(p_data) INTO v_file;
		v_body = gw_fct_json_object_set_key((v_return->>'body')::json, 'file', v_file);
		v_return = gw_fct_json_object_set_key(v_return, 'body', v_body);
		v_return = replace(v_return::text, '"message":{"level":1, "text":"Data quality analysis done succesfully"}',
		'"message":{"level":1, "text":"Export INP file 6/7 - Writing the INP file...... done succesfully"}')::json;

		RETURN v_return;

	-- step 7: post-proces
	ELSIF v_step=7 THEN

		-- move nodes data
		INSERT INTO rpt_inp_node (result_id, node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, demand,
		the_geom, expl_id, pattern_id, addparam, nodeparent, arcposition,dma_id, presszone_id, dqa_id, minsector_id, builtdate)
		SELECT result_id, node_id, top_elev, case when elev is null then top_elev else elev end, node_type, nodecat_id, epa_type, sector_id, state,
		state_type, annotation, demand, the_geom, expl_id, pattern_id, addparam, nodeparent, arcposition,dma_id, presszone_id, dqa_id, minsector_id, builtdate
		FROM temp_t_node;

		-- move arcs data
		INSERT INTO rpt_inp_arc
		(result_id, arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, diameter, roughness, length, status,
		the_geom, expl_id, flw_code, minorloss, addparam, arcparent,dma_id, presszone_id, dqa_id, minsector_id, age, family, builtdate)
		SELECT result_id, arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, diameter, roughness, length,
		status, the_geom, expl_id, flw_code, minorloss, addparam, arcparent,dma_id, presszone_id, dqa_id, minsector_id, age, family, builtdate
		FROM temp_t_arc;

		-- move result data
		UPDATE rpt_cat_result r set network_stats = t.network_stats FROM t_rpt_cat_result t WHERE r.result_id = t.result_id;

		-- move patterns data
		INSERT INTO rpt_inp_pattern_value SELECT * FROM t_rpt_inp_pattern_value;

		-- drop temp tables
		PERFORM gw_fct_manage_temp_tables('{"data":{"parameters":{"fid":227, "project_type":"WS", "action":"DROP", "group":"EPAMAIN"}}}');

		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 7/7 - Postprocess workflow...... done succesfully"}}'::json;
		RETURN v_return;

	END IF;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	PERFORM gw_fct_manage_temp_tables('{"data":{"parameters":{"fid":227, "project_type":"WS", "action":"DROP", "group":"EPAMAIN"}}}');
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
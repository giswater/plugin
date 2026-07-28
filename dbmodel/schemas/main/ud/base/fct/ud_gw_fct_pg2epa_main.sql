/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2894

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_pg2epa(character varying, boolean, boolean, boolean);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_pg2epa(character varying, boolean, boolean);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_pg2epa(json);
CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_pg2epa_main(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"1"}}$$); -- PRE-PROCESS
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"2"}}$$); -- AUTOREPAIR
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"3"}}$$); -- CHECK DATA
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"4"}}$$); -- STRUCTURE DATA
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"5"}}$$); -- CHECK GRAPH
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"6"}}$$); -- BUILD INP
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"7"}}$$); -- POST-PROCESS

-- fid: 227

*/

DECLARE

v_return json;
v_result text;
v_dumpsubcatch boolean;
v_inpoptions json;
v_file json;
v_body json;
v_advancedsettings boolean;
v_input json;
v_vdefault boolean;
v_error_context text;
v_count integer;
v_message text;
v_step integer=0;
v_expl integer = null;
v_sector_0 boolean = false;
v_expl_id integer[];
v_sector_id integer[];
v_network_type integer;
v_client_epsg integer;



BEGIN

	-- set search path
	SET search_path = "SCHEMA_NAME", public;

	-- get input data
	v_result =  (p_data->>'data')::json->>'resultId';
	v_dumpsubcatch = NULLIF((p_data->>'data')::json->>'dumpSubcatch', '')::boolean;
	v_step = (p_data->>'data')::json->>'step';
	v_input = concat('{"data":{"parameters":{"isEmbebed":true, "resultId":"',v_result,'", "dumpSubcatch":"',v_dumpsubcatch,'", "fid":227}}}')::json;


	-- get user parameters
	v_advancedsettings = (SELECT value::json->>'status' FROM config_param_user WHERE parameter='inp_options_advancedsettings' AND cur_user=current_user)::boolean;
	v_vdefault = (SELECT value::json->>'status' FROM config_param_user WHERE parameter='inp_options_vdefault' AND cur_user=current_user);

	IF (SELECT count(expl_id) FROM selector_expl WHERE cur_user = current_user) = 1 THEN
		v_expl = (SELECT expl_id FROM selector_expl WHERE cur_user = current_user);
	END IF;


	-- step 1: pre-process
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

		-- drop profilactic temp table of polygon
		DROP TABLE IF EXISTS temp_anl_polygon;

		-- check consistency for user options
		SELECT gw_fct_pg2epa_check_options(v_input) INTO v_return;
		IF v_return->>'status' = 'Failed' THEN
			RETURN v_return;
		END IF;

		-- check sector selector
		SELECT count(*) INTO v_count FROM selector_sector WHERE cur_user = current_user AND sector_id > 0;
		IF v_count = 0 THEN
			RETURN ('{"status":"Failed","message":{"level":1, "text":"There is no sector selected. Please select at least one"}}')::json;
		END IF;

		-- force only state 1 selector
		DELETE FROM selector_state WHERE cur_user=current_user;
		INSERT INTO selector_state (state_id, cur_user) VALUES (1, current_user);

		-- create temp tables
		PERFORM gw_fct_manage_temp_tables('{"data":{"parameters":{"fid":227, "project_type":"UD", "action":"CREATE", "group":"EPAMAIN"}}}');

		-- getting selectors
		SELECT array_agg(expl_id) INTO v_expl_id FROM selector_expl WHERE expl_id > 0 AND cur_user = current_user;
		SELECT array_agg(sector_id) INTO v_sector_id FROM selector_sector WHERE sector_id > 0 AND cur_user = current_user;
		SELECT value::integer INTO v_network_type FROM config_param_user WHERE parameter = 'inp_options_networkmode' AND cur_user = current_user;

		-- setting selectors
		v_inpoptions = (SELECT (replace (replace (replace (array_to_json(array_agg(json_build_object((t.parameter),(t.value))))::text,'},{', ' , '),'[',''),']',''))::json
				FROM (SELECT parameter, value FROM config_param_user
				JOIN sys_param_user a ON a.id=parameter	WHERE cur_user=current_user AND formname='epaoptions')t);

		-- setting selectors
		DELETE FROM rpt_cat_result WHERE result_id=v_result;
		INSERT INTO rpt_cat_result (result_id, inp_options, status, expl_id, sector_id, network_type)
			VALUES (v_result, v_inpoptions, 1, v_expl_id, v_sector_id, v_network_type);
		DELETE FROM selector_inp_result WHERE cur_user=current_user;
		INSERT INTO selector_inp_result (result_id, cur_user) VALUES (v_result, current_user);

		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 1/7 - Preprocess workflow...... done succesfully"}}'::json;
		RETURN v_return;

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

		RAISE NOTICE '4.1 - Fill temp tables';
		PERFORM gw_fct_pg2epa_fill_data(v_result);

		RAISE NOTICE '4.2 - Manage varcs';
		PERFORM gw_fct_pg2epa_manage_varc(v_result);

		RAISE NOTICE '4.3 - Call nod2arc function';
		PERFORM gw_fct_pg2epa_nod2arc(v_result);

		RAISE NOTICE '4.4 - Dump subcatchments';
		IF v_dumpsubcatch THEN
			PERFORM gw_fct_pg2epa_dump_subcatch(p_data);
		END IF;

		RAISE NOTICE '4.5 - Set default values';
		IF v_vdefault THEN
			PERFORM gw_fct_pg2epa_vdefault(v_input);
		END IF;

		RAISE NOTICE '4.6 - dscenario';
		PERFORM gw_fct_pg2epa_dscenario(v_result);

		RAISE NOTICE '4.7 - Advanced settings';
		IF v_advancedsettings THEN
			PERFORM gw_fct_pg2epa_advancedsettings(v_result);
		END IF;

		RAISE NOTICE '4.8 - Update values for temp table';
		UPDATE temp_t_arc SET result_id  = v_result;
		UPDATE temp_t_node SET result_id  = v_result;

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

		-- move arcs data
		INSERT INTO rpt_inp_arc (result_id, arc_id, node_1, node_2, elevmax1, elevmax2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation,
		length, n, the_geom, expl_id, addparam, arcparent, q0, qmax, barrels, slope, culvert, kentry, kexit, kavg, flap, seepage)
		SELECT
		result_id, arc_id, node_1, node_2, elevmax1, elevmax2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation,
		length, n, the_geom, expl_id, addparam, arcparent, q0, qmax, barrels, slope, culvert, kentry, kexit, kavg, flap, seepage
		FROM temp_t_arc;

		-- move nodes data
		INSERT INTO rpt_inp_node (result_id, node_id, top_elev, ymax, elev, node_type, nodecat_id,
		epa_type, sector_id, state, state_type, annotation, y0, ysur, apond, the_geom, expl_id, addparam, parent, arcposition, fusioned_node)
		SELECT result_id, node_id, top_elev, ymax, elev, node_type, nodecat_id, epa_type,
		sector_id, state, state_type, annotation, y0, ysur, apond, the_geom, expl_id, addparam, parent, arcposition, fusioned_node
		FROM temp_t_node;

		-- move result data
		UPDATE rpt_cat_result r set network_stats = t.network_stats FROM t_rpt_cat_result t WHERE r.result_id = t.result_id;

		-- drop temp tables
		PERFORM gw_fct_manage_temp_tables('{"data":{"parameters":{"fid":227, "project_type":"UD", "action":"DROP", "group":"EPAMAIN"}}}');

		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Export INP file 7/7 - Check according EPA rules...... done succesfully"}}'::json;
		RETURN v_return;
	END IF;

	--  Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	PERFORM gw_fct_manage_temp_tables('{"data":{"parameters":{"fid":227, "project_type":"UD", "action":"DROP", "group":"EPAMAIN"}}}');
	RETURN ('{"status":"Failed", "level": ' || to_json(right(SQLSTATE, 1)) || ',"text": ' || to_json(SQLERRM) || ', "body":{"data":{"info":{"values":[{"message":'||to_json(SQLERRM)||'}]}}}, "NOSQLERR":' ||
	to_json(SQLERRM) || ',"SQLSTATE":' || to_json(SQLSTATE) ||',"SQLCONTEXT":' || to_json(v_error_context) || '}')::json;


END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

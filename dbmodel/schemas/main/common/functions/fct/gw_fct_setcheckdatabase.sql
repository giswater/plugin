/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3364

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setcheckdatabase (p_data json)
  RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_setcheckdatabase($${"data":{"parameters":{"omCheck":true, "graphCheck":false, "epaCheck":false, "planCheck":false, "adminCheck":false, "verifiedExceptions":false}}}$$);

fid  =604
*/

DECLARE

v_project_type text;
v_version text;
v_epsg integer;
v_return json;
v_schemaname text;
v_error_context text;

v_verified_exceptions boolean = true;
v_omcheck boolean = true;
v_graphcheck boolean = true;
v_epacheck boolean = true;
v_plancheck boolean = true;
v_admincheck boolean = true;

v_fid integer = 604;

v_querytext TEXT;
v_rec record;
v_result_info JSON;
v_result_point JSON;
v_result_line JSON;
v_result_polygon JSON;

BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	SELECT project_type, giswater, epsg INTO v_project_type, v_version, v_epsg FROM sys_version order by id desc limit 1;

	-- Get input parameters
	v_verified_exceptions := ((p_data ->> 'data')::json->>'parameters')::json->> 'tab_data_verified_exceptions';
	v_omcheck :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'tab_data_om_check';
	v_graphcheck :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'tab_data_graph_check';
	v_epacheck :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'tab_data_epa_check';
	v_plancheck :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'tab_data_plan_check';
	v_admincheck :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'tab_data_admin_check';

	-- create temp tables (OMCHECK first so t_arc/t_node exist for EPA copy)
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"CREATE", "group":"LOG"}}}$$)';
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"CREATE", "group":"ANL"}}}$$)';
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"CREATE", "group":"OMCHECK", "verifiedExceptions":'||COALESCE(v_verified_exceptions::text, 'false')||'}}}$$)';
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"CREATE", "group":"MAPZONES", "subGroup":"ALL"}}}$$)';
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"CREATE", "group":"EPA"}}}$$)';

	-- EPA checks read temp_t_* / pgr; CREATE EPA leaves them empty (fill_data only runs in go2epa)
	IF v_epacheck IS TRUE THEN

		IF lower(v_project_type) = 'ws' THEN

			INSERT INTO temp_t_arc (arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, length, dma_id, presszone_id, dqa_id, minsector_id, omzone_id, builtdate)
			SELECT arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, COALESCE(custom_length, st_length2d(the_geom)), dma_id, presszone_id, dqa_id,
				minsector_id, omzone_id, builtdate
			FROM t_arc;

			INSERT INTO temp_t_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, omzone_id, builtdate)
			SELECT node_id, top_elev, top_elev - depth, node_type, nodecat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, omzone_id, builtdate
			FROM t_node;

			INSERT INTO temp_t_pgr_go2epa_arc (arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, length, dma_id, presszone_id, dqa_id, minsector_id, omzone_id, builtdate)
			SELECT arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, length, dma_id, presszone_id, dqa_id, minsector_id, omzone_id, builtdate
			FROM temp_t_arc;

			INSERT INTO temp_t_pgr_go2epa_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, omzone_id, builtdate)
			SELECT node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type,
				annotation, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, omzone_id, builtdate
			FROM temp_t_node;

		ELSIF lower(v_project_type) = 'ud' THEN

			INSERT INTO temp_t_arc (arc_id, node_1, node_2, elevmax1, elevmax2, arc_type, arccat_id, epa_type, sector_id, state,
				state_type, annotation, omzone_id, length, expl_id, the_geom)
			SELECT arc_id, node_1, node_2,
				COALESCE(custom_elev1, elev1), COALESCE(custom_elev2, elev2),
				arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, omzone_id,
				COALESCE(custom_length, st_length2d(the_geom)), expl_id, the_geom
			FROM t_arc;

			INSERT INTO temp_t_node (node_id, top_elev, ymax, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type,
				annotation, omzone_id, expl_id, the_geom)
			SELECT node_id, COALESCE(custom_top_elev, top_elev), ymax, COALESCE(custom_elev, elev), node_type, nodecat_id, epa_type,
				sector_id, state, state_type, annotation, omzone_id, expl_id, the_geom
			FROM t_node;

			INSERT INTO temp_t_gully (gully_id, gully_type, arc_id, sector_id, state, state_type, top_elev, width, length, the_geom)
			SELECT gully_id, gully_type, arc_id, sector_id, state, state_type, top_elev, width, length, the_geom
			FROM t_gully;

			INSERT INTO temp_t_pgr_go2epa_arc (arc_id, node_1, node_2, elevmax1, elevmax2, arc_type, arccat_id, epa_type, sector_id,
				state, state_type, annotation, omzone_id, length, expl_id, the_geom)
			SELECT arc_id, node_1, node_2, elevmax1, elevmax2, arc_type, arccat_id, epa_type, sector_id,
				state, state_type, annotation, omzone_id, length, expl_id, the_geom
			FROM temp_t_arc;

		END IF;

	END IF;

	-- create log tables
	EXECUTE 'SELECT gw_fct_create_logtables($${"data":{"parameters":{"fid":604}}}$$::json)';

	FOR v_rec IN
		SELECT DISTINCT f.fid
		FROM sys_fprocess f
		JOIN (
			SELECT 'om_check' AS check_data, v_omcheck AS val UNION ALL
			SELECT 'graph_check', v_graphcheck UNION ALL
			SELECT 'pg2epa_check_data', v_epacheck UNION ALL
			SELECT 'plan_check', v_plancheck UNION ALL
			SELECT 'admin_check', v_admincheck
		) t ON t.val IS TRUE AND f.function_name ILIKE '%' || t.check_data || '%'
		WHERE f.project_type IN (lower(v_project_type), 'utils')
			AND f.addparam IS NULL
			AND f.query_text IS NOT NULL
			AND f.active
		ORDER BY f.fid
	LOOP
		EXECUTE 'SELECT gw_fct_check_fprocess($${"client":{"device":4, "infoType":1, "lang":"ES"},
		"form":{},"feature":{},"data":{"parameters":{"functionFid": '||v_fid||', "checkFid":"'||v_rec.fid||'"}}}$$)';
	END LOOP;

	EXECUTE 'SELECT gw_fct_user_check_data($${"data":{"parameters":{"fid":'||v_fid||', "isEmbebed":true, "isAudit":true, "checkType": "Project"}}}$$)';

	-- materialize tables
	PERFORM gw_fct_create_logreturn($${"data":{"parameters":{"type":"fillExcepTables"}}}$$::json);

	-- create json return to send client
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"info"}}}$$::json)' INTO v_result_info;
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"point"}}}$$::json)' INTO v_result_point;
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"line"}}}$$::json)' INTO v_result_line;
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"polygon"}}}$$::json)' INTO v_result_polygon;

	-- drop temp tables
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"DROP", "group":"ANL"}}}$$)';

	-- Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Data quality analysis done succesfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||','||
				'"line":'||v_result_line||','||
				'"polygon":'||v_result_polygon||
		       '}'||
	    '}}')::json, 2670, null, null, null);

	--  Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
--FUNCTION CODE: 3040

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_anl_arc_duplicated(p_data json) RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_anl_arc_duplicated($${"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"tableName":"ve_node", "featureType":"NODE", "id":[]},
"data":{"filterFields":{}, "pageInfo":{}, "selectionMode":"wholeSelection",
"parameters":{"checkType":"finalNodes"}}}$$)::JSON

-- fid: 479

*/

DECLARE

v_id json;
v_selectionmode text;
v_worklayer text;
v_result json;
v_result_info json;
v_result_line json;
v_array integer[];
v_version text;
v_error_context text;
v_count integer;
v_checktype text;
v_fid integer = 479;

-- query variables
v_query_text text;


BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- select version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- getting input data
	v_id :=  ((p_data ->>'feature')::json->>'id')::json;
	v_worklayer := ((p_data ->>'feature')::json->>'tableName')::text;
	v_selectionmode :=  ((p_data ->>'data')::json->>'selectionMode')::text;
	v_checktype := ((p_data ->>'data')::json->>'parameters')::json->>'checkType';

	v_array := (SELECT array_agg(a::integer) FROM json_array_elements_text(v_id) a);

	-- Reset values
	DROP TABLE IF EXISTS temp_anl_arc;
	DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid;

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"3040", "fid":"'||v_fid||'", "criticity":"4", "is_process":true, "is_header":"true"}}$$)';

	-- Computing process
	IF v_checktype='geometry' THEN
		IF v_selectionmode = 'previousSelection' THEN
			v_query_text := 'WHERE va1.arc_id = ANY(' || quote_literal(v_array) || ') AND va2.arc_id = ANY(' || quote_literal(v_array) || ')';
		ELSE
			v_query_text := '';
		END IF;

		EXECUTE format($sql$
			CREATE TEMP TABLE temp_anl_arc AS
			SELECT a.arc_id, a.arccat_id, a.state, ta.arc_id_aux, a.node_1, a.node_2, a.expl_id, a.the_geom
			FROM (
				SELECT va1.arc_id, MIN(va2.arc_id) AS arc_id_aux
				FROM %I va1
				JOIN %I va2 ON va1.the_geom && va2.the_geom
						AND ST_Equals(va1.the_geom, va2.the_geom)
				GROUP BY va1.arc_id
				HAVING COUNT(*) > 1
				%s
			) ta
			JOIN arc a ON ta.arc_id = a.arc_id
			WHERE EXISTS (SELECT 1 FROM vf_arc vfa WHERE vfa.arc_id = a.arc_id)
		$sql$, v_worklayer, v_worklayer, v_query_text);

	ELSIF v_checktype='finalNodes' THEN
		IF v_selectionmode = 'previousSelection' THEN
			v_query_text := 'AND BOOL_OR(va.arc_id = ANY(' || quote_literal(v_array) || '))';
		ELSE
			v_query_text := '';
		END IF;

		EXECUTE format($sql$
			CREATE TEMP TABLE temp_anl_arc AS
			SELECT a.arc_id, a.arccat_id, a.state, ta.arc_id_aux, a.node_1, a.node_2, a.expl_id, a.the_geom
			FROM (
				SELECT least(va.node_1,va.node_2) AS least_node_1, greatest(va.node_1,va.node_2) AS greatest_node_2, min(va.arc_id) AS arc_id_aux
				FROM %I va
				GROUP BY least(va.node_1,va.node_2), greatest(va.node_1,va.node_2)
				HAVING COUNT(*) > 1
				%s
			) ta
			JOIN arc a ON (a.node_1 = ta.least_node_1 AND a.node_2 = ta.greatest_node_2)
					OR (a.node_1 = ta.greatest_node_2 AND a.node_2 = ta.least_node_1)
			WHERE EXISTS (SELECT 1 FROM vf_arc vfa WHERE vfa.arc_id = a.arc_id)
		$sql$, v_worklayer, v_query_text);
	END IF;

	-- set selector
	DELETE FROM selector_audit WHERE fid=v_fid AND cur_user=current_user;
	INSERT INTO selector_audit (fid,cur_user) VALUES (v_fid, current_user);

	-- get results
	--points
	v_result = null;
	SELECT jsonb_build_object(
	    'type', 'FeatureCollection',
	    'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
	) INTO v_result
	FROM (
	SELECT jsonb_build_object(
	     'type',       'Feature',
	   'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
	    'properties', to_jsonb(row) - 'the_geom'
	  	) AS feature
	  	FROM (SELECT arc_id, arc_id_aux, arccat_id, state,  node_1, node_2, expl_id, ST_Transform(the_geom, 4326) as the_geom
	  	FROM  temp_anl_arc) row) features;

	v_result_line := COALESCE(v_result, '{}');

	IF v_checktype='finalNodes' THEN
		SELECT count(*) INTO v_count FROM temp_anl_arc;
	ELSE
		SELECT count(*)/2 INTO v_count FROM temp_anl_arc;
	END IF;


	IF v_count = 0 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3574", "function":"3040", "fid":"'||v_fid||'", "fcount":"'||v_count||'", "is_process":true}}$$)';

	ELSE
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3576", "function":"3040", "fid":"'||v_fid||'", "parameters":{"v_count":"'||v_count||'"}, "fcount":"'||v_count||'", "is_process":true}}$$)';

		INSERT INTO audit_check_data(fid,  error_message, fcount)
		SELECT v_fid, concat('Arc_id: ', array_agg(arc_id), '.'), v_count
		FROM temp_anl_arc;

	END IF;

	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid order by  id asc) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_line := COALESCE(v_result_line, '{}');

	-- Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
	             ',"body":{"form":{}'||
			     ',"data":{ "info":'||v_result_info||','||
					'"line":'||v_result_line||
				'}}'||
		    '}')::json, 3040, null, null, null);

	-- Exception control
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM,  'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE,
	'SQLCONTEXT', v_error_context)::json;


END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
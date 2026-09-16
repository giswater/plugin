/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2760

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_update_elevation_from_dem(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setelevfromdem(p_data json)
  RETURNS json AS
$BODY$
/*
SELECT gw_fct_setelevfromdem($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{"tableName":"ve_connec", "featureType":"CONNEC", "id":["3235", "3239", "3197"]},
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{"updateValues":"allValues"}}}$$)::text

SELECT SCHEMA_NAME.gw_fct_setelevfromdem($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{"tableName":"node", "featureType":"NODE"},
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{ "updateValues":"allValues"}}}$$)::text

-- fid: 168

*/

DECLARE

v_schemaname text;
v_id json;
v_array text;
v_worklayer text;
v_updatevalues text;
v_saveondatabase boolean;
v_elevation numeric;
v_query text;
rec record;
v_geom text;
v_check_null_elevation record;
v_version text;
v_project_type text;
v_feature_type text;
v_result json;
v_result_info json;
v_result_point json;
v_update_field text;
v_level integer;
v_status text;
v_message text;
v_audit_result json;
v_count integer;
v_error_context text;

BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;

	-- SELECT giswater
	SELECT giswater, project_type INTO v_version, v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get input parameters
	v_schemaname = 'SCHEMA_NAME';

	v_id :=  ((p_data ->>'feature')::json->>'id')::json;
	v_worklayer := ((p_data ->>'feature')::json->>'tableName')::text;
	v_feature_type := lower(((p_data ->>'feature')::json->>'featureType'))::text;
	v_updatevalues :=  ((p_data ->>'data')::json->>'parameters')::json->>'updateValues'::text;
	v_update_field :=  ((p_data ->>'data')::json->>'parameters')::json->>'updateField'::text;

	select string_agg(quote_literal(a),',') into v_array from json_array_elements_text(v_id) a;

	DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=168;
	DELETE FROM anl_node WHERE cur_user="current_user"() AND fid=168;

	--Execute the process only if admin_raster_dem is true
	IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS FALSE THEN


		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message": "3630", "function":"2760", "fid":"168", "result_id":"elevation from raster", "is_process":true}}$$)';

	ELSIF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE THEN

		--select update field

		IF v_update_field IS NULL THEN
			SELECT json_extract_path_text(value::json,'updateField') INTO v_update_field FROM config_param_system WHERE parameter='admin_raster_dem';
		END IF;

		IF v_update_field NOT IN ('elevation', 'custom_top_elev', 'top_elev') THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3198", "function":"2760","parameters":null, "is_process":true}}$$)'
			INTO v_audit_result;

		ELSE

				--Select nodes on which the process will be executed - all values or only nulls from selected exploitation
			IF v_updatevalues = 'allValues' THEN
				IF v_project_type = 'WS' and v_feature_type='vnode' THEN
					v_query = 'SELECT '||v_feature_type||'_id as feature_id, elev as elevation, the_geom, state, expl_id FROM '||v_worklayer||'';
				ELSE
					v_query = 'SELECT '||v_feature_type||'_id as feature_id, top_elev as elevation, the_geom, state, expl_id FROM '||v_worklayer||'';
				END IF;

				--Filter features if there are only some selected
				IF v_array IS NOT NULL  THEN
					v_query = CONCAT(v_query, ' WHERE '||v_feature_type||'_id in ('||v_array||')');
				END IF;

			ELSIF v_updatevalues = 'nullValues' THEN
				IF v_project_type = 'WS' and v_feature_type='vnode' THEN
					v_query = 'SELECT '||v_feature_type||'_id as feature_id, elev as elevation, the_geom, state, expl_id FROM '||v_worklayer||' WHERE elev IS NULL';
				ELSE
					v_query = 'SELECT '||v_feature_type||'_id as feature_id, top_elev as elevation, the_geom, state, expl_id FROM '||v_worklayer||' WHERE '||v_update_field||' IS NULL';

				END IF;

				--Filter features if there are only some selected
				IF v_array IS NOT NULL  THEN
					v_query = CONCAT(v_query, ' AND '||v_feature_type||'_id in ('||v_array||')');
				END IF;

				--check if there are nodes with null values
				EXECUTE v_query INTO v_check_null_elevation;

				IF v_check_null_elevation IS NUll THEN

					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2110", "fid":"442", "criticity":"4", "is_process":true, "separator_id":"2025"}}$$)';

					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3628", "function":"2760", "fid":"168", "result_id":"elevation from raster", "is_process":true}}$$)';
				END IF;

			end if;

			--loop over selected nodes, intersect node with raster
			FOR rec IN EXECUTE v_query LOOP

				EXECUTE 'SELECT ST_Value(rast,1,$1,true) FROM v_raster_dem WHERE id =
						(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, $1, 1) LIMIT 1)'
					USING rec.the_geom
					INTO v_elevation;


				--if node is out of raster, add warning, if it's inside update value of node layer
				IF v_elevation = -9999 OR v_elevation IS NULL THEN

					--TODO
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message": "3626", "function":"2760", "fid":"168", "result_id":"elevation from raster", "prefix_id":"1002", "is_process":true, "parameters":{"feature_id":"'||rec.feature_id||'"}}}$$)';
				ELSE
					IF v_feature_type = 'vnode' THEN
						EXECUTE 'UPDATE vnode SET top_elev = '||v_elevation||'::numeric WHERE vnode_id = '||rec.feature_id||';';
					ELSIF v_feature_type != 'vnode'  THEN
						EXECUTE 'UPDATE '||v_feature_type||' SET '||v_update_field||' = '||v_elevation||' ::numeric WHERE '||v_feature_type||'_id = '||rec.feature_id||'';
					END IF;

					--temporal insert values into anl_node to create layer with all updated points
					INSERT INTO anl_node (node_id, state, expl_id, fid, the_geom, descript)
					VALUES (rec.feature_id, rec.state::integer, rec.expl_id, 168,rec.the_geom, upper(v_feature_type));

					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message": "3624", "function":"2760", "fid":"168", "result_id":"elevation from raster", "is_process":true, "parameters":{"feature_type":"'||upper(v_feature_type)||'", "feature_id":"'||rec.feature_id||'"}}}$$)';
				END IF;

			END LOOP;

		END IF;

	END IF;

	--count updated elements
	select count(*) from audit_check_data where fid = 168 and error_message like 'ELEVATION UPDATED%' and tstamp = now() into v_count;

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
    	"data":{"function":"2760", "fid":"168", "is_process":true, "separator_id":"2030"}}$$)';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message": "3622", "function":"2760", "fid":"168", "is_process":true, "parameters":{"count":"'||v_count||'", "feature_type":"'||upper(v_feature_type)||'"}}}$$)';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
    	"data":{"function":"2760", "fid":"168", "is_process":true, "separator_id":"2030"}}$$)';

	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=168 order by id desc) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

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
		FROM (SELECT id, node_id AS feature_id, state, expl_id, descript, ST_Transform(the_geom, 4326) as the_geom FROM anl_node WHERE cur_user="current_user"() AND fid=168) row) features;
	v_result := COALESCE(v_result, '{}');
	v_result_point = v_result;

	--    Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');

	IF v_audit_result is null THEN
		v_status = 'Accepted';
		v_level = 3;
		v_message = 'Process done successfully';

	ELSE

		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;

	END IF;

	--  Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
			 ',"body":{"form":{}'||
			 ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||
			'}}'||
		'}')::json,2760, null, null, null);

	-- Exception control
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM,  'message', json_build_object('level', 2, 'text', SQLERRM), 'SQLSTATE', SQLSTATE,
	'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

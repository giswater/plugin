/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 3270

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_config_mapzones(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
 SELECT SCHEMA_NAME.gw_fct_config_mapzones($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
 "parameters":{"configZone":"EXPL", "action":"PREVIEW", "nodeParent":, "toArc":}}}$$);
*/
DECLARE
    v_fid integer = 512;
    v_result json;
    v_result_info json;
    v_error_context text;
    v_version text;
    v_zone text;
    v_action text;
    v_nodeparent integer;
    v_toarc text;
    v_config text;
    rec_arc text;
    v_id text;
    v_preview json;
    v_forceclosed text;
    v_ignore text;
    v_mapzone_id text;
    v_project_type text;
    v_check_type text;
    v_audit_result text;
    v_level integer;
    v_status text;
    v_message text;
    v_use_node json;
    v_use_forceclosed json;
    v_netscenario_id integer;
    v_check_value text;
    v_use_value json;
    v_ignore_value json;
    v_forceClosed_value json;
    v_combined_use_value text;
    v_combined_ignore_value text;
    v_combined_forceClosed_value text;
BEGIN

	SET search_path = "SCHEMA_NAME", public;

	-- SELECT giswater
	SELECT giswater, project_type INTO v_version, v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

    v_zone = upper(json_extract_path_text(p_data, 'data', 'parameters', 'configZone')::TEXT);
    v_mapzone_id = lower(json_extract_path_text(p_data, 'data', 'parameters', 'mapzoneId')::TEXT);
    v_action = json_extract_path_text(p_data, 'data', 'parameters', 'action')::TEXT;
    v_nodeparent = json_extract_path_text(p_data, 'data', 'parameters', 'nodeParent')::TEXT;
    v_toarc = json_extract_path_text(p_data, 'data', 'parameters', 'toArc')::TEXT;
    v_forceclosed = json_extract_path_text(p_data, 'data', 'parameters', 'forceClosed')::TEXT;
    v_ignore = json_extract_path_text(p_data, 'data', 'parameters', 'ignore')::TEXT;
    v_config = json_extract_path_text(p_data, 'data', 'parameters', 'config')::TEXT;
    v_netscenario_id = json_extract_path_text(p_data, 'data', 'parameters', 'netscenarioId')::integer;

    -- Reset values
    DELETE FROM anl_node WHERE cur_user="current_user"() AND fid=v_fid;
    DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid;

    INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, concat('CONFIGURATION OF MAPZONES'));
    INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, '-------------------------------------------------------------');
    INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, '');

    IF v_action = 'ADD' THEN
        IF v_nodeparent IS NOT NULL THEN
            IF (v_netscenario_id IS NULL AND v_nodeparent NOT IN (SELECT node_id FROM node WHERE state = 1)) OR
               (v_netscenario_id IS NOT NULL AND v_nodeparent NOT IN (SELECT node_id FROM node WHERE state > 0)) THEN
                EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3242", "function":"3270","parameters":{"zone":"'||v_zone||'"}}}$$);' INTO v_audit_result;
            ELSE
                IF v_netscenario_id IS NULL THEN
                    EXECUTE 'SELECT json_agg(a::integer) FROM json_array_elements_text('''||v_toarc||'''::json) a WHERE a::integer IN (SELECT arc_id FROM arc WHERE state = 1 AND (node_1 ='||v_nodeparent||' OR node_2 = '||v_nodeparent||'))' INTO v_toarc;
                ELSE
                    EXECUTE 'SELECT json_agg(a::integer) FROM json_array_elements_text('''||v_toarc||'''::json) a WHERE a::integer IN (SELECT arc_id FROM arc WHERE state > 0 AND (node_1 ='||v_nodeparent||' OR node_2 = '||v_nodeparent||'))' INTO v_toarc;
                END IF;

                IF v_toarc IS NULL AND v_project_type = 'WS' THEN
                    EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                        "data":{"message":"3244", "function":"3270","parameters":{"nodeparent":"'||v_nodeparent||'"}}}$$);'  INTO v_audit_result;
                ELSIF v_project_type = 'WS' THEN
                        v_preview = concat('{"nodeParent":"',v_nodeparent,'", "toArc":',v_toarc,'}');
                ELSIF v_project_type = 'UD' THEN
                        v_preview = concat('{"nodeParent":"',v_nodeparent,'"}');
                END IF;

                IF v_config IS NULL THEN
                    v_config = '{"use":[], "ignore":[], "forceClosed":[]}';
                END IF;

                EXECUTE 'SELECT json_extract_path_text(json_extract_path('''||v_config||'''::json,''use'')->0,''nodeParent'')' INTO v_check_value;

                IF v_check_value = '' THEN
                    v_preview = concat('{"use":[',v_preview,'], "ignore":[], "forceClosed":[]}');
                ELSE
                    v_use_value = json_extract_path_text(v_config::json, 'use');
                    v_ignore_value = json_extract_path_text(v_config::json, 'ignore');
                    v_forceClosed_value = json_extract_path_text(v_config::json, 'forceClosed');

                    IF v_use_value::text = '[]' THEN
                        v_combined_use_value = v_preview::text;
                    ELSE
                        v_combined_use_value = trim(both '[]' FROM v_use_value::text) || ',' || v_preview::text;
                    END IF;

                    v_preview = gw_fct_json_object_set_key('{}'::json, 'use', ('[' || v_combined_use_value || ']')::json);
                    v_preview = gw_fct_json_object_set_key(v_preview, 'ignore', v_ignore_value::json);
                    v_preview = gw_fct_json_object_set_key(v_preview, 'forceClosed', v_forceClosed_value::json);
                END IF;
            END IF;

        ELSE
            v_preview = v_config;
        END IF;

        IF v_forceclosed IS NOT NULL THEN
            v_forceClosed_value = COALESCE(json_extract_path(v_preview::json, 'forceClosed'), '[]'::json);
            IF json_array_length(v_forceClosed_value) = 0 THEN
                v_preview = gw_fct_json_object_set_key(v_preview, 'forceClosed', v_forceclosed::json);
            ELSE
                v_combined_forceClosed_value = jsonb_concat(v_forceClosed_value::jsonb, v_forceclosed::jsonb);
                v_preview = gw_fct_json_object_set_key(v_preview, 'forceClosed', v_combined_forceClosed_value::json);
            END IF;
        END IF;

        IF v_ignore IS NOT NULL THEN
		    v_ignore_value = COALESCE(json_extract_path(v_preview::json, 'ignore'), '[]'::json);
		    IF json_array_length(v_ignore_value) = 0 THEN
		        v_combined_ignore_value = v_ignore::json;
		    ELSE
		        v_combined_ignore_value = jsonb_concat(v_ignore_value::jsonb, v_ignore::jsonb);
		    END IF;

		    v_preview = json_build_object(
		        'use', COALESCE(json_extract_path(v_preview::json, 'use'), '[]'::json),
		        'ignore', v_combined_ignore_value::json,
		        'forceClosed', COALESCE(json_extract_path(v_preview::json, 'forceClosed'), '[]'::json)
		    );
		END IF;

    ELSIF v_action = 'REMOVE' THEN
        IF v_nodeparent IS NOT NULL THEN
            EXECUTE 'SELECT json_agg(a.data::json) FROM (SELECT json_array_elements_text(json_extract_path('''||v_config||'''::json,''use'')) as data)a WHERE json_extract_path_text(data ::json,''nodeParent'') != '||quote_literal(v_nodeparent)||'' INTO v_use_node;

            IF v_use_node IS NULL THEN
                v_use_node = '[]';
            END IF;

            v_use_value = v_use_node;
            v_ignore_value = json_extract_path_text(v_config::json, 'ignore');
            v_forceClosed_value = json_extract_path_text(v_config::json, 'forceClosed');

            v_preview = gw_fct_json_object_set_key('{}'::json, 'use', v_use_value::json);
            v_preview = gw_fct_json_object_set_key(v_preview, 'ignore', v_ignore_value::json);
            v_preview = gw_fct_json_object_set_key(v_preview, 'forceClosed', v_forceClosed_value::json);
        END IF;

        IF v_forceclosed IS NOT NULL THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(elem::bigint)), '[]'::jsonb)
            INTO v_use_forceclosed
            FROM jsonb_array_elements_text(COALESCE(v_config::jsonb -> 'forceClosed', '[]'::jsonb)) AS x(elem)
            WHERE x.elem NOT IN (SELECT jsonb_array_elements_text(v_forceclosed::jsonb));

            v_use_value = COALESCE(json_extract_path(v_config::json, 'use'), '[]'::json);
            v_ignore_value = COALESCE(json_extract_path(v_config::json, 'ignore'), '[]'::json);
            v_forceClosed_value = COALESCE(v_use_forceclosed, '[]'::json);

            v_preview = json_build_object(
                'use', v_use_value,
                'ignore', v_ignore_value,
                'forceClosed', v_forceClosed_value
            );
        END IF;

        IF v_ignore IS NOT NULL THEN
            SELECT COALESCE(jsonb_agg(to_jsonb(elem::bigint)), '[]'::jsonb)
            INTO v_ignore_value
            FROM jsonb_array_elements_text(COALESCE(v_config::jsonb -> 'ignore', '[]'::jsonb)) AS x(elem)
            WHERE x.elem NOT IN (SELECT jsonb_array_elements_text(v_ignore::jsonb));

            v_use_value = COALESCE(json_extract_path(COALESCE(v_preview, v_config::json), 'use'), '[]'::json);
            v_forceClosed_value = COALESCE(json_extract_path(COALESCE(v_preview, v_config::json), 'forceClosed'), '[]'::json);

            v_preview = json_build_object(
                'use', v_use_value,
                'ignore', COALESCE(v_ignore_value, '[]'::json),
                'forceClosed', v_forceClosed_value
            );
        END IF;

    ELSIF v_action = 'UPDATE' THEN
        IF v_config IS NULL THEN
            v_config = '{"use":[], "ignore":[], "forceClosed":[]}';
        END IF;

        v_id = lower(v_zone) || '_id';

        IF v_netscenario_id IS NULL THEN
            EXECUTE 'UPDATE '||lower(v_zone)||' set graphconfig = '''||v_config::JSON||''' WHERE '||v_id||'::text = '''||v_mapzone_id||'''::text;';
        ELSE
            EXECUTE 'UPDATE plan_netscenario_'||lower(v_zone)||' set graphconfig = '''||v_config::JSON||''' WHERE '||v_id||'::text = '''||v_mapzone_id||'''::text AND netscenario_id='||v_netscenario_id||';';
        END IF;
    END IF;

    IF v_audit_result IS NULL THEN
        v_status = 'Accepted';
        v_level = 3;
        v_message = 'Process done successfully';
    ELSE
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;
    END IF;

    SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid ORDER BY id) row;

    v_result := COALESCE(v_result, '{}');
    v_result_info = concat('{"values":', v_result, '}');
    v_preview := COALESCE(v_preview, '{}');

    RETURN gw_fct_json_create_return(('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'", "body":{"form":{},"data":{"info":'||v_result_info||', "preview":'||v_preview||'}}}')::json, 3270, NULL, NULL, NULL);

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

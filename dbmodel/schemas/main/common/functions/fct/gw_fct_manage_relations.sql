/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3386

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_manage_relations(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_manage_relations(p_data json)
RETURNS json AS
$BODY$

/*

 * PARAMETERS OPTIONS:
 * * project_type: string -> 'WS' | 'UD' (mandatory)
 * * table_name: string -> 'doc' | 'element' (mandatory)
 * * object_id: string -> 'object_id' (mandatory)
 * * data: object - {'arc': [], 'node': [], 'connec': [], 'gully': [], 'psector': [], 'visit': [], 'workcat': []} (mandatory)

 * EXAMPLE CALLS:
 * * SELECT SCHEMA_NAME.gw_fct_manage_relations('{"data":{"parameters":{"project_type":"WS", "object_id": 1897, "table_name":"element", "data":{"arc": [135, 2028, 2030, 20851, 2027], "node": [113883, 1092], "connec": []}}}}');
 * * SELECT SCHEMA_NAME.gw_fct_manage_relations('{"data":{"parameters":{"project_type":"WS", "object_id": 1897, "table_name":"doc, "data":{"arc": [], "node": [4], "connec": [], 'psector': [], 'visit': [], 'workcat': [2, 4]}}}}');

 * * SELECT SCHEMA_NAME.gw_fct_manage_relations('{"data":{"parameters":{"project_type":"UD", "object_id": 1897, "table_name":"element", "data":{"arc": [1, 2, 3], "node": [4, 5, 6], "connec": [7, 8, 9], "gully": [10, 11, 12]}}}}');
 * * SELECT SCHEMA_NAME.gw_fct_manage_relations('{"data":{"parameters":{"project_type":"UD", "object_id": 1897, "table_name":"doc", "data":{"arc": [], "node": [4], "connec": [], "gully": [10], "psector": [13, 14], "visit": [], "workcat": []}}}}');

*/

DECLARE

    v_project_type text;

    -- parameters
    v_parameters json;
    v_table_name text;
    v_object_id text;
    v_data jsonb;

    v_relations_table_prefix text;

    v_querytext text;

BEGIN

    -- set search path
	SET search_path = "SCHEMA_NAME", public;

	-- get input parameters
	v_parameters := (((p_data ->>'data')::json->>'parameters')::json);
    v_project_type = UPPER(v_parameters->>'project_type');
    v_table_name = LOWER(v_parameters->>'table_name');
    v_object_id = v_parameters->>'object_id';
    v_data = v_parameters->>'data';

    -- validate parameters
    IF v_project_type IS NULL THEN
        RETURN ('{"status":"Failed","message":{"level":1, "text":"project_type is required"}}')::json;
    END IF;

    IF v_table_name IS NULL THEN
        RETURN ('{"status":"Failed","message":{"level":1, "text":"table_name is required"}}')::json;
    END IF;

    IF v_data IS NULL THEN
        RETURN ('{"status":"Failed","message":{"level":1, "text":"data is required"}}')::json;
    END IF;

    -- validate project_type
    IF v_project_type NOT IN ('WS', 'UD') THEN
        RETURN ('{"status":"Failed","message":{"level":1, "text":"project_type is invalid"}}')::json;
    END IF;

    -- validate table_name
    IF v_table_name NOT IN ('doc', 'element') THEN
        RETURN ('{"status":"Failed","message":{"level":1, "text":"table_name is invalid"}}')::json;
    END IF;

    -- validate object_id
    IF v_object_id IS NULL THEN
        RETURN ('{"status":"Failed","message":{"level":1, "text":"object_id is required"}}')::json;
    END IF;


    -- extra validations to check if the data is valid
    IF v_table_name = 'element' THEN
        IF v_data->>'psector' IS NOT NULL THEN
            RETURN ('{"status":"Failed","message":{"level":1, "text":"psector is not allowed for element table"}}')::json;
        END IF;

        IF v_data->>'visit' IS NOT NULL THEN
            RETURN ('{"status":"Failed","message":{"level":1, "text":"visit is not allowed for element table"}}')::json;
        END IF;

        IF v_data->>'workcat' IS NOT NULL THEN
            RETURN ('{"status":"Failed","message":{"level":1, "text":"workcat is not allowed for element table"}}')::json;
        END IF;
    END IF;

    IF v_project_type = 'WS' THEN
        IF v_data->>'gully' IS NOT NULL THEN
            RETURN ('{"status":"Failed","message":{"level":1, "text":"gully is not allowed for WS"}}')::json;
        END IF;
    END IF;

    -- element_x_arc, element_x_node, element_x_connec, element_x_gully
    -- doc_x_arc, doc_x_node, doc_x_connec, doc_x_gully, doc_x_link, doc_x_psector, doc_x_visit, doc_x_workcat, doc_x_element

    v_relations_table_prefix = v_table_name||'_x_';

    -- Delete existing relations not in arrays (skip null or empty arrays)
    IF v_data->>'arc' IS NOT NULL AND v_data->>'arc' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'arc', v_table_name||'_id', 'arc_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'arc';
    END IF;

    IF v_data->>'node' IS NOT NULL AND v_data->>'node' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'node', v_table_name||'_id', 'node_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'node';
    END IF;

    IF v_data->>'connec' IS NOT NULL AND v_data->>'connec' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'connec', v_table_name||'_id', 'connec_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'connec';
    END IF;

    IF v_data->>'link' IS NOT NULL AND v_data->>'link' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'link', v_table_name||'_id', 'link_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'link';
    END IF;

    IF v_project_type = 'UD' AND v_data->>'gully' IS NOT NULL AND v_data->>'gully' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'gully', v_table_name||'_id', 'gully_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'gully';
    END IF;

    IF v_data->>'psector' IS NOT NULL AND v_data->>'psector' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'psector', v_table_name||'_id', 'psector_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'psector';
    END IF;

    IF v_data->>'visit' IS NOT NULL AND v_data->>'visit' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'visit', v_table_name||'_id', 'visit_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'visit';
    END IF;

    IF v_data->>'workcat' IS NOT NULL AND v_data->>'workcat' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb))',
            v_relations_table_prefix||'workcat', v_table_name||'_id', 'workcat_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'workcat';
    END IF;

    IF v_data->>'element' IS NOT NULL AND v_data->>'element' != '[]' THEN
        v_querytext = format('DELETE FROM %I WHERE %I::text = $1 AND %I NOT IN (SELECT jsonb_array_elements_text($2::jsonb)::int)',
            v_relations_table_prefix||'element', v_table_name||'_id', 'element_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'element';
    END IF;

    -- Insert new relations
    IF v_data->>'arc' IS NOT NULL AND v_data->>'arc' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, arc_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'arc', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'arc';
    END IF;

    IF v_data->>'node' IS NOT NULL AND v_data->>'node' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, node_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'node', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'node';
    END IF;

    IF v_data->>'connec' IS NOT NULL AND v_data->>'connec' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, connec_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'connec', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'connec';
    END IF;

    IF v_data->>'link' IS NOT NULL AND v_data->>'link' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, link_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'link', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'link';
    END IF;

    IF v_project_type = 'UD' AND v_data->>'gully' IS NOT NULL AND v_data->>'gully' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, gully_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'gully', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'gully';
    END IF;

    IF v_data->>'psector' IS NOT NULL AND v_data->>'psector' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, psector_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'psector', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'psector';
    END IF;

    IF v_data->>'visit' IS NOT NULL AND v_data->>'visit' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, visit_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'visit', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'visit';
    END IF;

    IF v_data->>'workcat' IS NOT NULL AND v_data->>'workcat' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, workcat_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb) ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'workcat', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'workcat';
    END IF;

    IF v_data->>'element' IS NOT NULL AND v_data->>'element' != '[]' THEN
        v_querytext = format('INSERT INTO %I (%I, element_id) SELECT $1::int4, jsonb_array_elements_text($2::jsonb)::int4 ON CONFLICT DO NOTHING',
            v_relations_table_prefix||'element', v_table_name||'_id');

        EXECUTE v_querytext USING v_object_id, v_data->>'element';
    END IF;


    RETURN ('{"status":"Accepted","message":{"level":1, "text":"Relations updated successfully"}}')::json;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
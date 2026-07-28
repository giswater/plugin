/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2988

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getmincut(p_data json)
RETURNS json AS
$BODY$

/*
-- Button networkMincut on mincut dialog
SELECT gw_fct_getmincut('{"data":{"mincutId":"3"}}');

fid = 216

*/

DECLARE
    v_device integer;
    v_field jsonb;
    v_fields_array json[];
    v_fieldsjson jsonb := '[]';
    v_mincut record;
    v_mincutid text;
    v_response json;
    v_values jsonb;
    v_version text;
    aux_json json;
    array_index integer DEFAULT 0;
    field_value character varying;
    v_querystring text;
    v_debug_vars json;
    v_debug json;
    v_msgerr json;
    v_querytext text;
    v_mincutrec record;
    v_result_info json;
    v_selected_id text;
    v_selected_idval text;
    v_current_id text;
    v_new_id text;
    v_widgetcontrols json;
    v_values_array json;
    v_widgetvalues json;
    v_result json;
    v_result_init json;
    v_result_valve_proposed json;
    v_result_valve_not_proposed json;
    v_result_node json;
    v_result_connec json;
    v_result_arc json;
    v_point_geom public.geometry;
    v_bbox jsonb;
    address_array text[];
    aux_combo text[];
    aux_street_id text[];
    aux_street_name text[];
    aux_muni_id text[];
    aux_muni_name text[];
    aux_cp text[];
    v_error_context text;
    v_mincut_conflict_group_id uuid;
    v_mincut_conflict_state integer := 5; -- Conflict mincut state

BEGIN
    -- Set search path to local schema
    SET search_path = "SCHEMA_NAME", public;

    -- Get input data
    v_device := p_data -> 'client' ->> 'device';
    v_mincutid := ((p_data ->>'data')::json->>'mincutId')::integer;

    -- Get api version
    SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

    IF v_device = 5 THEN

        SELECT gw_fct_getformfields(
        'mincut',
        'form_mincut',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        v_device,
        NULL
        ) INTO v_fields_array;
        v_querystring = concat('SELECT (row_to_json(a)) FROM 
                (SELECT * FROM ','om_mincut',' WHERE id = ',quote_literal(v_mincutid),')a');
        EXECUTE v_querystring INTO v_values_array;

        -- Update table 'selector_mincut_result'
        DELETE FROM selector_mincut_result WHERE cur_user = current_user;
        INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
        VALUES (v_mincutid::int, current_user, 'current') ON CONFLICT (result_id, cur_user) DO NOTHING;

        SELECT id INTO v_mincut_conflict_group_id FROM om_mincut_conflict WHERE mincut_id = v_mincutid::int;

        INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
        SELECT omc.mincut_id, current_user, 'conflict'
        FROM om_mincut_conflict omc
        JOIN om_mincut om ON om.id = omc.mincut_id
        WHERE omc.id = v_mincut_conflict_group_id
        AND omc.mincut_id <> v_mincutid::int
        AND om.mincut_state  <> v_mincut_conflict_state
        ON CONFLICT (result_id, cur_user) DO NOTHING;

        INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
        SELECT omc.mincut_id, current_user, 'affected'
        FROM om_mincut_conflict omc
        JOIN om_mincut om ON om.id = omc.mincut_id
        WHERE omc.id = v_mincut_conflict_group_id
        AND omc.mincut_id <> v_mincutid::int
        AND om.mincut_state = v_mincut_conflict_state
        ON CONFLICT (result_id, cur_user) DO NOTHING;

        --Get location combos searching the address
        v_point_geom = (SELECT anl_the_geom FROM om_mincut WHERE id::text = v_mincutid::text);
        EXECUTE 'SELECT array_agg(row.id) FROM (SELECT id FROM v_address WHERE ST_DWithin(the_geom, $1, 200) ORDER BY ST_distance (the_geom,$1) ASC LIMIT 10) row'
            INTO address_array
            USING v_point_geom;

        IF address_array IS NULL THEN
            EXECUTE 'SELECT array_agg(row.id) FROM (SELECT id FROM v_address) row'
                INTO address_array
                USING v_point_geom;
        END IF;

        -- Get municipality
        EXECUTE 'SELECT array_agg(row.muni_id) FROM (SELECT DISTINCT v_municipality.muni_id FROM v_address JOIN v_municipality USING (muni_id) WHERE id = ANY($1)) row'
            INTO aux_muni_id
            USING address_array;
        EXECUTE 'SELECT array_agg(row.name) FROM (SELECT DISTINCT v_municipality.name FROM v_address JOIN v_municipality USING (muni_id) WHERE id = ANY($1)) row'
            INTO aux_muni_name
            USING address_array;

        -- Get postcode
        EXECUTE 'SELECT array_agg(row.postcode) FROM (SELECT DISTINCT postcode FROM v_address WHERE id = ANY($1)) row'
            INTO aux_cp
            USING address_array;

        -- Get street
        EXECUTE 'SELECT array_agg(row.streetaxis_id) FROM (SELECT DISTINCT streetaxis_id, v_streetaxis.name 
            FROM v_address JOIN v_streetaxis ON (streetaxis_id = v_streetaxis.id) WHERE v_address.id = ANY($1) order by name) row'
            INTO aux_street_id
            USING address_array;

        EXECUTE 'SELECT array_agg(row.name) FROM (SELECT DISTINCT streetaxis_id, v_streetaxis.name 
            FROM v_address JOIN v_streetaxis ON (streetaxis_id = v_streetaxis.id) WHERE v_address.id = ANY($1) order by name) row'
            INTO aux_street_name
            USING address_array;

        -- looping the array setting values and widgetcontrols
            FOREACH aux_json IN ARRAY v_fields_array
            LOOP
                array_index := array_index + 1;

                field_value := (v_values_array->>(aux_json->>'columnname'));
                IF (aux_json->>'columnname') = 'mincut_state' THEN
                    SELECT idval into field_value FROM om_typevalue where typevalue = 'mincut_state' and id = (v_values_array->>'mincut_state');
                END IF;

                IF (aux_json->>'columnname') = 'streetaxis_id' THEN
                    v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'comboIds', COALESCE(aux_street_id, '{}'));
                    v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'comboNames', COALESCE(aux_street_name, '{}'));
                END IF;

                IF (aux_json->>'columnname') = 'postnumber' THEN
                    v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'comboIds', COALESCE(aux_cp, '{}'));
                    v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'comboNames', COALESCE(aux_cp, '{}'));
                END IF;

                -- setting values
                IF (aux_json->>'widgettype')='combo' THEN
                    --check if selected id is on combo list
                    IF field_value::text not in  (select a from json_array_elements_text(json_extract_path(v_fields_array[array_index],'comboIds'))a) AND field_value IS NOT NULL then
                        --find dvquerytext for combo
                        v_querystring = concat('SELECT dv_querytext FROM config_form_fields WHERE 
                        columnname::text = (',quote_literal(v_fields_array[array_index]),'::json->>''columnname'')::text
                        and formname = ',quote_literal(p_table_id),';');
                        v_debug_vars := json_build_object('v_fields_array[array_index]', v_fields_array[array_index], 'p_table_id', p_table_id);
                        v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getfeatureupsert', 'flag', 100);
                        SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
                        EXECUTE v_querystring INTO v_querytext;

                        v_querytext = replace(lower(v_querytext),'active is true','1=1');

                        --select values for missing id
                        v_querystring = concat('SELECT id, idval FROM (',v_querytext,')a
                        WHERE id::text = ',quote_literal(field_value),'');
                        v_debug_vars := json_build_object('v_querytext', v_querytext, 'field_value', field_value);
                        v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getfeatureupsert', 'flag', 110);
                        SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
                        EXECUTE v_querystring INTO v_selected_id,v_selected_idval;

                        v_current_id =json_extract_path_text(v_fields_array[array_index],'comboIds');

                        IF v_current_id='[]' THEN
                            --case when list is empty
                            EXECUTE 'SELECT  array_to_json(''{'||v_selected_id||'}''::text[])'
                            INTO v_new_id;
                            v_fields_array[array_index] = gw_fct_json_object_set_key(v_fields_array[array_index],'comboIds',v_new_id::json);
                            EXECUTE 'SELECT  array_to_json(''{'||v_selected_idval||'}''::text[])'
                            INTO v_new_id;
                            v_fields_array[array_index] = gw_fct_json_object_set_key(v_fields_array[array_index],'comboNames',v_new_id::json);
                        ELSE

                            select string_agg(quote_ident(a),',') into v_new_id from json_array_elements_text(v_current_id::json) a ;
                            --remove current combo Ids from return json
                            v_fields_array[array_index] = v_fields_array[array_index]::jsonb - 'comboIds'::text;
                            v_new_id = '['||v_new_id || ','|| quote_ident(v_selected_id)||']';
                            --add new combo Ids to return json
                            v_fields_array[array_index] = gw_fct_json_object_set_key(v_fields_array[array_index],'comboIds',v_new_id::json);

                            v_current_id =json_extract_path_text(v_fields_array[array_index],'comboNames');
                            select string_agg(quote_ident(a),',') into v_new_id from json_array_elements_text(v_current_id::json) a ;
                            --remove current combo names from return json
                            v_fields_array[array_index] = v_fields_array[array_index]::jsonb - 'comboNames'::text;
                            v_new_id = '['||v_new_id || ','|| quote_ident(v_selected_idval)||']';
                            --add new combo names to return json
                            v_fields_array[array_index] = gw_fct_json_object_set_key(v_fields_array[array_index],'comboNames',v_new_id::json);
                        END IF;
                    END IF;
                    v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'selectedId', COALESCE(field_value, ''));
                ELSIF (aux_json->>'widgettype') !='button' THEN
                    v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'value', COALESCE(field_value, ''));
                END IF;

                -- setting widgetcontrols
                IF (aux_json->>'datatype')='double' OR (aux_json->>'datatype')='integer' OR (aux_json->>'datatype')='numeric' THEN
                    IF v_widgetvalues IS NOT NULL THEN
                        v_widgetcontrols = gw_fct_json_object_set_key ((aux_json->>'widgetcontrols')::json, 'maxMinValues' ,(v_widgetvalues->>(aux_json->>'columnname'))::json);
                        v_fields_array[array_index] := gw_fct_json_object_set_key (v_fields_array[array_index], 'widgetcontrols', v_widgetcontrols);
                    END IF;
                END IF;
            END LOOP;

        v_fieldsjson := to_json(v_fields_array);

        -- build geojson
        IF v_device = 5 THEN
            --v_om_mincut
            SELECT jsonb_build_object(
                'type', 'FeatureCollection',
                'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
            ) INTO v_result
                FROM (
            SELECT jsonb_build_object(
             'type',       'Feature',
            'geometry',   ST_AsGeoJSON(anl_the_geom)::jsonb,
            'properties', to_jsonb(row) - 'anl_the_geom'
            ) AS feature
            FROM (SELECT id, ST_Transform(anl_the_geom, 4326) as anl_the_geom
            FROM  v_om_mincut) row) features;

            v_result_init = v_result;

            --v_om_mincut_valve proposed true
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
            FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
            FROM  v_om_mincut_valve WHERE proposed = true) row) features;

            v_result_valve_proposed = v_result;

            --v_om_mincut_valve proposed false
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
            FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
            FROM  v_om_mincut_valve WHERE proposed = false) row) features;

            v_result_valve_not_proposed = v_result;

            --v_om_mincut_node
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
            FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
            FROM  v_om_mincut_node) row) features;

            v_result_node = v_result;

            --v_om_mincut_connec
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
            FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
            FROM  v_om_mincut_connec) row) features;

            v_result_connec = v_result;

            --v_om_mincut_arc
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
            FROM (SELECT id, arc_id, ST_Transform(the_geom, 4326) as the_geom
            FROM  v_om_mincut_arc) row) features;

            v_result_arc = v_result;

        END IF;

        -- get v_bbox for geometry
      	SELECT
		    jsonb_build_object(
		      'x1', ST_XMin(ST_Extent(the_geom)),
		      'y1', ST_YMin(ST_Extent(the_geom)),
		      'x2', ST_XMax(ST_Extent(the_geom)),
		      'y2', ST_YMax(ST_Extent(the_geom))
		    )
		FROM v_om_mincut_arc
		into v_bbox;

        -- mincut details
        SELECT * INTO v_mincutrec FROM om_mincut WHERE id::text = v_mincutid::text;
        DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=216;

        -- mincut details
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4362", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "cur_user":"current_user"}}$$)';
	    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "cur_user":"current_user"}}$$)';

        -- Stats
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'arcs'->>'number'), '0')||'"}, "cur_user":"current_user"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"'||COALESCE((v_mincutrec.output->'arcs'->>'length'), '0')||'"}, "cur_user":"current_user"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"'||COALESCE((v_mincutrec.output->'arcs'->>'volume'), '0')||'"}, "cur_user":"current_user"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'connecs'->>'number'), '0')||'"}, "cur_user":"current_user"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincutrec.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "cur_user":"current_user"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincutrec.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "cur_user":"current_user"}}$$)';

        -- info
        v_result = null;
        SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
        FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=216 order by id) row;
        v_result := COALESCE(v_result, '{}');
        v_result_info = concat ('{"values":',v_result, '}');

        v_result_info := COALESCE(v_result_info, '{}');

        v_result_init = COALESCE(v_result_init, '{}');
        v_result_valve_proposed = COALESCE(v_result_valve_proposed, '{}');
        v_result_valve_not_proposed = COALESCE(v_result_valve_not_proposed, '{}');
        v_result_node = COALESCE(v_result_node, '{}');
        v_result_connec = COALESCE(v_result_connec, '{}');
        v_result_arc = COALESCE(v_result_arc, '{}');
        v_bbox = COALESCE(v_bbox, '{}'::jsonb);
        v_response := concat('{"status":"Accepted", "version":"',v_version,'","body":{"form":{}',
            ',"feature":{}',
            ',"data":{ "info":',v_result_info::text,
              ',"mincutId":',v_mincutid::text,
              ',"fields":',v_fieldsjson::text,
              ',"mincutState":',(v_values_array->>'mincut_state')::text,
              ',"mincutInit":',v_result_init::text,
              ',"mincutProposedValve":',v_result_valve_proposed::text,
              ',"mincutNotProposedValve":',v_result_valve_not_proposed::text,
              ',"mincutNode":',v_result_node::text,
              ',"mincutConnec":',v_result_connec::text,
              ',"mincutArc":',v_result_arc::text,
              ',"geometry":{"bbox":',v_bbox::text,'}',
            '}}}'
        );

        RETURN v_response;

    ELSE
    -- mincut details
    SELECT * INTO v_mincutrec FROM om_mincut WHERE id::text = v_mincutid::text;
    DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=216;

    -- mincut details
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4362", "function":"2988", "fid":"216", "criticity":"4", "is_process":true, "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "cur_user":"current_user"}}$$)';

    -- Stats
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'arcs'->>'number'), '0')||'"}, "cur_user":"current_user"}}$$)';
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"'||COALESCE((v_mincutrec.output->'arcs'->>'length'), '0')||'"}, "cur_user":"current_user"}}$$)';
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"'||COALESCE((v_mincutrec.output->'arcs'->>'volume'), '0')||'"}, "cur_user":"current_user"}}$$)';
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'connecs'->>'number'), '0')||'"}, "cur_user":"current_user"}}$$)';
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincutrec.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "cur_user":"current_user"}}$$)';
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincutrec.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "cur_user":"current_user"}}$$)';

    -- info
    v_result = null;
    SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
    FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=216 order by id) row;
    v_result := COALESCE(v_result, '{}');
    v_result_info = concat ('{"values":',v_result, '}');

    v_result_info := COALESCE(v_result_info, '{}');

    -- return
    RETURN ('{"status":"Accepted", "version":"'||v_version||'","body":{"form":{}'||
            ',"data":{ "info":'||v_result_info||'}'||
            '}}')::json;
    END IF;

    -- Exception handling
    EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
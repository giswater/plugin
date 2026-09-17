/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 3484

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getfeatures(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
/*
Function for getting features by sysType, featureType, or config_form_list tableName.
Supports filterFields, canvasExtend, pageInfo, and outputFormat list|geojson.

Complex SQL (GROUP BY, custom columns) belongs in config_form_list.query_text, not here.

Examples:
SELECT SCHEMA_NAME.gw_fct_getfeatures('{"client":{"device":5, "epsg":SRID_VALUE}, "data": {"sysType": "PIPE"}}');
SELECT SCHEMA_NAME.gw_fct_getfeatures('{"client":{"device":5}, "data": {"featureType": "NODE", "filterFields":{"nodecat_id":{"value":["MEDPR"], "filterSign":"IN"}, "state":{"value":1, "filterSign":"="}}}}');
SELECT SCHEMA_NAME.gw_fct_getfeatures('{"client":{"device":5}, "data": {"tableName": "v_api_meters", "outputFormat": "geojson", "pageInfo": {"limit": 100}}}');
*/

DECLARE
    v_version text;
    v_epsg integer;
    v_device integer;
    v_systype text;
    v_featuretype_param text;
    v_tablename text;
    v_mapzone_type text;
    v_mapzone_id integer;
    v_parameter text;
    v_order text;
    v_output_format text;
    v_filter_values json;
    v_canvasextend json;
    v_pageinfo json;
    v_orderby varchar;
    v_ordertype varchar;
    v_limit integer;
    v_page integer;
    v_lastpage integer;
    v_feature_type text;
    v_from text;
    v_sql text;
    v_where text;
    v_order_clause text;
    v_list_mode boolean := false;
    v_resolved json;
    v_default json;
    v_listtype text;
    v_the_geom_col text;
    v_legacy_list boolean := false;
    v_include_pageinfo boolean := false;
    v_has_advanced boolean := false;
    v_result jsonb;
    v_result_array json[];
    v_select text;
    v_x1 float;
    v_y1 float;
    v_y2 float;
    v_x2 float;
    v_errcontext text;
    v_msgerr json;
BEGIN
    SET search_path = "SCHEMA_NAME", public;

    p_data = REPLACE(p_data::text, '"NULL"', 'null');
    p_data = REPLACE(p_data::text, '"null"', 'null');
    p_data = REPLACE(p_data::text, '""', 'null');
    p_data = REPLACE(p_data::text, '''''', 'null');

    SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;
    SELECT epsg INTO v_epsg FROM sys_version ORDER BY id DESC LIMIT 1;

    v_device := (p_data->>'client')::json->>'device';
    v_systype := (p_data->>'data')::json->>'sysType';
    v_featuretype_param := upper(COALESCE((p_data->>'data')::json->>'featureType', ''));
    v_tablename := (p_data->>'data')::json->>'tableName';
    v_mapzone_type := (p_data->>'data')::json->>'mapzoneType';
    v_mapzone_id := (p_data->>'data')::json->>'mapzoneId';
    v_parameter := (p_data->>'data')::json->>'parameter';
    v_order := lower((p_data->>'data')::json->>'order');
    v_output_format := lower(COALESCE((p_data->>'data')::json->>'outputFormat', 'list'));
    v_filter_values := (p_data->>'data')::json->>'filterFields';
    v_canvasextend := (p_data->>'data')::json->>'canvasExtend';
    v_orderby := ((p_data->>'data')::json->>'pageInfo')::json->>'orderBy';
    v_ordertype := ((p_data->>'data')::json->>'pageInfo')::json->>'orderType';
    v_page := ((p_data->>'data')::json->>'pageInfo')::json->>'page';
    v_limit := ((p_data->>'data')::json->>'pageInfo')::json->>'limit';

    IF v_output_format NOT IN ('list', 'geojson') THEN
        v_output_format := 'list';
    END IF;

    IF (v_systype IS NULL OR v_systype = '')
        AND (v_featuretype_param IS NULL OR v_featuretype_param = '')
        AND (v_tablename IS NULL OR v_tablename = '') THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"4138", "function":"3484","parameters":{}}}$$);';
    END IF;

    IF v_filter_values IS NOT NULL AND v_filter_values::text <> '{}' THEN
        v_has_advanced := true;
    END IF;
    IF v_canvasextend IS NOT NULL THEN
        v_has_advanced := true;
    END IF;
    IF (p_data->>'data')::json->>'pageInfo' IS NOT NULL THEN
        v_has_advanced := true;
    END IF;
    v_include_pageinfo := v_output_format = 'geojson' OR v_has_advanced;

    -- Resolve source
    IF v_tablename IS NOT NULL AND v_tablename <> '' THEN
        v_list_mode := true;
        v_resolved := gw_fct_resolve_list_query(v_tablename, v_device);
        v_sql := v_resolved->>'queryText';
        v_default := v_resolved->'vdefault';
        v_listtype := v_resolved->>'listtype';
        v_the_geom_col := v_resolved->>'theGeomCol';
        v_feature_type := NULLIF(v_featuretype_param, '');
        IF v_feature_type IS NULL THEN
            v_feature_type := upper(split_part(replace(v_tablename, 've_', ''), '_', 1));
            IF v_feature_type NOT IN ('NODE', 'ARC', 'CONNEC', 'LINK', 'GULLY') THEN
                v_feature_type := NULL;
            END IF;
        END IF;
    ELSIF v_systype IS NOT NULL AND v_systype <> '' THEN
        -- Legacy API consumers (e.g. sysType PIPE) expect generic ve_node / ve_arc, not parent_layer views
        SELECT feature_type INTO v_feature_type
        FROM cat_feature
        WHERE id = v_systype
        LIMIT 1;

        IF v_feature_type IS NULL THEN
            SELECT feature_type INTO v_feature_type
            FROM cat_feature
            WHERE feature_class = v_systype
            LIMIT 1;
        END IF;

        IF v_feature_type IS NULL THEN
            EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"4140", "function":"3484","parameters":{"sysType":"'||v_systype||'"}}}$$);';
        END IF;

        IF v_feature_type = 'NODE' THEN
            v_from := 've_node';
        ELSIF v_feature_type = 'ARC' THEN
            v_from := 've_arc';
        ELSE
            v_from := 've_' || lower(v_feature_type);
        END IF;
    ELSIF v_featuretype_param IS NOT NULL AND v_featuretype_param <> '' THEN
        v_feature_type := v_featuretype_param;
        v_from := 've_' || lower(v_feature_type);
    END IF;

    IF NOT v_list_mode THEN
        IF v_from IS NULL OR v_from = '' THEN
            v_from := 've_' || lower(v_feature_type);
        END IF;

        IF v_feature_type IS NULL OR v_feature_type NOT IN ('NODE', 'ARC', 'CONNEC', 'LINK', 'GULLY') THEN
            EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"4142", "function":"3484","parameters":{"sysType":"'||COALESCE(v_systype, '')||'", "featureType":"'||COALESCE(v_feature_type, '')||'"}}}$$);';
        END IF;

        v_where := ' WHERE the_geom IS NOT NULL';
        IF v_systype IS NOT NULL AND v_systype <> '' THEN
            v_where := v_where || ' AND sys_type = '''||v_systype||'''';
        END IF;
        IF v_mapzone_type IS NOT NULL AND v_mapzone_type != '' AND v_mapzone_id IS NOT NULL THEN
            v_where := v_where || ' AND ' || lower(v_mapzone_type) || '_id = ' || v_mapzone_id;
        END IF;

        v_where := v_where || gw_fct_build_filters_sql(v_filter_values, NULL);

        IF v_canvasextend IS NOT NULL THEN
            v_x1 := v_canvasextend->>'x1';
            v_y1 := v_canvasextend->>'y1';
            v_x2 := v_canvasextend->>'x2';
            v_y2 := v_canvasextend->>'y2';
            v_where := v_where || gw_fct_build_canvas_filter_sql(v_from || '.the_geom', v_x1, v_y1, v_x2, v_y2, v_epsg);
        END IF;

        v_sql := 'SELECT * FROM ' || v_from || v_where;
    ELSE
        v_sql := v_sql || gw_fct_build_filters_sql(v_filter_values, v_listtype);

        IF v_the_geom_col IS NOT NULL AND v_canvasextend IS NOT NULL THEN
            v_x1 := v_canvasextend->>'x1';
            v_y1 := v_canvasextend->>'y1';
            v_x2 := v_canvasextend->>'x2';
            v_y2 := v_canvasextend->>'y2';
            v_sql := v_sql || gw_fct_build_canvas_filter_sql(v_tablename || '.' || v_the_geom_col, v_x1, v_y1, v_x2, v_y2, v_epsg);
        END IF;
    END IF;

    IF v_output_format = 'geojson' THEN
        BEGIN
            EXECUTE 'SELECT the_geom FROM (' || v_sql || ') _geo_check LIMIT 0';
        EXCEPTION WHEN undefined_column THEN
            EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"4680", "function":"3484","parameters":{"tableName":"'||COALESCE(v_tablename, '')||'"}}}$$);';
        END;
    END IF;

    IF v_orderby IS NULL AND v_parameter IS NOT NULL AND v_parameter <> '' AND v_order IS NOT NULL AND v_order IN ('asc', 'desc') THEN
        v_orderby := v_parameter;
        v_ordertype := v_order;
    END IF;

    IF v_orderby IS NULL AND v_default IS NOT NULL THEN
        v_orderby := v_default->>'orderBy';
        v_ordertype := v_default->>'orderType';
    END IF;

    v_order_clause := '';
    IF v_orderby IS NOT NULL THEN
        v_order_clause := ' ORDER BY '||v_orderby;
        IF v_ordertype IS NOT NULL THEN
            v_order_clause := v_order_clause ||' '||v_ordertype;
        END IF;
    END IF;

    IF v_include_pageinfo THEN
        IF (p_data->>'data')::json->>'pageInfo' IS NOT NULL AND v_limit IS NULL THEN
            v_limit := 10;
        END IF;
        IF v_page IS NULL THEN
            v_page := 1;
        END IF;
        IF v_limit IS NOT NULL THEN
            EXECUTE 'SELECT count(*)/'||v_limit||' FROM (' || v_sql || ') a'
                INTO v_lastpage;
        ELSE
            v_lastpage := 0;
        END IF;
        v_pageinfo := json_build_object('orderBy', v_orderby, 'orderType', v_ordertype, 'currentPage', v_page, 'lastPage', v_lastpage);
    END IF;

    IF v_device IS DISTINCT FROM 4 AND v_limit IS NOT NULL AND v_limit != -1 THEN
        v_order_clause := v_order_clause || ' LIMIT '|| v_limit;
    END IF;

    v_legacy_list := v_output_format = 'list'
        AND NOT v_has_advanced
        AND NOT v_list_mode
        AND v_systype IS NOT NULL AND v_systype <> ''
        AND v_feature_type IN ('NODE', 'ARC');

    IF v_output_format = 'geojson' THEN
        EXECUTE format('
            SELECT jsonb_build_object(
                ''type'', ''FeatureCollection'',
                ''features'', COALESCE(jsonb_agg(features.feature), ''[]''::jsonb),
                ''pageInfo'', $1::jsonb
            )
            FROM (
                SELECT jsonb_build_object(
                    ''type'', ''Feature'',
                    ''geometry'', ST_AsGeoJSON(the_geom)::jsonb,
                    ''properties'', to_jsonb(row) - ''the_geom''
                ) AS feature
                FROM (
                    %s%s
                ) row
            ) features', v_sql, v_order_clause)
        INTO v_result
        USING v_pageinfo;

        RETURN jsonb_build_object(
            'status', 'Accepted',
            'message', jsonb_build_object('level', 1, 'text', 'Process done successfully'),
            'version', v_version,
            'body', jsonb_build_object(
                'form', '{}'::jsonb,
                'feature', '{}'::jsonb,
                'data', COALESCE(v_result, jsonb_build_object('type', 'FeatureCollection', 'features', '[]'::jsonb, 'pageInfo', COALESCE(v_pageinfo::jsonb, '{}'::jsonb)))
            )
        )::json;
    END IF;

    IF v_legacy_list THEN
        IF v_feature_type = 'NODE' THEN
            v_select := 'SELECT node_id as "nodeId", asset_id as "assetId", macrosector_id AS "macroSector", comment AS "aresepId", state, nodecat_id AS "featureClass", '
                      || 'json_build_object(''x'', ST_X(the_geom), ''y'', ST_Y(the_geom), ''epsg'', '||v_epsg||') AS coordinates '
                      || 'FROM ve_node'||v_where||v_order_clause;
        ELSE
            v_select := 'SELECT arc_id as "arcId", asset_id as "assetId", macrosector_id AS "macroSector", comment AS "aresepId", state, arccat_id AS "featureClass", '
                      || 'json_build_object(''x'', ST_X(ST_Centroid(the_geom)), ''y'', ST_Y(ST_Centroid(the_geom)), ''epsg'', '||v_epsg||') AS coordinates '
                      || 'FROM ve_arc'||v_where||v_order_clause;
        END IF;

        EXECUTE format('SELECT array_agg(row_to_json(a)) FROM (%s) a', v_select)
        INTO v_result_array;

        RETURN jsonb_build_object(
            'status', 'Accepted',
            'message', jsonb_build_object('level', 1, 'text', 'Process done successfully'),
            'version', v_version,
            'body', jsonb_build_object(
                'form', '{}'::jsonb,
                'feature', '{}'::jsonb,
                'data', jsonb_build_object('features', COALESCE(array_to_json(v_result_array), '[]'::json))
            )
        )::json;
    END IF;

    EXECUTE format('
        SELECT array_agg(
            ((to_jsonb(row) - ''the_geom'') || jsonb_build_object(
                ''coordinates'', jsonb_build_object(
                    ''x'', ST_X(ST_Centroid(the_geom)),
                    ''y'', ST_Y(ST_Centroid(the_geom)),
                    ''epsg'', %s
                )
            ))::json
        )
        FROM (
            %s%s
        ) row', v_epsg, v_sql, v_order_clause)
    INTO v_result_array;

    IF v_include_pageinfo THEN
        RETURN jsonb_build_object(
            'status', 'Accepted',
            'message', jsonb_build_object('level', 1, 'text', 'Process done successfully'),
            'version', v_version,
            'body', jsonb_build_object(
                'form', '{}'::jsonb,
                'feature', '{}'::jsonb,
                'data', jsonb_build_object(
                    'features', COALESCE(array_to_json(v_result_array), '[]'::json),
                    'pageInfo', v_pageinfo
                )
            )
        )::json;
    END IF;

    RETURN jsonb_build_object(
        'status', 'Accepted',
        'message', jsonb_build_object('level', 1, 'text', 'Process done successfully'),
        'version', v_version,
        'body', jsonb_build_object(
            'form', '{}'::jsonb,
            'feature', '{}'::jsonb,
            'data', jsonb_build_object(
                'features', COALESCE(array_to_json(v_result_array), '[]'::json)
            )
        )
    )::json;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_errcontext = pg_exception_context;
    RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE, 'MSGERR', (v_msgerr::json ->> 'MSGERR'))::json;
END;
$function$;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2604

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getvisit(p_data json)
RETURNS json
LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_getvisit($${"client":{"device":5, "lang":"es_ES", "cur_user": "bgeo", "infoType":1, "epsg":SRID_VALUE}, "form":{"visit_id": null, "visit_type": 1}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "coordinates": {"xcoord": 418980.68916666665, "ycoord": 4576904.783750001, "zoomRatio": 10000}}}$$);


*/

DECLARE

v_version text;
v_device integer;
v_feature_type text;
column_type text;
v_feature_id integer;
v_visit_id integer;
aux_json json;
array_index integer DEFAULT 0;
field_value character varying;
v_querystring text;
v_debug_vars json;
v_debug json;
v_msgerr json;
v_querytext text;
v_selected_id text;
v_selected_idval text;
v_current_id text;
v_new_id text;
v_widgetcontrols json;
v_values_array json;
v_widgetvalues json;
v_visit_type integer;
v_visit_type_name text;
v_header_text text;
v_id integer;
v_cur_user text;

v_fields_array json[];
v_fieldsjson jsonb := '[]';

form_tabs json[];
form_tabs_json json;
v_forminfo json;
v_tablename text;
v_ui_tablename text;
v_sourcetable character varying;
v_xcoord double precision;
v_ycoord double precision;
v_client_epsg integer;
v_epsg integer;
v_point public.geometry;
v_idname text;
v_layer record;
v_sql text;
v_config_layer text;
v_activelayer text;
v_visiblelayer text;
v_sensibility float;
v_sensibility_f float;
v_zoomratio double precision;
v_the_geom text;
v_schemaname text;

v_visitclass integer;
v_formname text;
v_ismultievent boolean;
v_featuretype text;
v_fields json;

v_errcontext text;
v_geometry json;
v_project_type text;

v_class_feature_type text;
v_real_feature text;
v_has_gully_visit boolean := false;

BEGIN

    -- Set search path to local schema
    SET search_path = "SCHEMA_NAME", public;
    v_schemaname := 'SCHEMA_NAME';

    -- Get api version
    SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;
    SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

    -- Get parameters from input
    v_device = ((p_data ->>'client')::json->>'device')::integer;
    v_feature_id = ((p_data ->>'feature')::json->>'id')::integer;
    v_feature_type = ((p_data ->>'feature')::json->>'featureType');
    v_visit_id = ((p_data ->>'form')::json->>'visitId');
    v_visit_type = ((p_data ->>'form')::json->>'visitType');
    v_cur_user = ((p_data ->>'client')::json->>'cur_user');
    v_xcoord := ((p_data ->> 'data')::json->> 'coordinates')::json->>'xcoord';
    v_ycoord := ((p_data ->> 'data')::json->> 'coordinates')::json->>'ycoord';
    v_zoomratio := ((p_data ->> 'data')::json->> 'coordinates')::json->>'zoomRatio';
    v_client_epsg := (p_data ->> 'client')::json->> 'epsg';
    v_epsg := (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1);
    v_fields = ((p_data ->>'data')::json->>'fields')::json;
    v_visitclass = ((p_data ->>'data')::json->>'fields')::json->>'class_id';

    IF v_client_epsg IS NULL THEN
        v_client_epsg = v_epsg;
    END IF;

    -- Make point
    IF v_visit_id IS NULL AND v_xcoord IS NOT NULL THEN
        SELECT ST_Transform(ST_SetSRID(ST_MakePoint(v_xcoord,v_ycoord),v_client_epsg),v_epsg) INTO v_point;

        -- Sensibility factor
        IF v_device = 1 OR v_device = 2 THEN
            EXECUTE 'SELECT (value::json->>''mobile'')::float FROM config_param_system WHERE parameter=''basic_info_sensibility_factor'''
            INTO v_sensibility_f;
            v_sensibility = (v_zoomratio * 10 * v_sensibility_f);

        ELSIF v_device = 3 THEN
            EXECUTE 'SELECT (value::json->>''web'')::float FROM config_param_system WHERE parameter=''basic_info_sensibility_factor'''
            INTO v_sensibility_f;
            v_sensibility = (v_zoomratio * 10 * v_sensibility_f);

        ELSIF v_device IN (4, 5) THEN
            EXECUTE 'SELECT (value::json->>''desktop'')::float FROM config_param_system WHERE parameter=''basic_info_sensibility_factor'''
            INTO v_sensibility_f;
            v_sensibility = ((v_zoomratio/5000) * 10 * v_sensibility_f);
        END IF;

        v_config_layer='config_info_layer';

        -- Get feature
        v_sql = concat(
            'SELECT DISTINCT(layer_id), orderby+100 orderby, cl.addparam->>''geomType'' as geomtype, lower(headertext) as feature_type
             FROM ', quote_ident(v_config_layer), ' cl
             JOIN cat_feature cf ON parent_layer=layer_id
             ORDER BY orderby'
        );

        FOR v_layer IN EXECUTE v_sql
        LOOP
            -- For views it suppose pk is the first column
            v_querystring = concat(
                'SELECT a.attname
                 FROM pg_attribute a
                 JOIN pg_class t on a.attrelid = t.oid
                 JOIN pg_namespace s on t.relnamespace = s.oid
                 WHERE a.attnum > 0
                   AND NOT a.attisdropped
                   AND t.relname = ''', v_layer.layer_id, '''
                   AND s.nspname = ''', v_schemaname, '''
                 ORDER BY a.attnum
                 LIMIT 1'
            );

            EXECUTE v_querystring INTO v_idname;

            -- Get geometry_column
            v_querystring = concat(
                'SELECT attname
                 FROM pg_attribute a
                 JOIN pg_class t on a.attrelid = t.oid
                 JOIN pg_namespace s on t.relnamespace = s.oid
                 WHERE a.attnum > 0
                   AND NOT a.attisdropped
                   AND t.relname = ', quote_nullable(v_layer.layer_id), '
                   AND s.nspname = ', quote_nullable(v_schemaname), '
                   AND left(pg_catalog.format_type(a.atttypid, a.atttypmod), 8)=''geometry''
                 ORDER BY a.attnum'
            );
            EXECUTE v_querystring INTO v_the_geom;

            -- Get element from active layer
            v_querystring = concat(
                'SELECT ', quote_ident(v_idname), '
                 FROM ', quote_ident(v_layer.layer_id), '
                 WHERE st_dwithin (''', v_point, ''', ', quote_ident(v_layer.layer_id), '.', quote_ident(v_the_geom), ', ', v_sensibility, ')
                 ORDER BY ST_Distance(', v_layer.layer_id, '.', v_the_geom, ', ''', v_point, ''') asc
                 LIMIT 1'
            );
            EXECUTE v_querystring INTO v_id;

            IF v_id IS NOT NULL THEN
                v_featuretype = v_layer.feature_type;
                EXIT;
            END IF;
        END LOOP;

        -- Get visit id
        IF v_visit_id IS NULL THEN
            v_visit_id := (SELECT max(id)+1 FROM om_visit);
            IF v_visit_id IS NULL THEN
                v_visit_id = nextval('om_visit_id_seq');
            END IF;
        END IF;
    END IF;

    IF v_visit_type = 2 THEN
        v_visit_type_name = 'unexpected_visit';
        v_header_text = 'INCIDENCIA - '||v_visit_id||'';
    ELSE
        v_visit_type_name = 'visit';
        v_header_text = 'VISIT - '||v_visit_id||'';
    END IF;

    -- Manage visit class
    IF v_visit_id IS NOT NULL AND v_visitclass IS NULL THEN
        v_visitclass = (SELECT class_id FROM om_visit WHERE id = v_visit_id);
    END IF;

    IF v_visitclass IS NULL THEN
        -- Prefer ALL classes for shared unexpected visits
        v_visitclass := (
            SELECT id
            FROM config_visit_class
            WHERE visit_type = v_visit_type
              AND feature_type = 'ALL'
            ORDER BY id
            LIMIT 1
        )::integer;

        -- Fallback to feature-specific if no ALL row exists
        IF v_visitclass IS NULL THEN
            v_visitclass := (
                SELECT id
                FROM config_visit_class
                WHERE visit_type = v_visit_type
                  AND feature_type = upper(v_featuretype)
                ORDER BY id
                LIMIT 1
            )::integer;
        END IF;
    END IF;

    -- Get class metadata
    SELECT formname, tablename, ui_tablename, ismultievent, feature_type
    INTO v_formname, v_tablename, v_ui_tablename, v_ismultievent, v_class_feature_type
    FROM config_visit_class
    WHERE id = v_visitclass;

    -- Resolve actual feature for ALL-template classes
    IF upper(v_class_feature_type) = 'ALL' THEN

        IF v_project_type = 'UD' AND v_visit_id IS NOT NULL THEN
            SELECT EXISTS (SELECT 1 FROM om_visit_x_gully WHERE visit_id = v_visit_id) INTO v_has_gully_visit;
        END IF;

        IF v_featuretype IS NOT NULL THEN
            v_real_feature := lower(v_featuretype);

        ELSIF v_fields IS NOT NULL AND NULLIF(v_fields->>'node_id', '') IS NOT NULL THEN
            v_real_feature := 'node';
        ELSIF v_fields IS NOT NULL AND NULLIF(v_fields->>'arc_id', '') IS NOT NULL THEN
            v_real_feature := 'arc';
        ELSIF v_fields IS NOT NULL AND NULLIF(v_fields->>'connec_id', '') IS NOT NULL THEN
            v_real_feature := 'connec';
        ELSIF v_fields IS NOT NULL AND NULLIF(v_fields->>'link_id', '') IS NOT NULL THEN
            v_real_feature := 'link';
        ELSIF v_project_type = 'UD' AND v_fields IS NOT NULL AND NULLIF(v_fields->>'gully_id', '') IS NOT NULL THEN
            v_real_feature := 'gully';

        ELSIF v_visit_id IS NOT NULL AND EXISTS (SELECT 1 FROM om_visit_x_node   WHERE visit_id = v_visit_id) THEN
            v_real_feature := 'node';
        ELSIF v_visit_id IS NOT NULL AND EXISTS (SELECT 1 FROM om_visit_x_arc    WHERE visit_id = v_visit_id) THEN
            v_real_feature := 'arc';
        ELSIF v_visit_id IS NOT NULL AND EXISTS (SELECT 1 FROM om_visit_x_connec WHERE visit_id = v_visit_id) THEN
            v_real_feature := 'connec';
        ELSIF v_visit_id IS NOT NULL AND EXISTS (SELECT 1 FROM om_visit_x_link   WHERE visit_id = v_visit_id) THEN
            v_real_feature := 'link';
        ELSIF v_has_gully_visit THEN
            v_real_feature := 'gully';

        ELSIF v_feature_type IS NOT NULL THEN
            v_real_feature := lower(v_feature_type);
        ELSE
            RAISE EXCEPTION 'Visit class % is ALL but actual feature type could not be resolved', v_visitclass;
        END IF;

        v_formname := replace(v_formname, 'all', v_real_feature);
        v_tablename := replace(v_tablename, 'all', v_real_feature);
        v_ui_tablename := replace(v_ui_tablename, 'all', v_real_feature);
        v_featuretype := upper(v_real_feature);

    ELSIF v_featuretype IS NULL THEN
        v_featuretype := v_class_feature_type;
    END IF;

    -- getting source table in order to enhance performance
    IF v_tablename LIKE 've_cad%' THEN
        v_sourcetable = v_tablename;
    ELSIF v_tablename LIKE '%link_connec%' OR v_tablename LIKE '%link_gully%' THEN
        v_sourcetable = 'link';
    ELSIF v_tablename LIKE 'v_%edit_%' THEN
        v_sourcetable = replace(v_tablename, 've_', '');
    ELSIF v_tablename LIKE 've_%node%' THEN
        v_sourcetable = 'node';
    ELSIF v_tablename LIKE 've_%arc%' THEN
        v_sourcetable = 'arc';
    ELSIF v_tablename LIKE 've_%connec%' THEN
        v_sourcetable = 'connec';
    ELSIF v_tablename LIKE 've_%gully%' THEN
        v_sourcetable = 'gully';
    ELSIF v_tablename LIKE '%hydrometer%' THEN
        v_sourcetable = 'vf_hydrometer';
    ELSIF v_tablename LIKE '%element%' THEN
        v_sourcetable = 'element';
    ELSE
        v_sourcetable = v_tablename;
    END IF;

    -- Manage fields
    IF v_visit_id IS NOT NULL AND v_tablename IS NOT NULL AND v_fields IS NULL THEN
        v_querystring = concat(
            'SELECT row_to_json(a)
             FROM (SELECT * FROM ', quote_ident(v_tablename), ' WHERE visit_id=', quote_nullable(v_visit_id), ') a'
        );
        EXECUTE v_querystring INTO v_fields;
    END IF;

    -- Get tabs
    v_querystring = concat(
        'SELECT array_agg(row_to_json(a))
         FROM (
            SELECT DISTINCT ON (tabname, orderby)
                tabname as "tabName",
                label as "tabLabel",
                tooltip as "tooltip",
                NULL as "tabFunction",
                NULL AS "tabactions",
                orderby
            FROM v_config_form_tabs
            WHERE formname = ''', v_formname, '''
              AND ', v_device, ' = ANY(device)
              AND orderby IS NOT NULL
            ORDER BY orderby, tabname
         ) a'
    );

    v_debug_vars := json_build_object('v_tablename', v_tablename, 'v_device', v_device);
    v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getinfofromid', 'flag', 180);
    SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
    EXECUTE v_querystring INTO form_tabs;

    form_tabs_json := array_to_json(form_tabs);

    -- Form Tabs info
    v_forminfo := gw_fct_json_object_set_key(v_forminfo, 'visibleTabs', form_tabs_json);

    -- Get fields
    SELECT gw_fct_getformfields(
        v_formname,
        'form_visit',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    ) INTO v_fields_array;

    -- looping the array setting values and widgetcontrols
    FOREACH aux_json IN ARRAY v_fields_array
    LOOP
        array_index := array_index + 1;

        IF v_fields IS NOT NULL THEN
            field_value = v_fields::json->>(aux_json->>'columnname');
        ELSE
            IF aux_json->>'columnname' = 'visit_id' THEN
                field_value = v_visit_id;
            ELSIF aux_json->>'columnname' = 'user_name' THEN
                field_value = v_cur_user;
            ELSIF aux_json->>'columnname' = 'feature_id' OR aux_json->>'columnname' = v_idname THEN
                field_value = v_id;
            ELSIF aux_json->>'columnname' = 'class_id' THEN
                field_value = v_visitclass;
            ELSE
                field_value := (v_values_array->>(aux_json->>'columnname'));
            END IF;
        END IF;

        -- setting values
        IF (aux_json->>'widgettype')='combo' THEN
            -- Plain combos load their items asynchronously in Python from
            -- dv_querytext, so there is no comboIds list to validate against
            -- here. Forward selectedId; the Python widget is responsible for
            -- showing the selected id even before its full list is loaded.
            v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'selectedId', COALESCE(field_value, ''));

        ELSIF (aux_json->>'widgettype') != 'button' THEN
            v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'value', COALESCE(field_value, ''));
        END IF;

        -- setting widgetcontrols
        IF (aux_json->>'datatype')='double' OR (aux_json->>'datatype')='integer' OR (aux_json->>'datatype')='numeric' THEN
            IF v_widgetvalues IS NOT NULL THEN
                v_widgetcontrols = gw_fct_json_object_set_key((aux_json->>'widgetcontrols')::json, 'maxMinValues', (v_widgetvalues->>(aux_json->>'columnname'))::json);
                v_fields_array[array_index] := gw_fct_json_object_set_key(v_fields_array[array_index], 'widgetcontrols', v_widgetcontrols);
            END IF;
        END IF;
    END LOOP;

    v_fieldsjson := to_json(v_fields_array);

    -- Get id column type
    EXECUTE 'SELECT pg_catalog.format_type(a.atttypid, a.atttypmod)
             FROM pg_attribute a
             JOIN pg_class t on a.attrelid = t.oid
             JOIN pg_namespace s on t.relnamespace = s.oid
             WHERE a.attnum > 0
               AND NOT a.attisdropped
               AND a.attname = $3
               AND t.relname = $2
               AND s.nspname = $1
             ORDER BY a.attnum'
    USING v_schemaname, v_sourcetable, v_idname
    INTO column_type;

    -- Get geometry (to feature response)
    IF v_the_geom IS NOT NULL AND v_id IS NOT NULL THEN
        EXECUTE 'SELECT row_to_json(row)
                 FROM (
                    SELECT ST_x(ST_centroid(ST_envelope(the_geom))) AS x,
                           ST_y(ST_centroid(ST_envelope(the_geom))) AS y,
                           St_AsText('||quote_ident(v_the_geom)||')
                    FROM '||quote_ident(v_sourcetable)||'
                    WHERE '||quote_ident(v_idname)||' = CAST('||quote_nullable(v_id)||' AS '||(column_type)||')
                 ) row'
        INTO v_geometry;
    END IF;

    -- Get geometry for elements without geometry
    IF v_the_geom IS NOT NULL AND v_sourcetable = 'element' THEN
        IF v_geometry IS NULL THEN
            IF v_project_type = 'WS' THEN
                SELECT row_to_json(c)
                INTO v_geometry
                FROM (
                    SELECT st_x(st_centroid(st_envelope(the_geom))) as x,
                           st_y(st_centroid(st_envelope(the_geom))) as y,
                           St_AsText(the_geom)
                    FROM (
                        SELECT st_union(array_agg(the_geom)) as the_geom
                        FROM (
                            SELECT the_geom, element_id FROM arc JOIN element_x_arc USING (arc_id)
                            UNION
                            SELECT the_geom, element_id FROM node JOIN element_x_node USING (node_id)
                            UNION
                            SELECT the_geom, element_id FROM connec JOIN element_x_connec USING (connec_id)
                        ) a
                        WHERE element_id = v_id
                    ) b
                ) c;
            ELSIF v_project_type = 'UD' THEN
                SELECT row_to_json(c)
                INTO v_geometry
                FROM (
                    SELECT st_x(st_centroid(st_envelope(the_geom))) as x,
                           st_y(st_centroid(st_envelope(the_geom))) as y,
                           St_AsText(the_geom)
                    FROM (
                        SELECT st_union(array_agg(the_geom)) as the_geom
                        FROM (
                            SELECT the_geom, element_id FROM arc JOIN element_x_arc USING (arc_id)
                            UNION
                            SELECT the_geom, element_id FROM node JOIN element_x_node USING (node_id)
                            UNION
                            SELECT the_geom, element_id FROM gully JOIN element_x_gully USING (gully_id)
                            UNION
                            SELECT the_geom, element_id FROM connec JOIN element_x_connec USING (connec_id)
                        ) a
                        WHERE element_id = v_id
                    ) b
                ) c;
            END IF;
        END IF;
    END IF;

    -- Control NULL's
    v_forminfo := COALESCE(v_forminfo, '{}');
    v_forminfo := gw_fct_json_object_set_key(v_forminfo,'headerText',v_header_text);

    -- Return
    RETURN ('{
        "status": "Accepted",
        "version": "'|| COALESCE(v_version, '') ||'",
        "body": {
            "data": {
                "form": '|| v_forminfo ||',
                "fields": '|| COALESCE(v_fieldsjson::text, '[]') ||',
                "feature": {
                    "idName": "'|| COALESCE(v_idname, '') ||'",
                    "'|| COALESCE(v_idname, '') ||'": "'|| COALESCE(v_id::text, '') ||'",
                    "visitId": "'|| COALESCE(v_visit_id::text, '') ||'",
                    "geometry": '|| COALESCE(v_geometry::text, 'null') ||'
                }
            }
        }
    }')::json;

END;
$function$;

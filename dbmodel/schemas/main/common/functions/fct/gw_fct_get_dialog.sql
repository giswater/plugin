/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3348

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_get_dialog(json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_get_dialog(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$


/*EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_get_dialog($${"client":{"device":5, "lang":"es_ES", "cur_user": "bgeo", "infoType":1, "epsg":SRID_VALUE},
"form":{"formName": "generic","formType":"nvo_manager"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}}}$$);

SELECT SCHEMA_NAME.gw_fct_get_dialog($${"client":{"device":5, "lang":"es_ES", "cur_user": "bgeo", "infoType":1, "epsg":SRID_VALUE},
"form":{"formName": "generic","formType":"nvo_roughness", "tableName":"cat_mat_roughness", "id":"id", "idval":1},
 "feature":{}, "data":{"filterFields":{}, "pageInfo":{}}}$$);

*/

DECLARE

v_array_index integer DEFAULT 0;
v_field_value text;
v_aux_json json;
v_form text;
v_device integer;
v_version text;
v_fields_array json[];
v_querystring text;
v_fieldsjson jsonb := '[]';
v_form_tabs_json json;
v_form_tabs_layouts jsonb;
v_cur_user text;
v_formname text;
v_formtype text;
v_layouts text[];
v_layout text;
v_addparam json;
v_error_context text;
v_widget jsonb;
v_tab_name text;
v_tab_names jsonb;
v_tab_data jsonb;
v_tablename text;
v_idname text;
v_id text;
v_idname_array text[];
v_id_array text[];
v_values_array json;
v_field jsonb;
v_result jsonb;
v_tabsjson jsonb := '[]';
v_tabnames_to_remove text[];
v_layouts_to_remove text[];
v_role TEXT[];
v_widget_roles jsonb;
v_filtered_fields_array jsonb := '[]';

BEGIN
    -- Set search path to local schema
    SET search_path = "SCHEMA_NAME", public;

    -- Get api version
    SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

    -- Get parameters from input
    v_device = ((p_data ->>'client')::json->>'device')::integer;
    v_cur_user = ((p_data ->>'client')::json->>'cur_user');
	v_formname = ((p_data ->>'form')::json->>'formName');
	v_formtype = ((p_data ->>'form')::json->>'formType');
	v_tablename = ((p_data ->>'form')::json->>'tableName');
	v_idname = ((p_data ->>'form')::json->>'idname');
	v_id = ((p_data ->>'form')::json->>'id');

    -- Get fields
    SELECT gw_fct_getformfields(
        v_formname,
        v_formtype,
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

	IF array_length(v_fields_array, 1) IS NULL THEN
    	RAISE EXCEPTION 'Variable v_fields_array is empty. Check the "formName" or "formType" parameters: %', v_fields_array;
	END IF;
	IF v_tablename IS NOT NULL AND (v_idname IS NOT NULL OR v_id IS NOT NULL) THEN

		-- Accept multiple idnames and ids
	    IF v_idname IS NOT NULL AND v_id IS NOT NULL THEN
	        v_idname_array := string_to_array(v_idname, ', ');
	        v_id_array := string_to_array(v_id, ', ');
	    END IF;

	    v_querystring := 'SELECT row_to_json(a) FROM (SELECT * FROM ' || quote_ident(v_tablename);

	    IF cardinality(v_idname_array) > 0 AND cardinality(v_id_array) > 0 THEN
	        v_querystring := v_querystring || ' WHERE ';
	        FOR i IN 1..cardinality(v_idname_array) LOOP
	            v_querystring := v_querystring || quote_ident(v_idname_array[i]) || ' = ' || quote_literal(v_id_array[i]) || ' AND ';
	        END LOOP;

	        v_querystring := substring(v_querystring FROM 1 FOR length(v_querystring) - 5);
	    END IF;

	    v_querystring := v_querystring || ') a;';
	    EXECUTE v_querystring INTO v_values_array;

		-- looping the array setting values
		FOREACH v_aux_json IN ARRAY v_fields_array
		LOOP
			v_array_index := v_array_index + 1;

			v_field_value := (v_values_array->>(v_aux_json->>'columnname'));

			-- setting values
			IF (v_aux_json->>'widgettype')='combo' THEN
				v_fields_array[v_array_index] := gw_fct_json_object_set_key(v_fields_array[v_array_index], 'selectedId', COALESCE(v_field_value, ''));
			ELSIF (v_aux_json->>'widgettype')='button' and json_extract_path_text(v_aux_json,'widgetcontrols','text') IS NOT NULL THEN
				v_fields_array[v_array_index] := gw_fct_json_object_set_key(v_fields_array[v_array_index], 'value', json_extract_path_text(v_aux_json,'widgetcontrols','text'));
			ELSE
				v_fields_array[v_array_index] := gw_fct_json_object_set_key(v_fields_array[v_array_index], 'value', COALESCE(v_field_value, ''));
			END IF;

		END LOOP;
	END IF;

    -- Loop through widgets
    FOR i IN 1 .. array_length(v_fields_array, 1) LOOP
	    v_widget := v_fields_array[i];

	    -- Check if widgettype is tabwidget
	    IF v_widget->>'widgettype' = 'tabwidget' THEN
	        -- Get the tabs
	        v_tab_names := v_widget->'widgetcontrols'->'tabs';

	        -- Initialize form_tabs_json
	        v_form_tabs_json := '[]';

	        -- Loop through each tab name
	        FOR v_tab_name IN SELECT jsonb_array_elements_text(v_tab_names)
	        LOOP
	            -- Get tab information from config_form_tabs
	           v_querystring := concat(
				    'SELECT row_to_json(a) FROM (',
				    'SELECT DISTINCT ON (t.tabname, t.orderby) ',
				    't.tabname as "tabName", t.label as "tabLabel", t.tooltip as "tooltip", ',
				    'NULL as "tabFunction", NULL AS "tabactions", t.orderby, ',
				    'ct.addparam as "addparam" ',
				    'FROM v_config_form_tabs t ',
				    'LEFT JOIN config_typevalue ct ON ct.typevalue = ''tabname_typevalue'' AND ct.id = t.tabname ',
				    'WHERE t.tabname = ''', v_tab_name, ''' ',
				    'AND t.formname = ''', v_formtype, ''' AND ', v_device,
				    ' = ANY(t.device) AND t.orderby IS NOT NULL ',
				    'ORDER BY t.orderby, t.tabname) a'
				);

				EXECUTE v_querystring INTO v_tab_data;

	            -- Get tab layouts
	            v_querystring := concat(
	                'SELECT value as layouts FROM config_param_system WHERE parameter = concat(',
	                '''', v_formtype, ''', ''_'', ''', v_tab_name, ''')'
	            );

	            EXECUTE v_querystring INTO v_form_tabs_layouts;

				-- Add layouts to v_tab_data
				IF v_form_tabs_layouts IS NOT NULL THEN
				    v_tab_data := jsonb_set(
				        v_tab_data,
				        '{layouts}',
				        to_jsonb(v_form_tabs_layouts->'layouts'),
				        true
				    );
				END IF;

	            -- Add v_tab_data to form_tabs_json
	            IF v_tab_data IS NOT NULL THEN
	                v_form_tabs_json := jsonb_set(
	                    v_form_tabs_json::jsonb,
	                    concat('{', jsonb_array_length(v_form_tabs_json::jsonb), '}')::text[],
	                    to_jsonb(v_tab_data),
	                    true
	                );
	            END IF;
	        END LOOP;

	        -- Update widget JSON with tabs in form_tabs_json
	        v_widget := jsonb_set(v_widget, format('{tabs_%s}', v_widget->>'columnname')::text[], v_form_tabs_json::jsonb, true);

			-- Remove wdgetcontrols
			v_widget := v_widget - 'widgetcontrols';

	        -- Replace tabwidget json with updated values
	        v_fields_array[i] := v_widget;

	    ELSE
			-- If inserting and field_value is NULL or empty, check widget controls for defaults
			IF (p_data->>'form')::json->>'id' IS NULL AND (v_field_value IS NULL OR v_field_value = '') THEN
			    IF (v_widget->>'widgetcontrols') IS NOT NULL THEN
			        -- Handle combo box default value logic
			        IF (v_widget->>'widgettype') = 'combo' THEN
			            IF ((v_widget->'widgetcontrols')::jsonb ? 'vdefault_value') THEN
			                IF ((v_widget->'widgetcontrols')::json->>'vdefault_value') IN
			                    (SELECT a FROM json_array_elements_text(json_extract_path(v_fields_array[v_array_index], 'comboIds')) a)
			                THEN
			                    v_field_value := (v_widget->'widgetcontrols')::json->>'vdefault_value';
			                END IF;
			            ELSIF ((v_widget->'widgetcontrols')::jsonb ? 'vdefault_querytext') THEN
			                EXECUTE (v_widget->'widgetcontrols')::json->>'vdefault_querytext' INTO v_field_value;
			                IF v_field_value IN
			                    (SELECT a FROM json_array_elements_text(json_extract_path(v_fields_array[v_array_index], 'comboIds')) a)
			                THEN
			                    -- Assign default query text if valid
			                    v_field_value := v_field_value;
			                END IF;
			            END IF;
			        ELSE
			            -- Handle non-combo default values
			            IF ((v_widget->'widgetcontrols')::jsonb ? 'vdefault_value') THEN
			                v_field_value := (v_widget->'widgetcontrols')::json->>'vdefault_value';
			            ELSIF ((v_widget->'widgetcontrols')::jsonb ? 'vdefault_querytext') THEN
			                EXECUTE (v_widget->'widgetcontrols')::json->>'vdefault_querytext' INTO v_field_value;
			            END IF;
			        END IF;
					IF v_field_value IS NOT NULL AND v_field_value != '' THEN
						v_widget := jsonb_set(v_widget, '{value}', to_jsonb(COALESCE(v_field_value, '')));
						v_widget := v_widget - 'widgetcontrols';
		        		v_fields_array[i] := v_widget;
						v_field_value := '';
					END IF;
			    END IF;
			END IF;
	    END IF;
	END LOOP;

    v_fieldsjson := to_jsonb(v_fields_array);

	-- Manage null
	v_version := COALESCE(v_version, '');
 	v_fieldsjson := COALESCE(v_fieldsjson, '[]');

	-- If there are tabs in dialog:
	IF jsonb_path_exists(v_fieldsjson, '$.**.tabs_tab_main') AND ((p_data ->>'form')::json->>'id') IS NOT NULL THEN
		-- REMOVE EMPTY TABS (WITH EMPTY TABLEWIDGETS)
		-- Get tabnames to remove with empty table widgets
	    FOREACH v_field IN ARRAY ARRAY(SELECT jsonb_array_elements(v_fieldsjson)) LOOP
			IF v_field->>'widgettype' IN ('tablewidget', 'tableview') AND
				(v_field->>'widgetcontrols')::json->>'filter' IS DISTINCT FROM 'false' THEN

				v_result := gw_fct_getlist(
			        json_build_object(
			            'client', p_data ->>'client',
			            'form', '{}',
			            'feature', json_build_object('tableName', v_field->>'linkedobject'),
			            'data', json_build_object(
				            'filterFields', json_build_object(
				                ((p_data ->>'form')::json->>'idname'), json_build_object(
				                    'value',  ((p_data ->>'form')::json->>'id'),
				                    'filterSign', '='
				                )
				            )
				        )
			        )
			    )::jsonb #>> '{body, data, fields, 0, value}';

	            IF v_result IS NULL THEN
					v_tabnames_to_remove := array_append(v_tabnames_to_remove, v_field->>'tabname');
					v_layouts_to_remove := array_append(v_layouts_to_remove, v_field->>'layoutname');
	            END IF;
			END IF;
	    END LOOP;

		-- Include tabs where tabName is not in v_tabnames (tab to remove)
		v_tabsjson := (
	        SELECT jsonb_agg(tab) FROM jsonb_array_elements(v_fieldsjson) AS field,
	        jsonb_array_elements(field->'tabs_tab_main') AS tab
	    	WHERE tab->>'tabName' NOT IN (SELECT unnest(v_tabnames_to_remove))
	    );

		 -- Update tabs when the key is 'tabs'
		 v_fieldsjson := (
	        SELECT jsonb_agg(
	            CASE
	                WHEN field->>'tabs_tab_main' IS NOT NULL THEN
						jsonb_set(field, '{tabs_tab_main}', to_jsonb(v_tabsjson))
	            ELSE
					field
	            END
	        )
	        FROM jsonb_array_elements(v_fieldsjson) AS field
		  );

		-- Remove empty table_views
		v_fieldsjson := (
			SELECT json_agg(field) FROM jsonb_array_elements(v_fieldsjson)
			AS field WHERE field->>'tabs_tab_main' IS NOT NULL OR field->>'tabname' NOT IN (SELECT unnest(v_tabnames_to_remove))
		);
	END IF;

	-- Create JSON from layouts
	SELECT array_agg(distinct layoutname) into v_layouts FROM v_config_form_fields  WHERE formtype = v_formtype;

	v_form:= '"layouts": {';

	-- Add form layout
	SELECT addparam INTO v_addparam FROM config_typevalue WHERE id = v_formtype;
	v_form := concat(v_form, '"', v_formtype, '":', coalesce(v_addparam, '{}'), ',');

	FOREACH v_layout IN ARRAY v_layouts
	LOOP
		IF v_layout NOT IN (SELECT unnest(v_layouts_to_remove)) THEN
			select addparam into v_addparam from config_typevalue where id = v_layout;
			v_form:= concat(v_form,  '"', v_layout, '":',coalesce(v_addparam, '{}'),',');
		END IF;
	END LOOP;

	v_form := left(v_form, length(v_form) - 1);
	v_form:= concat(v_form,'}' );

	-- Return JSON
	RETURN gw_fct_json_create_return(('{
        "status": "Accepted",
        "version": "' || v_version || '",
        "body": {
			"form":{' || v_form || '
			},
            "data": {
                "fields": ' || v_fieldsjson || '
            }
        }
    }')::json, 3348, null, null, null)::json;


EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
        RETURN ('{"status":"Failed","NOSQLERR":' || to_json(SQLERRM) || ',"SQLSTATE":' || to_json(SQLSTATE) ||
            ',"SQLCONTEXT":' || to_json(v_error_context) || '}')::json;
END;

$function$
;

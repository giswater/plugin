/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- common
ALTER TABLE inp_dscenario_controls ADD observ text NULL;
ALTER TABLE inp_dscenario_inlet ADD observ text NULL;
ALTER TABLE inp_dscenario_junction ADD observ text NULL;
ALTER TABLE inp_dscenario_frpump ADD observ text NULL;


DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT formname, COALESCE(MAX(layoutorder), 0) AS max_layoutorder
        FROM config_form_fields
        WHERE formname LIKE 'inp_dscenario_%'
        GROUP BY formname
    LOOP
        INSERT INTO config_form_fields (
            formname, formtype, tabname, columnname, layoutname, layoutorder,
            "datatype", widgettype, "label", tooltip, placeholder,
            ismandatory, isparent, iseditable, isautoupdate, isfilter,
            dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id,
            dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction,
            linkedobject, hidden, web_layoutorder
        ) VALUES (
            r.formname, 'form_feature', 'tab_none', 'observ', NULL, r.max_layoutorder + 1,
            'string', 'textarea', 'Observ', 'observ', NULL,
            false, false, true, false, NULL,
            NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL,
            NULL, false, NULL
        );
    END LOOP;
END $$;

UPDATE sys_function
   SET descript = 'Function for getting features filtering by sys_type, featureType or config_form_list tableName'
 WHERE id = 3484;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4680, 'GeoJSON output requires a the_geom column in the resolved query for tableName %tableName%', 'Include the_geom in config_form_list.query_text', 2, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3566, 'gw_fct_build_filters_sql', 'utils', 'function', 'json, text', 'text', 'Build SQL AND clauses from filterFields json for list and feature queries', NULL, NULL, 'core', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3568, 'gw_fct_resolve_list_query', 'utils', 'function', 'text, integer', 'json', 'Resolve config_form_list query_text and metadata for a listname', NULL, NULL, 'core', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3570, 'gw_fct_build_canvas_filter_sql', 'utils', 'function', 'text, double precision, double precision, double precision, double precision, integer', 'text', 'Build SQL canvas extend filter for a geometry expression', NULL, NULL, 'core', NULL)
ON CONFLICT (id) DO NOTHING;

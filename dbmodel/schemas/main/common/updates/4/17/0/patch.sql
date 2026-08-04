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

INSERT INTO config_param_user (parameter, value, cur_user)
VALUES ('utils_language_ui', '{"status":true, "lang":"en_US"}', current_user)
ON CONFLICT (parameter, cur_user) DO NOTHING;

DO $patch$
BEGIN
    IF to_regprocedure('gw_fct_get_utils_language_ui()') IS NOT NULL THEN
        ALTER FUNCTION gw_fct_get_utils_language_ui() VOLATILE;
    END IF;
END $patch$;



INSERT INTO sys_param_user (
    id, formname, descript, sys_role, "label", dv_querytext, isenabled, layoutorder,
    project_type, isparent, isautoupdate, "datatype", widgettype, ismandatory,
    layoutname, iseditable, "source", dv_isnullvalue
)
VALUES (
    'multilang_language', 'config',
    'UI language for database messages when multilang schema is enabled',
    'role_basic', 'UI language',
    'SELECT ''default'' AS id, ''Default'' AS idval UNION ALL SELECT id, idval FROM multilang.cat_language',
    false, 6, 'utils', false, false, 'string', 'combo', false,
    'lyt_basic', true, 'core', false
)
ON CONFLICT (id) DO UPDATE SET
    dv_querytext = EXCLUDED.dv_querytext,
    dv_isnullvalue = false,
    isenabled = CASE
        WHEN to_regclass('multilang.cat_language') IS NULL THEN false
        ELSE sys_param_user.isenabled
    END;


INSERT INTO config_param_user (parameter, value, cur_user)
SELECT
    'multilang_language',
    lower(replace(value::json->>'lang', '-', '_')),
    cur_user
FROM config_param_user
WHERE parameter = 'utils_language_ui'
  AND value IS NOT NULL
  AND btrim(value) <> ''
  AND value::json->>'lang' IS NOT NULL
  AND btrim(value::json->>'lang') <> ''
ON CONFLICT (parameter, cur_user) DO UPDATE SET value = EXCLUDED.value;


DELETE FROM config_param_user WHERE parameter = 'utils_language_ui';
DELETE FROM sys_param_user WHERE id = 'utils_language_ui';


UPDATE sys_param_user
SET
    dv_querytext = 'SELECT ''default'' AS id, ''Default'' AS idval UNION ALL SELECT id, idval FROM multilang.cat_language',
    dv_isnullvalue = false,
    isenabled = CASE
        WHEN to_regclass('multilang.cat_language') IS NULL THEN false
        ELSE isenabled
    END
WHERE id = 'multilang_language';


ALTER TABLE cat_feature ADD custom_code_autofill bool DEFAULT false NULL;
ALTER TABLE config_mapzones ADD custom_code_autofill bool DEFAULT false NULL;

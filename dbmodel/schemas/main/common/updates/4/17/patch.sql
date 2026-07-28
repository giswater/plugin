/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;


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

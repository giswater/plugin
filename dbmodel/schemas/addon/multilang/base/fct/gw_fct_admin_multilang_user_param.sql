/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_multilang_user_param(boolean);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_multilang_user_param(boolean, text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_multilang_user_param(
    p_enable boolean,
    p_schema_name text DEFAULT NULL
)
RETURNS json AS
$BODY$
/*
Enable or disable multilang_language in sys_param_user for WS/UD network schemas.
When p_schema_name is NULL, all eligible schemas are updated.
*/
DECLARE
    v_schema record;
    v_project_type text;
    v_dv_querytext text;
    v_count integer := 0;
BEGIN
    SET search_path = multilang, public;

    IF p_enable IS TRUE AND to_regclass('multilang.cat_language') IS NULL THEN
        p_enable := FALSE;
    END IF;

    -- No ORDER BY here: gw_fct_getconfig wraps dv_querytext with its own ORDER BY.
    v_dv_querytext :=
        'SELECT ''default'' AS id, ''Default'' AS idval '
        'UNION ALL SELECT id, idval FROM multilang.cat_language';

    FOR v_schema IN
        SELECT n.nspname AS schema_name
        FROM pg_namespace n
        WHERE n.nspname NOT LIKE 'pg_%'
          AND n.nspname <> 'information_schema'
          AND (p_schema_name IS NULL OR n.nspname = btrim(p_schema_name))
          AND EXISTS (
              SELECT 1
              FROM pg_class c
              WHERE c.relnamespace = n.oid
                AND c.relname = 'sys_version'
          )
          AND EXISTS (
              SELECT 1
              FROM pg_class c
              WHERE c.relnamespace = n.oid
                AND c.relname = 'sys_param_user'
          )
    LOOP
        BEGIN
            EXECUTE format(
                'SELECT upper(project_type)
                 FROM %I.sys_version
                 ORDER BY id DESC
                 LIMIT 1',
                v_schema.schema_name
            ) INTO v_project_type;

            IF v_project_type NOT IN ('WS', 'UD') THEN
                CONTINUE;
            END IF;

            EXECUTE format(
                'INSERT INTO %I.sys_param_user (
                    id, formname, descript, sys_role, "label", dv_querytext, isenabled,
                    layoutorder, project_type, isparent, isautoupdate, "datatype",
                    widgettype, ismandatory, layoutname, iseditable, "source", dv_isnullvalue
                ) VALUES (
                    ''multilang_language'', ''config'',
                    ''UI language for database messages when multilang schema is enabled'',
                    ''role_basic'', ''UI language'', %L, %L,
                    6, ''utils'', false, false, ''string'', ''combo'', false,
                    ''lyt_basic'', true, ''core'', false
                )
                ON CONFLICT (id) DO UPDATE SET
                    isenabled = EXCLUDED.isenabled,
                    dv_querytext = EXCLUDED.dv_querytext,
                    dv_isnullvalue = false',
                v_schema.schema_name,
                v_dv_querytext,
                p_enable
            );

            v_count := v_count + 1;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END LOOP;

    RETURN json_build_object('status', 'Accepted', 'schemas', v_count);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

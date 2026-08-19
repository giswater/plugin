/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_manage_multilang_views(boolean);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_manage_multilang_views(boolean, text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_manage_multilang_views(
    p_enable boolean,
    p_schema_name text DEFAULT NULL
)
RETURNS json AS
$BODY$
/*
Recreate UI translation views (v_*) in WS/UD/CM schemas.
When p_enable is TRUE, views LEFT JOIN multilang.* and COALESCE translated columns.
When FALSE, views are dropped and recreated as plain SELECT * copies of the base tables.
When p_schema_name is NULL, all eligible schemas are updated.
*/
DECLARE
    v_schema record;
    v_project_type text;
    v_count integer := 0;
    v_name text[] := ARRAY[]::text[];
    v_table text;
    v_view text;
    v_errors jsonb := '[]'::jsonb;
    v_error_context text;
    v_prev_search_path text;
    v_tables text[] := ARRAY[
        'config_form_fields',
        'config_form_tabs',
        'config_param_system',
        'sys_param_user',
        'sys_message',
        'sys_function',
        'sys_fprocess',
        'sys_table'
    ];
BEGIN
    v_prev_search_path := current_setting('search_path');
    PERFORM set_config('search_path', 'multilang, public', true);

    IF p_enable IS TRUE AND to_regnamespace('multilang') IS NULL THEN
        p_enable := FALSE;
    END IF;

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
    LOOP
        BEGIN
            EXECUTE format(
                'SELECT upper(project_type)
                 FROM %I.sys_version
                 ORDER BY id DESC
                 LIMIT 1',
                v_schema.schema_name
            ) INTO v_project_type;

            IF v_project_type NOT IN ('WS', 'UD', 'CM') THEN
                CONTINUE;
            END IF;

            FOREACH v_table IN ARRAY v_tables
            LOOP
                v_view := 'v_' || v_table;
                IF to_regclass(format('%I.%I', v_schema.schema_name, v_table)) IS NULL THEN
                    CONTINUE;
                END IF;

                BEGIN
                    EXECUTE format(
                        'DROP VIEW IF EXISTS %I.%I',
                        v_schema.schema_name, v_view
                    );
                    IF p_enable IS TRUE THEN
                        PERFORM multilang.gw_fct_admin_build_multilang_view_sql(
                            v_schema.schema_name, v_table
                        );
                    ELSE
                        EXECUTE format(
                            'CREATE VIEW %I.%I AS SELECT * FROM %I.%I',
                            v_schema.schema_name, v_view,
                            v_schema.schema_name, v_table
                        );
                        EXECUTE format(
                            'GRANT SELECT ON TABLE %I.%I TO role_basic',
                            v_schema.schema_name, v_view
                        );
                    END IF;

                    v_name := array_append(v_name, v_view);
                EXCEPTION WHEN OTHERS THEN
                    PERFORM set_config('search_path', v_prev_search_path, true);
                    v_errors := v_errors || jsonb_build_array(
                        jsonb_build_object(
                            'schema', v_schema.schema_name,
                            'view', v_view,
                            'table', v_table,
                            'error', SQLERRM,
                            'sqlstate', SQLSTATE
                        )
                    );
                END;
            END LOOP;

            v_count := v_count + 1;
        EXCEPTION WHEN OTHERS THEN
            PERFORM set_config('search_path', v_prev_search_path, true);
            v_errors := v_errors || jsonb_build_array(
                jsonb_build_object(
                    'schema', v_schema.schema_name,
                    'error', SQLERRM,
                    'sqlstate', SQLSTATE
                )
            );
        END;
    END LOOP;

    PERFORM set_config('search_path', v_prev_search_path, true);
    IF jsonb_array_length(v_errors) > 0 THEN
        RETURN json_build_object(
            'status', 'Failed',
            'message', json_build_object(
                'level', 2,
                'text', format(
                    'Multilang views provisioning failed (%s error(s)).',
                    jsonb_array_length(v_errors)
                )
            ),
            'errors', v_errors,
            'schemas', v_count,
            'enabled', p_enable,
            'views', v_name
        );
    END IF;

    RETURN json_build_object(
        'status', 'Accepted',
        'message', json_build_object(
            'level', 1,
            'text', format('Multilang views updated for %s schema(s).', v_count)
        ),
        'schemas', v_count,
        'enabled', p_enable,
        'views', v_name
    );
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    PERFORM set_config('search_path', v_prev_search_path, true);
    RETURN json_build_object(
        'status', 'Failed',
        'NOSQLERR', SQLERRM,
        'message', json_build_object(
            'level', 2,
            'text', SQLERRM
        ),
        'SQLSTATE', SQLSTATE,
        'SQLCONTEXT', v_error_context
    );
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

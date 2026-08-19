/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cm, public, pg_catalog;

-- Create UI translation views (v_*). JOIN multilang when present; otherwise plain copies.
DO $BODY$
DECLARE
    v_schema text := 'cm';
    v_tables text[] := ARRAY[
        'config_form_fields',
        'config_form_tabs',
        'config_param_system',
        'sys_param_user',
        'sys_table',
        'config_form_tableview'
    ];
    v_table text;
BEGIN
    IF to_regnamespace('multilang') IS NOT NULL
       AND to_regprocedure('multilang.gw_fct_admin_manage_multilang_views(boolean, text)') IS NOT NULL
    THEN
        PERFORM multilang.gw_fct_admin_manage_multilang_views(true, v_schema);
    ELSE
        FOREACH v_table IN ARRAY v_tables
        LOOP
            IF to_regclass(format('%I.%I', v_schema, v_table)) IS NOT NULL THEN
                EXECUTE format('DROP VIEW IF EXISTS %I.%I', v_schema, 'v_' || v_table);
                EXECUTE format(
                    'CREATE VIEW %I.%I AS SELECT * FROM %I.%I',
                    v_schema, 'v_' || v_table,
                    v_schema, v_table
                );
                EXECUTE format(
                    'GRANT SELECT ON TABLE %I.%I TO role_basic',
                    v_schema, 'v_' || v_table
                );
            END IF;
        END LOOP;
    END IF;
END
$BODY$;

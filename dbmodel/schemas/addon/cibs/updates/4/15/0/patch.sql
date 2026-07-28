/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cibs, public, pg_catalog;

DO $patch$
DECLARE
    rec_schema text;
    v_parent_schemas jsonb;
    v_save_payload json;
    v_restore_payload json;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'cibs'
          AND c.relname = 'hydrometer'
          AND a.attname = 'wmeter_number'
          AND NOT a.attisdropped
          AND format_type(a.atttypid, a.atttypmod) = 'text'
    ) THEN
        RETURN;
    END IF;

    SELECT addparam -> 'parent_schemas'
    INTO v_parent_schemas
    FROM cibs.sys_version
    ORDER BY id DESC
    LIMIT 1;

    v_save_payload := json_build_object(
        'data', json_build_object(
            'action', 'SAVE-DROP',
            'rootViews', json_build_array('v_hydrometer'),
            'batchId', 1
        )
    );

    v_restore_payload := json_build_object(
        'data', json_build_object(
            'action', 'RESTORE',
            'batchId', 1
        )
    );

    IF v_parent_schemas IS NOT NULL THEN
        FOR rec_schema IN
            SELECT jsonb_array_elements_text(v_parent_schemas)
        LOOP
            CONTINUE WHEN to_regclass(format('%I.v_hydrometer', rec_schema)) IS NULL;

            EXECUTE format(
                'SELECT %I.gw_fct_admin_manage_view_dependencies($1)',
                rec_schema
            ) USING v_save_payload;
        END LOOP;
    END IF;

    ALTER TABLE cibs.hydrometer ALTER COLUMN wmeter_number TYPE text USING wmeter_number::text;

    IF v_parent_schemas IS NOT NULL THEN
        FOR rec_schema IN
            SELECT jsonb_array_elements_text(v_parent_schemas)
        LOOP
            CONTINUE WHEN to_regclass(format('%I.ext_hydrometer_old', rec_schema)) IS NULL;

            EXECUTE format(
                'CREATE OR REPLACE VIEW %I.v_hydrometer AS SELECT * FROM cibs.hydrometer',
                rec_schema
            );

            EXECUTE format(
                'SELECT %I.gw_fct_admin_manage_view_dependencies($1)',
                rec_schema
            ) USING v_restore_payload;
        END LOOP;
    END IF;
END $patch$;

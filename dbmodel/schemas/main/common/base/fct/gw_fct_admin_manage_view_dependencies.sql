
/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3542

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_manage_view_dependencies(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_manage_view_dependencies(p_data json)
RETURNS json AS
$BODY$

/*
PURPOSE
    Recursively discovers dependent views and materialized views (any schema), saves their
    definitions, drops them in safe order, and restores them after parent views are recreated.

INTENDED USE CASES (automatic restore works)
    - Adding new columns to a parent view without removing existing ones.
    - Widening or changing output column types without dropping columns.
      Dependents that reference columns by name (without explicit incompatible casts) are
      recreated with the same SQL and pick up the new types from the parent.
    - Replacing parent table/view references during RESTORE via the replacements parameter
      (e.g. ext_municipality -> v_municipality after introducing an intermediate view).

ROOT OBJECTS
    rootViews accepts views, materialized views, and tables (relkind v, m, r).
    Tables are never dropped, even when dropRoots is true; only views and matviews are dropped
    as roots. Use dropRoots=false when the root table must remain untouched.

SAVE-DROP OPTIONS
    dropDependents (default true): when false, definitions are saved to temp_view_dependencies
    but dependent views/matviews are not dropped. Use this to snapshot definitions before
    manual changes or to prepare a RESTORE batch while keeping objects online.
    dropRoots (default true): when false, root views/matviews are not dropped either.
    saveRoots (default false): when true with dropRoots, root view/matview definitions are
    saved at depth 0 and recreated on RESTORE before dependents. Use for table/view column
    type changes where the saved SQL stays valid. Keep false when you will CREATE OR REPLACE
    the root view with a new definition before RESTORE.

NOT SUPPORTED (manual intervention required)
    - Removing columns from a parent view when dependents still reference them.
      You must edit or drop those dependents manually before changing the parent.
    - Renaming columns, changing column order semantics, or altering expressions in ways
      that make the saved definition invalid.
    - GRANTs, COMMENTs, indexes on materialized views, and REFRESH ... CONCURRENTLY setup.
    - Replacements that change SQL semantics or reference incompatible columns; replacements
      are textual substitutions applied to saved definitions and trigger DDL.

MATERIALIZED VIEWS
    Included in dependency discovery (relkind = m). On RESTORE they are recreated with
    CREATE MATERIALIZED VIEW and then REFRESH MATERIALIZED VIEW (default WITH DATA on create
    also populates them; refresh ensures data matches sources updated while parents changed).
    Matview-specific indexes and privileges are not preserved.

EXAMPLE

-- Preview dependents of a table or view
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"LIST","rootViews":["ext_municipality"]}}$$);

-- Save definitions only (dependents stay in place)
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP","rootViews":["ext_municipality"],"dropDependents":false,"dropRoots":false}}$$);

-- Save and drop dependents; table root is kept
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP","rootViews":["ext_municipality"],"dropRoots":false}}$$);
CREATE OR REPLACE VIEW v_municipality AS SELECT * FROM ext_municipality;
SELECT gw_fct_admin_manage_view_dependencies($${"data":{
  "action":"RESTORE",
  "replacements":[
    {"from":"v_ext_municipality","to":"ve_municipality"},
    {"from":"ext_municipality","to":"v_municipality"}
  ]
}}$$);

-- Save, drop, recreate parent view, restore unchanged
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP","rootViews":["ve_node"]}}$$);
-- CREATE OR REPLACE VIEW ve_node AS ...
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE"}}$$);

-- Alter base-table column type; roots are saved and restored automatically
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP","rootViews":["ve_node"],"saveRoots":true,"batchId":1}}$$);
ALTER TABLE node ALTER COLUMN dataquality_obs TYPE text[] USING (dataquality_obs::text)::text[];
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE","batchId":1}}$$);

-- Discard a saved batch
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"CLEAN"}}$$);

*/

DECLARE
    v_version text;
    v_schemaname text := 'SCHEMA_NAME';
    v_action text;
    v_batch_id integer;
    v_drop_roots boolean;
    v_drop_dependents boolean;
    v_save_roots boolean;
    v_root_views text[];
    v_root_views_json text;
    v_replacements_json text;
    v_count integer := 0;
    v_info json := '[]'::json;
    v_level integer;
    v_status text;
    v_message text;
    v_error_context text;

    rec record;
    rec_trg record;
    rec_repl record;
    v_def text;
    v_trg_def text;
    v_trg text;
    v_replace text;
    v_from_esc text;
    v_trg_cols text;
    v_trg_stmt text;

BEGIN

    SET search_path = "SCHEMA_NAME", public;

    SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

    v_action := json_extract_path_text(p_data, 'data', 'action');
    v_root_views_json := json_extract_path_text(p_data, 'data', 'rootViews');
    v_replacements_json := json_extract_path(p_data, 'data', 'replacements')::text;
    v_batch_id := COALESCE(
        json_extract_path_text(p_data, 'data', 'batchId')::integer,
        json_extract_path_text(p_data, 'data', 'fid')::integer,
        1
    );
    v_drop_roots := COALESCE(json_extract_path_text(p_data, 'data', 'dropRoots')::boolean, true);
    v_drop_dependents := COALESCE(json_extract_path_text(p_data, 'data', 'dropDependents')::boolean, true);
    v_save_roots := COALESCE(json_extract_path_text(p_data, 'data', 'saveRoots')::boolean, false);

    IF v_action IS NULL THEN
        RAISE EXCEPTION 'Parameter action is mandatory (LIST, SAVE-DROP, RESTORE, CLEAN)';
    END IF;

    IF v_action IN ('SAVE-DROP', 'RESTORE', 'CLEAN') THEN
        CREATE TABLE IF NOT EXISTS temp_view_dependencies (
            id serial PRIMARY KEY,
            batch_id integer NOT NULL,
            cur_user text DEFAULT current_user,
            view_schema text NOT NULL,
            view_name text NOT NULL,
            relkind char(1) NOT NULL DEFAULT 'v',
            view_depth integer NOT NULL,
            view_definition text NOT NULL,
            trigger_definition text,
            tstamp timestamp without time zone DEFAULT now(),
            CONSTRAINT temp_view_dependencies_un UNIQUE (batch_id, view_schema, view_name)
        );

        ALTER TABLE temp_view_dependencies
            ADD COLUMN IF NOT EXISTS relkind char(1) NOT NULL DEFAULT 'v';

        CREATE INDEX IF NOT EXISTS temp_view_dependencies_batch_id_depth_idx
            ON temp_view_dependencies (batch_id, view_depth);
    END IF;

    IF v_action IN ('LIST', 'SAVE-DROP') THEN
        IF v_root_views_json IS NULL THEN
            RAISE EXCEPTION 'Parameter rootViews is mandatory for action %', v_action;
        END IF;
        v_root_views := ARRAY(SELECT json_array_elements_text(v_root_views_json::json));
        IF array_length(v_root_views, 1) IS NULL THEN
            RAISE EXCEPTION 'Parameter rootViews must contain at least one root object name';
        END IF;
    END IF;

    IF v_action = 'LIST' THEN
        SELECT COALESCE(json_agg(json_build_object(
            'schema', view_schema,
            'name', view_name,
            'type', object_type,
            'depth', depth
        ) ORDER BY depth DESC, view_schema, view_name), '[]'::json)
        INTO v_info
        FROM (
            WITH RECURSIVE dep_tree AS (
                SELECT c.oid AS reloid, 0 AS depth
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = v_schemaname
                  AND c.relname = ANY(v_root_views)
                  AND c.relkind IN ('v', 'm', 'r')

                UNION ALL

                SELECT c.oid, dt.depth + 1
                FROM dep_tree dt
                JOIN pg_depend d ON d.refobjid = dt.reloid AND d.deptype = 'n'
                JOIN pg_rewrite r ON r.oid = d.objid
                JOIN pg_class c ON c.oid = r.ev_class AND c.relkind IN ('v', 'm')
                WHERE c.oid <> dt.reloid
            )
            SELECT n.nspname AS view_schema,
                   c.relname AS view_name,
                   c.relkind,
                   CASE c.relkind WHEN 'm' THEN 'matview' ELSE 'view' END AS object_type,
                   MAX(dt.depth) AS depth
            FROM dep_tree dt
            JOIN pg_class c ON c.oid = dt.reloid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE dt.depth > 0
            GROUP BY 1, 2, 3, 4
        ) dependents;

        v_status := 'Accepted';
        v_level := 3;
        v_message := 'Dependent views listed successfully';

    ELSIF v_action = 'SAVE-DROP' THEN

        DELETE FROM temp_view_dependencies WHERE batch_id = v_batch_id;

        FOR rec IN
            WITH RECURSIVE dep_tree AS (
                SELECT c.oid AS reloid, 0 AS depth
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = v_schemaname
                  AND c.relname = ANY(v_root_views)
                  AND c.relkind IN ('v', 'm', 'r')

                UNION ALL

                SELECT c.oid, dt.depth + 1
                FROM dep_tree dt
                JOIN pg_depend d ON d.refobjid = dt.reloid AND d.deptype = 'n'
                JOIN pg_rewrite r ON r.oid = d.objid
                JOIN pg_class c ON c.oid = r.ev_class AND c.relkind IN ('v', 'm')
                WHERE c.oid <> dt.reloid
            ),
            dependents AS (
                SELECT n.nspname AS view_schema,
                       c.relname AS view_name,
                       c.relkind,
                       MAX(dt.depth) AS depth
                FROM dep_tree dt
                JOIN pg_class c ON c.oid = dt.reloid
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE dt.depth > 0
                GROUP BY 1, 2, 3
            )
            SELECT * FROM dependents
            ORDER BY depth DESC, view_schema, view_name
        LOOP
            v_def := pg_get_viewdef(format('%I.%I', rec.view_schema, rec.view_name)::regclass, true);

            v_trg := NULL;
            IF rec.relkind = 'v' THEN
                FOR rec_trg IN
                    SELECT trigger_name,
                           action_timing,
                           action_statement,
                           string_agg(event_manipulation, ',' ORDER BY event_manipulation) AS events
                    FROM information_schema.triggers
                    WHERE event_object_schema = rec.view_schema
                      AND event_object_table = rec.view_name
                    GROUP BY trigger_name, action_timing, action_statement
                LOOP
                    SELECT replace(rec_trg.events, ',', ' OR ') INTO v_replace;

                    SELECT string_agg(event_object_column, ',') INTO v_trg_cols
                    FROM information_schema.triggered_update_columns
                    WHERE event_object_schema = rec.view_schema
                      AND event_object_table = rec.view_name
                      AND trigger_name = rec_trg.trigger_name;

                    IF v_trg_cols IS NOT NULL THEN
                        v_replace := replace(v_replace, 'UPDATE', 'UPDATE OF ' || v_trg_cols);
                    END IF;

                    v_trg := concat(
                        COALESCE(v_trg || E'\n', ''),
                        format(
                            'DROP TRIGGER IF EXISTS %I ON %I.%I;',
                            rec_trg.trigger_name,
                            rec.view_schema,
                            rec.view_name
                        ),
                        E'\n',
                        format(
                            'CREATE TRIGGER %I %s %s ON %I.%I FOR EACH ROW %s;',
                            rec_trg.trigger_name,
                            rec_trg.action_timing,
                            v_replace,
                            rec.view_schema,
                            rec.view_name,
                            rec_trg.action_statement
                        )
                    );
                END LOOP;
            END IF;

            INSERT INTO temp_view_dependencies (
                batch_id, view_schema, view_name, relkind, view_depth, view_definition, trigger_definition
            )
            VALUES (
                v_batch_id, rec.view_schema, rec.view_name, rec.relkind, rec.depth, v_def, v_trg
            );

            v_count := v_count + 1;
        END LOOP;

        IF v_save_roots IS TRUE AND v_drop_roots IS TRUE THEN
            FOR rec IN
                SELECT n.nspname AS view_schema,
                       c.relname AS view_name,
                       c.relkind
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = v_schemaname
                  AND c.relname = ANY(v_root_views)
                  AND c.relkind IN ('v', 'm')
                ORDER BY c.relname
            LOOP
                v_def := pg_get_viewdef(format('%I.%I', rec.view_schema, rec.view_name)::regclass, true);

                v_trg := NULL;
                IF rec.relkind = 'v' THEN
                    FOR rec_trg IN
                        SELECT trigger_name,
                               action_timing,
                               action_statement,
                               string_agg(event_manipulation, ',' ORDER BY event_manipulation) AS events
                        FROM information_schema.triggers
                        WHERE event_object_schema = rec.view_schema
                          AND event_object_table = rec.view_name
                        GROUP BY trigger_name, action_timing, action_statement
                    LOOP
                        SELECT replace(rec_trg.events, ',', ' OR ') INTO v_replace;

                        SELECT string_agg(event_object_column, ',') INTO v_trg_cols
                        FROM information_schema.triggered_update_columns
                        WHERE event_object_schema = rec.view_schema
                          AND event_object_table = rec.view_name
                          AND trigger_name = rec_trg.trigger_name;

                        IF v_trg_cols IS NOT NULL THEN
                            v_replace := replace(v_replace, 'UPDATE', 'UPDATE OF ' || v_trg_cols);
                        END IF;

                        v_trg := concat(
                            COALESCE(v_trg || E'\n', ''),
                            format(
                                'DROP TRIGGER IF EXISTS %I ON %I.%I;',
                                rec_trg.trigger_name,
                                rec.view_schema,
                                rec.view_name
                            ),
                            E'\n',
                            format(
                                'CREATE TRIGGER %I %s %s ON %I.%I FOR EACH ROW %s;',
                                rec_trg.trigger_name,
                                rec_trg.action_timing,
                                v_replace,
                                rec.view_schema,
                                rec.view_name,
                                rec_trg.action_statement
                            )
                        );
                    END LOOP;
                END IF;

                INSERT INTO temp_view_dependencies (
                    batch_id, view_schema, view_name, relkind, view_depth, view_definition, trigger_definition
                )
                VALUES (
                    v_batch_id, rec.view_schema, rec.view_name, rec.relkind, 0, v_def, v_trg
                )
                ON CONFLICT (batch_id, view_schema, view_name) DO UPDATE SET
                    relkind = EXCLUDED.relkind,
                    view_depth = EXCLUDED.view_depth,
                    view_definition = EXCLUDED.view_definition,
                    trigger_definition = EXCLUDED.trigger_definition;

                v_count := v_count + 1;
            END LOOP;
        END IF;

        IF v_drop_dependents IS TRUE THEN
            FOR rec IN
                SELECT view_schema, view_name, relkind
                FROM temp_view_dependencies
                WHERE batch_id = v_batch_id
                ORDER BY view_depth DESC, view_schema, view_name
            LOOP
                IF rec.relkind = 'm' THEN
                    EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %I.%I', rec.view_schema, rec.view_name);
                ELSE
                    EXECUTE format('DROP VIEW IF EXISTS %I.%I', rec.view_schema, rec.view_name);
                END IF;
            END LOOP;
        END IF;

        IF v_drop_roots IS TRUE THEN
            FOR rec IN
                SELECT c.relname AS view_name, c.relkind
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = v_schemaname
                  AND c.relname = ANY(v_root_views)
                  AND c.relkind IN ('v', 'm')
            LOOP
                IF rec.relkind = 'm' THEN
                    EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %I.%I', v_schemaname, rec.view_name);
                ELSE
                    EXECUTE format('DROP VIEW IF EXISTS %I.%I', v_schemaname, rec.view_name);
                END IF;
            END LOOP;
        END IF;

        v_status := 'Accepted';
        v_level := 3;
        IF v_drop_dependents IS TRUE THEN
            v_message := concat('Saved and dropped ', v_count, ' object(s)');
        ELSE
            v_message := concat('Saved ', v_count, ' object(s)');
        END IF;

    ELSIF v_action = 'RESTORE' THEN

        FOR rec IN
            SELECT view_schema, view_name, relkind, view_definition, trigger_definition
            FROM temp_view_dependencies
            WHERE batch_id = v_batch_id
            ORDER BY view_depth ASC, view_schema, view_name
        LOOP
            v_def := rec.view_definition;
            v_trg_def := rec.trigger_definition;

            IF v_replacements_json IS NOT NULL AND btrim(v_replacements_json) <> '' THEN
                FOR rec_repl IN
                    SELECT x."from" AS from_pat, x."to" AS to_pat
                    FROM json_to_recordset(v_replacements_json::json) AS x("from" text, "to" text)
                LOOP
                    v_from_esc := regexp_replace(rec_repl.from_pat, '([\[\](){}.*+?|^$\\])', '\\\1', 'g');
                    v_def := regexp_replace(v_def, '\m' || v_from_esc || '\M', rec_repl.to_pat, 'g');
                    IF position('.' IN rec_repl.from_pat) = 0 THEN
                        v_def := regexp_replace(
                            v_def,
                            '\m' || regexp_replace(v_schemaname, '([\[\](){}.*+?|^$\\])', '\\\1', 'g') || '\.' || v_from_esc || '\M',
                            rec_repl.to_pat,
                            'g'
                        );
                    END IF;
                    v_def := replace(v_def, '"' || rec_repl.from_pat || '"', '"' || rec_repl.to_pat || '"');

                    IF v_trg_def IS NOT NULL THEN
                        v_trg_def := regexp_replace(v_trg_def, '\m' || v_from_esc || '\M', rec_repl.to_pat, 'g');
                        IF position('.' IN rec_repl.from_pat) = 0 THEN
                            v_trg_def := regexp_replace(
                                v_trg_def,
                                '\m' || regexp_replace(v_schemaname, '([\[\](){}.*+?|^$\\])', '\\\1', 'g') || '\.' || v_from_esc || '\M',
                                rec_repl.to_pat,
                                'g'
                            );
                        END IF;
                        v_trg_def := replace(v_trg_def, '"' || rec_repl.from_pat || '"', '"' || rec_repl.to_pat || '"');
                    END IF;
                END LOOP;
            END IF;

            IF rec.relkind = 'm' THEN
                EXECUTE format(
                    'CREATE MATERIALIZED VIEW %I.%I AS %s',
                    rec.view_schema,
                    rec.view_name,
                    v_def
                );
                EXECUTE format(
                    'REFRESH MATERIALIZED VIEW %I.%I',
                    rec.view_schema,
                    rec.view_name
                );
            ELSE
                EXECUTE format(
                    'CREATE OR REPLACE VIEW %I.%I AS %s',
                    rec.view_schema,
                    rec.view_name,
                    v_def
                );

                IF v_trg_def IS NOT NULL AND btrim(v_trg_def) <> '' THEN
                    FOR v_trg_stmt IN
                        SELECT btrim(stmt)
                        FROM regexp_split_to_table(v_trg_def, E'\\n+') AS stmt
                        WHERE btrim(stmt) <> ''
                    LOOP
                        EXECUTE v_trg_stmt;
                    END LOOP;
                END IF;
            END IF;

            v_count := v_count + 1;
        END LOOP;

        DELETE FROM temp_view_dependencies WHERE batch_id = v_batch_id;

        v_status := 'Accepted';
        v_level := 3;
        v_message := concat('Restored ', v_count, ' object(s)');

    ELSIF v_action = 'CLEAN' THEN

        DELETE FROM temp_view_dependencies WHERE batch_id = v_batch_id;
        GET DIAGNOSTICS v_count = ROW_COUNT;

        v_status := 'Accepted';
        v_level := 3;
        v_message := concat('Removed ', v_count, ' saved object definition(s)');

    ELSE
        RAISE EXCEPTION 'Unsupported action: %. Valid values: LIST, SAVE-DROP, RESTORE, CLEAN', v_action;
    END IF;

    RETURN gw_fct_json_create_return(
        ('{"status":"' || v_status || '", "message":{"level":' || v_level || ', "text":"' || v_message || '"}, "version":"' || v_version || '"'
        || ',"body":{"form":{}'
        || ',"data":{"info":' || COALESCE(v_info::text, 'null') || '}'
        || '}'
        || '}')::json,
        3542, NULL, NULL, NULL
    );

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    RETURN json_build_object(
        'status', 'Failed',
        'message', json_build_object('level', 3, 'text', SQLERRM),
        'SQLSTATE', SQLSTATE,
        'SQLCONTEXT', v_error_context
    )::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

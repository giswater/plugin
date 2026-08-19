/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_build_multilang_view_sql(text, text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_build_multilang_view_sql(
    p_schema_name text,
    p_table text
)
RETURNS text AS
$BODY$
/*
Build and execute CREATE VIEW for one UI table in JOIN (multilang) mode.
Column list is taken from the live base table so WS/UD/CM shape differences are respected.
*/
DECLARE
    v_cols text;
    v_sql text;
    v_view text := 'v_' || p_table;
    v_lang_expr text;
    v_pt_expr text;
    v_join text;
    v_context text;
BEGIN
    v_lang_expr := format(
        '(SELECT lower(btrim(cpu.value))
          FROM %1$I.config_param_user cpu
          WHERE cpu.parameter = ''multilang_language''
            AND cpu.cur_user = current_user
            AND lower(btrim(cpu.value)) IS NOT NULL
            AND lower(btrim(cpu.value)) <> ''default''
            AND length(lower(btrim(cpu.value))) = 5)',
        p_schema_name
    );

    v_pt_expr := format(
        '(SELECT lower(btrim(sv.project_type))
          FROM %1$I.sys_version sv
          ORDER BY sv.id DESC
          LIMIT 1)',
        p_schema_name
    );

    IF p_table = 'config_form_fields' THEN
        -- Exact formnames win via equijoin; feature/wildcard patterns use formname_like.
        v_context := 'config_form_fields';
        v_join := format(
            'LEFT JOIN multilang.config_form_fields ml
                ON ml.formtype = t.formtype
               AND ml.tabname = t.tabname
               AND ml.source = t.columnname
               AND ml.context = %1$L
               AND ml.project_type = %2$s
               AND ml.lang = %3$s
               AND ml.formname = t.formname
               AND ml.formname_like IS NULL
            LEFT JOIN LATERAL (
                SELECT ml0.lb, ml0.tt, ml0.pl
                FROM multilang.config_form_fields ml0
                WHERE ml.formname IS NULL
                  AND ml0.formtype = t.formtype
                  AND ml0.tabname = t.tabname
                  AND ml0.source = t.columnname
                  AND ml0.context = %1$L
                  AND ml0.project_type = %2$s
                  AND ml0.lang = %3$s
                  AND ml0.formname_like IS NOT NULL
                  AND t.formname LIKE ml0.formname_like
                ORDER BY length(ml0.formname_like) DESC, ml0.formname
                LIMIT 1
            ) mlp ON TRUE
            LEFT JOIN multilang.config_form_fields_json mlj
                ON mlj.formtype = t.formtype
               AND mlj.tabname = t.tabname
               AND mlj.source = t.columnname
               AND mlj.context = %1$L
               AND mlj.hint = ''widgetcontrols''
               AND mlj.project_type = %2$s
               AND mlj.lang = %3$s
               AND mlj.formname = t.formname
               AND mlj.formname_like IS NULL
            LEFT JOIN LATERAL (
                SELECT mlj0.text
                FROM multilang.config_form_fields_json mlj0
                WHERE mlj.formname IS NULL
                  AND mlj0.formtype = t.formtype
                  AND mlj0.tabname = t.tabname
                  AND mlj0.source = t.columnname
                  AND mlj0.context = %1$L
                  AND mlj0.hint = ''widgetcontrols''
                  AND mlj0.project_type = %2$s
                  AND mlj0.lang = %3$s
                  AND mlj0.formname_like IS NOT NULL
                  AND t.formname LIKE mlj0.formname_like
                ORDER BY length(mlj0.formname_like) DESC, mlj0.formname
                LIMIT 1
            ) mljp ON TRUE',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'config_form_tabs' THEN
        v_context := 'config_form_tabs';
        v_join := format(
            'LEFT JOIN multilang.config_form_tabs ml
                ON ml.formname = t.formname
               AND ml.source = t.tabname
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'config_param_system' THEN
        v_context := 'config_param_system';
        v_join := format(
            'LEFT JOIN multilang.config_param_system ml
                ON ml.source = t.parameter
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'sys_param_user' THEN
        v_context := 'sys_param_user';
        v_join := format(
            'LEFT JOIN multilang.sys_param_user ml
                ON ml.source = t.id
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'sys_message' THEN
        v_context := 'sys_message';
        v_join := format(
            'LEFT JOIN multilang.sys_message ml
                ON ml.source = t.id::text
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'sys_function' THEN
        v_context := 'sys_function';
        v_join := format(
            'LEFT JOIN multilang.sys_function ml
                ON ml.source = t.id::text
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'sys_fprocess' THEN
        v_context := 'sys_fprocess';
        v_join := format(
            'LEFT JOIN multilang.sys_fprocess ml
                ON ml.source = t.fid::text
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'sys_table' THEN
        v_context := 'sys_table';
        v_join := format(
            'LEFT JOIN multilang.sys_table ml
                ON ml.source = t.id
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'sys_label' THEN
        v_context := 'sys_label';
        v_join := format(
            'LEFT JOIN multilang.sys_label ml
                ON ml.source = t.id::text
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSIF p_table = 'config_csv' THEN
        v_context := 'config_csv';
        v_join := format(
            'LEFT JOIN multilang.config_csv ml
                ON ml.source = t.fid::text
               AND ml.context = %L
               AND ml.project_type = %s
               AND ml.lang = %s',
            v_context, v_pt_expr, v_lang_expr
        );
    ELSE
        RAISE EXCEPTION 'Unsupported multilang view table: %', p_table;
    END IF;

    SELECT string_agg(col_expr, ', ' ORDER BY ordinal_position)
    INTO v_cols
    FROM (
        SELECT
            a.attnum AS ordinal_position,
            CASE
                WHEN x.inner_sql IS NOT NULL
                    THEN format(
                        '(%s)::%s AS %I',
                        x.inner_sql,
                        format_type(a.atttypid, a.atttypmod),
                        a.attname
                    )
                ELSE format('t.%I', a.attname)
            END AS col_expr
        FROM pg_attribute a
        JOIN pg_class r ON r.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = r.relnamespace
        CROSS JOIN LATERAL (
            SELECT CASE
                WHEN a.attname = 'label' AND p_table = 'config_form_fields'
                    THEN 'COALESCE(ml.lb, mlp.lb, t.label)'
                WHEN a.attname = 'label'
                    AND p_table IN (
                        'config_form_tabs',
                        'config_param_system', 'sys_param_user'
                    )
                    THEN 'COALESCE(ml.lb, t.label)'
                WHEN a.attname = 'tooltip' AND p_table = 'config_form_fields'
                    THEN 'COALESCE(ml.tt, mlp.tt, t.tooltip)'
                WHEN a.attname = 'placeholder' AND p_table = 'config_form_fields'
                    THEN 'COALESCE(ml.pl, mlp.pl, t.placeholder)'
                WHEN a.attname = 'tooltip' AND p_table = 'config_form_tabs'
                    THEN 'COALESCE(ml.tt, t.tooltip)'
                WHEN a.attname = 'descript'
                    AND p_table IN ('config_param_system', 'sys_param_user')
                    THEN 'COALESCE(ml.tt, t.descript)'
                WHEN a.attname = 'descript'
                    AND p_table IN ('sys_function', 'sys_table', 'config_csv')
                    THEN 'COALESCE(ml.ds, t.descript)'
                WHEN a.attname = 'error_message' AND p_table = 'sys_message'
                    THEN 'COALESCE(ml.ms, t.error_message)'
                WHEN a.attname = 'hint_message' AND p_table = 'sys_message'
                    THEN 'COALESCE(ml.ht, t.hint_message)'
                WHEN a.attname = 'fprocess_name' AND p_table = 'sys_fprocess'
                    THEN 'COALESCE(ml.na, t.fprocess_name)'
                WHEN a.attname = 'except_msg' AND p_table = 'sys_fprocess'
                    THEN 'COALESCE(ml.ex, t.except_msg)'
                WHEN a.attname = 'info_msg' AND p_table = 'sys_fprocess'
                    THEN 'COALESCE(ml."in", t.info_msg)'
                WHEN a.attname = 'alias'
                    AND p_table IN ('sys_table', 'config_csv')
                    THEN 'COALESCE(ml.al, t.alias)'
                WHEN a.attname = 'idval' AND p_table = 'sys_label'
                    THEN 'COALESCE(ml.vl, t.idval)'
                WHEN a.attname = 'widgetcontrols' AND p_table = 'config_form_fields'
                    THEN '(COALESCE(t.widgetcontrols::jsonb, ''{}''::jsonb)
                           || COALESCE(mlj.text, mljp.text, ''{}''::jsonb))::json'
                ELSE NULL
            END AS inner_sql
        ) x
        WHERE n.nspname = p_schema_name
          AND r.relname = p_table
          AND r.relkind IN ('r', 'p')
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) cols;

    IF v_cols IS NULL OR btrim(v_cols) = '' THEN
        RAISE EXCEPTION 'No columns found for %.%', p_schema_name, p_table;
    END IF;

    EXECUTE format('DROP VIEW IF EXISTS %I.%I', p_schema_name, v_view);

    v_sql := format(
        'CREATE VIEW %I.%I AS SELECT %s FROM %I.%I t %s',
        p_schema_name, v_view, v_cols, p_schema_name, p_table, v_join
    );

    EXECUTE v_sql;
    EXECUTE format('GRANT SELECT ON TABLE %I.%I TO role_basic', p_schema_name, v_view);

    RETURN v_sql;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

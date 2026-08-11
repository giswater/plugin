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
Build and execute CREATE OR REPLACE VIEW for one UI table in JOIN (multilang) mode.
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
                SELECT ml0.lb, ml0.tt
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
    ELSE
        RAISE EXCEPTION 'Unsupported multilang view table: %', p_table;
    END IF;

    SELECT string_agg(col_expr, ', ' ORDER BY ordinal_position)
    INTO v_cols
    FROM (
        SELECT
            c.ordinal_position,
            CASE
                WHEN c.column_name = 'label' AND p_table = 'config_form_fields'
                    THEN 'COALESCE(ml.lb, mlp.lb, t.label) AS label'
                WHEN c.column_name = 'label'
                    AND p_table IN (
                        'config_form_tabs',
                        'config_param_system', 'sys_param_user'
                    )
                    THEN 'COALESCE(ml.lb, t.label) AS label'
                WHEN c.column_name = 'tooltip' AND p_table = 'config_form_fields'
                    THEN 'COALESCE(ml.tt, mlp.tt, t.tooltip) AS tooltip'
                WHEN c.column_name = 'tooltip' AND p_table = 'config_form_tabs'
                    THEN 'COALESCE(ml.tt, t.tooltip) AS tooltip'
                WHEN c.column_name = 'descript'
                    AND p_table IN ('config_param_system', 'sys_param_user')
                    THEN 'COALESCE(ml.tt, t.descript) AS descript'
                WHEN c.column_name = 'descript'
                    AND p_table IN ('sys_function', 'sys_table')
                    THEN 'COALESCE(ml.ds, t.descript) AS descript'
                WHEN c.column_name = 'error_message' AND p_table = 'sys_message'
                    THEN 'COALESCE(ml.ms, t.error_message) AS error_message'
                WHEN c.column_name = 'hint_message' AND p_table = 'sys_message'
                    THEN 'COALESCE(ml.ht, t.hint_message) AS hint_message'
                WHEN c.column_name = 'fprocess_name' AND p_table = 'sys_fprocess'
                    THEN 'COALESCE(ml.na, t.fprocess_name) AS fprocess_name'
                WHEN c.column_name = 'except_msg' AND p_table = 'sys_fprocess'
                    THEN 'COALESCE(ml.ex, t.except_msg) AS except_msg'
                WHEN c.column_name = 'info_msg' AND p_table = 'sys_fprocess'
                    THEN 'COALESCE(ml."in", t.info_msg) AS info_msg'
                WHEN c.column_name = 'alias' AND p_table = 'sys_table'
                    THEN 'COALESCE(ml.al, t.alias) AS alias'
                WHEN c.column_name = 'widgetcontrols' AND p_table = 'config_form_fields'
                    THEN '(COALESCE(t.widgetcontrols::jsonb, ''{}''::jsonb)
                           || COALESCE(mlj.text, mljp.text, ''{}''::jsonb))::json AS widgetcontrols'
                WHEN c.column_name IN ('datatype', 'source', 'in', 'text', 'parameter', 'label')
                    THEN format('t.%I', c.column_name)
                ELSE format('t.%I', c.column_name)
            END AS col_expr
        FROM information_schema.columns c
        WHERE c.table_schema = p_schema_name
          AND c.table_name = p_table
    ) cols;

    IF v_cols IS NULL OR btrim(v_cols) = '' THEN
        RAISE EXCEPTION 'No columns found for %.%', p_schema_name, p_table;
    END IF;

    v_sql := format(
        'CREATE OR REPLACE VIEW %I.%I AS SELECT %s FROM %I.%I t %s',
        p_schema_name, v_view, v_cols, p_schema_name, p_table, v_join
    );

    EXECUTE v_sql;
    EXECUTE format('GRANT SELECT ON TABLE %I.%I TO role_basic', p_schema_name, v_view);

    RETURN v_sql;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
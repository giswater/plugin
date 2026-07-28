/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2752

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_manage_child_views_view(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_manage_child_views_view(p_data json)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
	v_schemaname text := (p_data ->> 'schema');
	v_viewname text := ((p_data ->> 'body')::json ->> 'viewname');
	v_feature_type text := ((p_data ->> 'body')::json ->> 'feature_type'); -- e.g. 'node', 'element', etc.
	v_parent_layer text := ((p_data ->> 'body')::json ->> 'parent_layer'); -- parent view/table name
	v_feature_class text := ((p_data ->> 'body')::json ->> 'feature_class'); -- e.g. 'manhole', 'valve'
	v_feature_cat text := ((p_data ->> 'body')::json ->> 'feature_cat'); -- cat_feature.id
	v_feature_childtable_name text := ((p_data ->> 'body')::json ->> 'feature_childtable_name'); -- e.g. 'man_node_adaptation'

	v_join_key text; -- *_id join key
	v_man_table text; -- man_* table name
	v_parent_cols text; -- qualified parent columns (with exclusions)
	v_man_cols text; -- qualified man_* columns (excluding *_id)
	v_add_cols text; -- qualified add table columns (excluding id, *_id)
	v_has_man_extra boolean := false;
	v_has_add_extra boolean := false;

	v_sql text;
BEGIN
  -- Set search_path to the target schema
  EXECUTE format('SET search_path = %I, public;', v_schemaname);

  v_join_key  := v_feature_type || '_id';
  v_man_table := 'man_' || v_feature_class;

  -- Check parent existence (table or view)
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_schemaname
      AND c.relname = v_parent_layer
      AND c.relkind IN ('r', 'v', 'm', 'p')
  ) THEN
    RAISE EXCEPTION 'Parent layer %.% does not exist', v_schemaname, v_parent_layer;
  END IF;

  -- Check man_* table existence
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_schemaname
      AND c.relname = v_man_table
      AND c.relkind IN ('r', 'p')
  ) THEN
    RAISE EXCEPTION 'man_* table %.% does not exist', v_schemaname, v_man_table;
  END IF;

  -- Get man_* columns (all except *_id). Don't filter overlaps here, will remove from parent selection.
  SELECT
    CASE WHEN COUNT(*) FILTER (WHERE a.attname <> v_join_key) > 0 THEN true ELSE false END,
    NULLIF(string_agg(
      CASE WHEN a.attname <> v_join_key
           THEN format('%I.%I', v_man_table, a.attname)
           ELSE NULL END,
      ', '
    ), '')
  INTO v_has_man_extra, v_man_cols
  FROM pg_catalog.pg_attribute a
  JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = v_schemaname
    AND c.relname = v_man_table
    AND a.attnum > 0
    AND NOT a.attisdropped;

  -- Get parent columns, excluding:
  --   - any column that exists in man_* (except *_id, which is kept from parent)
  WITH man_names AS (
    SELECT a.attname AS column_name
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_schemaname
      AND c.relname = v_man_table
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attname <> v_join_key
  )
  SELECT string_agg(format('%I.%I', v_parent_layer, a.attname), ', ')
  INTO v_parent_cols
  FROM pg_catalog.pg_attribute a
  JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = v_schemaname
    AND c.relname = v_parent_layer
    AND a.attnum > 0
    AND NOT a.attisdropped
    AND a.attname NOT IN (SELECT column_name FROM man_names);

  IF v_parent_cols IS NULL THEN
    -- This can happen if parent and man_* have the same columns (except *_id).
    -- In that case, at least select *_id from parent.
    SELECT string_agg(format('%I.%I', v_parent_layer, a.attname), ', ')
    INTO v_parent_cols
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_schemaname
      AND c.relname = v_parent_layer
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attname = v_join_key;

    IF v_parent_cols IS NULL THEN
      RAISE EXCEPTION 'Parent %.% does not have column %', v_schemaname, v_parent_layer, v_join_key;
    END IF;
  END IF;

  -- Get add table columns (if exists and has more than just id and *_id)
  IF v_feature_childtable_name IS NOT NULL
     AND EXISTS (
       SELECT 1
       FROM pg_catalog.pg_class c
       JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = v_schemaname
         AND c.relname = v_feature_childtable_name
         AND c.relkind IN ('r', 'p')
     )
  THEN
    SELECT
      CASE WHEN COUNT(*) FILTER (WHERE a.attname NOT IN ('id', v_join_key)) > 0 THEN true ELSE false END,
      NULLIF(string_agg(
        CASE WHEN a.attname NOT IN ('id', v_join_key)
             THEN format('%I.%I', v_feature_childtable_name, a.attname)
             ELSE NULL END,
        ', '
      ), '')
    INTO v_has_add_extra, v_add_cols
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = v_schemaname
      AND c.relname = v_feature_childtable_name
      AND a.attnum > 0
      AND NOT a.attisdropped;
  ELSE
    v_has_add_extra := false;
    v_add_cols      := NULL;
  END IF;

  -- Build final SELECT
  v_sql := 'CREATE OR REPLACE VIEW ' || quote_ident(v_viewname) || ' AS ' ||
           'SELECT ' || v_parent_cols;

  IF v_has_man_extra AND v_man_cols IS NOT NULL THEN
    v_sql := v_sql || ', ' || v_man_cols;
  END IF;

  IF v_has_add_extra AND v_add_cols IS NOT NULL THEN
    v_sql := v_sql || ', ' || v_add_cols;
  END IF;

  v_sql := v_sql || ' FROM ' || format('%I', v_parent_layer) ||
         ' JOIN ' || format('%I', v_man_table) || ' USING (' || quote_ident(v_join_key) || ')';

  IF v_has_add_extra THEN
    v_sql := v_sql || ' LEFT JOIN ' || format('%I', v_feature_childtable_name) ||
            ' USING (' || quote_ident(v_join_key) || ')';
  END IF;

  v_sql := v_sql || ' WHERE ' || format('%I.%I', v_parent_layer, v_feature_type || '_type') ||
          ' = ' || quote_literal(v_feature_cat) || ';';

  EXECUTE v_sql;
  RAISE NOTICE 'View % created in %', v_viewname, v_schemaname;

  --create trigger on view
  EXECUTE format(
    'DROP TRIGGER IF EXISTS gw_trg_edit_%s_%s ON %I.%I;',
    v_feature_type,
    lower(replace(replace(replace(v_feature_cat, ' ','_'),'-','_'),'.','_')),
    v_schemaname,
    v_viewname
  );
  RAISE NOTICE 'Trigger gw_trg_edit_% dropped in %', v_viewname, v_schemaname;

  EXECUTE format(
    'CREATE TRIGGER gw_trg_edit_%s_%s INSTEAD OF INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE PROCEDURE %I.gw_trg_edit_%s(%L);',
    v_feature_type,
    lower(replace(replace(replace(v_feature_cat, ' ','_'),'-','_'),'.','_')),
    v_schemaname,
    v_viewname,
    v_schemaname,
    v_feature_type,
    v_feature_cat
  );
  RAISE NOTICE 'Trigger % created in %', v_viewname, v_schemaname;

  EXECUTE format(
    'SELECT gw_fct_admin_manage_child_config(%L);',
    json_build_object(
      'feature', json_build_object('catFeature', v_feature_cat),
      'data', json_build_object(
        'view_name', v_viewname,
        'feature_type', v_feature_type
      )
    )::text
  );
  RAISE NOTICE 'Config % created in %', v_viewname, v_schemaname;

  RETURN json_build_object('status', 'Accepted', 'message', 'View created successfully')::json;

END;
$$;

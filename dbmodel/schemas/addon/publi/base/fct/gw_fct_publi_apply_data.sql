/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_apply_data(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT publi.gw_fct_publi_apply_data($${"data":{"configId":1, "staging":"publi_stg_1"}}$$);

Internal step of gw_fct_publi_sync: raises on error. Run after gw_fct_publi_apply_structure (modes alter / none),
so live and staging have the same columns.
Changed rows are detected comparing every column as text (json and other types have no equality operator).
*/

DECLARE
	v_cfg publi.config_publi_table;
	v_stg text;
	v_join text;
	v_cols text[];
	v_set text;
	v_cmp_t text;
	v_cmp_s text;
	v_all text;
	v_all_s text;
	v_updated int := 0;
	v_inserted int := 0;
	v_deleted int := 0;
BEGIN
	SELECT * INTO v_cfg FROM publi.config_publi_table WHERE id = (p_data -> 'data' ->> 'configId')::int;
	IF v_cfg.id IS NULL THEN
		RAISE EXCEPTION 'config_publi_table id % not found', p_data -> 'data' ->> 'configId';
	END IF;

	v_stg := p_data -> 'data' ->> 'staging';
	IF to_regclass(format('pg_temp.%I', v_stg)) IS NULL THEN
		RAISE EXCEPTION 'staging table % not found', v_stg;
	END IF;

	SELECT string_agg(format('t.%1$I = s.%1$I', c), ' AND ') INTO v_join FROM unnest(v_cfg.pk_columns) c;

	SELECT array_agg(attname::text ORDER BY attnum) INTO v_cols
	FROM pg_attribute
	WHERE attrelid = format('pg_temp.%I', v_stg)::regclass AND attnum > 0 AND NOT attisdropped
	AND NOT attname = ANY (v_cfg.pk_columns);

	IF v_cols IS NOT NULL THEN
		SELECT string_agg(format('%1$I = s.%1$I', c), ', '),
			string_agg(format('t.%I::text', c), ', '),
			string_agg(format('s.%I::text', c), ', ')
		INTO v_set, v_cmp_t, v_cmp_s
		FROM unnest(v_cols) c;

		EXECUTE format('UPDATE publi.%I t SET %s FROM pg_temp.%I s WHERE %s AND ROW(%s) IS DISTINCT FROM ROW(%s)',
			v_cfg.target_name, v_set, v_stg, v_join, v_cmp_t, v_cmp_s);
		GET DIAGNOSTICS v_updated = ROW_COUNT;
	END IF;

	SELECT string_agg(format('%I', c), ', '), string_agg(format('s.%I', c), ', ')
	INTO v_all, v_all_s
	FROM unnest(v_cfg.pk_columns || COALESCE(v_cols, '{}')) c;

	EXECUTE format('INSERT INTO publi.%I (%s) SELECT %s FROM pg_temp.%I s WHERE NOT EXISTS (SELECT 1 FROM publi.%I t WHERE %s)',
		v_cfg.target_name, v_all, v_all_s, v_stg, v_cfg.target_name, v_join);
	GET DIAGNOSTICS v_inserted = ROW_COUNT;

	-- separate DELETE: MERGE ... WHEN NOT MATCHED BY SOURCE needs PostgreSQL 17
	EXECUTE format('DELETE FROM publi.%I t WHERE NOT EXISTS (SELECT 1 FROM pg_temp.%I s WHERE %s)',
		v_cfg.target_name, v_stg, v_join);
	GET DIAGNOSTICS v_deleted = ROW_COUNT;

	IF v_updated + v_inserted + v_deleted > 0 THEN
		EXECUTE format('ANALYZE publi.%I', v_cfg.target_name);
	END IF;

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'inserted', v_inserted,
			'updated', v_updated,
			'deleted', v_deleted)));
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

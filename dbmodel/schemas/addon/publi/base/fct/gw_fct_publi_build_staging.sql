/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_build_staging(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT publi.gw_fct_publi_build_staging($${"data":{"configId":1}}$$);

Internal step of gw_fct_publi_sync: raises on error so the caller can roll back the table.
Leaves a temp table pg_temp.publi_stg_<configId> with the source rows plus one <col>_name per decoded column.
*/

DECLARE
	v_cfg publi.config_publi_table;
	v_base text;
	v_stg text;
	v_src text;
	v_formname text;
	v_rec record;
	v_cols text[];
	v_col text;
	v_namecol text;
	v_dvq text;
	v_same boolean;
	v_decode jsonb := '{}';
	v_decoded jsonb := '[]';
	v_skipped jsonb := '[]';
	v_select text[] := '{}';
	v_joins text := '';
	v_n int := 0;
	v_pk text;
	v_pkcond text;
	v_count int;
BEGIN
	SELECT * INTO v_cfg FROM publi.config_publi_table WHERE id = (p_data -> 'data' ->> 'configId')::int;
	IF v_cfg.id IS NULL THEN
		RAISE EXCEPTION 'config_publi_table id % not found', p_data -> 'data' ->> 'configId';
	END IF;

	v_base := 'publi_base_' || v_cfg.id;
	v_stg := 'publi_stg_' || v_cfg.id;
	EXECUTE format('DROP TABLE IF EXISTS pg_temp.%I', v_base);
	EXECUTE format('DROP TABLE IF EXISTS pg_temp.%I', v_stg);

	-- dv_querytext, where_clause and source_sql use unqualified source names
	PERFORM set_config('search_path', format('%I, public', v_cfg.source_schema), true);

	v_src := COALESCE(v_cfg.source_sql, format('SELECT * FROM %I.%I', v_cfg.source_schema, v_cfg.source_relation));
	IF v_cfg.where_clause IS NOT NULL THEN
		v_src := format('SELECT * FROM (%s) q WHERE %s', v_src, v_cfg.where_clause);
	END IF;
	EXECUTE format('CREATE TEMP TABLE %I AS %s', v_base, v_src);

	SELECT array_agg(attname::text ORDER BY attnum) INTO v_cols
	FROM pg_attribute
	WHERE attrelid = format('pg_temp.%I', v_base)::regclass AND attnum > 0 AND NOT attisdropped;

	-- decode candidates: every combo of the source form
	v_formname := COALESCE(v_cfg.source_formname, v_cfg.source_relation);
	IF v_cfg.decode_columns AND to_regclass(format('%I.config_form_fields', v_cfg.source_schema)) IS NOT NULL THEN
		FOR v_rec IN EXECUTE format(
			$q$SELECT DISTINCT ON (columnname) columnname::text AS columnname, dv_querytext
			FROM %I.config_form_fields
			WHERE formname = $1 AND formtype = 'form_feature'
			AND widgettype IN ('combo', 'typeahead') AND dv_querytext IS NOT NULL
			ORDER BY columnname, (tabname = 'tab_data') DESC$q$, v_cfg.source_schema)
			USING v_formname
		LOOP
			v_col := v_rec.columnname;
			v_namecol := CASE WHEN v_col LIKE '%\_id' THEN left(v_col, -3) || '_name' ELSE v_col || '_name' END;
			v_dvq := rtrim(btrim(v_rec.dv_querytext), ';');

			IF NOT v_col = ANY (v_cols) OR v_col = ANY (v_cfg.pk_columns) THEN
				CONTINUE;
			END IF;
			IF v_namecol = ANY (v_cols) THEN
				v_skipped := v_skipped || jsonb_build_object('column', v_col, 'reason', v_namecol || ' already exists');
				CONTINUE;
			END IF;

			BEGIN
				EXECUTE format('SELECT bool_and(q.id::text = q.idval::text) FROM (%s) q', v_dvq) INTO v_same;
			EXCEPTION WHEN OTHERS THEN
				v_skipped := v_skipped || jsonb_build_object('column', v_col, 'reason', SQLERRM);
				CONTINUE;
			END;

			IF v_same THEN
				v_skipped := v_skipped || jsonb_build_object('column', v_col, 'reason', 'id = idval');
				CONTINUE;
			END IF;

			v_decode := v_decode || jsonb_build_object(v_col, jsonb_build_object('nameColumn', v_namecol, 'query', v_dvq));
		END LOOP;
	END IF;

	-- name column right after its code column
	FOREACH v_col IN ARRAY v_cols
	LOOP
		v_select := v_select || format('t.%I', v_col);
		IF v_decode ? v_col THEN
			v_n := v_n + 1;
			v_namecol := v_decode -> v_col ->> 'nameColumn';
			v_dvq := v_decode -> v_col ->> 'query';
			v_select := v_select || format('d%s.idval AS %I', v_n, v_namecol);
			v_joins := v_joins || format(
				' LEFT JOIN (SELECT DISTINCT ON (q.id::text) q.id::text AS id, q.idval::text AS idval FROM (%s) q ORDER BY q.id::text) d%s ON d%s.id = t.%I::text',
				v_dvq, v_n, v_n, v_col);
			v_decoded := v_decoded || jsonb_build_object('column', v_col, 'nameColumn', v_namecol, 'query', v_dvq);
		END IF;
	END LOOP;

	EXECUTE format('CREATE TEMP TABLE %I AS SELECT %s FROM pg_temp.%I t%s',
		v_stg, array_to_string(v_select, ', '), v_base, v_joins);
	EXECUTE format('DROP TABLE pg_temp.%I', v_base);

	-- the PK must hold before touching the live table
	FOREACH v_col IN ARRAY v_cfg.pk_columns
	LOOP
		IF NOT v_col = ANY (v_cols) THEN
			RAISE EXCEPTION 'pk column % not found in source of %', v_col, v_cfg.target_name;
		END IF;
	END LOOP;

	SELECT string_agg(format('%I', c), ', '), string_agg(format('%I IS NULL', c), ' OR ')
	INTO v_pk, v_pkcond
	FROM unnest(v_cfg.pk_columns) c;

	EXECUTE format('SELECT count(*) FROM pg_temp.%I WHERE %s', v_stg, v_pkcond) INTO v_count;
	IF v_count > 0 THEN
		RAISE EXCEPTION '% rows with NULL pk (%) in source of %', v_count, v_pk, v_cfg.target_name;
	END IF;

	EXECUTE format('SELECT count(*) FROM (SELECT 1 FROM pg_temp.%I GROUP BY %s HAVING count(*) > 1) d', v_stg, v_pk) INTO v_count;
	IF v_count > 0 THEN
		RAISE EXCEPTION '% duplicated pk values (%) in source of %', v_count, v_pk, v_cfg.target_name;
	END IF;

	EXECUTE format('SELECT count(*) FROM pg_temp.%I', v_stg) INTO v_count;

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'staging', v_stg,
			'rows', v_count,
			'decoded', v_decoded,
			'skipped', v_skipped)));
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

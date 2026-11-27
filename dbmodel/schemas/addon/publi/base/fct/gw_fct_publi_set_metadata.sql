/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_set_metadata(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT publi.gw_fct_publi_set_metadata($${"data":{"configId":1,
  "decoded":[{"column":"dma_id", "nameColumn":"dma_name", "query":"SELECT dma_id as id, name as idval FROM dma"}]}}$$);

Internal step of gw_fct_publi_sync: raises on error.
  - table alias: alias_custom, else cat_feature.descript (child views), else sys_table.alias, else source name
  - column alias / description: config_form_fields label / tooltip of the source form
  - <col>_name inherits the label of <col>; <col> is described as a technical key
  - writes publi.sys_metadata, publi.sys_domain and COMMENT ON TABLE / COLUMN
  - warns about names shared by several ids (they must be grouped by id, DESIGN 6.3)
*/

DECLARE
	v_cfg publi.config_publi_table;
	v_live regclass;
	v_formname text;
	v_alias text;
	v_descript text;
	v_source text;
	v_labels jsonb := '{}';
	v_namecols jsonb := '{}';
	v_codecols jsonb := '{}';
	v_item jsonb;
	v_col text;
	v_code text;
	v_label text;
	v_coldesc text;
	v_colsource text;
	v_rec record;
	v_warnings jsonb := '[]';
	v_columns int := 0;
BEGIN
	SELECT * INTO v_cfg FROM publi.config_publi_table WHERE id = (p_data -> 'data' ->> 'configId')::int;
	IF v_cfg.id IS NULL THEN
		RAISE EXCEPTION 'config_publi_table id % not found', p_data -> 'data' ->> 'configId';
	END IF;

	v_live := to_regclass(format('publi.%I', v_cfg.target_name));
	IF v_live IS NULL THEN
		RAISE EXCEPTION 'table publi.% not found', v_cfg.target_name;
	END IF;

	PERFORM set_config('search_path', format('%I, public', v_cfg.source_schema), true);

	-- table
	v_alias := v_cfg.alias_custom;
	v_source := CASE WHEN v_alias IS NOT NULL THEN 'custom' END;

	IF v_alias IS NULL AND to_regclass(format('%I.cat_feature', v_cfg.source_schema)) IS NOT NULL THEN
		EXECUTE format('SELECT descript FROM %I.cat_feature WHERE child_layer = $1 AND descript IS NOT NULL LIMIT 1', v_cfg.source_schema)
		INTO v_alias USING v_cfg.source_relation;
		v_source := CASE WHEN v_alias IS NOT NULL THEN 'cat_feature' END;
	END IF;

	IF to_regclass(format('%I.sys_table', v_cfg.source_schema)) IS NOT NULL THEN
		EXECUTE format('SELECT alias, descript FROM %I.sys_table WHERE id = $1', v_cfg.source_schema)
		INTO v_rec USING v_cfg.source_relation;
		IF v_alias IS NULL AND v_rec.alias IS NOT NULL THEN
			v_alias := v_rec.alias;
			v_source := 'sys_table';
		END IF;
		v_descript := v_rec.descript;
	END IF;

	v_alias := COALESCE(v_alias, v_cfg.source_relation);
	v_source := COALESCE(v_source, 'default');

	DELETE FROM publi.sys_metadata WHERE target_name = v_cfg.target_name;
	INSERT INTO publi.sys_metadata (target_name, column_name, alias, description, "source")
	VALUES (v_cfg.target_name, '', v_alias, v_descript, v_source);
	EXECUTE format('COMMENT ON TABLE publi.%I IS %L', v_cfg.target_name,
		v_alias || COALESCE(': ' || v_descript, ''));

	-- columns
	v_formname := COALESCE(v_cfg.source_formname, v_cfg.source_relation);
	IF to_regclass(format('%I.config_form_fields', v_cfg.source_schema)) IS NOT NULL THEN
		EXECUTE format(
			$q$SELECT COALESCE(jsonb_object_agg(columnname, jsonb_build_object('label', label, 'tooltip', tooltip)), '{}')
			FROM (
				SELECT DISTINCT ON (columnname) columnname::text AS columnname,
					NULLIF(regexp_replace(label, '\s*:\s*$', ''), '') AS label,
					CASE WHEN lower(btrim(tooltip)) NOT IN (lower(columnname), lower(label), '') THEN tooltip END AS tooltip
				FROM %I.config_form_fields
				WHERE formname = $1 AND formtype = 'form_feature' AND label IS NOT NULL
				ORDER BY columnname, (tabname = 'tab_data') DESC
			) q$q$, v_cfg.source_schema)
		INTO v_labels USING v_formname;
	END IF;

	FOR v_item IN SELECT value FROM jsonb_array_elements(COALESCE((p_data -> 'data' -> 'decoded')::jsonb, '[]'))
	LOOP
		v_namecols := v_namecols || jsonb_build_object(v_item ->> 'nameColumn', v_item ->> 'column');
		v_codecols := v_codecols || jsonb_build_object(v_item ->> 'column', v_item ->> 'nameColumn');
	END LOOP;

	FOR v_col IN
		SELECT attname::text FROM pg_attribute
		WHERE attrelid = v_live AND attnum > 0 AND NOT attisdropped
		ORDER BY attnum
	LOOP
		IF v_namecols ? v_col THEN
			v_code := v_namecols ->> v_col;
			v_label := COALESCE(v_labels -> v_code ->> 'label', v_code);
			v_coldesc := format('Name of %s. Use it to display and to search by text; filter and group by %s.', v_label, v_code);
			v_colsource := 'decode';
		ELSE
			v_label := COALESCE(v_labels -> v_col ->> 'label', v_col);
			v_coldesc := v_labels -> v_col ->> 'tooltip';
			v_colsource := CASE WHEN v_labels ? v_col THEN 'config_form_fields' ELSE 'default' END;
			IF v_codecols ? v_col THEN
				v_coldesc := concat_ws(' ', v_coldesc,
					format('Technical key: filter and group by it, never show it to the user; the readable value is %s.', v_codecols ->> v_col));
			END IF;
		END IF;

		INSERT INTO publi.sys_metadata (target_name, column_name, alias, description, "source")
		VALUES (v_cfg.target_name, v_col, v_label, v_coldesc, v_colsource);
		EXECUTE format('COMMENT ON COLUMN publi.%I.%I IS %L', v_cfg.target_name, v_col,
			v_label || COALESCE(': ' || v_coldesc, ''));
		v_columns := v_columns + 1;
	END LOOP;

	-- value domains
	DELETE FROM publi.sys_domain WHERE target_name = v_cfg.target_name;
	FOR v_item IN SELECT value FROM jsonb_array_elements(COALESCE((p_data -> 'data' -> 'decoded')::jsonb, '[]'))
	LOOP
		EXECUTE format(
			$q$INSERT INTO publi.sys_domain (target_name, column_name, id, idval)
			SELECT DISTINCT ON (q.id::text) $1, $2, q.id::text, q.idval::text
			FROM (%s) q WHERE q.id IS NOT NULL ORDER BY q.id::text$q$, v_item ->> 'query')
		USING v_cfg.target_name, v_item ->> 'column';

		FOR v_rec IN
			SELECT idval, array_agg(id ORDER BY id) AS ids
			FROM publi.sys_domain
			WHERE target_name = v_cfg.target_name AND column_name = v_item ->> 'column' AND idval IS NOT NULL
			GROUP BY idval HAVING count(*) > 1
		LOOP
			v_warnings := v_warnings || to_jsonb(format('%s.%s: name "%s" shared by ids %s',
				v_cfg.target_name, v_item ->> 'nameColumn', v_rec.idval, v_rec.ids));
		END LOOP;
	END LOOP;

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'alias', v_alias,
			'aliasSource', v_source,
			'columns', v_columns,
			'warnings', v_warnings)));
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

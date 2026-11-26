/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_apply_security(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT publi.gw_fct_publi_apply_security($${"data":{"configId":1}}$$);

Internal step of gw_fct_publi_sync: raises on error. Idempotent: only creates what is missing.
  - primary key from config_publi_table.pk_columns
  - one GIST index per geometry / geography column
  - SELECT for role_addon_publi_read
  - RLS (ENABLE + FORCE) with policy publi_rls on expl_id / sector_id (scalar: = ANY, array as in mapzones: &&)
    through <source_schema>.cat_manager
    (via gw_fct_publi_user_ids), and policy publi_owner so the table owner (the sync role) can still write
If the rls column is missing the table stays with RLS enabled and no read policy: nobody but the owner sees it.
*/

DECLARE
	v_cfg publi.config_publi_table;
	v_live regclass;
	v_owner text;
	v_rec record;
	v_rlscol text;
	v_mgrcol text;
	v_isarray boolean;
	v_created jsonb := '[]';
	v_warnings jsonb := '[]';
BEGIN
	SELECT * INTO v_cfg FROM publi.config_publi_table WHERE id = (p_data -> 'data' ->> 'configId')::int;
	IF v_cfg.id IS NULL THEN
		RAISE EXCEPTION 'config_publi_table id % not found', p_data -> 'data' ->> 'configId';
	END IF;

	v_live := to_regclass(format('publi.%I', v_cfg.target_name));
	IF v_live IS NULL THEN
		RAISE EXCEPTION 'table publi.% not found', v_cfg.target_name;
	END IF;

	-- primary key
	IF NOT EXISTS (SELECT 1 FROM pg_index WHERE indrelid = v_live AND indisprimary) THEN
		EXECUTE format('ALTER TABLE publi.%I ADD PRIMARY KEY (%s)', v_cfg.target_name,
			(SELECT string_agg(format('%I', c), ', ') FROM unnest(v_cfg.pk_columns) c));
		v_created := v_created || to_jsonb('primary key'::text);
	END IF;

	-- spatial indexes
	FOR v_rec IN
		SELECT a.attname::text AS col
		FROM pg_attribute a
		WHERE a.attrelid = v_live AND a.attnum > 0 AND NOT a.attisdropped
		AND a.atttypid::regtype::text IN ('geometry', 'geography')
		AND NOT EXISTS (
			SELECT 1 FROM pg_index i
			JOIN pg_class ic ON ic.oid = i.indexrelid
			JOIN pg_am am ON am.oid = ic.relam
			WHERE i.indrelid = v_live AND am.amname = 'gist' AND i.indkey[0] = a.attnum)
	LOOP
		EXECUTE format('CREATE INDEX ON publi.%I USING gist (%I)', v_cfg.target_name, v_rec.col);
		v_created := v_created || to_jsonb('gist ' || v_rec.col);
	END LOOP;

	-- read role
	IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_addon_publi_read') THEN
		EXECUTE format('GRANT SELECT ON publi.%I TO role_addon_publi_read', v_cfg.target_name);
	ELSE
		v_warnings := v_warnings || to_jsonb('role_addon_publi_read does not exist, no grant'::text);
	END IF;

	-- row level security
	SELECT pg_get_userbyid(relowner) INTO v_owner FROM pg_class WHERE oid = v_live;

	EXECUTE format('DROP POLICY IF EXISTS publi_rls ON publi.%I', v_cfg.target_name);
	EXECUTE format('DROP POLICY IF EXISTS publi_owner ON publi.%I', v_cfg.target_name);

	IF v_cfg.rls_mode = 'none' THEN
		EXECUTE format('ALTER TABLE publi.%I NO FORCE ROW LEVEL SECURITY', v_cfg.target_name);
		EXECUTE format('ALTER TABLE publi.%I DISABLE ROW LEVEL SECURITY', v_cfg.target_name);
	ELSE
		v_mgrcol := CASE v_cfg.rls_mode WHEN 'expl' THEN 'expl_id' ELSE 'sector_id' END;
		v_rlscol := COALESCE(v_cfg.rls_column, v_mgrcol);

		EXECUTE format('ALTER TABLE publi.%I ENABLE ROW LEVEL SECURITY', v_cfg.target_name);
		EXECUTE format('ALTER TABLE publi.%I FORCE ROW LEVEL SECURITY', v_cfg.target_name);
		EXECUTE format('CREATE POLICY publi_owner ON publi.%I FOR ALL TO %I USING (true) WITH CHECK (true)',
			v_cfg.target_name, v_owner);

		SELECT t.typcategory = 'A' INTO v_isarray
		FROM pg_attribute a JOIN pg_type t ON t.oid = a.atttypid
		WHERE a.attrelid = v_live AND a.attname = v_rlscol AND NOT a.attisdropped;

		IF v_isarray IS NULL THEN
			v_warnings := v_warnings || to_jsonb(format('rls column %s missing: table hidden to everyone but %s', v_rlscol, v_owner));
		ELSIF to_regclass(format('%I.cat_manager', v_cfg.source_schema)) IS NULL THEN
			v_warnings := v_warnings || to_jsonb(format('%s.cat_manager missing: table hidden to everyone but %s', v_cfg.source_schema, v_owner));
		ELSE
			-- the scalar subquery makes the ids an initplan, computed once per query instead of per row
			EXECUTE format(
				'CREATE POLICY publi_rls ON publi.%I FOR SELECT USING (%s)',
				v_cfg.target_name,
				format(CASE WHEN v_isarray
					THEN '%I::integer[] && (SELECT publi.gw_fct_publi_user_ids(%L, %L, current_user))'
					ELSE '%I = ANY ((SELECT publi.gw_fct_publi_user_ids(%L, %L, current_user))::integer[])' END,
					v_rlscol, v_cfg.source_schema, v_mgrcol));
		END IF;
	END IF;

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'created', v_created,
			'rlsMode', v_cfg.rls_mode,
			'warnings', v_warnings)));
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

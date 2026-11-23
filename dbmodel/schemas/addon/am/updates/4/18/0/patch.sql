/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public;

-- Assignation reads these. Sample leaks leave them null and use the spatial match.
ALTER TABLE am.leaks ADD COLUMN IF NOT EXISTS feature_id varchar(16);
ALTER TABLE am.leaks ADD COLUMN IF NOT EXISTS feature_type varchar(16);

-- Inventory views are read-only (v_). Input views are editable (ve_).
DO $rename$
DECLARE
	parent text;
	old_name text;
	new_name text;
BEGIN
	FOR old_name, new_name IN
		SELECT *
		FROM (VALUES
			('ext_ws_arc_asset', 'v_ext_ws_arc_asset'),
			('ext_ws_node_asset', 'v_ext_ws_node_asset'),
			('ext_ws_link_asset', 'v_ext_ws_link_asset'),
			('ext_ud_arc_asset', 'v_ext_ud_arc_asset'),
			('ext_ud_node_asset', 'v_ext_ud_node_asset'),
			('v_asset_ws_arc_input', 've_asset_ws_arc_input'),
			('v_asset_ws_node_input', 've_asset_ws_node_input'),
			('v_asset_ws_link_input', 've_asset_ws_link_input'),
			('v_asset_ud_arc_input', 've_asset_ud_arc_input'),
			('v_asset_ud_node_input', 've_asset_ud_node_input')
		) AS names(old_name, new_name)
	LOOP
		IF to_regclass('am.' || old_name) IS NOT NULL
			AND to_regclass('am.' || new_name) IS NULL THEN
			EXECUTE format('ALTER VIEW am.%I RENAME TO %I', old_name, new_name);
		END IF;
	END LOOP;

	FOR parent IN
		SELECT DISTINCT NULLIF(btrim(addparam->>'parentSchema'), '')
		FROM am.sys_version
	LOOP
		IF parent IS NULL OR to_regnamespace(parent) IS NULL THEN
			CONTINUE;
		END IF;
		IF to_regclass(format('%I.sys_table', parent)) IS NULL THEN
			CONTINUE;
		END IF;

		FOR old_name, new_name IN
			SELECT *
			FROM (VALUES
				('ext_ws_arc_asset', 'v_ext_ws_arc_asset'),
				('ext_ws_node_asset', 'v_ext_ws_node_asset'),
				('ext_ws_link_asset', 'v_ext_ws_link_asset'),
				('ext_ud_arc_asset', 'v_ext_ud_arc_asset'),
				('ext_ud_node_asset', 'v_ext_ud_node_asset'),
				('v_asset_ws_arc_input', 've_asset_ws_arc_input'),
				('v_asset_ws_node_input', 've_asset_ws_node_input'),
				('v_asset_ws_link_input', 've_asset_ws_link_input'),
				('v_asset_ud_arc_input', 've_asset_ud_arc_input'),
				('v_asset_ud_node_input', 've_asset_ud_node_input')
			) AS names(old_name, new_name)
		LOOP
			IF to_regclass(format('%I.sys_style', parent)) IS NOT NULL THEN
				EXECUTE format(
					'DELETE FROM %I.sys_style s WHERE s.layername = %L AND EXISTS ('
					|| 'SELECT 1 FROM %I.sys_style n WHERE n.layername = %L AND n.styleconfig_id = s.styleconfig_id)',
					parent, old_name, parent, new_name);
				EXECUTE format(
					'UPDATE %I.sys_style SET layername = %L WHERE layername = %L',
					parent, new_name, old_name);
			END IF;

			EXECUTE format(
				'DELETE FROM %I.sys_table WHERE id = %L AND source = %L AND EXISTS ('
				|| 'SELECT 1 FROM %I.sys_table WHERE id = %L)',
				parent, old_name, 'am', parent, new_name);
			EXECUTE format(
				'UPDATE %I.sys_table SET id = %L WHERE id = %L AND source = %L',
				parent, new_name, old_name, 'am');
		END LOOP;
	END LOOP;
END
$rename$;

-- Inventory and AWARE grades are 1 = best, 5 = worst. Higher raw = higher priority.
-- Views and write-back triggers built before this stored (6 - grade). Drop that flip
-- in place so an upgrade does not have to rebuild the parent overlays.
DO $polarity$
DECLARE
	v_name text;
	v_def text;
	v_hits int;
	v_oid oid;
	v_func text;
BEGIN
	FOREACH v_name IN ARRAY ARRAY[
		'v_ext_ud_arc_asset', 'ext_ud_arc_asset',
		'v_ext_ud_node_asset', 'ext_ud_node_asset',
		'v_ext_ws_node_asset', 'ext_ws_node_asset'
	]
	LOOP
		v_oid := to_regclass('am.' || v_name);
		IF v_oid IS NULL THEN
			CONTINUE;
		END IF;
		v_def := pg_get_viewdef(v_oid, true);
		SELECT count(*) INTO v_hits
		FROM regexp_matches(v_def, '6[[:space:]]*-[[:space:]]*', 'g');
		IF v_hits = 0 THEN
			CONTINUE;
		END IF;
		IF v_hits <> 2 OR v_def !~ 'conserv_state' OR v_def !~ 'om_state' THEN
			RAISE EXCEPTION 'am.% grade polarity is not the expected (6 - grade) pair', v_name;
		END IF;
		v_def := regexp_replace(v_def, '6[[:space:]]*-[[:space:]]*', '', 'g');
		v_def := regexp_replace(v_def, '[[:space:]]*;[[:space:]]*$', '');
		EXECUTE 'CREATE OR REPLACE VIEW am.' || quote_ident(v_name) || ' AS ' || v_def;
	END LOOP;

	FOR v_oid, v_func IN
		SELECT p.oid, n.nspname || '.' || p.proname
		FROM pg_proc p
		JOIN pg_namespace n ON n.oid = p.pronamespace
		WHERE p.proname IN ('gw_trg_am_ud_arc_pathology', 'gw_trg_am_ud_node_pathology')
	LOOP
		v_def := pg_get_functiondef(v_oid);
		SELECT count(*) INTO v_hits
		FROM regexp_matches(v_def, '6[[:space:]]*-[[:space:]]*', 'g');
		IF v_hits = 0 THEN
			CONTINUE;
		END IF;
		IF v_hits <> 2 OR v_def !~ 'conserv_state' OR v_def !~ 'om_state' THEN
			RAISE EXCEPTION '% grade write-back is not the expected (6 - score) pair', v_func;
		END IF;
		v_def := regexp_replace(v_def, '6[[:space:]]*-[[:space:]]*', '', 'g');
		EXECUTE v_def;
	END LOOP;
END
$polarity$;

-- Compliance grade is 1 = best, 10 = worst. Rows stored before this used 10 as best.
DO $compliance$
DECLARE
	v_table text;
	v_parent text;
BEGIN
	FOREACH v_table IN ARRAY ARRAY[
		'config_material_def', 'config_material',
		'config_catalog_def', 'config_catalog',
		'config_nodecatalog_def', 'config_nodecatalog',
		'config_linkcatalog_def', 'config_linkcatalog',
		'ws_arc_input', 'ws_arc_output'
	]
	LOOP
		IF to_regclass('am.' || v_table) IS NULL THEN
			CONTINUE;
		END IF;
		IF NOT EXISTS (
			SELECT 1 FROM information_schema.columns
			WHERE table_schema = 'am' AND table_name = v_table
				AND column_name = 'compliance' AND data_type = 'integer'
		) THEN
			CONTINUE;
		END IF;
		EXECUTE format(
			'UPDATE am.%I SET compliance = 11 - compliance WHERE compliance BETWEEN 1 AND 10',
			v_table
		);
	END LOOP;

	-- New materials must default to 1 (best), not 10.
	FOR v_parent IN
		SELECT DISTINCT NULLIF(btrim(addparam->>'parentSchema'), '')
		FROM am.sys_version
	LOOP
		IF v_parent IS NULL OR to_regproc(format('%I.gw_trg_asset_cat_material', v_parent)) IS NULL THEN
			CONTINUE;
		END IF;
		EXECUTE format($fn$
			CREATE OR REPLACE FUNCTION %1$I.gw_trg_asset_cat_material() RETURNS trigger AS
			$BODY$
			DECLARE
				v_project_type varchar(2);
			BEGIN
				EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
				SELECT upper(project_type) INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;
				IF TG_OP = 'INSERT' THEN
					INSERT INTO am.config_material_def (
						material, project_type, pleak, age_max, age_med, age_min, builtdate_vdef, compliance
					)
					VALUES (NEW.id, v_project_type, 0.16, 58, 50, 42, 1964, 1)
					ON CONFLICT (material, project_type) DO NOTHING;
					RETURN NEW;
				END IF;
			END;
			$BODY$
			LANGUAGE plpgsql VOLATILE COST 100;
		$fn$, v_parent);
	END LOOP;
END
$compliance$;

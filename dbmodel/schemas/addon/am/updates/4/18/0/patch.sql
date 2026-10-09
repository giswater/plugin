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

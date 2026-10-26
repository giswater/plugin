/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later version.
*/

SET search_path = am, public;

DO $$
DECLARE
	v_parent text;
BEGIN
	-- Latest parentSchema is only the last link. Refresh every attached parent,
	-- plus PARENT_SCHEMA (the parent this integrate is wiring in, not registered yet).
	FOR v_parent IN
		SELECT DISTINCT btrim(parent_name)
		FROM am.sys_version v
		CROSS JOIN LATERAL (
			SELECT jsonb_array_elements_text(COALESCE(v.addparam->'parent_schemas', '[]'::jsonb))
			UNION ALL
			SELECT NULLIF(btrim(v.addparam->>'parentSchema'), '')
			UNION ALL
			SELECT NULLIF(btrim(v.addparam->>'parent_schema'), '')
			UNION ALL
			SELECT NULLIF(btrim('PARENT_SCHEMA'), '')
		) AS parents(parent_name)
		WHERE NULLIF(btrim(parent_name), '') IS NOT NULL
			AND to_regnamespace(btrim(parent_name)) IS NOT NULL
	LOOP
	EXECUTE format($sql$
		UPDATE %1$I.sys_table AS t
		SET alias = v.alias
		FROM (VALUES
			('leaks', 'Leak History Points'),
			('v_asset_ws_arc_output_compare', 'Comparison Arc Result'),
			('v_asset_ws_arc_output', 'Selected Arc Result'),
			('v_asset_ws_arc_corporate', 'Corporate Arc Plan'),
			('ws_arc_output', 'All Arc Calculation Results'),
			('v_asset_ws_arc_input', 'Arc Failure Rates and Inputs'),
			('ext_ws_arc_asset', 'Existing Arc Inventory'),
			('v_asset_ws_node_output_compare', 'Comparison Node Result'),
			('v_asset_ws_node_output', 'Selected Node Result'),
			('v_asset_ws_node_corporate', 'Corporate Node Plan'),
			('v_asset_ws_node_input', 'Node Planning Inputs'),
			('ext_ws_node_asset', 'Existing Node Inventory'),
			('v_asset_ws_link_output_compare', 'Comparison Link Result'),
			('v_asset_ws_link_output', 'Selected Link Result'),
			('v_asset_ws_link_corporate', 'Corporate Link Plan'),
			('v_asset_ws_link_input', 'Link Planning Inputs'),
			('ext_ws_link_asset', 'Existing Link Inventory'),
			('v_asset_ud_arc_output_compare', 'Comparison Arc Result'),
			('v_asset_ud_arc_output', 'Selected Arc Result'),
			('v_asset_ud_arc_corporate', 'Corporate Arc Plan'),
			('ud_arc_output', 'All Arc Calculation Results'),
			('v_asset_ud_arc_input', 'Arc Planning Inputs'),
			('ext_ud_arc_asset', 'Existing Arc Inventory'),
			('v_asset_ud_node_output_compare', 'Comparison Node Result'),
			('v_asset_ud_node_output', 'Selected Node Result'),
			('v_asset_ud_node_corporate', 'Corporate Node Plan'),
			('v_asset_ud_node_input', 'Node Planning Inputs'),
			('ext_ud_node_asset', 'Existing Node Inventory'),
			('v_ext_ws_arc_asset', 'Existing Arc Inventory'),
			('v_ext_ws_node_asset', 'Existing Node Inventory'),
			('v_ext_ws_link_asset', 'Existing Link Inventory'),
			('ve_asset_ws_arc_input', 'Arc Failure Rates and Inputs'),
			('ve_asset_ws_node_input', 'Node Planning Inputs'),
			('ve_asset_ws_link_input', 'Link Planning Inputs'),
			('v_ext_ud_arc_asset', 'Existing Arc Inventory'),
			('v_ext_ud_node_asset', 'Existing Node Inventory'),
			('ve_asset_ud_arc_input', 'Arc Planning Inputs'),
			('ve_asset_ud_node_input', 'Node Planning Inputs')
		) AS v(id, alias)
		WHERE t.id = v.id
	$sql$, v_parent);
	END LOOP;
END $$;

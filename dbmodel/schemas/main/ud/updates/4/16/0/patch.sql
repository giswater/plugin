/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

DELETE FROM config_toolbox WHERE id = 3248;

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES
('profile_interpolation', 'profile_interpolation', 'tab_none', 'type', 'lyt_profile_interp_1', 0, 'text', 'text', 'Type:', 'Interpolation type', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"vdefault_value":"FLOWEXIT"}'::json, NULL, NULL, true, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'node1', 'lyt_profile_node_1', 0, 'integer', 'text', 'Node 1:', 'Source node (FLOWEXIT)', NULL, true, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'btn_pick_node1', 'lyt_profile_node_1', 1, NULL, 'button', NULL, 'Pick node 1 on map', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon": "137"}'::json, NULL, '{"functionName": "pick_node", "module": "profile_interpolation", "parameters": {"target": "node1"}}'::json, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'node2', 'lyt_profile_node_2', 0, 'integer', 'text', 'Node 2:', 'Target node (FLOWEXIT)', NULL, true, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'btn_pick_node2', 'lyt_profile_node_2', 1, NULL, 'button', NULL, 'Pick node 2 on map', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon": "137"}'::json, NULL, '{"functionName": "pick_node", "module": "profile_interpolation", "parameters": {"target": "node2"}}'::json, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'profileMode', 'lyt_profile_interp_1', 1, 'text', 'combo', 'Profile mode:', 'Profile mode', NULL, false, false, true, false, false, 'SELECT ''SMOOTH'' AS id, ''SMOOTH'' AS idval UNION SELECT ''SHALLOW'', ''SHALLOW'' UNION SELECT ''DEEP'', ''DEEP'' UNION SELECT ''CENTERED'', ''CENTERED''', NULL, NULL, NULL, NULL, NULL, '{"vdefault_value":"SMOOTH"}'::json, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'minYmax', 'lyt_profile_interp_1', 2, 'numeric', 'text', 'Min Ymax:', 'Min Ymax (INIT/FLOWEXIT)', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'maxYmax', 'lyt_profile_interp_1', 3, 'numeric', 'text', 'Max Ymax:', 'Max Ymax (INIT/FLOWEXIT)', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'minSlope', 'lyt_profile_interp_1', 4, 'numeric', 'text', 'Min slope:', 'Min slope (INIT/FLOWEXIT)', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'maxSlope', 'lyt_profile_interp_1', 5, 'numeric', 'text', 'Max slope:', 'Max slope (INIT/FLOWEXIT)', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'smoothFactor', 'lyt_profile_interp_1', 6, 'numeric', 'text', 'Smooth factor:', 'Smooth factor (SMOOTH)', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'btn_run', 'lyt_buttons', 1, NULL, 'button', NULL, 'Run interpolation and show profile', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Run"}'::json, '{"functionName": "run", "module": "profile_interpolation"}'::json, NULL, false, 0),
('profile_interpolation', 'profile_interpolation', 'tab_none', 'btn_close', 'lyt_buttons', 2, NULL, 'button', NULL, 'Close', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Close"}'::json, '{"functionName": "close", "module": "profile_interpolation"}'::json, NULL, false, 0);


CREATE OR REPLACE VIEW vf_link AS
SELECT l.link_id, COALESCE(pp.state, l.state) AS p_state
FROM link l
LEFT JOIN LATERAL (
	SELECT x.psector_id
	FROM (SELECT 1 WHERE EXISTS (
			SELECT 1 FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
		)) gate
	CROSS JOIN LATERAL (
		SELECT p.psector_id
		FROM (
			SELECT pp1.psector_id
			FROM plan_psector_x_connec pp1
			WHERE pp1.connec_id = l.feature_id
				AND pp1.psector_id IN (
					SELECT sp.psector_id FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
				)
			UNION ALL
			SELECT pg1.psector_id
			FROM plan_psector_x_gully pg1
			WHERE pg1.gully_id = l.feature_id
				AND pg1.psector_id IN (
					SELECT sp.psector_id FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
				)
		) p
		ORDER BY p.psector_id DESC
		LIMIT 1
	) x
) last_ps ON true
LEFT JOIN LATERAL (
	SELECT x.state
	FROM (SELECT 1 WHERE last_ps.psector_id IS NOT NULL) gate
	CROSS JOIN LATERAL (
		SELECT p.state
		FROM (
			SELECT pp2.state
			FROM plan_psector_x_connec pp2
			WHERE pp2.link_id = l.link_id AND pp2.psector_id = last_ps.psector_id
			UNION ALL
			SELECT pg2.state
			FROM plan_psector_x_gully pg2
			WHERE pg2.link_id = l.link_id AND pg2.psector_id = last_ps.psector_id
		) p
		LIMIT 1
	) x
) pp ON true
WHERE EXISTS (
		SELECT 1 FROM selector_state ss
		WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, l.state)
	)
	AND l.sector_id IN (SELECT ssec.sector_id FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER)
	AND l.muni_id IN (SELECT sm.muni_id FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER)
	AND EXISTS (
		SELECT 1 FROM selector_expl se
		WHERE se.cur_user = CURRENT_USER
			AND (se.expl_id = l.expl_id OR se.expl_id = ANY (l.expl_visibility))
	);

CREATE OR REPLACE VIEW vf_gully AS
SELECT
	g.gully_id,
	COALESCE(pp.state, g.state) AS p_state,
	COALESCE(pp.arc_id, g.arc_id) AS arc_id,
	COALESCE(pp.exit_id, g.pjoint_id) AS pjoint_id,
	COALESCE(pp.exit_type, g.pjoint_type) AS pjoint_type
FROM gully g
LEFT JOIN LATERAL (
	SELECT x.state, x.arc_id, x.exit_id, x.exit_type
	FROM (SELECT 1 WHERE EXISTS (
			SELECT 1 FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
		)) gate
	CROSS JOIN LATERAL (
		SELECT pp_1.state, pp_1.arc_id, l.exit_id, l.exit_type
		FROM plan_psector_x_gully pp_1
		LEFT JOIN link l ON l.link_id = pp_1.link_id AND l.state = 2
		WHERE pp_1.gully_id = g.gully_id
			AND pp_1.psector_id IN (
				SELECT sp.psector_id FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
			)
		ORDER BY pp_1.psector_id DESC, pp_1.state DESC
		LIMIT 1
	) x
) pp ON true
WHERE EXISTS (
		SELECT 1 FROM selector_state ss
		WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, g.state)
	)
	AND g.sector_id IN (SELECT ssec.sector_id FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER)
	AND g.muni_id IN (SELECT sm.muni_id FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER)
	AND EXISTS (
		SELECT 1 FROM selector_expl se
		WHERE se.cur_user = CURRENT_USER
			AND (se.expl_id = g.expl_id OR se.expl_id = ANY (g.expl_visibility))
	);

-- Force reconnect checkbox on Connect Link dialog (gully)
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('generic', 'link_to_gully', 'tab_none', 'force_reconnect', 'lyt_connect_link_1', 3, 'boolean', 'check', 'Force reconnect:', 'Re-search closest arc ignoring current connection (applies pipe diameter / max distance)', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

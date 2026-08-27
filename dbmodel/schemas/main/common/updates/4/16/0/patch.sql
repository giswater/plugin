/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3560, 'gw_fct_scada_graph_build', 'utils', 'function', 'json', 'json', 'Creates a scada graph edge: insert, check/fix and export JSON.', 'role_om', NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;

INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES
('formtype_typevalue', 'profile_interpolation', 'profile_interpolation', 'profileInterpolation', NULL),
('formtype_typevalue', 'scada_graph', 'scada_graph', 'scadaGraph', NULL)
ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES
('layout_name_typevalue', 'lyt_profile_node_1', 'lyt_profile_node_1', 'lytProfileNode1', '{"lytOrientation": "horizontal"}'::json),
('layout_name_typevalue', 'lyt_profile_node_2', 'lyt_profile_node_2', 'lytProfileNode2', '{"lytOrientation": "horizontal"}'::json),
('layout_name_typevalue', 'lyt_profile_interp_1', 'lyt_profile_interp_1', 'lytProfileInterp1', '{"lytOrientation": "vertical"}'::json),
('layout_name_typevalue', 'lyt_scada_node_1', 'lyt_scada_node_1', 'lytScadaNode1', '{"lytOrientation": "horizontal"}'::json),
('layout_name_typevalue', 'lyt_scada_node_2', 'lyt_scada_node_2', 'lytScadaNode2', '{"lytOrientation": "horizontal"}'::json),
('layout_name_typevalue', 'lyt_buttons', 'lyt_buttons', 'lytButtons', '{"lytOrientation": "horizontal"}'::json)
ON CONFLICT (typevalue, id) DO NOTHING;


CREATE OR REPLACE VIEW vf_arc AS
SELECT a.arc_id, COALESCE(pp.state, a.state) AS p_state
FROM arc a
LEFT JOIN LATERAL (
	SELECT x.state
	FROM (SELECT 1 WHERE EXISTS (
			SELECT 1 FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
		)) gate
	CROSS JOIN LATERAL (
		SELECT pp_1.state
		FROM plan_psector_x_arc pp_1
		WHERE pp_1.arc_id = a.arc_id
			AND pp_1.psector_id IN (
				SELECT sp.psector_id FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
			)
		ORDER BY pp_1.psector_id DESC
		LIMIT 1
	) x
) pp ON true
WHERE EXISTS (
		SELECT 1 FROM selector_state ss
		WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, a.state)
	)
	AND a.sector_id IN (SELECT ssec.sector_id FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER)
	AND a.muni_id IN (SELECT sm.muni_id FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER)
	AND EXISTS (
		SELECT 1 FROM selector_expl se
		WHERE se.cur_user = CURRENT_USER
			AND (se.expl_id = a.expl_id OR se.expl_id = ANY (a.expl_visibility))
	);

CREATE OR REPLACE VIEW vf_node AS
SELECT n.node_id, COALESCE(pp.state, n.state) AS p_state
FROM node n
LEFT JOIN LATERAL (
	SELECT x.state
	FROM (SELECT 1 WHERE EXISTS (
			SELECT 1 FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
		)) gate
	CROSS JOIN LATERAL (
		SELECT pp_1.state
		FROM plan_psector_x_node pp_1
		WHERE pp_1.node_id = n.node_id
			AND pp_1.psector_id IN (
				SELECT sp.psector_id FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
			)
		ORDER BY pp_1.psector_id DESC
		LIMIT 1
	) x
) pp ON true
WHERE EXISTS (
		SELECT 1 FROM selector_state ss
		WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, n.state)
	)
	AND (
		n.sector_id IN (SELECT ssec.sector_id FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER)
		OR EXISTS (
			SELECT 1 FROM node_x_sector_visibility sv
			JOIN selector_sector ssec ON ssec.sector_id = sv.sector_id AND ssec.cur_user = CURRENT_USER
			WHERE sv.node_id = n.node_id
		)
	)
	AND (
		n.muni_id IN (SELECT sm.muni_id FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER)
		OR EXISTS (
			SELECT 1 FROM node_x_municipality_visibility mv
			JOIN selector_municipality sm ON sm.muni_id = mv.muni_id AND sm.cur_user = CURRENT_USER
			WHERE mv.node_id = n.node_id
		)
	)
	AND EXISTS (
		SELECT 1 FROM selector_expl se
		WHERE se.cur_user = CURRENT_USER
			AND (se.expl_id = n.expl_id OR se.expl_id = ANY (n.expl_visibility))
	);

CREATE OR REPLACE VIEW vf_connec AS
SELECT
	c.connec_id,
	COALESCE(pp.state, c.state) AS p_state,
	COALESCE(pp.arc_id, c.arc_id) AS arc_id,
	COALESCE(pp.exit_id, c.pjoint_id) AS pjoint_id,
	COALESCE(pp.exit_type, c.pjoint_type) AS pjoint_type
FROM connec c
LEFT JOIN LATERAL (
	SELECT x.state, x.arc_id, x.exit_id, x.exit_type
	FROM (SELECT 1 WHERE EXISTS (
			SELECT 1 FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
		)) gate
	CROSS JOIN LATERAL (
		SELECT pp_1.state, pp_1.arc_id, l.exit_id, l.exit_type
		FROM plan_psector_x_connec pp_1
		LEFT JOIN link l ON l.link_id = pp_1.link_id AND l.state = 2
		WHERE pp_1.connec_id = c.connec_id
			AND pp_1.psector_id IN (
				SELECT sp.psector_id FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
			)
		ORDER BY pp_1.psector_id DESC, pp_1.state DESC
		LIMIT 1
	) x
) pp ON true
WHERE EXISTS (
		SELECT 1 FROM selector_state ss
		WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, c.state)
	)
	AND c.sector_id IN (SELECT ssec.sector_id FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER)
	AND c.muni_id IN (SELECT sm.muni_id FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER)
	AND EXISTS (
		SELECT 1 FROM selector_expl se
		WHERE se.cur_user = CURRENT_USER
			AND (se.expl_id = c.expl_id OR se.expl_id = ANY (c.expl_visibility))
	);

CREATE OR REPLACE VIEW vf_element AS
SELECT 
	e.element_id,
    COALESCE(pp.state, e.state) AS p_state
FROM element e
LEFT JOIN man_frelem mf ON e.element_id = mf.element_id 
LEFT JOIN LATERAL (
	SELECT pp_1.state
	FROM plan_psector_x_node pp_1
	WHERE pp_1.node_id = mf.node_id AND (
		pp_1.psector_id IN (
			SELECT sp.psector_id
			FROM selector_psector sp
			WHERE sp.cur_user = CURRENT_USER
			)
		)
    ORDER BY pp_1.psector_id DESC
	LIMIT 1
) pp ON true
WHERE EXISTS (
		SELECT 1 FROM selector_state ss
		WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, e.state)
	)
	AND (
		e.sector_id IN (SELECT ssec.sector_id FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER)
		OR EXISTS (
			SELECT 1 FROM element_x_sector_visibility sv
			JOIN selector_sector ssec ON ssec.sector_id = sv.sector_id AND ssec.cur_user = CURRENT_USER
			WHERE sv.element_id = e.element_id
		)
	)
	AND (
		e.muni_id IN (SELECT sm.muni_id FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER)
		OR EXISTS (
			SELECT 1 FROM element_x_municipality_visibility mv
			JOIN selector_municipality sm ON sm.muni_id = mv.muni_id AND sm.cur_user = CURRENT_USER
			WHERE mv.element_id = e.element_id
		)
	)
	AND EXISTS (
		SELECT 1 FROM selector_expl se
		WHERE se.cur_user = CURRENT_USER
			AND (se.expl_id = e.expl_id OR se.expl_id = ANY (e.expl_visibility))
	);

-- Force reconnect checkbox on Connect Link dialog (connec)
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('generic', 'link_to_connec', 'tab_none', 'force_reconnect', 'lyt_connect_link_1', 3, 'boolean', 'check', 'Force reconnect:', 'Re-search closest arc ignoring current connection (applies pipe diameter / max distance)', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

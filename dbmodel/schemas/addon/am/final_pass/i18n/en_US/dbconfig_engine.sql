/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = am, public;
UPDATE config_engine_def AS t SET label = v.label, descript = v.descript, placeholder = v.placeholder FROM (
	VALUES
	('bratemain0', 'SH', 'Breakage rate coefficient', 'Pipe leak growth rate', NULL),
	('compliance', 'SH', 'Regulatory weight', 'Weight in final matrix for regulatory compliance', NULL),
	('compliance_1', 'WM', 'Compliance', NULL, NULL),
	('compliance_2', 'WM', 'Compliance', NULL, NULL),
	('drate', 'SH', 'Discount rate (%)', 'Real price discount rate. Takes into account price increases by discounting inflation.', NULL),
	('expected_year', 'SH', 'Expected annual weight', 'Weight in final matrix per year of renewal', NULL),
	('flow_1', 'WM', 'Circulating flow', NULL, NULL),
	('flow_2', 'WM', 'Circulating flow', NULL, NULL),
	('longevity_1', 'WM', 'Longevity', NULL, NULL),
	('longevity_2', 'WM', 'Longevity', NULL, NULL),
	('mleak_1', 'WM', 'Probability of failure', NULL, NULL),
	('mleak_2', 'WM', 'Probability of failure', NULL, NULL),
	('mincut_criticity_1', 'WM', 'Mincut criticity', 'Users affected by topological isolation after a burst', NULL),
	('mincut_criticity_2', 'WM', 'Mincut criticity', 'Users affected by topological isolation after a burst', NULL),
	('nrw_1', 'WM', 'NRW', NULL, NULL),
	('nrw_2', 'WM', 'NRW', NULL, NULL),
	('rleak_1', 'WM', 'Real breaks', NULL, NULL),
	('rleak_2', 'WM', 'Real breaks', NULL, NULL),
	('strategic', 'SH', 'Strategic weight', 'Weight in final matrix by strategic factors', NULL),
	('strategic_1', 'WM', 'Strategic', NULL, NULL),
	('strategic_2', 'WM', 'Strategic', NULL, NULL)
) AS v(parameter, method, label, descript, placeholder)
WHERE t.parameter = v.parameter AND t.method = v.method AND COALESCE(t.project_type, 'WS') = 'WS';

-- Stage 2: NODE-only Weighted Method parameters
UPDATE config_engine_def AS t SET label = v.label, descript = v.descript, placeholder = v.placeholder FROM (
	VALUES
	('incident_history_1', 'WM', 'Incident history', 'Number of past incidents recorded for the node', NULL),
	('incident_history_2', 'WM', 'Incident history', 'Number of past incidents recorded for the node', NULL),
	('structural_condition_1', 'WM', 'Structural condition', 'Structural assessment score of the node', NULL),
	('structural_condition_2', 'WM', 'Structural condition', 'Structural assessment score of the node', NULL),
	('operational_condition_1', 'WM', 'Operational condition', 'Operational assessment score of the node', NULL),
	('operational_condition_2', 'WM', 'Operational condition', 'Operational assessment score of the node', NULL),
	('affected_users_1', 'WM', 'Affected users', 'Users affected by a potential failure of the node', NULL),
	('affected_users_2', 'WM', 'Affected users', 'Users affected by a potential failure of the node', NULL),
	('affected_arcs_1', 'WM', 'Affected arcs',
	 'Weight for nodes between arcs planned in the linked ARC result', NULL),
	('affected_arcs_2', 'WM', 'Affected arcs',
	 'Weight for nodes between arcs planned in the linked ARC result', NULL)
) AS v(parameter, method, label, descript, placeholder)
WHERE t.parameter = v.parameter AND t.method = v.method AND t.asset_type = 'NODE' AND COALESCE(t.project_type, 'WS') = 'WS';

-- Stage 3: LINK-only Weighted Method parameters
UPDATE config_engine_def AS t SET label = v.label, descript = v.descript, placeholder = v.placeholder FROM (
	VALUES
	('incident_history_1', 'WM', 'Incident history', 'Number of past incidents recorded for the link or connec', NULL),
	('incident_history_2', 'WM', 'Incident history', 'Number of past incidents recorded for the link or connec', NULL),
	('material_condition_1', 'WM', 'Material condition', 'Condition score from the link material catalog', NULL),
	('material_condition_2', 'WM', 'Material condition', 'Condition score from the link material catalog', NULL),
	('affected_users_1', 'WM', 'Affected users', 'Users affected by a potential failure of the service connection', NULL),
	('affected_users_2', 'WM', 'Affected users', 'Users affected by a potential failure of the service connection', NULL),
	('parent_arc_selected_1', 'WM', 'Parent arc selected',
	 'Weight when the parent arc is selected in the linked ARC result', NULL),
	('parent_arc_selected_2', 'WM', 'Parent arc selected',
	 'Weight when the parent arc is selected in the linked ARC result', NULL)
) AS v(parameter, method, label, descript, placeholder)
WHERE t.parameter = v.parameter AND t.method = v.method AND t.asset_type = 'LINK' AND COALESCE(t.project_type, 'WS') = 'WS';

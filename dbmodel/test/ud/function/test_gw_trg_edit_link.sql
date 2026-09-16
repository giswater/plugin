/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(4);

INSERT INTO selector_state (state_id, cur_user)
SELECT s.id, current_user FROM value_state s
ON CONFLICT (state_id, cur_user) DO NOTHING;

INSERT INTO selector_expl (expl_id, cur_user)
SELECT e.expl_id, current_user FROM exploitation e
ON CONFLICT (expl_id, cur_user) DO NOTHING;

INSERT INTO selector_sector (sector_id, cur_user)
SELECT s.sector_id, current_user FROM sector s
ON CONFLICT (sector_id, cur_user) DO NOTHING;

INSERT INTO selector_psector (psector_id, cur_user)
SELECT p.psector_id, current_user FROM plan_psector p
ON CONFLICT (psector_id, cur_user) DO NOTHING;

SELECT has_function('gw_trg_edit_link'::name, 'Function gw_trg_edit_link should exist');

CREATE TEMP TABLE _t_op AS
SELECT l.link_id, l.feature_id, l.the_geom
FROM link l
JOIN connec c ON c.connec_id = l.feature_id
JOIN arc a ON a.arc_id = l.exit_id
WHERE l.feature_type = 'CONNEC' AND l.exit_type = 'ARC' AND l.state = 1 AND c.state = 1 AND a.state = 1
ORDER BY l.link_id
LIMIT 1;

SELECT is((SELECT count(*)::integer FROM _t_op), 1, 'fixture: operative connec link found');

SELECT throws_matching(
	format(
		$sql$INSERT INTO ve_link (the_geom, state)
		     SELECT the_geom, 1 FROM _t_op$sql$
	),
	'(?i)two operative links',
	'second state=1 link from the same connec raises sys_message 4750'
);

SELECT lives_ok(
	format('UPDATE ve_link SET observ = ''dup-check'' WHERE link_id = %s', (SELECT link_id FROM _t_op)),
	'updating the existing operative link does not raise 4750'
);

SELECT finish();
ROLLBACK;

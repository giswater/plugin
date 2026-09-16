/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(7);

INSERT INTO config_param_user (parameter, value, cur_user)
VALUES ('edit_disable_editcontrols', 'true', current_user)
ON CONFLICT (parameter, cur_user) DO UPDATE SET value = 'true';

INSERT INTO config_param_user (parameter, value, cur_user)
VALUES ('edit_disable_arc_linkupdate', 'false', current_user)
ON CONFLICT (parameter, cur_user) DO UPDATE SET value = 'false';

INSERT INTO selector_state (state_id, cur_user)
SELECT s.id, current_user FROM value_state s
ON CONFLICT (state_id, cur_user) DO NOTHING;

INSERT INTO selector_psector (psector_id, cur_user)
SELECT p.psector_id, current_user FROM plan_psector p
ON CONFLICT (psector_id, cur_user) DO NOTHING;

SELECT has_function('gw_trg_arc_link_update'::name, 'Function gw_trg_arc_link_update should exist');

CREATE TEMP TABLE _t_op AS
SELECT l.link_id, l.feature_id, l.exit_id AS arc_id, l.the_geom AS link_geom, a.the_geom AS arc_geom
FROM link l
JOIN arc a ON a.arc_id = l.exit_id
JOIN connec c ON c.connec_id = l.feature_id
WHERE l.exit_type = 'ARC' AND l.feature_type = 'CONNEC' AND l.state = 1 AND a.state = 1
  AND ST_Length(a.the_geom) > 8
  AND ST_LineLocatePoint(a.the_geom, ST_EndPoint(l.the_geom)) BETWEEN 0.25 AND 0.75
ORDER BY l.link_id
LIMIT 1;

SELECT is((SELECT count(*)::integer FROM _t_op), 1, 'fixture: operative connec-link-arc found');

CREATE TEMP TABLE _t_plan_arc AS
SELECT a.arc_id, a.the_geom
FROM arc a, _t_op t
WHERE a.state = 1 AND a.arc_id IS DISTINCT FROM t.arc_id AND ST_Length(a.the_geom) > 8
ORDER BY ST_Distance(a.the_geom, t.link_geom)
LIMIT 1;

INSERT INTO link (link_id, code, feature_id, feature_type, exit_id, exit_type, state, state_type, expl_id, sector_id,
	the_geom, linkcat_id, userdefined_geom)
SELECT -901, '-901', t.feature_id, 'CONNEC', p.arc_id, 'ARC', 2,
	(SELECT id FROM value_state_type WHERE state = 2 LIMIT 1),
	l.expl_id, l.sector_id,
	ST_MakeLine(ST_StartPoint(t.link_geom), ST_LineInterpolatePoint(p.the_geom, 0.5)),
	l.linkcat_id, false
FROM _t_op t
JOIN link l ON l.link_id = t.link_id
JOIN _t_plan_arc p ON true;

CREATE TEMP TABLE _t_plan_link AS
SELECT link_id, the_geom FROM link WHERE link_id = -901;

UPDATE arc SET the_geom = ST_SetSRID(ST_MakeLine(ARRAY[
	ST_StartPoint(the_geom),
	ST_Translate(ST_LineInterpolatePoint(the_geom, 0.5), 0, 5),
	ST_EndPoint(the_geom)
]), ST_SRID(the_geom))
WHERE arc_id = (SELECT arc_id FROM _t_op);

SELECT ok(
	(SELECT ST_DWithin(ST_EndPoint(l.the_geom), a.the_geom, 0.01)
	 FROM link l JOIN arc a ON a.arc_id = l.exit_id
	 WHERE l.link_id = (SELECT link_id FROM _t_op)),
	'state=1: link endpoint stays on the moved arc'
);

SELECT ok(
	(SELECT NOT ST_Equals(ST_EndPoint(l.the_geom), ST_EndPoint(t.link_geom))
	 FROM link l, _t_op t WHERE l.link_id = t.link_id),
	'state=1: link endpoint moved with the arc'
);

SELECT ok(
	(SELECT ST_Equals(l.the_geom, p.the_geom)
	 FROM link l, _t_plan_link p WHERE l.link_id = p.link_id),
	'state=2 sibling is not dragged onto the operative arc'
);

UPDATE arc SET the_geom = ST_SetSRID(ST_MakeLine(ARRAY[
	ST_StartPoint(the_geom),
	ST_Translate(ST_LineInterpolatePoint(the_geom, 0.5), 0, 5),
	ST_EndPoint(the_geom)
]), ST_SRID(the_geom))
WHERE arc_id = (SELECT arc_id FROM _t_plan_arc);

SELECT ok(
	(SELECT ST_DWithin(ST_EndPoint(l.the_geom), a.the_geom, 0.01)
	 FROM link l JOIN arc a ON a.arc_id = l.exit_id
	 WHERE l.link_id = -901),
	'state=2: link endpoint follows the planned arc via exit_id'
);

SELECT ok(
	(SELECT NOT ST_Equals(ST_EndPoint(l.the_geom), ST_EndPoint(p.the_geom))
	 FROM link l, _t_plan_link p WHERE l.link_id = p.link_id),
	'state=2: link endpoint moved with the planned arc'
);

SELECT finish();
ROLLBACK;

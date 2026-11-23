/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(16);

SELECT has_function('gw_trg_topocontrol_arc'::name, 'Function gw_trg_topocontrol_arc should exist');

INSERT INTO config_param_user (parameter, value, cur_user)
VALUES
	('edit_disable_statetopocontrol', 'false', current_user),
	('edit_disable_arctopocontrol', 'false', current_user),
	('edit_disable_topocontrol_complete', 'false', current_user)
ON CONFLICT (parameter, cur_user) DO UPDATE SET value = EXCLUDED.value;

UPDATE config_param_system SET value = 'true' WHERE parameter = 'edit_slope_direction';
UPDATE config_param_system
SET value = gw_fct_json_object_set_key(gw_fct_json_object_set_key(value::json, 'activated', true), 'value', 1)::text
WHERE parameter = 'edit_arc_searchnodes';

INSERT INTO selector_state (state_id, cur_user)
SELECT s.id, current_user FROM value_state s
ON CONFLICT (state_id, cur_user) DO NOTHING;

INSERT INTO selector_expl (expl_id, cur_user)
SELECT e.expl_id, current_user FROM exploitation e
ON CONFLICT (expl_id, cur_user) DO NOTHING;

INSERT INTO selector_sector (sector_id, cur_user)
SELECT s.sector_id, current_user FROM sector s
ON CONFLICT (sector_id, cur_user) DO NOTHING;

-- Clone a real row so NOT NULL / catalog columns stay valid. Endpoints sit on the nodes.
CREATE OR REPLACE FUNCTION pg_temp.insert_node(p_id varchar, p_elev numeric, p_x float8, p_y float8)
RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
	r node;
BEGIN
	SELECT * INTO r FROM node
	WHERE state = 1 AND the_geom IS NOT NULL
	ORDER BY node_id
	LIMIT 1;
	r.node_id := p_id;
	r.code := p_id;
	r.sys_code := p_id;
	r.ymax := NULL;
	r.elev := p_elev;
	r.custom_elev := NULL;
	r.uuid := gen_random_uuid();
	r.the_geom := ST_SetSRID(ST_MakePoint(p_x, p_y), ST_SRID(r.the_geom));
	INSERT INTO node VALUES (r.*);
END;
$fn$;

CREATE OR REPLACE FUNCTION pg_temp.insert_arc(
	p_id varchar, p_x1 float8, p_y1 float8, p_x2 float8, p_y2 float8,
	p_elev1 numeric, p_elev2 numeric, p_inverted boolean)
RETURNS void LANGUAGE plpgsql AS $fn$
DECLARE
	r arc;
	v_srid integer;
BEGIN
	SELECT * INTO r FROM arc
	WHERE state = 1 AND the_geom IS NOT NULL
	ORDER BY arc_id
	LIMIT 1;
	v_srid := ST_SRID(r.the_geom);
	r.arc_id := p_id;
	r.code := p_id;
	r.sys_code := p_id;
	r.node_1 := NULL;
	r.node_2 := NULL;
	r.y1 := NULL;
	r.y2 := NULL;
	r.elev1 := p_elev1;
	r.elev2 := p_elev2;
	r.custom_elev1 := NULL;
	r.custom_elev2 := NULL;
	r.sys_slope := NULL;
	r.inverted_slope := p_inverted;
	r.uuid := gen_random_uuid();
	r.the_geom := ST_SetSRID(ST_MakeLine(ST_MakePoint(p_x1, p_y1), ST_MakePoint(p_x2, p_y2)), v_srid);
	INSERT INTO arc VALUES (r.*);
END;
$fn$;

-- Uphill digitize, arc y/elev empty, node invert decides. Low node at the start.
SELECT pg_temp.insert_node('-971', 49.140, 500000, 4600000);
SELECT pg_temp.insert_node('-972', 49.150, 500010, 4600000);

SELECT lives_ok(
	$$SELECT pg_temp.insert_arc('-970', 500000, 4600000, 500010, 4600000, NULL, NULL, false)$$,
	'new arc with null y/elev inserts'
);

SELECT is(
	(SELECT node_1 FROM arc WHERE arc_id = '-970'),
	'-972',
	'edit_slope_direction swaps node_1 to the higher node invert'
);

SELECT ok(
	(SELECT ST_Equals(ST_StartPoint(a.the_geom), n.the_geom)
	 FROM arc a JOIN node n ON n.node_id = '-972'
	 WHERE a.arc_id = '-970'),
	'reversed geometry starts at the higher node'
);

SELECT cmp_ok(
	(SELECT slope FROM ve_arc WHERE arc_id = '-970'),
	'>',
	0::numeric,
	've_arc.slope is positive after the swap'
);

SELECT ok(
	(SELECT y1 IS NULL AND y2 IS NULL AND elev1 IS NULL AND elev2 IS NULL
		AND custom_elev1 IS NULL AND custom_elev2 IS NULL AND sys_slope IS NULL
	 FROM arc WHERE arc_id = '-970'),
	'node invert is not copied onto arc y/elev and sys_slope stays null'
);

-- Same geometry, parameter off: keep the digitized direction.
UPDATE config_param_system SET value = 'false' WHERE parameter = 'edit_slope_direction';

SELECT pg_temp.insert_node('-974', 49.140, 500000, 4600020);
SELECT pg_temp.insert_node('-975', 49.150, 500010, 4600020);

SELECT lives_ok(
	$$SELECT pg_temp.insert_arc('-973', 500000, 4600020, 500010, 4600020, NULL, NULL, false)$$,
	'arc inserts when edit_slope_direction is false'
);

SELECT is(
	(SELECT node_1 FROM arc WHERE arc_id = '-973'),
	'-974',
	'parameter false keeps the digitized start node'
);

SELECT cmp_ok(
	(SELECT slope FROM ve_arc WHERE arc_id = '-973'),
	'<',
	0::numeric,
	'slope stays negative when the parameter is false'
);

-- inverted_slope keeps the uphill direction.
UPDATE config_param_system SET value = 'true' WHERE parameter = 'edit_slope_direction';

SELECT pg_temp.insert_node('-977', 49.140, 500000, 4600040);
SELECT pg_temp.insert_node('-978', 49.150, 500010, 4600040);

SELECT lives_ok(
	$$SELECT pg_temp.insert_arc('-976', 500000, 4600040, 500010, 4600040, NULL, NULL, true)$$,
	'inverted_slope arc inserts'
);

SELECT is(
	(SELECT node_1 FROM arc WHERE arc_id = '-976'),
	'-977',
	'inverted_slope does not swap an uphill node invert'
);

SELECT cmp_ok(
	(SELECT slope FROM ve_arc WHERE arc_id = '-976'),
	'<',
	0::numeric,
	'inverted_slope keeps a negative slope'
);

-- Arc elev wins over the node invert. Nodes are already downhill; arc elev is uphill.
SELECT pg_temp.insert_node('-981', 49.150, 500000, 4600060);
SELECT pg_temp.insert_node('-982', 49.140, 500010, 4600060);

SELECT lives_ok(
	$$SELECT pg_temp.insert_arc('-980', 500000, 4600060, 500010, 4600060, 49.140, 49.150, false)$$,
	'arc with its own elev inserts'
);

SELECT is(
	(SELECT node_1 FROM arc WHERE arc_id = '-980'),
	'-982',
	'arc elev1 < elev2 still reverses, ignoring the node invert'
);

SELECT cmp_ok(
	(SELECT elev1 FROM arc WHERE arc_id = '-980'),
	'>',
	(SELECT elev2 FROM arc WHERE arc_id = '-980'),
	'swapped arc elev goes downhill'
);

SELECT cmp_ok(
	(SELECT sys_slope FROM arc WHERE arc_id = '-980'),
	'>',
	0::numeric,
	'stored sys_slope follows the arc elev after the swap'
);

SELECT finish();
ROLLBACK;

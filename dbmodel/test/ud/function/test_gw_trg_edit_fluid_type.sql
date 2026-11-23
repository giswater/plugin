/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(17);

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

UPDATE config_param_system SET value = 'TRUE' WHERE parameter = 'edit_connect_autoupdate_fluid';

-- down: connec edited by the user. up: connec whose link exits to down (upstream).
-- other: connec on a different arc, must stay untouched by the arc push.
CREATE TEMP TABLE _t_fluid AS
SELECT d.connec_id AS down_id,
       d.arc_id,
       dl.link_id AS down_link_id,
       u.connec_id AS up_id,
       ul.link_id AS up_link_id,
       o.connec_id AS other_id,
       o.fluid_type AS other_fluid
FROM connec d
JOIN link dl ON dl.feature_id = d.connec_id AND dl.feature_type = 'CONNEC' AND dl.state = 1 AND dl.exit_type = 'ARC'
JOIN connec u ON u.connec_id <> d.connec_id AND u.state = 1 AND u.arc_id IS DISTINCT FROM d.arc_id
JOIN link ul ON ul.feature_id = u.connec_id AND ul.feature_type = 'CONNEC' AND ul.state = 1
JOIN connec o ON o.connec_id <> d.connec_id AND o.connec_id <> u.connec_id AND o.state = 1
    AND o.arc_id IS DISTINCT FROM d.arc_id
WHERE d.state = 1 AND d.arc_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM ve_connec vc WHERE vc.connec_id = d.connec_id)
  AND EXISTS (SELECT 1 FROM ve_arc va WHERE va.arc_id = d.arc_id)
ORDER BY d.connec_id, u.connec_id, o.connec_id
LIMIT 1;

SELECT is((SELECT count(*)::integer FROM _t_fluid), 1, 'fixture: operative connec, upstream connec and other arc');

UPDATE connec SET fluid_type = 1 WHERE connec_id = (SELECT up_id FROM _t_fluid);
UPDATE link SET exit_type = 'CONNEC', exit_id = (SELECT down_id FROM _t_fluid)
WHERE link_id = (SELECT up_link_id FROM _t_fluid);

-- reconnect/move of the downstream connec must not copy its fluid upstream
UPDATE connec SET the_geom = the_geom WHERE connec_id = (SELECT down_id FROM _t_fluid);

SELECT is(
    (SELECT fluid_type FROM connec WHERE connec_id = (SELECT up_id FROM _t_fluid)),
    1,
    'moving the downstream connec does not change the upstream fluid_type'
);

UPDATE arc SET fluid_type = 1 WHERE arc_id = (SELECT arc_id FROM _t_fluid);
UPDATE ve_connec SET fluid_type = 3 WHERE connec_id = (SELECT down_id FROM _t_fluid);

SELECT is(
    (SELECT fluid_type FROM connec WHERE connec_id = (SELECT down_id FROM _t_fluid)),
    1,
    'with autoupdate true editing the connec takes the arc fluid_type'
);
SELECT is(
    (SELECT fluid_type FROM link WHERE link_id = (SELECT down_link_id FROM _t_fluid)),
    1,
    'the link copies the connec fluid_type taken from the arc'
);
SELECT is(
    (SELECT fluid_type FROM connec WHERE connec_id = (SELECT up_id FROM _t_fluid)),
    1,
    'editing the downstream fluid_type does not update the upstream connec'
);

UPDATE ve_arc SET fluid_type = 4 WHERE arc_id = (SELECT arc_id FROM _t_fluid);

SELECT is(
    (SELECT fluid_type FROM connec WHERE connec_id = (SELECT down_id FROM _t_fluid)),
    4,
    'arc fluid_type change updates the connec on that arc'
);
SELECT is(
    (SELECT count(*)::integer FROM gully WHERE arc_id = (SELECT arc_id FROM _t_fluid) AND fluid_type IS DISTINCT FROM 4),
    0,
    'arc fluid_type change updates the gullies on that arc'
);
SELECT is(
    (SELECT count(*)::integer FROM link
     WHERE exit_type = 'ARC' AND exit_id = (SELECT arc_id FROM _t_fluid) AND fluid_type IS DISTINCT FROM 4),
    0,
    'arc fluid_type change updates the links that exit to that arc'
);
SELECT is(
    (SELECT fluid_type FROM connec WHERE connec_id = (SELECT other_id FROM _t_fluid)),
    (SELECT other_fluid FROM _t_fluid),
    'a connec on another arc keeps its fluid_type'
);

UPDATE config_param_system SET value = 'FALSE' WHERE parameter = 'edit_connect_autoupdate_fluid';
UPDATE ve_arc SET fluid_type = 2 WHERE arc_id = (SELECT arc_id FROM _t_fluid);

SELECT is(
    (SELECT fluid_type FROM connec WHERE connec_id = (SELECT down_id FROM _t_fluid)),
    4,
    'with autoupdate false an arc fluid_type change does not touch its connec'
);
SELECT is(
    (SELECT fluid_type FROM link WHERE link_id = (SELECT down_link_id FROM _t_fluid)),
    4,
    'with autoupdate false an arc fluid_type change does not touch its link'
);
SELECT is(
    (SELECT count(*)::integer FROM gully WHERE arc_id = (SELECT arc_id FROM _t_fluid) AND fluid_type IS DISTINCT FROM 4),
    0,
    'with autoupdate false an arc fluid_type change does not touch its gullies'
);

UPDATE ve_connec SET fluid_type = 3 WHERE connec_id = (SELECT down_id FROM _t_fluid);

SELECT is(
    (SELECT fluid_type FROM connec WHERE connec_id = (SELECT down_id FROM _t_fluid)),
    3,
    'with autoupdate false the connec keeps the fluid_type set on the form'
);
SELECT is(
    (SELECT fluid_type FROM link WHERE link_id = (SELECT down_link_id FROM _t_fluid)),
    3,
    'with autoupdate false the link copies the fluid_type set on the connec'
);

CREATE TEMP TABLE _t_gully AS
SELECT g.gully_id, l.link_id, g.arc_id
FROM gully g
JOIN link l ON l.feature_id = g.gully_id AND l.feature_type = 'GULLY' AND l.state = 1 AND l.exit_type = 'ARC'
WHERE g.state = 1 AND g.arc_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM ve_gully vg WHERE vg.gully_id = g.gully_id)
ORDER BY g.gully_id
LIMIT 1;

SELECT is((SELECT count(*)::integer FROM _t_gully), 1, 'fixture: operative gully');

UPDATE config_param_system SET value = 'TRUE' WHERE parameter = 'edit_connect_autoupdate_fluid';
UPDATE arc SET fluid_type = 2 WHERE arc_id = (SELECT arc_id FROM _t_gully);
UPDATE ve_gully SET fluid_type = 3 WHERE gully_id = (SELECT gully_id FROM _t_gully);

SELECT is(
    (SELECT fluid_type FROM gully WHERE gully_id = (SELECT gully_id FROM _t_gully)),
    2,
    'with autoupdate true editing the gully takes the arc fluid_type'
);
SELECT is(
    (SELECT fluid_type FROM link WHERE link_id = (SELECT link_id FROM _t_gully)),
    2,
    'the link copies the gully fluid_type taken from the arc'
);

SELECT finish();
ROLLBACK;

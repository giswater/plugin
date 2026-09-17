/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

-- Suppress NOTICE messages
SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(16);

DELETE FROM link WHERE feature_id = 3095 AND feature_type = 'CONNEC';

INSERT INTO ve_link (code, sys_code, link_type, feature_type, feature_id, exit_type, exit_id, state, state_type, expl_id, sector_id, the_geom, linkcat_id, fluid_type)
SELECT '-901', '-901', cl.link_type, 'CONNEC', c.connec_id, 'ARC', a.arc_id, 1, 2, c.expl_id, c.sector_id,
	ST_MakeLine(c.the_geom, ST_ClosestPoint(a.the_geom, c.the_geom)),
	cl.id, 0
FROM connec c
JOIN LATERAL (
	SELECT arc_id, the_geom FROM ve_arc
	WHERE state > 0
	ORDER BY the_geom <-> c.the_geom
	LIMIT 1
) a ON true
CROSS JOIN LATERAL (
	SELECT id, link_type FROM cat_link
	WHERE link_type IN (SELECT link_type FROM cat_link GROUP BY link_type HAVING count(*) > 1)
	LIMIT 1
) cl
WHERE c.connec_id = 3095;

SELECT is((SELECT count(*)::integer FROM ve_link WHERE code = '-901'), 1, 'INSERT: ve_link -901 was inserted');
SELECT is((SELECT count(*)::integer FROM link WHERE code = '-901'), 1, 'INSERT: link -901 was inserted');
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), TRUE, 'INSERT: userdefined_geom defaults to TRUE');

UPDATE link SET userdefined_geom = NULL WHERE code = '-901';
UPDATE ve_link SET verified = 1 WHERE code = '-901';
SELECT ok((SELECT userdefined_geom FROM link WHERE code = '-901') IS NULL, 'UPDATE: other attrs keep userdefined_geom NULL');

UPDATE ve_link SET the_geom = ST_Translate(the_geom, 0.001, 0.001) WHERE code = '-901';
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), TRUE, 'UPDATE: geom change sets userdefined_geom TRUE');

UPDATE ve_link SET userdefined_geom = FALSE WHERE code = '-901';
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), FALSE, 'UPDATE: forced FALSE is kept');

UPDATE ve_link SET userdefined_geom = FALSE, the_geom = ST_Translate(the_geom, 0.001, 0.001) WHERE code = '-901';
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), FALSE, 'UPDATE: forced FALSE is kept when geom changes');

UPDATE ve_link SET verified = 1 WHERE code = '-901';
SELECT is((SELECT verified::integer FROM ve_link WHERE code = '-901'), 1, 'UPDATE: ve_link -901 was updated');
SELECT is((SELECT verified::integer FROM link WHERE code = '-901'), 1, 'UPDATE: link -901 was updated');

CREATE TEMP TABLE _linkcat_update AS
SELECT
	(SELECT linkcat_id FROM ve_link WHERE code = '-901') AS old_id,
	(SELECT id FROM cat_link
	 WHERE link_type = (SELECT link_type FROM ve_link WHERE code = '-901')
	   AND id IS DISTINCT FROM (SELECT linkcat_id FROM ve_link WHERE code = '-901')
	 LIMIT 1) AS new_id;

UPDATE ve_link SET linkcat_id = (SELECT new_id FROM _linkcat_update) WHERE code = '-901';
SELECT is((SELECT linkcat_id FROM ve_link WHERE code = '-901'),
	(SELECT new_id FROM _linkcat_update),
	'UPDATE: ve_link linkcat_id was updated');
SELECT is((SELECT linkcat_id FROM link WHERE code = '-901'),
	(SELECT new_id FROM _linkcat_update),
	'UPDATE: link linkcat_id was updated');

DELETE FROM ve_link WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_link WHERE code = '-901'), 0, 'DELETE: ve_link -901 was deleted');
SELECT is((SELECT count(*)::integer FROM link WHERE code = '-901'), 0, 'DELETE: link -901 was deleted');

-- Child view: cat_feature.id CONDUITLINK must resolve to man_conduitlink (sample profile)
INSERT INTO ve_link_conduitlink (code, sys_code, link_type, feature_type, feature_id, exit_type, exit_id, state, state_type, expl_id, sector_id, the_geom, linkcat_id, fluid_type)
SELECT '-902', '-902', 'CONDUITLINK', 'CONNEC', c.connec_id, 'ARC', a.arc_id, 1, 2, c.expl_id, c.sector_id,
	ST_MakeLine(c.the_geom, ST_ClosestPoint(a.the_geom, c.the_geom)),
	cl.id, 0
FROM connec c
JOIN LATERAL (
	SELECT arc_id, the_geom FROM ve_arc
	WHERE state > 0
	ORDER BY the_geom <-> c.the_geom
	LIMIT 1
) a ON true
CROSS JOIN LATERAL (SELECT id FROM cat_link WHERE link_type = 'CONDUITLINK' LIMIT 1) cl
WHERE c.connec_id = 3095;

SELECT is((SELECT count(*)::integer FROM ve_link_conduitlink WHERE code = '-902'), 1, 'INSERT: ve_link_conduitlink -902 was inserted');
SELECT is((SELECT count(*)::integer FROM link WHERE code = '-902'), 1, 'INSERT: link -902 was inserted');
SELECT is((SELECT count(*)::integer FROM man_conduitlink mc JOIN link l ON l.link_id = mc.link_id WHERE l.code = '-902'), 1,
	'INSERT: man_conduitlink row created for ve_link_conduitlink -902');

SELECT * FROM finish();

ROLLBACK;

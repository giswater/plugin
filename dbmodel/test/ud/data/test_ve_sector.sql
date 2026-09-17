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

SELECT plan(10);

INSERT INTO ve_sector
(sector_id, code, "name", descript, macrosector_id, expl_id, muni_id, sector_type, the_geom, graphconfig, stylesheet)
VALUES(-901, '-901', 'sector_01', 'sector_project_ud', 1, '{1}', '{1}', NULL, NULL, '{"use":[{"nodeParent":"", "toArc":[]}], "ignore":[], "forceClosed":[]}', NULL);
SELECT is((SELECT count(*)::integer FROM ve_sector WHERE code = '-901'), 1, 'INSERT: ve_sector -901 was inserted');
SELECT is((SELECT count(*)::integer FROM sector WHERE code = '-901'), 1, 'INSERT: sector -901 was inserted');

UPDATE ve_sector SET descript = 'updated descript' WHERE code = '-901';
SELECT is((SELECT descript FROM ve_sector WHERE code = '-901'), 'updated descript', 'UPDATE: ve_sector -901 was updated');
SELECT is((SELECT descript FROM sector WHERE code = '-901'), 'updated descript', 'UPDATE: sector -901 was updated');

DELETE FROM ve_sector WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_sector WHERE code = '-901'), 0, 'DELETE: ve_sector -901 was deleted');
SELECT is((SELECT count(*)::integer FROM sector WHERE code = '-901'), 0, 'DELETE: sector -901 was deleted');

INSERT INTO ve_sector (code, "name") VALUES ('-902', 'sector-null-expl');
SELECT is((SELECT count(*)::integer FROM sector WHERE code = '-902'), 1, 'INSERT: ve_sector -902 was inserted');
SELECT is((SELECT expl_id FROM sector WHERE code = '-902'), ARRAY[0]::integer[], 'INSERT: missing expl_id defaults to ARRAY[0]');
SELECT is((SELECT muni_id FROM sector WHERE code = '-902'), ARRAY[0]::integer[], 'INSERT: missing muni_id defaults to ARRAY[0]');
DELETE FROM ve_sector WHERE code = '-902';
SELECT is((SELECT count(*)::integer FROM sector WHERE code = '-902'), 0, 'DELETE: ve_sector -902 was deleted');


SELECT * FROM finish();


ROLLBACK;
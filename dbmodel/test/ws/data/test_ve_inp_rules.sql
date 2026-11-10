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

SELECT plan(6);

INSERT INTO ve_inp_rules (id, sector_id, "text", active)
VALUES(-901, (SELECT sector_id FROM sector WHERE code = '3' AND sector_id > 0), '', false);
SELECT is((SELECT count(*)::integer FROM ve_inp_rules WHERE id = -901), 1, 'INSERT: ve_inp_rules -901 was inserted');
SELECT is((SELECT count(*)::integer FROM inp_rules WHERE id = -901), 1, 'INSERT: inp_rules -901 was inserted');

UPDATE ve_inp_rules SET text = 'updated text' WHERE id = -901;
SELECT is((SELECT text FROM ve_inp_rules WHERE id = -901), 'updated text', 'UPDATE: ve_inp_rules -901 was updated');
SELECT is((SELECT text FROM inp_rules WHERE id = -901), 'updated text', 'UPDATE: inp_rules -901 was updated');

DELETE FROM ve_inp_rules WHERE id = -901;
SELECT is((SELECT count(*)::integer FROM ve_inp_rules WHERE id = -901), 0, 'DELETE: ve_inp_rules -901 was deleted');
SELECT is((SELECT count(*)::integer FROM inp_rules WHERE id = -901), 0, 'DELETE: inp_rules -901 was deleted');


SELECT * FROM finish();


ROLLBACK;
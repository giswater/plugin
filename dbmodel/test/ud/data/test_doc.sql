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

SELECT plan(4);

-- Subtest 1: Testing doc operations
INSERT INTO doc (doc_type, "path", observ, "date", user_name, tstamp, the_geom, "name")
VALUES('OTHER', 'https://bgeo.es', NULL, '2024-08-19 12:06:28.330', 'postgres', '2024-08-19 12:06:28.330', NULL, 'Demo document 4');
SELECT is((SELECT count(*)::integer FROM doc WHERE "name" = 'Demo document 4'), 1, 'INSERT: doc "Demo document 4" was inserted');

UPDATE doc SET observ = 'updated test' WHERE "name" = 'Demo document 4';
SELECT is((SELECT observ FROM doc WHERE "name" = 'Demo document 4'), 'updated test', 'UPDATE: observ was updated to "updated test"');

INSERT INTO doc (doc_type, "path", observ, "date", user_name, tstamp, the_geom, "name")
VALUES('OTHER', 'https://bgeo2.es', 'upsert test', '2024-08-19 12:06:28.330', 'postgres', '2024-08-19 12:06:28.330', NULL, 'Demo document 4')
ON CONFLICT (name) DO UPDATE SET observ = EXCLUDED.observ;
SELECT is((SELECT observ FROM doc WHERE "name" = 'Demo document 4'), 'upsert test', 'UPSERT: observ was updated to "upsert test" using ON CONFLICT');

-- Check that inserting a doc with NULL required field throws an error
-- SELECT throws_ok(
--     $$
--         INSERT INTO doc (doc_type, "path", observ, "date", user_name, tstamp, the_geom, "name")
--         VALUES(NULL, 'https://bgeo.es', NULL, '2024-08-19 12:06:28.330', 'postgres', '2024-08-19 12:06:28.330', NULL, 'Demo document 5');
--     $$,
--     'Function: [gw_trg_doc] - THE SPECIFIED PATH IS ALREADY IN USE ON ANOTHER DOCUMENT: DEMO DOCUMENT 4. HINT: USE A DIFFERENT PATH OR CHANGE IT IN THE OTHER DOCUMENT',
--     'THROWS_OK: inserting doc with NULL doc_type should error'
-- );

DELETE FROM doc WHERE "name" = 'Demo document 4';
SELECT is((SELECT count(*)::integer FROM doc WHERE "name" = 'Demo document 4'), 0, 'DELETE: doc "Demo document 4" was deleted');


SELECT * FROM finish();

ROLLBACK;

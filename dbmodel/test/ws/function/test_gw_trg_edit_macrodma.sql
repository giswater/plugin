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

-- Expected next id: max non-negative macrodma_id + 1
CREATE TEMP TABLE _expected ON COMMIT DROP AS
SELECT coalesce(max(macrodma_id), 0) + 1 AS next_id FROM macrodma WHERE macrodma_id >= 0;

-- 1. Insert with geometry through ve_macrodma
SELECT lives_ok(
    $sql$
    INSERT INTO ve_macrodma (name, code, expl_id, the_geom)
    VALUES ('test_macrodma_geom', 'TEST_MDMA_GEOM', ARRAY[0],
        ST_Multi(ST_Buffer(ST_SetSRID(ST_MakePoint(0, 0),
            Find_SRID(current_schema()::varchar, 'macrodma', 'the_geom')), 10)))
    $sql$,
    'Insert into ve_macrodma with geometry --> does not raise'
);

-- 2. Generated id is max + 1
SELECT is(
    (SELECT macrodma_id FROM macrodma WHERE name = 'test_macrodma_geom'),
    (SELECT next_id FROM _expected),
    'gw_trg_edit_macrodma --> new macrodma_id is max(macrodma_id) + 1'
);

-- 3. Geometry is stored on the new row
SELECT ok(
    (SELECT the_geom IS NOT NULL FROM macrodma WHERE name = 'test_macrodma_geom'),
    'gw_trg_edit_macrodma --> geometry is saved on insert'
);

-- 4. Insert without geometry
SELECT lives_ok(
    $sql$
    INSERT INTO ve_macrodma (name, code, expl_id)
    VALUES ('test_macrodma_nogeom', 'TEST_MDMA_NOGEOM', ARRAY[0])
    $sql$,
    'Insert into ve_macrodma without geometry --> does not raise'
);

-- 5. Next insert keeps incrementing
SELECT is(
    (SELECT macrodma_id FROM macrodma WHERE name = 'test_macrodma_nogeom'),
    (SELECT next_id + 1 FROM _expected),
    'gw_trg_edit_macrodma --> consecutive inserts get consecutive ids'
);

-- 6-7. Table without any non-negative id: first id must be 1, not NULL
-- Bypass FKs and control triggers to empty the table (rolled back at the end)
SET LOCAL session_replication_role = replica;
DELETE FROM macrodma WHERE macrodma_id >= 0;
SET LOCAL session_replication_role = origin;

SELECT lives_ok(
    $sql$
    INSERT INTO ve_macrodma (name, code, expl_id)
    VALUES ('test_macrodma_empty', 'TEST_MDMA_EMPTY', ARRAY[0])
    $sql$,
    'Insert into ve_macrodma on a table without non-negative ids --> does not raise'
);

SELECT is(
    (SELECT macrodma_id FROM macrodma WHERE name = 'test_macrodma_empty'),
    1,
    'gw_trg_edit_macrodma --> first id is 1 when no non-negative id exists'
);

SELECT finish();
ROLLBACK;

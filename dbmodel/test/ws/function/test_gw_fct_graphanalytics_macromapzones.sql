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

SELECT has_function(
    'gw_fct_graphanalytics_macromapzones',
    ARRAY['json'],
    'gw_fct_graphanalytics_macromapzones(json) exists'
);

-- macrosector 1 only contains sectors of exploitation 1
UPDATE macrosector SET the_geom = NULL WHERE macrosector_id = 1;

SELECT is(
    (gw_fct_graphanalytics_macromapzones($${"data":{"parameters":{"graphClass":"MACROSECTOR","exploitation":"1","updateMapZone":0,"commitChanges":false}}}$$)::json)->>'status',
    'Accepted',
    'MACROSECTOR preview returns Accepted'
);

SELECT ok(
    (SELECT the_geom IS NULL FROM macrosector WHERE macrosector_id = 1),
    'commitChanges false does not write macrosector.the_geom'
);

SELECT is(
    (gw_fct_graphanalytics_macromapzones($${"data":{"parameters":{"graphClass":"MACROSECTOR","exploitation":"1","updateMapZone":0,"commitChanges":false}}}$$)::json)->'body'->'data'->'polygon'->>'type',
    'FeatureCollection',
    'MACROSECTOR preview returns a polygon FeatureCollection'
);

SELECT is(
    (gw_fct_graphanalytics_macromapzones($${"data":{"parameters":{"graphClass":"MACROSECTOR","exploitation":"2","updateMapZone":0,"commitChanges":true}}}$$)::json)->>'status',
    'Accepted',
    'MACROSECTOR commit on another exploitation returns Accepted'
);

SELECT ok(
    (SELECT the_geom IS NULL FROM macrosector WHERE macrosector_id = 1),
    'committing exploitation 2 does not rebuild macrosector 1'
);

SELECT is(
    (gw_fct_graphanalytics_macromapzones($${"data":{"parameters":{"graphClass":"MACROSECTOR","exploitation":"1","updateMapZone":0,"commitChanges":true}}}$$)::json)->>'status',
    'Accepted',
    'MACROSECTOR commit returns Accepted'
);

SELECT ok(
    (
        SELECT m.the_geom IS NOT NULL
            AND ST_Area(m.the_geom) > 0
            AND abs(ST_Area(m.the_geom) - ST_Area(ST_UnaryUnion(ST_Collect(s.the_geom)))) < 1
        FROM macrosector m
        JOIN sector s ON s.macrosector_id = m.macrosector_id AND s.expl_id && ARRAY[1]::integer[]
        WHERE m.macrosector_id = 1
        GROUP BY m.the_geom
    ),
    'macrosector 1 geom is the union of its sectors in exploitation 1'
);

UPDATE dma SET macrodma_id = 1
WHERE dma_id = (
    SELECT dma_id FROM dma
    WHERE the_geom IS NOT NULL AND expl_id && ARRAY[1]::integer[]
    ORDER BY dma_id
    LIMIT 1
);
UPDATE macrodma SET the_geom = NULL WHERE macrodma_id = 1;

SELECT is(
    (gw_fct_graphanalytics_macromapzones($${"data":{"parameters":{"graphClass":"MACRODMA","exploitation":"1","updateMapZone":0,"commitChanges":true}}}$$)::json)->>'status',
    'Accepted',
    'MACRODMA commit returns Accepted'
);

SELECT ok(
    (SELECT the_geom IS NOT NULL AND ST_Area(the_geom) > 0 FROM macrodma WHERE macrodma_id = 1),
    'MACRODMA commit writes macrodma.the_geom from its dma'
);

INSERT INTO macrodqa (macrodqa_id, code, name, expl_id, active)
SELECT -990, '-990', 'test-macrodqa', expl_id, true
FROM macrodma
WHERE macrodma_id = 1;

UPDATE dqa SET macrodqa_id = -990
WHERE dqa_id = (
    SELECT dqa_id FROM dqa
    WHERE the_geom IS NOT NULL AND expl_id && ARRAY[1]::integer[]
    ORDER BY dqa_id
    LIMIT 1
);

SELECT is(
    (gw_fct_graphanalytics_macromapzones($${"data":{"parameters":{"graphClass":"MACRODQA","exploitation":"1","updateMapZone":0,"commitChanges":true}}}$$)::json)->>'status',
    'Accepted',
    'MACRODQA commit returns Accepted'
);

SELECT ok(
    (SELECT the_geom IS NOT NULL AND ST_Area(the_geom) > 0 FROM macrodqa WHERE macrodqa_id = -990),
    'MACRODQA commit writes macrodqa.the_geom from its dqa'
);

-- mapzones v1 only recalculates the macro when the flag is on
INSERT INTO selector_expl (expl_id, cur_user)
SELECT e.expl_id, current_user FROM exploitation e
ON CONFLICT (expl_id, cur_user) DO NOTHING;

INSERT INTO selector_sector (sector_id, cur_user)
SELECT s.sector_id, current_user FROM sector s
ON CONFLICT (sector_id, cur_user) DO NOTHING;

UPDATE macrosector SET the_geom = NULL WHERE macrosector_id = 1;

SELECT is(
    (gw_fct_graphanalytics_mapzones_v1($${"data":{"parameters":{"graphClass":"SECTOR","exploitation":"1","updateMapZone":2,"geomParamUpdate":5,"commitChanges":true,"usePlanPsector":false,"recalculateMacromapzones":true}}}$$)::json)->>'status',
    'Accepted',
    'mapzones SECTOR with recalculateMacromapzones returns Accepted'
);

SELECT ok(
    (SELECT the_geom IS NOT NULL AND ST_Area(the_geom) > 0 FROM macrosector WHERE macrosector_id = 1),
    'mapzones SECTOR rebuilds macrosector when the flag is true'
);

UPDATE macrosector SET the_geom = NULL WHERE macrosector_id = 1;

SELECT is(
    (gw_fct_graphanalytics_mapzones_v1($${"data":{"parameters":{"graphClass":"SECTOR","exploitation":"1","updateMapZone":2,"geomParamUpdate":5,"commitChanges":true,"usePlanPsector":false,"recalculateMacromapzones":false}}}$$)::json)->>'status',
    'Accepted',
    'mapzones SECTOR without recalculateMacromapzones returns Accepted'
);

SELECT ok(
    (SELECT the_geom IS NULL FROM macrosector WHERE macrosector_id = 1),
    'mapzones SECTOR does not rebuild macrosector when the flag is false'
);

SELECT finish();
ROLLBACK;

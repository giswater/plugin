/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(5);

SELECT has_function(
    'gw_fct_graphanalytics_macromapzones',
    ARRAY['json'],
    'gw_fct_graphanalytics_macromapzones(json) exists'
);

-- sample sectors sit on expl 0; the macro query only keeps rows overlapping the requested exploitation
UPDATE sector
SET expl_id = ARRAY[1]::integer[],
    muni_id = ARRAY[1]::integer[]
WHERE macrosector_id = 1;

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

SELECT finish();
ROLLBACK;

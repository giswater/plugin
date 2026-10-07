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

SELECT * FROM no_plan();

-- Check table
SELECT has_table('mapzone_graph'::name, 'Table mapzone_graph should exist');

-- Check columns
SELECT columns_are(
    'mapzone_graph',
    ARRAY[
        'node_id', 'mapzone_id', 'mapzone_type', 'flow_sign', 'synoptic_id', 'synoptic_geom'
    ],
    'Table mapzone_graph should have the correct columns'
);

-- Check column types
SELECT col_type_is('mapzone_graph', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('mapzone_graph', 'mapzone_id', 'int4', 'Column mapzone_id should be int4');
SELECT col_type_is('mapzone_graph', 'mapzone_type', 'text', 'Column mapzone_type should be text');
SELECT col_type_is('mapzone_graph', 'flow_sign', 'int2', 'Column flow_sign should be int2');
SELECT col_type_is('mapzone_graph', 'synoptic_id', 'int4', 'Column synoptic_id should be int4');
SELECT col_type_is('mapzone_graph', 'synoptic_geom', 'geometry(LineString)', 'Column synoptic_geom should be geometry(LineString)');

-- Finish
SELECT * FROM finish();

ROLLBACK;

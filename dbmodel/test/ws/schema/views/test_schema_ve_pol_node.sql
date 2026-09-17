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

-- Check view ve_pol_node
SELECT has_view('ve_pol_node'::name, 'View ve_pol_node should exist');

-- Check view columns
SELECT columns_are(
    've_pol_node',
    ARRAY[
        'pol_id', 'feature_id', 'featurecat_id', 'state', 'sys_type', 'the_geom',
        'trace_featuregeom', 'state_type'
    ],
    'View ve_pol_node should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_pol_node', 'pol_id', 'varchar(16)', 'Column pol_id should be varchar(16)');
SELECT col_type_is('ve_pol_node', 'feature_id', 'int4', 'Column feature_id should be int4');
SELECT col_type_is('ve_pol_node', 'featurecat_id', 'varchar(50)', 'Column featurecat_id should be varchar(50)');
SELECT col_type_is('ve_pol_node', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_pol_node', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_pol_node', 'the_geom', 'geometry(multipolygon, SRID_VALUE)', 'Column the_geom should be geometry(multipolygon, SRID_VALUE)');
SELECT col_type_is('ve_pol_node', 'trace_featuregeom', 'bool', 'Column trace_featuregeom should be bool');
SELECT col_type_is('ve_pol_node', 'state_type', 'int2', 'Column state_type should be int2');

SELECT * FROM finish();

ROLLBACK;

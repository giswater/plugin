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

-- Check view ve_inp_dscenario_reservoir
SELECT has_view('ve_inp_dscenario_reservoir'::name, 'View ve_inp_dscenario_reservoir should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_reservoir',
    ARRAY[
        'dscenario_id', 'node_id', 'pattern_id', 'head', 'init_quality', 'source_type',
        'source_quality', 'source_pattern_id', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_reservoir should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_reservoir', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_reservoir', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

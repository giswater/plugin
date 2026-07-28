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

-- Check view ve_inp_dscenario_shortpipe
SELECT has_view('ve_inp_dscenario_shortpipe'::name, 'View ve_inp_dscenario_shortpipe should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_shortpipe',
    ARRAY[
        'dscenario_id', 'node_id', 'minorloss', 'status', 'bulk_coeff', 'wall_coeff',
        'to_arc', 'head', 'pattern_id', 'demand', 'demand_pattern_id', 'emitter_coeff',
        'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_shortpipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'demand_pattern_id', 'varchar(16)', 'Column demand_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_shortpipe', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

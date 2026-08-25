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

-- Check view ve_inp_frvalve
SELECT has_view('ve_inp_frvalve'::name, 'View ve_inp_frvalve should exist');

-- Check view columns
SELECT columns_are(
    've_inp_frvalve',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'flwreg_length', 'valve_type', 'custom_dint',
        'setting', 'curve_id', 'minorloss', 'add_settings', 'init_quality', 'status',
        'the_geom', 'p_state'
    ],
    'View ve_inp_frvalve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_frvalve', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_frvalve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_frvalve', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_frvalve', 'flwreg_length', 'numeric', 'Column flwreg_length should be numeric');
SELECT col_type_is('ve_inp_frvalve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_inp_frvalve', 'custom_dint', 'numeric(12,4)', 'Column custom_dint should be numeric(12,4)');
SELECT col_type_is('ve_inp_frvalve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_inp_frvalve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_frvalve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_inp_frvalve', 'add_settings', 'float8', 'Column add_settings should be float8');
SELECT col_type_is('ve_inp_frvalve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_frvalve', 'status', 'varchar(16)', 'Column status should be varchar(16)');
SELECT col_type_is('ve_inp_frvalve', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_frvalve', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

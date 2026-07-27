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

-- Check view ve_inp_dscenario_frvalve
SELECT has_view('ve_inp_dscenario_frvalve'::name, 'View ve_inp_dscenario_frvalve should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_frvalve',
    ARRAY[
        'dscenario_id', 'element_id', 'node_id', 'valve_type', 'custom_dint', 'setting',
        'curve_id', 'minorloss', 'add_settings', 'init_quality', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_frvalve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_frvalve', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'custom_dint', 'numeric(12,4)', 'Column custom_dint should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'add_settings', 'float8', 'Column add_settings should be float8');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_frvalve', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

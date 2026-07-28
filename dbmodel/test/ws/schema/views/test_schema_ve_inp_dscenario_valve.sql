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

-- Check view ve_inp_dscenario_valve
SELECT has_view('ve_inp_dscenario_valve'::name, 'View ve_inp_dscenario_valve should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_valve',
    ARRAY[
        'dscenario_id', 'node_id', 'nodarc_id', 'valve_type', 'setting', 'curve_id',
        'minorloss', 'status', 'add_settings', 'init_quality', 'to_arc', 'head',
        'pattern_id', 'demand', 'demand_pattern_id', 'emitter_coeff', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_valve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_valve', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_valve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_valve', 'nodarc_id', 'text', 'Column nodarc_id should be text');
SELECT col_type_is('ve_inp_dscenario_valve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_valve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_valve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_valve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_valve', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_valve', 'add_settings', 'float8', 'Column add_settings should be float8');
SELECT col_type_is('ve_inp_dscenario_valve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_valve', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_dscenario_valve', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_inp_dscenario_valve', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_valve', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_valve', 'demand_pattern_id', 'varchar(16)', 'Column demand_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_valve', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_valve', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_valve', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

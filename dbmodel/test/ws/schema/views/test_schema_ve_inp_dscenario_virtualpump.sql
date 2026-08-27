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

-- Check view ve_inp_dscenario_virtualpump
SELECT has_view('ve_inp_dscenario_virtualpump'::name, 'View ve_inp_dscenario_virtualpump should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_virtualpump',
    ARRAY[
        'dscenario_id', 'arc_id', 'power', 'curve_id', 'speed', 'pattern_id',
        'status', 'pump_type', 'effic_curve_id', 'energy_price', 'energy_pattern_id', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_virtualpump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'pump_type', 'varchar(16)', 'Column pump_type should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_virtualpump', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

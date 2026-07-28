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

-- Check view ve_inp_dscenario_pump
SELECT has_view('ve_inp_dscenario_pump'::name, 'View ve_inp_dscenario_pump should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_pump',
    ARRAY[
        'dscenario_id', 'node_id', 'power', 'curve_id', 'speed', 'pattern_id',
        'status', 'effic_curve_id', 'energy_price', 'energy_pattern_id', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_pump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_pump', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_pump', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_pump', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('ve_inp_dscenario_pump', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('ve_inp_dscenario_pump', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_pump', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('ve_inp_dscenario_pump', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_pump', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_pump', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('ve_inp_dscenario_pump', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_pump', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_pump', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

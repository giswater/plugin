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

-- Check view ve_inp_dscenario_raingage
SELECT has_view('ve_inp_dscenario_raingage'::name, 'View ve_inp_dscenario_raingage should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_raingage',
    ARRAY[
        'dscenario_id', 'rg_id', 'form_type', 'intvl', 'scf', 'rgage_type',
        'timser_id', 'fname', 'sta', 'units', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_raingage should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_raingage', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_raingage', 'rg_id', 'varchar(16)', 'Column rg_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'form_type', 'varchar(12)', 'Column form_type should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'intvl', 'varchar(10)', 'Column intvl should be varchar(10)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'scf', 'numeric(12,4)', 'Column scf should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'rgage_type', 'varchar(18)', 'Column rgage_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'fname', 'varchar(254)', 'Column fname should be varchar(254)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'sta', 'varchar(12)', 'Column sta should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'units', 'varchar(3)', 'Column units should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_raingage', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

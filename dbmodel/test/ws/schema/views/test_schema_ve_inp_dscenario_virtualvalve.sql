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

-- Check view ve_inp_dscenario_virtualvalve
SELECT has_view('ve_inp_dscenario_virtualvalve'::name, 'View ve_inp_dscenario_virtualvalve should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_virtualvalve',
    ARRAY[
        'dscenario_id', 'arc_id', 'valve_type', 'diameter', 'setting', 'curve_id',
        'minorloss', 'status', 'init_quality', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_virtualvalve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'diameter', 'numeric(12,4)', 'Column diameter should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_virtualvalve', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

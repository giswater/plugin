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

-- Check view ve_inp_dscenario_conduit
SELECT has_view('ve_inp_dscenario_conduit'::name, 'View ve_inp_dscenario_conduit should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_conduit',
    ARRAY[
        'dscenario_id', 'arc_id', 'arccat_id', 'matcat_id', 'elev1', 'elev2',
        'custom_n', 'barrels', 'culvert', 'kentry', 'kexit', 'kavg',
        'flap', 'q0', 'qmax', 'seepage', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_conduit should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_conduit', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_conduit', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_dscenario_conduit', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'matcat_id', 'varchar(30)', 'Column matcat_id should be varchar(30)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'elev1', 'numeric(12,3)', 'Column elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'elev2', 'numeric(12,3)', 'Column elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'custom_n', 'numeric(12,4)', 'Column custom_n should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'barrels', 'int2', 'Column barrels should be int2');
SELECT col_type_is('ve_inp_dscenario_conduit', 'culvert', 'varchar(10)', 'Column culvert should be varchar(10)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'kentry', 'numeric(12,4)', 'Column kentry should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'kexit', 'numeric(12,4)', 'Column kexit should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'kavg', 'numeric(12,4)', 'Column kavg should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'q0', 'numeric(12,4)', 'Column q0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'qmax', 'numeric(12,4)', 'Column qmax should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'seepage', 'numeric(12,4)', 'Column seepage should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_conduit', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

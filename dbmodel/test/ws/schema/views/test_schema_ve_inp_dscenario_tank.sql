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

-- Check view ve_inp_dscenario_tank
SELECT has_view('ve_inp_dscenario_tank'::name, 'View ve_inp_dscenario_tank should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_tank',
    ARRAY[
        'dscenario_id', 'node_id', 'initlevel', 'minlevel', 'maxlevel', 'diameter',
        'minvol', 'curve_id', 'overflow', 'mixing_model', 'mixing_fraction', 'reaction_coeff',
        'init_quality', 'source_type', 'source_quality', 'source_pattern_id', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_tank should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_tank', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_tank', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_tank', 'initlevel', 'numeric(12,4)', 'Column initlevel should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_tank', 'minlevel', 'numeric(12,4)', 'Column minlevel should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_tank', 'maxlevel', 'numeric(12,4)', 'Column maxlevel should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_tank', 'diameter', 'numeric(12,4)', 'Column diameter should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_tank', 'minvol', 'numeric(12,4)', 'Column minvol should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_tank', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_tank', 'overflow', 'varchar(3)', 'Column overflow should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_tank', 'mixing_model', 'varchar(18)', 'Column mixing_model should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_tank', 'mixing_fraction', 'float8', 'Column mixing_fraction should be float8');
SELECT col_type_is('ve_inp_dscenario_tank', 'reaction_coeff', 'float8', 'Column reaction_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_tank', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_tank', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_tank', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_tank', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_tank', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_tank', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

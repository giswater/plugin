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

-- Check view ve_inp_dscenario_connec
SELECT has_view('ve_inp_dscenario_connec'::name, 'View ve_inp_dscenario_connec should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_connec',
    ARRAY[
        'dscenario_id', 'connec_id', 'pjoint_type', 'pjoint_id', 'demand', 'pattern_id',
        'peak_factor', 'status', 'minorloss', 'custom_roughness', 'custom_length', 'custom_dint',
        'emitter_coeff', 'init_quality', 'source_type', 'source_quality', 'source_pattern_id', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_connec should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_connec', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_connec', 'connec_id', 'int4', 'Column connec_id should be int4');
SELECT col_type_is('ve_inp_dscenario_connec', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_connec', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('ve_inp_dscenario_connec', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_connec', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_connec', 'peak_factor', 'numeric(12,4)', 'Column peak_factor should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_connec', 'status', 'varchar(16)', 'Column status should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_connec', 'minorloss', 'float8', 'Column minorloss should be float8');
SELECT col_type_is('ve_inp_dscenario_connec', 'custom_roughness', 'float8', 'Column custom_roughness should be float8');
SELECT col_type_is('ve_inp_dscenario_connec', 'custom_length', 'float8', 'Column custom_length should be float8');
SELECT col_type_is('ve_inp_dscenario_connec', 'custom_dint', 'float8', 'Column custom_dint should be float8');
SELECT col_type_is('ve_inp_dscenario_connec', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_connec', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_connec', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_connec', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_inp_dscenario_connec', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_connec', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_connec', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

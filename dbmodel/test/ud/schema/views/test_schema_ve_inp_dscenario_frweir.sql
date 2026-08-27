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

-- Check view ve_inp_dscenario_frweir
SELECT has_view('ve_inp_dscenario_frweir'::name, 'View ve_inp_dscenario_frweir should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_frweir',
    ARRAY[
        'dscenario_id', 'element_id', 'node_id', 'weir_type', 'offsetval', 'cd',
        'ec', 'cd2', 'flap', 'geom1', 'geom2', 'geom3',
        'geom4', 'surcharge', 'road_width', 'road_surf', 'coef_curve', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_frweir should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_frweir', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frweir', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frweir', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frweir', 'weir_type', 'varchar(18)', 'Column weir_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'cd', 'numeric(12,4)', 'Column cd should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'ec', 'numeric(12,4)', 'Column ec should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'surcharge', 'varchar(3)', 'Column surcharge should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'road_width', 'float8', 'Column road_width should be float8');
SELECT col_type_is('ve_inp_dscenario_frweir', 'road_surf', 'varchar(16)', 'Column road_surf should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'coef_curve', 'float8', 'Column coef_curve should be float8');
SELECT col_type_is('ve_inp_dscenario_frweir', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_frweir', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

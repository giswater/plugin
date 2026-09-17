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

-- Check view ve_inp_frweir
SELECT has_view('ve_inp_frweir'::name, 'View ve_inp_frweir should exist');

-- Check view columns
SELECT columns_are(
    've_inp_frweir',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'flwreg_length', 'weir_type', 'offsetval',
        'cd', 'ec', 'cd2', 'flap', 'geom1', 'geom2',
        'geom3', 'geom4', 'surcharge', 'road_width', 'road_surf', 'coef_curve',
        'the_geom', 'p_state'
    ],
    'View ve_inp_frweir should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_frweir', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_frweir', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_frweir', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_frweir', 'flwreg_length', 'numeric', 'Column flwreg_length should be numeric');
SELECT col_type_is('ve_inp_frweir', 'weir_type', 'varchar(18)', 'Column weir_type should be varchar(18)');
SELECT col_type_is('ve_inp_frweir', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'cd', 'numeric(12,4)', 'Column cd should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'ec', 'numeric(12,4)', 'Column ec should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_frweir', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('ve_inp_frweir', 'surcharge', 'varchar(3)', 'Column surcharge should be varchar(3)');
SELECT col_type_is('ve_inp_frweir', 'road_width', 'float8', 'Column road_width should be float8');
SELECT col_type_is('ve_inp_frweir', 'road_surf', 'varchar(16)', 'Column road_surf should be varchar(16)');
SELECT col_type_is('ve_inp_frweir', 'coef_curve', 'float8', 'Column coef_curve should be float8');
SELECT col_type_is('ve_inp_frweir', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_frweir', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_inp_weir
SELECT has_view('ve_inp_weir'::name, 'View ve_inp_weir should exist');

-- Check view columns
SELECT columns_are(
    've_inp_weir',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'y1', 'elev1', 'custom_elev1',
        'sys_elev1', 'y2', 'elev2', 'custom_elev2', 'sys_elev2', 'arccat_id',
        'gis_length', 'sector_id', 'macrosector_id', 'state', 'state_type', 'annotation',
        'inverted_slope', 'custom_length', 'expl_id', 'weir_type', 'offsetval', 'cd',
        'ec', 'cd2', 'flap', 'geom1', 'geom2', 'geom3',
        'geom4', 'surcharge', 'the_geom', 'road_width', 'road_surf', 'coef_curve', 'p_state'
    ],
    'View ve_inp_weir should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_weir', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_weir', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_weir', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_weir', 'y1', 'numeric(12,3)', 'Column y1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'elev1', 'numeric(12,3)', 'Column elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'custom_elev1', 'numeric(12,3)', 'Column custom_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'sys_elev1', 'numeric(12,3)', 'Column sys_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'y2', 'numeric(12,3)', 'Column y2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'elev2', 'numeric(12,3)', 'Column elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'custom_elev2', 'numeric(12,3)', 'Column custom_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'sys_elev2', 'numeric(12,3)', 'Column sys_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_weir', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_weir', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_weir', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_weir', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_weir', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_weir', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_weir', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_weir', 'inverted_slope', 'bool', 'Column inverted_slope should be bool');
SELECT col_type_is('ve_inp_weir', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_weir', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_weir', 'weir_type', 'varchar(18)', 'Column weir_type should be varchar(18)');
SELECT col_type_is('ve_inp_weir', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'cd', 'numeric(12,4)', 'Column cd should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'ec', 'numeric(12,4)', 'Column ec should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_weir', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('ve_inp_weir', 'surcharge', 'varchar(3)', 'Column surcharge should be varchar(3)');
SELECT col_type_is('ve_inp_weir', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_weir', 'road_width', 'float8', 'Column road_width should be float8');
SELECT col_type_is('ve_inp_weir', 'road_surf', 'varchar(16)', 'Column road_surf should be varchar(16)');
SELECT col_type_is('ve_inp_weir', 'coef_curve', 'float8', 'Column coef_curve should be float8');
SELECT col_type_is('ve_inp_weir', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_inp_outlet
SELECT has_view('ve_inp_outlet'::name, 'View ve_inp_outlet should exist');

-- Check view columns
SELECT columns_are(
    've_inp_outlet',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'y1', 'elev1', 'custom_elev1',
        'sys_elev1', 'y2', 'elev2', 'custom_elev2', 'sys_elev2', 'arccat_id',
        'gis_length', 'sector_id', 'macrosector_id', 'state', 'state_type', 'annotation',
        'inverted_slope', 'custom_length', 'expl_id', 'outlet_type', 'offsetval', 'curve_id',
        'cd1', 'cd2', 'flap', 'the_geom', 'p_state'
    ],
    'View ve_inp_outlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_outlet', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_outlet', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_outlet', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_outlet', 'y1', 'numeric(12,3)', 'Column y1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'elev1', 'numeric(12,3)', 'Column elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'custom_elev1', 'numeric(12,3)', 'Column custom_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'sys_elev1', 'numeric(12,3)', 'Column sys_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'y2', 'numeric(12,3)', 'Column y2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'elev2', 'numeric(12,3)', 'Column elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'custom_elev2', 'numeric(12,3)', 'Column custom_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'sys_elev2', 'numeric(12,3)', 'Column sys_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_outlet', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_outlet', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_outlet', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_outlet', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_outlet', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_outlet', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_outlet', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_outlet', 'inverted_slope', 'bool', 'Column inverted_slope should be bool');
SELECT col_type_is('ve_inp_outlet', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_outlet', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_outlet', 'outlet_type', 'varchar(16)', 'Column outlet_type should be varchar(16)');
SELECT col_type_is('ve_inp_outlet', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_outlet', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_outlet', 'cd1', 'numeric(12,4)', 'Column cd1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_outlet', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_outlet', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_outlet', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_outlet', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

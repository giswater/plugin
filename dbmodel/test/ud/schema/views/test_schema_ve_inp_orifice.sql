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

-- Check view ve_inp_orifice
SELECT has_view('ve_inp_orifice'::name, 'View ve_inp_orifice should exist');

-- Check view columns
SELECT columns_are(
    've_inp_orifice',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'y1', 'elev1', 'custom_elev1',
        'sys_elev1', 'y2', 'elev2', 'custom_elev2', 'sys_elev2', 'arccat_id',
        'gis_length', 'sector_id', 'macrosector_id', 'state', 'state_type', 'annotation',
        'inverted_slope', 'custom_length', 'expl_id', 'ori_type', 'offsetval', 'cd',
        'orate', 'flap', 'shape', 'geom1', 'geom2', 'geom3',
        'geom4', 'the_geom', 'p_state'
    ],
    'View ve_inp_orifice should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_orifice', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_orifice', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_orifice', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_orifice', 'y1', 'numeric(12,3)', 'Column y1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'elev1', 'numeric(12,3)', 'Column elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'custom_elev1', 'numeric(12,3)', 'Column custom_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'sys_elev1', 'numeric(12,3)', 'Column sys_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'y2', 'numeric(12,3)', 'Column y2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'elev2', 'numeric(12,3)', 'Column elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'custom_elev2', 'numeric(12,3)', 'Column custom_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'sys_elev2', 'numeric(12,3)', 'Column sys_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_orifice', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_orifice', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_orifice', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_orifice', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_orifice', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_orifice', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_orifice', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_orifice', 'inverted_slope', 'bool', 'Column inverted_slope should be bool');
SELECT col_type_is('ve_inp_orifice', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_orifice', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_orifice', 'ori_type', 'varchar(18)', 'Column ori_type should be varchar(18)');
SELECT col_type_is('ve_inp_orifice', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_orifice', 'cd', 'numeric(12,4)', 'Column cd should be numeric(12,4)');
SELECT col_type_is('ve_inp_orifice', 'orate', 'numeric(12,4)', 'Column orate should be numeric(12,4)');
SELECT col_type_is('ve_inp_orifice', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_orifice', 'shape', 'varchar(18)', 'Column shape should be varchar(18)');
SELECT col_type_is('ve_inp_orifice', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_orifice', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_orifice', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('ve_inp_orifice', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('ve_inp_orifice', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_orifice', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

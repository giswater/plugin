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

-- Check view ve_inp_conduit
SELECT has_view('ve_inp_conduit'::name, 'View ve_inp_conduit should exist');

-- Check view columns
SELECT columns_are(
    've_inp_conduit',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'y1', 'elev1', 'custom_elev1',
        'sys_elev1', 'y2', 'elev2', 'custom_elev2', 'sys_elev2', 'arccat_id',
        'matcat_id', 'cat_shape', 'cat_geom1', 'gis_length', 'sector_id', 'macrosector_id',
        'state', 'state_type', 'annotation', 'inverted_slope', 'custom_length', 'expl_id',
        'barrels', 'culvert', 'kentry', 'kexit', 'kavg', 'flap',
        'q0', 'qmax', 'seepage', 'custom_n', 'the_geom', 'p_state'
    ],
    'View ve_inp_conduit should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_conduit', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_conduit', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_conduit', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_conduit', 'y1', 'numeric(12,3)', 'Column y1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'elev1', 'numeric(12,3)', 'Column elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'custom_elev1', 'numeric(12,3)', 'Column custom_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'sys_elev1', 'numeric(12,3)', 'Column sys_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'y2', 'numeric(12,3)', 'Column y2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'elev2', 'numeric(12,3)', 'Column elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'custom_elev2', 'numeric(12,3)', 'Column custom_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'sys_elev2', 'numeric(12,3)', 'Column sys_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_conduit', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_conduit', 'matcat_id', 'varchar', 'Column matcat_id should be varchar');
SELECT col_type_is('ve_inp_conduit', 'cat_shape', 'varchar(16)', 'Column cat_shape should be varchar(16)');
SELECT col_type_is('ve_inp_conduit', 'cat_geom1', 'numeric(12,4)', 'Column cat_geom1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_conduit', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_conduit', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_conduit', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_conduit', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_conduit', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_conduit', 'inverted_slope', 'bool', 'Column inverted_slope should be bool');
SELECT col_type_is('ve_inp_conduit', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_conduit', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_conduit', 'barrels', 'int2', 'Column barrels should be int2');
SELECT col_type_is('ve_inp_conduit', 'culvert', 'varchar(10)', 'Column culvert should be varchar(10)');
SELECT col_type_is('ve_inp_conduit', 'kentry', 'numeric(12,4)', 'Column kentry should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'kexit', 'numeric(12,4)', 'Column kexit should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'kavg', 'numeric(12,4)', 'Column kavg should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_conduit', 'q0', 'numeric(12,4)', 'Column q0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'qmax', 'numeric(12,4)', 'Column qmax should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'seepage', 'numeric(12,4)', 'Column seepage should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'custom_n', 'numeric(12,4)', 'Column custom_n should be numeric(12,4)');
SELECT col_type_is('ve_inp_conduit', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_conduit', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

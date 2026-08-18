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

-- Check view ve_inp_virtual
SELECT has_view('ve_inp_virtual'::name, 'View ve_inp_virtual should exist');

-- Check view columns
SELECT columns_are(
    've_inp_virtual',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'arccat_id', 'gis_length', 'sector_id',
        'macrosector_id', 'state', 'state_type', 'expl_id', 'fusion_node', 'add_length',
        'the_geom', 'p_state'
    ],
    'View ve_inp_virtual should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_virtual', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_virtual', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_virtual', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_virtual', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_virtual', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_virtual', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_virtual', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_virtual', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_virtual', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_virtual', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_virtual', 'fusion_node', 'int4', 'Column fusion_node should be int4');
SELECT col_type_is('ve_inp_virtual', 'add_length', 'bool', 'Column add_length should be bool');
SELECT col_type_is('ve_inp_virtual', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_virtual', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

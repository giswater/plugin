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

-- Check view ve_inp_pump
SELECT has_view('ve_inp_pump'::name, 'View ve_inp_pump should exist');

-- Check view columns
SELECT columns_are(
    've_inp_pump',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'y1', 'elev1', 'custom_elev1',
        'sys_elev1', 'y2', 'elev2', 'custom_elev2', 'sys_elev2', 'arccat_id',
        'gis_length', 'sector_id', 'macrosector_id', 'state', 'state_type', 'annotation',
        'inverted_slope', 'custom_length', 'expl_id', 'curve_id', 'status', 'startup',
        'shutoff', 'the_geom', 'p_state'
    ],
    'View ve_inp_pump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_pump', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_pump', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_pump', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_pump', 'y1', 'numeric(12,3)', 'Column y1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'elev1', 'numeric(12,3)', 'Column elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'custom_elev1', 'numeric(12,3)', 'Column custom_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'sys_elev1', 'numeric(12,3)', 'Column sys_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'y2', 'numeric(12,3)', 'Column y2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'elev2', 'numeric(12,3)', 'Column elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'custom_elev2', 'numeric(12,3)', 'Column custom_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'sys_elev2', 'numeric(12,3)', 'Column sys_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_inp_pump', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_pump', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_pump', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_pump', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_pump', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_pump', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_pump', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_pump', 'inverted_slope', 'bool', 'Column inverted_slope should be bool');
SELECT col_type_is('ve_inp_pump', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_pump', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_pump', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_pump', 'status', 'varchar(3)', 'Column status should be varchar(3)');
SELECT col_type_is('ve_inp_pump', 'startup', 'numeric(12,4)', 'Column startup should be numeric(12,4)');
SELECT col_type_is('ve_inp_pump', 'shutoff', 'numeric(12,4)', 'Column shutoff should be numeric(12,4)');
SELECT col_type_is('ve_inp_pump', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_pump', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

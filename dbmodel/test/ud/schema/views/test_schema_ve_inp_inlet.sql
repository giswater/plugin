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

-- Check view ve_inp_inlet
SELECT has_view('ve_inp_inlet'::name, 'View ve_inp_inlet should exist');

-- Check view columns
SELECT columns_are(
    've_inp_inlet',
    ARRAY[
        'node_id', 'node_type', 'top_elev', 'ymax', 'elev', 'custom_elev',
        'sys_elev', 'nodecat_id', 'sector_id', 'macrosector_id', 'state', 'state_type',
        'annotation', 'expl_id', 'the_geom', 'depth', 'y0', 'ysur',
        'apond', 'inlet_type', 'outlet_type', 'gully_method', 'custom_top_elev', 'custom_depth',
        'inlet_length', 'inlet_width', 'cd1', 'cd2', 'efficiency', 'p_state'
    ],
    'View ve_inp_inlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_inlet', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_inlet', 'node_type', 'text', 'Column node_type should be text');
SELECT col_type_is('ve_inp_inlet', 'top_elev', 'numeric(12,3)', 'Column top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_inlet', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_inp_inlet', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_inlet', 'custom_elev', 'numeric(12,3)', 'Column custom_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_inlet', 'sys_elev', 'numeric(12,3)', 'Column sys_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_inlet', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_inlet', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_inlet', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_inlet', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_inlet', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_inlet', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_inlet', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_inlet', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_inlet', 'depth', 'numeric', 'Column depth should be numeric');
SELECT col_type_is('ve_inp_inlet', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_inlet', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_inp_inlet', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('ve_inp_inlet', 'inlet_type', 'varchar(30)', 'Column inlet_type should be varchar(30)');
SELECT col_type_is('ve_inp_inlet', 'outlet_type', 'varchar(30)', 'Column outlet_type should be varchar(30)');
SELECT col_type_is('ve_inp_inlet', 'gully_method', 'varchar(30)', 'Column gully_method should be varchar(30)');
SELECT col_type_is('ve_inp_inlet', 'custom_top_elev', 'float8', 'Column custom_top_elev should be float8');
SELECT col_type_is('ve_inp_inlet', 'custom_depth', 'float8', 'Column custom_depth should be float8');
SELECT col_type_is('ve_inp_inlet', 'inlet_length', 'float8', 'Column inlet_length should be float8');
SELECT col_type_is('ve_inp_inlet', 'inlet_width', 'float8', 'Column inlet_width should be float8');
SELECT col_type_is('ve_inp_inlet', 'cd1', 'float8', 'Column cd1 should be float8');
SELECT col_type_is('ve_inp_inlet', 'cd2', 'float8', 'Column cd2 should be float8');
SELECT col_type_is('ve_inp_inlet', 'efficiency', 'float8', 'Column efficiency should be float8');
SELECT col_type_is('ve_inp_inlet', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

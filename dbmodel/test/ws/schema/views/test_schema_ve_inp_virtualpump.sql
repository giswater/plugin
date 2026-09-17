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

-- Check view ve_inp_virtualpump
SELECT has_view('ve_inp_virtualpump'::name, 'View ve_inp_virtualpump should exist');

-- Check view columns
SELECT columns_are(
    've_inp_virtualpump',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'arccat_id', 'sector_id', 'state',
        'state_type', 'annotation', 'expl_id', 'dma_id', 'power', 'curve_id',
        'speed', 'pattern_id', 'status', 'effic_curve_id', 'energy_price', 'energy_pattern_id',
        'pump_type', 'the_geom', 'p_state'
    ],
    'View ve_inp_virtualpump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_virtualpump', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_virtualpump', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_virtualpump', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_virtualpump', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_virtualpump', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_virtualpump', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_virtualpump', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_virtualpump', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_virtualpump', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_virtualpump', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_virtualpump', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('ve_inp_virtualpump', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('ve_inp_virtualpump', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('ve_inp_virtualpump', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('ve_inp_virtualpump', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_virtualpump', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('ve_inp_virtualpump', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('ve_inp_virtualpump', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('ve_inp_virtualpump', 'pump_type', 'varchar(16)', 'Column pump_type should be varchar(16)');
SELECT col_type_is('ve_inp_virtualpump', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_virtualpump', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

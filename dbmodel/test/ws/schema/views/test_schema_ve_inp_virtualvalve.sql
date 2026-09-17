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

-- Check view ve_inp_virtualvalve
SELECT has_view('ve_inp_virtualvalve'::name, 'View ve_inp_virtualvalve should exist');

-- Check view columns
SELECT columns_are(
    've_inp_virtualvalve',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'arccat_id', 'expl_id', 'sector_id',
        'dma_id', 'state', 'state_type', 'custom_length', 'annotation', 'valve_type',
        'setting', 'curve_id', 'minorloss', 'status', 'init_quality', 'the_geom', 'p_state'
    ],
    'View ve_inp_virtualvalve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_virtualvalve', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_virtualvalve', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_virtualvalve', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_virtualvalve', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_virtualvalve', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_virtualvalve', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_virtualvalve', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_virtualvalve', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_virtualvalve', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_virtualvalve', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_virtualvalve', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_virtualvalve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_inp_virtualvalve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_inp_virtualvalve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_virtualvalve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_inp_virtualvalve', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_virtualvalve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_virtualvalve', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_virtualvalve', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

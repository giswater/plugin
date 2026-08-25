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

-- Check view ve_inp_reservoir
SELECT has_view('ve_inp_reservoir'::name, 'View ve_inp_reservoir should exist');

-- Check view columns
SELECT columns_are(
    've_inp_reservoir',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'depth', 'nodecat_id', 'expl_id',
        'sector_id', 'dma_id', 'state', 'state_type', 'annotation', 'pattern_id',
        'head', 'init_quality', 'source_type', 'source_quality', 'source_pattern_id', 'the_geom', 'p_state'
    ],
    'View ve_inp_reservoir should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_reservoir', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_reservoir', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_reservoir', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_reservoir', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_inp_reservoir', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_reservoir', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_reservoir', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_reservoir', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_reservoir', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_reservoir', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_reservoir', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_reservoir', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_reservoir', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_inp_reservoir', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_reservoir', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_inp_reservoir', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_inp_reservoir', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_reservoir', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_reservoir', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

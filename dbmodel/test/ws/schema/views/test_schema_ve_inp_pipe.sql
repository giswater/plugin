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

-- Check view ve_inp_pipe
SELECT has_view('ve_inp_pipe'::name, 'View ve_inp_pipe should exist');

-- Check view columns
SELECT columns_are(
    've_inp_pipe',
    ARRAY[
        'arc_id', 'node_1', 'node_2', 'arccat_id', 'expl_id', 'sector_id',
        'dma_id', 'state', 'state_type', 'custom_length', 'annotation', 'minorloss',
        'status', 'cat_matcat_id', 'builtdate', 'custom_roughness', 'cat_dint', 'custom_dint',
        'bulk_coeff', 'wall_coeff', 'the_geom', 'p_state'
    ],
    'View ve_inp_pipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_pipe', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_pipe', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_inp_pipe', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_inp_pipe', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_pipe', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_pipe', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_pipe', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_pipe', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_pipe', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_pipe', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_pipe', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_pipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_inp_pipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_pipe', 'cat_matcat_id', 'varchar(30)', 'Column cat_matcat_id should be varchar(30)');
SELECT col_type_is('ve_inp_pipe', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_inp_pipe', 'custom_roughness', 'numeric(12,4)', 'Column custom_roughness should be numeric(12,4)');
SELECT col_type_is('ve_inp_pipe', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_inp_pipe', 'custom_dint', 'numeric(12,3)', 'Column custom_dint should be numeric(12,3)');
SELECT col_type_is('ve_inp_pipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_inp_pipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_inp_pipe', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_pipe', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

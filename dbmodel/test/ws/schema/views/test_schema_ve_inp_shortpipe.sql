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

-- Check view ve_inp_shortpipe
SELECT has_view('ve_inp_shortpipe'::name, 'View ve_inp_shortpipe should exist');

-- Check view columns
SELECT columns_are(
    've_inp_shortpipe',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'depth', 'nodecat_id', 'expl_id',
        'sector_id', 'dma_id', 'state', 'state_type', 'annotation', 'nodarc_id',
        'minorloss', 'status', 'bulk_coeff', 'wall_coeff', 'head', 'pattern_id',
        'demand', 'demand_pattern_id', 'emitter_coeff', 'the_geom', 'p_state'
    ],
    'View ve_inp_shortpipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_shortpipe', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_shortpipe', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_shortpipe', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_shortpipe', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_inp_shortpipe', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_shortpipe', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_shortpipe', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_shortpipe', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_shortpipe', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_shortpipe', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_shortpipe', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_shortpipe', 'nodarc_id', 'text', 'Column nodarc_id should be text');
SELECT col_type_is('ve_inp_shortpipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_inp_shortpipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_shortpipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_inp_shortpipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_inp_shortpipe', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_inp_shortpipe', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_shortpipe', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_inp_shortpipe', 'demand_pattern_id', 'varchar(16)', 'Column demand_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_shortpipe', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_inp_shortpipe', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_shortpipe', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

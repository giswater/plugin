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

-- Check view ve_inp_connec
SELECT has_view('ve_inp_connec'::name, 'View ve_inp_connec should exist');

-- Check view columns
SELECT columns_are(
    've_inp_connec',
    ARRAY[
        'connec_id', 'top_elev', 'depth', 'conneccat_id', 'arc_id', 'expl_id',
        'sector_id', 'dma_id', 'state', 'state_type', 'pjoint_type', 'pjoint_id',
        'annotation', 'demand', 'pattern_id', 'peak_factor', 'status', 'minorloss',
        'custom_roughness', 'custom_length', 'custom_dint', 'emitter_coeff', 'init_quality', 'source_type',
        'source_quality', 'source_pattern_id', 'the_geom', 'p_state', 'p_arc_id', 'p_pjoint_id',
        'p_pjoint_type'
    ],
    'View ve_inp_connec should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_connec', 'connec_id', 'int4', 'Column connec_id should be int4');
SELECT col_type_is('ve_inp_connec', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_connec', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_inp_connec', 'conneccat_id', 'varchar(30)', 'Column conneccat_id should be varchar(30)');
SELECT col_type_is('ve_inp_connec', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_connec', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_connec', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_connec', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_connec', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_connec', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_connec', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('ve_inp_connec', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('ve_inp_connec', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_connec', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_inp_connec', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_connec', 'peak_factor', 'numeric(12,4)', 'Column peak_factor should be numeric(12,4)');
SELECT col_type_is('ve_inp_connec', 'status', 'varchar(16)', 'Column status should be varchar(16)');
SELECT col_type_is('ve_inp_connec', 'minorloss', 'float8', 'Column minorloss should be float8');
SELECT col_type_is('ve_inp_connec', 'custom_roughness', 'float8', 'Column custom_roughness should be float8');
SELECT col_type_is('ve_inp_connec', 'custom_length', 'float8', 'Column custom_length should be float8');
SELECT col_type_is('ve_inp_connec', 'custom_dint', 'float8', 'Column custom_dint should be float8');
SELECT col_type_is('ve_inp_connec', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_inp_connec', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_connec', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_inp_connec', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_inp_connec', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_connec', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_connec', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_inp_connec', 'p_arc_id', 'int4', 'Column p_arc_id should be int4');
SELECT col_type_is('ve_inp_connec', 'p_pjoint_id', 'int4', 'Column p_pjoint_id should be int4');
SELECT col_type_is('ve_inp_connec', 'p_pjoint_type', 'varchar(16)', 'Column p_pjoint_type should be varchar(16)');

SELECT * FROM finish();

ROLLBACK;

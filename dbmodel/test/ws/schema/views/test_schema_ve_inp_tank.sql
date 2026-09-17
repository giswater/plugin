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

-- Check view ve_inp_tank
SELECT has_view('ve_inp_tank'::name, 'View ve_inp_tank should exist');

-- Check view columns
SELECT columns_are(
    've_inp_tank',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'depth', 'nodecat_id', 'expl_id',
        'sector_id', 'dma_id', 'state', 'state_type', 'annotation', 'initlevel',
        'minlevel', 'maxlevel', 'diameter', 'minvol', 'curve_id', 'overflow',
        'mixing_model', 'mixing_fraction', 'reaction_coeff', 'init_quality', 'source_type', 'source_quality',
        'source_pattern_id', 'the_geom', 'p_state'
    ],
    'View ve_inp_tank should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_tank', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_tank', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_tank', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_tank', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_tank', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_tank', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_tank', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_tank', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_tank', 'initlevel', 'numeric(12,4)', 'Column initlevel should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'minlevel', 'numeric(12,4)', 'Column minlevel should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'maxlevel', 'numeric(12,4)', 'Column maxlevel should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'diameter', 'numeric(12,4)', 'Column diameter should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'minvol', 'numeric(12,4)', 'Column minvol should be numeric(12,4)');
SELECT col_type_is('ve_inp_tank', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_tank', 'overflow', 'varchar(3)', 'Column overflow should be varchar(3)');
SELECT col_type_is('ve_inp_tank', 'mixing_model', 'varchar(18)', 'Column mixing_model should be varchar(18)');
SELECT col_type_is('ve_inp_tank', 'mixing_fraction', 'float8', 'Column mixing_fraction should be float8');
SELECT col_type_is('ve_inp_tank', 'reaction_coeff', 'float8', 'Column reaction_coeff should be float8');
SELECT col_type_is('ve_inp_tank', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_tank', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_inp_tank', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_inp_tank', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_tank', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_tank', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

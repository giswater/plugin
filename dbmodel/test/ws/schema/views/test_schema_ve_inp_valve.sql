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

-- Check view ve_inp_valve
SELECT has_view('ve_inp_valve'::name, 'View ve_inp_valve should exist');

-- Check view columns
SELECT columns_are(
    've_inp_valve',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'depth', 'nodecat_id', 'expl_id',
        'sector_id', 'dma_id', 'state', 'state_type', 'annotation', 'nodarc_id',
        'valve_type', 'setting', 'curve_id', 'minorloss', 'to_arc', 'status',
        'cat_dint', 'custom_dint', 'add_settings', 'init_quality', 'head', 'pattern_id',
        'demand', 'demand_pattern_id', 'emitter_coeff', 'the_geom', 'p_state'
    ],
    'View ve_inp_valve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_valve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_valve', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_valve', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_valve', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_inp_valve', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_valve', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_valve', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_valve', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_valve', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_valve', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_valve', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_valve', 'nodarc_id', 'text', 'Column nodarc_id should be text');
SELECT col_type_is('ve_inp_valve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_inp_valve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_inp_valve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_valve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_inp_valve', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_valve', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_valve', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_inp_valve', 'custom_dint', 'numeric(12,4)', 'Column custom_dint should be numeric(12,4)');
SELECT col_type_is('ve_inp_valve', 'add_settings', 'float8', 'Column add_settings should be float8');
SELECT col_type_is('ve_inp_valve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_inp_valve', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_inp_valve', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_valve', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_inp_valve', 'demand_pattern_id', 'varchar(16)', 'Column demand_pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_valve', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_inp_valve', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_valve', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_inp_gully
SELECT has_view('ve_inp_gully'::name, 'View ve_inp_gully should exist');

-- Check view columns
SELECT columns_are(
    've_inp_gully',
    ARRAY[
        'gully_id', 'code', 'top_elev', 'gully_type', 'gullycat_id', 'grate_width',
        'grate_length', 'arc_id', 'sector_id', 'expl_id', 'state', 'state_type',
        'the_geom', 'units', 'units_placement', 'groove', 'groove_height', 'groove_length',
        'pjoint_id', 'pjoint_type', 'total_width', 'total_length', 'depth', 'annotation',
        'outlet_type', 'custom_top_elev', 'custom_width', 'custom_length', 'custom_depth', 'gully_method',
        'weir_cd', 'orifice_cd', 'custom_a_param', 'custom_b_param', 'efficiency',
        'p_state', 'p_arc_id', 'p_pjoint_id', 'p_pjoint_type'
    ],
    'View ve_inp_gully should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_gully', 'gully_id', 'int4', 'Column gully_id should be int4');
SELECT col_type_is('ve_inp_gully', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_inp_gully', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_gully', 'gully_type', 'varchar(30)', 'Column gully_type should be varchar(30)');
SELECT col_type_is('ve_inp_gully', 'gullycat_id', 'varchar(30)', 'Column gullycat_id should be varchar(30)');
SELECT col_type_is('ve_inp_gully', 'grate_width', 'numeric(12,2)', 'Column grate_width should be numeric(12,2)');
SELECT col_type_is('ve_inp_gully', 'grate_length', 'numeric(12,2)', 'Column grate_length should be numeric(12,2)');
SELECT col_type_is('ve_inp_gully', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_gully', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_gully', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_gully', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_gully', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_gully', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_gully', 'units', 'numeric(12,2)', 'Column units should be numeric(12,2)');
SELECT col_type_is('ve_inp_gully', 'units_placement', 'varchar(16)', 'Column units_placement should be varchar(16)');
SELECT col_type_is('ve_inp_gully', 'groove', 'bool', 'Column groove should be bool');
SELECT col_type_is('ve_inp_gully', 'groove_height', 'float8', 'Column groove_height should be float8');
SELECT col_type_is('ve_inp_gully', 'groove_length', 'float8', 'Column groove_length should be float8');
SELECT col_type_is('ve_inp_gully', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('ve_inp_gully', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('ve_inp_gully', 'total_width', 'numeric(12,3)', 'Column total_width should be numeric(12,3)');
SELECT col_type_is('ve_inp_gully', 'total_length', 'numeric(12,3)', 'Column total_length should be numeric(12,3)');
SELECT col_type_is('ve_inp_gully', 'depth', 'numeric', 'Column depth should be numeric');
SELECT col_type_is('ve_inp_gully', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_gully', 'outlet_type', 'varchar(30)', 'Column outlet_type should be varchar(30)');
SELECT col_type_is('ve_inp_gully', 'custom_top_elev', 'float8', 'Column custom_top_elev should be float8');
SELECT col_type_is('ve_inp_gully', 'custom_width', 'float8', 'Column custom_width should be float8');
SELECT col_type_is('ve_inp_gully', 'custom_length', 'float8', 'Column custom_length should be float8');
SELECT col_type_is('ve_inp_gully', 'custom_depth', 'float8', 'Column custom_depth should be float8');
SELECT col_type_is('ve_inp_gully', 'gully_method', 'varchar(30)', 'Column gully_method should be varchar(30)');
SELECT col_type_is('ve_inp_gully', 'weir_cd', 'float8', 'Column weir_cd should be float8');
SELECT col_type_is('ve_inp_gully', 'orifice_cd', 'float8', 'Column orifice_cd should be float8');
SELECT col_type_is('ve_inp_gully', 'custom_a_param', 'float8', 'Column custom_a_param should be float8');
SELECT col_type_is('ve_inp_gully', 'custom_b_param', 'float8', 'Column custom_b_param should be float8');
SELECT col_type_is('ve_inp_gully', 'efficiency', 'float8', 'Column efficiency should be float8');
SELECT col_type_is('ve_inp_gully', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_inp_gully', 'p_arc_id', 'int4', 'Column p_arc_id should be int4');
SELECT col_type_is('ve_inp_gully', 'p_pjoint_id', 'int4', 'Column p_pjoint_id should be int4');
SELECT col_type_is('ve_inp_gully', 'p_pjoint_type', 'varchar(16)', 'Column p_pjoint_type should be varchar(16)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_inp_netgully
SELECT has_view('ve_inp_netgully'::name, 'View ve_inp_netgully should exist');

-- Check view columns
SELECT columns_are(
    've_inp_netgully',
    ARRAY[
        'node_id', 'code', 'top_elev', 'custom_top_elev', 'ymax', 'elev',
        'custom_elev', 'sys_elev', 'node_type', 'nodecat_id', 'gullycat_id', 'grate_width',
        'grate_length', 'sector_id', 'macrosector_id', 'expl_id', 'state', 'state_type',
        'the_geom', 'units', 'units_placement', 'groove', 'groove_height', 'groove_length',
        'total_width', 'total_length', 'depth', 'annotation', 'y0', 'ysur',
        'apond', 'outlet_type', 'custom_width', 'custom_length', 'custom_depth', 'gully_method',
        'weir_cd', 'orifice_cd', 'custom_a_param', 'custom_b_param', 'efficiency', 'p_state'
    ],
    'View ve_inp_netgully should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_netgully', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_netgully', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_inp_netgully', 'top_elev', 'numeric(12,3)', 'Column top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'custom_top_elev', 'numeric(12,3)', 'Column custom_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'custom_elev', 'numeric(12,3)', 'Column custom_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'sys_elev', 'numeric(12,3)', 'Column sys_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'node_type', 'text', 'Column node_type should be text');
SELECT col_type_is('ve_inp_netgully', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_netgully', 'gullycat_id', 'varchar(18)', 'Column gullycat_id should be varchar(18)');
SELECT col_type_is('ve_inp_netgully', 'grate_width', 'numeric(12,3)', 'Column grate_width should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'grate_length', 'numeric(12,3)', 'Column grate_length should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_netgully', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_netgully', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_netgully', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_netgully', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_netgully', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_netgully', 'units', 'int2', 'Column units should be int2');
SELECT col_type_is('ve_inp_netgully', 'units_placement', 'varchar(16)', 'Column units_placement should be varchar(16)');
SELECT col_type_is('ve_inp_netgully', 'groove', 'bool', 'Column groove should be bool');
SELECT col_type_is('ve_inp_netgully', 'groove_height', 'float8', 'Column groove_height should be float8');
SELECT col_type_is('ve_inp_netgully', 'groove_length', 'float8', 'Column groove_length should be float8');
SELECT col_type_is('ve_inp_netgully', 'total_width', 'numeric(12,3)', 'Column total_width should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'total_length', 'numeric(12,3)', 'Column total_length should be numeric(12,3)');
SELECT col_type_is('ve_inp_netgully', 'depth', 'numeric', 'Column depth should be numeric');
SELECT col_type_is('ve_inp_netgully', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_netgully', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_netgully', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_inp_netgully', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('ve_inp_netgully', 'outlet_type', 'varchar(30)', 'Column outlet_type should be varchar(30)');
SELECT col_type_is('ve_inp_netgully', 'custom_width', 'float8', 'Column custom_width should be float8');
SELECT col_type_is('ve_inp_netgully', 'custom_length', 'float8', 'Column custom_length should be float8');
SELECT col_type_is('ve_inp_netgully', 'custom_depth', 'float8', 'Column custom_depth should be float8');
SELECT col_type_is('ve_inp_netgully', 'gully_method', 'varchar(30)', 'Column gully_method should be varchar(30)');
SELECT col_type_is('ve_inp_netgully', 'weir_cd', 'float8', 'Column weir_cd should be float8');
SELECT col_type_is('ve_inp_netgully', 'orifice_cd', 'float8', 'Column orifice_cd should be float8');
SELECT col_type_is('ve_inp_netgully', 'custom_a_param', 'float8', 'Column custom_a_param should be float8');
SELECT col_type_is('ve_inp_netgully', 'custom_b_param', 'float8', 'Column custom_b_param should be float8');
SELECT col_type_is('ve_inp_netgully', 'efficiency', 'float8', 'Column efficiency should be float8');
SELECT col_type_is('ve_inp_netgully', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

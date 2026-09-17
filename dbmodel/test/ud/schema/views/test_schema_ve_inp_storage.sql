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

-- Check view ve_inp_storage
SELECT has_view('ve_inp_storage'::name, 'View ve_inp_storage should exist');

-- Check view columns
SELECT columns_are(
    've_inp_storage',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'ymax', 'elev', 'custom_elev',
        'sys_elev', 'nodecat_id', 'sector_id', 'macrosector_id', 'state', 'state_type',
        'annotation', 'expl_id', 'storage_type', 'curve_id', 'a1', 'a2',
        'a0', 'fevap', 'sh', 'hc', 'imd', 'y0',
        'ysur', 'the_geom', 'p_state'
    ],
    'View ve_inp_storage should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_storage', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_storage', 'top_elev', 'numeric(12,3)', 'Column top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_storage', 'custom_top_elev', 'numeric(12,3)', 'Column custom_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_storage', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_inp_storage', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_storage', 'custom_elev', 'numeric(12,3)', 'Column custom_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_storage', 'sys_elev', 'numeric(12,3)', 'Column sys_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_storage', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_storage', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_storage', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_storage', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_storage', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_storage', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_storage', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_storage', 'storage_type', 'varchar(18)', 'Column storage_type should be varchar(18)');
SELECT col_type_is('ve_inp_storage', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_storage', 'a1', 'numeric(12,4)', 'Column a1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'a2', 'numeric(12,4)', 'Column a2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'a0', 'numeric(12,4)', 'Column a0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'fevap', 'numeric(12,4)', 'Column fevap should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'sh', 'numeric(12,4)', 'Column sh should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'hc', 'numeric(12,4)', 'Column hc should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'imd', 'numeric(12,4)', 'Column imd should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_inp_storage', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_storage', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

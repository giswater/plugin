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

-- Check view ve_inp_outfall
SELECT has_view('ve_inp_outfall'::name, 'View ve_inp_outfall should exist');

-- Check view columns
SELECT columns_are(
    've_inp_outfall',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'ymax', 'elev', 'custom_elev',
        'sys_elev', 'nodecat_id', 'sector_id', 'macrosector_id', 'state', 'state_type',
        'annotation', 'expl_id', 'outfall_type', 'stage', 'curve_id', 'timser_id',
        'gate', 'route_to', 'the_geom', 'p_state'
    ],
    'View ve_inp_outfall should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_outfall', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_outfall', 'top_elev', 'numeric(12,3)', 'Column top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_outfall', 'custom_top_elev', 'numeric(12,3)', 'Column custom_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_outfall', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_inp_outfall', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_outfall', 'custom_elev', 'numeric(12,3)', 'Column custom_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_outfall', 'sys_elev', 'numeric(12,3)', 'Column sys_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_outfall', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_outfall', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_outfall', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_outfall', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_outfall', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_outfall', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_outfall', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_outfall', 'outfall_type', 'varchar(16)', 'Column outfall_type should be varchar(16)');
SELECT col_type_is('ve_inp_outfall', 'stage', 'numeric(12,4)', 'Column stage should be numeric(12,4)');
SELECT col_type_is('ve_inp_outfall', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_outfall', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('ve_inp_outfall', 'gate', 'varchar(3)', 'Column gate should be varchar(3)');
SELECT col_type_is('ve_inp_outfall', 'route_to', 'varchar(16)', 'Column route_to should be varchar(16)');
SELECT col_type_is('ve_inp_outfall', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_outfall', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

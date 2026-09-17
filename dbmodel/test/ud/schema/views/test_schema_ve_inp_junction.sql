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

-- Check view ve_inp_junction
SELECT has_view('ve_inp_junction'::name, 'View ve_inp_junction should exist');

-- Check view columns
SELECT columns_are(
    've_inp_junction',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'ymax', 'elev', 'custom_elev',
        'sys_elev', 'nodecat_id', 'sector_id', 'macrosector_id', 'state', 'state_type',
        'annotation', 'expl_id', 'y0', 'ysur', 'apond', 'outfallparam',
        'the_geom', 'p_state'
    ],
    'View ve_inp_junction should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_junction', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_junction', 'top_elev', 'numeric(12,3)', 'Column top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_junction', 'custom_top_elev', 'numeric(12,3)', 'Column custom_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_junction', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_inp_junction', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_junction', 'custom_elev', 'numeric(12,3)', 'Column custom_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_junction', 'sys_elev', 'numeric(12,3)', 'Column sys_elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_junction', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_junction', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_junction', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_inp_junction', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_junction', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_junction', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_junction', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_junction', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_junction', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_inp_junction', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('ve_inp_junction', 'outfallparam', 'text', 'Column outfallparam should be text');
SELECT col_type_is('ve_inp_junction', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_junction', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

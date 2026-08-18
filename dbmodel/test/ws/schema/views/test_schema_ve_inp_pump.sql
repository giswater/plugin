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

-- Check view ve_inp_pump
SELECT has_view('ve_inp_pump'::name, 'View ve_inp_pump should exist');

-- Check view columns
SELECT columns_are(
    've_inp_pump',
    ARRAY[
        'node_id', 'top_elev', 'custom_top_elev', 'depth', 'nodecat_id', 'expl_id',
        'sector_id', 'dma_id', 'state', 'state_type', 'annotation', 'nodarc_id',
        'power', 'curve_id', 'speed', 'pattern_id', 'to_arc', 'status',
        'pump_type', 'effic_curve_id', 'energy_price', 'energy_pattern_id', 'the_geom', 'p_state'
    ],
    'View ve_inp_pump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_pump', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_pump', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_pump', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_inp_pump', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_inp_pump', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_inp_pump', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_pump', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_pump', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_pump', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_inp_pump', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_inp_pump', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_inp_pump', 'nodarc_id', 'text', 'Column nodarc_id should be text');
SELECT col_type_is('ve_inp_pump', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('ve_inp_pump', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('ve_inp_pump', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('ve_inp_pump', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('ve_inp_pump', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_pump', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_pump', 'pump_type', 'varchar(16)', 'Column pump_type should be varchar(16)');
SELECT col_type_is('ve_inp_pump', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('ve_inp_pump', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('ve_inp_pump', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('ve_inp_pump', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_pump', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

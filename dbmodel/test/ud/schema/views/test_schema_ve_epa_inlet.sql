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

-- Check view ve_epa_inlet
SELECT has_view('ve_epa_inlet'::name, 'View ve_epa_inlet should exist');
SELECT has_trigger('ve_epa_inlet', 'gw_trg_edit_ve_epa_inlet',
    'View ve_epa_inlet should have gw_trg_edit_ve_epa_inlet');

-- Check view columns
SELECT columns_are(
    've_epa_inlet',
    ARRAY[
        'node_id', 'y0', 'ysur', 'apond', 'inlet_type', 'outlet_type',
        'gully_method', 'custom_top_elev', 'custom_depth', 'inlet_length', 'inlet_width', 'cd1',
        'cd2', 'efficiency', 'depth_average', 'depth_max', 'depth_max_day', 'depth_max_hour',
        'surcharge_hour', 'surgarge_max_height', 'flood_hour', 'flood_max_rate', 'time_day', 'time_hour',
        'flood_total', 'flood_max_ponded'
    ],
    'View ve_epa_inlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_inlet', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_inlet', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'inlet_type', 'varchar(30)', 'Column inlet_type should be varchar(30)');
SELECT col_type_is('ve_epa_inlet', 'outlet_type', 'varchar(30)', 'Column outlet_type should be varchar(30)');
SELECT col_type_is('ve_epa_inlet', 'gully_method', 'varchar(30)', 'Column gully_method should be varchar(30)');
SELECT col_type_is('ve_epa_inlet', 'custom_top_elev', 'float8', 'Column custom_top_elev should be float8');
SELECT col_type_is('ve_epa_inlet', 'custom_depth', 'float8', 'Column custom_depth should be float8');
SELECT col_type_is('ve_epa_inlet', 'inlet_length', 'float8', 'Column inlet_length should be float8');
SELECT col_type_is('ve_epa_inlet', 'inlet_width', 'float8', 'Column inlet_width should be float8');
SELECT col_type_is('ve_epa_inlet', 'cd1', 'float8', 'Column cd1 should be float8');
SELECT col_type_is('ve_epa_inlet', 'cd2', 'float8', 'Column cd2 should be float8');
SELECT col_type_is('ve_epa_inlet', 'efficiency', 'float8', 'Column efficiency should be float8');
SELECT col_type_is('ve_epa_inlet', 'depth_average', 'numeric(12,4)', 'Column depth_average should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'depth_max', 'numeric(12,4)', 'Column depth_max should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'depth_max_day', 'varchar(10)', 'Column depth_max_day should be varchar(10)');
SELECT col_type_is('ve_epa_inlet', 'depth_max_hour', 'varchar(10)', 'Column depth_max_hour should be varchar(10)');
SELECT col_type_is('ve_epa_inlet', 'surcharge_hour', 'numeric(12,4)', 'Column surcharge_hour should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'surgarge_max_height', 'numeric(12,4)', 'Column surgarge_max_height should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'flood_hour', 'numeric(12,4)', 'Column flood_hour should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'flood_max_rate', 'numeric(12,4)', 'Column flood_max_rate should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'time_day', 'varchar(10)', 'Column time_day should be varchar(10)');
SELECT col_type_is('ve_epa_inlet', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_inlet', 'flood_total', 'numeric(12,4)', 'Column flood_total should be numeric(12,4)');
SELECT col_type_is('ve_epa_inlet', 'flood_max_ponded', 'numeric(12,4)', 'Column flood_max_ponded should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

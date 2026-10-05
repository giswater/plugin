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

-- Check view ve_epa_netgully
SELECT has_view('ve_epa_netgully'::name, 'View ve_epa_netgully should exist');
SELECT has_trigger('ve_epa_netgully', 'gw_trg_edit_ve_epa_netgully',
    'View ve_epa_netgully should have gw_trg_edit_ve_epa_netgully');

-- Check view columns
SELECT columns_are(
    've_epa_netgully',
    ARRAY[
        'node_id', 'y0', 'ysur', 'apond', 'outlet_type', 'custom_width',
        'custom_length', 'custom_depth', 'gully_method', 'weir_cd', 'orifice_cd', 'custom_a_param',
        'custom_b_param', 'efficiency', 'depth_average', 'depth_max', 'depth_max_day', 'depth_max_hour',
        'surcharge_hour', 'surgarge_max_height', 'flood_hour', 'flood_max_rate', 'time_day', 'time_hour',
        'flood_total', 'flood_max_ponded'
    ],
    'View ve_epa_netgully should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_netgully', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_netgully', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'outlet_type', 'varchar(30)', 'Column outlet_type should be varchar(30)');
SELECT col_type_is('ve_epa_netgully', 'custom_width', 'float8', 'Column custom_width should be float8');
SELECT col_type_is('ve_epa_netgully', 'custom_length', 'float8', 'Column custom_length should be float8');
SELECT col_type_is('ve_epa_netgully', 'custom_depth', 'float8', 'Column custom_depth should be float8');
SELECT col_type_is('ve_epa_netgully', 'gully_method', 'varchar(30)', 'Column gully_method should be varchar(30)');
SELECT col_type_is('ve_epa_netgully', 'weir_cd', 'float8', 'Column weir_cd should be float8');
SELECT col_type_is('ve_epa_netgully', 'orifice_cd', 'float8', 'Column orifice_cd should be float8');
SELECT col_type_is('ve_epa_netgully', 'custom_a_param', 'float8', 'Column custom_a_param should be float8');
SELECT col_type_is('ve_epa_netgully', 'custom_b_param', 'float8', 'Column custom_b_param should be float8');
SELECT col_type_is('ve_epa_netgully', 'efficiency', 'float8', 'Column efficiency should be float8');
SELECT col_type_is('ve_epa_netgully', 'depth_average', 'numeric(12,4)', 'Column depth_average should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'depth_max', 'numeric(12,4)', 'Column depth_max should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'depth_max_day', 'varchar(10)', 'Column depth_max_day should be varchar(10)');
SELECT col_type_is('ve_epa_netgully', 'depth_max_hour', 'varchar(10)', 'Column depth_max_hour should be varchar(10)');
SELECT col_type_is('ve_epa_netgully', 'surcharge_hour', 'numeric(12,4)', 'Column surcharge_hour should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'surgarge_max_height', 'numeric(12,4)', 'Column surgarge_max_height should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'flood_hour', 'numeric(12,4)', 'Column flood_hour should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'flood_max_rate', 'numeric(12,4)', 'Column flood_max_rate should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'time_day', 'varchar(10)', 'Column time_day should be varchar(10)');
SELECT col_type_is('ve_epa_netgully', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_netgully', 'flood_total', 'numeric(12,4)', 'Column flood_total should be numeric(12,4)');
SELECT col_type_is('ve_epa_netgully', 'flood_max_ponded', 'numeric(12,4)', 'Column flood_max_ponded should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

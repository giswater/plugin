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

-- Check view ve_epa_junction
SELECT has_view('ve_epa_junction'::name, 'View ve_epa_junction should exist');
SELECT has_trigger('ve_epa_junction', 'gw_trg_edit_ve_epa_junction',
    'View ve_epa_junction should have gw_trg_edit_ve_epa_junction');

-- Check view columns
SELECT columns_are(
    've_epa_junction',
    ARRAY[
        'node_id', 'y0', 'ysur', 'apond', 'outfallparam', 'depth_average',
        'depth_max', 'depth_max_day', 'depth_max_hour', 'surcharge_hour', 'surgarge_max_height', 'flood_hour',
        'flood_max_rate', 'time_day', 'time_hour', 'flood_total', 'flood_max_ponded'
    ],
    'View ve_epa_junction should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_junction', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_junction', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'outfallparam', 'json', 'Column outfallparam should be json');
SELECT col_type_is('ve_epa_junction', 'depth_average', 'numeric(12,4)', 'Column depth_average should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'depth_max', 'numeric(12,4)', 'Column depth_max should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'depth_max_day', 'varchar(10)', 'Column depth_max_day should be varchar(10)');
SELECT col_type_is('ve_epa_junction', 'depth_max_hour', 'varchar(10)', 'Column depth_max_hour should be varchar(10)');
SELECT col_type_is('ve_epa_junction', 'surcharge_hour', 'numeric(12,4)', 'Column surcharge_hour should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'surgarge_max_height', 'numeric(12,4)', 'Column surgarge_max_height should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'flood_hour', 'numeric(12,4)', 'Column flood_hour should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'flood_max_rate', 'numeric(12,4)', 'Column flood_max_rate should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'time_day', 'varchar(10)', 'Column time_day should be varchar(10)');
SELECT col_type_is('ve_epa_junction', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_junction', 'flood_total', 'numeric(12,4)', 'Column flood_total should be numeric(12,4)');
SELECT col_type_is('ve_epa_junction', 'flood_max_ponded', 'numeric(12,4)', 'Column flood_max_ponded should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_storage
SELECT has_view('ve_epa_storage'::name, 'View ve_epa_storage should exist');
SELECT has_trigger('ve_epa_storage', 'gw_trg_edit_ve_epa_storage',
    'View ve_epa_storage should have gw_trg_edit_ve_epa_storage');

-- Check view columns
SELECT columns_are(
    've_epa_storage',
    ARRAY[
        'node_id', 'storage_type', 'curve_id', 'a1', 'a2', 'a0',
        'fevap', 'sh', 'hc', 'imd', 'y0', 'ysur',
        'aver_vol', 'avg_full', 'ei_loss', 'max_vol', 'max_full', 'time_days',
        'time_hour', 'max_out'
    ],
    'View ve_epa_storage should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_storage', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_storage', 'storage_type', 'varchar(18)', 'Column storage_type should be varchar(18)');
SELECT col_type_is('ve_epa_storage', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_storage', 'a1', 'numeric(12,4)', 'Column a1 should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'a2', 'numeric(12,4)', 'Column a2 should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'a0', 'numeric(12,4)', 'Column a0 should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'fevap', 'numeric(12,4)', 'Column fevap should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'sh', 'numeric(12,4)', 'Column sh should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'hc', 'numeric(12,4)', 'Column hc should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'imd', 'numeric(12,4)', 'Column imd should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'aver_vol', 'numeric(12,4)', 'Column aver_vol should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'avg_full', 'numeric(12,4)', 'Column avg_full should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'ei_loss', 'numeric(12,4)', 'Column ei_loss should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'max_vol', 'numeric(12,4)', 'Column max_vol should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'max_full', 'numeric(12,4)', 'Column max_full should be numeric(12,4)');
SELECT col_type_is('ve_epa_storage', 'time_days', 'varchar(10)', 'Column time_days should be varchar(10)');
SELECT col_type_is('ve_epa_storage', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_storage', 'max_out', 'numeric(12,4)', 'Column max_out should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_outlet
SELECT has_view('ve_epa_outlet'::name, 'View ve_epa_outlet should exist');
SELECT has_trigger('ve_epa_outlet', 'gw_trg_edit_ve_epa_outlet',
    'View ve_epa_outlet should have gw_trg_edit_ve_epa_outlet');

-- Check view columns
SELECT columns_are(
    've_epa_outlet',
    ARRAY[
        'arc_id', 'outlet_type', 'offsetval', 'curve_id', 'cd1', 'cd2',
        'flap', 'max_flow', 'time_days', 'time_hour', 'max_veloc', 'mfull_flow',
        'mfull_dept', 'max_shear', 'max_hr', 'max_slope', 'day_max', 'time_max',
        'min_shear', 'day_min', 'time_min'
    ],
    'View ve_epa_outlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_outlet', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_epa_outlet', 'outlet_type', 'varchar(16)', 'Column outlet_type should be varchar(16)');
SELECT col_type_is('ve_epa_outlet', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_outlet', 'cd1', 'numeric(12,4)', 'Column cd1 should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_epa_outlet', 'max_flow', 'numeric(12,4)', 'Column max_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'time_days', 'varchar(10)', 'Column time_days should be varchar(10)');
SELECT col_type_is('ve_epa_outlet', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_outlet', 'max_veloc', 'numeric(12,4)', 'Column max_veloc should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'mfull_flow', 'numeric(12,4)', 'Column mfull_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'mfull_dept', 'numeric(12,4)', 'Column mfull_dept should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'max_shear', 'numeric(12,4)', 'Column max_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'max_hr', 'numeric(12,4)', 'Column max_hr should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'max_slope', 'numeric(12,4)', 'Column max_slope should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'day_max', 'varchar(10)', 'Column day_max should be varchar(10)');
SELECT col_type_is('ve_epa_outlet', 'time_max', 'varchar(10)', 'Column time_max should be varchar(10)');
SELECT col_type_is('ve_epa_outlet', 'min_shear', 'numeric(12,4)', 'Column min_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_outlet', 'day_min', 'varchar(10)', 'Column day_min should be varchar(10)');
SELECT col_type_is('ve_epa_outlet', 'time_min', 'varchar(10)', 'Column time_min should be varchar(10)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_pump
SELECT has_view('ve_epa_pump'::name, 'View ve_epa_pump should exist');
SELECT has_trigger('ve_epa_pump', 'gw_trg_edit_ve_epa_pump',
    'View ve_epa_pump should have gw_trg_edit_ve_epa_pump');

-- Check view columns
SELECT columns_are(
    've_epa_pump',
    ARRAY[
        'arc_id', 'curve_id', 'status', 'startup', 'shutoff', 'percent',
        'num_startup', 'min_flow', 'avg_flow', 'max_flow', 'vol_ltr', 'powus_kwh',
        'timoff_min', 'timoff_max'
    ],
    'View ve_epa_pump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_pump', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_epa_pump', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_pump', 'status', 'varchar(3)', 'Column status should be varchar(3)');
SELECT col_type_is('ve_epa_pump', 'startup', 'numeric(12,4)', 'Column startup should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'shutoff', 'numeric(12,4)', 'Column shutoff should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'percent', 'numeric(12,4)', 'Column percent should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'num_startup', 'int4', 'Column num_startup should be int4');
SELECT col_type_is('ve_epa_pump', 'min_flow', 'numeric(12,4)', 'Column min_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'avg_flow', 'numeric(12,4)', 'Column avg_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'max_flow', 'numeric(12,4)', 'Column max_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'vol_ltr', 'numeric(12,4)', 'Column vol_ltr should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'powus_kwh', 'numeric(12,4)', 'Column powus_kwh should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'timoff_min', 'numeric(12,4)', 'Column timoff_min should be numeric(12,4)');
SELECT col_type_is('ve_epa_pump', 'timoff_max', 'numeric(12,4)', 'Column timoff_max should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_frpump
SELECT has_view('ve_epa_frpump'::name, 'View ve_epa_frpump should exist');
SELECT has_trigger('ve_epa_frpump', 'gw_trg_edit_ve_epa_frpump',
    'View ve_epa_frpump should have gw_trg_edit_ve_epa_frpump');

-- Check view columns
SELECT columns_are(
    've_epa_frpump',
    ARRAY[
        'element_id', 'node_id', 'curve_id', 'status', 'startup', 'shutoff',
        'percent', 'num_startup', 'min_flow', 'avg_flow', 'max_flow', 'vol_ltr',
        'powus_kwh', 'timoff_min', 'timoff_max'
    ],
    'View ve_epa_frpump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_frpump', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_epa_frpump', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_frpump', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_frpump', 'status', 'varchar(3)', 'Column status should be varchar(3)');
SELECT col_type_is('ve_epa_frpump', 'startup', 'numeric(12,4)', 'Column startup should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'shutoff', 'numeric(12,4)', 'Column shutoff should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'percent', 'numeric(12,4)', 'Column percent should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'num_startup', 'int4', 'Column num_startup should be int4');
SELECT col_type_is('ve_epa_frpump', 'min_flow', 'numeric(12,4)', 'Column min_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'avg_flow', 'numeric(12,4)', 'Column avg_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'max_flow', 'numeric(12,4)', 'Column max_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'vol_ltr', 'numeric(12,4)', 'Column vol_ltr should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'powus_kwh', 'numeric(12,4)', 'Column powus_kwh should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'timoff_min', 'numeric(12,4)', 'Column timoff_min should be numeric(12,4)');
SELECT col_type_is('ve_epa_frpump', 'timoff_max', 'numeric(12,4)', 'Column timoff_max should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_outfall
SELECT has_view('ve_epa_outfall'::name, 'View ve_epa_outfall should exist');
SELECT has_trigger('ve_epa_outfall', 'gw_trg_edit_ve_epa_outfall',
    'View ve_epa_outfall should have gw_trg_edit_ve_epa_outfall');

-- Check view columns
SELECT columns_are(
    've_epa_outfall',
    ARRAY[
        'node_id', 'outfall_type', 'stage', 'curve_id', 'timser_id', 'gate',
        'flow_freq', 'avg_flow', 'max_flow', 'total_vol'
    ],
    'View ve_epa_outfall should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_outfall', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_outfall', 'outfall_type', 'varchar(16)', 'Column outfall_type should be varchar(16)');
SELECT col_type_is('ve_epa_outfall', 'stage', 'numeric(12,4)', 'Column stage should be numeric(12,4)');
SELECT col_type_is('ve_epa_outfall', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_outfall', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('ve_epa_outfall', 'gate', 'varchar(3)', 'Column gate should be varchar(3)');
SELECT col_type_is('ve_epa_outfall', 'flow_freq', 'numeric(12,4)', 'Column flow_freq should be numeric(12,4)');
SELECT col_type_is('ve_epa_outfall', 'avg_flow', 'numeric(12,4)', 'Column avg_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_outfall', 'max_flow', 'numeric(12,4)', 'Column max_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_outfall', 'total_vol', 'numeric(12,4)', 'Column total_vol should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

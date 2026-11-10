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

-- Check view ve_epa_pgully
SELECT has_view('ve_epa_pgully'::name, 'View ve_epa_pgully should exist');
SELECT has_trigger('ve_epa_pgully', 'gw_trg_edit_ve_epa_pgully',
    'View ve_epa_pgully should have gw_trg_edit_ve_epa_pgully');

-- Check view columns
SELECT columns_are(
    've_epa_pgully',
    ARRAY[
        'gully_id', 'outlet_type', 'custom_top_elev', 'custom_width', 'custom_length', 'custom_depth',
        'gully_method', 'weir_cd', 'orifice_cd', 'custom_a_param', 'custom_b_param', 'efficiency'
    ],
    'View ve_epa_pgully should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_pgully', 'gully_id', 'int4', 'Column gully_id should be int4');
SELECT col_type_is('ve_epa_pgully', 'outlet_type', 'varchar(30)', 'Column outlet_type should be varchar(30)');
SELECT col_type_is('ve_epa_pgully', 'custom_top_elev', 'float8', 'Column custom_top_elev should be float8');
SELECT col_type_is('ve_epa_pgully', 'custom_width', 'float8', 'Column custom_width should be float8');
SELECT col_type_is('ve_epa_pgully', 'custom_length', 'float8', 'Column custom_length should be float8');
SELECT col_type_is('ve_epa_pgully', 'custom_depth', 'float8', 'Column custom_depth should be float8');
SELECT col_type_is('ve_epa_pgully', 'gully_method', 'varchar(30)', 'Column gully_method should be varchar(30)');
SELECT col_type_is('ve_epa_pgully', 'weir_cd', 'float8', 'Column weir_cd should be float8');
SELECT col_type_is('ve_epa_pgully', 'orifice_cd', 'float8', 'Column orifice_cd should be float8');
SELECT col_type_is('ve_epa_pgully', 'custom_a_param', 'float8', 'Column custom_a_param should be float8');
SELECT col_type_is('ve_epa_pgully', 'custom_b_param', 'float8', 'Column custom_b_param should be float8');
SELECT col_type_is('ve_epa_pgully', 'efficiency', 'float8', 'Column efficiency should be float8');

SELECT * FROM finish();

ROLLBACK;

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

-- Check table
SELECT has_table('config_visit_parameter'::name, 'Table config_visit_parameter should exist');

-- Check columns
SELECT columns_are(
    'config_visit_parameter',
    ARRAY[
        'id', 'code', 'parameter_type', 'feature_type', 'data_type', 'criticity',
        'descript', 'form_type', 'vdefault', 'ismultifeature', 'short_descript', 'active',
        'direct_insert'
    ],
    'Table config_visit_parameter should have the correct columns'
);

-- Check column types
SELECT col_type_is('config_visit_parameter', 'id', 'varchar(50)', 'Column id should be varchar(50)');
SELECT col_type_is('config_visit_parameter', 'code', 'text', 'Column code should be text');
SELECT col_type_is('config_visit_parameter', 'parameter_type', 'varchar(30)', 'Column parameter_type should be varchar(30)');
SELECT col_type_is('config_visit_parameter', 'feature_type', 'varchar(30)', 'Column feature_type should be varchar(30)');
SELECT col_type_is('config_visit_parameter', 'data_type', 'varchar(16)', 'Column data_type should be varchar(16)');
SELECT col_type_is('config_visit_parameter', 'criticity', 'int2', 'Column criticity should be int2');
SELECT col_type_is('config_visit_parameter', 'descript', 'varchar(100)', 'Column descript should be varchar(100)');
SELECT col_type_is('config_visit_parameter', 'form_type', 'varchar(30)', 'Column form_type should be varchar(30)');
SELECT col_type_is('config_visit_parameter', 'vdefault', 'text', 'Column vdefault should be text');
SELECT col_type_is('config_visit_parameter', 'ismultifeature', 'bool', 'Column ismultifeature should be bool');
SELECT col_type_is('config_visit_parameter', 'short_descript', 'varchar(30)', 'Column short_descript should be varchar(30)');
SELECT col_type_is('config_visit_parameter', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('config_visit_parameter', 'direct_insert', 'bool', 'Column direct_insert should be bool');

-- Finish
SELECT * FROM finish();

ROLLBACK;

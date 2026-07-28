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
SELECT has_table('cat_feature'::name, 'Table cat_feature should exist');

-- Check columns
SELECT columns_are(
    'cat_feature',
    ARRAY[
        'id', 'feature_class', 'feature_type', 'shortcut_key', 'parent_layer', 'child_layer',
        'descript', 'link_path', 'code_autofill', 'active', 'addparam', 'inventory_vdefault', 'abrevation'
    ],
    'Table cat_feature should have the correct columns'
);

-- Check column types
SELECT col_type_is('cat_feature', 'id', 'varchar(30)', 'Column id should be varchar(30)');
SELECT col_type_is('cat_feature', 'feature_class', 'varchar(30)', 'Column feature_class should be varchar(30)');
SELECT col_type_is('cat_feature', 'feature_type', 'varchar(30)', 'Column feature_type should be varchar(30)');
SELECT col_type_is('cat_feature', 'shortcut_key', 'varchar(100)', 'Column shortcut_key should be varchar(100)');
SELECT col_type_is('cat_feature', 'parent_layer', 'varchar(100)', 'Column parent_layer should be varchar(100)');
SELECT col_type_is('cat_feature', 'child_layer', 'varchar(100)', 'Column child_layer should be varchar(100)');
SELECT col_type_is('cat_feature', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('cat_feature', 'link_path', 'text', 'Column link_path should be text');
SELECT col_type_is('cat_feature', 'code_autofill', 'bool', 'Column code_autofill should be bool');
SELECT col_type_is('cat_feature', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('cat_feature', 'addparam', 'json', 'Column addparam should be json');
SELECT col_type_is('cat_feature', 'inventory_vdefault', 'bool', 'Column inventory_vdefault should be bool');
SELECT col_type_is('cat_feature', 'abrevation', 'varchar(30)', 'Column abrevation should be varchar(30)');

-- Check foreign keys
SELECT has_fk('cat_feature', 'Table cat_feature should have foreign keys');

SELECT fk_ok('cat_feature', ARRAY['feature_class', 'feature_type'], 'sys_feature_class', ARRAY['id', 'type'], 'FK (feature_class, feature_type) → sys_feature_class(id, type)');

-- Finish
SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_cat_feature_node
SELECT has_view('ve_cat_feature_node'::name, 'View ve_cat_feature_node should exist');

-- Check view columns
SELECT columns_are(
    've_cat_feature_node',
    ARRAY[
        'id', 'system_id', 'epa_default', 'isarcdivide', 'isprofilesurface', 'choose_hemisphere',
        'code_autofill', 'double_geom', 'num_arcs', 'graph_delimiter', 'shortcut_key', 'link_path',
        'descript', 'active', 'abrevation'
    ],
    'View ve_cat_feature_node should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_cat_feature_node', 'id', 'varchar(30)', 'Column id should be varchar(30)');
SELECT col_type_is('ve_cat_feature_node', 'system_id', 'varchar(30)', 'Column system_id should be varchar(30)');
SELECT col_type_is('ve_cat_feature_node', 'epa_default', 'varchar(30)', 'Column epa_default should be varchar(30)');
SELECT col_type_is('ve_cat_feature_node', 'isarcdivide', 'bool', 'Column isarcdivide should be bool');
SELECT col_type_is('ve_cat_feature_node', 'isprofilesurface', 'bool', 'Column isprofilesurface should be bool');
SELECT col_type_is('ve_cat_feature_node', 'choose_hemisphere', 'bool', 'Column choose_hemisphere should be bool');
SELECT col_type_is('ve_cat_feature_node', 'code_autofill', 'bool', 'Column code_autofill should be bool');
SELECT col_type_is('ve_cat_feature_node', 'double_geom', 'text', 'Column double_geom should be text');
SELECT col_type_is('ve_cat_feature_node', 'num_arcs', 'int4', 'Column num_arcs should be int4');
SELECT col_type_is('ve_cat_feature_node', 'graph_delimiter', 'text[]', 'Column graph_delimiter should be text[]');
SELECT col_type_is('ve_cat_feature_node', 'shortcut_key', 'varchar(100)', 'Column shortcut_key should be varchar(100)');
SELECT col_type_is('ve_cat_feature_node', 'link_path', 'text', 'Column link_path should be text');
SELECT col_type_is('ve_cat_feature_node', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_cat_feature_node', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('ve_cat_feature_node', 'abrevation', 'varchar(30)', 'Column abrevation should be varchar(30)');

SELECT * FROM finish();

ROLLBACK;

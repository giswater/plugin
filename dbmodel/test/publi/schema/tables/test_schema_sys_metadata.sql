/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT * FROM no_plan();

SELECT has_table('sys_metadata'::name, 'Table sys_metadata should exist');

SELECT columns_are(
    'sys_metadata',
    ARRAY['target_name', 'column_name', 'alias', 'description', 'source'],
    'Table sys_metadata should have the correct columns'
);

SELECT col_type_is('sys_metadata', 'target_name', 'text', 'Column target_name should be text');
SELECT col_type_is('sys_metadata', 'column_name', 'text', 'Column column_name should be text');
SELECT col_default_is('sys_metadata', 'column_name', '', 'Column column_name should default to empty (table row)');

SELECT has_pk('sys_metadata', 'Table sys_metadata should have a primary key');
SELECT col_is_pk('sys_metadata', ARRAY['target_name', 'column_name'], 'Primary key should be (target_name, column_name)');

SELECT * FROM finish();

ROLLBACK;

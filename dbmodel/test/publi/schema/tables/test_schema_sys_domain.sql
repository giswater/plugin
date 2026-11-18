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

SELECT has_table('sys_domain'::name, 'Table sys_domain should exist');

SELECT columns_are(
    'sys_domain',
    ARRAY['target_name', 'column_name', 'id', 'idval'],
    'Table sys_domain should have the correct columns'
);

SELECT col_type_is('sys_domain', 'id', 'text', 'Column id should be text');
SELECT col_type_is('sys_domain', 'idval', 'text', 'Column idval should be text');

SELECT has_pk('sys_domain', 'Table sys_domain should have a primary key');
SELECT col_is_pk('sys_domain', ARRAY['target_name', 'column_name', 'id'], 'Primary key should be (target_name, column_name, id)');

SELECT * FROM finish();

ROLLBACK;

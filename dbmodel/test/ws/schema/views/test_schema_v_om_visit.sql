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

-- Check view v_om_visit
SELECT has_view('v_om_visit'::name, 'View v_om_visit should exist');

-- Check view columns
SELECT columns_are(
    'v_om_visit',
    ARRAY[
        'visit_id', 'code', 'visitcat_id', 'name', 'visit_start', 'visit_end',
        'user_name', 'is_done', 'feature_id', 'feature_type', 'the_geom'
    ],
    'View v_om_visit should have the correct columns'
);

-- Check column types
SELECT col_type_is('v_om_visit', 'visit_id', 'int8', 'Column visit_id should be int8');
SELECT col_type_is('v_om_visit', 'code', 'varchar(30)', 'Column code should be varchar(30)');
SELECT col_type_is('v_om_visit', 'visitcat_id', 'int4', 'Column visitcat_id should be int4');
SELECT col_type_is('v_om_visit', 'name', 'varchar(30)', 'Column name should be varchar(30)');
SELECT col_type_is('v_om_visit', 'visit_start', 'timestamp(6) without time zone', 'Column visit_start should be timestamp(6) without time zone');
SELECT col_type_is('v_om_visit', 'visit_end', 'timestamp(6) without time zone', 'Column visit_end should be timestamp(6) without time zone');
SELECT col_type_is('v_om_visit', 'user_name', 'varchar(50)', 'Column user_name should be varchar(50)');
SELECT col_type_is('v_om_visit', 'is_done', 'bool', 'Column is_done should be bool');
SELECT col_type_is('v_om_visit', 'feature_id', 'int4', 'Column feature_id should be int4');
SELECT col_type_is('v_om_visit', 'feature_type', 'text', 'Column feature_type should be text');
SELECT col_type_is('v_om_visit', 'the_geom', 'geometry', 'Column the_geom should be geometry');

SELECT * FROM finish();

ROLLBACK;

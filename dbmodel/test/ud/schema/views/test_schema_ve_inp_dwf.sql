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

-- Check view ve_inp_dwf
SELECT has_view('ve_inp_dwf'::name, 'View ve_inp_dwf should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dwf',
    ARRAY[
        'dwfscenario_id', 'node_id', 'value', 'pat1', 'pat2', 'pat3',
        'pat4', 'p_state'
    ],
    'View ve_inp_dwf should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dwf', 'dwfscenario_id', 'int4', 'Column dwfscenario_id should be int4');
SELECT col_type_is('ve_inp_dwf', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dwf', 'value', 'numeric(12,7)', 'Column value should be numeric(12,7)');
SELECT col_type_is('ve_inp_dwf', 'pat1', 'varchar(16)', 'Column pat1 should be varchar(16)');
SELECT col_type_is('ve_inp_dwf', 'pat2', 'varchar(16)', 'Column pat2 should be varchar(16)');
SELECT col_type_is('ve_inp_dwf', 'pat3', 'varchar(16)', 'Column pat3 should be varchar(16)');
SELECT col_type_is('ve_inp_dwf', 'pat4', 'varchar(16)', 'Column pat4 should be varchar(16)');
SELECT col_type_is('ve_inp_dwf', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

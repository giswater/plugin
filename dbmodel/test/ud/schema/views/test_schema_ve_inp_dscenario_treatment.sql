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

-- Check view ve_inp_dscenario_treatment
SELECT has_view('ve_inp_dscenario_treatment'::name, 'View ve_inp_dscenario_treatment should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_treatment',
    ARRAY[
        'dscenario_id', 'node_id', 'poll_id', 'function', 'observ'
    ],
    'View ve_inp_dscenario_treatment should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_treatment', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_treatment', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_treatment', 'poll_id', 'varchar(16)', 'Column poll_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_treatment', 'function', 'varchar(100)', 'Column function should be varchar(100)');
SELECT col_type_is('ve_inp_dscenario_treatment', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

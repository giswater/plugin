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
SELECT has_table('inp_dscenario_treatment'::name, 'Table inp_dscenario_treatment should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_treatment',
    ARRAY[
        'dscenario_id', 'node_id', 'poll_id', 'function', 'observ'
    ],
    'Table inp_dscenario_treatment should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_treatment', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_treatment', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_treatment', 'poll_id', 'varchar(16)', 'Column poll_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_treatment', 'function', 'varchar(100)', 'Column function should be varchar(100)');
SELECT col_type_is('inp_dscenario_treatment', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_treatment', 'Table inp_dscenario_treatment should have foreign keys');

SELECT fk_ok('inp_dscenario_treatment', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_treatment', 'poll_id', 'inp_pollutant', 'poll_id', 'FK poll_id → inp_pollutant.poll_id');
SELECT fk_ok('inp_dscenario_treatment', 'node_id', 'inp_treatment', 'node_id', 'FK node_id → inp_treatment.node_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

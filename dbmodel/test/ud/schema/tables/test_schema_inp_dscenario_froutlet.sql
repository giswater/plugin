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
SELECT has_table('inp_dscenario_froutlet'::name, 'Table inp_dscenario_froutlet should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_froutlet',
    ARRAY[
        'dscenario_id', 'element_id', 'outlet_type', 'offsetval', 'curve_id', 'cd1',
        'cd2', 'flap', 'observ'
    ],
    'Table inp_dscenario_froutlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_froutlet', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_froutlet', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('inp_dscenario_froutlet', 'outlet_type', 'varchar(16)', 'Column outlet_type should be varchar(16)');
SELECT col_type_is('inp_dscenario_froutlet', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_froutlet', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_froutlet', 'cd1', 'numeric(12,4)', 'Column cd1 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_froutlet', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_froutlet', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('inp_dscenario_froutlet', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_froutlet', 'Table inp_dscenario_froutlet should have foreign keys');

SELECT fk_ok('inp_dscenario_froutlet', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

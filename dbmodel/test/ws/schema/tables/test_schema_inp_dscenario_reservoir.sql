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
SELECT has_table('inp_dscenario_reservoir'::name, 'Table inp_dscenario_reservoir should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_reservoir',
    ARRAY[
        'dscenario_id', 'node_id', 'pattern_id', 'head', 'init_quality', 'source_type',
        'source_quality', 'source_pattern_id', 'observ'
    ],
    'Table inp_dscenario_reservoir should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_reservoir', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_reservoir', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_reservoir', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_reservoir', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('inp_dscenario_reservoir', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('inp_dscenario_reservoir', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('inp_dscenario_reservoir', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('inp_dscenario_reservoir', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_reservoir', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_reservoir', 'Table inp_dscenario_reservoir should have foreign keys');

SELECT fk_ok('inp_dscenario_reservoir', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_reservoir', 'node_id', 'inp_reservoir', 'node_id', 'FK node_id → inp_reservoir.node_id');
SELECT fk_ok('inp_dscenario_reservoir', 'pattern_id', 'inp_pattern', 'pattern_id', 'FK pattern_id → inp_pattern.pattern_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

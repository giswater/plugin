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
SELECT has_table('inp_dscenario_inflows'::name, 'Table inp_dscenario_inflows should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_inflows',
    ARRAY[
        'dscenario_id', 'node_id', 'order_id', 'timser_id', 'sfactor', 'base',
        'pattern_id', 'active', 'observ'
    ],
    'Table inp_dscenario_inflows should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_inflows', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_inflows', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_inflows', 'order_id', 'int4', 'Column order_id should be int4');
SELECT col_type_is('inp_dscenario_inflows', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inflows', 'sfactor', 'numeric(12,4)', 'Column sfactor should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inflows', 'base', 'numeric(12,4)', 'Column base should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inflows', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inflows', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('inp_dscenario_inflows', 'observ', 'text', 'Column observ should be text');
-- Check foreign keys
SELECT has_fk('inp_dscenario_inflows', 'Table inp_dscenario_inflows should have foreign keys');

SELECT fk_ok('inp_dscenario_inflows', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_inflows', 'pattern_id', 'inp_pattern', 'pattern_id', 'FK pattern_id → inp_pattern.pattern_id');
SELECT fk_ok('inp_dscenario_inflows', 'timser_id', 'inp_timeseries', 'id', 'FK timser_id → inp_timeseries.id');
SELECT fk_ok('inp_dscenario_inflows', 'node_id', 'node', 'node_id', 'FK node_id → node.node_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

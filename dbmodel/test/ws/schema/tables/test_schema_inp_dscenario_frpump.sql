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
SELECT has_table('inp_dscenario_frpump'::name, 'Table inp_dscenario_frpump should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_frpump',
    ARRAY[
        'dscenario_id', 'element_id', 'power', 'curve_id', 'speed', 'pattern_id',
        'status', 'effic_curve_id', 'energy_price', 'energy_pattern_id', 'observ'
    ],
    'Table inp_dscenario_frpump should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_frpump', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_frpump', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('inp_dscenario_frpump', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('inp_dscenario_frpump', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('inp_dscenario_frpump', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('inp_dscenario_frpump', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('inp_dscenario_frpump', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('inp_dscenario_frpump', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('inp_dscenario_frpump', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('inp_dscenario_frpump', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('inp_dscenario_frpump', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_frpump', 'Table inp_dscenario_frpump should have foreign keys');

SELECT fk_ok('inp_dscenario_frpump', 'curve_id', 'inp_curve', 'id', 'FK curve_id → inp_curve.id');
SELECT fk_ok('inp_dscenario_frpump', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_frpump', 'energy_pattern_id', 'inp_pattern', 'pattern_id', 'FK energy_pattern_id → inp_pattern.pattern_id');
SELECT fk_ok('inp_dscenario_frpump', 'element_id', 'inp_frpump', 'element_id', 'FK element_id → inp_frpump.element_id');
SELECT fk_ok('inp_dscenario_frpump', 'pattern_id', 'inp_pattern', 'pattern_id', 'FK pattern_id → inp_pattern.pattern_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

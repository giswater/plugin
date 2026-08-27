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
SELECT has_table('inp_dscenario_inlet'::name, 'Table inp_dscenario_inlet should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_inlet',
    ARRAY[
        'dscenario_id', 'node_id', 'initlevel', 'minlevel', 'maxlevel', 'diameter',
        'minvol', 'curve_id', 'head', 'pattern_id', 'overflow', 'mixing_model',
        'mixing_fraction', 'reaction_coeff', 'init_quality', 'source_type', 'source_quality', 'source_pattern_id',
        'demand', 'demand_pattern_id', 'emitter_coeff', 'observ'
    ],
    'Table inp_dscenario_inlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_inlet', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_inlet', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_inlet', 'initlevel', 'numeric(12,4)', 'Column initlevel should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'minlevel', 'numeric(12,4)', 'Column minlevel should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'maxlevel', 'numeric(12,4)', 'Column maxlevel should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'diameter', 'numeric(12,4)', 'Column diameter should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'minvol', 'numeric(12,4)', 'Column minvol should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inlet', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inlet', 'overflow', 'varchar(3)', 'Column overflow should be varchar(3)');
SELECT col_type_is('inp_dscenario_inlet', 'mixing_model', 'varchar(18)', 'Column mixing_model should be varchar(18)');
SELECT col_type_is('inp_dscenario_inlet', 'mixing_fraction', 'float8', 'Column mixing_fraction should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'reaction_coeff', 'float8', 'Column reaction_coeff should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('inp_dscenario_inlet', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inlet', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('inp_dscenario_inlet', 'demand_pattern_id', 'varchar(16)', 'Column demand_pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inlet', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_inlet', 'Table inp_dscenario_inlet should have foreign keys');

SELECT fk_ok('inp_dscenario_inlet', 'curve_id', 'inp_curve', 'id', 'FK curve_id → inp_curve.id');
SELECT fk_ok('inp_dscenario_inlet', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_inlet', 'node_id', 'inp_inlet', 'node_id', 'FK node_id → inp_inlet.node_id');
SELECT fk_ok('inp_dscenario_inlet', 'pattern_id', 'inp_pattern', 'pattern_id', 'FK pattern_id → inp_pattern.pattern_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

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
SELECT has_table('inp_dscenario_demand'::name, 'Table inp_dscenario_demand should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_demand',
    ARRAY[
        'id', 'dscenario_id', 'feature_id', 'feature_type', 'demand', 'pattern_id',
        'demand_type', 'source', 'observ'
    ],
    'Table inp_dscenario_demand should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_demand', 'id', 'int4', 'Column id should be int4');
SELECT col_type_is('inp_dscenario_demand', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_demand', 'feature_id', 'int4', 'Column feature_id should be int4');
SELECT col_type_is('inp_dscenario_demand', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('inp_dscenario_demand', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('inp_dscenario_demand', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_demand', 'demand_type', 'varchar(18)', 'Column demand_type should be varchar(18)');
SELECT col_type_is('inp_dscenario_demand', 'source', 'text', 'Column source should be text');
SELECT col_type_is('inp_dscenario_demand', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_demand', 'Table inp_dscenario_demand should have foreign keys');

SELECT fk_ok('inp_dscenario_demand', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_demand', 'pattern_id', 'inp_pattern', 'pattern_id', 'FK pattern_id → inp_pattern.pattern_id');
SELECT fk_ok('inp_dscenario_demand', 'feature_type', 'sys_feature_type', 'id', 'FK feature_type → sys_feature_type.id');
SELECT fk_ok('inp_dscenario_demand', 'pattern_id', 'inp_pattern', 'pattern_id', 'FK pattern_id → inp_pattern.pattern_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

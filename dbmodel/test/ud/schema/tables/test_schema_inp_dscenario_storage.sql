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
SELECT has_table('inp_dscenario_storage'::name, 'Table inp_dscenario_storage should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_storage',
    ARRAY[
        'dscenario_id', 'node_id', 'elev', 'ymax', 'storage_type', 'curve_id',
        'a1', 'a2', 'a0', 'fevap', 'sh', 'hc',
        'imd', 'y0', 'ysur', 'observ'
    ],
    'Table inp_dscenario_storage should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_storage', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_storage', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_storage', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('inp_dscenario_storage', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('inp_dscenario_storage', 'storage_type', 'varchar(18)', 'Column storage_type should be varchar(18)');
SELECT col_type_is('inp_dscenario_storage', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_storage', 'a1', 'numeric(12,4)', 'Column a1 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'a2', 'numeric(12,4)', 'Column a2 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'a0', 'numeric(12,4)', 'Column a0 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'fevap', 'numeric(12,4)', 'Column fevap should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'sh', 'numeric(12,4)', 'Column sh should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'hc', 'numeric(12,4)', 'Column hc should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'imd', 'numeric(12,4)', 'Column imd should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_storage', 'observ', 'text', 'Column observ should be text');
-- Check foreign keys
SELECT has_fk('inp_dscenario_storage', 'Table inp_dscenario_storage should have foreign keys');

SELECT fk_ok('inp_dscenario_storage', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_storage', 'curve_id', 'inp_curve', 'id', 'FK curve_id → inp_curve.id');
SELECT fk_ok('inp_dscenario_storage', 'node_id', 'inp_storage', 'node_id', 'FK node_id → inp_storage.node_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

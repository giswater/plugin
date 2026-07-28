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
        'dscenario_id', 'node_id', 'elev', 'ymax', 'y0', 'ysur',
        'apond', 'inlet_type', 'outlet_type', 'gully_method', 'custom_top_elev', 'custom_depth',
        'inlet_length', 'inlet_width', 'cd1', 'cd2', 'efficiency', 'observ'
    ],
    'Table inp_dscenario_inlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_inlet', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_inlet', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_inlet', 'elev', 'float8', 'Column elev should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'ymax', 'float8', 'Column ymax should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inlet', 'inlet_type', 'varchar(30)', 'Column inlet_type should be varchar(30)');
SELECT col_type_is('inp_dscenario_inlet', 'outlet_type', 'varchar(30)', 'Column outlet_type should be varchar(30)');
SELECT col_type_is('inp_dscenario_inlet', 'gully_method', 'varchar(30)', 'Column gully_method should be varchar(30)');
SELECT col_type_is('inp_dscenario_inlet', 'custom_top_elev', 'float8', 'Column custom_top_elev should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'custom_depth', 'float8', 'Column custom_depth should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'inlet_length', 'float8', 'Column inlet_length should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'inlet_width', 'float8', 'Column inlet_width should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'cd1', 'float8', 'Column cd1 should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'cd2', 'float8', 'Column cd2 should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'efficiency', 'float8', 'Column efficiency should be float8');
SELECT col_type_is('inp_dscenario_inlet', 'observ', 'text', 'Column observ should be text');
-- Check foreign keys
SELECT has_fk('inp_dscenario_inlet', 'Table inp_dscenario_inlet should have foreign keys');

SELECT fk_ok('inp_dscenario_inlet', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_inlet', 'node_id', 'inp_inlet', 'node_id', 'FK node_id → inp_inlet.node_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

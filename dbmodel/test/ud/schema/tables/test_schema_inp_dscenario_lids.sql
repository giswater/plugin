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
SELECT has_table('inp_dscenario_lids'::name, 'Table inp_dscenario_lids should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_lids',
    ARRAY[
        'dscenario_id', 'subc_id', 'lidco_id', 'numelem', 'area', 'width',
        'initsat', 'fromimp', 'toperv', 'rptfile', 'descript', 'observ'
    ],
    'Table inp_dscenario_lids should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_lids', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_lids', 'subc_id', 'varchar(16)', 'Column subc_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_lids', 'lidco_id', 'varchar(16)', 'Column lidco_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_lids', 'numelem', 'int2', 'Column numelem should be int2');
SELECT col_type_is('inp_dscenario_lids', 'area', 'numeric(16,6)', 'Column area should be numeric(16,6)');
SELECT col_type_is('inp_dscenario_lids', 'width', 'numeric(12,4)', 'Column width should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_lids', 'initsat', 'numeric(12,4)', 'Column initsat should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_lids', 'fromimp', 'numeric(12,4)', 'Column fromimp should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_lids', 'toperv', 'int2', 'Column toperv should be int2');
SELECT col_type_is('inp_dscenario_lids', 'rptfile', 'varchar(10)', 'Column rptfile should be varchar(10)');
SELECT col_type_is('inp_dscenario_lids', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('inp_dscenario_lids', 'observ', 'text', 'Column observ should be text');
-- Check foreign keys
SELECT has_fk('inp_dscenario_lids', 'Table inp_dscenario_lids should have foreign keys');

SELECT fk_ok('inp_dscenario_lids', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_lids', 'lidco_id', 'inp_lid', 'lidco_id', 'FK lidco_id → inp_lid.lidco_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

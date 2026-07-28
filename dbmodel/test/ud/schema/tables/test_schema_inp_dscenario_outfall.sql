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
SELECT has_table('inp_dscenario_outfall'::name, 'Table inp_dscenario_outfall should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_outfall',
    ARRAY[
        'dscenario_id', 'node_id', 'elev', 'ymax', 'outfall_type', 'stage',
        'curve_id', 'timser_id', 'gate', 'route_to', 'observ'
    ],
    'Table inp_dscenario_outfall should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_outfall', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_outfall', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_outfall', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('inp_dscenario_outfall', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('inp_dscenario_outfall', 'outfall_type', 'varchar(16)', 'Column outfall_type should be varchar(16)');
SELECT col_type_is('inp_dscenario_outfall', 'stage', 'numeric(12,4)', 'Column stage should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_outfall', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_outfall', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_outfall', 'gate', 'varchar(3)', 'Column gate should be varchar(3)');
SELECT col_type_is('inp_dscenario_outfall', 'route_to', 'varchar(16)', 'Column route_to should be varchar(16)');
SELECT col_type_is('inp_dscenario_outfall', 'observ', 'text', 'Column observ should be text');
-- Check foreign keys
SELECT has_fk('inp_dscenario_outfall', 'Table inp_dscenario_outfall should have foreign keys');

SELECT fk_ok('inp_dscenario_outfall', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_outfall', 'timser_id', 'inp_timeseries', 'id', 'FK timser_id → inp_timeseries.id');
SELECT fk_ok('inp_dscenario_outfall', 'curve_id', 'inp_curve', 'id', 'FK curve_id → inp_curve.id');
SELECT fk_ok('inp_dscenario_outfall', 'node_id', 'inp_outfall', 'node_id', 'FK node_id → inp_outfall.node_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

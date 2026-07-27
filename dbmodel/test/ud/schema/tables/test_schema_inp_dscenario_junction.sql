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
SELECT has_table('inp_dscenario_junction'::name, 'Table inp_dscenario_junction should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_junction',
    ARRAY[
        'dscenario_id', 'node_id', 'y0', 'ysur', 'apond', 'outfallparam',
        'elev', 'ymax', 'observ'
    ],
    'Table inp_dscenario_junction should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_junction', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_junction', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_junction', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_junction', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_junction', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_junction', 'outfallparam', 'json', 'Column outfallparam should be json');
SELECT col_type_is('inp_dscenario_junction', 'elev', 'float8', 'Column elev should be float8');
SELECT col_type_is('inp_dscenario_junction', 'ymax', 'float8', 'Column ymax should be float8');
SELECT col_type_is('inp_dscenario_junction', 'observ', 'text', 'Column observ should be text');
-- Check foreign keys
SELECT has_fk('inp_dscenario_junction', 'Table inp_dscenario_junction should have foreign keys');

SELECT fk_ok('inp_dscenario_junction', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_junction', 'node_id', 'inp_junction', 'node_id', 'FK node_id → inp_junction.node_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

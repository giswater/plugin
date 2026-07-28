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

-- Check view ve_inp_dscenario_froutlet
SELECT has_view('ve_inp_dscenario_froutlet'::name, 'View ve_inp_dscenario_froutlet should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_froutlet',
    ARRAY[
        'dscenario_id', 'element_id', 'node_id', 'outlet_type', 'offsetval', 'curve_id',
        'cd1', 'cd2', 'flap', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_froutlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_froutlet', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'outlet_type', 'varchar(16)', 'Column outlet_type should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'cd1', 'numeric(12,4)', 'Column cd1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_froutlet', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_inp_froutlet
SELECT has_view('ve_inp_froutlet'::name, 'View ve_inp_froutlet should exist');

-- Check view columns
SELECT columns_are(
    've_inp_froutlet',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'flwreg_length', 'outlet_type', 'offsetval',
        'curve_id', 'cd1', 'cd2', 'flap', 'the_geom', 'p_state'
    ],
    'View ve_inp_froutlet should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_froutlet', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_froutlet', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_froutlet', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_froutlet', 'flwreg_length', 'numeric', 'Column flwreg_length should be numeric');
SELECT col_type_is('ve_inp_froutlet', 'outlet_type', 'varchar(16)', 'Column outlet_type should be varchar(16)');
SELECT col_type_is('ve_inp_froutlet', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_froutlet', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_froutlet', 'cd1', 'numeric(12,4)', 'Column cd1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_froutlet', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_froutlet', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_froutlet', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_froutlet', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

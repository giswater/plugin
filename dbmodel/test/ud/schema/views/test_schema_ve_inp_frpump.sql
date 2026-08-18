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

-- Check view ve_inp_frpump
SELECT has_view('ve_inp_frpump'::name, 'View ve_inp_frpump should exist');

-- Check view columns
SELECT columns_are(
    've_inp_frpump',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'flwreg_length', 'curve_id', 'status',
        'startup', 'shutoff', 'the_geom', 'p_state'
    ],
    'View ve_inp_frpump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_frpump', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_frpump', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_frpump', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_frpump', 'flwreg_length', 'numeric', 'Column flwreg_length should be numeric');
SELECT col_type_is('ve_inp_frpump', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_frpump', 'status', 'varchar(3)', 'Column status should be varchar(3)');
SELECT col_type_is('ve_inp_frpump', 'startup', 'numeric(12,4)', 'Column startup should be numeric(12,4)');
SELECT col_type_is('ve_inp_frpump', 'shutoff', 'numeric(12,4)', 'Column shutoff should be numeric(12,4)');
SELECT col_type_is('ve_inp_frpump', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_frpump', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

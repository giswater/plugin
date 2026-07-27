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

-- Check view ve_inp_dscenario_frpump
SELECT has_view('ve_inp_dscenario_frpump'::name, 'View ve_inp_dscenario_frpump should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_frpump',
    ARRAY[
        'dscenario_id', 'element_id', 'node_id', 'curve_id', 'status', 'startup',
        'shutoff', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_frpump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_frpump', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frpump', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frpump', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frpump', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_frpump', 'status', 'varchar(3)', 'Column status should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_frpump', 'startup', 'numeric(12,4)', 'Column startup should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frpump', 'shutoff', 'numeric(12,4)', 'Column shutoff should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frpump', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_frpump', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

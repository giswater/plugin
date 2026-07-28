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

-- Check view ve_inp_dscenario_frorifice
SELECT has_view('ve_inp_dscenario_frorifice'::name, 'View ve_inp_dscenario_frorifice should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_frorifice',
    ARRAY[
        'dscenario_id', 'element_id', 'node_id', 'orifice_type', 'offsetval', 'cd',
        'orate', 'flap', 'shape', 'geom1', 'geom2', 'geom3',
        'geom4', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_frorifice should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_frorifice', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'orifice_type', 'varchar(18)', 'Column orifice_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'cd', 'numeric(12,4)', 'Column cd should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'orate', 'numeric(12,4)', 'Column orate should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'shape', 'varchar(18)', 'Column shape should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_frorifice', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

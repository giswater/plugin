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

-- Check view ve_inp_dscenario_outfall
SELECT has_view('ve_inp_dscenario_outfall'::name, 'View ve_inp_dscenario_outfall should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_outfall',
    ARRAY[
        'dscenario_id', 'node_id', 'elev', 'ymax', 'outfall_type', 'stage',
        'curve_id', 'timser_id', 'gate', 'route_to', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_outfall should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_outfall', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_outfall', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_outfall', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'outfall_type', 'varchar(16)', 'Column outfall_type should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'stage', 'numeric(12,4)', 'Column stage should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'gate', 'varchar(3)', 'Column gate should be varchar(3)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'route_to', 'varchar(16)', 'Column route_to should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_outfall', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

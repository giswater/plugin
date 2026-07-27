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

-- Check view ve_inp_dscenario_junction
SELECT has_view('ve_inp_dscenario_junction'::name, 'View ve_inp_dscenario_junction should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_junction',
    ARRAY[
        'dscenario_id', 'node_id', 'elev', 'ymax', 'y0', 'ysur',
        'apond', 'outfallparam', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_junction should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_junction', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_junction', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_junction', 'elev', 'float8', 'Column elev should be float8');
SELECT col_type_is('ve_inp_dscenario_junction', 'ymax', 'float8', 'Column ymax should be float8');
SELECT col_type_is('ve_inp_dscenario_junction', 'y0', 'numeric(12,4)', 'Column y0 should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_junction', 'ysur', 'numeric(12,4)', 'Column ysur should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_junction', 'apond', 'numeric(12,4)', 'Column apond should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_junction', 'outfallparam', 'json', 'Column outfallparam should be json');
SELECT col_type_is('ve_inp_dscenario_junction', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_junction', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

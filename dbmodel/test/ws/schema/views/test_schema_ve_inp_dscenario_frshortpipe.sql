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

-- Check view ve_inp_dscenario_frshortpipe
SELECT has_view('ve_inp_dscenario_frshortpipe'::name, 'View ve_inp_dscenario_frshortpipe should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_frshortpipe',
    ARRAY[
        'dscenario_id', 'element_id', 'node_id', 'minorloss', 'bulk_coeff', 'wall_coeff',
        'custom_dint', 'status', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_frshortpipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'custom_dint', 'int4', 'Column custom_dint should be int4');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_frshortpipe', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

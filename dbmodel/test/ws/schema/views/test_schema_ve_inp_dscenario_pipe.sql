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

-- Check view ve_inp_dscenario_pipe
SELECT has_view('ve_inp_dscenario_pipe'::name, 'View ve_inp_dscenario_pipe should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_pipe',
    ARRAY[
        'dscenario_id', 'arc_id', 'minorloss', 'status', 'roughness', 'dint',
        'bulk_coeff', 'wall_coeff', 'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_pipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_pipe', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_pipe', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_inp_dscenario_pipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_pipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_dscenario_pipe', 'roughness', 'numeric(12,4)', 'Column roughness should be numeric(12,4)');
SELECT col_type_is('ve_inp_dscenario_pipe', 'dint', 'numeric(12,3)', 'Column dint should be numeric(12,3)');
SELECT col_type_is('ve_inp_dscenario_pipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_pipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_inp_dscenario_pipe', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_pipe', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_inp_frshortpipe
SELECT has_view('ve_inp_frshortpipe'::name, 'View ve_inp_frshortpipe should exist');

-- Check view columns
SELECT columns_are(
    've_inp_frshortpipe',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'flwreg_length', 'minorloss', 'bulk_coeff',
        'wall_coeff', 'custom_dint', 'status', 'the_geom', 'p_state'
    ],
    'View ve_inp_frshortpipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_frshortpipe', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_inp_frshortpipe', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_frshortpipe', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_inp_frshortpipe', 'flwreg_length', 'numeric', 'Column flwreg_length should be numeric');
SELECT col_type_is('ve_inp_frshortpipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_inp_frshortpipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_inp_frshortpipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_inp_frshortpipe', 'custom_dint', 'int4', 'Column custom_dint should be int4');
SELECT col_type_is('ve_inp_frshortpipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_inp_frshortpipe', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_inp_frshortpipe', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

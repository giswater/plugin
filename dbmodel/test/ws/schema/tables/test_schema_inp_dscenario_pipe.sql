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

-- Check table
SELECT has_table('inp_dscenario_pipe'::name, 'Table inp_dscenario_pipe should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_pipe',
    ARRAY[
        'dscenario_id', 'arc_id', 'minorloss', 'status', 'roughness', 'dint',
        'bulk_coeff', 'wall_coeff', 'observ'
    ],
    'Table inp_dscenario_pipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_pipe', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_pipe', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('inp_dscenario_pipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('inp_dscenario_pipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('inp_dscenario_pipe', 'roughness', 'numeric(12,4)', 'Column roughness should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_pipe', 'dint', 'numeric(12,3)', 'Column dint should be numeric(12,3)');
SELECT col_type_is('inp_dscenario_pipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('inp_dscenario_pipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('inp_dscenario_pipe', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_pipe', 'Table inp_dscenario_pipe should have foreign keys');

SELECT fk_ok('inp_dscenario_pipe', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_pipe', 'arc_id', 'inp_pipe', 'arc_id', 'FK arc_id → inp_pipe.arc_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

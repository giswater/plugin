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
SELECT has_table('inp_dscenario_frshortpipe'::name, 'Table inp_dscenario_frshortpipe should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_frshortpipe',
    ARRAY[
        'dscenario_id', 'element_id', 'minorloss', 'status', 'custom_dint', 'bulk_coeff',
        'wall_coeff', 'observ'
    ],
    'Table inp_dscenario_frshortpipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_frshortpipe', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_frshortpipe', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('inp_dscenario_frshortpipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('inp_dscenario_frshortpipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('inp_dscenario_frshortpipe', 'custom_dint', 'int4', 'Column custom_dint should be int4');
SELECT col_type_is('inp_dscenario_frshortpipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('inp_dscenario_frshortpipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('inp_dscenario_frshortpipe', 'observ', 'text', 'Column observ should be text');

-- Check foreign keys
SELECT has_fk('inp_dscenario_frshortpipe', 'Table inp_dscenario_frshortpipe should have foreign keys');

SELECT fk_ok('inp_dscenario_frshortpipe', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_frshortpipe', 'element_id', 'inp_frshortpipe', 'element_id', 'FK element_id → inp_frshortpipe.element_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

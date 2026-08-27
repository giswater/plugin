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

-- Check view ve_inp_dscenario_controls
SELECT has_view('ve_inp_dscenario_controls'::name, 'View ve_inp_dscenario_controls should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_controls',
    ARRAY[
        'id', 'dscenario_id', 'sector_id', 'text', 'active', 'observ'
    ],
    'View ve_inp_dscenario_controls should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_controls', 'id', 'int4', 'Column id should be int4');
SELECT col_type_is('ve_inp_dscenario_controls', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_controls', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_dscenario_controls', 'text', 'text', 'Column text should be text');
SELECT col_type_is('ve_inp_dscenario_controls', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('ve_inp_dscenario_controls', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

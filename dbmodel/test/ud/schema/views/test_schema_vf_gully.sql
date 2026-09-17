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

-- Check view vf_gully
SELECT has_view('vf_gully'::name, 'View vf_gully should exist');

-- Check view columns
SELECT columns_are(
    'vf_gully',
    ARRAY[
        'gully_id', 'p_state', 'p_arc_id', 'p_pjoint_id', 'p_pjoint_type'
    ],
    'View vf_gully should have the correct columns'
);

-- Check column types
SELECT col_type_is('vf_gully', 'gully_id', 'int4', 'Column gully_id should be int4');
SELECT col_type_is('vf_gully', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('vf_gully', 'p_arc_id', 'int4', 'Column p_arc_id should be int4');
SELECT col_type_is('vf_gully', 'p_pjoint_id', 'int4', 'Column p_pjoint_id should be int4');
SELECT col_type_is('vf_gully', 'p_pjoint_type', 'varchar(16)', 'Column p_pjoint_type should be varchar(16)');

SELECT * FROM finish();

ROLLBACK;

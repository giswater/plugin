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

-- Check view ve_epa_virtual
SELECT has_view('ve_epa_virtual'::name, 'View ve_epa_virtual should exist');
SELECT has_trigger('ve_epa_virtual', 'gw_trg_edit_ve_epa_virtual',
    'View ve_epa_virtual should have gw_trg_edit_ve_epa_virtual');

-- Check view columns
SELECT columns_are(
    've_epa_virtual',
    ARRAY[
        'arc_id', 'fusion_node', 'add_length'
    ],
    'View ve_epa_virtual should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_virtual', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_epa_virtual', 'fusion_node', 'int4', 'Column fusion_node should be int4');
SELECT col_type_is('ve_epa_virtual', 'add_length', 'bool', 'Column add_length should be bool');

SELECT * FROM finish();

ROLLBACK;

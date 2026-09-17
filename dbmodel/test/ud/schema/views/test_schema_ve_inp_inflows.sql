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

-- Check view ve_inp_inflows
SELECT has_view('ve_inp_inflows'::name, 'View ve_inp_inflows should exist');

-- Check view columns
SELECT columns_are(
    've_inp_inflows',
    ARRAY[
        'node_id', 'order_id', 'timser_id', 'sfactor', 'base', 'pattern_id', 'p_state'
    ],
    'View ve_inp_inflows should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_inflows', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_inp_inflows', 'order_id', 'int4', 'Column order_id should be int4');
SELECT col_type_is('ve_inp_inflows', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('ve_inp_inflows', 'sfactor', 'numeric(12,4)', 'Column sfactor should be numeric(12,4)');
SELECT col_type_is('ve_inp_inflows', 'base', 'numeric(12,4)', 'Column base should be numeric(12,4)');
SELECT col_type_is('ve_inp_inflows', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_inflows', 'p_state', 'int2', 'Column p_state should be int2');

SELECT * FROM finish();

ROLLBACK;

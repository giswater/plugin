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
SELECT has_table('inp_dscenario_inflows_poll'::name, 'Table inp_dscenario_inflows_poll should exist');

-- Check columns
SELECT columns_are(
    'inp_dscenario_inflows_poll',
    ARRAY[
        'dscenario_id', 'node_id', 'poll_id', 'timser_id', 'form_type', 'mfactor',
        'sfactor', 'base', 'pattern_id', 'observ'
    ],
    'Table inp_dscenario_inflows_poll should have the correct columns'
);

-- Check column types
SELECT col_type_is('inp_dscenario_inflows_poll', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('inp_dscenario_inflows_poll', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('inp_dscenario_inflows_poll', 'poll_id', 'varchar(16)', 'Column poll_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inflows_poll', 'timser_id', 'varchar(16)', 'Column timser_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inflows_poll', 'form_type', 'varchar(18)', 'Column form_type should be varchar(18)');
SELECT col_type_is('inp_dscenario_inflows_poll', 'mfactor', 'numeric(12,4)', 'Column mfactor should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inflows_poll', 'sfactor', 'numeric(12,4)', 'Column sfactor should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inflows_poll', 'base', 'numeric(12,4)', 'Column base should be numeric(12,4)');
SELECT col_type_is('inp_dscenario_inflows_poll', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('inp_dscenario_inflows_poll', 'observ', 'text', 'Column observ should be text');
-- Check foreign keys
SELECT has_fk('inp_dscenario_inflows_poll', 'Table inp_dscenario_inflows_poll should have foreign keys');

SELECT fk_ok('inp_dscenario_inflows_poll', 'dscenario_id', 'cat_dscenario', 'dscenario_id', 'FK dscenario_id → cat_dscenario.dscenario_id');
SELECT fk_ok('inp_dscenario_inflows_poll', 'pattern_id', 'inp_pattern', 'pattern_id', 'FK pattern_id → inp_pattern.pattern_id');
SELECT fk_ok('inp_dscenario_inflows_poll', 'poll_id', 'inp_pollutant', 'poll_id', 'FK poll_id → inp_pollutant.poll_id');
SELECT fk_ok('inp_dscenario_inflows_poll', 'timser_id', 'inp_timeseries', 'id', 'FK timser_id → inp_timeseries.id');
SELECT fk_ok('inp_dscenario_inflows_poll', 'node_id', 'node', 'node_id', 'FK node_id → node.node_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

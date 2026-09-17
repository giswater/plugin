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
SELECT has_table('rpt_cat_result'::name, 'Table rpt_cat_result should exist');

-- Check columns
SELECT columns_are(
    'rpt_cat_result',
    ARRAY[
        'result_id', 'exec_date', 'cur_user', 'inp_options', 'rpt_stats', 'export_options',
        'network_stats', 'status', 'addparam', 'expl_id', 'network_type', 'sector_id',
        'descript', 'iscorporate', 'inp_file', 'is_twin', 'parent_id', 'isvalidated'
    ],
    'Table rpt_cat_result should have the correct columns'
);

-- Check column types
SELECT col_type_is('rpt_cat_result', 'result_id', 'varchar(50)', 'Column result_id should be varchar(50)');
SELECT col_type_is('rpt_cat_result', 'exec_date', 'timestamp(6) without time zone', 'Column exec_date should be timestamp(6) without time zone');
SELECT col_type_is('rpt_cat_result', 'cur_user', 'text', 'Column cur_user should be text');
SELECT col_type_is('rpt_cat_result', 'inp_options', 'json', 'Column inp_options should be json');
SELECT col_type_is('rpt_cat_result', 'rpt_stats', 'json', 'Column rpt_stats should be json');
SELECT col_type_is('rpt_cat_result', 'export_options', 'json', 'Column export_options should be json');
SELECT col_type_is('rpt_cat_result', 'network_stats', 'json', 'Column network_stats should be json');
SELECT col_type_is('rpt_cat_result', 'status', 'int2', 'Column status should be int2');
SELECT col_type_is('rpt_cat_result', 'addparam', 'json', 'Column addparam should be json');
SELECT col_type_is('rpt_cat_result', 'expl_id', 'int4[]', 'Column expl_id should be int4[]');
SELECT col_type_is('rpt_cat_result', 'network_type', 'text', 'Column network_type should be text');
SELECT col_type_is('rpt_cat_result', 'sector_id', 'int4[]', 'Column sector_id should be int4[]');
SELECT col_type_is('rpt_cat_result', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('rpt_cat_result', 'iscorporate', 'bool', 'Column iscorporate should be bool');
SELECT col_type_is('rpt_cat_result', 'inp_file', 'bytea', 'Column inp_file should be bytea');
SELECT col_type_is('rpt_cat_result', 'is_twin', 'bool', 'Column is_twin should be bool');
SELECT col_type_is('rpt_cat_result', 'parent_id', 'varchar(16)', 'Column parent_id should be varchar(16)');
SELECT col_type_is('rpt_cat_result', 'isvalidated', 'bool', 'Column isvalidated should be bool');
-- Finish
SELECT * FROM finish();

ROLLBACK;

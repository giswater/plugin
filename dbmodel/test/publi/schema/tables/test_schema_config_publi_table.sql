/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT * FROM no_plan();

SELECT has_table('config_publi_table'::name, 'Table config_publi_table should exist');

SELECT columns_are(
    'config_publi_table',
    ARRAY[
        'id', 'source_schema', 'source_relation', 'source_sql', 'source_formname', 'target_name', 'object_type',
        'pk_columns', 'alias_custom', 'selector_config', 'where_clause', 'decode_columns', 'rls_mode', 'rls_column',
        'sync_frequency', 'orderby', 'active'
    ],
    'Table config_publi_table should have the correct columns'
);

SELECT col_type_is('config_publi_table', 'id', 'integer', 'Column id should be integer');
SELECT col_type_is('config_publi_table', 'pk_columns', 'text[]', 'Column pk_columns should be text[]');
SELECT col_type_is('config_publi_table', 'selector_config', 'jsonb', 'Column selector_config should be jsonb');
SELECT col_type_is('config_publi_table', 'decode_columns', 'boolean', 'Column decode_columns should be boolean');
SELECT col_not_null('config_publi_table', 'target_name', 'Column target_name should be NOT NULL');
SELECT col_default_is('config_publi_table', 'rls_mode', 'expl', 'Column rls_mode should default to expl');

SELECT has_pk('config_publi_table', 'Table config_publi_table should have a primary key');
SELECT col_is_unique('config_publi_table', 'target_name', 'Column target_name should be unique');

SELECT throws_ok(
    $$INSERT INTO config_publi_table (source_schema, source_relation, target_name, object_type, pk_columns, rls_mode)
    VALUES ('ws', 've_arc', 'tst_bad_rls', 'parent', '{arc_id}', 'dma')$$,
    '23514', NULL, 'rls_mode outside expl/sector/none should be rejected'
);

SELECT throws_ok(
    $$INSERT INTO config_publi_table (source_schema, source_relation, target_name, object_type, pk_columns)
    VALUES ('ws', 've_arc', 'tst_no_pk', 'parent', '{}')$$,
    '23514', NULL, 'Empty pk_columns should be rejected'
);

SELECT * FROM finish();

ROLLBACK;

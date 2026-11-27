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

SELECT has_table('sync_log'::name, 'Table sync_log should exist');

SELECT columns_are(
    'sync_log',
    ARRAY[
        'id', 'target_name', 'mode', 'rows_inserted', 'rows_updated', 'rows_deleted', 'structure_changed',
        'details', 'tstamp_start', 'tstamp_end', 'error'
    ],
    'Table sync_log should have the correct columns'
);

SELECT col_type_is('sync_log', 'id', 'bigint', 'Column id should be bigint');
SELECT col_type_is('sync_log', 'details', 'jsonb', 'Column details should be jsonb');
SELECT col_type_is('sync_log', 'tstamp_start', 'timestamp without time zone', 'Column tstamp_start should be timestamp');

SELECT has_pk('sync_log', 'Table sync_log should have a primary key');
SELECT has_index('sync_log', 'sync_log_target_tstamp_idx', 'Index sync_log_target_tstamp_idx should exist');

SELECT * FROM finish();

ROLLBACK;

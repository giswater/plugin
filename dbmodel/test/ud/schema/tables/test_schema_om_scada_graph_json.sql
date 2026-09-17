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
SELECT has_table('om_scada_graph_json'::name, 'Table om_scada_graph_json should exist');

-- Check columns
SELECT columns_are(
    'om_scada_graph_json',
    ARRAY[
        'group_id', 'expl_id', 'om_scada_graph_json', 'insert_tstamp', 'update_tstamp'
    ],
    'Table om_scada_graph_json should have the correct columns'
);

SELECT is(
    (SELECT array_agg(attname::text ORDER BY attnum)
     FROM pg_attribute
     WHERE attrelid = 'om_scada_graph_json'::regclass
       AND attnum > 0 AND NOT attisdropped),
    ARRAY['group_id', 'expl_id', 'om_scada_graph_json', 'insert_tstamp', 'update_tstamp']::text[],
    'PK group_id should be the first column'
);

-- Check primary key
SELECT has_pk('om_scada_graph_json', 'Table om_scada_graph_json should have a primary key');
SELECT col_is_pk('om_scada_graph_json', ARRAY['group_id'], 'Primary key should be on group_id');

-- Check column types
SELECT col_type_is('om_scada_graph_json', 'group_id', 'int4', 'Column group_id should be int4');
SELECT col_type_is('om_scada_graph_json', 'expl_id', 'int4[]', 'Column expl_id should be int4[]');
SELECT col_type_is('om_scada_graph_json', 'om_scada_graph_json', 'json', 'Column om_scada_graph_json should be json');
SELECT col_type_is('om_scada_graph_json', 'insert_tstamp', 'timestamp without time zone', 'Column insert_tstamp should be timestamp without time zone');
SELECT col_type_is('om_scada_graph_json', 'update_tstamp', 'timestamp without time zone', 'Column update_tstamp should be timestamp without time zone');

SELECT * FROM finish();

ROLLBACK;

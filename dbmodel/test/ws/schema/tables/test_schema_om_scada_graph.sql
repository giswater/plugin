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
SELECT has_table('om_scada_graph'::name, 'Table om_scada_graph should exist');

-- Check columns
SELECT columns_are(
    'om_scada_graph',
    ARRAY[
        'node_1', 'node_2', 'group_id', 'order_id', 'node_type_1', 'node_type_2',
        'expl_id', 'attrib', 'active', 'the_geom'
    ],
    'Table om_scada_graph should have the correct columns'
);

-- Check primary key
SELECT has_pk('om_scada_graph', 'Table om_scada_graph should have a primary key');
SELECT col_is_pk('om_scada_graph', ARRAY['node_1', 'node_2'], 'Primary key should be on node_1, node_2');

-- Check column types
SELECT col_type_is('om_scada_graph', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('om_scada_graph', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('om_scada_graph', 'group_id', 'int4', 'Column group_id should be int4');
SELECT col_type_is('om_scada_graph', 'order_id', 'int4', 'Column order_id should be int4');
SELECT col_type_is('om_scada_graph', 'node_type_1', 'text', 'Column node_type_1 should be text');
SELECT col_type_is('om_scada_graph', 'node_type_2', 'text', 'Column node_type_2 should be text');
SELECT col_type_is('om_scada_graph', 'expl_id', 'int4[]', 'Column expl_id should be int4[]');
SELECT col_type_is('om_scada_graph', 'attrib', 'text', 'Column attrib should be text');
SELECT col_type_is('om_scada_graph', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('om_scada_graph', 'the_geom', 'geometry(multilinestring, SRID_VALUE)', 'Column the_geom should be geometry(multilinestring, SRID_VALUE)');

-- Check indexes
SELECT has_index('om_scada_graph', 'om_scada_graph_node_1_idx', ARRAY['node_1'], 'Index on node_1');
SELECT has_index('om_scada_graph', 'om_scada_graph_node_2_idx', ARRAY['node_2'], 'Index on node_2');

-- Check triggers
SELECT has_trigger('om_scada_graph', 'gw_trg_scada_graph_builder_before', 'Trigger gw_trg_scada_graph_builder_before exists');
SELECT has_trigger('om_scada_graph', 'gw_trg_scada_graph_builder_after', 'Trigger gw_trg_scada_graph_builder_after exists');

SELECT * FROM finish();

ROLLBACK;

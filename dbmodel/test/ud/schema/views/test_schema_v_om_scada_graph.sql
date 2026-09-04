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

-- Check view
SELECT has_view('v_om_scada_graph'::name, 'View v_om_scada_graph should exist');

-- Check view columns
SELECT columns_are(
    'v_om_scada_graph',
    ARRAY[
        'group_id', 'order_id', 'node_1', 'node_type_1', 'sys_code_1', 'expl_id_1',
        'dma_id_1', 'dma_name_1', 'node_2', 'node_type_2', 'sys_code_2', 'expl_id_2',
        'dma_id_2', 'dma_name_2', 'expl_id', 'attrib', 'active', 'the_geom'
    ],
    'View v_om_scada_graph should have the correct columns'
);

-- Check column types
SELECT col_type_is('v_om_scada_graph', 'group_id', 'int4', 'Column group_id should be int4');
SELECT col_type_is('v_om_scada_graph', 'order_id', 'int4', 'Column order_id should be int4');
SELECT col_type_is('v_om_scada_graph', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('v_om_scada_graph', 'node_type_1', 'text', 'Column node_type_1 should be text');
SELECT col_type_is('v_om_scada_graph', 'sys_code_1', 'text', 'Column sys_code_1 should be text');
SELECT col_type_is('v_om_scada_graph', 'expl_id_1', 'int4', 'Column expl_id_1 should be int4');
SELECT col_type_is('v_om_scada_graph', 'dma_id_1', 'int4', 'Column dma_id_1 should be int4');
SELECT col_type_is('v_om_scada_graph', 'dma_name_1', 'varchar(100)', 'Column dma_name_1 should be varchar(100)');
SELECT col_type_is('v_om_scada_graph', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('v_om_scada_graph', 'node_type_2', 'text', 'Column node_type_2 should be text');
SELECT col_type_is('v_om_scada_graph', 'sys_code_2', 'text', 'Column sys_code_2 should be text');
SELECT col_type_is('v_om_scada_graph', 'expl_id_2', 'int4', 'Column expl_id_2 should be int4');
SELECT col_type_is('v_om_scada_graph', 'dma_id_2', 'int4', 'Column dma_id_2 should be int4');
SELECT col_type_is('v_om_scada_graph', 'dma_name_2', 'varchar(100)', 'Column dma_name_2 should be varchar(100)');
SELECT col_type_is('v_om_scada_graph', 'expl_id', 'int4[]', 'Column expl_id should be int4[]');
SELECT col_type_is('v_om_scada_graph', 'attrib', 'text', 'Column attrib should be text');
SELECT col_type_is('v_om_scada_graph', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('v_om_scada_graph', 'the_geom', 'geometry(multilinestring, SRID_VALUE)', 'Column the_geom should be geometry(multilinestring, SRID_VALUE)');

SELECT * FROM finish();

ROLLBACK;

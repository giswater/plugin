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
SELECT has_table('rpt_node_stats'::name, 'Table rpt_node_stats should exist');

-- Check columns
SELECT columns_are(
    'rpt_node_stats',
    ARRAY[
        'node_id', 'result_id', 'node_type', 'sector_id', 'nodecat_id', 'top_elev',
        'demand_max', 't_demand_max', 'demand_min', 't_demand_min', 'demand_avg',
        'head_max', 't_head_max', 'head_min', 't_head_min', 'head_avg',
        'press_max', 't_press_max', 'press_min', 't_press_min', 'press_avg',
        'quality_max', 't_quality_max', 'quality_min', 't_quality_min', 'quality_avg',
        'the_geom'
    ],
    'Table rpt_node_stats should have the correct columns'
);

-- Check column types
SELECT col_type_is('rpt_node_stats', 'node_id', 'varchar(16)', 'Column node_id should be varchar(16)');
SELECT col_type_is('rpt_node_stats', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('rpt_node_stats', 'node_type', 'varchar(30)', 'Column node_type should be varchar(30)');
SELECT col_type_is('rpt_node_stats', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('rpt_node_stats', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('rpt_node_stats', 'top_elev', 'numeric', 'Column top_elev should be numeric');
SELECT col_type_is('rpt_node_stats', 'demand_max', 'numeric', 'Column demand_max should be numeric');
SELECT col_type_is('rpt_node_stats', 't_demand_max', 'varchar(100)', 'Column t_demand_max should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'demand_min', 'numeric', 'Column demand_min should be numeric');
SELECT col_type_is('rpt_node_stats', 't_demand_min', 'varchar(100)', 'Column t_demand_min should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'demand_avg', 'numeric(12,2)', 'Column demand_avg should be numeric(12,2)');
SELECT col_type_is('rpt_node_stats', 'head_max', 'numeric', 'Column head_max should be numeric');
SELECT col_type_is('rpt_node_stats', 't_head_max', 'varchar(100)', 'Column t_head_max should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'head_min', 'numeric', 'Column head_min should be numeric');
SELECT col_type_is('rpt_node_stats', 't_head_min', 'varchar(100)', 'Column t_head_min should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'head_avg', 'numeric(12,2)', 'Column head_avg should be numeric(12,2)');
SELECT col_type_is('rpt_node_stats', 'press_max', 'numeric', 'Column press_max should be numeric');
SELECT col_type_is('rpt_node_stats', 't_press_max', 'varchar(100)', 'Column t_press_max should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'press_min', 'numeric', 'Column press_min should be numeric');
SELECT col_type_is('rpt_node_stats', 't_press_min', 'varchar(100)', 'Column t_press_min should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'press_avg', 'numeric(12,2)', 'Column press_avg should be numeric(12,2)');
SELECT col_type_is('rpt_node_stats', 'quality_max', 'numeric', 'Column quality_max should be numeric');
SELECT col_type_is('rpt_node_stats', 't_quality_max', 'varchar(100)', 'Column t_quality_max should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'quality_min', 'numeric', 'Column quality_min should be numeric');
SELECT col_type_is('rpt_node_stats', 't_quality_min', 'varchar(100)', 'Column t_quality_min should be varchar(100)');
SELECT col_type_is('rpt_node_stats', 'quality_avg', 'numeric(12,2)', 'Column quality_avg should be numeric(12,2)');
SELECT col_type_is('rpt_node_stats', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');

-- Check foreign keys
SELECT has_fk('rpt_node_stats', 'Table rpt_node_stats should have foreign keys');

SELECT fk_ok('rpt_node_stats', 'result_id', 'rpt_cat_result', 'result_id', 'FK result_id → rpt_cat_result.result_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

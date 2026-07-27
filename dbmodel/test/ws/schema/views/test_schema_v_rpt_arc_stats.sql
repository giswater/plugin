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

-- Check view v_rpt_arc_stats
SELECT has_view('v_rpt_arc_stats'::name, 'View v_rpt_arc_stats should exist');

-- Check view columns
SELECT columns_are(
    'v_rpt_arc_stats',
    ARRAY[
        'arc_id', 'result_id', 'flow_units', 'quality_units', 'arc_type', 'sector_id',
        'arccat_id', 'flow_max', 't_flow_max', 'flow_min', 't_flow_min', 'flow_avg',
        'vel_max', 't_vel_max', 'vel_min', 't_vel_min', 'vel_avg',
        'headloss_max', 't_headloss_max', 'headloss_min', 't_headloss_min',
        'setting_max', 't_setting_max', 'setting_min', 't_setting_min',
        'reaction_max', 't_reaction_max', 'reaction_min', 't_reaction_min',
        'ffactor_max', 't_ffactor_max', 'ffactor_min', 't_ffactor_min',
        'length', 'tot_headloss_max', 'tot_headloss_min', 'diameter', 'the_geom'
    ],
    'View v_rpt_arc_stats should have the correct columns'
);

-- Check column types
SELECT col_type_is('v_rpt_arc_stats', 'arc_id', 'varchar(16)', 'Column arc_id should be varchar(16)');
SELECT col_type_is('v_rpt_arc_stats', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('v_rpt_arc_stats', 'flow_units', 'text', 'Column flow_units should be text');
SELECT col_type_is('v_rpt_arc_stats', 'quality_units', 'text', 'Column quality_units should be text');
SELECT col_type_is('v_rpt_arc_stats', 'arc_type', 'varchar(30)', 'Column arc_type should be varchar(30)');
SELECT col_type_is('v_rpt_arc_stats', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('v_rpt_arc_stats', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('v_rpt_arc_stats', 'flow_max', 'numeric', 'Column flow_max should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_flow_max', 'varchar(100)', 'Column t_flow_max should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'flow_min', 'numeric', 'Column flow_min should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_flow_min', 'varchar(100)', 'Column t_flow_min should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'flow_avg', 'numeric(12,2)', 'Column flow_avg should be numeric(12,2)');
SELECT col_type_is('v_rpt_arc_stats', 'vel_max', 'numeric', 'Column vel_max should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_vel_max', 'varchar(100)', 'Column t_vel_max should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'vel_min', 'numeric', 'Column vel_min should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_vel_min', 'varchar(100)', 'Column t_vel_min should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'vel_avg', 'numeric(12,2)', 'Column vel_avg should be numeric(12,2)');
SELECT col_type_is('v_rpt_arc_stats', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_headloss_max', 'varchar(100)', 'Column t_headloss_max should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_headloss_min', 'varchar(100)', 'Column t_headloss_min should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_setting_max', 'varchar(100)', 'Column t_setting_max should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_setting_min', 'varchar(100)', 'Column t_setting_min should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_reaction_max', 'varchar(100)', 'Column t_reaction_max should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_reaction_min', 'varchar(100)', 'Column t_reaction_min should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_ffactor_max', 'varchar(100)', 'Column t_ffactor_max should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 't_ffactor_min', 'varchar(100)', 'Column t_ffactor_min should be varchar(100)');
SELECT col_type_is('v_rpt_arc_stats', 'length', 'numeric', 'Column length should be numeric');
SELECT col_type_is('v_rpt_arc_stats', 'tot_headloss_max', 'numeric(12,2)', 'Column tot_headloss_max should be numeric(12,2)');
SELECT col_type_is('v_rpt_arc_stats', 'tot_headloss_min', 'numeric(12,2)', 'Column tot_headloss_min should be numeric(12,2)');
SELECT col_type_is('v_rpt_arc_stats', 'diameter', 'numeric(12,3)', 'Column diameter should be numeric(12,3)');
SELECT col_type_is('v_rpt_arc_stats', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');

SELECT * FROM finish();

ROLLBACK;

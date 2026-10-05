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

-- Check view ve_epa_pipe
SELECT has_view('ve_epa_pipe'::name, 'View ve_epa_pipe should exist');
SELECT has_trigger('ve_epa_pipe', 'gw_trg_edit_ve_epa_pipe',
    'View ve_epa_pipe should have gw_trg_edit_ve_epa_pipe');

-- Check view columns
SELECT columns_are(
    've_epa_pipe',
    ARRAY[
        'arc_id', 'minorloss', 'status', 'matcat_id', 'builtdate', 'cat_roughness',
        'custom_roughness', 'dint', 'custom_dint', 'reactionparam', 'reactionvalue', 'bulk_coeff',
        'wall_coeff', 'result_id', 'flow_max', 'flow_min', 'flow_avg', 'vel_max',
        'vel_min', 'vel_avg', 'headloss_max', 'headloss_min', 'setting_max', 'setting_min',
        'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min', 'tot_headloss_max', 'tot_headloss_min'
    ],
    'View ve_epa_pipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_pipe', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_epa_pipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_epa_pipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_pipe', 'matcat_id', 'varchar(30)', 'Column matcat_id should be varchar(30)');
SELECT col_type_is('ve_epa_pipe', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_epa_pipe', 'cat_roughness', 'numeric(12,4)', 'Column cat_roughness should be numeric(12,4)');
SELECT col_type_is('ve_epa_pipe', 'custom_roughness', 'numeric(12,4)', 'Column custom_roughness should be numeric(12,4)');
SELECT col_type_is('ve_epa_pipe', 'dint', 'numeric(12,5)', 'Column dint should be numeric(12,5)');
SELECT col_type_is('ve_epa_pipe', 'custom_dint', 'numeric(12,3)', 'Column custom_dint should be numeric(12,3)');
SELECT col_type_is('ve_epa_pipe', 'reactionparam', 'varchar(30)', 'Column reactionparam should be varchar(30)');
SELECT col_type_is('ve_epa_pipe', 'reactionvalue', 'varchar(30)', 'Column reactionvalue should be varchar(30)');
SELECT col_type_is('ve_epa_pipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_epa_pipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_epa_pipe', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_pipe', 'flow_max', 'numeric', 'Column flow_max should be numeric');
SELECT col_type_is('ve_epa_pipe', 'flow_min', 'numeric', 'Column flow_min should be numeric');
SELECT col_type_is('ve_epa_pipe', 'flow_avg', 'numeric(12,2)', 'Column flow_avg should be numeric(12,2)');
SELECT col_type_is('ve_epa_pipe', 'vel_max', 'numeric', 'Column vel_max should be numeric');
SELECT col_type_is('ve_epa_pipe', 'vel_min', 'numeric', 'Column vel_min should be numeric');
SELECT col_type_is('ve_epa_pipe', 'vel_avg', 'numeric(12,2)', 'Column vel_avg should be numeric(12,2)');
SELECT col_type_is('ve_epa_pipe', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_pipe', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_pipe', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_pipe', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_pipe', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_pipe', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_pipe', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_pipe', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');
SELECT col_type_is('ve_epa_pipe', 'tot_headloss_max', 'numeric(12,2)', 'Column tot_headloss_max should be numeric(12,2)');
SELECT col_type_is('ve_epa_pipe', 'tot_headloss_min', 'numeric(12,2)', 'Column tot_headloss_min should be numeric(12,2)');

SELECT * FROM finish();

ROLLBACK;

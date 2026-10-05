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

-- Check view ve_epa_link
SELECT has_view('ve_epa_link'::name, 'View ve_epa_link should exist');
SELECT has_trigger('ve_epa_link', 'gw_trg_edit_ve_epa_link',
    'View ve_epa_link should have gw_trg_edit_ve_epa_link');

-- Check view columns
SELECT columns_are(
    've_epa_link',
    ARRAY[
        'link_id', 'minorloss', 'status', 'matcat_id', 'cat_roughness', 'custom_roughness',
        'dint', 'custom_dint', 'custom_length', 'result_id', 'flow_max', 'flow_min',
        'flow_avg', 'vel_max', 'vel_min', 'vel_avg', 'headloss_max', 'headloss_min',
        'setting_max', 'setting_min', 'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min',
        'tot_headloss_max', 'tot_headloss_min'
    ],
    'View ve_epa_link should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_link', 'link_id', 'int4', 'Column link_id should be int4');
SELECT col_type_is('ve_epa_link', 'minorloss', 'float8', 'Column minorloss should be float8');
SELECT col_type_is('ve_epa_link', 'status', 'varchar(16)', 'Column status should be varchar(16)');
SELECT col_type_is('ve_epa_link', 'matcat_id', 'varchar(30)', 'Column matcat_id should be varchar(30)');
SELECT col_type_is('ve_epa_link', 'cat_roughness', 'numeric(12,4)', 'Column cat_roughness should be numeric(12,4)');
SELECT col_type_is('ve_epa_link', 'custom_roughness', 'float8', 'Column custom_roughness should be float8');
SELECT col_type_is('ve_epa_link', 'dint', 'numeric(12,5)', 'Column dint should be numeric(12,5)');
SELECT col_type_is('ve_epa_link', 'custom_dint', 'float8', 'Column custom_dint should be float8');
SELECT col_type_is('ve_epa_link', 'custom_length', 'float8', 'Column custom_length should be float8');
SELECT col_type_is('ve_epa_link', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_link', 'flow_max', 'numeric', 'Column flow_max should be numeric');
SELECT col_type_is('ve_epa_link', 'flow_min', 'numeric', 'Column flow_min should be numeric');
SELECT col_type_is('ve_epa_link', 'flow_avg', 'numeric(12,2)', 'Column flow_avg should be numeric(12,2)');
SELECT col_type_is('ve_epa_link', 'vel_max', 'numeric', 'Column vel_max should be numeric');
SELECT col_type_is('ve_epa_link', 'vel_min', 'numeric', 'Column vel_min should be numeric');
SELECT col_type_is('ve_epa_link', 'vel_avg', 'numeric(12,2)', 'Column vel_avg should be numeric(12,2)');
SELECT col_type_is('ve_epa_link', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_link', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_link', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_link', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_link', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_link', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_link', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_link', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');
SELECT col_type_is('ve_epa_link', 'tot_headloss_max', 'numeric(12,2)', 'Column tot_headloss_max should be numeric(12,2)');
SELECT col_type_is('ve_epa_link', 'tot_headloss_min', 'numeric(12,2)', 'Column tot_headloss_min should be numeric(12,2)');

SELECT * FROM finish();

ROLLBACK;

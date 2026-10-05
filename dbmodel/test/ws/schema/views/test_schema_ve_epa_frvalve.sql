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

-- Check view ve_epa_frvalve
SELECT has_view('ve_epa_frvalve'::name, 'View ve_epa_frvalve should exist');
SELECT has_trigger('ve_epa_frvalve', 'gw_trg_edit_ve_epa_frvalve',
    'View ve_epa_frvalve should have gw_trg_edit_ve_epa_frvalve');

-- Check view columns
SELECT columns_are(
    've_epa_frvalve',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'valve_type', 'custom_dint', 'setting',
        'curve_id', 'minorloss', 'add_settings', 'init_quality', 'status', 'flow_max',
        'flow_min', 'flow_avg', 'vel_max', 'vel_min', 'vel_avg', 'headloss_max',
        'headloss_min', 'setting_max', 'setting_min', 'reaction_max', 'reaction_min', 'ffactor_max',
        'ffactor_min'
    ],
    'View ve_epa_frvalve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_frvalve', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_epa_frvalve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_frvalve', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_epa_frvalve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_epa_frvalve', 'custom_dint', 'numeric(12,4)', 'Column custom_dint should be numeric(12,4)');
SELECT col_type_is('ve_epa_frvalve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_epa_frvalve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_frvalve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_epa_frvalve', 'add_settings', 'float8', 'Column add_settings should be float8');
SELECT col_type_is('ve_epa_frvalve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_epa_frvalve', 'status', 'varchar(16)', 'Column status should be varchar(16)');
SELECT col_type_is('ve_epa_frvalve', 'flow_max', 'numeric', 'Column flow_max should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'flow_min', 'numeric', 'Column flow_min should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'flow_avg', 'numeric(12,2)', 'Column flow_avg should be numeric(12,2)');
SELECT col_type_is('ve_epa_frvalve', 'vel_max', 'numeric', 'Column vel_max should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'vel_min', 'numeric', 'Column vel_min should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'vel_avg', 'numeric(12,2)', 'Column vel_avg should be numeric(12,2)');
SELECT col_type_is('ve_epa_frvalve', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_frvalve', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');

SELECT * FROM finish();

ROLLBACK;

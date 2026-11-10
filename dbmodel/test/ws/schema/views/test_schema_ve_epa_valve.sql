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

-- Check view ve_epa_valve
SELECT has_view('ve_epa_valve'::name, 'View ve_epa_valve should exist');
SELECT has_trigger('ve_epa_valve', 'gw_trg_edit_ve_epa_valve',
    'View ve_epa_valve should have gw_trg_edit_ve_epa_valve');

-- Check view columns
SELECT columns_are(
    've_epa_valve',
    ARRAY[
        'node_id', 'valve_type', 'dint', 'custom_dint', 'setting', 'curve_id',
        'minorloss', 'to_arc', 'status', 'add_settings', 'init_quality', 'head',
        'pattern_id', 'demand', 'demand_pattern_id', 'emitter_coeff', 'result_id', 'flowmax',
        'flowmin', 'flowavg', 'velmax', 'velmin', 'velavg', 'headloss_max',
        'headloss_min', 'setting_max', 'setting_min', 'reaction_max', 'reaction_min', 'ffactor_max',
        'ffactor_min', 'nodarc_id'
    ],
    'View ve_epa_valve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_valve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_valve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_epa_valve', 'dint', 'numeric(12,5)', 'Column dint should be numeric(12,5)');
SELECT col_type_is('ve_epa_valve', 'custom_dint', 'numeric(12,4)', 'Column custom_dint should be numeric(12,4)');
SELECT col_type_is('ve_epa_valve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_epa_valve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_valve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_epa_valve', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_epa_valve', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_valve', 'add_settings', 'float8', 'Column add_settings should be float8');
SELECT col_type_is('ve_epa_valve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_epa_valve', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_epa_valve', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_epa_valve', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_epa_valve', 'demand_pattern_id', 'varchar(16)', 'Column demand_pattern_id should be varchar(16)');
SELECT col_type_is('ve_epa_valve', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_epa_valve', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_valve', 'flowmax', 'numeric', 'Column flowmax should be numeric');
SELECT col_type_is('ve_epa_valve', 'flowmin', 'numeric', 'Column flowmin should be numeric');
SELECT col_type_is('ve_epa_valve', 'flowavg', 'numeric(12,2)', 'Column flowavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_valve', 'velmax', 'numeric', 'Column velmax should be numeric');
SELECT col_type_is('ve_epa_valve', 'velmin', 'numeric', 'Column velmin should be numeric');
SELECT col_type_is('ve_epa_valve', 'velavg', 'numeric(12,2)', 'Column velavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_valve', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_valve', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_valve', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_valve', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_valve', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_valve', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_valve', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_valve', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');
SELECT col_type_is('ve_epa_valve', 'nodarc_id', 'varchar(16)', 'Column nodarc_id should be varchar(16)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_pump
SELECT has_view('ve_epa_pump'::name, 'View ve_epa_pump should exist');
SELECT has_trigger('ve_epa_pump', 'gw_trg_edit_ve_epa_pump',
    'View ve_epa_pump should have gw_trg_edit_ve_epa_pump');

-- Check view columns
SELECT columns_are(
    've_epa_pump',
    ARRAY[
        'node_id', 'power', 'curve_id', 'speed', 'pattern_id', 'status',
        'to_arc', 'energyparam', 'energyvalue', 'pump_type', 'effic_curve_id', 'energy_price',
        'energy_pattern_id', 'result_id', 'flowmax', 'flowmin', 'flowavg', 'velmax',
        'velmin', 'velavg', 'headloss_max', 'headloss_min', 'setting_max', 'setting_min',
        'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min', 'nodarc_id'
    ],
    'View ve_epa_pump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_pump', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_pump', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('ve_epa_pump', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('ve_epa_pump', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('ve_epa_pump', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('ve_epa_pump', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_pump', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_epa_pump', 'energyparam', 'varchar(30)', 'Column energyparam should be varchar(30)');
SELECT col_type_is('ve_epa_pump', 'energyvalue', 'varchar(30)', 'Column energyvalue should be varchar(30)');
SELECT col_type_is('ve_epa_pump', 'pump_type', 'varchar(16)', 'Column pump_type should be varchar(16)');
SELECT col_type_is('ve_epa_pump', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('ve_epa_pump', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('ve_epa_pump', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('ve_epa_pump', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_pump', 'flowmax', 'numeric', 'Column flowmax should be numeric');
SELECT col_type_is('ve_epa_pump', 'flowmin', 'numeric', 'Column flowmin should be numeric');
SELECT col_type_is('ve_epa_pump', 'flowavg', 'numeric(12,2)', 'Column flowavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_pump', 'velmax', 'numeric', 'Column velmax should be numeric');
SELECT col_type_is('ve_epa_pump', 'velmin', 'numeric', 'Column velmin should be numeric');
SELECT col_type_is('ve_epa_pump', 'velavg', 'numeric(12,2)', 'Column velavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_pump', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_pump', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_pump', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_pump', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_pump', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_pump', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_pump', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_pump', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');
SELECT col_type_is('ve_epa_pump', 'nodarc_id', 'varchar(16)', 'Column nodarc_id should be varchar(16)');

SELECT * FROM finish();

ROLLBACK;

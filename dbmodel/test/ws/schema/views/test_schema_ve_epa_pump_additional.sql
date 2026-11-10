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

-- Check view ve_epa_pump_additional
SELECT has_view('ve_epa_pump_additional'::name, 'View ve_epa_pump_additional should exist');
SELECT has_trigger('ve_epa_pump_additional', 'gw_trg_edit_ve_epa_pump_additional',
    'View ve_epa_pump_additional should have gw_trg_edit_ve_epa_pump_additional');

-- Check view columns
SELECT columns_are(
    've_epa_pump_additional',
    ARRAY[
        'id', 'node_id', 'order_id', 'power', 'curve_id', 'speed',
        'pattern_id', 'status', 'energyparam', 'energyvalue', 'effic_curve_id', 'energy_price',
        'energy_pattern_id', 'result_id', 'flowmax', 'flowmin', 'flowavg', 'velmax',
        'velmin', 'velavg', 'headloss_max', 'headloss_min', 'setting_max', 'setting_min',
        'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min', 'nodarc_id'
    ],
    'View ve_epa_pump_additional should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_pump_additional', 'id', 'int4', 'Column id should be int4');
SELECT col_type_is('ve_epa_pump_additional', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_pump_additional', 'order_id', 'int2', 'Column order_id should be int2');
SELECT col_type_is('ve_epa_pump_additional', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('ve_epa_pump_additional', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('ve_epa_pump_additional', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('ve_epa_pump_additional', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('ve_epa_pump_additional', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_pump_additional', 'energyparam', 'varchar(30)', 'Column energyparam should be varchar(30)');
SELECT col_type_is('ve_epa_pump_additional', 'energyvalue', 'varchar(30)', 'Column energyvalue should be varchar(30)');
SELECT col_type_is('ve_epa_pump_additional', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('ve_epa_pump_additional', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('ve_epa_pump_additional', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('ve_epa_pump_additional', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_pump_additional', 'flowmax', 'numeric', 'Column flowmax should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'flowmin', 'numeric', 'Column flowmin should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'flowavg', 'numeric(12,2)', 'Column flowavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_pump_additional', 'velmax', 'numeric', 'Column velmax should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'velmin', 'numeric', 'Column velmin should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'velavg', 'numeric(12,2)', 'Column velavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_pump_additional', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');
SELECT col_type_is('ve_epa_pump_additional', 'nodarc_id', 'varchar(16)', 'Column nodarc_id should be varchar(16)');

SELECT * FROM finish();

ROLLBACK;

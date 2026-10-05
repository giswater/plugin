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

-- Check view ve_epa_frpump
SELECT has_view('ve_epa_frpump'::name, 'View ve_epa_frpump should exist');
SELECT has_trigger('ve_epa_frpump', 'gw_trg_edit_ve_epa_frpump',
    'View ve_epa_frpump should have gw_trg_edit_ve_epa_frpump');

-- Check view columns
SELECT columns_are(
    've_epa_frpump',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'power', 'curve_id', 'speed',
        'pattern_id', 'pump_type', 'energyparam', 'energyvalue', 'effic_curve_id', 'energy_price',
        'energy_pattern_id', 'status', 'result_id', 'flowmax', 'flowmin', 'flowavg',
        'velmax', 'velmin', 'velavg', 'headloss_max', 'headloss_min', 'setting_max',
        'setting_min', 'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min'
    ],
    'View ve_epa_frpump should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_frpump', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_epa_frpump', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_frpump', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_epa_frpump', 'power', 'varchar', 'Column power should be varchar');
SELECT col_type_is('ve_epa_frpump', 'curve_id', 'varchar', 'Column curve_id should be varchar');
SELECT col_type_is('ve_epa_frpump', 'speed', 'numeric(12,6)', 'Column speed should be numeric(12,6)');
SELECT col_type_is('ve_epa_frpump', 'pattern_id', 'varchar', 'Column pattern_id should be varchar');
SELECT col_type_is('ve_epa_frpump', 'pump_type', 'varchar(16)', 'Column pump_type should be varchar(16)');
SELECT col_type_is('ve_epa_frpump', 'energyparam', 'varchar(30)', 'Column energyparam should be varchar(30)');
SELECT col_type_is('ve_epa_frpump', 'energyvalue', 'varchar(30)', 'Column energyvalue should be varchar(30)');
SELECT col_type_is('ve_epa_frpump', 'effic_curve_id', 'varchar(18)', 'Column effic_curve_id should be varchar(18)');
SELECT col_type_is('ve_epa_frpump', 'energy_price', 'float8', 'Column energy_price should be float8');
SELECT col_type_is('ve_epa_frpump', 'energy_pattern_id', 'varchar(18)', 'Column energy_pattern_id should be varchar(18)');
SELECT col_type_is('ve_epa_frpump', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_frpump', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_frpump', 'flowmax', 'numeric', 'Column flowmax should be numeric');
SELECT col_type_is('ve_epa_frpump', 'flowmin', 'numeric', 'Column flowmin should be numeric');
SELECT col_type_is('ve_epa_frpump', 'flowavg', 'numeric(12,2)', 'Column flowavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_frpump', 'velmax', 'numeric', 'Column velmax should be numeric');
SELECT col_type_is('ve_epa_frpump', 'velmin', 'numeric', 'Column velmin should be numeric');
SELECT col_type_is('ve_epa_frpump', 'velavg', 'numeric(12,2)', 'Column velavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_frpump', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_frpump', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_frpump', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_frpump', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_frpump', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_frpump', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_frpump', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_frpump', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_virtualvalve
SELECT has_view('ve_epa_virtualvalve'::name, 'View ve_epa_virtualvalve should exist');
SELECT has_trigger('ve_epa_virtualvalve', 'gw_trg_edit_ve_epa_virtualvalve',
    'View ve_epa_virtualvalve should have gw_trg_edit_ve_epa_virtualvalve');

-- Check view columns
SELECT columns_are(
    've_epa_virtualvalve',
    ARRAY[
        'arc_id', 'valve_type', 'diameter', 'setting', 'curve_id', 'minorloss',
        'status', 'init_quality', 'result_id', 'flowmax', 'flowmin', 'flowavg',
        'velmax', 'velmin', 'velavg', 'headloss_max', 'headloss_min', 'setting_max',
        'setting_min', 'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min'
    ],
    'View ve_epa_virtualvalve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_virtualvalve', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_epa_virtualvalve', 'valve_type', 'varchar(18)', 'Column valve_type should be varchar(18)');
SELECT col_type_is('ve_epa_virtualvalve', 'diameter', 'numeric(12,4)', 'Column diameter should be numeric(12,4)');
SELECT col_type_is('ve_epa_virtualvalve', 'setting', 'numeric(12,4)', 'Column setting should be numeric(12,4)');
SELECT col_type_is('ve_epa_virtualvalve', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_virtualvalve', 'minorloss', 'numeric(12,4)', 'Column minorloss should be numeric(12,4)');
SELECT col_type_is('ve_epa_virtualvalve', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_virtualvalve', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_epa_virtualvalve', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_virtualvalve', 'flowmax', 'numeric', 'Column flowmax should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'flowmin', 'numeric', 'Column flowmin should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'flowavg', 'numeric(12,2)', 'Column flowavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_virtualvalve', 'velmax', 'numeric', 'Column velmax should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'velmin', 'numeric', 'Column velmin should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'velavg', 'numeric(12,2)', 'Column velavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_virtualvalve', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_virtualvalve', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');

SELECT * FROM finish();

ROLLBACK;

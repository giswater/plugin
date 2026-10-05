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

-- Check view ve_epa_shortpipe
SELECT has_view('ve_epa_shortpipe'::name, 'View ve_epa_shortpipe should exist');
SELECT has_trigger('ve_epa_shortpipe', 'gw_trg_edit_ve_epa_shortpipe',
    'View ve_epa_shortpipe should have gw_trg_edit_ve_epa_shortpipe');

-- Check view columns
SELECT columns_are(
    've_epa_shortpipe',
    ARRAY[
        'node_id', 'minorloss', 'dint', 'custom_dint', 'to_arc', 'status',
        'bulk_coeff', 'wall_coeff', 'head', 'pattern_id', 'demand', 'demand_pattern_id',
        'emitter_coeff', 'result_id', 'flowmax', 'flowmin', 'flowavg', 'velmax',
        'velmin', 'velavg', 'headloss_max', 'headloss_min', 'setting_max', 'setting_min',
        'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min', 'nodarc_id'
    ],
    'View ve_epa_shortpipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_shortpipe', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_shortpipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_epa_shortpipe', 'dint', 'numeric(12,5)', 'Column dint should be numeric(12,5)');
SELECT col_type_is('ve_epa_shortpipe', 'custom_dint', 'int4', 'Column custom_dint should be int4');
SELECT col_type_is('ve_epa_shortpipe', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_epa_shortpipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_shortpipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_epa_shortpipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_epa_shortpipe', 'head', 'float8', 'Column head should be float8');
SELECT col_type_is('ve_epa_shortpipe', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_epa_shortpipe', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_epa_shortpipe', 'demand_pattern_id', 'varchar(16)', 'Column demand_pattern_id should be varchar(16)');
SELECT col_type_is('ve_epa_shortpipe', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_epa_shortpipe', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_shortpipe', 'flowmax', 'numeric', 'Column flowmax should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'flowmin', 'numeric', 'Column flowmin should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'flowavg', 'numeric(12,2)', 'Column flowavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_shortpipe', 'velmax', 'numeric', 'Column velmax should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'velmin', 'numeric', 'Column velmin should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'velavg', 'numeric(12,2)', 'Column velavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_shortpipe', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');
SELECT col_type_is('ve_epa_shortpipe', 'nodarc_id', 'varchar(16)', 'Column nodarc_id should be varchar(16)');

SELECT * FROM finish();

ROLLBACK;

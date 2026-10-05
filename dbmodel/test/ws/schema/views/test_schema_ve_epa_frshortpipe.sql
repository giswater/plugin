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

-- Check view ve_epa_frshortpipe
SELECT has_view('ve_epa_frshortpipe'::name, 'View ve_epa_frshortpipe should exist');
SELECT has_trigger('ve_epa_frshortpipe', 'gw_trg_edit_ve_epa_frshortpipe',
    'View ve_epa_frshortpipe should have gw_trg_edit_ve_epa_frshortpipe');

-- Check view columns
SELECT columns_are(
    've_epa_frshortpipe',
    ARRAY[
        'element_id', 'node_id', 'to_arc', 'minorloss', 'custom_dint', 'status',
        'bulk_coeff', 'wall_coeff', 'result_id', 'flowmax', 'flowmin', 'flowavg',
        'velmax', 'velmin', 'velavg', 'headloss_max', 'headloss_min', 'setting_max',
        'setting_min', 'reaction_max', 'reaction_min', 'ffactor_max', 'ffactor_min'
    ],
    'View ve_epa_frshortpipe should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_frshortpipe', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_epa_frshortpipe', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_frshortpipe', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_epa_frshortpipe', 'minorloss', 'numeric(12,6)', 'Column minorloss should be numeric(12,6)');
SELECT col_type_is('ve_epa_frshortpipe', 'custom_dint', 'int4', 'Column custom_dint should be int4');
SELECT col_type_is('ve_epa_frshortpipe', 'status', 'varchar(12)', 'Column status should be varchar(12)');
SELECT col_type_is('ve_epa_frshortpipe', 'bulk_coeff', 'float8', 'Column bulk_coeff should be float8');
SELECT col_type_is('ve_epa_frshortpipe', 'wall_coeff', 'float8', 'Column wall_coeff should be float8');
SELECT col_type_is('ve_epa_frshortpipe', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_frshortpipe', 'flowmax', 'numeric', 'Column flowmax should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'flowmin', 'numeric', 'Column flowmin should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'flowavg', 'numeric(12,2)', 'Column flowavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_frshortpipe', 'velmax', 'numeric', 'Column velmax should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'velmin', 'numeric', 'Column velmin should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'velavg', 'numeric(12,2)', 'Column velavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_frshortpipe', 'headloss_max', 'numeric', 'Column headloss_max should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'headloss_min', 'numeric', 'Column headloss_min should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'setting_max', 'numeric', 'Column setting_max should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'setting_min', 'numeric', 'Column setting_min should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'reaction_max', 'numeric', 'Column reaction_max should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'reaction_min', 'numeric', 'Column reaction_min should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'ffactor_max', 'numeric', 'Column ffactor_max should be numeric');
SELECT col_type_is('ve_epa_frshortpipe', 'ffactor_min', 'numeric', 'Column ffactor_min should be numeric');

SELECT * FROM finish();

ROLLBACK;

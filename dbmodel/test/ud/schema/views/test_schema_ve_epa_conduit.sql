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

-- Check view ve_epa_conduit
SELECT has_view('ve_epa_conduit'::name, 'View ve_epa_conduit should exist');
SELECT has_trigger('ve_epa_conduit', 'gw_trg_edit_ve_epa_conduit',
    'View ve_epa_conduit should have gw_trg_edit_ve_epa_conduit');

-- Check view columns
SELECT columns_are(
    've_epa_conduit',
    ARRAY[
        'arc_id', 'barrels', 'culvert', 'kentry', 'kexit', 'kavg',
        'flap', 'q0', 'qmax', 'seepage', 'custom_n', 'max_flow',
        'time_days', 'time_hour', 'max_veloc', 'mfull_flow', 'mfull_depth', 'max_shear',
        'max_hr', 'max_slope', 'day_max', 'time_max', 'min_shear', 'day_min',
        'time_min'
    ],
    'View ve_epa_conduit should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_conduit', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_epa_conduit', 'barrels', 'int2', 'Column barrels should be int2');
SELECT col_type_is('ve_epa_conduit', 'culvert', 'varchar(10)', 'Column culvert should be varchar(10)');
SELECT col_type_is('ve_epa_conduit', 'kentry', 'numeric(12,4)', 'Column kentry should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'kexit', 'numeric(12,4)', 'Column kexit should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'kavg', 'numeric(12,4)', 'Column kavg should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_epa_conduit', 'q0', 'numeric(12,4)', 'Column q0 should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'qmax', 'numeric(12,4)', 'Column qmax should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'seepage', 'numeric(12,4)', 'Column seepage should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'custom_n', 'numeric(12,4)', 'Column custom_n should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'max_flow', 'numeric(12,4)', 'Column max_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'time_days', 'varchar(10)', 'Column time_days should be varchar(10)');
SELECT col_type_is('ve_epa_conduit', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_conduit', 'max_veloc', 'numeric(12,4)', 'Column max_veloc should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'mfull_flow', 'numeric(12,4)', 'Column mfull_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'mfull_depth', 'numeric(12,4)', 'Column mfull_depth should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'max_shear', 'numeric(12,4)', 'Column max_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'max_hr', 'numeric(12,4)', 'Column max_hr should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'max_slope', 'numeric(12,4)', 'Column max_slope should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'day_max', 'varchar(10)', 'Column day_max should be varchar(10)');
SELECT col_type_is('ve_epa_conduit', 'time_max', 'varchar(10)', 'Column time_max should be varchar(10)');
SELECT col_type_is('ve_epa_conduit', 'min_shear', 'numeric(12,4)', 'Column min_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_conduit', 'day_min', 'varchar(10)', 'Column day_min should be varchar(10)');
SELECT col_type_is('ve_epa_conduit', 'time_min', 'varchar(10)', 'Column time_min should be varchar(10)');

SELECT * FROM finish();

ROLLBACK;

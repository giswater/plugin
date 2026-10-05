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

-- Check view ve_epa_frorifice
SELECT has_view('ve_epa_frorifice'::name, 'View ve_epa_frorifice should exist');
SELECT has_trigger('ve_epa_frorifice', 'gw_trg_edit_ve_epa_frorifice',
    'View ve_epa_frorifice should have gw_trg_edit_ve_epa_frorifice');

-- Check view columns
SELECT columns_are(
    've_epa_frorifice',
    ARRAY[
        'element_id', 'node_id', 'orifice_type', 'offsetval', 'cd', 'orate',
        'flap', 'shape', 'geom1', 'geom2', 'geom3', 'geom4',
        'max_flow', 'time_days', 'time_hour', 'max_veloc', 'mfull_flow', 'mfull_depth',
        'max_shear', 'max_hr', 'max_slope', 'day_max', 'time_max', 'min_shear',
        'day_min', 'time_min'
    ],
    'View ve_epa_frorifice should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_frorifice', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_epa_frorifice', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_frorifice', 'orifice_type', 'varchar(18)', 'Column orifice_type should be varchar(18)');
SELECT col_type_is('ve_epa_frorifice', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'cd', 'numeric(12,4)', 'Column cd should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'orate', 'numeric(12,4)', 'Column orate should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_epa_frorifice', 'shape', 'varchar(18)', 'Column shape should be varchar(18)');
SELECT col_type_is('ve_epa_frorifice', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'max_flow', 'numeric(12,4)', 'Column max_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'time_days', 'varchar(10)', 'Column time_days should be varchar(10)');
SELECT col_type_is('ve_epa_frorifice', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_frorifice', 'max_veloc', 'numeric(12,4)', 'Column max_veloc should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'mfull_flow', 'numeric(12,4)', 'Column mfull_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'mfull_depth', 'numeric(12,4)', 'Column mfull_depth should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'max_shear', 'numeric(12,4)', 'Column max_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'max_hr', 'numeric(12,4)', 'Column max_hr should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'max_slope', 'numeric(12,4)', 'Column max_slope should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'day_max', 'varchar(10)', 'Column day_max should be varchar(10)');
SELECT col_type_is('ve_epa_frorifice', 'time_max', 'varchar(10)', 'Column time_max should be varchar(10)');
SELECT col_type_is('ve_epa_frorifice', 'min_shear', 'numeric(12,4)', 'Column min_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_frorifice', 'day_min', 'varchar(10)', 'Column day_min should be varchar(10)');
SELECT col_type_is('ve_epa_frorifice', 'time_min', 'varchar(10)', 'Column time_min should be varchar(10)');

SELECT * FROM finish();

ROLLBACK;

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

-- Check view ve_epa_weir
SELECT has_view('ve_epa_weir'::name, 'View ve_epa_weir should exist');
SELECT has_trigger('ve_epa_weir', 'gw_trg_edit_ve_epa_weir',
    'View ve_epa_weir should have gw_trg_edit_ve_epa_weir');

-- Check view columns
SELECT columns_are(
    've_epa_weir',
    ARRAY[
        'arc_id', 'weir_type', 'offsetval', 'cd', 'ec', 'cd2',
        'flap', 'geom1', 'geom2', 'geom3', 'geom4', 'surcharge',
        'road_width', 'road_surf', 'coef_curve', 'max_flow', 'time_days', 'time_hour',
        'max_veloc', 'mfull_flow', 'mfull_dept', 'max_shear', 'max_hr', 'max_slope',
        'day_max', 'time_max', 'min_shear', 'day_min', 'time_min'
    ],
    'View ve_epa_weir should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_weir', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_epa_weir', 'weir_type', 'varchar(18)', 'Column weir_type should be varchar(18)');
SELECT col_type_is('ve_epa_weir', 'offsetval', 'numeric(12,4)', 'Column offsetval should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'cd', 'numeric(12,4)', 'Column cd should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'ec', 'numeric(12,4)', 'Column ec should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'cd2', 'numeric(12,4)', 'Column cd2 should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'flap', 'varchar(3)', 'Column flap should be varchar(3)');
SELECT col_type_is('ve_epa_weir', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'surcharge', 'varchar(3)', 'Column surcharge should be varchar(3)');
SELECT col_type_is('ve_epa_weir', 'road_width', 'float8', 'Column road_width should be float8');
SELECT col_type_is('ve_epa_weir', 'road_surf', 'varchar(16)', 'Column road_surf should be varchar(16)');
SELECT col_type_is('ve_epa_weir', 'coef_curve', 'float8', 'Column coef_curve should be float8');
SELECT col_type_is('ve_epa_weir', 'max_flow', 'numeric(12,4)', 'Column max_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'time_days', 'varchar(10)', 'Column time_days should be varchar(10)');
SELECT col_type_is('ve_epa_weir', 'time_hour', 'varchar(10)', 'Column time_hour should be varchar(10)');
SELECT col_type_is('ve_epa_weir', 'max_veloc', 'numeric(12,4)', 'Column max_veloc should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'mfull_flow', 'numeric(12,4)', 'Column mfull_flow should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'mfull_dept', 'numeric(12,4)', 'Column mfull_dept should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'max_shear', 'numeric(12,4)', 'Column max_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'max_hr', 'numeric(12,4)', 'Column max_hr should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'max_slope', 'numeric(12,4)', 'Column max_slope should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'day_max', 'varchar(10)', 'Column day_max should be varchar(10)');
SELECT col_type_is('ve_epa_weir', 'time_max', 'varchar(10)', 'Column time_max should be varchar(10)');
SELECT col_type_is('ve_epa_weir', 'min_shear', 'numeric(12,4)', 'Column min_shear should be numeric(12,4)');
SELECT col_type_is('ve_epa_weir', 'day_min', 'varchar(10)', 'Column day_min should be varchar(10)');
SELECT col_type_is('ve_epa_weir', 'time_min', 'varchar(10)', 'Column time_min should be varchar(10)');

SELECT * FROM finish();

ROLLBACK;

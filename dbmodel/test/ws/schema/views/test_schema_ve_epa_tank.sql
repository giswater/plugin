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

-- Check view ve_epa_tank
SELECT has_view('ve_epa_tank'::name, 'View ve_epa_tank should exist');
SELECT has_trigger('ve_epa_tank', 'gw_trg_edit_ve_epa_tank',
    'View ve_epa_tank should have gw_trg_edit_ve_epa_tank');

-- Check view columns
SELECT columns_are(
    've_epa_tank',
    ARRAY[
        'node_id', 'initlevel', 'minlevel', 'maxlevel', 'diameter', 'minvol',
        'curve_id', 'overflow', 'mixing_model', 'mixing_fraction', 'reaction_coeff', 'init_quality',
        'source_type', 'source_quality', 'source_pattern_id', 'result_id', 'demandmax', 'demandmin',
        'demandavg', 'headmax', 'headmin', 'headavg', 'pressmax', 'pressmin',
        'pressavg', 'qualmax', 'qualmin', 'qualavg'
    ],
    'View ve_epa_tank should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_tank', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_epa_tank', 'initlevel', 'numeric(12,4)', 'Column initlevel should be numeric(12,4)');
SELECT col_type_is('ve_epa_tank', 'minlevel', 'numeric(12,4)', 'Column minlevel should be numeric(12,4)');
SELECT col_type_is('ve_epa_tank', 'maxlevel', 'numeric(12,4)', 'Column maxlevel should be numeric(12,4)');
SELECT col_type_is('ve_epa_tank', 'diameter', 'numeric(12,4)', 'Column diameter should be numeric(12,4)');
SELECT col_type_is('ve_epa_tank', 'minvol', 'numeric(12,4)', 'Column minvol should be numeric(12,4)');
SELECT col_type_is('ve_epa_tank', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('ve_epa_tank', 'overflow', 'varchar(3)', 'Column overflow should be varchar(3)');
SELECT col_type_is('ve_epa_tank', 'mixing_model', 'varchar(18)', 'Column mixing_model should be varchar(18)');
SELECT col_type_is('ve_epa_tank', 'mixing_fraction', 'float8', 'Column mixing_fraction should be float8');
SELECT col_type_is('ve_epa_tank', 'reaction_coeff', 'float8', 'Column reaction_coeff should be float8');
SELECT col_type_is('ve_epa_tank', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_epa_tank', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_epa_tank', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_epa_tank', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_epa_tank', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_tank', 'demandmax', 'numeric', 'Column demandmax should be numeric');
SELECT col_type_is('ve_epa_tank', 'demandmin', 'numeric', 'Column demandmin should be numeric');
SELECT col_type_is('ve_epa_tank', 'demandavg', 'numeric(12,2)', 'Column demandavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_tank', 'headmax', 'numeric', 'Column headmax should be numeric');
SELECT col_type_is('ve_epa_tank', 'headmin', 'numeric', 'Column headmin should be numeric');
SELECT col_type_is('ve_epa_tank', 'headavg', 'numeric(12,2)', 'Column headavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_tank', 'pressmax', 'numeric', 'Column pressmax should be numeric');
SELECT col_type_is('ve_epa_tank', 'pressmin', 'numeric', 'Column pressmin should be numeric');
SELECT col_type_is('ve_epa_tank', 'pressavg', 'numeric(12,2)', 'Column pressavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_tank', 'qualmax', 'numeric', 'Column qualmax should be numeric');
SELECT col_type_is('ve_epa_tank', 'qualmin', 'numeric', 'Column qualmin should be numeric');
SELECT col_type_is('ve_epa_tank', 'qualavg', 'numeric(12,2)', 'Column qualavg should be numeric(12,2)');

SELECT * FROM finish();

ROLLBACK;

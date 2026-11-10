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

-- Check view ve_epa_connec
SELECT has_view('ve_epa_connec'::name, 'View ve_epa_connec should exist');
SELECT has_trigger('ve_epa_connec', 'gw_trg_edit_ve_epa_connec',
    'View ve_epa_connec should have gw_trg_edit_ve_epa_connec');

-- Check view columns
SELECT columns_are(
    've_epa_connec',
    ARRAY[
        'connec_id', 'demand', 'pattern_id', 'peak_factor', 'emitter_coeff', 'init_quality',
        'source_type', 'source_quality', 'source_pattern_id', 'result_id', 'demandmax', 'demandmin',
        'demandavg', 'headmax', 'headmin', 'headavg', 'pressmax', 'pressmin',
        'pressavg', 'qualmax', 'qualmin', 'qualavg'
    ],
    'View ve_epa_connec should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_epa_connec', 'connec_id', 'int4', 'Column connec_id should be int4');
SELECT col_type_is('ve_epa_connec', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_epa_connec', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_epa_connec', 'peak_factor', 'numeric(12,4)', 'Column peak_factor should be numeric(12,4)');
SELECT col_type_is('ve_epa_connec', 'emitter_coeff', 'float8', 'Column emitter_coeff should be float8');
SELECT col_type_is('ve_epa_connec', 'init_quality', 'float8', 'Column init_quality should be float8');
SELECT col_type_is('ve_epa_connec', 'source_type', 'varchar(18)', 'Column source_type should be varchar(18)');
SELECT col_type_is('ve_epa_connec', 'source_quality', 'float8', 'Column source_quality should be float8');
SELECT col_type_is('ve_epa_connec', 'source_pattern_id', 'varchar(16)', 'Column source_pattern_id should be varchar(16)');
SELECT col_type_is('ve_epa_connec', 'result_id', 'varchar(30)', 'Column result_id should be varchar(30)');
SELECT col_type_is('ve_epa_connec', 'demandmax', 'numeric', 'Column demandmax should be numeric');
SELECT col_type_is('ve_epa_connec', 'demandmin', 'numeric', 'Column demandmin should be numeric');
SELECT col_type_is('ve_epa_connec', 'demandavg', 'numeric(12,2)', 'Column demandavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_connec', 'headmax', 'numeric', 'Column headmax should be numeric');
SELECT col_type_is('ve_epa_connec', 'headmin', 'numeric', 'Column headmin should be numeric');
SELECT col_type_is('ve_epa_connec', 'headavg', 'numeric(12,2)', 'Column headavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_connec', 'pressmax', 'numeric', 'Column pressmax should be numeric');
SELECT col_type_is('ve_epa_connec', 'pressmin', 'numeric', 'Column pressmin should be numeric');
SELECT col_type_is('ve_epa_connec', 'pressavg', 'numeric(12,2)', 'Column pressavg should be numeric(12,2)');
SELECT col_type_is('ve_epa_connec', 'qualmax', 'numeric', 'Column qualmax should be numeric');
SELECT col_type_is('ve_epa_connec', 'qualmin', 'numeric', 'Column qualmin should be numeric');
SELECT col_type_is('ve_epa_connec', 'qualavg', 'numeric(12,2)', 'Column qualavg should be numeric(12,2)');

SELECT * FROM finish();

ROLLBACK;

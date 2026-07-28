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

-- Check view ve_inp_dscenario_demand
SELECT has_view('ve_inp_dscenario_demand'::name, 'View ve_inp_dscenario_demand should exist');

-- Check view columns
SELECT columns_are(
    've_inp_dscenario_demand',
    ARRAY[
        'id', 'dscenario_id', 'feature_id', 'feature_type', 'demand', 'pattern_id',
        'demand_type', 'source', 'sector_id', 'expl_id', 'presszone_id', 'dma_id',
        'the_geom', 'observ'
    ],
    'View ve_inp_dscenario_demand should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_inp_dscenario_demand', 'id', 'int4', 'Column id should be int4');
SELECT col_type_is('ve_inp_dscenario_demand', 'dscenario_id', 'int4', 'Column dscenario_id should be int4');
SELECT col_type_is('ve_inp_dscenario_demand', 'feature_id', 'int4', 'Column feature_id should be int4');
SELECT col_type_is('ve_inp_dscenario_demand', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_demand', 'demand', 'numeric(12,6)', 'Column demand should be numeric(12,6)');
SELECT col_type_is('ve_inp_dscenario_demand', 'pattern_id', 'varchar(16)', 'Column pattern_id should be varchar(16)');
SELECT col_type_is('ve_inp_dscenario_demand', 'demand_type', 'varchar(18)', 'Column demand_type should be varchar(18)');
SELECT col_type_is('ve_inp_dscenario_demand', 'source', 'text', 'Column source should be text');
SELECT col_type_is('ve_inp_dscenario_demand', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_inp_dscenario_demand', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_inp_dscenario_demand', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_inp_dscenario_demand', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_inp_dscenario_demand', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_inp_dscenario_demand', 'observ', 'text', 'Column observ should be text');

SELECT * FROM finish();

ROLLBACK;

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

-- Check table
SELECT has_table('link'::name, 'Table link should exist');

-- Check columns
SELECT columns_are(
    'link',
    ARRAY[
        'link_id', 'code', 'sys_code', 'top_elev1', 'depth1', 'exit_id',
        'exit_type', 'top_elev2', 'depth2', 'feature_type', 'feature_id', 'linkcat_id',
        'state', 'state_type', 'expl_id', 'muni_id', 'sector_id', 'supplyzone_id',
        'presszone_id', 'dma_id', 'dqa_id', 'omzone_id', 'minsector_id', 'location_type',
        'fluid_type', 'custom_length', 'staticpressure1', 'staticpressure2', 'annotation', 'observ',
        'comment', 'descript', 'link', 'num_value', 'workcat_id', 'workcat_id_end',
        'builtdate', 'enddate', 'brand_id', 'model_id', 'verified', 'uncertain',
        'userdefined_geom', 'datasource', 'is_operative', 'lock_level', 'expl_visibility', 'created_at',
        'created_by', 'updated_at', 'updated_by', 'the_geom', 'uuid', 'dataquality', 'dataquality_obs'
    ],
    'Table link should have the correct columns'
);

-- Check column types
SELECT col_type_is('link', 'link_id', 'int4', 'Column link_id should be int4');
SELECT col_type_is('link', 'code', 'text', 'Column code should be text');
SELECT col_type_is('link', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('link', 'top_elev1', 'float8', 'Column top_elev1 should be float8');
SELECT col_type_is('link', 'depth1', 'numeric(12,4)', 'Column depth1 should be numeric(12,4)');
SELECT col_type_is('link', 'exit_id', 'int4', 'Column exit_id should be int4');
SELECT col_type_is('link', 'exit_type', 'varchar(16)', 'Column exit_type should be varchar(16)');
SELECT col_type_is('link', 'top_elev2', 'float8', 'Column top_elev2 should be float8');
SELECT col_type_is('link', 'depth2', 'numeric(12,4)', 'Column depth2 should be numeric(12,4)');
SELECT col_type_is('link', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('link', 'feature_id', 'int4', 'Column feature_id should be int4');
SELECT col_type_is('link', 'linkcat_id', 'varchar(30)', 'Column linkcat_id should be varchar(30)');
SELECT col_type_is('link', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('link', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('link', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('link', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('link', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('link', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('link', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('link', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('link', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('link', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('link', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('link', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('link', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('link', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('link', 'staticpressure1', 'numeric(12,3)', 'Column staticpressure1 should be numeric(12,3)');
SELECT col_type_is('link', 'staticpressure2', 'numeric(12,3)', 'Column staticpressure2 should be numeric(12,3)');
SELECT col_type_is('link', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('link', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('link', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('link', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('link', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('link', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('link', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('link', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('link', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('link', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('link', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('link', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('link', 'verified', 'int2', 'Column verified should be int2');
SELECT col_type_is('link', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('link', 'userdefined_geom', 'bool', 'Column userdefined_geom should be bool');
SELECT col_type_is('link', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('link', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('link', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('link', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('link', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('link', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('link', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('link', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('link', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('link', 'uuid', 'uuid', 'Column uuid should be uuid');

SELECT col_type_is('link', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('link', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

-- Check foreign keys
SELECT has_fk('link', 'Table link should have foreign keys');

SELECT fk_ok('link', 'exit_type', 'sys_feature_type', 'id', 'FK exit_type → sys_feature_type.id');
SELECT fk_ok('link', 'feature_type', 'sys_feature_type', 'id', 'FK feature_type → sys_feature_type.id');
SELECT fk_ok('link', 'presszone_id', 'presszone', 'presszone_id', 'FK presszone_id → presszone.presszone_id');
SELECT fk_ok('link', 'state', 'value_state', 'id', 'FK state → value_state.id');
SELECT fk_ok('link', 'supplyzone_id', 'supplyzone', 'supplyzone_id', 'FK supplyzone_id → supplyzone.supplyzone_id');
SELECT fk_ok('link', 'workcat_id_end', 'cat_work', 'id', 'FK workcat_id_end → cat_work.id');
SELECT fk_ok('link', 'workcat_id', 'cat_work', 'id', 'FK workcat_id → cat_work.id');
SELECT fk_ok('link', 'expl_id', 'exploitation', 'expl_id', 'FK expl_id → exploitation.expl_id');
SELECT fk_ok('link', 'omzone_id', 'omzone', 'omzone_id', 'FK omzone_id → omzone.omzone_id');
SELECT fk_ok('link', 'muni_id', 'ext_municipality', 'muni_id', 'FK muni_id → ext_municipality.muni_id');
SELECT fk_ok('link', 'linkcat_id', 'cat_link', 'id', 'FK linkcat_id → cat_link.id');
SELECT fk_ok('link', 'fluid_type', 'man_type_fluid', 'fluid_type', 'FK fluid_type → man_type_fluid.fluid_type');
SELECT fk_ok('link', 'location_type', 'man_type_location', 'location_type', 'FK location_type → man_type_location.location_type');
SELECT fk_ok('link', 'minsector_id', 'minsector', 'minsector_id', 'FK minsector_id → minsector.minsector_id');
SELECT fk_ok('link', 'sector_id', 'sector', 'sector_id', 'FK sector_id → sector.sector_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

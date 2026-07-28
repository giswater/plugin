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
SELECT has_table('arc'::name, 'Table arc should exist');

-- Check columns
SELECT columns_are(
    'arc',
    ARRAY[
        'arc_id', 'code', 'sys_code', 'node_1', 'nodetype_1', 'elevation1',
        'depth1', 'staticpressure1', 'node_2', 'nodetype_2', 'elevation2', 'depth2',
        'staticpressure2', 'feature_type', 'arccat_id', 'epa_type', 'state', 'state_type',
        'parent_id', 'expl_id', 'muni_id', 'sector_id', 'supplyzone_id', 'presszone_id',
        'dma_id', 'dqa_id', 'omzone_id', 'minsector_id', 'pavcat_id', 'soilcat_id',
        'function_type', 'category_type', 'location_type', 'fluid_type', 'descript', 'custom_length',
        'annotation', 'observ', 'comment', 'link', 'num_value', 'district_id',
        'postcode', 'streetaxis_id', 'postnumber', 'postcomplement', 'streetaxis2_id', 'postnumber2',
        'postcomplement2', 'workcat_id', 'workcat_id_end', 'workcat_id_plan', 'builtdate', 'enddate',
        'ownercat_id', 'om_state', 'conserv_state', 'brand_id', 'model_id', 'serial_number',
        'asset_id', 'adate', 'adescript', 'verified', 'datasource', 'label_x',
        'label_y', 'label_rotation', 'label_quadrant', 'inventory', 'publish', 'is_scadamap',
        'lock_level', 'expl_visibility', 'created_at', 'created_by', 'updated_at', 'updated_by',
        'the_geom', 'uuid', 'uncertain', 'dataquality', 'dataquality_obs'
    ],
    'Table arc should have the correct columns'
);

-- Check column types
SELECT col_type_is('arc', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('arc', 'code', 'text', 'Column code should be text');
SELECT col_type_is('arc', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('arc', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('arc', 'nodetype_1', 'varchar(30)', 'Column nodetype_1 should be varchar(30)');
SELECT col_type_is('arc', 'elevation1', 'numeric(12,4)', 'Column elevation1 should be numeric(12,4)');
SELECT col_type_is('arc', 'depth1', 'numeric(12,4)', 'Column depth1 should be numeric(12,4)');
SELECT col_type_is('arc', 'staticpressure1', 'numeric(12,3)', 'Column staticpressure1 should be numeric(12,3)');
SELECT col_type_is('arc', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('arc', 'nodetype_2', 'varchar(30)', 'Column nodetype_2 should be varchar(30)');
SELECT col_type_is('arc', 'elevation2', 'numeric(12,4)', 'Column elevation2 should be numeric(12,4)');
SELECT col_type_is('arc', 'depth2', 'numeric(12,4)', 'Column depth2 should be numeric(12,4)');
SELECT col_type_is('arc', 'staticpressure2', 'numeric(12,3)', 'Column staticpressure2 should be numeric(12,3)');
SELECT col_type_is('arc', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('arc', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('arc', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('arc', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('arc', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('arc', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('arc', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('arc', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('arc', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('arc', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('arc', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('arc', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('arc', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('arc', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('arc', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('arc', 'pavcat_id', 'varchar(30)', 'Column pavcat_id should be varchar(30)');
SELECT col_type_is('arc', 'soilcat_id', 'varchar(30)', 'Column soilcat_id should be varchar(30)');
SELECT col_type_is('arc', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('arc', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('arc', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('arc', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('arc', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('arc', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('arc', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('arc', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('arc', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('arc', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('arc', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('arc', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('arc', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('arc', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('arc', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('arc', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('arc', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('arc', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('arc', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('arc', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('arc', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('arc', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('arc', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('arc', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('arc', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('arc', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('arc', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('arc', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('arc', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('arc', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('arc', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('arc', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('arc', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('arc', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('arc', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('arc', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('arc', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('arc', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('arc', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('arc', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('arc', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('arc', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('arc', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('arc', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('arc', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('arc', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('arc', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('arc', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('arc', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('arc', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('arc', 'uncertain', 'bool', 'Column uncertain should be bool');

SELECT col_type_is('arc', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('arc', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

-- Check foreign keys
SELECT has_fk('arc', 'Table arc should have foreign keys');

SELECT fk_ok('arc', 'arccat_id', 'cat_arc', 'id', 'FK arccat_id → cat_arc.id');
SELECT fk_ok('arc', 'feature_type', 'sys_feature_type', 'id', 'FK feature_type → sys_feature_type.id');
SELECT fk_ok('arc', 'ownercat_id', 'cat_owner', 'id', 'FK ownercat_id → cat_owner.id');
SELECT fk_ok('arc', 'pavcat_id', 'cat_pavement', 'id', 'FK pavcat_id → cat_pavement.id');
SELECT fk_ok('arc', 'soilcat_id', 'cat_soil', 'id', 'FK soilcat_id → cat_soil.id');
SELECT fk_ok('arc', 'state', 'value_state', 'id', 'FK state → value_state.id');
SELECT fk_ok('arc', 'state_type', 'value_state_type', 'id', 'FK state_type → value_state_type.id');
SELECT fk_ok('arc', 'supplyzone_id', 'supplyzone', 'supplyzone_id', 'FK supplyzone_id → supplyzone.supplyzone_id');
SELECT fk_ok('arc', 'workcat_id_end', 'cat_work', 'id', 'FK workcat_id_end → cat_work.id');
SELECT fk_ok('arc', 'workcat_id', 'cat_work', 'id', 'FK workcat_id → cat_work.id');
SELECT fk_ok('arc', 'presszone_id', 'presszone', 'presszone_id', 'FK presszone_id → presszone.presszone_id');
SELECT fk_ok('arc', 'dma_id', 'dma', 'dma_id', 'FK dma_id → dma.dma_id');
SELECT fk_ok('arc', 'dqa_id', 'dqa', 'dqa_id', 'FK dqa_id → dqa.dqa_id');
SELECT fk_ok('arc', 'sector_id', 'sector', 'sector_id', 'FK sector_id → sector.sector_id');
SELECT fk_ok('arc', 'node_1', 'node', 'node_id', 'FK node_1 → node.node_id');
SELECT fk_ok('arc', 'node_2', 'node', 'node_id', 'FK node_2 → node.node_id');
SELECT fk_ok('arc', 'parent_id', 'node', 'node_id', 'FK parent_id → node.node_id');
SELECT fk_ok('arc', 'expl_id', 'exploitation', 'expl_id', 'FK expl_id → exploitation.expl_id');
SELECT fk_ok('arc', 'omzone_id', 'omzone', 'omzone_id', 'FK omzone_id → omzone.omzone_id');
SELECT fk_ok('arc', 'category_type', 'man_type_category', 'category_type', 'FK category_type → man_type_category.category_type');
SELECT fk_ok('arc', 'fluid_type', 'man_type_fluid', 'fluid_type', 'FK fluid_type → man_type_fluid.fluid_type');
SELECT fk_ok('arc', 'function_type', 'man_type_function', 'function_type', 'FK function_type → man_type_function.function_type');
SELECT fk_ok('arc', 'location_type', 'man_type_location', 'location_type', 'FK location_type → man_type_location.location_type');
SELECT fk_ok('arc', 'brand_id', 'cat_brand', 'id', 'FK brand_id → cat_brand.id');
SELECT fk_ok('arc', 'minsector_id', 'minsector', 'minsector_id', 'FK minsector_id → minsector.minsector_id');
SELECT fk_ok('arc', 'model_id', 'cat_brand_model', 'id', 'FK model_id → cat_brand_model.id');
SELECT fk_ok('arc', 'muni_id', 'ext_municipality', 'muni_id', 'FK muni_id → ext_municipality.muni_id');
SELECT fk_ok('arc', ARRAY['muni_id', 'streetaxis_id'], 'ext_streetaxis', ARRAY['muni_id', 'id'], 'FK (muni_id, streetaxis_id) → ext_streetaxis(muni_id, id)');
SELECT fk_ok('arc', ARRAY['muni_id', 'streetaxis2_id'], 'ext_streetaxis', ARRAY['muni_id', 'id'], 'FK (muni_id, streetaxis2_id) → ext_streetaxis(muni_id, id)');
SELECT fk_ok('arc', 'district_id', 'ext_district', 'district_id', 'FK district_id → ext_district.district_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

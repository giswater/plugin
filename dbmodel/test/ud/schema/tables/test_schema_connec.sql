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
SELECT has_table('connec'::name, 'Table connec should exist');

-- Check columns
SELECT columns_are(
    'connec',
    ARRAY[
        'connec_id', 'code', 'sys_code', 'top_elev', 'y1', 'y2',
        'feature_type', 'connec_type', 'matcat_id', 'conneccat_id', 'customer_code', 'connec_depth',
        'connec_length', 'state', 'state_type', 'arc_id', 'expl_id', 'muni_id',
        'sector_id', 'dma_id', 'dwfzone_id', 'omzone_id', 'omunit_id', 'minsector_id',
        'drainzone_outfall', 'dwfzone_outfall', 'soilcat_id', 'function_type', 'category_type', 'location_type',
        '_fluid_type', 'fluid_type', 'treatment_type', 'has_treatment', 'n_hydrometer', 'n_inhabitants',
        'demand', 'descript', 'annotation', 'observ', 'comment', 'link',
        'num_value', 'district_id', 'postcode', 'streetaxis_id', 'postnumber', 'postcomplement',
        'streetaxis2_id', 'postnumber2', 'postcomplement2', 'block_code', 'plot_id', 'workcat_id',
        'workcat_id_end', 'workcat_id_plan', 'builtdate', 'enddate', 'ownercat_id', 'om_state',
        'brand_id', 'model_id', 'pjoint_id', 'pjoint_type', 'access_type', 'placement_type',
        'accessibility', 'asset_id', 'adate', 'adescript', 'verified', 'uncertain',
        'datasource', 'label_x', 'label_y', 'label_rotation', 'rotation', 'label_quadrant',
        'inventory', 'publish', 'lock_level', 'expl_visibility', 'created_at', 'created_by',
        'updated_at', 'updated_by', 'the_geom', 'diagonal', 'uuid', 'xyz_date', 'dataquality', 'dataquality_obs'
    ],
    'Table connec should have the correct columns'
);

-- Check column types
SELECT col_type_is('connec', 'connec_id', 'int4', 'Column connec_id should be int4');
SELECT col_type_is('connec', 'code', 'text', 'Column code should be text');
SELECT col_type_is('connec', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('connec', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('connec', 'y1', 'numeric(12,4)', 'Column y1 should be numeric(12,4)');
SELECT col_type_is('connec', 'y2', 'numeric(12,4)', 'Column y2 should be numeric(12,4)');
SELECT col_type_is('connec', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('connec', 'connec_type', 'varchar(30)', 'Column connec_type should be varchar(30)');
SELECT col_type_is('connec', 'matcat_id', 'varchar(16)', 'Column matcat_id should be varchar(16)');
SELECT col_type_is('connec', 'conneccat_id', 'varchar(30)', 'Column conneccat_id should be varchar(30)');
SELECT col_type_is('connec', 'customer_code', 'varchar(30)', 'Column customer_code should be varchar(30)');
SELECT col_type_is('connec', 'connec_depth', 'numeric(12,3)', 'Column connec_depth should be numeric(12,3)');
SELECT col_type_is('connec', 'connec_length', 'numeric(12,3)', 'Column connec_length should be numeric(12,3)');
SELECT col_type_is('connec', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('connec', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('connec', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('connec', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('connec', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('connec', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('connec', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('connec', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('connec', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('connec', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('connec', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('connec', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('connec', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('connec', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('connec', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('connec', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('connec', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('connec', '_fluid_type', 'varchar(50)', 'Column _fluid_type should be varchar(50)');
SELECT col_type_is('connec', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('connec', 'treatment_type', 'int4', 'Column treatment_type should be int4');
SELECT col_type_is('connec', 'has_treatment', 'bool', 'Column has_treatment should be bool');
SELECT col_type_is('connec', 'n_hydrometer', 'int4', 'Column n_hydrometer should be int4');
SELECT col_type_is('connec', 'n_inhabitants', 'int4', 'Column n_inhabitants should be int4');
SELECT col_type_is('connec', 'demand', 'numeric(12,8)', 'Column demand should be numeric(12,8)');
SELECT col_type_is('connec', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('connec', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('connec', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('connec', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('connec', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('connec', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('connec', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('connec', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('connec', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('connec', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('connec', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('connec', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('connec', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('connec', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('connec', 'block_code', 'text', 'Column block_code should be text');
SELECT col_type_is('connec', 'plot_id', 'varchar(100)', 'Column plot_id should be varchar(100)');
SELECT col_type_is('connec', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('connec', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('connec', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('connec', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('connec', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('connec', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('connec', 'om_state', 'int4', 'Column om_state should be int4');
SELECT col_type_is('connec', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('connec', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('connec', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('connec', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('connec', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('connec', 'placement_type', 'varchar(50)', 'Column placement_type should be varchar(50)');
SELECT col_type_is('connec', 'accessibility', 'bool', 'Column accessibility should be bool');
SELECT col_type_is('connec', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('connec', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('connec', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('connec', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('connec', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('connec', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('connec', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('connec', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('connec', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('connec', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('connec', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('connec', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('connec', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('connec', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('connec', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('connec', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('connec', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('connec', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('connec', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('connec', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('connec', 'diagonal', 'varchar(50)', 'Column diagonal should be varchar(50)');
SELECT col_type_is('connec', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('connec', 'xyz_date', 'date', 'Column xyz_date should be date');

SELECT col_type_is('connec', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('connec', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

-- Check foreign keys
SELECT has_fk('connec', 'Table connec should have foreign keys');

SELECT fk_ok('connec', 'connec_type', 'cat_feature_connec', 'id', 'FK connec_type → cat_feature_connec.id');
SELECT fk_ok('connec', 'dwfzone_id', 'dwfzone', 'dwfzone_id', 'FK dwfzone_id → dwfzone.dwfzone_id');
SELECT fk_ok('connec', 'feature_type', 'sys_feature_type', 'id', 'FK feature_type → sys_feature_type.id');
SELECT fk_ok('connec', 'ownercat_id', 'cat_owner', 'id', 'FK ownercat_id → cat_owner.id');
SELECT fk_ok('connec', 'pjoint_type', 'sys_feature_type', 'id', 'FK pjoint_type → sys_feature_type.id');
SELECT fk_ok('connec', 'soilcat_id', 'cat_soil', 'id', 'FK soilcat_id → cat_soil.id');
SELECT fk_ok('connec', 'state', 'value_state', 'id', 'FK state → value_state.id');
SELECT fk_ok('connec', 'state_type', 'value_state_type', 'id', 'FK state_type → value_state_type.id');
SELECT fk_ok('connec', 'workcat_id_end', 'cat_work', 'id', 'FK workcat_id_end → cat_work.id');
SELECT fk_ok('connec', 'workcat_id', 'cat_work', 'id', 'FK workcat_id → cat_work.id');
SELECT fk_ok('connec', 'conneccat_id', 'cat_connec', 'id', 'FK conneccat_id → cat_connec.id');
SELECT fk_ok('connec', 'arc_id', 'arc', 'arc_id', 'FK arc_id → arc.arc_id');
SELECT fk_ok('connec', 'expl_id', 'exploitation', 'expl_id', 'FK expl_id → exploitation.expl_id');
SELECT fk_ok('connec', 'omzone_id', 'omzone', 'omzone_id', 'FK omzone_id → omzone.omzone_id');
SELECT fk_ok('connec', 'sector_id', 'sector', 'sector_id', 'FK sector_id → sector.sector_id');
SELECT fk_ok('connec', 'category_type', 'man_type_category', 'category_type', 'FK category_type → man_type_category.category_type');
SELECT fk_ok('connec', 'function_type', 'man_type_function', 'function_type', 'FK function_type → man_type_function.function_type');
SELECT fk_ok('connec', 'location_type', 'man_type_location', 'location_type', 'FK location_type → man_type_location.location_type');
SELECT fk_ok('connec', 'plot_id', 'ext_plot', 'id', 'FK plot_id → ext_plot.id');
SELECT fk_ok('connec', 'minsector_id', 'minsector', 'minsector_id', 'FK minsector_id → minsector.minsector_id');
SELECT fk_ok('connec', 'dma_id', 'dma', 'dma_id', 'FK dma_id → dma.dma_id');
SELECT fk_ok('connec', 'omunit_id', 'omunit', 'omunit_id', 'FK omunit_id → omunit.omunit_id');
SELECT fk_ok('connec', 'muni_id', 'ext_municipality', 'muni_id', 'FK muni_id → ext_municipality.muni_id');
SELECT fk_ok('connec', ARRAY['muni_id', 'streetaxis_id'], 'ext_streetaxis', ARRAY['muni_id', 'id'], 'FK (muni_id, streetaxis_id) → ext_streetaxis(muni_id, id)');
SELECT fk_ok('connec', ARRAY['muni_id', 'streetaxis2_id'], 'ext_streetaxis', ARRAY['muni_id', 'id'], 'FK (muni_id, streetaxis2_id) → ext_streetaxis(muni_id, id)');
SELECT fk_ok('connec', 'district_id', 'ext_district', 'district_id', 'FK district_id → ext_district.district_id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

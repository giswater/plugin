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

-- Check view ve_connec_samplepoint
SELECT has_view('ve_connec_samplepoint'::name, 'View ve_connec_samplepoint should exist');

-- Check view columns
SELECT columns_are(
    've_connec_samplepoint',
    ARRAY[
        'connec_id', 'code', 'sys_code', 'top_elev', 'y1', 'y2',
        'sys_type', 'connec_type', 'matcat_id', 'conneccat_id', 'customer_code', 'connec_depth',
        'connec_length', 'state', 'state_type', 'arc_id', 'expl_id', 'macroexpl_id',
        'muni_id', 'sector_id', 'macrosector_id', 'sector_type', 'drainzone_id', 'drainzone_type',
        'drainzone_outfall', 'dwfzone_id', 'dwfzone_type', 'dwfzone_outfall', 'omzone_id', 'macroomzone_id',
        'omzone_type', 'dma_id', 'omunit_id', 'minsector_id', 'soilcat_id', 'function_type',
        'category_type', 'location_type', 'fluid_type', 'n_hydrometer', 'n_inhabitants', 'demand',
        'descript', 'annotation', 'observ', 'comment', 'link', 'num_value',
        'district_id', 'postcode', 'streetaxis_id', 'postnumber', 'postcomplement', 'streetaxis2_id',
        'postnumber2', 'postcomplement2', 'region_id', 'province_id', 'block_code', 'plot_id',
        'workcat_id', 'workcat_id_end', 'workcat_id_plan', 'builtdate', 'enddate', 'ownercat_id',
        'om_state', 'pjoint_id', 'pjoint_type', 'access_type', 'placement_type', 'accessibility',
        'brand_id', 'model_id', 'asset_id', 'adate', 'adescript', 'verified',
        'uncertain', 'datasource', 'label', 'label_x', 'label_y', 'label_rotation',
        'rotation', 'label_quadrant', 'svg', 'inventory', 'publish', 'is_operative',
        'sector_style', 'drainzone_style', 'dwfzone_style', 'omzone_style', 'lock_level', 'expl_visibility',
        'xcoord', 'ycoord', 'lat', 'long', 'created_at', 'created_by',
        'updated_at', 'updated_by', 'the_geom', 'diagonal', 'p_state', 'uuid',
        'treatment_type', 'xyz_date', 'has_treatment', 'lab_code', 'place_name', 'cabinet', 'dataquality', 'dataquality_obs'
    ],
    'View ve_connec_samplepoint should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_connec_samplepoint', 'connec_id', 'int4', 'Column connec_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_connec_samplepoint', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_connec_samplepoint', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_connec_samplepoint', 'y1', 'numeric(12,4)', 'Column y1 should be numeric(12,4)');
SELECT col_type_is('ve_connec_samplepoint', 'y2', 'numeric(12,4)', 'Column y2 should be numeric(12,4)');
SELECT col_type_is('ve_connec_samplepoint', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'connec_type', 'text', 'Column connec_type should be text');
SELECT col_type_is('ve_connec_samplepoint', 'matcat_id', 'varchar(16)', 'Column matcat_id should be varchar(16)');
SELECT col_type_is('ve_connec_samplepoint', 'conneccat_id', 'varchar(30)', 'Column conneccat_id should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'customer_code', 'varchar(30)', 'Column customer_code should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'connec_depth', 'numeric(12,3)', 'Column connec_depth should be numeric(12,3)');
SELECT col_type_is('ve_connec_samplepoint', 'connec_length', 'numeric(12,3)', 'Column connec_length should be numeric(12,3)');
SELECT col_type_is('ve_connec_samplepoint', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_connec_samplepoint', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_connec_samplepoint', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'drainzone_id', 'int4', 'Column drainzone_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'drainzone_type', 'varchar(30)', 'Column drainzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('ve_connec_samplepoint', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'dwfzone_type', 'varchar(30)', 'Column dwfzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('ve_connec_samplepoint', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('ve_connec_samplepoint', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'n_hydrometer', 'int4', 'Column n_hydrometer should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'n_inhabitants', 'int4', 'Column n_inhabitants should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'demand', 'numeric(12,8)', 'Column demand should be numeric(12,8)');
SELECT col_type_is('ve_connec_samplepoint', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_connec_samplepoint', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_connec_samplepoint', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_connec_samplepoint', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_connec_samplepoint', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_connec_samplepoint', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_connec_samplepoint', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_connec_samplepoint', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_connec_samplepoint', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_connec_samplepoint', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_connec_samplepoint', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_connec_samplepoint', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'block_code', 'text', 'Column block_code should be text');
SELECT col_type_is('ve_connec_samplepoint', 'plot_id', 'varchar(100)', 'Column plot_id should be varchar(100)');
SELECT col_type_is('ve_connec_samplepoint', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_connec_samplepoint', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_connec_samplepoint', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_connec_samplepoint', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_connec_samplepoint', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_connec_samplepoint', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'om_state', 'int4', 'Column om_state should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('ve_connec_samplepoint', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_connec_samplepoint', 'placement_type', 'varchar(50)', 'Column placement_type should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'accessibility', 'bool', 'Column accessibility should be bool');
SELECT col_type_is('ve_connec_samplepoint', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_connec_samplepoint', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_connec_samplepoint', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_connec_samplepoint', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_connec_samplepoint', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_connec_samplepoint', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_connec_samplepoint', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_connec_samplepoint', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_connec_samplepoint', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_connec_samplepoint', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_connec_samplepoint', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_connec_samplepoint', 'drainzone_style', 'text', 'Column drainzone_style should be text');
SELECT col_type_is('ve_connec_samplepoint', 'dwfzone_style', 'text', 'Column dwfzone_style should be text');
SELECT col_type_is('ve_connec_samplepoint', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_connec_samplepoint', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_connec_samplepoint', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_connec_samplepoint', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_connec_samplepoint', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_connec_samplepoint', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_connec_samplepoint', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_connec_samplepoint', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_connec_samplepoint', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_connec_samplepoint', 'diagonal', 'varchar(50)', 'Column diagonal should be varchar(50)');
SELECT col_type_is('ve_connec_samplepoint', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_connec_samplepoint', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_connec_samplepoint', 'treatment_type', 'int4', 'Column treatment_type should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_connec_samplepoint', 'has_treatment', 'bool', 'Column has_treatment should be bool');
SELECT col_type_is('ve_connec_samplepoint', 'lab_code', 'varchar(30)', 'Column lab_code should be varchar(30)');
SELECT col_type_is('ve_connec_samplepoint', 'place_name', 'varchar(254)', 'Column place_name should be varchar(254)');
SELECT col_type_is('ve_connec_samplepoint', 'cabinet', 'varchar(150)', 'Column cabinet should be varchar(150)');

SELECT col_type_is('ve_connec_samplepoint', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_connec_samplepoint', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

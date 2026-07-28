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

-- Check view ve_connec_cjoin
SELECT has_view('ve_connec_cjoin'::name, 'View ve_connec_cjoin should exist');

-- Check view columns
SELECT columns_are(
    've_connec_cjoin',
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
        'treatment_type', 'xyz_date', 'has_treatment', 'dataquality', 'dataquality_obs'
    ],
    'View ve_connec_cjoin should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_connec_cjoin', 'connec_id', 'int4', 'Column connec_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_connec_cjoin', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_connec_cjoin', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_connec_cjoin', 'y1', 'numeric(12,4)', 'Column y1 should be numeric(12,4)');
SELECT col_type_is('ve_connec_cjoin', 'y2', 'numeric(12,4)', 'Column y2 should be numeric(12,4)');
SELECT col_type_is('ve_connec_cjoin', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'connec_type', 'text', 'Column connec_type should be text');
SELECT col_type_is('ve_connec_cjoin', 'matcat_id', 'varchar(16)', 'Column matcat_id should be varchar(16)');
SELECT col_type_is('ve_connec_cjoin', 'conneccat_id', 'varchar(30)', 'Column conneccat_id should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'customer_code', 'varchar(30)', 'Column customer_code should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'connec_depth', 'numeric(12,3)', 'Column connec_depth should be numeric(12,3)');
SELECT col_type_is('ve_connec_cjoin', 'connec_length', 'numeric(12,3)', 'Column connec_length should be numeric(12,3)');
SELECT col_type_is('ve_connec_cjoin', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_connec_cjoin', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_connec_cjoin', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'drainzone_id', 'int4', 'Column drainzone_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'drainzone_type', 'varchar(30)', 'Column drainzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('ve_connec_cjoin', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'dwfzone_type', 'varchar(30)', 'Column dwfzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('ve_connec_cjoin', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('ve_connec_cjoin', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('ve_connec_cjoin', 'n_hydrometer', 'int4', 'Column n_hydrometer should be int4');
SELECT col_type_is('ve_connec_cjoin', 'n_inhabitants', 'int4', 'Column n_inhabitants should be int4');
SELECT col_type_is('ve_connec_cjoin', 'demand', 'numeric(12,8)', 'Column demand should be numeric(12,8)');
SELECT col_type_is('ve_connec_cjoin', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_connec_cjoin', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_connec_cjoin', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_connec_cjoin', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_connec_cjoin', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_connec_cjoin', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_connec_cjoin', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_connec_cjoin', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_connec_cjoin', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_connec_cjoin', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_connec_cjoin', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_connec_cjoin', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_connec_cjoin', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_connec_cjoin', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'block_code', 'text', 'Column block_code should be text');
SELECT col_type_is('ve_connec_cjoin', 'plot_id', 'varchar(100)', 'Column plot_id should be varchar(100)');
SELECT col_type_is('ve_connec_cjoin', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_connec_cjoin', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_connec_cjoin', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_connec_cjoin', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_connec_cjoin', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_connec_cjoin', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'om_state', 'int4', 'Column om_state should be int4');
SELECT col_type_is('ve_connec_cjoin', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('ve_connec_cjoin', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('ve_connec_cjoin', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_connec_cjoin', 'placement_type', 'varchar(50)', 'Column placement_type should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'accessibility', 'bool', 'Column accessibility should be bool');
SELECT col_type_is('ve_connec_cjoin', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_connec_cjoin', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_connec_cjoin', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_connec_cjoin', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_connec_cjoin', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_connec_cjoin', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_connec_cjoin', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_connec_cjoin', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_connec_cjoin', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_connec_cjoin', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_connec_cjoin', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_connec_cjoin', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_connec_cjoin', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_connec_cjoin', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_connec_cjoin', 'drainzone_style', 'text', 'Column drainzone_style should be text');
SELECT col_type_is('ve_connec_cjoin', 'dwfzone_style', 'text', 'Column dwfzone_style should be text');
SELECT col_type_is('ve_connec_cjoin', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_connec_cjoin', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_connec_cjoin', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_connec_cjoin', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_connec_cjoin', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_connec_cjoin', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_connec_cjoin', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_connec_cjoin', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_connec_cjoin', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_connec_cjoin', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_connec_cjoin', 'diagonal', 'varchar(50)', 'Column diagonal should be varchar(50)');
SELECT col_type_is('ve_connec_cjoin', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_connec_cjoin', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_connec_cjoin', 'treatment_type', 'int4', 'Column treatment_type should be int4');
SELECT col_type_is('ve_connec_cjoin', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_connec_cjoin', 'has_treatment', 'bool', 'Column has_treatment should be bool');

SELECT col_type_is('ve_connec_cjoin', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_connec_cjoin', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

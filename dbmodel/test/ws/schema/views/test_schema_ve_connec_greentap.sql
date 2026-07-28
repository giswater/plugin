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

-- Check view ve_connec_greentap
SELECT has_view('ve_connec_greentap'::name, 'View ve_connec_greentap should exist');

-- Check view columns
SELECT columns_are(
    've_connec_greentap',
    ARRAY[
        'connec_id', 'code', 'sys_code', 'top_elev', 'depth', 'connec_type',
        'sys_type', 'conneccat_id', 'cat_matcat_id', 'cat_pnom', 'cat_dnom', 'cat_dint',
        'customer_code', 'connec_length', 'epa_type', 'state', 'state_type', 'arc_id',
        'expl_id', 'macroexpl_id', 'muni_id', 'sector_id', 'macrosector_id', 'sector_type',
        'supplyzone_id', 'supplyzone_type', 'presszone_id', 'presszone_type', 'presszone_head', 'dma_id',
        'macrodma_id', 'dma_type', 'dqa_id', 'macrodqa_id', 'dqa_type', 'omzone_id',
        'omzone_type', 'crmzone_id', 'macrocrmzone_id', 'crmzone_name', 'minsector_id', 'soilcat_id',
        'function_type', 'category_type', 'location_type', 'fluid_type', 'n_hydrometer', 'n_inhabitants',
        'staticpressure', 'descript', 'annotation', 'observ', 'comment', 'link',
        'num_value', 'district_id', 'postcode', 'streetaxis_id', 'postnumber', 'postcomplement',
        'streetaxis2_id', 'postnumber2', 'postcomplement2', 'region_id', 'province_id', 'block_code',
        'plot_id', 'workcat_id', 'workcat_id_end', 'workcat_id_plan', 'builtdate', 'enddate',
        'ownercat_id', 'pjoint_id', 'pjoint_type', 'om_state', 'conserv_state', 'accessibility',
        'access_type', 'placement_type', 'priority', 'brand_id', 'model_id', 'serial_number',
        'asset_id', 'adate', 'adescript', 'verified', 'datasource', 'label',
        'label_x', 'label_y', 'label_rotation', 'rotation', 'label_quadrant', 'svg',
        'inventory', 'publish', 'is_operative', 'inp_type', 'demand_base', 'demand_max',
        'demand_min', 'demand_avg', 'press_max', 'press_min', 'press_avg', 'quality_max',
        'quality_min', 'quality_avg', 'flow_max', 'flow_min', 'flow_avg', 'vel_max',
        'vel_min', 'vel_avg', 'result_id', 'sector_style', 'dma_style', 'presszone_style',
        'dqa_style', 'supplyzone_style', 'lock_level', 'expl_visibility', 'xcoord', 'ycoord',
        'lat', 'long', 'created_at', 'created_by', 'updated_at', 'updated_by',
        'the_geom', 'p_state', 'uuid', 'uncertain', 'xyz_date', 'linked_connec',
        'greentap_type', 'dataquality', 'dataquality_obs'
    ],
    'View ve_connec_greentap should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_connec_greentap', 'connec_id', 'int4', 'Column connec_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_connec_greentap', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_connec_greentap', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_connec_greentap', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_connec_greentap', 'connec_type', 'varchar(18)', 'Column connec_type should be varchar(18)');
SELECT col_type_is('ve_connec_greentap', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'conneccat_id', 'varchar(30)', 'Column conneccat_id should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'cat_matcat_id', 'varchar(16)', 'Column cat_matcat_id should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_connec_greentap', 'customer_code', 'varchar(30)', 'Column customer_code should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'connec_length', 'numeric(12,3)', 'Column connec_length should be numeric(12,3)');
SELECT col_type_is('ve_connec_greentap', 'epa_type', 'text', 'Column epa_type should be text');
SELECT col_type_is('ve_connec_greentap', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_connec_greentap', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_connec_greentap', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'supplyzone_type', 'varchar(30)', 'Column supplyzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'presszone_type', 'varchar(30)', 'Column presszone_type should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'presszone_head', 'numeric(12,2)', 'Column presszone_head should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'macrodma_id', 'int4', 'Column macrodma_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'dma_type', 'varchar(30)', 'Column dma_type should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'macrodqa_id', 'int4', 'Column macrodqa_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'dqa_type', 'varchar(30)', 'Column dqa_type should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'crmzone_id', 'int4', 'Column crmzone_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'macrocrmzone_id', 'int4', 'Column macrocrmzone_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'crmzone_name', 'varchar(100)', 'Column crmzone_name should be varchar(100)');
SELECT col_type_is('ve_connec_greentap', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'n_hydrometer', 'int4', 'Column n_hydrometer should be int4');
SELECT col_type_is('ve_connec_greentap', 'n_inhabitants', 'int4', 'Column n_inhabitants should be int4');
SELECT col_type_is('ve_connec_greentap', 'staticpressure', 'numeric(12,3)', 'Column staticpressure should be numeric(12,3)');
SELECT col_type_is('ve_connec_greentap', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_connec_greentap', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_connec_greentap', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_connec_greentap', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_connec_greentap', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_connec_greentap', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_connec_greentap', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_connec_greentap', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_connec_greentap', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_connec_greentap', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_connec_greentap', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'block_code', 'text', 'Column block_code should be text');
SELECT col_type_is('ve_connec_greentap', 'plot_id', 'varchar(100)', 'Column plot_id should be varchar(100)');
SELECT col_type_is('ve_connec_greentap', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_connec_greentap', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_connec_greentap', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_connec_greentap', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_connec_greentap', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_connec_greentap', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('ve_connec_greentap', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('ve_connec_greentap', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('ve_connec_greentap', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_connec_greentap', 'accessibility', 'int2', 'Column accessibility should be int2');
SELECT col_type_is('ve_connec_greentap', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_connec_greentap', 'placement_type', 'text', 'Column placement_type should be text');
SELECT col_type_is('ve_connec_greentap', 'priority', 'text', 'Column priority should be text');
SELECT col_type_is('ve_connec_greentap', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_connec_greentap', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_connec_greentap', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_connec_greentap', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_connec_greentap', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_connec_greentap', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_connec_greentap', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_connec_greentap', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_connec_greentap', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_connec_greentap', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_connec_greentap', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_connec_greentap', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_connec_greentap', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_connec_greentap', 'inp_type', 'text', 'Column inp_type should be text');
SELECT col_type_is('ve_connec_greentap', 'demand_base', 'numeric(12,2)', 'Column demand_base should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'demand_max', 'numeric(12,2)', 'Column demand_max should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'demand_min', 'numeric(12,2)', 'Column demand_min should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'demand_avg', 'numeric(12,2)', 'Column demand_avg should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'press_max', 'numeric(12,2)', 'Column press_max should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'press_min', 'numeric(12,2)', 'Column press_min should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'press_avg', 'numeric(12,2)', 'Column press_avg should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'quality_max', 'numeric(12,4)', 'Column quality_max should be numeric(12,4)');
SELECT col_type_is('ve_connec_greentap', 'quality_min', 'numeric(12,4)', 'Column quality_min should be numeric(12,4)');
SELECT col_type_is('ve_connec_greentap', 'quality_avg', 'numeric(12,4)', 'Column quality_avg should be numeric(12,4)');
SELECT col_type_is('ve_connec_greentap', 'flow_max', 'numeric(12,2)', 'Column flow_max should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'flow_min', 'numeric(12,2)', 'Column flow_min should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'flow_avg', 'numeric(12,2)', 'Column flow_avg should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'vel_max', 'numeric(12,2)', 'Column vel_max should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'vel_min', 'numeric(12,2)', 'Column vel_min should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'vel_avg', 'numeric(12,2)', 'Column vel_avg should be numeric(12,2)');
SELECT col_type_is('ve_connec_greentap', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_connec_greentap', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_connec_greentap', 'dma_style', 'text', 'Column dma_style should be text');
SELECT col_type_is('ve_connec_greentap', 'presszone_style', 'text', 'Column presszone_style should be text');
SELECT col_type_is('ve_connec_greentap', 'dqa_style', 'text', 'Column dqa_style should be text');
SELECT col_type_is('ve_connec_greentap', 'supplyzone_style', 'text', 'Column supplyzone_style should be text');
SELECT col_type_is('ve_connec_greentap', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_connec_greentap', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_connec_greentap', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_connec_greentap', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_connec_greentap', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_connec_greentap', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_connec_greentap', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_connec_greentap', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_connec_greentap', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_connec_greentap', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_connec_greentap', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_connec_greentap', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_connec_greentap', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_connec_greentap', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_connec_greentap', 'linked_connec', 'int4', 'Column linked_connec should be int4');
SELECT col_type_is('ve_connec_greentap', 'greentap_type', 'text', 'Column greentap_type should be text');

SELECT col_type_is('ve_connec_greentap', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_connec_greentap', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

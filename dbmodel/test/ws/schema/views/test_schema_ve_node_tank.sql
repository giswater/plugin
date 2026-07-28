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

-- Check view ve_node_tank
SELECT has_view('ve_node_tank'::name, 'View ve_node_tank should exist');

-- Check view columns
SELECT columns_are(
    've_node_tank',
    ARRAY[
        'node_id', 'code', 'sys_code', 'top_elev', 'custom_top_elev', 'sys_top_elev',
        'depth', 'node_type', 'sys_type', 'nodecat_id', 'cat_matcat_id', 'cat_pnom',
        'cat_dnom', 'cat_dint', 'epa_type', 'state', 'state_type', 'arc_id',
        'parent_id', 'expl_id', 'macroexpl_id', 'muni_id', 'sector_id', 'macrosector_id',
        'sector_type', 'supplyzone_id', 'supplyzone_type', 'presszone_id', 'presszone_type', 'presszone_head',
        'dma_id', 'macrodma_id', 'dma_type', 'dqa_id', 'macrodqa_id', 'dqa_type',
        'omzone_id', 'macroomzone_id', 'omzone_type', 'minsector_id', 'pavcat_id', 'soilcat_id',
        'function_type', 'category_type', 'location_type', 'fluid_type', 'staticpressure', 'annotation',
        'observ', 'comment', 'descript', 'link', 'num_value', 'district_id',
        'streetaxis_id', 'postcode', 'postnumber', 'postcomplement', 'streetaxis2_id', 'postnumber2',
        'postcomplement2', 'region_id', 'province_id', 'workcat_id', 'workcat_id_end', 'workcat_id_plan',
        'builtdate', 'enddate', 'ownercat_id', 'accessibility', 'om_state', 'conserv_state',
        'access_type', 'placement_type', 'brand_id', 'model_id', 'serial_number', 'asset_id',
        'adate', 'adescript', 'verified', 'datasource', 'hemisphere', 'label',
        'label_x', 'label_y', 'label_rotation', 'rotation', 'label_quadrant', 'svg',
        'inventory', 'publish', 'is_operative', 'is_scadamap', 'inp_type', 'demand_max',
        'demand_min', 'demand_avg', 'press_max', 'press_min', 'press_avg', 'head_max',
        'head_min', 'head_avg', 'quality_max', 'quality_min', 'quality_avg', 'result_id',
        'sector_style', 'dma_style', 'presszone_style', 'dqa_style', 'supplyzone_style', 'lock_level',
        'expl_visibility', 'xcoord', 'ycoord', 'lat', 'long', 'closed_valve',
        'broken_valve', 'created_at', 'created_by', 'updated_at', 'updated_by', 'the_geom',
        'p_state', 'uuid', 'uncertain', 'xyz_date', 'to_arc', 'sector_visibility',
        'muni_visibility', 'vmax', 'vutil', 'area', 'chlorination', 'name',
        'hmax', 'automated', 'length', 'width', 'shape', 'fence_type',
        'fence_length', 'inlet_arc', 'invert_level', 'tank_param_1', 'tank_param_2', 'vnom', 'dataquality', 'dataquality_obs'
    ],
    'View ve_node_tank should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_node_tank', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_node_tank', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_node_tank', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_node_tank', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_tank', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_tank', 'sys_top_elev', 'numeric(12,4)', 'Column sys_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_tank', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_node_tank', 'node_type', 'varchar(30)', 'Column node_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'cat_matcat_id', 'varchar(30)', 'Column cat_matcat_id should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_node_tank', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_node_tank', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_node_tank', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_node_tank', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_node_tank', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_node_tank', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_node_tank', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_node_tank', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_node_tank', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_node_tank', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_node_tank', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_node_tank', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_node_tank', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('ve_node_tank', 'supplyzone_type', 'varchar(30)', 'Column supplyzone_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_node_tank', 'presszone_type', 'varchar(30)', 'Column presszone_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'presszone_head', 'numeric(12,2)', 'Column presszone_head should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_node_tank', 'macrodma_id', 'int4', 'Column macrodma_id should be int4');
SELECT col_type_is('ve_node_tank', 'dma_type', 'varchar(30)', 'Column dma_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('ve_node_tank', 'macrodqa_id', 'int4', 'Column macrodqa_id should be int4');
SELECT col_type_is('ve_node_tank', 'dqa_type', 'varchar(30)', 'Column dqa_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_node_tank', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_node_tank', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_node_tank', 'pavcat_id', 'text', 'Column pavcat_id should be text');
SELECT col_type_is('ve_node_tank', 'soilcat_id', 'varchar(30)', 'Column soilcat_id should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'staticpressure', 'numeric(12,3)', 'Column staticpressure should be numeric(12,3)');
SELECT col_type_is('ve_node_tank', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_node_tank', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_node_tank', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_node_tank', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('ve_node_tank', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_node_tank', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_node_tank', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_node_tank', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_node_tank', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_node_tank', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_node_tank', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_node_tank', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_node_tank', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_node_tank', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_node_tank', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_node_tank', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_node_tank', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_node_tank', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_node_tank', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_node_tank', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_node_tank', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_node_tank', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'accessibility', 'int2', 'Column accessibility should be int2');
SELECT col_type_is('ve_node_tank', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('ve_node_tank', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_node_tank', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_node_tank', 'placement_type', 'text', 'Column placement_type should be text');
SELECT col_type_is('ve_node_tank', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_node_tank', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_node_tank', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_node_tank', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_node_tank', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_node_tank', 'hemisphere', 'float8', 'Column hemisphere should be float8');
SELECT col_type_is('ve_node_tank', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_node_tank', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_node_tank', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_tank', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_tank', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_node_tank', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_node_tank', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_node_tank', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_node_tank', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_node_tank', 'inp_type', 'text', 'Column inp_type should be text');
SELECT col_type_is('ve_node_tank', 'demand_max', 'numeric(12,2)', 'Column demand_max should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'demand_min', 'numeric(12,2)', 'Column demand_min should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'demand_avg', 'numeric(12,2)', 'Column demand_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'press_max', 'numeric(12,2)', 'Column press_max should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'press_min', 'numeric(12,2)', 'Column press_min should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'press_avg', 'numeric(12,2)', 'Column press_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'head_max', 'numeric(12,2)', 'Column head_max should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'head_min', 'numeric(12,2)', 'Column head_min should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'head_avg', 'numeric(12,2)', 'Column head_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'quality_max', 'numeric(12,2)', 'Column quality_max should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'quality_min', 'numeric(12,2)', 'Column quality_min should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'quality_avg', 'numeric(12,2)', 'Column quality_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_tank', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_node_tank', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_node_tank', 'dma_style', 'text', 'Column dma_style should be text');
SELECT col_type_is('ve_node_tank', 'presszone_style', 'text', 'Column presszone_style should be text');
SELECT col_type_is('ve_node_tank', 'dqa_style', 'text', 'Column dqa_style should be text');
SELECT col_type_is('ve_node_tank', 'supplyzone_style', 'text', 'Column supplyzone_style should be text');
SELECT col_type_is('ve_node_tank', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_node_tank', 'expl_visibility', 'int4[]', 'Column expl_visibility should be int4[]');
SELECT col_type_is('ve_node_tank', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_node_tank', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_node_tank', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_node_tank', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_node_tank', 'closed_valve', 'bool', 'Column closed_valve should be bool');
SELECT col_type_is('ve_node_tank', 'broken_valve', 'bool', 'Column broken_valve should be bool');
SELECT col_type_is('ve_node_tank', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_node_tank', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_node_tank', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_node_tank', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_node_tank', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_node_tank', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_node_tank', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_node_tank', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_node_tank', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_node_tank', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');
SELECT col_type_is('ve_node_tank', 'vmax', 'numeric(12,4)', 'Column vmax should be numeric(12,4)');
SELECT col_type_is('ve_node_tank', 'vutil', 'numeric(12,4)', 'Column vutil should be numeric(12,4)');
SELECT col_type_is('ve_node_tank', 'area', 'numeric(12,4)', 'Column area should be numeric(12,4)');
SELECT col_type_is('ve_node_tank', 'chlorination', 'varchar(255)', 'Column chlorination should be varchar(255)');
SELECT col_type_is('ve_node_tank', 'name', 'varchar(50)', 'Column name should be varchar(50)');
SELECT col_type_is('ve_node_tank', 'hmax', 'numeric(12,3)', 'Column hmax should be numeric(12,3)');
SELECT col_type_is('ve_node_tank', 'automated', 'bool', 'Column automated should be bool');
SELECT col_type_is('ve_node_tank', 'length', 'float8', 'Column length should be float8');
SELECT col_type_is('ve_node_tank', 'width', 'float8', 'Column width should be float8');
SELECT col_type_is('ve_node_tank', 'shape', 'int4', 'Column shape should be int4');
SELECT col_type_is('ve_node_tank', 'fence_type', 'int4', 'Column fence_type should be int4');
SELECT col_type_is('ve_node_tank', 'fence_length', 'float8', 'Column fence_length should be float8');
SELECT col_type_is('ve_node_tank', 'inlet_arc', 'int4[]', 'Column inlet_arc should be int4[]');
SELECT col_type_is('ve_node_tank', 'invert_level', 'numeric(12,3)', 'Column invert_level should be numeric(12,3)');
SELECT col_type_is('ve_node_tank', 'tank_param_1', 'int4', 'Column tank_param_1 should be int4');
SELECT col_type_is('ve_node_tank', 'tank_param_2', 'date', 'Column tank_param_2 should be date');

SELECT col_type_is('ve_node_tank', 'vnom', 'numeric(12,3)', 'Column vnom should be numeric(12,3)');
SELECT col_type_is('ve_node_tank', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_node_tank', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

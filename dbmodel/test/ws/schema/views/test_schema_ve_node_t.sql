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

-- Check view ve_node_t
SELECT has_view('ve_node_t'::name, 'View ve_node_t should exist');

-- Check view columns
SELECT columns_are(
    've_node_t',
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
        'muni_visibility', 'dataquality', 'dataquality_obs'
    ],
    'View ve_node_t should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_node_t', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_node_t', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_node_t', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_node_t', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_t', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_t', 'sys_top_elev', 'numeric(12,4)', 'Column sys_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_t', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_node_t', 'node_type', 'varchar(30)', 'Column node_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_node_t', 'cat_matcat_id', 'varchar(30)', 'Column cat_matcat_id should be varchar(30)');
SELECT col_type_is('ve_node_t', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_node_t', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_node_t', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_node_t', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_node_t', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_node_t', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_node_t', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_node_t', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_node_t', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_node_t', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_node_t', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_node_t', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_node_t', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_node_t', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('ve_node_t', 'supplyzone_type', 'varchar(30)', 'Column supplyzone_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_node_t', 'presszone_type', 'varchar(30)', 'Column presszone_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'presszone_head', 'numeric(12,2)', 'Column presszone_head should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_node_t', 'macrodma_id', 'int4', 'Column macrodma_id should be int4');
SELECT col_type_is('ve_node_t', 'dma_type', 'varchar(30)', 'Column dma_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('ve_node_t', 'macrodqa_id', 'int4', 'Column macrodqa_id should be int4');
SELECT col_type_is('ve_node_t', 'dqa_type', 'varchar(30)', 'Column dqa_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_node_t', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_node_t', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_node_t', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_node_t', 'pavcat_id', 'text', 'Column pavcat_id should be text');
SELECT col_type_is('ve_node_t', 'soilcat_id', 'varchar(30)', 'Column soilcat_id should be varchar(30)');
SELECT col_type_is('ve_node_t', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_node_t', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_node_t', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_node_t', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('ve_node_t', 'staticpressure', 'numeric(12,3)', 'Column staticpressure should be numeric(12,3)');
SELECT col_type_is('ve_node_t', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_node_t', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_node_t', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_node_t', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('ve_node_t', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_node_t', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_node_t', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_node_t', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_node_t', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_node_t', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_node_t', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_node_t', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_node_t', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_node_t', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_node_t', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_node_t', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_node_t', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_node_t', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_node_t', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_node_t', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_node_t', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_node_t', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_node_t', 'accessibility', 'int2', 'Column accessibility should be int2');
SELECT col_type_is('ve_node_t', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('ve_node_t', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_node_t', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_node_t', 'placement_type', 'text', 'Column placement_type should be text');
SELECT col_type_is('ve_node_t', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_node_t', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_node_t', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_node_t', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_node_t', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_node_t', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_node_t', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_node_t', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_node_t', 'hemisphere', 'float8', 'Column hemisphere should be float8');
SELECT col_type_is('ve_node_t', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_node_t', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_node_t', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_node_t', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_t', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_t', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_node_t', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_node_t', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_node_t', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_node_t', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_node_t', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_node_t', 'inp_type', 'text', 'Column inp_type should be text');
SELECT col_type_is('ve_node_t', 'demand_max', 'numeric(12,2)', 'Column demand_max should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'demand_min', 'numeric(12,2)', 'Column demand_min should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'demand_avg', 'numeric(12,2)', 'Column demand_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'press_max', 'numeric(12,2)', 'Column press_max should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'press_min', 'numeric(12,2)', 'Column press_min should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'press_avg', 'numeric(12,2)', 'Column press_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'head_max', 'numeric(12,2)', 'Column head_max should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'head_min', 'numeric(12,2)', 'Column head_min should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'head_avg', 'numeric(12,2)', 'Column head_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'quality_max', 'numeric(12,2)', 'Column quality_max should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'quality_min', 'numeric(12,2)', 'Column quality_min should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'quality_avg', 'numeric(12,2)', 'Column quality_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_t', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_node_t', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_node_t', 'dma_style', 'text', 'Column dma_style should be text');
SELECT col_type_is('ve_node_t', 'presszone_style', 'text', 'Column presszone_style should be text');
SELECT col_type_is('ve_node_t', 'dqa_style', 'text', 'Column dqa_style should be text');
SELECT col_type_is('ve_node_t', 'supplyzone_style', 'text', 'Column supplyzone_style should be text');
SELECT col_type_is('ve_node_t', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_node_t', 'expl_visibility', 'int4[]', 'Column expl_visibility should be int4[]');
SELECT col_type_is('ve_node_t', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_node_t', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_node_t', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_node_t', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_node_t', 'closed_valve', 'bool', 'Column closed_valve should be bool');
SELECT col_type_is('ve_node_t', 'broken_valve', 'bool', 'Column broken_valve should be bool');
SELECT col_type_is('ve_node_t', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_node_t', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_node_t', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_node_t', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_node_t', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_node_t', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_node_t', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_node_t', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_node_t', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_node_t', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_node_t', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_node_t', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');

SELECT col_type_is('ve_node_t', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_node_t', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

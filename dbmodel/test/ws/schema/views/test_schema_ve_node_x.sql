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

-- Check view ve_node_x
SELECT has_view('ve_node_x'::name, 'View ve_node_x should exist');

-- Check view columns
SELECT columns_are(
    've_node_x',
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
    'View ve_node_x should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_node_x', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_node_x', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_node_x', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_node_x', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_x', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_x', 'sys_top_elev', 'numeric(12,4)', 'Column sys_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_x', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_node_x', 'node_type', 'varchar(30)', 'Column node_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_node_x', 'cat_matcat_id', 'varchar(30)', 'Column cat_matcat_id should be varchar(30)');
SELECT col_type_is('ve_node_x', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_node_x', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_node_x', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_node_x', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_node_x', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_node_x', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_node_x', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_node_x', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_node_x', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_node_x', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_node_x', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_node_x', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_node_x', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_node_x', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('ve_node_x', 'supplyzone_type', 'varchar(30)', 'Column supplyzone_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_node_x', 'presszone_type', 'varchar(30)', 'Column presszone_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'presszone_head', 'numeric(12,2)', 'Column presszone_head should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_node_x', 'macrodma_id', 'int4', 'Column macrodma_id should be int4');
SELECT col_type_is('ve_node_x', 'dma_type', 'varchar(30)', 'Column dma_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('ve_node_x', 'macrodqa_id', 'int4', 'Column macrodqa_id should be int4');
SELECT col_type_is('ve_node_x', 'dqa_type', 'varchar(30)', 'Column dqa_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_node_x', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_node_x', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_node_x', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_node_x', 'pavcat_id', 'text', 'Column pavcat_id should be text');
SELECT col_type_is('ve_node_x', 'soilcat_id', 'varchar(30)', 'Column soilcat_id should be varchar(30)');
SELECT col_type_is('ve_node_x', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_node_x', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_node_x', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_node_x', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('ve_node_x', 'staticpressure', 'numeric(12,3)', 'Column staticpressure should be numeric(12,3)');
SELECT col_type_is('ve_node_x', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_node_x', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_node_x', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_node_x', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('ve_node_x', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_node_x', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_node_x', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_node_x', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_node_x', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_node_x', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_node_x', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_node_x', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_node_x', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_node_x', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_node_x', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_node_x', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_node_x', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_node_x', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_node_x', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_node_x', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_node_x', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_node_x', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_node_x', 'accessibility', 'int2', 'Column accessibility should be int2');
SELECT col_type_is('ve_node_x', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('ve_node_x', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_node_x', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_node_x', 'placement_type', 'text', 'Column placement_type should be text');
SELECT col_type_is('ve_node_x', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_node_x', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_node_x', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_node_x', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_node_x', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_node_x', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_node_x', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_node_x', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_node_x', 'hemisphere', 'float8', 'Column hemisphere should be float8');
SELECT col_type_is('ve_node_x', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_node_x', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_node_x', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_node_x', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_x', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_x', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_node_x', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_node_x', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_node_x', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_node_x', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_node_x', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_node_x', 'inp_type', 'text', 'Column inp_type should be text');
SELECT col_type_is('ve_node_x', 'demand_max', 'numeric(12,2)', 'Column demand_max should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'demand_min', 'numeric(12,2)', 'Column demand_min should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'demand_avg', 'numeric(12,2)', 'Column demand_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'press_max', 'numeric(12,2)', 'Column press_max should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'press_min', 'numeric(12,2)', 'Column press_min should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'press_avg', 'numeric(12,2)', 'Column press_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'head_max', 'numeric(12,2)', 'Column head_max should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'head_min', 'numeric(12,2)', 'Column head_min should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'head_avg', 'numeric(12,2)', 'Column head_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'quality_max', 'numeric(12,2)', 'Column quality_max should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'quality_min', 'numeric(12,2)', 'Column quality_min should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'quality_avg', 'numeric(12,2)', 'Column quality_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_x', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_node_x', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_node_x', 'dma_style', 'text', 'Column dma_style should be text');
SELECT col_type_is('ve_node_x', 'presszone_style', 'text', 'Column presszone_style should be text');
SELECT col_type_is('ve_node_x', 'dqa_style', 'text', 'Column dqa_style should be text');
SELECT col_type_is('ve_node_x', 'supplyzone_style', 'text', 'Column supplyzone_style should be text');
SELECT col_type_is('ve_node_x', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_node_x', 'expl_visibility', 'int4[]', 'Column expl_visibility should be int4[]');
SELECT col_type_is('ve_node_x', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_node_x', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_node_x', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_node_x', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_node_x', 'closed_valve', 'bool', 'Column closed_valve should be bool');
SELECT col_type_is('ve_node_x', 'broken_valve', 'bool', 'Column broken_valve should be bool');
SELECT col_type_is('ve_node_x', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_node_x', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_node_x', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_node_x', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_node_x', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_node_x', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_node_x', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_node_x', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_node_x', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_node_x', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_node_x', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_node_x', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');

SELECT col_type_is('ve_node_x', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_node_x', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

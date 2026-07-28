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

-- Check view ve_node_shutoff_valve
SELECT has_view('ve_node_shutoff_valve'::name, 'View ve_node_shutoff_valve should exist');

-- Check view columns
SELECT columns_are(
    've_node_shutoff_valve',
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
        'p_state', 'uuid', 'uncertain', 'xyz_date', 'sector_visibility', 'muni_visibility',
        'closed', 'broken', 'buried', 'irrigation_indicator', 'pressure_entry', 'pressure_exit',
        'depth_valveshaft', 'regulator_situation', 'regulator_location', 'regulator_observ', 'lin_meters', 'exit_type',
        'exit_code', 'drive_type', 'cat_valve2', 'ordinarystatus', 'shutter', 'brand2',
        'model2', 'valve_type', 'to_arc', 'automated', 'connection_type', 'flowsetting',
        'shtvalve_param_1', 'shtvalve_param_2', 'dataquality', 'dataquality_obs', 'turns_count'
    ],
    'View ve_node_shutoff_valve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_node_shutoff_valve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_shutoff_valve', 'custom_top_elev', 'numeric(12,4)', 'Column custom_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_shutoff_valve', 'sys_top_elev', 'numeric(12,4)', 'Column sys_top_elev should be numeric(12,4)');
SELECT col_type_is('ve_node_shutoff_valve', 'depth', 'numeric(12,4)', 'Column depth should be numeric(12,4)');
SELECT col_type_is('ve_node_shutoff_valve', 'node_type', 'varchar(30)', 'Column node_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'cat_matcat_id', 'varchar(30)', 'Column cat_matcat_id should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_node_shutoff_valve', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_node_shutoff_valve', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_node_shutoff_valve', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'supplyzone_type', 'varchar(30)', 'Column supplyzone_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'presszone_type', 'varchar(30)', 'Column presszone_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'presszone_head', 'numeric(12,2)', 'Column presszone_head should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'macrodma_id', 'int4', 'Column macrodma_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'dma_type', 'varchar(30)', 'Column dma_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'macrodqa_id', 'int4', 'Column macrodqa_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'dqa_type', 'varchar(30)', 'Column dqa_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'pavcat_id', 'text', 'Column pavcat_id should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'soilcat_id', 'varchar(30)', 'Column soilcat_id should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'staticpressure', 'numeric(12,3)', 'Column staticpressure should be numeric(12,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('ve_node_shutoff_valve', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_node_shutoff_valve', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_node_shutoff_valve', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_node_shutoff_valve', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_node_shutoff_valve', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_node_shutoff_valve', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_node_shutoff_valve', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_node_shutoff_valve', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'accessibility', 'int2', 'Column accessibility should be int2');
SELECT col_type_is('ve_node_shutoff_valve', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'placement_type', 'text', 'Column placement_type should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_node_shutoff_valve', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'hemisphere', 'float8', 'Column hemisphere should be float8');
SELECT col_type_is('ve_node_shutoff_valve', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_node_shutoff_valve', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_node_shutoff_valve', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'inp_type', 'text', 'Column inp_type should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'demand_max', 'numeric(12,2)', 'Column demand_max should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'demand_min', 'numeric(12,2)', 'Column demand_min should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'demand_avg', 'numeric(12,2)', 'Column demand_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'press_max', 'numeric(12,2)', 'Column press_max should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'press_min', 'numeric(12,2)', 'Column press_min should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'press_avg', 'numeric(12,2)', 'Column press_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'head_max', 'numeric(12,2)', 'Column head_max should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'head_min', 'numeric(12,2)', 'Column head_min should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'head_avg', 'numeric(12,2)', 'Column head_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'quality_max', 'numeric(12,2)', 'Column quality_max should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'quality_min', 'numeric(12,2)', 'Column quality_min should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'quality_avg', 'numeric(12,2)', 'Column quality_avg should be numeric(12,2)');
SELECT col_type_is('ve_node_shutoff_valve', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'dma_style', 'text', 'Column dma_style should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'presszone_style', 'text', 'Column presszone_style should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'dqa_style', 'text', 'Column dqa_style should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'supplyzone_style', 'text', 'Column supplyzone_style should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'expl_visibility', 'int4[]', 'Column expl_visibility should be int4[]');
SELECT col_type_is('ve_node_shutoff_valve', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_node_shutoff_valve', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_node_shutoff_valve', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_node_shutoff_valve', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_node_shutoff_valve', 'closed_valve', 'bool', 'Column closed_valve should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'broken_valve', 'bool', 'Column broken_valve should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_node_shutoff_valve', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_node_shutoff_valve', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_node_shutoff_valve', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_node_shutoff_valve', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_node_shutoff_valve', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_node_shutoff_valve', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_node_shutoff_valve', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_node_shutoff_valve', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');
SELECT col_type_is('ve_node_shutoff_valve', 'closed', 'bool', 'Column closed should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'broken', 'bool', 'Column broken should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'buried', 'varchar(16)', 'Column buried should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'irrigation_indicator', 'varchar(16)', 'Column irrigation_indicator should be varchar(16)');
SELECT col_type_is('ve_node_shutoff_valve', 'pressure_entry', 'numeric(12,3)', 'Column pressure_entry should be numeric(12,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'pressure_exit', 'numeric(12,3)', 'Column pressure_exit should be numeric(12,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'depth_valveshaft', 'numeric(12,3)', 'Column depth_valveshaft should be numeric(12,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'regulator_situation', 'varchar(150)', 'Column regulator_situation should be varchar(150)');
SELECT col_type_is('ve_node_shutoff_valve', 'regulator_location', 'varchar(150)', 'Column regulator_location should be varchar(150)');
SELECT col_type_is('ve_node_shutoff_valve', 'regulator_observ', 'varchar(254)', 'Column regulator_observ should be varchar(254)');
SELECT col_type_is('ve_node_shutoff_valve', 'lin_meters', 'numeric(12,3)', 'Column lin_meters should be numeric(12,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'exit_type', 'varchar(100)', 'Column exit_type should be varchar(100)');
SELECT col_type_is('ve_node_shutoff_valve', 'exit_code', 'int4', 'Column exit_code should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'drive_type', 'varchar(100)', 'Column drive_type should be varchar(100)');
SELECT col_type_is('ve_node_shutoff_valve', 'cat_valve2', 'varchar(30)', 'Column cat_valve2 should be varchar(30)');
SELECT col_type_is('ve_node_shutoff_valve', 'ordinarystatus', 'int2', 'Column ordinarystatus should be int2');
SELECT col_type_is('ve_node_shutoff_valve', 'shutter', 'text', 'Column shutter should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'brand2', 'text', 'Column brand2 should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'model2', 'text', 'Column model2 should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'valve_type', 'text', 'Column valve_type should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'to_arc', 'int4', 'Column to_arc should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'automated', 'bool', 'Column automated should be bool');
SELECT col_type_is('ve_node_shutoff_valve', 'connection_type', 'int4', 'Column connection_type should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'flowsetting', 'numeric(12,3)', 'Column flowsetting should be numeric(12,3)');
SELECT col_type_is('ve_node_shutoff_valve', 'shtvalve_param_1', 'text', 'Column shtvalve_param_1 should be text');
SELECT col_type_is('ve_node_shutoff_valve', 'shtvalve_param_2', 'text', 'Column shtvalve_param_2 should be text');

SELECT col_type_is('ve_node_shutoff_valve', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_node_shutoff_valve', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');
SELECT col_type_is('ve_node_shutoff_valve', 'turns_count', 'numeric(12,4)', 'Column turns_count should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

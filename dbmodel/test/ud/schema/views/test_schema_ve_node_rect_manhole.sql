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

-- Check view ve_node_rect_manhole
SELECT has_view('ve_node_rect_manhole'::name, 'View ve_node_rect_manhole should exist');

-- Check view columns
SELECT columns_are(
    've_node_rect_manhole',
    ARRAY[
        'node_id', 'code', 'sys_code', 'top_elev', 'custom_top_elev', 'sys_top_elev',
        'ymax', 'sys_ymax', 'elev', 'custom_elev', 'sys_elev', 'sys_type',
        'node_type', 'matcat_id', 'nodecat_id', 'epa_type', 'state', 'state_type',
        'arc_id', 'parent_id', 'expl_id', 'macroexpl_id', 'muni_id', 'sector_id',
        'macrosector_id', 'sector_type', 'drainzone_id', 'drainzone_type', 'drainzone_outfall', 'dwfzone_id',
        'dwfzone_type', 'dwfzone_outfall', 'omzone_id', 'macroomzone_id', 'dma_id', 'omunit_id',
        'minsector_id', 'pavcat_id', 'soilcat_id', 'function_type', 'category_type', 'location_type',
        'fluid_type', 'annotation', 'observ', 'comment', 'descript', 'link',
        'num_value', 'district_id', 'postcode', 'streetaxis_id', 'postnumber', 'postcomplement',
        'streetaxis2_id', 'postnumber2', 'postcomplement2', 'region_id', 'province_id', 'workcat_id',
        'workcat_id_end', 'workcat_id_plan', 'builtdate', 'enddate', 'ownercat_id', 'conserv_state',
        'om_state', 'access_type', 'placement_type', 'brand_id', 'model_id', 'serial_number',
        'asset_id', 'adate', 'adescript', 'verified', 'xyz_date', 'uncertain',
        'datasource', 'unconnected', 'label', 'label_x', 'label_y', 'label_rotation',
        'rotation', 'label_quadrant', 'hemisphere', 'svg', 'inventory', 'publish',
        'is_operative', 'is_scadamap', 'inp_type', 'result_id', 'max_depth', 'max_height',
        'flooding_rate', 'flooding_vol', 'sector_style', 'omzone_style', 'drainzone_style', 'dwfzone_style',
        'lock_level', 'expl_visibility', 'xcoord', 'ycoord', 'lat', 'long',
        'created_at', 'created_by', 'updated_at', 'updated_by', 'the_geom', 'p_state',
        'uuid', 'treatment_type', 'has_treatment', 'sector_visibility', 'muni_visibility', 'length',
        'width', 'sander_depth', 'prot_surface', 'inlet', 'bottom_channel', 'accessibility',
        'bottom_mat', 'height', 'manhole_code', 'recmanhole_param_1', 'recmanhole_param_2', 'has_access', 'dataquality', 'dataquality_obs'
    ],
    'View ve_node_rect_manhole should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_node_rect_manhole', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_node_rect_manhole', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_node_rect_manhole', 'top_elev', 'numeric(12,3)', 'Column top_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'custom_top_elev', 'numeric(12,3)', 'Column custom_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'sys_top_elev', 'numeric(12,3)', 'Column sys_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'sys_ymax', 'numeric', 'Column sys_ymax should be numeric');
SELECT col_type_is('ve_node_rect_manhole', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'custom_elev', 'numeric(12,3)', 'Column custom_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'sys_elev', 'numeric(12,3)', 'Column sys_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'node_type', 'text', 'Column node_type should be text');
SELECT col_type_is('ve_node_rect_manhole', 'matcat_id', 'varchar(16)', 'Column matcat_id should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_node_rect_manhole', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_node_rect_manhole', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'drainzone_id', 'int4', 'Column drainzone_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'drainzone_type', 'varchar(30)', 'Column drainzone_type should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('ve_node_rect_manhole', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'dwfzone_type', 'varchar(30)', 'Column dwfzone_type should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('ve_node_rect_manhole', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'pavcat_id', 'text', 'Column pavcat_id should be text');
SELECT col_type_is('ve_node_rect_manhole', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_node_rect_manhole', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_node_rect_manhole', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_node_rect_manhole', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_node_rect_manhole', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_node_rect_manhole', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_node_rect_manhole', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_node_rect_manhole', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_node_rect_manhole', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_node_rect_manhole', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_node_rect_manhole', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_node_rect_manhole', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_node_rect_manhole', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_node_rect_manhole', 'om_state', 'int4', 'Column om_state should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_node_rect_manhole', 'placement_type', 'varchar(50)', 'Column placement_type should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_node_rect_manhole', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_node_rect_manhole', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_node_rect_manhole', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_node_rect_manhole', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'unconnected', 'bool', 'Column unconnected should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_node_rect_manhole', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_node_rect_manhole', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_rect_manhole', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_rect_manhole', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_node_rect_manhole', 'hemisphere', 'float8', 'Column hemisphere should be float8');
SELECT col_type_is('ve_node_rect_manhole', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'inp_type', 'varchar(16)', 'Column inp_type should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_node_rect_manhole', 'max_depth', 'numeric(12,2)', 'Column max_depth should be numeric(12,2)');
SELECT col_type_is('ve_node_rect_manhole', 'max_height', 'numeric(12,2)', 'Column max_height should be numeric(12,2)');
SELECT col_type_is('ve_node_rect_manhole', 'flooding_rate', 'numeric(12,2)', 'Column flooding_rate should be numeric(12,2)');
SELECT col_type_is('ve_node_rect_manhole', 'flooding_vol', 'numeric(12,2)', 'Column flooding_vol should be numeric(12,2)');
SELECT col_type_is('ve_node_rect_manhole', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_node_rect_manhole', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_node_rect_manhole', 'drainzone_style', 'text', 'Column drainzone_style should be text');
SELECT col_type_is('ve_node_rect_manhole', 'dwfzone_style', 'text', 'Column dwfzone_style should be text');
SELECT col_type_is('ve_node_rect_manhole', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_node_rect_manhole', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_node_rect_manhole', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_node_rect_manhole', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_node_rect_manhole', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_node_rect_manhole', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_node_rect_manhole', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_node_rect_manhole', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_node_rect_manhole', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_node_rect_manhole', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_node_rect_manhole', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_node_rect_manhole', 'treatment_type', 'int4', 'Column treatment_type should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'has_treatment', 'bool', 'Column has_treatment should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_node_rect_manhole', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');
SELECT col_type_is('ve_node_rect_manhole', 'length', 'numeric(12,3)', 'Column length should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'width', 'numeric(12,3)', 'Column width should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'sander_depth', 'numeric(12,3)', 'Column sander_depth should be numeric(12,3)');
SELECT col_type_is('ve_node_rect_manhole', 'prot_surface', 'bool', 'Column prot_surface should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'inlet', 'bool', 'Column inlet should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'bottom_channel', 'bool', 'Column bottom_channel should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'accessibility', 'varchar(16)', 'Column accessibility should be varchar(16)');
SELECT col_type_is('ve_node_rect_manhole', 'bottom_mat', 'text', 'Column bottom_mat should be text');
SELECT col_type_is('ve_node_rect_manhole', 'height', 'numeric(12,4)', 'Column height should be numeric(12,4)');
SELECT col_type_is('ve_node_rect_manhole', 'manhole_code', 'text', 'Column manhole_code should be text');
SELECT col_type_is('ve_node_rect_manhole', 'recmanhole_param_1', 'text', 'Column recmanhole_param_1 should be text');
SELECT col_type_is('ve_node_rect_manhole', 'recmanhole_param_2', 'text', 'Column recmanhole_param_2 should be text');
SELECT col_type_is('ve_node_rect_manhole', 'has_access', 'bool', 'Column has_access should be bool');
SELECT col_type_is('ve_node_rect_manhole', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_node_rect_manhole', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

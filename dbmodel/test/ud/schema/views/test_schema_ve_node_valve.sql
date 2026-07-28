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

-- Check view ve_node_valve
SELECT has_view('ve_node_valve'::name, 'View ve_node_valve should exist');

-- Check view columns
SELECT columns_are(
    've_node_valve',
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
        'uuid', 'treatment_type', 'has_treatment', 'sector_visibility', 'muni_visibility', 'name',
        'flowsetting', 'has_access', 'dataquality', 'dataquality_obs', 'turns_count'
    ],
    'View ve_node_valve should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_node_valve', 'node_id', 'int4', 'Column node_id should be int4');
SELECT col_type_is('ve_node_valve', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_node_valve', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_node_valve', 'top_elev', 'numeric(12,3)', 'Column top_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'custom_top_elev', 'numeric(12,3)', 'Column custom_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'sys_top_elev', 'numeric(12,3)', 'Column sys_top_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'ymax', 'numeric(12,3)', 'Column ymax should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'sys_ymax', 'numeric', 'Column sys_ymax should be numeric');
SELECT col_type_is('ve_node_valve', 'elev', 'numeric(12,3)', 'Column elev should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'custom_elev', 'numeric(12,3)', 'Column custom_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'sys_elev', 'numeric(12,3)', 'Column sys_elev should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'node_type', 'text', 'Column node_type should be text');
SELECT col_type_is('ve_node_valve', 'matcat_id', 'varchar(16)', 'Column matcat_id should be varchar(16)');
SELECT col_type_is('ve_node_valve', 'nodecat_id', 'varchar(30)', 'Column nodecat_id should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_node_valve', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_node_valve', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_node_valve', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_node_valve', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_node_valve', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_node_valve', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_node_valve', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_node_valve', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_node_valve', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_node_valve', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'drainzone_id', 'int4', 'Column drainzone_id should be int4');
SELECT col_type_is('ve_node_valve', 'drainzone_type', 'varchar(30)', 'Column drainzone_type should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('ve_node_valve', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('ve_node_valve', 'dwfzone_type', 'varchar(30)', 'Column dwfzone_type should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('ve_node_valve', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_node_valve', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_node_valve', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_node_valve', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('ve_node_valve', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_node_valve', 'pavcat_id', 'text', 'Column pavcat_id should be text');
SELECT col_type_is('ve_node_valve', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('ve_node_valve', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('ve_node_valve', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_node_valve', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_node_valve', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_node_valve', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_node_valve', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_node_valve', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_node_valve', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_node_valve', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_node_valve', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_node_valve', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_node_valve', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_node_valve', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_node_valve', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_node_valve', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_node_valve', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_node_valve', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_node_valve', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_node_valve', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_node_valve', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_node_valve', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_node_valve', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_node_valve', 'om_state', 'int4', 'Column om_state should be int4');
SELECT col_type_is('ve_node_valve', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_node_valve', 'placement_type', 'varchar(50)', 'Column placement_type should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_node_valve', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_node_valve', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_node_valve', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_node_valve', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_node_valve', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_node_valve', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_node_valve', 'unconnected', 'bool', 'Column unconnected should be bool');
SELECT col_type_is('ve_node_valve', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_node_valve', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_node_valve', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_valve', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_node_valve', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_node_valve', 'hemisphere', 'float8', 'Column hemisphere should be float8');
SELECT col_type_is('ve_node_valve', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_node_valve', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_node_valve', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_node_valve', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_node_valve', 'inp_type', 'varchar(16)', 'Column inp_type should be varchar(16)');
SELECT col_type_is('ve_node_valve', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_node_valve', 'max_depth', 'numeric(12,2)', 'Column max_depth should be numeric(12,2)');
SELECT col_type_is('ve_node_valve', 'max_height', 'numeric(12,2)', 'Column max_height should be numeric(12,2)');
SELECT col_type_is('ve_node_valve', 'flooding_rate', 'numeric(12,2)', 'Column flooding_rate should be numeric(12,2)');
SELECT col_type_is('ve_node_valve', 'flooding_vol', 'numeric(12,2)', 'Column flooding_vol should be numeric(12,2)');
SELECT col_type_is('ve_node_valve', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_node_valve', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_node_valve', 'drainzone_style', 'text', 'Column drainzone_style should be text');
SELECT col_type_is('ve_node_valve', 'dwfzone_style', 'text', 'Column dwfzone_style should be text');
SELECT col_type_is('ve_node_valve', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_node_valve', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_node_valve', 'xcoord', 'float8', 'Column xcoord should be float8');
SELECT col_type_is('ve_node_valve', 'ycoord', 'float8', 'Column ycoord should be float8');
SELECT col_type_is('ve_node_valve', 'lat', 'float8', 'Column lat should be float8');
SELECT col_type_is('ve_node_valve', 'long', 'float8', 'Column long should be float8');
SELECT col_type_is('ve_node_valve', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_node_valve', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_node_valve', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_node_valve', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_node_valve', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_node_valve', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_node_valve', 'treatment_type', 'int4', 'Column treatment_type should be int4');
SELECT col_type_is('ve_node_valve', 'has_treatment', 'bool', 'Column has_treatment should be bool');
SELECT col_type_is('ve_node_valve', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_node_valve', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');
SELECT col_type_is('ve_node_valve', 'name', 'varchar(255)', 'Column name should be varchar(255)');
SELECT col_type_is('ve_node_valve', 'flowsetting', 'numeric(12,3)', 'Column flowsetting should be numeric(12,3)');
SELECT col_type_is('ve_node_valve', 'has_access', 'bool', 'Column has_access should be bool');
SELECT col_type_is('ve_node_valve', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_node_valve', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');
SELECT col_type_is('ve_node_valve', 'turns_count', 'numeric(12,4)', 'Column turns_count should be numeric(12,4)');

SELECT * FROM finish();

ROLLBACK;

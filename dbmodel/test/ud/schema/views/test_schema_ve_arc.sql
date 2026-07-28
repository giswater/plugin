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

-- Check view ve_arc
SELECT has_view('ve_arc'::name, 'View ve_arc should exist');

-- Check view columns
SELECT columns_are(
    've_arc',
    ARRAY[
        'arc_id', 'code', 'sys_code', 'node_1', 'nodetype_1', 'node_top_elev_1',
        'node_custom_top_elev_1', 'node_sys_top_elev_1', 'elev1', 'custom_elev1', 'sys_elev1', 'y1',
        'sys_y1', 'r1', 'z1', 'node_2', 'nodetype_2', 'node_top_elev_2',
        'node_custom_top_elev_2', 'node_sys_top_elev_2', 'elev2', 'custom_elev2', 'sys_elev2', 'y2',
        'sys_y2', 'r2', 'z2', 'sys_type', 'arc_type', 'arccat_id',
        'matcat_id', 'cat_shape', 'cat_geom1', 'cat_geom2', 'cat_width', 'cat_area',
        'epa_type', 'state', 'state_type', 'parent_id', 'expl_id', 'macroexpl_id',
        'muni_id', 'sector_id', 'macrosector_id', 'sector_type', 'drainzone_id', 'drainzone_type',
        'drainzone_outfall', 'dwfzone_id', 'dwfzone_type', 'dwfzone_outfall', 'omzone_id', 'macroomzone_id',
        'dma_id', 'omzone_type', 'omunit_id', 'minsector_id', 'pavcat_id', 'soilcat_id',
        'function_type', 'category_type', 'location_type', 'fluid_type', 'custom_length', 'gis_length',
        'slope', 'descript', 'annotation', 'observ', 'comment', 'link',
        'num_value', 'district_id', 'postcode', 'streetaxis_id', 'postnumber', 'postcomplement',
        'streetaxis2_id', 'postnumber2', 'postcomplement2', 'region_id', 'province_id', 'workcat_id',
        'workcat_id_end', 'workcat_id_plan', 'builtdate', 'registration_date', 'enddate', 'ownercat_id',
        'last_visitdate', 'visitability', 'om_state', 'conserv_state', 'brand_id', 'model_id',
        'serial_number', 'asset_id', 'adate', 'adescript', 'verified', 'uncertain',
        'datasource', 'label', 'label_x', 'label_y', 'label_rotation', 'label_quadrant',
        'inventory', 'publish', 'is_operative', 'is_scadamap', 'inp_type', 'result_id',
        'max_flow', 'max_veloc', 'mfull_flow', 'mfull_depth', 'manning_veloc', 'manning_flow',
        'dwf_minflow', 'dwf_maxflow', 'dwf_minvel', 'dwf_maxvel', 'conduit_capacity', 'sector_style',
        'drainzone_style', 'dwfzone_style', 'omzone_style', 'lock_level', 'initoverflowpath', 'inverted_slope',
        'negative_offset', 'expl_visibility', 'created_at', 'created_by', 'updated_at', 'updated_by',
        'the_geom', 'meandering', 'p_state', 'uuid', 'treatment_type', 'dataquality', 'dataquality_obs'
    ],
    'View ve_arc should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_arc', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_arc', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_arc', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_arc', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_arc', 'nodetype_1', 'varchar(30)', 'Column nodetype_1 should be varchar(30)');
SELECT col_type_is('ve_arc', 'node_top_elev_1', 'numeric(12,3)', 'Column node_top_elev_1 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'node_custom_top_elev_1', 'numeric(12,3)', 'Column node_custom_top_elev_1 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'node_sys_top_elev_1', 'numeric(12,3)', 'Column node_sys_top_elev_1 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'elev1', 'numeric(12,3)', 'Column elev1 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'custom_elev1', 'numeric(12,3)', 'Column custom_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'sys_elev1', 'numeric(12,3)', 'Column sys_elev1 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'y1', 'numeric(12,3)', 'Column y1 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'sys_y1', 'numeric', 'Column sys_y1 should be numeric');
SELECT col_type_is('ve_arc', 'r1', 'numeric', 'Column r1 should be numeric');
SELECT col_type_is('ve_arc', 'z1', 'numeric', 'Column z1 should be numeric');
SELECT col_type_is('ve_arc', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_arc', 'nodetype_2', 'varchar(30)', 'Column nodetype_2 should be varchar(30)');
SELECT col_type_is('ve_arc', 'node_top_elev_2', 'numeric(12,3)', 'Column node_top_elev_2 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'node_custom_top_elev_2', 'numeric(12,3)', 'Column node_custom_top_elev_2 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'node_sys_top_elev_2', 'numeric(12,3)', 'Column node_sys_top_elev_2 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'elev2', 'numeric(12,3)', 'Column elev2 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'custom_elev2', 'numeric(12,3)', 'Column custom_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'sys_elev2', 'numeric(12,3)', 'Column sys_elev2 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'y2', 'numeric(12,3)', 'Column y2 should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'sys_y2', 'numeric', 'Column sys_y2 should be numeric');
SELECT col_type_is('ve_arc', 'r2', 'numeric', 'Column r2 should be numeric');
SELECT col_type_is('ve_arc', 'z2', 'numeric', 'Column z2 should be numeric');
SELECT col_type_is('ve_arc', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_arc', 'arc_type', 'text', 'Column arc_type should be text');
SELECT col_type_is('ve_arc', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_arc', 'matcat_id', 'varchar', 'Column matcat_id should be varchar');
SELECT col_type_is('ve_arc', 'cat_shape', 'varchar(16)', 'Column cat_shape should be varchar(16)');
SELECT col_type_is('ve_arc', 'cat_geom1', 'numeric(12,4)', 'Column cat_geom1 should be numeric(12,4)');
SELECT col_type_is('ve_arc', 'cat_geom2', 'numeric(12,4)', 'Column cat_geom2 should be numeric(12,4)');
SELECT col_type_is('ve_arc', 'cat_width', 'numeric(12,2)', 'Column cat_width should be numeric(12,2)');
SELECT col_type_is('ve_arc', 'cat_area', 'numeric(12,4)', 'Column cat_area should be numeric(12,4)');
SELECT col_type_is('ve_arc', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_arc', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_arc', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_arc', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_arc', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_arc', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_arc', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_arc', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_arc', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_arc', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_arc', 'drainzone_id', 'int4', 'Column drainzone_id should be int4');
SELECT col_type_is('ve_arc', 'drainzone_type', 'varchar(30)', 'Column drainzone_type should be varchar(30)');
SELECT col_type_is('ve_arc', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('ve_arc', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('ve_arc', 'dwfzone_type', 'varchar(30)', 'Column dwfzone_type should be varchar(30)');
SELECT col_type_is('ve_arc', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('ve_arc', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_arc', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_arc', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_arc', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_arc', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('ve_arc', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_arc', 'pavcat_id', 'varchar(30)', 'Column pavcat_id should be varchar(30)');
SELECT col_type_is('ve_arc', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('ve_arc', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_arc', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_arc', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_arc', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('ve_arc', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_arc', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_arc', 'slope', 'numeric(12,4)', 'Column slope should be numeric(12,4)');
SELECT col_type_is('ve_arc', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_arc', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_arc', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_arc', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_arc', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_arc', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_arc', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_arc', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_arc', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_arc', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_arc', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_arc', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_arc', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_arc', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_arc', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_arc', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_arc', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_arc', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_arc', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_arc', 'registration_date', 'date', 'Column registration_date should be date');
SELECT col_type_is('ve_arc', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_arc', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_arc', 'last_visitdate', 'date', 'Column last_visitdate should be date');
SELECT col_type_is('ve_arc', 'visitability', 'int4', 'Column visitability should be int4');
SELECT col_type_is('ve_arc', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('ve_arc', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_arc', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_arc', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_arc', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_arc', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_arc', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_arc', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_arc', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_arc', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_arc', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_arc', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_arc', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_arc', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_arc', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_arc', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_arc', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_arc', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_arc', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_arc', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_arc', 'inp_type', 'varchar(16)', 'Column inp_type should be varchar(16)');
SELECT col_type_is('ve_arc', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_arc', 'max_flow', 'numeric(12,2)', 'Column max_flow should be numeric(12,2)');
SELECT col_type_is('ve_arc', 'max_veloc', 'numeric(12,2)', 'Column max_veloc should be numeric(12,2)');
SELECT col_type_is('ve_arc', 'mfull_flow', 'numeric(12,2)', 'Column mfull_flow should be numeric(12,2)');
SELECT col_type_is('ve_arc', 'mfull_depth', 'numeric(12,2)', 'Column mfull_depth should be numeric(12,2)');
SELECT col_type_is('ve_arc', 'manning_veloc', 'numeric(12,3)', 'Column manning_veloc should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'manning_flow', 'numeric(12,3)', 'Column manning_flow should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'dwf_minflow', 'numeric(12,3)', 'Column dwf_minflow should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'dwf_maxflow', 'numeric(12,3)', 'Column dwf_maxflow should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'dwf_minvel', 'numeric(12,3)', 'Column dwf_minvel should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'dwf_maxvel', 'numeric(12,3)', 'Column dwf_maxvel should be numeric(12,3)');
SELECT col_type_is('ve_arc', 'conduit_capacity', 'float8', 'Column conduit_capacity should be float8');
SELECT col_type_is('ve_arc', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_arc', 'drainzone_style', 'text', 'Column drainzone_style should be text');
SELECT col_type_is('ve_arc', 'dwfzone_style', 'text', 'Column dwfzone_style should be text');
SELECT col_type_is('ve_arc', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_arc', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_arc', 'initoverflowpath', 'bool', 'Column initoverflowpath should be bool');
SELECT col_type_is('ve_arc', 'inverted_slope', 'bool', 'Column inverted_slope should be bool');
SELECT col_type_is('ve_arc', 'negative_offset', 'bool', 'Column negative_offset should be bool');
SELECT col_type_is('ve_arc', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_arc', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_arc', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_arc', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_arc', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_arc', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_arc', 'meandering', 'int4', 'Column meandering should be int4');
SELECT col_type_is('ve_arc', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_arc', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_arc', 'treatment_type', 'int4', 'Column treatment_type should be int4');
SELECT col_type_is('ve_arc', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_arc', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

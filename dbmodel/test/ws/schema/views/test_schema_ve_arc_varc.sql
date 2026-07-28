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

-- Check view ve_arc_varc
SELECT has_view('ve_arc_varc'::name, 'View ve_arc_varc should exist');

-- Check view columns
SELECT columns_are(
    've_arc_varc',
    ARRAY[
        'arc_id', 'code', 'sys_code', 'node_1', 'nodetype_1', 'elevation1',
        'depth1', 'staticpressure1', 'node_2', 'nodetype_2', 'staticpressure2', 'elevation2',
        'depth2', 'depth', 'arc_type', 'arccat_id', 'sys_type', 'cat_matcat_id',
        'cat_pnom', 'cat_dnom', 'cat_dint', 'cat_dr', 'epa_type', 'state',
        'state_type', 'parent_id', 'expl_id', 'macroexpl_id', 'muni_id', 'sector_id',
        'macrosector_id', 'sector_type', 'supplyzone_id', 'supplyzone_type', 'presszone_id', 'presszone_type',
        'presszone_head', 'dma_id', 'macrodma_id', 'dma_type', 'dqa_id', 'macrodqa_id',
        'dqa_type', 'omzone_id', 'macroomzone_id', 'omzone_type', 'minsector_id', 'pavcat_id',
        'soilcat_id', 'function_type', 'category_type', 'location_type', 'fluid_type', 'descript',
        'gis_length', 'custom_length', 'annotation', 'observ', 'comment', 'link',
        'num_value', 'district_id', 'postcode', 'streetaxis_id', 'postnumber', 'postcomplement',
        'streetaxis2_id', 'postnumber2', 'postcomplement2', 'region_id', 'province_id', 'workcat_id',
        'workcat_id_end', 'workcat_id_plan', 'builtdate', 'enddate', 'ownercat_id', 'om_state',
        'conserv_state', 'brand_id', 'model_id', 'serial_number', 'asset_id', 'adate',
        'adescript', 'verified', 'datasource', 'label', 'label_x', 'label_y',
        'label_rotation', 'label_quadrant', 'inventory', 'publish', 'is_operative', 'is_scadamap',
        'inp_type', 'result_id', 'flow_max', 'flow_min', 'flow_avg', 'vel_max',
        'vel_min', 'vel_avg', 'tot_headloss_max', 'tot_headloss_min', 'mincut_connecs', 'mincut_hydrometers',
        'mincut_length', 'mincut_watervol', 'mincut_criticality', 'hydraulic_criticality', 'pipe_capacity', 'mincut_impact_topo',
        'mincut_impact_hydro', 'sector_style', 'dma_style', 'presszone_style', 'dqa_style', 'supplyzone_style',
        'lock_level', 'expl_visibility', 'created_at', 'created_by', 'updated_at', 'updated_by',
        'the_geom', 'p_state', 'uuid', 'uncertain', 'dataquality', 'dataquality_obs'
    ],
    'View ve_arc_varc should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_arc_varc', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_arc_varc', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_arc_varc', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_arc_varc', 'node_1', 'int4', 'Column node_1 should be int4');
SELECT col_type_is('ve_arc_varc', 'nodetype_1', 'varchar(30)', 'Column nodetype_1 should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'elevation1', 'numeric(12,4)', 'Column elevation1 should be numeric(12,4)');
SELECT col_type_is('ve_arc_varc', 'depth1', 'numeric(12,4)', 'Column depth1 should be numeric(12,4)');
SELECT col_type_is('ve_arc_varc', 'staticpressure1', 'numeric(12,3)', 'Column staticpressure1 should be numeric(12,3)');
SELECT col_type_is('ve_arc_varc', 'node_2', 'int4', 'Column node_2 should be int4');
SELECT col_type_is('ve_arc_varc', 'nodetype_2', 'varchar(30)', 'Column nodetype_2 should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'staticpressure2', 'numeric(12,3)', 'Column staticpressure2 should be numeric(12,3)');
SELECT col_type_is('ve_arc_varc', 'elevation2', 'numeric(12,4)', 'Column elevation2 should be numeric(12,4)');
SELECT col_type_is('ve_arc_varc', 'depth2', 'numeric(12,4)', 'Column depth2 should be numeric(12,4)');
SELECT col_type_is('ve_arc_varc', 'depth', 'numeric(12,2)', 'Column depth should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'arc_type', 'varchar(30)', 'Column arc_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'arccat_id', 'varchar(30)', 'Column arccat_id should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'cat_matcat_id', 'varchar(30)', 'Column cat_matcat_id should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_arc_varc', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_arc_varc', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_arc_varc', 'cat_dr', 'int4', 'Column cat_dr should be int4');
SELECT col_type_is('ve_arc_varc', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_arc_varc', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_arc_varc', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_arc_varc', 'parent_id', 'int4', 'Column parent_id should be int4');
SELECT col_type_is('ve_arc_varc', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_arc_varc', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_arc_varc', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_arc_varc', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_arc_varc', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_arc_varc', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('ve_arc_varc', 'supplyzone_type', 'varchar(30)', 'Column supplyzone_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_arc_varc', 'presszone_type', 'varchar(30)', 'Column presszone_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'presszone_head', 'numeric(12,2)', 'Column presszone_head should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_arc_varc', 'macrodma_id', 'int4', 'Column macrodma_id should be int4');
SELECT col_type_is('ve_arc_varc', 'dma_type', 'varchar(30)', 'Column dma_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('ve_arc_varc', 'macrodqa_id', 'int4', 'Column macrodqa_id should be int4');
SELECT col_type_is('ve_arc_varc', 'dqa_type', 'varchar(30)', 'Column dqa_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_arc_varc', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_arc_varc', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_arc_varc', 'pavcat_id', 'varchar(30)', 'Column pavcat_id should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'soilcat_id', 'varchar(30)', 'Column soilcat_id should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('ve_arc_varc', 'gis_length', 'numeric(12,2)', 'Column gis_length should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_arc_varc', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_arc_varc', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_arc_varc', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_arc_varc', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_arc_varc', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_arc_varc', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_arc_varc', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_arc_varc', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_arc_varc', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_arc_varc', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_arc_varc', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_arc_varc', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_arc_varc', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_arc_varc', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_arc_varc', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_arc_varc', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_arc_varc', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_arc_varc', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_arc_varc', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_arc_varc', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'om_state', 'text', 'Column om_state should be text');
SELECT col_type_is('ve_arc_varc', 'conserv_state', 'text', 'Column conserv_state should be text');
SELECT col_type_is('ve_arc_varc', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'serial_number', 'varchar(100)', 'Column serial_number should be varchar(100)');
SELECT col_type_is('ve_arc_varc', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_arc_varc', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_arc_varc', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_arc_varc', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_arc_varc', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_arc_varc', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_arc_varc', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_arc_varc', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_arc_varc', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_arc_varc', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_arc_varc', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_arc_varc', 'is_scadamap', 'bool', 'Column is_scadamap should be bool');
SELECT col_type_is('ve_arc_varc', 'inp_type', 'text', 'Column inp_type should be text');
SELECT col_type_is('ve_arc_varc', 'result_id', 'text', 'Column result_id should be text');
SELECT col_type_is('ve_arc_varc', 'flow_max', 'numeric(12,2)', 'Column flow_max should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'flow_min', 'numeric(12,2)', 'Column flow_min should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'flow_avg', 'numeric(12,2)', 'Column flow_avg should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'vel_max', 'numeric(12,2)', 'Column vel_max should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'vel_min', 'numeric(12,2)', 'Column vel_min should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'vel_avg', 'numeric(12,2)', 'Column vel_avg should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'tot_headloss_max', 'numeric(12,2)', 'Column tot_headloss_max should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'tot_headloss_min', 'numeric(12,2)', 'Column tot_headloss_min should be numeric(12,2)');
SELECT col_type_is('ve_arc_varc', 'mincut_connecs', 'int4', 'Column mincut_connecs should be int4');
SELECT col_type_is('ve_arc_varc', 'mincut_hydrometers', 'int4', 'Column mincut_hydrometers should be int4');
SELECT col_type_is('ve_arc_varc', 'mincut_length', 'numeric(12,3)', 'Column mincut_length should be numeric(12,3)');
SELECT col_type_is('ve_arc_varc', 'mincut_watervol', 'numeric(12,3)', 'Column mincut_watervol should be numeric(12,3)');
SELECT col_type_is('ve_arc_varc', 'mincut_criticality', 'numeric(12,3)', 'Column mincut_criticality should be numeric(12,3)');
SELECT col_type_is('ve_arc_varc', 'hydraulic_criticality', 'numeric(12,3)', 'Column hydraulic_criticality should be numeric(12,3)');
SELECT col_type_is('ve_arc_varc', 'pipe_capacity', 'float8', 'Column pipe_capacity should be float8');
SELECT col_type_is('ve_arc_varc', 'mincut_impact_topo', 'json', 'Column mincut_impact_topo should be json');
SELECT col_type_is('ve_arc_varc', 'mincut_impact_hydro', 'json', 'Column mincut_impact_hydro should be json');
SELECT col_type_is('ve_arc_varc', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_arc_varc', 'dma_style', 'text', 'Column dma_style should be text');
SELECT col_type_is('ve_arc_varc', 'presszone_style', 'text', 'Column presszone_style should be text');
SELECT col_type_is('ve_arc_varc', 'dqa_style', 'text', 'Column dqa_style should be text');
SELECT col_type_is('ve_arc_varc', 'supplyzone_style', 'text', 'Column supplyzone_style should be text');
SELECT col_type_is('ve_arc_varc', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_arc_varc', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_arc_varc', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_arc_varc', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_arc_varc', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_arc_varc', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_arc_varc', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_arc_varc', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_arc_varc', 'uncertain', 'bool', 'Column uncertain should be bool');

SELECT col_type_is('ve_arc_varc', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_arc_varc', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

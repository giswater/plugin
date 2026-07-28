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

-- Check view ve_gully_vgully
SELECT has_view('ve_gully_vgully'::name, 'View ve_gully_vgully should exist');

-- Check view columns
SELECT columns_are(
    've_gully_vgully',
    ARRAY[
        'gully_id', 'code', 'sys_code', 'top_elev', 'width', 'length',
        'ymax', 'sandbox', 'matcat_id', 'gully_type', 'sys_type', 'gullycat_id',
        'cat_gully_matcat', 'units', 'units_placement', 'groove', 'groove_height', 'groove_length',
        'siphon', 'siphon_type', 'odorflap', 'connec_arccat_id', 'connec_length', 'connec_depth',
        'connec_matcat_id', 'connec_y1', 'connec_y2', 'arc_id', 'epa_type', 'state',
        'state_type', 'expl_id', 'macroexpl_id', 'muni_id', 'sector_id', 'macrosector_id',
        'sector_type', 'drainzone_id', 'drainzone_type', 'drainzone_outfall', 'dwfzone_id', 'dwfzone_type',
        'dwfzone_outfall', 'omzone_id', 'macroomzone_id', 'dma_id', 'omzone_type', 'omunit_id',
        'minsector_id', 'soilcat_id', 'function_type', 'category_type', 'location_type', 'fluid_type',
        'descript', 'annotation', 'observ', 'comment', 'link', 'num_value',
        'district_id', 'postcode', 'streetaxis_id', 'postnumber', 'postcomplement', 'streetaxis2_id',
        'postnumber2', 'postcomplement2', 'region_id', 'province_id', 'workcat_id', 'workcat_id_end',
        'workcat_id_plan', 'builtdate', 'enddate', 'ownercat_id', 'om_state', 'pjoint_id',
        'pjoint_type', 'placement_type', 'access_type', 'brand_id', 'model_id', 'asset_id',
        'adate', 'adescript', 'verified', 'uncertain', 'datasource', 'label',
        'label_x', 'label_y', 'label_rotation', 'rotation', 'label_quadrant', 'svg',
        'inventory', 'publish', 'is_operative', 'inp_type', 'sector_style', 'omzone_style',
        'drainzone_style', 'dwfzone_style', 'lock_level', 'expl_visibility', 'created_at', 'created_by',
        'updated_at', 'updated_by', 'the_geom', 'p_state', 'uuid', 'treatment_type',
        'xyz_date', 'has_treatment', 'dataquality', 'dataquality_obs'
    ],
    'View ve_gully_vgully should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_gully_vgully', 'gully_id', 'int4', 'Column gully_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_gully_vgully', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_gully_vgully', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_gully_vgully', 'width', 'numeric', 'Column width should be numeric');
SELECT col_type_is('ve_gully_vgully', 'length', 'numeric', 'Column length should be numeric');
SELECT col_type_is('ve_gully_vgully', 'ymax', 'numeric(12,4)', 'Column ymax should be numeric(12,4)');
SELECT col_type_is('ve_gully_vgully', 'sandbox', 'numeric(12,4)', 'Column sandbox should be numeric(12,4)');
SELECT col_type_is('ve_gully_vgully', 'matcat_id', 'varchar(18)', 'Column matcat_id should be varchar(18)');
SELECT col_type_is('ve_gully_vgully', 'gully_type', 'varchar(30)', 'Column gully_type should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'gullycat_id', 'varchar(30)', 'Column gullycat_id should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'cat_gully_matcat', 'varchar(16)', 'Column cat_gully_matcat should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'units', 'numeric(12,2)', 'Column units should be numeric(12,2)');
SELECT col_type_is('ve_gully_vgully', 'units_placement', 'varchar(16)', 'Column units_placement should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'groove', 'bool', 'Column groove should be bool');
SELECT col_type_is('ve_gully_vgully', 'groove_height', 'float8', 'Column groove_height should be float8');
SELECT col_type_is('ve_gully_vgully', 'groove_length', 'float8', 'Column groove_length should be float8');
SELECT col_type_is('ve_gully_vgully', 'siphon', 'bool', 'Column siphon should be bool');
SELECT col_type_is('ve_gully_vgully', 'siphon_type', 'text', 'Column siphon_type should be text');
SELECT col_type_is('ve_gully_vgully', 'odorflap', 'text', 'Column odorflap should be text');
SELECT col_type_is('ve_gully_vgully', 'connec_arccat_id', 'varchar(18)', 'Column connec_arccat_id should be varchar(18)');
SELECT col_type_is('ve_gully_vgully', 'connec_length', 'numeric(12,3)', 'Column connec_length should be numeric(12,3)');
SELECT col_type_is('ve_gully_vgully', 'connec_depth', 'numeric(12,3)', 'Column connec_depth should be numeric(12,3)');
SELECT col_type_is('ve_gully_vgully', 'connec_matcat_id', 'text', 'Column connec_matcat_id should be text');
SELECT col_type_is('ve_gully_vgully', 'connec_y1', 'numeric', 'Column connec_y1 should be numeric');
SELECT col_type_is('ve_gully_vgully', 'connec_y2', 'numeric(12,3)', 'Column connec_y2 should be numeric(12,3)');
SELECT col_type_is('ve_gully_vgully', 'arc_id', 'int4', 'Column arc_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_gully_vgully', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_gully_vgully', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'drainzone_id', 'int4', 'Column drainzone_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'drainzone_type', 'varchar(30)', 'Column drainzone_type should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('ve_gully_vgully', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'dwfzone_type', 'varchar(30)', 'Column dwfzone_type should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('ve_gully_vgully', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'soilcat_id', 'varchar(16)', 'Column soilcat_id should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('ve_gully_vgully', 'descript', 'text', 'Column descript should be text');
SELECT col_type_is('ve_gully_vgully', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_gully_vgully', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_gully_vgully', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_gully_vgully', 'link', 'text', 'Column link should be text');
SELECT col_type_is('ve_gully_vgully', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_gully_vgully', 'district_id', 'int4', 'Column district_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'postcode', 'varchar(16)', 'Column postcode should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'streetaxis_id', 'varchar(16)', 'Column streetaxis_id should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'postnumber', 'int4', 'Column postnumber should be int4');
SELECT col_type_is('ve_gully_vgully', 'postcomplement', 'varchar(100)', 'Column postcomplement should be varchar(100)');
SELECT col_type_is('ve_gully_vgully', 'streetaxis2_id', 'varchar(16)', 'Column streetaxis2_id should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'postnumber2', 'int4', 'Column postnumber2 should be int4');
SELECT col_type_is('ve_gully_vgully', 'postcomplement2', 'varchar(100)', 'Column postcomplement2 should be varchar(100)');
SELECT col_type_is('ve_gully_vgully', 'region_id', 'int4', 'Column region_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'province_id', 'int4', 'Column province_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_gully_vgully', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_gully_vgully', 'workcat_id_plan', 'varchar(255)', 'Column workcat_id_plan should be varchar(255)');
SELECT col_type_is('ve_gully_vgully', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_gully_vgully', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_gully_vgully', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'om_state', 'int4', 'Column om_state should be int4');
SELECT col_type_is('ve_gully_vgully', 'pjoint_id', 'int4', 'Column pjoint_id should be int4');
SELECT col_type_is('ve_gully_vgully', 'pjoint_type', 'varchar(16)', 'Column pjoint_type should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'placement_type', 'varchar(50)', 'Column placement_type should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'access_type', 'text', 'Column access_type should be text');
SELECT col_type_is('ve_gully_vgully', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'adate', 'text', 'Column adate should be text');
SELECT col_type_is('ve_gully_vgully', 'adescript', 'text', 'Column adescript should be text');
SELECT col_type_is('ve_gully_vgully', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_gully_vgully', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_gully_vgully', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_gully_vgully', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('ve_gully_vgully', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_gully_vgully', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_gully_vgully', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_gully_vgully', 'label_quadrant', 'varchar(12)', 'Column label_quadrant should be varchar(12)');
SELECT col_type_is('ve_gully_vgully', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_gully_vgully', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_gully_vgully', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_gully_vgully', 'inp_type', 'varchar(16)', 'Column inp_type should be varchar(16)');
SELECT col_type_is('ve_gully_vgully', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_gully_vgully', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_gully_vgully', 'drainzone_style', 'text', 'Column drainzone_style should be text');
SELECT col_type_is('ve_gully_vgully', 'dwfzone_style', 'text', 'Column dwfzone_style should be text');
SELECT col_type_is('ve_gully_vgully', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_gully_vgully', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_gully_vgully', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_gully_vgully', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_gully_vgully', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_gully_vgully', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_gully_vgully', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_gully_vgully', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_gully_vgully', 'treatment_type', 'int4', 'Column treatment_type should be int4');
SELECT col_type_is('ve_gully_vgully', 'xyz_date', 'date', 'Column xyz_date should be date');
SELECT col_type_is('ve_gully_vgully', 'has_treatment', 'bool', 'Column has_treatment should be bool');

SELECT col_type_is('ve_gully_vgully', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_gully_vgully', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

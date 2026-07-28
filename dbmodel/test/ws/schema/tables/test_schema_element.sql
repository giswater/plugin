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

-- Check table
SELECT has_table('element'::name, 'Table element should exist');

-- Check columns
SELECT columns_are(
    'element',
    ARRAY[
        'element_id', 'code', 'sys_code', 'top_elev', 'feature_type', 'elementcat_id',
        'epa_type', 'num_elements', 'state', 'state_type', 'expl_id', 'muni_id',
        'sector_id', 'omzone_id', 'function_type', 'category_type', 'location_type', 'observ',
        'comment', 'link', 'workcat_id', 'workcat_id_end', 'builtdate', 'enddate',
        'ownercat_id', 'brand_id', 'model_id', 'serial_number', 'asset_id', 'verified',
        'datasource', 'label_x', 'label_y', 'label_rotation', 'rotation', 'inventory',
        'publish', 'trace_featuregeom', 'lock_level', 'expl_visibility', 'geometry_type', 'created_at',
        'created_by', 'updated_at', 'updated_by', 'the_geom', 'uuid', 'dataquality', 'dataquality_obs'
    ],
    'Table element should have the correct columns'
);

-- Check column types
SELECT col_type_is('element', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('element', 'code', 'text', 'Column code should be text');
SELECT col_type_is('element', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('element', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('element', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('element', 'elementcat_id', 'varchar(30)', 'Column elementcat_id should be varchar(30)');
SELECT col_type_is('element', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('element', 'num_elements', 'int4', 'Column num_elements should be int4');
SELECT col_type_is('element', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('element', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('element', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('element', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('element', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('element', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('element', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('element', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('element', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('element', 'observ', 'varchar(254)', 'Column observ should be varchar(254)');
SELECT col_type_is('element', 'comment', 'varchar(254)', 'Column comment should be varchar(254)');
SELECT col_type_is('element', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('element', 'workcat_id', 'varchar(30)', 'Column workcat_id should be varchar(30)');
SELECT col_type_is('element', 'workcat_id_end', 'varchar(30)', 'Column workcat_id_end should be varchar(30)');
SELECT col_type_is('element', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('element', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('element', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('element', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('element', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('element', 'serial_number', 'varchar(30)', 'Column serial_number should be varchar(30)');
SELECT col_type_is('element', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('element', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('element', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('element', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('element', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('element', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('element', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('element', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('element', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('element', 'trace_featuregeom', 'bool', 'Column trace_featuregeom should be bool');
SELECT col_type_is('element', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('element', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('element', 'geometry_type', 'text', 'Column geometry_type should be text');
SELECT col_type_is('element', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('element', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('element', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('element', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('element', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('element', 'uuid', 'uuid', 'Column uuid should be uuid');

SELECT col_type_is('element', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('element', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

-- Check foreign keys
SELECT has_fk('element', 'Table element should have foreign keys');

SELECT fk_ok('element', 'elementcat_id', 'cat_element', 'id', 'FK elementcat_id → cat_element.id');
SELECT fk_ok('element', 'feature_type', 'sys_feature_type', 'id', 'FK feature_type → sys_feature_type.id');
SELECT fk_ok('element', 'ownercat_id', 'cat_owner', 'id', 'FK ownercat_id → cat_owner.id');
SELECT fk_ok('element', 'state', 'value_state', 'id', 'FK state → value_state.id');
SELECT fk_ok('element', 'state_type', 'value_state_type', 'id', 'FK state_type → value_state_type.id');
SELECT fk_ok('element', 'workcat_id_end', 'cat_work', 'id', 'FK workcat_id_end → cat_work.id');
SELECT fk_ok('element', 'workcat_id', 'cat_work', 'id', 'FK workcat_id → cat_work.id');
SELECT fk_ok('element', 'muni_id', 'ext_municipality', 'muni_id', 'FK muni_id → ext_municipality.muni_id');
SELECT fk_ok('element', 'category_type', 'man_type_category', 'category_type', 'FK category_type → man_type_category.category_type');
SELECT fk_ok('element', 'function_type', 'man_type_function', 'function_type', 'FK function_type → man_type_function.function_type');
SELECT fk_ok('element', 'location_type', 'man_type_location', 'location_type', 'FK location_type → man_type_location.location_type');
SELECT fk_ok('element', 'expl_id', 'exploitation', 'expl_id', 'FK expl_id → exploitation.expl_id');
SELECT fk_ok('element', 'sector_id', 'sector', 'sector_id', 'FK sector_id → sector.sector_id');
SELECT fk_ok('element', 'brand_id', 'cat_brand', 'id', 'FK brand_id → cat_brand.id');
SELECT fk_ok('element', 'model_id', 'cat_brand_model', 'id', 'FK model_id → cat_brand_model.id');

-- Finish
SELECT * FROM finish();

ROLLBACK;

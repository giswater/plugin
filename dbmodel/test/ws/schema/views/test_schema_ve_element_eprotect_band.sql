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

-- Check view ve_element_eprotect_band
SELECT has_view('ve_element_eprotect_band'::name, 'View ve_element_eprotect_band should exist');

-- Check view columns
SELECT columns_are(
    've_element_eprotect_band',
    ARRAY[
        'element_id', 'code', 'sys_code', 'top_elev', 'element_type', 'elementcat_id',
        'num_elements', 'epa_type', 'state', 'state_type', 'expl_id', 'muni_id',
        'sector_id', 'omzone_id', 'function_type', 'category_type', 'location_type', 'observ',
        'comment', 'link', 'workcat_id', 'workcat_id_end', 'builtdate', 'enddate',
        'ownercat_id', 'brand_id', 'model_id', 'serial_number', 'asset_id', 'verified',
        'datasource', 'label_x', 'label_y', 'label_rotation', 'rotation', 'inventory',
        'publish', 'trace_featuregeom', 'lock_level', 'expl_visibility', 'created_at', 'created_by',
        'updated_at', 'updated_by', 'the_geom', 'uuid', 'sector_visibility', 'muni_visibility', 'dataquality', 'dataquality_obs'
    ],
    'View ve_element_eprotect_band should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_element_eprotect_band', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_element_eprotect_band', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_element_eprotect_band', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_element_eprotect_band', 'element_type', 'varchar(30)', 'Column element_type should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'elementcat_id', 'varchar(30)', 'Column elementcat_id should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'num_elements', 'int4', 'Column num_elements should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_element_eprotect_band', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_element_eprotect_band', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_element_eprotect_band', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'observ', 'varchar(254)', 'Column observ should be varchar(254)');
SELECT col_type_is('ve_element_eprotect_band', 'comment', 'varchar(254)', 'Column comment should be varchar(254)');
SELECT col_type_is('ve_element_eprotect_band', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('ve_element_eprotect_band', 'workcat_id', 'varchar(30)', 'Column workcat_id should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'workcat_id_end', 'varchar(30)', 'Column workcat_id_end should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_element_eprotect_band', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_element_eprotect_band', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'serial_number', 'varchar(30)', 'Column serial_number should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_element_eprotect_band', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_element_eprotect_band', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_element_eprotect_band', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_element_eprotect_band', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_element_eprotect_band', 'trace_featuregeom', 'bool', 'Column trace_featuregeom should be bool');
SELECT col_type_is('ve_element_eprotect_band', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_element_eprotect_band', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_element_eprotect_band', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_element_eprotect_band', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_element_eprotect_band', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_element_eprotect_band', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_element_eprotect_band', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_element_eprotect_band', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');

SELECT col_type_is('ve_element_eprotect_band', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_element_eprotect_band', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

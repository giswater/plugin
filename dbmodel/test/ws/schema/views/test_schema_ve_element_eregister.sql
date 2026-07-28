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

-- Check view ve_element_eregister
SELECT has_view('ve_element_eregister'::name, 'View ve_element_eregister should exist');

-- Check view columns
SELECT columns_are(
    've_element_eregister',
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
    'View ve_element_eregister should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_element_eregister', 'element_id', 'int4', 'Column element_id should be int4');
SELECT col_type_is('ve_element_eregister', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_element_eregister', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_element_eregister', 'top_elev', 'numeric(12,4)', 'Column top_elev should be numeric(12,4)');
SELECT col_type_is('ve_element_eregister', 'element_type', 'varchar(30)', 'Column element_type should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'elementcat_id', 'varchar(30)', 'Column elementcat_id should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'num_elements', 'int4', 'Column num_elements should be int4');
SELECT col_type_is('ve_element_eregister', 'epa_type', 'varchar(16)', 'Column epa_type should be varchar(16)');
SELECT col_type_is('ve_element_eregister', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_element_eregister', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_element_eregister', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_element_eregister', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_element_eregister', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_element_eregister', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_element_eregister', 'function_type', 'varchar(50)', 'Column function_type should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'category_type', 'varchar(50)', 'Column category_type should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'observ', 'varchar(254)', 'Column observ should be varchar(254)');
SELECT col_type_is('ve_element_eregister', 'comment', 'varchar(254)', 'Column comment should be varchar(254)');
SELECT col_type_is('ve_element_eregister', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('ve_element_eregister', 'workcat_id', 'varchar(30)', 'Column workcat_id should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'workcat_id_end', 'varchar(30)', 'Column workcat_id_end should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_element_eregister', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_element_eregister', 'ownercat_id', 'varchar(30)', 'Column ownercat_id should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'serial_number', 'varchar(30)', 'Column serial_number should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'asset_id', 'varchar(50)', 'Column asset_id should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'verified', 'int4', 'Column verified should be int4');
SELECT col_type_is('ve_element_eregister', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_element_eregister', 'label_x', 'varchar(30)', 'Column label_x should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'label_y', 'varchar(30)', 'Column label_y should be varchar(30)');
SELECT col_type_is('ve_element_eregister', 'label_rotation', 'numeric(6,3)', 'Column label_rotation should be numeric(6,3)');
SELECT col_type_is('ve_element_eregister', 'rotation', 'numeric(6,3)', 'Column rotation should be numeric(6,3)');
SELECT col_type_is('ve_element_eregister', 'inventory', 'bool', 'Column inventory should be bool');
SELECT col_type_is('ve_element_eregister', 'publish', 'bool', 'Column publish should be bool');
SELECT col_type_is('ve_element_eregister', 'trace_featuregeom', 'bool', 'Column trace_featuregeom should be bool');
SELECT col_type_is('ve_element_eregister', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_element_eregister', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_element_eregister', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_element_eregister', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_element_eregister', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_element_eregister', 'the_geom', 'geometry(point, SRID_VALUE)', 'Column the_geom should be geometry(point, SRID_VALUE)');
SELECT col_type_is('ve_element_eregister', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_element_eregister', 'sector_visibility', 'int4[]', 'Column sector_visibility should be int4[]');
SELECT col_type_is('ve_element_eregister', 'muni_visibility', 'int4[]', 'Column muni_visibility should be int4[]');

SELECT col_type_is('ve_element_eregister', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_element_eregister', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

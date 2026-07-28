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

-- Check view ve_link_vlink
SELECT has_view('ve_link_vlink'::name, 'View ve_link_vlink should exist');

-- Check view columns
SELECT columns_are(
    've_link_vlink',
    ARRAY[
        'link_id', 'code', 'sys_code', 'top_elev1', 'y1', 'elevation1',
        'exit_id', 'exit_type', 'top_elev2', 'y2', 'elevation2', 'feature_type',
        'feature_id', 'link_type', 'sys_type', 'linkcat_id', 'matcat_id', 'cat_dnom',
        'cat_dint', 'cat_pnom', 'state', 'state_type', 'expl_id', 'macroexpl_id',
        'muni_id', 'sector_id', 'macrosector_id', 'sector_type', 'drainzone_id', 'drainzone_type',
        'drainzone_outfall', 'dwfzone_id', 'dwfzone_type', 'dwfzone_outfall', 'omzone_id', 'macroomzone_id',
        'dma_id', 'location_type', 'fluid_type', 'custom_length', 'gis_length', 'sys_slope',
        'annotation', 'observ', 'comment', 'descript', 'link', 'num_value',
        'workcat_id', 'workcat_id_end', 'builtdate', 'enddate', 'brand_id', 'model_id',
        'private_linkcat_id', 'verified', 'uncertain', 'userdefined_geom', 'datasource', 'is_operative',
        'sector_style', 'omzone_style', 'drainzone_style', 'dwfzone_style', 'lock_level', 'expl_visibility',
        'created_at', 'created_by', 'updated_at', 'updated_by', 'the_geom', 'p_state',
        'uuid', 'omunit_id', 'treatment_type', 'dataquality', 'dataquality_obs'
    ],
    'View ve_link_vlink should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_link_vlink', 'link_id', 'int4', 'Column link_id should be int4');
SELECT col_type_is('ve_link_vlink', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_link_vlink', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_link_vlink', 'top_elev1', 'float8', 'Column top_elev1 should be float8');
SELECT col_type_is('ve_link_vlink', 'y1', 'numeric(12,4)', 'Column y1 should be numeric(12,4)');
SELECT col_type_is('ve_link_vlink', 'elevation1', 'float8', 'Column elevation1 should be float8');
SELECT col_type_is('ve_link_vlink', 'exit_id', 'int4', 'Column exit_id should be int4');
SELECT col_type_is('ve_link_vlink', 'exit_type', 'varchar(16)', 'Column exit_type should be varchar(16)');
SELECT col_type_is('ve_link_vlink', 'top_elev2', 'float8', 'Column top_elev2 should be float8');
SELECT col_type_is('ve_link_vlink', 'y2', 'numeric(12,4)', 'Column y2 should be numeric(12,4)');
SELECT col_type_is('ve_link_vlink', 'elevation2', 'float8', 'Column elevation2 should be float8');
SELECT col_type_is('ve_link_vlink', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('ve_link_vlink', 'feature_id', 'int4', 'Column feature_id should be int4');
SELECT col_type_is('ve_link_vlink', 'link_type', 'varchar(30)', 'Column link_type should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'linkcat_id', 'varchar(30)', 'Column linkcat_id should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'matcat_id', 'varchar(30)', 'Column matcat_id should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_link_vlink', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_link_vlink', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_link_vlink', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_link_vlink', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_link_vlink', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_link_vlink', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_link_vlink', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_link_vlink', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_link_vlink', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_link_vlink', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'drainzone_id', 'int4', 'Column drainzone_id should be int4');
SELECT col_type_is('ve_link_vlink', 'drainzone_type', 'varchar(30)', 'Column drainzone_type should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'drainzone_outfall', 'int4[]', 'Column drainzone_outfall should be int4[]');
SELECT col_type_is('ve_link_vlink', 'dwfzone_id', 'int4', 'Column dwfzone_id should be int4');
SELECT col_type_is('ve_link_vlink', 'dwfzone_type', 'varchar(30)', 'Column dwfzone_type should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'dwfzone_outfall', 'int4[]', 'Column dwfzone_outfall should be int4[]');
SELECT col_type_is('ve_link_vlink', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_link_vlink', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_link_vlink', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_link_vlink', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_link_vlink', 'fluid_type', 'int4', 'Column fluid_type should be int4');
SELECT col_type_is('ve_link_vlink', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_link_vlink', 'gis_length', 'numeric(12,3)', 'Column gis_length should be numeric(12,3)');
SELECT col_type_is('ve_link_vlink', 'sys_slope', 'numeric(12,3)', 'Column sys_slope should be numeric(12,3)');
SELECT col_type_is('ve_link_vlink', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_link_vlink', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_link_vlink', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_link_vlink', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('ve_link_vlink', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('ve_link_vlink', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_link_vlink', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_link_vlink', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_link_vlink', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_link_vlink', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_link_vlink', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_link_vlink', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_link_vlink', 'private_linkcat_id', 'varchar(30)', 'Column private_linkcat_id should be varchar(30)');
SELECT col_type_is('ve_link_vlink', 'verified', 'int2', 'Column verified should be int2');
SELECT col_type_is('ve_link_vlink', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_link_vlink', 'userdefined_geom', 'bool', 'Column userdefined_geom should be bool');
SELECT col_type_is('ve_link_vlink', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_link_vlink', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_link_vlink', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_link_vlink', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_link_vlink', 'drainzone_style', 'text', 'Column drainzone_style should be text');
SELECT col_type_is('ve_link_vlink', 'dwfzone_style', 'text', 'Column dwfzone_style should be text');
SELECT col_type_is('ve_link_vlink', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_link_vlink', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_link_vlink', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_link_vlink', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_link_vlink', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_link_vlink', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_link_vlink', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_link_vlink', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_link_vlink', 'uuid', 'uuid', 'Column uuid should be uuid');
SELECT col_type_is('ve_link_vlink', 'omunit_id', 'int4', 'Column omunit_id should be int4');
SELECT col_type_is('ve_link_vlink', 'treatment_type', 'int4', 'Column treatment_type should be int4');

SELECT col_type_is('ve_link_vlink', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_link_vlink', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

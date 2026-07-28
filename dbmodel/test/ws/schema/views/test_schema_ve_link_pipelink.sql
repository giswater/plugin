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

-- Check view ve_link_pipelink
SELECT has_view('ve_link_pipelink'::name, 'View ve_link_pipelink should exist');

-- Check view columns
SELECT columns_are(
    've_link_pipelink',
    ARRAY[
        'link_id', 'code', 'sys_code', 'top_elev1', 'depth1', 'elevation1',
        'exit_id', 'exit_type', 'top_elev2', 'depth2', 'elevation2', 'feature_type',
        'feature_id', 'link_type', 'sys_type', 'linkcat_id', 'matcat_id', 'cat_dnom',
        'cat_dint', 'cat_pnom', 'state', 'state_type', 'expl_id', 'macroexpl_id',
        'muni_id', 'sector_id', 'macrosector_id', 'sector_type', 'supplyzone_id', 'supplyzone_type',
        'presszone_id', 'presszone_type', 'presszone_head', 'dma_id', 'macrodma_id', 'dma_type',
        'dqa_id', 'macrodqa_id', 'dqa_type', 'omzone_id', 'macroomzone_id', 'omzone_type',
        'minsector_id', 'location_type', 'fluid_type', 'custom_length', 'gis_length', 'staticpressure1',
        'staticpressure2', 'annotation', 'observ', 'comment', 'descript', 'link',
        'num_value', 'workcat_id', 'workcat_id_end', 'builtdate', 'enddate', 'brand_id',
        'model_id', 'verified', 'uncertain', 'userdefined_geom', 'datasource', 'is_operative',
        'sector_style', 'omzone_style', 'dma_style', 'presszone_style', 'dqa_style', 'supplyzone_style',
        'inp_type', 'lock_level', 'expl_visibility', 'created_at', 'created_by', 'updated_at',
        'updated_by', 'the_geom', 'p_state', 'uuid', 'dataquality', 'dataquality_obs'
    ],
    'View ve_link_pipelink should have the correct columns'
);

-- Check column types
SELECT col_type_is('ve_link_pipelink', 'link_id', 'int4', 'Column link_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'code', 'text', 'Column code should be text');
SELECT col_type_is('ve_link_pipelink', 'sys_code', 'text', 'Column sys_code should be text');
SELECT col_type_is('ve_link_pipelink', 'top_elev1', 'float8', 'Column top_elev1 should be float8');
SELECT col_type_is('ve_link_pipelink', 'depth1', 'numeric(12,4)', 'Column depth1 should be numeric(12,4)');
SELECT col_type_is('ve_link_pipelink', 'elevation1', 'float8', 'Column elevation1 should be float8');
SELECT col_type_is('ve_link_pipelink', 'exit_id', 'int4', 'Column exit_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'exit_type', 'varchar(16)', 'Column exit_type should be varchar(16)');
SELECT col_type_is('ve_link_pipelink', 'top_elev2', 'float8', 'Column top_elev2 should be float8');
SELECT col_type_is('ve_link_pipelink', 'depth2', 'numeric(12,4)', 'Column depth2 should be numeric(12,4)');
SELECT col_type_is('ve_link_pipelink', 'elevation2', 'float8', 'Column elevation2 should be float8');
SELECT col_type_is('ve_link_pipelink', 'feature_type', 'varchar(16)', 'Column feature_type should be varchar(16)');
SELECT col_type_is('ve_link_pipelink', 'feature_id', 'int4', 'Column feature_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'link_type', 'varchar(30)', 'Column link_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'sys_type', 'varchar(30)', 'Column sys_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'linkcat_id', 'varchar(30)', 'Column linkcat_id should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'matcat_id', 'varchar(30)', 'Column matcat_id should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'cat_dnom', 'varchar(16)', 'Column cat_dnom should be varchar(16)');
SELECT col_type_is('ve_link_pipelink', 'cat_dint', 'numeric(12,5)', 'Column cat_dint should be numeric(12,5)');
SELECT col_type_is('ve_link_pipelink', 'cat_pnom', 'varchar(16)', 'Column cat_pnom should be varchar(16)');
SELECT col_type_is('ve_link_pipelink', 'state', 'int2', 'Column state should be int2');
SELECT col_type_is('ve_link_pipelink', 'state_type', 'int2', 'Column state_type should be int2');
SELECT col_type_is('ve_link_pipelink', 'expl_id', 'int4', 'Column expl_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'macroexpl_id', 'int4', 'Column macroexpl_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'muni_id', 'int4', 'Column muni_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'sector_id', 'int4', 'Column sector_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'macrosector_id', 'int4', 'Column macrosector_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'sector_type', 'varchar(30)', 'Column sector_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'supplyzone_id', 'int4', 'Column supplyzone_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'supplyzone_type', 'varchar(30)', 'Column supplyzone_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'presszone_id', 'int4', 'Column presszone_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'presszone_type', 'varchar(30)', 'Column presszone_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'presszone_head', 'numeric(12,2)', 'Column presszone_head should be numeric(12,2)');
SELECT col_type_is('ve_link_pipelink', 'dma_id', 'int4', 'Column dma_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'macrodma_id', 'int4', 'Column macrodma_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'dma_type', 'varchar(30)', 'Column dma_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'dqa_id', 'int4', 'Column dqa_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'macrodqa_id', 'int4', 'Column macrodqa_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'dqa_type', 'varchar(30)', 'Column dqa_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'omzone_id', 'int4', 'Column omzone_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'macroomzone_id', 'int4', 'Column macroomzone_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'omzone_type', 'varchar(30)', 'Column omzone_type should be varchar(30)');
SELECT col_type_is('ve_link_pipelink', 'minsector_id', 'int4', 'Column minsector_id should be int4');
SELECT col_type_is('ve_link_pipelink', 'location_type', 'varchar(50)', 'Column location_type should be varchar(50)');
SELECT col_type_is('ve_link_pipelink', 'fluid_type', 'varchar(50)', 'Column fluid_type should be varchar(50)');
SELECT col_type_is('ve_link_pipelink', 'custom_length', 'numeric(12,2)', 'Column custom_length should be numeric(12,2)');
SELECT col_type_is('ve_link_pipelink', 'gis_length', 'numeric(12,3)', 'Column gis_length should be numeric(12,3)');
SELECT col_type_is('ve_link_pipelink', 'staticpressure1', 'numeric(12,3)', 'Column staticpressure1 should be numeric(12,3)');
SELECT col_type_is('ve_link_pipelink', 'staticpressure2', 'numeric(12,3)', 'Column staticpressure2 should be numeric(12,3)');
SELECT col_type_is('ve_link_pipelink', 'annotation', 'text', 'Column annotation should be text');
SELECT col_type_is('ve_link_pipelink', 'observ', 'text', 'Column observ should be text');
SELECT col_type_is('ve_link_pipelink', 'comment', 'text', 'Column comment should be text');
SELECT col_type_is('ve_link_pipelink', 'descript', 'varchar(254)', 'Column descript should be varchar(254)');
SELECT col_type_is('ve_link_pipelink', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('ve_link_pipelink', 'num_value', 'numeric(12,3)', 'Column num_value should be numeric(12,3)');
SELECT col_type_is('ve_link_pipelink', 'workcat_id', 'varchar(255)', 'Column workcat_id should be varchar(255)');
SELECT col_type_is('ve_link_pipelink', 'workcat_id_end', 'varchar(255)', 'Column workcat_id_end should be varchar(255)');
SELECT col_type_is('ve_link_pipelink', 'builtdate', 'date', 'Column builtdate should be date');
SELECT col_type_is('ve_link_pipelink', 'enddate', 'date', 'Column enddate should be date');
SELECT col_type_is('ve_link_pipelink', 'brand_id', 'varchar(50)', 'Column brand_id should be varchar(50)');
SELECT col_type_is('ve_link_pipelink', 'model_id', 'varchar(50)', 'Column model_id should be varchar(50)');
SELECT col_type_is('ve_link_pipelink', 'verified', 'int2', 'Column verified should be int2');
SELECT col_type_is('ve_link_pipelink', 'uncertain', 'bool', 'Column uncertain should be bool');
SELECT col_type_is('ve_link_pipelink', 'userdefined_geom', 'bool', 'Column userdefined_geom should be bool');
SELECT col_type_is('ve_link_pipelink', 'datasource', 'int4', 'Column datasource should be int4');
SELECT col_type_is('ve_link_pipelink', 'is_operative', 'bool', 'Column is_operative should be bool');
SELECT col_type_is('ve_link_pipelink', 'sector_style', 'text', 'Column sector_style should be text');
SELECT col_type_is('ve_link_pipelink', 'omzone_style', 'text', 'Column omzone_style should be text');
SELECT col_type_is('ve_link_pipelink', 'dma_style', 'text', 'Column dma_style should be text');
SELECT col_type_is('ve_link_pipelink', 'presszone_style', 'text', 'Column presszone_style should be text');
SELECT col_type_is('ve_link_pipelink', 'dqa_style', 'text', 'Column dqa_style should be text');
SELECT col_type_is('ve_link_pipelink', 'supplyzone_style', 'text', 'Column supplyzone_style should be text');
SELECT col_type_is('ve_link_pipelink', 'inp_type', 'text', 'Column inp_type should be text');
SELECT col_type_is('ve_link_pipelink', 'lock_level', 'int4', 'Column lock_level should be int4');
SELECT col_type_is('ve_link_pipelink', 'expl_visibility', 'int2[]', 'Column expl_visibility should be int2[]');
SELECT col_type_is('ve_link_pipelink', 'created_at', 'timestamp with time zone', 'Column created_at should be timestamp with time zone');
SELECT col_type_is('ve_link_pipelink', 'created_by', 'varchar(50)', 'Column created_by should be varchar(50)');
SELECT col_type_is('ve_link_pipelink', 'updated_at', 'timestamp with time zone', 'Column updated_at should be timestamp with time zone');
SELECT col_type_is('ve_link_pipelink', 'updated_by', 'varchar(50)', 'Column updated_by should be varchar(50)');
SELECT col_type_is('ve_link_pipelink', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
SELECT col_type_is('ve_link_pipelink', 'p_state', 'int2', 'Column p_state should be int2');
SELECT col_type_is('ve_link_pipelink', 'uuid', 'uuid', 'Column uuid should be uuid');

SELECT col_type_is('ve_link_pipelink', 'dataquality', 'int4', 'Column dataquality should be int4');
SELECT col_type_is('ve_link_pipelink', 'dataquality_obs', 'text[]', 'Column dataquality_obs should be text[]');

SELECT * FROM finish();

ROLLBACK;

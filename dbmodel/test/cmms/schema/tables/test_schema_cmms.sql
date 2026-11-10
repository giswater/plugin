/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT * FROM no_plan();

SELECT has_table('sys_version'::name, 'Table sys_version should exist');
SELECT has_table('visit'::name, 'Table visit should exist');
SELECT has_table('attachment'::name, 'Table attachment should exist');
SELECT hasnt_table('asset_feature_map'::name, 'Table asset_feature_map should not exist');
SELECT has_table('attachment_x_feature'::name, 'Table attachment_x_feature should exist');
SELECT has_table('attachment_x_visit'::name, 'Table attachment_x_visit should exist');
SELECT has_table('visit_x_feature'::name, 'Table visit_x_feature should exist');

SELECT has_pk('visit', 'Table visit should have a primary key');

SELECT has_column('visit', 'the_geom', 'visit.the_geom should exist');
SELECT has_column('visit_x_feature', 'sys_code', 'visit_x_feature.sys_code should exist');
SELECT col_not_null('visit_x_feature', 'sys_code', 'visit_x_feature.sys_code is required');
SELECT hasnt_column('visit_x_feature', 'asset_feature_map_id', 'visit_x_feature has no map id');
SELECT has_column('attachment_x_feature', 'sys_code', 'attachment_x_feature.sys_code should exist');
SELECT col_not_null('attachment_x_feature', 'sys_code', 'attachment_x_feature.sys_code is required');
SELECT hasnt_column('attachment_x_feature', 'asset_feature_map_id', 'attachment_x_feature has no map id');
SELECT has_index(
    'visit_x_feature',
    'visit_x_feature_unique',
    'one visit_x_feature row per sys_code and visit'
);
SELECT has_index(
    'attachment_x_feature',
    'attachment_x_feature_unique',
    'one attachment_x_feature row per sys_code and attachment'
);

SELECT has_function(
    'gw_fct_admin_sys_version_register',
    ARRAY['json'],
    'gw_fct_admin_sys_version_register(json) should exist'
);
SELECT has_function('set_updated_at_column', 'set_updated_at_column() should exist');
SELECT has_function(
    'gw_fct_cmms_create_parent_views',
    ARRAY['text'],
    'gw_fct_cmms_create_parent_views(text) should exist'
);
SELECT hasnt_function(
    'gw_trg_cmms_asset_feature_map_validate',
    'gw_trg_cmms_asset_feature_map_validate() should not exist'
);
SELECT hasnt_function(
    'gw_trg_cmms_feature_sync',
    'gw_trg_cmms_feature_sync() should not exist'
);

SELECT has_trigger('visit', 'trg_visit_set_updated_at', 'visit should stamp updated_at');

SELECT col_is_pk('sys_version', 'id', 'sys_version primary key is id');

SELECT * FROM finish();

ROLLBACK;

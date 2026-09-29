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
SELECT has_table('asset_feature_map'::name, 'Table asset_feature_map should exist');
SELECT has_table('attachment_x_feature'::name, 'Table attachment_x_feature should exist');
SELECT has_table('attachment_x_visit'::name, 'Table attachment_x_visit should exist');
SELECT has_table('visit_x_feature'::name, 'Table visit_x_feature should exist');

SELECT has_pk('visit', 'Table visit should have a primary key');
SELECT has_pk('asset_feature_map', 'Table asset_feature_map should have a primary key');

SELECT has_column('visit', 'the_geom', 'visit.the_geom should exist');
SELECT has_column('asset_feature_map', 'schema_name', 'asset_feature_map.schema_name should exist');
SELECT has_column('asset_feature_map', 'feature_id', 'asset_feature_map.feature_id should exist');

SELECT has_function(
    'gw_fct_admin_sys_version_register',
    ARRAY['json'],
    'gw_fct_admin_sys_version_register(json) should exist'
);
SELECT has_function('set_updated_at_column', 'set_updated_at_column() should exist');

SELECT has_trigger('visit', 'trg_visit_set_updated_at', 'visit should stamp updated_at');
SELECT has_trigger(
    'asset_feature_map',
    'trg_asset_feature_map_set_updated_at',
    'asset_feature_map should stamp updated_at'
);

SELECT col_is_pk('sys_version', 'id', 'sys_version primary key is id');

SELECT * FROM finish();

ROLLBACK;

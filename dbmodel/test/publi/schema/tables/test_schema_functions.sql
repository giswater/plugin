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
SELECT is(
    (SELECT project_type FROM sys_version ORDER BY id DESC LIMIT 1),
    'PUBLI',
    'sys_version should register the schema as PUBLI'
);

SELECT has_function('gw_fct_admin_sys_version_register', ARRAY['json'], 'gw_fct_admin_sys_version_register(json) should exist');
SELECT has_function('gw_fct_refresh_materialized_views', ARRAY[]::text[], 'gw_fct_refresh_materialized_views() should exist');
SELECT has_function('gw_fct_publi_seed_config', ARRAY['json'], 'gw_fct_publi_seed_config(json) should exist');
SELECT has_function('gw_fct_publi_sync', ARRAY['json'], 'gw_fct_publi_sync(json) should exist');
SELECT has_function('gw_fct_publi_reset_selectors', ARRAY['json'], 'gw_fct_publi_reset_selectors(json) should exist');
SELECT has_function('gw_fct_publi_build_staging', ARRAY['json'], 'gw_fct_publi_build_staging(json) should exist');
SELECT has_function('gw_fct_publi_apply_structure', ARRAY['json'], 'gw_fct_publi_apply_structure(json) should exist');
SELECT has_function('gw_fct_publi_apply_data', ARRAY['json'], 'gw_fct_publi_apply_data(json) should exist');
SELECT has_function('gw_fct_publi_apply_security', ARRAY['json'], 'gw_fct_publi_apply_security(json) should exist');
SELECT has_function('gw_fct_publi_set_metadata', ARRAY['json'], 'gw_fct_publi_set_metadata(json) should exist');
SELECT has_function('gw_fct_publi_user_ids', ARRAY['text', 'text', 'name'], 'gw_fct_publi_user_ids(text, text, name) should exist');

SELECT ok(
    EXISTS (SELECT 1 FROM config_process WHERE function_name = 'gw_fct_publi_sync' AND active),
    'config_process should register gw_fct_publi_sync'
);

SELECT * FROM finish();

ROLLBACK;

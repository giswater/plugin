/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "SCHEMA_NAME", public, pg_catalog;

ALTER TABLE IF EXISTS ext_cat_hydrometer RENAME TO ext_cat_hydrometer_old;
ALTER TABLE IF EXISTS ext_cat_hydrometer_priority RENAME TO ext_cat_hydrometer_priority_old;
ALTER TABLE IF EXISTS ext_cat_hydrometer_type RENAME TO ext_cat_hydrometer_type_old;
ALTER TABLE IF EXISTS ext_cat_hydrometer_category RENAME TO ext_cat_hydrometer_category_old;
ALTER TABLE IF EXISTS ext_cat_hydrometer_state RENAME TO ext_cat_hydrometer_state_old;
ALTER TABLE IF EXISTS ext_hydrometer RENAME TO ext_hydrometer_old;
ALTER TABLE IF EXISTS ext_hydrometer_period RENAME TO ext_hydrometer_period_old;

DELETE FROM sys_table WHERE id = 'ext_cat_hydrometer';
DELETE FROM sys_table WHERE id = 'ext_cat_hydrometer_priority';
DELETE FROM sys_table WHERE id = 'ext_cat_hydrometer_type';
DELETE FROM sys_table WHERE id = 'ext_cat_hydrometer_category';
DELETE FROM sys_table WHERE id = 'ext_cat_hydrometer_state';
DELETE FROM sys_table WHERE id = 'ext_hydrometer';
DELETE FROM sys_table WHERE id = 'ext_hydrometer_period';
DELETE FROM sys_table WHERE id = 'ext_cat_period_type';
DELETE FROM sys_table WHERE id = 'ext_cat_period';

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["v_hydrometer"], "batchId":1}}$$);

CREATE OR REPLACE VIEW v_hydrometer AS
SELECT * FROM cibs.hydrometer;

CREATE OR REPLACE VIEW v_hydrometer_period AS
SELECT * FROM cibs.hydrometer_period;

CREATE OR REPLACE VIEW v_cat_hydrometer AS
SELECT * FROM cibs.cat_hydrometer;

CREATE OR REPLACE VIEW v_cat_hydrometer_state AS
SELECT * FROM cibs.cat_hydrometer_state;

CREATE OR REPLACE VIEW v_cat_hydrometer_priority AS
SELECT * FROM cibs.cat_hydrometer_priority;

CREATE OR REPLACE VIEW v_cat_hydrometer_type AS
SELECT * FROM cibs.cat_hydrometer_type;

CREATE OR REPLACE VIEW v_cat_hydrometer_category AS
SELECT * FROM cibs.cat_hydrometer_category;

CREATE OR REPLACE VIEW v_cat_period_type AS
SELECT * FROM cibs.cat_period_type;

CREATE OR REPLACE VIEW v_cat_period AS
SELECT * FROM cibs.cat_period;

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":1}}$$);

SELECT cibs.gw_fct_admin_sys_version_register(json_build_object(
	'data', json_build_object(
		'parentSchema', 'SCHEMA_NAME'
	)
)::json);

SELECT "SCHEMA_NAME".gw_fct_admin_sys_version_register(json_build_object(
	'data', json_build_object(
		'gwVersion', (SELECT giswater FROM sys_version ORDER BY id DESC LIMIT 1),
		'mergeAddparam', json_build_object(
			'satellites', json_build_object(
				'cibs', json_build_object('enabled', true, 'schema', 'cibs')
			)
		)
	)
)::json);

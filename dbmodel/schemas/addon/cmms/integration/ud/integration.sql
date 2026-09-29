/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT cmms.gw_fct_admin_sys_version_register(json_build_object(
	'data', json_build_object(
		'parentSchema', 'SCHEMA_NAME'
	)
)::json);

SELECT "SCHEMA_NAME".gw_fct_admin_sys_version_register(json_build_object(
	'data', json_build_object(
		'gwVersion', (SELECT giswater FROM sys_version ORDER BY id DESC LIMIT 1),
		'mergeAddparam', json_build_object(
			'satellites', json_build_object(
				'cmms', json_build_object('enabled', true, 'schema', 'cmms')
			)
		)
	)
)::json);

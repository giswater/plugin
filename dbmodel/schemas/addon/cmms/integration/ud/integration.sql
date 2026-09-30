/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "SCHEMA_NAME", public, pg_catalog;

DO $cmms_epsg$
DECLARE
	v_parent integer;
	v_cmms integer;
BEGIN
	SELECT epsg INTO v_parent FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT epsg INTO v_cmms FROM cmms.sys_version ORDER BY id DESC LIMIT 1;
	IF v_parent IS DISTINCT FROM v_cmms THEN
		RAISE EXCEPTION 'cmms EPSG % does not match parent schema % EPSG %', v_cmms, 'SCHEMA_NAME', v_parent;
	END IF;
END
$cmms_epsg$;

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

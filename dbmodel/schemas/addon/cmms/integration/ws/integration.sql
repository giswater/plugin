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

-- cmms.sys_version is appended once by the integrate profile's register_version
-- phase (it already receives parentSchema). A second call here duplicated the row.
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

-- Soft link: parent deletes orphan asset_feature_map, id changes rewrite feature_id.
-- The function lives in cmms; these triggers are the only parent-side objects.
DO $cmms_feature_sync$
DECLARE
    v_parent constant text := 'SCHEMA_NAME';
    v_table text;
    v_id_column text;
BEGIN
    FOREACH v_table IN ARRAY ARRAY['node', 'arc', 'connec', 'link', 'gully', 'element']
    LOOP
        IF to_regclass(format('%I.%I', v_parent, v_table)) IS NULL THEN
            CONTINUE;
        END IF;
        v_id_column := v_table || '_id';
        EXECUTE format(
            'DROP TRIGGER IF EXISTS gw_trg_cmms_feature_sync_delete ON %I.%I',
            v_parent, v_table
        );
        EXECUTE format(
            'DROP TRIGGER IF EXISTS gw_trg_cmms_feature_sync_id ON %I.%I',
            v_parent, v_table
        );
        EXECUTE format(
            'CREATE TRIGGER gw_trg_cmms_feature_sync_delete '
            'AFTER DELETE ON %I.%I '
            'FOR EACH ROW EXECUTE PROCEDURE cmms.gw_trg_cmms_feature_sync(%L)',
            v_parent, v_table, v_id_column
        );
        EXECUTE format(
            'CREATE TRIGGER gw_trg_cmms_feature_sync_id '
            'AFTER UPDATE OF %I ON %I.%I '
            'FOR EACH ROW WHEN (OLD.%I IS DISTINCT FROM NEW.%I) '
            'EXECUTE PROCEDURE cmms.gw_trg_cmms_feature_sync(%L)',
            v_id_column, v_parent, v_table, v_id_column, v_id_column, v_id_column
        );
    END LOOP;
END
$cmms_feature_sync$;

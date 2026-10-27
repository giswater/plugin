/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- Drop the parent-side views and tab config. cmms rows stay: they are keyed
-- by sys_code, so integrating this parent again (or another parent that
-- carries the same codes) shows them with no copy step.
CREATE OR REPLACE FUNCTION cmms.gw_fct_cmms_unlink_parent(p_parent text)
RETURNS json AS
$BODY$
DECLARE
	v_id integer;
BEGIN
	IF p_parent IS NULL OR btrim(p_parent) = '' THEN
		RETURN json_build_object('status', 'Accepted');
	END IF;

	IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = p_parent) THEN
		EXECUTE format('DROP VIEW IF EXISTS %I.v_cmms_attachment', p_parent);
		EXECUTE format('DROP VIEW IF EXISTS %I.v_cmms_visit', p_parent);
		EXECUTE format('DROP VIEW IF EXISTS %I.v_ui_cmms_attachment', p_parent);
		EXECUTE format('DROP VIEW IF EXISTS %I.v_ui_cmms_visit', p_parent);

		IF to_regclass(format('%I.config_form_tabs', p_parent)) IS NOT NULL THEN
			EXECUTE format('DELETE FROM %I.config_form_tabs WHERE tabname = %L', p_parent, 'tab_cmms');
		END IF;
		IF to_regclass(format('%I.config_form_fields', p_parent)) IS NOT NULL THEN
			EXECUTE format('DELETE FROM %I.config_form_fields WHERE tabname = %L', p_parent, 'tab_cmms');
		END IF;
		IF to_regclass(format('%I.config_form_tableview', p_parent)) IS NOT NULL THEN
			EXECUTE format(
				'DELETE FROM %I.config_form_tableview WHERE objectname IN (%L, %L)',
				p_parent, 'v_ui_cmms_visit', 'v_ui_cmms_attachment'
			);
		END IF;
		IF to_regclass(format('%I.sys_table', p_parent)) IS NOT NULL THEN
			EXECUTE format(
				'DELETE FROM %I.sys_table WHERE id IN (%L, %L, %L, %L)',
				p_parent, 'v_ui_cmms_visit', 'v_ui_cmms_attachment', 'v_cmms_visit', 'v_cmms_attachment'
			);
		END IF;
	END IF;

	SELECT id INTO v_id FROM cmms.sys_version ORDER BY id DESC LIMIT 1;
	IF v_id IS NOT NULL THEN
		UPDATE cmms.sys_version
		SET addparam = jsonb_set(
			COALESCE(addparam, '{}'::jsonb),
			'{parent_schemas}',
			COALESCE((
				SELECT jsonb_agg(elem)
				FROM jsonb_array_elements_text(COALESCE(addparam -> 'parent_schemas', '[]'::jsonb)) AS elem
				WHERE elem IS DISTINCT FROM p_parent
			), '[]'::jsonb),
			true
		)
		WHERE id = v_id;
	END IF;

	RETURN json_build_object('status', 'Accepted');
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

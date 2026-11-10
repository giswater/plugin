/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- parent_schemas is the only cmms text that stores the parent name.
-- v_ui_cmms_* reference the parent tables by oid, so the rename carries them.
CREATE OR REPLACE FUNCTION cmms.gw_fct_cmms_rename_parent(p_old text, p_new text)
RETURNS json AS
$BODY$
DECLARE
	v_id integer;
BEGIN
	IF p_old IS NULL OR p_new IS NULL OR btrim(p_old) = '' OR btrim(p_new) = '' OR p_old = p_new THEN
		RETURN json_build_object('status', 'Accepted');
	END IF;

	SELECT id INTO v_id FROM cmms.sys_version ORDER BY id DESC LIMIT 1;
	IF v_id IS NOT NULL THEN
		UPDATE cmms.sys_version
		SET addparam = jsonb_set(
			COALESCE(addparam, '{}'::jsonb),
			'{parent_schemas}',
			COALESCE((
				SELECT jsonb_agg(DISTINCT CASE WHEN elem = p_old THEN p_new ELSE elem END)
				FROM jsonb_array_elements_text(COALESCE(addparam -> 'parent_schemas', '[]'::jsonb)) AS elem
			), '[]'::jsonb),
			true
		)
		WHERE id = v_id;
	END IF;

	RETURN json_build_object('status', 'Accepted');
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

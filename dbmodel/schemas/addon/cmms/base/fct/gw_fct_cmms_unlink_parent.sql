/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION cmms.gw_fct_cmms_unlink_parent(p_parent text)
RETURNS json AS
$BODY$
DECLARE
	v_visit integer := 0;
	v_attachment integer := 0;
	v_map integer := 0;
	v_id integer;
BEGIN
	IF p_parent IS NULL OR btrim(p_parent) = '' THEN
		RETURN json_build_object(
			'status', 'Accepted',
			'asset_feature_map', 0,
			'visit_x_feature', 0,
			'attachment_x_feature', 0
		);
	END IF;

	-- Junction tables have no schema_name. They hang off asset_feature_map.
	DELETE FROM cmms.visit_x_feature AS v
	USING cmms.asset_feature_map AS m
	WHERE v.asset_feature_map_id = m.id
		AND m.schema_name = p_parent;
	GET DIAGNOSTICS v_visit = ROW_COUNT;

	DELETE FROM cmms.attachment_x_feature AS a
	USING cmms.asset_feature_map AS m
	WHERE a.asset_feature_map_id = m.id
		AND m.schema_name = p_parent;
	GET DIAGNOSTICS v_attachment = ROW_COUNT;

	DELETE FROM cmms.asset_feature_map WHERE schema_name = p_parent;
	GET DIAGNOSTICS v_map = ROW_COUNT;

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

	RETURN json_build_object(
		'status', 'Accepted',
		'asset_feature_map', v_map,
		'visit_x_feature', v_visit,
		'attachment_x_feature', v_attachment
	);
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

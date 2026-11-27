/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3576

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_set_expl_from_parent(
	p_expl_id integer,
	p_expl_visibility integer[],
	OUT o_expl_id integer,
	OUT o_expl_visibility integer[])
RETURNS record
LANGUAGE plpgsql
AS $function$
/*
Remap child exploitation to its parent and keep the child id in expl_visibility.
Then refuse the save if the current user has no permission on expl_id nor any
value in expl_visibility (vf_exploitation = cat_manager / admin_exploitation_x_user).

SELECT * FROM gw_fct_set_expl_from_parent(2, NULL);
SELECT * FROM gw_fct_set_expl_from_parent(2, ARRAY[3]::integer[]);
*/

DECLARE
	v_parent_id integer;
	v_child_id integer;
BEGIN

	o_expl_id := p_expl_id;
	o_expl_visibility := p_expl_visibility;

	IF o_expl_id IS NULL THEN
		RETURN;
	END IF;

	-- 1) Child exploitation: store original in expl_visibility, set expl_id = parent_id
	SELECT parent_id INTO v_parent_id
	FROM exploitation
	WHERE expl_id = o_expl_id;

	IF v_parent_id IS NOT NULL THEN
		v_child_id := o_expl_id;
		IF o_expl_visibility IS NULL OR NOT (v_child_id = ANY (o_expl_visibility)) THEN
			o_expl_visibility := array_append(COALESCE(o_expl_visibility, ARRAY[]::integer[]), v_child_id);
		END IF;
		o_expl_id := v_parent_id;
	END IF;

	-- 2) User must have permission on expl_id or some value in expl_visibility
	IF NOT EXISTS (
		SELECT 1
		FROM vf_exploitation vf
		WHERE vf.expl_id = ANY (
			array_append(COALESCE(o_expl_visibility, ARRAY[]::integer[]), o_expl_id)
		)
	) THEN
		EXECUTE format(
			'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"4762", "function":"3576","parameters":{"expl_id":"%s"}}}$$);',
			o_expl_id
		);
	END IF;

	RETURN;
END;
$function$;

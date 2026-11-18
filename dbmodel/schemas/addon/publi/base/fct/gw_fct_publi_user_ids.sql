/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_user_ids(p_schema text, p_column text, p_user name)
RETURNS integer[] AS
$BODY$

/*example
SELECT publi.gw_fct_publi_user_ids('ws', 'expl_id', current_user);

Ids (expl_id or sector_id) visible to p_user in <p_schema>, with the same rules as <p_schema>.vf_exploitation:
  - admin_exploitation_x_user false or missing: every exploitation
  - otherwise exploitations of the cat_manager rows whose rolename holds a role p_user is member of
sector_id: sectors whose expl_id (integer[] since 4.0) overlaps those exploitations; cat_manager has no sector_id.
Used by the publi_rls policies. SECURITY DEFINER because readers of publi have no access to the source
schema; the caller is passed explicitly since current_user inside a definer function is the owner.
*/

DECLARE
	v_rolecol text;
	v_filtered boolean;
	v_expl integer[];
	v_ids integer[];
BEGIN
	IF p_column NOT IN ('expl_id', 'sector_id') THEN
		RAISE EXCEPTION 'invalid column %', p_column;
	END IF;

	IF to_regclass(format('%I.config_param_system', p_schema)) IS NOT NULL THEN
		EXECUTE format('SELECT value::boolean FROM %I.config_param_system WHERE parameter = %L',
			p_schema, 'admin_exploitation_x_user')
		INTO v_filtered;
	END IF;

	IF COALESCE(v_filtered, false) IS FALSE THEN
		EXECUTE format('SELECT array_agg(expl_id) FROM %I.exploitation', p_schema) INTO v_expl;
	ELSE
		-- rolename since 3.6.11, username before
		SELECT attname INTO v_rolecol
		FROM pg_attribute
		WHERE attrelid = format('%I.cat_manager', p_schema)::regclass AND attname IN ('rolename', 'username')
		AND NOT attisdropped
		ORDER BY attname = 'rolename' DESC
		LIMIT 1;

		EXECUTE format(
			$q$SELECT array_agg(DISTINCT x)
			FROM %I.cat_manager m, unnest(m.expl_id) x
			WHERE m.active
			AND EXISTS (SELECT 1 FROM unnest(m.%I) u JOIN pg_roles r ON r.rolname = u
						WHERE pg_has_role($1, r.oid, 'MEMBER'))$q$,
			p_schema, v_rolecol)
		INTO v_expl
		USING p_user;
	END IF;

	IF p_column = 'expl_id' OR v_expl IS NULL THEN
		v_ids := v_expl;
	ELSIF (SELECT t.typcategory = 'A' FROM pg_attribute a JOIN pg_type t ON t.oid = a.atttypid
			WHERE a.attrelid = format('%I.sector', p_schema)::regclass AND a.attname = 'expl_id') THEN
		EXECUTE format('SELECT array_agg(sector_id) FROM %I.sector WHERE expl_id && $1', p_schema)
		INTO v_ids USING v_expl;
	ELSE
		EXECUTE format('SELECT array_agg(sector_id) FROM %I.sector WHERE expl_id = ANY ($1)', p_schema)
		INTO v_ids USING v_expl;
	END IF;

	RETURN COALESCE(v_ids, '{}');
END;
$BODY$
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public;

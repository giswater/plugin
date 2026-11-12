/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3580

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_core_feature_edit_request_get(bigint);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_core_feature_edit_request_get(p_id bigint)
 RETURNS TABLE(
	id bigint,
	table_name text,
	table_id integer,
	feature_code text,
	feature_type text,
	expl_id integer,
	field_user text,
	field_date timestamptz,
	field_annotation text,
	field_changes jsonb,
	review_changes jsonb,
	review_user text,
	review_date timestamptz,
	review_annotation text,
	status smallint,
	status_name text,
	child_layer text,
	current_values jsonb)
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT * FROM SCHEMA_NAME.gw_fct_core_feature_edit_request_get(1);

*/

DECLARE

v_rec record;
v_child text;
v_row jsonb;
v_current jsonb;
v_message_id text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	SELECT * INTO v_rec FROM feature_edit_request WHERE feature_edit_request.id = p_id;

	IF NOT FOUND THEN
		v_message_id := '4760';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3580')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_rec.field_changes IS NULL OR jsonb_typeof(v_rec.field_changes) <> 'object' THEN
		v_message_id := '4768';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3580')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_rec.table_name NOT IN ('node', 'arc', 'connec', 'link', 'gully')
		OR to_regclass(format('ve_%s', v_rec.table_name)) IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3580')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	EXECUTE format(
		'SELECT f.child_layer FROM %I t JOIN cat_feature f ON f.id = t.%I WHERE t.%I = $1',
		format('ve_%s', v_rec.table_name), v_rec.table_name || '_type', v_rec.table_name || '_id')
	INTO v_child
	USING v_rec.table_id;

	IF v_child IS NULL OR to_regclass(v_child) IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3580')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	EXECUTE format('SELECT to_jsonb(t) FROM %I t WHERE %I = $1', v_child, v_rec.table_name || '_id')
	INTO v_row
	USING v_rec.table_id;

	IF v_row IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3580')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	-- Same keys as field_changes. Values stay text, and a missing live value is JSON null.
	SELECT jsonb_object_agg(e.key, COALESCE(to_jsonb(v_row ->> e.key), 'null'::jsonb))
	INTO v_current
	FROM jsonb_object_keys(v_rec.field_changes) AS e(key);

	RETURN QUERY
	SELECT r.id, r.table_name, r.table_id,
		r.feature_code::text, r.feature_type::text, r.expl_id::integer,
		r.field_user, r.field_date, r.field_annotation, r.field_changes, r.review_changes,
		r.review_user, r.review_date, r.review_annotation,
		r.status, r.status_name::text,
		v_child, COALESCE(v_current, '{}'::jsonb)
	FROM v_ui_feature_edit_request r
	WHERE r.id = p_id;

	IF NOT FOUND THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3580')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

END;

$function$
;

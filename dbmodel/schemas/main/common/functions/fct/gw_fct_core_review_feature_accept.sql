/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3584

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_core_review_feature_accept(bigint, text, jsonb);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_core_review_feature_accept(
	p_id bigint,
	p_annotation text DEFAULT NULL,
	p_changes jsonb DEFAULT NULL)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_core_review_feature_accept(1, 'ok', '{"observ": "edited"}'::jsonb);

*/

DECLARE

v_rec record;
v_apply jsonb;
v_over jsonb;
v_child text;
v_cols text;
v_bad text;
v_count integer;
v_message_id text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	IF NOT pg_has_role(current_user, 'role_edit', 'member') THEN
		v_message_id := '4772';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT * INTO v_rec FROM review_feature WHERE id = p_id FOR UPDATE;

	IF NOT FOUND THEN
		v_message_id := '4760';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_rec.status <> 0 THEN
		v_message_id := '4762';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_rec.field_changes IS NULL OR jsonb_typeof(v_rec.field_changes) <> 'object' THEN
		v_message_id := '4768';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF p_changes IS NOT NULL AND jsonb_typeof(p_changes) <> 'object' THEN
		v_message_id := '4768';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT k INTO v_bad
	FROM jsonb_object_keys(COALESCE(p_changes, '{}'::jsonb)) AS k
	WHERE NOT (v_rec.field_changes ? k)
	LIMIT 1;

	IF v_bad IS NOT NULL THEN
		v_message_id := '4770';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object(
				'message', v_message_id,
				'function', '3584',
				'parameters', json_build_object('column', v_bad))));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT jsonb_object_agg(e.key, NULLIF(e.value, ''))
	INTO v_apply
	FROM jsonb_each_text(v_rec.field_changes) e;

	IF p_changes IS NOT NULL THEN
		SELECT jsonb_object_agg(e.key, NULLIF(e.value, ''))
		INTO v_over
		FROM jsonb_each_text(p_changes) e;
		v_apply := v_apply || COALESCE(v_over, '{}'::jsonb);
	END IF;

	IF v_apply IS NULL THEN
		v_message_id := '4768';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_rec.table_name NOT IN ('node', 'arc', 'connec', 'link', 'gully')
		OR to_regclass(format('ve_%s', v_rec.table_name)) IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
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
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT k INTO v_bad
	FROM jsonb_object_keys(v_apply) AS k
	WHERE NOT EXISTS (
		SELECT 1 FROM pg_attribute a
		WHERE a.attrelid = v_child::regclass
			AND a.attname = k
			AND a.attnum > 0
			AND NOT a.attisdropped)
	LIMIT 1;

	IF v_bad IS NOT NULL THEN
		v_message_id := '4766';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object(
				'message', v_message_id,
				'function', '3584',
				'parameters', json_build_object('column', v_bad))));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT string_agg(format('%I', k), ', ' ORDER BY k)
	INTO v_cols
	FROM jsonb_object_keys(v_apply) AS k;

	EXECUTE format(
		'UPDATE %I AS t SET (%s) = (SELECT %s FROM jsonb_populate_record(NULL::%I, $1)) WHERE t.%I = $2',
		v_child, v_cols, v_cols, v_child, v_rec.table_name || '_id')
	USING v_apply, v_rec.table_id;

	GET DIAGNOSTICS v_count = ROW_COUNT;
	IF v_count = 0 THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3584')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	UPDATE review_feature
	SET status = 1,
		review_user = current_user,
		review_date = now(),
		review_annotation = p_annotation,
		review_changes = v_apply
	WHERE id = p_id;

	RETURN true;

END;

$function$
;

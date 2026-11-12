/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3578

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_core_feature_edit_request_create(text, integer, jsonb, text);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_core_feature_edit_request_create(
	p_table_name text,
	p_table_id integer,
	p_changes jsonb,
	p_annotation text DEFAULT NULL)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_core_feature_edit_request_create('node', 1, '{"observ": "new"}'::jsonb, 'from the field');

*/

DECLARE

v_changes jsonb;
v_child text;
v_bad text;
v_hit integer;
v_id bigint;
v_message_id text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	IF p_changes IS NULL OR jsonb_typeof(p_changes) <> 'object' THEN
		v_message_id := '4768';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3578')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT jsonb_object_agg(e.key, NULLIF(e.value, ''))
	INTO v_changes
	FROM jsonb_each_text(p_changes) e;

	IF v_changes IS NULL THEN
		v_message_id := '4768';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3578')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF p_table_name IS NULL OR p_table_id IS NULL
		OR p_table_name NOT IN ('node', 'arc', 'connec', 'link', 'gully')
		OR to_regclass(format('ve_%s', p_table_name)) IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3578')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	EXECUTE format(
		'SELECT f.child_layer FROM %I t JOIN cat_feature f ON f.id = t.%I WHERE t.%I = $1',
		format('ve_%s', p_table_name), p_table_name || '_type', p_table_name || '_id')
	INTO v_child
	USING p_table_id;

	IF v_child IS NULL OR to_regclass(v_child) IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3578')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	EXECUTE format('SELECT 1 FROM %I WHERE %I = $1', v_child, p_table_name || '_id')
	INTO v_hit
	USING p_table_id;

	IF v_hit IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3578')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT k INTO v_bad
	FROM jsonb_object_keys(v_changes) AS k
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
				'function', '3578',
				'parameters', json_build_object('column', v_bad))));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	INSERT INTO feature_edit_request (table_name, table_id, field_annotation, field_changes)
	VALUES (p_table_name, p_table_id, p_annotation, v_changes)
	RETURNING feature_edit_request.id INTO v_id;

	RETURN v_id;

END;

$function$
;

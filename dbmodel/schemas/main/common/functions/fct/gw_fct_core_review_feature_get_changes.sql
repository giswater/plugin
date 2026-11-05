/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3582

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_core_review_feature_get_changes(bigint);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_core_review_feature_get_changes(p_id bigint)
 RETURNS TABLE(column_name text, current_value text, proposed_value text, applied_value text)
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT * FROM SCHEMA_NAME.gw_fct_core_review_feature_get_changes(1);

*/

DECLARE

v_rec record;
v_child text;
v_row jsonb;
v_message_id text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	SELECT * INTO v_rec FROM review_feature WHERE id = p_id;

	IF NOT FOUND THEN
		v_message_id := '4760';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3582')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_rec.table_name NOT IN ('node', 'arc', 'connec', 'link', 'gully')
		OR to_regclass(format('ve_%s', v_rec.table_name)) IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3582')));
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
			'data', json_build_object('message', v_message_id, 'function', '3582')));
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
			'data', json_build_object('message', v_message_id, 'function', '3582')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_rec.field_changes IS NULL OR jsonb_typeof(v_rec.field_changes) <> 'object' THEN
		v_message_id := '4768';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3582')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	RETURN QUERY
	SELECT e.key,
		v_row ->> e.key,
		v_rec.field_changes ->> e.key,
		v_rec.review_changes ->> e.key
	FROM jsonb_object_keys(v_rec.field_changes) AS e(key);

END;

$function$
;

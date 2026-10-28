/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3576

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_manage_review_feature(json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_manage_review_feature(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_manage_review_feature($${"client":{"device":4, "lang":"en_US"},
"data":{"action":"GET", "id":1}}$$);

SELECT SCHEMA_NAME.gw_fct_manage_review_feature($${"client":{"device":4, "lang":"en_US"},
"data":{"action":"ACCEPT", "id":1, "annotation":"ok", "fields":{"observ":"new"}}}$$);

SELECT SCHEMA_NAME.gw_fct_manage_review_feature($${"client":{"device":4, "lang":"en_US"},
"data":{"action":"REJECT", "id":1, "annotation":"no"}}$$);

*/

DECLARE

v_version text;
v_action text;
v_id bigint;
v_annotation text;
v_message_id text;
v_rec record;
v_table text;
v_idname text;
v_child text;
v_feature json;
v_review json;
v_changes jsonb;
v_apply jsonb;
v_form_fields text[];
v_raw text;
v_field jsonb;
v_by_col jsonb := '{}'::jsonb;
v_col text;
v_proposed text;
v_current text;
v_fields jsonb := '[]'::jsonb;
v_device integer;
v_set text;
v_count integer;
v_error_context text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_action := upper(p_data -> 'data' ->> 'action');
	v_id := (p_data -> 'data' ->> 'id')::bigint;
	v_annotation := p_data -> 'data' ->> 'annotation';
	v_device := COALESCE((p_data -> 'client' ->> 'device')::integer, 4);

	IF v_action IN ('ACCEPT', 'REJECT') THEN
		SELECT * INTO v_rec FROM review_feature WHERE id = v_id FOR UPDATE;
	ELSE
		SELECT * INTO v_rec FROM review_feature WHERE id = v_id;
	END IF;

	IF NOT FOUND THEN
		v_message_id := '4760';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3576')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_action IN ('ACCEPT', 'REJECT') AND v_rec.status <> 0 THEN
		v_message_id := '4762';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3576')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_action = 'REJECT' THEN
		UPDATE review_feature
		SET status = 2, review_user = current_user, review_date = now(), review_annotation = v_annotation
		WHERE id = v_id;

		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Accepted',
			'version', COALESCE(v_version, ''),
			'body', json_build_object(
				'form', '{}'::json,
				'feature', '{}'::json,
				'data', json_build_object('id', v_id, 'status', 2)
			)
		), 3576, null, null, null);
	END IF;

	IF v_action NOT IN ('GET', 'ACCEPT') THEN
		RAISE EXCEPTION 'Unknown review action %', v_action;
	END IF;

	v_table := v_rec.table_name;
	v_idname := v_table || '_id';
	v_changes := v_rec.field_changes;

	IF v_table NOT IN ('node', 'arc', 'connec', 'link', 'gully') OR jsonb_typeof(v_changes) <> 'object' THEN
		RAISE EXCEPTION 'Review % has an invalid table or field_changes', v_id;
	END IF;

	EXECUTE format(
		'SELECT f.child_layer FROM %I t JOIN cat_feature f ON f.id = t.%I WHERE t.%I = $1',
		format('ve_%s', v_table), v_table || '_type', v_idname)
	INTO v_child
	USING v_rec.table_id;

	IF v_child IS NOT NULL THEN
		EXECUTE format('SELECT row_to_json(t) FROM %I t WHERE %I = $1', v_child, v_idname)
		INTO v_feature
		USING v_rec.table_id;
	END IF;

	IF v_child IS NULL OR v_feature IS NULL THEN
		v_message_id := '4764';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3576')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_action = 'ACCEPT' THEN
		v_apply := p_data -> 'data' -> 'fields';
		IF v_apply IS NULL OR jsonb_typeof(v_apply) <> 'object' OR v_apply = '{}'::jsonb THEN
			v_apply := v_changes;
		END IF;

		SELECT string_agg(
			CASE
				WHEN value IS NULL THEN format('%I = NULL', key)
				ELSE format('%I = %L', key, value)
			END,
			', ')
		INTO v_set
		FROM jsonb_each_text(v_apply);

		IF v_set IS NULL THEN
			RAISE EXCEPTION 'Review % has no fields to apply', v_id;
		END IF;

		EXECUTE format('UPDATE %I SET %s WHERE %I = %L', v_child, v_set, v_idname, v_rec.table_id);
		GET DIAGNOSTICS v_count = ROW_COUNT;
		IF v_count = 0 THEN
			v_message_id := '4764';
			PERFORM gw_fct_getmessage(json_build_object(
				'client', json_build_object('device', 4, 'lang', 'en_US'),
				'feature', '{}'::json,
				'data', json_build_object('message', v_message_id, 'function', '3576')));
			RAISE EXCEPTION 'Review message % was not raised', v_message_id;
		END IF;

		UPDATE review_feature
		SET status = 1, review_user = current_user, review_date = now(), review_annotation = v_annotation
		WHERE id = v_id;

		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Accepted',
			'version', COALESCE(v_version, ''),
			'body', json_build_object(
				'form', '{}'::json,
				'feature', '{}'::json,
				'data', json_build_object('id', v_id, 'status', 1)
			)
		), 3576, null, null, null);
	END IF;

	-- GET: one widget per changed column, taken from the feature form.
	-- A broken combo query must not hide the proposed values, so fall back to plain text widgets.
	BEGIN
		v_form_fields := gw_fct_getformfields(v_child, 'form_feature', 'tab_data', NULL, NULL, NULL, NULL, 'UPDATE', NULL, v_device, NULL);
	EXCEPTION WHEN OTHERS THEN
		v_form_fields := NULL;
	END;

	IF v_form_fields IS NOT NULL THEN
		FOREACH v_raw IN ARRAY v_form_fields
		LOOP
			IF v_raw IS NULL OR btrim(v_raw) = '' THEN
				CONTINUE;
			END IF;
			v_field := v_raw::jsonb;
			v_col := v_field ->> 'columnname';
			IF v_col IS NULL OR NOT (v_changes ? v_col) OR v_by_col ? v_col THEN
				CONTINUE;
			END IF;
			IF COALESCE(v_field ->> 'widgettype', '') IN ('', 'hspacer', 'vspacer', 'button', 'tablewidget', 'tableview', 'tabwidget', 'divider', 'image', 'label') THEN
				CONTINUE;
			END IF;
			v_by_col := v_by_col || jsonb_build_object(v_col, v_field);
		END LOOP;
	END IF;

	FOR v_col IN SELECT jsonb_object_keys(v_changes)
	LOOP
		v_proposed := v_changes ->> v_col;
		v_current := v_feature ->> v_col;
		v_field := v_by_col -> v_col;
		IF v_field IS NULL OR jsonb_typeof(v_field) = 'null' THEN
			v_field := jsonb_build_object(
				'columnname', v_col,
				'widgetname', 'tab_data_' || v_col,
				'widgettype', 'text',
				'datatype', 'string',
				'label', v_col,
				'layoutname', 'lyt_data_1',
				'layoutorder', 1
			);
		END IF;

		v_field := jsonb_set(v_field, '{iseditable}', 'true'::jsonb, true);
		v_field := jsonb_set(v_field, '{ismandatory}', 'false'::jsonb, true);
		v_field := jsonb_set(v_field, '{hidden}', 'false'::jsonb, true);
		IF v_field ? 'widgetcontrols' AND jsonb_typeof(v_field -> 'widgetcontrols') = 'object' THEN
			v_field := jsonb_set(v_field, '{widgetcontrols,isEnabled}', 'true'::jsonb, true);
		END IF;
		v_field := v_field - 'widgetfunction' - 'widgetaction' - 'updateaction' - 'changeaction';

		v_field := gw_fct_json_object_set_key(v_field::json, 'value', COALESCE(v_proposed, ''))::jsonb;
		v_field := gw_fct_json_object_set_key(v_field::json, 'currentValue', COALESCE(v_current, ''))::jsonb;
		IF v_field ->> 'widgettype' = 'combo' THEN
			v_field := gw_fct_json_object_set_key(v_field::json, 'selectedId', COALESCE(v_proposed, ''))::jsonb;
		END IF;

		v_fields := v_fields || jsonb_build_array(v_field);
	END LOOP;

	SELECT row_to_json(a) INTO v_review
	FROM (
		SELECT id, table_name, table_id, feature_code, feature_type, field_user, field_date, field_annotation,
			review_annotation, status
		FROM v_ui_review_feature
		WHERE id = v_id
	) a;

	RETURN gw_fct_json_create_return(json_build_object(
		'status', 'Accepted',
		'version', COALESCE(v_version, ''),
		'body', json_build_object(
			'form', '{}'::json,
			'feature', '{}'::json,
			'data', json_build_object('review', COALESCE(v_review, '{}'::json), 'fields', v_fields)
		)
	), 3576, null, null, null);

EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
		RETURN json_build_object(
			'status', 'Failed',
			'NOSQLERR', SQLERRM,
			'SQLSTATE', SQLSTATE,
			'SQLCONTEXT', v_error_context,
			'version', COALESCE(v_version, ''));
END;

$function$
;

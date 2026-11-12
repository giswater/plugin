/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3576

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_manage_feature_edit_request(json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_manage_feature_edit_request(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_manage_feature_edit_request($${"client":{"device":4, "lang":"en_US"},
"data":{"action":"CREATE", "tableName":"node", "tableId":1, "annotation":"from the field", "fields":{"observ":"new"}}}$$);

SELECT SCHEMA_NAME.gw_fct_manage_feature_edit_request($${"client":{"device":4, "lang":"en_US"},
"data":{"action":"GET", "id":1}}$$);

SELECT SCHEMA_NAME.gw_fct_manage_feature_edit_request($${"client":{"device":4, "lang":"en_US"},
"data":{"action":"ACCEPT", "id":1, "annotation":"ok", "fields":{"observ":"new"}}}$$);

SELECT SCHEMA_NAME.gw_fct_manage_feature_edit_request($${"client":{"device":4, "lang":"en_US"},
"data":{"action":"REJECT", "id":1, "annotation":"no"}}$$);

*/

DECLARE

v_version text;
v_action text;
v_id bigint;
v_annotation text;
v_child text;
v_review json;
v_status integer;
v_form_fields text[];
v_raw text;
v_field jsonb;
v_by_col jsonb := '{}'::jsonb;
v_col text;
v_chg record;
v_selected text;
v_fields jsonb := '[]'::jsonb;
v_device integer;
v_error_context text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_action := upper(p_data -> 'data' ->> 'action');
	v_annotation := p_data -> 'data' ->> 'annotation';
	v_device := COALESCE((p_data -> 'client' ->> 'device')::integer, 4);

	IF v_action = 'CREATE' THEN
		v_id := gw_fct_core_feature_edit_request_create(
			p_data -> 'data' ->> 'tableName',
			(p_data -> 'data' ->> 'tableId')::integer,
			(p_data -> 'data' -> 'fields')::jsonb,
			v_annotation);

		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Accepted',
			'version', COALESCE(v_version, ''),
			'body', json_build_object(
				'form', '{}'::json,
				'feature', '{}'::json,
				'data', json_build_object('id', v_id)
			)
		), 3576, null, null, null);
	END IF;

	v_id := (p_data -> 'data' ->> 'id')::bigint;

	IF v_action = 'ACCEPT' THEN
		PERFORM gw_fct_core_feature_edit_request_accept(v_id, v_annotation, (p_data -> 'data' -> 'fields')::jsonb);

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

	IF v_action = 'REJECT' THEN
		PERFORM gw_fct_core_feature_edit_request_reject(v_id, v_annotation);

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

	IF v_action <> 'GET' THEN
		RAISE EXCEPTION 'Unknown review action %', v_action;
	END IF;

	SELECT row_to_json(a) INTO v_review
	FROM gw_fct_core_feature_edit_request_get(v_id) a;

	v_child := v_review ->> 'child_layer';
	v_status := (v_review ->> 'status')::integer;

	-- One widget per changed column, taken from the feature form.
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
			IF v_col IS NULL OR v_by_col ? v_col THEN
				CONTINUE;
			END IF;
			IF COALESCE(v_field ->> 'widgettype', '') IN ('', 'hspacer', 'vspacer', 'button', 'tablewidget', 'tableview', 'tabwidget', 'divider', 'image', 'label') THEN
				CONTINUE;
			END IF;
			v_by_col := v_by_col || jsonb_build_object(v_col, v_field);
		END LOOP;
	END IF;

	FOR v_chg IN
		SELECT * FROM gw_fct_core_feature_edit_request_get_changes(v_id)
	LOOP
		v_col := v_chg.column_name;
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

		-- Accepted reviews show the applied value in the right-hand column. The rest show the proposal.
		IF v_status = 1 THEN
			v_selected := COALESCE(v_chg.applied_value, '');
		ELSE
			v_selected := COALESCE(v_chg.proposed_value, '');
		END IF;

		v_field := gw_fct_json_object_set_key(v_field::json, 'value', COALESCE(v_chg.proposed_value, ''))::jsonb;
		v_field := gw_fct_json_object_set_key(v_field::json, 'currentValue', COALESCE(v_chg.current_value, ''))::jsonb;
		v_field := gw_fct_json_object_set_key(v_field::json, 'appliedValue', COALESCE(v_chg.applied_value, ''))::jsonb;
		IF v_field ->> 'widgettype' = 'combo' THEN
			v_field := gw_fct_json_object_set_key(v_field::json, 'selectedId', v_selected)::jsonb;
		END IF;

		v_fields := v_fields || jsonb_build_array(v_field);
	END LOOP;

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

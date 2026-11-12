/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3586

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_core_feature_edit_request_reject(bigint, text);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_core_feature_edit_request_reject(
	p_id bigint,
	p_annotation text DEFAULT NULL)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_core_feature_edit_request_reject(1, 'no');

*/

DECLARE

v_status smallint;
v_message_id text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	IF NOT pg_has_role(current_user, 'role_edit', 'member') THEN
		v_message_id := '4772';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3586')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	SELECT status INTO v_status FROM feature_edit_request WHERE id = p_id FOR UPDATE;

	IF NOT FOUND THEN
		v_message_id := '4760';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3586')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	IF v_status <> 0 THEN
		v_message_id := '4762';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3586')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	UPDATE feature_edit_request
	SET status = 2,
		review_user = current_user,
		review_date = now(),
		review_annotation = p_annotation
	WHERE id = p_id;

	RETURN true;

END;

$function$
;

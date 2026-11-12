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
	child_layer text,
	feature_code text,
	feature_type text,
	expl_id integer,
	status smallint,
	status_name text,
	field_user text,
	field_date timestamptz,
	field_annotation text,
	review_user text,
	review_date timestamptz,
	review_annotation text)
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT * FROM SCHEMA_NAME.gw_fct_core_feature_edit_request_get(1);

*/

DECLARE

v_message_id text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	IF NOT EXISTS (SELECT 1 FROM feature_edit_request r WHERE r.id = p_id) THEN
		v_message_id := '4760';
		PERFORM gw_fct_getmessage(json_build_object(
			'client', json_build_object('device', 4, 'lang', 'en_US'),
			'feature', '{}'::json,
			'data', json_build_object('message', v_message_id, 'function', '3580')));
		RAISE EXCEPTION 'Review message % was not raised', v_message_id;
	END IF;

	RETURN QUERY
	SELECT r.id, r.table_name, r.table_id, f.child_layer::text,
		r.feature_code::text, r.feature_type::text, r.expl_id,
		r.status, r.status_name::text,
		r.field_user, r.field_date, r.field_annotation,
		r.review_user, r.review_date, r.review_annotation
	FROM v_ui_feature_edit_request r
	JOIN cat_feature f ON f.id = r.feature_type AND f.child_layer IS NOT NULL
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

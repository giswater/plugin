/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3582

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_core_feature_edit_request_get_changes(bigint);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_core_feature_edit_request_get_list();

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_core_feature_edit_request_get_list()
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
	status_name text)
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:

SELECT * FROM SCHEMA_NAME.gw_fct_core_feature_edit_request_get_list();

*/

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	-- The view is created in the ws/ud patch, after these functions are loaded.
	RETURN QUERY
	SELECT r.id, r.table_name, r.table_id,
		r.feature_code::text, r.feature_type::text, r.expl_id::integer,
		r.field_user, r.field_date, r.field_annotation, r.field_changes, r.review_changes,
		r.review_user, r.review_date, r.review_annotation,
		r.status, r.status_name::text
	FROM v_ui_feature_edit_request r;

END;

$function$
;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3030

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_get_project_layers(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_get_project_layers(p_data json)
  RETURNS json AS
$BODY$
/*EXAMPLE:

*/

DECLARE
v_version text;
v_status text;
v_level integer = 1;
v_message text;
v_querystring text;
v_funcname text;
v_flag int;
v_vars json;
v_records json;
v_key text;
v_value text;
v_msgerr text;
v_error_context text;
v_error boolean = False;

v_project_type text;
project_type_id integer;
v_layers text[];
v_result_info json;
v_fields_array json;
item json;
v_final json;
v_is_cm boolean;

BEGIN
	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	v_project_type := (p_data ->> 'data')::json->> 'project_type';
	v_is_cm := COALESCE(((p_data ->> 'data')::json->>'is_cm')::boolean, FALSE);

	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	SELECT id INTO project_type_id FROM config_typevalue WHERE typevalue = 'project_type' AND idval = v_project_type;

	IF v_is_cm IS TRUE THEN
		-- For CM projects, get all base layers plus the CM-specific layers
		SELECT COALESCE((SELECT array_to_json(array_agg(row_to_json(d)))
		FROM (
			SELECT
				orderby,
				group_order,
				project_template,
				context,
				"layerName",
				"tableName",
				"tableSchema",
				"geomField",
				"tableId",
				"providerConfig"
			FROM (
				-- Base layers from main schema
				SELECT
					st.orderby,
					(ct.addparam->>'orderBy')::integer as group_order,
					st.project_template,
					concat('{"levels": ', ct.idval, '}') AS context,
					st.alias AS "layerName",
					st.id AS "tableName",
					COALESCE(c.table_schema, 'SCHEMA_NAME') AS "tableSchema",
					CASE
						WHEN c.column_name IS NULL THEN 'None'
						WHEN st.addparam->>'geom' IS NOT NULL THEN st.addparam->>'geom'
						ELSE c.column_name
					END AS "geomField",
					CASE
						WHEN st.addparam->>'pkey' IS NULL THEN i.column_name
						ELSE st.addparam->>'pkey'
					END AS "tableId",
					st.provider_config AS "providerConfig"
				FROM v_sys_table st
				JOIN v_config_typevalue ct ON ct.id = st.context
				LEFT JOIN (
					SELECT column_name, table_name, table_schema FROM information_schema.columns
					WHERE udt_name='geometry' and table_schema IN ('SCHEMA_NAME', 'am')
				) c ON st.id = c.table_name
				LEFT JOIN (
					SELECT column_name, table_name FROM information_schema.columns
					WHERE ordinal_position=1 and table_schema IN ('SCHEMA_NAME', 'am')
				) i ON st.id = i.table_name
				WHERE
					ct.typevalue = 'sys_table_context' AND
					(c.column_name IS NULL OR c.column_name != 'link_the_geom') AND
					st.project_template->'template' @> to_jsonb(ARRAY[project_type_id]) AND
					st.project_template IS NOT NULL

				UNION ALL

				-- Additional layers from 'cm' schema
				SELECT
					st.orderby,
					999 as group_order, -- CM layers go last
					st.project_template,
					concat('{"levels": ', t.idval, '}') as context,
					COALESCE(st.alias, st.id) as "layerName",
					st.id as "tableName",
					'cm' AS "tableSchema",
					CASE
						WHEN c.column_name IS NULL THEN 'None'
						WHEN st.addparam->>'geom' IS NOT NULL THEN st.addparam->>'geom'
						ELSE c.column_name
					END AS "geomField",
					CASE
						WHEN st.addparam->>'pkey' IS NULL THEN i.column_name
						ELSE st.addparam->>'pkey'
					END AS "tableId",
					NULL::jsonb AS "providerConfig"
				FROM cm.v_sys_table st
				JOIN cm.sys_typevalue t ON t.id = st.context
				LEFT JOIN (
					SELECT column_name, table_name FROM information_schema.columns
					WHERE udt_name = 'geometry' AND table_schema = 'cm'
				) c ON st.id = c.table_name
				LEFT JOIN (
					SELECT column_name, table_name FROM information_schema.columns
					WHERE ordinal_position = 1 AND table_schema = 'cm'
				) i ON st.id = i.table_name
				WHERE st.project_template IS NOT NULL AND t.typevalue = 'sys_table_context'
			) as layers
			ORDER BY
				CASE "tableSchema"
					WHEN 'cm' THEN 2
					ELSE 1
				END,
				group_order desc,
				orderby desc
		) d), '[]'::json) INTO v_final;

	ELSE
		-- Standard logic for non-CM projects
		SELECT COALESCE((SELECT array_to_json(array_agg(row_to_json(d)))
		FROM (
			SELECT
				st.orderby,
				(ct.addparam->>'orderBy')::integer as group_order,
				st.project_template,
				concat('{"levels": ', ct.idval, '}') AS context,
				st.alias AS "layerName",
				st.id AS "tableName",
				COALESCE(c.table_schema, 'SCHEMA_NAME') AS "tableSchema",
				CASE
					WHEN c.column_name IS NULL THEN 'None'
					WHEN st.addparam->>'geom' IS NOT NULL THEN st.addparam->>'geom'
					ELSE c.column_name
				END AS "geomField",
				CASE
					WHEN st.addparam->>'pkey' IS NULL THEN i.column_name
					ELSE st.addparam->>'pkey'
				END AS "tableId",
				st.addparam,
				st.provider_config AS "providerConfig"
			FROM v_sys_table st
			JOIN v_config_typevalue ct ON ct.id = st.context
			LEFT JOIN (
				SELECT column_name, table_name, table_schema FROM information_schema.columns
				WHERE udt_name='geometry' and table_schema IN ('SCHEMA_NAME', 'am')
			) c ON st.id = c.table_name
			LEFT JOIN (
				SELECT column_name, table_name FROM information_schema.columns
				WHERE ordinal_position=1 and table_schema IN ('SCHEMA_NAME', 'am')
			) i ON st.id = i.table_name
			WHERE
				ct.typevalue = 'sys_table_context' AND
				(c.column_name IS NULL OR c.column_name != 'link_the_geom') AND
				st.project_template->'template' @> to_jsonb(ARRAY[project_type_id]) AND
				st.project_template IS NOT NULL
			ORDER BY group_order desc, st.orderby desc
		) d), '[]'::json) INTO v_final;
	END IF;

	v_result_info := v_final;

	RETURN ('{"status":"Accepted", "version":"'||v_version||'"'||
   		',"body":{"form":{}'||
       		',"data":{"layers":'||v_result_info||' }}'||
        		'}')::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2600

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getsearch(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getsearch(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_getsearch($${"client":{"device": 5, "lang": "es_ES", "cur_user": "bgeo", "infoType": 1}, "form":{}, "feature":{}, "data":{"parameters":{"searchText":"calle"}}, "pageInfo":{}}}$$);
*/

DECLARE
v_version text;
v_addschema text;
v_filter text := '';
v_tiled boolean;
v_filter_poly text;
v_epsg int;
v_device int;

rec_tab record;
v_parameter text;
v_tab_params json;
v_label text;
v_fields json;
v_result json;
v_result_array json[];
v_sql text;
v_sys_query_text text;
v_sys_query_text_add text;
v_filter_split text;
v_record record;
v_geom text;

v_limit integer;

BEGIN

	SET search_path = "SCHEMA_NAME", public;
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_addschema = (p_data ->>'data')::json->>'addSchema';
	v_filter = ((p_data ->>'data')::json->>'parameters')::json->>'searchText';
	v_tiled = ((p_data ->>'client')::json->>'tiled')::boolean;
	v_device = ((p_data ->>'client')::json->>'device')::int;
	v_filter_poly = ((p_data ->>'data')::json->>'filterFields')::json->>'searchPoly';

	IF lower(v_addschema) = 'none' OR v_addschema = '' OR lower(v_addschema) ='null' THEN
		v_addschema = null;
	END IF;

	EXECUTE 'SELECT epsg FROM sys_version LIMIT 1' INTO v_epsg;

	IF (SELECT count(*) FROM selector_expl WHERE cur_user = current_user) = 0 THEN
		INSERT INTO selector_expl VALUES(0,current_user);
	END IF;

	v_filter = replace(coalesce(v_filter, ''), '''', '''''');

	FOR rec_tab IN SELECT * FROM v_config_form_tabs WHERE formname='search' ORDER BY orderby
	LOOP
		FOR v_parameter, v_tab_params, v_label IN
			SELECT parameter, value, label
			FROM config_param_system
			WHERE parameter ILIKE concat('basic_search_v2_', lower(rec_tab.tabname), '%')
				AND isenabled = TRUE
				AND (v_device = ANY(device) OR device IS NULL)
		LOOP

			v_limit = COALESCE((v_tab_params->>'sys_limit')::int, 10);

			IF v_parameter = 'basic_search_v2_tab_psector' AND v_tiled IS TRUE THEN
				CONTINUE;
			END IF;

			IF v_parameter = 'basic_search_v2_tab_address' THEN
				v_sql = concat('SELECT count(*) as count FROM ', quote_ident(v_tab_params->>'sys_tablename_aux'));
				EXECUTE concat('SELECT split_part(', quote_literal(v_filter), ', '', '', 1)') INTO v_filter_split;
				v_sql = concat(v_sql, ' WHERE name::text ILIKE ''%', v_filter_split::text, '%''');
				EXECUTE v_sql INTO v_record;

				IF v_record.count = 1 THEN
					v_sys_query_text_add = v_tab_params->>'sys_query_text_add';
					v_sql = concat(v_sys_query_text_add, '''%', v_filter::text, '%'' order by "displayName"');
					v_sql = concat('SELECT array_to_json(array_agg(a)) FROM (', v_sql::text, ' LIMIT ', v_limit, ')a');
					EXECUTE v_sql INTO v_fields;

					v_result = gw_fct_json_object_set_key (v_result, 'section', v_parameter);
					v_result = gw_fct_json_object_set_key (v_result, 'alias', v_label);
					v_result = gw_fct_json_object_set_key (v_result, 'execFunc', v_tab_params->>'sys_fct');
					v_result = gw_fct_json_object_set_key (v_result, 'tableName', v_tab_params->>'sys_tablename_aux');
					v_result = gw_fct_json_object_set_key (v_result, 'values', v_fields);
					v_result = gw_fct_json_object_set_key (v_result, 'searchAdd', True);
					v_result_array := array_append(v_result_array, v_result);
					CONTINUE;
				END IF;
			END IF;

			IF v_tab_params->>'sys_search_name' IS NOT NULL THEN
				v_sys_query_text = concat(
					'SELECT ', quote_literal(v_tab_params->>'sys_pk'), ' as key, ',
					(v_tab_params->>'sys_pk')::text, ' as value, ',
					(v_tab_params->>'sys_display_name')::text, ' as "displayName" FROM ',
					(v_tab_params->>'sys_tablename')::text, ' WHERE ',
					(v_tab_params->>'sys_search_name')::text, ' ILIKE ''%', v_filter::text, '%'' '
				);
			ELSE
				v_sys_query_text = concat(
					'SELECT ', quote_literal(v_tab_params->>'sys_pk'), ' as key, ',
					(v_tab_params->>'sys_pk')::text, ' as value, ',
					(v_tab_params->>'sys_display_name')::text, ' as "displayName" FROM ',
					(v_tab_params->>'sys_tablename')::text, ' WHERE ',
					(v_tab_params->>'sys_display_name')::text, ' ILIKE ''%', v_filter::text, '%'' '
				);
			END IF;

			IF v_tab_params->>'sys_filter' != '' THEN
				v_sys_query_text := concat(v_sys_query_text, ' AND (', (v_tab_params->>'sys_filter')::text, ')');
			END IF;

			IF v_filter_poly IS NOT NULL THEN
				v_geom := v_tab_params->>'sys_geom';
				IF v_geom IS NOT NULL AND v_geom != '' THEN
					v_sys_query_text := concat(v_sys_query_text, ' AND ST_Within(', v_geom::text, ', ST_GeomFromText(''', v_filter_poly::text, ''', ', v_epsg, '))');
				END IF;
			END IF;

			v_sys_query_text := concat(
				v_sys_query_text,
				' ORDER BY (CASE WHEN ',
				(v_tab_params->>'sys_pk')::text, '::text = ''', v_filter::text, ''' THEN 0 ',
				'WHEN ', (v_tab_params->>'sys_display_name')::text, ' ~* ''\m', v_filter::text, '\M'' THEN 1 ',
				'WHEN ', (v_tab_params->>'sys_display_name')::text, ' ILIKE ''', v_filter::text, '%'' THEN 2 ',
				'ELSE 3 END), ',
				'regexp_replace(', (v_tab_params->>'sys_display_name')::text, ',''[^0-9a-zA-Z]+'','''',''g'')'
			);

			v_sql = concat('SELECT array_to_json(array_agg(a)) FROM (', v_sys_query_text::text, ' LIMIT ', v_limit, ')a ;');
			EXECUTE v_sql INTO v_fields;

			v_result = gw_fct_json_object_set_key (v_result, 'section', v_parameter);
			v_result = gw_fct_json_object_set_key (v_result, 'alias', v_label);
			v_result = gw_fct_json_object_set_key (v_result, 'execFunc', v_tab_params->>'sys_fct');
			v_result = gw_fct_json_object_set_key (v_result, 'tableName', (COALESCE(v_tab_params->>'sys_fct_tablename', v_tab_params->>'sys_tablename'))::text);
			v_result = gw_fct_json_object_set_key (v_result, 'values', v_fields);
			v_result_array := array_append(v_result_array, v_result);
		END LOOP;
	END LOOP;

	RETURN (concat('{"status":"Accepted", "version":"', v_version, '", "body":{"data":{"searchResults":', to_json(v_result_array), '}}}'))::json;

EXCEPTION WHEN OTHERS THEN
	RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE)::json;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

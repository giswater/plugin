/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 3218


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getreport(p_data json)
  RETURNS json AS
$BODY$

/*DESCRIPTION:

This function has two logics with SQL:

1) SQL WITHOUT GROUP BY EXPRESSION

2) SQL WITH GROUP BY EXPRESSION. For use with this strategy:
	- 'queryAdd' to concatenate after filter fields on initial query
	- 'showOnTableModel' To show filterfields on tablemodel (as that fields are missed)

EXAMPLE:

SELECT SCHEMA_NAME.gw_fct_getreport($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"data":{"filterText":null, "listId":"1"}}$$);

SELECT SCHEMA_NAME.gw_fct_getreport($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "filter":[{"filterName": "cat_period_id", "filterValue": "6"}, {"filterName": "dma_id", "filterValue": "3"}], "listId":"103"}}$$);

SELECT SCHEMA_NAME.gw_fct_getreport($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "filter":[{"filterName": "code", "filterValue": "6"}, {"filterName": "dma_id", "filterValue": "5"}], "listId":"102"}}$$);

SELECT SCHEMA_NAME.gw_fct_getreport($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "filter":[{"filterName": "init", "filterValue": null}], "listId":"902"}}$$);

SELECT SCHEMA_NAME.gw_fct_getreport($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "filter":[{"filterName": "Exploitation", "filterValue": "expl_01", "filterSign": "=", "filterWithMissedColumn": null}, {"filterName": "Dma", "filterValue": "", "filterSign": "=", "filterWithMissedColumn": null}, {"filterName": "Period", "filterValue": "", "filterSign": "=", "filterWithMissedColumn": null}], "listId":"102"}}$$);

*/

DECLARE

v_list_id integer;
v_fields json;
v_filterparam json;
v_filterdvquery json;
v_comboid json;
v_comboidval json;
v_filterlist json[];
v_filter json;
rec_filter text;
v_filterinput text[];
v_filtername text;
v_filtervalue text;
v_filtersign text;
v_record record;
v_querytext text;
v_showontablemodel text;
v_default text;

v_version text;
v_error_context text;
v_filterdefault text;
v_queryadd text;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get input parameter
	v_list_id := json_extract_path_text(p_data,'data','listId');
	v_filter := json_extract_path_text(p_data,'data','filter');
	v_queryadd := json_extract_path_text(p_data,'data','queryAdd');

	SELECT array_agg(a) AS list FROM json_array_elements_text(v_filter) a INTO v_filterinput;

	--filter widgets
	IF (SELECT filterparam FROM v_config_report WHERE id = v_list_id) IS NOT NULL THEN

		FOR i IN 0..(SELECT jsonb_array_length(filterparam::jsonb)-1 FROM v_config_report WHERE id = v_list_id) LOOP

			SELECT filterparam::jsonb->>i into v_filterparam FROM v_config_report WHERE id = v_list_id;

				EXECUTE 'SELECT json_agg(t.id) FROM ('||json_extract_path_text(v_filterparam,'dvquerytext')||') t'
				INTO v_comboid;

				EXECUTE 'SELECT json_agg(t.idval) FROM ('||json_extract_path_text(v_filterparam,'dvquerytext')||') t'
				INTO v_comboidval;

				v_filterdvquery=(v_filterparam::jsonb || json_build_object(
				'comboIds', v_comboid,
				'comboNames', v_comboidval,
				'widgetname',json_extract_path_text(v_filterparam,'columnname'),
				'filterSign', json_extract_path_text(v_filterparam,'filterSign'),
				'showOnTableModel', json_extract_path_text(v_filterparam,'showOnTableModel'))::jsonb);

				v_filterlist = array_append(v_filterlist,v_filterdvquery);
			i=i+1;
		END LOOP;
	END IF;

	--execute query
	SELECT * INTO v_record FROM v_config_report WHERE id = v_list_id;

	v_querytext = v_record.query_text;
	IF v_filterinput IS NOT NULL THEN  -- when filter has not values form client

		FOREACH rec_filter IN ARRAY v_filterinput LOOP

			v_filtername = concat('"',json_extract_path_text(rec_filter::json,'filterName'),'"');
			v_filtersign = json_extract_path_text(rec_filter::json,'filterSign');
			v_filtervalue = json_extract_path_text(rec_filter::json,'filterValue');

			IF v_filtersign  IS NULL THEN
				v_filtersign='=';
			END IF;

			IF v_filtervalue = 'None' THEN
				v_filtervalue = '';
			END IF;

			IF v_filtername != '' AND v_filtervalue != '' THEN

				IF v_queryadd IS NOT NULL THEN

					v_querytext = concat(v_querytext,' AND ',v_filtername, v_filtersign, quote_literal(v_filtervalue));
				ELSE
					v_querytext = concat('SELECT * FROM (',v_querytext,') a WHERE ',v_filtername, v_filtersign, quote_literal(v_filtervalue));
				END IF;
			END IF;
		END LOOP;

		IF v_queryadd IS NOT NULL THEN
			v_querytext = concat(v_querytext,' ',v_queryadd, ' ');
		END IF;

	ELSIF (SELECT filterparam FROM v_config_report WHERE id = v_list_id) IS NOT NULL THEN  -- when filter has values form client

		-- Look for default values in each widget
		FOR i IN 0..(SELECT jsonb_array_length(filterparam::jsonb)-1 FROM v_config_report WHERE id = v_list_id) LOOP

			SELECT filterparam::jsonb->>i into v_filterparam FROM v_config_report WHERE id = v_list_id;

			v_filtername = concat('"',json_extract_path_text(v_filterparam::json,'columnname'),'"');
			v_filtersign = json_extract_path_text(v_filterparam::json,'filterSign');
			v_filterdefault  = (COALESCE(json_extract_path_text(v_filterparam::json,'filterDefault'), ''));

			IF v_filtername != '""' AND v_filterdefault != '' THEN

				IF v_queryadd IS NOT NULL THEN
					v_querytext = concat(v_querytext,' AND ',v_filtername, v_filtersign, quote_literal(v_filterdefault));
				ELSE
					v_querytext = concat('SELECT * FROM (',v_querytext,') a WHERE ',v_filtername, v_filtersign, quote_literal(v_filtervalue));
				END IF;
			END IF;
			i=i+1;
		END LOOP;

		IF v_queryadd IS NOT NULL THEN
			v_querytext = concat(v_querytext,' ',v_queryadd, ' ');
		END IF;

	END IF;


	-- order by
	v_default = (SELECT addparam->>'orderBy' FROM v_config_report WHERE id = v_list_id);

	IF v_default IS NOT NULL THEN
		v_querytext = concat (v_querytext ,' ORDER BY ', v_default);
		v_default = (SELECT addparam->>'orderType' FROM v_config_report WHERE id = v_list_id);
		v_querytext = concat (v_querytext ,' ', v_default);
	END IF;

	IF v_queryadd IS NOT NULL THEN
		EXECUTE 'SELECT json_agg(t) FROM (SELECT * FROM ('||v_querytext||') a) t'
		INTO v_fields ;
	ELSE
		EXECUTE 'SELECT json_agg(t) FROM ('||v_querytext||') t'
		INTO v_fields ;
	END IF;

	v_fields = json_build_object('widgettype', 'list', 'value',v_fields);

	v_fields:=json_build_object('id',v_record.id, 'alias',v_record.alias, 'descript',v_record.descript, 'sys_role',v_record.sys_role, 'fields', v_fields||v_filterlist);

	v_fields := COALESCE(v_fields, '{}');

	RETURN ('{"status":"Accepted", "version":"'||v_version||'"'||
	      ',"body":{"message":{"level":1, "text":"Process done successfully"}'||
		      ',"form":{}'||
		      ',"feature":{}'||
		      ',"data":' || v_fields ||'}'||
	       '}')::json;

	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
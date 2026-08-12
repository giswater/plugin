/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2592

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getlist(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getlist(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE:

TOC
----------
SELECT SCHEMA_NAME.gw_fct_getlist($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},
"feature":{},
"data":{"tableName":"ve_arc_pipe", "canvasExtend":{"x1coord":12131313,"y1coord":12131313,"x2coord":12131313,"y2coord":12131313},
        "pageInfo":{"orderBy":"arc_id", "orderType":"DESC", "page":1}}}$$)

VISIT
----------
-- Visit -> visites
SELECT SCHEMA_NAME.gw_fct_getlist($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},
"feature":{},
"data":{"tableName":"om_visit_x_arc", "filterFields":{"arc_id":{"value":2001, "filterSign":"="}},
    "pageInfo":{"orderBy":"visit_id", "orderType":"DESC", "limit":10}}}$$)


-- Visit -> events
SELECT SCHEMA_NAME.gw_fct_getlist($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{},
"data":{"tableName":"v_ui_om_event", "filterFields":{"visit_id":{"value":232, "filterSign":"="}},
    "pageInfo":{"orderBy":"tstamp", "orderType":"DESC", "page":3, "limit":10}}}$$)

FEATURE FORMS
-------------
-- Arc -> elements
SELECT SCHEMA_NAME.gw_fct_getlist($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{},
"data":{"tableName":"v_ui_element_x_arc", "filterFields":{"arc_id":{"value":2001, "filterSign":"="}},
    "pageInfo":{"orderBy":"element_id", "orderType":"DESC", "page":3}}}$$)
*/

DECLARE

v_version text;
v_filter_values  json;
v_schemaname text;
v_result_list json;
v_query_result text;
v_id  varchar;
v_device integer;
v_fields varchar[];
v_field varchar;
v_length integer;
v_value text;
v_orderby varchar;
v_ordertype varchar;
v_idname varchar;
v_limit integer;
v_page integer;
v_lastpage integer;
v_text text[];
v_json_field json;
text text;
i integer=1;
v_tablename text;
v_x1 float;
v_y1 float;
v_x2 float;
v_y2 float;
v_the_geom text;
v_canvasextend json;
v_srid integer;
v_pageinfo json;
v_listclass text;
v_sign text;
v_type text;
v_logical text;
v_data json;
v_default json;
v_listtype text;
v_audit_result text;
v_status text;
v_level integer;
v_message text;
v_pkey json;
v_table_params json;
v_headers_list json[];
v_headers_params json[];
v_headers_json json;
v_columnname text;
v_addparam json;
v_table_headers text[];
BEGIN

	-- Set search path to local schema
    SET search_path = "SCHEMA_NAME", public;
    v_schemaname := 'SCHEMA_NAME';

	--  get api version
    SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- fix diferent ways to say null on client
	p_data = REPLACE (p_data::text, '"NULL"', 'null');
	p_data = REPLACE (p_data::text, '"null"', 'null');
	p_data = REPLACE (p_data::text, '""', 'null');
    p_data = REPLACE (p_data::text, '''''', 'null');

    SELECT epsg INTO v_srid FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Get input parameters:
	v_device := (p_data ->> 'client')::json->> 'device';
	v_tablename := (p_data ->> 'data')::json->> 'tableName';
	v_canvasextend := (p_data ->> 'data')::json->> 'canvasExtend';
	v_orderby := ((p_data ->> 'data')::json->> 'pageInfo')::json->>'orderBy';
	v_filter_values := (p_data ->> 'data')::json->> 'filterFields';
	v_ordertype := ((p_data ->> 'data')::json->> 'pageInfo')::json->>'orderType';
	v_page := ((p_data ->> 'data')::json->> 'pageInfo')::json->>'page';
	v_limit := ((p_data ->> 'data')::json->> 'pageInfo')::json->>'limit';

	-- control nulls
	IF v_tablename IS NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3156", "function":"2592","parameters":{"table_name":"tableName"}, "is_process":true}}$$);'INTO v_audit_result;
	else
		execute 'SELECT addparam FROM config_form_list where listname = $1 and device = $2' into v_table_params using v_tablename, v_device;
	END IF;

	RAISE NOTICE 'gw_fct_getlist - Init Values: v_tablename %  v_filter_values  %', v_tablename, v_filter_values;


	-- setting value default for filter fields
	IF v_filter_values::text IS NULL OR v_filter_values::text = '{}' THEN

		v_data = '{"client":{"device":4, "infoType":1, "lang":"ES"},"data":{"formName": "'||v_tablename||'"}}';

		SELECT gw_fct_getfiltervaluesvdef(v_data) INTO v_filter_values;

		RAISE NOTICE 'gw_fct_getlist - Init Values setted by default %', v_filter_values;

	END IF;

--  Creating the list fields
----------------------------
	-- control not existing table
	IF v_tablename IN (SELECT table_name FROM information_schema.tables WHERE table_schema = v_schemaname) THEN

		-- Get idname column
		EXECUTE 'SELECT a.attname FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) WHERE  i.indrelid = $1::regclass AND i.indisprimary'
			INTO v_idname
			USING v_tablename;

		-- For views it suposse pk is the first column
		IF v_idname ISNULL THEN
			EXECUTE 'SELECT a.attname FROM pg_attribute a   JOIN pg_class t on a.attrelid = t.oid  JOIN pg_namespace s on t.relnamespace = s.oid WHERE a.attnum > 0   AND NOT a.attisdropped
				AND t.relname = $1
				AND s.nspname = $2
				ORDER BY a.attnum LIMIT 1'
					INTO v_idname
					USING v_tablename, v_schemaname;
		END IF;

		-- Getting geometry column
		EXECUTE 'SELECT attname FROM pg_attribute a
		JOIN pg_class t on a.attrelid = t.oid
		JOIN pg_namespace s on t.relnamespace = s.oid
		WHERE a.attnum > 0
		AND NOT a.attisdropped
		AND t.relname = $1
		AND s.nspname = $2
		AND left (pg_catalog.format_type(a.atttypid, a.atttypmod), 8)=''geometry''
		ORDER BY a.attnum'
			USING v_tablename, v_schemaname
			INTO v_the_geom;

		--  get querytext
		EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 AND device = $2'
			INTO v_query_result, v_default, v_listtype
			USING v_tablename, v_device;

		-- if v_device is not configured on config_form_list table
		IF v_query_result IS NULL THEN
			EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 LIMIT 1'
				INTO v_query_result, v_default, v_listtype
				USING v_tablename;
		END IF;

		-- if v_tablename is not configured on config_form_list table
		IF v_query_result IS NULL THEN
			v_query_result = 'SELECT * FROM '||v_tablename||' WHERE '||v_idname||' IS NOT NULL ';
		END IF;

	ELSE
		--  get querytext
		EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 AND device = $2'
			INTO v_query_result, v_default, v_listtype
			USING v_tablename, v_device;

		-- if v_device is not configured on config_form_list table
		IF v_query_result IS NULL THEN
			EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 LIMIT 1'
				INTO v_query_result, v_default, v_listtype
				USING v_tablename;
		END IF;
	END IF;

	--  add filters (fields)
	SELECT array_agg(row_to_json(a)) into v_text from json_each(v_filter_values) a;

	IF v_text IS NOT NULL THEN
		FOREACH text IN ARRAY v_text
		LOOP
			-- Get field and value from json
			SELECT v_text [i] into v_json_field;

			v_fields:= string_to_array((SELECT (v_json_field ->> 'key')), ', ') ;
			v_value:= (SELECT (v_json_field ->> 'value')) ;
			v_length := array_length(v_fields, 1);

			if (v_length = 1) then
				v_field:= v_fields [1];
			end if;

			-- Getting the type of the filter
			IF (SELECT v_value WHERE v_value ILIKE '%'||'filterType'||'%') IS NOT NULL then
				v_type = v_value::json->>'filterType';
			else
				v_type = 'text';
			END IF;

			-- Getting the sign of the filter
			IF (SELECT v_value WHERE v_value ILIKE '%'||'filterSign'||'%') IS NOT NULL then
			    -- Getting the type of the filter
				v_sign = v_value::json->>'filterSign';
				v_value = v_value::json->>'value';
				IF upper(v_sign) IN ('LIKE', 'ILIKE') THEN
					v_value = '%'||v_value||'%';
				END IF;
			ELSE
				IF v_listtype = 'attributeTable' THEN
					v_sign = 'ILIKE';
				ELSIF v_sign IS NULL THEN
					v_sign = '=';
				END IF;
			END IF;

			i=i+1;

			if v_length = 1 then

				IF v_value IS NOT NULL AND v_field != 'limit' then

				 	IF upper(v_type) = 'BETWEEN' then
				 		v_query_result := v_query_result || ' AND "'||v_field||'"::'||v_type||' '||v_sign||' '||v_value||'::'||v_type||' ';
				 	else
				 		v_query_result := v_query_result || ' AND "'||v_field||'"::'||v_type||' '||v_sign||' '''||v_value||'''::'||v_type||' ';

				 	end if;
				END IF;
			else
				v_query_result := v_query_result || ' AND (';
				FOR i IN array_lower(v_fields, 1)..array_upper(v_fields, 1) loop
					v_logical := 'OR';
			        if i = 1 then
			        	v_logical := '';
			        end if;
			       	v_query_result := v_query_result || ' '||v_logical||' "'||v_fields[i]||'"::'||v_type||' '||v_sign||' '''||v_value||'''::'||v_type||' ';
			    END LOOP;
				v_query_result := v_query_result || ')';
			end if;
			-- creating the query_text

		END LOOP;
	END IF;

	-- add extend filter
	IF v_the_geom IS NOT NULL AND v_canvasextend IS NOT NULL THEN

		-- getting coordinates values
		v_x1 = v_canvasextend->>'x1';
		v_y1 = v_canvasextend->>'y1';
		v_x2 = v_canvasextend->>'x2';
		v_y2 = v_canvasextend->>'y2';

		-- adding on the query text the extend filter
		v_query_result := v_query_result || ' AND ST_dwithin ( '|| v_tablename || '.' || v_the_geom || ',' ||
		'ST_MakePolygon(ST_GeomFromText(''LINESTRING ('||v_x1||' '||v_y1||', '||v_x1||' '||v_y2||', '||v_x2||' '||v_y2||', '||v_x2||' '||v_y1||', '||v_x1||' '||v_y1||')'','||v_srid||')),1)';
	END IF;

	-- add orderby

	IF v_orderby IS NULL THEN
		v_orderby = v_default->>'orderBy';
		v_ordertype = v_default->>'orderType';
	END IF;


	IF v_orderby IS NOT NULL THEN
		v_query_result := v_query_result || ' ORDER BY '||v_orderby;
	END IF;

	-- adding ordertype
	IF v_ordertype IS NOT NULL THEN
		v_query_result := v_query_result ||' '||v_ordertype;
	END IF;
	-- calculating last page
	IF v_limit IS NULL THEN
		v_limit = 10;
	END IF;

	-- add limit
	IF v_device != 4 AND v_limit != -1 THEN
		-- the list is truncated, so the total amount of rows has to be counted apart
		EXECUTE 'SELECT count(*)/'||v_limit||' FROM (' || v_query_result || ') a'
			INTO v_lastpage;

	    v_query_result := v_query_result || ' LIMIT '|| v_limit;
	END IF;

	-- calculating current page
	IF v_page IS NULL THEN
		v_page=1;
	END IF;

	RAISE NOTICE '--- gw_fct_getlist - Query Result: % ---', v_query_result;

	-- Execute query result
	EXECUTE 'SELECT array_to_json(array_agg(row_to_json(a))) FROM (' || v_query_result || ') a'
		INTO v_result_list;

	-- the list is not raised because sending the whole result as a notice slows down large lists
	RAISE NOTICE '--- gw_fct_getlist - List rows: % ---', coalesce(json_array_length(v_result_list), 0);

	-- Building headers
	i = 1;
	v_table_headers := array(SELECT json_object_keys(v_result_list->0));
		IF v_table_headers = '{}' THEN
		EXECUTE 'SELECT array_agg(column_name)
			FROM (
				SELECT DISTINCT column_name, ordinal_position
				FROM information_schema.columns
				WHERE table_name = ''' || substring(v_query_result FROM 'FROM\s+([a-zA-Z0-9_\.]+)') || '''
				ORDER BY ordinal_position
			) a' INTO v_table_headers;
	END IF;
	SELECT array_agg(row_to_json(merged_cols)) INTO v_headers_list
		FROM (
		  SELECT COALESCE(cftv.columnname, t.columnname) AS columnname, cftv.addparam, cftv.visible
		  FROM unnest(v_table_headers) AS t(columnname)
		  LEFT JOIN config_form_tableview AS cftv
		  ON t.columnname = cftv.columnname AND cftv.objectname = v_tablename
		  ORDER BY cftv.columnindex ASC
		) AS merged_cols
		where merged_cols.visible is not false ;
	IF v_headers_list IS NOT NULL THEN
		FOREACH text IN ARRAY v_headers_list
		loop
			SELECT v_headers_list[i] into v_json_field;
			v_columnname:= (SELECT (v_json_field ->> 'columnname'));
			v_addparam:= (SELECT (v_json_field ->> 'addparam'));
			if v_addparam is not null and (select (v_addparam ->> 'header')) is null then
				v_addparam := gw_fct_json_object_set_key(v_addparam, 'header', v_columnname);
			end if;
			v_headers_params := v_headers_params || coalesce(v_addparam, json_build_object('accessorKey', v_columnname, 'header', v_columnname, 'enableColumnActions', false, 'enableColumnFilter', false, 'columnFilterModeOptions', false, 'size', 0));

			i = i + 1;
		end loop;
	end if;
	v_headers_json = array_to_json (v_headers_params);

	-- building pageinfo
	-- when the whole list is returned the rows are already there, no need to count them on the database
	IF v_lastpage IS NULL THEN
		v_lastpage := coalesce(json_array_length(v_result_list), 0) / v_limit;
	END IF;

	v_pageinfo := json_build_object('orderBy',v_orderby, 'orderType', v_ordertype, 'currentPage', v_page, 'lastPage', v_lastpage);

	EXECUTE 'SELECT listclass FROM config_form_list WHERE listname = $1 LIMIT 1'
		INTO v_listclass
		USING v_tablename;

	-- get primary key
	EXECUTE 'SELECT addparam FROM sys_table WHERE id = $1' INTO v_pkey USING v_tablename;

	-- Control NULL's
	v_version := COALESCE(v_version, '');
	v_tablename := COALESCE(v_tablename, '');
	v_result_list := COALESCE(v_result_list, '[]');
	v_pageinfo := COALESCE(v_pageinfo, '{}');
	v_pkey := COALESCE(v_pkey, '{}');
	v_table_params := COALESCE(v_table_params, '{}');
	v_headers_json := COALESCE(v_headers_json, '{}');


	IF v_audit_result is null THEN
        v_status = 'Accepted';
        v_level = 3;
        v_message = 'Process done successfully';
    ELSE

        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;

    END IF;

	-- Return
    RETURN jsonb_build_object(
        'status', v_status,
        'message', jsonb_build_object(
            'level', v_level,
            'text', v_message
        ),
        'version', v_version,
        'body', jsonb_build_object(
            'form', jsonb_build_object(
                'table', v_table_params,
                'headers', v_headers_json
            ),
            'feature', '{}'::jsonb,
            'data', jsonb_build_object(
                'type', v_listclass,
                'fields', v_result_list,
                'addparam', v_pkey,
                'pageInfo', v_pageinfo
            )
        )
    )::json;
	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

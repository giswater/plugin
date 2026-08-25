/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2562

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_api_get_formfields(character varying, character varying, character varying,
character varying, character varying, character varying, character varying, character varying, character varying, integer);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_api_get_formfields(character varying, character varying, character varying,
character varying, character varying, character varying, character varying, character varying, character varying, integer, json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getformfields(
	p_formname character varying,
	p_formtype character varying,
	p_tabname character varying,
	p_tablename character varying,
	p_idname character varying,
	p_id character varying,
	p_columntype character varying,
	p_tgop character varying,
	p_filterfield character varying,
	p_device integer,
	p_values_array json)
    RETURNS text[]

AS $BODY$
/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_getformfields( 've_arc_pipe','form_feature','tab_data','ve_arc_pipe','arc_id',	'2088','character varying(16)',	'UPDATE',	1,	'4',	'{}' )
SELECT SCHEMA_NAME.gw_fct_getformfields('visit_arc_insp', 'form_visit', 'tab_data', NULL,	 NULL, 		NULL, 	NULL, 			'INSERT', 	null, 	3,	null)
SELECT "SCHEMA_NAME".gw_fct_getformfields('go2epa', 'form_generic', 'tab_data', null, null, null, null, null, null,null, '{}')
SELECT "SCHEMA_NAME".gw_fct_getformfields('ve_arc_conduit', 'form_feature', 'tab_data', 've_arc_conduit', 'arc_id', '2001', NULL, 'SELECT', null, 4, NULL)
SELECT "SCHEMA_NAME".gw_fct_getformfields('ve_arc_pipe', 'form_feature', NULL, NULL, NULL, NULL, NULL, 'INSERT', null, 4, '{}')
SELECT "SCHEMA_NAME".gw_fct_getformfields( 'print', 'form_generic', 'tab_data', null, null, null, null, 'SELECT', null, 3);

PERFORM gw_fct_debug(concat('{"data":{"msg":"----> INPUT FOR gw_fct_getformfields: ", "variables":"',v_debug,'"}}')::json);
PERFORM gw_fct_debug(concat('{"data":{"msg":"<---- OUTPUT FOR gw_fct_getformfields: ", "variables":"',v_debug,'"}}')::json);
UPDATE config_param_user SET value =  'true' WHERE parameter = 'utils_debug_mode' and cur_user = current_user;
*/

DECLARE
fields json;
fields_array json[];
aux_json json;
combo_json json;
schemas_array name[];
array_index integer DEFAULT 0;
field_value character varying;
v_version text;
v_selected_id text;
query_text text;
v_vdefault text;
v_id int8;
v_project_type varchar;
v_return json;
v_combo_id json;
v_orderby text;
v_image json;
v_array text[];
v_widgetvalue json;
v_input json;
v_editability text;
v_label text;
v_clause text;
v_device text;
v_debug boolean;
v_debug_var text;
v_errcontext text;
v_querystring text;
v_debug_vars json;
v_debug_sql json;
v_msgerr json;
v_featuretype text;
v_currency text;
v_filter_widgets text = '';
v_user_roles TEXT[];
v_min_role TEXT;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- Get schema name
	schemas_array := current_schemas(FALSE);

	-- get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get project type
	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT value::boolean INTO v_debug FROM config_param_user WHERE parameter='utils_debug_mode';

	-- get currency symbol
	SELECT value::json->'symbol' INTO v_currency FROM v_config_param_system WHERE parameter ='admin_currency';
	v_currency=replace(v_currency,'"','');

	IF v_debug = TRUE THEN
		v_debug_var = (SELECT jsonb_build_object('formname',  p_formname,'formtype',   p_formtype, 'tabname', p_tabname,'tablename', p_tablename, 'idname', p_idname,
		'id',p_id, 'columntype', p_columntype, 'tgop', p_tgop, 'filterfield', p_filterfield, 'device', p_device, 'values_array', p_values_array	));

		PERFORM gw_fct_debug(concat('{"data":{"msg":"----> INPUT FOR gw_fct_getformfields: ", "variables":',v_debug_var,'}}')::json);
	END IF;

	-- setting tabname
	IF p_tabname IS NULL THEN
		p_tabname = 'tabname';
	END IF;

	-- setting device
	IF p_device IN (1,2,3) THEN
		v_device = ' b.camelstyle AS type, columnname AS name, datatype AS "dataType", a.camelstyle AS "widgetAction", a.camelstyle as "updateAction", a.camelstyle as "changeAction",
		     (CASE WHEN layoutname=''0'' OR layoutname =''lyt_top_1'' THEN ''header'' WHEN layoutname=''9'' OR layoutname =''lyt_bot_1'' OR layoutname =''lyt_bot_2'' 
		     THEN ''footer'' ELSE ''body'' END) AS "position",
		     (CASE WHEN iseditable=true THEN false ELSE true END)  AS disabled,';
	ELSE
		v_device = '';
	END IF;


	IF p_filterfield IS NOT NULL AND p_filterfield!='' THEN
		v_filter_widgets = ' AND columnname NOT IN('||(p_filterfield)||') ';

	END IF;

	-- get user variable to show label as column id or not
	IF (SELECT value::boolean FROM config_param_user WHERE parameter = 'utils_formlabel_show_columname' AND cur_user =  current_user) THEN
		v_label = 'columnname AS label';
	ELSE
		v_label = 'label';
	END IF;

	v_orderby = 'layoutname, layoutorder';
	IF p_device = 5 THEN
		v_orderby = 'web_layoutorder';
	END IF;

	-- starting process - get fields
	IF p_formname ILIKE 've_inp%' THEN
	    v_querystring = concat('SELECT array_agg(row_to_json(a)) FROM (

			WITH typevalue AS (SELECT * FROM config_typevalue)

			SELECT ',v_label,', columnname, columnname as column_id, concat(tabname,''_'',columnname) AS widgetname, widgettype,
			widgetfunction, widgetfunction as  widgetAction, widgetfunction as updateAction, widgetfunction as changeAction,
			',v_device,' hidden, datatype , tooltip, placeholder, iseditable, row_number()over(ORDER BY ', v_orderby ,') AS orderby, tabname,
			layoutname, layoutorder, dv_parent_id AS "parentId", isparent, ismandatory, linkedobject, dv_querytext AS "queryText", dv_querytext_filterc AS "queryTextFilter", isautoupdate,

			dv_orderby_id AS "orderById", dv_isnullvalue AS "isNullValue", stylesheet, widgetcontrols, isfilter, web_layoutorder
			FROM v_config_form_fields
			LEFT JOIN config_typevalue a ON a.id = widgetfunction::json->>''functionName'' AND a.typevalue = ''widgetfunction_typevalue''
			LEFT JOIN config_typevalue b ON b.id = widgettype AND b.typevalue = ''widgettype_typevalue''
			WHERE (formname = ',quote_nullable(p_formname),') AND formtype= ',quote_nullable(p_formtype),' ',v_clause,' ',v_filter_widgets,' ORDER BY orderby) a');

		v_debug_vars := json_build_object('v_label', v_label, 'p_tabname', p_tabname, 'v_device', v_device, 'p_formname', p_formname, 'p_formtype', p_formtype, 'v_clause', v_clause);
		v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 10);
		SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
		EXECUTE v_querystring INTO fields_array;

	ELSIF p_formname ILIKE 've%' or p_formname ILIKE 'v_edit%' THEN

		if replace(p_idname,'_id','') in ('arc', 'node', 'connec', 'gully', 'element') then
			v_querystring = concat('SELECT array_agg(row_to_json(a)) FROM (

			WITH typevalue AS (SELECT * FROM config_typevalue)

			SELECT ',v_label,', columnname, columnname as column_id, concat(tabname,''_'',columnname) AS widgetname, widgettype,
			widgetfunction, widgetfunction as  widgetAction, widgetfunction as updateAction, widgetfunction as changeAction,
			',v_device,' hidden, datatype , tooltip, placeholder, iseditable, row_number()over(ORDER BY ', v_orderby ,') AS orderby, tabname,
			layoutname, layoutorder, dv_parent_id AS "parentId", isparent, ismandatory, linkedobject, dv_querytext AS "queryText", dv_querytext_filterc AS "queryTextFilter", isautoupdate,
			dv_orderby_id AS "orderById", dv_isnullvalue AS "isNullValue", stylesheet, widgetcontrols, isfilter, web_layoutorder
			FROM v_config_form_fields
			LEFT JOIN config_typevalue a ON a.id = widgetfunction::json->>''functionName'' AND a.typevalue = ''widgetfunction_typevalue''
			LEFT JOIN config_typevalue b ON b.id = widgettype AND b.typevalue = ''widgettype_typevalue''
			WHERE (formname = ',quote_nullable(p_formname),' OR formname = ''',replace(p_idname, '_id', ''),''') AND formtype= ',quote_nullable(p_formtype),' ',v_clause,' ',v_filter_widgets,' ORDER BY orderby) a');

		else
			v_querystring = concat('SELECT array_agg(row_to_json(a)) FROM (

			WITH typevalue AS (SELECT * FROM config_typevalue)

			SELECT ',v_label,', columnname, columnname as column_id, concat(tabname,''_'',columnname) AS widgetname, widgettype,
			widgetfunction, widgetfunction as  widgetAction, widgetfunction as updateAction, widgetfunction as changeAction,
			',v_device,' hidden, datatype , tooltip, placeholder, iseditable, row_number()over(ORDER BY ', v_orderby ,') AS orderby, tabname,
			layoutname, layoutorder, dv_parent_id AS "parentId", isparent, ismandatory, linkedobject, dv_querytext AS "queryText", dv_querytext_filterc AS "queryTextFilter", isautoupdate,
			dv_orderby_id AS "orderById", dv_isnullvalue AS "isNullValue", stylesheet, widgetcontrols, isfilter, web_layoutorder
			FROM v_config_form_fields
			LEFT JOIN config_typevalue a ON a.id = widgetfunction::json->>''functionName'' AND a.typevalue = ''widgetfunction_typevalue''
			LEFT JOIN config_typevalue b ON b.id = widgettype AND b.typevalue = ''widgettype_typevalue''
			WHERE formname = ',quote_nullable(p_formname),' AND formtype= ',quote_nullable(p_formtype),' ',v_clause,' ',v_filter_widgets,' ORDER BY orderby) a');

		end if;

		v_debug_vars := json_build_object('v_label', v_label, 'p_tabname', p_tabname, 'v_device', v_device, 'p_formname', p_formname, 'p_formtype', p_formtype, 'v_clause', v_clause);
		v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 10);
		SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
		EXECUTE v_querystring INTO fields_array;

	ELSIF p_formname='infoplan' THEN

		v_querystring = concat('SELECT array_agg(row_to_json(b)) FROM (
			SELECT (row_number()over(ORDER BY 1)) AS layoutorder, (row_number()over(ORDER BY 1)) AS orderby, * FROM
				(SELECT concat(unit, ''. '', descript) AS label, identif AS columnname, ''label'' AS widgettype,
				concat (',quote_literal(p_tabname),',''_'',identif) AS widgetname, ''string'' AS datatype,
				NULL AS tooltip, NULL AS placeholder, FALSE AS iseditable, orderby as layoutorder, ''lyt_plan_1'' AS layoutname,  NULL AS dv_parent_id,
				NULL AS isparent, NULL as ismandatory, NULL AS button_function, NULL AS dv_querytext,
				NULL AS dv_querytext_filterc, NULL AS linkedobject, NULL AS isautoupdate, 
				concat(measurement, '' '', unit, '' x '', gw_fct_set_currency_config(cost), ''/'', unit, '' = '', gw_fct_set_currency_config(total_cost)) as value, 
				null as stylesheet, null as widgetcontrols, null as hidden
				FROM ' ,p_tablename, ' WHERE ' ,p_idname, ' = ',quote_nullable(p_id),'
			UNION
				SELECT label, columnname, widgettype,
				concat (',quote_literal(p_tabname),',''_'',columnname) AS widgetname, datatype,
				tooltip, placeholder, iseditable, layoutorder+100 as layoutorder, ''lyt_plan_1'' as layoutname,  NULL AS dv_parent_id, NULL AS isparent, ismandatory,
				NULL AS widgetfunction, NULL AS dv_querytext,
				NULL AS dv_querytext_filterc, NULL AS linkedobject, NULL AS isautoupdate, null as value, null as stylesheet, widgetcontrols::text, hidden
				FROM v_config_form_fields WHERE formname  = ''infoplan'' ORDER BY layoutname, layoutorder) a
			ORDER BY 1) b');
		v_debug_vars := json_build_object('p_tabname', p_tabname, 'p_tablename', p_tablename, 'p_idname', p_idname, 'p_id', p_id, 'p_tabname', p_tabname);
		v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 20);
		SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
		EXECUTE v_querystring INTO fields_array;

	ELSE
		v_querystring = concat('SELECT array_agg(row_to_json(a)) FROM (

			WITH typevalue AS (SELECT * FROM config_typevalue)

			SELECT ',v_label,', columnname, columnname as column_id, concat(tabname,''_'',columnname) AS widgetname, widgettype,
			widgetfunction,', v_device,' hidden, datatype , tooltip, placeholder, iseditable, row_number()over(ORDER BY ', v_orderby ,') AS orderby,
			layoutname, layoutorder, dv_parent_id AS "parentId", isparent, ismandatory, linkedobject, dv_querytext AS "queryText", dv_querytext_filterc AS "queryTextFilter", isautoupdate,
			dv_orderby_id AS "orderById", dv_isnullvalue AS "isNullValue", stylesheet, widgetcontrols, web_layoutorder, isfilter, tabname
			FROM v_config_form_fields
			LEFT JOIN config_typevalue a ON a.id = widgetfunction::json->>''functionName'' AND a.typevalue = ''widgetfunction_typevalue''
			LEFT JOIN config_typevalue b ON b.id = widgettype AND b.typevalue = ''widgettype_typevalue''

			WHERE formname IN (',quote_nullable(p_formname),', ''generic'') AND formtype= ',quote_nullable(p_formtype),' ',v_clause,' ',v_filter_widgets,' ORDER BY orderby) a');

		v_debug_vars := json_build_object('v_label', v_label, 'p_tabname', p_tabname, 'v_device', v_device, 'p_formname', p_formname, 'p_formtype', p_formtype, 'v_clause', v_clause);
		v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 10);
		SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
		EXECUTE v_querystring INTO fields_array;

	END IF;

	fields_array := COALESCE(fields_array, '{}');

	-- for image widgets
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'widgettype' = 'image'
	LOOP
      		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'imageVal', COALESCE((aux_json->>'queryText'), ''));
      		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT],
      		'queryText', 'orderById', 'isNullValue', 'parentId', 'queryTextFilter');
	END LOOP;

	-- for buttons
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'widgettype' = 'button'
	LOOP
		IF json_extract_path_text(aux_json,'widgetcontrols','text') IS NOT NULL THEN
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'value', json_extract_path_text(aux_json,'widgetcontrols','text'));
		ELSE
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'value', COALESCE(field_value, ''));
		END IF;
	END LOOP;

	-- combo no childs
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE (a->>'widgettype' = 'combo' OR a->>'widgettype' = 'multiple_checkbox' OR a->>'widgettype' = 'multiple_option')  AND  a->>'parentId' IS NULL
	LOOP
		v_array := null;
		-- Define the order by column
		IF (aux_json->>'orderById')::boolean IS TRUE THEN
			v_orderby='id';
		ELSE
			v_orderby='idval';
		END IF;

		-- Get combo id's
		IF  (aux_json->>'queryText') is not null and (aux_json->>'queryText') != '' then
			v_querystring = concat('SELECT (array_agg(id)) FROM (', (aux_json->>'queryText') ,' ORDER BY ',v_orderby,')a');
			v_debug_vars := json_build_object('aux_json->>''queryText''', (aux_json->>'queryText'), 'v_orderby', v_orderby);
			v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 30);
			SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
			EXECUTE v_querystring INTO v_array;
		END IF;

		-- Enable null values
		IF (aux_json->>'isNullValue')::boolean IS TRUE THEN
			v_array = array_prepend('',v_array);
		END IF;
		combo_json = array_to_json(v_array);
		v_combo_id = combo_json;
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'comboIds', COALESCE(combo_json, '[]'));

		-- Get combo values
		IF  (aux_json->>'queryText') is not null and (aux_json->>'queryText') != '' then
			v_querystring = concat('SELECT (array_agg(idval)) FROM (',(aux_json->>'queryText'),' ORDER BY ',v_orderby,')a');
			v_debug_vars := json_build_object('aux_json->>''queryText''', (aux_json->>'queryText'), 'v_orderby', v_orderby);
			v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 40);
			SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
			EXECUTE v_querystring INTO v_array;
			-- Enable null values
			IF (aux_json->>'isNullValue')::boolean IS TRUE THEN
				v_array = array_prepend('',v_array);
				-- remove key when is used
				fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'isNullValue');
			END IF;
		END IF;

		combo_json = array_to_json(v_array);
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'comboNames', COALESCE(combo_json, '[]'));

		-- for typeahead widgets
		IF (aux_json->>'widgettype' = 'typeahead' OR aux_json->>'widgettype' = 'multiple_option') and (aux_json->>'queryText') IS NOT NULL THEN

			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'getDataAction', 'dataset'::text);
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'selectAction', 'setWidgetValue'::text);
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'threshold', 3);
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'dataset', combo_json);
		ELSE
			--removing the not used keys
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT],
			'queryText', 'orderById', 'parentId', 'queryTextFilter');
		END IF;

	END LOOP;

	-- combo childs
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'widgettype' = 'combo' AND  a->>'parentId' IS NOT NULL
	LOOP


		-- Get selected value from parent
		IF p_tgop ='INSERT' THEN
			IF (aux_json->>'parentId') = 'expl_id' THEN -- specific case for exploitation as parent mapzone
				v_selected_id = (SELECT value FROM config_param_user WHERE parameter = 'edit_exploitation_vdefault' AND cur_user = current_user);

			ELSIF (aux_json->>'parentId') = 'muni_id' THEN -- specific case for exploitation as parent mapzone
				v_selected_id = (SELECT value FROM config_param_user WHERE parameter = 'edit_municipality_vdefault' AND cur_user = current_user);
			ELSIF (aux_json->>'parentId') = 'arc_id' THEN -- specific case for arc_id as parent
				v_selected_id = p_id;
			ELSIF (aux_json->>'parentId') = 'team_id' THEN -- specific case for team_id as parent
				v_selected_id = p_values_array->>'team_id';
				/*IF v_selected_id IS NULL THEN
					v_selected_id = (select team_id from om_visit_lot_x_user where user_id = current_user and endtime is null);
				END IF;*/
			ELSE
				v_querystring = concat('SELECT value::text FROM sys_param_user JOIN config_param_user ON sys_param_user.id=parameter
					WHERE cur_user=current_user AND feature_field_id=',quote_literal(quote_ident(aux_json->>'parentId')));
				v_debug_vars := json_build_object('aux_json->>''parentId''', (aux_json->>'parentId'));
				v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 50);
				SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
				EXECUTE v_querystring INTO v_selected_id;
			END IF;

		ELSIF (p_tgop ='UPDATE' OR p_tgop = 'SELECT') THEN
			v_selected_id := p_values_array->>(aux_json->>'parentId');

		END IF;

		-- Define the order by column
		IF (aux_json->>'orderById')::boolean IS TRUE THEN
			v_orderby='id';
		ELSE
			v_orderby='idval';
		END IF;

		-- Get combo id's
		IF (aux_json->>'queryTextFilter') IS NOT NULL AND v_selected_id IS NOT NULL THEN

			v_querystring = concat('SELECT (array_agg(id)) FROM (', (aux_json->>'queryText') ,' ',(aux_json->>'queryTextFilter'),'::text = ',quote_literal(v_selected_id)
			,' ORDER BY ',v_orderby,') a');
			v_debug_vars := json_build_object('aux_json->>''queryText''', (aux_json->>'queryText'), 'aux_json->>''queryTextFilter''', (aux_json->>'queryTextFilter'), 'v_selected_id', v_selected_id, 'v_orderby', v_orderby);
			v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 60);
			SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;

			EXECUTE v_querystring INTO v_array;
		ELSE
			v_querystring = concat('SELECT (array_agg(id)) FROM (',(aux_json->>'queryText'),' ORDER BY ',v_orderby,')a');
			v_debug_vars := json_build_object('aux_json->>''queryText''', (aux_json->>'queryText'), 'v_orderby', v_orderby);
			v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 70);
			SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
			EXECUTE v_querystring INTO v_array;

		END IF;

		-- set false the editability
		v_editability = replace (((aux_json->>'widgetcontrols')::json->>'enableWhenParent'), '[', '{');
		v_editability = replace (v_editability, ']', '}');

		IF v_selected_id::text != ANY (v_editability::text[]) THEN
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'iseditable', false);
		END IF;

		-- Enable null values
		IF (aux_json->>'dv_isnullvalue')::boolean IS TRUE THEN
			v_array = array_prepend('',v_array);
		END IF;
		combo_json = array_to_json(v_array);
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'comboIds', COALESCE(combo_json, '[]'));

		-- Get combo values
		IF (aux_json->>'queryTextFilter') IS NOT NULL AND v_selected_id IS NOT NULL THEN
			v_querystring = concat('SELECT (array_agg(idval)) FROM (', (aux_json->>'queryText') , ' ' ,(aux_json->>'queryTextFilter'),'::text = ',quote_literal(v_selected_id)
			,' ORDER BY ',v_orderby,') a');
			v_debug_vars := json_build_object('aux_json->>''queryText''', (aux_json->>'queryText'), 'aux_json->>''queryTextFilter''', (aux_json->>'queryTextFilter'), 'v_selected_id', v_selected_id, 'v_orderby', v_orderby);
			v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 80);
			SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
			EXECUTE v_querystring INTO v_array;
		ELSE
			v_querystring = concat('SELECT (array_agg(idval)) FROM (',(aux_json->>'queryText'),' ORDER BY ',v_orderby,')a');
			v_debug_vars := json_build_object('aux_json->>''queryText''', (aux_json->>'queryText'), 'v_orderby', v_orderby);
			v_debug_sql := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getformfields', 'flag', 90);
			SELECT gw_fct_debugsql(v_debug_sql) INTO v_msgerr;
			EXECUTE v_querystring INTO v_array;
		END IF;

		-- Enable null values
		IF (aux_json->>'dv_isnullvalue')::boolean IS TRUE THEN
			v_array = array_prepend('',v_array);
			-- remove key when is used
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'isNullValue');
		END IF;
		combo_json = array_to_json(v_array);

		combo_json := COALESCE(combo_json, '[]');
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'comboNames', combo_json);

		-- for typeahead widgets
		IF aux_json->>'widgettype' = 'typeahead' and (aux_json->>'queryText') IS NOT NULL THEN

			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'getDataAction', 'dataset'::text);
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'selectAction', 'setWidgetValue'::text);
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'threshold', 3);
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'dataset', combo_json);

		ELSE
			--removing the not used keys
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT],
			'queryText', 'orderById', 'parentId', 'queryTextFilter');
		END IF;

	END LOOP;

	-- add logic to deal with min_roles and widgets to show
	-- Extract current user roles (ensuring it's never NULL)
	SELECT ARRAY_AGG(rolname) INTO v_user_roles FROM pg_roles
	WHERE pg_has_role(current_user, oid, 'member');


	-- Filter fields based on minRole
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->'widgetcontrols'->>'minRole' IS NOT NULL OR a->'widgetcontrols'->>'minRole' <> ''
	LOOP
	    v_min_role := aux_json->'widgetcontrols'->>'minRole';


	    IF NOT EXISTS (
	        SELECT 1 FROM unnest(v_user_roles) AS user_role WHERE user_role = v_min_role
	    ) THEN
	        fields_array[(aux_json->>'orderby')::INT] :=
	            gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'hidden', true);

	    END IF;
	END LOOP;

	-- for the rest of widgets removing not used keys
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'widgettype' NOT IN ('image', 'combo', 'typeahead', 'multiple_option')
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT],
		'queryText', 'orderById', 'isNullValue', 'parentId', 'queryTextFilter');
	END LOOP;

	-- Remove widgetaction when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'widgetaction' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'widgetaction');
	END LOOP;

	-- Remove updateaction when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'updateaction' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'updateaction');
	END LOOP;

	-- Remove changeaction when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'changeaction' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'changeaction');
	END LOOP;

	-- Remove widgetfunction when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'widgetfunction' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'widgetfunction');
	END LOOP;

	/*
	-- Remove stylesheet when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'stylesheet' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'stylesheet');
	END LOOP;
	*/

	-- Remove tooltip when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'tooltip' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'tooltip');
	END LOOP;

	-- Remove linkedobject when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'linkedobject' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'linkedobject');
	END LOOP;

	-- Remove placeholder when is null
	FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a WHERE a->>'placeholder' is null
	LOOP
		fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'placeholder');
	END LOOP;

	IF p_device != 5 THEN
		-- Remove web_layoutorder if form is not for web
		FOR aux_json IN SELECT * FROM json_array_elements(array_to_json(fields_array)) AS a
		LOOP
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_delete_keys(fields_array[(aux_json->>'orderby')::INT], 'web_layoutorder');
		END LOOP;
	END IF;

	-- Convert to json
	fields := array_to_json(fields_array);

	PERFORM gw_fct_debug(concat('{"data":{"msg":"<---- OUTPUT FOR gw_fct_getformfields: ", "variables":""}}')::json);

	-- Return
	RETURN fields_array;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

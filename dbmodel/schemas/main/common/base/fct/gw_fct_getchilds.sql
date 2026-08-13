/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2572

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getchilds(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getchilds(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_getchilds($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},
"feature":{"featureType":"arc", "tableName":"ve_arc_pipe", "idName":"arc_id"},
"data":{"comboParent":"state", "comboId":"1"}}$$)

SELECT SCHEMA_NAME.gw_fct_getchilds($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},
"feature":{"featureType":"arc", "tableName":"ve_arc_pipe", "idName":"arc_id"},
"data":{"comboParent":"expl_id", "comboId":"2"}}$$)

SELECT SCHEMA_NAME.gw_fct_getchilds($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},
"feature":{"tableName":"config"},
"data":{"comboParent":"inp_options_demandtype", "comboId":"1"}}$$)

*/

DECLARE

v_tablename character varying;
v_idname character varying;
v_comboparent character varying;
v_combovalue character varying;
v_featuretype character varying;
	
v_fields json;
v_combo_rows_child json[];
v_aux_json_child json;    
combo_json_child json;
schemas_array name[];
v_version text;
query_text text;
v_current_value text;
v_column_type varchar;
v_parameter text;
v_formtype varchar;
v_config_param_user record;
v_message json;
v_orderby text;
v_editability text;
v_errcontext text;
v_querystring text;
v_debug_vars json;
v_debug json;
v_msgerr json;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- Get schema name
	schemas_array := current_schemas(FALSE);

	-- get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get input parameters
	--v_id :=  ((p_data ->>'feature')::json->>'id')::text;
	v_featuretype = ((p_data ->>'feature')::json->>'featureType')::text;
	v_tablename = ((p_data ->>'feature')::json->>'tableName')::text;
	v_idname = ((p_data ->>'feature')::json->>'idName')::text;
	v_comboparent = ((p_data ->>'data')::json->>'comboParent')::text;
	v_combovalue = ((p_data ->>'data')::json->>'comboId')::text;

			
	-- get column type of idname
	v_querystring = concat('SELECT data_type FROM information_schema.columns  WHERE table_schema = ',quote_nullable(schemas_array[1]),' AND table_name = ',quote_literal(v_tablename),' AND column_name = ',quote_nullable(v_idname));
	v_debug_vars := json_build_object('schemas_array[1]', schemas_array[1], 'v_tablename', v_tablename, 'v_idname', v_idname);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 10);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	EXECUTE v_querystring INTO v_column_type;

	IF (v_tablename = 'config') THEN

		--  Combo rows child CONFIG
		v_querystring = concat('SELECT (array_agg(row_to_json(a))) FROM (
				 SELECT label, sys_param_user.id as widgetname, datatype, widgettype, layoutorder,layoutname,
				(CASE WHEN iseditable IS NULL OR iseditable IS TRUE THEN ''True'' ELSE ''False'' END) AS iseditable,
				 row_number()over(ORDER BY layoutname, layoutorder) AS orderby, value, project_type, dv_querytext, dv_querytext_filterc, dv_parent_id, isparent, sys_role,
				 placeholder,
				 dv_orderby_id,feature_dv_parent_value, descript AS tooltip, dv_isnullvalue AS "isNullValue", widgetcontrols
				 FROM sys_param_user LEFT JOIN (SELECT * FROM config_param_user WHERE cur_user=current_user) a ON a.parameter=sys_param_user.id 
				 WHERE sys_role IN (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
				 AND dv_parent_id=',quote_literal(v_comboparent),'
				 AND isenabled IS TRUE
				 ORDER BY orderby) a WHERE widgettype = ''combo''');
		v_debug_vars := json_build_object('v_comboparent', v_comboparent);
		v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 20);
		SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
		EXECUTE v_querystring INTO v_combo_rows_child;
		v_combo_rows_child := COALESCE(v_combo_rows_child, '{}');

		v_formtype='config';

	ELSIF (v_tablename = 'catalog') THEN

		-- Get parameter to seacrh
		v_parameter:= 'upsert_catalog_' || v_featuretype;

		--  Combo rows child CATALOG
		v_querystring = concat('SELECT array_agg(row_to_json(a)) FROM (SELECT columnname, widgettype, columnname as widgetname,
				dv_querytext, isparent, dv_parent_id, row_number()over(ORDER BY layoutname, layoutorder) AS orderby , dv_querytext_filterc, isautoupdate, placeholder, dv_orderby_id, tooltip, dv_isnullvalue AS "isNullValue", widgetcontrols
				FROM columnname WHERE formname = ',quote_literal(v_parameter),' AND dv_parent_id=',quote_literal(v_comboparent),' ORDER BY orderby) a WHERE widgettype = ''combo''');
		v_debug_vars := json_build_object('v_parameter', v_parameter, 'v_comboparent', v_comboparent);
		v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 30);
		SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
		EXECUTE v_querystring INTO v_combo_rows_child;
		v_combo_rows_child := COALESCE(v_combo_rows_child, '{}');
		v_formtype='catalog';

	ELSE
		--  Combo rows child
		v_querystring = concat('SELECT array_agg(row_to_json(a)) FROM (SELECT columnname, widgettype, datatype, concat(''tab_data_'',columnname) as widgetname,
				dv_querytext, isparent, dv_parent_id, row_number()over(ORDER BY layoutname, layoutorder) AS orderby , dv_querytext_filterc, isautoupdate, placeholder, dv_orderby_id, tooltip, dv_isnullvalue AS "isNullValue", widgetcontrols
				FROM v_config_form_fields WHERE formname = ',quote_nullable(v_tablename),' AND dv_parent_id=',quote_literal(v_comboparent),' ORDER BY orderby) a WHERE widgettype = ''combo''');
		v_debug_vars := json_build_object('v_tablename', v_tablename, 'v_comboparent', v_comboparent);
		v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 40);
		SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
		EXECUTE v_querystring INTO v_combo_rows_child;
		v_combo_rows_child := COALESCE(v_combo_rows_child, '{}');
		v_formtype='feature';
	END IF;

	FOREACH v_aux_json_child IN ARRAY v_combo_rows_child
	LOOP
		-- Define the order by column
		IF (v_aux_json_child->>'dv_orderby_id')::boolean IS TRUE THEN
			v_orderby='id';
		ELSE 
			v_orderby='idval';
		END IF;
		
		-- set false the editability
		v_editability = replace (((v_aux_json_child->>'editability')::json->>'trueWhenParentIn'), '[', '{');
		v_editability = replace (v_editability, ']', '}');


		IF v_combovalue != ANY (v_editability::text[]) THEN
			v_combo_rows_child[(v_aux_json_child->>'orderby')::INT] := gw_fct_json_object_set_key(v_combo_rows_child[(v_aux_json_child->>'orderby')::INT], 'iseditable', false);
		END IF;

		-- Get combo child name
		--v_combo_rows_child[(v_aux_json_child->>'orderby')::INT] := gw_fct_json_object_set_key(v_combo_rows_child[(v_aux_json_child->>'orderby')::INT], 'widgetname', (v_aux_json_child->>'widgetname'));
		
		-- Get combo id's
		IF (v_aux_json_child->>'dv_querytext_filterc') IS NOT NULL AND v_combovalue IS NOT NULL THEN
			query_text = concat('SELECT array_to_json(array_agg(id)) FROM (',((v_aux_json_child->>'dv_querytext')),((v_aux_json_child->>'dv_querytext_filterc')),'::text = ',(quote_literal(v_combovalue)),' ORDER BY ',v_orderby,') a');
			v_debug_vars := json_build_object('v_aux_json_child->>''dv_querytext''', (v_aux_json_child->>'dv_querytext'), 'v_aux_json_child->>''dv_querytext_filterc''', (v_aux_json_child->>'dv_querytext_filterc'), 'v_combovalue', v_combovalue, 'v_orderby', v_orderby);
			v_debug := json_build_object('querystring', query_text, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 50);
			SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
			EXECUTE query_text INTO combo_json_child;
		ELSE 	
			v_querystring = concat('SELECT array_to_json(array_agg(id)) FROM (',((v_aux_json_child->>'dv_querytext')),' ORDER BY ',v_orderby,')a');
			v_debug_vars := json_build_object('v_aux_json_child->>''dv_querytext''', (v_aux_json_child->>'dv_querytext'), 'v_orderby', v_orderby);
			v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 60);
			SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
			EXECUTE v_querystring INTO combo_json_child;
		END IF;
		
		combo_json_child := COALESCE(combo_json_child, '[]');
		v_combo_rows_child[(v_aux_json_child->>'orderby')::INT] := gw_fct_json_object_set_key(v_combo_rows_child[(v_aux_json_child->>'orderby')::INT], 'comboIds', COALESCE(combo_json_child, '[]'));
	
		-- Get combo value's
		IF (v_aux_json_child->>'dv_querytext_filterc') IS NOT NULL AND v_combovalue IS NOT NULL THEN
			query_text = concat('SELECT array_to_json(array_agg(idval)) FROM (',(v_aux_json_child->>'dv_querytext'),(v_aux_json_child->>'dv_querytext_filterc'),'::text = ',quote_literal(v_combovalue),' ORDER BY ',v_orderby,') a');
			v_debug_vars := json_build_object('v_aux_json_child->>''dv_querytext''', (v_aux_json_child->>'dv_querytext'), 'v_aux_json_child->>''dv_querytext_filterc''', (v_aux_json_child->>'dv_querytext_filterc'), 'v_combovalue', v_combovalue, 'v_orderby', v_orderby);
			v_debug := json_build_object('querystring', query_text, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 70);
			SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
			EXECUTE query_text INTO combo_json_child;
		ELSE 	
			v_querystring = concat('SELECT array_to_json(array_agg(idval)) FROM (',((v_aux_json_child->>'dv_querytext')),' ORDER BY ',v_orderby,')a');
			v_debug_vars := json_build_object('v_aux_json_child->>''dv_querytext''', (v_aux_json_child->>'dv_querytext'), 'v_orderby', v_orderby);
			v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_getchilds', 'flag', 80);
			SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
			EXECUTE v_querystring INTO combo_json_child;
		END IF;
		combo_json_child := COALESCE(combo_json_child, '[]');
		v_combo_rows_child[(v_aux_json_child->>'orderby')::INT] := gw_fct_json_object_set_key(v_combo_rows_child[(v_aux_json_child->>'orderby')::INT], 'comboNames', combo_json_child);

		-- Set current value
		IF v_formtype != 'feature' THEN
			v_combo_rows_child[(v_aux_json_child->>'orderby')::INT] := gw_fct_json_object_set_key(v_combo_rows_child[(v_aux_json_child->>'orderby')::INT], 'selectedId', combo_json_child->0);
		ELSE
			--looping for the differents velues on sys_param_user that are coincident with the child parameter
			FOR v_config_param_user IN SELECT * FROM sys_param_user WHERE feature_field_id = (v_aux_json_child->>'columnname')
			LOOP
				IF v_config_param_user.feature_dv_parent_value IS NULL THEN 
					-- if there is only one because dv_parent_value is null then
					v_current_value = (SELECT value FROM config_param_user JOIN sys_param_user ON sys_param_user.id=config_param_user.parameter 
							WHERE feature_field_id = (v_aux_json_child->>'columnname')
							AND cur_user=current_user LIMIT 1);			
				ELSE
					-- if there are more than one, taking that parameter with the same feature_dv_parent_value
					v_current_value = (SELECT value FROM config_param_user JOIN sys_param_user ON sys_param_user.id=config_param_user.parameter 
							WHERE feature_field_id = quote_ident(v_aux_json_child->>'columnname')
							AND feature_dv_parent_value = v_combovalue
							AND cur_user=current_user LIMIT 1);
				END IF;
			END LOOP;
			
			v_combo_rows_child[(v_aux_json_child->>'orderby')::INT] := gw_fct_json_object_set_key(v_combo_rows_child[(v_aux_json_child->>'orderby')::INT], 'selectedId', v_current_value);           		
		END IF;

	END LOOP;
	
	-- Convert to json
    v_fields := array_to_json(v_combo_rows_child);

    v_message := '{"level":"0", "text":"Childs update successfully"}';

	--  Control NULL's
	v_message := COALESCE(v_message, '[]');
	v_version := COALESCE(v_version, '');
	v_fields := COALESCE(v_fields, '[]');    
    
	--  Return
    RETURN ('{"status":"Accepted"' || ', "message":'|| v_message || ', "version":"'|| v_version ||'"' ||
        ', "body": {"form":{}'||
		 ', "feature":{}'||
		 ', "data":' || v_fields ||
		'}}')::json;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_errcontext = pg_exception_context;
	RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE, 'MSGERR', (v_msgerr::json ->> 'MSGERR'))::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


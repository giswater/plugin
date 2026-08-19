/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2770

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_gettoolbox(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:
SELECT SCHEMA_NAME.gw_fct_gettoolbox($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"data":{"filterText":"Import inp epanet file"}}$$)

SELECT SCHEMA_NAME.gw_fct_gettoolbox($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"data":{"filterText":"Import inp epanet file"}}$$)

SELECT SCHEMA_NAME.gw_fct_gettoolbox($${"client":{"device":4, "lang":"CA", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "isToolbox":true}}$$);


*/

DECLARE

v_version text;
v_role text;
v_projectype text;
v_filter text;
v_om_fields json;
ve_fields json;
v_epa_fields json;
v_master_fields json;
v_admin_fields json;
v_cm_fields json;
v_isepa boolean = false;
v_epa_user text;
rec record;
v_querytext text;
v_querytext_mod text;
v_queryresult text;
v_expl text;
v_state text;
v_inp_result text;
v_rpt_result text;
v_return json;
v_return2 text;
v_nodetype text;
v_nodecat text;
v_arrayresult text[];
v_selectedid text;
v_rec_replace json;
v_errcontext text;
v_querystring text;
v_debug_vars json;
v_debug json;
v_msgerr json;
v_value text;
v_reports json;
v_reports_basic json;
v_reports_om json;
v_reports_edit json;
v_reports_epa json;
v_reports_master json;
v_reports_admin json;
v_inp_hydrology text;
v_inp_dwf text;
v_inp_dscenario text;
v_sector text;
v_process json;
v_mincut integer;
v_device integer;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get input parameter
	v_filter := (p_data ->> 'data')::json->> 'filterText';
	v_device := (p_data ->> 'client')::json->> 'device';

	-- get project type
	SELECT lower(project_type) INTO v_projectype FROM sys_version ORDER BY id DESC LIMIT 1;

	v_filter := COALESCE(v_filter, '');

	-- get epa results
	IF (SELECT result_id FROM rpt_cat_result LIMIT 1) IS NOT NULL THEN
		v_isepa = true;
		v_epa_user = (SELECT result_id FROM rpt_cat_result WHERE cur_user=current_user LIMIT 1);
		IF v_epa_user IS NULL THEN
			v_epa_user = (SELECT result_id FROM rpt_cat_result LIMIT 1);
		END IF;
	END IF;

	-- get om toolbox parameters
	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT config_toolbox.id, alias, function_name as functionname
			 FROM sys_function
			 JOIN config_toolbox USING (id)
			 WHERE alias ILIKE ''%', v_filter ,'%'' AND sys_role =''role_om'' AND config_toolbox.active IS TRUE
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND (project_type=',quote_literal(v_projectype),' or project_type=''utils'')
			 AND ',v_device,' = ANY(device)) a');
	v_debug_vars := json_build_object('v_filter', v_filter, 'v_projectype', v_projectype);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 10);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	EXECUTE v_querystring INTO v_om_fields;

	-- get edit toolbox parameters
	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT config_toolbox.id, alias, function_name as functionname
			 FROM sys_function
			 JOIN config_toolbox USING (id)
			 WHERE alias ILIKE ''%', v_filter ,'%'' AND sys_role =''role_edit'' AND config_toolbox.active IS TRUE
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND ( project_type=',quote_literal(v_projectype),' or project_type=''utils'')
			 AND ',v_device,' = ANY(device)) a');
	v_debug_vars := json_build_object('v_filter', v_filter, 'v_projectype', v_projectype);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 20);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	EXECUTE v_querystring INTO ve_fields;

	-- get epa toolbox parameters
	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			SELECT config_toolbox.id, alias, function_name as functionname
			FROM sys_function
			JOIN config_toolbox USING (id)
			WHERE alias ILIKE ''%', v_filter ,'%'' AND sys_role =''role_epa'' AND config_toolbox.active IS TRUE
			AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			AND ( project_type=',quote_literal(v_projectype),' or project_type=''utils'')
			AND ',v_device,' = ANY(device)) a');
	v_debug_vars := json_build_object('v_filter', v_filter, 'v_projectype', v_projectype);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 30);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	EXECUTE v_querystring INTO v_epa_fields;

	-- get master toolbox parameters
	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT config_toolbox.id, alias, function_name as functionname
			 FROM sys_function
			 JOIN config_toolbox USING (id)
			 WHERE alias ILIKE ''%', v_filter ,'%'' AND sys_role =''role_plan'' AND config_toolbox.active IS TRUE
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND (project_type=',quote_literal(v_projectype),' OR project_type=''utils'')
			 AND ',v_device,' = ANY(device)) a');
	v_debug_vars := json_build_object('v_filter', v_filter, 'v_projectype', v_projectype);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 40);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	EXECUTE v_querystring INTO v_master_fields;

	-- get admin toolbox parameters
	v_querystring = concat('
		SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT config_toolbox.id, alias, function_name as functionname
			 FROM sys_function
			 JOIN config_toolbox USING (id)
			 WHERE alias ILIKE ''%', v_filter ,'%'' AND sys_role =''role_admin'' AND config_toolbox.active IS TRUE
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND (project_type=',quote_literal(v_projectype),' or project_type=''utils'')
			 AND ',v_device,' = ANY(device)
			 AND (COALESCE(source,'''') <> ''cm'' OR EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = ''cm''))
		) a');

	v_debug_vars := json_build_object('v_filter', v_filter, 'v_projectype', v_projectype);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 50);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	EXECUTE v_querystring INTO v_admin_fields;

	-- get cm toolbox parameters
	v_querystring = concat('
		SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT config_toolbox.id, alias, function_name as functionname
			 FROM sys_function
			 JOIN config_toolbox USING (id)
			 WHERE alias ILIKE ''%', v_filter ,'%'' AND sys_role =''role_cm'' AND config_toolbox.active IS TRUE
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND (project_type=',quote_literal(v_projectype),' or project_type=''utils'')
			 AND ',v_device,' = ANY(device)
			 AND EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = ''cm'')
		) a');

	v_debug_vars := json_build_object('v_filter', v_filter, 'v_projectype', v_projectype);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 50);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	EXECUTE v_querystring INTO v_cm_fields;

	-- get reports toolbox parameters
	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT id, alias, addparam
			 FROM v_config_report
			 WHERE sys_role = ''role_basic''
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND alias ILIKE ''%', v_filter ,'%'' AND active IS TRUE AND ',v_device,' = ANY(device) ORDER BY id) a');

	EXECUTE v_querystring INTO v_reports_basic;

	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT id, alias, addparam
			 FROM v_config_report
			 WHERE sys_role = ''role_om''
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND alias ILIKE ''%', v_filter ,'%'' AND active IS TRUE AND ',v_device,' = ANY(device) ORDER BY id) a');

	EXECUTE v_querystring INTO v_reports_om;

	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT id, alias, addparam
			 FROM v_config_report
			 WHERE sys_role = ''role_edit''
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND alias ILIKE ''%', v_filter ,'%'' AND active IS TRUE AND ',v_device,' = ANY(device) ORDER BY id) a');

	EXECUTE v_querystring INTO v_reports_edit;

	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT id, alias, addparam
			 FROM v_config_report
			 WHERE sys_role = ''role_epa''
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND alias ILIKE ''%', v_filter ,'%'' AND active IS TRUE AND ',v_device,' = ANY(device) ORDER BY id) a');

	EXECUTE v_querystring INTO v_reports_epa;

	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT id, alias, addparam
			 FROM v_config_report
			 WHERE sys_role = ''role_plan''
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND alias ILIKE ''%', v_filter ,'%'' AND active IS TRUE AND ',v_device,' = ANY(device) ORDER BY id) a');

	EXECUTE v_querystring INTO v_reports_master;

	v_querystring = concat('SELECT array_to_json(array_agg(row_to_json(a))) FROM (
			 SELECT id, alias, addparam
			 FROM v_config_report
			 WHERE sys_role = ''role_admin''
			 AND sys_role IN  (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, ''member''))
			 AND alias ILIKE ''%', v_filter ,'%'' AND active IS TRUE AND ',v_device,' = ANY(device) ORDER BY id) a');

	EXECUTE v_querystring INTO v_reports_admin;

	SELECT json_strip_nulls(json_build_object('basic', v_reports_basic,
	'om', v_reports_om,
	'edit', v_reports_edit,
	'epa', v_reports_epa,
	'master', v_reports_master,
	'admin', v_reports_admin)) INTO v_reports;

--    Control NULL's
	SELECT json_strip_nulls(json_build_object('om', v_om_fields,
	'edit', ve_fields,
	'epa', v_epa_fields,
	'master', v_master_fields,
	'admin', v_admin_fields,
	'cm', v_cm_fields)) INTO v_process;

	v_process := COALESCE(v_process, '[]');
	v_reports := COALESCE(v_reports, '[]');

	-- make return
	v_return ='{"status":"Accepted", "message":{"level":1, "text":"Process done successfully"}, "version":"'||v_version||'","body":{"form":{}'||
		     ',"feature":{}'||
		     ',"data":{"processes":{"fields": '|| v_process ||'}'||
				', "reports":{"fields":'||v_reports||'}}}}';

	RETURN v_return;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_errcontext = pg_exception_context;
	RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM,  'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'version', v_version, 'SQLSTATE', SQLSTATE, 'MSGERR', (v_msgerr::json ->> 'MSGERR'))::json;

END;
$function$
;

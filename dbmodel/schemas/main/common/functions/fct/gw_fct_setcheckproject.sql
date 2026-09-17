/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2794

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_audit_check_project(INTEGER);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_audit_check_project(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setcheckproject (p_data json)
  RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_setcheckproject($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
"version":"3.5.021.1", "fid":101, "initProject":false, "addSchema":"NULL", "mainSchema":"NULL", "projecRole":"role_admin", "infoType":"full", "logFolderVolume":"139.56 MB",
"projectType":"ws", "qgisVersion":"3.16.6-Hannover", "osVersion":"Windows 10"}}$$);
-- fid: main: 101
*/

DECLARE

v_querytext text;
v_count integer = 0;
v_table_host text;
v_table_dbname text;
v_table_schema text;
v_project_type text;
v_errortext text;
v_version text;
v_epsg integer;
v_return json;
v_missing_layers json;
v_schemaname text;
v_layer_list text;
v_result_point json;
v_result_line json;
v_result_polygon json;
v_result json;
v_result_info json;
v_qgis_version text;
v_error_context text;
v_init_project boolean;
v_qgisversion text;
v_osversion text;
v_qgis_init_guide_map boolean;
v_qgis_layers_setpropierties boolean;
v_addschema text;
v_fid integer;
v_mainschema text;
v_projectrole text;
v_infotype text;
v_insert_fields json;
v_field json;
v_qgis_project_type text;
v_logfoldervolume text;
v_uservalues json;
v_show_versions boolean=True;
v_show_qgis_project boolean=True;

BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	SELECT project_type, giswater, epsg INTO v_project_type, v_version, v_epsg FROM sys_version order by id desc limit 1;

	-- Get input parameters
	v_fid := (p_data ->> 'data')::json->> 'fid';
	v_qgis_version := (p_data ->> 'data')::json->> 'version';
	v_init_project := (p_data ->> 'data')::json->> 'initProject';
	v_qgisversion := (p_data ->> 'data')::json->> 'qgisVersion';
	v_osversion := (p_data ->> 'data')::json->> 'osVersion';
	v_addschema := (p_data ->> 'data')::json->> 'addSchema';
	v_mainschema := (p_data ->> 'data')::json->> 'mainSchema';
	v_projectrole := (p_data ->> 'data')::json->> 'projectRole';
	v_infotype := (p_data ->> 'data')::json->> 'infoType';
	v_insert_fields := (p_data ->> 'data')::json->> 'fields';
	v_qgis_project_type := (p_data ->> 'data')::json->> 'projectType';
	v_logfoldervolume := (p_data ->> 'data')::json->> 'logFolderVolume';
	v_show_versions :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'showVersions';
	v_show_qgis_project :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'showQgisProject';

	-- profilactic control of qgis variables
	IF lower(v_mainschema) = 'none' OR v_mainschema = '' OR lower(v_mainschema) ='null' THEN v_mainschema = null; END IF;
	IF lower(v_projectrole) = 'none' OR v_projectrole = '' OR lower(v_projectrole) ='null' THEN v_projectrole = null; END IF;
	IF lower(v_infotype) = 'none' OR v_infotype = '' OR lower(v_infotype) ='null' THEN v_infotype = null; END IF;
	IF lower(v_qgis_project_type) = 'none' OR v_qgis_project_type = '' OR lower(v_qgis_project_type) ='null' THEN v_qgis_project_type = null; END IF;

	-- profilactic control of schema name
	IF lower(v_addschema) = 'none' OR v_addschema = '' OR lower(v_addschema) ='null' OR v_addschema is null THEN
		 v_addschema = null;
	ELSE
		IF (select schemaname from pg_tables WHERE schemaname = v_addschema LIMIT 1) IS NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3132", "function":"2580","parameters":null, "is_process":true}}$$)';
		END IF;
	END IF;

	-- get user parameters
	SELECT value INTO v_qgis_init_guide_map FROM config_param_user where parameter='qgis_init_guide_map' AND cur_user=current_user;
	SELECT value INTO v_qgis_layers_setpropierties FROM config_param_user where parameter='qgis_layers_set_propierties' AND cur_user=current_user;
	IF v_qgis_init_guide_map IS NULL THEN v_qgis_init_guide_map = FALSE; END IF;
	IF v_qgis_layers_setpropierties IS NULL THEN v_qgis_layers_setpropierties = TRUE; END IF;

	-- create temp tables
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"CREATE", "group":"CHECKPROJECT"}}}$$)';

	-- Header log
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2794", "fid":"'||v_fid||'", "criticity":"4", "is_process":true, "is_header":"true", "label_id":"3010", "separator_id":"2030", "tempTable":"t_"}}$$)';
	IF v_show_versions THEN
		--check plugin and db version and other system parameters
		IF v_qgis_version = v_version THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4100", "function":"2794", "fid":"'||v_fid||'", "result_id":"null", "fcount":"0", 
			"parameters":{"version":"'||v_version||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4102", "function":"2794", "fid":"'||v_fid||'", "result_id":"349", "fcount":"1", 
			"parameters":{"version":"'||v_version||'", "qgis_version":"'||v_qgisversion||'"}, "prefix_id":"1003", "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		END IF;

		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4104", "function":"2794", "fid":"'||v_fid||'",  "result_id":"null", "fcount":"0", 
		"parameters":{"version":"'||(SELECT version())||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4106", "function":"2794", "fid":"'||v_fid||'",  "result_id":"null", "fcount":"0", 
		"parameters":{"postgis_version":"'||(SELECT postgis_version())||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4108", "function":"2794", "fid":"'||v_fid||'",  "result_id":"null", "fcount":"0", 
		"parameters":{"qgis_version":"'||v_qgisversion||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4110", "function":"2794", "fid":"'||v_fid||'",  "result_id":"null", "fcount":"0", 
		"parameters":{"os_version":"'||v_osversion||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';

		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2794", "fid":"'||v_fid||'", "criticity":"4", "is_process":true, "separator_id":"2000", "fcount":"0", "tempTable":"t_"}}$$)';
	END IF;

	IF v_show_qgis_project THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4112", "function":"2794", "fid":"'||v_fid||'",  "result_id":"null", "fcount":"0", 
		"parameters":{"logfoldervolume":"'||v_logfoldervolume||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4114", "function":"2794", "fid":"'||v_fid||'",  "result_id":"null", "fcount":"0", 
		"parameters":{"v_qgis_project_type":"'||quote_nullable(v_qgis_project_type)||'", "v_infotype":"'||quote_nullable(v_infotype)||'", "v_projectrole":"'||quote_nullable(v_projectrole)||'", 
		"v_mainschema":"'||quote_nullable(v_mainschema)||'", "v_addschema":"'||quote_nullable(v_addschema)||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4116", "function":"2794", "fid":"'||v_fid||'",  "result_id":"null", "fcount":"0", 
		"parameters":{"current_user":"'||current_user||'", "now":"'||now()||'"}, "criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';


		-- check layers from project and insert on log table
		v_querytext=NULL;
		FOR v_field in SELECT * FROM json_array_elements(v_insert_fields) LOOP
			select into v_querytext concat(v_querytext, 'INSERT INTO t_audit_check_project (table_schema, table_id, table_dbname, table_host, fid, table_user) ') ;
			select into v_querytext concat(v_querytext, 'VALUES('||quote_literal((v_field->>'table_schema'))||', '||quote_literal((v_field->>'table_id'))||', '||quote_literal((v_field->>'table_dbname'))||',
			'||quote_literal((v_field->>'table_host'))||'') ;
			select into v_querytext concat(v_querytext, ', '||quote_literal((v_field->>'fid'))||', '||quote_literal((v_field->>'table_user'))||');') ;
		END LOOP;
		IF v_querytext IS NOT NULL THEN EXECUTE v_querytext; END IF;

		-- get db source using ve_node as 'current'  (in case ve_node is wrong all will he wrong)
		SELECT table_host, table_dbname, table_schema INTO v_table_host, v_table_dbname, v_table_schema
		FROM t_audit_check_project where table_id = 've_node' and cur_user=current_user;

		--check layers host (350)
		SELECT count(*), string_agg(table_id,',') INTO v_count, v_layer_list
		FROM audit_check_project WHERE table_host != v_table_host AND cur_user=current_user;

		IF v_count>0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4118", "function":"2794", "fid":"'||v_fid||'", "result_id":"350", "fcount":"0", 
			"parameters":{"v_count":"'||v_count||'", "v_layer_list":"'||v_layer_list||'"}, "criticity":"3", "prefix_id":"1003", "is_process":true, "tempTable":"t_"}}$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4120", "function":"2794", "fid":"'||v_fid||'", "result_id":"350", "fcount":"0", 
			"criticity":"1", "prefix_id":"1001", "is_process":true, "tempTable":"t_"}}$$)';
		END IF;

		--check layers database (351)
		SELECT count(*), string_agg(table_id,',') INTO v_count, v_layer_list
		FROM audit_check_project WHERE table_dbname != v_table_dbname AND cur_user=current_user;

		IF v_count>0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4122", "function":"2794", "fid":"'||v_fid||'", "result_id":"351", "fcount":"0", 
			"parameters":{"v_count":"'||v_count||'", "v_layer_list":"'||v_layer_list||'"}, "criticity":"3", "prefix_id":"1003", "is_process":true, "tempTable":"t_"}}$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4124", "function":"2794", "fid":"'||v_fid||'", "result_id":"351", "fcount":"0", 
			"criticity":"1", "prefix_id":"1001", "is_process":true, "tempTable":"t_"}}$$)';
		END IF;

		--check layers database (352)
		SELECT count(*), string_agg(table_id,',') INTO v_count, v_layer_list
		FROM audit_check_project WHERE table_schema != v_table_schema AND cur_user=current_user;

		IF v_count>0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4126", "function":"2794", "fid":"'||v_fid||'", "result_id":"352", "fcount":"0", 
			"parameters":{"v_count":"'||v_count||'", "v_layer_list":"'||v_layer_list||'"}, "criticity":"3", "prefix_id":"1003", "is_process":true, "tempTable":"t_"}}$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4128", "function":"2794", "fid":"'||v_fid||'", "result_id":"352", "fcount":"0", 
			"criticity":"1", "prefix_id":"1001", "is_process":true, "tempTable":"t_"}}$$)';
		END IF;

		--check layers user (353)
		SELECT count(*), string_agg(table_id,',') INTO v_count, v_layer_list
		FROM audit_check_project WHERE cur_user != table_user AND table_user != 'None' AND cur_user=current_user;

		IF v_count>0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4130", "function":"2794", "fid":"'||v_fid||'", "result_id":"353", "fcount":"0", 
			"parameters":{"v_count":"'||v_count||'", "v_layer_list":"'||v_layer_list||'"}, "criticity":"3", "prefix_id":"1003", "is_process":true, "tempTable":"t_"}}$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4132", "function":"2794", "fid":"'||v_fid||'", "result_id":"353", "fcount":"0", 
			"criticity":"1", "prefix_id":"1001", "is_process":true, "tempTable":"t_"}}$$)';
		END IF;
	END IF;

	-- Force state selector in case of null values for addschema
	IF v_addschema IS NOT NULL THEN

		EXECUTE 'SET search_path = '||v_addschema||', public';
		IF (SELECT count(*) FROM selector_state WHERE cur_user=current_user) < 1 THEN
			INSERT INTO selector_state (state_id, cur_user) VALUES (1, current_user);
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4134", "function":"2794", "fid":"'||v_fid||'", "result_id":"null", "fcount":"0", 
			"criticity":"4", "is_process":true, "tempTable":"t_"}}$$)';
		END IF;
		SET search_path = 'SCHEMA_NAME';
	END IF;

	-- set uservalues
	PERFORM gw_fct_setinitproject($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{}}$$);

	-- get uservalues (to show in return)
	PERFORM gw_fct_workspacemanager($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{},"data":{"filterFields":{}, "pageInfo":{}, "action":"CHECK"}}$$);
	UPDATE config_param_user SET value = NULL WHERE parameter = 'plan_psector_current' AND cur_user = current_user;
	v_uservalues = (SELECT to_json(array_agg(row_to_json(a))) FROM (SELECT parameter, value FROM config_param_user WHERE parameter IN ('plan_psector_current', 'utils_workspace_current')
	AND cur_user = current_user ORDER BY parameter)a);
	v_uservalues := COALESCE(v_uservalues, '{}');

	-- built return
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"info"}}}$$::json)' INTO v_result_info;
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"point"}}}$$::json)' INTO v_result_point;
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"line"}}}$$::json)' INTO v_result_line;
	EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"polygon"}}}$$::json)' INTO v_result_polygon;

	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"DROP", "group":"CHECKPROJECT"}}}$$)';

	-- Control null
	v_uservalues:=COALESCE(v_uservalues,'{}');
	v_missing_layers:=COALESCE(v_missing_layers,'{}');
	v_qgis_layers_setpropierties:=COALESCE(v_qgis_layers_setpropierties,true);
	v_qgis_init_guide_map:=COALESCE(v_qgis_init_guide_map,true);

	--return definition for v_audit_check_result
	v_return= ('{"status":"Accepted", "message":{"level":1, "text":"Data quality analysis done succesfully"}, "version":"'||v_version||'" '||
		',"body":{"form":{}'||
			',"data":{ "epsg":'||v_epsg||
					',"userValues":'||v_uservalues||
			    ',"info":'||v_result_info||','||
					'"point":'||v_result_point||','||
					'"line":'||v_result_line||','||
					'"polygon":'||v_result_polygon||','||
					'"missingLayers":'||v_missing_layers||'}'||
			', "variables":{"setQgisLayers":' || v_qgis_layers_setpropierties||', "useGuideMap":'||v_qgis_init_guide_map||'}}}')::json;

	--  Return
	RETURN v_return;

	--  Exception handling
	--EXCEPTION WHEN OTHERS THEN
	--GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	--RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE',
	--SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
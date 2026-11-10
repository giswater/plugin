/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3078

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_workspacemanager(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_workspacemanager(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
--create new workspace
SELECT SCHEMA_NAME.gw_fct_workspacemanager($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{},"data":{"filterFields":{}, "pageInfo":{}, "action":"CREATE", "name":"WS2", "descript":"test" }}$$);

--set workspace as current
SELECT SCHEMA_NAME.gw_fct_workspacemanager($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{},"data":{"filterFields":{}, "pageInfo":{}, "action":"CURRENT", "id":"9"}}$$);

--delete selected workspace
SELECT SCHEMA_NAME.gw_fct_workspacemanager($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{},"data":{"filterFields":{}, "pageInfo":{}, "action":"DELETE", "id":"1"}}$$);

SELECT SCHEMA_NAME.gw_fct_workspacemanager($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{},"data":{"filterFields":{}, "pageInfo":{}, "action":"CHECK" }}$$);

SELECT SCHEMA_NAME.gw_fct_workspacemanager($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{},"data":{"filterFields":{}, "pageInfo":{}, "action":"INFO","id":"2" }}$$);
*/

DECLARE

v_schemaname text = 'SCHEMA_NAME';
v_project_type text;

v_action text;
v_workspace_id integer;
v_workspace_name text;
v_workspace_config json;
v_selectors_config json;
v_selectors_configcompound json;
v_inp_json_config json;
v_workspace_descript text;
rec_selector json;
v_config_values json;
v_selector_name text;
v_selector_value json;
rec_inp text;
rec_selectorcomp text;
rec_selectorcolumn record;
v_datatype text;
v_fid integer=398;
v_check_config json;
v_workspace_private boolean=false;

v_return_level integer;
v_return_status text;
v_return_msg text;
v_error_context text;
v_audit_result text;
v_version text;
v_result_info json;
v_uservalues json;
v_querytext text;
v_iseditable boolean;
v_deleted_dscenario text;
v_deleted_psector text;
v_deleted_sector text;
v_deleted_result text;
v_deleted_muni text;
v_geometry text;

BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;

	-- get project type
	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;


	-- get parameters
	v_action = json_extract_path_text(p_data,'data','action');
	v_workspace_id = json_extract_path_text(p_data,'data','id');
	v_workspace_name = json_extract_path_text(p_data,'data','name');
	v_workspace_descript = json_extract_path_text(p_data,'data','descript');
	v_workspace_private = json_extract_path_text(p_data,'data', 'private');

	IF v_workspace_name IS NULL THEN
		SELECT name into v_workspace_name FROM cat_workspace WHERE id = v_workspace_id;
	END IF;

	SELECT iseditable into v_iseditable FROM cat_workspace WHERE id = v_workspace_id;

	DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid;
	INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, concat('WORKSPACE MANAGER'));
	INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, '-----------------------------');

	IF v_action <> 'CHECK' THEN
		-- sector 0 (Undefined) is forced by gw_fct_setselectors; never snapshot or restore it
		DELETE FROM selector_sector WHERE sector_id = 0 AND cur_user = current_user;
	END IF;

	IF v_action = 'CREATE' OR v_action = 'CHECK' OR v_action = 'UPDATE' THEN

		IF v_action = 'CREATE' AND v_workspace_name IN (SELECT name FROM cat_workspace) THEN

			v_return_msg = 'Name already exists, please set a new one or delete existing workspace';
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3188", "function":"3078","parameters":null, "is_process":true}}$$);' INTO v_audit_result;

		ELSE
		--create configuration json for creating new workspace or saving the current settings as temporal in order to beeing able to reset them
		--save configuration from config_param_user
		SELECT jsonb_build_object('inp',i.inp_conf) INTO v_workspace_config FROM
		(SELECT json_object_agg(parameter, value) as inp_conf
		FROM config_param_user WHERE
		(parameter ilike 'inp_options%' OR parameter ilike 'inp_report%' or parameter ilike  'inp_times%') AND
		parameter NOT IN ('inp_options_buildup_supply', 'inp_options_advancedsettings','inp_options_debug','inp_options_vdefault')
		AND cur_user=current_user) i;
		--save configuration from config_param_user (parameters with json values)
		SELECT json_object_agg(parameter, value::JSON) as inp_conf INTO v_inp_json_config
		FROM config_param_user where parameter IN ('inp_options_buildup_supply', 'inp_options_advancedsettings','inp_options_debug','inp_options_vdefault')
		AND cur_user=current_user;

		v_workspace_config = gw_fct_json_object_set_key(v_workspace_config,'inp_json', v_inp_json_config);

		--save current configuration of selector
		SELECT json_agg(s.selector_conf) INTO v_selectors_config FROM (
		select jsonb_build_object('selector_expl', array_agg(expl_id))  as selector_conf
		FROM selector_expl where cur_user=current_user
		UNION
		select jsonb_build_object('selector_municipality', array_agg(muni_id)) as selector_conf
		FROM selector_municipality where cur_user=current_user
		UNION
		select jsonb_build_object('selector_sector', array_agg(sector_id)) as selector_conf
		FROM selector_sector where cur_user=current_user
		UNION
		select jsonb_build_object('selector_psector', array_agg(psector_id)) as selector_conf
		FROM selector_psector where cur_user=current_user
		UNION
		select jsonb_build_object('selector_inp_dscenario', array_agg(dscenario_id)) as selector_conf
		FROM selector_inp_dscenario where cur_user=current_user
		UNION
		select jsonb_build_object('selector_rpt_main', array_agg(result_id)) as selector_conf
		FROM selector_rpt_main where cur_user=current_user
		UNION
		select jsonb_build_object('selector_rpt_compare', array_agg(result_id)) as selector_conf
		FROM selector_rpt_compare where cur_user=current_user
		UNION
		select jsonb_build_object('selector_state', array_agg(state_id)) as selector_conf
		FROM selector_state where cur_user=current_user)s;

		--save current configuration of selectors, where there is more than 1 field of selector or the selector are diffent in ws and ud
		IF v_project_type = 'WS' THEN
			SELECT json_agg(s.selector_conf) INTO v_selectors_configcompound FROM (
				select jsonb_build_object('selector_rpt_main_tstep',array_agg(timestep)) as selector_conf
				FROM selector_rpt_main_tstep where cur_user=current_user
				UNION
				select jsonb_build_object('selector_rpt_compare_tstep',array_agg(timestep)) as selector_conf
				FROM selector_rpt_compare_tstep where cur_user=current_user
				UNION
				select jsonb_build_object('selector_date', json_agg(a.selector_value::json)) as selector_conf FROM (
				select json_build_object('from_date', from_date, 'to_date', to_date,'context', context)::text as selector_value
				FROM selector_date where cur_user=current_user) a
			) s;
		ELSIF v_project_type = 'UD' THEN
			SELECT json_agg(s.selector_conf) INTO v_selectors_configcompound  FROM (
				select jsonb_build_object('selector_rpt_main_tstep', json_agg(a.selector_value::json))as selector_conf FROM (
				select json_build_object('resultdate', resultdate, 'resulttime', resulttime)::text as selector_value
				FROM selector_rpt_main_tstep where cur_user=current_user)a
				UNION
				select jsonb_build_object('selector_rpt_compare_tstep', json_agg(a.selector_value::json))as selector_conf FROM (
				select json_build_object('resultdate', resultdate, 'resulttime', resulttime)::text as selector_value
				FROM selector_rpt_compare_tstep where cur_user=current_user)a
				UNION
				select jsonb_build_object('selector_date', json_agg(a.selector_value::json)) as selector_conf FROM (
				select json_build_object('from_date', from_date, 'to_date', to_date,'context', context)::text as selector_value
				FROM selector_date where cur_user=current_user) a
			) s;
		END IF;

		--join jsons of configuration
		v_selectors_config = v_selectors_config::jsonb||v_selectors_configcompound::jsonb;
		v_workspace_config = gw_fct_json_object_set_key(v_workspace_config,'selectors', v_selectors_config);

		IF v_action = 'CHECK' THEN
			DELETE FROM temp_table WHERE fid=v_fid AND cur_user=current_user;
			INSERT INTO temp_table (fid,addparam) VALUES (v_fid, v_workspace_config);
		END IF;

		INSERT INTO audit_check_data (fid, error_message) VALUES (v_fid, 'SELECTOR CONFIGURATION');
		INSERT INTO audit_check_data (fid, error_message) SELECT v_fid, value::text FROM json_array_elements(v_selectors_config) order by value;

		INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, '----------------------------------');
		INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, 'INP CONFIGURATION');
		INSERT INTO audit_check_data (fid, error_message) SELECT v_fid, replace(jsonb_build_object(parameter, value)::text,'\','')
		FROM config_param_user WHERE
		(parameter ilike 'inp_options%' OR parameter ilike 'inp_report%') AND cur_user=current_user order by parameter;

		END IF;
	END IF;

	IF v_action = 'DELETE' THEN
		--check if someone uses a workspace at the moment, if not, remove it
		IF v_workspace_id::text IN (SELECT value FROM config_param_user WHERE parameter='utils_workspace_current' AND cur_user != current_user) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3186", "function":"3078","parameters":null, "is_process":true}}$$);'INTO v_audit_result;
		ELSIF v_iseditable IS NOT TRUE THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3200", "function":"3078","parameters":null, "is_process":true}}$$);'INTO v_audit_result;
		ELSE
			IF (SELECT value FROM config_param_user WHERE parameter='utils_workspace_current' AND cur_user = current_user) = v_workspace_id::text THEN
				--remove workspace from config_param_user
				DELETE FROM config_param_user WHERE parameter = 'utils_workspace_current' AND cur_user = current_user;
			END IF;
			DELETE FROM cat_workspace WHERE id=v_workspace_id;
			v_return_msg = 'Workspace successfully deleted';
			v_return_level = 3;
		END IF;

	ELSIF v_action = 'CREATE' AND v_audit_result is null THEN
		--insert new workspace into catalog and set it as vdefault
		INSERT INTO cat_workspace (name, descript, config, private)
		VALUES (v_workspace_name, v_workspace_descript, v_workspace_config, v_workspace_private) RETURNING id INTO v_workspace_id;

		INSERT INTO config_param_user (parameter,value, cur_user)
		VALUES ('utils_workspace_current',v_workspace_id, current_user)
		ON CONFLICT (parameter, cur_user) DO UPDATE SET value=v_workspace_id;

		v_return_msg = 'Workspace successfully created';
		v_return_level = 3;

	ELSIF v_action = 'UPDATE' THEN
		IF v_iseditable IS NOT TRUE THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3200", "function":"3078","parameters":null, "is_process":true}}$$);'INTO v_audit_result;
		ELSE
			-- update configuration of selected workspace
			v_workspace_private = COALESCE(v_workspace_private, (SELECT private FROM cat_workspace WHERE id = v_workspace_id));
			UPDATE cat_workspace SET name = v_workspace_name, descript = v_workspace_descript, config = v_workspace_config, private = v_workspace_private WHERE id = v_workspace_id;
		END IF;

		v_return_msg = 'Workspace successfully updated';
		v_return_level = 3;

	ELSIF v_action = 'CURRENT' THEN

		--save workspace in config_param_user
		DELETE FROM config_param_user WHERE parameter = 'utils_workspace_current' AND cur_user = current_user;
		INSERT INTO config_param_user (parameter,value, cur_user)
		VALUES ('utils_workspace_current', v_workspace_id, current_user);

		--capture config of selected workspace
		SELECT config INTO v_workspace_config FROM cat_workspace WHERE id=v_workspace_id;

		v_config_values = json_extract_path_text(v_workspace_config,'selectors');

	ELSIF v_action = 'INFO' THEN
		--capture config of selected workspace
		SELECT config INTO v_workspace_config FROM cat_workspace WHERE id=v_workspace_id;

		v_config_values = json_extract_path_text(v_workspace_config,'selectors');

	ELSIF v_action = 'TOGGLE' THEN
		IF v_iseditable IS NOT TRUE THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3200", "function":"3078","parameters":null, "is_process":true}}$$);'INTO v_audit_result;
		ELSE
			UPDATE cat_workspace SET private = (NOT private) WHERE id=v_workspace_id;
		END IF;


	ELSIF v_action = 'CHECK' THEN

		-- code to check if user selection fits on some current workspace
		v_workspace_id = NULL;

		SELECT addparam INTO v_check_config FROM temp_table WHERE fid=v_fid AND cur_user=current_user;

		SELECT id INTO v_workspace_id FROM cat_workspace WHERE config::text = v_check_config::text LIMIT 1;

		INSERT INTO config_param_user (parameter, value, cur_user) VALUES ('utils_workspace_current', v_workspace_id, current_user)
		ON CONFLICT (parameter, cur_user) DO UPDATE SET value = v_workspace_id;

	END IF;

	IF v_action = 'CURRENT' OR  v_action = 'INFO'  THEN
		INSERT INTO audit_check_data (fid, error_message) VALUES (v_fid, 'SELECTOR CONFIGURATION');
		--set selector values
		FOR rec_selector IN SELECT * FROM json_array_elements(v_config_values) LOOP

			INSERT INTO audit_check_data (fid, error_message) VALUES (v_fid, rec_selector);

			v_selector_name = json_object_keys(rec_selector);

			IF v_action = 'CURRENT' THEN
				--remove values for selector
				EXECUTE 'DELETE FROM '||v_selector_name||' WHERE cur_user = current_user;';

				v_selector_value = json_extract_path_text(rec_selector,v_selector_name);

				IF v_selector_value IS NOT NULL THEN

					--insert values into selectors with more than 1 field
					IF v_project_type = 'UD' AND v_selector_name IN ('selector_rpt_compare_tstep', 'selector_rpt_main_tstep', 'selector_date')
					OR v_project_type = 'WS' AND v_selector_name IN ('selector_date') THEN

						FOR rec_selectorcomp IN SELECT * FROM json_array_elements(v_selector_value) LOOP

							SELECT string_agg(key,', ') as keys,  string_agg(quote_literal(value),', ') as values  INTO rec_selectorcolumn FROM (
							SELECT * from json_each_text(rec_selectorcomp::JSON))a;

							EXECUTE 'INSERT INTO '||v_selector_name||' ('||rec_selectorcolumn.keys||') 
							VALUES ('||rec_selectorcolumn.values||' );';

						END LOOP;

					--insert values into selectors with 1 field
					ELSIF v_selector_name = 'selector_sector' THEN

							EXECUTE 'SELECT string_agg(value::text, '', '')  FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer NOT IN (SELECT sector_id FROM sector WHERE active is true)'
							INTO v_deleted_sector;

							EXECUTE 'INSERT INTO selector_sector
							SELECT value::integer, current_user FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer <> 0 AND value::integer IN (SELECT sector_id FROM sector WHERE active is true);';

					ELSIF v_selector_name = 'selector_municipality' THEN

							EXECUTE 'SELECT string_agg(value::text, '', '')  FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer NOT IN (SELECT muni_id FROM v_municipality WHERE active is true)'
							INTO v_deleted_muni;

							EXECUTE 'INSERT INTO selector_municipality
							SELECT value::integer, current_user FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer IN (SELECT muni_id FROM v_municipality WHERE active is true);';

					ELSIF v_selector_name = 'selector_psector' THEN

							EXECUTE 'SELECT string_agg(value::text, '', '')  FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer NOT IN (SELECT psector_id FROM plan_psector WHERE active is true)'
							INTO v_deleted_psector;

							EXECUTE 'INSERT INTO selector_psector
							SELECT value::integer, current_user FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer IN (SELECT psector_id FROM plan_psector WHERE active is true);';

					ELSIF v_selector_name = 'selector_inp_dscenario' THEN

							EXECUTE 'SELECT string_agg(value::text, '', '') FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer NOT IN (SELECT dscenario_id FROM cat_dscenario WHERE active is true)'
							INTO v_deleted_dscenario;

							EXECUTE 'INSERT INTO selector_inp_dscenario
							SELECT value::integer, current_user FROM json_array_elements_text('''||v_selector_value||''') WHERE value::integer IN (SELECT dscenario_id FROM cat_dscenario WHERE active is true);';

					ELSIF v_selector_name in ('selector_rpt_main', 'selector_rpt_compare') THEN

							EXECUTE 'SELECT string_agg(value::text, '', '') FROM json_array_elements_text('''||v_selector_value||''') WHERE value::text 
							NOT IN (SELECT result_id FROM rpt_cat_result)'
							INTO v_deleted_result;

							EXECUTE 'INSERT INTO '||v_selector_name||
							' SELECT value::text, current_user FROM json_array_elements_text('''||v_selector_value||''') WHERE value::text IN 
							(SELECT result_id FROM rpt_cat_result);';
					ELSE

						IF v_selector_value IS NOT NULL THEN
							EXECUTE 'SELECT data_type FROM information_schema.columns where table_name = '||quote_literal(v_selector_name)||'
							AND table_schema='||quote_literal(v_schemaname)||' and column_name!=''cur_user'''
							INTO v_datatype;

							EXECUTE 'INSERT INTO '||v_selector_name||'
							SELECT value::'||v_datatype||', current_user FROM json_array_elements_text('''||v_selector_value||''')';
						END IF;
					END IF;
				END IF;
			END IF;
		END LOOP;


		INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, '----------------------------------');
		INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, null, 4, 'INP CONFIGURATION');

		--insert values into config_param_user
		FOR rec_inp IN SELECT 'inp' UNION SELECT 'inp_json' LOOP
			v_config_values = json_extract_path_text(v_workspace_config,rec_inp);

			INSERT INTO audit_check_data (fid, error_message) SELECT v_fid, replace(jsonb_build_object(key, value)::text,'\','') from json_each_text(v_config_values);

			IF v_action = 'CURRENT' THEN
				v_querytext = 'DELETE FROM config_param_user WHERE parameter IN (SELECT key from json_each_text('||quote_literal(v_config_values)||')) AND cur_user = current_user';
				EXECUTE v_querytext;

				v_querytext =  'INSERT INTO config_param_user (parameter, value, cur_user) 
				SELECT key, valor, current_user FROM 
				(SELECT key, value as valor from json_each_text('||quote_literal(v_config_values)||')) a';
				EXECUTE v_querytext;
			END IF;
		END LOOP;

		v_return_msg = 'Workspace successfully changed';
		v_return_level = 3;
	END IF;

	IF v_deleted_psector IS NOT NULL OR v_deleted_muni IS NOT NULL OR v_deleted_dscenario IS NOT NULL OR v_deleted_sector IS NOT NULL OR v_deleted_result IS NOT NULL THEN

		p_data = replace(p_data::text, 'CURRENT', 'UPDATE');
		PERFORM gw_fct_workspacemanager(p_data);

		IF v_deleted_psector IS NOT NULL THEN
			v_return_msg = concat(v_return_msg,'. Workspace recreated without psectors:',v_deleted_psector);
		END IF;
		IF v_deleted_muni IS NOT NULL THEN
			v_return_msg = concat(v_return_msg,'. Workspace recreated without muni:',v_deleted_muni);
		END IF;
		IF v_deleted_dscenario IS NOT NULL THEN
			v_return_msg = concat(v_return_msg,'. Workspace recreated without dscenarios:',v_deleted_dscenario,'.');
		END IF;
		IF v_deleted_sector IS NOT NULL THEN
			v_return_msg = concat(v_return_msg,'. Workspace recreated without sectors:',v_deleted_sector,'.');
		END IF;
		IF v_deleted_result IS NOT NULL THEN
			v_return_msg = concat(v_return_msg,'. Workspace recreated without result:',v_deleted_result,'.');
		END IF;
		v_return_level = 3;
	END IF;

	IF v_audit_result is null THEN
		v_return_status = 'Accepted';
		IF v_return_msg IS NULL THEN
			v_return_msg='Process executed successfully';
			v_return_level = 3;
		END IF;
	ELSE

        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_return_status;
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_return_level;
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_return_msg;

    END IF;

	IF (SELECT id FROM cat_workspace WHERE id=v_workspace_id) is null THEN
		v_result_info = '{}';
	ELSE
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result_info
		FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid order by  id asc) row;
	END IF;
	v_result_info = concat ('{"values":',v_result_info, '}');

	-- get uservalues
	v_uservalues = (SELECT to_json(array_agg(row_to_json(a))) FROM (SELECT parameter, value FROM config_param_user WHERE parameter IN ('plan_psector_current', 'utils_workspace_current')
	AND cur_user = current_user ORDER BY parameter)a);

	SELECT row_to_json (a) INTO v_geometry
		FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
		FROM (SELECT st_expand(st_collect(the_geom), 50.0) as the_geom FROM exploitation where expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user)
		UNION SELECT st_expand(st_collect(the_geom), 50.0) as the_geom FROM exploitation where expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user)) b) a;

	-- Control nulls
	v_version := COALESCE(v_version, '');
	v_result_info := COALESCE(v_result_info, '{}');
	v_uservalues := COALESCE(v_uservalues, '{}');
	v_geometry := COALESCE(v_geometry, '{}');

	-- Return
	RETURN gw_fct_json_create_return(('{"status":"'||v_return_status||'", "message":{"level":'||v_return_level||', "text":"'||v_return_msg||'"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "userValues":'||v_uservalues||', "info":'||v_result_info||', "geometry":'||v_geometry||
		       '}'||
	    '}}')::json, 3078, null, null, null);

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
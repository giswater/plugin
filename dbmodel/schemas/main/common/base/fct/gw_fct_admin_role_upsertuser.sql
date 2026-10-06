/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2780

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_role_upsertuser(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_role_upsertuser(p_data json)
  RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_admin_role_upsertuser($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "user_id": "john", "user_name":"John Smith", "password":"123", "role":"role_basic", "action":"insert", 
"manager_x_schema":{"SCHEMA_NAME":["1","3"],"SCHEMA_NAME":["2"],"SCHEMA_NAME_dev":[]}}}$$);

 
SELECT SCHEMA_NAME.gw_fct_admin_role_upsertuser($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "user_id": "john", "user_name":"John Smith", "password":"32", 
"role":"role_edit", "action":"update","manager_x_schema":{"SCHEMA_NAME":["2"],"SCHEMA_NAME":["3","1"],"SCHEMA_NAME_dev":[]}}}$$);

SELECT SCHEMA_NAME.gw_fct_admin_role_upsertuser($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "user_id": "john", "user_name":"John Smith", "password":"32", 
"role":"role_edit", "action":"delete","manager_x_schema":{"SCHEMA_NAME":["2"],"SCHEMA_NAME":["3","1"],"SCHEMA_NAME_dev":[]}}}$$);

-- fid: 207

*/

DECLARE

v_user_name text;
v_user_id text;
v_password text;
v_role text;
v_action text;
v_current_role text;
v_current_name text;
v_version text;
v_manager json;
v_manager_array text[];
v_expl_array integer[];
v_current_manager text[];
v_sys_expl_x_user boolean;
v_gw_schema_array text[];
v_manager_x_schema json;
v_manager_x_schema_array text[];
	
v_result_point json;
v_result_line json;
v_result_polygon json;
v_result json;
v_result_info json;	
v_return json;	
v_audit_result text;
v_level integer;
v_status text;
v_message text;
v_error_context text;
	
rec_schema text;
rec_expl integer;
rec_manager text;
rec record;

BEGIN

	SET search_path = 'SCHEMA_NAME' , public;

	SELECT giswater INTO  v_version FROM sys_version order by id desc limit 1;

	v_user_name = ((p_data ->>'data')::json->>'user_name')::text;
	v_user_id = lower(((p_data ->>'data')::json->>'user_id')::text);
	v_password = ((p_data ->>'data')::json->>'password')::text;
	v_role = ((p_data ->>'data')::json->>'role')::text;
	v_action = ((p_data ->>'data')::json->>'action')::text;
	v_manager = ((p_data->>'data')::json->>'manager_id')::text;
	v_manager_x_schema = ((p_data->>'data')::json->>'manager_x_schema')::text;
	
	--change schema list into array
	IF v_manager_x_schema IS NOT NULL AND v_manager_x_schema::text NOT IN ('', 'null') THEN
		v_gw_schema_array = (SELECT array_agg(a.key) result FROM json_each(v_manager_x_schema) a);
	END IF;
	IF v_gw_schema_array IS NULL THEN
		v_gw_schema_array := ARRAY['SCHEMA_NAME']::text[];
	END IF;
	IF v_user_name IS NULL OR v_user_name = '' THEN
		v_user_name := v_user_id;
	END IF;

	-- delete old values on result table
	DELETE FROM audit_check_data WHERE fid = 207 AND cur_user=current_user;
	
	-- Starting process
	INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (207, null, 4, 'ROLE MANAGEMENT');
	INSERT INTO audit_check_data (fid, result_id, criticity, error_message) VALUES (207, null, 4, '-------------------------------------------------------------');
    

	IF v_action = 'insert' THEN

		--create user in  a database, encrypt password and assign a role	
		IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_user_id) THEN
		
			EXECUTE 'CREATE USER '||quote_ident(v_user_id)||' WITH ENCRYPTED PASSWORD '||quote_literal(v_password)||';';

			INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
			VALUES (207, null, 1, concat('INFO: User ',v_user_id,' created in a database'));
	
		ELSE
			-- 3040 is AUDIT/log_level 0: writes audit_check_data, does not RAISE / abort
			EXECUTE format(
				$sql$SELECT gw_fct_getmessage(%L)$sql$,
				json_build_object(
					'client', json_build_object('device', 4, 'infoType', 1, 'lang', 'ES'),
					'feature', json_build_object(),
					'data', json_build_object(
						'message', '3040',
						'function', '2780',
						'fid', '207',
						'criticity', '1',
						'is_process', true,
						'parameters', json_build_object('v_user_id', v_user_id)
					)
				)::text
			);
		END IF;

		IF v_role IS NOT NULL AND v_role <> '' THEN
			EXECUTE format('GRANT %I TO %I', v_role, v_user_id);
		END IF;
		
		INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
		VALUES (207, null, 1, concat('INFO: Role ',v_role,' granted.'));
	
		FOREACH rec_schema IN ARRAY v_gw_schema_array LOOP
			--insert user into user catalog
			EXECUTE 'INSERT INTO '||quote_ident(rec_schema)||'.cat_users (id, name, sys_role, active)
			VALUES ('||quote_literal(v_user_id)||','||quote_literal(v_user_name)||','||quote_literal(v_role)||', true)
			ON CONFLICT (id) DO UPDATE SET
				name = EXCLUDED.name,
				sys_role = EXCLUDED.sys_role,
				active = true;';

			INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
			VALUES (207, null, 1, concat('INFO: User ',v_user_id,' inserted into cat_users of schema ',rec_schema,'.'));

			EXECUTE 'SELECT value::boolean  
			FROM '||rec_schema||'.config_param_system WHERE parameter = ''admin_exploitation_x_user'''
			INTO v_sys_expl_x_user;

			IF v_sys_expl_x_user THEN
				--get the defined manager for the schema
				v_manager=(v_manager_x_schema::json->>rec_schema)::text;
				--change manager list into array
				v_manager_array=(SELECT array_agg(value) AS list FROM json_array_elements_text(v_manager) );
				
				--insert user into related cat_manager and exploitation if managing exploitation for user is used (true)
				FOREACH rec_manager IN ARRAY v_manager_array LOOP
					EXECUTE 'UPDATE '||rec_schema||'.cat_manager 
					SET username = array_append(username,'''||v_user_id||''') WHERE id = '||rec_manager::integer||';';
				END LOOP;
				
				INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
				VALUES (207, null, 1, concat('INFO: User ',v_user_id,' inserted into cat_manager of schema ',rec_schema,'.'));

				--insert values for the new user into basic selectors
				EXECUTE 'INSERT INTO '||rec_schema||'.selector_state (state_id, cur_user) 
				VALUES (1,'''||v_user_id||''') ON CONFLICT (state_id,cur_user) DO NOTHING';

				EXECUTE 'INSERT INTO '||rec_schema||'.selector_expl (expl_id, cur_user) 
				SELECT expl_id, '''||v_user_id||''' FROM '||rec_schema||'.config_user_x_expl 
				WHERE username= '''||v_user_id||''' ON CONFLICT (expl_id,cur_user) DO NOTHING';

				
	
				INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
				VALUES (207, null, 1, concat('INFO: User ',v_user_id,' inserted into expl and state selectors of schema ',rec_schema,'.'));

			ELSE
				--insert values for the new user into basic selectors
				EXECUTE 'INSERT INTO '||rec_schema||'.selector_state (state_id, cur_user) 
				VALUES (1,'''||v_user_id||''') ON CONFLICT (state_id,cur_user) DO NOTHING';
	
				EXECUTE 'INSERT INTO '||rec_schema||'.selector_expl (expl_id, cur_user) 
				SELECT expl_id, '''||v_user_id||''' FROM '||rec_schema||'.exploitation 
				ON CONFLICT (expl_id,cur_user) DO NOTHING';

				EXECUTE 'INSERT INTO '||rec_schema||'.selector_sector (sector_id, cur_user) 
				SELECT sector_id, '''||v_user_id||''' FROM '||rec_schema||'.sector 
				ON CONFLICT (sector_id,cur_user) DO NOTHING';
	
				INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
				VALUES (207, null, 1, concat('INFO: User ',v_user_id,' inserted into expl and state selectors of schema ',rec_schema,'.'));

			END IF;

		END LOOP;
	ElSIF v_action = 'update' THEN

		--assign a new password if its not null
		IF v_password IS NOT NULL THEN

			EXECUTE 'ALTER USER '||v_user_id||' WITH ENCRYPTED PASSWORD '''||v_password||''';';

			INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
			VALUES (207, null, 1, concat('INFO: Password changed for user ',v_user_id,'.'));
		END IF;

		--check users current role
		EXECUTE 'SELECT rolname FROM pg_user u JOIN pg_auth_members m ON (m.member = u.usesysid) JOIN pg_roles r ON (r.oid = m.roleid)
		WHERE  u.usename = '''||v_user_id||''';'
		INTO v_current_role;

		--assign a new role if its different than the current one and change values in users catalog
		IF v_role != v_current_role AND v_role IS NOT NULL THEN

			EXECUTE ' REVOKE '||v_current_role||' FROM '||v_user_id||';';

			EXECUTE ' GRANT '||v_role||' TO '||v_user_id||';';

			INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
			VALUES (207, null, 1, concat('INFO: Role changed to ',v_role,'.'));


			FOREACH rec_schema IN ARRAY v_gw_schema_array LOOP

				--update cat_users with new role
				IF v_role != v_current_role AND v_role IS NOT NULL THEN

					EXECUTE 'UPDATE '||rec_schema||'.cat_users SET sys_role = '''||v_role||''' WHERE id = '''||v_user_id||''';';

				END IF;
				
			END LOOP;
		END IF;
		
		--check users current name and update it if it changed
		SELECT name INTO v_current_name FROM cat_users WHERE id = v_user_id;

		IF v_user_name != v_current_name THEN
			UPDATE cat_users SET name = v_user_name WHERE id=v_user_id;
		END IF;

		FOREACH rec_schema IN ARRAY v_gw_schema_array LOOP

			EXECUTE 'SELECT value::boolean 
			FROM '||rec_schema||'.config_param_system WHERE parameter = ''admin_exploitation_x_user'''
			INTO v_sys_expl_x_user;
			--if managing exploitation for user is used (true)
			IF v_sys_expl_x_user THEN

				--get the defined manager for the schema
				v_manager=(v_manager_x_schema::json->>rec_schema)::text;
				--change manager list into array
				v_manager_array=(SELECT array_agg(value) AS list FROM json_array_elements_text(v_manager) );
				
				--check to which manager user is assigned
				EXECUTE 'select array_agg(id) 
				from (select id, username as users from '||rec_schema||'.cat_manager) a where '''||v_user_id||''' =any(users)'
				INTO v_current_manager ;

				--change assignation to managers if it changed
				IF v_manager_array IS NULL OR (v_current_manager <> v_manager_array) 
				OR (v_current_manager is null and v_manager_array iS NOT NULL) THEN
					--remove user from current managers
					EXECUTE 'UPDATE '||rec_schema||'.cat_manager 
					SET username = array_remove(username,'''||v_user_id||''') WHERE '''||v_user_id||''' = any(username);';

					--insert user into manager if there are elements in manager array
					IF array_length(v_manager_array,1) > 0 THEN
						--add user to new managers
						FOREACH rec_manager IN ARRAY v_manager_array LOOP
							EXECUTE 'UPDATE '||rec_schema||'.cat_manager 
							SET username = array_append(username,'''||v_user_id||''') WHERE id = '||rec_manager::integer||';';

							INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
							VALUES (207, null, 1, concat('INFO: User ',v_user_id,' assigned to new managers.'));
						END LOOP;
					END IF;
				END IF;

			END IF;
		END LOOP;

	ElSIF v_action = 'delete' THEN

		FOREACH rec_schema IN ARRAY v_gw_schema_array LOOP
			--remove values for user from all the selectors and delete user
			FOR rec IN EXECUTE 'SELECT * FROM information_schema.tables 
			WHERE table_name ilike ''%selector%'' AND table_schema= '''||rec_schema||'''' LOOP

				EXECUTE 'DELETE FROM '||rec_schema||'.'||rec.table_name||' WHERE cur_user = '''||v_user_id||''';';
			END LOOP;

			INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
			VALUES (207, null, 1, concat('INFO: User ',v_user_id,' deleted from selectors.'));

			EXECUTE 'SELECT value::boolean  
			FROM '||rec_schema||'.config_param_system WHERE parameter = ''admin_exploitation_x_user'''
			INTO v_sys_expl_x_user;

			--if managing exploitation for user is used (true)
			IF v_sys_expl_x_user THEN
				--remove user from cat_manager
				EXECUTE 'UPDATE '||rec_schema||'.cat_manager 
				SET username = array_remove(username,'''||v_user_id||''') WHERE '''||v_user_id||''' = any(username);';

				INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
				VALUES (207, null, 1, concat('INFO: User ',v_user_id,' deleted from cat_manager.'));
			END IF;

			-- keep the catalog row so mincut/visit FKs stay valid
			EXECUTE 'UPDATE '||quote_ident(rec_schema)||'.cat_users SET active = false WHERE id = '||quote_literal(v_user_id)||';';
			
			INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
			VALUES (207, null, 1, concat('INFO: User ',v_user_id,' deactivated in cat_users.'));

		END LOOP;
		--drop user from the database
		EXECUTE 'DROP USER '||v_user_id||';';

		INSERT INTO audit_check_data (fid, result_id, criticity, error_message)
		VALUES (207, null, 1, concat('INFO: User ',v_user_id,' deleted from database.'));

	END IF;
	
	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() 
	AND fid = 207 order by criticity desc, id asc) row;

	IF v_audit_result is null THEN
        v_status = 'Accepted';
        v_level = 3;
        v_message = 'User management done succesfully';
    ELSE

        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status; 
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
        SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;

    END IF;

	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"values":',v_result, '}');
	v_result_point:=COALESCE(v_result_point,'{}');
	v_result_line:=COALESCE(v_result_line,'{}');
	v_result_polygon:=COALESCE(v_result_polygon,'{}');

		--return definition for v_audit_check_result
	 v_return = ('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
		     ',"body":{"form":{}'||
			     ',"data":{ "info":'||v_result_info||','||
					'"point":'||v_result_point||','||
					'"line":'||v_result_line||','||
					'"polygon":'||v_result_polygon||
			      '}}}')::json;

	RETURN v_return;

END;
 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

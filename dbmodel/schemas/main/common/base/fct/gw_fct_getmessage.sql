/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2820

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getmessage(p_data json)
  RETURNS json AS
$BODY$

/*
There are three types of messages: 'UI', 'AUDIT', and 'DEBUG' (see edit_typevalue table).
UI: Show message on UI
AUDIT: Save message on audit table
DEBUG: Show message on debug table (TODO)

Messages criticity:
0: Accepted -> NO exception
1: Warning -> NO exception
2: Error -> Execption
*/		


/* EXAMPLES
SELECT SCHEMA_NAME.gw_fct_getmessage($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{},
"data":{"message":"2", "function":"1312","parameters":{"feature_id": 1, "expl_id": 2}, "variables":"value", "is_process":true}}$$)
*/

DECLARE

rec_function record;
rec_cat_error record;
rec_cat_label record;

v_return_text text;
v_level integer;
v_error_context text;
v_result_info json;
v_projectype text;
v_version text;
v_status text;
v_parameters json;
v_message_id integer;
v_function_id integer;
v_variables text;
v_debug Boolean;
v_isprocess boolean = false;
v_fid text;
v_result_id text;
v_temp_table text = '';
v_criticity integer;
_key text;
_value text;
v_label_id integer;
v_header_separator_id integer = 2030; -- there are 30 dashes
v_is_header boolean = false;
v_function_alias text;
v_querytext text;
v_separator text;
v_prefix_id integer;
v_fcount integer;
v_table_id text;
v_column_id text;
v_cur_user text;
v_ui_lang text;
v_ml_pref jsonb;
v_ml_project_type text;
v_i18n_ms text;
v_i18n_ht text;
v_i18n_ds text;
v_schema text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	-- Get debug variable
	SELECT value::boolean INTO v_debug FROM config_param_system WHERE parameter='admin_message_debug';

	-- Get parameters from input json
	v_message_id = lower(p_data->'data'->>'message');
	v_function_id = lower(p_data->'data'->>'function');
	v_parameters = p_data->'data'->>'parameters';
	v_variables = lower(p_data->'data'->>'variables');
	v_isprocess = lower(p_data->'data'->>'is_process');

	v_fid = lower(p_data->'data'->>'fid');
	v_result_id = p_data->'data'->>'result_id';
	v_temp_table = p_data->'data'->>'tempTable';
	v_criticity = p_data->'data'->>'criticity';
	v_is_header = p_data->'data'->>'is_header';
	v_label_id = p_data->'data'->>'label_id';
	v_prefix_id = p_data->'data'->>'prefix_id';
	v_fcount = p_data->'data'->>'fcount';
	v_header_separator_id = p_data->'data'->>'separator_id';
	v_table_id = p_data->'data'->>'table_id';
	v_column_id = p_data->'data'->>'column_id';
	v_cur_user = p_data->'data'->>'cur_user';

	SELECT giswater, project_type INTO v_version, v_projectype FROM sys_version ORDER BY id DESC LIMIT 1;


	IF v_is_header THEN

		IF v_label_id IS NOT NULL THEN
			SELECT * INTO rec_cat_label FROM sys_label  WHERE sys_label.id=v_label_id;
			FOR _key, _value IN SELECT * FROM json_each_text(v_parameters)
			LOOP
				rec_cat_label.idval = concat(rec_cat_label.idval, ' ', _value);
			END LOOP;
		ELSE
			-- get label from sys_function, upper()
			-- get separator from sys_label

			SELECT function_alias INTO v_function_alias FROM sys_function WHERE id=v_function_id;

			FOR _key, _value IN
				SELECT * FROM json_each_text(v_parameters)
			LOOP
				v_function_alias = concat(v_function_alias, ' ', _value);
			END LOOP;
		END IF;



		IF rec_cat_label IS NULL THEN
			IF v_cur_user IS NOT NULL THEN
				v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id, cur_user)
				VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(COALESCE(v_function_alias, ''))||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||', '||v_cur_user||');';
			ELSE
				v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id)
				VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(COALESCE(v_function_alias, ''))||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||');';
			END IF;
		ELSE
			IF v_cur_user IS NOT NULL THEN
				v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id, cur_user)
				VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(rec_cat_label.idval)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||', '||v_cur_user||');';
			ELSE
				v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id)
				VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(rec_cat_label.idval)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||');';
			END IF;
		END IF;

		EXECUTE v_querytext;

		SELECT idval INTO v_separator FROM sys_label WHERE id = COALESCE(v_header_separator_id, 2030);
		IF v_cur_user IS NOT NULL THEN
			v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id, cur_user)
			VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(v_separator)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||', '||v_cur_user||');';
		ELSE
			v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id)
			VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(v_separator)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||');';
		END IF;

		EXECUTE v_querytext;

		RETURN ('{"status":"Accepted", "message":{"level":3, "text":"Message passed successfully"}, "version":"'||v_version||'"'||
       ',"body":{"form":{}'||
           ',"data":{"info":"" }}'||
            '}')::json;
    END IF;

	IF v_header_separator_id IS NOT NULL THEN
        SELECT idval INTO v_separator FROM sys_label WHERE id = COALESCE(v_header_separator_id, 2030);

		IF v_cur_user IS NOT NULL THEN
			v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id, cur_user)
			VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(v_separator)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||', '||v_cur_user||');';
		ELSE
			v_querytext := 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id)
        	VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||quote_nullable(v_criticity)||','||quote_literal(v_separator)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||');';
		END IF;

        EXECUTE v_querytext;

		RETURN ('{"status":"Accepted", "message":{"level":3, "text":"Message passed successfully"}, "version":"'||v_version||'"'||
       ',"body":{"form":{}'||
           ',"data":{"info":"" }}'||
            '}')::json;
    END IF;

	-- get flow parameters
	SELECT * INTO rec_cat_error FROM sys_message WHERE sys_message.id=v_message_id;

	IF NOT FOUND THEN
		RETURN json_build_object('status', 'Failed', 'message', json_build_object('level', 1, 'text', 'The process has returned an error code, but this error code is not present on the sys_message table. Please contact with your system administrator in order to update your sys_message table'))::json;
	END IF;

	-- Apply multilang UI translations for sys_message
	v_schema := 'SCHEMA_NAME';
	v_ml_pref := NULL;
	v_ui_lang := NULL;
	v_ml_project_type := NULL;
	IF to_regnamespace('multilang') IS NOT NULL THEN
		v_ml_pref := multilang.gw_fct_get_multilang_language('SCHEMA_NAME');
		v_ui_lang := v_ml_pref->>'lang';
		v_ml_project_type := v_ml_pref->>'project_type';
	END IF;
	IF v_ui_lang IS NOT NULL THEN
		SELECT i.ms, i.ht INTO v_i18n_ms, v_i18n_ht
		FROM multilang.sys_message i
		WHERE i.project_type = v_ml_project_type
		  AND i.context = 'sys_message'
		  AND i.source = v_message_id::text
		  AND i.lang = v_ui_lang
		LIMIT 1;
		IF v_i18n_ms IS NOT NULL THEN
			rec_cat_error.error_message = v_i18n_ms;
		END IF;
		IF v_i18n_ht IS NOT NULL THEN
			rec_cat_error.hint_message = v_i18n_ht;
		END IF;
	END IF;

	IF rec_cat_error.message_type != 'UI' OR rec_cat_error.message_type IS NULL THEN
		SELECT * INTO rec_function
		FROM sys_function WHERE sys_function.id=v_function_id;

		IF rec_function IS NULL THEN
			RETURN json_build_object('status', 'Failed', 'message', json_build_object('level', 1, 'text', 'Function does not exist'))::json;
		END IF;

		IF v_ui_lang IS NOT NULL THEN
			SELECT i.ds INTO v_i18n_ds
			FROM multilang.sys_function i
			WHERE i.project_type = v_ml_project_type
			  AND i.context = 'sys_function'
			  AND i.source = v_function_id::text
			  AND i.lang = v_ui_lang
			LIMIT 1;
			IF v_i18n_ds IS NOT NULL THEN
				rec_function.descript = v_i18n_ds;
			END IF;
		END IF;
	END IF;

	-- compare parameters in message with parameters recieved
	IF rec_cat_error.error_message IS NOT NULL THEN
		IF (select (select array(SELECT key FROM json_each_text(v_parameters) order by key)) =
		(select array(select split_part(token, '%', 2) as msg_parameters
		from string_to_table(rec_cat_error.error_message, ' ') token where token like '%\%%\%%'
		order by msg_parameters))) THEN
			-- replace parameter names in message with parameter values recieved
			FOR _key, _value IN
				SELECT * FROM json_each_text(v_parameters)
			LOOP
				rec_cat_error.error_message = replace(rec_cat_error.error_message, concat('%', _key, '%'), _value);
			END LOOP;
		ELSE
			-- return error parameters aren't the same
			--RAISE EXCEPTION '%', upper(rec_cat_error.error_message);
		END IF;
	END IF;

	-- add specified headers
	IF v_prefix_id IS NOT NULL THEN
		-- select label record
		SELECT * INTO rec_cat_label FROM sys_label  WHERE sys_label.id=v_prefix_id;
		IF rec_cat_label IS NULL THEN
			RETURN json_build_object('status', 'Failed', 'message', json_build_object('level', 1, 'text', 'Header does not exist'))::json;
		END IF;
		IF rec_cat_error.message_type = 'UI' OR rec_cat_error.message_type IS NULL THEN
			-- add header to message if message type is UI
			rec_cat_error.error_message = concat(rec_cat_label.idval, ': ', rec_cat_error.error_message);
		ELSIF rec_cat_error.message_type = 'AUDIT' THEN
			-- add header to message if message type is AUDIT
			IF v_result_id IS NOT NULL THEN
				rec_cat_error.error_message = concat(rec_cat_label.idval, ' ', COALESCE(v_result_id, ''), ': ', rec_cat_error.error_message);
			ELSE
				rec_cat_error.error_message = concat(rec_cat_label.idval, ' ', COALESCE(v_fid, ''), ': ', rec_cat_error.error_message);
			END IF;
		END IF;
	END IF;

	IF rec_cat_error.message_type = 'UI' OR rec_cat_error.message_type IS NULL THEN
		-- message process
		IF v_isprocess THEN
			-- log_level of type 'WARNING' (mostly applied to functions)
			IF rec_cat_error.log_level = 1 THEN
				SELECT * INTO rec_function
				FROM sys_function WHERE sys_function.id=v_function_id;

				IF v_debug THEN
					SELECT  concat('Function: ',function_name,' - ',upper(rec_cat_error.error_message),'. HINT: ', upper(rec_cat_error.hint_message),'.')  INTO v_return_text
					FROM sys_function WHERE sys_function.id=v_function_id;
				END IF;

				RAISE 'Function: [%] - %. HINT: % - %', rec_function.function_name, upper(rec_cat_error.error_message), upper(rec_cat_error.hint_message), v_variables
				USING ERRCODE  = concat('GW00', rec_cat_error.log_level);

			-- log_level of type 'ERROR' (mostly applied to trigger functions)
			ELSIF rec_cat_error.log_level = 2 THEN
				SELECT * INTO rec_function
				FROM sys_function WHERE sys_function.id=v_function_id;

				RAISE 'Function: [%] - %. HINT: % - %', rec_function.function_name, upper(rec_cat_error.error_message), upper(rec_cat_error.hint_message), v_variables
				USING ERRCODE  = concat('GW00', rec_cat_error.log_level);
			ELSIF rec_cat_error.log_level = 3 THEN
				IF v_debug THEN
					SELECT  concat('Function: ',function_name,' - ',upper(rec_cat_error.error_message),'. HINT: ', upper(rec_cat_error.hint_message),'.')  INTO v_return_text
					FROM sys_function WHERE sys_function.id=v_function_id;
				ELSE
					SELECT  upper(rec_cat_error.error_message)  INTO v_return_text
					FROM sys_function WHERE sys_function.id=v_function_id;
				END IF;

				v_level = 2;
				v_status = 'Failed';

			-- log_level Accepted just to show message when fct is called from another function
			ELSIF rec_cat_error.log_level = 0 THEN

				SELECT  upper(rec_cat_error.error_message)  INTO v_return_text
				FROM sys_function WHERE sys_function.id=v_function_id;

				v_level = 3;
				v_status = 'Accepted';

				SELECT jsonb_build_object
				('level', v_level,
				'status', v_status,
				'message', v_return_text,
				'text', v_return_text) INTO v_result_info;

				RETURN v_result_info::json;

			END IF;

		ELSE

			-- log_level of type 'WARNING' (mostly applied to functions)
			IF rec_cat_error.log_level = 1 THEN

				SELECT * INTO rec_function
				FROM sys_function WHERE sys_function.id=v_function_id;
				RAISE WARNING 'Function: [%] - %. HINT: %', rec_function.function_name, upper(rec_cat_error.error_message), upper(rec_cat_error.hint_message) ;

			-- log_level of type 'ERROR' (mostly applied to trigger functions)
			ELSIF rec_cat_error.log_level = 2 THEN
				SELECT * INTO rec_function
				FROM sys_function WHERE sys_function.id=v_function_id;

				IF v_variables IS NOT NULL and v_variables != '<NULL>' THEN
					RAISE EXCEPTION 'Function: [%] - %. HINT: % - %', rec_function.function_name, upper(rec_cat_error.error_message), upper(rec_cat_error.hint_message), v_variables ;
				ELSE
					RAISE EXCEPTION 'Function: [%] - %. HINT: %', rec_function.function_name, upper(rec_cat_error.error_message), upper(rec_cat_error.hint_message);
				END IF;
			ELSIF rec_cat_error.log_level = 3 THEN

				SELECT * INTO rec_function
				FROM sys_function WHERE sys_function.id=v_function_id;

				IF v_debug THEN
					SELECT  concat('Function: ',function_name,' - ',upper(rec_cat_error.error_message),'. HINT: ', upper(rec_cat_error.hint_message),'.')  INTO v_return_text
					FROM sys_function WHERE sys_function.id=v_function_id;
				ELSE
					SELECT  upper(rec_cat_error.error_message)  INTO v_return_text
					FROM sys_function WHERE sys_function.id=v_function_id;
				END IF;
				v_level = 2;
				v_status = 'Error';

			ELSIF rec_cat_error.log_level = 0 THEN

				IF v_debug THEN
					SELECT  concat('Function: ',function_name,' - ',upper(rec_cat_error.error_message),'. HINT: ', upper(rec_cat_error.hint_message),'.')  INTO v_return_text
					FROM sys_function WHERE sys_function.id=v_function_id;
				ELSE
					SELECT  upper(rec_cat_error.error_message)  INTO v_return_text
					FROM sys_function WHERE sys_function.id=v_function_id;
				END IF;
				v_level = 3;
				v_status = 'Accepted';
			END IF;
		END IF;

	ELSIF rec_cat_error.message_type = 'AUDIT' THEN
        IF rec_cat_error.log_level = 0 AND v_criticity IS NOT NULL THEN
            rec_cat_error.log_level = v_criticity;
        END IF;

		IF v_cur_user IS NOT NULL THEN
			v_querytext = 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id, cur_user)
			VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||rec_cat_error.log_level||','||quote_literal(rec_cat_error.error_message)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||', '||v_cur_user||');';
		ELSE
			v_querytext = 'INSERT INTO '||COALESCE(v_temp_table, '')||'audit_check_data (fid, result_id, criticity, error_message, fcount, table_id, column_id)
			VALUES ('||v_fid||','||quote_nullable(v_result_id)||','||rec_cat_error.log_level||','||quote_literal(rec_cat_error.error_message)||', '||quote_nullable(v_fcount)||', '||quote_nullable(v_table_id)||', '||quote_nullable(v_column_id)||');';
		END IF;

        EXECUTE v_querytext;

    ELSIF rec_cat_error.message_type = 'DEBUG' THEN

	END IF;

	SELECT jsonb_build_object
	('level', v_level,
	'status', v_status,
	'message', v_return_text,
	'text', v_return_text) INTO v_result_info;

	-- Control nulls
	v_result_info := COALESCE(v_result_info, '{}');

	-- Return
	RETURN ('{"status":"Accepted", "message":{"level":3, "text":"Message passed successfully"}, "version":"'||v_version||'"'||
       ',"body":{"form":{}'||
           ',"data":{"info":'||v_result_info||' }}'||
            '}')::json;

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
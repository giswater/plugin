/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3242

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setinitproject (p_data json)
  RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_setinitproject($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{}}$$);

-- fid:

*/

DECLARE

v_schemaname text;
v_rectable record;
v_error_context text;
v_errortext text;
v_qgis_init_guide_map boolean;
v_user text;
v_isaudit boolean;
v_rol_exists bool;
v_project_type text;
v_version text;
v_epsg integer;
v_message text;
v_return json;
v_add_schema text;
v_sectorisexplismuni boolean;
v_has_usage boolean;

BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	-- get system parameters
	SELECT project_type, giswater, epsg INTO v_project_type, v_version, v_epsg FROM sys_version order by id desc limit 1;
	v_sectorisexplismuni = (SELECT value::boolean FROM config_param_system WHERE parameter = 'basic_selector_sectorisexplismuni');


	-- Get input parameters
   	v_user := (p_data ->> 'client')::json->> 'cur_user';
	v_isaudit := (p_data ->> 'data')::json->> 'isAudit';

	if v_user is null then
		v_user = current_user;
	end if;

	-- check if role name exists
	IF v_user IS NOT NULL THEN
		SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_user) INTO v_rol_exists;
		IF NOT v_rol_exists THEN
			v_message := concat('The user ''', v_user, ''' does not exist in the database. Please contact an administrator.');
			RETURN ('{"status":"Failed", "message":{"level":1, "text":"'|| v_message ||'"}, "version":"'||v_version||'"'||'}')::json;
		END IF;
	END IF;

	-- get user parameters
	SELECT value INTO v_qgis_init_guide_map FROM config_param_user where parameter='qgis_init_guide_map' AND cur_user=current_user;

	-- profilactic null control
	IF v_qgis_init_guide_map IS NULL THEN v_qgis_init_guide_map = FALSE; END IF;

	-- set mandatory values of config_param_user in case of not exists (for new users or for updates)
	FOR v_rectable IN SELECT * FROM sys_param_user WHERE ismandatory IS TRUE AND sys_role IN (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member'))
	LOOP
		IF v_rectable.id NOT IN (SELECT parameter FROM config_param_user WHERE cur_user=current_user) THEN
			INSERT INTO config_param_user (parameter, value, cur_user)
			SELECT sys_param_user.id, vdefault, current_user FROM sys_param_user WHERE sys_param_user.id = v_rectable.id;

			v_errortext=concat('Set value for new variable in config param user: ',v_rectable.id,'.');

			INSERT INTO audit_check_data (fid,  criticity, error_message) VALUES (101, 4, v_errortext);
		END IF;
	END LOOP;

	-- delete on config_param_user fron updated values on sys_param_user
	DELETE FROM config_param_user WHERE parameter NOT IN (SELECT id FROM sys_param_user) AND cur_user = current_user;

	-- CM extra: if cm schema exists, initialize its user params similarly and ensure edit_disable_topocontrol default
	IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cm') THEN
		-- Require USAGE on cm; avoid error popups
		SELECT has_schema_privilege(current_user, 'cm', 'USAGE') INTO v_has_usage;
		IF v_has_usage THEN
			-- ensure mandatory cm.sys_param_user values exist in cm.config_param_user for current user
			FOR v_rectable IN SELECT * FROM cm.sys_param_user WHERE ismandatory IS TRUE AND sys_role IN (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member'))
			LOOP
				IF v_rectable.id NOT IN (SELECT parameter FROM cm.config_param_user WHERE cur_user = current_user) THEN
					INSERT INTO cm.config_param_user (parameter, value, cur_user)
					SELECT cm.sys_param_user.id, vdefault, current_user FROM cm.sys_param_user WHERE cm.sys_param_user.id = v_rectable.id;

					v_errortext = concat('Set value for new variable in cm.config_param_user: ', v_rectable.id, '.');
					INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (101, 4, v_errortext);
				END IF;
			END LOOP;

			-- cleanup obsolete cm.config_param_user values not present in cm.sys_param_user
			DELETE FROM cm.config_param_user WHERE parameter NOT IN (SELECT id FROM cm.sys_param_user) AND cur_user = current_user;

			-- guarantee presence of the toggle used by CM topocontrol
			INSERT INTO cm.config_param_user (parameter, value, cur_user)
			VALUES ('edit_disable_topocontrol', 'false', current_user)
			ON CONFLICT (parameter, cur_user) DO NOTHING;
		END IF;
	END IF;

	-- Force exploitation selector
	IF (v_isaudit IS DISTINCT FROM TRUE) AND (v_qgis_init_guide_map OR v_sectorisexplismuni) THEN -- v_sectorisexplismuni IS used ALSO here NOT ONLY IN selectors
		DELETE FROM selector_expl WHERE cur_user = current_user;
		DELETE FROM selector_sector WHERE cur_user = current_user;
		DELETE FROM selector_municipality WHERE cur_user = current_user;
		DELETE FROM selector_macroexpl WHERE cur_user = current_user;
		DELETE FROM selector_macrosector WHERE cur_user = current_user;
		DELETE FROM selector_network WHERE cur_user = current_user;
		DELETE FROM selector_psector WHERE cur_user = current_user;
		DELETE FROM selector_dscenario WHERE cur_user = current_user;

		-- looking for additional schema
		IF v_add_schema IS NOT NULL AND v_add_schema != v_schemaname THEN
			EXECUTE 'SET search_path = '||v_add_schema||', public';
			DELETE FROM selector_expl WHERE cur_user = current_user;
			DELETE FROM selector_sector WHERE cur_user = current_user;
			DELETE FROM selector_municipality WHERE cur_user = current_user;
			DELETE FROM selector_macroexpl WHERE cur_user = current_user;
			DELETE FROM selector_macrosector WHERE cur_user = current_user;
			DELETE FROM selector_network WHERE cur_user = current_user;
			DELETE FROM selector_psector WHERE cur_user = current_user;
			DELETE FROM selector_dscenario WHERE cur_user = current_user;

			SET search_path = 'SCHEMA_NAME', public;
		END IF;
	ELSE
		-- Force exploitation selector in case of null values
		IF (SELECT count(*) FROM selector_expl WHERE cur_user=current_user) < 1 THEN
			IF EXISTS (SELECT 1 FROM exploitation WHERE active IS NOT FALSE AND expl_id > 0) THEN
				EXECUTE format(
					$$SELECT gw_fct_setselectors('{
						"client":{
							"cur_user":"', v_user, '"
						},
						"data":{
							"selectorType":"selector_basic",
							"tabName":"tab_exploitation",
							"checkAll":"True",
							"addSchema":"', v_add_schema, '"
						}
					}')$$
				);
			END IF;
			IF EXISTS (SELECT 1 FROM selector_expl WHERE cur_user=current_user) THEN
				v_errortext = 'Set all active exploitations as visible exploitations for user';
				INSERT INTO audit_check_data (fid,  criticity, error_message) VALUES (101, 4, v_errortext);
			ELSE
				v_errortext=concat('No exploitation found for user ', current_user);
				INSERT INTO audit_check_data (fid,  criticity, error_message) VALUES (101, 4, v_errortext);
			END IF;
		END IF;
	END IF;

	-- Force network selector in case of null values
	IF (SELECT count(*) FROM selector_network WHERE cur_user=current_user) < 1 THEN
	  	INSERT INTO selector_network (network_id, cur_user) VALUES (1, current_user);
	END IF;

	-- Force state selector in case of null values
	IF (SELECT count(*) FROM selector_state WHERE cur_user=current_user) < 1 THEN
	  	INSERT INTO selector_state (state_id, cur_user) VALUES (1, current_user);
		v_errortext=concat('Set feature state = 1 for user');
		INSERT INTO audit_check_data (fid,  criticity, error_message) VALUES (101, 4, v_errortext);
	END IF;

	-- Force muni selector for 0 values
	INSERT INTO selector_municipality VALUES (0, current_user) ON CONFLICT (muni_id, cur_user) DO NOTHING;

	--Force hydrology_selector when null values from user
	IF v_project_type='UD' THEN
		IF (SELECT hydrology_id FROM cat_hydrology LIMIT 1) IS NOT NULL THEN
			INSERT INTO config_param_user
			SELECT 'inp_options_hydrology_current', hydrology_id, current_user FROM cat_hydrology LIMIT 1
			ON CONFLICT (parameter, cur_user) DO NOTHING;
			UPDATE config_param_user SET value = hydrology_id FROM (SELECT hydrology_id FROM cat_hydrology LIMIT 1) a
			WHERE parameter =  'inp_options_hydrology_current' and value is null;
		END IF;
	END IF;

	-- Add user to cat_users if not exists
	INSERT INTO cat_users (id,name,active) values (v_user, v_user, true) ON CONFLICT (id) DO NOTHING;

	-- Disable psector mode
	INSERT INTO config_param_user ("parameter", value, cur_user) VALUES('plan_psector_current', NULL, current_user)
	ON CONFLICT("parameter", cur_user) DO NOTHING;
	UPDATE config_param_user SET value = NULL WHERE "parameter" = 'plan_psector_current' AND cur_user = current_user;

    -- Control null
	v_message := COALESCE(v_message, '{}');
	v_return := COALESCE(v_return,'{}');

	--  Return
    RETURN ('{"status":"Accepted", "message":{"level":1, "text":"'|| v_message ||'"}, "version":"'||v_version||'"'||'}')::json;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
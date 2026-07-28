/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2870

-- DROP FUNCTION SCHEMA_NAME.gw_fct_setselectors(json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setselectors(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*example
SELECT SCHEMA_NAME.gw_fct_setselectors($${"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"None", "tabName":"tab_exploitation", "forceParent":"True", "checkAll":"True", "addSchema":"None"}}$$);
SELECT SCHEMA_NAME.gw_fct_setselectors($${"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"explfrommuni", "id":32, "value":true, "isAlone":true, "addSchema":"ud"}}$$)::text

SELECT SCHEMA_NAME.gw_fct_setselectors($${"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_psector", "id":"1", "ids":"[1,2]", "isAlone":"True", "value":"True", "addSchema":"None", "useAtlas":true}}$$);

SELECT SCHEMA_NAME.gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_mincut", "tabName":"tab_mincut", "checkAll":"True", "addSchema":"NULL"}}$$);

SELECT SCHEMA_NAME.gw_fct_setselectors($${"client":{"device":4, "lang":"", "epsg":25830}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
"selectorType":"explfrommuni", "id":527, "value":true, "isAlone":true, "addSchema":"ud"}

fid: 397

select * from SCHEMA_NAME.anl_arc

*/

DECLARE

-- input variables
v_tab_name text;
v_selector_type text;
v_id text;
v_ids text;
v_value text;
v_is_alone boolean;
v_check_all boolean;
v_add_schema text;
v_use_atlas boolean;
v_disable_parent boolean;
v_cur_user text;
v_tiled boolean;


-- aux variables
v_prev_cur_user text;

v_parameter_selector json;
v_tablename text;
v_columnname text;
v_table text;
v_table_id text;
v_sector_is_expl_is_muni boolean;

v_name text;
v_user_values json;
v_action text = null;
v_sector integer;
v_expand float=50;
v_expl_x_user boolean;
v_project_type text;
v_cur_psector integer;

v_expl integer;

-- message variables
v_error_context text;
v_message json = json_build_object('level', 1, 'text', 'Process done successfully');
v_count integer = 0;
v_count_aux integer = 0;
-- v_fid integer = 397;
v_result json;
v_schema_name text;
v_return json;
v_geometry text;
v_querytext text;



BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;
	v_schema_name = 'SCHEMA_NAME';

	-- get system variables
	v_expl_x_user = (SELECT value FROM config_param_system WHERE parameter = 'admin_exploitation_x_user');
	v_project_type = (SELECT project_type FROM sys_version LIMIT 1);

	-- Get input parameters:
	v_tab_name := p_data->'data'->>'tabName';
	v_selector_type := p_data->'data'->>'selectorType';
	v_id := p_data->'data'->>'id';
	v_ids := p_data->'data'->>'ids';
	v_value := p_data->'data'->>'value';
	v_is_alone := p_data->'data'->>'isAlone';
	v_check_all := p_data->'data'->>'checkAll';
	v_add_schema := p_data->'data'->>'addSchema';
	v_use_atlas := p_data->'data'->>'useAtlas';
	v_disable_parent := p_data->'data'->>'disableParent';
	v_cur_user := p_data->'client'->>'cur_user';
	v_tiled := (p_data->'client'->>'tiled')::boolean;

	v_prev_cur_user = current_user;
	IF v_cur_user IS NOT NULL THEN
		EXECUTE 'SET ROLE "'||v_cur_user||'"';
	END IF;

	-- profilactic control
	IF lower(v_selector_type) = 'none' OR v_selector_type = '' OR lower(v_selector_type) ='null' THEN v_selector_type = 'selector_basic'; END IF;
	IF v_use_atlas IS null then v_use_atlas = false; END IF;

	-- profilactic control of schema name
	IF lower(v_add_schema) = 'none' OR v_add_schema = '' OR lower(v_add_schema) ='null' OR v_add_schema is null OR v_add_schema='NULL'
		THEN v_add_schema = null;
	ELSE
		IF (select schemaname from pg_tables WHERE schemaname = v_add_schema LIMIT 1) IS NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	            "data":{"message":"3132", "function":"2870","parameters":null, "is_process":true}}$$)';
		-- todo: send message to response
		END IF;
	END IF;

	-- control null tabname when layout of municipalities appear
	IF v_tab_name IS NULL AND v_selector_type = 'explfrommuni' THEN
		v_tab_name = 'tab_municipality';
	END IF;

	-- Get system parameters
	v_parameter_selector = (SELECT value::json FROM config_param_system WHERE parameter = concat('basic_selector_', v_tab_name));
	v_tablename = v_parameter_selector->>'selector';
	v_columnname = v_parameter_selector->>'selector_id';
	v_table = v_parameter_selector->>'table';
	v_table_id = v_parameter_selector->>'table_id';
	v_sector_is_expl_is_muni = (SELECT value::boolean FROM config_param_system WHERE parameter = 'basic_selector_sectorisexplismuni');

	IF v_sector_is_expl_is_muni IS NULL THEN v_sector_is_expl_is_muni = FALSE; END IF;
	
	-- setting schema add
	IF v_tab_name like '%add%' AND v_add_schema IS NOT NULL THEN
		v_tablename = concat(v_add_schema,'.',v_tablename);
		v_table = concat(v_add_schema,'.',v_table);
	END IF;

	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"project_type":"'||v_project_type||'", "action":"DROP", "group":"SELECTOR"}}}$$)';
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"project_type":"'||v_project_type||'", "action":"CREATE", "group":"SELECTOR"}}}$$)';

	IF v_expl_x_user is false THEN
		-- create auxiliar table temp_aux_sector_muni
		CREATE TEMP TABLE temp_muni_sector_expl AS
		SELECT DISTINCT muni_id, sector_id, expl_id FROM node WHERE state > 0
		UNION
		SELECT * FROM (SELECT DISTINCT muni_id, sector_id, unnest(expl_visibility) AS expl_id FROM node WHERE state > 0)
		WHERE expl_id IS NOT NULL;

		INSERT INTO temp_exploitation (expl_id, code, name, descript, macroexpl_id, active)
		SELECT expl_id, code, name, descript, macroexpl_id, active 
		FROM exploitation 
		WHERE active 
		AND expl_id > 0 
		ORDER BY expl_id;

		INSERT INTO temp_macroexploitation (macroexpl_id, code, name, descript, active)
		SELECT macroexpl_id, code, name, descript, active 
		FROM macroexploitation 
		WHERE active 
		AND macroexpl_id > 0 
		ORDER BY macroexpl_id;

		INSERT INTO temp_sector (sector_id, code, name, descript, expl_id, muni_id, macrosector_id, parent_id, active)
		SELECT sector_id, code, name, descript, expl_id, muni_id, macrosector_id, parent_id, active 
		FROM sector 
		WHERE active 
		AND sector_id > 0 
		ORDER BY sector_id;

		INSERT INTO temp_macrosector (macrosector_id, code, name, descript, expl_id, muni_id, active)
		SELECT macrosector_id, code, name, descript, expl_id, muni_id, active 
		FROM macrosector 
		WHERE active 
		AND macrosector_id > 0 
		ORDER BY macrosector_id;

		INSERT INTO temp_municipality (muni_id, name, observ, active)
		SELECT muni_id, name, observ, active 
		FROM v_municipality 
		WHERE active 
		AND muni_id > 0 
		ORDER BY muni_id;

		INSERT INTO temp_network (network_id, name, active)
		SELECT id::integer AS network_id, idval AS name, true AS active 
		FROM om_typevalue 
		WHERE typevalue = 'network_type' 
		ORDER BY id;

		IF v_project_type = 'WS' THEN
			INSERT INTO temp_t_mincut (id, work_order, expl_id, macroexpl_id, muni_id, minsector_id, forecast_start, forecast_end)
			SELECT id, work_order, expl_id, macroexpl_id, muni_id, minsector_id, forecast_start, forecast_end 
			FROM om_mincut 
			WHERE id > 0 
			ORDER BY id;
		END IF;
	ELSE
		-- create auxiliar table temp_aux_sector_muni
		CREATE TEMP TABLE temp_muni_sector_expl AS
		SELECT DISTINCT muni_id, sector_id, expl_id FROM (
			SELECT muni_id, sector_id, expl_id FROM node WHERE state > 0
			UNION
			SELECT muni_id, sector_id, unnest(expl_visibility) AS expl_id FROM node WHERE state > 0
		) n
		WHERE expl_id IS NOT NULL
		AND EXISTS (SELECT 1 FROM cat_manager cm
		WHERE n.expl_id = ANY (cm.expl_id)
		AND EXISTS (SELECT 1 FROM unnest(cm.rolename) r(role)
		WHERE pg_has_role(current_user, r.role, 'member')));

		INSERT INTO temp_exploitation (expl_id, code, name, descript, macroexpl_id, active)
		SELECT DISTINCT e.expl_id, e.code, e.name, e.descript, e.macroexpl_id, e.active
		FROM temp_muni_sector_expl t
		JOIN exploitation e ON e.expl_id = t.expl_id
		WHERE e.active AND e.expl_id > 0
		ORDER BY 1;

		-- populate temp_network
		INSERT INTO temp_network (network_id, name, active)
		SELECT id::integer AS network_id, idval AS name, true AS active
		FROM om_typevalue WHERE typevalue = 'network_type' ORDER BY id;

		-- populate temp_macroexploitation
		INSERT INTO temp_macroexploitation (macroexpl_id, code, name, descript, active)
		SELECT DISTINCT ON (m.macroexpl_id) m.macroexpl_id, m.code, m.name, m.descript, m.active
		FROM macroexploitation m
		JOIN temp_exploitation e USING (macroexpl_id)
		WHERE m.active AND m.macroexpl_id > 0
		ORDER BY 1
		ON CONFLICT (macroexpl_id) DO NOTHING;

		-- populate temp_sector
		INSERT INTO temp_sector (sector_id, code, name, descript, expl_id, muni_id, macrosector_id, parent_id, active)
		SELECT DISTINCT ON (s.sector_id) s.sector_id, s.code, s.name, s.descript, s.expl_id, s.muni_id, s.macrosector_id, s.parent_id, s.active
		FROM temp_muni_sector_expl t
		JOIN temp_exploitation e USING (expl_id)
		JOIN sector s ON s.sector_id = t.sector_id
		WHERE s.active AND s.sector_id > 0
		ORDER BY s.sector_id
		ON CONFLICT (sector_id) DO NOTHING;

		-- populate temp_macrosector
		INSERT INTO temp_macrosector (macrosector_id, code, name, descript, expl_id, muni_id, active)
		SELECT DISTINCT ON (m.macrosector_id) m.macrosector_id, m.code, m.name, m.descript, m.expl_id, m.muni_id, m.active
		FROM macrosector m
		JOIN temp_sector e USING (macrosector_id)
		WHERE m.active AND m.macrosector_id > 0
		ORDER BY m.macrosector_id
		ON CONFLICT (macrosector_id) DO NOTHING;

		-- populate temp_municipality
		INSERT INTO temp_municipality (muni_id, name, observ, active)
		SELECT DISTINCT ON (em.muni_id) em.muni_id, em.name, em.observ, em.active
		FROM temp_muni_sector_expl t
		JOIN temp_exploitation e USING (expl_id)
		JOIN v_municipality em ON em.muni_id = t.muni_id
		WHERE em.active
		ORDER BY em.muni_id
		ON CONFLICT (muni_id) DO NOTHING;

		IF v_project_type = 'WS' THEN
			INSERT INTO temp_t_mincut (id, work_order, expl_id, macroexpl_id, muni_id, minsector_id, forecast_start, forecast_end)
			SELECT DISTINCT ON (m.id) m.id, m.work_order, m.expl_id, m.macroexpl_id, m.muni_id, m.minsector_id, m.forecast_start, m.forecast_end
			FROM om_mincut m
			WHERE m.id > 0 AND EXISTS (SELECT 1 FROM cat_manager cm
	        WHERE m.expl_id = ANY (cm.expl_id)
	        AND EXISTS (SELECT 1 FROM unnest(cm.rolename) r(role)
	        WHERE pg_has_role(current_user, r.role, 'member')
	        ))
			ORDER BY m.id
			ON CONFLICT (id) DO NOTHING;
		END IF;
	END IF;

	-- manage selector psector in psector-mode
	SELECT value::INT INTO v_cur_psector FROM config_param_user WHERE PARAMETER = 'plan_psector_current' AND cur_user = current_user;
	
	IF v_cur_psector IS NOT NULL AND v_tab_name IN ('tab_psector', 'tab_exploitation', 'tab_sector') THEN  -- mode psector ON
		--unselect psector in different ways
		v_geometry := COALESCE(v_geometry, '{}');
		v_user_values := COALESCE(v_user_values, '{}');
		v_action := COALESCE(v_action, 'null');

		IF v_tab_name = 'tab_psector' AND v_check_all IS FALSE THEN
		
			EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE cur_user = current_user AND ' || v_columnname || ' != ' || v_cur_psector;

			SELECT json_build_object('level', log_level, 'text', error_message) INTO v_message FROM sys_message WHERE id = 4358;
		
			v_message := COALESCE(v_message, '{}');

			v_return = concat('{"client":',gw_fct_json_object_set_key((p_data ->> 'client')::json, 'isReturnSetSelectors', true::boolean),', "message":', v_message, ', "form":{"currentTab":"', v_tab_name,'"}, 
			"feature":{}, "data":{"isReturnSetSelectors":true, "userValues":',v_user_values,', "geometry":', v_geometry,', "useAtlas":"',v_use_atlas,'", "action":',v_action,', "selectorType":"',v_selector_type,'", "addSchema":"', v_add_schema,'", "tiled":"', v_tiled,'", "id":"', v_id,'", "ids":"', v_ids,'","layers":',COALESCE(((p_data ->> 'data')::json->> 'layers'), '{}'),'}}')::json;
			
			RETURN gw_fct_getselectors(v_return);
		
		ELSIF (v_cur_psector = v_id::integer AND v_value = 'False')
			OR v_check_all IS FALSE
			OR (v_cur_psector != v_id::integer AND v_is_alone)
			OR (v_tab_name = 'tab_exploitation' AND v_id::int IN (SELECT expl_id FROM plan_psector WHERE psector_id = v_cur_psector))
			OR (
				v_tab_name = 'tab_sector' AND 
				v_id::int IN (SELECT s.sector_id FROM plan_psector pp JOIN sector s ON pp.expl_id = ANY (s.expl_id) WHERE psector_id = v_cur_psector)
				)
		THEN
			IF v_tab_name = 'tab_exploitation' THEN
				SELECT json_build_object('level', log_level, 'text', error_message) INTO v_message FROM sys_message WHERE id = 4444;
			ELSIF v_tab_name = 'tab_sector' THEN
				SELECT json_build_object('level', log_level, 'text', error_message) INTO v_message FROM sys_message WHERE id = 4446;
			ELSE
				SELECT json_build_object('level', log_level, 'text', error_message) INTO v_message FROM sys_message WHERE id = 4358;
			END IF;
		
			v_message := COALESCE(v_message, '{}');

			v_return = concat('{"client":',gw_fct_json_object_set_key((p_data ->> 'client')::json, 'isReturnSetSelectors', true::boolean),', "message":', v_message, ', "form":{"currentTab":"', v_tab_name,'"}, 
			"feature":{}, "data":{"isReturnSetSelectors":true, "userValues":',v_user_values,', "geometry":', v_geometry,', "useAtlas":"',v_use_atlas,'", "action":',v_action,', "selectorType":"',v_selector_type,'", "addSchema":"', v_add_schema,'", "tiled":"', v_tiled,'", "id":"', v_id,'", "ids":"', v_ids,'","layers":',COALESCE(((p_data ->> 'data')::json->> 'layers'), '{}'),'}}')::json;
			
			RETURN gw_fct_getselectors(v_return);
	
		END IF;
	
	END IF;

	-- manage check all
	IF v_check_all THEN
		IF v_tab_name = 'tab_psector' THEN -- to manage only those psectors related to selected exploitations and not archived
			EXECUTE format(
				'INSERT INTO %I (%I, cur_user) 
				SELECT %I, CURRENT_USER 
				FROM %I t
				WHERE status NOT IN (5,6,7) 
				AND EXISTS (
					SELECT 1 
					FROM selector_expl se 
					WHERE se.expl_id = t.expl_id
					AND se.cur_user = CURRENT_USER
				) ON CONFLICT DO NOTHING',
				v_tablename, v_columnname, 
				v_table_id, 
				v_table
			);
		ELSIF v_tab_name = 'tab_dscenario' THEN -- to manage only those dscenarios related to selected exploitations
			EXECUTE format(
				'INSERT INTO %I (%I, cur_user) 
				SELECT %I, CURRENT_USER 
				FROM %I t
				WHERE EXISTS (
					SELECT 1 
					FROM selector_expl se 
					WHERE se.expl_id = t.expl_id
					AND se.cur_user = CURRENT_USER
				) OR expl_id IS NULL
				ON CONFLICT DO NOTHING',
				v_tablename, v_columnname, 
				v_table_id, 
				v_table
			);
		ELSIF v_tab_name in ('tab_mincut') THEN
			EXECUTE concat('INSERT INTO ',v_tablename,' (',v_columnname,', cur_user) SELECT ',v_table_id,', current_user FROM ',v_table,'
			',(CASE when v_ids is not null then concat(' WHERE id = ANY(ARRAY',v_ids,') ') end),' 
			ON CONFLICT (',v_columnname,', cur_user) DO NOTHING;');
		ELSE
			EXECUTE concat('INSERT INTO ',v_tablename,' (',v_columnname,', cur_user) SELECT ',v_table_id,', current_user FROM ',v_table,'
			',(CASE when v_ids is not null then concat(' WHERE id = ANY(ARRAY',v_ids,')') end),' WHERE active
			ON CONFLICT (',v_columnname,', cur_user) DO NOTHING;');
		END IF;

	ELSIF v_check_all is false THEN
		EXECUTE format(
			'DELETE FROM %I WHERE cur_user = CURRENT_USER',
			v_tablename
		);

	ELSE
		IF v_is_alone THEN
			EXECUTE format(
				'DELETE FROM %I WHERE cur_user = CURRENT_USER',
				v_tablename
			);
		END IF;

		-- manage value
		IF v_value then
			EXECUTE 'INSERT INTO ' || v_tablename || ' ('|| v_columnname ||', cur_user) VALUES('|| v_id ||', '''|| current_user ||''')ON CONFLICT DO NOTHING';
		ELSE
			EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE ' || v_columnname || '::text = '''|| v_id ||''' AND cur_user = current_user';
		END IF;


	END IF;

	-- manage parents
	IF v_tab_name IN ('tab_psector', 'tab_dscenario', 'tab_sector') AND v_check_all IS NULL AND v_disable_parent IS NOT TRUE THEN

		-- getting name
		v_name = substring (v_tab_name,5,99);

		IF v_value THEN

			-- getting parent_id for selected row
			EXECUTE 'SELECT parent_id FROM '||v_table||' WHERE active IS TRUE AND parent_id IS NOT NULL AND '||v_table_id||' = '||v_id
			INTO v_id;

			IF v_id IS NOT NULL THEN

				-- force parent_id to be visible if child have been enabled
				EXECUTE 'INSERT INTO ' || v_tablename || ' ('|| v_columnname ||', cur_user) VALUES('|| v_id ||', '''|| current_user ||''')ON CONFLICT DO NOTHING';
				GET DIAGNOSTICS v_count = row_count;
				IF v_count > 0 THEN
					v_message = concat ('{"level":0, "text":"',v_name,' ',v_id,' have been enabled, because of its parent-relation with selected ', v_name,'"}');
				END IF;

			END IF;
		ELSE
			-- getting childs for parent_id for selected row
			v_querytext = 'SELECT '||v_table_id||' FROM '||v_table||' WHERE active IS TRUE AND parent_id = '|| v_id;

			FOR v_id IN EXECUTE v_querytext
			LOOP
				EXECUTE 'DELETE FROM '||v_tablename||' WHERE ' || v_columnname || ' = '|| v_id ||' AND cur_user = current_user';
				GET DIAGNOSTICS v_count_aux = row_count;
				v_count = v_count + v_count_aux;
			END LOOP;

			IF v_count > 0 THEN
				v_message = concat ('{"level":0, "text":"',v_count,' ',v_name,'(s) have been disabled, because of its child-relation from selected ', v_name,'"}');
			END IF;
		END IF;
	END IF;

	--set expl as vdefault if only one value on selector (remember default value has priority over spatial intersection)
	IF (SELECT count (*) FROM selector_expl WHERE cur_user = current_user) = 1 THEN

		v_expl = (SELECT expl_id FROM selector_expl WHERE cur_user = current_user);

		INSERT INTO config_param_user(parameter, value, cur_user)
		VALUES ('edit_exploitation_vdefault', v_expl, current_user) ON CONFLICT (parameter, cur_user)
		DO UPDATE SET value = v_expl WHERE config_param_user.parameter = 'edit_exploitation_vdefault' AND config_param_user.cur_user = current_user;

	ELSE -- delete if more than one value on selector

		DELETE FROM config_param_user WHERE parameter = 'edit_exploitation_vdefault' AND cur_user = current_user;
	END IF;

	--set sector as vdefault if only one value on selector (remember default value has priority over spatial intersection)
	IF (SELECT count (*) FROM selector_sector WHERE cur_user = current_user) = 1 THEN

		v_sector = (SELECT sector_id FROM selector_sector WHERE cur_user = current_user);

		INSERT INTO config_param_user(parameter, value, cur_user)
		VALUES ('edit_sector_vdefault', v_sector, current_user) ON CONFLICT (parameter, cur_user)
		DO UPDATE SET value = v_sector WHERE config_param_user.parameter = 'edit_sector_vdefault' AND config_param_user.cur_user = current_user;

	ELSE -- delete if more than one value on selector

		DELETE FROM config_param_user WHERE parameter = 'edit_sector_vdefault' AND cur_user = current_user;
	END IF;

	-- trigger getmapzones
	IF v_tab_name IN('tab_exploitation', 'tab_macroexploitation') THEN
		v_action = '[{"funcName": "set_style_mapzones", "params": {}}]';
	END IF;

	-- manage cross-reference tables
	SELECT 1 INTO v_count FROM node LIMIT 1;
	IF v_count > 0 THEN
		IF v_tab_name IN ('tab_exploitation', 'tab_macroexploitation') THEN

			IF v_tab_name = 'tab_exploitation' THEN
				DELETE FROM selector_macroexpl WHERE cur_user = current_user;

			ELSIF v_tab_name = 'tab_macroexploitation' THEN
				DELETE FROM selector_expl WHERE cur_user = current_user;
				INSERT INTO selector_expl
				SELECT DISTINCT expl_id, current_user FROM exploitation WHERE active is true and macroexpl_id IN (SELECT macroexpl_id FROM selector_macroexpl WHERE cur_user = current_user AND macroexpl_id > 0)
				ON CONFLICT (expl_id, cur_user) DO NOTHING;
			END IF;

			-- macrosector
			DELETE FROM selector_macrosector WHERE cur_user = current_user;

			-- sector
			DELETE FROM selector_sector WHERE cur_user = current_user;
			INSERT INTO selector_sector
			SELECT DISTINCT sector_id, current_user 
			FROM temp_muni_sector_expl
			JOIN selector_expl USING (expl_id)
 		    WHERE cur_user = current_user
			ON CONFLICT (sector_id, cur_user) DO NOTHING;

			-- muni
			DELETE FROM selector_municipality WHERE cur_user = current_user;
			INSERT INTO selector_municipality
			SELECT DISTINCT muni_id, current_user 
			FROM temp_muni_sector_expl
			JOIN selector_expl USING (expl_id)
 		    WHERE cur_user = current_user
			ON CONFLICT (muni_id, cur_user) DO NOTHING;

			IF (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member') AND rolname = 'role_epa') IS NOT NULL THEN
				DELETE FROM selector_inp_dscenario WHERE dscenario_id NOT IN
				(SELECT dscenario_id FROM cat_dscenario WHERE active is true and expl_id IS NULL OR expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));
			END IF;

			-- psector
			DELETE FROM selector_psector WHERE psector_id NOT IN
			(SELECT psector_id FROM plan_psector WHERE active is true and expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));


		ELSIF v_tab_name IN ('tab_sector', 'tab_macrosector') THEN

			IF  v_tab_name = 'tab_macrosector' THEN
				DELETE FROM selector_sector WHERE cur_user = current_user;
				INSERT INTO selector_sector
				SELECT DISTINCT sector_id, current_user FROM sector WHERE macrosector_id IN (SELECT macrosector_id FROM selector_macrosector WHERE cur_user = current_user)
				ON CONFLICT (sector_id, cur_user) DO NOTHING;
			END IF;

			-- expl
			DELETE FROM selector_expl WHERE cur_user = current_user;
			INSERT INTO selector_expl
			SELECT DISTINCT expl_id, current_user 
			FROM temp_muni_sector_expl
			JOIN selector_sector USING (sector_id)
 		    WHERE cur_user = current_user
			AND selector_sector.sector_id > 0
			ON CONFLICT (expl_id, cur_user) DO NOTHING;

			-- muni
			DELETE FROM selector_municipality WHERE cur_user = current_user;
			INSERT INTO selector_municipality
			SELECT DISTINCT muni_id, current_user 
			FROM temp_muni_sector_expl
			JOIN selector_sector USING (sector_id)
 		    WHERE cur_user = current_user
			AND selector_sector.sector_id > 0
			ON CONFLICT (muni_id, cur_user) DO NOTHING;

			IF (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member') AND rolname = 'role_epa') IS NOT NULL THEN
				DELETE FROM selector_inp_dscenario WHERE dscenario_id NOT IN
				(SELECT dscenario_id FROM cat_dscenario WHERE active is true and expl_id IS NULL OR expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));
			END IF;

			-- psector
			DELETE FROM selector_psector WHERE psector_id NOT IN
			(SELECT psector_id FROM plan_psector WHERE active is true and expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));



		-- inserting muni_id from selected muni
		ELSIF v_tab_name IN ('tab_municipality') THEN

			-- macroexpl
			DELETE FROM selector_macroexpl WHERE cur_user = current_user;

			-- expl
			DELETE FROM selector_expl WHERE cur_user = current_user;
			INSERT INTO selector_expl
			SELECT DISTINCT expl_id, current_user 
			FROM temp_muni_sector_expl
			JOIN selector_municipality USING (muni_id)
 		    WHERE cur_user = current_user
			ON CONFLICT (expl_id, cur_user) DO NOTHING;

			-- macrosector
			DELETE FROM selector_macrosector WHERE cur_user = current_user;

			-- sector
			DELETE FROM selector_sector WHERE cur_user = current_user;
			INSERT INTO selector_sector
			SELECT DISTINCT sector_id, current_user 
			FROM temp_muni_sector_expl
			JOIN selector_municipality USING (muni_id)
 		    WHERE cur_user = current_user
			ON CONFLICT (sector_id, cur_user) DO NOTHING;			


			-- scenarios
			IF (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member') AND rolname = 'role_epa') IS NOT NULL THEN
				DELETE FROM selector_inp_dscenario WHERE dscenario_id NOT IN
				(SELECT dscenario_id FROM cat_dscenario WHERE active is true and expl_id IS NULL OR expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));
			END IF;

			-- psector
			DELETE FROM selector_psector WHERE psector_id NOT IN
			(SELECT psector_id FROM plan_psector WHERE active is true and expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));

			-- manage add schema for muni
			IF v_add_schema IS NOT NULL THEN
				EXECUTE 'SET search_path = '||v_add_schema||', public';

				EXECUTE' DELETE FROM selector_municipality WHERE cur_user = current_user';
				EXECUTE' INSERT INTO selector_municipality 
				SELECT muni_id, current_user FROM '||v_schema_name||'.selector_municipality WHERE cur_user = current_user';

				EXECUTE 'SET search_path = '||v_schema_name||', public';
			END IF;
		END IF;
	END IF;

	-- manage addschema
	IF v_add_schema IS NOT NULL AND v_tab_name IN ('tab_exploitation', 'tab_macroexploitation') THEN

		EXECUTE 'SET search_path = '||v_add_schema||', public';

		EXECUTE' DELETE FROM selector_municipality WHERE cur_user = current_user';
		EXECUTE' INSERT INTO selector_municipality 
		SELECT muni_id, current_user FROM '||v_schema_name||'.selector_municipality WHERE cur_user = current_user';

		-- expl
		DELETE FROM selector_expl WHERE cur_user = current_user;
		IF v_sector_is_expl_is_muni THEN			
			INSERT INTO selector_expl SELECT expl_id, current_user FROM SCHEMA_NAME.selector_expl WHERE cur_user = current_user AND expl_id 
			IN (SELECT expl_id FROM exploitation WHERE active);
		ELSE	
			INSERT INTO selector_expl
			SELECT DISTINCT expl_id, current_user FROM node WHERE muni_id IN (SELECT muni_id FROM selector_municipality WHERE cur_user = current_user)
			ON CONFLICT (expl_id, cur_user) DO NOTHING;
		END IF;
	
		-- macroexpl
		DELETE FROM selector_macroexpl WHERE cur_user = current_user;
		IF v_sector_is_expl_is_muni THEN			
			INSERT INTO selector_macroexpl SELECT macroexpl_id, current_user FROM SCHEMA_NAME.selector_macroexpl sm WHERE cur_user = current_user AND macroexpl_id 
			IN (SELECT macroexpl_id FROM macroexploitation m WHERE active);
		
			INSERT INTO selector_expl SELECT expl_id, current_user FROM exploitation 
			WHERE macroexpl_id IN (SELECT macroexpl_id FROM selector_macroexpl WHERE cur_user = current_user)
			ON CONFLICT (expl_id, cur_user) DO NOTHING;
		END IF;
		
		-- macrosector
		DELETE FROM selector_macrosector WHERE cur_user = current_user;

		-- sector
		DELETE FROM selector_sector WHERE cur_user = current_user AND sector_id > 0;
		IF v_sector_is_expl_is_muni THEN			
			INSERT INTO selector_sector SELECT expl_id, current_user FROM SCHEMA_NAME.selector_expl WHERE cur_user = current_user AND expl_id 
			IN (SELECT sector_id FROM sector WHERE active);
		ELSE 
			INSERT INTO selector_sector
			SELECT DISTINCT sector_id, current_user FROM node WHERE muni_id IN (SELECT muni_id FROM selector_municipality WHERE cur_user = current_user)
			ON CONFLICT (sector_id, cur_user) DO NOTHING;
		END IF;
		
		-- sector for those objects wich has expl_visibility and expl_visibility is not selected but yes one
		INSERT INTO selector_sector
		SELECT DISTINCT sector_id,current_user FROM arc WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(arc.expl_visibility))
		UNION
		SELECT DISTINCT sector_id,current_user FROM node WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(node.expl_visibility))
		ON CONFLICT (sector_id, cur_user) DO NOTHING;

		-- scenarios
		IF (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member') AND rolname = 'role_epa') IS NOT NULL THEN
			DELETE FROM selector_inp_dscenario WHERE dscenario_id NOT IN
			(SELECT dscenario_id FROM cat_dscenario WHERE active is true and expl_id IS NULL OR expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));
		END IF;

		-- psector
		DELETE FROM selector_psector WHERE psector_id NOT IN
		(SELECT psector_id FROM plan_psector WHERE active is true and expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));
	
		EXECUTE 'SET search_path = '||v_schema_name||', public';
	END IF;

	IF v_add_schema IS NOT NULL AND v_tab_name IN ('tab_exploitation_add', 'tab_macroexploitation_add') THEN

		EXECUTE 'SET search_path = '||v_add_schema||', public';

		-- manage cross-reference tables
		SELECT 1 INTO v_count FROM node LIMIT 1;
		IF v_count > 0 THEN

			IF v_check_all THEN

				EXECUTE concat('INSERT INTO ',v_tablename,' (',v_columnname,', cur_user) SELECT ',v_table_id,', current_user FROM ',v_table,'
				',(CASE when v_ids is not null then concat(' WHERE id = ANY(ARRAY',v_ids,')') end),' WHERE active
				ON CONFLICT (',v_columnname,', cur_user) DO NOTHING;');

			ELSIF v_check_all is false THEN
				EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE cur_user = current_user';
			ELSE

				IF v_is_alone THEN
					EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE cur_user = current_user';
				END IF;

				-- manage value
				IF v_value THEN
					EXECUTE 'INSERT INTO ' || v_tablename || ' ('|| v_columnname ||', cur_user) VALUES('|| v_id ||', '''|| current_user ||''')ON CONFLICT ('|| v_columnname ||', cur_user) DO NOTHING';
				ELSE
					EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE ' || v_columnname || '::text = '''|| v_id ||''' AND cur_user = current_user';
				END IF;

			END IF;
		
			IF  v_tab_name = 'tab_macroexploitation_add' THEN
				DELETE FROM selector_expl WHERE cur_user = current_user;
				INSERT INTO selector_expl
				SELECT DISTINCT expl_id, current_user FROM exploitation WHERE active is true and macroexpl_id IN (SELECT macroexpl_id FROM selector_macroexpl WHERE cur_user = current_user)
				ON CONFLICT (expl_id, cur_user) DO NOTHING;
			END IF;

			-- macrosector
			DELETE FROM selector_macrosector WHERE cur_user = current_user;

			-- sector
			DELETE FROM selector_sector WHERE cur_user = current_user AND sector_id > 0;
			INSERT INTO selector_sector
			SELECT DISTINCT sector_id, current_user FROM node WHERE expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user)
			ON CONFLICT (sector_id, cur_user) DO NOTHING;

			-- those that are in expl_visibility
			INSERT INTO selector_sector
			SELECT DISTINCT sector_id, current_user FROM arc WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(arc.expl_visibility))
			UNION
			SELECT DISTINCT sector_id, current_user FROM node WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(node.expl_visibility))
			UNION	
			SELECT DISTINCT sector_id, current_user FROM connec WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(connec.expl_visibility))
			UNION 
			SELECT DISTINCT sector_id, current_user FROM link WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(link.expl_visibility))
			ON CONFLICT (sector_id, cur_user) DO NOTHING;

			-- muni
			DELETE FROM selector_municipality WHERE cur_user = current_user;
			INSERT INTO selector_municipality
			SELECT DISTINCT muni_id, current_user FROM node WHERE expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user);

			-- those that are in expl_visibility
			INSERT INTO selector_municipality
			SELECT DISTINCT muni_id, current_user FROM arc WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(arc.expl_visibility))
			UNION
			SELECT DISTINCT muni_id, current_user FROM node WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(node.expl_visibility))
			UNION	
			SELECT DISTINCT muni_id, current_user FROM connec WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(connec.expl_visibility))
			UNION 
			SELECT DISTINCT muni_id, current_user FROM link WHERE EXISTS (SELECT 1 FROM selector_expl se WHERE se.cur_user = current_user AND se.expl_id = ANY(link.expl_visibility))
			ON CONFLICT (muni_id, cur_user) DO NOTHING;

			IF v_sector_is_expl_is_muni IS FALSE THEN
				EXECUTE' DELETE FROM '||v_schema_name||'.selector_municipality WHERE cur_user = current_user';
				EXECUTE' INSERT INTO '||v_schema_name||'.selector_municipality 
				SELECT muni_id, current_user FROM selector_municipality WHERE cur_user = current_user';
			END IF;
			
			SELECT row_to_json (a)
			INTO v_geometry
			FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, 
			st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
			FROM (
				SELECT st_expand(st_extent(the_geom)::geometry, v_expand) as the_geom
				FROM temp_ve_arc_geom_selector
			) b) a;

		END IF;

		EXECUTE 'SET search_path = '||v_schema_name||', public';
								
		IF v_sector_is_expl_is_muni IS NOT TRUE THEN

			-- macroexpl
			DELETE FROM selector_macroexpl WHERE cur_user = current_user;
	
			-- expl
			DELETE FROM selector_expl WHERE cur_user = current_user;
			INSERT INTO selector_expl
			SELECT DISTINCT expl_id, current_user FROM node WHERE muni_id IN (SELECT muni_id FROM selector_municipality WHERE cur_user = current_user)
			ON CONFLICT (expl_id, cur_user) DO NOTHING;
	
			-- macrosector
			DELETE FROM selector_macrosector WHERE cur_user = current_user;
	
			-- sector
			DELETE FROM selector_sector WHERE cur_user = current_user AND sector_id > 0;
			INSERT INTO selector_sector
			SELECT DISTINCT sector_id, current_user FROM node WHERE muni_id IN (SELECT muni_id FROM selector_municipality WHERE cur_user = current_user)
			ON CONFLICT (sector_id, cur_user) DO NOTHING;
	
			-- scenarios
			IF (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, 'member') AND rolname = 'role_epa') IS NOT NULL THEN
				DELETE FROM selector_inp_dscenario WHERE dscenario_id NOT IN
				(SELECT dscenario_id FROM cat_dscenario WHERE active is true and expl_id IS NULL OR expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));
			END IF;
	
			-- psector
			DELETE FROM selector_psector WHERE psector_id NOT IN
			(SELECT psector_id FROM plan_psector WHERE active is true and expl_id IN 
		    (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));
		END IF;
	END IF;

	-- change current psector if selector_expl changes
	v_expl = (SELECT expl_id FROM plan_psector JOIN
            (SELECT value FROM config_param_user where parameter ='plan_psector_current' and cur_user = current_user) a ON value::integer = psector_id
            WHERE expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user));

	IF v_expl IS NULL THEN
		UPDATE config_param_user SET value = NULL WHERE parameter = 'plan_psector_current' AND cur_user = CURRENT_USER;
	END IF;

	-- cross reference schema for state 
    IF v_add_schema IS NOT NULL THEN 
        EXECUTE 'DELETE FROM '||v_add_schema||'.selector_state WHERE cur_user = current_user';
        EXECUTE 'INSERT INTO '||v_add_schema||'.selector_state SELECT state_id, current_user FROM selector_state WHERE cur_user = current_user';
    END IF;

	-- get envelope
	v_count = (SELECT 1 FROM vf_node LIMIT 1);

	IF v_tab_name IN ('tab_sector', 'tab_macrosector','tab_exploitation', 'tab_macroexploitation', 'tab_municipality') THEN
		SELECT row_to_json (a)
		INTO v_geometry
		FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1,
		st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
		FROM (
			SELECT st_expand(st_extent(the_geom)::geometry, v_expand) as the_geom
			FROM temp_ve_arc_geom_selector
		) b) a;
				
	ELSIF v_tab_name IN ('tab_psector') THEN
		SELECT row_to_json (a)
		INTO v_geometry
		FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
		FROM (SELECT st_expand(st_extent(the_geom)::geometry, v_expand) as the_geom FROM plan_psector WHERE psector_id IN (select psector_id FROM selector_psector WHERE cur_user = current_user))b) a;
	
	ELSIF v_tab_name IN ('tab_network_state', 'tab_dscenario') THEN
		v_geometry = NULL;

	ELSIF (v_count > 0 or (v_check_all IS False and v_id is null)) AND v_tab_name NOT IN ('tab_exploitation_add', 'tab_macroexploitation_add')  THEN
		SELECT row_to_json (a)
		INTO v_geometry
		FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
		FROM (
			SELECT st_expand(st_extent(the_geom)::geometry, v_expand) as the_geom
			FROM temp_ve_arc_geom_selector
		) b) a;

	END IF;

	-- force 0 
	INSERT INTO selector_municipality VALUES (0, current_user) ON CONFLICT (muni_id, cur_user) DO NOTHING;
	INSERT INTO selector_expl VALUES (0, current_user) ON CONFLICT (expl_id, cur_user) DO NOTHING;
	INSERT INTO selector_sector VALUES (0, current_user) ON CONFLICT (sector_id, cur_user) DO NOTHING;

	-- warn the user that in the selected psectors, there is a connec connected to different arcs
	WITH mec AS (
		SELECT connec_id,
		row_number() over(PARTITION BY connec_id ORDER BY connec_id) AS rowid_connec,
		row_number() over(PARTITION BY arc_id ORDER BY arc_id) AS rowid_arc,
		row_number() over(PARTITION BY psector_id ORDER BY psector_id) AS rowid_psector
		FROM plan_psector_x_connec
		JOIN selector_psector USING (psector_id) WHERE cur_user = current_user
	)
	SELECT count(*) INTO v_count FROM mec WHERE rowid_connec>1 AND rowid_arc > 0 AND rowid_psector > 0;

	IF v_count>0 then

		SELECT concat('{"level":',log_level, ', "text":"', error_message, '"}') INTO v_message FROM sys_message WHERE id = 4340;

	END IF;

	IF v_project_type = 'UD' THEN

		WITH mec AS (
			SELECT gully_id,
			row_number() over(PARTITION BY gully_id ORDER BY gully_id) AS rowid_gully,
			row_number() over(PARTITION BY arc_id ORDER BY arc_id) AS rowid_arc,
			row_number() over(PARTITION BY psector_id ORDER BY psector_id) AS rowid_psector
			FROM plan_psector_x_gully
			JOIN selector_psector USING (psector_id) WHERE cur_user = current_user
		)
		SELECT count(*) INTO v_count FROM mec WHERE rowid_gully>1 AND rowid_arc > 0 AND rowid_psector > 0;

		IF v_count>0 then

			SELECT concat('{"level":',log_level, ', "text":"', error_message, '"}') INTO v_message FROM sys_message WHERE id = 4340;

		END IF;

	END IF;

	-- get uservalues
	PERFORM gw_fct_workspacemanager($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{},"data":{"filterFields":{}, "pageInfo":{}, "action":"CHECK"}}$$);
	v_user_values = (SELECT to_json(array_agg(row_to_json(a))) FROM (SELECT parameter, value FROM config_param_user WHERE parameter IN ('plan_psector_current', 'utils_workspace_current')
	AND cur_user = current_user ORDER BY parameter)a);


	-- Control NULL's
	v_geometry := COALESCE(v_geometry, '{}');
	v_user_values := COALESCE(v_user_values, '{}');
	v_action := COALESCE(v_action, 'null');
	v_message := COALESCE(v_message, '{}');


	EXECUTE 'SET ROLE "'||v_prev_cur_user||'"';

	-- Return
	v_return = concat('{"client":',gw_fct_json_object_set_key((p_data ->> 'client')::json, 'isReturnSetSelectors', true::boolean),', "message":', v_message, ', "form":{"currentTab":"', v_tab_name,'"}, "feature":{}, 
	"data":{"isReturnSetSelectors":true, "isReturnSetselectors":true, "userValues":',v_user_values,', "geometry":', v_geometry,', "useAtlas":"',v_use_atlas,'", "action":',v_action,', 
	"selectorType":"',v_selector_type,'", "addSchema":"', v_add_schema,'", "tiled":"', v_tiled,'", "id":"', v_id,'", "ids":"', v_ids,'",
	"layers":',COALESCE(((p_data ->> 'data')::json->> 'layers'), '{}'),'}}');
	RETURN gw_fct_getselectors(v_return);

	--Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"project_type":"'||v_project_type||'", "action":"DROP", "group":"SELECTOR"}}}$$)';
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;

$function$
;

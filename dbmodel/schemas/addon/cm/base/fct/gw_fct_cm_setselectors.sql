/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 3454

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_setselectors(p_data json)
  RETURNS json AS
$BODY$

/*example

*/

DECLARE

v_version text;
v_tabname text;
v_tablename text;
v_columnname text;
v_id text;
v_ids text;
v_value text;
v_muni integer;
v_isalone boolean;
v_parameter_selector json;
v_data json;
v_expl integer;
v_addschema text;
v_error_context text;
v_selectortype text;
v_schemaname text;
v_return json;
v_table text;
v_tableid text;
v_checkall boolean;
v_geometry text;
v_useatlas boolean;
v_querytext text;
v_message json := json_build_object('level', 1, 'text', 'Process done successfully');
v_count integer = 0;
v_count_aux integer = 0;
v_count_2 integer = 0;
v_name text;
v_disableparent boolean;
v_fid integer = 397;
v_uservalues json;
v_action text = null;
v_sector integer;
v_zonetable text;
v_cur_user text;
v_prev_cur_user text;
v_device integer;
v_expand float=0;
v_tiled boolean;
v_result json;
v_result_init json;
v_result_valve json;
v_result_node json;
v_result_connec json;
v_result_arc json;
v_sectorfromexpl boolean;
v_sectorfrommacro boolean;
v_explfrommacro boolean;
v_expl_x_user boolean;
v_project_type text;
v_psector_current_value integer;
v_prev_search_path text;

BEGIN

	-- Set search path to local schema
	v_prev_search_path := current_setting('search_path');
	PERFORM set_config('search_path', 'cm,public', true);
	v_schemaname = 'cm';

	--  get api version
	v_version = (SELECT giswater FROM sys_version LIMIT 1);

	-- get system variables
	v_sectorfromexpl = (SELECT value::json->>'sectorFromExpl' FROM config_param_system WHERE parameter = 'basic_selector_options');
	v_sectorfrommacro = (SELECT value::json->>'sectorFromMacro' FROM config_param_system WHERE parameter = 'basic_selector_options');
	v_explfrommacro = (SELECT value::json->>'explFromMacro' FROM config_param_system WHERE parameter = 'basic_selector_options');
	v_expl_x_user = (SELECT value FROM config_param_system WHERE parameter = 'admin_exploitation_x_user');
	v_project_type = (SELECT project_type FROM sys_version LIMIT 1);

	-- Get input parameters:
	v_tabname := (p_data ->> 'data')::json->> 'tabName';
	v_selectortype := (p_data ->> 'data')::json->> 'selectorType';
	v_id := (p_data ->> 'data')::json->> 'id';
	v_ids := (p_data ->> 'data')::json->> 'ids';
	v_value := (p_data ->> 'data')::json->> 'value';
	v_isalone := (p_data ->> 'data')::json->> 'isAlone';
	v_checkall := (p_data ->> 'data')::json->> 'checkAll';
	v_addschema := (p_data ->> 'data')::json->> 'addSchema';
	v_useatlas := (p_data ->> 'data')::json->> 'useAtlas';
	v_disableparent := (p_data ->> 'data')::json->> 'disableParent';
	v_data = p_data->>'data';
	v_cur_user := (p_data ->> 'client')::json->> 'cur_user';
	v_device := (p_data ->> 'client')::json->> 'device';

	v_tiled := ((p_data ->>'client')::json->>'tiled')::boolean;
	v_prev_cur_user = current_user;
	IF v_cur_user IS NOT NULL THEN
		EXECUTE 'SET ROLE "'||v_cur_user||'"';
	END IF;

	IF v_device = 5 THEN
		v_expand = 50.0;
	END IF;

	-- profilactic control
	IF lower(v_selectortype) = 'none' OR v_selectortype = '' OR lower(v_selectortype) ='null' THEN v_selectortype = 'selector_basic'; END IF;
	IF v_useatlas IS null then v_useatlas = false; END IF;

	-- profilactic control of schema name
	IF lower(v_addschema) = 'none' OR v_addschema = '' OR lower(v_addschema) ='null' OR v_addschema is null OR v_addschema='NULL'
		THEN v_addschema = null;
	ELSE
		IF (select schemaname from pg_tables WHERE schemaname = v_addschema LIMIT 1) IS NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	            "data":{"message":"3132", "function":"2870","parameters":null, "is_process":true}}$$)';
		-- todo: send message to response
		END IF;
	END IF;

	-- Get system parameters
	v_parameter_selector = (SELECT value::json FROM config_param_system WHERE parameter = concat('basic_selector_', v_tabname));
	v_tablename = v_parameter_selector->>'selector';
	v_columnname = v_parameter_selector->>'selector_id';
	v_table = v_parameter_selector->>'table';
	v_tableid = v_parameter_selector->>'table_id';

	-- setting schema add
	IF v_tabname like '%add%' AND v_addschema IS NOT NULL THEN
		v_tablename = concat(v_addschema,'.',v_tablename);
		v_table = concat(v_addschema,'.',v_table);
	END IF;

	-- create temp tables related to expl x user variable
	DROP TABLE IF EXISTS temp_om_campaign;
	DROP TABLE IF EXISTS temp_om_campaign_lot;


	-- creation of the temporal tables in function of the role
	if 'role_cm_admin' in (	SELECT r.rolname AS role_name FROM pg_roles r JOIN pg_auth_members m ON r.oid = m.roleid
						  	JOIN pg_roles u ON u.oid = m.member WHERE u.rolname = current_user) then

		CREATE TEMP TABLE temp_om_campaign AS
		select c.* from om_campaign c
		where c.active;

		CREATE TEMP TABLE temp_om_campaign_lot AS
		select l.* from om_campaign_lot l
		join selector_campaign sc using (campaign_id)
		where l.active
		and cur_user = current_user; -- only campaigns enabled for user

	else

		CREATE TEMP TABLE temp_om_campaign  AS
		select c.* from om_campaign c
		join cat_organization  using (organization_id)
		join cat_team t using (organization_id)
		join cat_user using (team_id)
		where c.active and username = current_user;

		CREATE TEMP TABLE temp_om_campaign_lot AS
		select l.* from om_campaign_lot l
		join selector_campaign sc using (campaign_id)
		join cat_team t using (team_id)
		where l.active
		and cur_user = current_user; -- only campaigns enabled for user

	end if;

	-- manage check all
	IF v_checkall THEN
		EXECUTE concat('INSERT INTO ',v_tablename,' (',v_columnname,', cur_user) SELECT ',v_tableid,', current_user FROM ',v_table,'
		',(CASE when v_ids is not null then concat(' WHERE id = ANY(ARRAY',v_ids,')') end),' WHERE active
		ON CONFLICT (',v_columnname,', cur_user) DO NOTHING;');

	ELSIF v_checkall is false THEN
		EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE cur_user = current_user';

	ELSE
		IF v_isalone THEN
			EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE cur_user = current_user';
		END IF;

		-- manage value
		IF v_value then
			EXECUTE 'INSERT INTO ' || v_tablename || ' ('|| v_columnname ||', cur_user) VALUES('|| v_id ||', '''|| current_user ||''')ON CONFLICT DO NOTHING';
		ELSE
			EXECUTE 'DELETE FROM ' || v_tablename || ' WHERE ' || v_columnname || '::text = '''|| v_id ||''' AND cur_user = current_user';
		END IF;


	END IF;

	DELETE FROM cm.selector_lot sl
	WHERE NOT EXISTS (
	    SELECT 1
	    FROM cm.om_campaign_lot ocl
	    JOIN cm.selector_campaign oc
	      ON oc.campaign_id = ocl.campaign_id
	    WHERE oc.cur_user = current_user AND sl.lot_id = ocl.lot_id
	)
	and sl.cur_user = current_user;

	-- get envelope
	--SELECT count(the_geom) INTO v_count_2 FROM ve_node LIMIT 1;

	IF v_tabname='tab_campaign' THEN
		SELECT row_to_json (a)
		INTO v_geometry
		FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
		FROM (SELECT st_expand(the_geom, v_expand) as the_geom FROM om_campaign where campaign_id IN
		(SELECT campaign_id FROM selector_campaign WHERE cur_user=current_user)) b) a;

	ELSIF v_tabname='tab_lot' THEN
		SELECT row_to_json (a)
		INTO v_geometry
		FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
		FROM (SELECT st_expand(the_geom, v_expand) as the_geom FROM om_campaign_lot where lot_id IN
		(SELECT lot_id FROM selector_lot WHERE cur_user=current_user)) b) a;

	END IF;

	-- Control NULL's
	v_geometry := COALESCE(v_geometry, '{}');
	v_uservalues := COALESCE(v_uservalues, '{}');
	v_action := COALESCE(v_action, 'null');

	EXECUTE 'SET ROLE "'||v_prev_cur_user||'"';

	-- Return
	v_return := json_build_object(
	    'client', (p_data -> 'client'),
	    'message', v_message::json,
	    'form', json_build_object(
	        'currentTab', v_tabname
	    ),
	    'feature', json_build_object(),
	    'data', json_build_object(
	        'userValues', COALESCE(v_uservalues::json, '{}'::json),
	        'geometry', COALESCE(v_geometry::json, '{}'::json),
	        'action', v_action,
	        'selectorType', v_selectortype,
	        'id', v_id,
	        'ids', v_ids,
	        'layers', COALESCE((p_data -> 'data' -> 'layers'), '{}'::json)
	    )
	);

	PERFORM set_config('search_path', v_prev_search_path, true);
	RETURN cm.gw_fct_cm_getselectors(v_return::json);

	--Exception handling
	--EXCEPTION WHEN OTHERS THEN
	--GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	--RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

EXCEPTION WHEN OTHERS THEN
	PERFORM set_config('search_path', v_prev_search_path, true);
	RAISE;
END;

$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

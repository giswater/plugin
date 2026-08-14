/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 3442

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_getselectors(p_data json)
  RETURNS json AS
$BODY$

/*example

*/

DECLARE
rec_tab record;

v_formTabsAux  json;
v_formTabs text;
v_version text;
v_active boolean=false;
v_firsttab boolean=false;
v_selector_list text;
v_selector_type text;
v_result_list text[];
v_filter_name text;
v_label text;
v_table text;
v_selector text;
v_table_id text;
v_selector_id text;
v_filterfromconfig text;
v_manageall boolean;
v_typeahead text;
v_expl_x_user boolean;
v_filter text;
v_selectionMode text;
v_typeaheadForced boolean=false;
v_stylesheet json;
v_errcontext text;
v_currenttab text;
v_tab record;
v_ids text;
v_filterfrominput text;
v_filterfromids text;
v_fullfilter text;
v_finalquery text;
v_querytab text;
v_orderby text;
v_geometry text;
v_query text;
v_name text;
v_pkeyfield text;
v_querystring text;
v_debug_vars json;
v_debug json;
v_msgerr json;
v_count_zone integer;
rec_macro integer;
v_count_selector integer;
v_useatlas boolean;
v_message json;
v_uservalues json;
v_action text;
v_zonetable text;
v_zoneid text;
v_macroid text;
v_macrotable text;
v_macroselector text;
v_cur_user text;
v_prev_cur_user text;
v_device integer;
v_layers text;
v_layer text;
v_rec record;
v_columns json;
v_layerColumns json;
v_loadProject boolean=false;
v_addschema text;
v_tiled boolean;
v_result json;
v_mincut_init json;
v_mincut_valve_proposed json;
v_mincut_valve_not_proposed json;
v_mincut_node json;
v_mincut_connec json;
v_mincut_arc json;
v_exclude_tab text='';
v_orderby_query text;
v_sectorfromexpl boolean;
v_orderby_check boolean;
v_sectorfrommacro boolean;
v_explfrommacro boolean;
v_project_type text;
v_prev_search_path text;

BEGIN

	-- Save current search_path and set cm (transaction-local)
	v_prev_search_path := current_setting('search_path');
	PERFORM set_config('search_path', 'cm,public', true);

	--  get system values
	v_project_type = (SELECT project_type FROM sys_version LIMIT 1);
	v_version = (SELECT giswater FROM sys_version LIMIT 1);


	-- Get input parameters:
	v_selector_type := (p_data ->> 'data')::json->> 'selectorType';
	v_currenttab := (p_data ->> 'form')::json->> 'currentTab';
	v_filterfrominput := (p_data ->> 'data')::json->> 'filterText';
	v_geometry := ((p_data ->> 'data')::json->>'geometry');
	v_useatlas := (p_data ->> 'data')::json->> 'useAtlas';
	v_loadProject := (p_data ->> 'data')::json->> 'loadProject';
	v_message := (p_data ->> 'message')::json;
	v_cur_user := (p_data ->> 'client')::json->> 'cur_user';
	v_device := (p_data ->> 'client')::json->> 'device';
	v_addschema := (p_data ->> 'data')::json->> 'addSchema';
	v_tiled := ((p_data ->>'client')::json->>'tiled')::boolean;

	IF v_device is null then v_device = 4; END IF;

	v_prev_cur_user = current_user;
	IF v_cur_user IS NOT NULL THEN
		EXECUTE 'SET ROLE '||quote_ident(v_cur_user);
	END IF;

	-- profilactic control of schema name
	IF lower(v_addschema) = 'none' OR v_addschema = '' OR lower(v_addschema) ='null' OR v_addschema is null OR v_addschema='NULL' THEN
		v_addschema = null;
		v_exclude_tab = ' AND tabname != ''tab_exploitation_add''';
	END IF;
	-- profilactic control of message
	IF v_message is null THEN
    	v_message := json_build_object('level', 111, 'text', 'Process done successfully');
	END IF;

	-- get system variables:
	v_expl_x_user = (SELECT value FROM config_param_system WHERE parameter = 'admin_exploitation_x_user');
	v_sectorfromexpl = (SELECT value::json->>'sectorFromExpl' FROM config_param_system WHERE parameter = 'basic_selector_options');
	v_sectorfrommacro = (SELECT value::json->>'sectorFromMacro' FROM config_param_system WHERE parameter = 'basic_selector_options');
	v_explfrommacro = (SELECT value::json->>'explFromMacro' FROM config_param_system WHERE parameter = 'basic_selector_options');

	v_stylesheet = (SELECT value FROM config_param_system WHERE parameter = 'qgis_form_selector_stylesheet');

	-- when typeahead only one tab is executed
	IF v_filterfrominput IS NULL OR v_filterfrominput = '' OR lower(v_filterfrominput) ='None' or lower(v_filterfrominput) = 'null' THEN
		v_querytab = '';
	ELSE
		v_querytab = concat(' AND tabname = ', quote_literal(v_currenttab));
	END IF;

	-- Start the construction of the tabs array
	v_formTabs := '[';

	v_query = concat(
	'SELECT formname, tabname, label, tooltip, tabfunction, tabactions, value
	 FROM (SELECT formname, tabname, f.label, f.tooltip, tabfunction, tabactions, unnest(device) AS device, value, orderby FROM v_config_form_tabs f, config_param_system
	 WHERE formname=',quote_literal(v_selector_type),' AND isenabled IS TRUE AND concat(''basic_selector_'', tabname) = parameter ',(v_querytab),
	' AND sys_role IN (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, ''member'')))a WHERE device = ',v_device, v_exclude_tab,' ORDER BY orderby');


	DROP TABLE IF EXISTS temp_om_campaign;
	DROP TABLE IF EXISTS temp_om_campaign_lot;


	-- creation of the temporal tables in function of the role
	if 'role_cm_admin' in (	SELECT r.rolname AS role_name FROM pg_roles r JOIN pg_auth_members m ON r.oid = m.roleid
						  	JOIN pg_roles u ON u.oid = m.member WHERE u.rolname = current_user) then

		CREATE TEMP TABLE temp_om_campaign AS
		select c.*, sy.idval as status_name from om_campaign c
		LEFT JOIN cm.sys_typevalue sy ON sy.id::text = c.status::text AND sy.typevalue = 'campaign_status'::text
		where c.active;

		CREATE TEMP TABLE temp_om_campaign_lot AS
		select l.* from om_campaign_lot l
		join selector_campaign sc using (campaign_id)
		where l.active
		and cur_user = current_user; -- only campaigns enabled for user

	else

		CREATE TEMP TABLE temp_om_campaign  AS
		select c.*, sy.idval as status_name from om_campaign c
		join cat_organization  using (organization_id)
		join cat_team t using (organization_id)
		join cat_user using (team_id)
		LEFT JOIN cm.sys_typevalue sy ON sy.id::text = c.status::text AND sy.typevalue = 'campaign_status'::text
		where c.active and username = current_user;

		CREATE TEMP TABLE temp_om_campaign_lot AS
		select l.* from om_campaign_lot l
		join selector_campaign sc using (campaign_id)
		join cat_team t using (team_id)
		where l.active
		and cur_user = current_user; -- only campaigns enabled for user

	end if;

	-- starting loop for tabs
	FOR v_tab IN EXECUTE v_query

	LOOP
		-- get variables form input
		v_selector_list := (p_data ->> 'data')::json->> 'ids';
		v_filterfrominput := (p_data ->> 'data')::json->> 'filterText';

		-- get variables from tab
		v_label = v_tab.value::json->>'label';
		v_table = v_tab.value::json->>'table';
		v_table_id = v_tab.value::json->>'table_id';
		v_selector = v_tab.value::json->>'selector';
		v_selector_id = v_tab.value::json->>'selector_id';
		v_filterfromconfig = v_tab.value::json->>'query_filter';
		v_manageall = v_tab.value::json->>'manageAll';
		v_typeahead = v_tab.value::json->>'typeaheadFilter';
		v_selectionMode = v_tab.value::json->>'selectionMode';
		v_orderby = v_tab.value::json->>'orderBy';
		v_name = v_tab.value::json->>'name';
		v_typeaheadForced = v_tab.value::json->>'typeaheadForced';
		v_orderby_check = v_tab.value::json->>'orderbyCheck';

		IF v_orderby IS NULL THEN v_orderby = v_pkeyfield; end if;
		IF v_name IS NULL THEN v_name = v_orderby; end if;

		-- profilactic control of selection mode
		IF v_selectionMode = '' OR v_selectionMode is null then
			v_selectionMode = 'keepPrevious';
		END IF;

		-- order by heck. This enables to put checked rows on the top. Useful when there are lots of rows and you need to use the scrollbar to kwow what is checked
		IF v_orderby_check AND v_tab.tabname != v_currenttab THEN
			v_orderby_query = 'ORDER BY value DESC, orderby';
		ELSE
			v_orderby_query = 'ORDER BY orderby';
		END IF;

		-- built filter from input
		IF v_filterfrominput IS NULL OR v_filterfrominput = '' OR lower(v_filterfrominput) ='None' or lower(v_filterfrominput) = 'null' THEN
			v_filterfrominput := NULL;
		ELSE
			v_filterfrominput = concat (v_typeahead,' LIKE ''%', lower(v_filterfrominput), '%''');
		END IF;


		-- profilactic null control
		v_fullfilter := COALESCE(v_fullfilter, '');

		-- setting schema add
		IF v_tab.tabname like '%add%' AND v_addschema IS NOT  NULL THEN
			v_table = concat(v_addschema,'.',v_table);
			v_selector = concat(v_addschema,'.',v_selector);
		END IF;

		-- final query
		v_finalquery = concat('SELECT array_to_json(array_agg(row_to_json(b))) FROM (
				select *, row_number() OVER (',v_orderby_query,') as orderby from (
				SELECT ',quote_ident(v_table_id),', concat(' , v_label , ') AS label, ',v_name,' as name, ', v_table_id , '::text as widgetname, ' ,
				v_orderby, ' as orderby , ''', v_selector_id , ''' as columnname, ''check'' as type, ''boolean'' as "dataType", true as "value"
				FROM ', v_table ,' WHERE ' , v_table_id , ' IN (SELECT ' , v_selector_id , ' FROM ', v_selector ,' WHERE cur_user=' , quote_literal(current_user) , ') ', v_fullfilter ,' UNION
				SELECT ',quote_ident(v_table_id),', concat(' , v_label , ') AS label, ',v_name,' as name, ', v_table_id , '::text as widgetname, ' ,
				v_orderby, ' , ''',v_selector_id , ''' as columnname, ''check'' as type, ''boolean'' as "dataType", false as "value"
				FROM ', v_table ,' WHERE ' , v_table_id , ' NOT IN (SELECT ' , v_selector_id , ' FROM ', v_selector ,' WHERE cur_user=' , quote_literal(current_user) , ') ',
				 v_fullfilter ,') a)b');


		EXECUTE  v_finalquery INTO v_formTabsAux;
		--reset v_ids
		v_ids= null;

		-- Add tab name to json
		IF v_formTabsAux IS NULL THEN
			v_formTabsAux := ('{"fields":[]}')::json;
		ELSE
			v_formTabsAux := ('{"fields":' || v_formTabsAux || '}')::json;
		END IF;

		-- setting active tab
		IF v_currenttab = v_tab.tabname THEN
			v_active = true;
		ELSIF v_currenttab IS NULL OR v_currenttab = '' OR v_currenttab ='None' OR v_firsttab is false THEN
			v_active = false;
		END IF;

		-- setting other variables of tab
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'tabName', v_tab.tabname::TEXT);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'tableName', v_selector);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'tabLabel', v_tab.label::TEXT);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'tooltip', v_tab.tooltip::TEXT);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'selectorType', v_tab.formname::TEXT);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'manageAll', v_manageall::TEXT);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'typeaheadFilter', v_typeahead::TEXT);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'selectionMode', v_selectionMode::TEXT);
		v_formTabsAux := gw_fct_cm_json_object_set_key(v_formTabsAux, 'typeaheadForced', v_typeaheadForced::TEXT);

		-- Create tabs array
		IF v_firsttab THEN
			v_formTabs := v_formTabs || ',' || v_formTabsAux::text;
		ELSE
			v_formTabs := v_formTabs || v_formTabsAux::text;
		END IF;
		v_firsttab := TRUE;

	END LOOP;

	-- Manage web client
	IF v_device = 5 THEN

		-- Get active exploitations geometry (to zoom on them)
		IF v_loadProject IS TRUE AND v_geometry IS NULL THEN
			SELECT row_to_json (a)
			INTO v_geometry
			FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
			FROM (SELECT st_expand(st_collect(the_geom), 50.0) as the_geom FROM exploitation where expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user)) b) a;
		END IF;

		if v_selector_type='selector_mincut' then
		-- GET GEOJSON
		--v_om_mincut
		SELECT jsonb_build_object(
		    'type', 'FeatureCollection',
		    'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		) INTO v_result
			FROM (
	  	SELECT jsonb_build_object(
	     'type',       'Feature',
	    'geometry',   ST_AsGeoJSON(anl_the_geom)::jsonb,
	    'properties', to_jsonb(row) - 'anl_the_geom'
	  	) AS feature
	  	FROM (SELECT id, ST_Transform(anl_the_geom, 4326) as anl_the_geom
	  	FROM  v_om_mincut) row) features;
		raise notice 'v_om_mincut -> %', v_result;
		v_mincut_init = v_result;

			--v_om_mincut_valve proposed true
            SELECT jsonb_build_object(
		        'type', 'FeatureCollection',
		        'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		    ) INTO v_result
                FROM (
            SELECT jsonb_build_object(
             'type',       'Feature',
            'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
            'properties', to_jsonb(row) - 'the_geom'
            ) AS feature
            FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
            FROM  v_om_mincut_valve WHERE proposed = true) row) features;

            v_mincut_valve_proposed = v_result;

            --v_om_mincut_valve proposed false
            SELECT jsonb_build_object(
		        'type', 'FeatureCollection',
		        'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		    ) INTO v_result
                FROM (
            SELECT jsonb_build_object(
             'type',       'Feature',
            'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
            'properties', to_jsonb(row) - 'the_geom'
            ) AS feature
            FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
            FROM  v_om_mincut_valve WHERE proposed = false) row) features;

            v_mincut_valve_not_proposed = v_result;

		--v_om_mincut_node
		SELECT jsonb_build_object(
		    'type', 'FeatureCollection',
		    'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		) INTO v_result
			FROM (
	  	SELECT jsonb_build_object(
	     'type',       'Feature',
	    'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
	    'properties', to_jsonb(row) - 'the_geom'
	  	) AS feature
	  	FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
	  	FROM  v_om_mincut_node) row) features;

		v_mincut_node = v_result;

		--v_om_mincut_connec
		SELECT jsonb_build_object(
		    'type', 'FeatureCollection',
		    'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		) INTO v_result
			FROM (
	  	SELECT jsonb_build_object(
	     'type',       'Feature',
	    'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
	    'properties', to_jsonb(row) - 'the_geom'
	  	) AS feature
	  	FROM (SELECT id, ST_Transform(the_geom, 4326) as the_geom
	  	FROM  v_om_mincut_connec) row) features;

		v_mincut_connec = v_result;

		--v_om_mincut_arc
		SELECT jsonb_build_object(
		    'type', 'FeatureCollection',
		    'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		) INTO v_result
			FROM (
	  	SELECT jsonb_build_object(
	     'type',       'Feature',
	    'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
	    'properties', to_jsonb(row) - 'the_geom'
	  	) AS feature
	  	FROM (SELECT id, arc_id, ST_Transform(the_geom, 4326) as the_geom
	  	FROM  v_om_mincut_arc) row) features;

		v_mincut_arc = v_result;
		end if;
	END IF;

	-- Finish the construction of the tabs array
	v_formTabs := v_formTabs ||']';

	-- Check null
	v_formTabs := COALESCE(v_formTabs, '[]');
	v_manageall := COALESCE(v_manageall, FALSE);
	v_selectionMode = COALESCE(v_selectionMode, '');
	v_currenttab = COALESCE(v_currenttab, '');
	v_geometry = COALESCE(v_geometry, '{}');
	v_stylesheet := COALESCE(v_stylesheet, '{}');
	v_layerColumns = COALESCE(v_layerColumns, '{}');
	v_mincut_init = COALESCE(v_mincut_init, '[]');
	v_mincut_valve_proposed = COALESCE(v_mincut_valve_proposed, '[]');
	v_mincut_valve_not_proposed = COALESCE(v_mincut_valve_not_proposed, '[]');
	v_mincut_node = COALESCE(v_mincut_node, '[]');
	v_mincut_connec = COALESCE(v_mincut_connec, '[]');
	v_mincut_arc = COALESCE(v_mincut_arc, '[]');
	v_uservalues = COALESCE(v_uservalues, '{}');
	v_tiled = COALESCE(v_tiled, FALSE);

	EXECUTE 'SET ROLE '||quote_ident(v_prev_cur_user);

	-- Return
	IF v_firsttab IS FALSE THEN
		-- Return not implemented
		PERFORM set_config('search_path', v_prev_search_path, true);
		RETURN ('{"status":"Accepted"' ||
		', "version":"'|| v_version ||'"'||
		', "message":"Not implemented"'||
		'}')::json;
	ELSE
		v_uservalues := COALESCE(json_extract_path_text(p_data,'data','userValues'),
			(SELECT to_json(array_agg(row_to_json(a))) FROM (SELECT parameter, value FROM config_param_user WHERE parameter IN ('plan_psector_current', 'utils_workspace_current') AND cur_user = current_user ORDER BY parameter)a)::text,
			'{}');
		v_action := json_extract_path_text(p_data,'data','action');
		IF v_action = '' THEN v_action = NULL; END IF;


		-- Return formtabs
		PERFORM set_config('search_path', v_prev_search_path, true);
		RETURN json_build_object(
		    'status', 'Accepted',
		    'version', v_version,
		    'body', json_build_object(
		        'message', v_message,
		        'form', json_build_object(
		            'formName', '',
		            'formLabel', '',
		            'currentTab', v_currenttab,
		            'formText', '',
		            'formTabs', COALESCE(v_formTabs::json, '[]'::json),
		            'style', COALESCE(v_stylesheet::json, '{}'::json)
		        ),
		        'feature', json_build_object(),
		        'data', json_build_object(
		            'userValues', COALESCE(v_uservalues::json, '{}'::json),
		            'geometry', COALESCE(v_geometry::json, '{}'::json),
		            'layerColumns', COALESCE(v_layerColumns::json, '{}'::json)
		        )
		    )
		);

	END IF;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_errcontext = pg_exception_context;
	PERFORM set_config('search_path', v_prev_search_path, true);
	RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE, 'MSGERR', (v_msgerr::json ->> 'MSGERR'))::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

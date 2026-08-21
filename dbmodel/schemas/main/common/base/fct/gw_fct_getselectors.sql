/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 2796

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getselectors(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*example

SELECT SCHEMA_NAME.gw_fct_getselectors($${"client":{"lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{"currentTab":"tab_exploitation"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic" ,"filterText":"1"}}$$);

SELECT SCHEMA_NAME.gw_fct_getselectors($${"client":{"lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{"currentTab":"tab_exploitation"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "filterText":""}}$$);

SELECT SCHEMA_NAME.gw_fct_getselectors($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{"currentTab":"tab_exploitation"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "filterText":""}}$$);

SELECT SCHEMA_NAME.gw_fct_setselectors($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_exploitation", "id":"1", "isAlone":"True", "disableParent":"False", "value":"True", "addSchema":"NULL"}}$$)

*/

DECLARE

-- input variables
v_selector_type text;
v_current_tab text;
v_filter_from_input text;
v_geometry text;
v_use_atlas boolean;
v_load_project boolean=false;
v_message text;
v_cur_user text;
v_device integer;
v_add_schema text;
v_tiled boolean;
v_is_return_set_selectors boolean;

-- aux variables
v_form_tabs_aux  json;
v_version text;
v_first_tab boolean=false;
v_selector_list text;
v_label text;
v_table text;
v_selector text;
v_table_id text;
v_selector_id text;
v_filter_from_config text;
v_typeahead text;
v_expl_x_user boolean;
v_typeahead_forced boolean=false;
v_error_context text;
v_tab record;
v_filter_from_ids text;
v_full_filter text;
v_final_query text;
v_query_tab text;
v_orderby text;
v_query text;
v_name text;
v_pkey_field text;
v_query_string text;
v_debug_vars json;
v_debug json;
v_msgerr json;
v_action text;
v_prev_cur_user text;
v_rec record;
v_result json;

v_exclude_tab text='';
v_orderby_query text;
v_order_by_check boolean;
v_project_type text;
v_tab_network_signal integer = 0;
v_custom_order_by_column text;
v_selector_macro_tabs boolean;

-- return variables
v_formTabs text;
v_manage_all boolean;
v_has_custom_order_by boolean;
v_selection_mode text;
v_stylesheet json;
v_mincut_init json;
v_mincut_valve_proposed json;
v_mincut_valve_not_proposed json;
v_mincut_node json;
v_mincut_connec json;
v_mincut_arc json;
v_user_values json;


BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	--  get system values
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_project_type = (SELECT project_type FROM sys_version LIMIT 1);

	-- Get input parameters:
	v_selector_type := p_data->'data'->> 'selectorType';
	v_current_tab := p_data->'form'->> 'currentTab';
	v_filter_from_input := p_data->'data'->>'filterText';
	v_geometry := p_data->'data'->>'geometry';
	v_use_atlas := p_data->'data'->>'useAtlas';
	v_load_project := p_data->'data'->>'loadProject';
	v_message := p_data->'message';
	v_cur_user := p_data->'client'->>'cur_user';
	v_device := p_data->'client'->>'device';
	v_add_schema := p_data->'data'->>'addSchema';
	v_tiled := (p_data->'client'->>'tiled')::boolean;
	-- Backward compatible flag parsing: accepted in client/data and with both key casings.
	v_is_return_set_selectors := COALESCE(
		(p_data->'client'->>'isReturnSetSelectors')::boolean,
		(p_data->'client'->>'isReturnSetselectors')::boolean,
		(p_data->'data'->>'isReturnSetSelectors')::boolean,
		(p_data->'data'->>'isReturnSetselectors')::boolean
	);

	IF v_add_schema IS NOT NULL THEN v_tab_network_signal = -1; END IF;

	IF v_device is null then v_device = 4; END IF;

	v_prev_cur_user = current_user;
	IF v_cur_user IS NOT NULL THEN
		EXECUTE 'SET ROLE "'||v_cur_user||'"';
	END IF;

	-- profilactic control of schema name
	IF lower(v_add_schema) = 'none' OR v_add_schema = '' OR lower(v_add_schema) ='null' OR v_add_schema is null OR v_add_schema='NULL' THEN
		v_add_schema = null;
		v_exclude_tab = ' AND tabname != ''tab_exploitation_add''';
	END IF;
	-- profilactic control of message
	IF v_message is null THEN
		v_message = '{"level":111, "text":"Process done successfully"}';
	END IF;

	-- get system variables:
	v_expl_x_user = (SELECT value FROM config_param_system WHERE parameter = 'admin_exploitation_x_user');

	v_stylesheet = (SELECT value FROM config_param_system WHERE parameter = 'qgis_form_selector_stylesheet');

	-- when typeahead only one tab is executed
	IF v_filter_from_input IS NULL OR v_filter_from_input = '' OR lower(v_filter_from_input) ='None' or lower(v_filter_from_input) = 'null' THEN
		v_query_tab = '';
	ELSE
		v_query_tab = concat(' AND tabname = ', quote_literal(v_current_tab));
	END IF;

	-- get if user has a role to show macroexploitation and macrosector tabs or not
	v_selector_macro_tabs = (select selector_macro_tabs from cat_manager cm
	where exists (select 1 from pg_roles r
	where pg_has_role(current_user, r.oid, 'member')
	and r.rolname = any (cm.rolename)
	and selector_macro_tabs is not false) limit 1);

	-- Start the construction of the tabs array
	v_formTabs := '[';

	v_query = concat(
	'SELECT formname, tabname, label, tooltip, tabfunction, tabactions, value
	 FROM (SELECT formname, tabname, f.label, f.tooltip, tabfunction, tabactions, unnest(f.device) AS device, value, orderby FROM v_config_form_tabs f, config_param_system
	 WHERE formname=',quote_literal(v_selector_type),' AND isenabled IS TRUE AND concat(''basic_selector_'', tabname) = parameter ',(v_query_tab),
	'AND orderby >=',v_tab_network_signal,' AND sys_role IN (SELECT rolname FROM pg_roles WHERE pg_has_role(current_user, oid, ''member'')))a
	WHERE device = ',v_device, v_exclude_tab,' ORDER BY orderby');
	v_debug_vars := json_build_object('v_selector_type', v_selector_type, 'v_query_tab', v_query_tab);
	v_debug := json_build_object('querystring', v_query, 'vars', v_debug_vars, 'funcname', 'gw_fct_getselectors', 'flag', 10);
	raise notice 'v_query: %', v_query;
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;

	IF v_is_return_set_selectors IS FALSE OR v_is_return_set_selectors IS NULL THEN

		-- create temp tables related to expl x user variable
		EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"project_type":"'||v_project_type||'", "action":"DROP", "group":"SELECTOR"}}}$$)';
		EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"project_type":"'||v_project_type||'", "action":"CREATE", "group":"SELECTOR"}}}$$)';

		CREATE TEMP TABLE temp_muni_sector_expl AS
		WITH
			node_expl AS (
				SELECT nn.node_id, nn.expl_id
				FROM (
					SELECT n.node_id, n.expl_id
					FROM node n
					WHERE n.expl_id IS NOT NULL
					UNION
					SELECT n.node_id, unnest(n.expl_visibility) AS expl_id
					FROM node n
					WHERE n.expl_visibility IS NOT NULL
				) nn
				JOIN vf_exploitation e ON e.expl_id = nn.expl_id
				-- vf_exploitation is filtered by active AND expl_id > 0
			),
			node_muni AS (
				SELECT nn.node_id, nn.muni_id
				FROM (
					SELECT n.node_id, n.muni_id
					FROM node n
					WHERE n.muni_id IS NOT NULL
					UNION
					SELECT n.node_id, n.muni_id
					FROM node_x_municipality_visibility n
					WHERE n.muni_id IS NOT NULL
				) nn
				JOIN v_municipality m ON m.muni_id = nn.muni_id
				WHERE m.active
			),
			node_sector AS (
				SELECT nn.node_id, nn.sector_id
				FROM (
					SELECT n.node_id, n.sector_id
					FROM node n
					WHERE n.sector_id IS NOT NULL
					UNION
					SELECT n.node_id, n.sector_id
					FROM node_x_sector_visibility n
					WHERE n.sector_id IS NOT NULL
				) nn
				JOIN sector s ON s.sector_id = nn.sector_id
				WHERE s.active
			)
		SELECT DISTINCT nm.muni_id, ns.sector_id, ne.expl_id
		FROM node_expl ne
		JOIN node_muni nm ON nm.node_id = ne.node_id
		JOIN node_sector ns ON ns.node_id = ne.node_id;

		-- populate temp_network
		INSERT INTO temp_network (network_id, name, active)
		SELECT id::integer AS network_id, idval AS name, true AS active
		FROM om_typevalue WHERE typevalue = 'network_type' ORDER BY id;

		-- populate temp_exploitation
		INSERT INTO temp_exploitation (expl_id, code, name, descript, macroexpl_id, active)
		SELECT e.expl_id, e.code, e.name, e.descript, e.macroexpl_id, e.active
		FROM exploitation e
		JOIN vf_exploitation vf ON vf.expl_id = e.expl_id
		ORDER BY 1;

		-- populate temp_macroexploitation
		INSERT INTO temp_macroexploitation (macroexpl_id, code, name, descript, active)
		SELECT m.macroexpl_id, m.code, m.name, m.descript, m.active
		FROM macroexploitation m
		WHERE m.active AND m.macroexpl_id > 0
		AND EXISTS (SELECT 1 FROM temp_exploitation e WHERE e.macroexpl_id = m.macroexpl_id)
		ORDER BY 1;

		-- populate temp_municipality
		INSERT INTO temp_municipality (muni_id, name, observ, active)
		SELECT em.muni_id, em.name, em.observ, em.active
		FROM v_municipality em
		WHERE EXISTS (SELECT 1 FROM temp_muni_sector_expl t WHERE t.muni_id = em.muni_id)
		ORDER BY 1;

		-- populate temp_sector
		INSERT INTO temp_sector (sector_id, code, name, descript, expl_id, muni_id, macrosector_id, parent_id, active)
		SELECT s.sector_id, s.code, s.name, s.descript, s.expl_id, s.muni_id, s.macrosector_id, s.parent_id, s.active
		FROM sector s
		WHERE s.sector_id = 0;

		INSERT INTO temp_sector (sector_id, code, name, descript, expl_id, muni_id, macrosector_id, parent_id, active)
		SELECT s.sector_id, s.code, s.name, s.descript, s.expl_id, s.muni_id, s.macrosector_id, s.parent_id, s.active
		FROM sector s
		WHERE EXISTS (SELECT 1 FROM temp_muni_sector_expl t WHERE t.sector_id = s.sector_id)
		AND s.sector_id > 0
		ORDER BY 1;

		-- populate temp_macrosector
		INSERT INTO temp_macrosector (macrosector_id, code, name, descript, expl_id, muni_id, active)
		SELECT macrosector_id, code, name, descript, expl_id, muni_id, active
		FROM macrosector m
		WHERE m.active AND m.macrosector_id > 0
		AND EXISTS (SELECT 1 FROM temp_sector s WHERE s.macrosector_id = m.macrosector_id)
		ORDER BY 1;

		IF v_project_type = 'WS' THEN
			INSERT INTO temp_t_mincut (id, work_order, expl_id, macroexpl_id, muni_id, minsector_id, forecast_start, forecast_end)
			SELECT m.id, m.work_order, e.expl_id, m.macroexpl_id, m.muni_id, m.minsector_id, m.forecast_start, m.forecast_end
			FROM om_mincut m
			JOIN temp_exploitation e ON e.expl_id = m.expl_id
			WHERE m.id > 0
			ORDER BY m.id;
		END IF;
	END IF;

	-- starting loop for tabs
	FOR v_tab IN EXECUTE v_query
	LOOP

		IF v_selector_macro_tabs is null AND v_tab.tabname IN ('tab_macroexploitation', 'tab_macrosector') THEN
   			CONTINUE;
		END IF;

		-- get variables form input
		v_selector_list := (p_data ->> 'data')::json->> 'ids';
		v_filter_from_input := (p_data ->> 'data')::json->> 'filterText';

		-- get variables from tab
		v_label = v_tab.value::json->>'label';
		v_table = v_tab.value::json->>'table';
		v_table_id = v_tab.value::json->>'table_id';
		v_selector = v_tab.value::json->>'selector';
		v_selector_id = v_tab.value::json->>'selector_id';
		v_filter_from_config = v_tab.value::json->>'query_filter';
		v_manage_all = v_tab.value::json->>'manageAll';
		v_typeahead = v_tab.value::json->>'typeaheadFilter';
		v_selection_mode = v_tab.value::json->>'selectionMode';
		v_orderby = v_tab.value::json->>'orderBy';
		v_name = v_tab.value::json->>'name';
		v_typeahead_forced = v_tab.value::json->>'typeaheadForced';
		v_order_by_check = v_tab.value::json->>'orderbyCheck';
		v_has_custom_order_by = v_tab.value::json->>'hasCustomOrderBy';

		-- profilactic control of v_orderby
		v_query_string = concat('SELECT gw_fct_getpkeyfield(''',v_table,''');');
		v_debug_vars := json_build_object('v_table', v_table);
		v_debug := json_build_object('querystring', v_query_string, 'vars', v_debug_vars, 'funcname', 'gw_fct_getselectors', 'flag', 20);
		SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
		EXECUTE v_query_string INTO v_pkey_field;
		IF v_orderby IS NULL THEN v_orderby = v_pkey_field; end if;
		IF v_name IS NULL THEN v_name = v_orderby; end if;

		-- profilactic control of selection mode
		IF v_selection_mode = '' OR v_selection_mode is null then
			v_selection_mode = 'keepPrevious';
		END IF;

		IF v_has_custom_order_by THEN
			EXECUTE format(
				'SELECT value::jsonb->''%s''->>''order_by_column'' FROM config_param_user cpu WHERE PARAMETER = ''custom_order_by'' AND (value::jsonb->''%s''->>''is_checked'')::boolean IS TRUE AND cur_user = ''%s''',
				v_tab.tabname,
				v_tab.tabname,
				current_user
			) INTO v_custom_order_by_column;
			IF v_custom_order_by_column IS NOT NULL THEN
				v_orderby_query = 'ORDER BY ' || v_custom_order_by_column || ' DESC, orderby';
			END IF;
		ELSIF v_order_by_check THEN
			v_orderby_query = 'ORDER BY value DESC, orderby';
		END IF;

		IF v_orderby_query IS NULL THEN
			v_orderby_query = 'ORDER BY orderby';
		END IF;

		-- built filter from input
		IF v_filter_from_input IS NULL OR v_filter_from_input = '' OR lower(v_filter_from_input) ='None' or lower(v_filter_from_input) = 'null' THEN
			v_filter_from_input := NULL;
		ELSE
			v_filter_from_input = concat (v_typeahead,' LIKE ''%', lower(v_filter_from_input), '%''');
		END IF;


		-- Manage filters from ids (only mincut)
		IF v_selector = 'selector_mincut_result' THEN
			v_selector_list = replace(replace(v_selector_list, '[', '('), ']', ')');
			IF v_selector_list != '' THEN
				v_filter_from_ids = ' AND ' || v_table_id || ' IN '|| v_selector_list || ' ';
			END IF;
			-- always order descending for mincut
			v_orderby_query = 'ORDER BY orderby DESC';
		END IF;

		-- built full filter
		v_full_filter = concat(v_filter_from_ids, v_filter_from_config, v_filter_from_input);

		-- use atlas on psector selector
		IF v_use_atlas AND v_tab.tabname ='tab_psector' THEN
			v_orderby = 'atlas_id::integer';
			v_name = 'concat(row_number() over(order by atlas_id::integer), ''-'',name)';
		END IF;

		-- filter out archived psectors (status 5, 6, 7 = archived)
		IF v_tab.tabname = 'tab_psector' THEN
			v_full_filter = concat(v_full_filter, ' AND (status NOT IN (''5'', ''6'', ''7'') OR status IS NULL)');
		END IF;

		-- profilactic null control
		v_full_filter := COALESCE(v_full_filter, '');

		-- setting schema add
		IF v_tab.tabname like '%add%' AND v_add_schema IS NOT  NULL THEN
			v_table = concat(v_add_schema,'.',v_table);
			v_selector = concat(v_add_schema,'.',v_selector);
		END IF;

		-- final query
		-- Add conditional active filter (not applicable for mincut selector)
		IF v_selector = 'selector_mincut_result' THEN
			v_final_query = concat('SELECT array_to_json(array_agg(row_to_json(b))) FROM (
					select *, row_number() OVER (',v_orderby_query,') as orderby from (
					SELECT ',quote_ident(v_table_id),', concat(' , v_label , ') AS label, ',v_name,' as name, ', v_table_id , '::text as widgetname, ' ,
					v_orderby, ' as orderby , ''', v_selector_id , ''' as columnname, ''check'' as type, ''boolean'' as "dataType",
					EXISTS (SELECT ', v_selector_id, ' FROM ', v_selector, ' e WHERE e.', v_selector_id, ' = s.', v_table_id, ' and cur_user=current_user) as "value", null as active,
					null as stylesheet
					FROM ', v_table ,' s WHERE TRUE ', v_full_filter, ' ) a)b');
		ELSE
			v_final_query = concat('SELECT array_to_json(array_agg(row_to_json(b))) FROM (
					select *, row_number() OVER (',v_orderby_query,') as orderby from (
					SELECT ',quote_ident(v_table_id),', concat(' , v_label , ') AS label, ',v_name,' as name, ', v_table_id , '::text as widgetname, ' ,
					v_orderby, ' as orderby , ''', v_selector_id , ''' as columnname, ''check'' as type, ''boolean'' as "dataType",
					EXISTS (SELECT ', v_selector_id, ' FROM ', v_selector, ' e WHERE e.', v_selector_id, ' = s.', v_table_id, ' and cur_user=current_user) as "value", active,
					case when EXISTS(SELECT ', v_table_id, ' FROM ', v_table, ' e WHERE active and e.', v_table_id, ' = s.', v_table_id, ') is not true then ''color: lightgray; font-style: italic;'' end as stylesheet
					FROM ', v_table ,' s WHERE TRUE ', v_full_filter, ' ) a)b');
		END IF;

		v_debug_vars := json_build_object('v_table_id', v_table_id, 'v_label', v_label, 'v_orderby', v_orderby, 'v_name', v_name, 'v_selector_id', v_selector_id,
						  'v_table', v_table, 'v_selector', v_selector, 'current_user', current_user, 'v_full_filter', v_full_filter);
		v_debug := json_build_object('querystring', v_final_query, 'vars', v_debug_vars, 'funcname', 'gw_fct_getselectors', 'flag', 30);
		SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;


		EXECUTE  v_final_query INTO v_form_tabs_aux;

		-- Add tab name to json
		IF v_form_tabs_aux IS NULL THEN
			v_form_tabs_aux := ('{"fields":[]}')::json;
		ELSE
			v_form_tabs_aux := ('{"fields":' || v_form_tabs_aux || '}')::json;
		END IF;

		-- setting other variables of tab
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'tabName', v_tab.tabname::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'tableName', v_selector);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'tabLabel', v_tab.label::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'tooltip', v_tab.tooltip::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'selectorType', v_tab.formname::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'manageAll', v_manage_all::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'typeaheadFilter', v_typeahead::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'selectionMode', v_selection_mode::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'typeaheadForced', v_typeahead_forced::TEXT);
		v_form_tabs_aux := gw_fct_json_object_set_key(v_form_tabs_aux, 'hasCustomOrderBy', v_has_custom_order_by::TEXT);

		-- Create tabs array
		IF v_first_tab THEN
			v_formTabs := v_formTabs || ',' || v_form_tabs_aux::text;
		ELSE
			v_formTabs := v_formTabs || v_form_tabs_aux::text;
		END IF;
		v_first_tab := TRUE;

	END LOOP;

	-- Manage web client
	IF v_device = 5 THEN

		-- Get active exploitations geometry (to zoom on them)
		IF v_load_project IS TRUE AND v_geometry IS NULL THEN
			SELECT row_to_json (a)
			INTO v_geometry
			FROM (SELECT st_xmin(the_geom)::numeric(12,2) as x1, st_ymin(the_geom)::numeric(12,2) as y1, st_xmax(the_geom)::numeric(12,2) as x2, st_ymax(the_geom)::numeric(12,2) as y2
			FROM (SELECT st_expand(st_extent(the_geom)::geometry, 50.0) as the_geom FROM exploitation where expl_id IN (SELECT expl_id FROM selector_expl WHERE cur_user = current_user)) b) a;
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
	v_manage_all := COALESCE(v_manage_all, FALSE);
	v_has_custom_order_by := COALESCE(v_has_custom_order_by, FALSE);
	v_selection_mode = COALESCE(v_selection_mode, '');
	v_current_tab = COALESCE(v_current_tab, '');
	v_geometry = COALESCE(v_geometry, '{}');
	v_stylesheet := COALESCE(v_stylesheet, '{}');
	v_mincut_init = COALESCE(v_mincut_init, '[]');
	v_mincut_valve_proposed = COALESCE(v_mincut_valve_proposed, '[]');
	v_mincut_valve_not_proposed = COALESCE(v_mincut_valve_not_proposed, '[]');
	v_mincut_node = COALESCE(v_mincut_node, '[]');
	v_mincut_connec = COALESCE(v_mincut_connec, '[]');
	v_mincut_arc = COALESCE(v_mincut_arc, '[]');
	v_user_values = COALESCE(v_user_values, '{}');
	v_tiled = COALESCE(v_tiled, FALSE);

	EXECUTE 'SET ROLE "'||v_prev_cur_user||'"';

	-- Return
	IF v_first_tab IS FALSE THEN
		-- Return not implemented
		RETURN ('{"status":"Accepted"' ||
		', "version":"'|| v_version ||'"'||
		', "message":"Not implemented"'||
		'}')::json;
	ELSE
		v_user_values := COALESCE(json_extract_path_text(p_data,'data','userValues'),
			(SELECT to_json(array_agg(row_to_json(a))) FROM (SELECT parameter, value FROM config_param_user WHERE parameter IN ('plan_psector_current', 'utils_workspace_current') AND cur_user = current_user ORDER BY parameter)a)::text,
			'{}');
		v_action := json_extract_path_text(p_data,'data','action');
		IF v_action = '' THEN v_action = NULL; END IF;

		-- Return formtabs
		RETURN gw_fct_json_create_return(('{"status":"Accepted", "version":"'||v_version||'"'||
			',"body":{"message":'||v_message||
			',"form":{"formName":"", "formLabel":"", "currentTab":"'||v_current_tab||'", "formText":"", "formTabs":'||v_formTabs||', "style": '||v_stylesheet||'}'||
			',"feature":{}'||
			',"data":{
				"userValues":'||v_user_values||',
				"geometry":'||v_geometry||
				(case when v_selector_type = 'selector_mincut' then ',
					"tiled":'||v_tiled||',
					"mincutInit":'||v_mincut_init||',
					"mincutProposedValve":'||v_mincut_valve_proposed||',
					"mincutNotProposedValve":'||v_mincut_valve_not_proposed||',
					"mincutNode":'||v_mincut_node||',
					"mincutConnec":'||v_mincut_connec||',
					"mincutArc":'||v_mincut_arc else '' end ) ||
				'}'||
			'}'||
		    '}')::json,2796, null, null, v_action::json);
	END IF;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"project_type":"'||v_project_type||'", "action":"DROP", "group":"SELECTOR"}}}$$)';
	RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE, 'MSGERR', (v_msgerr::json ->> 'MSGERR'))::json;

END;
$function$
;

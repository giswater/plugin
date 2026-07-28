/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2618

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_api_setsearch (json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setsearch(p_data json)
  RETURNS json AS
$BODY$

/*example
SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"addNetwork"}, "feature":{},
"data":{"filterFields":{}, "pageInfo":{}, "net_type":{"id":"ve_arc", "name":"Arcs"}, "searchType":"arc", "net_code":{"text":"3"}}}$$);

SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"network"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "searchType":"None", "net_type":{"id":"", "name":""}, "net_code":{"text":"e"}, "addSchema":"None"}}$$);

SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"workcat"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "workcat_search":{"text":"w"}, "addSchema":"None"}}$$);

SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"addNetwork"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "net_type":{"id":"", "name":""}, "net_code":{"text":"3"}, "addSchema":"ud"}}$$);

SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"network"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "searchType":"None", "net_type":{"id":"", "name":""}, "net_code":{"text":"3"}, "addSchema":"ud"}}$$);

SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"network"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "searchType":"None", "net_type":{"id":"", "name":""}, "net_code":{"text":"3"}, "addSchema":"None"}}$$);

SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"network"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "searchType":"arc", "net_type":{"id":"ve_arc", "name":"Arcs"}, "net_code":{"text":"5"}, "addSchema":"None"}}$$);

SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"add_network"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "net_type":{"id":"", "name":""}, "net_code":{"text":"3"}, "addSchema":"ud"}}$$);


 SELECT gw_fct_setsearch($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{"tabName":"add_network"}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "net_type":{"id":"", "name":""}, "net_code":{"text":"4"}, "addSchema":"ud"}}$$);

MAIN ISSUES
-----------
- basic_search_network is key issue to define variables on config_param_system to searh anything you want
- Second schema is avaliable to search

*/

DECLARE

v_response json;
v_name varchar;
v_idarg varchar;
v_textarg varchar;
v_tab varchar;
v_combo json;
v_edittext json;
v_version text;
v_projecttype character varying;
v_count integer;
v_querytext text;
v_searchtype text;
v_partial text;

--network
v_network_layername text;
v_network_idname text;
v_network_code text;
v_network_catalog text;
v_value text;
v_network_all json;

--muni
v_muni_layer varchar;
v_muni_id_field varchar;
v_muni_display_field varchar;
v_muni_geom_field varchar;

-- street
v_street_layer varchar;
v_street_id_field varchar;
v_street_search_field varchar;
v_street_display_field varchar;
v_street_muni_id_field varchar;
v_street_geom_field varchar;

-- address
v_address_layer varchar;
v_address_id_field varchar;
v_address_display_field varchar;
v_address_street_id_field varchar;
v_address_geom_id_field varchar;

--hydro
v_hydro_layer varchar;
v_hydro_id_field varchar;
v_hydro_feature_field varchar;
v_hydro_search_field_1 varchar;
v_hydro_search_field_2 varchar;
v_hydro_search_field_3 varchar;
v_hydro_parent_field varchar;

--workcat
v_workcat_layer varchar;
v_workcat_id_field varchar;
v_workcat_display_field varchar;
v_workcat_geom_field varchar;
v_filter_text varchar;

--visit
v_visit_layer varchar;
v_visit_id_field varchar;
v_visit_display_field varchar;
v_visit_geom_field varchar;

--psector
v_psector_layer varchar;
v_psector_id_field varchar;
v_psector_display_field varchar;
v_psector_parent_field varchar;
v_psector_geom_field varchar;

--exploitation
v_exploitation_layer varchar;
v_exploitation_id_field varchar;
v_exploitation_display_field varchar;
v_exploitation_geom_field varchar;

v_schemaname text;
v_addschema text;

v_hydro_contains text;

v_srid integer;
v_return json;
v_flag boolean = false;

v_tablename text;
v_geometry json;
v_executepk text;
v_id text;
v_section text;
v_json_value json;
v_result text;
v_filter_key text;
v_filter_value text;
v_exec_func text;
v_table_name text;
v_search_add text;
v_device integer;
v_xcoord float;
v_ycoord float;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	-- Set api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Get project type
	SELECT project_type INTO v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT epsg INTO v_srid FROM sys_version ORDER BY id DESC LIMIT 1;


	-- Get unified payload (v2)
	v_section := ((p_data->>'data')::json)->>'section';
	v_value := (p_data->>'data')::json->>'value';
	v_filter_key := (p_data->>'data')::json->>'filterKey';
	v_filter_value := (p_data->>'data')::json->>'filterValue';
	v_exec_func := (p_data->>'data')::json->>'execFunc';
	v_table_name := (p_data->>'data')::json->>'tableName';
	v_search_add = ((p_data ->>'data')::json->>'searchAdd');
	if v_filter_value = 'undefined' then
		v_filter_value = v_value;
	end if;

	if v_section ilike 'basic_search_v2_tab_network%' then
		EXECUTE 'SELECT row_to_json(row) FROM (SELECT ST_x(ST_centroid(ST_envelope(the_geom))) AS xcoord, ST_y(ST_centroid(ST_envelope(the_geom))) AS ycoord, St_AsText(the_geom) FROM '||v_table_name||
		' WHERE '||v_filter_key||' = ('||quote_nullable(v_filter_value)||'))row'
		INTO v_geometry;
	elsif v_section = 'basic_search_v2_tab_address' and v_search_add = 'true' then

		EXECUTE 'SELECT row_to_json(row) FROM (SELECT st_x (a.the_geom) as xcoord, st_y (a.the_geom) as  ycoord, St_AsText(a.the_geom) FROM ve_streetaxis s join v_municipality m using(muni_id) left join ve_address a on s.id = a.streetaxis_id
		 WHERE concat(s.name, '', '', m.name, '', '', a.postnumber) = ('||quote_nullable(v_filter_value)||'))row'
		INTO v_geometry;

	elsif v_section = 'basic_search_v2_tab_address' then
		EXECUTE 'SELECT row_to_json(row) FROM (SELECT ST_x(ST_centroid(ST_envelope(the_geom))) AS xcoord, ST_y(ST_centroid(ST_envelope(the_geom))) AS ycoord, St_AsText(the_geom) FROM ve_streetaxis '||
		' s WHERE '||v_filter_key||' = ('||quote_nullable(v_filter_value)||'))row'
		INTO v_geometry;
	elsif v_section = 'basic_search_v2_tab_psector' then
		EXECUTE 'SELECT row_to_json(row) FROM (SELECT ST_x(ST_centroid(ST_envelope(the_geom))) AS xcoord, ST_y(ST_centroid(ST_envelope(the_geom))) AS ycoord, St_AsText(the_geom) FROM '||quote_ident(v_table_name)||
		' WHERE '||quote_ident(v_filter_key)||' = ('||quote_nullable(v_filter_value)||'))row'
		INTO v_geometry;
	elsif v_section = 'basic_search_v2_tab_visit' then
		EXECUTE 'SELECT row_to_json(row) FROM (SELECT ST_x(ST_centroid(ST_envelope(the_geom))) AS xcoord, ST_y(ST_centroid(ST_envelope(the_geom))) AS ycoord, St_AsText(the_geom) FROM '||quote_ident(v_table_name)||
		' WHERE '||quote_ident(v_filter_key)||' = ('||quote_nullable(v_filter_value)||') AND the_geom IS NOT NULL)row'
		INTO v_geometry;
	elsif v_section = 'basic_search_v2_tab_workcat' then

		execute 'SELECT row_to_json(row) FROM (SELECT
			CASE
			WHEN st_geometrytype(st_concavehull(st_simplify(d.the_geom, 1), 0.99::double precision)) = ''ST_Polygon''::text
			THEN st_astext(st_buffer(st_concavehull(st_simplify(d.the_geom, 1), 0.99::double precision), 10::double precision)::geometry(Polygon, '||v_srid||'))
			ELSE st_astext(st_expand(st_buffer(d.the_geom, 10::double precision), 1::double precision)::geometry(Polygon, '||v_srid||'))
			END AS st_astext
			FROM (SELECT st_collect(a.the_geom) AS the_geom, a.workcat_id FROM (  SELECT node.workcat_id, node.the_geom FROM node WHERE node.state = 1
					UNION
					 SELECT arc.workcat_id, arc.the_geom FROM arc WHERE arc.state = 1
					UNION
					 SELECT connec.workcat_id, connec.the_geom FROM connec WHERE connec.state = 1
					UNION
					 SELECT element.workcat_id, element.the_geom FROM element WHERE element.state = 1
					UNION
					  SELECT node.workcat_id_end AS workcat_id,node.the_geom FROM node WHERE node.state = 0
					UNION
					  SELECT arc.workcat_id_end AS workcat_id, arc.the_geom FROM arc WHERE arc.state = 0
					UNION
					 SELECT connec.workcat_id_end AS workcat_id,connec.the_geom FROM connec WHERE connec.state = 0
					UNION
					 SELECT element.workcat_id_end AS workcat_id, element.the_geom FROM element WHERE element.state = 0) a GROUP BY a.workcat_id ) d

			JOIN cat_work AS b ON d.workcat_id = b.id WHERE b.id::text ILIKE '||quote_nullable(v_filter_value)||' LIMIT 10 )row'
		into v_geometry;
	elsif v_section = 'basic_search_v2_tab_coordinates' then
		v_xcoord = split_part(v_value,',',1);
		v_ycoord = split_part(v_value,',',2);

		EXECUTE 'SELECT row_to_json(row) FROM (SELECT '||v_xcoord||' as xcoord, '||v_ycoord||' as ycoord, St_AsText(ST_Point('||v_xcoord||','||v_ycoord||')))row'
		INTO v_geometry;

	end if;

	v_response = gw_fct_json_object_set_key (v_response, 'geometry', v_geometry);
	v_response = gw_fct_json_object_set_key (v_response, 'execFunc', v_exec_func);
	v_response = gw_fct_json_object_set_key (v_response, 'funcTable', v_table_name);
	v_response = gw_fct_json_object_set_key (v_response, 'funcValue', v_filter_value);

	-- Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted"' || ', "version":"'|| v_version ||'"'||
		', "data":' || v_response ||
		'}')::json, 2618, null, null, null);

	-- exception handling
	EXCEPTION WHEN OTHERS THEN
	RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE)::json;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

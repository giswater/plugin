/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 2714
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_setfeaturereplace(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setfeaturereplace (p_data json)
RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_setfeaturereplace($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{"type":"NODE"},
"data":{"old_feature_id":"129","workcat_id_end":"work1", "enddate":"2019-05-17","keep_elements":true }}$$)

SELECT SCHEMA_NAME.gw_fct_setfeaturereplace($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{"type":"ARC"},
"data":{"old_feature_id":"2067","workcat_id_end":"work1", "enddate":"2019-05-17","keep_elements":true }}$$)

-- fid: 143

*/

DECLARE

v_the_geom public.geometry;
v_query_string_select text;
v_query_string_insert text;
v_query_string_update text;
v_column varchar;
v_value text;
v_muni_id integer;
v_state integer;
v_state_type integer;
v_old_epa_type text;
v_epa_type_new text;
rec_arc record;
v_old_featuretype varchar;
v_old_featurecat varchar;
v_sector_id integer;
v_dma_id integer;
v_omzone_id integer;
v_expl_id integer;
v_man_table varchar;
v_epa_table varchar;
v_epa_table_new varchar;
v_code text;
v_id int8;
v_old_id integer;
v_workcat_id_end varchar;
v_enddate date;
v_keep_elements boolean;
v_feature_type text;
v_feature_layer text;
v_id_column text;
v_feature_type_table text;
v_type_column text;
v_cat_column text;
v_sql text;
v_element_table text;
v_verified_id integer;
v_inventory boolean;
v_connec_proximity_value text;
v_connec_proximity_active text;
v_result_id text= 'replace feature';
v_project_type text;
v_version text;
v_result text;
v_result_info text;
v_arc_searchnodes_value text;
v_arc_searchnodes_active text;
v_error_context text;
v_audit_result text;
v_level integer;
v_status text;
v_message text;
rec_addfields record;
v_count integer;
v_field_cat text;
v_feature_type_new text;
v_featurecat_id_new text;
v_mapzone_old text[];
v_mapzone_new text[];
v_fid integer = 143;
v_gully_proximity_value text;
v_gully_proximity_active text;
v_category text;
v_function text;
v_fluid text;
v_location text;
v_node1_graph text[];
v_node_1 text;
v_node2_graph  text[];
v_node_2 text;
rec_connec record;
rec_link record;
rec_gully record;
v_dqa_id integer;
v_minsector_id integer;
v_dwfzone_id integer;
v_presszone_id integer;
v_feature_childtable_name_old text;
v_feature_childtable_name_new text;
v_schemaname text;
v_code_autofill_bool boolean;
v_link text;
v_nodetype text;
v_check_featurecat_id boolean;
v_keep_sys_code boolean;
v_keep_customer_code boolean;
v_excluded_columns text;

BEGIN

	-- Search path
	SET search_path = 'SCHEMA_NAME', public;
	v_schemaname = 'SCHEMA_NAME';

	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;


	SELECT  value::json->>'value' as value INTO v_arc_searchnodes_value FROM config_param_system where parameter = 'edit_arc_searchnodes';
	SELECT  value::json->>'activated' INTO v_arc_searchnodes_active FROM config_param_system where parameter = 'edit_arc_searchnodes';

	-- manage log (fid: 143)
	DELETE FROM audit_check_data WHERE fid = v_fid AND cur_user=current_user;

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{}, "data":{"function":"2714", "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "criticity":"1", "is_process":true, "is_header":"true"}}$$)';

	-- get input parameters

	v_feature_type = lower(((p_data ->>'feature')::json->>'type'))::text;
	v_old_id = ((p_data ->>'data')::json->>'old_feature_id')::integer;
	v_workcat_id_end = ((p_data ->>'data')::json->>'workcat_id_end')::text;
	v_enddate = ((p_data ->>'data')::json->>'enddate')::text;
	v_keep_elements = ((p_data ->>'data')::json->>'keep_elements')::text;
	v_feature_type_new = ((p_data ->>'data')::json->>'feature_type_new')::text;
	v_featurecat_id_new = ((p_data ->>'data')::json->>'featurecat_id')::text;
	v_keep_sys_code = COALESCE(((p_data ->>'data')::json->>'keep_sys_code')::boolean, false);
	v_keep_customer_code = COALESCE(((p_data ->>'data')::json->>'keep_customer_code')::boolean, false);

	EXECUTE format('SELECT 1 FROM cat_%I WHERE %I_type = %L AND id = %L', v_feature_type, v_feature_type, v_feature_type_new, v_featurecat_id_new) INTO v_check_featurecat_id;
	IF v_check_featurecat_id IS NOT TRUE THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"4464", "function":"2714","parameters":null, "is_process":true}}$$);';
	END IF;

	--deactivate connec proximity control
	IF v_feature_type='connec' THEN
		SELECT  value::json->>'value' as value INTO v_connec_proximity_value FROM config_param_system where parameter = 'edit_connec_proximity';
		SELECT  value::json->>'activated' INTO v_connec_proximity_active FROM config_param_system where parameter = 'edit_connec_proximity';
		UPDATE config_param_system SET value ='{"activated":false,"value":0.1}' WHERE parameter='edit_connec_proximity';
	END IF;

	--deactivate gully proximity control
	IF v_feature_type='gully' THEN
		SELECT value::json->>'value' as value INTO v_gully_proximity_value FROM config_param_system WHERE parameter = 'edit_gully_proximity';
		SELECT value::json->>'activated' INTO v_gully_proximity_active FROM config_param_system WHERE parameter = 'edit_gully_proximity';
		UPDATE config_param_system SET value = '{"activated":false,"value":0.1}' WHERE parameter = 'edit_gully_proximity';
	END IF;

	--define columns used for feature_cat
	v_feature_layer = concat('ve_',v_feature_type);
	v_feature_type_table = concat('cat_feature_',v_feature_type);
	v_id_column:=concat(v_feature_type,'_id');
	v_type_column=concat(v_feature_type,'_type');
	v_cat_column=concat(v_feature_type,'cat_id');


	--capture old feature type and old feature catalog
	EXECUTE 'SELECT '||v_type_column||'  FROM '|| v_feature_layer  ||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO  v_old_featuretype;

	EXECUTE 'SELECT  '|| v_cat_column||' FROM '|| v_feature_layer  ||'  WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_old_featurecat;

	EXECUTE 'SELECT epa_type FROM '|| v_feature_layer  ||'  WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_old_epa_type;

	EXECUTE 'SELECT muni_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_muni_id;
	EXECUTE 'SELECT sector_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_sector_id;
	EXECUTE 'SELECT state_type FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_state_type;
	EXECUTE 'SELECT state FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_state;
	EXECUTE 'SELECT omzone_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_omzone_id;
	EXECUTE 'SELECT the_geom FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_the_geom;
	EXECUTE 'SELECT expl_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_expl_id;
	EXECUTE 'SELECT verified FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_verified_id;
	EXECUTE 'SELECT inventory FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
	INTO v_inventory;
	EXECUTE 'SELECT n.category_type FROM '||v_feature_layer||' n JOIN man_type_category m ON n.category_type=m.category_type
	WHERE m.feature_type IS NULL OR'''||upper(v_feature_type)||''' = ANY(m.feature_type) AND 
	(featurecat_id IS NULL OR '''||v_feature_type_new||''' = ANY(featurecat_id::text[])) AND '||v_id_column||'='''||v_old_id||''';'
	INTO v_category;
	EXECUTE 'SELECT n.function_type FROM '||v_feature_layer||' n JOIN man_type_function m ON n.function_type=m.function_type
	WHERE m.feature_type IS NULL OR'''||upper(v_feature_type)||''' = ANY(m.feature_type) AND 
	(featurecat_id IS NULL OR '''||v_feature_type_new||''' = ANY(featurecat_id::text[])) AND '||v_id_column||'='''||v_old_id||''';'
	INTO v_function;

	IF v_project_type = 'WS' THEN
		EXECUTE 'SELECT n.fluid_type FROM '||v_feature_layer||' n JOIN man_type_fluid m ON n.fluid_type=m.fluid_type
		WHERE m.feature_type IS NULL OR'''||upper(v_feature_type)||''' = ANY(m.feature_type) AND 
		(featurecat_id IS NULL OR '''||v_feature_type_new||''' = ANY(featurecat_id::text[])) AND '||v_id_column||'='''||v_old_id||''';'
		INTO v_fluid;
	END IF;


	EXECUTE 'SELECT n.location_type FROM '||v_feature_layer||' n JOIN man_type_location m ON n.location_type=m.location_type
	WHERE m.feature_type IS NULL OR'''||upper(v_feature_type)||''' = ANY(m.feature_type) AND 
	(featurecat_id IS NULL OR '''||v_feature_type_new||''' = ANY(featurecat_id::text[])) AND '||v_id_column||'='''||v_old_id||''';'
	INTO v_location;

	IF v_project_type = 'WS' THEN
		EXECUTE 'SELECT dma_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
		INTO v_dma_id;
		EXECUTE 'SELECT minsector_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
		INTO v_minsector_id;
		EXECUTE 'SELECT dqa_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
		INTO v_dqa_id;
		EXECUTE 'SELECT presszone_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
		INTO v_presszone_id;
	ELSIF v_project_type = 'UD' THEN
		EXECUTE 'SELECT dwfzone_id FROM '||v_feature_layer||' WHERE '||v_id_column||'='''||v_old_id||''';'
		INTO v_dwfzone_id;
	END IF;

	-- epa
	IF v_feature_type ='connec' AND v_project_type = 'UD' THEN
		-- is not epa
	ELSE
		EXECUTE 'select epa_default from cat_feature_'||v_feature_type||' where id='''||v_feature_type_new||''';'
		INTO v_epa_type_new;

		IF v_epa_type_new <> 'UNDEFINED' AND v_feature_type IN ('arc', 'node') THEN
			v_epa_table_new = concat('inp_', lower(v_epa_type_new));
		ELSIF v_feature_type = 'connec' THEN
			v_epa_table_new = 'inp_connec';
		END IF;
	END IF;

	-- Control of state(1)
	IF (v_state=0 OR v_state=2 OR v_state IS NULL) THEN
		v_state = 0;
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"1070", "function":"2714","parameters":{"state_id": '||v_state||'}, "is_process":true}}$$);' INTO v_audit_result;

		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;

		v_id := v_old_id;
	ELSE

		-- new feature_id
		v_id := (SELECT nextval('SCHEMA_NAME.urn_id_seq'));

		-- Code
		IF v_project_type='WS' then
			EXECUTE 'SELECT code_autofill FROM cat_feature 
			JOIN cat_'||v_feature_type||' a ON cat_feature.id=a.'||v_feature_type||'_type 
			WHERE a.id='||quote_literal(v_featurecat_id_new)||';' INTO v_code_autofill_bool;
		ELSE
			EXECUTE 'SELECT code_autofill FROM cat_feature 
			WHERE id='||quote_literal(v_feature_type_new)||';' INTO v_code_autofill_bool;
		END IF;

		v_code := gw_fct_generate_code('feature', v_feature_type_new, json_strip_nulls(json_build_object(
			v_id_column, v_id,
			v_type_column, v_feature_type_new,
			'the_geom', CASE WHEN v_the_geom IS NOT NULL THEN ST_AsGeoJSON(v_the_geom)::json END,
			'sector_id', v_sector_id,
			'dma_id', v_dma_id,
			'omzone_id', v_omzone_id,
			'dqa_id', v_dqa_id,
			'presszone_id', v_presszone_id,
			'dwfzone_id', v_dwfzone_id,
			'minsector_id', v_minsector_id
		)));

		--Copy id to code field
		IF (v_code_autofill_bool IS TRUE) AND v_code IS NULL THEN
			v_code = v_id;
		END IF;

		-- LINK
		--google maps style
		IF (SELECT (value::json->>'google_maps')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			v_link=CONCAT ('https://www.google.com/maps/place/',(ST_Y(ST_transform(NEW.the_geom,4326))),'N+',(ST_X(ST_transform(NEW.the_geom,4326))),'E');
		--fid style
		ELSIF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			v_link=v_id;
		END IF;

		-- inserting new feature on parent tables
		IF v_feature_type='node' THEN

			IF v_project_type='WS' then
				INSERT INTO node (node_id, code, nodecat_id, epa_type, sector_id, dma_id, omzone_id, expl_id, muni_id, state, state_type, workcat_id, the_geom,
				category_type, function_type, fluid_type, location_type, minsector_id, dqa_id, presszone_id, link)
				VALUES (v_id, v_code, v_old_featurecat, v_epa_type_new, v_sector_id, v_dma_id, v_omzone_id, v_expl_id, v_muni_id,
				0, v_state_type, v_workcat_id_end, v_the_geom, v_category, v_function, v_fluid, v_location, v_minsector_id, v_dqa_id, v_presszone_id, v_link);
			ELSE
				INSERT INTO node (node_id, code, node_type, nodecat_id, epa_type, sector_id, omzone_id, expl_id, muni_id, state, state_type, workcat_id,
				the_geom, category_type, function_type, fluid_type, location_type, link, dwfzone_id)
				VALUES (v_id, v_code, v_old_featuretype, v_old_featurecat, v_epa_type_new, v_sector_id, v_omzone_id, v_expl_id, v_muni_id,
				0, v_state_type, v_workcat_id_end, v_the_geom, v_category, v_function, 0, v_location, v_link, v_dwfzone_id);

			END IF;

			INSERT INTO audit_check_data (fid, result_id, error_message)
			VALUES (v_fid, v_result_id, concat('New feature (',v_id,') inserted into node table.'));
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3346", "function":"2714", "parameters":{"v_id":"'||v_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';


		ELSIF v_feature_type='arc' THEN

			IF v_project_type='WS' then
				INSERT INTO arc (arc_id, code, arccat_id, epa_type, sector_id, dma_id, omzone_id, expl_id, muni_id, state, state_type, workcat_id, the_geom,
				verified, category_type, function_type, fluid_type, location_type, minsector_id, dqa_id, presszone_id, link)
				VALUES (v_id, v_code, v_old_featurecat, v_epa_type_new, v_sector_id, v_dma_id, v_omzone_id, v_expl_id, v_muni_id, 0, v_state_type, v_workcat_id_end, v_the_geom,
				v_verified_id, v_category, v_function, v_fluid, v_location, v_minsector_id, v_dqa_id, v_presszone_id, v_link);
			ELSE
				INSERT INTO arc (arc_id, code, arc_type, arccat_id, epa_type, sector_id, omzone_id, expl_id, muni_id, state, state_type, workcat_id, the_geom,
				verified, category_type, function_type, fluid_type, location_type, link, dwfzone_id)
				VALUES (v_id, v_code, v_old_featuretype, v_old_featurecat, v_epa_type_new, v_sector_id, v_omzone_id, v_expl_id, v_muni_id, 0, v_state_type, v_workcat_id_end,
				v_the_geom, v_verified_id, v_category, v_function, 0, v_location, v_link, v_dwfzone_id);
			END IF;


			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3318", "function":"2714", "parameters":{"v_id":"'||v_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

		ELSIF v_feature_type ='connec' THEN

			IF v_project_type='WS' then
				INSERT INTO connec (connec_id, code, conneccat_id, sector_id, dma_id, omzone_id, expl_id, muni_id, state, state_type, the_geom, workcat_id, verified,
				inventory, category_type, function_type, fluid_type, location_type,epa_type, minsector_id, dqa_id, presszone_id, link)
				VALUES (v_id, v_code, v_old_featurecat, v_sector_id, v_dma_id, v_omzone_id, v_expl_id, v_muni_id, 0, v_state_type, v_the_geom, v_workcat_id_end, v_verified_id,
				v_inventory, v_category, v_function, v_fluid, v_location, v_epa_type_new, v_minsector_id, v_dqa_id, v_presszone_id, v_link);
			ELSE
				INSERT INTO connec (connec_id, code, connec_type, conneccat_id,  sector_id, omzone_id, expl_id, muni_id, state, state_type, the_geom, workcat_id,
				verified, inventory, category_type, function_type, fluid_type, location_type, link, dwfzone_id)
				VALUES (v_id, v_code, v_old_featuretype, v_old_featurecat, v_sector_id, v_omzone_id, v_expl_id, v_muni_id, 0, v_state_type, v_the_geom,v_workcat_id_end,
				v_verified_id, v_inventory, v_category, v_function, 0, v_location, v_link, v_dwfzone_id);
			END IF;


			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3308", "function":"2714", "parameters":{"v_id":"'||v_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

		ELSIF v_feature_type = 'gully' THEN

			INSERT INTO gully (gully_id, code, gully_type, gullycat_id, sector_id, omzone_id, expl_id, muni_id, state, state_type, the_geom,workcat_id, verified,
			inventory, category_type, function_type, fluid_type, location_type,epa_type, link, dwfzone_id)
			VALUES (v_id, v_code, v_old_featuretype, v_old_featurecat, v_sector_id, v_omzone_id, v_expl_id, v_muni_id, 0, v_state_type, v_the_geom, v_workcat_id_end,
			v_verified_id, v_inventory, v_category, v_function, 0, v_location, v_epa_type_new, v_link, v_dwfzone_id);


				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3310", "function":"2714", "parameters":{"v_id":"'||v_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		IF v_feature_type  in ('arc', 'node') or (v_feature_type ='connec' and v_project_type = 'WS') THEN

			-- inserting new feature on table man_table / epa table
			EXECUTE 'SELECT man_table FROM cat_feature c JOIN sys_feature_class s ON c.feature_class = s.id WHERE c.id='''||v_feature_type_new||''';'
				INTO v_man_table;

			v_query_string_insert='INSERT INTO '||v_man_table||' VALUES ('||v_id||') ON CONFLICT ('||v_feature_type||'_id) DO NOTHING;';
			EXECUTE v_query_string_insert;
		END IF;

		IF v_epa_table_new IS NOT NULL THEN
			v_query_string_insert='INSERT INTO '||v_epa_table_new||' VALUES ('||v_id||') ON CONFLICT ('||v_feature_type||'_id) DO NOTHING;';
			EXECUTE v_query_string_insert;
		END IF;

		-- updating values on feature parent table from values of old feature
		v_excluded_columns := ''''||v_id_column||''',''the_geom'',''state'',''code'',''epa_type'',''state_type'','''||v_cat_column||''',
			''sector_id'',''dma_id'',''expl_id'',''category_type'',''function_type'',''fluid_type'',''location_type'',''link''';
		IF v_keep_sys_code IS NOT TRUE THEN
			v_excluded_columns := v_excluded_columns || ',''sys_code''';
		END IF;
		IF v_feature_type = 'connec' AND v_keep_customer_code IS NOT TRUE THEN
			v_excluded_columns := v_excluded_columns || ',''customer_code''';
		END IF;
		v_sql:='select column_name FROM information_schema.columns 
				where (table_schema=''SCHEMA_NAME'' and udt_name <> ''inet'' and 
				table_name='''||v_feature_type||''') 
				and column_name not in ('||v_excluded_columns||');';

		FOR v_column IN EXECUTE v_sql
		LOOP
			v_query_string_select= 'SELECT '||v_column||' FROM '||v_feature_type||' where '||v_id_column||'='||quote_literal(v_old_id)||';';
			IF v_query_string_select IS NOT NULL THEN
				EXECUTE v_query_string_select INTO v_value;
			END IF;

			v_query_string_update= 'UPDATE '||v_feature_type||' set '||v_column||'='||quote_literal(v_value)||' where '||v_id_column||'='||quote_literal(v_id)||';';
			IF v_query_string_update IS NOT NULL THEN
				EXECUTE v_query_string_update;

			END IF;
		END LOOP;


		-- updating values on table man_table from values of old feature
		IF v_old_featuretype = v_feature_type_new AND (v_feature_type='node' or v_feature_type='arc' or (v_feature_type='connec' AND v_project_type='WS')) THEN
			v_sql:='select column_name    FROM information_schema.columns 
								where (table_schema=''SCHEMA_NAME'' and udt_name <> ''inet'' and 
								table_name='''||v_man_table||''') and column_name!='''||v_id_column||''';';
			FOR v_column IN EXECUTE v_sql
			LOOP
				v_query_string_select= 'SELECT '||v_column||' FROM '||v_man_table||' where '||v_id_column||'='||quote_literal(v_old_id)||';';
				IF v_query_string_select IS NOT NULL THEN
					EXECUTE v_query_string_select INTO v_value;
				END IF;

				v_query_string_update= 'UPDATE '||v_man_table||' set '||v_column||'='||quote_literal(v_value)||' where '||v_feature_type||'_id='||quote_literal(v_id)||';';
				IF v_query_string_update IS NOT NULL THEN
					EXECUTE v_query_string_update;

				END IF;

			END LOOP;
		END IF;

		-- updating values on table epa_table from values of old feature
		IF (v_feature_type='node' or v_feature_type='arc' or v_feature_type='gully' or (v_feature_type='connec' AND v_project_type='WS'))
		and v_epa_table_new is not null AND v_epa_type_new = v_old_epa_type THEN
			v_sql:='select column_name  FROM information_schema.columns 
								where (table_schema=''SCHEMA_NAME'' and udt_name <> ''inet'' and 
								table_name='''||v_epa_table_new||''') and column_name!='''||v_id_column||''';';

			FOR v_column IN EXECUTE v_sql LOOP
				v_query_string_select= 'SELECT '||v_column||' FROM '||v_epa_table_new||' where '||v_feature_type||'_id='||quote_literal(v_old_id)||';';
				IF v_query_string_select IS NOT NULL THEN
					EXECUTE v_query_string_select INTO v_value;
				END IF;

				v_query_string_update= 'UPDATE '||v_epa_table_new||' set '||v_column||'='||quote_literal(v_value)||' where '||v_id_column||'='||quote_literal(v_id)||';';
				IF v_query_string_update IS NOT NULL THEN
					EXECUTE v_query_string_update;

				END IF;
			END LOOP;
		END IF;


		v_feature_childtable_name_old := 'man_' || v_feature_type || '_' || lower(v_old_featuretype);
		v_feature_childtable_name_new := 'man_' || v_feature_type || '_' || lower(v_feature_type_new);

		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = v_schemaname AND table_name = v_feature_childtable_name_old)) IS TRUE AND
			(SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = v_schemaname AND table_name = v_feature_childtable_name_new)) IS TRUE
		THEN

			EXECUTE 'INSERT INTO '||v_feature_childtable_name_new||' ('||v_feature_type||'_id) VALUES ('||v_id||');';

			v_sql := 'SELECT column_name FROM information_schema.columns 
					WHERE table_schema = ''SCHEMA_NAME'' 
					AND table_name = '''||v_feature_childtable_name_old||''' 
					AND column_name !=''id'' AND column_name != '''||v_feature_type||'_id'' 
					AND column_name IN (SELECT column_name
										FROM information_schema.columns
										WHERE table_name = '''||v_feature_childtable_name_new||'''
										AND column_name !=''id'' AND column_name != '''||v_feature_type||'_id'');';

			-- taking values from old feature (from man_{feature_type}_{feature_childtype}) if the column is equal.
			FOR rec_addfields IN EXECUTE v_sql
			LOOP

				v_query_string_update = 'UPDATE '||v_feature_childtable_name_new||' SET '||rec_addfields.column_name||' = '
										'(SELECT '||rec_addfields.column_name||' FROM '||v_feature_childtable_name_old||' WHERE '||v_id_column||' = '||quote_literal(v_old_id)||' ) '
										'WHERE '||v_feature_childtable_name_new||'.'||v_id_column||' = '||quote_literal(v_id)||';';
				IF v_query_string_update IS NOT NULL THEN
					EXECUTE v_query_string_update;

					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3312", "function":"2714", "parameters":{"rec_addfields.column_name":"'||rec_addfields.column_name||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

				END IF;

			END LOOP;

			EXECUTE 'DELETE FROM '||v_feature_childtable_name_old||' WHERE '||v_id_column||'='||quote_literal(v_old_id)||';';
		END IF;

		--Moving elements from old feature to new feature
		IF v_keep_elements IS TRUE THEN
			v_element_table:=concat('element_x_',v_feature_type);
			EXECUTE 'SELECT count(element_id) FROM '||v_element_table||' WHERE '||v_id_column||'='''||v_old_id||''';'
			INTO v_count;
			IF v_count > 0 THEN
				v_element_table:=concat('element_x_',v_feature_type);
				EXECUTE 'UPDATE '||v_element_table||' SET '||v_id_column||'='''||v_id||''' WHERE '||v_id_column||'='''||v_old_id||''';';

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3344", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			END IF;
		END IF;

		-- reconnecting features
		IF v_feature_type='node' THEN
			UPDATE config_param_system SET value =concat('{"activated":','false',', "value":',v_arc_searchnodes_value,'}') WHERE parameter='edit_arc_searchnodes';

			FOR rec_arc IN SELECT arc_id FROM arc WHERE node_1=v_old_id
			LOOP
				UPDATE arc SET node_1=v_id where arc_id=rec_arc.arc_id;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3314", "function":"2714", "parameters":{"rec_arc.arc_id":"'||rec_arc.arc_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END LOOP;

			FOR rec_arc IN SELECT arc_id FROM arc WHERE node_2=v_old_id
			LOOP
				UPDATE arc SET node_2=v_id where arc_id=rec_arc.arc_id;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3314", "function":"2714", "parameters":{"rec_arc.arc_id":"'||rec_arc.arc_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			END LOOP;

			FOR rec_connec IN SELECT connec_id FROM connec WHERE pjoint_id = v_old_id AND  pjoint_type = 'NODE'
			LOOP
				UPDATE connec SET pjoint_id=v_id where connec_id=rec_connec.connec_id;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3316", "function":"2714", "parameters":{"rec_connec.connec_id":"'||rec_connec.connec_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			END LOOP;

			FOR rec_link IN SELECT link_id FROM link WHERE exit_id = v_old_id AND exit_type = 'NODE'
			LOOP
				UPDATE link SET exit_id=v_id where link_id=rec_link.link_id;
				INSERT INTO audit_check_data (fid, result_id, error_message)
				VALUES (v_fid, v_result_id, concat('Reconnect link ',rec_link.link_id,'.'));
			END LOOP;

			IF v_project_type = 'UD' THEN
				FOR rec_gully IN SELECT gully_id FROM gully WHERE pjoint_id = v_old_id AND pjoint_type = 'NODE'
				LOOP
					UPDATE gully SET pjoint_id=v_id where gully_id=rec_gully.gully_id;
					INSERT INTO audit_check_data (fid, result_id, error_message)
					VALUES (v_fid, v_result_id, concat('Reconnect gully ',rec_gully.gully_id,'.'));
				END LOOP;
			END IF;

		ELSIF v_feature_type='arc' THEN

			UPDATE connec SET arc_id = v_id WHERE arc_id = v_old_id;
			GET DIAGNOSTICS v_count = row_count;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3290", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			UPDATE plan_psector_x_connec SET arc_id = v_id WHERE arc_id = v_old_id;
			GET DIAGNOSTICS v_count = row_count;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3292", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			IF v_project_type='UD' then
				UPDATE gully SET arc_id = v_id WHERE arc_id = v_old_id;
				GET DIAGNOSTICS v_count = row_count;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3294", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

				UPDATE plan_psector_x_gully SET arc_id = v_id WHERE arc_id = v_old_id;
				GET DIAGNOSTICS v_count = row_count;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3296", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;

		ELSIF v_feature_type='connec' or  v_feature_type='gully' THEN

			UPDATE link SET exit_id = v_id WHERE exit_id = v_old_id AND state > 0;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3298", "function":"2714", "parameters":{"v_count":"'||quote_nullable(v_count)||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';


		END IF;

		-- update node_id on on going or planned psectors
		IF v_feature_type='node' THEN
			SELECT count(psector_id) INTO v_count FROM plan_psector_x_node JOIN plan_psector USING (psector_id)
			WHERE status in (1,2) AND node_id = v_old_id;
			IF v_count > 0 THEN
				UPDATE plan_psector_x_node SET node_id = v_id FROM plan_psector pp
				WHERE pp.psector_id = plan_psector_x_node.psector_id AND status in (1,2) AND node_id = v_old_id;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3300", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;
		END IF;

		-- upgrading and downgrading features
		v_state_type = (SELECT id FROM value_state_type WHERE state=0 LIMIT 1);

		IF v_workcat_id_end IS NOT NULL THEN
			EXECUTE 'UPDATE '||v_feature_type||' SET state=0, workcat_id_end='''||v_workcat_id_end||''', enddate='''||v_enddate||''', 
			state_type='||v_state_type||' WHERE '||v_id_column||'='''||v_old_id||''';';
		ELSE
			EXECUTE 'UPDATE '||v_feature_type||' SET state=0, enddate='''||v_enddate||''', 
			state_type='||v_state_type||' WHERE '||v_id_column||'='''||v_old_id||''';';
		END IF;

		-- when the arc is obsolete, set node_1 and node_2 to null
		IF v_feature_type = 'arc' THEN
			UPDATE arc SET node_1 = NULL, node_2 = NULL WHERE arc_id = v_old_id;
		END IF;

		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3302", "function":"2714", "parameters":{"v_old_id":"'||v_old_id||'", "v_workcat_id_end":"'||quote_nullable(v_workcat_id_end)||'", "v_enddate":"'||quote_nullable(v_enddate)||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

		IF v_id IS NOT NULL THEN
			IF v_workcat_id_end IS NOT NULL THEN
				EXECUTE 'UPDATE '||v_feature_type||' SET state=1, workcat_id='''||v_workcat_id_end||''', builtdate='''||v_enddate||''', 
				enddate=NULL WHERE '||v_id_column||'='''||v_id||''';';
			ELSE
				EXECUTE 'UPDATE '||v_feature_type||' SET state=1,builtdate='''||v_enddate||''', 
				enddate=NULL WHERE '||v_id_column||'='''||v_id||''';';
			END IF;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3304", "function":"2714", "parameters":{"v_workcat_id_end":"'||quote_nullable(v_workcat_id_end)||'", "v_enddate":"'||quote_nullable(v_enddate)||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3306", "function":"2714", "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';


		END IF;

		--reconect existing link to the new feature
		IF v_feature_type='connec' OR v_feature_type='gully' THEN
			SELECT count(link_id) INTO v_count FROM link WHERE (feature_id = v_old_id and feature_type = upper(v_feature_type) and state=1) OR
			(exit_id = v_old_id and exit_type = upper(v_feature_type) and state=1);
			IF v_count > 0 THEN
				UPDATE link SET feature_id = v_id WHERE feature_id = v_old_id and feature_type = upper(v_feature_type) and state=1;
				UPDATE link SET exit_id = v_id WHERE exit_id = v_old_id and exit_type = upper(v_feature_type) and state=1;
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3342", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			END IF;

		ELSIF v_feature_type='node' THEN
			SELECT count(link_id) INTO v_count FROM link WHERE exit_id = v_old_id and exit_type = upper(v_feature_type) and state=1;
			IF v_count > 0 THEN
				UPDATE link SET exit_id = v_id WHERE exit_id = v_old_id and exit_type = upper(v_feature_type) and state=1;
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3342", "function":"2714", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			END IF;
		END IF;

		-- enable config parameters
		IF v_feature_type='arc' THEN
			UPDATE config_param_system SET value =concat('{"activated":',v_arc_searchnodes_active,', "value":',v_arc_searchnodes_value,'}') WHERE parameter='edit_arc_searchnodes';
		ELSIF v_feature_type='connec' THEN
			UPDATE config_param_system SET value =concat('{"activated":',v_connec_proximity_active,', "value":',v_connec_proximity_value,'}') WHERE parameter='edit_connec_proximity';
		ELSIF v_feature_type='node' THEN
			UPDATE config_param_system SET value =concat('{"activated":',v_arc_searchnodes_active,', "value":',v_arc_searchnodes_value,'}') WHERE parameter='edit_arc_searchnodes';
		ELSIF v_feature_type='gully' THEN
			UPDATE config_param_system SET value = concat('{"activated":',v_gully_proximity_active,', "value":',v_gully_proximity_value,'}') WHERE parameter = 'edit_gully_proximity';
		END IF;

		v_field_cat=concat(v_feature_type,'cat_id');

		-- log
		INSERT INTO audit_log_data (fid, feature_type,feature_id, log_message)
		SELECT v_fid, 'ARC', arc_id, concat('{"description":"Pipe replacement", "workcat":"'||quote_nullable(v_workcat_id_end)||'", "sector":"',name,'", "length":',
		(st_length(arc.the_geom))::numeric(12,2),', "newCatalog":"',v_featurecat_id_new,'", "oldCatalog":"',v_old_featurecat,'"}')
		FROM arc JOIN sector USING (sector_id) WHERE arc_id = v_id;

		-- update catalog of new feature
		IF v_featurecat_id_new IS NOT NULL AND v_feature_type_new IS NOT NULL THEN

			EXECUTE 'UPDATE '||v_feature_type||' SET '||v_field_cat||' =  '||quote_literal(v_featurecat_id_new)||' 
			WHERE '||v_feature_type||'_id = '||quote_literal(v_id)||';';

			IF v_project_type = 'UD' THEN
				IF v_feature_type != 'gully' THEN
					EXECUTE 'UPDATE '||v_feature_type||' SET '||v_feature_type||'_type =  '||quote_literal(v_feature_type_new)||' 
					WHERE '||v_feature_type||'_id = '||quote_literal(v_id)||';';
				END IF;
			END IF;
		END IF;

		-- update nodetype on arc
		IF v_feature_type='node' then

			FOR rec_arc IN SELECT arc_id, nodetype_1 FROM arc WHERE node_1=v_id
			loop
				select node_type from ve_node where node_id=v_id into v_nodetype;
				UPDATE arc SET nodetype_1=v_nodetype where arc_id=rec_arc.arc_id;
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3340", "function":"2714", "parameters":{"rec_arc.arc_id":"'||rec_arc.arc_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END LOOP;

			FOR rec_arc IN SELECT arc_id, nodetype_2 FROM arc WHERE node_2=v_id
			loop
				select node_type from ve_node where node_id=v_id into v_nodetype;
				UPDATE arc SET nodetype_2=v_nodetype where arc_id=rec_arc.arc_id;
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3340", "function":"2714", "parameters":{"rec_arc.arc_id":"'||rec_arc.arc_id||'"}, "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			END LOOP;
		end if;

		--reset mapzone configuration
		IF v_project_type='WS' THEN

			IF v_feature_type = 'node' THEN

				-- check if old / new nodes they are graphdelimiters
				EXECUTE '
					SELECT 
						CASE 
							WHEN array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''NONE'') IS NOT NULL
							  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''MINSECTOR'') IS NOT NULL
							  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''CHECKVALVE'') IS NOT NULL
							THEN NULL
							ELSE ARRAY(SELECT lower(unnest(graph_delimiter)))
						END AS graph
					FROM '||v_feature_type_table||' c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE s.id='''||v_old_featuretype||''';
				' INTO v_mapzone_old;

				EXECUTE '
					SELECT 
						CASE 
							WHEN array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''NONE'') IS NOT NULL
							  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''MINSECTOR'') IS NOT NULL
							  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''CHECKVALVE'') IS NOT NULL
							THEN NULL
							ELSE ARRAY(SELECT lower(unnest(graph_delimiter)))
						END AS graph
					FROM '||v_feature_type_table||' c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE s.id='''||v_feature_type_new||''';
				' INTO v_mapzone_new;

				IF v_mapzone_old IS NOT NULL OR v_mapzone_new IS NOT NULL THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2714", "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true, "is_header":"true"}}$$)';

					IF v_mapzone_old = v_mapzone_new and v_mapzone_new is not null THEN
						EXECUTE 'SELECT gw_fct_setmapzoneconfig($${
						"client":{"device":4, "infoType":1,"lang":"ES"}, "data":{"parameters":{"nodeIdOld":"'||v_old_id||'",
						"nodeIdNew":"'||v_id||'", "action":"updateNode"}}}$$);';

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3338", "function":"2714", "fid":"'||v_fid||'","result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

					ELSIF  v_mapzone_old is not null AND  v_mapzone_new is nulL THEN


										EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3336", "function":"2714", "fid":"'||v_fid||'","result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

					ELSIF  v_mapzone_old is null AND v_mapzone_new is not null THEN

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3334", "function":"2714", "fid":"'||v_fid||'","result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

					ELSIF v_mapzone_old!=v_mapzone_new AND  v_mapzone_old is not null AND v_mapzone_new is not null THEN


						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3332", "function":"2714", "fid":"'||v_fid||'","result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
					END IF;
				END IF;

			ELSIF v_feature_type = 'arc' THEN

					--check if final nodes of arc are graph delimiters
					EXECUTE '
						SELECT 
							CASE 
								WHEN array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''NONE'') IS NOT NULL
								  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''MINSECTOR'') IS NOT NULL
								  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''CHECKVALVE'') IS NOT NULL
								THEN NULL
								ELSE ARRAY(SELECT lower(unnest(graph_delimiter)))
							END AS graph, node_1 
						FROM ve_arc a 
						JOIN ve_node n1 ON n1.node_id = node_1
						JOIN cat_feature_node cf1 ON n1.node_type = cf1.id 
						WHERE a.arc_id = '''||v_id||''';'
					INTO v_node1_graph, v_node_1;

					EXECUTE '
						SELECT 
							CASE 
								WHEN array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''NONE'') IS NOT NULL
								  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''MINSECTOR'') IS NOT NULL
								  OR array_position(ARRAY(SELECT upper(unnest(graph_delimiter))), ''CHECKVALVE'') IS NOT NULL
								THEN NULL
								ELSE ARRAY(SELECT lower(unnest(graph_delimiter)))
							END AS graph, node_2
						FROM ve_arc a 
						JOIN ve_node n2 ON n2.node_id=node_2
						JOIN cat_feature_node cf2 ON n2.node_type = cf2.id
						WHERE a.arc_id = '''||v_id||''';'
					INTO v_node2_graph, v_node_2;

					IF v_node1_graph IS NOT NULL THEN
						EXECUTE 'SELECT gw_fct_setmapzoneconfig($${
						"client":{"device":4, "infoType":1,"lang":"ES"}	,"data":{"parameters":{"nodeIdOld":"'||v_node_1||'",
						"arcIdOld":'||v_old_id||',"arcIdNew":'||v_id||',"action":"updateArc"}}}$$);';


						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2714", "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true, "is_header":"true"}}$$)';

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3322", "function":"2714", "fid":"'||v_fid||'", "criticity":"1", "is_process":true}}$$)';
					END IF;

					IF v_node2_graph IS NOT NULL THEN

						EXECUTE 'SELECT gw_fct_setmapzoneconfig($${
						"client":{"device":4, "infoType":1,"lang":"ES"},"data":{"parameters":{"nodeIdOld":"'||v_node_2||'", 
						"arcIdOld":'||v_old_id||',"arcIdNew":'||v_id||',"action":"updateArc"}}}$$);';


						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2714", "fid":"'||v_fid||'", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true, "is_header":"true"}}$$)';

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3320", "function":"2714", "fid":"'||v_fid||'", "criticity":"1", "is_process":true}}$$)';
					END IF;
			END IF;

		ELSIF v_project_type='UD' AND v_feature_type = 'node' THEN

			EXECUTE 'SELECT gw_fct_setmapzoneconfig($${
			"client":{"device":4, "infoType":1,"lang":"ES"}, "data":{"parameters":{"nodeIdOld":"'||v_old_id||'",
			"nodeIdNew":"'||v_id||'", "action":"updateNode"}}}$$);';

		END IF;


		-- get log (fid: 143)
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message AS message FROM audit_check_data WHERE cur_user="current_user"() AND fid = v_fid) row;

		IF v_audit_result is null THEN
		v_status = 'Accepted';
		v_level = 3;
		--v_message = 'Replace feature done successfully';
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3288", "function":"2714", "is_process":true}}$$)::JSON->>''text''' INTO v_message;

	    ELSE

		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;

	    END IF;

	END IF;

	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_version := COALESCE(v_version, '');
	v_result_info := COALESCE(v_result_info, '{}');


	-- Return
	RETURN ('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "featureId":"'||v_id||'",
				"info":'||v_result_info||'}}'||
	    '}')::json;

	--    Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN ('{"status":"Failed", "SQLERR":' || to_json(SQLERRM) || ',"SQLCONTEXT":' || to_json(v_error_context) || ',"SQLSTATE":' || to_json(SQLSTATE) || '}')::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
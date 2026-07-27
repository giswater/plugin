/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3194

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_infofromid(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_infofromid(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
UPSERT FEATURE
arc no nodes extremals
SELECT SCHEMA_NAME.gw_fct_infofromid($${
		"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"},
		"form":{"editable":"True"},
		"feature":{"tableName":"ve_arc_pipe", "inputGeometry":"0102000020E7640000020000000056560000A083198641000000669A33C041000000E829D880410000D0AE90F0F341" },
		"data":{}}$$)
arc with nodes extremals
SELECT SCHEMA_NAME.gw_fct_infofromid($${
		"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"},
		"form":{"editable":"True"},
		"feature":{"tableName":"ve_arc_pipe", "inputGeometry":"0102000020E764000002000000998B3C512F881941B28315AA7F76514105968D7D748819419FDF72D781765141" },
		"data":{"addSchema":"SCHEMA_NAME"}}$$)
INFO BASIC
SELECT SCHEMA_NAME.gw_fct_infofromid($${
		"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"},
		"form":{"editable":"True"},
		"feature":{"tableName":"ve_arc_pipe", "id":"2001"},
		"data":{}}$$)

SELECT SCHEMA_NAME.gw_fct_infofromid($${
		"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"},
		"form":{"editable":"True"},
		"feature":{"tableName":"ve_arc","id":"2001"},
		"data":{}}$$)

SELECT SCHEMA_NAME.gw_fct_infofromid($${
		"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"},
		"form":{"editable":"True"},
		"feature":{"tableName":"ve_node_junction", "id":"1001"},
		"data":{}}$$)
SELECT SCHEMA_NAME.gw_fct_infofromid($${
		"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"},
		"form":{"editable":"True"},
		"feature":{"tableName":"ve_connec_wjoin", "id":"3001"},
		"data":{}}$$)
SELECT SCHEMA_NAME.gw_fct_infofromid($${
		"client":{"device":4, "infoType":1, "lang":"ES", "cur_user":"test_user"},
		"form":{"editable":"True"},
		"feature":{"tableName":"ve_element", "id":"125101"},
		"data":{}}$$)

SELECT SCHEMA_NAME.gw_fct_getfeatureinsert($${"client":{"device":4, "infoType":1, "lang":"ES","epsg":SRID_VALUE, "cur_user":"test_user"}, "form":{}, "feature":{"tableName":"ve_node_air_valve"}, "data":{"filterFields":{}, "pageInfo":{}, "toolBar":"basic", "rolePermissions":"full", "coordinates":{"x1":418957.8771109133, "y1":4576670.596288238}}}$$);

*/

DECLARE


v_id text;
v_id_integer integer;
v_id_array text[];

v_layouts text[];
v_layout text;
add_param_orientation json;
v_form_orientation text;
layout_orientation_exist boolean;

v_tablename character varying;
v_sourcetable character varying;
v_tablename_original character varying;

v_inputgeometry public.geometry;
v_editable boolean = true;
v_device integer;
v_infotype integer = 1;
v_forminfo json;
form_tabs json[];
form_tablabel varchar[];
form_tabs_json json;
v_fields json;
formid_arg text;
tableparent_id_arg text;
parent_child_relation boolean = false;
v_idname text;
v_featuretype text;
v_featureclass text;
column_type text;
v_schemaname text;
v_version text;
v_geometry json;
v_the_geom text;
v_table_parent varchar;
v_tg_op varchar;
v_project_type text;
v_per boolean;
v_permissions json;
v_configtabledefined boolean;
v_formtype text;
v_vdefault_values text;
v_vdefault_array json;
v_list_parameter text[];
v_aux_parameter text;
list_values character varying[];
v_value character varying;
v_featureinfo json;
v_parent_layer text;
v_message json;
v_maxcanvasmargin double precision;
v_mincanvasmargin double precision;
v_canvasmargin  double precision;
v_canvasmargin_text text ;
v_toolbar text;
v_role text;
v_parentfields text;
v_status text ='Accepted';
v_childtype text;
v_errcontext text;
v_islayer boolean;
v_isepa boolean;
v_addschema text;
v_return json;
v_flag boolean = false;
v_isgraphdelimiter boolean  = false;
v_isepatoarc boolean  = false;
v_nodetype text;
v_isarcdivide boolean = false;
v_querystring text;
v_msgerr json;
v_pkeyfield text;
v_featuredialog text;
v_headertext text;
v_formheader_value text;
v_formheader_field text;
v_formheader_new_text text;
v_tabdata_lytname json;
v_tabdata_lytname_result json;
v_record record;
v_cur_user text;
v_prev_cur_user text;
v_table_child text;
v_table_class varchar;
v_table_epa text;
v_epatype text;
v_tablename_aux text;
v_zone text;

v_idname_array text[];
column_type_id_array text[];
i integer=1;
v_querytext text;
idname text;
v_addparam json;

v_noderecord1 record;
v_order_id integer;
v_flwreg_type text;
v_arc_searchnodes double precision;
v_talblenameorigin text;
v_ui_lang text;
v_ml_pref jsonb;
v_ml_project_type text;
v_i18n_lb text;
v_i18n_tt text;
v_tab_idx integer;


BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname := 'SCHEMA_NAME';

	-- input parameters
	v_device := (p_data ->> 'client')::json->> 'device';
	v_tablename := (p_data ->> 'feature')::json->> 'tableName';
	v_epatype := (p_data ->> 'feature')::json->> 'epaType';
	v_id := (p_data ->> 'feature')::json->> 'id';
	if (p_data ->> 'feature')::json->> 'inputGeometry' = '' then
		v_inputgeometry := NULL;
	else
		v_inputgeometry := (p_data ->> 'feature')::json->> 'inputGeometry';
	end if;
	v_islayer := (p_data ->> 'feature')::json->> 'isLayer';
	v_isepa := (p_data ->> 'feature')::json->> 'isEpa';
	v_editable = (p_data ->> 'form')::json->> 'editable';
	v_toolbar := (p_data ->> 'data')::json->> 'toolBar';
	v_addschema := (p_data ->> 'data')::json->> 'addSchema';
	v_featuredialog := coalesce((p_data ->> 'form')::json->> 'featureDialog','[]');
	v_cur_user := (p_data ->> 'client')::json->> 'cur_user';
	v_talblenameorigin := v_tablename;

	-- control of nulls
	IF v_addschema = 'NULL' THEN v_addschema = null; END IF;

	v_prev_cur_user = current_user;
	IF v_cur_user IS NOT NULL THEN
		EXECUTE 'SET ROLE "'||v_cur_user||'"';
	END IF;

	-- Get values from config
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

    SELECT ((value::json)->>'value') INTO v_arc_searchnodes FROM config_param_system WHERE parameter='edit_arc_searchnodes';

	-- control strange null
	IF lower(v_addschema) = 'none' or v_addschema = '' THEN
		v_addschema = null;
	END IF;

	-- special case of polygon
	IF (v_tablename = 've_pol_node' or v_tablename = 've_pol_connec' or v_tablename = 've_pol_gully') AND v_id IS NOT NULL THEN

		EXECUTE 'SELECT feature_id, featurecat_id  FROM '||v_tablename||' WHERE pol_id = '||quote_literal(v_id)||''
		INTO v_id, v_tablename;
		v_tablename = (SELECT concat('ve_',lower(feature_type)) FROM cat_feature WHERE id = v_tablename LIMIT 1);
		IF v_tablename IS NULL THEN v_tablename = 've_element'; END IF;
		v_editable = true;
	END IF;

	IF v_tablename IN ('ve_man_frelem', 've_man_genelem') AND v_id IS NOT NULL THEN
		EXECUTE format('SELECT concat(''ve_element_'', lower(element_type)) FROM %I WHERE element_id = %L', v_tablename, v_id) INTO v_tablename;
	END IF;

	-- Check if feature exist
	IF v_id is not null then

		-- Manage primary key
		EXECUTE 'SELECT addparam FROM sys_table WHERE id = $1' INTO v_addparam USING v_tablename;
		v_idname = v_addparam ->> 'pkey';
		v_idname_array := string_to_array(v_idname, ', ');

		if v_idname_array is null THEN
			EXECUTE 'SELECT gw_fct_getpkeyfield('''||v_tablename||''');' INTO v_pkeyfield;
			v_idname_array := string_to_array(v_pkeyfield, ', ');
		end if;

		v_id_array := string_to_array(v_id, ', ');

		IF v_idname_array IS NULL THEN
			EXECUTE 'SET ROLE "'||v_prev_cur_user||'"';
			RETURN ('{"status":"Accepted", "message":{"level":0, "text":"No feature found"}, "version":"'|| v_version ||'", "body":{}}')::json;

		END IF;


		if v_idname_array is not null then
			if array_length(v_idname_array, 1) = 1 then
				v_idname = v_idname_array[1];
			end if;
			FOREACH idname IN ARRAY v_idname_array LOOP
				EXECUTE 'SELECT pg_catalog.format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
				    JOIN pg_class t on a.attrelid = t.oid
				    JOIN pg_namespace s on t.relnamespace = s.oid
				    WHERE a.attnum > 0
				    AND NOT a.attisdropped
				    AND a.attname = $3
				    AND t.relname = $2
				    AND s.nspname = $1
				    ORDER BY a.attnum'
			    USING v_schemaname, v_tablename, idname
			    INTO column_type;
				column_type_id_array[i] := column_type;
				i=i+1;
			END LOOP;
		else
			--   Get id column type
			EXECUTE 'SELECT pg_catalog.format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
			    JOIN pg_class t on a.attrelid = t.oid
			    JOIN pg_namespace s on t.relnamespace = s.oid
			    WHERE a.attnum > 0
			    AND NOT a.attisdropped
			    AND a.attname = $3
			    AND t.relname = $2
			    AND s.nspname = $1
			    ORDER BY a.attnum'
	            USING v_schemaname, v_tablename, v_idname
	            INTO column_type;
		end if;

		-- Get Epa Type
	    if v_epatype is null and (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE table_name = v_tablename AND column_name = 'epa_type' and table_schema = v_schemaname) is not null then

	    	v_querytext = 'SELECT epa_type FROM '|| v_tablename || ' ';

			i = 1;
			v_querytext := v_querytext || ' WHERE ';
			FOREACH idname IN ARRAY v_idname_array loop
				v_querytext := v_querytext || quote_ident(idname) || ' = CAST(' || quote_literal(v_id_array[i]) || ' AS ' || column_type_id_array[i] || ') AND ';
				i=i+1;
			END LOOP;
			v_querytext = substring(v_querytext, 0, length(v_querytext)-4);
			EXECUTE v_querytext INTO v_epatype;
		end if;
	END IF;

	-- looking for additional schema
	IF (v_addschema IS NOT NULL OR v_addschema != 'NULL') AND v_addschema != v_schemaname AND v_flag IS FALSE THEN
		v_querystring = concat('SET search_path = ',v_addschema,', public');

		EXECUTE v_querystring;

		SELECT gw_fct_infofromid(p_data) INTO v_return;
		SET search_path = 'SCHEMA_NAME', public;
		EXECUTE 'SET ROLE "'||v_prev_cur_user||'"';
		RETURN v_return;
	END IF;

	IF v_toolbar is NULL THEN
		v_toolbar := 'basic';
	END IF;

	-- get project type
	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- check layer if it's child layer
	IF (SELECT child_layer FROM cat_feature WHERE child_layer=v_tablename) IS NOT NULL THEN
		v_table_parent := (SELECT parent_layer FROM cat_feature WHERE child_layer=v_tablename);


		--check if is delimiter
		IF upper(v_project_type) = 'WS' AND v_table_parent='ve_node' THEN
			IF (SELECT ARRAY(SELECT upper(unnest(graph_delimiter))) FROM cat_feature_node JOIN cat_feature USING (id)
				WHERE child_layer=v_tablename) && ARRAY['DMA','PRESSZONE'] THEN
				v_isgraphdelimiter = TRUE;
			ELSIF (SELECT upper(epa_default) FROM cat_feature_node JOIN cat_feature USING (id)
				WHERE child_layer=v_tablename) IN ('PUMP', 'VALVE', 'SHORTPIPE') THEN
					v_isepatoarc = TRUE;
			END IF;
		END IF;

		IF (SELECT isarcdivide FROM cat_feature_node JOIN cat_feature USING (id) WHERE child_layer=v_tablename) IS TRUE THEN
				v_isarcdivide = TRUE;
		END IF;

	ELSIF POSITION('epa' IN v_tablename) > 0 then

		if v_tablename = 've_epa_junction' then
			v_table_epa = v_tablename;
			v_table_parent = 've_node';
		elsif v_tablename = 've_epa_connec' then
			v_table_epa = v_tablename;
			v_table_parent = 've_connec';
		else
			v_table_epa = concat('ve_epa_', lower(v_epatype));
			v_querystring = concat('SELECT concat(''ve_'', lower(feature_type)) FROM sys_feature_epa_type WHERE id =''', v_epatype,'''');
			execute v_querystring into v_table_parent;
		end if;

	ELSE
		-- tablename is used as table parent.
		v_table_parent = v_tablename;

		IF v_id IS NOT NULL THEN

			IF v_table_parent='ve_node' THEN

				v_querystring = concat('SELECT node_type FROM ',v_table_parent,' WHERE node_id = ',v_id::integer,';');

				EXECUTE v_querystring INTO v_nodetype;

				SELECT child_layer INTO v_table_child FROM cat_feature WHERE id =v_nodetype;

				IF (SELECT isarcdivide FROM cat_feature_node WHERE id=v_nodetype) IS TRUE THEN
					v_isarcdivide = TRUE;
				END IF;
				IF upper(v_project_type) = 'WS' THEN
					IF (SELECT ARRAY(SELECT upper(unnest(graph_delimiter))) FROM cat_feature_node WHERE id = v_nodetype) && ARRAY['DMA','PRESSZONE'] THEN
						v_isgraphdelimiter = TRUE;
					ELSIF (SELECT upper(epa_type) FROM node WHERE node_id = v_id::integer) IN ('PUMP', 'VALVE', 'SHORTPIPE') THEN
						v_isepatoarc = TRUE;
					END IF;
				END IF;
			END IF;
		END IF;

		if v_table_epa is null then
			v_table_epa = concat('ve_epa_', lower(v_epatype));
		end if;
	END IF;

	-- get tableparent fields
	v_querystring = concat('SELECT to_json(array_agg(columnname)) FROM
		(SELECT a.attname as columnname FROM pg_attribute a JOIN pg_class t on a.attrelid = t.oid JOIN pg_namespace s on t.relnamespace = s.oid
		WHERE a.attnum > 0 AND NOT a.attisdropped AND t.relname = ',quote_nullable(v_table_parent),' AND s.nspname = ',quote_nullable(v_schemaname),'	ORDER BY a.attnum) a');

	EXECUTE v_querystring INTO v_parentfields;

	v_parentfields = replace (v_parentfields::text, '{', '[');
	v_parentfields = replace (v_parentfields::text, '}', ']');

    -- to build json
	v_querystring = concat('SELECT row_to_json(row) FROM (SELECT formtemplate AS template, headertext AS "headerText"
				FROM config_info_layer WHERE layer_id = ',quote_nullable(v_tablename),' LIMIT 1) row');

	EXECUTE v_querystring INTO v_forminfo;

    -- IF v_forminfo is null and it's layer it's child layer --> parent form info is used
    IF v_forminfo IS NULL AND v_table_parent IS NOT NULL THEN
    	v_querystring = concat('SELECT row_to_json(row) FROM (SELECT formtemplate AS template , headertext AS "headerText"
    				FROM config_info_layer WHERE layer_id = ',quote_nullable(v_table_parent),' LIMIT 1) row');

    	EXECUTE v_querystring INTO v_forminfo;
    END IF;


	-- Set layouts orientation
	v_form_orientation = '"layouts": {';

	SELECT array_agg(distinct layoutname) INTO v_layouts FROM config_form_fields  WHERE formtype = 'form_feature';
	layout_orientation_exist = false;

	IF v_layouts IS NOT NULL THEN
		FOREACH v_layout IN ARRAY v_layouts
		LOOP
			IF (SELECT addparam->'lytOrientation' FROM config_typevalue WHERE id = v_layout) IS NOT NULL THEN
				SELECT json_build_object('lytOrientation', addparam->'lytOrientation') INTO add_param_orientation FROM config_typevalue WHERE id = v_layout;
				v_form_orientation:= concat(v_form_orientation,  '"', v_layout, '":',coalesce(add_param_orientation, '{}'),',');
				layout_orientation_exist = true;
			END IF;
		END LOOP;
	END IF;
	IF layout_orientation_exist IS TRUE THEN
		v_form_orientation := left(v_form_orientation, length(v_form_orientation) - 1);
	END iF;
    v_form_orientation:= concat(v_form_orientation,'}' );


	-- Get feature type
	v_querystring = concat('SELECT lower(feature_type), lower(parent_layer), lower(feature_class) FROM cat_feature WHERE  (parent_layer = ',quote_nullable(v_tablename),' OR child_layer = ',quote_nullable(v_tablename),') LIMIT 1');

	EXECUTE v_querystring INTO v_featuretype, v_parent_layer, v_featureclass;
	v_featuretype := LOWER(v_featuretype);
	v_featuretype := COALESCE(v_featuretype, '');

	-- Get vdefault values
	-- Create List
	list_values = ARRAY['from_date_vdefault','to_date_vdefault','parameter_vdefault','om_param_type_vdefault','edit_doc_type_vdefault'];

	FOREACH v_value IN ARRAY list_values
	LOOP
		v_querystring = concat('SELECT value FROM config_param_user WHERE parameter = ',quote_literal(v_value),' AND cur_user = current_user');

		EXECUTE v_querystring INTO v_vdefault_values;
		v_vdefault_array := gw_fct_json_object_set_key(v_vdefault_array, v_value, COALESCE(v_vdefault_values));
	END LOOP;

	-- Control NULL's
	v_vdefault_array := COALESCE(v_vdefault_array, '[]');

	-- getting source table in order to enhance performance
	IF v_tablename LIKE 've_cad%' THEN v_sourcetable = v_tablename;
    ELSIF v_tablename LIKE 've_flwreg_%' THEN v_sourcetable = replace(v_tablename, 've_', 'inp_');
	ELSIF v_tablename LIKE 've_node_%' THEN v_sourcetable = 'node';
	ELSIF v_tablename LIKE 've_link_%' THEN v_sourcetable = 'link';
	ELSIF v_tablename LIKE 've_arc_%' THEN v_sourcetable = 'arc';
	ELSIF v_tablename LIKE 've_connec_%' THEN v_sourcetable = 'connec';
	ELSIF v_tablename LIKE 've_gully_%' THEN v_sourcetable = 'gully';
	ELSIF v_tablename LIKE '%hydrometer%' THEN v_sourcetable = 'vf_hydrometer';
	ELSIF v_tablename LIKE '%elem%' THEN v_sourcetable = 'element';
	ELSIF v_tablename LIKE 've_%' AND v_tablename != 've_flwreg' THEN v_sourcetable = replace (v_tablename, 've_', '');
	ELSE v_sourcetable = v_tablename;
	END IF;

	--if v_idname_array is null

	-- Get id column
	if v_id is null then

		-- Manage primary key
		EXECUTE 'SELECT addparam FROM sys_table WHERE id = $1' INTO v_addparam USING v_tablename;
		v_idname = v_addparam ->> 'pkey';
		v_idname_array := string_to_array(v_idname, ', ');

		if v_idname_array is null then

			EXECUTE 'SELECT gw_fct_getpkeyfield('''||v_tablename||''');' INTO v_pkeyfield;
			v_idname_array := string_to_array(v_pkeyfield, ', ');

			if v_idname_array is not null then
				FOREACH idname IN ARRAY v_idname_array LOOP
					EXECUTE 'SELECT pg_catalog.format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
					    JOIN pg_class t on a.attrelid = t.oid
					    JOIN pg_namespace s on t.relnamespace = s.oid
					    WHERE a.attnum > 0
					    AND NOT a.attisdropped
					    AND a.attname = $3
					    AND t.relname = $2
					    AND s.nspname = $1
					    ORDER BY a.attnum'
				    USING v_schemaname, v_tablename, idname
				    INTO column_type;
					column_type_id_array[i] := column_type;
					i=i+1;
				END LOOP;
			else
				--   Get id column type
				EXECUTE 'SELECT pg_catalog.format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
				    JOIN pg_class t on a.attrelid = t.oid
				    JOIN pg_namespace s on t.relnamespace = s.oid
				    WHERE a.attnum > 0
				    AND NOT a.attisdropped
				    AND a.attname = $3
				    AND t.relname = $2
				    AND s.nspname = $1
				    ORDER BY a.attnum'
		            USING v_schemaname, v_tablename, v_idname
		            INTO column_type;
			end if;

		end if;

	end if;

    -- Get geometry_column
	EXECUTE 'SELECT attname FROM pg_attribute a
	    JOIN pg_class t on a.attrelid = t.oid
	    JOIN pg_namespace s on t.relnamespace = s.oid
	    WHERE a.attnum > 0
	    AND NOT a.attisdropped
	    AND t.relname = $1
	    AND s.nspname = $2
	    AND left (pg_catalog.format_type(a.atttypid, a.atttypmod), 8)=''geometry''
	    ORDER BY a.attnum
		LIMIT 1'
		INTO v_the_geom
		USING v_sourcetable, v_schemaname;

	-- Get geometry (to feature response)
	IF v_the_geom IS NOT NULL AND v_id IS NOT NULL THEN

		IF v_talblenameorigin = 've_man_frelem' THEN
			v_querytext = 'SELECT row_to_json(row) FROM (SELECT ST_x(ST_centroid(ST_envelope(the_geom))) AS x, ST_y(ST_centroid(ST_envelope(the_geom))) AS y, St_AsText('||quote_ident(v_the_geom)||') FROM '||quote_ident(v_talblenameorigin);
		ELSE
			v_querytext = 'SELECT row_to_json(row) FROM (SELECT ST_x(ST_centroid(ST_envelope(the_geom))) AS x, ST_y(ST_centroid(ST_envelope(the_geom))) AS y, St_AsText('||quote_ident(v_the_geom)||') FROM '||quote_ident(v_sourcetable);
		END IF;

		i = 1;
		v_querytext := v_querytext || ' WHERE ';
		FOREACH idname IN ARRAY v_idname_array loop
			v_querytext := v_querytext || quote_ident(idname) || ' = CAST(' || quote_literal(v_id_array[i]) || ' AS ' || column_type_id_array[i] || ') AND ';
			i=i+1;
		END LOOP;
		v_querytext = substring(v_querytext, 0, length(v_querytext)-4);
		v_querytext := v_querytext || ')row';
		EXECUTE v_querytext INTO v_geometry;
	END IF;

	-- Get geometry for elements without geometry
	IF v_the_geom is not null AND v_sourcetable = 'element' THEN
		IF v_geometry ISNULL THEN
			IF v_project_type = 'WS' THEN
				select  row_to_json(c) INTO v_geometry from (SELECT st_x(st_centroid(st_envelope(the_geom))) as x, st_y(st_centroid(st_envelope(the_geom))) as y , St_AsText(the_geom) from
				(select st_union(array_agg(the_geom))  as the_geom from (SELECT the_geom, element_id FROM arc JOIN element_x_arc USING (arc_id)
						UNION SELECT the_geom, element_id FROM node JOIN element_x_node USING (node_id)
						UNION SELECT the_geom, element_id FROM connec JOIN element_x_connec USING (connec_id))a WHERE element_id = v_id::integer)b)c;
			ELSIF v_project_type = 'UD' THEN
				select  row_to_json(c) INTO v_geometry from (SELECT st_x(st_centroid(st_envelope(the_geom))) as x, st_y(st_centroid(st_envelope(the_geom))) as y , St_AsText(the_geom) from
				(select st_union(array_agg(the_geom))  as the_geom from (SELECT the_geom, element_id FROM arc JOIN element_x_arc USING (arc_id)
						UNION SELECT the_geom, element_id FROM node JOIN element_x_node USING (node_id)
						UNION SELECT the_geom, element_id FROM gully JOIN element_x_gully USING (gully_id)
						UNION SELECT the_geom, element_id FROM connec JOIN element_x_connec USING (connec_id))a WHERE element_id = v_id::integer)b)c;
			END IF;
		END IF;
	END IF;

	IF v_tablename != v_sourcetable THEN

        if v_idname isnull then
    		-- get id column for tablename
    		execute 'select a.attname from pg_index i join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey) where  i.indrelid = $1::regclass and i.indisprimary'
    			into v_idname
    			using v_tablename;
        end if;

		-- for views it suposse pk is the first column
		if v_idname isnull then
			execute '
			select a.attname from pg_attribute a   join pg_class t on a.attrelid = t.oid  join pg_namespace s on t.relnamespace = s.oid where a.attnum > 0   and not a.attisdropped
			and t.relname = $1
			and s.nspname = $2
			order by a.attnum limit 1'
			into v_idname
			using v_tablename, v_schemaname;
		end if;

		-- get id column type
		execute 'select pg_catalog.format_type(a.atttypid, a.atttypmod) from pg_attribute a
			join pg_class t on a.attrelid = t.oid
			join pg_namespace s on t.relnamespace = s.oid
			where a.attnum > 0
			and not a.attisdropped
			and a.attname = $3
			and t.relname = $2
			and s.nspname = $1
			order by a.attnum'
				using v_schemaname, v_tablename, v_idname
				into column_type;
	END IF;

	if v_table_epa is not null then
		v_tablename_aux = v_tablename;
		v_tablename = v_table_epa;
	end if;

	-- Get tabs for form
	-- Getting child table if null
	if v_featuretype in (null, '') and v_epatype is not null  then
		v_querystring = concat('SELECT feature_type FROM sys_feature_epa_type WHERE id = '''||v_epatype||'''');

		EXECUTE v_querystring INTO v_featuretype;
	end if;

	v_table_class = 've_man_' || lower(v_featureclass);
	v_querystring = concat(
	'SELECT array_agg(row_to_json(a)) FROM(
	SELECT '||quote_nullable(v_table_parent)||' as formname, "tabName", "tabLabel", "tooltip", tabactions, orderby, device
	FROM (
    SELECT formname, tabname as "tabName", label as "tabLabel", tooltip as "tooltip", tabactions, orderby, device,
           ROW_NUMBER() OVER (
               PARTITION BY tabname
               ORDER BY
                   CASE
                       WHEN formname = '||quote_nullable(v_tablename) ||' THEN 0
                       WHEN formname = '||quote_nullable(v_table_child)||' THEN 1
                       WHEN formname = '||quote_nullable(v_table_class)||' THEN 2
                       WHEN formname = '||quote_nullable(v_table_parent)||' THEN 3
                       ELSE 3
                   END
           ) as rn
    FROM config_form_tabs
    WHERE (formname ='||quote_nullable(v_table_parent)||' OR formname ='||quote_nullable(v_table_class)||' OR formname ='||quote_nullable(v_table_child)||' OR formname ='||quote_nullable(v_tablename)||' OR formname IS NULL)
          AND '||quote_nullable(v_device)||' = ANY(device)
	) AS subquery
	WHERE rn = 1
	ORDER BY orderby)a');

	EXECUTE v_querystring INTO form_tabs;

	-- Apply multilang UI translations for config_form_tabs
	v_ml_pref := NULL;
	v_ui_lang := NULL;
	v_ml_project_type := NULL;
	IF to_regnamespace('multilang') IS NOT NULL THEN
		v_ml_pref := multilang.gw_fct_get_multilang_language('SCHEMA_NAME');
		v_ui_lang := v_ml_pref->>'lang';
		v_ml_project_type := v_ml_pref->>'project_type';
	END IF;
	IF v_ui_lang IS NOT NULL AND form_tabs IS NOT NULL THEN
		FOR v_tab_idx IN 1..array_length(form_tabs, 1) LOOP
			SELECT i.lb, i.tt INTO v_i18n_lb, v_i18n_tt
			FROM multilang.config_form_tabs i
			WHERE i.project_type = v_ml_project_type
			  AND i.formname = form_tabs[v_tab_idx]->>'formname'
			  AND i.source = form_tabs[v_tab_idx]->>'tabName'
			  AND i.context = 'config_form_tabs'
			  AND i.lang = v_ui_lang
			LIMIT 1;
			IF v_i18n_lb IS NOT NULL THEN
				form_tabs[v_tab_idx] := gw_fct_json_object_set_key(
					form_tabs[v_tab_idx], 'tabLabel', v_i18n_lb);
			END IF;
			IF v_i18n_tt IS NOT NULL THEN
				form_tabs[v_tab_idx] := gw_fct_json_object_set_key(
					form_tabs[v_tab_idx], 'tooltip', v_i18n_tt);
			END IF;
		END LOOP;
	END IF;

	if v_tablename_aux is not null then
		v_tablename = v_tablename_aux;
	end if;

	-- Check if it is parent table
	IF v_tablename IN (SELECT layer_id FROM config_info_layer WHERE is_parent IS TRUE) AND v_id IS NOT NULL THEN

		parent_child_relation:=true;

		-- get childtype
		EXECUTE 'SELECT '||v_featuretype||'_type FROM '||v_parent_layer||' WHERE '||v_featuretype||'_id = '||v_id::integer INTO v_childtype;

		-- Identify tableinfotype_id
		v_querystring = concat(' SELECT tableinfotype_id FROM cat_feature
			JOIN config_info_layer_x_type ON child_layer=tableinfo_id
			WHERE cat_feature.id= (SELECT ',v_featuretype,'_type FROM ',quote_ident(v_tablename),' WHERE ',v_featuretype,'_id=',v_id::integer,')
			AND infotype_id=',quote_nullable(v_infotype));
		EXECUTE v_querystring INTO v_tablename;

	ELSE

		-- get child type
		v_querystring = concat('SELECT id FROM cat_feature WHERE child_layer = ',quote_nullable(v_tablename),' LIMIT 1');

		EXECUTE v_querystring INTO v_childtype;

	END IF;

	v_childtype := COALESCE(v_childtype, '');

	-- Propierties of info layer's
	IF v_tablename IS NULL THEN

		v_message='{"level":2, "text":"The config environment is bad configured. Please take a look on table config layers (config_info_layer_x_type or config_info_layer)", "results":0}';

	ELSIF v_tablename IS NOT NULL THEN

		-- Check generic
		IF v_forminfo ISNULL THEN
			v_forminfo := json_build_object('formName','Generic','template','info_generic');
			formid_arg := 'F16';
		END IF;

		-- Add default tab
		form_tabs_json := array_to_json(form_tabs);

		-- Form Tabs info
		v_forminfo := gw_fct_json_object_set_key(v_forminfo, 'visibleTabs', form_tabs_json);

		-- Zoom to feature margin values
		-- get margin values (The goal of this part is pass margin values to client. As bigger is feature less is margin. For point features, maxcanvasmargin configuration is used)
		EXECUTE 'SELECT row_to_json(row) FROM (SELECT value FROM config_param_system WHERE parameter=''basic_info_canvasmargin'') row'
			INTO v_canvasmargin_text;
		v_maxcanvasmargin = (((v_canvasmargin_text::json->>'value')::json->>'maxcanvasmargin')::json->>'mts')::numeric(12,2);
		v_mincanvasmargin = (((v_canvasmargin_text::json->>'value')::json->>'mincanvasmargin')::json->>'mts')::numeric(12,2);

		-- control of null values from config
		IF v_maxcanvasmargin IS NULL then v_maxcanvasmargin=50; END IF;
		IF v_mincanvasmargin IS NULL then v_mincanvasmargin=5; END IF;

		-- Margin calulate
		v_canvasmargin = (SELECT max(c) FROM
		(SELECT (v_maxcanvasmargin*2-(st_xmax(st_envelope((v_geometry->>'st_astext')::geometry))-st_xmin(st_envelope((v_geometry->>'st_astext')::geometry))))/2 AS c
		UNION SELECT (v_maxcanvasmargin*2-(st_ymax(st_envelope((v_geometry->>'st_astext')::geometry))-st_ymin(st_envelope((v_geometry->>'st_astext')::geometry))))/2)a)::numeric(12,2);
		IF v_canvasmargin <= v_mincanvasmargin THEN
			v_canvasmargin = v_mincanvasmargin;
		END IF;

		IF v_islayer THEN
			v_tg_op = 'LAYER';
		ELSIF v_id IS NULL THEN
			v_tg_op = 'INSERT';
		ELSE
			v_tg_op = 'UPDATE';
		END IF;

		-- Get editability
		IF v_editable IS FALSE THEN
			v_editable := FALSE;
		ELSE
			v_querystring = concat('SELECT gw_fct_getpermissions($${"tableName":"',quote_ident(v_tablename),'"}$$::json)');

			EXECUTE v_querystring INTO v_permissions;

			v_editable := v_permissions->>'isEditable';
		END IF;

		--  Get if field's table are configured on config_info_layer_field
		IF (SELECT distinct formname from config_form_fields WHERE formname=v_tablename) IS NOT NULL THEN
			v_configtabledefined  = TRUE;
		ELSE
			v_configtabledefined  = FALSE;
		END IF;

		-- Get form type
		IF v_editable = TRUE AND v_configtabledefined = TRUE THEN
			v_formtype := 'custom_feature';
		ELSIF v_editable = TRUE AND v_configtabledefined = FALSE THEN
			v_formtype := 'default';
		ELSIF v_editable = FALSE AND v_configtabledefined = TRUE THEN
			v_formtype := 'custom_feature';
		ELSIF v_editable = FALSE AND v_configtabledefined = FALSE THEN
			v_formtype := 'default';
		END IF;

		-- call fields function
		IF v_islayer then

			-- call info form function
			v_querystring = 'SELECT gw_fct_getfeatureinfo($$' ||
				json_build_object(
					'data', json_build_object(
						'parameters', json_build_object(
							'table_id', v_tablename,
							'id', v_id,
							'device', v_device,
							'info_type', v_infotype,
							'configtable', v_configtabledefined,
							'idname', v_idname,
							'columntype', column_type,
							'tgop', v_tg_op
						)
					)
				)::text || '$$);';
			EXECUTE v_querystring INTO v_fields;

		ELSIF v_editable THEN

			-- getting id from URN
			-- TODO: revise this code
			IF v_id IS NULL AND v_isepa IS true THEN
			    v_id = '';
			ELSIF v_id IS NULL AND v_tablename in  ('ve_dma', 've_dqa', 've_sector', 've_drainzone', 've_supplyzone', 've_macrodma', 've_macrodqa', 've_macrosector', 've_dwfzone', 've_omzone', 've_macroomzone', 've_presszone') THEN
				v_zone = replace(v_tablename,'ve_','');
				v_querystring = format('SELECT max(%I_id::integer)+1 FROM %I WHERE %I_id::text ~ ''^[0-9]+$''', v_zone, v_zone, v_zone);
				EXECUTE v_querystring INTO v_id;
			ELSIF v_id IS NULL AND v_tablename IN ('plan_netscenario_dma', 'plan_netscenario_presszone') THEN
				v_zone = replace(v_tablename, 'plan_netscenario_', '');
				v_querystring = format('SELECT coalesce(max(%I_id::integer)+1, 1) FROM %I WHERE %I_id::text ~ ''^[0-9]+$''', v_zone, v_tablename, v_zone);
				EXECUTE v_querystring INTO v_id;
            ELSIF v_id IS NULL AND v_featuretype = 'flwreg' THEN
                -- WARNING: this code is also in gw_fct_getfeatureupsert. If it needs to be changed here, it will most likely have to be changed there too.
                -- Get node id from initial clicked point
                SELECT * INTO v_noderecord1 FROM ve_node WHERE ST_DWithin(ST_startpoint(v_inputgeometry), ve_node.the_geom, v_arc_searchnodes)
                ORDER BY ST_Distance(ve_node.the_geom, ST_startpoint(v_inputgeometry)) LIMIT 1;
                -- Get order_id
                SELECT COALESCE(MAX(order_id), 0) + 1 INTO v_order_id FROM man_frelem WHERE node_id = v_noderecord1.node_id ::text; -- afegir flwreg_type
                -- Get flowreg_type
                v_querystring = concat('SELECT feature_class FROM cat_feature WHERE child_layer = ' , quote_nullable(v_tablename) ,' LIMIT 1');
                EXECUTE v_querystring INTO v_flwreg_type;
                -- Set nodarc_id
                v_id = concat(v_noderecord1.node_id,upper(substring(v_flwreg_type FROM 1 FOR 2)), v_order_id);
			ELSIF v_id IS NULL AND v_islayer is not true then
				v_id = (SELECT nextval('SCHEMA_NAME.urn_id_seq'));
			END IF;

			RAISE NOTICE 'User has permissions to edit table % using id %', v_tablename, v_id;
			-- call edit form function

			-- check null values

			v_querystring = 'SELECT gw_fct_getfeatureupsert($$' ||
				json_build_object(
					'data', json_build_object(
						'parameters', json_build_object(
							'table_id', v_tablename,
							'id', v_id,
							'reduced_geometry', v_inputgeometry,
							'device', v_device,
							'info_type', v_infotype,
							'tg_op', v_tg_op,
							'configtable', v_configtabledefined,
							'idname', v_idname,
							'columntype', column_type
						)
					)
				)::text || '$$);';

			EXECUTE v_querystring INTO v_fields;

		ELSIF v_editable = FALSE THEN

			RAISE NOTICE 'User has NOT permissions to edit table % using id %', v_tablename, v_id;
			-- call info form function

			v_querystring = 'SELECT gw_fct_getfeatureinfo($$' ||
				json_build_object(
					'data', json_build_object(
						'parameters', json_build_object(
							'table_id', v_tablename,
							'id', v_id,
							'device', v_device,
							'info_type', v_infotype,
							'configtable', v_configtabledefined,
							'idname', v_idname,
							'columntype', column_type
						)
					)
				)::text || '$$);';

			EXECUTE v_querystring INTO v_fields;
		END IF;
	END IF;

	--Formheader
	-- get column to use on header
	EXECUTE 'SELECT value::json->>'||quote_literal(v_sourcetable)||' FROM config_param_system WHERE parameter=''admin_formheader_field''' INTO v_formheader_field;

	-- get text to use when insert new feature
	EXECUTE 'SELECT value::json->>''newText'' FROM config_param_system WHERE parameter=''admin_formheader_field''' INTO v_formheader_new_text;

	-- get value to use on header
	IF v_sourcetable ='vf_hydrometer' THEN
		v_childtype = (SELECT (value::json->>'hydrometer')::json->>'childType' FROM config_param_system WHERE parameter='admin_formheader_field');
		v_formheader_field = (SELECT (value::json->>'hydrometer')::json->>'column' FROM config_param_system WHERE parameter='admin_formheader_field');
		v_querystring ='SELECT '||quote_ident(v_formheader_field)||' FROM '||quote_ident(v_sourcetable)||' WHERE hydrometer_id ='||quote_literal(v_id);
	ELSIF v_sourcetable ='element' THEN
		v_formheader_field = (SELECT (value::json->>'element')::json->>'column' FROM config_param_system WHERE parameter='admin_formheader_field');
		v_querystring ='SELECT '||quote_ident(v_formheader_field)||' FROM '||quote_ident(v_sourcetable)||' WHERE element_id ='||v_id::integer;
	ELSE
		IF v_id ~ '^\d+$' THEN
			v_querystring = 'SELECT '||quote_ident(v_formheader_field)||' FROM '||quote_ident(v_sourcetable)||' WHERE '||concat(v_sourcetable,'_id')||'='||v_id::integer;
		ELSE
			v_querystring = 'SELECT '||quote_ident(v_formheader_field)||' FROM '||quote_ident(v_sourcetable)||' WHERE '||concat(v_sourcetable,'_id')||'='||quote_literal(v_id);
		END IF;
	END IF;


	IF v_querystring IS NOT NULL THEN

		EXECUTE v_querystring INTO v_formheader_value;


		-- define v_headertext
		IF v_formheader_value IS NOT NULL THEN
			v_headertext= concat(v_childtype,' - ', v_formheader_value);
		ELSE
			v_headertext=concat(v_formheader_new_text,' ',v_childtype, ' (',v_id,')');
		END IF;
	END IF;

	--    Hydrometer 'id' fix
	IF v_idname = 'sys_hydrometer_id' THEN
		v_idname = 'hydrometer_id';
	END IF;

	-- Feature info
	v_featureinfo := json_build_object('permissions',v_permissions,'tableName',v_tablename,'idName',v_idname,'id',v_id,
		'featureType',v_featuretype, 'childType', v_childtype, 'tableParent',v_table_parent, 'schemaName', v_schemaname,
		'geometry', v_geometry, 'zoomCanvasMargin',v_canvasmargin);



	IF (v_fields->>'status')='Failed' THEN
		v_message = (v_fields->>'message');
		v_status = 'Failed';
	END IF;

	-- message for null
	IF v_tablename IS NULL THEN
		v_message='{"level":0, "text":"No feature found"}';
	END IF;

	--    Control NULL's
	v_forminfo := COALESCE(v_forminfo, '{}');
	v_featureinfo := COALESCE(v_featureinfo, '{}');
	v_parentfields := COALESCE(v_parentfields, '{}');
	v_fields := COALESCE(v_fields, '{}');
	v_message := COALESCE(v_message, '{}');
    v_editable := COALESCE(v_editable, 'false');

	v_forminfo := gw_fct_json_object_set_key(v_forminfo,'headerText',v_headertext);
	v_tabdata_lytname = (SELECT value::json->>'custom_form_tab_labels' FROM config_param_system WHERE parameter='admin_customform_param')::text;

	FOR v_record IN SELECT (a)->>'index' as index,(a)->>'text' as text  FROM json_array_elements(v_tabdata_lytname) a
	LOOP
		v_tabdata_lytname_result := gw_fct_json_object_set_key(v_tabdata_lytname_result,concat('index_', v_record.index), v_record.text);
	END LOOP;
	v_forminfo := gw_fct_json_object_set_key(v_forminfo,'tabDataLytNames', v_tabdata_lytname_result);


	v_forminfo:= concat(left(v_forminfo::text, length(v_forminfo::text) - 1), ',', v_form_orientation, '}');


	EXECUTE 'SET ROLE "'||v_prev_cur_user||'"';

	--    Return
	RETURN gw_fct_json_create_return(('{"status":"'||v_status||'", "message":'||v_message||', "version":"' || v_version || '"'||
      ',"body":{"form":' || v_forminfo ||
	     ', "feature":'|| v_featureinfo ||
	      ',"data":{"editable":' || v_editable ||
		      ',"parentFields":' || v_parentfields ||
		      ',"fields":' || v_fields ||
		      '}'||
		'}'||
	'}')::json, 3194, null, null, null);


END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2735

--drop function SCHEMA_NAME.gw_fct_admin_manage_child_views(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_manage_child_config(p_data json)
  RETURNS void AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_config($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},
"feature":{"catFeature":"SHUTOFF_VALVE"},
"data":{"filterFields":{}, "pageInfo":{}, "view_name":"ve_node_shutoffvalve", "feature_type":"node" }}$$);
*/

DECLARE

v_schemaname text;
v_insert_fields text;
v_view_name text;
v_feature_type text;
v_project_type text;
v_version text;
v_config_fields text;

rec record;

v_cat_feature text;
v_feature_class text;
v_man_fields text;
v_man_addfields text;
v_orderby integer;
v_datatype text;
v_widgettype text;
v_formname text;

BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- dissable temporary trigger to manage control_config
	UPDATE config_param_system SET value = 'FALSE'  WHERE parameter='admin_config_control_trigger';

	-- get input parameters
	v_cat_feature = ((p_data ->>'feature')::json->>'catFeature')::text;
	v_view_name = ((p_data ->>'data')::json->>'view_name')::text;
	v_feature_type = lower(((p_data ->>'data')::json->>'feature_type')::text);
    v_feature_class  = (SELECT lower(feature_class) FROM cat_feature where id=v_cat_feature);
    v_formname := 've_'||lower(v_feature_type);

	-- Register layer in sys_table only; role grants run once after MULTI-CREATE
	-- (gw_fct_admin_manage_child_views) or via gw_trg_cat_feature on single edits.
	IF v_view_name NOT IN (SELECT tableinfo_id FROM config_info_layer_x_type) THEN
        INSERT INTO sys_table(id, context, descript, sys_role)
        VALUES (v_view_name, (SELECT context FROM sys_table WHERE id = concat('ve_', v_feature_type)),
		concat('Custom editable view for ',v_cat_feature), 'role_edit') ON CONFLICT (id) DO NOTHING;
	END IF;

	EXECUTE 'GRANT ALL ON TABLE '||v_view_name||' TO role_edit';

	--manage tab hydrometer on netwjoin
	IF v_view_name IS NOT NULL AND v_project_type = 'WS' and v_feature_class = 'netwjoin' THEN
		INSERT INTO config_form_tabs ( formname, tabname, label, tooltip, sys_role, tabfunction, tabactions, device, orderby)
		SELECT v_view_name,  tabname, label, tooltip, sys_role, tabfunction, tabactions, device, orderby
		FROM config_form_tabs WHERE tabname in ('tab_hydrometer', 'tab_hydrometer_val') ON CONFLICT (formname, tabname) DO NOTHING;
	END IF;

	IF v_view_name NOT IN (SELECT tableinfo_id FROM config_info_layer_x_type) THEN
		INSERT INTO config_info_layer_x_type(tableinfo_id, infotype_id, tableinfotype_id) VALUES (v_view_name,1,v_view_name)
		ON CONFLICT (tableinfo_id, infotype_id) DO NOTHING;
	END IF;

	--select list of fields different than id from config_form_fields
	EXECUTE 'SELECT DISTINCT string_agg(col.attname::text,'' ,'') FROM (
	SELECT a.attname
	FROM pg_catalog.pg_attribute a
	JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
	JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
	WHERE c.relname = ''config_form_fields''
	  AND n.nspname = '''||v_schemaname||'''
	  AND a.attnum > 0
	  AND NOT a.attisdropped
	  AND a.attname != ''id''
	ORDER BY a.attnum
	) col;'
	INTO v_config_fields;

	--select list of fields different than id and formname from config_form_fields
	EXECUTE 'SELECT DISTINCT string_agg(col.attname::text,'' ,'') FROM (
	SELECT a.attname
	FROM pg_catalog.pg_attribute a
	JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
	JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
	WHERE c.relname = ''config_form_fields''
	  AND n.nspname = '''||v_schemaname||'''
	  AND a.attnum > 0
	  AND NOT a.attisdropped
	  AND a.attname NOT IN (''id'', ''formname'', ''formtype'')
	ORDER BY a.attnum
	) col;'
	INTO v_insert_fields;

	--insert configuration copied from the parent view config
	EXECUTE 'INSERT INTO config_form_fields('||v_config_fields||')
	SELECT '''||v_view_name||''', ''form_feature'', '||v_insert_fields||' FROM config_form_fields
	WHERE formname='''||v_formname||'''
	ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING';

	--update configuration of man_type fields setting featurecat related to the view
	IF v_project_type = 'WS' THEN
		EXECUTE 'UPDATE config_form_fields SET dv_querytext = concat(dv_querytext, '' OR '''||quote_literal(upper(v_cat_feature))||''' = ANY(featurecat_id::text[])'')
		WHERE formname = '''||v_view_name||'''
		AND (columnname =''location_type'' OR columnname =''fluid_type'' OR columnname =''function_type'' OR columnname =''category_type'')
		AND dv_querytext NOT ILIKE ''% OR%'';';
	ELSE
		EXECUTE 'UPDATE config_form_fields SET dv_querytext = concat(dv_querytext, '' OR '''||quote_literal(upper(v_cat_feature))||''' = ANY(featurecat_id::text[])'')
		WHERE formname = '''||v_view_name||'''
		AND (columnname =''location_type'' OR columnname =''function_type'' OR columnname =''category_type'')
		AND dv_querytext NOT ILIKE ''% OR%'';';
	END IF;

	
	UPDATE config_form_fields SET dv_querytext = (
	SELECT concat(dv_querytext, ' AND ', v_feature_type, '_type = ', quote_literal(v_cat_feature))
	FROM config_form_fields WHERE formname = v_view_name AND columnname = concat(v_feature_type, 'cat_id')
	) WHERE formname = v_view_name AND columnname = concat(v_feature_type, 'cat_id');

	-- Update brand_id and model_id and dvquerytext for catalog
	EXECUTE 'UPDATE config_form_fields SET dv_querytext = ''SELECT id, id as idval FROM cat_brand WHERE '''||quote_literal(upper(v_cat_feature))||''' = ANY(featurecat_id::text[])''
	WHERE formname = '''||v_view_name||''' AND columnname =''brand_id'';';

	EXECUTE 'UPDATE config_form_fields SET dv_querytext = ''SELECT id, id as idval FROM cat_brand_model WHERE '''||quote_literal(upper(v_cat_feature))||''' = ANY(featurecat_id::text[])''
	WHERE formname = '''||v_view_name||''' AND columnname =''model_id'';';

	--select columns from man_* table without repeating the identifier
	v_man_fields = 'SELECT DISTINCT a.attname::text AS column_name,
	CASE t.typname
		WHEN ''varchar'' THEN ''character varying''
		WHEN ''int4'' THEN ''integer''
		WHEN ''int2'' THEN ''smallint''
		WHEN ''bool'' THEN ''boolean''
		ELSE t.typname
	END::text AS data_type,
	CASE WHEN t.typname IN (''numeric'', ''decimal'') THEN ((a.atttypmod - 4) >> 16) & 65535 END AS numeric_precision,
	CASE WHEN t.typname IN (''numeric'', ''decimal'') THEN (a.atttypmod - 4) & 65535 END AS numeric_scale
	FROM pg_catalog.pg_attribute a
	JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
	JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
	JOIN pg_catalog.pg_type t ON t.oid = a.atttypid
	WHERE c.relname = ''man_'||lower(v_feature_class)||'''
	  AND n.nspname = '''||v_schemaname||'''
	  AND a.attnum > 0
	  AND NOT a.attisdropped
	  AND a.attname != '''||lower(v_feature_type)||'_id''
	GROUP BY a.attname, t.typname, a.atttypmod;';


	--insert configuration from the man_* tables of the feature type
	FOR rec IN  EXECUTE v_man_fields LOOP

		--capture max layout_id for the view
		EXECUTE 'SELECT max(layoutorder::integer) + 1 FROM config_form_fields WHERE formname = '''||v_view_name||''' AND  layoutname=''lyt_data_1'';'
		INTO v_orderby;

		--transform data and widget types
		IF rec.data_type = 'character varying' OR  rec.data_type = 'text' THEN
			v_datatype='string';
			v_widgettype='text';
		ELSIF rec.data_type = 'numeric' THEN
			v_datatype='double';
			v_widgettype='text';
		ELSIF rec.data_type = 'integer' OR rec.data_type = 'smallint' THEN
			v_datatype='integer';
			v_widgettype='text';
		ELSIF rec.data_type = 'boolean' THEN
			v_datatype='boolean';
			v_widgettype='check';
		ELSIF rec.data_type = 'date' THEN
			v_datatype='date';
			v_widgettype='datetime';
		ELSE
			v_datatype='string';
			v_widgettype='text';
		END IF;

		--insert into config_form_fields
		INSERT INTO config_form_fields (formname, formtype, columnname, tabname, datatype, widgettype, layoutname, layoutorder,
			label, ismandatory, isparent, iseditable, isautoupdate)
		VALUES (v_view_name,'form_feature', rec.column_name, 'tab_data', v_datatype, v_widgettype, 'lyt_data_1',v_orderby,
			rec.column_name, false, false,true,false) ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

	END LOOP;

	--select all already created addfields
	v_man_addfields = 'SELECT * FROM sys_addfields WHERE active = TRUE AND (cat_feature_id IS NULL OR cat_feature_id='''||v_cat_feature||''');';

	--insert configuration for the addfields of the feature type
	FOR rec IN EXECUTE v_man_addfields LOOP
		--capture max layout_id for the view
		EXECUTE 'SELECT max(layoutorder::integer) + 1 FROM config_form_fields WHERE formname = '''||v_view_name||''' AND  layoutname=''lyt_data_1'';'
		INTO v_orderby;

		--transform data and widget types
		IF rec.datatype_id = 'numeric' THEN
			v_datatype='double';
		ELSE
			v_datatype=rec.datatype_id;
		END IF;

		IF  rec.datatype_id = 'boolean' THEN
			v_widgettype='check';
		ELSIF rec.datatype_id = 'date' THEN
			v_widgettype='datetime';
		ELSE
			v_widgettype='text';
		END IF;

		--insert into config_form_fields
		INSERT INTO config_form_fields (formname,formtype,columnname,datatype,widgettype, layoutname,layoutorder,
			label, ismandatory,isparent,iseditable,isautoupdate, tabname)
		VALUES (v_view_name,'form_feature',rec.param_name, v_datatype,v_widgettype, 'lyt_data_1',v_orderby,
			rec.param_name, rec.is_mandatory, false,rec.iseditable,false, 'tab_data') ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

	END LOOP;

	-- enable trigger to manage control_config
	UPDATE config_param_system SET value = 'TRUE'  WHERE parameter='admin_config_control_trigger';

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

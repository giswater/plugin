/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2716
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_manage_child_views(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_manage_child_views(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE

-- create views and add config_form_fields columns only if is empty
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{"catFeature":"T"},"data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-CREATE" }}$$);

-- create views and add config_form_fields columns only if is empty
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{},
 "data":{"filterFields":{}, "pageInfo":{}, "action":"MULTI-CREATE" }}$$);

--only replace views, not delete nothing but add a new one column on config_form_fields (newColumn) copying values from ONE UNIQUE parent
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"featureType":"NODE"},
 "data":{"filterFields":{}, "pageInfo":{}, "action":"MULTI-UPDATE", "newColumn":"workcat_id_plan" }}$$);

--only replace views, not delete nothing but add a new one column on config_form_fields (newColumn) copying values from ONE UNIQUE MAN-TABLE
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"systemId":"CONDUIT"},
 "data":{"filterFields":{}, "pageInfo":{}, "action":"MULTI-UPDATE", "newColumn":"inlet_offset" }}$$);

--only replace views, not delete nothing but add a new one column on config_form_fields (newColumn) copying values from parent
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{},
"feature":{"catFeature":"PIPE"}, "data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-UPDATE", "newColumn":"workcat_id_plan" }}$$);

--delete views
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{},
 "data":{"filterFields":{}, "pageInfo":{}, "action":"MULTI-DELETE" }}$$);


select *  from SCHEMA_NAME.config_form_fields where formname = 've_arc' and columnname = 'workcat_id_plan'
*/

DECLARE

v_schemaname text = 'SCHEMA_NAME';
v_cat_feature text;
v_viewname text;
v_feature_type text;
v_feature_class text;
v_feature_childtable_name text;
v_parent_layer text;

rec record;
v_project_type text;
v_querytext text;
v_data_view json;
v_action text;
v_childview text;
v_return_status text = 'Failed';
v_return_msg text = 'Process finished with some errors';
v_error_context text;
v_newcolumn text;
v_query json;
v_sys_feature_class text;
v_parent text;


BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;

	-- get project type
 	IF (SELECT tablename FROM pg_tables WHERE schemaname = v_schemaname AND tablename = 'inp_storage') IS NOT NULL THEN
		v_project_type = 'UD';
 	ELSE
		v_project_type = 'WS';
 	END IF;

	v_cat_feature = ((p_data ->>'feature')::json->>'catFeature')::text;
	v_action = ((p_data ->>'data')::json->>'action')::text;
	v_newcolumn = ((p_data ->>'data')::json->>'newColumn')::text;
	v_feature_type = ((p_data ->>'feature')::json->>'featureType')::text;
	v_sys_feature_class = ((p_data ->>'feature')::json->>'systemId')::text;
	v_parent = ((p_data ->>'feature')::json->>'parentLayer')::text;

	IF v_cat_feature IS NULL THEN
		v_cat_feature = (SELECT id FROM cat_feature LIMIT 1);
	END IF;

	IF v_action = 'MULTI-DELETE' THEN

		FOR v_childview IN
			SELECT child_layer
			FROM cat_feature
			WHERE child_layer IS NOT NULL
			AND (v_parent IS NULL OR parent_layer = v_parent)
		LOOP
			EXECUTE 'DROP VIEW IF EXISTS '||v_childview||'';
			PERFORM gw_fct_debug(concat('{"data":{"msg":"Deleted layer: ", "variables":"',v_childview,'"}}')::json);

		END LOOP;

		v_return_status = 'Accepted';
		v_return_msg = 'Multi-delete view successfully';


	ELSIF v_action = 'MULTI-UPDATE' THEN

		IF v_sys_feature_class IS NOT NULL THEN
			v_querytext = 'SELECT child_layer, id, parent_layer FROM cat_feature WHERE child_layer IS NOT NULL AND feature_class = '||quote_literal(v_sys_feature_class);

		ELSIF v_feature_type IS NOT NULL THEN
			v_querytext = 'SELECT child_layer, id, parent_layer FROM cat_feature WHERE child_layer IS NOT NULL AND feature_type = '||quote_literal(v_feature_type);

		ELSIF v_feature_type IS NULL THEN
			v_querytext = 'SELECT child_layer, id, parent_layer FROM cat_feature WHERE child_layer IS NOT NULL';

		END IF;


		FOR v_childview, v_cat_feature, v_parent_layer IN EXECUTE v_querytext
		LOOP


			-- delete existing view
			EXECUTE 'DROP VIEW IF EXISTS '||v_childview||' CASCADE';
			PERFORM gw_fct_debug(concat('{"data":{"msg":"Deleted layer: ", "variables":"',v_childview,'"}}')::json);

			-- create new view with all columns from parent/man/addfields
			v_query = concat('{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"catFeature":"',v_cat_feature,
			'"},"data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-CREATE"}}');

			PERFORM gw_fct_admin_manage_child_views(v_query);

		END LOOP;


		v_return_status = 'Accepted';
		v_return_msg = 'Multi-update view successfully';

	ELSIF v_action = 'SINGLE-UPDATE' THEN

		SELECT child_layer, parent_layer INTO v_childview, v_parent_layer FROM cat_feature WHERE id = v_cat_feature;


		-- delete existing view
		EXECUTE 'DROP VIEW IF EXISTS '||v_childview||' CASCADE';
		PERFORM gw_fct_debug(concat('{"data":{"msg":"Deleted layer: ", "variables":"',v_childview,'"}}')::json);

		-- create new view with all columns from parent/man/addfields
		v_query = concat('{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"catFeature":"',v_cat_feature,
		'"},"data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-CREATE"}}');

		PERFORM gw_fct_admin_manage_child_views(v_query);

		v_return_status = 'Accepted';
		v_return_msg = 'Single-update view successfully';


	ELSIF v_action = 'MULTI-CREATE' THEN

		v_querytext = 'SELECT cat_feature.* FROM cat_feature ORDER BY id';

		FOR rec IN EXECUTE v_querytext LOOP

			--get the system type and feature_class of the feature and view name
			v_feature_type = lower(rec.feature_type);
			v_feature_class  = lower(rec.feature_class);
			v_parent_layer = lower(rec.parent_layer);
			v_cat_feature = rec.id;
			v_feature_childtable_name := 'man_' || v_feature_type || '_' || lower(v_cat_feature);


			--create a child view name if doesnt exist
			IF (SELECT child_layer FROM cat_feature WHERE id=rec.id) IS NULL THEN
				UPDATE cat_feature SET child_layer=concat(v_parent_layer,'_',lower(id)) WHERE id=rec.id;
			END IF;
			v_viewname = (SELECT child_layer FROM cat_feature WHERE id=rec.id);

			IF v_viewname ilike '%-%' OR v_viewname ilike '% %' OR v_viewname ilike '%.%' THEN
				v_viewname = replace(replace(replace(v_viewname,'-','_'),' ','_'),'.','_');
				UPDATE cat_feature SET child_layer=v_viewname WHERE id=rec.id;
			END IF;

			-- drop view before to recreate it if exists
			IF v_viewname IS NOT NULL THEN
				EXECUTE 'DROP VIEW IF EXISTS '||v_viewname;
			END IF;

			v_data_view = '{
			"schema":"'||v_schemaname ||'",
			"body":{"viewname":"'||v_viewname||'",
				"feature_type":"'||v_feature_type||'",
				"parent_layer":"'||v_parent_layer||'",
				"feature_class":"'||v_feature_class||'",
				"feature_cat":"'||v_cat_feature||'",
				"feature_childtable_name":"'||v_feature_childtable_name||'"
				}
			}';

			SELECT gw_fct_admin_manage_child_views_view(v_data_view) INTO v_return_status, v_return_msg;

		END LOOP;

		v_return_status = 'Accepted';
		v_return_msg = 'Multi-create view successfully';

	ELSIF v_action = 'SINGLE-CREATE' THEN

		--get the system type and feature_class of the feature and view name
		v_feature_type = (SELECT lower(feature_type) FROM cat_feature where id=v_cat_feature);
		v_feature_class  = (SELECT lower(feature_class) FROM cat_feature where id=v_cat_feature);
		v_parent_layer = (SELECT lower(parent_layer) FROM cat_feature where id=v_cat_feature);
		v_feature_childtable_name := 'man_' || v_feature_type || '_' || lower(v_cat_feature);

		--create a child view name if doesnt exist
		IF (SELECT child_layer FROM cat_feature WHERE id=v_cat_feature) IS NULL THEN
			UPDATE cat_feature SET child_layer=concat(v_parent_layer,'_',lower(id)) WHERE id=v_cat_feature;
		END IF;
		v_viewname = (SELECT child_layer FROM cat_feature WHERE id=v_cat_feature);

		IF v_viewname ilike '%-%' OR v_viewname ilike '% %' OR v_viewname ilike '%.%' THEN
				v_viewname = replace(replace(replace(v_viewname,'-','_'),' ','_'),'.','_');
			UPDATE cat_feature SET child_layer=v_viewname WHERE id=v_cat_feature;
		END IF;

		-- drop view before to recreate it if exists
		IF v_viewname IS NOT NULL THEN
			EXECUTE 'DROP VIEW IF EXISTS '||v_viewname;
		END IF;

		-- if addfield table does not exists (when creating a new object in cat_feature)
		IF (SELECT EXISTS (
			SELECT 1
			FROM pg_catalog.pg_class c
			JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
			WHERE n.nspname = CURRENT_SCHEMA
			  AND c.relname = v_feature_childtable_name
			  AND c.relkind IN ('r', 'p')
		)) IS FALSE THEN
			
			-- create the addfields table and add as many columns as common addfields
			FOR rec IN SELECT param_name, datatype_id FROM sys_addfields WHERE cat_feature_id IS NULL
			LOOP

				EXECUTE 'SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"'||v_cat_feature||'"},
				"data":{"action":"CREATE", "parameters":{"columnname":"'||rec.param_name||'", "datatype":"'||rec.datatype_id||'",
				"widgettype":"check", "label":"'||rec.param_name||'","ismandatory":"False",
				"active":"True", "iseditable":"True", "layoutname":"lyt_data_1"}}}$$)';
				
			END LOOP;
		
		END IF;

		v_data_view = '{
		"schema":"'||v_schemaname ||'",
		"body":{"viewname":"'||v_viewname||'",
			"feature_type":"'||v_feature_type||'",
			"parent_layer":"'||v_parent_layer||'",
			"feature_class":"'||v_feature_class||'",
			"feature_cat":"'||v_cat_feature||'",
			"feature_childtable_name":"'||v_feature_childtable_name||'"
			}
		}';

		SELECT gw_fct_admin_manage_child_views_view(v_data_view) INTO v_return_status, v_return_msg;

		v_return_status = 'Accepted';
		v_return_msg = 'Single-create view successfully';

	END IF;

	-- manage permissions
    IF v_action <> 'MULTI-DELETE' THEN
        --PERFORM gw_fct_admin_role_permissions();
    END IF;

	--  Return
	RETURN ('{"status":"'||v_return_status||'", "message":{"level":0, "text":"'||v_return_msg||'"},"body":{"form":{}'||',"data":{}}'||'}')::json;


	--EXCEPTION WHEN OTHERS THEN
	--GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	--RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;



END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
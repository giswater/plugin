/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2758

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_trg_update_child_view()cascade;
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_cat_feature()
  RETURNS trigger AS
$BODY$


DECLARE
v_schemaname text;
v_viewname text;
v_definition text;
v_id text;
v_layout text;
v_projecttype text;
v_layoutorder integer;
v_partialquerytext text;
v_querytext text;
v_table text;
v_feature_field_id text;
v_feature record;
v_query text;
v_arc_epa text;
v_new_child_layer text;
v_old_child_layer text;
v_isrenameview boolean;
v_parent_layer text;

BEGIN

	-- search path
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- get input parameters
	v_schemaname = 'SCHEMA_NAME';
	v_table:= TG_ARGV[0];


	--  Get project type
	SELECT project_type INTO v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;

	SELECT json_extract_path_text (value::json,'rename_view_x_id')::boolean INTO v_isrenameview FROM config_param_system
	WHERE parameter='admin_manage_cat_feature';


	IF (TG_OP = 'INSERT' OR  TG_OP = 'UPDATE') THEN

		--Controls on update or insert of cat_feature.id check if the new id or child layer has accents, dots or dashes. If so, give an error.
		v_id = array_to_string(ts_lexize('unaccent',NEW.id),',','*');

		IF v_id IS NOT NULL OR NEW.id ilike '%.%' OR NEW.id ilike '%-%' THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3038", "function":"2758","parameters":{"characters":"'||NEW.id||'"}}}$$);';
		END IF;

		v_id = array_to_string(ts_lexize('unaccent',NEW.child_layer),',','*');

		IF v_id IS NOT NULL OR NEW.child_layer ilike '%-%' OR NEW.child_layer ilike '%.%' THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3038", "function":"2758","parameters":{"characters":"'||NEW.child_layer||'"}}}$$);';
		END IF;

		-- set v_id
		v_id = (lower(NEW.id));
	END IF;


	-- manage sys_param_user parameters
	IF (TG_OP = 'INSERT' OR  TG_OP = 'UPDATE') THEN

		-- set layoutname
		v_layout = concat('lyt_', lower(NEW.feature_type));

		-- set layoutorder
		SELECT max(layoutorder)+1 INTO v_layoutorder FROM sys_param_user WHERE formname='config' and layoutname=v_layout;

		IF v_layoutorder IS NULL THEN
			v_layoutorder=1;
		END IF;

		v_table = concat('cat_',lower(NEW.feature_type));

		v_partialquerytext = concat('JOIN cat_feature ON cat_feature.id = ',v_table,'.',lower(NEW.feature_type),'_type WHERE cat_feature.id = ',quote_literal(NEW.id));
		v_feature_field_id = concat (lower(NEW.feature_type), 'cat_id');

		v_querytext = concat('SELECT ',v_table,'.id, ', v_table,'.id AS idval FROM ', v_table,' ', v_partialquerytext);

		-- insert parameter
		IF TG_OP = 'UPDATE' THEN
			DELETE FROM sys_param_user WHERE id = concat('feat_',lower(OLD.id),'_vdefault');
		END IF;

		INSERT INTO sys_param_user(id, formname, descript, sys_role, label, isenabled, layoutname, layoutorder,
		dv_querytext, feature_field_id, project_type, isparent, isautoupdate, datatype, widgettype, ismandatory, iseditable)
		VALUES (concat('feat_',v_id,'_vdefault'),'config',concat ('Value default catalog for ',v_id,' cat_feature'), 'role_edit', concat ('Default catalog for ', v_id), true, v_layout ,v_layoutorder,
		v_querytext, v_feature_field_id, lower(v_projecttype),false,false,'text', 'combo', true, true)
		ON CONFLICT (id) DO NOTHING;

	END IF;

	IF TG_OP = 'INSERT' THEN

		IF NEW.feature_class IN ('VALVE', 'PUMP', 'METER') THEN

            SELECT concat('ve_', lower(feature_type), '_', lower(id)) INTO v_viewname FROM cat_feature WHERE id=NEW.id;

            INSERT INTO config_form_tabs (formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
            VALUES(v_viewname, 'tab_data', 'Data', 'Data', 'role_basic', NULL,
            '[{
            "actionName": "actionEdit",
            "disabled": false},
            {"actionName": "actionZoom","disabled": false},
            {"actionName": "actionCentered","disabled": false},
            {"actionName": "actionZoomOut","disabled": false},
            {"actionName": "actionCatalog","disabled": false},
            {"actionName": "actionWorkcat","disabled": false},
            {"actionName": "actionCopyPaste","disabled": false},
            {"actionName": "actionLink","disabled": false},
            {"actionName": "actionSetToArc","disabled": false},
            {"actionName": "actionMapZone","disabled": false},
            {"actionName": "actionGetParentId","disabled": false},
            {"actionName": "actionGetArcId","disabled": false},
            {"actionName": "actionRotation","disabled": false},
            {"actionName": "actionInterpolate","disabled": false}
            ]'::json, 0, '{4,5}') ON CONFLICT (formname, tabname) DO NOTHING;

        END IF;

		EXECUTE 'SELECT lower(id) as id, type, concat(''man_'',lower(id)) as man_table, epa_default, 
		CASE WHEN epa_default IS NOT NULL THEN concat(''inp_'',lower(epa_default)) END AS epa_table 
		FROM sys_feature_class WHERE id='||quote_literal(NEW.feature_class)
		INTO v_feature;

        SELECT parent_layer INTO v_parent_layer FROM cat_feature WHERE id=NEW.id;
		IF v_parent_layer IS NULL THEN
			EXECUTE 'UPDATE cat_feature SET parent_layer =  concat(''ve_'',lower('||quote_literal(v_feature.type)||'))
			WHERE id = '||quote_literal(NEW.id)||';';
		END IF;
		EXECUTE 'UPDATE cat_feature SET feature_type = '||quote_literal(v_feature.type)||' WHERE id = '||quote_literal(NEW.id)||';';

		IF lower(v_feature.type)='arc' THEN
			EXECUTE 'INSERT INTO cat_feature_arc (id, epa_default)
			VALUES ('||quote_literal(NEW.id)||', '||quote_literal(v_feature.epa_default)||');';

		ELSIF lower(v_feature.type)='node' THEN
			EXECUTE 'INSERT INTO cat_feature_node (id, epa_default, choose_hemisphere, isarcdivide, num_arcs)
			VALUES ('||quote_literal(NEW.id)||', '||quote_literal(v_feature.epa_default)||', TRUE, TRUE, 2)';

		ELSIF lower(v_feature.type)='connec' THEN
			EXECUTE 'INSERT INTO cat_feature_connec (id)
			VALUES ('||quote_literal(NEW.id)||');';

		ELSIF lower(v_feature.type)='gully' THEN
			EXECUTE 'INSERT INTO cat_feature_gully (id)
			VALUES ('||quote_literal(NEW.id)||');';

		ELSIF lower(v_feature.type)='element' THEN
			EXECUTE 'INSERT INTO cat_feature_element (id, epa_default)
			VALUES ('||quote_literal(NEW.id)||', '||quote_literal(v_feature.epa_default)||');';

		ELSIF lower(v_feature.type)='link' THEN
			EXECUTE 'INSERT INTO cat_feature_link (id)
			VALUES ('||quote_literal(NEW.id)||');';
		END IF;

		--create child view
		v_query='{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"catFeature":"'||NEW.id||'"},
		"data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-CREATE" }}';
		PERFORM gw_fct_admin_manage_child_views(v_query::json);

		--insert definition into config_info_layer_x_type if its not present already
		IF NEW.child_layer NOT IN (SELECT tableinfo_id from config_info_layer_x_type)
		and NEW.child_layer IS NOT NULL THEN
			INSERT INTO config_info_layer_x_type (tableinfo_id,infotype_id,tableinfotype_id)
			VALUES (NEW.child_layer,1,NEW.child_layer);
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF NEW.feature_class IN ('VALVE', 'PUMP', 'METER') THEN

			SELECT concat('ve_', lower(feature_type), '_', lower(id)) INTO v_viewname FROM cat_feature WHERE id=NEW.id;

			UPDATE config_form_tabs SET formname = v_viewname WHERE formname = concat('ve_', lower(NEW.feature_type), '_', lower(OLD.id));

		END IF;

		SELECT child_layer INTO v_viewname FROM cat_feature WHERE id = NEW.id;
		-- update child views
		--on update and change of cat_feature.id or child layer name
		IF NEW.id != OLD.id THEN

			IF v_viewname IS NOT NULL THEN

				IF  (SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = v_schemaname
				AND table_name = v_viewname)) = true THEN

					--get the old view definition
					EXECUTE 'SELECT pg_get_viewdef('''||v_schemaname||'.'||v_viewname||''', true);'
					INTO v_definition;

					--replace cat_feature.id in the view definition
					v_definition = replace(v_definition,quote_literal(OLD.id),quote_literal(NEW.id));

					--replace the existing view and drop the old trigger
					EXECUTE 'CREATE OR REPLACE VIEW '||v_schemaname||'.'||NEW.child_layer||' AS '||v_definition||';';
					EXECUTE 'DROP TRIGGER IF EXISTS gw_trg_edit_'||lower(NEW.feature_type)||'_'||lower(OLD.id)||' ON '||v_viewname||';';

					EXECUTE 'CREATE TRIGGER gw_trg_edit_'||lower(NEW.feature_type)||'_'||lower(NEW.id)||'
					INSTEAD OF INSERT OR UPDATE OR DELETE ON '||v_viewname||' FOR EACH ROW EXECUTE
					PROCEDURE gw_trg_edit_'||lower(NEW.feature_type)||'('||quote_literal(NEW.id)||');';

				ELSE
					IF NEW.feature_class <> 'LINK' THEN
						v_query='{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"catFeature":"'||NEW.id||'"},
						"data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-CREATE" }}';
						PERFORM gw_fct_admin_manage_child_views(v_query::json);
					END IF;

					--insert definition into config_info_layer_x_type if its not present already
					IF NEW.child_layer NOT IN (SELECT tableinfo_id from config_info_layer_x_type)
					and NEW.child_layer IS NOT NULL THEN
						INSERT INTO config_info_layer_x_type (tableinfo_id,infotype_id,tableinfotype_id)
						VALUES (NEW.child_layer,1,NEW.child_layer);
					END IF;

					EXECUTE 'DROP TRIGGER IF EXISTS gw_trg_edit_'||lower(NEW.feature_type)||'_'||lower(OLD.id)||' ON '||v_viewname||';';
				END IF;
			END IF;
		END IF;

		--if child layer name has changed OR id has changed and p, rename it
		IF (NEW.child_layer != OLD.child_layer  AND NEW.child_layer IS NOT NULL ) OR
		(NEW.id != OLD.id AND v_isrenameview IS TRUE )THEN

			IF (NEW.child_layer != OLD.child_layer  AND NEW.child_layer IS NOT NULL ) THEN
				v_old_child_layer=OLD.child_layer;
				v_viewname=NEW.child_layer;
			ELSE
				v_old_child_layer=NEW.child_layer;
				v_viewname=concat('ve_',lower(NEW.feature_type),'_',lower(NEW.id));
			END IF;

			IF v_viewname IS NOT NULL THEN
				IF  (SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = v_schemaname
				AND table_name = v_old_child_layer)) = true THEN

					--get the old view definition
					EXECUTE 'SELECT pg_get_viewdef('''||v_schemaname||'.'||v_old_child_layer||''', true);'
					INTO v_definition;

					--replace the existing view
					EXECUTE 'CREATE OR REPLACE VIEW '||v_schemaname||'.'||v_viewname||' AS '||v_definition||';';
					EXECUTE 'DROP VIEW IF EXISTS '||v_schemaname||'.'||v_old_child_layer||';';
					-- addfields table man_<feature_type>_<id> exists only when that feature type has custom fields
					IF (SELECT EXISTS (
						SELECT 1
						FROM pg_catalog.pg_class c
						JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
						WHERE n.nspname = v_schemaname
						  AND c.relname = 'man_' || lower(OLD.feature_type) || '_' || lower(OLD.id)
						  AND c.relkind IN ('r', 'p')
					)) IS TRUE THEN
						EXECUTE 'ALTER TABLE man_' ||lower(OLD.feature_type)||'_'||lower(OLD.id)||' RENAME TO man_'||lower(NEW.feature_type)||'_'||lower(NEW.id)||';';
					END IF;
					EXECUTE 'DROP TRIGGER IF EXISTS gw_trg_edit_'||lower(NEW.feature_type)||'_'||lower(OLD.id)||' ON '||v_viewname||';';

					EXECUTE 'CREATE TRIGGER gw_trg_edit_'||lower(NEW.feature_type)||'_'||lower(NEW.id)||'
					INSTEAD OF INSERT OR UPDATE OR DELETE ON '||v_viewname||' FOR EACH ROW EXECUTE
					PROCEDURE gw_trg_edit_'||lower(NEW.feature_type)||'('||quote_literal(NEW.id)||');';

					EXECUTE 'UPDATE cat_feature SET child_layer='||quote_literal(v_viewname)||' WHERE id='||quote_literal(NEW.id)||';';
				ELSE

					EXECUTE 'DROP VIEW IF EXISTS '||v_schemaname||'.'||v_old_child_layer||';';
					v_query='{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"catFeature":"'||NEW.id||'"},
					"data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-CREATE" }}';
					PERFORM gw_fct_admin_manage_child_views(v_query::json);

					--insert definition into config_info_layer_x_type if its not present already
					IF NEW.child_layer NOT IN (SELECT tableinfo_id from config_info_layer_x_type)
					and NEW.child_layer IS NOT NULL THEN
						INSERT INTO config_info_layer_x_type (tableinfo_id,infotype_id,tableinfotype_id)
						VALUES (NEW.child_layer,1,NEW.child_layer) ON CONFLICT (tableinfo_id, infotype_id) DO NOTHING;
					END IF;
				END IF;
			END IF;

			--delete configuration from config_form_fields
			DELETE FROM config_form_fields where formname=OLD.child_layer AND formtype = 'form_feature';

			--delete definition from config_info_layer_x_type
			DELETE FROM config_info_layer_x_type where tableinfo_id=OLD.child_layer OR tableinfotype_id=OLD.child_layer;

			--delete definition from sys_table
			DELETE FROM sys_table where id=OLD.child_layer;

			EXECUTE 'SELECT gw_fct_admin_manage_child_config($${"client":{"device":4, "infoType":1, "lang":"ES"},
			"form":{}, 	"feature":{"catFeature":"'||NEW.id||'"},
			"data":{"filterFields":{}, "pageInfo":{}, "view_name":"'||v_viewname||'",
			"feature_type":"'||lower(NEW.feature_type)||'" }}$$);';
			PERFORM gw_fct_admin_role_permissions();

			--manage tab hydrometer on netwjoin
			IF  v_projecttype = 'WS' and OLD.feature_class = 'NETWJOIN' THEN
				DELETE FROM config_form_tabs where formname=v_old_child_layer and tabname in ('tab_hydrometer', 'tab_hydrometer_val');
			END IF;

		ELSIF NEW.feature_type !=OLD.feature_type or NEW.feature_class !=OLD.feature_class THEN

			EXECUTE 'DROP VIEW IF EXISTS '||NEW.child_layer||';';

			--delete configuration from config_form_fields
			DELETE FROM config_form_fields where formname=NEW.child_layer AND formtype = 'form_feature';

			--delete definition from config_info_layer_x_type
			DELETE FROM config_info_layer_x_type where tableinfo_id=NEW.child_layer OR tableinfo_id=OLD.child_layer;

			EXECUTE 'SELECT lower(id) as id,type, concat(''man_'',lower(id)) as man_table, epa_default,
			CASE WHEN epa_default IS NOT NULL THEN concat(''inp_'',lower(epa_default)) END AS epa_table
			FROM sys_feature_class WHERE id='||quote_literal(NEW.feature_class)||';'
			INTO v_feature;

			v_new_child_layer = replace(NEW.child_layer,lower(OLD.feature_type),lower(NEW.feature_type));

			EXECUTE 'UPDATE cat_feature SET parent_layer = concat(''ve_'',lower('||quote_literal(NEW.feature_type)||')),
			child_layer = '||quote_literal(v_new_child_layer)||' WHERE id = '||quote_literal(NEW.id)||';';

			EXECUTE 'DELETE FROM cat_feature_'||lower(OLD.feature_type)||' WHERE id = '||quote_literal(NEW.id)||';';

			IF lower(NEW.feature_type)='arc' THEN
				EXECUTE 'INSERT INTO cat_feature_arc (id, epa_default)
				VALUES ('||quote_literal(NEW.id)||','||quote_literal(v_feature.epa_default)||')';
			ELSIF lower(NEW.feature_type)='node' THEN
				EXECUTE 'INSERT INTO cat_feature_node (id, epa_default, choose_hemisphere, isarcdivide, num_arcs)
				VALUES ('||quote_literal(NEW.id)||','||quote_literal(v_feature.epa_default)||', TRUE, TRUE, 2);';
			ELSIF lower(NEW.feature_type)='connec' THEN
				EXECUTE 'INSERT INTO cat_feature_connec (id)
				VALUES ('||quote_literal(NEW.id)||');';
			ELSIF lower(NEW.feature_type)='link' THEN
				EXECUTE 'INSERT INTO cat_feature_link (id)
				VALUES ('||quote_literal(NEW.id)||');';
			ELSIF lower(NEW.feature_type)='gully' THEN
				EXECUTE 'INSERT INTO cat_feature_gully (id)
				VALUES ('||quote_literal(NEW.id)||');';
			ELSIF lower(NEW.feature_type)='element' THEN
				EXECUTE 'INSERT INTO cat_feature_element (id, epa_default)
				VALUES ('||quote_literal(NEW.id)||','||quote_literal(v_feature.epa_default)||')';
			END IF;

			--delete configuration from config_form_fields
			DELETE FROM config_form_fields where formname=OLD.child_layer AND formtype = 'form_feature';

			--create child view
			v_query='{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"catFeature":"'||NEW.id||'"},
			"data":{"filterFields":{}, "pageInfo":{}, "action":"SINGLE-CREATE" }}';
			PERFORM gw_fct_admin_manage_child_views(v_query::json);

			IF  v_projecttype = 'WS' and OLD.feature_class = 'NETWJOIN' THEN
				DELETE FROM config_form_tabs where formname=OLD.child_layer and tabname in ('tab_hydrometer', 'tab_hydrometer_val');
			END IF;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		DELETE FROM config_form_tabs WHERE formname = concat('ve_', lower(old.feature_type), '_', lower(old.id));

		IF v_table = 'DELETE' THEN
			RETURN OLD;
		ELSE
			-- delete child views
			IF OLD.child_layer IS NOT NULL THEN
				EXECUTE 'DROP VIEW IF EXISTS '||OLD.child_layer||';';
			END IF;

			--delete configuration from config_form_fields
			DELETE FROM config_form_fields where formname=OLD.child_layer AND formtype = 'form_feature';

			--delete definition from config_info_layer_x_type
			DELETE FROM config_info_layer_x_type where tableinfo_id=OLD.child_layer OR tableinfotype_id=OLD.child_layer;

			--delete definition from sys_table
			DELETE FROM sys_table where id=OLD.child_layer;

			-- delete sys_param_user parameters
			DELETE FROM sys_param_user WHERE id = concat('feat_',lower(OLD.id),'_vdefault');

			IF  v_projecttype = 'WS' and OLD.feature_class = 'NETWJOIN' THEN
				DELETE FROM config_form_tabs where formname=OLD.child_layer and tabname in ('tab_hydrometer', 'tab_hydrometer_val');
			END IF;
		    RETURN NULL;
		END IF;
	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
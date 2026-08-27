/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2816

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_config_control()
  RETURNS trigger AS
$BODY$

DECLARE
v_querytext text;
v_configtable text;
v_count integer;
v_widgettype text;
v_message json;
v_variables text;
rec_feature text;
v_project_type text;
v_sql TEXT;
rec record;

BEGIN

	-- search path
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	SELECT UPPER(project_type), giswater INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	v_configtable:= TG_ARGV[0];

	IF (SELECT value::boolean FROM config_param_system WHERE parameter='admin_config_control_trigger') IS TRUE THEN

		IF v_configtable = 'sys_param_user' THEN

		ELSIF v_configtable IN ('cat_material', 'man_type_category', 'man_type_fluid', 'man_type_function', 'man_type_location') THEN
			v_querytext='SELECT * FROM '||v_configtable||';';
			--check if all feature_type are present on table sys_feature_type
			IF NEW.feature_type IS NOT NULL THEN
				FOREACH rec_feature IN array(NEW.feature_type) LOOP
					IF rec_feature NOT IN (SELECT id FROM sys_feature_type) THEN
						v_variables = concat('table: ',v_configtable,', feature_type: ',rec_feature);
						v_message = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3172",
						"function":"2816", "debug":null, "variables":"',v_variables,'"}}');
						PERFORM gw_fct_getmessage(v_message);
					END IF;
				END LOOP;
			
				IF v_configtable = 'cat_material' THEN
					IF v_project_type = 'UD' THEN
					
						v_sql := format($sql$
						WITH mec AS (
						    SELECT lower(id) AS feature_type
						    FROM sys_feature_type
						    WHERE id NOT IN ('ELEMENT', 'LINK')
						      AND id NOT IN (
						      	SELECT unnest(feature_type) FROM cat_material WHERE id =%L
						    )
						)
						SELECT format(
				           'SELECT %%L as feature_type FROM %%I WHERE matcat_id = %%L',
				           feature_type,
				           feature_type,
				           %L
				      	) AS feature_query, feature_type
						FROM mec
						$sql$, NEW.id, NEW.id);
				
					ELSIF v_project_type = 'WS' THEN 
										
						v_sql := format($sql$
						WITH mec AS (
							    SELECT lower(id) AS feature_type
							    FROM sys_feature_type
							    WHERE id NOT IN ('ELEMENT', 'LINK')
							      AND id NOT IN (
							      	SELECT unnest(feature_type) FROM cat_material WHERE id =%L
							    )
							)
						SELECT format(
				           'SELECT %%L as feature_type FROM %%I
				            JOIN %%I ON %%I.%%I = %%I.id
				            WHERE %%I.matcat_id = %%L',
							feature_type,
				           feature_type,
				           'cat_' || feature_type,
				           feature_type,
				           feature_type || 'cat_id',
				           'cat_' || feature_type,
				           'cat_' || feature_type,
				           %L
				       	) AS feature_query, feature_type
						FROM mec
						$sql$, NEW.id, NEW.id);
					
					/* EXAMPLE:
						with mec as (
							SELECT lower(id) as feature_type from sys_Feature_type where id <> 'ELEMENT' AND id NOT IN (
							SELECT unnest(feature_type) FROM cat_material WHERE id = 'PVC'
							)
						)
						SELECT 
						' SELECT COUNT(*) FROM '||feature_type||'
						JOIN cat_'|| feature_type ||' ON '|| feature_type ||'.'|| feature_type ||'cat_id = cat_'|| feature_type ||'.id
						WHERE cat_'|| feature_type ||'.matcat_id = ''PVC'''
						as num FROM mec;
					*/
					
					END IF;
				
					
					FOR rec IN EXECUTE v_sql
					
					LOOP
										
						EXECUTE 'SELECT COUNT(*) FROM ('||rec.feature_query||')' INTO v_count;
						IF v_count > 0 THEN
							RAISE EXCEPTION 'Tienes % con este material. Ajusta antes de modificar los features del material', rec.feature_type;
						END IF;
					END LOOP;
				END IF;
			ELSE -- NEW.feature_type IS NULL
			
			END IF;

			IF NEW.featurecat_id IS NOT NULL THEN
				FOREACH rec_feature IN array(NEW.featurecat_id) LOOP
					IF rec_feature NOT IN (
					SELECT id FROM cat_feature
					WHERE feature_type = ANY (NEW.feature_type)
					UNION
					SELECT id FROM cat_feature_element
					) THEN
						v_variables = concat('table: ',v_configtable,', featurecat: ',rec_feature);
						v_message = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3172",
						"function":"2816", "debug":null, "variables":"',v_variables,'"}}');
						PERFORM gw_fct_getmessage(v_message);
					END IF;
				END LOOP;
			END IF;

			-- Insert into cat_mat_roughness if feature_type is ARC and operation is INSERT. Before rule called: insert_inp_cat_mat_roughness
			IF v_configtable = 'cat_material' THEN
				IF TG_OP = 'INSERT' AND v_project_type = 'WS' THEN
					IF 'ARC' = ANY(NEW.feature_type) THEN
						INSERT INTO cat_mat_roughness (matcat_id)
						VALUES (NEW.id) ON CONFLICT DO NOTHING;
					END IF;
				END IF;
			END IF;

		ELSIF v_configtable IN ('cat_brand', 'cat_brand_model') THEN
			v_querytext='SELECT * FROM '||v_configtable||';';

			--check if all featurecat are present on table cat_feature
			IF NEW.featurecat_id IS NOT NULL THEN
				FOREACH rec_feature IN array(NEW.featurecat_id) LOOP
					IF rec_feature NOT IN (SELECT id FROM cat_feature UNION SELECT id FROM cat_feature_element) THEN
						v_variables = concat('table: ',v_configtable,', featurecat: ',rec_feature);
						v_message = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3172",
						"function":"2816", "parameters":null, "variables":"',v_variables,'"}}');
						PERFORM gw_fct_getmessage(v_message);
					END IF;
				END LOOP;
			END IF;

		ELSIF v_configtable = 'config_form_fields' THEN

			IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN

				v_variables = concat('formname: ',NEW.formname,', columnname: ',NEW.columnname,', dv_querytext_filterc: ',NEW.dv_querytext_filterc);

				-- check dv_querytext restrictions
				IF (NEW.widgettype = 'combo' OR NEW.widgettype = 'typeahead') THEN

					--check dv_querytext is correct
					IF NEW.dv_querytext IS NOT NULL THEN
						v_querytext = NEW.dv_querytext;
						EXECUTE v_querytext;
					END IF;

					--check that when dv_querytextfilterc exists dv_parent_id also
					IF NEW.dv_querytext_filterc IS NOT null THEN

						--check if dv_parent_id is not null (only for combo because for typeahead null value means feature_id)
						IF NEW.dv_parent_id IS null AND NEW.widgettype != 'typeahead' THEN
							v_message = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3102", "function":"2816",
							"parameters":null, "variables":"',v_variables,'"}}');
							PERFORM gw_fct_getmessage(v_message);

						elsif NEW.dv_parent_id IS null AND NEW.widgettype = 'typeahead' THEN
							NEW.dv_parent_id= '';
						end if;

						--check if dv_parent_id is correct (another existing columnname)
						EXECUTE 'SELECT columnname FROM config_form_fields WHERE columnname = '||quote_literal(NEW.dv_parent_id)||' AND formname = '||
						quote_literal(NEW.formname)||'' INTO v_widgettype;

						IF v_widgettype IS NULL and NEW.widgettype != 'typeahead'THEN
							v_message = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3104",
							"function":"2816", "parameters":null, "variables":"',v_variables,'"}}');
							PERFORM gw_fct_getmessage(v_message);
						END IF;
					END IF;
				END IF;

				--check for typeahead some additional restrictions
				IF NEW.widgettype = 'typeahead' THEN

					-- isautoupdate is FALSE
					IF NEW.isautoupdate = TRUE THEN
						PERFORM gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3096", "function":"2816","parameters":null}}$$);
					END IF;

					-- --query text HAS SAME id THAN idval (with the exception of streetname and streename2)
					-- IF NEW.dv_querytext IS NOT NULL THEN

					-- 	IF NEW.columnname = 'streetname' OR NEW.columnname = 'streetname2' THEN
					-- 		-- do nothing (with the exception of streetname and streename2
					-- 	ELSE
					-- 		EXECUTE 'SELECT count(*) FROM( ' ||NEW.dv_querytext|| ')a WHERE id::text != idval::text' INTO v_count;

					-- 		IF v_count > 0 THEN
					-- 			v_message = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3100",
					-- 			"function":"2816", "parameters":null, "variables":"',v_variables,'"}}');
					-- 			PERFORM gw_fct_getmessage(v_message);
					-- 		END IF;
					-- 	END IF;
					-- END IF;
				END IF;

			ELSIF TG_OP = 'UPDATE' THEN

				IF NEW.dv_parent_id IS NULL THEN

					-- check if related isparent is TRUE when setting dv_parent_id to NULL
					IF (SELECT isparent FROM config_form_fields WHERE formname=NEW.formname AND columnname=OLD.dv_parent_id
					and NEW.widgettype != 'typeahead') is true THEN

						--only if there're no more fields related to the parent
						SELECT count(*) FROM config_form_fields WHERE formname=NEW.formname AND dv_parent_id=OLD.dv_parent_id INTO v_count;

						IF v_count = 1 THEN
								v_message = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3170",
								"function":"2816", "parameters":null, "variables":"',v_variables,'"}}');
								PERFORM gw_fct_getmessage(v_message);
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;

	-- return
	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		RETURN NEW;
	ELSIF TG_OP = 'DELETE' THEN
		RETURN OLD;
	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


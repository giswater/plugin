/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1304


CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_connec()
  RETURNS trigger AS
$BODY$

DECLARE

v_sql varchar;
v_man_table varchar;
v_code_autofill_bool boolean;
v_type_man_table varchar;
v_proximity_buffer double precision;
v_link_path varchar;
v_record_link record;
v_record_vnode record;
v_count integer;
v_insert_double_geom boolean;
v_double_geom_buffer double precision;
v_new_connec_type text;
v_old_connec_type text;
v_customfeature text;
v_addfields record;
v_new_value_param text;
v_old_value_param text;
v_featurecat text;
v_psector_vdefault integer;
v_arc_id text;
v_auto_pol_id text;
v_force_delete boolean;
v_autoupdate_fluid boolean;
v_message text;
v_dsbl_error boolean;
v_connect2network boolean;
v_feature_class text;
v_featurecat_id text;
v_arc record;
v_link integer;
v_link_geom public.geometry;
v_auto_streetvalues_status boolean;
v_auto_streetvalues_buffer integer;
v_auto_streetvalues_field text;
v_ispresszone boolean = false;
v_trace_featuregeom boolean;
v_connec_id text;
v_childtable_name text;
v_schemaname text;
v_sys_code_autofill text;

v_district_ids _int4;

BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
    v_man_table:= TG_ARGV[0];
    v_schemaname:= TG_TABLE_SCHEMA;

	IF v_man_table IN (SELECT id FROM cat_feature WHERE feature_type = 'CONNEC') THEN
		v_customfeature:=v_man_table;
		v_man_table:=(SELECT man_table FROM cat_feature_connec c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id=v_man_table);
	END IF;

	v_type_man_table:=v_man_table;

	-- get system and user variables
	v_proximity_buffer = (SELECT "value" FROM config_param_system WHERE parameter='edit_feature_buffer_on_mapzone');
	SELECT ((value::json)->>'activated') INTO v_insert_double_geom FROM config_param_system WHERE parameter='insert_double_geometry';
	SELECT ((value::json)->>'value') INTO v_double_geom_buffer FROM config_param_system WHERE parameter='insert_double_geometry';
	SELECT value::boolean INTO v_autoupdate_fluid FROM config_param_system WHERE parameter='edit_connect_autoupdate_fluid';
	SELECT value::boolean INTO v_dsbl_error FROM config_param_system WHERE parameter='edit_topocontrol_disable_error' ;
	v_auto_streetvalues_status := (SELECT (value::json->>'status')::boolean FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_buffer := (SELECT (value::json->>'buffer')::integer FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_field := (SELECT (value::json->>'field')::text FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_ispresszone:= (SELECT value::json->>'PRESSZONE' FROM config_param_system WHERE parameter = 'utils_graphanalytics_status');
	v_sys_code_autofill := (SELECT (value::json->>'connec')::text FROM config_param_system WHERE parameter = 'edit_sys_code_autofill');

	SELECT value::boolean INTO v_connect2network FROM config_param_user WHERE parameter='edit_connec_automatic_link' AND cur_user=current_user;

	IF v_proximity_buffer IS NULL THEN v_proximity_buffer=0.5; END IF;
	IF v_insert_double_geom IS NULL THEN v_insert_double_geom=FALSE; END IF;
	IF v_double_geom_buffer IS NULL THEN v_double_geom_buffer=1; END IF;

	v_psector_vdefault = (SELECT config_param_user.value::integer AS value FROM config_param_user WHERE config_param_user.parameter::text
			    = 'plan_psector_current'::text AND config_param_user.cur_user::name = "current_user"() LIMIT 1);

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		IF NEW.conneccat_id NOT IN (SELECT id FROM cat_connec WHERE connec_type = NEW.connec_type) AND NEW.connec_type IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	       		"data":{"message":"4464", "function":"1304","parameters":null, "is_process":true}}$$);';
		END IF;
		-- check arc exploitation
		IF NEW.arc_id IS NOT NULL AND NEW.expl_id IS NOT NULL THEN
			IF (SELECT expl_id FROM arc WHERE arc_id = NEW.arc_id) != NEW.expl_id THEN

				IF v_dsbl_error IS NOT TRUE THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3144", "function":"1304","parameters":{"arc_id":"'||NEW.arc_id::text||'"}}}$$);';
				ELSE
					SELECT concat('ERROR-',id,':',error_message,'.',hint_message) INTO v_message FROM sys_message WHERE id = 3144;
					INSERT INTO audit_log_data (fid, feature_id, log_message) VALUES (394, NEW.connec_id, v_message);
				END IF;
			END IF;
		END IF;

		-- setting pjoint_id, pjoint_type and arc_id and removing link in case of connec is over arc
		v_arc_id = (SELECT arc_id FROM ve_arc WHERE st_dwithin(the_geom, NEW.the_geom, 0.01) AND state > 0 LIMIT 1);
		IF v_arc_id IS NOT NULL THEN
			NEW.arc_id = v_arc_id;
			NEW.pjoint_id = NEW.arc_id;
			NEW.pjoint_type = 'ARC';
			DELETE FROM link WHERE feature_id = NEW.connec_id;
		END IF;
	END IF;

	-- Control insertions ID
	IF TG_OP = 'INSERT' THEN

		-- setting psector vdefault as visible
		IF NEW.state = 2 THEN
			INSERT INTO selector_psector (psector_id, cur_user) VALUES (v_psector_vdefault, current_user) ON CONFLICT DO NOTHING;
		END IF;

		-- connec ID
		IF NEW.connec_id != (SELECT last_value FROM urn_id_seq) OR NEW.connec_id IS NULL THEN
			NEW.connec_id = (SELECT nextval('urn_id_seq'));
		END IF;

		-- connec Catalog ID
		IF (NEW.conneccat_id IS NULL) THEN
			IF ((SELECT COUNT(*) FROM cat_connec WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			  "data":{"message":"1022", "function":"1304","parameters":null, "variables":null}}$$);';
			END IF;

			IF v_customfeature IS NOT NULL THEN
				NEW.conneccat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"=lower(concat(v_customfeature,'_vdefault')) AND "cur_user"="current_user"() LIMIT 1);
			ELSE
				NEW.conneccat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_connecat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			IF (NEW.conneccat_id IS NULL) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				 "data":{"message":"1086", "function":"1304","parameters":null, "variables":null}}$$);';
			END IF;
		ELSE
			IF (SELECT true from cat_connec where id=NEW.conneccat_id) IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3282", "function":"1304","parameters":{"catalog_value":"'||NEW.conneccat_id||'"}}}$$);';
			END IF;
		END IF;

		-- Exploitation
		IF (NEW.expl_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1110", "function":"1304","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.expl_id IS NULL) THEN
				NEW.expl_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_exploitation_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.expl_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM exploitation WHERE ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) AND active IS TRUE;
				IF v_count = 1 THEN
					NEW.expl_id = (SELECT expl_id FROM exploitation WHERE ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) AND active IS TRUE LIMIT 1);
				ELSE
					NEW.expl_id =(SELECT expl_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- control error when no value
			IF (NEW.expl_id IS NULL) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"2012", "function":"1304","parameters":{"feature_id":"'||NEW.connec_id::text||'"}}}$$);';
			END IF;
		END IF;

		-- Sector ID
		IF (NEW.sector_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM sector WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1008", "function":"1304","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.sector_id IS NULL) THEN
				NEW.sector_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_sector_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.sector_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM sector WHERE ST_DWithin(NEW.the_geom, sector.the_geom,0.001) AND active IS TRUE ;
				IF v_count = 1 THEN
					NEW.sector_id = (SELECT sector_id FROM sector WHERE ST_DWithin(NEW.the_geom, sector.the_geom,0.001) AND active IS TRUE  LIMIT 1);
				ELSE
					NEW.sector_id =(SELECT sector_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- control when no value
			IF NEW.sector_id IS NULL THEN
				NEW.sector_id = 0;
			END IF;
		END IF;

		-- Dma ID
		IF (NEW.dma_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM dma WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1012", "function":"1304","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.dma_id IS NULL) THEN
				NEW.dma_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_dma_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.dma_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM dma WHERE ST_DWithin(NEW.the_geom, dma.the_geom,0.001) AND active IS TRUE ;
				IF v_count = 1 THEN
					NEW.dma_id = (SELECT dma_id FROM dma WHERE ST_DWithin(NEW.the_geom, dma.the_geom,0.001) AND active IS TRUE LIMIT 1);
				ELSE
					NEW.dma_id =(SELECT dma_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- control when no value
			IF NEW.dma_id IS NULL THEN
				NEW.dma_id = 0;
			END IF;
		END IF;

		-- Presszone
		IF (NEW.presszone_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM presszone WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3106", "function":"1304","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.presszone_id IS NULL) THEN
				NEW.presszone_id := (SELECT "value" FROM config_param_user WHERE "parameter"='presszone_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.presszone_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM presszone WHERE ST_DWithin(NEW.the_geom, presszone.the_geom,0.001) AND active IS TRUE ;
				IF v_count = 1 THEN
					NEW.presszone_id = (SELECT presszone_id FROM presszone WHERE ST_DWithin(NEW.the_geom, presszone.the_geom,0.001) AND active IS TRUE LIMIT 1);
				ELSE
					NEW.presszone_id =(SELECT presszone_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- control when no value
			IF NEW.presszone_id IS NULL THEN
				NEW.presszone_id = 0;
			END IF;
		END IF;

		-- District
		IF (NEW.district_id IS NULL) THEN
			-- getting value from geometry of mapzone
			v_district_ids = (SELECT array_agg(district_id) FROM v_district WHERE ST_DWithin(NEW.the_geom, v_district.the_geom,0.001));
			IF cardinality(v_district_ids) = 1 THEN
				NEW.district_id := v_district_ids[1];
			ELSIF cardinality(v_district_ids) > 1 THEN
				NEW.district_id := (SELECT district_id FROM ve_arc WHERE district_id = ANY(v_district_ids) ORDER BY ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
			END IF;
		END IF;

		-- Municipality
		IF (NEW.muni_id IS NULL) THEN

			IF NEW.district_id IS NOT NULL THEN
				NEW.muni_id := (SELECT muni_id FROM v_municipality WHERE district_id = NEW.district_id AND active IS TRUE LIMIT 1);
			END IF;

			-- getting value default
			IF (NEW.muni_id IS NULL) THEN
				NEW.muni_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_municipality_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.muni_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM v_municipality WHERE ST_DWithin(NEW.the_geom, v_municipality.the_geom,0.001) AND active IS TRUE ;
				IF v_count = 1 THEN
					NEW.muni_id = (SELECT muni_id FROM v_municipality WHERE ST_DWithin(NEW.the_geom, v_municipality.the_geom,0.001)
					AND active IS TRUE LIMIT 1);
				ELSE
					NEW.muni_id =(SELECT muni_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;
		END IF;

		-- State
		IF (NEW.state IS NULL) THEN
			NEW.state := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_state_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		-- State_type
		IF (NEW.state=0) THEN
			IF (NEW.state_type IS NULL) THEN
				NEW.state_type := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_statetype_0_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;
		ELSIF (NEW.state=1) THEN
			IF (NEW.state_type IS NULL) THEN
				NEW.state_type := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_statetype_1_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;
		ELSIF (NEW.state=2) THEN
			IF (NEW.state_type IS NULL) THEN
				NEW.state_type := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_statetype_2_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;
		END IF;

		--check relation state - state_type
		IF NEW.state_type NOT IN (SELECT id FROM value_state_type WHERE state = NEW.state) THEN
			IF NEW.state IS NOT NULL THEN
				v_sql = NEW.state;
			ELSE
				v_sql = 'null';
			END IF;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3036", "function":"1318","parameters":{"state_id":"'||v_sql::text||'"}}}$$);';
		END IF;

		--Publish
		IF NEW.publish IS NULL THEN
			NEW.publish := (SELECT "value" FROM config_param_system WHERE "parameter"='edit_publish_sysvdefault');
		END IF;

		-- Workcat_id
		IF (NEW.workcat_id IS NULL) THEN
			NEW.workcat_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_workcat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		--Workcat_id_plan
		IF (NEW.workcat_id_plan IS NULL AND NEW.state = 2) THEN
			NEW.workcat_id_plan := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_workcat_id_plan' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		-- Soilcat_id
		IF (NEW.soilcat_id IS NULL) THEN
			NEW.soilcat_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_soilcat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		--Builtdate
		IF (NEW.builtdate IS NULL) THEN
			NEW.builtdate :=(SELECT "value" FROM config_param_user WHERE "parameter"='edit_builtdate_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			IF (NEW.builtdate IS NULL) AND (SELECT value::boolean FROM config_param_system WHERE parameter='edit_feature_auto_builtdate') IS TRUE THEN
				NEW.builtdate :=date(now());
			END IF;
		END IF;

		--Address
		IF (NEW.streetaxis_id IS NULL) THEN
			IF (v_auto_streetvalues_status is true) THEN
				NEW.streetaxis_id := (select v_v_streetaxis.id from v_v_streetaxis
								join node on ST_DWithin(NEW.the_geom, v_v_streetaxis.the_geom, v_auto_streetvalues_buffer)
								order by ST_Distance(NEW.the_geom, v_v_streetaxis.the_geom) LIMIT 1);
			END IF;
		END IF;

		--Postnumber/postcomplement
		IF (v_auto_streetvalues_status) IS TRUE THEN
			IF (v_auto_streetvalues_field = 'postcomplement') THEN
				IF (NEW.postcomplement IS NULL) THEN
					NEW.postcomplement = (select v_address.postnumber from v_address
						join node on ST_DWithin(NEW.the_geom, v_address.the_geom, v_auto_streetvalues_buffer)
						order by ST_Distance(NEW.the_geom, v_address.the_geom) LIMIT 1);
				END IF;
			ELSIF (v_auto_streetvalues_field = 'postnumber') THEN
				IF (NEW.postnumber IS NULL) THEN
					NEW.postnumber= (select v_address.postnumber from v_address
						join node on ST_DWithin(NEW.the_geom, v_address.the_geom, v_auto_streetvalues_buffer)
						order by ST_Distance(NEW.the_geom, v_address.the_geom) LIMIT 1);
				END IF;
			END IF;
		END IF;

		-- Verified
		IF (NEW.verified IS NULL) THEN
			NEW.verified := (SELECT "value"::INTEGER FROM config_param_user WHERE "parameter"='edit_verified_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		-- Code
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		SELECT code_autofill, cat_feature.id
		INTO v_code_autofill_bool, v_featurecat
		FROM cat_feature
		JOIN cat_connec ON cat_feature.id = cat_connec.connec_type
		WHERE cat_connec.id = NEW.conneccat_id;

		IF NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('feature', v_featurecat, json_strip_nulls(row_to_json(NEW)::json));

			IF NEW.code IS NULL AND v_code_autofill_bool THEN
				NEW.code := NEW.connec_id;
			END IF;
		END IF;

		IF NEW.sys_code IS NOT NULL AND v_sys_code_autofill NOT IN ('false', 'none') THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4678", "function":"1304"}}$$);';
		END IF;

		--Sys_code (uuid | code | none)
		IF v_sys_code_autofill IN ('uuid', 'true') THEN
			NEW.sys_code := gen_random_uuid();
		ELSIF v_sys_code_autofill = 'code' THEN
			NEW.sys_code := NEW.code;
		END IF;

		-- LINK
		--google maps style
		IF (SELECT (value::json->>'google_maps')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=CONCAT ('https://www.google.com/maps/place/',(ST_Y(ST_transform(NEW.the_geom,4326))),'N+',(ST_X(ST_transform(NEW.the_geom,4326))),'E');
		--fid style
		ELSIF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=NEW.connec_id;
		END IF;

		-- Customer code
		IF NEW.customer_code IS NULL AND (SELECT (value::json->>'status')::boolean FROM config_param_system WHERE parameter = 'edit_connec_autofill_ccode') IS TRUE
		AND (SELECT (value::json->>'field')::text FROM config_param_system WHERE parameter = 'edit_connec_autofill_ccode')='code'  THEN

			NEW.customer_code = NEW.code;

		ELSIF NEW.customer_code IS NULL AND (SELECT (value::json->>'status')::boolean FROM config_param_system WHERE parameter = 'edit_connec_autofill_ccode') IS TRUE
		AND (SELECT (value::json->>'field')::text FROM config_param_system WHERE parameter = 'edit_connec_autofill_ccode')='connec_id'  THEN

			NEW.customer_code = NEW.connec_id;

		END IF;

		v_featurecat = (SELECT connec_type FROM cat_connec WHERE id = NEW.conneccat_id);

		--Location type
		IF NEW.location_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_location_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_location_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.location_type IS NULL THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'connec_location_vdefault' AND cur_user = current_user);
		END IF;

		--Fluid type
		IF v_autoupdate_fluid IS TRUE AND NEW.arc_id IS NOT NULL THEN
			NEW.fluid_type = (SELECT fluid_type FROM arc WHERE arc_id = NEW.arc_id);
		END IF;

		IF NEW.fluid_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_fluid_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_fluid_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.fluid_type IS NULL THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'connec_fluid_vdefault' AND cur_user = current_user);
		END IF;

		--Category type
		IF NEW.category_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_category_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_category_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.category_type IS NULL THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'connec_category_vdefault' AND cur_user = current_user);
		END IF;

		--Function type
		IF NEW.function_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_function_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_function_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.function_type IS NULL THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'connec_function_vdefault' AND cur_user = current_user);
		END IF;

		-- crmzone_id
		IF (NEW.crmzone_id IS NULL) THEN
			-- getting value from geometry of mapzone
			IF (NEW.crmzone_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM crmzone WHERE ST_DWithin(NEW.the_geom, crmzone.the_geom,0.001);
				NEW.crmzone_id = (SELECT crmzone_id FROM crmzone WHERE ST_DWithin(NEW.the_geom, crmzone.the_geom,0.001) LIMIT 1);
			END IF;
		END IF;

		--top_elev from raster
		IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
		 AND (NEW.top_elev IS NULL) AND
		(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_insert_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
			NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
				(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1) LIMIT 1);
		END IF;

		-- plot_id from plot layer
		IF (SELECT value::boolean FROM config_param_system WHERE parameter = 'edit_connec_autofill_plotcode') = TRUE THEN
			NEW.plot_id = (SELECT id FROM v_plot WHERE st_dwithin(the_geom, NEW.the_geom, 0) LIMIT 1);
		END IF;

		IF NEW.epa_type IS NULL THEN
			NEW.epa_type ='JUNCTION';
		END IF;
		
		-- uuid random
		IF NEW.uuid is null then
			NEW.uuid = gen_random_uuid();
		END IF;

		-- FEATURE INSERT
		INSERT INTO connec (connec_id, code, sys_code, datasource, top_elev, depth,conneccat_id,  sector_id, customer_code,  state, state_type, annotation, observ, comment,dma_id, presszone_id, soilcat_id,
		function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, streetaxis_id, postnumber, postnumber2,
		muni_id, streetaxis2_id,  postcode, district_id, postcomplement, postcomplement2, descript, link, verified, rotation,  the_geom, label_x,label_y,label_rotation, expl_id,
		publish, inventory,num_value, connec_length, arc_id, minsector_id, dqa_id, pjoint_id, pjoint_type,
		adate, adescript, accessibility, updated_at, updated_by, asset_id, epa_type, om_state, conserv_state, priority,
		access_type, placement_type, crmzone_id, expl_visibility, plot_id, brand_id, model_id, serial_number, label_quadrant, n_inhabitants, lock_level, block_code, n_hydrometer, uuid, dataquality, dataquality_obs)
		VALUES (NEW.connec_id, NEW.code, NEW.sys_code, NEW.datasource, NEW.top_elev, NEW.depth, NEW.conneccat_id, NEW.sector_id, NEW.customer_code,  NEW.state, NEW.state_type, NEW.annotation,   NEW.observ, NEW.comment,
		NEW.dma_id, NEW.presszone_id, NEW.soilcat_id, NEW.function_type, NEW.category_type, NEW.fluid_type,  NEW.location_type, NEW.workcat_id, NEW.workcat_id_end,  NEW.workcat_id_plan,
		NEW.builtdate, NEW.enddate, NEW.ownercat_id, NEW.streetaxis_id, NEW.postnumber, NEW.postnumber2, NEW.muni_id, NEW.streetaxis2_id, NEW.postcode, NEW.district_id, NEW.postcomplement,
		NEW.postcomplement2, NEW.descript, NEW.link, NEW.verified, NEW.rotation, NEW.the_geom,NEW.label_x, NEW.label_y,NEW.label_rotation,  NEW.expl_id, NEW.publish, NEW.inventory,
		NEW.num_value, NEW.connec_length, NEW.arc_id, COALESCE(NEW.minsector_id, 0), COALESCE(NEW.dqa_id, 0), NEW.pjoint_id, NEW.pjoint_type,
		NEW.adate, NEW.adescript, NEW.accessibility, NEW.updated_at, NEW.updated_by, NEW.asset_id, NEW.epa_type, NEW.om_state, NEW.conserv_state, NEW.priority,
		NEW.access_type, NEW.placement_type, COALESCE(NEW.crmzone_id, 0), NEW.expl_visibility, NEW.plot_id, NEW.brand_id, NEW.model_id, NEW.serial_number,
		NEW.label_quadrant, NEW.n_inhabitants, NEW.lock_level, NEW.block_code, NEW.n_hydrometer, NEW.uuid, NEW.dataquality, NEW.dataquality_obs);

		-- insert into connec_add table
		INSERT INTO connec_add (connec_id, demand_base, demand_max,demand_min, demand_avg, press_max, press_min, press_avg, quality_max, quality_min, quality_avg,
		flow_max, flow_min, flow_avg, vel_max, vel_min, vel_avg, result_id)
		VALUES ( NEW.connec_id, NEW.demand_base, NEW.demand_max, NEW.demand_min, NEW.demand_avg, NEW.press_max, NEW.press_min, NEW.press_avg, NEW.quality_max,
		NEW.quality_min, NEW.quality_avg, NEW.flow_max, NEW.flow_min, NEW.flow_avg, NEW.vel_max, NEW.vel_min, NEW.vel_avg, NEW.result_id);

		SELECT feature_class, cat_feature.id INTO v_feature_class, v_featurecat_id FROM cat_feature
		JOIN cat_connec ON cat_feature.id=connec_type where cat_connec.id=NEW.conneccat_id;

		EXECUTE 'SELECT json_extract_path_text(double_geom,''activated'')::boolean, json_extract_path_text(double_geom,''value'')  
		FROM cat_feature_connec WHERE id='||quote_literal(v_featurecat_id)||''
		INTO v_insert_double_geom, v_double_geom_buffer;

		IF (v_insert_double_geom IS TRUE) THEN
			INSERT INTO polygon(sys_type, the_geom, featurecat_id, feature_id, state)
			VALUES (v_feature_class, (SELECT ST_Multi(ST_Envelope(ST_Buffer(connec.the_geom,v_double_geom_buffer)))
			from connec where connec_id=NEW.connec_id), v_featurecat_id, NEW.connec_id, NEW.state);
		END IF;


		IF v_man_table='man_greentap' THEN
			INSERT INTO man_greentap (connec_id, linked_connec, greentap_type)
			VALUES(NEW.connec_id, NEW.linked_connec, NEW.greentap_type);

		ELSIF v_man_table='man_fountain' THEN

			INSERT INTO man_fountain(connec_id, linked_connec, vmax, vtotal, container_number, pump_number, power, regulation_tank,name,
			chlorinator, arq_patrimony)
			VALUES (NEW.connec_id, NEW.linked_connec, NEW.vmax, NEW.vtotal,NEW.container_number, NEW.pump_number, NEW.power, NEW.regulation_tank, NEW.name,
			NEW.chlorinator, NEW.arq_patrimony);

		ELSIF v_man_table='man_tap' THEN
			INSERT INTO man_tap(connec_id, linked_connec, drain_diam, drain_exit, drain_gully, drain_distance, arq_patrimony, com_state)
			VALUES (NEW.connec_id, NEW.linked_connec, NEW.drain_diam, NEW.drain_exit, NEW.drain_gully, NEW.drain_distance, NEW.arq_patrimony, NEW.com_state);

		ELSIF v_man_table='man_wjoin' THEN
		 	INSERT INTO man_wjoin (connec_id, top_floor,wjoin_type)
			VALUES (NEW.connec_id, NEW.top_floor, NEW.wjoin_type);
		
		ELSIF v_man_table='man_samplepoint' THEN
			INSERT INTO man_samplepoint (connec_id, lab_code, place_name, cabinet)
			VALUES (NEW.connec_id, NEW.lab_code, NEW.place_name, NEW.cabinet);

		END IF;

		IF v_man_table='parent' THEN
			v_man_table:= (SELECT man_table FROM cat_feature_connec c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id JOIN cat_connec ON cat_connec.id=NEW.conneccat_id
		    	WHERE c.id = cat_connec.connec_type LIMIT 1)::text;

			IF v_man_table IS NOT NULL THEN
			    v_sql:= 'INSERT INTO '||v_man_table||' (connec_id) VALUES ('||quote_literal(NEW.connec_id)||')';
			    EXECUTE v_sql;
			END IF;
	 	END IF;

	 	-- insertint on psector table
		IF NEW.state=2 THEN
		
			INSERT INTO plan_psector_x_connec (connec_id, psector_id, state, doable, arc_id)
			VALUES (NEW.connec_id, v_psector_vdefault, 1, true, NEW.arc_id)
			ON CONFLICT (connec_id, psector_id, state) DO NOTHING;
			
		END IF;

		-- manage connect2network
		IF v_connect2network THEN

			IF NEW.arc_id IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":'|| array_to_json(array_agg(NEW.connec_id))||'},"data":{"feature_type":"CONNEC", "forcedArcs":["'||NEW.arc_id||'"]}}$$)';
			ELSE
				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":'|| array_to_json(array_agg(NEW.connec_id))||'},"data":{"feature_type":"CONNEC"}}$$)';
			END IF;

			-- recover values in order to do not disturb this workflow
			SELECT * INTO v_arc FROM arc WHERE arc_id = NEW.arc_id;
			NEW.pjoint_id = v_arc.arc_id; NEW.pjoint_type = 'ARC'; NEW.sector_id = v_arc.sector_id; NEW.dma_id = v_arc.dma_id;
			NEW.presszone_id = v_arc.presszone_id; NEW.dqa_id = v_arc.dqa_id;  NEW.minsector_id = v_arc.minsector_id;
		END IF;

		-- childtable insert
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='CONNEC' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' ||v_addfields.param_name||'"'
					USING NEW
					INTO v_new_value_param;

				v_childtable_name := 'man_connec_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF v_new_value_param IS NOT NULL THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (connec_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (connec_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.connec_id=$1'
							USING NEW.connec_id, v_new_value_param;
					END IF;
				END IF;
			END LOOP;
		END IF;

		-- epa insert
		IF (NEW.epa_type = 'JUNCTION') THEN
			INSERT INTO inp_connec (connec_id) VALUES (NEW.connec_id);
		END IF;

		-- static pressure
		IF v_ispresszone AND NEW.presszone_id IS NOT NULL THEN
			UPDATE connec SET staticpressure = (SELECT head from presszone WHERE presszone_id = NEW.presszone_id)-top_elev WHERE connec_id = NEW.connec_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		SELECT code_autofill, cat_feature.id INTO v_code_autofill_bool, v_featurecat FROM cat_feature
		join cat_connec on cat_feature.id=cat_connec.connec_type where cat_connec.id=NEW.conneccat_id;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('feature', v_featurecat, json_strip_nulls(row_to_json(NEW)::json));
		END IF;

				-- static pressure
		IF v_ispresszone AND (NEW.presszone_id != OLD.presszone_id) THEN
			UPDATE connec SET staticpressure = (SELECT head from presszone WHERE presszone_id = NEW.presszone_id)-top_elev
			WHERE connec_id = NEW.connec_id;
		END IF;

		-- EPA update
		IF (NEW.epa_type != OLD.epa_type) THEN
			IF NEW.epa_type = 'UNDEFINED' THEN
				DELETE FROM inp_connec WHERE connec_id = NEW.connec_id;
			ELSIF NEW.epa_type = 'JUNCTION' THEN
				INSERT INTO inp_connec (connec_id) VALUES (NEW.connec_id)
				ON CONFLICT (connec_id) DO NOTHING;
			END IF;
		END IF;

		-- UPDATE geom
		UPDATE connec SET connec_length = NEW.connec_length WHERE connec_id = OLD.connec_id;
		IF st_equals(NEW.the_geom, OLD.the_geom) IS FALSE AND geometrytype(NEW.the_geom)='POINT'  THEN
			UPDATE connec SET the_geom=NEW.the_geom WHERE connec_id = OLD.connec_id;

			--update top_elev from raster
			IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
			AND (NEW.top_elev = OLD.top_elev) AND
			(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_update_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
				NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
							(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1) LIMIT 1);
			END IF;

			--update associated geometry of element (if exists) and trace_featuregeom is true
			v_trace_featuregeom:= (SELECT trace_featuregeom FROM element JOIN element_x_connec using (element_id) WHERE connec_id=NEW.connec_id AND the_geom IS NOT NULL LIMIT 1);

			-- if trace_featuregeom is false, do nothing
			IF v_trace_featuregeom IS TRUE THEN
				UPDATE element SET the_geom = NEW.the_geom WHERE St_dwithin(OLD.the_geom, the_geom, 0.001)
				AND element_id IN (SELECT element_id FROM element_x_connec WHERE connec_id=NEW.connec_id);
			END IF;

			-- setting pjoint_id, pjoint_type and arc_id and removing link in case of connec is over arc
			v_arc_id = (SELECT arc_id FROM ve_arc WHERE st_dwithin(the_geom, NEW.the_geom, 0.01) AND state > 0 LIMIT 1);
			IF v_arc_id IS NULL AND OLD.pjoint_type = 'CONNEC' THEN
				NEW.arc_id = NULL;
				NEW.pjoint_id = NULL;
				NEW.pjoint_type = NULL;
			END IF;

			-- plot_id from plot layer
			IF (SELECT value::boolean FROM config_param_system WHERE parameter = 'edit_connec_autofill_plotcode') = TRUE THEN
				NEW.plot_id = (SELECT id FROM v_plot WHERE st_dwithin(the_geom, NEW.the_geom, 0) LIMIT 1);
			END IF;

		ELSIF st_equals( NEW.the_geom, OLD.the_geom) IS FALSE AND geometrytype(NEW.the_geom)='MULTIPOLYGON'  THEN
			UPDATE polygon SET the_geom=NEW.the_geom WHERE pol_id = OLD.pol_id;
			NEW.sector_id:= (SELECT sector_id FROM sector WHERE ST_DWithin(NEW.the_geom, sector.the_geom,0.001) LIMIT 1);
			NEW.dma_id := (SELECT dma_id FROM dma WHERE ST_DWithin(NEW.the_geom, dma.the_geom,0.001) LIMIT 1);
			NEW.expl_id := (SELECT expl_id FROM exploitation WHERE ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) LIMIT 1);

		END IF;

		-- Reconnect arc_id
		IF (coalesce (NEW.arc_id,0) != coalesce(OLD.arc_id,0)) THEN

			-- when connec_id comes from psector_table
			IF NEW.state = 1 AND (SELECT connec_id FROM plan_psector_x_connec JOIN selector_psector USING (psector_id)
				WHERE connec_id=NEW.connec_id AND psector_id = v_psector_vdefault AND cur_user = current_user AND state = 1) IS NOT NULL THEN

				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":'|| array_to_json(array_agg(NEW.connec_id))||'},"data":{"feature_type":"CONNEC", "forceEndPoint":"true", "forcedArcs":["'||NEW.arc_id||'"]}}$$)';

			ELSIF NEW.state = 2 THEN

				IF NEW.arc_id IS NOT NULL THEN

					IF (SELECT connec_id FROM plan_psector_x_connec JOIN selector_psector USING (psector_id)
						WHERE connec_id=NEW.connec_id AND psector_id = v_psector_vdefault AND cur_user = current_user AND state = 1) IS NOT NULL THEN

						EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
						"feature":{"id":'|| array_to_json(array_agg(NEW.connec_id))||'},"data":{"feature_type":"CONNEC", "forceEndPoint":"true", "forcedArcs":["'||NEW.arc_id||'"]}}$$)';
					END IF;
				ELSE
					IF (SELECT link_id FROM plan_psector_x_connec JOIN selector_psector USING (psector_id)
						WHERE connec_id=NEW.connec_id AND psector_id = v_psector_vdefault AND cur_user = current_user AND state = 1) IS NOT NULL THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3204", "function":"1304","parameters":null}}$$);';
					ELSE
						UPDATE plan_psector_x_connec SET arc_id = null, link_id = null WHERE connec_id=NEW.connec_id AND psector_id = v_psector_vdefault AND state = 1;
					END IF;
				END IF;
			ELSE
				-- when arc_id comes from connec table
				UPDATE connec SET arc_id=COALESCE(NEW.arc_id, OLD.arc_id) where connec_id=NEW.connec_id RETURNING arc_id INTO v_arc_id;

				IF v_arc_id IS NOT NULL THEN
					-- recover values in order to do not disturb this workflow
					SELECT * INTO v_arc FROM arc WHERE arc_id = NEW.arc_id;
					NEW.pjoint_id = v_arc.arc_id; NEW.pjoint_type = 'ARC'; NEW.sector_id = v_arc.sector_id; NEW.dma_id = v_arc.dma_id;
					NEW.presszone_id = v_arc.presszone_id; NEW.dqa_id = v_arc.dqa_id;  NEW.minsector_id = v_arc.minsector_id;
				ELSE
					IF (SELECT count(*)FROM link WHERE feature_id = NEW.connec_id AND state = 1) > 0 THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3204", "function":"1304","parameters":null}}$$);';
					ELSE
						NEW.sector_id = 0; NEW.presszone_id = '0'; NEW.dqa_id = 0; NEW.dma_id = 0; NEW.minsector_id = 0; NEW.minsector_id = 0; NEW.pjoint_id = null; NEW.pjoint_type = null;
					END IF;
				END IF;
			END IF;
		END IF;

		-- Looking for state control and insert planned connecs to default psector
		IF (NEW.state != OLD.state) THEN

			PERFORM gw_fct_state_control(json_build_object('parameters', json_build_object('feature_type_aux', 'CONNEC', 'feature_id_aux', NEW.connec_id, 'state_aux', NEW.state, 'tg_op_aux', TG_OP)));

			IF NEW.state = 2 AND OLD.state=1 THEN

				v_link = (SELECT link_id FROM link WHERE feature_id = NEW.connec_id AND state = 1 LIMIT 1);

				INSERT INTO plan_psector_x_connec (connec_id, psector_id, state, doable, link_id, arc_id)
				VALUES (NEW.connec_id, v_psector_vdefault, 1, true,
				v_link, NEW.arc_id);

				UPDATE link SET state = 2 WHERE link_id  = v_link;
			END IF;

			IF NEW.state = 1 AND OLD.state=2 THEN

				v_link = (SELECT link_id FROM link WHERE feature_id = NEW.connec_id AND state = 2 LIMIT 1);

				-- force delete
				UPDATE config_param_user SET value = 'true' WHERE parameter = 'plan_psector_downgrade_feature' AND cur_user= current_user;
				DELETE FROM plan_psector_x_connec WHERE connec_id=NEW.connec_id;
				-- recover values
				UPDATE config_param_user SET value = 'false' WHERE parameter = 'plan_psector_downgrade_feature' AND cur_user= current_user;

				UPDATE link SET state = 1 WHERE link_id  = v_link;

			END IF;

			UPDATE connec SET state=NEW.state WHERE connec_id = NEW.connec_id;

		END IF;


		-- update inherit link fields
		IF NEW.top_elev IS NOT NULL THEN
			UPDATE link
			SET top_elev1 = NEW.top_elev
			WHERE link_id in (SELECT link_id FROM link WHERE feature_id = NEW.connec_id AND state = 1);
		END IF;

		IF NEW.depth IS NOT NULL THEN
			UPDATE link
			SET depth1 = NEW.depth
			WHERE link_id in (SELECT link_id FROM link WHERE feature_id = NEW.connec_id AND state = 1);
		END IF;

		-- State_type
		IF NEW.state=0 AND OLD.state=1 THEN
			IF (SELECT state FROM value_state_type WHERE id=NEW.state_type) != NEW.state THEN
				NEW.state_type=(SELECT "value" FROM config_param_user WHERE parameter='statetype_end_vdefault' AND "cur_user"="current_user"() LIMIT 1);
				IF NEW.state_type IS NULL THEN
					NEW.state_type=(SELECT id from value_state_type WHERE state=0 LIMIT 1);
					IF NEW.state_type IS NULL THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"2110", "function":"1318","parameters":null}}$$);';
					END IF;
				END IF;
			END IF;

			-- Automatic downgrade of associated link
			UPDATE link SET state=0 WHERE feature_id=OLD.connec_id;

			--check if there is any active hydrometer related to connec
			IF (SELECT count(hydrometer_id) FROM v_hydrometer erh JOIN connec c ON c.customer_code = erh.feature_customer_code
			WHERE (c.connec_id=NEW.connec_id) AND state_id = 1) > 0 THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3184", "function":"1318","parameters":null}}$$);';
			END IF;

		END IF;

		--check relation state - state_type
		IF (NEW.state_type != OLD.state_type) THEN
			IF NEW.state_type NOT IN (SELECT id FROM value_state_type WHERE state = NEW.state) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3036", "function":"1318","parameters":{"state_id":"'||NEW.state::text||'"}}}$$);';
			ELSE
				UPDATE connec SET state_type=NEW.state_type WHERE connec_id = OLD.connec_id;
			END IF;
		END IF;

		-- rotation
		IF NEW.rotation != OLD.rotation THEN
			UPDATE connec SET rotation=NEW.rotation WHERE connec_id = OLD.connec_id;
		END IF;

		--link_path
		SELECT link_path INTO v_link_path FROM cat_feature JOIN cat_connec ON cat_connec.connec_type=cat_feature.id WHERE cat_connec.id=NEW.conneccat_id;
		IF v_link_path IS NOT NULL THEN
			NEW.link = replace(NEW.link, v_link_path,'');
		END IF;

		-- Connec type for parent tables
		IF v_man_table='parent' THEN
	    	IF (NEW.conneccat_id != OLD.conneccat_id) THEN
				v_new_connec_type= (SELECT feature_class FROM cat_feature JOIN cat_connec ON cat_feature.id=connec_type where cat_connec.id=NEW.conneccat_id);
				v_old_connec_type= (SELECT feature_class FROM cat_feature JOIN cat_connec ON cat_feature.id=connec_type where cat_connec.id=OLD.conneccat_id);
				IF v_new_connec_type != v_old_connec_type THEN
					v_sql='INSERT INTO man_'||lower(v_new_connec_type)||' (connec_id) VALUES ('||NEW.connec_id||')';
					EXECUTE v_sql;
					v_sql='DELETE FROM man_'||lower(v_old_connec_type)||' WHERE connec_id='||quote_literal(OLD.connec_id);
					EXECUTE v_sql;
				END IF;
			END IF;
		END IF;

		-- customer_code
		IF (NEW.customer_code != OLD.customer_code) OR (OLD.customer_code IS NULL AND NEW.customer_code IS NOT NULL) THEN
			UPDATE connec SET customer_code=NEW.customer_code WHERE connec_id = OLD.connec_id;
		END IF;

		UPDATE connec
			SET code=NEW.code, sys_code=NEW.sys_code, top_elev=NEW.top_elev, datasource=NEW.datasource, "depth"=NEW.depth, conneccat_id=NEW.conneccat_id, sector_id=COALESCE(NEW.sector_id, OLD.sector_id),
			annotation=NEW.annotation, observ=NEW.observ, "comment"=NEW.comment, rotation=NEW.rotation,dma_id=NEW.dma_id, presszone_id=NEW.presszone_id,
			soilcat_id=NEW.soilcat_id, function_type=NEW.function_type, category_type=NEW.category_type, fluid_type=NEW.fluid_type, location_type=NEW.location_type, workcat_id=NEW.workcat_id,
			workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan, builtdate=NEW.builtdate, enddate=NEW.enddate, ownercat_id=NEW.ownercat_id, streetaxis2_id=NEW.streetaxis2_id,
			postnumber=NEW.postnumber, postnumber2=NEW.postnumber2, muni_id=NEW.muni_id, streetaxis_id=NEW.streetaxis_id, postcode=NEW.postcode,
			district_id =NEW.district_id, descript=NEW.descript, verified=NEW.verified, postcomplement=NEW.postcomplement, postcomplement2=NEW.postcomplement2,
			label_x=NEW.label_x,label_y=NEW.label_y, label_rotation=NEW.label_rotation,publish=NEW.publish,
			inventory=NEW.inventory, expl_id=NEW.expl_id, num_value=NEW.num_value, link=NEW.link, updated_at=now(), updated_by=current_user,
			dqa_id=NEW.dqa_id, minsector_id=NEW.minsector_id, pjoint_id=NEW.pjoint_id, pjoint_type = NEW.pjoint_type,
			adate=NEW.adate, adescript=NEW.adescript, accessibility =  NEW.accessibility, asset_id=NEW.asset_id, epa_type = NEW.epa_type,
			om_state = NEW.om_state, conserv_state = NEW.conserv_state, priority = NEW.priority, access_type = NEW.access_type, placement_type = NEW.placement_type,
			crmzone_id=NEW.crmzone_id, expl_visibility=NEW.expl_visibility, plot_id=NEW.plot_id, brand_id=NEW.brand_id, model_id=NEW.model_id, serial_number=NEW.serial_number,
			label_quadrant=NEW.label_quadrant, n_inhabitants = NEW.n_inhabitants, lock_level=NEW.lock_level, block_code=NEW.block_code, n_hydrometer=NEW.n_hydrometer, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
			WHERE connec_id=OLD.connec_id;

		-- update connec_add table
		UPDATE connec_add SET demand_base = NEW.demand_base, demand_max = NEW.demand_max, demand_min = NEW.demand_min, demand_avg = NEW.demand_avg, press_max = NEW.press_max,
		press_min = NEW.press_min, press_avg = NEW.press_avg, quality_max = NEW.quality_max, quality_min = NEW.quality_min, quality_avg = NEW.quality_avg,
		flow_max = NEW.flow_max, flow_min = NEW.flow_min, flow_avg = NEW.flow_avg, vel_max = NEW.vel_max, vel_min = NEW.vel_min, vel_avg = NEW.vel_avg,
		result_id = NEW.result_id
		WHERE connec_id = OLD.connec_id;

		IF v_man_table ='man_greentap' THEN
			UPDATE man_greentap SET linked_connec=NEW.linked_connec,
			greentap_type=NEW.greentap_type
			WHERE connec_id=OLD.connec_id;

		ELSIF v_man_table ='man_wjoin' THEN
			UPDATE man_wjoin SET top_floor=NEW.top_floor,
			wjoin_type=NEW.wjoin_type
			WHERE connec_id=OLD.connec_id;

		ELSIF v_man_table ='man_tap' THEN
			UPDATE man_tap SET linked_connec=NEW.linked_connec, drain_diam=NEW.drain_diam,drain_exit=NEW.drain_exit,drain_gully=NEW.drain_gully,
			drain_distance=NEW.drain_distance, arq_patrimony=NEW.arq_patrimony, com_state=NEW.com_state
			WHERE connec_id=OLD.connec_id;

		ELSIF v_man_table ='man_fountain' THEN
			UPDATE man_fountain SET vmax=NEW.vmax,vtotal=NEW.vtotal,container_number=NEW.container_number,pump_number=NEW.pump_number,power=NEW.power,
			regulation_tank=NEW.regulation_tank,name=NEW.name,chlorinator=NEW.chlorinator, linked_connec=NEW.linked_connec, arq_patrimony=NEW.arq_patrimony
			WHERE connec_id=OLD.connec_id;
		
		ELSIF v_man_table='man_samplepoint' THEN
			UPDATE man_samplepoint SET lab_code=NEW.lab_code, place_name=NEW.place_name, cabinet=NEW.cabinet
			WHERE connec_id=OLD.connec_id;
		END IF;

		-- childtable update
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='CONNEC' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING NEW
					INTO v_new_value_param;

				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING OLD
					INTO v_old_value_param;

				v_childtable_name := 'man_connec_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF (v_new_value_param IS NOT NULL AND v_old_value_param!=v_new_value_param) OR (v_new_value_param IS NOT NULL AND v_old_value_param IS NULL) THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (connec_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (connec_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.connec_id=$1'
							USING NEW.connec_id, v_new_value_param;

					ELSIF v_new_value_param IS NULL AND v_old_value_param IS NOT NULL THEN
						EXECUTE 'UPDATE '||v_childtable_name||' SET '||v_addfields.param_name||' = null WHERE '||v_childtable_name||'.connec_id=$1'
							USING NEW.connec_id;
					END IF;
				END IF;
			END LOOP;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		EXECUTE 'SELECT gw_fct_getcheckdelete($${"client":{"device":4, "infoType":1, "lang":"ES"},
		"feature":{"id":"'||OLD.connec_id||'","featureType":"CONNEC"}, "data":{}}$$)';

		-- force plan_psector_force_delete
		SELECT value INTO v_force_delete FROM config_param_user WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;
		UPDATE config_param_user SET value = 'true' WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		DELETE FROM connec WHERE connec_id = OLD.connec_id;

 		-- restore plan_psector_force_delete
		UPDATE config_param_user SET value = v_force_delete WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		DELETE FROM polygon WHERE feature_id = OLD.connec_id;

		-- delete links
		FOR v_record_link IN SELECT * FROM link WHERE feature_type='CONNEC' AND feature_id=OLD.connec_id
		LOOP
			-- delete link
			DELETE FROM link WHERE link_id=v_record_link.link_id;

		END LOOP;

		-- Delete childtable addfields (after or before deletion of node, doesn't matter)

		v_customfeature = old.connec_type;
		v_connec_id = old.connec_id;

	   	v_childtable_name := 'man_connec_' || lower(v_customfeature);
		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
			EXECUTE 'DELETE FROM '||v_childtable_name||' WHERE connec_id = '||quote_literal(v_connec_id)||'';
		END IF;

		RETURN NULL;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1202


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_edit_arc()
  RETURNS trigger AS
$BODY$
DECLARE
v_inp_table varchar;
v_man_table varchar;
v_new_man_table varchar;
v_old_man_table varchar;
v_sql varchar;
v_type_v_man_table varchar;
v_count integer;
v_proximity_buffer double precision;
ve_enable_arc_nodes_update boolean;
v_code_autofill_bool boolean;
v_link_path varchar;
v_addfields record;
v_new_value_param text;
v_old_value_param text;
v_customfeature text;
v_featurecat text;
v_matfromcat boolean = false;
v_force_delete boolean;
v_autoupdate_fluid boolean;
v_psector integer;
v_auto_sander boolean;
v_arc_id text;
v_childtable_name text;
v_schemaname text;
rec_param_link record;
v_connecs text;
v_sys_code_autofill text;

v_district_ids _int4;

BEGIN
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	v_man_table:= TG_ARGV[0];
    v_schemaname:= TG_TABLE_SCHEMA;

	--modify values for custom view inserts
	IF v_man_table IN (SELECT id FROM cat_feature_arc) THEN
		v_customfeature:=v_man_table;
		v_man_table:=(SELECT man_table FROM cat_feature_arc c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id=v_man_table);
	END IF;

	v_type_v_man_table:=v_man_table;

	v_proximity_buffer = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_feature_buffer_on_mapzone');
	ve_enable_arc_nodes_update = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_arc_enable nodes_update');
	v_autoupdate_fluid = (SELECT value::boolean FROM config_param_system WHERE parameter='edit_connect_autoupdate_fluid');
	v_psector = (SELECT value::integer FROM config_param_user WHERE "parameter"='plan_psector_current' AND cur_user=current_user);
	v_sys_code_autofill := (SELECT (value::json->>'arc')::text FROM config_param_system WHERE parameter = 'edit_sys_code_autofill');

	SELECT value::boolean into v_auto_sander FROM config_param_system WHERE parameter='edit_node_automatic_sander';

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN

		IF NEW.arccat_id NOT IN (SELECT id FROM cat_arc WHERE arc_type = NEW.arc_type) AND NEW.arc_type IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	       		"data":{"message":"4464", "function":"1202","parameters":null, "is_process":true}}$$);';
		END IF;
		-- managing matcat
		IF (SELECT matcat_id FROM cat_arc WHERE id = NEW.arccat_id) IS NOT NULL THEN
			v_matfromcat = true;
		END IF;

	END IF;

	IF TG_OP = 'INSERT' THEN

		-- force current psector
		IF NEW.state = 2 THEN
			INSERT INTO selector_psector (psector_id, cur_user) VALUES (v_psector, current_user) ON CONFLICT DO NOTHING;
		END IF;

		-- Arc ID
		IF NEW.arc_id != (SELECT last_value FROM urn_id_seq) OR NEW.arc_id IS NULL THEN
			NEW.arc_id = (SELECT nextval('urn_id_seq'));
		END IF;

		 -- Arc type
		IF (NEW.arc_type IS NULL) THEN
			IF ((SELECT COUNT(*) FROM cat_feature_arc JOIN cat_feature USING (id) WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1018", "function":"1202","parameters":null}}$$);';
			END IF;

			IF v_customfeature IS NOT NULL THEN
				NEW.arc_type:=v_customfeature;
			END IF;

			 -- get it from relation on cat_node
 			IF NEW.arc_type IS NULL THEN
				NEW.arc_type:= (SELECT c.id FROM cat_feature_arc c JOIN cat_arc s ON c.id = s.arc_type WHERE s.id=NEW.arccat_id);
			END IF;

			-- get it from vdefault
			IF (NEW.arc_type IS NULL) AND v_man_table='parent' THEN
				NEW.arc_type:=(SELECT "value" FROM config_param_user WHERE "parameter"='edit_arctype_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			IF (NEW.arc_type IS NULL) AND v_man_table !='parent' THEN
				NEW.arc_type:= (SELECT c.id FROM cat_feature_arc c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE man_table=v_type_v_man_table LIMIT 1);
			END IF;
		END IF;

		 -- Epa type
		IF (NEW.epa_type IS NULL) THEN
			NEW.epa_type:= (SELECT epa_default FROM cat_feature_arc WHERE cat_feature_arc.id=NEW.arc_type)::text;
		END IF;

		-- Arc catalog ID
		IF (NEW.arccat_id IS NULL) THEN
			IF ((SELECT COUNT(*) FROM cat_arc WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1020", "function":"1202","parameters":null}}$$);';
			END IF;
				NEW.arccat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_arccat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			IF (NEW.arccat_id IS NULL) THEN
				NEW.arccat_id := (SELECT arccat_id from arc WHERE ST_DWithin(NEW.the_geom, arc.the_geom,0.001) LIMIT 1);
			END IF;
		ELSE
			IF (SELECT true from cat_arc where id=NEW.arccat_id) IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3282", "function":"1202","parameters":{"catalog_value":"'||NEW.arccat_id||'"}}}$$);';
			END IF;
		END IF;


		-- Exploitation
		IF (NEW.expl_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1110", "function":"1202","parameters":null}}$$);';
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
				"data":{"message":"2012", "function":"1202","parameters":{"feature_id":"'||NEW.arc_id::text||'"}}}$$);';
			END IF;
		END IF;


		-- Sector ID
		IF (NEW.sector_id IS NULL ) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM sector WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1008", "function":"1202","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.sector_id IS NULL) THEN
				NEW.sector_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_sector_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.sector_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM sector WHERE ST_DWithin(NEW.the_geom, sector.the_geom,0.001) AND active IS TRUE;
				IF v_count = 1 THEN
					NEW.sector_id = (SELECT sector_id FROM sector WHERE ST_DWithin(NEW.the_geom, sector.the_geom,0.001) AND active IS TRUE LIMIT 1);
				ELSE
					NEW.sector_id =(SELECT sector_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- control error when no value
			IF (NEW.sector_id IS NULL) THEN
				NEW.sector_id = 0;
			END IF;
		END IF;


		-- Omzone ID
		IF (NEW.omzone_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM omzone WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1012", "function":"1202","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.omzone_id IS NULL) THEN
				NEW.omzone_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_omzone_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.omzone_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM omzone WHERE ST_DWithin(NEW.the_geom, omzone.the_geom,0.001) AND active IS TRUE;
				IF v_count = 1 THEN
					NEW.omzone_id = (SELECT omzone_id FROM omzone WHERE ST_DWithin(NEW.the_geom, omzone.the_geom,0.001) AND active IS TRUE LIMIT 1);
				ELSE
					NEW.omzone_id =(SELECT omzone_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- control error when no value
			IF (NEW.omzone_id IS NULL) THEN
				NEW.omzone_id = 0;
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
				SELECT count(*) INTO v_count FROM v_municipality WHERE ST_DWithin(NEW.the_geom, v_municipality.the_geom,0.001);
				IF v_count = 1 THEN
					NEW.muni_id = (SELECT muni_id FROM v_municipality WHERE ST_DWithin(NEW.the_geom, v_municipality.the_geom,0.001)
						AND active IS TRUE LIMIT 1);
				ELSE
					NEW.muni_id =(SELECT muni_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;
		END IF;


		-- Verified
		IF (NEW.verified IS NULL) THEN
			NEW.verified := (SELECT "value"::INTEGER FROM config_param_user WHERE "parameter"='edit_verified_vdefault' AND "cur_user"="current_user"() LIMIT 1);
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
       			"data":{"message":"3036", "function":"1202","parameters":{"state_id":"'||v_sql::text||'"}}}$$);';
	       	END IF;

		--Publish
		IF NEW.publish IS NULL THEN
			NEW.publish := (SELECT "value" FROM config_param_system WHERE "parameter"='edit_publish_sysvdefault');
		END IF;

		--Uncertain
		IF NEW.uncertain IS NULL THEN
			NEW.uncertain := (SELECT "value" FROM config_param_system WHERE "parameter"='edit_uncertain_sysvdefault');
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
			NEW.builtdate:=(SELECT "value" FROM config_param_user WHERE "parameter"='edit_builtdate_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			IF (NEW.builtdate IS NULL) AND (SELECT value::boolean FROM config_param_system WHERE parameter='edit_feature_auto_builtdate') IS TRUE THEN
				NEW.builtdate :=date(now());
			END IF;
		END IF;

		-- Code
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		SELECT code_autofill, cat_feature.id
		INTO v_code_autofill_bool, v_featurecat
		FROM cat_feature WHERE id = NEW.arc_type;

		IF NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('feature', NEW.arc_type, json_strip_nulls(row_to_json(NEW)::json));

			IF NEW.code IS NULL AND v_code_autofill_bool THEN
				NEW.code := NEW.arc_id;
			END IF;
		END IF;

		IF NEW.sys_code IS NOT NULL AND v_sys_code_autofill NOT IN ('false', 'none') THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4678", "function":"1202", "is_process":true}}$$);';
		END IF;

		--Sys_code (uuid | code | none)
		IF v_sys_code_autofill IN ('uuid', 'true') THEN
			NEW.sys_code := gen_random_uuid();
		ELSIF v_sys_code_autofill = 'code' THEN
			NEW.sys_code := NEW.code;
		END IF;

		-- LINK
		IF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=NEW.arc_id;
		END IF;

		--Location type
		IF NEW.location_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_location_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'featureval_location_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.location_type IS NULL THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_arc_location_vdefault' AND cur_user = current_user);
		END IF;

		--Fluid type
		IF NEW.fluid_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_fluid_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_fluid_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.fluid_type IS NULL THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_arc_fluid_vdefault' AND cur_user = current_user);
		END IF;

		--Category type
		IF NEW.category_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_category_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_category_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.category_type IS NULL THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_arc_category_vdefault' AND cur_user = current_user);
		END IF;

		--Function type
		IF NEW.function_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_function_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_function_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.function_type IS NULL THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_arc_function_vdefault' AND cur_user = current_user);
		END IF;

        --Pavement
		IF NEW.pavcat_id IS NULL THEN
			NEW.pavcat_id = (SELECT value FROM config_param_user WHERE parameter = 'edit_pavementcat_vdefault' AND cur_user = current_user);
		END IF;

		-- visitability
		IF NEW.visitability IS NULL THEN
			NEW.visitability = (SELECT visitability_vdef FROM cat_arc WHERE id = NEW.arccat_id);
		END IF;
		
		-- uuid random
		IF NEW.uuid is null then
			NEW.uuid = gen_random_uuid();
		END IF;

		-- FEATURE INSERT
		IF v_matfromcat THEN
			INSERT INTO arc (arc_id, code, sys_code, node_1, node_2, y1, y2, elev1, elev2, custom_elev1, custom_elev2, arc_type, arccat_id, epa_type, sector_id, "state", state_type,
			annotation, observ, "comment", inverted_slope, custom_length, omzone_id, dma_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan,
			builtdate, enddate, ownercat_id, muni_id, streetaxis_id, postcode, district_id, streetaxis2_id, postnumber, postnumber2, postcomplement, postcomplement2, descript, link, verified,
			the_geom,label_x,label_y, label_rotation, expl_id, publish, inventory, uncertain, num_value, updated_at, updated_by, asset_id, pavcat_id,
			parent_id, expl_visibility, adate, adescript, visitability, label_quadrant, brand_id, model_id, serial_number, initoverflowpath, lock_level, is_scadamap, registration_date,
			meandering, conserv_state, om_state, last_visitdate, negative_offset, drainzone_outfall, dwfzone_outfall, omunit_id, uuid, treatment_type, dataquality, dataquality_obs)
			VALUES (NEW.arc_id, NEW.code, NEW.sys_code, NEW.node_1, NEW.node_2, NEW.y1, NEW.y2, NEW.elev1, NEW.elev2,
			NEW.custom_elev1, NEW.custom_elev2,NEW.arc_type, NEW.arccat_id, NEW.epa_type, COALESCE(NEW.sector_id, 0), NEW.state, NEW.state_type, NEW.annotation, NEW.observ, NEW.comment,
			NEW.inverted_slope, NEW.custom_length, COALESCE(NEW.omzone_id, 0), COALESCE(NEW.dma_id, 0), NEW.soilcat_id, NEW.function_type, NEW.category_type, COALESCE(NEW.fluid_type, 0),
			NEW.location_type, NEW.workcat_id,NEW.workcat_id_end, NEW.workcat_id_plan, NEW.builtdate, NEW.enddate, NEW.ownercat_id,
			COALESCE(NEW.muni_id, 0), NEW.streetaxis_id,  NEW.postcode, NEW.district_id, NEW.streetaxis2_id, NEW.postnumber, NEW.postnumber2, NEW.postcomplement, NEW.postcomplement2,
			NEW.descript, NEW.link, NEW.verified, NEW.the_geom,NEW.label_x,
			NEW.label_y, NEW.label_rotation, COALESCE(NEW.expl_id, 0), NEW.publish, NEW.inventory, NEW.uncertain, NEW.num_value, NEW.updated_at, NEW.updated_by, NEW.asset_id, NEW.pavcat_id,
			 NEW.parent_id, NEW.expl_visibility, NEW.adate, NEW.adescript, NEW.visitability, NEW.label_quadrant, NEW.brand_id, NEW.model_id, NEW.serial_number, NEW.initoverflowpath, NEW.lock_level, NEW.is_scadamap,
			NEW.registration_date, NEW.meandering, NEW.conserv_state, NEW.om_state, NEW.last_visitdate, NEW.negative_offset, NEW.drainzone_outfall, NEW.dwfzone_outfall, COALESCE(NEW.omunit_id, 0), NEW.uuid, COALESCE(NEW.treatment_type, 0), NEW.dataquality, NEW.dataquality_obs);
		ELSE
			INSERT INTO arc (arc_id, code, sys_code, y1, y2, elev1, elev2, custom_elev1, custom_elev2, arc_type, arccat_id, epa_type, sector_id, "state", state_type,
			annotation, observ, "comment", inverted_slope, custom_length, omzone_id, dma_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan,
			builtdate, enddate, ownercat_id, muni_id, streetaxis_id, postcode, district_id, streetaxis2_id, postnumber, postnumber2, postcomplement, postcomplement2, descript, link, verified,
			the_geom,label_x,label_y, label_rotation, expl_id, publish, inventory,	uncertain, num_value, matcat_id, updated_at, updated_by, asset_id, pavcat_id,
			parent_id, expl_visibility, adate, adescript, visitability, label_quadrant, brand_id, model_id, serial_number, initoverflowpath, lock_level, is_scadamap, registration_date,
			meandering, conserv_state, om_state, last_visitdate, negative_offset, drainzone_outfall, dwfzone_outfall, omunit_id, uuid, treatment_type, dataquality, dataquality_obs)
			VALUES (NEW.arc_id, NEW.code, NEW.sys_code, NEW.y1, NEW.y2, NEW.elev1, NEW.elev2,
			NEW.custom_elev1, NEW.custom_elev2,NEW.arc_type, NEW.arccat_id, NEW.epa_type, COALESCE(NEW.sector_id, 0), NEW.state, NEW.state_type, NEW.annotation, NEW.observ, NEW.comment,
			NEW.inverted_slope, NEW.custom_length, COALESCE(NEW.omzone_id, 0), COALESCE(NEW.dma_id, 0), NEW.soilcat_id, NEW.function_type, NEW.category_type, COALESCE(NEW.fluid_type, 0),
			NEW.location_type, NEW.workcat_id,NEW.workcat_id_end, NEW.workcat_id_plan, NEW.builtdate, NEW.enddate, NEW.ownercat_id,
			COALESCE(NEW.muni_id, 0), NEW.streetaxis_id,  NEW.postcode, NEW.district_id, NEW.streetaxis2_id, NEW.postnumber, NEW.postnumber2, NEW.postcomplement, NEW.postcomplement2,
			NEW.descript, NEW.link, NEW.verified, NEW.the_geom,NEW.label_x,
			NEW.label_y, NEW.label_rotation, COALESCE(NEW.expl_id, 0), NEW.publish, NEW.inventory, NEW.uncertain, NEW.num_value, NEW.matcat_id, NEW.updated_at, NEW.updated_by,
			NEW.asset_id, NEW.pavcat_id,  NEW.parent_id, NEW.expl_visibility, NEW.adate, NEW.adescript, NEW.visitability, NEW.label_quadrant, NEW.brand_id, NEW.model_id, NEW.serial_number, NEW.initoverflowpath, NEW.lock_level, NEW.is_scadamap,
			NEW.registration_date, NEW.meandering, NEW.conserv_state, NEW.om_state, NEW.last_visitdate, NEW.negative_offset, NEW.drainzone_outfall, NEW.dwfzone_outfall, COALESCE(NEW.omunit_id, 0), NEW.uuid, COALESCE(NEW.treatment_type, 0), NEW.dataquality, NEW.dataquality_obs);
		END IF;

		INSERT INTO arc_add (arc_id, result_id, max_flow, max_veloc, mfull_flow, mfull_depth, manning_veloc, manning_flow, dwf_minflow, dwf_maxflow, dwf_minvel, dwf_maxvel, conduit_capacity)
		VALUES ( NEW.arc_id, NEW.result_id, NEW.max_flow, NEW.max_veloc, NEW.mfull_flow, NEW.mfull_depth, NEW.manning_veloc, NEW.manning_flow, NEW.dwf_minflow,
		NEW.dwf_maxflow, NEW.dwf_minvel, NEW.dwf_maxvel, NEW.conduit_capacity);

		-- this overwrites triger topocontrol arc values (triggered before insertion) just in that moment: In order to make more profilactic this issue only will be overwrited in case of NEW.node_* not nulls
		IF ve_enable_arc_nodes_update IS TRUE THEN
			IF NEW.node_1 IS NOT NULL THEN
				UPDATE arc SET node_1=NEW.node_1 WHERE arc_id=NEW.arc_id;
			END IF;
			IF NEW.node_2 IS NOT NULL THEN
				UPDATE arc SET node_2=NEW.node_2 WHERE arc_id=NEW.arc_id;
			END IF;
		END IF;

		IF v_man_table='man_conduit' THEN

			INSERT INTO man_conduit (arc_id, bottom_mat, conduit_code) VALUES (NEW.arc_id, NEW.bottom_mat, NEW.conduit_code);

		ELSIF v_man_table='man_siphon' THEN

			INSERT INTO man_siphon (arc_id,name, siphon_code) VALUES (NEW.arc_id,NEW.name, NEW.siphon_code);

		ELSIF v_man_table='man_waccel' THEN

			INSERT INTO man_waccel (arc_id, sander_length,sander_depth,prot_surface,accessibility, name, waccel_code)
			VALUES (NEW.arc_id, NEW.sander_length, NEW.sander_depth,NEW.prot_surface,NEW.accessibility, NEW.name, NEW.waccel_code);

		ELSIF v_man_table='man_varc' THEN

			INSERT INTO man_varc (arc_id) VALUES (NEW.arc_id);

		ELSIF v_man_table='parent' THEN
		v_man_table := (SELECT man_table FROM cat_feature_arc c	JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id
		JOIN cat_arc ON c.id = cat_arc.arc_type WHERE cat_arc.id=NEW.arccat_id);
		v_sql:= 'INSERT INTO '||v_man_table||' (arc_id) VALUES ('||quote_literal(NEW.arc_id)||')';
		EXECUTE v_sql;

		END IF;

		--sander calculation
		IF v_auto_sander IS TRUE THEN
			EXECUTE 'SELECT gw_fct_calculate_sander($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":"'||NEW.node_1||'"}}$$)';
		END IF;

		-- EPA INSERT
		IF (NEW.epa_type = 'CONDUIT') THEN
		    INSERT INTO inp_conduit (arc_id, q0, qmax) VALUES (NEW.arc_id,0,0);

		ELSIF (NEW.epa_type = 'PUMP') THEN
		    INSERT INTO inp_pump (arc_id) VALUES (NEW.arc_id);

		ELSIF (NEW.epa_type = 'ORIFICE') THEN
		    INSERT INTO inp_orifice (arc_id, ori_type) VALUES (NEW.arc_id,'BOTTOM');

		ELSIF (NEW.epa_type = 'WEIR') THEN
		    INSERT INTO inp_weir (arc_id, weir_type) VALUES (NEW.arc_id,'SIDEFLOW');

		ELSIF (NEW.epa_type = 'OUTLET') THEN
		    INSERT INTO inp_outlet (arc_id, outlet_type) VALUES (NEW.arc_id,'TABULAR/HEAD');

		ELSIF (NEW.epa_type = 'VIRTUAL') THEN
		    INSERT INTO inp_virtual (arc_id, add_length) VALUES (NEW.arc_id, false);

		END IF;

		-- childtable insert
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='ARC' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' ||v_addfields.param_name||'"'
					USING NEW
					INTO v_new_value_param;

				v_childtable_name := 'man_arc_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF v_new_value_param IS NOT NULL THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (arc_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (arc_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.arc_id=$1'
							USING NEW.arc_id, v_new_value_param;
					END IF;
				END IF;
			END LOOP;
		END IF;


		-- automatic connection of closest connecs to the arc
		SELECT
		("value"::json->>'active')::boolean as v_active,
		("value"::json->>'buffer')::numeric as v_buffer
		INTO rec_param_link
		FROM config_param_user
		WHERE "parameter" ilike 'edit_arc_automatic_link2network'
		AND cur_user = current_user;

		IF rec_param_link.v_active is true THEN

			SELECT string_agg(connec_id::text, ',')
			INTO v_connecs
			FROM ve_connec c
			WHERE st_dwithin (new.the_geom, c.the_geom, rec_param_link.v_buffer)
			AND c.connec_id not in (select feature_id from ve_link);

			execute 'SELECT gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1,"lang":"ES"},"feature":
			{"id":"['||v_connecs||']"}, "data":{"feature_type":"CONNEC", "forcedArcs":["'||new.arc_id||'"]}}$$)';

		END IF;



		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('feature', NEW.arc_type, json_strip_nulls(row_to_json(NEW)::json));
		END IF;

				-- this overwrites triger topocontrol arc values (triggered before insertion) just in that moment: In order to make more profilactic this issue only will be overwrited in case of NEW.node_* not nulls
		IF ve_enable_arc_nodes_update IS TRUE THEN
			IF NEW.node_1 IS NOT NULL THEN
				UPDATE arc SET node_1=NEW.node_1 WHERE arc_id=NEW.arc_id;
			END IF;
			IF NEW.node_2 IS NOT NULL THEN
				UPDATE arc SET node_2=NEW.node_2 WHERE arc_id=NEW.arc_id;
			END IF;
		END IF;

		-- State
		IF (NEW.state != OLD.state) THEN
			UPDATE arc SET state=NEW.state WHERE arc_id = OLD.arc_id;
			IF NEW.state = 2 AND OLD.state=1 THEN
				INSERT INTO plan_psector_x_arc (arc_id, psector_id, state, doable)
				VALUES (NEW.arc_id, (SELECT config_param_user.value::integer AS value FROM config_param_user WHERE config_param_user.parameter::text
				= 'plan_psector_current'::text AND config_param_user.cur_user::name = "current_user"() LIMIT 1), 1, true);
			END IF;
			IF NEW.state = 1 AND OLD.state=2 THEN
				DELETE FROM plan_psector_x_arc WHERE arc_id=NEW.arc_id;
			END IF;
			IF NEW.state=0 THEN
				UPDATE arc SET node_1=NULL, node_2=NULL WHERE arc_id = OLD.arc_id;
			END IF;
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
		END IF;

		--check relation state - state_type
		IF (NEW.state_type != OLD.state_type) AND NEW.state_type NOT IN (SELECT id FROM value_state_type WHERE state = NEW.state) THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3036", "function":"1202","parameters":{"state_id":"'||NEW.state::text||'"}}}$$);';
		END IF;

		-- The geom
		IF st_orderingequals(NEW.the_geom, OLD.the_geom) IS FALSE OR NEW.node_1 IS NULL OR NEW.node_2 IS NULL THEN
			UPDATE arc SET the_geom=NEW.the_geom WHERE arc_id = OLD.arc_id;
		END IF;

		IF (NEW.epa_type != OLD.epa_type) THEN

			IF (OLD.epa_type = 'CONDUIT') THEN
				v_inp_table:= 'inp_conduit';
			ELSIF (OLD.epa_type = 'PUMP') THEN
				v_inp_table:= 'inp_pump';
			ELSIF (OLD.epa_type = 'ORIFICE') THEN
				v_inp_table:= 'inp_orifice';
			ELSIF (OLD.epa_type = 'WEIR') THEN
				v_inp_table:= 'inp_weir';
			ELSIF (OLD.epa_type = 'OUTLET') THEN
				v_inp_table:= 'inp_outlet';
			ELSIF (OLD.epa_type = 'VIRTUAL') THEN
				v_inp_table:= 'inp_virtual';
			END IF;

			IF v_inp_table IS NOT NULL THEN
				v_sql:= 'DELETE FROM '||v_inp_table||' WHERE arc_id = '||quote_literal(OLD.arc_id);
				EXECUTE v_sql;
			END IF;

			v_inp_table := NULL;

			IF (NEW.epa_type = 'CONDUIT') THEN
				v_inp_table:= 'inp_conduit';
			ELSIF (NEW.epa_type = 'PUMP') THEN
				v_inp_table:= 'inp_pump';
			ELSIF (NEW.epa_type = 'ORIFICE') THEN
				v_inp_table:= 'inp_orifice';
			ELSIF (NEW.epa_type = 'WEIR') THEN
				v_inp_table:= 'inp_weir';
			ELSIF (NEW.epa_type = 'OUTLET') THEN
				v_inp_table:= 'inp_outlet';
			ELSIF (NEW.epa_type = 'VIRTUAL') THEN
				v_inp_table:= 'inp_virtual';
			END IF;
			IF v_inp_table IS NOT NULL THEN
				v_sql:= 'INSERT INTO '||v_inp_table||' (arc_id) VALUES ('||quote_literal(NEW.arc_id)||') ON CONFLICT (arc_id) DO NOTHING ';
				EXECUTE v_sql;
			END IF;

		END IF;

		 -- UPDATE management values
		IF (NEW.arc_type <> OLD.arc_type) THEN
			v_new_man_table:= (SELECT man_table FROM cat_feature_arc  c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id = NEW.arc_type);
			v_old_man_table:= (SELECT man_table FROM cat_feature_arc  c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id = OLD.arc_type);
			IF v_new_man_table IS NOT NULL THEN
				v_sql:= 'DELETE FROM '||v_old_man_table||' WHERE arc_id= '||quote_literal(OLD.arc_id);
				EXECUTE v_sql;
				v_sql:= 'INSERT INTO '||v_new_man_table||' (arc_id) VALUES ('||quote_literal(NEW.arc_id)||')';
				EXECUTE v_sql;
			END IF;
		END IF;

		--link_path
		SELECT link_path INTO v_link_path FROM cat_feature WHERE id=NEW.arc_type;
		IF v_link_path IS NOT NULL THEN
			NEW.link = replace(NEW.link, v_link_path,'');
		END IF;

		-- Update of topocontrol fields only when one if it has changed in order to prevent to be triggered the topocontrol without changes
		IF (NEW.y1 != OLD.y1) OR (NEW.y1 IS NULL AND OLD.y1 IS NOT NULL) OR (NEW.y1 IS NOT NULL AND OLD.y1 IS NULL) OR
		   (NEW.y2 != OLD.y2) OR (NEW.y2 IS NULL AND OLD.y2 IS NOT NULL) OR (NEW.y2 IS NOT NULL AND OLD.y2 IS NULL) OR
		   (NEW.elev1 != OLD.elev1) OR (NEW.elev1 IS NULL AND OLD.elev1 IS NOT NULL) OR (NEW.elev1 IS NOT NULL AND OLD.elev1 IS NULL) OR
		   (NEW.elev2 != OLD.elev2) OR (NEW.elev2 IS NULL AND OLD.elev2 IS NOT NULL) OR (NEW.elev2 IS NOT NULL AND OLD.elev2 IS NULL) OR
		   (NEW.custom_elev1 != OLD.custom_elev1) OR (NEW.custom_elev1 IS NULL AND OLD.custom_elev1 IS NOT NULL) OR (NEW.custom_elev1 IS NOT NULL AND OLD.custom_elev1 IS NULL) OR
		   (NEW.custom_elev2 != OLD.custom_elev2) OR (NEW.custom_elev2 IS NULL AND OLD.custom_elev2 IS NOT NULL) OR (NEW.custom_elev2 IS NOT NULL AND OLD.custom_elev2 IS NULL) OR
		   (NEW.inverted_slope::text != OLD.inverted_slope::text) OR (NEW.inverted_slope is null and OLD.inverted_slope is not null)
		   OR (NEW.inverted_slope is not null and OLD.inverted_slope is null)
		   THEN
			UPDATE arc SET y1=NEW.y1, y2=NEW.y2, elev1=NEW.elev1, elev2=NEW.elev2,
					custom_elev1=NEW.custom_elev1, custom_elev2=NEW.custom_elev2, inverted_slope=NEW.inverted_slope
					WHERE arc_id=NEW.arc_id;
		END IF;


		-- parent table fields
		IF v_matfromcat THEN

			UPDATE arc
			SET arc_type=NEW.arc_type, sys_code=NEW.sys_code, arccat_id=NEW.arccat_id, epa_type=NEW.epa_type, sector_id=NEW.sector_id, state_type=NEW.state_type,
			annotation= NEW.annotation, "observ"=NEW.observ,"comment"=NEW.comment, custom_length=NEW.custom_length, omzone_id=NEW.omzone_id,
			soilcat_id=NEW.soilcat_id, function_type=NEW.function_type, category_type=NEW.category_type, fluid_type=COALESCE(NEW.fluid_type, 0),location_type=NEW.location_type,
			workcat_id=NEW.workcat_id, builtdate=NEW.builtdate,ownercat_id=NEW.ownercat_id, muni_id=NEW.muni_id, streetaxis_id=NEW.streetaxis_id,
			postcode=NEW.postcode, district_id = NEW.district_id, streetaxis2_id=NEW.streetaxis2_id, postcomplement=NEW.postcomplement,
			postcomplement2=NEW.postcomplement2, postnumber=NEW.postnumber, postnumber2=NEW.postnumber2,  descript=NEW.descript, link=NEW.link,
			verified=NEW.verified,label_x=NEW.label_x,
			label_y=NEW.label_y, label_rotation=NEW.label_rotation,workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan, code=NEW.code, publish=NEW.publish, inventory=NEW.inventory,
			enddate=NEW.enddate, uncertain=NEW.uncertain, expl_id=NEW.expl_id, num_value = NEW.num_value,updated_at=now(), updated_by=current_user,
			asset_id=NEW.asset_id, pavcat_id=NEW.pavcat_id, parent_id=NEW.parent_id, expl_visibility=NEW.expl_visibility, adate=NEW.adate, adescript=NEW.adescript,
			visitability=NEW.visitability, label_quadrant=NEW.label_quadrant, brand_id=NEW.brand_id, model_id=NEW.model_id, serial_number=NEW.serial_number,
			initoverflowpath=NEW.initoverflowpath, lock_level=NEW.lock_level, is_scadamap=NEW.is_scadamap, registration_date=NEW.registration_date,
			meandering=NEW.meandering, conserv_state=NEW.conserv_state, om_state=NEW.om_state, last_visitdate=NEW.last_visitdate, negative_offset=NEW.negative_offset, drainzone_outfall=NEW.drainzone_outfall, dwfzone_outfall=NEW.dwfzone_outfall, omunit_id=NEW.omunit_id, dma_id=NEW.dma_id, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
			WHERE arc_id=OLD.arc_id;
		ELSE
			UPDATE arc
			SET arc_type=NEW.arc_type, sys_code=NEW.sys_code, arccat_id=NEW.arccat_id, epa_type=NEW.epa_type, sector_id=NEW.sector_id, state_type=NEW.state_type,
			annotation= NEW.annotation, "observ"=NEW.observ,"comment"=NEW.comment, custom_length=NEW.custom_length, omzone_id=NEW.omzone_id,
			soilcat_id=NEW.soilcat_id, function_type=NEW.function_type, category_type=NEW.category_type, fluid_type=COALESCE(NEW.fluid_type, 0),location_type=NEW.location_type,
			workcat_id=NEW.workcat_id, builtdate=NEW.builtdate,ownercat_id=NEW.ownercat_id, muni_id=NEW.muni_id, streetaxis_id=NEW.streetaxis_id,
			postcode=NEW.postcode, district_id=NEW.district_id, streetaxis2_id=NEW.streetaxis2_id, postcomplement=NEW.postcomplement, postcomplement2=NEW.postcomplement2, postnumber=NEW.postnumber,
			postnumber2=NEW.postnumber2,  descript=NEW.descript, link=NEW.link, verified=NEW.verified,label_x=NEW.label_x,
			label_y=NEW.label_y, label_rotation=NEW.label_rotation,workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan, code=NEW.code, publish=NEW.publish, inventory=NEW.inventory,
			enddate=NEW.enddate, uncertain=NEW.uncertain, expl_id=NEW.expl_id, num_value = NEW.num_value,updated_at=now(), updated_by=current_user, matcat_id=NEW.matcat_id,
			asset_id=NEW.asset_id, pavcat_id=NEW.pavcat_id, parent_id=NEW.parent_id, expl_visibility=NEW.expl_visibility, adate=NEW.adate, adescript=NEW.adescript,
			visitability=NEW.visitability, label_quadrant=NEW.label_quadrant, brand_id=NEW.brand_id, model_id=NEW.model_id, serial_number=NEW.serial_number,
			initoverflowpath=NEW.initoverflowpath, lock_level=NEW.lock_level, is_scadamap=NEW.is_scadamap, registration_date=NEW.registration_date,
			meandering=NEW.meandering, conserv_state=NEW.conserv_state, om_state=NEW.om_state, last_visitdate=NEW.last_visitdate, negative_offset=NEW.negative_offset, drainzone_outfall=NEW.drainzone_outfall, dwfzone_outfall=NEW.dwfzone_outfall, omunit_id=NEW.omunit_id, dma_id=NEW.dma_id, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
			WHERE arc_id=OLD.arc_id;
		END IF;

		-- Update arc_add table
		UPDATE arc_add SET arc_id=NEW.arc_id, result_id = NEW.result_id, max_flow = NEW.max_flow, max_veloc = NEW.max_veloc, mfull_flow = NEW.mfull_flow, mfull_depth = NEW.mfull_depth,
		manning_veloc = NEW.manning_veloc, manning_flow = NEW.manning_flow, dwf_minflow = NEW.dwf_minflow, dwf_maxflow = NEW.dwf_maxflow, dwf_minvel = NEW.dwf_minvel,
		dwf_maxvel = NEW.dwf_maxvel, conduit_capacity = NEW.conduit_capacity
		WHERE arc_id = OLD.arc_id;

		-- child tables fields
		IF v_man_table='man_conduit' THEN

			UPDATE man_conduit SET arc_id=NEW.arc_id, bottom_mat=NEW.bottom_mat, conduit_code=NEW.conduit_code WHERE arc_id=OLD.arc_id;

		ELSIF v_man_table='man_siphon' THEN

			UPDATE man_siphon SET  name=NEW.name, siphon_code=NEW.siphon_code
			WHERE arc_id=OLD.arc_id;

		ELSIF v_man_table='man_waccel' THEN

			UPDATE man_waccel SET  sander_length=NEW.sander_length, sander_depth=NEW.sander_depth, prot_surface=NEW.prot_surface,
			accessibility=NEW.accessibility, name=NEW.name, waccel_code=NEW.waccel_code
			WHERE arc_id=OLD.arc_id;

		ELSIF v_man_table='man_varc' THEN

			UPDATE man_varc SET arc_id=NEW.arc_id
			WHERE arc_id=OLD.arc_id;

		END IF;

		--sander calculation
		IF v_auto_sander IS TRUE THEN
			EXECUTE 'SELECT gw_fct_calculate_sander($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":"'||NEW.node_1||'"}}$$)';
		END IF;

		-- childtable update
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='ARC' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING NEW
					INTO v_new_value_param;

				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING OLD
					INTO v_old_value_param;



				v_childtable_name := 'man_arc_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF (v_new_value_param IS NOT NULL AND v_old_value_param!=v_new_value_param) OR (v_new_value_param IS NOT NULL AND v_old_value_param IS NULL) THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (arc_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (arc_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.arc_id=$1'
							USING NEW.arc_id, v_new_value_param;

					ELSIF v_new_value_param IS NULL AND v_old_value_param IS NOT NULL THEN
						EXECUTE 'UPDATE '||v_childtable_name||' SET '||v_addfields.param_name||' = null WHERE '||v_childtable_name||'.arc_id=$1'
							USING NEW.arc_id;
					END IF;
				END IF;
			END LOOP;
		END IF;

		--update values of related connecs;
		IF NEW.fluid_type != OLD.fluid_type AND v_autoupdate_fluid IS TRUE THEN
			UPDATE connec SET fluid_type = NEW.fluid_type WHERE arc_id = NEW.arc_id;
			UPDATE gully SET fluid_type = NEW.fluid_type WHERE arc_id = NEW.arc_id;
			UPDATE link SET fluid_type = NEW.fluid_type WHERE exit_id = NEW.arc_id;
		END IF;

		IF NEW. expl_id != OLD. expl_id THEN
			UPDATE connec SET expl_id = NEW.expl_id WHERE arc_id = NEW.arc_id;
			UPDATE gully SET expl_id = NEW.expl_id WHERE arc_id = NEW.arc_id;
			UPDATE link SET expl_id = NEW.expl_id WHERE exit_id = NEW.arc_id;
		END IF;

		RETURN NEW;

	 ELSIF TG_OP = 'DELETE' THEN

		EXECUTE 'SELECT gw_fct_getcheckdelete($${"client":{"device":4, "infoType":1, "lang":"ES"},
		"feature":{"id":"'||OLD.arc_id||'","featureType":"ARC"}, "data":{}}$$)';

		-- force plan_psector_force_delete
		SELECT value INTO v_force_delete FROM config_param_user WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;
		UPDATE config_param_user SET value = 'true' WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		DELETE FROM arc WHERE arc_id = OLD.arc_id;

		-- restore plan_psector_force_delete
		UPDATE config_param_user SET value = v_force_delete WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		-- Delete childtable addfields (after or before deletion of arc, doesn't matter)
		v_customfeature = old.arc_type;
		v_arc_id = old.arc_id;

		v_childtable_name := 'man_arc_' || lower(v_customfeature);
		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
			EXECUTE 'DELETE FROM '||v_childtable_name||' WHERE arc_id = '||quote_literal(v_arc_id)||'';
		END IF;

		RETURN NULL;

	 END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

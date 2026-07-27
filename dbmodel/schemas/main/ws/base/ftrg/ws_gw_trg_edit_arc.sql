/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1302

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_arc()
  RETURNS trigger AS
$BODY$
DECLARE
v_inp_table varchar;
v_man_table varchar;
v_sql varchar;
v_code_autofill_bool boolean;
v_count integer;
v_proximity_buffer double precision;
ve_enable_arc_nodes_update boolean;
v_link_path varchar;
v_new_arc_type text;
v_old_arc_type text;
v_customfeature text;
v_addfields record;
v_new_value_param text;
v_old_value_param text;
v_featurecat text;
v_force_delete boolean;
v_autoupdate_fluid boolean;
v_psector integer;
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
	IF v_man_table IN (SELECT id FROM cat_feature) THEN
		v_customfeature:=v_man_table;
		v_man_table:=(SELECT man_table FROM cat_feature_arc c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id=v_man_table);
	END IF;

	v_proximity_buffer = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_feature_buffer_on_mapzone');
	ve_enable_arc_nodes_update = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_arc_enable nodes_update');
	v_autoupdate_fluid = (SELECT value::boolean FROM config_param_system WHERE parameter='edit_connect_autoupdate_fluid');
	v_psector = (SELECT value::integer FROM config_param_user WHERE "parameter"='plan_psector_current' AND cur_user=current_user);
	v_sys_code_autofill := (SELECT (value::json->>'arc')::text FROM config_param_system WHERE parameter = 'edit_sys_code_autofill');

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		IF NEW.arccat_id NOT IN (SELECT id FROM cat_arc WHERE arc_type = NEW.arc_type) AND NEW.arc_type IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	       		"data":{"message":"4464", "function":"1302","parameters":null, "is_process":true}}$$);';
		END IF;
	END IF;

	IF TG_OP = 'INSERT' THEN

		-- setting psector vdefault as visible
		IF NEW.state = 2 THEN
			INSERT INTO selector_psector (psector_id, cur_user) VALUES (v_psector, current_user) ON CONFLICT DO NOTHING;
		END IF;

		-- Arc ID
		IF NEW.arc_id != (SELECT last_value FROM urn_id_seq) OR NEW.arc_id IS NULL THEN
			NEW.arc_id = (SELECT nextval('urn_id_seq'));
		END IF;

		-- Arc catalog ID
		IF (NEW.arccat_id IS NULL) THEN
			IF ((SELECT COUNT(*) FROM cat_arc WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1020", "function":"1302","parameters":null}}$$);';
			END IF;

			-- get vdefault values using config user values
			IF v_customfeature IS NOT NULL THEN
				NEW.arccat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"=lower(concat('feat_',v_customfeature,'_vdefault')) AND "cur_user"="current_user"() LIMIT 1);
			ELSE
				NEW.arccat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_arccat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- get values using proximity
			IF (NEW.arccat_id IS NULL) THEN
				NEW.arccat_id := (SELECT arccat_id from arc WHERE ST_DWithin(NEW.the_geom, arc.the_geom,0.001) LIMIT 1);
			END IF;

			IF (NEW.arccat_id IS NULL) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1088", "function":"1302","parameters":null}}$$);';
			END IF;
		ELSE
			IF (SELECT true from cat_arc where id=NEW.arccat_id) IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3282", "function":"1302","parameters":{"catalog_value":"'||NEW.arccat_id||'"}}}$$);';
			END IF;
		END IF;

		


		 -- Set EPA type
		IF (NEW.epa_type IS NULL) THEN
			NEW.epa_type = 'PIPE';
		END IF;


		-- Exploitation
		IF (NEW.expl_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1110", "function":"1302","parameters":null}}$$);';
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
				"data":{"message":"2012", "function":"1302","parameters":{"feature_id":"'||NEW.arc_id::text||'"}}}$$);';
			END IF;
		END IF;


		-- Sector ID
		IF (NEW.sector_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM sector WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1008", "function":"1302","parameters":null}}$$);';
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
				NEW.sector_id =0;
			END IF;
		END IF;


		-- Dma ID
		IF (NEW.dma_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM dma WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1012", "function":"1302","parameters":null}}$$);';
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

			-- control error when no value
			IF (NEW.dma_id IS NULL) THEN
				NEW.dma_id =0;
			END IF;
		END IF;


		-- Presszone
		IF (NEW.presszone_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM presszone WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"3106", "function":"1302","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.presszone_id IS NULL) THEN
				NEW.presszone_id := (SELECT "value" FROM config_param_user WHERE "parameter"='presszone_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.presszone_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM presszone WHERE ST_DWithin(NEW.the_geom, presszone.the_geom,0.001) AND active IS TRUE ;
				IF v_count = 1 THEN
					NEW.presszone_id = (SELECT presszone_id FROM presszone WHERE ST_DWithin(NEW.the_geom, presszone.the_geom,0.001) AND active IS TRUE  LIMIT 1);
				ELSE
					NEW.presszone_id =(SELECT presszone_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- control error when no value
			IF (NEW.presszone_id IS NULL) THEN
				NEW.presszone_id =0;
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

		-- Code
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		SELECT code_autofill, cat_feature.id
		INTO v_code_autofill_bool, v_featurecat
		FROM cat_feature
		JOIN cat_arc ON cat_feature.id = cat_arc.arc_type
		WHERE cat_arc.id = NEW.arccat_id;

		IF NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('feature', v_featurecat, json_strip_nulls(row_to_json(NEW)::json));

			IF NEW.code IS NULL AND v_code_autofill_bool THEN
				NEW.code := NEW.arc_id;
			END IF;
		END IF;

		IF NEW.sys_code IS NOT NULL AND v_sys_code_autofill NOT IN ('false', 'none') THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4678", "function":"1302", "is_process":true}}$$);';
		END IF;

		--Sys_code (uuid | code | none)
		IF v_sys_code_autofill IN ('uuid', 'true') THEN
			NEW.sys_code := gen_random_uuid();
		ELSIF v_sys_code_autofill = 'code' THEN
			NEW.sys_code := NEW.code;
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

		-- Builtdate
		IF (NEW.builtdate IS NULL) THEN
			NEW.builtdate :=(SELECT "value" FROM config_param_user WHERE "parameter"='edit_builtdate_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			IF (NEW.builtdate IS NULL) AND (SELECT value::boolean FROM config_param_system WHERE parameter='edit_feature_auto_builtdate') IS TRUE THEN
				NEW.builtdate :=date(now());
			END IF;
		END IF;

		-- Verified
		IF (NEW.verified IS NULL) THEN
			NEW.verified := (SELECT "value"::INTEGER FROM config_param_user WHERE "parameter"='edit_verified_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		-- LINK
		IF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=NEW.arc_id;
		END IF;

		v_featurecat = (SELECT arc_type FROM cat_arc WHERE id = NEW.arccat_id);

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
		
		-- uuid random
		IF NEW.uuid is null then
			NEW.uuid = gen_random_uuid();
		END IF;

		-- FEATURE INSERT
		INSERT INTO arc (arc_id, code, sys_code, datasource, arccat_id, epa_type, sector_id, "state", state_type, annotation, observ,"comment",custom_length,dma_id, dqa_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type,
					workcat_id, workcat_id_end, workcat_id_plan, builtdate,enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement,
					streetaxis2_id,postnumber2, postcomplement2,descript,link,verified,the_geom,label_x,label_y,label_rotation,  publish, inventory, expl_id, num_value,
					adate, adescript, updated_at, updated_by, asset_id, pavcat_id, om_state, conserv_state, parent_id,expl_visibility, brand_id, model_id, serial_number, label_quadrant, lock_level, is_scadamap, uuid, supplyzone_id, omzone_id, minsector_id, dataquality, dataquality_obs)
					VALUES (NEW.arc_id, NEW.code, NEW.sys_code, NEW.datasource, NEW.arccat_id, NEW.epa_type, COALESCE(NEW.sector_id, 0), NEW."state", NEW.state_type, NEW.annotation, NEW.observ, NEW.comment, NEW.custom_length,COALESCE(NEW.dma_id, 0), COALESCE(NEW.dqa_id, 0), COALESCE(NEW.presszone_id, 0),
					NEW.soilcat_id, NEW.function_type, NEW.category_type, NEW.fluid_type, NEW.location_type, NEW.workcat_id, NEW.workcat_id_end, NEW.workcat_id_plan, NEW.builtdate,NEW.enddate, NEW.ownercat_id,
					COALESCE(NEW.muni_id, 0), NEW.postcode, NEW.district_id,NEW.streetaxis_id,NEW.postnumber, NEW.postcomplement, NEW.streetaxis2_id, NEW.postnumber2, NEW.postcomplement2, NEW.descript,NEW.link, NEW.verified,
					NEW.the_geom,NEW.label_x,NEW.label_y,NEW.label_rotation, NEW.publish, NEW.inventory, COALESCE(NEW.expl_id, 0), NEW.num_value,
					NEW.adate, NEW.adescript, NEW.updated_at, NEW.updated_by, NEW.asset_id, NEW.pavcat_id, NEW.om_state, NEW.conserv_state,
					NEW.parent_id, NEW.expl_visibility, NEW.brand_id, NEW.model_id, NEW.serial_number, NEW.label_quadrant, NEW.lock_level, NEW.is_scadamap, NEW.uuid, COALESCE(NEW.supplyzone_id, 0), COALESCE(NEW.omzone_id, 0), COALESCE(NEW.minsector_id, 0), NEW.dataquality, NEW.dataquality_obs);

		-- Insert into arc_add table
		INSERT INTO arc_add (arc_id, result_id, flow_max, flow_min, flow_avg, vel_max, vel_min, vel_avg, tot_headloss_max, tot_headloss_min, mincut_connecs, mincut_hydrometers,
		mincut_length, mincut_watervol, mincut_criticality, hydraulic_criticality, pipe_capacity, mincut_impact_topo, mincut_impact_hydro)
		VALUES (NEW.arc_id, NEW.result_id, NEW.flow_max, NEW.flow_min, NEW.flow_avg, NEW.vel_max, NEW.vel_min, NEW.vel_avg,
		NEW.tot_headloss_max, NEW.tot_headloss_min, NEW.mincut_connecs, NEW.mincut_hydrometers, NEW.mincut_length, NEW.mincut_watervol, NEW.mincut_criticality, NEW.hydraulic_criticality, NEW.pipe_capacity, NEW.mincut_impact_topo, NEW.mincut_impact_hydro);

		-- this overwrites triger topocontrol arc values (triggered before insertion) just in that moment: In order to make more profilactic this issue only will be overwrited in case of NEW.node_* not nulls
		IF ve_enable_arc_nodes_update IS TRUE THEN
			IF NEW.node_1 IS NOT NULL THEN
				UPDATE arc SET node_1=NEW.node_1 WHERE arc_id=NEW.arc_id;
			END IF;
			IF NEW.node_2 IS NOT NULL THEN
				UPDATE arc SET node_2=NEW.node_2 WHERE arc_id=NEW.arc_id;
			END IF;
		END IF;


		-- MAN INSERT
		IF v_man_table='man_pipe' THEN
				INSERT INTO man_pipe (arc_id) VALUES (NEW.arc_id);

		ELSIF v_man_table='man_varc' THEN
				INSERT INTO man_varc (arc_id) VALUES (NEW.arc_id);

		ELSIF v_man_table='parent' THEN
			v_man_table := (SELECT man_table FROM cat_feature_arc c	JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id
			JOIN cat_arc ON c.id = cat_arc.arc_type WHERE cat_arc.id=NEW.arccat_id);
        	IF v_man_table IS NOT NULL THEN
            	v_sql:= 'INSERT INTO '||v_man_table||' (arc_id) VALUES ('||quote_literal(NEW.arc_id)||')';
           		EXECUTE v_sql;
      		END IF;
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

        -- EPA INSERT
        IF (NEW.epa_type = 'PIPE') THEN
		v_inp_table:= 'inp_pipe';

	ELSIF (NEW.epa_type = 'VIRTUALPUMP') THEN
	 	v_inp_table:= 'inp_virtualpump';

	ELSIF (NEW.epa_type = 'VIRTUALVALVE') THEN
		v_inp_table:= 'inp_virtualvalve';

        END IF;

       	IF v_inp_table IS NOT NULL THEN
			v_sql:= 'INSERT INTO '||v_inp_table||' (arc_id) VALUES ('||quote_literal(NEW.arc_id)||')';
	        EXECUTE v_sql;
       	END IF;

		--in case a project is dhc, insert cable
		IF (SELECT value FROM config_param_system WHERE parameter='dhc_plugin_version') is not null then
			IF (SELECT value::boolean FROM config_param_user WHERE parameter='dhc_edit_insert_cable'
			AND cur_user=current_user) is true AND (SELECT json_extract_path_text(value::json,'cableFeaturecat')
				FROM config_param_system WHERE parameter='dhc_edit_insert_cable') != NEW.arc_type THEN
					EXECUTE 'SELECT dhc_fct_edit_cable($${"client":{"device":4, "infoType":1, "lang":"ES"},
					"form":{},"feature":{"tableName":"ve_node", "featureType":"NODE", "id":[]}, 
					"data":{"filterFields":{}, "pageInfo":{},"arcId":"'||NEW.arc_id::text||'", 
					"arcGeom":"'||NEW.the_geom::text||'", "muniId":"'||NEW.muni_id::text||'", "explId":"'||NEW.expl_id::text||'",
					"state":"'||NEW.state::text||'","stateType":"'||NEW.state_type::text||'", "arcId":"'||NEW.arc_id||'" }}$$);';
			END IF;
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

    		-- this overwrites triger topocontrol arc values (triggered before insertion) just in that moment: In order to make more profilactic this issue only will be overwrited in case of NEW.node_* not nulls
		IF ve_enable_arc_nodes_update IS TRUE THEN
			IF NEW.node_1 IS NOT NULL THEN
				UPDATE arc SET node_1=NEW.node_1 WHERE arc_id=NEW.arc_id;
			END IF;
			IF NEW.node_2 IS NOT NULL THEN
				UPDATE arc SET node_2=NEW.node_2 WHERE arc_id=NEW.arc_id;
			END IF;
		END IF;

		-- epa type
		IF (NEW.epa_type != OLD.epa_type) THEN

			-- delete from old inp table
			IF (OLD.epa_type = 'PIPE') THEN
				v_inp_table:= 'inp_pipe';
			ELSIF (OLD.epa_type = 'VIRTUALVALVE') THEN
				v_inp_table:= 'inp_virtualvalve';
			ELSIF (OLD.epa_type = 'VIRTUALPUMP') THEN
				v_inp_table:= 'inp_virtualpump';
			END IF;
			IF v_inp_table IS NOT NULL THEN
				v_sql:= 'DELETE FROM '||v_inp_table||' WHERE arc_id = '||quote_literal(OLD.arc_id);
				EXECUTE v_sql;
			END IF;

			v_inp_table := NULL;

			-- insert into new inp table
			IF (NEW.epa_type = 'PIPE') THEN
				INSERT INTO inp_pipe VALUES (NEW.arc_id) ON CONFLICT (arc_id) DO NOTHING;
			ELSIF (NEW.epa_type = 'VIRTUALVALVE') THEN
				INSERT INTO inp_virtualvalve (arc_id, status) VALUES (NEW.arc_id, 'ACTIVE') ON CONFLICT (arc_id) DO NOTHING;
			ELSIF (NEW.epa_type = 'VIRTUALPUMP') THEN
				INSERT INTO inp_virtualpump (arc_id, status) VALUES (NEW.arc_id, 'ACTIVE') ON CONFLICT (arc_id) DO NOTHING;
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
				"data":{"message":"3036", "function":"1318","parameters":{"state_id":"'||NEW.state::text||'"}}}$$);';
		END IF;

		-- The geom
		IF st_orderingequals(NEW.the_geom, OLD.the_geom) IS FALSE OR NEW.node_1 IS NULL OR NEW.node_2 IS NULL THEN
			UPDATE arc SET the_geom=NEW.the_geom WHERE arc_id = OLD.arc_id;
		END IF;

		--link_path
		SELECT link_path INTO v_link_path FROM cat_feature JOIN cat_arc ON cat_arc.arc_type=cat_feature.id WHERE cat_arc.id=NEW.arccat_id;

		IF v_link_path IS NOT NULL THEN
			NEW.link = replace(NEW.link, v_link_path,'');
		END IF;

		 -- Arc type for parent view
		IF v_man_table='parent' THEN
	    	IF (NEW.arccat_id != OLD.arccat_id) THEN
				v_new_arc_type= (SELECT feature_class FROM cat_feature JOIN cat_arc ON cat_feature.id=arc_type where cat_arc.id=NEW.arccat_id);
				v_old_arc_type= (SELECT feature_class FROM cat_feature JOIN cat_arc ON cat_feature.id=arc_type where cat_arc.id=OLD.arccat_id);
				IF v_new_arc_type != v_old_arc_type THEN
					v_sql='INSERT INTO man_'||lower(v_new_arc_type)||' (arc_id) VALUES ('||NEW.arc_id||')';
					EXECUTE v_sql;
					v_sql='DELETE FROM man_'||lower(v_old_arc_type)||' WHERE arc_id='||quote_literal(OLD.arc_id);
					EXECUTE v_sql;
				END IF;
			END IF;
		END IF;

		UPDATE arc
		SET code=NEW.code, sys_code=NEW.sys_code, datasource=NEW.datasource, arccat_id=NEW.arccat_id, epa_type=NEW.epa_type, sector_id=NEW.sector_id,  state_type=NEW.state_type, annotation= NEW.annotation, "observ"=NEW.observ,
				"comment"=NEW.comment, custom_length=NEW.custom_length, dma_id=NEW.dma_id, dqa_id=NEW.dqa_id, presszone_id=NEW.presszone_id, soilcat_id=NEW.soilcat_id, function_type=NEW.function_type,
				category_type=NEW.category_type, fluid_type=NEW.fluid_type, location_type=NEW.location_type, workcat_id=NEW.workcat_id, workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan,
				builtdate=NEW.builtdate, enddate=NEW.enddate, ownercat_id=NEW.ownercat_id, muni_id=NEW.muni_id, streetaxis_id=NEW.streetaxis_id,
				streetaxis2_id=NEW.streetaxis2_id,postcode=NEW.postcode, district_id = NEW.district_id, postnumber=NEW.postnumber, postnumber2=NEW.postnumber2,descript=NEW.descript, verified=NEW.verified,
				label_x=NEW.label_x, postcomplement=NEW.postcomplement, postcomplement2=NEW.postcomplement2,label_y=NEW.label_y,label_rotation=NEW.label_rotation, publish=NEW.publish, inventory=NEW.inventory,
				expl_id=NEW.expl_id,num_value=NEW.num_value, link=NEW.link, updated_at=now(), updated_by=current_user,
				adate=NEW.adate, adescript=NEW.adescript, asset_id=NEW.asset_id, pavcat_id=NEW.pavcat_id,
				om_state=NEW.om_state, conserv_state=NEW.conserv_state, parent_id = NEW.parent_id,expl_visibility =NEW.expl_visibility, brand_id=NEW.brand_id, model_id=NEW.model_id, serial_number=NEW.serial_number,
				label_quadrant=NEW.label_quadrant, lock_level=NEW.lock_level, is_scadamap=NEW.is_scadamap, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
				WHERE arc_id=OLD.arc_id;

		-- update arc_add table
		UPDATE arc_add SET result_id = NEW.result_id, flow_max = NEW.flow_max, flow_min = NEW.flow_min, flow_avg = NEW.flow_avg, vel_max = NEW.vel_max,
		vel_min = NEW.vel_min, vel_avg = NEW.vel_avg, tot_headloss_max = NEW.tot_headloss_max, tot_headloss_min = NEW.tot_headloss_min, mincut_connecs = NEW.mincut_connecs,
		mincut_hydrometers = NEW.mincut_hydrometers, mincut_length = NEW.mincut_length, mincut_watervol = NEW.mincut_watervol, mincut_criticality = NEW.mincut_criticality, hydraulic_criticality = NEW.hydraulic_criticality, pipe_capacity = NEW.pipe_capacity,
		mincut_impact_topo = NEW.mincut_impact_topo, mincut_impact_hydro = NEW.mincut_impact_hydro
		WHERE arc_id = OLD.arc_id;

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
			IF NEW.fluid_type not in (SELECT fluid_type FROM man_type_fluid WHERE 'CONNEC' = ANY(feature_type)) AND NEW.fluid_type IS NOT NULL THEN
				INSERT INTO man_type_fluid (fluid_type, feature_type) VALUES (NEW.fluid_type, '{CONNEC}') ON CONFLICT (fluid_type, feature_type) DO NOTHING;
			END IF;
			UPDATE connec SET fluid_type = NEW.fluid_type WHERE arc_id = NEW.arc_id;
			UPDATE link SET fluid_type = NEW.fluid_type WHERE exit_id = NEW.arc_id;
		END IF;

		IF NEW. expl_id != OLD. expl_id THEN
			UPDATE connec SET expl_id = NEW.expl_id WHERE arc_id = NEW.arc_id;
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

		-- Delete childtable addfields (after or before deletion of node, doesn't matter)

		v_customfeature = old.arc_type;
		v_arc_id = old.arc_id;

		v_childtable_name := 'man_arc_' || lower(v_customfeature);
		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
	   		EXECUTE 'DELETE FROM '||v_childtable_name||' WHERE arc_id = '||quote_literal(v_arc_id)||'';
		END IF;

  	-- delete from arc_add table
		DELETE FROM arc_add WHERE arc_id = OLD.arc_id;

		RETURN NULL;
	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

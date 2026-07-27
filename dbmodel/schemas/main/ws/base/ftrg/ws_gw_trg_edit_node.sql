/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION NODE: 1320


CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_node()
  RETURNS trigger AS
$BODY$
DECLARE
v_srid integer;
v_inp_table varchar;
v_man_table varchar;
v_type_man_table varchar;
v_code_autofill_bool boolean;
v_node_id text;
v_tablename varchar;
v_pol_id varchar;
v_sql text;
v_count integer;
v_proximity_buffer double precision;
ve_node_reduction_auto_d1d2 boolean;
v_link_path varchar;
v_insert_double_geom boolean;
v_double_geom_buffer double precision;
v_new_node_type text;
v_old_node_type text;
v_addfields record;
v_new_value_param text;
v_old_value_param text;
v_customfeature text;
v_featurecat text;
v_new_epatable text;
v_old_epatable text;
v_new_epatype text;
v_sys_type text;
v_force_delete boolean;
v_feature_class text;
v_featurecat_id text;
v_psector integer;
v_auto_streetvalues_status boolean;
v_auto_streetvalues_buffer integer;
v_auto_streetvalues_field text;
v_trace_featuregeom boolean;

-- dynamic mapzones strategy
v_isdma boolean = false;
v_issector boolean = false;
v_ispresszone boolean = false;
v_isautoinsertdma boolean = false;
v_isautoinsertsector boolean = false;
v_isautoinsertpresszone boolean = false;

-- vdefault values for epa-valves
v_epavdef json;

-- automatic_man2inp_values
v_man_view text;
v_input json;


v_childtable_name text;
v_schemaname text;

v_dist_xlab numeric;
v_dist_ylab numeric;
v_label_point public.geometry;
v_rot1 numeric;
v_rot2 numeric;
v_geom public.geometry;
v_cur_rotation numeric;
v_cur_quadrant TEXT;
v_new_lab_position public.geometry;
v_dist_sign numeric;
v_label_dist numeric;
v_sys_code_autofill text;

v_district_ids _int4;



BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	v_man_table:= TG_ARGV[0];
    v_schemaname:= TG_TABLE_SCHEMA;

	-- get dynamic mapzones status
	v_isdma := (SELECT value::json->>'DMA' FROM config_param_system WHERE parameter = 'utils_graphanalytics_status');
	v_issector:= (SELECT value::json->>'SECTOR' FROM config_param_system WHERE parameter = 'utils_graphanalytics_status');
	v_ispresszone:= (SELECT value::json->>'PRESSZONE' FROM config_param_system WHERE parameter = 'utils_graphanalytics_status');

	-- get automatic insert for mapzone
	v_isautoinsertsector:= (SELECT value::json->>'SECTOR' FROM config_param_system WHERE parameter = 'edit_mapzone_automatic_insert');
	v_isautoinsertdma := (SELECT value::json->>'DMA' FROM config_param_system WHERE parameter = 'edit_mapzones_automatic_insert');
	v_isautoinsertpresszone:= (SELECT value::json->>'PRESSZONE' FROM config_param_system WHERE parameter = 'edit_mapzones_automatic_insert');
	v_psector = (SELECT value::integer FROM config_param_user WHERE "parameter"='plan_psector_current' AND cur_user=current_user);

	--modify values for custom view inserts
	IF v_man_table IN (SELECT id FROM cat_feature WHERE feature_type = 'NODE') THEN
		v_customfeature:=v_man_table;
		v_man_table:=(SELECT man_table FROM cat_feature_node c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id  WHERE c.id=v_man_table);
	END IF;

	v_type_man_table=v_man_table;

	--Get data from config table
	v_proximity_buffer = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_feature_buffer_on_mapzone');
	ve_node_reduction_auto_d1d2 = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_node_reduction_auto_d1d2');
	v_auto_streetvalues_status := (SELECT (value::json->>'status')::boolean FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_buffer := (SELECT (value::json->>'buffer')::integer FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_field := (SELECT (value::json->>'field')::text FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_sys_code_autofill := (SELECT (value::json->>'node')::text FROM config_param_system WHERE parameter = 'edit_sys_code_autofill');
	v_srid = (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1);

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		-- man2inp_values
		SELECT child_layer, feature_class INTO v_man_view, v_feature_class FROM cat_feature f JOIN cat_node c ON c.node_type = f.id WHERE c.id = NEW.nodecat_id;
		v_input = concat('{"feature":{"type":"node", "childLayer":"',v_man_view,'", "id":"',NEW.node_id,'"}}');
		IF NEW.nodecat_id NOT IN (SELECT id FROM cat_node WHERE node_type = NEW.node_type) AND NEW.node_type IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	       		"data":{"message":"4464", "function":"1320","parameters":null, "is_process":true}}$$);';
		END IF;
	END IF;

	-- Control insertions ID
	IF TG_OP = 'INSERT' THEN

		-- setting psector vdefault as visible
		IF NEW.state = 2 THEN
			INSERT INTO selector_psector (psector_id, cur_user) VALUES (v_psector, current_user) ON CONFLICT DO NOTHING;
		END IF;

		-- Node ID
		IF NEW.node_id != (SELECT last_value FROM urn_id_seq) OR NEW.node_id IS NULL THEN
			NEW.node_id = (SELECT nextval('urn_id_seq'));
		END IF;

		v_input = concat('{"feature":{"type":"node", "childLayer":"',v_man_view,'", "id":"',NEW.node_id,'"}}');

		-- Node Catalog ID
		IF (NEW.nodecat_id IS NULL) THEN
			IF ((SELECT COUNT(*) FROM cat_node WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1006", "function":"1320","parameters":null}}$$);';
			END IF;

			IF v_customfeature IS NOT NULL THEN
				NEW.nodecat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"=lower(concat(v_customfeature,'_vdefault')) AND "cur_user"="current_user"() LIMIT 1);
			ELSE
				NEW.nodecat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_nodecat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			IF (NEW.nodecat_id IS NULL) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1090", "function":"1320","parameters":null}}$$);';
			END IF;
		ELSE
			IF (SELECT true from cat_node where id=NEW.nodecat_id) IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3282", "function":"1320","parameters":{"catalog_value":"'||NEW.nodecat_id||'"}}}$$);';
			END IF;
		END IF;


		-- Epa type
		IF NEW.epa_type IN ('VALVE', 'PUMP') THEN
			IF NEW.epa_type <> v_feature_class THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3266", "function":"1320","parameters":null, "is_process":true}}$$)';
			END IF;
		ELSIF NEW.epa_type IS NULL THEN
			NEW.epa_type:= (SELECT epa_default FROM cat_node JOIN cat_feature_node ON cat_feature_node.id=cat_node.node_type WHERE cat_node.id=NEW.nodecat_id LIMIT 1)::text;
		END IF;


		-- Exploitation
		IF (NEW.expl_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1110", "function":"1320","parameters":null}}$$);';
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
				"data":{"message":"2012", "function":"1320","parameters":{"feature_id":"'||NEW.node_id::text||'"}}}$$);';
			END IF;
		END IF;

		-- Sector
		IF (NEW.sector_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM sector WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1008", "function":"1320","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.sector_id IS NULL) THEN
				NEW.sector_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_sector_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.sector_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM sector WHERE ST_DWithin(NEW.the_geom, sector.the_geom,0.001) AND active IS TRUE ;
				IF v_count = 1 THEN
					NEW.sector_id = (SELECT sector_id FROM sector WHERE ST_DWithin(NEW.the_geom, sector.the_geom,0.001) AND active IS TRUE LIMIT 1);
				ELSE
					NEW.sector_id =(SELECT sector_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, ve_arc.the_geom, v_proximity_buffer)
					order by ST_Distance (NEW.the_geom, ve_arc.the_geom) LIMIT 1);
				END IF;
			END IF;

			-- force cero values always - undefined
			IF (NEW.sector_id IS NULL) THEN
				NEW.sector_id := 0;
			END IF;
		END IF;


		-- Dma
		IF (NEW.dma_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF (SELECT COUNT(*) FROM dma WHERE active IS TRUE ) = 0 THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1012", "function":"1320","parameters":null}}$$);';
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

			-- force cero values always - undefined
			IF (NEW.dma_id IS NULL) THEN
				NEW.dma_id := 0;
			END IF;
		END IF;

		-- Presszone
		IF (NEW.presszone_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM presszone WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3106", "function":"1320","parameters":null}}$$);';
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

			-- force cero values always - undefined
			IF (NEW.presszone_id IS NULL) THEN
				NEW.presszone_id := 0;
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
				SELECT count(*) INTO v_count FROM v_municipality WHERE ST_DWithin(NEW.the_geom, v_municipality.the_geom,0.001) AND active IS TRUE;
				IF v_count = 1 THEN
					NEW.muni_id = (SELECT muni_id FROM v_municipality WHERE ST_DWithin(NEW.the_geom, v_municipality.the_geom,0.001)
					AND active IS TRUE LIMIT 1);
				ELSIF v_count > 1 THEN
					SELECT array_agg(muni_id ORDER BY ST_Distance(NEW.the_geom, v_municipality.the_geom), muni_id)
					INTO NEW.muni_visibility
					FROM v_municipality
					WHERE ST_DWithin(NEW.the_geom, v_municipality.the_geom,0.001) AND active IS TRUE;

					NEW.muni_id := NEW.muni_visibility[1];
					NEW.muni_visibility := NEW.muni_visibility[2:array_length(NEW.muni_visibility, 1)];
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
			"data":{"message":"3036", "function":"1320","parameters":{"state_id":"'||v_sql::text||'"}}}$$);';

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
		JOIN cat_node ON cat_feature.id = cat_node.node_type
		WHERE cat_node.id = NEW.nodecat_id;

		IF NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('feature', v_featurecat, json_strip_nulls(row_to_json(NEW)::json));

			IF NEW.code IS NULL AND v_code_autofill_bool THEN
				NEW.code := NEW.node_id;
			END IF;
		END IF;

		IF NEW.sys_code IS NOT NULL AND v_sys_code_autofill NOT IN ('false', 'none') THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4678", "function":"1320"}}$$);';
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
				NEW.streetaxis_id := (select ve_streetaxis.id from ve_streetaxis
								join node on ST_DWithin(NEW.the_geom, ve_streetaxis.the_geom, v_auto_streetvalues_buffer)
								order by ST_Distance(NEW.the_geom, ve_streetaxis.the_geom) LIMIT 1);
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

		-- Parent id
		SELECT pol_id INTO v_pol_id FROM polygon JOIN cat_feature ON cat_feature.id=polygon.featurecat_id
		WHERE ST_DWithin(NEW.the_geom, polygon.the_geom, 0.001) LIMIT 1;

		IF v_pol_id IS NOT NULL THEN
			v_sql:= 'SELECT feature_id FROM polygon WHERE pol_id::bigint='||v_pol_id||' LIMIT 1';
			EXECUTE v_sql INTO v_node_id;
			NEW.parent_id=v_node_id;
		END IF;

		-- LINK
		--google maps style
		IF (SELECT (value::json->>'google_maps')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=CONCAT ('https://www.google.com/maps/place/',(ST_Y(ST_transform(NEW.the_geom,4326))),'N+',(ST_X(ST_transform(NEW.the_geom,4326))),'E');
		--fid style
		ELSIF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=NEW.node_id;
		END IF;

		v_featurecat = (SELECT node_type FROM cat_node WHERE id = NEW.nodecat_id);

		--arc_id
		IF NEW.arc_id IS NULL AND (SELECT isarcdivide FROM cat_feature_node WHERE id=v_featurecat) IS FALSE THEN
			NEW.arc_id = (SELECT arc_id FROM ve_arc WHERE ST_DWithin(NEW.the_geom, the_geom, 0.1) LIMIT 1);
		END IF;

		--Location type
		IF NEW.location_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_location_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'featureval_location_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.location_type IS NULL THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_node_location_vdefault' AND cur_user = current_user);
		END IF;

		--Fluid type
		IF NEW.fluid_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_fluid_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_fluid_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.fluid_type IS NULL THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_node_fluid_vdefault' AND cur_user = current_user);
		END IF;

		--Category type
		IF NEW.category_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_category_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_category_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.category_type IS NULL THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_node_category_vdefault' AND cur_user = current_user);
		END IF;

		--Function type
		IF NEW.function_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_function_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_function_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.function_type IS NULL THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'node_function_vdefault' AND cur_user = current_user);
		END IF;

		--top_elev from raster
		IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
		AND (NEW.top_elev IS NULL) AND
		(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_insert_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
			NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
				(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1) LIMIT 1);
		END IF;

		-- uuid random
		IF NEW.uuid is null then
			NEW.uuid = gen_random_uuid();
		END IF;

		-- FEATURE INSERT
		INSERT INTO node (node_id, code, sys_code, top_elev, custom_top_elev, datasource, depth, nodecat_id, epa_type, sector_id, arc_id, parent_id, state, state_type, annotation, observ,comment, dma_id, dqa_id, presszone_id,
		soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id,streetaxis_id,
		streetaxis2_id, postcode, postnumber, postnumber2, postcomplement, district_id,	postcomplement2, descript, link, rotation,verified,label_x,label_y,label_rotation,
		expl_id, publish, inventory, the_geom, hemisphere, num_value, adate, adescript, accessibility, updated_at, updated_by, asset_id,
		om_state, conserv_state, access_type, placement_type, expl_visibility, brand_id, model_id, serial_number, label_quadrant, pavcat_id, lock_level, is_scadamap, uuid, minsector_id,
		supplyzone_id, omzone_id, dataquality, dataquality_obs)
		VALUES (NEW.node_id, NEW.code, NEW.sys_code, NEW.top_elev, NEW.custom_top_elev, NEW.datasource, NEW.depth, NEW.nodecat_id, NEW.epa_type, NEW.sector_id, NEW.arc_id, NEW.parent_id, NEW.state, NEW.state_type, NEW.annotation, NEW.observ,
		NEW.comment, COALESCE(NEW.dma_id, 0), COALESCE(NEW.dqa_id, 0), COALESCE(NEW.presszone_id, 0), NEW.soilcat_id, NEW.function_type, NEW.category_type, NEW.fluid_type, NEW.location_type,NEW.workcat_id, NEW.workcat_id_end, NEW.workcat_id_plan,
		NEW.builtdate, NEW.enddate, NEW.ownercat_id, NEW.muni_id, NEW.streetaxis_id, NEW.streetaxis2_id, NEW.postcode, NEW.postnumber ,NEW.postnumber2, NEW.postcomplement, NEW.district_id,
		NEW.postcomplement2, NEW.descript, NEW.link, NEW.rotation, NEW.verified,NEW.label_x,NEW.label_y,NEW.label_rotation,
		NEW.expl_id, NEW.publish, NEW.inventory, NEW.the_geom,  NEW.hemisphere, NEW.num_value,
		NEW.adate, NEW.adescript, NEW.accessibility, NEW.updated_at, NEW.updated_by, NEW.asset_id,
		NEW.om_state, NEW.conserv_state, NEW.access_type, NEW.placement_type, NEW.expl_visibility, NEW.brand_id, NEW.model_id, NEW.serial_number, NEW.label_quadrant, NEW.pavcat_id, NEW.lock_level, NEW.is_scadamap, NEW.uuid,
		COALESCE(NEW.minsector_id, 0), COALESCE(NEW.supplyzone_id, 0), COALESCE(NEW.omzone_id, 0), NEW.dataquality, NEW.dataquality_obs);


		-- Insert into node_add
		INSERT INTO node_add (node_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, result_id)
		VALUES (NEW.node_id, NEW.demand_max, NEW.demand_min, NEW.demand_avg, NEW.press_max, NEW.press_min, NEW.press_avg, NEW.head_max, NEW.head_min, NEW.head_avg, NEW.quality_max, NEW.quality_min, NEW.quality_avg, NEW.result_id);

		-- Insert into visibility tables
		IF NEW.sector_visibility IS NOT NULL THEN
		    INSERT INTO node_x_sector_visibility (node_id, sector_id)
		    SELECT NEW.node_id, unnest(NEW.sector_visibility);
		END IF;

		IF NEW.muni_visibility IS NOT NULL THEN
		    INSERT INTO node_x_municipality_visibility (node_id, muni_id)
		    SELECT NEW.node_id, unnest(NEW.muni_visibility);
		END IF;

		SELECT feature_class, cat_feature.id INTO v_feature_class, v_featurecat_id FROM cat_feature
		JOIN cat_node ON cat_feature.id=node_type where cat_node.id=NEW.nodecat_id;

		EXECUTE 'SELECT json_extract_path_text(double_geom,''activated'')::boolean, json_extract_path_text(double_geom,''value'')
		FROM cat_feature_node WHERE id='||quote_literal(v_featurecat_id)||''
		INTO v_insert_double_geom, v_double_geom_buffer;

		IF (v_insert_double_geom IS TRUE) THEN

				IF (v_pol_id IS NULL) THEN
					v_pol_id:= (SELECT nextval('pol_pol_id_seq'));
				END IF;

				INSERT INTO polygon(pol_id, sys_type, the_geom, featurecat_id, feature_id, state)
				VALUES (v_pol_id, v_feature_class, (SELECT ST_Multi(ST_Envelope(ST_Buffer(node.the_geom,v_double_geom_buffer)))
				from node where node_id=NEW.node_id), v_featurecat_id, NEW.node_id, NEW.state);
		END IF;


		IF v_man_table='man_tank' THEN
			INSERT INTO man_tank (node_id, vmax, vutil, area, chlorination, name, hmax, automated, length, width, shape, fence_type, fence_length, inlet_arc, invert_level, vnom)
			VALUES (NEW.node_id, NEW.vmax, NEW.vutil, NEW.area,NEW.chlorination, NEW.name, NEW.hmax, NEW.automated, NEW.length, NEW.width, COALESCE(NEW.shape, 0), NEW.fence_type, NEW.fence_length, NEW.inlet_arc, NEW.invert_level, NEW.vnom);

		ELSIF v_man_table='man_hydrant' THEN
			INSERT INTO man_hydrant (node_id, fire_code, communication, valve, geom1, geom2, customer_code, hydrant_type, security_cover)
			VALUES (NEW.node_id, NEW.fire_code, NEW.communication, NEW.valve, NEW.geom1, NEW.geom2, NEW.customer_code, NEW.hydrant_type, NEW.security_cover);

		ELSIF v_man_table='man_junction' THEN
			INSERT INTO man_junction (node_id) VALUES(NEW.node_id);

		ELSIF v_man_table='man_pump' THEN
				INSERT INTO man_pump (node_id, max_flow, min_flow, nom_flow, power, pressure_exit, elev_height, name, pump_number, to_arc, pump_type, engine_type)
				VALUES(NEW.node_id, NEW.max_flow, NEW.min_flow, NEW.nom_flow, NEW.power, NEW.pressure_exit, NEW.elev_height, NEW.name, NEW.pump_number, NEW.to_arc, NEW.pump_type, NEW.engine_type);

		ELSIF v_man_table='man_reduction' THEN

			IF ve_node_reduction_auto_d1d2 = 'TRUE' THEN
				IF (NEW.diam1 IS NULL) THEN
					NEW.diam1=(SELECT dnom FROM cat_node WHERE id=NEW.nodecat_id);
				END IF;
				IF (NEW.diam2 IS NULL) THEN
					NEW.diam2=(SELECT dint FROM cat_node WHERE id=NEW.nodecat_id);
				END IF;
			END IF;

			INSERT INTO man_reduction (node_id,diam1,diam2) VALUES(NEW.node_id,NEW.diam1, NEW.diam2);

		ELSIF v_man_table='man_valve' THEN
			INSERT INTO man_valve (node_id,closed, broken, buried,irrigation_indicator,pressure_entry, pressure_exit, depth_valveshaft,regulator_situation, regulator_location, regulator_observ,
			lin_meters, exit_type,exit_code,drive_type, cat_valve2, ordinarystatus, shutter, brand2, model2, valve_type, to_arc, automated, connection_type, flowsetting, turns_count)
			VALUES (NEW.node_id, NEW.closed, NEW.broken, NEW.buried, NEW.irrigation_indicator, NEW.pressure_entry, NEW.pressure_exit, NEW.depth_valveshaft, NEW.regulator_situation,
			NEW.regulator_location, NEW.regulator_observ, NEW.lin_meters, NEW.exit_type, NEW.exit_code, NEW.drive_type, NEW.cat_valve2, NEW.ordinarystatus,
			NEW.shutter, NEW.brand2, NEW.model2, NEW.valve_type, NEW.to_arc, NEW.automated, COALESCE(NEW.connection_type, 0), NEW.flowsetting, NEW.turns_count);

		ELSIF v_man_table='man_manhole' THEN
			INSERT INTO man_manhole (node_id, name) VALUES(NEW.node_id, NEW.name);

		ELSIF v_man_table='man_meter' THEN
			INSERT INTO man_meter (node_id, real_press_max, real_press_min, real_press_avg, meter_code, automated, closed, to_arc, meter_type, name, nominal_flowrate)
			VALUES(NEW.node_id, NEW.real_press_max, NEW.real_press_min, NEW.real_press_avg, NEW.meter_code, NEW.automated, NEW.closed, NEW.to_arc, NEW.meter_type, NEW.name, NEW.nominal_flowrate);


		ELSIF v_man_table='man_source' THEN
				INSERT INTO man_source (node_id, name, source_type, source_code, aquifer_type, aquifer_name, wtp_id, registered_flow, auth_code, basin_id, subbasin_id, inlet_arc)
				VALUES(NEW.node_id, NEW.name, NEW.source_type, NEW.source_code, NEW.aquifer_type, NEW.aquifer_name, NEW.wtp_id, NEW.registered_flow, NEW.auth_code, NEW.basin_id, NEW.subbasin_id, NEW.inlet_arc);

		ELSIF v_man_table='man_waterwell' THEN
			INSERT INTO man_waterwell (node_id, name, inlet_arc) VALUES(NEW.node_id, NEW.name, NEW.inlet_arc);

		ELSIF v_man_table='man_filter' THEN
			INSERT INTO man_filter (node_id) VALUES(NEW.node_id);

		ELSIF v_man_table='man_register' THEN
			INSERT INTO man_register (node_id, length, width, height, max_volume, util_volume) VALUES (NEW.node_id, NEW.length, NEW.width, NEW.height, NEW.max_volume, NEW.util_volume);

		ELSIF v_man_table='man_netwjoin' THEN
			INSERT INTO man_netwjoin (node_id, top_floor, customer_code)
			VALUES(NEW.node_id, NEW.top_floor, NEW.customer_code);

		ELSIF v_man_table='man_expansiontank' THEN
			INSERT INTO man_expansiontank (node_id) VALUES(NEW.node_id);

		ELSIF v_man_table='man_flexunion' THEN
			INSERT INTO man_flexunion (node_id) VALUES(NEW.node_id);

		ELSIF v_man_table='man_netelement' THEN
			INSERT INTO man_netelement (node_id, automated, fence_type)
			VALUES(NEW.node_id, NEW.automated, NEW.fence_type);

		ELSIF v_man_table='man_netsamplepoint' THEN
			INSERT INTO man_netsamplepoint (node_id, lab_code, place_name, cabinet)
			VALUES (NEW.node_id, NEW.lab_code, NEW.place_name, NEW.cabinet);

		ELSIF v_man_table='man_wtp' THEN
			INSERT INTO man_wtp (node_id, name, maxflow, opsflow, screening, desander, chemical, oxidation, coagulation, floculation, presendiment, sediment,
			filtration, disinfection, storage, sludgeman, inlet_arc)
			VALUES (NEW.node_id, NEW.name, NEW.maxflow, NEW.opsflow, NEW.screening, NEW.desander, NEW.chemical, NEW.oxidation, NEW.coagulation, NEW.floculation,
			NEW.presendiment, NEW.sediment, NEW.filtration, NEW.disinfection, NEW.storage, NEW.sludgeman, NEW.inlet_arc);

		END IF;

		IF v_man_table='parent' then

		    v_man_table:= (SELECT man_table FROM cat_feature_node n
			JOIN cat_feature cf ON cf.id = n.id
			JOIN sys_feature_class s ON cf.feature_class = s.id
			JOIN cat_node ON cat_node.id=NEW.nodecat_id WHERE n.id = cat_node.node_type LIMIT 1)::text;

			--insert valve values for valve objects
			IF v_man_table='man_valve' then
				if NEW.closed_valve is null then NEW.closed_valve = false; end if;
				if NEW.broken_valve is null then NEW.broken_valve = false; end if;

				v_sql:= 'INSERT INTO man_valve (node_id, closed, broken, connection_type) VALUES ('||quote_literal(NEW.node_id)||', '||(NEW.closed_valve)||', '||(NEW.broken_valve)||', 0)';

			ELSE
				v_sql:= 'INSERT INTO '||v_man_table||' (node_id) VALUES ('||(NEW.node_id)||')';
			END IF;

			EXECUTE v_sql;

		END IF;

		--insert tank into config_graph_mincut
		IF v_man_table='man_tank' THEN

			INSERT INTO config_graph_mincut(node_id, active)
			VALUES (NEW.node_id, TRUE);
		END IF;

		-- childtable insert
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='NODE' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' ||v_addfields.param_name||'"'
					USING NEW
					INTO v_new_value_param;

				v_childtable_name := 'man_node_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF v_new_value_param IS NOT NULL THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (node_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (node_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.node_id=$1'
							USING NEW.node_id, v_new_value_param;
					END IF;
				END IF;
			END LOOP;
		END IF;

		-- EPA insert
		IF (NEW.epa_type = 'JUNCTION') THEN
			INSERT INTO inp_junction (node_id) VALUES (NEW.node_id);

		ELSIF (NEW.epa_type = 'TANK') THEN
			INSERT INTO inp_tank (node_id) VALUES (NEW.node_id);

		ELSIF (NEW.epa_type = 'RESERVOIR') THEN
			INSERT INTO inp_reservoir (node_id) VALUES (NEW.node_id);

		ELSIF (NEW.epa_type = 'PUMP') THEN
			INSERT INTO inp_pump (node_id, status, pump_type) VALUES (NEW.node_id, 'OPEN', 'POWERPUMP');

		ELSIF (NEW.epa_type = 'VALVE') THEN

			v_customfeature	:= (SELECT node_type FROM cat_node WHERE id = NEW.nodecat_id);
			SELECT vdef INTO v_epavdef FROM (
			SELECT json_array_elements_text ((value::json->>'catfeatureId')::json) id , (value::json->>'vdefault') vdef FROM config_param_system WHERE parameter like 'epa_valve_vdefault_%'
			)a WHERE id = v_customfeature;

			INSERT INTO inp_valve (node_id, valve_type, custom_dint, setting, minorloss)
			VALUES (NEW.node_id, v_epavdef ->>'valve_type', (v_epavdef ->>'coef_loss')::numeric, (v_epavdef ->>'pressure')::numeric,(v_epavdef ->>'minorloss')::numeric);

		ELSIF (NEW.epa_type = 'SHORTPIPE') THEN

			v_customfeature	:= (SELECT node_type FROM cat_node WHERE id = NEW.nodecat_id);
			SELECT vdef INTO v_epavdef FROM (
			SELECT json_array_elements_text ((value::json->>'catfeatureId')::json) id , (value::json->>'vdefault') vdef FROM config_param_system WHERE parameter like 'epa_shortpipe_vdefault'
			)a WHERE id = v_customfeature;

			INSERT INTO inp_shortpipe (node_id, minorloss)
			VALUES (NEW.node_id, (v_epavdef ->>'minorloss')::numeric);


		ELSIF (NEW.epa_type = 'INLET') THEN
			INSERT INTO inp_inlet (node_id) VALUES (NEW.node_id);
		END IF;

		-- static pressure
		IF v_ispresszone AND NEW.presszone_id IS NOT NULL THEN
			UPDATE node SET staticpressure = (SELECT head from presszone WHERE presszone_id = NEW.presszone_id)-top_elev WHERE node_id = NEW.node_id;
		END IF;

		-- man2inp_values
		PERFORM gw_fct_man2inp_values(v_input);

		RETURN NEW;

    -- UPDATE
	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		SELECT code_autofill, cat_feature.id INTO v_code_autofill_bool, v_featurecat FROM cat_feature
		JOIN cat_node ON cat_feature.id=cat_node.node_type WHERE cat_node.id=NEW.nodecat_id;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('feature', v_featurecat, json_strip_nulls(row_to_json(NEW)::json));
		END IF;

			-- static pressure
		IF v_ispresszone AND (NEW.presszone_id != OLD.presszone_id) THEN
			UPDATE node SET staticpressure = (SELECT head from presszone WHERE presszone_id = NEW.presszone_id)-top_elev
			WHERE node_id = NEW.node_id;
		END IF;

		-- EPA update
		IF (NEW.epa_type != OLD.epa_type) THEN

		    IF (OLD.epa_type = 'JUNCTION') THEN
			v_inp_table:= 'inp_junction';
		    ELSIF (OLD.epa_type = 'TANK') THEN
			v_inp_table:= 'inp_tank';
		    ELSIF (OLD.epa_type = 'RESERVOIR') THEN
			v_inp_table:= 'inp_reservoir';
		    ELSIF (OLD.epa_type = 'SHORTPIPE') THEN
			v_inp_table:= 'inp_shortpipe';
		    ELSIF (OLD.epa_type = 'VALVE') THEN
			v_inp_table:= 'inp_valve';
		    ELSIF (OLD.epa_type = 'PUMP') THEN
			v_inp_table:= 'inp_pump';
		    ELSIF (OLD.epa_type = 'INLET') THEN
			v_inp_table:= 'inp_inlet';
		    END IF;

		    -- specific case to move data between inlet <-> tank
		    IF (OLD.epa_type = 'TANK') and (NEW.epa_type = 'INLET') THEN
		      DELETE FROM inp_inlet WHERE node_id = OLD.node_id;
					INSERT INTO inp_inlet (node_id, initlevel, minlevel, maxlevel, diameter, minvol, curve_id, overflow)
					SELECT NEW.node_id, initlevel, minlevel, maxlevel, diameter, minvol, curve_id, overflow
					FROM inp_tank WHERE node_id = OLD.node_id;

		    ELSIF (OLD.epa_type = 'INLET') and (NEW.epa_type = 'TANK') THEN
					DELETE FROM inp_tank WHERE node_id = OLD.node_id;
					INSERT INTO inp_tank
					SELECT NEW.node_id, initlevel, minlevel, maxlevel, diameter, minvol, curve_id, overflow
					FROM inp_inlet WHERE node_id = OLD.node_id;

				ELSIF (OLD.epa_type = 'RESERVOIR') and (NEW.epa_type = 'INLET') THEN
		      DELETE FROM inp_inlet WHERE node_id = OLD.node_id;
					INSERT INTO inp_inlet (node_id, pattern_id, head)
					SELECT NEW.node_id, pattern_id, head
					FROM inp_reservoir WHERE node_id = OLD.node_id;

		    ELSIF (OLD.epa_type = 'INLET') and (NEW.epa_type = 'RESERVOIR') THEN
					DELETE FROM inp_reservoir WHERE node_id = OLD.node_id;
					INSERT INTO inp_reservoir (node_id, pattern_id, head)
					SELECT NEW.node_id, pattern_id, head
					FROM inp_inlet WHERE node_id = OLD.node_id;
		    END IF;

		    IF v_inp_table IS NOT NULL THEN
			v_sql:= 'DELETE FROM '||v_inp_table||' WHERE node_id = '||quote_literal(OLD.node_id);
			EXECUTE v_sql;
		    END IF;
		    v_inp_table := NULL;

		    IF (NEW.epa_type = 'JUNCTION') THEN
			v_inp_table:= 'inp_junction';
		    ELSIF (NEW.epa_type = 'TANK') THEN
			v_inp_table:= 'inp_tank';
		    ELSIF (NEW.epa_type = 'RESERVOIR') THEN
			v_inp_table:= 'inp_reservoir';
		    ELSIF (NEW.epa_type = 'SHORTPIPE') THEN
			v_inp_table:= 'inp_shortpipe';
		    ELSIF (NEW.epa_type = 'VALVE') THEN
				IF (SELECT lower(feature_class) FROM cat_feature_node cfn JOIN cat_node c ON cfn.id=c.node_type JOIN cat_feature cf ON cfn.id=cf.id WHERE c.id=NEW.nodecat_id)<>'valve' THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3266", "function":"1320","parameters":null, "is_process":true}}$$)';
				END IF;
			v_inp_table:= 'inp_valve';
		    ELSIF (NEW.epa_type = 'PUMP') THEN
				IF (SELECT lower(feature_class) FROM cat_feature_node cfn JOIN cat_node c ON cfn.id=c.node_type JOIN cat_feature cf ON cfn.id=cf.id WHERE c.id=NEW.nodecat_id)<>'pump' THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3266", "function":"1320","parameters":null, "is_process":true}}$$)';
				END IF;
			v_inp_table:= 'inp_pump';
		    ELSIF (NEW.epa_type = 'INLET') THEN
			v_inp_table:= 'inp_inlet';
		    END IF;
		    IF v_inp_table IS NOT NULL THEN
			v_sql:= 'INSERT INTO '||v_inp_table||' (node_id) VALUES ('||quote_literal(NEW.node_id)||') ON CONFLICT (node_id) DO NOTHING';
			EXECUTE v_sql;
		    END IF;
		END IF;

		-- State
		IF (NEW.state != OLD.state) THEN
			UPDATE node SET state=NEW.state WHERE node_id = OLD.node_id;
			IF NEW.state = 2 AND OLD.state=1 THEN
				INSERT INTO plan_psector_x_node (node_id, psector_id, state, doable)
				VALUES (NEW.node_id, (SELECT config_param_user.value::integer AS value FROM config_param_user WHERE config_param_user.parameter::text
				= 'plan_psector_current'::text AND config_param_user.cur_user::name = "current_user"() LIMIT 1), 1, true);
			END IF;
			IF NEW.state = 1 AND OLD.state=2 THEN
				DELETE FROM plan_psector_x_node WHERE node_id=NEW.node_id;
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
					"data":{"message":"2110", "function":"1320","parameters":null}}$$);';
					END IF;
				END IF;
			END IF;
		END IF;

		--check relation state - state_type
		IF (NEW.state_type != OLD.state_type) AND NEW.state_type NOT IN (SELECT id FROM value_state_type WHERE state = NEW.state) THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3036", "function":"1320","parameters":{"state_id":"'||NEW.state::text||'"}}}$$);';
		END IF;

		-- rotation
		IF NEW.rotation IS DISTINCT FROM OLD.rotation THEN
			UPDATE node SET rotation=NEW.rotation WHERE node_id = OLD.node_id;
		END IF;

		-- hemisphere
		IF NEW.hemisphere IS DISTINCT FROM OLD.hemisphere THEN
			UPDATE node SET hemisphere=NEW.hemisphere WHERE node_id = OLD.node_id;
		END IF;

		-- The geom
		IF st_equals( NEW.the_geom, OLD.the_geom) IS FALSE THEN

			--the_geom
			UPDATE node SET the_geom=NEW.the_geom WHERE node_id = OLD.node_id;

			-- Parent id
			SELECT pol_id INTO v_pol_id FROM polygon JOIN cat_feature ON cat_feature.id=polygon.featurecat_id
			WHERE ST_DWithin(NEW.the_geom, polygon.the_geom, 0.001) LIMIT 1;

			IF v_pol_id IS NOT NULL THEN
				v_sql:= 'SELECT feature_id FROM polygon WHERE pol_id::integer='||v_pol_id||' LIMIT 1';
				EXECUTE v_sql INTO v_node_id;
				NEW.parent_id=v_node_id;
			END IF;

			--update top_elev from raster
			IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
			AND (NEW.top_elev = OLD.top_elev) AND
				(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_update_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
				NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
							(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1) LIMIT 1);
			END IF;

			--update associated geometry of element (if exists) and trace_featuregeom is true
			v_trace_featuregeom:= (SELECT trace_featuregeom FROM element join element_x_node USING (element_id)
                WHERE node_id=NEW.node_id AND the_geom IS NOT NULL LIMIT 1);
			-- if trace_featuregeom is false, do nothing
			IF v_trace_featuregeom IS TRUE THEN
				UPDATE element SET the_geom = NEW.the_geom WHERE St_dwithin(OLD.the_geom, the_geom, 0.001)
				AND element_id IN (SELECT element_id FROM element_x_node WHERE node_id = NEW.node_id);
			END IF;

		END IF;

		--link_path
		SELECT link_path INTO v_link_path FROM cat_feature JOIN cat_node ON cat_node.node_type=cat_feature.id WHERE cat_node.id=NEW.nodecat_id;
		IF v_link_path IS NOT NULL THEN
			NEW.link = replace(NEW.link, v_link_path,'');
		END IF;

	  IF (NEW.nodecat_id != OLD.nodecat_id) THEN

		-- man tables
		v_old_node_type= (SELECT feature_class FROM cat_feature JOIN cat_node ON cat_feature.id=node_type where cat_node.id=OLD.nodecat_id);
		v_new_node_type= (SELECT feature_class FROM cat_feature JOIN cat_node ON cat_feature.id=node_type where cat_node.id=NEW.nodecat_id);
		-- Man and epa epa tables when parent is used
			IF v_man_table='parent' THEN
				IF v_new_node_type != v_old_node_type THEN
					v_sql='INSERT INTO man_'||lower(v_new_node_type)||' (node_id) VALUES ('||NEW.node_id||')';
					EXECUTE v_sql;
					v_sql='DELETE FROM man_'||lower(v_old_node_type)||' WHERE node_id='||quote_literal(OLD.node_id);
					EXECUTE v_sql;
				END IF;

				-- epa tables
				SELECT epa_table,epa_default into v_new_epatable, NEW.epa_type FROM cat_feature_node JOIN sys_feature_epa_type s ON epa_default = s.id
				JOIN cat_node ON cat_feature_node.id=node_type where cat_node.id=NEW.nodecat_id AND s.feature_type = 'NODE';

				v_old_epatable = (SELECT epa_table FROM cat_feature_node JOIN sys_feature_epa_type s ON epa_default = s.id WHERE epa_default = OLD.epa_type AND s.feature_type = 'NODE' LIMIT 1);

				IF v_new_epatable != v_old_epatable THEN
					v_sql='DELETE FROM '||v_old_epatable||' WHERE node_id='||quote_literal(OLD.node_id);
					EXECUTE v_sql;
					v_sql='INSERT INTO '||v_new_epatable||' (node_id) VALUES ('||NEW.node_id||')';
					EXECUTE v_sql;
				END IF;
			END IF;

		END IF;

		UPDATE node
		SET code=NEW.code, sys_code=NEW.sys_code, top_elev=NEW.top_elev, custom_top_elev=NEW.custom_top_elev, datasource=NEW.datasource, "depth"=NEW."depth", nodecat_id=NEW.nodecat_id, epa_type=NEW.epa_type, sector_id=NEW.sector_id, arc_id=NEW.arc_id, parent_id=NEW.parent_id,
		state_type=NEW.state_type, annotation=NEW.annotation, "observ"=NEW."observ", "comment"=NEW."comment", dma_id=NEW.dma_id, dqa_id=NEW.dqa_id, presszone_id=NEW.presszone_id, soilcat_id=NEW.soilcat_id,
		function_type=NEW.function_type, category_type=NEW.category_type, fluid_type=NEW.fluid_type, location_type=NEW.location_type, workcat_id=NEW.workcat_id, workcat_id_end=NEW.workcat_id_end,
		workcat_id_plan=NEW.workcat_id_plan,builtdate=NEW.builtdate, enddate=NEW.enddate, ownercat_id=NEW.ownercat_id, muni_id=NEW.muni_id, streetaxis_id=NEW.streetaxis_id,
		postcomplement=NEW.postcomplement, postcomplement2=NEW.postcomplement2, streetaxis2_id=NEW.streetaxis2_id,postcode=NEW.postcode,district_id=NEW.district_id,postnumber=NEW.postnumber,
		postnumber2=NEW.postnumber2, descript=NEW.descript, verified=NEW.verified, label_x=NEW.label_x, label_y=NEW.label_y, label_rotation=NEW.label_rotation,
		publish=NEW.publish, inventory=NEW.inventory, expl_id=NEW.expl_id, num_value=NEW.num_value, link=NEW.link, updated_at=now(), updated_by=current_user,
		adate=NEW.adate, adescript=NEW.adescript, accessibility = NEW.accessibility, asset_id=NEW.asset_id,
		om_state=NEW.om_state, conserv_state=NEW.conserv_state, access_type=NEW.access_type, placement_type=NEW.placement_type, expl_visibility=NEW.expl_visibility,
		brand_id=NEW.brand_id, model_id=NEW.model_id, serial_number=NEW.serial_number, label_quadrant=NEW.label_quadrant, pavcat_id = NEW.pavcat_id, lock_level=NEW.lock_level, is_scadamap=NEW.is_scadamap,
		dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
		WHERE node_id = OLD.node_id;

		-- Update node_add
		UPDATE node_add SET node_id=NEW.node_id, demand_max = NEW.demand_max, demand_min = NEW.demand_min, demand_avg = NEW.demand_avg, press_max = NEW.press_max,press_min = NEW.press_min,
		press_avg = NEW.press_avg, head_max = NEW.head_max, head_min = NEW.head_min, head_avg = NEW.head_avg, quality_max = NEW.quality_max, quality_min = NEW.quality_min,
		quality_avg = NEW.quality_avg, result_id = NEW.result_id
		WHERE node_id = OLD.node_id;

		-- Update visibility tables
		IF NEW.sector_visibility IS DISTINCT FROM OLD.sector_visibility THEN
		    DELETE FROM node_x_sector_visibility WHERE node_id = OLD.node_id;
		    IF NEW.sector_visibility IS NOT NULL THEN
		        INSERT INTO node_x_sector_visibility (node_id, sector_id)
		        SELECT NEW.node_id, unnest(NEW.sector_visibility);
		    END IF;
		END IF;

		IF NEW.muni_visibility IS DISTINCT FROM OLD.muni_visibility THEN
		    DELETE FROM node_x_municipality_visibility WHERE node_id = OLD.node_id;
		    IF NEW.muni_visibility IS NOT NULL THEN
		        INSERT INTO node_x_municipality_visibility (node_id, muni_id)
		        SELECT NEW.node_id, unnest(NEW.muni_visibility);
		    END IF;
		END IF;

		IF v_man_table ='man_junction' THEN
			UPDATE man_junction SET node_id=NEW.node_id
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_tank' THEN
			UPDATE man_tank SET vmax=NEW.vmax, vutil=NEW.vutil, area=NEW.area, chlorination=NEW.chlorination, name=NEW.name, invert_level = NEW.invert_level,
			hmax=NEW.hmax, automated=NEW.automated, length=NEW.length, width=NEW.width, shape=COALESCE(NEW.shape, 0), fence_type=NEW.fence_type, fence_length=NEW.fence_length, inlet_arc=NEW.inlet_arc, vnom=NEW.vnom
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_pump' THEN
			UPDATE man_pump SET max_flow=NEW.max_flow, min_flow=NEW.min_flow, nom_flow=NEW.nom_flow, "power"=NEW.power,
			pressure_exit=NEW.pressure_exit, elev_height=NEW.elev_height, name=NEW.name, pump_number=NEW.pump_number, to_arc=NEW.to_arc
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_manhole' THEN
			UPDATE man_manhole SET name=NEW.name
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_hydrant' THEN
			UPDATE man_hydrant SET fire_code=NEW.fire_code, communication=NEW.communication, valve=NEW.valve,
			geom1=NEW.geom1, geom2=NEW.geom2, customer_code=NEW.customer_code, hydrant_type=NEW.hydrant_type, security_cover=NEW.security_cover
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_source' THEN
			UPDATE man_source SET name=NEW.name, source_type=NEW.source_type, source_code=NEW.source_code, aquifer_type=NEW.aquifer_type, aquifer_name=NEW.aquifer_name,
			wtp_id=NEW.wtp_id, registered_flow=NEW.registered_flow, auth_code=NEW.auth_code, basin_id=NEW.basin_id, subbasin_id=NEW.subbasin_id, inlet_arc=NEW.inlet_arc
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_meter' THEN
			UPDATE man_meter
			SET real_press_max=NEW.real_press_max, real_press_min=NEW.real_press_min, real_press_avg=NEW.real_press_avg, meter_code=NEW.meter_code,
			automated=NEW.automated, closed=NEW.closed, to_arc=NEW.to_arc, meter_type=NEW.meter_type, name=NEW.name, nominal_flowrate=NEW.nominal_flowrate
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_waterwell' THEN
			UPDATE man_waterwell SET name=NEW.name
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_reduction' THEN
			UPDATE man_reduction SET diam1=NEW.diam1, diam2=NEW.diam2
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_valve' THEN

			UPDATE man_valve
			SET closed=NEW.closed, broken=NEW.broken, buried=NEW.buried, irrigation_indicator=NEW.irrigation_indicator, pressure_entry=NEW.pressure_entry, pressure_exit=NEW.pressure_exit,
			depth_valveshaft=NEW.depth_valveshaft, regulator_situation=NEW.regulator_situation, regulator_location=NEW.regulator_location, regulator_observ=NEW.regulator_observ,
			lin_meters=NEW.lin_meters, exit_type=NEW.exit_type, exit_code=NEW.exit_code, drive_type=NEW.drive_type, cat_valve2=NEW.cat_valve2, ordinarystatus = NEW.ordinarystatus,
			shutter=NEW.shutter, brand2=NEW.brand2, model2=NEW.model2, valve_type=NEW.valve_type, to_arc=NEW.to_arc, automated=NEW.automated, connection_type=NEW.connection_type,
			flowsetting=NEW.flowsetting, turns_count=NEW.turns_count
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_register' THEN
			UPDATE man_register	SET node_id=NEW.node_id, length=NEW.length, width=NEW.width, height=NEW.height, max_volume=NEW.max_volume, util_volume=NEW.util_volume
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_netwjoin' THEN
			UPDATE man_netwjoin
			SET top_floor= NEW.top_floor, customer_code=NEW.customer_code
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_expansiontank' THEN
			UPDATE man_expansiontank SET node_id=NEW.node_id
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_flexunion' THEN
			UPDATE man_flexunion SET node_id=NEW.node_id
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_netelement' THEN
			UPDATE man_netelement SET node_id=NEW.node_id, automated=NEW.automated, fence_type=NEW.fence_type
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_netsamplepoint' THEN
			UPDATE man_netsamplepoint SET node_id=NEW.node_id, lab_code=NEW.lab_code, place_name=NEW.place_name, cabinet=NEW.cabinet
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_wtp' THEN
			UPDATE man_wtp SET name = NEW.name, maxflow = NEW.maxflow, opsflow = NEW.opsflow, screening = NEW.screening, desander = NEW.desander, chemical = NEW.chemical,
    		oxidation = NEW.oxidation, coagulation = NEW.coagulation, floculation = NEW.floculation, presendiment = NEW.presendiment, sediment = NEW.sediment,
    		filtration = NEW.filtration, disinfection = NEW.disinfection, storage = NEW.storage, sludgeman = NEW.sludgeman, inlet_arc=NEW.inlet_arc
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_filter' THEN
			UPDATE man_filter SET node_id=NEW.node_id
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='parent' THEN
		    v_man_table:= (SELECT man_table FROM cat_feature_node n
			JOIN cat_feature cf ON cf.id = n.id
			JOIN sys_feature_class s ON cf.feature_class = s.id
			JOIN cat_node ON cat_node.id=NEW.nodecat_id WHERE n.id = cat_node.node_type LIMIT 1)::text;

			IF v_man_table='man_valve' THEN

				-- profilactic control for null values on closed and broken columns
				IF NEW.closed_valve IS NULL THEN NEW.closed_valve = false; end if;
				IF NEW.broken_valve IS NULL THEN NEW.broken_valve = false; end if;

				v_sql:= 'UPDATE man_valve SET closed='||coalesce(NEW.closed_valve, false)||', broken='||coalesce(NEW.broken_valve,false)||' WHERE node_id='||quote_literal(NEW.node_id)||'';
				EXECUTE v_sql;
			END IF;
		END IF;

		-- childtable update
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='NODE' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING NEW
					INTO v_new_value_param;

				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING OLD
					INTO v_old_value_param;

				v_childtable_name := 'man_node_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF (v_new_value_param IS NOT NULL AND v_old_value_param!=v_new_value_param) OR (v_new_value_param IS NOT NULL AND v_old_value_param IS NULL) THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (node_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (node_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.node_id=$1'
							USING NEW.node_id, v_new_value_param;

					ELSIF v_new_value_param IS NULL AND v_old_value_param IS NOT NULL THEN
						EXECUTE 'UPDATE '||v_childtable_name||' SET '||v_addfields.param_name||' = null WHERE '||v_childtable_name||'.node_id=$1'
							USING NEW.node_id;
					END IF;
				END IF;
			END LOOP;
		END IF;

		v_new_node_type= (SELECT node_type FROM  cat_node where cat_node.id=NEW.nodecat_id);

		UPDATE arc SET nodetype_1 = v_new_node_type, elevation1=NEW.top_elev, depth1=NEW.depth, staticpressure1 = NEW.staticpressure WHERE node_1 = NEW.node_id;
		UPDATE arc SET nodetype_2 = v_new_node_type, elevation2=NEW.top_elev, depth2=NEW.depth, staticpressure2 = NEW.staticpressure WHERE node_2 = NEW.node_id;

		-- set label_quadrant, label_x and label_y according to cat_feature
		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>0
		FROM cat_feature JOIN cat_node on cat_feature.id = cat_node.node_type WHERE cat_node.id = '||quote_literal(new.nodecat_id)||'
		' INTO v_dist_xlab;

		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>1
		FROM cat_feature JOIN cat_node on cat_feature.id = cat_node.node_type WHERE cat_node.id = '||quote_literal(new.nodecat_id)||'
		' INTO v_dist_ylab;

		if new.label_x != old.label_x and new.label_y != old.label_y then
			--raise exception 'a';

			update node set label_x = new.label_x, label_y = new.label_y where node_id = new.node_id;

			v_dist_ylab = null;
			v_dist_xlab = null;

		end if;

		if new.label_rotation != old.label_rotation then
			--raise exception 'a';

			update node set label_rotation = new.label_rotation where node_id = new.node_id;

			v_dist_ylab = null;
			v_dist_xlab = null;

		end if;

		new.rotation = coalesce(new.rotation, 0);

		if v_dist_ylab is not null and v_dist_xlab is not null and
		(SELECT value::boolean FROM config_param_user WHERE parameter='edit_disable_noderotation' AND cur_user=current_user) IS FALSE
		then -- only start the process with not-null values


			-- prev calc: intermediate rotations according to dist_x and dist_y from cat_feature
			if (v_dist_xlab > 0 and v_dist_ylab > 0) -- top right
			or (v_dist_xlab < 0 and v_dist_ylab < 0) -- bottom left
			then
				v_rot1 = 90+new.rotation;
				v_rot2 = 0+new.rotation;

			elsif (v_dist_xlab > 0 and v_dist_ylab < 0) -- bottom right
			or 	  (v_dist_xlab < 0 and v_dist_ylab > 0) -- top left
			then
				v_rot1 = -90+new.rotation;
				v_rot2 = -180+new.rotation;

				v_dist_xlab = v_dist_xlab * (-1);
				v_dist_ylab = v_dist_ylab * (-1);


			end if;

			-- prev calc: label position according to cat_feature
			v_sql = '
			with mec as (
			select the_geom, ST_Project(ST_Transform(the_geom, 4326)::geography, '||v_dist_xlab||', radians('||v_rot1||')) as eee
			FROM node WHERE node_id = '||QUOTE_LITERAL(new.node_id)||'), lab_point as (
			SELECT ST_Project(ST_Transform(eee::geometry, 4326)::geography, '||v_dist_ylab||', radians('||v_rot2||')) as fff
			from mec)
			select st_transform(fff::geometry, '||v_srid||') as label_p from lab_point';

			execute v_sql into v_label_point;

			-- prev calc: diagonal distance between node and label position (Pitagoras)
			v_label_dist = sqrt(v_dist_xlab^2 + v_dist_ylab^2);


			-- prev calc: current angle between node and label position
			v_sql = '
			with mec as (
				SELECT
				n.the_geom as vertex_point,
				n.rotation as rotation_node,
				$1 as point1,
				ST_LineInterpolatePoint(a.the_geom, ST_LineLocatePoint(a.the_geom, n.the_geom)) as point2
				from node n, arc a  where n.node_id = $2 and st_dwithin (a.the_geom, n.the_geom, 0.001) limit 1
			)
			select degrees(ST_Azimuth(vertex_point, point1))
			from mec';

			execute v_sql into v_cur_rotation using v_label_point, new.node_id;


			-- prev calc: current label_quadrant according to cat_feature
			if v_dist_xlab > 0 and v_dist_ylab > 0 then -- top right
				v_cur_quadrant = 'TR';
			elsif v_dist_xlab < 0 and v_dist_ylab > 0 then -- top left
				v_cur_quadrant = 'TL';
			elsif v_dist_xlab > 0 and v_dist_ylab < 0 then --bottom right
				v_cur_quadrant = 'BR';
			elsif v_dist_xlab < 0 and v_dist_ylab < 0 then -- bottom left
				v_cur_quadrant = 'BL';
			end if;

			-- set label_x and label_y according to cat_feature
			update node set label_x = st_x(v_label_point) where node_id = new.node_id;
			update node set label_y = st_y(v_label_point) where node_id = new.node_id;

			update node set label_quadrant = v_cur_quadrant where node_id = new.node_id;
			update node set label_rotation =  new.rotation where node_id = new.node_id;

			-- CASE: if label_quadrant changes
			if new.label_quadrant != old.label_quadrant then
				--v_label_dist = sqrt(v_dist_xlab^2 + v_dist_ylab^2);

				if new.label_quadrant ilike 'B%' then
					v_dist_ylab = v_dist_ylab * (-1);
				end if;

				if new.label_quadrant ilike '%L' then
					v_dist_xlab = v_dist_xlab * (-1);
				end if;

				if new.label_quadrant ilike 'B%' then
					if new.label_quadrant ilike '%L' then
						v_rot1 = -90;
					elsif new.label_quadrant ilike '%R' then
						v_rot1 = 90;
					end if;
				end if;

				if new.label_quadrant ilike 'T%' then
					if new.label_quadrant ilike '%L' then
						v_rot1 = 90;
					elsif new.label_quadrant ilike '%R' then
						v_rot1 = -90;
					end if;
				end if;

				if (v_dist_xlab > 0 and v_dist_ylab > 0) -- top right
				or (v_dist_xlab < 0 and v_dist_ylab < 0) -- bottom left
				then
					v_rot1 = 90+new.rotation;
					v_rot2 = 0+new.rotation;

				elsif (v_dist_xlab > 0 and v_dist_ylab < 0) -- bottom right
				or 	  (v_dist_xlab < 0 and v_dist_ylab > 0) -- top left
				then
					v_rot1 = -90+new.rotation;
					v_rot2 = -180+new.rotation;

					v_dist_xlab = v_dist_xlab * (-1);
					v_dist_ylab = v_dist_ylab * (-1);

				end if;

				v_rot1=coalesce(v_rot1, 0);
				v_rot2=coalesce(v_rot2, 0);

				v_sql = '
				with mec as (
				select the_geom, ST_Project(ST_Transform(the_geom, 4326)::geography, '||v_dist_xlab||', radians('||v_rot1||')) as eee
				FROM node WHERE node_id = '||QUOTE_LITERAL(new.node_id)||'), lab_point as (
				SELECT ST_Project(ST_Transform(eee::geometry, 4326)::geography, '||v_dist_ylab||', radians('||v_rot2||')) as fff
				from mec)
				select st_transform(fff::geometry, '||v_srid||') as label_p from lab_point';

				execute v_sql into v_new_lab_position;

				-- update label position
				update node set label_x = st_x(v_new_lab_position) where node_id = new.node_id;
				update node set label_y = st_y(v_new_lab_position) where node_id = new.node_id;

				update node set label_quadrant = new.label_quadrant where node_id = new.node_id;
				update node set label_rotation = new.rotation where node_id = new.node_id;

			end if;

		-- CASE: if rotation of the node changes
		if new.rotation::text != old.rotation::text OR (OLD.rotation IS NULL AND NEW.rotation IS NOT NULL) then

			-- prev calc: current label position
			select st_setsrid(st_makepoint(label_x::numeric, label_y::numeric), v_srid) into v_label_point from node where node_id = new.node_id;

			-- prev calc: geom of the node
			execute 'select the_geom from node where node_id = '||quote_literal(new.node_id)||''  into v_geom;

			-- prev calc: current angle between node and its label
			v_sql = '
			with mec as (
				SELECT
				n.the_geom as vertex_point,
				n.rotation as rotation_node,
				$1 as point1,
				ST_LineInterpolatePoint(a.the_geom, ST_LineLocatePoint(a.the_geom, n.the_geom)) as point2
				from node n, arc a  where n.node_id = $2 and st_dwithin (a.the_geom, n.the_geom, 0.001) limit 1
			)
			select degrees(ST_Azimuth(vertex_point, point1))
			from mec';

			execute v_sql into v_cur_rotation using v_label_point, new.node_id;

			-- prev calc: intermediate rotations according to dist_x and dist_y
			if (v_dist_xlab > 0 and v_dist_ylab > 0) -- top right
			or (v_dist_xlab < 0 and v_dist_ylab < 0) -- bottom left
			then
				v_rot1 = 90+new.rotation;
				v_rot2 = 0+new.rotation;

			elsif (v_dist_xlab > 0 and v_dist_ylab < 0) -- bottom right
			or 	  (v_dist_xlab < 0 and v_dist_ylab > 0) -- top left
			then
				v_rot1 = -90+new.rotation;
				v_rot2 = -180+new.rotation;

				v_dist_xlab = v_dist_xlab * (-1);
				v_dist_ylab = v_dist_ylab * (-1);

			end if;

			-- label position
			v_sql = '
			with mec as (
			select the_geom, ST_Project(ST_Transform(the_geom, 4326)::geography, '||v_dist_xlab||', radians('||v_rot1||')) as eee
			FROM node WHERE node_id = '||QUOTE_LITERAL(new.node_id)||'), lab_point as (
			SELECT ST_Project(ST_Transform(eee::geometry, 4326)::geography, '||v_dist_ylab||', radians('||v_rot2||')) as fff
			from mec)
			select st_transform(fff::geometry, '||v_srid||') as label_p from lab_point';
			execute v_sql into v_label_point;

			update node set label_rotation = new.rotation where node_id = new.node_id;
			update node set label_x = st_x(v_label_point) where node_id = new.node_id;
			update node set label_y = st_y(v_label_point) where node_id = new.node_id;
		end if;
	end if;

	-- man2inp_values
	PERFORM gw_fct_man2inp_values(v_input);
	RETURN NEW;

   -- DELETE
   ELSIF TG_OP = 'DELETE' THEN

		EXECUTE 'SELECT gw_fct_getcheckdelete($${"client":{"device":4, "infoType":1, "lang":"ES"},
		"feature":{"id":"'||OLD.node_id||'","featureType":"NODE"}, "data":{}}$$)';

		-- delete from polygon table (before the deletion of node)
		DELETE FROM polygon WHERE feature_id = OLD.node_id;

		-- force plan_psector_force_delete
		SELECT value INTO v_force_delete FROM config_param_user WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;
		UPDATE config_param_user SET value = 'true' WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		-- delete from node table
		DELETE FROM node WHERE node_id = OLD.node_id;

		-- restore plan_psector_force_delete
		UPDATE config_param_user SET value = v_force_delete WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		--remove node from config_graph_mincut
		DELETE FROM config_graph_mincut WHERE node_id=OLD.node_id;

		-- Delete childtable addfields (after or before deletion of node, doesn't matter)

		v_customfeature = old.node_type;
		v_node_id = old.node_id;

		v_childtable_name := 'man_node_' || lower(v_customfeature);
		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
			EXECUTE 'DELETE FROM '||v_childtable_name||' WHERE node_id = '||quote_literal(v_node_id)||'';
		END IF;


		-- delete from node_add table
		DELETE FROM node_add WHERE node_id = OLD.node_id;

		UPDATE arc SET nodetype_1 = NULL, elevation1=NULL, depth1=NULL, staticpressure1 = NULL WHERE node_1 = OLD.node_id;
		UPDATE arc SET nodetype_2 = NULL, elevation2=NULL, depth2=NULL, staticpressure2 = NULL WHERE node_2 = OLD.node_id;

		RETURN NULL;
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

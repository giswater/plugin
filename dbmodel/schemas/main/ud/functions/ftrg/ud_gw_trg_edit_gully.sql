 /*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1206


CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_gully()  RETURNS trigger AS $BODY$
DECLARE
v_sql varchar;
v_count integer;
v_proximity_buffer double precision;
v_code_autofill_bool boolean;
v_link_path varchar;
v_record_link record;
v_record_vnode record;
v_man_table varchar;
v_customfeature text;
v_addfields record;
v_new_value_param text;
v_old_value_param text;
v_arg text;
v_doublegeometry boolean;
v_length float;
v_width float;
v_rotation float;
v_unitsfactor float;
v_linelocatepoint float;
v_thegeom public.geometry;
v_the_geom_pol public.geometry;
p21x float;
p02x float;
p21y float;
p02y float;
p22x float;
p22y float;
p01x float;
p01y float;
dx float;
dy float;
v_x float;
v_y float;
v_codeautofill boolean;
v_srid integer;
v_featurecat text;
v_psector_vdefault integer;
v_arc_id text;
v_autorotation_disabled boolean;
v_force_delete boolean;
v_autoupdate_fluid boolean;
v_matfromcat boolean = false;
v_epa_gully_efficiency  float;
v_epa_gully_method text;
v_epa_gully_orifice_cd float;
v_epa_gully_outlet_type text;
v_epa_gully_weir_cd float;
v_arc record;
v_link integer;
v_link_geom public.geometry;
v_connect2network boolean;
v_auto_streetvalues_status boolean;
v_auto_streetvalues_buffer integer;
v_auto_streetvalues_field text;
v_trace_featuregeom boolean;
v_gully_id text;
v_childtable_name text;
v_schemaname text;
v_featureclass text;
v_sys_code_autofill text;

v_district_ids _int4;

BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	-- get custom gully type
	v_man_table:= TG_ARGV[0];
    v_schemaname:= TG_TABLE_SCHEMA;

	IF v_man_table IN (SELECT id FROM cat_feature WHERE feature_type = 'GULLY') THEN
		v_customfeature:=v_man_table;
		v_man_table:=(SELECT man_table FROM cat_feature_gully c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id=v_man_table);
	END IF;

	IF v_customfeature='parent' THEN
		v_customfeature:=NULL;
	END IF;

	-- get system and user variables
	v_proximity_buffer = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_feature_buffer_on_mapzone');
	SELECT value::boolean INTO v_autoupdate_fluid FROM config_param_system WHERE parameter='edit_connect_autoupdate_fluid';

	v_autorotation_disabled = (SELECT value::boolean FROM config_param_user WHERE "parameter"='edit_gullyrotation_disable' AND cur_user=current_user);
	v_epa_gully_efficiency := (SELECT value FROM config_param_user WHERE parameter='epa_gully_efficiency_vdefault' AND cur_user=current_user);
	v_epa_gully_orifice_cd := (SELECT value FROM config_param_user WHERE parameter='epa_gully_orifice_cd_vdefault' AND cur_user=current_user);
	v_epa_gully_weir_cd := (SELECT value FROM config_param_user WHERE parameter='epa_gully_weir_cd_vdefault' AND cur_user=current_user);
	v_epa_gully_method := (SELECT value FROM config_param_user WHERE parameter='epa_gully_method_vdefault' AND cur_user=current_user);
	v_epa_gully_outlet_type := (SELECT value FROM config_param_user WHERE parameter='epa_gully_outlet_type_vdefault' AND cur_user=current_user);
	SELECT value::boolean INTO v_connect2network FROM config_param_user WHERE parameter='edit_gully_automatic_link' AND cur_user=current_user;
	v_auto_streetvalues_status := (SELECT (value::json->>'status')::boolean FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_buffer := (SELECT (value::json->>'buffer')::integer FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_field := (SELECT (value::json->>'field')::text FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_sys_code_autofill := (SELECT (value::json->>'gully')::text FROM config_param_system WHERE parameter = 'edit_sys_code_autofill');


	v_srid = (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1);

	IF v_proximity_buffer IS NULL THEN v_proximity_buffer=0.5; END IF;

	v_psector_vdefault = (SELECT config_param_user.value::integer AS value FROM config_param_user WHERE config_param_user.parameter::text
	= 'plan_psector_current'::text AND config_param_user.cur_user::name = "current_user"() LIMIT 1);

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		IF NEW.gullycat_id NOT IN (SELECT id FROM cat_gully WHERE gully_type = NEW.gully_type) AND NEW.gully_type IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	       		"data":{"message":"4464", "function":"1206","parameters":null, "is_process":true}}$$);';
		END IF;
		-- managing matcat
		IF (SELECT matcat_id FROM cat_gully WHERE id = NEW.gullycat_id) IS NOT NULL THEN
			v_matfromcat = true;
		END IF;

		-- managing gully_type
		IF NEW.gully_type IS NULL THEN

			SELECT gully_type INTO NEW.gully_type FROM cat_gully WHERE id = NEW.gullycat_id;

			IF NEW.gully_type IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3262", "function":"1206","parameters":null}}$$);';
			END IF;

		END IF;

		--check if feature is double geom
		EXECUTE 'SELECT json_extract_path_text(double_geom,''activated'')::boolean, json_extract_path_text(double_geom,''value'')  
		FROM cat_feature_gully WHERE id='||quote_literal(NEW.gully_type)||''
		INTO v_doublegeometry, v_unitsfactor;

		IF NEW.arc_id IS NOT NULL AND NEW.expl_id IS NOT NULL THEN
			IF (SELECT expl_id FROM arc WHERE arc_id = NEW.arc_id) != NEW.expl_id THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3144", "function":"1206","parameters":{"arc_id":"'||NEW.arc_id::text||'"}}}$$);';
			END IF;
		END IF;

	END IF;

	-- Control insertions ID
	IF TG_OP = 'INSERT' THEN

		-- setting psector vdefault as visible
		IF NEW.state = 2 THEN
			INSERT INTO selector_psector (psector_id, cur_user) VALUES (v_psector_vdefault, current_user)
			ON CONFLICT DO NOTHING;
		END IF;

		-- Gully ID
		IF NEW.gully_id != (SELECT last_value FROM urn_id_seq) OR NEW.gully_id IS NULL THEN
			NEW.gully_id = (SELECT nextval('urn_id_seq'));
		END IF;

		-- Gully Catalog ID
		IF (NEW.gullycat_id IS NULL OR NEW.gullycat_id = '') THEN
				NEW.gullycat_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_gullycat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		ELSE
			IF (SELECT true from cat_gully where id=NEW.gullycat_id) IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3282", "function":"1206","parameters":{"catalog_value":"'||NEW.gullycat_id||'"}}}$$);';
			END IF;
		END IF;

		-- Arc Catalog ID
		IF (NEW.connec_arccat_id IS NULL) THEN
			NEW.connec_arccat_id := (SELECT "value" FROM config_param_user WHERE "parameter"='connecarccat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;


		-- Exploitation
		IF (NEW.expl_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1110", "function":"1206","parameters":null}}$$);';
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
				"data":{"message":"2012", "function":"1206","parameters":{"feature_id":"'||NEW.gully_id::text||'"}}}$$);';
			END IF;
		END IF;


		-- Sector ID
		IF (NEW.sector_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM sector WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1008", "function":"1206","parameters":null}}$$);';
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
		       	"data":{"message":"1012", "function":"1206","parameters":null}}$$);';
			END IF;

			-- getting value default
			IF (NEW.omzone_id IS NULL) THEN
				NEW.omzone_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_omzone_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			-- getting value from geometry of mapzone
			IF (NEW.omzone_id IS NULL) THEN
				SELECT count(*) INTO v_count FROM omzone WHERE ST_DWithin(NEW.the_geom, omzone.the_geom,0.001) AND active IS TRUE ;
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
			"data":{"message":"3036", "function":"1206","parameters":{"state_id":"'||v_sql::text||'"}}}$$);';
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
				NEW.streetaxis_id = (select ve_streetaxis.id from ve_streetaxis
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

		--Publish
		IF NEW.publish IS NULL THEN
			NEW.publish := (SELECT "value" FROM config_param_system WHERE "parameter"='edit_publish_sysvdefault');
		END IF;

		--Uncertain
		IF NEW.uncertain IS NULL THEN
			NEW.uncertain := (SELECT "value" FROM config_param_system WHERE "parameter"='edit_uncertain_sysvdefault');
		END IF;

		-- Code
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		SELECT code_autofill, cat_feature.id, feature_class
		INTO v_code_autofill_bool, v_featurecat, v_featureclass
		FROM cat_feature WHERE id = NEW.gully_type;

		IF NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('feature', NEW.gully_type, json_strip_nulls(row_to_json(NEW)::json));

			IF NEW.code IS NULL AND v_code_autofill_bool THEN
				NEW.code := NEW.gully_id;
			END IF;
		END IF;

		IF NEW.sys_code IS NOT NULL AND v_sys_code_autofill NOT IN ('false', 'none') THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4678", "function":"1206"}}$$);';
		END IF;

		--Sys_code (uuid | code | none)
		IF v_sys_code_autofill IN ('uuid', 'true') THEN
			NEW.sys_code := gen_random_uuid();
		ELSIF v_sys_code_autofill = 'code' THEN
			NEW.sys_code := NEW.code;
		END IF;

		--Units
		IF (NEW.units IS NULL) THEN
			NEW.units :='1';
		END IF;

		--Inventory
		IF (NEW.inventory IS NULL) THEN
			NEW.inventory :='TRUE';
		END IF;

		-- LINK
		--google maps style
		IF (SELECT (value::json->>'google_maps')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=CONCAT ('https://www.google.com/maps/place/',(ST_Y(ST_transform(NEW.the_geom,4326))),'N+',(ST_X(ST_transform(NEW.the_geom,4326))),'E');
		--fid style
		ELSIF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=NEW.gully_id;
		END IF;


		--Location type
		IF NEW.location_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_location_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_location_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.location_type IS NULL THEN
			NEW.location_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_gully_location_vdefault' AND cur_user = current_user);
		END IF;

		--Fluid type
		IF v_autoupdate_fluid IS TRUE AND NEW.arc_id IS NOT NULL THEN
			NEW.fluid_type = (SELECT fluid_type FROM arc WHERE arc_id = NEW.arc_id);
		END IF;

		IF NEW.fluid_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_fluid_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_fluid_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.fluid_type IS NULL THEN
			NEW.fluid_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_gully_fluid_vdefault' AND cur_user = current_user);
		END IF;

		--Category type
		IF NEW.category_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_category_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_category_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.category_type IS NULL THEN
			NEW.category_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_gully_category_vdefault' AND cur_user = current_user);
		END IF;

		--Function type
		IF NEW.function_type IS NULL AND (SELECT value FROM config_param_user WHERE parameter = 'edit_feature_function_vdefault' AND cur_user = current_user)  = v_featurecat THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_featureval_function_vdefault' AND cur_user = current_user);
		END IF;

		IF NEW.function_type IS NULL THEN
			NEW.function_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_gully_function_vdefault' AND cur_user = current_user);
		END IF;

		-- Epa type
		IF (NEW.epa_type IS NULL) THEN
			NEW.epa_type:= (SELECT epa_default FROM cat_feature_gully WHERE cat_feature_gully.id=NEW.gully_type)::text;
		END IF;

		-- elevation from raster
		IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
		AND (NEW.top_elev IS NULL) AND
		(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_insert_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
			NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
				(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1) LIMIT 1);
		END IF;

		--set rotation field
		WITH index_query AS(
		SELECT ST_Distance(the_geom, NEW.the_geom) as distance, the_geom FROM arc WHERE state=1 ORDER BY the_geom <-> NEW.the_geom LIMIT 10)
		SELECT St_linelocatepoint(the_geom, St_closestpoint(the_geom, NEW.the_geom)), the_geom INTO v_linelocatepoint, v_thegeom FROM index_query ORDER BY distance LIMIT 1;
		IF v_linelocatepoint < 0.01 THEN
			v_rotation = st_azimuth (st_startpoint(v_thegeom), st_lineinterpolatepoint(v_thegeom,0.01));
		ELSIF v_linelocatepoint > 0.99 THEN
			v_rotation = st_azimuth (st_lineinterpolatepoint(v_thegeom,0.98), st_lineinterpolatepoint(v_thegeom,0.99));
		ELSE
			v_rotation = st_azimuth (st_lineinterpolatepoint(v_thegeom,v_linelocatepoint), st_lineinterpolatepoint(v_thegeom,v_linelocatepoint+0.01));
		END IF;

		-- use automatic rotation only on INSERT. On update it's only posible manual rotation update
		IF v_autorotation_disabled IS NULL OR v_autorotation_disabled IS FALSE THEN
			NEW.rotation = v_rotation*180/pi();
		END IF;

		v_rotation = -(v_rotation - pi()/2);

		-- double geometry
		IF v_doublegeometry AND NEW.gullycat_id IS NOT NULL THEN

			v_length = (SELECT length FROM cat_gully WHERE id=NEW.gullycat_id);
			v_width = (SELECT width FROM cat_gully WHERE id=NEW.gullycat_id);


			IF v_length*v_width IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3062", "function":"1206","parameters":{"gullycat_id":"'||NEW.gullycat_id::text||'"}}}$$);';

			ELSIF v_length*v_width != 0 THEN

				-- get grate dimensions
				v_unitsfactor = 0.01*v_unitsfactor ; -- using 0.01 to convert from cms of catalog  to meters of the map

				--multiply length x units if is not null
				IF NEW.units IS NOT NULL THEN
					v_length = v_length*v_unitsfactor*NEW.units;
				ELSE
					v_length = v_length*v_unitsfactor;
				END IF;

				v_width = v_width*v_unitsfactor;

				-- calculate center coordinates
				v_x = st_x(NEW.the_geom);
				v_y = st_y(NEW.the_geom);

				-- calculate dx & dy to fix extend from center
				dx = v_length/2;
				dy = v_width/2;

				-- calculate the extend polygon
				p01x = v_x - dx*cos(v_rotation)-dy*sin(v_rotation);
				p01y = v_y - dx*sin(v_rotation)+dy*cos(v_rotation);

				p02x = v_x + dx*cos(v_rotation)-dy*sin(v_rotation);
				p02y = v_y + dx*sin(v_rotation)+dy*cos(v_rotation);

				p21x = v_x - dx*cos(v_rotation)+dy*sin(v_rotation);
				p21y = v_y - dx*sin(v_rotation)-dy*cos(v_rotation);

				p22x = v_x + dx*cos(v_rotation)+dy*sin(v_rotation);
				p22y = v_y + dx*sin(v_rotation)-dy*cos(v_rotation);


				-- generating the geometry
				EXECUTE 'SELECT ST_Multi(ST_makePolygon(St_SetSrid(ST_GeomFromText(''LINESTRING(' || p21x ||' '|| p21y || ',' ||
					p22x ||' '|| p22y || ',' || p02x || ' ' || p02y || ','|| p01x ||' '|| p01y || ',' || p21x ||' '|| p21y || ')''),'||v_srid||')))'
					INTO v_the_geom_pol;

				INSERT INTO polygon(sys_type, the_geom, featurecat_id, feature_id, state)
				VALUES (v_featureclass, v_the_geom_pol, NEW.gully_type, NEW.gully_id, NEW.state);
			END IF;
		END IF;

		-- FEATURE INSERT
		IF v_matfromcat THEN

			INSERT INTO gully (gully_id, code, sys_code, top_elev, "ymax",sandbox, matcat_id, gully_type, gullycat_id, units, groove, _connec_arccat_id, connec_length,
				connec_depth, siphon, arc_id, sector_id, "state",state_type, annotation, "observ", "comment", omzone_id, soilcat_id, function_type,
				category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id,
				postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation,
				link,verified, the_geom,label_x, label_y,label_rotation, expl_id, publish, inventory,uncertain, num_value, brand_id, model_id,
				updated_at, updated_by, asset_id, epa_type, units_placement, groove_height, groove_length, expl_visibility, adate, adescript,
				siphon_type, odorflap, connec_y2, placement_type, label_quadrant, access_type, lock_level, length, width, drainzone_outfall, dwfzone_outfall, 
				omunit_id, dma_id, uuid, treatment_type, has_treatment, dataquality, dataquality_obs)
			VALUES (NEW.gully_id, NEW.code, NEW.sys_code, NEW.top_elev, NEW."ymax",NEW.sandbox, NEW.matcat_id, NEW.gully_type, NEW.gullycat_id, NEW.units, NEW.groove,
				NEW.connec_arccat_id, NEW.connec_length, NEW.connec_depth, NEW.siphon, NEW.arc_id, COALESCE(NEW.sector_id, 0), NEW."state",
				NEW.state_type, NEW.annotation, NEW."observ", NEW."comment", COALESCE(NEW.omzone_id, 0), NEW.soilcat_id, NEW.function_type, NEW.category_type,
				NEW.fluid_type, NEW.location_type, NEW.workcat_id, NEW.workcat_id_end, NEW.workcat_id_plan, NEW.builtdate, NEW.enddate,
				NEW.ownercat_id, COALESCE(NEW.muni_id, 0), NEW.postcode, NEW.district_id, NEW.streetaxis_id, NEW.postnumber, NEW.postcomplement, NEW.streetaxis2_id,
				NEW.postnumber2, NEW.postcomplement2, NEW.descript, NEW.rotation, NEW.link, NEW.verified, NEW.the_geom,
				NEW.label_x, NEW.label_y, NEW.label_rotation,  COALESCE(NEW.expl_id, 0) , NEW.publish, NEW.inventory,
				NEW.uncertain, NEW.num_value, NEW.brand_id, NEW.model_id, NEW.updated_at, NEW.updated_by, NEW.asset_id, NEW.epa_type, NEW.units_placement,
				NEW.groove_height, NEW.groove_length, NEW.expl_visibility, NEW.adate, NEW.adescript, NEW.siphon_type, NEW.odorflap,
				NEW.connec_y2, NEW.placement_type, NEW.label_quadrant, NEW.access_type, NEW.lock_level, NEW.length, NEW.width, NEW.drainzone_outfall, NEW.dwfzone_outfall, 
				COALESCE(NEW.omunit_id, 0), COALESCE(NEW.dma_id, 0), NEW.uuid, COALESCE(NEW.treatment_type, 0), NEW.has_treatment, NEW.dataquality, NEW.dataquality_obs);
		ELSE

			INSERT INTO gully (gully_id, code, sys_code, top_elev, "ymax",sandbox, matcat_id, gully_type, gullycat_id, units, groove, _connec_arccat_id, connec_length,
				connec_depth, siphon, arc_id, sector_id, "state",state_type, annotation, "observ", "comment", omzone_id, soilcat_id, function_type,
				category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id,
				postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation,
				link,verified, the_geom, label_x, label_y,label_rotation, expl_id, publish, inventory,uncertain, num_value, brand_id, model_id,
				updated_at, updated_by, asset_id, epa_type, units_placement, groove_height, groove_length, expl_visibility, adate, adescript,
				siphon_type, odorflap, connec_y2, placement_type, label_quadrant, access_type, lock_level, length, width, drainzone_outfall, dwfzone_outfall, 
				omunit_id, dma_id, uuid, treatment_type, has_treatment, dataquality, dataquality_obs)
			VALUES (NEW.gully_id, NEW.code, NEW.sys_code, NEW.top_elev, NEW."ymax",NEW.sandbox, NEW.matcat_id, NEW.gully_type, NEW.gullycat_id, NEW.units, NEW.groove,
				NEW.connec_arccat_id, NEW.connec_length, NEW.connec_depth, NEW.siphon, NEW.arc_id, COALESCE(NEW.sector_id, 0), NEW."state",
				NEW.state_type, NEW.annotation, NEW."observ", NEW."comment", COALESCE(NEW.omzone_id, 0), NEW.soilcat_id, NEW.function_type, NEW.category_type,
				NEW.fluid_type, NEW.location_type, NEW.workcat_id, NEW.workcat_id_end, NEW.workcat_id_plan, NEW.builtdate, NEW.enddate,
				NEW.ownercat_id, COALESCE(NEW.muni_id, 0), NEW.postcode, NEW.district_id, NEW.streetaxis_id, NEW.postnumber, NEW.postcomplement, NEW.streetaxis2_id,
				NEW.postnumber2, NEW.postcomplement2, NEW.descript, NEW.rotation, NEW.link, NEW.verified, NEW.the_geom,
				NEW.label_x, NEW.label_y, NEW.label_rotation,  COALESCE(NEW.expl_id, 0) , NEW.publish, NEW.inventory,
				NEW.uncertain, NEW.num_value, NEW.brand_id, NEW.model_id, NEW.updated_at, NEW.updated_by, NEW.asset_id,
				NEW.epa_type, NEW.units_placement, NEW.groove_height, NEW.groove_length, NEW.expl_visibility, NEW.adate, NEW.adescript,
				NEW.siphon_type, NEW.odorflap, NEW.connec_y2, NEW.placement_type, NEW.label_quadrant, NEW.access_type, NEW.lock_level, NEW.length, NEW.width, NEW.drainzone_outfall, NEW.dwfzone_outfall, 
				COALESCE(NEW.omunit_id, 0), COALESCE(NEW.dma_id, 0), NEW.uuid, COALESCE(NEW.treatment_type, 0), NEW.has_treatment, NEW.dataquality, NEW.dataquality_obs);

		END IF;

		IF v_man_table = 'man_ginlet' THEN
			INSERT INTO man_ginlet (gully_id) VALUES (NEW.gully_id);
		ELSIF v_man_table = 'man_vgully' THEN
			INSERT INTO man_vgully (gully_id) VALUES (NEW.gully_id);
		ELSIF v_man_table = 'parent' THEN
			v_man_table:= (SELECT man_table FROM cat_feature_gully c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id JOIN cat_gully ON cat_gully.id=NEW.gullycat_id
		    	WHERE c.id = cat_gully.gully_type LIMIT 1)::text;

			IF v_man_table IS NOT NULL THEN
			    v_sql:= 'INSERT INTO '||v_man_table||' (gully_id) VALUES ('||quote_literal(NEW.gully_id)||')';
			    EXECUTE v_sql;
			END IF;
		END IF;

		-- insertint on psector table and setting visible
		IF NEW.state=2 THEN
			INSERT INTO plan_psector_x_gully (gully_id, psector_id, state, doable, arc_id)
			VALUES (NEW.gully_id, v_psector_vdefault, 1, true, NEW.arc_id)
			ON CONFLICT (gully_id, psector_id, state) DO NOTHING;
		END IF;

		-- manage connect2network
		IF v_connect2network THEN

			IF NEW.arc_id IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":'|| array_to_json(array_agg(NEW.gully_id))||'},"data":{"feature_type":"GULLY", "forcedArcs":["'||NEW.arc_id||'"]}}$$)';
			ELSE
				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":'|| array_to_json(array_agg(NEW.gully_id))||'},"data":{"feature_type":"GULLY"}}$$)';
			END IF;

			-- recover values in order to do not disturb this workflow
			SELECT * INTO v_arc FROM arc WHERE arc_id = NEW.arc_id;
			NEW.pjoint_id = v_arc.arc_id; NEW.pjoint_type = 'ARC'; NEW.sector_id = v_arc.sector_id; NEW.omzone_id = v_arc.omzone_id;
		END IF;

		-- childtable insert
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='GULLY' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' ||v_addfields.param_name||'"'
					USING NEW
					INTO v_new_value_param;

				v_childtable_name := 'man_gully_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF v_new_value_param IS NOT NULL THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (gully_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (gully_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.gully_id=$1'
							USING NEW.gully_id, v_new_value_param;
					END IF;
				END IF;
			END LOOP;
		END IF;

		-- EPA INSERT
		IF (NEW.epa_type = 'GULLY') THEN
			INSERT INTO inp_gully (gully_id, outlet_type, gully_method, weir_cd, orifice_cd, efficiency)
			VALUES (NEW.gully_id, v_epa_gully_outlet_type, v_epa_gully_method, v_epa_gully_weir_cd, v_epa_gully_orifice_cd, v_epa_gully_efficiency);
		END IF;

		RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

		-- EPA update
		IF (OLD.epa_type = 'GULLY') AND (NEW.epa_type = 'UNDEFINED') THEN
			DELETE FROM inp_gully WHERE gully_id = OLD.gully_id;
		ELSIF (OLD.epa_type = 'UNDEFINED') AND (NEW.epa_type = 'GULLY') THEN
			INSERT INTO inp_gully (gully_id, outlet_type, gully_method, weir_cd, orifice_cd, efficiency)
			VALUES (NEW.gully_id, v_epa_gully_outlet_type, v_epa_gully_method, v_epa_gully_weir_cd, v_epa_gully_orifice_cd, v_epa_gully_efficiency);
		END IF;

		-- UPDATE geom
		UPDATE gully SET connec_length = NEW.connec_length WHERE gully_id = OLD.gully_id;
		IF st_equals(NEW.the_geom, OLD.the_geom)is false THEN
			UPDATE gully SET the_geom=NEW.the_geom WHERE gully_id = OLD.gully_id;

			--update elevation from raster
			IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
			 AND (NEW.top_elev = OLD.top_elev) AND
			(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_update_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
				NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
							(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1) LIMIT 1);
			END IF;

			--update associated geometry of element (if exists) and trace_featuregeom is true
			v_trace_featuregeom:= (SELECT trace_featuregeom FROM element JOIN element_x_gully USING (element_id)
                WHERE gully_id=NEW.gully_id AND the_geom IS NOT NULL LIMIT 1);
			-- if trace_featuregeom is false, do nothing
			IF v_trace_featuregeom IS TRUE THEN
			UPDATE ve_element SET the_geom = NEW.the_geom WHERE St_dwithin(OLD.the_geom, the_geom, 0.001)
				AND element_id IN (SELECT element_id FROM element_x_gully WHERE gully_id = NEW.gully_id);
			END IF;

		END IF;

		-- Reconnect arc_id
		IF (coalesce (NEW.arc_id,0) != coalesce(OLD.arc_id,0)) THEN

			-- when connec_id comes on psector_table
			IF NEW.state = 1 AND (SELECT gully_id FROM plan_psector_x_gully JOIN selector_psector USING (psector_id)
				WHERE gully_id=NEW.gully_id AND psector_id = v_psector_vdefault AND cur_user = current_user AND state = 1) IS NOT NULL THEN

				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":'|| array_to_json(array_agg(NEW.gully_id))||'},"data":{"feature_type":"GULLY", "forceEndPoint":"true", "forcedArcs":["'||NEW.arc_id||'"]}}$$)';

			ELSIF NEW.state = 2 THEN

				IF NEW.arc_id IS NOT NULL THEN

					IF (SELECT gully_id FROM plan_psector_x_gully JOIN selector_psector USING (psector_id)
						WHERE gully_id=NEW.gully_id AND psector_id = v_psector_vdefault AND cur_user = current_user AND state = 1) IS NOT NULL THEN

						EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
						"feature":{"id":'|| array_to_json(array_agg(NEW.gully_id))||'},"data":{"feature_type":"GULLY", "forceEndPoint":"true", "forcedArcs":["'||NEW.arc_id||'"]}}$$)';
					END IF;
				ELSE
					IF (SELECT link_id FROM plan_psector_x_gully JOIN selector_psector USING (psector_id)
						WHERE gully_id=NEW.gully_id AND psector_id = v_psector_vdefault AND cur_user = current_user AND state = 1) IS NOT NULL THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3206", "function":"1204","parameters":null}}$$);';
					ELSE
						UPDATE plan_psector_x_gully SET arc_id = null, link_id = null WHERE gully_id=NEW.gully_id AND psector_id = v_psector_vdefault AND state = 1;
					END IF;

					-- setting values
					NEW.sector_id = 0; NEW.omzone_id = 0; NEW.pjoint_id = null; NEW.pjoint_type = null;
				END IF;
			ELSE
				-- when arc_id comes from gully table
				UPDATE gully SET arc_id=NEW.arc_id where gully_id=NEW.gully_id;

				IF NEW.arc_id IS NOT NULL THEN

					-- when link exists
					IF (SELECT link_id FROM link WHERE state = 1 and feature_id =  NEW.gully_id) IS NOT NULL THEN
						EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
						"feature":{"id":'|| array_to_json(array_agg(NEW.gully_id))||'},"data":{"feature_type":"GULLY", "forceEndPoint":"true",  "forcedArcs":["'||NEW.arc_id||'"]}}$$)';
					END IF;

					-- recover values in order to do not disturb this workflow
					SELECT * INTO v_arc FROM arc WHERE arc_id = NEW.arc_id;
					NEW.pjoint_id = v_arc.arc_id; NEW.pjoint_type = 'ARC'; NEW.sector_id = v_arc.sector_id; NEW.omzone_id = v_arc.omzone_id;

				ELSE
					IF (SELECT count(*)FROM link WHERE feature_id = NEW.gully_id AND state = 1) > 0 THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3206", "function":"1206","parameters":null}}$$);';
					ELSE
						NEW.sector_id = 0; NEW.omzone_id = 0; NEW.pjoint_id = null; NEW.pjoint_type = null;
					END IF;
				END IF;
			END IF;
		END IF;

		IF NEW.top_elev IS NOT NULL THEN
			UPDATE link
			SET top_elev1 = NEW.top_elev
			WHERE link_id in (SELECT link_id FROM link WHERE feature_id = NEW.gully_id AND state = 1);
		END IF;

		-- State_type
		IF NEW.state=0 AND OLD.state=1 THEN
			IF (SELECT state FROM value_state_type WHERE id=NEW.state_type) != NEW.state THEN
			NEW.state_type=(SELECT "value" FROM config_param_user WHERE parameter='statetype_end_vdefault' AND "cur_user"="current_user"() LIMIT 1);
				IF NEW.state_type IS NULL THEN
				NEW.state_type=(SELECT id from value_state_type WHERE state=0 LIMIT 1);
					IF NEW.state_type IS NULL THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"2110", "function":"1206","parameters":null}}$$);';
					END IF;
				END IF;
			END IF;

			-- Automatic downgrade of associated link
			UPDATE link SET state=0 WHERE feature_id=OLD.gully_id;
		END IF;

		-- Looking for state control and insert planified connecs to default psector
		IF (NEW.state != OLD.state) THEN

			PERFORM gw_fct_state_control(json_build_object('parameters', json_build_object('feature_type_aux', 'GULLY', 'feature_id_aux', NEW.gully_id, 'state_aux', NEW.state, 'tg_op_aux', TG_OP)));

			IF NEW.state = 2 AND OLD.state=1 THEN

				v_link = (SELECT link_id FROM link WHERE feature_id = NEW.gully_id AND state = 1 LIMIT 1);

				INSERT INTO plan_psector_x_gully (gully_id, psector_id, state, doable, link_id, arc_id)
				VALUES (NEW.gully_id, v_psector_vdefault, 1, true,
				v_link, NEW.arc_id);

				UPDATE link SET state = 2 WHERE link_id  = v_link;
			END IF;

			IF NEW.state = 1 AND OLD.state=2 THEN

				v_link = (SELECT link_id FROM link WHERE feature_id = NEW.gully_id AND state = 2 LIMIT 1);

				-- force delete
				UPDATE config_param_user SET value = 'true' WHERE parameter = 'plan_psector_downgrade_feature' AND cur_user= current_user;
				DELETE FROM plan_psector_x_gully WHERE gully_id=NEW.gully_id;
				-- recover values
				UPDATE config_param_user SET value = 'false' WHERE parameter = 'plan_psector_downgrade_feature' AND cur_user= current_user;

				UPDATE link SET state = 1 WHERE link_id  = v_link;
			END IF;

			UPDATE gully SET state=NEW.state WHERE gully_id = OLD.gully_id;
		END IF;

		--check relation state - state_type
		IF (NEW.state_type != OLD.state_type) AND NEW.state_type NOT IN (SELECT id FROM value_state_type WHERE state = NEW.state) THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3036", "function":"1206","parameters":{"state_id":"'||NEW.state::text||'"}}}$$);';
		END IF;

		--link_path
		SELECT link_path INTO v_link_path FROM cat_feature WHERE id=NEW.gully_type;
		IF v_link_path IS NOT NULL THEN
			NEW.link = replace(NEW.link, v_link_path,'');
		END IF;


		-- calculate rotation
		IF v_doublegeometry AND ((ST_equals(NEW.the_geom, OLD.the_geom) IS FALSE) OR (NEW.gullycat_id != OLD.gullycat_id) OR (NEW.units <> OLD.units)) THEN
			WITH index_query AS(
			SELECT ST_Distance(the_geom, NEW.the_geom) as distance, the_geom FROM arc WHERE state=1 ORDER BY the_geom <-> NEW.the_geom LIMIT 10)
			SELECT St_linelocatepoint(the_geom, St_closestpoint(the_geom, NEW.the_geom)), the_geom INTO v_linelocatepoint, v_thegeom FROM index_query ORDER BY distance LIMIT 1;
			IF v_linelocatepoint < 0.01 THEN
				v_rotation = st_azimuth (st_startpoint(v_thegeom), st_lineinterpolatepoint(v_thegeom,0.01));
			ELSIF v_linelocatepoint > 0.99 THEN
				v_rotation = st_azimuth (st_lineinterpolatepoint(v_thegeom,0.98), st_lineinterpolatepoint(v_thegeom,0.99));
			ELSE
				v_rotation = st_azimuth (st_lineinterpolatepoint(v_thegeom,v_linelocatepoint), st_lineinterpolatepoint(v_thegeom,v_linelocatepoint+0.01));
			END IF;

			v_rotation = -(v_rotation - pi()/2);
		END IF;

		-- double geometry catalog update
		IF v_doublegeometry AND ((NEW.gullycat_id != OLD.gullycat_id) OR (NEW.units <> OLD.units)) THEN

			v_length = (SELECT length FROM cat_gully WHERE id=NEW.gullycat_id);
			v_width = (SELECT width FROM cat_gully WHERE id=NEW.gullycat_id);

				IF v_length*v_width IS NULL THEN

					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3062", "function":"1206","parameters":{"gullycat_id":"'||NEW.gullycat_id::text||'"}}}$$);';

				ELSIF v_length*v_width != 0 THEN

					-- get grate dimensions
					v_unitsfactor = 0.01*v_unitsfactor; -- using 0.01 to convert from cms of catalog  to meters of the map

                    --multiply length x units if is not null
                    IF NEW.units IS NOT NULL THEN
                        v_length = v_length*v_unitsfactor*NEW.units;
                    ELSE
                        v_length = v_length*v_unitsfactor;
                    END IF;

					v_width = v_width*v_unitsfactor;


					-- calculate center coordinates
					v_x = st_x(NEW.the_geom);
					v_y = st_y(NEW.the_geom);

					-- calculate dx & dy to fix extend from center
					dx = v_length/2;
					dy = v_width/2;

					-- calculate the extend polygon
					p01x = v_x - dx*cos(v_rotation)-dy*sin(v_rotation);
					p01y = v_y - dx*sin(v_rotation)+dy*cos(v_rotation);

					p02x = v_x + dx*cos(v_rotation)-dy*sin(v_rotation);
					p02y = v_y + dx*sin(v_rotation)+dy*cos(v_rotation);

					p21x = v_x - dx*cos(v_rotation)+dy*sin(v_rotation);
					p21y = v_y - dx*sin(v_rotation)-dy*cos(v_rotation);

					p22x = v_x + dx*cos(v_rotation)+dy*sin(v_rotation);
					p22y = v_y + dx*sin(v_rotation)-dy*cos(v_rotation);

					-- generating the geometry
					EXECUTE 'SELECT ST_Multi(ST_makePolygon(St_SetSrid(ST_GeomFromText(''LINESTRING(' || p21x ||' '|| p21y || ',' ||
						p22x ||' '|| p22y || ',' || p02x || ' ' || p02y || ','|| p01x ||' '|| p01y || ',' || p21x ||' '|| p21y || ')''),'||v_srid||')))'
						INTO v_the_geom_pol;

					IF (SELECT pol_id FROM polygon WHERE feature_id = NEW.gully_id) IS NULL THEN
						INSERT INTO polygon(sys_type, the_geom, featurecat_id, feature_id, state)
						VALUES (v_featureclass, v_the_geom_pol, NEW.gully_type, NEW.gully_id, NEW.state);
					ELSE
						UPDATE polygon SET the_geom = v_the_geom_pol WHERE feature_id =NEW.gully_id;
					END IF;
				END IF;
		END IF;

		--fluid_type
		IF v_autoupdate_fluid IS TRUE AND NEW.arc_id IS NOT NULL THEN
			NEW.fluid_type = (SELECT fluid_type FROM arc WHERE arc_id = NEW.arc_id);
		END IF;

		-- UPDATE values
		IF v_matfromcat THEN
			UPDATE gully
			SET code=NEW.code, sys_code=NEW.sys_code, top_elev=NEW.top_elev, ymax=NEW."ymax", sandbox=NEW.sandbox, matcat_id=NEW.matcat_id, gully_type=NEW.gully_type, gullycat_id=NEW.gullycat_id, units=NEW.units,
			groove=NEW.groove, _connec_arccat_id=NEW.connec_arccat_id, connec_depth=NEW.connec_depth, siphon=NEW.siphon, sector_id=NEW.sector_id,
			"state"=NEW."state",  state_type=NEW.state_type, annotation=NEW.annotation, "observ"=NEW."observ", "comment"=NEW."comment", omzone_id=NEW.omzone_id, soilcat_id=NEW.soilcat_id,
			function_type=NEW.function_type, category_type=NEW.category_type, fluid_type=NEW.fluid_type, location_type=NEW.location_type, workcat_id=NEW.workcat_id,
			workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan, builtdate=NEW.builtdate, enddate=NEW.enddate,
			ownercat_id=NEW.ownercat_id, postcode=NEW.postcode, district_id=NEW.district_id, streetaxis2_id=NEW.streetaxis2_id, postnumber2=NEW.postnumber2, postcomplement=NEW.postcomplement,
			postcomplement2=NEW.postcomplement2, descript=NEW.descript, rotation=NEW.rotation, link=NEW.link, verified=NEW.verified, pjoint_id=NEW.pjoint_id, pjoint_type = NEW.pjoint_type,
			label_x=NEW.label_x, label_y=NEW.label_y,label_rotation=NEW.label_rotation, publish=NEW.publish, inventory=NEW.inventory, muni_id=NEW.muni_id, streetaxis_id=NEW.streetaxis_id,
			postnumber=NEW.postnumber,  expl_id=NEW.expl_id, uncertain=NEW.uncertain, num_value=NEW.num_value, updated_at=now(), updated_by=current_user,
			asset_id=NEW.asset_id, epa_type=NEW.epa_type, units_placement=NEW.units_placement, groove_height=NEW.groove_height,
			groove_length=NEW.groove_length, expl_visibility=NEW.expl_visibility, adate=NEW.adate, adescript=NEW.adescript, siphon_type=NEW.siphon_type, odorflap=NEW.odorflap, connec_y2=NEW.connec_y2,
			placement_type=NEW.placement_type, label_quadrant=NEW.label_quadrant, access_type=NEW.access_type, lock_level=NEW.lock_level, length=NEW.length, width=NEW.width, drainzone_outfall=NEW.drainzone_outfall, 
			dwfzone_outfall=NEW.dwfzone_outfall, omunit_id=NEW.omunit_id, dma_id=NEW.dma_id, has_treatment=NEW.has_treatment, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
			WHERE gully_id = OLD.gully_id;

		ELSE
			UPDATE gully
			SET code=NEW.code, sys_code=NEW.sys_code, top_elev=NEW.top_elev, ymax=NEW."ymax", sandbox=NEW.sandbox, matcat_id=NEW.matcat_id, gully_type=NEW.gully_type, gullycat_id=NEW.gullycat_id, units=NEW.units,
			groove=NEW.groove, _connec_arccat_id=NEW.connec_arccat_id, connec_depth=NEW.connec_depth, siphon=NEW.siphon, sector_id=NEW.sector_id,
			"state"=NEW."state",  state_type=NEW.state_type, annotation=NEW.annotation, "observ"=NEW."observ", "comment"=NEW."comment", omzone_id=NEW.omzone_id, soilcat_id=NEW.soilcat_id,
			function_type=NEW.function_type, category_type=NEW.category_type, fluid_type=NEW.fluid_type, location_type=NEW.location_type, workcat_id=NEW.workcat_id,
			workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan, builtdate=NEW.builtdate, enddate=NEW.enddate,
			ownercat_id=NEW.ownercat_id, postcode=NEW.postcode, district_id=NEW.district_id, streetaxis2_id=NEW.streetaxis2_id, postnumber2=NEW.postnumber2, postcomplement=NEW.postcomplement,
			postcomplement2=NEW.postcomplement2, descript=NEW.descript, rotation=NEW.rotation, link=NEW.link, verified=NEW.verified, pjoint_id=NEW.pjoint_id, pjoint_type = NEW.pjoint_type,
			label_x=NEW.label_x, label_y=NEW.label_y,label_rotation=NEW.label_rotation, publish=NEW.publish, inventory=NEW.inventory, muni_id=NEW.muni_id, streetaxis_id=NEW.streetaxis_id,
			postnumber=NEW.postnumber,  expl_id=NEW.expl_id, uncertain=NEW.uncertain, num_value=NEW.num_value, updated_at=now(), updated_by=current_user,
			asset_id=NEW.asset_id, epa_type=NEW.epa_type, units_placement=NEW.units_placement, groove_height=NEW.groove_height,
			groove_length=NEW.groove_length, expl_visibility=NEW.expl_visibility, adate=NEW.adate, adescript=NEW.adescript, siphon_type=NEW.siphon_type, odorflap=NEW.odorflap, connec_y2=NEW.connec_y2,
			placement_type=NEW.placement_type, label_quadrant=NEW.label_quadrant, access_type=NEW.access_type, lock_level=NEW.lock_level, length=NEW.length, width=NEW.width, drainzone_outfall=NEW.drainzone_outfall, 
			dwfzone_outfall=NEW.dwfzone_outfall, omunit_id=NEW.omunit_id, dma_id=NEW.dma_id, has_treatment=NEW.has_treatment, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
			WHERE gully_id = OLD.gully_id;

		END IF;

		-- childtable update
		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='GULLY' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING NEW
					INTO v_new_value_param;

				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING OLD
					INTO v_old_value_param;



				v_childtable_name := 'man_gully_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF (v_new_value_param IS NOT NULL AND v_old_value_param!=v_new_value_param) OR (v_new_value_param IS NOT NULL AND v_old_value_param IS NULL) THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (gully_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (gully_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.gully_id=$1'
							USING NEW.gully_id, v_new_value_param;

					ELSIF v_new_value_param IS NULL AND v_old_value_param IS NOT NULL THEN
						EXECUTE 'UPDATE '||v_childtable_name||' SET '||v_addfields.param_name||' = null WHERE '||v_childtable_name||'.gully_id=$1'
							USING NEW.gully_id;
					END IF;
				END IF;
			END LOOP;
		END IF;

        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN

		EXECUTE 'SELECT gw_fct_getcheckdelete($${"client":{"device":4, "infoType":1, "lang":"ES"},
		"feature":{"id":"'||OLD.gully_id||'","featureType":"GULLY"}, "data":{}}$$)';

		-- delete from polygon table (before the deletion of gully)
		DELETE FROM polygon WHERE feature_id=OLD.gully_id AND sys_type='GULLY';

		-- force plan_psector_force_delete
		SELECT value INTO v_force_delete FROM config_param_user WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;
		UPDATE config_param_user SET value = 'true' WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		DELETE FROM gully WHERE gully_id = OLD.gully_id;

		-- restore plan_psector_force_delete
		UPDATE config_param_user SET value = v_force_delete WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		-- Delete childtable addfields (after or before deletion of gully, doesn't matter)
       	v_customfeature = old.gully_type;
		v_gully_id = old.gully_id;

		v_childtable_name := 'man_gully_' || lower(v_customfeature);
		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
	   		EXECUTE 'DELETE FROM '||v_childtable_name||' WHERE gully_id = '||quote_literal(v_gully_id)||'';
		END IF;

		-- delete links
		FOR v_record_link IN SELECT * FROM link WHERE feature_type='GULLY' AND feature_id=OLD.gully_id
		LOOP
			-- delete link
			DELETE FROM link WHERE link_id=v_record_link.link_id;

		END LOOP;

		RETURN NULL;

    END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

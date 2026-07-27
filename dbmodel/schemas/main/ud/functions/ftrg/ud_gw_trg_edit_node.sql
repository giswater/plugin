/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1220


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_edit_node()
  RETURNS trigger AS
$BODY$
DECLARE
v_inp_table varchar;
v_man_table varchar;
v_new_v_man_table varchar;
v_old_v_man_table varchar;
v_sql varchar;
v_type_v_man_table varchar;
v_code_autofill_bool boolean;
v_count integer;
v_proximity_buffer double precision;
v_link_path varchar;
v_doublegeom_buffer double precision;
v_addfields record;
v_new_value_param text;
v_old_value_param text;
v_customfeature text;
v_featurecat text;
v_matfromcat boolean = false;
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
v_force_delete boolean;
v_feature_class text;
v_psector integer;
v_trace_featuregeom boolean;

v_gully_outlet_type text;
v_gully_method text;
v_gully_weir_cd float;
v_gully_orifice_cd float;
v_gully_efficiency float;

v_auto_streetvalues_status boolean;
v_auto_streetvalues_buffer integer;
v_auto_streetvalues_field text;

-- automatic_man2inp_values
v_man_view text;
v_input json;
v_auto_sander boolean;
v_node_id text;

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

	-- modify values for custom view inserts
	IF v_man_table IN (SELECT id FROM cat_feature_node) THEN
		v_customfeature:=v_man_table;
		v_man_table:=(SELECT man_table FROM cat_feature_node c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id  WHERE c.id=v_man_table);
	END IF;

	v_type_v_man_table:=v_man_table;

	-- get data from config table
	v_proximity_buffer = (SELECT "value" FROM config_param_system WHERE "parameter"='edit_feature_buffer_on_mapzone');
	v_srid = (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1);

	SELECT value::boolean into v_auto_sander FROM config_param_system WHERE parameter='edit_node_automatic_sander';

	-- get user variables
	v_gully_outlet_type = (SELECT value FROM config_param_user WHERE parameter = 'epa_gully_outlet_type_vdefault' AND cur_user = current_user);
	v_gully_method = (SELECT value FROM config_param_user WHERE parameter = 'epa_gully_method_vdefault' AND cur_user = current_user);
	v_gully_weir_cd = (SELECT value FROM config_param_user WHERE parameter = 'epa_gully_weir_cd_vdefault' AND cur_user = current_user);
	v_gully_orifice_cd = (SELECT value FROM config_param_user WHERE parameter = 'epa_gully_orifice_cd_vdefault' AND cur_user = current_user);
	v_gully_efficiency = (SELECT value FROM config_param_user WHERE parameter = 'epa_gully_efficiency_vdefault' AND cur_user = current_user);
	v_psector = (SELECT value::integer FROM config_param_user WHERE "parameter"='plan_psector_current' AND cur_user=current_user);
	v_auto_streetvalues_status := (SELECT (value::json->>'status')::boolean FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_buffer := (SELECT (value::json->>'buffer')::integer FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_auto_streetvalues_field := (SELECT (value::json->>'field')::text FROM config_param_system WHERE parameter = 'edit_auto_streetvalues');
	v_sys_code_autofill := (SELECT (value::json->>'node')::text FROM config_param_system WHERE parameter = 'edit_sys_code_autofill');


	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		IF NEW.node_type IS NOT NULL THEN
			-- man2inp_values
			v_man_view  = (SELECT child_layer FROM cat_feature WHERE id = NEW.node_type);
			v_input = concat('{"feature":{"type":"node", "childLayer":"',v_man_view,'", "id":"',NEW.node_id,'"}}');

			IF NEW.nodecat_id NOT IN (SELECT id FROM cat_node WHERE node_type = NEW.node_type) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"4464", "function":"1220","parameters":null, "is_process":true}}$$);';
			END IF;

			--check if feature is double geom
			EXECUTE 'SELECT json_extract_path_text(double_geom,''activated'')::boolean, json_extract_path_text(double_geom,''value'')
			FROM cat_feature_node WHERE id='||quote_literal(NEW.node_type)||''
			INTO v_doublegeometry, v_doublegeom_buffer;
		END IF;

		-- managing matcat
		IF (SELECT matcat_id FROM cat_node WHERE id = NEW.nodecat_id) IS NOT NULL THEN
			v_matfromcat = true;
		END IF;
	END IF;

	-- manage netgully doublegeom in case of exists
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND v_doublegeometry AND v_man_table = 'man_netgully' THEN

		v_unitsfactor = v_doublegeom_buffer;

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

		NEW.rotation = v_rotation*180/pi();
		v_rotation = -(v_rotation - pi()/2);

		-- get gullycat dimensions
		v_length = (SELECT length FROM cat_gully WHERE id=NEW.gullycat_id);
		v_width = (SELECT width FROM cat_gully WHERE id=NEW.gullycat_id);

		-- control null grate dimensions
		IF v_length*v_width IS NULL OR v_length*v_width = 0 THEN -- use default values for node polygon
			v_length = v_doublegeom_buffer*100;
			v_width = v_doublegeom_buffer*100;
		END IF;

		-- transform grate dimensions
		v_unitsfactor = 0.01*v_unitsfactor ; -- using 0.01 to convert from cms of catalog  to meters of the map
		v_length = v_length*v_unitsfactor;
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
	END IF;

	-- Control insertions ID
	IF TG_OP = 'INSERT' THEN

		-- force current psector
		IF NEW.state = 2 THEN
			INSERT INTO selector_psector (psector_id, cur_user) VALUES (v_psector, current_user) ON CONFLICT DO NOTHING;
		END IF;

		-- Node ID
		IF NEW.node_id != (SELECT last_value FROM urn_id_seq) OR NEW.node_id IS NULL THEN
			NEW.node_id:= (SELECT nextval('urn_id_seq'));
		END IF;

		v_input = concat('{"feature":{"type":"node", "childLayer":"',v_man_view,'", "id":"',NEW.node_id,'"}}');

		-- Node type
		IF NEW.node_type IS NULL THEN
			IF ((SELECT COUNT(*) FROM cat_feature_node JOIN cat_feature USING (id) WHERE active IS TRUE)  = 0 ) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1004", "function":"1220","parameters":null}}$$);';
			END IF;

 			IF v_customfeature IS NOT NULL THEN
 				NEW.node_type:=v_customfeature;
 			END IF;

 			-- get it from relation on cat_node
 			IF NEW.node_type IS NULL THEN
				NEW.node_type:= (SELECT c.id FROM cat_feature_node c JOIN cat_node s ON c.id = s.node_type WHERE s.id=NEW.nodecat_id);
			END IF;

			-- get it from vdefault
			IF NEW.node_type IS NULL AND v_man_table='parent' THEN
				NEW.node_type:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_nodetype_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

			IF NEW.node_type IS NULL AND v_man_table !='parent' THEN
				NEW.node_type:= (SELECT id FROM cat_feature_node c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE man_table=v_type_v_man_table LIMIT 1);
			END IF;
		END IF;

		-- Epa type
		IF (NEW.epa_type IS NULL) THEN
			NEW.epa_type:= (SELECT epa_default FROM cat_feature_node WHERE id=NEW.node_type LIMIT 1)::text;
		END IF;

		-- Node catalog
		IF (NEW.nodecat_id IS NULL) THEN
			IF ((SELECT COUNT(*) FROM cat_node WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1006", "function":"1220","parameters":null}}$$);';
			END IF;
				NEW.nodecat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_nodecat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		ELSE
			IF (SELECT true from cat_node where id=NEW.nodecat_id) IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3282", "function":"1220","parameters":{"catalog_value":"'||NEW.nodecat_id||'"}}}$$);';
			END IF;
		END IF;

		-- Exploitation
		IF (NEW.expl_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1110", "function":"1220","parameters":null}}$$);';
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
				"data":{"message":"2012", "function":"1220","parameters":{"feature_id":"'||NEW.node_id::text||'"}}}$$);';
			END IF;
		END IF;

		-- Sector
		IF (NEW.sector_id IS NULL) THEN

			-- control error without any mapzones defined on the table of mapzone
			IF ((SELECT COUNT(*) FROM sector WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1008", "function":"1220","parameters":null}}$$);';
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
			IF ((SELECT COUNT(*) FROM omzone WHERE active IS TRUE ) = 0) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"1012", "function":"1220","parameters":null}}$$);';
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
			"data":{"message":"3036", "function":"1220","parameters":{"state_id":"'||v_sql::text||'"}}}$$);';
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

		SELECT code_autofill, cat_feature.id
		INTO v_code_autofill_bool, v_featurecat
		FROM cat_feature WHERE id = NEW.node_type;

		IF NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('feature', NEW.node_type, json_strip_nulls(row_to_json(NEW)::json));

			IF NEW.code IS NULL AND v_code_autofill_bool THEN
				NEW.code := NEW.node_id;
			END IF;
		END IF;

		IF NEW.sys_code IS NOT NULL AND v_sys_code_autofill NOT IN ('false', 'none') THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4678", "function":"1220"}}$$);';
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

		-- LINK
		--google maps style
		IF (SELECT (value::json->>'google_maps')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=CONCAT ('https://www.google.com/maps/place/',(ST_Y(ST_transform(NEW.the_geom,4326))),'N+',(ST_X(ST_transform(NEW.the_geom,4326))),'E');
		--fid style
		ELSIF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
			NEW.link=NEW.node_id;
		END IF;

		v_featurecat = NEW.node_type;

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

		-- Ymax
		IF (NEW.ymax IS NULL) THEN
		    NEW.ymax := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_node_ymax_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		--elevation from raster
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

		-- feature insert
		IF v_matfromcat THEN
			INSERT INTO node (node_id, code, sys_code, top_elev, custom_top_elev, ymax, elev, custom_elev, node_type,nodecat_id,epa_type,sector_id,"state", state_type, annotation,observ,"comment",
			omzone_id,soilcat_id, function_type, category_type,fluid_type,location_type,workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, conserv_state,
			muni_id, streetaxis_id, postcode, district_id, streetaxis2_id,postnumber, postnumber2, postcomplement, postcomplement2, descript,rotation,link,verified,
			label_x,label_y,label_rotation,the_geom, expl_id, publish, inventory, uncertain, xyz_date, unconnected, num_value, updated_at, updated_by,
			asset_id, parent_id, arc_id, expl_visibility, adate, adescript, placement_type, label_quadrant, access_type, brand_id, model_id, serial_number, lock_level, is_scadamap, pavcat_id, hemisphere,
			drainzone_outfall, dwfzone_outfall, dma_id, omunit_id, uuid, treatment_type, has_treatment, dataquality, dataquality_obs)
			VALUES (NEW.node_id, NEW.code, NEW.sys_code, NEW.top_elev,NEW.custom_top_elev, NEW.ymax, NEW. elev, NEW. custom_elev, NEW.node_type,NEW.nodecat_id,NEW.epa_type,COALESCE(NEW.sector_id, 0),
			NEW.state, NEW.state_type, NEW.annotation,NEW.observ, NEW.comment,COALESCE(NEW.omzone_id, 0),NEW.soilcat_id, NEW. function_type, NEW.category_type,COALESCE(NEW.fluid_type, 0),NEW.location_type,
			NEW.workcat_id, NEW.workcat_id_end, NEW.workcat_id_plan,NEW.builtdate, NEW.enddate, NEW.ownercat_id, NEW.conserv_state,
			COALESCE(NEW.muni_id, 0), NEW.streetaxis_id, NEW.postcode, NEW.district_id,NEW.streetaxis2_id,NEW.postnumber,NEW.postnumber2, NEW.postcomplement, NEW.postcomplement2,
			NEW.descript, NEW.rotation,NEW.link, NEW.verified, NEW.label_x,NEW.label_y,NEW.label_rotation,NEW.the_geom,
			COALESCE(NEW.expl_id, 0), NEW.publish, NEW.inventory, NEW.uncertain, NEW.xyz_date, NEW.unconnected, NEW.num_value, NEW.updated_at, NEW.updated_by,
			NEW.asset_id,  NEW.parent_id, NEW.arc_id, NEW.expl_visibility, NEW.adate, NEW.adescript, NEW.placement_type, NEW.label_quadrant,
			NEW.access_type, NEW.brand_id, NEW.model_id, NEW.serial_number, NEW.lock_level, NEW.is_scadamap, NEW.pavcat_id, NEW.hemisphere,
			NEW.drainzone_outfall, NEW.dwfzone_outfall, COALESCE(NEW.dma_id, 0), COALESCE(NEW.omunit_id, 0), NEW.uuid, COALESCE(NEW.treatment_type, 0), NEW.has_treatment, NEW.dataquality, NEW.dataquality_obs);
		ELSE
			INSERT INTO node (node_id, code, sys_code, top_elev, custom_top_elev, ymax, elev, custom_elev, node_type,nodecat_id,epa_type,sector_id,"state", state_type, annotation,observ,"comment",
			omzone_id,soilcat_id, function_type, category_type,fluid_type,location_type,workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, conserv_state,
			muni_id, streetaxis_id, postcode, district_id, streetaxis2_id,postnumber, postnumber2, postcomplement, postcomplement2, descript,rotation,link,verified,
			label_x,label_y,label_rotation,the_geom, expl_id, publish, inventory, uncertain, xyz_date, unconnected, num_value, updated_at, updated_by, matcat_id,
			asset_id, parent_id, arc_id, expl_visibility, adate, adescript, placement_type, label_quadrant, access_type, brand_id, model_id, serial_number, lock_level, is_scadamap, pavcat_id, hemisphere,
			drainzone_outfall, dwfzone_outfall, dma_id, omunit_id, uuid, treatment_type, has_treatment, dataquality, dataquality_obs)
			VALUES (NEW.node_id, NEW.code, NEW.sys_code, NEW.top_elev,NEW.custom_top_elev, NEW.ymax, NEW. elev, NEW. custom_elev, NEW.node_type,NEW.nodecat_id,NEW.epa_type,COALESCE(NEW.sector_id, 0),
			NEW.state, NEW.state_type, NEW.annotation,NEW.observ, NEW.comment,COALESCE(NEW.omzone_id, 0),NEW.soilcat_id, NEW. function_type, NEW.category_type,COALESCE(NEW.fluid_type, 0),NEW.location_type,
			NEW.workcat_id, NEW.workcat_id_end, NEW.workcat_id_plan,NEW.builtdate, NEW.enddate, NEW.ownercat_id, NEW.conserv_state,
			COALESCE(NEW.muni_id, 0), NEW.streetaxis_id, NEW.postcode, NEW.district_id, NEW.streetaxis2_id,NEW.postnumber,NEW.postnumber2, NEW.postcomplement, NEW.postcomplement2,
			NEW.descript, NEW.rotation,NEW.link, NEW.verified, NEW.label_x,NEW.label_y,NEW.label_rotation,NEW.the_geom,
			COALESCE(NEW.expl_id, 0), NEW.publish, NEW.inventory, NEW.uncertain, NEW.xyz_date, NEW.unconnected, NEW.num_value,  NEW.updated_at, NEW.updated_by,NEW.matcat_id,
			NEW.asset_id,  NEW.parent_id, NEW.arc_id, NEW.expl_visibility, NEW.adate, NEW.adescript, NEW.placement_type,
			NEW.label_quadrant, NEW.access_type, NEW.brand_id, NEW.model_id, NEW.serial_number, NEW.lock_level, NEW.is_scadamap, NEW.pavcat_id, NEW.hemisphere,
			NEW.drainzone_outfall, NEW.dwfzone_outfall, COALESCE(NEW.dma_id, 0), COALESCE(NEW.omunit_id, 0), NEW.uuid, COALESCE(NEW.treatment_type, 0), NEW.has_treatment, NEW.dataquality, NEW.dataquality_obs);
		END IF;

		-- insert into node_add
		INSERT INTO node_add (node_id, result_id, max_depth, max_height, flooding_rate, flooding_vol) VALUES (NEW.node_id, NEW.result_id, NEW.max_depth, NEW.max_height, NEW.flooding_rate, NEW.flooding_vol);

		-- Insert into visibility tables
		IF NEW.sector_visibility IS NOT NULL THEN
		    INSERT INTO node_x_sector_visibility (node_id, sector_id)
		    SELECT NEW.node_id, unnest(NEW.sector_visibility);
		END IF;

		IF NEW.muni_visibility IS NOT NULL THEN
		    INSERT INTO node_x_municipality_visibility (node_id, muni_id)
		    SELECT NEW.node_id, unnest(NEW.muni_visibility);
		END IF;

		--check if feature is double geom
		SELECT feature_class INTO v_feature_class FROM cat_feature WHERE cat_feature.id=NEW.node_type;

		-- set and get id for polygonFse
		IF (v_doublegeometry IS TRUE) THEN
			INSERT INTO polygon(sys_type, the_geom, featurecat_id, feature_id, state)
			VALUES (v_feature_class, (SELECT ST_Multi(ST_Envelope(ST_Buffer(node.the_geom,v_doublegeom_buffer)))
			from node where node_id=NEW.node_id), NEW.node_type, NEW.node_id, NEW.state);
		END IF;


		IF v_man_table='man_junction' THEN

			INSERT INTO man_junction (node_id) VALUES (NEW.node_id);

		ELSIF v_man_table='man_outfall' THEN

			INSERT INTO man_outfall (node_id, name, outfall_medium) VALUES (NEW.node_id,NEW.name, NEW.outfall_medium);

		ELSIF v_man_table='man_valve' THEN

			INSERT INTO man_valve (node_id, name, flowsetting, turns_count) VALUES (NEW.node_id,NEW.name, NEW.flowsetting, NEW.turns_count);

		ELSIF v_man_table='man_storage' THEN

			INSERT INTO man_storage (node_id, length, width, custom_area, max_volume, util_volume, min_height, accessibility, name)
			VALUES(NEW.node_id, NEW.length, NEW.width,NEW.custom_area, NEW.max_volume, NEW.util_volume, NEW.min_height,NEW.accessibility, NEW.name);

		ELSIF v_man_table='man_netgully' THEN

			INSERT INTO man_netgully (node_id,  sander_depth, gullycat_id, units, groove, siphon, gullycat2_id, groove_length, groove_height, units_placement)
			VALUES(NEW.node_id,  NEW.sander_depth, NEW.gullycat_id, NEW.units,
			NEW.groove, NEW.siphon, NEW.gullycat2_id, NEW.groove_length, NEW.groove_height, NEW.units_placement);

		ELSIF v_man_table='man_chamber' THEN

			INSERT INTO man_chamber (node_id, length, width, sander_depth, max_volume, util_volume, inlet, bottom_channel, accessibility, name, bottom_mat, slope, height)
			VALUES (NEW.node_id, NEW.length,NEW.width, NEW.sander_depth, NEW.max_volume, NEW.util_volume,
			NEW.inlet, NEW.bottom_channel, NEW.accessibility,NEW.name, NEW.bottom_mat, NEW.slope, NEW.height);

		ELSIF v_man_table='man_manhole' THEN

			INSERT INTO man_manhole (node_id,length, width, sander_depth, prot_surface, inlet, bottom_channel, accessibility, bottom_mat, height, manhole_code)
			VALUES (NEW.node_id,NEW.length, NEW.width, NEW.sander_depth,NEW.prot_surface, NEW.inlet, NEW.bottom_channel, NEW.accessibility,
			NEW.bottom_mat, NEW.height, NEW.manhole_code);

		ELSIF v_man_table='man_netinit' THEN

			INSERT INTO man_netinit (node_id,length, width, inlet, bottom_channel, accessibility, name, inlet_medium)
			VALUES (NEW.node_id, NEW.length,NEW.width,NEW.inlet, NEW.bottom_channel, NEW.accessibility, NEW.name, NEW.inlet_medium);

		ELSIF v_man_table='man_wjump' THEN

			INSERT INTO man_wjump (node_id, length, width,sander_depth,prot_surface, accessibility, name, wjump_code)
			VALUES (NEW.node_id, NEW.length,NEW.width, NEW.sander_depth,NEW.prot_surface,NEW.accessibility, NEW.name, NEW.wjump_code);

		ELSIF v_man_table='man_wwtp' THEN

			INSERT INTO man_wwtp (node_id, name, wwtp_code, wwtp_type, treatment_type, maxflow, opsflow, wwtp_function, served_hydrometer, efficiency, sludge_disposition, sludge_treatment)
			VALUES (NEW.node_id, NEW.name, NEW.wwtp_code, NEW.wwtp_type, NEW.treatment_type, NEW.maxflow, NEW.opsflow, NEW.wwtp_function, NEW.served_hydrometer, NEW.efficiency, NEW.sludge_disposition, NEW.sludge_treatment);

		ELSIF v_man_table='man_netelement' THEN

			INSERT INTO man_netelement (node_id) VALUES(NEW.node_id);

		ELSIF v_man_table='parent' THEN

			v_man_table:= (SELECT man_table FROM cat_feature_node c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id=NEW.node_type);
			v_sql:= 'INSERT INTO '||v_man_table||' (node_id) VALUES ('||quote_literal(NEW.node_id)||')';
			EXECUTE v_sql;
		END IF;

		--sander calculation
		IF (v_man_table='man_chamber' OR  v_man_table='man_manhole' OR  v_man_table='man_wjump') AND v_auto_sander IS TRUE THEN
			EXECUTE 'SELECT gw_fct_calculate_sander($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":"'||NEW.node_id||'"}}$$)';
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

		-- epa type
		IF (NEW.epa_type = 'JUNCTION') THEN
			INSERT INTO inp_junction (node_id, y0, ysur, apond) VALUES (NEW.node_id, 0, 0, 0);
		ELSIF (NEW.epa_type = 'DIVIDER') THEN
			INSERT INTO inp_divider (node_id, divider_type) VALUES (NEW.node_id, 'CUTOFF');
		ELSIF (NEW.epa_type = 'OUTFALL') THEN
			INSERT INTO inp_outfall (node_id, outfall_type) VALUES (NEW.node_id, 'NORMAL');
		ELSIF (NEW.epa_type = 'STORAGE') THEN
			INSERT INTO inp_storage (node_id, storage_type) VALUES (NEW.node_id, 'TABULAR');
		ELSIF (NEW.epa_type = 'NETGULLY') THEN
			INSERT INTO inp_netgully (node_id, y0, ysur, apond, outlet_type, gully_method, weir_cd, orifice_cd, efficiency)
			VALUES (NEW.node_id, 0, 0, 0, v_gully_outlet_type, v_gully_method, v_gully_weir_cd, v_gully_orifice_cd, v_gully_efficiency);
		ELSIF (NEW.epa_type = 'INLET') THEN
			INSERT INTO inp_inlet (node_id, y0, ysur, apond, inlet_type, outlet_type, gully_method, custom_top_elev, custom_depth, inlet_length, inlet_width, cd1, cd2, efficiency)
			VALUES (NEW.node_id, 0, 0, 0, 'GULLY', v_gully_outlet_type, v_gully_method, 0, 0, 0, 0, 0, 0, 0);
		END IF;

		-- man2inp_values
		PERFORM gw_fct_man2inp_values(v_input);

		RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

		-- epa type
		IF (NEW.epa_type != OLD.epa_type) THEN
			IF (OLD.epa_type = 'JUNCTION') THEN
				v_inp_table:= 'inp_junction';
			ELSIF (OLD.epa_type = 'DIVIDER') THEN
				v_inp_table:= 'inp_divider';
			ELSIF (OLD.epa_type = 'OUTFALL') THEN
				v_inp_table:= 'inp_outfall';
			ELSIF (OLD.epa_type = 'STORAGE') THEN
				v_inp_table:= 'inp_storage';
			ELSIF (OLD.epa_type = 'NETGULLY') THEN
				v_inp_table:= 'inp_netgully';
			ELSIF (OLD.epa_type = 'INLET') THEN
				v_inp_table:= 'inp_inlet';
			END IF;

			IF v_inp_table IS NOT NULL THEN
				v_sql:= 'DELETE FROM '||v_inp_table||' WHERE node_id = '||quote_literal(OLD.node_id);
				EXECUTE v_sql;
			END IF;

			v_inp_table := NULL;

			IF (NEW.epa_type = 'JUNCTION') THEN
				v_inp_table:= 'inp_junction';
			ELSIF (NEW.epa_type = 'DIVIDER') THEN
				v_inp_table:= 'inp_divider';
			ELSIF (NEW.epa_type = 'OUTFALL') THEN
				v_inp_table:= 'inp_outfall';
			ELSIF (NEW.epa_type = 'STORAGE') THEN
				v_inp_table:= 'inp_storage';
			ELSIF (NEW.epa_type = 'NETGULLY') THEN
				v_inp_table:= 'inp_netgully';
			ELSIF (NEW.epa_type = 'INLET') THEN
				v_inp_table:= 'inp_inlet';
			END IF;
			IF v_inp_table IS NOT NULL THEN
				v_sql:= 'INSERT INTO '||v_inp_table||' (node_id) VALUES ('||quote_literal(NEW.node_id)||') ON CONFLICT (node_id) DO NOTHING';
				EXECUTE v_sql;

				IF (NEW.epa_type = 'NETGULLY') THEN
					UPDATE inp_netgully SET outlet_type = v_gully_outlet_type, gully_method = v_gully_method, weir_cd = v_gully_weir_cd,
					orifice_cd = v_gully_orifice_cd, efficiency = v_gully_efficiency
					WHERE node_id = OLD.node_id;

				END IF;

			END IF;
		END IF;

		-- node type
		IF (NEW.node_type <> OLD.node_type) THEN
			v_new_v_man_table:= (SELECT man_table FROM cat_feature_node c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id = NEW.node_type);
			v_old_v_man_table:= (SELECT man_table FROM cat_feature_node c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE c.id = OLD.node_type);
			IF v_new_v_man_table IS NOT NULL THEN
				v_sql:= 'DELETE FROM '||v_old_v_man_table||' WHERE node_id= '||quote_literal(OLD.node_id);
				EXECUTE v_sql;
				v_sql:= 'INSERT INTO '||v_new_v_man_table||' (node_id) VALUES ('||quote_literal(NEW.node_id)||')';
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
			"data":{"message":"2110", "function":"1220","parameters":null}}$$);';
					END IF;
				END IF;
			END IF;
		END IF;

		--check relation state - state_type
		IF (NEW.state_type != OLD.state_type) AND NEW.state_type NOT IN (SELECT id FROM value_state_type WHERE state = NEW.state) THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3036", "function":"1220","parameters":{"state_id":"'||NEW.state::text||'"}}}$$);';
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
		IF st_equals( NEW.the_geom, OLD.the_geom) IS FALSE AND geometrytype(NEW.the_geom)='POINT'  THEN
			UPDATE node SET the_geom=NEW.the_geom WHERE node_id = OLD.node_id;

			--update elevation from raster
			IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
			AND (NEW.top_elev = OLD.top_elev) AND
			(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_update_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
				NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
							(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1) LIMIT 1);
			END IF;

			--update associated geometry of element (if exists) and trace_featuregeom is true
			v_trace_featuregeom:= (SELECT trace_featuregeom FROM element JOIN element_x_node USING (element_id)
                WHERE node_id=NEW.node_id AND the_geom IS NOT NULL LIMIT 1);
			-- if trace_featuregeom is false, do nothing
			IF v_trace_featuregeom IS TRUE THEN
			UPDATE ve_element SET the_geom = NEW.the_geom WHERE St_dwithin(OLD.the_geom, the_geom, 0.001)
				AND element_id IN (SELECT element_id FROM element_x_node WHERE node_id = NEW.node_id);
			END IF;

		ELSIF st_equals( NEW.the_geom, OLD.the_geom) IS FALSE AND geometrytype(NEW.the_geom)='MULTIPOLYGON'  THEN
			UPDATE polygon SET the_geom=NEW.the_geom WHERE pol_id = OLD.pol_id;
		END IF;

		--link_path
		SELECT link_path INTO v_link_path FROM cat_feature WHERE id=NEW.node_type;
		IF v_link_path IS NOT NULL THEN
			NEW.link = replace(NEW.link, v_link_path,'');
		END IF;

		IF NEW.rotation != OLD.rotation THEN
			UPDATE node SET rotation=NEW.rotation WHERE node_id = OLD.node_id;
		END IF;

		-- Update of topocontrol fields only when one if it has changed in order to prevent to be triggered the topocontrol without changes
		IF  (NEW.top_elev IS DISTINCT FROM OLD.top_elev) OR
			(NEW.custom_top_elev IS DISTINCT FROM OLD.custom_top_elev) OR
			(NEW.ymax IS DISTINCT FROM OLD.ymax) OR
			(NEW.elev IS DISTINCT FROM OLD.elev) OR
			(NEW.custom_elev IS DISTINCT FROM OLD.custom_elev) THEN
				UPDATE	node SET top_elev=NEW.top_elev, custom_top_elev=NEW.custom_top_elev, ymax=NEW.ymax, elev=NEW.elev, custom_elev=NEW.custom_elev
				WHERE node_id = OLD.node_id;
		END IF;

		IF v_matfromcat THEN
			UPDATE node
			SET code=NEW.code, sys_code=NEW.sys_code, node_type=NEW.node_type, nodecat_id=NEW.nodecat_id, epa_type=NEW.epa_type, sector_id=NEW.sector_id, state_type=NEW.state_type, annotation=NEW.annotation,
			"observ"=NEW.observ, "comment"=NEW.comment, omzone_id=NEW.omzone_id, soilcat_id=NEW.soilcat_id, function_type=NEW.function_type, category_type=NEW.category_type,fluid_type=COALESCE(NEW.fluid_type, 0),
			location_type=NEW.location_type, workcat_id=NEW.workcat_id, workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan, builtdate=NEW.builtdate, enddate=NEW.enddate,
			ownercat_id=NEW.ownercat_id, conserv_state=NEW.conserv_state, postcomplement=NEW.postcomplement, postcomplement2=NEW.postcomplement2, muni_id=NEW.muni_id,
			streetaxis_id=NEW.streetaxis_id, postcode=NEW.postcode, district_id=NEW.district_id,
			streetaxis2_id=NEW.streetaxis2_id, postnumber=NEW.postnumber, postnumber2=NEW.postnumber2, descript=NEW.descript, link=NEW.link, verified=NEW.verified,
			label_x=NEW.label_x, label_y=NEW.label_y, label_rotation=NEW.label_rotation, publish=NEW.publish, inventory=NEW.inventory, rotation=NEW.rotation, uncertain=NEW.uncertain,
			xyz_date=NEW.xyz_date, unconnected=NEW.unconnected, expl_id=NEW.expl_id, num_value=NEW.num_value, updated_at=now(), updated_by=current_user,
			asset_id=NEW.asset_id, parent_id=NEW.parent_id, arc_id = NEW.arc_id, expl_visibility=NEW.expl_visibility, adate=NEW.adate, adescript=NEW.adescript,
			placement_type=NEW.placement_type, label_quadrant=NEW.label_quadrant,
			access_type=NEW.access_type, brand_id=NEW.brand_id, model_id=NEW.model_id, serial_number=NEW.serial_number, lock_level=NEW.lock_level, is_scadamap=NEW.is_scadamap,
			pavcat_id=NEW.pavcat_id, drainzone_outfall=NEW.drainzone_outfall, dwfzone_outfall=NEW.dwfzone_outfall, dma_id=NEW.dma_id, omunit_id=NEW.omunit_id, has_treatment=NEW.has_treatment, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
			WHERE node_id = OLD.node_id;
		ELSE
			UPDATE node
			SET code=NEW.code, sys_code=NEW.sys_code, node_type=NEW.node_type, nodecat_id=NEW.nodecat_id, epa_type=NEW.epa_type, sector_id=NEW.sector_id, state_type=NEW.state_type, annotation=NEW.annotation,
			"observ"=NEW.observ, "comment"=NEW.comment, omzone_id=NEW.omzone_id, soilcat_id=NEW.soilcat_id, function_type=NEW.function_type, category_type=NEW.category_type,fluid_type=COALESCE(NEW.fluid_type, 0),
			location_type=NEW.location_type, workcat_id=NEW.workcat_id, workcat_id_end=NEW.workcat_id_end, workcat_id_plan=NEW.workcat_id_plan, builtdate=NEW.builtdate, enddate=NEW.enddate,
			ownercat_id=NEW.ownercat_id, conserv_state=NEW.conserv_state, postcomplement=NEW.postcomplement, postcomplement2=NEW.postcomplement2, muni_id=NEW.muni_id,
			streetaxis_id=NEW.streetaxis_id, postcode=NEW.postcode, district_id=NEW.district_id,
			streetaxis2_id=NEW.streetaxis2_id, postnumber=NEW.postnumber, postnumber2=NEW.postnumber2, descript=NEW.descript, link=NEW.link, verified=NEW.verified,
			label_x=NEW.label_x, label_y=NEW.label_y, label_rotation=NEW.label_rotation, publish=NEW.publish, inventory=NEW.inventory, rotation=NEW.rotation, uncertain=NEW.uncertain,
			xyz_date=NEW.xyz_date, unconnected=NEW.unconnected, expl_id=NEW.expl_id, num_value=NEW.num_value, updated_at=now(), updated_by=current_user, matcat_id = NEW.matcat_id,
			asset_id=NEW.asset_id, parent_id=NEW.parent_id, arc_id = NEW.arc_id, expl_visibility=NEW.expl_visibility, adate=NEW.adate, adescript=NEW.adescript,
			placement_type=NEW.placement_type, label_quadrant=NEW.label_quadrant, access_type=NEW.access_type, brand_id=NEW.brand_id, model_id=NEW.model_id, serial_number=NEW.serial_number,
			lock_level=NEW.lock_level, is_scadamap=NEW.is_scadamap, pavcat_id=NEW.pavcat_id, drainzone_outfall=NEW.drainzone_outfall, dwfzone_outfall=NEW.dwfzone_outfall, dma_id=NEW.dma_id, omunit_id=NEW.omunit_id, has_treatment=NEW.has_treatment, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
			WHERE node_id = OLD.node_id;
		END IF;

		-- update node_add table
		UPDATE node_add SET node_id=NEW.node_id, result_id=NEW.result_id, max_depth=NEW.max_depth, max_height=NEW.max_height, flooding_rate=NEW.flooding_rate, flooding_vol=NEW.flooding_vol
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

		ELSIF v_man_table='man_netgully' THEN

			-- update geom polygon
			IF NEW.gullycat_id != OLD.gullycat_id OR OLD.gullycat_id IS NULL THEN
				UPDATE polygon SET the_geom = v_the_geom_pol WHERE feature_id = NEW.node_id;
			END IF;

			UPDATE man_netgully SET sander_depth=NEW.sander_depth, gullycat_id=NEW.gullycat_id, units=NEW.units, groove=NEW.groove, siphon=NEW.siphon,
			gullycat2_id=NEW.gullycat2_id, groove_length=NEW.groove_length, groove_height=NEW.groove_height, units_placement=NEW.units_placement
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_outfall' THEN
			UPDATE man_outfall SET name=NEW.name, outfall_medium=NEW.outfall_medium
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_storage' THEN
			UPDATE man_storage SET length=NEW.length, width=NEW.width, custom_area=NEW.custom_area,
			max_volume=NEW.max_volume, util_volume=NEW.util_volume,min_height=NEW.min_height,
			accessibility=NEW.accessibility, name=NEW.name
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_valve' THEN
			UPDATE man_valve SET name=NEW.name, flowsetting=NEW.flowsetting
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_chamber' THEN
			UPDATE man_chamber SET length=NEW.length, width=NEW.width, sander_depth=NEW.sander_depth, max_volume=NEW.max_volume, util_volume=NEW.util_volume,
			inlet=NEW.inlet, bottom_channel=NEW.bottom_channel, accessibility=NEW.accessibility, name=NEW.name, bottom_mat=NEW.bottom_mat, slope=NEW.slope,
			height=NEW.height
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_manhole' THEN
			UPDATE man_manhole SET length=NEW.length, width=NEW.width, sander_depth=NEW.sander_depth, prot_surface=NEW.prot_surface,
			inlet=NEW.inlet, bottom_channel=NEW.bottom_channel, accessibility=NEW.accessibility,
			bottom_mat=NEW.bottom_mat, height=NEW.height, manhole_code=NEW.manhole_code
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_netinit' THEN
			UPDATE man_netinit SET length=NEW.length, width=NEW.width, inlet=NEW.inlet, bottom_channel=NEW.bottom_channel, accessibility=NEW.accessibility, name=NEW.name,
			inlet_medium=NEW.inlet_medium
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_wjump' THEN
			UPDATE man_wjump SET length=NEW.length, width=NEW.width, sander_depth=NEW.sander_depth, prot_surface=NEW.prot_surface, accessibility=NEW.accessibility, name=NEW.name,
			wjump_code=NEW.wjump_code
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table='man_wwtp' THEN
			UPDATE man_wwtp SET name=NEW.name, wwtp_code=NEW.wwtp_code, wwtp_type=NEW.wwtp_type, treatment_type=NEW.treatment_type, maxflow=NEW.maxflow, opsflow=NEW.opsflow, wwtp_function=NEW.wwtp_function,
			served_hydrometer=NEW.served_hydrometer, efficiency=NEW.efficiency, sludge_disposition=NEW.sludge_disposition, sludge_treatment=NEW.sludge_treatment
			WHERE node_id=OLD.node_id;

		ELSIF v_man_table ='man_netelement' THEN
			UPDATE man_netelement SET node_id=NEW.node_id
			WHERE node_id=OLD.node_id;
		END IF;

		--sander calculation
		IF (v_man_table='man_chamber' OR  v_man_table='man_manhole' OR  v_man_table='man_wjump') AND v_auto_sander IS TRUE THEN
			EXECUTE 'SELECT gw_fct_calculate_sander($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":"'||NEW.node_id||'"}}$$)';
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


		-- set label_quadrant, label_x and label_y according to cat_feature

		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>0
		FROM cat_feature WHERE id = '||quote_literal(new.node_type)||'
		' INTO v_dist_xlab;

		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>1
		FROM cat_feature WHERE id = '||quote_literal(new.node_type)||'
		' INTO v_dist_ylab;

		if new.label_x != old.label_x and new.label_y != old.label_y then

			update node set label_x = new.label_x, label_y = new.label_y where node_id = new.node_id;

			v_dist_ylab = null;
			v_dist_xlab = null;

		end if;

		if new.label_rotation != old.label_rotation then

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

	ELSIF TG_OP = 'DELETE' THEN

		EXECUTE 'SELECT gw_fct_getcheckdelete($${"client":{"device":4, "infoType":1, "lang":"ES"},
		"feature":{"id":"'||OLD.node_id||'","featureType":"NODE"}, "data":{}}$$)';

		-- delete from polygon table (before the deletion of node)
		DELETE FROM polygon WHERE feature_id=OLD.node_id;

		-- force plan_psector_force_delete
		SELECT value INTO v_force_delete FROM config_param_user WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;
		UPDATE config_param_user SET value = 'true' WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		-- delete from note table
		DELETE FROM node WHERE node_id = OLD.node_id;

		-- restore plan_psector_force_delete
		UPDATE config_param_user SET value = v_force_delete WHERE parameter = 'plan_psector_force_delete' and cur_user = current_user;

		-- Delete childtable addfields (after or before deletion of node, doesn't matter)
		v_customfeature = old.node_type;
		v_node_id = old.node_id;

		v_childtable_name := 'man_node_' || lower(v_customfeature);
		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
	   		EXECUTE 'DELETE FROM '||v_childtable_name||' WHERE node_id = '||quote_literal(v_node_id)||'';
		END IF;

		RETURN NULL;
	END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

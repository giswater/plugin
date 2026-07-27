/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1114


-- DROP FUNCTION "SCHEMA_NAME".gw_trg_edit_element();

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_element()
RETURNS trigger AS
$BODY$
DECLARE

v_code_autofill_bool boolean;
v_featurecat text;
v_doublegeometry boolean;
v_insert_double_geom boolean;
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
v_pol_id varchar(16);
v_srid integer;
v_project_type text;

v_feature text;
v_tablefeature text;
v_element_type text;
v_trace_featuregeom boolean;

--
v_origin_table TEXT;
v_parent_table TEXT;
v_json_new_data JSON;
v_sql TEXT;
v_rec_sentence record;
v_tg_table_name TEXT;
v_epa_type text;
v_result text;
v_input_json JSON;
v_result_rec record;
v_json_old_data JSON;

--
v_man_table TEXT;
v_customfeature TEXT;
v_childtable_name TEXT;
v_element_id TEXT;
v_feature_type TEXT;
v_length_arc numeric;
v_inp_table TEXT;

--
v_new_data jsonb;
v_feature_id_name TEXT;
v_uuid_column TEXT;
v_uuid_value uuid;
v_feature_id TEXT;

v_addfields record;
v_new_value_param TEXT;
v_old_value_param TEXT;
BEGIN

	v_tg_table_name = TG_TABLE_NAME;
	v_man_table:= TG_ARGV[0];

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- get values
	SELECT ((value::json)->>'activated')::boolean INTO v_insert_double_geom FROM config_param_system WHERE parameter='edit_element_doublegeom';
	SELECT ((value::json)->>'value')::float INTO v_unitsfactor FROM config_param_system WHERE parameter='edit_element_doublegeom';

	v_srid = (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1);
	v_project_type = (SELECT project_type FROM sys_version ORDER BY id DESC LIMIT 1);

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- get feature_type and man_table dynamically
        EXECUTE '
        SELECT lower(feature_type) FROM cat_feature WHERE child_layer = '||quote_literal(v_tg_table_name)||' OR parent_layer = '||quote_literal(v_tg_table_name)||' LIMIT 1'
        INTO v_feature_type;

		IF v_feature_type IS NULL THEN
			v_feature_type := 'element';
		END IF;


        --modify values for custom view inserts
        IF v_man_table IN (SELECT id FROM cat_feature WHERE feature_type = 'ELEMENT') THEN
            v_customfeature:=v_man_table;
            v_man_table:=(SELECT man_table FROM cat_feature_element c JOIN cat_feature cf ON cf.id = c.id JOIN sys_feature_class s ON cf.feature_class = s.id  WHERE c.id=v_man_table);
        END IF;

        IF v_unitsfactor IS NULL THEN
            v_unitsfactor = 1;
        END IF;

		IF v_man_table='man_frelem' THEN
			v_length_arc := (SELECT ST_Length(the_geom) FROM arc WHERE arc_id = NEW.to_arc);
			IF v_length_arc < NEW.flwreg_length THEN
				RAISE EXCEPTION 'Element is longer than to_arc length';
			END IF;
		END IF;

        -- get element_type and associated feature
        SELECT element_type INTO v_element_type FROM cat_element WHERE id=NEW.elementcat_id;
		SELECT node_id, 'node'::text INTO v_feature, v_tablefeature FROM ve_node WHERE st_dwithin(the_geom, NEW.the_geom, 0.01);
		IF v_feature IS NULL THEN
			SELECT connec_id, 'connec'::text INTO v_feature, v_tablefeature FROM ve_connec WHERE st_dwithin(the_geom, NEW.the_geom, 0.01);
			IF v_feature IS NULL THEN
				SELECT arc_id, 'arc'::text INTO v_feature, v_tablefeature FROM ve_arc WHERE st_dwithin(the_geom, NEW.the_geom, 0.01);
				IF v_feature IS NULL AND v_project_type='UD' THEN
					SELECT gully_id, 'gully'::text INTO v_feature, v_tablefeature FROM ve_gully WHERE st_dwithin(the_geom, NEW.the_geom, 0.01);
				END IF;
			END IF;
		END IF;

		-- Muni ID
		IF (NEW.muni_id IS NULL) THEN
			NEW.muni_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_municipality_vdefault' AND "cur_user"="current_user"());
			IF (NEW.muni_id IS NULL AND NEW.the_geom IS NOT NULL) THEN
				NEW.muni_id := (SELECT m.muni_id FROM v_municipality m WHERE ST_intersects(NEW.the_geom, m.the_geom) AND active IS TRUE limit 1);
			END IF;
		END IF;

	END IF;

	-- INSERT
	IF TG_OP = 'INSERT' THEN

		-- element_id
		IF NEW.element_id != (SELECT last_value FROM urn_id_seq) THEN
			NEW.element_id = (SELECT nextval('urn_id_seq'));
		END IF;

		-- Cat element
		IF (NEW.elementcat_id IS NULL) THEN
			NEW.elementcat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_elementcat_vdefault' AND "cur_user"="current_user"() LIMIT 1);

			IF v_customfeature IS NOT NULL THEN
				NEW.elementcat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"=lower(concat(v_customfeature,'_vdefault')) AND "cur_user"="current_user"() LIMIT 1);
			ELSE
				NEW.elementcat_id:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_elementcat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
			END IF;

		ELSE
			SELECT element_type INTO v_customfeature FROM cat_element WHERE id = NEW.elementcat_id;
		END IF;

		-- Verified
		IF (NEW.verified IS NULL) THEN
			NEW.verified := (SELECT "value"::INTEGER FROM config_param_user WHERE "parameter"='edit_verified_vdefault' AND "cur_user"="current_user"() LIMIT 1);
		END IF;

		-- State
		IF (NEW.state IS NULL) THEN
			NEW.state := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_state_vdefault' AND "cur_user"="current_user"());
		END IF;

		-- State type
		IF (NEW.state_type IS NULL) THEN
			NEW.state_type := (SELECT "value" FROM config_param_user WHERE "parameter"='state_type_vdefault' AND "cur_user"="current_user"());
		END IF;

		-- Exploitation
		IF (NEW.expl_id IS NULL) THEN
			NEW.expl_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_exploitation_vdefault' AND "cur_user"="current_user"());
			IF (NEW.expl_id IS NULL) THEN
				NEW.expl_id := (SELECT expl_id FROM exploitation WHERE active IS TRUE AND ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) LIMIT 1);
				IF (NEW.expl_id IS NULL) THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
       				 "data":{"message":"2012", "function":"1114","parameters":{"feature_id":"'||NEW.element_id||'"}}}$$);';
				END IF;
			END IF;
		END IF;

		-- Sector
		IF (NEW.sector_id IS NULL AND NEW.the_geom IS NOT NULL) THEN
			NEW.sector_id := (SELECT sector_id FROM sector WHERE ST_intersects(NEW.the_geom, sector.the_geom) AND active IS TRUE limit 1);
		END IF;

		-- Enddate
		IF (NEW.state > 0) THEN
			NEW.enddate := NULL;
		END IF;

		--Publish
		NEW.publish := (SELECT "value" FROM config_param_system WHERE "parameter"='edit_publish_sysvdefault');

		-- Element id
		IF (NEW.element_id IS NULL) THEN
			NEW.element_id:= (SELECT nextval('urn_id_seq'));
		END IF;

		-- LINK
		IF (SELECT "value" FROM config_param_system WHERE "parameter"='edit_automatic_insert_link')::boolean=TRUE THEN
			NEW.link=NEW.element_id;
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

		NEW.rotation = v_rotation*180/pi();
		v_rotation = -(v_rotation - pi()/2);

		v_doublegeometry = (SELECT isdoublegeom FROM cat_element WHERE id = NEW.elementcat_id);

		-- double geometry only if NEW.the_geom exists
		IF v_insert_double_geom AND v_doublegeometry AND NEW.elementcat_id IS NOT NULL AND NEW.the_geom IS NOT NULL THEN

			v_length = (SELECT geom1 FROM cat_element WHERE id=NEW.elementcat_id);
			v_width = (SELECT geom2 FROM cat_element WHERE id=NEW.elementcat_id);

			IF v_length IS NULL OR v_length = 0 THEN

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3152", "function":"1114","parameters":{"elementcat_id":"'||NEW.elementcat_id::text||'"}}}$$);';

			ELSIF v_length IS NOT NULL AND (v_width IS NULL OR v_width = 0) THEN

				-- get element dimensions to generate CIRCULARE geometry
				v_pol_id:= (SELECT nextval('urn_id_seq'));

				INSERT INTO polygon(sys_type, the_geom, pol_id, featurecat_id, feature_id, state)
				VALUES ('ELEMENT', St_Multi(ST_buffer(NEW.the_geom, v_length*0.01*v_unitsfactor/2)),v_pol_id, v_element_type, NEW.element_id, NEW.state);

			ELSIF v_length*v_width != 0 THEN

				-- get element dimensions
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

				v_pol_id:= (SELECT nextval('urn_id_seq'));

				INSERT INTO polygon(sys_type, the_geom, pol_id, featurecat_id, feature_id, state)
				VALUES ('ELEMENT', v_the_geom_pol, v_pol_id, v_element_type, NEW.element_id, NEW.state);
			END IF;
		END IF;

		IF v_man_table = 'man_frelem' THEN
			NEW.the_geom = NULL;
		END IF;

		v_featurecat := COALESCE(v_customfeature, v_element_type);

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND v_featurecat IS NOT NULL THEN
			SELECT code_autofill INTO v_code_autofill_bool FROM cat_feature WHERE id = v_featurecat;

			NEW.code := gw_fct_generate_code('feature', v_featurecat, json_strip_nulls(row_to_json(NEW)::json));

			IF NEW.code IS NULL AND v_code_autofill_bool THEN
				NEW.code := NEW.element_id::text;
			END IF;
		END IF;

		INSERT INTO "element" (element_id, code, sys_code, elementcat_id, serial_number, num_elements, state, state_type, observ, "comment", function_type, category_type,
		location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, rotation, link, verified, label_x, label_y, label_rotation,
		publish, inventory, expl_id, feature_type, top_elev, expl_visibility, trace_featuregeom, muni_id, sector_id, brand_id, model_id, /*asset_id,*/ datasource,
		lock_level, the_geom, created_at, created_by, updated_at, updated_by, epa_type, omzone_id, dataquality, dataquality_obs)
		VALUES(NEW.element_id, NEW.code, NEW.sys_code, NEW.elementcat_id, NEW.serial_number, NEW.num_elements, NEW.state, NEW.state_type, NEW.observ, NEW."comment", NEW.function_type, NEW.category_type,
		NEW.location_type, NEW.workcat_id, NEW.workcat_id_end, NEW.builtdate, NEW.enddate, NEW.ownercat_id, NEW.rotation, NEW.link, NEW.verified, NEW.label_x, NEW.label_y, NEW.label_rotation,
		NEW.publish, NEW.inventory, NEW.expl_id, upper(v_feature_type), NEW.top_elev, NEW.expl_visibility, NEW.trace_featuregeom, NEW.muni_id, NEW.sector_id, NEW.brand_id, NEW.model_id, /*NEW.asset_id,*/ NEW.datasource,
		NEW.lock_level, NEW.the_geom, now(), CURRENT_USER, NEW.updated_at, NEW.updated_by, NEW.epa_type, NEW.omzone_id, NEW.dataquality, NEW.dataquality_obs);

		-- Insert into visibility tables
		IF NEW.sector_visibility IS NOT NULL THEN
		    INSERT INTO element_x_sector_visibility (element_id, sector_id)
		    SELECT NEW.element_id, unnest(NEW.sector_visibility);
		END IF;

		IF NEW.muni_visibility IS NOT NULL THEN
		    INSERT INTO element_x_municipality_visibility (element_id, muni_id)
		    SELECT NEW.element_id, unnest(NEW.muni_visibility);
		END IF;

		-- MAN TABLE INSERT AND EPA_TYPE INSERT
		IF v_man_table='man_frelem' THEN
			INSERT INTO man_frelem (element_id, node_id, to_arc, flwreg_length)
			VALUES(NEW.element_id, NEW.node_id, NEW.to_arc, NEW.flwreg_length);
			UPDATE "element" SET epa_type = NEW.epa_type WHERE element_id = NEW.element_id;
		ELSIF v_man_table='man_genelem' THEN
			INSERT INTO man_genelem (element_id) VALUES (NEW.element_id);
			UPDATE "element" SET epa_type = 'UNDEFINED' WHERE element_id = NEW.element_id;
		END IF;

		-- EPA INSERT
		IF (NEW.epa_type = 'FRPUMP') THEN
		    INSERT INTO inp_frpump (element_id) VALUES (NEW.element_id);

		ELSIF (NEW.epa_type = 'FRVALVE') THEN
		    INSERT INTO inp_frvalve (element_id) VALUES (NEW.element_id);

		ELSIF (NEW.epa_type = 'FRWEIR') THEN
		    INSERT INTO inp_frweir (element_id) VALUES (NEW.element_id);

		ELSIF (NEW.epa_type = 'FRORIFICE') THEN
		    INSERT INTO inp_frorifice (element_id) VALUES (NEW.element_id);

		ELSIF (NEW.epa_type = 'FROUTLET') THEN
		    INSERT INTO inp_froutlet (element_id) VALUES (NEW.element_id);

		ELSIF (NEW.epa_type = 'FRSHORTPIPE') THEN
		    INSERT INTO inp_frshortpipe (element_id) VALUES (NEW.element_id);

		END IF;

		-- insert into element_x_feature table
		IF v_tablefeature IS NOT NULL THEN

			v_new_data := to_jsonb(NEW);
			v_feature_id_name := v_tablefeature||'_id';
			v_uuid_column := v_tablefeature||'_uuid';
			v_uuid_value := (v_new_data->>v_uuid_column)::uuid;

			IF v_uuid_value IS NOT NULL THEN
				EXECUTE 'SELECT '||v_feature_id_name||' FROM '||v_tablefeature||' WHERE uuid = '||v_uuid_value||' LIMIT 1'
				INTO v_feature_id;
			END IF;

			IF v_feature_id IS NOT NULL THEN
				EXECUTE 'INSERT INTO element_x_'||v_tablefeature||' ('||v_feature_id_name||', element_id, '||v_uuid_column||') VALUES ('||v_feature_id||','||NEW.element_id||','||v_uuid_value||') ON CONFLICT
				('||v_tablefeature||'_id, element_id) DO NOTHING';
			ELSE
				EXECUTE 'INSERT INTO element_x_'||v_tablefeature||' ('||v_feature_id_name||', element_id) VALUES ('||v_feature||','||NEW.element_id||') ON CONFLICT
				('||v_tablefeature||'_id, element_id) DO NOTHING';
			END IF;
		END IF;

		--elevation from raster
		IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
		AND (NEW.top_elev IS NULL) AND
		(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_insert_elevation_from_dem' and cur_user = current_user) = 'TRUE'
		AND ST_geometrytype(NEW.the_geom) = 'ST_Point'
		THEN
			NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
				(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1));
		END IF;

		UPDATE element SET top_elev = NEW.top_elev WHERE element_id = NEW.element_id;

		-- childtable insert
		IF v_customfeature IS NOT NULL THEN

			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='NODE' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP

				EXECUTE 'SELECT $1."' ||v_addfields.param_name||'"'
					USING NEW
					INTO v_new_value_param;

				v_childtable_name := 'man_element_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF v_new_value_param IS NOT NULL THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (element_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (element_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.element_id=$1'
							USING NEW.element_id, v_new_value_param;
					END IF;
				END IF;
			END LOOP;
		END IF;

		RETURN NEW;


	-- UPDATE
	ELSIF TG_OP = 'UPDATE' THEN
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		v_featurecat := COALESCE(v_customfeature, v_element_type);
		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL AND v_featurecat IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('feature', v_featurecat, json_strip_nulls(row_to_json(NEW)::json));
		END IF;

				-- epa type
		IF (NEW.epa_type != OLD.epa_type) THEN
			IF (OLD.epa_type = 'FRPUMP') THEN
				v_inp_table:= 'inp_frpump';
			ELSIF (OLD.epa_type = 'FRVALVE') THEN
				v_inp_table:= 'inp_frvalve';
			ELSIF (OLD.epa_type = 'FRWEIR') THEN
				v_inp_table:= 'inp_frweir';
			ELSIF (OLD.epa_type = 'FRORIFICE') THEN
				v_inp_table:= 'inp_frorifice';
			ELSIF (OLD.epa_type = 'FROUTLET') THEN
				v_inp_table:= 'inp_froutlet';
			ELSIF (OLD.epa_type = 'FRSHORTPIPE') THEN
				v_inp_table:= 'inp_frshortpipe';
			END IF;

			IF v_inp_table IS NOT NULL THEN
				v_sql:= 'DELETE FROM '||v_inp_table||' WHERE element_id = '||quote_literal(OLD.element_id);
				EXECUTE v_sql;
			END IF;

			v_inp_table := NULL;

			IF (NEW.epa_type = 'FRPUMP') THEN
				v_inp_table:= 'inp_frpump';
			ELSIF (NEW.epa_type = 'FRVALVE') THEN
				v_inp_table:= 'inp_frvalve';
			ELSIF (NEW.epa_type = 'FRWEIR') THEN
				v_inp_table:= 'inp_frweir';
			ELSIF (NEW.epa_type = 'FRORIFICE') THEN
				v_inp_table:= 'inp_frorifice';
			ELSIF (NEW.epa_type = 'FROUTLET') THEN
				v_inp_table:= 'inp_froutlet';
			ELSIF (NEW.epa_type = 'FRSHORTPIPE') THEN
				v_inp_table:= 'inp_frshortpipe';
			END IF;
			IF v_inp_table IS NOT NULL THEN
				v_sql:= 'INSERT INTO '||v_inp_table||' (element_id) VALUES ('||quote_literal(NEW.element_id)||') ON CONFLICT (element_id) DO NOTHING';
				EXECUTE v_sql;
			END IF;
		END IF;

		-- Sector
		IF (NEW.sector_id IS NULL AND NEW.the_geom IS NOT NULL) THEN
			NEW.sector_id := (SELECT sector_id FROM sector WHERE ST_intersects(NEW.the_geom, sector.the_geom) AND active IS TRUE limit 1);
		END IF;

		IF v_man_table='man_genelem' THEN
			UPDATE element SET the_geom = NEW.the_geom WHERE element_id = OLD.element_id;
		END IF;

		UPDATE "element" SET code=NEW.code, sys_code=NEW.sys_code, elementcat_id=NEW.elementcat_id, serial_number=NEW.serial_number, num_elements=NEW.num_elements, state=NEW.state,
		state_type=NEW.state_type, observ=NEW.observ, "comment"=NEW."comment",  function_type=NEW.function_type, category_type=NEW.category_type,
		location_type=NEW.location_type, workcat_id=NEW.workcat_id, workcat_id_end=NEW.workcat_id_end, builtdate=NEW.builtdate, enddate=NEW.enddate, ownercat_id=NEW.ownercat_id,
		rotation=NEW.rotation, link=NEW.link, verified=NEW.verified, label_x=NEW.label_x, label_y=NEW.label_y, label_rotation=NEW.label_rotation, publish=NEW.publish,
		inventory=NEW.inventory, expl_id=NEW.expl_id, feature_type=upper(v_feature_type), top_elev=NEW.top_elev, expl_visibility=NEW.expl_visibility, trace_featuregeom=NEW.trace_featuregeom,
		muni_id=NEW.muni_id, sector_id=NEW.sector_id, brand_id=NEW.brand_id, model_id=NEW.model_id, asset_id=NEW.asset_id, datasource=NEW.datasource,
		lock_level=NEW.lock_level, created_at=NEW.created_at, created_by=NEW.created_by, updated_at=now(), updated_by=CURRENT_USER, epa_type=NEW.epa_type, omzone_id=NEW.omzone_id, dataquality=NEW.dataquality, dataquality_obs=NEW.dataquality_obs
		WHERE element_id=OLD.element_id;

		-- Update visibility tables
		IF NEW.sector_visibility IS DISTINCT FROM OLD.sector_visibility THEN
		    DELETE FROM element_x_sector_visibility WHERE element_id = OLD.element_id;
		    IF NEW.sector_visibility IS NOT NULL THEN
		        INSERT INTO element_x_sector_visibility (element_id, sector_id)
		        SELECT NEW.element_id, unnest(NEW.sector_visibility);
		    END IF;
		END IF;

		IF NEW.muni_visibility IS DISTINCT FROM OLD.muni_visibility THEN
		    DELETE FROM element_x_municipality_visibility WHERE element_id = OLD.element_id;
		    IF NEW.muni_visibility IS NOT NULL THEN
		        INSERT INTO element_x_municipality_visibility (element_id, muni_id)
		        SELECT NEW.element_id, unnest(NEW.muni_visibility);
		    END IF;
		END IF;

		IF v_man_table='man_frelem' THEN
			UPDATE man_frelem SET element_id=NEW.element_id, to_arc=NEW.to_arc, flwreg_length=NEW.flwreg_length
			WHERE element_id=OLD.element_id;
		ELSIF v_man_table='man_genelem' THEN
			UPDATE man_genelem SET element_id=NEW.element_id
			WHERE element_id=OLD.element_id;
		END IF;

		-- -- UPDATE element (DYNAMIC TRIGGER)
		-- SELECT row_to_json(NEW) INTO v_json_new_data;
		-- SELECT row_to_json(OLD) INTO v_json_old_data;

		-- v_input_json := jsonb_build_object(
        -- 'client', jsonb_build_object(
        --     'device', 4,
        --     'infoType', 1,
        --     'lang', 'ES'
        -- 	),
        -- 'feature', '{}'::jsonb,
        -- 'data', jsonb_build_object(
        --     'parameters', jsonb_build_object(
        --         'jsonNewData', v_json_new_data,
        --         'jsonOldData', v_json_old_data,
        --         'action', 'UPDATE',
        --         'originTable', v_tg_table_name,
        --         'pkeyColumn', 'element_id',
        --         'pkeyValue', NEW.element_id
        --     	)
        -- 	)
    	-- );

		-- PERFORM gw_fct_admin_dynamic_trigger(v_input_json);

		-- UPDATE geom
		IF st_equals( NEW.the_geom, OLD.the_geom) IS FALSE THEN
			--update elevation from raster
			IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
			AND (NEW.top_elev = OLD.top_elev) AND
			(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_update_elevation_from_dem' and cur_user = current_user) = 'TRUE'
			AND ST_geometrytype(NEW.the_geom) = 'ST_Point'
			THEN
				NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
							(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1));
			END IF;
		END IF;
		UPDATE element SET top_elev = NEW.top_elev WHERE element_id = OLD.element_id;

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


		v_doublegeometry = (SELECT isdoublegeom FROM cat_element WHERE id = NEW.elementcat_id);

		-- double geometry catalog update
		IF v_insert_double_geom AND v_doublegeometry AND
		(NEW.elementcat_id != OLD.elementcat_id OR NEW.the_geom::text <> OLD.the_geom::text) THEN

			v_length = (SELECT geom1 FROM cat_element WHERE id=NEW.elementcat_id);
			v_width = (SELECT geom2 FROM cat_element WHERE id=NEW.elementcat_id);


			IF v_length IS NULL OR v_length = 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3152", "function":"1114","parameters":{"elementcat_id":"'||NEW.elementcat_id::text||'"}}}$$);';

			ELSIF v_length IS NOT NULL AND (v_width IS NULL OR v_width = 0) THEN

				v_pol_id:= (SELECT nextval('urn_id_seq'));

				-- get element dimensions to generate CIRCULARE geometry
				IF (SELECT pol_id FROM element WHERE element_id = NEW.element_id) IS NULL THEN
					INSERT INTO polygon(sys_type, the_geom, pol_id, featurecat_id, feature_id, state)
					VALUES ('ELEMENT', St_multi(ST_buffer(NEW.the_geom, v_length*0.01*v_unitsfactor/2)),v_pol_id, v_element_type, NEW.element_id, NEW.state);
				ELSE
					SELECT trace_featuregeom INTO v_trace_featuregeom FROM polygon WHERE feature_id=OLD.element_id;
					IF v_trace_featuregeom IS TRUE THEN
						UPDATE polygon SET the_geom = St_multi(ST_buffer(NEW.the_geom, v_length*0.01*v_unitsfactor/2))
						WHERE pol_id = (SELECT pol_id FROM element WHERE element_id = NEW.element_id);
					END IF;
				END IF;

			ELSIF v_length*v_width != 0 THEN

				-- get grate dimensions
				v_unitsfactor = 0.01*v_unitsfactor; -- using 0.01 to convert from cms of catalog  to meters of the map
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

				v_pol_id:= (SELECT nextval('urn_id_seq'));

				IF (SELECT pol_id FROM element WHERE element_id = NEW.element_id) IS NULL THEN
					INSERT INTO polygon(sys_type, the_geom, pol_id, featurecat_id, feature_id, state)
					VALUES ('ELEMENT', v_the_geom_pol, v_pol_id, v_element_type, NEW.element_id, NEW.state);

				ELSE
					SELECT trace_featuregeom INTO v_trace_featuregeom FROM polygon WHERE feature_id=OLD.element_id;
					IF v_trace_featuregeom IS TRUE THEN
						UPDATE polygon SET the_geom = v_the_geom_pol WHERE pol_id = (SELECT pol_id FROM element WHERE element_id = NEW.element_id);
					END IF;
				END IF;
			END IF;
		ELSE
			-- Updating polygon geometry in case of exists it
			SELECT pol_id, trace_featuregeom INTO v_pol_id, v_trace_featuregeom FROM polygon WHERE feature_id=OLD.element_id;
			IF v_pol_id IS NOT NULL AND (NEW.the_geom::text <> OLD.the_geom::text) THEN
				IF v_trace_featuregeom IS TRUE THEN
					v_x= (st_x(NEW.the_geom)-st_x(OLD.the_geom));
					v_y= (st_y(NEW.the_geom)-st_y(OLD.the_geom));
					UPDATE polygon SET the_geom=ST_translate(the_geom, v_x, v_y) WHERE pol_id=v_pol_id;
				END IF;
			END IF;
		END IF;


		IF v_customfeature IS NOT NULL THEN
			FOR v_addfields IN SELECT * FROM sys_addfields
			WHERE (cat_feature_id = v_customfeature OR cat_feature_id is null) AND (feature_type='element' OR feature_type='ALL' OR feature_type='CHILD') AND active IS TRUE AND iseditable IS TRUE
			LOOP
				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING NEW
					INTO v_new_value_param;

				EXECUTE 'SELECT $1."' || v_addfields.param_name ||'"'
					USING OLD
					INTO v_old_value_param;

				v_childtable_name := 'man_element_' || lower(v_customfeature);
				IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
					IF (v_new_value_param IS NOT NULL AND v_old_value_param!=v_new_value_param) OR (v_new_value_param IS NOT NULL AND v_old_value_param IS NULL) THEN
						EXECUTE 'INSERT INTO '||v_childtable_name||' (element_id, '||v_addfields.param_name||') VALUES ($1, $2::'||v_addfields.datatype_id||')
							ON CONFLICT (element_id)
							DO UPDATE SET '||v_addfields.param_name||'=$2::'||v_addfields.datatype_id||' WHERE '||v_childtable_name||'.element_id=$1'
							USING NEW.element_id, v_new_value_param;

					ELSIF v_new_value_param IS NULL AND v_old_value_param IS NOT NULL THEN
						EXECUTE 'UPDATE '||v_childtable_name||' SET '||v_addfields.param_name||' = null WHERE '||v_childtable_name||'.element_id=$1'
							USING NEW.element_id;
					END IF;
				END IF;
			END LOOP;
		END IF;



		RETURN NEW;

	-- DELETE
	ELSIF TG_OP = 'DELETE' THEN

        -- delete related polygon if exists
    	IF (SELECT 1 FROM polygon WHERE feature_id=OLD.element_id) IS NOT NULL THEN
			DELETE FROM polygon WHERE feature_id=OLD.element_id;
		END IF;

		DELETE FROM element WHERE element_id=OLD.element_id;

		v_customfeature = old.element_type;
		v_element_id = old.element_id;

		v_childtable_name := 'man_element_' || lower(v_customfeature);
		IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = TG_TABLE_SCHEMA AND table_name = v_childtable_name)) IS TRUE THEN
			EXECUTE 'DELETE FROM '||v_childtable_name||' WHERE element_id = '||quote_literal(v_element_id)||'';
		END IF;

        RETURN NULL;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

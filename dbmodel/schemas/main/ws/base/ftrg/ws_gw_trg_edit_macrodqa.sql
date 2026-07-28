/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2954


CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_macrodqa()
  RETURNS trigger AS
$BODY$
DECLARE
	v_view_name TEXT;
	expl_id_int integer[];
	v_macrodqa_id INTEGER;
BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	v_view_name = TG_ARGV[0];

    IF TG_OP = 'INSERT' THEN

		--Exploitation ID
		IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"1110", "function":"1312","parameters":null}}$$);';
			RETURN NULL;
      	END IF;

		expl_id_int := NEW.expl_id;
      	IF v_view_name = 'EDIT' THEN

			IF NEW.active IS NULL THEN
				NEW.active := TRUE;
			END IF;

			IF NEW.the_geom IS NOT NULL THEN
				IF NEW.expl_id IS NULL THEN
					expl_id_int := (SELECT expl_id FROM exploitation WHERE active IS TRUE AND ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) LIMIT 1);
					IF (expl_id_int IS NULL) THEN
						expl_id_int := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_exploitation_vdefault' AND "cur_user"="current_user"());
					END IF;
				END IF;
			END IF;
		END IF;

		SELECT max(macrodqa_id::integer)+1 INTO v_macrodqa_id FROM macrodqa WHERE macrodqa_id::text ~ '^[0-9]+$';
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'MACRODQA', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		IF NEW.code IS NULL THEN
			NEW.code := v_macrodqa_id::text;
		END IF;

        -- FEATURE INSERT

		INSERT INTO macrodqa (macrodqa_id, code, name, descript, active, expl_id, sector_id, muni_id, stylesheet, link, lock_level, addparam, created_at, created_by, updated_at, updated_by)
		VALUES (v_macrodqa_id, NEW.code, NEW.name, NEW.descript, NEW.active, expl_id_int, NEW.sector_id, NEW.muni_id, 
		NEW.stylesheet::json, NEW.link, NEW.lock_level, NEW.addparam::json, now(), current_user, now(), current_user);

      	IF v_view_name = 'EDIT' THEN
			UPDATE macrodqa SET the_geom = NEW.the_geom WHERE macrodqa_id = NEW.macrodqa_id;
		END IF;

		RETURN NEW;


    ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF v_view_name = 'EDIT' AND NEW.the_geom IS NOT NULL AND NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'MACRODQA', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		UPDATE macrodqa
		SET macrodqa_id=NEW.macrodqa_id, code=NEW.code, "name"=NEW.name, descript=NEW.descript, active=NEW.active, expl_id=NEW.expl_id, sector_id=NEW.sector_id, 
		muni_id=NEW.muni_id, stylesheet=NEW.stylesheet::json, link=NEW.link, lock_level=NEW.lock_level, addparam=NEW.addparam::json, updated_at=now(), updated_by = current_user
		WHERE macrodqa_id=NEW.macrodqa_id;

      	IF v_view_name = 'EDIT' THEN
			UPDATE macrodqa SET the_geom = NEW.the_geom WHERE macrodqa_id = OLD.macrodqa_id;
		END IF;

        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        		"data":{"message":"2", "function":"1312","parameters":null}}$$);';
        RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN
		DELETE FROM macrodqa WHERE macrodqa_id=OLD.macrodqa_id;

        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"3", "function":"1312","parameters":null}}$$);';
        RETURN NULL;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


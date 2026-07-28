/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2926

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_presszone()
  RETURNS trigger AS
$BODY$

DECLARE

	v_view_name TEXT; -- EDIT | UI
	v_mapzone_id INTEGER;
	v_presszone_id INTEGER;
	v_count INTEGER;

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- Get parameters
	v_view_name = UPPER(TG_ARGV[0]);

	-- Validate parameters
	IF v_view_name IS NULL THEN
		RAISE EXCEPTION 'Param ''v_view_name'' is requiered';
    END IF;

	IF v_view_name NOT IN ('EDIT', 'UI') THEN
		RAISE EXCEPTION 'Param ''v_view_name'' is wrong, need to be: ''EDIT'' or ''UI''.';
	END IF;

	-- Other validations
	IF NOT (SELECT array_agg(expl_id ORDER BY expl_id) @> NEW.expl_id FROM exploitation) THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3276", "function":"2926","parameters":null, "is_process":true}}$$);';
	END IF;

	IF NOT (SELECT array_agg(muni_id ORDER BY muni_id) @> NEW.muni_id FROM v_municipality) THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3278", "function":"2926","parameters":null, "is_process":true}}$$);';
	END IF;

	IF NOT (SELECT array_agg(sector_id ORDER BY sector_id) @> NEW.sector_id FROM sector) THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3280", "function":"2926","parameters":null, "is_process":true}}$$);';
	END IF;

	IF TG_OP = 'INSERT' THEN
		IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
			RETURN NULL;
		END IF;

		
		IF NEW.presszone_id != (SELECT last_value FROM urn_id_seq) OR NEW.presszone_id IS NULL THEN
			NEW.presszone_id:= (SELECT nextval('urn_id_seq'));
		END IF;

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'PRESSZONE', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		IF NEW.code IS NULL THEN
			NEW.code := NEW.presszone_id::text;
		END IF;

		IF NEW.active IS NULL THEN
			NEW.active = TRUE;
		END IF;

		IF v_view_name = 'EDIT' THEN
			IF NEW.the_geom IS NOT NULL THEN
				IF NEW.expl_id IS NULL THEN
					NEW.expl_id := (SELECT array_agg(expl_id) FROM exploitation WHERE active IS TRUE AND ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) LIMIT 1);
				END IF;
			END IF;
		END IF;

		INSERT INTO presszone (presszone_id, code, name, descript, active, presszone_type, expl_id, sector_id, muni_id, avg_press, head, graphconfig, stylesheet, link, lock_level, addparam, created_at, created_by, updated_at, updated_by)
		VALUES (NEW.presszone_id, NEW.code, NEW.name, NEW.descript, NEW.active, NEW.presszone_type, NEW.expl_id, NEW.sector_id, NEW.muni_id, NEW.avg_press, 
		NEW.head, NEW.graphconfig::json, NEW.stylesheet::json, NEW.link, NEW.lock_level, NEW.addparam::json, now(), current_user, now(), current_user);

		IF v_view_name = 'EDIT' THEN
			UPDATE presszone SET the_geom = NEW.the_geom WHERE presszone_id = OLD.presszone_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF v_view_name = 'EDIT' AND NEW.the_geom IS NOT NULL AND NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'PRESSZONE', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		UPDATE presszone
		SET presszone_id=NEW.presszone_id, code=NEW.code, name=NEW.name, descript=NEW.descript, active=NEW.active, presszone_type=NEW.presszone_type, expl_id=NEW.expl_id, 
		muni_id = NEW.muni_id, sector_id = NEW.sector_id, avg_press=NEW.avg_press, head = NEW.head, graphconfig=NEW.graphconfig::json, stylesheet=NEW.stylesheet::json,
		link = NEW.link, lock_level=NEW.lock_level, addparam=NEW.addparam::json, updated_at=now(), updated_by = current_user
		WHERE presszone_id=OLD.presszone_id;

		IF v_view_name = 'EDIT' THEN
			UPDATE presszone SET the_geom = NEW.the_geom WHERE presszone_id = OLD.presszone_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		-- Check if there are operative elements in the mapzone before allowing delete
		SELECT SUM(counts) INTO v_count FROM (
			SELECT count(*) as counts
				FROM node n
				JOIN value_state_type vst ON vst.id = n.state_type
				WHERE n.presszone_id = OLD.presszone_id
					AND n.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM arc a
				JOIN value_state_type vst ON vst.id = a.state_type
				WHERE a.presszone_id = OLD.presszone_id
					AND a.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM connec c
				JOIN value_state_type vst ON vst.id = c.state_type
				WHERE c.presszone_id = OLD.presszone_id
					AND c.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM link l
				JOIN value_state_type vst ON vst.id = l.state_type
				WHERE l.presszone_id = OLD.presszone_id
					AND l.state = 1
					AND vst.is_operative
		) combined;
		IF COALESCE(v_count, 0) > 0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4468", "function":"2926","parameters":{"mapzone_name":"Presszone", "mapzone_id":'||OLD.presszone_id||'}}}$$);';
		END IF;

		UPDATE node SET presszone_id = 0 WHERE presszone_id = OLD.presszone_id;
		UPDATE arc SET presszone_id = 0 WHERE presszone_id = OLD.presszone_id;
		UPDATE connec SET presszone_id = 0 WHERE presszone_id = OLD.presszone_id;
		UPDATE link SET presszone_id = 0 WHERE presszone_id = OLD.presszone_id;

		DELETE FROM presszone WHERE presszone_id = OLD.presszone_id;
		RETURN NULL;

	END IF;

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



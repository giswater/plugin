/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: TODO


CREATE OR REPLACE FUNCTION gw_trg_edit_supplyzone()
  RETURNS trigger AS
$BODY$

DECLARE
	v_view_name TEXT; -- EDIT | UI
	v_supplyzone_id INTEGER;
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
		"data":{"message":"3276", "function":"3378","parameters":null, "is_process":true}}$$);';
	END IF;

	IF NOT (SELECT array_agg(muni_id ORDER BY muni_id) @> NEW.muni_id FROM v_municipality) THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3278", "function":"3378","parameters":null, "is_process":true}}$$);';
	END IF;

	IF TG_OP = 'INSERT' THEN

		IF NEW.supplyzone_id != (SELECT last_value FROM urn_id_seq) OR NEW.supplyzone_id IS NULL THEN
			NEW.supplyzone_id:= (SELECT nextval('urn_id_seq'));
		END IF;

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'SUPPLYZONE', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		IF NEW.code IS NULL THEN
			NEW.code := NEW.supplyzone_id::text;
		END IF;

		IF NEW.active IS NULL THEN
			NEW.active = TRUE;
		END IF;

		INSERT INTO supplyzone (supplyzone_id, code, name, descript, active, supplyzone_type, expl_id, sector_id, muni_id, avg_press, pattern_id, graphconfig, stylesheet, link, lock_level, addparam, created_at, created_by, updated_at, updated_by)
		VALUES (NEW.supplyzone_id, NEW.code, NEW.name, NEW.descript, NEW.active, NEW.supplyzone_type, NEW.expl_id, NEW.sector_id, NEW.muni_id, NEW.avg_press, 
		NEW.pattern_id, NEW.graphconfig::json, NEW.stylesheet::json, NEW.link, NEW.lock_level, NEW.addparam::json, now(), current_user, now(), current_user);

		IF v_view_name = 'EDIT' THEN
			UPDATE supplyzone SET the_geom = NEW.the_geom WHERE supplyzone_id = NEW.supplyzone_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF v_view_name = 'EDIT' AND NEW.the_geom IS NOT NULL AND NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'SUPPLYZONE', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		UPDATE supplyzone
		SET supplyzone_id=NEW.supplyzone_id, code=NEW.code, name=NEW.name, descript=NEW.descript, active=NEW.active, supplyzone_type = NEW.supplyzone_type, expl_id=NEW.expl_id,
		sector_id=NEW.sector_id, muni_id=NEW.muni_id, avg_press=NEW.avg_press, pattern_id=NEW.pattern_id, graphconfig=NEW.graphconfig::json,
		stylesheet=NEW.stylesheet::json, link=NEW.link, lock_level=NEW.lock_level, addparam=NEW.addparam::json, updated_at=now(), updated_by = current_user
		WHERE supplyzone_id=OLD.supplyzone_id;

		IF v_view_name = 'EDIT' THEN
			UPDATE supplyzone SET the_geom = NEW.the_geom WHERE supplyzone_id = OLD.supplyzone_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN
		-- Check if there are operative elements in the mapzone before allowing delete
		SELECT SUM(counts) INTO v_count FROM (
			SELECT count(*) as counts
				FROM node n
				JOIN value_state_type vst ON vst.id = n.state_type
				WHERE n.supplyzone_id = OLD.supplyzone_id
					AND n.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM arc a
				JOIN value_state_type vst ON vst.id = a.state_type
				WHERE a.supplyzone_id = OLD.supplyzone_id
					AND a.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM connec c
				JOIN value_state_type vst ON vst.id = c.state_type
				WHERE c.supplyzone_id = OLD.supplyzone_id
					AND c.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM link l
				JOIN value_state_type vst ON vst.id = l.state_type
				WHERE l.supplyzone_id = OLD.supplyzone_id
					AND l.state = 1
					AND vst.is_operative
		) combined;
		IF COALESCE(v_count, 0) > 0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4468", "function":"3378","parameters":{"mapzone_name":"Supplyzone", "mapzone_id":'||OLD.supplyzone_id||'}}}$$);';
		END IF;

		UPDATE node SET supplyzone_id = 0 WHERE supplyzone_id = OLD.supplyzone_id;
		UPDATE arc SET supplyzone_id = 0 WHERE supplyzone_id = OLD.supplyzone_id;
		UPDATE connec SET supplyzone_id = 0 WHERE supplyzone_id = OLD.supplyzone_id;
		UPDATE link SET supplyzone_id = 0 WHERE supplyzone_id = OLD.supplyzone_id;

		DELETE FROM supplyzone WHERE supplyzone_id = OLD.supplyzone_id;
		RETURN NULL;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



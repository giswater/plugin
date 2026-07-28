/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- FUNCTION CODE: 1124

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_sector()
  RETURNS trigger AS
$BODY$
DECLARE
	v_view_name TEXT;
	v_mapzone_id INTEGER;
	v_sector_id INTEGER;
	v_count INTEGER;
BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- Arg will be or 'edit' or 'ui'
	v_view_name = TG_ARGV[0];

	IF TG_OP = 'INSERT' THEN

		IF NEW.active IS NULL THEN
				NEW.active = TRUE;
		END IF;

		IF NEW.sector_id != (SELECT last_value FROM urn_id_seq) OR NEW.sector_id IS NULL THEN
			NEW.sector_id:= (SELECT nextval('urn_id_seq'));
		END IF;

		IF v_view_name = 'EDIT' THEN
			-- set macrosector_id = 0 if null
			IF NEW.macrosector_id IS NULL THEN NEW.macrosector_id = 0; END IF;
			v_mapzone_id = NEW.macrosector_id;
		ELSIF v_view_name = 'UI' THEN
			SELECT macrosector_id INTO v_mapzone_id FROM macrosector WHERE name = NEW.macrosector;
		END IF;

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'SECTOR', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		IF NEW.code IS NULL THEN
			NEW.code := NEW.sector_id::text;
		END IF;

		INSERT INTO sector (sector_id, code, name, descript, active, macrosector_id, sector_type, expl_id, muni_id, graphconfig, stylesheet, lock_level, link, addparam)
		VALUES (NEW.sector_id, NEW.code, NEW.name, NEW.descript, NEW.active, v_mapzone_id, NEW.sector_type, NEW.expl_id, NEW.muni_id,
		NEW.graphconfig::json, NEW.stylesheet::json, NEW.lock_level, NEW.link, NEW.addparam::json);

		IF v_view_name = 'UI' THEN
			UPDATE sector SET active = NEW.active WHERE sector_id = NEW.sector_id;
		ELSIF v_view_name = 'EDIT' THEN
			UPDATE sector SET the_geom = NEW.the_geom WHERE sector_id = NEW.sector_id;
		END IF;

		INSERT INTO selector_sector VALUES (NEW.sector_id, current_user) ON CONFLICT DO NOTHING;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF v_view_name = 'EDIT' THEN
			IF NEW.the_geom IS NOT NULL THEN
				IF NEW.code IS NULL THEN
					NEW.code := gw_fct_generate_code('mapzone', 'SECTOR', json_strip_nulls(row_to_json(NEW)::json));
				END IF;
			END IF;
			IF NEW.macrosector_id IS NULL THEN NEW.macrosector_id := 0; END IF;
			v_mapzone_id = NEW.macrosector_id;
		ELSIF v_view_name = 'UI' THEN
			SELECT macrosector_id INTO v_mapzone_id FROM macrosector WHERE name = NEW.macrosector;
		END IF;
		UPDATE sector
		SET sector_id=NEW.sector_id, code=NEW.code, name=NEW.name, descript=NEW.descript, active=NEW.active, macrosector_id=v_mapzone_id, sector_type=NEW.sector_type,
		expl_id=NEW.expl_id, muni_id=NEW.muni_id, graphconfig=NEW.graphconfig::json,
		stylesheet = NEW.stylesheet::json, lock_level=NEW.lock_level, link = NEW.link, addparam=NEW.addparam::json,
		updated_at=now(), updated_by = current_user
		WHERE sector_id=OLD.sector_id;
		IF v_view_name = 'UI' THEN
			UPDATE sector SET active = NEW.active WHERE sector_id = NEW.sector_id;

		ELSIF v_view_name = 'EDIT' THEN
			UPDATE sector SET the_geom = NEW.the_geom WHERE sector_id = NEW.sector_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		-- Check if there are operative elements in the mapzone before allowing delete
		SELECT SUM(counts) INTO v_count FROM (
			SELECT count(*) as counts
				FROM node n
				JOIN value_state_type vst ON vst.id = n.state_type
				WHERE n.sector_id = OLD.sector_id
					AND n.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM arc a
				JOIN value_state_type vst ON vst.id = a.state_type
				WHERE a.sector_id = OLD.sector_id
					AND a.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM connec c
				JOIN value_state_type vst ON vst.id = c.state_type
				WHERE c.sector_id = OLD.sector_id
					AND c.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM gully g
				JOIN value_state_type vst ON vst.id = g.state_type
				WHERE g.sector_id = OLD.sector_id
					AND g.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM link l
				JOIN value_state_type vst ON vst.id = l.state_type
				WHERE l.sector_id = OLD.sector_id
					AND l.state = 1
					AND vst.is_operative
		) combined;
		IF COALESCE(v_count, 0) > 0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4468", "function":"1112","parameters":{"mapzone_name":"Sector", "mapzone_id":'||OLD.sector_id||'}}}$$);';
		END IF;

		UPDATE node SET sector_id = 0 WHERE sector_id = OLD.sector_id;
		UPDATE arc SET sector_id = 0 WHERE sector_id = OLD.sector_id;
		UPDATE connec SET sector_id = 0 WHERE sector_id = OLD.sector_id;
		UPDATE gully SET sector_id = 0 WHERE sector_id = OLD.sector_id;
		UPDATE link SET sector_id = 0 WHERE sector_id = OLD.sector_id;

		DELETE FROM sector WHERE sector_id = OLD.sector_id;

		RETURN NULL;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

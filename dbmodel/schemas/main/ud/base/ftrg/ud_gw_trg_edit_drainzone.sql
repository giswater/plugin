/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3178

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_drainzone()  RETURNS trigger AS
$BODY$

DECLARE
	v_view_name TEXT;
	v_drainzone_id INTEGER;
BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- Arg will be or 'edit' or 'ui'
	v_view_name = TG_ARGV[0];

	IF TG_OP = 'INSERT' THEN

		-- expl_id
		IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
			RETURN NULL;
		END IF;

		-- active
		IF NEW.active IS NULL THEN
			NEW.active = TRUE;
		END IF;

		IF v_view_name = 'EDIT'THEN
			IF NEW.the_geom IS NOT NULL THEN
				IF NEW.expl_id IS NULL THEN
					NEW.expl_id := (SELECT expl_id FROM exploitation WHERE active IS TRUE AND ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) LIMIT 1);
				END IF;
			END IF;
		END IF;

		SELECT max(drainzone_id::integer)+1 INTO v_drainzone_id FROM drainzone WHERE drainzone_id::text ~ '^[0-9]+$';
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'DRAINZONE', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		IF NEW.code IS NULL THEN
			NEW.code := v_drainzone_id::text;
		END IF;

		INSERT INTO drainzone (drainzone_id, code, name, active, drainzone_type, expl_id, sector_id, muni_id, descript, graphconfig, stylesheet, link, lock_level, addparam, created_at, created_by, updated_at, updated_by)
		VALUES (v_drainzone_id, NEW.code, NEW.name, NEW.active, NEW.drainzone_type, NEW.expl_id, NEW.sector_id, NEW.muni_id, NEW.descript,
		NEW.graphconfig::json, NEW.stylesheet::json, NEW.link, NEW.lock_level, NEW.addparam::json, now(), current_user, now(), current_user);

		IF v_view_name = 'EDIT' THEN
			UPDATE drainzone SET the_geom = NEW.the_geom WHERE drainzone_id = NEW.drainzone_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF v_view_name = 'EDIT' AND NEW.the_geom IS NOT NULL AND NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'DRAINZONE', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		UPDATE drainzone
		SET drainzone_id=NEW.drainzone_id, code=NEW.code, name=NEW.name, descript=NEW.descript, active=NEW.active, drainzone_type=NEW.drainzone_type, expl_id=NEW.expl_id,
		sector_id=NEW.sector_id, muni_id=NEW.muni_id, graphconfig=NEW.graphconfig::json, stylesheet=NEW.stylesheet::json,
		link=NEW.link, lock_level=NEW.lock_level, addparam=NEW.addparam::json, updated_at=now(), updated_by = current_user
		WHERE drainzone_id=OLD.drainzone_id;

		IF v_view_name = 'EDIT' THEN
			UPDATE drainzone SET the_geom = NEW.the_geom WHERE drainzone_id = OLD.drainzone_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		DELETE FROM drainzone WHERE drainzone_id = OLD.drainzone_id;
		RETURN NULL;
	END IF;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



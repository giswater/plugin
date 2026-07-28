/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1246

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_macrosector()
  RETURNS trigger AS
$BODY$

DECLARE
	v_view_name TEXT; -- EDIT | UI
	v_macrosector_id INTEGER;
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

	IF TG_OP = 'INSERT' THEN

		SELECT max(macrosector_id::integer)+1 INTO v_macrosector_id FROM macrosector WHERE macrosector_id::text ~ '^[0-9]+$';
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'MACROSECTOR', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		IF NEW.code IS NULL THEN
			NEW.code := v_macrosector_id::text;
		END IF;

		IF NEW.active IS NULL THEN
			NEW.active = TRUE;
		END IF;

		INSERT INTO macrosector (macrosector_id, code, name, descript, active, expl_id, muni_id, stylesheet, link, lock_level, addparam, created_at, created_by, updated_at, updated_by)
		VALUES (v_macrosector_id, NEW.code, NEW.name, NEW.descript, NEW.active, NEW.expl_id, NEW.muni_id, 
		NEW.stylesheet::json, NEW.link, NEW.lock_level, NEW.addparam::json, now(), current_user, now(), current_user);

		IF v_view_name = 'EDIT' THEN
			UPDATE macrosector SET the_geom = NEW.the_geom WHERE macrosector_id = NEW.macrosector_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF v_view_name = 'EDIT' AND NEW.the_geom IS NOT NULL AND NEW.code IS NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'MACROSECTOR', json_strip_nulls(row_to_json(NEW)::json));
		END IF;

		UPDATE macrosector
		SET macrosector_id=NEW.macrosector_id, code=NEW.code, name=NEW.name, descript=NEW.descript, active=NEW.active, expl_id=NEW.expl_id, 
		muni_id=NEW.muni_id, stylesheet=NEW.stylesheet::json, link=NEW.link, lock_level=NEW.lock_level, addparam=NEW.addparam::json, 
		updated_at=now(), updated_by = current_user
		WHERE macrosector_id=NEW.macrosector_id;


		IF v_view_name = 'EDIT' THEN
			UPDATE macrosector SET the_geom = NEW.the_geom WHERE macrosector_id = OLD.macrosector_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		UPDATE sector SET macrosector_id=NULL WHERE macrosector_id = OLD.macrosector_id;
		DELETE FROM macrosector WHERE macrosector_id = OLD.macrosector_id;
		RETURN NULL;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

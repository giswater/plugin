/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1112

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_dma()  RETURNS trigger AS
$BODY$

DECLARE
	v_view_name TEXT;
	v_count INTEGER;
BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	v_view_name = TG_ARGV[0];

	IF TG_OP = 'INSERT' THEN

		-- expl_id
		IF ((SELECT COUNT(*) FROM exploitation WHERE active IS TRUE) = 0) THEN
			RETURN NULL;
		END IF;


		IF NEW.dma_id != (SELECT last_value FROM urn_id_seq) OR NEW.dma_id IS NULL THEN
			NEW.dma_id:= (SELECT nextval('urn_id_seq'));
		END IF;
		
		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF NEW.code IS NULL AND NEW.the_geom IS NOT NULL THEN
			NEW.code := gw_fct_generate_code('mapzone', 'DMA', json_strip_nulls(row_to_json(NEW)::json));
		END IF;
		IF NEW.code IS NULL THEN
			NEW.code := NEW.dma_id::text;
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

		INSERT INTO dma (dma_id, code, name, descript, active, dma_type, expl_id, sector_id, muni_id, avg_press, pattern_id, effc, graphconfig, stylesheet, link, lock_level, addparam, created_at, created_by, updated_at, updated_by)
		VALUES (NEW.dma_id, NEW.code, NEW.name, NEW.descript, NEW.active, NEW.dma_type, NEW.expl_id, NEW.sector_id, NEW.muni_id, NEW.avg_press, NEW.pattern_id,
		NEW.effc, NEW.graphconfig::json, NEW.stylesheet::json, NEW.link, NEW.lock_level, NEW.addparam::json, now(), current_user, now(), current_user);

		IF v_view_name = 'EDIT' THEN
			UPDATE dma SET the_geom = NEW.the_geom WHERE dma_id = NEW.dma_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF btrim(coalesce(NEW.code, '')) = '' THEN
			NEW.code := NULL;
		END IF;

		IF v_view_name = 'EDIT' THEN
			IF NEW.the_geom IS NOT NULL AND NEW.code IS NULL THEN
				NEW.code := gw_fct_generate_code('mapzone', 'DMA', json_strip_nulls(row_to_json(NEW)::json));
			END IF;
		END IF;

				UPDATE dma
		SET dma_id=NEW.dma_id, code=NEW.code, name=NEW.name, descript=NEW.descript, active=NEW.active, dma_type=NEW.dma_type, expl_id=NEW.expl_id,
		muni_id=NEW.muni_id, sector_id=NEW.sector_id, avg_press=NEW.avg_press, pattern_id=NEW.pattern_id, effc=NEW.effc, graphconfig=NEW.graphconfig::json, 
		stylesheet=NEW.stylesheet::json, link=NEW.link, lock_level=NEW.lock_level, addparam=NEW.addparam::json, updated_at=now(), updated_by = current_user
		WHERE dma_id=OLD.dma_id;

		IF v_view_name = 'EDIT' THEN
			UPDATE dma SET the_geom = NEW.the_geom WHERE dma_id = OLD.dma_id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		-- Check if there are operative elements in the mapzone before allowing delete
		SELECT SUM(counts) INTO v_count FROM (
			SELECT count(*) as counts
				FROM node n
				JOIN value_state_type vst ON vst.id = n.state_type
				WHERE n.dma_id = OLD.dma_id
					AND n.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM arc a
				JOIN value_state_type vst ON vst.id = a.state_type
				WHERE a.dma_id = OLD.dma_id
					AND a.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM connec c
				JOIN value_state_type vst ON vst.id = c.state_type
				WHERE c.dma_id = OLD.dma_id
					AND c.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM gully g
				JOIN value_state_type vst ON vst.id = g.state_type
				WHERE g.dma_id = OLD.dma_id
					AND g.state = 1
					AND vst.is_operative
			UNION ALL
			SELECT count(*) as counts
				FROM link l
				JOIN value_state_type vst ON vst.id = l.state_type
				WHERE l.dma_id = OLD.dma_id
					AND l.state = 1
					AND vst.is_operative
		) combined;
		IF COALESCE(v_count, 0) > 0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4468", "function":"1112","parameters":{"mapzone_name":"DMA", "mapzone_id":'||OLD.dma_id||'}}}$$);';
		END IF;

		UPDATE node SET dma_id = 0 WHERE dma_id = OLD.dma_id;
		UPDATE arc SET dma_id = 0 WHERE dma_id = OLD.dma_id;
		UPDATE connec SET dma_id = 0 WHERE dma_id = OLD.dma_id;
		UPDATE gully SET dma_id = 0 WHERE dma_id = OLD.dma_id;
		UPDATE link SET dma_id = 0 WHERE dma_id = OLD.dma_id;

		DELETE FROM dma WHERE dma_id = OLD.dma_id;
		RETURN NULL;
	END IF;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



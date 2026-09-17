/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_om_visit()
  RETURNS trigger AS
$BODY$
DECLARE

v_version text;
v_featuretype text;
v_triggerfromtable text;
v_expl_id integer;
v_muni_id integer;
v_sector_id integer;


BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	v_featuretype:= TG_ARGV[0];
	v_version = (SELECT giswater FROM sys_version ORDER by 1 desc LIMIT 1);


	IF v_featuretype IS NULL THEN
        v_triggerfromtable = 'om_visit';
	ELSE
        v_triggerfromtable = 'om_visit_x_feature';
	END IF;

	IF TG_OP='INSERT' THEN

		-- automatic creation of workcat
		IF (SELECT (value::json->>'AutoNewWorkcat') FROM config_param_system WHERE parameter='om_visit_parameters') THEN
			INSERT INTO cat_work (id) VALUES (NEW.id);
		END IF;

		IF v_triggerfromtable = 'om_visit' THEN -- we need workflow when function is triggered by om_visit (for this reason when parameter is null)

			-- Setting expl_id when visit have geometry
			IF NEW.expl_id IS NULL THEN
				v_expl_id := (SELECT expl_id FROM exploitation WHERE active IS TRUE AND ST_DWithin(NEW.the_geom, exploitation.the_geom,0.001) LIMIT 1);
                UPDATE om_visit SET expl_id=v_expl_id WHERE id=NEW.id;
			END IF;

			-- Setting muni_id from user default, then geometry
			IF NEW.muni_id IS NULL THEN
				v_muni_id := (SELECT "value" FROM config_param_user WHERE "parameter"='edit_municipality_vdefault' AND "cur_user"="current_user"());
				IF (v_muni_id IS NULL AND NEW.the_geom IS NOT NULL) THEN
					v_muni_id := (SELECT m.muni_id FROM v_municipality m WHERE ST_Intersects(NEW.the_geom, m.the_geom) AND m.active IS TRUE LIMIT 1);
				END IF;
				IF v_muni_id IS NOT NULL THEN
					UPDATE om_visit SET muni_id=v_muni_id WHERE id=NEW.id;
				END IF;
			END IF;

			-- Setting sector_id when visit have geometry
			IF NEW.sector_id IS NULL AND NEW.the_geom IS NOT NULL THEN
				v_sector_id := (SELECT sector_id FROM sector WHERE active IS TRUE AND ST_Intersects(NEW.the_geom, sector.the_geom) LIMIT 1);
				IF v_sector_id IS NOT NULL THEN
					UPDATE om_visit SET sector_id=v_sector_id WHERE id=NEW.id;
				END IF;
			END IF;

			-- if uses lot_manage, equal visitcat and visitclass (in order to fill Visit tab)
			IF (SELECT value::json->>'lotManage' FROM config_param_system WHERE parameter='plugin_lotmanage')='TRUE' AND NEW.class_id IS NULL THEN
				UPDATE om_visit SET class_id=NEW.visitcat_id WHERE id=NEW.id;
			END IF;

            -- when visit is not finished
			IF NEW.status < 4 THEN
				NEW.enddate=null;

			-- when visit is finished and it has not lot_id assigned visit is automatic published
			ELSIF NEW.status=4 AND NEW.lot_id IS NULL THEN
				UPDATE om_visit SET publish=TRUE WHERE id=NEW.id;
			END IF;

			-- set visit_type from class_id only when it was not provided (Add Visit form)
			IF NEW.visit_type IS NULL THEN
				UPDATE om_visit v SET visit_type = c.visit_type
				FROM config_visit_class c
				WHERE v.id = NEW.id AND v.class_id = c.id AND v.visit_type IS NULL;
			END IF;

		ELSIF v_triggerfromtable = 'om_visit_x_feature' THEN

			-- Getting expl_id / muni_id / sector_id when visit have related feature
			IF v_featuretype='arc' THEN
				SELECT expl_id, muni_id, sector_id INTO v_expl_id, v_muni_id, v_sector_id FROM arc WHERE arc_id=NEW.arc_id;
			ELSIF v_featuretype='node' THEN
				SELECT expl_id, muni_id, sector_id INTO v_expl_id, v_muni_id, v_sector_id FROM node WHERE node_id=NEW.node_id;
			ELSIF v_featuretype='connec' THEN
				SELECT expl_id, muni_id, sector_id INTO v_expl_id, v_muni_id, v_sector_id FROM connec WHERE connec_id=NEW.connec_id;
			ELSIF v_featuretype='gully' THEN
				SELECT expl_id, muni_id, sector_id INTO v_expl_id, v_muni_id, v_sector_id FROM gully WHERE gully_id=NEW.gully_id;
			ELSIF v_featuretype='link' THEN
				SELECT expl_id, muni_id, sector_id INTO v_expl_id, v_muni_id, v_sector_id FROM link WHERE link_id=NEW.link_id;
			END IF;

			-- Setting values only the first time they are null (sector 0 is the column default)
			UPDATE om_visit SET
				expl_id = COALESCE(om_visit.expl_id, v_expl_id),
				muni_id = COALESCE(om_visit.muni_id, v_muni_id),
				sector_id = COALESCE(NULLIF(om_visit.sector_id, 0), v_sector_id)
			WHERE id=NEW.visit_id
				AND (expl_id IS NULL OR muni_id IS NULL OR sector_id IS NULL OR sector_id = 0);

			-- update is_last visit from each feature_type

			UPDATE om_visit_event SET is_last = TRUE WHERE id = NEW.id;
			UPDATE om_visit_event SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_event GROUP BY visit_id);

			EXECUTE format(
			    'UPDATE %I SET is_last = TRUE WHERE id = $1',
			    'om_visit_x_' || v_featuretype
			) USING NEW.id;

			EXECUTE format(
			    'UPDATE %I SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM %I GROUP BY %I)',
			    'om_visit_x_' || v_featuretype,
			    'om_visit_x_' || v_featuretype,
			    v_featuretype || '_id'
			);

		END IF;

		RETURN NEW;

	ELSIF TG_OP='UPDATE' AND v_triggerfromtable ='om_visit' THEN -- we need workflow when function is triggered by om_visit (for this reason when parameter is null)

		-- move status of lot element to status=0 (visited)
		IF NEW.status <> 4 THEN
			NEW.enddate=null;

			-- when visit is finished and it has lot_id assigned visit is automatic published
			IF NEW.status=5 AND NEW.lot_id IS NOT NULL THEN
				UPDATE om_visit SET publish=TRUE WHERE id=NEW.id;
			END IF;
		END IF;

		IF NEW.class_id != OLD.class_id THEN
			DELETE FROM om_visit_event WHERE visit_id=NEW.id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP='DELETE' THEN

		-- automatic creation of workcat
		IF (SELECT (value::json->>'AutoNewWorkcat') FROM config_param_system WHERE parameter='om_visit_parameters') THEN
			DELETE FROM cat_work WHERE id=OLD.id::text;
		END IF;

		RETURN OLD;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



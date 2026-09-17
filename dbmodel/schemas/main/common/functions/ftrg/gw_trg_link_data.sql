/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- FUNCTION CODE: 3214


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_link_data() RETURNS trigger AS $BODY$
DECLARE
v_projecttype text;
v_feature_type text;

BEGIN
	-- set search_path
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- select config values
	SELECT upper(project_type)  INTO v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;

	v_feature_type = upper(TG_ARGV[0]);

	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN

		IF v_feature_type = 'LINK' THEN

			IF v_projecttype = 'WS' THEN
				UPDATE link l
				SET linkcat_id = NEW.linkcat_id, top_elev1 = COALESCE(NEW.top_elev1, (SELECT top_elev FROM connec WHERE connec_id=NEW.feature_id LIMIT 1)),
				depth1 = COALESCE(NEW.depth1, (SELECT depth FROM connec WHERE connec_id=NEW.feature_id LIMIT 1))
				WHERE l.feature_id = NEW.feature_id AND l.state > 0 AND l.link_id = NEW.link_id;

				UPDATE link l SET is_operative = v.is_operative, expl_visibility = c.expl_visibility, fluid_type = c.fluid_type, muni_id = c.muni_id
				FROM connec c
				JOIN value_state_type v ON v.id = c.state_type WHERE l.feature_id = c.connec_id AND c.connec_id = NEW.feature_id AND l.state > 0 AND link_id = NEW.link_id;
			ELSE
				IF NEW.top_elev1 IS NULL THEN
					IF NEW.feature_type ='CONNEC' THEN
						NEW.top_elev1 = (SELECT top_elev FROM connec WHERE connec_id=NEW.feature_id LIMIT 1);
					ELSEIF NEW.feature_type ='GULLY' THEN
						NEW.top_elev1 = (SELECT top_elev FROM gully WHERE gully_id=NEW.feature_id LIMIT 1);
					END IF;
				END IF;

				UPDATE link l
				SET linkcat_id = NEW.linkcat_id, top_elev1 = NEW.top_elev1
				WHERE l.feature_id = NEW.feature_id AND l.state > 0 AND l.link_id = NEW.link_id;

				UPDATE link l SET is_operative = v.is_operative, expl_visibility = c.expl_visibility, fluid_type = c.fluid_type, muni_id = c.muni_id
				FROM gully c
				JOIN value_state_type v ON v.id = c.state_type WHERE l.feature_id = c.gully_id AND c.gully_id = NEW.feature_id AND l.state > 0 AND link_id = NEW.link_id;

				UPDATE link l SET is_operative = v.is_operative, expl_visibility = c.expl_visibility, fluid_type = c.fluid_type, muni_id = c.muni_id
				FROM connec c
				JOIN value_state_type v ON v.id = c.state_type WHERE l.feature_id = c.connec_id AND c.connec_id = NEW.feature_id AND l.state > 0 AND link_id = NEW.link_id;
			END IF;

			IF (SELECT value::boolean FROM config_param_system WHERE parameter ='edit_link_autoupdate_connect_length') IS true AND NEW.uncertain IS FALSE THEN
				UPDATE connec c SET connec_length = st_length(NEW.the_geom) WHERE c.connec_id = NEW.feature_id;
				IF v_projecttype = 'UD' THEN
					UPDATE gully g SET connec_length = st_length(NEW.the_geom) WHERE g.gully_id = NEW.feature_id;
				END IF;
			END IF;
		END IF;
	END IF;

	IF TG_OP = 'UPDATE' THEN

		IF v_feature_type = 'CONNEC'  THEN

			IF v_projecttype = 'WS' THEN
				UPDATE link SET is_operative = v.is_operative, expl_visibility = NEW.expl_visibility, fluid_type = NEW.fluid_type, muni_id = NEW.muni_id
				FROM value_state_type v WHERE id = NEW.state_type AND feature_id = NEW.connec_id;
			ELSE
				UPDATE link SET is_operative = v.is_operative, expl_visibility = NEW.expl_visibility, fluid_type = NEW.fluid_type,muni_id = NEW.muni_id
				FROM value_state_type v WHERE id = NEW.state_type AND feature_id = NEW.connec_id;
			END IF;

		ELSIF v_feature_type = 'GULLY' THEN
			UPDATE link SET is_operative = v.is_operative, expl_visibility = NEW.expl_visibility, fluid_type = NEW.fluid_type, muni_id = NEW.muni_id
			FROM value_state_type v WHERE id = NEW.state_type AND feature_id = NEW.gully_id;
		END IF;
	END IF;

	RETURN NEW;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;







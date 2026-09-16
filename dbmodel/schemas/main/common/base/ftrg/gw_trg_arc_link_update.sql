/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2542

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_trg_arc_vnodelink_update() CASCADE;
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_arc_link_update()
  RETURNS trigger AS
$BODY$

/*
This function redraws links when arc geometry is updated.

Topology is taken from link.exit_id (not connec.arc_id): planned links store the
arc on the link / plan_psector_x_* row, while connec.arc_id stays on the operative arc.

It is mandatory to activate psectors in order to not disconnect planned links.
*/

DECLARE
v_link record;
v_closest_point PUBLIC.geometry;
v_debugmsg text;
v_projecttype text;
v_disable_arc_linkupdate boolean := false;

BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- select config values
	SELECT upper(project_type)  INTO v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT COALESCE(value::boolean, false) INTO v_disable_arc_linkupdate
	FROM config_param_user
	WHERE parameter = 'edit_disable_arc_linkupdate'
	AND cur_user = current_user;

	IF v_disable_arc_linkupdate IS TRUE THEN
		RETURN NEW;
	END IF;

    -- only if the geometry has changed (not reversed) because reverse may not affect links....
    IF st_orderingequals(OLD.the_geom, NEW.the_geom) IS FALSE THEN

		-- check if there are not-selected psector affected
		IF (SELECT count (*) FROM plan_psector_x_connec JOIN plan_psector USING (psector_id)
		WHERE arc_id = NEW.arc_id AND state = 1 AND status IN (1,2) AND psector_id NOT IN (SELECT psector_id FROM selector_psector WHERE cur_user=current_user)) > 0 THEN

			SELECT concat('Psector: ',string_agg(distinct name::text, ', ')) into v_debugmsg FROM plan_psector_x_connec JOIN plan_psector USING (psector_id)
			WHERE arc_id = NEW.arc_id AND state = 1 AND status IN (1,2) AND psector_id NOT IN (SELECT psector_id FROM selector_psector WHERE cur_user=current_user);

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3180", "function":"2542","parameters":{"debugmsg":"'||v_debugmsg||'"}}}$$);';
		END IF;

		IF v_projecttype = 'UD' THEN
			IF (SELECT count (*) FROM plan_psector_x_gully JOIN plan_psector USING (psector_id)
			WHERE arc_id = NEW.arc_id AND state = 1 AND status IN (1,2) AND psector_id NOT IN (SELECT psector_id FROM selector_psector WHERE cur_user=current_user)) > 0 THEN

				SELECT concat('Psector: ',string_agg(distinct name::text, ', ')) into v_debugmsg FROM plan_psector_x_gully JOIN plan_psector USING (psector_id)
				WHERE arc_id = NEW.arc_id AND state = 1 AND status IN (1,2) AND psector_id NOT IN (SELECT psector_id FROM selector_psector WHERE cur_user=current_user);

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3180", "function":"2542","parameters":{"debugmsg":"'||v_debugmsg||'"}}}$$);';
			END IF;
		END IF;

		-- Redraw endpoint of every link that exits onto this arc (operative and planned)
		FOR v_link IN
			SELECT * FROM link
			WHERE exit_type = 'ARC' AND exit_id = NEW.arc_id
		LOOP
			v_closest_point := ST_ClosestPoint(NEW.the_geom, ST_EndPoint(v_link.the_geom));
			UPDATE link SET the_geom = ST_SetPoint(v_link.the_geom, ST_NumPoints(v_link.the_geom) - 1, v_closest_point)
			WHERE link_id = v_link.link_id;
		END LOOP;
    END IF;

    RETURN NEW;


END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

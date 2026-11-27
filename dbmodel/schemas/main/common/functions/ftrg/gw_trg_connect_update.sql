/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2732


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_connect_update() RETURNS trigger LANGUAGE plpgsql AS $$

/*
This trigger updates mapzone connect columns ( if that connecs are connected) and redraw link geometry if end connect geometry is also updated
As updateable links only must be class 2 (wich geometry is stored on link table, it is not need to work with ve_link, and as a result this trigger works with table link)
*/

DECLARE

linkrec Record;
querystring text;
connecRecord1 record;
connecRecord2 record;
connecRecord3 record;
v_projectype text;
v_featuretype text;
gullyRecord1 record;
gullyRecord2 record;
gullyRecord3 record;
v_link record;
xvar float;
yvar float;
v_dma_autoupdate boolean;
v_pol_id text;
v_dma_value integer;
v_arc record;
v_trace_featuregeom boolean;

BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
    v_featuretype:= TG_ARGV[0];

    v_projectype = (SELECT project_type FROM sys_version ORDER BY id DESC LIMIT 1);

    SELECT value INTO v_dma_autoupdate FROM config_param_system WHERE parameter = 'edit_connect_autoupdate_dma';

    -- get arc values
    SELECT * INTO v_arc FROM arc WHERE arc_id = NEW.arc_id;

    -- control of dma automatic values
	IF v_projectype = 'WS' THEN
	    IF v_dma_autoupdate IS TRUE OR v_dma_autoupdate IS NULL THEN v_dma_value = v_arc.dma_id; ELSE v_dma_value = NEW.dma_id; END IF;

		IF v_dma_value IS NULL THEN v_dma_value = NEW.dma_id; END IF;
	END IF;

	IF v_featuretype='connec' THEN

		-- updating links geom
		IF st_equals (NEW.the_geom, OLD.the_geom) IS FALSE THEN

			--Select links with start on the updated connec
			querystring := 'SELECT * FROM ve_link WHERE feature_id = ' || quote_literal(NEW.connec_id) || ' AND feature_type=''CONNEC''';
			FOR linkrec IN EXECUTE querystring
			LOOP
				EXECUTE 'UPDATE link SET the_geom = ST_SetPoint($1, 0, $2) WHERE link_id = ' || quote_literal(linkrec."link_id") USING linkrec.the_geom, NEW.the_geom;
			END LOOP;

			--Select links with end on the updated connec
			querystring := 'SELECT * FROM ve_link WHERE exit_id = ' || quote_literal(NEW.connec_id) || ' AND exit_type=''CONNEC''';
			FOR linkrec IN EXECUTE querystring
			LOOP
				EXECUTE 'UPDATE link SET the_geom = ST_SetPoint($1, ST_NumPoints($1) - 1, $2) WHERE link_id = ' || quote_literal(linkrec."link_id")
				USING linkrec.the_geom, NEW.the_geom;
			END LOOP;
		END IF;

		-- update the rest of the feature parameters for state = 1 connects
		FOR v_link IN SELECT * FROM ve_link WHERE (exit_type='CONNEC' AND exit_id=OLD.connec_id) AND state = 1
		LOOP
			IF v_link.feature_type='CONNEC' THEN

				IF v_projectype = 'WS' THEN
					UPDATE connec SET arc_id=NEW.arc_id, expl_id=NEW.expl_id, sector_id=NEW.sector_id, presszone_id = NEW.presszone_id, dqa_id = NEW.dqa_id, dma_id = NEW.dma_id,
					omzone_id = NEW.omzone_id, minsector_id = NEW.minsector_id
					WHERE connec_id=v_link.feature_id;

				ELSIF v_projectype = 'UD' THEN
					UPDATE connec SET arc_id=NEW.arc_id, expl_id=NEW.expl_id, omzone_id = NEW.omzone_id, sector_id=NEW.sector_id
					WHERE connec_id=v_link.feature_id;
				END IF;

			ELSIF v_link.feature_type='GULLY' THEN

				UPDATE gully SET arc_id=NEW.arc_id, expl_id=NEW.expl_id, dma_id= v_dma_value, sector_id=NEW.sector_id
				WHERE gully_id=v_link.feature_id;
			END IF;
		END LOOP;


		-- update planned links (and planned connects as well)
		FOR v_link IN SELECT * FROM ve_link WHERE (exit_type='CONNEC' AND exit_id=OLD.connec_id) AND state = 2
		LOOP
			IF v_projectype = 'WS' THEN
				UPDATE link SET expl_id=NEW.expl_id, sector_id=NEW.sector_id, dma_id = NEW.dma_id, omzone_id = NEW.omzone_id,
				presszone_id = NEW.presszone_id, dqa_id = NEW.dqa_id, minsector_id = NEW.minsector_id
				WHERE link_id=v_link.link_id;
			ELSE
				UPDATE link SET expl_id=NEW.expl_id, sector_id=NEW.sector_id, omzone_id = NEW.omzone_id
				WHERE link_id=v_link.link_id;

				UPDATE plan_psector_x_gully SET arc_id = NEW.arc_id WHERE link_id = v_link.link_id;
			END IF;

			UPDATE plan_psector_x_connec SET arc_id = NEW.arc_id WHERE link_id = v_link.link_id;

		END LOOP;

		-- Updating polygon geometry (if exists) and trace_featuregeom is true
		v_pol_id:= (SELECT pol_id FROM polygon WHERE feature_id=OLD.connec_id);
		v_trace_featuregeom:= (SELECT trace_featuregeom FROM polygon WHERE feature_id=OLD.connec_id);
		-- if trace_featuregeom is false, do nothing
		IF v_trace_featuregeom is true then
			IF st_equals (NEW.the_geom, OLD.the_geom) IS FALSE AND (v_pol_id IS NOT NULL) THEN
				xvar= (st_x(NEW.the_geom)-st_x(OLD.the_geom));
				yvar= (st_y(NEW.the_geom)-st_y(OLD.the_geom));
				UPDATE polygon SET the_geom=ST_translate(the_geom, xvar, yvar) WHERE pol_id=v_pol_id;
			END IF;
		END IF;

	ELSIF v_featuretype='gully' THEN

		-- Updating polygon geometry (if exists) and trace_featuregeom is true
		v_pol_id:= (SELECT pol_id FROM polygon WHERE feature_id=OLD.gully_id);
		v_trace_featuregeom:= (SELECT trace_featuregeom FROM polygon WHERE feature_id=OLD.gully_id);
		-- if trace_featuregeom is false, do nothing
		IF v_trace_featuregeom is true then
			IF st_equals (NEW.the_geom, OLD.the_geom) IS FALSE AND (v_pol_id IS NOT NULL) THEN
				xvar= (st_x(NEW.the_geom)-st_x(OLD.the_geom));
				yvar= (st_y(NEW.the_geom)-st_y(OLD.the_geom));
				UPDATE polygon SET the_geom=ST_translate(the_geom, xvar, yvar) WHERE pol_id=v_pol_id;
			END IF;
		END IF;

		-- updating links geom
		IF st_equals (NEW.the_geom, OLD.the_geom) IS FALSE THEN

			--Select links with start on the updated gully
			querystring := 'SELECT * FROM ve_link WHERE feature_id = ' || quote_literal(NEW.gully_id) || ' AND feature_type=''GULLY''';
			FOR linkrec IN EXECUTE querystring
			LOOP
				EXECUTE 'UPDATE link SET the_geom = ST_SetPoint($1, 0, $2) WHERE link_id = ' || quote_literal(linkrec."link_id") USING linkrec.the_geom, NEW.the_geom;
			END LOOP;

			--Select links with end on the updated gully
			querystring := 'SELECT * FROM ve_link WHERE exit_id = ' || quote_literal(NEW.gully_id) || ' AND exit_type=''GULLY''';
			FOR linkrec IN EXECUTE querystring
			LOOP
				EXECUTE 'UPDATE link SET the_geom = ST_SetPoint($1, ST_NumPoints($1) - 1, $2) WHERE link_id = ' || quote_literal(linkrec."link_id")
				USING linkrec.the_geom, NEW.the_geom;
			END LOOP;
		END IF;

		-- update the rest of the feature parameters for state = 1 connects
		FOR v_link IN SELECT * FROM ve_link WHERE (exit_type='GULLY' AND exit_id=OLD.gully_id) AND state = 1
		LOOP
			IF v_link.feature_type='CONNEC' THEN

				IF v_projectype = 'WS' THEN
					UPDATE connec SET arc_id=NEW.arc_id, expl_id=NEW.expl_id, dma_id= v_dma_value, omzone_id = NEW.omzone_id, sector_id=NEW.sector_id
					WHERE connec_id=v_link.feature_id;
				ELSE
					UPDATE connec SET arc_id=NEW.arc_id, expl_id=NEW.expl_id, omzone_id = NEW.omzone_id, sector_id=NEW.sector_id
					WHERE connec_id=v_link.feature_id;
				END IF;

			ELSIF v_link.feature_type='GULLY' THEN

				IF v_projectype = 'WS' THEN
					UPDATE gully SET arc_id=NEW.arc_id, expl_id=NEW.expl_id, dma_id= v_dma_value, omzone_id = NEW.omzone_id, sector_id=NEW.sector_id
					WHERE gully_id=v_link.feature_id;
				ELSE
					UPDATE gully SET arc_id=NEW.arc_id, expl_id=NEW.expl_id, omzone_id = NEW.omzone_id, sector_id=NEW.sector_id
					WHERE gully_id=v_link.feature_id;
				END IF;
			END IF;
		END LOOP;

		-- update planned links (and planned connects as well)
		FOR v_link IN SELECT * FROM ve_link WHERE (exit_type='GULLY' AND exit_id=OLD.gully_id) AND state = 2
		LOOP
			IF v_projectype = 'WS' THEN
				UPDATE link SET expl_id=NEW.expl_id, sector_id=NEW.sector_id, dma_id = v_dma_value, omzone_id = NEW.omzone_id
				WHERE link_id=v_link.link_id;
			ELSE
				UPDATE link SET expl_id=NEW.expl_id, sector_id=NEW.sector_id, omzone_id = NEW.omzone_id
				WHERE link_id=v_link.link_id;
			END IF;

			UPDATE plan_psector_x_gully SET arc_id = NEW.arc_id WHERE link_id = v_link.link_id;

		END LOOP;
	END IF;

	RETURN NEW;

END;
$$;


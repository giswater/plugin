/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3528

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_autoupdate_arc_topology() RETURNS trigger AS $BODY$
DECLARE

v_node_topelev_autoupdate integer := 0;
v_node_top_elev_1 numeric(12,3);
v_node_top_elev_2 numeric(12,3);

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	SELECT value::integer INTO v_node_topelev_autoupdate FROM config_param_user WHERE parameter='edit_node_topelev_options' AND cur_user = current_user;
	v_node_topelev_autoupdate := COALESCE(v_node_topelev_autoupdate, 0);

	IF NEW.node_1 IS NOT NULL THEN
		SELECT COALESCE(custom_top_elev, top_elev) INTO v_node_top_elev_1 FROM node WHERE node_id = NEW.node_1;
	END IF;

	IF NEW.node_2 IS NOT NULL THEN
		SELECT COALESCE(custom_top_elev, top_elev) INTO v_node_top_elev_2 FROM node WHERE node_id = NEW.node_2;
	END IF;

	-- node_1
	IF v_node_top_elev_1 IS NOT NULL AND (
		TG_OP = 'INSERT'
		OR NEW.node_1 IS DISTINCT FROM OLD.node_1
		OR NEW.y1 IS DISTINCT FROM OLD.y1
		OR NEW.elev1 IS DISTINCT FROM OLD.elev1
	) THEN
		IF v_node_topelev_autoupdate = 0 THEN
			IF NEW.y1 IS NOT NULL THEN
				NEW.elev1 := v_node_top_elev_1 - NEW.y1;
			ELSIF NEW.elev1 IS NOT NULL THEN
				NEW.y1 := v_node_top_elev_1 - NEW.elev1;
			END IF;
		ELSIF v_node_topelev_autoupdate = 1 THEN
			IF NEW.elev1 IS NOT NULL THEN
				NEW.y1 := v_node_top_elev_1 - NEW.elev1;
			ELSIF NEW.y1 IS NOT NULL THEN
				NEW.elev1 := v_node_top_elev_1 - NEW.y1;
			END IF;
		END IF;
	END IF;

	-- node_2
	IF v_node_top_elev_2 IS NOT NULL AND (
		TG_OP = 'INSERT'
		OR NEW.node_2 IS DISTINCT FROM OLD.node_2
		OR NEW.y2 IS DISTINCT FROM OLD.y2
		OR NEW.elev2 IS DISTINCT FROM OLD.elev2
	) THEN
		IF v_node_topelev_autoupdate = 0 THEN
			IF NEW.y2 IS NOT NULL THEN
				NEW.elev2 := v_node_top_elev_2 - NEW.y2;
			ELSIF NEW.elev2 IS NOT NULL THEN
				NEW.y2 := v_node_top_elev_2 - NEW.elev2;
			END IF;
		ELSIF v_node_topelev_autoupdate = 1 THEN
			IF NEW.elev2 IS NOT NULL THEN
				NEW.y2 := v_node_top_elev_2 - NEW.elev2;
			ELSIF NEW.y2 IS NOT NULL THEN
				NEW.elev2 := v_node_top_elev_2 - NEW.y2;
			END IF;
		END IF;
	END IF;

RETURN NEW;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

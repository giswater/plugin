/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2938

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_plan_psector_link()
  RETURNS trigger AS
$BODY$


DECLARE

v_table_name text;
v_projecttype text;
v_connect integer;
v_featuretype text;
v_feature integer;
v_id integer;

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	v_table_name:= TG_ARGV[0];
	v_projecttype = (SELECT project_type FROM sys_version ORDER BY id DESC LIMIT 1);

	-- setting variables
	v_id = NEW.id;

	-- getting variables in function of table
	IF v_table_name = 'connec' THEN
		v_featuretype = 'CONNEC';
		v_feature = NEW.connec_id;

	ELSIF v_table_name = 'gully' THEN
		v_featuretype = 'GULLY';
		v_feature = NEW.gully_id;
	END IF;

	-- executing options
	IF TG_OP = 'INSERT' THEN

		IF NEW.state = 1 AND NEW.arc_id IS NOT NULL AND NEW.link_id IS NULL THEN

			EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
			"feature":{"id":["'|| v_feature ||'"]},"data":{"feature_type":"'|| v_featuretype ||'", "isPsector":"true", "forcedArcs":['||NEW.arc_id||']}}$$)';
		END IF;

	ELSIF TG_OP = 'UPDATE' THEN

		-- Block arc_id update when state = 0
		IF (OLD.state = 0 AND NEW.state = 0) AND NEW.arc_id IS DISTINCT FROM OLD.arc_id THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
			"data":{"message":"3286", "function":"2938","parameters":{"psector_id":"'||NEW.psector_id||'"}}}$$);';
		END IF;


		IF NEW.state = 1 AND COALESCE(NEW.arc_id,0) != COALESCE(OLD.arc_id,0) AND COALESCE(NEW.link_id,0) = COALESCE(OLD.link_id,0) THEN

			IF NEW.arc_id IS NULL THEN

				IF (SELECT exit_type FROM link WHERE link_id = NEW.link_id) = 'ARC' THEN
					EXECUTE 'UPDATE plan_psector_x_'||v_table_name||' SET link_id = NULL WHERE id = '||v_id;
					DELETE FROM link WHERE link_id = NEW.link_id;
				END IF;
			ELSE
				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":["'|| v_feature ||'"]},"data":{"feature_type":"'|| v_featuretype ||'", "isPsector":"true", "forcedArcs":['||NEW.arc_id||']}}$$)';
			END IF;
		END IF;
	END IF;

	-- reconnect connects
	IF v_table_name = 'connec' THEN

		-- looking for related connecs
		FOR v_connect IN SELECT feature_id FROM ve_link WHERE feature_type = 'CONNEC' AND exit_type = 'CONNEC' and exit_id = NEW.connec_id
		LOOP
			UPDATE plan_psector_x_connec SET arc_id = NEW.arc_id WHERE connec_id = v_connect AND psector_id = NEW.psector_id AND state = 1;
		END LOOP;

		-- looking for related gullies
		IF v_projecttype = 'UD' THEN
			FOR v_connect IN SELECT feature_id FROM ve_link WHERE feature_type = 'GULLY' AND exit_type = 'CONNEC' and exit_id = NEW.connec_id
			LOOP

				UPDATE plan_psector_x_gully SET arc_id = NEW.arc_id WHERE gully_id = v_connect AND psector_id = NEW.psector_id AND state = 1;
			END LOOP;
		END IF;


	ELSIF v_table_name = 'gully' THEN

		-- looking for related connecs
		FOR v_connect IN SELECT feature_id FROM ve_link WHERE feature_type = 'CONNEC' AND exit_type = 'GULLY' and exit_id = NEW.gully_id
		LOOP
			UPDATE plan_psector_x_connec SET arc_id = NEW.arc_id WHERE connec_id = v_connect AND psector_id = NEW.psector_id AND state = 1;
		END LOOP;

		-- looking for related gullies
		FOR v_connect IN SELECT feature_id FROM ve_link WHERE feature_type = 'GULLY' AND exit_type = 'GULLY' and exit_id = NEW.gully_id
		LOOP
			UPDATE plan_psector_x_gully SET arc_id = NEW.arc_id WHERE gully_id = v_connect AND psector_id = NEW.psector_id AND state = 1;
		END LOOP;
	END IF;

	RETURN NEW;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

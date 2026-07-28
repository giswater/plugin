/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/

--FUNCTION CODE: 2996


CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_element_pol() RETURNS trigger AS
$BODY$


BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';


	-- INSERT
	IF TG_OP = 'INSERT' THEN

		-- Pol ID
		IF (NEW.pol_id IS NULL) THEN
			NEW.pol_id:= (SELECT nextval('urn_id_seq'));
		END IF;

		-- element id
		IF (NEW.element_id IS NULL) THEN
			NEW.element_id := (SELECT element_id FROM element WHERE ST_DWithin(NEW.the_geom, element.the_geom,0.001) LIMIT 1);
			IF (NEW.element_id IS NULL) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
   			"data":{"message":"2094", "function":"2996","parameters":null}}$$);';
			END IF;
		END IF;

		-- Insert into polygon table
		INSERT INTO polygon (pol_id, sys_type, the_geom, featurecat_id, feature_id, state)
		SELECT NEW.pol_id, feature_class, NEW.the_geom, element_type, NEW.element_id, e.state
		FROM element e
		JOIN cat_element ce ON ce.id = e.elementcat_id
		JOIN cat_feature_element cfe ON cfe.id = ce.element_type
		JOIN cat_feature cf ON cf.id = cfe.id
		WHERE element_id=NEW.element_id
		ON CONFLICT (feature_id) DO UPDATE SET the_geom=NEW.the_geom;

		RETURN NEW;


	-- UPDATE
	ELSIF TG_OP = 'UPDATE' THEN

		UPDATE polygon SET pol_id=NEW.pol_id, the_geom=NEW.the_geom, trace_featuregeom=NEW.trace_featuregeom WHERE pol_id=OLD.pol_id;

		IF (NEW.element_id != OLD.element_id) THEN
			IF (SELECT element_id FROM element WHERE element_id=NEW.element_id) iS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
   			"data":{"message":"2098", "function":"2996","parameters":null}}$$);';
			END IF;

			UPDATE polygon SET feature_id=NEW.element_id, featurecat_id = element_type
			FROM element WHERE element_id=OLD.element_id AND pol_id=NEW.pol_id;
		END IF;

		RETURN NEW;

	-- DELETE
	ELSIF TG_OP = 'DELETE' THEN

		DELETE FROM polygon WHERE pol_id=OLD.pol_id;

		RETURN NULL;

	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
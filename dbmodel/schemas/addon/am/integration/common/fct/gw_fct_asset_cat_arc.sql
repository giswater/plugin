/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


-----------
-- cat_arc
------------

SET search_path = am, public;

CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_asset_cat_arc()  RETURNS trigger AS
$BODY$

DECLARE

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	IF TG_OP = 'INSERT' THEN

		INSERT INTO am.config_catalog_def (arccat_id, project_type, dnom)
		VALUES (NEW.id, 'WS', NEW.dnom::numeric)
		ON CONFLICT (arccat_id, project_type) DO NOTHING;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		UPDATE am.config_catalog_def SET dnom = NEW.dnom::numeric
		WHERE arccat_id = OLD.id AND project_type = 'WS';

		RETURN NEW;
	END IF;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

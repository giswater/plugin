/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


-----------
-- cat_node
------------

SET search_path = am, public;

CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_asset_cat_node()  RETURNS trigger AS
$BODY$

DECLARE

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	IF TG_OP = 'INSERT' THEN

		INSERT INTO am.config_nodecatalog_def (nodecat_id, dnom)
		VALUES (
			NEW.id,
			NULLIF(regexp_replace(COALESCE(NEW.dnom, ''), '[^0-9\.]', '', 'g'), '')::numeric
		)
		ON CONFLICT (nodecat_id) DO NOTHING;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		UPDATE am.config_nodecatalog_def
		SET dnom = NULLIF(regexp_replace(COALESCE(NEW.dnom, ''), '[^0-9\.]', '', 'g'), '')::numeric
		WHERE nodecat_id = OLD.id;

		RETURN NEW;
	END IF;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

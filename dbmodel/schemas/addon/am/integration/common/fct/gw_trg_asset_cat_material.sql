/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

------------
-- material
------------

SET search_path = am, public;

CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_asset_cat_material()  RETURNS trigger AS
$BODY$

DECLARE
	v_project_type varchar(2);

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	SELECT upper(project_type) INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	IF TG_OP = 'INSERT' THEN

		INSERT INTO am.config_material_def (
			material, project_type, pleak, age_max, age_med, age_min, builtdate_vdef, compliance
		)
		VALUES (NEW.id, v_project_type, 0.16, 58, 50, 42, 1964, 10)
		ON CONFLICT (material, project_type) DO NOTHING;

		RETURN NEW;
	END IF;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


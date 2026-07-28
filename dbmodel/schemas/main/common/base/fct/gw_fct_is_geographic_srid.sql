/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_is_geographic_srid(integer);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_is_geographic_srid(p_srid integer)
RETURNS boolean AS
$BODY$
BEGIN
	IF p_srid IS NULL THEN
		RETURN NULL;
	END IF;

	RETURN EXISTS (
		SELECT 1 FROM spatial_ref_sys
		WHERE srid = p_srid
		AND (
			proj4text ~ '^\+proj=(longlat|latlong|lonlat)'
			OR srtext LIKE 'GEOGCS%'
			OR srtext LIKE 'GEOGCRS%'
		)
	);
END;
$BODY$
  LANGUAGE plpgsql STABLE;

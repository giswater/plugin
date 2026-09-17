/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3572

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_set_updated()
RETURNS trigger
LANGUAGE plpgsql
AS $BODY$
BEGIN
	NEW.updated_at := clock_timestamp();
	NEW.updated_by := current_user;
	RETURN NEW;
END;
$BODY$;

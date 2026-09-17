/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3202
-- No-op stub: denormalized arc node values are computed in ve_arc (JOIN).
-- Kept so historical patches can CREATE TRIGGER; dropped in 4.17.0.

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_arc_node_values() RETURNS trigger AS $BODY$
BEGIN
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

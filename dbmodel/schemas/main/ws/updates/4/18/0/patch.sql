/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Persist mapzone synoptic layout on plan netscenario graph (#965)
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"plan_netscenario_mapzone_graph",
  "column":"synoptic_id", "dataType":"int4"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"plan_netscenario_mapzone_graph",
  "column":"synoptic_geom", "dataType":"geometry(LineString)"}}$$);

CREATE INDEX IF NOT EXISTS plan_netscenario_mapzone_graph_synoptic_id_idx
	ON plan_netscenario_mapzone_graph USING btree (synoptic_id);

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- 4.9 dropped this row on ud. The form reads it on insert to fill top_elev from the DEM.
INSERT INTO config_param_user (parameter, value, cur_user)
SELECT 'edit_insert_show_elevation_from_dem', 'TRUE', users.cur_user
FROM (SELECT DISTINCT cur_user FROM config_param_user) AS users
ON CONFLICT (parameter, cur_user) DO NOTHING;

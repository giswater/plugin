/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- gw_fct_setfeaturereplace (#967) lives in base/fct.
-- update / update_step run reload_fct_ftrg before this folder, so the body
-- is not duplicated here.

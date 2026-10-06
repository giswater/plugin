/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- gw_fct_setinitproject and gw_fct_admin_role_upsertuser live in base/fct.
-- update / update_step run reload_fct_ftrg before this folder, so the bodies
-- are not duplicated here.

-- 3040 was UI/log_level 2; is_process=true RAISED and aborted upsertuser before GRANT/cat_users.
UPDATE sys_message
SET message_type = 'AUDIT', log_level = 0
WHERE id = 3040;

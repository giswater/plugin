/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

UPDATE sys_function
SET function_alias = 'DUPLICATE PSECTOR'
WHERE id = 2734;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4752, 'The new psector name already exists(can be inactive)', 'Try using a different name', 2, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

UPDATE config_form_fields
SET dv_isnullvalue = true
WHERE columnname = 'ownercat_id'
  AND formname ILIKE 've_element%';
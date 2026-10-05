/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

INSERT INTO config_param_system (
	parameter, value, descript, label, isenabled, project_type, datatype, widgettype
)
VALUES (
	'admin_skip_set_updated', 'false',
	'System parameter to skip gw_trg_set_updated (updated_at/updated_by) during bulk or derived updates. Example: scada graph is_scadamap.',
	'Skip set updated:',
	false, 'utils', 'boolean', 'check'
)
ON CONFLICT (parameter) DO NOTHING;

UPDATE sys_function
SET descript = 'BEFORE UPDATE trigger: set updated_at/updated_by from clock_timestamp() and current_user unless admin_skip_set_updated is true'
WHERE id = 3572;

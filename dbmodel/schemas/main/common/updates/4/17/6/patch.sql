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

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3574, 'gw_fct_synoptic_core', 'utils', 'function', 'json', 'json',
'Builds synoptic layout (group_id, level_id, position_id, synopticGeometry) for SCADA or MAPZONE temp graphs',
'role_om', NULL, 'core', NULL)
ON CONFLICT (id) DO UPDATE SET
	function_name = EXCLUDED.function_name,
	descript = EXCLUDED.descript;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4754, 'Unknown synoptic fct_type: %fct_type%. Use SCADA or MAPZONE.', 'Set data.fct_type to SCADA or MAPZONE.', 2, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4756, 'Synoptic layout generated', NULL, 0, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4758, 'Failed to generate synoptic layout: %error%', 'Review the SCADA graph or mapzone synoptic input.', 2, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

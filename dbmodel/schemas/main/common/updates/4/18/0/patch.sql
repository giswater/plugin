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

INSERT INTO sys_table (id, descript, sys_role, "source") VALUES
('v_ui_om_visit_x_doc', 'Shows the documents related to visits. User Interface view.', 'role_om', 'core'),
('v_om_visit', 'Shows all the executed visits.', 'role_om', 'core'),
('vf_exploitation', 'Filtered exploitation view.', 'role_basic', 'core'),
('v_ui_sector_sel', 'Sector selector view.', 'role_basic', 'core'),
('v_ui_macrosector_sel', 'Macrosector selector view.', 'role_basic', 'core'),
('v_ui_dma_sel', 'DMA selector view.', 'role_basic', 'core'),
('v_ui_macroomzone_sel', 'Macroomzone selector view.', 'role_basic', 'core'),
('ve_inp_dscenario_pattern', 'Editable demand-scenario pattern view.', 'role_epa', 'core'),
('ve_inp_dscenario_pattern_value', 'Editable demand-scenario pattern value view.', 'role_epa', 'core')
ON CONFLICT (id) DO NOTHING;
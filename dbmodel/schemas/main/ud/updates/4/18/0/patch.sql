/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

INSERT INTO sys_table (id, descript, sys_role, "source") VALUES
('v_rpt_multi_arcflow_sum', 'Summed multi-result arc flow.', 'role_edit', 'core'),
('v_rpt_multi_nodeflooding_sum', 'Summed multi-result node flooding.', 'role_edit', 'core'),
('v_ui_dma', 'DMA user interface view.', 'role_basic', 'core'),
('v_ui_drainzone_sel', 'Drainzone selector view.', 'role_basic', 'core'),
('v_ui_dwfzone_sel', 'DWF zone selector view.', 'role_basic', 'core'),
('v_ui_event_x_link', 'User interface view for links related to their events.', 'role_edit', 'core'),
('ve_dma', 'Shows editable information about DMA.', 'role_edit', 'core'),
('ve_epa_inlet', 'Editable EPA view for inlets.', 'role_epa', 'core'),
('ve_epa_pgully', 'Editable EPA view for gully pipes.', 'role_epa', 'core'),
('ve_inp_dscenario_inlet', 'Editable demand-scenario view for inlets.', 'role_epa', 'core'),
('ve_inp_pgully', 'Editable INP view for gully pipes.', 'role_epa', 'core'),
('ve_link_connec', 'Custom editable view for connec links.', 'role_edit', 'core'),
('ve_link_gully', 'Custom editable view for gully links.', 'role_edit', 'core'),
('ve_review_audit_node', 'Editable review audit view for nodes.', 'role_edit', 'core')
ON CONFLICT (id) DO NOTHING;

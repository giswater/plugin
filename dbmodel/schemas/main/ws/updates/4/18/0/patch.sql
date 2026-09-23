/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

INSERT INTO sys_table (id, descript, sys_role, "source") VALUES
('v_ui_presszone_sel', 'Presszone selector view.', 'role_basic', 'core'),
('v_ui_macrodma_sel', 'Macrodma selector view.', 'role_basic', 'core'),
('v_ui_macrodqa_sel', 'Macrodqa selector view.', 'role_basic', 'core'),
('v_ui_dqa_sel', 'DQA selector view.', 'role_basic', 'core'),
('v_ui_supplyzone_sel', 'Supplyzone selector view.', 'role_basic', 'core'),
('v_ui_crmzone', 'CRM zone user interface view.', 'role_basic', 'core'),
('v_ui_crmzone_sel', 'CRM zone selector view.', 'role_basic', 'core'),
('v_rpt_comp_arc_stats', 'Compared arc result statistics.', 'role_basic', 'core'),
('v_rpt_comp_node_stats', 'Compared node result statistics.', 'role_basic', 'core'),
('v_rpt_compare_arc', 'Compared arc simulation results.', 'role_basic', 'core'),
('ve_epa_link', 'Editable EPA view for links.', 'role_epa', 'core'),
('ve_epa_frshortpipe', 'Editable EPA view for flow-regulator shortpipes.', 'role_epa', 'core'),
('ve_inp_dscenario_frshortpipe', 'Editable demand-scenario view for flow-regulator shortpipes.', 'role_epa', 'core'),
('ve_inp_dscenario_pump_additional', 'Editable demand-scenario view for additional pumps.', 'role_epa', 'core'),
('ve_inp_pump_additional', 'Editable INP view for additional pumps.', 'role_epa', 'core'),
('ve_link_link', 'Custom editable view for LINK.', 'role_edit', 'core'),
('v_ui_node_incident', 'Node incident user interface view.', 'role_basic', 'core'),
('v_ui_arc_incident', 'Arc incident user interface view.', 'role_basic', 'core'),
('v_ui_connec_incident', 'Connec incident user interface view.', 'role_basic', 'core'),
('v_ui_link_incident', 'Link incident user interface view.', 'role_basic', 'core'),
('ve_visit_node_incident', 'View for node incidents (events/visits).', 'role_basic', 'core'),
('ve_visit_arc_incident', 'View for arc incidents (events/visits).', 'role_basic', 'core'),
('ve_visit_connec_incident', 'View for connec incidents (events/visits).', 'role_basic', 'core'),
('ve_visit_link_incident', 'View for link incidents (events/visits).', 'role_basic', 'core')
ON CONFLICT (id) DO NOTHING;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_param_system SET value = FALSE WHERE parameter = 'admin_config_control_trigger';

UPDATE config_form_fields AS t SET widgetcontrols = v.text::json FROM (
	VALUES
	('btn_accept', 'arc', 'form_feature', 'tab_none', '{"text":"Accept"}'),
    ('btn_apply', 'arc', 'form_feature', 'tab_none', '{"text":"Apply"}'),
    ('btn_cancel', 'arc', 'form_feature', 'tab_none', '{"text":"Cancel"}'),
    ('btn_accept', 'connec', 'form_feature', 'tab_none', '{"text":"Accept"}'),
    ('btn_apply', 'connec', 'form_feature', 'tab_none', '{"text":"Apply"}'),
    ('btn_cancel', 'connec', 'form_feature', 'tab_none', '{"text":"Cancel"}'),
    ('cancel', 'element_manager', 'form_element', 'tab_none', '{"saveValue":false,"text":"Close"}'),
    ('create', 'element_manager', 'form_element', 'tab_none', '{"saveValue":false,"text":"Create"}'),
    ('delete', 'element_manager', 'form_element', 'tab_none', '{"onContextMenu":"Delete","saveValue":false,"text":"Delete"}'),
    ('btn_close', 'generic', 'audit', 'tab_none', '{"text":"Close"}'),
    ('btn_close', 'generic', 'audit_manager', 'tab_none', '{"text":"Close"}'),
    ('btn_open', 'generic', 'audit_manager', 'tab_none', '{"text":"Open"}'),
    ('btn_open_date', 'generic', 'audit_manager', 'tab_none', '{"text":"Open date"}'),
    ('Info:', 'generic', 'check_project', 'tab_data', '{"vdefault_value":"This function verifies both the project and the database. For the database verification, all objects selected by the user through their sector and exploitation selector are checked."}'),
    ('btn_accept', 'generic', 'create_organization', 'tab_none', '{"text":"Accept"}'),
    ('btn_close', 'generic', 'create_organization', 'tab_none', '{"text":"Close"}'),
    ('btn_close', 'generic', 'dscenario', 'tab_none', '{"text":"Close"}'),
    ('btn_close', 'generic', 'dscenario_manager', 'tab_none', '{"text":"Close"}'),
    ('btn_close', 'generic', 'epa_manager', 'tab_none', '{"text":"Close"}'),
    ('btn_accept', 'generic', 'epa_selector', 'tab_none', '{"text":"Accept"}'),
    ('btn_cancel', 'generic', 'epa_selector', 'tab_none', '{"text":"Cancel"}'),
    ('btn_accept', 'generic', 'form_featuretype_change', 'tab_none', '{"text":"Accept"}'),
    ('btn_cancel', 'generic', 'form_featuretype_change', 'tab_none', '{"text":"Cancel"}'),
    ('btn_options', 'generic', 'go2epa', 'tab_data', '{"text":"Options"}'),
    ('btn_selector', 'generic', 'go2epa', 'tab_data', '{"text":"Selector"}'),
    ('btn_download_inp', 'generic', 'go2epa', 'tab_log', '{"text":"INP File"}'),
    ('btn_download_rpt', 'generic', 'go2epa', 'tab_log', '{"text":"RPT File"}'),
    ('btn_close', 'generic', 'go2epa', 'tab_none', '{"text":"Close"}'),
    ('btn_execute_epa', 'generic', 'go2epa', 'tab_none', '{"text":"Execute"}'),
    ('btn_accept', 'generic', 'link_to_connec', 'tab_none', '{"text":"Accept"}'),
    ('btn_close', 'generic', 'link_to_connec', 'tab_none', '{"text":"Close"}'),
    ('btn_cancel', 'generic', 'nvo_manager', 'tab_none', '{"text":"Close"}'),
    ('btn_accept', 'generic', 'psector', 'tab_none', '{"text":"Accept"}'),
    ('btn_close', 'generic', 'psector', 'tab_none', '{"text":"Cancel"}'),
    ('btn_close', 'generic', 'psector_manager', 'tab_none', '{"text":"Close"}'),
    ('btn_close', 'generic', 'snapshot_view', 'tab_none', '{"text":"Close"}'),
    ('btn_run', 'generic', 'snapshot_view', 'tab_none', '{"text":"Run"}'),
    ('btn_close', 'generic', 'workspace_manager', 'tab_none', '{"text":"Close"}'),
    ('btn_accept', 'generic', 'workspace_open', 'tab_none', '{"text":"Save"}'),
    ('btn_close', 'generic', 'workspace_open', 'tab_none', '{"text":"Close"}'),
    ('btn_accept', 'node', 'form_feature', 'tab_none', '{"text":"Accept"}'),
    ('btn_apply', 'node', 'form_feature', 'tab_none', '{"text":"Apply"}'),
    ('btn_cancel', 'node', 'form_feature', 'tab_none', '{"text":"Cancel"}'),
    ('btn_accept', 'mincut', 'form_mincut', 'tab_mincut', '{"text":"Aceptar"}'),
    ('btn_apply', 'mincut', 'form_mincut', 'tab_mincut', '{"text":"Apply"}'),
    ('btn_cancel', 'mincut', 'form_mincut', 'tab_mincut', '{"text":"Cancelar"}'),
    ('btn_end', 'mincut', 'form_mincut', 'tab_mincut', '{"text":"Fin"}'),
    ('btn_start', 'mincut', 'form_mincut', 'tab_mincut', '{"text":"Inicio"}'),
    ('cancel', 'mincut_manager', 'form_mincut', 'tab_none', '{"saveValue":false,"text":"Close"}'),
    ('cancel_mincut', 'mincut_manager', 'form_mincut', 'tab_none', '{"onContextMenu":"Cancel mincut","saveValue":false,"text":"Cancel mincut"}'),
    ('delete', 'mincut_manager', 'form_mincut', 'tab_none', '{"onContextMenu":"Delete mincut","saveValue":false,"text":"Delete mincut"}')
) AS v(columnname, formname, formtype, tabname, text)
WHERE t.columnname = v.columnname AND t.formname = v.formname AND t.formtype = v.formtype AND t.tabname = v.tabname;
UPDATE config_param_system SET value = TRUE WHERE parameter = 'admin_config_control_trigger';

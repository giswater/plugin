/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = cm, public, public;
UPDATE config_form_fields AS t SET widgetcontrols = v.text::json FROM (
	VALUES
	('active', 'campaign_inventory', 'form_feature', 'tab_data', '{"vdefault_value":"True"}'),
    ('active', 'campaign_review', 'form_feature', 'tab_data', '{"vdefault_value":"True"}'),
    ('active', 'campaign_visit', 'form_feature', 'tab_data', '{"vdefault_value":"True"}'),
    ('txt_info', 'generic', 'check_project_cm', 'tab_data', '{"vdefault_value":"Esta función tiene por objetivo pasar el control de calidad de una campaña, pudiendo escoger de forma concreta un lote especifico.<br><br>Se analizan diferentes aspectos siendo lo más destacado que se configura para que los datos esten operativos en el conjunto de una campaña para que el modelo hidraulico funcione."}'),
    ('active', 'lot', 'form_feature', 'tab_data', '{"vdefault_value":"True"}')
) AS v(columnname, formname, formtype, tabname, text)
WHERE t.columnname = v.columnname AND t.formname = v.formname AND t.formtype = v.formtype AND t.tabname = v.tabname;
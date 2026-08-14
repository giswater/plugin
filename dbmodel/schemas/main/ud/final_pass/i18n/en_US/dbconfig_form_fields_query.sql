/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_param_system SET value = FALSE WHERE parameter = 'admin_config_control_trigger';

UPDATE config_form_fields AS t SET dv_querytext = v.text FROM (
	VALUES
	('feature_type', 'config_visit_parameter', 'form_feature', 'tab_none', 'SELECT ''ALL'' as id, ''ALL'' as idval
UNION
SELECT id, id as idval
FROM sys_feature_type
WHERE classlevel = 1 OR classlevel = 2 OR classlevel = 4')
) AS v(columnname, formname, formtype, tabname, text)
WHERE t.columnname = v.columnname
  AND t.formname = v.formname
  AND t.formtype = v.formtype
  AND t.tabname = v.tabname;

UPDATE config_form_fields AS t SET dv_querytext = v.text FROM (
	VALUES
	('profileMode', 'profile_interpolation', 'profile_interpolation', 'tab_none', 'SELECT ''SMOOTH'' AS id, ''SMOOTH'' AS idval UNION SELECT ''SHALLOW'', ''SHALLOW'' UNION SELECT ''DEEP'', ''DEEP'' UNION SELECT ''CENTERED'', ''CENTERED''')
) AS v(columnname, formname, formtype, tabname, text)
WHERE t.columnname = v.columnname
  AND t.formname = v.formname
  AND t.formtype = v.formtype
  AND t.tabname = v.tabname;
UPDATE config_param_system SET value = TRUE WHERE parameter = 'admin_config_control_trigger';

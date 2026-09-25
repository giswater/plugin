/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- The hydrometer info tab reads listname/objectname vf_hydrometer.
-- Curated aliases were still stored on tbl_hydrometer, which the widget ignores.
INSERT INTO config_form_tableview (
    location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam
)
SELECT
    src.location_type,
    src.project_type,
    'vf_hydrometer',
    mapped.columnname,
    src.columnindex,
    src.visible,
    src.width,
    src.alias,
    src.style,
    src.addparam
FROM config_form_tableview src
JOIN (VALUES
    ('hydrometer_customer_code', 'hydro_customer_code'),
    ('connec_customer_code', 'feature_customer_code'),
    ('connec_id', 'feature_id'),
    ('expl_id', 'expl_id'),
    ('hydrometer_id', 'hydrometer_id'),
    ('hydrometer_link', 'hydrometer_link'),
    ('state', 'state')
) AS mapped(oldname, columnname) ON mapped.oldname = src.columnname
WHERE src.objectname = 'tbl_hydrometer'
ON CONFLICT (objectname, columnname) DO UPDATE
SET alias = EXCLUDED.alias,
    visible = EXCLUDED.visible
WHERE config_form_tableview.alias IS NULL
   OR lower(replace(config_form_tableview.alias, ' ', '_')) = lower(config_form_tableview.columnname);

DELETE FROM config_form_tableview WHERE objectname = 'tbl_hydrometer';
DELETE FROM config_form_list WHERE listname IN ('tbl_hydrometer', 'v_ui_hydrometer');

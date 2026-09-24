/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Toolbox 2118 (build nodes from arc vertices): node type combo, alphabetical
UPDATE config_toolbox
SET inputparams = replace(
    inputparams::text,
    'where cfn.id is not null',
    'where cfn.id is not null order by cfn.id'
)::json
WHERE id = 2118
  AND inputparams::text ILIKE '%where cfn.id is not null%'
  AND inputparams::text NOT ILIKE '%order by cfn.id%';

UPDATE config_form_fields
SET dv_isnullvalue = true
WHERE columnname = 'ownercat_id'
  AND formname ILIKE 've_element%';

-- GENELEM (and any other form with no lyt_data_2 fields) got dataquality rows
-- with layoutorder NULL, so the info form never creates the widgets.
UPDATE config_form_fields AS c
SET layoutname = chosen.layoutname,
    layoutorder = chosen.layoutorder
FROM (
    SELECT
        f.formname,
        f.formtype,
        f.tabname,
        f.columnname,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM config_form_fields AS other
                WHERE other.formname = f.formname
                  AND other.formtype = f.formtype
                  AND other.tabname = f.tabname
                  AND other.layoutname = 'lyt_data_2'
                  AND other.columnname NOT IN ('dataquality', 'dataquality_obs')
            ) THEN 'lyt_data_2'
            ELSE 'lyt_data_1'
        END AS layoutname,
        COALESCE((
            SELECT max(other.layoutorder)
            FROM config_form_fields AS other
            WHERE other.formname = f.formname
              AND other.formtype = f.formtype
              AND other.tabname = f.tabname
              AND other.layoutname = CASE
                    WHEN EXISTS (
                        SELECT 1
                        FROM config_form_fields AS has_lyt2
                        WHERE has_lyt2.formname = f.formname
                          AND has_lyt2.formtype = f.formtype
                          AND has_lyt2.tabname = f.tabname
                          AND has_lyt2.layoutname = 'lyt_data_2'
                          AND has_lyt2.columnname NOT IN ('dataquality', 'dataquality_obs')
                    ) THEN 'lyt_data_2'
                    ELSE 'lyt_data_1'
                END
              AND other.columnname NOT IN ('dataquality', 'dataquality_obs')
        ), 0) + CASE WHEN f.columnname = 'dataquality' THEN 1 ELSE 2 END AS layoutorder
    FROM config_form_fields AS f
    WHERE f.formtype = 'form_feature'
      AND f.tabname = 'tab_data'
      AND f.columnname IN ('dataquality', 'dataquality_obs')
      AND f.layoutorder IS NULL
) AS chosen
WHERE c.formname = chosen.formname
  AND c.formtype = chosen.formtype
  AND c.tabname = chosen.tabname
  AND c.columnname = chosen.columnname;

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

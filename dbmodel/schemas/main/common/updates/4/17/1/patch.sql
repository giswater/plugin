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

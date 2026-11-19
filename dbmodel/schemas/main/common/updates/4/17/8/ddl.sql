/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

UPDATE sys_fprocess SET except_level = 3 WHERE fid = 166;

-- EPA tab edits ve_inp_dscenario_*; 4.17.0 registered observ only on inp_dscenario_* (#995)
INSERT INTO config_form_fields (
    formname, formtype, tabname, columnname, layoutname, layoutorder,
    "datatype", widgettype, "label", tooltip, placeholder,
    ismandatory, isparent, iseditable, isautoupdate, isfilter,
    dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id,
    dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction,
    linkedobject, hidden, web_layoutorder
)
SELECT
    've_' || src.formname,
    src.formtype,
    src.tabname,
    src.columnname,
    src.layoutname,
    COALESCE((
        SELECT MAX(v.layoutorder)
        FROM config_form_fields v
        WHERE v.formname = 've_' || src.formname
          AND v.formtype = src.formtype
          AND v.tabname = src.tabname
    ), 0) + 1,
    src.datatype,
    src.widgettype,
    src.label,
    src.tooltip,
    src.placeholder,
    src.ismandatory,
    src.isparent,
    src.iseditable,
    src.isautoupdate,
    src.isfilter,
    src.dv_querytext,
    src.dv_orderby_id,
    src.dv_isnullvalue,
    src.dv_parent_id,
    src.dv_querytext_filterc,
    src.stylesheet,
    src.widgetcontrols,
    src.widgetfunction,
    src.linkedobject,
    src.hidden,
    src.web_layoutorder
FROM config_form_fields src
WHERE src.formname LIKE 'inp_dscenario_%'
  AND src.columnname = 'observ'
  AND src.formtype = 'form_feature'
  AND src.tabname = 'tab_none'
  AND EXISTS (
      SELECT 1
      FROM config_form_fields v
      WHERE v.formname = 've_' || src.formname
        AND v.formtype = 'form_feature'
  )
  AND EXISTS (
      SELECT 1
      FROM information_schema.columns c
      WHERE c.table_schema = current_schema()
        AND c.table_name = 've_' || src.formname
        AND c.column_name = 'observ'
  )
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
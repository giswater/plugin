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

UPDATE config_toolbox SET inputparams='[
  {
    "datatype": "text",
    "label": "Scenario name:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "value": "",
    "widgetname": "name",
    "widgettype": "text"
  },
  {
    "datatype": "text",
    "label": "Scenario descript:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "value": "",
    "widgetname": "descript",
    "widgettype": "text"
  },
  {
    "datatype": "text",
    "dvQueryText": "SELECT expl_id as id, name as idval FROM exploitation where expl_id>0 UNION select 99999 as id, ''ALL'' as idval order by id desc",
    "label": "Exploitation:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 4,
    "selectedId": "0",
    "widgetname": "exploitation",
    "widgettype": "combo"
  },
  {
    "comboIds": [
      1,
      2
    ],
    "comboNames": [
      "PERIOD ID",
      "DATE INTERVAL"
    ],
    "datatype": "text",
    "isMandatory": true,
    "label": "Choose time method:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 5,
    "widgetname": "patternOrDate",
    "widgettype": "combo"
  },
  {
    "datatype": "text",
    "dvQueryText": "SELECT id, code as idval FROM ext_cat_period",
    "label": "if PERIOD_ID - Period:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 6,
    "selectedId": "1",
    "widgetname": "period",
    "widgettype": "combo"
  },
  {
    "datatype": "text",
    "label": "[if DATE INTERVAL] Source CRM init date:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 7,
    "value": null,
    "widgetname": "initDate",
    "widgettype": "datetime"
  },
  {
    "datatype": "text",
    "label": "[if DATE INTERVAL] Source CRM end date:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 8,
    "value": "2015-07-30 00:00:00",
    "widgetname": "endDate",
    "widgettype": "datetime"
  },
  {
    "datatype": "boolean",
    "label": "Only hydrometers with waterbal true:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 9,
    "value": null,
    "widgetname": "onlyIsWaterBal",
    "widgettype": "check"
  },
  {
    "comboIds": [
      1,
      2,
      3,
      6,
      7
    ],
    "comboNames": [
      "NONE",
      "SECTOR-DEFAULT",
      "DMA-DEFAULT",
      "HYDROMETER-CATEGORY",
      "FEATURE-PATTERN"
    ],
    "datatype": "text",
    "label": "Feature pattern:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 10,
    "selectedId": "",
    "tooltip": "This value will be stored on pattern_id of inp_dscenario_demand table in order to be used on the inp file exportation ONLY with the pattern method FEATURE PATTERN.",
    "widgetname": "pattern",
    "widgettype": "combo"
  },
  {
    "comboIds": [
      "LPS",
      "LPM",
      "MLD",
      "CMH",
      "CMD",
      "CFS",
      "GPM",
      "MGD",
      "AFD"
    ],
    "comboNames": [
      "LPS",
      "LPM",
      "MLD",
      "CMH",
      "CMD",
      "CFS",
      "GPM",
      "MGD",
      "AFD"
    ],
    "datatype": "text",
    "label": "Demand units:",
    "layoutname": "grl_option_parameters",
    "layoutorder": 11,
    "selectedId": "",
    "tooltip": "Choose units to insert volume data on demand column. This value need to be the same that flow units used on EPANET. On the other hand, it is assumed that volume from hydrometer data table is expresed on m3/period and column period_seconds is filled.",
    "widgetname": "demandUnits",
    "widgettype": "combo"
  },
  {
    "label": "Demand as DMA weight factor:",
    "tooltip": "",
    "datatype": "boolean",
    "layoutname": "grl_option_parameters",
    "widgetname": "export_weight",
    "widgettype": "check",
    "layoutorder": 12
  }
]'::json
WHERE id=3110;

UPDATE sys_message
SET error_message = 'The following mapzones have no nodeParent or toArc: %feature_list%'
WHERE id = 4634;

UPDATE sys_message
SET error_message = 'There are no mapzones with no nodeParent or toArc'
WHERE id = 4636;

UPDATE sys_message
SET error_message = 'The following pump/meter/valve nodeParents don''t have the same to_arc on their graphconfig and man_table: %node_list%'
WHERE id = 4500;

UPDATE sys_message
SET error_message = 'There are no pump/meter/valve nodeParents with different to_arc on their graphconfig and man_table'
WHERE id = 4502;

UPDATE sys_message
SET error_message = 'The following tank/source/waterwell/wtp nodeParents toArc is inlet_arc in its man_table: %node_list%'
WHERE id = 4504;

UPDATE sys_message
SET error_message = 'There are no arcs connected to a tank/source/waterwell/wtp that aren''t set as toArc or inlet_arc'
WHERE id = 4534;

UPDATE sys_message
SET error_message = 'The following arcs are set more than once in graphconfig: %arc_list%'
WHERE id = 4492;

UPDATE sys_message
SET error_message = 'There are no arcs set more than once in graphconfig'
WHERE id = 4494;

UPDATE sys_message
SET error_message = 'The following forceClosed/forceOpen are set more than once in graphconfig: %arc_list%'
WHERE id = 4524;

UPDATE sys_message
SET error_message = 'There are no forceClosed/forceOpen set more than once in graphconfig'
WHERE id = 4526;

DELETE FROM sys_label WHERE id = 4006;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES
	(4764, 'Arc (%v_id%) have been downgraded, new planned arc have been created (%v_arc%)', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4766, '%v_count% connec(s) have been reconnected.', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4768, '%v_count% gully(s) have been reconnected.', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4770, 'Using current (%v_psector%) psector, %v_count% succesfully replacements have been executed', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4772, 'Arc catalog used for new arc(s): %v_catalog%', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4774, 'Copied columns from old arc(s): Mapzones, *_type, soil, address and label values', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4776, 'NOT copied columns from old arc(s): Free text and addfield values', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4778, 'Replacement on planned mode is only available for arcs', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4780, 'Arc replacement done succesfully', NULL, 0, true, 'utils', 'core', 'UI'),
	(4788, 'REPLACE FEATURE ON PSECTOR', NULL, 0, true, 'utils', 'core', 'AUDIT')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES
	(4782, 'Activate topology control.', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4784, 'MERGE PSECTOR', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4786, 'merge psectors', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4790, 'Proportional cost of connec connections (pjoint cost)', NULL, 0, true, 'utils', 'core', 'AUDIT'),
	(4792, 'Proportional cost of gully connections (pjoint cost)', NULL, 0, true, 'utils', 'core', 'AUDIT')
ON CONFLICT (id) DO NOTHING;

-- cat_arc.bulk was renamed to thickness in 4.0.0. The form field still pointed at bulk,
-- so the attribute table aliased the column from its name ("Thickness") and skipped i18n.
UPDATE config_form_fields
SET columnname = 'thickness', label = 'Thickness:', tooltip = 'Thickness'
WHERE formname = 'cat_arc'
	AND formtype = 'form_feature'
	AND tabname = 'tab_none'
	AND columnname = 'bulk';

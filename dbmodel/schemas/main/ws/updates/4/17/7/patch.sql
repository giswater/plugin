/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Append parent_id at the end.
CREATE OR REPLACE VIEW v_ui_rpt_cat_result AS
SELECT DISTINCT ON (rpt_cat_result.result_id)
	rpt_cat_result.result_id,
	e.exploitation_names AS expl_id,
	rpt_cat_result.sector_id,
	rpt_cat_result.dma_id,
	t2.idval AS network_type,
	t1.idval AS status,
	rpt_cat_result.iscorporate,
	rpt_cat_result.descript,
	rpt_cat_result.exec_date,
	rpt_cat_result.cur_user,
	rpt_cat_result.export_options,
	rpt_cat_result.network_stats,
	rpt_cat_result.inp_options,
	rpt_cat_result.rpt_stats,
	rpt_cat_result.addparam,
	rpt_cat_result.isvalidated,
	rpt_cat_result.parent_id
FROM rpt_cat_result
	JOIN selector_expl s ON (s.expl_id = ANY(rpt_cat_result.expl_id) AND s.cur_user = CURRENT_USER) OR rpt_cat_result.expl_id = ARRAY[NULL::integer]
	LEFT JOIN inp_typevalue t1 ON rpt_cat_result.status::text = t1.id::text
	LEFT JOIN inp_typevalue t2 ON rpt_cat_result.network_type = t2.id
	LEFT JOIN LATERAL (
		SELECT array_agg(ex.name) AS exploitation_names
		FROM unnest(rpt_cat_result.expl_id) AS x(expl_id)
		JOIN exploitation ex ON ex.expl_id = x.expl_id
	) e ON true
WHERE t1.typevalue = 'inp_result_status'
AND t2.typevalue = 'inp_options_networkmode';

-- #990: show demand_* corporate EPA stats on connec forms (gw_fct_epa2data fills them)

-- Shift press_* so demand_* can sit before them (same order as ve_node)
UPDATE config_form_fields
SET layoutorder = CASE columnname
	WHEN 'press_max' THEN 29
	WHEN 'press_min' THEN 31
	WHEN 'press_avg' THEN 32
END
WHERE formname IN (
	've_connec', 've_connec_fountain', 've_connec_greentap',
	've_connec_tap', 've_connec_vconnec', 've_connec_wjoin'
)
AND formtype = 'form_feature'
AND tabname = 'tab_data'
AND columnname IN ('press_max', 'press_min', 'press_avg');

INSERT INTO config_form_fields (
	formname, formtype, tabname, columnname, layoutname, layoutorder,
	"datatype", widgettype, "label", tooltip, placeholder,
	ismandatory, isparent, iseditable, isautoupdate, isfilter,
	dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc,
	stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder
)
VALUES
	('ve_connec', 'form_feature', 'tab_data', 'demand_max', 'lyt_data_2', 26, 'numeric', 'text', 'Demand max:', 'Demand_max', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 85),
	('ve_connec', 'form_feature', 'tab_data', 'demand_min', 'lyt_data_2', 27, 'numeric', 'text', 'Demand min:', 'Demand_min', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 86),
	('ve_connec', 'form_feature', 'tab_data', 'demand_avg', 'lyt_data_2', 28, 'numeric', 'text', 'Demand avg:', 'Demand_avg', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 87),
	('ve_connec_fountain', 'form_feature', 'tab_data', 'demand_max', 'lyt_data_2', 26, 'numeric', 'text', 'Demand max:', 'Demand_max', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 91),
	('ve_connec_fountain', 'form_feature', 'tab_data', 'demand_min', 'lyt_data_2', 27, 'numeric', 'text', 'Demand min:', 'Demand_min', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 92),
	('ve_connec_fountain', 'form_feature', 'tab_data', 'demand_avg', 'lyt_data_2', 28, 'numeric', 'text', 'Demand avg:', 'Demand_avg', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 93),
	('ve_connec_greentap', 'form_feature', 'tab_data', 'demand_max', 'lyt_data_2', 26, 'numeric', 'text', 'Demand max:', 'Demand_max', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 85),
	('ve_connec_greentap', 'form_feature', 'tab_data', 'demand_min', 'lyt_data_2', 27, 'numeric', 'text', 'Demand min:', 'Demand_min', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 86),
	('ve_connec_greentap', 'form_feature', 'tab_data', 'demand_avg', 'lyt_data_2', 28, 'numeric', 'text', 'Demand avg:', 'Demand_avg', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 87),
	('ve_connec_tap', 'form_feature', 'tab_data', 'demand_max', 'lyt_data_2', 26, 'numeric', 'text', 'Demand max:', 'Demand_max', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 88),
	('ve_connec_tap', 'form_feature', 'tab_data', 'demand_min', 'lyt_data_2', 27, 'numeric', 'text', 'Demand min:', 'Demand_min', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 89),
	('ve_connec_tap', 'form_feature', 'tab_data', 'demand_avg', 'lyt_data_2', 28, 'numeric', 'text', 'Demand avg:', 'Demand_avg', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 90),
	('ve_connec_vconnec', 'form_feature', 'tab_data', 'demand_max', 'lyt_data_2', 26, 'numeric', 'text', 'Demand max:', 'Demand_max', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 85),
	('ve_connec_vconnec', 'form_feature', 'tab_data', 'demand_min', 'lyt_data_2', 27, 'numeric', 'text', 'Demand min:', 'Demand_min', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 86),
	('ve_connec_vconnec', 'form_feature', 'tab_data', 'demand_avg', 'lyt_data_2', 28, 'numeric', 'text', 'Demand avg:', 'Demand_avg', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 87),
	('ve_connec_wjoin', 'form_feature', 'tab_data', 'demand_max', 'lyt_data_2', 26, 'numeric', 'text', 'Demand max:', 'Demand_max', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 85),
	('ve_connec_wjoin', 'form_feature', 'tab_data', 'demand_min', 'lyt_data_2', 27, 'numeric', 'text', 'Demand min:', 'Demand_min', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 86),
	('ve_connec_wjoin', 'form_feature', 'tab_data', 'demand_avg', 'lyt_data_2', 28, 'numeric', 'text', 'Demand avg:', 'Demand_avg', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 87)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

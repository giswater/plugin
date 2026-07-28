/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_csv AS t SET alias = v.alias, descript = v.descript FROM (
	VALUES
	(385, 'Import inp timeseries', 'Function to assist the import of timeseries for inp models. The csv file must containts next columns on same position: timseries, timser_type, times_type, descript, expl_id, date, hour, time, value (fill date/hour for ABSOLUTE or time for RELATIVE)'),
    (408, 'Import istram nodes', NULL),
    (409, 'Import istram arcs', NULL),
    (445, 'Import cat_feature_node', 'The csv file must contain the following columns in the exact same order:  id, system_id, epa_default, isarcdivide, isprofilesurface, code_autofill, choose_hemisphere, double_geom, num_arcs, isexitupperintro, shortcut_key, link_path, descript, active'),
    (446, 'Import cat_feature_connec', 'The csv file must contain the following columns in the exact same order:  id, system_id, code_autofill, double_geom, shortcut_key, link_path, descript, active'),
    (447, 'Import cat_feature_gully', 'The csv file must contain the following columns in the exact same order:  id, system_id, epa_default, code_autofill, double_geom, shortcut_key, link_path, descript, active'),
    (448, 'Import cat_node', 'The csv file must contain the following columns in the exact same order:  id, matcat_id, shape, geom1, geom2, geom3, descript, link, brand, model, svg, estimated_y, cost_unit, cost, active, label, node_type, acoeff'),
    (449, 'Import cat_connec', 'The csv file must contain the following columns in the exact same order:  id, matcat_id, shape, geom1, geom2, geom3, geom4, geom_r, descript, link, brand, model, svg, active, label, connec_type'),
    (450, 'Import cat_arc', 'The csv file must contain the following columns in the exact same order:  id, matcat_id, shape, geom1, geom2, geom3, geom4, geom5, geom6,geom7, geom8, geom_r, descript, link, brand, model, svg, z1, z2, width, area, estimated_depth, bulk, cost_unit, cost, m2bottom_cost, m3protec_cost, active, label, tsect_id, curve_id, arc_type, acoeff, connect_cost'),
    (451, 'Import cat_grate', 'The csv file must contain the following columns in the exact same order:  id, matcat_id, length, width, total_area, effective_area, n_barr_l, n_barr_w, n_barr_diag, a_param, b_param, descript, link, brand, model, svg, active, label, gully_type'),
    (527, 'Import DWF', 'Function to import DWF values. The CSV file must contain the following columns in the exact same order:   dwfscenario_id, node_id, value, pat1, pat2, pat3, pat4'),
    (234, 'Import db prices', 'The csv file must contains next columns on same position: id, unit, descript, text, price.  - The column price must be numeric with two decimals.  - You can choose a catalog name for these prices setting an import label.  '),
    (235, 'Import elements', 'The csv file must containts next columns on same position: Id (arc_id, node_id, connec_id), code, elementcat_id, observ, comment, num_elements, state type (id), workcat_id, verified (choose from edit_typevalue>value_verified). - Observations and comments fields are optional - ATTENTION! Import label has to be filled with the type of element (node, arc, connec)'),
    (238, 'Import om visit', 'To use this import csv function parameter you need to configure before execute it the system parameter ''utils_csv2pg_om_visit_parameters''.  Also whe recommend to read before the annotations inside the function to work as well as posible with'),
    (384, 'Import inp curves', 'Function to automatize the import of inp curves files.  The csv file must containts next columns on same position:  curve_id, x_value, y_value, curve_type (for WS project OR UD project curve_type has diferent values. Check user manual)'),
    (386, 'Import inp patterns', 'Function to automatize the import of inp patterns files.  The csv file must containts next columns on same position:  pattern_id, pattern_type, factor1,.......,factorn.  For WS use up factor18, repeating rows if you like.  For UD use up factor24. More than one row for pattern is not allowed'),
    (444, 'Import cat_feature_arc', 'The csv file must contain the following columns in the exact same order:  id, system_id, epa_default, code_autofill, shortcut_key, link_path, descript, active'),
    (469, 'Import scada values', 'Import scada values into table ext_rtc_scada_x_data according example file scada_values.csv'),
    (470, 'Import hydrometer_x_data', 'The csv file must have the following fields: hydrometer_id, cat_period_id, sum, value_date (optional), value_type (optional), value_status (optional), value_state (optional)'),
    (471, 'Import crm period values', 'The csv file must have the following fields: id, start_date, end_date, period_seconds (optional), code'),
    (445, 'Import cat_feature_node', 'The csv file must contain the following columns in the exact same order:  id, system_id, epa_default, isarcdivide, isprofilesurface, choose_hemisphere, code_autofill, double_geom, num_arcs, graph_delimiter, shortcut_key, link_path, descript, active'),
    (446, 'Import cat_feature_connec', 'The csv file must contain the following columns in the exact same order:  id, system_id, epa_default, code_autofill, shortcut_key, link_path, descript, active'),
    (448, 'Import cat_node', 'The csv file must contain the following columns in the exact same order:  id, nodetype_id, matcat_id, pnom, dnom, dint, dext, shape, descript, link, brand, model, svg, estimated_depth, cost_unit, cost, active, label, ischange, acoeff'),
    (449, 'Import cat_connec', 'The csv file must contain the following columns in the exact same order:  id, connectype_id, matcat_id, pnom, dnom, dint, dext, descript, link, brand, model, svg, active, label'),
    (450, 'Import cat_arc', 'The csv file must contain the following columns in the exact same order:  id, arctype_id, matcat_id, pnom, dnom, dint, dext, descript, link, brand, model, svg, z1, z2, width, area, estimated_depth, bulk, cost_unit, cost, m2bottom_cost, m3protec_cost, active, label, shape, acoeff, connect_cost'),
    (500, 'Import valve status', 'The csv file must have the folloWing fields: dscenario_name, node_id, status'),
    (501, 'Import dscenario demands', 'The csv file must have the following fields: dscenario_name, feature_id, feature_type, value, demand_type, pattern_id, source'),
    (504, 'Import flowmeter daily values', 'Import daily flowmeter values into table ext_rtc_scada_x_data according example file scada_flowmeter_daily_values.csv'),
    (506, 'Import flowmeter agg values', 'Import aggregated flowmeter values into table ext_rtc_scada_x_data according example file scada_flowmeter_agg_values.csv'),
    (514, 'Import netscenario closed valves ', 'The csv file must have the following fields: netscenario_id, node_id, closed')
) AS v(fid, alias, descript)
WHERE t.fid = v.fid;
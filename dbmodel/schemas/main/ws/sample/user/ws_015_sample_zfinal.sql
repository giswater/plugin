/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = 'SCHEMA_NAME', public, pg_catalog;


INSERT INTO selector_sector SELECT sector_id, current_user from sector where sector_id > 0 ON CONFLICT (sector_id, cur_user) DO NOTHING;
DELETE FROM selector_psector;

INSERT INTO selector_municipality SELECT muni_id,current_user FROM ext_municipality ON CONFLICT (muni_id, cur_user) DO NOTHING;

UPDATE cat_arc SET active=TRUE WHERE arc_type = 'VARC' AND id = 'VIRTUAL';

UPDATE om_visit SET startdate = startdate -  random() * (startdate - timestamp '2022-01-01 10:00:00');
UPDATE om_visit SET enddate = startdate;

UPDATE arc SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');
UPDATE node SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');
UPDATE connec SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');
UPDATE link SET builtdate = c.builtdate FROM connec c WHERE feature_id = connec_id;
UPDATE element SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');

INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES ('1080',1, 'DMA', -1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES ('1080',2, 'DMA', 1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES ('1097',4, 'DMA', 1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES ('1101',4, 'DMA', 1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES ('113766',1, 'DMA', 1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES ('113766',4, 'DMA', -1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES('111111', 5, 'DMA', 1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES('113952', 5, 'DMA', -1);
INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign) VALUES('113952', 3, 'DMA', 1);

UPDATE config_param_user SET value = replace(value, '"removeDemandOnDryNodes":false', '"delDryNetwork":false, "removeDemandOnDryNodes":true')
WHERE parameter = 'inp_options_debug';

UPDATE cat_feature_node SET graph_delimiter = '{MINSECTOR}' WHERE id = 'SHUTOFF_VALVE';
UPDATE cat_feature_node SET graph_delimiter = '{MINSECTOR}' WHERE id = 'CHECK_VALVE';
UPDATE cat_feature_node SET graph_delimiter = '{PRESSZONE}' WHERE id IN ('PUMP', 'PR_REDUC_VALVE','PR_BREAK_VALVE','PR_SUSTA_VALVE');
UPDATE cat_feature_node SET graph_delimiter=NULL WHERE id='PRESSURE_METER';
UPDATE cat_feature_node SET graph_delimiter='{SECTOR,DMA,PRESSZONE}' WHERE id='TANK';

-- 01/05/2024
UPDATE config_param_system
	SET value='{"status":true, "values":[
{"sourceTable":"ve_node_pr_reduc_valve", "query":"UPDATE presszone t SET head = CASE WHEN top_elev + pressure_exit IS NOT NULL THEN top_elev + pressure_exit ELSE t.head END FROM ve_node_pr_reduc_valve s "},
{"sourceTable":"ve_node_pump", "query":"UPDATE presszone t SET head = CASE WHEN top_elev + pressure_exit IS NOT NULL THEN top_elev + pressure_exit ELSE t.head END FROM ve_node_pump s "},
{"sourceTable":"ve_node_tank", "query":"UPDATE presszone t SET head= CASE WHEN invert_level + hmax IS NOT NULL THEN invert_level + hmax ELSE t.head END FROM ve_node_tank s "}]}'
	WHERE "parameter"='epa_automatic_man2graph_values';


UPDATE config_param_system SET value =
'{"status":true, "values":[
{"sourceTable":"ve_node_tank", "query":"UPDATE inp_inlet t SET maxlevel = hmax, diameter=sqrt(4*area/3.14159) FROM ve_node_tank s "},
{"sourceTable":"ve_node_pr_reduc_valve", "query":"UPDATE inp_valve t SET setting = pressure_exit FROM ve_node_pr_reduc_valve s "}]}'
WHERE parameter = 'epa_automatic_man2inp_values';


UPDATE config_param_system SET value = '{"setArcObsolete":"true","setOldCode":"false"}' WHERE parameter = 'edit_arc_divide';

SELECT gw_fct_setchangefeaturetype($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{"type":"node"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_id":"1082", "feature_type_new":"SHUTOFF_VALVE", "featurecat_id":"SHTFF-VALVE110-PN16"}}$$);

UPDATE cat_feature set active=true where id = 'THROTTLE_VALVE';
INSERT INTO cat_node (id, node_type, matcat_id, pnom, dnom, dint, dext, shape, descript, link, brand_id, model_id, svg, estimated_depth, cost_unit, "cost", active, "label", ischange, acoeff)
VALUES('THROTTLE_VALVE_200', 'THROTTLE_VALVE', 'FD', '16', '200', 200.00000, NULL, NULL, 'THROTTLE VALVE 200mm', 'c:\users\users\catalog.pdf', NULL, NULL, NULL, 1, 'u', 'N_CHKVAL200_PN10', true, NULL, 2, NULL);

SELECT gw_fct_setchangefeaturetype($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{"type":"node"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_id":"1107", "feature_type_new":"THROTTLE_VALVE", "featurecat_id":"THROTTLE_VALVE_200"}}$$);
UPDATE man_valve SET to_arc = '113884' WHERE node_id = '1107';

UPDATE man_valve set broken=false where node_id = '1093';

-- 12/08/2024
UPDATE config_param_system SET value = gw_fct_json_object_set_key(value::json, 'sys_geom', 'the_geom'::text)
	WHERE parameter IN (
		'basic_search_v2_tab_network_arc',
		'basic_search_v2_tab_network_connec',
		'basic_search_v2_tab_network_gully',
		'basic_search_v2_tab_network_node'
	);

UPDATE config_param_system SET value = gw_fct_json_object_set_key(value::json, 'sys_geom', 's.the_geom'::text)
	WHERE parameter ='basic_search_v2_tab_address';


UPDATE link SET muni_id = c.muni_id FROM connec c WHERE connec_id =  feature_id;


UPDATE ext_hydrometer SET is_waterbal = false WHERE hydrometer_id::integer in (3,4);

INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_junction1','{NODE}','{JUNCTION}');
INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_junction2','{NODE}','{JUNCTION}');
INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_hydrant1','{NODE}','{HYDRANT}');
INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_hydrant2','{NODE}','{HYDRANT}');

INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_junction1','{NODE}','{JUNCTION}');
INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_junction2','{NODE}','{JUNCTION}');
INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_hydrant1','{NODE}','{HYDRANT}');
INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_hydrant2','{NODE}','{HYDRANT}');

INSERT INTO man_type_fluid (fluid_type, feature_type, featurecat_id) VALUES ('fluid_junction1','{NODE}','{JUNCTION}');
INSERT INTO man_type_fluid (fluid_type, feature_type, featurecat_id) VALUES ('fluid_junction2','{NODE}','{JUNCTION}');
INSERT INTO man_type_fluid (fluid_type, feature_type, featurecat_id) VALUES ('fluid_hydrant1','{NODE}','{HYDRANT}');
INSERT INTO man_type_fluid (fluid_type, feature_type, featurecat_id) VALUES ('fluid_hydrant2','{NODE}','{HYDRANT}');

INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_junction1','{NODE}','{JUNCTION}');
INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_junction2','{NODE}','{JUNCTION}');
INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_hydrant1','{NODE}','{HYDRANT}');
INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_hydrant2','{NODE}','{HYDRANT}');

UPDATE node SET category_type = 'category_junction1' where nodecat_id like 'JUNCT%';
UPDATE node SET location_type = 'location_junction1' where nodecat_id like 'JUNCT%';
UPDATE node SET fluid_type = 'fluid_junction1' where nodecat_id like 'JUNCT%';
UPDATE node SET function_type = 'function_junction1' where nodecat_id like 'JUNCT%';

UPDATE node SET category_type = 'category_hydrant1' where nodecat_id like 'HYDR%';
UPDATE node SET location_type = 'location_hydrant1' where nodecat_id like 'HYDR%';
UPDATE node SET fluid_type = 'fluid_hydrant1' where nodecat_id like 'HYDR%';
UPDATE node SET function_type = 'function_hydrant1' where nodecat_id like 'HYDR%';

UPDATE om_visit SET ext_code = concat('EXT', 1000 + id);

UPDATE ext_plot set muni_id = 2 where id::integer < 40;

UPDATE macroexploitation SET name ='macroexpl-01', lock_level = 1 WHERE macroexpl_id = 1;
INSERT INTO macroexploitation (macroexpl_id, "name", descript, lock_level, active) VALUES(2, 'Other', 'Macroexploitation used for test', 1, true);

UPDATE config_param_system SET isenabled = false where parameter = ' basic_selector_tab_municipality';

insert into sys_style select 've_node', 106, 'qml', stylevalue, true from sys_style where layername = 've_node' and styleconfig_id = 101 ON CONFLICT (layername, styleconfig_id) DO NOTHING;
insert into sys_style select 've_node', 107, 'qml', stylevalue, true from sys_style where layername = 've_node' and styleconfig_id = 101 ON CONFLICT (layername, styleconfig_id) DO NOTHING;;
insert into sys_style select 've_node', 108, 'qml', stylevalue, true from sys_style where layername = 've_node' and styleconfig_id = 101 ON CONFLICT (layername, styleconfig_id) DO NOTHING;;

UPDATE ext_cat_period b SET end_date = a.end_date FROM (
	SELECT id, end_date + INTERVAL '1 day' AS end_date FROM ext_cat_period
)a WHERE a.id = b.id;

UPDATE ext_cat_period b SET period_seconds = a.period_seconds FROM (
	SELECT id, LEFT((end_date::TIMESTAMP - start_date::TIMESTAMP)::TEXT, 2)::integer * 24 * 3600 AS period_seconds FROM ext_cat_period
)a WHERE a.id = b.id;

UPDATE connec SET connec_length = st_length(l.the_geom) FROM link l WHERE connec_id = l.feature_id;

INSERT INTO man_genelem (element_id)
SELECT e.element_id
FROM element e
JOIN cat_element ce ON ce.id::text = e.elementcat_id::text
LEFT JOIN cat_feature cf ON ce.element_type::text = cf.id::text
WHERE cf.feature_class='GENELEM';

update plan_psector set active = true;

update element set code = element_id;

UPDATE config_form_fields SET "label"='Price pattern:',tooltip='Price pattern' WHERE formname='ve_epa_virtualpump' AND formtype='form_feature' AND columnname='energy_pattern_id' AND tabname='tab_epa';

-- 08/09/2025
UPDATE config_form_fields SET hidden=true WHERE formname='ve_epa_pipe' AND formtype='form_feature' AND columnname='setting_max' AND tabname='tab_epa';
UPDATE config_form_fields SET hidden=true WHERE formname='ve_epa_pipe' AND formtype='form_feature' AND columnname='setting_min' AND tabname='tab_epa';

-- 09/09/2025
UPDATE plan_psector_x_node set psector_id = 1 WHERE node_id IN (10761);
UPDATE plan_psector_x_arc set psector_id = 1 WHERE arc_id IN (20851,20861);
UPDATE plan_psector_x_connec set psector_id = 1 WHERE connec_id IN (114462,114461);
DELETE FROM plan_psector_x_connec WHERE connec_id IN (3105);

-- update is_last
UPDATE om_visit_event SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_event GROUP BY visit_id);
UPDATE om_visit_event SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_event GROUP BY visit_id);

UPDATE om_visit_x_arc SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_arc GROUP BY arc_id);
UPDATE om_visit_x_node SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_node GROUP BY node_id);
UPDATE om_visit_x_connec SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_connec GROUP BY connec_id);
UPDATE om_visit_x_link SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_link GROUP BY link_id);

UPDATE om_visit_x_arc SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_arc GROUP BY arc_id);
UPDATE om_visit_x_node SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_node GROUP BY node_id);
UPDATE om_visit_x_connec SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_connec GROUP BY connec_id);
UPDATE om_visit_x_link SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_link GROUP BY link_id);

UPDATE cat_feature_node SET graph_delimiter='{PRESSZONE}' WHERE id='PRESSURE_METER';

-- 25/03/2026
UPDATE plan_psector_x_connec p
SET arc_id = c.arc_id,
    link_id = l.link_id
FROM connec c
LEFT JOIN LATERAL (
    SELECT link_id
    FROM link
    WHERE feature_id = c.connec_id
      AND feature_type = 'CONNEC'
      AND state = 2
    ORDER BY link_id DESC
    LIMIT 1
) l ON true
WHERE p.connec_id = c.connec_id
  AND p.psector_id = 1
  AND p.state = 1
  AND p.connec_id IN (114461, 114462);


UPDATE arc SET presszone_id = 4 WHERE arc_id = 2089;
UPDATE arc SET presszone_id = 4 WHERE arc_id = 2095;
UPDATE arc SET presszone_id = 4 WHERE arc_id = 2208;

UPDATE arc SET presszone_id = 2 WHERE arc_id = 2205;
UPDATE arc SET presszone_id = 2 WHERE arc_id = 113884;

UPDATE arc SET presszone_id = 1 WHERE arc_id = 2207;
UPDATE arc SET presszone_id = 1 WHERE arc_id = 113881;

UPDATE arc SET presszone_id = 3 WHERE presszone_id = 0 AND expl_id = 1;

UPDATE arc SET presszone_id = 5 WHERE arc_id = 114025;
UPDATE arc SET presszone_id = 5 WHERE arc_id = 114026;
UPDATE arc SET presszone_id = 5 WHERE arc_id = 114145;

UPDATE arc SET presszone_id = 6 WHERE presszone_id = 0 AND expl_id = 2;

-- Extra filters example (sample only): fluid_type combo (nullable)
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES
('generic', 'link_to_connec', 'tab_none', 'fluid_type', 'lyt_extra_filters', 0, 'string', 'combo', 'Fluid type:', 'Restrict connection to arcs/nodes with this fluid type', NULL, false, false, true, false, false, 'SELECT fluid_type as id, fluid_type as idval FROM man_type_fluid WHERE ((featurecat_id is null AND ''ARC''=ANY(feature_type)) ) AND active IS TRUE ', true, true, NULL, NULL, NULL, NULL, NULL, NULL, false, 0)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

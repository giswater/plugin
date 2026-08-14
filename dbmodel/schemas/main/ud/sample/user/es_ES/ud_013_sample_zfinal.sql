/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = 'SCHEMA_NAME', public, pg_catalog;

ALTER TABLE arc DISABLE TRIGGER gw_trg_topocontrol_arc;

INSERT INTO selector_sector SELECT sector_id, current_user from sector where sector_id > 0 ON CONFLICT (sector_id, cur_user) DO NOTHING;
DELETE FROM selector_psector;

INSERT INTO selector_municipality SELECT muni_id,current_user FROM ext_municipality where muni_id > 0 ON CONFLICT (muni_id, cur_user) DO NOTHING;

UPDATE cat_feature SET id = 'OVERFLOW_STORAGE' WHERE id = 'OWERFLOW_STORAGE';

INSERT INTO cat_node (id, matcat_id, shape, geom1, geom2, geom3, descript, link, brand_id, model_id, svg, estimated_y, cost_unit, "cost", active, "label", node_type, acoeff) VALUES('CHANGE_1', NULL, NULL, 1.00, 1.00, NULL, 'Change', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, 'CHANGE', NULL);
INSERT INTO cat_node (id, matcat_id, shape, geom1, geom2, geom3, descript, link, brand_id, model_id, svg, estimated_y, cost_unit, "cost", active, "label", node_type, acoeff) VALUES('OVERFLOW_STORAGE_1', NULL, NULL, 1.00, 1.00, NULL, 'Overflow storage', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_OF_STR', true, NULL, 'OVERFLOW_STORAGE', NULL);
INSERT INTO cat_node (id, matcat_id, shape, geom1, geom2, geom3, descript, link, brand_id, model_id, svg, estimated_y, cost_unit, "cost", active, "label", node_type, acoeff) VALUES('SANDBOX_1', NULL, NULL, 1.00, 1.00, NULL, 'Sandbox', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, 'SANDBOX', NULL);
INSERT INTO cat_node (id, matcat_id, shape, geom1, geom2, geom3, descript, link, brand_id, model_id, svg, estimated_y, cost_unit, "cost", active, "label", node_type, acoeff) VALUES('PUMP_STATION', NULL, NULL, 1.00, 1.00, NULL, 'Pump station', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PUMP_STN', true, NULL, 'PUMP_STATION', NULL);

INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('PGULLY', 'PGULLY', 'FD', 50.0000, 25.0000, 400.0000/860.0000, true);

UPDATE om_visit SET startdate = startdate -  random() * (startdate - timestamp '2022-01-01 10:00:00');
UPDATE om_visit SET enddate = startdate;

UPDATE arc SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');
UPDATE node SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');
UPDATE connec SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');
UPDATE gully SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');
UPDATE link SET builtdate = c.builtdate FROM connec c WHERE feature_id = connec_id;
UPDATE link SET builtdate = g.builtdate FROM gully g WHERE feature_id = gully_id;
UPDATE element SET builtdate = now() -  random() * (now() - timestamp '1990-01-01 00:00:00');

UPDATE config_param_system SET value = '{"setArcObsolete":"true","setOldCode":"false"}' WHERE parameter = 'edit_arc_divide';

UPDATE cat_arc SET geom2 = null WHERE id = 'EG150';


-- refactoring flowregulators for node pump station on expl_1
UPDATE ve_arc SET epa_type = 'PUMP' WHERE arc_id = '303';
UPDATE inp_pump set curve_id = 'PUMP-01', status='OFF', startup=2, shutoff=0.4 WHERE arc_id = '303';
UPDATE ve_arc SET epa_type = 'WEIR' WHERE arc_id = '342';
UPDATE inp_weir SET weir_type ='TRANSVERSE', offsetval = 17, cd=1.5, geom1=1, geom2=1;


-- refactoring flowregulators form node weir of expl_1

SELECT gw_fct_setarcfusion('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":[20587]},
"data":{"workcatId":"work1","enddate":"2020-02-05", "arccat_id":"RC200", "action_mode": 2, "arc_type":"CONDUIT"}}'::json);
SELECT gw_fct_setarcfusion('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":[20590]},
"data":{"workcatId":"work1","enddate":"2020-02-05", "arccat_id":"RC200", "action_mode": 2, "arc_type":"CONDUIT"}}'::json);

DELETE FROM arc WHERE node_1 = '250';
DELETE FROM arc WHERE node_2 = '250';
DELETE FROM node WHERE node_id  = '250';

UPDATE config_param_user SET value ='PARTIAL' WHERE parameter = 'inp_options_inertial_damping';

-- add example for specific sequence on circ_manhole
UPDATE cat_feature SET abrevation='CM_' WHERE id='CIRC_MANHOLE';

CREATE SEQUENCE circ_manhole_code_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1000
	CACHE 1
	NO CYCLE;

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

-- change default visitability_vdef for cat_arc
UPDATE cat_arc SET visitability_vdef = 1 WHERE geom1 <= 1.2; -- NO VISITABLE
UPDATE cat_arc SET visitability_vdef = 2 WHERE geom1 > 1.2 AND geom1 < 1.6; -- SEMI VISITABLE
UPDATE cat_arc SET visitability_vdef = 3 WHERE geom1 >= 1.6; -- VISITABLE

UPDATE link SET muni_id = c.muni_id FROM connec c WHERE connec_id =  feature_id;
UPDATE link SET muni_id = g.muni_id FROM gully g WHERE gully_id =  feature_id;

-- TODO: revise is this is needed
-- SELECT gw_fct_graphanalytics_mapzones_advanced($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"graphClass":"DRAINZONE", "exploitation":"1", "floodOnlyMapzone":null, "forceOpen":null, "forceClosed":null, "usePlanPsector":"false", "commitChanges":"true", "valueForDisconnected":null, "updateMapZone":"2", "geomParamUpdate":"8"}, "aux_params":null}}$$);

UPDATE arc SET muni_id = 1, streetaxis_id  ='1-9150C' WHERE arc_id = '179';

INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_junction1','{NODE}','{JUNCTION}');
INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_junction2','{NODE}','{JUNCTION}');
INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_manhole1','{NODE}','{CIRC_MANHOLE}');
INSERT INTO man_type_category (category_type, feature_type, featurecat_id) VALUES ('category_manhole2','{NODE}','{CIRC_MANHOLE}');

INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_junction1','{NODE}','{JUNCTION}');
INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_junction2','{NODE}','{JUNCTION}');
INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_manhole1','{NODE}','{CIRC_MANHOLE}');
INSERT INTO man_type_location (location_type, feature_type, featurecat_id) VALUES ('location_manhole2','{NODE}','{CIRC_MANHOLE}');

INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_junction1','{NODE}','{JUNCTION}');
INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_junction2','{NODE}','{JUNCTION}');
INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_manhole1','{NODE}','{CIRC_MANHOLE}');
INSERT INTO man_type_function (function_type, feature_type, featurecat_id) VALUES ('function_manhole2','{NODE}','{CIRC_MANHOLE}');

UPDATE node SET category_type = 'category_junction1' where nodecat_id like 'JUNCT%';
UPDATE node SET location_type = 'location_junction1' where nodecat_id like 'JUNCT%';
UPDATE node SET function_type = 'function_junction1' where nodecat_id like 'JUNCT%';

UPDATE node SET category_type = 'category_manhole1' where nodecat_id like 'CIRC_MANHOLE%';
UPDATE node SET location_type = 'location_manhole1' where nodecat_id like 'CIRC_MANHOLE%';
UPDATE node SET function_type = 'function_manhole1' where nodecat_id like 'CIRC_MANHOLE%';

UPDATE om_visit SET ext_code = concat('EXT', 1000 + id);

UPDATE cat_arc SET geom2 = 0 WHERE id = 'EG150';

UPDATE inp_junction SET ysur=999 WHERE node_id= '302';

UPDATE cat_arc SET id = 'PP030', geom1 = 0.25, geom2 = 100 WHERE id = 'PP020';

UPDATE inp_dwf SET value = value*6*random();

UPDATE inp_dwf SET pat1 = 'pattern_12';

UPDATE node set ymax = 2 WHERE node_id = '301';

UPDATE inp_subcatchment SET outlet_id = 95 where subc_id IN ('S91','S92','S94');

UPDATE ext_plot set muni_id = 2 where id::integer < 40;

UPDATE arc SET y1 = 3, y2 = 3, matcat_id = 'Concrete' WHERE arc_id = '100012';
UPDATE arc SET y1 = 2.2, y2 = 3, matcat_id = 'Concrete' WHERE arc_id = '100014';

update cat_feature_node set isexitupperintro=2 where id in ('VIRTUAL_NODE', 'RECT_MANHOLE', 'CIRC_MANHOLE');

delete from element where element_id in ('787', '791', '794', '983', '987', '990', '1650', '1653', '1662');

delete from om_visit where id in (386, 389, 390, 575);

update macroexploitation set name ='macroexpl-01', lock_level = 1 where macroexpl_id = 1;
insert into macroexploitation (macroexpl_id, code, name, descript, lock_level, active) values (2, '2', 'Other', 'Macroexploitation used for test', 1, true);

-- update descript for cat_feature
update cat_feature set descript = concat(left(id,1), substring(lower(id), 2,99));

UPDATE config_param_system SET isenabled = false where parameter = ' basic_selector_tab_municipality';


INSERT INTO element  (element_id, code, elementcat_id, epa_type, state, state_type, num_elements, rotation, verified, publish, inventory, expl_id, feature_type, top_elev, muni_id, sector_id, the_geom) VALUES
('100020', 'E100020', 'WEIR-01','FRWEIR', 1,2,1,79.731, 1,true,true,2,'ELEMENT',30.190,2,2,'POINT (418716.0233455198 4577601.812087212)'),
('100021', 'E100021', 'ORIFICE-01','FRORIFICE', 1,2,1,122.505,1,true,true,1,'ELEMENT',19.230,1,1,'POINT (419597.7191116698 4576460.6400896525)');

INSERT INTO man_frelem (element_id, node_id, to_arc, flwreg_length) VALUES
('100020','18828','18968',0.5),
('100021','237','100014',0.5);

INSERT INTO man_genelem (element_id)
SELECT e.element_id
FROM element e
JOIN cat_element ce ON ce.id::text = e.elementcat_id::text
LEFT JOIN cat_feature cf ON ce.element_type::text = cf.id::text
WHERE cf.feature_class='GENELEM';

INSERT INTO inp_frweir (element_id, weir_type, offsetval, cd, flap, geom1,geom2, geom3, geom4) VALUES
('100020', 'TRANSVERSE',17.15,1.5000,'NO',1.0000,1.0000,0.0000,0.0000);

INSERT INTO inp_frorifice (element_id, orifice_type, offsetval, cd, orate, flap, shape, geom1,geom2, geom3, geom4) VALUES
('100021', 'SIDE',16.35,1.5000, 0.0000,'NO','RECT_CLOSED',2.0000,1.0000,0.0000,0.0000);

INSERT INTO element_x_node SELECT element_id, node_id from man_frelem;

update plan_psector set active=true;

ALTER TABLE arc ENABLE TRIGGER gw_trg_topocontrol_arc;

-- update is_last
UPDATE om_visit_event SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_event GROUP BY visit_id);
UPDATE om_visit_event SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_event GROUP BY visit_id);

UPDATE om_visit_x_arc SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_arc GROUP BY arc_id);
UPDATE om_visit_x_node SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_node GROUP BY node_id);
UPDATE om_visit_x_connec SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_connec GROUP BY connec_id);
UPDATE om_visit_x_link SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_link GROUP BY link_id);
UPDATE om_visit_x_gully SET is_last = TRUE WHERE id IN (SELECT max(id) FROM om_visit_x_gully GROUP BY gully_id);

UPDATE om_visit_x_arc SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_arc GROUP BY arc_id);
UPDATE om_visit_x_node SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_node GROUP BY node_id);
UPDATE om_visit_x_connec SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_connec GROUP BY connec_id);
UPDATE om_visit_x_link SET is_last = FALSE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_link GROUP BY link_id);
UPDATE om_visit_x_gully SET is_last = TRUE WHERE id NOT IN (SELECT max(id) FROM om_visit_x_gully GROUP BY gully_id);

UPDATE drainzone SET expl_id = ARRAY[0] WHERE drainzone_id <1;

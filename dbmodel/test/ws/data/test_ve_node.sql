/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

-- Suppress NOTICE messages
SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(165);

-- IMPORTANT: In this test, we check for existence using the code, not the ID,
-- because we don't allow the user to change the code.
-- In test_node.sql, we test the `node` table and can check `node_id`,
-- but here we are testing the views.

-- ve_node_air_valve
INSERT INTO ve_node_air_valve
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, closed, broken, buried, irrigation_indicator, pressure_entry, pressure_exit, depth_valveshaft, regulator_situation, regulator_location, regulator_observ, lin_meters, exit_type, exit_code, drive_type, cat_valve2, ordinarystatus, shutter, brand2, model2, valve_type, to_arc, airvalve_param_1, airvalve_param_2, connection_type)
VALUES('-901', '-901', 32.8800, NULL, NULL, 'AIR_VALVE', 'VALVE', 'AIR VALVE DN50', 'FD', '16', '50', NULL, 'UNDEFINED', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.870, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:17:21.000', 'postgres', '2024-08-22 14:17:21.000', 'postgres', 'SRID=25831;POINT (418464.27187965554 4577996.645015663)'::public.geometry, NULL, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0);
SELECT is((SELECT count(*)::integer FROM ve_node_air_valve WHERE code = '-901'), 1, 'INSERT: ve_node_air_valve "-901" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-901'), 1, 'INSERT: node "-901" was inserted');

UPDATE ve_node_air_valve SET descript = 'updated test' WHERE code = '-901';
SELECT is((SELECT descript FROM ve_node_air_valve WHERE code = '-901'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-901'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_air_valve WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_node_air_valve WHERE code = '-901'), 0, 'DELETE: ve_node_air_valve "-901" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-901'), 0, 'DELETE: node "-901" was deleted');


-- ve_node_check_valve
INSERT INTO ve_node_check_valve
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, closed, broken, buried, irrigation_indicator, pressure_entry, pressure_exit, depth_valveshaft, regulator_situation, regulator_location, regulator_observ, lin_meters, exit_type, exit_code, drive_type, cat_valve2, ordinarystatus, shutter, brand2, model2, valve_type, to_arc, checkvalve_param_1, checkvalve_param_2, connection_type)
VALUES('-902', '-902', 32.8800, NULL, NULL, 'CHECK_VALVE', 'VALVE', 'CHK-VALVE63-PN16', 'FD', '16', '63', 65.00000, 'SHORTPIPE', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.870, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:28:10.000', 'postgres', '2024-08-22 14:28:10.000', 'postgres', 'SRID=25831;POINT (418464.49079948553 4577995.057846895)'::public.geometry, 'SHORTPIPE', false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0);
SELECT is((SELECT count(*)::integer FROM ve_node_check_valve WHERE code = '-902'), 1, 'INSERT: ve_node_check_valve "-902" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-902'), 1, 'INSERT: node "-902" was inserted');

UPDATE ve_node_check_valve SET descript = 'updated test' WHERE code = '-902';
SELECT is((SELECT descript FROM ve_node_check_valve WHERE code = '-902'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-902'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_check_valve WHERE code = '-902';
SELECT is((SELECT count(*)::integer FROM ve_node_check_valve WHERE code = '-902'), 0, 'DELETE: ve_node_check_valve "-902" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-902'), 0, 'DELETE: node "-902" was deleted');


-- ve_node_control_register
INSERT INTO ve_node_control_register
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-903', '-903', 32.8800, NULL, NULL, 'CONTROL_REGISTER', 'REGISTER', 'CONTROL_REGISTER_1', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.870, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:28:54.000', 'postgres', '2024-08-22 14:28:54.000', 'postgres', 'SRID=25831;POINT (418464.8191792305 4577993.525408085)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_control_register WHERE code = '-903'), 1, 'INSERT: ve_node_control_register "-903" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-903'), 1, 'INSERT: node "-903" was inserted');

UPDATE ve_node_control_register SET descript = 'updated test' WHERE code = '-903';
SELECT is((SELECT descript FROM ve_node_control_register WHERE code = '-903'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-903'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_control_register WHERE code = '-903';
SELECT is((SELECT count(*)::integer FROM ve_node_control_register WHERE code = '-903'), 0, 'DELETE: ve_node_control_register "-903" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-903'), 0, 'DELETE: node "-903" was deleted');


-- ve_node_curve
INSERT INTO ve_node_curve
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-904', '-904', 32.9700, NULL, NULL, 'CURVE', 'JUNCTION', 'CURVE30DN110 PVCPN16', 'PVC', '16', '110', 94.00000, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.780, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:29:04.000', 'postgres', '2024-08-22 14:29:04.000', 'postgres', 'SRID=25831;POINT (418465.09282901796 4577992.102429191)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_curve WHERE code = '-904'), 1, 'INSERT: ve_node_curve "-904" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-904'), 1, 'INSERT: node "-904" was inserted');

UPDATE ve_node_curve SET descript = 'updated test' WHERE code = '-904';
SELECT is((SELECT descript FROM ve_node_curve WHERE code = '-904'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-904'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_curve WHERE code = '-904';
SELECT is((SELECT count(*)::integer FROM ve_node_curve WHERE code = '-904'), 0, 'DELETE: ve_node_curve "-904" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-904'), 0, 'DELETE: node "-904" was deleted');


-- ve_node_endline
INSERT INTO ve_node_endline
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-905', '-905', 32.9700, NULL, NULL, 'ENDLINE', 'JUNCTION', 'ENDLINE DN63', 'PVC', '16', '63', 54.00000, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.780, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:29:21.000', 'postgres', '2024-08-22 14:29:21.000', 'postgres', 'SRID=25831;POINT (418465.25701889046 4577990.734180253)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_endline WHERE code = '-905'), 1, 'INSERT: ve_node_endline "-905" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-905'), 1, 'INSERT: node "-905" was inserted');

UPDATE ve_node_endline SET descript = 'updated test' WHERE code = '-905';
SELECT is((SELECT descript FROM ve_node_endline WHERE code = '-905'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-905'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_endline WHERE code = '-905';
SELECT is((SELECT count(*)::integer FROM ve_node_endline WHERE code = '-905'), 0, 'DELETE: ve_node_endline "-905" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-905'), 0, 'DELETE: node "-905" was deleted');


-- ve_node_expantank
INSERT INTO ve_node_expantank
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-906', '-906', 32.9700, NULL, NULL, 'EXPANTANK', 'EXPANSIONTANK', 'EXPANTANK', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.780, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:29:50.000', 'postgres', '2024-08-22 14:29:50.000', 'postgres', 'SRID=25831;POINT (418465.4212087629 4577989.365931316)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_expantank WHERE code = '-906'), 1, 'INSERT: ve_node_expantank "-906" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-906'), 1, 'INSERT: node "-906" was inserted');

UPDATE ve_node_expantank SET descript = 'updated test' WHERE code = '-906';
SELECT is((SELECT descript FROM ve_node_expantank WHERE code = '-906'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-906'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_expantank WHERE code = '-906';
SELECT is((SELECT count(*)::integer FROM ve_node_expantank WHERE code = '-906'), 0, 'DELETE: ve_node_expantank "-906" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-906'), 0, 'DELETE: node "-906" was deleted');


-- ve_node_filter
INSERT INTO ve_node_filter
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, filter_param_1, filter_param_2)
VALUES('-907', '-907', 32.9700, NULL, NULL, 'FILTER', 'FILTER', 'FILTER-01-DN200', 'FD', '16', '200', 186.00000, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.780, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:30:05.000', 'postgres', '2024-08-22 14:30:05.000', 'postgres', 'SRID=25831;POINT (418465.6401285929 4577987.614572676)'::public.geometry, 'JUNCTION', NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_filter WHERE code = '-907'), 1, 'INSERT: ve_node_filter "-907" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-907'), 1, 'INSERT: node "-907" was inserted');

UPDATE ve_node_filter SET descript = 'updated test' WHERE code = '-907';
SELECT is((SELECT descript FROM ve_node_filter WHERE code = '-907'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-907'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_filter WHERE code = '-907';
SELECT is((SELECT count(*)::integer FROM ve_node_filter WHERE code = '-907'), 0, 'DELETE: ve_node_filter "-907" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-907'), 0, 'DELETE: node "-907" was deleted');


-- ve_node_flexunion
INSERT INTO ve_node_flexunion
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-908', '-908', 33.0600, NULL, NULL, 'FLEXUNION', 'FLEXUNION', 'FLEXUNION', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.690, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:30:19.000', 'postgres', '2024-08-22 14:30:19.000', 'postgres', 'SRID=25831;POINT (418465.9137783804 4577986.082133867)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_flexunion WHERE code = '-908'), 1, 'INSERT: ve_node_flexunion "-908" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-908'), 1, 'INSERT: node "-908" was inserted');

UPDATE ve_node_flexunion SET descript = 'updated test' WHERE code = '-908';
SELECT is((SELECT descript FROM ve_node_flexunion WHERE code = '-908'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-908'), 'updated test', 'UPDATE: descript was updated to "updated test"');


-- ve_node_flowmeter
INSERT INTO ve_node_flowmeter
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, real_press_max, real_press_min, real_press_avg, meter_code)
VALUES('-909', '-909', 33.0600, NULL, NULL, 'FLOWMETER', 'METER', 'FLOWMETER-01-DN200', 'FD', '16', '200', 186.00000, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.690, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:30:28.000', 'postgres', '2024-08-22 14:30:28.000', 'postgres', 'SRID=25831;POINT (418466.18742816785 4577984.3307752265)'::public.geometry, 'JUNCTION', NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_flowmeter WHERE code = '-909'), 1, 'INSERT: ve_node_flowmeter "-909" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-909'), 1, 'INSERT: node "-909" was inserted');

UPDATE ve_node_flowmeter SET descript = 'updated test' WHERE code = '-909';
SELECT is((SELECT descript FROM ve_node_flowmeter WHERE code = '-909'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-909'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_flowmeter WHERE code = '-909';
SELECT is((SELECT count(*)::integer FROM ve_node_flowmeter WHERE code = '-909'), 0, 'DELETE: ve_node_flowmeter "-909" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-909'), 0, 'DELETE: node "-909" was deleted');


-- ve_node_green_valve
INSERT INTO ve_node_green_valve
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, closed, broken, buried, irrigation_indicator, pressure_entry, pressure_exit, depth_valveshaft, regulator_situation, regulator_location, regulator_observ, lin_meters, exit_type, exit_code, drive_type, cat_valve2, ordinarystatus, shutter, brand2, model2, valve_type, to_arc, greenvalve_param_1, greenvalve_param_2, connection_type)
VALUES('-910', '-910', 33.0600, NULL, NULL, 'GREEN_VALVE', 'VALVE', 'GREENVALVEDN63 PN16', 'FD', '16', '63', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.690, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:30:40.000', 'postgres', '2024-08-22 14:30:40.000', 'postgres', 'SRID=25831;POINT (418466.3516180403 4577983.071986204)'::public.geometry, 'JUNCTION', false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, 0);
SELECT is((SELECT count(*)::integer FROM ve_node_green_valve WHERE code = '-910'), 1, 'INSERT: ve_node_green_valve "-910" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-910'), 1, 'INSERT: node "-910" was inserted');

UPDATE ve_node_green_valve SET descript = 'updated test' WHERE code = '-910';
SELECT is((SELECT descript FROM ve_node_green_valve WHERE code = '-910'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-910'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_green_valve WHERE code = '-910';
SELECT is((SELECT count(*)::integer FROM ve_node_green_valve WHERE code = '-910'), 0, 'DELETE: ve_node_green_valve "-910" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-910'), 0, 'DELETE: node "-910" was deleted');


-- ve_node_hydrant
INSERT INTO ve_node_hydrant
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, fire_code, communication, valve, geom1, geom2, hydrant_type, customer_code, hydrant_param_1, hydrant_param_2)
VALUES('-911', '-911', 33.1500, NULL, NULL, 'HYDRANT', 'HYDRANT', 'HYDRANT 1X110', 'FD', '16', '110', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.600, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:30:54.000', 'postgres', '2024-08-22 14:30:54.000', 'postgres', 'SRID=25831;POINT (418466.5705378703 4577981.43008748)'::public.geometry, 'JUNCTION', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_hydrant WHERE code = '-911'), 1, 'INSERT: ve_node_hydrant "-911" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-911'), 1, 'INSERT: node "-911" was inserted');

UPDATE ve_node_hydrant SET descript = 'updated test' WHERE code = '-911';
SELECT is((SELECT descript FROM ve_node_hydrant WHERE code = '-911'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-911'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_hydrant WHERE code = '-911';
SELECT is((SELECT count(*)::integer FROM ve_node_hydrant WHERE code = '-911'), 0, 'DELETE: ve_node_hydrant "-911" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-911'), 0, 'DELETE: node "-911" was deleted');


-- ve_node_junction
INSERT INTO ve_node_junction
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-912', '-912', 33.1500, NULL, NULL, 'JUNCTION', 'JUNCTION', 'JUNCTION DN63', 'FD', '16', '63', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.600, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:31:10.000', 'postgres', '2024-08-22 14:31:10.000', 'postgres', 'SRID=25831;POINT (418466.7894577002 4577980.444948242)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_junction WHERE code = '-912'), 1, 'INSERT: ve_node_junction "-912" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-912'), 1, 'INSERT: node "-912" was inserted');

UPDATE ve_node_junction SET descript = 'updated test' WHERE code = '-912';
SELECT is((SELECT descript FROM ve_node_junction WHERE code = '-912'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-912'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_junction WHERE code = '-912';
SELECT is((SELECT count(*)::integer FROM ve_node_junction WHERE code = '-912'), 0, 'DELETE: ve_node_junction "-912" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-912'), 0, 'DELETE: node "-912" was deleted');


-- ve_node_manhole
INSERT INTO ve_node_manhole
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, "name")
VALUES('-913', '-913', 33.1500, NULL, NULL, 'MANHOLE', 'MANHOLE', 'MANHOLE', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.600, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:31:25.000', 'postgres', '2024-08-22 14:31:25.000', 'postgres', 'SRID=25831;POINT (418466.9810125514 4577979.760823773)'::public.geometry, 'JUNCTION', NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_manhole WHERE code = '-913'), 1, 'INSERT: ve_node_manhole "-913" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-913'), 1, 'INSERT: node "-913" was inserted');

UPDATE ve_node_manhole SET descript = 'updated test' WHERE code = '-913';
SELECT is((SELECT descript FROM ve_node_manhole WHERE code = '-913'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-913'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_manhole WHERE code = '-913';
SELECT is((SELECT count(*)::integer FROM ve_node_manhole WHERE code = '-913'), 0, 'DELETE: ve_node_manhole "-913" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-913'), 0, 'DELETE: node "-913" was deleted');


-- ve_node_netelement
INSERT INTO ve_node_netelement
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-914', '-914', 33.1500, NULL, NULL, 'NETELEMENT', 'NETELEMENT', 'NETELEMENT', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.600, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:31:36.000', 'postgres', NULL, NULL, 'SRID=25831;POINT (418467.0904724664 4577978.96723939)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_netelement WHERE code = '-914'), 1, 'INSERT: ve_node_netelement "-914" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-914'), 1, 'INSERT: node "-914" was inserted');

UPDATE ve_node_netelement SET descript = 'updated test' WHERE code = '-914';
SELECT is((SELECT descript FROM ve_node_netelement WHERE code = '-914'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-914'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_netelement WHERE code = '-914';
SELECT is((SELECT count(*)::integer FROM ve_node_netelement WHERE code = '-914'), 0, 'DELETE: ve_node_netelement "-914" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-914'), 0, 'DELETE: node "-914" was deleted');


-- ve_node_netsamplepoint
INSERT INTO ve_node_netsamplepoint
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, lab_code)
VALUES('-915', '-915', 33.1500, NULL, NULL, 'NETSAMPLEPOINT', 'NETSAMPLEPOINT', 'NETSAMPLEPOINT', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.600, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:32:04.000', 'postgres', '2024-08-22 14:32:04.000', 'postgres', 'SRID=25831;POINT (418467.17256740265 4577978.118925049)'::public.geometry, 'JUNCTION', NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_netsamplepoint WHERE code = '-915'), 1, 'INSERT: ve_node_netsamplepoint "-915" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-915'), 1, 'INSERT: node "-915" was inserted');

UPDATE ve_node_netsamplepoint SET descript = 'updated test' WHERE code = '-915';
SELECT is((SELECT descript FROM ve_node_netsamplepoint WHERE code = '-915'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-915'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_netsamplepoint WHERE code = '-915';
SELECT is((SELECT count(*)::integer FROM ve_node_netsamplepoint WHERE code = '-915'), 0, 'DELETE: ve_node_netsamplepoint "-915" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-915'), 0, 'DELETE: node "-915" was deleted');


-- ve_node_outfall_valve
INSERT INTO ve_node_outfall_valve
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, closed, broken, buried, irrigation_indicator, pressure_entry, pressure_exit, depth_valveshaft, regulator_situation, regulator_location, regulator_observ, lin_meters, exit_type, exit_code, drive_type, cat_valve2, ordinarystatus, shutter, brand2, model2, valve_type, to_arc, outfallvalve_param_1, outfallvalve_param_2, connection_type)
VALUES('-916', '-916', 33.2400, NULL, NULL, 'OUTFALL_VALVE', 'VALVE', 'OUTFALL VALVE-DN150', 'FD', '16', '150', 145.00000, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.510, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:32:14.000', 'postgres', '2024-08-22 14:32:14.000', 'postgres', 'SRID=25831;POINT (418467.30939229636 4577977.21588075)'::public.geometry, 'JUNCTION', false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0);
SELECT is((SELECT count(*)::integer FROM ve_node_outfall_valve WHERE code = '-916'), 1, 'INSERT: ve_node_outfall_valve "-916" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-916'), 1, 'INSERT: node "-916" was inserted');

UPDATE ve_node_outfall_valve SET descript = 'updated test' WHERE code = '-916';
SELECT is((SELECT descript FROM ve_node_outfall_valve WHERE code = '-916'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-916'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_outfall_valve WHERE code = '-916';
SELECT is((SELECT count(*)::integer FROM ve_node_outfall_valve WHERE code = '-916'), 0, 'DELETE: ve_node_outfall_valve "-916" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-916'), 0, 'DELETE: node "-916" was deleted');


-- ve_node_pressure_meter
INSERT INTO ve_node_pressure_meter
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, real_press_max, real_press_min, real_press_avg, meter_code, pressmeter_param_1, pressmeter_param_2)
VALUES('-917', '-917', 33.2400, NULL, NULL, 'PRESSURE_METER', 'METER', 'PRESMETER-63-PN16', 'FD', '16', '63', 65.00000, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.510, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:33:24.000', 'postgres', '2024-08-22 14:33:24.000', 'postgres', 'SRID=25831;POINT (418467.4462171901 4577976.449661345)'::public.geometry, 'JUNCTION', NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_pressure_meter WHERE code = '-917'), 1, 'INSERT: ve_node_pressure_meter "-917" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-917'), 1, 'INSERT: node "-917" was inserted');

UPDATE ve_node_pressure_meter SET descript = 'updated test' WHERE code = '-917';
SELECT is((SELECT descript FROM ve_node_pressure_meter WHERE code = '-917'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_pressure_meter WHERE code = '-917';
SELECT is((SELECT count(*)::integer FROM ve_node_pressure_meter WHERE code = '-917'), 0, 'DELETE: ve_node_pressure_meter "-917" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-917'), 0, 'DELETE: node "-917" was deleted');


-- ve_node_pump
INSERT INTO ve_node_pump
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, max_flow, min_flow, nom_flow, power, pressure_exit, elev_height, "name", pump_number, to_arc)
VALUES('-918', '-918', 33.1200, NULL, NULL, 'PUMP', 'PUMP', 'PUMP-01', 'FD', '16', '110', 98.00000, 'PUMP', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.630, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:33:32.000', 'postgres', '2024-08-22 14:33:32.000', 'postgres', 'SRID=25831;POINT (418467.61040706263 4577975.628711983)'::public.geometry, 'PUMP', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_pump WHERE code = '-918'), 1, 'INSERT: ve_node_pump "-918" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-918'), 1, 'INSERT: node "-918" was inserted');

UPDATE ve_node_pump SET descript = 'updated test' WHERE code = '-918';
SELECT is((SELECT descript FROM ve_node_pump WHERE code = '-918'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-918'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_pump WHERE code = '-918';
SELECT is((SELECT count(*)::integer FROM ve_node_pump WHERE code = '-918'), 0, 'DELETE: ve_node_pump "-918" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-918'), 0, 'DELETE: node "-918" was deleted');


-- ve_node_reduction
INSERT INTO ve_node_reduction
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, diam1, diam2)
VALUES('-919', '-919', 33.1200, NULL, NULL, 'REDUCTION', 'REDUCTION', 'REDUC_110-90 PN16', 'PVC', '16', '110', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.630, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:33:40.000', 'postgres', '2024-08-22 14:33:40.000', 'postgres', 'SRID=25831;POINT (418467.7745969351 4577974.889857557)'::public.geometry, 'JUNCTION', NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_reduction WHERE code = '-919'), 1, 'INSERT: ve_node_reduction "-919" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-919'), 1, 'INSERT: node "-919" was inserted');

UPDATE ve_node_reduction SET descript = 'updated test' WHERE code = '-919';
SELECT is((SELECT descript FROM ve_node_reduction WHERE code = '-919'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-919'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_reduction WHERE code = '-919';
SELECT is((SELECT count(*)::integer FROM ve_node_reduction WHERE code = '-919'), 0, 'DELETE: ve_node_reduction "-919" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-919'), 0, 'DELETE: node "-919" was deleted');


-- ve_node_register
INSERT INTO ve_node_register
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-920', '-920', 33.1200, NULL, NULL, 'REGISTER', 'REGISTER', 'REGISTER', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.630, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:33:48.000', 'postgres', '2024-08-22 14:33:48.000', 'postgres', 'SRID=25831;POINT (418467.82932689256 4577974.014178237)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_register WHERE code = '-920'), 1, 'INSERT: ve_node_register "-920" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-920'), 1, 'INSERT: node "-920" was inserted');

UPDATE ve_node_register SET descript = 'updated test' WHERE code = '-920';
SELECT is((SELECT descript FROM ve_node_register WHERE code = '-920'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-920'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_register WHERE code = '-920';
SELECT is((SELECT count(*)::integer FROM ve_node_register WHERE code = '-920'), 0, 'DELETE: ve_node_register "-920" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-920'), 0, 'DELETE: node "-920" was deleted');


-- ve_node_shutoff_valve
INSERT INTO ve_node_shutoff_valve
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, closed, broken, buried, irrigation_indicator, pressure_entry, pressure_exit, depth_valveshaft, regulator_situation, regulator_location, regulator_observ, lin_meters, exit_type, exit_code, drive_type, cat_valve2, ordinarystatus, shutter, brand2, model2, valve_type, to_arc, shtvalve_param_1, shtvalve_param_2, connection_type)
VALUES('-921', '-921', 33.1200, NULL, NULL, 'SHUTOFF_VALVE', 'VALVE', 'SHTFF-VALVE160-PN16', 'FD', '16', '160', 148.00000, 'SHORTPIPE', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.630, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:33:58.000', 'postgres', '2024-08-22 14:33:58.000', 'postgres', 'SRID=25831;POINT (418467.843009382 4577973.480561153)'::public.geometry, 'SHORTPIPE', false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0);
SELECT is((SELECT count(*)::integer FROM ve_node_shutoff_valve WHERE code = '-921'), 1, 'INSERT: ve_node_shutoff_valve "-921" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-921'), 1, 'INSERT: node "-921" was inserted');

UPDATE ve_node_shutoff_valve SET descript = 'updated test' WHERE code = '-921';
SELECT is((SELECT descript FROM ve_node_shutoff_valve WHERE code = '-921'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-921'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_shutoff_valve WHERE code = '-921';
SELECT is((SELECT count(*)::integer FROM ve_node_shutoff_valve WHERE code = '-921'), 0, 'DELETE: ve_node_shutoff_valve "-921" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-921'), 0, 'DELETE: node "-921" was deleted');


-- ve_node_source
INSERT INTO ve_node_source
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, "name", source_type, aquifer_type, basin_id, subbasin_id)
VALUES('-922', '-922', 33.1200, NULL, NULL, 'SOURCE', 'SOURCE', 'SOURCE-01', 'N/I', NULL, NULL, NULL, 'RESERVOIR', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.630, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:34:08.000', 'postgres', '2024-08-22 14:34:08.000', 'postgres', 'SRID=25831;POINT (418467.9251043183 4577972.89221411)'::public.geometry, 'RESERVOIR', NULL, 0, 0, 0, 0);
SELECT is((SELECT count(*)::integer FROM ve_node_source WHERE code = '-922'), 1, 'INSERT: ve_node_source "-922" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-922'), 1, 'INSERT: node "-922" was inserted');

UPDATE ve_node_source SET descript = 'updated test' WHERE code = '-922';
SELECT is((SELECT descript FROM ve_node_source WHERE code = '-922'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-922'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_source WHERE code = '-922';
SELECT is((SELECT count(*)::integer FROM ve_node_source WHERE code = '-922'), 0, 'DELETE: ve_node_source "-922" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-922'), 0, 'DELETE: node "-922" was deleted');


-- ve_node_t
INSERT INTO ve_node_t
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-923', '-923', 33.2100, NULL, NULL, 'T', 'JUNCTION', 'TDN110-63 PN16', 'PVC', '16', '110', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.540, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:34:16.000', 'postgres', '2024-08-22 14:34:16.000', 'postgres', 'SRID=25831;POINT (418468.04824672267 4577972.495421918)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_t WHERE code = '-923'), 1, 'INSERT: ve_node_t "-923" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-923'), 1, 'INSERT: node "-923" was inserted');

UPDATE ve_node_t SET descript = 'updated test' WHERE code = '-923';
SELECT is((SELECT descript FROM ve_node_t WHERE code = '-923'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-923'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_t WHERE code = '-923';
SELECT is((SELECT count(*)::integer FROM ve_node_t WHERE code = '-923'), 0, 'DELETE: ve_node_t "-923" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-923'), 0, 'DELETE: node "-923" was deleted');


-- ve_node_tank
INSERT INTO ve_node_tank
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, vmax, vutil, area, chlorination, "name", hmax, tank_param_1, tank_param_2, shape)
VALUES('-924', '-924', 33.2100, NULL, NULL, 'TANK', 'TANK', 'TANK_01', 'FD', NULL, NULL, NULL, 'TANK', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 38.540, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:34:27.000', 'postgres', '2024-08-22 14:34:27.000', 'postgres', 'SRID=25831;POINT (418468.1166591695 4577972.125994705)'::public.geometry, 'TANK', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0);
SELECT is((SELECT count(*)::integer FROM ve_node_tank WHERE code = '-924'), 1, 'INSERT: ve_node_tank "-924" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-924'), 1, 'INSERT: node "-924" was inserted');

UPDATE ve_node_tank SET descript = 'updated test' WHERE code = '-924';
SELECT is((SELECT descript FROM ve_node_tank WHERE code = '-924'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-924'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_tank WHERE code = '-924';
SELECT is((SELECT count(*)::integer FROM ve_node_tank WHERE code = '-924'), 0, 'DELETE: ve_node_tank "-924" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-924'), 0, 'DELETE: node "-924" was deleted');


-- ve_node_water_connection
INSERT INTO ve_node_water_connection
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, customer_code, top_floor, wjoin_type)
VALUES('-925', '-925', 33.2100, NULL, NULL, 'WATER_CONNECTION', 'NETWJOIN', 'WATER-CONNECTION', 'N/I', NULL, NULL, NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:34:53.000', 'postgres', NULL, NULL, 'SRID=25831;POINT (418468.171389127 4577971.592377619)'::public.geometry, 'JUNCTION', NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_water_connection WHERE code = '-925'), 1, 'INSERT: ve_node_water_connection "-925" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-925'), 1, 'INSERT: node "-925" was inserted');

UPDATE ve_node_water_connection SET descript = 'updated test' WHERE code = '-925';
SELECT is((SELECT descript FROM ve_node_water_connection WHERE code = '-925'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-925'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_water_connection WHERE code = '-925';
SELECT is((SELECT count(*)::integer FROM ve_node_water_connection WHERE code = '-925'), 0, 'DELETE: ve_node_water_connection "-925" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-925'), 0, 'DELETE: node "-925" was deleted');


-- ve_node_waterwell
INSERT INTO ve_node_waterwell
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, "name", inlet_arc)
VALUES('-926', '-926', 33.2100, NULL, NULL, 'WATERWELL', 'WATERWELL', 'WATERWELL-01', 'FD', NULL, NULL, NULL, 'RESERVOIR', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:35:15.000', 'postgres', '2024-08-22 14:35:15.000', 'postgres', 'SRID=25831;POINT (418468.171389127 4577971.195585428)'::public.geometry, 'RESERVOIR', NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_waterwell WHERE code = '-926'), 1, 'INSERT: ve_node_waterwell "-926" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-926'), 1, 'INSERT: node "-926" was inserted');

UPDATE ve_node_waterwell SET descript = 'updated test' WHERE code = '-926';
SELECT is((SELECT descript FROM ve_node_waterwell WHERE code = '-926'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-926'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_waterwell WHERE code = '-926';
SELECT is((SELECT count(*)::integer FROM ve_node_waterwell WHERE code = '-926'), 0, 'DELETE: ve_node_waterwell "-926" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-926'), 0, 'DELETE: node "-926" was deleted');


-- ve_node_wtp
INSERT INTO ve_node_wtp
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type, "name")
VALUES('-927', '-927', 33.2100, NULL, NULL, 'WTP', 'WTP', 'ETAP', 'N/I', NULL, NULL, NULL, 'RESERVOIR', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:35:28.000', 'postgres', '2024-08-22 14:35:28.000', 'postgres', 'SRID=25831;POINT (418468.29453153134 4577970.716698299)'::public.geometry, 'RESERVOIR', NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_wtp WHERE code = '-927'), 1, 'INSERT: ve_node_wtp "-927" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-927'), 1, 'INSERT: node "-927" was inserted');

UPDATE ve_node_wtp SET descript = 'updated test' WHERE code = '-927';
SELECT is((SELECT descript FROM ve_node_wtp WHERE code = '-927'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-927'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_wtp WHERE code = '-927';
SELECT is((SELECT count(*)::integer FROM ve_node_wtp WHERE code = '-927'), 0, 'DELETE: ve_node_wtp "-927" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-927'), 0, 'DELETE: node "-927" was deleted');


-- ve_node_x
INSERT INTO ve_node_x
(node_id, code, top_elev, custom_top_elev, "depth", node_type, sys_type, nodecat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, arc_id, parent_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, hemisphere, num_value, adate, adescript, accessibility, dma_style, presszone_style, asset_id, om_state, conserv_state, access_type, placement_type, is_operative, brand_id, model_id, serial_number, minsector_id, demand_max, demand_min, demand_avg, press_max, press_min, press_avg, head_max, head_min, head_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-928', '-928', 33.2100, NULL, NULL, 'X', 'JUNCTION', 'XDN110 PN16', 'FD', '16', '110', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', NULL, NULL, NULL, NULL, true, true, NULL, NULL, NULL, NULL, NULL, '204,235,197', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-08-22 14:35:37.000', 'postgres', '2024-08-22 14:35:37.000', 'postgres', 'SRID=25831;POINT (418468.39030895696 4577970.2378111705)'::public.geometry, 'JUNCTION');
SELECT is((SELECT count(*)::integer FROM ve_node_x WHERE code = '-928'), 1, 'INSERT: ve_node_x "-928" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-928'), 1, 'INSERT: node "-928" was inserted');

UPDATE ve_node_x SET descript = 'updated test' WHERE code = '-928';
SELECT is((SELECT descript FROM ve_node_x WHERE code = '-928'), 'updated test', 'UPDATE: descript was updated to "updated test"');
SELECT is((SELECT descript FROM node WHERE code = '-928'), 'updated test', 'UPDATE: descript was updated to "updated test"');

DELETE FROM ve_node_x WHERE code = '-928';
SELECT is((SELECT count(*)::integer FROM ve_node_x WHERE code = '-928'), 0, 'DELETE: ve_node_x "-928" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-928'), 0, 'DELETE: node "-928" was deleted');


SELECT * FROM finish();

ROLLBACK;

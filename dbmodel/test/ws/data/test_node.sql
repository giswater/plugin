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

SELECT plan(84);

-- node -> airvalve
INSERT INTO node (node_id, code, sys_code, top_elev, custom_top_elev,"depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-901', '-901', '-901', 32.8800, NULL, NULL, 'AIR VALVE DN50', 'UNDEFINED', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418464.27187965554 4577996.645015663)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:17:21.141', '2024-08-22 14:17:21.238', 'postgres', 'postgres', NULL, NULL, 38.870, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-901'), 1, 'INSERT: node:airvalve "-901" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-901';
SELECT is((SELECT descript FROM node WHERE node_id = '-901'), 'updated test', 'UPDATE: node:airvalve "-901" was updated');

DELETE FROM node WHERE node_id = '-901';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-901'), 0, 'DELETE: node:airvalve "-901" was deleted');


-- node -> checkvalve
INSERT INTO node (node_id, code, sys_code, top_elev, custom_top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-902', '-902', '-902', 32.8800, NULL, NULL, 'CHK-VALVE63-PN16', 'SHORTPIPE', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418464.49079948553 4577995.057846895)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:28:10.079', '2024-08-22 14:28:10.131', 'postgres', 'postgres', NULL, NULL, 38.870, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-902'), 1, 'INSERT: node:checkvalve "-902" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-902';
SELECT is((SELECT descript FROM node WHERE node_id = '-902'), 'updated test', 'UPDATE: node:checkvalve "-902" was updated');

DELETE FROM node WHERE node_id = '-902';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-902'), 0, 'DELETE: node:checkvalve "-902" was deleted');


-- node -> control register
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-903', '-903', '-903', 32.8800, NULL, 'CONTROL_REGISTER_1', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418464.8191792305 4577993.525408085)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:28:54.406', '2024-08-22 14:28:54.449', 'postgres', 'postgres', NULL, NULL, 38.870, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-903'), 1, 'INSERT: node:control-register "-903" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-903';
SELECT is((SELECT descript FROM node WHERE node_id = '-903'), 'updated test', 'UPDATE: node:control-register "-903" was updated');

DELETE FROM node WHERE node_id = '-903';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-903'), 0, 'DELETE: node:control-register "-903" was deleted');


-- node -> curve
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-904', '-904', '-904', 32.9700, NULL, 'CURVE30DN110 PVCPN16', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418465.09282901796 4577992.102429191)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:29:04.037', '2024-08-22 14:29:04.087', 'postgres', 'postgres', NULL, NULL, 38.780, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-904'), 1, 'INSERT: node:curve "-904" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-904';
SELECT is((SELECT descript FROM node WHERE node_id = '-904'), 'updated test', 'UPDATE: node:curve "-904" was updated');

DELETE FROM node WHERE node_id = '-904';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-904'), 0, 'DELETE: node:curve "-904" was deleted');


-- node -> endline
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-905', '-905', '-905', 32.9700, NULL, 'ENDLINE DN63', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418465.25701889046 4577990.734180253)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:29:21.851', '2024-08-22 14:29:21.891', 'postgres', 'postgres', NULL, NULL, 38.780, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-905'), 1, 'INSERT: node:endline "-905" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-905';
SELECT is((SELECT descript FROM node WHERE node_id = '-905'), 'updated test', 'UPDATE: node:endline "-905" was updated');

DELETE FROM node WHERE node_id = '-905';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-905'), 0, 'DELETE: node:endline "-905" was deleted');


-- node -> expantank
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-906', '-906', '-906', 32.9700, NULL, 'EXPANTANK', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418465.4212087629 4577989.365931316)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:29:50.488', '2024-08-22 14:29:50.529', 'postgres', 'postgres', NULL, NULL, 38.780, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-906'), 1, 'INSERT: node:expantank "-906" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-906';
SELECT is((SELECT descript FROM node WHERE node_id = '-906'), 'updated test', 'UPDATE: node:expantank "-906" was updated');

DELETE FROM node WHERE node_id = '-906';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-906'), 0, 'DELETE: node:expantank "-906" was deleted');


-- node -> filter
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-907', '-907', '-907', 32.9700, NULL, 'FILTER-01-DN200', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418465.6401285929 4577987.614572676)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:30:05.376', '2024-08-22 14:30:05.414', 'postgres', 'postgres', NULL, NULL, 38.780, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-907'), 1, 'INSERT: node:filter "-907" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-907';
SELECT is((SELECT descript FROM node WHERE node_id = '-907'), 'updated test', 'UPDATE: node:filter "-907" was updated');

DELETE FROM node WHERE node_id = '-907';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-907'), 0, 'DELETE: node:filter "-907" was deleted');


-- node -> flexunion
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-908', '-908', '-908', 33.0600, NULL, 'FLEXUNION', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418465.9137783804 4577986.082133867)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:30:19.395', '2024-08-22 14:30:19.421', 'postgres', 'postgres', NULL, NULL, 38.690, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-908'), 1, 'INSERT: node:flexunion "-908" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-908';
SELECT is((SELECT descript FROM node WHERE node_id = '-908'), 'updated test', 'UPDATE: node:flexunion "-908" was updated');

DELETE FROM node WHERE node_id = '-908';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-908'), 0, 'DELETE: node:flexunion "-908" was deleted');

-- node -> flowmeter
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-909', '-909', '-909', 33.0600, NULL, 'FLOWMETER-01-DN200', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418466.18742816785 4577984.3307752265)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:30:28.600', '2024-08-22 14:30:28.627', 'postgres', 'postgres', NULL, NULL, 38.690, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-909'), 1, 'INSERT: node:flowmeter "-909" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-909';
SELECT is((SELECT descript FROM node WHERE node_id = '-909'), 'updated test', 'UPDATE: node:flowmeter "-909" was updated');

DELETE FROM node WHERE node_id = '-909';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-909'), 0, 'DELETE: node:flowmeter "-909" was deleted');


-- node -> greenvalve
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-910', '-910', '-910', 33.0600, NULL, 'GREENVALVEDN63 PN16', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418466.3516180403 4577983.071986204)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:30:40.033', '2024-08-22 14:30:40.058', 'postgres', 'postgres', NULL, NULL, 38.690, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-910'), 1, 'INSERT: node:greenvalve "-910" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-910';
SELECT is((SELECT descript FROM node WHERE node_id = '-910'), 'updated test', 'UPDATE: node:greenvalve "-910" was updated');

DELETE FROM node WHERE node_id = '-910';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-910'), 0, 'DELETE: node:greenvalve "-910" was deleted');


-- node -> hydrant
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-911', '-911', '-911', 33.1500, NULL, 'HYDRANT 1X110', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418466.5705378703 4577981.43008748)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:30:54.591', '2024-08-22 14:30:54.618', 'postgres', 'postgres', NULL, NULL, 38.600, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-911'), 1, 'INSERT: node:hydrant "-911" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-911';
SELECT is((SELECT descript FROM node WHERE node_id = '-911'), 'updated test', 'UPDATE: node:hydrant "-911" was updated');

DELETE FROM node WHERE node_id = '-911';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-911'), 0, 'DELETE: node:hydrant "-911" was deleted');


-- node -> junction
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-912', '-912', '-912', 33.1500, NULL, 'JUNCTION DN63', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418466.7894577002 4577980.444948242)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:31:10.492', '2024-08-22 14:31:10.517', 'postgres', 'postgres', NULL, NULL, 38.600, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-912'), 1, 'INSERT: node:junction "-912" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-912';
SELECT is((SELECT descript FROM node WHERE node_id = '-912'), 'updated test', 'UPDATE: node:junction "-912" was updated');

DELETE FROM node WHERE node_id = '-912';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-912'), 0, 'DELETE: node:junction "-912" was deleted');


-- node -> manhole
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-913', '-913', '-913', 33.1500, NULL, 'MANHOLE', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418466.9810125514 4577979.760823773)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:31:25.808', '2024-08-22 14:31:25.834', 'postgres', 'postgres', NULL, NULL, 38.600, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-913'), 1, 'INSERT: node:manhole "-913" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-913';
SELECT is((SELECT descript FROM node WHERE node_id = '-913'), 'updated test', 'UPDATE: node:manhole "-913" was updated');

DELETE FROM node WHERE node_id = '-913';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-913'), 0, 'DELETE: node:manhole "-913" was deleted');


-- node -> netsamplepoint
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-914', '-914', '-914', 33.1500, NULL, 'NETSAMPLEPOINT', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.17256740265 4577978.118925049)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:32:04.514', '2024-08-22 14:32:04.551', 'postgres', 'postgres', NULL, NULL, 38.600, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-914'), 1, 'INSERT: node:netsamplepoint "-914" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-914';
SELECT is((SELECT descript FROM node WHERE node_id = '-914'), 'updated test', 'UPDATE: node:netsamplepoint "-914" was updated');

DELETE FROM node WHERE node_id = '-914';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-914'), 0, 'DELETE: node:netsamplepoint "-914" was deleted');


-- node -> netelement
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-915', '-915', '-915', 33.1500, NULL, 'NETELEMENT', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1', NULL, 'SRID=25831;POINT (418467.0904724664 4577978.96723939)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:31:36.283', NULL, NULL, 'postgres', NULL, NULL, 38.600, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-915'), 1, 'INSERT: node:netelement "-915" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-915';
SELECT is((SELECT descript FROM node WHERE node_id = '-915'), 'updated test', 'UPDATE: node:netelement "-915" was updated');

DELETE FROM node WHERE node_id = '-915';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-915'), 0, 'DELETE: node:netelement "-915" was deleted');


-- node -> pressuremeter
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-916', '-916', '-916', 33.2400, NULL, 'PRESMETER-63-PN16', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.4462171901 4577976.449661345)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:33:24.035', '2024-08-22 14:33:24.060', 'postgres', 'postgres', NULL, NULL, 38.510, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-916'), 1, 'INSERT: node:pressuremeter "-916" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-916';
SELECT is((SELECT descript FROM node WHERE node_id = '-916'), 'updated test', 'UPDATE: node:pressuremeter "-916" was updated');

DELETE FROM node WHERE node_id = '-916';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-916'), 0, 'DELETE: node:pressuremeter "-916" was deleted');


-- node -> outfall valve
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-917', '-917', '-917', 33.2400, NULL, 'OUTFALL VALVE-DN150', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.30939229636 4577977.21588075)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:32:14.748', '2024-08-22 14:32:14.774', 'postgres', 'postgres', NULL, NULL, 38.510, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-917'), 1, 'INSERT: node:outfall valve "-917" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-917';
SELECT is((SELECT descript FROM node WHERE node_id = '-917'), 'updated test', 'UPDATE: node:outfall valve "-917" was updated');

DELETE FROM node WHERE node_id = '-917';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-917'), 0, 'DELETE: node:outfall valve "-917" was deleted');


-- node -> pump
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-918', '-918', '-918', 33.1200, NULL, 'PUMP-01', 'PUMP', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.61040706263 4577975.628711983)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:33:32.626', '2024-08-22 14:33:32.653', 'postgres', 'postgres', NULL, NULL, 38.630, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-918'), 1, 'INSERT: node:pump "-918" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-918';
SELECT is((SELECT descript FROM node WHERE node_id = '-918'), 'updated test', 'UPDATE: node:pump "-918" was updated');

DELETE FROM node WHERE node_id = '-918';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-918'), 0, 'DELETE: node:pump "-918" was deleted');


-- node -> reduction
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-919', '-919', '-919', 33.1200, NULL, 'REDUC_110-90 PN16', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.7745969351 4577974.889857557)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:33:40.012', '2024-08-22 14:33:40.039', 'postgres', 'postgres', NULL, NULL, 38.630, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-919'), 1, 'INSERT: node:reduction "-919" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-919';
SELECT is((SELECT descript FROM node WHERE node_id = '-919'), 'updated test', 'UPDATE: node:reduction "-919" was updated');

DELETE FROM node WHERE node_id = '-919';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-919'), 0, 'DELETE: node:reduction "-919" was deleted');

-- node -> register
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-920', '-920', '-920', 33.1200, NULL, 'REGISTER', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.82932689256 4577974.014178237)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:33:48.102', '2024-08-22 14:33:48.128', 'postgres', 'postgres', NULL, NULL, 38.630, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-920'), 1, 'INSERT: node:register "-920" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-920';
SELECT is((SELECT descript FROM node WHERE node_id = '-920'), 'updated test', 'UPDATE: node:register "-920" was updated');

DELETE FROM node WHERE node_id = '-920';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-920'), 0, 'DELETE: node:register "-920" was deleted');


-- node -> shutoff_valve
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-921', '-921', '-921', 33.1200, NULL, 'SHTFF-VALVE160-PN16', 'SHORTPIPE', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.843009382 4577973.480561153)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:33:58.650', '2024-08-22 14:33:58.677', 'postgres', 'postgres', NULL, NULL, 38.630, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-921'), 1, 'INSERT: node:shutoff_valve "-921" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-921';
SELECT is((SELECT descript FROM node WHERE node_id = '-921'), 'updated test', 'UPDATE: node:shutoff_valve "-921" was updated');

DELETE FROM node WHERE node_id = '-921';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-921'), 0, 'DELETE: node:shutoff_valve "-921" was deleted');


-- node -> source
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-922', '-922', '-922', 33.1200, NULL, 'SOURCE-01', 'RESERVOIR', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418467.9251043183 4577972.89221411)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:34:08.731', '2024-08-22 14:34:08.759', 'postgres', 'postgres', NULL, NULL, 38.630, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-922'), 1, 'INSERT: node:source "-922" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-922';
SELECT is((SELECT descript FROM node WHERE node_id = '-922'), 'updated test', 'UPDATE: node:source "-922" was updated');

DELETE FROM node WHERE node_id = '-922';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-922'), 0, 'DELETE: node:source "-922" was deleted');


-- node -> t
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-923', '-923', '-923', 33.2100, NULL, 'TDN110-63 PN16', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418468.04824672267 4577972.495421918)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:34:16.715', '2024-08-22 14:34:16.740', 'postgres', 'postgres', NULL, NULL, 38.540, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-923'), 1, 'INSERT: node:t "-923" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-923';
SELECT is((SELECT descript FROM node WHERE node_id = '-923'), 'updated test', 'UPDATE: node:t "-923" was updated');

DELETE FROM node WHERE node_id = '-923';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-923'), 0, 'DELETE: node:t "-923" was deleted');


-- node -> tank
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-924', '-924', '-924', 33.2100, NULL, 'TANK_01', 'TANK', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418468.1166591695 4577972.125994705)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:34:27.199', '2024-08-22 14:34:27.258', 'postgres', 'postgres', NULL, NULL, 38.540, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-924'), 1, 'INSERT: node:tank "-924" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-924';
SELECT is((SELECT descript FROM node WHERE node_id = '-924'), 'updated test', 'UPDATE: node:tank "-924" was updated');

DELETE FROM node WHERE node_id = '-924';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-924'), 0, 'DELETE: node:tank "-924" was deleted');


-- node -> water_connection
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-925', '-925', '-925', 33.2100, NULL, 'WATER-CONNECTION', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1', NULL, 'SRID=25831;POINT (418468.171389127 4577971.592377619)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:34:53.188', NULL, NULL, 'postgres', NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-925'), 1, 'INSERT: node:water_connection "-925" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-925';
SELECT is((SELECT descript FROM node WHERE node_id = '-925'), 'updated test', 'UPDATE: node:water_connection "-925" was updated');

DELETE FROM node WHERE node_id = '-925';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-925'), 0, 'DELETE: node:water_connection "-925" was deleted');


-- node -> waterwell
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-926', '-926', '-926', 33.2100, NULL, 'WATERWELL-01', 'RESERVOIR', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418468.171389127 4577971.195585428)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:35:15.361', '2024-08-22 14:35:15.393', 'postgres', 'postgres', NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-926'), 1, 'INSERT: node:waterwell "-926" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-926';
SELECT is((SELECT descript FROM node WHERE node_id = '-926'), 'updated test', 'UPDATE: node:waterwell "-926" was updated');

DELETE FROM node WHERE node_id = '-926';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-926'), 0, 'DELETE: node:waterwell "-926" was deleted');


-- node -> wtp
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-927', '-927', '-927', 33.2100, NULL, 'ETAP', 'RESERVOIR', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418468.29453153134 4577970.716698299)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:35:28.066', '2024-08-22 14:35:28.093', 'postgres', 'postgres', NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-927'), 1, 'INSERT: node:wtp "-927" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-927';
SELECT is((SELECT descript FROM node WHERE node_id = '-927'), 'updated test', 'UPDATE: node:wtp "-927" was updated');

DELETE FROM node WHERE node_id = '-927';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-927'), 0, 'DELETE: node:wtp "-927" was deleted');


-- node -> x
INSERT INTO node (node_id, code, sys_code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state,
state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type,
location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id,
postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom,
label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at,
updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility,
workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-928', '-928', '-928', 33.2100, NULL, 'XDN110 PN16', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418468.39030895696 4577970.2378111705)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 2, NULL, 'NODE', '2024-08-22 14:35:37.892', '2024-08-22 14:35:37.918', 'postgres', 'postgres', NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-928'), 1, 'INSERT: node:x "-928" was inserted');

UPDATE node SET descript = 'updated test' WHERE node_id = '-928';
SELECT is((SELECT descript FROM node WHERE node_id = '-928'), 'updated test', 'UPDATE: node:x "-928" was updated');

DELETE FROM node WHERE node_id = '-928';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-928'), 0, 'DELETE: node:x "-928" was deleted');

SELECT * FROM finish();

ROLLBACK;

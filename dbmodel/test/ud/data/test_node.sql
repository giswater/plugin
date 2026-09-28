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

SELECT plan(54);

-- node -> chamber
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-901', '-901', '-901', 33.220, NULL, NULL, NULL, NULL, 'CHAMBER', 'CHAMBER-01', 'STORAGE', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.7137334756 4577989.971585366)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:39:25.227', NULL, '2024-08-23 10:39:25.306', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-901'), 1, 'INSERT: node "-901" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-901';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-901'), 33.000, 'UPDATE: node "-901" was updated');

DELETE FROM node WHERE node_id = '-901';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-901'), 0, 'DELETE: node "-901" was deleted');


-- node -> change
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-902', '-902', '-902', 33.220, NULL, NULL, NULL, NULL, 'CHANGE', 'CHANGE_1', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.8107021616 4577989.445183928)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:39:33.554', NULL, '2024-08-23 10:39:33.605', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-902'), 1, 'INSERT: node "-902" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-902';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-902'), 33.000, 'UPDATE: node "-902" was updated');

DELETE FROM node WHERE node_id = '-902';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-902'), 0, 'DELETE: node "-902" was deleted');


-- node -> circ_manhole
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-903', '-903', '-903', 33.220, NULL, NULL, NULL, NULL, 'CIRC_MANHOLE', 'C_MANHOLE_100', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.90767084755 4577988.974193167)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:39:42.985', NULL, '2024-08-23 10:39:43.040', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-903'), 1, 'INSERT: node "-903" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-903';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-903'), 33.000, 'UPDATE: node "-903" was updated');

DELETE FROM node WHERE node_id = '-903';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-903'), 0, 'DELETE: node "-903" was deleted');


-- node -> highpoint
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-904', '-904', '-904', 33.220, NULL, NULL, NULL, NULL, 'HIGHPOINT', 'HIGH POINT-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.9907868641 4577988.489349738)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:39:50.929', NULL, '2024-08-23 10:39:50.977', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-904'), 1, 'INSERT: node "-904" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-904';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-904'), 33.000, 'UPDATE: node "-904" was updated');

DELETE FROM node WHERE node_id = '-904';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-904'), 0, 'DELETE: node "-904" was deleted');


-- node -> jump
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-905', '-905', '-905', 33.220, NULL, NULL, NULL, NULL, 'JUMP', 'JUMP-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.9907868641 4577988.17073834)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:40:03.235', NULL, '2024-08-23 10:40:03.284', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-905'), 1, 'INSERT: node "-905" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-905';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-905'), 33.000, 'UPDATE: node "-905" was updated');

DELETE FROM node WHERE node_id = '-905';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-905'), 0, 'DELETE: node "-905" was deleted');


-- node -> netelement
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-906', '-906', '-906', 33.220, NULL, NULL, NULL, NULL, 'NETELEMENT', 'NETELEMENT-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.12931355834 4577987.71360025)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:40:12.914', NULL, '2024-08-23 10:40:12.965', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-906'), 1, 'INSERT: node "-906" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-906';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-906'), 33.000, 'UPDATE: node "-906" was updated');

DELETE FROM node WHERE node_id = '-906';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-906'), 0, 'DELETE: node "-906" was deleted');


-- node -> netgully
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-907', '-907', '-907', 33.300, NULL, NULL, NULL, NULL, 'NETGULLY', 'NETGULLY-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.184724236 4577987.325725506)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:40:22.746', NULL, '2024-08-23 10:40:22.784', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-907'), 1, 'INSERT: node "-907" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-907';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-907'), 33.000, 'UPDATE: node "-907" was updated');

DELETE FROM node WHERE node_id = '-907';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-907'), 0, 'DELETE: node "-907" was deleted');


-- node -> netinit
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-908', '-908', '-908', 33.300, NULL, NULL, NULL, NULL, 'NETINIT', 'NETINIT-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.2678402526 4577986.868587415)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:40:33.250', NULL, '2024-08-23 10:40:33.287', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-908'), 1, 'INSERT: node "-908" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-908';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-908'), 33.000, 'UPDATE: node "-908" was updated');

DELETE FROM node WHERE node_id = '-908';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-908'), 0, 'DELETE: node "-908" was deleted');


-- node -> outfall
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-909', '-909', '-909', 33.300, NULL, NULL, NULL, NULL, 'OUTFALL', 'OUTFALL-01', 'OUTFALL', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.36480893864 4577986.356038646)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:40:43.539', NULL, '2024-08-23 10:40:43.577', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-909'), 1, 'INSERT: node "-909" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-909';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-909'), 33.000, 'UPDATE: node "-909" was updated');

DELETE FROM node WHERE node_id = '-909';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-909'), 0, 'DELETE: node "-909" was deleted');


-- node -> overflow_storage
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-910', '-910', '-910', 33.300, NULL, NULL, NULL, NULL, 'OVERFLOW_STORAGE', 'OVERFLOW_STORAGE_1', 'STORAGE', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.4202196165 4577985.968163903)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:41:21.802', NULL, '2024-08-23 10:41:21.841', 'postgres', 'postgres', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-910'), 1, 'INSERT: node "-910" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-910';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-910'), 33.000, 'UPDATE: node "-910" was updated');

DELETE FROM node WHERE node_id = '-910';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-910'), 0, 'DELETE: node "-910" was deleted');


-- node -> pump_station
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-911', '-911', '-911', 33.180, NULL, NULL, NULL, NULL, 'PUMP_STATION', 'PUMP_STATION', 'STORAGE', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.51718830236 4577985.511025811)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:41:38.316', NULL, '2024-08-23 10:41:38.353', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-911'), 1, 'INSERT: node "-911" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-911';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-911'), 33.000, 'UPDATE: node "-911" was updated');

DELETE FROM node WHERE node_id = '-911';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-911'), 0, 'DELETE: node "-911" was deleted');

-- node -> rect_manhole
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-912', '-912', '-912', 33.180, NULL, NULL, NULL, NULL, 'RECT_MANHOLE', 'R_MANHOLE_100', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.55874631065 4577985.095445728)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:41:49.366', NULL, '2024-08-23 10:41:49.401', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-912'), 1, 'INSERT: node "-912" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-912';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-912'), 33.000, 'UPDATE: node "-912" was updated');

DELETE FROM node WHERE node_id = '-912';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-912'), 0, 'DELETE: node "-912" was deleted');


-- node -> sandbox
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-913', '-913', '-913', 33.180, NULL, NULL, NULL, NULL, 'SANDBOX', 'SANDBOX_1', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.669567666 4577984.735276323)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:47:08.984', NULL, '2024-08-23 10:47:09.026', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-913'), 1, 'INSERT: node "-913" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-913';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-913'), 33.000, 'UPDATE: node "-913" was updated');

DELETE FROM node WHERE node_id = '-913';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-913'), 0, 'DELETE: node "-913" was deleted');


-- node -> sewer_storage
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-914', '-914', '-914', 33.180, NULL, NULL, NULL, NULL, 'SEWER_STORAGE', 'SEW_STORAGE-01', 'STORAGE', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.7526836826 4577984.347401579)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:47:17.399', NULL, '2024-08-23 10:47:17.444', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-914'), 1, 'INSERT: node "-914" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-914';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-914'), 33.000, 'UPDATE: node "-914" was updated');

DELETE FROM node WHERE node_id = '-914';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-914'), 0, 'DELETE: node "-914" was deleted');


-- node -> valve
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-915', '-915', '-915', 33.180, NULL, NULL, NULL, NULL, 'VALVE', 'VALVE-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.84965236863 4577983.917968828)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:47:30.005', NULL, '2024-08-23 10:47:30.040', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-915'), 1, 'INSERT: node "-915" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-915';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-915'), 33.000, 'UPDATE: node "-915" was updated');

DELETE FROM node WHERE node_id = '-915';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-915'), 0, 'DELETE: node "-915" was deleted');


-- node -> virtual_node
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-916', '-916', '-916', 33.180, NULL, NULL, NULL, NULL, 'VIRTUAL_NODE', 'VIR_NODE-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.98817906284 4577983.599357432)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:47:39.804', NULL, '2024-08-23 10:47:39.840', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-916'), 1, 'INSERT: node "-916" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-916';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-916'), 33.000, 'UPDATE: node "-916" was updated');

DELETE FROM node WHERE node_id = '-916';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-916'), 0, 'DELETE: node "-916" was deleted');


-- node -> weir
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-917', '-917', '-917', 33.180, NULL, NULL, NULL, NULL, 'WEIR', 'WEIR-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418458.1267057571 4577983.294598704)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:47:49.485', NULL, '2024-08-23 10:47:49.521', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-917'), 1, 'INSERT: node "-917" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-917';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-917'), 33.000, 'UPDATE: node "-917" was updated');

DELETE FROM node WHERE node_id = '-917';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-917'), 0, 'DELETE: node "-917" was deleted');


-- node -> wwtep
INSERT INTO node
(node_id, code, sys_code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-918', '-918', '-918', 33.180, NULL, NULL, NULL, NULL, 'WWTP', 'WWTP-01', 'JUNCTION', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418458.16826376534 4577982.948281969)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 2, NULL, 'NODE', '2024-08-23 10:47:58.950', NULL, '2024-08-23 10:47:58.985', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-918'), 1, 'INSERT: node "-918" was inserted');

UPDATE node SET top_elev = 33.000 WHERE node_id = '-918';
SELECT is((SELECT top_elev FROM node WHERE node_id = '-918'), 33.000, 'UPDATE: node "-918" was updated');

DELETE FROM node WHERE node_id = '-918';
SELECT is((SELECT count(*)::integer FROM node WHERE node_id = '-918'), 0, 'DELETE: node "-918" was deleted');

SELECT * FROM finish();

ROLLBACK;

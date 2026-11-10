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

SELECT plan(108);

-- IMPORTANT: In this test, we check for existence using the code, not the ID,
-- because we don't allow the user to change the code.
-- In test_node.sql, we test the `node` table and can check `node_id`,
-- but here we are testing the views.

-- node -> ve_node_chamber
INSERT INTO ve_node_chamber
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, sander_depth, max_volume, util_volume, inlet, bottom_channel, accessibility, "name", bottom_mat, slope, chamber_param_1, chamber_param_2, dwfzone_outfall, drainzone_outfall)
VALUES('-901', '-901', '-901', 33.220, NULL, 33.220, NULL, NULL, NULL, NULL, NULL, 'CHAMBER', 'CHAMBER', 'CHAMBER-01', NULL, 'STORAGE', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.7137334756 4577989.971585366)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:39:25.000', 'postgres', '2024-08-23 10:39:25.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'STORAGE', 0.000, 0.000, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, Null);
SELECT is((SELECT count(*)::integer FROM ve_node_chamber WHERE code = '-901'), 1, 'INSERT: ve_node_chamber "-901" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-901'), 1, 'INSERT: node "-901" was inserted');

UPDATE ve_node_chamber SET top_elev = 33.000 WHERE code = '-901';
SELECT is((SELECT top_elev FROM ve_node_chamber WHERE code = '-901'), 33.000, 'UPDATE: ve_node_chamber "-901" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-901'), 33.000, 'UPDATE: node "-901" was updated');

DELETE FROM ve_node_chamber WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_node_chamber WHERE code = '-901'), 0, 'DELETE: ve_node_chamber "-901" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-901'), 0, 'DELETE: node "-901" was deleted');


-- node -> ve_node_change
INSERT INTO ve_node_change
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, dwfzone_outfall, drainzone_outfall)
VALUES('-902', '-902', '-902', 33.220, NULL, 33.220, NULL, NULL, NULL, NULL, NULL, 'CHANGE', 'JUNCTION', 'CHANGE_1', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.8107021616 4577989.445183928)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:39:33.000', 'postgres', '2024-08-23 10:39:33.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_change WHERE code = '-902'), 1, 'INSERT: ve_node_change "-902" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-902'), 1, 'INSERT: node "-902" was inserted');

UPDATE ve_node_change SET top_elev = 33.000 WHERE code = '-902';
SELECT is((SELECT top_elev FROM ve_node_change WHERE code = '-902'), 33.000, 'UPDATE: ve_node_change "-902" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-902'), 33.000, 'UPDATE: node "-902" was updated');

DELETE FROM ve_node_change WHERE code = '-902';
SELECT is((SELECT count(*)::integer FROM ve_node_change WHERE code = '-902'), 0, 'DELETE: ve_node_change "-902" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-902'), 0, 'DELETE: node "-902" was deleted');


-- node -> ve_node_circ_manhole
INSERT INTO ve_node_circ_manhole
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, sander_depth, prot_surface, inlet, bottom_channel, accessibility, bottom_mat, cirmanhole_param_1, cirmanhole_param_2, dwfzone_outfall, drainzone_outfall)
VALUES('-903', '-903', '-903', 33.220, NULL, 33.220, NULL, NULL, NULL, NULL, NULL, 'CIRC_MANHOLE', 'MANHOLE', 'C_MANHOLE_100', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.90767084755 4577988.974193167)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:39:42.000', 'postgres', '2024-08-23 10:39:43.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', 0.000, 0.000, NULL, false, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_circ_manhole WHERE code = '-903'), 1, 'INSERT: ve_node_circ_manhole "-904" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-903'), 1, 'INSERT: node "-903" was inserted');

UPDATE ve_node_circ_manhole SET top_elev = 33.000 WHERE code = '-903';
SELECT is((SELECT top_elev FROM ve_node_circ_manhole WHERE code = '-903'), 33.000, 'UPDATE: ve_node_circ_manhole "-903" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-903'), 33.000, 'UPDATE: node "-903" was updated');

DELETE FROM ve_node_circ_manhole WHERE code = '-903';
SELECT is((SELECT count(*)::integer FROM ve_node_circ_manhole WHERE code = '-903'), 0, 'DELETE: ve_node_circ_manhole "-903" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-903'), 0, 'DELETE: node "-903" was deleted');


-- node -> ve_node_highpoint
INSERT INTO ve_node_highpoint
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, dwfzone_outfall, drainzone_outfall)
VALUES('-904', '-904', '-904', 33.220, NULL, 33.220, NULL, NULL, NULL, NULL, NULL, 'HIGHPOINT', 'JUNCTION', 'HIGH POINT-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.9907868641 4577988.489349738)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:39:50.000', 'postgres', '2024-08-23 10:39:50.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_highpoint WHERE code = '-904'), 1, 'INSERT: ve_node_highpoint "-904" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-904'), 1, 'INSERT: node "-904" was inserted');

UPDATE ve_node_highpoint SET top_elev = 33.000 WHERE code = '-904';
SELECT is((SELECT top_elev FROM ve_node_highpoint WHERE code = '-904'), 33.000, 'UPDATE: ve_node_highpoint "-904" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-904'), 33.000, 'UPDATE: node "-904" was updated');

DELETE FROM ve_node_highpoint WHERE code = '-904';
SELECT is((SELECT count(*)::integer FROM ve_node_highpoint WHERE code = '-904'), 0, 'DELETE: ve_node_highpoint "-904" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-904'), 0, 'DELETE: node "-904" was deleted');


-- node -> ve_node_jump
INSERT INTO ve_node_jump
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, sander_depth, prot_surface, accessibility, "name", dwfzone_outfall, drainzone_outfall)
VALUES('-905', '-905', '-905', 33.220, NULL, 33.220, NULL, NULL, NULL, NULL, NULL, 'JUMP', 'WJUMP', 'JUMP-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418456.9907868641 4577988.17073834)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:40:03.000', 'postgres', '2024-08-23 10:40:03.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', 0.000, 0.000, NULL, false, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_jump WHERE code = '-905'), 1, 'INSERT: ve_node_jump "-905" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-905'), 1, 'INSERT: node "-905" was inserted');

UPDATE ve_node_jump SET top_elev = 33.000 WHERE code = '-905';
SELECT is((SELECT top_elev FROM ve_node_jump WHERE code = '-905'), 33.000, 'UPDATE: ve_node_jump "-905" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-905'), 33.000, 'UPDATE: node "-905" was updated');

DELETE FROM ve_node_jump WHERE code = '-905';
SELECT is((SELECT count(*)::integer FROM ve_node_jump WHERE code = '-905'), 0, 'DELETE: ve_node_jump "-905" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-905'), 0, 'DELETE: node "-905" was deleted');


-- node -> ve_node_netelement
INSERT INTO ve_node_netelement
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, serial_number, dwfzone_outfall, drainzone_outfall)
VALUES('-906', '-906', '-906', 33.220, NULL, 33.220, NULL, NULL, NULL, NULL, NULL, 'NETELEMENT', 'NETELEMENT', 'NETELEMENT-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.12931355834 4577987.71360025)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:40:12.000', 'postgres', '2024-08-23 10:40:12.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_netelement WHERE code = '-906'), 1, 'INSERT: ve_node_netelement "-906" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-906'), 1, 'INSERT: node "-906" was inserted');

UPDATE ve_node_netelement SET top_elev = 33.000 WHERE code = '-906';
SELECT is((SELECT top_elev FROM ve_node_netelement WHERE code = '-906'), 33.000, 'UPDATE: ve_node_netelement "-906" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-906'), 33.000, 'UPDATE: node "-906" was updated');

DELETE FROM ve_node_netelement WHERE code = '-906';
SELECT is((SELECT count(*)::integer FROM ve_node_netelement WHERE code = '-906'), 0, 'DELETE: ve_node_netelement "-906" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-906'), 0, 'DELETE: node "-906" was deleted');


-- node -> ve_node_netgully
INSERT INTO ve_node_netgully
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, sander_depth, gullycat_id, units, groove, siphon, gullycat2_id, groove_height, groove_length, units_placement, dwfzone_outfall, drainzone_outfall)
VALUES('-907', '-907', '-907', 33.300, NULL, 33.300, NULL, NULL, NULL, NULL, NULL, 'NETGULLY', 'NETGULLY', 'NETGULLY-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.184724236 4577987.325725506)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:40:22.000', 'postgres', '2024-08-23 10:40:22.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', NULL, NULL, NULL, false, false, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_netgully WHERE code = '-907'), 1, 'INSERT: ve_node_netgully "-907" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-907'), 1, 'INSERT: node "-907" was inserted');

UPDATE ve_node_netgully SET top_elev = 33.000 WHERE code = '-907';
SELECT is((SELECT top_elev FROM ve_node_netgully WHERE code = '-907'), 33.000, 'UPDATE: ve_node_netgully "-907" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-907'), 33.000, 'UPDATE: node "-907" was updated');

DELETE FROM ve_node_netgully WHERE code = '-907';
SELECT is((SELECT count(*)::integer FROM ve_node_netgully WHERE code = '-907'), 0, 'DELETE: ve_node_netgully "-907" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-907'), 0, 'DELETE: node "-907" was deleted');


-- node -> ve_node_netinit
INSERT INTO ve_node_netinit
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, inlet, bottom_channel, accessibility, "name", sander_depth, dwfzone_outfall, drainzone_outfall)
VALUES('-908', '-908', '-908', 33.300, NULL, 33.300, NULL, NULL, NULL, NULL, NULL, 'NETINIT', 'NETINIT', 'NETINIT-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.2678402526 4577986.868587415)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:40:33.000', 'postgres', '2024-08-23 10:40:33.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', 0.000, 0.000, NULL, false, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_netinit WHERE code = '-908'), 1, 'INSERT: ve_node_netinit "-908" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-908'), 1, 'INSERT: node "-908" was inserted');

UPDATE ve_node_netinit SET top_elev = 33.000 WHERE code = '-908';
SELECT is((SELECT top_elev FROM ve_node_netinit WHERE code = '-908'), 33.000, 'UPDATE: ve_node_netinit "-908" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-908'), 33.000, 'UPDATE: node "-908" was updated');

DELETE FROM ve_node_netinit WHERE code = '-908';
SELECT is((SELECT count(*)::integer FROM ve_node_netinit WHERE code = '-908'), 0, 'DELETE: ve_node_netinit "-908" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-908'), 0, 'DELETE: node "-908" was deleted');


-- node -> ve_node_outfall
INSERT INTO ve_node_outfall
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, "name", dwfzone_outfall, drainzone_outfall)
VALUES('-909', '-909', '-909', 33.300, NULL, 33.300, NULL, NULL, NULL, NULL, NULL, 'OUTFALL', 'OUTFALL', 'OUTFALL-01', NULL, 'OUTFALL', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.36480893864 4577986.356038646)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:40:43.000', 'postgres', '2024-08-23 10:40:43.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'OUTFALL', NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_outfall WHERE code = '-909'), 1, 'INSERT: ve_node_outfall "-909" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-909'), 1, 'INSERT: node "-909" was inserted');

UPDATE ve_node_outfall SET top_elev = 33.000 WHERE code = '-909';
SELECT is((SELECT top_elev FROM ve_node_outfall WHERE code = '-909'), 33.000, 'UPDATE: ve_node_outfall "-909" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-909'), 33.000, 'UPDATE: node "-909" was updated');

DELETE FROM ve_node_outfall WHERE code = '-909';
SELECT is((SELECT count(*)::integer FROM ve_node_outfall WHERE code = '-909'), 0, 'DELETE: ve_node_outfall "-909" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-909'), 0, 'DELETE: node "-909" was deleted');


-- node -> ve_node_overflow_storage
INSERT INTO ve_node_overflow_storage
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, custom_area, max_volume, util_volume, min_height, accessibility, "name", dwfzone_outfall, drainzone_outfall)
VALUES('-910', '-910', '-910', 33.300, NULL, 33.300, NULL, NULL, NULL, NULL, NULL, 'OVERFLOW_STORAGE', 'STORAGE', 'OVERFLOW_STORAGE_1', NULL, 'STORAGE', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.4202196165 4577985.968163903)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:41:21.000', 'postgres', '2024-08-23 10:41:21.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'STORAGE', 0.000, 0.000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_overflow_storage WHERE code = '-910'), 1, 'INSERT: ve_node_overflow_storage "-910" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-910'), 1, 'INSERT: node "-910" was inserted');

UPDATE ve_node_overflow_storage SET top_elev = 33.000 WHERE code = '-910';
SELECT is((SELECT top_elev FROM ve_node_overflow_storage WHERE code = '-910'), 33.000, 'UPDATE: ve_node_overflow_storage "-910" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-910'), 33.000, 'UPDATE: node "-910" was updated');

DELETE FROM ve_node_overflow_storage WHERE code = '-910';
SELECT is((SELECT count(*)::integer FROM ve_node_overflow_storage WHERE code = '-910'), 0, 'DELETE: ve_node_overflow_storage "-910" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-910'), 0, 'DELETE: node "-910" was deleted');


-- node -> ve_node_pump_station
INSERT INTO ve_node_pump_station
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, sander_depth, max_volume, util_volume, inlet, bottom_channel, accessibility, "name", bottom_mat, slope, dwfzone_outfall, drainzone_outfall)
VALUES('-911', '-911', '-911', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'PUMP_STATION', 'CHAMBER', 'PUMP_STATION', NULL, 'STORAGE', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.51718830236 4577985.511025811)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:41:38.000', 'postgres', '2024-08-23 10:41:38.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'STORAGE', 0.000, 0.000, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_pump_station WHERE code = '-911'), 1, 'INSERT: ve_node_pump_station "-911" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-911'), 1, 'INSERT: node "-911" was inserted');

UPDATE ve_node_pump_station SET top_elev = 33.000 WHERE code = '-911';
SELECT is((SELECT top_elev FROM ve_node_pump_station WHERE code = '-911'), 33.000, 'UPDATE: ve_node_pump_station "-911" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-911'), 33.000, 'UPDATE: node "-911" was updated');

DELETE FROM ve_node_pump_station WHERE code = '-911';
SELECT is((SELECT count(*)::integer FROM ve_node_pump_station WHERE code = '-911'), 0, 'DELETE: ve_node_pump_station "-911" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-911'), 0, 'DELETE: node "-911" was deleted');


-- node -> ve_node_rect_manhole
INSERT INTO ve_node_rect_manhole
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, sander_depth, prot_surface, inlet, bottom_channel, accessibility, bottom_mat, recmanhole_param_1, recmanhole_param_2, dwfzone_outfall, drainzone_outfall)
VALUES('-912', '-912', '-912', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'RECT_MANHOLE', 'MANHOLE', 'R_MANHOLE_100', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.55874631065 4577985.095445728)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:41:49.000', 'postgres', '2024-08-23 10:41:49.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', 0.000, 0.000, NULL, false, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_rect_manhole WHERE code = '-912'), 1, 'INSERT: ve_node_rect_manhole "-912" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-912'), 1, 'INSERT: node "-912" was inserted');

UPDATE ve_node_rect_manhole SET top_elev = 33.000 WHERE code = '-912';
SELECT is((SELECT top_elev FROM ve_node_rect_manhole WHERE code = '-912'), 33.000, 'UPDATE: ve_node_rect_manhole "-912" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-912'), 33.000, 'UPDATE: node "-912" was updated');

DELETE FROM ve_node_rect_manhole WHERE code = '-912';
SELECT is((SELECT count(*)::integer FROM ve_node_rect_manhole WHERE code = '-912'), 0, 'DELETE: ve_node_rect_manhole "-912" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-912'), 0, 'DELETE: node "-912" was deleted');


-- node -> ve_node_sandbox
INSERT INTO ve_node_sandbox
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, sander_depth, prot_surface, inlet, bottom_channel, accessibility, bottom_mat, dwfzone_outfall, drainzone_outfall)
VALUES('-913', '-913', '-913', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'SANDBOX', 'MANHOLE', 'SANDBOX_1', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.669567666 4577984.735276323)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:47:08.000', 'postgres', '2024-08-23 10:47:09.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', 0.000, 0.000, NULL, false, NULL, false, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_sandbox WHERE code = '-913'), 1, 'INSERT: ve_node_sandbox "-913" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-913'), 1, 'INSERT: node "-913" was inserted');

UPDATE ve_node_sandbox SET top_elev = 33.000 WHERE code = '-913';
SELECT is((SELECT top_elev FROM ve_node_sandbox WHERE code = '-913'), 33.000, 'UPDATE: ve_node_sandbox "-913" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-913'), 33.000, 'UPDATE: node "-913" was updated');

DELETE FROM ve_node_sandbox WHERE code = '-913';
SELECT is((SELECT count(*)::integer FROM ve_node_sandbox WHERE code = '-913'), 0, 'DELETE: ve_node_sandbox "-913" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-913'), 0, 'DELETE: node "-913" was deleted');


-- node -> ve_node_sewer_storage
INSERT INTO ve_node_sewer_storage
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, custom_area, max_volume, util_volume, min_height, accessibility, "name", sewstorage_param_1, sewstorage_param_2, dwfzone_outfall, drainzone_outfall)
VALUES('-914', '-914', '-914', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'SEWER_STORAGE', 'STORAGE', 'SEW_STORAGE-01', NULL, 'STORAGE', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.7526836826 4577984.347401579)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:47:17.000', 'postgres', '2024-08-23 10:47:17.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'STORAGE', 0.000, 0.000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_sewer_storage WHERE code = '-914'), 1, 'INSERT: ve_node_sewer_storage "-914" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-914'), 1, 'INSERT: node "-914" was inserted');

UPDATE ve_node_sewer_storage SET top_elev = 33.000 WHERE code = '-914';
SELECT is((SELECT top_elev FROM ve_node_sewer_storage WHERE code = '-914'), 33.000, 'UPDATE: ve_node_sewer_storage "-914" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-914'), 33.000, 'UPDATE: node "-914" was updated');

DELETE FROM ve_node_sewer_storage WHERE code = '-914';
SELECT is((SELECT count(*)::integer FROM ve_node_sewer_storage WHERE code = '-914'), 0, 'DELETE: ve_node_sewer_storage "-914" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-914'), 0, 'DELETE: node "-914" was deleted');


-- node -> ve_node_valve
INSERT INTO ve_node_valve
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, "name", dwfzone_outfall, drainzone_outfall)
VALUES('-915', '-915', '-915', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'VALVE', 'VALVE', 'VALVE-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.84965236863 4577983.917968828)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:47:30.000', 'postgres', '2024-08-23 10:47:30.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_valve WHERE code = '-915'), 1, 'INSERT: ve_node_valve "-915" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-915'), 1, 'INSERT: node "-915" was inserted');

UPDATE ve_node_valve SET top_elev = 33.000 WHERE code = '-915';
SELECT is((SELECT top_elev FROM ve_node_valve WHERE code = '-915'), 33.000, 'UPDATE: ve_node_valve "-915" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-915'), 33.000, 'UPDATE: node "-915" was updated');

DELETE FROM ve_node_valve WHERE code = '-915';
SELECT is((SELECT count(*)::integer FROM ve_node_valve WHERE code = '-915'), 0, 'DELETE: ve_node_valve "-915" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-915'), 0, 'DELETE: node "-915" was deleted');


-- node -> ve_node_virtual_node
INSERT INTO ve_node_virtual_node
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, dwfzone_outfall, drainzone_outfall)
VALUES('-916', '-916', '-916', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'VIRTUAL_NODE', 'JUNCTION', 'VIR_NODE-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418457.98817906284 4577983.599357432)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:47:39.000', 'postgres', '2024-08-23 10:47:39.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_virtual_node WHERE code = '-916'), 1, 'INSERT: ve_node_virtual_node "-916" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-916'), 1, 'INSERT: node "-916" was inserted');

UPDATE ve_node_virtual_node SET top_elev = 33.000 WHERE code = '-916';
SELECT is((SELECT top_elev FROM ve_node_virtual_node WHERE code = '-916'), 33.000, 'UPDATE: ve_node_virtual_node "-916" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-916'), 33.000, 'UPDATE: node "-916" was updated');

DELETE FROM ve_node_virtual_node WHERE code = '-916';
SELECT is((SELECT count(*)::integer FROM ve_node_virtual_node WHERE code = '-916'), 0, 'DELETE: ve_node_virtual_node "-916" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-916'), 0, 'DELETE: node "-916" was deleted');


-- node -> ve_node_weir
INSERT INTO ve_node_weir
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, length, width, sander_depth, max_volume, util_volume, inlet, bottom_channel, accessibility, "name", bottom_mat, slope, weir_param_1, weir_param_2, dwfzone_outfall, drainzone_outfall)
VALUES('-917', '-917', '-917', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'WEIR', 'CHAMBER', 'WEIR-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418458.1267057571 4577983.294598704)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:47:49.000', 'postgres', '2024-08-23 10:47:49.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', 0.000, 0.000, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_weir WHERE code = '-917'), 1, 'INSERT: ve_node_weir "-917" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-917'), 1, 'INSERT: node "-917" was inserted');

UPDATE ve_node_weir SET top_elev = 33.000 WHERE code = '-917';
SELECT is((SELECT top_elev FROM ve_node_weir WHERE code = '-917'), 33.000, 'UPDATE: ve_node_weir "-917" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-917'), 33.000, 'UPDATE: node "-917" was updated');

DELETE FROM ve_node_weir WHERE code = '-917';
SELECT is((SELECT count(*)::integer FROM ve_node_weir WHERE code = '-917'), 0, 'DELETE: ve_node_weir "-917" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-917'), 0, 'DELETE: node "-917" was deleted');


-- node -> ve_node_wwtp
INSERT INTO ve_node_wwtp
(node_id, code, sys_code, top_elev, custom_top_elev, sys_top_elev, ymax, sys_ymax, elev, custom_elev, sys_elev, node_type, sys_type, nodecat_id, matcat_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, drainzone_id, annotation, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, the_geom, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, xyz_date, unconnected, num_value, created_at, created_by, updated_at, updated_by, workcat_id_plan, asset_id, parent_id, arc_id, is_operative, adate, adescript, placement_type, inp_type, "name", wwtp_type, treatment_type, dwfzone_outfall, drainzone_outfall)
VALUES('-918', '-918', '-918', 33.180, NULL, 33.180, NULL, NULL, NULL, NULL, NULL, 'WWTP', 'WWTP', 'WWTP-01', NULL, 'JUNCTION', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 2, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (418458.16826376534 4577982.948281969)'::public.geometry, NULL, NULL, NULL, NULL, true, true, false, NULL, false, NULL, '2024-08-23 10:47:58.000', 'postgres', '2024-08-23 10:47:58.000', 'postgres', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 'JUNCTION', NULL, 0, 0, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_node_wwtp WHERE code = '-918'), 1, 'INSERT: ve_node_wwtp "-918" was inserted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-918'), 1, 'INSERT: node "-918" was inserted');

UPDATE ve_node_wwtp SET top_elev = 33.000 WHERE code = '-918';
SELECT is((SELECT top_elev FROM ve_node_wwtp WHERE code = '-918'), 33.000, 'UPDATE: ve_node_wwtp "-918" was updated');
SELECT is((SELECT top_elev FROM node WHERE code = '-918'), 33.000, 'UPDATE: node "-918" was updated');

DELETE FROM ve_node_wwtp WHERE code = '-918';
SELECT is((SELECT count(*)::integer FROM ve_node_wwtp WHERE code = '-918'), 0, 'DELETE: ve_node_wwtp "-918" was deleted');
SELECT is((SELECT count(*)::integer FROM node WHERE code = '-918'), 0, 'DELETE: node "-918" was deleted');


SELECT * FROM finish();

ROLLBACK;

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

-- Plan for 1 test
SELECT plan(1);

-- initial data is prepared before proceeding with the test
INSERT INTO node (node_id, code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id, updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-999', '-999', 43.810, NULL, NULL, NULL, NULL, 'CHAMBER', 'CHAMBER-01', 'STORAGE', (SELECT sector_id FROM sector WHERE code = '1' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '1' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (419178.51934327977 4576785.174134543)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 1, NULL, 'NODE', '2024-08-21 15:27:00.827', NULL, '2024-08-21 15:19:33.000', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO node (node_id, code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id, updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-998', '-998', 43.810, NULL, NULL, NULL, NULL, 'CHAMBER', 'CHAMBER-01', 'STORAGE', (SELECT sector_id FROM sector WHERE code = '1' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '1' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (419179.1158701493 4576785.631744197)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 1, NULL, 'NODE', '2024-08-21 15:27:00.827', NULL, '2024-08-21 15:19:39.000', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO node (node_id, code, top_elev, ymax, elev, custom_top_elev, custom_elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, rotation, link, verified, the_geom, label_x, label_y, label_rotation, publish, inventory, xyz_date, uncertain, unconnected, expl_id, num_value, feature_type, created_at, arc_id, updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, parent_id, adate, adescript, hemisphere, placement_type)
VALUES('-997', '-997', 43.810, NULL, NULL, NULL, NULL, 'CHAMBER', 'CHAMBER-01', 'STORAGE', (SELECT sector_id FROM sector WHERE code = '1' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '1' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 'SRID=25831;POINT (419178.790046 4576785.38173)'::public.geometry, NULL, NULL, NULL, true, true, NULL, false, false, 1, NULL, 'NODE', '2024-08-21 15:27:00.827', NULL, '2024-08-21 15:19:43.000', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO ve_arc_conduit (arc_id, code, node_1, nodetype_1, y1, elev1, custom_elev1, sys_elev1, sys_y1, r1, z1, node_2, nodetype_2, y2, elev2, custom_elev2, sys_elev2, sys_y2, r2, z2, slope, arc_type, sys_type, arccat_id, matcat_id, cat_shape, cat_geom1, cat_geom2, cat_width, cat_area, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, macrosector_id, annotation, gis_length, custom_length, inverted_slope, observ, "comment", omzone_id, macroomzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, link, verified, "label", label_x, label_y, label_rotation, publish, inventory, uncertain, num_value, asset_id, pavcat_id, parent_id, is_operative, adate, adescript, visitability, created_at, created_by, updated_at, updated_by, the_geom, inp_type, bottom_mat)
VALUES('-996', '-996', (SELECT node_id FROM node WHERE code = '-998'), 'CHAMBER', NULL, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT node_id FROM node WHERE code = '-999'), 'CHAMBER', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'CONDUIT', 'CONDUIT', 'CC100', NULL, 'CIRCULAR', 1.0000, 0.0000, 1.30, 0.7854, 'CONDUIT', 1, 2, 1, 1, (SELECT sector_id FROM sector WHERE code = '1' AND sector_id > 0), 1, NULL, 0.75, NULL, false, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '1' AND omzone_id > 0), NULL, 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-21', NULL, NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, true, true, false, NULL, NULL, 'Asphalt', NULL, true, NULL, NULL, 1, '2024-08-21 16:20:55.000', 'postgres', '2024-08-21 16:20:55.000', 'postgres', 'SRID=25831;LINESTRING (419179.1158701493 4576785.631744197, 419178.51934327977 4576785.174134543)'::public.geometry, 'CONDUIT', NULL);

UPDATE node SET the_geom = ST_GeomFromText('POINT(419178.790046 4576785.381730)', 25831) WHERE code = '-997';

-- Create roles for testing
CREATE USER plan_user;
GRANT role_plan to plan_user;

CREATE USER epa_user;
GRANT role_epa to epa_user;

CREATE USER edit_user;
GRANT role_edit to edit_user;

CREATE USER om_user;
GRANT role_om to om_user;

CREATE USER basic_user;
GRANT role_basic to basic_user;

-- Extract and test the "status" field from the function's JSON response
SELECT is (
    (gw_fct_setarcdivide($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["-997"]}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setarcdivide returns status "Accepted"'
);

-- Finish the test
SELECT finish();

ROLLBACK;
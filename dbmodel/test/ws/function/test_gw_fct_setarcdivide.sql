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


INSERT INTO node (node_id, code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state, state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-901', '-901', 43.2300, NULL, 'SHTFF-VALVE160-PN16', 'SHORTPIPE', (SELECT sector_id FROM sector WHERE code = '3' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '1' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (419189.1684562919 4576779.026603929)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 1, NULL, 'NODE', '2024-08-21 17:42:15.426', '2024-08-21 17:42:15.469', 'postgres', 'postgres', NULL, NULL, 28.520, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO node (node_id, code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state, state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-902', '-902', 43.2300, NULL, 'SHTFF-VALVE160-PN16', 'SHORTPIPE', (SELECT sector_id FROM sector WHERE code = '3' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '1' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (419190.45461029344 4576779.998060674)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 1, NULL, 'NODE', '2024-08-21 17:43:29.356', '2024-08-21 17:43:29.401', 'postgres', 'postgres', NULL, NULL, 28.520, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO node (node_id, code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state, state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-903', '-903', 43.2300, NULL, 'SHTFF-VALVE160-PN16', 'SHORTPIPE', (SELECT sector_id FROM sector WHERE code = '3' AND sector_id > 0), NULL, NULL, 1, 2, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '1' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (419190.2220079739 4576779.0129214395)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 1, NULL, 'NODE', '2024-08-21 17:44:05.610', '2024-08-21 17:44:05.651', 'postgres', 'postgres', NULL, NULL, 28.520, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO ve_arc_varc (arc_id, code, node_1, nodetype_1, elevation1, depth1, staticpressure1, node_2, nodetype_2, staticpressure2, elevation2, depth2, "depth",
arccat_id, arc_type, sys_type, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id,
presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, annotation, observ, "comment",
gis_length, custom_length, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan,
builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id,
province_id, descript, link, verified, "label", label_x, label_y, label_rotation, label_quadrant, publish, inventory, num_value, adate, adescript,
dma_style, presszone_style, asset_id, pavcat_id, om_state, conserv_state, parent_id, is_operative, brand_id, model_id, serial_number, minsector_id,
flow_max, flow_min, flow_avg, vel_max, vel_min, vel_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-904', '-904', '-902', 'SHUTOFF_VALVE', 51.5000, 0.0000, 0.000, '-901', 'SHUTOFF_VALVE', 3.500, 81.5000, 0.0000, 0.00, 'VIRTUAL', 'VARC', 'VARC', 'PE-HD', NULL, NULL, 999.00000, 'PIPE', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '4' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '5' AND presszone_id > 0), NULL, 119.69, (SELECT dma_id FROM dma WHERE code = '5' AND dma_id > 0), 'source-2', NULL, (SELECT dqa_id FROM dqa WHERE code = '4' AND dqa_id > 0), NULL, NULL, NULL, NULL, NULL, 10.05, NULL, 'soil1', 'St. Function', 'St. Category', 'St. Fluid', 'St. Location', 'work3', NULL, NULL, '1994-07-24', NULL, 'owner1', 2, '08830', 2, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, 'https://www.giswater.org', '0', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, '255,255,204', '254,217,166', NULL, 'Asphalt', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, '2020-08-13 09:15:52.000', 'postgres', '2025-01-21 17:20:21.000', 'postgres', 'SRID=25831;LINESTRING (419190.45461029344 4576779.998060674, 419189.1684562919 4576779.026603929)'::public.geometry, 'PIPE');

UPDATE node SET the_geom = ST_GeomFromText('POINT(419189.81153329264 4576779.512332302)', 25831) WHERE node_id = '-903';

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
    "feature":{"id":["-903"]}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setarcdivide returns status "Accepted"'
);

-- Finish the test
SELECT finish();

ROLLBACK;
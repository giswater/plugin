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

SELECT plan(4);

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

SELECT is(
    (gw_fct_scada_graph_build($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831},
    "form":{}, "feature":{}, "data":{"parameters":{"object_1":1109}}}$$)::JSON)->>'status',
    'Failed',
    'Check if gw_fct_scada_graph_build without object_2 returns status "Failed"'
);

SELECT is(
    (gw_fct_scada_graph_build($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831},
    "form":{}, "feature":{}, "data":{"parameters":{"object_1":1109, "object_2":1109}}}$$)::JSON)->>'status',
    'Failed',
    'Check if gw_fct_scada_graph_build with equal object_1/object_2 returns status "Failed"'
);

SELECT col_is_pk(
    'om_scada_graph',
    ARRAY['node_1', 'node_2'],
    'Table om_scada_graph should have primary key on node_1, node_2'
);

UPDATE config_param_system SET "value" = 'TRUE' WHERE "parameter"='edit_arc_enable nodes_update';

INSERT INTO node (node_id, code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state, state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-901', '-901', 43.2300, NULL, 'SHTFF-VALVE160-PN16', 'SHORTPIPE', 3, NULL, NULL, 1, 2, NULL, NULL, NULL, 1, '3', 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (419189.1684562919 4576779.026603929)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 1, NULL, 'NODE', '2024-08-21 17:42:15.426', '2024-08-21 17:42:15.469', 'postgres', 'postgres', NULL, NULL, 28.520, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO node (node_id, code, top_elev, "depth", nodecat_id, epa_type, sector_id, arc_id, parent_id, state, state_type, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, hemisphere, expl_id, num_value, feature_type, created_at, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, om_state, conserv_state, access_type, placement_type, brand_id, model_id, serial_number)
VALUES('-902', '-902', 43.2300, NULL, 'SHTFF-VALVE160-PN16', 'SHORTPIPE', 3, NULL, NULL, 1, 2, NULL, NULL, NULL, 1, '3', 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-21', NULL, 'owner1', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (419190.45461029344 4576779.998060674)'::public.geometry, NULL, NULL, NULL, true, true, NULL, 1, NULL, 'NODE', '2024-08-21 17:43:29.356', '2024-08-21 17:43:29.401', 'postgres', 'postgres', NULL, NULL, 28.520, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO ve_arc_varc (arc_id, code, node_1, node_2,
arccat_id, arc_type, sys_type, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id,
presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, annotation, observ, "comment",
gis_length, custom_length, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan,
builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id,
province_id, descript, link, verified, "label", label_x, label_y, label_rotation, label_quadrant, publish, inventory, num_value, adate, adescript,
dma_style, presszone_style, asset_id, pavcat_id, om_state, conserv_state, parent_id, is_operative, brand_id, model_id, serial_number, minsector_id,
flow_max, flow_min, flow_avg, vel_max, vel_min, vel_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-904', '-904', '-902', '-901', 'VIRTUAL', 'VARC', 'VARC', 'PE-HD',
NULL, NULL, 999.00000, 'PIPE', 1, 2, 2, 1, 4, 5, NULL, 119.69, 5, 'source-2', NULL, 4, NULL, NULL, NULL, NULL, NULL, 10.05,
NULL, 'soil1', 'St. Function', 'St. Category', 'St. Fluid', 'St. Location', 'work3', NULL, NULL, '1994-07-24', NULL, 'owner1', 2, '08830', 2,
NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, 'https://www.giswater.org', '0', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL,
'255,255,204', '254,217,166', NULL, 'Asphalt', NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL,
'2020-08-13 09:15:52.000', 'postgres', '2025-01-21 17:20:21.000', 'postgres', 'SRID=25831;LINESTRING (419190.45461029344 4576779.998060674, 419189.1684562919 4576779.026603929)'::public.geometry, 'PIPE');

-- Must be network-connected: BEFORE trigger runs pgr_dijkstra and rejects phantom IDs.
INSERT INTO om_scada_graph (node_1, node_2, expl_id, attrib)
VALUES (-902, -901, ARRAY[1], '{"keep":"first"}');

SELECT throws_matching(
    $$INSERT INTO om_scada_graph (node_1, node_2) VALUES (-902, -901)$$,
    'already exists',
    'Check if om_scada_graph rejects duplicate node_1/node_2'
);

SELECT finish();

ROLLBACK;

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

SELECT plan(3);

-- prepare test
INSERT INTO connec (connec_id, code, sys_code, top_elev, "depth", feature_type, conneccat_id, customer_code, connec_length, epa_type, state, state_type, arc_id, expl_id, muni_id, sector_id, supplyzone_id, presszone_id, dma_id, dqa_id, omzone_id, crmzone_id, minsector_id, soilcat_id, function_type, category_type, location_type, fluid_type, n_hydrometer, n_inhabitants, staticpressure, descript, annotation, observ, "comment", link, num_value, district_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, block_code, plot_id, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, pjoint_id, pjoint_type, om_state, conserv_state, accessibility, access_type, placement_type, priority, brand_id, model_id, serial_number, asset_id, adate, adescript, verified, datasource, label_x, label_y, label_rotation, rotation, label_quadrant, inventory, publish, lock_level, expl_visibility, created_at, created_by, updated_at, updated_by, the_geom)
VALUES(-901, '-901', NULL, 45.0300, NULL, 'CONNEC', 'FACADE-CABINET', '-901', NULL, 'JUNCTION', 1, 2, 113909, 1, 1, 3, 0, 1, 1, 1, 0, NULL, NULL, 'soil1', NULL, NULL, NULL, 'St. Fluid', NULL, NULL, 58.820, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'work1', NULL, NULL, '2025-07-02', NULL, NULL, 113909, 'ARC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, 'L', NULL, 51.688, 51.688, NULL, NULL, true, NULL, NULL, '2025-07-02 09:32:53.986', 'postgres', NULL, NULL, 'SRID=25831;POINT (419208.07353503513 4576833.064586339)'::public.geometry);

INSERT INTO connec (connec_id, code, sys_code, top_elev, "depth", feature_type, conneccat_id, customer_code, connec_length, epa_type, state, state_type, arc_id, expl_id, muni_id, sector_id, supplyzone_id, presszone_id, dma_id, dqa_id, omzone_id, crmzone_id, minsector_id, soilcat_id, function_type, category_type, location_type, fluid_type, n_hydrometer, n_inhabitants, staticpressure, descript, annotation, observ, "comment", link, num_value, district_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, block_code, plot_id, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, pjoint_id, pjoint_type, om_state, conserv_state, accessibility, access_type, placement_type, priority, brand_id, model_id, serial_number, asset_id, adate, adescript, verified, datasource, label_x, label_y, label_rotation, rotation, label_quadrant, inventory, publish, lock_level, expl_visibility, created_at, created_by, updated_at, updated_by, the_geom)
VALUES(-902, '-902', NULL, 40.0600, NULL, 'CONNEC', 'FACADE-CABINET', '-902', NULL, 'JUNCTION', 1, 2, NULL, 1, 1, 3, 0, 1, 1, NULL, 0, NULL, NULL, 'soil1', NULL, NULL, NULL, NULL, NULL, NULL, 63.790, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'work1', NULL, NULL, '2025-07-02', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, '2025-07-02 09:37:35.798', 'postgres', NULL, NULL, 'SRID=25831;POINT (419261.38522399316 4576820.8300856585)'::public.geometry);

INSERT INTO connec (connec_id, code, sys_code, top_elev, "depth", feature_type, conneccat_id, customer_code, connec_length, epa_type, state, state_type, arc_id, expl_id, muni_id, sector_id, supplyzone_id, presszone_id, dma_id, dqa_id, omzone_id, crmzone_id, minsector_id, soilcat_id, function_type, category_type, location_type, fluid_type, n_hydrometer, n_inhabitants, staticpressure, descript, annotation, observ, "comment", link, num_value, district_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, block_code, plot_id, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, pjoint_id, pjoint_type, om_state, conserv_state, accessibility, access_type, placement_type, priority, brand_id, model_id, serial_number, asset_id, adate, adescript, verified, datasource, label_x, label_y, label_rotation, rotation, label_quadrant, inventory, publish, lock_level, expl_visibility, created_at, created_by, updated_at, updated_by, the_geom)
VALUES(-903, '-903', NULL, 40.9000, NULL, 'CONNEC', 'DRINKING-FOUNTAIN', '-903', NULL, 'JUNCTION', 1, 2, NULL, 1, 1, 3, 0, 1, 1, NULL, 0, NULL, NULL, 'soil1', NULL, NULL, NULL, NULL, NULL, NULL, 62.950, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'work1', NULL, NULL, '2025-07-02', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, '2025-07-02 09:37:56.659', 'postgres', NULL, NULL, 'SRID=25831;POINT (419264.6950406025 4576823.78527906)'::public.geometry);

INSERT INTO connec (connec_id, code, sys_code, top_elev, "depth", feature_type, conneccat_id, customer_code, connec_length, epa_type, state, state_type, arc_id, expl_id, muni_id, sector_id, supplyzone_id, presszone_id, dma_id, dqa_id, omzone_id, crmzone_id, minsector_id, soilcat_id, function_type, category_type, location_type, fluid_type, n_hydrometer, n_inhabitants, staticpressure, descript, annotation, observ, "comment", link, num_value, district_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, block_code, plot_id, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, pjoint_id, pjoint_type, om_state, conserv_state, accessibility, access_type, placement_type, priority, brand_id, model_id, serial_number, asset_id, adate, adescript, verified, datasource, label_x, label_y, label_rotation, rotation, label_quadrant, inventory, publish, lock_level, expl_visibility, created_at, created_by, updated_at, updated_by, the_geom)
VALUES(-904, '-904', NULL, 39.9200, NULL, 'CONNEC', 'ORNAMENTAL-FOUNTAIN', '-904', NULL, 'JUNCTION', 1, 2, NULL, 1, 1, 3, 0, 1, 1, NULL, 0, NULL, NULL, 'soil1', NULL, NULL, NULL, NULL, NULL, NULL, 63.930, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'work1', NULL, NULL, '2025-07-02', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, '2025-07-02 09:38:09.483', 'postgres', NULL, NULL, 'SRID=25831;POINT (419267.53202626767 4576826.267641516)'::public.geometry);

UPDATE connec SET expl_visibility = ARRAY[-901]::smallint[] WHERE connec_id = -901;

SELECT is(
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "version":"4.0.002", "infoType":1, "epsg":25831},
    "form":{}, "feature":{"id":"[-901]"}, "data":{"filterFields":{}, "pageInfo":{},
    "feature_type": "CONNEC", "pipeDiameter": "100", "maxDistance": "100", "linkcatId": "PVC25-PN16"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setlinktonetwork (wjoin) returns status "Accepted"'
);

SELECT is(
    (SELECT expl_visibility FROM link WHERE feature_id = -901 AND state > 0 ORDER BY link_id DESC LIMIT 1),
    ARRAY[-901]::smallint[],
    'New/reconnected link inherits expl_visibility from connec'
);

SELECT is(
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "version":"4.0.002", "infoType":1, "epsg":25831},
    "form":{}, "feature":{"id":"[-902, -903, -904]"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":
    "CONNEC", "pipeDiameter": "150", "maxDistance": "100", "linkcatId": "VIRTUAL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setlinktonetwork (wjoin, fountain, greentap) returns status "Accepted"'
);

-- Finish the test
SELECT finish();

ROLLBACK;
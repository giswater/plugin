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

SELECT plan(9);

-- connec -> fountain
INSERT INTO connec
(connec_id, code, sys_code, top_elev, "depth", conneccat_id, sector_id, customer_code, state, state_type, arc_id, connec_length, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, epa_type, om_state, conserv_state, priority, access_type, placement_type, crmzone_id, plot_id, brand_id, model_id, serial_number, n_hydrometer)
VALUES('-901', '-901', '-901', 32.9300, NULL, 'DRINKING-FOUNTAIN', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), '-901', 1, 2, NULL, NULL, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '6' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418470.98314069357 4577984.057125445)'::public.geometry, NULL, NULL, NULL, true, true, 2, NULL, 'CONNEC', '2024-08-22 16:38:55.382', NULL, NULL, '2024-08-22 16:38:55.455', 'postgres', 'postgres', NULL, NULL, 52.070, 1, NULL, NULL, NULL, NULL, NULL, 'JUNCTION', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-901'), 1, 'INSERT: connec:fountain "-901" was inserted');

UPDATE connec SET top_elev = 33.0000 WHERE connec_id = '-901';
SELECT is((SELECT top_elev FROM connec WHERE connec_id = '-901'), 33.0000, 'UPDATE: connec:fountain "-901" was updated');

DELETE FROM connec WHERE connec_id = '-901';
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-901'), 0, 'DELETE: connec:fountain "-901" was deleted');


-- connec -> greentap
INSERT INTO connec
(connec_id, code, sys_code, top_elev, "depth", conneccat_id, sector_id, customer_code, state, state_type, arc_id, connec_length, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, epa_type, om_state, conserv_state, priority, access_type, placement_type, crmzone_id, plot_id, brand_id, model_id, serial_number, n_hydrometer)
VALUES('-902', '-902', '-902', 32.9300, NULL, 'ORNAMENTAL-FOUNTAIN', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), '-902', 1, 2, NULL, NULL, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '6' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418471.1473305661 4577983.030938743)'::public.geometry, NULL, NULL, NULL, true, true, 2, NULL, 'CONNEC', '2024-08-22 16:39:07.824', NULL, NULL, '2024-08-22 16:39:07.860', 'postgres', 'postgres', NULL, NULL, 52.070, 1, NULL, NULL, NULL, NULL, NULL, 'JUNCTION', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-902'), 1, 'INSERT: connec:greentap "-902" was inserted');

UPDATE connec SET top_elev = 33.0000 WHERE connec_id = '-902';
SELECT is((SELECT top_elev FROM connec WHERE connec_id = '-902'), 33.0000, 'UPDATE: connec:greentap "-902" was updated');

DELETE FROM connec WHERE connec_id = '-902';
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-902'), 0, 'DELETE: connec:greentap "-902" was deleted');


-- connec -> wjoin
INSERT INTO connec
(connec_id, code, sys_code, top_elev, "depth", conneccat_id, sector_id, customer_code, state, state_type, arc_id, connec_length, annotation, observ, "comment", dma_id, presszone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id, updated_at, updated_by, created_by, minsector_id, dqa_id, staticpressure, district_id, adate, adescript, accessibility, workcat_id_plan, asset_id, epa_type, om_state, conserv_state, priority, access_type, placement_type, crmzone_id, plot_id, brand_id, model_id, serial_number, n_hydrometer)
VALUES('-903', '-903', '-903', 33.0300, NULL, 'FACADE-CABINET', (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0), '-903', 1, 2, NULL, NULL, NULL, NULL, NULL, (SELECT dma_id FROM dma WHERE code = '3' AND dma_id > 0), (SELECT presszone_id FROM presszone WHERE code = '6' AND presszone_id > 0), 'soil1', NULL, NULL, NULL, NULL, 'work1', NULL, '2024-08-22', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', NULL, 'SRID=25831;POINT (418471.2704729705 4577982.127894443)'::public.geometry, NULL, NULL, NULL, true, true, 2, NULL, 'CONNEC', '2024-08-22 16:39:19.160', NULL, NULL, '2024-08-22 16:39:19.197', 'postgres', 'postgres', NULL, NULL, 51.970, 1, NULL, NULL, NULL, NULL, NULL, 'JUNCTION', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-903'), 1, 'INSERT: connec:wjoin "-903" was inserted');

UPDATE connec SET top_elev = 33.0000 WHERE connec_id = '-903';
SELECT is((SELECT top_elev FROM connec WHERE connec_id = '-903'), 33.0000, 'UPDATE: connec:wjoin "-903" was updated');

DELETE FROM connec WHERE connec_id = '-903';
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-903'), 0, 'DELETE: connec:wjoin "-903" was deleted');


SELECT * FROM finish();

ROLLBACK;

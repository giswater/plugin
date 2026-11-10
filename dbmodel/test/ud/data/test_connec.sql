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

SELECT plan(6);

-- connec -> connec
INSERT INTO connec
(connec_id, code, sys_code, top_elev, y1, y2, connec_type, conneccat_id, sector_id, customer_code, demand, state, state_type, connec_depth, connec_length, arc_id, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, accessibility, diagonal, publish, inventory, uncertain, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, adate, adescript, plot_id, placement_type, n_hydrometer)
VALUES('-901', '-901', '-901', 33.2200, NULL, NULL, 'CJOIN', 'INSPECTION-CHAMBER', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), '-901', NULL, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1', NULL, 'SRID=25831;POINT (418456.45053275774 4577991.751653385)'::public.geometry, NULL, NULL, NULL, NULL, NULL, true, true, false, 2, NULL, 'CONNEC', '2024-08-23 09:38:22.082', NULL, NULL, NULL, NULL, 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-901'), 1, 'INSERT: connec:connec "-901" was inserted');

UPDATE connec SET top_elev = 33.0000 WHERE connec_id = '-901';
SELECT is((SELECT top_elev FROM connec WHERE connec_id = '-901'), 33.0000, 'UPDATE: connec:connec "-901" was updated');

DELETE FROM connec WHERE connec_id = '-901';
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-901'), 0, 'DELETE: connec:connec "-901" was deleted');


-- connec -> vconnec
INSERT INTO connec
(connec_id, code, sys_code, top_elev, y1, y2, connec_type, conneccat_id, sector_id, customer_code, demand, state, state_type, connec_depth, connec_length, arc_id, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, accessibility, diagonal, publish, inventory, uncertain, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id,  updated_at, updated_by, created_by, matcat_id, district_id, workcat_id_plan, asset_id, adate, adescript, plot_id, placement_type, n_hydrometer)
VALUES('-902', '-902', '-902', 33.0900, NULL, NULL, 'VCONNEC', 'VIRTUAL', (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), '-902', NULL, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1', NULL, 'SRID=25831;POINT (418458.1128530885 4577992.084117452)'::public.geometry, NULL, NULL, NULL, NULL, NULL, true, true, false, 2, NULL, 'CONNEC', '2024-08-23 09:38:37.820', NULL, NULL, NULL, NULL, 'postgres', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-902'), 1, 'INSERT: connec:vconnec "-902" was inserted');

UPDATE connec SET top_elev = 33.0000 WHERE connec_id = '-902';
SELECT is((SELECT top_elev FROM connec WHERE connec_id = '-902'), 33.0000, 'UPDATE: connec:vconnec "-902" was updated');

DELETE FROM connec WHERE connec_id = '-902';
SELECT is((SELECT count(*)::integer FROM connec WHERE connec_id = '-902'), 0, 'DELETE: connec:vconnec "-902" was deleted');


SELECT * FROM finish();

ROLLBACK;

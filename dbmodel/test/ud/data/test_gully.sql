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

-- gully -> ve_gully_gully
INSERT INTO gully
(gully_id, code, top_elev, ymax, sandbox, matcat_id, gully_type, gullycat_id, units, groove, siphon, _connec_arccat_id, connec_length, connec_depth, arc_id, "_pol_id_", sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, uncertain, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id,  updated_at, updated_by, created_by, district_id, workcat_id_plan, asset_id, _connec_matcat_id, connec_y2, epa_type, groove_height, groove_length, units_placement, adate, adescript, siphon_type, odorflap, placement_type)
VALUES('-901', '-901', 33.0000, NULL, NULL, 'N/I', 'GINLET', 'SGRT3', 1.00, false, false, 'DIRECT-CONNECTION', NULL, NULL, NULL, NULL, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 350.443, 'SRID=25831;POINT (418460.4262488815 4577992.6105188895)'::public.geometry, NULL, NULL, NULL, true, true, false, 2, NULL, 'GULLY', '2024-08-23 09:44:56.527', NULL, NULL, '2024-08-23 09:44:56.614', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, 'GULLY', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM gully WHERE gully_id = '-901'), 1, 'INSERT: gully "-901" was inserted');

UPDATE gully SET top_elev = 33.0000 WHERE gully_id = '-901';
SELECT is((SELECT top_elev FROM gully WHERE gully_id = '-901'), 33.0000, 'UPDATE: gully "-901" was updated');

DELETE FROM gully WHERE gully_id = '-901';
SELECT is((SELECT count(*)::integer FROM gully WHERE gully_id = '-901'), 0, 'DELETE: gully "-901" was deleted');


-- gully -> ve_gully_pgully
INSERT INTO gully
(gully_id, code, top_elev, ymax, sandbox, matcat_id, gully_type, gullycat_id, units, groove, siphon, _connec_arccat_id, connec_length, connec_depth, arc_id, "_pol_id_", sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, uncertain, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id,  updated_at, updated_by, created_by, district_id, workcat_id_plan, asset_id, _connec_matcat_id, connec_y2, epa_type, groove_height, groove_length, units_placement, adate, adescript, siphon_type, odorflap, placement_type)
VALUES('-902', '-902', 33.0000, NULL, NULL, 'N/I', 'PGULLY', 'PGULLY', 1.00, false, false, 'DIRECT-CONNECTION', NULL, NULL, NULL, NULL, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 350.443, 'SRID=25831;POINT (418461.31281972467 4577992.776750923)'::public.geometry, NULL, NULL, NULL, true, true, false, 2, NULL, 'GULLY', '2024-08-23 09:45:07.061', NULL, NULL, '2024-08-23 09:45:07.109', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, 'GULLY', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM gully WHERE gully_id = '-902'), 1, 'INSERT: gully "-902" was inserted');

UPDATE gully SET top_elev = 33.0000 WHERE gully_id = '-902';
SELECT is((SELECT top_elev FROM gully WHERE gully_id = '-902'), 33.0000, 'UPDATE: gully "-902" was updated');

DELETE FROM gully WHERE gully_id = '-902';
SELECT is((SELECT count(*)::integer FROM gully WHERE gully_id = '-902'), 0, 'DELETE: gully "-902" was deleted');

-- gully -> ve_gully_vgully
INSERT INTO gully
(gully_id, code, top_elev, ymax, sandbox, matcat_id, gully_type, gullycat_id, units, groove, siphon, _connec_arccat_id, connec_length, connec_depth, arc_id, "_pol_id_", sector_id, state, state_type, annotation, observ, "comment", omzone_id, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, builtdate, enddate, ownercat_id, muni_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, descript, link, verified, rotation, the_geom, label_x, label_y, label_rotation, publish, inventory, uncertain, expl_id, num_value, feature_type, created_at, pjoint_type, pjoint_id,  updated_at, updated_by, created_by, district_id, workcat_id_plan, asset_id, _connec_matcat_id, connec_y2, epa_type, groove_height, groove_length, units_placement, adate, adescript, siphon_type, odorflap, placement_type)
VALUES('-903', '-903', 33.0000, NULL, NULL, 'N/I', 'VGULLY', 'SGRT6', 1.00, false, false, 'DIRECT-CONNECTION', NULL, NULL, NULL, NULL, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), 1, 2, NULL, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), 'soil1', NULL, NULL, 0, NULL, 'work1', NULL, '2024-08-23', NULL, 'owner1', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '1', 350.443, 'SRID=25831;POINT (418462.42103327863 4577992.942982956)'::public.geometry, NULL, NULL, NULL, true, true, false, 2, NULL, 'GULLY', '2024-08-23 09:52:22.408', NULL, NULL, '2024-08-23 09:52:22.461', 'postgres', 'postgres', NULL, NULL, NULL, NULL, NULL, 'GULLY', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM gully WHERE gully_id = '-903'), 1, 'INSERT: gully "-903" was inserted');

UPDATE gully SET top_elev = 33.0000 WHERE gully_id = '-903';
SELECT is((SELECT top_elev FROM gully WHERE gully_id = '-903'), 33.0000, 'UPDATE: gully "-903" was updated');

DELETE FROM gully WHERE gully_id = '-903';
SELECT is((SELECT count(*)::integer FROM gully WHERE gully_id = '-903'), 0, 'DELETE: gully "-903" was deleted');


SELECT * FROM finish();

ROLLBACK;

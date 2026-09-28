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

INSERT INTO ve_gully (gully_id, code, sys_code, top_elev, width, length, ymax, sandbox, matcat_id, gully_type, sys_type, gullycat_id, cat_gully_matcat, units, groove, groove_height, groove_length, siphon, connec_arccat_id, connec_length, connec_depth, connec_matcat_id, connec_y1, connec_y2, arc_id, omunit_id, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, sector_type, macrosector_id, muni_id, drainzone_id, drainzone_type, omzone_id, omzone_type, macroomzone_id, dwfzone_id, dwfzone_type, minsector_id, soilcat_id, function_type, category_type, location_type, fluid_type, descript, annotation, observ, "comment", link, num_value, district_id, postcode, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, placement_type, access_type, asset_id, adate, adescript, verified, uncertain, "label", label_x, label_y, label_rotation, rotation, label_quadrant, svg, inventory, publish, is_operative, inp_type, sector_style, omzone_style, drainzone_style, dwfzone_style, lock_level, expl_visibility, created_at, created_by, updated_at, updated_by, the_geom, pjoint_id, pjoint_type, units_placement, siphon_type, odorflap, dwfzone_outfall, drainzone_outfall, brand_id, model_id)
VALUES('-901', '-901', '-901', 36.7800, 34.5000, 77.6000, 0.8000, 0.0000, 'Concrete', 'GINLET', 'GULLY', 'SGRT4', 'FD', 1.00, false, NULL, NULL, false, 'DIRECT-CONNECTION', 4.672, 1.200, 'Concrete', 35.9800, NULL, '18893', 0, 'GULLY', 1, 2, 2, 1, (SELECT sector_id FROM sector WHERE code = '2' AND sector_id > 0), NULL, 2, 2, NULL, NULL, (SELECT omzone_id FROM omzone WHERE code = '3' AND omzone_id > 0), NULL, 2, 0, NULL, 0, 'soil1', 'St. Function', 'St. Category', 'St. Location', 0, NULL, NULL, NULL, NULL, 'https://www.giswater.org', NULL, 2, '08830', '1-10320C', NULL, NULL, NULL, NULL, NULL, 1, 1, 'work3', NULL, NULL, '2023-10-15', NULL, 'owner1', NULL, NULL, NULL, NULL, NULL, 0, false, NULL, '3', NULL, -9.377, -9.377, NULL, NULL, true, true, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2021-09-05 15:42:47.000', 'postgres', NULL, NULL, 'SRID=25831;POINT (429089.6348767015 4576325.2010902)'::public.geometry, '18893', 'ARC', NULL, NULL, NULL, NULL, NULL, NULL, NULL);

SELECT is((SELECT count(*)::integer FROM ve_gully WHERE code = '-901'), 1, 'INSERT: ve_gully -901 was inserted');
SELECT is((SELECT count(*)::integer FROM gully WHERE code = '-901'), 1, 'INSERT: gully -901 was inserted');

UPDATE ve_gully SET annotation = 'updated annotation' WHERE code = '-901';
SELECT is((SELECT annotation FROM ve_gully WHERE code = '-901'), 'updated annotation', 'UPDATE: ve_gully -901 was updated');
SELECT is((SELECT annotation FROM gully WHERE code = '-901'), 'updated annotation', 'UPDATE: gully -901 was updated');

DELETE FROM ve_gully WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_gully WHERE code = '-901'), 0, 'DELETE: ve_gully -901 was deleted');
SELECT is((SELECT count(*)::integer FROM gully WHERE code = '-901'), 0, 'DELETE: gully -901 was deleted');


SELECT * FROM finish();


ROLLBACK;
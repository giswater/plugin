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


INSERT INTO ve_connec (code, sys_code, top_elev, "depth", connec_type, sys_type, conneccat_id, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, inp_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, crmzone_id, crmzone_name, customer_code, connec_length, n_hydrometer, arc_id, annotation, observ, "comment", staticpressure, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, svg, rotation, link, verified, "label", label_x, label_y, label_rotation, label_quadrant, publish, inventory, num_value, pjoint_id, pjoint_type, adate, adescript, accessibility, asset_id, dma_style, presszone_style, priority, access_type, placement_type, om_state, conserv_state, is_operative, plot_id, brand_id, model_id, serial_number, minsector_id, demand_base, press_max, press_min, press_avg, quality_max, quality_min, quality_avg, created_at, created_by, updated_at, updated_by, the_geom, demand_max, demand_min, demand_avg)
VALUES('-901', '-901', 38.0963, NULL, 'WJOIN', 'WJOIN', 'FACADE-CABINET', 'PVC', '16', '25', 25.00000, 'JUNCTION', 'JUNCTION', 1, 2, 1, 1, (SELECT sector_id FROM sector WHERE code = '3' AND sector_id > 0), (SELECT presszone_id FROM presszone WHERE code = '3' AND presszone_id > 0), NULL, 71.75, (SELECT dma_id FROM dma WHERE code = '2' AND dma_id > 0), NULL, NULL, (SELECT dqa_id FROM dqa WHERE code = '1' AND dqa_id > 0), NULL, NULL, NULL, NULL, 'cc3279', NULL, NULL, '2031', NULL, NULL, NULL, 33.654, 'soil1', 'St. Function', 'St. Category', 'St. Fluid', 'St. Location', 'work2', NULL, NULL, '1993-09-02', NULL, 'owner1', 1, '08830', 1, '1-11011C', 58, '58', NULL, NULL, NULL, 1, 1, NULL, NULL, 2.564, 'https://www.giswater.org', '0', NULL, '5', NULL, 2.564, NULL, true, true, NULL, '2031', 'ARC', NULL, NULL, NULL, NULL, '179,205,227', '204,235,197', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, 113921, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2021-03-28 17:06:35.000', 'postgres', '2024-02-21 12:08:24.000', 'postgres', 'SRID=25831;POINT (414234.94619056734 4576497.812674751)'::public.geometry, NULL, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_connec WHERE code = '-901'), 1, 'INSERT: ve_connec -901 was inserted');
SELECT is((SELECT count(*)::integer FROM connec WHERE code = '-901'), 1, 'INSERT: connec -901 was inserted');


UPDATE ve_connec SET descript = 'updated descript' WHERE code = '-901';
SELECT is((SELECT descript FROM ve_connec WHERE code = '-901'), 'updated descript', 'UPDATE: ve_connec -901 was updated');
SELECT is((SELECT descript FROM connec WHERE code = '-901'), 'updated descript', 'UPDATE: connec -901 was updated');


DELETE FROM ve_connec WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_connec WHERE code = '-901'), 0, 'DELETE: ve_connec -901 was deleted');
SELECT is((SELECT count(*)::integer FROM connec WHERE code = '-901'), 0, 'DELETE: connec -901 was deleted');


SELECT * FROM finish();

ROLLBACK;
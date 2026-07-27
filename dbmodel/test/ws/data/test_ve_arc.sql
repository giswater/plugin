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

INSERT INTO ve_arc (code, node_1, nodetype_1, elevation1, depth1, staticpressure1, node_2, nodetype_2, staticpressure2, elevation2, depth2, "depth", arccat_id, arc_type, sys_type, cat_matcat_id, cat_pnom, cat_dnom, cat_dint, epa_type, state, state_type, expl_id, macroexpl_id, sector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, annotation, observ, "comment", gis_length, custom_length, soilcat_id, function_type, category_type, fluid_type, location_type, workcat_id, workcat_id_end, workcat_id_plan, builtdate, enddate, ownercat_id, muni_id, postcode, district_id, streetaxis_id, postnumber, postcomplement, streetaxis2_id, postnumber2, postcomplement2, region_id, province_id, descript, link, verified, "label", label_x, label_y, label_rotation, label_quadrant, publish, inventory, num_value, adate, adescript, dma_style, presszone_style, asset_id, pavcat_id, om_state, conserv_state, parent_id, is_operative, brand_id, model_id, serial_number, minsector_id, flow_max, flow_min, flow_avg, vel_max, vel_min, vel_avg, created_at, created_by, updated_at, updated_by, the_geom, inp_type)
VALUES('-901', '1059', 'T', 39.4360, 0.0000, 32.314, '1058', 'T', 34.309, 37.4409, 0.0000, 0.00, 'FD150', 'PIPE', 'PIPE', 'FD', '16', '150', 153.00000, 'PIPE', 1, 2, 1, 1, 3, '3', NULL, 71.75, 2, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, 31.14, NULL, 'soil1', 'St. Function', 'St. Category', 'St. Fluid', 'St. Location', 'work1', NULL, NULL, '2007-07-07', NULL, 'owner1', 1, '08830', 1, '1-10000C', NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, 'https://www.giswater.org', '0', NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, '179,205,227', '204,235,197', NULL, 'Asphalt', NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-08-13 09:15:52.000', 'postgres', '2020-08-13 09:15:52.000', 'postgres', 'SRID=25831;LINESTRING (419226.5872581192 4576722.169890118, 419241.7624485789 4576716.732824818, 419252.54014363216 4576704.955957653)'::public.geometry, 'PIPE');
SELECT is((SELECT count(*)::integer FROM ve_arc WHERE code = '-901'), 1, 'INSERT: ve_arc -901 was inserted');
SELECT is((SELECT count(*)::integer FROM arc WHERE code = '-901'), 1, 'INSERT: arc -901 was inserted');

UPDATE ve_arc SET descript = 'updated descript' WHERE code = '-901';
SELECT is((SELECT descript FROM ve_arc WHERE code = '-901'), 'updated descript', 'UPDATE: ve_arc -901 was updated');
SELECT is((SELECT descript FROM arc WHERE code = '-901'), 'updated descript', 'UPDATE: arc -901 was updated');

DELETE FROM ve_arc WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_arc WHERE code = '-901'), 0, 'DELETE: ve_arc -901 was deleted');
SELECT is((SELECT count(*)::integer FROM arc WHERE code = '-901'), 0, 'DELETE: arc -901 was deleted');


SELECT * FROM finish();

ROLLBACK;

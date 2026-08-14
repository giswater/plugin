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

SELECT plan(17);

-- Delete existing sample link
DELETE FROM link WHERE feature_id = 3008 AND feature_type = 'CONNEC';

INSERT INTO ve_link (link_id, code, link_type, feature_type, feature_id, exit_type, exit_id, state, expl_id, sector_id, sector_type, macrosector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, top_elev2, elevation1, fluid_type, gis_length, the_geom, muni_id, is_operative, staticpressure1, linkcat_id, workcat_id, workcat_id_end, builtdate, enddate, updated_at, updated_by, uncertain, minsector_id, verified, state_type, brand_id, model_id)
VALUES(-901, '-901', 'PIPELINK', 'CONNEC', '3008', 'ARC', '2067', 1, 1, 3, 'DISTRIBUTION', 1, '3', NULL, 71.75, 2, NULL, NULL, 1, NULL, NULL, NULL, NULL, 'St. Fluid', 16.646, 'SRID=25831;LINESTRING (419084.18264611065 4576806.076099069, 419093.3076407612 4576819.998540623)'::public.geometry, 1, true, 22.741, 'PVC25-PN16', NULL, NULL, '2002-04-21', NULL, NULL, NULL, false, 113854, 0, 2, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_link WHERE code = '-901'), 1, 'INSERT: ve_link -901 was inserted');
SELECT is((SELECT count(*)::integer FROM link WHERE code = '-901'), 1, 'INSERT: link -901 was inserted');
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), TRUE, 'INSERT: userdefined_geom defaults to TRUE');

UPDATE link SET userdefined_geom = NULL WHERE code = '-901';
UPDATE ve_link SET verified = 1 WHERE code = '-901';
SELECT ok((SELECT userdefined_geom FROM link WHERE code = '-901') IS NULL, 'UPDATE: other attrs keep userdefined_geom NULL');

UPDATE ve_link SET the_geom = ST_Translate(the_geom, 0.001, 0.001) WHERE code = '-901';
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), TRUE, 'UPDATE: geom change sets userdefined_geom TRUE');

UPDATE ve_link SET userdefined_geom = FALSE WHERE code = '-901';
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), FALSE, 'UPDATE: forced FALSE is kept');

UPDATE ve_link SET userdefined_geom = FALSE, the_geom = ST_Translate(the_geom, 0.001, 0.001) WHERE code = '-901';
SELECT is((SELECT userdefined_geom FROM link WHERE code = '-901'), FALSE, 'UPDATE: forced FALSE is kept when geom changes');


UPDATE ve_link SET verified = 1 WHERE code = '-901';
SELECT is((SELECT verified::integer FROM ve_link WHERE code = '-901'), 1, 'UPDATE: ve_link -901 was updated');
SELECT is((SELECT verified::integer FROM link WHERE code = '-901'), 1, 'UPDATE: link -901 was updated');


DELETE FROM ve_link WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_link WHERE code = '-901'), 0, 'DELETE: ve_link -901 was deleted');
SELECT is((SELECT count(*)::integer FROM link WHERE code = '-901'), 0, 'DELETE: link -901 was deleted');


INSERT INTO ve_link (link_id, code, link_type, feature_type, feature_id, exit_type, exit_id, state, expl_id, sector_id, sector_type, macrosector_id, presszone_id, presszone_type, presszone_head, dma_id, dma_type, macrodma_id, dqa_id, dqa_type, macrodqa_id, top_elev2, elevation1, fluid_type, gis_length, the_geom, muni_id, is_operative, staticpressure1, linkcat_id, workcat_id, workcat_id_end, builtdate, enddate, updated_at, updated_by, uncertain, minsector_id, verified, state_type, brand_id, model_id)
VALUES(-901, '-901', 'VLINK', 'CONNEC', '3008', 'ARC', '2067', 1, 1, 3, 'DISTRIBUTION', 1, '3', NULL, 71.75, 2, NULL, NULL, 1, NULL, NULL, NULL, NULL, 'St. Fluid', 16.646, 'SRID=25831;LINESTRING (419084.18264611065 4576806.076099069, 419093.3076407612 4576819.998540623)'::public.geometry, 1, true, 22.741, 'VIRTUAL', NULL, NULL, '2002-04-21', NULL, NULL, NULL, false, 113854, 0, 2, NULL, NULL);
SELECT is((SELECT count(*)::integer FROM ve_link WHERE code = '-901'), 1, 'INSERT: ve_link -901 was inserted');
SELECT is((SELECT count(*)::integer FROM link WHERE code = '-901'), 1, 'INSERT: link -901 was inserted');


UPDATE ve_link SET verified = 1 WHERE code = '-901';
SELECT is((SELECT verified::integer FROM ve_link WHERE code = '-901'), 1, 'UPDATE: ve_link -901 was updated');
SELECT is((SELECT verified::integer FROM link WHERE code = '-901'), 1, 'UPDATE: link -901 was updated');


DELETE FROM ve_link WHERE code = '-901';
SELECT is((SELECT count(*)::integer FROM ve_link WHERE code = '-901'), 0, 'DELETE: ve_link -901 was deleted');
SELECT is((SELECT count(*)::integer FROM link WHERE code = '-901'), 0, 'DELETE: link -901 was deleted');


SELECT * FROM finish();

ROLLBACK;
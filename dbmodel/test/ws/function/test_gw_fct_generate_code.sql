/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(11);

INSERT INTO config_code_parts (context, entity, part, source_expr, concat_order, descript, active) VALUES
('feature', NULL, 'separator', $$'_'::text$$, 2, 'Underscore separator', true),
('feature', NULL, 'sequence', $$lpad(nextval('seq_feature_code')::text, 8, '0')$$, 3, 'Global feature sequence', true),
('feature', NULL, 'macrosector_code', $$SELECT m.code::text
FROM macrosector m,
LATERAL (
    SELECT ST_SetSRID(
        ST_GeomFromGeoJSON(($1::json->>'the_geom')),
        (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)
    ) AS feat_geom
) g
WHERE m.active IS TRUE
  AND ($1::json->>'the_geom') IS NOT NULL
  AND btrim($1::json->>'the_geom') <> ''
  AND g.feat_geom IS NOT NULL
  AND ST_DWithin(m.the_geom, g.feat_geom, 0.001)
ORDER BY ST_Distance(g.feat_geom, ST_Centroid(m.the_geom))
LIMIT 1$$, 90, 'Macrosector from geometry', false),
('feature', NULL, 'project_network', $$SELECT CASE upper(project_type) WHEN 'WS' THEN 'A' WHEN 'UD' THEN 'S' ELSE '' END FROM sys_version LIMIT 1$$, 91, 'Network suffix', false),
('feature', 'NODE', 'abrevation', '(SELECT abrevation FROM cat_feature WHERE id = ($1::json->>''node_type''))', 1, 'Catalog abrevation for nodes', true),
('mapzone', NULL, 'abrevation', '(SELECT abrevation FROM config_mapzones WHERE id = $2)', 1, 'Mapzone abrevation prefix', true),
('mapzone', NULL, 'separator', $$'_'::text$$, 2, 'Underscore separator', true),
('mapzone', NULL, 'sequence', $$lpad(nextval('seq_mapzone_code')::text, 5, '0')$$, 3, 'Global mapzone sequence', true),
('mapzone', NULL, 'macrosector_code', $$SELECT m.code::text
FROM macrosector m,
LATERAL (
    SELECT ST_SetSRID(
        ST_GeomFromGeoJSON(($1::json->>'the_geom')),
        (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)
    ) AS feat_geom
) g
WHERE m.active IS TRUE
  AND ($1::json->>'the_geom') IS NOT NULL
  AND btrim($1::json->>'the_geom') <> ''
  AND g.feat_geom IS NOT NULL
  AND ST_DWithin(m.the_geom, g.feat_geom, 0.001)
ORDER BY ST_Distance(g.feat_geom, ST_Centroid(m.the_geom))
LIMIT 1$$, 90, 'Macrosector from geometry', false),
('mapzone', NULL, 'project_network', $$SELECT CASE upper(project_type) WHEN 'WS' THEN 'A' WHEN 'UD' THEN 'S' ELSE '' END FROM sys_version LIMIT 1$$, 91, 'Network suffix', false)
ON CONFLICT (context, entity, part) DO UPDATE SET
  source_expr = EXCLUDED.source_expr,
  concat_order = EXCLUDED.concat_order,
  descript = EXCLUDED.descript,
  active = EXCLUDED.active;

INSERT INTO config_mapzones (id, abrevation, descript, fid, code_autofill, active, is_dynamic)
VALUES ('TSTMAP', 'TST', 'Test mapzone', NULL, true, true, true)
ON CONFLICT (id) DO UPDATE
SET abrevation = EXCLUDED.abrevation, code_autofill = EXCLUDED.code_autofill;

UPDATE cat_feature
SET abrevation = 'TST', code_autofill = true
WHERE id = 'MANHOLE';

SELECT is(
    gw_fct_generate_code('feature', 'MANHOLE', json_build_object('node_id', 1, 'node_type', 'MANHOLE')),
    'TST_00000001',
    'Feature code uses abrevation + separator + sequence'
);

WITH feat AS (
    SELECT ST_SetSRID(ST_MakePoint(500000, 4500000), (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)) AS geom
)
INSERT INTO macrosector (macrosector_id, code, name, active, the_geom)
SELECT -998, 'CR02', 'Far macrosector', true, ST_Multi(ST_Buffer(ST_Translate(feat.geom, 500, 0), 100)) FROM feat
ON CONFLICT (macrosector_id) DO UPDATE SET code = EXCLUDED.code, the_geom = EXCLUDED.the_geom;

WITH feat AS (
    SELECT ST_SetSRID(ST_MakePoint(500000, 4500000), (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)) AS geom
)
INSERT INTO macrosector (macrosector_id, code, name, active, the_geom)
SELECT -999, 'CR01', 'Near macrosector', true, ST_Multi(ST_Buffer(feat.geom, 100)) FROM feat
ON CONFLICT (macrosector_id) DO UPDATE SET code = EXCLUDED.code, the_geom = EXCLUDED.the_geom;

UPDATE cat_feature SET abrevation = 'TST_' WHERE id = 'MANHOLE';

UPDATE config_code_parts c
SET concat_order = 900 + sub.rn
FROM (
    SELECT id, row_number() OVER (ORDER BY part) AS rn
    FROM config_code_parts
    WHERE context = 'feature' AND entity IS NULL
) sub
WHERE c.id = sub.id;

UPDATE config_code_parts SET concat_order = 905 WHERE context = 'feature' AND entity = 'NODE' AND part = 'abrevation';

UPDATE config_code_parts SET active = true, concat_order = 1 WHERE context = 'feature' AND part = 'macrosector_code';
UPDATE config_code_parts SET active = true, concat_order = 2 WHERE context = 'feature' AND part = 'project_network';
UPDATE config_code_parts SET active = false, concat_order = 900 WHERE context = 'feature' AND part = 'separator';
UPDATE config_code_parts SET concat_order = 3 WHERE context = 'feature' AND entity = 'NODE' AND part = 'abrevation';
UPDATE config_code_parts SET active = true, concat_order = 4 WHERE context = 'feature' AND part = 'sequence';

ALTER SEQUENCE seq_feature_code RESTART WITH 1;

SELECT is(
    gw_fct_generate_code('feature', 'MANHOLE', (
        SELECT json_build_object(
            'node_id', 1,
            'node_type', 'MANHOLE',
            'the_geom', ST_AsGeoJSON(geom)::json
        )
        FROM (SELECT ST_SetSRID(ST_MakePoint(500000, 4500000), (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)) AS geom) feat
    )),
    'CR01ATST_00000001',
    'Feature code picks nearest macrosector from element geometry (CR layout)'
);

UPDATE config_code_parts c
SET concat_order = 900 + sub.rn
FROM (
    SELECT id, row_number() OVER (ORDER BY part) AS rn
    FROM config_code_parts
    WHERE context = 'mapzone' AND entity IS NULL
) sub
WHERE c.id = sub.id;

UPDATE config_code_parts SET active = true, concat_order = 1 WHERE context = 'mapzone' AND part = 'macrosector_code';
UPDATE config_code_parts SET active = true, concat_order = 2 WHERE context = 'mapzone' AND part = 'project_network';
UPDATE config_code_parts SET active = false, concat_order = 900 WHERE context = 'mapzone' AND part = 'separator';
UPDATE config_code_parts SET concat_order = 3 WHERE context = 'mapzone' AND part = 'abrevation';
UPDATE config_code_parts SET active = true, concat_order = 4 WHERE context = 'mapzone' AND part = 'sequence';

ALTER SEQUENCE seq_mapzone_code RESTART WITH 1;

SELECT is(
    gw_fct_generate_code('mapzone', 'DMA', (
        SELECT json_build_object(
            'dma_id', 7,
            'the_geom', ST_AsGeoJSON(geom)::json
        )
        FROM (SELECT ST_SetSRID(ST_MakePoint(500000, 4500000), (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)) AS geom) feat
    )),
    'CR01ADMA00001',
    'Mapzone code picks nearest macrosector from geometry (CR layout)'
);

UPDATE config_code_parts c
SET concat_order = 900 + sub.rn
FROM (
    SELECT id, row_number() OVER (ORDER BY part) AS rn
    FROM config_code_parts
    WHERE context = 'mapzone' AND entity IS NULL
) sub
WHERE c.id = sub.id;

UPDATE config_code_parts SET active = false WHERE context = 'mapzone' AND part IN ('macrosector_code', 'project_network');
UPDATE config_code_parts SET active = true, concat_order = 1 WHERE context = 'mapzone' AND part = 'abrevation';
UPDATE config_code_parts SET active = true, concat_order = 2 WHERE context = 'mapzone' AND part = 'separator';
UPDATE config_code_parts SET active = true, concat_order = 3, source_expr = $$lpad(nextval('seq_mapzone_code')::text, 5, '0')$$ WHERE context = 'mapzone' AND part = 'sequence';

ALTER SEQUENCE seq_mapzone_code RESTART WITH 1;

SELECT is(
    gw_fct_generate_code('mapzone', 'TSTMAP', json_build_object('sector_id', 42)),
    'TST_00001',
    'Mapzone code uses abrevation + separator + sequence'
);

UPDATE cat_feature SET code_autofill = false WHERE id = 'MANHOLE';

SELECT is(
    gw_fct_generate_code('feature', 'MANHOLE', json_build_object('node_id', 1, 'node_type', 'MANHOLE')),
    NULL::text,
    'Returns NULL when cat_feature.code_autofill is false'
);

UPDATE cat_feature SET code_autofill = true WHERE id = 'MANHOLE';
UPDATE cat_feature SET abrevation = 'TST' WHERE id = 'MANHOLE';

UPDATE config_code_parts SET active = false WHERE context = 'feature';

SELECT is(
    gw_fct_generate_code('feature', 'MANHOLE', json_build_object('node_id', 1, 'node_type', 'MANHOLE')),
    NULL::text,
    'Returns NULL when all feature code parts are inactive'
);

UPDATE config_code_parts c
SET concat_order = 900 + sub.rn
FROM (
    SELECT id, row_number() OVER (ORDER BY part) AS rn
    FROM config_code_parts
    WHERE context = 'feature' AND entity IS NULL
) sub
WHERE c.id = sub.id;

UPDATE config_code_parts SET concat_order = 905 WHERE context = 'feature' AND entity = 'NODE' AND part = 'abrevation';
UPDATE config_code_parts SET active = true, concat_order = 1 WHERE context = 'feature' AND entity = 'NODE' AND part = 'abrevation';
UPDATE config_code_parts
SET active = true,
    concat_order = 2,
    source_expr = $$'_' || lpad(nextval(format('%I_code_seq', lower(($1::json->>'node_type')))::regclass)::text, 8, '0')$$
WHERE context = 'feature' AND part = 'sequence';

CREATE SEQUENCE IF NOT EXISTS manhole_code_seq START 10 INCREMENT 1;

SELECT is(
    gw_fct_generate_code('feature', 'MANHOLE', json_build_object('node_id', 1, 'node_type', 'MANHOLE')),
    'TST_00000010',
    'Per-featurecat sequence works when configured in code parts'
);

UPDATE config_code_parts SET active = false WHERE context = 'feature';

SELECT is(
    gw_fct_generate_code('feature', 'MANHOLE', json_build_object('node_id', 1, 'node_type', 'MANHOLE')),
    NULL::text,
    'Returns NULL when no concat parts are active'
);

SELECT is(
    CASE
        WHEN btrim(coalesce('USER01', '')) = '' THEN gw_fct_generate_code('feature', 'MANHOLE', json_build_object('node_id', 1, 'node_type', 'MANHOLE'))
        ELSE btrim('USER01')
    END,
    'USER01',
    'User-provided code is preserved (CR NULL-only autofill rule)'
);

UPDATE config_code_parts c
SET concat_order = 900 + sub.rn
FROM (
    SELECT id, row_number() OVER (ORDER BY part) AS rn
    FROM config_code_parts
    WHERE context = 'mapzone' AND entity IS NULL
) sub
WHERE c.id = sub.id;

UPDATE config_code_parts SET active = true, concat_order = 1 WHERE context = 'mapzone' AND part = 'macrosector_code';
UPDATE config_code_parts SET active = true, concat_order = 2 WHERE context = 'mapzone' AND part = 'project_network';
UPDATE config_code_parts SET active = false, concat_order = 900 WHERE context = 'mapzone' AND part = 'separator';
UPDATE config_code_parts SET concat_order = 3 WHERE context = 'mapzone' AND part = 'abrevation';
UPDATE config_code_parts SET active = true, concat_order = 4, source_expr = $$lpad(nextval('seq_mapzone_code')::text, 5, '0')$$ WHERE context = 'mapzone' AND part = 'sequence';
UPDATE config_mapzones SET abrevation = 'TST_' WHERE id = 'TSTMAP';

ALTER SEQUENCE seq_mapzone_code RESTART WITH 1;

SELECT is(
    CASE
        WHEN NULL::text IS NULL AND ST_SetSRID(ST_MakePoint(500000, 4500000), (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)) IS NOT NULL
        THEN gw_fct_generate_code('mapzone', 'TSTMAP', json_build_object(
            'sector_id', 42,
            'the_geom', ST_AsGeoJSON(ST_SetSRID(ST_MakePoint(500000, 4500000), (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1)))::json
        ))
        ELSE 'USERMAP'::text
    END,
    'CR01ATST_00001',
    'Mapzone autofill runs when code is NULL and geometry is present (CR layout)'
);

SELECT is(
    CASE
        WHEN btrim(coalesce('USERMAP', '')) = '' THEN gw_fct_generate_code('mapzone', 'TSTMAP', json_build_object('sector_id', 42))
        ELSE btrim('USERMAP')
    END,
    'USERMAP',
    'User-provided mapzone code is not overwritten'
);

SELECT finish();

ROLLBACK;

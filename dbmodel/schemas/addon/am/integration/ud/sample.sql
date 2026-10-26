/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public;

INSERT INTO config_material_def (material, project_type, pleak, age_max, age_med, age_min, builtdate_vdef, compliance)
SELECT id, 'UD', 0.16, 58, 50, 42, 1964, 10
FROM PARENT_SCHEMA.cat_material
WHERE active = true
ON CONFLICT (material, project_type) DO NOTHING;

INSERT INTO config_catalog_def (arccat_id, project_type, dnom, cost_constr, cost_repmain, cost_rehab, compliance)
SELECT id AS arccat_id,
	'UD',
	geom1 AS dnom,
	round(COALESCE(geom1, 0)::numeric * 3 / 5 + 70) AS cost_constr,
	round(COALESCE(geom1, 0)::numeric * 9 / 5 + 310) AS cost_repmain,
	round(COALESCE(geom1, 0)::numeric * 2 / 5 + 40) AS cost_rehab,
	10 AS compliance
FROM PARENT_SCHEMA.cat_arc
ON CONFLICT (arccat_id, project_type) DO UPDATE SET
	dnom = EXCLUDED.dnom,
	cost_constr = EXCLUDED.cost_constr,
	cost_repmain = EXCLUDED.cost_repmain,
	cost_rehab = EXCLUDED.cost_rehab,
	compliance = EXCLUDED.compliance;

INSERT INTO config_nodecatalog_def (nodecat_id, project_type, dnom, cost_constr, cost_repmain, cost_rehab, compliance)
SELECT id AS nodecat_id,
	'UD',
	geom1 AS dnom,
	round(COALESCE(geom1, 0)::numeric * 3 / 5 + 70) AS cost_constr,
	round(COALESCE(geom1, 0)::numeric * 9 / 5 + 310) AS cost_repmain,
	round(COALESCE(geom1, 0)::numeric * 2 / 5 + 40) AS cost_rehab,
	10 AS compliance
FROM PARENT_SCHEMA.cat_node
WHERE active IS DISTINCT FROM FALSE
ON CONFLICT (nodecat_id, project_type) DO UPDATE SET
	dnom = EXCLUDED.dnom,
	cost_constr = EXCLUDED.cost_constr,
	cost_repmain = EXCLUDED.cost_repmain,
	cost_rehab = EXCLUDED.cost_rehab,
	compliance = EXCLUDED.compliance;

-- Sample catalogs are inserted with matcat_id null. The dialog Material column and the
-- inventory view read it, so copy the material already used on the operative assets.
UPDATE PARENT_SCHEMA.cat_arc c
SET matcat_id = picked.matcat_id
FROM (
	SELECT DISTINCT ON (a.arccat_id)
		a.arccat_id::text AS arccat_id,
		a.matcat_id
	FROM PARENT_SCHEMA.arc a
	JOIN PARENT_SCHEMA.cat_material m
		ON m.id = a.matcat_id AND COALESCE(m.active, true) AND 'ARC' = ANY(m.feature_type)
	WHERE a.state = 1
		AND a.matcat_id IS NOT NULL
	GROUP BY a.arccat_id, a.matcat_id
	ORDER BY a.arccat_id, count(*) DESC, a.matcat_id
) picked
WHERE c.id::text = picked.arccat_id
	AND c.matcat_id IS NULL;

UPDATE PARENT_SCHEMA.cat_node c
SET matcat_id = picked.matcat_id
FROM (
	SELECT DISTINCT ON (n.nodecat_id)
		n.nodecat_id::text AS nodecat_id,
		n.matcat_id
	FROM PARENT_SCHEMA.node n
	JOIN PARENT_SCHEMA.cat_material m
		ON m.id = n.matcat_id AND COALESCE(m.active, true) AND 'NODE' = ANY(m.feature_type)
	WHERE n.state = 1
		AND n.matcat_id IS NOT NULL
	GROUP BY n.nodecat_id, n.matcat_id
	ORDER BY n.nodecat_id, count(*) DESC, n.matcat_id
) picked
WHERE c.id::text = picked.nodecat_id
	AND c.matcat_id IS NULL;

-- Trunk sewers are the operative collectors of 1 m or more. The exercise asks the
-- user to mark two more of these as strategic; one is already flagged below.
INSERT INTO PARENT_SCHEMA.man_type_function (function_type, feature_type, featurecat_id, observ, active)
SELECT 'Trunk sewer', '{ARC}'::text[], NULL::text[], 'Collector of a large area', true
WHERE NOT EXISTS (
	SELECT 1 FROM PARENT_SCHEMA.man_type_function m WHERE m.function_type = 'Trunk sewer'
);

UPDATE PARENT_SCHEMA.arc a
SET function_type = 'Trunk sewer'
FROM PARENT_SCHEMA.cat_arc c
WHERE c.id::text = a.arccat_id::text
	AND a.state = 1
	AND a.arc_type IN ('CONDUIT', 'SIPHON')
	AND COALESCE(c.geom1, 0) >= 1
	AND (a.function_type IS NULL OR a.function_type = 'St. Function');

-- CCTV, breakdowns and the input override, visible without the importer.
-- Inspection 9001 is replaced on re-integrate. Every operative pipe gets at least
-- one defect; code and severity rotate so the priority run is not one flat class.
-- The delete trigger writes a dummy score of 1; clear that on the pipes that just lost the inspection.
CREATE TEMP TABLE IF NOT EXISTS am_ud_sample_cctv_reset (arc_id varchar(16));
TRUNCATE am_ud_sample_cctv_reset;
INSERT INTO am_ud_sample_cctv_reset (arc_id)
SELECT DISTINCT arc_id FROM am.ud_arc_pathology WHERE inspection_id = 9001;

DELETE FROM am.ud_arc_pathology WHERE inspection_id = 9001;

UPDATE am.ud_arc_input i
SET structural_raw = NULL,
	operational_raw = NULL,
	estimated_cost = NULL,
	inspection_id = NULL,
	inspection_date = NULL
FROM pg_temp.am_ud_sample_cctv_reset r
WHERE i.arc_id = r.arc_id
	AND NOT EXISTS (
		SELECT 1 FROM am.ud_arc_pathology p
		WHERE p.arc_id = i.arc_id AND COALESCE(p.active, true)
	);

INSERT INTO am.ud_arc_pathology (
	arc_id, pathology_id, inspection_id, pk_start, pk_end, severity, observation, inspection_date
)
SELECT asset.arc_id, cat.pathology_id, 9001,
	0, 1 + (asset.n % 5),
	1 + ((asset.n + extra.k) % 5),
	'Sample CCTV', DATE '2024-06-01'
FROM (
	SELECT a.arc_id::varchar(16) AS arc_id,
		(row_number() OVER (ORDER BY a.arc_id::integer) - 1)::integer AS n
	FROM PARENT_SCHEMA.arc a
	WHERE a.state = 1
		AND a.arc_type IN ('CONDUIT', 'SIPHON')
) asset
CROSS JOIN LATERAL (
	SELECT 0 AS k
	UNION ALL
	SELECT 3 WHERE asset.n % 4 = 0
) extra
JOIN (
	VALUES
		(0, 'BAF'),
		(1, 'BAB'),
		(2, 'BBA'),
		(3, 'BBD'),
		(4, 'BAC'),
		(5, 'BAL')
) AS obs(slot, code) ON obs.slot = (asset.n + extra.k) % 6
JOIN am.ud_cat_pathology cat ON cat.code = obs.code
WHERE NOT EXISTS (
	SELECT 1 FROM am.ud_arc_pathology p
	WHERE p.arc_id = asset.arc_id AND p.inspection_id = 9001 AND p.pathology_id = cat.pathology_id
);

INSERT INTO am.ud_node_pathology (
	node_id, pathology_id, inspection_id, severity, observation, inspection_date
)
SELECT asset.node_id, cat.pathology_id, 9001, 4, 'Sample node break', DATE '2024-06-01'
FROM (
	SELECT node_id::varchar(16) AS node_id
	FROM PARENT_SCHEMA.node
	WHERE state = 1
	ORDER BY node_id
	LIMIT 1
) asset
JOIN am.ud_cat_pathology cat ON cat.code = 'BAC'
WHERE NOT EXISTS (
	SELECT 1 FROM am.ud_node_pathology p
	WHERE p.node_id = asset.node_id AND p.inspection_id = 9001
);

-- Pathology triggers update the parent schema and leave search_path there.
SET search_path = am, public;

-- Drop the connec-count proxy previously stored as DWF. A function will calculate it.
UPDATE am.ud_arc_input SET dwf_raw = NULL WHERE dwf_raw IS NOT NULL;
UPDATE am.ud_node_input SET dwf_raw = NULL WHERE dwf_raw IS NOT NULL;

CREATE TABLE IF NOT EXISTS am.ud_breakdown (
	id serial PRIMARY KEY,
	feature_id varchar(16),
	feature_type varchar(16),
	"date" date,
	breakdown_type varchar(50),
	the_geom public.geometry(Point, SRID_VALUE)
);
CREATE INDEX IF NOT EXISTS idx_ud_breakdown_feature ON am.ud_breakdown (feature_type, feature_id);

INSERT INTO am.ud_breakdown (feature_id, feature_type, "date", breakdown_type, the_geom)
SELECT a.arc_id::varchar(16), 'ARC', DATE '2023-03-12', 'Collapse',
	ST_LineInterpolatePoint(ST_LineMerge(a.the_geom), 0.5)
FROM PARENT_SCHEMA.arc a
WHERE a.state = 1
	AND NOT EXISTS (
		SELECT 1 FROM am.ud_breakdown b
		WHERE b.feature_id = a.arc_id::varchar(16) AND b.feature_type = 'ARC' AND b."date" = DATE '2023-03-12'
	)
ORDER BY a.arc_id
LIMIT 2;

-- Drop the previous sample flag (lowest arc_id) so only one pipe stays strategic.
UPDATE am.ud_arc_input
SET strategic = NULL, mandatory = NULL, compliance = NULL
WHERE strategic IS TRUE
	AND mandatory IS TRUE
	AND compliance IS TRUE
	AND data_quality = 2
	AND arc_id <> (
		SELECT a.arc_id::varchar(16)
		FROM PARENT_SCHEMA.arc a
		WHERE a.state = 1
			AND a.function_type = 'Trunk sewer'
		ORDER BY a.arc_id::integer
		LIMIT 1
	);

INSERT INTO am.ud_arc_input (arc_id, strategic, mandatory, compliance, data_quality)
SELECT a.arc_id::varchar(16), true, true, true, 2
FROM PARENT_SCHEMA.arc a
WHERE a.state = 1
	AND a.function_type = 'Trunk sewer'
ORDER BY a.arc_id::integer
LIMIT 1
ON CONFLICT (arc_id) DO UPDATE SET
	strategic = EXCLUDED.strategic,
	mandatory = EXCLUDED.mandatory,
	compliance = EXCLUDED.compliance,
	data_quality = EXCLUDED.data_quality;

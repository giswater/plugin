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

-- A few operative assets so CCTV, breakdowns and the input override are visible
-- without running the importer. Re-integrate does not duplicate them.
INSERT INTO am.ud_arc_pathology (
	arc_id, pathology_id, inspection_id, pk_start, pk_end, severity, observation, inspection_date
)
SELECT asset.arc_id, cat.pathology_id, 9001, obs.pk_start, obs.pk_end, obs.severity,
	obs.observation, DATE '2024-06-01'
FROM (
	SELECT arc_id::varchar(16) AS arc_id, row_number() OVER (ORDER BY arc_id) AS n
	FROM PARENT_SCHEMA.arc
	WHERE state = 1
	ORDER BY arc_id
	LIMIT 3
) asset
JOIN (
	VALUES
		(1, 'BAC', 0::numeric, 8::numeric, 5, 'Sample collapse, full replacement'),
		(1, 'BBA', 1::numeric, 2::numeric, 2, 'Sample roots, maintenance only'),
		(2, 'BAB', 0::numeric, 3::numeric, 3, 'Sample crack, rehabilitation'),
		(3, 'BBD', 2::numeric, 4::numeric, 4, 'Sample infiltration')
) AS obs(n, code, pk_start, pk_end, severity, observation) ON obs.n = asset.n
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

INSERT INTO am.ud_arc_input (arc_id, strategic, mandatory, compliance, data_quality)
SELECT arc_id::varchar(16), true, true, true, 2
FROM PARENT_SCHEMA.arc
WHERE state = 1
ORDER BY arc_id
LIMIT 1
ON CONFLICT (arc_id) DO UPDATE SET
	strategic = EXCLUDED.strategic,
	mandatory = EXCLUDED.mandatory,
	compliance = EXCLUDED.compliance,
	data_quality = EXCLUDED.data_quality;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public;

-- UD catalogs use geom1, not dnom (WS trigger body from common/fct is overwritten here)
CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_asset_cat_arc() RETURNS trigger AS
$BODY$
BEGIN
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	IF TG_OP = 'INSERT' THEN
		INSERT INTO am.config_catalog_def (arccat_id, project_type, dnom)
		VALUES (NEW.id, 'UD', NEW.geom1)
		ON CONFLICT (arccat_id, project_type) DO NOTHING;
		RETURN NEW;
	ELSIF TG_OP = 'UPDATE' THEN
		UPDATE am.config_catalog_def SET dnom = NEW.geom1
		WHERE arccat_id = OLD.id AND project_type = 'UD';
		RETURN NEW;
	END IF;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_asset_cat_node() RETURNS trigger AS
$BODY$
BEGIN
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	IF TG_OP = 'INSERT' THEN
		INSERT INTO am.config_nodecatalog_def (nodecat_id, project_type, dnom)
		VALUES (NEW.id, 'UD', NEW.geom1)
		ON CONFLICT (nodecat_id, project_type) DO NOTHING;
		RETURN NEW;
	ELSIF TG_OP = 'UPDATE' THEN
		UPDATE am.config_nodecatalog_def SET dnom = NEW.geom1
		WHERE nodecat_id = OLD.id AND project_type = 'UD';
		RETURN NEW;
	END IF;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

INSERT INTO PARENT_SCHEMA.config_typevalue (typevalue, id, idval, camelstyle, addparam)
VALUES('sys_table_context', '{"levels": ["AM", "LAYERS"]}', NULL, NULL, '{"orderBy":1}'::json)
ON CONFLICT (typevalue,id) DO NOTHING;

-- catalog FKs / triggers (ARC + NODE only; LINK is WS)
DROP TRIGGER IF EXISTS gw_trg_asset_cat_arc ON PARENT_SCHEMA.cat_arc;
CREATE TRIGGER gw_trg_asset_cat_arc AFTER INSERT OR UPDATE OF geom1 ON PARENT_SCHEMA.cat_arc
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_asset_cat_arc();

-- Shared am catalog tables hold WS and UD rows. A FK can only point at one parent.
ALTER TABLE am.config_catalog_def DROP CONSTRAINT IF EXISTS config_catalog_def_fk;

DROP TRIGGER IF EXISTS gw_trg_asset_cat_material ON PARENT_SCHEMA.cat_material;
CREATE TRIGGER gw_trg_asset_cat_material AFTER INSERT ON PARENT_SCHEMA.cat_material
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_asset_cat_material();

ALTER TABLE am.config_material_def DROP CONSTRAINT IF EXISTS config_material_def_fk;

DROP TRIGGER IF EXISTS gw_trg_asset_cat_node ON PARENT_SCHEMA.cat_node;
CREATE TRIGGER gw_trg_asset_cat_node AFTER INSERT OR UPDATE OF geom1 ON PARENT_SCHEMA.cat_node
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_asset_cat_node();

ALTER TABLE am.config_nodecatalog_def DROP CONSTRAINT IF EXISTS config_nodecatalog_def_fk;

INSERT INTO am.config_catalog_def (
	arccat_id, project_type, dnom, cost_constr, cost_repmain, cost_rehab, compliance
)
SELECT id, 'UD', geom1, 0, 0, 0, 10
FROM PARENT_SCHEMA.cat_arc
ON CONFLICT (arccat_id, project_type) DO NOTHING;

INSERT INTO am.config_nodecatalog_def (
	nodecat_id, project_type, dnom, cost_constr, cost_repmain, cost_rehab, compliance
)
SELECT id, 'UD', geom1, 0, 0, 0, 10
FROM PARENT_SCHEMA.cat_node
WHERE active IS DISTINCT FROM FALSE
ON CONFLICT (nodecat_id, project_type) DO NOTHING;

INSERT INTO am.config_material_def (
	material, project_type, pleak, age_max, age_med, age_min, builtdate_vdef, compliance
)
SELECT id, 'UD', 0.16, 58, 50, 42, 1964, 10
FROM PARENT_SCHEMA.cat_material
WHERE active IS TRUE
ON CONFLICT (material, project_type) DO NOTHING;

INSERT INTO PARENT_SCHEMA.config_typevalue (typevalue, id, idval, addparam) VALUES
('sys_table_context', '35', '["AM", "ARC"]', '{"orderBy": 35}'),
('sys_table_context', '36', '["AM", "NODE"]', '{"orderBy": 36}'),
('sys_table_context', '37', '["AM", "CONFIG"]', '{"orderBy": 38}')
ON CONFLICT (typevalue, id) DO UPDATE SET idval = EXCLUDED.idval, addparam = EXCLUDED.addparam;

INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES
('config_catalog_def', 'Table to define the catalogs', 'role_om', NULL, '37', 4, 'Config catalog', NULL, NULL, NULL, 'am', NULL),
('config_nodecatalog_def', 'Table to define the node catalogs', 'role_om', NULL, '37', 3, 'Config node catalog', NULL, NULL, NULL, 'am', NULL),
('config_material_def', 'Table to define the materials', 'role_om', NULL, '37', 2, 'Config material', NULL, NULL, NULL, 'am', NULL),
('config_engine_def', 'Table to define engines configuration', 'role_om', NULL, '37', 1, 'Config engine', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;

-- Keep integration idempotent when it is run against an AM schema created by an older client.
CREATE TABLE IF NOT EXISTS am.ud_node_pathology (
    rid bigserial PRIMARY KEY,
    node_id varchar(16) NOT NULL,
    pathology_id integer NOT NULL REFERENCES am.ud_cat_pathology (pathology_id),
    inspection_id bigint,
    pk_start numeric(10,2),
    pk_end numeric(10,2),
    pk numeric(10,2),
    clock_start numeric(4,1),
    clock_end numeric(4,1),
    quantification_value numeric(12,3),
    quantification_unit varchar(20),
    severity integer NOT NULL CHECK (severity BETWEEN 1 AND 5),
    observation text,
    inspection_date date,
    active boolean DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_ud_node_pathology_node ON am.ud_node_pathology (node_id);

CREATE TABLE IF NOT EXISTS am.ud_breakdown (
    id serial PRIMARY KEY,
    feature_id varchar(16),
    feature_type varchar(16),
    "date" date,
    breakdown_type varchar(50),
    the_geom public.geometry(Point, SRID_VALUE)
);
CREATE INDEX IF NOT EXISTS idx_ud_breakdown_feature ON am.ud_breakdown (feature_type, feature_id);

GRANT ALL ON TABLE am.ud_node_pathology TO role_basic;
GRANT ALL ON TABLE am.ud_breakdown TO role_basic;

ALTER TABLE am.ud_node_input ADD COLUMN IF NOT EXISTS inspection_id bigint;
ALTER TABLE am.ud_node_input ADD COLUMN IF NOT EXISTS inspection_date date;

-- Per-observation CCTV row: intervention, extent, AWARE score, cost.
-- MAINTENANCE is listed but score is NULL (does not enter AWARE).
CREATE OR REPLACE VIEW am.v_ud_arc_pathology AS
SELECT
	p.rid,
	p.arc_id,
	p.pathology_id,
	c.code,
	c.name,
	c.name_es,
	c.pathology_group,
	p.severity,
	p.pk_start,
	p.pk_end,
	p.pk,
	p.clock_start,
	p.clock_end,
	p.inspection_id,
	p.inspection_date,
	p.observation,
	p.active,
	am.gw_fct_am_ud_extent_m(p.pk_start, p.pk_end, p.pk) AS extent_m,
	ST_Length(a.the_geom)::numeric AS arc_length,
	am.gw_fct_am_ud_intervention(
		p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5
	) AS intervention,
	CASE
		WHEN am.gw_fct_am_ud_intervention(
			p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5
		) = 'MAINTENANCE' THEN NULL
		ELSE am.gw_fct_am_ud_observation_score(
			p.severity,
			am.gw_fct_am_ud_extent_m(p.pk_start, p.pk_end, p.pk),
			ST_Length(a.the_geom)::numeric
		)
	END AS aware_score,
	am.gw_fct_am_ud_defect_cost(
		am.gw_fct_am_ud_intervention(
			p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5
		),
		am.gw_fct_am_ud_extent_m(p.pk_start, p.pk_end, p.pk),
		cat.cost_repmain,
		cat.cost_rehab,
		cat.cost_constr
	) AS calculated_cost
FROM am.ud_arc_pathology p
JOIN am.ud_cat_pathology c ON c.pathology_id = p.pathology_id
JOIN PARENT_SCHEMA.arc a ON a.arc_id::text = p.arc_id::text
LEFT JOIN am.config_catalog_def cat ON cat.arccat_id = a.arccat_id::text AND cat.project_type = 'UD'
WHERE COALESCE(p.active, true) IS TRUE
  AND COALESCE(c.active, true) IS TRUE;

-- Node CCTV. Extent is punctual (pk unused); prices come from the node catalog.
CREATE OR REPLACE VIEW am.v_ud_node_pathology AS
SELECT
	p.rid,
	p.node_id,
	p.pathology_id,
	c.code,
	c.name,
	c.name_es,
	c.pathology_group,
	p.severity,
	p.inspection_id,
	p.inspection_date,
	p.observation,
	p.active,
	am.gw_fct_am_ud_intervention(
		p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5
	) AS intervention,
	CASE
		WHEN am.gw_fct_am_ud_intervention(
			p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5
		) = 'MAINTENANCE' THEN NULL
		ELSE p.severity::numeric
	END AS aware_score,
	am.gw_fct_am_ud_defect_cost(
		am.gw_fct_am_ud_intervention(
			p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5
		),
		0,
		cat.cost_repmain,
		cat.cost_rehab,
		cat.cost_constr
	) AS calculated_cost
FROM am.ud_node_pathology p
JOIN am.ud_cat_pathology c ON c.pathology_id = p.pathology_id
JOIN PARENT_SCHEMA.node n ON n.node_id::text = p.node_id::text
LEFT JOIN am.config_nodecatalog_def cat ON cat.nodecat_id = n.nodecat_id::text AND cat.project_type = 'UD'
WHERE COALESCE(p.active, true) IS TRUE
  AND COALESCE(c.active, true) IS TRUE;

-- Aggregated scores for AWARE input (cond_state = max BA, om_state = max BB).
CREATE OR REPLACE VIEW am.v_ud_inspection_score AS
SELECT
	'ARC'::text AS asset_type,
	v.arc_id::text AS asset_id,
	COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BA'), 1)::numeric AS max_structural_score,
	COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BB'), 1)::numeric AS max_operational_score,
	count(*)::integer AS observation_count,
	count(*) FILTER (WHERE v.severity >= 4)::integer AS severe_observation_count,
	COALESCE(sum(v.calculated_cost), 0)::numeric AS total_cost
FROM am.v_ud_arc_pathology v
GROUP BY v.arc_id
UNION ALL
SELECT
	'NODE'::text,
	v.node_id::text,
	COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BA'), 1)::numeric,
	COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BB'), 1)::numeric,
	count(*)::integer,
	count(*) FILTER (WHERE v.severity >= 4)::integer,
	COALESCE(sum(v.calculated_cost), 0)::numeric
FROM am.v_ud_node_pathology v
GROUP BY v.node_id;

-- Overlay: parent inventory LEFT JOIN extras. presszone_id is the AM dialog filter.
-- Upgraded UD stores the drain zone on omzone_id (4.2 renamed arc.drainzone_id to dma_id).
-- Drop first: ST_Multi() without a typmod cast cannot be changed in place, and the input view depends on it.
DROP VIEW IF EXISTS am.v_asset_ud_arc_input CASCADE;
DROP VIEW IF EXISTS am.ext_ud_arc_asset CASCADE;
CREATE OR REPLACE VIEW am.ext_ud_arc_asset AS
SELECT
	a.arc_id::varchar(16) AS arc_id,
	a.sector_id,
	s.macrosector_id,
	a.omzone_id::varchar AS drainzone_id,
	a.omzone_id::varchar AS presszone_id,
	a.builtdate,
	a.arccat_id,
	cat.geom1 AS dnom,
	cat.matcat_id,
	a.function_type,
	a.code,
	a.expl_id,
	a.dma_id,
	ST_Multi(a.the_geom)::geometry(MultiLineString, SRID_VALUE) AS the_geom,
	CASE WHEN a.builtdate IS NULL THEN NULL
		ELSE EXTRACT(YEAR FROM age(CURRENT_DATE, a.builtdate))::numeric END AS age,
	COALESCE(ps.total_cost, 0)::numeric AS estimated_cost,
	COALESCE(ps.observation_count, 0)::integer AS observation_count,
	COALESCE(ps.severe_observation_count, 0)::integer AS severe_observation_count,
	(
		SELECT v.intervention
		FROM am.v_ud_arc_pathology v
		WHERE v.arc_id::text = a.arc_id::text
		ORDER BY CASE v.intervention
			WHEN 'FULL_REPLACEMENT' THEN 4
			WHEN 'REHABILITATION' THEN 3
			WHEN 'SPOT_REPAIR' THEN 2
			ELSE 1
		END DESC
		LIMIT 1
	) AS recommended_action_src,
	COALESCE(
		ps.max_structural_score,
		CASE WHEN a.conserv_state::text ~ '^[1-5]$' THEN (6 - a.conserv_state::integer)::numeric ELSE NULL END
	) AS structural_raw_src,
	COALESCE(
		ps.max_operational_score,
		CASE WHEN a.om_state::text ~ '^[1-5]$' THEN (6 - a.om_state::integer)::numeric ELSE NULL END
	) AS operational_raw_src,
	(
		(SELECT count(*)::numeric FROM PARENT_SCHEMA.om_visit_x_arc v WHERE v.arc_id = a.arc_id)
		+ (SELECT count(*)::numeric FROM am.ud_breakdown b
			WHERE b.feature_id::text = a.arc_id::text AND upper(trim(b.feature_type)) = 'ARC')
	) AS incident_count_src,
	(SELECT count(*)::numeric FROM PARENT_SCHEMA.connec c WHERE c.arc_id = a.arc_id AND c.state = 1) AS dwf_raw_src,
	COALESCE(arc_add.max_flow, 0)::numeric AS storm_raw_src,
	a.dataquality AS data_quality_src,
	a.dataquality_obs::varchar[] AS data_quality_obs_src
FROM PARENT_SCHEMA.arc a
	JOIN PARENT_SCHEMA.vf_arc vf ON vf.arc_id = a.arc_id
	JOIN PARENT_SCHEMA.sector s ON s.sector_id = a.sector_id
	JOIN PARENT_SCHEMA.cat_arc cat ON cat.id::text = a.arccat_id::text
	LEFT JOIN PARENT_SCHEMA.arc_add ON arc_add.arc_id = a.arc_id
	LEFT JOIN am.v_ud_inspection_score ps ON ps.asset_type = 'ARC' AND ps.asset_id = a.arc_id::text
WHERE a.state = 1;

CREATE OR REPLACE VIEW am.ext_ud_node_asset AS
SELECT
	n.node_id::varchar(16) AS node_id,
	n.sector_id,
	s.macrosector_id,
	n.omzone_id::varchar AS drainzone_id,
	n.omzone_id::varchar AS presszone_id,
	n.builtdate,
	n.nodecat_id,
	cn.matcat_id,
	COALESCE(cn.node_type, n.epa_type) AS node_type,
	n.code,
	n.expl_id,
	n.dma_id,
	n.the_geom,
	CASE WHEN n.builtdate IS NULL THEN NULL
		ELSE EXTRACT(YEAR FROM age(CURRENT_DATE, n.builtdate))::numeric END AS age,
	COALESCE(ps.total_cost, 0)::numeric AS estimated_cost,
	COALESCE(ps.observation_count, 0)::integer AS observation_count,
	COALESCE(ps.severe_observation_count, 0)::integer AS severe_observation_count,
	(
		SELECT v.intervention
		FROM am.v_ud_node_pathology v
		WHERE v.node_id::text = n.node_id::text
		ORDER BY CASE v.intervention
			WHEN 'FULL_REPLACEMENT' THEN 4
			WHEN 'REHABILITATION' THEN 3
			WHEN 'SPOT_REPAIR' THEN 2
			ELSE 1
		END DESC
		LIMIT 1
	) AS recommended_action_src,
	COALESCE(
		ps.max_structural_score,
		CASE WHEN n.conserv_state::text ~ '^[1-5]$' THEN (6 - n.conserv_state::integer)::numeric ELSE NULL END
	) AS structural_raw_src,
	COALESCE(
		ps.max_operational_score,
		CASE WHEN n.om_state::text ~ '^[1-5]$' THEN (6 - n.om_state::integer)::numeric ELSE NULL END
	) AS operational_raw_src,
	(
		(SELECT count(*)::numeric FROM PARENT_SCHEMA.om_visit_x_node v WHERE v.node_id = n.node_id)
		+ (SELECT count(*)::numeric FROM am.ud_breakdown b
			WHERE b.feature_id::text = n.node_id::text AND upper(trim(b.feature_type)) = 'NODE')
	) AS incident_count_src,
	-- No node flow column on the UD parent. Missing values score 0 and count as incomplete.
	NULL::numeric AS dwf_raw_src,
	NULL::numeric AS storm_raw_src,
	n.dataquality AS data_quality_src,
	n.dataquality_obs::varchar[] AS data_quality_obs_src
FROM PARENT_SCHEMA.node n
	JOIN PARENT_SCHEMA.vf_node ON vf_node.node_id = n.node_id
	JOIN PARENT_SCHEMA.sector s ON s.sector_id = n.sector_id
	LEFT JOIN PARENT_SCHEMA.cat_node cn ON cn.id::text = n.nodecat_id::text
	LEFT JOIN am.v_ud_inspection_score ps ON ps.asset_type = 'NODE' AND ps.asset_id = n.node_id::text
WHERE n.state = 1;

SET search_path = am, public;

DROP VIEW IF EXISTS v_asset_ud_arc_input CASCADE;
CREATE VIEW v_asset_ud_arc_input AS
SELECT
	a.arc_id,
	COALESCE(i.age, a.age) AS age,
	COALESCE(i.incident_count, a.incident_count_src) AS incident_count,
	COALESCE(i.structural_raw, a.structural_raw_src) AS structural_raw,
	COALESCE(i.operational_raw, a.operational_raw_src) AS operational_raw,
	COALESCE(i.dwf_raw, a.dwf_raw_src) AS dwf_raw,
	COALESCE(i.storm_raw, a.storm_raw_src) AS storm_raw,
	i.strategic,
	i.compliance,
	COALESCE(i.mandatory, false) AS mandatory,
	COALESCE(i.data_quality, a.data_quality_src) AS data_quality,
	COALESCE(i.data_quality_obs, a.data_quality_obs_src) AS data_quality_obs,
	i.inspection_id,
	i.inspection_date,
	COALESCE(i.estimated_cost, a.estimated_cost) AS estimated_cost,
	a.observation_count,
	a.severe_observation_count,
	a.recommended_action_src,
	a.arccat_id,
	a.matcat_id,
	a.dnom,
	a.builtdate,
	a.function_type,
	a.expl_id,
	a.macrosector_id,
	a.sector_id,
	a.drainzone_id,
	a.presszone_id,
	a.dma_id,
	a.code,
	a.the_geom::geometry(MultiLineString, SRID_VALUE) AS the_geom
FROM ext_ud_arc_asset a
	LEFT JOIN ud_arc_input i USING (arc_id);

CREATE RULE v_asset_ud_arc_input_update AS ON UPDATE TO v_asset_ud_arc_input
DO INSTEAD
INSERT INTO ud_arc_input (arc_id, mandatory, strategic, incident_count,
	structural_raw, operational_raw, dwf_raw, storm_raw, compliance, estimated_cost,
	data_quality, data_quality_obs)
VALUES (NEW.arc_id, NEW.mandatory, NEW.strategic, NEW.incident_count,
	NEW.structural_raw, NEW.operational_raw, NEW.dwf_raw, NEW.storm_raw, NEW.compliance, NEW.estimated_cost,
	NEW.data_quality, NEW.data_quality_obs)
ON CONFLICT(arc_id) DO
UPDATE SET mandatory = EXCLUDED.mandatory,
	strategic = EXCLUDED.strategic,
	incident_count = EXCLUDED.incident_count,
	structural_raw = EXCLUDED.structural_raw,
	operational_raw = EXCLUDED.operational_raw,
	dwf_raw = EXCLUDED.dwf_raw,
	storm_raw = EXCLUDED.storm_raw,
	compliance = EXCLUDED.compliance,
	estimated_cost = EXCLUDED.estimated_cost,
	data_quality = EXCLUDED.data_quality,
	data_quality_obs = EXCLUDED.data_quality_obs;

DROP VIEW IF EXISTS v_asset_ud_node_input CASCADE;
CREATE VIEW v_asset_ud_node_input AS
SELECT
	a.node_id,
	COALESCE(i.age, a.age) AS age,
	COALESCE(i.incident_count, a.incident_count_src) AS incident_count,
	COALESCE(i.structural_raw, a.structural_raw_src) AS structural_raw,
	COALESCE(i.operational_raw, a.operational_raw_src) AS operational_raw,
	COALESCE(i.dwf_raw, a.dwf_raw_src) AS dwf_raw,
	COALESCE(i.storm_raw, a.storm_raw_src) AS storm_raw,
	i.strategic,
	i.compliance,
	COALESCE(i.mandatory, false) AS mandatory,
	COALESCE(i.data_quality, a.data_quality_src) AS data_quality,
	COALESCE(i.data_quality_obs, a.data_quality_obs_src) AS data_quality_obs,
	i.inspection_id,
	i.inspection_date,
	COALESCE(i.estimated_cost, a.estimated_cost) AS estimated_cost,
	a.observation_count,
	a.severe_observation_count,
	a.recommended_action_src,
	a.nodecat_id,
	a.node_type,
	a.builtdate,
	a.expl_id,
	a.macrosector_id,
	a.sector_id,
	a.drainzone_id,
	a.presszone_id,
	a.dma_id,
	a.code,
	a.the_geom
FROM ext_ud_node_asset a
	LEFT JOIN ud_node_input i USING (node_id);

CREATE RULE v_asset_ud_node_input_update AS ON UPDATE TO v_asset_ud_node_input
DO INSTEAD
INSERT INTO ud_node_input (node_id, mandatory, strategic, incident_count,
	structural_raw, operational_raw, dwf_raw, storm_raw, compliance, estimated_cost,
	data_quality, data_quality_obs)
VALUES (NEW.node_id, NEW.mandatory, NEW.strategic, NEW.incident_count,
	NEW.structural_raw, NEW.operational_raw, NEW.dwf_raw, NEW.storm_raw, NEW.compliance, NEW.estimated_cost,
	NEW.data_quality, NEW.data_quality_obs)
ON CONFLICT(node_id) DO
UPDATE SET mandatory = EXCLUDED.mandatory,
	strategic = EXCLUDED.strategic,
	incident_count = EXCLUDED.incident_count,
	structural_raw = EXCLUDED.structural_raw,
	operational_raw = EXCLUDED.operational_raw,
	dwf_raw = EXCLUDED.dwf_raw,
	storm_raw = EXCLUDED.storm_raw,
	compliance = EXCLUDED.compliance,
	estimated_cost = EXCLUDED.estimated_cost,
	data_quality = EXCLUDED.data_quality,
	data_quality_obs = EXCLUDED.data_quality_obs;

GRANT ALL ON TABLE am.ext_ud_arc_asset TO role_basic;
GRANT ALL ON TABLE am.ext_ud_node_asset TO role_basic;
GRANT ALL ON TABLE am.v_asset_ud_arc_input TO role_basic;
GRANT ALL ON TABLE am.v_asset_ud_node_input TO role_basic;
GRANT ALL ON TABLE am.v_ud_arc_pathology TO role_basic;
GRANT ALL ON TABLE am.v_ud_node_pathology TO role_basic;
GRANT ALL ON TABLE am.v_ud_inspection_score TO role_basic;

INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES
('ud_cat_pathology', 'EN 13508-2 pathology catalog', 'role_om', NULL, '37', 5, 'UD pathology catalog', NULL, NULL, NULL, 'am', NULL),
('ud_arc_pathology', 'CCTV pathologies per UD arc', 'role_om', NULL, '35', 8, 'UD arc pathologies', NULL, NULL, NULL, 'am', NULL),
('v_ud_arc_pathology', 'UD arc pathologies with cost and AWARE score', 'role_om', NULL, '35', 9, 'UD arc pathology calc', NULL, NULL, NULL, 'am', NULL),
('ud_node_pathology', 'CCTV pathologies per UD node', 'role_om', NULL, '36', 8, 'UD node pathologies', NULL, NULL, NULL, 'am', NULL),
('v_ud_node_pathology', 'UD node pathologies with cost and AWARE score', 'role_om', NULL, '36', 9, 'UD node pathology calc', NULL, NULL, NULL, 'am', NULL),
('v_ud_arc_am', 'UD arc condition, cost and observation summary', 'role_om', NULL, '35', 10, 'UD arc AM', NULL, NULL, NULL, 'am', NULL),
('v_ud_node_am', 'UD node condition, cost and observation summary', 'role_om', NULL, '36', 10, 'UD node AM', NULL, NULL, NULL, 'am', NULL),
('ud_breakdown', 'UD breakdowns by feature', 'role_om', NULL, '35', 11, 'UD breakdowns', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;

-- Write BA/BB scores back to parent conserv_state / om_state (1=Critical … 5=Excellent).
CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_am_ud_arc_pathology()
RETURNS trigger AS
$BODY$
DECLARE
	v_arc_id varchar(16);
	v_cond numeric;
	v_om numeric;
	v_total numeric;
	v_inspection_id bigint;
	v_inspection_date date;
BEGIN
	v_arc_id := COALESCE(NEW.arc_id, OLD.arc_id);
	SELECT
		COALESCE(max_structural_score, 1),
		COALESCE(max_operational_score, 1),
		COALESCE(total_cost, 0)
	INTO v_cond, v_om, v_total
	FROM am.v_ud_inspection_score
	WHERE asset_type = 'ARC' AND asset_id = v_arc_id::text;

	IF v_cond IS NULL AND v_om IS NULL THEN
		v_cond := 1;
		v_om := 1;
		v_total := 0;
	END IF;

	SELECT inspection_id, inspection_date INTO v_inspection_id, v_inspection_date
	FROM am.ud_arc_pathology
	WHERE arc_id = v_arc_id AND COALESCE(active, true)
	ORDER BY inspection_date DESC NULLS LAST, rid DESC LIMIT 1;

	UPDATE PARENT_SCHEMA.arc SET
		conserv_state = GREATEST(1, LEAST(5, ROUND(6 - COALESCE(v_cond, 1)))),
		om_state = GREATEST(1, LEAST(5, ROUND(6 - COALESCE(v_om, 1))))
	WHERE arc_id::text = v_arc_id;

	INSERT INTO am.ud_arc_input (
		arc_id, structural_raw, operational_raw, estimated_cost, inspection_id, inspection_date
	)
	VALUES (v_arc_id, v_cond, v_om, v_total, v_inspection_id, v_inspection_date)
	ON CONFLICT (arc_id) DO UPDATE SET
		structural_raw = EXCLUDED.structural_raw,
		operational_raw = EXCLUDED.operational_raw,
		estimated_cost = EXCLUDED.estimated_cost,
		inspection_id = EXCLUDED.inspection_id,
		inspection_date = EXCLUDED.inspection_date;

	RETURN COALESCE(NEW, OLD);
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

DROP TRIGGER IF EXISTS gw_trg_am_ud_arc_pathology ON am.ud_arc_pathology;
CREATE TRIGGER gw_trg_am_ud_arc_pathology
AFTER INSERT OR UPDATE OR DELETE ON am.ud_arc_pathology
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_am_ud_arc_pathology();

CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_am_ud_node_pathology()
RETURNS trigger AS
$BODY$
DECLARE
	v_node_id varchar(16);
	v_cond numeric;
	v_om numeric;
	v_total numeric;
	v_inspection_id bigint;
	v_inspection_date date;
BEGIN
	v_node_id := COALESCE(NEW.node_id, OLD.node_id);
	SELECT
		COALESCE(max_structural_score, 1),
		COALESCE(max_operational_score, 1),
		COALESCE(total_cost, 0)
	INTO v_cond, v_om, v_total
	FROM am.v_ud_inspection_score
	WHERE asset_type = 'NODE' AND asset_id = v_node_id::text;

	IF v_cond IS NULL AND v_om IS NULL THEN
		v_cond := 1;
		v_om := 1;
		v_total := 0;
	END IF;

	SELECT inspection_id, inspection_date INTO v_inspection_id, v_inspection_date
	FROM am.ud_node_pathology
	WHERE node_id = v_node_id AND COALESCE(active, true)
	ORDER BY inspection_date DESC NULLS LAST, rid DESC LIMIT 1;

	UPDATE PARENT_SCHEMA.node SET
		conserv_state = GREATEST(1, LEAST(5, ROUND(6 - COALESCE(v_cond, 1)))),
		om_state = GREATEST(1, LEAST(5, ROUND(6 - COALESCE(v_om, 1))))
	WHERE node_id::text = v_node_id;

	INSERT INTO am.ud_node_input (node_id, structural_raw, operational_raw, estimated_cost, inspection_id, inspection_date)
	VALUES (v_node_id, v_cond, v_om, v_total, v_inspection_id, v_inspection_date)
	ON CONFLICT (node_id) DO UPDATE SET
		structural_raw = EXCLUDED.structural_raw,
		operational_raw = EXCLUDED.operational_raw,
		estimated_cost = EXCLUDED.estimated_cost,
		inspection_id = EXCLUDED.inspection_id,
		inspection_date = EXCLUDED.inspection_date;

	RETURN COALESCE(NEW, OLD);
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

DROP TRIGGER IF EXISTS gw_trg_am_ud_node_pathology ON am.ud_node_pathology;
CREATE TRIGGER gw_trg_am_ud_node_pathology
AFTER INSERT OR UPDATE OR DELETE ON am.ud_node_pathology
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_am_ud_node_pathology();

-- One row per arc: condition, cost, observation counts. TOC layer, not an info-form tab.
CREATE OR REPLACE VIEW am.v_ud_arc_am AS
SELECT
	a.arc_id,
	s.max_structural_score AS cond_state,
	s.max_operational_score AS om_state,
	s.total_cost,
	s.observation_count,
	s.severe_observation_count,
	a.the_geom
FROM PARENT_SCHEMA.arc a
LEFT JOIN am.v_ud_inspection_score s ON s.asset_type = 'ARC' AND s.asset_id = a.arc_id::text
WHERE a.state = 1;

CREATE OR REPLACE VIEW am.v_ud_node_am AS
SELECT
	n.node_id,
	s.max_structural_score AS cond_state,
	s.max_operational_score AS om_state,
	s.total_cost,
	s.observation_count,
	s.severe_observation_count,
	n.the_geom
FROM PARENT_SCHEMA.node n
LEFT JOIN am.v_ud_inspection_score s ON s.asset_type = 'NODE' AND s.asset_id = n.node_id::text
WHERE n.state = 1;

GRANT ALL ON TABLE am.v_ud_arc_am TO role_basic;
GRANT ALL ON TABLE am.v_ud_node_am TO role_basic;

INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_output_compare', 'id', 'role_om', NULL, '35', 7, 'UD Arc Result - Compare', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_output', 'id', 'role_om', NULL, '35', 6, 'UD Arc Result - Main', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_corporate', 'id', 'role_om', NULL, '35', 5, 'UD Arc Corporate Assets', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('ud_arc_output', 'id', 'role_om', NULL, '35', 4, 'UD Arc Assets Result', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_input', 'id', 'role_om', NULL, '35', 3, 'UD Arc Input Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('ext_ud_arc_asset', 'id', 'role_om', NULL, '35', 1, 'UD Existing Arc Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;

INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_output_compare', 'id', 'role_om', NULL, '36', 5, 'UD Node Result - Compare', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_output', 'id', 'role_om', NULL, '36', 4, 'UD Node Result - Main', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_corporate', 'id', 'role_om', NULL, '36', 3, 'UD Node Corporate Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_input', 'id', 'role_om', NULL, '36', 2, 'UD Node Input Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('ext_ud_node_asset', 'id', 'role_om', NULL, '36', 1, 'UD Existing Node Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;

-- Reuse WS QML if this AM was already integrated with WS; otherwise layers load unstyled.
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_arc_output', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'v_asset_ws_arc_output' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_arc_output_compare', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'v_asset_ws_arc_output_compare' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_arc_corporate', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'v_asset_ws_arc_corporate' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'ext_ud_arc_asset', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'ext_ws_arc_asset' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_node_output', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername IN ('v_asset_ws_node_output', 'v_asset_ws_arc_output') AND styleconfig_id = 101
ORDER BY CASE WHEN layername = 'v_asset_ws_node_output' THEN 0 ELSE 1 END
LIMIT 1
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_node_output_compare', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername IN ('v_asset_ws_node_output_compare', 'v_asset_ws_arc_output_compare') AND styleconfig_id = 101
ORDER BY CASE WHEN layername = 'v_asset_ws_node_output_compare' THEN 0 ELSE 1 END
LIMIT 1
ON CONFLICT (layername, styleconfig_id) DO NOTHING;

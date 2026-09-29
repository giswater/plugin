/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public;

ALTER TABLE am.ud_node_input ADD COLUMN IF NOT EXISTS inspection_id bigint;
ALTER TABLE am.ud_node_input ADD COLUMN IF NOT EXISTS inspection_date date;

ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS recommended_action varchar(30);
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS intervention_type varchar(30);
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS recommended_inspection_year integer;
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS inspection_priority integer;
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS inspection_reason varchar[];
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS calculation_completeness numeric(5,2);
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS missing_criteria varchar[];
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS inspection_id bigint;
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS calculation_date timestamp DEFAULT now();

ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS recommended_action varchar(30);
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS intervention_type varchar(30);
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS recommended_inspection_year integer;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS inspection_priority integer;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS inspection_reason varchar[];
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS calculation_completeness numeric(5,2);
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS missing_criteria varchar[];
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS inspection_id bigint;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS calculation_date timestamp DEFAULT now();

CREATE TABLE IF NOT EXISTS am.ud_node_pathology (
    rid bigserial PRIMARY KEY,
    node_id int4 NOT NULL,
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
    feature_id int4,
    feature_type varchar(16),
    "date" date,
    breakdown_type varchar(50),
    the_geom public.geometry(Point)
);
CREATE INDEX IF NOT EXISTS idx_ud_breakdown_feature ON am.ud_breakdown (feature_type, feature_id);

GRANT ALL ON TABLE am.ud_node_pathology TO role_basic;
GRANT ALL ON TABLE am.ud_breakdown TO role_basic;

CREATE OR REPLACE VIEW am.v_asset_ud_arc_output AS
 SELECT o.arc_id, o.result_id, o.sector_id, o.macrosector_id, o.drainzone_id, o.presszone_id,
    o.builtdate, o.arccat_id, o.dnom, o.matcat_id, o.function_type, o.code, o.expl_id, o.dma_id,
    o.longevity, o.incident_history, o.structural_condition, o.operational_condition,
    o.dwf, o.storm, o.strategic, o.mandatory, o.compliance, o.val, o.orderby, o.selected,
    o.expected_year, o.replacement_year, o.budget, o.total, o.estimated_cost, o.length,
    o.comments, o.data_quality_class, o.the_geom,
    o.recommended_action, o.intervention_type, o.recommended_inspection_year,
    o.inspection_priority, o.inspection_reason, o.calculation_completeness,
    o.missing_criteria, o.inspection_id, o.calculation_date
   FROM am.ud_arc_output o
     JOIN am.selector_result_main s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_ud_arc_output_compare AS
 SELECT o.arc_id, o.result_id, o.sector_id, o.macrosector_id, o.drainzone_id, o.presszone_id,
    o.builtdate, o.arccat_id, o.dnom, o.matcat_id, o.function_type, o.code, o.expl_id, o.dma_id,
    o.longevity, o.incident_history, o.structural_condition, o.operational_condition,
    o.dwf, o.storm, o.strategic, o.mandatory, o.compliance, o.val, o.orderby, o.selected,
    o.expected_year, o.replacement_year, o.budget, o.total, o.estimated_cost, o.length,
    o.comments, o.data_quality_class, o.the_geom,
    o.recommended_action, o.intervention_type, o.recommended_inspection_year,
    o.inspection_priority, o.inspection_reason, o.calculation_completeness,
    o.missing_criteria, o.inspection_id, o.calculation_date
   FROM am.ud_arc_output o
     JOIN am.selector_result_compare s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_ud_arc_corporate AS
 SELECT o.arc_id, o.result_id, o.sector_id, o.macrosector_id, o.drainzone_id, o.presszone_id,
    o.builtdate, o.arccat_id, o.dnom, o.matcat_id, o.function_type, o.code, o.expl_id, o.dma_id,
    o.longevity, o.incident_history, o.structural_condition, o.operational_condition,
    o.dwf, o.storm, o.strategic, o.mandatory, o.compliance, o.val, o.orderby, o.selected,
    o.expected_year, o.replacement_year, o.budget, o.total, o.estimated_cost, o.length,
    o.comments, o.data_quality_class, o.the_geom,
    o.recommended_action, o.intervention_type, o.recommended_inspection_year,
    o.inspection_priority, o.inspection_reason, o.calculation_completeness,
    o.missing_criteria, o.inspection_id, o.calculation_date
   FROM am.ud_arc_output o
     JOIN am.cat_result r ON r.result_id = o.result_id
  WHERE r.iscorporate = TRUE;

CREATE OR REPLACE VIEW am.v_asset_ud_node_output AS
 SELECT o.node_id, o.result_id, o.sector_id, o.macrosector_id, o.drainzone_id, o.presszone_id,
    o.builtdate, o.nodecat_id, o.node_type, o.code, o.expl_id, o.dma_id,
    o.longevity, o.incident_history, o.structural_condition, o.operational_condition,
    o.dwf, o.storm, o.strategic, o.mandatory, o.compliance, o.val, o.orderby, o.selected,
    o.expected_year, o.replacement_year, o.budget, o.total, o.estimated_cost,
    o.comments, o.data_quality_class, o.the_geom,
    o.recommended_action, o.intervention_type, o.recommended_inspection_year,
    o.inspection_priority, o.inspection_reason, o.calculation_completeness,
    o.missing_criteria, o.inspection_id, o.calculation_date
   FROM am.ud_node_output o
     JOIN am.selector_result_main s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_ud_node_output_compare AS
 SELECT o.node_id, o.result_id, o.sector_id, o.macrosector_id, o.drainzone_id, o.presszone_id,
    o.builtdate, o.nodecat_id, o.node_type, o.code, o.expl_id, o.dma_id,
    o.longevity, o.incident_history, o.structural_condition, o.operational_condition,
    o.dwf, o.storm, o.strategic, o.mandatory, o.compliance, o.val, o.orderby, o.selected,
    o.expected_year, o.replacement_year, o.budget, o.total, o.estimated_cost,
    o.comments, o.data_quality_class, o.the_geom,
    o.recommended_action, o.intervention_type, o.recommended_inspection_year,
    o.inspection_priority, o.inspection_reason, o.calculation_completeness,
    o.missing_criteria, o.inspection_id, o.calculation_date
   FROM am.ud_node_output o
     JOIN am.selector_result_compare s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_ud_node_corporate AS
 SELECT o.node_id, o.result_id, o.sector_id, o.macrosector_id, o.drainzone_id, o.presszone_id,
    o.builtdate, o.nodecat_id, o.node_type, o.code, o.expl_id, o.dma_id,
    o.longevity, o.incident_history, o.structural_condition, o.operational_condition,
    o.dwf, o.storm, o.strategic, o.mandatory, o.compliance, o.val, o.orderby, o.selected,
    o.expected_year, o.replacement_year, o.budget, o.total, o.estimated_cost,
    o.comments, o.data_quality_class, o.the_geom,
    o.recommended_action, o.intervention_type, o.recommended_inspection_year,
    o.inspection_priority, o.inspection_reason, o.calculation_completeness,
    o.missing_criteria, o.inspection_id, o.calculation_date
   FROM am.ud_node_output o
     JOIN am.cat_result r ON r.result_id = o.result_id
  WHERE r.iscorporate = TRUE;

-- Node CCTV view, score union, breakdown counts and triggers when a UD parent is already linked.
DO $$
DECLARE
	v_parent text;
BEGIN
	SELECT NULLIF(btrim(addparam->>'parentSchema'), '') INTO v_parent
	FROM am.sys_version ORDER BY id DESC LIMIT 1;
	IF v_parent IS NULL OR to_regclass(format('%I.node', v_parent)) IS NULL THEN
		RETURN;
	END IF;

	EXECUTE format($sql$
		CREATE OR REPLACE VIEW am.v_ud_node_pathology AS
		SELECT p.rid, p.node_id, p.pathology_id, c.code, c.name, c.name_es, c.pathology_group,
			p.severity, p.inspection_id, p.inspection_date, p.observation, p.active,
			am.gw_fct_am_ud_intervention(p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5) AS intervention,
			CASE WHEN am.gw_fct_am_ud_intervention(p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5) = 'MAINTENANCE' THEN NULL
			ELSE p.severity::numeric END AS aware_score,
			am.gw_fct_am_ud_defect_cost(
				am.gw_fct_am_ud_intervention(p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5),
				0, cat.cost_repmain, cat.cost_rehab, cat.cost_constr
			) AS calculated_cost
		FROM am.ud_node_pathology p
		JOIN am.ud_cat_pathology c ON c.pathology_id = p.pathology_id
		JOIN %1$I.node n ON n.node_id = p.node_id
		LEFT JOIN am.config_nodecatalog_def cat ON cat.nodecat_id = n.nodecat_id
		WHERE COALESCE(p.active, true) IS TRUE AND COALESCE(c.active, true) IS TRUE
	$sql$, v_parent);

	CREATE OR REPLACE VIEW am.v_ud_inspection_score AS
	SELECT 'ARC'::text AS asset_type, v.arc_id::text AS asset_id,
		COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BA'), 1)::numeric AS max_structural_score,
		COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BB'), 1)::numeric AS max_operational_score,
		count(*)::integer AS observation_count,
		count(*) FILTER (WHERE v.severity >= 4)::integer AS severe_observation_count,
		COALESCE(sum(v.calculated_cost), 0)::numeric AS total_cost
	FROM am.v_ud_arc_pathology v
	GROUP BY v.arc_id
	UNION ALL
	SELECT 'NODE'::text, v.node_id::text,
		COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BA'), 1)::numeric,
		COALESCE(max(v.aware_score) FILTER (WHERE v.pathology_group = 'BB'), 1)::numeric,
		count(*)::integer,
		count(*) FILTER (WHERE v.severity >= 4)::integer,
		COALESCE(sum(v.calculated_cost), 0)::numeric
	FROM am.v_ud_node_pathology v
	GROUP BY v.node_id;

	EXECUTE format($sql$
		CREATE OR REPLACE VIEW am.v_ud_arc_am AS
		SELECT a.arc_id,
			s.max_structural_score AS cond_state,
			s.max_operational_score AS om_state,
			s.total_cost,
			s.observation_count,
			s.severe_observation_count,
			a.the_geom
		FROM %1$I.arc a
		LEFT JOIN am.v_ud_inspection_score s ON s.asset_type = 'ARC' AND s.asset_id = a.arc_id::text
		WHERE a.state = 1
	$sql$, v_parent);

	EXECUTE format($sql$
		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
		VALUES
		('ud_node_pathology', 'CCTV pathologies per UD node', 'role_om', NULL, '36', 8, 'UD node pathologies', NULL, NULL, NULL, 'am', NULL),
		('v_ud_node_pathology', 'UD node pathologies with cost and AWARE score', 'role_om', NULL, '36', 9, 'UD node pathology calc', NULL, NULL, NULL, 'am', NULL),
		('v_ud_arc_am', 'UD arc condition, cost and observation summary', 'role_om', NULL, '35', 10, 'UD arc AM', NULL, NULL, NULL, 'am', NULL),
		('ud_breakdown', 'UD breakdowns by feature', 'role_om', NULL, '35', 11, 'UD breakdowns', NULL, NULL, NULL, 'am', NULL)
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source
	$sql$, v_parent);

	GRANT ALL ON TABLE am.v_ud_node_pathology TO role_basic;
	GRANT ALL ON TABLE am.v_ud_inspection_score TO role_basic;
	GRANT ALL ON TABLE am.v_ud_arc_am TO role_basic;

	EXECUTE format($sql$
		CREATE OR REPLACE FUNCTION %1$I.gw_trg_am_ud_node_pathology()
		RETURNS trigger AS $body$
		DECLARE
			v_node_id integer;
			v_cond numeric;
			v_om numeric;
		BEGIN
			v_node_id := COALESCE(NEW.node_id, OLD.node_id);
			SELECT COALESCE(max_structural_score, 1), COALESCE(max_operational_score, 1)
			INTO v_cond, v_om
			FROM am.v_ud_inspection_score
			WHERE asset_type = 'NODE' AND asset_id = v_node_id::text;
			IF v_cond IS NULL AND v_om IS NULL THEN
				RETURN COALESCE(NEW, OLD);
			END IF;
			UPDATE %1$I.node SET
				conserv_state = GREATEST(1, LEAST(5, ROUND(6 - COALESCE(v_cond, 1)))),
				om_state = GREATEST(1, LEAST(5, ROUND(6 - COALESCE(v_om, 1))))
			WHERE node_id = v_node_id;
			INSERT INTO am.ud_node_input (node_id, structural_raw, operational_raw, estimated_cost, inspection_id, inspection_date)
			SELECT v_node_id, v_cond, v_om, s.total_cost,
				COALESCE(NEW.inspection_id, OLD.inspection_id),
				COALESCE(NEW.inspection_date, OLD.inspection_date)
			FROM am.v_ud_inspection_score s
			WHERE s.asset_type = 'NODE' AND s.asset_id = v_node_id::text
			ON CONFLICT (node_id) DO UPDATE SET
				structural_raw = EXCLUDED.structural_raw,
				operational_raw = EXCLUDED.operational_raw,
				estimated_cost = EXCLUDED.estimated_cost,
				inspection_id = COALESCE(EXCLUDED.inspection_id, am.ud_node_input.inspection_id),
				inspection_date = COALESCE(EXCLUDED.inspection_date, am.ud_node_input.inspection_date);
			RETURN COALESCE(NEW, OLD);
		END;
		$body$ LANGUAGE plpgsql VOLATILE;
		DROP TRIGGER IF EXISTS gw_trg_am_ud_node_pathology ON am.ud_node_pathology;
		CREATE TRIGGER gw_trg_am_ud_node_pathology
		AFTER INSERT OR UPDATE OR DELETE ON am.ud_node_pathology
		FOR EACH ROW EXECUTE PROCEDURE %1$I.gw_trg_am_ud_node_pathology();
	$sql$, v_parent);
END $$;

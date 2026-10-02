/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public;

-- Early Stage 4 builds used integer UD identifiers. Preserve dependent views,
-- rules, triggers and grants while converting those work tables in place.
DO $$
DECLARE
	rec record;
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_schema = 'am'
			AND table_name IN (
				'ud_arc_input', 'ud_arc_engine_wm', 'ud_arc_output', 'ud_arc_pathology',
				'ud_node_input', 'ud_node_engine_wm', 'ud_node_output', 'ud_node_pathology',
				'ud_breakdown'
			)
			AND column_name IN ('arc_id', 'node_id', 'feature_id')
			AND data_type IN ('smallint', 'integer', 'bigint')
	) THEN
		RETURN;
	END IF;

	CREATE TEMP TABLE am_ud_migration_views (
		view_oid oid PRIMARY KEY,
		depth integer NOT NULL,
		schema_name text NOT NULL,
		view_name text NOT NULL,
		view_definition text NOT NULL,
		owner_name text NOT NULL,
		view_comment text
	) ON COMMIT DROP;
	CREATE TEMP TABLE am_ud_migration_rules (
		view_oid oid NOT NULL,
		rule_definition text NOT NULL
	) ON COMMIT DROP;
	CREATE TEMP TABLE am_ud_migration_triggers (
		view_oid oid NOT NULL,
		trigger_definition text NOT NULL
	) ON COMMIT DROP;
	CREATE TEMP TABLE am_ud_migration_grants (
		view_oid oid NOT NULL,
		grant_definition text NOT NULL
	) ON COMMIT DROP;

	WITH RECURSIVE target_relations AS (
		SELECT c.oid
		FROM pg_class c
		JOIN pg_namespace n ON n.oid = c.relnamespace
		WHERE n.nspname = 'am'
			AND c.relname IN (
				'ud_arc_input', 'ud_arc_engine_wm', 'ud_arc_output', 'ud_arc_pathology',
				'ud_node_input', 'ud_node_engine_wm', 'ud_node_output', 'ud_node_pathology',
				'ud_breakdown'
			)
	), dependent_views AS (
		SELECT view_class.oid AS view_oid, 1 AS depth
		FROM target_relations target
		JOIN pg_depend dependency ON dependency.refobjid = target.oid
		JOIN pg_rewrite rewrite ON rewrite.oid = dependency.objid
		JOIN pg_class view_class ON view_class.oid = rewrite.ev_class
		WHERE view_class.relkind = 'v'
		UNION ALL
		SELECT view_class.oid, dependent.depth + 1
		FROM dependent_views dependent
		JOIN pg_depend dependency ON dependency.refobjid = dependent.view_oid
		JOIN pg_rewrite rewrite ON rewrite.oid = dependency.objid
		JOIN pg_class view_class ON view_class.oid = rewrite.ev_class
		WHERE view_class.relkind = 'v'
			AND view_class.oid <> dependent.view_oid
	)
	INSERT INTO am_ud_migration_views (
		view_oid, depth, schema_name, view_name, view_definition,
		owner_name, view_comment
	)
	SELECT
		view_class.oid,
		max(dependent.depth),
		namespace.nspname,
		view_class.relname,
		pg_get_viewdef(view_class.oid, true),
		pg_get_userbyid(view_class.relowner),
		obj_description(view_class.oid, 'pg_class')
	FROM dependent_views dependent
	JOIN pg_class view_class ON view_class.oid = dependent.view_oid
	JOIN pg_namespace namespace ON namespace.oid = view_class.relnamespace
	GROUP BY view_class.oid, namespace.nspname, view_class.relname;

	INSERT INTO am_ud_migration_rules (view_oid, rule_definition)
	SELECT saved.view_oid, pg_get_ruledef(rewrite.oid, true)
	FROM am_ud_migration_views saved
	JOIN pg_rewrite rewrite ON rewrite.ev_class = saved.view_oid
	WHERE rewrite.rulename <> '_RETURN';

	INSERT INTO am_ud_migration_triggers (view_oid, trigger_definition)
	SELECT saved.view_oid, pg_get_triggerdef(trigger.oid, true)
	FROM am_ud_migration_views saved
	JOIN pg_trigger trigger ON trigger.tgrelid = saved.view_oid
	WHERE trigger.tgisinternal IS FALSE;

	INSERT INTO am_ud_migration_grants (view_oid, grant_definition)
	SELECT
		saved.view_oid,
		format(
			'GRANT %s ON TABLE %I.%I TO %s%s',
			acl.privilege_type,
			saved.schema_name,
			saved.view_name,
			CASE
				WHEN acl.grantee = 0 THEN 'PUBLIC'
				ELSE quote_ident(pg_get_userbyid(acl.grantee))
			END,
			CASE WHEN acl.is_grantable THEN ' WITH GRANT OPTION' ELSE '' END
		)
	FROM am_ud_migration_views saved
	JOIN pg_class view_class ON view_class.oid = saved.view_oid
	CROSS JOIN LATERAL aclexplode(view_class.relacl) acl;

	FOR rec IN
		SELECT * FROM am_ud_migration_views ORDER BY depth DESC, schema_name, view_name
	LOOP
		EXECUTE format('DROP VIEW %I.%I', rec.schema_name, rec.view_name);
	END LOOP;

	FOR rec IN
		SELECT *
		FROM (VALUES
			('ud_arc_input', 'arc_id'),
			('ud_arc_engine_wm', 'arc_id'),
			('ud_arc_output', 'arc_id'),
			('ud_arc_pathology', 'arc_id'),
			('ud_node_input', 'node_id'),
			('ud_node_engine_wm', 'node_id'),
			('ud_node_output', 'node_id'),
			('ud_node_pathology', 'node_id'),
			('ud_breakdown', 'feature_id')
		) AS columns_to_migrate(table_name, column_name)
	LOOP
		IF EXISTS (
			SELECT 1
			FROM information_schema.columns column_def
			WHERE column_def.table_schema = 'am'
				AND column_def.table_name = rec.table_name
				AND column_def.column_name = rec.column_name
				AND column_def.data_type IN ('smallint', 'integer', 'bigint')
		) THEN
			EXECUTE format(
				'ALTER TABLE am.%I ALTER COLUMN %I TYPE varchar(16) USING %I::text',
				rec.table_name, rec.column_name, rec.column_name
			);
		END IF;
	END LOOP;

	-- A saved view that compared integer parent ids to these columns cannot be
	-- created again after the varchar cast. Skip it; the block below rebuilds
	-- the UD inventory and pathology views with explicit ::text comparisons.
	FOR rec IN
		SELECT * FROM am_ud_migration_views ORDER BY depth, schema_name, view_name
	LOOP
		BEGIN
			EXECUTE format('CREATE VIEW %I.%I AS ', rec.schema_name, rec.view_name) || rec.view_definition;
			IF rec.view_comment IS NOT NULL THEN
				EXECUTE format(
					'COMMENT ON VIEW %I.%I IS %L',
					rec.schema_name, rec.view_name, rec.view_comment
				);
			END IF;
		EXCEPTION WHEN OTHERS THEN
			RAISE WARNING 'am 4.17.1 left view %.% dropped: %', rec.schema_name, rec.view_name, SQLERRM;
		END;
	END LOOP;

	FOR rec IN SELECT * FROM am_ud_migration_rules ORDER BY view_oid LOOP
		BEGIN
			EXECUTE rec.rule_definition;
		EXCEPTION WHEN OTHERS THEN
			RAISE WARNING 'am 4.17.1 skipped a view rule: %', SQLERRM;
		END;
	END LOOP;
	FOR rec IN SELECT * FROM am_ud_migration_triggers ORDER BY view_oid LOOP
		BEGIN
			EXECUTE rec.trigger_definition;
		EXCEPTION WHEN OTHERS THEN
			RAISE WARNING 'am 4.17.1 skipped a view trigger: %', SQLERRM;
		END;
	END LOOP;
	FOR rec IN SELECT * FROM am_ud_migration_grants ORDER BY view_oid LOOP
		BEGIN
			EXECUTE rec.grant_definition;
		EXCEPTION WHEN OTHERS THEN
			RAISE WARNING 'am 4.17.1 skipped a view grant: %', SQLERRM;
		END;
	END LOOP;
	FOR rec IN SELECT * FROM am_ud_migration_views ORDER BY depth, schema_name, view_name LOOP
		BEGIN
			EXECUTE format(
				'ALTER VIEW %I.%I OWNER TO %I',
				rec.schema_name, rec.view_name, rec.owner_name
			);
		EXCEPTION WHEN OTHERS THEN
			RAISE WARNING 'am 4.17.1 skipped owner of %.%: %', rec.schema_name, rec.view_name, SQLERRM;
		END;
	END LOOP;
END $$;

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
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS inspection_date date;
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS observation_count integer;
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS severe_observation_count integer;
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS data_quality integer;
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS data_quality_obs varchar[];
ALTER TABLE am.ud_arc_output ADD COLUMN IF NOT EXISTS calculation_date timestamp DEFAULT now();

ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS recommended_action varchar(30);
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS intervention_type varchar(30);
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS recommended_inspection_year integer;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS inspection_priority integer;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS inspection_reason varchar[];
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS calculation_completeness numeric(5,2);
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS missing_criteria varchar[];
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS inspection_id bigint;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS inspection_date date;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS observation_count integer;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS severe_observation_count integer;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS data_quality integer;
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS data_quality_obs varchar[];
ALTER TABLE am.ud_node_output ADD COLUMN IF NOT EXISTS calculation_date timestamp DEFAULT now();

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

CREATE OR REPLACE VIEW am.v_asset_ud_arc_output AS
 SELECT o.arc_id, o.result_id, o.sector_id, o.macrosector_id, o.drainzone_id, o.presszone_id,
    o.builtdate, o.arccat_id, o.dnom, o.matcat_id, o.function_type, o.code, o.expl_id, o.dma_id,
    o.longevity, o.incident_history, o.structural_condition, o.operational_condition,
    o.dwf, o.storm, o.strategic, o.mandatory, o.compliance, o.val, o.orderby, o.selected,
    o.expected_year, o.replacement_year, o.budget, o.total, o.estimated_cost, o.length,
    o.comments, o.data_quality_class, o.the_geom,
    o.recommended_action, o.intervention_type, o.recommended_inspection_year,
    o.inspection_priority, o.inspection_reason, o.calculation_completeness,
    o.missing_criteria, o.inspection_id, o.calculation_date, o.inspection_date,
    o.observation_count, o.severe_observation_count, o.data_quality, o.data_quality_obs
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
    o.missing_criteria, o.inspection_id, o.calculation_date, o.inspection_date,
    o.observation_count, o.severe_observation_count, o.data_quality, o.data_quality_obs
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
    o.missing_criteria, o.inspection_id, o.calculation_date, o.inspection_date,
    o.observation_count, o.severe_observation_count, o.data_quality, o.data_quality_obs
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
    o.missing_criteria, o.inspection_id, o.calculation_date, o.inspection_date,
    o.observation_count, o.severe_observation_count, o.data_quality, o.data_quality_obs
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
    o.missing_criteria, o.inspection_id, o.calculation_date, o.inspection_date,
    o.observation_count, o.severe_observation_count, o.data_quality, o.data_quality_obs
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
    o.missing_criteria, o.inspection_id, o.calculation_date, o.inspection_date,
    o.observation_count, o.severe_observation_count, o.data_quality, o.data_quality_obs
   FROM am.ud_node_output o
     JOIN am.cat_result r ON r.result_id = o.result_id
  WHERE r.iscorporate = TRUE;

-- Node CCTV view, score union, breakdown counts and triggers when a UD parent is already linked.
DO $$
DECLARE
	v_parent text;
	v_srid integer;
BEGIN
	SELECT NULLIF(btrim(v.addparam->>'parentSchema'), '') INTO v_parent
	FROM am.sys_version v
	WHERE EXISTS (
		SELECT 1
		FROM information_schema.columns c
		WHERE c.table_schema = v.addparam->>'parentSchema'
			AND c.table_name = 'cat_arc'
			AND c.column_name = 'geom1'
	)
	ORDER BY v.id DESC LIMIT 1;
	IF v_parent IS NULL OR to_regclass(format('%I.node', v_parent)) IS NULL THEN
		RETURN;
	END IF;

	-- 4.17.0 created this view with integer = varchar joins. Replace it in place.
	EXECUTE format($sql$
		CREATE OR REPLACE VIEW am.v_ud_arc_pathology AS
		SELECT p.rid, p.arc_id, p.pathology_id, c.code, c.name, c.name_es, c.pathology_group,
			p.severity, p.pk_start, p.pk_end, p.pk, p.clock_start, p.clock_end,
			p.inspection_id, p.inspection_date, p.observation, p.active,
			am.gw_fct_am_ud_extent_m(p.pk_start, p.pk_end, p.pk) AS extent_m,
			ST_Length(a.the_geom)::numeric AS arc_length,
			am.gw_fct_am_ud_intervention(p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5) AS intervention,
			CASE WHEN am.gw_fct_am_ud_intervention(p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5) = 'MAINTENANCE' THEN NULL
			ELSE am.gw_fct_am_ud_observation_score(p.severity, am.gw_fct_am_ud_extent_m(p.pk_start, p.pk_end, p.pk), ST_Length(a.the_geom)::numeric) END AS aware_score,
			am.gw_fct_am_ud_defect_cost(
				am.gw_fct_am_ud_intervention(p.severity, c.intervention_s1, c.intervention_s2, c.intervention_s3, c.intervention_s4, c.intervention_s5),
				am.gw_fct_am_ud_extent_m(p.pk_start, p.pk_end, p.pk), cat.cost_repmain, cat.cost_rehab, cat.cost_constr
			) AS calculated_cost
		FROM am.ud_arc_pathology p
		JOIN am.ud_cat_pathology c ON c.pathology_id = p.pathology_id
		JOIN %1$I.arc a ON a.arc_id::text = p.arc_id::text
		LEFT JOIN am.config_catalog_def cat ON cat.arccat_id = a.arccat_id::text AND cat.project_type = 'UD'
		WHERE COALESCE(p.active, true) IS TRUE AND COALESCE(c.active, true) IS TRUE
	$sql$, v_parent);

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
		JOIN %1$I.node n ON n.node_id::text = p.node_id::text
		LEFT JOIN am.config_nodecatalog_def cat
			ON cat.nodecat_id = n.nodecat_id::text AND cat.project_type = 'UD'
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
		CREATE OR REPLACE VIEW am.v_ud_node_am AS
		SELECT n.node_id,
			s.max_structural_score AS cond_state,
			s.max_operational_score AS om_state,
			s.total_cost,
			s.observation_count,
			s.severe_observation_count,
			n.the_geom
		FROM %1$I.node n
		LEFT JOIN am.v_ud_inspection_score s
			ON s.asset_type = 'NODE' AND s.asset_id = n.node_id::text
		WHERE n.state = 1
	$sql$, v_parent);

	EXECUTE format($sql$
		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
		VALUES
		('ud_node_pathology', 'CCTV pathologies per UD node', 'role_om', NULL, '36', 8, 'UD node pathologies', NULL, NULL, NULL, 'am', NULL),
		('v_ud_node_pathology', 'UD node pathologies with cost and AWARE score', 'role_om', NULL, '36', 9, 'UD node pathology calc', NULL, NULL, NULL, 'am', NULL),
		('v_ud_arc_am', 'UD arc condition, cost and observation summary', 'role_om', NULL, '35', 10, 'UD arc AM', NULL, NULL, NULL, 'am', NULL),
		('v_ud_node_am', 'UD node condition, cost and observation summary', 'role_om', NULL, '36', 10, 'UD node AM', NULL, NULL, NULL, 'am', NULL),
		('ud_breakdown', 'UD breakdowns by feature', 'role_om', NULL, '35', 11, 'UD breakdowns', NULL, NULL, NULL, 'am', NULL)
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source
	$sql$, v_parent);

	GRANT ALL ON TABLE am.v_ud_node_pathology TO role_basic;
	GRANT ALL ON TABLE am.v_ud_inspection_score TO role_basic;
	GRANT ALL ON TABLE am.v_ud_arc_am TO role_basic;
	GRANT ALL ON TABLE am.v_ud_node_am TO role_basic;

	EXECUTE format($sql$
		CREATE OR REPLACE FUNCTION %1$I.gw_trg_am_ud_node_pathology()
		RETURNS trigger AS $body$
		DECLARE
			v_node_id varchar(16);
			v_cond numeric;
			v_om numeric;
			v_total numeric;
			v_inspection_id bigint;
			v_inspection_date date;
		BEGIN
			v_node_id := COALESCE(NEW.node_id, OLD.node_id);
			SELECT COALESCE(max_structural_score, 1), COALESCE(max_operational_score, 1),
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
			UPDATE %1$I.node SET
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
		$body$ LANGUAGE plpgsql VOLATILE;
		DROP TRIGGER IF EXISTS gw_trg_am_ud_node_pathology ON am.ud_node_pathology;
		CREATE TRIGGER gw_trg_am_ud_node_pathology
		AFTER INSERT OR UPDATE OR DELETE ON am.ud_node_pathology
		FOR EACH ROW EXECUTE PROCEDURE %1$I.gw_trg_am_ud_node_pathology();
	$sql$, v_parent);

	GRANT ALL ON TABLE am.v_ud_arc_pathology TO role_basic;

	EXECUTE format($sql$
		CREATE OR REPLACE FUNCTION %1$I.gw_trg_am_ud_arc_pathology()
		RETURNS trigger AS $body$
		DECLARE
			v_arc_id varchar(16);
			v_cond numeric;
			v_om numeric;
			v_total numeric;
			v_inspection_id bigint;
			v_inspection_date date;
		BEGIN
			v_arc_id := COALESCE(NEW.arc_id, OLD.arc_id);
			SELECT COALESCE(max_structural_score, 1), COALESCE(max_operational_score, 1),
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
			UPDATE %1$I.arc SET
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
		$body$ LANGUAGE plpgsql VOLATILE;
		DROP TRIGGER IF EXISTS gw_trg_am_ud_arc_pathology ON am.ud_arc_pathology;
		CREATE TRIGGER gw_trg_am_ud_arc_pathology
		AFTER INSERT OR UPDATE OR DELETE ON am.ud_arc_pathology
		FOR EACH ROW EXECUTE PROCEDURE %1$I.gw_trg_am_ud_arc_pathology();
	$sql$, v_parent);

	-- Upgrade does not re-run integration.sql. Rebuild the overlays priority reads.
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_schema = v_parent AND table_name = 'arc' AND column_name = 'omzone_id'
	) OR to_regclass(format('%I.vf_arc', v_parent)) IS NULL
	  OR to_regclass(format('%I.vf_node', v_parent)) IS NULL THEN
		RETURN;
	END IF;

	SELECT gc.srid INTO v_srid
	FROM public.geometry_columns gc
	WHERE gc.f_table_schema = v_parent
		AND gc.f_table_name = 'arc'
		AND gc.f_geometry_column = 'the_geom'
	LIMIT 1;
	IF v_srid IS NULL THEN
		RETURN;
	END IF;

	EXECUTE format($sql$
		DROP VIEW IF EXISTS am.v_asset_ud_arc_input;
		DROP VIEW IF EXISTS am.v_asset_ud_node_input;
		DROP VIEW IF EXISTS am.ext_ud_arc_asset;
		DROP VIEW IF EXISTS am.ext_ud_node_asset;

		CREATE VIEW am.ext_ud_arc_asset AS
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
			ST_Multi(a.the_geom)::geometry(MultiLineString, %2$s) AS the_geom,
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
				(SELECT count(*)::numeric FROM %1$I.om_visit_x_arc v WHERE v.arc_id = a.arc_id)
				+ (SELECT count(*)::numeric FROM am.ud_breakdown b
					WHERE b.feature_id::text = a.arc_id::text AND upper(trim(b.feature_type)) = 'ARC')
			) AS incident_count_src,
			(SELECT count(*)::numeric FROM %1$I.connec c WHERE c.arc_id = a.arc_id AND c.state = 1) AS dwf_raw_src,
			COALESCE(arc_add.max_flow, 0)::numeric AS storm_raw_src
		FROM %1$I.arc a
			JOIN %1$I.vf_arc vf ON vf.arc_id = a.arc_id
			JOIN %1$I.sector s ON s.sector_id = a.sector_id
			JOIN %1$I.cat_arc cat ON cat.id::text = a.arccat_id::text
			LEFT JOIN %1$I.arc_add ON arc_add.arc_id = a.arc_id
			LEFT JOIN am.v_ud_inspection_score ps ON ps.asset_type = 'ARC' AND ps.asset_id = a.arc_id::text
		WHERE a.state = 1;

		CREATE VIEW am.ext_ud_node_asset AS
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
				(SELECT count(*)::numeric FROM %1$I.om_visit_x_node v WHERE v.node_id = n.node_id)
				+ (SELECT count(*)::numeric FROM am.ud_breakdown b
					WHERE b.feature_id::text = n.node_id::text AND upper(trim(b.feature_type)) = 'NODE')
			) AS incident_count_src,
			NULL::numeric AS dwf_raw_src,
			NULL::numeric AS storm_raw_src
		FROM %1$I.node n
			JOIN %1$I.vf_node ON vf_node.node_id = n.node_id
			JOIN %1$I.sector s ON s.sector_id = n.sector_id
			LEFT JOIN %1$I.cat_node cn ON cn.id::text = n.nodecat_id::text
			LEFT JOIN am.v_ud_inspection_score ps ON ps.asset_type = 'NODE' AND ps.asset_id = n.node_id::text
		WHERE n.state = 1;

		CREATE VIEW am.v_asset_ud_arc_input AS
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
			i.data_quality,
			i.data_quality_obs,
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
			a.the_geom::geometry(MultiLineString, %2$s) AS the_geom
		FROM am.ext_ud_arc_asset a
			LEFT JOIN am.ud_arc_input i USING (arc_id);

		CREATE RULE v_asset_ud_arc_input_update AS ON UPDATE TO am.v_asset_ud_arc_input
		DO INSTEAD
		INSERT INTO am.ud_arc_input (arc_id, mandatory, strategic, incident_count,
			structural_raw, operational_raw, dwf_raw, storm_raw, compliance, estimated_cost)
		VALUES (NEW.arc_id, NEW.mandatory, NEW.strategic, NEW.incident_count,
			NEW.structural_raw, NEW.operational_raw, NEW.dwf_raw, NEW.storm_raw, NEW.compliance, NEW.estimated_cost)
		ON CONFLICT(arc_id) DO
		UPDATE SET mandatory = EXCLUDED.mandatory,
			strategic = EXCLUDED.strategic,
			incident_count = EXCLUDED.incident_count,
			structural_raw = EXCLUDED.structural_raw,
			operational_raw = EXCLUDED.operational_raw,
			dwf_raw = EXCLUDED.dwf_raw,
			storm_raw = EXCLUDED.storm_raw,
			compliance = EXCLUDED.compliance,
			estimated_cost = EXCLUDED.estimated_cost;

		CREATE VIEW am.v_asset_ud_node_input AS
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
			i.data_quality,
			i.data_quality_obs,
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
		FROM am.ext_ud_node_asset a
			LEFT JOIN am.ud_node_input i USING (node_id);

		CREATE RULE v_asset_ud_node_input_update AS ON UPDATE TO am.v_asset_ud_node_input
		DO INSTEAD
		INSERT INTO am.ud_node_input (node_id, mandatory, strategic, incident_count,
			structural_raw, operational_raw, dwf_raw, storm_raw, compliance, estimated_cost)
		VALUES (NEW.node_id, NEW.mandatory, NEW.strategic, NEW.incident_count,
			NEW.structural_raw, NEW.operational_raw, NEW.dwf_raw, NEW.storm_raw, NEW.compliance, NEW.estimated_cost)
		ON CONFLICT(node_id) DO
		UPDATE SET mandatory = EXCLUDED.mandatory,
			strategic = EXCLUDED.strategic,
			incident_count = EXCLUDED.incident_count,
			structural_raw = EXCLUDED.structural_raw,
			operational_raw = EXCLUDED.operational_raw,
			dwf_raw = EXCLUDED.dwf_raw,
			storm_raw = EXCLUDED.storm_raw,
			compliance = EXCLUDED.compliance,
			estimated_cost = EXCLUDED.estimated_cost;
	$sql$, v_parent, v_srid);

	GRANT ALL ON TABLE am.ext_ud_arc_asset TO role_basic;
	GRANT ALL ON TABLE am.ext_ud_node_asset TO role_basic;
	GRANT ALL ON TABLE am.v_asset_ud_arc_input TO role_basic;
	GRANT ALL ON TABLE am.v_asset_ud_node_input TO role_basic;
	GRANT ALL ON TABLE am.v_ud_arc_pathology TO role_basic;
END $$;

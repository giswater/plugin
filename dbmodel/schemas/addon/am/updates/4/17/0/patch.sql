/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public, pg_catalog;

-- Stage 1: Mincut criticity + Stage 2: WS nodes (Weighted Method)

-- Stage 1: Mincut criticity (Weighted Method)

ALTER TABLE am.arc_input
	ADD COLUMN IF NOT EXISTS mincut_customers integer,
	ADD COLUMN IF NOT EXISTS mincut_criticity numeric(4,2);

ALTER TABLE am.arc_engine_wm
	ADD COLUMN IF NOT EXISTS mincut_customers integer,
	ADD COLUMN IF NOT EXISTS mincut_criticity numeric(4,2);

ALTER TABLE am.arc_output
	ADD COLUMN IF NOT EXISTS mincut_customers integer,
	ADD COLUMN IF NOT EXISTS mincut_criticity numeric(4,2);

-- Stage 2: WS nodes Weighted Method

-- arc_input: data quality bookkeeping fields
ALTER TABLE am.arc_input
	ADD COLUMN IF NOT EXISTS data_quality integer,
	ADD COLUMN IF NOT EXISTS data_quality_obs varchar[];

-- cat_result: asset_type discriminator (ARC results keep their previous behaviour)
ALTER TABLE am.cat_result
	ADD COLUMN IF NOT EXISTS asset_type varchar(10) DEFAULT 'ARC';

UPDATE am.cat_result SET asset_type = 'ARC' WHERE asset_type IS NULL;

ALTER TABLE am.cat_result
	ADD COLUMN IF NOT EXISTS nodecat_id character varying(30),
	ADD COLUMN IF NOT EXISTS node_type character varying(30);

-- config_engine_def: asset_type becomes part of the primary key so ARC and NODE
-- parameters can share the same (parameter, method) name without clashing.
ALTER TABLE am.config_engine_def
	ADD COLUMN IF NOT EXISTS asset_type varchar(10);

UPDATE am.config_engine_def SET asset_type = 'ARC' WHERE asset_type IS NULL;

ALTER TABLE am.config_engine_def
	ALTER COLUMN asset_type SET DEFAULT 'ARC',
	ALTER COLUMN asset_type SET NOT NULL;

ALTER TABLE am.config_engine_def DROP CONSTRAINT IF EXISTS config_engine_def_asset_type_check;
ALTER TABLE am.config_engine_def
	ADD CONSTRAINT config_engine_def_asset_type_check CHECK (asset_type = ANY (ARRAY['ARC', 'NODE']));

ALTER TABLE am.config_engine_def DROP CONSTRAINT IF EXISTS config_engine_def_pkey;
ALTER TABLE am.config_engine_def
	ADD CONSTRAINT config_engine_def_pkey PRIMARY KEY (parameter, method, asset_type);

-- config_engine: mirrors config_engine_def structure for saved results, keep asset_type in sync
ALTER TABLE am.config_engine
	ADD COLUMN IF NOT EXISTS asset_type varchar(10);

UPDATE am.config_engine SET asset_type = 'ARC' WHERE asset_type IS NULL;

ALTER TABLE am.config_engine
	ALTER COLUMN asset_type SET DEFAULT 'ARC',
	ALTER COLUMN asset_type SET NOT NULL;

ALTER TABLE am.config_engine DROP CONSTRAINT IF EXISTS config_engine_asset_type_check;
ALTER TABLE am.config_engine
	ADD CONSTRAINT config_engine_asset_type_check CHECK (asset_type = ANY (ARRAY['ARC', 'NODE']));

--
-- Stage 2: NODE Weighted Method tables
--

DROP VIEW IF EXISTS am.v_asset_node_input CASCADE;
DROP VIEW IF EXISTS am.v_asset_node_output CASCADE;
DROP VIEW IF EXISTS am.v_asset_node_output_compare CASCADE;
DROP VIEW IF EXISTS am.v_asset_node_corporate CASCADE;

CREATE TABLE IF NOT EXISTS am.node_input (
	node_id int4 NOT NULL,
	age numeric(12,3),
	incident_count numeric(12,3),
	structural_raw numeric(12,3),
	operational_raw numeric(12,3),
	nrw_raw numeric(12,3),
	affected_users_raw numeric(12,3),
	strategic boolean,
	compliance boolean,
	mandatory boolean DEFAULT false,
	data_quality integer,
	data_quality_obs varchar[],
	estimated_cost numeric(12,2),
	CONSTRAINT node_input_pkey PRIMARY KEY (node_id)
);

-- Upgrade path if an older Stage-2 draft table already exists
ALTER TABLE am.node_input ADD COLUMN IF NOT EXISTS age numeric(12,3);
ALTER TABLE am.node_input ADD COLUMN IF NOT EXISTS structural_raw numeric(12,3);
ALTER TABLE am.node_input ADD COLUMN IF NOT EXISTS operational_raw numeric(12,3);
ALTER TABLE am.node_input ADD COLUMN IF NOT EXISTS nrw_raw numeric(12,3);
ALTER TABLE am.node_input ADD COLUMN IF NOT EXISTS affected_users_raw numeric(12,3);
ALTER TABLE am.node_input ADD COLUMN IF NOT EXISTS data_quality integer;
ALTER TABLE am.node_input ADD COLUMN IF NOT EXISTS data_quality_obs varchar[];
ALTER TABLE am.node_input DROP COLUMN IF EXISTS affected_flow_raw;

CREATE TABLE IF NOT EXISTS am.node_engine_wm (
	node_id int4 NOT NULL,
	result_id integer NOT NULL,
	longevity numeric(5,2),
	incident_history numeric(5,2),
	structural_condition numeric(5,2),
	operational_condition numeric(5,2),
	nrw numeric(5,2),
	affected_users numeric(5,2),
	strategic numeric(5,2),
	compliance numeric(5,2),
	val_first double precision,
	val double precision,
	orderby integer,
	CONSTRAINT node_engine_wm_pkey PRIMARY KEY (node_id, result_id)
);

ALTER TABLE am.node_engine_wm ADD COLUMN IF NOT EXISTS orderby integer;
ALTER TABLE am.node_engine_wm DROP COLUMN IF EXISTS affected_flow;

CREATE TABLE IF NOT EXISTS am.node_output (
	node_id int4 NOT NULL,
	result_id integer NOT NULL,
	sector_id integer,
	macrosector_id integer,
	presszone_id character varying(30),
	builtdate date,
	nodecat_id character varying(30),
	node_type character varying(30),
	the_geom public.geometry(point,SCHEMA_SRID),
	code character varying(50),
	expl_id integer,
	dma_id integer,
	longevity numeric(12,3),
	incident_history numeric(12,3),
	structural_condition numeric(12,3),
	operational_condition numeric(12,3),
	nrw numeric(12,3),
	affected_users numeric(12,3),
	strategic boolean,
	mandatory boolean,
	compliance boolean,
	val double precision,
	orderby integer,
	selected boolean DEFAULT false,
	expected_year integer,
	replacement_year integer,
	budget numeric(12,2),
	total numeric(12,2),
	estimated_cost numeric(12,2),
	comments text,
	data_quality_class varchar(20),
	CONSTRAINT node_output_pkey PRIMARY KEY (node_id, result_id)
);

ALTER TABLE am.node_output DROP COLUMN IF EXISTS affected_flow;

ALTER TABLE am.node_output ADD COLUMN IF NOT EXISTS longevity numeric(12,3);
ALTER TABLE am.node_output ADD COLUMN IF NOT EXISTS incident_history numeric(12,3);
ALTER TABLE am.node_output ADD COLUMN IF NOT EXISTS selected boolean DEFAULT false;
ALTER TABLE am.node_output ADD COLUMN IF NOT EXISTS estimated_cost numeric(12,2);
ALTER TABLE am.node_output ADD COLUMN IF NOT EXISTS comments text;
ALTER TABLE am.node_output ADD COLUMN IF NOT EXISTS data_quality_class varchar(20);

--
-- NODE Weighted Method default weights
--
INSERT INTO am.config_engine_def (
	parameter, value, method, round, descript, active, layoutname, layoutorder,
	label, datatype, widgettype, dv_querytext, dv_controls, ismandatory, iseditable,
	stylesheet, widgetcontrols, placeholder, standardvalue, asset_type
) VALUES
	('longevity_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 1, 'Longevity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('incident_history_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 2, 'Incident history', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('structural_condition_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 3, 'Structural condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('operational_condition_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 4, 'Operational condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('nrw_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 5, 'ANC', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('affected_users_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 6, 'Affected users', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('strategic_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 7, 'Strategic', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('compliance_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 8, 'Compliance', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('longevity_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 1, 'Longevity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('incident_history_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 2, 'Incident history', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('structural_condition_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 3, 'Structural condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('operational_condition_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 4, 'Operational condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('nrw_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 5, 'ANC', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('affected_users_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 6, 'Affected users', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('strategic_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 7, 'Strategic', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
	('compliance_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 8, 'Compliance', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE')
ON CONFLICT (parameter, method, asset_type) DO NOTHING;

-- Drop retired NODE indicator affected_flow (redistribute param_2 defaults to sum 1)
DELETE FROM am.config_engine
WHERE parameter IN ('affected_flow_1', 'affected_flow_2') AND asset_type = 'NODE';
DELETE FROM am.config_engine_def
WHERE parameter IN ('affected_flow_1', 'affected_flow_2') AND asset_type = 'NODE';

UPDATE am.config_engine_def SET layoutorder = 6
WHERE parameter = 'affected_users_1' AND method = 'WM' AND asset_type = 'NODE';
UPDATE am.config_engine_def SET layoutorder = 7
WHERE parameter = 'strategic_1' AND method = 'WM' AND asset_type = 'NODE';
UPDATE am.config_engine_def SET layoutorder = 8
WHERE parameter = 'compliance_1' AND method = 'WM' AND asset_type = 'NODE';
UPDATE am.config_engine_def SET layoutorder = 6, value = '0.25'
WHERE parameter = 'affected_users_2' AND method = 'WM' AND asset_type = 'NODE';
UPDATE am.config_engine_def SET layoutorder = 7, value = '0.25'
WHERE parameter = 'strategic_2' AND method = 'WM' AND asset_type = 'NODE';
UPDATE am.config_engine_def SET layoutorder = 8, value = '0.25'
WHERE parameter = 'compliance_2' AND method = 'WM' AND asset_type = 'NODE';
UPDATE am.config_engine_def SET value = '0.25'
WHERE parameter = 'nrw_2' AND method = 'WM' AND asset_type = 'NODE';

INSERT INTO am.config_engine_def (
	parameter, value, method, round, descript, active, layoutname, layoutorder,
	label, datatype, widgettype, dv_querytext, dv_controls, ismandatory, iseditable,
	stylesheet, widgetcontrols, placeholder, standardvalue, asset_type
) VALUES
	('mincut_criticity_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 10,
	 'Mincut criticity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC'),
	('mincut_criticity_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 11,
	 'Mincut criticity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC')
ON CONFLICT (parameter, method, asset_type) DO NOTHING;

CREATE OR REPLACE VIEW am.v_asset_arc_output AS
 SELECT arc_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    arccat_id,
    dnom,
    matcat_id,
    pavcat_id,
    function_type,
    code,
    expl_id,
    dma_id,
    press1,
    press2,
    flow_avg,
    longevity,
    rleak,
    nrw,
    strategic,
    mandatory,
    compliance,
    mincut_customers,
    mincut_criticity,
    val,
    orderby,
    expected_year,
    replacement_year,
    budget,
    total,
    length,
    cum_length,
    the_geom
   FROM arc_output o
     JOIN selector_result_main s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_arc_output_compare AS
 SELECT arc_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    arccat_id,
    dnom,
    matcat_id,
    pavcat_id,
    function_type,
    code,
    expl_id,
    dma_id,
    press1,
    press2,
    flow_avg,
    longevity,
    rleak,
    nrw,
    strategic,
    mandatory,
    compliance,
    mincut_customers,
    mincut_criticity,
    val,
    orderby,
    expected_year,
    replacement_year,
    budget,
    total,
    length,
    cum_length,
    the_geom
   FROM arc_output o
     JOIN selector_result_compare s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_arc_corporate AS
 SELECT o.arc_id,
    o.result_id,
    o.sector_id,
    o.macrosector_id,
    o.presszone_id,
    o.builtdate,
    o.arccat_id,
    o.dnom,
    o.matcat_id,
    o.pavcat_id,
    o.function_type,
    o.code,
    o.expl_id,
    o.dma_id,
    o.press1,
    o.press2,
    o.flow_avg,
    o.longevity,
    o.rleak,
    o.nrw,
    o.strategic,
    o.mandatory,
    o.compliance,
    o.mincut_customers,
    o.mincut_criticity,
    o.val,
    o.orderby,
    o.expected_year,
    o.replacement_year,
    o.budget,
    o.total,
    o.length,
    o.cum_length,
    o.the_geom
   FROM arc_output o
     JOIN cat_result r ON r.result_id = o.result_id
  WHERE r.iscorporate = TRUE;

-- v_asset_arc_input depends on WS integration view ext_arc_asset
DO $$
BEGIN
	IF to_regclass('am.ext_arc_asset') IS NOT NULL THEN
		DROP VIEW IF EXISTS am.v_asset_arc_input CASCADE;

		EXECUTE $view$
			CREATE VIEW am.v_asset_arc_input AS
			 SELECT a.arc_id,
			    i.mandatory,
			    i.strategic,
			    i.rleak,
			    i.mincut_customers,
			    i.mincut_criticity,
			    a.arccat_id,
			    a.matcat_id,
			    a.dnom,
			    a.builtdate,
			    a.press1,
			    a.press2,
			    a.flow_avg,
			    a.pavcat_id,
			    a.function_type,
			    a.expl_id,
			    a.macrosector_id,
			    a.sector_id,
			    a.presszone_id,
			    a.dma_id,
			    a.code,
			    a.the_geom
			   FROM (ext_arc_asset a
			     LEFT JOIN arc_input i USING (arc_id))
		$view$;

		EXECUTE $rule$
			CREATE RULE v_asset_arc_input_update AS ON UPDATE TO v_asset_arc_input
			 DO INSTEAD
			 INSERT INTO arc_input (arc_id, mandatory, strategic, rleak)
			 VALUES (NEW.arc_id, NEW.mandatory, NEW.strategic, NEW.rleak)
			 ON CONFLICT(arc_id) DO
			 UPDATE SET mandatory = EXCLUDED.mandatory,
			    strategic = EXCLUDED.strategic,
			    rleak = EXCLUDED.rleak
		$rule$;

		GRANT ALL ON TABLE am.v_asset_arc_input TO role_basic;
	END IF;
END $$;

GRANT ALL ON TABLE am.v_asset_arc_output TO role_basic;
GRANT ALL ON TABLE am.v_asset_arc_output_compare TO role_basic;
GRANT ALL ON TABLE am.v_asset_arc_corporate TO role_basic;

CREATE OR REPLACE FUNCTION am.gw_fct_am_update_mincut_criticity(p_data json DEFAULT '{}'::json)
RETURNS json AS
$BODY$
DECLARE
	v_parent_schema text;
	v_project_type text;
	v_has_mincut boolean := false;
	v_updated integer := 0;
	v_version text;
	v_result json;
	v_result_info json;
BEGIN
	SET search_path = am, public;

	SELECT NULLIF(btrim(addparam->>'parentSchema'), ''), project_type, giswater
	INTO v_parent_schema, v_project_type, v_version
	FROM am.sys_version
	ORDER BY id DESC
	LIMIT 1;

	IF v_parent_schema IS NULL OR to_regnamespace(v_parent_schema) IS NULL THEN
		RETURN jsonb_build_object(
			'status', 'Failed',
			'message', jsonb_build_object('level', 2, 'text', 'Parent schema not found in am.sys_version.addparam'),
			'version', v_version
		);
	END IF;

	SELECT EXISTS (
		SELECT 1
		FROM information_schema.tables
		WHERE table_schema = v_parent_schema
			AND table_name = 'minsector_mincut'
	) INTO v_has_mincut;

	IF NOT v_has_mincut THEN
		RETURN jsonb_build_object(
			'status', 'Accepted',
			'message', jsonb_build_object('level', 1, 'text', 'minsector_mincut not found; nothing updated'),
			'version', v_version,
			'body', jsonb_build_object('data', jsonb_build_object('updated', 0))
		);
	END IF;

	UPDATE am.arc_input
	SET mincut_customers = NULL,
		mincut_criticity = NULL;

	EXECUTE format(
		$sql$
		WITH affected_customers AS (
			SELECT
				a.arc_id,
				COALESCE(SUM(m.num_connec), 0)::integer AS mincut_customers
			FROM %1$I.arc a
			JOIN %1$I.minsector_mincut mm ON mm.minsector_id = a.minsector_id
			JOIN %1$I.minsector m ON m.minsector_id = mm.mincut_minsector_id
			WHERE a.state = 1
				AND a.minsector_id IS NOT NULL
			GROUP BY a.arc_id
		),
		limits AS (
			SELECT
				MIN(mincut_customers) AS min_customers,
				MAX(mincut_customers) AS max_customers
			FROM affected_customers
		),
		classified AS (
			SELECT
				ac.arc_id,
				ac.mincut_customers,
				CASE
					WHEN l.max_customers IS NULL THEN NULL
					WHEN l.max_customers = l.min_customers THEN 5.5
					ELSE round(
						(
							1 + 9.0 * (ac.mincut_customers - l.min_customers)
								/ (l.max_customers - l.min_customers)
						)::numeric,
						2
					)
				END AS mincut_criticity
			FROM affected_customers ac
			CROSS JOIN limits l
		)
		INSERT INTO am.arc_input (arc_id, mincut_customers, mincut_criticity)
		SELECT arc_id, mincut_customers, mincut_criticity
		FROM classified
		ON CONFLICT (arc_id) DO UPDATE
		SET mincut_customers = EXCLUDED.mincut_customers,
			mincut_criticity = EXCLUDED.mincut_criticity
		$sql$,
		v_parent_schema
	);

	GET DIAGNOSTICS v_updated = ROW_COUNT;

	v_result_info := jsonb_build_object('updated', v_updated);
	v_result := jsonb_build_object(
		'status', 'Accepted',
		'message', jsonb_build_object('level', 1, 'text', 'Mincut criticity updated'),
		'version', v_version,
		'body', jsonb_build_object('data', v_result_info)
	);

	RETURN v_result;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION am.gw_fct_am_update_mincut_criticity(json) TO role_basic;

--
-- NODE result views
--
CREATE OR REPLACE VIEW am.v_asset_node_output AS
 SELECT node_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    nodecat_id,
    node_type,
    code,
    expl_id,
    dma_id,
    longevity,
    incident_history,
    structural_condition,
    operational_condition,
    nrw,
    affected_users,
    strategic,
    mandatory,
    compliance,
    val,
    orderby,
    selected,
    expected_year,
    replacement_year,
    budget,
    total,
    estimated_cost,
    comments,
    data_quality_class,
    the_geom
   FROM am.node_output o
     JOIN am.selector_result_main s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_node_output_compare AS
 SELECT node_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    nodecat_id,
    node_type,
    code,
    expl_id,
    dma_id,
    longevity,
    incident_history,
    structural_condition,
    operational_condition,
    nrw,
    affected_users,
    strategic,
    mandatory,
    compliance,
    val,
    orderby,
    selected,
    expected_year,
    replacement_year,
    budget,
    total,
    estimated_cost,
    comments,
    data_quality_class,
    the_geom
   FROM am.node_output o
     JOIN am.selector_result_compare s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW am.v_asset_node_corporate AS
 SELECT o.node_id,
    o.result_id,
    o.sector_id,
    o.macrosector_id,
    o.presszone_id,
    o.builtdate,
    o.nodecat_id,
    o.node_type,
    o.code,
    o.expl_id,
    o.dma_id,
    o.longevity,
    o.incident_history,
    o.structural_condition,
    o.operational_condition,
    o.nrw,
    o.affected_users,
    o.strategic,
    o.mandatory,
    o.compliance,
    o.val,
    o.orderby,
    o.selected,
    o.expected_year,
    o.replacement_year,
    o.budget,
    o.total,
    o.estimated_cost,
    o.comments,
    o.data_quality_class,
    o.the_geom
   FROM am.node_output o
     JOIN am.cat_result r ON r.result_id = o.result_id
  WHERE r.iscorporate = TRUE;

GRANT ALL ON TABLE am.node_input TO role_basic;
GRANT ALL ON TABLE am.node_engine_wm TO role_basic;
GRANT ALL ON TABLE am.node_output TO role_basic;
GRANT ALL ON TABLE am.v_asset_node_output TO role_basic;
GRANT ALL ON TABLE am.v_asset_node_output_compare TO role_basic;
GRANT ALL ON TABLE am.v_asset_node_corporate TO role_basic;

-- NODE catalog config (mirrors config_catalog_def / config_catalog for cat_node)
CREATE TABLE IF NOT EXISTS am.config_nodecatalog_def (
	id serial PRIMARY KEY,
	nodecat_id varchar(30) NOT NULL,
	dnom numeric(12,2),
	cost_constr numeric(12,2),
	cost_repmain numeric(12,2),
	compliance integer,
	CONSTRAINT config_nodecatalog_def_nodecat_id UNIQUE (nodecat_id)
);

CREATE TABLE IF NOT EXISTS am.config_nodecatalog (
	nodecat_id varchar(30) NOT NULL,
	dnom numeric(12,2),
	cost_constr numeric(12,2),
	cost_repmain numeric(12,2),
	compliance integer,
	result_id integer NOT NULL,
	CONSTRAINT config_nodecatalog_pkey PRIMARY KEY (nodecat_id, result_id)
);

GRANT ALL ON TABLE am.config_nodecatalog TO role_basic;
GRANT ALL ON TABLE am.config_nodecatalog_def TO role_basic;

INSERT INTO am.config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'dnom', 0, true, NULL, NULL, '{"stretch": true}')
ON CONFLICT (objectname, columnname) DO NOTHING;
INSERT INTO am.config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'cost_constr', 1, true, NULL, NULL, '{"stretch": true}')
ON CONFLICT (objectname, columnname) DO NOTHING;
INSERT INTO am.config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'cost_repmain', 2, true, NULL, NULL, '{"stretch": true}')
ON CONFLICT (objectname, columnname) DO NOTHING;
INSERT INTO am.config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'compliance', 3, true, NULL, NULL, '{"stretch": true}')
ON CONFLICT (objectname, columnname) DO NOTHING;

-- ext_node_asset + v_asset_node_input when parent WS is known
DO $$
DECLARE
	v_parent text;
BEGIN
	SELECT NULLIF(btrim(addparam->>'parentSchema'), '')
	INTO v_parent
	FROM am.sys_version
	ORDER BY id DESC
	LIMIT 1;

	IF v_parent IS NULL OR to_regnamespace(v_parent) IS NULL THEN
		RETURN;
	END IF;

	EXECUTE format($view$
		CREATE OR REPLACE VIEW am.ext_node_asset AS
		SELECT
			n.node_id,
			n.sector_id,
			s.macrosector_id,
			n.presszone_id,
			n.builtdate,
			n.nodecat_id,
			cn.matcat_id,
			COALESCE(cn.node_type, n.epa_type) AS node_type,
			n.code,
			n.expl_id,
			n.dma_id,
			CASE
				WHEN n.builtdate IS NULL THEN NULL
				ELSE EXTRACT(YEAR FROM age(CURRENT_DATE, n.builtdate))::numeric
			END AS age,
			0::numeric AS estimated_cost,
			n.the_geom
		FROM %1$I.node n
		JOIN %1$I.vf_node vf ON vf.node_id = n.node_id
		JOIN %1$I.sector s ON s.sector_id = n.sector_id
		LEFT JOIN %1$I.cat_node cn ON cn.id::text = n.nodecat_id::text
		WHERE n.state = 1
	$view$, v_parent);

	EXECUTE $view$
		CREATE OR REPLACE VIEW am.v_asset_node_input AS
		SELECT
			a.node_id,
			COALESCE(i.age, a.age) AS age,
			i.incident_count,
			i.structural_raw,
			i.operational_raw,
			i.nrw_raw,
			i.affected_users_raw,
			i.strategic,
			i.compliance,
			COALESCE(i.mandatory, false) AS mandatory,
			i.data_quality,
			i.data_quality_obs,
			COALESCE(i.estimated_cost, a.estimated_cost) AS estimated_cost,
			a.nodecat_id,
			a.node_type,
			a.builtdate,
			a.expl_id,
			a.macrosector_id,
			a.sector_id,
			a.presszone_id,
			a.dma_id,
			a.code,
			a.the_geom
		FROM am.ext_node_asset a
		LEFT JOIN am.node_input i USING (node_id)
	$view$;

	EXECUTE $rule$
		CREATE OR REPLACE RULE v_asset_node_input_update AS ON UPDATE TO am.v_asset_node_input
		DO INSTEAD
		INSERT INTO am.node_input (
			node_id, strategic, compliance, mandatory,
			incident_count, structural_raw, operational_raw,
			nrw_raw, affected_users_raw, estimated_cost
		) VALUES (
			NEW.node_id, NEW.strategic, NEW.compliance, NEW.mandatory,
			NEW.incident_count, NEW.structural_raw, NEW.operational_raw,
			NEW.nrw_raw, NEW.affected_users_raw, NEW.estimated_cost
		)
		ON CONFLICT (node_id) DO UPDATE SET
			strategic = EXCLUDED.strategic,
			compliance = EXCLUDED.compliance,
			mandatory = EXCLUDED.mandatory,
			incident_count = EXCLUDED.incident_count,
			structural_raw = EXCLUDED.structural_raw,
			operational_raw = EXCLUDED.operational_raw,
			nrw_raw = EXCLUDED.nrw_raw,
			affected_users_raw = EXCLUDED.affected_users_raw,
			estimated_cost = EXCLUDED.estimated_cost
	$rule$;

	GRANT ALL ON TABLE am.ext_node_asset TO role_basic;
	GRANT ALL ON TABLE am.v_asset_node_input TO role_basic;

	-- Seed / sync NODE catalog from parent cat_node (mirrors cat_arc → config_catalog_def)
	IF NOT EXISTS (SELECT 1 FROM am.config_nodecatalog_def LIMIT 1) THEN
		EXECUTE format($seed$
			INSERT INTO am.config_nodecatalog_def (nodecat_id, dnom, cost_constr, cost_repmain, compliance)
			SELECT id,
				NULLIF(regexp_replace(COALESCE(dnom, ''), '[^0-9\.]', '', 'g'), '')::NUMERIC,
				100,
				0,
				10
			FROM %1$I.cat_node
			WHERE active IS DISTINCT FROM FALSE
			ON CONFLICT (nodecat_id) DO NOTHING
		$seed$, v_parent);
	END IF;

	EXECUTE format($trg$
		CREATE OR REPLACE FUNCTION %1$I.gw_trg_asset_cat_node() RETURNS trigger AS $BODY$
		BEGIN
			EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
			IF TG_OP = 'INSERT' THEN
				INSERT INTO am.config_nodecatalog_def (nodecat_id, dnom)
				VALUES (
					NEW.id,
					NULLIF(regexp_replace(COALESCE(NEW.dnom, ''), '[^0-9\.]', '', 'g'), '')::numeric
				)
				ON CONFLICT (nodecat_id) DO NOTHING;
				RETURN NEW;
			ELSIF TG_OP = 'UPDATE' THEN
				UPDATE am.config_nodecatalog_def
				SET dnom = NULLIF(regexp_replace(COALESCE(NEW.dnom, ''), '[^0-9\.]', '', 'g'), '')::numeric
				WHERE nodecat_id = OLD.id;
				RETURN NEW;
			END IF;
			RETURN NEW;
		END;
		$BODY$ LANGUAGE plpgsql VOLATILE;

		DROP TRIGGER IF EXISTS gw_trg_asset_cat_node ON %1$I.cat_node;
		CREATE TRIGGER gw_trg_asset_cat_node AFTER INSERT OR UPDATE OF dnom ON %1$I.cat_node
		FOR EACH ROW EXECUTE PROCEDURE %1$I.gw_trg_asset_cat_node();
	$trg$, v_parent);

	ALTER TABLE am.config_nodecatalog_def DROP CONSTRAINT IF EXISTS config_nodecatalog_def_fk;
	EXECUTE format(
		'ALTER TABLE am.config_nodecatalog_def ADD CONSTRAINT config_nodecatalog_def_fk
		 FOREIGN KEY (nodecat_id) REFERENCES %I.cat_node (id)
		 MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE',
		v_parent
	);

	-- Register node layers in parent schema TOC (AM > NODE)
	EXECUTE format($sys$
		INSERT INTO %1$I.config_typevalue (typevalue, id, idval, addparam)
		VALUES ('sys_table_context', '36', '["AM", "NODE"]', '{"orderBy": 36}')
		ON CONFLICT (typevalue, id) DO NOTHING;

		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
		VALUES('v_asset_node_output_compare', 'id', 'role_om', NULL, '36', 5, 'Node Result - Compare', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "allOthers": false, "symbolField": "replacement_year"}')
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
		VALUES('v_asset_node_output', 'id', 'role_om', NULL, '36', 4, 'Node Result - Main', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "allOthers": false, "symbolField": "replacement_year"}')
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
		VALUES('v_asset_node_corporate', 'id', 'role_om', NULL, '36', 3, 'Node Corporate Assets', NULL, NULL, NULL, 'am', NULL)
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
		VALUES('v_asset_node_input', 'id', 'role_om', NULL, '36', 2, 'Node Input Assets', NULL, NULL, NULL, 'am', NULL)
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
		VALUES('ext_node_asset', 'id', 'role_om', NULL, '36', 1, 'Existing Node Assets', NULL, NULL, NULL, 'am', NULL)
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
	$sys$, v_parent);
END $$;

-- Regroup AM TOC: AM > ARC | NODE | CONFIG (idempotent for existing DBs)
DO $$
DECLARE
	v_parent text;
BEGIN
	SELECT NULLIF(btrim(addparam->>'parentSchema'), '')
	INTO v_parent
	FROM am.sys_version
	ORDER BY id DESC
	LIMIT 1;

	IF v_parent IS NULL OR to_regnamespace(v_parent) IS NULL THEN
		RAISE NOTICE 'AM TOC regroup skipped: parent schema not found';
		RETURN;
	END IF;

	EXECUTE format($sys$
		INSERT INTO %1$I.config_typevalue (typevalue, id, idval, addparam) VALUES
			('sys_table_context', '35', '["AM", "ARC"]', '{"orderBy": 35}'),
			('sys_table_context', '36', '["AM", "NODE"]', '{"orderBy": 36}'),
			('sys_table_context', '37', '["AM", "CONFIG"]', '{"orderBy": 37}')
		ON CONFLICT (typevalue, id) DO NOTHING;

		-- ARC layers
		UPDATE %1$I.sys_table SET context = '35', orderby = 7, alias = 'Arc Result - Compare', "source" = 'am'
		WHERE id = 'v_asset_arc_output_compare';
		UPDATE %1$I.sys_table SET context = '35', orderby = 6, alias = 'Arc Result - Main', "source" = 'am'
		WHERE id = 'v_asset_arc_output';
		UPDATE %1$I.sys_table SET context = '35', orderby = 5, alias = 'Arc Corporate Assets', "source" = 'am'
		WHERE id = 'v_asset_arc_corporate';
		UPDATE %1$I.sys_table SET context = '35', orderby = 4, alias = 'Arc Assets Result', "source" = 'am'
		WHERE id = 'arc_output';
		UPDATE %1$I.sys_table SET context = '35', orderby = 3, alias = 'Arc Input Assets', "source" = 'am'
		WHERE id = 'v_asset_arc_input';
		UPDATE %1$I.sys_table SET context = '35', orderby = 2, alias = 'Leaks', "source" = 'am'
		WHERE id = 'leaks';
		UPDATE %1$I.sys_table SET context = '35', orderby = 1, alias = 'Existing Arc Assets', "source" = 'am'
		WHERE id = 'ext_arc_asset';

		-- NODE layers
		UPDATE %1$I.sys_table SET context = '36', orderby = 5, alias = 'Node Result - Compare', "source" = 'am'
		WHERE id = 'v_asset_node_output_compare';
		UPDATE %1$I.sys_table SET context = '36', orderby = 4, alias = 'Node Result - Main', "source" = 'am'
		WHERE id = 'v_asset_node_output';
		UPDATE %1$I.sys_table SET context = '36', orderby = 3, alias = 'Node Corporate Assets', "source" = 'am'
		WHERE id = 'v_asset_node_corporate';
		UPDATE %1$I.sys_table SET context = '36', orderby = 2, alias = 'Node Input Assets', "source" = 'am'
		WHERE id = 'v_asset_node_input';
		UPDATE %1$I.sys_table SET context = '36', orderby = 1, alias = 'Existing Node Assets', "source" = 'am'
		WHERE id = 'ext_node_asset';

		-- CONFIG tables
		INSERT INTO %1$I.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES
			('config_catalog_def', 'Table to define the catalogs', 'role_om', NULL, '37', 4, 'Config catalog', NULL, NULL, NULL, 'am', NULL),
			('config_nodecatalog_def', 'Table to define the node catalogs', 'role_om', NULL, '37', 3, 'Config node catalog', NULL, NULL, NULL, 'am', NULL),
			('config_material_def', 'Table to define the materials', 'role_om', NULL, '37', 2, 'Config material', NULL, NULL, NULL, 'am', NULL),
			('config_engine_def', 'Table to define engines configuration', 'role_om', NULL, '37', 1, 'Config engine', NULL, NULL, NULL, 'am', NULL)
		ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
	$sys$, v_parent);
END $$;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public, pg_catalog;

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

INSERT INTO am.config_engine_def (
	parameter, value, method, round, descript, active, layoutname, layoutorder,
	label, datatype, widgettype, dv_querytext, dv_controls, ismandatory, iseditable,
	stylesheet, widgetcontrols, placeholder, standardvalue
) VALUES
	('mincut_criticity_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 10,
	 'Mincut criticity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('mincut_criticity_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 11,
	 'Mincut criticity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
ON CONFLICT (parameter, method) DO NOTHING;

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
    the_geom,
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
    cum_length
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
    the_geom,
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
    cum_length
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
    o.the_geom,
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
    o.cum_length
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

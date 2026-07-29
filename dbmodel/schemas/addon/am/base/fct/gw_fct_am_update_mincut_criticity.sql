/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 9999
-- Update am.arc_input.mincut_customers / mincut_criticity from parent minsector_mincut topology.

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

	IF upper(COALESCE(v_project_type, '')) <> 'WS'
		AND NOT EXISTS (
			SELECT 1
			FROM information_schema.tables
			WHERE table_schema = v_parent_schema
				AND table_name = 'minsector_mincut'
		) THEN
		RETURN jsonb_build_object(
			'status', 'Accepted',
			'message', jsonb_build_object('level', 1, 'text', 'Mincut tables not available; nothing updated'),
			'version', v_version,
			'body', jsonb_build_object('data', jsonb_build_object('updated', 0))
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

	-- Clear previous values so arcs without a valid mincut footprint stay NULL
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

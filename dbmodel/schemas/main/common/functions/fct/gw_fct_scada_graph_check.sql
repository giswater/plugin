/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_scada_graph_check();

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_scada_graph_check(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/* 

Example:

SELECT SCHEMA_NAME.gw_fct_scada_graph_check($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25830}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, 
"parameters":{"explId":"551", "commitChanges":true}, "aux_params":null}}$$);


Documentation:

The function:
- checks inconsistencies making sure that the attributes of om_scada_graph are synced according to attributes of table "node". It returns a temp table in the map to see the inconsistencies.
- fixes the inconsistencies making sure that the attributes of om_scada_graph are synced according to attributes of table "node"
- when commitChanges is true, writes om_scada_graph_json via gw_fct_scada_graph_export from temp_om_scada_graph (same rows as line_valid)

The features checked are:
- node_1 and node_2 must not be orphan nodes
- node_1 and node_2 must be operative

*/

DECLARE

-- Input vars
v_srid INTEGER;
v_project_type TEXT;
v_expl_id TEXT;
v_expl_id_array integer[];
v_edge_filter TEXT;
v_commit_changes BOOLEAN;

-- Vars
rec record;
v_arcs JSON;
v_fid int = 999;
v_pgr_distance INTEGER;
v_pgr_root_vids INTEGER	[];

v_query_text TEXT;
v_query_combinations TEXT;
v_error_context TEXT;
v_message TEXT;

-- result variables
v_version TEXT;
v_result JSON;
v_result_info JSON;
v_result_line_valid JSON;
v_result_line_invalid JSON;
v_result_line JSON;
v_visible_layer TEXT;
v_export_result JSON;
v_msg_header TEXT;
v_msg_edges TEXT;
v_msg_valid TEXT;
v_msg_inconsist TEXT;
v_msg_no_inconsist TEXT;
v_msg_json_saved TEXT;
v_msg_done TEXT;
v_msg_err_missing_both TEXT;
v_msg_err_missing_1 TEXT;
v_msg_err_missing_2 TEXT;
v_msg_err_obsolete_both TEXT;
v_msg_err_obsolete_1 TEXT;
v_msg_err_obsolete_2 TEXT;
v_msg_err_orphan_both TEXT;
v_msg_err_orphan_1 TEXT;
v_msg_err_orphan_2 TEXT;
v_msg_err_nopath TEXT;
v_msg_separator TEXT;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	SELECT
		COALESCE(max(error_message) FILTER (WHERE id = 4696), 'CHECK DATA QUALITY - OM_SCADA_GRAPH'),
		COALESCE(max(error_message) FILTER (WHERE id = 4700), 'Edges analysed: %v_count%'),
		COALESCE(max(error_message) FILTER (WHERE id = 4702), 'Valid geometry: %v_count%'),
		COALESCE(max(error_message) FILTER (WHERE id = 4704), 'Inconsistencies: %v_count%'),
		COALESCE(max(error_message) FILTER (WHERE id = 4706), 'No inconsistencies found.'),
		COALESCE(max(error_message) FILTER (WHERE id = 4708), 'JSON saved to table om_scada_graph_json'),
		COALESCE(max(error_message) FILTER (WHERE id = 4710), 'Data quality analysis done successfully'),
		COALESCE(max(error_message) FILTER (WHERE id = 4712), '1. node_1 and node_2 are missing'),
		COALESCE(max(error_message) FILTER (WHERE id = 4714), '1. node_1 is missing'),
		COALESCE(max(error_message) FILTER (WHERE id = 4716), '1. node_2 is missing'),
		COALESCE(max(error_message) FILTER (WHERE id = 4718), '2. node_1 and node_2 are obsolete'),
		COALESCE(max(error_message) FILTER (WHERE id = 4720), '2. node_1 is obsolete'),
		COALESCE(max(error_message) FILTER (WHERE id = 4722), '2. node_2 is obsolete'),
		COALESCE(max(error_message) FILTER (WHERE id = 4724), '3. node_1 and node_2 are orphan'),
		COALESCE(max(error_message) FILTER (WHERE id = 4726), '3. node_1 is orphan'),
		COALESCE(max(error_message) FILTER (WHERE id = 4728), '3. node_2 is orphan'),
		COALESCE(max(error_message) FILTER (WHERE id = 4730), '4. node_1 and node_2 without a valid connection')
	INTO
		v_msg_header, v_msg_edges, v_msg_valid, v_msg_inconsist, v_msg_no_inconsist,
		v_msg_json_saved, v_msg_done, v_msg_err_missing_both, v_msg_err_missing_1, v_msg_err_missing_2,
		v_msg_err_obsolete_both, v_msg_err_obsolete_1, v_msg_err_obsolete_2, v_msg_err_orphan_both,
		v_msg_err_orphan_1, v_msg_err_orphan_2, v_msg_err_nopath
	FROM v_sys_message
	WHERE id IN (4696, 4700, 4702, 4704, 4706, 4708, 4710, 4712, 4714, 4716, 4718, 4720, 4722, 4724, 4726, 4728, 4730);

	SELECT COALESCE((SELECT idval FROM v_sys_label WHERE id = 2030 LIMIT 1), '-------------------------------------')
	INTO v_msg_separator;

	-- Input data and init params
	SELECT giswater, upper(project_type), epsg INTO v_version, v_project_type, v_srid FROM sys_version ORDER BY id DESC LIMIT 1;

	v_expl_id := COALESCE(
		p_data -> 'data' -> 'parameters' ->> 'explId',
		p_data -> 'data' -> 'parameters' ->> 'exploitation'
	);
	v_commit_changes := COALESCE(
		(p_data -> 'data' -> 'parameters' ->> 'commitChanges')::boolean,
		false
	);

	DROP TABLE IF EXISTS temp_om_scada_graph;
	DROP TABLE IF EXISTS temp_graph;
	DROP TABLE IF EXISTS temp_audit_check_data;

	CREATE TEMP TABLE IF NOT EXISTS temp_om_scada_graph (LIKE SCHEMA_NAME.om_scada_graph INCLUDING ALL);
	ALTER TABLE temp_om_scada_graph ADD COLUMN error_message TEXT;

	CREATE TEMP TABLE IF NOT EXISTS temp_audit_check_data (LIKE SCHEMA_NAME.audit_check_data INCLUDING ALL);

	-- Get exploitation ID array
	v_expl_id_array := gw_fct_get_expl_id_array(v_expl_id);

	-- if v_expl_id_array is null, return error
	IF v_expl_id_array IS NULL THEN
		SELECT COALESCE(
			(SELECT error_message FROM v_sys_message WHERE id = 4478 LIMIT 1),
			'There are no exploitations in your exploitation selection'
		)
		INTO v_message;
		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Failed',
			'message', json_build_object('level', 2, 'text', v_message),
			'version', v_version,
			'body', json_build_object('form', '{}'::json, 'data', '{}'::json)
		)::json, 3548, null, null, null);
	END IF;

	-- Initialize process
	-- =======================
	v_query_text := $q$
		SELECT row_number() OVER () AS id, node_1 AS source, node_2 AS target, 1 AS cost
		FROM om_scada_graph
	$q$;

	EXECUTE format($sql$
		WITH connectedcomponents AS (
			SELECT *
			FROM pgr_connectedcomponents($q$%s$q$)
		),
		components AS (
			SELECT DISTINCT c.component
			FROM connectedcomponents c
			WHERE cardinality($1) = 0
			OR EXISTS (
				SELECT 1
				FROM om_scada_graph g
				LEFT JOIN node n1 ON g.node_1 = n1.node_id
				LEFT JOIN node n2 ON g.node_2 = n2.node_id
				WHERE (
					(g.expl_id && $1 AND g.node_1 = c.node) 
					OR (n1.expl_id = ANY ($1) AND g.node_1 = c.node)
					OR (n2.expl_id = ANY ($1) AND g.node_2 = c.node)
				)
			)
		)
		INSERT INTO temp_om_scada_graph (node_1, node_2, active)
		SELECT g.node_1, g.node_2, g.active
		FROM om_scada_graph g
		JOIN connectedcomponents c1 ON c1.node = g.node_1
		WHERE EXISTS (
			SELECT 1
			FROM components cc
			WHERE cc.component = c1.component
		) 
	$sql$, v_query_text)
	USING v_expl_id_array;

	v_query_combinations := '
		SELECT node_1 AS source, node_2 AS target FROM temp_om_scada_graph WHERE active = TRUE
	';

	IF v_project_type = 'WS' THEN
		CREATE TEMP TABLE temp_graph AS
		SELECT d.start_vid as node_1, d.end_vid as node_2, d.edge AS arc_id, d.node AS node_id
		FROM pgr_dijkstra(
			$pgr$WITH
				closed_valve AS (
					SELECT n.node_id
					FROM node n
					JOIN value_state_type s ON n.state_type = s.id
					JOIN man_valve m ON n.node_id = m.node_id
					JOIN cat_node cn ON n.nodecat_id = cn.id
					JOIN cat_feature_node cf ON cf.id = cn.node_type
					WHERE n.state = 1 AND s.is_operative
					AND m.closed AND 'MINSECTOR' = ANY (cf.graph_delimiter)
				)
				SELECT
					a.arc_id::int AS id,
					a.node_1::int AS source,
					a.node_2::int AS target,
					COALESCE(a.custom_length, st_length(a.the_geom)) / (
						COALESCE(NULLIF(ca.dint, 0), 1)::float ^ 2
					) AS cost
				FROM arc a
				JOIN cat_arc ca ON ca.id = a.arccat_id
				JOIN value_state_type s ON a.state_type = s.id
				WHERE a.state = 1 AND s.is_operative
				AND a.node_1 IS NOT NULL AND a.node_2 IS NOT NULL
				AND NOT EXISTS (SELECT 1 FROM closed_valve cv WHERE cv.node_id = a.node_1 OR cv.node_id = a.node_2)
			$pgr$,
			v_query_combinations,
			directed := false
		) d;
	ELSIF v_project_type = 'UD' THEN
		CREATE TEMP TABLE temp_graph AS
		SELECT d.start_vid as node_1, d.end_vid as node_2, d.edge AS arc_id, d.node AS node_id
		FROM pgr_dijkstra(
			$pgr$SELECT
					a.arc_id::int AS id,
					a.node_1::int AS source,
					a.node_2::int AS target,
					COALESCE(a.custom_length, st_length(a.the_geom)) / COALESCE(
						COALESCE(NULLIF(ca.geom1, 0), NULLIF(ca.geom2, 0)) 
						* COALESCE(NULLIF(ca.geom2, 0), NULLIF(ca.geom1, 0)),
						1
					) AS cost, -- geom1*geom2 (geom1,geom2>0) or geom1*geom1(geom2=0) or geom2*geom2(geom1=0) or 1 (geom1=geom2=0)
					-1.0 AS reverse_cost
				FROM arc a
				JOIN cat_arc ca ON ca.id = a.arccat_id
				JOIN value_state_type s ON a.state_type = s.id 
				WHERE a.state = 1 AND s.is_operative AND a.node_1 IS NOT NULL AND a.node_2 IS NOT NULL
			$pgr$,
			v_query_combinations,
			directed := true
		) d;
	END IF;

	CREATE INDEX IF NOT EXISTS temp_graph_node_1_node_2_idx ON temp_graph USING btree (node_1, node_2);
	CREATE INDEX IF NOT EXISTS temp_graph_arc_id_idx ON temp_graph USING btree (arc_id);
	CREATE INDEX IF NOT EXISTS temp_graph_node_id_idx ON temp_graph USING btree (node_id);

	-- Update temp_om_scada_graph with the_geom and attrib
	UPDATE temp_om_scada_graph t
	SET the_geom = agg.the_geom,
		attrib = agg.attrib
	FROM (
		SELECT g.node_1, g.node_2,
			ST_Multi(ST_LineMerge(ST_Collect(a.the_geom))) AS the_geom,
			json_build_object('arcs', json_agg(a.arc_id)) AS attrib
		FROM temp_om_scada_graph g
		JOIN temp_graph t ON g.node_1 = t.node_1 AND g.node_2 = t.node_2
		JOIN arc a ON t.arc_id = a.arc_id
		GROUP BY g.node_1, g.node_2
	) agg
	WHERE t.node_1 = agg.node_1 AND t.node_2 = agg.node_2;

	-- Update temp_om_scada_graph with expl_id when node_1 and noe_2 are in temp_graph
	UPDATE temp_om_scada_graph t
	SET expl_id = agg.expl_id
	FROM (
		SELECT g.node_1, g.node_2, array_agg(DISTINCT n.expl_id) AS expl_id
		FROM temp_om_scada_graph g
		JOIN temp_graph t ON g.node_1 = t.node_1 AND g.node_2 = t.node_2
		JOIN node n ON t.node_id = n.node_id
		GROUP BY g.node_1, g.node_2
	) agg
	WHERE t.node_1 = agg.node_1 AND t.node_2 = agg.node_2;

	-- expl_id when node_1 and node_2 are not in temp_graph (the_geom is null)
	UPDATE temp_om_scada_graph t
	SET expl_id = (
			SELECT array_agg(DISTINCT v.expl_id)
			FROM (VALUES (n1.expl_id), (n2.expl_id)) AS v(expl_id)
			WHERE v.expl_id IS NOT NULL
		)
	FROM temp_om_scada_graph g
	LEFT JOIN node n1 ON g.node_1 = n1.node_id
	LEFT JOIN node n2 ON g.node_2 = n2.node_id
	WHERE g.the_geom IS NULL
	AND t.node_1 = g.node_1 AND t.node_2 = g.node_2;

	-- Update temp_om_scada_graph with node_type_1 and node_type_2
	UPDATE temp_om_scada_graph t
	SET node_type_1 = cn1.node_type
	FROM node n1
	JOIN cat_node cn1 ON n1.nodecat_id = cn1.id
	WHERE t.node_1 = n1.node_id;

	UPDATE temp_om_scada_graph t
	SET node_type_2 = cn2.node_type
	FROM node n2
	JOIN cat_node cn2 ON n2.nodecat_id = cn2.id
	WHERE t.node_2 = n2.node_id;

	-- update group_id and order_id
	v_query_text := '
		SELECT row_number() OVER () AS id, node_1 AS source, node_2 AS target, 1::float AS cost
		FROM temp_om_scada_graph
		WHERE the_geom IS NOT NULL';

	v_pgr_distance := (SELECT count(*)::int FROM temp_om_scada_graph);

	SELECT COALESCE(array_agg(DISTINCT g.node_1), '{}')::int[]
	INTO v_pgr_root_vids
	FROM temp_om_scada_graph g
	WHERE  g.the_geom IS NOT NULL
	AND NOT EXISTS (
		SELECT 1 FROM temp_om_scada_graph g2
		WHERE  g2.the_geom IS NOT NULL
		AND g2.node_2 = g.node_1
	);

	-- group_id: for each connected component, assign the minimum root node id (from v_pgr_root_vids)
	WITH
		connectedcomponents AS (
			SELECT component, node AS node_id
			FROM pgr_connectedcomponents('SELECT row_number() OVER () AS id, node_1 AS source, node_2 AS target, 1::float AS cost
			FROM temp_om_scada_graph
			WHERE the_geom IS NOT NULL')
		),
		group_ids AS (
			SELECT c.component, min(c.node_id) AS group_id
			FROM connectedcomponents c
			WHERE c.node_id = ANY (v_pgr_root_vids)
			GROUP BY c.component
		)
	UPDATE temp_om_scada_graph t
	SET group_id = g.group_id
	FROM connectedcomponents c
	JOIN group_ids g ON c.component = g.component
	WHERE t.node_1 = c.node_id
	AND t.the_geom IS NOT NULL; -- assures to update all the edges, because drivingdistance returns nodes, not edges

	-- order_id
	UPDATE temp_om_scada_graph t
	SET order_id = g.order_id
	FROM (
		SELECT pred as node_id, max(agg_cost) AS order_id
		FROM pgr_drivingDistance(v_query_text, v_pgr_root_vids, v_pgr_distance, directed := true)
		WHERE edge <> -1
		GROUP BY pred
	) g
	WHERE t.node_1 = g.node_id
	AND t.the_geom IS NOT NULL; -- assures to update all the edges, because drivingdistance returns nodes, not edges

	-- ERRORS
	--==========================
	UPDATE temp_om_scada_graph t
	SET error_message =
		CASE

		WHEN NOT EXISTS (SELECT 1 FROM node n WHERE t.node_1 = n.node_id)
			AND NOT EXISTS (SELECT 1 FROM node n WHERE t.node_2 = n.node_id)
		THEN v_msg_err_missing_both

		WHEN NOT EXISTS (SELECT 1 FROM node n WHERE t.node_1 = n.node_id)
		THEN v_msg_err_missing_1

		WHEN NOT EXISTS (SELECT 1 FROM node n WHERE t.node_2 = n.node_id)
		THEN v_msg_err_missing_2

		WHEN EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.node_1 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		) AND EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.node_2 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		)
		THEN v_msg_err_obsolete_both

		WHEN EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.node_1 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		)
		THEN v_msg_err_obsolete_1

		WHEN EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.node_2 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		)
		THEN v_msg_err_obsolete_2

		WHEN NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.node_1 OR a.node_2 = t.node_1)
		) AND NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.node_2 OR a.node_2 = t.node_2)
		)
		THEN v_msg_err_orphan_both

		WHEN NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.node_1 OR a.node_2 = t.node_1)
		)
		THEN v_msg_err_orphan_1

		WHEN NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.node_2 OR a.node_2 = t.node_2)
		)
		THEN v_msg_err_orphan_2

		WHEN t.the_geom IS NULL
		THEN v_msg_err_nopath
	END
	WHERE t.active = TRUE;

	-- Update om_scada_graph if v_commit_changes is TRUE
	--================================================

	IF v_commit_changes IS  TRUE THEN

		-- update is_scadamap = false for obsolete arcs
		WITH old_arc AS (
			SELECT DISTINCT json_array_elements_text(g.attrib::json -> 'arcs')::int AS arc_id
			FROM om_scada_graph g
			JOIN temp_om_scada_graph t ON t.node_1 = g.node_1 AND t.node_2 = g.node_2
		),
		new_arc AS (
			SELECT DISTINCT arc_id FROM temp_graph
		)
		UPDATE arc a
		SET is_scadamap = FALSE
		WHERE a.is_scadamap = TRUE
		AND EXISTS (SELECT 1 FROM old_arc a1 WHERE a1.arc_id = a.arc_id)
		AND NOT EXISTS (SELECT 1 FROM new_arc a2 WHERE a2.arc_id = a.arc_id);

		WITH old_arc AS (
			SELECT DISTINCT json_array_elements_text(g.attrib::json -> 'arcs')::int AS arc_id
			FROM om_scada_graph g
			JOIN temp_om_scada_graph t ON t.node_1 = g.node_1 AND t.node_2 = g.node_2
		),
		new_arc AS (
			SELECT DISTINCT arc_id FROM temp_graph
		)
		UPDATE node n
		SET is_scadamap = FALSE
		WHERE n.is_scadamap = TRUE
		AND EXISTS (
			SELECT 1 FROM old_arc a1 
			JOIN arc a ON a1.arc_id = a.arc_id
			WHERE a.node_1 = n.node_id OR a.node_2 = n.node_id
		)
		AND NOT EXISTS (
			SELECT 1 FROM new_arc a2
			JOIN arc a ON a2.arc_id = a.arc_id
			WHERE a.node_1 = n.node_id OR a.node_2 = n.node_id
		);

		-- update is_scadamap = true for new arcs
		UPDATE arc a
		SET is_scadamap = TRUE
		WHERE EXISTS (SELECT 1 FROM temp_graph g WHERE g.arc_id = a.arc_id)
		AND a.is_scadamap = FALSE;

		UPDATE node n
		SET is_scadamap = TRUE
		WHERE EXISTS (SELECT 1 FROM temp_graph g WHERE g.node_id = n.node_id)
		AND n.is_scadamap = FALSE;

		-- update om_scada_graph
		-- expl_id, node_type_1 and node_type_2 keep their previous value if the new calculation doesn't provide one
		UPDATE om_scada_graph g
		SET the_geom = t.the_geom,
			attrib = t.attrib,
			expl_id = COALESCE(t.expl_id, g.expl_id),
			node_type_1 = COALESCE(t.node_type_1, g.node_type_1),
			node_type_2 = COALESCE(t.node_type_2, g.node_type_2),
			group_id = t.group_id,
			order_id = t.order_id
		FROM temp_om_scada_graph t
		WHERE g.node_1 = t.node_1 AND g.node_2 = t.node_2;

		-- Snapshot JSON from temp (scoped by check; export does not re-filter expl)
		v_export_result := gw_fct_scada_graph_export(p_data);
		IF v_export_result ->> 'status' IS DISTINCT FROM 'Accepted' THEN
			RETURN v_export_result;
		END IF;

	END IF;

	-- SECTION Creating temporal layers
	--==================================

	-- get results - line_valid
	IF v_commit_changes IS TRUE THEN
		v_visible_layer := '"v_om_scada_graph"';
	ELSE
		v_visible_layer := NULL;

		SELECT jsonb_build_object(
			'type', 'FeatureCollection',
			'layerName', 'line_valid',
			'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
		)
		INTO v_result
		FROM (
			SELECT jsonb_build_object(
			'type',       'Feature',
			'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
			'properties', to_jsonb(r) - 'the_geom'
			) AS feature
			FROM (
			SELECT
				g.group_id,
				g.order_id,
				g.node_1,
				g.node_type_1,
				n1.sys_code AS sys_code_1,
				n1.expl_id AS expl_id_1,
				n1.dma_id AS dma_id_1,
				d1.name AS dma_name_1,
				g.node_2,
				g.node_type_2,
				n2.sys_code AS sys_code_2,
				n2.expl_id AS expl_id_2,
				n2.dma_id AS dma_id_2,
				d2.name AS dma_name_2,
				g.expl_id,
				g.attrib,
				g.active,
				g.the_geom
			FROM temp_om_scada_graph g
			LEFT JOIN node n1 ON n1.node_id = g.node_1
			LEFT JOIN dma d1 ON d1.dma_id = n1.dma_id
			LEFT JOIN node n2 ON n2.node_id = g.node_2
			LEFT JOIN dma d2 ON d2.dma_id = n2.dma_id
			WHERE g.error_message IS NULL -- the layer contains active = TRUE AND the_geom IS NOT NULL AND also active = FALSE
			ORDER BY g.group_id, g.order_id
			) r
		) f;

		v_result_line_valid := v_result;
	END IF;

	-- get errors info and results - line_invalid
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, v_msg_header);
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, v_msg_separator);
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
	SELECT 1, null, 1, replace(v_msg_edges, '%v_count%', count(*)::text) FROM temp_om_scada_graph;
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
	SELECT 1, null, 1, replace(v_msg_valid, '%v_count%', count(*)::text)
	FROM temp_om_scada_graph
	WHERE the_geom IS NOT NULL AND error_message IS NULL;
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
	SELECT 1, null, 1, replace(v_msg_inconsist, '%v_count%', count(*)::text)
	FROM temp_om_scada_graph
	WHERE error_message IS NOT NULL;

	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
	SELECT 1, null, 2, concat(count(*),' ', t.error_message)
	FROM temp_om_scada_graph t
	WHERE t.error_message IS NOT NULL
	GROUP BY t.error_message
	ORDER BY t.error_message;

	IF NOT EXISTS (SELECT 1 FROM temp_om_scada_graph WHERE error_message IS NOT NULL) THEN
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
		VALUES (1, null, 1, v_msg_no_inconsist);
	END IF;

	IF v_commit_changes IS TRUE THEN
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
		VALUES (1, null, 1, v_msg_json_saved);
	END IF;

	SELECT json_agg(row_to_json(row) ORDER BY row.id) INTO v_result
	FROM (
		SELECT ROW_NUMBER() OVER (ORDER BY criticity DESC NULLS LAST, id) AS id,
			error_message AS message
		FROM temp_audit_check_data
	) row;

	v_result := COALESCE(v_result, '[]'::json);
	v_result_info = concat('{"geometryType":"", "values":', v_result, '}');

	SELECT jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'line_invalid',
		'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
	)
	INTO v_result
	FROM (
		SELECT jsonb_build_object(
		'type',       'Feature',
		'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
		'properties', to_jsonb(r) - 'the_geom'
		) AS feature
		FROM (
			SELECT
				g.group_id,
				g.order_id,
				g.node_1,
				g.node_type_1,
				n1.sys_code AS sys_code_1,
				n1.expl_id AS expl_id_1,
				n1.dma_id AS dma_id_1,
				d1.name AS dma_name_1,
				g.node_2,
				g.node_type_2,
				n2.sys_code AS sys_code_2,
				n2.expl_id AS expl_id_2,
				n2.dma_id AS dma_id_2,
				d2.name AS dma_name_2,
				g.expl_id,
				g.attrib,
				g.active,
				g.error_message,
				g.the_geom
			FROM temp_om_scada_graph g
			LEFT JOIN node n1 ON n1.node_id = g.node_1
			LEFT JOIN dma d1 ON d1.dma_id = n1.dma_id
			LEFT JOIN node n2 ON n2.node_id = g.node_2
			LEFT JOIN dma d2 ON d2.dma_id = n2.dma_id
			WHERE g.error_message IS NOT NULL
		) r
	) f;

	v_result_line_invalid := v_result;

	v_result_line_valid := COALESCE(v_result_line_valid, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'line_valid',
		'features', '[]'::jsonb
	)::json);
	v_result_line_invalid := COALESCE(v_result_line_invalid, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'line_invalid',
		'features', '[]'::jsonb
	)::json);

	v_result_line := jsonb_build_array(
		v_result_line_invalid,
		v_result_line_valid
	)::json;

	--drop temporal tables
	DROP TABLE IF EXISTS temp_om_scada_graph;
	DROP TABLE IF EXISTS temp_audit_check_data;
	DROP TABLE IF EXISTS temp_graph;

	-- Return
	RETURN gw_fct_json_create_return(json_build_object(
		'status', 'Accepted',
		'message', json_build_object('level', 1, 'text', v_msg_done),
		'version', v_version,
		'body', json_build_object(
			'form', '{}'::json,
			'data', json_build_object(
				'info', v_result_info::json,
				'line', v_result_line
			)
		)
	)::json, 3548, null, ('{"visible": [' || COALESCE(v_visible_layer, '') || ']}')::json, null);

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;
$function$
;

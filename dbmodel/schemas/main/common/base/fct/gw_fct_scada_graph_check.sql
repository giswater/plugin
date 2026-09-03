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

The features checked are:
- object_1 and object_2 must not be orphan nodes
- object_1 and object_2 must be operative

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

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- Input data and init params
	SELECT giswater, upper(project_type), epsg INTO v_version, v_project_type, v_srid FROM sys_version ORDER BY id DESC LIMIT 1;

	v_expl_id := p_data ->'data'->'parameters'->>'explId';
	v_commit_changes := p_data->'data'->'parameters'->>'commitChanges';

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
		RETURN NULL::json;
		-- TODO FERRAN: create a function and an error message to be returned
		/*EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"4478", "function":"3424","parameters":null}}$$);';
		*/
	END IF;

	-- Initialize process
	-- =======================
	v_query_text := $q$
		SELECT row_number() OVER () AS id, object_1 AS source, object_2 AS target, 1 AS cost
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
				LEFT JOIN node n1 ON g.object_1 = n1.node_id
				LEFT JOIN node n2 ON g.object_2 = n2.node_id
				WHERE (
					(string_to_array(g.expl_add, ',')::int[] && $1 AND g.object_1 = c.node) 
					OR (n1.expl_id = ANY ($1) AND g.object_1 = c.node)
					OR (n2.expl_id = ANY ($1) AND g.object_2 = c.node)
				)
			)
		)
		INSERT INTO temp_om_scada_graph (object_1, object_2, active)
		SELECT g.object_1, g.object_2, g.active
		FROM om_scada_graph g
		JOIN connectedcomponents c1 ON c1.node = g.object_1
		WHERE EXISTS (
			SELECT 1
			FROM components cc
			WHERE cc.component = c1.component
		) 
	$sql$, v_query_text)
	USING v_expl_id_array;

	v_query_combinations := '
		SELECT object_1 AS source, object_2 AS target FROM temp_om_scada_graph WHERE active = TRUE
	';

	IF v_project_type = 'WS' THEN
		CREATE TEMP TABLE temp_graph AS
		SELECT d.start_vid as object_1, d.end_vid as object_2, d.edge AS arc_id, d.node AS node_id
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
		SELECT d.start_vid as object_1, d.end_vid as object_2, d.edge AS arc_id, d.node AS node_id
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

	CREATE INDEX IF NOT EXISTS temp_graph_object_1_object_2_idx ON temp_graph USING btree (object_1, object_2);
	CREATE INDEX IF NOT EXISTS temp_graph_arc_id_idx ON temp_graph USING btree (arc_id);
	CREATE INDEX IF NOT EXISTS temp_graph_node_id_idx ON temp_graph USING btree (node_id);

	UPDATE temp_om_scada_graph t
	SET the_geom = agg.the_geom,
		attrib = agg.attrib,
		expl_add = agg.expl_add
	FROM (
		SELECT g.object_1, g.object_2,
			ST_Multi(ST_LineMerge(ST_Collect(a.the_geom))) AS the_geom,
			json_build_object('arcs', json_agg(a.arc_id)) AS attrib,
			string_agg(DISTINCT a.expl_id::text, ',') AS expl_add
		FROM temp_om_scada_graph g
		JOIN temp_graph t ON g.object_1 = t.object_1 AND g.object_2 = t.object_2
		JOIN arc a ON t.arc_id = a.arc_id
		GROUP BY g.object_1, g.object_2
	) agg
	WHERE t.object_1 = agg.object_1 AND t.object_2 = agg.object_2;

	UPDATE temp_om_scada_graph t
	SET objecttype_1 = cn1.node_type
	FROM node n1
	JOIN cat_node cn1 ON n1.nodecat_id = cn1.id
	WHERE t.object_1 = n1.node_id;

	UPDATE temp_om_scada_graph t
	SET objecttype_2 = cn2.node_type
	FROM node n2
	JOIN cat_node cn2 ON n2.nodecat_id = cn2.id
	WHERE t.object_2 = n2.node_id;

	-- TODO update group_id

	-- update order_id
	v_query_text := '
		SELECT row_number() OVER () AS id, object_1 AS source, object_2 AS target, 1::float AS cost, -1::float as reverse_cost
		FROM temp_om_scada_graph
		WHERE the_geom IS NOT NULL';

	v_pgr_distance := (SELECT count(*)::int FROM temp_om_scada_graph);

	SELECT COALESCE(array_agg(DISTINCT g.object_1), '{}')::int[]
	INTO v_pgr_root_vids
	FROM temp_om_scada_graph g
	WHERE  g.the_geom IS NOT NULL
	AND NOT EXISTS (
		SELECT 1 FROM temp_om_scada_graph g2
		WHERE  g2.the_geom IS NOT NULL
		AND g2.object_2 = g.object_1
	);

	UPDATE temp_om_scada_graph g
	SET order_id = t.order_id
	FROM (
		SELECT pred as node_id, max(agg_cost) AS order_id FROM 
		pgr_drivingDistance(v_query_text, v_pgr_root_vids, v_pgr_distance, directed := true)
		WHERE edge <> -1
		GROUP BY pred
	) t
	WHERE g.object_1 = t.node_id; -- assures to update all the edges, because drivingdistance returns nodes, not edges

	-- ERRORS
	--==========================
	UPDATE temp_om_scada_graph t
	SET error_message =
		CASE

		WHEN NOT EXISTS (SELECT 1 FROM node n WHERE t.object_1 = n.node_id)
			AND NOT EXISTS (SELECT 1 FROM node n WHERE t.object_2 = n.node_id)
		THEN '1. object_1 and object_2 are missing'

		WHEN NOT EXISTS (SELECT 1 FROM node n WHERE t.object_1 = n.node_id)
		THEN '1. object_1 is missing'

		WHEN NOT EXISTS (SELECT 1 FROM node n WHERE t.object_2 = n.node_id)
		THEN '1. object_2 is missing'

		WHEN EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.object_1 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		) AND EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.object_2 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		)
		THEN '2. object_1 and object_2 are obsolete'

		WHEN EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.object_1 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		)
		THEN '2. object_1 is obsolete'

		WHEN EXISTS (
			SELECT 1 FROM node n JOIN value_state_type s ON n.state_type = s.id
			WHERE t.object_2 = n.node_id AND (n.state <> 1 OR s.is_operative = false)
		)
		THEN '2. object_2 is obsolete'

		WHEN NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.object_1 OR a.node_2 = t.object_1)
		) AND NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.object_2 OR a.node_2 = t.object_2)
		)
		THEN '3. object_1 and object_2 are orphan'

		WHEN NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.object_1 OR a.node_2 = t.object_1)
		)
		THEN '3. object_1 is orphan'

		WHEN NOT EXISTS (
			SELECT 1 FROM arc a JOIN value_state_type sa ON a.state_type = sa.id
			WHERE a.state = 1 AND sa.is_operative = TRUE
			AND (a.node_1 = t.object_2 OR a.node_2 = t.object_2)
		)
		THEN '3. object_2 is orphan'

		WHEN t.the_geom IS NULL
		THEN '4. object_1 and object_2 without a valid connection'
	END
	WHERE t.active = TRUE;

	-- Update om_scada_graph if v_commit_changes is TRUE
	--================================================

	IF v_commit_changes IS  TRUE THEN

		-- update is_scadamap = false for obsolete arcs
		WITH old_arc AS (
			SELECT DISTINCT json_array_elements_text(g.attrib::json -> 'arcs')::int AS arc_id
			FROM om_scada_graph g
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

		-- update om_scada_graph for valid connections
		UPDATE om_scada_graph g
		SET the_geom = t.the_geom,
			attrib = t.attrib,
			expl_add = t.expl_add,
			objecttype_1 = t.objecttype_1,
			objecttype_2 = t.objecttype_2,
			order_id = t.order_id
		FROM temp_om_scada_graph t
		WHERE t.the_geom IS NOT NULL
		AND g.object_1 = t.object_1 AND g.object_2 = t.object_2;

		-- update om_scada_graph for invalid connections
		UPDATE om_scada_graph g
        SET 
            objecttype_1 = COALESCE(t.objecttype_1, g.objecttype_1),
            objecttype_2 = COALESCE(t.objecttype_2, g.objecttype_2),
            attrib = NULL,
            order_id = NULL,
            expl_add = (
				SELECT string_agg(DISTINCT v.expl_id::text, ',')
				FROM (VALUES (n1.expl_id), (n2.expl_id)) AS v(expl_id)
				WHERE v.expl_id IS NOT NULL
			)
        FROM temp_om_scada_graph t
        LEFT JOIN node n1 ON t.object_1 = n1.node_id
        LEFT JOIN node n2 ON t.object_2 = n2.node_id
        WHERE t.the_geom IS NULL
        AND g.object_1 = t.object_1 AND g.object_2 = t.object_2; 

	END IF;

	-- SECTION Creating temporal layers
	--==================================

	-- get results - line_valid
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
		SELECT g.object_1, g.objecttype_1, g.object_2, g.objecttype_2, g.order_id, g.expl_add, g.the_geom
		FROM temp_om_scada_graph g
		WHERE g.the_geom IS NOT NULL
		) r
	) f;

	v_result_line_valid := v_result;

	-- get errors info and results - line_invalid
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, concat('CHECK DATA QUALITY - OM_SCADA_GRAPH'));
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, '-------------------------------------');

	INSERT INTO temp_audit_check_data (error_message)
	SELECT concat(count(*),' ', t.error_message) 
	FROM temp_om_scada_graph t
	WHERE t.error_message IS NOT NULL
	GROUP BY t.error_message
	ORDER BY t.error_message;

	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result 
	FROM (SELECT id, error_message as message FROM temp_audit_check_data) row;

	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"geometryType":"", "values":',v_result, '}');

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
			SELECT t.object_1, coalesce(t.objecttype_1, g.objecttype_1) AS objecttype_1, t.object_2, coalesce(t.objecttype_2, g.objecttype_2) AS objecttype_2, t.error_message, g.the_geom
			FROM temp_om_scada_graph t
			JOIN om_scada_graph g ON g.object_1 = t.object_1 AND g.object_2 = t.object_2
			WHERE t.error_message IS NOT NULL
		) r
	) f;

	v_result_line_invalid := v_result;

	v_result_line := jsonb_build_array(
		v_result_line_invalid,
		v_result_line_valid
	)::json;

	--drop temporal tables
	DROP TABLE IF EXISTS temp_om_scada_graph;
	DROP TABLE IF EXISTS temp_audit_check_data;
	DROP TABLE IF EXISTS temp_graph;

	-- Return
	RETURN gw_fct_json_create_return(('{
		"status":"Accepted",
		"message":{
			"level":1,
			"text":"Data quality analysis done succesfully"
		}, 
		"version":"'||v_version||'",
		"body":{
			"form":{},
			"data":{
				"info":'||v_result_info||',
				"line":'||v_result_line||'
			}
		}
	}')::json, 3548, null, null, null);

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;
$function$
;

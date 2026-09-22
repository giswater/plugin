DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_synoptic_core();

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_synoptic_core(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

DECLARE

-- Input vars
v_fct_type text;

-- Vars
v_pgr_distance INTEGER;
v_pgr_root_vids INTEGER	[];
v_iterations INTEGER;
v_updated_rows INTEGER;
v_query_text TEXT;
v_graph_table text;

v_data json;
v_error_context TEXT;

-- result variables

BEGIN

    -- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- Get variables from input JSON
	v_fct_type = (SELECT (p_data::json->>'data')::json->>'fct_type');

    IF v_fct_type = 'SCADA' THEN
		v_graph_table := 'temp_om_scada_graph';
	ELSIF v_fct_type = 'MAPZONE' THEN
		v_graph_table := 'temp_pgr_mapzone_synoptic';
	ELSE
        -- TODO
		--EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		--"data":{"message":"3090", "function":"3508","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
	END IF;

    -- update group_id, level_id, position_id
	EXECUTE format('SELECT count(*)::int FROM %I', v_graph_table) INTO v_pgr_distance;

	v_query_text := format('
		SELECT
			row_number() OVER () AS id,
			g.node_1 AS source,
			g.node_2 AS target,
			1::float AS cost
		FROM %I g
		WHERE g.active = TRUE
		AND g.error_message IS NULL
	', v_graph_table);

	EXECUTE format('
		SELECT COALESCE(array_agg(DISTINCT g.node_1), ''{}'')::int[]
		FROM %I g
		WHERE g.active = TRUE
		AND g.error_message IS NULL
		AND NOT EXISTS (
			SELECT 1 FROM %I g2
			WHERE g2.active = TRUE
			AND g2.error_message IS NULL
			AND g2.node_2 = g.node_1
		)
	', v_graph_table, v_graph_table)
	INTO v_pgr_root_vids;

	-- group_id: for each connected component, assign a group identifier.
	-- For SCADA, this is the minimum root node id (from v_pgr_root_vids).
	-- For mapzones, this is the mapzone_id of the minimum root node id (from v_pgr_root_vids).
	WITH
		connectedcomponents AS (
			SELECT component, node AS node_id
			FROM pgr_connectedcomponents(v_query_text)
		),
		group_ids AS (
			SELECT c.component, min(c.node_id) AS group_id
			FROM connectedcomponents c
			WHERE c.node_id = ANY (v_pgr_root_vids)
			GROUP BY c.component
		)
	INSERT INTO temp_vertice (node_id, group_id)
	SELECT c.node_id, g.group_id
	FROM connectedcomponents c
	JOIN group_ids g ON c.component = g.component;

	IF v_fct_type = 'MAPZONE' THEN
		EXECUTE format('
			UPDATE temp_vertice v
			SET group_id = g.node_2
			FROM %I g
			WHERE v.group_id = g.node_1
		', v_graph_table);
	END IF;

	EXECUTE format('
		UPDATE %I g
		SET group_id = n.group_id
		FROM temp_vertice n
		WHERE g.active = TRUE
		AND g.error_message IS NULL
		AND n.node_id = g.node_1
	', v_graph_table);

	-- level_id
	UPDATE temp_vertice n
	SET level_id = g.level_id
	FROM (
		SELECT node as node_id, max(agg_cost+1) AS level_id
		FROM pgr_drivingDistance(v_query_text, v_pgr_root_vids, v_pgr_distance, directed := true)
		GROUP BY node
	) g
	WHERE n.node_id = g.node_id;

	-- add not-real nodes and not_real arcs for multi-level links - used for complet Sugiyama method
	EXECUTE format('
		UPDATE %I g
		SET is_multilevel = TRUE
		FROM temp_vertice v1, temp_vertice v2
		WHERE v1.node_id = g.node_1
		AND v2.node_id = g.node_2
		AND g.active = TRUE
		AND g.error_message IS NULL
		AND v2.level_id > v1.level_id + 1
	', v_graph_table);

	EXECUTE format('
		WITH
			edges_to_split AS (
				SELECT
					g.node_1,
					g.node_2,
					g.group_id,
					v1.level_id AS level_1,
					v2.level_id AS level_2
				FROM %I g
				JOIN temp_vertice v1 ON v1.node_id = g.node_1
				JOIN temp_vertice v2 ON v2.node_id = g.node_2
				WHERE g.is_multilevel = TRUE
			),
			vertices_levels AS (
				SELECT
					e.node_1,
					e.node_2,
					e.group_id,
					e.level_1,
					e.level_2,
					gs AS level_id
				FROM edges_to_split e
				CROSS JOIN LATERAL generate_series(
					e.level_1+1,
					e.level_2-1
				) gs
			)
		INSERT INTO temp_vertice (node_id, group_id, level_id, is_real, orig_node_1, orig_node_2)
		SELECT -(row_number() OVER ()) AS node_id, group_id, level_id, FALSE AS is_real, node_1, node_2
		FROM vertices_levels
	', v_graph_table);

	EXECUTE format('
		WITH
			vertices_levels AS (
				SELECT
					g.node_1 AS node_id,
					v.level_id,
					g.node_1 AS orig_node_1,
					g.node_2 AS orig_node_2
				FROM %I g
				JOIN temp_vertice v ON v.node_id = g.node_1
				WHERE g.is_multilevel = TRUE
				UNION
				SELECT
					g.node_2 AS node_id,
					v.level_id,
					g.node_1 AS orig_node_1,
					g.node_2 AS orig_node_2
				FROM %I g
				JOIN temp_vertice v ON v.node_id = g.node_2
				WHERE g.is_multilevel = TRUE
				UNION
				SELECT
					v.node_id,
					v.level_id,
					v.orig_node_1,
					v.orig_node_2
				FROM temp_vertice v
				WHERE v.is_real = FALSE
			),
			new_edges AS (
				SELECT
					vl.orig_node_1,
					vl.orig_node_2,
					vl.node_id AS vertice_1,
					lead(vl.node_id) OVER (PARTITION BY vl.orig_node_1, vl.orig_node_2 ORDER BY vl.level_id) AS vertice_2
				FROM vertices_levels vl
			)
		INSERT INTO %I (node_1, node_2, orig_node_1, orig_node_2, group_id, node_type_1, node_type_2, is_real, is_multilevel)
		SELECT
			e.vertice_1,
			e.vertice_2,
			e.orig_node_1,
			e.orig_node_2,
			g.group_id,
			CASE WHEN e.vertice_1 = e.orig_node_1 THEN g.node_type_1
				WHEN e.vertice_1 = e.orig_node_2 THEN g.node_type_2
				ELSE ''VIRTUAL VERTICE''
			END AS node_type_1,
			CASE WHEN e.vertice_2 = e.orig_node_1 THEN g.node_type_1
				WHEN e.vertice_2 = e.orig_node_2 THEN g.node_type_2
				ELSE ''VIRTUAL VERTICE''
			END AS node_type_2,
			FALSE AS is_real,
			FALSE AS is_multilevel
		FROM new_edges e
		JOIN %I g ON g.node_1 = e.orig_node_1 AND g.node_2 = e.orig_node_2
		WHERE e.vertice_2 IS NOT NULL
	', v_graph_table, v_graph_table, v_graph_table, v_graph_table);

	-- position_id 
	-- order root nodes by their coordinates x and y coordinates so their position_id is assigned from left to right
	EXECUTE format('
		SELECT COALESCE(array_agg(t.node_id ORDER BY t.x, t.y), ''{}'')::int[]
		FROM (
			SELECT DISTINCT g.node_1 AS node_id, st_x(n.the_geom) AS x, st_y(n.the_geom) AS y
			FROM %I g
			JOIN node n ON n.node_id = g.node_1
			WHERE g.active = TRUE
			AND g.error_message IS NULL
			AND g.is_multilevel = FALSE
			AND NOT EXISTS (
				SELECT 1 FROM %I g2
				WHERE g2.active = TRUE
				AND g2.error_message IS NULL
				AND g2.is_multilevel = FALSE
				AND g2.node_2 = g.node_1
			)
		) t
	', v_graph_table, v_graph_table)
	INTO v_pgr_root_vids;

	v_query_text := format('
		SELECT
			row_number() OVER () AS id,
			g.node_1 AS source,
			g.node_2 AS target,
			1::float AS cost
		FROM %I g
		WHERE g.group_id IS NOT NULL
		AND g.is_multilevel = FALSE
	', v_graph_table);

	-- 1. initial raw value for position_aux from DFS traversal order (pgr_depthFirstSearch)
	UPDATE temp_vertice n
	SET position_aux = g.position_aux
	FROM (
		SELECT node as node_id, min(seq) AS position_aux
		FROM pgr_depthFirstSearch(v_query_text, v_pgr_root_vids, directed := true)
		GROUP BY node
	) g
	WHERE n.node_id = g.node_id;

	-- 2. normalize position_aux to consecutive positions within each level
	UPDATE temp_vertice n
	SET position_aux = g.position_aux
	FROM (
		SELECT node_id,
			row_number() OVER (PARTITION BY group_id, level_id ORDER BY position_aux) AS position_aux
		FROM temp_vertice
	) g
	WHERE n.node_id = g.node_id;

	-- 3. Sugiyama-style barycenter iterations for hierarchical graphs to reduce link crossings
	v_iterations := 20;

	FOR i IN 1..v_iterations LOOP

		IF i % 2 = 1 THEN
			-- downward pass: update position_aux of node_2 based on its predecessor node_1
      		-- (only consider arcs connecting consecutive levels)
			EXECUTE format('
				UPDATE temp_vertice n
				SET position_aux = bc.avg_pos
				FROM (
					SELECT g.node_2 AS node_id, avg(v1.position_aux) AS avg_pos
					FROM %I g
					JOIN temp_vertice v1 ON v1.node_id = g.node_1
					JOIN temp_vertice v2 ON v2.node_id = g.node_2
					WHERE g.active = TRUE
					AND g.error_message IS NULL
					AND v2.level_id = v1.level_id + 1
					GROUP BY g.node_2
				) bc
				WHERE n.node_id = bc.node_id
				AND n.position_aux IS DISTINCT FROM bc.avg_pos
			', v_graph_table);
		ELSE
			-- upward pass: update position_aux of node_1 based on its successor node_2
      		-- (only consider arcs connecting consecutive levels)
			EXECUTE format('
				UPDATE temp_vertice n
				SET position_aux = bc.avg_pos
				FROM (
					SELECT g.node_1 AS node_id, avg(v2.position_aux) AS avg_pos
					FROM %I g
					JOIN temp_vertice v1 ON v1.node_id = g.node_1
					JOIN temp_vertice v2 ON v2.node_id = g.node_2
					WHERE g.active = TRUE
					AND g.error_message IS NULL
					AND v2.level_id = v1.level_id + 1
					GROUP BY g.node_1
				) bc
				WHERE n.node_id = bc.node_id
				AND n.position_aux IS DISTINCT FROM bc.avg_pos
			', v_graph_table);
		END IF;

		-- re-rank nodes within each level based on the updated barycenter position
		UPDATE temp_vertice t
		SET position_aux = g.position_aux
		FROM (
			SELECT v.node_id,
				row_number() OVER (PARTITION BY v.group_id, v.level_id ORDER BY v.position_aux, st_x(n.the_geom), st_y(n.the_geom), v.node_id) AS position_aux
			FROM temp_vertice v
			LEFT JOIN node n ON n.node_id = v.node_id
		) g
		WHERE t.node_id = g.node_id
		AND t.position_aux IS DISTINCT FROM g.position_aux;

		-- stop early if the ranking has already converged (no changes this iteration)
		GET DIAGNOSTICS v_updated_rows = ROW_COUNT;
		RAISE NOTICE 'Iteration %: % rows updated', i, v_updated_rows;
		EXIT WHEN v_updated_rows = 0;

	END LOOP;

	-- 4. final position_id: position after all barycenter iterations
	UPDATE temp_vertice t
	SET position_id = g.position_id
	FROM (
		SELECT v.node_id,
			row_number() OVER (PARTITION BY v.group_id, v.level_id ORDER BY v.position_aux, st_x(n.the_geom), st_y(n.the_geom), v.node_id) AS position_id
		FROM temp_vertice v
		LEFT JOIN node n ON n.node_id = v.node_id
	) g
	WHERE t.node_id = g.node_id;

	-- 5. update "attrib" with synopticOrder
	EXECUTE format('
		WITH
			all_nodes AS (
				SELECT t.orig_node_1, t.orig_node_2, t.node_1 AS node_id
				FROM %I t
				WHERE t.group_id IS NOT NULL
				AND t.is_multilevel = FALSE
				UNION
				SELECT t.orig_node_1, t.orig_node_2, t.node_2 AS node_id
				FROM %I t
				WHERE t.group_id IS NOT NULL
				AND t.is_multilevel = FALSE
				AND t.node_2 = t.orig_node_2
			),
			synoptic AS (
				SELECT
					an.orig_node_1,
					an.orig_node_2,
					json_build_object(
						''type'', ''LineString'',
						''coordinates'', json_agg(
							json_build_array(v.position_id, v.level_id)
							ORDER BY v.level_id
						)
					) AS synoptic_geometry
				FROM all_nodes an
				JOIN temp_vertice v ON v.node_id = an.node_id
				GROUP BY an.orig_node_1, an.orig_node_2
			)
		UPDATE %I g
		SET attrib = CASE
			WHEN g.attrib::jsonb -> ''arcs'' IS NOT NULL THEN
				json_build_object(
					''synopticGeometry'', s.synoptic_geometry,
					''arcs'', (g.attrib::jsonb -> ''arcs'')
				)
			ELSE
				json_build_object(
					''synopticGeometry'', s.synoptic_geometry
				)
			END
		FROM synoptic s
		WHERE g.node_1 = s.orig_node_1
		AND g.node_2 = s.orig_node_2
	', v_graph_table, v_graph_table, v_graph_table);

	-- TODO RETURN
	RETURN NULL; 
	
	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;
$function$
;
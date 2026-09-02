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
"parameters":{"explId":"551", "action":"fix"}, "aux_params":null}}$$);


Documentation:

The function performs 2 actions (v_action):
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
v_expl_id text;
v_expl_id_array integer[];
v_action TEXT;
v_object_1 integer;
v_object_2 integer;
v_edge_id integer;
v_edge_filter text;

-- Vars
rec record;
v_arcs JSON;
v_fid int = 999;
v_pgr_distance integer;
v_pgr_root_vids int[];

v_query_text TEXT;
v_query_combinations TEXT;
v_error_context text;
v_message text;

-- Return
v_version TEXT;
v_result JSON = '{}';
v_result_info JSON = '{}';
v_result_point JSON = '{}';

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- Input data and init params
	SELECT giswater, upper(project_type), epsg INTO v_version, v_project_type, v_srid FROM sys_version ORDER BY id DESC LIMIT 1;

	v_expl_id := COALESCE(p_data ->'data'->'parameters'->>'explId', p_data ->'data'->>'explId');
	v_action := COALESCE(p_data ->'data'->'parameters'->>'action', p_data ->'data'->>'action');
	v_object_1 := COALESCE((p_data ->'data'->'parameters'->>'object_1')::integer, (p_data ->'data'->>'object_1')::integer);
	v_object_2 := COALESCE((p_data ->'data'->'parameters'->>'object_2')::integer, (p_data ->'data'->>'object_2')::integer);
	v_edge_id := COALESCE((p_data ->'data'->'parameters'->>'edgeId')::integer, (p_data ->'data'->>'edgeId')::integer);

	DROP TABLE IF EXISTS temp_om_scada_graph;
	CREATE TEMP TABLE IF NOT EXISTS temp_om_scada_graph (LIKE SCHEMA_NAME.om_scada_graph INCLUDING ALL);

	IF v_object_1 IS NOT NULL AND v_object_2 IS NOT NULL THEN

		INSERT INTO temp_om_scada_graph 
		SELECT * 
		FROM om_scada_graph WHERE object_1 = v_object_1 AND object_2 = v_object_2;

	ELSE
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

		IF v_action = 'fix' THEN
			v_query_text := $q$
				SELECT edge_id AS id, object_1 AS source, object_2 AS target, 1 AS cost
				FROM om_scada_graph
				WHERE active
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
						WHERE (g.expl_1 = ANY ($1) AND g.object_1 = c.node)
							OR (g.expl_2 = ANY ($1) AND g.object_2 = c.node)
						-- WHERE (g.expl_id && $1 AND g.object_1 = c.node) 
					)
				)
				INSERT INTO temp_om_scada_graph
				SELECT g.*
				FROM om_scada_graph g
				JOIN connectedcomponents c1 ON c1.node = g.object_1
				WHERE g.active
				AND EXISTS (
					SELECT 1
					FROM components cc
					WHERE cc.component = c1.component
				) 
			$sql$, v_query_text)
			USING v_expl_id_array;
		ELSE
			INSERT INTO temp_om_scada_graph 
			SELECT * 
			FROM om_scada_graph
			WHERE active
			AND (
				expl_1 = ANY (v_expl_id_array) OR expl_2 = ANY (v_expl_id_array)
			);
			-- AND g.expl_id && v_expl_id_array;
		END IF;

	END IF;

	CREATE TEMP TABLE IF NOT EXISTS temp_anl_node (LIKE SCHEMA_NAME.anl_node INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_audit_check_data (LIKE SCHEMA_NAME.audit_check_data INCLUDING ALL);

	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, concat('CHECK DATA QUALITY - OM_SCADA_GRAPH'));
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, '-------------------------------------');

	raise notice '1 - object_1 and object_2 must exist and be operative';
	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom, descript)
	SELECT v_fid, '1', g.object_1, n.nodecat_id, s.state, n.expl_id, g.edge_id, n.the_geom, 
	CASE 
		WHEN n.node_id IS NULL THEN concat('Object_1 from edge_id ', g.edge_id, ' no existeix a la taula node.')
		ELSE concat('Object_1 from edge_id ', g.edge_id, ' is obsolete.')
	END AS descript
	FROM temp_om_scada_graph g
	LEFT JOIN node n ON g.object_1 = n.node_id
	LEFT JOIN value_state_type s ON n.state_type = s.id
	WHERE n.node_id IS NULL
	OR n.state <> 1
	OR s.is_operative = false;

	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	SELECT v_fid, '1', g.object_2, n.nodecat_id, s.state, n.expl_id, g.edge_id, n.the_geom, 
	CASE 
		WHEN n.node_id IS NULL THEN concat('Object_2 from edge_id ', g.edge_id, ' no existeix a la taula node.')
		ELSE concat('Object_2 from edge_id ', g.edge_id, ' is obsolete.')
	END AS descript
	FROM temp_om_scada_graph g
	LEFT JOIN node n ON g.object_2 = n.node_id
	LEFT JOIN value_state_type s ON n.state_type = s.id
	WHERE n.node_id IS NULL
	OR n.state <> 1
	OR s.is_operative = false;

	INSERT INTO temp_audit_check_data (error_message)
	SELECT concat(count(DISTINCT arc_id),' edge_id with object_1 or object_2 as obsolete nodes.') 
	FROM temp_anl_node WHERE result_id = '1';

	raise notice '2 - object_1 and object_2 must not be orphan nodes';
	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	SELECT v_fid, '2', g.object_1, n.nodecat_id, sn.state, n.expl_id, g.edge_id, n.the_geom, 
	concat('Object_1 from edge_id ', g.edge_id, ' is orphan.') 
	FROM temp_om_scada_graph g
	JOIN node n ON g.object_1 = n.node_id
	JOIN value_state_type sn ON n.state_type = sn.id
	WHERE n.state = 1 
	AND sn.is_operative = TRUE
	AND NOT EXISTS (
		SELECT 1
		FROM arc a
		JOIN value_state_type sa ON a.state_type = sa.id
		WHERE a.state = 1 AND sa.is_operative = TRUE
		AND (a.node_1 = g.object_1 OR a.node_2 = g.object_1)
	);

	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	SELECT v_fid, '2', g.object_2, n.nodecat_id, sn.state, n.expl_id, g.edge_id, n.the_geom, 
	concat('Object_2 from edge_id ', g.edge_id, ' is orphan.') 
	FROM temp_om_scada_graph g
	JOIN node n ON g.object_2 = n.node_id
	JOIN value_state_type sn ON n.state_type = sn.id
	WHERE n.state = 1 
	AND sn.is_operative = TRUE
	AND NOT EXISTS (
		SELECT 1
		FROM arc a
		JOIN value_state_type sa ON a.state_type = sa.id
		WHERE a.state = 1 AND sa.is_operative = TRUE
		AND (a.node_1 = g.object_2 OR a.node_2 = g.object_2)
	);

	INSERT INTO temp_audit_check_data (error_message)
	SELECT concat(count(DISTINCT arc_id),' edge_id with object_1 or object_2 as orphan nodes') 
	FROM temp_anl_node WHERE result_id = '2';

	INSERT INTO temp_audit_check_data (error_message)
	SELECT concat('The edge_id ', edge_id, ' has at least 1 object_id missing in table of nodes')
	FROM temp_om_scada_graph 
	WHERE object_1 NOT IN (SELECT node_id FROM node)
	OR object_2 NOT IN (SELECT node_id FROM node);	

	IF v_action = 'check' OR EXISTS (SELECT 1 FROM temp_anl_node) THEN

		--points
		SELECT jsonb_agg(features.feature) INTO v_result
		FROM (
	  	SELECT jsonb_build_object(
		'type',       'Feature',
		'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
		'properties', to_jsonb(row) - 'the_geom'
	  	) AS feature
	  	FROM (SELECT node_id, nodecat_id, state, expl_id, arc_id, descript, the_geom FROM temp_anl_node) row) features;
	
		v_result := COALESCE(v_result, '{}'); 
		v_result_point = concat ('{"geometryType":"Point", "features":',v_result, '}');

	ELSIF v_action = 'fix' THEN -- update attrib.om_scada_graph AND ALL obsolete attrs
	
		v_query_combinations := 'SELECT object_1 AS source, object_2 AS target FROM temp_om_scada_graph';

		DROP TABLE IF EXISTS temp_graph;

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

		SELECT string_agg(concat('object_1=', g.object_1, ' and object_2=', g.object_2, '\n'), '')
		INTO v_message
		FROM temp_om_scada_graph g
		WHERE NOT EXISTS (
			SELECT 1 FROM temp_graph t
			WHERE g.object_1 = t.object_1 AND g.object_2 = t.object_2
		);

		IF v_message IS NOT NULL THEN
			RAISE EXCEPTION 'No network path between: %', v_message;
			-- TODO FERRAN: create a function and an error message to be returned
			--EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4480", "function":"2706","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
		ELSE
			--EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4482", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
		END IF;

		-- update is_scadamap
		UPDATE arc a
		SET is_scadamap = TRUE
		WHERE EXISTS (SELECT 1 FROM temp_graph g WHERE g.arc_id = a.arc_id)
		AND a.is_scadamap = FALSE;

		UPDATE node n
		SET is_scadamap = TRUE
		WHERE EXISTS (SELECT 1 FROM temp_graph g WHERE g.node_id = n.node_id)
		AND n.is_scadamap = FALSE;

		-- TODO FERRAN fer UPDATE arc, node SET is_scada = FALSE quan estan en temp_om_scada_graph i no estan en temp_graph

		UPDATE om_scada_graph osg
		SET the_geom = agg.the_geom,
			attrib = agg.attrib,
			expl_add = agg.expl_add
		FROM (
			SELECT g.edge_id,
				ST_Multi(ST_LineMerge(ST_Collect(a.the_geom))) AS the_geom,
				json_build_object('arcs', json_agg(a.arc_id)) AS attrib,
				string_agg(DISTINCT a.expl_id::text, ',') AS expl_add
			FROM temp_om_scada_graph g
			JOIN temp_graph t ON g.object_1 = t.object_1 AND g.object_2 = t.object_2
			JOIN arc a ON t.arc_id = a.arc_id
			GROUP BY g.edge_id
		) agg
		WHERE osg.edge_id = agg.edge_id;

		UPDATE om_scada_graph g
		SET objecttype_1 = cn1.node_type, objecttype_2 = cn2.node_type
		FROM temp_om_scada_graph t
		JOIN node n1 ON t.object_1 = n1.node_id
		JOIN node n2 ON t.object_2 = n2.node_id
		JOIN cat_node cn1 ON n1.nodecat_id = cn1.id
		JOIN cat_node cn2 ON n2.nodecat_id = cn2.id
		WHERE t.edge_id = g.edge_id;

		-- TODO FERRAN update altres camps si falten?

	-- TODO FERRAN millorar aquests 2 FOR
		FOR rec IN -- build COLUMN object_name (from man_addfield table) AND VALUES IN a single query

			WITH mec AS (
				SELECT objecttype_1 AS object_type FROM temp_om_scada_graph
				UNION ALL
				SELECT objecttype_2 AS object_type FROM temp_om_scada_graph
			), moc AS (
				SELECT DISTINCT concat('man_node_', lower(object_type)) AS man_addf_table, b.column_name 
				FROM mec a 
				JOIN  information_Schema.COLUMNS b ON concat('man_node_', lower(object_type)) = b.table_name
				WHERE table_schema = 'SCHEMA_NAME' AND column_name = 'name'
			), mic AS (
				SELECT * FROM moc CROSS JOIN generate_series(1, 2) AS serie
			)
			SELECT *, CASE WHEN column_name = 'name' THEN concat('object_name_', serie) ELSE concat(column_name, '_', serie) END AS om_column
			FROM mic

		LOOP

			v_query_text = 'UPDATE om_scada_graph t SET '||rec.om_column||' = a.'||rec.column_name||' FROM '||rec.man_addf_table||' a WHERE a.node_id::int = t.object_'||rec.serie||' and a.'||rec.column_name||' is not null';
			IF v_edge_id IS NOT NULL THEN
				v_query_text := v_query_text || format(' AND t.edge_id = %s', v_edge_id);
			END IF;
			EXECUTE v_query_text;	
	
		END LOOP;

		-- build COLUMN object_name (from man_tabLe, if column "name" does not exists in man_addfield table)
		FOR rec IN 
		
			WITH mec AS (
				SELECT *, concat('man_', lower(b.feature_class)) AS sys_man_table FROM temp_om_scada_graph g
				CROSS JOIN LATERAL (
								    VALUES 
								        ('object_1', g.object_1, 'objecttype_1', g.objecttype_1,'object_name_1', g.object_name_1),
								        ('object_2', g.object_2, 'objecttype_2', g.objecttype_2, 'object_name_2', g.object_name_2)
								) AS v(object_id_col, object_id_val, object_type_col, object_type_val, object_name_col, object_name)
				LEFT JOIN cat_feature b ON v.object_type_val = b.id
				WHERE v_edge_id IS NULL OR g.edge_id = v_edge_id
			)
			SELECT DISTINCT sys_man_table, concat('object_name_', serie) AS object_name_col, serie FROM mec 
			CROSS JOIN generate_series(1, 2) AS serie
			WHERE sys_man_table IN (
				SELECT table_name FROM information_schema.COLUMNS WHERE table_schema = 'SCHEMA_NAME' AND column_name = 'name' AND table_name ILIKE 'man_%'
			)
		
		LOOP
			
			v_query_text = 'UPDATE om_scada_graph t SET '||rec.object_name_col||' = a.name from '||rec.sys_man_table||' a where a.node_id::int = t.object_'||rec.serie||' and a.name is not null';
			IF v_edge_id IS NOT NULL THEN
				v_query_text := v_query_text || format(' AND t.edge_id = %s', v_edge_id);
			END IF;
		
			EXECUTE v_query_text;
			
		END LOOP;

		-- update order_id
		v_query_text := 'SELECT edge_id AS id, object_1 AS source, object_2 AS target, 1::float AS cost FROM temp_om_scada_graph';

		v_pgr_distance := (SELECT count(*)::int FROM temp_om_scada_graph);

		SELECT COALESCE(array_agg(DISTINCT g.object_1), '{}')::int[]
		INTO v_pgr_root_vids
		FROM temp_om_scada_graph g
		WHERE  NOT EXISTS (SELECT 1 FROM temp_om_scada_graph g2 WHERE  g2.object_2 = g.object_1);

		UPDATE om_scada_graph g
		SET order_id = t.order_id
		FROM (
			SELECT node as node_id, max(agg_cost) AS order_id FROM 
			pgr_drivingDistance(v_query_text, v_pgr_root_vids, v_pgr_distance, directed := true)
			WHERE edge <> -1
			GROUP BY node
		) t
		WHERE g.object_2 = t.node_id; -- assure to update all the edge_ids, because drivingdistance returns nodes, not edges

	END IF;
	

	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result 
	FROM (SELECT id, error_message as message FROM temp_audit_check_data) row;
	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"geometryType":"", "values":',v_result, '}');

	--drop temporal tables
	DROP TABLE IF EXISTS temp_anl_node ;
	DROP TABLE IF EXISTS temp_audit_check_data;
	DROP TABLE IF EXISTS temp_om_scada_graph;
	DROP TABLE IF EXISTS temp_graph;


	-- Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Data quality analysis done succesfully"}, 
	"version":"'||v_version||'","body":{"form":{},"data":{"info":'||v_result_info||',"point":'||v_result_point||'}}}')::json,
	3548, null, null, null);


	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;
$function$
;

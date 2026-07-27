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
v_expl_id text;
v_action TEXT;
v_object_1 integer;
v_object_2 integer;

-- Vars
rec record;
v_arcs JSON;
v_fid int = 999;

-- Return
v_version TEXT;
v_result JSON = '{}';
v_result_info JSON = '{}';
v_result_point JSON = '{}';

v_sql TEXT;
v_error_context text;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- Input data and init params
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_expl_id := COALESCE(p_data ->'data'->'parameters'->>'explId', p_data ->'data'->>'explId');
	v_action := COALESCE(p_data ->'data'->'parameters'->>'action', p_data ->'data'->>'action');
	v_object_1 := COALESCE((p_data ->'data'->'parameters'->>'object_1')::integer, (p_data ->'data'->>'object_1')::integer);
	v_object_2 := COALESCE((p_data ->'data'->'parameters'->>'object_2')::integer, (p_data ->'data'->>'object_2')::integer);

	-- expl_id optional: resolve from om_scada_graph edge (trigger sets expl_1/expl_2 on insert)
	IF v_expl_id IS NULL AND v_object_1 IS NOT NULL AND v_object_2 IS NOT NULL THEN
		SELECT COALESCE(expl_1, expl_2)::text INTO v_expl_id
		FROM om_scada_graph
		WHERE object_1 = v_object_1 AND object_2 = v_object_2
		ORDER BY edge_id DESC LIMIT 1;
	END IF;

	IF v_expl_id IS NULL THEN
	
		SELECT string_agg(expl_id::text, ',') INTO v_expl_id FROM exploitation WHERE expl_id > 0;
		
	END IF;


	CREATE TEMP TABLE IF NOT EXISTS temp_anl_node (LIKE SCHEMA_NAME.anl_node INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_audit_check_data (LIKE SCHEMA_NAME.audit_check_data INCLUDING ALL);

	CREATE TEMP TABLE IF NOT EXISTS v_om_scada_graph AS
	WITH mec AS (
			SELECT a_1.edge_id,
				a_1.order_id,
				a_1.attrib,
				a_1.expl_add,
				a_1.object_name_1,
				a_1.object_name_2,
				a_1.object_1,
				b_1.nodecat_id AS nc_1,
				b_1.dma_id AS dma_id_1,
				b_1.expl_id AS expl_1,
				a_1.object_2,
				c_1.nodecat_id AS nc_2,
				c_1.dma_id AS dma_id_2,
				c_1.expl_id AS expl_2
			FROM om_scada_graph a_1
				LEFT JOIN node b_1 ON a_1.object_1 = b_1.node_id::integer
				LEFT JOIN node c_1 ON a_1.object_2 = c_1.node_id::integer
			)
	SELECT a.edge_id,
		a.order_id,
		a.attrib,
		a.expl_add,
		a.object_1,
		b.node_type AS object_type_1,
		a.expl_1,
		a.dma_id_1,
		e.name AS dma_name_1,
		a.object_name_1,
		a.object_2,
		c.node_type AS object_type_2,
		a.expl_2,
		a.dma_id_2,
		f.name AS dma_name_2,
		a.object_name_2
	FROM mec a
		LEFT JOIN cat_node b ON a.nc_1::text = b.id::text
		LEFT JOIN cat_node c ON a.nc_2::text = c.id::text
		LEFT JOIN dma e ON a.dma_id_1 = e.dma_id
		LEFT JOIN dma f ON a.dma_id_2 = f.dma_id;

	EXECUTE '
	CREATE TEMP TABLE IF NOT EXISTS temp_om_scada_graph AS 
	SELECT a.edge_id, a.the_geom, b.the_geom AS geom_1, c.the_geom AS geom_2,
	a.object_1, a.objecttype_1, b.state AS state_1, a.expl_1, 
	a.object_2, a.objecttype_2, c.state AS state_2, a.expl_2
	FROM om_scada_graph a
	LEFT JOIN node b ON a.object_1 = b.node_id::int
	LEFT JOIN node c ON a.object_2 = c.node_id::int
	WHERE b.expl_id IN ('||v_expl_id||') OR c.expl_id IN ('||v_expl_id||')';


	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, concat('CHECK DATA QUALITY - OM_SCADA_GRAPH'));
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (1, null, 4, '-------------------------------------');



	raise notice '1 - object_1 and object_2 must be operative';
	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	SELECT v_fid, '1', object_1, objecttype_1, state_1, expl_1, edge_id, geom_1, 
	concat('Object_1 from edge_id ', edge_id, ' is obsolete.') 
	FROM temp_om_scada_graph a
	WHERE state_1=0;

	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	SELECT v_fid, '1', object_2, objecttype_2, state_2, expl_2, edge_id, geom_2, 
	concat('Object_2 from edge_id ', edge_id, ' is obsolete.') 
	FROM temp_om_scada_graph a
	WHERE state_2=0;

	INSERT INTO temp_audit_check_data (error_message)
	SELECT concat(count(DISTINCT arc_id),' edge_id with object_1 or object_2 as obsolete nodes.') 
	FROM temp_anl_node WHERE result_id = '1';
	

	raise notice '2 - object_1 and object_2 must not be orphan nodes';
/*
	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom, descript)
	SELECT v_fid, '2', object_1, objecttype_1, state_1, expl_1, edge_id, geom_1, 
	concat('Object_1 from edge_id ', edge_id, ' is orphan.') 
	FROM temp_om_scada_graph a 
	WHERE object_1::text NOT IN (
		SELECT node_1 FROM arc UNION ALL SELECT node_2 FROM arc
	);
*/
	execute 'INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	WITH temp_om_scada_graph AS (
	SELECT a.edge_id, a.the_geom, b.the_geom AS geom_1, c.the_geom AS geom_2,
	a.object_1, a.objecttype_1, b.state AS state_1, a.expl_1, 
	a.object_2, a.objecttype_2, c.state AS state_2, a.expl_2
	FROM om_scada_graph a
	LEFT JOIN node b ON a.object_1 = b.node_id::int
	LEFT JOIN node c ON a.object_2 = c.node_id::int
	WHERE b.expl_id IN ('||v_expl_id||') OR c.expl_id IN ('||v_expl_id||')
	), mec AS (
		SELECT * FROM temp_om_scada_graph a WHERE object_1 IN (SELECT node_1 FROM arc UNION ALL SELECT node_2 FROM arc)
	)
	SELECT '||v_fid||', ''2'', object_1, objecttype_1, state_1, expl_1, edge_id, geom_1, 
	concat(''Object_1 from edge_id '', edge_id, '' is orphan.'') FROM temp_om_scada_graph 
	WHERE object_1 NOT IN (SELECT object_1 FROM mec)';


/*
	INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	SELECT v_fid, '2', object_2, objecttype_2, state_2, expl_2, edge_id, geom_2, 
	concat('Object_2 from edge_id ', edge_id, ' is orphan.') 
	FROM temp_om_scada_graph a
	WHERE a.object_2::text NOT IN (
		SELECT node_1 FROM arc UNION ALL SELECT node_2 FROM arc
	);
*/
	execute 'INSERT INTO temp_anl_node (fid, result_id, node_id, nodecat_id, state, expl_id, arc_id, the_geom,descript)
	WITH temp_om_scada_graph AS (
	SELECT a.edge_id, a.the_geom, b.the_geom AS geom_1, c.the_geom AS geom_2,
	a.object_1, a.objecttype_1, b.state AS state_1, a.expl_1, 
	a.object_2, a.objecttype_2, c.state AS state_2, a.expl_2
	FROM om_scada_graph a
	LEFT JOIN node b ON a.object_1 = b.node_id::int
	LEFT JOIN node c ON a.object_2 = c.node_id::int
	WHERE b.expl_id IN ('||v_expl_id||') OR c.expl_id IN ('||v_expl_id||')
	), mec AS (
		SELECT * FROM temp_om_scada_graph a WHERE object_2 IN (SELECT node_1 FROM arc UNION ALL SELECT node_2 FROM arc)
	)
	SELECT '||v_fid||', ''2'', object_2, objecttype_2, state_2, expl_2, edge_id, geom_2, 
	concat(''Object_2 from edge_id '', edge_id, '' is orphan.'') FROM temp_om_scada_graph 
	WHERE object_2 NOT IN (SELECT object_2 FROM mec)';

	INSERT INTO temp_audit_check_data (error_message)
	SELECT concat(count(DISTINCT arc_id),' edge_id with object_1 or object_2 as orphan nodes') 
	FROM temp_anl_node WHERE result_id = '2';

	INSERT INTO temp_audit_check_data (error_message)
	SELECT concat('The edge_id ', edge_id, ' has at least 1 object_id missing in table of nodes') FROM temp_om_scada_graph 
	WHERE object_1 NOT IN (SELECT node_id FROM node)
	OR object_2 NOT IN (SELECT node_id FROM node);

	

	IF v_action = 'check' then

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
	
		FOR rec IN EXECUTE '
		SELECT edge_id, object_1, object_2, expl_1, expl_2 FROM om_scada_graph
		WHERE (expl_1 IN ('||v_expl_id||') OR expl_2 IN ('||v_expl_id||'))
		ORDER BY edge_id asc'
		LOOP
	
			RAISE NOTICE '%', rec.edge_id;
			
			EXECUTE format(
			'SELECT json_build_object(
				''arcs'', json_agg(edge)
			) FROM pgr_dijkstra(
			    	''SELECT arc_id::int AS id, node_1::int AS source, node_2::int AS target, 1.0 AS cost 
					FROM arc where state=1 and node_1 is not null and node_2 is not null'',
			    %s, %s, directed := false
		    )res
		    LEFT JOIN om_scada_graph g ON res.edge = g.edge_id',
		    rec.object_1,
		    rec.object_2
		   	) INTO v_arcs;
		   	
		   	UPDATE om_scada_graph SET attrib = v_arcs WHERE edge_id = rec.edge_id;
		
		END LOOP;
	
		EXECUTE '
		UPDATE om_scada_graph t
		SET 
		objecttype_1 = a.object_type_1, objecttype_2 = a.object_type_2, 
		dma_id_1 = a.dma_id_1, dma_name_1 = a.dma_name_1, dma_id_2 = a.dma_id_2, dma_name_2 = a.dma_name_2,
		expl_1 = a.expl_1, expl_2 = a.expl_2 FROM (
		SELECT edge_id, order_id, attrib,
		object_1, object_type_1, expl_1, dma_id_1, dma_name_1, 
		object_2, object_type_2, expl_2, dma_id_2, dma_name_2
		FROM v_om_scada_graph
		)a WHERE t.edge_id = a.edge_id';
	
		FOR rec IN -- build COLUMN object_name (from man_addfield table) AND VALUES IN a single query

			WITH mec AS (
				SELECT object_type_1 AS object_type FROM v_om_scada_graph UNION ALL
				SELECT object_type_2 FROM v_om_scada_graph
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
			
			RAISE NOTICE '%', rec;
		
			v_sql = 'UPDATE om_scada_graph t SET '||rec.om_column||' = a.'||rec.column_name||' FROM '||rec.man_addf_table||' a WHERE a.node_id::int = t.object_'||rec.serie||' and a.'||rec.column_name||' is not null';
			EXECUTE v_sql;	
	
		END LOOP;


		-- build COLUMN object_name (from man_tabLe, if column "name" does not exists in man_addfield table)
		FOR rec IN 
		
			WITH mec AS (
				SELECT *, concat('man_', lower(b.feature_class)) AS sys_man_table FROM om_scada_graph g
				CROSS JOIN LATERAL (
								    VALUES 
								        ('object_1', g.object_1, 'objecttype_1', g.objecttype_1,'object_name_1', g.object_name_1),
								        ('object_2', g.object_2, 'objecttype_2', g.objecttype_2, 'object_name_2', g.object_name_2)
								) AS v(object_id_col, object_id_val, object_type_col, object_type_val, object_name_col, object_name)
				LEFT JOIN cat_feature b ON v.object_type_val = b.id
			)
			SELECT DISTINCT sys_man_table, concat('object_name_', serie) AS object_name_col, serie FROM mec 
			CROSS JOIN generate_series(1, 2) AS serie
			WHERE sys_man_table IN (
				SELECT table_name FROM information_schema.COLUMNS WHERE table_schema = 'SCHEMA_NAME' AND column_name = 'name' AND table_name ILIKE 'man_%'
			)
		
		LOOP
			
			v_sql = 'UPDATE om_scada_graph t SET '||rec.object_name_col||' = a.name from '||rec.sys_man_table||' a where a.node_id::int = t.object_'||rec.serie||' and a.name is not null';
		
			EXECUTE v_sql;
			
		END LOOP;
	
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
	DROP TABLE IF EXISTS v_om_scada_graph;


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

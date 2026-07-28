/*
This file is part of Giswater 3
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This version of Giswater is provided by Giswater Association
*/


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getdmagraph(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

-- Function code: 3338

/*
EXAMPLE:

SELECT gw_fct_getdmagraph($${"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{},"data":{"parameters":{"explId":1, "searchDistRouting":999}}}$$);

*/

DECLARE

-- input params --
v_expl_id INTEGER;
v_search_dist INTEGER;

-- vars --
v_srid INTEGER;
rec_meter RECORD;
v_tank_id INTEGER;
rec RECORD;
v_sql_pgrouting TEXT;
v_sql TEXT;
v_schema_date date;
v_json_result_header json;
v_json_result_nodes json;
v_json_result_links json;
v_json_result_return json;

-- return --
v_version TEXT;
v_result_info TEXT;
v_message JSON;


BEGIN
	
	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- Input params
	v_expl_id = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'explId')::integer;
	v_search_dist = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'searchDistRouting')::integer;
	SELECT "date", giswater, epsg INTO v_schema_date, v_version, v_srid FROM sys_version ORDER BY giswater DESC LIMIT 1;

	-- Create temp tables
	CREATE TEMP TABLE temp_dma_order AS 
	SELECT NULL::int AS meter_id, NULL::int AS dma_1, NULL::int AS dma_2, NULL::integer AS agg_cost;

	-- Reset values
	DELETE FROM dma_graph_meter WHERE expl_id = v_expl_id;
	DELETE FROM dma_graph_object WHERE expl_id = v_expl_id;

	-- Get topology of dma's: 
	v_sql_pgrouting = 'WITH entr AS (SELECT node_id, dma_id AS dma_2 FROM mapzone_graph WHERE mapzone_type = ''DMA'' AND flow_sign = 1),
	sort AS (SELECT node_id, dma_id AS dma_1 FROM mapzone_graph WHERE mapzone_type = ''DMA'' AND flow_sign = -1)
	SELECT node_id AS id, 
	case when dma_1 IS NULL THEN 0 else dma_1 end AS source,
	case when dma_2 IS NULL THEN 0 else dma_2 end AS target, 
	1 AS cost FROM entr 
	LEFT JOIN sort USING (node_id)
	JOIN node n USING (node_id) 
	WHERE n.state = 1 
	AND n.expl_id = '||v_expl_id||'';

	-- Get the flooding order of the dma's USING previous query
	FOR rec in execute 'SELECT DISTINCT "source" from ('||v_sql_pgrouting||')a'
	LOOP
		
		v_sql = '
		INSERT INTO temp_dma_order (meter_id, dma_1, dma_2, agg_cost)
		SELECT edge AS meter_id, '||rec."source"||' AS dma_1, node AS dma_2, agg_cost 
		FROM pgr_drivingDistance('||quote_literal(v_sql_pgrouting)||', '||rec."source"||', '||v_search_dist||')
		';

		EXECUTE v_sql;
	
	END LOOP;
	

	-- STEP 1.1 Fill the table dma_graph_meter (the tanks are represented with meter_id = 0)
	INSERT INTO dma_graph_meter (meter_id, object_1, object_2, expl_id,	the_geom, order_id) 
	SELECT DISTINCT a.meter_id, a.dma_1, a.dma_2, n.expl_id,
    st_makeline(CASE WHEN d.the_geom IS NULL THEN n.the_geom ELSE st_centroid(d.the_geom) end, st_centroid(e.the_geom)) AS the_geom,    
    a.agg_cost AS order_id
    FROM temp_dma_order a
    JOIN node n ON a.meter_id = n.node_id
    LEFT JOIN dma d ON d.dma_id = a.dma_1 
    LEFT JOIN dma e ON e.dma_id = a.dma_2
    WHERE n.expl_id = v_expl_id AND a.agg_cost = 1
    ON CONFLICT (meter_id) DO NOTHING;

   	-- STEP 1.2 Fill the table dma_graph_object (it contains dma's AND tanks)
	
	-- INSERT dmas
	INSERT INTO dma_graph_object (object_id, object_type, the_geom, order_id)
	SELECT DISTINCT d.dma_id, 'DMA', st_centroid(the_geom), min(b.agg_cost) 
	FROM mapzone_graph a
	LEFT JOIN dma d USING (dma_id) 
	LEFT JOIN temp_dma_order b ON dma_id = b.dma_2
	WHERE v_expl_id = ANY(d.expl_id) AND a.mapzone_type = 'DMA'
	group by d.dma_id, st_centroid(the_geom)
	ON CONFLICT (object_id) DO NOTHING;

	-- INSERT tanks (pgr_drivingdistnace): take them from the meter_id WHERE dma_1 = 0 AND dma_2 > 0
	-- prepare graph: go backwards from the meter to look for the tank upstream
	v_sql_pgrouting = '
		SELECT arc_id AS id, 
        node_1 AS source, node_2 AS target, 1 as cost, 1 as reverse_cost, b.closed as closed_1, c.closed as closed_2
        FROM arc a
        LEFT JOIN man_valve b ON a.node_1 = b.node_id
        LEFT JOIN man_valve c ON a.node_2 = c.node_id
        WHERE a.dma_id < 1
        AND a.state = 1
        AND (node_1 IS NOT NULL AND node_2 IS NOT NULL)
        AND (b.closed IS NOT true OR c.closed IS NOT true)
	';

   	FOR rec_meter IN  
		SELECT meter_id FROM temp_dma_order a LEFT JOIN node b ON a.meter_id = b.node_id
		WHERE dma_1 = 0 AND dma_2 > 0 AND b.expl_id = v_expl_id
   	LOOP

	   	v_sql = '
	   	SELECT a.node from pgr_drivingdistance('||quote_literal(v_sql_pgrouting)||', '||rec_meter.meter_id||', '||v_search_dist||') a
		JOIN node b ON a.node = b.node_id 
		JOIN cat_node c on b.nodecat_id = c.id
		JOIN cat_feature e on c.node_type = e.id
		WHERE e.feature_class = ''TANK''
		ORDER BY agg_cost ASC LIMIT 1';

		EXECUTE v_sql INTO v_tank_id;
   	   
   	   	IF v_tank_id IS NOT NULL AND rec_meter.meter_id::text NOT IN (SELECT graphconfig -> 'use' -> 0 ->> 'nodeParent' FROM dma WHERE dma_type = 'CAUD_ALTA') 
   	   	THEN -- there IS a tank upstream FROM the meter_is
   	   	
   	   		RAISE NOTICE 'tank: %, meter: %', v_tank_id, rec_meter.meter_id;
   	   	
   	   		EXECUTE 'INSERT INTO dma_graph_meter (meter_id, expl_id, object_1, object_2, order_id)
   	   		VALUES ('||v_tank_id||', '||v_expl_id||', '||v_tank_id||', '||rec_meter.meter_id||', 0)
			ON CONFLICT (meter_id, expl_id) DO NOTHING';
   	   	
   	   		EXECUTE 'UPDATE dma_graph_meter SET object_1 = '||v_tank_id||' WHERE meter_id = '||rec_meter.meter_id||'';
   	   		
   	   		EXECUTE '
	   	   	INSERT INTO dma_graph_object (object_id, object_type, expl_id, order_id) 
			SELECT  '||v_tank_id||', ''TANK'', c.expl_id, b.agg_cost FROM dma_graph_meter a 
			LEFT JOIN temp_dma_order b USING (meter_id)
			LEFT JOIN node c ON b.meter_id = c.node_id
			WHERE b.meter_id = '||rec_meter.meter_id||'
			ON CONFLICT (object_id, expl_id) DO NOTHING	
			';
		
			UPDATE dma_graph_object t SET the_geom = a.the_geom FROM (
				SELECT node_id, the_geom FROM node
			)a WHERE t.object_id = a.node_id;
		
		END IF;
				
	END LOOP;


	-- for those meter_id = 0, replace the 0 by the upstream expl_id from the meter_id
	FOR rec_meter IN (SELECT * from dma_graph_meter WHERE object_1 = 0)
	loop
	
		UPDATE dma_graph_meter set object_1 = a.expl_id from (
			WITH mec AS (
				SELECT arc_id::text, expl_id FROM arc 
				WHERE node_1 = rec_meter.meter_id
				OR node_2 = rec_meter.meter_id
				), moc AS (
					SELECT REPLACE((graphconfig->'use'->0->'nodeParent')::text, '"', '') AS meter_id,
					(graphconfig->'use'->0->'toArc'->0)::text AS arc_id FROM dma 
					WHERE REPLACE((graphconfig->'use'->0->'nodeParent')::text, '"', '') = rec_meter.meter_id::text
				)
				SELECT expl_id FROM mec LEFT JOIN moc USING (arc_id) WHERE meter_id IS NULL LIMIT 1
		)a WHERE meter_id = rec_meter.meter_id;
	
	END LOOP;

	-- Step 2.1 Calculate stats for table dma_graph_meter
	UPDATE dma_graph_meter t SET attrib = a.attrib FROM (
		SELECT c.meter_id,
		json_build_object(
		    'networkPressureType', a.category_type,
		    'meterId', c.meter_id,
		    'meterTransmission', b.matcat_id
		    ) AS attrib FROM node a
		   	LEFT JOIN cat_node b ON a.nodecat_id = b.matcat_id
		    JOIN dma_graph_meter c ON a.node_id = c.meter_id
	)a WHERE t.meter_id = a.meter_id AND expl_id = v_expl_id;

	-- Step 2.2 Calculate stats for table dma_graph_object
	UPDATE dma_graph_object t SET attrib = a.json_stats::json FROM (
		WITH dma_graph_stats AS (
		    WITH aa AS ( -- pipe len
			    SELECT dma_id, round(sum(st_length(the_geom)::numeric/1000), 2) AS pipe_length
			    FROM arc WHERE state = 1 GROUP BY dma_id
		    ), bb AS ( -- total connecs
			    SELECT dma_id, count(*) AS n_connecs
			    FROM connec WHERE state = 1 GROUP BY dma_id
		    ), cc AS ( -- total hydrometers
			    SELECT c.dma_id, count(erh.hydrometer_id) AS n_hydro FROM v_hydrometer erh 
			    JOIN connec c ON c.customer_code = erh.feature_customer_code GROUP BY c.dma_id
		    ), dd AS ( -- total pumps
			    SELECT a.dma_id, count(a.node_id) AS n_pump FROM node a 
			    LEFT JOIN cat_node b ON a.nodecat_id = b.id 
				LEFT JOIN cat_feature c ON b.node_type = c.id
				WHERE feature_class = 'PUMP'
				AND a.state = 1 GROUP BY b.node_type, a.dma_id
		    ), ee AS ( -- total valve
			    SELECT a.dma_id, count(*) AS n_vrp FROM node a
			    LEFT JOIN cat_node b ON a.nodecat_id = b.id 
				LEFT JOIN cat_feature c ON b.node_type = c.id
				WHERE feature_class = 'VALVE'
				AND a.state = 1 GROUP BY b.node_type, a.dma_id
		    ), all_tab AS (
			    SELECT dma_id, 
			    coalesce(aa.pipe_length, 0) AS pipe_length, 
			    coalesce(bb.n_connecs, 0) AS n_connecs, 
			    coalesce(cc.n_hydro, 0) AS n_hydro, 
			    coalesce(dd.n_pump, 0) AS n_pump, 
			    coalesce(ee.n_vrp, 0) AS n_vrp FROM aa 
			        LEFT JOIN bb USING (dma_id)
			        LEFT JOIN cc USING (dma_id)
			        LEFT JOIN dd USING (dma_id)
			        LEFT JOIN ee USING (dma_id)
		    )
		    SELECT dma_id, json_build_object(
		    'pipeLength', pipe_length,
		    'numConnecs', n_connecs,
		    'numHydro', n_hydro,
		    'numPump', n_pump,
		    'numVrp', n_vrp
		    )::text AS json_stats FROM all_tab
		)
		SELECT DISTINCT a.dma_id AS object_id, a.json_stats FROM dma_graph_stats a
		LEFT JOIN dma b USING (dma_id)
		LEFT JOIN temp_dma_order c ON b.graphconfig -> 'use' -> 0 ->> 'nodeParent' = c.meter_id::text
	)a WHERE a.object_id = t.object_id;
	
	-- Step 3 Fill other columns
	UPDATE dma_graph_object t SET object_label = a.name FROM (SELECT node_id, name FROM man_tank)a WHERE t.object_id = a.node_id::int;
	UPDATE dma_graph_object t SET object_label = a.name FROM (SELECT dma_id, name FROM dma)a WHERE t.object_id = a.dma_id;
	UPDATE dma_graph_object SET coord_x = st_x(the_geom) WHERE expl_id = v_expl_id;
	UPDATE dma_graph_object SET coord_y = st_y(the_geom) WHERE expl_id = v_expl_id;

	-- UPDATE agg_cost for DMAs (object_1 AND object_2)
	UPDATE dma_graph_object a SET order_id = b.max_cost FROM (
		SELECT a.object_1, max(b.agg_cost) AS max_cost FROM dma_graph_meter a 
		LEFT JOIN temp_dma_order b USING (meter_id) GROUP BY meter_id, expl_id, object_1, object_2, the_geom
	)b WHERE a.object_id = b.object_1;
	
	UPDATE dma_graph_object a SET order_id = b.max_cost FROM (
		SELECT a.object_2, max(b.agg_cost) AS max_cost FROM dma_graph_meter a 
		LEFT JOIN temp_dma_order b USING (meter_id) GROUP BY meter_id, expl_id, object_1, object_2, the_geom
	)b WHERE a.object_id = b.object_2;
	
	-- build topology of meters into table of nodes
	UPDATE dma_graph_object t SET meter_2 = a.meter_1 FROM (
		SELECT object_1, array_agg(meter_id) AS meter_1 
		FROM dma_graph_meter WHERE expl_id = v_expl_id 
		GROUP BY object_1
	)a WHERE t.object_id = a.object_1 AND t.expl_id = v_expl_id;

	UPDATE dma_graph_object t SET meter_1 = a.meter_2 FROM (
		SELECT object_2, array_agg(meter_id) AS meter_2 
		FROM dma_graph_meter WHERE expl_id = v_expl_id 
		GROUP BY object_2
	)a WHERE t.object_id = a.object_2 AND t.expl_id = v_expl_id;

	UPDATE dma_graph_object 
	SET meter_1 = array_remove(meter_1, object_id), meter_2 = array_remove(meter_2, object_id) 
	WHERE expl_id = v_expl_id;

	UPDATE dma_graph_meter t SET the_geom = a.line_tank FROM (
		SELECT a.meter_id, st_makeline(n.the_geom, st_centroid(b.the_geom)) AS line_tank FROM dma_graph_meter a
		LEFT JOIN node n ON a.object_1 = n.node_id::int
		LEFT JOIN dma b ON a.object_2 = b.dma_id::int
		WHERE st_makeline(n.the_geom, st_centroid(b.the_geom)) IS NOT NULL
	)a WHERE t.meter_id = a.meter_id;


	UPDATE dma_graph_meter t SET order_id = max_agg_cost FROM (
		SELECT a.meter_id, max(b.agg_cost) AS max_agg_cost from dma_graph_meter a 
		JOIN temp_dma_order b USING (meter_id)
		WHERE a.expl_id = v_expl_id
		GROUP BY meter_id, expl_id
	)a WHERE t.meter_id = a.meter_id;


	-- clean data
	UPDATE dma_graph_object SET order_id = 0 WHERE object_type = 'TANK';
	UPDATE dma_graph_object SET meter_1 = NULL WHERE object_type = 'TANK';
	DELETE FROM dma_graph_meter WHERE meter_id = object_1 AND expl_id = v_expl_id;

	DROP TABLE IF EXISTS temp_dma_order;

	-- Build Network info:
	SELECT json_build_object(
		'name', concat(v_expl_id, ' - ', e.name), 
		'description', concat('DMA graph of ', e.name),
		'macroExpl', concat(e.macroexpl_id, ' - ', f.name),
		'generatedDate', now(),
		'schemaDate', v_schema_date
	) INTO v_json_result_header
	FROM node n 
	JOIN exploitation e USING (expl_id) 
	JOIN macroexploitation f ON e.macroexpl_id = f.macroexpl_id
	WHERE e.expl_id = v_expl_id
	LIMIT 1;


	-- Build key "nodes" (table dma_graph_object)
	SELECT 
	json_agg(
		json_build_object(
		'id', object_id,
		'type', object_type,
		'label', object_label,
		'attributes', attrib::json,
		'orderId', order_id,
		'fromMeter', meter_1,
		'toMeter', meter_2,
		'coordPosition', json_build_object('x', round(ST_X(the_geom)::numeric, 3), 'y', round(st_y(the_geom)::numeric, 3))
		)
	) INTO v_json_result_nodes
	FROM dma_graph_object
	WHERE expl_id = v_expl_id;
	
	
	-- Build key "links" (table dma_graph_meter)
	SELECT 
	json_agg(
		json_build_object(
		'id', meter_id,
		'type', 'METER',
		'fromNode', object_1,
		'toNode', object_2,
		'orderId', order_id,
		'attributes', attrib::json
		) 
	) INTO v_json_result_links 
	FROM dma_graph_meter a
	WHERE expl_id = v_expl_id;


	SELECT jsonb_build_object('level', log_level,'text', error_message) INTO v_message FROM sys_message WHERE id = 3700;

	v_json_result_return = json_build_object(
		'networkInfo', v_json_result_header, 
		'nodes' ,v_json_result_nodes, 
		'links', v_json_result_links
	);
	
	
	v_version = COALESCE(v_version, '{}');
	v_result_info = COALESCE(v_result_info, '{}');
	v_json_result_return = COALESCE(v_json_result_return, '{}');

	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":'||v_message||', "version":"'||v_version||'", 
	"body":{"form":{},"data":{"result":'||v_json_result_return||'}}}')::json, 3338, null, null, null);

END;

$function$
;

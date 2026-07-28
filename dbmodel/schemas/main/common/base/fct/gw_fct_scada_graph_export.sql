/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_scada_graph_export();

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_scada_graph_export(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*

- Example:

SELECT SCHEMA_NAME.gw_fct_scada_graph_export($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"parameters":{"explId":513, "searchDistRouting":999}}}$$);


- Documentation:
It takes the row of table "om_scada_graph" according to the expl_id (v_expl_id) and it creates a JSON which is inserted into table "om_scada_graph_json".

 */


DECLARE
v_schema_date date;
v_json_result_header json;
v_json_result_nodes json;
v_json_result_links json;
v_json_result_return json;
v_expl_id integer;
v_object_1 integer;
v_object_2 integer;
v_result JSON;
v_Result_info JSON;
v_error_context text;
BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;
	-- Input params
	SELECT "date" INTO v_schema_date FROM sys_version ORDER BY giswater DESC LIMIT 1;
	v_expl_id := COALESCE(
		(p_data -> 'data' -> 'parameters' ->> 'explId')::integer,
		(p_data -> 'data' ->> 'explId')::integer
	);
	v_object_1 := COALESCE((p_data -> 'data' -> 'parameters' ->> 'object_1')::integer, (p_data -> 'data' ->> 'object_1')::integer);
	v_object_2 := COALESCE((p_data -> 'data' -> 'parameters' ->> 'object_2')::integer, (p_data -> 'data' ->> 'object_2')::integer);

	IF v_expl_id IS NULL AND v_object_1 IS NOT NULL AND v_object_2 IS NOT NULL THEN
		SELECT COALESCE(expl_1, expl_2) INTO v_expl_id
		FROM om_scada_graph
		WHERE object_1 = v_object_1 AND object_2 = v_object_2
		ORDER BY edge_id DESC LIMIT 1;
	END IF;

	IF v_expl_id IS NULL THEN
		SELECT COALESCE(expl_1, expl_2) INTO v_expl_id FROM om_scada_graph ORDER BY edge_id DESC LIMIT 1;
	END IF;

	IF v_expl_id IS NULL THEN
		RETURN gw_fct_json_create_return(('{"status":"Failed", "message":{"level":2, "text":"explId could not be resolved from om_scada_graph"}, "version":""'||
			',"body":{"form":{},"data":{}}}')::json, 3546, null, null, null);
	END IF;

	-- Build Network info:
	SELECT json_build_object(
		'name', concat('Network graph'),
		'entity', '',
		'generatedDate', now(),
		'schemaDate', v_schema_date
	) INTO v_json_result_header;

	
	-- Build key "links" (table om_scada_graph)
  SELECT 
	json_agg(
		json_build_object(
		'edgeId', edge_id,
		'orderId', order_id,
		'fromNode', object_1,
		'nodeType1', objecttype_1,
		'nodeName1', object_name_1,
		'explId1', expl_1,
		'dma_id_1', dma_id_1,
		'dma_name_1', dma_name_1,
		'toNode', object_2,
		'nodeType2', objecttype_2,
		'nodeName2', object_name_2,
		'explId2', expl_2,		
		'dma_id_2', dma_id_2,
		'dma_name_2', dma_name_2,
		'sist_com_1', sist_com_1,
		'sist_com_2', sist_com_2,
		'attributes', attrib::JSON,
		'explAdd',expl_add
	)
	) INTO v_json_result_links
	FROM om_scada_graph a
	WHERE (expl_1 = v_expl_id OR expl_2 = v_expl_id) OR v_expl_id::text IN (expl_add);
	

	v_json_result_return = json_build_object(
		'networkInfo', v_json_result_header, 
		'links', v_json_result_links
	);


	INSERT INTO om_scada_graph_json (expl_id, om_scada_graph_json, insert_tstamp, update_tstamp)
	SELECT v_expl_id, v_json_result_return::json, now(), now()
	ON CONFLICT (expl_id) DO UPDATE 
	SET om_scada_graph_json= excluded.om_scada_graph_json,
	update_tstamp = now();


	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result 
	FROM (SELECT 1, concat('Network Graph generated for expl_id ', v_expl_id) as message) row;
	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"geometryType":"", "values":',v_result, '}');

	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Network JSON graph successfully created"}, "version":""'||
				',"body":{"form":{}'||
				',"data":{  "info":'||v_result_info||', "result":'||v_json_result_return||'}}'||
			'}')::json, 3546, null, null, null);

EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;

$function$
;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_scada_graph_build(json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_scada_graph_build(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*
Example:

SELECT SCHEMA_NAME.gw_fct_scada_graph_build($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831},
"form":{}, "feature":{}, "data":{"parameters":{"object_1":1109, "object_2":1075}}}$$);

Documentation:

Orchestrates the scada graph Accept pipeline:
1. INSERT om_scada_graph (object_1, object_2) -> gw_trg_scada_graph_builder trigger
2. gw_fct_scada_graph_check (action fix)
3. gw_fct_scada_graph_export

gw_fct_scada_graph_check and gw_fct_scada_graph_export remain available for standalone use.
*/

DECLARE
v_object_1 integer;
v_object_2 integer;
v_edge_id integer;
v_search_dist_routing integer;
v_version text;
v_check_data json;
v_export_data json;
v_check_result json;
v_export_result json;
v_export_data_body json;
v_check_data_body json;
v_error_context text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_object_1 := COALESCE((p_data -> 'data' -> 'parameters' ->> 'object_1')::integer, (p_data -> 'data' ->> 'object_1')::integer);
	v_object_2 := COALESCE((p_data -> 'data' -> 'parameters' ->> 'object_2')::integer, (p_data -> 'data' ->> 'object_2')::integer);
	v_search_dist_routing := COALESCE(
		(p_data -> 'data' -> 'parameters' ->> 'searchDistRouting')::integer,
		(p_data -> 'data' ->> 'searchDistRouting')::integer,
		999
	);

	IF v_object_1 IS NULL OR v_object_2 IS NULL THEN
		RETURN gw_fct_json_create_return(('{"status":"Failed", "message":{"level":2, "text":"object_1 and object_2 are required"},
			"version":"'||v_version||'","body":{"form":{},"data":{}}}')::json, 3547, null, null, null);
	END IF;

	IF v_object_1 = v_object_2 THEN
		RETURN gw_fct_json_create_return(('{"status":"Failed", "message":{"level":2, "text":"object_1 and object_2 must be different"},
			"version":"'||v_version||'","body":{"form":{},"data":{}}}')::json, 3547, null, null, null);
	END IF;

	INSERT INTO om_scada_graph (object_1, object_2)
	VALUES (v_object_1, v_object_2)
	RETURNING edge_id INTO v_edge_id;

	v_check_data := jsonb_set(
		COALESCE(p_data::jsonb, '{}'::jsonb),
		'{data,parameters}',
		COALESCE(p_data -> 'data' -> 'parameters', '{}'::json)::jsonb
			|| jsonb_build_object('object_1', v_object_1, 'object_2', v_object_2, 'action', 'fix')
	)::json;

	v_check_result := gw_fct_scada_graph_check(v_check_data);
	IF v_check_result ->> 'status' IS DISTINCT FROM 'Accepted' THEN
		RETURN v_check_result;
	END IF;

	v_export_data := jsonb_set(
		COALESCE(p_data::jsonb, '{}'::jsonb),
		'{data,parameters}',
		COALESCE(p_data -> 'data' -> 'parameters', '{}'::json)::jsonb
			|| jsonb_build_object(
				'object_1', v_object_1,
				'object_2', v_object_2,
				'searchDistRouting', v_search_dist_routing
			)
	)::json;

	v_export_result := gw_fct_scada_graph_export(v_export_data);
	IF v_export_result ->> 'status' IS DISTINCT FROM 'Accepted' THEN
		RETURN v_export_result;
	END IF;

	v_check_data_body := COALESCE(v_check_result -> 'body' -> 'data', '{}'::json);
	v_export_data_body := COALESCE(v_export_result -> 'body' -> 'data', '{}'::json);

	RETURN gw_fct_json_create_return(json_build_object(
		'status', 'Accepted',
		'message', json_build_object('level', 1, 'text', 'Scada graph edge created successfully'),
		'version', v_version,
		'body', json_build_object(
			'form', '{}'::json,
			'data', json_build_object(
				'edgeId', v_edge_id,
				'object_1', v_object_1,
				'object_2', v_object_2,
				'check', v_check_data_body,
				'export', v_export_data_body
			)
		)
	)::json, 3547, null, null, null);

EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;
$function$
;

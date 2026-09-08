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
"form":{}, "feature":{}, "data":{"parameters":{"node_1":1109, "node_2":1075}}}$$);

Documentation:

Accept pipeline:
1. Reject duplicate (node_1, node_2)
2. INSERT om_scada_graph (node_1, node_2) -> gw_trg_scada_graph_builder fills THIS row only

JSON export lives in gw_fct_scada_graph_check (commitChanges=true), not here.
*/

DECLARE
v_node_1 integer;
v_node_2 integer;
v_version text;
v_error_context text;
v_message text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_node_1 := COALESCE(
		(p_data -> 'data' -> 'parameters' ->> 'node_1')::integer,
		(p_data -> 'data' -> 'parameters' ->> 'object_1')::integer,
		(p_data -> 'data' ->> 'node_1')::integer,
		(p_data -> 'data' ->> 'object_1')::integer
	);
	v_node_2 := COALESCE(
		(p_data -> 'data' -> 'parameters' ->> 'node_2')::integer,
		(p_data -> 'data' -> 'parameters' ->> 'object_2')::integer,
		(p_data -> 'data' ->> 'node_2')::integer,
		(p_data -> 'data' ->> 'object_2')::integer
	);

	IF v_node_1 IS NULL OR v_node_2 IS NULL THEN
		SELECT COALESCE(
			(SELECT error_message FROM v_sys_message WHERE id = 4738 LIMIT 1),
			'node_1 and node_2 are required'
		)
		INTO v_message;
		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Failed',
			'message', json_build_object('level', 2, 'text', v_message),
			'version', v_version,
			'body', json_build_object('form', '{}'::json, 'data', '{}'::json)
		)::json, 3560, null, null, null);
	END IF;

	IF v_node_1 = v_node_2 THEN
		SELECT COALESCE(
			(SELECT error_message FROM v_sys_message WHERE id = 4740 LIMIT 1),
			'node_1 and node_2 must be different'
		)
		INTO v_message;
		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Failed',
			'message', json_build_object('level', 2, 'text', v_message),
			'version', v_version,
			'body', json_build_object('form', '{}'::json, 'data', '{}'::json)
		)::json, 3560, null, null, null);
	END IF;

	IF EXISTS (
		SELECT 1 FROM om_scada_graph
		WHERE node_1 = v_node_1 AND node_2 = v_node_2
	) THEN
		SELECT COALESCE(
			(SELECT error_message FROM v_sys_message WHERE id = 4742 LIMIT 1),
			'Scada graph edge already exists'
		)
		INTO v_message;
		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Failed',
			'message', json_build_object('level', 2, 'text', v_message),
			'version', v_version,
			'body', json_build_object('form', '{}'::json, 'data', '{}'::json)
		)::json, 3560, null, null, null);
	END IF;

	INSERT INTO om_scada_graph (node_1, node_2)
	VALUES (v_node_1, v_node_2);

	SELECT COALESCE(
		(SELECT error_message FROM v_sys_message WHERE id = 4744 LIMIT 1),
		'Scada graph edge created successfully'
	)
	INTO v_message;

	RETURN gw_fct_json_create_return(json_build_object(
		'status', 'Accepted',
		'message', json_build_object('level', 1, 'text', v_message),
		'version', v_version,
		'body', json_build_object(
			'form', '{}'::json,
			'data', json_build_object(
				'node_1', v_node_1,
				'node_2', v_node_2
			)
		)
	)::json, 3560, null, null, null);

EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;
$function$
;

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

Called from gw_fct_scada_graph_check on commitChanges=true (same session).
Reads temp_om_scada_graph with the line_valid query. Exploitation scoping is
already done in check; do not filter by explId here.

 */

DECLARE
v_schema_date date;
v_json_result_header json;
v_json_result_links json;
v_json_result_return json;
v_result JSON;
v_result_info JSON;
v_error_context text;
v_message text;
BEGIN

	SET search_path = "SCHEMA_NAME", public;

	IF to_regclass('pg_temp.temp_om_scada_graph') IS NULL THEN
		SELECT COALESCE(
			(SELECT error_message FROM v_sys_message WHERE id = 4732 LIMIT 1),
			'temp_om_scada_graph not found; call gw_fct_scada_graph_export from gw_fct_scada_graph_check'
		)
		INTO v_message;
		RETURN gw_fct_json_create_return(json_build_object(
			'status', 'Failed',
			'message', json_build_object('level', 2, 'text', v_message),
			'version', '',
			'body', json_build_object('form', '{}'::json, 'data', '{}'::json)
		)::json, 3546, null, null, null);
	END IF;

	SELECT "date" INTO v_schema_date FROM sys_version ORDER BY giswater DESC LIMIT 1;

	SELECT json_build_object(
		'name', concat('Network graph'),
		'entity', '',
		'generatedDate', now(),
		'schemaDate', v_schema_date
	) INTO v_json_result_header;

	SELECT json_agg(s.link ORDER BY s.group_id, s.order_id)
	INTO v_json_result_links
	FROM (
		SELECT
			g.group_id,
			g.order_id,
			json_build_object(
				'groupId', g.group_id,
				'orderId', g.order_id,
				'fromNode', g.node_1,
				'nodeType1', g.node_type_1,
				'nodeName1', n1.sys_code,
				'explId1', n1.expl_id,
				'dma_id_1', n1.dma_id,
				'dma_name_1', d1.name,
				'toNode', g.node_2,
				'nodeType2', g.node_type_2,
				'nodeName2', n2.sys_code,
				'explId2', n2.expl_id,
				'dma_id_2', n2.dma_id,
				'dma_name_2', d2.name,
				'attributes', CASE WHEN g.attrib IS JSON THEN g.attrib::json ELSE NULL END,
				'explId', g.expl_id
			) AS link
		FROM temp_om_scada_graph g
		LEFT JOIN node n1 ON n1.node_id = g.node_1
		LEFT JOIN dma d1 ON d1.dma_id = n1.dma_id
		LEFT JOIN node n2 ON n2.node_id = g.node_2
		LEFT JOIN dma d2 ON d2.dma_id = n2.dma_id
		WHERE g.the_geom IS NOT NULL
	) s;

	v_json_result_links := COALESCE(v_json_result_links, '[]'::json);

	v_json_result_return = json_build_object(
		'networkInfo', v_json_result_header,
		'links', v_json_result_links
	);

	INSERT INTO om_scada_graph_json (expl_id, om_scada_graph_json, insert_tstamp, update_tstamp)
	SELECT e.expl_id, v_json_result_return, now(), now()
	FROM (
		SELECT unnest(g.expl_id) AS expl_id
		FROM temp_om_scada_graph g
		WHERE g.the_geom IS NOT NULL
		UNION
		SELECT n1.expl_id
		FROM temp_om_scada_graph g
		LEFT JOIN node n1 ON n1.node_id = g.node_1
		WHERE g.the_geom IS NOT NULL
		UNION
		SELECT n2.expl_id
		FROM temp_om_scada_graph g
		LEFT JOIN node n2 ON n2.node_id = g.node_2
		WHERE g.the_geom IS NOT NULL
	) e
	WHERE e.expl_id IS NOT NULL
	ON CONFLICT (expl_id) DO UPDATE
	SET om_scada_graph_json = excluded.om_scada_graph_json,
		update_tstamp = now();

	SELECT COALESCE(
		(SELECT error_message FROM v_sys_message WHERE id = 4734 LIMIT 1),
		'Network Graph generated from scada graph check'
	)
	INTO v_message;

	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT 1, v_message as message) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"geometryType":"", "values":',v_result, '}');

	SELECT COALESCE(
		(SELECT error_message FROM v_sys_message WHERE id = 4736 LIMIT 1),
		'Network JSON graph successfully created'
	)
	INTO v_message;

	RETURN gw_fct_json_create_return(json_build_object(
		'status', 'Accepted',
		'message', json_build_object('level', 1, 'text', v_message),
		'version', '',
		'body', json_build_object(
			'form', '{}'::json,
			'data', json_build_object('info', v_result_info::json)
		)
	)::json, 3546, null, null, null);

EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;

$function$
;

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
One om_scada_graph_json row per distinct group_id (one synoptic).
Reads temp_om_scada_graph / temp_om_scada_vertice; exploitation scoping is
already done in check. Do not re-filter by explId here.
Does not delete JSON rows of groups that are still in om_scada_graph
(other exploitations). Drops only group_ids gone from om_scada_graph.

 */

DECLARE
v_schema_date date;
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

	CREATE TEMP TABLE IF NOT EXISTS temp_om_scada_vertice (
		node_id integer,
		group_id integer,
		row_id integer,
		column_id integer,
		column_aux integer
	);

	SELECT "date" INTO v_schema_date FROM sys_version ORDER BY giswater DESC LIMIT 1;

	WITH scada_groups AS (
		SELECT
			g.group_id,
			COALESCE((
				SELECT ARRAY(
					SELECT DISTINCT e
					FROM temp_om_scada_graph t
					CROSS JOIN LATERAL unnest(t.expl_id) AS e
					WHERE t.group_id = g.group_id
						AND t.the_geom IS NOT NULL
						AND e IS NOT NULL
					ORDER BY e
				)
			), '{}'::int4[]) AS expl_id
		FROM (
			SELECT DISTINCT group_id
			FROM temp_om_scada_graph
			WHERE group_id IS NOT NULL
				AND the_geom IS NOT NULL
		) g
	),
	links AS (
		SELECT s.group_id, json_agg(s.link ORDER BY s.order_id, s.node_1, s.node_2) AS links
		FROM (
			SELECT
				g.group_id,
				g.order_id,
				g.node_1,
				g.node_2,
				json_build_object(
					'groupId', g.group_id,
					'rowId', g.order_id,
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
				AND g.group_id IS NOT NULL
		) s
		GROUP BY s.group_id
	),
	vertices AS (
		SELECT s.group_id, json_agg(s.vertex ORDER BY s.row_id, s.column_id) AS vertices
		FROM (
			SELECT
				g.group_id,
				g.row_id,
				g.column_id,
				json_build_object(
					'groupId', g.group_id,
					'rowId', g.row_id,
					'columnId', g.column_id,
					'Node', g.node_id,
					'nodeType', cn.node_type,
					'nodeName', n.sys_code,
					'explId', n.expl_id,
					'dmaId', n.dma_id,
					'dmaName', d.name
				) AS vertex
			FROM temp_om_scada_vertice g
			LEFT JOIN node n ON n.node_id = g.node_id
			LEFT JOIN cat_node cn ON n.nodecat_id = cn.id
			LEFT JOIN dma d ON d.dma_id = n.dma_id
			WHERE g.group_id IS NOT NULL
		) s
		GROUP BY s.group_id
	)
	INSERT INTO om_scada_graph_json (group_id, expl_id, om_scada_graph_json, insert_tstamp, update_tstamp)
	SELECT
		g.group_id,
		g.expl_id,
		json_build_object(
			'networkInfo', json_build_object(
				'name', concat('Network graph'),
				'entity', '',
				'generatedDate', now(),
				'schemaDate', v_schema_date,
				'groupId', g.group_id
			),
			'vertices', COALESCE(v.vertices, '[]'::json),
			'links', COALESCE(l.links, '[]'::json)
		),
		now(),
		now()
	FROM scada_groups g
	JOIN links l ON l.group_id = g.group_id
	JOIN vertices v ON v.group_id = g.group_id
	ON CONFLICT (group_id) DO UPDATE
	SET expl_id = excluded.expl_id,
		om_scada_graph_json = excluded.om_scada_graph_json,
		update_tstamp = now();

	DELETE FROM om_scada_graph_json j
	WHERE NOT EXISTS (
		SELECT 1 FROM om_scada_graph g WHERE g.group_id = j.group_id
	);

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

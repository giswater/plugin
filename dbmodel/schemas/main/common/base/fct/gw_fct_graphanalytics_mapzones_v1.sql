/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
-- The code of this inundation function have been provided by Claudia Dragoste (Aigues de Manresa, S.A.)

--FUNCTION CODE: 3508

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_graphanalytics_mapzones_v1(json);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_graphanalytics_mapzones_v1(jsonb);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_graphanalytics_mapzones_v1(p_data jsonb)
RETURNS jsonb AS
$BODY$

/* Example usage:

- temp_pgr_node and pgr_temp_arc - temporary table
- v_temp_arc, v_temp_node, v_temp_connec, v_temp_gully, v_temp_link_connec, v_temp_link_gully
are temporary views for active explotation and for is_operatiu = TRUE, with psectors or not, depending of usePlanPsector
- Use the views for building temporary table;
- Use the tables node, arc, connec, gully or link to get the_geom, are faster then the views

-- QUERY SAMPLE
SELECT gw_fct_graphanalytics_mapzones('
	{
		"data":{
			"parameters":{
				"graphClass":"DWFZONE",
				"exploitation":"1,2,0",
				"updateMapZone":2,
				"geomParamUpdate":15,
				"commitChanges":true,
				"usePlanPsector":false,
				"forceOpen":"1,2,3",
				"forceClosed":"2,3,4"
			}
		}
	}
');
SELECT gw_fct_graphanalytics_mapzones('
	{
		"data":{
			"parameters":{
				"graphClass":"PRESSZONE",
				"exploitation":"1,2,0",
				"updateMapZone":2,
				"geomParamUpdate":15,
				"commitChanges":true,
				"usePlanPsector":false
			}
		}
	}
');
*/

DECLARE

	-- system variables
	v_version text;
	v_srid integer;
	v_project_type text;
	v_fid integer;
	v_checks_fid integer := 909;

	-- dialog variables
	v_class text;
	v_expl_id text;
	v_expl_id_array integer[];
	v_update_map_zone integer = 0;
	v_geom_param_update float;
	v_use_plan_psector boolean;
	v_commit_changes boolean;
	v_netscenario integer;
	v_recalculate_macromapzones boolean;
	v_reverse_cost INTEGER;
	v_reverse_cost_new_arcs INTEGER;

	-- geometry variables
	v_geom_param_update_divide float;
	v_concave_hull float = 0.9;

	v_from_zero boolean = FALSE;

    v_parameters json;
	--
	v_audit_result text;
	v_has_conflicts boolean = false;
	v_source text;
	v_target text;

	v_mapzone_count integer;
	v_arcs_count integer;
	v_nodes_count integer;
	v_connecs_count integer;
	v_gullies_count integer;
	v_mapzones_ids text;

	v_mapzone_table text;
	v_mapzone_graph_table text;
	v_mapzone_field text;
	v_visible_layer text;
	v_mapzone_id int4;
	v_pgr_distance integer;
	v_pgr_root_vids int[];
	v_count INTEGER;
	v_missing_to_arc INTEGER;

	-- query variables
	v_query_text text;
	v_query_text_aux text;
	v_data json;
	rec_man record;

	rec record;
	-- result variables
	v_result json;
	v_result_info json;
	v_result_point_valid json;
	v_result_point_invalid json;
	v_result_point json;
	v_result_line_valid json;
	v_result_line_invalid json;
	v_result_line json;
	v_result_graphconfig json;

	-- response variables
	v_level integer;
	v_status text;
	v_message text;
	v_response JSON;

	v_error_context text;

	-- check variables
	message text;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

    -- Select configuration values
	SELECT giswater, epsg, UPPER(project_type) INTO v_version, v_srid, v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Get variables from input JSON
	v_class := p_data->'data'->'parameters'->>'graphClass';
	v_expl_id := p_data->'data'->'parameters'->>'exploitation';
	v_update_map_zone := p_data->'data'->'parameters'->>'updateMapZone';
	v_geom_param_update := p_data->'data'->'parameters'->>'geomParamUpdate';
	v_use_plan_psector := p_data->'data'->'parameters'->>'usePlanPsector';
	v_commit_changes := p_data->'data'->'parameters'->>'commitChanges';
	v_netscenario := p_data->'data'->'parameters'->>'netscenario';
	v_recalculate_macromapzones := p_data->'data'->'parameters'->>'recalculateMacromapzones';

	-- fromZero: sent as text "true"/"false" by client; default FALSE when absent (keeps v1 behavior)
	v_from_zero := COALESCE(
		NULLIF(p_data->'data'->'parameters'->>'fromZero','')::boolean,
		false
	);

	-- extra parameters
	v_parameters := p_data->'data'->'parameters';

	-- it's not allowed to commit changes when psectors are used
 	IF v_use_plan_psector AND v_commit_changes THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4542", "function":"3508", "parameters":null}}$$);';
	END IF;

	IF v_class NOT IN ('PRESSZONE', 'DMA', 'DQA', 'SECTOR', 'DWFZONE', 'SUPPLYZONE') THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"3090", "function":"3508","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
	END IF;

	-- SECTION[epic=mapzones]: SET VARIABLES
	v_mapzone_table := LOWER(v_class);
	v_mapzone_graph_table := 'mapzone_graph';
	v_mapzone_field := v_mapzone_table || '_id';
	SELECT fid INTO v_fid FROM config_mapzones WHERE id = v_class;
	IF v_netscenario IS NOT NULL THEN
		v_mapzone_table := 'plan_netscenario_' || v_mapzone_table;
		v_mapzone_graph_table := 'plan_netscenario_' || v_mapzone_graph_table;
		v_from_zero := FALSE; -- from zero is not allowed for netscenario
	END IF;
	v_visible_layer := 've_' || v_mapzone_table;

    -- Get exploitation ID array
    v_expl_id_array := gw_fct_get_expl_id_array(v_expl_id);

    -- if v_expl_id_array is null, return error
    IF v_expl_id_array IS NULL THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"4478", "function":"2706","parameters":null}}$$);';
    END IF;

	-- Delete temporary tables
	-- =======================
	v_data :=
    jsonb_build_object(
        'data',
        jsonb_build_object(
            'action', 'DROP',
            'fct_name', v_class
        )
    );
	SELECT gw_fct_graphanalytics_manage_temporary(v_data) INTO v_response;

	IF v_response->>'status' <> 'Accepted' THEN
        RETURN v_response;
    END IF;

	-- Create temporary tables
	-- =======================
	v_data :=
		jsonb_build_object(
			'data',
			jsonb_build_object(
				'action', 'CREATE',
				'fct_name', v_class,
				'fct_type', 'MAPZONE',
				'use_psector', v_use_plan_psector
			)
		);

	SELECT gw_fct_graphanalytics_manage_temporary(v_data)
	INTO v_response;

    IF v_response->>'status' <> 'Accepted' THEN
        RETURN v_response;
    END IF;

	-- Create temp tables for log (needed by gw_fct_getmessage with tempTable='t_')
	-- ========================================================================
	v_data :=
	jsonb_build_object(
		'data',
		jsonb_build_object(
			'parameters',
			jsonb_build_object(
				'fid', v_fid,
				'project_type', v_project_type,
				'action', 'CREATE',
				'group', 'LOG'
			)
		)
	);

	SELECT gw_fct_manage_temp_tables(v_data) INTO v_response;

	IF v_response->>'status' <> 'Accepted' THEN
		RETURN v_response;
	END IF;

	-- Reset log tables content for this run
	DELETE FROM t_audit_check_data WHERE (fid = v_fid OR fid = v_checks_fid) AND cur_user = current_user;
	DELETE FROM t_audit_check_project WHERE fid = v_fid AND cur_user = current_user;
	DELETE FROM t_audit_log_data WHERE fid = v_fid AND cur_user = current_user;
	DELETE FROM temp_audit_check_data WHERE (fid = v_fid OR fid = v_checks_fid) AND cur_user = current_user;

	-- Start Building Log Message
	-- =======================
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":{"graphClass":"'
		|| upper(v_class) || '"}, "tempTable":"t_", "criticity":"4", "fid": '||v_fid||', "is_process":true, "is_header":true, "separator_id":"2049"}}$$);';

	-- Use psectors (already exists on sys_message id 4018)
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4018","function":"3508","parameters":{"v_usepsector":"'
		|| upper(v_use_plan_psector::text) || '"}, "tempTable":"t_", "criticity":"4", "fid": '||v_fid||'}}$$);';

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4592","function":"3508","parameters":{"updateMapZone":"'
		|| upper(v_update_map_zone::text) || '"}, "tempTable":"t_", "criticity":"4", "fid": '||v_fid||'}}$$);';

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4594","function":"3508","parameters":{"commitChanges":"'
		|| upper(v_commit_changes::text) || '"}, "tempTable":"t_", "criticity":"4", "fid": '||v_fid||'}}$$);';

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4596","function":"3508","parameters":{"fromZero":"'
		|| upper(v_from_zero::text) || '"}, "tempTable":"t_", "criticity":"4", "fid": '||v_fid||'}}$$);';

	-- spacer line from sys_label separator
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"4", "fid": '||v_fid||', "separator_id":"2000"}}$$);';

	-- section headers from sys_label
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"3", "fid": '||v_fid||', "separator_id":"2000"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"3", "fid": '||v_fid||', "is_process":true, "is_header":true, "label_id":"3003", "separator_id":"2011"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"2", "fid": '||v_fid||', "separator_id":"2000"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"2", "fid": '||v_fid||', "is_process":true, "is_header":true, "label_id":"3002", "separator_id":"2014"}}$$);';

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_fid||', "separator_id":"2000"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_fid||', "is_process":true, "is_header":true, "label_id":"3001", "separator_id":"2007"}}$$);';

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"0", "fid": '||v_fid||', "separator_id":"2000"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"t_", "criticity":"0", "fid": '||v_fid||', "is_process":true, "is_header":true, "label_id":"3012", "separator_id":"2010"}}$$);';

	-- Initialize process
	-- =======================
	v_query_text := $q$
        SELECT arc_id AS id, node_1 AS source, node_2 AS target, 1 AS cost
        FROM v_temp_arc
    $q$;

    -- INSERT
	EXECUTE format($sql$
        WITH connectedcomponents AS (
            SELECT *
            FROM pgr_connectedcomponents($q$%s$q$)
        ),
        components AS (
            SELECT c.component
            FROM connectedcomponents c
            WHERE cardinality($1) = 0
            OR EXISTS (
                SELECT 1
                FROM v_temp_arc v
                WHERE v.expl_visibility && $1
                AND v.node_1 = c.node
            )
            GROUP BY c.component
        )
        INSERT INTO temp_pgr_node (pgr_node_id)
        SELECT c.node
        FROM connectedcomponents c
        WHERE EXISTS (
            SELECT 1
            FROM components cc
            WHERE cc.component = c.component
        )
    $sql$, v_query_text)
    USING v_expl_id_array;

	INSERT INTO temp_pgr_arc (pgr_arc_id, pgr_node_1, pgr_node_2)
	SELECT a.arc_id, a.node_1, a.node_2
	FROM v_temp_arc a
	JOIN temp_pgr_node n1 ON n1.pgr_node_id = a.node_1
	JOIN temp_pgr_node n2 ON n2.pgr_node_id = a.node_2;

	INSERT INTO temp_pgr_connec (pgr_connec_id, pgr_arc_id)
	SELECT c.connec_id, c.arc_id
	FROM v_temp_connec c
	JOIN temp_pgr_arc a ON a.pgr_arc_id = c.arc_id;

	IF v_project_type = 'UD' THEN
		INSERT INTO temp_pgr_gully (pgr_gully_id, pgr_arc_id)
		SELECT g.gully_id, g.arc_id
		FROM v_temp_gully g
		JOIN temp_pgr_arc a ON a.pgr_arc_id = g.arc_id;
	END IF;

	IF v_class = 'SECTOR' THEN
		INSERT INTO temp_pgr_element (pgr_element_id)
		SELECT element_id
		FROM v_temp_element e
		WHERE EXISTS (
			SELECT 1
			FROM element_x_arc exa
			JOIN temp_pgr_arc a ON a.pgr_arc_id = exa.arc_id
			WHERE exa.element_id = e.element_id
		) ON CONFLICT DO NOTHING;

		INSERT INTO temp_pgr_element (pgr_element_id)
		SELECT element_id
		FROM v_temp_element e
		WHERE EXISTS (
			SELECT 1
			FROM element_x_node exn
			JOIN temp_pgr_node n ON n.pgr_node_id = exn.node_id
			WHERE exn.element_id = e.element_id
		) ON CONFLICT DO NOTHING;

		INSERT INTO temp_pgr_element (pgr_element_id)
		SELECT element_id
		FROM v_temp_element e
		WHERE EXISTS (
			SELECT 1
			FROM element_x_connec exc
			JOIN temp_pgr_connec c ON c.pgr_connec_id = exc.connec_id
			WHERE exc.element_id = e.element_id
		) ON CONFLICT DO NOTHING;

		INSERT INTO temp_pgr_element (pgr_element_id)
		SELECT element_id
		FROM v_temp_element e
		WHERE EXISTS (
			SELECT 1
			FROM element_x_link exl
			JOIN link l ON l.link_id = exl.link_id
			JOIN temp_pgr_connec c ON l.feature_id = c.pgr_connec_id
			WHERE l.feature_type = 'CONNEC'
			AND exl.element_id = e.element_id
		) ON CONFLICT DO NOTHING;

		IF v_project_type = 'UD' THEN
    		INSERT INTO temp_pgr_element (pgr_element_id)
    		SELECT element_id
    		FROM v_temp_element e
    		WHERE EXISTS (
    			SELECT 1
    			FROM element_x_gully exg
    			JOIN temp_pgr_gully g ON g.pgr_gully_id = exg.gully_id
    			WHERE exg.element_id = e.element_id
    		) ON CONFLICT DO NOTHING;

    		INSERT INTO temp_pgr_element (pgr_element_id)
    		SELECT element_id
    		FROM v_temp_element e
    		WHERE EXISTS (
    			SELECT 1
    			FROM element_x_link exl
    			JOIN link l ON l.link_id = exl.link_id
    			JOIN temp_pgr_gully g ON l.feature_id = g.pgr_gully_id
    			WHERE l.feature_type = 'GULLY'
                AND exl.element_id = e.element_id
    		) ON CONFLICT DO NOTHING;
		END IF;
	END IF;

	EXECUTE format(
		'INSERT INTO temp_pgr_old_mapzone (mapzone_id)
		SELECT DISTINCT a.%I
		FROM temp_pgr_arc t
		JOIN arc a ON t.pgr_arc_id = a.arc_id
		WHERE a.%I > 0',
		v_mapzone_field,
		v_mapzone_field
	);

	IF v_from_zero THEN
		EXECUTE format($sql$
		SELECT count(*)
		FROM %I t
		WHERE active
			AND %I NOT IN (0, -1) -- 0 and -1 are conflict and undefined
			AND EXISTS (
				SELECT 1
				FROM temp_pgr_old_mapzone t2
				WHERE t2.mapzone_id = t.%I
			)
		$sql$, v_mapzone_table, v_mapzone_field, v_mapzone_field)
		INTO v_mapzone_count;

		IF v_mapzone_count > 0 AND v_commit_changes = TRUE THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
	        "data":{"message":"4346", "function":"3508","parameters":{"mapzone_name":"'|| v_class ||'"}, "is_process":true}}$$)';
		END IF;
	END IF;

	-- CREATE MAPZONES
	-- =======================

	IF v_project_type = 'WS' THEN

		-- prepare graph_delimiters

		-- valves (minsector)
		UPDATE temp_pgr_node t
		SET graph_delimiter = 'MINSECTOR'
		FROM v_temp_node n
		JOIN man_valve m ON n.node_id = m.node_id
		WHERE 'MINSECTOR' = ANY (n.graph_delimiter)
		AND t.pgr_node_id = n.node_id;

		-- MAPZONES (graphconfig)
		IF v_from_zero THEN

			-- update graph_delimiter for nodeParent
			UPDATE temp_pgr_node t
			SET graph_delimiter = 'nodeParent'
			FROM v_temp_node n
			WHERE v_class = ANY(n.graph_delimiter)
			AND t.pgr_node_id = n.node_id;

			-- set node_parent for arcs connected to graph_delimiter METER, PUMP, VALVE (ex. PR_SUSTA_VALVE, PR_REDUC_VALVE)
			WITH meter_pump_valve AS (
			SELECT node_id, to_arc FROM man_meter
			UNION ALL SELECT node_id, to_arc FROM man_pump
			UNION ALL SELECT node_id, to_arc FROM man_valve
			)
			UPDATE temp_pgr_arc t
			SET node_parent = n.pgr_node_id
			FROM temp_pgr_node n
			JOIN meter_pump_valve m ON m.node_id = n.pgr_node_id
			WHERE n.graph_delimiter = 'nodeParent'
			AND t.pgr_arc_id = m.to_arc
			AND m.to_arc IS NOT NULL;

			-- set node_parent for arcs connected to graph_delimiter water_facility
			WITH water_facility AS (
				SELECT node_id, inlet_arc FROM man_tank
				UNION ALL SELECT node_id, inlet_arc FROM man_source
				UNION ALL SELECT node_id, inlet_arc FROM man_waterwell
				UNION ALL SELECT node_id, inlet_arc FROM man_wtp
				)
			UPDATE temp_pgr_arc t
			SET node_parent = n.pgr_node_id
			FROM temp_pgr_node n
			WHERE n.graph_delimiter = 'nodeParent'
			AND n.pgr_node_id IN (t.pgr_node_1, t.pgr_node_2)
			AND t.node_parent IS NULL
			AND EXISTS (
				SELECT 1
				FROM water_facility w
				WHERE w.node_id = n.pgr_node_id
				AND (
					w.inlet_arc IS NULL
					OR NOT (t.pgr_arc_id = ANY (w.inlet_arc))
				)
			);

			-- check if there are graph_delimiter nodes without at least one to_arc
			SELECT count(*)
			INTO v_missing_to_arc
			FROM temp_pgr_node n
			WHERE n.graph_delimiter = 'nodeParent'
			AND NOT EXISTS (
				SELECT 1 FROM temp_pgr_arc a
				WHERE a.node_parent = n.pgr_node_id
			);

		ELSE -- v_from_zero

			-- netscenario query
			IF v_netscenario IS NOT NULL THEN
				v_query_text_aux := ' AND netscenario_id = ' || v_netscenario;
			ELSE
				v_query_text_aux := '';
			END IF;

			-- prepare temp_pgr_graphconfig
			-- use
			EXECUTE format($sql$
				WITH graphconfig AS (
					SELECT
						t.%I AS mapzone_id,
						NULLIF(use_item->>'nodeParent','')::int AS node_parent,
						elem_to_arc.value::int AS to_arc
					FROM %I t
					JOIN LATERAL json_array_elements(t.graphconfig->'use') AS use_item ON TRUE
					LEFT JOIN LATERAL json_array_elements_text(use_item->'toArc') AS elem_to_arc(value) ON TRUE
					WHERE t.graphconfig IS NOT NULL
					AND t.active
					AND (cardinality($1) = 0 OR t.expl_id && $1)
					%s
				), graphconfig_filtered AS (
					SELECT g.* 
					FROM graphconfig g
					JOIN node n ON n.node_id = g.node_parent
					WHERE EXISTS (SELECT 1 FROM vf_exploitation vfe WHERE vfe.expl_id = ANY(array_append(n.expl_visibility, n.expl_id)))
				)
				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id, pgr_arc_id)
				SELECT
				mapzone_id,
				'use',
				node_parent,
				to_arc
				FROM graphconfig_filtered
				WHERE mapzone_id > 0
				AND (node_parent IS DISTINCT FROM 0 OR to_arc IS DISTINCT FROM 0);
			$sql$, v_mapzone_field, v_mapzone_table, v_query_text_aux) USING v_expl_id_array;

			-- forceClosed
			EXECUTE format($sql$
				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id)
				SELECT
					t.%I,
					'forceClosed',
					elem.value::int
				FROM %I t
				JOIN LATERAL json_array_elements_text(t.graphconfig->'forceClosed') AS elem(value) ON TRUE
				WHERE t.graphconfig IS NOT NULL
					AND t.active
					%s;
			$sql$, v_mapzone_field, v_mapzone_table, v_query_text_aux);

			-- forceOpen
			EXECUTE format($sql$
				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id)
				SELECT
					t.%I,
					'forceOpen',
					elem.value::int
				FROM %I t
				JOIN LATERAL json_array_elements_text(t.graphconfig->'ignore') AS elem(value) ON TRUE
				WHERE t.graphconfig IS NOT NULL
					AND t.active
					%s;
			$sql$, v_mapzone_field, v_mapzone_table, v_query_text_aux);

			-- update temp_pgr_node (nodeParent)
			UPDATE temp_pgr_node n
			SET graph_delimiter = 'nodeParent',
				mapzone_id = g.mapzone_id
			FROM temp_pgr_graphconfig g
			WHERE n.pgr_node_id = g.pgr_node_id
			AND g.graph_type = 'use';

			-- update temp_pgr_arc (toArc-nodeParent)
			UPDATE temp_pgr_arc a
			SET mapzone_id = g.mapzone_id,
				node_parent = g.pgr_node_id
			FROM temp_pgr_graphconfig g
			WHERE a.pgr_arc_id = g.pgr_arc_id
			AND g.graph_type = 'use';

			-- update temp_pgr_node (forceClosed, ignore)
			-- cannot be forceClosed/ignore a node that is already 'nodeParent'
			UPDATE temp_pgr_node n
			SET graph_delimiter = g.graph_type
			FROM temp_pgr_graphconfig g
			WHERE n.pgr_node_id = g.pgr_node_id
			AND g.graph_type IN  ('forceClosed', 'forceOpen');

		END IF; -- v_from_zero

		-- water facilities
		WITH water_facility AS (
			SELECT node_id FROM man_tank
			UNION ALL SELECT node_id FROM man_source
			UNION ALL SELECT node_id FROM man_waterwell
			UNION ALL SELECT node_id FROM man_wtp
		)
		UPDATE temp_pgr_node t
		SET graph_delimiter = 'SECTOR'
		FROM v_temp_node n
		JOIN water_facility w ON n.node_id = w.node_id
		WHERE 'SECTOR' = ANY (n.graph_delimiter)
		AND t.pgr_node_id = n.node_id
		AND t.graph_delimiter = 'NONE';

		-- init parameters
		-- forceClosed - cannot be forceClosed a node that is already 'nodeParent'
		UPDATE temp_pgr_node n SET graph_delimiter = 'forceClosed'
		WHERE n.pgr_node_id IN (SELECT (json_array_elements_text((v_parameters->>'forceClosed')::json))::int4)
		AND n.graph_delimiter <> 'nodeParent';

		-- ignore - cannot be ignore a node that is already 'nodeParent'
		UPDATE temp_pgr_node n SET graph_delimiter = 'forceOpen'
		WHERE n.pgr_node_id IN (SELECT (json_array_elements_text((v_parameters->>'forceOpen')::json))::int4)
		AND n.graph_delimiter <> 'nodeParent';

	ELSE -- v_project_type (UD)

		-- prepare graph_delimiters

		-- arcs 'initoverflowpath'
		UPDATE temp_pgr_arc t
        SET graph_delimiter = 'initoverflowpath'
        FROM arc v
        WHERE v.arc_id = t.pgr_arc_id
		AND v.initoverflowpath;

		-- MAPZONES (graphconfig)
		IF v_from_zero THEN
			-- nodeParent
			UPDATE temp_pgr_node t
			SET graph_delimiter = 'nodeParent'
			FROM v_temp_node n
			WHERE v_class = ANY(n.graph_delimiter)
			AND t.pgr_node_id = n.node_id;

			-- set node_parent only for arcs whose pgr_node_2 is a graph_delimiter node
			UPDATE temp_pgr_arc t
			SET node_parent = n.pgr_node_id
			FROM temp_pgr_node n
			WHERE t.pgr_node_2 = n.pgr_node_id
			AND n.graph_delimiter  = 'nodeParent';

		ELSE
			-- prepare temp_pgr_graphconfig
			-- use
			EXECUTE format($sql$
				WITH graphconfig AS (
					SELECT
					t.%I AS mapzone_id,
					NULLIF(use_item->>'nodeParent','')::int AS node_parent
					FROM %I t
					JOIN LATERAL json_array_elements(t.graphconfig->'use') AS use_item ON TRUE
					WHERE t.graphconfig IS NOT NULL
					AND t.active
					AND (cardinality($1) = 0 OR t.expl_id && $1)
				), graphconfig_filtered AS (
					SELECT g.* 
					FROM graphconfig g
					JOIN node n ON n.node_id = g.node_parent
					WHERE EXISTS (SELECT 1 FROM vf_exploitation vfe WHERE vfe.expl_id = ANY(array_append(n.expl_visibility, n.expl_id)))
				)
				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id, pgr_arc_id)
				SELECT
					g.mapzone_id,
					'use',
					g.node_parent,
					a.arc_id
				FROM graphconfig_filtered g
				LEFT JOIN v_temp_arc a ON a.node_2 = g.node_parent
				WHERE g.mapzone_id > 0
				AND g.node_parent IS DISTINCT FROM 0
			$sql$, v_mapzone_field, v_mapzone_table) USING v_expl_id_array;

			-- forceClosed
			EXECUTE format($sql$
				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_arc_id)
				SELECT
					t.%I,
					'forceClosed',
					elem.value::int
				FROM %I t
				JOIN LATERAL json_array_elements_text(t.graphconfig->'forceClosed') AS elem(value) ON TRUE
				WHERE t.graphconfig IS NOT NULL
					AND t.active
			$sql$, v_mapzone_field, v_mapzone_table);

			-- ignore
			EXECUTE format($sql$
				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_arc_id)
				SELECT
					t.%I,
					'forceOpen',
					elem.value::int
				FROM %I t
				JOIN LATERAL json_array_elements_text(t.graphconfig->'ignore') AS elem(value) ON TRUE
				WHERE t.graphconfig IS NOT NULL
					AND t.active
			$sql$, v_mapzone_field, v_mapzone_table);

			-- update temp_pgr_node (nodeParent)
			UPDATE temp_pgr_node n
			SET graph_delimiter = 'nodeParent',
				mapzone_id = g.mapzone_id
			FROM temp_pgr_graphconfig g
			WHERE n.pgr_node_id = g.pgr_node_id
			AND g.graph_type = 'use';

			-- update temp_pgr_arc (inletArc-nodeParent only for arcs whose pgr_node_2 is a graph_delimiter node)
			UPDATE temp_pgr_arc a
			SET mapzone_id = g.mapzone_id,
				node_parent = g.pgr_node_id
			FROM temp_pgr_graphconfig g
			WHERE a.pgr_arc_id= g.pgr_arc_id
			AND g.graph_type = 'use';

			-- update temp_pgr_arc (forceClosed)
			UPDATE temp_pgr_arc a
			SET graph_delimiter = 'forceClosed'
			FROM temp_pgr_graphconfig g
			WHERE a.pgr_arc_id = g.pgr_arc_id
			AND g.graph_type = 'forceClosed';

			-- update temp_pgr_arc (ignore)
			UPDATE temp_pgr_arc a
			SET graph_delimiter = 'forceOpen'
			FROM temp_pgr_graphconfig g
			WHERE a.pgr_arc_id = g.pgr_arc_id
			AND g.graph_type = 'forceOpen';

		END IF; -- v_from_zero

		-- init parameters
		-- forceClosed
		UPDATE temp_pgr_arc a SET graph_delimiter = 'forceClosed'
		WHERE a.pgr_arc_id IN (SELECT (json_array_elements_text((v_parameters->>'forceClosed')::json))::int4);

		-- ignore
		UPDATE temp_pgr_arc a SET graph_delimiter = 'forceOpen'
		WHERE a.pgr_arc_id IN (SELECT (json_array_elements_text((v_parameters->>'forceOpen')::json))::int4);

	END IF; -- v_project_type

	-- SECTION CHECK GRAPHCONFIG
	--==============================

	IF v_from_zero = FALSE THEN

		IF v_project_type = 'WS' THEN
			-- Check if there are any nodes in the graphconfig that are not in the operative network
			SELECT string_agg(concat('mapzone_id: ', sub.mapzone_id, ' - node_ids: ', mapzone_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.mapzone_id,
					string_agg(g.pgr_node_id::TEXT, ', ' ORDER BY g.pgr_node_id) AS mapzone_block
				FROM (SELECT DISTINCT pgr_node_id, mapzone_id FROM temp_pgr_graphconfig) g
				WHERE NOT EXISTS (
					SELECT 1
					FROM v_temp_node n
					WHERE n.node_id = g.pgr_node_id
				)
				GROUP BY g.mapzone_id
				ORDER BY g.mapzone_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4480", "function":"2706","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4482", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if there are any arcs in the graphconfig that are not in the operative network
			SELECT string_agg(concat('mapzone_id: ', sub.mapzone_id, ' - arc_ids: ', mapzone_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.mapzone_id,
					string_agg(g.pgr_arc_id::TEXT, ', ' ORDER BY g.pgr_arc_id) AS mapzone_block
				FROM (SELECT DISTINCT pgr_arc_id, mapzone_id FROM temp_pgr_graphconfig  WHERE pgr_arc_id IS NOT NULL) g
				WHERE NOT EXISTS (
					SELECT 1
					FROM v_temp_arc a
					WHERE a.arc_id = g.pgr_arc_id
				)
				GROUP BY g.mapzone_id
				ORDER BY g.mapzone_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4484", "function":"2706","parameters":{"arc_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4486", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if there are any nodes set in more than one mapzone (only for connected networks) - IN use, forceClosed or ignore
			SELECT string_agg(concat('node_id: ', sub.pgr_node_id, ' - mapzone_ids: ', mapzone_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.pgr_node_id,
					string_agg(g.mapzone_id::text, ', ' ORDER BY g.mapzone_id) AS mapzone_block
				FROM (SELECT DISTINCT pgr_node_id, mapzone_id FROM temp_pgr_graphconfig) g
				WHERE EXISTS (
					SELECT 1 
					FROM v_temp_node n 
					JOIN temp_pgr_node t ON n.node_id = t.pgr_node_id 
					WHERE g.pgr_node_id = n.node_id 
					AND t.mapzone_id <> 0
				)
				GROUP BY g.pgr_node_id
				HAVING  count(g.mapzone_id) > 1
				ORDER BY g.pgr_node_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4488", "function":"2706","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4490", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if there are any arcs set in more than one nodeParent (only for connected networks)
			SELECT string_agg(concat('arc_id: ', sub.arc_id, ' - ', sub.pair_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.pgr_arc_id AS arc_id,
					string_agg(concat('[mapzone_id: ', g.mapzone_id, ', node_id: ', g.pgr_node_id, ']'), ' ' ORDER BY g.mapzone_id) AS pair_block
				FROM temp_pgr_graphconfig g
				WHERE EXISTS (
					SELECT 1 
					FROM v_temp_arc a
					JOIN temp_pgr_arc t ON a.arc_id = t.pgr_arc_id
				 	WHERE g.pgr_arc_id = a.arc_id)
				GROUP BY g.pgr_arc_id
				HAVING COUNT(*) > 1
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4492", "function":"2706","parameters":{"arc_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4494", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if there are any to_arcs not connected to its nodeParent (only for connected networks)
			SELECT string_agg(sub.mapzone_arcs, '')
			INTO message
			FROM (
				SELECT concat('mapzone_id: ', g.mapzone_id, ': (node_id: ',g.pgr_node_id,', arc_id: ', g.pgr_arc_id, ')\n') AS mapzone_arcs
				FROM temp_pgr_graphconfig g
				JOIN v_temp_arc a ON g.pgr_arc_id = a.arc_id
				JOIN temp_pgr_arc t ON a.arc_id = t.pgr_arc_id
				WHERE g.graph_type = 'use'
				AND g.pgr_node_id NOT IN (a.node_1, a.node_2)
				ORDER BY g.mapzone_id,  g.pgr_node_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4496", "function":"2706","parameters":{"arc_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4498", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if nodeParent or toArc is null
			SELECT string_agg(sub.mapzone_arcs, '')
			INTO message
			FROM (
				SELECT concat('mapzone_id: ', g.mapzone_id, ': (node_id: ', g.pgr_node_id, ', arc_id: ', g.pgr_arc_id, ')\n') AS mapzone_arcs
				FROM temp_pgr_graphconfig g
				WHERE g.graph_type = 'use'
				AND (g.pgr_node_id IS NULL OR g.pgr_arc_id IS NULL)
				ORDER BY g.mapzone_id,  g.pgr_node_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4508", "function":"2706","parameters":{"feature_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4510", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			IF v_use_plan_psector = FALSE THEN
				-- Check if there are pump/meter/valve nodeParent where its to_arc is not the same as in its man_table
				SELECT string_agg(sub.mapzone_arcs, '')
				INTO message
				FROM (
					WITH
					meter_pump_valve AS (
						SELECT node_id, to_arc FROM man_meter
						UNION ALL
						SELECT node_id, to_arc FROM man_pump
						UNION ALL
						SELECT node_id, to_arc FROM man_valve
					)
					SELECT concat('mapzone_id: ', g.mapzone_id, ': (node_id: ', g.pgr_node_id, ', arc_id: ', g.pgr_arc_id, ')\n') AS mapzone_arcs
					FROM temp_pgr_graphconfig g
					WHERE g.graph_type = 'use'
					AND EXISTS (
						SELECT 1 FROM meter_pump_valve m
						WHERE m.node_id = g.pgr_node_id
						AND m.to_arc <> g.pgr_arc_id
					)
					ORDER BY g.mapzone_id,  g.pgr_node_id
				) sub;

				IF message IS NOT NULL THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4500", "function":"2706","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
				ELSE
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4502", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
				END IF;

				-- Check if there are tank/source/waterwell/wtp nodeParent where its to_arc is inlet in its man_table
				SELECT string_agg(sub.mapzone_arcs, '')
				INTO message
				FROM (
					WITH
					inlet AS (
						SELECT node_id, unnest(inlet_arc) AS arc_id FROM man_tank
						UNION ALL SELECT node_id, unnest(inlet_arc) AS arc_id FROM man_source
						UNION ALL SELECT node_id, unnest(inlet_arc) AS arc_id FROM man_waterwell
						UNION ALL SELECT node_id, unnest(inlet_arc) AS arc_id FROM man_wtp
					)
					SELECT concat('mapzone_id: ', g.mapzone_id, ': (node_id: ', g.pgr_node_id, ', arc_id: ', g.pgr_arc_id, ')\n') AS mapzone_arcs
					FROM temp_pgr_graphconfig g
					WHERE g.graph_type = 'use'
					AND EXISTS (
						SELECT 1 FROM inlet i
						WHERE i.node_id = g.pgr_node_id
						AND i.arc_id = g.pgr_arc_id
					)
					ORDER BY g.mapzone_id,  g.pgr_node_id
				) sub;

				IF message IS NOT NULL THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4504", "function":"2706","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
				ELSE
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4506", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
				END IF;

				-- check if there are arcs for nodeParents that are not toArc, neither inlet_arc
				SELECT string_agg(sub.mapzone_arcs, '')
				INTO message
				FROM (
					WITH inlet AS (
						SELECT node_id, inlet_arc FROM man_tank
						UNION ALL SELECT node_id, inlet_arc FROM man_source
						UNION ALL SELECT node_id, inlet_arc FROM man_waterwell
						UNION ALL SELECT node_id, inlet_arc FROM man_wtp
						)
					SELECT
						concat('mapzone_id: ', g.mapzone_id, ': (node_id: ', g.pgr_node_id, ', arc_id: ', a.arc_id, ')\n') AS mapzone_arcs
					FROM v_temp_node n
					JOIN temp_pgr_graphconfig g ON g.pgr_node_id = n.node_id
					JOIN v_temp_arc a ON n.node_id IN (a.node_1, a.node_2)
					WHERE g.graph_type = 'use' -- nodeParent
					AND EXISTS (
						SELECT 1
						FROM inlet i
						WHERE i.node_id = n.node_id
					)
					AND NOT EXISTS (
						SELECT 1
						FROM inlet i
						WHERE i.node_id = n.node_id
							AND a.arc_id = ANY (i.inlet_arc)
					)
					AND NOT EXISTS (
						SELECT 1
						FROM temp_pgr_graphconfig ga
						WHERE ga.graph_type = 'use'
							AND ga.pgr_node_id IN (a.node_1, a.node_2)
							AND ga.pgr_arc_id  = a.arc_id
					)
					ORDER BY g.mapzone_id,  g.pgr_node_id
				) sub;

				IF message IS NOT NULL THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4532", "function":"2706","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"2", "fid": '||v_checks_fid||'}}$$);';
				ELSE
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4534", "function":"2706","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
				END IF;

			END IF;

		ELSIF v_project_type = 'UD' THEN

			-- Check if there are any nodeParents in the graphconfig that are not in the operative network
			SELECT string_agg(concat('mapzone_id: ', sub.mapzone_id, ' - node_ids: ', sub.mapzone_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.mapzone_id,
					string_agg(g.pgr_node_id::TEXT, ', ' ORDER BY g.pgr_node_id)
					AS mapzone_block
				FROM (SELECT DISTINCT pgr_node_id, mapzone_id FROM temp_pgr_graphconfig WHERE graph_type = 'use') g
				WHERE NOT EXISTS (
					SELECT 1 FROM v_temp_node n 
					WHERE g.pgr_node_id = n.node_id
				)
				GROUP BY g.mapzone_id
				ORDER BY g.mapzone_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4512", "function":"3508","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4514", "function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if there are any forceClose/forceOpen in the graphconfig that are not in the operative network
			SELECT string_agg(concat('mapzone_id: ', sub.mapzone_id, ' - arc_ids: ', sub.mapzone_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.mapzone_id,
					string_agg(g.pgr_arc_id::TEXT, ', ' ORDER BY g.pgr_arc_id) AS mapzone_block
				FROM temp_pgr_graphconfig g
				WHERE g.graph_type IN ('forceClosed', 'forceOpen')
				AND NOT EXISTS (
					SELECT 1 
					FROM v_temp_arc a
					WHERE g.pgr_arc_id = a.arc_id
				)
				GROUP BY g.mapzone_id
				ORDER BY g.mapzone_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4516", "function":"3508","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4518", "function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if there are any nodeParents set in more than one mapzone (only for connected networks)
			SELECT string_agg(concat('node_id: ', sub.pgr_node_id, ' - mapzone_ids: ', sub.mapzone_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.pgr_node_id,
					string_agg(g.mapzone_id::text, ', ' ORDER BY g.mapzone_id) AS mapzone_block
				FROM (SELECT DISTINCT pgr_node_id, mapzone_id FROM temp_pgr_graphconfig WHERE graph_type = 'use') g
				WHERE EXISTS (
					SELECT 1 
					FROM v_temp_node n
					JOIN temp_pgr_node t ON n.node_id = t.pgr_node_id
					WHERE g.pgr_node_id = n.node_id
				)
				GROUP BY g.pgr_node_id
				HAVING  count(*) > 1
				ORDER BY g.pgr_node_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4520", "function":"3508","parameters":{"node_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4522", "function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if there are any forceClosed/forceOpen set in more than one mapzone (only for connected networks)
			SELECT string_agg(concat('arc_id: ', sub.pgr_arc_id, ' - mapzone_ids: ', sub.mapzone_block, '\n'), '')
			INTO message
			FROM (
				SELECT
					g.pgr_arc_id,
					string_agg(g.mapzone_id::text, ', ' ORDER BY g.mapzone_id) AS mapzone_block
				FROM temp_pgr_graphconfig g
				WHERE g.graph_type IN ('forceClosed', 'forceOpen')
				AND EXISTS (
					SELECT 1 
					FROM v_temp_arc a
					JOIN temp_pgr_arc t ON a.arc_id = t.pgr_arc_id
					WHERE g.pgr_arc_id = a.arc_id
				)
				GROUP BY g.pgr_arc_id
				HAVING  count(*) > 1
				ORDER BY g.pgr_arc_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4524", "function":"3508","parameters":{"arc_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4526", "function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check if nodeParent or toArc is null
			SELECT string_agg(sub.mapzone_arcs, '')
			INTO message
			FROM (
				SELECT concat('mapzone_id: ', g.mapzone_id, ': (node_id: ', g.pgr_node_id, ', arc_id: ', g.pgr_arc_id, ')\n') AS mapzone_arcs
				FROM temp_pgr_graphconfig g
				WHERE g.graph_type = 'use'
				AND (g.pgr_node_id IS NULL OR g.pgr_arc_id IS NULL)
				ORDER BY g.mapzone_id,  g.pgr_node_id
			) sub;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4634", "function":"3508","parameters":{"feature_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4636", "function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;

			-- Check when 2 arcs make a circle
			SELECT string_agg(concat('arc_1: ', lg.source, ' - arc_2: ', lg.target, '\n'), '') AS message
			INTO message
			FROM pgr_linegraph(
				'SELECT pgr_arc_id AS id, pgr_node_1 AS source, pgr_node_2 AS target, 1::float8 AS cost, -1::float8 AS reverse_cost
				FROM temp_pgr_arc',
				directed := TRUE
			) AS lg
			WHERE reverse_cost =  1;

			IF message IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4536", "function":"3508","parameters":{"arc_list":"\n' || message || '"}, "tempTable":"t_", "criticity":"3", "fid": '||v_checks_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4538", "function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_checks_fid||'}}$$);';
			END IF;
		END IF;
	END IF; --v_from_zero

	-- check if there are any errors in graphconfig, when v_from_zero FALSE
	-- Detect real errors in graphconfig, ignoring UI scaffolding rows
	-- (we insert section headers/spacers into t_audit_check_data as well).
	IF NOT EXISTS (SELECT 1 FROM t_audit_check_data WHERE fid = v_checks_fid AND criticity = 3) THEN
		-- GENERATE LINEGRAPH
		-- ===================

		IF v_project_type = 'WS' THEN
			v_reverse_cost := 1;
		ELSE
			v_reverse_cost := -1;
		END IF;

		v_query_text := format(
			'SELECT pgr_arc_id AS id, pgr_node_1 AS source, pgr_node_2 AS target, 1::float8 AS cost, %s::float8 AS reverse_cost
			FROM temp_pgr_arc',
			v_reverse_cost
		);

		INSERT INTO temp_pgr_arc_linegraph (pgr_arc_id, pgr_node_1, pgr_node_2, cost, reverse_cost)
		SELECT lg.seq, lg.source, lg.target, lg.cost, lg.reverse_cost
		FROM pgr_linegraph(
			v_query_text,
			directed := TRUE
		) AS lg
		WHERE lg.source <> lg.target;

		-- PREPARE temp_pgr_arc_linegraph
		-- ==============================

		IF v_project_type = 'WS' THEN

			-- UPDATE pgr_node_id for nodes with graph_delimiter (MINSECTOR, SECTOR, 'nodeParent', forceClosed, ignore)
			--checking node_1 for arc_1
			UPDATE temp_pgr_arc_linegraph t
			SET pgr_node_id = n.pgr_node_id,
				graph_delimiter = n.graph_delimiter
			FROM temp_pgr_arc_linegraph ta
			JOIN temp_pgr_arc a1 ON ta.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON ta.pgr_node_2 = a2.pgr_arc_id
			JOIN temp_pgr_node n ON a1.pgr_node_1 = n.pgr_node_id
			WHERE n.graph_delimiter <> 'NONE'
			AND a1.pgr_node_1 IN (a2.pgr_node_1, a2.pgr_node_2)
			AND ta.pgr_arc_id = t.pgr_arc_id;

			--checking node_2 for arc_1
			UPDATE temp_pgr_arc_linegraph t
			SET pgr_node_id = n.pgr_node_id,
				graph_delimiter = n.graph_delimiter
			FROM temp_pgr_arc_linegraph ta
			JOIN temp_pgr_arc a1 ON ta.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON ta.pgr_node_2 = a2.pgr_arc_id
			JOIN temp_pgr_node n ON a1.pgr_node_2 = n.pgr_node_id
			WHERE n.graph_delimiter <> 'NONE'
			AND a1.pgr_node_2 IN (a2.pgr_node_1, a2.pgr_node_2)
			AND ta.pgr_arc_id = t.pgr_arc_id;

			-- update aditional fields for valves (MINSECTOR)
			-- valves from the network
			UPDATE temp_pgr_arc_linegraph t
			SET
				closed = m.closed,
				broken = m.broken,
				to_arc = m.to_arc
			FROM man_valve m
			WHERE t.graph_delimiter = 'MINSECTOR'
			AND t.pgr_node_id = m.node_id;

			-- closed valves
			UPDATE temp_pgr_arc_linegraph t
			SET graph_delimiter = 'closedValve'
			WHERE t.closed = TRUE;

			-- check valves
			UPDATE temp_pgr_arc_linegraph t
			SET graph_delimiter = 'checkValve'
			WHERE t.closed = FALSE
			AND t.broken = FALSE
			AND t.to_arc IS NOT NULL;

			-- open valves
			UPDATE temp_pgr_arc_linegraph t
			SET graph_delimiter = 'openValve'
			WHERE t.graph_delimiter = 'MINSECTOR';

			-- valves from NETSCENARIO
			-- ======================================
			IF v_netscenario IS NOT NULL THEN
				-- closed valves
				UPDATE temp_pgr_arc_linegraph t
				SET graph_delimiter = 'netscenClosedValve',
					closed = TRUE,
					broken = FALSE
				FROM plan_netscenario_valve v
				WHERE v.netscenario_id = v_netscenario
				AND v.closed IS TRUE
				AND t.pgr_node_id = v.node_id;

				-- open valves
				UPDATE temp_pgr_arc_linegraph t
				SET graph_delimiter = 'netscenOpenedValve',
					closed = FALSE,
					broken = FALSE,
					to_arc = NULL
				FROM plan_netscenario_valve v
				WHERE v.netscenario_id = v_netscenario
				AND v.closed IS FALSE
				AND t.pgr_node_id = v.node_id;
			END IF;

			UPDATE temp_pgr_node n
			SET graph_delimiter = a.graph_delimiter
			FROM temp_pgr_arc_linegraph a
			WHERE n.graph_delimiter = 'MINSECTOR'
			AND n.pgr_node_id = a.pgr_node_id;

			-- COST/REVERSE_COST

			-- closed valves
			UPDATE temp_pgr_arc_linegraph t
			SET cost = -1, reverse_cost = -1
			WHERE graph_delimiter IN ('closedValve', 'netscenClosedValve');

			-- checkvalves
			UPDATE temp_pgr_arc_linegraph t
			SET
				cost = CASE WHEN t.to_arc = t.pgr_node_2 THEN 1 ELSE -1 END,
				reverse_cost = CASE WHEN t.to_arc = t.pgr_node_2 THEN -1 ELSE 1 END
			WHERE t.graph_delimiter = 'checkValve';

			-- inlet arcs of water utilities behave as checkvalves
			WITH
				water_facility AS (
					SELECT node_id, inlet_arc FROM man_tank
					UNION ALL SELECT node_id, inlet_arc FROM man_source
					UNION ALL SELECT node_id, inlet_arc FROM man_waterwell
					UNION ALL SELECT node_id, inlet_arc FROM man_wtp
				)
			UPDATE temp_pgr_arc_linegraph t
			SET
				cost = CASE WHEN t.pgr_node_2 = ANY (w.inlet_arc) THEN -1 ELSE 1 END,
				reverse_cost = CASE WHEN t.pgr_node_1 = ANY (w.inlet_arc) THEN -1 ELSE 1 END
			FROM water_facility w
			WHERE t.graph_delimiter IN ('SECTOR', 'nodeParent')
			AND t.pgr_node_id = w.node_id;

			-- forceClosed
			UPDATE temp_pgr_arc_linegraph t
			SET cost = -1, reverse_cost = -1
			WHERE graph_delimiter = 'forceClosed';

			-- ignore
			UPDATE temp_pgr_arc_linegraph t
			SET cost = 1, reverse_cost = 1
			WHERE graph_delimiter = 'forceOpen';

		ELSE -- v_project_type (UD)

			-- UPDATE pgr_node_id for nodes head of mapzones ('nodeParent')
			--checking node_1 for arc_1
			UPDATE temp_pgr_arc_linegraph t
			SET pgr_node_id = n.pgr_node_id
			FROM temp_pgr_arc_linegraph ta
			JOIN temp_pgr_arc a1 ON ta.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON ta.pgr_node_2 = a2.pgr_arc_id
			JOIN temp_pgr_node n ON a1.pgr_node_1 = n.pgr_node_id
			WHERE n.graph_delimiter = 'nodeParent'
			AND a1.pgr_node_1 IN (a2.pgr_node_1, a2.pgr_node_2)
			AND ta.pgr_arc_id = t.pgr_arc_id;

			--checking node_2 for arc_1
			UPDATE temp_pgr_arc_linegraph t
			SET pgr_node_id = n.pgr_node_id
			FROM temp_pgr_arc_linegraph ta
			JOIN temp_pgr_arc a1 ON ta.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON ta.pgr_node_2 = a2.pgr_arc_id
			JOIN temp_pgr_node n ON a1.pgr_node_2 = n.pgr_node_id
			WHERE n.graph_delimiter = 'nodeParent'
			AND a1.pgr_node_2 IN (a2.pgr_node_1, a2.pgr_node_2)
			AND ta.pgr_arc_id = t.pgr_arc_id;

			-- UPDATE pgr_node_id, graph_delimiter for arcs (initoverflowpath, forceClosed, ignore)
			UPDATE temp_pgr_arc_linegraph t
			SET graph_delimiter = a.graph_delimiter,
				pgr_node_id = a.pgr_node_1
			FROM temp_pgr_arc a
			WHERE a.graph_delimiter IN ('initoverflowpath', 'forceClosed', 'forceOpen')
			AND a.pgr_arc_id = t.pgr_node_2;

			-- COST/REVERSE_COST

			-- initoverflowpath
			IF v_class = 'DWFZONE' THEN
				UPDATE temp_pgr_arc_linegraph t
				SET cost = -1, reverse_cost = -1
				WHERE graph_delimiter = 'initoverflowpath';
			END IF;

			-- forceClosed
			UPDATE temp_pgr_arc_linegraph t
			SET cost = -1, reverse_cost = -1
			WHERE graph_delimiter = 'forceClosed';

			-- forceOpen
			UPDATE temp_pgr_arc_linegraph t
			SET cost = 1, reverse_cost = 1
			WHERE graph_delimiter = 'forceOpen';


		END IF; -- v_project_type

		v_pgr_distance := (SELECT count(*)::int FROM temp_pgr_arc_linegraph);

		-- Compute to_arc and assign arc node_parent (v_missing_to_arc > 0)
		-- =================================================================

		IF v_project_type = 'WS' AND v_from_zero AND v_missing_to_arc > 0 THEN

			-- root_vids = toArcs of the water facilities
			WITH
				water_facility AS (
					SELECT node_id, inlet_arc FROM man_tank
					UNION ALL SELECT node_id, inlet_arc FROM man_source
					UNION ALL SELECT node_id, inlet_arc FROM man_waterwell
					UNION ALL SELECT node_id, inlet_arc FROM man_wtp
				)
			SELECT array_agg(DISTINCT a.pgr_arc_id)::int[]
			INTO v_pgr_root_vids
			FROM temp_pgr_arc a
			JOIN temp_pgr_node n ON n.pgr_node_id IN  (a.pgr_node_1, a.pgr_node_2)
			WHERE n.graph_delimiter IN ('SECTOR', 'nodeParent')
			AND EXISTS (
				SELECT 1
				FROM water_facility w
				WHERE w.node_id = n.pgr_node_id
			);

			v_query_text := format($sql$
				WITH
				water_facility AS (
					SELECT node_id FROM man_tank
					UNION ALL SELECT node_id FROM man_source
					UNION ALL SELECT node_id FROM man_waterwell
					UNION ALL SELECT node_id FROM man_wtp
				)
				SELECT
					a.pgr_arc_id AS id,
					a.pgr_node_1 AS source,
					a.pgr_node_2 AS target,
					a.cost,
					a.reverse_cost
				FROM temp_pgr_arc_linegraph a
				WHERE a.pgr_node_id IS NULL
				OR NOT EXISTS (
					SELECT 1 FROM water_facility w
					WHERE a.graph_delimiter IN ('SECTOR', 'nodeParent')
					AND w.node_id = a.pgr_node_id
				)
			$sql$);

			TRUNCATE temp_pgr_drivingdistance;
			INSERT INTO temp_pgr_drivingdistance(seq, "depth", start_vid, pred, node, edge, "cost", agg_cost)
			(
				SELECT seq, "depth", start_vid, pred, node, edge, "cost", agg_cost
				FROM pgr_drivingdistance(v_query_text, v_pgr_root_vids, v_pgr_distance)
			);

			-- set arc - node_parent for arcs without node_parent that exists in pgr_drivingdistance
			WITH
				best_dd AS (
					SELECT DISTINCT ON (edge) edge, node
					FROM temp_pgr_drivingdistance
					WHERE cost > 0
					ORDER BY edge, cost, node
				)
			UPDATE temp_pgr_arc t
			SET node_parent = lg.pgr_node_id
			FROM temp_pgr_arc_linegraph lg
			JOIN best_dd d ON d.edge = lg.pgr_arc_id
			WHERE lg.graph_delimiter = 'nodeParent'
			AND t.node_parent IS NULL
			AND t.pgr_arc_id = d.node
			AND NOT EXISTS (
				SELECT 1 FROM temp_pgr_arc a
				WHERE a.node_parent = lg.pgr_node_id
			);

		END IF; -- v_missing_to_arc

		-- FLOOD THE LINEGRAPH
		-- ====================

		-- for WS - from source to target for UD - INVERTED FLOOD, from target to source

		IF v_project_type = 'WS' THEN
			v_source := 'pgr_node_1';
			v_target := 'pgr_node_2';
		ELSE
			v_source := 'pgr_node_2';
			v_target := 'pgr_node_1';
		END IF;

		-- root_vids = arcs with nodeParent
		SELECT array_agg(pgr_arc_id)::int[]
			INTO v_pgr_root_vids
			FROM temp_pgr_arc
			WHERE node_parent IS NOT NULL;

		-- Remove from temp_pgr_arc_linegraph any connections that cross the nodeParents of the mapzones as the graph is broken at those nodes
		v_query_text := format($sql$
			SELECT
				a.pgr_arc_id AS id,
				a.%I AS source,
				a.%I AS target,
				a.cost,
				a.reverse_cost
			FROM temp_pgr_arc_linegraph a
			WHERE a.pgr_node_id IS NULL
			OR NOT EXISTS (
				SELECT 1
				FROM temp_pgr_arc np
				WHERE np.node_parent IS NOT NULL
				AND np.node_parent = a.pgr_node_id
			)
			$sql$
		, v_source, v_target);

		TRUNCATE temp_pgr_drivingdistance;
		INSERT INTO temp_pgr_drivingdistance(seq, "depth", start_vid, pred, node, edge, "cost", agg_cost)
		(
			SELECT seq, "depth", start_vid, pred, node, edge, "cost", agg_cost
			FROM pgr_drivingdistance(v_query_text, v_pgr_root_vids, v_pgr_distance)
		);

		-- extra flood for DWFZONE for calculating later the drainzone_outfall
		-- put again cost/reverse_cost 1 from initoverflowpath
		IF v_class = 'DWFZONE' THEN
			UPDATE temp_pgr_arc_linegraph t
			SET cost = 1, reverse_cost = -1
			WHERE graph_delimiter = 'initoverflowpath';

			INSERT INTO temp_pgr_drivingdistance_initoverflowpath (seq, "depth", start_vid, pred, node, edge, "cost", agg_cost)
			(
				SELECT seq, "depth", start_vid, pred, node, edge, "cost", agg_cost
				FROM pgr_drivingdistance(v_query_text, v_pgr_root_vids, v_pgr_distance)
			);
		END IF;

		-- group the mapzones; add connections between toArc(WS)/inletArc(UD) for pgr_root_vids
		v_query_text := '
			WITH edges AS (
				SELECT
					start_vid AS source,
					node AS target
				FROM temp_pgr_drivingdistance
				UNION ALL
				SELECT
					a1.pgr_arc_id AS source,
					a2.pgr_arc_id AS target
				FROM temp_pgr_arc a1 
				JOIN temp_pgr_arc a2 ON a1.node_parent = a2.node_parent
				WHERE a2.pgr_arc_id > a1.pgr_arc_id
			)
			SELECT
				row_number() OVER () AS id,
				source,
				target,
				1 AS cost
			FROM edges
		';

		-- GENERATE MAPZONES
		-- ====================

		-- component = MIN(arc_id) of the connected arc group
		INSERT INTO temp_pgr_connectedcomponents (seq, component, node)
		SELECT seq, component, node
		FROM pgr_connectedComponents(v_query_text);

		INSERT INTO temp_pgr_mapzone (component, mapzone_id, mapzone_ids, name)
		VALUES (0,0, array[0]::int[], 'Disconnected');

		INSERT INTO temp_pgr_mapzone (component, name)
		SELECT DISTINCT c.component, ''::text
		FROM temp_pgr_connectedcomponents c;

		-- UPDATE MAPZONES
		-- ====================

		-- update component for arc
		UPDATE temp_pgr_arc t
		SET component = c.component
		FROM temp_pgr_connectedcomponents c
		WHERE c.node = t.pgr_arc_id;

		-- update mapzone_ids, mapzone_id, name for temp_pgr_mapzone
		IF v_from_zero = TRUE THEN

			IF v_commit_changes THEN
				v_query_text_aux := 'nextval(''urn_id_seq'')';
			ELSE
				v_query_text_aux := 'row_number() OVER ()';
			END IF;

			EXECUTE format($sql$
				WITH idx AS (
					SELECT
						t.component,
						%s AS new_id
					FROM temp_pgr_mapzone t
					WHERE t.component > 0
				)
				UPDATE temp_pgr_mapzone m
				SET mapzone_ids = ARRAY[i.new_id],
					mapzone_id = i.new_id,
					name = concat(%L, i.new_id)
				FROM idx i
				WHERE m.component = i.component
			$sql$, v_query_text_aux, v_mapzone_table);

			-- update mapzone_id for nodeParents
			UPDATE temp_pgr_node t
			SET mapzone_id = tn.mapzone_id
			FROM (
				SELECT
					a.node_parent,
					MIN(a.mapzone_id) AS mapzone_id
				FROM temp_pgr_arc a
				WHERE a.node_parent IS NOT NULL
				GROUP BY a.node_parent
			) tn
			WHERE t.pgr_node_id = tn.node_parent
			AND t.graph_delimiter = 'nodeParent';

		ELSE -- v_from_zero
			-- mapzone_id
			UPDATE temp_pgr_mapzone m
			SET mapzone_ids = c.mapzone_ids,
				mapzone_id  =
				CASE
					WHEN cardinality(c.mapzone_ids) = 1 THEN c.mapzone_ids[1]
					ELSE -1
				END
			FROM (
			SELECT a.component,
					array_agg(DISTINCT a.mapzone_id ORDER BY a.mapzone_id) AS mapzone_ids
			FROM temp_pgr_arc a
			WHERE a.node_parent IS NOT NULL
			GROUP BY a.component
			) c
			WHERE m.component = c.component;

			-- mapzone_pattern
			IF v_netscenario IS NOT NULL AND v_class = 'DMA' THEN
				EXECUTE format($sql$
					UPDATE temp_pgr_mapzone t
					SET pattern_id = m.pattern_id
					FROM %I m
					WHERE t.mapzone_id = m.%I
					AND t.mapzone_id > 0
					$sql$,
					v_mapzone_table,
					v_mapzone_field
				);
			END IF;

			EXECUTE format($sql$
				UPDATE temp_pgr_mapzone t
				SET name = COALESCE(m.name, ''),
				graphconfig = m.graphconfig
				FROM %I m
				WHERE t.mapzone_id = m.%I
				AND t.mapzone_id > 0
				$sql$,
				v_mapzone_table,
				v_mapzone_field
			);

			UPDATE temp_pgr_mapzone t
			SET name = 'Conflict'
			WHERE t.mapzone_id = -1;

		END IF; -- v_from_zero

		-- for DWFZONE generate id for drainzone (will be the minimum value of arc id)
		IF v_class = 'DWFZONE' THEN

			TRUNCATE temp_pgr_connectedcomponents;
			v_query_text := $sql$
				WITH components AS (
					SELECT n1.component AS source, n2.component AS target
					FROM temp_pgr_arc_linegraph a
					JOIN temp_pgr_arc n1 ON a.pgr_node_1 = n1.pgr_arc_id
					JOIN temp_pgr_arc n2 ON a.pgr_node_2 = n2.pgr_arc_id
					WHERE a.graph_delimiter = 'initoverflowpath'
				)
				SELECT row_number() OVER () AS id,
						source,
						target,
						1 AS cost
				FROM components
				$sql$
			;

			INSERT INTO temp_pgr_connectedcomponents (seq,component, node)
			SELECT seq,component, node
			FROM pgr_connectedComponents(v_query_text);

			UPDATE temp_pgr_mapzone m
			SET drainzone_id = c.component
			FROM temp_pgr_connectedcomponents c
			WHERE m.component = c.node;

			UPDATE temp_pgr_mapzone m
			SET drainzone_id = m.component
			WHERE COALESCE(m.drainzone_id, 0) = 0;
		END IF;

		-- end update temp_pgr_mapzone

		-- update mapzone_id for arcs
		UPDATE temp_pgr_arc t
		SET mapzone_id = m.mapzone_id
		FROM temp_pgr_mapzone m
		WHERE m.component = t.component;

		-- update mapzone_id for nodeParents if fromZero
		IF v_from_zero THEN
			UPDATE temp_pgr_node t
			SET mapzone_id = tn.mapzone_id
			FROM (
				SELECT
					a.node_parent,
					MIN(a.mapzone_id) AS mapzone_id
				FROM temp_pgr_arc a
				WHERE a.node_parent IS NOT NULL
				GROUP BY a.node_parent
			) tn
			WHERE t.pgr_node_id = tn.node_parent
			AND t.graph_delimiter = 'nodeParent';
		END IF;

		-- EXCEPTION
		-- NodeParent self-conflict: the arcs toArc and the ones that are not have the same mapzone_id
		-- set mapzone_id = -1

		WITH
			selfconflict AS (
			SELECT DISTINCT l.pgr_node_id, n.mapzone_id
			FROM temp_pgr_arc a
			JOIN temp_pgr_arc_linegraph l ON a.pgr_arc_id IN (l.pgr_node_1, l.pgr_node_2)
			JOIN temp_pgr_node n ON l.pgr_node_id = n.pgr_node_id
			WHERE n.graph_delimiter = 'nodeParent'
			AND a.mapzone_id > 0
			AND a.mapzone_id = n.mapzone_id
			AND a.node_parent IS DISTINCT FROM l.pgr_node_id
		)
		UPDATE temp_pgr_mapzone m
		SET mapzone_id = -1, name = 'SelfConflict'
		WHERE EXISTS (
			SELECT 1
			FROM selfconflict s
			WHERE s.mapzone_id = m.mapzone_id
		);

		UPDATE temp_pgr_arc a
		SET mapzone_id = -1
		WHERE EXISTS (
			SELECT 1
			FROM temp_pgr_mapzone m
			WHERE m.component = a.component
			AND m.mapzone_id = -1
		)
		AND a.mapzone_id <> -1;

		-- END EXCEPTION

		-- update component/mapzone_id for nodes
		-- Nodes are updated only if all connected arcs belong to the same component (component ≠ 0).
		-- If multiple components are detected, nodes stay at 0
		UPDATE temp_pgr_node t
		SET component = tn.component,
			mapzone_id = tn.mapzone_id
		FROM (
			SELECT
				n.pgr_node_id,
				MIN (a.component) AS component,
				MIN(a.mapzone_id) AS mapzone_id
			FROM temp_pgr_node n
			JOIN temp_pgr_arc a
			ON n.pgr_node_id = a.pgr_node_1 OR n.pgr_node_id = a.pgr_node_2
			WHERE a.component <> 0
			GROUP BY n.pgr_node_id
			HAVING count(DISTINCT a.component) = 1
		) tn
		WHERE t.pgr_node_id = tn.pgr_node_id
		AND t.graph_delimiter IS DISTINCT FROM 'nodeParent';

		-- update mapzone_id for nodeParents (always) and component only if it's unique
		UPDATE temp_pgr_node t
		SET mapzone_id = tn.mapzone_id,
			component  = CASE
							WHEN tn.comp_cnt = 1 THEN tn.component
							ELSE t.component      -- keep existing (typically 0)
						END
		FROM (
			SELECT
				a.node_parent,
				MIN (a.component) AS component,
				MIN(a.mapzone_id) AS mapzone_id,
        		COUNT(DISTINCT a.component) AS comp_cnt
			FROM temp_pgr_arc a
			WHERE a.node_parent IS NOT NULL
			GROUP BY a.node_parent
		) tn
		WHERE t.pgr_node_id = tn.node_parent
		AND t.graph_delimiter = 'nodeParent';

		-- update connec
		UPDATE temp_pgr_connec t
		SET component = a.component,
			mapzone_id = a.mapzone_id
		FROM temp_pgr_arc a
		WHERE t.pgr_arc_id = a.pgr_arc_id;

		IF v_project_type = 'UD' THEN
			-- update gully
			UPDATE temp_pgr_gully t
			SET component = a.component,
				mapzone_id = a.mapzone_id
			FROM temp_pgr_arc a
			WHERE t.pgr_arc_id = a.pgr_arc_id;
		END IF;

		-- update elements
		IF v_class = 'SECTOR' THEN
			UPDATE temp_pgr_element t
			SET mapzone_id = a.mapzone_id
			FROM element_x_arc exa
			JOIN temp_pgr_arc a ON a.pgr_arc_id = exa.arc_id
			WHERE t.pgr_element_id = exa.element_id;

			UPDATE temp_pgr_element t
			SET mapzone_id = n.mapzone_id
			FROM element_x_node exn
			JOIN temp_pgr_node n ON n.pgr_node_id = exn.node_id
			WHERE t.pgr_element_id = exn.element_id;

			UPDATE temp_pgr_element t
			SET mapzone_id = c.mapzone_id
			FROM element_x_connec exc
			JOIN temp_pgr_connec c ON c.pgr_connec_id = exc.connec_id
			WHERE t.pgr_element_id = exc.element_id;

			UPDATE temp_pgr_element t
			SET mapzone_id = c.mapzone_id
			FROM element_x_link exl
			JOIN link l ON l.link_id = exl.link_id
			JOIN temp_pgr_connec c ON l.feature_id = c.pgr_connec_id
			WHERE t.pgr_element_id = exl.element_id;

			IF v_project_type = 'UD' THEN
				UPDATE temp_pgr_element t
				SET mapzone_id = g.mapzone_id
				FROM element_x_gully exg
				JOIN temp_pgr_gully g ON g.pgr_gully_id = exg.gully_id
				WHERE t.pgr_element_id = exg.element_id;

				UPDATE temp_pgr_element t
				SET mapzone_id = g.mapzone_id
				FROM element_x_link exl
				JOIN link l ON l.link_id = exl.link_id
				JOIN temp_pgr_gully g ON l.feature_id = g.pgr_gully_id
				WHERE t.pgr_element_id = exl.element_id;
			END IF;
		END IF;

		-- CONFLICT COUNTS
		SELECT count(*)
		INTO v_arcs_count
		FROM temp_pgr_arc t
		WHERE t.mapzone_id = -1;

		SELECT count(*)
		INTO v_connecs_count
		FROM temp_pgr_connec t
		WHERE t.mapzone_id = -1;

		SELECT string_agg(unnest_id::text, ',') INTO v_mapzones_ids
		FROM (
			SELECT UNNEST(m.mapzone_ids) AS unnest_id
			FROM temp_pgr_mapzone m
			WHERE CARDINALITY(m.mapzone_ids) > 1
			ORDER BY unnest_id
		) sub;

		IF v_arcs_count > 0 OR v_connecs_count > 0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4598","function":"3508","parameters":{"graphClass":"'
				|| upper(v_class) || '","mapzones_ids":"' || COALESCE(v_mapzones_ids, '') || '","arcs_count":"'
				|| COALESCE(v_arcs_count::text, '0') || '","connecs_count":"' || COALESCE(v_connecs_count::text, '0')
				|| '"}, "tempTable":"t_", "criticity":"2", "fid": '||v_fid||'}}$$);';
		END IF;

		IF v_project_type = 'WS' THEN
			EXECUTE format($sql$
				INSERT INTO temp_audit_check_data (fid, criticity, error_message)
				SELECT %L, 0, concat(m.name,' with ', a.arcs,' Arcs, ', n.nodes,' Nodes and ', c.connecs,' Connecs')
				FROM temp_pgr_mapzone m
				LEFT JOIN LATERAL (
					SELECT COUNT(*) AS arcs
					FROM temp_pgr_arc ta
					WHERE ta.component = m.component
				) a ON TRUE
				LEFT JOIN LATERAL (
					SELECT COUNT(*) AS nodes
					FROM temp_pgr_node tn
					WHERE tn.component = m.component
				) n ON TRUE
				LEFT JOIN LATERAL (
					SELECT COUNT(*) AS connecs
					FROM temp_pgr_connec tc
					WHERE tc.component = m.component
				) c ON TRUE
				WHERE CARDINALITY(m.mapzone_ids) = 1
			$sql$, v_fid);
		ELSE
			EXECUTE format($sql$
				INSERT INTO temp_audit_check_data (fid, criticity, error_message)
				SELECT %L, 0, concat(m.name,' with ',a.arcs,' Arcs, ',n.nodes,' Nodes, ',c.connecs,' Connecs and ',g.gully,' Gully')
				FROM temp_pgr_mapzone m
				LEFT JOIN LATERAL (
					SELECT COUNT(*) AS arcs
					FROM temp_pgr_arc ta
					WHERE ta.component = m.component
				) a ON TRUE
				LEFT JOIN LATERAL (
					SELECT COUNT(*) AS nodes
					FROM temp_pgr_node tn
					WHERE tn.component = m.component
				) n ON TRUE
				LEFT JOIN LATERAL (
					SELECT COUNT(*) AS connecs
					FROM temp_pgr_connec tc
					WHERE tc.component = m.component
				) c ON TRUE
				LEFT JOIN LATERAL (
					SELECT COUNT(*) AS gully
					FROM temp_pgr_gully tg
					WHERE tg.component = m.component
				) g ON TRUE
				WHERE CARDINALITY(m.mapzone_ids) = 1
			$sql$, v_fid);
		END IF;

		-- DISCONECTED COUNTS
		RAISE NOTICE 'Disconnected arcs';
		SELECT COUNT(t.*) INTO v_arcs_count
		FROM temp_pgr_arc t
		WHERE t.mapzone_id = 0;

		IF v_arcs_count > 0 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4600","function":"3508","parameters":{"arcs_count":"'
			|| COALESCE(v_arcs_count::text, '0')
			|| '"}, "tempTable":"t_", "criticity":"2", "fid": '||v_fid||'}}$$);';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4602","function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_fid||'}}$$);';
		END IF;

		RAISE NOTICE 'Disconnected connecs';
		IF v_arcs_count > 0 THEN
			SELECT COUNT(*) INTO v_connecs_count
			FROM temp_pgr_connec t
			WHERE t.mapzone_id = 0;

			IF v_connecs_count > 0 THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4604","function":"3508","parameters":{"connecs_count":"'
					|| COALESCE(v_connecs_count::text, '0')
					|| '"}, "tempTable":"t_", "criticity":"2", "fid": '||v_fid||'}}$$);';
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4606","function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_fid||'}}$$);';
			END IF;
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4606","function":"3508","parameters":null, "tempTable":"t_", "criticity":"1", "fid": '||v_fid||'}}$$);';
		END IF;

		IF v_audit_result is null THEN
			v_status := 'Accepted';
			v_level := 3;
			v_message := 'Mapzones dynamic analysis done succesfull';
		ELSE
			SELECT (v_audit_result::json -> 'body' -> 'data' -> 'info' ->> 'status') INTO v_status;
			SELECT (v_audit_result::json -> 'body' -> 'data' -> 'info' ->> 'level')::integer INTO v_level;
			SELECT (v_audit_result::json -> 'body' -> 'data' -> 'info' ->> 'message') INTO v_message;
		END IF;

		-- fill table temp_pgr_graphconfig when from_zero and graphconfig for temp_pgr_mapzone
		-- it can be possible that there are new mapzones with selfConflict that have to be saved also
		-- use mapzpne_ids[1] instead of mapzone_id because mapzone_id = -1 for selfConflict mapzones
		IF v_from_zero = TRUE THEN

			IF v_project_type = 'WS' THEN

				-- insert into temp_pgr_graphconfig
				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id, pgr_arc_id)
				SELECT
					m.mapzone_ids[1] as mapzone_id,
					'use' AS graph_type,
					a.node_parent AS pgr_node_id,
					a.pgr_arc_id AS pgr_arc_id
				FROM temp_pgr_arc a
				JOIN temp_pgr_mapzone m ON a.component = m.component
				WHERE a.node_parent IS NOT NULL
				AND m.mapzone_id <> 0;

				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id)
				SELECT DISTINCT ON (n.pgr_node_id)
					m.mapzone_ids[1] AS mapzone_id,
					'forceClosed' AS graph_type,
					n.pgr_node_id
				FROM temp_pgr_node n
				JOIN temp_pgr_arc a ON n.pgr_node_id IN (a.pgr_node_1, a.pgr_node_2)
				JOIN temp_pgr_mapzone m ON a.component = m.component
				WHERE n.graph_delimiter = 'forceClosed'
				AND m.mapzone_id <> 0
				ORDER BY n.pgr_node_id, m.mapzone_id DESC;

				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id)
				SELECT
					m.mapzone_ids[1] AS mapzone_id,
					'forceOpen' AS graph_type,
					n.pgr_node_id
				FROM temp_pgr_node n
				JOIN temp_pgr_mapzone m ON n.component = m.component
				WHERE n.graph_delimiter = 'forceOpen'
				AND m.mapzone_id <> 0;

				-- update graphconfig 'use'
				UPDATE temp_pgr_mapzone mz
				SET graphconfig = json_build_object(
				'use',         s.use_json,
				'ignore',      json_build_array(),
				'forceClosed', json_build_array()
				)
				FROM (
					SELECT
						mapzone_id,
						json_agg(
						json_build_object(
							'nodeParent', node_parent,
							'toArc',      to_arc
						)
						ORDER BY node_parent
						) AS use_json
					FROM (
						SELECT
						g.mapzone_id,
						g.pgr_node_id::text AS node_parent,
						json_agg(g.pgr_arc_id ORDER BY g.pgr_arc_id) AS to_arc
						FROM temp_pgr_graphconfig g
						WHERE g.graph_type = 'use'
						GROUP BY g.mapzone_id, g.pgr_node_id
					) x
					GROUP BY mapzone_id
				) s
				WHERE mz.mapzone_ids[1] = s.mapzone_id;

				-- forceClosed (nodes)
				UPDATE temp_pgr_mapzone mz
				SET graphconfig = json_build_object(
				'use',         mz.graphconfig->'use',
				'ignore',      mz.graphconfig->'ignore',
				'forceClosed', t.forceclosed_json
				)
				FROM (
					SELECT
						g.mapzone_id,
						json_agg(g.pgr_node_id ORDER BY g.pgr_node_id) AS forceclosed_json
					FROM temp_pgr_graphconfig g
					WHERE g.graph_type = 'forceClosed'
					GROUP BY g.mapzone_id
				) t
				WHERE mz.mapzone_ids[1] = t.mapzone_id;

				-- ignore (nodes)
				UPDATE temp_pgr_mapzone mz
				SET graphconfig = json_build_object(
				'use',         mz.graphconfig->'use',
				'ignore',      t.ignore_json,
				'forceClosed', mz.graphconfig->'forceClosed'
				)
				FROM (
					SELECT
						g.mapzone_id,
						json_agg(g.pgr_node_id ORDER BY g.pgr_node_id) AS ignore_json
					FROM temp_pgr_graphconfig g
					WHERE g.graph_type = 'forceOpen'
					GROUP BY g.mapzone_id
				) t
				WHERE mz.mapzone_ids[1] = t.mapzone_id;

			ELSE -- v_project_type

				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_node_id, pgr_arc_id)
				SELECT
					m.mapzone_ids[1] as mapzone_id,
					'use' AS graph_type,
					a.node_parent AS pgr_node_id,
					a.pgr_arc_id AS pgr_arc_id
				FROM temp_pgr_arc a
				JOIN temp_pgr_mapzone m ON a.component = m.component
				WHERE a.node_parent IS NOT NULL
				AND m.mapzone_id <> 0;

				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_arc_id)
				SELECT
					m.mapzone_ids[1] AS mapzone_id,
					'forceClosed' AS graph_type,
					a.pgr_arc_id AS pgr_arc_id
				FROM temp_pgr_arc a
				JOIN temp_pgr_mapzone m ON a.component = m.component
				WHERE a.graph_delimiter = 'forceClosed'
				AND a.mapzone_id <> 0;

				INSERT INTO temp_pgr_graphconfig (mapzone_id, graph_type, pgr_arc_id)
				SELECT
					m.mapzone_ids[1] AS mapzone_id,
					'forceOpen' AS graph_type,
					a.pgr_arc_id AS pgr_arc_id
				FROM temp_pgr_arc a
				JOIN temp_pgr_mapzone m ON a.component = m.component
				WHERE a.graph_delimiter = 'forceOpen'
				AND a.mapzone_id <> 0;

				-- update graphconfig for temp_pgr_mapzone
				UPDATE temp_pgr_mapzone mz
				SET graphconfig = json_build_object(
					'use',         s.use_json,
					'ignore',      json_build_array(),
					'forceClosed', json_build_array()
				)
				FROM (
					SELECT
						g.mapzone_id,
						json_agg(
							json_build_object('nodeParent', g.pgr_node_id::text)
							ORDER BY g.pgr_node_id
						) AS use_json
					FROM (
						SELECT DISTINCT
							mapzone_id,
							pgr_node_id
						FROM temp_pgr_graphconfig
						WHERE graph_type = 'use'
					) g
					GROUP BY g.mapzone_id
				) s
				WHERE mz.mapzone_ids[1] = s.mapzone_id;

				-- forceClosed (arcs)
				UPDATE temp_pgr_mapzone mz
				SET graphconfig = json_build_object(
				'use',         mz.graphconfig->'use',
				'ignore',      mz.graphconfig->'ignore',
				'forceClosed', t.forceclosed_json
				)
				FROM (
				SELECT
					mapzone_id,
					json_agg(pgr_arc_id ORDER BY pgr_arc_id) AS forceclosed_json
				FROM temp_pgr_graphconfig
				WHERE graph_type = 'forceClosed'
				GROUP BY mapzone_id
				) t
				WHERE mz.mapzone_ids[1] = t.mapzone_id;

				--  ignore (arcs)
				UPDATE temp_pgr_mapzone mz
				SET graphconfig = json_build_object(
				'use',         mz.graphconfig->'use',
				'ignore',      t.ignore_json,
				'forceClosed', mz.graphconfig->'forceClosed'
				)
				FROM (
				SELECT
					mapzone_id,
					json_agg(pgr_arc_id ORDER BY pgr_arc_id) AS ignore_json
				FROM temp_pgr_graphconfig
				WHERE graph_type = 'forceOpen'
				GROUP BY mapzone_id
				) t
				WHERE mz.mapzone_ids[1] = t.mapzone_id;

			END IF; -- v_project_type

		END IF; -- v_from_zero

		IF v_commit_changes IS TRUE THEN

			-- UPDATE TEMP_PGR_MAPZONE
			-- =======================

			RAISE NOTICE 'Creating geometry of mapzones';
			-- SECTION: Creating geometry of mapzones

			IF v_update_map_zone > 0 THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4608","function":"3508","parameters":{"graphClass":"'
					|| upper(v_class) || '"}, "tempTable":"t_", "criticity":"1", "fid": '||v_fid||'}}$$);';
			END IF;

			IF v_update_map_zone = 0 THEN
				-- do nothing

			ELSIF  v_update_map_zone = 1 THEN

				-- concave polygon
				v_query_text := '
					UPDATE temp_pgr_mapzone m SET the_geom = ST_Multi(a.the_geom)
					FROM (
						WITH polygon AS (
						SELECT
							t.mapzone_id,
							ST_Collect(ar.the_geom) AS g
						FROM temp_pgr_arc t
						JOIN arc ar ON ar.arc_id = t.pgr_arc_id
						WHERE t.mapzone_id > 0
						GROUP BY t.mapzone_id
						)
						SELECT
						mapzone_id,
						CASE
							WHEN ST_GeometryType(ST_ConcaveHull(g, '||v_concave_hull||')) = ''ST_Polygon'' THEN
							ST_Buffer(ST_ConcaveHull(g, '||v_concave_hull||'), 2)::geometry(Polygon,'||v_srid||')
							ELSE
							ST_Expand(ST_Buffer(g, 3::double precision), 1::double precision)::geometry(Polygon,'||v_srid||')
						END AS the_geom
						FROM polygon
					) a
					WHERE a.mapzone_id = m.mapzone_id
				';
				EXECUTE v_query_text;

			ELSIF  v_update_map_zone = 2 THEN

				-- pipe buffer
				v_query_text := '
					UPDATE temp_pgr_mapzone m SET the_geom = a.geom
					FROM (
						SELECT
						t.mapzone_id,
						ST_Multi(ST_Buffer(ST_Collect(ar.the_geom), '||v_geom_param_update||')) AS geom
						FROM temp_pgr_arc t
						JOIN arc ar ON ar.arc_id = t.pgr_arc_id
						WHERE t.mapzone_id > 0
						GROUP BY t.mapzone_id
					) a
					WHERE a.mapzone_id = m.mapzone_id
				';
				EXECUTE v_query_text;

			ELSIF  v_update_map_zone = 3 THEN

				-- use plot and pipe buffer
				v_query_text := '
					UPDATE temp_pgr_mapzone m SET the_geom = b.geom
					FROM (
						SELECT
						mapzone_id,
						ST_Multi(ST_Buffer(ST_Collect(geom), 0.01)) AS geom
						FROM (
							SELECT
								t.mapzone_id,
								ST_Buffer(ar.the_geom, '||v_geom_param_update||') AS geom
							FROM temp_pgr_arc t
							JOIN arc ar ON ar.arc_id = t.pgr_arc_id
							WHERE t.mapzone_id > 0
							UNION ALL
							SELECT
								t.mapzone_id,
								vp.the_geom AS geom
							FROM temp_pgr_connec t
							JOIN connec vc ON t.pgr_connected_id = vc.connec_id
							LEFT JOIN v_plot vp
								ON vc.plot_id = vp.id
							AND ST_DWithin(vc.the_geom, vp.the_geom, 0.001)
							WHERE t.mapzone_id > 0
							AND vp.the_geom IS NOT NULL
						) a
						GROUP BY mapzone_id
					) b
					WHERE b.mapzone_id = m.mapzone_id
				';
				EXECUTE v_query_text;

			ELSIF  v_update_map_zone = 4 THEN

				v_geom_param_update_divide := v_geom_param_update / 2;

				IF v_project_type = 'UD' THEN
				v_query_text_aux := '
					UNION ALL
					SELECT
					g.mapzone_id,
					ST_Buffer(ST_Collect(l.the_geom), '||v_geom_param_update_divide||', ''endcap=flat join=round'') AS geom
					FROM temp_pgr_gully g
					JOIN link l ON l.feature_id = g.pgr_gully_id
					WHERE g.mapzone_id > 0
					GROUP BY g.mapzone_id
				';
				ELSE
					v_query_text_aux := '';
				END IF;

				-- use link and pipe buffer
				v_query_text := '
					UPDATE temp_pgr_mapzone m SET the_geom = b.geom
					FROM (
					SELECT
						mapzone_id,
						ST_Multi(ST_Buffer(ST_Collect(geom), 0.01)) AS geom
					FROM (
						SELECT
						a.mapzone_id,
						ST_Buffer(ST_Collect(ar.the_geom), '||v_geom_param_update||') AS geom
						FROM temp_pgr_arc a
						JOIN arc ar ON ar.arc_id = a.pgr_arc_id
						WHERE a.mapzone_id > 0
						GROUP BY a.mapzone_id
						UNION ALL
						SELECT
						c.mapzone_id,
						ST_Buffer(ST_Collect(l.the_geom), '||v_geom_param_update_divide||', ''endcap=flat join=round'') AS geom
						FROM temp_pgr_connec c
						JOIN link l ON l.feature_id = c.pgr_connec_id
						WHERE c.mapzone_id > 0
						GROUP BY c.mapzone_id
						'||v_query_text_aux||'
					) u
					GROUP BY mapzone_id
					) b
					WHERE b.mapzone_id = m.mapzone_id
				';
				EXECUTE v_query_text;
			END IF;

			-- update expl_id
			UPDATE temp_pgr_mapzone m
			SET expl_id = s.expl_ids
			FROM (
			SELECT
				ta.mapzone_id,
				array_agg(DISTINCT e.expl_id ORDER BY e.expl_id) AS expl_ids
			FROM temp_pgr_arc ta
			JOIN arc a ON a.arc_id = ta.pgr_arc_id
			CROSS JOIN LATERAL unnest(array_append(a.expl_visibility, a.expl_id)) AS e(expl_id)
			WHERE ta.mapzone_id > 0
			AND EXISTS (SELECT 1 FROM vf_exploitation vfe WHERE vfe.expl_id = e.expl_id)
			GROUP BY ta.mapzone_id
			) s
			WHERE m.mapzone_id = s.mapzone_id;

			-- update muni_id
			UPDATE temp_pgr_mapzone m
			SET muni_id = s.muni_ids
			FROM (
			SELECT
				ta.mapzone_id,
				array_agg(DISTINCT a.muni_id ORDER BY a.muni_id) AS muni_ids
			FROM temp_pgr_arc ta
			JOIN arc a ON a.arc_id = ta.pgr_arc_id
			WHERE ta.mapzone_id > 0
			GROUP BY ta.mapzone_id
			) s
			WHERE m.mapzone_id = s.mapzone_id;

			-- update sector_id
			IF v_class <> 'SECTOR' THEN
				UPDATE temp_pgr_mapzone m
				SET sector_id = s.sector_ids
				FROM (
				SELECT
					ta.mapzone_id,
					array_agg(DISTINCT a.sector_id ORDER BY a.sector_id) AS sector_ids
				FROM temp_pgr_arc ta
				JOIN arc a ON a.arc_id = ta.pgr_arc_id
				WHERE ta.mapzone_id > 0
				AND a.sector_id > 0
				GROUP BY ta.mapzone_id
				) s
				WHERE m.mapzone_id = s.mapzone_id;
			END IF;

			-- addparam (km of red)
			UPDATE temp_pgr_mapzone m
			SET addparam = json_build_object(
			'kmLength', COALESCE(s.km, 0)
			)
			FROM (
			SELECT
				ta.mapzone_id,
				sum(st_length(a.the_geom) / 1000)::numeric(12,3) AS km
			FROM temp_pgr_arc ta
			JOIN arc a ON a.arc_id = ta.pgr_arc_id
			WHERE ta.mapzone_id > 0
			GROUP BY ta.mapzone_id
			) s
			WHERE s.mapzone_id = m.mapzone_id;

			-- UPDATE TABLES
			-- ======================

			-- mapzone
			IF v_from_zero = TRUE THEN
				-- insert the new mapzones
				EXECUTE format($sql$
				INSERT INTO %I (%I, code, name, expl_id, muni_id, the_geom, addparam, graphconfig, created_at , created_by)
				SELECT t.mapzone_ids[1],
					COALESCE(gw_fct_generate_code('mapzone', %L, json_strip_nulls(json_build_object(%I, t.mapzone_ids[1], 'the_geom', ST_AsGeoJSON(t.the_geom)::json))), t.mapzone_ids[1]::text),
					t.name, t.expl_id, t.muni_id, t.the_geom, t.addparam, t.graphconfig, t.created_at , t.created_by
				FROM temp_pgr_mapzone t
				WHERE t.mapzone_id <> 0
				$sql$, v_mapzone_table, v_mapzone_field, v_class, v_mapzone_field);

			ELSE
				EXECUTE format($sql$
					UPDATE %I m
					SET
						expl_id = t.expl_id,
						muni_id = t.muni_id,
						the_geom = t.the_geom,
						addparam = t.addparam,
						graphconfig = t.graphconfig,
						updated_at = t.created_at,
						updated_by = t.created_by
					FROM temp_pgr_mapzone t
					WHERE m.%I = t.mapzone_id
						AND t.mapzone_id > 0
					$sql$
				, v_mapzone_table, v_mapzone_field);
			END IF;


			IF v_class = 'DWFZONE' THEN
				INSERT INTO drainzone (drainzone_id, code, name, created_at, created_by)
				SELECT m.drainzone_id, m.drainzone_id, concat('drainzone',m.drainzone_id), now(), current_user
				FROM temp_pgr_mapzone m
				GROUP BY m.drainzone_id
				HAVING max(CARDINALITY(m.mapzone_ids)) = 1
				AND NOT EXISTS (SELECT 1 FROM drainzone d WHERE d.drainzone_id = m.drainzone_id);

				-- clear geometries of drainzones that are not assigned before updating dwfzone.drainzone_id
				UPDATE drainzone d SET the_geom = NULL,
				updated_at = now(),
				updated_by = current_user
				WHERE EXISTS (
					SELECT 1
					FROM temp_pgr_old_mapzone m
					JOIN dwfzone dw ON m.mapzone_id = dw.dwfzone_id
					WHERE d.drainzone_id = dw.drainzone_id
				)
				AND NOT EXISTS (
					SELECT 1 FROM temp_pgr_mapzone m
					WHERE m.drainzone_id = d.drainzone_id
				);

				-- clear the geometries of drainzones that have at least on dwfzone in conflict in dwfzone
				UPDATE drainzone d SET the_geom = NULL,
				updated_at = now(),
				updated_by = current_user
				WHERE EXISTS (
					SELECT 1
					FROM (
						SELECT drainzone_id from temp_pgr_mapzone
						GROUP BY drainzone_id
						HAVING max(CARDINALITY(mapzone_ids)) > 1
					) m
					WHERE m.drainzone_id = d.drainzone_id
				);

				UPDATE dwfzone d SET drainzone_id =
					CASE
						WHEN m.max_dwfzones = 1 then m.drainzone_id
						ELSE -1
					END,
					updated_at = now(),
					updated_by = current_user
				FROM (
					SELECT mapzone_id,
						drainzone_id,
						max(CARDINALITY(mapzone_ids)) over(PARTITION BY drainzone_id) AS max_dwfzones,
						mapzone_ids
					FROM temp_pgr_mapzone
				) m
				WHERE d.dwfzone_id = ANY(m.mapzone_ids);

				UPDATE dwfzone d SET drainzone_id = 0,
					updated_at = now(),
					updated_by = current_user
				WHERE NOT EXISTS (SELECT 1 FROM temp_pgr_mapzone m WHERE d.dwfzone_id = ANY(m.mapzone_ids))
				AND EXISTS (SELECT 1 FROM temp_pgr_mapzone m WHERE d.drainzone_id = m.drainzone_id);
			END IF;

			-- update expl_id for the mapzones with conflict
			EXECUTE format($sql$
				UPDATE %I m
				SET expl_id = t.expl_ids
				FROM (
					SELECT
						g.mapzone_id,
						array_agg(DISTINCT e.expl_id ORDER BY e.expl_id) AS expl_ids
					FROM temp_pgr_graphconfig g
					JOIN arc a ON a.arc_id = g.pgr_arc_id
					CROSS JOIN LATERAL unnest(array_append(a.expl_visibility::integer[], a.expl_id)) AS e(expl_id)
					WHERE EXISTS (
						SELECT 1 FROM temp_pgr_mapzone tm WHERE tm.mapzone_id = -1 AND g.mapzone_id = ANY (tm.mapzone_ids)
					)
					AND g.graph_type = 'use'
					AND EXISTS (SELECT 1 FROM vf_exploitation vfe WHERE vfe.expl_id = e.expl_id)
					GROUP BY g.mapzone_id
				) t
				WHERE m.%I = t.mapzone_id
				$sql$
			, v_mapzone_table, v_mapzone_field);

			-- update muni_id for the mapzones with conflict
			EXECUTE format($sql$
				UPDATE %I m
				SET muni_id = t.muni_ids
				FROM (
					SELECT
						g.mapzone_id,
						array_agg(DISTINCT a.muni_id ORDER BY a.muni_id) AS muni_ids
					FROM temp_pgr_graphconfig g
					JOIN arc a ON a.arc_id = g.pgr_arc_id
					WHERE EXISTS (
						SELECT 1 FROM temp_pgr_mapzone tm WHERE tm.mapzone_id = -1 AND g.mapzone_id = ANY (tm.mapzone_ids)
					)
					AND g.graph_type = 'use'
					GROUP BY g.mapzone_id
				) t
				WHERE m.%I = t.mapzone_id
				$sql$
			, v_mapzone_table, v_mapzone_field);

			IF v_class <> 'SECTOR' THEN
				EXECUTE format($sql$
					UPDATE %I m
					SET sector_id = t.sector_id
					FROM temp_pgr_mapzone t
					WHERE m.%I = t.mapzone_id
						AND t.mapzone_id > 0
					$sql$
				, v_mapzone_table, v_mapzone_field);

				-- update sector_id for the mapzones with conflict
				EXECUTE format($sql$
					UPDATE %I m
					SET sector_id = t.sector_ids
					FROM (
						SELECT
							g.mapzone_id,
							array_agg(DISTINCT a.sector_id ORDER BY a.sector_id) AS sector_ids
						FROM temp_pgr_graphconfig g
						JOIN arc a ON a.arc_id = g.pgr_arc_id
						WHERE EXISTS (
							SELECT 1 FROM temp_pgr_mapzone tm WHERE tm.mapzone_id = -1 AND g.mapzone_id = ANY (tm.mapzone_ids)
						)
						AND g.graph_type = 'use'
						GROUP BY g.mapzone_id
					) t
					WHERE m.%I = t.mapzone_id
					$sql$
				, v_mapzone_table, v_mapzone_field);

			ELSE
				-- Synchronize selector_sector with the sectors that match muni_id and expl_id
				DELETE FROM selector_sector ss
				WHERE NOT EXISTS (
					SELECT 1
					FROM sector s
					JOIN selector_municipality sm ON sm.muni_id = ANY(s.muni_id)
					WHERE s.active
						AND EXISTS (
							SELECT 1
							FROM selector_expl se
							WHERE se.expl_id = ANY(s.expl_id) AND se.cur_user = sm.cur_user
						)
						AND ss.sector_id = s.sector_id
						AND ss.cur_user = sm.cur_user
				);

				INSERT INTO selector_sector (sector_id, cur_user)
				SELECT DISTINCT s.sector_id, sm.cur_user
				FROM sector s
				JOIN selector_municipality sm ON sm.muni_id = ANY(s.muni_id)
				WHERE s.active
				AND EXISTS (
					SELECT 1
					FROM selector_expl se
					WHERE se.expl_id = ANY(s.expl_id) AND se.cur_user = sm.cur_user
				)
				AND NOT EXISTS (
					SELECT 1
					FROM selector_sector ss
					WHERE ss.sector_id = s.sector_id AND ss.cur_user = ss.cur_user
				);

			END IF;

			-- Clear geometries for mapzones that existed previously but are no longer assigned to any feature
			EXECUTE format($sql$
				UPDATE %I tm
				SET the_geom   = NULL,
					addparam = NULL,
					updated_at = now(),
					updated_by = current_user
				WHERE EXISTS (
					SELECT 1
					FROM temp_pgr_old_mapzone om
					WHERE om.mapzone_id = tm.%I
				)
				AND NOT EXISTS (
					SELECT 1
					FROM temp_pgr_mapzone nm
					WHERE tm.%I = nm.mapzone_id
				)
				$sql$
			, v_mapzone_table, v_mapzone_field, v_mapzone_field);

			-- UPDATE TABLES
			-- ==============

			IF v_netscenario IS NOT NULL THEN

				DELETE FROM plan_netscenario_arc WHERE netscenario_id = v_netscenario::integer;
				DELETE FROM plan_netscenario_node WHERE netscenario_id = v_netscenario::integer;
				DELETE FROM plan_netscenario_connec WHERE netscenario_id = v_netscenario::integer;

				EXECUTE format($sql$
					INSERT INTO plan_netscenario_arc (netscenario_id, arc_id, %I, the_geom)
					SELECT %s, a.arc_id, t.mapzone_id, a.the_geom
					FROM temp_pgr_arc t
					JOIN arc a ON a.arc_id = t.pgr_arc_id
					WHERE t.mapzone_id > 0
					$sql$
				, v_mapzone_field, v_netscenario);

				EXECUTE format($sql$
					INSERT INTO plan_netscenario_node (netscenario_id, node_id, %I, the_geom)
					SELECT %s, n.node_id, t.mapzone_id, n.the_geom
					FROM temp_pgr_node t
					JOIN node n ON n.node_id = t.pgr_node_id
					WHERE EXISTS (
						SELECT 1
						FROM temp_pgr_arc ta
						WHERE ta.mapzone_id > 0
						AND t.pgr_node_id IN (ta.pgr_node_1, ta.pgr_node_2)
					)
					$sql$
				, v_mapzone_field, v_netscenario);

				EXECUTE format($sql$
					INSERT INTO plan_netscenario_connec (netscenario_id, connec_id, %I, the_geom)
					SELECT %s, c.connec_id, t.mapzone_id, c.the_geom
					FROM temp_pgr_connec t
					JOIN connec c ON c.connec_id = t.pgr_connec_id
					WHERE t.mapzone_id > 0
					$sql$
				, v_mapzone_field, v_netscenario);

				IF v_class = 'PRESSZONE' THEN

					-- nodes
					EXECUTE format($sql$
						UPDATE plan_netscenario_node n
						SET staticpressure = t.staticpressure
						FROM (
							SELECT
							pn.node_id,
							CASE
								WHEN pn.%I > 0 THEN
								(p.head
								- COALESCE(n.custom_top_elev, n.top_elev)
								+ COALESCE(n.depth, 0)
								)::numeric(12,3)
								ELSE NULL
							END AS staticpressure
							FROM plan_netscenario_node pn
							JOIN node n ON pn.node_id = n.node_id
							JOIN %I p ON pn.%I = p.%I
							WHERE EXISTS (
							SELECT 1
							FROM temp_pgr_node t
							WHERE t.pgr_node_id = n.node_id
							)
						) t
						WHERE n.node_id = t.node_id
						AND n.staticpressure IS DISTINCT FROM t.staticpressure
						$sql$
					, v_mapzone_field, v_mapzone_table, v_mapzone_field, v_mapzone_field);

					-- connec
					EXECUTE format($sql$
						UPDATE plan_netscenario_connec c
						SET staticpressure = t.staticpressure
						FROM (
							SELECT
							pc.connec_id,
							CASE
								WHEN pc.%I > 0 THEN
								(p.head
								- c.top_elev
								+ COALESCE(c.depth, 0)
								)::numeric(12,3)
								ELSE NULL
							END AS staticpressure
							FROM plan_netscenario_connec pc
							JOIN connec c ON pc.connec_id = c.connec_id
							JOIN %I p ON pc.%I = p.%I
							WHERE EXISTS (
								SELECT 1
								FROM temp_pgr_arc t
								WHERE t.pgr_arc_id = c.arc_id
							)
						) t
						WHERE c.connec_id = t.connec_id
							AND c.staticpressure IS DISTINCT FROM t.staticpressure
						$sql$
					, v_mapzone_field, v_mapzone_table, v_mapzone_field, v_mapzone_field);

				ELSIF v_class = 'DMA' THEN

					UPDATE plan_netscenario_node n
					SET pattern_id = t.pattern_id
					FROM temp_pgr_mapzone t
					WHERE n.dma_id = t.mapzone_id;

					UPDATE plan_netscenario_connec c
					SET pattern_id = t.pattern_id
					FROM temp_pgr_mapzone t
					WHERE c.dma_id = t.mapzone_id;
				END IF;

			ELSE -- v_netscenario

				-- update arc
				EXECUTE format($sql$
					UPDATE arc a
					SET %I = ta.mapzone_id
					FROM temp_pgr_arc ta
					WHERE a.arc_id = ta.pgr_arc_id
					AND a.%I IS DISTINCT FROM ta.mapzone_id
					$sql$
				, v_mapzone_field, v_mapzone_field);

				-- node
				EXECUTE format($sql$
					UPDATE node n
					SET %I = tn.mapzone_id
					FROM temp_pgr_node tn
					WHERE n.node_id = tn.pgr_node_id
					AND n.%I IS DISTINCT FROM tn.mapzone_id
					$sql$
				, v_mapzone_field, v_mapzone_field);

				IF v_class = 'SECTOR' THEN
    				UPDATE element e
    				SET sector_id = te.mapzone_id
    				FROM temp_pgr_element te
    				WHERE e.element_id = te.pgr_element_id
    				    AND e.sector_id IS DISTINCT FROM te.mapzone_id;

					-- node_x_sector_visibility for borders (nodes for ws, arcs for ud) and for the Heads of the mapzones
	                INSERT INTO node_x_sector_visibility (node_id, sector_id)
					SELECT n.pgr_node_id, a.mapzone_id
                    FROM temp_pgr_node n
                    JOIN temp_pgr_arc a ON n.pgr_node_id = a.pgr_node_1 OR n.pgr_node_id = a.pgr_node_2
                    WHERE n.mapzone_id >= 0
                    AND a.mapzone_id > 0
					AND a.mapzone_id <> n.mapzone_id
                    ON CONFLICT DO NOTHING;

                    DELETE FROM node_x_sector_visibility nxsv
                    WHERE NOT EXISTS (
                        SELECT 1
                        FROM temp_pgr_node n
                        JOIN temp_pgr_arc a ON n.pgr_node_id = a.pgr_node_1 OR n.pgr_node_id = a.pgr_node_2
                        WHERE nxsv.node_id = n.pgr_node_id
                        AND nxsv.sector_id = a.mapzone_id
                    );

					v_query_text_aux := '';
					IF v_project_type = 'UD' THEN
						v_query_text_aux := format($sql$
							UNION ALL
							SELECT exg.element_id, exg.gully_id AS feature_id, tg.mapzone_id
							FROM element_x_gully exg
							JOIN temp_pgr_element te ON te.pgr_element_id = exg.element_id
							JOIN temp_pgr_gully tg ON tg.pgr_gully_id = exg.gully_id
							UNION ALL
							SELECT exl.element_id, exl.link_id AS feature_id, te.mapzone_id
							FROM element_x_link exl
							JOIN temp_pgr_element te ON te.pgr_element_id = exl.element_id
							JOIN link l ON l.link_id = exl.link_id
							JOIN temp_pgr_gully tg ON l.feature_id = tg.pgr_gully_id
							WHERE l.feature_type = 'GULLY'
						$sql$
						);
					END IF;

					v_query_text := format($sql$
						SELECT exa.element_id, exa.arc_id AS feature_id, ta.mapzone_id
						FROM element_x_arc exa
						JOIN temp_pgr_element te ON te.pgr_element_id = exa.element_id
						JOIN temp_pgr_arc ta ON ta.pgr_arc_id = exa.arc_id
						UNION ALL
						SELECT exn.element_id, exn.node_id AS feature_id, tn.mapzone_id
						FROM element_x_node exn
						JOIN temp_pgr_element te ON te.pgr_element_id = exn.element_id
						JOIN temp_pgr_node tn ON tn.pgr_node_id = exn.node_id
						UNION ALL
						SELECT exc.element_id, exc.connec_id AS feature_id, tc.mapzone_id
						FROM element_x_connec exc
						JOIN temp_pgr_element te ON te.pgr_element_id = exc.element_id
						JOIN temp_pgr_connec tc ON tc.pgr_connec_id = exc.connec_id
						UNION ALL
						SELECT exl.element_id, exl.link_id AS feature_id, te.mapzone_id
						FROM element_x_link exl
						JOIN temp_pgr_element te ON te.pgr_element_id = exl.element_id
						JOIN link l ON l.link_id = exl.link_id
						JOIN temp_pgr_connec tc ON l.feature_id = tc.pgr_connec_id
						WHERE l.feature_type = 'CONNEC'
						%s
					$sql$, v_query_text_aux);

					EXECUTE format($sql$
						INSERT INTO element_x_sector_visibility (element_id, sector_id)
						SELECT t.element_id, t.mapzone_id FROM (
							%s
						) t
						JOIN temp_pgr_element te ON te.pgr_element_id = t.element_id
						WHERE te.mapzone_id <> t.mapzone_id
						ON CONFLICT DO NOTHING;
					$sql$, v_query_text);

					EXECUTE format($sql$
						DELETE FROM element_x_sector_visibility exsv
						WHERE NOT EXISTS (
							SELECT 1
							FROM (%s) t
							WHERE t.element_id = exsv.element_id
							AND t.mapzone_id = exsv.sector_id
						)
					$sql$, v_query_text);
				END IF;

				-- connec
				EXECUTE format($sql$
					UPDATE connec c
					SET %I = tc.mapzone_id
					FROM temp_pgr_connec tc
					WHERE c.connec_id = tc.pgr_connec_id
					AND c.%I IS DISTINCT FROM tc.mapzone_id
					$sql$
				, v_mapzone_field, v_mapzone_field);

				-- link connec
				EXECUTE format($sql$
					UPDATE link l
					SET %I = tc.mapzone_id
					FROM temp_pgr_connec tc
					WHERE l.feature_id = tc.pgr_connec_id
					AND l.feature_type = 'CONNEC'
					AND l.%I IS DISTINCT FROM tc.mapzone_id
					$sql$
				, v_mapzone_field, v_mapzone_field);

				IF v_project_type = 'UD' THEN
					-- gully
					EXECUTE format($sql$
						UPDATE gully g
						SET %I = tg.mapzone_id
						FROM temp_pgr_gully tg
						WHERE g.gully_id = tg.pgr_gully_id
							AND g.%I IS DISTINCT FROM tg.mapzone_id
						$sql$
					, v_mapzone_field, v_mapzone_field);

					-- link gully
					EXECUTE format($sql$
						UPDATE link l
						SET %I = tg.mapzone_id
						FROM temp_pgr_gully tg
						WHERE l.feature_id = tg.pgr_gully_id
							AND l.feature_type = 'GULLY'
							AND l.%I IS DISTINCT FROM tg.mapzone_id
						$sql$
					, v_mapzone_field, v_mapzone_field);
				END IF;

				-- Reset mapzone assignment for the red that belonged to old mapzones
				-- but is no longer present in the current graph
				IF EXISTS (SELECT 1 FROM temp_pgr_old_mapzone LIMIT 1) THEN

					-- node, connec, gully
					IF v_class = 'PRESSZONE' THEN
						v_query_text_aux := ', staticpressure = NULL';
					ELSIF v_class = 'DWFZONE' THEN
						v_query_text_aux := ', drainzone_outfall = NULL, dwfzone_outfall = NULL';
					ELSE
						v_query_text_aux := '';
					END IF;

					EXECUTE format($sql$
						UPDATE node n
						SET %I = 0
							%s
						WHERE EXISTS (
							SELECT 1 FROM temp_pgr_old_mapzone tm WHERE n.%I = tm.mapzone_id
						)
						AND NOT EXISTS (
							SELECT 1 FROM temp_pgr_node tn WHERE tn.pgr_node_id = n.node_id
						)
						AND n.%I IS DISTINCT FROM 0
						$sql$
					, v_mapzone_field, v_query_text_aux, v_mapzone_field, v_mapzone_field);

					IF v_class = 'SECTOR' THEN
						UPDATE element e
						SET sector_id = 0
						WHERE exists (
							SELECT 1 FROM temp_pgr_old_mapzone tm WHERE tm.mapzone_id = e.sector_id
						)
						AND NOT EXISTS (
							SELECT 1 FROM temp_pgr_element te WHERE te.pgr_element_id = e.element_id
						);

    					DELETE FROM node_x_sector_visibility nxsv
                        WHERE EXISTS (
							SELECT 1 FROM temp_pgr_old_mapzone tm WHERE tm.mapzone_id = nxsv.sector_id
						)
						AND NOT EXISTS (
							SELECT 1 FROM temp_pgr_node tn WHERE tn.pgr_node_id = nxsv.node_id
						);

						DELETE FROM element_x_sector_visibility exsv
						WHERE EXISTS (
							SELECT 1 FROM temp_pgr_old_mapzone tm WHERE tm.mapzone_id = exsv.sector_id
						)
						AND NOT EXISTS (
							SELECT 1 FROM temp_pgr_element te WHERE te.pgr_element_id = exsv.element_id
						);
					END IF;

					EXECUTE format($sql$
						UPDATE connec c
						SET %I = 0
							%s
						WHERE EXISTS (
							SELECT 1 FROM temp_pgr_old_mapzone tm WHERE c.%I = tm.mapzone_id
						)
						AND NOT EXISTS (
							SELECT 1 FROM temp_pgr_connec tc WHERE tc.pgr_connec_id = c.connec_id
						)
						AND c.%I IS DISTINCT FROM 0
						$sql$
					, v_mapzone_field, v_query_text_aux, v_mapzone_field, v_mapzone_field);

					IF v_project_type = 'UD' THEN
						EXECUTE format($sql$
							UPDATE gully g
							SET %I = 0
								%s
							WHERE EXISTS (
								SELECT 1
								FROM temp_pgr_old_mapzone tm
								WHERE g.%I = tm.mapzone_id
							)
							AND NOT EXISTS (
								SELECT 1
								FROM temp_pgr_gully tg
								WHERE tg.pgr_gully_id = g.gully_id
							)
							AND g.%I IS DISTINCT FROM 0
							$sql$
						, v_mapzone_field, v_query_text_aux, v_mapzone_field, v_mapzone_field);
					END IF;

					-- arcs, links
					IF v_class = 'PRESSZONE' THEN
						v_query_text_aux := ', staticpressure1 = NULL, staticpressure2 = NULL';
					ELSIF v_class = 'DWFZONE' THEN
						v_query_text_aux := ', drainzone_outfall = NULL, dwfzone_outfall = NULL';
					ELSE
						v_query_text_aux := '';
					END IF;

					EXECUTE format($sql$
						UPDATE arc a
						SET %I = 0
							%s
						WHERE EXISTS (
							SELECT 1 FROM temp_pgr_old_mapzone tm WHERE a.%I = tm.mapzone_id
						)
						AND NOT EXISTS (
							SELECT 1 FROM temp_pgr_arc ta WHERE ta.pgr_arc_id = a.arc_id
						)
						AND a.%I IS DISTINCT FROM 0
						$sql$
					, v_mapzone_field, v_query_text_aux, v_mapzone_field, v_mapzone_field);

					EXECUTE format($sql$
						UPDATE link l
						SET %I = 0
							%s
						WHERE l.feature_type = 'CONNEC'
							AND EXISTS (
								SELECT 1 FROM temp_pgr_old_mapzone tm WHERE l.%I = tm.mapzone_id
							)
							AND NOT EXISTS (
								SELECT 1 FROM temp_pgr_connec tc WHERE tc.pgr_connec_id = l.feature_id
							)
							AND l.%I IS DISTINCT FROM 0
						$sql$
					, v_mapzone_field, v_query_text_aux, v_mapzone_field, v_mapzone_field);

					IF v_project_type = 'UD' THEN
						EXECUTE format($sql$
							UPDATE link l
							SET %I = 0
								%s
							WHERE l.feature_type = 'GULLY'
								AND EXISTS (
									SELECT 1 FROM temp_pgr_old_mapzone tm WHERE l.%I = tm.mapzone_id
								)
								AND NOT EXISTS (
									SELECT 1 FROM temp_pgr_gully tg WHERE tg.pgr_gully_id = l.feature_id
								)
								AND l.%I IS DISTINCT FROM 0
							$sql$
						, v_mapzone_field, v_query_text_aux, v_mapzone_field, v_mapzone_field);
					END IF;

				END IF; -- exists in temp_pgr_old_mapzone

				-- -- Mapzone-specific updates
				-- ==============================

				IF v_project_type = 'WS' THEN

					-- update to_arc for METER, PUMP if to_arc IS NULL
					UPDATE man_meter m
					SET to_arc = t.pgr_arc_id
					FROM temp_pgr_arc t
					WHERE t.node_parent = m.node_id
					AND m.to_arc IS NULL;

					UPDATE man_pump p
					SET to_arc = t.pgr_arc_id
					FROM temp_pgr_arc t
					WHERE t.node_parent = p.node_id
					AND p.to_arc IS NULL;

					-- static pressure
					IF v_class = 'PRESSZONE' THEN

						-- nodes
						UPDATE node nn
						SET staticpressure = t.staticpressure
						FROM (
							SELECT
								n.node_id,
								(p.head - COALESCE(n.custom_top_elev, n.top_elev) + COALESCE(n.depth, 0))::numeric(12,3) AS staticpressure
							FROM node n
							JOIN presszone p ON n.presszone_id = p.presszone_id
							WHERE p.head IS DISTINCT FROM 0
							AND EXISTS (SELECT 1 FROM temp_pgr_node t WHERE t.pgr_node_id = n.node_id)
						) t
						WHERE nn.node_id = t.node_id
						AND nn.staticpressure IS DISTINCT FROM t.staticpressure;

						-- connec
						UPDATE connec cc
						SET staticpressure = t.staticpressure
						FROM (
							SELECT
								c.connec_id,
								(p.head - c.top_elev + COALESCE(c.depth, 0))::numeric(12,3) AS staticpressure
							FROM connec c
							JOIN presszone p ON c.presszone_id = p.presszone_id
							WHERE p.head IS DISTINCT FROM 0
							AND EXISTS (SELECT 1 FROM temp_pgr_connec t WHERE t.pgr_connec_id = c.connec_id)
						) t
						WHERE cc.connec_id = t.connec_id
						AND cc.staticpressure IS DISTINCT FROM t.staticpressure;

						-- arc
						UPDATE arc aa
						SET staticpressure1 = t.staticpressure1,
							staticpressure2 = t.staticpressure2
						FROM (
							SELECT
								a.arc_id,
								(p.head - a.elevation1 + COALESCE(a.depth1, 0))::numeric(12,3) AS staticpressure1,
								(p.head - a.elevation2 + COALESCE(a.depth2, 0))::numeric(12,3) AS staticpressure2
							FROM arc a
							JOIN presszone p ON a.presszone_id = p.presszone_id
							WHERE p.head IS DISTINCT FROM 0
							AND EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = a.arc_id)
						) t
						WHERE aa.arc_id = t.arc_id
						AND (aa.staticpressure1 IS DISTINCT FROM t.staticpressure1
							OR aa.staticpressure2 IS DISTINCT FROM t.staticpressure2);

						-- link
						UPDATE link ll
						SET staticpressure1 = t.staticpressure1,
							staticpressure2 = t.staticpressure2
						FROM (
							SELECT
								l.link_id,
								(p.head - l.top_elev1 + COALESCE(l.depth1, 0))::numeric(12,3) AS staticpressure1,
								(p.head - l.top_elev2 + COALESCE(l.depth2, 0))::numeric(12,3) AS staticpressure2
							FROM link l
							JOIN presszone p ON l.presszone_id = p.presszone_id
							WHERE p.head IS DISTINCT FROM 0
							AND l.feature_type = 'CONNEC'
							AND EXISTS (
								SELECT 1
								FROM temp_pgr_connec t
								WHERE t.pgr_connec_id = l.feature_id
							)
						) t
						WHERE ll.link_id = t.link_id
						AND (ll.staticpressure1 IS DISTINCT FROM t.staticpressure1
						OR ll.staticpressure2 IS DISTINCT FROM t.staticpressure2);

					ELSIF v_class = 'DMA' THEN



						-- todo work in progress
						/*
						FOR rec IN SELECT DISTINCT expl_id FROM v_temp_arc
						LOOP

							EXECUTE 'SELECT gw_fct_getdmagraph($${"client":{"device":4, "infoType":1, "lang":"ES"},
							"feature":{},"data":{"parameters":{"explId":"'||rec.expl_id||'", "searchDistRouting":999}}}$$)';

						END LOOP;
						*/

					END IF; -- v_class

				ELSE -- v_project_type (UD)

					-- dwfzone, drainzone
					IF v_class = 'DWFZONE' THEN

						-- update dwfzone_outfall (in one querry are updated DISCONNECTED and CONFLICT too - o.dwfzone_outfall = NULL)

						WITH outfalls AS (
							SELECT
								d.node AS pgr_arc_id,
								array_agg(DISTINCT ta.pgr_node_2 ORDER BY ta.pgr_node_2) AS dwfzone_outfall
							FROM temp_pgr_drivingdistance d
							JOIN temp_pgr_arc ta ON d.start_vid = ta.pgr_arc_id
							WHERE EXISTS (
								SELECT 1
								FROM temp_pgr_mapzone m
								WHERE cardinality(m.mapzone_ids) = 1
								AND m.component = ta.component
							)
							GROUP BY d.node
						)
						UPDATE arc a SET dwfzone_outfall = o.dwfzone_outfall
						FROM temp_pgr_arc pa
						LEFT JOIN  outfalls o USING (pgr_arc_id)
						WHERE a.arc_id = pa.pgr_arc_id
						AND a.dwfzone_outfall IS DISTINCT FROM o.dwfzone_outfall;

						UPDATE node n SET dwfzone_outfall = a.dwfzone_outfall
						FROM arc a
						WHERE EXISTS (SELECT 1 FROM temp_pgr_node tn WHERE tn.pgr_node_id = n.node_id)
						AND a.node_2 = n.node_id
						AND n.dwfzone_outfall IS DISTINCT FROM a.dwfzone_outfall;

						UPDATE connec c SET dwfzone_outfall = a.dwfzone_outfall
						FROM arc a
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = c.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_connec t WHERE t.connec_id = c.connec_id)
						AND c.arc_id = a.arc_id
						AND c.dwfzone_outfall IS DISTINCT FROM a.dwfzone_outfall;

						UPDATE gully g SET dwfzone_outfall = a.dwfzone_outfall
						FROM arc a
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = g.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_gully t WHERE t.gully_id = g.gully_id)
						AND g.arc_id = a.arc_id
						AND g.dwfzone_outfall IS DISTINCT FROM a.dwfzone_outfall;

						UPDATE link l SET dwfzone_outfall = c.dwfzone_outfall
						FROM connec c
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = c.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_link_connec t WHERE t.link_id = l.link_id)
						AND l.feature_id = c.connec_id
						AND l.dwfzone_outfall IS DISTINCT FROM c.dwfzone_outfall;

						UPDATE link l SET dwfzone_outfall = g.dwfzone_outfall
						FROM gully g
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = g.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_link_gully t WHERE t.link_id = l.link_id)
						AND l.feature_id = g.gully_id
						AND l.dwfzone_outfall IS DISTINCT FROM g.dwfzone_outfall;

						-- update drainzone_outfall (in one querry are updated DISCONNECTED and CONFLICT too - o.drainzone_outfall = NULL)
						WITH outfalls AS (
							SELECT
								d.node AS pgr_arc_id,
								array_agg(DISTINCT ta.pgr_node_2 ORDER BY ta.pgr_node_2) AS drainzone_outfall
							FROM temp_pgr_drivingdistance_initoverflowpath d
							JOIN temp_pgr_arc ta ON d.start_vid = ta.pgr_arc_id
							WHERE EXISTS (
								SELECT 1
								FROM temp_pgr_mapzone m
								WHERE cardinality(m.mapzone_ids) = 1
								AND m.component = ta.component
							)
							AND NOT EXISTS (
								SELECT 1
								FROM temp_pgr_drivingdistance dd
								WHERE dd.node = d.node
								AND dd.start_vid = d.start_vid
							)
							GROUP BY d.node
						)
						UPDATE arc a SET drainzone_outfall = o.drainzone_outfall
						FROM temp_pgr_arc pa
						LEFT JOIN  outfalls o USING (pgr_arc_id)
						WHERE a.arc_id = pa.pgr_arc_id
						AND a.drainzone_outfall IS DISTINCT FROM o.drainzone_outfall;

						UPDATE node n SET drainzone_outfall = a.drainzone_outfall
						FROM arc a
						WHERE EXISTS (SELECT 1 FROM temp_pgr_node tn WHERE tn.pgr_node_id = n.node_id)
						AND a.node_2 = n.node_id
						AND n.drainzone_outfall IS DISTINCT FROM a.drainzone_outfall;

						UPDATE connec c SET drainzone_outfall = a.drainzone_outfall
						FROM arc a
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = c.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_connec t WHERE t.connec_id = c.connec_id)
						AND c.arc_id = a.arc_id
						AND c.drainzone_outfall IS DISTINCT FROM a.drainzone_outfall;

						UPDATE gully g SET drainzone_outfall = a.drainzone_outfall
						FROM arc a
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = g.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_gully t WHERE t.gully_id = g.gully_id)
						AND g.arc_id = a.arc_id
						AND g.drainzone_outfall IS DISTINCT FROM a.drainzone_outfall;

						UPDATE link l SET drainzone_outfall = c.drainzone_outfall
						FROM connec c
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = c.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_link_connec t WHERE t.link_id = l.link_id)
						AND l.feature_id = c.connec_id
						AND l.drainzone_outfall IS DISTINCT FROM c.drainzone_outfall;

						UPDATE link l SET drainzone_outfall = g.drainzone_outfall
						FROM gully g
						WHERE EXISTS (SELECT 1 FROM temp_pgr_arc t WHERE t.pgr_arc_id = g.arc_id)
						AND EXISTS (SELECT 1 FROM v_temp_link_gully t WHERE t.link_id = l.link_id)
						AND l.feature_id = g.gully_id
						AND l.drainzone_outfall IS DISTINCT FROM g.drainzone_outfall;

					END IF;

				END IF; -- v_project_type

			END IF; -- v_netscenario

			RAISE NOTICE 'Filling temp_pgr_mapzone_graph ';

			-- it's SELECT DISTINCT in case the graph_delimiter is a source with 2 toArc with the same DMA
			-- restriction unicity: mapzone_id, node_id
			INSERT INTO temp_pgr_mapzone_graph (node_id, netscenario_id, mapzone_id, mapzone_type, flow_sign)
			SELECT DISTINCT n.pgr_node_id, v_netscenario, a.mapzone_id, v_class,
			CASE WHEN a.node_parent IS NOT NULL THEN 1
			ELSE -1
			END
			FROM temp_pgr_node n
			JOIN temp_pgr_arc a ON n.pgr_node_id IN (a.pgr_node_1, a.pgr_node_2)
			WHERE n.graph_delimiter = 'nodeParent'
			AND a.mapzone_id > 0;

			EXECUTE format($sql$
				WITH affected_mapzone AS (
					SELECT DISTINCT mapzone_id FROM temp_pgr_mapzone_graph
					UNION
					SELECT DISTINCT mapzone_id FROM temp_pgr_old_mapzone
				)
				DELETE FROM %I mzg
				WHERE EXISTS (
					SELECT 1
					FROM affected_mapzone am
					WHERE mzg.mapzone_type = %L
					AND mzg.mapzone_id = am.mapzone_id
				);
			$sql$, v_mapzone_graph_table, v_class);

			EXECUTE format($sql$
				WITH affected_node AS (
					SELECT DISTINCT node_id FROM temp_pgr_mapzone_graph
				)
				DELETE FROM %I mzg
				WHERE EXISTS (
					SELECT 1 
					FROM affected_node an 
					WHERE mzg.mapzone_type = %L
					AND mzg.node_id = an.node_id);
			$sql$, v_mapzone_graph_table, v_class);

			IF v_netscenario IS NOT NULL THEN
				INSERT INTO plan_netscenario_mapzone_graph (node_id, netscenario_id, mapzone_id, mapzone_type, flow_sign)
				SELECT node_id, v_netscenario, mapzone_id, mapzone_type, flow_sign FROM temp_pgr_mapzone_graph;
			ELSE
				INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign)
				SELECT node_id, mapzone_id, mapzone_type, flow_sign FROM temp_pgr_mapzone_graph;
			END IF;

			-- update macromapzones
			IF v_class = 'DWFZONE' THEN
				WITH
					temp_dwfzone AS (
						SELECT d.dwfzone_id, d.drainzone_id, d.the_geom, d.expl_id, d.muni_id, d.sector_id
						FROM temp_pgr_mapzone m
						JOIN dwfzone d ON d.dwfzone_id = m.mapzone_ids[1]
						WHERE d.drainzone_id > 0
					),
					geom AS (
						SELECT drainzone_id, ST_Multi(ST_CollectionExtract(ST_Collect(the_geom), 3)) AS the_geom
						FROM temp_dwfzone
						GROUP BY drainzone_id
					),
					expl AS (
						SELECT a.drainzone_id, array_agg(DISTINCT a.expl_id ORDER BY a.expl_id) AS expl_id
						FROM (
							SELECT drainzone_id, unnest(expl_id) AS expl_id FROM temp_dwfzone
						) a
						GROUP BY a.drainzone_id
					),
					muni AS (
						SELECT a.drainzone_id, array_agg(DISTINCT a.muni_id ORDER BY a.muni_id) AS muni_id
						FROM (
							SELECT drainzone_id, unnest(muni_id) AS muni_id FROM temp_dwfzone
						) a
						GROUP BY a.drainzone_id
					),
					sector AS (
						SELECT a.drainzone_id, array_agg(DISTINCT a.sector_id ORDER BY a.sector_id) AS sector_id
						FROM (
							SELECT drainzone_id, unnest(sector_id) AS sector_id FROM temp_dwfzone
						) a
						GROUP BY a.drainzone_id
					)
				UPDATE drainzone d
				SET the_geom = g.the_geom,
					expl_id = e.expl_id,
					muni_id =m.muni_id,
					sector_id = s.sector_id,
					updated_at = now(),
					updated_by = current_user
				FROM geom g
				JOIN expl e USING(drainzone_id)
				JOIN muni m USING(drainzone_id)
				JOIN sector s USING(drainzone_id)
				WHERE d.drainzone_id = g.drainzone_id;
			ELSE
				IF v_recalculate_macromapzones THEN
					-- TODO: recalculate macromapzones
				END IF;
			END IF;

		END IF; -- v_commit_changes
	ELSE
		-- Insert message for graphconfig errors found
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4628", "function":"2706", "tempTable":"temp_", "criticity":"3", "fid": '||v_fid||'}}$$);';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2706", "tempTable":"temp_", "separator_id": 2049, "criticity":"3", "fid": '||v_fid||'}}$$);';

		v_visible_layer := NULL;
	END IF;

	INSERT INTO temp_audit_check_data (fid,  criticity, error_message)
	SELECT v_fid, criticity, error_message
	FROM t_audit_check_data
	where fid = v_fid or fid = v_checks_fid;

	-- insert spacer lines from sys_label separator
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"", "criticity":"3", "fid": '||v_fid||', "separator_id":"2000"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"", "criticity":"2", "fid": '||v_fid||', "separator_id":"2000"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"", "criticity":"1", "fid": '||v_fid||', "separator_id":"2000"}}$$);';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3508","parameters":null, "tempTable":"", "criticity":"0", "fid": '||v_fid||', "separator_id":"2000"}}$$);';

	-- Get Info for the audit
	SELECT json_agg(row_to_json(t)) INTO v_result
	FROM (
		SELECT id, error_message AS message
		FROM temp_audit_check_data
		WHERE cur_user = current_user AND fid = v_fid
		ORDER BY criticity DESC, id ASC
	) t;
	v_result := COALESCE(v_result, '{}');
	v_result_info := concat ('{"values":',v_result, '}');

	-- END UPDATE SECTION

	-- SECTION[epic=mapzones]: Creating temporal layers

	-- graphconfig
	IF v_project_type = 'WS' THEN

		EXECUTE format($sql$
			SELECT jsonb_build_object(
				'type', 'FeatureCollection',
				'layerName', 'Graphconfig',
				'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
			)
			FROM (
				SELECT jsonb_build_object(
				'type',       'Feature',
				'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
				'properties', to_jsonb(r) - 'the_geom'
				) AS feature
				FROM (
				SELECT
					n.node_id AS feature_id,
					tn.graph_delimiter AS graph_type,
					tn.mapzone_id AS %I,
					mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS name,
					n.the_geom,
					NULL::float AS rotation
					FROM temp_pgr_node tn
					JOIN node n ON n.node_id = tn.pgr_node_id
					JOIN temp_pgr_mapzone mz ON mz.component = tn.component
					WHERE tn.graph_delimiter IN (
						'nodeParent',
						'forceClosed',
						'forceOpen',
						'closedValve',
						'netscenClosedValve',
						'netscenOpenedValve'
					)
				UNION ALL
				SELECT
					a.arc_id AS feature_id,
					'toArc' AS graph_type,
					ta.mapzone_id AS %I,
					mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS name,
					CASE WHEN ta.pgr_node_1 = ta.node_parent THEN
						ST_StartPoint(a.the_geom)
					ELSE
						ST_EndPoint (a.the_geom)
					END AS the_geom,
					CASE WHEN ta.pgr_node_1 = ta.node_parent  THEN
						st_azimuth(st_lineinterpolatepoint(a.the_geom, 0.01), st_lineinterpolatepoint(a.the_geom, 0.02))*400/6.28
					ELSE
						st_azimuth(st_lineinterpolatepoint(a.the_geom, 0.99), st_lineinterpolatepoint(a.the_geom, 0.98))*400/6.28
					END AS rotation
				FROM temp_pgr_arc ta
				JOIN arc a ON ta.pgr_arc_id = a.arc_id
				JOIN temp_pgr_mapzone mz ON mz.component = ta.component
				AND ta.node_parent IS NOT NULL

				) r
			) f
			$sql$, v_mapzone_field, v_mapzone_field
		) INTO v_result;

	ELSE -- v_project_type

		EXECUTE format($sql$
			SELECT jsonb_build_object(
				'type', 'FeatureCollection',
				'layerName', 'Graphconfig',
				'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
			)
			FROM (
				SELECT jsonb_build_object(
				'type',       'Feature',
				'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
				'properties', to_jsonb(r) - 'the_geom'
				) AS feature
				FROM (
				SELECT
					n.node_id AS feature_id,
					tn.graph_delimiter AS graph_type,
					tn.mapzone_id AS %I,
					mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS name,
					n.the_geom,
					NULL::float AS rotation
					FROM temp_pgr_node tn
					JOIN node n ON n.node_id = tn.pgr_node_id
					JOIN temp_pgr_mapzone mz ON mz.component = tn.component
					WHERE tn.graph_delimiter = 'nodeParent'
				UNION ALL
				SELECT
					a.arc_id AS feature_id,
					'toArc' AS graph_type,
					ta.mapzone_id AS %I,
					mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS name,
					ST_EndPoint (a.the_geom) AS the_geom,
					st_azimuth(st_lineinterpolatepoint(a.the_geom, 0.99), st_lineinterpolatepoint(a.the_geom, 0.98))*400/6.28 AS rotation
				FROM temp_pgr_arc ta
				JOIN arc a ON ta.pgr_arc_id = a.arc_id
				JOIN temp_pgr_mapzone mz ON mz.component = ta.component
				AND ta.node_parent IS NOT NULL
				UNION ALL
				SELECT
					a.arc_id AS feature_id,
					ta.graph_delimiter AS graph_type,
					ta.mapzone_id AS %I,
					mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS name,
					ST_StartPoint (a.the_geom) AS the_geom,
					st_azimuth(st_lineinterpolatepoint(a.the_geom, 0.01), st_lineinterpolatepoint(a.the_geom, 0.02))*400/6.28 AS rotation
				FROM temp_pgr_arc ta
				JOIN arc a ON ta.pgr_arc_id = a.arc_id
				JOIN temp_pgr_mapzone mz ON mz.component = ta.component
				AND ta.graph_delimiter = 'initoverflopath'
				UNION ALL
				SELECT
					a.arc_id AS feature_id,
					ta.graph_delimiter AS graph_type,
					ta.mapzone_id AS %I,
					mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS name,
					ST_StartPoint (a.the_geom) AS the_geom,
					st_azimuth(st_lineinterpolatepoint(a.the_geom, 0.01), st_lineinterpolatepoint(a.the_geom, 0.02))*400/6.28 AS rotation
				FROM temp_pgr_arc ta
				JOIN arc a ON ta.pgr_arc_id = a.arc_id
				JOIN temp_pgr_mapzone mz ON mz.component = ta.component
				AND ta.graph_delimiter IN ('forceClosed', 'forceOpen')
				) r
			) f
			$sql$, v_mapzone_field, v_mapzone_field, v_mapzone_field, v_mapzone_field
		) INTO v_result;

	END IF; -- v_project_type

	v_result_graphconfig := v_result;

	EXECUTE format($sql$
		SELECT jsonb_build_object(
			'type', 'FeatureCollection',
			'layerName', 'line_invalid',
			'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
		)
		FROM (
			SELECT jsonb_build_object(
			'type',       'Feature',
			'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
			'properties', to_jsonb(r) - 'the_geom'
			) AS feature
			FROM (
			SELECT a.arc_id, a.arccat_id, a.state, a.expl_id,
				ta.mapzone_id AS %I,
				a.%I AS %I,
				a.the_geom,
				mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS descript
			FROM temp_pgr_arc ta
			JOIN arc a ON a.arc_id = ta.pgr_arc_id
			JOIN temp_pgr_mapzone mz ON mz.component = ta.component
			WHERE ta.mapzone_id IN (0, -1)
			) r
		) f
		$sql$,
		v_mapzone_field, v_mapzone_field, 'old_' || v_mapzone_field
	) INTO v_result;

	v_result_line_invalid := v_result;

	IF v_project_type = 'UD' THEN
		v_query_text_aux := format($sql$
			UNION ALL
			SELECT
				g.gully_id AS feature_id, 'GULLY' AS feature_type, g.gullycat_id AS featurecat_id, g.state, g.expl_id,
				tg.mapzone_id AS %I,
				g.%I AS %I,
				g.the_geom,
				mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS descript
			FROM temp_pgr_gully tg
			JOIN gully g ON g.gully_id = tg.pgr_gully_id
			JOIN temp_pgr_mapzone mz ON mz.component = tg.component
			WHERE tg.mapzone_id IN (0, -1)
			$sql$,
			v_mapzone_field, v_mapzone_field, 'old_' || v_mapzone_field
		);

		v_query_text_aux := ' ' || v_query_text_aux;
	ELSE
		v_query_text_aux := '';
	END IF;

	EXECUTE format($sql$
		SELECT jsonb_build_object(
			'type', 'FeatureCollection',
			'layerName', 'point_invalid',
			'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
		)
		FROM (
			SELECT jsonb_build_object(
			'type',       'Feature',
			'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
			'properties', to_jsonb(r) - 'the_geom'
			) AS feature
			FROM (
			SELECT
				c.connec_id AS feature_id, 'CONNEC'::text AS feature_type, c.conneccat_id AS featurecat_id, c.state, c.expl_id,
				tpc.mapzone_id AS %I,
				c.%I AS %I,
				c.the_geom,
				mz.name || '(' || array_to_string(mz.mapzone_ids, ',') || ')' AS descript
			FROM temp_pgr_connec tpc
			JOIN connec c ON c.connec_id = tpc.pgr_connec_id
			JOIN temp_pgr_mapzone mz ON mz.component = tpc.component
			WHERE tpc.mapzone_id IN (0, -1)
			%s
			) r
		) f
		$sql$,
		v_mapzone_field, v_mapzone_field, 'old_' || v_mapzone_field, v_query_text_aux
	) INTO v_result;

	v_result_point_invalid := v_result;

	SELECT EXISTS (
		SELECT 1
		FROM temp_pgr_arc ta
		WHERE ta.mapzone_id = -1
	) INTO v_has_conflicts;

	IF v_commit_changes IS  FALSE THEN

		EXECUTE format($sql$
			SELECT jsonb_build_object(
				'type', 'FeatureCollection',
				'layerName', 'line_valid',
				'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
			)
			FROM (
				SELECT jsonb_build_object(
				'type',       'Feature',
				'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
				'properties', to_jsonb(r) - 'the_geom'
				) AS feature
				FROM (
				SELECT a.arc_id, a.arccat_id, a.state, a.expl_id,
					ta.mapzone_id AS %I,
					a.%I AS %I,
					a.the_geom,
					mz.name AS descript
				FROM temp_pgr_arc ta
				JOIN arc a ON a.arc_id = ta.pgr_arc_id
				JOIN temp_pgr_mapzone mz ON mz.component = ta.component
				WHERE ta.mapzone_id > 0
				) r
			) f
			$sql$,
			v_mapzone_field, v_mapzone_field, 'old_' || v_mapzone_field
		) INTO v_result;

		v_result_line_valid := v_result;


		IF v_project_type = 'UD' THEN
			v_query_text_aux := format($sql$
				UNION ALL
				SELECT
					g.gully_id AS feature_id, 'GULLY'::text AS feature_type, g.gullycat_id AS featurecat_id, g.state, g.expl_id,
					tg.mapzone_id AS %I,
					g.%I AS %I,
					g.the_geom,
					mz.name AS descript
				FROM temp_pgr_gully tg
				JOIN gully g ON g.gully_id = tg.pgr_gully_id
				JOIN temp_pgr_mapzone mz ON mz.component = tg.component
				WHERE tg.mapzone_id > 0
				$sql$,
				v_mapzone_field, v_mapzone_field, 'old_' || v_mapzone_field
			);

			v_query_text_aux := ' ' || v_query_text_aux;
		ELSE
			v_query_text_aux := '';
		END IF;

		EXECUTE format($sql$
			SELECT jsonb_build_object(
				'type', 'FeatureCollection',
				'layerName', 'point_valid',
				'features', COALESCE(jsonb_agg(f.feature), '[]'::jsonb)
			)
			FROM (
				SELECT jsonb_build_object(
				'type',       'Feature',
				'geometry',   ST_AsGeoJSON(ST_Transform(r.the_geom, 4326))::jsonb,
				'properties', to_jsonb(r) - 'the_geom'
				) AS feature
				FROM (
				SELECT
					c.connec_id AS feature_id, 'CONNEC'::text AS feature_type, c.conneccat_id AS featurecat_id, c.state, c.expl_id,
					tpc.mapzone_id AS %I,
					c.%I AS %I,
					c.the_geom,
					mz.name AS descript
				FROM temp_pgr_connec tpc
				JOIN connec c ON c.connec_id = tpc.pgr_connec_id
				JOIN temp_pgr_mapzone mz ON mz.component = tpc.component
				WHERE tpc.mapzone_id > 0
				%s
				) r
			) f
			$sql$,
			v_mapzone_field, v_mapzone_field, 'old_' || v_mapzone_field,
			v_query_text_aux
			) INTO v_result;

		v_result_point_valid := v_result;

		v_visible_layer := NULL;
	END IF;
	-- ENDSECTION

	-- Control NULL values
	v_status := COALESCE(v_status, 'Accepted');
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_graphconfig := COALESCE(v_result_graphconfig, '{}');
	v_result_point_valid := COALESCE(v_result_point_valid, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'point_valid',
		'features', '[]'::jsonb
	)::json);
	v_result_line_valid := COALESCE(v_result_line_valid, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'line_valid',
		'features', '[]'::jsonb
	)::json);
	v_result_point_invalid := COALESCE(v_result_point_invalid, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'point_invalid',
		'features', '[]'::jsonb
	)::json);
	v_result_line_invalid := COALESCE(v_result_line_invalid, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'line_invalid',
		'features', '[]'::jsonb
	)::json);
	v_level := COALESCE(v_level, 0);
	v_message := COALESCE(v_message, '');
	v_version := COALESCE(v_version, '');
	v_netscenario := COALESCE(v_netscenario, -1);

	v_result_line := jsonb_build_array(
		v_result_line_invalid,
		v_result_line_valid
	)::json;

	v_result_point := jsonb_build_array(
		v_result_graphconfig,
		v_result_point_valid,
		v_result_point_invalid
	)::json;

	-- drop temp tables
	v_data :=
    jsonb_build_object(
        'data',
        jsonb_build_object(
            'parameters',
			jsonb_build_object(
				'fid', v_fid,
				'project_type', v_project_type,
				'action', 'DROP'
			)
        )
    );

	PERFORM gw_fct_manage_temp_tables(v_data);

	-- Return JSON
	RETURN gw_fct_json_create_return(('{
		"status":"'||v_status||'",
		"message":{
			"level":'||v_level||',
			"text":"'||v_message||'"
		},
		"version":"'||v_version||'",
		"body":{
			"form":{},
			"data":{
				"graphClass": "'||v_class||'",
				"netscenarioId": "'||v_netscenario::text||'",
				"hasConflicts": '||v_has_conflicts||',
				"info":'||v_result_info||',
				"point":'||v_result_point||',
				"line":'||v_result_line||'
			}
		}
	}')::json, 3508, null, ('{"visible": ["'||v_visible_layer||'"]}')::json, null)::json;

	EXCEPTION WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
		RETURN json_build_object(
		'status', 'Failed',
		'NOSQLERRM', SQLERRM,
		'message', json_build_object(
			'level', right(SQLSTATE, 1),
			'text', SQLERRM
		),
		'SQLSTATE', SQLSTATE,
		'SQLCONTEXT', v_error_context
	);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

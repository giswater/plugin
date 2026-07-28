/*)
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2980

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_setmincut(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setmincut(p_data json)
RETURNS json AS
$BODY$

/*
-- Button networkMincut on mincut dialog
SELECT gw_fct_setmincut('{"data":{"action":"mincutNetwork", "arcId":"2001", "mincutId":"3", "usePsectors":false}}');

-- Button valveUnaccess on mincut dialog
SELECT gw_fct_setmincut('{"data":{"action":"mincutValveUnaccess", "nodeId":1001, "mincutId":"3", "usePsectors":false}}');

-- Button Accept on mincut dialog
SELECT gw_fct_setmincut('{"data":{"action":"mincutAccept", "mincutClass":1, "mincutId":"3", "usePsectors":false}}');

-- Button Accept when is mincutClass = 2
SELECT gw_fct_setmincut('{"data":{"action":"mincutAccept", "mincutClass":2, "mincutId":"3"}}');

-- Button Accept when is mincutClass = 3
SELECT gw_fct_setmincut('{"data":{"action":"mincutAccept", "mincutClass":3, "mincutId":"3"}}');

fid = 216

*/

DECLARE

-- Parameters
v_cur_user text;
v_device integer;
v_action text;
v_mincut_id integer;
v_mincut_class integer;
v_valve_node_id integer;
v_arc_id integer;
v_exists boolean;
v_node integer;
v_minsector_id integer;
v_init_node integer;
v_use_plan_psectors boolean;
v_mincut_version text;
-- 6.0 - normal mincut
-- 6.1 - mincut with minsectors
v_vdefault json;
v_ignore_check_valves boolean;

v_action_aux text;

-- dialog parameters
v_mincut_type text;
v_forecast_start timestamp;
v_forecast_end timestamp;
v_anl_cause text;
v_anl_descript text;
v_received_date timestamp;
v_exec_start timestamp;
v_exec_end timestamp;
v_exec_descript text;
v_exec_user text;
v_exec_from_plot float;
v_exec_depth float;
v_exec_appropiate boolean;
v_exec_the_geom public.geometry;

v_xcoord double precision;
v_ycoord double precision;
v_epsg integer;
v_client_epsg integer;
v_zoomratio float;
v_muni_id integer;
v_streetaxis_id character varying(250);
v_postnumber text;
v_street_name text;
v_has_address_match boolean := FALSE;

v_sensibility_f float;
v_sensibility float;
v_point public.geometry;

v_id integer;
v_version text;
v_days integer;
v_query_text text;
v_pgr_distance float;

-- mincut details
v_mincut_details json;
v_num_arcs integer;
v_length double precision;
v_volume float;
v_num_connecs integer;
v_num_hydrometer integer;
v_num_valve_proposed integer;
v_num_valve_closed integer;
v_priority json;
v_mincut_conflict_array text;
v_mincut_conflict_count integer;
v_bbox jsonb;
v_count_unselected_psectors integer;
v_default_key text;
v_default_value text;

v_mincut_record record;
v_mincut_group_record record;
v_mincut_conflict_record record;
v_mincut_affected_id integer;
v_mincut_affected_ids text;
v_mincut_conflict_group_id uuid;
v_arc_count integer;
v_has_overlap boolean := FALSE;

v_mincut_plannified_state integer := 0; -- Plannified mincut state
v_mincut_in_progress_state integer := 1; -- In progress mincut state
v_mincut_finished_state integer := 2; -- Finished mincut state
v_mincut_cancel_state integer := 3; -- Cancel mincut state
v_mincut_on_planning_state integer := 4; -- On planning mincut state
v_mincut_conflict_state integer := 5; -- Conflict mincut state

v_mincut_network_class integer := 1; -- Network mincut class

v_data json;
v_result json;
v_result_info json;

v_response json;
v_message json;
v_error_context text;

v_row_count integer;

v_init_mincut boolean := FALSE;
v_prepare_mincut boolean := FALSE;
v_core_mincut boolean := FALSE;

v_mode text;

v_update_map_zone integer := 0;
v_concave_hull float := 0.9;
v_srid integer;
v_geom_param_update float := 10;
v_geom_param_update_divide float;

v_has_other_exploitations boolean := FALSE;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;
	SELECT giswater, epsg INTO v_version, v_srid FROM sys_version order by id desc limit 1;

	-- get input parameters
	v_cur_user := p_data->'client'->>'cur_user';
	v_device := p_data->'client'->>'device';
	v_client_epsg := p_data->'client'->>'epsg';

	v_action := p_data->'data'->>'action';
	v_mincut_id := p_data->'data'->>'mincutId';
	v_mincut_class := p_data->'data'->>'mincutClass';
	v_valve_node_id := p_data->'data'->>'nodeId';
	v_arc_id := p_data->'data'->>'arcId';
	v_use_plan_psectors := p_data->'data'->>'usePsectors';
	-- get dialog parameters (IMPORTANT to execute mincut with dialog data)
	v_mincut_type := p_data->'data'->>'mincutType';
	v_anl_cause := p_data->'data'->>'anlCause';
	v_anl_descript := p_data->'data'->>'anlDescript';
	v_forecast_start := p_data->'data'->>'forecastStart';
	v_forecast_end := p_data->'data'->>'forecastEnd';
	v_received_date := p_data->'data'->>'receivedDate';

	v_exec_start := p_data->'data'->>'execStart';
	v_exec_end := p_data->'data'->>'execEnd';
	v_exec_descript := p_data->'data'->>'execDescript';
	v_exec_user := p_data->'data'->>'execUser';
	v_exec_from_plot := p_data->'data'->>'execFromPlot';
	v_exec_depth := p_data->'data'->>'execDepth';
	v_exec_appropiate := p_data->'data'->>'execAppropiate';
	v_exec_the_geom := p_data->'data'->>'execTheGeom';

	v_xcoord := p_data->'data'->'coordinates'->>'xcoord';
	v_ycoord := p_data->'data'->'coordinates'->>'ycoord';
	v_zoomratio := p_data->'data'->'coordinates'->>'zoomRatio';

	v_epsg := (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1);

	v_mincut_version := (SELECT value::json->>'version' FROM config_param_system WHERE parameter = 'om_mincut_config');
	v_vdefault := (SELECT value::json FROM config_param_system WHERE parameter = 'om_mincut_vdefault');
	v_ignore_check_valves := (SELECT value::boolean FROM config_param_system WHERE parameter = 'ignoreCheckValvesMincut');
	v_update_map_zone := (SELECT value::json->>'bufferType' FROM config_param_system WHERE parameter = 'om_mincut_config');
	v_geom_param_update := (SELECT value::json->>'geomParamUpdate' FROM config_param_system WHERE parameter = 'om_mincut_config');

	IF v_client_epsg IS NULL THEN v_client_epsg := v_epsg; END IF;
	IF v_cur_user IS NULL THEN v_cur_user := current_user; END IF;


	-- Create temporary tables if not exists
	-- =======================
	v_data := jsonb_build_object(
		'data', jsonb_build_object(
			'action', 'CREATE',
			'fct_name', 'MINCUT',
			'use_psector', v_use_plan_psectors
		)
	)::text;
	SELECT gw_fct_graphanalytics_manage_temporary(v_data) INTO v_response;

	IF v_response->>'status' <> 'Accepted' THEN
		RETURN v_response;
	END IF;

	-- only allow to delete mincut if it's on planning and the current_user is the one that created it
	IF v_action = 'mincutDelete'
    		AND (SELECT mincut_state FROM om_mincut WHERE id = v_mincut_id) <> v_mincut_on_planning_state
		    AND (SELECT anl_user FROM om_mincut WHERE id = v_mincut_id) = current_user THEN
		RETURN jsonb_build_object(
			'status', 'Failed',
			'message', jsonb_build_object(
				'level', 2,
				'text', 'Mincut not on planning, cannot be deleted, you can cancel it.'
			)
		);
	END IF;

	-- get arc_id from click
	IF v_xcoord IS NOT NULL THEN
		v_sensibility_f := (SELECT (value::json->>'web')::float FROM config_param_system WHERE parameter = 'basic_info_sensibility_factor');
		v_sensibility := (v_zoomratio / 500 * v_sensibility_f);

		-- Make point
		SELECT ST_Transform(ST_SetSRID(ST_MakePoint(v_xcoord,v_ycoord),v_client_epsg),v_epsg) INTO v_point;

		SELECT va.arc_id INTO v_arc_id
		FROM v_temp_arc va
		WHERE ST_DWithin(va.the_geom, v_point,v_sensibility)
		AND EXISTS (
			SELECT 1
			FROM v_temp_arc vta
			WHERE va.arc_id = vta.arc_id
		)
		LIMIT 1;
	END IF;

	-- get valve from coordinates
	IF v_valve_node_id IS NULL AND v_xcoord IS NOT NULL THEN
		v_sensibility_f := (SELECT (value::json->>'web')::float FROM config_param_system WHERE parameter = 'basic_info_sensibility_factor');
		v_sensibility := (v_zoomratio / 500 * v_sensibility_f);

		-- Make point
		SELECT ST_Transform(ST_SetSRID(ST_MakePoint(v_xcoord,v_ycoord),v_client_epsg),v_epsg) INTO v_point;

		SELECT vn.node_id INTO v_valve_node_id
		FROM ve_node vn
		WHERE ST_DWithin(vn.the_geom, v_point, v_sensibility)
		AND EXISTS (
			SELECT 1
			FROM v_temp_node vtn
			WHERE vtn.node_id = vn.node_id
				AND 'MINSECTOR' = ANY (vtn.graph_delimiter)
		)
		LIMIT 1;
	END IF;

	-- CHECK
	-- check if use psectors is active with minsector version
	IF v_use_plan_psectors AND v_mincut_version = '6.1' THEN
		v_mincut_version := '6';
	END IF;

	IF v_mincut_version = '6.1' THEN
		v_mode := 'MINSECTOR';
    ELSE
		v_mode := '';
    END IF;

	--check if arc exists in database or look for a new arc_id in the same location
	IF v_arc_id IS NULL THEN
		SELECT om.anl_feature_id INTO v_arc_id
			FROM om_mincut om
			WHERE om.id = v_mincut_id
			AND EXISTS (
				SELECT 1
				FROM v_temp_arc vta
				WHERE om.anl_feature_id = vta.arc_id
			) ;

		IF v_arc_id IS NULL THEN
			SELECT a.arc_id INTO v_arc_id
			FROM v_temp_arc a
			WHERE EXISTS (
				SELECT 1
				FROM om_mincut om
				WHERE om.id = v_mincut_id
				AND ST_DWithin(a.the_geom, om.anl_the_geom,0.1)
			)
			LIMIT 1;
		END IF;
	ELSE
		-- check if arc_id from ve_arc exists in v_temp_arc
		IF NOT EXISTS (
			SELECT 1 FROM v_temp_arc WHERE arc_id = v_arc_id
		) THEN
			v_arc_id := NULL;
		END IF;
	END IF;

	IF v_arc_id IS NULL THEN

		SELECT json_build_object('level', log_level,'text', error_message)
		INTO v_message FROM sys_message WHERE id = 2008;

		v_message := COALESCE(v_message, '{}');

		v_response := json_build_object(
			'status', 'Failed',
			'message', v_message,
			'version', v_version,
			'body', jsonb_build_object(
				'form', jsonb_build_object(),
				'feature', jsonb_build_object(),
				'data', jsonb_build_object()
			)
		);
		RETURN v_response;

	ELSE
		-- Keep anl_the_geom on refresh/recompute; only (re)position on explicit click or first arc bind
		UPDATE om_mincut om SET
			anl_feature_id = v_arc_id,
			anl_feature_type = 'ARC',
			anl_the_geom = CASE
				WHEN v_point IS NOT NULL THEN v_point
				WHEN om.anl_the_geom IS NULL OR om.anl_feature_id IS DISTINCT FROM v_arc_id THEN
					(SELECT ST_LineInterpolatePoint(the_geom, 0.5) FROM v_temp_arc WHERE arc_id = v_arc_id)
				ELSE om.anl_the_geom
			END,
			expl_id = a.expl_id,
			macroexpl_id = e.macroexpl_id
		FROM v_temp_arc a
		JOIN exploitation e ON e.expl_id = a.expl_id
		WHERE om.id = v_mincut_id
		  AND a.arc_id = v_arc_id
		  AND a.expl_id IS NOT NULL;
	END IF;

	-- check if there is at least one operative node, if not - exit
	IF NOT EXISTS (
		SELECT 1
		FROM v_temp_node n
		JOIN v_temp_arc a ON n.node_id = a.node_1 OR n.node_id = a.node_2
		WHERE a.arc_id = v_arc_id
	) THEN

		SELECT json_build_object('level', log_level,'text', error_message)
		INTO v_message FROM sys_message WHERE id = 4618;

		v_message := COALESCE(v_message, '{}');

		v_response := json_build_object(
			'status', 'Failed',
			'message', v_message,
			'version', v_version,
			'body', jsonb_build_object(
				'form', jsonb_build_object(),
				'feature', jsonb_build_object(),
				'data', jsonb_build_object()
			)
		);
		RETURN v_response;
	END IF;

	IF v_mode = 'MINSECTOR' THEN
		v_minsector_id := (SELECT minsector_id FROM v_temp_arc WHERE arc_id = v_arc_id);

		IF v_minsector_id IS NULL OR v_minsector_id = 0 THEN

			SELECT json_build_object('level', log_level,'text', error_message)
			INTO v_message FROM sys_message WHERE id = 4620;

			v_message := COALESCE(v_message, '{}');

			v_response := json_build_object(
				'status', 'Failed',
				'message', v_message,
				'version', v_version,
				'body', jsonb_build_object(
					'form', jsonb_build_object(),
					'feature', jsonb_build_object(),
					'data', jsonb_build_object()
				)
			);

			RETURN v_response;

		END IF;
	ELSE
		-- pick one of the nodes of the arc v_temp_arc that is not water source (SECTOR); 0 if the arc is in between 2 nodes SECTOR
		v_node := COALESCE(
			(
				SELECT n.node_id
				FROM v_temp_node n
				JOIN v_temp_arc a
					ON n.node_id = a.node_1
					OR n.node_id = a.node_2
				WHERE a.arc_id = v_arc_id
				AND 'SECTOR' <> ALL (n.graph_delimiter)
				LIMIT 1
			),
			0
		);
	END IF;

	IF v_action IN ('mincutValveUnaccess', 'mincutChangeValveStatus') AND v_valve_node_id IS NULL THEN
		SELECT json_build_object('level', log_level,'text', error_message)
		INTO v_message FROM sys_message WHERE id = 2002;

		v_message := COALESCE(v_message, '{}');

		v_response := json_build_object(
			'status', 'Failed',
			'message', v_message,
			'version', v_version,
			'body', jsonb_build_object(
				'form', jsonb_build_object(),
				'feature', jsonb_build_object(),
				'data', jsonb_build_object()
			)
		);

		RETURN v_response;

	END IF;

	-- check if the minsector_id of the arc exists in the cluster:
		-- true: refresh mincut
		-- false: init and refresh mincut
	SELECT EXISTS (
		SELECT 1
		FROM temp_pgr_node_minsector
		WHERE pgr_node_id = v_minsector_id
	)
	INTO v_exists;

	-- manage actions
	------------------
	IF v_action = 'mincutNetwork' THEN
		IF v_exists IS FALSE THEN
			v_init_mincut := TRUE;
			v_prepare_mincut := FALSE;
		ELSE
			v_init_mincut := FALSE;
			v_prepare_mincut := TRUE;
		END IF;
		v_core_mincut := TRUE;

		IF v_device = 5 AND v_mincut_id IS NULL THEN
			SELECT setval('om_mincut_seq', COALESCE((SELECT max(id::integer)+1 FROM om_mincut), 1), true) INTO v_mincut_id;
			INSERT INTO om_mincut (id, mincut_state) VALUES (v_mincut_id, v_mincut_on_planning_state);

			-- Set default values
			FOR v_default_key, v_default_value IN SELECT * FROM jsonb_each_text(v_vdefault::jsonb) LOOP
				EXECUTE 'UPDATE om_mincut SET '||v_default_key||' = '||v_default_value||' WHERE id = '||v_mincut_id||';';
			END LOOP;
			p_data := jsonb_set(p_data::jsonb, '{data,mincutId}', to_jsonb(v_mincut_id))::json;

			-- Build dynamic UPDATE with only passed parameters
			v_query_text := format(
				'UPDATE om_mincut SET mincut_class = %s, anl_the_geom = %L, anl_user = %L, anl_feature_type = %L, anl_feature_id = %s',
				v_mincut_network_class,
				ST_SetSRID(ST_Point(v_xcoord, v_ycoord), v_client_epsg),
				v_cur_user,
				'ARC',
				v_arc_id
			);
			IF (p_data->'data')::jsonb ? 'mincutType' THEN v_query_text := concat(v_query_text, ', mincut_type = ', quote_nullable(v_mincut_type)); END IF;
			IF (p_data->'data')::jsonb ? 'anlCause' THEN v_query_text := concat(v_query_text, ', anl_cause = ', quote_nullable(v_anl_cause)); END IF;
			IF (p_data->'data')::jsonb ? 'anlDescript' THEN v_query_text := concat(v_query_text, ', anl_descript = ', quote_nullable(v_anl_descript)); END IF;
			IF (p_data->'data')::jsonb ? 'receivedDate' THEN v_query_text := concat(v_query_text, ', received_date = ', quote_nullable(v_received_date)); END IF;
			IF (p_data->'data')::jsonb ? 'forecastStart' THEN v_query_text := concat(v_query_text, ', forecast_start = ', quote_nullable(v_forecast_start)); END IF;
			IF (p_data->'data')::jsonb ? 'forecastEnd' THEN v_query_text := concat(v_query_text, ', forecast_end = ', quote_nullable(v_forecast_end)); END IF;
			v_query_text := concat(v_query_text, ' WHERE id = ', v_mincut_id);
			EXECUTE v_query_text;

			UPDATE om_mincut m
			SET expl_id = a.expl_id,
			    macroexpl_id = e.macroexpl_id
			FROM v_temp_arc a
			JOIN exploitation e ON e.expl_id = a.expl_id
			WHERE m.id = v_mincut_id
			  AND a.arc_id = v_arc_id
			  AND a.expl_id IS NOT NULL;
		END IF;

	ELSIF v_action = 'mincutRefresh' THEN
		IF v_exists IS FALSE THEN
			v_init_mincut := TRUE;
			v_prepare_mincut := FALSE;
		ELSE
			v_init_mincut := FALSE;
			v_prepare_mincut := TRUE;
		END IF;
		v_core_mincut := TRUE;

	ELSIF v_action = 'mincutValveUnaccess' THEN
		UPDATE om_mincut_valve
		SET unaccess =
			CASE
				WHEN proposed = TRUE THEN TRUE
				WHEN unaccess = TRUE THEN FALSE
				ELSE unaccess
			END
		WHERE node_id = v_valve_node_id
			AND result_id = v_mincut_id;

		GET DIAGNOSTICS v_row_count = ROW_COUNT;

		IF v_row_count = 0 THEN
			-- do nothing because the previous result is exactly the same
			v_init_mincut := FALSE;
			v_prepare_mincut := FALSE;
			v_core_mincut := FALSE;
		ELSE
			IF v_exists IS FALSE THEN
				v_init_mincut := TRUE;
				v_prepare_mincut := FALSE;
			ELSE
				v_init_mincut := FALSE;
				v_prepare_mincut := TRUE;
			END IF;
			v_core_mincut := TRUE;
		END IF;
	ELSIF v_action = 'mincutChangeValveStatus' THEN
		UPDATE om_mincut_valve
		SET changestatus =
			CASE
				WHEN changestatus = TRUE THEN FALSE
				WHEN closed = TRUE AND broken = FALSE AND to_arc IS NULL THEN TRUE
				ELSE changestatus
			END
		WHERE node_id = v_valve_node_id
			AND result_id = v_mincut_id;
		GET DIAGNOSTICS v_row_count = ROW_COUNT;

		IF v_row_count = 0 THEN
			-- do nothing because the previous result is exactly the same
			v_init_mincut := FALSE;
			v_prepare_mincut := FALSE;
			v_core_mincut := FALSE;
		ELSE
			IF v_exists IS FALSE THEN
				v_init_mincut := TRUE;
				v_prepare_mincut := FALSE;
			ELSE
				v_init_mincut := FALSE;
				v_prepare_mincut := TRUE;
			END IF;
			v_core_mincut := TRUE;
		END IF;
	ELSIF v_action = 'mincutStart' THEN
		v_message := json_build_object(
			'text', 'Start mincut',
			'level', 3
		);
		IF v_device = 5 THEN
			IF (SELECT mincut_state FROM om_mincut WHERE id = v_mincut_id) IN (v_mincut_plannified_state, v_mincut_on_planning_state) THEN
				UPDATE om_mincut SET mincut_state = 1 WHERE id = v_mincut_id;
			END IF;
			-- Update planning fields if passed
			v_query_text := 'UPDATE om_mincut SET id = id';
			IF (p_data->'data')::jsonb ? 'mincutType' THEN v_query_text := concat(v_query_text, ', mincut_type = ', quote_nullable(v_mincut_type)); END IF;
			IF (p_data->'data')::jsonb ? 'anlCause' THEN v_query_text := concat(v_query_text, ', anl_cause = ', quote_nullable(v_anl_cause)); END IF;
			IF (p_data->'data')::jsonb ? 'anlDescript' THEN v_query_text := concat(v_query_text, ', anl_descript = ', quote_nullable(v_anl_descript)); END IF;
			IF (p_data->'data')::jsonb ? 'forecastStart' THEN v_query_text := concat(v_query_text, ', forecast_start = ', quote_nullable(v_forecast_start)); END IF;
			IF (p_data->'data')::jsonb ? 'forecastEnd' THEN v_query_text := concat(v_query_text, ', forecast_end = ', quote_nullable(v_forecast_end)); END IF;
			IF (p_data->'data')::jsonb ? 'receivedDate' THEN v_query_text := concat(v_query_text, ', received_date = ', quote_nullable(v_received_date)); END IF;
			v_query_text := concat(v_query_text, ' WHERE id = ', v_mincut_id);
			EXECUTE v_query_text;
		END IF;

		IF (SELECT json_extract_path_text(value::json, 'redoOnStart','status')::boolean FROM config_param_system WHERE parameter='om_mincut_settings') is true THEN
			--reexecuting mincut on clicking start
			SELECT json_extract_path_text(value::json, 'redoOnStart','days')::integer INTO v_days FROM config_param_system WHERE parameter='om_mincut_settings';

			IF (SELECT date(anl_tstamp) + v_days FROM om_mincut WHERE id = v_mincut_id) <= date(now()) THEN
				IF v_exists IS FALSE THEN
					v_init_mincut := TRUE;
					v_prepare_mincut := FALSE;
				ELSE
					v_init_mincut := FALSE;
					v_prepare_mincut := TRUE;
				END IF;
				v_core_mincut := TRUE;
			END IF;
		ELSE
			-- do nothing
			IF v_device = 5 THEN
				RETURN gw_fct_getmincut(p_data);
			ELSE
				v_init_mincut := FALSE;
				v_prepare_mincut := FALSE;
				v_core_mincut := FALSE;
			END IF;
		END IF;
	ELSIF v_action IN ('mincutAccept', 'mincutEnd') THEN

		IF v_action = 'mincutAccept' THEN
			UPDATE om_mincut m
			SET expl_id = src.expl_id,
			    macroexpl_id = src.macroexpl_id
			FROM (
				SELECT a.expl_id, e.macroexpl_id
				FROM om_mincut om
				JOIN arc a ON a.arc_id = COALESCE(
					NULLIF(CASE WHEN upper(om.anl_feature_type) = 'ARC' THEN om.anl_feature_id END, NULL),
					(SELECT arc_id FROM arc
					 WHERE the_geom IS NOT NULL AND om.anl_the_geom IS NOT NULL
					 ORDER BY the_geom <-> om.anl_the_geom LIMIT 1)
				)
				JOIN exploitation e ON e.expl_id = a.expl_id
				WHERE om.id = v_mincut_id
				  AND a.expl_id IS NOT NULL
			) src
			WHERE m.id = v_mincut_id;
		END IF;

		-- call setfields
		v_message := json_build_object(
			'text', 'Mincut accepted.',
			'level', 3
		);
		IF v_device = 5 THEN
			IF v_action = 'mincutAccept' THEN
				v_query_text := concat('SELECT gw_fct_setfields($$', p_data, '$$);');
				EXECUTE v_query_text;
				-- Update planning fields if mincutAccept and state = 0 (plannified)
				IF (SELECT mincut_state FROM om_mincut WHERE id = v_mincut_id) = v_mincut_plannified_state THEN
					v_query_text := 'UPDATE om_mincut SET id = id';
					IF (p_data->'data')::jsonb ? 'mincutType' THEN v_query_text := concat(v_query_text, ', mincut_type = ', quote_nullable(v_mincut_type)); END IF;
					IF (p_data->'data')::jsonb ? 'anlCause' THEN v_query_text := concat(v_query_text, ', anl_cause = ', quote_nullable(v_anl_cause)); END IF;
					IF (p_data->'data')::jsonb ? 'anlDescript' THEN v_query_text := concat(v_query_text, ', anl_descript = ', quote_nullable(v_anl_descript)); END IF;
					IF (p_data->'data')::jsonb ? 'forecastStart' THEN v_query_text := concat(v_query_text, ', forecast_start = ', quote_nullable(v_forecast_start)); END IF;
					IF (p_data->'data')::jsonb ? 'forecastEnd' THEN v_query_text := concat(v_query_text, ', forecast_end = ', quote_nullable(v_forecast_end)); END IF;
					IF (p_data->'data')::jsonb ? 'receivedDate' THEN v_query_text := concat(v_query_text, ', received_date = ', quote_nullable(v_received_date)); END IF;
					v_query_text := concat(v_query_text, ' WHERE id = ', v_mincut_id);
					EXECUTE v_query_text;
				-- Update execution fields if mincutAccept and state = 1 (in progress)
				ELSIF (SELECT mincut_state FROM om_mincut WHERE id = v_mincut_id) = v_mincut_in_progress_state THEN
					v_query_text := 'UPDATE om_mincut SET id = id';
					IF (p_data->'data')::jsonb ? 'execStart' THEN v_query_text := concat(v_query_text, ', exec_start = ', quote_nullable(v_exec_start)); END IF;
					IF (p_data->'data')::jsonb ? 'execEnd' THEN v_query_text := concat(v_query_text, ', exec_end = ', quote_nullable(v_exec_end)); END IF;
					IF (p_data->'data')::jsonb ? 'execDescript' THEN v_query_text := concat(v_query_text, ', exec_descript = ', quote_nullable(v_exec_descript)); END IF;
					IF (p_data->'data')::jsonb ? 'execUser' THEN v_query_text := concat(v_query_text, ', exec_user = ', quote_nullable(v_exec_user)); END IF;
					IF (p_data->'data')::jsonb ? 'execFromPlot' THEN v_query_text := concat(v_query_text, ', exec_from_plot = ', quote_nullable(v_exec_from_plot)); END IF;
					IF (p_data->'data')::jsonb ? 'execDepth' THEN v_query_text := concat(v_query_text, ', exec_depth = ', quote_nullable(v_exec_depth)); END IF;
					IF (p_data->'data')::jsonb ? 'execAppropiate' THEN v_query_text := concat(v_query_text, ', exec_appropiate = ', quote_nullable(v_exec_appropiate)); END IF;
					IF (p_data->'data')::jsonb ? 'execTheGeom' THEN v_query_text := concat(v_query_text, ', exec_the_geom = ', quote_nullable(v_exec_the_geom)); END IF;
					v_query_text := concat(v_query_text, ' WHERE id = ', v_mincut_id);
					EXECUTE v_query_text;
				END IF;
				IF (select mincut_state from om_mincut where id = v_mincut_id) = v_mincut_on_planning_state THEN
					UPDATE om_mincut SET mincut_state = v_mincut_plannified_state WHERE id = v_mincut_id;
				END IF;
			ELSIF v_action = 'mincutEnd' THEN
				-- Update execution fields for mincutEnd
				IF (SELECT mincut_state FROM om_mincut WHERE id = v_mincut_id) = v_mincut_in_progress_state THEN
					v_query_text := 'UPDATE om_mincut SET id = id';
					IF (p_data->'data')::jsonb ? 'execStart' THEN v_query_text := concat(v_query_text, ', exec_start = ', quote_nullable(v_exec_start)); END IF;
					IF (p_data->'data')::jsonb ? 'execEnd' THEN v_query_text := concat(v_query_text, ', exec_end = ', quote_nullable(v_exec_end)); END IF;
					IF (p_data->'data')::jsonb ? 'execDescript' THEN v_query_text := concat(v_query_text, ', exec_descript = ', quote_nullable(v_exec_descript)); END IF;
					IF (p_data->'data')::jsonb ? 'execUser' THEN v_query_text := concat(v_query_text, ', exec_user = ', quote_nullable(v_exec_user)); END IF;
					IF (p_data->'data')::jsonb ? 'execFromPlot' THEN v_query_text := concat(v_query_text, ', exec_from_plot = ', quote_nullable(v_exec_from_plot)); END IF;
					IF (p_data->'data')::jsonb ? 'execDepth' THEN v_query_text := concat(v_query_text, ', exec_depth = ', quote_nullable(v_exec_depth)); END IF;
					IF (p_data->'data')::jsonb ? 'execAppropiate' THEN v_query_text := concat(v_query_text, ', exec_appropiate = ', quote_nullable(v_exec_appropiate)); END IF;
					IF (p_data->'data')::jsonb ? 'execTheGeom' THEN v_query_text := concat(v_query_text, ', exec_the_geom = ', quote_nullable(v_exec_the_geom)); END IF;
					v_query_text := concat(v_query_text, ' WHERE id = ', v_mincut_id);
					EXECUTE v_query_text;
					UPDATE om_mincut SET mincut_state = v_mincut_finished_state WHERE id = v_mincut_id;
				END IF;
			END IF;
		END IF;

		-- Manage the selector
		DELETE FROM selector_mincut_result WHERE cur_user = v_cur_user;
		INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
		VALUES (v_mincut_id, current_user, 'current') ON CONFLICT (result_id, cur_user) DO NOTHING;

		SELECT id INTO v_mincut_conflict_group_id FROM om_mincut_conflict WHERE mincut_id = v_mincut_id;

		INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
		SELECT omc.mincut_id, current_user, 'conflict'
		FROM om_mincut_conflict omc
		JOIN om_mincut om ON om.id = omc.mincut_id
		WHERE omc.id = v_mincut_conflict_group_id
		AND omc.mincut_id <> v_mincut_id
		AND om.mincut_state  <> v_mincut_conflict_state
		ON CONFLICT (result_id, cur_user) DO NOTHING;

		INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
		SELECT omc.mincut_id, current_user, 'affected'
		FROM om_mincut_conflict omc
		JOIN om_mincut om ON om.id = omc.mincut_id
		WHERE omc.id = v_mincut_conflict_group_id
		AND omc.mincut_id <> v_mincut_id
		AND om.mincut_state = v_mincut_conflict_state
		ON CONFLICT (result_id, cur_user) DO NOTHING;

		IF v_device = 5 THEN
			RETURN gw_fct_getmincut(p_data);
		END IF;

		SELECT * INTO v_mincut_record FROM om_mincut WHERE id = v_mincut_id;

        DELETE FROM audit_check_data WHERE cur_user = current_user AND fid=216;
		IF v_mincut_conflict_group_id IS NOT NULL THEN
			v_has_overlap := TRUE;

			-- creating log
			SELECT string_agg(result_id::text, ',') INTO v_mincut_affected_ids FROM selector_mincut_result WHERE cur_user = current_user AND result_type = 'affected';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4406", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "parameters":{"state_type":"'||v_mincut_conflict_state||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4422", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "parameters":{"array":"'||v_mincut_affected_ids||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

			-- mincut details
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2000", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4362", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

			-- Stats
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincut_record.output->'arcs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"'||COALESCE((v_mincut_record.output->'arcs'->>'length'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"'||COALESCE((v_mincut_record.output->'arcs'->>'volume'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincut_record.output->'connecs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincut_record.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincut_record.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';


			FOR v_mincut_affected_id IN SELECT result_id FROM selector_mincut_result WHERE cur_user = current_user AND result_type = 'affected' LOOP
				-- mincut extra details
				SELECT * INTO v_mincut_record FROM om_mincut WHERE id = v_mincut_affected_id;
				-- mincut affected details
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2000", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4420", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

				-- Extra details
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4424", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"id":"'||v_mincut_affected_id||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4418", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"array":"'||COALESCE((v_mincut_record.output->'conflicts'->>'array'), '')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4426", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"interval":"'||COALESCE(v_mincut_record.forecast_start::text, '0')||' - '||COALESCE(v_mincut_record.forecast_end::text, '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2007", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

				-- Stats
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincut_record.output->'arcs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"'||COALESCE((v_mincut_record.output->'arcs'->>'length'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"'||COALESCE((v_mincut_record.output->'arcs'->>'volume'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincut_record.output->'connecs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincut_record.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincut_record.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			END LOOP;

		ELSE
			v_has_overlap := FALSE;

			-- mincut details
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4362", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

			-- Stats
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincut_record.output->'arcs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"'||COALESCE((v_mincut_record.output->'arcs'->>'length'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"'||COALESCE((v_mincut_record.output->'arcs'->>'volume'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincut_record.output->'connecs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincut_record.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"2988", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincut_record.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			END IF;

		-- get results
		-- info
		v_result := null;
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM temp_audit_check_data WHERE cur_user = current_user AND fid=216 order by id) row;
		v_result := COALESCE(v_result, '{}');
		v_result_info := concat ('{"values":',v_result, '}');

		-- bbox (the boundary of mincut using arcs and valves)
		SELECT jsonb_build_object(
			'x1', ST_XMin(ST_Extent(st_buffer(the_geom, 20))),
			'y1', ST_YMin(ST_Extent(st_buffer(the_geom, 20))),
			'x2', ST_XMax(ST_Extent(st_buffer(the_geom, 20))),
			'y2', ST_YMax(ST_Extent(st_buffer(the_geom, 20)))
		)
		FROM (
			SELECT the_geom FROM om_mincut_arc WHERE result_id = v_mincut_id
			UNION
			SELECT the_geom FROM om_mincut_valve WHERE result_id = v_mincut_id
		) a
		INTO v_bbox;

		-- Control nulls
		v_result_info := COALESCE(v_result_info, '{}');
		v_bbox := COALESCE(v_bbox, '{}'::jsonb);

		-- Set message based on overlap status
		IF v_has_overlap THEN
			SELECT json_build_object('level', log_level,'text', error_message) -- conflicts
			INTO v_message FROM sys_message WHERE id = 4610;
		ELSE
			SELECT json_build_object('level', log_level,'text', error_message) -- successful
			INTO v_message FROM sys_message WHERE id = 3700;
		END IF;

		-- return
		RETURN gw_fct_json_create_return(
			jsonb_build_object(
				'status', 'Accepted',
				'message', v_message::jsonb,
				'version', v_version,
				'body', jsonb_build_object(
					'form', jsonb_build_object(),
					'feature', jsonb_build_object(),
					'data', jsonb_build_object(
						'info', v_result_info::jsonb,
						'geometry', jsonb_build_object(
							'bbox', v_bbox
						)
					)
				)
			)::json, 2244, null, null, null
		);

	ELSIF v_action = 'mincutCancel' THEN

		SELECT json_build_object('level', log_level,'text', error_message) -- successful
		INTO v_message FROM sys_message WHERE id = 3700;

		IF (SELECT id FROM om_mincut WHERE id = v_mincut_id) IS NOT NULL THEN
			WITH groups_conflict AS (
				SELECT DISTINCT id FROM om_mincut_conflict WHERE mincut_id = v_mincut_id
			),
			mincuts_to_delete AS (
				SELECT omc.mincut_id
				FROM om_mincut_conflict omc
				JOIN om_mincut om ON om.id = omc.mincut_id
				WHERE om.mincut_state = v_mincut_conflict_state
				AND omc.id IN (SELECT id FROM groups_conflict)
			)
			DELETE FROM om_mincut WHERE id IN (SELECT mincut_id FROM mincuts_to_delete);

			WITH groups_conflict AS (
				SELECT DISTINCT id FROM om_mincut_conflict WHERE mincut_id = v_mincut_id
			)
			DELETE FROM om_mincut_conflict
			WHERE id IN (SELECT id FROM groups_conflict);

			IF (SELECT mincut_state FROM om_mincut WHERE id = v_mincut_id) = v_mincut_on_planning_state THEN
				DELETE FROM om_mincut WHERE id = v_mincut_id;
			ELSE
				UPDATE om_mincut SET mincut_state = v_mincut_cancel_state WHERE id = v_mincut_id;
			END IF;
			v_message := json_build_object(
				'text', 'Mincut cancelled.',
				'level', 0
			);

			-- Drop temporary tables if exist
			-- =======================
			v_data := jsonb_build_object(
				'data', jsonb_build_object(
					'action', 'DROP',
					'fct_name', 'MINCUT'
				)
			)::text;
			SELECT gw_fct_graphanalytics_manage_temporary(v_data) INTO v_response;

			IF v_response->>'status' <> 'Accepted' THEN
				RETURN v_response;
			END IF;
		END IF;
		-- manage null values
		v_message := COALESCE(v_message, '{}');

		v_response := json_build_object(
			'status', 'Accepted',
			'message', v_message,
			'version', v_version,
			'body', jsonb_build_object(
				'form', jsonb_build_object(),
				'feature', jsonb_build_object(),
				'data', jsonb_build_object()
			)
		);
		RETURN v_response;
	ELSIF v_action = 'mincutDelete' THEN

		SELECT json_build_object('level', log_level,'text', error_message)
		INTO v_message FROM sys_message WHERE id = 4614;

		IF (SELECT id FROM om_mincut WHERE id = v_mincut_id) IS NOT NULL THEN
			DELETE FROM om_mincut WHERE id = v_mincut_id;

			SELECT json_build_object('level', log_level,'text', error_message)
			INTO v_message FROM sys_message WHERE id = 4616;

		END IF;

		-- manage null values
		v_message := COALESCE(v_message, '{}');

		v_response := json_build_object(
			'status', 'Accepted',
			'message', v_message,
			'version', v_version,
			'body', jsonb_build_object(
				'form', jsonb_build_object(),
				'feature', jsonb_build_object(),
				'data', jsonb_build_object()
			)
		);
		RETURN v_response;
	END IF;

	-- Address auto-fill for network mincut (null-safe):
	-- 1) ve_address (street + number + muni)
	-- 2) ve_streetaxis (street + muni)
	-- 3) mun / v_municipality (muni)
	IF v_action IN ('mincutNetwork', 'mincutRefresh') THEN
	    IF v_point IS NULL THEN
	        SELECT anl_the_geom INTO v_point
	        FROM om_mincut
	        WHERE id = v_mincut_id;
	    END IF;
	    IF v_point IS NOT NULL THEN
	        -- Primary source: nearest address (street name + number + muni)
	        SELECT
	            CASE
	                WHEN a.muni_id::text ~ '^[0-9]+$' THEN a.muni_id::integer
	                ELSE NULL
	            END,
	            NULLIF(trim(COALESCE(sa.name, a.streetaxis_id::text)), ''),
	            NULLIF(trim(a.postnumber), '')
	        INTO v_muni_id, v_street_name, v_postnumber
	        FROM ve_address a
	        LEFT JOIN ve_streetaxis sa ON sa.id = a.streetaxis_id
	        ORDER BY a.the_geom <-> v_point
	        LIMIT 1;
	        v_has_address_match := FOUND;
	        -- Fallback: nearest streetaxis (name + muni)
	        IF v_street_name IS NULL OR v_muni_id IS NULL THEN
	            SELECT
	                COALESCE(v_muni_id, s.muni_id),
	                COALESCE(v_street_name, NULLIF(trim(s.name), ''))
	            INTO v_muni_id, v_street_name
	            FROM ve_streetaxis s
	            ORDER BY s.the_geom <-> v_point
	            LIMIT 1;
	        END IF;
	        -- Municipality fallback from mun table, if present
	        IF v_muni_id IS NULL AND to_regclass('mun') IS NOT NULL THEN
	            EXECUTE 'SELECT muni_id FROM mun WHERE ST_Intersects(the_geom, $1) ORDER BY ST_Area(the_geom) ASC LIMIT 1'
	            INTO v_muni_id
	            USING v_point;
	            IF v_muni_id IS NULL THEN
	                EXECUTE 'SELECT muni_id FROM mun ORDER BY the_geom <-> $1 LIMIT 1'
	                INTO v_muni_id
	                USING v_point;
	            END IF;
	        END IF;
	        -- Final municipality fallback from view
	        IF v_muni_id IS NULL AND to_regclass('v_municipality') IS NOT NULL THEN
	            SELECT m.muni_id
	            INTO v_muni_id
	            FROM v_municipality m
	            WHERE m.active IS TRUE
	              AND ST_Intersects(m.the_geom, v_point)
	            ORDER BY ST_Area(m.the_geom) ASC
	            LIMIT 1;
	            IF v_muni_id IS NULL THEN
	                SELECT m.muni_id
	                INTO v_muni_id
	                FROM v_municipality m
	                WHERE m.active IS TRUE
	                ORDER BY m.the_geom <-> v_point
	                LIMIT 1;
	            END IF;
	        END IF;
	        UPDATE om_mincut
	        SET muni_id       = COALESCE(v_muni_id, om_mincut.muni_id),
	            streetaxis_id = COALESCE(v_street_name, om_mincut.streetaxis_id),
	            postnumber    = CASE
	                WHEN v_has_address_match THEN COALESCE(v_postnumber, om_mincut.postnumber)
	                ELSE om_mincut.postnumber
	            END
	        WHERE id = v_mincut_id;
	    END IF;
	END IF;

	-- CORE MINCUT CODE
	IF v_init_mincut THEN
		-- Initialize process
		-- =======================
		IF v_mode = 'MINSECTOR' THEN
			TRUNCATE temp_pgr_node_minsector;
			TRUNCATE temp_pgr_arc_linegraph;

			-- insert MINSECTOR nodes
			SELECT count(*)::float FROM  minsector_graph INTO v_pgr_distance;
			v_query_text := '
				SELECT node_id AS id, minsector_1 AS source, minsector_2 AS target, 1 AS cost
            	FROM minsector_graph
			';
			INSERT INTO temp_pgr_node_minsector (pgr_node_id, graph_delimiter)
			SELECT node, 'MINSECTOR'
			FROM pgr_drivingdistance(v_query_text, v_minsector_id, v_pgr_distance, directed => false);

			-- NODES graph_delimiter = 'SECTOR'
			-- MINSECTORS that contain an arc that connects to a node SECTOR-WATER and is not inlet_arc
			-- TANK, SOURCE, WATERWELL, WTP
			WITH
				water AS (
					SELECT node_id, inlet_arc FROM man_tank
					UNION ALL
					SELECT node_id, inlet_arc FROM man_source
					UNION ALL
					SELECT node_id, inlet_arc FROM man_waterwell
					UNION ALL
					SELECT node_id, inlet_arc FROM man_wtp
				),
				sector_water AS (
					SELECT w.node_id, w.inlet_arc
					FROM water w
					JOIN v_temp_node n USING (node_id)
					WHERE 'SECTOR' = ANY (n.graph_delimiter)
				)
			UPDATE temp_pgr_node_minsector t
			SET graph_delimiter = 'SECTOR'
			WHERE EXISTS (
				SELECT 1
				FROM v_temp_arc a
			  	LEFT JOIN sector_water s1 ON a.node_1 = s1.node_id
			  	LEFT JOIN sector_water s2 ON a.node_2 = s2.node_id
			  	WHERE t.pgr_node_id = a.minsector_id
			    AND (
			      (s1.node_id IS NOT NULL AND a.arc_id <> ALL(COALESCE(s1.inlet_arc,ARRAY[]::int[])))
			      OR
			      (s2.node_id IS NOT NULL AND a.arc_id <> ALL(COALESCE(s2.inlet_arc,ARRAY[]::int[])))
			    )
			);

			-- temp_pgr_arc is not used

			-- insert the valves as arcs;
			-- the table that is used: temp_pgr_arc_linegraph where pgr_node_id is the valve and pgr_node_1/pgr_node_2 are the connected minsectors
			INSERT INTO temp_pgr_arc_linegraph (pgr_node_id, pgr_node_1, pgr_node_2, graph_delimiter, cost, reverse_cost, cost_mincut, reverse_cost_mincut)
			SELECT a.node_id, a.minsector_1, a.minsector_2, 'MINSECTOR', 1, 1, -1, -1
			FROM minsector_graph a
			WHERE EXISTS (SELECT 1 FROM temp_pgr_node_minsector n WHERE n.pgr_node_id = a.minsector_1)
			AND EXISTS (SELECT 1 FROM temp_pgr_node_minsector n WHERE n.pgr_node_id = a.minsector_2);

		ELSE
			-- START ALGORITHM GENERATE MINSECTORS
			TRUNCATE temp_pgr_node;
			TRUNCATE temp_pgr_arc;
			TRUNCATE temp_pgr_node_minsector;
			TRUNCATE temp_pgr_arc_linegraph;

			IF v_node = 0 THEN

				-- arc is in between 2 nodes SECTOR, insert it in temp_pgr_arc
				INSERT INTO temp_pgr_arc (pgr_arc_id, pgr_node_1, pgr_node_2)
				SELECT a.arc_id, a.node_1, a.node_2
				FROM v_temp_arc a
				WHERE a.arc_id = v_arc_id;

			ELSE

				-- insert nodes (the graph is without water sources that are SECTOR)
				SELECT count(*)::float FROM  v_temp_arc INTO v_pgr_distance;

				v_query_text := '
					WITH
						water AS (
							SELECT node_id FROM man_tank
							UNION ALL
							SELECT node_id FROM man_source
							UNION ALL
							SELECT node_id FROM man_waterwell
							UNION ALL
							SELECT node_id FROM man_wtp
						),
						sector_water AS (
							SELECT w.node_id
							FROM water w
							JOIN v_temp_node n USING (node_id)
							WHERE ''SECTOR'' = ANY (n.graph_delimiter)
						)
					SELECT
						arc_id AS id,
						node_1 AS source,
						node_2 AS target,
						1 AS cost
					FROM v_temp_arc a
					WHERE NOT EXISTS (SELECT 1 FROM sector_water s WHERE s.node_id = a.node_1)
					AND NOT EXISTS (SELECT 1 FROM sector_water s WHERE s.node_id = a.node_2)
				';
				INSERT INTO temp_pgr_node (pgr_node_id)
				SELECT node
				FROM pgr_drivingdistance(v_query_text, v_node, v_pgr_distance, directed => false);

				-- nodes that are valve MINSECTOR
				UPDATE temp_pgr_node t
				SET graph_delimiter = 'MINSECTOR'
				FROM v_temp_node n
				JOIN man_valve m ON n.node_id = m.node_id
				WHERE t.pgr_node_id = n.node_id
				AND 'MINSECTOR' = ANY (n.graph_delimiter);

				-- insert arcs (including the arcs that would be connected to the SECTOR nodes)
				INSERT INTO temp_pgr_arc (pgr_arc_id, pgr_node_1, pgr_node_2)
				SELECT a.arc_id, a.node_1, a.node_2
				FROM v_temp_arc a
				WHERE EXISTS (SELECT 1 FROM temp_pgr_node n WHERE n.pgr_node_id = a.node_1)
				OR EXISTS (SELECT 1 FROM temp_pgr_node n WHERE n.pgr_node_id = a.node_2);

			END IF;

			-- set arcs connected to WATER SECTOR (TANKS, SOURCE, WATERWELL, WTP):
			--   - 'INLET'  -> if the arc is an inlet_arc
			--   - 'SECTOR' -> otherwise
			WITH
				water AS (
					SELECT node_id, inlet_arc FROM man_tank
					UNION ALL
					SELECT node_id, inlet_arc FROM man_source
					UNION ALL
					SELECT node_id, inlet_arc FROM man_waterwell
					UNION ALL
					SELECT node_id, inlet_arc FROM man_wtp
				),
				sector_water AS (
					SELECT w.node_id, w.inlet_arc
					FROM water w
					JOIN v_temp_node n USING (node_id)
					WHERE 'SECTOR' = ANY (n.graph_delimiter)
				)
			UPDATE temp_pgr_arc a
			SET graph_delimiter =
			CASE
				WHEN EXISTS (
					SELECT 1
					FROM sector_water s
					WHERE (s.node_id = a.pgr_node_1 OR s.node_id = a.pgr_node_2)
					AND a.pgr_arc_id = ANY (COALESCE(s.inlet_arc, ARRAY[]::int[]))
				)
				THEN 'INLET'
				ELSE 'SECTOR'
			END
			WHERE EXISTS (
				SELECT 1
				FROM sector_water s
				WHERE (s.node_id = a.pgr_node_1 OR s.node_id = a.pgr_node_2)
			);

			-- generate lineGraph (pgr_node_1 and pgr_node_2 are arc_id)
			v_query_text :=
			'SELECT pgr_arc_id AS id, pgr_node_1 AS source, pgr_node_2 AS target, 1 AS cost
			FROM temp_pgr_arc';

			INSERT INTO temp_pgr_arc_linegraph (
				pgr_arc_id, pgr_node_1, pgr_node_2, cost_mincut, reverse_cost_mincut
			)
			SELECT seq, source, target, cost, -1
			FROM pgr_linegraph(
				v_query_text,
				directed => FALSE
			);

			-- Propagate original node_id for valves (MINSECTOR) to the linegraph and tag them in graph_delimiter
			--checking node_1 for arc_1
			UPDATE temp_pgr_arc_linegraph t
			SET pgr_node_id = n.pgr_node_id,
				graph_delimiter = n.graph_delimiter,
				cost_mincut = -1
			FROM temp_pgr_arc_linegraph ta
			JOIN temp_pgr_arc a1 ON ta.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON ta.pgr_node_2 = a2.pgr_arc_id
			JOIN temp_pgr_node n ON a1.pgr_node_1 = n.pgr_node_id
			WHERE n.graph_delimiter = 'MINSECTOR'
			AND a1.pgr_node_1 IN (a2.pgr_node_1, a2.pgr_node_2)
			AND ta.pgr_arc_id = t.pgr_arc_id;

			--checking node_2 for arc_1
			UPDATE temp_pgr_arc_linegraph t
			SET pgr_node_id = n.pgr_node_id,
				graph_delimiter = n.graph_delimiter,
				cost_mincut = -1
			FROM temp_pgr_arc_linegraph ta
			JOIN temp_pgr_arc a1 ON ta.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON ta.pgr_node_2 = a2.pgr_arc_id
			JOIN temp_pgr_node n ON a1.pgr_node_2 = n.pgr_node_id
			WHERE n.graph_delimiter = 'MINSECTOR'
			AND a1.pgr_node_2 IN (a2.pgr_node_1, a2.pgr_node_2)
			AND ta.pgr_arc_id = t.pgr_arc_id;

			-- force cost_mincut = -1 for adjacent 'SECTOR'/'INLET' arcs to limit the mincut network;
			-- water sources always act as network boundaries
			UPDATE temp_pgr_arc_linegraph t
			SET graph_delimiter = 'SECTOR',
				cost_mincut = -1
			FROM temp_pgr_arc_linegraph ta
			JOIN temp_pgr_arc a1 ON ta.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON ta.pgr_node_2 = a2.pgr_arc_id
			WHERE a1.graph_delimiter IN ('INLET', 'SECTOR')
			AND  a2.graph_delimiter IN ('INLET', 'SECTOR')
			AND t.pgr_arc_id = ta.pgr_arc_id;

			-- Generate the minsectors
			--------------------------

			PERFORM 1 FROM temp_pgr_arc_linegraph LIMIT 1;

			IF NOT FOUND THEN
				-- there is just one arc in temp_pgr_arc (mapzone_id = arc_id)
				UPDATE temp_pgr_arc
				SET mapzone_id = pgr_arc_id
				WHERE mapzone_id = 0;
        	ELSE
				v_query_text :=
				'SELECT pgr_arc_id AS id, pgr_node_1 AS source, pgr_node_2 AS target, cost_mincut as cost
				FROM temp_pgr_arc_linegraph';

				TRUNCATE temp_pgr_connectedcomponents;
				INSERT INTO temp_pgr_connectedcomponents(seq, component, node)
				SELECT seq, component, node FROM pgr_connectedcomponents(v_query_text);

				-- Update the mapzone_id field for arcs (mapzone_id = min(arc_id) for the connected arcs)
				UPDATE temp_pgr_arc a
				SET mapzone_id = c.component
				FROM temp_pgr_connectedcomponents c
				WHERE a.pgr_arc_id = c.node;

				-- update mapzone_id for arcs that have node_1 and node_2 graph_delimiters
				UPDATE temp_pgr_arc
				SET mapzone_id = pgr_arc_id
				WHERE mapzone_id = 0;

			END IF;

			-- set v_minsector_id
			v_minsector_id := (SELECT mapzone_id FROM temp_pgr_arc WHERE pgr_arc_id = v_arc_id);

			-- END ALGORITHM GENERATE MINSECTORS

			-- Initialize tables for mincut
			-- tables used: temp_pgr_node_minsector (nodes) and temp_pgr_arc_linegraph (arcs)
			------------------------------

			-- fill temp_pgr_node_minsector
			INSERT INTO temp_pgr_node_minsector (pgr_node_id, graph_delimiter)
			SELECT DISTINCT mapzone_id, 'MINSECTOR'
			FROM temp_pgr_arc;

			-- remove line that are not 'MINSECTOR'
			DELETE FROM temp_pgr_arc_linegraph
			WHERE graph_delimiter <> 'MINSECTOR';

			UPDATE temp_pgr_arc_linegraph l
			SET pgr_node_1 = s.minsector_1,
				pgr_node_2 = s.minsector_2
			FROM (
			SELECT lg.pgr_arc_id,
					a1.mapzone_id AS minsector_1,
					a2.mapzone_id AS minsector_2
			FROM temp_pgr_arc_linegraph lg
			JOIN temp_pgr_arc a1 ON lg.pgr_node_1 = a1.pgr_arc_id
			JOIN temp_pgr_arc a2 ON lg.pgr_node_2 = a2.pgr_arc_id
			) s
			WHERE l.pgr_arc_id = s.pgr_arc_id;

			-- remove MINSECTORS with a1.mapzone_id = a2.mapzone_id (keep the valves that are border for minsectors)
			DELETE FROM temp_pgr_arc_linegraph
			WHERE pgr_node_1 = pgr_node_2;

			-- NODES graph_delimiter as 'SECTOR'
			 -- MINSECTORS that contain an arc that connects to a water source and is not inlet_arc WILL BE A WATER SOURCE
			UPDATE temp_pgr_node_minsector t
			SET graph_delimiter = 'SECTOR'
			WHERE EXISTS (
				SELECT 1 FROM temp_pgr_arc a
				WHERE a.graph_delimiter = 'SECTOR'
				AND a.mapzone_id = t.pgr_node_id
			);

		END IF;

		-- update aditional fields for valves (MINSECTOR)
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
		SET cost = -1, reverse_cost = -1
		WHERE t.graph_delimiter = 'MINSECTOR'
		AND t.closed = TRUE;

		-- check valves (compare minsector of to_arc with pgr_node_2 because pgr_node_2 is a minsector)
		IF v_mode = 'MINSECTOR' THEN
			UPDATE temp_pgr_arc_linegraph t
			SET cost = CASE WHEN a.minsector_id = t.pgr_node_2 THEN 1 ELSE -1 END,
				reverse_cost = CASE WHEN a.minsector_id = t.pgr_node_2 THEN -1 ELSE 1 END
			FROM arc a
			WHERE t.graph_delimiter = 'MINSECTOR'
			AND t.closed = FALSE
			AND t.to_arc IS NOT NULL
			AND a.arc_id = t.to_arc;
		ELSE
			UPDATE temp_pgr_arc_linegraph t
			SET cost = CASE WHEN a.mapzone_id = t.pgr_node_2 THEN 1 ELSE -1 END,
				reverse_cost = CASE WHEN a.mapzone_id = t.pgr_node_2 THEN -1 ELSE 1 END
			FROM temp_pgr_arc a
			WHERE t.graph_delimiter = 'MINSECTOR'
			AND t.closed = FALSE
			AND t.to_arc IS NOT NULL
			AND a.pgr_arc_id = t.to_arc;
		END IF;

		-- update cost/reverse for the broken open checkvalves (behave as open valves)
		UPDATE temp_pgr_arc_linegraph t
		SET cost = 1, reverse_cost = 1
		WHERE cost <> reverse_cost
		AND t.broken = TRUE;

		-- update cost_mincut/reverse_cost_mincut (open broken valves cannot be manipulated)
		UPDATE temp_pgr_arc_linegraph t
		SET cost_mincut = 1, reverse_cost_mincut = 1
		WHERE t.closed = FALSE
		AND t.broken = TRUE;

		-- update cost_mincut/reverse_cost_mincut (depending of ignore check_valves)
		IF v_ignore_check_valves THEN
            UPDATE temp_pgr_arc_linegraph t
            SET cost_mincut = 1, reverse_cost_mincut = 1
            WHERE cost <> reverse_cost;
        ELSE
            UPDATE temp_pgr_arc_linegraph t
            SET cost_mincut = cost, reverse_cost_mincut = reverse_cost
            WHERE cost <> reverse_cost;
        END IF;

		-- Update cost_mincut / reverse_cost_mincut when the valve no longer exists
		-- this can occur in v_mode = 'MINSECTOR' if the valve was substituted or became obsolete after the minsectors were calculated
		UPDATE temp_pgr_arc_linegraph t
		SET cost_mincut = 1, reverse_cost_mincut = 1
		WHERE t.closed IS NULL;

	END IF;

	IF v_prepare_mincut THEN
		-- prepare mincut
		UPDATE temp_pgr_node_minsector
		SET mapzone_id = 0
		WHERE mapzone_id <> 0;

		UPDATE temp_pgr_arc_linegraph
		SET mapzone_id = 0
		WHERE mapzone_id <> 0;

		-- set the default values for proposed valves for current mincut (adjacent_mincut_id = 0) and adjacents mincuts, if they exist (adjacent_mincut_id <> 0)
		UPDATE temp_pgr_arc_linegraph
		SET proposed = FALSE
		WHERE proposed = TRUE
		AND adjacent_mincut_id = 0;

		UPDATE temp_pgr_arc_linegraph
		SET proposed = FALSE,
			cost = 1,
			reverse_cost = 1,
			adjacent_mincut_id = 0
		WHERE proposed = TRUE
		AND adjacent_mincut_id <> 0;

		-- set the default values for unaccess valves for current mincut,
		-- the unaccess valves of the adjacent valves are not taken into account
		UPDATE temp_pgr_arc_linegraph
		SET unaccess = FALSE,
			cost_mincut = -1,
			reverse_cost_mincut = -1
		WHERE unaccess = TRUE;

		-- set the default values for changestatus valves
		--for current mincut (adjacent_mincut_id = 0)
		-- and adjacent mincuts, if they exist (adjacent_mincut_id <> 0)
		UPDATE temp_pgr_arc_linegraph
		SET changestatus = FALSE,
			cost = -1,
			reverse_cost = -1,
			adjacent_mincut_id = 0
		WHERE changestatus = TRUE;

	END IF;

	IF v_core_mincut THEN

		-- update unaccess valves
		UPDATE temp_pgr_arc_linegraph tpa
		SET unaccess = TRUE,
			cost_mincut = 1,
			reverse_cost_mincut = 1
		FROM om_mincut_valve omv
		WHERE omv.result_id = v_mincut_id
		AND omv.unaccess = TRUE
		AND omv.node_id = tpa.pgr_node_id
		AND tpa.graph_delimiter = 'MINSECTOR';

		-- update changestatus valves (temporary open the closed valves that belong to the mincut)
		UPDATE temp_pgr_arc_linegraph tpa
		SET changestatus = TRUE,
			cost = 1,
			reverse_cost = 1
		FROM om_mincut_valve omv
		WHERE omv.result_id = v_mincut_id
		AND omv.node_id = tpa.pgr_node_id
		AND omv.changestatus = TRUE
		AND tpa.closed = TRUE
		AND tpa.broken = FALSE
		AND tpa.to_arc IS NULL
		AND tpa.graph_delimiter = 'MINSECTOR';

		-- mincut
		---------

		SELECT count(*)::float INTO v_pgr_distance FROM temp_pgr_arc_linegraph;

		IF v_pgr_distance = 0 THEN
			-- the choosen arc is isolated
			UPDATE temp_pgr_node_minsector SET mapzone_id = 1;
		ELSE
			-- Use jsonb_build_object for cleaner and safer JSON construction
			v_data := jsonb_build_object(
				'data', jsonb_build_object(
					'pgrDistance', v_pgr_distance,
					'pgrRootVids', ARRAY[v_minsector_id],
					'ignoreCheckValvesMincut', v_ignore_check_valves,
					'mode', v_mode
				)
			)::text;
			v_response := gw_fct_mincut_core(v_data);

			IF v_response->>'status' <> 'Accepted' THEN
				RETURN v_response;
			END IF;
		END IF;

		-- include in the mincut the valves with changestatus TRUE that are out of the mincut
		UPDATE temp_pgr_arc_linegraph tpa
		SET mapzone_id = v_mincut_id
		WHERE tpa.mapzone_id = 0
		AND tpa.changestatus = TRUE;

		-- if a valve with changestatus = TRUE is proposed, remove changestatus and also proposed
		UPDATE temp_pgr_arc_linegraph tpa
		SET changestatus = FALSE,
			proposed = FALSE,
			cost = -1,
			reverse_cost = -1
		WHERE tpa.changestatus = TRUE
		AND tpa.proposed = TRUE;

		-- delete this rows, and for the mincut conflict delete it in the om_mincut table. CASCADE.
		DELETE FROM om_mincut_node where result_id=v_mincut_id;
		DELETE FROM om_mincut_arc where result_id=v_mincut_id;
		DELETE FROM om_mincut_connec where result_id=v_mincut_id;
		DELETE FROM om_mincut_hydrometer where result_id=v_mincut_id;
		DELETE FROM om_mincut_valve where result_id=v_mincut_id;

		DELETE FROM selector_mincut_result WHERE cur_user = current_user;

		WITH groups_conflict AS (
			SELECT DISTINCT id FROM om_mincut_conflict WHERE mincut_id = v_mincut_id
		),
		mincuts_to_delete AS (
			SELECT omc.mincut_id
			FROM om_mincut_conflict omc
			JOIN om_mincut om ON om.id = omc.mincut_id
			WHERE om.mincut_state = v_mincut_conflict_state
			AND omc.id IN (SELECT id FROM groups_conflict)
		)
		DELETE FROM om_mincut WHERE id IN (SELECT mincut_id FROM mincuts_to_delete);


		WITH groups_conflict AS (
			SELECT DISTINCT id FROM om_mincut_conflict WHERE mincut_id = v_mincut_id
		)
		DELETE FROM om_mincut_conflict
		WHERE id IN (SELECT id FROM groups_conflict);

		-- insert the arcs, nodes and valves for the mincut
		IF v_mode = 'MINSECTOR' THEN
			-- insert arcs
			INSERT INTO om_mincut_arc (result_id, arc_id, the_geom)
			SELECT v_mincut_id, a.arc_id, a.the_geom
			FROM temp_pgr_node_minsector m
			JOIN v_temp_arc a ON a.minsector_id = m.pgr_node_id
			WHERE m.mapzone_id <> 0;

			-- insert nodes
			INSERT INTO om_mincut_node (result_id, node_id, the_geom, node_type)
			SELECT v_mincut_id, n.node_id, n.the_geom, n.node_type
			FROM temp_pgr_node_minsector m
			JOIN v_temp_node n ON n.minsector_id = m.pgr_node_id
			WHERE m.mapzone_id <> 0;

		ELSE
			-- insert arcs
			INSERT INTO om_mincut_arc (result_id, arc_id, the_geom)
			SELECT v_mincut_id, a.arc_id, a.the_geom
			FROM temp_pgr_node_minsector m
			JOIN temp_pgr_arc tpa ON tpa.mapzone_id = m.pgr_node_id
			JOIN arc a ON a.arc_id = tpa.pgr_arc_id
			WHERE m.mapzone_id <> 0;

			-- insert nodes
			INSERT INTO om_mincut_node (result_id, node_id, the_geom, node_type)
			SELECT v_mincut_id, n.node_id, n.the_geom, cn.node_type
			FROM temp_pgr_node_minsector m
			JOIN temp_pgr_node tpn ON tpn.mapzone_id = m.pgr_node_id
			JOIN node n ON n.node_id = tpn.pgr_node_id
			JOIN cat_node cn ON n.nodecat_id = cn.id
			WHERE m.mapzone_id <> 0;

		END IF;

		-- insert valves
		INSERT INTO om_mincut_valve (
			result_id,
			node_id,
			closed,
			broken,
			unaccess,
			changestatus,
			proposed,
			the_geom,
			to_arc
		)
		SELECT DISTINCT ON (tpa.pgr_node_id)
			v_mincut_id,
			tpa.pgr_node_id AS node_id,
			tpa.closed,
			tpa.broken,
			tpa.unaccess,
			tpa.changestatus,
			tpa.proposed,
			n.the_geom,
			tpa.to_arc
		FROM temp_pgr_arc_linegraph tpa
		JOIN node n ON n.node_id = tpa.pgr_node_id
		WHERE tpa.mapzone_id <> 0
		ORDER BY tpa.pgr_node_id;

		INSERT INTO om_mincut_connec (result_id, connec_id, the_geom, customer_code)
		SELECT v_mincut_id, c.connec_id, c.the_geom, c.customer_code
		FROM om_mincut_arc oma
		JOIN v_temp_connec vtc ON vtc.arc_id = oma.arc_id
		JOIN connec c ON c.connec_id = vtc.connec_id
		WHERE oma.result_id = v_mincut_id;

		IF v_update_map_zone = 0 THEN
			-- do nothing

		ELSIF  v_update_map_zone = 1 THEN

			-- concave polygon
			v_query_text := '
				UPDATE om_mincut m SET polygon_the_geom = ST_Multi(a.the_geom)
				FROM (
					WITH polygon AS (
						SELECT ST_Collect(a.the_geom) AS g
						FROM om_mincut_arc a
						WHERE result_id = '||v_mincut_id||'
					)
					SELECT
					CASE WHEN ST_GeometryType(ST_ConcaveHull(g, '||v_concave_hull||')) = ''ST_Polygon''::text THEN
						ST_Buffer(ST_ConcaveHull(g, '||v_concave_hull||'), 2)::geometry(Polygon,'||(v_srid)||')
						ELSE ST_Expand(ST_Buffer(g, 3::double precision), 1::double precision)::geometry(Polygon,'||(v_srid)||')
						END AS the_geom
					FROM polygon
					)a
				WHERE m.id = '||v_mincut_id||';';
			EXECUTE v_query_text;

		ELSIF  v_update_map_zone = 2 THEN

			-- pipe buffer
			v_query_text := '
				UPDATE om_mincut m SET polygon_the_geom = the_geom
				FROM (
					SELECT ST_Multi(ST_Buffer(ST_Collect(a.the_geom),'||v_geom_param_update||')) AS the_geom
					FROM om_mincut_arc a
					WHERE result_id = '||v_mincut_id||'
				) a
				WHERE m.id = '||v_mincut_id||';';
			EXECUTE v_query_text;

		ELSIF  v_update_map_zone = 3 THEN

			-- use plot and pipe buffer
			v_query_text := '
				UPDATE om_mincut m SET polygon_the_geom = the_geom FROM (
					SELECT ST_Multi(ST_Buffer(ST_Collect(the_geom),0.01)) AS the_geom FROM (
						SELECT ST_Buffer(ST_Collect(a.the_geom), '||v_geom_param_update||') AS the_geom
						FROM om_mincut_arc a
						WHERE result_id = '||v_mincut_id||'
						UNION
						SELECT ST_Collect(ep.the_geom) AS the_geom
						FROM om_mincut_connec co
						JOIN connec c ON c.connec_id = co.connec_id
						LEFT JOIN v_plot ep ON c.plot_id = ep.id
							AND ST_DWithin(c.the_geom, ep.the_geom, 0.001)
						WHERE a.result_id = '||v_mincut_id||'
					) a
				) b
				WHERE m.id = '||v_mincut_id||';';
			EXECUTE v_query_text;

		ELSIF  v_update_map_zone = 4 THEN

			v_geom_param_update_divide := v_geom_param_update / 2;

			-- use link and pipe buffer
			v_query_text := '
				UPDATE om_mincut m SET polygon_the_geom = the_geom FROM (
					SELECT ST_Multi(ST_Buffer(ST_Collect(c.the_geom),0.01)) AS the_geom FROM (
						SELECT ST_Buffer(ST_Collect(a.the_geom), '||v_geom_param_update||') AS the_geom
						FROM om_mincut_arc a
						WHERE result_id = '||v_mincut_id||'
						UNION
						SELECT (ST_Buffer(ST_Collect(l.the_geom),'||v_geom_param_update_divide||',''endcap=flat join=round'')) AS the_geom
						FROM om_mincut_arc a
						JOIN link l ON a.arc_id = l.exit_id
						WHERE l.exit_type = ''ARC''
						AND a.result_id = '||v_mincut_id||'
					) c
				) b
				WHERE m.id = '||v_mincut_id||';';

			EXECUTE v_query_text;
		END IF;

		-- insert hydrometer from connec
		WITH states as (
			SELECT (json_array_elements_text((value::json->>'1')::json))::INTEGER as state_id
			FROM config_param_system
			WHERE parameter  = 'admin_hydrometer_state'
		)
		INSERT INTO om_mincut_hydrometer (result_id, hydrometer_id)
		SELECT v_mincut_id, erh.hydrometer_id
		FROM v_hydrometer erh
		JOIN connec c ON erh.feature_customer_code = c.customer_code
		WHERE erh.state_id IN (SELECT state_id FROM states)
		AND EXISTS (
			SELECT 1
			FROM om_mincut_connec omc
			WHERE omc.connec_id = c.connec_id
			AND omc.result_id = v_mincut_id
		);

		-- insert hydrometer from node
		WITH states as (
			SELECT (json_array_elements_text((value::json->>'1')::json))::INTEGER as state_id
			FROM config_param_system
			WHERE parameter  = 'admin_hydrometer_state'
		)
		INSERT INTO om_mincut_hydrometer (result_id, hydrometer_id)
		SELECT v_mincut_id, erh.hydrometer_id
		FROM v_hydrometer erh
		JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code
		JOIN node n ON n.node_id = mn.node_id
		WHERE erh.state_id IN (SELECT state_id FROM states)
		AND EXISTS (
			SELECT 1
			FROM om_mincut_node omn
			WHERE omn.node_id = n.node_id
			AND omn.result_id = v_mincut_id
		);

		-- fill connnec & hydrometer details on om_mincut.output
		-- count arcs
		SELECT count(arc_id), sum(ST_Length(the_geom))::numeric(12,2) INTO v_num_arcs, v_length
		FROM om_mincut_arc
		WHERE result_id = v_mincut_id;

		SELECT sum(pi() * (ca.dint * ca.dint / 4_000_000) * ST_Length(oma.the_geom))::numeric(12,2)
		INTO v_volume
		FROM om_mincut_arc oma
		JOIN arc a ON oma.arc_id = a.arc_id
		JOIN cat_arc ca ON a.arccat_id = ca.id
		WHERE oma.result_id = v_mincut_id;

		-- count valves
		SELECT count(node_id) INTO v_num_valve_proposed
		FROM om_mincut_valve
		WHERE result_id = v_mincut_id
			AND proposed IS TRUE;

		SELECT count(node_id) INTO v_num_valve_closed
		FROM om_mincut_valve
		WHERE result_id = v_mincut_id
			AND closed IS TRUE AND changestatus = FALSE;

		-- count connec
		SELECT count(connec_id) INTO v_num_connecs
		FROM om_mincut_connec
		WHERE result_id = v_mincut_id;

		-- count hydrometers
		SELECT count(*) INTO v_num_hydrometer
		FROM om_mincut_hydrometer
		WHERE result_id = v_mincut_id;

		-- priority hydrometers
		v_priority := (
			SELECT array_to_json(array_agg(b))
			FROM (
				SELECT
					json_build_object(
						'category', hc.observ,
						'number', count(omh.hydrometer_id)
					) AS b
				FROM om_mincut_hydrometer omh
				JOIN vf_hydrometer h ON h.hydrometer_id = omh.hydrometer_id
				LEFT JOIN v_cat_hydrometer_category hc ON hc.id::text = h.category_id::text
				WHERE omh.result_id = v_mincut_id
				GROUP BY hc.observ
				ORDER BY hc.observ
			) a
		);

		IF v_priority IS NULL THEN v_priority := '{}'; END IF;
		v_count_unselected_psectors := COALESCE(v_count_unselected_psectors, 0);


		v_mincut_details := json_build_object(
			'arcs', json_build_object(
				'number', v_num_arcs,
				'length', v_length,
				'volume', v_volume
			),
			'connecs', json_build_object(
				'number', v_num_connecs,
				'hydrometers', json_build_object(
					'total', v_num_hydrometer,
					'classified', v_priority
				)
			),
			'valve', json_build_object(
				'proposed', v_num_valve_proposed,
				'closed', v_num_valve_closed
			)
		);

		--update output results
		UPDATE om_mincut SET output = v_mincut_details WHERE id = v_mincut_id;


		-- calculate the bbox of mincut using arcs and valves
		SELECT jsonb_build_object(
			'x1', ST_XMin(ST_Extent(st_buffer(the_geom, 20))),
			'y1', ST_YMin(ST_Extent(st_buffer(the_geom, 20))),
			'x2', ST_XMax(ST_Extent(st_buffer(the_geom, 20))),
			'y2', ST_YMax(ST_Extent(st_buffer(the_geom, 20)))
		)
		FROM (
			SELECT the_geom FROM om_mincut_arc WHERE result_id = v_mincut_id
			UNION
			SELECT the_geom FROM om_mincut_valve WHERE result_id = v_mincut_id
		) a
		INTO v_bbox;

		-- FIRST MINCUT FINISHED

		IF v_forecast_start IS NOT NULL AND v_forecast_end IS NOT NULL THEN

			v_query_text := format($fmt$
				WITH mincut_conflicts AS (
					SELECT o.id, o.anl_feature_type, o.anl_feature_id,
						tsrange(o.forecast_start, o.forecast_end, '[]') * tsrange(%L, %L, '[]') AS seg_mincut
					FROM om_mincut o
					JOIN om_mincut_cat_type c ON o.mincut_type = c.id
					WHERE o.mincut_state IN (%s, %s)
						AND o.mincut_class = %s
						AND c.virtual = FALSE
						AND o.forecast_start <= o.forecast_end
						AND tsrange(o.forecast_start, o.forecast_end, '[]') && tsrange(%L, %L, '[]')
						AND o.id <> %s
				),
				mincut_times AS (
					-- put togther all the limits of all the intervals for mincuts in conflict
					SELECT LOWER(seg_mincut) AS forecast_date
					FROM mincut_conflicts
					UNION
					SELECT UPPER(seg_mincut) AS forecast_date
					FROM mincut_conflicts
				),
				mincut_times_before AS (
					-- generate the previous limit time
					SELECT
						LAG(forecast_date) OVER (ORDER BY forecast_date) AS forecast_date_before,
						forecast_date
					FROM mincut_times
				),
				mincut_segments AS (
					-- create all the atomic intervals of all the intervals [prev, actual)
					SELECT
						tsrange(forecast_date_before, forecast_date, '()') AS seg
					FROM mincut_times_before
					WHERE forecast_date_before IS NOT NULL
				),
				mincut_covers AS (
					-- for every segment, group the ids
					SELECT *
					FROM mincut_conflicts m
					JOIN mincut_segments s ON m.seg_mincut && s.seg
				),
				mincut_groups AS (
					SELECT seg, array_agg(DISTINCT id ORDER BY id) AS mincut_group
					FROM mincut_covers
					GROUP BY seg
				)
				SELECT g.seg, g.mincut_group
				FROM mincut_groups g
				WHERE NOT EXISTS (
					SELECT 1 FROM mincut_groups g1
					WHERE g.mincut_group <@ g1.mincut_group
					AND g.mincut_group <> g1.mincut_group
				);
			$fmt$,
			v_forecast_start, v_forecast_end,
			v_mincut_plannified_state, v_mincut_in_progress_state,
			v_mincut_network_class,
			v_forecast_start, v_forecast_end,
			v_mincut_id
			);

			FOR v_mincut_group_record IN EXECUTE v_query_text LOOP

				-- prepare mincut
				UPDATE temp_pgr_node_minsector
				SET mapzone_id = 0
				WHERE mapzone_id <> 0;

				UPDATE temp_pgr_arc_linegraph
				SET mapzone_id = 0
				WHERE mapzone_id <> 0;

				-- set the default values for proposed valves
				-- for current mincut (adjacent_mincut_id = 0)
				UPDATE temp_pgr_arc_linegraph
				SET proposed = FALSE
				WHERE proposed = TRUE
				AND adjacent_mincut_id = 0;

				-- set the default values for proposed valves
				-- for adjacents mincuts, if they exist (adjacent_mincut_id <> 0)
				UPDATE temp_pgr_arc_linegraph
				SET proposed = FALSE,
					cost = 1,
					reverse_cost = 1,
					adjacent_mincut_id = 0
				WHERE proposed = TRUE
				AND adjacent_mincut_id <> 0;

				-- set the default values for changestatus valves
				-- for adjacent mincuts, if they exist (adjacent_mincut_id <> 0)
				UPDATE temp_pgr_arc_linegraph
				SET changestatus = FALSE,
					cost = -1,
					reverse_cost = -1,
					adjacent_mincut_id = 0
				WHERE changestatus = TRUE
				AND adjacent_mincut_id <> 0;

				EXECUTE format('
					UPDATE temp_pgr_arc_linegraph tpa
					SET changestatus = omv.changestatus, cost = 1, reverse_cost = 1, adjacent_mincut_id = omv.result_id
					FROM om_mincut_valve omv
					WHERE omv.result_id = ANY(%L)
						AND omv.node_id = tpa.pgr_node_id
						AND omv.changestatus = TRUE
						AND tpa.closed = TRUE AND tpa.broken = FALSE AND tpa.to_arc IS NULL
						AND tpa.graph_delimiter = ''MINSECTOR'';
				', v_mincut_group_record.mincut_group);

				EXECUTE format('
					UPDATE temp_pgr_arc_linegraph tpa
					SET proposed = omv.proposed, cost = -1, reverse_cost = -1, adjacent_mincut_id = omv.result_id
					FROM om_mincut_valve omv
					WHERE omv.result_id = ANY(%L)
						AND omv.proposed = TRUE
						AND omv.node_id = tpa.pgr_node_id
						AND tpa.graph_delimiter = ''MINSECTOR'';
				', v_mincut_group_record.mincut_group);

				GET DIAGNOSTICS v_row_count = ROW_COUNT;

				IF v_row_count = 0 THEN
					continue;
				END IF;

				v_data := jsonb_build_object(
					'data', jsonb_build_object(
						'pgrDistance', v_pgr_distance,
						'pgrRootVids', ARRAY[v_minsector_id],
						'ignoreCheckValvesMincut', v_ignore_check_valves,
						'mode', v_mode
					)
				)::text;

				v_response := gw_fct_mincut_core(v_data);

				IF v_response->>'status' <> 'Accepted' THEN
					RETURN v_response;
				END IF;

				IF v_mode = 'MINSECTOR' THEN
					EXECUTE format('
						SELECT count(*)
						FROM temp_pgr_node_minsector tpn
						WHERE tpn.mapzone_id <> 0
						AND NOT EXISTS (
							SELECT 1
							FROM om_mincut_arc oma
							JOIN v_temp_arc a ON oma.arc_id = a.arc_id
							WHERE (oma.result_id = %L OR oma.result_id = ANY(%L))
								AND a.minsector_id = tpn.pgr_node_id
						);
					', v_mincut_id, v_mincut_group_record.mincut_group) INTO v_arc_count;
				ELSE
					EXECUTE format('
						SELECT count(*)
						FROM temp_pgr_node_minsector tpn
						WHERE tpn.mapzone_id <> 0
						AND NOT EXISTS (
							SELECT 1
							FROM om_mincut_arc oma
							JOIN temp_pgr_arc tpa ON oma.arc_id = tpa.pgr_arc_id
							WHERE (oma.result_id = %L OR oma.result_id = ANY(%L))
								AND tpa.mapzone_id = tpn.pgr_node_id
						);
					', v_mincut_id, v_mincut_group_record.mincut_group) INTO v_arc_count;
				END IF;

				IF v_arc_count > 0 THEN
					v_has_overlap := TRUE;

					IF v_mode = 'MINSECTOR' THEN
						v_query_text := format($fmt$
							SELECT tpa.pgr_arc_id AS id, tpa.pgr_node_1 AS source, tpa.pgr_node_2 AS target, 1 as cost
							FROM temp_pgr_arc_linegraph tpa
							WHERE tpa.mapzone_id <> 0
							AND (
								NOT EXISTS (
									SELECT 1
									FROM v_temp_arc a
									JOIN om_mincut_arc oma ON oma.arc_id = a.arc_id
									WHERE oma.result_id = %L
									AND a.minsector_id = tpa.pgr_node_1
								)
								OR
								NOT EXISTS (
									SELECT 1
									FROM v_temp_arc a
									JOIN om_mincut_arc oma ON oma.arc_id = a.arc_id
									WHERE oma.result_id = %L
									AND a.minsector_id = tpa.pgr_node_2
								)
							)
						$fmt$, v_mincut_id, v_mincut_id);
					ELSE
						v_query_text := format($fmt$
							SELECT tpa.pgr_arc_id AS id, tpa.pgr_node_1 AS source, tpa.pgr_node_2 AS target, 1 as cost
							FROM temp_pgr_arc_linegraph tpa
							WHERE tpa.mapzone_id <> 0
							AND (
								NOT EXISTS (
									SELECT 1
									FROM temp_pgr_arc a
									JOIN om_mincut_arc oma ON oma.arc_id = a.pgr_arc_id
									WHERE oma.result_id = %L
									AND a.mapzone_id = tpa.pgr_node_1
								)
								OR
								NOT EXISTS (
									SELECT 1
									FROM temp_pgr_arc a
									JOIN om_mincut_arc oma ON oma.arc_id = a.pgr_arc_id
									WHERE oma.result_id = %L
									AND a.mapzone_id = tpa.pgr_node_2
								)
							)
						$fmt$, v_mincut_id, v_mincut_id);
					END IF;

					TRUNCATE temp_pgr_connectedcomponents;
					INSERT INTO temp_pgr_connectedcomponents (seq, component, node)
					SELECT seq, component, node FROM pgr_connectedcomponents(v_query_text);

					v_query_text :='
						SELECT DISTINCT component
						FROM temp_pgr_connectedcomponents
					';

					FOR v_mincut_conflict_record IN EXECUTE v_query_text LOOP
						-- create the new mincut virtual: [onPlanning and Conflict]
						INSERT INTO om_mincut (mincut_class, mincut_state)
						VALUES (v_mincut_network_class, v_mincut_conflict_state)
						RETURNING id INTO v_mincut_affected_id;

						IF v_mode = 'MINSECTOR' THEN
							-- insert arcs
							EXECUTE format('
								INSERT INTO om_mincut_arc (result_id, arc_id, the_geom)
								SELECT %L, a.arc_id, a.the_geom
								FROM temp_pgr_node_minsector tpn
								JOIN v_temp_arc a ON a.minsector_id = tpn.pgr_node_id
								WHERE tpn.mapzone_id <> 0
								AND EXISTS (
									SELECT 1
									FROM temp_pgr_connectedcomponents c
									WHERE c.node = tpn.pgr_node_id
									AND c.component = %L
								)
								AND NOT EXISTS (
									SELECT 1
									FROM v_temp_arc a
									JOIN om_mincut_arc oma ON oma.arc_id = a.arc_id
									WHERE oma.result_id = %L
									AND a.minsector_id = tpn.pgr_node_id
								)
							', v_mincut_affected_id, v_mincut_conflict_record.component, v_mincut_id);

							-- insert nodes
							EXECUTE format('
								INSERT INTO om_mincut_node (result_id, node_id, node_type, the_geom)
								SELECT %L, n.node_id, n.node_type, n.the_geom
								FROM temp_pgr_node_minsector tpn
								JOIN v_temp_node n ON n.minsector_id = tpn.pgr_node_id
								WHERE tpn.mapzone_id <> 0
								AND EXISTS (
									SELECT 1
									FROM temp_pgr_connectedcomponents c
									WHERE c.node = tpn.pgr_node_id
									AND c.component = %L
								)
								AND NOT EXISTS (
									SELECT 1
									FROM v_temp_node n
									JOIN om_mincut_node omn ON omn.node_id = n.node_id
									WHERE omn.result_id = %L
									AND n.minsector_id = tpn.pgr_node_id
								);
							', v_mincut_affected_id, v_mincut_conflict_record.component, v_mincut_id);

						ELSE
							-- insert arcs
							EXECUTE format('
								INSERT INTO om_mincut_arc (result_id, arc_id, the_geom)
								SELECT %L, a.arc_id, a.the_geom
								FROM temp_pgr_node_minsector tpn
								JOIN temp_pgr_arc tpa ON tpa.mapzone_id = tpn.pgr_node_id
								JOIN arc a ON a.arc_id = tpa.pgr_arc_id
								WHERE tpn.mapzone_id <> 0
								AND EXISTS (
									SELECT 1
									FROM temp_pgr_connectedcomponents c
									WHERE c.node = tpn.pgr_node_id
									AND c.component = %L
								)
								AND NOT EXISTS (
									SELECT 1
									FROM temp_pgr_arc a
									JOIN om_mincut_arc oma ON oma.arc_id = a.pgr_arc_id
									WHERE oma.result_id = %L
									AND a.mapzone_id = tpn.pgr_node_id
								)
							', v_mincut_affected_id, v_mincut_conflict_record.component, v_mincut_id);

							-- insert nodes
							EXECUTE format('
								INSERT INTO om_mincut_node (result_id, node_id, node_type, the_geom)
								SELECT %L, n.node_id, cn.node_type, n.the_geom
								FROM temp_pgr_node_minsector tpn
								JOIN temp_pgr_node tn ON tn.mapzone_id = tpn.pgr_node_id
								JOIN node n ON n.node_id = tn.pgr_node_id
								JOIN cat_node cn ON n.nodecat_id = cn.id
								WHERE tpn.mapzone_id <> 0
								AND EXISTS (
									SELECT 1
									FROM temp_pgr_connectedcomponents c
									WHERE c.node = tpn.pgr_node_id
									AND c.component = %L
								)
								AND NOT EXISTS (
									SELECT 1
									FROM temp_pgr_node n
									JOIN om_mincut_node omn ON omn.node_id = n.pgr_node_id
									WHERE omn.result_id = %L
									AND n.mapzone_id = tpn.pgr_node_id
								);
							', v_mincut_affected_id, v_mincut_conflict_record.component, v_mincut_id);

						END IF;

						-- insert valves
						EXECUTE format('
							INSERT INTO om_mincut_valve (
								result_id,
								node_id,
								closed,
								broken,
								unaccess,
								changestatus,
								proposed,
								the_geom,
								to_arc
							)
							SELECT %L,
								tpa.pgr_node_id AS node_id,
								tpa.closed,
								tpa.broken,
								tpa.unaccess,
								tpa.changestatus,
								tpa.proposed,
								n.the_geom,
								tpa.to_arc
							FROM temp_pgr_arc_linegraph tpa
							JOIN node n ON n.node_id = tpa.pgr_node_id
							WHERE tpa.mapzone_id <> 0
							AND EXISTS (
								SELECT 1
								FROM temp_pgr_connectedcomponents c
								WHERE c.node = tpa.pgr_node_1
								AND c.component = %L
							)
							AND EXISTS (
								SELECT 1
								FROM temp_pgr_connectedcomponents c
								WHERE c.node = tpa.pgr_node_2
									AND c.component = %L
							)
							AND NOT EXISTS (
								SELECT 1
								FROM om_mincut_valve om
								WHERE (
										om.result_id = %L OR om.result_id = ANY(%L)
									)
								AND om.node_id = tpa.pgr_node_id
							);',
							v_mincut_affected_id,
							v_mincut_conflict_record.component,
							v_mincut_conflict_record.component,
							v_mincut_id, v_mincut_group_record.mincut_group);

						INSERT INTO om_mincut_connec (result_id, connec_id, the_geom, customer_code)
                        SELECT v_mincut_affected_id, vtc.connec_id, vtc.the_geom, vtc.customer_code
                        FROM om_mincut_arc oma
                        JOIN v_temp_connec vtc ON vtc.arc_id = oma.arc_id
                        WHERE oma.result_id = v_mincut_affected_id;

						-- insert hydrometer from connec
						WITH states as (
							SELECT (json_array_elements_text((value::json->>'1')::json))::INTEGER as state_id
							FROM config_param_system
							WHERE parameter  = 'admin_hydrometer_state'
						)
						INSERT INTO om_mincut_hydrometer (result_id, hydrometer_id)
						SELECT v_mincut_affected_id, erh.hydrometer_id
						FROM v_hydrometer erh
						JOIN connec c ON erh.feature_customer_code = c.customer_code
						WHERE erh.state_id IN (SELECT state_id FROM states)
						AND EXISTS (
							SELECT 1
							FROM om_mincut_connec omc
							WHERE omc.connec_id = c.connec_id
							AND omc.result_id = v_mincut_affected_id
						);

						-- insert hydrometer from node
						WITH states as (
							SELECT (json_array_elements_text((value::json->>'1')::json))::INTEGER as state_id
							FROM config_param_system
							WHERE parameter  = 'admin_hydrometer_state'
						)
						INSERT INTO om_mincut_hydrometer (result_id, hydrometer_id)
						SELECT v_mincut_affected_id, erh.hydrometer_id
						FROM v_hydrometer erh
						JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code
						JOIN node n ON n.node_id = mn.node_id
						WHERE erh.state_id IN (SELECT state_id FROM states)
						AND EXISTS (
							SELECT 1
							FROM om_mincut_node omn
							WHERE omn.node_id = n.node_id
							AND omn.result_id = v_mincut_affected_id
						);

						v_mincut_conflict_group_id := gen_random_uuid();

						-- insert affected zone mincut first
						INSERT INTO om_mincut_conflict (id, mincut_id)
						VALUES (v_mincut_conflict_group_id, v_mincut_affected_id);

						-- insert original mincut
						INSERT INTO om_mincut_conflict (id, mincut_id)
						VALUES (v_mincut_conflict_group_id, v_mincut_id);

						-- insert conflict mincuts
						EXECUTE format('
							WITH mincuts_conflicts AS (
								SELECT DISTINCT om.result_id
								FROM temp_pgr_arc_linegraph a
								JOIN om_mincut_valve om ON om.node_id = a.pgr_node_id
									AND om.result_id = ANY(%L)
								WHERE a.mapzone_id <> 0
									AND EXISTS (
										SELECT 1
										FROM temp_pgr_connectedcomponents c
										WHERE c.node = a.pgr_node_1
											AND c.component = %L
										)
									AND EXISTS (
										SELECT 1
										FROM temp_pgr_connectedcomponents c
										WHERE c.node = a.pgr_node_2
											AND c.component = %L
										)
							)
							INSERT INTO om_mincut_conflict (id, mincut_id)
							SELECT %L, m.result_id
							FROM mincuts_conflicts m;
						', v_mincut_group_record.mincut_group,
						v_mincut_conflict_record.component, v_mincut_conflict_record.component,
						v_mincut_conflict_group_id::uuid);

						-- update forecast_start and forecast_end for the affected zone mincut
						WITH forecast_time AS (
							SELECT
								GREATEST(MAX (forecast_start),v_forecast_start)  AS forecast_start,
								LEAST(MIN (forecast_end), v_forecast_end) AS forecast_end
							FROM om_mincut om
							WHERE EXISTS (
								SELECT 1 FROM om_mincut_conflict omc
								WHERE omc.id = v_mincut_conflict_group_id
								AND omc.mincut_id <> v_mincut_affected_id
								AND omc.mincut_id <> v_mincut_id
								AND omc.mincut_id = om.id
							)
						)
						UPDATE om_mincut om SET
							forecast_start = ft.forecast_start,
							forecast_end = ft.forecast_end
						FROM forecast_time ft
						WHERE om.id = v_mincut_affected_id;

						-- fill connnec & hydrometer details on om_mincut.output
						-- count arcs
						SELECT count(arc_id), sum(ST_Length(the_geom))::numeric(12,2) INTO v_num_arcs, v_length
						FROM om_mincut_arc
						WHERE result_id = v_mincut_affected_id;

						SELECT sum(pi() * (ca.dint * ca.dint / 4_000_000) * ST_Length(oma.the_geom))::numeric(12,2) INTO v_volume
						FROM om_mincut_arc oma
						JOIN arc a ON oma.arc_id = a.arc_id
						JOIN cat_arc ca ON a.arccat_id = ca.id
						WHERE oma.result_id = v_mincut_affected_id;

						-- count valves
						SELECT count(node_id) INTO v_num_valve_proposed
						FROM om_mincut_valve
						WHERE result_id = v_mincut_affected_id
						AND proposed IS TRUE;

						SELECT count(node_id) INTO v_num_valve_closed
						FROM om_mincut_valve
						WHERE result_id = v_mincut_affected_id
						AND closed IS TRUE AND changestatus IS FALSE;

						-- count connec
						SELECT count(connec_id) INTO v_num_connecs
						FROM om_mincut_connec
						WHERE result_id = v_mincut_affected_id;

						-- count hydrometers
						SELECT count(*) INTO v_num_hydrometer
						FROM om_mincut_hydrometer
						WHERE result_id = v_mincut_affected_id;

						-- priority hydrometers
						v_priority := (
							SELECT array_to_json(array_agg(b))
							FROM (
								SELECT
									json_build_object(
										'category', hc.observ,
										'number', count(omh.hydrometer_id)
									) AS b
								FROM om_mincut_hydrometer omh
								JOIN vf_hydrometer h ON h.hydrometer_id = omh.hydrometer_id
								LEFT JOIN v_cat_hydrometer_category hc ON hc.id::text = h.category_id::text
								WHERE omh.result_id = v_mincut_affected_id
								GROUP BY hc.observ
								ORDER BY hc.observ
							) a
						);

						-- mincut conflict array
						SELECT count(*), string_agg(omc.mincut_id::text, ',' ORDER BY omc.mincut_id)
						INTO v_mincut_conflict_count, v_mincut_conflict_array
						FROM om_mincut_conflict omc
						WHERE omc.id = v_mincut_conflict_group_id
						AND omc.mincut_id <> v_mincut_id
						AND omc.mincut_id <> v_mincut_affected_id;

						IF v_priority IS NULL THEN v_priority := '{}'; END IF;
						v_count_unselected_psectors := COALESCE(v_count_unselected_psectors, 0);

						v_mincut_details := json_build_object(
							'arcs', json_build_object(
								'number', v_num_arcs,
								'length', v_length,
								'volume', v_volume
							),
							'connecs', json_build_object(
								'number', v_num_connecs,
								'hydrometers', json_build_object(
									'total', v_num_hydrometer,
									'classified', v_priority
								)
							),
							'valve', json_build_object(
								'proposed', v_num_valve_proposed,
								'closed', v_num_valve_closed
							),
							'conflicts', json_build_object(
								'number', v_mincut_conflict_count,
								'array', v_mincut_conflict_array
							)
						);
						UPDATE om_mincut SET output = v_mincut_details WHERE id = v_mincut_affected_id;

						-- insert selector mincut result
						INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
						VALUES (v_mincut_affected_id, current_user, 'affected') ON CONFLICT (result_id, cur_user) DO NOTHING;

						INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
						SELECT omc.mincut_id, current_user, 'conflict'
						FROM om_mincut_conflict omc
						WHERE omc.id = v_mincut_conflict_group_id
						AND omc.mincut_id <> v_mincut_id
						AND omc.mincut_id <> v_mincut_affected_id
						ON CONFLICT (result_id, cur_user) DO NOTHING;

					END LOOP;

				ELSE
					v_has_overlap := FALSE;
				END IF;

			END LOOP;

		END IF;
		-- select current mincut
		INSERT INTO selector_mincut_result (result_id, cur_user, result_type)
		VALUES (v_mincut_id, current_user, 'current') ON CONFLICT (result_id, cur_user) DO NOTHING;
	END IF;

	-- Check if arcs of the mincut are in exploitations that I don't have permissions to see with cat manager.
	-- using selectors to see if the are conflicts with other exploitations...
	SELECT EXISTS (
		SELECT 1
		FROM om_mincut_arc oma
		JOIN arc a ON oma.arc_id = a.arc_id
		WHERE EXISTS (
			SELECT 1
			FROM selector_mincut_result smr
			WHERE smr.result_id = oma.result_id
			AND smr.cur_user = current_user
		)
		AND a.expl_id > 0
		AND NOT EXISTS (
			SELECT 1
			FROM vf_exploitation vfe
			WHERE vfe.expl_id = a.expl_id
		)
	) INTO v_has_other_exploitations;

	IF v_has_other_exploitations THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4638", "function":"2980","parameters":null, "is_process":true}}$$)';
	END IF;
	-- END CORE MINCUT CODE


	-- build geojson
	IF v_device = 5 THEN
		RETURN gw_fct_getmincut(p_data);
	END IF;

	-- Set message based on overlap status
	IF v_has_overlap THEN
		SELECT json_build_object('level', log_level,'text', error_message) -- conflicts
		INTO v_message FROM sys_message WHERE id = 4610;
	ELSE
		v_message := COALESCE(v_message, '{}');
	END IF;

	v_response := ('{
	    "status": "Accepted",
        "message": ' || v_message || ',
	    "version": "' || v_version || '",
	    "body": {
	      "form": {},
	      "feature": {},
	      "data": {
	        "mincutId": ' || v_mincut_id ||'
	      }
	    }
	}');
	RETURN v_response;

	--  Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

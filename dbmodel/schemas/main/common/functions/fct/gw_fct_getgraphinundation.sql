/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- SELECT SCHEMA_NAME.gw_fct_getgraphinundation($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"mapzone":"SECTOR"}}}$$);
-- SELECT SCHEMA_NAME.gw_fct_getgraphinundation($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"mapzone":"DMA"}}}$$);
-- SELECT SCHEMA_NAME.gw_fct_getgraphinundation($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"mapzone":"PRESSZONE"}}}$$);
-- SELECT SCHEMA_NAME.gw_fct_getgraphinundation($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"mapzone":"DQA"}}}$$);



--FUNCTION CODE: 3338

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getgraphinundation(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getgraphinundation(p_data json)
  RETURNS json AS
$BODY$

DECLARE
	v_version text;
	v_mapzone text;
	v_mapzone_field text;
	v_selected_arc_id integer;
	v_fid integer = 710;
	v_layername text = 'Graphanalytics tstep process';
	v_tablename text = 'v_anl_graphinundation';
	v_error_context text;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_mapzone := (p_data->'data'->'parameters'->>'mapzone')::text;
	v_selected_arc_id := (p_data->'data'->'parameters'->>'selected_arc_id')::integer;
	v_mapzone_field := lower(v_mapzone) || '_id';

	-- Replace previous inundation result for current user
	DELETE FROM anl_graphinundation WHERE cur_user = CURRENT_USER::text;

	EXECUTE format($sql$
		INSERT INTO anl_graphinundation (
			fid, mapzone, arc_id, start_vid, node_1, node_2, arc_type, arccat_id,
			state, state_type, is_operative, mapzone_id, old_mapzone_id, descript, timestep, the_geom
		)
		SELECT
			$2,
			$3,
			a.arc_id,
			d.start_vid,
			a.node_1,
			a.node_2,
			ca.arc_type,
			a.arccat_id,
			a.state,
			a.state_type,
			v.is_operative,
			array_to_string(m.mapzone_ids, ','),
			(a.%I)::text,
			m.name,
			(date_trunc('day', now()) + (d.agg_cost + 1) * interval '1 second')::timestamp,
			a.the_geom
		FROM temp_pgr_arc ta
		JOIN temp_pgr_drivingdistance d ON ta.pgr_arc_id = d.node
		JOIN arc a ON a.arc_id = ta.pgr_arc_id
		JOIN cat_arc ca ON ca.id = a.arccat_id
		JOIN value_state_type v ON v.id = a.state_type
		JOIN temp_pgr_mapzone m ON m.component = ta.component
		WHERE m.mapzone_ids IN (
			SELECT m2.mapzone_ids
			FROM temp_pgr_arc ta2
			JOIN temp_pgr_mapzone m2 ON m2.component = ta2.component
			WHERE ta2.pgr_arc_id = $1 OR $1 IS NULL
		)
	$sql$, v_mapzone_field)
	USING v_selected_arc_id, v_fid, upper(v_mapzone);

	RETURN gw_fct_json_create_return((
		'{"status":"Accepted",
		"message":{
			"level":1,
			"text":"Process done successfully"
		},
		"version":"' || v_version || '",
		"body":{
			"form":{},
			"data":{
				"layerName":"' || v_layername || '",
				"tableName":"' || v_tablename || '",
				"fid":' || v_fid || '
			}
		}
	}'
	)::json, 3338, null, null, null);

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

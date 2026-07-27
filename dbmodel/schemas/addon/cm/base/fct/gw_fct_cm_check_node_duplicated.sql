/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- DROP FUNCTION cm.gw_fct_cm_check_node_duplicated(json);

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_check_node_duplicated(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE


SELECT gw_fct_cm_check_node_duplicated($${"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{},"data":{"parameters":{"nodeId":1}}}$$);

*/

DECLARE

-- Init params
v_version text;
v_srid integer;

v_lot_id integer;
v_campaign_id integer;

-- Vars

v_sql_result TEXT;
v_count int = 0;
v_tolerance NUMERIC = 0;
v_lot_id_array integer[];

-- Return
v_result json;
v_result_info json;
v_result_point json;



BEGIN

    SET search_path = "PARENT_SCHEMA","cm", public;

	-- Init params
	SELECT giswater, epsg INTO v_version, v_srid FROM sys_version ORDER BY id DESC LIMIT 1;
   
	v_campaign_id := (p_data ->'data' ->'parameters'->>'campaignId')::integer;
   	v_lot_id := (p_data ->'data' ->'parameters'->>'lotId')::integer;
   	v_tolerance := (p_data ->'data' ->'parameters'->>'searchTolerance')::numeric;

	IF v_lot_id IS NULL THEN
		SELECT array_agg(lot_id) INTO v_lot_id_array FROM cm.om_campaign_lot WHERE status IN (3,4,6) AND campaign_id = v_campaign_id GROUP BY campaign_id;
	ELSE
		v_lot_id_array := array[v_lot_id];
	END IF;

	CREATE TEMP TABLE IF NOT EXISTS t_audit_check_data (LIKE audit_check_data INCLUDING ALL);

	-- Query for orphan nodes
   	v_sql_result := format(
    'WITH mec AS (
		SELECT node_id, nodecat_id, the_geom FROM cm.om_campaign_x_node a
		JOIN cm.om_campaign_lot_x_node b USING (node_id) 
		WHERE the_geom IS NOT NULL AND lot_id IN (%s)
	)
	SELECT a.node_id, a.nodecat_id, string_agg(b.node_id::text, '','') AS node_id_duplicated, a.the_geom
	FROM mec a LEFT JOIN mec b ON st_dwithin(a.the_geom, b.the_geom, %L) 
	WHERE a.node_id != b.node_id
	GROUP BY a.node_id, a.nodecat_id, a.the_geom
	ORDER BY a.nodecat_id',
	array_to_string(v_lot_id_array, ','),
	v_tolerance
    );

   	EXECUTE 'select count(*) from ('||v_sql_result||')' INTO v_count;
   
   	-- Report results
   	INSERT INTO t_audit_check_data (fid, criticity, error_message)
	SELECT 999, 1, concat('Hay ', v_count, ' nodos duplicados en el lote ', array_to_string(v_lot_id_array, ','), '.');

   	-- Return results
	-- temporal table for nodes
	execute FORMAT(
		'SELECT jsonb_build_object(
		    ''type'', ''FeatureCollection'',
		    ''features'', COALESCE(jsonb_agg(features.feature), ''[]''::jsonb)
		)
		FROM (
		  	SELECT jsonb_build_object(
		     ''type'',       ''Feature'',
		    ''geometry'',   ST_AsGeoJSON(the_geom)::jsonb,
		    ''properties'', to_jsonb(row) - ''the_geom''
		  	) AS feature
		  	FROM (%s) row) features',
		  	v_sql_result
	) INTO v_result;
	v_result_point := COALESCE(v_result, '{}');
	
   
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM t_audit_check_data WHERE fid = 999) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');


	DROP TABLE IF EXISTS t_audit_check_data;

	--    Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');

	--  Return
	RETURN PARENT_SCHEMA.gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||
			'}}'||
	    '}')::json, 2110, null, null, null);
   
END;
$function$
;

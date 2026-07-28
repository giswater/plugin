/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2914

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_anl_node_proximity(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_anl_node_proximity(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_anl_node_proximity($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{"tableName":"ve_node_junction", "id":["1004","1005"]},
"data":{"selectionMode":"previousSelection",
  "parameters":{"nodeProximity":3, "saveOnDatabase":true}}}$$)

-- fid: 132

*/

DECLARE

v_id json;
v_selectionmode text;
v_nodeproximity	float;
v_saveondatabase boolean;
v_worklayer text;
v_result json;
v_result_info json;
v_result_point json;
v_array text;
v_error_context text;
 v_version text;

BEGIN

    -- Search path
    SET search_path = "SCHEMA_NAME", public;


  -- SELECT giswater
  SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

    -- getting input data
    v_id :=  ((p_data ->>'feature')::json->>'id')::json;
    v_worklayer := ((p_data ->>'feature')::json->>'tableName')::text;
    v_selectionmode :=  ((p_data ->>'data')::json->>'selectionMode')::text;
	 v_saveondatabase :=  (((p_data ->>'data')::json->>'parameters')::json->>'saveOnDatabase')::boolean;
    v_nodeproximity := ((p_data ->>'data')::json->>'parameters')::json->>'nodeProximity';

    select string_agg(quote_literal(a),',') into v_array from json_array_elements_text(v_id) a;

    -- Reset values
    DELETE FROM anl_node WHERE cur_user="current_user"() AND fid=132;


  -- Computing process
  IF v_selectionmode = 'previousSelection' THEN
    EXECUTE 'INSERT INTO anl_node (node_id, nodecat_id, state, node_id_aux, nodecat_id_aux, state_aux, expl_id, fid, the_geom)
        SELECT * FROM (
        SELECT DISTINCT t1.node_id, t1.nodecat_id, t1.state as state1, t2.node_id, t2.nodecat_id, t2.state as state2, t1.expl_id, 132, t1.the_geom
        FROM '||v_worklayer||' AS t1 JOIN '||v_worklayer||' AS t2 ON ST_Dwithin(t1.the_geom, t2.the_geom,('||v_nodeproximity||')) 
        WHERE t1.node_id != t2.node_id AND t1.node_id IN ('||v_array||') ORDER BY t1.node_id ) a where a.state1 > 0 AND a.state2 > 0';
  ELSE
    EXECUTE 'INSERT INTO anl_node (node_id, nodecat_id, state, node_id_aux, nodecat_id_aux, state_aux, expl_id, fid, the_geom)
        SELECT * FROM (
        SELECT DISTINCT t1.node_id, t1.nodecat_id, t1.state as state1, t2.node_id, t2.nodecat_id, t2.state as state2, t1.expl_id, 132, t1.the_geom
        FROM '||v_worklayer||' AS t1 JOIN '||v_worklayer||' AS t2 ON ST_Dwithin(t1.the_geom, t2.the_geom,('||v_nodeproximity||')) 
        WHERE t1.node_id != t2.node_id ORDER BY t1.node_id ) a where a.state1 > 0 AND a.state2 > 0';
  END IF;


  	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=132 order by id) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	--points
v_result = null;
  SELECT jsonb_build_object(
      'type', 'FeatureCollection',
      'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
  ) INTO v_result
  FROM (
    SELECT jsonb_build_object(
     'type',       'Feature',
    'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
    'properties', to_jsonb(row) - 'the_geom'
    ) AS feature
    FROM (SELECT id, node_id, nodecat_id, state, expl_id, descript,fid, ST_Transform(the_geom, 4326) as the_geom
    FROM  anl_node WHERE cur_user="current_user"() AND fid=132) row) features;

  v_result_point := COALESCE(v_result, '{}');

	IF v_saveondatabase IS FALSE THEN
		-- delete previous results
		DELETE FROM anl_node WHERE cur_user="current_user"() AND fid=132;
	ELSE
		-- set selector
		DELETE FROM selector_audit WHERE fid=132 AND cur_user=current_user;
		INSERT INTO selector_audit (fid,cur_user) VALUES (132, current_user);
	END IF;


	--    Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');

	--  Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||
			'}}'||
	    '}')::json, 2914, null, null, null);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

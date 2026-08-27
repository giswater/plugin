/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3012

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_mincut_connec(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_mincut_connec(p_data json)
RETURNS json AS
$BODY$

/*

SELECT gw_fct_setmincut('{"data":{"mincutClass":3, "mincutId":"3"}}');

fid = 216

*/

DECLARE

v_id integer;
v_mincut integer;
v_numconnecs integer;
v_numhydrometer integer;
v_priority json;
v_mincutdetails json;
v_mincut_class integer;
v_version text;
v_error_context text;
v_expl integer;
v_macroexpl integer;
v_mincutrec record;
v_result json;
v_result_info json;
v_connec_id integer;
v_geom geometry;


BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;
	
	SELECT giswater INTO v_version FROM sys_version order by id desc limit 1;

	-- delete previous
	DELETE FROM audit_check_data WHERE fid = 216 and cur_user=current_user;

	-- get input parameters
	v_mincut := ((p_data ->>'data')::json->>'mincutId')::integer;	
	v_mincut_class := ((p_data ->>'data')::json->>'mincutClass')::integer;	
	
	-- get connecs when mincut class = 3
	IF v_mincut_class=3 THEN
		INSERT INTO om_mincut_connec (result_id, connec_id) 
		SELECT DISTINCT ON (connec_id) result_id, connec_id FROM v_hydrometer erh JOIN connec c ON erh.feature_customer_code = c.customer_code JOIN om_mincut_hydrometer USING (hydrometer_id) 
		WHERE result_id = v_mincut ON CONFLICT (result_id, connec_id) DO NOTHING;
	ELSIF v_mincut_class=2 THEN
		UPDATE om_mincut_connec m SET the_geom=c.the_geom, customer_code=c.customer_code FROM connec c 
		WHERE c.connec_id=m.connec_id AND result_id = v_mincut;
	END IF;
    
	-- fill anl_feature_type, anl_the_geom and anl_feature_id (even for multiple connec mincut, get one random connec_id and geom)
	IF v_mincut_class=2 THEN
		SELECT connec_id, c.the_geom INTO v_connec_id, v_geom FROM connec c JOIN om_mincut_connec USING (connec_id) 
		WHERE result_id=v_mincut LIMIT 1;
	
		UPDATE om_mincut SET anl_feature_type='CONNEC', anl_feature_id=v_connec_id, anl_the_geom=v_geom 
		WHERE om_mincut.id=v_mincut;
	END IF;

	-- update om_mincut table
	v_expl = (SELECT expl_id FROM om_mincut_connec JOIN connec USING (connec_id) WHERE result_id=v_mincut LIMIT 1);
	
	v_macroexpl = (SELECT macroexpl_id FROM exploitation WHERE expl_id=v_expl);
			
	UPDATE om_mincut SET expl_id=v_expl, macroexpl_id=v_macroexpl, anl_user=current_user WHERE om_mincut.id=v_mincut;
			  
	-- count connec
	SELECT count(connec_id) INTO v_numconnecs FROM om_mincut_connec WHERE result_id=v_mincut;

	-- count hydrometers
	SELECT count (*) INTO v_numhydrometer FROM om_mincut_hydrometer WHERE result_id=v_mincut;

	-- count priority hydrometers
	v_priority = (SELECT (array_to_json(array_agg((b)))) FROM 
	(SELECT concat('{"category":"',observ,'","number":"', count(om_mincut_hydrometer.hydrometer_id), '"}')::json as b FROM om_mincut_hydrometer 
			JOIN vf_hydrometer USING (hydrometer_id)
			LEFT JOIN v_cat_hydrometer_category ON v_cat_hydrometer_category.id::text=vf_hydrometer.category_id::text
			WHERE result_id=v_mincut
			GROUP BY observ ORDER BY observ)a);

	-- profilactic control of priority
	IF v_priority IS NULL THEN v_priority='{}'; END IF;

	v_mincutdetails = (concat('{"connecs":{"number":"',v_numconnecs,'","hydrometers":{"total":"',v_numhydrometer,'","classified":',v_priority,'}}}'));
				
	--update output results
	UPDATE om_mincut SET output = v_mincutdetails WHERE id = v_mincut;	
	
	-- mincut details
	SELECT * INTO v_mincutrec FROM om_mincut WHERE id = v_mincut;
	DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=216;
	
	-- mincut details
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2000", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4362", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		
	-- Stats
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"3012", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"0"}, "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"3012", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"0"}, "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"3012", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"0"}, "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"3012", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'connecs'->>'number'), '0')||'"}, "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"3012", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincutrec.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"3012", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincutrec.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "cur_user":"current_user"}}$$)';

	-- info
	v_result = null;
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result 
	FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=216 order by id) row;
	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"values":',v_result, '}');

	v_result_info := COALESCE(v_result_info, '{}'); 

	RETURN ('{"status":"Accepted", "version":"'||v_version||'","body":{"form":{}'||
			',"data":{ "info":'||v_result_info||'}'||
			'}}')::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:3168

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_import_hydrometer_x_data(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_import_hydrometer_x_data($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{},"data":{}}$$)

--fid:470

SELECT * FROM ext_hydrometer_period
DELETE FROM ext_hydrometer_period


*/


DECLARE

v_addfields record;
v_result_id text= 'import hdyro_x_data';
v_result json;
v_result_info json;
v_project_type text;
v_version text;
v_fid integer = 470;
i integer = 0;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get system parameters
	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- manage log (fid: v_fid)
	DELETE FROM audit_check_data WHERE fid = v_fid AND cur_user=current_user;

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"3168", "fid":"'||v_fid||'", "v_result_id":"'||v_result_id||'", "is_process":true, "is_header":"true"}}$$)';


 	-- starting process
	FOR v_addfields IN SELECT * FROM temp_csv WHERE cur_user=current_user AND fid = v_fid
	LOOP
		i = i+1;
		INSERT INTO v_hydrometer_period (hydrometer_id, cat_period_id, billed_volume, value_date, value_type, value_status, value_state) VALUES
		(v_addfields.csv1::integer, v_addfields.csv2, v_addfields.csv3::float, v_addfields.csv4::timestamp, v_addfields.csv5::integer, v_addfields.csv6::integer, v_addfields.csv7::integer);
	END LOOP;

	-- manage log (fid: v_fid)
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3922", "function":"3168", "fid":"'||v_fid||'", "v_result_id":"'||v_result_id||'", "is_process":true}}$$)';

		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3928", "function":"3168", "fid":"'||v_fid||'", "v_result_id":"'||v_result_id||'", "is_process":true}}$$)';

		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3930", "function":"3168", "fid":"'||v_fid||'", "v_result_id":"'||v_result_id||'", "is_process":true}}$$)';

		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3932", "function":"3168", "parameters":{"i":"'||i||'"}, "fid":"'||v_fid||'", "v_result_id":"'||v_result_id||'", "is_process":true}}$$)';

	-- get log (fid: v_fid)
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message AS message FROM audit_check_data WHERE cur_user="current_user"() AND fid = v_fid) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_version := COALESCE(v_version, '');
	v_result_info := COALESCE(v_result_info, '{}');

	-- Return
	RETURN ('{"status":"Accepted", "message":{"level":0, "text":"Import hydrometer x data executed"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||'}}'||
	    '}')::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

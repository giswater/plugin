/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:3272

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_import_scada_flowmeteragg_values(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_import_scada_flowmeteragg_values($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{}}$$)

--fid:506

*/


DECLARE

v_addfields record;
v_result_id text= 'import flowmeter agg values';
v_result json;
v_result_info json;
v_project_type text;
v_version text;
v_fid integer = 506;
i integer = 0;
v_count integer;
v_loop_numdays integer = 0;
v_volume_numdays integer = 0;
v_currentdate date;
v_nextdate date;
v_nextvol float = 0;
v_currentvol float = 0;
v_flag boolean = false;
v_time4date text = '23:59:59'; -- two values '00:00:00' or '23:59:59'. It depens where you consider measure;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get system parameters
	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- manage log (fid: v_fid)
	DELETE FROM audit_check_data WHERE fid = v_fid AND cur_user=current_user;
	DELETE FROM temp_data;
	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"3272", "fid":"'||v_fid||'", "result_id":"'||v_result_id||'", "is_process":true, "is_header":"true"}}$$)';

	-- refactoring data on temp csv
	FOR v_addfields IN SELECT * FROM temp_csv WHERE cur_user=current_user AND fid = v_fid
	LOOP
		-- setting dates
		v_nextdate := (SELECT csv3 FROM temp_csv WHERE cur_user=current_user AND fid = v_fid AND id = v_addfields.id+1)::date;
		v_currentdate = v_addfields.csv3::date;
		v_volume_numdays = v_nextdate - v_currentdate;

		-- setting numdays
		IF v_time4date = '00:00:00' THEN
			v_loop_numdays = v_nextdate - v_currentdate -1;
			i = 0;
		ELSIF v_time4date = '23:59:59' THEN
			v_loop_numdays = v_nextdate - v_currentdate;
			 i = 1;
		END IF;

		-- setting volumes
		v_nextvol := (SELECT csv4 FROM temp_csv WHERE cur_user=current_user AND fid = v_fid AND id = v_addfields.id+1)::double precision;
		v_currentvol := v_addfields.csv4::double precision;

		--loop inserting on temp table
		IF v_loop_numdays IS NOT NULL THEN  -- excluding by this way last row wich from temp_csv
			FOR n IN i..v_loop_numdays
			LOOP
				INSERT INTO temp_data (feature_id, date_value, float_value, int_value, text_value, log_message)
				VALUES (v_addfields.csv2, v_currentdate + n, ((v_nextvol -v_currentvol)/(v_volume_numdays))::numeric(12,4),
				v_addfields.csv5::integer, v_addfields.csv6::text, v_addfields.csv1);
			END LOOP;
		END IF;
	END LOOP;

	-- mapping values on table
	INSERT INTO ext_rtc_scada_x_data SELECT log_message, feature_id, date_value::date, float_value, int_value, text_value  FROM temp_data;

	-- couting
	SELECT count(*) INTO v_count FROM (SELECT DISTINCT csv1 FROM temp_csv WHERE cur_user=current_user AND fid = v_fid)a;
	SELECT count(*) INTO i FROM (SELECT feature_id FROM temp_data)a;


	-- manage log (fid: v_fid)
	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3908", "function":"3272", "fid":"'||v_fid||'", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3910", "function":"3272", "fid":"'||v_fid||'", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3912", "function":"3272", "fid":"'||v_fid||'", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3914", "function":"3272", "fid":"'||v_fid||'", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3916", "function":"3272", "parameters":{"i":"'||i||'"}, "fid":"'||v_fid||'", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3918", "function":"3272", "parameters":{"v_count":"'||v_count||'"}, "fid":"'||v_fid||'", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	-- get log (fid: v_fid)
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message AS message FROM audit_check_data WHERE cur_user="current_user"() AND fid = v_fid) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_version := COALESCE(v_version, '');
	v_result_info := COALESCE(v_result_info, '{}');

	-- Return
	RETURN ('{"status":"Accepted", "message":{"level":0, "text":"Process executed"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||'}}'||
	    '}')::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2782

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_rpt2pg_log(text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_rpt2pg_log(p_result text, p_return json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT gw_fct_rpt2pg_log('t1')

-- fid: 103,107,114,139,164,166,170,171,198

*/

DECLARE

v_result json;
v_result_info json;
v_result_point json;
v_result_line json;
v_result_polygon json;
v_project_type text;
v_version text;
v_stats json;
v_error_context text;
v_status text = 'Accepted';

v_only_minmax boolean;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	CREATE TEMP TABLE IF NOT EXISTS temp_audit_check_data (LIKE SCHEMA_NAME.audit_check_data INCLUDING ALL);

	-- select config values
	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	SELECT value::boolean INTO v_only_minmax FROM config_param_user WHERE parameter = 'inp_report_onlymaxmin_values' AND cur_user = current_user;

	-- Header
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, concat('IMPORT RPT FILE LOG'));
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, '----------------------------');
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, concat('Result id: ', p_result));
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, concat('Imported by: ', current_user, ', on ', to_char(now(),'YYYY-MM-DD HH:MM:SS')));
	INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, '');

	IF v_project_type = 'WS' THEN

		IF v_only_minmax THEN
			IF (SELECT count(*) FROM rpt_arc_stats WHERE result_id = p_result) < 1 THEN

				-- errors
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, '------------------------------------------------------------------');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				VALUES (114, p_result, 3, UPPER('CRITICAL ERROR: The import file have been failed.'));
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 3, '');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				VALUES (114, p_result, 3, 'HINT: Take a look on the RPT file OR Export INP file again without ''Execute EPA software'' & ''Import Results'' in order to check and fix errors.');

				UPDATE rpt_cat_result SET status = 4 WHERE result_id = p_result;

				v_status = 'Failed';
			ELSE

				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, 'ONLY MAX AND MIN VALUES ARE REPORTED');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, '--------------------------------');

				-- basic statistics
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, 'BASIC STATISTICS');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, '-----------------------');

				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				SELECT 114, 'stats', 1, concat ('FLOW : Max.(',max(flow_max)::numeric(12,3), ') , Min.(', min(flow_min)::numeric(12,3),').') FROM rpt_arc_stats WHERE result_id = p_result;

				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				SELECT 114, 'stats', 1, concat ('VELOCITY : Max.(',max(vel_max)::numeric(12,3), ') , Min.(', min(vel_min)::numeric(12,3),').') FROM rpt_arc_stats WHERE result_id = p_result;

				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				SELECT 114, 'stats', 1, concat ('PRESSURE : Max.(',max(press_max)::numeric(12,3), ') , Min.(', min(press_min)::numeric(12,3),').') FROM rpt_node_stats WHERE result_id = p_result;

			END IF;
		ELSE
			IF (SELECT count(*) FROM rpt_arc WHERE result_id = p_result) < 1 THEN

				-- errors
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, '------------------------------------------------------------------');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				VALUES (114, p_result, 3, UPPER('CRITICAL ERROR: The import file have been failed.'));
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 3, '');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				VALUES (114, p_result, 3, 'HINT: Take a look on the RPT file OR Export INP file again without ''Execute EPA software'' & ''Import Results'' in order to check and fix errors.');

				UPDATE rpt_cat_result SET status = 4 WHERE result_id = p_result;

				v_status = 'Failed';
			ELSE

				-- basic statistics
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, 'BASIC STATISTICS');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, '-----------------------');

				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				SELECT 114, 'stats', 1, concat ('FLOW : Max.(',max(flow)::numeric(12,3), ') , Avg.(', avg(flow)::numeric(12,3), ') , Standard dev.(', stddev(flow)::numeric(12,3)
				, ') , Min.(', min (flow)::numeric(12,3),').') FROM rpt_arc WHERE result_id = p_result;

				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				SELECT 114, 'stats', 1, concat ('VELOCITY : Max.(',max(vel)::numeric(12,3), ') , Avg.(', avg(vel)::numeric(12,3), ') , Standard dev.(', stddev(vel)::numeric(12,3)
				, ') , Min.(', min (vel)::numeric(12,3),').') FROM rpt_arc WHERE result_id = p_result;

				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				SELECT 114, 'stats', 1, concat ('PRESSURE : Max.(',max(press)::numeric(12,3), ') , Avg.(', avg(press)::numeric(12,3), ') , Standard dev.(', stddev(press)::numeric(12,3)
				, ') , Min.(', min (press)::numeric(12,3),').') FROM rpt_node WHERE result_id = p_result;

				-- warnings
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, '');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, 'WARNINGS');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, '--------------');
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
				SELECT 114, p_result, 2, concat (time, ' ', text) FROM rpt_hydraulic_status WHERE result_id = p_result AND time = 'WARNING:';
				INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, '');

			END IF;
		END IF;

	ELSIF v_project_type = 'UD' THEN

		IF (SELECT count(*) FROM rpt_arcflow_sum WHERE result_id = p_result) < 1 THEN

			-- errors
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 4, '------------------------------------------------------------------');
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			VALUES (114, p_result, 3, UPPER('CRITICAL ERROR: The import file have been failed.'));
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 3, '');
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			VALUES (114, p_result, 3, 'HINT: Take a look on the RPT file OR Export INP file again without ''Execute EPA software'' & ''Import Results'' in order to check and fix errors.');

			UPDATE rpt_cat_result SET status = 4 WHERE result_id = p_result;

			v_status = 'Failed';

		ELSE
			-- basic statistics
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, 'BASIC STATISTICS');
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, '-----------------------');

			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			SELECT 114, p_result, 1, concat ('MAX. FLOW : Max.(',max(max_flow)::numeric(12,3), ') , Avg.(', avg(max_flow)::numeric(12,3), ') , Standard dev.(', stddev(max_flow)::numeric(12,3)
			, ') , Min.(', min (max_flow)::numeric(12,3),').') FROM rpt_arcflow_sum WHERE result_id = p_result;

			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			SELECT 114, p_result, 1, concat ('VELOCITY : Max.(',max(max_veloc)::numeric(12,3), ') , Avg.(', avg(max_veloc)::numeric(12,3), ') , Standard dev.(', stddev(max_veloc)::numeric(12,3)
			, ') , Min.(', min (max_veloc)::numeric(12,3),').') FROM rpt_arcflow_sum WHERE result_id = p_result;

			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			SELECT 114, p_result, 1, concat ('FULL PERCENT. : Max.(',max(mfull_depth)::numeric(12,3), ') , Avg.(', avg(mfull_depth)::numeric(12,3), ') , Standard dev.(', stddev(mfull_depth)::numeric(12,3)
			, ') , Min.(', min (mfull_depth)::numeric(12,3),').') FROM rpt_arcflow_sum WHERE result_id = p_result;

			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			SELECT 114, p_result, 1, concat ('NODE SURCHARGE : Number of nodes (', count(*)::integer,').')
			FROM rpt_nodesurcharge_sum WHERE result_id = p_result;

			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			SELECT 114, p_result, 1, concat ('NODE FLOODING: Number of nodes (', count(*)::integer,'), Max. rate (',max(max_rate)::numeric(12,3), '), Total flood (' ,sum(tot_flood),
			'), Max. flood (', max(tot_flood),').')
			FROM rpt_nodeflooding_sum WHERE result_id = p_result;

			-- warnings
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, '');
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, 'WARNINGS');
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, '-----------------------');
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			SELECT 114, p_result, 1, concat(csv1,' ',csv2, ' ',csv3, ' ',csv4, ' ',csv5, ' ',csv6, ' ',csv7, ' ',csv8, ' ',csv9, ' ',csv10, ' ',csv11, ' ',csv12) from temp_csv
			where fid = 11 and source='rpt_warning_summary' and cur_user=current_user;
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
			SELECT 114, p_result, 1, concat(csv1,' ',csv2, ' ',csv3, ' ',csv4, ' ',csv5, ' ',csv6, ' ',csv7, ' ',csv8, ' ',csv9, ' ',csv10, ' ',csv11, ' ',csv12) from temp_csv
			where fid = 11 and source='rpt_warning_summary' and cur_user=current_user;
			INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 2, '');
		END IF;
	END IF;

	IF v_status = 'Accepted' THEN

		v_stats = (SELECT array_to_json(array_agg(error_message)) FROM temp_audit_check_data WHERE result_id=p_result AND fid=114 AND cur_user=current_user);

		UPDATE rpt_cat_result SET rpt_stats = v_stats WHERE result_id=p_result;

		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
		SELECT 114, p_result, 1, concat(csv1,' ',csv2, ' ',csv3, ' ',csv4, ' ',csv5, ' ',csv6, ' ',csv7, ' ',csv8, ' ',csv9, ' ',csv10, ' ',csv11, ' ',csv12) from temp_csv
		where fid = 11 and source='rpt_cat_result' and cur_user=current_user;


		-- detalied user inp options
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, '');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, 'DETAILED USER INPUT OPTIONS');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (114, p_result, 1, '----------------------------------------');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message)
		SELECT 114, p_result, 1, concat (label, ' : ', value) FROM config_param_user
		JOIN sys_param_user a ON a.id=parameter WHERE cur_user=current_user AND formname='epaoptions' AND value is not null;

	END IF;

	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=114 order by criticity desc, id asc) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');
	v_result_line := COALESCE(v_result_line, '{}');
	v_result_polygon := COALESCE(v_result_polygon, '{}');

	-- drop tables
	DROP TABLE IF EXISTS temp_audit_check_data;
	DROP TABLE IF EXISTS temp_t_csv;

	--  Return
	RETURN ('{"status":"Accepted", "message":{"level":1, "text":"Rpt file have been imported"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||','||
				'"line":'||v_result_line||','||
				'"polygon":'||v_result_polygon||'}'||
		       '}'||
	    '}')::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
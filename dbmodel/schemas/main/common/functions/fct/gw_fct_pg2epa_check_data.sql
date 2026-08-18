/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2670

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_check_data(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_pg2epa_check_data($${"data":{"parameters":{"verifiedExceptions":true}}}$$);
-- v_fid: 604 check from checkproject

-- v_fid: 227 check from pg2epa
*/

DECLARE
	v_rec record;
	v_project_type text;
	v_querytext text;
	v_verified_exceptions boolean = true;
	v_fid integer = 225;
	v_isembebed boolean;
	v_return json;
	v_result_info json;
	v_result_point json;
	v_result_line json;
	v_result_polygon json;
	v_version text;
BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- select config values
	SELECT project_type, giswater INTO v_project_type, v_version FROM sys_version order by id desc limit 1;

	-- getting input parameters
	v_fid :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'fid';
	v_isembebed :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'isEmbebed';
	v_verified_exceptions :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'verifiedExceptions';

	IF v_fid IS NULL THEN v_fid = 225; END IF;
	IF v_verified_exceptions IS NULL THEN v_verified_exceptions = false; END IF;

	IF v_isembebed IS FALSE OR v_isembebed IS NULL THEN -- create temporal tables if function is not embebed
		EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"CREATE", "group":"EPAMAIN"}}}$$)';
	END IF;

    -- [MODIFICACIÓN 1] Insertar cabeceras y separadores para ordenar la salida (Estilo O&M)
    IF v_fid = 225 THEN
       
        -- Critical Errors (Criticity 3)
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2430", "fid":"'||v_fid||'", "criticity":"3", "tempTable":"t_", "is_process":true, "is_header":"true"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2430", "fid":"'||v_fid||'","criticity":"3", "tempTable":"t_", "is_process":true, "is_header":true, "label_id":"1004", "separator_id":"2014"}}$$)';

        -- Warnings (Criticity 2)
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2430", "fid":"'||v_fid||'", "criticity":"2", "tempTable":"t_","is_process":true, "separator_id":"2000"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2430", "fid":"'||v_fid||'","criticity":"2", "tempTable":"t_", "is_process":true, "is_header":true, "label_id":"3002", "separator_id":"2014"}}$$)';

        -- Info (Criticity 1)
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2430", "fid":"'||v_fid||'", "criticity":"1", "tempTable":"t_", "is_process":true, "separator_id":"2000"}}$$)';
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2430", "fid":"'||v_fid||'","criticity":"1", "tempTable":"t_", "is_process":true, "is_header":true, "label_id":"3001", "separator_id":"2007"}}$$)';
    END IF;

	-- getting sys_fprocess to be executed
	v_querytext = '
		SELECT * FROM sys_fprocess 
		WHERE project_type IN (LOWER('||quote_literal(v_project_type)||'), ''utils'') 
		AND addparam IS NULL 
		AND (query_text IS NOT NULL AND query_text <> '''') 
		AND function_name ILIKE ''%pg2epa_check_data%'' 
		AND active ORDER BY fid ASC
	';

	-- loop for checks
	FOR v_rec IN EXECUTE v_querytext LOOP
		EXECUTE 'SELECT gw_fct_check_fprocess($${"client":{"device":4, "infoType":1, "lang":"ES"}, 
	    "form":{},"feature":{},"data":{"parameters":{"functionFid":'||v_fid||', "checkFid":"'||v_rec.fid||'"}}}$$)';
	END LOOP;


	-- built return
	IF v_fid = 225 THEN

		-- materialize tables
		PERFORM gw_fct_create_logreturn($${"data":{"parameters":{"type":"fillExcepTables"}}}$$::json);

		-- create json return to send client
		EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"info"}}}$$::json)' INTO v_result_info;
		EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"point"}}}$$::json)' INTO v_result_point;
		EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"line"}}}$$::json)' INTO v_result_line;
		EXECUTE 'SELECT gw_fct_create_logreturn($${"data":{"parameters":{"type":"polygon"}}}$$::json)' INTO v_result_polygon;

		IF v_isembebed IS FALSE OR v_isembebed IS NULL THEN -- drop temporal tables if function is not embebed
			EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"DROP", "group":"EPAMAIN"}}}$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":'||v_fid||', "project_type":"'||v_project_type||'", "action":"DROP", "group":"EPA"}}}$$)';
		END IF;

		-- Return
		RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Data quality analysis done succesfully"}, "version":"'||v_version||'"'||
	             ',"body":{"form":{}'||
			     ',"data":{ "info":'||v_result_info||','||
					'"point":'||v_result_point||','||
					'"line":'||v_result_line||','||
					'"polygon":'||v_result_polygon||
			       '}'||
		    '}}')::json, 2430, null, null, null);
	ELSE
		--  Return
		RETURN '{"status":"ok"}';

	END IF;

	--  Return
	EXECUTE 'SELECT gw_fct_create_return($${"data":{"parameters":{"functionId":3364, "isEmbebed":'||v_isembebed||'}}}$$::json)' INTO v_return;
	RETURN v_return;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
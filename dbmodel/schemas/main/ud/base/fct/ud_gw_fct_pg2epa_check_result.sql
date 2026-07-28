/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2858

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_check_result(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_pg2epa_check_result($${"data":{"parameters":{"resultId":"gw_check_project","fid":227, "dumpSubcatch":true}}}$$)-- when is called from go2epa_main from toolbox
SELECT SCHEMA_NAME.gw_fct_pg2epa_check_result($${"data":{"parameters":{"resultId":"gw_check_project"}}}$$) -- when is called from toolbox

SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES"}, "data":{"resultId":"test1", "useNetworkGeom":"false", "dumpSubcatch":"true"}}$$)

SELECT * FROM SCHEMA_NAME.audit_check_data where fid::text  = 227::text

	-- delete old values on result table
	DELETE FROM audit_check_data WHERE fid = 114 AND cur_user=current_user;
	DELETE FROM audit_check_data WHERE id < 0;
	DELETE FROM anl_node WHERE fid IN (159) AND cur_user=current_user;
	DELETE FROM anl_arc WHERE fid IN (103) AND cur_user=current_user;

-- fid: 369,370,396,401,402,455,456,457,458

*/

DECLARE

i integer = 0;
v_fid integer;
v_record record;
v_project_type text;
v_count	integer;
v_count_2 integer;
v_infiltration text;
v_min_node2arc float;
v_saveondatabase boolean;
v_result text;
v_version text;
v_result_info json;
v_result_point json;
v_result_line json;
v_result_polygon json;
v_querytext text;
v_nodearc_real float;
v_nodearc_user float;
v_result_id text;
v_min numeric (12,4);
v_max numeric (12,4);
v_hydrologyscenario text;
v_qualitymode text;
v_qualmodeval text;
v_buildupmode int2;
v_buildmodeval text;
v_usenetworkgeom boolean;
v_usenetworkdemand boolean;
v_defaultdemand	float;
v_doublen2a integer;
v_curvedefault text;
v_options json;
v_error_context text;

v_dumpsubc boolean;
v_hydroscenarioval text;

v_checkresult boolean;

v_debug boolean;
v_debugval text;
v_advanced boolean;
v_advancedval text;
v_default boolean;
v_defaultval text;
v_dwfscenarioval text;
v_exportmodeval text;
v_networkmode integer;
v_setallraingages text;

object_rec record;

v_graphiclog boolean;
v_workspace text;
v_dscenarioused integer;
v_psectorused integer;

v_rec record;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- getting input data
	v_result_id := ((p_data ->>'data')::json->>'parameters')::json->>'resultId'::text;
	v_fid := ((p_data ->>'data')::json->>'parameters')::json->>'fid';
	v_dumpsubc := NULLIF(((p_data ->>'data')::json->>'parameters')::json->>'dumpSubcatch', '')::boolean;

	-- get system values
	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get user values
	v_checkresult = NULLIF((SELECT value::json->>'checkResult' FROM config_param_user WHERE parameter='inp_options_debug' AND cur_user=current_user), '')::boolean;
	v_graphiclog = NULLIF((SELECT (value::json->>'graphicLog') FROM config_param_user WHERE parameter='inp_options_debug' AND cur_user=current_user), '')::boolean;
	v_networkmode = (SELECT (value) FROM config_param_user WHERE parameter='inp_options_networkmode' AND cur_user=current_user)::integer;
	v_setallraingages = (SELECT (value) FROM config_param_user WHERE parameter='inp_options_setallraingages' AND cur_user=current_user);


	-- manage no found results
	IF (SELECT result_id FROM rpt_cat_result WHERE result_id=v_result_id) IS NULL THEN
		v_result  = (SELECT array_to_json(array_agg(row_to_json(row))) FROM (SELECT 1::integer as id, 'No result found whith this name....' as  message)row);
		v_result_info = concat ('{"values":',v_result, '}');
		RETURN ('{"status":"Accepted", "message":{"level":1, "text":"No result found"}, "version":"'||v_version||'"'||
			',"body":{"form":{}, "data":{"info":'||v_result_info||'}}}')::json;
	END IF;

	-- init variables
	v_count=0;
	IF v_fid is null THEN
		v_fid = 114;
	END IF;

	-- delete old values on result table
	DELETE FROM audit_check_data WHERE fid = 114 AND cur_user=current_user;
	DELETE FROM audit_check_data WHERE id < 0;

	-- get user parameters
	v_hydroscenarioval = (SELECT name FROM config_param_user JOIN cat_hydrology c ON value = hydrology_id::text WHERE parameter = 'inp_options_hydrology_current' AND cur_user = current_user);
	v_dwfscenarioval = (SELECT idval FROM config_param_user JOIN cat_dwf c ON value = c.id::text WHERE parameter = 'inp_options_dwfscenario_current' AND cur_user = current_user);
	IF v_dwfscenarioval IS NULL THEN
		v_dwfscenarioval = 'No dwf scenario chosen';
	END IF;

	-- get settings values
	v_default = NULLIF((SELECT value::json->>'status' FROM config_param_user WHERE parameter = 'inp_options_vdefault' AND cur_user=current_user), '')::boolean;
	v_defaultval = (SELECT value::json->>'parameters' FROM config_param_user WHERE parameter = 'inp_options_vdefault' AND cur_user=current_user);

	v_advanced = NULLIF((SELECT value::json->>'status' FROM config_param_user WHERE parameter = 'inp_options_advancedsettings' AND cur_user=current_user), '')::boolean;
	v_advancedval = (SELECT value::json->>'parameters' FROM config_param_user WHERE parameter = 'inp_options_advancedsettings' AND cur_user=current_user);

	v_debug = NULLIF((SELECT value::json->>'showLog' FROM config_param_user WHERE parameter = 'inp_options_debug' AND cur_user=current_user), '')::boolean;
	v_debugval = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_debug' AND cur_user=current_user);

	v_exportmodeval = (SELECT idval FROM config_param_user, inp_typevalue WHERE id = value AND typevalue = 'inp_options_networkmode' and cur_user = current_user and parameter = 'inp_options_networkmode');
	SELECT name INTO v_workspace FROM config_param_user c JOIN cat_workspace ON value = id::text WHERE parameter = 'utils_workspace_current' AND c.cur_user=current_user;

	v_dscenarioused = (SELECT count(dscenario_id) FROM selector_inp_dscenario WHERE cur_user = current_user);
	v_psectorused = (SELECT count(psector_id) FROM selector_psector WHERE cur_user = current_user);

	-- Header
	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message) VALUES (-10, v_fid, v_result_id, 4,
	concat('CHECK RESULT WITH CURRENT USER-OPTIONS ACORDING EPA RULES'));
	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message)
	VALUES (-9, v_fid, v_result_id, 4, '--------------------------------------------------------------------------------------');

	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message) VALUES (-8, v_fid, v_result_id, 3, 'CRITICAL ERRORS');
	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message) VALUES (-7, v_fid, v_result_id, 3, '----------------------');

	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message) VALUES (-6, v_fid, v_result_id, 2, 'WARNINGS');
	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message) VALUES (-5, v_fid, v_result_id, 2, '--------------');

	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message) VALUES (-4, v_fid, v_result_id, 1, 'INFO');
	INSERT INTO t_audit_check_data (id, fid, result_id, criticity, error_message) VALUES (-3, v_fid, v_result_id, 1, '-------');

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4006", "function":"2858", "parameters":{"v_eparesult":"'||v_result_id||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4560", "function":"2858", "parameters":{"v_createdby":"'||current_user||'", "v_date":"'||to_char(now(),'YYYY-MM-DD HH-MM-SS')||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4562", "function":"2858", "parameters":{"v_exportmodeval":"'||v_exportmodeval||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4564", "function":"2858", "parameters":{"v_hydroscenarioval":"'||COALESCE(v_hydroscenarioval, '')||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4566", "function":"2858", "parameters":{"v_dwfscenarioval":"'||COALESCE(v_dwfscenarioval, '')||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4568", "function":"2858", "parameters":{"v_dumpsubc":"'||v_dumpsubc::text||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4570", "function":"2858", "parameters":{"v_workspace":"'||COALESCE(v_workspace, '')||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4572", "function":"2858", "parameters":{"v_dscenarioused":"'||v_dscenarioused||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4574", "function":"2858", "parameters":{"v_psectorused":"'||v_psectorused||'"}, "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';

	UPDATE rpt_cat_result SET
	export_options = concat('{"Hydrology scenario": "', v_hydroscenarioval,'", "DWF scenario":"',v_dwfscenarioval,'"}')::json
	WHERE result_id = v_result_id;

	IF v_checkresult THEN

		IF v_default::boolean THEN
			EXECUTE 'SELECT gw_fct_getmessage($$' || jsonb_build_object('data', jsonb_build_object('message', '4548','function', '2858','parameters', jsonb_build_object('v_defaultval', v_defaultval),'fid', v_fid,'criticity', '4','tempTable', 't_'))::text ||'$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4550", "function":"2858", "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
		END IF;

		IF v_advanced::boolean THEN
			EXECUTE 'SELECT gw_fct_getmessage($$' || jsonb_build_object('data', jsonb_build_object('message', '4552','function', '2858','parameters', jsonb_build_object('v_advancedval', v_advancedval),'fid', v_fid,'criticity', '4','tempTable', 't_'))::text ||'$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4554", "function":"2858", "fid":"'||v_fid||'", "criticity":"4", "tempTable":"t_"}}$$)';
		END IF;

		IF v_debug::boolean THEN
			EXECUTE 'SELECT gw_fct_getmessage($$' || jsonb_build_object('data', jsonb_build_object('message', '4556','function', '2858','parameters', jsonb_build_object('v_defaultval', v_defaultval),'fid', v_fid,'criticity', '4','tempTable', 't_'))::text ||'$$)';
		END IF;

		IF v_setallraingages IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($$' || jsonb_build_object('data', jsonb_build_object('message', '4558','function', '2858','parameters', jsonb_build_object('v_setallraingages', v_setallraingages),'fid', v_fid,'criticity', '4','tempTable', 't_'))::text ||'$$)';
		END IF;


		v_querytext = '
		SELECT * FROM sys_fprocess 
		WHERE project_type IN (LOWER('||quote_literal(v_project_type)||'), ''utils'') 
		AND addparam IS NULL 
		AND query_text IS NOT NULL 
		AND function_name ILIKE ''%gw_fct_pg2epa_check_result%'' AND function_name NOT ILIKE ''%gw_fct_pg2epa_check_result_%''
		AND active ORDER BY fid ASC
		';

		-- loop for checks
		FOR v_rec IN EXECUTE v_querytext
		LOOP
			EXECUTE 'SELECT gw_fct_check_fprocess($${"client":{"device":4, "infoType":1, "lang":"ES"}, 
			"form":{},"feature":{},"data":{"parameters":{"functionFid":'||v_fid||', "checkFid":"'||v_rec.fid||'"}}}$$)';
		END LOOP;


		SELECT infiltration INTO v_infiltration FROM cat_hydrology JOIN config_param_user ON hydrology_id=value::integer WHERE cur_user=current_user AND parameter = 'inp_options_hydrology_current';

		IF v_infiltration IS NOT NULL THEN

			v_querytext = '
			SELECT * FROM sys_fprocess 
			WHERE project_type IN (LOWER('||quote_literal(v_project_type)||'), ''utils'') 
			AND addparam IS NULL 
			AND query_text IS NOT NULL 
			AND function_name ILIKE ''%gw_fct_pg2epa_check_result_'||lower(v_infiltration)||'%''
			AND active ORDER BY fid ASC
			';

			-- loop for checks
			FOR v_rec IN EXECUTE v_querytext
			LOOP
				EXECUTE 'SELECT gw_fct_check_fprocess($${"client":{"device":4, "infoType":1, "lang":"ES"}, 
				"form":{},"feature":{},"data":{"parameters":{"functionFid":'||v_fid||', "checkFid":"'||v_rec.fid||'"}}}$$)';
			END LOOP;

		END IF;
	END IF;

	-- insert spacers for log
	INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, v_result_id, 4, '');
	INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, v_result_id, 3, '');
	INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, v_result_id, 2, '');
	INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, v_result_id, 1, '');

	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT error_message as message FROM t_audit_check_data WHERE cur_user="current_user"() AND fid = v_fid
	order by criticity desc, id asc) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	IF v_graphiclog THEN

		--points
		v_result = null;
		SELECT jsonb_build_object(
			'type', 'FeatureCollection',
			'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		) INTO v_result
		FROM (
			SELECT jsonb_build_object(
				'type',       'Feature',
				'geometry',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
				'properties', to_jsonb(row) - 'the_geom'
			) AS feature FROM
			(SELECT node_id as id, 228 as fid, 'ERROR-228: Orphan node' as descript, ST_Transform(the_geom, 4326) as the_geom FROM t_anl_node WHERE cur_user="current_user"() AND fid IN (228,107)
			UNION
			SELECT node_id as id, 396 as fid, 'ERROR-396: Node used on more than one scenario' as descript, ST_Transform(the_geom, 4326) as the_geom FROM t_anl_node WHERE cur_user="current_user"() AND fid = 396)
		row) features;

		v_result := COALESCE(v_result, '{}');
		v_result_point = v_result::text;

		-- arcs
		v_result = null;
		SELECT jsonb_build_object(
			'type', 'FeatureCollection',
			'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		) INTO v_result
		FROM (
			SELECT jsonb_build_object(
				'type',       'Feature',
				'geometry',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
				'properties', to_jsonb(row) - 'the_geom'
			) AS feature
			FROM  (SELECT arc_id as id, fid, 'ERROR: Disconnected arc'::text as descript, ST_Transform(the_geom, 4326) as the_geom FROM t_anl_arc WHERE cur_user="current_user"() AND fid = 139
					UNION
				SELECT arc_id as id, fid, 'ERROR-427: Flow regulator length do not fits with target arc', ST_Transform(the_geom, 4326) as the_geom FROM t_anl_arc WHERE cur_user="current_user"() AND fid = 427
					UNION
				SELECT arc_id as id, fid, 'ERROR-396: Arc used on more than one scenario', ST_Transform(the_geom, 4326) as the_geom FROM t_anl_arc WHERE cur_user="current_user"() AND fid = 396
			) row) features;

		v_result := COALESCE(v_result, '{}');
		v_result_line = v_result::text;

	END IF;

	-- control nulls
	v_options := COALESCE(v_options, '{}');
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');
	v_result_line := COALESCE(v_result_line, '{}');

	--  Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Data quality analysis done succesfully"}, "version":"'||v_version||'"'||
		',"body":{"form":{}'||
			',"data":{"options":'||v_options||','||
				'"info":'||v_result_info||','||
				'"point":'||v_result_point||','||
				'"line":'||v_result_line||'}'||
			'}'||
		'}')::json, 2858, null, null, null);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
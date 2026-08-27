/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2848

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_check_result(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_pg2epa_check_result($${"data":{"parameters":{"resultId":"test1","fid":227}}}$$) --when is called from go2epa_main from toolbox
*/

DECLARE

	v_rec record;
	v_project_type text;
	v_querytext text;
	v_verified_exceptions boolean = true;
	v_fid integer;
	v_isembebed boolean;
	v_return json;
	v_result_id text;

	object_rec record;
	v_count integer;
	i integer;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- select config values
	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- getting input parameters
	v_result_id := ((p_data ->>'data')::json->>'parameters')::json->>'resultId'::text;
	v_fid :=  ((p_data ->> 'data')::json->>'parameters')::json->> 'fid';

	-- getting sys_fprocess to be executed
	v_querytext = '
		SELECT * FROM sys_fprocess 
		WHERE project_type IN (LOWER('||quote_literal(v_project_type)||'), ''utils'') 
		AND addparam IS NULL 
		AND query_text IS NOT NULL 
		AND function_name ILIKE ''%pg2epa_check_result%''
		AND function_name NOT ILIKE ''%gw_fct_pg2epa_check_result\_%''
		AND active ORDER BY fid ASC
	';

	-- loop for checks
	FOR v_rec IN EXECUTE v_querytext
	LOOP
		EXECUTE 'SELECT gw_fct_check_fprocess($${"client":{"device":4, "infoType":1, "lang":"ES"}, 
	    "form":{},"feature":{},"data":{"parameters":{"functionFid":'||v_fid||', "checkFid":"'||v_rec.fid||'"}}}$$)';
	END LOOP;

	EXECUTE 'SELECT gw_fct_create_logtables($${"data":{"parameters":{"fid":227, "resultId":"'||v_result_id||'"}}}$$::json)';
	-- TODO
	-------------------- to be replaced
	RAISE NOTICE 'Check if there are conflicts with dscenarios (396)';
	IF (SELECT count(*) FROM selector_inp_dscenario WHERE cur_user = current_user) > 0 THEN

		FOR object_rec IN SELECT json_array_elements_text('["tank", "reservoir", "pipe", "pump", "valve", "virtualvalve", "connec", "inlet", "junction"]'::json) as tabname,
					 json_array_elements_text('["node", "node" , "arc" , "node" , "node", "arc", "connec", "node", "node"]'::json) as colname
		LOOP

			EXECUTE 'SELECT count(*) FROM (SELECT count(*) FROM ve_inp_dscenario_'||object_rec.tabname||' GROUP BY '||object_rec.colname||'_id HAVING count(*) > 1) a' INTO v_count;
			IF v_count > 0 THEN

				IF object_rec.colname IN ('arc', 'node') THEN

					EXECUTE 'INSERT INTO t_'||object_rec.colname||' ('||object_rec.colname||'_id, descript, the_geom) 
					SELECT '||object_rec.colname||'_id, concat(''Present on '',count(*),'' enabled dscenarios''), ve_inp_dscenario_'||object_rec.tabname||'.the_geom 
					FROM ve_inp_dscenario_'||object_rec.tabname||' JOIN '||	object_rec.colname||' USING ('||object_rec.colname||'_id) GROUP 
					BY '||object_rec.colname||'_id, ve_inp_dscenario_'||object_rec.tabname||'.the_geom having count(arc_id) > 1';


					INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
					VALUES (v_fid, v_result_id, 3, concat('ERROR-396 (anl_',object_rec.colname,'): There is/are ', v_count, ' ',
					object_rec.colname,'(s) for ',upper(object_rec.tabname),' used on more than one enabled dscenarios.'));
				ELSE
					INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
					VALUES (v_fid, v_result_id, 3, concat('ERROR-396: There is/are ', v_count, ' ',
					object_rec.colname,'(s) for ',upper(object_rec.tabname),' used on more than one enabled dscenarios.'));
				END IF;
			END IF;
		END LOOP;
	ELSE
		INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
		VALUES (v_fid, v_result_id, 1, concat('INFO: There are not dscenarios selected.'));
	END IF;

	-- RULES nodes
	FOR object_rec IN SELECT json_array_elements_text('["NODE", "JUNCTION", "RESERVOIR", "TANK"]'::json) as tabname
	LOOP
		v_querytext = '(SELECT a.id, a.code as controls, b.code as templayer FROM 
		(SELECT substring(split_part(text,'||quote_literal(object_rec.tabname)||', 2) FROM ''[^ ]+''::text) code, id, sector_id FROM inp_rules WHERE active is true)a
		LEFT JOIN t_node b USING (code)
		WHERE b.code IS NULL AND a.code IS NOT NULL 
		AND a.sector_id IN (SELECT sector_id FROM selector_sector WHERE cur_user=current_user) AND a.sector_id IS NOT NULL
		OR a.sector_id::text != b.sector_id::text) a';

		EXECUTE concat ('SELECT count(*) FROM ',v_querytext) INTO v_count;
		IF v_count > 0 THEN
			i = i+1;
			EXECUTE concat ('SELECT array_agg(id) FROM ',v_querytext) INTO v_querytext;
			INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
			VALUES (v_fid, v_result_id, 3, concat('ERROR-402: There is/are ', v_count, ' RULES with ',lower(object_rec.tabname),' not present on this result. Rule id''s:',v_querytext));
		END IF;
	END LOOP;

	IF v_count = 0 AND i = 0 THEN
		INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
		VALUES (v_fid, v_result_id, 1, concat('INFO: All RULES has correct node id values.'));
	END IF;

	-- RULES arcs
	i = 0;
	FOR object_rec IN SELECT json_array_elements_text('["LINK", "PIPE", "PUMP", "VALVE"]'::json) as tabname
	LOOP
		v_querytext = '(SELECT a.id, a.code as controls, b.code as templayer FROM 
		(SELECT substring(split_part(text,'||quote_literal(object_rec.tabname)||', 2) FROM ''[^ ]+''::text) code, id, sector_id FROM inp_rules WHERE active is true)a
		LEFT JOIN t_arc b USING (code)
		WHERE b.code IS NULL AND a.code IS NOT NULL 
		AND a.sector_id IN (SELECT sector_id FROM selector_sector WHERE cur_user=current_user) AND a.sector_id IS NOT NULL
		OR a.sector_id::text != b.sector_id::text) a';

		EXECUTE concat ('SELECT count(*) FROM ',v_querytext) INTO v_count;
		IF v_count > 0 THEN
			i = i+1;
			EXECUTE concat ('SELECT array_agg(id) FROM ',v_querytext) INTO v_querytext;
			INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
			VALUES (v_fid, v_result_id, 3, concat('ERROR-402: There is/are ', v_count, ' RULES with ',lower(object_rec.tabname),' not present on this result. Rule id''s:',v_querytext));
		END IF;
	END LOOP;

	IF v_count = 0 AND i = 0 THEN
		INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
		VALUES (v_fid, v_result_id, 1, concat('INFO: All RULES has correct link id values.'));
	END IF;
	------- to be replaced

	--  Return
	RETURN '{"status":"ok"}';

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
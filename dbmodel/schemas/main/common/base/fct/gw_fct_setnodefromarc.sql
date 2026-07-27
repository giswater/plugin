/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2118

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_built_nodefromarc();
DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_built_nodefromarc(json);
DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_node_builtfromarc(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setnodefromarc(p_data json) RETURNS json AS
$BODY$

/*EXAMPLE

MODE 1: complete
SELECT SCHEMA_NAME.gw_fct_setnodefromarc (2118)($${"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{}, "feature":{},
"data":{"filterFields":{}, "pageInfo":{}, "selectionMode":"wholeSelection",
"parameters":{"exploitation":"1", "inserIntoNode":"true", "nodeTolerance":"0.01", "saveOnDatabase":"true"}}}$$)::text

MODE 2: usign pure SQL
SELECT SCHEMA_NAME.gw_fct_setnodefromarc(concat('{"client":{"device":4,"lang":"ES","version":"4.0.001","infoType":1,"epsg":25831},
"form":{},"feature":{"tableName":"ve_arc","featureType":"ARC","id":["',arc_id,'"]},
"data":{"filterFields":{},"pageInfo":{},"selectionMode":"previousSelection",
"parameters":{"insertIntoNode":"true","nodeTolerance":"0.1","exploitation":"10",
"stateType":"2","builtdate":null,"nodeType":"JUNCTION","nodeCat":"JUNCTION"},"aux_params":null}}')::json
) FROM .... WHERE ....;

-- fid: 116
*/

DECLARE

rec_arc record;
rec_table record;

numnodes integer;
v_version text;
v_saveondatabase boolean = true;
v_result json;
v_result_info json;
v_result_point json;
v_node_proximity double precision;
v_buffer double precision;
v_nodetype text;
v_expl integer;
v_insertnode boolean;
v_projecttype text;
rec record;
v_nodecat text;
v_node_type text;
v_isarcdivide boolean;

v_workcat text;
v_state integer;
v_state_type integer;
v_builtdate date;
v_nodecat_id text;
v_arclist json;
v_count integer;
v_node_id text;
v_selection_mode text;
v_id text;
v_querytext text;
v_error_context text;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- SELECT giswater
	SELECT giswater, project_type INTO v_version, v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;

	-- getting input data
	v_expl :=  ((p_data ->>'data')::json->>'parameters')::json->>'exploitation';
	v_buffer := ((p_data ->>'data')::json->>'parameters')::json->>'nodeTolerance';
	v_insertnode := ((p_data ->>'data')::json->>'parameters')::json->>'insertIntoNode';

	v_workcat := ((p_data ->>'data')::json->>'parameters')::json->>'workcatId'::text;
	v_state_type := ((p_data ->>'data')::json->>'parameters')::json->>'stateType'::text;
	v_builtdate := ((p_data ->>'data')::json->>'parameters')::json->>'builtdate'::text;
	v_node_type := ((p_data ->>'data')::json->>'parameters')::json->>'nodeType'::text;
	v_nodecat_id := ((p_data ->>'data')::json->>'parameters')::json->>'nodeCat'::text;
	v_selection_mode := (p_data ->>'data')::json->>'selectionMode'::text;
	v_id := (p_data ->>'feature')::json->>'id'::text;

	IF v_id IS NULL OR v_id = '' THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4330", "function":"2118", "parameters":{"parameter":"id"}, "is_process":true}}$$);';
	END IF;

	select replace(replace(replace(v_id, '[', ''), ']', ''), '"', '''') into v_id;

	if v_selection_mode = 'previousSelection' then
		v_querytext = ' AND arc_id in ('||v_id||')';
	else
		v_querytext = '';
	end if;

	-- disable arc divide temporary
	UPDATE config_param_user SET value = 'TRUE'  WHERE "parameter"='edit_disable_arc_divide' AND cur_user=current_user;


	select state into v_state from value_state_type where id=v_state_type;

	--  Reset values
	DELETE FROM temp_table WHERE cur_user=current_user AND fid = 116;
	DELETE FROM anl_node WHERE cur_user=current_user AND fid = 116;
	DELETE FROM audit_check_data WHERE cur_user=current_user AND fid = 116;


EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2118", "fid":"116", "criticity":"4", "is_process":true, "is_header":"true"}}$$)';
	-- inserting all extrem nodes on temp_node
	EXECUTE 'INSERT INTO temp_table (fid, text_column, geom_point)
	SELECT 	116, arc_id, ST_StartPoint(the_geom) AS the_geom FROM ve_arc WHERE expl_id='||v_expl||' and (state=1 or state=2) '||v_querytext||'
	UNION 
	SELECT 	116, arc_id, ST_EndPoint(the_geom) AS the_geom FROM ve_arc WHERE expl_id='||v_expl||' and (state=1 or state=2) '||v_querytext||'';

   -- disable arc divide because new nodes are on start/end vertices
	ALTER TABLE node DISABLE TRIGGER gw_trg_node_arc_divide;

	-- inserting into node table
	FOR rec_table IN SELECT * FROM temp_table WHERE cur_user=current_user AND fid = 116
	LOOP
	    -- Check existing nodes
	    numNodes:= 0;
		numNodes:= (SELECT COUNT(*) FROM node WHERE st_dwithin(node.the_geom, rec_table.geom_point, v_buffer));
		IF numNodes = 0 THEN
			IF v_insertnode THEN
				INSERT INTO ve_node (expl_id, workcat_id, state, state_type, builtdate, node_type, the_geom, nodecat_id)
				VALUES (v_expl, v_workcat, v_state, v_state_type, v_builtdate, v_node_type, rec_table.geom_point, v_nodecat_id)
				RETURNING node_id INTO v_node_id;

				INSERT INTO anl_node (node_id, the_geom, state, fid, expl_id, nodecat_id)
				VALUES (v_node_id, rec_table.geom_point, v_state, 116, v_expl, v_nodecat_id);

			ELSE
				INSERT INTO anl_node (the_geom, state, fid, expl_id, nodecat_id)
				VALUES (rec_table.geom_point, v_state, 116,v_expl, v_nodecat_id);
			END IF;
		END IF;
	END LOOP;

	-- repair arcs
	IF v_insertnode THEN


		if v_selection_mode = 'previousSelection' then
			EXECUTE 'SELECT array_to_json(array_agg(arc_id::text)) 
			FROM arc WHERE expl_id='||v_expl||' AND arc_id in ('||v_id||')'
			INTO v_arclist;
		else
			EXECUTE 'SELECT array_to_json(array_agg(arc_id::text)) 
			FROM arc WHERE expl_id='||v_expl||' AND (node_1 IS NULL OR node_2 IS NULL)'
			INTO v_arclist;
		end if;

		IF v_arclist IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_arc_repair($${"client":{"device":4, "infoType":1,"lang":"ES"},"feature":{"id":'||v_arclist||'},
			"data":{}}$$);';
		END IF;

	END IF;

    -- enable arc divide
    ALTER TABLE node ENABLE TRIGGER gw_trg_node_arc_divide;

	-- get log
	SELECT count(*) INTO v_count FROM anl_node WHERE cur_user="current_user"() AND fid=116;

	IF v_count=0 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4408", "function":"2118", "fid":"116", "fcount":"0", "is_process":true}}$$)';
	ELSE
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4410", "function":"2118", "parameters":{"v_count":"'||v_count||'"}, "fid":"116", "fcount":"'||v_count||'", "is_process":true}}$$)';

		INSERT INTO audit_check_data(fid,  error_message, fcount)
		SELECT 116,  concat ('Node_id: ',string_agg(node_id, ', '), '.' ), v_count
		FROM anl_node WHERE cur_user="current_user"() AND fid=116;
	END IF;

	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid = 116) row;
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
  	FROM  anl_node WHERE cur_user="current_user"() AND fid=116) row) features;

	v_result_point = v_result;

  	IF v_saveondatabase IS FALSE THEN
		-- delete previous results
		DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=116;
	ELSE
		-- set selector
		DELETE FROM selector_audit WHERE fid=116 AND cur_user=current_user;
		INSERT INTO selector_audit (fid,cur_user) VALUES (116, current_user);
	END IF;

	-- enable arc divide temporary
	UPDATE config_param_user SET value = 'FALSE'  WHERE "parameter"='edit_disable_arc_divide' AND cur_user=current_user;


	-- Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');

	-- Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Process done successfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||'}}'||
	    '}')::json, 2118, null, null, null);

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);


END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

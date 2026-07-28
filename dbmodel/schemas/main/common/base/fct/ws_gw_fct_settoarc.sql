/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


--FUNCTION CODE: 3006

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_settoarc(p_data json)
  RETURNS json AS
$BODY$


/*EXAMPLE

SELECT SCHEMA_NAME.gw_fct_settoarc($${"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"featureType":"CHECK_VALVE", "id":"1082"},
"data":{"filterFields":{}, "pageInfo":{}, "arcId":"2064", "dmaId":"2", "presszoneId":"3", "sectorId":"3", "dqaId":"1"}}$$);

SELECT SCHEMA_NAME.gw_fct_settoarc($${"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"featureType":"SHUTOFF_VALVE", "id":"1115"},
"data":{"filterFields":{}, "pageInfo":{},"parameters":{"arcId":"11","dmaId":"2", "presszoneId":"3"}}}$$)::text;

fid:359
*/

DECLARE

v_feature_type text;
v_feature_id integer;
v_arc_id integer;
v_feature_class text;
v_epatype text;
v_graphdelim text[];
v_mapzone_id text;
v_dma_id text;
v_dqa_id text;
v_presszone_id text;
v_mapzone_array text[];
rec text;
v_check_graphconfig text;

v_level integer;
v_result_info text;
v_result text;
v_version text;
v_error_context text;
v_element_id integer;

BEGIN

	--  Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- SELECT giswater
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	v_feature_type := json_extract_path_text (p_data,'feature','featureType')::text;
	v_feature_id:= json_extract_path_text (p_data,'feature','id')::integer;
	v_arc_id:= json_extract_path_text (p_data,'data','arcId')::integer;
	v_dma_id:= json_extract_path_text (p_data,'data','dmaId')::text;
	v_presszone_id:= json_extract_path_text (p_data,'data','presszoneId')::text;
	v_dqa_id:= json_extract_path_text (p_data,'data','dqaId')::text;

	SELECT upper(feature_class), ARRAY(SELECT upper(unnest(graph_delimiter))) INTO v_feature_class, v_graphdelim
	FROM cat_feature_node
	JOIN cat_feature ON cat_feature.id = cat_feature_node.id
	WHERE cat_feature_node.id = v_feature_type;

	IF v_feature_class IS NULL THEN
		SELECT upper(feature_class) INTO v_feature_class
		FROM cat_feature WHERE cat_feature.id = v_feature_type;
	END IF;

	SELECT upper(epa_type) INTO v_epatype FROM node WHERE node_id = v_feature_id;

	DELETE FROM audit_check_data WHERE fid=359 AND cur_user=current_user;
	

	-- get feature id if the objet is a frelement  
	IF v_feature_class ='FRELEM' THEN
		v_element_id = v_feature_id;
		v_feature_id = (SELECT node_id FROM man_frelem WHERE element_id = v_element_id);
	END IF;

	-- check if to_arc is connected with node
	IF v_element_id IS NULL AND v_arc_id NOT IN (SELECT arc_id FROM arc WHERE node_1 = v_feature_id AND state > 0 UNION SELECT arc_id FROM arc WHERE node_2 = v_feature_id AND state > 0) THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                    "data":{"message":"3272", "function":"3006","parameters":null}}$$);';
	END IF;

	-- man_tables
	IF v_feature_class = 'PUMP' THEN

		INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (359,1,
		concat('Set to_arc for pump, ', v_feature_id, ' with value ',v_arc_id, '.'));

		UPDATE man_pump SET to_arc = v_arc_id::int4 WHERE node_id = v_feature_id;

	ELSIF v_feature_class = 'VALVE' THEN

		INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (359,1,
		concat('Set to_arc for valve, ', v_feature_id, ' with value ',v_arc_id, '.'));

		UPDATE man_valve SET to_arc = v_arc_id::int4 WHERE node_id = v_feature_id;

	ELSIF v_feature_class = 'METER' THEN

		UPDATE man_meter SET to_arc = v_arc_id::int4 WHERE node_id = v_feature_id;

	ELSIF v_feature_class = 'FRELEM' THEN

		UPDATE man_frelem SET to_arc = v_arc_id::int4 WHERE element_id = v_element_id;

	END IF;

	-- graphconfig for mapzones
	IF v_graphdelim && ARRAY['SECTOR','PRESSZONE','DMA','DQA', 'DWFZONE', 'DRAINZONE'] THEN

		--define list of mapzones to be set
		SELECT array_agg(lower(unnest)) INTO v_mapzone_array FROM unnest(v_graphdelim);

		FOREACH rec IN ARRAY(v_mapzone_array) LOOP

		    IF rec IN ('dma', 'presszone', 'dqa') THEN
			IF rec = 'dma' THEN
			    v_mapzone_id=v_dma_id;

			    INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (359,1, concat('Set to_arc of dma ', v_dma_id, ' with value ',v_arc_id, '.'));

			ELSIF rec = 'presszone' THEN
			    v_mapzone_id=v_presszone_id;

			    INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (359,1, concat('Set to_arc of presszone ', v_presszone_id, ' with value ',v_arc_id, '.'));
			ELSIF rec = 'dqa' THEN
				v_mapzone_id=v_dqa_id;

				INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (359,1, concat('Set to_arc of dqa ', v_dqa_id, ' with value ',v_arc_id, '.'));
			END IF;

			IF v_mapzone_id IS NULL THEN
			    EXECUTE 'SELECT '||rec||'_id  FROM node WHERE node_id = '||v_feature_id||''
			    INTO v_mapzone_id;
			END IF;

			EXECUTE 'SELECT graphconfig FROM '||rec||' WHERE '||rec||'_id::text = '||quote_literal(v_mapzone_id)||'::text'
			INTO v_check_graphconfig;

			IF v_check_graphconfig IS NOT NULL
			   AND v_check_graphconfig <> '{"use":[{"nodeParent":"", "toArc":[]}], "ignore":[], "forceClosed":[]}' THEN

			    EXECUTE  'SELECT 1 FROM '||rec||' CROSS JOIN json_array_elements((graphconfig->>''use'')::json) elem 
			    WHERE (elem->>''nodeParent'')::int4 = '||v_feature_id||' AND '||rec||'_id = '||v_mapzone_id||' LIMIT 1'
			    INTO v_check_graphconfig;

			    IF v_check_graphconfig = '1'  THEN
				-- update toArc only when nodeParent is already configured on the mapzone

				EXECUTE 'UPDATE '||rec||' set graphconfig = replace(graphconfig::text,a.toarc,'||v_arc_id||'::text)::json FROM (
				select json_array_elements_text((elem->>''toArc'')::json) as toarc, elem->>''nodeParent'' as elem
				from '||rec||'
				cross join json_array_elements((graphconfig->>''use'')::json) elem
				where (elem->>''nodeParent'')::int4 = '||v_feature_id||' AND '||rec||'_id = '||v_mapzone_id||')a 
				WHERE '||rec||'_id ='||v_mapzone_id||'';

			    END IF;
			END IF;
		   END IF;
		END LOOP;
	ELSE
		v_level = 0;
		INSERT INTO audit_check_data (fid, criticity, error_message)
		VALUES (359,1, concat('There is no mapzone to configure for  ', v_feature_type,' ', v_feature_id, '.'));
	END IF;

	SELECT  string_agg(error_message,' ') INTO v_result  FROM audit_check_data WHERE cur_user="current_user"() AND
	fid = 359;

	IF v_level IS NULL THEN
		v_level=3;
	END IF;

	v_result_info = v_result;

	--    Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result := COALESCE(v_result, '{}');

	v_result = concat ('{"values":',to_json(v_result), '}');

	--  Return
	RETURN ('{"status":"Accepted", "message":{"level":'||v_level||', "text":"'||v_result_info||'"}, "version":"'||v_version||'"'||
		     ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result||'}'||
		    '}'||
		'}')::json;

	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;


END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

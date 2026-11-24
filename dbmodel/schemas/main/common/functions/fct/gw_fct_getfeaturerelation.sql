/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2725

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getfeaturerelation(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getfeaturerelation(p_data json)
RETURNS json AS
$BODY$

/*

SELECT SCHEMA_NAME.gw_fct_getfeaturerelation($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{"type":"ARC"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_id":"2076562"}}$$);

SELECT SCHEMA_NAME.gw_fct_getfeaturerelation($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{"type":"ARC"},
"data":{"feature_id":"2098" }}$$);

SELECT SCHEMA_NAME.gw_fct_getfeaturerelation($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{"type":"NODE"},
"data":{"feature_id":"1051"}}$$);

SELECT SCHEMA_NAME.gw_fct_getfeaturerelation($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{"type":"CONNEC"},
"data":{"feature_id":"3254" }}$$);

-- fid: 151

*/

DECLARE

v_feature_type text;
v_feature_id integer;
v_workcat_id_end text;
v_enddate text;
v_descript text;
v_project_type text;
v_connect_connec text;
v_connect_gully text;
v_connect_node text;
v_element text;
v_visit text;
v_doc text;
v_psector text;
v_connect_arc text;
v_version text;
v_result_id text= 'feature relations';
v_result_info text;
v_result text;
v_man_table text;
v_featurecat text;
v_connect_pol text;
v_error_context text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;
	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- manage log (fid: 151)
	DELETE FROM audit_check_data WHERE fid = 151 AND cur_user=current_user;
	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2725", "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true, "is_header":"true"}}$$)';

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	--get information about feature
	v_feature_type = lower(((p_data ->>'feature')::json->>'type'))::text;
	v_feature_id = ((p_data ->>'data')::json->>'feature_id')::text;

	EXECUTE 'SELECT '||v_feature_type||'_type FROM ve_'||v_feature_type||' WHERE '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_featurecat;

	EXECUTE 'SELECT man_table FROM cat_feature_'||v_feature_type||' c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE s.id = '''||v_featurecat||''';'
	INTO v_man_table;

	IF v_feature_type='arc' THEN
		--check connec& gully related to arc
		SELECT array_agg(feature_id) INTO v_connect_connec FROM v_ui_arc_x_relations
		JOIN sys_feature_class ON sys_feature_class.id=v_ui_arc_x_relations.sys_type WHERE type='CONNEC' AND  arc_id = v_feature_id;

		IF v_connect_connec IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3676", "function":"2725", "parameters":{"v_connect_connec":"'||v_connect_connec||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		SELECT array_agg(feature_id) INTO v_connect_gully FROM v_ui_arc_x_relations
		JOIN sys_feature_class ON sys_feature_class.id=v_ui_arc_x_relations.sys_type WHERE type='GULLY' AND  arc_id = v_feature_id;

		IF v_connect_gully IS NOT NULL THEN

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3678", "function":"2725", "parameters":{"v_connect_gully":"'||v_connect_gully||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

		END IF;

		--check final nodes related to arc
		SELECT concat(node_1,',',node_2) INTO v_connect_node FROM ve_arc
		LEFT JOIN node a ON a.node_id::text = ve_arc.node_1::text
     	LEFT JOIN node b ON b.node_id::text = ve_arc.node_2::text
     	WHERE ve_arc.arc_id = v_feature_id;

		IF v_connect_node IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3680", "function":"2725", "parameters":{"v_connect_node":"'||v_connect_node||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;

	ELSIF v_feature_type='node' THEN
		--check nodes childs related to node

		IF v_project_type = 'WS' THEN
		 	SELECT array_agg(child_id) INTO v_connect_node FROM v_ui_node_x_relations WHERE node_id = v_feature_id;

			IF v_connect_node IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3682", "function":"2725", "parameters":{"v_connect_node":"'||v_connect_node||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;
		END IF;

		--check arcs related to node (on service)
		SELECT array_agg(arc.arc_id)  INTO v_connect_arc FROM arc
		LEFT JOIN node a ON a.node_id::text = arc.node_1::text
     	LEFT JOIN node b ON b.node_id::text = arc.node_2::text
     	WHERE (node_1 = v_feature_id OR node_2 = v_feature_id) AND arc.state=1;

		IF v_connect_arc IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3684", "function":"2725", "parameters":{"v_connect_arc":"'||v_connect_arc||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--check arcs related to node (obsolete)
		SELECT array_agg(arc.arc_id)  INTO v_connect_arc FROM arc
		LEFT JOIN node a ON a.node_id::text = arc.node_1::text
     	LEFT JOIN node b ON b.node_id::text = arc.node_2::text
     	WHERE  (node_1 = v_feature_id OR node_2 = v_feature_id) AND arc.state=0;

		IF v_connect_arc IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3686", "function":"2725", "parameters":{"v_connect_arc":"'||v_connect_arc||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--check links exiting on the node
		SELECT string_agg(link_id::text, ',') INTO v_connect_connec FROM link
		WHERE exit_type = 'NODE' AND exit_id::text = v_feature_id::text;

		IF v_connect_connec IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3690", "function":"2725", "parameters":{"v_connect_connec":"'||v_connect_connec||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--check related polygon
		EXECUTE 'SELECT pol_id FROM polygon where feature_id= '||v_feature_id||';'
		INTO v_connect_pol;

		IF v_connect_pol IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3688", "function":"2725", "parameters":{"v_connect_pol":"'||v_connect_pol||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

	ELSIF v_feature_type='connec' OR v_feature_type='gully' THEN
		EXECUTE 'SELECT string_agg(link_id::text,'','') FROM link where (exit_type=''CONNEC''  AND  exit_id = '||v_feature_id||')
		OR  (feature_type=''CONNEC''  AND  feature_id = '||v_feature_id||')'
		INTO v_connect_connec;

		IF v_connect_connec IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3690", "function":"2725", "parameters":{"v_connect_connec":"'||v_connect_connec||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		EXECUTE 'SELECT string_agg(link_id::text,'','') FROM link where exit_type=''GULLY''  AND  exit_id = '||v_feature_id||'
		OR  (feature_type=''GULLY''  AND  feature_id = '||v_feature_id||')'
		INTO v_connect_gully;

		IF v_connect_gully IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3692", "function":"2725", "parameters":{"v_connect_gully":"'||v_connect_gully||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--check related polygon
		EXECUTE 'SELECT pol_id FROM polygon where feature_id= '||v_feature_id||';'
		INTO v_connect_pol;

		IF v_connect_pol IS NOT NULL THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3480", "function":"2725", "parameters":{"v_connect_gully":"'||v_connect_gully||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

	END IF;

	--check elements related to feature
	EXECUTE 'SELECT array_agg(element_id) FROM element_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_element;

	IF v_element IS NOT NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3518", "function":"2725", "parameters":{"v_element":"'||v_element||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
	END IF;
	--check visits related to feature
	EXECUTE 'SELECT string_agg(visit_id::text,'','') FROM om_visit_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_visit;

	IF v_visit IS NOT NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3520", "function":"2725", "parameters":{"v_visit":"'||v_visit||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
	END IF;

	--check documents related to feature
	EXECUTE 'SELECT string_agg(doc_id::text,'','') FROM doc_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_doc;

	IF v_doc IS NOT NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3522", "function":"2725", "parameters":{"v_doc":"'||v_doc||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
	END IF;

	--check psectors related to feature
	IF v_feature_type='node' THEN
		EXECUTE 'SELECT string_agg(distinct a.name, '', '') FROM (
		SELECT name FROM plan_psector_x_node
		JOIN plan_psector USING (psector_id) where node_id = '||v_feature_id||' 
		UNION 
		SELECT name FROM plan_psector_x_arc
		JOIN plan_psector USING (psector_id) 
		JOIN arc using (arc_id) 
		where node_1 =  '||v_feature_id||' or node_2= '||v_feature_id||'  and arc.state=2)a'
		INTO v_psector;
	ELSE

		EXECUTE 'SELECT string_agg(name,'', '') FROM plan_psector_x_'||v_feature_type||' 
		JOIN plan_psector USING (psector_id) where '||v_feature_type||'_id = '||v_feature_id||''
		INTO v_psector;
	END IF;

	IF v_psector IS NOT NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3524", "function":"2725", "parameters":{"v_psector":"'||v_psector||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3526", "function":"2725", "parameters":{"v_psector":"'||v_psector||'"}, "fid":"151", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
	END IF;

	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message AS message FROM audit_check_data WHERE cur_user="current_user"() AND fid = 151) row;

	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_version := COALESCE(v_version, '');
	v_result_info := COALESCE(v_result_info, '{}');

	RETURN ('{"status":"Accepted", "version":"'||v_version||'"'||
            ',"message":{"level":1, "text":""},"body":{"data": {"info":'||v_result_info||'}}}')::json;

	-- Exception control
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

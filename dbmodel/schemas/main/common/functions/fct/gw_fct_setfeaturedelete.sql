/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2736

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_set_delete_feature(json);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_feature_delete(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setfeaturedelete(p_data json)
RETURNS json AS

$BODY$

/*
-- MODE 1: individual
SELECT SCHEMA_NAME.gw_fct_setfeaturedelete($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"type":"NODE"},
"data":{"feature_id":"42"}}$$);

SELECT SCHEMA_NAME.gw_fct_setfeaturedelete($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"type":"CONNEC"},
"data":{"feature_id":"3244"}}$$);

SELECT SCHEMA_NAME.gw_fct_setfeaturedelete($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"type":"ARC"},"data":{"feature_id":"2002"}}$$);

-- MODE 2: massive usign pure SQL
SELECT SCHEMA_NAME.gw_fct_setfeaturedelete(CONCAT('
{"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"type":"NODE"},"data":{"feature_id":"',node_id,'"}}')::json) FROM ... WHERE...;

-- fid: 152

*/

DECLARE

v_version text;
v_feature_type text;
v_feature_id integer;
v_arc_id text;
v_project_type text;
v_result_id text= 'delete feature';
v_result_info text;
v_result text;
v_connec_id text;
v_featurecat text;
v_man_table text;
v_error_context text;
v_count integer;
v_related_id text;
v_feature_childview_name text;
v_feature_childtable_name text;
v_schemaname text;
v_plan_psector_current text;
v_feature_state integer;
v_feature_psector_id text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

		--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

 	UPDATE config_param_user SET value = 'TRUE' WHERE parameter = 'edit_arc_downgrade_force' AND cur_user=current_user;

	-- manage log (fid: 152)
	DELETE FROM audit_check_data WHERE fid = 152 AND cur_user=current_user;
	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2736", "fid":"152", "result_id":"'||COALESCE(v_result_id, null)||'", "is_process":true, "is_header":"true"}}$$)';

 	--get information about feature
	v_feature_type = lower(((p_data ->>'feature')::json->>'type'))::text;
	v_feature_id = ((p_data ->>'data')::json->>'feature_id')::integer;

	-- get current plan psector
	EXECUTE 'SELECT value FROM config_param_user WHERE parameter = ''plan_psector_current'' AND cur_user = ''' || current_user || ''''
	INTO v_plan_psector_current;
	-- get feature state
	EXECUTE 'SELECT state FROM '||v_feature_type||' WHERE '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_feature_state;

	-- validate feature state and current mode
	IF v_feature_state = 2 AND v_plan_psector_current IS NULL THEN
		-- planified features in operative mode
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4412", "function":"3516", "is_process":true}}$$)';
	ELSIF v_feature_state = 2 AND v_plan_psector_current IS NOT NULL THEN
		-- planified features in plan mode
		-- get feature psector id
		EXECUTE 'SELECT psector_id FROM plan_psector_x_'||v_feature_type||' WHERE '||v_feature_type||'_id = '||v_feature_id||''
		INTO v_feature_psector_id;
		-- validate psector id
		IF v_feature_psector_id != v_plan_psector_current THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4414", "function":"3516", "is_process":true}}$$)';
		END IF;
	ELSEIF v_feature_state != 2 AND v_plan_psector_current IS NOT NULL THEN
		-- operative features in plan mode
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4416", "function":"3516", "is_process":true}}$$)';
	END IF;

	EXECUTE 'SELECT '||v_feature_type||'_type FROM ve_'||v_feature_type||' WHERE '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_featurecat;
	v_feature_childview_name := 've_' || v_feature_type || '_' || lower(v_featurecat);

	IF v_feature_type!='gully' THEN
		EXECUTE 'SELECT man_table FROM cat_feature_'||v_feature_type||' c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id WHERE s.id = '''||v_featurecat||''';'
		INTO v_man_table;
	END IF;

	--check and remove elements related to feature
	EXECUTE 'SELECT count(*) FROM element_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_count;

	IF v_count > 0 THEN
		EXECUTE 'DELETE FROM element_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||';';
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3436", "function":"2736", "parameters":{"v_count":"'||v_count||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
	END IF;

	--check and remove visits related to feature
	EXECUTE 'SELECT count(*) FROM om_visit_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_count;

	IF v_count > 0 THEN
		EXECUTE 'DELETE FROM om_visit_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||';';
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3438", "function":"2736", "parameters":{"v_count":"'||v_count||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
	END IF;

	--check and remove docs related to feature
	EXECUTE 'SELECT count(*) FROM doc_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||''
	INTO v_count;

	IF v_count > 0 THEN
		EXECUTE 'DELETE FROM doc_x_'||v_feature_type||' where '||v_feature_type||'_id = '||v_feature_id||';';
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3482", "function":"2736", "parameters":{"v_count":"'||v_count||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
	END IF;

	--update position_id related to node
	EXECUTE 'SELECT count(*) FROM om_visit_event where position_id = '''||v_feature_id||''';'
	INTO v_count;

	IF v_count > 0 THEN
		EXECUTE 'UPDATE om_visit_event SET position_id = NULL where position_id = '''||v_feature_id||''';';
	END IF;

	IF v_feature_type='node' THEN

		IF v_project_type = 'WS' THEN
			--remove scada related to node
			EXECUTE 'SELECT count(*) FROM ext_rtc_scada where node_id = '||v_feature_id||''
			INTO v_count;

			IF v_count > 0 THEN
				EXECUTE 'DELETE FROM ext_rtc_scada where node_id = '||v_feature_id||';';
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3484", "function":"2736", "parameters":{"v_count":"'||v_count||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;
		END IF;

		--remove link related to node
		EXECUTE 'SELECT count(*) FROM ve_link where exit_type=''NODE'' and exit_id = '||v_feature_id||''
		INTO v_count;

		IF v_count > 0 THEN
			EXECUTE 'DELETE FROM ve_link WHERE exit_type=''NODE'' and exit_id = '||v_feature_id||';';
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3486", "function":"2736", "parameters":{"v_count":"'||v_count||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--remove parent related to node
		IF v_project_type = 'WS' THEN
			EXECUTE 'SELECT parent_id FROM node where parent_id IS NOT NULL AND node_id = '||v_feature_id||''
			into v_related_id;

			IF v_related_id IS NOT NULL THEN
				EXECUTE 'UPDATE node SET parent_id=NULL WHERE node_id = '||v_feature_id||';';
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3488", "function":"2736", "parameters":{"v_related_id":"'||v_related_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;
		END IF;

		--delete related polygon
		EXECUTE 'SELECT pol_id FROM polygon WHERE feature_id = '||v_feature_id||' AND featurecat_id = '''||v_featurecat||''';'
		into v_related_id;

		IF v_related_id IS NOT NULL THEN
			 	EXECUTE 'DELETE FROM polygon WHERE feature_id = '||v_feature_id||' AND featurecat_id = '''||v_featurecat||''';';
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3490", "function":"2736", "parameters":{"v_related_id":"'||v_related_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;

		--find if there is an arc related to node
		SELECT array_agg(arc.arc_id)  INTO v_arc_id FROM arc
		LEFT JOIN node a ON a.node_id = arc.node_1
     	LEFT JOIN node b ON b.node_id = arc.node_2
     	WHERE  (node_1 = v_feature_id OR node_2 = v_feature_id);

		IF v_arc_id IS NULL THEN
			--delete node
			EXECUTE 'DELETE FROM '||v_feature_childview_name||' WHERE node_id='||v_feature_id||';';

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3492", "function":"2736", "parameters":{"v_feature_id":"'||v_feature_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		ELSE
			--set final nodes to NULL and delete node
			IF v_project_type = 'WS' THEN
				EXECUTE'UPDATE arc SET node_1=NULL, nodetype_1=NULL, elevation1=NULL, depth1=NULL, staticpressure1 = NULL WHERE node_1='||v_feature_id||';';
				EXECUTE'UPDATE arc SET node_2=NULL, nodetype_2=NULL, elevation2=NULL, depth2=NULL, staticpressure2 = NULL WHERE node_2='||v_feature_id||';';
			ELSE
				EXECUTE'UPDATE arc SET node_1=NULL, nodetype_1=NULL, node_top_elev_1=NULL, node_elev_1=NULL, node_custom_top_elev_1=NULL, node_custom_elev_1=NULL WHERE node_1='||v_feature_id||';';
				EXECUTE'UPDATE arc SET node_2=NULL, nodetype_2=NULL, node_top_elev_2=NULL, node_elev_2=NULL, node_custom_top_elev_2=NULL, node_custom_elev_2=NULL WHERE node_2='||v_feature_id||';';
			END IF;
			EXECUTE 'DELETE FROM '||v_feature_childview_name||' WHERE node_id='||v_feature_id||';';

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3494", "function":"2736", "parameters":{"v_arc_id":"'||v_arc_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3492", "function":"2736", "parameters":{"v_feature_id":"'||v_feature_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;


	ELSIF v_feature_type='arc' THEN
		--remove links related to arc
		EXECUTE 'SELECT count(*) FROM ve_link WHERE feature_type=''CONNEC'' AND feature_id IN 
		(SELECT connec_id FROM connec  WHERE connec.arc_id='||v_feature_id||');'
		INTO v_count;

		IF v_count > 0 THEN
			EXECUTE 'DELETE FROM ve_link WHERE feature_type=''CONNEC'' AND feature_id IN (SELECT connec_id FROM connec  WHERE connec.arc_id='||v_feature_id||');';
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3496", "function":"2736", "parameters":{"v_count":"'||v_count||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--set arc_id to null if there are connecs related
		EXECUTE 'SELECT string_agg(connec_id::text,'','') FROM connec WHERE arc_id='||v_feature_id||''
		INTO v_related_id;

		IF v_related_id IS NOT NULL THEN
			EXECUTE 'UPDATE connec SET arc_id=NULL WHERE arc_id='||v_feature_id||';';
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3498", "function":"2736", "parameters":{"v_related_id":"'||v_related_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		IF v_project_type = 'WS' THEN
			--remove arc_id reference from inlet_arc if there are man_valve related
			EXECUTE 'UPDATE man_source SET inlet_arc = array_remove(inlet_arc, '||quote_literal(v_feature_id)||') WHERE '||quote_literal(v_feature_id)||'=ANY(inlet_arc);';
			EXECUTE 'UPDATE man_tank SET inlet_arc = array_remove(inlet_arc, '||quote_literal(v_feature_id)||') WHERE '||quote_literal(v_feature_id)||'=ANY(inlet_arc);';
			EXECUTE 'UPDATE man_wtp SET inlet_arc = array_remove(inlet_arc, '||quote_literal(v_feature_id)||') WHERE '||quote_literal(v_feature_id)||'=ANY(inlet_arc);';
			EXECUTE 'UPDATE man_waterwell SET inlet_arc = array_remove(inlet_arc, '||quote_literal(v_feature_id)||') WHERE '||quote_literal(v_feature_id)||'=ANY(inlet_arc);';

			--set to_arc to null if there are man_valve related
			EXECUTE 'UPDATE man_valve SET to_arc = NULL WHERE to_arc = '||v_feature_id||';';
			EXECUTE 'UPDATE man_pump SET to_arc = NULL WHERE to_arc = '||v_feature_id||';';
			EXECUTE 'UPDATE man_meter SET to_arc = NULL WHERE to_arc = '||v_feature_id||';';
		END IF;

		--set arc_id to null if there are nodes related
		EXECUTE 'SELECT string_agg(node_id::text,'','') FROM node WHERE arc_id='||v_feature_id||''
		INTO v_related_id;

		IF v_related_id IS NOT NULL THEN
			EXECUTE 'UPDATE node SET arc_id=NULL WHERE arc_id='||v_feature_id||';';
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3500", "function":"2736", "parameters":{"v_related_id":"'||v_related_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--set arc_id to null if there are gullies related
		IF v_project_type='UD' THEN

			--remove links related to arc
			EXECUTE 'SELECT count(*) FROM ve_link WHERE feature_type=''GULLY'' AND feature_id IN 
			(SELECT gully_id FROM gully  WHERE gully.arc_id='||v_feature_id||');'
			INTO v_count;

			IF v_count > 0 THEN
				EXECUTE 'DELETE FROM ve_link WHERE feature_type=''GULLY'' AND feature_id IN (SELECT gully_id FROM gully  WHERE gully.arc_id='||v_feature_id||');';
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3502", "function":"2736", "parameters":{"v_count":"'||v_count||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;

			EXECUTE 'SELECT string_agg(gully_id::text,'','') FROM gully WHERE arc_id='||v_feature_id||''
			INTO v_related_id;

			EXECUTE'UPDATE gully SET arc_id=NULL WHERE arc_id='||v_feature_id||';';
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3504", "function":"2736", "parameters":{"v_related_id":"'||quote_nullable(v_related_id)||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
		END IF;

		--delete arc
		EXECUTE 'DELETE FROM '||v_feature_childview_name||' WHERE arc_id='||v_feature_id||';';
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3508", "function":"2736", "parameters":{"v_feature_id":"'||v_feature_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

	ELSIF  v_feature_type='connec' OR v_feature_type='gully' THEN

		--check related polygon
		EXECUTE 'SELECT pol_id FROM polygon WHERE feature_id = '||v_feature_id||' AND featurecat_id = '''||v_featurecat||''';'
		into v_related_id;

		IF v_related_id IS NOT NULL THEN
			 	EXECUTE 'DELETE FROM polygon WHERE feature_id = '||v_feature_id||' AND featurecat_id = '''||v_featurecat||''';';

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3506", "function":"2736", "parameters":{"v_related_id":"'||v_related_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';
			END IF;

		--remove links related to connec/gully
		IF v_feature_type='connec' THEN
			EXECUTE 'SELECT string_agg(link_id::text,'','') FROM link where (exit_type=''CONNEC''  AND  exit_id = '||v_feature_id||')
			OR  (feature_type=''CONNEC''  AND  feature_id = '||v_feature_id||')'
			INTO v_related_id;
		ELSIF v_feature_type = 'gully' THEN
			EXECUTE 'SELECT string_agg(link_id::text,'','') FROM link where exit_type=''GULLY''  AND  exit_id = '||v_feature_id||'
			OR  (feature_type=''GULLY''  AND  feature_id = '||v_feature_id||')'
			INTO v_related_id;
		END IF;

		IF v_related_id IS NOT NULL THEN
			EXECUTE 'DELETE FROM ve_link WHERE feature_type='''||UPPER(v_feature_type)||''' AND feature_id ='||v_feature_id||';';
	  		EXECUTE 'DELETE FROM ve_link WHERE feature_type='''||UPPER(v_feature_type)||''' AND exit_id ='||v_feature_id||';';

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3510", "function":"2736", "parameters":{"v_related_id":"'||v_related_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';


		END IF;

		--delete feature
		EXECUTE 'DELETE FROM '||v_feature_childview_name||' WHERE '||v_feature_type||'_id='||v_feature_id||';';

		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3512", "function":"2736", "parameters":{"v_feature_type":"'||v_feature_type||'", "v_feature_id":"'||v_feature_id||'"}, "fid":"152", "result_id":"'||quote_nullable(v_result_id)||'", "is_process":true}}$$)';

	END IF;

 	--delete addfields values
	v_feature_childtable_name := 'man_' || v_feature_type || '_' || lower(v_featurecat);

	IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = v_schemaname AND table_name = v_feature_childtable_name)) IS TRUE THEN
        EXECUTE 'DELETE FROM '||v_feature_childtable_name||' WHERE '||concat(v_feature_type,'_id')||'='||v_feature_id||';';
    END IF;

 	UPDATE config_param_user SET value = 'FALSE' WHERE parameter = 'edit_arc_downgrade_force' AND cur_user=current_user;

 	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message AS message FROM audit_check_data WHERE cur_user="current_user"() AND fid = 152)
	row;

	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	-- Control nulls
	v_version := COALESCE(v_version, '');
	v_result_info := COALESCE(v_result_info, '{}');

    RETURN ('{"status":"Accepted", "version":"'||v_version||'"'||
             ',"message":{"level":1, "text":""},"body":{"data": {"info":'||v_result_info||'}}}')::json;

	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

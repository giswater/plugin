/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3284

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_psector_merge(p_data json)
RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_psector_merge($${
"client":{"device":4, "lang":"ca_ES", "infoType":1, "epsg":SRID_VALUE},
"form":{}, "feature":{},
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{"psector_ids":"1, 3", "new_psector_name":"merged_psector"}}}$$);

-- fid: 518

*/

DECLARE

v_version text;
v_arc_id TEXT;
v_project_type text;
v_result_id text= 'merge psectors';
v_result_name text;
v_result_info text;
v_result text;
v_connec_id text;
v_old_psector_id integer;
v_old_psector_ids text;
v_psector_ids int[];
v_psector_id int;
v_new_psector_id integer;
v_new_psector_name text;
v_field_id text;

v_count integer;
rec record;
rec_type record;

v_insert_fields text;
v_type record;
v_connec_proximity json;
v_gully_proximity json;
v_sql text;
v_psector_vdefault text;
v_schemaname text;
v_list_features_obsolete text;
v_list_connec_undoable text;
v_list_gully_undoable text;
v_list_arc_new text;
v_list_connec_doable text;
v_list_gully_doable text;
v_error_context text;
v_connecautolink text;
v_gullyautolink text;
v_subquery text;
v_id_last text;
v_querytext text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;
	-- get input parameters
	v_schemaname = 'SCHEMA_NAME';

	SELECT project_type, giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- manage log (fid: 518)
	DELETE FROM audit_check_data WHERE fid=518 AND cur_user=current_user;
	-- 4786 is the process name getmessage splices into the error prefix (AUDIT + prefix_id).
	SELECT replace(error_message, '"', '') INTO v_result_name FROM v_sys_message WHERE id = 4786;
	v_result_name := COALESCE(v_result_name, v_result_id);

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"4784", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "is_process":true}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "separator_id":"2030", "is_process":true}}$$)';

	-- disable arc divide temporary
	UPDATE config_param_user SET value = 'TRUE'  WHERE "parameter"='edit_disable_arc_divide' AND cur_user=current_user;

	
    -- insert connec2network variable for user in case it doesn't exist
    INSERT INTO config_param_user VALUES('edit_connec_automatic_link', 'false', current_user) ON CONFLICT (parameter, cur_user) DO NOTHING;
    IF v_project_type='UD' THEN
        INSERT INTO config_param_user VALUES('edit_gully_automatic_link', 'false', current_user) ON CONFLICT (parameter, cur_user) DO NOTHING;
    END IF;
    -- save value for automatic connect2network and set true in order to automatically connect new feature
    SELECT value INTO v_connecautolink FROM config_param_user WHERE parameter='edit_connec_automatic_link' AND cur_user=current_user;
    SELECT value INTO v_gullyautolink FROM config_param_user WHERE parameter='edit_gully_automatic_link' AND cur_user=current_user;
    UPDATE config_param_user SET value='false' WHERE parameter IN ('edit_connec_automatic_link', 'edit_gully_automatic_link') AND cur_user=current_user;

	UPDATE  config_param_system SET value = gw_fct_json_object_set_key(v_connec_proximity::json, 'activated'::text, 'false'::text) WHERE parameter='edit_connec_proximity';
	UPDATE  config_param_system SET value = gw_fct_json_object_set_key(v_gully_proximity::json, 'activated'::text, 'false'::text) WHERE parameter='edit_gully_proximity';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3778", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	--capture input values
 	v_old_psector_ids = ((((p_data ->>'data')::json)->>'parameters')::json->>'psector_ids')::text;
	v_new_psector_name = ((((p_data ->>'data')::json)->>'parameters')::json->>'new_psector_name')::text;
 	v_psector_ids = string_to_array(v_old_psector_ids, ',')::int[];

	SELECT COUNT (*) INTO v_count FROM (SELECT priority, status, psector_type, expl_id FROM plan_psector
	WHERE psector_id = ANY(v_psector_ids)
	GROUP BY priority, status, psector_type, expl_id) AS a;

	IF v_count > 1 THEN
		INSERT INTO audit_check_data (fid, result_id, error_message)
		VALUES (518, v_result_id, '');
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3780", "function":"3284", "fid":"518", "result_id":"'||v_result_name||'", "prefix_id":"1003", "is_process":true}}$$)';

		INSERT INTO audit_check_data (fid, result_id, error_message)
		VALUES (518, v_result_id, '');
	END IF;

	IF v_count = 1 THEN
		v_old_psector_id = v_psector_ids[1];

		--copy psector definition, update plan selector and psector vdefault
	 	INSERT INTO plan_psector (name, psector_type, expl_id, priority)
	 	SELECT v_new_psector_name, psector_type, expl_id, priority
	 	FROM plan_psector WHERE psector_id=v_old_psector_id RETURNING psector_id INTO v_new_psector_id;

		--INSERT INTO audit_check_data (fid, result_id, error_message)
		--VALUES (518, v_result_id, concat('Create psector ',v_new_psector_id,' as ',v_new_psector_name,'.' ));
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3782", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_new_psector_id":"'||v_new_psector_id||'", "v_new_psector_name":"'||v_new_psector_name||'"}, "is_process":true}}$$)';


		SELECT value INTO v_psector_vdefault FROM config_param_user where parameter = 'plan_psector_current' and cur_user=current_user;

		IF v_psector_vdefault IS NULL THEN
			INSERT INTO config_param_user (parameter,value, cur_user) VALUES ('plan_psector_current', v_new_psector_id, current_user) ON CONFLICT (parameter, cur_user) DO NOTHING;
		ELSE
			UPDATE config_param_user SET value=v_new_psector_id WHERE parameter='plan_psector_current' and cur_user=current_user;
		END IF;

		--copy arcs with state 0 inside plan_psector tables
		SELECT string_agg(DISTINCT arc_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_arc  WHERE psector_id= ANY(v_psector_ids) AND state=0;

		IF v_list_features_obsolete IS NOT NULL THEN
			UPDATE config_param_user SET value='false' WHERE parameter='edit_plan_order_control' AND cur_user=current_user;
			PERFORM setval('SCHEMA_NAME.plan_psector_x_arc_id_seq', (select max(id) from plan_psector_x_arc) , true);
			INSERT INTO plan_psector_x_arc(arc_id, psector_id, state, doable, descript, addparam)
			SELECT DISTINCT ON (arc_id) arc_id, v_new_psector_id, state, doable, descript, addparam FROM plan_psector_x_arc
			WHERE psector_id=ANY(v_psector_ids) AND state=0;

			UPDATE config_param_user SET value='true' WHERE parameter='edit_plan_order_control' AND cur_user=current_user;
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3784", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_list_features_obsolete":"'||v_list_features_obsolete||'"}, "is_process":true}}$$)';

		END IF;

		--copy nodes with state 0 inside plan_psector tables
		SELECT string_agg(node_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_node  WHERE psector_id=ANY(v_psector_ids) AND state=0;

		IF v_list_features_obsolete IS NOT NULL THEN
			PERFORM setval('SCHEMA_NAME.plan_psector_x_node_id_seq', (select max(id) from plan_psector_x_node) , true);
			INSERT INTO plan_psector_x_node(node_id, psector_id, state, doable, descript)
			SELECT DISTINCT ON (node_id) node_id, v_new_psector_id, state, doable, descript FROM plan_psector_x_node
			WHERE psector_id=ANY(v_psector_ids) AND state=0;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3786", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_list_features_obsolete":"'||v_list_features_obsolete||'"}, "is_process":true}}$$)';
		END IF;

		--copy connecs with state 0 inside plan_psector tables
		SELECT string_agg(connec_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_connec WHERE psector_id=ANY(v_psector_ids) AND state=0;

		IF v_list_features_obsolete IS NOT NULL THEN
			PERFORM setval('SCHEMA_NAME.plan_psector_x_connec_id_seq', (select max(id) from plan_psector_x_connec) , true);
			INSERT INTO plan_psector_x_connec(connec_id, psector_id, state, doable, descript, arc_id, link_id)
			SELECT DISTINCT ON (connec_id) connec_id, v_new_psector_id, 0, false, descript, arc_id, link_id FROM plan_psector_x_connec
			WHERE psector_id=ANY(v_psector_ids) AND state=0 ON CONFLICT (psector_id, connec_id, state) DO NOTHING;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3788", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_list_features_obsolete":"'||v_list_features_obsolete||'"}, "is_process":true}}$$)';

		END IF;

		--copy connecs with state 1 inside plan_psector tables
		SELECT string_agg(connec_id::text,',') INTO v_list_connec_undoable FROM plan_psector_x_connec WHERE psector_id=ANY(v_psector_ids) AND state=1 AND doable=false;

		IF v_list_connec_undoable IS NOT NULL THEN
			PERFORM setval('SCHEMA_NAME.plan_psector_x_connec_id_seq', (select max(id) from plan_psector_x_connec) , true);
			INSERT INTO plan_psector_x_connec(connec_id, psector_id, state, doable, descript)
			SELECT DISTINCT ON (connec_id) connec_id, v_new_psector_id, 1, false, descript FROM plan_psector_x_connec
			WHERE psector_id=ANY(v_psector_ids) AND state=1 AND doable=false ON CONFLICT (psector_id, connec_id, state) DO NOTHING;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3790", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_list_connec_undoable":"'||v_list_connec_undoable||'"}, "is_process":true}}$$)';

		END IF;

		IF v_project_type='UD' THEN
			--copy gullies with state 0 inside plan_psector tables
			SELECT string_agg(gully_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_gully WHERE psector_id=ANY(v_psector_ids) AND state=0;
			IF v_list_features_obsolete IS NOT NULL THEN
				PERFORM setval('SCHEMA_NAME.plan_psector_x_gully_id_seq', (select max(id) from plan_psector_x_gully) , true);
				INSERT INTO plan_psector_x_gully(gully_id, psector_id, state, doable, descript, arc_id, link_id)
				SELECT DISTINCT ON (gully_id) gully_id, v_new_psector_id, state, doable, descript, arc_id, link_id FROM plan_psector_x_gully
				WHERE psector_id=ANY(v_psector_ids) AND state=0 ON CONFLICT (psector_id, gully_id, state) DO NOTHING;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3792", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_list_features_obsolete":"'||v_list_features_obsolete||'"}, "is_process":true}}$$)';

			END IF;

			--copy gullies with state 1 inside plan_psector tables
			SELECT string_agg(gully_id::text,',') INTO v_list_gully_undoable FROM plan_psector_x_gully WHERE psector_id=ANY(v_psector_ids) AND state=1 AND doable=false;

			IF v_list_gully_undoable IS NOT NULL THEN
				PERFORM setval('SCHEMA_NAME.plan_psector_x_gully_id_seq', (select max(id) from plan_psector_x_gully) , true);
				INSERT INTO plan_psector_x_gully(gully_id, psector_id, state, doable, descript)
				SELECT DISTINCT ON (gully_id) gully_id, v_new_psector_id, 1, false, descript FROM plan_psector_x_gully
				WHERE psector_id=ANY(v_psector_ids) AND state=1 AND doable=false ON CONFLICT (psector_id, gully_id, state) DO NOTHING;

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3794", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_list_gully_undoable":"'||v_list_gully_undoable||'"}, "is_process":true}}$$)';
			END IF;
		END IF;

		--copy features inside plan_psector tables
		SELECT string_agg(price_id,',') INTO v_list_features_obsolete FROM plan_psector_x_other WHERE psector_id=ANY(v_psector_ids);
		IF v_list_features_obsolete IS NOT NULL THEN
			PERFORM setval('SCHEMA_NAME.plan_psector_x_other_id_seq', (SELECT max(id) FROM plan_psector_x_other), true);
			-- same price_id on several source psectors becomes one row; measurements add up
			INSERT INTO plan_psector_x_other(price_id, measurement, psector_id, observ, the_geom)
			SELECT price_id, sum(measurement), v_new_psector_id,
				(array_agg(observ ORDER BY id) FILTER (WHERE observ IS NOT NULL))[1],
				(array_agg(the_geom ORDER BY id) FILTER (WHERE the_geom IS NOT NULL))[1]
			FROM plan_psector_x_other
			WHERE psector_id = ANY(v_psector_ids)
			GROUP BY price_id;

			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3796", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_list_features_obsolete":"'||v_list_features_obsolete||'"}, "is_process":true}}$$)';

		END IF;

		-- delete all current selected psectors
		DELETE FROM selector_psector WHERE cur_user=current_user;

		--insert copy of the planified feature in the corresponding ve_* view and insert it into plan_psector_x_* table
		FOR rec_type IN (SELECT * FROM sys_feature_type WHERE classlevel=1 OR classlevel = 2 ORDER BY CASE
			WHEN id='NODE' THEN 1
			WHEN id='ARC' THEN 2
			WHEN id='CONNEC' THEN 3
			WHEN id='GULLY' THEN 4 END) LOOP

			EXECUTE 'SELECT DISTINCT string_agg(column_name::text,'' ,'')
			FROM information_schema.columns where table_name=''ve_'||lower(rec_type.id)||''' and table_schema='''||v_schemaname||'''
			and column_name IN (SELECT column_name FROM information_schema.columns where table_name='''||lower(rec_type.id)||''' and table_schema='''||v_schemaname||''') 
			AND column_name!='''||lower(rec_type.id)||'_id'' and column_name!=''state'' and column_name != ''node_1'' and  column_name != ''node_2'' and column_name != ''code'';'
			INTO v_insert_fields;

			IF rec_type.id='CONNEC' OR rec_type.id='GULLY' THEN
				v_subquery = ' AND doable = true';
			ELSE
				v_subquery = '';
			END IF;

			FOR rec IN EXECUTE 'SELECT DISTINCT ON ('||lower(rec_type.id)||'_id) * FROM plan_psector_x_'||lower(rec_type.id)||' WHERE psector_id=ANY($1) and state=1 '||v_subquery||'' USING v_psector_ids LOOP
				IF rec_type.id='ARC' THEN
					v_field_id=rec.arc_id;
				ELSIF rec_type.id='NODE' THEN
					v_field_id=rec.node_id;
				ELSIF rec_type.id='CONNEC' THEN
					v_field_id=rec.connec_id;
				ELSIF rec_type.id='GULLY' THEN
					v_field_id=rec.gully_id;
				END IF;

				--activate topocontrol for arc, deactivate for other features
				if rec_type.id='arc' THEN
					UPDATE config_param_system SET value ='FALSE' WHERE parameter='edit_topocontrol_disable_error';
				ELSE
					UPDATE config_param_system SET value ='TRUE' WHERE parameter='edit_topocontrol_disable_error';
				END IF;

				v_querytext = 'INSERT INTO ve_'||lower(rec_type.id)||' ('||v_insert_fields||',state) SELECT '||v_insert_fields||',2 FROM '||lower(rec_type.id)||'
				WHERE '||lower(rec_type.id)||'_id='''||v_field_id||''';';
				EXECUTE v_querytext;
			END LOOP;

			EXECUTE 'SELECT string_agg('||lower(rec_type.id)||'_id::text,'','') FROM plan_psector_x_'||lower(rec_type.id)||' WHERE psector_id=ANY($1) and state=1'
			into v_list_features_obsolete USING v_psector_ids;

			IF v_list_features_obsolete IS NOT NULL THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3902", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"rec_type.id":"'||lower(rec_type.id)||'", "v_list_features_obsolete":"'||v_list_features_obsolete||'"}, "is_process":true}}$$)';

			END IF;

		END LOOP;

		-- delete old psector from selector and set new
		DELETE FROM selector_psector WHERE psector_id=ANY(v_psector_ids) AND cur_user=current_user;
		INSERT INTO selector_psector VALUES (v_new_psector_id, current_user) ON CONFLICT (psector_id, cur_user) DO NOTHING;
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3798", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "parameters":{"v_new_psector_name":"'||v_new_psector_name||'"}, "is_process":true}}$$)';

		-- select forced arcs to connect with
		SELECT string_agg(arc_id::text,',') INTO v_list_arc_new FROM plan_psector_x_arc WHERE psector_id=v_new_psector_id;

		IF v_list_connec_undoable IS NOT NULL AND v_list_arc_new IS NOT NULL THEN
			-- connect to network connecs with state 1 from v_list_connec_undoable
			EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
			"feature":{"id":"['||v_list_connec_undoable||']"},"data":{"feature_type":"CONNEC", "forcedArcs":['||v_list_arc_new||']}}$$)';
		END IF;

		IF v_project_type='UD' THEN
			IF v_list_gully_undoable IS NOT NULL AND v_list_arc_new IS NOT NULL THEN
				-- connect to network gullies with state 1 from v_list_gully_undoable
				EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
				"feature":{"id":"['||v_list_gully_undoable||']"},"data":{"feature_type":"GULLY", "forcedArcs":['||v_list_arc_new||']}}$$)';
			END IF;
		END IF;

		SELECT string_agg(connec_id::text,',') INTO v_list_connec_doable FROM plan_psector_x_connec WHERE psector_id=v_new_psector_id AND doable=true AND state=1 AND
		connec_id NOT IN (SELECT feature_id FROM link WHERE feature_type='CONNEC');

		IF v_list_connec_doable IS NOT NULL THEN
			-- connect to network connecs with state 1 from v_list_connec_doable
			EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
			"feature":{"id":"['||v_list_connec_doable||']"},"data":{"feature_type":"CONNEC"}}$$)';
		END IF;

		IF v_project_type='UD' THEN
	        SELECT string_agg(gully_id::text,',') INTO v_list_gully_doable FROM plan_psector_x_gully WHERE psector_id=v_new_psector_id AND doable=true AND state=1 AND
	        gully_id NOT IN (SELECT feature_id FROM link WHERE feature_type='GULLY');

	        IF v_list_gully_doable IS NOT NULL THEN
	            -- connect to network gullys with state 1 from v_list_gully_doable
	            EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
	            "feature":{"id":"['||v_list_gully_doable||']"},"data":{"feature_type":"GULLY"}}$$)';
	        END IF;
	    END IF;

	END IF;
	
	-- enable arc divide
	UPDATE config_param_user SET value = 'false'  WHERE "parameter"='edit_disable_arc_divide' AND cur_user=current_user;


	--activate the functions an set back the values of parameters
	UPDATE config_param_user SET value=v_connecautolink WHERE parameter='edit_connec_automatic_link' and cur_user=current_user;
	UPDATE config_param_user SET value=v_gullyautolink WHERE parameter='edit_gully_automatic_link' and cur_user=current_user;

	UPDATE config_param_system SET value = v_connec_proximity WHERE parameter='edit_connec_proximity';
	UPDATE config_param_system SET value = v_gully_proximity WHERE parameter='edit_gully_proximity';
	UPDATE config_param_system SET value ='FALSE' WHERE parameter='edit_topocontrol_disable_error';

	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"4782", "function":"3284", "fid":"518", "result_id":"'||v_result_id||'", "is_process":true}}$$)';

	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message AS message FROM audit_check_data WHERE cur_user="current_user"() AND fid=518) row;

	-- Control nulls
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');
	v_result_info := COALESCE(v_result_info, '{}');
	v_version := COALESCE(v_version, '');

	-- return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "version":"'||v_version||'"'||
            ',"message":{"level":1, "text":""},"body":{"data": {"info":'||v_result_info||'}}}')::json, 2734, null, null, null);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

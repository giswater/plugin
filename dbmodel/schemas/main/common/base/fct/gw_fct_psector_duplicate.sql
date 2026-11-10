/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2734

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_psector_duplicate(p_data json)
RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_psector_duplicate($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"type":"PSECTOR"},
"data":{"psector_id":"1","new_psector_name":"new_psector"}}$$);

-- fid: 153

*/

DECLARE

v_version text;
v_arc_id TEXT;
v_project_type text;
v_result_id text= 'duplicate psector';
v_result_info text;
v_result text;
v_connec_id text;
v_old_psector_id integer;
v_new_psector_id integer;
v_new_psector_name text;
v_field_id text;

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

	--capture input values
 	v_old_psector_id = ((p_data ->>'data')::json->>'psector_id')::text;
	v_new_psector_name = ((p_data ->>'data')::json->>'new_psector_name')::text;

	IF v_new_psector_name IN (SELECT name FROM plan_psector) THEN
		SELECT gw_fct_getmessage($${"data":{"message":"4752", "function":"2734", "is_process":true}}$$);
	END IF;

	-- manage log (fid: 153)
	DELETE FROM audit_check_data WHERE fid=153 AND cur_user=current_user;

	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"2734", "fid":"153", "result_id":"'||v_result_id||'", "is_process":true, "is_header":true}}$$)';

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

	INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Deactivate topology control for connecs and gullies.' ));

	-- disable arc divide temporary
	UPDATE config_param_user SET value = 'TRUE'  WHERE "parameter"='edit_disable_arc_divide' AND cur_user=current_user;

	--copy psector definition, update plan selector and psector vdefault
 	INSERT INTO plan_psector (name, psector_type, descript, expl_id, priority, text1, text2, observ, rotation, scale,  atlas_id, gexpenses,
 	vat, other, active, the_geom, enable_all, status, ext_code, text3, text4, text5, text6, num_value)
 	SELECT v_new_psector_name, psector_type, descript, expl_id, priority, text1, text2, observ, rotation, scale,  atlas_id, gexpenses,
 	vat, other, active, the_geom, enable_all, status, ext_code, text3, text4, text5, text6, num_value
 	FROM plan_psector WHERE psector_id=v_old_psector_id RETURNING psector_id INTO v_new_psector_id;

	INSERT INTO audit_check_data (fid, result_id, error_message)
	VALUES (153, v_result_id, concat('Copy psector ',v_old_psector_id,' as ',v_new_psector_name,'.' ));

	SELECT value INTO v_psector_vdefault FROM config_param_user where parameter = 'plan_psector_current' and cur_user=current_user;

	IF v_psector_vdefault IS NULL THEN
		INSERT INTO config_param_user (parameter,value, cur_user) VALUES ('plan_psector_current', v_new_psector_id, current_user);
	ELSE
		UPDATE config_param_user SET value=v_new_psector_id WHERE parameter='plan_psector_current' and cur_user=current_user;
	END IF;

	INSERT INTO audit_check_data (fid, result_id, error_message)
	VALUES (153, v_result_id, concat('Set source psector (',v_old_psector_id,') as current psector.' ));

	-- delete all current selected psectors
	DELETE FROM selector_psector WHERE cur_user=current_user;

	--copy arcs with state 0 inside plan_psector tables
	SELECT string_agg(arc_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_arc  WHERE psector_id=v_old_psector_id AND state=0;

	IF v_list_features_obsolete IS NOT NULL THEN
		UPDATE config_param_user SET value='false' WHERE parameter='edit_plan_order_control' AND cur_user=current_user;

		PERFORM setval('SCHEMA_NAME.plan_psector_x_arc_id_seq', (select max(id) from plan_psector_x_arc) , true);
		INSERT INTO plan_psector_x_arc(arc_id, psector_id, state, doable, descript, addparam)
		SELECT arc_id, v_new_psector_id, state, doable, descript, addparam FROM plan_psector_x_arc
		WHERE psector_id=v_old_psector_id AND state=0;

		UPDATE config_param_user SET value='true' WHERE parameter='edit_plan_order_control' AND cur_user=current_user;

		INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Copied arcs with state 0: ', v_list_features_obsolete ));
	END IF;

	--copy nodes with state 0 inside plan_psector tables
	SELECT string_agg(node_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_node  WHERE psector_id=v_old_psector_id AND state=0;

	IF v_list_features_obsolete IS NOT NULL THEN
		PERFORM setval('SCHEMA_NAME.plan_psector_x_node_id_seq', (select max(id) from plan_psector_x_node) , true);
		INSERT INTO plan_psector_x_node(node_id, psector_id, state, doable, descript)
		SELECT node_id, v_new_psector_id, state, doable, descript FROM plan_psector_x_node
		WHERE psector_id=v_old_psector_id AND state=0;

		INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Copied nodes with state 0: ', v_list_features_obsolete ));
	END IF;

	--copy connecs with state 0 inside plan_psector tables
	SELECT string_agg(connec_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_connec WHERE psector_id=v_old_psector_id AND state=0;

	IF v_list_features_obsolete IS NOT NULL THEN
		PERFORM setval('SCHEMA_NAME.plan_psector_x_connec_id_seq', (select max(id) from plan_psector_x_connec) , true);
		INSERT INTO plan_psector_x_connec(connec_id, psector_id, state, doable, descript, arc_id, link_id)
		SELECT DISTINCT connec_id, v_new_psector_id, 0, false, descript, arc_id, link_id FROM plan_psector_x_connec
		WHERE psector_id=v_old_psector_id AND state=0 ON CONFLICT (psector_id, connec_id, state) DO NOTHING;

		INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Copied connecs with state 0: ', v_list_features_obsolete ));
	END IF;

	--copy connecs with state 1 inside plan_psector tables
	SELECT string_agg(connec_id::text,',') INTO v_list_connec_undoable FROM plan_psector_x_connec WHERE psector_id=v_old_psector_id AND state=1 AND doable=false;

	IF v_list_connec_undoable IS NOT NULL THEN
		PERFORM setval('SCHEMA_NAME.plan_psector_x_connec_id_seq', (select max(id) from plan_psector_x_connec) , true);
		INSERT INTO plan_psector_x_connec(connec_id, psector_id, state, doable, descript)
		SELECT DISTINCT connec_id, v_new_psector_id, 1, false, descript FROM plan_psector_x_connec
		WHERE psector_id=v_old_psector_id AND state=1 AND doable=false ON CONFLICT (psector_id, connec_id, state) DO NOTHING;

		INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Copied connecs with state 1 (doable false): ', v_list_connec_undoable));
	END IF;

	IF v_project_type='UD' THEN
		--copy gullies with state 0 inside plan_psector tables
		SELECT string_agg(gully_id::text,',') INTO v_list_features_obsolete FROM plan_psector_x_gully WHERE psector_id=v_old_psector_id AND state=0;
		IF v_list_features_obsolete IS NOT NULL THEN
			PERFORM setval('SCHEMA_NAME.plan_psector_x_gully_id_seq', (select max(id) from plan_psector_x_gully) , true);
			INSERT INTO plan_psector_x_gully(gully_id, psector_id, state, doable, descript, arc_id, link_id)
			SELECT DISTINCT gully_id, v_new_psector_id, state, doable, descript, arc_id, link_id FROM plan_psector_x_gully
			WHERE psector_id=v_old_psector_id AND state=0 ON CONFLICT (psector_id, gully_id, state) DO NOTHING;

			INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Copied gullies with state 0: ', v_list_features_obsolete ));
		END IF;

		--copy gullies with state 1 inside plan_psector tables
		SELECT string_agg(gully_id::text,',') INTO v_list_gully_undoable FROM plan_psector_x_gully WHERE psector_id=v_old_psector_id AND state=1 AND doable=false;

		IF v_list_connec_undoable IS NOT NULL THEN
			PERFORM setval('SCHEMA_NAME.plan_psector_x_gully_id_seq', (select max(id) from plan_psector_x_gully) , true);
			INSERT INTO plan_psector_x_gully(gully_id, psector_id, state, doable, descript)
			SELECT DISTINCT gully_id, v_new_psector_id, 1, false, descript FROM plan_psector_x_gully
			WHERE psector_id=v_old_psector_id AND state=1 AND doable=false ON CONFLICT (psector_id, gully_id, state) DO NOTHING;

			INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Copied gullies with state 1: ', v_list_gully_undoable));
		END IF;
	END IF;
	--copy features inside plan_psector tables
	SELECT string_agg(price_id,',') INTO v_list_features_obsolete FROM plan_psector_x_other WHERE psector_id=v_old_psector_id;
	IF v_list_features_obsolete IS NOT NULL THEN
		INSERT INTO plan_psector_x_other(price_id, measurement, psector_id, descript)
		SELECT  price_id, measurement, psector_id, descript FROM plan_psector_x_other WHERE psector_id=v_old_psector_id;

		INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Copied other prices: ', v_list_features_obsolete ));
	END IF;

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

		FOR rec IN EXECUTE 'SELECT * FROM plan_psector_x_'||lower(rec_type.id)||' WHERE psector_id='||v_old_psector_id||' and state=1 '||v_subquery||'' LOOP
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


			
			EXECUTE 'INSERT INTO ve_'||lower(rec_type.id)||' ('||v_insert_fields||',state) SELECT '||v_insert_fields||',2 FROM '||lower(rec_type.id)||'
			WHERE '||lower(rec_type.id)||'_id='''||v_field_id||''';';

		END LOOP;

		EXECUTE 'SELECT string_agg('||lower(rec_type.id)||'_id::text,'','') FROM plan_psector_x_'||lower(rec_type.id)||' WHERE psector_id='||v_old_psector_id||' and state=1'
		into v_list_features_obsolete;

		IF v_list_features_obsolete IS NOT NULL THEN
			INSERT INTO audit_check_data (fid, result_id, error_message)
			VALUES (153, v_result_id, concat('New ',lower(rec_type.id),' inserted with state 1: ', v_list_features_obsolete));
		END IF;

	END LOOP;

	-- delete old psector from selector and set new
	DELETE FROM selector_psector WHERE psector_id=v_old_psector_id AND cur_user=current_user;
	INSERT INTO selector_psector VALUES (v_new_psector_id, current_user) ON CONFLICT (psector_id, cur_user) DO NOTHING;

	INSERT INTO audit_check_data (fid, result_id, error_message)
	VALUES (153, v_result_id, concat('Set ',v_new_psector_name,' as current psector.' ));

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


	--activate the functions an set back the values of parameters
	UPDATE config_param_user SET value=v_connecautolink WHERE parameter='edit_connec_automatic_link' and cur_user=current_user;
	UPDATE config_param_user SET value=v_gullyautolink WHERE parameter='edit_gully_automatic_link' and cur_user=current_user;

	UPDATE config_param_system SET value = v_connec_proximity WHERE parameter='edit_connec_proximity';
	UPDATE config_param_system SET value = v_gully_proximity WHERE parameter='edit_gully_proximity';
	UPDATE config_param_system SET value ='FALSE' WHERE parameter='edit_topocontrol_disable_error';

	INSERT INTO audit_check_data (fid, result_id, error_message) VALUES (153, v_result_id, concat('Activate topology control.'));

	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message AS message FROM audit_check_data WHERE cur_user="current_user"() AND fid=153) row;

	-- enable arc divide temporary
	UPDATE config_param_user SET value = 'FALSE'  WHERE "parameter"='edit_disable_arc_divide' AND cur_user=current_user;


	-- Control nulls
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');
	v_result_info := COALESCE(v_result_info, '{}');
	v_version := COALESCE(v_version, '');

	-- return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "version":"'||v_version||'"'||
            ',"message":{"level":1, "text":""},"body":{"data": {"info":'||v_result_info||'}}}')::json, 2734, null, null, null);

	-- manage exceptions
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

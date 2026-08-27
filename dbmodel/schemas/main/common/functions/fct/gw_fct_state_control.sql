/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2130
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_state_control(feature_type_aux character varying,feature_id_aux character varying, state_aux integer, tg_op_aux character varying);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_state_control(p_data json)
RETURNS integer AS
$BODY$

-- fid: 128

DECLARE

-- parameters
feature_type_aux text;
feature_id_aux integer;
state_aux integer;
tg_op_aux text;

v_project_type text;
v_old_state integer;
v_psector_vdefault integer;
v_num_feature integer;
v_downgrade_force boolean;
v_connec_downgrade_force boolean;
v_state_type integer;
v_psector_list text;
v_schemaname text;
v_channel text;
v_result text;

rec_feature record;

BEGIN

	SET search_path="SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;
	v_downgrade_force:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_arc_downgrade_force' AND cur_user=current_user)::boolean;
	v_connec_downgrade_force:= (SELECT "value" FROM config_param_system WHERE "parameter"='edit_connec_downgrade_force')::boolean;

	feature_type_aux = ((p_data ->>'parameters')::json->>'feature_type_aux')::text;
	feature_id_aux = ((p_data ->>'parameters')::json->>'feature_id_aux')::text;
	state_aux = ((p_data ->>'parameters')::json->>'state_aux')::integer;
	tg_op_aux = ((p_data ->>'parameters')::json->>'tg_op_aux')::text;

	-- control for downgrade features to state(0)
	IF tg_op_aux = 'UPDATE' THEN

		IF feature_type_aux='NODE' and state_aux=0 THEN

			SELECT state INTO v_old_state FROM node WHERE node_id=feature_id_aux;
			IF state_aux!=v_old_state AND (v_downgrade_force IS NOT TRUE) THEN

				-- arcs control state 1
				SELECT count(arc.arc_id) INTO v_num_feature FROM arc WHERE (node_1=feature_id_aux OR node_2=feature_id_aux) AND arc.state = 1;
				IF v_num_feature > 0 THEN 
					v_result = 'SELECT array_agg(arc_id) FROM arc WHERE (node_1='|| quote_literal(feature_id_aux)||' OR node_2='|| quote_literal(feature_id_aux)||') AND arc.state = 1;';
					EXECUTE v_result INTO v_result;
					v_result=concat(feature_id_aux,' has associated arcs ',v_result);				
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"1072", "function":"2130","debug_msg":"'||v_result||'", "is_process":true}}$$);';
				END IF;

				-- arcs control state 2
				SELECT count(arc.arc_id) INTO v_num_feature FROM arc WHERE (node_1=feature_id_aux OR node_2=feature_id_aux) AND arc.state = 2;
				IF v_num_feature > 0 THEN 
					SELECT string_agg(name::text, ', ') INTO v_psector_list FROM plan_psector_x_arc 
					JOIN plan_psector p USING (psector_id) where p.active and arc_id IN 
					(SELECT arc.arc_id FROM arc WHERE (node_1=feature_id_aux OR node_2=feature_id_aux) AND arc.state = 2); 
					IF v_psector_list is not null then			
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3140", "function":"2130","debug_msg":"'||v_psector_list||'", "is_process":true}}$$);';
					END IF;
				END IF;

				-- connec control state 1
				SELECT count(connec.connec_id) INTO v_num_feature FROM connec WHERE connec.state = 1 AND arc_id = feature_id_aux;
				IF v_num_feature > 0 THEN 
					v_result = 'SELECT array_agg(connec_id) FROM connec WHERE connec.state = 1 AND arc_id = feature_id_aux;';
					EXECUTE v_result INTO v_result;
					v_result=concat(feature_id_aux,' has associated arcs ',v_result);				
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"1072", "function":"2130","debug_msg":"'||v_result||'", "is_process":true}}$$);';
				END IF;

				-- connecs control state 2
				SELECT count(connec.connec_id) INTO v_num_feature FROM connec WHERE connec.state = 2 AND arc_id = feature_id_aux;
				IF v_num_feature > 0 THEN 
					SELECT string_agg(name::text, ', ') INTO v_psector_list FROM plan_psector_x_connec 
					JOIN plan_psector p USING (psector_id) where p.active AND connec_id = feature_id_aux and connec_id IN 
					(SELECT connec.connec_id FROM connec WHERE connec.state = 2); 

					IF v_psector_list is not null then
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3140", "function":"2130","debug_msg":"'||v_psector_list||'", "is_process":true}}$$);';
					END IF;
				END IF;

				-- gully to do:
				IF v_project_type = 'UD' THEN
					SELECT count(gully.gully_id) INTO v_num_feature FROM gully WHERE gully.state = 2 AND arc_id = feature_id_aux;
					IF v_num_feature > 0 THEN 
						SELECT string_agg(name::text, ', ') INTO v_psector_list FROM plan_psector_x_gully 
						JOIN plan_psector p USING (psector_id) where p.active AND gully_id = feature_id_aux and gully_id IN 
						(SELECT gully.gully_id FROM gully WHERE gully.state = 2); 
	
						IF v_psector_list is not null then
							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
							"data":{"message":"3140", "function":"2130","debug_msg":"'||v_psector_list||'", "is_process":true}}$$);';
						END IF;
					END IF;
				END IF;
				
			ELSIF state_aux!=v_old_state AND (v_downgrade_force IS TRUE) THEN

				-- arcs control
				SELECT count(arc.arc_id) INTO v_num_feature FROM arc WHERE (node_1=feature_id_aux OR node_2=feature_id_aux) AND arc.state > 0;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT state_type FROM node WHERE node_id=$1'
						INTO v_state_type
						USING feature_id_aux;
					INSERT INTO audit_log_data (fid, feature_type, feature_id, log_message) VALUES (128,'NODE', feature_id_aux, concat(v_old_state,',',v_state_type));
				END IF;

				--link control
				SELECT count(link_id) INTO v_num_feature FROM link WHERE exit_type='NODE' AND exit_id=feature_id_aux AND link.state > 0;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT state_type FROM node WHERE node_id=$1'
						INTO v_state_type
						USING feature_id_aux;
					INSERT INTO audit_log_data (fid, feature_type, feature_id, log_message) VALUES (128,'NODE', feature_id_aux, concat(v_old_state,',',v_state_type));
				END IF;
				
				-- node control

				-- connec control
				
				-- gully control				
				
			END IF;

		ELSIF feature_type_aux='ARC' and state_aux=0 THEN

			SELECT state INTO v_old_state FROM arc WHERE arc_id=feature_id_aux;
			IF state_aux!=v_old_state AND (v_downgrade_force IS NOT TRUE) THEN
			
				--node's control
				SELECT count(arc_id) INTO v_num_feature FROM node WHERE arc_id=feature_id_aux AND node.state=1;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"1074", "function":"2130","parameters":{"arc_id":"'||feature_id_aux||'"}, "is_process":true}}$$);';
				END IF;
				
				--node's control state = 2
				SELECT count(node.node_id) INTO v_num_feature FROM node WHERE node.state = 2 AND arc_id = feature_id_aux;
				IF v_num_feature > 0 THEN 
					SELECT string_agg(name::text, ', ') INTO v_psector_list FROM plan_psector_x_node 
					JOIN plan_psector p USING (psector_id) where p.active AND node_id = feature_id_aux and node_id IN 
					(SELECT node.node_id FROM node WHERE node.state = 2); 

					IF v_psector_list is not null then
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3140", "function":"2130","debug_msg":"'||v_psector_list||'", "is_process":true}}$$);';
					END IF;
				END IF;
			
				--connec's control state = 1
				SELECT count(arc_id) INTO v_num_feature FROM connec WHERE arc_id=feature_id_aux AND connec.state=1;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"1074", "function":"2130","parameters":{"arc_id":"'||feature_id_aux||'"}, "is_process":true}}$$);';
				END IF;
				
				-- connecs control state 2
				SELECT count(connec.connec_id) INTO v_num_feature FROM connec WHERE connec.state = 2 AND arc_id = feature_id_aux;
				IF v_num_feature > 0 THEN 
					SELECT string_agg(name::text, ', ') INTO v_psector_list FROM plan_psector_x_connec 
					JOIN plan_psector p USING (psector_id) where p.active AND connec_id = feature_id_aux and connec_id IN 
					(SELECT connec.connec_id FROM connec WHERE connec.state = 2); 

					IF v_psector_list is not null then
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3140", "function":"2130","debug_msg":"'||v_psector_list||'", "is_process":true}}$$);';
					END IF;
				END IF;
				
				IF v_project_type='UD' THEN
					
					--gully's control state = 1
					SELECT count(arc_id) INTO v_num_feature FROM gully WHERE arc_id=feature_id_aux AND gully.state=1;
					IF v_num_feature > 0 THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"1074", "function":"2130","parameters":{"arc_id":"'||feature_id_aux||'"}, "is_process":true}}$$);';
					END IF;
							
					-- gully's control state 2
					SELECT count(gully.gully_id) INTO v_num_feature FROM gully WHERE gully.state = 2 AND arc_id = feature_id_aux;
					IF v_num_feature > 0 THEN 
						SELECT string_agg(name::text, ', ') INTO v_psector_list FROM plan_psector_x_gully 
						JOIN plan_psector p USING (psector_id) where p.active AND gully_id = feature_id_aux and gully_id IN 
						(SELECT gully.gully_id FROM gully WHERE gully.state = 2); 

						IF v_psector_list is not null then
							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
							"data":{"message":"3140", "function":"2130","debug_msg":"'||v_psector_list||'", "is_process":true}}$$);';
						END IF;
					END IF;
				END IF;

			ELSIF state_aux!=v_old_state AND (v_downgrade_force IS TRUE) THEN
			
				--node's control
				FOR rec_feature IN SELECT * FROM node WHERE arc_id=feature_id_aux AND node.state>0
				LOOP
					UPDATE node set arc_id=NULL WHERE node_id=rec_feature.node_id;
				END LOOP;
							
				--connec's control
				FOR rec_feature IN SELECT * FROM connec WHERE arc_id=feature_id_aux AND connec.state>0
				LOOP
					UPDATE connec set arc_id=NULL WHERE connec_id=rec_feature.connec_id;
				END LOOP;

				--gully's control
				ELSIF v_project_type='UD' THEN
					FOR rec_feature IN SELECT * FROM gully WHERE arc_id=feature_id_aux AND gully.state>0
					LOOP
						UPDATE gully set arc_id=NULL WHERE gully_id=rec_feature.gully_id;
					END LOOP;
				END IF;
			END IF;

		ELSIF feature_type_aux='CONNEC' and state_aux=0 THEN

			SELECT state INTO v_old_state FROM connec WHERE connec_id=feature_id_aux;
			IF state_aux!=v_old_state AND (v_connec_downgrade_force IS NOT TRUE) THEN

				--link control
				SELECT count(link_id) INTO v_num_feature FROM link WHERE exit_type='CONNEC' AND exit_id=feature_id_aux AND link.state > 0;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"1072", "function":"2130","parameters":{"node_id":"'||feature_id_aux||'"}, "is_process":true}}$$);';
				END IF;

				-- hydrometer control
				SELECT count(*) INTO v_num_feature
				FROM v_hydrometer erh
					JOIN connec c ON c.customer_code = erh.feature_customer_code
				WHERE c.connec_id = feature_id_aux
                	AND erh.state_id IN (
								SELECT (json_array_elements_text((value::json->>'1')::json))::INTEGER
								FROM config_param_system
								where parameter  = 'admin_hydrometer_state');

				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3194", "function":"2130","parameters":{"feature_id":"'||feature_id_aux||'"}, "is_process":true}}$$);';
				END IF;

			ELSIF state_aux!=v_old_state AND (v_connec_downgrade_force IS TRUE) THEN

				--link control
				SELECT count(link_id) INTO v_num_feature FROM link WHERE exit_type='CONNEC' AND exit_id=feature_id_aux AND link.state > 0;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT state_type FROM connec WHERE connec_id=$1'
						INTO v_state_type
						USING feature_id_aux;
					INSERT INTO audit_log_data (fid, feature_type, feature_id, log_message) VALUES (128,'CONNEC', feature_id_aux, concat(v_old_state,',',v_state_type));
				END IF;

				-- hydrometer control
				SELECT count(*) INTO v_num_feature
				FROM v_hydrometer erh
					JOIN connec c ON c.customer_code = erh.feature_customer_code
				WHERE c.connec_id = feature_id_aux
                	AND erh.state_id IN (
								SELECT (json_array_elements_text((value::json->>'1')::json))::INTEGER
								FROM config_param_system
								where parameter  = 'admin_hydrometer_state');

				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT state_type FROM connec WHERE connec_id=$1'
						INTO v_state_type
						USING feature_id_aux;
					INSERT INTO audit_log_data (fid, feature_type, feature_id, log_message) VALUES (128,'CONNEC', feature_id_aux, concat(v_old_state,',',v_state_type));
				END IF;
			END IF;

		ELSIF feature_type_aux='GULLY' and state_aux=0 THEN

			SELECT state INTO v_old_state FROM gully WHERE gully_id=feature_id_aux;
			IF state_aux!=v_old_state AND (v_connec_downgrade_force IS NOT TRUE) THEN

				--link control
				SELECT count(link_id) INTO v_num_feature FROM link WHERE exit_type='GULLY' AND exit_id=feature_id_aux AND link.state > 0;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"1072", "function":"2130","parameters":{"node_id":"'||feature_id_aux||'"}, "is_process":true}}$$);';
				END IF;

			ELSIF state_aux!=v_old_state AND (v_connec_downgrade_force IS TRUE) THEN

				--link control
				SELECT count(link_id) INTO v_num_feature FROM link WHERE exit_type='GULLY' AND exit_id=feature_id_aux AND link.state > 0;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT state_type FROM gully WHERE gully_id=$1'
						INTO v_state_type
						USING feature_id_aux;
					INSERT INTO audit_log_data (fid, feature_type, feature_id, log_message) VALUES (128,'GULLY', feature_id_aux, concat(v_old_state,',',v_state_type));
				END IF;
			END IF;
		END IF;

	-- control of insert/update nodes with state(2)
	IF feature_type_aux='NODE' THEN
		SELECT state INTO v_old_state FROM node WHERE node_id=feature_id_aux;
	ELSIF feature_type_aux='ARC' THEN
		SELECT state INTO v_old_state FROM arc WHERE arc_id=feature_id_aux;
	END IF;

	IF tg_op_aux = 'INSERT' THEN

		IF state_aux=2 THEN

			IF ('role_plan' NOT IN (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, 'member'))) THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1080", "function":"2130","parameters":null, "is_process":true}}$$);';
			END IF;

			-- check at least one psector defined
			IF (SELECT psector_id FROM plan_psector LIMIT 1) IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1081", "function":"2130","parameters":null, "is_process":true}}$$);';
			END IF;

			-- check user's variable
			SELECT value INTO v_psector_vdefault FROM config_param_user WHERE parameter='plan_psector_current' AND cur_user="current_user"();
			IF v_psector_vdefault IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1083", "function":"2130","parameters":null, "is_process":true}}$$);';
			END IF;

			-- force visible psector vdefault
			IF (SELECT psector_id FROM selector_psector WHERE cur_user = current_user AND psector_id = v_psector_vdefault) IS NULL THEN
				-- insert selector
				INSERT INTO selector_psector VALUES (v_psector_vdefault, current_user);
				-- message to user
				v_channel = replace(current_user,'.','_');
				PERFORM pg_notify(v_channel, '{"functionAction":{"functions":[{"name":"show_message", "parameters":{"type":"textWindow", "level":0, "text":"Current psector have been selected"}},
				{"name":"get_selector","parameters":{"tab":"tab_psector"}}]} ,"user":"'||current_user||'","schema":"'||v_schemaname||'"}');

			END IF;
		END IF;

	ELSIF tg_op_aux = 'UPDATE' THEN

		IF state_aux=2 AND v_old_state<2 THEN

			-- check user's role
			IF ('role_plan' NOT IN (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, 'member'))) THEN
				PERFORM pg_notify(v_channel, '{"functionAction":{"functions":[{"name":"show_message", "parameters":{"level":0, "duration":10, "text":"Current psector have been selected"}},
				{"name":"get_selector","parameters":{"current_tab":"tab_psector"}}]} ,"user":"'||current_user||'","schema":"'||v_schemaname||'"}');
			END IF;

			-- check user's variable
			SELECT value INTO v_psector_vdefault FROM config_param_user WHERE parameter='plan_psector_current' AND cur_user="current_user"();
			IF v_psector_vdefault IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1083", "function":"2130","parameters":null, "is_process":true}}$$);';
			END IF;

			-- force visible psector vdefault
			IF (SELECT psector_id FROM selector_psector WHERE cur_user = current_user AND psector_id = v_psector_vdefault) IS NULL THEN
				-- insert selector
				INSERT INTO selector_psector VALUES (v_psector_vdefault, current_user);
				-- message to user
				v_channel = replace(current_user,'.','_');
				PERFORM pg_notify(v_channel, '{"functionAction":{"functions":[{"name":"show_message", "parameters":{"level":0, "duration":10, "text":"Current psector have been selected"}},
				{"name":"get_selector","parameters":{"current_tab":"tab_psector"}}]} ,"user":"'||current_user||'","schema":"'||v_schemaname||'"}');
			END IF;

			IF feature_type_aux='NODE' AND v_old_state = 1 THEN

				-- look for operative arcs related to node
				SELECT count(*) INTO v_num_feature FROM (SELECT * FROM arc WHERE state = 1 AND node_1 = feature_id_aux UNION SELECT * FROM arc WHERE state = 1 AND node_2 = feature_id_aux)a;
				IF v_num_feature > 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3258", "function":"2130","parameters":null, "is_process":true}}$$);';
				END IF;

			ELSIF feature_type_aux='ARC' AND v_old_state = 1 THEN

				-- look for operative connecs related arc
				SELECT count(*) INTO v_num_feature FROM connec WHERE state = 1 AND arc_id = feature_id_aux;
				IF v_num_feature> 0 THEN
					EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3254", "function":"2130","parameters":null, "is_process":true}}$$);';
				END IF;

				-- look for operative gullies related arc
				IF v_project_type = 'UD' THEN

					SELECT count(*) INTO v_num_feature FROM gully WHERE state = 1 AND arc_id = feature_id_aux;
					IF v_num_feature > 0 THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3256", "function":"2130","parameters":null, "is_process":true}}$$);';
					END IF;
				END IF;
			END IF;

		ELSIF state_aux<2 AND v_old_state=2 THEN

			-- check user's role
			IF ('role_plan' NOT IN (SELECT rolname FROM pg_roles WHERE  pg_has_role( current_user, oid, 'member')))  THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"1080", "function":"2130","parameters":null, "is_process":true}}$$);';
			END IF;
		END IF;
	END IF;

	RETURN 0;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



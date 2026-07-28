/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2114

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_arc_divide(character varying);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_arc_divide(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setarcdivide(p_data json) RETURNS json AS
$BODY$

/*EXAMPLE:

-- fid: 212

-- MODE 1: individual
SELECT SCHEMA_NAME.gw_fct_setarcdivide($${"client":{"device":4, "infoType":1, "lang":"ES"}, "feature":{"id":["269951"]}}$$)

-- MODE 2: massive using id as array
SELECT SCHEMA_NAME.gw_fct_setarcdivide($${"feature":{"id":"SELECT array_to_json(array_agg(node_id::text)) FROM node JOIN ... WHERE ..."}, "data":{}}$$);

-- MODE 3: massive usign pure SQL
SELECT SCHEMA_NAME.gw_fct_setarcdivide(concat('{"feature":{"id":["',node_id,'"]},"data":{"parameters":{"skipInitEndMessage":true}}}')::json) FROM node JOIN ... WHERE ...;

*/

DECLARE
v_node_geom public.geometry;
v_arc_id integer;
v_code varchar;
v_arc_geom public.geometry;
v_line1 public.geometry;
v_line2 public.geometry;
v_intersect_loc	double precision;
v_project_type text;
v_state_arc integer;
v_state_node integer;
v_gully_id 	integer;
v_connec_id integer;
v_return smallint;
v_arc_divide_tolerance float =0.05;
v_array_connec varchar [];
v_array_gully varchar [];
v_arc_searchnodes float;
v_newarc integer;
v_visitlocation	float;
v_eventlocation	float;
v_srid integer;
v_newvisit1	int8;
v_newvisit2	int8;
v_psector integer;
v_ficticius	int2;
v_isarcdivide boolean;
v_manquerytext text;
v_manquerytext1	text;
v_manquerytext2	text;
v_epaquerytext text;
v_epaquerytext1	text;
v_epaquerytext2	text;
v_mantable text;
v_epatable text;
v_schemaname text;
v_node_type text;
v_version text;
v_arc_code text;
v_count integer;
v_count_connec integer=0;
v_count_gully integer=0;
v_skipinitendmessage boolean;

rec_link record;
rec_visit record;
rec_node record;
rec_event record;
rec_aux	 record;
rec_aux1 "SCHEMA_NAME".arc;
rec_aux2 "SCHEMA_NAME".arc;
rec_table	record;
v_query_string  text;
v_max_seq_id	int8;

v_result text;
v_result_info text;
v_error_context text;
v_audit_result text;
v_level integer;
v_status text;
v_message text;
v_hide_form boolean;
v_array_node_id json;
v_node_id integer;
v_arc_closest integer;
v_set_arc_obsolete boolean;
v_set_old_code boolean;
v_obsoletetype integer;
v_node1_graph text;
v_node2_graph text;
v_node_1 integer;
v_node_2 integer;
v_new_node_graph text;
v_graph_arc_id TEXT;
v_force_delete text;
rec_connec record;
rec_gully record;

rec_addfields record;
v_sql text;
v_query_string_update text;
v_arc_childtable_name text;
v_arc_type text;
v_fid integer = 212;
v_result_id text= 'arc divide';


BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	-- Get parameters from input json
	v_array_node_id = lower(((p_data ->>'feature')::json->>'id'));
	v_skipinitendmessage = (((p_data ->>'data')::json->>'parameters')::json->>'skipInitEndMessage')::boolean;

	v_node_id = (SELECT json_array_elements_text(v_array_node_id)::integer);
	-- Get project type
	SELECT project_type, epsg, giswater INTO v_project_type, v_srid,v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Get node values
	SELECT the_geom INTO v_node_geom FROM node WHERE node_id = v_node_id;
	SELECT state INTO v_state_node FROM node WHERE node_id=v_node_id;

	IF v_project_type = 'WS' THEN
		SELECT isarcdivide, cat_feature_node.id INTO v_isarcdivide, v_node_type
		FROM cat_feature_node JOIN cat_node ON cat_node.node_type=cat_feature_node.id
		JOIN node ON node.nodecat_id = cat_node.id WHERE node.node_id=v_node_id;
	ELSE
		SELECT isarcdivide, cat_feature_node.id INTO v_isarcdivide, v_node_type
		FROM cat_feature_node JOIN node ON node.node_type = cat_feature_node.id WHERE node.node_id=v_node_id;
	END IF;

	-- Get parameters from configs table
	SELECT ((value::json)->>'value') INTO v_arc_searchnodes FROM config_param_system WHERE parameter='edit_arc_searchnodes';
	SELECT value::int4 INTO v_psector FROM config_param_user WHERE "parameter"='plan_psector_current' AND cur_user=current_user;
	v_ficticius:= (SELECT (value::json->>'plan_statetype_ficticius')::smallint FROM config_param_system WHERE parameter='plan_statetype_vdefault');
	SELECT value::boolean INTO v_hide_form FROM config_param_user where parameter='qgis_form_log_hidden' AND cur_user=current_user;
	SELECT json_extract_path_text (value::json,'setArcObsolete')::boolean INTO v_set_arc_obsolete FROM config_param_system WHERE parameter='edit_arc_divide';
	SELECT json_extract_path_text (value::json,'setOldCode')::boolean INTO v_set_old_code FROM config_param_system WHERE parameter='edit_arc_divide';
	SELECT value::smallint INTO v_obsoletetype FROM config_param_user where parameter='edit_statetype_0_vdefault' AND cur_user=current_user;
	IF v_obsoletetype IS NULL THEN
		SELECT id INTO v_obsoletetype FROM value_state_type WHERE state=0 LIMIT 1;
	END IF;

	-- delete old values on result table
	DELETE FROM audit_check_data WHERE fid=212 AND cur_user=current_user;

	-- Starting process
	EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2114", "fid":"212", "criticity":"4", "is_process":true, "is_header":"true"}}$$)';

	-- State control
	IF v_state_arc=0 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"1050", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;

	ELSIF v_state_node=0 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		"data":{"message":"1052", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
	ELSE


		-- Control if node divides arc
		IF v_isarcdivide=TRUE then

			-- update arc_id null in case the node has related the arc_id
			UPDATE node set arc_id = null where node_id = v_node_id and arc_id is not NULL;

			-- Check if it's a end/start point node in case of wrong topology without start or end nodes
			SELECT arc_id INTO v_arc_id FROM ve_arc WHERE ST_DWithin(ST_startpoint(the_geom), v_node_geom, v_arc_searchnodes) OR ST_DWithin(ST_endpoint(the_geom), v_node_geom, v_arc_searchnodes) LIMIT 1;
			IF v_arc_id IS NOT NULL THEN
				-- force trigger of topology in order to reconnect extremal nodes (in case of null's)
				UPDATE arc SET the_geom=the_geom WHERE arc_id=v_arc_id;
				-- get another arc if exists
				SELECT arc_id INTO v_arc_id FROM ve_arc WHERE ST_DWithin(the_geom, v_node_geom, v_arc_searchnodes) AND arc_id != v_arc_id;
			END IF;

			-- For the specificic case of extremal node not reconnected due topology issues (i.e. arc state (1) and node state (2)

			-- Find closest arc inside tolerance
			SELECT arc_id, state, the_geom, code INTO v_arc_id, v_state_arc, v_arc_geom, v_code  FROM ve_arc AS a
			WHERE ST_DWithin(v_node_geom, a.the_geom, v_arc_divide_tolerance) AND node_1 != v_node_id AND node_2 != v_node_id
			ORDER BY a.the_geom <-> v_node_geom LIMIT 1;

			IF v_arc_id IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3348", "function":"2114", "parameters":{"v_arc_id":"'||v_arc_id||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';

				-- Get arctype
				v_sql := 'SELECT arc_type FROM ve_arc WHERE arc_id = '||v_arc_id||';';
				EXECUTE v_sql
				INTO v_arc_type;

				--  Locate position of the nearest point
				v_intersect_loc := ST_LineLocatePoint(v_arc_geom, v_node_geom);

				-- Compute pieces
				v_line1 := ST_LineSubstring(v_arc_geom, 0.0, v_intersect_loc);
				v_line2 := ST_LineSubstring(v_arc_geom, v_intersect_loc, 1.0);

				-- Check if any of the 'lines' are in fact a point AS a result to be placed on the initY
				IF (ST_GeometryType(v_line1) = 'ST_Point') OR (ST_GeometryType(v_line2) = 'ST_Point') THEN

					IF v_skipinitendmessage THEN

					ELSE
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3094", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
					END IF;

				ELSE
					-- check if there are not-selected psector affecting connecs
					IF (SELECT count (*) FROM plan_psector_x_connec JOIN plan_psector USING (psector_id)
					WHERE arc_id = v_arc_id AND state = 1 AND status IN (1,2) AND psector_id NOT IN (SELECT psector_id FROM selector_psector)) > 0 THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3180", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
					END IF;

					-- check if there are not-selected psector affecting gullies
					IF v_project_type = 'UD' THEN
						IF (SELECT count (*) FROM plan_psector_x_gully JOIN plan_psector USING (psector_id)
						WHERE arc_id = v_arc_id AND state = 1 AND status IN (1,2) AND psector_id NOT IN (SELECT psector_id FROM selector_psector)) > 0 THEN
							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
							"data":{"message":"3180", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
						END IF;
					END IF;

					-- Get arc data
					SELECT * INTO rec_aux1 FROM arc WHERE arc_id = v_arc_id;
					SELECT * INTO rec_aux2 FROM arc WHERE arc_id = v_arc_id;


					-- Update values of new arc_id (1)
					rec_aux1.arc_id := nextval('SCHEMA_NAME.urn_id_seq');

					--code
					rec_aux1.code := gw_fct_generate_code('feature', v_arc_type, json_strip_nulls(to_json(rec_aux1)::json));
					IF rec_aux1.code IS NULL AND v_set_old_code IS TRUE THEN
						rec_aux1.code := v_code;
					ELSIF rec_aux1.code IS NULL THEN
						rec_aux1.code := rec_aux1.arc_id;
					END IF;

					-- node and geom
					rec_aux1.node_2 := v_node_id ;-- rec_aux1.node_1 take values from original arc
					rec_aux1.the_geom := v_line1;

					-- Update values of new arc_id (2)
					rec_aux2.arc_id := nextval('SCHEMA_NAME.urn_id_seq');
					rec_aux2.uuid := gen_random_uuid();

					-- code
					rec_aux2.code := gw_fct_generate_code('feature', v_arc_type, json_strip_nulls(to_json(rec_aux2)::json));
					IF rec_aux2.code IS NULL AND v_set_old_code IS TRUE THEN
						rec_aux2.code := v_code;
					ELSIF rec_aux2.code IS NULL THEN
						rec_aux2.code := rec_aux2.arc_id;
					END IF;

					-- node and geom
					rec_aux2.node_1 := v_node_id; -- rec_aux2.node_2 take values from original arc
					rec_aux2.the_geom := v_line2;

					-- getting table child information (man_table)
					v_mantable = (SELECT man_table FROM cat_feature_arc c JOIN cat_feature cf ON c.id = cf.id JOIN sys_feature_class s ON cf.feature_class = s.id JOIN ve_arc ON c.id=arc_type WHERE arc_id=v_arc_id);
					v_epatable = (SELECT epa_table FROM cat_feature_arc c JOIN sys_feature_epa_type s ON epa_default = s.id JOIN ve_arc ON c.id=arc_type WHERE arc_id=v_arc_id);

					-- building querytext for man_table
					v_manquerytext:= (SELECT replace (replace (array_agg(column_name::text)::text,'{',','),'}','') FROM (SELECT column_name FROM information_schema.columns
					WHERE table_name=v_mantable AND table_schema=v_schemaname AND column_name !='arc_id' ORDER BY ordinal_position)a);
					IF v_manquerytext IS NULL THEN
						v_manquerytext='';
					END IF;
					v_manquerytext1 = 'INSERT INTO '||v_mantable||' SELECT ';
					v_manquerytext2 = v_manquerytext||' FROM '||v_mantable||' WHERE arc_id= '||v_arc_id||'';

					-- building querytext for epa_table
					v_epaquerytext:= (SELECT replace (replace (array_agg(column_name::text)::text,'{',','),'}','') FROM (SELECT column_name FROM information_schema.columns
					WHERE table_name=v_epatable AND table_schema=v_schemaname AND column_name !='arc_id' ORDER BY ordinal_position)a);
					IF  v_epaquerytext IS NULL THEN
						v_epaquerytext='';
					END IF;
					v_epaquerytext1 =  'INSERT INTO '||v_epatable||' SELECT ';
					v_epaquerytext2 =  v_epaquerytext||' FROM '||v_epatable||' WHERE arc_id= '||v_arc_id||'';

					IF v_project_type = 'WS' THEN

						--check if final nodes maybe graph delimiters
						EXECUTE 'SELECT CASE WHEN (''NONE'' = ANY(graph_delimiter) OR ''MINSECTOR'' = ANY(graph_delimiter)) THEN NULL ELSE graph_delimiter END AS graph, node_1 FROM ve_arc a
						JOIN ve_node n1 ON n1.node_id=node_1
						JOIN cat_feature_node cf1 ON n1.node_type = cf1.id
						WHERE a.arc_id='||v_arc_id||''
						INTO v_node1_graph, v_node_1;

						EXECUTE 'SELECT CASE WHEN (''NONE'' = ANY(graph_delimiter) OR ''MINSECTOR'' = ANY(graph_delimiter)) THEN NULL ELSE graph_delimiter END AS graph,node_2 FROM ve_arc a
						JOIN ve_node n2 ON n2.node_id=node_2
						JOIN cat_feature_node cf2 ON n2.node_type = cf2.id
						WHERE a.arc_id='||v_arc_id||''
						INTO v_node2_graph, v_node_2;

						EXECUTE 'SELECT CASE WHEN (''NONE'' = ANY(graph_delimiter) OR ''MINSECTOR'' = ANY(graph_delimiter)) THEN NULL ELSE graph_delimiter END AS graph FROM ve_node
						JOIN cat_feature_node cf2 ON node_type = cf2.id
						WHERE node_id='||v_node_id||';'
						INTO v_new_node_graph;

					END IF;


					-- In function of states and user's variables proceed.....
					IF v_state_node=1 THEN

						-- Insert new records into arc table
						INSERT INTO arc SELECT rec_aux1.*;
						INSERT INTO arc SELECT rec_aux2.*;

						IF rec_aux1.state = 2 THEN
							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
							"data":{"message":"3202", "function":"2114","parameters":{"arc_id":"'||rec_aux1.arc_id||'"}, "is_process":true}}$$);' INTO v_audit_result;
						END IF;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3350", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

						INSERT INTO audit_check_data (fid,  criticity, error_message)
						VALUES (212, 1, concat('Arc1: arc_id:', rec_aux1.arc_id,', code:',rec_aux1.code,' length:',
						round(st_length(rec_aux1.the_geom)::numeric,2),'.'));

						INSERT INTO audit_check_data (fid,  criticity, error_message)
						VALUES (212, 1, concat('Arc2: arc_id:', rec_aux2.arc_id,', code:',rec_aux2.code,' length:',
						round(st_length(rec_aux2.the_geom)::numeric,2),'.'));

						-- insert new records into man_table
						EXECUTE v_manquerytext1||rec_aux1.arc_id||v_manquerytext2;
						EXECUTE v_manquerytext1||rec_aux2.arc_id||v_manquerytext2;

						-- insert new records into epa_table
						EXECUTE v_epaquerytext1||rec_aux1.arc_id||v_epaquerytext2;
						EXECUTE v_epaquerytext1||rec_aux2.arc_id||v_epaquerytext2;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3352", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';


						-- update node_1 and node_2 because it's not possible to pass using parameters
						UPDATE arc SET node_1=rec_aux1.node_1,node_2=rec_aux1.node_2 where arc_id=rec_aux1.arc_id;
						UPDATE arc SET node_1=rec_aux2.node_1,node_2=rec_aux2.node_2 where arc_id=rec_aux2.arc_id;

						-- update link only with enabled variable
						IF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
							UPDATE arc SET link=rec_aux1.arc_id where arc_id=rec_aux1.arc_id;
							UPDATE arc SET link=rec_aux2.arc_id where arc_id=rec_aux2.arc_id;
						END IF;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3416", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

						v_arc_childtable_name := 'man_arc_' || lower(v_arc_type);

						IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = v_schemaname AND table_name = v_arc_childtable_name)) IS TRUE THEN
							EXECUTE 'INSERT INTO '||v_arc_childtable_name||' (arc_id) VALUES ('''||rec_aux1.arc_id||''') ON CONFLICT DO NOTHING;';
							EXECUTE 'INSERT INTO '||v_arc_childtable_name||' (arc_id) VALUES ('''||rec_aux2.arc_id||''') ON CONFLICT DO NOTHING;';


							v_sql := 'SELECT column_name FROM information_schema.columns 
									WHERE table_schema = ''SCHEMA_NAME'' 
									AND table_name = '''||v_arc_childtable_name||''' 
									AND column_name !=''id'' AND column_name != ''arc_id'' ;';

							FOR rec_addfields IN EXECUTE v_sql
							LOOP

								v_query_string_update = 'UPDATE '||v_arc_childtable_name||' SET '||rec_addfields.column_name|| ' = '
														'( SELECT '||rec_addfields.column_name||' FROM '||v_arc_childtable_name||' WHERE arc_id = '||quote_literal(v_arc_id)||' ) '
														'WHERE '||v_arc_childtable_name||'.arc_id = '||quote_literal(rec_aux1.arc_id)||';';

								IF v_query_string_update IS NOT NULL THEN
									EXECUTE v_query_string_update;
								END IF;

								v_query_string_update = 'UPDATE '||v_arc_childtable_name||' SET '||rec_addfields.column_name|| ' = '
														'( SELECT '||rec_addfields.column_name||' FROM '||v_arc_childtable_name||' WHERE arc_id = '||quote_literal(v_arc_id)||' ) '
														'WHERE '||v_arc_childtable_name||'.arc_id = '||quote_literal(rec_aux2.arc_id)||';';

								IF v_query_string_update IS NOT NULL THEN
									EXECUTE v_query_string_update;
								END IF;

							END LOOP;

					   EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3354", "function":"2114", "parameters":{"v_arc_id":"'||v_arc_id||'", "rec_aux1.arc_id":"'||rec_aux1.arc_id||'", "rec_aux2.arc_id":"'||rec_aux2.arc_id||'"}, "fid":"212", "result_id":"arc divide", "is_process":true}}$$)';


						END IF;

						-- update arc_id of disconnected nodes linked to old arc
						FOR rec_node IN SELECT node_id, the_geom FROM node WHERE arc_id=v_arc_id AND node_id!=v_node_id
						LOOP
							UPDATE node SET arc_id=(SELECT arc_id FROM ve_arc WHERE ST_DWithin(rec_node.the_geom,
							ve_arc.the_geom,0.001) AND arc_id != v_arc_id LIMIT 1)
							WHERE node_id=rec_node.node_id;

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3356", "function":"2114", "parameters":{"rec_node.node_id":"'||rec_node.node_id||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';

						END LOOP;

						IF v_project_type='UD' THEN
							INSERT INTO temp_table (fid, geom_line, expl_id)
							SELECT 398, the_geom,link_id FROM link JOIN plan_psector_x_gully USING (link_id) WHERE arc_id = v_arc_id AND psector_id = v_psector;
						END IF;

						-- connec
						SELECT array_agg(connec_id) INTO v_array_connec FROM connec c WHERE arc_id=v_arc_id AND c.state = 1;
			
						SELECT count(connec_id) INTO v_count_connec FROM ve_connec WHERE arc_id=v_arc_id AND state > 0;

						UPDATE plan_psector_x_connec SET link_id=NULL WHERE arc_id=v_arc_id;
						UPDATE plan_psector_x_connec SET arc_id=NULL WHERE arc_id=v_arc_id;

						-- gully
						IF v_project_type='UD' THEN

							SELECT array_agg(gully_id) INTO v_array_gully FROM gully g JOIN link ON link.feature_id=gully_id WHERE link.feature_type='GULLY' AND arc_id=v_arc_id  AND
							g.state = 1;
							
							SELECT count(gully_id) INTO v_count_gully FROM ve_gully WHERE arc_id=v_arc_id AND state > 0;

							UPDATE plan_psector_x_gully SET link_id=NULL WHERE arc_id=v_arc_id;
							UPDATE plan_psector_x_gully SET arc_id=NULL WHERE arc_id=v_arc_id;
						END IF;

						-- Insert data into traceability table
						select code INTO v_code FROM ve_arc  WHERE arc_id=v_arc_id;

						INSERT INTO audit_arc_traceability ("type", arc_id, code,arc_id1, arc_id2, node_id, tstamp, cur_user)
						VALUES ('DIVIDE ARC',  v_arc_id, v_code, rec_aux1.arc_id, rec_aux2.arc_id, v_node_id,CURRENT_TIMESTAMP,CURRENT_USER);

						-- Update elements from old arc to new arcs
						SELECT count(*) into v_count FROM element_x_arc WHERE arc_id=v_arc_id;

						IF v_count > 0 THEN
							FOR rec_aux IN SELECT * FROM element_x_arc WHERE arc_id=v_arc_id  LOOP
								INSERT INTO element_x_arc (element_id, arc_id) VALUES (rec_aux.element_id, rec_aux1.arc_id);
								INSERT INTO element_x_arc (element_id, arc_id) VALUES (rec_aux.element_id, rec_aux2.arc_id);
								DELETE FROM element_x_arc WHERE arc_id=v_arc_id;
							END LOOP;

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3358", "function":"2114", "parameters":{"v_count":"'||v_count||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';


						END IF;

						-- Update documents from old arc to the new arcs
						SELECT count(*) into v_count FROM doc_x_arc WHERE arc_id=v_arc_id;
						IF v_count > 0 THEN
							FOR rec_aux IN SELECT * FROM doc_x_arc WHERE arc_id=v_arc_id  LOOP
								INSERT INTO doc_x_arc (doc_id, arc_id) VALUES (rec_aux.doc_id, rec_aux1.arc_id);
								INSERT INTO doc_x_arc (doc_id, arc_id) VALUES (rec_aux.doc_id, rec_aux2.arc_id);
								DELETE FROM doc_x_arc WHERE arc_id=v_arc_id;
							END LOOP;

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3360", "function":"2114", "parameters":{"v_count":"'||v_count||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';
						END IF;

						-- Update visits from old arc to the new arcs (only for state=1, state=1)
						SELECT count(*) INTO v_count FROM om_visit_x_arc WHERE arc_id=v_arc_id;

						IF v_count > 0 THEN
							FOR rec_visit IN SELECT om_visit.* FROM om_visit_x_arc JOIN om_visit ON om_visit.id=visit_id WHERE arc_id=v_arc_id
							LOOP
								IF rec_visit.the_geom IS NULL AND rec_visit.id IS NOT NULL THEN -- if visit does not has geometry, events may have. It's mandatory to distribute one by one

									-- Get visit data into two new visits
									INSERT INTO om_visit (visitcat_id, ext_code, startdate, enddate, user_name, webclient_id,expl_id,descript,is_done, lot_id, class_id, status, visit_type)
									VALUES (rec_visit.visitcat_id, rec_visit.ext_code, rec_visit.startdate, rec_visit.enddate, rec_visit.user_name, rec_visit.webclient_id, rec_visit.expl_id,
									rec_visit.descript, rec_visit.is_done, rec_visit.lot_id, rec_visit.class_id, rec_visit.status, rec_visit.visit_type)
									RETURNING id INTO v_newvisit1;

									INSERT INTO om_visit (visitcat_id, ext_code, startdate, enddate, user_name, webclient_id,expl_id,descript,is_done, lot_id, class_id, status, visit_type)
									VALUES (rec_visit.visitcat_id, rec_visit.ext_code, rec_visit.startdate, rec_visit.enddate, rec_visit.user_name, rec_visit.webclient_id, rec_visit.expl_id,
									rec_visit.descript, rec_visit.is_done, rec_visit.lot_id, rec_visit.class_id, rec_visit.status, rec_visit.visit_type)
									RETURNING id INTO v_newvisit2;

									FOR rec_event IN SELECT * FROM om_visit_event WHERE visit_id=rec_visit.id LOOP

										IF rec_event.xcoord IS NOT NULL AND rec_event.ycoord IS NOT NULL THEN -- event must be related to one of the two new visits

											--  Locate position of the nearest point
											v_eventlocation := ST_LineLocatePoint(v_arc_geom, ST_ClosestPoint(v_arc_geom, ST_setSrid(ST_MakePoint(rec_event.xcoord, rec_event.ycoord), v_srid)));

											IF v_eventlocation < v_intersect_loc THEN
												UPDATE om_visit_event SET visit_id=v_newvisit1 WHERE id=rec_event.id;
											ELSE
												UPDATE om_visit_event SET visit_id=v_newvisit2 WHERE id=rec_event.id;
											END IF;
										ELSE 	-- event must be related on both new visits. As a result, new event must be created

											-- insert new event related to new visit1
											INSERT INTO om_visit_event (event_code, visit_id, position_id, position_value, parameter_id,value, value1, value2,geom1, geom2,
											geom3,xcoord,ycoord,compass,text, index_val,is_last)
											SELECT event_code, v_newvisit1, position_id, position_value, parameter_id,value, value1, value2,geom1, geom2,
											geom3,xcoord,ycoord,compass,text, index_val,is_last FROM om_visit_event WHERE id=rec_event.id;

											-- insert new event related to new visit2
											INSERT INTO om_visit_event (event_code, visit_id, position_id, position_value, parameter_id,value, value1, value2,geom1, geom2,
											geom3,xcoord,ycoord,compass,text, index_val,is_last)
											SELECT event_code, v_newvisit2, position_id, position_value, parameter_id,value, value1, value2,geom1, geom2,
											geom3,xcoord,ycoord,compass,text, index_val,is_last FROM om_visit_event WHERE id=rec_event.id;
										END IF;
									END LOOP;

									INSERT INTO om_visit_x_arc (visit_id, arc_id) VALUES (v_newvisit1, rec_aux1.arc_id) ON CONFLICT (visit_id, arc_id) DO NOTHING;
									INSERT INTO om_visit_x_arc (visit_id, arc_id) VALUES (v_newvisit2, rec_aux2.arc_id) ON CONFLICT (visit_id, arc_id) DO NOTHING;

									-- delete old visit
									DELETE FROM om_visit WHERE id=rec_visit.id;

								ELSIF rec_visit.the_geom IS NOT NULL THEN -- if visit has geometry, events does not have geometry

									--  Locate position of the nearest point
									v_visitlocation := ST_LineLocatePoint(v_arc_geom, ST_ClosestPoint(v_arc_geom, rec_visit.the_geom));

									IF v_visitlocation < v_intersect_loc THEN
										v_newarc = rec_aux1.arc_id;
									ELSE
										v_newarc = rec_aux2.arc_id;
									END IF;

									-- distribute visit to new arc
									INSERT INTO om_visit_x_arc (visit_id, arc_id) VALUES (rec_visit.id, v_newarc) ON CONFLICT (visit_id, arc_id) DO NOTHING;
									DELETE FROM om_visit_x_arc WHERE arc_id=v_arc_id;
								END IF;
							END LOOP;

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3362", "function":"2114", "parameters":{"v_count":"'||v_count||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';

						END IF;

						-- reconnect operative connec links
						FOR rec_link IN SELECT * FROM link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 1 AND feature_type  ='CONNEC'
						LOOP
							SELECT arc_id INTO v_arc_closest FROM link l, ve_arc a WHERE st_dwithin(a.the_geom, st_endpoint(l.the_geom),1) AND l.link_id = rec_link.link_id
							AND arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) LIMIT 1;
							UPDATE connec SET arc_id = v_arc_closest WHERE arc_id = v_arc_id AND connec_id = rec_link.feature_id;
							UPDATE link SET exit_id = v_arc_closest WHERE link_id = rec_link.link_id;
						END LOOP;

						-- reconnect operative gully links
						FOR rec_link IN SELECT * FROM link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 1 AND feature_type  ='GULLY'
						LOOP
							SELECT arc_id INTO v_arc_closest FROM link l, ve_arc a WHERE st_dwithin(a.the_geom, st_endpoint(l.the_geom),1) AND l.link_id = rec_link.link_id
							AND arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) LIMIT 1;
							UPDATE gully SET arc_id = v_arc_closest WHERE arc_id = v_arc_id AND gully_id = rec_link.feature_id;
							UPDATE link SET exit_id = v_arc_closest WHERE link_id = rec_link.link_id;
						END LOOP;

						-- reconnect connecs without link but with arc_id
						FOR rec_connec IN SELECT connec_id FROM connec WHERE arc_id=v_arc_id AND state = 1
						AND connec_id NOT IN (SELECT DISTINCT feature_id FROM link WHERE exit_id=v_arc_id)
						LOOP
							SELECT a.arc_id INTO v_arc_closest FROM connec c, ve_arc a WHERE st_dwithin(a.the_geom, c.the_geom, 100) AND c.connec_id = rec_connec.connec_id
							AND a.arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) ORDER BY st_distance(a.the_geom, c.the_geom) ASC LIMIT 1;
							
							UPDATE connec SET arc_id = v_arc_closest WHERE connec_id = rec_connec.connec_id;
						
						END LOOP;

						-- reconnec operative gully without link but with arc_id
						IF v_project_type='UD' THEN
							FOR rec_gully IN SELECT gully_id FROM gully WHERE arc_id=v_arc_id AND state = 1 AND pjoint_type='ARC'
							AND gully_id NOT IN (SELECT DISTINCT feature_id FROM link WHERE exit_id=v_arc_id)
							LOOP
								SELECT a.arc_id INTO v_arc_closest FROM gully g, ve_arc a WHERE st_dwithin(a.the_geom, g.the_geom, 100) AND g.gully_id = rec_gully.gully_id
								AND a.arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) LIMIT 1;
								UPDATE gully SET arc_id = v_arc_closest WHERE arc_id = v_arc_id AND gully_id = rec_gully.gully_id;
								UPDATE link SET exit_id = v_arc_closest WHERE link_id = rec_link.link_id;
								v_arc_closest = null;
							END LOOP;
						END IF;

						-- reconnect operative node links from node_1
						FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'NODE' AND exit_id = (SELECT node_1 FROM arc WHERE arc_id = rec_aux1.arc_id)
						LOOP
							UPDATE link SET exit_id = rec_aux1.arc_id  WHERE link_id = rec_link.link_id;
							UPDATE connec SET arc_id = rec_aux1.arc_id WHERE arc_id = v_arc_id AND connec_id = rec_link.feature_id;
							IF v_project_type ='UD' THEN
								UPDATE gully SET arc_id = rec_aux1.arc_id WHERE arc_id = v_arc_id AND gully_id = rec_link.feature_id;
							END IF;
						END LOOP;

						-- reconnect operative node links from node_2
						FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'NODE' AND exit_id = (SELECT node_2 FROM arc WHERE arc_id = rec_aux2.arc_id)
						LOOP
							UPDATE link SET exit_id = rec_aux2.arc_id  WHERE link_id = rec_link.link_id;
							UPDATE connec SET arc_id = rec_aux2.arc_id WHERE arc_id = v_arc_id AND connec_id = rec_link.feature_id;
							IF v_project_type ='UD' THEN
								UPDATE gully SET arc_id = rec_aux2.arc_id WHERE arc_id = v_arc_id AND gully_id = rec_link.feature_id;
							END IF;
						END LOOP;

						-- reconnect planned node links from node_1
						FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'NODE' AND exit_id = (SELECT node_1 FROM arc WHERE arc_id = rec_aux1.arc_id)
						LOOP
							UPDATE plan_psector_x_connec SET arc_id = rec_aux1.arc_id WHERE link_id = rec_link.link_id;
							IF v_project_type ='UD' THEN
								UPDATE plan_psector_x_gully SET arc_id = rec_aux1.arc_id WHERE link_id = rec_link.feature_id;
							END IF;
						END LOOP;

						-- reconnect planned node links from node_2
						FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'NODE' AND exit_id = (SELECT node_2 FROM arc WHERE arc_id = rec_aux2.arc_id)
						LOOP
							UPDATE plan_psector_x_connec SET arc_id = rec_aux2.arc_id WHERE link_id = rec_link.link_id;
							IF v_project_type ='UD' THEN
								UPDATE plan_psector_x_gully SET arc_id = rec_aux2.arc_id WHERE link_id = rec_link.feature_id;
							END IF;
						END LOOP;

						-- reconnect planned connec links
						FOR rec_link IN SELECT * FROM link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 2 AND feature_type  ='CONNEC'
						LOOP
							EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
							"feature":{"id":['|| rec_link.feature_id||']},"data":{"linkId":"'||rec_link.link_id||'", "feature_type":"CONNEC", "forcedArcs":['||rec_aux1.arc_id||','||rec_aux2.arc_id||']}}$$)';
						END LOOP;

						-- reconnect planned gully links
						FOR rec_link IN SELECT * FROM link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 2 AND feature_type  ='GULLY'
						LOOP
							EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
							"feature":{"id":['|| rec_link.feature_id||']},"data":{"linkId":"'||rec_link.link_id||'", "feature_type":"GULLY", "forcedArcs":['||rec_aux1.arc_id||','||rec_aux2.arc_id||']}}$$)';
						END LOOP;

						IF v_project_type = 'WS' THEN

							--reconfigure mapzones
							IF v_new_node_graph IS NOT NULL THEN

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3364", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';
							END IF;

							IF v_node1_graph IS NOT NULL THEN
								IF rec_aux1.node_1 =v_node_1 OR rec_aux1.node_2 = v_node_1 THEN
									v_graph_arc_id =  rec_aux1.arc_id;
								ELSIF rec_aux2.node_1 =v_node_1 OR rec_aux2.node_2 = v_node_1 THEN
									v_graph_arc_id =  rec_aux2.arc_id;
								END IF;

								EXECUTE 'SELECT gw_fct_setmapzoneconfig($${
								"data":{"parameters":{"nodeIdOld":"'||v_node_1||'", "arcIdOld":"'||v_arc_id||'", "arcIdNew":"'||v_graph_arc_id||'", "action":"updateArc"}}}$$);';

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2114", "fid":"212", "criticity":"0", "is_process":true, "is_header":"true"}}$$)';

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3366", "function":"2114", "fid":"212", "criticity":"0", "is_process":true}}$$)';

							END IF;

							IF v_node2_graph IS NOT NULL THEN
								IF rec_aux1.node_1 =v_node_2 OR rec_aux1.node_2 = v_node_2 THEN
									v_graph_arc_id =  rec_aux1.arc_id;
								ELSIF rec_aux2.node_1 =v_node_2 OR rec_aux2.node_2 = v_node_2 THEN
									v_graph_arc_id =  rec_aux2.arc_id;
								END IF;

								EXECUTE 'SELECT gw_fct_setmapzoneconfig($${
								"data":{"parameters":{"nodeIdOld":"'||v_node_2||'", "arcIdOld":"'||v_arc_id||'", "arcIdNew":"'||v_graph_arc_id||'", "action":"updateArc"}}}$$);';

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"function":"2114", "fid":"212", "criticity":"0", "is_process":true, "is_header":"true"}}$$)';

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3368", "function":"2114", "fid":"212", "criticity":"0", "is_process":true}}$$)';
							END IF;
						END IF;

						--set arc to obsolete or delete it
						IF v_set_arc_obsolete IS TRUE THEN
							UPDATE arc SET state=0, state_type=v_obsoletetype  WHERE arc_id=v_arc_id;

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3370", "function":"2114", "parameters":{"v_arc_id":"'||v_arc_id||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';

						ELSE
							EXECUTE 'SELECT gw_fct_setfeaturedelete($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, 
							"feature":{"type":"ARC"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_id":"'||v_arc_id||'"}}$$);';

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3382", "function":"2114", "parameters":{"v_arc_id":"'||v_arc_id||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';
						END IF;

					IF (SELECT EXISTS (SELECT arc_id FROM plan_psector_x_arc WHERE arc_id = v_arc_id)) IS TRUE THEN -- the divided arc IS involved INTO a psector WITH p_state=0
						
							INSERT INTO plan_psector_x_arc (arc_id, psector_id, state, insert_tstamp, insert_user)
							SELECT rec_aux1.arc_id, psector_id, 0, now(), current_user FROM plan_psector_x_arc WHERE arc_id = v_arc_id;
						
							INSERT INTO plan_psector_x_arc (arc_id, psector_id, state, insert_tstamp, insert_user)
							SELECT rec_aux2.arc_id, psector_id, 0, now(), current_user FROM plan_psector_x_arc WHERE arc_id = v_arc_id;


							-- downgrade the features, as the divided arc will be eventually downgraded according to plan_psector_x_arc.status
							INSERT INTO plan_psector_x_node (node_id, psector_id, state, insert_tstamp, insert_user)
							SELECT v_node_id, psector_id, 0, now(), current_user FROM plan_psector_x_arc WHERE arc_id = v_arc_id;

							-- remove old arc references from psector
							DELETE FROM plan_psector_x_arc WHERE arc_id = v_arc_id;
	
						END IF;

					ELSIF v_state_node = 2 THEN --is psector

						-- set temporary values for config variables in order to enable the insert of arc in spite of due a 'bug' of postgres (it seems that does not recognize the new node inserted)
						UPDATE config_param_user SET value=TRUE WHERE parameter = 'edit_disable_statetopocontrol' AND cur_user=current_user;

						-- manage plan_psector_force_delete in order to enable delete from old planified arcs
						SELECT value INTO v_force_delete FROM config_param_user WHERE parameter = 'plan_psector_force_delete' AND cur_user=current_user;
						UPDATE config_param_user SET value='true' WHERE parameter = 'plan_psector_force_delete' AND cur_user=current_user;

						IF v_state_arc = 1 THEN -- ficticius arc

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3384", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

							rec_aux1.state=2;
							rec_aux1.state_type=v_ficticius;

							rec_aux2.state=2;
							rec_aux2.state_type=v_ficticius;

						ELSIF v_state_arc = 2 THEN -- planned arc

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3386", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

						END IF;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3388", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';


						INSERT INTO audit_check_data (fid,  criticity, error_message)
						VALUES (212, 1, concat('Arc1: arc_id:', rec_aux1.arc_id,', code:',rec_aux1.code,' length:',
						round(st_length(rec_aux1.the_geom)::numeric,2),'.'));

						INSERT INTO audit_check_data (fid,  criticity, error_message)
						VALUES (212, 1, concat('Arc2: arc_id:', rec_aux2.arc_id,', code:',rec_aux2.code,' length:',
						round(st_length(rec_aux2.the_geom)::numeric,2),'.'));

						-- Insert new records into arc table
						INSERT INTO arc SELECT rec_aux1.*;
						INSERT INTO arc SELECT rec_aux2.*;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3390", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

						-- Insert new records into man table
						EXECUTE v_manquerytext1||rec_aux1.arc_id||v_manquerytext2;
						EXECUTE v_manquerytext1||rec_aux2.arc_id||v_manquerytext2;

						-- Insert new records into epa table
						EXECUTE v_epaquerytext1||rec_aux1.arc_id||v_epaquerytext2;
						EXECUTE v_epaquerytext1||rec_aux2.arc_id||v_epaquerytext2;

						-- restore temporary value for edit_disable_statetopocontrol variable
						UPDATE config_param_user SET value=FALSE WHERE parameter = 'edit_disable_statetopocontrol' AND cur_user=current_user;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3392", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

						-- update node_1 and node_2 because it's not possible to pass using parameters
						UPDATE arc SET node_1=rec_aux1.node_1,node_2=rec_aux1.node_2 where arc_id=rec_aux1.arc_id;
						UPDATE arc SET node_1=rec_aux2.node_1,node_2=rec_aux2.node_2 where arc_id=rec_aux2.arc_id;

						-- update link only with enabled variable
						IF (SELECT (value::json->>'fid')::boolean FROM config_param_system WHERE parameter='edit_custom_link') IS TRUE THEN
							UPDATE arc SET link=rec_aux1.arc_id where arc_id=rec_aux1.arc_id;
							UPDATE arc SET link=rec_aux2.arc_id where arc_id=rec_aux2.arc_id;
						END IF;

						v_arc_childtable_name := 'man_arc_' || lower(v_arc_type);

						IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE table_schema = v_schemaname AND table_name = v_arc_childtable_name)) IS TRUE THEN
							EXECUTE 'INSERT INTO '||v_arc_childtable_name||' (arc_id) VALUES ('''||rec_aux1.arc_id||''');';
							EXECUTE 'INSERT INTO '||v_arc_childtable_name||' (arc_id) VALUES ('''||rec_aux2.arc_id||''');';


							v_sql := 'SELECT column_name FROM information_schema.columns 
									WHERE table_schema = ''SCHEMA_NAME'' 
									AND table_name = '''||v_arc_childtable_name||''' 
									AND column_name !=''id'' AND column_name != ''arc_id'' ;';

							FOR rec_addfields IN EXECUTE v_sql
							LOOP

								v_query_string_update = 'UPDATE '||v_arc_childtable_name||' SET '||rec_addfields.column_name|| ' = '
														'( SELECT '||rec_addfields.column_name||' FROM '||v_arc_childtable_name||' WHERE arc_id = '||quote_literal(v_arc_id)||' ) '
														'WHERE '||v_arc_childtable_name||'.arc_id = '||quote_literal(rec_aux1.arc_id)||';';

								IF v_query_string_update IS NOT NULL THEN
									EXECUTE v_query_string_update;
								END IF;

								v_query_string_update = 'UPDATE '||v_arc_childtable_name||' SET '||rec_addfields.column_name|| ' = '
														'( SELECT '||rec_addfields.column_name||' FROM '||v_arc_childtable_name||' WHERE arc_id = '||quote_literal(v_arc_id)||' ) '
														'WHERE '||v_arc_childtable_name||'.arc_id = '||quote_literal(rec_aux2.arc_id)||';';

								IF v_query_string_update IS NOT NULL THEN
									EXECUTE v_query_string_update;
								END IF;

							END LOOP;

							EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3394", "function":"2114", "parameters":{"v_arc_id":"'||v_arc_id||'", "rec_aux1.arc_id":"'||rec_aux1.arc_id||'", "rec_aux2.arc_id":"'||rec_aux2.arc_id||'" },"fid":"212", "result_id":"arc divide", "is_process":true}}$$)';
						END IF;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3396", "function":"2114","fid":"212", "criticity":"1", "is_process":true}}$$)';

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3398", "function":"2114","fid":"212", "criticity":"1", "is_process":true}}$$)';

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3400", "function":"2114","fid":"212", "criticity":"1", "is_process":true}}$$)';

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3402", "function":"2114","fid":"212", "criticity":"1", "is_process":true}}$$)';


						IF v_project_type='WS' THEN

							-- reconnect nodes (update arc_id of disconnected nodes linked to old arc)
							FOR rec_node IN SELECT node_id, the_geom FROM ve_node WHERE arc_id=v_arc_id AND state = 2
							LOOP
								UPDATE node SET arc_id=(SELECT arc_id FROM ve_arc WHERE ST_DWithin(rec_node.the_geom,
								ve_arc.the_geom,0.001) AND arc_id != v_arc_id LIMIT 1)
								WHERE node_id=rec_node.node_id;

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3404", "function":"2114", "parameters":{"rec_node.node_id":"'||rec_node.node_id||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';

							END LOOP;
						END IF;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3406", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

						IF v_state_arc = 1 THEN -- ficticius arc

							-- Insert data into traceability table
							INSERT INTO audit_arc_traceability ("type", arc_id, code, arc_id1, arc_id2, node_id, tstamp, cur_user)
							VALUES ('DIVIDE EXISTING ARC WITH PLANNED NODE',  v_arc_id, v_code, rec_aux1.arc_id, rec_aux2.arc_id, v_node_id, now(), current_user);

							-- insert operative connec's on alternative in order to reconnect (upgrade)
							INSERT INTO plan_psector_x_connec (psector_id, connec_id, state, doable, arc_id)
							SELECT v_psector, connec_id, 1, false, null FROM connec WHERE arc_id = v_arc_id AND connec.state=1
							ON CONFLICT (psector_id, connec_id, state) DO NOTHING;

							-- insert operative connec's on alternative in order to reconnect (donwgrade)
							INSERT INTO plan_psector_x_connec (psector_id, connec_id, state, doable, link_id, arc_id)
							SELECT v_psector, connec_id, 0, false, link_id, arc_id FROM connec LEFT JOIN link ON feature_id = connec_id
							WHERE arc_id = v_arc_id AND connec.state=1 ON CONFLICT (psector_id, connec_id, state) DO NOTHING;

							IF v_project_type='UD' THEN

								-- insert operative connec's on alternative in order to reconnect (upgrade)
								INSERT INTO plan_psector_x_gully (psector_id, gully_id, state, doable, arc_id)
								SELECT v_psector, gully_id, 1, false, null FROM gully WHERE arc_id = v_arc_id AND gully.state=1
								ON CONFLICT (psector_id, gully_id, state) DO NOTHING;

								-- insert operative gully's on alternative in order to reconnect (donwgrade)
								INSERT INTO plan_psector_x_gully (psector_id, gully_id, state, doable, link_id, arc_id)
								SELECT v_psector, gully_id, 0, false, link_id, arc_id FROM gully LEFT JOIN link ON feature_id = gully_id
								WHERE arc_id = v_arc_id AND gully.state=1 ON CONFLICT (psector_id, gully_id, state) DO NOTHING;

							END IF;

							-- Insert existig arc (downgraded) to the current alternative
							INSERT INTO plan_psector_x_arc (psector_id, arc_id, state, doable) VALUES (v_psector, v_arc_id, 0, FALSE)
							ON CONFLICT (arc_id, psector_id) DO NOTHING;

							-- reconnect operative connec links related to other connects
							FOR rec_link IN SELECT * FROM link l JOIN plan_psector_x_connec p USING (link_id) WHERE exit_type != 'ARC' AND p.arc_id = v_arc_id AND feature_type  ='CONNEC'
							LOOP
								EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
								"feature":{"id":['|| rec_link.feature_id||']},"data":{"feature_type":"CONNEC"}}$$)';
							END LOOP;

							-- reconnect operative connec links
							FOR rec_link IN SELECT * FROM link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 1 AND feature_type  ='CONNEC'
							LOOP
								EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
								"feature":{"id":['|| rec_link.feature_id||']},"data":{"feature_type":"CONNEC", "isArcDivide":"true", "forcedArcs":['||rec_aux1.arc_id||','||rec_aux2.arc_id||']}}$$)';
							END LOOP;

							-- connecs without link but with arc_id
							FOR rec_connec IN SELECT connec_id FROM connec WHERE arc_id=v_arc_id AND state = 1 AND pjoint_type='ARC'
							AND connec_id NOT IN (SELECT DISTINCT feature_id FROM link WHERE exit_id=v_arc_id)
							LOOP
								UPDATE plan_psector_x_connec pc SET arc_id=q.arc_id FROM (
								SELECT a.arc_id FROM arc a JOIN connec c ON st_dwithin(c.the_geom, a.the_geom, 100)
								WHERE a.arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) AND c.connec_id=rec_connec.connec_id
								order by ST_Distance(c.the_geom, a.the_geom) LIMIT 1
								)q WHERE connec_id=rec_connec.connec_id AND pc.state=1;

								UPDATE plan_psector_x_connec SET link_id= NULL WHERE connec_id=rec_connec.connec_id;
								DELETE FROM link WHERE feature_id=rec_connec.connec_id;
							END LOOP;


							IF v_project_type='UD' THEN

								-- reconnect operative gully links related to other connects
								FOR rec_link IN SELECT * FROM link l JOIN plan_psector_x_gully p USING (link_id) WHERE exit_type != 'ARC' AND p.arc_id = v_arc_id AND feature_type  ='GULLY'
								LOOP
									EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
									"feature":{"id":['|| rec_link.feature_id||']},"data":{"feature_type":"GULLY"}}$$)';
								END LOOP;

								-- reconnect operative gully links
								FOR rec_link IN SELECT * FROM link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 1 AND feature_type  ='GULLY'
								LOOP
									EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
									"feature":{"id":['|| rec_link.feature_id||']},"data":{"feature_type":"GULLY", "isArcDivide":"true", "forcedArcs":['||rec_aux1.arc_id||','||rec_aux2.arc_id||']}}$$)';
								END LOOP;

								-- gullys without link but with arc_id
								FOR rec_gully IN SELECT gully_id FROM gully WHERE arc_id=v_arc_id AND state = 1 AND pjoint_type='ARC'
								AND gully_id NOT IN (SELECT DISTINCT feature_id FROM link WHERE exit_id=v_arc_id)
								LOOP
									UPDATE plan_psector_x_gully pg SET arc_id=q.arc_id FROM (
									SELECT a.arc_id FROM arc a JOIN gully c ON st_dwithin(c.the_geom, a.the_geom, 100)
									WHERE a.arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) AND c.gully_id=rec_gully.gully_id
									order by ST_Distance(c.the_geom, a.the_geom) LIMIT 1
									)q WHERE gully_id=rec_gully.gully_id AND pg.state=1;

									UPDATE plan_psector_x_gully SET link_id= NULL WHERE gully_id=rec_gully.gully_id;
									DELETE FROM link WHERE feature_id=rec_gully.gully_id;
								END LOOP;
							END IF;

							-- reconnect planned connec links
							FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 2 AND feature_type  ='CONNEC'
							LOOP
								EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
								"feature":{"id":['|| rec_link.feature_id||']},"data":{"feature_type":"CONNEC", "isArcDivide":"true","forcedArcs":['||rec_aux1.arc_id||','||rec_aux2.arc_id||']}}$$)';
							END LOOP;

							-- reconnect planned gully links
							FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'ARC' AND exit_id = v_arc_id AND state = 2 AND feature_type  ='GULLY'
							LOOP
								EXECUTE 'SELECT gw_fct_linktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
								"feature":{"id":['|| rec_link.feature_id||']},"data":{"feature_type":"GULLY", "isArcDivide":"true","forcedArcs":['||rec_aux1.arc_id||','||rec_aux2.arc_id||']}}$$)';
							END LOOP;

							-- reconnect planned node links
							FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'NODE' AND exit_id = (SELECT node_1 FROM arc WHERE arc_id = rec_aux1.arc_id)
							LOOP
								UPDATE plan_psector_x_connec SET arc_id = rec_aux1.arc_id, link_id = rec_link.link_id WHERE arc_id = v_arc_id AND connec_id = rec_link.feature_id;
								IF v_project_type ='UD' THEN
									UPDATE plan_psector_x_gully SET arc_id = rec_aux1.arc_id, link_id = rec_link.link_id WHERE arc_id = v_arc_id AND gully_id = rec_link.feature_id;
								END IF;
							END LOOP;

							-- Update doability for the new arcs
							UPDATE plan_psector_x_arc SET doable=FALSE where arc_id=rec_aux1.arc_id;
							UPDATE plan_psector_x_arc SET doable=FALSE where arc_id=rec_aux2.arc_id;

						ELSIF v_state_arc = 2 THEN -- planned arc

							-- Insert data into traceability table
							INSERT INTO audit_arc_traceability ("type", arc_id, code, arc_id1, arc_id2, node_id, tstamp, cur_user)
							VALUES ('DIVIDE PLANNED ARC WITH PLANNED NODE',  v_arc_id, v_code, rec_aux1.arc_id, rec_aux2.arc_id, v_node_id, CURRENT_TIMESTAMP, CURRENT_USER);

							-- in case of divide ficitius arc, new arcs will be ficticius, but we need to set doable false because they are inserted by default as true
							IF (SELECT state_type FROM arc WHERE arc_id=v_arc_id) = v_ficticius THEN

								UPDATE plan_psector_x_arc SET doable=FALSE where arc_id=rec_aux1.arc_id;
								UPDATE plan_psector_x_arc SET doable=FALSE where arc_id=rec_aux2.arc_id;

								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       			"data":{"message":"3408", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

							END IF;

							-- reconnect planned connec links
							FOR rec_link IN SELECT link.* FROM link JOIN plan_psector_x_connec USING (link_id)
							WHERE link.feature_type='CONNEC' AND exit_type='ARC' AND arc_id=v_arc_id
							LOOP
								SELECT arc_id INTO v_arc_closest FROM ve_link l, ve_arc a WHERE st_dwithin(a.the_geom, st_endpoint(l.the_geom),1) AND l.link_id = rec_link.link_id
								AND arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) LIMIT 1;
								UPDATE plan_psector_x_connec SET arc_id = v_arc_closest WHERE arc_id = v_arc_id AND connec_id = rec_link.feature_id;
								v_arc_closest = null;
							END LOOP;

							-- connecs without link but with arc_id
							FOR rec_connec IN SELECT connec_id FROM ve_connec WHERE arc_id=v_arc_id AND state = 1 AND pjoint_type='ARC'
							AND connec_id NOT IN (SELECT DISTINCT feature_id FROM link WHERE exit_id=v_arc_id)
							LOOP
								UPDATE plan_psector_x_connec pc SET arc_id=q.arc_id FROM (
								SELECT a.arc_id FROM arc a JOIN connec c ON st_dwithin(c.the_geom, a.the_geom, 100)
								WHERE a.arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) AND c.connec_id=rec_connec.connec_id
								order by ST_Distance(c.the_geom, a.the_geom) LIMIT 1
								)q WHERE connec_id=rec_connec.connec_id AND pc.state=1;

								UPDATE plan_psector_x_connec SET link_id= NULL WHERE connec_id=rec_connec.connec_id;
								DELETE FROM link WHERE feature_id=rec_connec.connec_id;
							END LOOP;


							IF v_project_type ='UD' THEN

								-- reconnect planned gully links
								FOR rec_link IN SELECT link.* FROM link JOIN plan_psector_x_gully USING (link_id)
								WHERE link.feature_type='GULLY' AND exit_type='ARC' AND arc_id=v_arc_id
								LOOP
									SELECT arc_id INTO v_arc_closest FROM ve_link l, ve_arc a WHERE st_dwithin(a.the_geom, st_endpoint(l.the_geom),1) AND l.link_id = rec_link.link_id
									AND arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) LIMIT 1;
									UPDATE plan_psector_x_gully SET arc_id = v_arc_closest WHERE arc_id = v_arc_id AND gully_id = rec_link.feature_id;
									v_arc_closest = null;
								END LOOP;

								-- reconnect gullys without link but with arc_id
								FOR rec_gully IN SELECT gully_id FROM ve_gully WHERE arc_id=v_arc_id AND state = 1 AND pjoint_type='ARC'
								AND gully_id NOT IN (SELECT DISTINCT feature_id FROM link WHERE exit_id=v_arc_id)
								LOOP
									UPDATE plan_psector_x_gully pg SET arc_id=q.arc_id FROM (
									SELECT a.arc_id FROM arc a JOIN gully c ON st_dwithin(c.the_geom, a.the_geom, 100)
									WHERE a.arc_id IN (rec_aux1.arc_id, rec_aux2.arc_id) AND c.gully_id=rec_gully.gully_id
									order by ST_Distance(c.the_geom, a.the_geom) LIMIT 1
									)q WHERE gully_id=rec_gully.gully_id AND pg.state=1;

									UPDATE plan_psector_x_gully SET link_id= NULL WHERE gully_id=rec_gully.gully_id;
									DELETE FROM link WHERE feature_id=rec_gully.gully_id;
								END LOOP;
							END IF;

							-- reconnect planned node links
							FOR rec_link IN SELECT * FROM ve_link WHERE exit_type = 'NODE' AND exit_id = (SELECT node_1 FROM arc WHERE arc_id = rec_aux1.arc_id)
							LOOP
								UPDATE plan_psector_x_connec SET arc_id = rec_aux1.arc_id WHERE connec_id = rec_link.feature_id;
								IF v_project_type ='UD' THEN
									UPDATE plan_psector_x_gully SET arc_id = rec_aux1.arc_id WHERE gully_id = rec_link.feature_id;
								END IF;
							END LOOP;

							DELETE FROM plan_psector_x_arc WHERE arc_id  =v_arc_id AND psector_id = v_psector;

							SELECT count(*) INTO v_count FROM plan_psector_x_arc WHERE arc_id=v_arc_id;

							IF v_count = 0 THEN
								DELETE FROM arc WHERE arc_id=v_arc_id;
							END IF;

							UPDATE config_param_user SET value=v_force_delete WHERE parameter = 'plan_psector_force_delete' AND cur_user=current_user;
						END IF;

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3410", "function":"2114", "parameters":{"v_psector":"'||v_psector||'"}, "fid":"212", "criticity":"1", "is_process":true}}$$)';

						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3412", "function":"2114", "fid":"212", "criticity":"1", "is_process":true}}$$)';

						-- Set addparam (parent/child)
						UPDATE plan_psector_x_arc SET addparam='{"arcDivide":"parent"}' WHERE  psector_id=v_psector AND arc_id=v_arc_id;
						UPDATE plan_psector_x_arc SET addparam='{"arcDivide":"child"}' WHERE  psector_id=v_psector AND arc_id=rec_aux1.arc_id;
						UPDATE plan_psector_x_arc SET addparam='{"arcDivide":"child"}' WHERE  psector_id=v_psector AND arc_id=rec_aux2.arc_id;


					ELSIF (v_state_arc=2 AND v_state_node=1) THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3042", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
					ELSE
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3044", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
					END IF;

				-- set values of node
				UPDATE node SET sector_id = rec_aux1.sector_id, omzone_id = rec_aux1.omzone_id, muni_id = rec_aux1.muni_id WHERE node_id = v_node_id;

					IF v_project_type ='WS' THEN

						UPDATE node SET presszone_id = rec_aux1.presszone_id, dqa_id = rec_aux1.dqa_id, dma_id = rec_aux1.dma_id,
						minsector_id = rec_aux1.minsector_id WHERE node_id = v_node_id;

					ELSIF v_project_type ='UD' THEN

						-- set y1/y2 to null for those values related to new node
						update config_param_system set value = false WHERE parameter='edit_state_topocontrol' ;
						UPDATE arc SET y2=null WHERE arc_id = rec_aux1.arc_id;
						UPDATE arc SET y1=null WHERE arc_id = rec_aux2.arc_id;
						update config_param_system set value = true WHERE parameter='edit_state_topocontrol' ;
					END IF;
					
					
				END IF;
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"3044", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
			END IF;
		ELSE
			IF v_node_type IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3046", "function":"2114","parameters":{"node_type":"'||v_node_type||'"}, "is_process":true}}$$);' INTO v_audit_result;
			ELSE

				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3046", "function":"2114","parameters":null, "is_process":true}}$$);' INTO v_audit_result;
			END IF;
		END IF;
	END IF;

	

	-- get results
	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM audit_check_data
	WHERE cur_user="current_user"() AND fid=212 ORDER BY criticity desc, id asc) row;

	IF v_audit_result is null THEN
		v_status = 'Accepted';
		v_level = 3;

		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3414", "function":"2114", "is_process":true}}$$)::JSON->>''text''' INTO v_message;

	ELSE
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;

	END IF;

	v_result_info := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result_info, '}');

	v_status := COALESCE(v_status, '{}');
	v_level := COALESCE(v_level, '0');
	v_message := COALESCE(v_message, '{}');
	v_hide_form := COALESCE(v_hide_form, true);

	--  Return
	RETURN ('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||'}'||
				', "actions":{"hideForm":' || v_hide_form || '}'||
		       '}'||
	    '}')::json;

	--EXCEPTION WHEN OTHERS THEN
	--GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	--RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
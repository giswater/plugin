/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3188

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_connect_to_network(character varying[], character varying);
DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_connect_to_network(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_linktonetwork(p_data json)
RETURNS json AS
$BODY$


/*
GOAL
----
This function have been refactorized on 2022/12 changing the full strategy of links

DESCRIPTION
-----------
No doubt this is the most important function for links. Lots of procedures and workflows works with this function. See: https://github.com/giswater/plugin/wiki/Links-Workflows.
Main workflows:
- Create a new link with or without defined target for operative connects
- Create a new link  with or without defined target for operative connects in order to be used on psector strategy
- Create a new link with or without defined target for planned connects
- Redraw an existing link when target feature have been changed
- Reverse link geom when need in order to repair it


EXAMPLES
--------
SELECT SCHEMA_NAME.gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":["3201","3200"]},"data":{"feature_type":"CONNEC", "forcedArcs":["2001","2002"]}}$$);

SELECT SCHEMA_NAME.gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":["3209"]},"data":{"feature_type":"CONNEC"}}$$);

SELECT SCHEMA_NAME.gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":["100013"]},"data":{"feature_type":"CONNEC", "forcedArcs":["221"]}}$$);

SELECT SCHEMA_NAME.gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":["100013"]},"data":{"feature_type":"CONNEC"}}$$);
SELECT SCHEMA_NAME.gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"id":["100014"]},"data":{"feature_type":"GULLY"}}$$);

SELECT SCHEMA_NAME.gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1,"lang":"ES"},"feature":
{"id":"SELECT array_to_json(array_agg(connec_id::text)) FROM ve_connec WHERE connec_id IS NOT NULL AND state=1"},"data":{"feature_type":"CONNEC"}}$$);

--fid: 217

*/

DECLARE


-- input variables
v_feature_type text;-- Type of features affected
v_feature_ids text; -- List of feature affected
v_forcedarcs text; -- Used to force only some specific arcs
v_isforcedarcs boolean; -- Check if forced arcs strategy is being used
v_ispsector boolean; -- When function is called from psector side (gw_trg_plan_psector_link)
v_isarcdivide boolean;	-- When function is called for arcdivide procedure (gw_fct_setarcdivide)
v_link_id integer; -- Id for link
v_psector_id_param integer; -- Psector ID from Python when psector is active

-- standard variables
v_projecttype text; -- To store project type (UD / WS)
v_version text; -- To store version of system
v_psector_current integer; -- Current psector related to user

-- process variables
v_i integer = 0;
v_connect record; -- Record to store the value for the used connect
v_link record; -- Record to store the value for the used link
v_link_point public.geometry;
v_arc record; -- Record to store the value for the used arc
v_connect_id  integer; -- id for the used connect
v_point_aux public.geometry; -- Variable to store the geometry of the end of the link
v_feature_array integer[]; -- Transforming v_feature_ids on real array
v_old_arc_id integer; -- Original arc_id for psector state=0 record

v_endfeature_geom public.geometry; -- Variable to store the geometry of the end object, as well as node, connec, gully or arc
v_pjointtype text; -- Type for the destination feature (ARC, NODE, CONNEC, GULLY)
v_pjointid integer; -- Id for the destination feature

v_count integer; -- Counter
v_count2 integer; -- Counter

v_isoperative_psector boolean = false; -- It shows when the worflow comes from psector but for those existing connects which they are involved on psector
v_existing_link integer; -- link_id: In case of psector for operative links, we collect the value of the operative link
v_linkfrompsector integer; -- link_id: It is the id of link stored on psector table
v_dfactor double precision;  -- Distance factor. Value 0-1 used to separate link from the endpoints of arcs. Only applied to ws. For UD it is more understandable to connect with nodes

v_fluidtype_value text;
v_dma_value integer;
v_fluidtype_autoupdate boolean;
v_dma_autoupdate boolean;
v_forceendpoint boolean = false;
v_force_reconnect boolean = false;
v_geom_point public.geometry;
v_linktype text;

-- return variables
v_result text;
v_result_info text;
v_result_point text;
v_result_line text;
v_result_polygon text;
v_error_context text;
v_audit_result text;
v_level integer;
v_status text;
v_message text;
v_check_arcdnom float;
v_check_maxdistance float;
v_checkeddiam text;
v_querytext text;
v_linkcat_id text;
v_linkcat_id_default text;
v_link_type text;
v_state_type integer;
v_man_table text;

v_min_arcdnom float;

BEGIN


	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get system variables
	SELECT project_type, giswater INTO v_projecttype, v_version FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT value INTO v_dma_autoupdate FROM config_param_system WHERE parameter = 'edit_connect_autoupdate_dma';
	SELECT value INTO v_fluidtype_autoupdate FROM config_param_system WHERE parameter = 'edit_connect_autoupdate_fluid';

	-- get parameters from input json
	v_feature_type =  ((p_data ->>'data')::json->>'feature_type'::text);
	v_feature_ids = ((p_data ->>'feature')::json->>'id'::text);
	v_forcedarcs = (p_data->>'data')::json->>'forcedArcs';
	v_ispsector = (p_data->>'data')::json->>'isPsector';
	v_forceendpoint = (p_data->>'data')::json->>'forceEndPoint';
	v_force_reconnect = (p_data->>'data')::json->>'forceReconnect';
	v_isarcdivide = (p_data->>'data')::json->>'isArcDivide';
	v_link_id = (p_data->>'data')::json->>'linkId';
	v_linkcat_id = (p_data->>'data')::json->>'linkcatId';
	v_linkcat_id_default = (SELECT value FROM config_param_user WHERE parameter = 'edit_linkcat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
	v_check_arcdnom = (p_data->>'data')::json->>'pipeDiameter';
	v_check_maxdistance = (p_data->>'data')::json->>'maxDistance';
	v_psector_id_param = ((p_data->>'data')::json->>'psectorId')::integer;

	-- get user variables (use psector from Python if provided, otherwise from config)
	v_psector_current = COALESCE(v_psector_id_param, (SELECT value::integer FROM config_param_user WHERE parameter = 'plan_psector_current' AND cur_user = current_user));

	--profilactic values
	IF v_forceendpoint IS NULL THEN v_forceendpoint = FALSE; END IF;
	IF v_force_reconnect IS NULL THEN v_force_reconnect = FALSE; END IF;

	--control v_check status and value and distance
	IF v_check_maxdistance IS NULL THEN v_check_maxdistance = 9999; END IF;
	IF v_check_arcdnom IS NULL THEN v_check_arcdnom = 9999; END IF;

	IF v_linkcat_id IS NULL AND v_linkcat_id_default IS NOT NULL THEN
		v_linkcat_id = v_linkcat_id_default;
	END IF;

  	IF v_projecttype = 'WS' THEN
		BEGIN
			SELECT min(ca.dnom::float) INTO v_min_arcdnom
			FROM cat_arc ca
			WHERE ca.id IN (
				SELECT DISTINCT arccat_id
				FROM arc
				JOIN vf_arc va ON va.arc_id = arc.arc_id
				WHERE state > 0 AND arccat_id IS NOT NULL
			);

			IF v_min_arcdnom IS NOT NULL AND v_check_arcdnom <= v_min_arcdnom THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3260", "function":"3188","parameters":{"edit_link_check_arcdnom":"'||v_check_arcdnom||'"}, "is_process":true}}$$);';
			END IF;
		EXCEPTION WHEN invalid_text_representation THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"4626", "function":"3188","parameters":{"invalid_dnom":"'||(SELECT string_agg(id, ',') FROM cat_arc WHERE trim(dnom) !~ '^[+-]?([0-9]+(\.[0-9]+)?|\.[0-9]+)$')||'"}, "is_process":true}}$$);';
		END;
	END IF;

	-- create query text for forced arcs
	IF v_forcedarcs IS NULL THEN
		v_forcedarcs= '';
		v_isforcedarcs = False;
	ELSE
		v_forcedarcs = replace(ARRAY(SELECT json_array_elements_text(((p_data::json->>'data')::json->>'forcedArcs')::json))::text, '{','(');
		v_forcedarcs = concat (' AND arc_id::integer IN ', replace (v_forcedarcs, '}',')'));
		v_isforcedarcs = True;

		-- check if forced arcs really exists on ve_arc
		v_querytext = 'SELECT count(arc_id) FROM ve_arc WHERE arc_id IS NOT NULL '||v_forcedarcs||';';
		EXECUTE v_querytext INTO v_count;
		IF v_count=0 THEN
			v_forcedarcs= '';
			v_isforcedarcs = False;
		END IF;
	END IF;

	-- get values from feature array
	IF v_feature_ids ILIKE '[%]' THEN
		v_feature_array = ARRAY(SELECT json_array_elements_text(v_feature_ids::json)::integer);
	ELSE
		EXECUTE v_feature_ids INTO v_feature_ids;
		v_feature_array = ARRAY(SELECT json_array_elements_text(v_feature_ids::json)::integer);
	END IF;

	-- delete old values on result table
	DELETE FROM audit_check_data WHERE fid = 217 AND cur_user=current_user;

	-- Starting process

	EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1103","function":"3188","fid": 217,"v_criticity": 4}}$$);';

	EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1105","function":"3188","fid": 217,"v_criticity": 4}}$$);';

	-- Main loop
	IF v_feature_array IS NOT NULL THEN

	    FOREACH v_connect_id IN ARRAY v_feature_array
	    LOOP

			IF v_linkcat_id IS NULL THEN
				v_linkcat_id = (SELECT id FROM cat_link limit 1 offset 1);
			END IF;

			v_linktype = (SELECT link_type FROM cat_link WHERE id = v_linkcat_id);

			v_i = v_i+1;


			IF v_isforcedarcs IS FALSE THEN
				v_forcedarcs= '';
			END IF;

			IF v_projecttype = 'WS' OR v_projecttype = 'UD' THEN
				-- Different messages for different parameters passed
				IF v_check_arcdnom = 9999 THEN
					IF v_check_maxdistance = 9999 THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "4434","function":"3188","fid": 217,"v_criticity": 4, 
						"parameters":{"feature_type":"'||lower(v_feature_type)||'", "connect_id":"'||v_connect_id||'"}}}$$);';
					ELSE
						EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "4436","function":"3188","fid": 217,"v_criticity": 4, 
						"parameters":{"feature_type":"'||lower(v_feature_type)||'", "connect_id":"'||v_connect_id||'", "max_distance":"'||v_check_maxdistance||'"}}}$$);';
					END IF;
				ELSE
					IF v_check_maxdistance = 9999 THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "4438","function":"3188","fid": 217,"v_criticity": 4, 
						"parameters":{"feature_type":"'||lower(v_feature_type)||'", "connect_id":"'||v_connect_id||'", "check_arcdnom":"'||v_check_arcdnom||'"}}}$$);';
					ELSE
						EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "4440","function":"3188","fid": 217,"v_criticity": 4, 
						"parameters":{"feature_type":"'||lower(v_feature_type)||'", "connect_id":"'||v_connect_id||'", "check_arcdnom":"'||v_check_arcdnom||'", 
						"max_distance":"'||v_check_maxdistance||'"}}}$$);';
					END IF;
				END IF;
			ELSE
				EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1111","function":"3188","fid": 217,"v_criticity": 4, 
				"parameters":{"feature_type":"'||lower(v_feature_type)||'", "connect_id":"'||v_connect_id||'"}}}$$);';
			END IF;

			-- get feature information
			IF v_feature_type ='CONNEC' THEN
				SELECT * INTO v_connect FROM ve_connec WHERE connec_id = v_connect_id;

				IF (SELECT connec_id FROM plan_psector_x_connec WHERE connec_id = v_connect.connec_id AND psector_id = v_psector_current AND psector_id
						IN (SELECT psector_id FROM selector_psector WHERE cur_user = current_user) AND state = 1) IS NOT NULL AND v_connect.state = 1 THEN
						v_isoperative_psector = true;
						v_linkfrompsector = (SELECT link_id FROM plan_psector_x_connec WHERE connec_id = v_connect.connec_id AND psector_id IN
									(SELECT psector_id FROM selector_psector WHERE cur_user = current_user) AND state = 1 LIMIT 1);
						-- Get old link and arc from base tables (source of truth)
						v_old_arc_id = (SELECT arc_id FROM connec WHERE connec_id = v_connect.connec_id);
						v_existing_link = (SELECT link_id FROM link WHERE feature_id = v_connect.connec_id AND feature_type = 'CONNEC' AND exit_id = v_old_arc_id AND exit_type = 'ARC' AND state = 1 ORDER BY link_id ASC LIMIT 1);
				ELSIF v_psector_id_param IS NOT NULL AND v_connect.state = 1 THEN
					IF (SELECT connec_id FROM plan_psector_x_connec WHERE connec_id = v_connect.connec_id AND psector_id = v_psector_id_param) IS NULL THEN
						v_isoperative_psector = true;
						v_psector_current = v_psector_id_param;
						-- Get old link and arc from base tables (source of truth)
						v_old_arc_id = (SELECT arc_id FROM connec WHERE connec_id = v_connect.connec_id);
						v_existing_link = (SELECT link_id FROM link WHERE feature_id = v_connect.connec_id AND feature_type = 'CONNEC' AND exit_id = v_old_arc_id AND exit_type = 'ARC' AND state = 1 ORDER BY link_id ASC LIMIT 1);
					END IF;
				END IF;

			ELSIF v_feature_type ='GULLY' THEN
				SELECT * INTO v_connect FROM ve_gully WHERE gully_id = v_connect_id;

				IF (SELECT gully_id FROM plan_psector_x_gully WHERE gully_id = v_connect.gully_id AND psector_id = v_psector_current AND psector_id IN
						(SELECT psector_id FROM selector_psector WHERE cur_user = current_user) AND state = 1) IS NOT NULL AND v_connect.state = 1 THEN
						v_isoperative_psector = true;
						v_linkfrompsector = (SELECT link_id FROM plan_psector_x_gully WHERE gully_id = v_connect.gully_id AND psector_id IN
									(SELECT psector_id FROM selector_psector WHERE cur_user = current_user) AND state = 1 LIMIT 1);
						-- Get old link and arc from base tables (source of truth)
						v_old_arc_id = (SELECT arc_id FROM gully WHERE gully_id = v_connect.gully_id);
						v_existing_link = (SELECT link_id FROM link WHERE feature_id = v_connect.gully_id AND feature_type = 'GULLY' AND exit_id = v_old_arc_id AND exit_type = 'ARC' AND state = 1 ORDER BY link_id ASC LIMIT 1);

				ELSIF v_psector_id_param IS NOT NULL AND v_connect.state = 1 THEN
					IF (SELECT gully_id FROM plan_psector_x_gully WHERE gully_id = v_connect.gully_id AND psector_id = v_psector_id_param) IS NULL THEN
						v_isoperative_psector = true;
						v_psector_current = v_psector_id_param;
						-- Get old link and arc from base tables (source of truth)
						v_old_arc_id = (SELECT arc_id FROM gully WHERE gully_id = v_connect.gully_id);
						v_existing_link = (SELECT link_id FROM link WHERE feature_id = v_connect.gully_id AND feature_type = 'GULLY' AND exit_id = v_old_arc_id AND exit_type = 'ARC' AND state = 1 ORDER BY link_id ASC LIMIT 1);
					END IF;
				END IF;
			END IF;

			-- getting link values
			IF v_isoperative_psector THEN
				IF v_linkfrompsector IS NULL THEN
					-- First time: get link structure from existing operative link
					SELECT * INTO v_link FROM link WHERE link_id = v_existing_link;
				ELSE
					-- Already in psector: get link structure from psector link
					SELECT * INTO v_link FROM link WHERE link_id = v_linkfrompsector;
				END IF;
				-- Force new link creation
				v_link.link_id = null;
			ELSE
				SELECT * INTO v_link FROM ve_link WHERE feature_id = v_connect_id limit 1;
			END IF;

			-- exception control. It is not possible to create a link for connec over arc
			SELECT * INTO v_arc FROM ve_arc WHERE ST_DWithin(v_connect.the_geom, ve_arc.the_geom, 0.001);

			-- Use connect.arc_id as forced arcs in case of exists (skip when forceReconnect re-searches)
			IF v_force_reconnect IS FALSE AND v_connect.arc_id IS NOT NULL AND v_connect.arc_id <> v_old_arc_id AND v_isforcedarcs is False THEN
				v_forcedarcs = concat (' AND arc_id::integer = ',v_connect.arc_id,' ');

				-- check if forced arc diameter is smaller than configured
				IF v_projecttype = 'WS' then
					IF (SELECT cat_dnom::integer FROM ve_arc WHERE arc_id=v_connect.arc_id) >= v_check_arcdnom THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},' ||
						'"data":{"message":"3232", "function":"3188", "fid": 217, "parameters":{"diameter":' || v_check_arcdnom || '}}, "is_process":true}$$);';
					END IF;
				END IF;
			END IF;

			IF v_arc.arc_id IS NOT NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1113","function":"3188","fid": 217,"v_criticity": 4, 
				"parameters":{"connect_id":"'||v_connect_id||'", "arc_id":"'||v_arc.arc_id||'"}}}$$);';
			ELSE

				-- Use check arc diameter variable
				IF v_projecttype = 'WS' THEN
					v_checkeddiam = concat(' AND dnom::float <',v_check_arcdnom,' ');
				ELSE v_checkeddiam = '';
				END IF;

				IF v_link.the_geom IS NULL OR v_force_reconnect THEN -- looking for closest arc from connect
					EXECUTE format(
					'WITH knn AS MATERIALIZED (
                            SELECT a.arc_id, a.arccat_id, ST_Distance(a.the_geom, %L::geometry) AS distance
                            FROM arc a
                            WHERE a.state > 0
                            %s
                            ORDER BY a.the_geom <-> %L::geometry
                            LIMIT 200
                        )
                        SELECT k.arc_id
                        FROM knn k
                        JOIN cat_arc ca ON ca.id = k.arccat_id
                        JOIN vf_arc va ON va.arc_id = k.arc_id
                        WHERE k.distance < %s
                        %s
                        ORDER BY k.distance
                        LIMIT 1',
					v_connect.the_geom::text, replace(v_forcedarcs, 'arc_id', 'a.arc_id'),
					v_connect.the_geom::text, v_check_maxdistance, v_checkeddiam)
					INTO v_connect.arc_id;

				ELSIF v_link.the_geom IS NOT NULL THEN -- looking for closest arc from link's endpoint
					EXECUTE format(
					'WITH knn AS MATERIALIZED (
                            SELECT a.arc_id, a.arccat_id, ST_Distance(a.the_geom, ST_EndPoint(%L::geometry)) AS distance
                            FROM arc a
                            WHERE a.state > 0
                            %s
                            ORDER BY a.the_geom <-> ST_EndPoint(%L::geometry)
                            LIMIT 200
                        )
                        SELECT k.arc_id
                        FROM knn k
                        JOIN cat_arc ca ON ca.id = k.arccat_id
                        JOIN vf_arc va ON va.arc_id = k.arc_id
                        WHERE k.distance < %s
                        %s
                        ORDER BY k.distance
                        LIMIT 1',
					v_link.the_geom::text, replace(v_forcedarcs, 'arc_id', 'a.arc_id'),
					v_link.the_geom::text, v_check_maxdistance, v_checkeddiam)
					INTO v_connect.arc_id;

					IF v_connect.arc_id IS NULL AND v_isforcedarcs THEN -- looking for closest arc from connect within forced set
						EXECUTE format(
						'WITH knn AS MATERIALIZED (
                            SELECT a.arc_id, a.arccat_id, ST_Distance(a.the_geom, %L::geometry) AS distance
                            FROM arc a
                            WHERE a.state > 0
                            %s
                            ORDER BY a.the_geom <-> %L::geometry
                            LIMIT 200
                        )
                        SELECT k.arc_id
                        FROM knn k
                        JOIN cat_arc ca ON ca.id = k.arccat_id
                        JOIN vf_arc va ON va.arc_id = k.arc_id
                        WHERE k.distance < %s
                        %s
                        ORDER BY k.distance
                        LIMIT 1',
						v_connect.the_geom::text, replace(v_forcedarcs, 'arc_id', 'a.arc_id'),
						v_connect.the_geom::text, v_check_maxdistance, v_checkeddiam)
						INTO v_connect.arc_id;
					END IF;

				END IF;

				IF v_connect.arc_id IS NULL THEN
				--pass
				ELSE

					-- get ve_arc information
					SELECT * INTO v_arc FROM arc WHERE arc_id = v_connect.arc_id;

					-- state control
					IF v_arc.state=2 AND v_connect.state=1 AND v_isarcdivide is false THEN
						EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
						"data":{"message":"3050", "function":"2124","fid": 217, "parameters":null, "is_process":true}}$$);' INTO v_audit_result;
					END IF;

					-- get endfeature attributes (forceReconnect always targets closest ARC)
					IF v_force_reconnect THEN
						v_pjointtype='ARC';
						v_endfeature_geom = v_arc.the_geom;
						v_link.exit_type = 'ARC';
						v_link.exit_id = v_arc.arc_id;
						v_pjointid = v_arc.arc_id;

					ELSIF v_link.exit_type='NODE' THEN
						SELECT node_id, the_geom INTO v_pjointid, v_endfeature_geom FROM node WHERE node_id=v_link.exit_id;
						v_pjointtype='NODE';
						v_link.exit_type = 'NODE';
						v_link.exit_id = v_pjointid;

						-- case when planned node over existing node
						SELECT count(*) INTO v_count2 FROM ve_node WHERE node_id = v_link.exit_id;
						IF v_count2 = 0 AND v_ispsector IS TRUE THEN
							SELECT node_id INTO v_link.exit_id FROM node WHERE state = 2 AND st_dwithin(the_geom,v_link.the_geom,0.01) ORDER BY tstamp DESC LIMIT 1;
						END IF;

					ELSIF v_link.exit_type='CONNEC' THEN
						SELECT pjoint_type, connec_id, the_geom INTO v_pjointtype, v_pjointid, v_endfeature_geom FROM connec WHERE connec_id=v_link.exit_id;
						v_pjointtype='CONNEC';
						v_link.exit_type = 'CONNEC';
						v_link.exit_id = v_pjointid;

					ELSIF v_link.exit_type='GULLY' THEN
						SELECT pjoint_type, gully_id, the_geom INTO v_pjointtype, v_pjointid, v_endfeature_geom FROM gully WHERE gully_id=v_link.exit_id;
						v_pjointtype='GULLY';
						v_link.exit_type = 'GULLY';
						v_link.exit_id = v_pjointid;

					ELSE  -- it means ARC or NOTHING
						v_pjointtype='ARC';
						v_endfeature_geom = v_arc.the_geom;
						v_link.exit_type = 'ARC';
						v_link.exit_id = v_arc.arc_id;
						v_pjointid = v_arc.arc_id;
					END IF;

					-- compute link
					IF v_arc.the_geom IS NOT NULL THEN

						-- setting distance factor
						IF v_projecttype  ='WS' THEN
							v_dfactor = 0.3/(st_length(v_arc.the_geom));
							IF v_dfactor > 0.5 THEN v_dfactor = 0.5; END IF;
						ELSIF  v_projecttype  ='UD' THEN
							v_dfactor = 0;
						END IF;

						-- setting point aux
						SELECT geom_point INTO v_geom_point FROM temp_table WHERE fid = 485 and cur_user = current_user;

						if v_geom_point is not null then
							v_point_aux := St_closestpoint(v_arc.the_geom, v_geom_point);
						end if;

						DELETE FROM temp_table WHERE fid = 485 AND cur_user=current_user;

						IF v_point_aux IS NULL THEN

							-- getting the appropiate vertex of link to check distance againts arc
							select geom INTO v_link_point from (select (st_dumppoints(the_geom)).geom, (st_dumppoints(the_geom)).path, the_geom
							from link where link.link_id = v_link.link_id) a where path[1] = st_numpoints(the_geom)-1;
							v_point_aux := St_closestpoint(v_arc.the_geom, v_link_point);

							-- profilactic control for v_point_aux
							IF v_point_aux IS NULL THEN
								v_point_aux := St_closestpoint(v_arc.the_geom, v_connect.the_geom);
							END IF;

							-- changing closest point
							IF st_equals(v_point_aux, st_endpoint(v_arc.the_geom)) THEN
								v_point_aux = (ST_lineinterpolatepoint(v_arc.the_geom, 1-v_dfactor));

							ELSIF st_equals(v_point_aux, st_startpoint(v_arc.the_geom)) THEN
								v_point_aux = (ST_lineinterpolatepoint(v_arc.the_geom, v_dfactor));

							END IF;

							-- profilactic control for v_point_aux
							IF v_point_aux IS NULL THEN
								v_point_aux := St_closestpoint(v_arc.the_geom, v_connect.the_geom);
							END IF;

						END IF;

						IF v_link.the_geom IS NULL AND v_pjointtype='ARC' THEN

							IF v_link.the_geom IS NULL THEN
								SELECT the_geom INTO v_link.the_geom FROM link WHERE feature_id = v_connect_id AND feature_type=v_feature_type AND state=1 LIMIT 1;
							END IF;

							IF v_link.the_geom IS NULL THEN
								-- create link geom
								v_link.the_geom := st_setsrid(ST_makeline(v_connect.the_geom, v_point_aux), ST_SRID(v_connect.the_geom));


								IF v_isforcedarcs THEN
									EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1117","function":"3188","fid": 217,"v_criticity": 4, 
									"parameters":{"arc_id":"'||v_connect.arc_id||'"}}}$$);';
								ELSE
									EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1119","function":"3188","fid": 217,"v_criticity": 4}}$$);';
								END IF;
							ELSE
								v_link.state = 2; -- because it is copied from existing one but related to psector
								EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1121","function":"3188","fid": 217,"v_criticity": 4}}$$);';
							END IF;

						ELSIF v_link.the_geom IS NOT NULL AND v_pjointtype='ARC' THEN

							-- Reverse (if it's need) the existing link geometry
							IF (st_dwithin (st_startpoint(v_link.the_geom), v_connect.the_geom, 0.01)) IS FALSE THEN
								v_point_aux := St_closestpoint(v_endfeature_geom, St_startpoint(v_link.the_geom));
								v_link.the_geom = ST_SetPoint(v_link.the_geom, 0, v_point_aux) ;

								EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "1123","function":"3188","fid": 217,"v_criticity": 4}}$$);';
							ELSE
								v_link.the_geom = ST_SetPoint(v_link.the_geom, (ST_NumPoints(v_link.the_geom) - 1),v_point_aux);
							END IF;

						-- when we are forcing arc_id for those links coming from connec, guly, node
						ELSIF v_link.the_geom IS NOT NULL AND v_pjointtype !='ARC' AND (v_forcedarcs IS NOT NULL AND v_forcedarcs !='') AND v_forceendpoint IS TRUE THEN

							IF st_dwithin(v_link.the_geom, v_arc.the_geom,0) is true then
								-- do not modify geometry of link
							ELSE
								v_link.the_geom = ST_SetPoint(v_link.the_geom, (ST_NumPoints(v_link.the_geom) - 1),v_point_aux);
							END IF;
							v_pjointtype='ARC';
							v_endfeature_geom = v_arc.the_geom;
							v_link.exit_type = 'ARC';
							v_link.exit_id = v_arc.arc_id;
							v_pjointid = v_arc.arc_id;
						ELSE
							-- do nothing for those links coming from connec, guly, node and they not are forced with some arc_id
						END IF;
					END IF;

					-- getting values for dma and fluidtype automatic values
					v_dma_value = v_arc.dma_id;
					v_fluidtype_value = v_connect.fluid_type;

					IF v_link.link_id IS NULL THEN

						-- creation of link
						v_link.link_id = (SELECT nextval('urn_id_seq'));
						SELECT cf.feature_class INTO v_man_table FROM cat_link c
						JOIN cat_feature cf on cf.id=c.link_type
						WHERE c.id = v_linkcat_id LIMIT 1;

						SELECT link_type INTO v_link_type FROM cat_link WHERE id = v_linkcat_id LIMIT 1;

						IF v_psector_current IS NOT NULL THEN
							v_state_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_statetype_2_vdefault' AND cur_user = current_user);
							IF v_state_type IS NULL THEN
								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
								"data":{"message":"4432", "function":"3188","fid": 217, "is_process":true}}$$);';
							END IF;
						ELSE
							v_state_type = (SELECT value FROM config_param_user WHERE parameter = 'edit_statetype_1_vdefault' AND cur_user = current_user);
							IF v_state_type IS NULL THEN
								EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
								"data":{"message":"4432", "function":"3188","fid": 217, "is_process":true}}$$);';
							END IF;
						END IF;
					
						IF v_projecttype = 'WS' THEN
							INSERT INTO link (link_id, the_geom, feature_id, feature_type, exit_type, exit_id, state, expl_id, sector_id, dma_id, omzone_id,
							presszone_id, dqa_id, minsector_id, fluid_type, muni_id, linkcat_id, state_type)
							VALUES (v_link.link_id, v_link.the_geom, v_connect_id, v_feature_type, v_link.exit_type, v_link.exit_id,
							CASE WHEN v_isoperative_psector THEN 2 ELSE v_connect.state END, v_arc.expl_id, v_arc.sector_id, v_dma_value, v_arc.omzone_id, v_arc.presszone_id, v_arc.dqa_id, v_arc.minsector_id, v_fluidtype_value, v_connect.muni_id,
							v_linkcat_id, v_state_type);

							EXECUTE 'INSERT INTO man_'||v_man_table||' values ('||v_link.link_id||')';

						ELSIF v_projecttype = 'UD' THEN
							INSERT INTO link (link_id, the_geom, feature_id, feature_type, exit_type, exit_id, state, expl_id, sector_id, omzone_id, fluid_type, muni_id, linkcat_id, link_type, state_type)
							VALUES (v_link.link_id, v_link.the_geom, v_connect_id, v_feature_type, v_link.exit_type, v_link.exit_id,
							CASE WHEN v_isoperative_psector THEN 2 ELSE v_connect.state END, v_arc.expl_id, v_arc.sector_id, v_arc.omzone_id, v_fluidtype_value::INTEGER, v_connect.muni_id, v_linkcat_id, v_link_type, v_state_type);

							EXECUTE 'INSERT INTO man_'||v_man_table||' values ('||v_link.link_id||')';

						END IF;
					ELSE
						IF v_linkcat_id IS NULL THEN
							IF v_projecttype = 'WS' THEN
								UPDATE link SET the_geom=v_link.the_geom, exit_type=v_link.exit_type, exit_id=v_link.exit_id, omzone_id = v_arc.omzone_id, fluid_type = v_fluidtype_value
								WHERE link_id = v_link.link_id;
							ELSE
								UPDATE link SET the_geom=v_link.the_geom, exit_type=v_link.exit_type, exit_id=v_link.exit_id, omzone_id = v_arc.omzone_id, fluid_type = v_fluidtype_value::INTEGER
								WHERE link_id = v_link.link_id;
							END IF;
						ELSE
							IF v_projecttype = 'WS' THEN
								UPDATE link SET the_geom=v_link.the_geom, exit_type=v_link.exit_type, exit_id=v_link.exit_id, omzone_id = v_arc.omzone_id, fluid_type = v_fluidtype_value, linkcat_id = v_linkcat_id
								WHERE link_id = v_link.link_id;
							ELSE
								UPDATE link SET the_geom=v_link.the_geom, exit_type=v_link.exit_type, exit_id=v_link.exit_id, omzone_id = v_arc.omzone_id, fluid_type = v_fluidtype_value::INTEGER, linkcat_id = v_linkcat_id
								WHERE link_id = v_link.link_id;
							END IF;
						END IF;

						IF v_projecttype = 'WS' THEN
							UPDATE link SET	presszone_id=v_arc.presszone_id, dqa_id=v_arc.dqa_id, dma_id = v_dma_value, minsector_id=v_arc.minsector_id
							WHERE link_id = v_link.link_id;
						END IF;
					END IF;

					-- update connect values
					IF v_connect.state=1 then

						IF v_ispsector AND v_forceendpoint IS FALSE THEN -- then returning link

							IF v_feature_type ='CONNEC' THEN
								UPDATE plan_psector_x_connec SET link_id = v_link.link_id WHERE psector_id = v_psector_current
								AND connec_id = v_connect_id AND state = 1;

							ELSIF v_feature_type ='GULLY' THEN
								UPDATE plan_psector_x_gully SET link_id = v_link.link_id WHERE psector_id = v_psector_current
								AND gully_id = v_connect_id  AND state = 1;
							END IF;

							UPDATE link SET state = 2 WHERE link_id  = v_link.link_id;

						ELSIF v_isarcdivide or v_isoperative_psector or (v_ispsector and v_forceendpoint) THEN -- then returning link & arc_id

							-- Insert state=0 FIRST (before link state changes to 2, so trigger can't overwrite it)
							IF v_isoperative_psector THEN
								IF v_feature_type ='CONNEC' THEN
									INSERT INTO plan_psector_x_connec (psector_id, connec_id, state, link_id, arc_id, doable) 
									VALUES (v_psector_current, v_connect_id, 0, v_existing_link, v_old_arc_id, true)
									ON CONFLICT (psector_id, connec_id, state) DO NOTHING;
								ELSIF v_feature_type ='GULLY' THEN
									INSERT INTO plan_psector_x_gully (psector_id, gully_id, state, link_id, arc_id, doable) 
									VALUES (v_psector_current, v_connect_id, 0, v_existing_link, v_old_arc_id, true)
									ON CONFLICT (psector_id, gully_id, state) DO NOTHING;
								END IF;
							END IF;

							-- Now insert state=1 and update link state
							IF v_feature_type ='CONNEC' THEN
								INSERT INTO plan_psector_x_connec (psector_id, connec_id, state, link_id, arc_id, doable)
								VALUES (v_psector_current, v_connect_id, 1, v_link.link_id, v_arc.arc_id, true)
								ON CONFLICT (psector_id, connec_id, state) DO UPDATE 
								SET link_id = v_link.link_id, arc_id = v_arc.arc_id;

							ELSIF v_feature_type ='GULLY' THEN
								INSERT INTO plan_psector_x_gully (psector_id, gully_id, state, link_id, arc_id, doable)
								VALUES (v_psector_current, v_connect_id, 1, v_link.link_id, v_arc.arc_id, true)
								ON CONFLICT (psector_id, gully_id, state) DO UPDATE 
								SET link_id = v_link.link_id, arc_id = v_arc.arc_id;
							END IF;

							UPDATE link SET state = 2 WHERE link_id  = v_link.link_id;

						ELSE -- Update connect attributes

							IF v_feature_type ='CONNEC' THEN

								-- update specific fields for ws projects
								IF v_projecttype = 'WS' THEN

									UPDATE connec SET arc_id=v_connect.arc_id, expl_id=v_arc.expl_id, omzone_id=v_arc.omzone_id, sector_id=v_arc.sector_id,
									pjoint_type=v_pjointtype, pjoint_id=v_pjointid, fluid_type = v_fluidtype_value
									WHERE connec_id = v_connect_id;

									UPDATE connec SET dqa_id=v_arc.dqa_id, minsector_id=v_arc.minsector_id, dma_id = v_dma_value, presszone_id=v_arc.presszone_id,
									staticpressure = ((SELECT head from presszone WHERE presszone_id = v_arc.presszone_id)- v_connect.top_elev)
									WHERE connec_id = v_connect_id;
								ELSE
									UPDATE connec SET arc_id=v_connect.arc_id, expl_id=v_arc.expl_id, omzone_id=v_arc.omzone_id, sector_id=v_arc.sector_id,
									pjoint_type=v_pjointtype, pjoint_id=v_pjointid, fluid_type = v_fluidtype_value::INTEGER
									WHERE connec_id = v_connect_id;
								END IF;

							ELSIF v_feature_type ='GULLY' THEN

								UPDATE gully SET arc_id=v_connect.arc_id, expl_id=v_arc.expl_id, omzone_id=v_arc.omzone_id, sector_id=v_arc.sector_id,
								pjoint_type=v_pjointtype, pjoint_id=v_pjointid, fluid_type = v_fluidtype_value::INTEGER
								WHERE gully_id = v_connect_id;
							END IF;
						END IF;

					ELSIF v_connect.state=2 THEN

						IF v_ispsector IS TRUE THEN -- then returning link

							IF v_feature_type ='CONNEC' THEN
								UPDATE plan_psector_x_connec SET link_id = v_link.link_id WHERE psector_id = v_psector_current
								AND connec_id = v_connect_id AND state = 1;

							ELSIF v_feature_type ='GULLY' THEN
								UPDATE plan_psector_x_gully SET link_id = v_link.link_id WHERE psector_id = v_psector_current
								 AND gully_id = v_connect_id AND state = 1;
							END IF;

						ELSE -- then updating psector with link and arc

							IF v_feature_type ='CONNEC' THEN
								UPDATE plan_psector_x_connec SET link_id = v_link.link_id, arc_id = v_arc.arc_id
								WHERE psector_id = v_psector_current AND connec_id = v_connect_id AND state = 1;

							ELSIF v_feature_type ='GULLY' THEN

								UPDATE plan_psector_x_gully SET link_id = v_link.link_id, arc_id = v_arc.arc_id
								WHERE psector_id = v_psector_current AND gully_id = v_connect_id AND state = 1;
							END IF;
						END IF;
					END IF;
					EXECUTE 'SELECT gw_fct_getmessage($${"data": {"message": "4430","function":"3188","fid": 217,"v_criticity": 4, 
					"parameters":{"feature_type":"'||lower(v_feature_type)||'", "connec_id":"'||v_connect_id||'", "arc_id":"'||v_arc.arc_id||'"}}}$$);';
				end if;
				-- reset values
				v_connect := null;
				v_link := null;
				v_arc := null;
				v_point_aux := null;
				-- Reset psector-related variables for next iteration
				v_isoperative_psector := false;
				v_existing_link := null;
				v_linkfrompsector := null;
				v_old_arc_id := null;
			END IF;

	    END LOOP;
	END IF;

	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM audit_check_data
	WHERE cur_user="current_user"() AND fid = 217 ORDER BY criticity desc, id asc) row;

	IF v_audit_result is null THEN
		v_status = 'Accepted';
		v_level = 3;
		v_message = 'Process done successfully';
	ELSE

		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;
	END IF;

	v_result_info := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result_info, '}');

	v_result_point = '{}';
	v_result_line = '{}';
	v_result_polygon = '{}';

	--  Return
	RETURN gw_fct_json_create_return(('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||','||
				'"line":'||v_result_line||','||
				'"polygon":'||v_result_polygon||'}'||
		       '}'||
	    '}')::json, 3188, null, null, null);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

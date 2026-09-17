/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1244

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_topocontrol_arc()  RETURNS trigger AS
$BODY$

DECLARE
nodeRecord1 Record;
nodeRecord2 Record;
y_aux double precision;
v_sys_statetopocontrol boolean;
sys_length_aux double precision;
geom_slp_direction_bool boolean;
v_projecttype text;
v_dsbl_error boolean;
v_samenode_init_end_control boolean;
v_nodeinsert_arcendpoint boolean;
v_arc_searchnodes_control boolean;
v_arc_searchnodes double precision;
v_node2 text;
v_nodecat text;
v_keepdepthvalues boolean;
v_message text;
v_user_disable_statetopocontrol boolean;
v_user_disable_arctopocontrol boolean;
v_node_topelev_autoupdate integer := 0;

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- Get system variables
 	SELECT project_type INTO v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT value::boolean INTO v_sys_statetopocontrol FROM config_param_system WHERE parameter='edit_state_topocontrol' ;
	SELECT value::boolean INTO geom_slp_direction_bool FROM config_param_system WHERE parameter='edit_slope_direction' ;
	SELECT value::boolean INTO v_dsbl_error FROM config_param_system WHERE parameter='edit_topocontrol_disable_error' ;
   	SELECT value::boolean INTO v_samenode_init_end_control FROM config_param_system WHERE parameter='edit_arc_samenode_control' ;
	SELECT ((value::json)->>'activated') INTO v_arc_searchnodes_control FROM config_param_system WHERE parameter='edit_arc_searchnodes';
	SELECT ((value::json)->>'value') INTO v_arc_searchnodes FROM config_param_system WHERE parameter='edit_arc_searchnodes';

	-- Get user variables
	SELECT value::boolean INTO v_user_disable_statetopocontrol FROM config_param_user WHERE parameter='edit_disable_statetopocontrol' AND cur_user = current_user;
	SELECT value::boolean INTO v_nodeinsert_arcendpoint FROM config_param_user WHERE parameter='edit_arc_insert_automatic_endpoint' AND cur_user = current_user;
	SELECT value::boolean INTO v_keepdepthvalues FROM config_param_user WHERE parameter='edit_arc_keepdepthval_when_reverse_geom' AND cur_user = current_user;
	SELECT value::boolean INTO v_user_disable_arctopocontrol FROM config_param_user WHERE parameter='edit_disable_arctopocontrol' AND cur_user = current_user;
	SELECT value::integer INTO v_node_topelev_autoupdate FROM config_param_user WHERE parameter='edit_node_topelev_options' AND cur_user = current_user;
	v_node_topelev_autoupdate := COALESCE(v_node_topelev_autoupdate, 0);

	--Check if user has migration mode enabled
	IF (SELECT value::boolean FROM config_param_user WHERE parameter='edit_disable_topocontrol_complete' AND cur_user=current_user) IS TRUE THEN
		RETURN NEW;
	END IF;

	IF (SELECT value::boolean FROM config_param_user WHERE parameter='edit_disable_topocontrol' AND cur_user=current_user) IS TRUE THEN
  		v_samenode_init_end_control = FALSE;
  		v_dsbl_error = TRUE;
  	END IF;

	-- disable trigger
	IF v_user_disable_arctopocontrol THEN
		RETURN NEW;
	END IF;

	IF v_sys_statetopocontrol IS NOT TRUE THEN

		SELECT * INTO nodeRecord1 FROM node
		JOIN cat_feature_node ON cat_feature_node.id = node_type
		WHERE ST_DWithin(ST_startpoint(NEW.the_geom), node.the_geom, v_arc_searchnodes)
		ORDER BY (case when isarcdivide is true then 1 else 2 end),
		ST_Distance(node.the_geom, ST_startpoint(NEW.the_geom)) LIMIT 1;


		SELECT * INTO nodeRecord2 FROM node
		JOIN cat_feature_node ON cat_feature_node.id = node_type
		WHERE ST_DWithin(ST_endpoint(NEW.the_geom), node.the_geom, v_arc_searchnodes)
		ORDER BY (case when isarcdivide is true then 1 else 2 end),
		ST_Distance(node.the_geom, ST_endpoint(NEW.the_geom)) LIMIT 1;

	ELSIF v_sys_statetopocontrol IS TRUE THEN

		-- Looking for state control
		PERFORM gw_fct_state_control(json_build_object('parameters', json_build_object('feature_type_aux', 'ARC', 'feature_id_aux', NEW.arc_id, 'state_aux', NEW.state, 'tg_op_aux', TG_OP)));

		-- Lookig for state=0
		IF NEW.state=0 THEN
			RAISE WARNING 'Topology is not enabled with state=0. The feature will be disconected of the network';
			RETURN NEW;
		END IF;

		-- Starting process
		IF TG_OP='INSERT' THEN

			SELECT * INTO nodeRecord1 FROM node
			JOIN cat_feature_node ON cat_feature_node.id = node_type
			WHERE ST_DWithin(ST_startpoint(NEW.the_geom), node.the_geom, v_arc_searchnodes)
			AND ((NEW.state=1 AND node.state=1)


					-- looking for existing nodes that not belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=1 AND node_id NOT IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND state=0 AND psector_id =
							(SELECT value::integer FROM config_param_user
							WHERE parameter='plan_psector_current' AND cur_user="current_user"() LIMIT 1 )))

					-- looking for planified nodes that belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=2 AND node_id IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND state=1 AND psector_id =
							(SELECT value::integer FROM config_param_user
							WHERE parameter='plan_psector_current' AND cur_user="current_user"() LIMIT 1))))

					ORDER BY ST_Distance(node.the_geom, ST_startpoint(NEW.the_geom)) LIMIT 1;

			SELECT * INTO nodeRecord2 FROM node
			JOIN cat_feature_node ON cat_feature_node.id = node_type
			WHERE ST_DWithin(ST_endpoint(NEW.the_geom), node.the_geom, v_arc_searchnodes)
			AND ((NEW.state=1 AND node.state=1)


					-- looking for existing nodes that not belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=1 AND node_id NOT IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND state=0 AND psector_id =
							(SELECT value::integer FROM config_param_user
							WHERE parameter='plan_psector_current' AND cur_user="current_user"() LIMIT 1)))

					-- looking for planified nodes that belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=2 AND node_id IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND state=1 AND psector_id =
							(SELECT value::integer FROM config_param_user
							WHERE parameter='plan_psector_current' AND cur_user="current_user"() LIMIT 1 ))))

					ORDER BY ST_Distance(node.the_geom, ST_endpoint(NEW.the_geom)) LIMIT 1;

		ELSIF TG_OP='UPDATE' THEN

			SELECT * INTO nodeRecord1 FROM node
			JOIN cat_feature_node ON cat_feature_node.id = node_type
			WHERE ST_DWithin(ST_startpoint(NEW.the_geom), node.the_geom, v_arc_searchnodes)
			AND ((NEW.state=1 AND node.state=1)


					-- looking for existing nodes that not belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=1 AND node_id NOT IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND  state=0 AND psector_id IN
							(SELECT psector_id FROM plan_psector_x_arc WHERE arc_id=NEW.arc_id)))


					-- looking for planified nodes that belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=2 AND node_id IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND  state=1 AND psector_id IN
							(SELECT psector_id FROM plan_psector_x_arc WHERE arc_id=NEW.arc_id))))

					ORDER BY ST_Distance(node.the_geom, ST_startpoint(NEW.the_geom)) LIMIT 1;

			SELECT * INTO nodeRecord2 FROM node
			JOIN cat_feature_node ON cat_feature_node.id = node_type
			WHERE ST_DWithin(ST_endpoint(NEW.the_geom), node.the_geom, v_arc_searchnodes)
			AND ((NEW.state=1 AND node.state=1)


					-- looking for existing nodes that not belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=1 AND node_id NOT IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND  state=0 AND psector_id IN
							(SELECT psector_id FROM plan_psector_x_arc WHERE arc_id=NEW.arc_id)))

					-- looking for planified nodes that belongs on the same alternatives that arc
					OR (NEW.state=2 AND node.state=2 AND node_id IN
						(SELECT node_id FROM plan_psector_x_node
						 WHERE plan_psector_x_node.node_id=node.node_id AND  state=1 AND psector_id IN
							(SELECT psector_id FROM plan_psector_x_arc WHERE arc_id=NEW.arc_id))))

					ORDER BY ST_Distance(node.the_geom, ST_endpoint(NEW.the_geom)) LIMIT 1;
		END IF;

	END IF;

    -- only if user variable is not disabled
    IF v_user_disable_statetopocontrol IS FALSE THEN

        --  Control of start/end node and depth variables
        IF (nodeRecord1.node_id IS NOT NULL) AND (nodeRecord2.node_id IS NOT NULL) THEN

            -- Control of same node initial and final
            IF (nodeRecord1.node_id = nodeRecord2.node_id) AND (v_samenode_init_end_control IS TRUE) THEN
                IF v_dsbl_error IS NOT TRUE THEN
                    EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                    "data":{"message":"1040", "function":"1344","parameters":{"node_id":"'||nodeRecord1.node_id||'"}}}$$);';
                ELSE
                    SELECT concat('ERROR-',id,':',error_message,'.',hint_message) INTO v_message FROM sys_message WHERE id = 1040;
                    INSERT INTO audit_log_data (fid, feature_id, log_message) VALUES (103, NEW.arc_id, v_message);
                END IF;

            ELSIF ((nodeRecord1.state = 2) OR (nodeRecord2.state = 2)) AND (NEW.state = 1) THEN
                EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                "data":{"message":"3192", "function":"1344","parameters":null}}$$);';

            ELSE

                -- node_1
                --SELECT * INTO nodeRecord1 FROM ve_node WHERE node_id = nodeRecord1.node_id;
                NEW.node_1 := nodeRecord1.node_id;

                -- node_2
                --SELECT * INTO nodeRecord2 FROM ve_node WHERE node_id = nodeRecord2.node_id;
                NEW.node_2 := nodeRecord2.node_id;

                -- the_geom
                NEW.the_geom := ST_SetPoint(NEW.the_geom, 0, nodeRecord1.the_geom);
                NEW.the_geom := ST_SetPoint(NEW.the_geom, ST_NumPoints(NEW.the_geom) - 1, nodeRecord2.the_geom);

                -- calculate length
                sys_length_aux := COALESCE(NEW.custom_length, ST_length(NEW.the_geom));

                IF sys_length_aux < 0.1 THEN
                    sys_length_aux=0.1;
                END IF;

				-- node_1
				-- 1: ymax is changed
				IF NEW.y1 IS NOT NULL AND (OLD.y1 IS DISTINCT FROM NEW.y1) THEN
					IF nodeRecord1.top_elev IS NOT NULL THEN
						NEW.elev1 := COALESCE(nodeRecord1.custom_top_elev, nodeRecord1.top_elev) - NEW.y1;
					END IF;
				-- 2: elev is changed
				ELSIF NEW.elev1 IS NOT NULL AND (OLD.elev1 IS DISTINCT FROM NEW.elev1) THEN
					IF nodeRecord1.top_elev IS NOT NULL THEN
						NEW.y1 := COALESCE(nodeRecord1.custom_top_elev, nodeRecord1.top_elev) - NEW.elev1;
					END IF;
				END IF;

				-- node_2
				-- 1: ymax is changed
				IF NEW.y2 IS NOT NULL AND (OLD.y2 IS DISTINCT FROM NEW.y2) THEN
					IF nodeRecord2.top_elev IS NOT NULL THEN
						NEW.elev2 := COALESCE(nodeRecord2.custom_top_elev, nodeRecord2.top_elev) - NEW.y2;
					END IF;
				-- 2: elev is changed
				ELSIF NEW.elev2 IS NOT NULL AND (OLD.elev2 IS DISTINCT FROM NEW.elev2) THEN
					IF nodeRecord2.top_elev IS NOT NULL THEN
						NEW.y2 := COALESCE(nodeRecord2.custom_top_elev, nodeRecord2.top_elev) - NEW.elev2;
					END IF;
				END IF;

                IF TG_OP = 'UPDATE' THEN

                    -- update values when geometry is forced to reverse by custom operation
                    IF  geom_slp_direction_bool IS FALSE AND st_orderingequals(NEW.the_geom, OLD.the_geom) IS FALSE
                    AND st_equals(NEW.the_geom, OLD.the_geom) IS TRUE THEN

						IF v_keepdepthvalues IS NOT FALSE THEN -- change depth values

							-- Depth values for arc
							y_aux := NEW.y1;
							NEW.y1 := NEW.y2;
							NEW.y2 := y_aux;

							y_aux := NEW.elev1;
							NEW.elev1 := NEW.elev2;
							NEW.elev2 := y_aux;

							y_aux := NEW.custom_elev1;
							NEW.custom_elev1 := NEW.custom_elev2;
							NEW.custom_elev2 := y_aux;

						END IF;

                    END IF;

                END IF;

                -- update values when geometry is forced to reverse by geom_slp_direction_bool variable on true
                IF geom_slp_direction_bool IS TRUE THEN

                    IF ((COALESCE(NEW.custom_elev1, NEW.elev1) < COALESCE(NEW.custom_elev2, NEW.elev2)) AND (NEW.inverted_slope IS NOT TRUE))
                    OR ((COALESCE(NEW.custom_elev1, NEW.elev1) > COALESCE(NEW.custom_elev2, NEW.elev2)) AND (NEW.inverted_slope IS TRUE)) THEN

                        -- Update conduit direction
                        -- Geometry
                        NEW.the_geom := ST_reverse(NEW.the_geom);

                        -- Node 1 & Node 2
                        NEW.node_1 := nodeRecord2.node_id;
                        NEW.node_2 := nodeRecord1.node_id;

                        -- Depth values for arc
                        y_aux := NEW.y1;
                        NEW.y1 := NEW.y2;
                        NEW.y2 := y_aux;

                        y_aux := NEW.elev1;
                        NEW.elev1 := NEW.elev2;
                        NEW.elev2 := y_aux;

                        y_aux := NEW.custom_elev1;
                        NEW.custom_elev1 := NEW.custom_elev2;
                        NEW.custom_elev2 := y_aux;

                    END IF;

                END IF;

                -- slope
                NEW.sys_slope:= (NEW.elev1-NEW.elev2)/sys_length_aux;

			END IF;

        -- Check auto insert end nodes
        ELSIF (nodeRecord1.node_id IS NOT NULL) AND (nodeRecord2.node_id IS NULL) AND v_nodeinsert_arcendpoint THEN

            IF TG_OP = 'INSERT' THEN

                -- getting nodecat user's value
                v_nodecat:= (SELECT "value" FROM config_param_user WHERE "parameter"='edit_nodecat_vdefault' AND "cur_user"="current_user"() LIMIT 1);
                -- get first value (last chance)
                IF (v_nodecat IS NULL) THEN
                    v_nodecat := (SELECT id FROM cat_node WHERE active IS TRUE LIMIT 1);
                END IF;

                -- Inserting new node
                INSERT INTO ve_node (node_id, sector_id, state, state_type, omzone_id, soilcat_id, workcat_id, builtdate, nodecat_id, ownercat_id, muni_id,
                postcode, district_id, expl_id, the_geom)
                VALUES ((SELECT nextval('urn_id_seq')), NEW.sector_id, NEW.state, NEW.state_type, NEW.omzone_id, NEW.soilcat_id, NEW.workcat_id, NEW.builtdate, v_nodecat,
                NEW.ownercat_id, NEW.muni_id, NEW.postcode, NEW.district_id, NEW.expl_id, st_endpoint(NEW.the_geom))
                RETURNING node_id INTO v_node2;

                -- Update arc
                NEW.node_1:= nodeRecord1.node_id;
                NEW.node_2:= v_node2;

            END IF;

        -- Error, no existing nodes
        ELSIF ((nodeRecord1.node_id IS NULL) OR (nodeRecord2.node_id IS NULL)) AND (v_arc_searchnodes_control IS TRUE) THEN
            IF v_dsbl_error IS NOT TRUE THEN
                EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                    "data":{"message":"1042", "function":"1244","parameters":{"arc_id":"'||NEW.arc_id||'"}}}$$);';
            ELSE
                SELECT concat('ERROR-',id,':',error_message,'.',hint_message) INTO v_message FROM sys_message WHERE id = 1042;
                INSERT INTO audit_log_data (fid, feature_id, log_message) VALUES (103, NEW.arc_id, v_message);
            END IF;

        --Not existing nodes but accepted insertion
        ELSIF ((nodeRecord1.node_id IS NULL) OR (nodeRecord2.node_id IS NULL)) AND (v_arc_searchnodes_control IS FALSE) THEN
            RETURN NEW;

        ELSE
            IF v_dsbl_error IS NOT TRUE THEN
                EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                    "data":{"message":"1042", "function":"1244","parameters":{"arc_id":"'||NEW.arc_id||'"}}}$$);';
            ELSE
                SELECT concat('ERROR-',id,':',error_message,'.',hint_message) INTO v_message FROM sys_message WHERE id = 1042;
                INSERT INTO audit_log_data (fid, feature_id, log_message) VALUES (103, NEW.arc_id, v_message);
            END IF;
        END IF;

		-- if the new arc is equal to an existing arc
      	IF TG_OP = 'INSERT' AND (SELECT EXISTS (SELECT 1 FROM arc WHERE ST_Equals(the_geom, NEW.the_geom) AND arc.state = 1 AND NEW.state=1)) IS TRUE THEN
      
			IF v_dsbl_error IS NOT TRUE THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"4348", "function":"1344","parameters":null}}$$);';
			ELSE
				SELECT concat('ERROR-',id,':',error_message,'.',hint_message) INTO v_message FROM sys_message WHERE id = 4348;
				INSERT INTO audit_log_data (fid, feature_id, log_message) VALUES (103, NEW.arc_id, v_message);
			END IF;
      
	  	END IF;

    END IF;

RETURN NEW;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

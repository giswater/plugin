/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3552

DROP FUNCTION IF EXISTS cm.gw_fct_cm_setarcdivide_massive(json);
CREATE OR REPLACE FUNCTION cm.gw_fct_cm_setarcdivide_massive(p_data json) RETURNS json AS
$BODY$

/*EXAMPLE:

-- fid: 3552

-- Check mode: Check for orphan and tcandidate nodes
SELECT SCHEMA_NAME.gw_fct_cm_setarcdivide_massive($${
	"client":{"device":4, "infoType":1, "lang":"ES"},
	"data":{
		"parameters":{
			"mode":"Check",
			"buffer":0.01
		}
	}
}$$)

-- Set mode: Move nodes to nearest arcs and update columns
SELECT SCHEMA_NAME.gw_fct_cm_setarcdivide_massive($${
	"client":{"device":4, "infoType":1, "lang":"ES"},
	"data":{
		"parameters":{
			"mode":"Set",
			"buffer":0.01
		}
	}
}$$)

*/

DECLARE
-- Schema and configuration variables
v_schemaname text;              -- Current schema name (cm)
v_version text;                 -- Giswater version from sys_version table
v_projectype text;              -- Project type: 'WS' (Water Supply) or 'UD' (Urban Drainage)

-- Input parameters
v_mode text;                    -- Operation mode: 'Check' (analysis only) or 'Set' (apply changes)                -- Buffer distance in meters for finding arcs near nodes (used for T-candidate detection)
v_campaign_id integer;         -- Campaign ID for filtering nodes/arcs
v_lot_id integer;              -- Lot ID for filtering nodes/arcs (optional)
v_lot_id_array integer[];      -- Array of lot IDs for filtering nodes/arcs

-- Result variables
v_result json;                  -- Temporary JSON result for building response
v_result_info json;             -- Info messages array for audit trail
v_result_point json;            -- GeoJSON FeatureCollection with point features (nodes found)

-- Counter variables
v_count_orphan integer;         -- Number of orphan nodes found
v_count_tcandidate integer;     -- Number of T-candidate nodes found
v_count_total integer;          -- Total number of nodes processed

-- Node and arc processing variables
v_node_id integer;              -- Current node ID being processed
v_arc_id integer;               -- Current arc ID being processed
v_node_geom public.geometry;   -- Geometry of the node
v_closest_point public.geometry; -- Closest point on arc to the node

-- Arc division variables
v_intersect_loc double precision; -- Position along arc where node intersects (0.0 to 1.0)
v_line1 public.geometry;         -- First segment of divided arc (from start to node)
v_line2 public.geometry;         -- Second segment of divided arc (from node to end)
v_new_arc_id1 integer;          -- ID of first new arc after division
v_new_arc_id2 integer;          -- ID of second new arc after division
v_new_arc_uuid1 uuid;
v_new_arc_uuid2 uuid;
rec_arc record;                  -- Record for arc data
rec_arc_child record;            -- Record for child arc data

-- Record variables for loops
rec_node record;                -- Record for iterating through nodes in Set mode
rec_orphan record;              -- Record for iterating through orphan nodes in Check mode
rec_tcandidate record;         -- Record for iterating through T-candidate nodes in Check mode

-- Closest arc calculation variables
v_closest_arc_id integer;       -- ID of the closest arc to a node
v_closest_arc_distance numeric; -- Distance from node to closest arc

-- JSON building variable
v_array_nodes jsonb;            -- JSONB array to build GeoJSON features for Check mode

-- Error handling
v_error_context text;            -- Error context for exception handling

-- Query text variables
v_querytext text;   
v_node_type text;
v_arc_type text;
v_exists boolean;
v_rec record;

v_arc_child_table text;
v_arc_insert_cols text;
v_arc_select_cols text;

BEGIN

	-- Set search path to current schema and public schema
	SET search_path = "SCHEMA_NAME","PARENT_SCHEMA", public;
	v_schemaname = 'PARENT_SCHEMA';

	-- Get Giswater version and project type from sys_version table
	-- Project type determines which tables/views and logic to use
	SELECT giswater, project_type INTO v_version, v_projectype FROM "PARENT_SCHEMA".sys_version ORDER BY id DESC LIMIT 1;

	-- Extract input parameters from JSON
	v_mode := (((p_data ->>'data')::json->>'parameters')::json->>'mode')::text;
	v_campaign_id := (p_data ->'data' ->'parameters'->>'campaignId')::integer;
	v_lot_id := (p_data ->'data' ->'parameters'->>'lotId')::integer;

	-- Set default values if parameters are not provided
	v_mode := UPPER(COALESCE(v_mode, 'CHECK'));

	-- Clean up previous audit data for this function (fid=3552)
	DELETE FROM PARENT_SCHEMA.audit_check_data WHERE cur_user="current_user"() AND fid=3552;

	-- Log function start message
	EXECUTE 'SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"function":"3552", "fid":"3552", "criticity":"4", "is_process":true, "is_header":"true"}}$$)';

	-- ============================================================================
	-- CONFIGURATION BASED ON PROJECT TYPE
	-- ============================================================================

	IF v_lot_id IS NULL THEN
		SELECT array_agg(lot_id) INTO v_lot_id_array FROM cm.om_campaign_lot WHERE status IN (3,4,6) AND campaign_id = v_campaign_id GROUP BY campaign_id;
	ELSE
		v_lot_id_array := array[v_lot_id];
	END IF;

	-- ============================================================================
	-- CHECK MODE: Analysis Only - Find and Report Orphan and T-Candidate Nodes
	-- ============================================================================
	
	IF v_mode = 'CHECK' THEN
		-- Initialize counters and result array
		v_count_orphan := 0;
		v_count_tcandidate := 0;
		v_array_nodes := '[]'::jsonb;

		-- ------------------------------------------------------------------------
		-- STEP 1: Find Orphan Nodes
		-- ------------------------------------------------------------------------
		-- Orphan nodes: Nodes that are not connected to any arc (not node_1 or node_2)
		-- Query finds nodes that:
		--   - Are not connected to any arc (COUNT of arcs with this node as endpoint = 0)
		--   - Are within buffer distance of at least one arc (using ST_DWithin)
		FOR rec_orphan IN 
			EXECUTE format('
				SELECT DISTINCT a.*, n.the_geom AS campaign_node_geom
				FROM cm.om_campaign_lot_x_node a 
				JOIN cm.om_campaign_x_node n ON n.node_id = a.node_id
				JOIN PARENT_SCHEMA.cat_feature_node cfn ON cfn.id = n.node_type
				WHERE cfn.isarcdivide IS TRUE AND a.lot_id IN (%s)
				AND (SELECT COUNT(*) FROM cm.om_campaign_lot_x_arc WHERE (node_1 = a.node_id OR node_2 = a.node_id) AND ("action" != 3 OR "action" IS NULL)) = 0
				AND EXISTS (
					SELECT 1 FROM cm.om_campaign_x_arc arc
					JOIN cm.om_campaign_lot_x_arc oclxa ON arc.arc_id = oclxa.arc_id
					WHERE ST_DWithin(arc.the_geom, n.the_geom, 0.05)
					AND (oclxa."action" != 3 OR oclxa."action" IS NULL)
				)', 
			array_to_string(v_lot_id_array, ','))
		LOOP
			-- For each orphan node, find the closest arc to it
			-- This will be used to show where the node could be moved to
			SELECT arc_id
			INTO v_closest_arc_id
			FROM cm.om_campaign_x_arc arc
			JOIN cm.om_campaign_lot_x_arc larc USING (arc_id)
			WHERE (action <> 3 OR action IS NULL) ORDER BY arc.the_geom <-> rec_orphan.campaign_node_geom LIMIT 1;
			RAISE NOTICE 'orphan - v_arc_id: %', rec_orphan.node_id;

			-- If a closest arc is found, add this node to the result set
			IF v_closest_arc_id IS NOT NULL THEN
				-- Build GeoJSON Feature with node information
				-- Transform geometry to EPSG:8908 (WGS84) for web display
				v_array_nodes := v_array_nodes || jsonb_build_array(jsonb_build_object(
					'type', 'Feature',
					'geometry', ST_Transform(rec_orphan.campaign_node_geom, 4326),
					'properties', jsonb_build_object(
						'node_id', rec_orphan.node_id,
						'descript', 'Nodo huérfano',
						'arc_id', v_closest_arc_id           -- Closest arc where node could be placed
					)
				));
				v_count_orphan := v_count_orphan + 1;
			END IF;
		END LOOP;

		-- ------------------------------------------------------------------------
		-- STEP 2: Find T-Candidate Nodes
		-- ------------------------------------------------------------------------
		-- T-candidate nodes: Nodes that are near arcs but are NOT endpoints of those arcs
		-- These nodes are already connected to the network (they are endpoints of other arcs)
		-- but are positioned close to arcs they don't belong to, creating potential T-junctions
		-- Query finds nodes that:
		--   - Are endpoints of some arcs (in the UNION of node_1 and node_2)
		--   - Are within buffer distance of other arcs
		--   - Are NOT endpoints of those nearby arcs (creating T-junction potential)
		FOR rec_tcandidate IN
			EXECUTE format('
				SELECT  DISTINCT n1.*, cxn.*
				FROM cm.om_campaign_lot_x_node n1
				JOIN cm.om_campaign_x_node cxn ON n1.node_id = cxn.node_id
				JOIN PARENT_SCHEMA.cat_feature_node cfn ON cfn.id = cxn.node_type
				where
					cfn.isarcdivide IS TRUE AND
					n1.lot_id in (%s) AND
					EXISTS (SELECT 1 from cm.om_campaign_lot_x_arc arc WHERE (node_1 = n1.node_id OR node_2 = n1.node_id) and ("action" != 3 OR "action" IS NULL))
					AND EXISTS (
						SELECT * FROM cm.om_campaign_x_arc a
						JOIN cm.om_campaign_lot_x_arc oclxa ON a.arc_id = oclxa.arc_id
						WHERE ST_DWithin(a.the_geom, cxn.the_geom, 0.05)
						AND (n1.node_id is distinct from a.node_1 and n1.node_id is distinct from a.node_2)
						AND n1.lot_id = oclxa.lot_id
						AND (oclxa."action" != 3 OR oclxa."action" IS NULL)
					)', array_to_string(v_lot_id_array, ','))
		LOOP

			SELECT arc_id INTO v_arc_id
			FROM cm.om_campaign_x_arc arc
			JOIN cm.om_campaign_lot_x_arc larc USING (arc_id)
			WHERE ST_DWithin(the_geom, rec_tcandidate.the_geom, 0.05)
			AND (rec_tcandidate.node_id is distinct from arc.node_1 and rec_tcandidate.node_id is distinct from arc.node_2)
			AND larc.lot_id = rec_tcandidate.lot_id
			AND (action <> 3 OR action IS NULL)
			ORDER BY arc.the_geom <-> rec_tcandidate.the_geom LIMIT 1;
			RAISE NOTICE 'tcandidate - v_arc_id: %', rec_tcandidate.node_id;

			-- Add T-candidate node to result set
			-- Note: arc_id is NULL because we don't know which specific arc yet
			v_array_nodes := v_array_nodes || jsonb_build_array(jsonb_build_object(
				'type', 'Feature',
				'geometry', ST_Transform(rec_tcandidate.the_geom, 4326),
				'properties', jsonb_build_object(
					'node_id', rec_tcandidate.node_id,
					'nodecat_id', rec_tcandidate.nodecat_id,
					'descript', 'Nodo T candidato',
					'arc_id', v_arc_id
				)
			));
			v_count_tcandidate := v_count_tcandidate + 1;
		END LOOP;

		-- Build final GeoJSON FeatureCollection for temporal layer display
		-- This will be returned as a point layer showing all found nodes
		v_result_point := jsonb_build_object(
			'type', 'FeatureCollection',
			'layerName', 'DividingNodes',
			'features', v_array_nodes
		);

		-- ------------------------------------------------------------------------
		-- STEP 4: Generate Messages and Info
		-- ------------------------------------------------------------------------
		
		-- Log message based on whether nodes were found or not
		IF v_count_orphan > 0 THEN
			EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"4584", "function":"3552", "parameters":{"v_count":"%s"}, "fid":"3552", "fcount":"%s", "is_process":true}}$$)', 
							v_count_orphan, v_count_orphan);
		ELSE
			EXECUTE 'SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"3602", "function":"3552", "fid":"3552", "fcount":"0", "is_process":true}}$$)';
		END IF;

		IF v_count_tcandidate > 0 THEN
			EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"3612", "function":"3552", "parameters":{"v_count":"%s"}, "fid":"3552", "fcount":"%s", "is_process":true}}$$)', 
						v_count_tcandidate, v_count_tcandidate);
		ELSE
			EXECUTE 'SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"3610", "function":"3552", "fid":"3552", "fcount":"0", "is_process":true}}$$)';
		END IF;

		-- Get audit messages from audit_check_data table
		-- These are informational messages logged during the process
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=3552 order by id) row;
		v_result := COALESCE(v_result, '[]');
		v_result_info := concat ('{"values":',v_result, '}');

	-- ============================================================================
	-- SET MODE: Apply Changes - Move Nodes to Nearest Arcs and Update Network
	-- ============================================================================
	
	ELSIF v_mode = 'SET' THEN
		-- Initialize counter and result array for temporal layer (processed nodes)
		v_count_total := 0;
		v_array_nodes := '[]'::jsonb;

		-- ------------------------------------------------------------------------
		-- STEP 1: Process Orphan Nodes
		-- ------------------------------------------------------------------------
		FOR rec_node IN 
			EXECUTE format('
				SELECT DISTINCT a.*, n.the_geom AS campaign_node_geom, n.node_type
				FROM cm.om_campaign_lot_x_node a 
				JOIN cm.om_campaign_x_node n ON n.node_id = a.node_id
				JOIN PARENT_SCHEMA.cat_feature_node cfn ON cfn.id = n.node_type
				WHERE cfn.isarcdivide IS TRUE AND a.lot_id IN (%s) AND (a."action" <> 3 OR a."action" IS NULL)
				AND (SELECT COUNT(*) FROM cm.om_campaign_lot_x_arc WHERE (node_1 = a.node_id OR node_2 = a.node_id) AND ("action" != 3 OR "action" IS NULL)) = 0
				AND EXISTS (
					SELECT 1 FROM cm.om_campaign_x_arc arc
					JOIN cm.om_campaign_lot_x_arc oclxa ON arc.arc_id = oclxa.arc_id
					WHERE ST_DWithin(arc.the_geom, n.the_geom, 0.05)
					AND a.lot_id = oclxa.lot_id
					AND (oclxa."action" != 3 OR oclxa."action" IS NULL)
				)', 
			array_to_string(v_lot_id_array, ','))
		LOOP
			v_node_id := rec_node.node_id;
			RAISE NOTICE 'orphan - v_node_id: %', v_node_id;
			-- Use campaign_node_geom from the JOINed table for spatial operations
			v_node_geom := rec_node.campaign_node_geom;

			FOR v_rec IN SELECT t.table_name, c.column_name AS id_column
				FROM information_schema.tables t
				JOIN information_schema.columns c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
				WHERE t.table_type = 'BASE TABLE'
				  AND t.table_name LIKE 'PARENT_SCHEMA_%'
					AND t.table_schema = 'cm'
				  AND c.ordinal_position = 3
			LOOP
				EXECUTE format('select 1 FROM cm.%I WHERE %I = $1', v_rec.table_name, v_rec.id_column) USING v_node_id INTO v_exists;

				IF v_exists IS NOT NULL THEN
					v_node_type = UPPER(regexp_replace(v_rec.table_name, '^PARENT_SCHEMA_', ''));
					exit;
				END IF;
			END LOOP;

			-- Find the closest arc to this orphan node within buffer distance
			-- Uses PostGIS distance operator for efficient nearest neighbor search
			SELECT arc.arc_id INTO v_arc_id
			FROM cm.om_campaign_x_arc arc
			JOIN cm.om_campaign_lot_x_arc larc ON arc.arc_id = larc.arc_id
			WHERE ST_DWithin(arc.the_geom, v_node_geom, 0.05)
			AND larc.lot_id = rec_node.lot_id
			AND (larc."action" != 3 OR larc."action" IS NULL)
			ORDER BY the_geom <-> v_node_geom LIMIT 1;

			IF v_arc_id IS NOT NULL THEN

				FOR v_rec IN 	SELECT t.table_name, c.column_name AS id_column
								FROM information_schema.tables t
								JOIN information_schema.columns c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
								WHERE t.table_type = 'BASE TABLE'
								AND t.table_name LIKE 'PARENT_SCHEMA_%'
									AND t.table_schema = 'cm'
								AND c.ordinal_position = 3
				LOOP
					EXECUTE format('select 1 FROM cm.%I WHERE %I = $1', v_rec.table_name, v_rec.id_column) USING v_arc_id INTO v_exists;

					IF v_exists IS NOT NULL THEN
						v_arc_type = UPPER(regexp_replace(v_rec.table_name, '^PARENT_SCHEMA_', ''));
						exit;
					END IF;
				END LOOP;

				-- Get the geometry of the closest arc from campaign table
				SELECT * INTO rec_arc FROM cm.om_campaign_x_arc WHERE arc_id = v_arc_id;
				EXECUTE format('SELECT * FROM cm.PARENT_SCHEMA_'||lower(v_arc_type)||' WHERE arc_id = '||v_arc_id) INTO rec_arc_child;

				v_arc_child_table := 'PARENT_SCHEMA_' || lower(v_arc_type);
				SELECT string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
				INTO v_arc_insert_cols
				FROM information_schema.columns
				WHERE table_schema = 'cm'
				AND column_name NOT IN ('id')
				AND table_name = v_arc_child_table;

				IF rec_arc.the_geom IS NOT NULL THEN
					-- Calculate the closest point on the arc to the node
					-- This is where the node will be moved to
					v_closest_point := ST_ClosestPoint(rec_arc.the_geom, v_node_geom);

					-- Move the node to the closest point on the arc
					-- Update campaign node table: only the_geom column
					UPDATE cm.om_campaign_x_node SET the_geom = v_closest_point WHERE node_id = v_node_id;
					RAISE NOTICE 'UPDATE cm.om_campaign_x_node SET the_geom for node_id: %', v_node_id;
					v_querytext := 'UPDATE cm.PARENT_SCHEMA_'||lower(v_node_type)||' SET the_geom = $1 WHERE node_id = '||v_node_id;
					EXECUTE v_querytext USING v_closest_point;
					RAISE NOTICE 'UPDATE cm.PARENT_SCHEMA_% SET the_geom for node_id: %', v_node_type, v_node_id;

					-- Log: node moved (Set mode audit)
					EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"4578", "function":"3552", "parameters":{"node_id": %s, "arc_id": %s}, "fid":"3552", "criticity":"4", "is_process":true}}$$)', v_node_id, v_arc_id);

					-- Divide the arc at this node
					-- This splits the arc into two arcs, with the node as the division point
					
					-- Calculate position along arc where node intersects (0.0 to 1.0)
					v_intersect_loc := ST_LineLocatePoint(rec_arc.the_geom, v_closest_point);
					
					-- Skip division if node is at start (0.0) or end (1.0) of arc
					-- In these cases, the node is already an endpoint and doesn't need to divide the arc

					IF v_intersect_loc >= 0.0 AND v_intersect_loc <= 1.0 THEN
						-- Split arc into two segments
						v_line1 := ST_LineSubstring(rec_arc.the_geom, 0.0, v_intersect_loc);
						v_line2 := ST_LineSubstring(rec_arc.the_geom, v_intersect_loc, 1.0);
						
						-- Check if division creates valid segments (not points)
						IF (ST_GeometryType(v_line1) != 'ST_Point') AND (ST_GeometryType(v_line2) != 'ST_Point') THEN
							
							-- Create first new arc in campaign tables
							v_new_arc_id1 := nextval('cm.cm_urn_id_seq');
							v_new_arc_uuid1 := gen_random_uuid();
					
							SELECT string_agg(
								CASE column_name
									WHEN 'arc_id' THEN v_new_arc_id1::text
									WHEN 'node_1' THEN quote_nullable(rec_arc.node_1)
									WHEN 'node_2' THEN v_node_id::text
									WHEN 'the_geom' THEN '$1'
									WHEN 'arc_type' THEN quote_literal(v_arc_type)
									WHEN 'uuid' THEN quote_literal(v_new_arc_uuid1::text)
									ELSE 's.' || quote_ident(column_name)
								END,
								', ' ORDER BY ordinal_position
							)
							INTO v_arc_select_cols
							FROM information_schema.columns
							WHERE table_schema = 'cm'
							AND column_name NOT IN ('id')
							AND table_name = v_arc_child_table;

							v_querytext := 'INSERT INTO cm.' || v_arc_child_table || ' (' || v_arc_insert_cols || ') SELECT ' || v_arc_select_cols ||
								' FROM cm.' || v_arc_child_table || ' s WHERE s.arc_id = ' || v_arc_id;

							raise notice 'first segment geometry: %', v_line1;

							EXECUTE v_querytext USING v_line1;
							RAISE NOTICE 'INSERT cm.PARENT_SCHEMA_% arc_id: % (first segment, orphan)', v_arc_type, v_new_arc_id1;

							-- Insert into cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom)
							INSERT INTO cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom, arccat_id, arc_type, status)
							VALUES (v_new_arc_id1, v_campaign_id, rec_arc.node_1, v_node_id, v_line1, rec_arc_child.arccat_id, v_arc_type, rec_arc.status);
							RAISE NOTICE 'INSERT cm.om_campaign_x_arc arc_id: %', v_new_arc_id1;
							
							-- Insert into cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2)
							-- Copy all lot associations from original arc to new arc
							INSERT INTO cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2, status, "action")
							SELECT v_new_arc_id1, lot_id, rec_arc.node_1, v_node_id, status, 1
							FROM cm.om_campaign_lot_x_arc WHERE arc_id = v_arc_id;
							RAISE NOTICE 'INSERT cm.om_campaign_lot_x_arc arc_id: % (first segment), node_1: %, node_2: %', v_new_arc_id1, rec_arc.node_1, v_node_id;
							
							raise notice 'INSERTING INTO DOC_X_ARC: %', (select concat(string_agg(doc_id::text, ','), rec_arc_child.uuid) from cm.doc_x_arc WHERE arc_uuid = rec_arc_child.uuid);

							-- INSERT doc relation into new arc
							INSERT INTO cm.doc_x_arc (doc_id, arc_id, arc_uuid, featurecat_id)
							SELECT doc_id, v_new_arc_id1, v_new_arc_uuid1, 'TUBERIA'
							from cm.doc_x_arc
							WHERE arc_uuid = rec_arc_child.uuid;

							raise notice 'INSERTING INTO DOC_X_ARC AFTER: %', (select concat(string_agg(doc_id::text, ',')) from cm.doc_x_arc WHERE arc_uuid = v_new_arc_uuid1);


							-- Create second new arc in campaign tables
							v_new_arc_id2 := nextval('cm.cm_urn_id_seq');
							v_new_arc_uuid2 := gen_random_uuid();
							-- Insert into child tables
							SELECT string_agg(
								CASE column_name
									WHEN 'arc_id' THEN v_new_arc_id2::text
									WHEN 'node_1' THEN v_node_id::text
									WHEN 'node_2' THEN quote_nullable(rec_arc.node_2)
									WHEN 'the_geom' THEN '$1'
									WHEN 'arc_type' THEN quote_literal(v_arc_type)
									WHEN 'uuid' THEN quote_literal(v_new_arc_uuid2::text)
									ELSE 's.' || quote_ident(column_name)
								END,
								', ' ORDER BY ordinal_position
							)
							INTO v_arc_select_cols
							FROM information_schema.columns
							WHERE table_schema = 'cm'
							AND column_name NOT IN ('id')
							AND table_name = v_arc_child_table;

							v_querytext := 'INSERT INTO cm.' || v_arc_child_table || ' (' || v_arc_insert_cols || ') SELECT ' || v_arc_select_cols ||
								' FROM cm.' || v_arc_child_table || ' s WHERE s.arc_id = ' || v_arc_id;

							raise notice 'second segment geometry: %', v_line2;

							EXECUTE v_querytext USING v_line2;
							RAISE NOTICE 'INSERT cm.PARENT_SCHEMA_% arc_id: % (second segment, orphan)', v_arc_type, v_new_arc_id2;

							-- Insert into cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom)
							INSERT INTO cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom, arccat_id, arc_type, status)
							VALUES (v_new_arc_id2, v_campaign_id, v_node_id, rec_arc.node_2, v_line2, rec_arc_child.arccat_id, v_arc_type, rec_arc.status);
							RAISE NOTICE 'INSERT cm.om_campaign_x_arc arc_id: %', v_new_arc_id2;
							
							-- Insert into cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2)
							-- Copy all lot associations from original arc to new arc
							INSERT INTO cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2, status, "action")
							SELECT v_new_arc_id2, lot_id, v_node_id, rec_arc.node_2, status, 1
							FROM cm.om_campaign_lot_x_arc WHERE arc_id = v_arc_id;
							RAISE NOTICE 'INSERT cm.om_campaign_lot_x_arc arc_id: % (second segment), node_1: %, node_2: %', v_new_arc_id2, v_node_id, rec_arc.node_2;
							
							-- INSERT doc relation into new arc
							INSERT INTO cm.doc_x_arc (doc_id, arc_id, arc_uuid, featurecat_id)
							SELECT doc_id, v_new_arc_id2, v_new_arc_uuid2, 'TUBERIA'
							from cm.doc_x_arc
							WHERE arc_uuid = rec_arc_child.uuid;
							
							-- Delete original arc from campaign tables
							IF v_arc_id < 0 THEN
								EXECUTE format('DELETE FROM "cm".%I WHERE arc_id = %s', concat('ve_ap_lot_', lower(v_arc_type)), v_arc_id);
								RAISE NOTICE 'DELETE cm.ap_% WHERE arc_id: %', lower(v_arc_type), v_arc_id;
							ELSE
								EXECUTE format('DELETE FROM "cm".%I WHERE arc_id = %s', concat('ve_PARENT_SCHEMA_lot_', lower(v_arc_type)), v_arc_id);
								RAISE NOTICE 'UPDATE cm.om_campaign_lot_x_arc action=3 for arc_id: %', v_arc_id;
							END IF;
							

							-- Log: arc divided and new arcs created (Set mode audit)
							EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"4580", "function":"3552", "parameters":{"arc_id": %s}, "fid":"3552", "criticity":"4", "is_process":true}}$$)', v_arc_id);
							EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"4582", "function":"3552", "parameters":{"arc_id1": %s, "arc_id2": %s, "arc_id": %s}, "fid":"3552", "criticity":"4", "is_process":true}}$$)', v_new_arc_id1, v_new_arc_id2, v_arc_id);
						END IF;
					END IF;

					-- Add processed orphan node to result layer
					v_array_nodes := v_array_nodes || jsonb_build_array(jsonb_build_object(
						'type', 'Feature',
						'geometry', ST_Transform(v_closest_point, 4326),
						'properties', jsonb_build_object(
							'node_id', v_node_id,
							'descript', 'Nodo huérfano procesado',
							'arc_id', v_arc_id
						)
					));
					v_count_total := v_count_total + 1;
				END IF;
			END IF;
		END LOOP;

		-- ------------------------------------------------------------------------
		-- STEP 2: Process T-Candidate Nodes
		-- ------------------------------------------------------------------------
		FOR rec_node IN
			EXECUTE format('
				SELECT DISTINCT n1.*, cxn.*
				FROM cm.om_campaign_lot_x_node n1
				JOIN cm.om_campaign_x_node cxn ON n1.node_id = cxn.node_id
				JOIN PARENT_SCHEMA.cat_feature_node cfn ON cfn.id = cxn.node_type
				WHERE cfn.isarcdivide IS TRUE AND n1.lot_id IN (%s) AND (n1."action" <> 3 OR n1."action" IS NULL)
				AND EXISTS (SELECT 1 FROM cm.om_campaign_lot_x_arc arc WHERE (node_1 = n1.node_id OR node_2 = n1.node_id) and ("action" != 3 OR "action" IS NULL))
				AND EXISTS (
					SELECT 1 FROM cm.om_campaign_x_arc a
					JOIN cm.om_campaign_lot_x_arc oclxa ON a.arc_id = oclxa.arc_id
					WHERE ST_DWithin(a.the_geom, cxn.the_geom, 0.05)
					AND (n1.node_id is distinct from a.node_1 and n1.node_id is distinct from a.node_2)
					AND n1.lot_id = oclxa.lot_id
					AND (oclxa."action" != 3 OR oclxa."action" IS NULL)
				)', 
				array_to_string(v_lot_id_array, ','))
		LOOP
			v_node_id := rec_node.node_id;
			RAISE NOTICE 'tcandidate - v_node_id: %', v_node_id;
			-- Use campaign_node_geom from the JOINed table for spatial operations
			v_node_geom := rec_node.the_geom;

			FOR v_rec IN 	SELECT t.table_name, c.column_name AS id_column
				FROM information_schema.tables t
				JOIN information_schema.columns c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
				WHERE t.table_type = 'BASE TABLE'
				  AND t.table_name LIKE 'PARENT_SCHEMA_%'
					AND t.table_schema = 'cm'
				  AND c.ordinal_position = 3
			LOOP
				EXECUTE format('select 1 FROM cm.%I WHERE %I = $1', v_rec.table_name, v_rec.id_column) USING v_node_id INTO v_exists;

				IF v_exists IS NOT NULL THEN
					v_node_type = UPPER(regexp_replace(v_rec.table_name, '^PARENT_SCHEMA_', ''));
					exit;
				END IF;
			END LOOP;

			-- Find the closest arc to this T-candidate node within buffer distance
			-- Uses PostGIS distance operator for efficient nearest neighbor search
			SELECT arc.arc_id INTO v_arc_id
			FROM cm.om_campaign_x_arc arc
			JOIN cm.om_campaign_lot_x_arc larc ON arc.arc_id = larc.arc_id
			WHERE ST_DWithin(arc.the_geom, v_node_geom, 0.05)
			AND (v_node_id is distinct from arc.node_1 and v_node_id is distinct from arc.node_2)
			AND larc.lot_id = rec_node.lot_id
			AND (larc."action" <> 3 OR larc."action" IS NULL)
			ORDER BY arc.the_geom <-> v_node_geom LIMIT 1;
			RAISE NOTICE 'tcandidate - v_arc_id: %', v_arc_id;

			-- Process if a nearby arc was found within buffer distance
			IF v_arc_id IS NOT NULL THEN

				FOR v_rec IN 	SELECT t.table_name, c.column_name AS id_column
								FROM information_schema.tables t
								JOIN information_schema.columns c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
								WHERE t.table_type = 'BASE TABLE'
								AND t.table_name LIKE 'PARENT_SCHEMA_%'
									AND t.table_schema = 'cm'
								AND c.ordinal_position = 3
				LOOP
					EXECUTE format('select 1 FROM cm.%I WHERE %I = $1', v_rec.table_name, v_rec.id_column) USING v_arc_id INTO v_exists;

					IF v_exists IS NOT NULL THEN
						v_arc_type = UPPER(regexp_replace(v_rec.table_name, '^PARENT_SCHEMA_', ''));
						exit;
					END IF;
					
				END LOOP;
				-- Get arc geometry from campaign table
				SELECT * INTO rec_arc FROM cm.om_campaign_x_arc WHERE arc_id = v_arc_id;
				EXECUTE format('SELECT * FROM cm.PARENT_SCHEMA_'||lower(v_arc_type)||' WHERE arc_id = '||v_arc_id) INTO rec_arc_child;

				v_arc_child_table := 'PARENT_SCHEMA_' || lower(v_arc_type);
				SELECT string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
				INTO v_arc_insert_cols
				FROM information_schema.columns
				WHERE table_schema = 'cm'
				AND column_name NOT IN ('id')
				AND table_name = v_arc_child_table;

				IF rec_arc.the_geom IS NOT NULL THEN
					-- Calculate closest point on arc
					v_closest_point := ST_ClosestPoint(rec_arc.the_geom, v_node_geom);

					-- Move node to closest point on arc
					-- Update campaign node table: only the_geom column
					UPDATE cm.om_campaign_x_node SET the_geom = v_closest_point WHERE node_id = v_node_id;
					RAISE NOTICE 'UPDATE cm.om_campaign_x_node SET the_geom for node_id: % (tcandidate)', v_node_id;
					v_querytext := 'UPDATE cm.PARENT_SCHEMA_'||lower(v_node_type)||' SET the_geom = $1 WHERE node_id = '||v_node_id;
					EXECUTE v_querytext USING v_closest_point;
					RAISE NOTICE 'UPDATE cm.PARENT_SCHEMA_% SET the_geom for node_id: % (tcandidate)', v_node_type, v_node_id;

					-- Log: node moved (Set mode audit)
					EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"4578", "function":"3552", "parameters":{"node_id": %s, "arc_id": %s}, "fid":"3552", "criticity":"4", "is_process":true}}$$)', v_node_id, v_arc_id);

					-- Update the geometries of the arcs that were already connected to this node
					WITH connected_arcs AS (
						SELECT a.arc_id, a.the_geom,
							n1.the_geom AS node_1_geom, n2.the_geom AS node_2_geom,
							ST_NPoints(a.the_geom) AS npts
						FROM cm.om_campaign_x_arc a
						JOIN cm.om_campaign_x_node n1 ON n1.node_id = a.node_1
						JOIN cm.om_campaign_x_node n2 ON n2.node_id = a.node_2
						WHERE (a.node_1 = v_node_id OR a.node_2 = v_node_id)
						AND a.arc_id != v_arc_id  -- Don't update the arc we're about to divide
					),
					arcs_with_new_geom AS (
						SELECT arc_id,
							CASE
								WHEN npts <= 2 THEN ST_MakeLine(node_1_geom, node_2_geom)
								ELSE ST_MakeLine(
									ARRAY[node_1_geom]
									|| (SELECT array_agg(ST_PointN(the_geom, g.i) ORDER BY g.i) FROM generate_series(2, npts - 1) g(i))
									|| ARRAY[node_2_geom]
								)
							END AS new_geom
						FROM connected_arcs
					)
					UPDATE cm.om_campaign_x_arc SET the_geom = arcs_with_new_geom.new_geom
					FROM arcs_with_new_geom
					WHERE cm.om_campaign_x_arc.arc_id = arcs_with_new_geom.arc_id;
					RAISE NOTICE 'UPDATE cm.om_campaign_x_arc SET the_geom for arcs connected to node_id: %', v_node_id;

					-- Divide the arc at this node to create proper T-junction
					-- This splits the arc into two arcs connected at this node
					
					-- Calculate position along arc where node intersects (0.0 to 1.0)
					v_intersect_loc := ST_LineLocatePoint(rec_arc.the_geom, v_closest_point);
					
					-- Skip division if node is at start (0.0) or end (1.0) of arc
					-- In these cases, the node is already an endpoint and doesn't need to divide the arc
					IF v_intersect_loc >= 0.0 AND v_intersect_loc <= 1.0 THEN
						-- Split arc into two segments
						v_line1 := ST_LineSubstring(rec_arc.the_geom, 0.0, v_intersect_loc);
						v_line2 := ST_LineSubstring(rec_arc.the_geom, v_intersect_loc, 1.0);
						
						-- Check if division creates valid segments (not points)
						IF (ST_GeometryType(v_line1) != 'ST_Point') AND (ST_GeometryType(v_line2) != 'ST_Point') THEN
							
							-- Create first new arc in campaign tables
							v_new_arc_id1 := nextval('cm.cm_urn_id_seq');
							v_new_arc_uuid1 := gen_random_uuid();
							-- Insert into child tables
							SELECT string_agg(
								CASE column_name
									WHEN 'arc_id' THEN v_new_arc_id1::text
									WHEN 'node_1' THEN quote_nullable(rec_arc.node_1)
									WHEN 'node_2' THEN v_node_id::text
									WHEN 'the_geom' THEN '$1'
									WHEN 'arc_type' THEN quote_literal(v_arc_type)
									WHEN 'uuid' THEN quote_literal(v_new_arc_uuid1::text)
									ELSE 's.' || quote_ident(column_name)
								END,
								', ' ORDER BY ordinal_position
							)
							INTO v_arc_select_cols
							FROM information_schema.columns
							WHERE table_schema = 'cm'
							AND column_name NOT IN ('id')
							AND table_name = v_arc_child_table;

							v_querytext := 'INSERT INTO cm.' || v_arc_child_table || ' (' || v_arc_insert_cols || ') SELECT ' || v_arc_select_cols ||
								' FROM cm.' || v_arc_child_table || ' s WHERE s.arc_id = ' || v_arc_id;
							EXECUTE v_querytext USING v_line1;
							RAISE NOTICE 'INSERT cm.PARENT_SCHEMA_% arc_id: % (first segment, tcandidate)', v_arc_type, v_new_arc_id1;

							-- Insert into cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom)
							INSERT INTO cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom, arccat_id, arc_type, status)
							VALUES (v_new_arc_id1, v_campaign_id, rec_arc.node_1, v_node_id, v_line1, rec_arc_child.arccat_id, v_arc_type, rec_arc.status);
							RAISE NOTICE 'INSERT cm.om_campaign_x_arc arc_id: % (tcandidate)', v_new_arc_id1;
							
							-- Insert into cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2)
							-- Copy all lot associations from original arc to new arc
							INSERT INTO cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2, status, "action")
							SELECT v_new_arc_id1, lot_id, rec_arc.node_1, v_node_id, status, 1
							FROM cm.om_campaign_lot_x_arc WHERE arc_id = v_arc_id;
							RAISE NOTICE 'INSERT cm.om_campaign_lot_x_arc arc_id: % (first segment, tcandidate)', v_new_arc_id1;

							-- INSERT doc relation into new arc
							INSERT INTO cm.doc_x_arc (doc_id, arc_id, arc_uuid, featurecat_id)
							SELECT doc_id, v_new_arc_id1, v_new_arc_uuid1, 'TUBERIA'
							from cm.doc_x_arc
							WHERE arc_uuid = rec_arc_child.uuid;
							
							-- Create second new arc in campaign tables
							v_new_arc_id2 := nextval('cm.cm_urn_id_seq');
							v_new_arc_uuid2 := gen_random_uuid();
							-- Insert into child tables
							SELECT string_agg(
								CASE column_name
									WHEN 'arc_id' THEN v_new_arc_id2::text
									WHEN 'node_1' THEN v_node_id::text
									WHEN 'node_2' THEN quote_nullable(rec_arc.node_2)
									WHEN 'the_geom' THEN '$1'
									WHEN 'arc_type' THEN quote_literal(v_arc_type)
									WHEN 'uuid' THEN quote_literal(v_new_arc_uuid2::text)
									ELSE 's.' || quote_ident(column_name)
								END,
								', ' ORDER BY ordinal_position
							)
							INTO v_arc_select_cols
							FROM information_schema.columns
							WHERE table_schema = 'cm'
							AND column_name NOT IN ('id')
							AND table_name = v_arc_child_table;

							v_querytext := 'INSERT INTO cm.' || v_arc_child_table || ' (' || v_arc_insert_cols || ') SELECT ' || v_arc_select_cols ||
								' FROM cm.' || v_arc_child_table || ' s WHERE s.arc_id = ' || v_arc_id;
							EXECUTE v_querytext USING v_line2;
							RAISE NOTICE 'INSERT cm.PARENT_SCHEMA_% arc_id: % (second segment, tcandidate)', v_arc_type, v_new_arc_id2;

							-- Insert into cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom)
							INSERT INTO cm.om_campaign_x_arc (arc_id, campaign_id, node_1, node_2, the_geom, arccat_id, arc_type, status)
							VALUES (v_new_arc_id2, v_campaign_id, v_node_id, rec_arc.node_2, v_line2, rec_arc_child.arccat_id, v_arc_type, rec_arc.status);
							RAISE NOTICE 'INSERT cm.om_campaign_x_arc arc_id: % (tcandidate)', v_new_arc_id2;
							
							-- Insert into cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2)
							-- Copy all lot associations from original arc to new arc
							INSERT INTO cm.om_campaign_lot_x_arc (arc_id, lot_id, node_1, node_2, status, "action")
							SELECT v_new_arc_id2, lot_id, v_node_id, rec_arc.node_2, status, 1
							FROM cm.om_campaign_lot_x_arc WHERE arc_id = v_arc_id;
							RAISE NOTICE 'INSERT cm.om_campaign_lot_x_arc arc_id: % (second segment, tcandidate)', v_new_arc_id2;

							-- INSERT doc relation into new arc
							INSERT INTO cm.doc_x_arc (doc_id, arc_id, arc_uuid, featurecat_id)
							SELECT doc_id, v_new_arc_id2, v_new_arc_uuid2, 'TUBERIA'
							from cm.doc_x_arc
							WHERE arc_uuid = rec_arc_child.uuid;
							
							-- Delete original arc from campaign tables
							IF v_arc_id < 0 THEN
								EXECUTE format('DELETE FROM "cm".%I WHERE arc_id = %s', concat('ve_PARENT_SCHEMA_lot_', lower(v_arc_type)), v_arc_id);
								RAISE NOTICE 'DELETE cm.PARENT_SCHEMA_% WHERE arc_id: %', lower(v_arc_type), v_arc_id;
							ELSE
								EXECUTE format('DELETE FROM "cm".%I WHERE arc_id = %s', concat('ve_PARENT_SCHEMA_lot_', lower(v_arc_type)), v_arc_id);
								RAISE NOTICE 'UPDATE cm.om_campaign_lot_x_arc action=3 for arc_id: %', v_arc_id;
							END IF;

							-- Log: arc divided and new arcs created (Set mode audit)
							EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"4580", "function":"3552", "parameters":{"arc_id": %s}, "fid":"3552", "criticity":"4", "is_process":true}}$$)', v_arc_id);
							EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"data":{"message":"4582", "function":"3552", "parameters":{"arc_id1": %s, "arc_id2": %s, "arc_id": %s}, "fid":"3552", "criticity":"4", "is_process":true}}$$)', v_new_arc_id1, v_new_arc_id2, v_arc_id);
						END IF;
					END IF;

					-- Add processed T-candidate node to result layer
					v_array_nodes := v_array_nodes || jsonb_build_array(jsonb_build_object(
						'type', 'Feature',
						'geometry', ST_Transform(v_closest_point, 4326),
						'properties', jsonb_build_object(
							'node_id', v_node_id,
							'descript', 'Nodo T candidato procesado',
							'arc_id', v_arc_id
						)
					));
					v_count_total := v_count_total + 1;
				END IF;
			END IF;
		END LOOP;

		-- Build point layer with processed nodes (same structure as Check mode)
		v_result_point := jsonb_build_object(
			'type', 'FeatureCollection',
			'layerName', 'DividingNodes',
			'features', v_array_nodes
		);

		-- Log completion message with count of processed nodes
		EXECUTE format('SELECT PARENT_SCHEMA.gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3414", "function":"3552", "parameters":{"v_count":"%s"}, "fid":"3552", "is_process":true}}$$)', v_count_total);

		-- Get audit messages from the process
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM audit_check_data WHERE cur_user="current_user"() AND fid=3552 order by id) row;
		v_result := COALESCE(v_result, '[]');
		v_result_info := concat ('{"values":',v_result, '}');

	-- ============================================================================
	-- INVALID MODE HANDLING
	-- ============================================================================
	ELSE
		-- Mode is neither 'Check' nor 'Set' - log error message
		EXECUTE 'SELECT PARENT_SCHEMA.gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
                       "data":{"message":"3044", "function":"3552","parameters":{"mode":"'||v_mode||'"}, "is_process":true}}$$)';
		v_result_info := '{"values":[]}';
		v_result_point := '{}';
	END IF;

	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');


	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Process done successfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||
			'}}'||
	    '}')::json, 3552, null, null, null);

	EXCEPTION WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_context = pg_exception_context;
		RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE, 'MSGERR', SQLERRM)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

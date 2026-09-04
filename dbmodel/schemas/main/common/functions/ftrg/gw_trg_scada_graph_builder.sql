/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_scada_graph_builder()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$

/*

Documentation:
Takes node_1 and node_2 and connects them with pgr_dijkstra (operative arcs).
Writes the_geom, attrib.arcs and is_scadamap on the path.

TROUBLESHOOTING: If it raises "No network path", there is no continuity between the two nodes. 

 */

DECLARE

-- Init params
v_srid INTEGER;
v_project_type TEXT;

-- Vars

-- Return

BEGIN

    --	Set search path to local schema
    SET search_path = SCHEMA_NAME, public;

    -- Init params
    SELECT upper(project_type), epsg INTO v_project_type, v_srid FROM sys_version ORDER BY id DESC LIMIT 1;

	IF TG_WHEN = 'BEFORE' THEN
	
	    IF TG_OP IN ('INSERT', 'UPDATE') THEN

			IF EXISTS (
				SELECT 1 FROM om_scada_graph g
				WHERE g.node_1 = NEW.node_1
				  AND g.node_2 = NEW.node_2
				  AND TG_OP = 'INSERT'
			) THEN
				RAISE EXCEPTION 'Scada graph edge already exists for node_1=% and node_2=%', NEW.node_1, NEW.node_2
					USING ERRCODE = 'unique_violation';
			END IF;

	    	-- shortest path on operative arcs (not gw_fct_getprofilevalues)
			DROP TABLE IF EXISTS temp_graph;
			IF v_project_type = 'WS' THEN
				CREATE TEMP TABLE temp_graph AS
				SELECT d.edge AS arc_id, d.node AS node_id
				FROM pgr_dijkstra(
					$pgr$WITH
						closed_valve AS (
							SELECT n.node_id
							FROM node n
							JOIN value_state_type s ON n.state_type = s.id
							JOIN man_valve m ON n.node_id = m.node_id
							JOIN cat_node cn ON n.nodecat_id = cn.id
							JOIN cat_feature_node cf ON cf.id = cn.node_type
							WHERE n.state = 1 AND s.is_operative
							AND m.closed AND 'MINSECTOR' = ANY (cf.graph_delimiter)
						)
						SELECT
							a.arc_id::int AS id,
							a.node_1::int AS source,
							a.node_2::int AS target,
							COALESCE(a.custom_length, st_length(a.the_geom)) / (
								COALESCE(NULLIF(ca.dint, 0), 1)::float ^ 2
							) AS cost
						FROM arc a
						JOIN cat_arc ca ON ca.id = a.arccat_id
						JOIN value_state_type s ON a.state_type = s.id
						WHERE a.state = 1 AND s.is_operative
						AND a.node_1 IS NOT NULL AND a.node_2 IS NOT NULL
						AND NOT EXISTS (SELECT 1 FROM closed_valve cv WHERE cv.node_id = a.node_1 OR cv.node_id = a.node_2)
					$pgr$,
					NEW.node_1,
					NEW.node_2,
					directed := false
				) d;
			ELSIF v_project_type = 'UD' THEN
				CREATE TEMP TABLE temp_graph AS
				SELECT d.edge AS arc_id, d.node AS node_id
				FROM pgr_dijkstra(
					$pgr$SELECT
							a.arc_id::int AS id,
							a.node_1::int AS source,
							a.node_2::int AS target,
							COALESCE(a.custom_length, st_length(a.the_geom)) / COALESCE(
								COALESCE(NULLIF(ca.geom1, 0), NULLIF(ca.geom2, 0)) 
								* COALESCE(NULLIF(ca.geom2, 0), NULLIF(ca.geom1, 0)),
								1
							) AS cost, -- geom1*geom2 (geom1,geom2>0) or geom1*geom1(geom2=0) or geom2*geom2(geom1=0) or 1 (geom1=geom2=0)
							-1.0 AS reverse_cost
						FROM arc a
						JOIN cat_arc ca ON ca.id = a.arccat_id
						JOIN value_state_type s ON a.state_type = s.id 
						WHERE a.state = 1 AND s.is_operative AND a.node_1 IS NOT NULL AND a.node_2 IS NOT NULL
					$pgr$,
					NEW.node_1,
					NEW.node_2,
					directed := true
				) d;
			END IF;

			IF NOT EXISTS (SELECT 1 FROM temp_graph) THEN
				RAISE EXCEPTION 'No network path between node_1=% and node_2=%', NEW.node_1, NEW.node_2;
			END IF;

			RETURN NEW;
		END IF;
	
	ELSIF TG_WHEN = 'AFTER' THEN
	
		IF TG_OP IN ('INSERT', 'UPDATE') THEN

			-- UPDATE om_scada_graph with the_geom, attrib, expl_id, node_type_1, node_type_2, group_id, order_id
			UPDATE om_scada_graph g
			SET the_geom = agg.the_geom, attrib = agg.attrib
			FROM (
				SELECT g.node_1, g.node_2,
					ST_Multi(ST_LineMerge(ST_Collect(a.the_geom))) AS the_geom,
					json_build_object('arcs', json_agg(a.arc_id)) AS attrib
				FROM temp_graph t
				JOIN arc a ON t.arc_id = a.arc_id
			) agg
			WHERE t.node_1 = NEW.node_1 AND t.node_2 = NEW.node_2;

			UPDATE om_scada_graph g
			SET expl_id = agg.expl_id
			FROM (
				SELECT g.node_1, g.node_2, array_agg(DISTINCT n.expl_id) AS expl_id
				FROM temp_graph t
				JOIN node n ON t.node_id = n.node_id
			) agg
			WHERE t.node_1 = NEW.node_1 AND t.node_2 = NEW.node_2;
	
			UPDATE om_scada_graph g
			SET node_type_1 = cn1.node_type
			FROM node n1
			JOIN cat_node cn1 ON n1.nodecat_id = cn1.id
			WHERE n1.node_id = NEW.node_id
			AND g.node_1 = NEW.node_id;

			UPDATE om_scada_graph g
			SET node_type_2 = cn2.node_type
			FROM node n2
			JOIN cat_node cn2 ON n2.nodecat_id = cn2.id
			WHERE n2.node_id = NEW.node_id
			AND g.node_2 = NEW.node_id;
			
			-- group_id and order_id only for this row (parent hop + 1, or 1 if node_1 is a root)
	 		UPDATE om_scada_graph g
			SET group_id = COALESCE(t.group_id, NEW.node_1),
				order_id = COALESCE(t.order_id, 0) + 1
			FROM (SELECT 1 AS flag) s
			LEFT JOIN (
				SELECT
					group_id, 
					order_id
				FROM om_scada_graph
				WHERE node_2 = NEW.node_1
				ORDER BY order_id DESC
				LIMIT 1
			) t ON true
			WHERE g.node_1 = NEW.node_1 AND g.node_2 = NEW.node_2;

			-- i_scadamap = TRUE for arcs and nodes in the path
			UPDATE arc SET is_scadamap = TRUE
			WHERE arc_id IN (SELECT arc_id FROM temp_graph);

			UPDATE node SET is_scadamap = TRUE
			WHERE node_id IN (
				SELECT node_id FROM temp_graph
			);

			DROP TABLE IF EXISTS temp_graph;
		
			RETURN NEW;
	
		ELSIF TG_OP = 'DELETE' THEN
		
			RETURN NULL;
		
		
		END IF;


		
	END IF;

    IF TG_OP = 'DELETE' THEN
    
    	RETURN OLD;


    END IF;



END;
$function$
;
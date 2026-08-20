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
Takes object_1 and object_2 and connects them with pgr_dijkstra (operative arcs).
Writes the_geom, attrib.arcs and is_scadamap on the path.

TROUBLESHOOTING: If it raises "No network path", there is no continuity between the two nodes. 

 */

DECLARE

-- Init params
v_srid INTEGER;
v_project_type TEXT;
v_node_1 TEXT;
v_node_2 TEXT;
v_sql_1 TEXT;

-- Vars
v_arc_geom public.geometry(LINESTRING, SRID_VALUE);
v_sql TEXT;
v_arcs TEXT;
v_column_name TEXT;
v_man_table TEXT;
v_table TEXT;
rec record;
v_exists bool;


-- Return
v_return JSON;

-- 


BEGIN

    --	Set search path to local schema
    SET search_path = SCHEMA_NAME, public;

    -- Init params
    SELECT project_type, epsg INTO v_project_type, v_srid FROM sys_version ORDER BY id DESC LIMIT 1;

	IF TG_WHEN = 'BEFORE' THEN
	
	    IF TG_OP IN ('INSERT', 'UPDATE') THEN

			IF EXISTS (
				SELECT 1 FROM om_scada_graph g
				WHERE g.object_1 = NEW.object_1
				  AND g.object_2 = NEW.object_2
				  AND (TG_OP = 'INSERT' OR g.edge_id IS DISTINCT FROM NEW.edge_id)
			) THEN
				RAISE EXCEPTION 'Scada graph edge already exists for object_1=% and object_2=%', NEW.object_1, NEW.object_2
					USING ERRCODE = 'unique_violation';
			END IF;

	    	-- shortest path on operative arcs (not gw_fct_getprofilevalues)
			DROP TABLE IF EXISTS temp_graph;
			CREATE TEMP TABLE temp_graph AS
			SELECT d.edge AS arc_id, d.node AS node_id
			FROM pgr_dijkstra(
				$pgr$SELECT arc_id::int AS id, node_1::int AS source, node_2::int AS target, 1.0 AS cost
				FROM arc WHERE state = 1 AND node_1 IS NOT NULL AND node_2 IS NOT NULL$pgr$,
				NEW.object_1,
				NEW.object_2,
				directed := false
			) d
			WHERE d.edge > 0;

			IF NOT EXISTS (SELECT 1 FROM temp_graph) THEN
				RAISE EXCEPTION 'No network path between object_1=% and object_2=%', NEW.object_1, NEW.object_2;
			END IF;

			SELECT ST_Multi(ST_LineMerge(ST_Collect(b.the_geom)))
			FROM temp_graph a
			JOIN arc b ON a.arc_id = b.arc_id::int
			INTO NEW.the_geom;

			SELECT json_build_object('arcs', json_agg(arc_id))
			FROM temp_graph
			WHERE arc_id IS NOT NULL
			INTO NEW.attrib;

			UPDATE arc SET is_scadamap = TRUE
			WHERE arc_id::int IN (SELECT arc_id FROM temp_graph);
			UPDATE node SET is_scadamap = TRUE
			WHERE node_id::int IN (
				SELECT node_id FROM temp_graph
				UNION SELECT NEW.object_1
				UNION SELECT NEW.object_2
			);

			DROP TABLE IF EXISTS temp_graph;

			RETURN NEW;
		END IF;
	
	ELSIF TG_WHEN = 'AFTER' THEN
	
		IF TG_OP IN ('INSERT', 'UPDATE') THEN

		DROP TABLE IF EXISTS v_om_scada_graph;
		CREATE TEMP TABLE v_om_scada_graph AS
		WITH mec AS (
			SELECT a_1.edge_id,
				a_1.order_id,
				a_1.attrib,
				a_1.expl_add,
				a_1.object_name_1,
				a_1.object_name_2,
				a_1.object_1,
				b_1.nodecat_id AS nc_1,
				b_1.dma_id AS dma_id_1,
				b_1.expl_id AS expl_1,
				a_1.object_2,
				c_1.nodecat_id AS nc_2,
				c_1.dma_id AS dma_id_2,
				c_1.expl_id AS expl_2
			FROM  om_scada_graph a_1
				LEFT JOIN node b_1 ON a_1.object_1 = b_1.node_id::integer
				LEFT JOIN node c_1 ON a_1.object_2 = c_1.node_id::integer
			WHERE a_1.edge_id = NEW.edge_id
		)
		SELECT a.edge_id,
			a.order_id,
			a.attrib,
			a.expl_add,
			a.object_1,
			b.node_type AS object_type_1,
			a.expl_1,
			a.dma_id_1,
			e.name AS dma_name_1,
			a.object_name_1,
			a.object_2,
			c.node_type AS object_type_2,
			a.expl_2,
			a.dma_id_2,
			f.name AS dma_name_2,
			a.object_name_2
		FROM mec a
			LEFT JOIN cat_node b ON a.nc_1::text = b.id::text
			LEFT JOIN cat_node c ON a.nc_2::text = c.id::text
			LEFT JOIN dma e ON a.dma_id_1 = e.dma_id
			LEFT JOIN dma f ON a.dma_id_2 = f.dma_id;
	
			-- attrs that can be taken from table node.
			UPDATE  om_scada_graph t SET 
			objecttype_1 = a.object_type_1,
			objecttype_2 = a.object_type_2,
			dma_id_1 = a.dma_id_1,
			dma_name_1 = a.dma_name_1,
			dma_id_2 = a.dma_id_2,
			dma_name_2 = a.dma_name_2,
			expl_1 = a.expl_1,
			expl_2 = a.expl_2,
			active = TRUE 
			FROM (
				SELECT edge_id, 
				dma_id_1, dma_name_1, object_type_1, expl_1,
				dma_id_2, dma_name_2, object_type_2, expl_2 FROM v_om_scada_graph 
				WHERE edge_id = NEW.edge_id
			)a WHERE t.edge_id = a.edge_id;
			
			-- order_id only for this row (parent hop + 1, or 1 if object_1 is a root)
	 		UPDATE om_scada_graph t SET order_id = COALESCE((
				SELECT MIN(g.order_id) + 1
				FROM om_scada_graph g
				WHERE g.object_2 = NEW.object_1
				  AND g.edge_id IS DISTINCT FROM NEW.edge_id
				  AND g.order_id IS NOT NULL
			), 1)
			WHERE t.edge_id = NEW.edge_id;
		
			v_sql = '
			SELECT v.object_id_col, v.object_id_val, v.object_type_col, v.object_type_val, v.object_name_col,
				concat(''man_node_'', lower(v.object_type_val)) AS man_addf_table, 
				concat(''man_'', lower(b.feature_class)) AS man_table
				FROM om_scada_graph g
				CROSS JOIN LATERAL (
				    VALUES 
				        (''object_1'', g.object_1, ''objecttype_1'', g.objecttype_1,''object_name_1''),
				        (''object_2'', g.object_2, ''objecttype_2'', g.objecttype_2, ''object_name_2'')
				) AS v(object_id_col, object_id_val, object_type_col, object_type_val, object_name_col)
				LEFT JOIN cat_feature b ON v.object_type_val = b.id
			WHERE g.edge_id = '|| NEW.edge_id;

		
			FOR rec IN EXECUTE 'SELECT*FROM ('||v_sql||')' -- build COLUMN names AND VALUES IN a single query
			LOOP 
				-- find column "name" in addfields
				EXECUTE FORMAT('SELECT %L, column_name 
				FROM information_schema.COLUMNS 
				WHERE table_schema = ''SCHEMA_NAME'' 
				AND table_name = %L
				AND column_name = ''name''',
				rec.man_addf_table,
				rec.man_addf_table
				) INTO v_table, v_column_name;

				IF v_column_name IS NOT NULL THEN -- UPDATE ONLY IF COLUMN "name" EXISTS (=avoid objects that don't have name)
			
					EXECUTE FORMAT('UPDATE om_scada_graph SET %s = (
						SELECT %s FROM %s WHERE node_id = %s
					) WHERE edge_id = %s',
					rec.object_name_col,
					v_column_name,
					v_table,
					quote_literal(rec.object_id_val),
					NEW.edge_id);
							
				ELSE -- find COLUMN "name" IN man_table (man_pump, man_valve, ...)
						
					EXECUTE FORMAT('SELECT %L, column_name 
					FROM information_schema.COLUMNS 
					WHERE table_schema = ''SCHEMA_NAME'' 
					AND table_name = %L
					AND column_name = ''name''',
					rec.man_table,
					rec.man_table
					) INTO v_table, v_column_name;
				
					IF v_column_name IS NOT NULL THEN
					
						EXECUTE FORMAT('UPDATE om_scada_graph SET %s = (
							SELECT %s FROM %s WHERE node_id = %s
						) WHERE edge_id = %s',
						rec.object_name_col,
						v_column_name,
						v_table,
						quote_literal(rec.object_id_val),
						NEW.edge_id);
						-- UPDATE om_scada_graph SET object_name_1 = (SELECT name FROM man_tank WHERE node_id = '29801') WHERE edge_id = 9999
				
					END IF;
					
				END IF;
		
			END LOOP;		
		
			DROP TABLE IF EXISTS v_om_scada_graph ;
		
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
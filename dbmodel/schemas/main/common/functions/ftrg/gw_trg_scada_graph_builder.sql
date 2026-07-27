/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_trg_scada_graph_builder();

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_scada_graph_builder()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$

/*

Documentation:
Takes the node_1 and node_2 (from p_data) and connects them using pgrouting. Then, their attributes are inserted into  om_scada_graph table.

TROUBLESHOOTING: If CREATE TEMP TABLE temp_graph fails trying to invoke json_array_elements en un no-array, 
it's because there is no continuity in the path, therefore, the profile does not return de keys needed to create the table. 

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
v_test int;
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
	
	    	-- prepare data (=get arcs i nodes of the routing)   		
    		EXECUTE format(
    		'CREATE TEMP TABLE temp_graph as
		    WITH mec AS (
		        SELECT gw_fct_getprofilevalues(''{"data":{"initNode":"%s", "endNode":"%s", "linksDistance":5}}'') AS v_return
		    )
		    SELECT 
		        (json_array_elements(v_return -> ''body'' -> ''data'' -> ''node'') ->> ''node_id'')::int as node_id,
		        (json_array_elements(v_return -> ''body'' -> ''data'' -> ''arc'') ->> ''arc_id'')::int as arc_id
		    FROM mec', 
		    NEW.object_1, 
		    NEW.object_2
			);
			
			-- get values to update row
			EXECUTE '
			SELECT st_astext(ST_LineMerge(ST_Collect(b.the_geom))) FROM temp_graph a
	        JOIN arc b ON a.arc_id = b.arc_id::int'
			INTO NEW.the_geom;
		
			EXECUTE '
			select 
			json_build_object(
				''arcs'', json_agg(arc_id)
			) from temp_graph where arc_id is not null' 
			INTO NEW.attrib;
			
		
	      	EXECUTE 'UPDATE arc SET is_scadamap = TRUE WHERE arc_id::int IN (SELECT arc_id FROM temp_graph)';
			EXECUTE 'UPDATE node SET is_scadamap = TRUE WHERE node_id::int IN (SELECT node_id FROM temp_graph)';
	
			DROP TABLE IF EXISTS temp_graph;
	      
			RETURN NEW;
		END IF;
	
	ELSIF TG_WHEN = 'AFTER' THEN
	
		IF TG_OP IN ('INSERT', 'UPDATE') THEN

		CREATE TEMP TABLE IF NOT EXISTS v_om_scada_graph  AS
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
			
			-- attrs from the graph 
	 		UPDATE om_scada_graph t SET order_id = a.agg_cost FROM (
				SELECT a.agg_cost, b.edge_id FROM pgr_drivingdistance(
				'SELECT edge_id AS id, object_1 AS SOURCE, object_2 AS TARGET, 1.0 AS COST FROM om_scada_graph',
				(SELECT array_agg(object_1) FROM  om_scada_graph WHERE object_1 NOT IN (SELECT object_2 FROM om_scada_graph)),
				9999,
				FALSE)a JOIN om_scada_graph b ON a.edge = b.edge_id
			)a WHERE t.edge_id = a.edge_id;
		
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
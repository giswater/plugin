/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2994

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_vnode_repair();
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_vnode_repair(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_linkexitgenerator(p_input integer)
RETURNS integer AS
$BODY$

/*EXAMPLE

SELECT  gw_fct_linkexitgenerator(1);

p_input = 1 go2epa
p_input = 2 profiletool


*/

DECLARE

	v_link record;
	v_id integer;
	v_version text;
	v_project_type text;
	v_tolerance double precision = 0.02;
	v_links record;
	v_links_2 record;
	v_geom public.geometry;
	v_loop record;
	v_node record;
	v_end_point public.geometry;
	v_query_text text;
	v_query_text_aux text;
	v_temp_node_table regclass;

BEGIN

	SET search_path= 'SCHEMA_NAME','public';

	-- select config values
	SELECT project_type, giswater INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	IF p_input = 1 THEN -- the whole ve_link (fill_data)
		v_query_text_aux := ' AND sector_id > 0';
	ELSIF p_input = 2 THEN -- only those links wich are on arcs present on temp_anl_arc and nodes present temp_anl_node (profiletool)
		v_query_text_aux := ' AND exit_id IN (SELECT arc_id FROM temp_anl_arc UNION SELECT node_id FROM temp_anl_node)';
	END IF;

	-- insert features temp_link
	v_query_text := format($sql$
		INSERT INTO temp_link (
			link_id, vnode_id, vnode_type, feature_id, feature_type,
			exit_id, exit_type, state, expl_id,
			sector_id, exit_topelev, exit_elev,
			the_geom, the_geom_endpoint, flag
		)
		SELECT
			link_id,
			CASE WHEN exit_type = 'ARC' THEN link_id ELSE exit_id END AS vnode_id,
			exit_type AS vnode_type,
			feature_id,
			feature_type,
			exit_id,
			exit_type,
			state,
			expl_id,
			sector_id,
			top_elev2,
			elevation2,
			the_geom,
			ST_EndPoint(the_geom),
			FALSE
		FROM ve_link n1
		WHERE COALESCE(p_state, state) > 0 
		%s;
	$sql$, v_query_text_aux);

	EXECUTE v_query_text;

	IF v_project_type = 'WS' THEN
		UPDATE temp_link SET omzone_id=l.omzone_id, dma_id = l.dma_id, supplyzone_id = l.supplyzone_id 
		FROM ve_link l 
		WHERE temp_link.link_id = l.link_id;
	END IF;

	-- insert duplicated features on temp_vnode
	INSERT INTO temp_vnode (l1,v1,l2,v2)
	SELECT 
		n1.link_id AS l1, 
		n1.vnode_id AS v1, 
		n2.link_id AS l2, 
		n2.vnode_id AS v2 
	FROM temp_link n1
	JOIN temp_link n2 ON st_dwithin(n1.the_geom_endpoint, n2.the_geom_endpoint, 0.02)
	WHERE n1.link_id < n2.link_id AND n1.exit_id = n2.exit_id
	ORDER BY 1;

	-- harmonize those links with same endpoint
	FOR v_links IN SELECT * FROM temp_vnode order by 1
    LOOP
        UPDATE temp_link a SET vnode_id = t.vnode_id, flag=true 
		FROM temp_link t 
		WHERE a.link_id = v_links.l1 
		AND t.link_id = v_links.l2 
		AND a.flag IS false;
    END LOOP;

	TRUNCATE temp_vnode;

	IF p_input = 1 THEN 
		v_temp_node_table := 'temp_node';
	ELSIF p_input = 2 THEN 
		v_temp_node_table := 'temp_anl_node';
	END IF;
	
	v_query_text := format($sql$
		INSERT INTO temp_vnode (l1, v1, l2, v2)
		SELECT 
			n1.link_id,
			n1.vnode_id,
			n2.node_id::integer,
			n2.node_id::integer
		FROM temp_link n1
		JOIN %I n2 ON ST_DWithin(n1.the_geom_endpoint, n2.the_geom, 0.01)
		JOIN arc a ON n2.node_id::integer = a.node_1::integer
		WHERE a.arc_id = n1.exit_id::integer
		AND n1.exit_type = 'ARC'
		ORDER BY 3;
	$sql$, v_temp_node_table); 

	EXECUTE v_query_text;

	v_query_text := format($sql$
		INSERT INTO temp_vnode (l1, v1, l2, v2)
		SELECT 
			n1.link_id,
			n1.vnode_id,
			n2.node_id::integer,
			n2.node_id::integer
		FROM temp_link n1
		JOIN %I n2 ON ST_DWithin(n1.the_geom_endpoint, n2.the_geom, 0.01)
		JOIN arc a ON n2.node_id::integer = a.node_2::integer
		WHERE a.arc_id = n1.exit_id::integer
		AND n1.exit_type = 'ARC'
		ORDER BY 3;
	$sql$, v_temp_node_table); 

	EXECUTE v_query_text;

	-- harmonize those links with same endpoint whith node
	UPDATE temp_link a 
    SET vnode_id = v.v2, vnode_type = 'NODE'
    FROM temp_vnode v
    WHERE a.link_id = v.l1;

	--  Return
	RETURN 0;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

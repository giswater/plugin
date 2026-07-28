/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2728


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_vnodetrimarcs(result_id_var character varying)  RETURNS json AS
$BODY$

--SELECT link_id, vnode_id FROM SCHEMA_NAME.link, SCHEMA_NAME.vnode where st_dwithin(st_endpoint(link.the_geom), vnode.the_geom, 0.01) and vnode.state = 0 and link.state > 0

/*
SELECT SCHEMA_NAME.gw_fct_pg2epa_vnodetrimarcs('r1')
*/

DECLARE

v_count integer = 0;
v_fid integer = 0;
v_record record;
v_count2 integer = 0;

BEGIN
	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	RAISE NOTICE 'vnodetrimarcs 1 - starting process';
	TRUNCATE temp_t_go2epa;

	CREATE TEMP TABLE t_t_go2epa (LIKE temp_t_go2epa INCLUDING ALL);


	RAISE NOTICE 'vnodetrimarcs 2 - insert node_1 (locate 0 & 1)';
	INSERT INTO t_t_go2epa (arc_id, vnode_id, locate, elevation)
	SELECT arc_id, vnode_id, locate, vnode_elevation
	FROM (	SELECT node_1 as vnode_id, arc_id,  0 as locate, null::numeric as vnode_elevation FROM temp_t_arc WHERE arc_type NOT IN ('NODE2ARC', 'LINK'))z;

	RAISE NOTICE 'vnodetrimarcs 3 - insert node_2 (locate 0 & 1)';
	INSERT INTO t_t_go2epa (arc_id, vnode_id, locate, elevation)
	SELECT  arc_id, vnode_id, locate, elevation
	FROM ( 	SELECT node_2 as vnode_id, arc_id,  1 as locate, null::numeric as elevation FROM temp_t_arc WHERE arc_type NOT IN ('NODE2ARC', 'LINK') )z;

	RAISE NOTICE 'vnodetrimarcs 4 - insert real vnode coming from link (arc_id, vnode_id, locate, elevation, depth)';
	-- First, create a temp table to store the mapping of duplicate vnodes
	CREATE TEMP TABLE IF NOT EXISTS temp_vnode_mapping (
		original_vnode_id text,
		merged_vnode_id text,
		arc_id text,
		locate numeric(12,4)
	);
	TRUNCATE temp_vnode_mapping;

	-- Insert all vnodes with their locations, grouping by arc_id and locate to detect duplicates
	WITH vnode_data AS (
		SELECT
			a.arc_id,
			vnode_id,
			case
				when st_linelocatepoint (a.the_geom , l.the_geom_endpoint) > 0.9999 then 0.9999
				when st_linelocatepoint (a.the_geom , l.the_geom_endpoint) < 0.0001 then 0.0001
				else (st_linelocatepoint (a.the_geom , l.the_geom_endpoint))::numeric(12,4)
			end as locate,
			l.exit_topelev as elevation
		FROM temp_t_arc a, temp_link l
		JOIN connec c ON l.feature_id = c.connec_id::text
		WHERE st_dwithin ( a.the_geom, l.the_geom_endpoint, 0.01) AND l.state > 0
		AND a.arc_type NOT IN ('NODE2ARC', 'LINK') AND a.state > 0
		AND c.epa_type = 'JUNCTION' AND l.vnode_type = 'ARC'
	),
	-- For each unique (arc_id, locate) combination, pick the first vnode_id as the "merged" one
	merged_vnodes AS (
		SELECT DISTINCT ON (arc_id, locate)
			arc_id,
			vnode_id as merged_vnode_id,
			locate,
			elevation
		FROM vnode_data
		ORDER BY arc_id, locate, vnode_id
	)
	-- Insert only the unique vnodes (one per location)
	INSERT INTO t_t_go2epa (arc_id, vnode_id, locate, elevation)
	SELECT arc_id, concat('VN', merged_vnode_id) as vnode_id, locate, elevation
	FROM merged_vnodes;

	-- Store the mapping for later use in demand assignment (one row per link_id)
	WITH link_vnode_data AS (
		SELECT
			l.link_id,
			a.arc_id,
			l.vnode_id,
			case
				when st_linelocatepoint (a.the_geom , l.the_geom_endpoint) > 0.9999 then 0.9999
				when st_linelocatepoint (a.the_geom , l.the_geom_endpoint) < 0.0001 then 0.0001
				else (st_linelocatepoint (a.the_geom , l.the_geom_endpoint))::numeric(12,4)
			end as locate
		FROM temp_t_arc a, temp_link l
		JOIN connec c ON l.feature_id = c.connec_id::text
		WHERE st_dwithin ( a.the_geom, l.the_geom_endpoint, 0.01) AND l.state > 0
		AND a.arc_type NOT IN ('NODE2ARC', 'LINK') AND a.state > 0
		AND c.epa_type = 'JUNCTION' AND l.vnode_type = 'ARC'
	),
	merged_vnodes AS (
		SELECT DISTINCT ON (arc_id, locate)
			arc_id,
			vnode_id as merged_vnode_id,
			locate
		FROM link_vnode_data
		ORDER BY arc_id, locate, vnode_id
	)
	INSERT INTO temp_vnode_mapping (original_vnode_id, merged_vnode_id, arc_id, locate)
	SELECT
		concat('VN', v.link_id) as original_vnode_id,
		concat('VN', m.merged_vnode_id) as merged_vnode_id,
		v.arc_id,
		v.locate
	FROM link_vnode_data v
	JOIN merged_vnodes m ON v.arc_id = m.arc_id AND v.locate = m.locate;


	RAISE NOTICE 'vnodetrimarcs 5 - insert ficticius vnode coming from temp_table (using values created by gw_fct_pg2epa_breakpipes function)';
	INSERT INTO t_t_go2epa (arc_id, vnode_id, locate, elevation)
	SELECT distinct on (temp_t_table.id)
	arc_id,
	concat('VN',temp_t_table.id) as vnode_id,
	case
		when st_linelocatepoint (temp_t_arc.the_geom , geom_point) > 0.9999 then 0.9999
		when st_linelocatepoint (temp_t_arc.the_geom , geom_point) < 0.0001 then 0.0001
		else (st_linelocatepoint (temp_t_arc.the_geom , geom_point))::numeric(12,4) end as locate,
	null::numeric as elevation
	FROM temp_t_arc , temp_t_table
	WHERE st_dwithin ( temp_t_arc.the_geom, geom_point, 0.01)
	AND temp_t_arc.arc_type NOT IN ('NODE2ARC', 'LINK') AND temp_t_arc.state > 0;

	RAISE NOTICE 'vnodetrimarcs 6 - update links connected to a NODE2ARC setting n2a node as node_2';
	-- SELECT links connected to a node2arc arc
	WITH geom_arc AS (
	    SELECT
	        l.link_id,
	        t.arc_id AS arc_id_geom
	    FROM temp_link l
	    JOIN LATERAL (
	        SELECT t2.arc_id
	        FROM temp_t_arc t2
	        WHERE t2.arc_type = 'NODE2ARC'
	          AND t2.state > 0
	          AND ST_DWithin(t2.the_geom, ST_EndPoint(l.the_geom), 0.001)
	        LIMIT 1
	    ) t ON TRUE
	),
	link_arc AS (
	    SELECT link_id, exit_id AS arc_id_link, feature_id
	    FROM temp_link
	)
	-- insert data for later update
	INSERT INTO t_t_go2epa (arc_id, vnode_id, locate, elevation)
	SELECT DISTINCT
	    CONCAT('CO', c.connec_id, 'NODE2ARC') AS arc_id,
	    n.node_id AS vnode_id,
	    NULL::double precision AS locate,
	    NULL::double precision AS elevation
	FROM link_arc la
	JOIN geom_arc ga ON ga.link_id = la.link_id
	JOIN temp_t_arc a1 ON a1.arc_id = la.arc_id_link
	JOIN temp_t_arc a2 ON a2.arc_id = ga.arc_id_geom
	JOIN temp_t_node n ON n.node_id IN (a1.node_1, a1.node_2)
	                   AND n.node_id IN (a2.node_1, a2.node_2)
	JOIN connec c ON c.connec_id::TEXT = la.feature_id;

	-- update links setting n2a node as node_2 and update geometry
	UPDATE temp_t_arc arc
	SET 
	    the_geom = ST_MakeLine(ST_StartPoint(arc.the_geom), t.node_geom),
	    node_2 = t.vnode_id
	FROM (
	    SELECT t.arc_id, t.vnode_id, n.the_geom AS node_geom
	    FROM t_t_go2epa t
	    JOIN temp_t_node n ON n.node_id = t.vnode_id
	) t
	WHERE concat(arc.arc_id, 'NODE2ARC') = t.arc_id;
	
	-- delete used data
	DELETE from t_t_go2epa where arc_id ilike '%NODE2ARC';

	RAISE NOTICE 'vnodetrimarcs 7 - insert connec over arc';
	INSERT INTO t_t_go2epa (arc_id, vnode_id, locate, elevation)
	SELECT distinct on (node_id)
	temp_t_arc.arc_id,
	concat('VC',node_id) as vnode_id,
	case
		when st_linelocatepoint (temp_t_arc.the_geom , vnode.the_geom) > 0.9999 then 0.9999
		when st_linelocatepoint (temp_t_arc.the_geom , vnode.the_geom) < 0.0001 then 0.0001
		else (st_linelocatepoint (temp_t_arc.the_geom , vnode.the_geom))::numeric(12,4) end as locate,
	vnode.top_elev
	FROM temp_t_arc, temp_t_node AS vnode
	WHERE node_type = 'CONNEC' AND st_dwithin ( temp_t_arc.the_geom, vnode.the_geom, 0.01)
	AND vnode.state > 0 AND temp_t_arc.arc_type NOT IN ('NODE2ARC', 'LINK');

	RAISE NOTICE 'vnodetrimarcs 7b - deduplicate vnodes on same arc';
	-- Same vnode at multiple locates (link harmonization) creates EPANET pipes with node_1 = node_2
	DELETE FROM t_t_go2epa t
	USING t_t_go2epa t2
	WHERE t.arc_id = t2.arc_id
	  AND t.vnode_id = t2.vnode_id
	  AND (t.locate > t2.locate OR (t.locate = t2.locate AND t.id > t2.id));

	-- Different vnodes at the same locate (link + breakpipe overlap)
	DELETE FROM t_t_go2epa t
	USING t_t_go2epa t2
	WHERE t.arc_id = t2.arc_id
	  AND t.locate = t2.locate
	  AND t.id > t2.id;

	RAISE NOTICE 'vnodetrimarcs 8 - insert previous data into data on temp_table';
	INSERT INTO temp_t_go2epa (arc_id, vnode_id, locate, elevation, depth)
	SELECT  arc.arc_id::text, vnode_id, locate,
	case when t.elevation is null then (n1.top_elev - locate*(n1.top_elev-n2.top_elev))::numeric(12,3) ELSE t.elevation END as elevation,
	(CASE WHEN (n1.depth - locate*(n1.depth-n2.depth)) IS NULL THEN 0 ELSE (n1.depth - locate*(n1.depth-n2.depth)) END)::numeric (12,3) as depth
	FROM t_t_go2epa t
	JOIN arc ON t.arc_id=arc.arc_id::text
	JOIN node n1 ON node_1 = node_id
	JOIN node n2 ON node_2 = n2.node_id
	ORDER BY arc_id, locate;

	DROP TABLE t_t_go2epa;


	RAISE NOTICE 'vnodetrimarcs 9 - Delete connec over arcs ';
	UPDATE temp_t_node SET epa_type = 'TODELETE' FROM arc JOIN connec c USING (arc_id)
	WHERE node_type = 'CONNEC' AND st_dwithin ( arc.the_geom, temp_t_node.the_geom, 0.01) AND c.connec_id::text = temp_t_node.node_id;
	DELETE FROM temp_t_node WHERE epa_type = 'TODELETE';

	RAISE NOTICE '4 - new nodes from links on temp_t_node table ';
	INSERT INTO temp_t_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, the_geom, addparam, dma_id, presszone_id, dqa_id, minsector_id)
	SELECT
		vnode_id as node_id,
		t.elevation::numeric(12,3), -- elevation it's interpolated elevation against node1 and node2 of pipe
		t.elevation::numeric(12,3) - t.depth::numeric(12,3) as elev,  -- elev it's interpolated using elevation-depth against node1 and node2 of pipe
		'VNODE',
		'VNODE',
		'JUNCTION',
		a.sector_id,
		a.state,
		a.state_type,
		null,
		ST_LineInterpolatePoint (a.the_geom, locate::numeric(12,4)) as the_geom,
		addparam, a.dma_id, a.presszone_id, a.dqa_id, a.minsector_id
		FROM temp_t_go2epa t
		JOIN temp_t_arc a ON a.arc_id::text = t.arc_id
		WHERE vnode_id like 'VN%' AND a.arc_type !='LINK';


	RAISE NOTICE 'vnodetrimarcs 10 - new nodes from connecs over arc on temp_t_node table ';
	INSERT INTO temp_t_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, the_geom, addparam, dma_id, presszone_id, dqa_id, minsector_id)
	SELECT
		vnode_id as node_id,
		t.elevation::numeric(12,3), -- elevation it's interpolated elevation against node1 and node2 of pipe
		t.elevation::numeric(12,3) - t.depth::numeric(12,3) as elev,  -- elev it's interpolated using elevation-depth against node1 and node2 of pipe
		'VCONNEC',
		'VNODE',
		'JUNCTION',
		a.sector_id,
		a.state,
		a.state_type,
		null,
		ST_LineInterpolatePoint (a.the_geom, locate::numeric(12,4)) as the_geom,
		addparam, a.dma_id, a.presszone_id, a.dqa_id, a.minsector_id
		FROM temp_t_go2epa t
		JOIN temp_t_arc a USING (arc_id)
		WHERE vnode_id like 'VC%' AND a.arc_type !='LINK';


	RAISE NOTICE 'vnodetrimarcs 11 - update temp_table to work with next process';
	UPDATE temp_t_go2epa SET idmin = c.idmin FROM
	(SELECT min(id) as idmin, arc_id FROM (
		SELECT  a.id, a.arc_id as arc_id, a.vnode_id as node_1, (a.locate)::numeric(12,4) as locate_1 ,
			b.vnode_id as node_2, (b.locate)::numeric(12,4) as locate_2
			FROM temp_t_go2epa a
			JOIN temp_t_go2epa b ON a.id=b.id-1 WHERE a.arc_id=b.arc_id
			ORDER by arc_id)
			a group by arc_id) c
		WHERE temp_t_go2epa.arc_id = c.arc_id;


	RAISE NOTICE 'vnodetrimarcs 12 - new arcs on temp_t_arc table';
	INSERT INTO temp_t_arc (arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, diameter, roughness, length, status,
	the_geom, flw_code, minorloss, addparam, arcparent, dma_id, presszone_id, dqa_id, minsector_id, family, builtdate)

	WITH a AS (SELECT  a.idmin, a.id, a.arc_id as arc_id, a.vnode_id as node_1, (a.locate)::numeric(12,4) as locate_1 ,
			b.vnode_id as node_2, (b.locate)::numeric(12,4) as locate_2
			FROM temp_t_go2epa a
			LEFT JOIN temp_t_go2epa b ON a.id=b.id-1 WHERE a.arc_id=b.arc_id
			ORDER by arc_id)
	SELECT
		concat(arc_id,'P',a.id-a.idmin) as arc_id,
		a.node_1,
		a.node_2,
		temp_t_arc.arc_type,
		temp_t_arc.arccat_id,
		temp_t_arc.epa_type,
		temp_t_arc.sector_id,
		temp_t_arc.state,
		temp_t_arc.state_type,
		temp_t_arc.annotation,
		temp_t_arc.diameter,
		temp_t_arc.roughness,
		st_length(ST_LineSubstring(the_geom, locate_1, locate_2)),
		temp_t_arc.status,
		CASE
			WHEN st_geometrytype(ST_LineSubstring(the_geom, locate_1, locate_2))='ST_LineString' THEN ST_LineSubstring(the_geom, locate_1, locate_2)
			ELSE null END AS the_geom,
		temp_t_arc.flw_code,
		0,
		temp_t_arc.addparam,
		a.arc_id, dma_id, presszone_id, dqa_id, minsector_id, family, builtdate
		FROM a
		JOIN temp_t_arc USING (arc_id)
		WHERE (a.node_1 ilike 'VN%' OR a.node_2 ilike 'VN%' OR a.node_1 ilike 'VC%' or a.node_2 ilike 'VC%')
		AND a.node_1 IS DISTINCT FROM a.node_2
		ORDER BY temp_t_arc.arc_id, a.id;


	RAISE NOTICE 'vnodetrimarcs 13 - delete only trimmed arc on temp_t_arc table';
	-- step 1
	UPDATE temp_t_arc SET epa_type ='TODELETE'
		FROM (SELECT DISTINCT arcparent AS arc_id FROM temp_t_arc WHERE arcparent !='') a
		WHERE a.arc_id = temp_t_arc.arc_id;
	-- step 2
	DELETE FROM temp_t_arc WHERE epa_type ='TODELETE';

	RAISE NOTICE '8 - set minimum value of arcs';
	UPDATE temp_t_arc SET length=0.01 WHERE length < 0.01;

	RAISE NOTICE '9 - delete those repeated vnodes when more than one link is sharing same vnode';
	-- step 1
	UPDATE temp_t_node SET epa_type ='TODELETE' FROM (SELECT a.id FROM temp_t_node a, temp_t_node b WHERE a.id < b.id AND a.node_id = b.node_id)a WHERE temp_t_node.id = a.id;
	-- step 2
	DELETE FROM temp_t_node WHERE epa_type ='TODELETE';

	RAISE NOTICE '10 - cleanup temp_vnode_mapping table (keep it for demand functions)';
	-- Note: temp_vnode_mapping is kept as it's a session-level temp table and will be used by demand functions

RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
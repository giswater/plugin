/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- FUNCTION CODE: 3492

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_graphanalytics_omunit(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_graphanalytics_omunit(p_data json)
RETURNS json AS
$BODY$

/*
TO EXECUTE

SELECT gw_fct_graphanalytics_omunit($$
	{
		"data":{
			"parameters":{
				"exploitation":"1",
				"updateMapZone":2,
				"geomParamUpdate":15,
				"commitChanges":true,
				"usePlanPsector":false
			}
		}
	}
$$);

--fid: 640

*/

DECLARE

    -- dialog
    v_expl_id TEXT;
    v_expl_id_array INTEGER[];
    v_usepsector BOOLEAN;
    v_updatemapzgeom INTEGER;
    v_geomparamupdate FLOAT;
    v_commitchanges BOOLEAN;

    v_data JSON;

    v_fid INTEGER = 640;
    v_query_text TEXT;

    v_version TEXT;

    v_visible_layer TEXT;

    -- result variables
    v_result JSON;
    v_result_info JSON;
    v_result_polygon JSON;
    v_result_polygon_omunit JSON;
    v_result_polygon_macroomunit JSON;

    -- response variables
	v_level integer;
	v_status text;
	v_message text;
	v_response JSON;

    v_error_context text;

	-- LOCK LEVEL LOGIC
	v_original_disable_locklevel json;
	v_original_disable_fkarray text;

    -- general variables
    v_root_vids int[];

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME";

    -- Select configuration values
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

    -- Get variables from input JSON
	v_expl_id = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'exploitation');
    v_usepsector = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'usePlanPsector')::BOOLEAN;
	v_commitchanges = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'commitChanges')::BOOLEAN;
	v_updatemapzgeom = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'updateMapZone');
	v_geomparamupdate = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'geomParamUpdate');

    -- it's not allowed to commit changes when psectors are used
 	IF v_usepsector AND v_commitchanges THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4542", "function":"2706", "parameters":null}}$$);';
	END IF;

    -- Get exploitation ID array
    v_expl_id_array := gw_fct_get_expl_id_array(v_expl_id);

    -- if v_expl_id_array is null, return error
    IF v_expl_id_array IS NULL THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		       	"data":{"message":"4478", "function":"3492","parameters":null}}$$);';
    END IF;

    -- Get user variable for disabling lock level
    SELECT value::json INTO v_original_disable_locklevel FROM config_param_user
    WHERE parameter = 'edit_disable_locklevel' AND cur_user = current_user;
    -- Set disable lock level to true for this operation
    UPDATE config_param_user SET value = '{"update":true, "delete":true}'
    WHERE parameter = 'edit_disable_locklevel' AND cur_user = current_user;

	-- Delete temporary tables
	-- =======================
	v_data := '{"data":{"action":"DROP", "fct_name":"OMUNIT"}}';
	SELECT gw_fct_graphanalytics_manage_temporary(v_data) INTO v_response;

	IF v_response->>'status' <> 'Accepted' THEN
        RETURN v_response;
    END IF;

	-- Create temporary tables
	-- =======================
    v_data := '{"data":{"action":"CREATE", "fct_name":"OMUNIT", "use_psector":"'|| v_usepsector ||'"}}';
	SELECT gw_fct_graphanalytics_manage_temporary(v_data) INTO v_response;

    IF v_response->>'status' <> 'Accepted' THEN
        RETURN v_response;
    END IF;

	-- Starting process
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3492", "fid":"'||v_fid||'", "criticity":"4", "is_process":true, "is_header":"true", "separator_id":"2049", "tempTable":"temp_"}}$$)';

    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3492", "fid":"'||v_fid||'","criticity":"3", "tempTable":"temp_", "is_process":true, "is_header":"true", "label_id":"3003", "separator_id":"2011"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3492", "fid":"'||v_fid||'", "criticity":"2", "is_process":true, "separator_id":"2000", "tempTable":"temp_"}}$$)';
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3492", "fid":"'||v_fid||'","criticity":"2", "tempTable":"temp_", "is_process":true, "is_header":"true", "label_id":"3002", "separator_id":"2014"}}$$)';
    EXECUTE 'SELECT gw_fct_getmessage($${"data":{"function":"3492", "fid":"'||v_fid||'","criticity":"1", "tempTable":"temp_", "is_process":true, "is_header":"true", "label_id":"3001", "separator_id":"2007"}}$$)';

    -- Initialize process
	-- =======================
    v_query_text := $q$
        SELECT arc_id AS id, node_1 AS source, node_2 AS target, 1 AS cost
        FROM v_temp_arc
    $q$;

    -- INSERT
	EXECUTE format($sql$
        WITH connectedcomponents AS (
            SELECT *
            FROM pgr_connectedcomponents($q$%s$q$)
        ),
        components AS (
            SELECT c.component
            FROM connectedcomponents c
            WHERE cardinality($1) = 0
            OR EXISTS (
                SELECT 1
                FROM v_temp_arc v
                WHERE v.expl_id = ANY($1)
                AND v.node_1 = c.node
            )
            GROUP BY c.component
        )
        INSERT INTO temp_pgr_node (pgr_node_id)
        SELECT c.node
        FROM connectedcomponents c
        WHERE EXISTS (
            SELECT 1
            FROM components cc
            WHERE cc.component = c.component
        )
    $sql$, v_query_text)
    USING v_expl_id_array;

	INSERT INTO temp_pgr_arc (pgr_arc_id, pgr_node_1, pgr_node_2)
	SELECT a.arc_id, a.node_1, a.node_2
	FROM v_temp_arc a
	JOIN temp_pgr_node n1 ON n1.pgr_node_id = a.node_1
	JOIN temp_pgr_node n2 ON n2.pgr_node_id = a.node_2;

	INSERT INTO temp_pgr_connec (pgr_connec_id, pgr_arc_id)
	SELECT c.connec_id, c.arc_id
	FROM v_temp_connec c
	JOIN temp_pgr_arc a ON a.pgr_arc_id = c.arc_id;

    INSERT INTO temp_pgr_gully (pgr_gully_id, pgr_arc_id)
	SELECT g.gully_id, g.arc_id
	FROM v_temp_gully g
	JOIN temp_pgr_arc a ON a.pgr_arc_id = g.arc_id;

    INSERT INTO temp_pgr_old_mapzone (mapzone_id, macromapzone_id)
    SELECT DISTINCT a.omunit_id, o.macroomunit_id
    FROM temp_pgr_arc t
    JOIN arc a ON t.pgr_arc_id = a.arc_id
    JOIN omunit o ON a.omunit_id = o.omunit_id
    WHERE a.omunit_id > 0;

    UPDATE temp_pgr_node t
    SET graph_delimiter = 'OMUNIT'
    FROM v_temp_node vn
    JOIN node n ON n.node_id = vn.node_id
    WHERE 'OMUNIT' = ANY(vn.graph_delimiter)
    AND n.has_access = TRUE
    AND t.pgr_node_id = vn.node_id;

    --------------------------------------------------
    -- SECTION: Create omunits and macroomunits
    --------------------------------------------------

    -- fill table temp_pgr_arc_linegraph using pgr_lineGraph for oriented graphs 
    -- in the result, reverse_cost will be always -1
    -- pgr_node_1 and pgr_node_2 are connected arcs
    INSERT INTO temp_pgr_arc_linegraph (pgr_arc_id, pgr_node_1, pgr_node_2, COST, reverse_cost)
    SELECT seq, source, target, cost, reverse_cost
    FROM pgr_lineGraph(
        'SELECT pgr_arc_id as id, pgr_node_1 as source, pgr_node_2 as target, 1 as cost, -1 as reverse_cost
        FROM temp_pgr_arc',
        directed => true
    );

    -- CATCHMENTS
    -- choose the best candidate among TARGET ARCS (pgr_node_2); the ones that are not the best candidate will have graph_delimiter = 'CATCHMENT'; the best candidate will keep graph_delimiter = 'NONE'
    -- TODO improve the condition, add section and elevation (F_FACTOR)
    WITH 
        pair_arcs AS (
            SELECT 
                l.pgr_node_1, l.pgr_arc_id, l.pgr_node_2,
                CASE
                    WHEN a1.initoverflowpath = a2.initoverflowpath THEN 0  -- the same: first
                    ELSE 1                                        -- not the same: after
                END AS initoverflowpath,
                least(
	                abs(st_azimuth(st_lineinterpolatepoint(a1.the_geom,0.99),st_endpoint(a1.the_geom))
	                - st_azimuth(st_startpoint(a2.the_geom),st_lineinterpolatepoint(a2.the_geom,0.01)) 
	                ),
	                2*pi() - 
	                abs(st_azimuth(st_lineinterpolatepoint(a1.the_geom,0.99),st_endpoint(a1.the_geom))
	                - st_azimuth(st_startpoint(a2.the_geom),st_lineinterpolatepoint(a2.the_geom,0.01)) 
	                )
                ) AS azimuth_difference
            FROM temp_pgr_arc_linegraph l
            JOIN arc a1 ON l.pgr_node_1 = a1.arc_id
            JOIN arc a2 ON l.pgr_node_2 = a2.arc_id
        ),
        best_pair AS (
            SELECT DISTINCT ON (pgr_node_1) pgr_node_1, pgr_node_2, pgr_arc_id
            FROM pair_arcs
            ORDER BY pgr_node_1, initoverflowpath, azimuth_difference, pgr_node_2
        )
    UPDATE temp_pgr_arc_linegraph l
    SET graph_delimiter = 'CATCHMENT'
    WHERE NOT EXISTS (SELECT 1 FROM best_pair bp WHERE bp.pgr_arc_id = l.pgr_arc_id);

    -- MACROOMUNITS
    -- choose the best candidate among SOURCE ARCS (pgr_node_1); the ones that are not the best candidate will have graph_delimiter = 'MACROOMUNIT'; 
    -- every macroomunit will be a chain, the relation between arcs-in and arcs-out of a node is 1:1
    -- TODO improve the condition, add section and elevation - if it's needed
    WITH 
        pair_arcs AS (
            SELECT 
                l.pgr_node_1, l.pgr_arc_id, l.pgr_node_2, l.graph_delimiter,
                least(
	                abs(st_azimuth(st_lineinterpolatepoint(a1.the_geom,0.99),st_endpoint(a1.the_geom))
	                - st_azimuth(st_startpoint(a2.the_geom),st_lineinterpolatepoint(a2.the_geom,0.01)) 
	                ),
	                2*pi() - 
	                abs(st_azimuth(st_lineinterpolatepoint(a1.the_geom,0.99),st_endpoint(a1.the_geom))
	                - st_azimuth(st_startpoint(a2.the_geom),st_lineinterpolatepoint(a2.the_geom,0.01)) 
	                )
                ) AS azimuth_difference
            FROM temp_pgr_arc_linegraph l
            JOIN arc a1 ON l.pgr_node_1 = a1.arc_id
            JOIN arc a2 ON l.pgr_node_2 = a2.arc_id
            WHERE graph_delimiter = 'NONE'
        ),
        best_pair AS (
            SELECT DISTINCT ON (pgr_node_2) pgr_node_2, pgr_node_1, pgr_arc_id
            FROM pair_arcs
            ORDER BY pgr_node_2, azimuth_difference, pgr_node_1
        )
    UPDATE temp_pgr_arc_linegraph l
    SET graph_delimiter = 'MACROOMUNIT'
    WHERE l.graph_delimiter = 'NONE'
    AND NOT EXISTS (SELECT 1 FROM best_pair bp WHERE bp.pgr_arc_id = l.pgr_arc_id);

    -- OMUNITS
    -- =======================
    --TODO maybe should be good checking the accessibility of the node with graph_delimiter = 'OMUNIT'
    UPDATE temp_pgr_arc_linegraph l
    SET graph_delimiter = 'OMUNIT'
    FROM temp_pgr_arc a
    WHERE l.graph_delimiter ='NONE'
        AND l.pgr_node_1 = a.pgr_arc_id
        AND EXISTS (
            SELECT 1 FROM temp_pgr_node n 
            JOIN node nn ON n.pgr_node_id = nn.node_id
            WHERE n.graph_delimiter = 'OMUNIT'
            AND nn.has_access
            AND a.pgr_node_2 = n.pgr_node_id   
        );

    -- generate omunit_id applying connectedComponents over temp_pgr_arc_linegraph filtering graph_delimiter = 'OMUNIT', 'MACROOMUNIT' AND 'CATCHMENT'
    TRUNCATE temp_pgr_connectedcomponents;
    INSERT INTO temp_pgr_connectedcomponents(seq, component, node)
    SELECT seq, component, node 
    FROM pgr_connectedcomponents(
        'SELECT pgr_arc_id AS id, pgr_node_1 AS source, pgr_node_2 AS target, cost 
        FROM temp_pgr_arc_linegraph
        WHERE graph_delimiter <> ''OMUNIT'' 
            AND graph_delimiter <> ''MACROOMUNIT'' 
            AND graph_delimiter <> ''CATCHMENT'' 
        '
    );

    -- Update the mapzone_id (omunit) for arcs
    UPDATE temp_pgr_arc a
    SET
        mapzone_id = c.component
    FROM temp_pgr_connectedcomponents c
    WHERE a.pgr_arc_id = c.node;

    -- update the mapzone_id (omunit) for arcs that have node_1 and node_2 graph_delimiters or isolated arcs
    UPDATE temp_pgr_arc a
    SET mapzone_id = pgr_arc_id
    WHERE mapzone_id = 0;

    -- fill table temp_pgr_omunit
    INSERT INTO temp_pgr_omunit (omunit_id)
    SELECT DISTINCT mapzone_id
    FROM temp_pgr_arc;

    WITH omunit_start AS (
        SELECT t.mapzone_id, t.pgr_node_1
        FROM temp_pgr_arc t
        WHERE NOT EXISTS (
            SELECT 1 
            FROM temp_pgr_arc t2
            WHERE t.mapzone_id = t2.mapzone_id 
            AND t.pgr_node_1 = t2.pgr_node_2
        )
    )
    UPDATE temp_pgr_omunit o
    SET node_1 = os.pgr_node_1
    FROM omunit_start os
    WHERE o.omunit_id = os.mapzone_id;

    WITH omunit_end AS (
        SELECT t.mapzone_id, t.pgr_node_2
        FROM temp_pgr_arc t
        WHERE NOT EXISTS (
            SELECT 1 
            FROM temp_pgr_arc t2
            WHERE t.mapzone_id = t2.mapzone_id 
            AND t.pgr_node_2 = t2.pgr_node_1
        )
    )
    UPDATE temp_pgr_omunit o
    SET node_2 = oe.pgr_node_2
    FROM omunit_end oe
    WHERE o.omunit_id = oe.mapzone_id;

    -- MACROOMUNITS
    -- =======================
    -- generate macroomunit_id applying connectedComponents over temp_pgr_arc_linegraph filtering graph_delimiter = 'MACROOMUNIT' and 'CATCHMENT'
    TRUNCATE temp_pgr_connectedcomponents;
    INSERT INTO temp_pgr_connectedcomponents(seq, component, node)
    SELECT seq, component, node 
    FROM pgr_connectedcomponents(
        'SELECT pgr_arc_id AS id, pgr_node_1 AS source, pgr_node_2 AS target, cost 
        FROM temp_pgr_arc_linegraph
        WHERE graph_delimiter <> ''MACROOMUNIT''
        AND graph_delimiter <> ''CATCHMENT'' 
        '
    );

    -- Update the macroomunit_id  for arcs
    UPDATE temp_pgr_arc a
    SET
        macromapzone_id = c.component
    FROM temp_pgr_connectedcomponents c
    WHERE a.pgr_arc_id = c.node;

    -- update macroomunit_id for arcs that have node_1 and node_2 graph_delimiters or isolated arcs
    UPDATE temp_pgr_arc a
    SET macromapzone_id = pgr_arc_id
    WHERE macromapzone_id = 0;

    -- Update the macroomunit_id for omunit_id
    UPDATE temp_pgr_omunit o
    SET
        macroomunit_id = a.macroomunit_id
    FROM 
        (SELECT DISTINCT mapzone_id as omunit_id, macromapzone_id AS macroomunit_id
        FROM  temp_pgr_arc
        ) a
    WHERE o.omunit_id = a.omunit_id;

    -- fill table temp_pgr_macroomunit
    INSERT INTO temp_pgr_macroomunit (macroomunit_id)
    SELECT DISTINCT macroomunit_id
    FROM temp_pgr_omunit;

    WITH macroomunit_start AS (
        SELECT t.macromapzone_id, t.pgr_node_1
        FROM temp_pgr_arc t
        WHERE NOT EXISTS (
            SELECT 1 
            FROM temp_pgr_arc t2
            WHERE t.macromapzone_id = t2.macromapzone_id 
            AND t.pgr_node_1 = t2.pgr_node_2
        )
    )
    UPDATE temp_pgr_macroomunit o
    SET node_1 = os.pgr_node_1
    FROM macroomunit_start os
    WHERE o.macroomunit_id = os.macromapzone_id;

    WITH macroomunit_end AS (
        SELECT t.macromapzone_id, t.pgr_node_2
        FROM temp_pgr_arc t
        WHERE NOT EXISTS (
            SELECT 1 
            FROM temp_pgr_arc t2
            WHERE t.macromapzone_id = t2.macromapzone_id 
            AND t.pgr_node_2 = t2.pgr_node_1
        )
    )
    UPDATE temp_pgr_macroomunit o
    SET node_2 = oe.pgr_node_2
    FROM macroomunit_end oe
    WHERE o.macroomunit_id = oe.macromapzone_id;

    -- CATCHMENT_NODE AND ORDER SECTION FOR OMUNITS/MACROOMUNITS
    --===================================================

    -- choose the arcs from where starts 
    SELECT array_agg(a.pgr_arc_id)::INT[] INTO v_root_vids
    FROM temp_pgr_arc a
    WHERE NOT EXISTS (
        SELECT 1 FROM temp_pgr_arc a1
        WHERE a.pgr_node_2 = a1.pgr_node_1
    ); 

    -- Traverse the line graph upstream (from pgr_node_2 to pgr_node_1)
    -- filter CATCHMENT boundary connections.
    -- TODO (maybe) order using elev2 for a better ordering, could be faster
    INSERT INTO temp_pgr_drivingdistance(seq, "depth", start_vid, node, edge, "cost", agg_cost)
    (
        SELECT seq, "depth", start_vid, node, edge, "cost", agg_cost
        FROM pgr_depthFirstSearch(
            'SELECT l.pgr_arc_id AS id, l.pgr_node_2 AS source, l.pgr_node_1 AS target, l.cost, l.reverse_cost 
            FROM temp_pgr_arc_linegraph l
            WHERE l.graph_delimiter <> ''CATCHMENT''
            ',
        v_root_vids, directed => true)
    );

    -- update catchment_node for macroomunits
    UPDATE temp_pgr_macroomunit m
    SET catchment_node = t.catchment_node
    FROM (
        SELECT DISTINCT a.macromapzone_id AS macroomunit_id, a2.pgr_node_2 AS catchment_node
        FROM temp_pgr_drivingdistance d
        JOIN temp_pgr_arc a ON d.node = a.pgr_arc_id
        JOIN temp_pgr_arc a2 ON d.start_vid = a2.pgr_arc_id
    ) t
    WHERE t.macroomunit_id = m.macroomunit_id;

    -- update order_number for macroomunits
    WITH
        macroomunit AS (
            SELECT
                a2.pgr_node_2 AS catchment_node,
                a.macromapzone_id as macroomunit_id,                
                min(d.seq) AS min_seq
            FROM temp_pgr_drivingdistance d
            JOIN temp_pgr_arc a ON d.node = a.pgr_arc_id
            JOIN temp_pgr_arc a2 ON d.start_vid = a2.pgr_arc_id
            GROUP BY a2.pgr_node_2, a.macromapzone_id 
        ),
        macroomunit_ordered AS (
            SELECT 
                m.macroomunit_id,
                ROW_NUMBER() OVER (
                    PARTITION BY m.catchment_node
                    ORDER BY m.min_seq DESC
                ) AS order_number
            FROM macroomunit m
        )
    UPDATE temp_pgr_macroomunit t
    SET order_number = mo.order_number
    FROM macroomunit_ordered mo
    WHERE t.macroomunit_id = mo.macroomunit_id;

    -- update order_number for omunits
    WITH
        omunit AS (
            SELECT
                a.macromapzone_id AS macroomunit_id,
                a.mapzone_id as omunit_id,
                min(d.seq) AS min_seq
            FROM temp_pgr_drivingdistance d
            JOIN temp_pgr_arc a ON d.node = a.pgr_arc_id
            GROUP BY a.macromapzone_id, a.mapzone_id
        ),
        omunit_ordered AS (
            SELECT 
                o.omunit_id,
                ROW_NUMBER() OVER (
                    PARTITION BY o.macroomunit_id
                    ORDER BY o.min_seq DESC
                ) AS order_number
            FROM omunit o
        )
    UPDATE temp_pgr_omunit t
    SET order_number = oo.order_number
    FROM omunit_ordered oo
    WHERE t.omunit_id = oo.omunit_id;

    -- update geometry of mapzones
    IF v_updatemapzgeom = 0 OR v_updatemapzgeom IS NULL THEN
        -- do nothing

    ELSIF  v_updatemapzgeom = 2 THEN

        -- pipe buffer
        -- update geometry of omunits
        v_query_text = '
            UPDATE temp_pgr_omunit o SET the_geom = ST_Multi(b.geom) 
            FROM (
                SELECT t.mapzone_id AS omunit_id, (ST_Buffer(ST_Collect(v.the_geom),'||v_geomparamupdate||')) AS geom
                FROM temp_pgr_arc t
                JOIN arc v ON v.arc_id = t.pgr_arc_id 
                GROUP BY t.mapzone_id
            ) b 
            WHERE b.omunit_id = o.omunit_id;
        ';
        EXECUTE v_query_text;

        -- update geometry of macroomunits
        v_query_text = '
            UPDATE temp_pgr_macroomunit mo SET the_geom = ST_Multi(b.geom)
            FROM (
                SELECT o.macroomunit_id, ST_Union(o.the_geom) AS geom
                FROM temp_pgr_omunit o
                GROUP BY o.macroomunit_id
            ) b 
            WHERE b.macroomunit_id = mo.macroomunit_id;
        ';
        EXECUTE v_query_text;

    ELSIF  v_updatemapzgeom = 4 THEN

        -- use link and pipe buffer
       -- TODO
    END IF;

    -- Update omunit expl_id, muni_id, sector_id
        UPDATE temp_pgr_omunit o
        SET expl_id = sub.expl_id_arr,
            muni_id = sub.muni_id_arr,
            sector_id = sub.sector_id_arr
        FROM (
            SELECT
                ta.mapzone_id AS omunit_id,
                array_agg(DISTINCT va.expl_id ORDER BY va.expl_id) AS expl_id_arr,
                array_agg(DISTINCT va.muni_id ORDER BY va.muni_id) AS muni_id_arr,
                array_agg(DISTINCT va.sector_id ORDER BY va.sector_id) AS sector_id_arr
            FROM temp_pgr_arc ta
            JOIN arc va ON va.arc_id = ta.pgr_arc_id
            GROUP BY ta.mapzone_id
        ) sub
        WHERE sub.omunit_id = o.omunit_id;

    -- update macroomunits
    UPDATE temp_pgr_macroomunit mo
    SET expl_id = sub.expl_id_arr,
        muni_id = sub.muni_id_arr,
        sector_id = sub.sector_id_arr
    FROM (
        SELECT
            o.macroomunit_id,
            array_agg(DISTINCT e ORDER BY e) AS expl_id_arr,
            array_agg(DISTINCT m ORDER BY m) AS muni_id_arr,
            array_agg(DISTINCT s ORDER BY s) AS sector_id_arr
        FROM temp_pgr_omunit o
        LEFT JOIN LATERAL unnest(o.expl_id) AS e ON TRUE
        LEFT JOIN LATERAL unnest(o.muni_id) AS m ON TRUE
        LEFT JOIN LATERAL unnest(o.sector_id) AS s ON TRUE
        GROUP BY o.macroomunit_id
    ) sub
    WHERE sub.macroomunit_id = mo.macroomunit_id;

    -- END UPDATE SECTION

	-- SECTION[epic=mapzones]: Creating temporal layers
	-- =================================================

    IF v_commitchanges IS FALSE THEN
        -- Polygons
        EXECUTE 'SELECT jsonb_build_object(
                ''type'', ''FeatureCollection'',
                ''features'', COALESCE(jsonb_agg(features.feature), ''[]''::jsonb),
                ''layerName'', ''Temp Omunit''
            )
        FROM (
            SELECT jsonb_build_object(
                ''type'',       ''Feature'',
                ''geometry'',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
                ''properties'', to_jsonb(row) - ''the_geom''
            ) AS feature
            FROM (
                SELECT 
                    o.omunit_id, o.node_1, o.node_2, o.macroomunit_id, o.order_number, o.the_geom,  ''ve_omunit'' AS layer 
                FROM temp_pgr_omunit o
            ) row
        ) features' INTO v_result;

        v_result_polygon_omunit := v_result;

        EXECUTE 'SELECT jsonb_build_object(
                ''type'', ''FeatureCollection'',
                ''features'', COALESCE(jsonb_agg(features.feature), ''[]''::jsonb),
                ''layerName'', ''Temp MacroOmunit''
            )
        FROM (
            SELECT jsonb_build_object(
                ''type'',       ''Feature'',
                ''geometry'',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
                ''properties'', to_jsonb(row) - ''the_geom''
            ) AS feature
            FROM (
                SELECT 
                    mo.macroomunit_id, mo.node_1, mo.node_2, mo.catchment_node, mo.order_number, mo.the_geom,  ''ve_macroomunit'' AS layer 
                FROM temp_pgr_macroomunit mo
            ) row
        ) features' INTO v_result;

        v_result_polygon_macroomunit := v_result;

        v_visible_layer = NULL;

        -- Message
        EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4020", "function":"2706", "fid":"'||v_fid||'", "prefix_id": "1001", "is_process":true}}$$)';

    ELSE 

        SELECT value INTO v_original_disable_fkarray FROM config_param_user
        WHERE parameter = 'edit_disable_arc_fkarray' AND cur_user = current_user;
        UPDATE config_param_user SET value = 'true'
        WHERE parameter = 'edit_disable_arc_fkarray' AND cur_user = current_user;

        -- update TABLES
        -----------------

        -- First, SET omunit_id = 0 when the arcs are not connected to the cluster
        UPDATE arc a SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE a.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_arc ta 
            WHERE ta.pgr_arc_id = a.arc_id
        );

        UPDATE node n SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE n.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_node tn
            WHERE tn.pgr_node_id = n.node_id
        );

        UPDATE connec c SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE c.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_connec tc
            WHERE tc.pgr_connec_id = c.connec_id
        );

        UPDATE link l SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE l.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_connec t
            WHERE t.pgr_connec_id = l.feature_id
        );

        UPDATE gully g SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE g.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_gully tg
            WHERE tg.pgr_gully_id = g.gully_id
        );

        UPDATE link l SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE l.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_gully t
            WHERE t.pgr_gully_id = l.feature_id
        );

        -- SET omunit_id = 0 for the omunits that don't exist anymore
        UPDATE arc a SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE a.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_omunit tpo
            WHERE a.omunit_id = tpo.omunit_id
        );

        UPDATE node n SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE n.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_omunit tpo
            WHERE n.omunit_id = tpo.omunit_id
        );

        UPDATE connec c SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE c.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_omunit tpo
            WHERE c.omunit_id = tpo.omunit_id
        );

        UPDATE gully g SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE g.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_omunit tpo
            WHERE g.omunit_id = tpo.omunit_id
        );

        UPDATE link l SET omunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone m
            WHERE l.omunit_id = m.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_omunit tpo
            WHERE l.omunit_id = tpo.omunit_id
        );

        -- Second, delete the omunits that don't exist anymore;
        DELETE FROM omunit m
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone mo
            WHERE m.omunit_id = mo.mapzone_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_omunit tpo
            WHERE m.omunit_id = tpo.omunit_id
        );

        -- Insert new macroomunits before re-pointing / deleting parents
        -- (omunit_macroomunit_id_fkey is ON DELETE RESTRICT)
        INSERT INTO macroomunit (macroomunit_id)
        SELECT tmm.macroomunit_id
        FROM temp_pgr_macroomunit tmm
        WHERE NOT EXISTS (
            SELECT 1
            FROM macroomunit m
            WHERE tmm.macroomunit_id = m.macroomunit_id
        );

        -- Re-point surviving omunits to their new macroomunit before parent DELETE
        UPDATE omunit o
        SET macroomunit_id = tpo.macroomunit_id
        FROM temp_pgr_omunit tpo
        WHERE tpo.omunit_id = o.omunit_id
        AND o.macroomunit_id IS DISTINCT FROM tpo.macroomunit_id;

        -- Zero omunits still pointing at doomed macroomunits (incl. out-of-scope)
        UPDATE omunit o
        SET macroomunit_id = 0
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone mo
            WHERE mo.macromapzone_id = o.macroomunit_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_macroomunit tmm
            WHERE o.macroomunit_id = tmm.macroomunit_id
        );

        -- Third, delete the macroomunits that don't exist anymore;
        DELETE FROM macroomunit m
        WHERE EXISTS (
            SELECT 1 FROM temp_pgr_old_mapzone mo
            WHERE mo.macromapzone_id = m.macroomunit_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM temp_pgr_macroomunit tmm
            WHERE m.macroomunit_id = tmm.macroomunit_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM omunit o
            WHERE o.macroomunit_id = m.macroomunit_id
        );

        -- Update macroomunits
        UPDATE macroomunit m
        SET node_1 = tmm.node_1,
            node_2 = tmm.node_2,
            catchment_node = tmm.catchment_node,
            order_number = tmm.order_number,
            the_geom = tmm.the_geom,
            expl_id = tmm.expl_id,
            muni_id = tmm.muni_id,
            sector_id = tmm.sector_id
        FROM temp_pgr_macroomunit tmm
        WHERE m.macroomunit_id = tmm.macroomunit_id;

        -- Insert new omunits
        INSERT INTO omunit (omunit_id)
        SELECT tpo.omunit_id
        FROM temp_pgr_omunit tpo
        WHERE NOT EXISTS (
            SELECT 1
            FROM omunit m
            WHERE tpo.omunit_id = m.omunit_id
        );

        -- update omunits
        UPDATE omunit o
        SET node_1 = tpo.node_1,
            node_2 = tpo.node_2,
            order_number = tpo.order_number,
            macroomunit_id = tpo.macroomunit_id,
            the_geom = tpo.the_geom,
            expl_id = tpo.expl_id,
            muni_id = tpo.muni_id,
            sector_id = tpo.sector_id
        FROM temp_pgr_omunit tpo
        WHERE tpo.omunit_id = o.omunit_id;

        -- update arc, node, connec, gully, link
        UPDATE arc a
        SET omunit_id = t.mapzone_id
        FROM temp_pgr_arc t
        WHERE a.arc_id = t.pgr_arc_id
        AND a.omunit_id IS DISTINCT FROM t.mapzone_id;

        UPDATE node n 
        SET omunit_id = t.mapzone_id
        FROM temp_pgr_node t
        WHERE n.node_id = t.pgr_node_id
        AND n.omunit_id IS DISTINCT FROM t.mapzone_id;

        UPDATE connec c
        SET omunit_id = t.mapzone_id
        FROM temp_pgr_connec t
        WHERE c.connec_id = t.pgr_connec_id
        AND c.omunit_id IS DISTINCT FROM t.mapzone_id;

        UPDATE link l
        SET omunit_id = t.mapzone_id
        FROM temp_pgr_connec t
        WHERE l.feature_id = t.pgr_connec_id 
        AND l.omunit_id IS DISTINCT FROM t.mapzone_id;

        UPDATE gully g
        SET omunit_id = t.mapzone_id
        FROM temp_pgr_gully t
        WHERE g.gully_id = t.pgr_gully_id
        AND g.omunit_id IS DISTINCT FROM t.mapzone_id;

        UPDATE link l
        SET omunit_id = t.mapzone_id
        FROM temp_pgr_gully t
        WHERE l.feature_id = t.pgr_gully_id 
        AND l.omunit_id IS DISTINCT FROM t.mapzone_id;

        v_visible_layer = 've_omunit';
    END IF;

    -- ENDSECTION UPDATE

    -- Get Info for the audit
	SELECT json_agg(row_to_json(t)) INTO v_result
	FROM (
		SELECT id, error_message AS message
		FROM temp_audit_check_data
		WHERE cur_user = current_user AND fid = v_fid
		ORDER BY criticity DESC, id ASC
	) t;
	v_result := COALESCE(v_result, '{}');
	v_result_info := concat ('{"values":',v_result, '}');

    -- Control nulls
    v_result_polygon_omunit := COALESCE(v_result_polygon_omunit, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'Temp Omunit',
		'features', '[]'::jsonb
	)::json);
    v_result_polygon_macroomunit := COALESCE(v_result_polygon_macroomunit, jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'Temp MacroOmunit',
		'features', '[]'::jsonb
	)::json);

    v_result_info := COALESCE(v_result_info, '{}');

    v_status := COALESCE(v_status, 'Accepted');
    v_level := COALESCE(v_level, 3);
    v_message := COALESCE(v_message, 'Omunit dynamic analysis done successfully');
    v_version := COALESCE(v_version, '');

    v_result_polygon := jsonb_build_array(
		v_result_polygon_omunit,
		v_result_polygon_macroomunit
	)::json;

	-- Restore original disable lock level
    UPDATE config_param_user SET value = v_original_disable_locklevel WHERE parameter = 'edit_disable_locklevel' AND cur_user = current_user;

    IF v_commitchanges THEN
        UPDATE config_param_user SET value = COALESCE(v_original_disable_fkarray, 'false')
        WHERE parameter = 'edit_disable_arc_fkarray' AND cur_user = current_user;
    END IF;

    -- Return
    	v_result := gw_fct_json_create_return(('{
		"status":"'||v_status||'",
		"message":{
			"level":'||v_level||',
			"text":"'||v_message||'"
		},
		"version":"'||v_version||'",
		"body":{
			"form":{},
			"data":{
				"polygon":'||v_result_polygon||'
			}
		}
	}')::json, 3492, null, ('{"visible": ["'||v_visible_layer||'"]}')::json, null)::json;

    RETURN v_result;

	EXCEPTION WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
		RETURN json_build_object(
		'status', 'Failed',
		'NOSQLERRM', SQLERRM,
		'message', json_build_object(
			'level', right(SQLSTATE, 1),
			'text', SQLERRM
		),
		'SQLSTATE', SQLSTATE,
		'SQLCONTEXT', v_error_context
	);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2832

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_getprofilevalues(p_data json)
RETURNS json AS
$BODY$

/*example
current petition from client:
SELECT SCHEMA_NAME.gw_fct_getprofilevalues($${"data":{"initNode":"6970", "endNode":"147", "linksDistance":5}}$$);
SELECT SCHEMA_NAME.gw_fct_getprofilevalues($${"data":{"initNode":"6970", "endNode":"147", "linksDistance":5}}$$);

SELECT SCHEMA_NAME.gw_fct_getprofilevalues($${"client":{}, "form":{}, "feature":{}, "data":{"initNode":"64", "endNode":"38", "linksDistance":1, "scale":{ "eh":1000, "ev":1000}}}$$);

-----------
further petitions from client:
SELECT SCHEMA_NAME.gw_fct_getprofilevalues($${"client":{},
	"data":{"initNode":"116", "endNode":"111", "composer":"mincutA4", "legendFactor":1, "linksDistance":1, "scale":{"scaleToFit":false, "eh":2000, "ev":500}, "papersize":{"id":0, "customDim":{"xdim":300, "ydim":200}},
		"ComposerTemplates":[{"ComposerTemplate":"mincutA4", "ComposerMap":[{"width":"179.0","height":"140.826","index":0, "name":"map0"},{"width":"77.729","height":"55.9066","index":1, "name":"map7"}]},
				     {"ComposerTemplate":"mincutA3","ComposerMap":[{"width":"53.44","height":"55.9066","index":0, "name":"map7"},{"width":"337.865","height":"275.914","index":1, "name":"map6"}]}]
				     }}$$);

SELECT SCHEMA_NAME.gw_fct_getprofilevalues($${"client":{},
	"data":{"initNode":"116", "endNode":"111", "composer":"mincutA4", "legendFactor":1, "linksDistance":1, "scale":{"scaleToFit":false, "eh":2000, "ev":500},"papersize":{"id":2, "customDim":{}},
		"ComposerTemplates":[{"ComposerTemplate":"mincutA4", "ComposerMap":[{"width":"179.0","height":"140.826","index":0, "name":"map0"},{"width":"77.729","height":"55.9066","index":1, "name":"map7"}]},
				     {"ComposerTemplate":"mincutA3","ComposerMap":[{"width":"53.44","height":"55.9066","index":0, "name":"map7"},{"width":"337.865","height":"275.914","index":1, "name":"map6"}]}]
				     }}$$);

 SELECT gw_fct_getprofilevalues($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "initNode":"64", "endNode":"38", "linksDistance":, "scale":{ "eh":1000, "ev":1000}}}$$);


-- fid: 222

Mains:
- 3 types of nodes
	- TOP: Normal case, dimensions provided and node has representation on surface
	- BOTTOM: Node has not representation on surface (node_type WHERE isprofilesurface IS FALSE)
	- VNODES: vnodes, to represent only terrain
- 2 types of data
	- REAL: Data is fullfilled on nodes (sys_top_elev, sys_elev, sys_ymax)
	- INTERPOLATED: When data is missed in some intermediate node, values are interpolated. Vnodes are automatic disabled

- profile works with user-friendly variables
	- Vnode min distance: Value to prevent on guitar when text is overlaped with another text

Is mandatory start-end nodes must have data, and must be profile_surface = true

*/

DECLARE

	v_init  integer;
	v_mid text;
	v_end text;
	v_nodes integer[];
	v_hs float;
	v_vs float;
	v_arc json;
	v_node json;
	v_terrain json;
	v_stylesheet json;
	v_version text;
	v_status text = 'Accepted';
	v_level integer = 3;
	v_message text = 'Profile done successfully';
	v_guitarlegend json;
	v_textarc text;
	v_textnode text;
	v_vdefault json;
	v_composer text;
	v_templates json;
	v_json json;
	v_project_type text;
	v_index integer;
	v_mapcomposer_name text;
	v_scaletofit boolean;
	v_array_width float[];
	v_scale text;
	v_extension json;
	v_vstext text;
	v_hstext text;
	v_legendfactor float;
	v_linksdistance float;
	v_arc_geom1 float;
	v_node_geom1 float;
	i integer = 0;
	v_dist numeric[];
	v_telev numeric[];
	v_elev numeric[];
	v_nid integer[];
	v_elevation float;
	v_distance float;
	v_compheight float;
	v_compwidth float;
	v_profheigtht float;
	v_profwidth float;
	v_error_context text;
	v_initv float;
	v_inith float;
	v_initpoint json;
	v_fid integer = 222;


	-- field variables to work with UD/WS
	-- temp_anl_arc
	v_cat_geom1 text;
	v_slope text;
	v_elev1 text;
	v_elev2 text;
	v_node_top_elev1 text;
	v_node_top_elev2 text;
	v_z1 text;
	v_z2 text;
	v_y1 text;
	v_y2 text;
	v_omunit_id text;
	--temp_anl_node
	v_ymax text;
	v_node_elev text;

	v_querytext text;
	v_papersize integer;
	v_count integer;
	object_rec record;
	v_vnode_status boolean;
	v_result json;
	v_result_line json;
	v_result_point json;
	v_result_polygon json;
	v_device integer;
	v_nonpriority_statetype text;
	v_cost_string text;
	v_last_dist float;
	v_last_nid integer;
	v_last_systype text;

	v_disconnected integer[];

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get projectytpe
	SELECT project_type, giswater FROM sys_version ORDER BY id DESC LIMIT 1 INTO v_project_type, v_version;

	--  Get input data
	v_init = (p_data->>'data')::json->>'initNode';
	v_mid = (p_data->>'data')::json->>'midFeatures';
	v_end = (p_data->>'data')::json->>'endNode';
	v_hs = ((p_data->>'data')::json->>'scale')::json->>'eh';
	v_vs = ((p_data->>'data')::json->>'scale')::json->>'ev';
	v_scaletofit := ((p_data->>'data')::json->>'scale')::json->>'scaleToFit';
	v_legendfactor = (p_data->>'data')::json->>'legendFactor';
	v_linksdistance = (p_data->>'data')::json->>'linksDistance';
	v_composer := (p_data ->> 'data')::json->> 'composer';
	v_templates := (p_data ->> 'data')::json->> 'ComposerTemplates';
	v_papersize := ((p_data ->> 'data')::json->> 'papersize')::json->>'id';
	v_device := (p_data ->> 'client')::json->> 'device';

	-- get systemvalues
	SELECT value INTO v_guitarlegend FROM config_param_system WHERE parameter = 'om_profile_guitarlegend';
	SELECT value INTO v_stylesheet FROM config_param_user WHERE parameter = 'om_profile_stylesheet' AND cur_user = current_user;
	SELECT value::json->>'arc' INTO v_textarc FROM config_param_system WHERE parameter = 'om_profile_guitartext';
	SELECT value::json->>'node' INTO v_textnode FROM config_param_system WHERE parameter = 'om_profile_guitartext';
	SELECT value INTO v_vdefault FROM config_param_system WHERE parameter = 'om_profile_vdefault';
	SELECT value::json->>'vs' INTO v_vstext FROM config_param_system WHERE parameter = 'om_profile_guitarlegend';
  	SELECT value::json->>'hs' INTO v_hstext FROM config_param_system WHERE parameter = 'om_profile_guitarlegend';
  	SELECT (value::json->>'arc')::json->>'cat_geom1' INTO v_arc_geom1 FROM config_param_system WHERE parameter = 'om_profile_vdefault';
  	SELECT (value::json->>'node')::json->>'cat_geom1' INTO v_node_geom1 FROM config_param_system WHERE parameter = 'om_profile_vdefault';
  	SELECT (value::json->>'vnodeStatus') INTO v_vnode_status FROM config_param_system WHERE parameter = 'om_profile_vdefault';

	-- drop temporary tables
	DROP TABLE IF EXISTS temp_anl_arc;
	DROP TABLE IF EXISTS temp_anl_node;
	DROP TABLE IF EXISTS temp_vnode;
	DROP TABLE IF EXISTS temp_link;
	DROP TABLE IF EXISTS temp_pgr_dijkstra;

	CREATE TEMP TABLE temp_vnode (
		id serial NOT NULL,
		l1 integer,
		v1 integer,
		l2 integer,
		v2 integer,
		CONSTRAINT temp_vnode_pkey PRIMARY KEY (id)
	);

	CREATE TEMP TABLE temp_link(
		link_id integer NOT NULL,
		vnode_id integer,
		vnode_type text,
		feature_id integer,
		feature_type character varying(16),
		exit_id integer,
		exit_type character varying(16),
		state smallint,
		expl_id integer,
		sector_id integer,
		omzone_id integer,
		exit_topelev double precision,
		exit_elev double precision,
		the_geom geometry(LineString,SRID_VALUE),
		the_geom_endpoint geometry(Point,SRID_VALUE),
		flag boolean,
		CONSTRAINT temp_link_pkey PRIMARY KEY (link_id)
	);
	CREATE INDEX IF NOT EXISTS temp_link_exit_id_idx ON temp_link USING btree (exit_id);
	CREATE INDEX IF NOT EXISTS  temp_link_index ON temp_link USING gist (the_geom_endpoint);

	IF v_project_type = 'WS' THEN
		ALTER TABLE temp_link ADD COLUMN dma_id integer;
		ALTER TABLE temp_link ADD COLUMN supplyzone_id integer;
	END IF;

	CREATE TEMP TABLE temp_pgr_dijkstra(
		seq INTEGER NOT NULL,
		path_id INTEGER NOT NULL,
		path_seq INTEGER NOT NULL,
		start_vid INTEGER NULL,
		end_vid INTEGER NULL,
		node INTEGER NULL,
		edge INTEGER NULL,
		"cost" FLOAT8 NULL,
		agg_cost FLOAT8 NULL,
		route_agg_cost FLOAT8 NULL,
		CONSTRAINT temp_pgr_dijkstra_pkey PRIMARY KEY (seq)
	);
	CREATE INDEX IF NOT EXISTS temp_pgr_dijkstra_node_idx ON temp_pgr_dijkstra USING btree (node);
	CREATE INDEX IF NOT EXISTS temp_pgr_dijkstra_edge_idx ON temp_pgr_dijkstra USING btree (edge);

	CREATE TEMP TABLE temp_anl_arc (
		id serial PRIMARY KEY,
		arc_id integer,
		code text,
		reversed boolean,
		node_1 integer,
		node_2 integer,
		sys_type text,
		arccat_id text,
		cat_geom1 numeric(12,4),
		length numeric(12,3),
		total_length numeric(12,3),
		slope numeric(12,4),
		z1 numeric(12,3),
		z2 numeric(12,3),
		y1 numeric(12,3),
		y2 numeric(12,3),
		elev1 numeric(12,3),
		elev2 numeric(12,3),
		top_elev1 numeric(12,3),
		top_elev2 numeric(12,3),
		expl_id integer,
		omunit_id integer,
		the_geom geometry(LineString, SRID_VALUE),
		descript text
	);
	CREATE INDEX IF NOT EXISTS temp_anl_arc_arc_id ON temp_anl_arc USING btree (arc_id);
	CREATE INDEX IF NOT EXISTS temp_anl_arc_node_1 ON temp_anl_arc USING btree (node_1);
	CREATE INDEX IF NOT EXISTS temp_anl_arc_node_2 ON temp_anl_arc USING btree (node_2);

	CREATE TEMP TABLE temp_anl_node (
		id serial PRIMARY KEY,
		node_id integer,
		code text,
		sys_type text,
		nodecat_id text,
		top_elev numeric(12,3),
		ymax numeric(12,3),
		elev numeric(12,3),
		cat_geom1 numeric(12,4),
		arc_id integer,
		arc_distance numeric(12,3),
		total_distance numeric(12,3),
		expl_id integer,
		the_geom geometry(Point, SRID_VALUE),
		descript text,
		result_id text
	);
	CREATE INDEX IF NOT EXISTS temp_anl_node_arc_id ON temp_anl_node USING btree (arc_id);
	CREATE INDEX IF NOT EXISTS temp_anl_node_index ON temp_anl_node USING gist (the_geom);
	CREATE INDEX IF NOT EXISTS temp_anl_node_node_id_index ON temp_anl_node USING btree (node_id);


	-- set value to v_linksdistance if null
	IF v_linksdistance IS NULL OR v_linksdistance < 0 THEN
		v_linksdistance = 0;
	END IF;

	SELECT json_extract_path_text(value::json,'state_type') INTO v_nonpriority_statetype
	FROM config_param_system WHERE parameter = 'om_profile_nonpriority_statetype';

	IF v_nonpriority_statetype IS NULL or v_nonpriority_statetype='' THEN
		 v_cost_string = 'gis_length::float/2 ';
	ELSE
		v_cost_string := format(
			'CASE WHEN state_type = %s THEN -1 ELSE gis_length::float/2 END',
			v_nonpriority_statetype::integer
		);
	END IF;

	-- Check start-end nodes
	IF v_project_type = 'UD' THEN
		IF (SELECT COUNT(*) FROM ve_node JOIN cat_feature_node ON node_type = id
			WHERE sys_elev IS NOT NULL AND sys_top_elev IS NOT NULL AND sys_ymax IS NOT NULL AND node_id = v_init) < 1
		THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
		    "data":{"message":"4466", "function":"2832", "parameters":{}, "fid":'||v_fid||', "criticity":"2",  "is_process":true}}$$)';
		END IF;
	END IF;

	IF v_level = 3 THEN

		v_nodes := ARRAY [v_init] || (SELECT array_agg(value::integer) FROM json_array_elements_text(v_mid::json)) || ARRAY [v_end::integer];

		SELECT COALESCE(array_agg(q.nid), '{}')
		INTO v_disconnected
		FROM (
			WITH via AS (
				SELECT unnest(v_nodes) AS nid
			)
			SELECT v.nid
			FROM via v
			WHERE NOT EXISTS (
				SELECT 1 
				FROM vf_node n 
				WHERE n.node_id = v.nid
			)
			AND NOT EXISTS (
				SELECT 1 
				FROM vf_arc a 
				WHERE v.nid = a.arc_id
			)
		) q;

		IF cardinality(v_disconnected) > 0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4528", "function":"2832","parameters":{"v_disconnected":"'||array_to_string(v_disconnected, ',')||'"}, "is_process":true}}$$);';
		END IF;

		v_querytext := format($sql$
			SELECT
				a.arc_id * 2 AS id,
				a.node_1 AS source,
				a.arc_id AS target,
				(%s) AS cost
			FROM ve_arc a
			WHERE a.node_1 IS NOT NULL AND a.node_2 IS NOT NULL
			UNION ALL
			SELECT
				a.arc_id * 2 + 1 AS id,
				a.node_2 AS source,
				a.arc_id AS target,
				(%s) AS cost
			FROM ve_arc a
			WHERE a.node_1 IS NOT NULL AND a.node_2 IS NOT NULL
		$sql$, v_cost_string, v_cost_string);

		INSERT INTO temp_pgr_dijkstra (seq, path_id, path_seq, start_vid, end_vid, node, edge, cost, agg_cost, route_agg_cost)
		SELECT seq, path_id, path_seq, start_vid, end_vid, node, edge, cost, agg_cost, route_agg_cost
		FROM pgr_dijkstraVia (v_querytext, v_nodes, directed => FALSE, strict => TRUE, U_turn_on_edge => FALSE);

		-- insert nodes-arc on temp_anl_arc table
		-- filter edge = -1 marks intermediate nodes in dijkstra table
		IF v_project_type = 'UD' THEN
			v_cat_geom1 := 'a.cat_geom1';
			v_slope := 'a.slope';
			v_z1 := 'a.z1';
			v_z2 := 'a.z2';
			v_y1 := 'a.sys_y1';
			v_y2 := 'a.sys_y2';
			v_elev1 := 'a.sys_elev1';
			v_elev2 := 'a.sys_elev2';
			v_node_top_elev1 := 'a.node_sys_top_elev_1';
			v_node_top_elev2 := 'a.node_sys_top_elev_2';
			v_omunit_id := 'a.omunit_id';

		ELSIF v_project_type = 'WS' THEN
			v_cat_geom1 := 'a.cat_dnom::float * 0.001';
			v_slope := '((a.elevation1 - a.depth1) - (a.elevation2 - a.depth2))/a.gis_length';
			v_z1 := '0';
			v_z2 := '0';
			v_y1 := 'a.depth1';
			v_y2 := 'a.depth2';
			v_elev1 := 'a.elevation1 - a.depth1';
			v_elev2 := 'a.elevation2 - a.depth2';
			v_node_top_elev1 := 'a.elevation1';
			v_node_top_elev2 := 'a.elevation2';
			v_omunit_id := 'NULL';

		END IF;

		EXECUTE format($sql$
			WITH dijkstra AS (
				SELECT
					seq,
					node,
					LAG(node) OVER (ORDER BY seq) AS pred,
					cost,
					route_agg_cost
				FROM temp_pgr_dijkstra
				WHERE edge <> -1
			)
			INSERT INTO temp_anl_arc (
				reversed,
				arc_id,
				code,
				node_1,
				node_2,
				sys_type,
				arccat_id,
				length,
				expl_id,
				the_geom,
				total_length,
				cat_geom1,
				slope,
				z1,
				z2,
				y1,
				y2,
				elev1,
				elev2,
				top_elev1,
				top_elev2,
				omunit_id
			)
			SELECT
				CASE WHEN d.pred = a.node_1 THEN false ELSE true END AS reversed,
				a.arc_id,
				COALESCE(a.code, a.arc_id::text) AS code,
				a.node_1,
				a.node_2,
				a.sys_type,
				a.arccat_id,
				a.gis_length AS length,
				a.expl_id,
				a.the_geom,
				d.cost + d.route_agg_cost AS total_length,
				%s AS cat_geom1,
				%s AS slope,
				%s AS z1,
				%s AS z2,
				%s AS y1,
				%s AS y2,
				%s AS elev1,
				%s AS elev2,
				%s AS top_elev1,
				%s AS top_elev2,
				%s AS omunit_id
			FROM dijkstra d
			JOIN ve_arc a ON d.node = a.arc_id;
		$sql$,
			v_cat_geom1,
			v_slope,
			v_z1,
			v_z2,
			v_y1,
			v_y2,
			v_elev1,
			v_elev2,
			v_node_top_elev1,
			v_node_top_elev2,
			v_omunit_id
		);

		-- orient arcs according to the profile path direction
		UPDATE temp_anl_arc SET
			node_1 = node_2,       node_2 = node_1,
			z1 = z2,               z2 = z1,
			y1 = y2,               y2 = y1,
			elev1 = elev2,         elev2 = elev1,
			top_elev1 = top_elev2, top_elev2 = top_elev1,
			slope = -slope
		WHERE reversed;

		-- insert nodes-node on temp_anl_node table
		IF v_project_type = 'UD' THEN
			v_ymax := 'COALESCE(n.custom_top_elev, n.top_elev) - COALESCE(n.custom_elev, n.elev)';
			v_node_elev := 'COALESCE(n.custom_elev, n.elev) ';

		ELSIF v_project_type = 'WS' THEN
			v_ymax := 'n.depth';
			v_node_elev := 'COALESCE(n.custom_top_elev, n.top_elev) - n.depth';

		END IF;

		-- filter edge = -1 marks intermediate nodes in dijkstra table
		EXECUTE format($sql$
			INSERT INTO temp_anl_node (
				node_id,
				code,
				sys_type,
				nodecat_id,
				top_elev,
				ymax,
				elev,
				arc_id,
				arc_distance,
				total_distance,
				expl_id,
				the_geom
			)
			SELECT
				n.node_id,
				COALESCE(n.code, n.node_id::varchar),
				cat_feature.feature_class,
				n.nodecat_id,
				COALESCE(n.custom_top_elev, n.top_elev) AS top_elev,
				%s AS ymax,
				%s AS elev,
				n.arc_id,
				0 AS arc_distance,
				d.route_agg_cost AS total_distance,
				n.expl_id,
				n.the_geom
			FROM temp_pgr_dijkstra d
			JOIN node n ON d.node = n.node_id
			JOIN vf_node vfn ON vfn.node_id = n.node_id
			JOIN cat_node ON cat_node.id::text = n.nodecat_id::text
     		JOIN cat_feature ON cat_feature.id::text = cat_node.node_type::text
			WHERE d.edge <> -1
			ORDER BY d.seq;
		$sql$,
			v_ymax,
			v_node_elev
		);

		-- looking for null values (in case of exists links graph will be disabled as below)
		SELECT count(*) INTO v_count FROM temp_anl_node WHERE top_elev IS NULL OR elev IS NULL;

		IF v_linksdistance > 0 AND v_count = 0 and v_vnode_status IS NOT False THEN

			-- generate temp link table
			PERFORM gw_fct_linkexitgenerator(2);

			-- get vnode-connec/gully values
			INSERT INTO temp_anl_node (
				node_id,
				sys_type,
				top_elev,
				ymax,
				elev,
				arc_id,
				arc_distance,
				total_distance
			)
			SELECT
				a.link_id,
				'LINK' AS sys_type,
				COALESCE(
					a.exit_topelev,
					(a.top_elev1 - a.locate * (a.top_elev1 - a.top_elev2))::numeric(12,3)
				) AS top_elev,
				COALESCE(
					a.exit_topelev,
					(a.top_elev1 - a.locate * (a.top_elev1 - a.top_elev2))::numeric(12,3)
				)
				- COALESCE(
					a.exit_elev,
					(a.elev1 - a.locate * (a.elev1 - a.elev2))::numeric(12,3)
				) AS ymax,
				COALESCE(
					a.exit_elev,
					(a.elev1 - a.locate * (a.elev1 - a.elev2))::numeric(12,3)
				) AS elev,
				a.arc_id,
				(a.length * a.locate)::numeric(12,3) AS arc_distance,
				(a.total_length - a.length + a.length * a.locate)::numeric(12,3) AS total_distance
			FROM (
				SELECT
					l.link_id,
					l.exit_topelev,
					l.exit_elev,
					CASE
						WHEN ta.reversed = FALSE
						THEN ST_LineLocatePoint(ta.the_geom, l.the_geom_endpoint)
						ELSE 1 - ST_LineLocatePoint(ta.the_geom, l.the_geom_endpoint)
					END::numeric(12,3) AS locate,
					ta.total_length,
					ta.length,
					ta.elev1,
					ta.elev2,
					ta.top_elev1,
					ta.top_elev2,
					ta.arc_id
				FROM temp_link l
				JOIN temp_anl_arc ta ON ta.arc_id = l.exit_id
				WHERE l.link_id = l.vnode_id
			) a;

			-- delete links overlaped with nodes using the user's parameter
			-- initNode
			SELECT node_id FROM temp_anl_node WHERE total_distance = 0 INTO v_last_nid;
			SELECT sys_type FROM temp_anl_node WHERE total_distance = 0 INTO v_last_systype;
			v_last_dist := 0;

			-- start with the second node_id from temp_anl_node
			FOR object_rec IN
				SELECT node_id, sys_type, total_distance
				FROM temp_anl_node
				WHERE total_distance > 0
				ORDER BY total_distance
			LOOP
				IF object_rec.sys_type = 'LINK' THEN
					IF object_rec.total_distance < (v_last_dist + v_linksdistance) THEN
						DELETE FROM temp_anl_node WHERE node_id = object_rec.node_id;
					ELSE
						v_last_nid := object_rec.node_id;
						v_last_systype:= object_rec.sys_type;
						v_last_dist := object_rec.total_distance;
					END IF;
				ELSE -- object_rec.node_id - NODE REAL
					IF v_last_systype = 'LINK' AND v_last_dist > (object_rec.total_distance - v_linksdistance) THEN
						DELETE FROM temp_anl_node WHERE node_id = v_last_nid;
					END IF;
					v_last_nid := object_rec.node_id;
					v_last_systype:= object_rec.sys_type;
					v_last_dist := object_rec.total_distance;
				END IF;
			END LOOP;

		ELSIF v_linksdistance > 0 AND v_count > 0 THEN
			v_level = 3;
			v_message = 'Profile done, but during the execution vnode information have been disabled because only is possible to interpolate missed data on intermediate nodes, but not vnodes.';
		END IF;

		-- update descript field
		EXECUTE format(
			'
			UPDATE temp_anl_arc t
			SET
				descript = a.descript
			FROM (
				SELECT
					arc_id,
					row_to_json(r) AS descript
				FROM (%s) r
			) a
			WHERE a.arc_id = t.arc_id
			',
			v_textarc
		);

		UPDATE temp_anl_node t
		SET descript = a.descript
		FROM (
			SELECT
				id,
				row_to_json(r)::text AS descript
			FROM (
				SELECT
					id,
					top_elev::float8 AS top_elev,
					ymax::float8 AS ymax,
					elev::float8 AS elev,
					COALESCE(code, node_id::text) AS code,
					total_distance
				FROM temp_anl_node
			) r
		) a
		WHERE a.id = t.id;

		EXECUTE format(
			'
			UPDATE temp_anl_node t
			SET descript = gw_fct_json_object_set_key(descript::json, ''code'', a.code)
			FROM (
				SELECT
					node_id,
					COALESCE(code, node_id::varchar) AS code
				FROM (%s) r
			) a
			WHERE a.node_id = t.node_id
			',
			v_textnode
		);

		-- delete not used keys
		UPDATE temp_anl_arc SET descript = gw_fct_json_object_delete_keys(descript::json, 'arc_id');
		UPDATE temp_anl_node SET descript = gw_fct_json_object_delete_keys(descript::json, 'id');

		-- update node table setting default values
		UPDATE temp_anl_arc SET cat_geom1 = v_arc_geom1 WHERE cat_geom1 IS NULL ;
		UPDATE temp_anl_node SET cat_geom1 = v_node_geom1 WHERE cat_geom1 IS NULL AND sys_type !='LINK';

		-- update node table when node has not values and need to be interpolated
		SELECT
			array_agg(total_distance ORDER BY total_distance, id),
			array_agg(top_elev ORDER BY total_distance, id),
			array_agg(elev ORDER BY total_distance, id),
			array_agg(node_id ORDER BY total_distance, id)
		INTO v_dist, v_telev, v_elev, v_nid
		FROM temp_anl_node;

		i = 0;
		LOOP
			i = i+1;
			EXIT WHEN v_nid[i] IS NULL;

			--topelev values
			IF v_telev[i] IS NULL THEN
				IF v_telev[i+1] IS NOT NULL AND v_telev[i-1] IS NOT NULL THEN
					UPDATE temp_anl_node SET top_elev = (v_telev[i-1] + ((v_dist[i]-v_dist[i-1])*(v_telev[i+1]-v_telev[i-1])/(v_dist[i+1]-v_dist[i-1])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSIF v_telev[i+1] IS NOT NULL AND v_telev[i-2] IS NOT NULL THEN
					UPDATE temp_anl_node SET top_elev = (v_telev[i-2] + ((v_dist[i]-v_dist[i-2])*(v_telev[i+1]-v_telev[i-2])/(v_dist[i+1]-v_dist[i-2])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSIF v_telev[i+2] IS NOT NULL AND v_telev[i-1] IS NOT NULL THEN
					UPDATE temp_anl_node SET top_elev = (v_telev[i-1] + ((v_dist[i]-v_dist[i-1])*(v_telev[i+2]-v_telev[i-1])/(v_dist[i+2]-v_dist[i-1])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSIF v_telev[i+2] IS NOT NULL AND v_telev[i-2] IS NOT NULL THEN
					UPDATE temp_anl_node SET top_elev = (v_telev[i-2] + ((v_dist[i]-v_dist[i-2])*(v_telev[i+2]-v_telev[i-2])/(v_dist[i+2]-v_dist[i-2])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSE
					v_level  = 2;
					v_message = 'Interpolation tool it is designed to interpolate with data missed maximun at two consecutives nodes. Please check your data!';
					v_status = 'Failed';
				END IF;

				UPDATE temp_anl_node SET result_id = 'interpolated', descript = gw_fct_json_object_set_key(descript::json, 'top_elev', 'None'::text)
				WHERE node_id = v_nid[i];
			END IF;

			--elev values
			IF v_elev[i] IS NULL THEN
				IF v_elev[i+1] IS NOT NULL AND v_elev[i-1] IS NOT NULL THEN
					UPDATE temp_anl_node SET elev = (v_elev[i-1]+ ((v_dist[i]-v_dist[i-1])*(v_elev[i+1]-v_elev[i-1])/(v_dist[i+1]-v_dist[i-1])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSIF v_elev[i+1] IS NOT NULL AND v_elev[i-2] IS NOT NULL THEN
					UPDATE temp_anl_node SET elev = (v_elev[i-2]+ ((v_dist[i]-v_dist[i-2])*(v_elev[i+1]-v_elev[i-2])/(v_dist[i+1]-v_dist[i-2])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSIF v_elev[i+2] IS NOT NULL AND v_elev[i-1] IS NOT NULL THEN
					UPDATE temp_anl_node SET elev = (v_elev[i-1]+ ((v_dist[i]-v_dist[i-1])*(v_elev[i+2]-v_elev[i-1])/(v_dist[i+2]-v_dist[i-1])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSIF v_elev[i+2] IS NOT NULL AND v_elev[i-2] IS NOT NULL THEN
					UPDATE temp_anl_node SET elev = (v_elev[i-2]+ ((v_dist[i]-v_dist[i-2])*(v_elev[i+2]-v_elev[i-2])/(v_dist[i+2]-v_dist[i-2])))::numeric(12,3) WHERE node_id = v_nid[i];
				ELSE
					v_level  = 2;
					v_message = 'Interpolation tool it is designed to interpolate with data missed maximun at two consecutives nodes. Please check your data!';
					v_status = 'Failed';
				END IF;

				UPDATE temp_anl_node SET  result_id = 'interpolated', descript = gw_fct_json_object_set_key(descript::json, 'elev', 'None'::text)
				WHERE node_id = v_nid[i];
			END IF;

			UPDATE 	temp_anl_node SET nodecat_id = 'VNODE' WHERE node_id = v_nid[i] AND nodecat_id IS NULL;
		END LOOP;

		-- update node table those ymax nulls
		UPDATE temp_anl_node SET
			descript = gw_fct_json_object_set_key(descript::json, 'ymax', 'None'::text)::text,
			ymax = top_elev - elev
		WHERE ymax IS NULL;

		-- update node catalog
		UPDATE temp_anl_node SET nodecat_id = 'BOTTOM' FROM cat_feature_node n JOIN cat_feature cf ON cf.id = n.id WHERE cf.feature_class = sys_type
		AND isprofilesurface IS FALSE AND nodecat_id !='VNODE';
		UPDATE temp_anl_node SET nodecat_id = 'TOP' WHERE nodecat_id NOT IN ('BOTTOM', 'VNODE') ;

		-- update node type
		UPDATE temp_anl_node SET sys_type = 'REAL' WHERE sys_type NOT IN ('LINK') ;
		UPDATE temp_anl_node SET sys_type = 'INTERPOLATED' WHERE result_id = 'interpolated';

		-- update arc type
		UPDATE temp_anl_arc SET sys_type = 'SLOPE-REAL'
		WHERE slope IS NOT NULL;

		UPDATE temp_anl_arc SET
			z1 = COALESCE(z1, 0),
			z2 = COALESCE(z2, 0),
			sys_type = 'SLOPE-ESTIMATED'
		WHERE slope IS NULL;

		-- update arc table with estimated values of the interpolated nodes
		UPDATE temp_anl_arc a SET
			elev1 = COALESCE(a.elev1, n.elev + a.z1),
			top_elev1 = COALESCE(a.top_elev1, n.top_elev)
		FROM temp_anl_node n
		WHERE n.node_id = a.node_1
		AND a.sys_type = 'SLOPE-ESTIMATED';
		
		UPDATE temp_anl_arc a SET
			elev2 = COALESCE(a.elev2, n.elev + a.z2),
			top_elev2 = COALESCE(a.top_elev2, n.top_elev)
		FROM temp_anl_node n
		WHERE n.node_id = a.node_2
		AND a.sys_type = 'SLOPE-ESTIMATED';

		-- recalculate depths and slope on estimated arcs
		UPDATE temp_anl_arc SET
			y1 = top_elev1 - elev1,
			y2 = top_elev2 - elev2,
			slope = (elev1 - elev2)/length
		WHERE sys_type = 'SLOPE-ESTIMATED';

		-- get profile dimensions
		EXECUTE 'SELECT max(top_elev)-min(elev) FROM temp_anl_node '
		INTO v_elevation;
		v_distance = (SELECT max(total_distance) FROM temp_anl_node);

		-- get leaflet dimensions
		v_profheigtht = 1000*v_elevation/v_vs + v_legendfactor*50 + 10;
		v_profwidth = 1000*v_distance/v_hs + v_legendfactor*20 + 10; -- profile + guitar + margin


		-- get portrait extension
		IF v_composer !='' THEN
			SELECT * INTO v_json FROM json_array_elements(v_templates) AS a WHERE a->>'ComposerTemplate' = v_composer;

			-- select map with maximum width
			SELECT array_agg(a->>'width') INTO v_array_width FROM json_array_elements( v_json ->'ComposerMap') AS a;
			SELECT max (a) INTO v_compwidth FROM unnest(v_array_width) AS a;
			SELECT a->>'name' INTO v_mapcomposer_name FROM json_array_elements( v_json ->'ComposerMap') AS a WHERE (a->>'width')::float = v_compwidth::float;
			SELECT a->>'height' INTO v_compheight FROM json_array_elements( v_json ->'ComposerMap') AS a WHERE a->>'name' = v_mapcomposer_name;
			SELECT a->>'index' INTO v_index FROM json_array_elements( v_json ->'ComposerMap') AS a WHERE a->>'name' = v_mapcomposer_name;

			IF v_scaletofit IS FALSE THEN
				IF v_compheight < v_profheigtht THEN
					v_level = 2;
					v_message = 'Profile too large. You need to modify the vertical scale or change the composer';
					RETURN (concat('{"status":"Failed", "message":{"level":',v_level,', "text":"',v_message,'"}}')::json);
				END IF;
				IF v_compwidth < v_profwidth THEN
					v_level = 2;
					v_message = 'Profile too long. You need to modify the horitzontal scale or change the composer';
					RETURN (concat('{"status":"Failed", "message":{"level":',v_level,', "text":"',v_message,'"}}')::json);
				END IF;
			END IF;
		ELSE
			-- set values for v_compheight & v_compwidth
			v_compheight = v_profheigtht;
			v_compwidth = v_profwidth;
		END IF;

		-- get portrait extension
		IF v_papersize = 0 THEN
			v_compwidth = (((p_data ->> 'data')::json->> 'papersize')::json->>'customDim')::json->>'xdim';
			v_compheight = (((p_data ->> 'data')::json->> 'papersize')::json->>'customDim')::json->>'ydim';
		ELSE
			v_compwidth = (SELECT addparam->>'xdim' FROM om_typevalue WHERE typevalue = 'profile_papersize' AND id = v_papersize::text);
			v_compheight = (SELECT addparam->>'ydim' FROM om_typevalue WHERE typevalue = 'profile_papersize' AND id = v_papersize::text);
		END IF;

		-- check dimensions against scale
		IF v_scaletofit IS FALSE THEN
			IF v_compheight < v_profheigtht THEN
				v_level = 2;
				v_message = 'Profile too large. You need to modify the vertical scale or change the composer';
				RETURN (concat('{"status":"Failed", "message":{"level":',v_level,', "text":"',v_message,'"}}')::json);
			END IF;
			IF v_compwidth < v_profwidth THEN
				v_level = 2;
				v_message = 'Profile too long. You need to modify the horitzontal scale or change the composer';
				RETURN (concat('{"status":"Failed", "message":{"level":',v_level,', "text":"',v_message,'"}}')::json);
			END IF;
			-- calculate the init point to start to draw profile
			v_initv = (v_compheight - v_profheigtht)/2;
			v_inith = (v_compwidth - v_profwidth)/2;
		ELSE
			-- calculate scale
			v_vs = (1000*v_elevation)/(v_compheight - v_legendfactor*50 - 10);
			v_hs = (1000*v_distance)/(v_compwidth - v_legendfactor*20 - 10);

			-- calculate the init point to start to draw profile
			v_initv = v_legendfactor*50;
			v_inith = v_legendfactor*20;
		END IF;

		IF v_compwidth IS NOT NULL  and v_compheight IS NOT NULL AND v_inith IS NOT NULL  and v_initv IS NOT NULL
			AND v_hs IS NOT NULL  AND v_hstext IS NOT NULL  AND v_vs IS NOT NULL AND v_vstext IS NOT NULL THEN

			-- extension as composer (redundant to fit the image as is)
			v_extension = (concat('{"width":', v_compwidth,', "height":', v_compheight,'}'))::json;

			-- initpoint to start to draw profile
			v_initpoint = (concat('{"initx":', v_inith,', "inity":', v_initv,'}'))::json;

			-- scale text
			v_scale = concat('1:',v_hs, '(',v_hstext,') - 1:',v_vs,'(',v_vstext,')');

			-- update values using scale factor
			v_hs = 2000/v_hs;
			v_vs = 500/v_vs;
		ELSE
			v_vs = 1;
			v_hs= 1;
		END IF;

		-- vertical (v_vs): all elevations and depths; horizontal (v_hs): all distances
		UPDATE temp_anl_arc SET
			cat_geom1 = cat_geom1*v_vs,
			elev1 = elev1*v_vs, elev2 = elev2*v_vs,
			top_elev1 = top_elev1*v_vs, top_elev2 = top_elev2*v_vs,
			y1 = y1*v_vs, y2 = y2*v_vs,
			z1 = z1*v_vs, z2 = z2*v_vs,
			length = length*v_hs,
			total_length = total_length*v_hs;

		UPDATE temp_anl_node SET
			cat_geom1 = cat_geom1*v_vs,
			top_elev = top_elev*v_vs,
			elev = elev*v_vs,
			ymax = ymax*v_vs,
			total_distance = total_distance*v_hs,
			arc_distance = arc_distance*v_hs;

		-- recover values from temp table into response (filtering by spacing certain distance of length in order to not collapse profile)
		IF v_project_type = 'UD' THEN
			SELECT array_to_json(array_agg(row_to_json(row))) INTO v_arc
			FROM (SELECT arc_id, reversed, descript, cat_geom1, length, z1, z2, y1, y2, elev1, elev2, top_elev1, top_elev2, node_1, node_2, omunit_id FROM temp_anl_arc ORDER BY total_length) row;
		ELSE
			SELECT array_to_json(array_agg(row_to_json(row))) INTO v_arc
			FROM (SELECT arc_id, reversed, descript, cat_geom1, length, z1, z2, y1, y2, elev1, elev2, top_elev1, top_elev2, node_1, node_2 FROM temp_anl_arc ORDER BY total_length) row;
		END IF;

		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_node
		FROM (
			SELECT DISTINCT node_id, nodecat_id AS surface_type, descript, sys_type AS data_type,
				cat_geom1, top_elev, elev, ymax, total_distance
			FROM temp_anl_node
			WHERE nodecat_id != 'VNODE'
			ORDER BY total_distance
		) row;

		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_terrain
		FROM (
			SELECT
				row_number() OVER w AS rid,
				top_elev AS top_n1,
				LEAD(top_elev) OVER w AS top_n2,
				(LEAD(top_elev) OVER w - top_elev)::numeric(12,3) AS delta_y,
				LEAD(total_distance) OVER w - total_distance AS delta_x,
				total_distance AS total_x,
				descript AS label_n1,
				nodecat_id AS surface_type
			FROM temp_anl_node
			WINDOW w AS (ORDER BY total_distance, id)
			ORDER BY total_distance, id
		) row;

	END IF;

	-- use SELECT DISTINCT because arc_id or node_id can appear multiple times
	-- when the route traverses the same element in both directions
	SELECT jsonb_build_object(
		'type', 'FeatureCollection',
		'layerName', 'Profile line',
		'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
	) INTO v_result
	FROM (
	SELECT jsonb_build_object(
		'type',       'Feature',
	'geometry',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
	'properties', to_jsonb(row) - 'the_geom'
	) AS feature
	FROM (
		SELECT DISTINCT arc_id, arccat_id, NULLIF(descript, '') as descript, expl_id, the_geom, 'ARC' as feature_type
		FROM  temp_anl_arc
		UNION ALL
		SELECT DISTINCT l.link_id, l.linkcat_id, NULLIF(l.descript, '') as descript, l.expl_id, l.the_geom, 'LINK' as feature_type
		FROM temp_anl_node n
		JOIN link l ON n.node_id = l.link_id) row) features;


	v_result_line = v_result;

	IF v_project_type = 'UD' THEN
		v_querytext := $aux$
			UNION ALL
			SELECT DISTINCT
				g.gully_id,
				g.gullycat_id,
				NULLIF(g.descript, '') AS descript,
				g.expl_id,
				g.the_geom,
				'GULLY' AS feature_type
			FROM temp_anl_node n
			JOIN temp_link l ON n.node_id = l.link_id
			JOIN gully g ON g.gully_id = l.feature_id
		$aux$;
	ELSE
		v_querytext := '';
	END IF;

	EXECUTE format($sql$
		SELECT 
			jsonb_build_object(
				'type', 'FeatureCollection',
				'layerName', 'Profile point',
				'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
			)
		FROM (
			SELECT 
				jsonb_build_object(
					'type', 'Feature',
					'geometry', ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
					'properties', to_jsonb(row) - 'the_geom'
				) AS feature
			FROM (
				SELECT DISTINCT
					node_id,
					nodecat_id,
					NULLIF(descript, '') AS descript,
					expl_id,
					the_geom,
					'NODE' AS feature_type
				FROM temp_anl_node
				WHERE nodecat_id != 'VNODE'
				UNION ALL
				SELECT DISTINCT
					c.connec_id,
					c.conneccat_id,
					NULLIF(c.descript, '') AS descript,
					c.expl_id,
					c.the_geom,
					'CONNEC' AS feature_type
				FROM temp_anl_node n
				JOIN temp_link l ON n.node_id = l.link_id
				JOIN connec c ON c.connec_id = l.feature_id
				%s
			) row
		) features;
	$sql$, v_querytext)
	INTO v_result;

	v_result_point = v_result;

	v_result_polygon = '{}';

	IF v_arc IS NULL THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4530", "function":"2832","parameters":null, "is_process":true}}$$);';
	END IF;

	-- control null values
	IF v_guitarlegend IS NULL THEN v_guitarlegend='{}'; END IF;
	IF v_stylesheet IS NULL THEN v_stylesheet='{}'; END IF;

	v_scale := COALESCE(v_scale, '{}');
	v_extension := COALESCE(v_extension, '{}');
	v_initpoint := COALESCE(v_initpoint, '{}');
	v_arc := COALESCE(v_arc, '{}');
	v_node := COALESCE(v_node, '{}');
	v_terrain := COALESCE(v_terrain, '{}');

	DROP TABLE IF EXISTS temp_anl_arc;
	DROP TABLE IF EXISTS temp_anl_node;
	DROP TABLE IF EXISTS temp_vnode;
	DROP TABLE IF EXISTS temp_link;
	DROP TABLE IF EXISTS temp_pgr_dijkstra;

	--  Return
	RETURN gw_fct_json_create_return(('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
               ',"body":{"form":{}'||
               ',"data":{"legend":'||v_guitarlegend||','||
			'"scale":"'||v_scale||'",'||
			'"extension":'||v_extension||','||
			'"initpoint":'||v_initpoint||','||
			'"stylesheet":'||v_stylesheet||','||
			'"node":'||v_node||','||
			'"terrain":'||v_terrain||','||
			'"arc":'||v_arc||','||
			'"point":'||v_result_point||','||
			'"line":'||v_result_line||','||
			'"polygon":'||v_result_polygon||'}}}')::json, 2832, null, null, null);

	--EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
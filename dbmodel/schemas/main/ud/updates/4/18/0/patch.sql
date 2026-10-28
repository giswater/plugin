/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- Mapzone synoptic layer that only exists on ud (#977).
-- Lines run from the border node to the zone polygon (flow_sign -1 is zone -> node).
-- Point rows with is_zone use the zone id as node_id.

CREATE OR REPLACE VIEW v_synoptic_line_dwfzone AS
SELECT
	g.mapzone_id AS synoptic_id,
	'DWFZONE'::text AS synoptic_type,
	g.node_id AS node_1,
	cn.node_type::text AS node_type_1,
	n.sys_code::text AS label_1,
	g.mapzone_id AS node_2,
	'MAPZONE'::text AS node_type_2,
	z.name::text AS label_2,
	g.flow_sign,
	CASE
		WHEN n.the_geom IS NULL OR z.the_geom IS NULL THEN NULL::geometry(LineString, SRID_VALUE)
		WHEN g.flow_sign = -1 THEN ST_MakeLine(ST_PointOnSurface(z.the_geom), n.the_geom)::geometry(LineString, SRID_VALUE)
		ELSE ST_MakeLine(n.the_geom, ST_PointOnSurface(z.the_geom))::geometry(LineString, SRID_VALUE)
	END AS the_geom
FROM mapzone_graph g
JOIN node n ON n.node_id = g.node_id
LEFT JOIN cat_node cn ON cn.id = n.nodecat_id
LEFT JOIN dwfzone z ON z.dwfzone_id = g.mapzone_id
WHERE g.mapzone_type = 'DWFZONE';

CREATE OR REPLACE VIEW v_synoptic_point_dwfzone AS
SELECT
	g.mapzone_id AS synoptic_id,
	'DWFZONE'::text AS synoptic_type,
	g.node_id,
	cn.node_type::text AS node_type,
	n.sys_code::text AS label,
	g.flow_sign,
	false AS is_zone,
	n.the_geom::geometry(Point, SRID_VALUE) AS the_geom
FROM mapzone_graph g
JOIN node n ON n.node_id = g.node_id
LEFT JOIN cat_node cn ON cn.id = n.nodecat_id
WHERE g.mapzone_type = 'DWFZONE'
UNION ALL
SELECT
	g.mapzone_id,
	'DWFZONE'::text,
	g.mapzone_id,
	'MAPZONE'::text,
	z.name::text,
	NULL::int2,
	true,
	ST_PointOnSurface(z.the_geom)::geometry(Point, SRID_VALUE)
FROM (
	SELECT DISTINCT mapzone_id
	FROM mapzone_graph
	WHERE mapzone_type = 'DWFZONE'
) g
LEFT JOIN dwfzone z ON z.dwfzone_id = g.mapzone_id;

INSERT INTO sys_table (id, descript, sys_role, alias, "source", addparam)
VALUES
	('v_synoptic_line_dwfzone', 'Mapzone synoptic edges for DWFZONE (node to zone geometry)', 'role_basic', 'Synoptic DWFZONE lines', 'core', '{"pkey": "node_1,node_2"}'::json),
	('v_synoptic_point_dwfzone', 'Mapzone synoptic vertices for DWFZONE', 'role_basic', 'Synoptic DWFZONE points', 'core', '{"pkey": "synoptic_id,node_id,is_zone"}'::json)
ON CONFLICT (id) DO UPDATE SET
	descript = EXCLUDED.descript,
	sys_role = EXCLUDED.sys_role,
	alias = EXCLUDED.alias,
	addparam = EXCLUDED.addparam;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Persist mapzone synoptic layout on plan netscenario graph (#965)
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"plan_netscenario_mapzone_graph",
  "column":"synoptic_id", "dataType":"int4"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"plan_netscenario_mapzone_graph",
  "column":"synoptic_geom", "dataType":"geometry(LineString)"}}$$);

CREATE INDEX IF NOT EXISTS plan_netscenario_mapzone_graph_synoptic_id_idx
	ON plan_netscenario_mapzone_graph USING btree (synoptic_id);

-- Mapzone synoptic layers that only exist on ws (#977).
-- Lines run from the border node to the zone polygon (flow_sign -1 is zone -> node).
-- Point rows with is_zone use the zone id as node_id.

CREATE OR REPLACE VIEW v_synoptic_line_dqa AS
SELECT
	g.mapzone_id AS synoptic_id,
	'DQA'::text AS synoptic_type,
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
LEFT JOIN dqa z ON z.dqa_id = g.mapzone_id
WHERE g.mapzone_type = 'DQA';

CREATE OR REPLACE VIEW v_synoptic_point_dqa AS
SELECT
	g.mapzone_id AS synoptic_id,
	'DQA'::text AS synoptic_type,
	g.node_id,
	cn.node_type::text AS node_type,
	n.sys_code::text AS label,
	g.flow_sign,
	false AS is_zone,
	n.the_geom::geometry(Point, SRID_VALUE) AS the_geom
FROM mapzone_graph g
JOIN node n ON n.node_id = g.node_id
LEFT JOIN cat_node cn ON cn.id = n.nodecat_id
WHERE g.mapzone_type = 'DQA'
UNION ALL
SELECT
	g.mapzone_id,
	'DQA'::text,
	g.mapzone_id,
	'MAPZONE'::text,
	z.name::text,
	NULL::int2,
	true,
	ST_PointOnSurface(z.the_geom)::geometry(Point, SRID_VALUE)
FROM (
	SELECT DISTINCT mapzone_id
	FROM mapzone_graph
	WHERE mapzone_type = 'DQA'
) g
LEFT JOIN dqa z ON z.dqa_id = g.mapzone_id;

CREATE OR REPLACE VIEW v_synoptic_line_presszone AS
SELECT
	g.mapzone_id AS synoptic_id,
	'PRESSZONE'::text AS synoptic_type,
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
LEFT JOIN presszone z ON z.presszone_id = g.mapzone_id
WHERE g.mapzone_type = 'PRESSZONE';

CREATE OR REPLACE VIEW v_synoptic_point_presszone AS
SELECT
	g.mapzone_id AS synoptic_id,
	'PRESSZONE'::text AS synoptic_type,
	g.node_id,
	cn.node_type::text AS node_type,
	n.sys_code::text AS label,
	g.flow_sign,
	false AS is_zone,
	n.the_geom::geometry(Point, SRID_VALUE) AS the_geom
FROM mapzone_graph g
JOIN node n ON n.node_id = g.node_id
LEFT JOIN cat_node cn ON cn.id = n.nodecat_id
WHERE g.mapzone_type = 'PRESSZONE'
UNION ALL
SELECT
	g.mapzone_id,
	'PRESSZONE'::text,
	g.mapzone_id,
	'MAPZONE'::text,
	z.name::text,
	NULL::int2,
	true,
	ST_PointOnSurface(z.the_geom)::geometry(Point, SRID_VALUE)
FROM (
	SELECT DISTINCT mapzone_id
	FROM mapzone_graph
	WHERE mapzone_type = 'PRESSZONE'
) g
LEFT JOIN presszone z ON z.presszone_id = g.mapzone_id;

CREATE OR REPLACE VIEW v_synoptic_line_supplyzone AS
SELECT
	g.mapzone_id AS synoptic_id,
	'SUPPLYZONE'::text AS synoptic_type,
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
LEFT JOIN supplyzone z ON z.supplyzone_id = g.mapzone_id
WHERE g.mapzone_type = 'SUPPLYZONE';

CREATE OR REPLACE VIEW v_synoptic_point_supplyzone AS
SELECT
	g.mapzone_id AS synoptic_id,
	'SUPPLYZONE'::text AS synoptic_type,
	g.node_id,
	cn.node_type::text AS node_type,
	n.sys_code::text AS label,
	g.flow_sign,
	false AS is_zone,
	n.the_geom::geometry(Point, SRID_VALUE) AS the_geom
FROM mapzone_graph g
JOIN node n ON n.node_id = g.node_id
LEFT JOIN cat_node cn ON cn.id = n.nodecat_id
WHERE g.mapzone_type = 'SUPPLYZONE'
UNION ALL
SELECT
	g.mapzone_id,
	'SUPPLYZONE'::text,
	g.mapzone_id,
	'MAPZONE'::text,
	z.name::text,
	NULL::int2,
	true,
	ST_PointOnSurface(z.the_geom)::geometry(Point, SRID_VALUE)
FROM (
	SELECT DISTINCT mapzone_id
	FROM mapzone_graph
	WHERE mapzone_type = 'SUPPLYZONE'
) g
LEFT JOIN supplyzone z ON z.supplyzone_id = g.mapzone_id;

INSERT INTO sys_table (id, descript, sys_role, alias, "source", addparam)
VALUES
	('v_synoptic_line_dqa', 'Mapzone synoptic edges for DQA (node to zone geometry)', 'role_basic', 'Synoptic DQA lines', 'core', '{"pkey": "node_1,node_2"}'::json),
	('v_synoptic_point_dqa', 'Mapzone synoptic vertices for DQA', 'role_basic', 'Synoptic DQA points', 'core', '{"pkey": "synoptic_id,node_id,is_zone"}'::json),
	('v_synoptic_line_presszone', 'Mapzone synoptic edges for PRESSZONE (node to zone geometry)', 'role_basic', 'Synoptic PRESSZONE lines', 'core', '{"pkey": "node_1,node_2"}'::json),
	('v_synoptic_point_presszone', 'Mapzone synoptic vertices for PRESSZONE', 'role_basic', 'Synoptic PRESSZONE points', 'core', '{"pkey": "synoptic_id,node_id,is_zone"}'::json),
	('v_synoptic_line_supplyzone', 'Mapzone synoptic edges for SUPPLYZONE (node to zone geometry)', 'role_basic', 'Synoptic SUPPLYZONE lines', 'core', '{"pkey": "node_1,node_2"}'::json),
	('v_synoptic_point_supplyzone', 'Mapzone synoptic vertices for SUPPLYZONE', 'role_basic', 'Synoptic SUPPLYZONE points', 'core', '{"pkey": "synoptic_id,node_id,is_zone"}'::json)
ON CONFLICT (id) DO UPDATE SET
	descript = EXCLUDED.descript,
	sys_role = EXCLUDED.sys_role,
	alias = EXCLUDED.alias,
	addparam = EXCLUDED.addparam;

-- Reviews joined to the feature. ve_* keeps rows outside the exploitation selector out of the list.
CREATE OR REPLACE VIEW v_ui_review_feature AS
SELECT r.id, r.table_name, r.table_id,
	COALESCE(n.code, a.code, c.code, l.code) AS feature_code,
	COALESCE(n.node_type, a.arc_type, c.connec_type, l.link_type) AS feature_type,
	COALESCE(n.expl_id, a.expl_id, c.expl_id, l.expl_id) AS expl_id,
	r.field_user, r.field_date, r.field_annotation, r.field_changes,
	r.review_user, r.review_date, r.review_annotation,
	r.status, et.idval AS status_name
FROM review_feature r
LEFT JOIN ve_node n ON r.table_name = 'node' AND n.node_id = r.table_id
LEFT JOIN ve_arc a ON r.table_name = 'arc' AND a.arc_id = r.table_id
LEFT JOIN ve_connec c ON r.table_name = 'connec' AND c.connec_id = r.table_id
LEFT JOIN ve_link l ON r.table_name = 'link' AND l.link_id = r.table_id
LEFT JOIN edit_typevalue et ON et.typevalue = 'review_status' AND et.id = r.status::text;

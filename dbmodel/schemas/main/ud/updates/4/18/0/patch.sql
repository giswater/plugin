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

-- Same condition scale as ws: 1 = excellent, 5 = critical.
INSERT INTO edit_typevalue (typevalue, id, idval, descript, addparam) VALUES
	('om_state', '1', 'Excellent',
	 'The asset fully meets its operational requirements, with high reliability, adequate capacity and no relevant performance constraints.', NULL),
	('om_state', '2', 'Good',
	 'The asset performs its intended function reliably and meets the required level of service. Minor deficiencies may exist but have no significant operational impact.', NULL),
	('om_state', '3', 'Fair',
	 'The asset performs its required function but with moderate operational limitations, reduced efficiency or reliability. Increased monitoring and planned maintenance are recommended.', NULL),
	('om_state', '4', 'Poor',
	 'The asset operates with major limitations, reduced reliability or insufficient capacity. There is a significant risk of service disruption and corrective action is required in the short term.', NULL),
	('om_state', '5', 'Critical',
	 'The asset is non-operational or unable to deliver its required function. Service continuity is compromised and immediate corrective action or replacement is required.', NULL),
	('conserv_state', '1', 'Excellent',
	 'The asset is in very good or near-new condition, with no significant deterioration and full physical integrity. Only routine maintenance is required.', NULL),
	('conserv_state', '2', 'Good',
	 'The asset is in good physical condition with only minor deterioration or defects. Preventive or routine maintenance is sufficient.', NULL),
	('conserv_state', '3', 'Fair',
	 'Moderate deterioration and localized defects are present. The asset remains serviceable but planned maintenance or rehabilitation is required to prevent further degradation.', NULL),
	('conserv_state', '4', 'Poor',
	 'Significant deterioration or defects are present. Asset condition is approaching unacceptable limits and major maintenance or rehabilitation is required in the short term.', NULL),
	('conserv_state', '5', 'Critical',
	 'Severe deterioration, structural damage or loss of integrity is present. The probability of physical failure is high and immediate rehabilitation or replacement is required.', NULL)
ON CONFLICT (typevalue, id) DO UPDATE SET
	idval = EXCLUDED.idval,
	descript = EXCLUDED.descript;

INSERT INTO sys_foreignkey (typevalue_table, typevalue_name, target_table, target_field, parameter_id, active) VALUES
	('edit_typevalue', 'om_state', 'node', 'om_state', NULL, true),
	('edit_typevalue', 'om_state', 'arc', 'om_state', NULL, true),
	('edit_typevalue', 'om_state', 'connec', 'om_state', NULL, true),
	('edit_typevalue', 'om_state', 'gully', 'om_state', NULL, true),
	('edit_typevalue', 'conserv_state', 'node', 'conserv_state', NULL, true),
	('edit_typevalue', 'conserv_state', 'arc', 'conserv_state', NULL, true)
ON CONFLICT (typevalue_table, typevalue_name, target_table, target_field) DO NOTHING;

UPDATE config_form_fields
SET widgettype = 'combo',
	dv_querytext = 'SELECT id, idval FROM edit_typevalue WHERE typevalue=''om_state'' ORDER BY id::integer',
	dv_orderby_id = true,
	dv_isnullvalue = true
WHERE columnname = 'om_state'
  AND formname ILIKE ANY (ARRAY['ve_node%', 've_arc%', 've_connec%', 've_gully%']);

UPDATE config_form_fields
SET widgettype = 'combo',
	dv_querytext = 'SELECT id, idval FROM edit_typevalue WHERE typevalue=''conserv_state'' ORDER BY id::integer',
	dv_orderby_id = true,
	dv_isnullvalue = true
WHERE columnname = 'conserv_state'
  AND formname ILIKE ANY (ARRAY['ve_node%', 've_arc%']);

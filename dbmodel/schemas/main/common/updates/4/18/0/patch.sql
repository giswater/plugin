/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Persist mapzone synoptic layout from gw_fct_graphanalytics_mapzones_v1 (#965)
-- synoptic_geom uses abstract Sugiyama coords (no project SRID), same space as attrib.synopticGeometry
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"mapzone_graph",
  "column":"synoptic_id", "dataType":"int4"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"mapzone_graph",
  "column":"synoptic_geom", "dataType":"geometry(LineString)"}}$$);

CREATE INDEX IF NOT EXISTS mapzone_graph_synoptic_id_idx ON mapzone_graph USING btree (synoptic_id);

INSERT INTO config_param_system (
    parameter, value, descript, label, isenabled, layoutorder, project_type,
    dv_isparent, isautoupdate, datatype, widgettype, ismandatory, iseditable, layoutname
)
VALUES (
    'edit_element_geom_from_feature', 'false',
    'If true, a new element without geometry takes a point from the associated feature, and an element that shares a node, connec or gully point follows that feature when it moves. Flow regulators (FRELEM) are excluded. Arcs and links use the midpoint of the line.',
    'Copy element geometry from feature:',
    true, 12, 'utils', false, false, 'boolean', 'check', false, true, 'lyt_topology'
)
ON CONFLICT (parameter) DO NOTHING;

INSERT INTO sys_label (id, idval, label_type) VALUES (4005, 'NEW', 'python') ON CONFLICT (id) DO NOTHING;

-- om_scada_graph.group_id is the synoptic id. Layout line leaves attrib (#977).
-- v_om_scada_graph is dropped (no CASCADE) and recreated so synoptic_geom
-- sits next to attrib. Grants are copied back; lastprocess also re-grants.

DROP TABLE IF EXISTS pg_temp._v_om_scada_graph_acl;
CREATE TEMP TABLE _v_om_scada_graph_acl AS
SELECT DISTINCT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = current_schema()
	AND table_name = 'v_om_scada_graph'
	AND grantee <> 'PUBLIC';

DROP TRIGGER IF EXISTS gw_trg_v_om_scada_graph_delete ON v_om_scada_graph;
DROP VIEW IF EXISTS v_om_scada_graph;

SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"om_scada_graph","column":"group_id","newName":"synoptic_id"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"om_scada_graph","column":"synoptic_geom","dataType":"geometry(LineString, 0)"}}$$);

-- Schematic line: x = position_id, y = level_id. Not the project SRID.
UPDATE om_scada_graph
SET synoptic_geom = ST_SetSRID(ST_GeomFromGeoJSON((attrib::json -> 'synopticGeometry')::text), 0)
WHERE attrib IS JSON
	AND json_typeof(attrib::json -> 'synopticGeometry') = 'object'
	AND attrib::json -> 'synopticGeometry' ->> 'type' = 'LineString'
	AND json_typeof(attrib::json -> 'synopticGeometry' -> 'coordinates') = 'array'
	AND json_array_length(attrib::json -> 'synopticGeometry' -> 'coordinates') >= 2;

UPDATE om_scada_graph
SET attrib = NULLIF((attrib::jsonb - 'synopticGeometry')::text, '{}')
WHERE synoptic_geom IS NOT NULL
	AND attrib IS JSON
	AND attrib::jsonb ? 'synopticGeometry';

CREATE INDEX IF NOT EXISTS om_scada_graph_synoptic_id_idx ON om_scada_graph USING btree (synoptic_id);

CREATE OR REPLACE VIEW v_om_scada_graph AS
SELECT
	osg.synoptic_id,
	osg.node_1,
	osg.node_type_1,
	n1.sys_code AS sys_code_1,
	n1.expl_id AS expl_id_1,
	n1.dma_id AS dma_id_1,
	d1.name AS dma_name_1,
	osg.node_2,
	osg.node_type_2,
	n2.sys_code AS sys_code_2,
	n2.expl_id AS expl_id_2,
	n2.dma_id AS dma_id_2,
	d2.name AS dma_name_2,
	osg.expl_id,
	osg.attrib,
	osg.synoptic_geom,
	osg.active,
	osg.the_geom
FROM om_scada_graph osg
LEFT JOIN node n1 ON n1.node_id = osg.node_1
LEFT JOIN dma d1 ON d1.dma_id = n1.dma_id
LEFT JOIN node n2 ON n2.node_id = osg.node_2
LEFT JOIN dma d2 ON d2.dma_id = n2.dma_id;

CREATE TRIGGER gw_trg_v_om_scada_graph_delete
INSTEAD OF DELETE ON v_om_scada_graph
FOR EACH ROW EXECUTE FUNCTION gw_trg_scada_graph_builder();

DO $scada_view_acl$
DECLARE
	r record;
BEGIN
	FOR r IN SELECT grantee, privilege_type FROM _v_om_scada_graph_acl
	LOOP
		EXECUTE format(
			'GRANT %s ON TABLE v_om_scada_graph TO %I',
			r.privilege_type,
			r.grantee
		);
	END LOOP;
END
$scada_view_acl$;

DROP TABLE IF EXISTS pg_temp._v_om_scada_graph_acl;

UPDATE sys_function
SET descript = 'Builds synoptic layout (level_id, position_id). Both graphs store synoptic_id. SCADA also stores synoptic_geom; MAPZONE keeps the layout line in attrib.synopticGeometry.'
WHERE id = 3574;

-- Synoptic layers (#977).
-- SCADA: schematic geometry (SRID 0). x = position_id, y = level_id.
-- Mapzone: mapzone_graph has no stored layout. Lines run from the border node
-- to the zone polygon (flow_sign -1 is zone -> node). Point rows with
-- is_zone use the zone id as node_id, same id space as the synoptic edges.

CREATE OR REPLACE VIEW v_synoptic_line_scada AS
SELECT
	g.synoptic_id,
	'SCADA'::text AS synoptic_type,
	g.node_1,
	g.node_type_1::text AS node_type_1,
	n1.sys_code::text AS label_1,
	g.node_2,
	g.node_type_2::text AS node_type_2,
	n2.sys_code::text AS label_2,
	NULL::int2 AS flow_sign,
	g.synoptic_geom::geometry(LineString, 0) AS the_geom
FROM om_scada_graph g
LEFT JOIN node n1 ON n1.node_id = g.node_1
LEFT JOIN node n2 ON n2.node_id = g.node_2;

CREATE OR REPLACE VIEW v_synoptic_point_scada AS
SELECT DISTINCT ON (synoptic_id, node_id)
	synoptic_id,
	'SCADA'::text AS synoptic_type,
	node_id,
	node_type,
	label,
	NULL::int2 AS flow_sign,
	false AS is_zone,
	the_geom
FROM (
	SELECT
		g.synoptic_id,
		g.node_1 AS node_id,
		g.node_type_1::text AS node_type,
		n.sys_code::text AS label,
		ST_StartPoint(g.synoptic_geom)::geometry(Point, 0) AS the_geom
	FROM om_scada_graph g
	LEFT JOIN node n ON n.node_id = g.node_1
	WHERE g.synoptic_geom IS NOT NULL
	UNION ALL
	SELECT
		g.synoptic_id,
		g.node_2,
		g.node_type_2::text,
		n.sys_code::text,
		ST_EndPoint(g.synoptic_geom)::geometry(Point, 0)
	FROM om_scada_graph g
	LEFT JOIN node n ON n.node_id = g.node_2
	WHERE g.synoptic_geom IS NOT NULL
) s
ORDER BY synoptic_id, node_id, the_geom IS NULL;

INSERT INTO sys_table (id, descript, sys_role, alias, "source", addparam)
VALUES
	('v_synoptic_line_scada', 'SCADA synoptic edges (schematic LineString, SRID 0)', 'role_om', 'Synoptic SCADA lines', 'core', '{"pkey": "node_1,node_2"}'::json),
	('v_synoptic_point_scada', 'SCADA synoptic vertices (schematic Point, SRID 0)', 'role_om', 'Synoptic SCADA points', 'core', '{"pkey": "synoptic_id,node_id,is_zone"}'::json)
ON CONFLICT (id) DO UPDATE SET
	descript = EXCLUDED.descript,
	sys_role = EXCLUDED.sys_role,
	alias = EXCLUDED.alias,
	addparam = EXCLUDED.addparam;

-- dma and sector exist on ws and ud. presszone, dqa and supplyzone are in the
-- ws 4.18.0 patch. dwfzone is in the ud 4.18.0 patch.

CREATE OR REPLACE VIEW v_synoptic_line_dma AS
SELECT
	g.mapzone_id AS synoptic_id,
	'DMA'::text AS synoptic_type,
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
LEFT JOIN dma z ON z.dma_id = g.mapzone_id
WHERE g.mapzone_type = 'DMA';

CREATE OR REPLACE VIEW v_synoptic_point_dma AS
SELECT
	g.mapzone_id AS synoptic_id,
	'DMA'::text AS synoptic_type,
	g.node_id,
	cn.node_type::text AS node_type,
	n.sys_code::text AS label,
	g.flow_sign,
	false AS is_zone,
	n.the_geom::geometry(Point, SRID_VALUE) AS the_geom
FROM mapzone_graph g
JOIN node n ON n.node_id = g.node_id
LEFT JOIN cat_node cn ON cn.id = n.nodecat_id
WHERE g.mapzone_type = 'DMA'
UNION ALL
SELECT
	g.mapzone_id,
	'DMA'::text,
	g.mapzone_id,
	'MAPZONE'::text,
	z.name::text,
	NULL::int2,
	true,
	ST_PointOnSurface(z.the_geom)::geometry(Point, SRID_VALUE)
FROM (
	SELECT DISTINCT mapzone_id
	FROM mapzone_graph
	WHERE mapzone_type = 'DMA'
) g
LEFT JOIN dma z ON z.dma_id = g.mapzone_id;

CREATE OR REPLACE VIEW v_synoptic_line_sector AS
SELECT
	g.mapzone_id AS synoptic_id,
	'SECTOR'::text AS synoptic_type,
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
LEFT JOIN sector z ON z.sector_id = g.mapzone_id
WHERE g.mapzone_type = 'SECTOR';

CREATE OR REPLACE VIEW v_synoptic_point_sector AS
SELECT
	g.mapzone_id AS synoptic_id,
	'SECTOR'::text AS synoptic_type,
	g.node_id,
	cn.node_type::text AS node_type,
	n.sys_code::text AS label,
	g.flow_sign,
	false AS is_zone,
	n.the_geom::geometry(Point, SRID_VALUE) AS the_geom
FROM mapzone_graph g
JOIN node n ON n.node_id = g.node_id
LEFT JOIN cat_node cn ON cn.id = n.nodecat_id
WHERE g.mapzone_type = 'SECTOR'
UNION ALL
SELECT
	g.mapzone_id,
	'SECTOR'::text,
	g.mapzone_id,
	'MAPZONE'::text,
	z.name::text,
	NULL::int2,
	true,
	ST_PointOnSurface(z.the_geom)::geometry(Point, SRID_VALUE)
FROM (
	SELECT DISTINCT mapzone_id
	FROM mapzone_graph
	WHERE mapzone_type = 'SECTOR'
) g
LEFT JOIN sector z ON z.sector_id = g.mapzone_id;

INSERT INTO sys_table (id, descript, sys_role, alias, "source", addparam)
VALUES
	('v_synoptic_line_dma', 'Mapzone synoptic edges for DMA (node to zone geometry)', 'role_basic', 'Synoptic DMA lines', 'core', '{"pkey": "node_1,node_2"}'::json),
	('v_synoptic_point_dma', 'Mapzone synoptic vertices for DMA', 'role_basic', 'Synoptic DMA points', 'core', '{"pkey": "synoptic_id,node_id,is_zone"}'::json),
	('v_synoptic_line_sector', 'Mapzone synoptic edges for SECTOR (node to zone geometry)', 'role_basic', 'Synoptic SECTOR lines', 'core', '{"pkey": "node_1,node_2"}'::json),
	('v_synoptic_point_sector', 'Mapzone synoptic vertices for SECTOR', 'role_basic', 'Synoptic SECTOR points', 'core', '{"pkey": "synoptic_id,node_id,is_zone"}'::json)
ON CONFLICT (id) DO UPDATE SET
	descript = EXCLUDED.descript,
	sys_role = EXCLUDED.sys_role,
	alias = EXCLUDED.alias,
	addparam = EXCLUDED.addparam;

-- gw_fct_scada_graph_export has no callers. om_scada_graph_json only existed
-- as its output. _om_scada_graph_json_ is the 4.17.0 rename leftover (#977).
DROP FUNCTION IF EXISTS gw_fct_scada_graph_export(json);
DROP FUNCTION IF EXISTS gw_fct_scada_graph_export();
DROP TABLE IF EXISTS om_scada_graph_json;
DROP TABLE IF EXISTS _om_scada_graph_json_;

DELETE FROM sys_function WHERE function_name = 'gw_fct_scada_graph_export';

UPDATE sys_function
SET descript = 'Checks or fixes om_scada_graph against the network (toolbox: Scada graph analysis).'
WHERE id = 3548;

UPDATE sys_function
SET descript = 'Creates a scada graph edge (insert + trigger fill).'
WHERE id = 3560;

DELETE FROM sys_message WHERE id IN (4708, 4732, 4734, 4736);

-- Feature reviews: proposed field changes waiting to be accepted or rejected.
-- gw_fct_manage_review_feature lives in base/fct (code 3576).

CREATE TABLE IF NOT EXISTS review_feature (
	id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	table_name text NOT NULL CHECK (table_name IN ('node', 'arc', 'connec', 'link', 'gully')),
	table_id int4 NOT NULL,
	field_user text DEFAULT current_user,
	field_date timestamptz DEFAULT now(),
	field_annotation text,
	field_changes jsonb NOT NULL,
	review_annotation text,
	review_user text,
	review_date timestamptz,
	status int2 NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS review_feature_feature_idx ON review_feature (table_name, table_id);
CREATE INDEX IF NOT EXISTS review_feature_status_idx ON review_feature (status);

INSERT INTO edit_typevalue (typevalue, id, idval, descript, addparam) VALUES
	('review_status', '0', 'PENDING', NULL, NULL),
	('review_status', '1', 'ACCEPTED', NULL, NULL),
	('review_status', '2', 'REJECTED', NULL, NULL)
ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO sys_table (id, descript, sys_role, alias, "source", addparam) VALUES
	('review_feature', 'Proposed feature changes waiting for review', 'role_edit', 'Feature review', 'core', '{"pkey": "id"}'::json),
	('v_ui_review_feature', 'Feature reviews with the feature code and type', 'role_edit', 'Feature reviews', 'core', '{"pkey": "id"}'::json)
ON CONFLICT (id) DO UPDATE SET
	descript = EXCLUDED.descript,
	sys_role = EXCLUDED.sys_role,
	alias = EXCLUDED.alias,
	addparam = EXCLUDED.addparam;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES (3576, 'gw_fct_manage_review_feature', 'utils', 'function', 'json', 'json',
	'Gets a feature review and accepts or rejects its proposed changes',
	'role_edit', NULL, 'core', 'Review feature')
ON CONFLICT (id) DO UPDATE SET
	function_name = EXCLUDED.function_name,
	descript = EXCLUDED.descript,
	sys_role = EXCLUDED.sys_role;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES
	(4760, 'This review does not exist.', 'Refresh the list and open it again.', 2, true, 'utils', 'core', 'UI'),
	(4762, 'This review is no longer pending.', 'It was already accepted or rejected.', 2, true, 'utils', 'core', 'UI'),
	(4764, 'The feature for this review was not found.', 'It may have been deleted or it is outside the exploitation selector.', 2, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES
	('layout_name_typevalue', 'lyt_review_mng_1', 'lyt_review_mng_1', 'layoutReviewManager1', '{"lytOrientation":"horizontal"}'::json),
	('layout_name_typevalue', 'lyt_review_mng_2', 'lyt_review_mng_2', 'layoutReviewManager2', '{"lytOrientation":"horizontal"}'::json),
	('formtype_typevalue', 'form_review', 'form_review', 'formReview', NULL)
ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES
	('review_manager', 'form_review', 'tab_none', 'status', 'lyt_review_mng_1', 1, 'string', 'combo', 'Status:', NULL, NULL, false, false, true, false, true,
		'SELECT id, idval FROM edit_typevalue WHERE typevalue = ''review_status''', true, true, NULL, NULL, NULL,
		'{"saveValue": false, "filterSign": "=", "vdefault_value": "0"}'::json,
		'{"functionName": "filter_table", "parameters": {"columnfind": "status"}}'::json, 'v_ui_review_feature', false, NULL),
	('review_manager', 'form_review', 'tab_none', 'table_name', 'lyt_review_mng_1', 2, 'string', 'combo', 'Table:', NULL, NULL, false, false, true, false, true,
		'SELECT id, id AS idval FROM (VALUES (''node''), (''arc''), (''connec''), (''link''), (''gully'')) AS t(id)', true, true, NULL, NULL, NULL,
		'{"saveValue": false, "filterSign": "="}'::json,
		'{"functionName": "filter_table", "parameters": {"columnfind": "table_name"}}'::json, 'v_ui_review_feature', false, NULL),
	('review_manager', 'form_review', 'tab_none', 'field_user', 'lyt_review_mng_1', 3, 'string', 'typeahead', 'Field user:', NULL, NULL, false, false, true, false, true,
		'SELECT DISTINCT field_user AS id, field_user AS idval FROM review_feature WHERE field_user IS NOT NULL', NULL, NULL, NULL, NULL, NULL,
		'{"saveValue": false, "filterSign": "ILIKE"}'::json,
		'{"functionName": "filter_table", "parameters": {"columnfind": "field_user"}}'::json, 'v_ui_review_feature', false, NULL),
	('review_manager', 'form_review', 'tab_none', 'date_from', 'lyt_review_mng_1', 4, 'date', 'datetime', 'From:', NULL, NULL, false, false, true, false, true,
		NULL, NULL, NULL, NULL, NULL, NULL,
		'{"saveValue": false, "filterSign": ">="}'::json,
		'{"functionName": "filter_table", "parameters": {"columnfind": "date_from"}}'::json, 'v_ui_review_feature', false, NULL),
	('review_manager', 'form_review', 'tab_none', 'date_to', 'lyt_review_mng_1', 5, 'date', 'datetime', 'To:', NULL, NULL, false, false, true, false, true,
		NULL, NULL, NULL, NULL, NULL, NULL,
		'{"saveValue": false, "filterSign": "<="}'::json,
		'{"functionName": "filter_table", "parameters": {"columnfind": "date_to"}}'::json, 'v_ui_review_feature', false, NULL),
	('review_manager', 'form_review', 'tab_none', 'hspacer_lyt_review_mng_1', 'lyt_review_mng_1', 6, NULL, 'hspacer', NULL, NULL, NULL, false, false, true, false, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
	('review_manager', 'form_review', 'tab_none', 'tbl_review', 'lyt_review_mng_2', 1, NULL, 'tablewidget', NULL, NULL, NULL, false, false, false, false, false,
		NULL, NULL, NULL, NULL, NULL, NULL,
		'{"saveValue": false}'::json,
		'{"functionName": "open_review", "module": "review_manager", "parameters": {"columnfind": "id"}}'::json, 'v_ui_review_feature', false, NULL),
	('review_manager', 'form_review', 'tab_none', 'hspacer_lyt_buttons', 'lyt_buttons', 1, NULL, 'hspacer', NULL, NULL, NULL, false, false, true, false, NULL,
		NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
	('review_manager', 'form_review', 'tab_none', 'close', 'lyt_buttons', 2, NULL, 'button', NULL, 'Close', NULL, false, false, true, false, false,
		NULL, NULL, NULL, NULL, NULL, NULL,
		'{"saveValue": false, "text": "Close"}'::json,
		'{"functionName": "close_manager", "parameters": {}}'::json, NULL, false, NULL)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

-- date_from / date_to are aliases of field_date so both ends of the range can filter.
INSERT INTO config_form_list (listname, query_text, device, listtype, listclass, vdefault)
VALUES (
	'v_ui_review_feature',
	'SELECT * FROM (SELECT id, table_name, table_id, feature_code, feature_type, expl_id, field_user, field_date, field_date::date AS date_from, field_date::date AS date_to, field_annotation, review_user, review_date, review_annotation, status, status_name FROM v_ui_review_feature) a WHERE id IS NOT NULL',
	4, 'tab', 'list', '{"orderBy":"field_date", "orderType":"DESC"}'::json
)
ON CONFLICT (listname, device) DO NOTHING;

INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, alias) VALUES
	('review_manager', 'utils', 'v_ui_review_feature', 'status_name', 0, true, 'Status'),
	('review_manager', 'utils', 'v_ui_review_feature', 'table_name', 1, true, 'Table'),
	('review_manager', 'utils', 'v_ui_review_feature', 'table_id', 2, true, 'Feature id'),
	('review_manager', 'utils', 'v_ui_review_feature', 'feature_code', 3, true, 'Code'),
	('review_manager', 'utils', 'v_ui_review_feature', 'feature_type', 4, true, 'Type'),
	('review_manager', 'utils', 'v_ui_review_feature', 'expl_id', 5, true, 'Exploitation'),
	('review_manager', 'utils', 'v_ui_review_feature', 'field_user', 6, true, 'Field user'),
	('review_manager', 'utils', 'v_ui_review_feature', 'field_date', 7, true, 'Field date'),
	('review_manager', 'utils', 'v_ui_review_feature', 'field_annotation', 8, true, 'Annotation'),
	('review_manager', 'utils', 'v_ui_review_feature', 'review_user', 9, true, 'Review user'),
	('review_manager', 'utils', 'v_ui_review_feature', 'review_date', 10, true, 'Review date'),
	('review_manager', 'utils', 'v_ui_review_feature', 'review_annotation', 11, true, 'Review annotation'),
	('review_manager', 'utils', 'v_ui_review_feature', 'id', 12, false, 'Id'),
	('review_manager', 'utils', 'v_ui_review_feature', 'status', 13, false, 'Status id'),
	('review_manager', 'utils', 'v_ui_review_feature', 'date_from', 14, false, 'From'),
	('review_manager', 'utils', 'v_ui_review_feature', 'date_to', 15, false, 'To')
ON CONFLICT (objectname, columnname) DO NOTHING;

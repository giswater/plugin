/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public;

-- UD catalogs use geom1, not dnom (WS trigger body from common/fct is overwritten here)
CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_asset_cat_arc() RETURNS trigger AS
$BODY$
BEGIN
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	IF TG_OP = 'INSERT' THEN
		INSERT INTO am.config_catalog_def (arccat_id, dnom)
		VALUES (NEW.id, NEW.geom1)
		ON CONFLICT (arccat_id) DO NOTHING;
		RETURN NEW;
	ELSIF TG_OP = 'UPDATE' THEN
		UPDATE am.config_catalog_def SET dnom = NEW.geom1 WHERE arccat_id = OLD.id;
		RETURN NEW;
	END IF;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION PARENT_SCHEMA.gw_trg_asset_cat_node() RETURNS trigger AS
$BODY$
BEGIN
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	IF TG_OP = 'INSERT' THEN
		INSERT INTO am.config_nodecatalog_def (nodecat_id, dnom)
		VALUES (NEW.id, NEW.geom1)
		ON CONFLICT (nodecat_id) DO NOTHING;
		RETURN NEW;
	ELSIF TG_OP = 'UPDATE' THEN
		UPDATE am.config_nodecatalog_def SET dnom = NEW.geom1 WHERE nodecat_id = OLD.id;
		RETURN NEW;
	END IF;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

INSERT INTO PARENT_SCHEMA.config_typevalue (typevalue, id, idval, camelstyle, addparam)
VALUES('sys_table_context', '{"levels": ["AM", "LAYERS"]}', NULL, NULL, '{"orderBy":1}'::json)
ON CONFLICT (typevalue,id) DO NOTHING;

-- catalog FKs / triggers (ARC + NODE only; LINK is WS)
DROP TRIGGER IF EXISTS gw_trg_asset_cat_arc ON PARENT_SCHEMA.cat_arc;
CREATE TRIGGER gw_trg_asset_cat_arc AFTER INSERT OR UPDATE OF geom1 ON PARENT_SCHEMA.cat_arc
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_asset_cat_arc();

ALTER TABLE am.config_catalog_def DROP CONSTRAINT IF EXISTS config_catalog_def_fk;
ALTER TABLE am.config_catalog_def ADD CONSTRAINT config_catalog_def_fk FOREIGN KEY (arccat_id)
REFERENCES PARENT_SCHEMA.cat_arc (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;

DROP TRIGGER IF EXISTS gw_trg_asset_cat_material ON PARENT_SCHEMA.cat_material;
CREATE TRIGGER gw_trg_asset_cat_material AFTER INSERT ON PARENT_SCHEMA.cat_material
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_asset_cat_material();

ALTER TABLE am.config_material_def DROP CONSTRAINT IF EXISTS config_material_def_fk;
ALTER TABLE am.config_material_def ADD CONSTRAINT config_material_def_fk FOREIGN KEY (material)
REFERENCES PARENT_SCHEMA.cat_material (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;

DROP TRIGGER IF EXISTS gw_trg_asset_cat_node ON PARENT_SCHEMA.cat_node;
CREATE TRIGGER gw_trg_asset_cat_node AFTER INSERT OR UPDATE OF geom1 ON PARENT_SCHEMA.cat_node
FOR EACH ROW EXECUTE PROCEDURE PARENT_SCHEMA.gw_trg_asset_cat_node();

ALTER TABLE am.config_nodecatalog_def DROP CONSTRAINT IF EXISTS config_nodecatalog_def_fk;
ALTER TABLE am.config_nodecatalog_def ADD CONSTRAINT config_nodecatalog_def_fk FOREIGN KEY (nodecat_id)
REFERENCES PARENT_SCHEMA.cat_node (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;

INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES
('config_catalog_def', 'Table to define the catalogs', 'role_om', NULL, '37', 4, 'Config catalog', NULL, NULL, NULL, 'am', NULL),
('config_nodecatalog_def', 'Table to define the node catalogs', 'role_om', NULL, '37', 3, 'Config node catalog', NULL, NULL, NULL, 'am', NULL),
('config_material_def', 'Table to define the materials', 'role_om', NULL, '37', 2, 'Config material', NULL, NULL, NULL, 'am', NULL),
('config_engine_def', 'Table to define engines configuration', 'role_om', NULL, '37', 1, 'Config engine', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;

-- Overlay: parent inventory LEFT JOIN extras. presszone_id is drainzone (dialog filter).
CREATE OR REPLACE VIEW am.ext_ud_arc_asset AS
SELECT
	a.arc_id,
	a.sector_id,
	s.macrosector_id,
	a.drainzone_id::varchar AS drainzone_id,
	a.drainzone_id::varchar AS presszone_id,
	a.builtdate,
	a.arccat_id,
	cat.geom1 AS dnom,
	cat.matcat_id,
	a.function_type,
	a.code,
	a.expl_id,
	a.dma_id,
	ST_Multi(a.the_geom) AS the_geom,
	CASE WHEN a.builtdate IS NULL THEN NULL
		ELSE EXTRACT(YEAR FROM age(CURRENT_DATE, a.builtdate))::numeric END AS age,
	0::numeric AS estimated_cost,
	CASE WHEN a.conserv_state::text ~ '^[1-5]$' THEN (6 - a.conserv_state::integer)::numeric ELSE NULL END AS structural_raw_src,
	CASE WHEN a.om_state::text ~ '^[1-5]$' THEN (6 - a.om_state::integer)::numeric ELSE NULL END AS operational_raw_src,
	(SELECT count(*)::numeric FROM PARENT_SCHEMA.om_visit_x_arc v WHERE v.arc_id = a.arc_id) AS incident_count_src,
	(SELECT count(*)::numeric FROM PARENT_SCHEMA.connec c WHERE c.arc_id = a.arc_id AND c.state = 1) AS dwf_raw_src,
	COALESCE(arc_add.max_flow, 0)::numeric AS storm_raw_src
FROM PARENT_SCHEMA.arc a
	JOIN PARENT_SCHEMA.vf_arc vf ON vf.arc_id = a.arc_id
	JOIN PARENT_SCHEMA.sector s ON s.sector_id = a.sector_id
	JOIN PARENT_SCHEMA.cat_arc cat ON cat.id::text = a.arccat_id::text
	LEFT JOIN PARENT_SCHEMA.arc_add ON arc_add.arc_id = a.arc_id
WHERE a.state = 1;

CREATE OR REPLACE VIEW am.ext_ud_node_asset AS
SELECT
	n.node_id,
	n.sector_id,
	s.macrosector_id,
	n.drainzone_id::varchar AS drainzone_id,
	n.drainzone_id::varchar AS presszone_id,
	n.builtdate,
	n.nodecat_id,
	cn.matcat_id,
	COALESCE(cn.node_type, n.epa_type) AS node_type,
	n.code,
	n.expl_id,
	n.dma_id,
	n.the_geom,
	CASE WHEN n.builtdate IS NULL THEN NULL
		ELSE EXTRACT(YEAR FROM age(CURRENT_DATE, n.builtdate))::numeric END AS age,
	0::numeric AS estimated_cost,
	CASE WHEN n.conserv_state::text ~ '^[1-5]$' THEN (6 - n.conserv_state::integer)::numeric ELSE NULL END AS structural_raw_src,
	CASE WHEN n.om_state::text ~ '^[1-5]$' THEN (6 - n.om_state::integer)::numeric ELSE NULL END AS operational_raw_src,
	(SELECT count(*)::numeric FROM PARENT_SCHEMA.om_visit_x_node v WHERE v.node_id = n.node_id) AS incident_count_src,
	0::numeric AS dwf_raw_src,
	0::numeric AS storm_raw_src
FROM PARENT_SCHEMA.node n
	JOIN PARENT_SCHEMA.vf_node ON vf_node.node_id = n.node_id
	JOIN PARENT_SCHEMA.sector s ON s.sector_id = n.sector_id
	LEFT JOIN PARENT_SCHEMA.cat_node cn ON cn.id::text = n.nodecat_id::text
WHERE n.state = 1;

SET search_path = am, public;

DROP VIEW IF EXISTS v_asset_ud_arc_input CASCADE;
CREATE VIEW v_asset_ud_arc_input AS
SELECT
	a.arc_id,
	COALESCE(i.age, a.age) AS age,
	COALESCE(i.incident_count, a.incident_count_src) AS incident_count,
	COALESCE(i.structural_raw, a.structural_raw_src) AS structural_raw,
	COALESCE(i.operational_raw, a.operational_raw_src) AS operational_raw,
	COALESCE(i.dwf_raw, a.dwf_raw_src) AS dwf_raw,
	COALESCE(i.storm_raw, a.storm_raw_src) AS storm_raw,
	i.strategic,
	i.compliance,
	COALESCE(i.mandatory, false) AS mandatory,
	i.data_quality,
	i.data_quality_obs,
	COALESCE(i.estimated_cost, a.estimated_cost) AS estimated_cost,
	a.arccat_id,
	a.matcat_id,
	a.dnom,
	a.builtdate,
	a.function_type,
	a.expl_id,
	a.macrosector_id,
	a.sector_id,
	a.drainzone_id,
	a.presszone_id,
	a.dma_id,
	a.code,
	a.the_geom
FROM ext_ud_arc_asset a
	LEFT JOIN ud_arc_input i USING (arc_id);

CREATE RULE v_asset_ud_arc_input_update AS ON UPDATE TO v_asset_ud_arc_input
DO INSTEAD
INSERT INTO ud_arc_input (arc_id, mandatory, strategic, incident_count,
	structural_raw, operational_raw, dwf_raw, storm_raw, compliance, estimated_cost)
VALUES (NEW.arc_id, NEW.mandatory, NEW.strategic, NEW.incident_count,
	NEW.structural_raw, NEW.operational_raw, NEW.dwf_raw, NEW.storm_raw, NEW.compliance, NEW.estimated_cost)
ON CONFLICT(arc_id) DO
UPDATE SET mandatory = EXCLUDED.mandatory,
	strategic = EXCLUDED.strategic,
	incident_count = EXCLUDED.incident_count,
	structural_raw = EXCLUDED.structural_raw,
	operational_raw = EXCLUDED.operational_raw,
	dwf_raw = EXCLUDED.dwf_raw,
	storm_raw = EXCLUDED.storm_raw,
	compliance = EXCLUDED.compliance,
	estimated_cost = EXCLUDED.estimated_cost;

DROP VIEW IF EXISTS v_asset_ud_node_input CASCADE;
CREATE VIEW v_asset_ud_node_input AS
SELECT
	a.node_id,
	COALESCE(i.age, a.age) AS age,
	COALESCE(i.incident_count, a.incident_count_src) AS incident_count,
	COALESCE(i.structural_raw, a.structural_raw_src) AS structural_raw,
	COALESCE(i.operational_raw, a.operational_raw_src) AS operational_raw,
	COALESCE(i.dwf_raw, a.dwf_raw_src) AS dwf_raw,
	COALESCE(i.storm_raw, a.storm_raw_src) AS storm_raw,
	i.strategic,
	i.compliance,
	COALESCE(i.mandatory, false) AS mandatory,
	i.data_quality,
	i.data_quality_obs,
	COALESCE(i.estimated_cost, a.estimated_cost) AS estimated_cost,
	a.nodecat_id,
	a.node_type,
	a.builtdate,
	a.expl_id,
	a.macrosector_id,
	a.sector_id,
	a.drainzone_id,
	a.presszone_id,
	a.dma_id,
	a.code,
	a.the_geom
FROM ext_ud_node_asset a
	LEFT JOIN ud_node_input i USING (node_id);

CREATE RULE v_asset_ud_node_input_update AS ON UPDATE TO v_asset_ud_node_input
DO INSTEAD
INSERT INTO ud_node_input (node_id, mandatory, strategic, incident_count,
	structural_raw, operational_raw, dwf_raw, storm_raw, compliance, estimated_cost)
VALUES (NEW.node_id, NEW.mandatory, NEW.strategic, NEW.incident_count,
	NEW.structural_raw, NEW.operational_raw, NEW.dwf_raw, NEW.storm_raw, NEW.compliance, NEW.estimated_cost)
ON CONFLICT(node_id) DO
UPDATE SET mandatory = EXCLUDED.mandatory,
	strategic = EXCLUDED.strategic,
	incident_count = EXCLUDED.incident_count,
	structural_raw = EXCLUDED.structural_raw,
	operational_raw = EXCLUDED.operational_raw,
	dwf_raw = EXCLUDED.dwf_raw,
	storm_raw = EXCLUDED.storm_raw,
	compliance = EXCLUDED.compliance,
	estimated_cost = EXCLUDED.estimated_cost;

GRANT ALL ON TABLE am.ext_ud_arc_asset TO role_basic;
GRANT ALL ON TABLE am.ext_ud_node_asset TO role_basic;
GRANT ALL ON TABLE am.v_asset_ud_arc_input TO role_basic;
GRANT ALL ON TABLE am.v_asset_ud_node_input TO role_basic;

INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_output_compare', 'id', 'role_om', NULL, '35', 7, 'UD Arc Result - Compare', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_output', 'id', 'role_om', NULL, '35', 6, 'UD Arc Result - Main', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_corporate', 'id', 'role_om', NULL, '35', 5, 'UD Arc Corporate Assets', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('ud_arc_output', 'id', 'role_om', NULL, '35', 4, 'UD Arc Assets Result', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "dnomSymbol": "dnom", "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_arc_input', 'id', 'role_om', NULL, '35', 3, 'UD Arc Input Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('ext_ud_arc_asset', 'id', 'role_om', NULL, '35', 1, 'UD Existing Arc Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;

INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_output_compare', 'id', 'role_om', NULL, '36', 5, 'UD Node Result - Compare', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_output', 'id', 'role_om', NULL, '36', 4, 'UD Node Result - Main', NULL, NULL, NULL, 'am', '{"refreshSymbology": true, "allOthers": false, "symbolField": "replacement_year"}')
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, addparam = EXCLUDED.addparam, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_corporate', 'id', 'role_om', NULL, '36', 3, 'UD Node Corporate Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('v_asset_ud_node_input', 'id', 'role_om', NULL, '36', 2, 'UD Node Input Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;
INSERT INTO PARENT_SCHEMA.sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('ext_ud_node_asset', 'id', 'role_om', NULL, '36', 1, 'UD Existing Node Assets', NULL, NULL, NULL, 'am', NULL)
ON CONFLICT (id) DO UPDATE SET context = EXCLUDED.context, orderby = EXCLUDED.orderby, alias = EXCLUDED.alias, "source" = EXCLUDED.source;

-- Reuse WS QML if this AM was already integrated with WS; otherwise layers load unstyled.
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_arc_output', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'v_asset_ws_arc_output' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_arc_output_compare', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'v_asset_ws_arc_output_compare' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_arc_corporate', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'v_asset_ws_arc_corporate' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'ext_ud_arc_asset', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername = 'ext_ws_arc_asset' AND styleconfig_id = 101
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_node_output', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername IN ('v_asset_ws_node_output', 'v_asset_ws_arc_output') AND styleconfig_id = 101
ORDER BY CASE WHEN layername = 'v_asset_ws_node_output' THEN 0 ELSE 1 END
LIMIT 1
ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO PARENT_SCHEMA.sys_style (layername, styleconfig_id, styletype, stylevalue, active)
SELECT 'v_asset_ud_node_output_compare', styleconfig_id, styletype, stylevalue, active
FROM PARENT_SCHEMA.sys_style
WHERE layername IN ('v_asset_ws_node_output_compare', 'v_asset_ws_arc_output_compare') AND styleconfig_id = 101
ORDER BY CASE WHEN layername = 'v_asset_ws_node_output_compare' THEN 0 ELSE 1 END
LIMIT 1
ON CONFLICT (layername, styleconfig_id) DO NOTHING;

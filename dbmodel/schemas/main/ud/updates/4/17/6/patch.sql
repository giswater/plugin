/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Expose graph_delimiter on ve_cat_feature_node (UD was missing it vs WS) (#966)
-- Append graph_delimiter (CREATE OR REPLACE cannot insert a column mid-list)
CREATE OR REPLACE VIEW ve_cat_feature_node
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_node.epa_default,
    cat_feature_node.isarcdivide,
    cat_feature_node.isprofilesurface,
    cat_feature.code_autofill,
    cat_feature_node.choose_hemisphere,
    cat_feature_node.double_geom::text AS double_geom,
    cat_feature_node.num_arcs,
    cat_feature_node.isexitupperintro,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abbreviation,
    cat_feature.custom_code_autofill,
    cat_feature_node.graph_delimiter
   FROM cat_feature
     JOIN cat_feature_node USING (id);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, "datatype", widgettype, "label", tooltip,
	ismandatory, isparent, iseditable, isautoupdate, hidden)
VALUES ('ve_cat_feature_node', 'form_feature', 'tab_none', 'graph_delimiter', 'string', 'text',
	'Graph delimiter:', 'Graph delimiter', false, false, true, false, false)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

-- gw_fct_graphanalytics_omunit (#968) lives in base/fct; applied via reload_fct_ftrg.

-- Recreate UD cat_link like UD cat_arc (was wrongly WS-shaped) (#969)
SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["cat_link"], "batchId":969}}$$);

ALTER TABLE link DROP CONSTRAINT IF EXISTS link_linkcat_id_fkey;

ALTER TABLE cat_link RENAME TO _cat_link_;

ALTER TABLE _cat_link_ DROP CONSTRAINT IF EXISTS cat_link_pkey;
ALTER TABLE _cat_link_ DROP CONSTRAINT IF EXISTS cat_link_linktype_fkey;
ALTER TABLE _cat_link_ DROP CONSTRAINT IF EXISTS cat_link_brand_fkey;
ALTER TABLE _cat_link_ DROP CONSTRAINT IF EXISTS cat_link_cost_fkey;
ALTER TABLE _cat_link_ DROP CONSTRAINT IF EXISTS cat_link_m2bottom_cost_fkey;
ALTER TABLE _cat_link_ DROP CONSTRAINT IF EXISTS cat_link_m3protec_cost_fkey;
ALTER TABLE _cat_link_ DROP CONSTRAINT IF EXISTS cat_link_model_fkey;

DROP INDEX IF EXISTS cat_link_cost_pkey;
DROP INDEX IF EXISTS cat_link_m2bottom_cost_pkey;
DROP INDEX IF EXISTS cat_link_m3protec_cost_pkey;

CREATE TABLE cat_link (
	id varchar(30) NOT NULL,
	link_type varchar(30) NOT NULL,
	matcat_id varchar(16) NULL,
	shape varchar(16) NOT NULL DEFAULT 'CIRCULAR',
	geom1 numeric(12, 4) NULL,
	geom2 numeric(12, 4) DEFAULT 0.00 NULL,
	geom3 numeric(12, 4) DEFAULT 0.00 NULL,
	geom4 numeric(12, 4) DEFAULT 0.00 NULL,
	geom5 numeric(12, 4) NULL,
	geom6 numeric(12, 4) NULL,
	geom7 numeric(12, 4) NULL,
	geom8 numeric(12, 4) NULL,
	geom_r varchar(20) NULL,
	descript varchar(255) NULL,
	link varchar(512) NULL,
	brand_id varchar(30) NULL,
	model_id varchar(30) NULL,
	svg varchar(50) NULL,
	z1 numeric(12, 2) NULL,
	z2 numeric(12, 2) NULL,
	width numeric(12, 2) NULL,
	area numeric(12, 4) NULL,
	estimated_depth numeric(12, 2) NULL,
	thickness numeric(12, 2) NULL,
	cost_unit varchar(3) DEFAULT 'm'::character varying NULL,
	"cost" varchar(16) NULL,
	m2bottom_cost varchar(16) NULL,
	m3protec_cost varchar(16) NULL,
	active bool DEFAULT true NULL,
	"label" varchar(255) NULL,
	tsect_id varchar(16) NULL,
	curve_id varchar(16) NULL,
	acoeff float8 NULL,
	connect_cost text NULL,
	visitability_vdef int4 NULL,
	code text NULL,
	CONSTRAINT cat_link_pkey PRIMARY KEY (id),
	CONSTRAINT cat_link_linktype_fkey FOREIGN KEY (link_type) REFERENCES cat_feature_link(id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT cat_link_cost_fkey FOREIGN KEY ("cost") REFERENCES plan_price(id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT cat_link_curve_id_fkey FOREIGN KEY (curve_id) REFERENCES inp_curve(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT cat_link_m2bottom_cost_fkey FOREIGN KEY (m2bottom_cost) REFERENCES plan_price(id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT cat_link_m3protec_cost_fkey FOREIGN KEY (m3protec_cost) REFERENCES plan_price(id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT cat_link_shape_id_fkey FOREIGN KEY (shape) REFERENCES cat_arc_shape(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT cat_link_tsect_id_fkey FOREIGN KEY (tsect_id) REFERENCES inp_transects(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT cat_link_brand_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT cat_link_model_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX cat_link_cost_idx ON cat_link USING btree (cost);
CREATE INDEX cat_link_m2bottom_cost_idx ON cat_link USING btree (m2bottom_cost);
CREATE INDEX cat_link_m3protec_cost_idx ON cat_link USING btree (m3protec_cost);

INSERT INTO cat_link (
	id, link_type, matcat_id, descript, link, brand_id, model_id, svg,
	z1, z2, width, area, estimated_depth, thickness, cost_unit, "cost",
	m2bottom_cost, m3protec_cost, active, "label", code
)
SELECT
	id, link_type, matcat_id::varchar(16), descript::varchar(255), link,
	brand_id::varchar(30), model_id::varchar(30), svg,
	z1, z2, width, area, estimated_depth, thickness, cost_unit, "cost",
	m2bottom_cost, m3protec_cost, active, "label", code
FROM _cat_link_;

ALTER TABLE link ADD CONSTRAINT link_linkcat_id_fkey
	FOREIGN KEY (linkcat_id) REFERENCES cat_link(id) ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TRIGGER gw_trg_cat_material_fk_insert AFTER INSERT ON cat_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_material_fk('link');
CREATE TRIGGER gw_trg_cat_material_fk_update AFTER UPDATE OF matcat_id ON cat_link
FOR EACH ROW WHEN (((OLD.matcat_id)::TEXT IS DISTINCT FROM (NEW.matcat_id)::TEXT))
EXECUTE FUNCTION gw_trg_cat_material_fk('link');

-- Restore dependents; rewrite WS diameter columns to UD geom columns in saved defs
SELECT gw_fct_admin_manage_view_dependencies($${"data":{
	"action":"RESTORE",
	"batchId":969,
	"replacements":[
		{"from":"cat_link.dnom AS cat_dnom,\n    cat_link.dint AS cat_dint,\n    cat_link.pnom AS cat_pnom","to":"cat_link.geom1 AS cat_geom1,\n    cat_link.geom2 AS cat_geom2"},
		{"from":"ve_link.cat_dnom,\n    ve_link.cat_dint,\n    ve_link.cat_pnom","to":"ve_link.cat_geom1,\n    ve_link.cat_geom2"}
	]
}}$$);

-- Form fields: drop WS diameter columns, add UD geom/shape columns (#969)
ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_config_control;

DELETE FROM config_form_fields
WHERE formname = 'cat_link' AND formtype = 'form_feature' AND tabname = 'tab_none'
	AND columnname IN ('pnom', 'dnom', 'dint', 'dext');

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, "datatype", widgettype, "label", tooltip,
	ismandatory, isparent, iseditable, isautoupdate, dv_querytext, dv_orderby_id, dv_isnullvalue, widgetcontrols, hidden)
VALUES
	('cat_link', 'form_feature', 'tab_none', 'shape', 'string', 'combo', 'Shape:', 'Shape', false, false, true, false,
		'SELECT id, id AS idval FROM cat_arc_shape WHERE id IS NOT NULL', true, false,
		'{"setMultiline": false, "valueRelation":{"nullValue":true, "layer": "cat_arc_shape", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": ""}}'::json, false),
	('cat_link', 'form_feature', 'tab_none', 'geom1', 'double', 'text', 'Geom1:', 'Geom1', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom2', 'double', 'text', 'Geom2:', 'Geom2', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom3', 'double', 'text', 'Geom3:', 'Geom3', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom4', 'double', 'text', 'Geom4:', 'Geom4', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom5', 'double', 'text', 'Geom5:', 'Geom5', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom6', 'double', 'text', 'Geom6:', 'Geom6', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom7', 'double', 'text', 'Geom7:', 'Geom7', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom8', 'double', 'text', 'Geom8:', 'Geom8', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'geom_r', 'string', 'text', 'Geom r:', 'Geom r', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'tsect_id', 'string', 'combo', 'Tsect id:', 'Tsect id', false, false, true, false,
		'SELECT id, id AS idval FROM inp_transects WHERE id IS NOT NULL', true, false, '{"setMultiline":false}'::json, false),
	('cat_link', 'form_feature', 'tab_none', 'curve_id', 'string', 'combo', 'Curve id:', 'Curve id', false, false, true, false,
		'SELECT id, id AS idval FROM inp_curve WHERE id IS NOT NULL', true, true,
		'{"setMultiline":false,"valueRelation":{"nullValue":true, "layer": "ve_inp_curve", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": ""}}'::json, false),
	('cat_link', 'form_feature', 'tab_none', 'acoeff', 'double', 'text', 'Acoeff:', 'Acoeff', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'connect_cost', 'string', 'text', 'Connect cost:', 'Connect cost', false, false, true, false, NULL, NULL, NULL, NULL, false),
	('cat_link', 'form_feature', 'tab_none', 'visitability_vdef', 'integer', 'text', 'Visitability:', 'Visitability', false, false, true, false, NULL, NULL, NULL, NULL, false)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

DELETE FROM config_form_fields
WHERE formname = 'upsert_catalog_link' AND formtype = 'form_catalog' AND tabname = 'tab_none'
	AND columnname IN ('pnom', 'dnom');

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip,
	ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id,
	dv_querytext_filterc, widgetcontrols, hidden)
VALUES
	('upsert_catalog_link', 'form_catalog', 'tab_none', 'shape', 'lyt_data_1', 2, 'string', 'combo', 'Shape:', 'Shape',
		false, false, true, false, NULL, 'SELECT DISTINCT(shape) AS id, shape AS idval FROM cat_link WHERE id IS NOT NULL', true, false, 'matcat_id',
		' AND cat_link.matcat_id', '{"setMultiline":false}'::json, false),
	('upsert_catalog_link', 'form_catalog', 'tab_none', 'geom1', 'lyt_data_1', 3, 'string', 'combo', 'Geom1:', 'Geom1',
		false, false, true, false, NULL, 'SELECT DISTINCT(geom1::text) AS id, geom1::text AS idval FROM cat_link WHERE id IS NOT NULL', true, false, 'matcat_id',
		' AND cat_link.matcat_id', '{"setMultiline":false}'::json, false)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_config_control;

UPDATE config_form_tableview SET columnname = 'cat_geom1', alias = 'Cat geom1'
WHERE objectname = 've_link' AND columnname = 'cat_dnom';
UPDATE config_form_tableview SET columnname = 'cat_geom2', alias = 'Cat geom2'
WHERE objectname = 've_link' AND columnname = 'cat_dint';
DELETE FROM config_form_tableview
WHERE objectname = 've_link' AND columnname = 'cat_pnom';

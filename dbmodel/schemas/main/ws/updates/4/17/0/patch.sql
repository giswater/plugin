/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

ALTER TABLE inp_dscenario_connec ADD observ text NULL;
ALTER TABLE inp_dscenario_demand ADD observ text NULL;
ALTER TABLE inp_dscenario_frshortpipe ADD observ text NULL;
ALTER TABLE inp_dscenario_frvalve ADD observ text NULL;
ALTER TABLE inp_dscenario_pipe ADD observ text NULL;
ALTER TABLE inp_dscenario_pump ADD observ text NULL;
ALTER TABLE inp_dscenario_pump_additional ADD observ text NULL;
ALTER TABLE inp_dscenario_reservoir ADD observ text NULL;
ALTER TABLE inp_dscenario_rules ADD observ text NULL;
ALTER TABLE inp_dscenario_shortpipe ADD observ text NULL;
ALTER TABLE inp_dscenario_tank ADD observ text NULL;
ALTER TABLE inp_dscenario_valve ADD observ text NULL;
ALTER TABLE inp_dscenario_virtualpump ADD observ text NULL;
ALTER TABLE inp_dscenario_virtualvalve ADD observ text NULL;


CREATE OR REPLACE VIEW ve_inp_dscenario_connec
AS SELECT d.dscenario_id,
    connec.connec_id,
    connec.pjoint_type,
    connec.pjoint_id,
    c.demand,
    c.pattern_id,
    c.peak_factor,
    c.status,
    c.minorloss,
    c.custom_roughness,
    c.custom_length,
    c.custom_dint,
    c.emitter_coeff,
    c.init_quality,
    c.source_type,
    c.source_quality,
    c.source_pattern_id,
    connec.the_geom,
    c.observ
   FROM ve_inp_connec connec
     JOIN inp_dscenario_connec c USING (connec_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = c.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_controls
AS SELECT i.id,
    d.dscenario_id,
    i.sector_id,
    i.text,
    i.active,
    i.observ
   FROM selector_inp_dscenario,
    inp_dscenario_controls i
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE i.dscenario_id = selector_inp_dscenario.dscenario_id AND selector_inp_dscenario.cur_user = "current_user"()::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_demand
AS SELECT idd.id,
    idd.dscenario_id,
    idd.feature_id,
    idd.feature_type,
    idd.demand,
    idd.pattern_id,
    idd.demand_type,
    idd.source,
    n.sector_id,
    n.expl_id,
    n.presszone_id,
    n.dma_id,
    n.the_geom,
    idd.observ
   FROM inp_dscenario_demand idd
     JOIN node n ON n.node_id = idd.feature_id
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = idd.dscenario_id AND s.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_sector s
          WHERE s.sector_id = n.sector_id AND s.cur_user = CURRENT_USER))
UNION
 SELECT idd.id,
    idd.dscenario_id,
    idd.feature_id,
    idd.feature_type,
    idd.demand,
    idd.pattern_id,
    idd.demand_type,
    idd.source,
    c.sector_id,
    c.expl_id,
    c.presszone_id,
    c.dma_id,
    c.the_geom,
    idd.observ
   FROM inp_dscenario_demand idd
     JOIN connec c ON c.connec_id = idd.feature_id
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = idd.dscenario_id AND s.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_sector s
          WHERE s.sector_id = c.sector_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_frpump
AS SELECT s.dscenario_id,
    f.element_id,
    n.node_id,
    f.power,
    f.curve_id,
    f.speed,
    f.pattern_id,
    f.effic_curve_id,
    f.energy_price,
    f.energy_pattern_id,
    f.status,
    n.the_geom,
    f.observ
   FROM selector_inp_dscenario s,
    inp_dscenario_frpump f
     JOIN ve_inp_frpump n USING (element_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_frshortpipe
AS SELECT s.dscenario_id,
    p.element_id,
    n.node_id,
    p.minorloss,
    p.bulk_coeff,
    p.wall_coeff,
    p.custom_dint,
    p.status,
    n.the_geom,
    p.observ
   FROM selector_inp_dscenario s,
    inp_dscenario_frshortpipe p
     JOIN ve_inp_frshortpipe n ON n.element_id = p.element_id
  WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_frvalve
AS SELECT s.dscenario_id,
    v.element_id,
    n.node_id,
    v.valve_type,
    v.custom_dint,
    v.setting,
    v.curve_id,
    v.minorloss,
    v.add_settings,
    v.init_quality,
    n.the_geom,
    v.observ
   FROM selector_inp_dscenario s,
    inp_dscenario_frvalve v
     JOIN ve_inp_frvalve n ON n.element_id = v.element_id
  WHERE s.dscenario_id = v.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_inlet
AS SELECT p.dscenario_id,
    n.node_id,
    p.initlevel,
    p.minlevel,
    p.maxlevel,
    p.diameter,
    p.minvol,
    p.curve_id,
    p.overflow,
    p.mixing_model,
    p.mixing_fraction,
    p.reaction_coeff,
    p.init_quality,
    p.source_type,
    p.source_quality,
    p.source_pattern_id,
    p.head,
    p.pattern_id,
    p.demand,
    p.demand_pattern_id,
    p.emitter_coeff,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_inlet p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;


CREATE OR REPLACE VIEW ve_inp_dscenario_junction
AS SELECT p.dscenario_id,
    p.node_id,
    p.demand,
    p.pattern_id,
    p.emitter_coeff,
    p.init_quality,
    p.source_type,
    p.source_quality,
    p.source_pattern_id,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_junction p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_pipe
AS SELECT d.dscenario_id,
    p.arc_id,
    p.minorloss,
    p.status,
    p.roughness,
    p.dint,
    p.bulk_coeff,
    p.wall_coeff,
    a.the_geom,
    p.observ
   FROM ve_arc a
     JOIN inp_dscenario_pipe p USING (arc_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND a.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_pump
AS SELECT d.dscenario_id,
    p.node_id,
    p.power,
    p.curve_id,
    p.speed,
    p.pattern_id,
    p.status,
    p.effic_curve_id,
    p.energy_price,
    p.energy_pattern_id,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_pump p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_pump_additional
AS SELECT d.dscenario_id,
    p.node_id,
    p.order_id,
    p.power,
    p.curve_id,
    p.speed,
    p.pattern_id,
    p.status,
    p.effic_curve_id,
    p.energy_price,
    p.energy_pattern_id,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_pump_additional p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_reservoir
AS SELECT d.dscenario_id,
    p.node_id,
    p.pattern_id,
    p.head,
    p.init_quality,
    p.source_type,
    p.source_quality,
    p.source_pattern_id,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_reservoir p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_rules
AS SELECT i.id,
    d.dscenario_id,
    i.sector_id,
    i.text,
    i.active,
    i.observ
   FROM inp_dscenario_rules i
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = i.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_shortpipe
AS SELECT d.dscenario_id,
    p.node_id,
    p.minorloss,
    p.status,
    p.bulk_coeff,
    p.wall_coeff,
    p.to_arc,
    p.head,
    p.pattern_id,
    p.demand,
    p.demand_pattern_id,
    p.emitter_coeff,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_shortpipe p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_tank
AS SELECT d.dscenario_id,
    p.node_id,
    p.initlevel,
    p.minlevel,
    p.maxlevel,
    p.diameter,
    p.minvol,
    p.curve_id,
    p.overflow,
    p.mixing_model,
    p.mixing_fraction,
    p.reaction_coeff,
    p.init_quality,
    p.source_type,
    p.source_quality,
    p.source_pattern_id,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_tank p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_valve
AS SELECT d.dscenario_id,
    p.node_id,
    concat(p.node_id, '_n2a') AS nodarc_id,
    p.valve_type,
    p.setting,
    p.curve_id,
    p.minorloss,
    p.status,
    p.add_settings,
    p.init_quality,
    p.to_arc,
    p.head,
    p.pattern_id,
    p.demand,
    p.demand_pattern_id,
    p.emitter_coeff,
    n.the_geom,
    p.observ
   FROM ve_node n
     JOIN inp_dscenario_valve p USING (node_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND n.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_dscenario_virtualpump
AS SELECT v.dscenario_id,
    p.arc_id,
    v.power,
    v.curve_id,
    v.speed,
    v.pattern_id,
    v.status,
    v.pump_type,
    v.effic_curve_id,
    v.energy_price,
    v.energy_pattern_id,
    p.the_geom,
    v.observ
   FROM ve_inp_virtualpump p
     JOIN inp_dscenario_virtualpump v USING (arc_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = v.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_virtualvalve
AS SELECT d.dscenario_id,
    p.arc_id,
    p.valve_type,
    p.diameter,
    p.setting,
    p.curve_id,
    p.minorloss,
    p.status,
    p.init_quality,
    a.the_geom,
    p.observ
   FROM ve_arc a
     JOIN inp_dscenario_virtualvalve p USING (arc_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER)) AND a.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_cat_feature_arc
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_arc.epa_default,
    cat_feature.code_autofill,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation,
    cat_feature.custom_code_autofill
   FROM cat_feature
     JOIN cat_feature_arc USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_connec
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_connec.epa_default,
    cat_feature.code_autofill,
    cat_feature_connec.double_geom::text AS double_geom,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation,
    cat_feature.custom_code_autofill
   FROM cat_feature
     JOIN cat_feature_connec USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_element
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_element.epa_default,
    cat_feature.code_autofill,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation,
    cat_feature.custom_code_autofill
   FROM cat_feature
     JOIN cat_feature_element USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_link
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature.code_autofill,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation,
    cat_feature.custom_code_autofill
   FROM cat_feature
     JOIN cat_feature_link USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_node
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_node.epa_default,
    cat_feature_node.isarcdivide,
    cat_feature_node.isprofilesurface,
    cat_feature_node.choose_hemisphere,
    cat_feature.code_autofill,
    cat_feature_node.double_geom::text AS double_geom,
    cat_feature_node.num_arcs,
    cat_feature_node.graph_delimiter,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation,
    cat_feature.custom_code_autofill
   FROM cat_feature
     JOIN cat_feature_node USING (id);

DO $$
BEGIN
  IF lower((SELECT language FROM sys_version LIMIT 1)) NOT ILIKE 'es_%' OR (SELECT language FROM sys_version LIMIT 1) IS NULL THEN
    UPDATE config_form_fields
      SET "label"='Pattern:',tooltip='Pattern'
      WHERE formname='ve_epa_shortpipe' AND formtype='form_feature' AND columnname='pattern_id' AND tabname='tab_epa' AND "label"='Patrón:';
    UPDATE config_form_fields
      SET "label"='Pattern:',tooltip='Pattern'
      WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='pattern_id' AND tabname='tab_epa' AND "label"='Patrón:';
    UPDATE config_form_fields
      SET "label"='Head:',tooltip='Head'
      WHERE formname='ve_epa_shortpipe' AND formtype='form_feature' AND columnname='head' AND tabname='tab_epa' AND "label"='Carga hidráulica:';
    UPDATE config_form_fields
      SET "label"='Head:',tooltip='Head'
      WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='head' AND tabname='tab_epa' AND "label"='Carga hidráulica:';
    UPDATE config_form_fields
      SET "label"='Emitter coefficient:',tooltip='Emitter coefficient'
      WHERE formname='ve_epa_shortpipe' AND formtype='form_feature' AND columnname='emitter_coeff' AND tabname='tab_epa' AND "label"='Coeficiente emisor:';
    UPDATE config_form_fields
      SET "label"='Emitter coefficient:',tooltip='Emitter coefficient'
      WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='emitter_coeff' AND tabname='tab_epa' AND "label"='Coeficiente emisor:';
    UPDATE config_form_fields
      SET "label"='Pattern id:',tooltip='Pattern id'
      WHERE formname='ve_epa_shortpipe' AND formtype='form_feature' AND columnname='demand_pattern_id' AND tabname='tab_epa' AND "label"='Id del patrón:';
    UPDATE config_form_fields
      SET "label"='Pattern id:',tooltip='Pattern id'
      WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='demand_pattern_id' AND tabname='tab_epa' AND "label"='Id del patrón:';
    UPDATE config_form_fields
      SET "label"='Demand:',tooltip='demand - Water demand'
      WHERE formname='ve_epa_shortpipe' AND formtype='form_feature' AND columnname='demand' AND tabname='tab_epa' AND "label"='Demanda:';
    UPDATE config_form_fields
      SET "label"='Demand:',tooltip='demand - Water demand'
      WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='demand' AND tabname='tab_epa' AND "label"='Demanda:';
  END IF;
END $$;

CREATE OR REPLACE VIEW v_om_visit AS
SELECT DISTINCT ON (visit_id)
	visit_id,
	code,
	visitcat_id,
	name,
	visit_start,
	visit_end,
	user_name,
	is_done,
	feature_id,
	feature_type,
	the_geom::geometry(Point, SRID_VALUE) AS the_geom
FROM (
	SELECT
		om_visit.id AS visit_id,
		om_visit.ext_code AS code,
		om_visit.visitcat_id,
		om_visit_cat.name,
		om_visit.startdate AS visit_start,
		om_visit.enddate AS visit_end,
		om_visit.user_name,
		om_visit.is_done,
		om_visit_x_node.node_id AS feature_id,
		'NODE'::text AS feature_type,
		CASE
			WHEN om_visit.the_geom IS NULL THEN node.the_geom
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_node ON om_visit_x_node.visit_id = om_visit.id
	JOIN node ON node.node_id = om_visit_x_node.node_id
	JOIN vf_node vf ON vf.node_id = node.node_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
	UNION
	SELECT
		om_visit.id AS visit_id,
		om_visit.ext_code AS code,
		om_visit.visitcat_id,
		om_visit_cat.name,
		om_visit.startdate AS visit_start,
		om_visit.enddate AS visit_end,
		om_visit.user_name,
		om_visit.is_done,
		om_visit_x_arc.arc_id AS feature_id,
		'ARC'::text AS feature_type,
		CASE
			WHEN om_visit.the_geom IS NULL THEN st_lineinterpolatepoint(arc.the_geom, 0.5::double precision)
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_arc ON om_visit_x_arc.visit_id = om_visit.id
	JOIN arc ON arc.arc_id = om_visit_x_arc.arc_id
	JOIN vf_arc vf ON vf.arc_id = arc.arc_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
	UNION
	SELECT
		om_visit.id AS visit_id,
		om_visit.ext_code AS code,
		om_visit.visitcat_id,
		om_visit_cat.name,
		om_visit.startdate AS visit_start,
		om_visit.enddate AS visit_end,
		om_visit.user_name,
		om_visit.is_done,
		om_visit_x_connec.connec_id AS feature_id,
		'CONNEC'::text AS feature_type,
		CASE
			WHEN om_visit.the_geom IS NULL THEN connec.the_geom
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_connec ON om_visit_x_connec.visit_id = om_visit.id
	JOIN connec ON connec.connec_id = om_visit_x_connec.connec_id
	JOIN vf_connec vf ON vf.connec_id = connec.connec_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
) a;

-- Drop denormalized node fields from arc; compute them in ve_arc via JOIN
DROP TRIGGER IF EXISTS gw_trg_arc_node_values ON arc;

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["ve_arc", "v_edit_arc"], "batchId":17}}$$);

CREATE OR REPLACE VIEW ve_arc
AS WITH typevalue AS (
         SELECT edit_typevalue.typevalue,
            edit_typevalue.id,
            edit_typevalue.idval
           FROM edit_typevalue
          WHERE edit_typevalue.typevalue::text = ANY (ARRAY['sector_type'::text, 'presszone_type'::text, 'dma_type'::text, 'dqa_type'::text, 'supplyzone_type'::text, 'omzone_type'::text])
        ), sector_table AS (
         SELECT sector.sector_id,
            sector.macrosector_id,
            sector.stylesheet,
            t.id AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), dma_table AS (
         SELECT dma.dma_id,
            dma.macrodma_id,
            dma.stylesheet,
            t.id AS dma_type
           FROM dma
             LEFT JOIN typevalue t ON t.id::text = dma.dma_type::text AND t.typevalue::text = 'dma_type'::text
        ), presszone_table AS (
         SELECT presszone.presszone_id,
            presszone.head AS presszone_head,
            presszone.stylesheet,
            t.id AS presszone_type
           FROM presszone
             LEFT JOIN typevalue t ON t.id::text = presszone.presszone_type AND t.typevalue::text = 'presszone_type'::text
        ), dqa_table AS (
         SELECT dqa.dqa_id,
            dqa.stylesheet,
            t.id AS dqa_type,
            dqa.macrodqa_id
           FROM dqa
             LEFT JOIN typevalue t ON t.id::text = dqa.dqa_type::text AND t.typevalue::text = 'dqa_type'::text
        ), supplyzone_table AS (
         SELECT supplyzone.supplyzone_id,
            supplyzone.stylesheet,
            t.id AS supplyzone_type
           FROM supplyzone
             LEFT JOIN typevalue t ON t.id::text = supplyzone.supplyzone_type::text AND t.typevalue::text = 'supplyzone_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            t.id AS omzone_type,
            omzone.macroomzone_id
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        )
 SELECT a.arc_id,
    a.code,
    a.sys_code,
    a.node_1,
    cn1.node_type AS nodetype_1,
    n1.top_elev AS elevation1,
    n1.depth AS depth1,
    n1.staticpressure AS staticpressure1,
    a.node_2,
    cn2.node_type AS nodetype_2,
    n2.staticpressure AS staticpressure2,
    n2.top_elev AS elevation2,
    n2.depth AS depth2,
    ((COALESCE(n1.depth, 0::numeric) + COALESCE(n2.depth, 0::numeric)) / 2::numeric)::numeric(12,2) AS depth,
    cat_arc.arc_type,
    a.arccat_id,
    cat_feature.feature_class AS sys_type,
    cat_arc.matcat_id AS cat_matcat_id,
    cat_arc.pnom AS cat_pnom,
    cat_arc.dnom AS cat_dnom,
    cat_arc.dint AS cat_dint,
    cat_arc.dr AS cat_dr,
    a.epa_type,
    a.state,
    a.state_type,
    a.parent_id,
    a.expl_id,
    exploitation.macroexpl_id,
    a.muni_id,
    a.sector_id,
    sector_table.macrosector_id,
    sector_table.sector_type,
    a.supplyzone_id,
    supplyzone_table.supplyzone_type,
    a.presszone_id,
    presszone_table.presszone_type,
    presszone_table.presszone_head,
    a.dma_id,
    dma_table.macrodma_id,
    dma_table.dma_type,
    a.dqa_id,
    dqa_table.macrodqa_id,
    dqa_table.dqa_type,
    a.omzone_id,
    omzone_table.macroomzone_id,
    omzone_table.omzone_type,
    a.minsector_id,
    a.pavcat_id,
    a.soilcat_id,
    a.function_type,
    a.category_type,
    a.location_type,
    a.fluid_type,
    a.descript,
    st_length2d(a.the_geom)::numeric(12,2) AS gis_length,
    a.custom_length,
    a.annotation,
    a.observ,
    a.comment,
    concat(cat_feature.link_path, a.link) AS link,
    a.num_value,
    a.district_id,
    a.postcode,
    a.streetaxis_id,
    a.postnumber,
    a.postcomplement,
    a.streetaxis2_id,
    a.postnumber2,
    a.postcomplement2,
    vm.region_id,
    vm.province_id,
    a.workcat_id,
    a.workcat_id_end,
    a.workcat_id_plan,
    a.builtdate,
    a.enddate,
    a.ownercat_id,
    a.om_state,
    a.conserv_state,
    COALESCE(a.brand_id, cat_arc.brand_id) AS brand_id,
    COALESCE(a.model_id, cat_arc.model_id) AS model_id,
    a.serial_number,
    a.asset_id,
    a.adate,
    a.adescript,
    a.verified,
    a.datasource,
    cat_arc.label,
    a.label_x,
    a.label_y,
    a.label_rotation,
    a.label_quadrant,
    a.inventory,
    a.publish,
    vst.is_operative,
    a.is_scadamap,
        CASE
            WHEN a.sector_id > 0 AND vst.is_operative = true AND a.epa_type::text <> 'UNDEFINED'::text THEN a.epa_type::text
            ELSE NULL::text
        END AS inp_type,
    arc_add.result_id,
    arc_add.flow_max,
    arc_add.flow_min,
    arc_add.flow_avg,
    arc_add.vel_max,
    arc_add.vel_min,
    arc_add.vel_avg,
    arc_add.tot_headloss_max,
    arc_add.tot_headloss_min,
    arc_add.mincut_connecs,
    arc_add.mincut_hydrometers,
    arc_add.mincut_length,
    arc_add.mincut_watervol,
    arc_add.mincut_criticality,
    arc_add.hydraulic_criticality,
    arc_add.pipe_capacity,
    arc_add.mincut_impact_topo,
    arc_add.mincut_impact_hydro,
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    dma_table.stylesheet ->> 'featureColor'::text AS dma_style,
    presszone_table.stylesheet ->> 'featureColor'::text AS presszone_style,
    dqa_table.stylesheet ->> 'featureColor'::text AS dqa_style,
    supplyzone_table.stylesheet ->> 'featureColor'::text AS supplyzone_style,
    a.lock_level,
    a.expl_visibility,
    date_trunc('second'::text, a.created_at) AS created_at,
    a.created_by,
    date_trunc('second'::text, a.updated_at) AS updated_at,
    a.updated_by,
    a.the_geom,
    vf.p_state,
    a.uuid,
    a.uncertain,
    a.dataquality,
    a.dataquality_obs
   FROM arc a
     JOIN vf_arc vf ON vf.arc_id = a.arc_id
     JOIN cat_arc ON cat_arc.id::text = a.arccat_id::text
     JOIN cat_feature ON cat_feature.id::text = cat_arc.arc_type::text
     JOIN exploitation ON a.expl_id = exploitation.expl_id
     JOIN v_municipality vm ON a.muni_id = vm.muni_id
     JOIN sector_table ON sector_table.sector_id = a.sector_id
     LEFT JOIN node n1 ON n1.node_id = a.node_1
     LEFT JOIN cat_node cn1 ON cn1.id::text = n1.nodecat_id::text
     LEFT JOIN node n2 ON n2.node_id = a.node_2
     LEFT JOIN cat_node cn2 ON cn2.id::text = n2.nodecat_id::text
     LEFT JOIN presszone_table ON presszone_table.presszone_id = a.presszone_id
     LEFT JOIN dma_table ON dma_table.dma_id = a.dma_id
     LEFT JOIN dqa_table ON dqa_table.dqa_id = a.dqa_id
     LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = a.supplyzone_id
     LEFT JOIN omzone_table ON omzone_table.omzone_id = a.omzone_id
     LEFT JOIN arc_add ON arc_add.arc_id = a.arc_id
     LEFT JOIN value_state_type vst ON vst.id = a.state_type;

-- Legacy view still selected denorm cols from arc (4/2); alias to ve_arc
CREATE OR REPLACE VIEW v_edit_arc AS SELECT * FROM ve_arc;

DROP FUNCTION IF EXISTS gw_trg_arc_node_values();

SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"nodetype_1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"elevation1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"depth1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"staticpressure1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"nodetype_2"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"elevation2"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"depth2"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"staticpressure2"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"nodetype_1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"elevation1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"depth1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"staticpressure1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"nodetype_2"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"elevation2"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"depth2"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"archived_psector_arc", "column":"staticpressure2"}}$$);

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":17}}$$);

CREATE TRIGGER gw_trg_edit_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_arc('parent');

CREATE TRIGGER gw_trg_edit_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON
v_edit_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_arc('parent');

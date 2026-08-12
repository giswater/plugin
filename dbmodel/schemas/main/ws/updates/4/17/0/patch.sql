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
DROP VIEW IF EXISTS v_om_visit;
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
	the_geom
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

UPDATE sys_fprocess SET query_text='WITH base AS (
    SELECT l.link_id, l.feature_type, l.exit_type, l.the_geom AS link_geom,
           c.connec_id, c.conneccat_id, c.the_geom AS connec_geom,
           c.expl_id, c.arc_id AS connec_arc_id
    FROM t_link l
    JOIN t_connec c ON l.feature_id = c.connec_id
    WHERE l.feature_type = ''CONNEC''
      AND l.state = 1
      AND c.state = 1
),
matched_arc AS (
    SELECT DISTINCT b.link_id
    FROM base b
    JOIN t_arc a ON ST_DWithin(a.the_geom, ST_EndPoint(b.link_geom), 0.01)
    WHERE b.exit_type = ''ARC''
      AND a.state = 1
      AND (a.arc_id <> b.connec_arc_id OR b.connec_arc_id IS NULL)
),
matched_node AS (
    SELECT DISTINCT b.link_id
    FROM base b
    JOIN t_node n ON ST_DWithin(n.the_geom, ST_EndPoint(b.link_geom), 0.01)
    WHERE b.exit_type IN (''NODE'', ''ARC'')
      AND n.state = 1
)
SELECT b.connec_id, b.conneccat_id, b.connec_geom AS the_geom,
       b.expl_id, b.feature_type, b.link_id
FROM base b
JOIN matched_arc ma ON ma.link_id = b.link_id
WHERE NOT EXISTS (
    SELECT 1 FROM matched_node mn WHERE mn.link_id = b.link_id
)
ORDER BY b.feature_type, b.link_id' WHERE fid=257;

DROP VIEW IF EXISTS v_ui_rpt_cat_result;
CREATE OR REPLACE VIEW v_ui_rpt_cat_result AS
SELECT DISTINCT ON (rpt_cat_result.result_id)
	rpt_cat_result.result_id,
	e.exploitation_names AS expl_id,
	rpt_cat_result.sector_id,
  rpt_cat_result.dma_id,
	t2.idval AS network_type,
	t1.idval AS status,
	rpt_cat_result.iscorporate,
	rpt_cat_result.descript,
	rpt_cat_result.exec_date,
	rpt_cat_result.cur_user,
	rpt_cat_result.export_options,
	rpt_cat_result.network_stats,
	rpt_cat_result.inp_options,
	rpt_cat_result.rpt_stats,
	rpt_cat_result.addparam
FROM rpt_cat_result
	JOIN selector_expl s ON (s.expl_id = ANY(rpt_cat_result.expl_id) AND s.cur_user = CURRENT_USER) OR rpt_cat_result.expl_id = ARRAY[NULL::integer]
	LEFT JOIN inp_typevalue t1 ON rpt_cat_result.status::text = t1.id::text
	LEFT JOIN inp_typevalue t2 ON rpt_cat_result.network_type = t2.id
	LEFT JOIN LATERAL (
		SELECT array_agg(ex.name) AS exploitation_names
		FROM unnest(rpt_cat_result.expl_id) AS x(expl_id)
		JOIN exploitation ex ON ex.expl_id = x.expl_id
	) e ON true
WHERE t1.typevalue = 'inp_result_status'
AND t2.typevalue = 'inp_options_networkmode';

CREATE TRIGGER gw_trg_ui_rpt_cat_result INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_rpt_cat_result
FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_rpt_cat_result();

UPDATE config_param_system
	SET layoutorder=12
	WHERE "parameter"='admin_crm_schema';
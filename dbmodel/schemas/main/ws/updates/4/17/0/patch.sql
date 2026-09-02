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
    cat_feature.abbreviation,
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
    cat_feature.abbreviation,
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
    cat_feature.abbreviation,
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
    cat_feature.abbreviation,
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
    cat_feature.abbreviation,
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



CREATE OR REPLACE VIEW vf_link AS
SELECT
  l.link_id,
  pp.state AS p_state
FROM
  link l
  LEFT JOIN LATERAL (
    SELECT
      x.connec_id,
      x.psector_id
    FROM
      (
        SELECT
          1
        WHERE
          (
            EXISTS (
              SELECT
                1
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
      ) gate
      CROSS JOIN LATERAL (
        SELECT
          pp1.connec_id,
          pp1.psector_id
        FROM
          plan_psector_x_connec pp1
        WHERE
          pp1.connec_id = l.feature_id
          AND (
            pp1.psector_id IN (
              SELECT
                sp.psector_id
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
        ORDER BY
          pp1.psector_id DESC
        LIMIT
          1
      ) x
  ) last_ps ON TRUE
  LEFT JOIN LATERAL (
    SELECT
      x.state
    FROM
      (
        SELECT
          1
        WHERE
          last_ps.psector_id IS NOT NULL
      ) gate
      CROSS JOIN LATERAL (
        SELECT
          pp2.state
        FROM
          plan_psector_x_connec pp2
        WHERE
          pp2.link_id = l.link_id
          AND pp2.psector_id = last_ps.psector_id
        LIMIT
          1
      ) x
  ) pp ON TRUE
WHERE
  (
    EXISTS (
      SELECT
        1
      FROM
        selector_state ss
      WHERE
        ss.cur_user = CURRENT_USER
        AND ss.state_id = COALESCE(pp.state, l.state)
    )
  )
  AND (
    (
      l.sector_id IN (
        SELECT
          ssec.sector_id
        FROM
          selector_sector ssec
        WHERE
          ssec.cur_user = CURRENT_USER
      )
    )
    OR pp.state IS NOT NULL
  )
  AND (
    l.muni_id IN (
      SELECT
        sm.muni_id
      FROM
        selector_municipality sm
      WHERE
        sm.cur_user = CURRENT_USER
    )
  )
  AND (
    EXISTS (
      SELECT
        1
      FROM
        selector_expl se
      WHERE
        se.cur_user = CURRENT_USER
        AND (
          se.expl_id = l.expl_id
          OR (se.expl_id = ANY (l.expl_visibility))
        )
    )
  );

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["ve_connec"], "batchId":4}}$$);

DROP VIEW IF EXISTS v_om_visit;
DROP VIEW IF EXISTS vf_connec;
CREATE OR REPLACE VIEW vf_connec AS
SELECT
  c.connec_id,
  pp.state AS p_state,
  pp.arc_id AS p_arc_id,
  pp.exit_id AS p_pjoint_id,
  pp.exit_type AS p_pjoint_type
FROM
  connec c
  LEFT JOIN LATERAL (
    SELECT
      x.state,
      x.arc_id,
      x.exit_id,
      x.exit_type
    FROM
      (
        SELECT
          1
        WHERE
          (
            EXISTS (
              SELECT
                1
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
      ) gate
      CROSS JOIN LATERAL (
        SELECT
          pp_1.state,
          pp_1.arc_id,
          l.exit_id,
          l.exit_type
        FROM
          plan_psector_x_connec pp_1
          LEFT JOIN link l ON l.link_id = pp_1.link_id
          AND l.state = 2
        WHERE
          pp_1.connec_id = c.connec_id
          AND (
            pp_1.psector_id IN (
              SELECT
                sp.psector_id
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
        ORDER BY
          pp_1.psector_id DESC,
          pp_1.state DESC
        LIMIT
          1
      ) x
  ) pp ON TRUE
WHERE
  (
    EXISTS (
      SELECT
        1
      FROM
        selector_state ss
      WHERE
        ss.cur_user = CURRENT_USER
        AND ss.state_id = COALESCE(pp.state, c.state)
    )
  )
  AND (
    (
      c.sector_id IN (
        SELECT
          ssec.sector_id
        FROM
          selector_sector ssec
        WHERE
          ssec.cur_user = CURRENT_USER
      )
    )
    OR pp.state IS NOT NULL
  )
  AND (
    c.muni_id IN (
      SELECT
        sm.muni_id
      FROM
        selector_municipality sm
      WHERE
        sm.cur_user = CURRENT_USER
    )
  )
  AND (
    EXISTS (
      SELECT
        1
      FROM
        selector_expl se
      WHERE
        se.cur_user = CURRENT_USER
        AND (
          se.expl_id = c.expl_id
          OR (se.expl_id = ANY (c.expl_visibility))
        )
    )
  );

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
  feature_class,
  featurecat_id,
  feature_state,
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
    cat_feature.feature_class,
    node.nodecat_id AS featurecat_id,
    node.state AS feature_state,
		CASE
			WHEN om_visit.the_geom IS NULL THEN node.the_geom
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_node ON om_visit_x_node.visit_id = om_visit.id
	JOIN node ON node.node_id = om_visit_x_node.node_id
	JOIN vf_node vf ON vf.node_id = node.node_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
  JOIN cat_node ON cat_node.id = node.nodecat_id
  JOIN cat_feature ON cat_feature.id = cat_node.node_type
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
    cat_feature.feature_class,
    arc.arccat_id AS featurecat_id,
    arc.state AS feature_state,
		CASE
			WHEN om_visit.the_geom IS NULL THEN st_lineinterpolatepoint(arc.the_geom, 0.5::double precision)
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_arc ON om_visit_x_arc.visit_id = om_visit.id
	JOIN arc ON arc.arc_id = om_visit_x_arc.arc_id
	JOIN vf_arc vf ON vf.arc_id = arc.arc_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
  JOIN cat_arc ON cat_arc.id = arc.arccat_id
  JOIN cat_feature ON cat_feature.id = cat_arc.arc_type
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
    cat_feature.feature_class,
    connec.conneccat_id AS featurecat_id,
    connec.state AS feature_state,
		CASE
			WHEN om_visit.the_geom IS NULL THEN connec.the_geom
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_connec ON om_visit_x_connec.visit_id = om_visit.id
	JOIN connec ON connec.connec_id = om_visit_x_connec.connec_id
	JOIN vf_connec vf ON vf.connec_id = connec.connec_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
  JOIN cat_connec ON cat_connec.id = connec.conneccat_id
  JOIN cat_feature ON cat_feature.id = cat_connec.connec_type
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
		om_visit_x_link.link_id AS feature_id,
		'LINK'::text AS feature_type,
    cat_feature.feature_class,
    link.linkcat_id AS featurecat_id,
    link.state AS feature_state,
		CASE
			WHEN om_visit.the_geom IS NULL THEN link.the_geom
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_link ON om_visit_x_link.visit_id = om_visit.id
	JOIN link ON link.link_id = om_visit_x_link.link_id
	JOIN vf_link vf ON vf.link_id = link.link_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
  JOIN cat_link ON cat_link.id = link.linkcat_id
  JOIN cat_feature ON cat_feature.id = cat_link.link_type
) a;

CREATE OR REPLACE VIEW ve_connec
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
        ), inp_network_mode AS (
         SELECT config_param_user.value
           FROM config_param_user
          WHERE config_param_user.parameter::text = 'inp_options_networkmode'::text AND config_param_user.cur_user::text = CURRENT_USER
        )
 SELECT c.connec_id,
    c.code,
    c.sys_code,
    c.top_elev,
    c.depth,
    cat_connec.connec_type,
    cat_feature.feature_class AS sys_type,
    c.conneccat_id,
    cat_connec.matcat_id AS cat_matcat_id,
    cat_connec.pnom AS cat_pnom,
    cat_connec.dnom AS cat_dnom,
    cat_connec.dint AS cat_dint,
    c.customer_code,
    c.connec_length,
    c.epa_type,
    c.state,
    c.state_type,
    c.arc_id,
    c.expl_id,
    exploitation.macroexpl_id,
    c.muni_id,
    c.sector_id,
    sector_table.macrosector_id,
    sector_table.sector_type,
    supplyzone_table.supplyzone_id,
    supplyzone_table.supplyzone_type,
    presszone_table.presszone_id,
    presszone_table.presszone_type,
    presszone_table.presszone_head,
    dma_table.dma_id,
    dma_table.macrodma_id,
    dma_table.dma_type,
    dqa_table.dqa_id,
    dqa_table.macrodqa_id,
    dqa_table.dqa_type,
    omzone_table.omzone_id,
    omzone_table.omzone_type,
    c.crmzone_id,
    crmzone.macrocrmzone_id,
    crmzone.name AS crmzone_name,
    c.minsector_id,
    c.soilcat_id,
    c.function_type,
    c.category_type,
    c.location_type,
    c.fluid_type,
    c.n_hydrometer,
    c.n_inhabitants,
    c.staticpressure,
    c.descript,
    c.annotation,
    c.observ,
    c.comment,
    concat(cat_feature.link_path, c.link) AS link,
    c.num_value,
    c.district_id,
    c.postcode,
    c.streetaxis_id,
    c.postnumber,
    c.postcomplement,
    c.streetaxis2_id,
    c.postnumber2,
    c.postcomplement2,
    vm.region_id,
    vm.province_id,
    c.block_code,
    c.plot_id,
    c.workcat_id,
    c.workcat_id_end,
    c.workcat_id_plan,
    c.builtdate,
    c.enddate,
    c.ownercat_id,
    c.pjoint_id,
    c.pjoint_type,
    c.om_state,
    c.conserv_state,
    c.accessibility,
    c.access_type,
    c.placement_type,
    c.priority,
    COALESCE(c.brand_id, cat_connec.brand_id) AS brand_id,
    COALESCE(c.model_id, cat_connec.model_id) AS model_id,
    c.serial_number,
    c.asset_id,
    c.adate,
    c.adescript,
    c.verified,
    c.datasource,
    cat_connec.label,
    c.label_x,
    c.label_y,
    c.label_rotation,
    c.rotation,
    c.label_quadrant,
    cat_connec.svg,
    c.inventory,
    c.publish,
    vst.is_operative,
        CASE
            WHEN c.sector_id > 0 AND vst.is_operative = true AND c.epa_type = 'JUNCTION'::text AND inp_network_mode.value = '4'::text THEN c.epa_type::character varying::text
            ELSE NULL::text
        END AS inp_type,
    connec_add.demand_base,
    connec_add.demand_max,
    connec_add.demand_min,
    connec_add.demand_avg,
    connec_add.press_max,
    connec_add.press_min,
    connec_add.press_avg,
    connec_add.quality_max,
    connec_add.quality_min,
    connec_add.quality_avg,
    connec_add.flow_max,
    connec_add.flow_min,
    connec_add.flow_avg,
    connec_add.vel_max,
    connec_add.vel_min,
    connec_add.vel_avg,
    connec_add.result_id,
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    dma_table.stylesheet ->> 'featureColor'::text AS dma_style,
    presszone_table.stylesheet ->> 'featureColor'::text AS presszone_style,
    dqa_table.stylesheet ->> 'featureColor'::text AS dqa_style,
    supplyzone_table.stylesheet ->> 'featureColor'::text AS supplyzone_style,
    c.lock_level,
    c.expl_visibility,
    ( SELECT st_x(c.the_geom) AS st_x) AS xcoord,
    ( SELECT st_y(c.the_geom) AS st_y) AS ycoord,
    ( SELECT st_y(st_transform(c.the_geom, 4326)) AS st_y) AS lat,
    ( SELECT st_x(st_transform(c.the_geom, 4326)) AS st_x) AS long,
    date_trunc('second'::text, c.created_at) AS created_at,
    c.created_by,
    date_trunc('second'::text, c.updated_at) AS updated_at,
    c.updated_by,
    c.the_geom,
    vf.p_state,
    c.uuid,
    c.uncertain,
    c.xyz_date,
    c.dataquality,
    c.dataquality_obs,
    vf.p_arc_id,
    vf.p_pjoint_id,
    vf.p_pjoint_type
   FROM connec c
     JOIN vf_connec vf ON vf.connec_id = c.connec_id
     JOIN cat_connec ON cat_connec.id::text = c.conneccat_id::text
     JOIN cat_feature ON cat_feature.id::text = cat_connec.connec_type::text
     JOIN exploitation ON c.expl_id = exploitation.expl_id
     JOIN v_municipality vm ON c.muni_id = vm.muni_id
     JOIN sector_table ON sector_table.sector_id = c.sector_id
     LEFT JOIN presszone_table ON presszone_table.presszone_id = c.presszone_id
     LEFT JOIN dma_table ON dma_table.dma_id = c.dma_id
     LEFT JOIN dqa_table ON dqa_table.dqa_id = c.dqa_id
     LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = c.supplyzone_id
     LEFT JOIN omzone_table ON omzone_table.omzone_id = c.omzone_id
     LEFT JOIN crmzone ON crmzone.crmzone_id = c.crmzone_id
     LEFT JOIN connec_add ON connec_add.connec_id = c.connec_id
     LEFT JOIN value_state_type vst ON vst.id = c.state_type
     LEFT JOIN inp_network_mode ON true;

CREATE TRIGGER gw_trg_edit_connec INSTEAD OF
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    ve_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');


SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":4}}$$);


CREATE OR REPLACE VIEW ve_inp_connec
AS SELECT c.connec_id,
    c.top_elev,
    c.depth,
    c.conneccat_id,
    c.arc_id,
    c.expl_id,
    c.sector_id,
    c.dma_id,
    c.state,
    c.state_type,
    c.pjoint_type,
    c.pjoint_id,
    c.annotation,
    ic.demand,
    ic.pattern_id,
    ic.peak_factor,
    ic.status,
    ic.minorloss,
    ic.custom_roughness,
    ic.custom_length,
    ic.custom_dint,
    ic.emitter_coeff,
    ic.init_quality,
    ic.source_type,
    ic.source_quality,
    ic.source_pattern_id,
    c.the_geom,
    vf.p_state,
    vf.p_arc_id,
    vf.p_pjoint_id,
    vf.p_pjoint_type
   FROM connec c
     JOIN vf_connec vf ON vf.connec_id = c.connec_id
     JOIN inp_connec ic on c.connec_id = ic.connec_id
     join value_state_type vst on vst.id = c.state_type 
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_frpump
AS SELECT f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    p.power,
    p.curve_id,
    p.speed,
    p.pattern_id,
    p.pump_type,
    p.effic_curve_id,
    p.energy_price,
    p.energy_pattern_id,
    p.status,
    f.the_geom,
    vf.p_state
   FROM ve_man_frelem f
     JOIN vf_element vf ON vf.element_id = f.element_id
     JOIN inp_frpump p ON f.element_id = p.element_id;

CREATE OR REPLACE VIEW ve_inp_frshortpipe
AS SELECT f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    p.minorloss,
    p.bulk_coeff,
    p.wall_coeff,
    p.custom_dint,
    p.status,
    f.the_geom,
    vf.p_state
   FROM ve_man_frelem f
     JOIN vf_element vf ON vf.element_id = f.element_id
     JOIN inp_frshortpipe p ON f.element_id = p.element_id;

CREATE OR REPLACE VIEW ve_inp_frvalve
AS SELECT f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    v.valve_type,
    v.custom_dint,
    v.setting,
    v.curve_id,
    v.minorloss,
    v.add_settings,
    v.init_quality,
    v.status,
    f.the_geom,
    vf.p_state
   FROM ve_man_frelem f
     JOIN vf_element vf ON vf.element_id = f.element_id
     JOIN inp_frvalve v ON f.element_id = v.element_id;

CREATE OR REPLACE VIEW ve_inp_inlet
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.dma_id,
    n.state,
    n.state_type,
    n.annotation,
    ii.initlevel,
    ii.minlevel,
    ii.maxlevel,
    ii.diameter,
    ii.minvol,
    ii.curve_id,
    ii.overflow,
    ii.mixing_model,
    ii.mixing_fraction,
    ii.reaction_coeff,
    ii.init_quality,
    ii.source_type,
    ii.source_quality,
    ii.source_pattern_id,
    ii.pattern_id,
    ii.head,
    ii.demand,
    ii.demand_pattern_id,
    ii.emitter_coeff,
    n.the_geom,
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_inlet ii ON ii.node_id = n.node_id
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_junction
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.dma_id,
    n.state,
    n.state_type,
    n.annotation,
    ij.demand,
    ij.pattern_id,
    ij.peak_factor,
    ij.emitter_coeff,
    ij.init_quality,
    ij.source_type,
    ij.source_quality,
    ij.source_pattern_id,
    n.the_geom,
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_junction ij ON ij.node_id = n.node_id
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_pipe
AS SELECT a.arc_id,
    a.node_1,
    a.node_2,
    a.arccat_id,
    a.expl_id,
    a.sector_id,
    a.dma_id,
    a.state,
    a.state_type,
    a.custom_length,
    a.annotation,
    ip.minorloss,
    ip.status,
    cat_arc.matcat_id AS cat_matcat_id,
    a.builtdate,
    ip.custom_roughness,
    cat_arc.dint AS cat_dint,
    ip.custom_dint,
    ip.bulk_coeff,
    ip.wall_coeff,
    a.the_geom,
    vf.p_state
   FROM arc a
     JOIN vf_arc vf ON vf.arc_id = a.arc_id
     JOIN inp_pipe ip ON ip.arc_id = a.arc_id
     JOIN cat_arc ON cat_arc.id::text = a.arccat_id::text
     JOIN value_state_type vst ON vst.id = a.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_pump
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.dma_id,
    n.state,
    n.state_type,
    n.annotation,
    concat(n.node_id, '_n2a') AS nodarc_id,
    ip.power,
    ip.curve_id,
    ip.speed,
    ip.pattern_id,
    man_pump.to_arc,
    ip.status,
    ip.pump_type,
    ip.effic_curve_id,
    ip.energy_price,
    ip.energy_pattern_id,
    n.the_geom,
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_pump ip ON ip.node_id = n.node_id
     JOIN man_pump ON man_pump.node_id = n.node_id
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_pump_additional
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.state,
    n.state_type,
    n.annotation,
    n.dma_id,
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
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_pump_additional p ON p.node_id = n.node_id
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_reservoir
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.dma_id,
    n.state,
    n.state_type,
    n.annotation,
    ir.pattern_id,
    ir.head,
    ir.init_quality,
    ir.source_type,
    ir.source_quality,
    ir.source_pattern_id,
    n.the_geom,
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_reservoir ir ON ir.node_id = n.node_id
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_shortpipe
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.dma_id,
    n.state,
    n.state_type,
    n.annotation,
    concat(n.node_id, '_n2a') AS nodarc_id,
    isp.minorloss,
        CASE
            WHEN v.closed IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN v.broken IS FALSE AND v.to_arc IS NOT NULL THEN 'CV'::character varying(12)
            ELSE 'OPEN'::character varying(12)
        END AS status,
    isp.bulk_coeff,
    isp.wall_coeff,
    isp.head,
    isp.pattern_id,
    isp.demand,
    isp.demand_pattern_id,
    isp.emitter_coeff,
    n.the_geom,
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_shortpipe isp ON isp.node_id = n.node_id
     LEFT JOIN man_valve v ON v.node_id = n.node_id
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_tank
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.dma_id,
    n.state,
    n.state_type,
    n.annotation,
    it.initlevel,
    it.minlevel,
    it.maxlevel,
    it.diameter,
    it.minvol,
    it.curve_id,
    it.overflow,
    it.mixing_model,
    it.mixing_fraction,
    it.reaction_coeff,
    it.init_quality,
    it.source_type,
    it.source_quality,
    it.source_pattern_id,
    n.the_geom,
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_tank it ON it.node_id = n.node_id
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_valve
AS SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.depth,
    n.nodecat_id,
    n.expl_id,
    n.sector_id,
    n.dma_id,
    n.state,
    n.state_type,
    n.annotation,
    concat(n.node_id, '_n2a') AS nodarc_id,
    iv.valve_type,
    iv.setting,
    iv.curve_id,
    iv.minorloss,
    mv.to_arc,
        CASE
            WHEN mv.closed IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN mv.broken IS FALSE AND (mv.to_arc IS NOT NULL OR iv.valve_type::text = 'TCV'::text) THEN 'ACTIVE'::character varying(12)
            ELSE 'OPEN'::character varying(12)
        END AS status,
    cat_node.dint AS cat_dint,
    iv.custom_dint,
    iv.add_settings,
    iv.init_quality,
    iv.head,
    iv.pattern_id,
    iv.demand,
    iv.demand_pattern_id,
    iv.emitter_coeff,
    n.the_geom,
    vf.p_state
   FROM node n
     JOIN vf_node vf ON vf.node_id = n.node_id
     JOIN inp_valve iv ON iv.node_id = n.node_id
     JOIN man_valve mv ON mv.node_id = n.node_id
     JOIN cat_node ON cat_node.id::text = n.nodecat_id::text
     JOIN value_state_type vst ON vst.id = n.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_virtualpump
AS SELECT a.arc_id,
    a.node_1,
    a.node_2,
    a.arccat_id,
    a.sector_id,
    a.state,
    a.state_type,
    a.annotation,
    a.expl_id,
    a.dma_id,
    p.power,
    p.curve_id,
    p.speed,
    p.pattern_id,
    p.status,
    p.effic_curve_id,
    p.energy_price,
    p.energy_pattern_id,
    p.pump_type,
    a.the_geom,
    vf.p_state
   FROM arc a
     JOIN vf_arc vf ON vf.arc_id = a.arc_id
     JOIN inp_virtualpump p ON p.arc_id = a.arc_id
     JOIN value_state_type vst ON vst.id = a.state_type
  WHERE vst.is_operative IS TRUE;

CREATE OR REPLACE VIEW ve_inp_virtualvalve
AS SELECT a.arc_id,
    a.node_1,
    a.node_2,
    a.arccat_id,
    a.expl_id,
    a.sector_id,
    a.dma_id,
    a.state,
    a.state_type,
    a.custom_length,
    a.annotation,
    v.valve_type,
    v.setting,
    v.curve_id,
    v.minorloss,
    v.status,
    v.init_quality,
    a.the_geom,
    vf.p_state
   FROM arc a
     JOIN vf_arc vf ON vf.arc_id = a.arc_id
     JOIN inp_virtualvalve v ON v.arc_id = a.arc_id
     JOIN value_state_type vst ON vst.id = a.state_type
  WHERE vst.is_operative IS TRUE;
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
	rpt_cat_result.addparam,
	rpt_cat_result.isvalidated
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

INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('node form','utils','tbl_doc_x_node','node_uuid',8,true,'Node Uuid');
INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('node form','utils','tbl_doc_x_node','doc_name',8,true,'Document Name');

INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('connec form','utils','tbl_doc_x_connec','connec_uuid',8,true,'Node Uuid');
INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('connec form','utils','tbl_doc_x_connec','doc_name',8,true,'Document Name');

INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('arc form','utils','tbl_doc_x_arc','arc_uuid',8,true,'Node Uuid');
INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('arc form','utils','tbl_doc_x_arc','doc_name',8,true,'Document Name');


DROP VIEW IF EXISTS ve_macroexploitation;

ALTER TABLE macroexploitation DROP COLUMN IF EXISTS the_geom;

CREATE OR REPLACE VIEW ve_macroexploitation
AS WITH sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        )
 SELECT DISTINCT ON (m.macroexpl_id) m.macroexpl_id,
    m.code,
    m.name,
    m.descript,
    m.lock_level,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by
   FROM macroexploitation m
     JOIN exploitation e USING (macroexpl_id)
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = e.expl_id)) AND m.active IS TRUE;

ALTER TABLE inp_typevalue DISABLE TRIGGER gw_trg_typevalue_config_fk;
DELETE FROM inp_typevalue WHERE typevalue = 'inp_options_networkmode' AND id = '5';
ALTER TABLE inp_typevalue ENABLE TRIGGER gw_trg_typevalue_config_fk;

DELETE FROM config_form_tableview
	WHERE objectname='tbl_visit_x_arc' AND columnname='sys_id';
DELETE FROM config_form_tableview
	WHERE objectname='tbl_visit_x_connec' AND columnname='sys_id';
DELETE FROM config_form_tableview
	WHERE objectname='tbl_visit_x_node' AND columnname='sys_id';

-- abbreviation and custom_code_autofill fields for ve_cat_feature_** (element, link, node, connec, arc)
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_element','form_feature','tab_none','abbreviation','string','text','Abbreviation:','Abbreviation',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_element','form_feature','tab_none','custom_code_autofill','string','text','Custom code autofill:','Custom code autofill',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_link','form_feature','tab_none','abbreviation','string','text','Abbreviation:','Abbreviation',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_link','form_feature','tab_none','custom_code_autofill','string','text','Custom code autofill:','Custom code autofill',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_node','form_feature','tab_none','abbreviation','string','text','Abbreviation:','Abbreviation',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_node','form_feature','tab_none','custom_code_autofill','string','text','Custom code autofill:','Custom code autofill',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_connec','form_feature','tab_none','abbreviation','string','text','Abbreviation:','Abbreviation',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_connec','form_feature','tab_none','custom_code_autofill','string','text','Custom code autofill:','Custom code autofill',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_arc','form_feature','tab_none','abbreviation','string','text','Abbreviation:','Abbreviation',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_cat_feature_arc','form_feature','tab_none','custom_code_autofill','string','text','Custom code autofill:','Custom code autofill',false,false,true,false,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

-- code field for cat_** (element, link, node, connec, arc)
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('cat_element','form_feature','tab_none','code','string','text','Code:','Code',false,false,true,false,'{"setMultiline":false}'::json,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('cat_link','form_feature','tab_none','code','string','text','Code:','Code',false,false,true,false,'{"setMultiline":false}'::json,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('cat_node','form_feature','tab_none','code','string','text','Code:','Code',false,false,true,false,'{"setMultiline":false}'::json,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('cat_connec','form_feature','tab_none','code','string','text','Code:','Code',false,false,true,false,'{"setMultiline":false}'::json,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('cat_arc','form_feature','tab_none','code','string','text','Code:','Code',false,false,true,false,'{"setMultiline":false}'::json,false)
  ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
-- Drop denormalized node fields from arc; compute them in ve_arc via JOIN
DROP TRIGGER IF EXISTS gw_trg_arc_node_values ON arc;

DROP VIEW IF EXISTS v_edit_arc; -- BREAKING CHANGE: v_edit_arc is no longer supported

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["ve_arc"], "batchId":17}}$$);

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

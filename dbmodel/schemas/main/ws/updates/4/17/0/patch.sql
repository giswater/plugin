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

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

ALTER TABLE inp_dscenario_conduit ADD observ text NULL;
ALTER TABLE inp_dscenario_frorifice ADD observ text NULL;
ALTER TABLE inp_dscenario_froutlet ADD observ text NULL;
ALTER TABLE inp_dscenario_frweir ADD observ text NULL;
ALTER TABLE inp_dscenario_inflows ADD observ text NULL;
ALTER TABLE inp_dscenario_inflows_poll ADD observ text NULL;
ALTER TABLE inp_dscenario_lids ADD observ text NULL;
ALTER TABLE inp_dscenario_outfall ADD observ text NULL;
ALTER TABLE inp_dscenario_raingage ADD observ text NULL;
ALTER TABLE inp_dscenario_storage ADD observ text NULL;
ALTER TABLE inp_dscenario_treatment ADD observ text NULL;


CREATE OR REPLACE VIEW ve_inp_dscenario_conduit
AS SELECT f.dscenario_id,
    f.arc_id,
    f.arccat_id,
    f.matcat_id,
    f.elev1,
    f.elev2,
    f.custom_n,
    f.barrels,
    f.culvert,
    f.kentry,
    f.kexit,
    f.kavg,
    f.flap,
    f.q0,
    f.qmax,
    f.seepage,
    ve_inp_conduit.the_geom,
    f.observ
   FROM inp_dscenario_conduit f
     JOIN ve_inp_conduit USING (arc_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_controls
AS SELECT i.id,
    d.dscenario_id,
    i.sector_id,
    i.text,
    i.active,
    i.observ
   FROM inp_dscenario_controls i
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = i.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_frorifice
AS SELECT f.dscenario_id,
    f.element_id,
    n.node_id,
    f.orifice_type,
    f.offsetval,
    f.cd,
    f.orate,
    f.flap,
    f.shape,
    f.geom1,
    f.geom2,
    f.geom3,
    f.geom4,
    n.the_geom,
    f.observ
   FROM inp_dscenario_frorifice f
     JOIN ve_inp_frorifice n USING (element_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_froutlet
AS SELECT f.dscenario_id,
    f.element_id,
    n.node_id,
    f.outlet_type,
    f.offsetval,
    f.curve_id,
    f.cd1,
    f.cd2,
    f.flap,
    n.the_geom,
    f.observ
   FROM inp_dscenario_froutlet f
     JOIN ve_inp_froutlet n USING (element_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_frpump
AS SELECT f.dscenario_id,
    f.element_id,
    n.node_id,
    f.curve_id,
    f.status,
    f.startup,
    f.shutoff,
    n.the_geom,
    f.observ
   FROM inp_dscenario_frpump f
     JOIN ve_inp_frpump n USING (element_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_frweir
AS SELECT f.dscenario_id,
    f.element_id,
    n.node_id,
    f.weir_type,
    f.offsetval,
    f.cd,
    f.ec,
    f.cd2,
    f.flap,
    f.geom1,
    f.geom2,
    f.geom3,
    f.geom4,
    f.surcharge,
    f.road_width,
    f.road_surf,
    f.coef_curve,
    n.the_geom,
    f.observ
   FROM inp_dscenario_frweir f
     JOIN ve_inp_frweir n USING (element_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_inflows
AS SELECT f.dscenario_id,
    f.node_id,
    f.order_id,
    f.timser_id,
    f.sfactor,
    f.base,
    f.pattern_id,
    f.observ
   FROM inp_dscenario_inflows f
     JOIN ve_inp_junction USING (node_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_inflows_poll
AS SELECT f.dscenario_id,
    f.node_id,
    f.poll_id,
    f.timser_id,
    f.form_type,
    f.mfactor,
    f.sfactor,
    f.base,
    f.pattern_id,
    f.observ
   FROM inp_dscenario_inflows_poll f
     JOIN ve_inp_junction USING (node_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_inlet
AS SELECT f.dscenario_id,
    f.node_id,
    f.y0,
    f.ysur,
    f.apond,
    f.inlet_type,
    f.outlet_type,
    f.gully_method,
    f.custom_top_elev,
    f.custom_depth,
    f.inlet_length,
    f.inlet_width,
    f.cd1,
    f.cd2,
    f.efficiency,
    ve_inp_inlet.the_geom,
    f.observ
   FROM inp_dscenario_inlet f
     JOIN ve_inp_inlet USING (node_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_junction
AS SELECT f.dscenario_id,
    f.node_id,
    f.elev,
    f.ymax,
    f.y0,
    f.ysur,
    f.apond,
    f.outfallparam,
    ve_inp_junction.the_geom,
    f.observ
   FROM inp_dscenario_junction f
     JOIN ve_inp_junction USING (node_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_lids
AS SELECT l.dscenario_id,
    l.subc_id,
    l.lidco_id,
    l.numelem,
    l.area,
    l.width,
    l.initsat,
    l.fromimp,
    l.toperv,
    l.rptfile,
    l.descript,
    s.the_geom,
    l.observ
   FROM inp_dscenario_lids l
     JOIN ve_inp_subcatchment s USING (subc_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s_1
          WHERE s_1.dscenario_id = l.dscenario_id AND s_1.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_outfall
AS SELECT f.dscenario_id,
    f.node_id,
    f.elev,
    f.ymax,
    f.outfall_type,
    f.stage,
    f.curve_id,
    f.timser_id,
    f.gate,
    f.route_to,
    ve_inp_outfall.the_geom,
    f.observ
   FROM inp_dscenario_outfall f
     JOIN ve_inp_outfall USING (node_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_raingage
AS SELECT r.dscenario_id,
    r.rg_id,
    r.form_type,
    r.intvl,
    r.scf,
    r.rgage_type,
    r.timser_id,
    r.fname,
    r.sta,
    r.units,
    ve_raingage.the_geom,
    r.observ
   FROM inp_dscenario_raingage r
     JOIN ve_raingage USING (rg_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = r.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_storage
AS SELECT f.dscenario_id,
    f.node_id,
    f.elev,
    f.ymax,
    f.storage_type,
    f.curve_id,
    f.a1,
    f.a2,
    f.a0,
    f.fevap,
    f.sh,
    f.hc,
    f.imd,
    f.y0,
    f.ysur,
    ve_inp_storage.the_geom,
    f.observ
   FROM inp_dscenario_storage f
     JOIN ve_inp_storage USING (node_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW ve_inp_dscenario_treatment
AS SELECT f.dscenario_id,
    f.node_id,
    f.poll_id,
    f.function,
    f.observ
   FROM inp_dscenario_treatment f
     JOIN ve_inp_junction USING (node_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER));

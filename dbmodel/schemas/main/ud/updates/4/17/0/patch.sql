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

CREATE OR REPLACE VIEW ve_cat_feature_gully
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_gully.epa_default,
    cat_feature.code_autofill,
    cat_feature_gully.double_geom::text AS double_geom,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation,
    cat_feature.custom_code_autofill
   FROM cat_feature
     JOIN cat_feature_gully USING (id);

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
    cat_feature.code_autofill,
    cat_feature_node.choose_hemisphere,
    cat_feature_node.double_geom::text AS double_geom,
    cat_feature_node.num_arcs,
    cat_feature_node.isexitupperintro,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation,
    cat_feature.custom_code_autofill
   FROM cat_feature
     JOIN cat_feature_node USING (id);

UPDATE config_form_fields
	SET "label"='Lab code'
	WHERE formtype='form_feature' AND tabname='tab_data' AND columnname='lab_code' AND "label"='lab_code';

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
		om_visit_x_gully.gully_id AS feature_id,
		'GULLY'::text AS feature_type,
		CASE
			WHEN om_visit.the_geom IS NULL THEN gully.the_geom
			ELSE om_visit.the_geom
		END AS the_geom
	FROM om_visit
	JOIN om_visit_x_gully ON om_visit_x_gully.visit_id = om_visit.id
	JOIN gully ON gully.gully_id = om_visit_x_gully.gully_id
	JOIN vf_gully vf ON vf.gully_id = gully.gully_id
	JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
) a;

DROP VIEW IF EXISTS v_ui_rpt_cat_result;
CREATE OR REPLACE VIEW v_ui_rpt_cat_result AS
SELECT DISTINCT ON (rpt_cat_result.result_id)
	rpt_cat_result.result_id,
	e.exploitation_names AS expl_id,
	rpt_cat_result.sector_id,
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

UPDATE sys_param_user
	SET layoutorder=10
	WHERE id='edit_gully_automatic_link';

UPDATE config_param_system
	SET layoutorder=12
	WHERE "parameter"='admin_crm_schema';
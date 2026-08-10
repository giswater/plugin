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
	SET "label"='Cabinet:'
	WHERE formname='ve_connec_samplepoint' AND formtype='form_feature' AND tabname='tab_data' AND columnname='cabinet' AND "label"='cabinet';

UPDATE config_form_fields
	SET "label"='Place name:'
	WHERE formname='ve_connec_samplepoint' AND formtype='form_feature' AND tabname='tab_data' AND columnname='place_name' AND "label"='place_name';

UPDATE config_form_fields
	SET "label"='Lab code'
	WHERE formtype='form_feature' AND tabname='tab_data' AND columnname='lab_code' AND "label"='lab_code';



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

-- ve_connec source

CREATE OR REPLACE VIEW ve_connec
AS WITH typevalue AS (
         SELECT edit_typevalue.typevalue,
            edit_typevalue.id,
            edit_typevalue.idval
           FROM edit_typevalue
          WHERE edit_typevalue.typevalue::text = ANY (ARRAY['sector_type'::character varying::text, 'drainzone_type'::character varying::text, 'omzone_type'::character varying::text, 'dwfzone_type'::character varying::text])
        ), sector_table AS (
         SELECT sector.sector_id,
            sector.macrosector_id,
            sector.stylesheet,
            t.id AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            omzone.macroomzone_id,
            omzone.stylesheet,
            t.id AS omzone_type
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), drainzone_table AS (
         SELECT drainzone.drainzone_id,
            drainzone.stylesheet,
            t.id AS drainzone_type
           FROM drainzone
             LEFT JOIN typevalue t ON t.id::text = drainzone.drainzone_type::text AND t.typevalue::text = 'drainzone_type'::text
        ), dwfzone_table AS (
         SELECT dwfzone.dwfzone_id,
            dwfzone.stylesheet,
            t.id AS dwfzone_type,
            dwfzone.drainzone_id
           FROM dwfzone
             LEFT JOIN typevalue t ON t.id::text = dwfzone.dwfzone_type::text AND t.typevalue::text = 'dwfzone_type'::text
        )
 SELECT c.connec_id,
    c.code,
    c.sys_code,
    c.top_elev,
    c.y1,
    c.y2,
    cat_feature.feature_class AS sys_type,
    c.connec_type::text AS connec_type,
    c.matcat_id,
    c.conneccat_id,
    c.customer_code,
    c.connec_depth,
    c.connec_length,
    c.state,
    c.state_type,
    c.arc_id,
    c.expl_id,
    exploitation.macroexpl_id,
    c.muni_id,
    c.sector_id,
    sector_table.macrosector_id,
    sector_table.sector_type,
    dwfzone_table.drainzone_id,
    drainzone_table.drainzone_type,
    c.drainzone_outfall,
    c.dwfzone_id,
    dwfzone_table.dwfzone_type,
    c.dwfzone_outfall,
    c.omzone_id,
    omzone_table.macroomzone_id,
    omzone_table.omzone_type,
    c.dma_id,
    c.omunit_id,
    c.minsector_id,
    c.soilcat_id,
    c.function_type,
    c.category_type,
    c.location_type,
    c.fluid_type,
    c.n_hydrometer,
    c.n_inhabitants,
    c.demand,
    c.descript,
    c.annotation,
    c.observ,
    c.comment,
    c.link::text AS link,
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
    c.om_state,
    c.pjoint_id,
    c.pjoint_type,
    c.access_type,
    c.placement_type,
    c.accessibility,
    c.brand_id,
    c.model_id,
    c.asset_id,
    c.adate,
    c.adescript,
    c.verified,
    c.uncertain,
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
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    drainzone_table.stylesheet ->> 'featureColor'::text AS drainzone_style,
    dwfzone_table.stylesheet ->> 'featureColor'::text AS dwfzone_style,
    omzone_table.stylesheet ->> 'featureColor'::text AS omzone_style,
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
    c.diagonal,
    vf.p_state,
    c.uuid,
    c.treatment_type,
    c.xyz_date,
    c.has_treatment,
    c.dataquality,
    c.dataquality_obs,
    vf.p_arc_id,
    vf.p_pjoint_id,
    vf.p_pjoint_type
   FROM connec c
     JOIN vf_connec vf ON vf.connec_id = c.connec_id
     JOIN cat_connec ON cat_connec.id::text = c.conneccat_id::text
     JOIN cat_feature ON cat_feature.id::text = c.connec_type::text
     JOIN exploitation ON c.expl_id = exploitation.expl_id
     JOIN v_municipality vm ON c.muni_id = vm.muni_id
     JOIN value_state_type vst ON vst.id = c.state_type
     JOIN sector_table ON sector_table.sector_id = c.sector_id
     LEFT JOIN omzone_table ON omzone_table.omzone_id = c.omzone_id
     LEFT JOIN drainzone_table ON c.omzone_id = drainzone_table.drainzone_id
     LEFT JOIN dwfzone_table ON c.dwfzone_id = dwfzone_table.dwfzone_id;


CREATE TRIGGER gw_trg_edit_connec INSTEAD OF
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    ve_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":4}}$$);

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["ve_gully"], "batchId":5}}$$);

DROP VIEW IF EXISTS vf_gully;
CREATE OR REPLACE VIEW vf_gully AS
SELECT
  g.gully_id,
  pp.state AS p_state,
  pp.arc_id AS p_arc_id,
  pp.exit_id AS p_pjoint_id,
  pp.exit_type AS p_pjoint_type
FROM
  gully g
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
          plan_psector_x_gully pp_1
          LEFT JOIN link l ON l.link_id = pp_1.link_id
          AND l.state = 2
        WHERE
          pp_1.gully_id = g.gully_id
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
        AND ss.state_id = COALESCE(pp.state, g.state)
    )
  )
  AND (
    (
      g.sector_id IN (
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
    g.muni_id IN (
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
          se.expl_id = g.expl_id
          OR (se.expl_id = ANY (g.expl_visibility))
        )
    )
  );


CREATE OR REPLACE VIEW ve_gully
AS WITH typevalue AS (
         SELECT edit_typevalue.typevalue,
            edit_typevalue.id,
            edit_typevalue.idval
           FROM edit_typevalue
          WHERE edit_typevalue.typevalue::text = ANY (ARRAY['sector_type'::character varying::text, 'drainzone_type'::character varying::text, 'omzone_type'::character varying::text, 'dwfzone_type'::character varying::text])
        ), sector_table AS (
         SELECT sector.sector_id,
            sector.macrosector_id,
            sector.stylesheet,
            t.id AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            omzone.macroomzone_id,
            omzone.stylesheet,
            t.id AS omzone_type
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), drainzone_table AS (
         SELECT drainzone.drainzone_id,
            drainzone.stylesheet,
            t.id AS drainzone_type
           FROM drainzone
             LEFT JOIN typevalue t ON t.id::text = drainzone.drainzone_type::text AND t.typevalue::text = 'drainzone_type'::text
        ), dwfzone_table AS (
         SELECT dwfzone.dwfzone_id,
            dwfzone.stylesheet,
            t.id AS dwfzone_type,
            dwfzone.drainzone_id
           FROM dwfzone
             LEFT JOIN typevalue t ON t.id::text = dwfzone.dwfzone_type::text AND t.typevalue::text = 'dwfzone_type'::text
        ), inp_network_mode AS (
         SELECT config_param_user.value
           FROM config_param_user
          WHERE config_param_user.parameter::text = 'inp_options_networkmode'::text AND config_param_user.cur_user::text = CURRENT_USER
        )
 SELECT gully.gully_id,
    gully.code,
    gully.sys_code,
    gully.top_elev,
    COALESCE(gully.width, cat_gully.width) AS width,
    COALESCE(gully.length, cat_gully.length) AS length,
    COALESCE(gully.ymax, cat_gully.ymax) AS ymax,
    gully.sandbox,
    gully.matcat_id,
    gully.gully_type,
    cat_feature.feature_class AS sys_type,
    gully.gullycat_id,
    cat_gully.matcat_id AS cat_gully_matcat,
    gully.units,
    gully.units_placement,
    gully.groove,
    gully.groove_height,
    gully.groove_length,
    gully.siphon,
    gully.siphon_type,
    gully.odorflap,
    gully._connec_arccat_id AS connec_arccat_id,
    gully.connec_length,
    COALESCE(((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric)::numeric(12,3), gully.connec_depth) AS connec_depth,
    COALESCE(gully._connec_matcat_id, cc.matcat_id::text) AS connec_matcat_id,
    gully.top_elev - gully.ymax + gully.sandbox AS connec_y1,
    gully.connec_y2,
    gully.arc_id,
    gully.epa_type,
    gully.state,
    gully.state_type,
    gully.expl_id,
    exploitation.macroexpl_id,
    gully.muni_id,
    sector_table.sector_id,
    sector_table.macrosector_id,
    sector_table.sector_type,
    dwfzone_table.drainzone_id,
    drainzone_table.drainzone_type,
    gully.drainzone_outfall,
    dwfzone_table.dwfzone_id,
    dwfzone_table.dwfzone_type,
    gully.dwfzone_outfall,
    omzone_table.omzone_id,
    omzone_table.macroomzone_id,
    gully.dma_id,
    omzone_table.omzone_type,
    gully.omunit_id,
    gully.minsector_id,
    gully.soilcat_id,
    gully.function_type,
    gully.category_type,
    gully.location_type,
    gully.fluid_type,
    gully.descript,
    gully.annotation,
    gully.observ,
    gully.comment,
    concat(cat_feature.link_path, gully.link) AS link,
    gully.num_value,
    gully.district_id,
    gully.postcode,
    gully.streetaxis_id,
    gully.postnumber,
    gully.postcomplement,
    gully.streetaxis2_id,
    gully.postnumber2,
    gully.postcomplement2,
    vm.region_id,
    vm.province_id,
    gully.workcat_id,
    gully.workcat_id_end,
    gully.workcat_id_plan,
    gully.builtdate,
    gully.enddate,
    gully.ownercat_id,
    gully.om_state,
    gully.pjoint_id,
    gully.pjoint_type,
    gully.placement_type,
    gully.access_type,
    gully.brand_id,
    gully.model_id,
    gully.asset_id,
    gully.adate,
    gully.adescript,
    gully.verified,
    gully.uncertain,
    gully.datasource,
    cat_gully.label,
    gully.label_x,
    gully.label_y,
    gully.label_rotation,
    gully.rotation,
    gully.label_quadrant,
    cat_gully.svg,
    gully.inventory,
    gully.publish,
    vst.is_operative,
        CASE
            WHEN gully.sector_id > 0 AND vst.is_operative = true AND gully.epa_type::text = 'GULLY'::character varying(16)::text AND inp_network_mode.value = '2'::text THEN gully.epa_type
            ELSE NULL::character varying(16)
        END AS inp_type,
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    omzone_table.stylesheet ->> 'featureColor'::text AS omzone_style,
    drainzone_table.stylesheet ->> 'featureColor'::text AS drainzone_style,
    dwfzone_table.stylesheet ->> 'featureColor'::text AS dwfzone_style,
    gully.lock_level,
    gully.expl_visibility,
    date_trunc('second'::text, gully.created_at) AS created_at,
    gully.created_by,
    date_trunc('second'::text, gully.updated_at) AS updated_at,
    gully.updated_by,
    gully.the_geom,
    vf.p_state,
    gully.uuid,
    gully.treatment_type,
    gully.xyz_date,
    gully.has_treatment,
    gully.dataquality,
    gully.dataquality_obs,
    vf.p_arc_id,
    vf.p_pjoint_id,
    vf.p_pjoint_type
   FROM gully
     JOIN vf_gully vf ON vf.gully_id = gully.gully_id
     JOIN cat_gully ON gully.gullycat_id::text = cat_gully.id::text
     JOIN exploitation ON gully.expl_id = exploitation.expl_id
     JOIN cat_feature ON gully.gully_type::text = cat_feature.id::text
     LEFT JOIN cat_connec cc ON cc.id::text = gully._connec_arccat_id::text
     JOIN value_state_type vst ON vst.id = gully.state_type
     JOIN v_municipality vm ON gully.muni_id = vm.muni_id
     JOIN sector_table ON gully.sector_id = sector_table.sector_id
     LEFT JOIN omzone_table ON gully.omzone_id = omzone_table.omzone_id
     LEFT JOIN drainzone_table ON gully.omzone_id = drainzone_table.drainzone_id
     LEFT JOIN dwfzone_table ON gully.dwfzone_id = dwfzone_table.dwfzone_id
     LEFT JOIN inp_network_mode ON true;

CREATE TRIGGER gw_trg_edit_gully INSTEAD OF
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    ve_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_gully('parent');


SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":5}}$$);

CREATE OR REPLACE VIEW vf_link AS
SELECT
  l.link_id,
  pp.state AS p_state
FROM
  link l
  LEFT JOIN LATERAL (
    SELECT
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
          p.psector_id
        FROM
          (
            SELECT
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
            UNION ALL
            SELECT
              pg1.psector_id
            FROM
              plan_psector_x_gully pg1
            WHERE
              pg1.gully_id = l.feature_id
              AND (
                pg1.psector_id IN (
                  SELECT
                    sp.psector_id
                  FROM
                    selector_psector sp
                  WHERE
                    sp.cur_user = CURRENT_USER
                )
              )
          ) p
        ORDER BY
          p.psector_id DESC
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
          p.state
        FROM
          (
            SELECT
              pp2.state
            FROM
              plan_psector_x_connec pp2
            WHERE
              pp2.link_id = l.link_id
              AND pp2.psector_id = last_ps.psector_id
            UNION ALL
            SELECT
              pg2.state
            FROM
              plan_psector_x_gully pg2
            WHERE
              pg2.link_id = l.link_id
              AND pg2.psector_id = last_ps.psector_id
          ) p
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
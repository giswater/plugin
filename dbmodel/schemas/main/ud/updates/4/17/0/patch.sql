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


UPDATE sys_style SET stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.40.7-Bratislava">
 <renderer-v2 symbollevels="0" referencescale="-1" forceraster="0" type="categorizedSymbol" attr="state" enableorderby="0">
  <categories>
   <category render="true" value="0" label="OBSOLETE" type="double" uuid="{80823eb1-ba4e-4517-8d07-82b656725f9b}" symbol="0"/>
   <category render="true" value="1" label="OPERATIVE" type="string" uuid="{718813e6-c212-4d14-b2d5-b98922743e2c}" symbol="1"/>
   <category render="true" value="2" label="PLANIFIED" type="double" uuid="{f2a68c83-ffba-48c2-9142-acb8ab246deb}" symbol="2"/>
   <category render="true" value="NULL" label="ELSE" type="NULL" uuid="{008959b5-0990-4a3e-b59c-737e6def7796}" symbol="3"/>
  </categories>
  <symbols>
   <symbol is_animated="0" force_rhr="0" type="line" clip_to_extent="1" frame_rate="10" name="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleLine" pass="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="234,81,83,255,hsv:0.99833333333333329,0.6537575341420615,0.91807431143663687,1" type="QString" name="line_color"/>
      <Option value="solid" type="QString" name="line_style"/>
      <Option value="0.36" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="MarkerLine" pass="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="4" type="QString" name="average_angle_length"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="average_angle_map_unit_scale"/>
      <Option value="MM" type="QString" name="average_angle_unit"/>
      <Option value="3" type="QString" name="interval"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="interval_map_unit_scale"/>
      <Option value="MM" type="QString" name="interval_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="0" type="QString" name="offset_along_line"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_along_line_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_along_line_unit"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="true" type="bool" name="place_on_every_part"/>
      <Option value="CentralPoint" type="QString" name="placements"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="1" type="QString" name="rotate"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
     <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="@0@1" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
       </Option>
      </data_defined_properties>
      <layer class="SimpleMarker" pass="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" enabled="1" locked="0">
       <Option type="Map">
        <Option value="0" type="QString" name="angle"/>
        <Option value="square" type="QString" name="cap_style"/>
        <Option value="234,81,83,255,hsv:0.99833333333333329,0.6537575341420615,0.91807431143663687,1" type="QString" name="color"/>
        <Option value="1" type="QString" name="horizontal_anchor_point"/>
        <Option value="bevel" type="QString" name="joinstyle"/>
        <Option value="filled_arrowhead" type="QString" name="name"/>
        <Option value="0,0" type="QString" name="offset"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
        <Option value="MM" type="QString" name="offset_unit"/>
        <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
        <Option value="solid" type="QString" name="outline_style"/>
        <Option value="0" type="QString" name="outline_width"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
        <Option value="MM" type="QString" name="outline_width_unit"/>
        <Option value="diameter" type="QString" name="scale_method"/>
        <Option value="0.36" type="QString" name="size"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
        <Option value="MM" type="QString" name="size_unit"/>
        <Option value="1" type="QString" name="vertical_anchor_point"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" type="QString" name="name"/>
         <Option type="Map" name="properties">
          <Option type="Map" name="size">
           <Option value="true" type="bool" name="active"/>
           <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 1000 THEN 0&#xd;&#xa;END" type="QString" name="expression"/>
           <Option value="3" type="int" name="type"/>
          </Option>
         </Option>
         <Option value="collection" type="QString" name="type"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="line" clip_to_extent="1" frame_rate="10" name="1" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleLine" pass="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="45,84,255,255,rgb:0.17647058823529413,0.32941176470588235,1,1" type="QString" name="line_color"/>
      <Option value="solid" type="QString" name="line_style"/>
      <Option value="0.36" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="SimpleLine" pass="0" id="{7684a725-426f-47d3-859a-9e4bb0b9a024}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="219,219,219,0,hsv:0,0,0.86047150377660797,0" type="QString" name="line_color"/>
      <Option value="dot" type="QString" name="line_style"/>
      <Option value="0.3" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineColor">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when initoverflowpath = true then color_rgba(255,255,255,200) else color_rgba(100,100,100,0) end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.1 + 0.415 * ln((cat_geom1*cat_geom2) + 0.10)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.1 + 0.415 * ln((3.14*cat_geom1*cat_geom1/2) + 0.10)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="MarkerLine" pass="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="4" type="QString" name="average_angle_length"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="average_angle_map_unit_scale"/>
      <Option value="MM" type="QString" name="average_angle_unit"/>
      <Option value="3" type="QString" name="interval"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="interval_map_unit_scale"/>
      <Option value="MM" type="QString" name="interval_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="0" type="QString" name="offset_along_line"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_along_line_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_along_line_unit"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="true" type="bool" name="place_on_every_part"/>
      <Option value="CentralPoint" type="QString" name="placements"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="1" type="QString" name="rotate"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
     <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="@1@2" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
       </Option>
      </data_defined_properties>
      <layer class="SimpleMarker" pass="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" enabled="1" locked="0">
       <Option type="Map">
        <Option value="0" type="QString" name="angle"/>
        <Option value="square" type="QString" name="cap_style"/>
        <Option value="31,120,180,255,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,1" type="QString" name="color"/>
        <Option value="1" type="QString" name="horizontal_anchor_point"/>
        <Option value="bevel" type="QString" name="joinstyle"/>
        <Option value="filled_arrowhead" type="QString" name="name"/>
        <Option value="0,0" type="QString" name="offset"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
        <Option value="MM" type="QString" name="offset_unit"/>
        <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
        <Option value="solid" type="QString" name="outline_style"/>
        <Option value="0" type="QString" name="outline_width"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
        <Option value="MM" type="QString" name="outline_width_unit"/>
        <Option value="diameter" type="QString" name="scale_method"/>
        <Option value="2.56" type="QString" name="size"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
        <Option value="MM" type="QString" name="size_unit"/>
        <Option value="1" type="QString" name="vertical_anchor_point"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" type="QString" name="name"/>
         <Option type="Map" name="properties">
          <Option type="Map" name="size">
           <Option value="true" type="bool" name="active"/>
           <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1500 THEN 3.0 &#xd;&#xa;WHEN @map_scale  > 1500 THEN 0&#xd;&#xa;END" type="QString" name="expression"/>
           <Option value="3" type="int" name="type"/>
          </Option>
         </Option>
         <Option value="collection" type="QString" name="type"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="line" clip_to_extent="1" frame_rate="10" name="2" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleLine" pass="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="255,127,0,255,rgb:1,0.49803921568627452,0,1" type="QString" name="line_color"/>
      <Option value="solid" type="QString" name="line_style"/>
      <Option value="0.36" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="MarkerLine" pass="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="4" type="QString" name="average_angle_length"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="average_angle_map_unit_scale"/>
      <Option value="MM" type="QString" name="average_angle_unit"/>
      <Option value="3" type="QString" name="interval"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="interval_map_unit_scale"/>
      <Option value="MM" type="QString" name="interval_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="0" type="QString" name="offset_along_line"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_along_line_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_along_line_unit"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="true" type="bool" name="place_on_every_part"/>
      <Option value="CentralPoint" type="QString" name="placements"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="1" type="QString" name="rotate"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
     <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="@2@1" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
       </Option>
      </data_defined_properties>
      <layer class="SimpleMarker" pass="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" enabled="1" locked="0">
       <Option type="Map">
        <Option value="0" type="QString" name="angle"/>
        <Option value="square" type="QString" name="cap_style"/>
        <Option value="255,127,0,255,rgb:1,0.49803921568627452,0,1" type="QString" name="color"/>
        <Option value="1" type="QString" name="horizontal_anchor_point"/>
        <Option value="bevel" type="QString" name="joinstyle"/>
        <Option value="filled_arrowhead" type="QString" name="name"/>
        <Option value="0,0" type="QString" name="offset"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
        <Option value="MM" type="QString" name="offset_unit"/>
        <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
        <Option value="solid" type="QString" name="outline_style"/>
        <Option value="0" type="QString" name="outline_width"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
        <Option value="MM" type="QString" name="outline_width_unit"/>
        <Option value="diameter" type="QString" name="scale_method"/>
        <Option value="0.36" type="QString" name="size"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
        <Option value="MM" type="QString" name="size_unit"/>
        <Option value="1" type="QString" name="vertical_anchor_point"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" type="QString" name="name"/>
         <Option type="Map" name="properties">
          <Option type="Map" name="size">
           <Option value="true" type="bool" name="active"/>
           <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 1000 THEN 0&#xd;&#xa;END" type="QString" name="expression"/>
           <Option value="3" type="int" name="type"/>
          </Option>
         </Option>
         <Option value="collection" type="QString" name="type"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="line" clip_to_extent="1" frame_rate="10" name="3" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleLine" pass="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1" type="QString" name="line_color"/>
      <Option value="solid" type="QString" name="line_style"/>
      <Option value="0.36" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="SimpleLine" pass="0" id="{7684a725-426f-47d3-859a-9e4bb0b9a024}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1" type="QString" name="line_color"/>
      <Option value="dot" type="QString" name="line_style"/>
      <Option value="0.3" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineColor">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when initoverflowpath = true then color_rgba(255,255,255,200) else color_rgba(100,100,100,0) end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.1 + 0.415 * ln((cat_geom1*cat_geom2) + 0.10)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.1 + 0.415 * ln((3.14*cat_geom1*cat_geom1/2) + 0.10)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="MarkerLine" pass="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="4" type="QString" name="average_angle_length"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="average_angle_map_unit_scale"/>
      <Option value="MM" type="QString" name="average_angle_unit"/>
      <Option value="3" type="QString" name="interval"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="interval_map_unit_scale"/>
      <Option value="MM" type="QString" name="interval_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="0" type="QString" name="offset_along_line"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_along_line_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_along_line_unit"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="true" type="bool" name="place_on_every_part"/>
      <Option value="CentralPoint" type="QString" name="placements"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="1" type="QString" name="rotate"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
     <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="@3@2" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
       </Option>
      </data_defined_properties>
      <layer class="SimpleMarker" pass="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" enabled="1" locked="0">
       <Option type="Map">
        <Option value="0" type="QString" name="angle"/>
        <Option value="square" type="QString" name="cap_style"/>
        <Option value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1" type="QString" name="color"/>
        <Option value="1" type="QString" name="horizontal_anchor_point"/>
        <Option value="bevel" type="QString" name="joinstyle"/>
        <Option value="filled_arrowhead" type="QString" name="name"/>
        <Option value="0,0" type="QString" name="offset"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
        <Option value="MM" type="QString" name="offset_unit"/>
        <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
        <Option value="solid" type="QString" name="outline_style"/>
        <Option value="0" type="QString" name="outline_width"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
        <Option value="MM" type="QString" name="outline_width_unit"/>
        <Option value="diameter" type="QString" name="scale_method"/>
        <Option value="2.56" type="QString" name="size"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
        <Option value="MM" type="QString" name="size_unit"/>
        <Option value="1" type="QString" name="vertical_anchor_point"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" type="QString" name="name"/>
         <Option type="Map" name="properties">
          <Option type="Map" name="size">
           <Option value="true" type="bool" name="active"/>
           <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1500 THEN 3.0 &#xd;&#xa;WHEN @map_scale  > 1500 THEN 0&#xd;&#xa;END" type="QString" name="expression"/>
           <Option value="3" type="int" name="type"/>
          </Option>
         </Option>
         <Option value="collection" type="QString" name="type"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
  </symbols>
  <source-symbol>
   <symbol is_animated="0" force_rhr="0" type="line" clip_to_extent="1" frame_rate="10" name="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleLine" pass="0" id="{3803a869-1bdf-438a-bb5c-37d3f352e512}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="45,84,255,255,rgb:0.17647058823529413,0.32941176470588235,1,1" type="QString" name="line_color"/>
      <Option value="solid" type="QString" name="line_style"/>
      <Option value="0.36" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option name="properties"/>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="MarkerLine" pass="0" id="{737b3486-832c-473a-a370-2cfc286e6e75}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="4" type="QString" name="average_angle_length"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="average_angle_map_unit_scale"/>
      <Option value="MM" type="QString" name="average_angle_unit"/>
      <Option value="3" type="QString" name="interval"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="interval_map_unit_scale"/>
      <Option value="MM" type="QString" name="interval_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="0" type="QString" name="offset_along_line"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_along_line_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_along_line_unit"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="true" type="bool" name="place_on_every_part"/>
      <Option value="CentralPoint" type="QString" name="placements"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="1" type="QString" name="rotate"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="outlineWidth">
         <Option value="true" type="bool" name="active"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 5000 THEN 0&#xd;&#xa;END" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
     <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="@0@1" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
       </Option>
      </data_defined_properties>
      <layer class="SimpleMarker" pass="0" id="{48a00b63-2aee-4e04-a1cf-ef06d7691b80}" enabled="1" locked="0">
       <Option type="Map">
        <Option value="0" type="QString" name="angle"/>
        <Option value="square" type="QString" name="cap_style"/>
        <Option value="45,84,255,255,rgb:0.17647058823529413,0.32941176470588235,1,1" type="QString" name="color"/>
        <Option value="1" type="QString" name="horizontal_anchor_point"/>
        <Option value="bevel" type="QString" name="joinstyle"/>
        <Option value="filled_arrowhead" type="QString" name="name"/>
        <Option value="0,0" type="QString" name="offset"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
        <Option value="MM" type="QString" name="offset_unit"/>
        <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
        <Option value="solid" type="QString" name="outline_style"/>
        <Option value="0" type="QString" name="outline_width"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
        <Option value="MM" type="QString" name="outline_width_unit"/>
        <Option value="diameter" type="QString" name="scale_method"/>
        <Option value="0.36" type="QString" name="size"/>
        <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
        <Option value="MM" type="QString" name="size_unit"/>
        <Option value="1" type="QString" name="vertical_anchor_point"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" type="QString" name="name"/>
         <Option type="Map" name="properties">
          <Option type="Map" name="size">
           <Option value="true" type="bool" name="active"/>
           <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 1000 THEN 0&#xd;&#xa;END" type="QString" name="expression"/>
           <Option value="3" type="int" name="type"/>
          </Option>
         </Option>
         <Option value="collection" type="QString" name="type"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
  </source-symbol>
  <colorramp type="randomcolors" name="[source]">
   <Option/>
  </colorramp>
  <rotation/>
  <sizescale/>
  <data-defined-properties>
   <Option type="Map">
    <Option value="" type="QString" name="name"/>
    <Option name="properties"/>
    <Option value="collection" type="QString" name="type"/>
   </Option>
  </data-defined-properties>
 </renderer-v2>
 <selection mode="Default">
  <selectionColor invalid="1"/>
  <selectionSymbol>
   <symbol is_animated="0" force_rhr="0" type="line" clip_to_extent="1" frame_rate="10" name="" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleLine" pass="0" id="{3eade21d-240a-43fc-8947-ccec8cc9a73f}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="align_dash_pattern"/>
      <Option value="square" type="QString" name="capstyle"/>
      <Option value="5;2" type="QString" name="customdash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="customdash_map_unit_scale"/>
      <Option value="MM" type="QString" name="customdash_unit"/>
      <Option value="0" type="QString" name="dash_pattern_offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="dash_pattern_offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="dash_pattern_offset_unit"/>
      <Option value="0" type="QString" name="draw_inside_polygon"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString" name="line_color"/>
      <Option value="solid" type="QString" name="line_style"/>
      <Option value="0.26" type="QString" name="line_width"/>
      <Option value="MM" type="QString" name="line_width_unit"/>
      <Option value="0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0" type="QString" name="ring_filter"/>
      <Option value="0" type="QString" name="trim_distance_end"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_end_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_end_unit"/>
      <Option value="0" type="QString" name="trim_distance_start"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="trim_distance_start_map_unit_scale"/>
      <Option value="MM" type="QString" name="trim_distance_start_unit"/>
      <Option value="0" type="QString" name="tweak_dash_pattern_on_corners"/>
      <Option value="0" type="QString" name="use_custom_dash"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="width_map_unit_scale"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option name="properties"/>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </selectionSymbol>
 </selection>
 <blendMode>0</blendMode>
 <featureBlendMode>0</featureBlendMode>
 <layerGeometryType>1</layerGeometryType>
</qgis>
' WHERE layername='ve_arc' AND styleconfig_id=101;
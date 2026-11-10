/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;


SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"link", "column":"treatment_type", "dataType":"int4", "isUtils":"False"}}$$);


DROP VIEW IF EXISTS ve_dma;
ALTER TABLE dma ALTER COLUMN the_geom TYPE public.geometry(multipolygon, SRID_VALUE)
    USING the_geom::public.geometry::public.geometry(multipolygon, SRID_VALUE);
ALTER TABLE dma ALTER COLUMN graphconfig SET DEFAULT '{"use":[{"nodeParent":"", "toArc":[]}], "ignore":[], "forceClosed":[]}'::json;


CREATE TABLE dwfzone_graph (
	node_1 int4 NOT NULL,
	node_type_1 int4 NOT NULL,
	node_2 int4 NOT NULL,
	node_type_2 int4 NOT NULL,
	dwfzone_id int4 NOT NULL,
	the_geom geometry(MULTILINESTRING, SRID_VALUE),
	CONSTRAINT dwfzone_graph_pkey PRIMARY KEY (node_1, node_2)
);

CREATE INDEX IF NOT EXISTS dwfzone_graph_node_1_idx ON dwfzone_graph USING btree (node_1);
CREATE INDEX IF NOT EXISTS dwfzone_graph_node_2_idx ON dwfzone_graph USING btree (node_2);
CREATE INDEX IF NOT EXISTS the_geom_graph_idx ON dwfzone_graph USING gist (the_geom);


ALTER TABLE gully DROP CONSTRAINT IF EXISTS gully_sys_code_unique;

CREATE OR REPLACE VIEW ve_element
AS SELECT e.element_id,
    e.code,
    e.sys_code,
    e.top_elev,
    cat_element.element_type,
    e.elementcat_id,
    e.num_elements,
    e.epa_type,
    e.state,
    e.state_type,
    e.expl_id,
    e.muni_id,
    e.sector_id,
    e.omzone_id,
    e.function_type,
    e.category_type,
    e.location_type,
    e.observ,
    e.comment,
    cat_element.link,
    e.workcat_id,
    e.workcat_id_end,
    e.builtdate,
    e.enddate,
    e.ownercat_id,
    e.brand_id,
    e.model_id,
    e.serial_number,
    e.asset_id,
    e.verified,
    e.datasource,
    e.label_x,
    e.label_y,
    e.label_rotation,
    e.rotation,
    e.inventory,
    e.publish,
    e.trace_featuregeom,
    e.lock_level,
    e.expl_visibility,
    e.created_at,
    e.created_by,
    e.updated_at,
    e.updated_by,
    e.the_geom,
    e.uuid
FROM element e
JOIN cat_element ON e.elementcat_id = cat_element.id
WHERE EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = e.state AND ss.cur_user = CURRENT_USER)
AND EXISTS (SELECT 1 FROM selector_sector ssec WHERE ssec.sector_id = e.sector_id AND ssec.cur_user = CURRENT_USER)
AND EXISTS (SELECT 1 FROM selector_municipality sm WHERE sm.muni_id = e.muni_id AND sm.cur_user = CURRENT_USER)
AND EXISTS (SELECT 1 FROM selector_expl se WHERE (se.expl_id = ANY (array_append(e.expl_visibility, e.expl_id))) AND se.cur_user = CURRENT_USER);


CREATE OR REPLACE VIEW ve_pol_element
AS SELECT p.pol_id,
    e.element_id,
    p.the_geom,
    p.trace_featuregeom,
    p.featurecat_id,
    p.state,
    p.sys_type
FROM polygon p
JOIN element e ON p.feature_id = e.element_id
WHERE EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = e.state AND ss.cur_user = CURRENT_USER)
AND EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = p.state AND ss.cur_user = CURRENT_USER)
AND EXISTS (SELECT 1 FROM selector_sector ssec WHERE ssec.sector_id = e.sector_id AND ssec.cur_user = CURRENT_USER)
AND EXISTS (SELECT 1 FROM selector_municipality sm WHERE sm.muni_id = e.muni_id AND sm.cur_user = CURRENT_USER)
AND EXISTS (SELECT 1 FROM selector_expl se WHERE (se.expl_id = ANY (array_append(e.expl_visibility, e.expl_id))) AND se.cur_user = CURRENT_USER);

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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            omzone.macroomzone_id,
            omzone.stylesheet,
            t.id::character varying(16) AS omzone_type
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), drainzone_table AS (
         SELECT drainzone.drainzone_id,
            drainzone.stylesheet,
            t.id::character varying(16) AS drainzone_type
           FROM drainzone
             LEFT JOIN typevalue t ON t.id::text = drainzone.drainzone_type::text AND t.typevalue::text = 'drainzone_type'::text
        ), dwfzone_table AS (
         SELECT dwfzone.dwfzone_id,
            dwfzone.stylesheet,
            t.id::character varying(16) AS dwfzone_type,
            dwfzone.drainzone_id
           FROM dwfzone
             LEFT JOIN typevalue t ON t.id::text = dwfzone.dwfzone_type::text AND t.typevalue::text = 'dwfzone_type'::text
        ), link_planned AS (
         SELECT l.link_id,
            l.feature_id,
            l.feature_type,
            l.exit_id,
            l.exit_type,
            l.expl_id
           FROM link l
          WHERE l.state = 2
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
    COALESCE(pp.arc_id, c.arc_id) AS arc_id,
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
    mu.region_id,
    mu.province_id,
    c.block_code,
    c.plot_code,
    c.workcat_id,
    c.workcat_id_end,
    c.workcat_id_plan,
    c.builtdate,
    c.enddate,
    c.ownercat_id,
    c.om_state,
    COALESCE(link_planned.exit_id, c.pjoint_id) AS pjoint_id,
    COALESCE(link_planned.exit_type, c.pjoint_type) AS pjoint_type,
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
    COALESCE(pp.state, c.state) AS p_state,
    c.uuid,
    c.treatment_type,
    c.xyz_date
   FROM connec c
     LEFT JOIN LATERAL ( SELECT pp_1.state,
            pp_1.arc_id,
            pp_1.link_id
           FROM plan_psector_x_connec pp_1
          WHERE pp_1.connec_id = c.connec_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC, pp_1.state DESC
         LIMIT 1) pp ON true
     JOIN cat_connec ON cat_connec.id::text = c.conneccat_id::text
     JOIN cat_feature ON cat_feature.id::text = c.connec_type::text
     JOIN exploitation ON c.expl_id = exploitation.expl_id
     JOIN ext_municipality mu ON c.muni_id = mu.muni_id
     JOIN value_state_type vst ON vst.id = c.state_type
     JOIN sector_table ON sector_table.sector_id = c.sector_id
     LEFT JOIN omzone_table ON omzone_table.omzone_id = c.omzone_id
     LEFT JOIN drainzone_table ON c.omzone_id = drainzone_table.drainzone_id
     LEFT JOIN dwfzone_table ON c.dwfzone_id = dwfzone_table.dwfzone_id
     LEFT JOIN link_planned ON link_planned.link_id = pp.link_id
    WHERE EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = COALESCE(pp.state, c.state) AND ss.cur_user = CURRENT_USER)
	 AND EXISTS (SELECT 1 FROM selector_sector ssec WHERE ssec.sector_id = c.sector_id AND ssec.cur_user = CURRENT_USER)
	 AND EXISTS (SELECT 1 FROM selector_municipality sm WHERE sm.muni_id = c.muni_id AND sm.cur_user = CURRENT_USER)
	 AND EXISTS (SELECT 1 FROM selector_expl se WHERE (se.expl_id = ANY (array_append(c.expl_visibility, c.expl_id))) AND se.cur_user = CURRENT_USER);

CREATE OR REPLACE VIEW ve_link
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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            omzone.macroomzone_id,
            omzone.stylesheet,
            t.id::character varying(16) AS omzone_type
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), drainzone_table AS (
         SELECT drainzone.drainzone_id,
            drainzone.stylesheet,
            t.id::character varying(16) AS drainzone_type
           FROM drainzone
             LEFT JOIN typevalue t ON t.id::text = drainzone.drainzone_type::text AND t.typevalue::text = 'drainzone_type'::text
        ), dwfzone_table AS (
         SELECT dwfzone.dwfzone_id,
            dwfzone.stylesheet,
            t.id::character varying(16) AS dwfzone_type,
            dwfzone.drainzone_id
           FROM dwfzone
             LEFT JOIN typevalue t ON t.id::text = dwfzone.dwfzone_type::text AND t.typevalue::text = 'dwfzone_type'::text
        ), inp_network_mode AS (
         SELECT config_param_user.value
           FROM config_param_user
          WHERE config_param_user.parameter::text = 'inp_options_networkmode'::text AND config_param_user.cur_user::text = CURRENT_USER
        )
 SELECT l.link_id,
    l.code,
    l.sys_code,
    l.top_elev1,
    l.y1,
        CASE
            WHEN l.top_elev1 IS NULL OR l.y1 IS NULL THEN NULL::double precision
            ELSE l.top_elev1 - l.y1::double precision
        END AS elevation1,
    l.exit_id,
    l.exit_type,
    l.top_elev2,
    l.y2,
        CASE
            WHEN l.top_elev2 IS NULL OR l.y2 IS NULL THEN NULL::double precision
            ELSE l.top_elev2 - l.y2::double precision
        END AS elevation2,
    l.feature_type,
    l.feature_id,
    l.link_type,
    cat_feature.feature_class AS sys_type,
    l.linkcat_id,
    l.state,
    l.state_type,
    l.expl_id,
    exploitation.macroexpl_id,
    l.muni_id,
    l.sector_id,
    sector_table.macrosector_id,
    sector_table.sector_type,
    dwfzone_table.drainzone_id,
    drainzone_table.drainzone_type,
    l.drainzone_outfall,
    l.dwfzone_id,
    dwfzone_table.dwfzone_type,
    l.dwfzone_outfall,
    l.omzone_id,
    omzone_table.macroomzone_id,
    l.dma_id,
    l.location_type,
    l.fluid_type,
    l.custom_length,
    st_length2d(l.the_geom)::numeric(12,3) AS gis_length,
    l.sys_slope,
    l.annotation,
    l.observ,
    l.comment,
    l.descript,
    l.link,
    l.num_value,
    l.workcat_id,
    l.workcat_id_end,
    l.builtdate,
    l.enddate,
    l.brand_id,
    l.model_id,
    l.private_linkcat_id,
    l.verified,
    l.uncertain,
    l.userdefined_geom,
    l.datasource,
    l.is_operative,
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    omzone_table.stylesheet ->> 'featureColor'::text AS omzone_style,
    drainzone_table.stylesheet ->> 'featureColor'::text AS drainzone_style,
    dwfzone_table.stylesheet ->> 'featureColor'::text AS dwfzone_style,
    l.lock_level,
    l.expl_visibility,
    l.created_at,
    l.created_by,
    date_trunc('second'::text, l.updated_at) AS updated_at,
    l.updated_by,
    l.the_geom,
    COALESCE(pp.state, l.state) AS p_state,
    l.uuid,
    l.omunit_id,
    l.treatment_type
   FROM link l
     LEFT JOIN LATERAL ( SELECT p.psector_id
           FROM ( SELECT pp1.connec_id AS feature_id,
                    pp1.psector_id
                   FROM plan_psector_x_connec pp1
                  WHERE (pp1.psector_id IN ( SELECT sp.psector_id
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER)) AND pp1.connec_id = l.feature_id
                UNION ALL
                 SELECT pg1.gully_id AS feature_id,
                    pg1.psector_id
                   FROM plan_psector_x_gully pg1
                  WHERE (pg1.psector_id IN ( SELECT sp.psector_id
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER)) AND pg1.gully_id = l.feature_id) p
          ORDER BY p.psector_id DESC
         LIMIT 1) last_ps ON true
     LEFT JOIN LATERAL ( SELECT p.state
           FROM ( SELECT pp2.state
                   FROM plan_psector_x_connec pp2
                  WHERE pp2.link_id = l.link_id AND pp2.psector_id = last_ps.psector_id
                UNION ALL
                 SELECT pg2.state
                   FROM plan_psector_x_gully pg2
                  WHERE pg2.link_id = l.link_id AND pg2.psector_id = last_ps.psector_id) p
         LIMIT 1) pp ON true
     JOIN exploitation ON l.expl_id = exploitation.expl_id
     JOIN ext_municipality mu ON l.muni_id = mu.muni_id
     JOIN sector_table ON l.sector_id = sector_table.sector_id
     JOIN cat_link ON cat_link.id::text = l.linkcat_id::text
     JOIN cat_feature ON cat_feature.id::text = l.link_type::text
     LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
     LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
     LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
     LEFT JOIN inp_network_mode ON TRUE
     WHERE EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = COALESCE(pp.state, l.state) AND ss.cur_user = CURRENT_USER)
     AND EXISTS (SELECT 1 FROM selector_sector ssec WHERE ssec.sector_id = l.sector_id AND ssec.cur_user = CURRENT_USER)
     AND EXISTS (SELECT 1 FROM selector_municipality sm WHERE sm.muni_id = l.muni_id AND sm.cur_user = CURRENT_USER)
     AND EXISTS (SELECT 1 FROM selector_expl se WHERE (se.expl_id = ANY (array_append(l.expl_visibility, l.expl_id))) AND se.cur_user = CURRENT_USER);

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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            omzone.macroomzone_id,
            omzone.stylesheet,
            t.id::character varying(16) AS omzone_type
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), drainzone_table AS (
         SELECT drainzone.drainzone_id,
            drainzone.stylesheet,
            t.id::character varying(16) AS drainzone_type
           FROM drainzone
             LEFT JOIN typevalue t ON t.id::text = drainzone.drainzone_type::text AND t.typevalue::text = 'drainzone_type'::text
        ), dwfzone_table AS (
         SELECT dwfzone.dwfzone_id,
            dwfzone.stylesheet,
            t.id::character varying(16) AS dwfzone_type,
            dwfzone.drainzone_id
           FROM dwfzone
             LEFT JOIN typevalue t ON t.id::text = dwfzone.dwfzone_type::text AND t.typevalue::text = 'dwfzone_type'::text
        ), inp_network_mode AS (
         SELECT config_param_user.value
           FROM config_param_user
          WHERE config_param_user.parameter::text = 'inp_options_networkmode'::text AND config_param_user.cur_user::text = CURRENT_USER
        ), link_planned AS (
         SELECT l.link_id,
            l.feature_id,
            l.feature_type,
            l.exit_id,
            l.exit_type,
            l.expl_id
           FROM link l
          WHERE l.state = 2
        )
 SELECT gully.gully_id,
    gully.code,
    gully.sys_code,
    gully.top_elev,
    COALESCE (gully.width, cat_gully.width) AS width,
    COALESCE (gully.length, cat_gully.length) AS length,
    COALESCE (gully.ymax, cat_gully.ymax) AS ymax,
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
    COALESCE (
    	((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric)::numeric(12,3),
    	gully.connec_depth
    ) AS connec_depth,
    COALESCE (gully._connec_matcat_id, cc.matcat_id)AS connec_matcat_id,
    gully.top_elev - gully.ymax + gully.sandbox AS connec_y1,
    gully.connec_y2,
    COALESCE(pp.arc_id, gully.arc_id) AS arc_id,
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
    mu.region_id,
    mu.province_id,
    gully.workcat_id,
    gully.workcat_id_end,
    gully.workcat_id_plan,
    gully.builtdate,
    gully.enddate,
    gully.ownercat_id,
    gully.om_state,
    COALESCE(link_planned.exit_id, gully.pjoint_id) AS pjoint_id,
    COALESCE(link_planned.exit_type, gully.pjoint_type) AS pjoint_type,
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
    COALESCE(pp.state, gully.state) AS p_state,
    gully.uuid,
    gully.treatment_type,
    gully.xyz_date
   FROM gully
     LEFT JOIN LATERAL ( SELECT pp_1.state,
            pp_1.arc_id,
            pp_1.link_id
           FROM plan_psector_x_gully pp_1
          WHERE pp_1.gully_id = gully.gully_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC, pp_1.state DESC
         LIMIT 1) pp ON true
     JOIN cat_gully ON gully.gullycat_id::text = cat_gully.id::text
     JOIN exploitation ON gully.expl_id = exploitation.expl_id
     JOIN cat_feature ON gully.gully_type::text = cat_feature.id::text
     LEFT JOIN cat_connec cc ON cc.id::text = gully._connec_arccat_id::text
     JOIN value_state_type vst ON vst.id = gully.state_type
     JOIN ext_municipality mu ON gully.muni_id = mu.muni_id
     JOIN sector_table ON gully.sector_id = sector_table.sector_id
     LEFT JOIN omzone_table ON gully.omzone_id = omzone_table.omzone_id
     LEFT JOIN drainzone_table ON gully.omzone_id = drainzone_table.drainzone_id
     LEFT JOIN dwfzone_table ON gully.dwfzone_id = dwfzone_table.dwfzone_id
     LEFT JOIN link_planned ON gully.gully_id = link_planned.feature_id
     LEFT JOIN inp_network_mode ON TRUE
     WHERE EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = COALESCE(pp.state, gully.state) AND ss.cur_user = CURRENT_USER)
		 AND EXISTS (SELECT 1 FROM selector_sector ssec WHERE ssec.sector_id = gully.sector_id AND ssec.cur_user = CURRENT_USER)
		 AND EXISTS (SELECT 1 FROM selector_municipality sm WHERE sm.muni_id = gully.muni_id AND sm.cur_user = CURRENT_USER)
		 AND EXISTS (SELECT 1 FROM selector_expl se WHERE (se.expl_id = ANY (array_append(gully.expl_visibility, gully.expl_id))) AND se.cur_user = CURRENT_USER);

CREATE OR REPLACE VIEW ve_arc
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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            omzone.macroomzone_id,
            omzone.stylesheet,
            t.id::character varying(16) AS omzone_type
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), drainzone_table AS (
         SELECT drainzone.drainzone_id,
            drainzone.stylesheet,
            t.id::character varying(16) AS drainzone_type
           FROM drainzone
             LEFT JOIN typevalue t ON t.id::text = drainzone.drainzone_type::text AND t.typevalue::text = 'drainzone_type'::text
        ), dwfzone_table AS (
         SELECT dwfzone.dwfzone_id,
            dwfzone.stylesheet,
            t.id::character varying(16) AS dwfzone_type,
            dwfzone.drainzone_id
           FROM dwfzone
             LEFT JOIN typevalue t ON t.id::text = dwfzone.dwfzone_type::text AND t.typevalue::text = 'dwfzone_type'::text
        )
 SELECT a.arc_id,
 	a.code,
	a.sys_code,
	a.node_1,
	a.nodetype_1,
	a.node_top_elev_1,
	a.node_custom_top_elev_1,
  COALESCE(a.node_custom_top_elev_1, a.node_top_elev_1) AS node_sys_top_elev_1,
  a.elev1,
  a.custom_elev1,
  COALESCE(a.custom_elev1, a.elev1, a.node_custom_elev_1, a.node_elev_1) AS sys_elev1,
  a.y1,
 	COALESCE(
		COALESCE (a.node_custom_top_elev_1, a.node_top_elev_1) - COALESCE (a.custom_elev1, a.elev1, a.node_custom_elev_1, a.node_elev_1),
		y1
	) AS sys_y1,
  COALESCE(
		COALESCE (a.node_custom_top_elev_1, a.node_top_elev_1) - COALESCE (a.custom_elev1, a.elev1, a.node_custom_elev_1, a.node_elev_1),
		y1
	) - cat_arc.geom1 AS r1,
  COALESCE(a.custom_elev1, a.elev1, a.node_custom_elev_1, a.node_elev_1) - COALESCE(a.node_custom_elev_1, a.node_elev_1) AS z1,
  a.node_2,
  a.nodetype_2,
  a.node_top_elev_2,
  a.node_custom_top_elev_2,
  COALESCE(a.node_custom_top_elev_2, a.node_top_elev_2) AS node_sys_top_elev_2,
  a.elev2,
  a.custom_elev2,
  COALESCE(a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2) AS sys_elev2,
  a.y2,
 	COALESCE(
		COALESCE (a.node_custom_top_elev_2, a.node_top_elev_2) - COALESCE (a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2),
		y2
	) AS sys_y2,
  COALESCE(
		COALESCE (a.node_custom_top_elev_2, a.node_top_elev_2) - COALESCE (a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2),
		y2
	) - cat_arc.geom1 AS r2,
  COALESCE(a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2) - COALESCE(a.node_custom_elev_2, a.node_elev_2) AS z2,
  cat_feature.feature_class AS sys_type,
  a.arc_type::text,
  a.arccat_id,
  COALESCE(a.matcat_id, cat_arc.matcat_id) AS matcat_id,
  cat_arc.shape AS cat_shape,
	cat_arc.geom1 AS cat_geom1,
	cat_arc.geom2 AS cat_geom2,
	cat_arc.width AS cat_width,
	cat_arc.area AS cat_area,
  a.epa_type,
  a.state,
  a.state_type,
  a.parent_id,
	a.expl_id,
	e.macroexpl_id,
	a.muni_id,
	a.sector_id,
	sector_table.macrosector_id,
	sector_table.sector_type,
	dwfzone_table.drainzone_id,
	drainzone_table.drainzone_type,
	a.drainzone_outfall,
	a.dwfzone_id,
	dwfzone_table.dwfzone_type,
	a.dwfzone_outfall,
	a.omzone_id,
	omzone_table.macroomzone_id,
	a.dma_id,
	omzone_table.omzone_type,
  a.omunit_id,
	a.minsector_id,
	a.pavcat_id,
	a.soilcat_id,
	a.function_type,
	a.category_type,
	a.location_type,
	a.fluid_type,
	a.custom_length,
	st_length(a.the_geom)::numeric(12,2) AS gis_length,
	a.sys_slope AS slope,
	a.descript,
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
	mu.region_id,
	mu.province_id,
	a.workcat_id,
	a.workcat_id_end,
	a.workcat_id_plan,
	a.builtdate,
	a.registration_date,
	a.enddate,
	a.ownercat_id,
	a.last_visitdate,
	a.visitability,
	a.om_state,
	a.conserv_state,
	a.brand_id,
	a.model_id,
	a.serial_number,
	a.asset_id,
	a.adate,
	a.adescript,
	a.verified,
  a.uncertain,
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
	    WHEN a.sector_id > 0 AND vst.is_operative = true AND a.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN a.epa_type
	    ELSE NULL::character varying(16)
	END AS inp_type,
	arc_add.result_id,
	arc_add.max_flow,
	arc_add.max_veloc,
	arc_add.mfull_flow,
	arc_add.mfull_depth,
	arc_add.manning_veloc,
	arc_add.manning_flow,
	arc_add.dwf_minflow,
	arc_add.dwf_maxflow,
	arc_add.dwf_minvel,
	arc_add.dwf_maxvel,
	arc_add.conduit_capacity,
	sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
	drainzone_table.stylesheet ->> 'featureColor'::text AS drainzone_style,
	dwfzone_table.stylesheet ->> 'featureColor'::text AS dwfzone_style,
	omzone_table.stylesheet ->> 'featureColor'::text AS omzone_style,
	a.lock_level,
	a.initoverflowpath,
	a.inverted_slope,
	a.negative_offset,
	a.expl_visibility,
	date_trunc('second'::text, a.created_at) AS created_at,
	a.created_by,
	date_trunc('second'::text, a.updated_at) AS updated_at,
	a.updated_by,
	a.the_geom,
	a.meandering,
	COALESCE(pp.state, a.state) AS p_state,
	a.uuid,
	a.treatment_type
FROM arc a
LEFT JOIN LATERAL ( SELECT pp_1.state
       FROM plan_psector_x_arc pp_1
      WHERE pp_1.arc_id = a.arc_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
               FROM selector_psector sp
              WHERE sp.cur_user = CURRENT_USER))
      ORDER BY pp_1.psector_id DESC
     LIMIT 1) pp ON true
 JOIN cat_arc ON a.arccat_id = cat_arc.id
 JOIN cat_feature ON a.arc_type = cat_feature.id
 JOIN exploitation e ON e.expl_id = a.expl_id
 JOIN ext_municipality mu ON a.muni_id = mu.muni_id
 JOIN value_state_type vst ON vst.id = a.state_type
 JOIN sector_table ON sector_table.sector_id = a.sector_id
 LEFT JOIN omzone_table ON omzone_table.omzone_id = a.omzone_id
 LEFT JOIN drainzone_table ON a.omzone_id = drainzone_table.drainzone_id
 LEFT JOIN dwfzone_table ON a.dwfzone_id = dwfzone_table.dwfzone_id
 LEFT JOIN arc_add ON arc_add.arc_id = a.arc_id
 WHERE EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = COALESCE(pp.state, a.state) AND ss.cur_user = CURRENT_USER)
 AND EXISTS (SELECT 1 FROM selector_sector ssec WHERE ssec.sector_id = a.sector_id AND ssec.cur_user = CURRENT_USER)
 AND EXISTS (SELECT 1 FROM selector_municipality sm WHERE sm.muni_id = a.muni_id AND sm.cur_user = CURRENT_USER)
 AND EXISTS (SELECT 1 FROM selector_expl se WHERE (se.expl_id = ANY (array_append(a.expl_visibility, a.expl_id))) AND se.cur_user = CURRENT_USER);

CREATE OR REPLACE VIEW ve_node
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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            omzone.macroomzone_id,
            omzone.stylesheet,
            t.id::character varying(16) AS omzone_type
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), drainzone_table AS (
         SELECT drainzone.drainzone_id,
            drainzone.stylesheet,
            t.id::character varying(16) AS drainzone_type
           FROM drainzone
             LEFT JOIN typevalue t ON t.id::text = drainzone.drainzone_type::text AND t.typevalue::text = 'drainzone_type'::text
        ), dwfzone_table AS (
         SELECT dwfzone.dwfzone_id,
            dwfzone.stylesheet,
            t.id::character varying(16) AS dwfzone_type,
            dwfzone.drainzone_id
           FROM dwfzone
             LEFT JOIN typevalue t ON t.id::text = dwfzone.dwfzone_type::text AND t.typevalue::text = 'dwfzone_type'::text
        )
 SELECT n.node_id,
    n.code,
    n.sys_code,
    n.top_elev,
    n.custom_top_elev,
    COALESCE(n.custom_top_elev, n.top_elev) AS sys_top_elev,
    n.ymax,
    COALESCE (
    	COALESCE(n.custom_top_elev, n.top_elev) - COALESCE(n.custom_elev, n.elev),
    	n.ymax
    ) AS sys_ymax,
    n.elev,
    n.custom_elev,
    COALESCE(n.custom_elev, n.elev) AS sys_elev,
    cat_feature.feature_class AS sys_type,
    n.node_type::text AS node_type,
    COALESCE(n.matcat_id, cat_node.matcat_id) AS matcat_id,
    n.nodecat_id,
    n.epa_type,
    n.state,
    n.state_type,
    n.arc_id,
    n.parent_id,
    n.expl_id,
    exploitation.macroexpl_id,
    n.muni_id,
    n.sector_id,
    sector_table.macrosector_id,
    sector_table.sector_type,
    dwfzone_table.drainzone_id,
    drainzone_table.drainzone_type,
    n.drainzone_outfall,
    n.dwfzone_id,
    dwfzone_table.dwfzone_type,
    n.dwfzone_outfall,
    n.omzone_id,
    omzone_table.macroomzone_id,
    n.dma_id,
    n.omunit_id,
    n.minsector_id,
    n.pavcat_id,
    n.soilcat_id,
    n.function_type,
    n.category_type,
    n.location_type,
    n.fluid_type,
    n.annotation,
    n.observ,
    n.comment,
    n.descript,
    concat(cat_feature.link_path, n.link) AS link,
    n.num_value,
    n.district_id,
    n.postcode,
    n.streetaxis_id,
    n.postnumber,
    n.postcomplement,
    n.streetaxis2_id,
    n.postnumber2,
    n.postcomplement2,
    mu.region_id,
    mu.province_id,
    n.workcat_id,
    n.workcat_id_end,
    n.workcat_id_plan,
    n.builtdate,
    n.enddate,
    n.ownercat_id,
    n.conserv_state,
    n.om_state,
    n.access_type,
    n.placement_type,
    n.brand_id,
    n.model_id,
    n.serial_number,
    n.asset_id,
    n.adate,
    n.adescript,
    n.verified,
    n.xyz_date,
    n.uncertain,
    n.datasource,
    n.unconnected,
    cat_node.label,
    n.label_x,
    n.label_y,
    n.label_rotation,
    n.rotation,
    n.label_quadrant,
    n.hemisphere,
    cat_node.svg,
    n.inventory,
    n.publish,
    vst.is_operative,
    n.is_scadamap,
        CASE
            WHEN n.sector_id > 0 AND vst.is_operative = true AND n.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN n.epa_type
            ELSE NULL::character varying(16)
        END AS inp_type,
    node_add.result_id,
    node_add.max_depth,
    node_add.max_height,
    node_add.flooding_rate,
    node_add.flooding_vol,
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    omzone_table.stylesheet ->> 'featureColor'::text AS omzone_style,
    drainzone_table.stylesheet ->> 'featureColor'::text AS drainzone_style,
    dwfzone_table.stylesheet ->> 'featureColor'::text AS dwfzone_style,
    n.lock_level,
    n.expl_visibility,
    ( SELECT st_x(n.the_geom) AS st_x) AS xcoord,
    ( SELECT st_y(n.the_geom) AS st_y) AS ycoord,
    ( SELECT st_y(st_transform(n.the_geom, 4326)) AS st_y) AS lat,
    ( SELECT st_x(st_transform(n.the_geom, 4326)) AS st_x) AS long,
    date_trunc('second'::text, n.created_at) AS created_at,
    n.created_by,
    date_trunc('second'::text, n.updated_at) AS updated_at,
    n.updated_by,
    n.the_geom,
    COALESCE(pp.state, n.state) AS p_state,
    n.uuid,
    n.treatment_type
   FROM node n
     LEFT JOIN LATERAL ( SELECT pp_1.state
           FROM plan_psector_x_node pp_1
          WHERE pp_1.node_id = n.node_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC
         LIMIT 1) pp ON true
     JOIN cat_node ON n.nodecat_id::text = cat_node.id::text
     JOIN cat_feature ON cat_feature.id::text = n.node_type::text
     JOIN exploitation ON n.expl_id = exploitation.expl_id
     JOIN ext_municipality mu ON n.muni_id = mu.muni_id
     JOIN value_state_type vst ON vst.id = n.state_type
     JOIN sector_table ON sector_table.sector_id = n.sector_id
     LEFT JOIN omzone_table ON omzone_table.omzone_id = n.omzone_id
     LEFT JOIN drainzone_table ON n.omzone_id = drainzone_table.drainzone_id
     LEFT JOIN dwfzone_table ON n.dwfzone_id = dwfzone_table.dwfzone_id
     LEFT JOIN node_add ON node_add.node_id = n.node_id
 WHERE EXISTS (SELECT 1 FROM selector_state ss WHERE ss.state_id = COALESCE(pp.state, n.state) AND ss.cur_user = CURRENT_USER)
 AND EXISTS (SELECT 1 FROM selector_sector ssec WHERE ssec.sector_id = n.sector_id AND ssec.cur_user = CURRENT_USER)
 AND EXISTS (SELECT 1 FROM selector_municipality sm WHERE sm.muni_id = n.muni_id AND sm.cur_user = CURRENT_USER)
 AND EXISTS (SELECT 1 FROM selector_expl se WHERE (se.expl_id = ANY (array_append(n.expl_visibility, n.expl_id))) AND se.cur_user = CURRENT_USER);


CREATE OR REPLACE VIEW ve_dma
AS WITH sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        )
 SELECT dma_id,
    code,
    name,
    descript,
    active,
    dma_type,
    expl_id,
    sector_id,
    muni_id,
    avg_press,
    pattern_id,
    effc,
    graphconfig::text AS graphconfig,
    stylesheet,
    lock_level,
    link,
    the_geom,
    addparam::text AS addparam,
    created_at,
    created_by,
    updated_at,
    updated_by
   FROM dma d
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = ANY (d.expl_id))) AND dma_id > 0;
          

INSERT INTO macroomunit (macroomunit_id) VALUES(0) ON CONFLICT (macroomunit_id) DO NOTHING;
INSERT INTO omunit (omunit_id) VALUES(0) ON CONFLICT (omunit_id) DO NOTHING;

INSERT INTO sys_param_user (id,formname,descript,sys_role,"label",isenabled,layoutorder,project_type,isparent,isautoupdate,"datatype",widgettype,ismandatory,layoutname,iseditable,"source")
VALUES ('edit_insert_show_elevation_from_dem','config','If true, the elevation will be showed from the DEM raster when inserting a new feature','role_edit','Show elevation from DEM:',true,28,'utils',false,false,'boolean','check',false,'lyt_other',true,'core');
INSERT INTO config_param_user ("parameter", value, cur_user) VALUES('edit_insert_show_elevation_from_dem', 'true', 'postgres');

UPDATE sys_param_user SET descript = 'If elev, try to recalculate elev if ymax is not null. If ymax, try to recalculate ymax if elev is not null.'
WHERE id = 'edit_node_topelev_options';

UPDATE sys_feature_class SET epa_default = 'UNDEFINED' WHERE id = 'CJOIN' or id = 'VGULLY';
UPDATE sys_feature_class SET epa_default = 'GULLY' WHERE id = 'GINLET';

UPDATE om_typevalue SET idval = 'NOT TREATED' WHERE id = '3' AND typevalue = 'treatment_type';
UPDATE om_typevalue SET idval = 'PRETREATED' WHERE id = '2' AND typevalue = 'treatment_type';

INSERT INTO sys_foreignkey (typevalue_table, typevalue_name, target_table, target_field, parameter_id, active)
VALUES('om_typevalue', 'treatment_type', 'link', 'treatment_type', NULL, true);

UPDATE config_function SET style=
'{
  "style": {
    "point": {
      "style": "categorized",
      "field": "feature_type",
      "transparency": 0.5,
      "width": 2,
      "values": [
        {
          "id": "NODE",
          "color": [255, 0, 0],
		  "legend_id": "NODE (profile)"
        },
        {
          "id": "GULLY",
          "color": [216, 197, 52],
		  "legend_id": "GULLY (profile)"
        },
        {
          "id": "CONNEC",
          "color": [166, 206, 227],
		  "legend_id": "CONNEC (profile)"
        }
      ]
    },
    "line": {
      "style": "categorized",
      "field": "feature_type",
      "transparency": 0.5,
      "width": 2,
      "values": [
        {
          "id": "ARC",
          "color": [176, 250, 248],
		  "legend_id": "ARC (profile)"
        },
        {
          "id": "LINK",
          "color": [255, 116, 130],
		  "legend_id": "LINK (profile)"
        }
      ]
    },
    "polygon": {}
  }
}'::json
WHERE id=2832;

UPDATE config_param_system SET value='{"sys_table_id":"ve_gully","sys_id_field":"gully_id","sys_search_field":"gully_id","alias":"Gullies","cat_field":"gullycat_id","orderby":"3","search_type":"gully"}', project_type='ud' WHERE "parameter"='basic_search_network_gully';


INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4470, 'Fluid type autoupdate is enabled. Disable it to update the fluid type with this function.', NULL, 2, true, 'ud', 'core', 'UI');

CREATE INDEX gully_minsector_id_idx ON gully USING btree (minsector_id);

ALTER TABLE gully ADD CONSTRAINT gully_minsector_id_fkey FOREIGN KEY (minsector_id) REFERENCES minsector(minsector_id);

CREATE INDEX IF NOT EXISTS node_omunit_id_idx ON node USING btree (omunit_id);
CREATE INDEX IF NOT EXISTS arc_omunit_id_idx ON arc USING btree (omunit_id);
CREATE INDEX IF NOT EXISTS connec_omunit_id_idx ON connec USING btree (omunit_id);
CREATE INDEX IF NOT EXISTS link_omunit_id_idx ON link USING btree (omunit_id);
CREATE INDEX IF NOT EXISTS gully_omunit_id_idx ON gully USING btree (omunit_id);

CREATE INDEX IF NOT EXISTS gully_dma_id_idx ON gully USING btree (dma_id);

ALTER TABLE node ADD CONSTRAINT node_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id);
ALTER TABLE arc ADD CONSTRAINT arc_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id);
ALTER TABLE connec ADD CONSTRAINT connec_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id);
ALTER TABLE link ADD CONSTRAINT link_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id);
ALTER TABLE gully ADD CONSTRAINT gully_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id);

ALTER TABLE anl_arc ADD COLUMN omunit_id INTEGER;

DROP INDEX IF EXISTS node_expl_visibility_idx;
DROP INDEX IF EXISTS arc_expl_visibility_idx;
DROP INDEX IF EXISTS connec_expl_visibility_idx;
DROP INDEX IF EXISTS link_expl_visibility_idx;
DROP INDEX IF EXISTS element_expl_visibility_idx;
DROP INDEX IF EXISTS gully_expl_visibility_idx;

-- Recreate indexes with gin index
CREATE INDEX node_expl_visibility_gin ON node USING gin(expl_visibility) WHERE expl_visibility IS NOT NULL;
CREATE INDEX arc_expl_visibility_gin ON arc USING gin(expl_visibility) WHERE expl_visibility IS NOT NULL;
CREATE INDEX connec_expl_visibility_gin ON connec USING gin(expl_visibility) WHERE expl_visibility IS NOT NULL;
CREATE INDEX link_expl_visibility_gin ON link USING gin(expl_visibility) WHERE expl_visibility IS NOT NULL;
CREATE INDEX element_expl_visibility_gin ON element USING gin(expl_visibility) WHERE expl_visibility IS NOT NULL;
CREATE INDEX gully_expl_visibility_gin ON gully USING gin(expl_visibility) WHERE expl_visibility IS NOT NULL;

-- cat_link
CREATE TRIGGER gw_trg_cat_material_fk_insert AFTER INSERT ON cat_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_material_fk('link');
CREATE TRIGGER gw_trg_cat_material_fk_update AFTER UPDATE OF matcat_id ON cat_link
FOR EACH ROW WHEN (((OLD.matcat_id)::TEXT IS DISTINCT FROM (NEW.matcat_id)::TEXT)) EXECUTE FUNCTION gw_trg_cat_material_fk('link');

-- node
CREATE TRIGGER gw_trg_cat_material_fk_insert AFTER INSERT ON cat_node
FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_material_fk('node');
CREATE TRIGGER gw_trg_cat_material_fk_update AFTER UPDATE OF matcat_id ON cat_node
FOR EACH ROW WHEN (((OLD.matcat_id)::TEXT IS DISTINCT FROM (NEW.matcat_id)::TEXT)) EXECUTE FUNCTION gw_trg_cat_material_fk('node');

-- arc
CREATE TRIGGER gw_trg_cat_material_fk_insert AFTER INSERT ON cat_arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_material_fk('arc');
CREATE TRIGGER gw_trg_cat_material_fk_update AFTER UPDATE OF matcat_id ON cat_arc
FOR EACH ROW WHEN (((OLD.matcat_id)::TEXT IS DISTINCT FROM (NEW.matcat_id)::TEXT)) EXECUTE FUNCTION gw_trg_cat_material_fk('arc');

-- connec
CREATE TRIGGER gw_trg_cat_material_fk_insert AFTER INSERT ON cat_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_material_fk('connec');
CREATE TRIGGER gw_trg_cat_material_fk_update AFTER UPDATE OF matcat_id ON cat_connec
FOR EACH ROW WHEN (((OLD.matcat_id)::TEXT IS DISTINCT FROM (NEW.matcat_id)::TEXT)) EXECUTE FUNCTION gw_trg_cat_material_fk('connec');


DROP TRIGGER IF EXISTS gw_trg_typevalue_fk_update ON link;
CREATE TRIGGER gw_trg_typevalue_fk_update AFTER
UPDATE
    OF fluid_type,
    treatment_type ON
    link FOR EACH ROW
    WHEN ((old.fluid_type IS DISTINCT
    FROM
    new.fluid_type)
    OR (old.treatment_type IS DISTINCT
    FROM
    new.treatment_type))
    EXECUTE FUNCTION gw_trg_typevalue_fk('link');


CREATE TRIGGER gw_trg_v_edit_dma INSTEAD OF INSERT
OR DELETE
OR UPDATE ON
ve_dma FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dma('EDIT');

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Live slope must use the same elevation as sys_elev. The 4.17.0 fallback
-- preferred the node invert over arc elev/custom_elev, so a one-sided y2
-- or custom_elev2 moved sys_elev2 and left slope unchanged (#996).
-- Column list is unchanged, so CREATE OR REPLACE keeps gw_trg_edit_arc.

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
 SELECT a.arc_id,
    a.code,
    a.sys_code,
    a.node_1,
    cn1.node_type::varchar(30) AS nodetype_1,
    n1.top_elev AS node_top_elev_1,
    n1.custom_top_elev AS node_custom_top_elev_1,
    COALESCE(n1.custom_top_elev, n1.top_elev) AS node_sys_top_elev_1,
    a.elev1,
    a.custom_elev1,
    COALESCE(a.custom_elev1, a.elev1, n1.custom_elev, n1.elev) AS sys_elev1,
    a.y1,
    COALESCE(COALESCE(n1.custom_top_elev, n1.top_elev) - COALESCE(a.custom_elev1, a.elev1, n1.custom_elev, n1.elev), a.y1) AS sys_y1,
    COALESCE(COALESCE(n1.custom_top_elev, n1.top_elev) - COALESCE(a.custom_elev1, a.elev1, n1.custom_elev, n1.elev), a.y1) - cat_arc.geom1 AS r1,
    COALESCE(a.custom_elev1, a.elev1, n1.custom_elev, n1.elev) - COALESCE(n1.custom_elev, n1.elev) AS z1,
    a.node_2,
    cn2.node_type::varchar(30) AS nodetype_2,
    n2.top_elev AS node_top_elev_2,
    n2.custom_top_elev AS node_custom_top_elev_2,
    COALESCE(n2.custom_top_elev, n2.top_elev) AS node_sys_top_elev_2,
    a.elev2,
    a.custom_elev2,
    COALESCE(a.custom_elev2, a.elev2, n2.custom_elev, n2.elev) AS sys_elev2,
    a.y2,
    COALESCE(COALESCE(n2.custom_top_elev, n2.top_elev) - COALESCE(a.custom_elev2, a.elev2, n2.custom_elev, n2.elev), a.y2) AS sys_y2,
    COALESCE(COALESCE(n2.custom_top_elev, n2.top_elev) - COALESCE(a.custom_elev2, a.elev2, n2.custom_elev, n2.elev), a.y2) - cat_arc.geom1 AS r2,
    COALESCE(a.custom_elev2, a.elev2, n2.custom_elev, n2.elev) - COALESCE(n2.custom_elev, n2.elev) AS z2,
    cat_feature.feature_class AS sys_type,
    a.arc_type::text AS arc_type,
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
        CASE
            WHEN a.sys_slope IS NULL THEN ((COALESCE(a.custom_elev1, a.elev1, n1.custom_elev, n1.elev) - COALESCE(a.custom_elev2, a.elev2, n2.custom_elev, n2.elev))::double precision / st_length(a.the_geom))::numeric(12,4)
            ELSE a.sys_slope
        END AS slope,
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
    vm.region_id,
    vm.province_id,
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
    vf.p_state,
    a.uuid,
    a.treatment_type,
    a.dataquality,
    a.dataquality_obs
   FROM arc a
     JOIN vf_arc vf ON vf.arc_id = a.arc_id
     JOIN cat_arc ON a.arccat_id::text = cat_arc.id::text
     JOIN cat_feature ON a.arc_type::text = cat_feature.id::text
     JOIN exploitation e ON e.expl_id = a.expl_id
     JOIN v_municipality vm ON a.muni_id = vm.muni_id
     JOIN value_state_type vst ON vst.id = a.state_type
     JOIN sector_table ON sector_table.sector_id = a.sector_id
     LEFT JOIN omzone_table ON omzone_table.omzone_id = a.omzone_id
     LEFT JOIN drainzone_table ON a.omzone_id = drainzone_table.drainzone_id
     LEFT JOIN dwfzone_table ON a.dwfzone_id = dwfzone_table.dwfzone_id
     LEFT JOIN node n1 ON n1.node_id = a.node_1
     LEFT JOIN cat_node cn1 ON cn1.id::text = n1.nodecat_id::text
     LEFT JOIN node n2 ON n2.node_id = a.node_2
     LEFT JOIN cat_node cn2 ON cn2.id::text = n2.nodecat_id::text
     LEFT JOIN arc_add ON arc_add.arc_id = a.arc_id;

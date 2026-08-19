/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;


CREATE TABLE IF NOT EXISTS inp_dscenario_pattern (
	dscenario_id int4 NOT NULL,
	pattern_id varchar(16) NOT NULL,
	pattern_type varchar(30) NULL,
	observ text NULL,
	tsparameters json NULL,
	expl_id int4 NULL,
	log text NULL,
	active bool DEFAULT true NULL,
	CONSTRAINT inp_dscenario_pattern_pkey PRIMARY KEY (dscenario_id, pattern_id)
);

ALTER TABLE inp_dscenario_pattern ADD CONSTRAINT inp_dscenario_pattern_pattern_id_fkey 
FOREIGN KEY (pattern_id) REFERENCES inp_pattern(pattern_id) 
ON DELETE CASCADE ON UPDATE CASCADE;


CREATE TABLE IF NOT EXISTS inp_dscenario_pattern_value (
	dscenario_id int4 NOT NULL,
	pattern_id varchar(16) NOT NULL,
	factor_1 numeric(12, 4) NULL,
	factor_2 numeric(12, 4) NULL,
	factor_3 numeric(12, 4) NULL,
	factor_4 numeric(12, 4) NULL,
	factor_5 numeric(12, 4) NULL,
	factor_6 numeric(12, 4) NULL,
	factor_7 numeric(12, 4) NULL,
	factor_8 numeric(12, 4) NULL,
	factor_9 numeric(12, 4) NULL,
	factor_10 numeric(12, 4) NULL,
	factor_11 numeric(12, 4) NULL,
	factor_12 numeric(12, 4) NULL,
	factor_13 numeric(12, 4) NULL,
	factor_14 numeric(12, 4) NULL,
	factor_15 numeric(12, 4) NULL,
	factor_16 numeric(12, 4) NULL,
	factor_17 numeric(12, 4) NULL,
	factor_18 numeric(12, 4) NULL,
	factor_19 numeric(12, 4) NULL,
	factor_20 numeric(12, 4) NULL,
	factor_21 numeric(12, 4) NULL,
	factor_22 numeric(12, 4) NULL,
	factor_23 numeric(12, 4) NULL,
	factor_24 numeric(12, 4) NULL,
	CONSTRAINT inp_dscenario_pattern_value_pkey PRIMARY KEY (dscenario_id, pattern_id)
);

ALTER TABLE inp_dscenario_pattern_value ADD CONSTRAINT inp_dscenario_pattern_value_dscenario_id_pattern_id_fkey 
FOREIGN KEY (dscenario_id, pattern_id) REFERENCES inp_dscenario_pattern(dscenario_id, pattern_id) 
ON DELETE CASCADE ON UPDATE CASCADE;


ALTER TABLE dwfzone DISABLE TRIGGER USER;
ALTER TABLE drainzone DISABLE TRIGGER USER;
ALTER TABLE omunit DISABLE TRIGGER USER;
ALTER TABLE macroomunit DISABLE TRIGGER USER;

UPDATE dwfzone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE dwfzone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE dwfzone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE dwfzone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE dwfzone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE dwfzone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE dwfzone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE dwfzone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE dwfzone ALTER COLUMN muni_id SET NOT NULL;

UPDATE drainzone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE drainzone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE drainzone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE drainzone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE drainzone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE drainzone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE drainzone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE drainzone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE drainzone ALTER COLUMN muni_id SET NOT NULL;

UPDATE omunit SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE omunit SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE omunit SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE omunit ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE omunit ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE omunit ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE omunit ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE omunit ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE omunit ALTER COLUMN muni_id SET NOT NULL;

UPDATE macroomunit SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE macroomunit SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE macroomunit SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE macroomunit ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE macroomunit ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE macroomunit ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE macroomunit ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE macroomunit ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE macroomunit ALTER COLUMN muni_id SET NOT NULL;

ALTER TABLE omunit ALTER COLUMN the_geom TYPE public.geometry(multilinestring, SRID_VALUE) USING the_geom::public.geometry(multilinestring, SRID_VALUE);
ALTER TABLE macroomunit ALTER COLUMN the_geom TYPE public.geometry(multilinestring, SRID_VALUE) USING the_geom::public.geometry(multilinestring, SRID_VALUE);

ALTER TABLE dwfzone ENABLE TRIGGER USER;
ALTER TABLE drainzone ENABLE TRIGGER USER;
ALTER TABLE omunit ENABLE TRIGGER USER;
ALTER TABLE macroomunit ENABLE TRIGGER USER;


DROP RULE IF EXISTS omzone_expl ON omzone;
DROP RULE IF EXISTS dwfzone_expl ON dwfzone;


CREATE INDEX IF NOT EXISTS idx_gully_arc_id ON gully USING btree (arc_id);

DROP TABLE IF EXISTS dwfzone_graph;


CREATE TABLE IF NOT EXISTS man_netsamplepoint (
	node_id int4 NOT NULL,
	lab_code varchar(30) NULL,
	place_name varchar(254) NULL,
	cabinet varchar(150) NULL,
	CONSTRAINT man_netsamplepoint_pkey PRIMARY KEY (node_id),
	CONSTRAINT man_netsamplepoint_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE VIEW vf_link AS
SELECT l.link_id, COALESCE(pp.state, l.state) AS p_state
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
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.state_id = COALESCE(pp.state, l.state) AND ss.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_sector ssec
          WHERE ssec.sector_id = l.sector_id AND ssec.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_municipality sm
          WHERE sm.muni_id = l.muni_id AND sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE (se.expl_id = ANY (array_append(l.expl_visibility::integer[], l.expl_id))) AND se.cur_user = CURRENT_USER));


CREATE OR REPLACE VIEW ve_inp_dscenario_pattern
AS SELECT p.dscenario_id,
    p.pattern_id,
    p.pattern_type,
    p.observ,
    p.tsparameters,
    p.expl_id,
    p.log,
    p.active
FROM inp_dscenario_pattern p
JOIN cat_dscenario d USING (dscenario_id)
WHERE EXISTS (
	SELECT 1
	FROM selector_inp_dscenario s
	WHERE s.dscenario_id = p.dscenario_id
	AND s.cur_user = CURRENT_USER
);

CREATE OR REPLACE VIEW ve_inp_dscenario_pattern_value
AS SELECT
	p.dscenario_id,
    p.pattern_id,
    p.observ,
    p.tsparameters,
    p.expl_id,
    pv.factor_1,
    pv.factor_2,
    pv.factor_3,
    pv.factor_4,
    pv.factor_5,
    pv.factor_6,
    pv.factor_7,
    pv.factor_8,
    pv.factor_9,
    pv.factor_10,
    pv.factor_11,
    pv.factor_12,
    pv.factor_13,
    pv.factor_14,
    pv.factor_15,
    pv.factor_16,
    pv.factor_17,
    pv.factor_18,
    pv.factor_19,
    pv.factor_20,
    pv.factor_21,
    pv.factor_22,
    pv.factor_23,
    pv.factor_24
FROM inp_dscenario_pattern p
JOIN inp_dscenario_pattern_value pv USING (pattern_id)
WHERE EXISTS (
	SELECT 1
	FROM selector_inp_dscenario s
	WHERE s.dscenario_id = p.dscenario_id
	AND s.cur_user = CURRENT_USER
) AND EXISTS (
	SELECT 1
	FROM selector_expl s
	WHERE s.expl_id = p.expl_id
	AND s.cur_user = CURRENT_USER
);


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
        ), sector_visibility_agg AS (
            SELECT node_id, array_agg(sector_id ORDER BY sector_id) AS sector_visibility
            FROM node_x_sector_visibility
            GROUP BY node_id
        ),
        muni_visibility_agg AS (
            SELECT node_id, array_agg(muni_id ORDER BY muni_id) AS muni_visibility
            FROM node_x_municipality_visibility
            GROUP BY node_id
        )
 SELECT n.node_id,
    n.code,
    n.sys_code,
    n.top_elev,
    n.custom_top_elev,
    COALESCE(n.custom_top_elev, n.top_elev) AS sys_top_elev,
    n.ymax,
    COALESCE(COALESCE(n.custom_top_elev, n.top_elev) - COALESCE(n.custom_elev, n.elev), n.ymax) AS sys_ymax,
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
    vm.region_id,
    vm.province_id,
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
    vf.p_state,
    n.uuid,
    n.treatment_type,
    n.has_treatment,
    sva.sector_visibility,
    mva.muni_visibility
  FROM node n
  JOIN vf_node vf ON vf.node_id = n.node_id
  JOIN cat_node ON n.nodecat_id::text = cat_node.id::text
  JOIN cat_feature ON cat_feature.id::text = n.node_type::text
  JOIN exploitation ON n.expl_id = exploitation.expl_id
  JOIN v_municipality vm ON n.muni_id = vm.muni_id
  JOIN value_state_type vst ON vst.id = n.state_type
  JOIN sector_table ON sector_table.sector_id = n.sector_id
  LEFT JOIN omzone_table ON omzone_table.omzone_id = n.omzone_id
  LEFT JOIN drainzone_table ON n.omzone_id = drainzone_table.drainzone_id
  LEFT JOIN dwfzone_table ON n.dwfzone_id = dwfzone_table.dwfzone_id
  LEFT JOIN node_add ON node_add.node_id = n.node_id
  LEFT JOIN sector_visibility_agg sva ON sva.node_id = n.node_id
  LEFT JOIN muni_visibility_agg mva ON mva.node_id = n.node_id;


CREATE OR REPLACE VIEW ve_arc AS
WITH typevalue AS (
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
    COALESCE(COALESCE(a.node_custom_top_elev_1, a.node_top_elev_1) - COALESCE(a.custom_elev1, a.elev1, a.node_custom_elev_1, a.node_elev_1), a.y1) AS sys_y1,
    COALESCE(COALESCE(a.node_custom_top_elev_1, a.node_top_elev_1) - COALESCE(a.custom_elev1, a.elev1, a.node_custom_elev_1, a.node_elev_1), a.y1) - cat_arc.geom1 AS r1,
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
    COALESCE(COALESCE(a.node_custom_top_elev_2, a.node_top_elev_2) - COALESCE(a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2), a.y2) AS sys_y2,
    COALESCE(COALESCE(a.node_custom_top_elev_2, a.node_top_elev_2) - COALESCE(a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2), a.y2) - cat_arc.geom1 AS r2,
    COALESCE(a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2) - COALESCE(a.node_custom_elev_2, a.node_elev_2) AS z2,
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
	(case when sys_slope is null then
	((coalesce (node_custom_elev_1, node_elev_1, elev1, node_top_elev_1-y1, node_elev_1)-coalesce (node_custom_elev_2, node_elev_2, elev2, node_top_elev_2-y2, node_elev_2))/st_length(a.the_geom))::numeric(12,4)
	else sys_slope end) as slope,
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
    a.treatment_type
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
  LEFT JOIN arc_add ON arc_add.arc_id = a.arc_id;


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
    vf.arc_id,
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
    vf.pjoint_id,
    vf.pjoint_type,
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
    c.has_treatment
  FROM connec c
  JOIN vf_connec vf on vf.connec_id = c.connec_id
  JOIN cat_connec ON cat_connec.id::text = c.conneccat_id::text
  JOIN cat_feature ON cat_feature.id::text = c.connec_type::text
  JOIN exploitation ON c.expl_id = exploitation.expl_id
  JOIN v_municipality vm ON c.muni_id = vm.muni_id
  JOIN value_state_type vst ON vst.id = c.state_type
  JOIN sector_table ON sector_table.sector_id = c.sector_id
  LEFT JOIN omzone_table ON omzone_table.omzone_id = c.omzone_id
  LEFT JOIN drainzone_table ON c.omzone_id = drainzone_table.drainzone_id
  LEFT JOIN dwfzone_table ON c.dwfzone_id = dwfzone_table.dwfzone_id;


CREATE OR REPLACE VIEW vf_gully AS
SELECT
  g.gully_id,
  COALESCE(pp.state, g.state) AS p_state,
  COALESCE(pp.arc_id, g.arc_id) AS arc_id,
  COALESCE(pp.exit_id, g.pjoint_id) AS pjoint_id,
  COALESCE(pp.exit_type, g.pjoint_type) AS pjoint_type
FROM gully g
LEFT JOIN LATERAL ( SELECT pp_1.state,
            pp_1.arc_id,
            l.exit_id,
            l.exit_type
           FROM plan_psector_x_gully pp_1
             LEFT JOIN link l ON l.link_id = pp_1.link_id AND l.state = 2
          WHERE pp_1.gully_id = g.gully_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC, pp_1.state DESC
         LIMIT 1) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.state_id = COALESCE(pp.state, g.state) AND ss.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_sector ssec
          WHERE ssec.sector_id = g.sector_id AND ssec.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_municipality sm
          WHERE sm.muni_id = g.muni_id AND sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE (se.expl_id = ANY (array_append(g.expl_visibility::integer[], g.expl_id))) AND se.cur_user = CURRENT_USER));

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
    vf.arc_id,
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
    vf.pjoint_id,
    vf.pjoint_type,
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
    gully.has_treatment
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

CREATE OR REPLACE VIEW v_rtc_hydrometer
AS WITH sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        )
 SELECT ext_rtc_hydrometer.hydrometer_id,
    ext_rtc_hydrometer.code AS hydrometer_customer_code,
    connec.connec_id AS feature_id,
    'CONNEC'::text AS feature_type,
    COALESCE(ext_rtc_hydrometer.customer_code, 'XXXX'::character varying) AS customer_code,
    ext_rtc_hydrometer_state.name AS state,
    v_municipality.name AS muni_name,
    connec.expl_id,
    exploitation.name AS expl_name,
    ext_rtc_hydrometer.plot_code,
    ext_rtc_hydrometer.priority_id,
    ext_rtc_hydrometer.catalog_id,
    ext_rtc_hydrometer.category_id,
    ext_rtc_hydrometer.hydro_number,
    ext_rtc_hydrometer.hydro_man_date,
    ext_rtc_hydrometer.crm_number,
    ext_rtc_hydrometer.customer_name,
    ext_rtc_hydrometer.address1,
    ext_rtc_hydrometer.address2,
    ext_rtc_hydrometer.address3,
    ext_rtc_hydrometer.address2_1,
    ext_rtc_hydrometer.address2_2,
    ext_rtc_hydrometer.address2_3,
    ext_rtc_hydrometer.m3_volume,
    ext_rtc_hydrometer.start_date,
    ext_rtc_hydrometer.end_date,
    ext_rtc_hydrometer.update_date,
        CASE
            WHEN (( SELECT config_param_system.value
               FROM config_param_system
              WHERE config_param_system.parameter::text = 'edit_hydro_link_absolute_path'::text)) IS NULL THEN ext_rtc_hydrometer.link
            ELSE concat(( SELECT config_param_system.value
               FROM config_param_system
              WHERE config_param_system.parameter::text = 'edit_hydro_link_absolute_path'::text), ext_rtc_hydrometer.link)
        END AS hydrometer_link,
    ext_rtc_hydrometer_state.is_operative,
    ext_rtc_hydrometer.shutdown_date
   FROM ext_rtc_hydrometer
     JOIN ext_rtc_hydrometer_state ON ext_rtc_hydrometer_state.id = ext_rtc_hydrometer.state_id
     JOIN connec ON connec.customer_code = ext_rtc_hydrometer.customer_code
     LEFT JOIN v_municipality ON v_municipality.muni_id = connec.muni_id
     LEFT JOIN exploitation ON exploitation.expl_id = connec.expl_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = connec.expl_id));



CREATE OR REPLACE VIEW v_rtc_hydrometer_x_connec
AS WITH sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        )
 SELECT ext_rtc_hydrometer.hydrometer_id,
    ext_rtc_hydrometer.code AS hydrometer_customer_code,
    COALESCE(connec.connec_id, NULL::integer) AS connec_id,
    COALESCE(ext_rtc_hydrometer.customer_code::character varying, 'XXXX'::character varying) AS connec_customer_code,
    ext_rtc_hydrometer_state.name AS state,
    v_municipality.name AS muni_name,
    connec.expl_id,
    exploitation.name AS expl_name,
    ext_rtc_hydrometer.plot_code,
    ext_rtc_hydrometer.priority_id,
    ext_rtc_hydrometer.catalog_id,
    ext_rtc_hydrometer.category_id,
    ext_rtc_hydrometer.hydro_number,
    ext_rtc_hydrometer.hydro_man_date,
    ext_rtc_hydrometer.crm_number,
    ext_rtc_hydrometer.customer_name,
    ext_rtc_hydrometer.address1,
    ext_rtc_hydrometer.address2,
    ext_rtc_hydrometer.address3,
    ext_rtc_hydrometer.address2_1,
    ext_rtc_hydrometer.address2_2,
    ext_rtc_hydrometer.address2_3,
    ext_rtc_hydrometer.m3_volume,
    ext_rtc_hydrometer.start_date,
    ext_rtc_hydrometer.end_date,
    ext_rtc_hydrometer.update_date,
        CASE
            WHEN (( SELECT config_param_system.value
               FROM config_param_system
              WHERE config_param_system.parameter::text = 'edit_hydro_link_absolute_path'::text)) IS NULL THEN ext_rtc_hydrometer.link
            ELSE concat(( SELECT config_param_system.value
               FROM config_param_system
              WHERE config_param_system.parameter::text = 'edit_hydro_link_absolute_path'::text), ext_rtc_hydrometer.link)
        END AS hydrometer_link
   FROM ext_rtc_hydrometer
     JOIN ext_rtc_hydrometer_state ON ext_rtc_hydrometer_state.id = ext_rtc_hydrometer.state_id
     JOIN connec ON connec.customer_code = ext_rtc_hydrometer.customer_code
     LEFT JOIN v_municipality ON v_municipality.muni_id = connec.muni_id
     LEFT JOIN exploitation ON exploitation.expl_id = connec.expl_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = connec.expl_id));


CREATE OR REPLACE VIEW v_ui_hydroval
AS SELECT ext_rtc_hydrometer_x_data.id,
    connec.connec_id AS feature_id,
    connec.arc_id,
    ext_rtc_hydrometer_x_data.hydrometer_id,
    ext_rtc_hydrometer.code AS hydrometer_customer_code,
    ext_rtc_hydrometer.catalog_id,
    ext_cat_hydrometer.madeby,
    ext_cat_hydrometer.class,
    ext_rtc_hydrometer_x_data.cat_period_id,
    ext_rtc_hydrometer_x_data.sum,
    ext_rtc_hydrometer_x_data.custom_sum,
    crmtype.idval AS value_type,
    crmstatus.idval AS value_status,
    crmstate.idval AS value_state
   FROM ext_rtc_hydrometer_x_data
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer_x_data.hydrometer_id::text = ext_rtc_hydrometer.hydrometer_id::text
     LEFT JOIN ext_cat_hydrometer ON ext_cat_hydrometer.id::text = ext_rtc_hydrometer.catalog_id::text
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     LEFT JOIN crm_typevalue crmtype ON ext_rtc_hydrometer_x_data.value_type = crmtype.id::integer AND crmtype.typevalue::text = 'crm_value_type'::text
     LEFT JOIN crm_typevalue crmstatus ON ext_rtc_hydrometer_x_data.value_status = crmstatus.id::integer AND crmstatus.typevalue::text = 'crm_value_status'::text
     LEFT JOIN crm_typevalue crmstate ON ext_rtc_hydrometer_x_data.value_state = crmstate.id::integer AND crmstate.typevalue::text = 'crm_value_state'::text
  ORDER BY ext_rtc_hydrometer_x_data.id;


CREATE OR REPLACE VIEW v_ui_hydroval_x_connec
AS SELECT ext_rtc_hydrometer_x_data.id,
    connec.connec_id,
    connec.arc_id,
    ext_rtc_hydrometer_x_data.hydrometer_id,
    ext_rtc_hydrometer.catalog_id,
    ext_cat_hydrometer.madeby,
    ext_cat_hydrometer.class,
    ext_rtc_hydrometer_x_data.cat_period_id,
    ext_rtc_hydrometer_x_data.sum,
    ext_rtc_hydrometer_x_data.custom_sum,
    crmtype.idval AS value_type,
    crmstatus.idval AS value_status,
    crmstate.idval AS value_state
   FROM ext_rtc_hydrometer_x_data
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer_x_data.hydrometer_id::text = ext_rtc_hydrometer.hydrometer_id::text
     LEFT JOIN ext_cat_hydrometer ON ext_cat_hydrometer.id::text = ext_rtc_hydrometer.catalog_id::text
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     LEFT JOIN crm_typevalue crmtype ON ext_rtc_hydrometer_x_data.value_type = crmtype.id::integer AND crmtype.typevalue::text = 'crm_value_type'::text
     LEFT JOIN crm_typevalue crmstatus ON ext_rtc_hydrometer_x_data.value_status = crmstatus.id::integer AND crmstatus.typevalue::text = 'crm_value_status'::text
     LEFT JOIN crm_typevalue crmstate ON ext_rtc_hydrometer_x_data.value_state = crmstate.id::integer AND crmstate.typevalue::text = 'crm_value_state'::text
  ORDER BY ext_rtc_hydrometer_x_data.id;


CREATE OR REPLACE VIEW ve_rtc_hydro_data_x_connec
AS SELECT ext_rtc_hydrometer_x_data.id,
    connec.connec_id,
    ext_rtc_hydrometer_x_data.hydrometer_id,
    ext_rtc_hydrometer.code,
    ext_rtc_hydrometer.catalog_id,
    ext_rtc_hydrometer_x_data.cat_period_id,
    ext_cat_period.code AS cat_period_code,
    ext_rtc_hydrometer_x_data.value_date,
    ext_rtc_hydrometer_x_data.sum,
    ext_rtc_hydrometer_x_data.custom_sum
   FROM ext_rtc_hydrometer_x_data
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer_x_data.hydrometer_id::bigint = ext_rtc_hydrometer.hydrometer_id::bigint
     LEFT JOIN ext_cat_hydrometer ON ext_cat_hydrometer.id::bigint = ext_rtc_hydrometer.catalog_id::bigint
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     JOIN ext_cat_period ON ext_rtc_hydrometer_x_data.cat_period_id::text = ext_cat_period.id::text
  ORDER BY ext_rtc_hydrometer_x_data.hydrometer_id, ext_rtc_hydrometer_x_data.cat_period_id DESC;

SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"data":{"action":"MULTI-DELETE"}, "feature":{"parentLayer":"ve_link"}}$$);
DROP VIEW IF EXISTS ve_link_gully;
DROP VIEW IF EXISTS ve_link_connec;
DROP VIEW IF EXISTS ve_link;

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
    cat_link.matcat_id,
    cat_link.dnom AS cat_dnom,
    cat_link.dint AS cat_dint,
    cat_link.pnom AS cat_pnom,
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
    vf.p_state,
    l.uuid,
    l.omunit_id,
    l.treatment_type
  FROM link l
  JOIN vf_link vf ON vf.link_id = l.link_id
  JOIN exploitation ON l.expl_id = exploitation.expl_id
  JOIN sector_table ON l.sector_id = sector_table.sector_id
  JOIN cat_link ON cat_link.id::text = l.linkcat_id::text
  JOIN cat_feature ON cat_feature.id::text = l.link_type::text
  LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
  LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
  LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
  LEFT JOIN inp_network_mode ON true;

CREATE OR REPLACE VIEW ve_link_connec
AS SELECT link_id,
    code,
    sys_code,
    top_elev1,
    y1,
    elevation1,
    exit_id,
    exit_type,
    top_elev2,
    y2,
    elevation2,
    feature_type,
    feature_id,
    link_type,
    sys_type,
    linkcat_id,
    state,
    state_type,
    expl_id,
    macroexpl_id,
    muni_id,
    sector_id,
    macrosector_id,
    sector_type,
    drainzone_id,
    drainzone_type,
    drainzone_outfall,
    dwfzone_id,
    dwfzone_type,
    dwfzone_outfall,
    omzone_id,
    macroomzone_id,
    dma_id,
    location_type,
    fluid_type,
    custom_length,
    gis_length,
    sys_slope,
    annotation,
    observ,
    comment,
    descript,
    link,
    num_value,
    workcat_id,
    workcat_id_end,
    builtdate,
    enddate,
    brand_id,
    model_id,
    private_linkcat_id,
    verified,
    uncertain,
    userdefined_geom,
    datasource,
    is_operative,
    sector_style,
    omzone_style,
    drainzone_style,
    dwfzone_style,
    lock_level,
    expl_visibility,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom
   FROM ve_link
  WHERE feature_type::text = 'CONNEC'::text;


CREATE OR REPLACE VIEW ve_link_gully
AS SELECT link_id,
    code,
    sys_code,
    top_elev1,
    y1,
    elevation1,
    exit_id,
    exit_type,
    top_elev2,
    y2,
    elevation2,
    feature_type,
    feature_id,
    link_type,
    sys_type,
    linkcat_id,
    state,
    state_type,
    expl_id,
    macroexpl_id,
    muni_id,
    sector_id,
    macrosector_id,
    sector_type,
    drainzone_id,
    drainzone_type,
    drainzone_outfall,
    dwfzone_id,
    dwfzone_type,
    dwfzone_outfall,
    omzone_id,
    macroomzone_id,
    dma_id,
    location_type,
    fluid_type,
    custom_length,
    gis_length,
    sys_slope,
    annotation,
    observ,
    comment,
    descript,
    link,
    num_value,
    workcat_id,
    workcat_id_end,
    builtdate,
    enddate,
    brand_id,
    model_id,
    private_linkcat_id,
    verified,
    uncertain,
    userdefined_geom,
    datasource,
    is_operative,
    sector_style,
    omzone_style,
    drainzone_style,
    dwfzone_style,
    lock_level,
    expl_visibility,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom
   FROM ve_link
  WHERE feature_type::text = 'GULLY'::text;



CREATE OR REPLACE VIEW v_plan_arc
AS SELECT arc_id,
    node_1,
    node_2,
    arc_type,
    arccat_id,
    epa_type,
    state,
    expl_id,
    sector_id,
    annotation,
    soilcat_id,
    y1,
    y2,
    mean_y,
    z1,
    z2,
    thickness,
    width,
    b,
    bulk,
    geom1,
    area,
    y_param,
    total_y,
    rec_y,
    geom1_ext,
    calculed_y,
    m3mlexc,
    m2mltrenchl,
    m2mlbottom,
    m2mlpav,
    m3mlprotec,
    m3mlfill,
    m3mlexcess,
    m3exc_cost,
    m2trenchl_cost,
    m2bottom_cost,
    m2pav_cost,
    m3protec_cost,
    m3fill_cost,
    m3excess_cost,
    cost_unit,
    pav_cost,
    exc_cost,
    trenchl_cost,
    base_cost,
    protec_cost,
    fill_cost,
    excess_cost,
    arc_cost,
    cost,
    length,
    budget,
    other_budget,
        CASE
            WHEN other_budget IS NOT NULL THEN (budget + other_budget)::numeric(14,2)
            ELSE budget
        END AS total_budget,
    the_geom
   FROM ( WITH v_plan_aux_arc_cost AS (
                 WITH v_plan_aux_arc_ml AS (
                         SELECT ve_arc.arc_id,
                            ve_arc.y1,
                            ve_arc.y2,
                                CASE
                                    WHEN (ve_arc.y1 * ve_arc.y2) = 0::numeric OR (ve_arc.y1 * ve_arc.y2) IS NULL THEN v_price_x_catarc.estimated_depth
                                    ELSE ((ve_arc.y1 + ve_arc.y2) / 2::numeric)::numeric(12,2)
                                END AS mean_y,
                            ve_arc.arccat_id,
                            COALESCE(v_price_x_catarc.geom1, 0::numeric)::numeric(12,4) AS geom1,
                            COALESCE(v_price_x_catarc.z1, 0::numeric)::numeric(12,2) AS z1,
                            COALESCE(v_price_x_catarc.z2, 0::numeric)::numeric(12,2) AS z2,
                            COALESCE(v_price_x_catarc.area, 0::numeric)::numeric(12,4) AS area,
                            COALESCE(v_price_x_catarc.width, 0::numeric)::numeric(12,2) AS width,
                            COALESCE(v_price_x_catarc.thickness / 1000::numeric, 0::numeric)::numeric(12,2) AS bulk,
                            v_price_x_catarc.cost_unit,
                            COALESCE(v_price_x_catarc.cost, 0::numeric)::numeric(12,2) AS arc_cost,
                            COALESCE(v_price_x_catarc.m2bottom_cost, 0::numeric)::numeric(12,2) AS m2bottom_cost,
                            COALESCE(v_price_x_catarc.m3protec_cost, 0::numeric)::numeric(12,2) AS m3protec_cost,
                            v_price_x_catsoil.id AS soilcat_id,
                            COALESCE(v_price_x_catsoil.y_param, 10::numeric)::numeric(5,2) AS y_param,
                            COALESCE(v_price_x_catsoil.b, 0::numeric)::numeric(5,2) AS b,
                            COALESCE(v_price_x_catsoil.trenchlining, 0::numeric) AS trenchlining,
                            COALESCE(v_price_x_catsoil.m3exc_cost, 0::numeric)::numeric(12,2) AS m3exc_cost,
                            COALESCE(v_price_x_catsoil.m3fill_cost, 0::numeric)::numeric(12,2) AS m3fill_cost,
                            COALESCE(v_price_x_catsoil.m3excess_cost, 0::numeric)::numeric(12,2) AS m3excess_cost,
                            COALESCE(v_price_x_catsoil.m2trenchl_cost, 0::numeric)::numeric(12,2) AS m2trenchl_cost,
                            COALESCE(v_plan_aux_arc_pavement.thickness, 0::numeric)::numeric(12,2) AS thickness,
                            COALESCE(v_plan_aux_arc_pavement.m2pav_cost, 0::numeric) AS m2pav_cost,
                            ve_arc.state,
                            ve_arc.expl_id,
                            ve_arc.the_geom
                           FROM ve_arc
                             LEFT JOIN v_price_x_catarc ON ve_arc.arccat_id::text = v_price_x_catarc.id::text
                             LEFT JOIN v_price_x_catsoil ON ve_arc.soilcat_id::text = v_price_x_catsoil.id::text
                             LEFT JOIN v_plan_aux_arc_pavement ON v_plan_aux_arc_pavement.arc_id = ve_arc.arc_id
                          WHERE v_plan_aux_arc_pavement.arc_id IS NOT NULL
                        )
                 SELECT v_plan_aux_arc_ml.arc_id,
                    v_plan_aux_arc_ml.y1,
                    v_plan_aux_arc_ml.y2,
                    v_plan_aux_arc_ml.mean_y,
                    v_plan_aux_arc_ml.arccat_id,
                    v_plan_aux_arc_ml.geom1,
                    v_plan_aux_arc_ml.z1,
                    v_plan_aux_arc_ml.z2,
                    v_plan_aux_arc_ml.area,
                    v_plan_aux_arc_ml.width,
                    v_plan_aux_arc_ml.bulk,
                    v_plan_aux_arc_ml.cost_unit,
                    v_plan_aux_arc_ml.arc_cost,
                    v_plan_aux_arc_ml.m2bottom_cost,
                    v_plan_aux_arc_ml.m3protec_cost,
                    v_plan_aux_arc_ml.soilcat_id,
                    v_plan_aux_arc_ml.y_param,
                    v_plan_aux_arc_ml.b,
                    v_plan_aux_arc_ml.trenchlining,
                    v_plan_aux_arc_ml.m3exc_cost,
                    v_plan_aux_arc_ml.m3fill_cost,
                    v_plan_aux_arc_ml.m3excess_cost,
                    v_plan_aux_arc_ml.m2trenchl_cost,
                    v_plan_aux_arc_ml.thickness,
                    v_plan_aux_arc_ml.m2pav_cost,
                    v_plan_aux_arc_ml.state,
                    v_plan_aux_arc_ml.expl_id,
                    (2::numeric * ((v_plan_aux_arc_ml.mean_y + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric)::numeric(12,3) AS m2mlpavement,
                    (2::numeric * v_plan_aux_arc_ml.b + v_plan_aux_arc_ml.width)::numeric(12,3) AS m2mlbase,
                    (v_plan_aux_arc_ml.mean_y + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness)::numeric(12,3) AS calculed_y,
                    (v_plan_aux_arc_ml.trenchlining * 2::numeric * (v_plan_aux_arc_ml.mean_y + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness))::numeric(12,3) AS m2mltrenchl,
                    ((v_plan_aux_arc_ml.mean_y + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) * (2::numeric * ((v_plan_aux_arc_ml.mean_y + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width) / 2::numeric)::numeric(12,3) AS m3mlexc,
                    ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.geom1 + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) * ((2::numeric * ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.geom1 + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + (v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width)) / 2::numeric) - v_plan_aux_arc_ml.area)::numeric(12,3) AS m3mlprotec,
                    ((v_plan_aux_arc_ml.mean_y + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) * (2::numeric * ((v_plan_aux_arc_ml.mean_y + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width) / 2::numeric - (v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.geom1 + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) * ((2::numeric * ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.geom1 + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + (v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width)) / 2::numeric))::numeric(12,3) AS m3mlfill,
                    ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.geom1 + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) * ((2::numeric * ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.geom1 + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + (v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width)) / 2::numeric))::numeric(12,3) AS m3mlexcess,
                    v_plan_aux_arc_ml.the_geom
                   FROM v_plan_aux_arc_ml
                  WHERE v_plan_aux_arc_ml.arc_id IS NOT NULL
                )
         SELECT v_plan_aux_arc_cost.arc_id,
            arc.node_1,
            arc.node_2,
            arc.arc_type::text AS arc_type,
            v_plan_aux_arc_cost.arccat_id,
            arc.epa_type,
            v_plan_aux_arc_cost.state,
            v_plan_aux_arc_cost.expl_id,
            arc.sector_id,
            arc.annotation,
            v_plan_aux_arc_cost.soilcat_id,
            v_plan_aux_arc_cost.y1,
            v_plan_aux_arc_cost.y2,
            v_plan_aux_arc_cost.mean_y,
            v_plan_aux_arc_cost.z1,
            v_plan_aux_arc_cost.z2,
            v_plan_aux_arc_cost.thickness,
            v_plan_aux_arc_cost.width,
            v_plan_aux_arc_cost.b,
            v_plan_aux_arc_cost.bulk,
            v_plan_aux_arc_cost.geom1,
            v_plan_aux_arc_cost.area,
            v_plan_aux_arc_cost.y_param,
            (v_plan_aux_arc_cost.calculed_y + v_plan_aux_arc_cost.thickness)::numeric(12,2) AS total_y,
            (v_plan_aux_arc_cost.calculed_y - 2::numeric * v_plan_aux_arc_cost.bulk - v_plan_aux_arc_cost.z1 - v_plan_aux_arc_cost.z2 - v_plan_aux_arc_cost.geom1)::numeric(12,2) AS rec_y,
            (v_plan_aux_arc_cost.geom1 + 2::numeric * v_plan_aux_arc_cost.bulk)::numeric(12,2) AS geom1_ext,
            v_plan_aux_arc_cost.calculed_y,
            v_plan_aux_arc_cost.m3mlexc,
            v_plan_aux_arc_cost.m2mltrenchl,
            v_plan_aux_arc_cost.m2mlbase AS m2mlbottom,
            v_plan_aux_arc_cost.m2mlpavement AS m2mlpav,
            v_plan_aux_arc_cost.m3mlprotec,
            v_plan_aux_arc_cost.m3mlfill,
            v_plan_aux_arc_cost.m3mlexcess,
            v_plan_aux_arc_cost.m3exc_cost,
            v_plan_aux_arc_cost.m2trenchl_cost,
            v_plan_aux_arc_cost.m2bottom_cost,
            v_plan_aux_arc_cost.m2pav_cost::numeric(12,2) AS m2pav_cost,
            v_plan_aux_arc_cost.m3protec_cost,
            v_plan_aux_arc_cost.m3fill_cost,
            v_plan_aux_arc_cost.m3excess_cost,
            v_plan_aux_arc_cost.cost_unit,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::numeric
                    ELSE v_plan_aux_arc_cost.m2mlpavement * v_plan_aux_arc_cost.m2pav_cost
                END::numeric(12,3) AS pav_cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::numeric
                    ELSE v_plan_aux_arc_cost.m3mlexc * v_plan_aux_arc_cost.m3exc_cost
                END::numeric(12,3) AS exc_cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::numeric
                    ELSE v_plan_aux_arc_cost.m2mltrenchl * v_plan_aux_arc_cost.m2trenchl_cost
                END::numeric(12,3) AS trenchl_cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::numeric
                    ELSE v_plan_aux_arc_cost.m2mlbase * v_plan_aux_arc_cost.m2bottom_cost
                END::numeric(12,3) AS base_cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::numeric
                    ELSE v_plan_aux_arc_cost.m3mlprotec * v_plan_aux_arc_cost.m3protec_cost
                END::numeric(12,3) AS protec_cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::numeric
                    ELSE v_plan_aux_arc_cost.m3mlfill * v_plan_aux_arc_cost.m3fill_cost
                END::numeric(12,3) AS fill_cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::numeric
                    ELSE v_plan_aux_arc_cost.m3mlexcess * v_plan_aux_arc_cost.m3excess_cost
                END::numeric(12,3) AS excess_cost,
            v_plan_aux_arc_cost.arc_cost::numeric(12,3) AS arc_cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN v_plan_aux_arc_cost.arc_cost
                    ELSE v_plan_aux_arc_cost.m3mlexc * v_plan_aux_arc_cost.m3exc_cost + v_plan_aux_arc_cost.m2mlbase * v_plan_aux_arc_cost.m2bottom_cost + v_plan_aux_arc_cost.m2mltrenchl * v_plan_aux_arc_cost.m2trenchl_cost + v_plan_aux_arc_cost.m3mlprotec * v_plan_aux_arc_cost.m3protec_cost + v_plan_aux_arc_cost.m3mlfill * v_plan_aux_arc_cost.m3fill_cost + v_plan_aux_arc_cost.m3mlexcess * v_plan_aux_arc_cost.m3excess_cost + v_plan_aux_arc_cost.m2mlpavement * v_plan_aux_arc_cost.m2pav_cost + v_plan_aux_arc_cost.arc_cost
                END::numeric(12,2) AS cost,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN NULL::double precision
                    ELSE st_length2d(v_plan_aux_arc_cost.the_geom)
                END::numeric(12,2) AS length,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN v_plan_aux_arc_cost.arc_cost
                    ELSE st_length2d(v_plan_aux_arc_cost.the_geom)::numeric(12,2) * (v_plan_aux_arc_cost.m3mlexc * v_plan_aux_arc_cost.m3exc_cost + v_plan_aux_arc_cost.m2mlbase * v_plan_aux_arc_cost.m2bottom_cost + v_plan_aux_arc_cost.m2mltrenchl * v_plan_aux_arc_cost.m2trenchl_cost + v_plan_aux_arc_cost.m3mlprotec * v_plan_aux_arc_cost.m3protec_cost + v_plan_aux_arc_cost.m3mlfill * v_plan_aux_arc_cost.m3fill_cost + v_plan_aux_arc_cost.m3mlexcess * v_plan_aux_arc_cost.m3excess_cost + v_plan_aux_arc_cost.m2mlpavement * v_plan_aux_arc_cost.m2pav_cost + v_plan_aux_arc_cost.arc_cost)::numeric(14,2)
                END::numeric(14,2) AS budget,
            COALESCE(v_plan_aux_arc_connec.connec_total_cost, 0::numeric) + COALESCE(v_plan_aux_arc_gully.gully_total_cost, 0::numeric) AS other_budget,
            v_plan_aux_arc_cost.the_geom
           FROM v_plan_aux_arc_cost
             JOIN arc ON v_plan_aux_arc_cost.arc_id = arc.arc_id
             LEFT JOIN LATERAL ( WITH selected_psector AS (
                         SELECT selector_psector.psector_id
                           FROM selector_psector
                          WHERE selector_psector.cur_user = CURRENT_USER
                        ), candidate_connec AS (
                         SELECT connec.connec_id
                           FROM connec
                          WHERE connec.arc_id = v_plan_aux_arc_cost.arc_id
                        UNION
                         SELECT plan_psector_x_connec.connec_id
                           FROM plan_psector_x_connec
                             JOIN selected_psector USING (psector_id)
                          WHERE plan_psector_x_connec.arc_id = v_plan_aux_arc_cost.arc_id
                        ), vf_connec_arc AS (
                         SELECT connec.connec_id,
                            COALESCE(plan_connec.state, connec.state) AS p_state,
                            COALESCE(plan_connec.arc_id, connec.arc_id) AS arc_id,
                            connec.expl_id,
                            connec.expl_visibility,
                            connec.sector_id,
                            connec.muni_id
                           FROM connec
                             JOIN candidate_connec USING (connec_id)
                             LEFT JOIN LATERAL ( SELECT pp.state,
                                    pp.arc_id,
                                    link.exit_id,
                                    link.exit_type
                                   FROM plan_psector_x_connec pp
                                     LEFT JOIN link ON link.link_id = pp.link_id AND link.state = 2
                                  WHERE pp.connec_id = connec.connec_id AND (pp.psector_id IN ( SELECT selected_psector.psector_id
   FROM selected_psector))
                                  ORDER BY pp.psector_id DESC, pp.state DESC
                                 LIMIT 1) plan_connec ON true
                          WHERE (EXISTS ( SELECT 1
                                   FROM selector_state
                                  WHERE selector_state.state_id = COALESCE(plan_connec.state, connec.state) AND selector_state.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
                                   FROM selector_sector
                                  WHERE selector_sector.sector_id = connec.sector_id AND selector_sector.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
                                   FROM selector_municipality
                                  WHERE selector_municipality.muni_id = connec.muni_id AND selector_municipality.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
                                   FROM selector_expl
                                  WHERE (selector_expl.expl_id = ANY (array_append(connec.expl_visibility::integer[], connec.expl_id))) AND selector_expl.cur_user = CURRENT_USER))
                        )
                 SELECT (min(v_price_compost.price) * count(*)::numeric)::numeric(12,2) AS connec_total_cost
                   FROM vf_connec_arc
                     JOIN arc arc_1 ON arc_1.arc_id = vf_connec_arc.arc_id
                     JOIN cat_arc ON cat_arc.id::text = arc_1.arccat_id::text
                     LEFT JOIN v_price_compost ON cat_arc.connect_cost = v_price_compost.id::text
                  WHERE vf_connec_arc.arc_id = v_plan_aux_arc_cost.arc_id) v_plan_aux_arc_connec ON true
             LEFT JOIN LATERAL ( WITH selected_psector AS (
                         SELECT selector_psector.psector_id
                           FROM selector_psector
                          WHERE selector_psector.cur_user = CURRENT_USER
                        ), candidate_gully AS (
                         SELECT gully.gully_id
                           FROM gully
                          WHERE gully.arc_id = v_plan_aux_arc_cost.arc_id
                        UNION
                         SELECT plan_psector_x_gully.gully_id
                           FROM plan_psector_x_gully
                             JOIN selected_psector USING (psector_id)
                          WHERE plan_psector_x_gully.arc_id = v_plan_aux_arc_cost.arc_id
                        ), vf_gully_arc AS (
                         SELECT gully.gully_id,
                            COALESCE(plan_gully.state, gully.state) AS p_state,
                            COALESCE(plan_gully.arc_id, gully.arc_id) AS arc_id,
                            gully.expl_id,
                            gully.expl_visibility,
                            gully.sector_id,
                            gully.muni_id
                           FROM gully
                             JOIN candidate_gully USING (gully_id)
                             LEFT JOIN LATERAL ( SELECT pp.state,
                                    pp.arc_id,
                                    link.exit_id,
                                    link.exit_type
                                   FROM plan_psector_x_gully pp
                                     LEFT JOIN link ON link.link_id = pp.link_id AND link.state = 2
                                  WHERE pp.gully_id = gully.gully_id AND (pp.psector_id IN ( SELECT selected_psector.psector_id
   FROM selected_psector))
                                  ORDER BY pp.psector_id DESC, pp.state DESC
                                 LIMIT 1) plan_gully ON true
                          WHERE (EXISTS ( SELECT 1
                                   FROM selector_state
                                  WHERE selector_state.state_id = COALESCE(plan_gully.state, gully.state) AND selector_state.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
                                   FROM selector_sector
                                  WHERE selector_sector.sector_id = gully.sector_id AND selector_sector.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
                                   FROM selector_municipality
                                  WHERE selector_municipality.muni_id = gully.muni_id AND selector_municipality.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
                                   FROM selector_expl
                                  WHERE (selector_expl.expl_id = ANY (array_append(gully.expl_visibility::integer[], gully.expl_id))) AND selector_expl.cur_user = CURRENT_USER))
                        )
                 SELECT (min(v_price_compost.price) * count(*)::numeric)::numeric(12,2) AS gully_total_cost
                   FROM vf_gully_arc
                     JOIN arc arc_1 ON arc_1.arc_id = vf_gully_arc.arc_id
                     JOIN cat_arc ON cat_arc.id::text = arc_1.arccat_id::text
                     LEFT JOIN v_price_compost ON cat_arc.connect_cost = v_price_compost.id::text
                  WHERE vf_gully_arc.arc_id = v_plan_aux_arc_cost.arc_id) v_plan_aux_arc_gully ON true) d;


CREATE OR REPLACE VIEW v_ui_node_x_connection_upstream
AS SELECT row_number() OVER (ORDER BY ve_arc.node_2) + 1000000 AS rid,
    ve_arc.node_2 AS node_id,
    ve_arc.arc_id AS feature_id,
    ve_arc.code AS feature_code,
    ve_arc.arc_type AS featurecat_id,
    ve_arc.arccat_id,
    ve_arc.y1 AS depth,
    st_length2d(ve_arc.the_geom)::numeric(12,2) AS length,
    node.node_id AS upstream_id,
    node.code AS upstream_code,
    node.node_type AS upstream_type,
    ve_arc.y2 AS upstream_depth,
    ve_arc.sys_type,
    st_x(st_lineinterpolatepoint(ve_arc.the_geom, 0.5::double precision)) AS x,
    st_y(st_lineinterpolatepoint(ve_arc.the_geom, 0.5::double precision)) AS y,
    cat_arc.descript,
    value_state.name AS state,
    've_arc'::text AS sys_table_id
   FROM ve_arc
     JOIN node ON ve_arc.node_1 = node.node_id
     LEFT JOIN cat_arc ON ve_arc.arccat_id::text = cat_arc.id::text
     JOIN value_state ON ve_arc.state = value_state.id
UNION
 SELECT DISTINCT ON (ve_connec.connec_id) row_number() OVER (ORDER BY node.node_id) + 2000000 AS rid,
    node.node_id,
    ve_connec.connec_id AS feature_id,
    ve_connec.code AS feature_code,
    ve_connec.connec_type AS featurecat_id,
    ve_connec.conneccat_id AS arccat_id,
    ve_connec.y1 AS depth,
    st_length2d(link.the_geom)::numeric(12,2) AS length,
    ve_connec.connec_id AS upstream_id,
    ve_connec.code AS upstream_code,
    ve_connec.connec_type AS upstream_type,
    ve_connec.y2 AS upstream_depth,
    ve_connec.sys_type,
    st_x(ve_connec.the_geom) AS x,
    st_y(ve_connec.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    've_connec'::text AS sys_table_id
   FROM ve_connec
     JOIN link ON link.feature_id = ve_connec.connec_id AND link.feature_type::text = 'CONNEC'::text
     JOIN node ON ve_connec.pjoint_id = node.node_id AND ve_connec.pjoint_type::text = 'NODE'::text
     LEFT JOIN cat_connec ON ve_connec.conneccat_id::text = cat_connec.id::text
     JOIN value_state ON ve_connec.state = value_state.id
UNION
 SELECT DISTINCT ON (ve_connec.connec_id) row_number() OVER (ORDER BY node.node_id) + 3000000 AS rid,
    node.node_id,
    ve_connec.connec_id AS feature_id,
    ve_connec.code AS feature_code,
    ve_connec.connec_type AS featurecat_id,
    ve_connec.conneccat_id AS arccat_id,
    ve_connec.y1 AS depth,
    st_length2d(link.the_geom)::numeric(12,2) AS length,
    ve_connec.connec_id AS upstream_id,
    ve_connec.code AS upstream_code,
    ve_connec.connec_type AS upstream_type,
    ve_connec.y2 AS upstream_depth,
    ve_connec.sys_type,
    st_x(ve_connec.the_geom) AS x,
    st_y(ve_connec.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    've_connec'::text AS sys_table_id
   FROM ve_connec
     JOIN link ON link.feature_id = ve_connec.connec_id AND link.feature_type::text = 'CONNEC'::text AND link.exit_type::text = 'CONNEC'::text
     JOIN connec ON connec.connec_id = link.exit_id AND connec.pjoint_type::text = 'NODE'::text
     JOIN node ON connec.pjoint_id = node.node_id
     LEFT JOIN cat_connec ON ve_connec.conneccat_id::text = cat_connec.id::text
     JOIN value_state ON ve_connec.state = value_state.id
UNION
 SELECT DISTINCT ON (ve_gully.gully_id) row_number() OVER (ORDER BY node.node_id) + 4000000 AS rid,
    node.node_id,
    ve_gully.gully_id AS feature_id,
    ve_gully.code AS feature_code,
    ve_gully.gully_type AS featurecat_id,
    ve_gully.connec_arccat_id AS arccat_id,
    ve_gully.ymax - ve_gully.sandbox AS depth,
    ve_gully.connec_length AS length,
    ve_gully.gully_id AS upstream_id,
    ve_gully.code AS upstream_code,
    ve_gully.gully_type AS upstream_type,
    ve_gully.connec_depth AS upstream_depth,
    ve_gully.sys_type,
    st_x(ve_gully.the_geom) AS x,
    st_y(ve_gully.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    've_gully'::text AS sys_table_id
   FROM ve_gully
     JOIN link ON link.feature_id = ve_gully.gully_id AND link.feature_type::text = 'GULLY'::text
     JOIN node ON ve_gully.pjoint_id = node.node_id AND ve_gully.pjoint_type::text = 'NODE'::text
     LEFT JOIN cat_connec ON ve_gully.connec_arccat_id::text = cat_connec.id::text
     JOIN value_state ON ve_gully.state = value_state.id
UNION
 SELECT DISTINCT ON (ve_gully.gully_id) row_number() OVER (ORDER BY node.node_id) + 5000000 AS rid,
    node.node_id,
    ve_gully.gully_id AS feature_id,
    ve_gully.code AS feature_code,
    ve_gully.gully_type AS featurecat_id,
    ve_gully.connec_arccat_id AS arccat_id,
    ve_gully.ymax - ve_gully.sandbox AS depth,
    ve_gully.connec_length AS length,
    ve_gully.gully_id AS upstream_id,
    ve_gully.code AS upstream_code,
    ve_gully.gully_type AS upstream_type,
    ve_gully.connec_depth AS upstream_depth,
    ve_gully.sys_type,
    st_x(ve_gully.the_geom) AS x,
    st_y(ve_gully.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    've_gully'::text AS sys_table_id
   FROM ve_gully
     JOIN link ON link.feature_id = ve_gully.gully_id AND link.feature_type::text = 'GULLY'::text AND link.exit_type::text = 'GULLY'::text
     JOIN gully ON gully.gully_id = link.exit_id AND gully.pjoint_type::text = 'NODE'::text
     JOIN node ON gully.pjoint_id = node.node_id
     LEFT JOIN cat_connec ON ve_gully.connec_arccat_id::text = cat_connec.id::text
     JOIN value_state ON ve_gully.state = value_state.id;



CREATE OR REPLACE VIEW v_plan_result_arc
AS SELECT plan_rec_result_arc.arc_id,
    plan_rec_result_arc.node_1,
    plan_rec_result_arc.node_2,
    plan_rec_result_arc.arc_type::text AS arc_type,
    plan_rec_result_arc.arccat_id,
    plan_rec_result_arc.epa_type,
    plan_rec_result_arc.state,
    plan_rec_result_arc.sector_id,
    plan_rec_result_arc.expl_id,
    plan_rec_result_arc.annotation,
    plan_rec_result_arc.soilcat_id,
    plan_rec_result_arc.y1,
    plan_rec_result_arc.y2,
    plan_rec_result_arc.mean_y,
    plan_rec_result_arc.z1,
    plan_rec_result_arc.z2,
    plan_rec_result_arc.thickness,
    plan_rec_result_arc.width,
    plan_rec_result_arc.b,
    plan_rec_result_arc.bulk,
    plan_rec_result_arc.geom1,
    plan_rec_result_arc.area,
    plan_rec_result_arc.y_param,
    plan_rec_result_arc.total_y,
    plan_rec_result_arc.rec_y,
    plan_rec_result_arc.geom1_ext,
    plan_rec_result_arc.calculed_y,
    plan_rec_result_arc.m3mlexc,
    plan_rec_result_arc.m2mltrenchl,
    plan_rec_result_arc.m2mlbottom,
    plan_rec_result_arc.m2mlpav,
    plan_rec_result_arc.m3mlprotec,
    plan_rec_result_arc.m3mlfill,
    plan_rec_result_arc.m3mlexcess,
    plan_rec_result_arc.m3exc_cost,
    plan_rec_result_arc.m2trenchl_cost,
    plan_rec_result_arc.m2bottom_cost,
    plan_rec_result_arc.m2pav_cost,
    plan_rec_result_arc.m3protec_cost,
    plan_rec_result_arc.m3fill_cost,
    plan_rec_result_arc.m3excess_cost,
    plan_rec_result_arc.cost_unit,
    plan_rec_result_arc.pav_cost,
    plan_rec_result_arc.exc_cost,
    plan_rec_result_arc.trenchl_cost,
    plan_rec_result_arc.base_cost,
    plan_rec_result_arc.protec_cost,
    plan_rec_result_arc.fill_cost,
    plan_rec_result_arc.excess_cost,
    plan_rec_result_arc.arc_cost,
    plan_rec_result_arc.cost,
    plan_rec_result_arc.length,
    plan_rec_result_arc.budget,
    plan_rec_result_arc.other_budget,
    plan_rec_result_arc.total_budget,
    plan_rec_result_arc.the_geom,
    plan_rec_result_arc.builtcost,
    plan_rec_result_arc.builtdate,
    plan_rec_result_arc.age,
    plan_rec_result_arc.acoeff,
    plan_rec_result_arc.aperiod,
    plan_rec_result_arc.arate,
    plan_rec_result_arc.amortized,
    plan_rec_result_arc.pending
   FROM selector_plan_result,
    plan_rec_result_arc
  WHERE plan_rec_result_arc.result_id::text = selector_plan_result.result_id::text AND selector_plan_result.cur_user = "current_user"()::text AND plan_rec_result_arc.state = 1
UNION
 SELECT v_plan_arc.arc_id,
    v_plan_arc.node_1,
    v_plan_arc.node_2,
    v_plan_arc.arc_type,
    v_plan_arc.arccat_id,
    v_plan_arc.epa_type,
    v_plan_arc.state,
    v_plan_arc.sector_id,
    v_plan_arc.expl_id,
    v_plan_arc.annotation,
    v_plan_arc.soilcat_id,
    v_plan_arc.y1,
    v_plan_arc.y2,
    v_plan_arc.mean_y,
    v_plan_arc.z1,
    v_plan_arc.z2,
    v_plan_arc.thickness,
    v_plan_arc.width,
    v_plan_arc.b,
    v_plan_arc.bulk,
    v_plan_arc.geom1,
    v_plan_arc.area,
    v_plan_arc.y_param,
    v_plan_arc.total_y,
    v_plan_arc.rec_y,
    v_plan_arc.geom1_ext,
    v_plan_arc.calculed_y,
    v_plan_arc.m3mlexc,
    v_plan_arc.m2mltrenchl,
    v_plan_arc.m2mlbottom,
    v_plan_arc.m2mlpav,
    v_plan_arc.m3mlprotec,
    v_plan_arc.m3mlfill,
    v_plan_arc.m3mlexcess,
    v_plan_arc.m3exc_cost,
    v_plan_arc.m2trenchl_cost,
    v_plan_arc.m2bottom_cost,
    v_plan_arc.m2pav_cost,
    v_plan_arc.m3protec_cost,
    v_plan_arc.m3fill_cost,
    v_plan_arc.m3excess_cost,
    v_plan_arc.cost_unit,
    v_plan_arc.pav_cost,
    v_plan_arc.exc_cost,
    v_plan_arc.trenchl_cost,
    v_plan_arc.base_cost,
    v_plan_arc.protec_cost,
    v_plan_arc.fill_cost,
    v_plan_arc.excess_cost,
    v_plan_arc.arc_cost,
    v_plan_arc.cost,
    v_plan_arc.length,
    v_plan_arc.budget,
    v_plan_arc.other_budget,
    v_plan_arc.total_budget,
    v_plan_arc.the_geom,
    NULL::double precision AS builtcost,
    NULL::timestamp without time zone AS builtdate,
    NULL::double precision AS age,
    NULL::double precision AS acoeff,
    NULL::text AS aperiod,
    NULL::double precision AS arate,
    NULL::double precision AS amortized,
    NULL::double precision AS pending
   FROM v_plan_arc
  WHERE v_plan_arc.state = 2;



CREATE OR REPLACE VIEW v_plan_psector
AS
WITH base AS (
    SELECT plan_psector.psector_id,
        plan_psector.name,
        plan_psector.psector_type,
        plan_psector.descript,
        plan_psector.priority,
        COALESCE(a.suma, 0::numeric)::numeric(14,2) AS total_arc,
        COALESCE(b.suma, 0::numeric)::numeric(14,2) AS total_node,
        COALESCE(c.suma, 0::numeric)::numeric(14,2) AS total_other,
        plan_psector.text1,
        plan_psector.text2,
        plan_psector.observ,
        plan_psector.rotation,
        plan_psector.scale,
        plan_psector.active,
        plan_psector.gexpenses,
        plan_psector.vat,
        plan_psector.other,
        plan_psector.the_geom
       FROM plan_psector
         LEFT JOIN LATERAL ( SELECT sum(v_plan_arc.total_budget) AS suma
               FROM plan_psector_x_arc
                 JOIN LATERAL ( SELECT v_plan_arc_1.total_budget
                       FROM v_plan_arc v_plan_arc_1
                      WHERE v_plan_arc_1.arc_id = plan_psector_x_arc.arc_id
                     OFFSET 0) v_plan_arc ON true
              WHERE plan_psector_x_arc.psector_id = plan_psector.psector_id
                AND plan_psector_x_arc.doable IS TRUE) a ON true
         LEFT JOIN LATERAL ( SELECT sum(v_plan_node.budget) AS suma
               FROM plan_psector_x_node
                 JOIN LATERAL ( SELECT v_plan_node_1.budget
                       FROM v_plan_node v_plan_node_1
                      WHERE v_plan_node_1.node_id = plan_psector_x_node.node_id
                     OFFSET 0) v_plan_node ON true
              WHERE plan_psector_x_node.psector_id = plan_psector.psector_id
                AND plan_psector_x_node.doable IS TRUE) b ON true
         LEFT JOIN LATERAL ( SELECT sum((plan_psector_x_other.measurement * v_price_compost.price)::numeric(14,2)) AS suma
               FROM plan_psector_x_other
                 JOIN v_price_compost ON v_price_compost.id::text = plan_psector_x_other.price_id::text
              WHERE plan_psector_x_other.psector_id = plan_psector.psector_id) c ON true
     WHERE EXISTS ( SELECT 1
               FROM selector_psector
              WHERE selector_psector.psector_id = plan_psector.psector_id
                AND selector_psector.cur_user = CURRENT_USER)
), totals AS (
    SELECT base.psector_id,
        base.name,
        base.psector_type,
        base.descript,
        base.priority,
        base.total_arc,
        base.total_node,
        base.total_other,
        base.text1,
        base.text2,
        base.observ,
        base.rotation,
        base.scale,
        base.active,
        (base.total_arc + base.total_node + base.total_other)::numeric(14,2) AS pem,
        base.gexpenses,
        base.vat,
        base.other,
        base.the_geom
       FROM base
)
 SELECT totals.psector_id,
    totals.name,
    totals.psector_type,
    totals.descript,
    totals.priority,
    totals.total_arc,
    totals.total_node,
    totals.total_other,
    totals.text1,
    totals.text2,
    totals.observ,
    totals.rotation,
    totals.scale,
    totals.active,
    totals.pem,
    totals.gexpenses,
    (totals.pem * (100::numeric + totals.gexpenses) / 100::numeric)::numeric(14,2) AS pec,
    totals.vat,
    ((totals.pem * (100::numeric + totals.gexpenses) / 100::numeric) * (100::numeric + totals.vat) / 100::numeric)::numeric(14,2) AS pec_vat,
    totals.other,
    (((totals.pem * (100::numeric + totals.gexpenses) / 100::numeric) * (100::numeric + totals.vat) / 100::numeric) * (100::numeric + totals.other) / 100::numeric)::numeric(14,2) AS pca,
    totals.the_geom
   FROM totals;


CREATE OR REPLACE VIEW v_plan_current_psector
AS SELECT plan_psector.psector_id,
    plan_psector.name,
    plan_psector.psector_type,
    plan_psector.descript,
    plan_psector.priority,
    a.suma::numeric(14,2) AS total_arc,
    b.suma::numeric(14,2) AS total_node,
    c.suma::numeric(14,2) AS total_other,
    plan_psector.text1,
    plan_psector.text2,
    plan_psector.observ,
    plan_psector.rotation,
    plan_psector.scale,
    plan_psector.active,
    (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::numeric(14,2) AS pem,
    plan_psector.gexpenses,
    ((100::numeric + plan_psector.gexpenses) / 100::numeric)::numeric(14,2) * (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::numeric(14,2) AS pec,
    plan_psector.vat,
    ((100::numeric + plan_psector.gexpenses) / 100::numeric * ((100::numeric + plan_psector.vat) / 100::numeric))::numeric(14,2) * (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::numeric(14,2) AS pec_vat,
    plan_psector.other,
    ((100::numeric + plan_psector.gexpenses) / 100::numeric * ((100::numeric + plan_psector.vat) / 100::numeric) * ((100::numeric + plan_psector.other) / 100::numeric))::numeric(14,2) * (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::numeric(14,2) AS pca,
    plan_psector.the_geom
   FROM config_param_user,
    plan_psector
     LEFT JOIN ( SELECT sum(v_plan_psector_x_arc.total_budget) AS suma,
            v_plan_psector_x_arc.psector_id
           FROM ( SELECT row_number() OVER (ORDER BY v_plan_arc.arc_id) AS rid,
                    v_plan_arc.arc_id,
                    v_plan_arc.node_1,
                    v_plan_arc.node_2,
                    v_plan_arc.arc_type,
                    v_plan_arc.arccat_id,
                    v_plan_arc.epa_type,
                    v_plan_arc.state,
                    v_plan_arc.sector_id,
                    v_plan_arc.expl_id,
                    v_plan_arc.annotation,
                    v_plan_arc.soilcat_id,
                    v_plan_arc.y1,
                    v_plan_arc.y2,
                    v_plan_arc.mean_y,
                    v_plan_arc.z1,
                    v_plan_arc.z2,
                    v_plan_arc.thickness,
                    v_plan_arc.width,
                    v_plan_arc.b,
                    v_plan_arc.bulk,
                    v_plan_arc.geom1,
                    v_plan_arc.area,
                    v_plan_arc.y_param,
                    v_plan_arc.total_y,
                    v_plan_arc.rec_y,
                    v_plan_arc.geom1_ext,
                    v_plan_arc.calculed_y,
                    v_plan_arc.m3mlexc,
                    v_plan_arc.m2mltrenchl,
                    v_plan_arc.m2mlbottom,
                    v_plan_arc.m2mlpav,
                    v_plan_arc.m3mlprotec,
                    v_plan_arc.m3mlfill,
                    v_plan_arc.m3mlexcess,
                    v_plan_arc.m3exc_cost,
                    v_plan_arc.m2trenchl_cost,
                    v_plan_arc.m2bottom_cost,
                    v_plan_arc.m2pav_cost,
                    v_plan_arc.m3protec_cost,
                    v_plan_arc.m3fill_cost,
                    v_plan_arc.m3excess_cost,
                    v_plan_arc.cost_unit,
                    v_plan_arc.pav_cost,
                    v_plan_arc.exc_cost,
                    v_plan_arc.trenchl_cost,
                    v_plan_arc.base_cost,
                    v_plan_arc.protec_cost,
                    v_plan_arc.fill_cost,
                    v_plan_arc.excess_cost,
                    v_plan_arc.arc_cost,
                    v_plan_arc.cost,
                    v_plan_arc.length,
                    v_plan_arc.budget,
                    v_plan_arc.other_budget,
                    v_plan_arc.total_budget,
                    v_plan_arc.the_geom,
                    plan_psector_x_arc.id,
                    plan_psector_x_arc.arc_id,
                    plan_psector_x_arc.psector_id,
                    plan_psector_x_arc.state,
                    plan_psector_x_arc.doable,
                    plan_psector_x_arc.descript,
                    plan_psector_x_arc.addparam
                   FROM v_plan_arc
                     JOIN plan_psector_x_arc ON plan_psector_x_arc.arc_id = v_plan_arc.arc_id
                     JOIN plan_psector plan_psector_1 ON plan_psector_1.psector_id = plan_psector_x_arc.psector_id
                  ORDER BY plan_psector_x_arc.psector_id) v_plan_psector_x_arc(rid, arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, arc_id_1, psector_id, state_1, doable, descript, addparam)
          GROUP BY v_plan_psector_x_arc.psector_id) a ON a.psector_id = plan_psector.psector_id
     LEFT JOIN ( SELECT sum(v_plan_psector_x_node.budget) AS suma,
            v_plan_psector_x_node.psector_id
           FROM ( SELECT row_number() OVER (ORDER BY v_plan_node.node_id) AS rid,
                    v_plan_node.node_id,
                    v_plan_node.nodecat_id,
                    v_plan_node.node_type,
                    v_plan_node.top_elev,
                    v_plan_node.elev,
                    v_plan_node.epa_type,
                    v_plan_node.state,
                    v_plan_node.sector_id,
                    v_plan_node.expl_id,
                    v_plan_node.annotation,
                    v_plan_node.cost_unit,
                    v_plan_node.descript,
                    v_plan_node.cost,
                    v_plan_node.measurement,
                    v_plan_node.budget,
                    v_plan_node.the_geom,
                    plan_psector_x_node.id,
                    plan_psector_x_node.node_id,
                    plan_psector_x_node.psector_id,
                    plan_psector_x_node.state,
                    plan_psector_x_node.doable,
                    plan_psector_x_node.descript
                   FROM v_plan_node
                     JOIN plan_psector_x_node ON plan_psector_x_node.node_id = v_plan_node.node_id
                     JOIN plan_psector plan_psector_1 ON plan_psector_1.psector_id = plan_psector_x_node.psector_id
                  ORDER BY plan_psector_x_node.psector_id) v_plan_psector_x_node(rid, node_id, nodecat_id, node_type, top_elev, elev, epa_type, state, sector_id, expl_id, annotation, cost_unit, descript, cost, measurement, budget, the_geom, id, node_id_1, psector_id, state_1, doable, descript_1)
          GROUP BY v_plan_psector_x_node.psector_id) b ON b.psector_id = plan_psector.psector_id
     LEFT JOIN ( SELECT sum(v_plan_psector_x_other.total_budget) AS suma,
            v_plan_psector_x_other.psector_id
           FROM ( SELECT plan_psector_x_other.id,
                    plan_psector_x_other.psector_id,
                    plan_psector_1.psector_type,
                    v_price_compost.id AS price_id,
                    v_price_compost.descript,
                    v_price_compost.price,
                    plan_psector_x_other.measurement,
                    (plan_psector_x_other.measurement * v_price_compost.price)::numeric(14,2) AS total_budget
                   FROM plan_psector_x_other
                     JOIN v_price_compost ON v_price_compost.id::text = plan_psector_x_other.price_id::text
                     JOIN plan_psector plan_psector_1 ON plan_psector_1.psector_id = plan_psector_x_other.psector_id
                  ORDER BY plan_psector_x_other.psector_id) v_plan_psector_x_other
          GROUP BY v_plan_psector_x_other.psector_id) c ON c.psector_id = plan_psector.psector_id
  WHERE config_param_user.cur_user::text = "current_user"()::text AND config_param_user.parameter::text = 'plan_psector_vdefault'::text AND config_param_user.value::integer = plan_psector.psector_id;



CREATE OR REPLACE VIEW v_plan_psector_budget
AS SELECT row_number() OVER (ORDER BY v_plan_arc.arc_id) AS rid,
    plan_psector_x_arc.psector_id,
    'arc'::text AS feature_type,
    v_plan_arc.arccat_id AS featurecat_id,
    v_plan_arc.arc_id AS feature_id,
    v_plan_arc.length,
    (v_plan_arc.total_budget / v_plan_arc.length)::numeric(14,2) AS unitary_cost,
    v_plan_arc.total_budget
   FROM v_plan_arc
     JOIN plan_psector_x_arc ON plan_psector_x_arc.arc_id = v_plan_arc.arc_id
  WHERE plan_psector_x_arc.doable = true
UNION
 SELECT row_number() OVER (ORDER BY v_plan_node.node_id) + 9999 AS rid,
    plan_psector_x_node.psector_id,
    'node'::text AS feature_type,
    v_plan_node.nodecat_id AS featurecat_id,
    v_plan_node.node_id AS feature_id,
    1 AS length,
    v_plan_node.budget AS unitary_cost,
    v_plan_node.budget AS total_budget
   FROM v_plan_node
     JOIN plan_psector_x_node ON plan_psector_x_node.node_id = v_plan_node.node_id
  WHERE plan_psector_x_node.doable = true
UNION
 SELECT row_number() OVER (ORDER BY ve_plan_psector_x_other.id) + 19999 AS rid,
    ve_plan_psector_x_other.psector_id,
    'other'::text AS feature_type,
    ve_plan_psector_x_other.price_id AS featurecat_id,
    NULL::integer AS feature_id,
    ve_plan_psector_x_other.measurement AS length,
    ve_plan_psector_x_other.price AS unitary_cost,
    ve_plan_psector_x_other.total_budget
   FROM ve_plan_psector_x_other
  ORDER BY 1, 2, 4;


CREATE OR REPLACE VIEW v_plan_psector_budget_arc
AS SELECT row_number() OVER (ORDER BY v_plan_arc.arc_id) AS rid,
    plan_psector_x_arc.psector_id,
    plan_psector.psector_type,
    v_plan_arc.arc_id,
    v_plan_arc.arccat_id,
    v_plan_arc.cost_unit,
    v_plan_arc.cost::numeric(14,2) AS cost,
    v_plan_arc.length,
    v_plan_arc.budget,
    v_plan_arc.other_budget,
    v_plan_arc.total_budget,
    v_plan_arc.state,
    plan_psector.expl_id,
    plan_psector.atlas_id,
    plan_psector_x_arc.doable,
    plan_psector.priority,
    v_plan_arc.the_geom
   FROM v_plan_arc
     JOIN plan_psector_x_arc ON plan_psector_x_arc.arc_id = v_plan_arc.arc_id
     JOIN plan_psector ON plan_psector.psector_id = plan_psector_x_arc.psector_id
  WHERE plan_psector_x_arc.doable = true
  ORDER BY plan_psector_x_arc.psector_id;



CREATE OR REPLACE VIEW v_plan_psector_budget_detail
AS SELECT v_plan_arc.arc_id,
    plan_psector_x_arc.psector_id,
    v_plan_arc.arccat_id,
    v_plan_arc.soilcat_id,
    v_plan_arc.y1,
    v_plan_arc.y2,
    v_plan_arc.arc_cost AS mlarc_cost,
    v_plan_arc.m3mlexc,
    v_plan_arc.exc_cost AS mlexc_cost,
    v_plan_arc.m2mltrenchl,
    v_plan_arc.trenchl_cost AS mltrench_cost,
    v_plan_arc.m2mlbottom AS m2mlbase,
    v_plan_arc.base_cost AS mlbase_cost,
    v_plan_arc.m2mlpav,
    v_plan_arc.pav_cost AS mlpav_cost,
    v_plan_arc.m3mlprotec,
    v_plan_arc.protec_cost AS mlprotec_cost,
    v_plan_arc.m3mlfill,
    v_plan_arc.fill_cost AS mlfill_cost,
    v_plan_arc.m3mlexcess,
    v_plan_arc.excess_cost AS mlexcess_cost,
    v_plan_arc.cost AS mltotal_cost,
    v_plan_arc.length,
    v_plan_arc.budget AS other_budget,
    v_plan_arc.total_budget
   FROM v_plan_arc
     JOIN plan_psector_x_arc ON plan_psector_x_arc.arc_id = v_plan_arc.arc_id
  WHERE plan_psector_x_arc.doable = true
  ORDER BY plan_psector_x_arc.psector_id, v_plan_arc.soilcat_id, v_plan_arc.arccat_id;



CREATE OR REPLACE VIEW v_plan_psector_all
AS SELECT plan_psector.psector_id,
    plan_psector.name,
    plan_psector.psector_type,
    plan_psector.descript,
    plan_psector.priority,
    a.suma::numeric(14,2) AS total_arc,
    b.suma::numeric(14,2) AS total_node,
    c.suma::numeric(14,2) AS total_other,
    plan_psector.text1,
    plan_psector.text2,
    plan_psector.observ,
    plan_psector.rotation,
    plan_psector.scale,
    (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::numeric(14,2) AS pem,
    plan_psector.gexpenses,
    (((100::numeric + plan_psector.gexpenses) / 100::numeric)::double precision * (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::double precision)::numeric(14,2) AS pec,
    plan_psector.vat,
    (((100::numeric + plan_psector.gexpenses) / 100::numeric * ((100::numeric + plan_psector.vat) / 100::numeric))::double precision * (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::double precision)::numeric(14,2) AS pec_vat,
    plan_psector.other,
    ((((100::numeric + plan_psector.gexpenses) / 100::numeric * ((100::numeric + plan_psector.vat) / 100::numeric))::double precision * (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::double precision)::numeric(14,2)::double precision + ((100::numeric + plan_psector.vat) / 100::numeric * (plan_psector.other / 100::numeric))::double precision * (
        CASE
            WHEN a.suma IS NULL THEN 0::numeric
            ELSE a.suma
        END +
        CASE
            WHEN b.suma IS NULL THEN 0::numeric
            ELSE b.suma
        END +
        CASE
            WHEN c.suma IS NULL THEN 0::numeric
            ELSE c.suma
        END)::double precision)::numeric(14,2) AS pca,
    plan_psector.the_geom
   FROM selector_psector,
    plan_psector
     LEFT JOIN ( SELECT sum(v_plan_psector_x_arc.total_budget) AS suma,
            v_plan_psector_x_arc.psector_id
           FROM ( SELECT row_number() OVER (ORDER BY v_plan_arc.arc_id) AS rid,
                    v_plan_arc.arc_id,
                    v_plan_arc.node_1,
                    v_plan_arc.node_2,
                    v_plan_arc.arc_type,
                    v_plan_arc.arccat_id,
                    v_plan_arc.epa_type,
                    v_plan_arc.state,
                    v_plan_arc.expl_id,
                    v_plan_arc.sector_id,
                    v_plan_arc.annotation,
                    v_plan_arc.soilcat_id,
                    v_plan_arc.y1,
                    v_plan_arc.y2,
                    v_plan_arc.mean_y,
                    v_plan_arc.z1,
                    v_plan_arc.z2,
                    v_plan_arc.thickness,
                    v_plan_arc.width,
                    v_plan_arc.b,
                    v_plan_arc.bulk,
                    v_plan_arc.geom1,
                    v_plan_arc.area,
                    v_plan_arc.y_param,
                    v_plan_arc.total_y,
                    v_plan_arc.rec_y,
                    v_plan_arc.geom1_ext,
                    v_plan_arc.calculed_y,
                    v_plan_arc.m3mlexc,
                    v_plan_arc.m2mltrenchl,
                    v_plan_arc.m2mlbottom,
                    v_plan_arc.m2mlpav,
                    v_plan_arc.m3mlprotec,
                    v_plan_arc.m3mlfill,
                    v_plan_arc.m3mlexcess,
                    v_plan_arc.m3exc_cost,
                    v_plan_arc.m2trenchl_cost,
                    v_plan_arc.m2bottom_cost,
                    v_plan_arc.m2pav_cost,
                    v_plan_arc.m3protec_cost,
                    v_plan_arc.m3fill_cost,
                    v_plan_arc.m3excess_cost,
                    v_plan_arc.cost_unit,
                    v_plan_arc.pav_cost,
                    v_plan_arc.exc_cost,
                    v_plan_arc.trenchl_cost,
                    v_plan_arc.base_cost,
                    v_plan_arc.protec_cost,
                    v_plan_arc.fill_cost,
                    v_plan_arc.excess_cost,
                    v_plan_arc.arc_cost,
                    v_plan_arc.cost,
                    v_plan_arc.length,
                    v_plan_arc.budget,
                    v_plan_arc.other_budget,
                    v_plan_arc.total_budget,
                    v_plan_arc.the_geom,
                    plan_psector_x_arc.id,
                    plan_psector_x_arc.arc_id,
                    plan_psector_x_arc.psector_id,
                    plan_psector_x_arc.state,
                    plan_psector_x_arc.doable,
                    plan_psector_x_arc.descript,
                    plan_psector_x_arc.addparam
                   FROM v_plan_arc
                     JOIN plan_psector_x_arc ON plan_psector_x_arc.arc_id = v_plan_arc.arc_id
                     JOIN plan_psector plan_psector_1 ON plan_psector_1.psector_id = plan_psector_x_arc.psector_id
                  ORDER BY plan_psector_x_arc.psector_id) v_plan_psector_x_arc(rid, arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, arc_id_1, psector_id, state_1, doable, descript, addparam)
          GROUP BY v_plan_psector_x_arc.psector_id) a ON a.psector_id = plan_psector.psector_id
     LEFT JOIN ( SELECT sum(v_plan_psector_x_node.budget) AS suma,
            v_plan_psector_x_node.psector_id
           FROM ( SELECT row_number() OVER (ORDER BY v_plan_node.node_id) AS rid,
                    v_plan_node.node_id,
                    v_plan_node.nodecat_id,
                    v_plan_node.node_type,
                    v_plan_node.top_elev,
                    v_plan_node.elev,
                    v_plan_node.epa_type,
                    v_plan_node.state,
                    v_plan_node.sector_id,
                    v_plan_node.expl_id,
                    v_plan_node.annotation,
                    v_plan_node.cost_unit,
                    v_plan_node.descript,
                    v_plan_node.cost,
                    v_plan_node.measurement,
                    v_plan_node.budget,
                    v_plan_node.the_geom,
                    plan_psector_x_node.id,
                    plan_psector_x_node.node_id,
                    plan_psector_x_node.psector_id,
                    plan_psector_x_node.state,
                    plan_psector_x_node.doable,
                    plan_psector_x_node.descript
                   FROM v_plan_node
                     JOIN plan_psector_x_node ON plan_psector_x_node.node_id = v_plan_node.node_id
                     JOIN plan_psector plan_psector_1 ON plan_psector_1.psector_id = plan_psector_x_node.psector_id
                  ORDER BY plan_psector_x_node.psector_id) v_plan_psector_x_node(rid, node_id, nodecat_id, node_type, top_elev, elev, epa_type, state, sector_id, expl_id, annotation, cost_unit, descript, cost, measurement, budget, the_geom, id, node_id_1, psector_id, state_1, doable, descript_1)
          GROUP BY v_plan_psector_x_node.psector_id) b ON b.psector_id = plan_psector.psector_id
     LEFT JOIN ( SELECT sum(v_plan_psector_x_other.total_budget) AS suma,
            v_plan_psector_x_other.psector_id
           FROM ( SELECT plan_psector_x_other.id,
                    plan_psector_x_other.psector_id,
                    plan_psector_1.psector_type,
                    v_price_compost.id AS price_id,
                    v_price_compost.descript,
                    v_price_compost.price,
                    plan_psector_x_other.measurement,
                    (plan_psector_x_other.measurement * v_price_compost.price)::numeric(14,2) AS total_budget
                   FROM plan_psector_x_other
                     JOIN v_price_compost ON v_price_compost.id::text = plan_psector_x_other.price_id::text
                     JOIN plan_psector plan_psector_1 ON plan_psector_1.psector_id = plan_psector_x_other.psector_id
                  ORDER BY plan_psector_x_other.psector_id) v_plan_psector_x_other
          GROUP BY v_plan_psector_x_other.psector_id) c ON c.psector_id = plan_psector.psector_id;



CREATE OR REPLACE VIEW v_ui_plan_arc_cost
AS WITH p AS (
         SELECT v_plan_arc.arc_id,
            v_plan_arc.node_1,
            v_plan_arc.node_2,
            v_plan_arc.arc_type,
            v_plan_arc.arccat_id,
            v_plan_arc.epa_type,
            v_plan_arc.state,
            v_plan_arc.expl_id,
            v_plan_arc.sector_id,
            v_plan_arc.annotation,
            v_plan_arc.soilcat_id,
            v_plan_arc.y1,
            v_plan_arc.y2,
            v_plan_arc.mean_y,
            v_plan_arc.z1,
            v_plan_arc.z2,
            v_plan_arc.thickness,
            v_plan_arc.width,
            v_plan_arc.b,
            v_plan_arc.bulk,
            v_plan_arc.geom1,
            v_plan_arc.area,
            v_plan_arc.y_param,
            v_plan_arc.total_y,
            v_plan_arc.rec_y,
            v_plan_arc.geom1_ext,
            v_plan_arc.calculed_y,
            v_plan_arc.m3mlexc,
            v_plan_arc.m2mltrenchl,
            v_plan_arc.m2mlbottom,
            v_plan_arc.m2mlpav,
            v_plan_arc.m3mlprotec,
            v_plan_arc.m3mlfill,
            v_plan_arc.m3mlexcess,
            v_plan_arc.m3exc_cost,
            v_plan_arc.m2trenchl_cost,
            v_plan_arc.m2bottom_cost,
            v_plan_arc.m2pav_cost,
            v_plan_arc.m3protec_cost,
            v_plan_arc.m3fill_cost,
            v_plan_arc.m3excess_cost,
            v_plan_arc.cost_unit,
            v_plan_arc.pav_cost,
            v_plan_arc.exc_cost,
            v_plan_arc.trenchl_cost,
            v_plan_arc.base_cost,
            v_plan_arc.protec_cost,
            v_plan_arc.fill_cost,
            v_plan_arc.excess_cost,
            v_plan_arc.arc_cost,
            v_plan_arc.cost,
            v_plan_arc.length,
            v_plan_arc.budget,
            v_plan_arc.other_budget,
            v_plan_arc.total_budget,
            v_plan_arc.the_geom,
            a.id,
            a.matcat_id,
            a.shape,
            a.geom1,
            a.geom2,
            a.geom3,
            a.geom4,
            a.geom5,
            a.geom6,
            a.geom7,
            a.geom8,
            a.geom_r,
            a.descript,
            a.link,
            a.brand_id,
            a.model_id,
            a.svg,
            a.z1,
            a.z2,
            a.width,
            a.area,
            a.estimated_depth,
            a.thickness,
            a.cost_unit,
            a.cost,
            a.m2bottom_cost,
            a.m3protec_cost,
            a.active,
            a.label,
            a.tsect_id,
            a.curve_id,
            a.arc_type,
            a.acoeff,
            a.connect_cost,
            s.id,
            s.descript,
            s.link,
            s.y_param,
            s.b,
            s.trenchlining,
            s.m3exc_cost,
            s.m3fill_cost,
            s.m3excess_cost,
            s.m2trenchl_cost,
            s.active,
            a.cost AS cat_cost,
            a.m2bottom_cost AS cat_m2bottom_cost,
            a.connect_cost AS cat_connect_cost,
            a.m3protec_cost AS cat_m3_protec_cost,
            s.m3exc_cost AS cat_m3exc_cost,
            s.m3fill_cost AS cat_m3fill_cost,
            s.m3excess_cost AS cat_m3excess_cost,
            s.m2trenchl_cost AS cat_m2trenchl_cost
           FROM v_plan_arc
             JOIN cat_arc a ON a.id::text = v_plan_arc.arccat_id::text
             JOIN cat_soil s ON s.id::text = v_plan_arc.soilcat_id::text
        )
 SELECT p.arc_id,
    1 AS orderby,
    'element'::text AS identif,
    p.arccat_id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    1 AS measurement,
    1::numeric * v_price_compost.price AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_price_compost ON p.cat_cost::text = v_price_compost.id::text
UNION
 SELECT p.arc_id,
    2 AS orderby,
    'm2bottom'::text AS identif,
    p.arccat_id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    p.m2mlbottom AS measurement,
    p.m2mlbottom * v_price_compost.price AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_price_compost ON p.cat_m2bottom_cost::text = v_price_compost.id::text
UNION
 SELECT p.arc_id,
    3 AS orderby,
    'm3protec'::text AS identif,
    p.arccat_id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    p.m3mlprotec AS measurement,
    p.m3mlprotec * v_price_compost.price AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_price_compost ON p.cat_m3_protec_cost::text = v_price_compost.id::text
UNION
 SELECT p.arc_id,
    4 AS orderby,
    'm3exc'::text AS identif,
    p.soilcat_id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    p.m3mlexc AS measurement,
    p.m3mlexc * v_price_compost.price AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_price_compost ON p.cat_m3exc_cost::text = v_price_compost.id::text
UNION
 SELECT p.arc_id,
    5 AS orderby,
    'm3fill'::text AS identif,
    p.soilcat_id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    p.m3mlfill AS measurement,
    p.m3mlfill * v_price_compost.price AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_price_compost ON p.cat_m3fill_cost::text = v_price_compost.id::text
UNION
 SELECT p.arc_id,
    6 AS orderby,
    'm3excess'::text AS identif,
    p.soilcat_id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    p.m3mlexcess AS measurement,
    p.m3mlexcess * v_price_compost.price AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_price_compost ON p.cat_m3excess_cost::text = v_price_compost.id::text
UNION
 SELECT p.arc_id,
    7 AS orderby,
    'm2trenchl'::text AS identif,
    p.soilcat_id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    p.m2mltrenchl AS measurement,
    p.m2mltrenchl * v_price_compost.price AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_price_compost ON p.cat_m2trenchl_cost::text = v_price_compost.id::text
UNION
 SELECT p.arc_id,
    8 AS orderby,
    'pavement'::text AS identif,
        CASE
            WHEN a.price_id IS NULL THEN 'Various pavements'::character varying
            ELSE a.pavcat_id
        END AS catalog_id,
        CASE
            WHEN a.price_id IS NULL THEN 'Various prices'::character varying
            ELSE a.pavcat_id
        END AS price_id,
    'm2'::character varying AS unit,
        CASE
            WHEN a.price_id IS NULL THEN 'Various prices'::character varying
            ELSE a.pavcat_id
        END AS descript,
    a.m2pav_cost AS cost,
    p.m2mlpav AS measurement,
    p.m2mlpav*a.m2pav_cost AS total_cost,
    p.length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_plan_aux_arc_pavement a ON a.arc_id = p.arc_id
     JOIN cat_pavement c ON a.pavcat_id::text = c.id::text
     LEFT JOIN v_price_compost r ON a.price_id::text = c.m2_cost::text
UNION
 SELECT p.arc_id,
    9 AS orderby,
    'connec'::text AS identif,
    'Various connecs'::character varying AS catalog_id,
    'VARIOUS'::character varying AS price_id,
    'PP'::character varying AS unit,
    'Proportional cost of connec connections (pjoint cost)'::character varying AS descript,
    min(v.price) AS cost,
    count(ve_connec.connec_id) AS measurement,
    (min(v.price) * count(ve_connec.connec_id)::numeric / COALESCE(min(p.length), 1::numeric))::numeric(12,2) AS total_cost,
    min(p.length)::numeric(12,2) AS length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN ve_connec USING (arc_id)
     JOIN v_price_compost v ON p.cat_connect_cost = v.id::text
  GROUP BY p.arc_id
UNION
 SELECT p.arc_id,
    10 AS orderby,
    'connec'::text AS identif,
    'Various connecs'::character varying AS catalog_id,
    'VARIOUS'::character varying AS price_id,
    'PP'::character varying AS unit,
    'Proportional cost of gully connections (pjoint cost)'::character varying AS descript,
    min(v.price) AS cost,
    count(ve_gully.gully_id) AS measurement,
    (min(v.price) * count(ve_gully.gully_id)::numeric / COALESCE(min(p.length), 1::numeric))::numeric(12,2) AS total_cost,
    min(p.length)::numeric(12,2) AS length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN ve_gully USING (arc_id)
     JOIN v_price_compost v ON p.cat_connect_cost = v.id::text
  GROUP BY p.arc_id
  ORDER BY 1, 2;


CREATE OR REPLACE VIEW v_ui_arc_x_relations
AS WITH links_node AS (
         SELECT n.node_id,
            l.feature_id,
            l.exit_type AS proceed_from,
            l.exit_id AS proceed_from_id,
            l.state AS l_state,
            n.state AS n_state
           FROM node n
             JOIN link l ON n.node_id = l.exit_id
          WHERE l.state = 1
        )
 SELECT row_number() OVER () + 1000000 AS rid,
    ve_connec.arc_id,
    ve_connec.connec_type AS featurecat_id,
    ve_connec.conneccat_id AS catalog,
    ve_connec.connec_id AS feature_id,
    ve_connec.code AS feature_code,
    ve_connec.sys_type,
    a.state AS arc_state,
    ve_connec.state AS feature_state,
    st_x(ve_connec.the_geom) AS x,
    st_y(ve_connec.the_geom) AS y,
    l.exit_type AS proceed_from,
    l.exit_id AS proceed_from_id,
    've_connec'::text AS sys_table_id
   FROM ve_connec
     JOIN link l ON ve_connec.connec_id = l.feature_id
     JOIN arc a ON a.arc_id = ve_connec.arc_id
  WHERE ve_connec.arc_id IS NOT NULL AND l.exit_type::text <> 'NODE'::text AND l.state = 1 AND l.state = 1 AND a.state = 1
UNION
 SELECT DISTINCT ON (c.connec_id) row_number() OVER () + 2000000 AS rid,
    a.arc_id,
    c.connec_type AS featurecat_id,
    c.conneccat_id AS catalog,
    c.connec_id AS feature_id,
    c.code AS feature_code,
    c.sys_type,
    a.state AS arc_state,
    c.state AS feature_state,
    st_x(c.the_geom) AS x,
    st_y(c.the_geom) AS y,
    n.proceed_from,
    n.proceed_from_id,
    've_connec'::text AS sys_table_id
   FROM arc a
     JOIN links_node n ON a.node_1 = n.node_id
     JOIN ve_connec c ON c.connec_id = n.feature_id
UNION
 SELECT row_number() OVER () + 3000000 AS rid,
    ve_gully.arc_id,
    ve_gully.gully_type AS featurecat_id,
    ve_gully.gullycat_id AS catalog,
    ve_gully.gully_id AS feature_id,
    ve_gully.code AS feature_code,
    ve_gully.sys_type,
    a.state AS arc_state,
    ve_gully.state AS feature_state,
    st_x(ve_gully.the_geom) AS x,
    st_y(ve_gully.the_geom) AS y,
    l.exit_type AS proceed_from,
    l.exit_id AS proceed_from_id,
    've_gully'::text AS sys_table_id
   FROM ve_gully
     JOIN link l ON ve_gully.gully_id = l.feature_id
     JOIN arc a ON a.arc_id = ve_gully.arc_id
  WHERE ve_gully.arc_id IS NOT NULL AND l.exit_type::text <> 'NODE'::text AND l.state = 1 AND a.state = 1
UNION
 SELECT DISTINCT ON (g.gully_id) row_number() OVER () + 4000000 AS rid,
    a.arc_id,
    g.gully_type AS featurecat_id,
    g.gullycat_id AS catalog,
    g.gully_id AS feature_id,
    g.code AS feature_code,
    g.sys_type,
    a.state AS arc_state,
    g.state AS feature_state,
    st_x(g.the_geom) AS x,
    st_y(g.the_geom) AS y,
    n.proceed_from,
    n.proceed_from_id,
    've_gully'::text AS sys_table_id
   FROM arc a
     JOIN links_node n ON a.node_1 = n.node_id
     JOIN ve_gully g ON g.gully_id = n.feature_id;


CREATE OR REPLACE VIEW v_ui_workcat_x_feature_end
AS SELECT row_number() OVER (ORDER BY ve_arc.arc_id) + 1000000 AS rid,
    'ARC'::character varying AS feature_type,
    ve_arc.arccat_id AS featurecat_id,
    ve_arc.arc_id AS feature_id,
    ve_arc.code,
    exploitation.name AS expl_name,
    ve_arc.workcat_id_end,
    exploitation.expl_id
   FROM ve_arc
     JOIN exploitation ON exploitation.expl_id = ve_arc.expl_id
  WHERE ve_arc.state = 0
UNION
 SELECT row_number() OVER (ORDER BY ve_node.node_id) + 2000000 AS rid,
    'NODE'::character varying AS feature_type,
    ve_node.nodecat_id AS featurecat_id,
    ve_node.node_id AS feature_id,
    ve_node.code,
    exploitation.name AS expl_name,
    ve_node.workcat_id_end,
    exploitation.expl_id
   FROM ve_node
     JOIN exploitation ON exploitation.expl_id = ve_node.expl_id
  WHERE ve_node.state = 0
UNION
 SELECT row_number() OVER (ORDER BY ve_connec.connec_id) + 3000000 AS rid,
    'CONNEC'::character varying AS feature_type,
    ve_connec.conneccat_id AS featurecat_id,
    ve_connec.connec_id AS feature_id,
    ve_connec.code,
    exploitation.name AS expl_name,
    ve_connec.workcat_id_end,
    exploitation.expl_id
   FROM ve_connec
     JOIN exploitation ON exploitation.expl_id = ve_connec.expl_id
  WHERE ve_connec.state = 0
UNION
 SELECT row_number() OVER (ORDER BY element.element_id) + 4000000 AS rid,
    'ELEMENT'::character varying AS feature_type,
    element.elementcat_id AS featurecat_id,
    element.element_id AS feature_id,
    element.code,
    exploitation.name AS expl_name,
    element.workcat_id_end,
    exploitation.expl_id
   FROM element
     JOIN exploitation ON exploitation.expl_id = element.expl_id
  WHERE element.state = 0
UNION
 SELECT row_number() OVER (ORDER BY ve_gully.gully_id) + 4000000 AS rid,
    'GULLY'::character varying AS feature_type,
    ve_gully.gullycat_id AS featurecat_id,
    ve_gully.gully_id AS feature_id,
    ve_gully.code,
    exploitation.name AS expl_name,
    ve_gully.workcat_id_end,
    exploitation.expl_id
   FROM ve_gully
     JOIN exploitation ON exploitation.expl_id = ve_gully.expl_id
  WHERE ve_gully.state = 0;


CREATE OR REPLACE VIEW v_edit_connec
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
            l.expl_id,
            exploitation.macroexpl_id,
            l.sector_id,
            sector_table.sector_type,
            sector_table.macrosector_id,
            l.omzone_id,
            omzone_table.macroomzone_id,
            omzone_table.omzone_type,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            l.dwfzone_id,
            dwfzone_table.dwfzone_type,
            l.dma_id,
            l.fluid_type
           FROM link l
             JOIN exploitation USING (expl_id)
             JOIN sector_table ON l.sector_id = sector_table.sector_id
             LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
             LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
          WHERE l.state = 2
        ), connec_psector AS (
         SELECT DISTINCT ON (pp.connec_id, pp.state) pp.connec_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.arc_id,
            pp.link_id
           FROM plan_psector_x_connec pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST
        ), connec_selector AS (
         SELECT connec.connec_id,
            connec.arc_id,
            NULL::integer AS link_id
           FROM connec
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND connec.state = s.state_id
             LEFT JOIN ( SELECT connec_psector.connec_id
                   FROM connec_psector
                  WHERE connec_psector.p_state = 0) a USING (connec_id)
          WHERE a.connec_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(connec.expl_visibility::integer[], connec.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = connec.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = connec.muni_id))
        UNION ALL
         SELECT connec_psector.connec_id,
            connec_psector.arc_id,
            connec_psector.link_id
           FROM connec_psector
          WHERE connec_psector.p_state = 1
        ), connec_selected AS (
         SELECT connec.connec_id,
            connec.code,
            connec.sys_code,
            connec.top_elev,
            connec.y1,
            connec.y2,
            cat_feature.feature_class AS sys_type,
            connec.connec_type::text AS connec_type,
            connec.matcat_id,
            connec.conneccat_id,
            connec.customer_code,
            connec.connec_depth,
            connec.connec_length,
            connec.state,
            connec.state_type,
            connec_selector.arc_id,
            connec.expl_id,
            exploitation.macroexpl_id,
            connec.muni_id,
                CASE
                    WHEN link_planned.sector_id IS NULL THEN connec.sector_id
                    ELSE link_planned.sector_id
                END AS sector_id,
                CASE
                    WHEN link_planned.macrosector_id IS NULL THEN sector_table.macrosector_id
                    ELSE link_planned.macrosector_id
                END AS macrosector_id,
            sector_table.sector_type,
                CASE
                    WHEN link_planned.drainzone_id IS NULL THEN dwfzone_table.drainzone_id
                    ELSE link_planned.drainzone_id
                END AS drainzone_id,
                CASE
                    WHEN link_planned.drainzone_type IS NULL THEN drainzone_table.drainzone_type
                    ELSE link_planned.drainzone_type
                END AS drainzone_type,
            connec.drainzone_outfall,
                CASE
                    WHEN link_planned.dwfzone_id IS NULL THEN connec.dwfzone_id
                    ELSE link_planned.dwfzone_id
                END AS dwfzone_id,
                CASE
                    WHEN link_planned.dwfzone_type IS NULL THEN dwfzone_table.dwfzone_type
                    ELSE link_planned.dwfzone_type
                END AS dwfzone_type,
            connec.dwfzone_outfall,
                CASE
                    WHEN link_planned.omzone_id IS NULL THEN connec.omzone_id
                    ELSE link_planned.omzone_id
                END AS omzone_id,
                CASE
                    WHEN link_planned.macroomzone_id IS NULL THEN omzone_table.macroomzone_id
                    ELSE link_planned.macroomzone_id
                END AS macroomzone_id,
                CASE
                    WHEN link_planned.omzone_type IS NULL THEN omzone_table.omzone_type
                    ELSE link_planned.omzone_type
                END AS omzone_type,
                CASE
                    WHEN link_planned.dma_id IS NULL THEN connec.dma_id
                    ELSE link_planned.dma_id
                END AS dma_id,
            connec.omunit_id,
            connec.minsector_id,
            connec.soilcat_id,
            connec.function_type,
            connec.category_type,
            connec.location_type,
            connec.fluid_type,
            connec.n_hydrometer,
            connec.n_inhabitants,
            connec.demand,
            connec.descript,
            connec.annotation,
            connec.observ,
            connec.comment,
            connec.link::text AS link,
            connec.num_value,
            connec.district_id,
            connec.postcode,
            connec.streetaxis_id,
            connec.postnumber,
            connec.postcomplement,
            connec.streetaxis2_id,
            connec.postnumber2,
            connec.postcomplement2,
            mu.region_id,
            mu.province_id,
            connec.block_code,
            connec.plot_id,
            connec.workcat_id,
            connec.workcat_id_end,
            connec.workcat_id_plan,
            connec.builtdate,
            connec.enddate,
            connec.ownercat_id,
            connec.om_state,
                CASE
                    WHEN link_planned.exit_id IS NULL THEN connec.pjoint_id
                    ELSE link_planned.exit_id
                END AS pjoint_id,
                CASE
                    WHEN link_planned.exit_type IS NULL THEN connec.pjoint_type
                    ELSE link_planned.exit_type
                END AS pjoint_type,
            connec.access_type,
            connec.placement_type,
            connec.accessibility,
            connec.brand_id,
            connec.model_id,
            connec.asset_id,
            connec.adate,
            connec.adescript,
            connec.verified,
            connec.uncertain,
            connec.datasource,
            cat_connec.label,
            connec.label_x,
            connec.label_y,
            connec.label_rotation,
            connec.rotation,
            connec.label_quadrant,
            cat_connec.svg,
            connec.inventory,
            connec.publish,
            vst.is_operative,
            sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
            drainzone_table.stylesheet ->> 'featureColor'::text AS drainzone_style,
            dwfzone_table.stylesheet ->> 'featureColor'::text AS dwfzone_style,
            omzone_table.stylesheet ->> 'featureColor'::text AS omzone_style,
            connec.lock_level,
            connec.expl_visibility,
            ( SELECT st_x(connec.the_geom) AS st_x) AS xcoord,
            ( SELECT st_y(connec.the_geom) AS st_y) AS ycoord,
            ( SELECT st_y(st_transform(connec.the_geom, 4326)) AS st_y) AS lat,
            ( SELECT st_x(st_transform(connec.the_geom, 4326)) AS st_x) AS long,
            date_trunc('second'::text, connec.created_at) AS created_at,
            connec.created_by,
            date_trunc('second'::text, connec.updated_at) AS updated_at,
            connec.updated_by,
            connec.the_geom,
            connec.diagonal
           FROM connec_selector
             JOIN connec USING (connec_id)
             JOIN cat_connec ON cat_connec.id::text = connec.conneccat_id::text
             JOIN cat_feature ON cat_feature.id::text = connec.connec_type::text
             JOIN exploitation ON connec.expl_id = exploitation.expl_id
             JOIN ext_municipality mu ON connec.muni_id = mu.muni_id
             JOIN value_state_type vst ON vst.id = connec.state_type
             JOIN sector_table ON sector_table.sector_id = connec.sector_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = connec.omzone_id
             LEFT JOIN drainzone_table ON connec.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON connec.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN link_planned USING (link_id)
        )
 SELECT connec_id,
    code,
    sys_code,
    top_elev,
    y1,
    y2,
    sys_type,
    connec_type,
    matcat_id,
    conneccat_id,
    customer_code,
    connec_depth,
    connec_length,
    state,
    state_type,
    arc_id,
    expl_id,
    macroexpl_id,
    muni_id,
    sector_id,
    macrosector_id,
    sector_type,
    drainzone_id,
    drainzone_type,
    drainzone_outfall,
    dwfzone_id,
    dwfzone_type,
    dwfzone_outfall,
    omzone_id,
    macroomzone_id,
    omzone_type,
    dma_id,
    omunit_id,
    minsector_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
    n_hydrometer,
    n_inhabitants,
    demand,
    descript,
    annotation,
    observ,
    comment,
    link,
    num_value,
    district_id,
    postcode,
    streetaxis_id,
    postnumber,
    postcomplement,
    streetaxis2_id,
    postnumber2,
    postcomplement2,
    region_id,
    province_id,
    block_code,
    plot_id,
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    enddate,
    ownercat_id,
    om_state,
    pjoint_id,
    pjoint_type,
    access_type,
    placement_type,
    accessibility,
    brand_id,
    model_id,
    asset_id,
    adate,
    adescript,
    verified,
    uncertain,
    datasource,
    label,
    label_x,
    label_y,
    label_rotation,
    rotation,
    label_quadrant,
    svg,
    inventory,
    publish,
    is_operative,
    sector_style,
    drainzone_style,
    dwfzone_style,
    omzone_style,
    lock_level,
    expl_visibility,
    xcoord,
    ycoord,
    lat,
    long,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom,
    diagonal
   FROM connec_selected;

CREATE or replace VIEW v_anl_node_massiveinterpolate
AS SELECT
    n.id,
    n.node_id,
    n.expl_id,
    fid,
    descript,
    top_elev::numeric(12,3),
    elev::numeric(12,3),
    ymax::numeric(12,3),
    n.cur_user,
    the_geom
  FROM anl_node n
    JOIN selector_expl s ON n.expl_id = s.expl_id
  WHERE fid = 496 AND s.cur_user = current_user;

create or replace VIEW v_anl_arc_massiveinterpolate
AS SELECT
    a.id,
    a.arc_id,
    a.expl_id,
    fid,
    descript,
    a.cur_user,
    the_geom
  FROM anl_arc a
    JOIN selector_expl s ON a.expl_id = s.expl_id
  WHERE fid = 496 AND s.cur_user = current_user;


DROP VIEW IF EXISTS ve_epa_conduit;
DROP VIEW IF EXISTS v_rpt_arcflow_sum;

CREATE OR REPLACE VIEW v_rpt_arcflow_sum AS
SELECT rpt_inp_arc.id,
    rpt_inp_arc.arc_id,
    rpt_inp_arc.result_id,
    rpt_inp_arc.arc_type,
    rpt_inp_arc.arccat_id,
    rpt_inp_arc.sector_id,
    rpt_inp_arc.the_geom,
    rpt_arcflow_sum.arc_type AS swarc_type,
    rpt_arcflow_sum.max_flow,
    rpt_arcflow_sum.time_days,
    rpt_arcflow_sum.time_hour,
    rpt_arcflow_sum.max_veloc,
    COALESCE(rpt_arcflow_sum.mfull_flow, 0::numeric(12,4)) AS mfull_flow,
    COALESCE(rpt_arcflow_sum.mfull_depth, 0::numeric(12,4)) AS mfull_depth,
    rpt_arcflow_sum.max_shear,
    rpt_arcflow_sum.max_hr,
    rpt_arcflow_sum.max_slope,
    rpt_arcflow_sum.day_max,
    rpt_arcflow_sum.time_max,
    rpt_arcflow_sum.min_shear,
    rpt_arcflow_sum.day_min,
    rpt_arcflow_sum.time_min
   FROM rpt_inp_arc
   JOIN rpt_arcflow_sum ON rpt_arcflow_sum.arc_id::text = rpt_inp_arc.arc_id::TEXT
   AND rpt_arcflow_sum.result_id = rpt_inp_arc.result_id
  WHERE
EXISTS (SELECT 1 FROM selector_rpt_main r WHERE r.result_id = rpt_inp_arc.result_id AND r.cur_user = CURRENT_USER);


CREATE OR REPLACE VIEW ve_epa_conduit
AS SELECT inp_conduit.arc_id,
    inp_conduit.barrels,
    inp_conduit.culvert,
    inp_conduit.kentry,
    inp_conduit.kexit,
    inp_conduit.kavg,
    inp_conduit.flap,
    inp_conduit.q0,
    inp_conduit.qmax,
    inp_conduit.seepage,
    inp_conduit.custom_n,
    v_rpt_arcflow_sum.max_flow,
    v_rpt_arcflow_sum.time_days,
    v_rpt_arcflow_sum.time_hour,
    v_rpt_arcflow_sum.max_veloc,
    v_rpt_arcflow_sum.mfull_flow,
    v_rpt_arcflow_sum.mfull_depth,
    v_rpt_arcflow_sum.max_shear,
    v_rpt_arcflow_sum.max_hr,
    v_rpt_arcflow_sum.max_slope,
    v_rpt_arcflow_sum.day_max,
    v_rpt_arcflow_sum.time_max,
    v_rpt_arcflow_sum.min_shear,
    v_rpt_arcflow_sum.day_min,
    v_rpt_arcflow_sum.time_min
   FROM inp_conduit
     LEFT JOIN v_rpt_arcflow_sum ON inp_conduit.arc_id::text = v_rpt_arcflow_sum.arc_id::text;

UPDATE config_form_fields SET dv_querytext='SELECT function_type AS id, function_type AS idval FROM man_type_function WHERE active AND (featurecat_id IS NULL AND ''GULLY''=ANY(feature_type))' WHERE formname='ve_gully' AND formtype='form_feature' AND columnname='function_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT category_type AS id, category_type AS idval FROM man_type_category WHERE active AND (featurecat_id IS NULL AND ''GULLY''=ANY(feature_type))' WHERE formname='ve_gully' AND formtype='form_feature' AND columnname='category_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT location_type AS id, location_type AS idval FROM man_type_location WHERE active AND (featurecat_id IS NULL AND ''GULLY''=ANY(feature_type))' WHERE formname='ve_gully' AND formtype='form_feature' AND columnname='location_type' AND tabname='tab_data';

UPDATE config_form_fields SET dv_querytext='SELECT id, idval FROM om_typevalue WHERE typevalue = ''fluid_type''' WHERE formname='ve_element' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT id, idval FROM om_typevalue WHERE typevalue = ''fluid_type''' WHERE formname='ve_arc' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT id, idval FROM om_typevalue WHERE typevalue = ''fluid_type''' WHERE formname='ve_node' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT id, idval FROM om_typevalue WHERE typevalue = ''fluid_type''' WHERE formname='ve_connec' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT id, idval FROM om_typevalue WHERE typevalue = ''fluid_type''' WHERE formname='ve_gully' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';

DELETE FROM config_param_user WHERE "parameter"='edit_insert_show_elevation_from_dem' AND cur_user='postgres';


WITH connec_customer AS (
    SELECT rxc.hydrometer_id,
        MIN(c.customer_code) AS customer_code
    FROM rtc_hydrometer_x_connec rxc
    JOIN connec c ON c.connec_id = rxc.connec_id
    WHERE c.customer_code IS NOT NULL
    GROUP BY rxc.hydrometer_id
)
UPDATE ext_rtc_hydrometer h
SET customer_code = cc.customer_code
FROM connec_customer cc
WHERE h.hydrometer_id = cc.hydrometer_id;

DROP TABLE IF EXISTS rtc_hydrometer_x_connec;

INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3248, 'Massive node interpolation', '{"featureType":[]}'::json,
'[
  {"label": "type:", "value": null, "tooltip": "Process name", "comboIds": ["MASSIVE", "INIT", "FLOWEXIT"], "datatype": "text", "comboNames": ["MASSIVE", "INIT", "FLOWEXIT"], "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "type", "widgettype": "combo", "layoutorder": 1},
  {"label": "Min Ymax (INIT/FLOWEXIT):", "value": null, "tooltip": "Choose minimum ymax value", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "minYmax", "widgettype": "text", "layoutorder": 2},
  {"label": "Max Ymax (INIT/FLOWEXIT):", "value": null, "tooltip": "Choose maximum ynax value", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "maxYmax", "widgettype": "text", "layoutorder": 3},
  {"label": "Min Slope (INIT/FLOWEXIT):", "value": null, "tooltip": "Choose minimum slope", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "minSlope", "widgettype": "text", "layoutorder": 4},
  {"label": "Max Slope (INIT/FLOWEXIT):", "value": null, "tooltip": "Choose maximum slope", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "maxSlope", "widgettype": "text", "layoutorder": 5},
  {"label": "node1 (FLOWEXIT):", "value": null, "tooltip": "Choose source node of your path", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "node1", "widgettype": "text", "layoutorder": 6},
  {"label": "node2 (FLOWEXIT):", "value": null, "tooltip": "Choose target node of your path", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "node2", "widgettype": "text", "layoutorder": 7},
  {"label": "Profile Mode (FLOWEXIT):", "value": null, "tooltip": "Profile mode", "comboIds": ["SMOOTH", "SHALLOW", "DEEP", "CENTERED"], "datatype": "text", "comboNames": ["SMOOTH", "SHALLOW", "DEEP", "CENTERED"], "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "profileMode", "widgettype": "combo", "layoutorder": 8},
  {"label": "Smooth Factor (SMOOTH):", "value": null, "tooltip": "Choose smoothAlpha", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "smoothFactor", "widgettype": "text", "layoutorder": 9}
  ]'::json,
NULL, true, '{4}');


UPDATE sys_function SET sys_role = 'role_edit', function_alias = 'Massive node interpolation' ,
descript =
'PURPOSE
This function calculates node invert elevations using different strategies depending on the requested calculation type.

SUPPORTED TYPES
1) MASSIVE
Legacy mode. For each node with sys_elev IS NULL, the function tries to identify upstream and downstream reference nodes with known elevation and delegates interpolation to gw_fct_node_interpolate.

2) FLOWEXIT
Advanced profile solver mode. The function:
- computes the shortest path between node1 and node2,
- treats node1 and node2 as fixed anchor points,
- may stop earlier at an internal hard point, validates the calculation window,solves the profile globally using: minYmax,maxYmax,minSlope, maxSlope and assigns elevations according to profileMode.

3) INIT
Head node initialization mode. The function:
- finds arcs whose node_1 is a head node (degree = 1, only connected to that arc),
- requires node_2 to have a fixed elevation (sys_elev or custom_elev),
- computes a feasible elevation interval for node_1 using: minYmax, maxYmax, minSlope,  maxSlope,
- updates node_1 when the interval is feasible and writes detailed log messages when the interval is infeasible.

ELEVATION MODEL
- sys_elev is the authoritative known elevation.
- custom_elev is the calculated elevation written by this function.
- The function only writes custom_elev for nodes where sys_elev IS NULL.

PROFILE MODES
- DEEP: Selects the deepest feasible solution.
- SHALLOW: Selects the shallowest feasible solution.
- CENTERED: Selects the midpoint between the lower and upper feasible envelopes.
- SMOOTH: Starts from a centered feasible solution and applies internal smoothing. iterations while preserving feasibility and fixed anchors. SmoothFactor: Strength of each smoothing iteration. Lower values = rougher / more conservative.  Higher values = smoother / more aggressive.

BUSINESS RULES
- custom_elev is only written where sys_elev IS NULL.
- MASSIVE interpolates node by node using nearby known references.
- FLOWEXIT solves a constrained profile along shortest path(node1, node2).
- In FLOWEXIT, node1 and node2 are always fixed anchors.
- Internal hard points can also act as fixed anchors.
- Hard points are nodes with degree > 2, existing custom_elev, and at least one connected arc with slope.
- Hard points are not cleaned or recalculated.
- INIT only processes head arcs where node_1 has degree = 1. In INIT, node_2 must already have fixed elevation.
- FLOWEXIT and INIT must satisfy Ymax and slope constraints.
- Infeasible cases are logged in audit_check_data with detailed diagnostics.'
WHERE id  = 3248;


INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('v_anl_node_massiveinterpolate', 'Massive interpolate for nodes', 'role_basic', 'core') ON CONFLICT DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('v_anl_arc_massiveinterpolate', 'Massive interpolate for arcs', 'role_basic', 'core') ON CONFLICT DO NOTHING;


INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4628, 'Number of nodes interpolated', null, 2, true, 'ud', 'core', 'UI') ON CONFLICT DO NOTHING;


DROP RULE IF EXISTS dwfzone_expl ON dwfzone;
INSERT INTO dwfzone (dwfzone_id, code, "name", dwfzone_type, expl_id, sector_id, muni_id, descript, link, graphconfig, stylesheet, lock_level, active, the_geom, created_at, created_by, updated_at, updated_by, drainzone_id, addparam) VALUES(-1, '-1', 'Conflict', NULL, '{0}', '{0}', '{0}', 'Dwfzone used on graphanalytics algorithm when two ore more zones has conflict in terms of some interconnection.', NULL, '{"use":[{"nodeParent":""}], "ignore":[], "forceClosed":[]}'::json, NULL, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL) ON CONFLICT (dwfzone_id) DO NOTHING;


INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4630, 'The node does not belong to the selected lot', 'Choose a node that belongs to the selected lot or change selected lot', 2, true, 'ud', 'core', 'UI') ON CONFLICT DO NOTHING;


INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_drainzone', 'tab_drainzone', 'tabRelations', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_dwfzone', 'tab_dwfzone', 'tabRelations', NULL);

INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_drainzone', 'Drainzone', 'Drainzone', 'role_basic', NULL, NULL, 5, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_dwfzone', 'Dwfzone', 'Dwfzone', 'role_basic', NULL, NULL, 6, '{4}');

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'tab_main', 'lyt_mapzone_mng_2', 1, NULL, 'tabwidget', NULL, NULL, NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "tabs": [
    "tab_macrosector",
	"tab_sector",
	"tab_drainzone",
	"tab_dwfzone",
	"tab_dma",
	"tab_macroomzone"
  ]
}'::json, NULL, NULL, false, 10);

UPDATE sys_function SET id = 2430, project_type = 'utils' WHERE function_name = 'gw_fct_pg2epa_check_data';


INSERT INTO sys_feature_class (id, "type", epa_default, man_table) VALUES('NETSAMPLEPOINT', 'NODE', 'JUNCTION', 'man_netsamplepoint');

INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('man_netsamplepoint', 'Additional information for netsamplepoint management', 'role_edit', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;


DO $$
DECLARE
	rec record;
	v_new_id integer;
	v_exit_id integer;
	v_conneccat_id varchar;
	v_connec_epa text;
	v_has_exit boolean;
	v_exit_is_arc boolean;
BEGIN
  IF (SELECT COUNT(*) FROM _samplepoint_) > 0 THEN
    RAISE NOTICE 'Samplepoints found, inserting new connecs...';
    INSERT INTO cat_feature (id, feature_class, feature_type, parent_layer, child_layer, active) VALUES ('SAMPLEPOINT', 'SAMPLEPOINT','CONNEC', 've_connec', 've_connec_samplepoint', true) ON CONFLICT (id) DO NOTHING;

    INSERT INTO cat_connec (id,connec_type,matcat_id,pnom,dnom,dint,active)
	  VALUES ('UPDATE_SAMPLEPOINT_490','SAMPLEPOINT','PVC','16','25',25.00000,true) ON CONFLICT (id) DO NOTHING;

    v_conneccat_id := 'UPDATE_SAMPLEPOINT_490';
    v_connec_epa := 'JUNCTION';

    FOR rec IN
      SELECT *
      FROM _samplepoint_ sp
      ORDER BY sp.sample_id
    LOOP
      v_new_id := NULL;
      v_exit_id := CASE WHEN rec.feature_id ~ '^[0-9]+$' THEN rec.feature_id::integer ELSE NULL END;

      INSERT INTO connec (
        code, top_elev, depth, conneccat_id, epa_type, state, state_type,
        expl_id, muni_id, sector_id, dma_id, presszone_id, district_id,
        streetaxis_id, postcode, postnumber, postcomplement,
        streetaxis2_id, postnumber2, postcomplement2,
        workcat_id, workcat_id_end, builtdate, enddate,
        verified, rotation, the_geom
      ) VALUES (
        rec.code, NULL, NULL, v_conneccat_id, v_connec_epa, rec.state, 2,
        rec.expl_id, rec.muni_id, COALESCE(rec.sector_id, 0), rec.dma_id, rec.presszone_id, rec.district_id,
        rec.streetaxis_id, rec.postcode, rec.postnumber, rec.postcomplement,
        rec.streetaxis2_id, rec.postnumber2, rec.postcomplement2,
        rec.workcat_id, rec.workcat_id_end, rec.builtdate, rec.enddate,
        rec.verified, rec.rotation, rec.the_geom
      )
      RETURNING connec_id INTO v_new_id;

      INSERT INTO man_samplepoint (connec_id, lab_code, place_name, cabinet)
      VALUES (v_new_id, rec.lab_code, rec.place_name, rec.cabinet);

      v_has_exit := v_exit_id IS NOT NULL AND (
        EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = v_exit_id)
        OR EXISTS (SELECT 1 FROM node n WHERE n.node_id = v_exit_id)
        OR EXISTS (SELECT 1 FROM connec c WHERE c.connec_id = v_exit_id)
      );
      IF v_has_exit THEN
        v_exit_is_arc := EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = v_exit_id);

        IF v_exit_is_arc IS FALSE THEN
          -- If exit_id refers to a node, find an arc that connects to this node
          SELECT arc_id INTO v_exit_id
          FROM arc
          WHERE node_1 = v_exit_id OR node_2 = v_exit_id
          LIMIT 1;

          v_exit_is_arc := v_exit_id IS NOT NULL;
        END IF;

        IF v_exit_is_arc THEN
          PERFORM gw_fct_setlinktonetwork(
            json_build_object(
              'client', json_build_object('device', 4, 'infoType', 1, 'lang', 'ES'),
              'feature', json_build_object('id', to_json(ARRAY[v_new_id::text])),
              'data', json_build_object(
                'feature_type', 'CONNEC',
                'forcedArcs', to_json(ARRAY[v_exit_id::text])
              )
            )
          );
        END IF;
      END IF;
    END LOOP;

  ELSE
    RAISE NOTICE 'No samplepoints found, skipping...';
  END IF;
END $$;


UPDATE config_param_system
SET value = jsonb_set(
    value::jsonb,
    '{sys_fct_tablename}',
    '"ve_gully"'
)
WHERE parameter = 'basic_search_v2_tab_network_gully';


UPDATE config_toolbox
	SET inputparams='[
  {
    "widgetname": "graphClass",
    "label": "Graph class:",
    "widgettype": "combo",
    "datatype": "text",
    "tooltip": "Graphanalytics method used",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "comboIds": [
      "MACROSECTOR",
      "MACROOMZONE"
    ],
    "comboNames": [
      "MACROSECTOR",
      "MACROOMZONE"
    ],
    "selectedId": null
  },
  {
    "widgetname": "exploitation",
    "label": "Exploitation:",
    "widgettype": "combo",
    "datatype": "text",
    "tooltip": "Choose exploitation to work with",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "SELECT id, idval FROM ( SELECT -901 AS id, ''User selected expl'' AS idval, ''a'' AS sort_order UNION SELECT -902 AS id, ''All exploitations'' AS idval, ''b'' AS sort_order UNION SELECT expl_id AS id, name AS idval, ''c'' AS sort_order FROM exploitation WHERE active IS NOT FALSE ) a ORDER BY sort_order ASC, idval ASC",
    "selectedId": null
  },
  {
    "widgetname": "commitChanges",
    "label": "Commit changes:",
    "widgettype": "check",
    "datatype": "boolean",
    "tooltip": "If True, changes will be applied to DB. If False, algorithm results will be saved in a temporal layer",
    "layoutname": "grl_option_parameters",
    "layoutorder": 8,
    "value": null
  },
  {
    "label": "Mapzone constructor method:",
    "comboIds": [
      0,
      1,
      2,
      3,
      4
    ],
    "datatype": "integer",
    "comboNames": [
      "NONE",
      "CONCAVE POLYGON",
      "PIPE BUFFER",
      "PLOT & PIPE BUFFER",
      "LINK & PIPE BUFFER"
    ],
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "updateMapZone",
    "widgettype": "combo",
    "layoutorder": 9
  },
  {
    "label": "Pipe buffer",
    "value": null,
    "tooltip": "Buffer from arcs to create mapzone geometry using [PIPE BUFFER] options. Normal values maybe between 3-20 mts.",
    "datatype": "float",
    "layoutname": "grl_option_parameters",
    "widgetname": "geomParamUpdate",
    "widgettype": "text",
    "isMandatory": false,
    "layoutorder": 10,
    "placeholder": "5-30"
  }
]'::json
	WHERE id=3482;

UPDATE config_toolbox
SET "inputparams"='[{"label": "Graph class:", "tooltip": "Graphanalytics method used", "comboIds": ["DWFZONE", "SECTOR", "DMA"], "datatype": "text", "comboNames": ["Drainage area (DRAINZONE + DWFZONE)", "SECTOR", "DMA"], "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "graphClass", "widgettype": "combo", "layoutorder": 1}, {"label": "Exploitation:", "tooltip": "Choose exploitation to work with", "datatype": "text", "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "exploitation", "widgettype": "combo", "dvQueryText": "SELECT id, idval FROM ( SELECT -901 AS id, ''User selected expl'' AS idval, ''a'' AS sort_order UNION SELECT -902 AS id, ''All exploitations'' AS idval, ''b'' AS sort_order UNION SELECT expl_id AS id, name AS idval, ''c'' AS sort_order FROM exploitation WHERE active IS NOT FALSE AND expl_id > 0 ) a ORDER BY sort_order ASC, idval ASC", "layoutorder": 2}, {"label": "Force open arcs: (*)", "value": null, "tooltip": "Optative arc id(s) to temporary open closed arc(s) in order to force algorithm to continue there", "datatype": "text", "layoutname": "grl_option_parameters", "widgetname": "forceOpen", "widgettype": "linetext", "isMandatory": false, "layoutorder": 5, "placeholder": "1015,2231,3123"}, {"label": "Force closed arcs: (*)", "value": null, "tooltip": "Optative arc id(s) to temporary close open arc(s) to force algorithm to stop there", "datatype": "text", "layoutname": "grl_option_parameters", "widgetname": "forceClosed", "widgettype": "text", "isMandatory": false, "layoutorder": 6, "placeholder": "1015,2231,3123"}, {"label": "Use selected psectors:", "value": null, "tooltip": "If true, use selected psectors. If false ignore selected psectors and only works with on-service network", "datatype": "boolean", "layoutname": "grl_option_parameters", "widgetname": "usePlanPsector", "widgettype": "check", "layoutorder": 7}, {"label": "Commit changes:", "value": null, "tooltip": "If true, changes will be applied to DB. If false, algorithm results will be saved in anl tables", "datatype": "boolean", "layoutname": "grl_option_parameters", "widgetname": "commitChanges", "widgettype": "check", "layoutorder": 8}, {"label": "Mapzone constructor method:", "comboIds": [0, 1, 2, 6], "datatype": "integer", "comboNames": ["NONE", "CONCAVE POLYGON", "PIPE BUFFER", "EPA SUBCATCH"], "layoutname": "grl_option_parameters", "selectedId": null, "widgetname": "updateMapZone", "widgettype": "combo", "layoutorder": 10}, {"label": "Pipe buffer", "value": null, "tooltip": "Buffer from arcs to create mapzone geometry using [PIPE BUFFER] options. Normal values maybe between 3-20 mts.", "datatype": "float", "layoutname": "grl_option_parameters", "widgetname": "geomParamUpdate", "widgettype": "text", "isMandatory": false, "layoutorder": 11, "placeholder": "5-30"}, {"label": "Mapzones from zero:", "value": null, "tooltip": "If true, mapzones are calculated automatically from zero", "datatype": "boolean", "layoutname": "grl_option_parameters", "widgetname": "fromZero", "widgettype": "check", "layoutorder": 12}]'::json
WHERE id = 2768;



UPDATE sys_style
	SET stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.40.9-Bratislava">
  <renderer-v2 symbollevels="0" enableorderby="0" type="RuleRenderer" referencescale="-1" forceraster="0">
    <rules key="{0636f35c-7cdb-4ac1-935d-1cf79c89bfa5}">
      <rule symbol="0" label="FLUID TYPE" key="{ecd5686e-b0b0-4a8a-867a-3e881ff055ed}">
        <rule filter="&quot;fluid_type&quot; = ''0''" symbol="1" label="NOT INFORMED" key="{40e8c9c5-e496-4f35-8c10-e31f6d62aba8}"/>
        <rule filter="&quot;fluid_type&quot; = ''1''" symbol="2" label="STORMWATER" key="{4a15a529-2726-4994-8c68-89318c76da72}"/>
        <rule filter="&quot;fluid_type&quot; = ''2''" symbol="3" label="COMBINED DILUTED" key="{35abe4e2-8068-4788-88ad-ad882466bca2}"/>
        <rule filter="&quot;fluid_type&quot; = ''3''" symbol="4" label="SEWAGE" key="{a9358e41-776d-4a35-a01f-d1239b85409f}"/>
        <rule filter="&quot;fluid_type&quot; = ''4''" symbol="5" label="COMBINED" key="{6932aaa4-244a-48eb-89c8-0eb1ff750952}"/>
      </rule>
      <rule filter="initoverflowpath IS FALSE" symbol="6" label="Initoverflowpath FALSE" key="{997a52d5-68d3-4988-8274-c9a9ad97ae73}"/>
      <rule filter="initoverflowpath IS TRUE" symbol="7" label="Initoverflowpath TRUE" key="{53702b46-77ae-48dc-87cb-adc8d9b4d459}"/>
    </rules>
    <symbols>
      <symbol force_rhr="0" frame_rate="10" name="0" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{82d77555-fd1a-4c4b-9dfb-6cf4f89043ea}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="223,0,255,0,hsv:0.8125,1,1,0" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="1" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{e27969d7-935c-44dd-b635-1762befd319c}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="0,236,255,255,rgb:0,0.92549019607843142,1,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="2" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{f5733214-6984-4124-9c69-b801dad5db3d}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="204,163,0,255,rgb:0.80000000000000004,0.63921568627450975,0,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="3" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{c48c11c7-7bb9-4b99-8b87-f1ba495dbaca}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="255,0,0,255,rgb:1,0,0,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="4" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{1faa0c62-4b21-408e-8118-b4d46d1e1f83}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="255,0,242,255,rgb:1,0,0.94901960784313721,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="5" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{dcfa2132-2ed5-4aef-8162-caa7823b95bd}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="0,255,76,255,rgb:0,1,0.29803921568627451,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="6" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{22a8834d-18a7-497b-92ee-d4d461063da0}" locked="0" enabled="1" class="MarkerLine">
          <Option type="Map">
            <Option name="average_angle_length" value="4" type="QString"/>
            <Option name="average_angle_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="average_angle_unit" value="MM" type="QString"/>
            <Option name="interval" value="3" type="QString"/>
            <Option name="interval_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="interval_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_along_line" value="0" type="QString"/>
            <Option name="offset_along_line_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_along_line_unit" value="MM" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="place_on_every_part" value="true" type="bool"/>
            <Option name="placements" value="Interval" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="rotate" value="1" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
          <symbol force_rhr="0" frame_rate="10" name="@6@0" alpha="1" is_animated="0" type="marker" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" value="" type="QString"/>
                <Option name="properties"/>
                <Option name="type" value="collection" type="QString"/>
              </Option>
            </data_defined_properties>
            <layer pass="0" id="{6d54d628-e447-4f9b-aa18-854b2fc7a132}" locked="0" enabled="1" class="SimpleMarker">
              <Option type="Map">
                <Option name="angle" value="0" type="QString"/>
                <Option name="cap_style" value="square" type="QString"/>
                <Option name="color" value="0,0,0,255,hsv:0.63749999999999996,0.5077744716563668,0,1" type="QString"/>
                <Option name="horizontal_anchor_point" value="1" type="QString"/>
                <Option name="joinstyle" value="bevel" type="QString"/>
                <Option name="name" value="circle" type="QString"/>
                <Option name="offset" value="0,0" type="QString"/>
                <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="offset_unit" value="MM" type="QString"/>
                <Option name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString"/>
                <Option name="outline_style" value="solid" type="QString"/>
                <Option name="outline_width" value="0" type="QString"/>
                <Option name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="outline_width_unit" value="MM" type="QString"/>
                <Option name="scale_method" value="diameter" type="QString"/>
                <Option name="size" value="1.5" type="QString"/>
                <Option name="size_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="size_unit" value="MM" type="QString"/>
                <Option name="vertical_anchor_point" value="1" type="QString"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" value="" type="QString"/>
                  <Option name="properties"/>
                  <Option name="type" value="collection" type="QString"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="7" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{3d948eb9-9960-4238-9138-1757f13eaeee}" locked="0" enabled="1" class="MarkerLine">
          <Option type="Map">
            <Option name="average_angle_length" value="4" type="QString"/>
            <Option name="average_angle_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="average_angle_unit" value="MM" type="QString"/>
            <Option name="interval" value="3" type="QString"/>
            <Option name="interval_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="interval_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_along_line" value="0" type="QString"/>
            <Option name="offset_along_line_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_along_line_unit" value="MM" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="place_on_every_part" value="true" type="bool"/>
            <Option name="placements" value="Interval" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="rotate" value="1" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
          <symbol force_rhr="0" frame_rate="10" name="@7@0" alpha="1" is_animated="0" type="marker" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" value="" type="QString"/>
                <Option name="properties"/>
                <Option name="type" value="collection" type="QString"/>
              </Option>
            </data_defined_properties>
            <layer pass="0" id="{2675b728-5ff3-49a7-9855-100d997df1fc}" locked="0" enabled="1" class="SimpleMarker">
              <Option type="Map">
                <Option name="angle" value="0" type="QString"/>
                <Option name="cap_style" value="square" type="QString"/>
                <Option name="color" value="255,255,255,255,hsv:0,0,1,1" type="QString"/>
                <Option name="horizontal_anchor_point" value="1" type="QString"/>
                <Option name="joinstyle" value="bevel" type="QString"/>
                <Option name="name" value="circle" type="QString"/>
                <Option name="offset" value="0,0" type="QString"/>
                <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="offset_unit" value="MM" type="QString"/>
                <Option name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString"/>
                <Option name="outline_style" value="solid" type="QString"/>
                <Option name="outline_width" value="0" type="QString"/>
                <Option name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="outline_width_unit" value="MM" type="QString"/>
                <Option name="scale_method" value="diameter" type="QString"/>
                <Option name="size" value="1.5" type="QString"/>
                <Option name="size_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="size_unit" value="MM" type="QString"/>
                <Option name="vertical_anchor_point" value="1" type="QString"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" value="" type="QString"/>
                  <Option name="properties"/>
                  <Option name="type" value="collection" type="QString"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" value="" type="QString"/>
        <Option name="properties"/>
        <Option name="type" value="collection" type="QString"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol force_rhr="0" frame_rate="10" name="" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{e56f016d-a2d7-4934-8012-09784c514d01}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="0.26" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
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
'
	WHERE layername='Fluid Type Lines' AND styleconfig_id=101;

UPDATE sys_style SET stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.40.8-Bratislava" styleCategories="Symbology|Labeling" labelsEnabled="1">
  <renderer-v2 forceraster="0" referencescale="-1" type="RuleRenderer" enableorderby="0" symbollevels="0">
    <rules key="{fa44a69a-c6e2-45fc-8b74-9424880bcf8e}">
      <rule label="0% - 50%" filter="&quot;mfull_depth_compare&quot; >= 0 AND &quot;mfull_depth_compare&quot; &lt;= 0.5" key="{5228d50d-7467-4079-b88f-079bc22aa232}" symbol="0"/>
      <rule label="51% - 70%" filter="&quot;mfull_depth_compare&quot; > 0.5 AND &quot;mfull_depth_compare&quot; &lt;= 0.7" key="{605ca4d9-4f82-4656-b48f-16f77067c1a7}" symbol="1"/>
      <rule label="71% - 85%" filter="&quot;mfull_depth_compare&quot; > 0.7 AND &quot;mfull_depth_compare&quot; &lt;= 0.85" key="{606f5076-56a8-493b-89b9-60a974e9e6fb}" symbol="2"/>
      <rule label="86% - 100%" filter="&quot;mfull_depth_compare&quot; > 0.85 AND &quot;mfull_depth_compare&quot; &lt;= 1" key="{f8e30195-8b1c-483f-9d5e-defca173ac2f}" symbol="3"/>
    </rules>
    <symbols>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{12dbbec5-66e6-41a6-ba96-6f9f07d628ad}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="53,165,45,255,rgb:0.20784313725490197,0.6470588235294118,0.17647058823529413,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{b7a2be15-2ccb-4905-ab21-52177fe67849}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="66,181,236,255,rgb:0.25882352941176473,0.70980392156862748,0.92549019607843142,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="2">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{52ee2378-098c-46a7-a535-97d0fb0beea5}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="250,126,39,255,rgb:0.98039215686274506,0.49411764705882355,0.15294117647058825,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="3">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{4bc79f1b-1065-41a4-9946-a872d4885cae}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="212,26,28,255,rgb:0.83137254901960789,0.10196078431372549,0.10980392156862745,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option type="QString" value="" name="name"/>
        <Option name="properties"/>
        <Option type="QString" value="collection" name="type"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{7b5ef12c-e372-44b6-808e-6c386ded9ce8}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.26" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style tabStopDistance="80" fontSizeMapUnitScale="3x:0,0,0,0,0,0" multilineHeight="1" fontSize="8" fontItalic="0" fieldName="arccat_id" fontFamily="Arial" textOrientation="horizontal" textOpacity="1" blendMode="0" fontWordSpacing="0" textColor="0,0,0,255,rgb:0,0,0,1" multilineHeightUnit="Percentage" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" namedStyle="Normal" fontSizeUnit="Point" fontStrikeout="0" stretchFactor="100" useSubstitutions="0" forcedBold="0" isExpression="0" allowHtml="0" forcedItalic="0" fontKerning="1" fontLetterSpacing="0" fontUnderline="0" fontWeight="50" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" legendString="Aa" tabStopDistanceUnit="Point" capitalization="0">
        <families/>
        <text-buffer bufferNoFill="0" bufferColor="255,255,255,255,rgb:1,1,1,1" bufferSizeUnits="MM" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferBlendMode="0" bufferSize="1" bufferDraw="0" bufferOpacity="1" bufferJoinStyle="64"/>
        <text-mask maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskedSymbolLayers="" maskSize="1.5" maskSize2="1.5" maskOpacity="1" maskSizeUnits="MM" maskJoinStyle="128" maskType="0" maskEnabled="0"/>
        <background shapeOffsetX="0" shapeBlendMode="0" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidthUnit="MM" shapeDraw="0" shapeType="0" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeOffsetY="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeSizeType="0" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeBorderColor="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" shapeJoinStyle="64" shapeOffsetUnit="MM" shapeRadiiY="0" shapeRadiiX="0" shapeSVGFile="" shapeBorderWidth="0" shapeRotationType="0" shapeRadiiUnit="MM" shapeSizeUnit="MM" shapeOpacity="1" shapeRotation="0" shapeSizeX="0" shapeSizeY="0">
          <symbol type="marker" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="markerSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer class="SimpleMarker" pass="0" enabled="1" id="" locked="0">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="196,60,57,255,rgb:0.7686274509803922,0.23529411764705882,0.22352941176470589,1" name="color"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="circle" name="name"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="solid" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="diameter" name="scale_method"/>
                <Option type="QString" value="2" name="size"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
                <Option type="QString" value="MM" name="size_unit"/>
                <Option type="QString" value="1" name="vertical_anchor_point"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" value="" name="name"/>
                  <Option name="properties"/>
                  <Option type="QString" value="collection" name="type"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
          <symbol type="fill" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="fillSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer class="SimpleFill" pass="0" enabled="1" id="" locked="0">
              <Option type="Map">
                <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" name="outline_color"/>
                <Option type="QString" value="no" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="solid" name="style"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" value="" name="name"/>
                  <Option name="properties"/>
                  <Option type="QString" value="collection" name="type"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </background>
        <shadow shadowOffsetDist="1" shadowOpacity="0.69999999999999996" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowDraw="0" shadowUnder="0" shadowScale="100" shadowRadius="1.5" shadowRadiusUnit="MM" shadowOffsetUnit="MM" shadowOffsetGlobal="1" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowBlendMode="6" shadowOffsetAngle="135" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowRadiusAlphaOnly="0"/>
        <dd_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format leftDirectionSymbol="&lt;" placeDirectionSymbol="0" rightDirectionSymbol=">" useMaxLineLengthForAutoWrap="1" multilineAlign="0" decimals="3" autoWrapLength="0" formatNumbers="0" addDirectionSymbol="0" plussign="0" reverseDirectionSymbol="0" wrapChar=""/>
      <placement dist="0" overlapHandling="PreventOverlap" centroidInside="0" placementFlags="10" overrunDistanceUnit="MM" distMapUnitScale="3x:0,0,0,0,0,0" geometryGeneratorType="PointGeometry" lineAnchorClipping="0" offsetUnits="MapUnit" offsetType="0" repeatDistanceUnits="MM" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" maxCurvedCharAngleIn="20" preserveRotation="1" yOffset="0" geometryGenerator="" overrunDistance="0" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" polygonPlacementFlags="2" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" placement="2" geometryGeneratorEnabled="0" priority="5" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" prioritization="PreferCloser" xOffset="0" lineAnchorType="0" maximumDistanceUnit="MM" rotationAngle="0" layerType="LineGeometry" quadOffset="4" centroidWhole="0" maximumDistance="0" rotationUnit="AngleDegrees" lineAnchorTextPoint="CenterOfText" fitInPolygonOnly="0" repeatDistance="0" maxCurvedCharAngleOut="-20" allowDegraded="0" lineAnchorPercent="0.5" distUnits="MM"/>
      <rendering upsidedownLabels="0" obstacleFactor="1" unplacedVisibility="0" minFeatureSize="0" obstacleType="0" fontMaxPixelSize="10000" mergeLines="0" scaleMin="1" drawLabels="1" fontMinPixelSize="3" scaleVisibility="1" limitNumLabels="0" zIndex="0" fontLimitPixelSize="0" maxNumLabels="2000" labelPerPart="0" obstacle="1" scaleMax="3000"/>
      <dd_properties>
        <Option type="Map">
          <Option type="QString" value="" name="name"/>
          <Option name="properties"/>
          <Option type="QString" value="collection" name="type"/>
        </Option>
      </dd_properties>
      <callout type="simple">
        <Option type="Map">
          <Option type="QString" value="pole_of_inaccessibility" name="anchorPoint"/>
          <Option type="int" value="0" name="blendMode"/>
          <Option type="Map" name="ddProperties">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
          <Option type="bool" value="false" name="drawToAllParts"/>
          <Option type="QString" value="0" name="enabled"/>
          <Option type="QString" value="point_on_exterior" name="labelAnchorPoint"/>
          <Option type="QString" value="&lt;symbol type=&quot;line&quot; clip_to_extent=&quot;1&quot; alpha=&quot;1&quot; is_animated=&quot;0&quot; force_rhr=&quot;0&quot; frame_rate=&quot;10&quot; name=&quot;symbol&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer class=&quot;SimpleLine&quot; pass=&quot;0&quot; enabled=&quot;1&quot; id=&quot;{e2e73dbb-bfcf-457b-8501-e974a735ee6d}&quot; locked=&quot;0&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;align_dash_pattern&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;square&quot; name=&quot;capstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;5;2&quot; name=&quot;customdash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;customdash_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;customdash_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;dash_pattern_offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;dash_pattern_offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;dash_pattern_offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;draw_inside_polygon&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;bevel&quot; name=&quot;joinstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.23529411764705882,0.23529411764705882,0.23529411764705882,1&quot; name=&quot;line_color&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;solid&quot; name=&quot;line_style&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0.3&quot; name=&quot;line_width&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;line_width_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;ring_filter&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_end&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_end_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_end_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_start&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_start_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_start_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;tweak_dash_pattern_on_corners&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;use_custom_dash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;width_map_unit_scale&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>" name="lineSymbol"/>
          <Option type="double" value="0" name="minLength"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="minLengthMapUnitScale"/>
          <Option type="QString" value="MM" name="minLengthUnit"/>
          <Option type="double" value="0" name="offsetFromAnchor"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="offsetFromAnchorMapUnitScale"/>
          <Option type="QString" value="MM" name="offsetFromAnchorUnit"/>
          <Option type="double" value="0" name="offsetFromLabel"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="offsetFromLabelMapUnitScale"/>
          <Option type="QString" value="MM" name="offsetFromLabelUnit"/>
        </Option>
      </callout>
    </settings>
  </labeling>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>' WHERE layername IN ('v_rpt_comp_arcflow_sum');


UPDATE sys_style SET stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.40.8-Bratislava" styleCategories="Symbology|Labeling" labelsEnabled="1">
  <renderer-v2 forceraster="0" referencescale="-1" type="RuleRenderer" enableorderby="0" symbollevels="0">
    <rules key="{fa44a69a-c6e2-45fc-8b74-9424880bcf8e}">
      <rule label="0% - 50%" filter="&quot;mfull_depth&quot; >= 0 AND &quot;mfull_depth&quot; &lt;= 0.5" key="{5228d50d-7467-4079-b88f-079bc22aa232}" symbol="0"/>
      <rule label="51% - 70%" filter="&quot;mfull_depth&quot; > 0.5 AND &quot;mfull_depth&quot; &lt;= 0.7" key="{605ca4d9-4f82-4656-b48f-16f77067c1a7}" symbol="1"/>
      <rule label="71% - 85%" filter="&quot;mfull_depth&quot; > 0.7 AND &quot;mfull_depth&quot; &lt;= 0.85" key="{606f5076-56a8-493b-89b9-60a974e9e6fb}" symbol="2"/>
      <rule label="86% - 100%" filter="&quot;mfull_depth&quot; > 0.85 AND &quot;mfull_depth&quot; &lt;= 1" key="{f8e30195-8b1c-483f-9d5e-defca173ac2f}" symbol="3"/>
    </rules>
    <symbols>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{12dbbec5-66e6-41a6-ba96-6f9f07d628ad}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="53,165,45,255,rgb:0.20784313725490197,0.6470588235294118,0.17647058823529413,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{b7a2be15-2ccb-4905-ab21-52177fe67849}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="66,181,236,255,rgb:0.25882352941176473,0.70980392156862748,0.92549019607843142,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="2">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{52ee2378-098c-46a7-a535-97d0fb0beea5}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="250,126,39,255,rgb:0.98039215686274506,0.49411764705882355,0.15294117647058825,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="3">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{4bc79f1b-1065-41a4-9946-a872d4885cae}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="212,26,28,255,rgb:0.83137254901960789,0.10196078431372549,0.10980392156862745,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.65" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option type="QString" value="" name="name"/>
        <Option name="properties"/>
        <Option type="QString" value="collection" name="type"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol type="line" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" pass="0" enabled="1" id="{7b5ef12c-e372-44b6-808e-6c386ded9ce8}" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.26" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style tabStopDistance="80" fontSizeMapUnitScale="3x:0,0,0,0,0,0" multilineHeight="1" fontSize="8" fontItalic="0" fieldName="arccat_id" fontFamily="Arial" textOrientation="horizontal" textOpacity="1" blendMode="0" fontWordSpacing="0" textColor="0,0,0,255,rgb:0,0,0,1" multilineHeightUnit="Percentage" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" namedStyle="Normal" fontSizeUnit="Point" fontStrikeout="0" stretchFactor="100" useSubstitutions="0" forcedBold="0" isExpression="0" allowHtml="0" forcedItalic="0" fontKerning="1" fontLetterSpacing="0" fontUnderline="0" fontWeight="50" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" legendString="Aa" tabStopDistanceUnit="Point" capitalization="0">
        <families/>
        <text-buffer bufferNoFill="0" bufferColor="255,255,255,255,rgb:1,1,1,1" bufferSizeUnits="MM" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferBlendMode="0" bufferSize="1" bufferDraw="0" bufferOpacity="1" bufferJoinStyle="64"/>
        <text-mask maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskedSymbolLayers="" maskSize="1.5" maskSize2="1.5" maskOpacity="1" maskSizeUnits="MM" maskJoinStyle="128" maskType="0" maskEnabled="0"/>
        <background shapeOffsetX="0" shapeBlendMode="0" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidthUnit="MM" shapeDraw="0" shapeType="0" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeOffsetY="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeSizeType="0" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeBorderColor="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" shapeJoinStyle="64" shapeOffsetUnit="MM" shapeRadiiY="0" shapeRadiiX="0" shapeSVGFile="" shapeBorderWidth="0" shapeRotationType="0" shapeRadiiUnit="MM" shapeSizeUnit="MM" shapeOpacity="1" shapeRotation="0" shapeSizeX="0" shapeSizeY="0">
          <symbol type="marker" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="markerSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer class="SimpleMarker" pass="0" enabled="1" id="" locked="0">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="196,60,57,255,rgb:0.7686274509803922,0.23529411764705882,0.22352941176470589,1" name="color"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="circle" name="name"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="solid" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="diameter" name="scale_method"/>
                <Option type="QString" value="2" name="size"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
                <Option type="QString" value="MM" name="size_unit"/>
                <Option type="QString" value="1" name="vertical_anchor_point"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" value="" name="name"/>
                  <Option name="properties"/>
                  <Option type="QString" value="collection" name="type"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
          <symbol type="fill" clip_to_extent="1" alpha="1" is_animated="0" force_rhr="0" frame_rate="10" name="fillSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer class="SimpleFill" pass="0" enabled="1" id="" locked="0">
              <Option type="Map">
                <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" name="outline_color"/>
                <Option type="QString" value="no" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="solid" name="style"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" value="" name="name"/>
                  <Option name="properties"/>
                  <Option type="QString" value="collection" name="type"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </background>
        <shadow shadowOffsetDist="1" shadowOpacity="0.69999999999999996" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowDraw="0" shadowUnder="0" shadowScale="100" shadowRadius="1.5" shadowRadiusUnit="MM" shadowOffsetUnit="MM" shadowOffsetGlobal="1" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowBlendMode="6" shadowOffsetAngle="135" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowRadiusAlphaOnly="0"/>
        <dd_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format leftDirectionSymbol="&lt;" placeDirectionSymbol="0" rightDirectionSymbol=">" useMaxLineLengthForAutoWrap="1" multilineAlign="0" decimals="3" autoWrapLength="0" formatNumbers="0" addDirectionSymbol="0" plussign="0" reverseDirectionSymbol="0" wrapChar=""/>
      <placement dist="0" overlapHandling="PreventOverlap" centroidInside="0" placementFlags="10" overrunDistanceUnit="MM" distMapUnitScale="3x:0,0,0,0,0,0" geometryGeneratorType="PointGeometry" lineAnchorClipping="0" offsetUnits="MapUnit" offsetType="0" repeatDistanceUnits="MM" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" maxCurvedCharAngleIn="20" preserveRotation="1" yOffset="0" geometryGenerator="" overrunDistance="0" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" polygonPlacementFlags="2" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" placement="2" geometryGeneratorEnabled="0" priority="5" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" prioritization="PreferCloser" xOffset="0" lineAnchorType="0" maximumDistanceUnit="MM" rotationAngle="0" layerType="LineGeometry" quadOffset="4" centroidWhole="0" maximumDistance="0" rotationUnit="AngleDegrees" lineAnchorTextPoint="CenterOfText" fitInPolygonOnly="0" repeatDistance="0" maxCurvedCharAngleOut="-20" allowDegraded="0" lineAnchorPercent="0.5" distUnits="MM"/>
      <rendering upsidedownLabels="0" obstacleFactor="1" unplacedVisibility="0" minFeatureSize="0" obstacleType="0" fontMaxPixelSize="10000" mergeLines="0" scaleMin="1" drawLabels="1" fontMinPixelSize="3" scaleVisibility="1" limitNumLabels="0" zIndex="0" fontLimitPixelSize="0" maxNumLabels="2000" labelPerPart="0" obstacle="1" scaleMax="3000"/>
      <dd_properties>
        <Option type="Map">
          <Option type="QString" value="" name="name"/>
          <Option name="properties"/>
          <Option type="QString" value="collection" name="type"/>
        </Option>
      </dd_properties>
      <callout type="simple">
        <Option type="Map">
          <Option type="QString" value="pole_of_inaccessibility" name="anchorPoint"/>
          <Option type="int" value="0" name="blendMode"/>
          <Option type="Map" name="ddProperties">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
          <Option type="bool" value="false" name="drawToAllParts"/>
          <Option type="QString" value="0" name="enabled"/>
          <Option type="QString" value="point_on_exterior" name="labelAnchorPoint"/>
          <Option type="QString" value="&lt;symbol type=&quot;line&quot; clip_to_extent=&quot;1&quot; alpha=&quot;1&quot; is_animated=&quot;0&quot; force_rhr=&quot;0&quot; frame_rate=&quot;10&quot; name=&quot;symbol&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer class=&quot;SimpleLine&quot; pass=&quot;0&quot; enabled=&quot;1&quot; id=&quot;{e2e73dbb-bfcf-457b-8501-e974a735ee6d}&quot; locked=&quot;0&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;align_dash_pattern&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;square&quot; name=&quot;capstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;5;2&quot; name=&quot;customdash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;customdash_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;customdash_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;dash_pattern_offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;dash_pattern_offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;dash_pattern_offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;draw_inside_polygon&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;bevel&quot; name=&quot;joinstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.23529411764705882,0.23529411764705882,0.23529411764705882,1&quot; name=&quot;line_color&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;solid&quot; name=&quot;line_style&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0.3&quot; name=&quot;line_width&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;line_width_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;ring_filter&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_end&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_end_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_end_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_start&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_start_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_start_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;tweak_dash_pattern_on_corners&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;use_custom_dash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;width_map_unit_scale&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>" name="lineSymbol"/>
          <Option type="double" value="0" name="minLength"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="minLengthMapUnitScale"/>
          <Option type="QString" value="MM" name="minLengthUnit"/>
          <Option type="double" value="0" name="offsetFromAnchor"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="offsetFromAnchorMapUnitScale"/>
          <Option type="QString" value="MM" name="offsetFromAnchorUnit"/>
          <Option type="double" value="0" name="offsetFromLabel"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="offsetFromLabelMapUnitScale"/>
          <Option type="QString" value="MM" name="offsetFromLabelUnit"/>
        </Option>
      </callout>
    </settings>
  </labeling>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>' WHERE layername IN ('v_rpt_arcflow_sum');

-- update cat_feature_gully column double_geom default value
ALTER TABLE cat_feature_gully ALTER COLUMN double_geom SET DEFAULT '{"activated":false,"value":1}'::JSON;


ALTER TABLE sys_feature_class ADD CONSTRAINT sys_feature_cat_check CHECK
(((id)::text = ANY (ARRAY['CHAMBER'::text, 'CONDUIT'::text, 'CJOIN'::text, 'CONDUITLINK'::text, 'VLINK'::text, 'VCONNEC'::text, 'GINLET'::text, 'VGULLY'::text, 'JUNCTION'::text, 'MANHOLE'::text, 'NETELEMENT'::text, 'NETGULLY'::text, 'NETINIT'::text,
'OUTFALL'::text, 'SIPHON'::text, 'STORAGE'::text, 'VALVE'::text, 'VARC'::text, 'WACCEL'::text, 'WJUMP'::text, 'WWTP'::text,
'GENELEM'::text, 'FRELEM'::TEXT, 'SAMPLEPOINT'::text, 'NETSAMPLEPOINT'::text])));


ALTER TABLE arc DROP CONSTRAINT IF EXISTS arc_dma_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE arc DROP CONSTRAINT IF EXISTS arc_omunit_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE connec DROP CONSTRAINT IF EXISTS connec_dma_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE connec DROP CONSTRAINT IF EXISTS connec_omunit_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE gully DROP CONSTRAINT IF EXISTS gully_dma_id_fkey;
ALTER TABLE gully ADD CONSTRAINT gully_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE gully DROP CONSTRAINT IF EXISTS gully_minsector_id_fkey;
ALTER TABLE gully ADD CONSTRAINT gully_minsector_id_fkey FOREIGN KEY (minsector_id) REFERENCES minsector(minsector_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE gully DROP CONSTRAINT IF EXISTS gully_omunit_id_fkey;
ALTER TABLE gully ADD CONSTRAINT gully_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE link DROP CONSTRAINT IF EXISTS link_dma_id_fkey;
ALTER TABLE link ADD CONSTRAINT link_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE link DROP CONSTRAINT IF EXISTS link_omunit_id_fkey;
ALTER TABLE link ADD CONSTRAINT link_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE node DROP CONSTRAINT IF EXISTS node_dma_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE node DROP CONSTRAINT IF EXISTS node_omunit_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_omunit_id_fkey FOREIGN KEY (omunit_id) REFERENCES omunit(omunit_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE gully ADD CONSTRAINT gully_expl_fkey FOREIGN KEY (expl_id) REFERENCES exploitation(expl_id) ON UPDATE CASCADE ON DELETE RESTRICT;

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
        ALTER TABLE raingage DROP CONSTRAINT IF EXISTS raingage_muni_id;
        ALTER TABLE raingage ADD CONSTRAINT raingage_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;

        ALTER TABLE inp_subcatchment DROP CONSTRAINT IF EXISTS inp_subcatchment_muni_id;
        ALTER TABLE inp_subcatchment ADD CONSTRAINT inp_subcatchment_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
    ELSE
        ALTER TABLE raingage DROP CONSTRAINT IF EXISTS raingage_muni_id;
        ALTER TABLE raingage ADD CONSTRAINT raingage_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES ext_municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;

        ALTER TABLE inp_subcatchment DROP CONSTRAINT IF EXISTS inp_subcatchment_muni_id;
        ALTER TABLE inp_subcatchment ADD CONSTRAINT inp_subcatchment_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES ext_municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
    END IF;
END; $$;

CREATE TRIGGER gw_trg_edit_inp_dscenario_pattern INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_pattern
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('PATTERN');

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link('LINK');

CREATE TRIGGER gw_trg_edit_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');


CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_visibility ON gully
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_visibility', 'exploitation', 'expl_id');


DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON drainzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON drainzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_sector ON drainzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON dwfzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON dwfzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_sector ON dwfzone;

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON drainzone
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON dwfzone
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON omunit
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macroomunit
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
    ELSE
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON drainzone
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON dwfzone
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON omunit
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macroomunit
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
    END IF;

	CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON drainzone
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON drainzone
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

	CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON dwfzone
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON dwfzone
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON omunit
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON omunit
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON macroomunit
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON macroomunit
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

END; $$;


CREATE TRIGGER gw_trg_update_element_mapzones AFTER INSERT ON element_x_gully
FOR EACH ROW EXECUTE FUNCTION gw_trg_update_element_mapzones('element_x_gully');

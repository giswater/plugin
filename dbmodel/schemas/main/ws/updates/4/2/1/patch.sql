/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"temp_demand", "column":"feature_id", "dataType":"text"}}$$);

drop table archived_psector_link;
 
CREATE TABLE archived_psector_link (
    id serial4 NOT NULL,
	psector_id int4 NOT NULL,
	psector_state int2 NOT NULL,
	doable bool NOT NULL,
	audit_tstamp timestamp DEFAULT now() NULL,
	audit_user text DEFAULT CURRENT_USER NULL,
	action varchar(16) NOT NULL,
 	link_id int4 NOT NULL,
	code text NULL,
	sys_code text NULL,
	top_elev1 float8 NULL,
	depth1 numeric(12, 4) NULL,
	exit_id int4 NULL,
	exit_type varchar(16) NULL,
	top_elev2 float8 NULL,
	depth2 numeric(12, 4) NULL,
	feature_type varchar(16) NULL,
	feature_id int4 NULL,
	linkcat_id varchar(30) NOT NULL,
	state int2 NOT NULL,
	state_type int2 NOT NULL,
	expl_id int4 NOT NULL,
	muni_id int4 NULL,
	sector_id int4 NULL,
	supplyzone_id int4 NULL,
	presszone_id int4 NULL,
	dma_id int4 NULL,
	dqa_id int4 NULL,
	omzone_id int4 NULL,
	minsector_id int4 NULL,
	location_type varchar(50) NULL,
	fluid_type varchar(50) NULL,
	custom_length numeric(12, 2) NULL,
	staticpressure1 numeric(12, 3) NULL,
	staticpressure2 numeric(12, 3) NULL,
	annotation text NULL,
	observ text NULL,
	"comment" text NULL,
	descript varchar(254) NULL,
	link varchar(512) NULL,
	num_value numeric(12, 3) NULL,
	workcat_id varchar(255) NULL,
	workcat_id_end varchar(255) NULL,
	builtdate date NULL,
	enddate date NULL,
	brand_id varchar(50) NULL,
	model_id varchar(50) NULL,
	verified int2 NULL,
	uncertain bool NULL,
	userdefined_geom bool NULL,
	datasource int4 NULL,
	is_operative bool NULL,
	lock_level int4 NULL,
	expl_visibility _int2 NULL,
	created_at timestamptz DEFAULT now() NULL,
	created_by varchar(50) DEFAULT CURRENT_USER NULL,
	updated_at timestamptz NULL,
	updated_by varchar(50) NULL,
	the_geom public.geometry(linestring, SRID_VALUE) NULL,
	CONSTRAINT archived_psector_link_pkey PRIMARY KEY (link_id)
);
CREATE INDEX archived_psector_link_exit_id ON link USING btree (exit_id);
CREATE INDEX archived_psector_link_expl_visibility_idx ON archived_psector_link USING btree (expl_visibility);
CREATE INDEX larchived_psector_ink_feature_id ON archived_psector_link USING btree (feature_id);
CREATE INDEX archived_psector_link_index ON archived_psector_link USING gist (the_geom);
CREATE INDEX archived_psector_link_muni ON archived_psector_link USING btree (muni_id);

ALTER TABLE macrodma ALTER COLUMN expl_id DROP NOT NULL;
ALTER TABLE macroomzone ALTER COLUMN expl_id DROP NOT NULL;
ALTER TABLE macrodqa ALTER COLUMN expl_id DROP NOT NULL;

DROP RULE IF EXISTS dma_conflict ON dma;
DROP RULE IF EXISTS dma_undefined ON dma;
UPDATE dma SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
ALTER TABLE dma ALTER COLUMN expl_id SET NOT NULL;

DROP RULE IF EXISTS dqa_conflict ON dqa;
DROP RULE IF EXISTS dqa_undefined ON dqa;
UPDATE dqa SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
ALTER TABLE dqa ALTER COLUMN expl_id SET NOT NULL;

DROP RULE IF EXISTS omzone_conflict ON omzone;
DROP RULE IF EXISTS omzone_undefined ON omzone;
UPDATE omzone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
ALTER TABLE omzone ALTER COLUMN expl_id SET NOT NULL;

DROP RULE IF EXISTS presszone_conflict ON presszone;
DROP RULE IF EXISTS presszone_undefined ON presszone;
UPDATE presszone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
ALTER TABLE presszone ALTER COLUMN expl_id SET NOT NULL;


SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"omzone", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"omzone", "column":"graphconfig", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"omzone", "column":"stylesheet", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"omzone", "column":"sector_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"supplyzone", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"supplyzone", "column":"sector_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"supplyzone", "column":"muni_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"dqa", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"dma", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"presszone", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"sector", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrosector", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrosector", "column":"expl_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrosector", "column":"muni_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrosector", "column":"stylesheet", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrosector", "column":"link", "dataType":"text", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macroomzone", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macroomzone", "column":"expl_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macroomzone", "column":"sector_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macroomzone", "column":"muni_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macroomzone", "column":"stylesheet", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macroomzone", "column":"link", "dataType":"text", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodma", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodma", "column":"sector_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodma", "column":"muni_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodma", "column":"stylesheet", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodma", "column":"link", "dataType":"text", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodqa", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodqa", "column":"sector_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodqa", "column":"muni_id", "dataType":"int4[]", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodqa", "column":"stylesheet", "dataType":"json", "isUtils":"False"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"macrodqa", "column":"link", "dataType":"text", "isUtils":"False"}}$$);

DROP VIEW IF EXISTS v_ui_rpt_cat_result;
CREATE OR REPLACE VIEW v_ui_rpt_cat_result
AS SELECT DISTINCT ON (rpt_cat_result.result_id) rpt_cat_result.result_id,
    rpt_cat_result.expl_id,
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
   FROM selector_expl s,
    rpt_cat_result
     LEFT JOIN inp_typevalue t1 ON rpt_cat_result.status::text = t1.id::text
     LEFT JOIN inp_typevalue t2 ON rpt_cat_result.network_type = t2.id::text
  WHERE t1.typevalue::text = 'inp_result_status'::text AND t2.typevalue::text = 'inp_options_networkmode'::text AND ((s.expl_id = ANY (rpt_cat_result.expl_id)) AND s.cur_user = CURRENT_USER OR rpt_cat_result.expl_id = ARRAY[NULL::integer]);

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
     JOIN ve_connec c ON c.connec_id = n.feature_id;


CREATE OR REPLACE VIEW ve_epa_link
AS SELECT link.link_id,
	  inp_connec.minorloss,
	  inp_connec.status,
	  cat_link.matcat_id,
	  r.roughness AS cat_roughness,
	  inp_connec.custom_roughness,
	  cat_link.dint,
	  inp_connec.custom_dint,
	  inp_connec.custom_length,
	  v_rpt_arc_stats.result_id,
    v_rpt_arc_stats.flow_max,
    v_rpt_arc_stats.flow_min,
    v_rpt_arc_stats.flow_avg,
    v_rpt_arc_stats.vel_max,
    v_rpt_arc_stats.vel_min,
    v_rpt_arc_stats.vel_avg,
    v_rpt_arc_stats.headloss_max,
    v_rpt_arc_stats.headloss_min,
    v_rpt_arc_stats.setting_max,
    v_rpt_arc_stats.setting_min,
    v_rpt_arc_stats.reaction_max,
    v_rpt_arc_stats.reaction_min,
    v_rpt_arc_stats.ffactor_max,
    v_rpt_arc_stats.ffactor_min,
    v_rpt_arc_stats.tot_headloss_max,
    v_rpt_arc_stats.tot_headloss_min
  FROM inp_connec
   	 JOIN link ON link.feature_id = inp_connec.connec_id
     LEFT JOIN v_rpt_arc_stats ON concat('CO', inp_connec.connec_id)::text = v_rpt_arc_stats.arc_id::text
     LEFT JOIN cat_link ON cat_link.id::text = link.linkcat_id::TEXT
     LEFT JOIN cat_mat_roughness r ON cat_link.matcat_id::text = r.matcat_id::text;

DROP VIEW IF EXISTS ve_epa_connec;
CREATE OR REPLACE VIEW ve_epa_connec
AS SELECT inp_connec.connec_id,
    inp_connec.demand,
    inp_connec.pattern_id,
    inp_connec.peak_factor,
    inp_connec.emitter_coeff,
    inp_connec.init_quality,
    inp_connec.source_type,
    inp_connec.source_quality,
    inp_connec.source_pattern_id,
    v_rpt_node_stats.result_id,
    v_rpt_node_stats.demand_max AS demandmax,
    v_rpt_node_stats.demand_min AS demandmin,
    v_rpt_node_stats.demand_avg AS demandavg,
    v_rpt_node_stats.head_max AS headmax,
    v_rpt_node_stats.head_min AS headmin,
    v_rpt_node_stats.head_avg AS headavg,
    v_rpt_node_stats.press_max AS pressmax,
    v_rpt_node_stats.press_min AS pressmin,
    v_rpt_node_stats.press_avg AS pressavg,
    v_rpt_node_stats.quality_max AS qualmax,
    v_rpt_node_stats.quality_min AS qualmin,
    v_rpt_node_stats.quality_avg AS qualavg
   FROM inp_connec
     LEFT JOIN v_rpt_node_stats ON inp_connec.connec_id::text = v_rpt_node_stats.node_id::text;

-- Refactor mapzones
DROP VIEW IF EXISTS v_ui_omzone;
DROP VIEW IF EXISTS ve_omzone;
DROP VIEW IF EXISTS v_ui_sector;
DROP VIEW IF EXISTS ve_sector;
DROP VIEW IF EXISTS v_ui_dma;
DROP VIEW IF EXISTS ve_dma;
DROP VIEW IF EXISTS v_ui_dqa;
DROP VIEW IF EXISTS ve_dqa;
DROP VIEW IF EXISTS v_ui_presszone;
DROP VIEW IF EXISTS ve_presszone;
DROP VIEW IF EXISTS v_ui_supplyzone;
DROP VIEW IF EXISTS ve_supplyzone;
DROP VIEW IF EXISTS v_ui_macrosector;
DROP VIEW IF EXISTS ve_macrosector;
DROP VIEW IF EXISTS v_ui_macroomzone;
DROP VIEW IF EXISTS ve_macroomzone;
DROP VIEW IF EXISTS v_ui_macrodma;
DROP VIEW IF EXISTS ve_macrodma;
DROP VIEW IF EXISTS v_ui_macrodqa;
DROP VIEW IF EXISTS ve_macrodqa;

CREATE VIEW v_ui_omzone
AS SELECT DISTINCT ON (o.omzone_id) o.omzone_id,
    o.code,
    o.name,
    o.descript,
    o.active,
    et.idval AS omzone_type,
    mo.name AS macroomzone,
    o.expl_id,
    o.sector_id,
    o.muni_id,
    o.graphconfig,
    o.stylesheet,
    o.lock_level,
    o.link,
    o.addparam,
    o.created_at,
    o.created_by,
    o.updated_at,
    o.updated_by
   FROM selector_expl se, omzone o
     LEFT JOIN macroomzone mo USING (macroomzone_id)
     LEFT JOIN edit_typevalue et ON et.id::text = o.omzone_type::text AND et.typevalue::text = 'omzone_type'::text
  WHERE se.expl_id = ANY(o.expl_id) AND se.cur_user = CURRENT_USER AND o.omzone_id > 0
  ORDER BY o.omzone_id;

CREATE VIEW ve_omzone
AS SELECT DISTINCT ON (o.omzone_id) o.omzone_id,
    o.code,
    o.name,
    o.descript,
    o.active,
    o.omzone_type,
    o.macroomzone_id,
    o.expl_id,
    o.sector_id,
    o.muni_id,
    o.graphconfig,
    o.stylesheet,
    o.lock_level,
    o.link,
    o.addparam,
    o.created_at,
    o.created_by,
    o.updated_at,
    o.updated_by,
    o.the_geom
   FROM selector_expl se, omzone o
  WHERE se.expl_id = ANY(o.expl_id) AND se.cur_user = CURRENT_USER AND o.omzone_id > 0
  ORDER BY o.omzone_id;

CREATE OR REPLACE VIEW v_ui_sector
AS SELECT DISTINCT ON (s.sector_id) s.sector_id,
    s.code,
    s.name,
    s.descript,
    s.active,
    et.idval AS sector_type,
    ms.name AS macrosector,
    s.expl_id,
    s.muni_id,
    s.avg_press,
    s.pattern_id,
    s.graphconfig::text,
    s.stylesheet::text,
    s.lock_level,
    s.link,
    s.addparam::text,
    s.created_at,
    s.created_by,
    s.updated_at,
    s.updated_by
   FROM selector_sector ss, sector s
     LEFT JOIN macrosector ms USING (macrosector_id)
     LEFT JOIN edit_typevalue et ON et.id::text = s.sector_type::text AND et.typevalue::text = 'sector_type'::text
  WHERE ss.sector_id = s.sector_id AND ss.cur_user = CURRENT_USER AND s.sector_id > 0
  ORDER BY s.sector_id;

CREATE OR REPLACE VIEW ve_sector
AS SELECT DISTINCT ON (s.sector_id) s.sector_id,
    s.code,
    s.name,
    s.descript,
    s.active,
    s.sector_type,
    s.macrosector_id,
    s.expl_id,
    s.muni_id,
    s.avg_press,
    s.pattern_id,
    s.graphconfig::text,
    s.stylesheet::text,
    s.lock_level,
    s.link,
    s.addparam::text,
    s.created_at,
    s.created_by,
    s.updated_at,
    s.updated_by,
    s.the_geom
  FROM selector_sector ss, sector s
  WHERE ss.sector_id = s.sector_id AND ss.cur_user = CURRENT_USER AND s.sector_id > 0
  ORDER BY s.sector_id;


CREATE OR REPLACE VIEW v_ui_dma
AS SELECT DISTINCT ON (d.dma_id) d.dma_id,
    d.code,
    d.name,
    d.descript,
    d.active,
    et.idval AS dma_type,
    md.name AS macrodma,
    d.expl_id,
    d.sector_id,
    d.muni_id,
    d.avg_press,
    d.pattern_id,
    d.effc,
    d.graphconfig::text,
    d.stylesheet::text,
    d.lock_level,
    d.link,
    d.addparam::text,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by
   FROM selector_expl se, dma d
     LEFT JOIN macrodma md USING (macrodma_id)
     LEFT JOIN edit_typevalue et ON et.id::text = d.dma_type::text AND et.typevalue::text = 'dma_type'::text
  WHERE se.expl_id = ANY(d.expl_id) AND se.cur_user = CURRENT_USER AND d.dma_id > 0
  ORDER BY d.dma_id;

CREATE OR REPLACE VIEW ve_dma
AS SELECT DISTINCT ON (d.dma_id) d.dma_id,
    d.code,
    d.name,
    d.descript,
    d.active,
    d.dma_type,
    d.macrodma_id,
    d.expl_id,
    d.sector_id,
    d.muni_id,
    d.avg_press,
    d.pattern_id,
    d.effc,
    d.graphconfig::text,
    d.stylesheet::text,
    d.lock_level,
    d.link,
    d.addparam::text,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by,
    d.the_geom
   FROM selector_expl se, dma d
  WHERE se.expl_id = ANY(d.expl_id) AND se.cur_user = CURRENT_USER AND d.dma_id > 0
  ORDER BY d.dma_id;

CREATE OR REPLACE VIEW v_ui_dqa
AS SELECT DISTINCT ON (d.dqa_id) d.dqa_id,
    d.code,
    d.name,
    d.descript,
    d.active,
    et.idval AS dqa_type,
    md.name AS macrodqa,
    d.expl_id,
    d.sector_id,
    d.muni_id,
    d.avg_press,
    d.pattern_id,
    d.graphconfig::text,
    d.stylesheet::text,
    d.lock_level,
    d.link,
    d.addparam::text,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by
   FROM selector_expl se, dqa d
     LEFT JOIN macrodqa md USING (macrodqa_id)
     LEFT JOIN edit_typevalue et ON et.id::text = d.dqa_type::text AND et.typevalue::text = 'dqa_type'::text
  WHERE se.expl_id = ANY(d.expl_id) AND se.cur_user = CURRENT_USER AND d.dqa_id > 0
  ORDER BY d.dqa_id;

CREATE OR REPLACE VIEW ve_dqa
AS SELECT DISTINCT ON (d.dqa_id) d.dqa_id,
    d.code,
    d.name,
    d.descript,
    d.active,
    d.dqa_type,
    d.macrodqa_id,
    d.expl_id,
    d.sector_id,
    d.muni_id,
    d.avg_press,
    d.pattern_id,
    d.graphconfig::text,
    d.stylesheet::text,
    d.lock_level,
    d.link,
    d.addparam::text,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by,
    d.the_geom
   FROM selector_expl se, dqa d
  WHERE se.expl_id = ANY(d.expl_id) AND se.cur_user = CURRENT_USER AND d.dqa_id > 0
  ORDER BY d.dqa_id;

CREATE OR REPLACE VIEW v_ui_presszone
AS SELECT DISTINCT ON (p.presszone_id) p.presszone_id,
    p.code,
    p.name,
    p.descript,
    p.active,
    et.idval AS presszone_type,
    p.expl_id,
    p.sector_id,
    p.muni_id,
    p.avg_press,
    p.head,
    p.graphconfig::text,
    p.stylesheet::text,
    p.lock_level,
    p.link,
    p.addparam::text,
    p.created_at,
    p.created_by,
    p.updated_at,
    p.updated_by
   FROM selector_expl se, presszone p
     LEFT JOIN edit_typevalue et ON et.id::text = p.presszone_type::text AND et.typevalue::text = 'presszone_type'::text
  WHERE se.expl_id = ANY(p.expl_id) AND se.cur_user = CURRENT_USER AND p.presszone_id > 0
  ORDER BY p.presszone_id;

CREATE OR REPLACE VIEW ve_presszone
AS SELECT DISTINCT ON (p.presszone_id) p.presszone_id,
    p.code,
    p.name,
    p.descript,
    p.active,
    p.presszone_type,
    p.expl_id,
    p.sector_id,
    p.muni_id,
    p.avg_press,
    p.head,
    p.graphconfig::text,
    p.stylesheet::text,
    p.lock_level,
    p.link,
    p.addparam::text,
    p.created_at,
    p.created_by,
    p.updated_at,
    p.updated_by,
    p.the_geom
   FROM selector_expl se, presszone p
  WHERE se.expl_id = ANY(p.expl_id) AND se.cur_user = CURRENT_USER AND p.presszone_id > 0
  ORDER BY p.presszone_id;

CREATE OR REPLACE VIEW v_ui_supplyzone
AS SELECT DISTINCT ON (supplyzone_id) supplyzone_id,
    d.code,
    d.name,
    d.descript,
    d.active,
    et.idval AS supplyzone_type,
    d.expl_id,
    d.sector_id,
    d.muni_id,
    d.avg_press,
    d.pattern_id,
    d.graphconfig::text,
    d.stylesheet::text,
    d.lock_level,
    d.link,
    d.addparam::text,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by
   FROM supplyzone d
     LEFT JOIN edit_typevalue et ON et.id::text = d.supplyzone_type::text AND et.typevalue::text = 'supplyzone_type'::text
  WHERE supplyzone_id > 0
  ORDER BY supplyzone_id;

CREATE OR REPLACE VIEW ve_supplyzone
AS SELECT DISTINCT ON (supplyzone_id) supplyzone_id,
    d.code,
    d.name,
    d.descript,
    d.active,
    d.supplyzone_type,
    d.expl_id,
    d.sector_id,
    d.muni_id,
    d.avg_press,
    d.pattern_id,
    d.graphconfig::text,
    d.stylesheet::text,
    d.lock_level,
    d.link,
    d.addparam::text,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by,
    d.the_geom
   FROM supplyzone d
  WHERE supplyzone_id > 0
  ORDER BY supplyzone_id;

CREATE OR REPLACE VIEW v_ui_macroomzone
AS SELECT DISTINCT ON (macroomzone_id) macroomzone_id,
    code,
    name,
    descript,
    active,
    expl_id,
    sector_id,
    muni_id,
    stylesheet::text,
    lock_level,
    link,
    addparam::text,
    created_at,
    created_by,
    updated_at,
    updated_by
   FROM macroomzone m
  WHERE macroomzone_id > 0
  ORDER BY macroomzone_id;

CREATE OR REPLACE VIEW ve_macroomzone
AS SELECT DISTINCT ON (macroomzone_id) macroomzone_id,
    code,
    name,
    descript,
    active,
    expl_id,
    sector_id,
    muni_id,
    stylesheet::text,
    lock_level,
    link,
    addparam::text,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom
   FROM macroomzone m
  WHERE macroomzone_id > 0
  ORDER BY macroomzone_id;


CREATE OR REPLACE VIEW v_ui_macrodma
AS SELECT DISTINCT ON (m.macrodma_id) m.macrodma_id,
    m.code,
    m.name,
    m.descript,
    m.active,
    m.expl_id,  
    m.sector_id,
    m.muni_id,
    m.stylesheet::text,
    m.lock_level,
    m.link,
    m.addparam::text,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by
   FROM macrodma m
  WHERE m.macrodma_id > 0
  ORDER BY m.macrodma_id;

CREATE OR REPLACE VIEW ve_macrodma
AS SELECT DISTINCT ON (m.macrodma_id) m.macrodma_id,
    m.code,
    m.name,
    m.descript,
    m.active,
    m.expl_id,  
    m.sector_id,
    m.muni_id,
    m.stylesheet::text,
    m.lock_level,
    m.link,
    m.addparam::text,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by,
    m.the_geom
   FROM macrodma m
  WHERE m.macrodma_id > 0
  ORDER BY m.macrodma_id;

CREATE OR REPLACE VIEW v_ui_macrodqa
AS SELECT DISTINCT ON (m.macrodqa_id) m.macrodqa_id,
    m.code,
    m.name,
    m.descript,
    m.active,
    m.expl_id,
    m.sector_id,
    m.muni_id,
    m.stylesheet::text,
    m.lock_level,
    m.link,
    m.addparam::text,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by
   FROM selector_expl se,
    macrodqa m
  WHERE m.macrodqa_id > 0
  ORDER BY m.macrodqa_id;

CREATE OR REPLACE VIEW ve_macrodqa
AS SELECT DISTINCT ON (m.macrodqa_id) m.macrodqa_id,
    m.code,
    m.name,
    m.descript,
    m.active,
    m.expl_id,
    m.sector_id,
    m.muni_id,
    m.stylesheet::text,
    m.lock_level,
    m.link,
    m.addparam::text,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by,
    m.the_geom
   FROM selector_expl se,
    macrodqa m
  WHERE m.macrodqa_id > 0
  ORDER BY m.macrodqa_id;

CREATE OR REPLACE VIEW v_ui_macrosector
AS SELECT DISTINCT ON (m.macrosector_id) m.macrosector_id,
    m.code,
    m.name,
    m.descript,
    m.active,
    m.expl_id,
    m.muni_id,
    m.stylesheet::text,
    m.lock_level,
    m.link,
    m.addparam::text,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by
   FROM selector_sector ss,
    macrosector m
  WHERE m.macrosector_id > 0
  ORDER BY m.macrosector_id;

CREATE OR REPLACE VIEW ve_macrosector
AS SELECT DISTINCT ON (m.macrosector_id) m.macrosector_id,
    m.code,
    m.name,
    m.descript,
    m.active,
    m.expl_id,
    m.muni_id,
    m.stylesheet::text,
    m.lock_level,
    m.link,
    m.addparam::text,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by,
    m.the_geom
   FROM selector_sector ss,
    macrosector m
  WHERE m.macrosector_id > 0
  ORDER BY m.macrosector_id;

UPDATE sys_feature_class SET epa_default = 'UNDEFINED' WHERE type IN ('ELEMENT','CONNEC');

UPDATE sys_function SET function_name = 'gw_fct_pg2epa_flwreg2arc', descript = 'This functions transform flwreg elements to arcs.' WHERE id = 2318;

INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES('epa_toolbar', 'utils', 'v_ui_rpt_cat_result', 'dma_id', (SELECT MAX(columnindex) FROM config_form_tableview WHERE location_type = 'epa_toolbar' AND project_type = 'utils' AND objectname = 'v_ui_rpt_cat_result'), true, NULL, 'dma_id', NULL, NULL);


DELETE FROM config_form_fields WHERE formname ILIKE 've_element_%';
DO $$
DECLARE
  rec record;
  v_view text;
BEGIN
  FOR rec IN (SELECT * FROM cat_feature_element WHERE id NOT IN ('EPUMP', 'EORIFICE', 'EWEIR', 'EOUTLET', 'EVALVE', 'EMETER'))
  LOOP
    v_view := concat('ve_element_', lower(REPLACE(REC.id, ' ', '_')));

    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID:','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','state','lyt_bot_1',2,'integer','combo','State:','State:',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','state_type','lyt_bot_1',3,'integer','combo','State type:','State type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','code','lyt_data_1',1,'string','text','Code:','Code:',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','num_elements','lyt_data_1',2,'integer','text','Element number:','Element number',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','comment','lyt_data_1',3,'string','text','Comment:','Comment',false,false,true,false,'{"setMultiline":true}'::json,true);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','function_type','lyt_data_1',4,'string','combo','Function type:','Function type',false,false,true,false,concat('SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''E',rec.id,''' = ANY(featurecat_id::text[])'),true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','category_type','lyt_data_1',5,'string','combo','Category type:','Category type',false,false,true,false,concat('SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''E',rec.id,''' = ANY(featurecat_id::text[])'),true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','location_type','lyt_data_1',6,'string','combo','Location type:','Location type',false,false,true,false,concat('SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''E',rec.id,''' = ANY(featurecat_id::text[])'),true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
        VALUES (v_view,'form_feature','tab_data','workcat_id','lyt_data_1',7,'string','typeahead','Workcat:','Workcat',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','workcat_id_end','lyt_data_1',8,'string','typeahead','Workcat ID end:','Workcat ID end','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','builtdate','lyt_data_1',9,'date','datetime','Builtdate:','Builtdate:',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','enddate','lyt_data_1',10,'date','datetime','Enddate:','Enddate',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','ownercat_id','lyt_data_1',11,'string','combo','Owner:','ownercat_id - Related to the catalog of owners (cat_owner)',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,hidden)
        VALUES (v_view,'form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand:','brand_id',false,false,true,false,concat('SELECT id, id as idval FROM cat_brand WHERE ''E',rec.id,''' = ANY(featurecat_id::text[])'),false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,hidden)
        VALUES (v_view,'form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model:','model_id',false,false,true,false,concat('SELECT id, id as idval FROM cat_brand_model WHERE ''E',rec.id,''' = ANY(featurecat_id::text[])'),false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','rotation','lyt_data_1',14,'double','text','Rotation:','Rotation:',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','top_elev','lyt_data_1',15,'double','text','Top elevation:','top_elev - Elevation of the node in ft or m.',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','expl_id','lyt_data_2',1,'integer','combo','Exploitation:','Exploitation',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
        VALUES (v_view,'form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality id:','muni_id - Identifier of the municipality',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','observ','lyt_data_3',2,'string','text','Observation:','Observation',false,false,true,false,'{"setMultiline":true}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_data','elementcat_id','lyt_top_1',1,'string','combo','Catalog:','Catalog',true,false,true,false,concat('SELECT id, id as idval FROM cat_element WHERE element_type = ''E',rec.id,''''),true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
        VALUES (v_view,'form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
        VALUES (v_view,'form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
    "icon": "111"
    }'::json,'{
    "saveValue": false
    }'::json,'{
    "functionName": "insert_feature",
    "parameters": {
        "targetwidget": "tab_features_feature_id"
    }
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
        VALUES (v_view,'form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
    "icon": "112"
    }'::json,'{
    "saveValue": false
    }'::json,'{
    "functionName": "delete_object",
    "parameters": {
        "columnfind": "element_id",
        "targetwidget": "tab_features_tbl_element",
        "sourceview": "element"
    }
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
        VALUES (v_view,'form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
    "icon": "137"
    }'::json,'{
    "saveValue": false
    }'::json,'{
    "functionName": "selection_init"
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
        VALUES (v_view,'form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
    "icon": "178"
    }'::json,'{
    "saveValue": false
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
        VALUES (v_view,'form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview',':','',false,false,false,false,false,'{
    "saveValue": false,
    "tableUpsert": "v_ui_element_x_arc",
    "featureType": "arc"
    }'::json,'tbl_element_x_arc',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
        VALUES (v_view,'form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview',':','',false,false,false,false,false,'{
    "saveValue": false,
    "tableUpsert": "v_ui_element_x_connec",
    "featureType": "connec"
    }'::json,'tbl_element_x_connec',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
        VALUES (v_view,'form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview',':','',false,false,false,false,false,'{
    "saveValue": false,
    "tableUpsert": "v_ui_element_x_link",
    "featureType": "link"
    }'::json,'tbl_element_x_link',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
        VALUES (v_view,'form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview',':','',false,false,false,false,false,'{
    "saveValue": false,
    "tableUpsert": "v_ui_element_x_node",
    "featureType": "node"
    }'::json,'tbl_element_x_node',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (v_view,'form_feature','tab_documents','date_from','lyt_document_1',1,'date','datetime','Date from:','Date from:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":">="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,1);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (v_view,'form_feature','tab_documents','date_to','lyt_document_1',2,'date','datetime','Date to:','Date to:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":"<="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,2);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_isnullvalue,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (v_view,'form_feature','tab_documents','doc_type','lyt_document_1',3,'string','combo','Doc type:','Doc type:',false,false,true,false,true,'SELECT id as id, idval as idval FROM edit_typevalue WHERE typevalue = ''doc_type''',true,'{"labelPosition": "top"}'::json,'{"functionName": "filter_table", "parameters":{}}'::json,'tbl_doc_x_element',false,3);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,widgetfunction,hidden)
      VALUES (v_view,'form_feature','tab_documents','doc_name','lyt_document_2',0,'string','typeahead','Doc id:','Doc id:',false,false,true,false,false,'SELECT name as id, name as idval FROM doc WHERE name IS NOT NULL','{"saveValue": false, "filterSign":"ILIKE"}'::json,'{"functionName": "filter_table"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (v_view,'form_feature','tab_documents','btn_doc_insert','lyt_document_2',2,'button','Insert document',false,false,true,false,false,'{"icon":"113"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
      "functionName": "add_object",
      "parameters": {
        "sourcewidget": "tab_documents_doc_name",
        "targetwidget": "tab_documents_tbl_documents",
        "sourceview": "doc"
      }
    }'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (v_view,'form_feature','tab_documents','btn_doc_delete','lyt_document_2',3,'button','Delete document',false,false,true,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Delete document"}'::json,'{"functionName": "delete_object", "parameters": {"columnfind": "doc_id", "targetwidget": "tab_documents_tbl_documents", "sourceview": "doc"}}'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (v_view,'form_feature','tab_documents','btn_doc_new','lyt_document_2',4,'button','New document',false,false,true,false,false,'{"icon":"143"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
      "functionName": "manage_document",
      "parameters": {
        "sourcewidget": "tab_documents_doc_name",
        "targetwidget": "tab_documents_tbl_documents",
        "sourceview": "doc"
      }
    }'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,hidden)
      VALUES (v_view,'form_feature','tab_documents','hspacer_document_1','lyt_document_2',10,'hspacer',false,false,true,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (v_view,'form_feature','tab_documents','open_doc','lyt_document_2',11,'button','Open document',false,false,true,false,false,'{"icon":"147"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Open document"}'::json,'{
      "functionName": "open_selected_path",
      "parameters": {
        "columnfind": "path",
        "targetwidget": "tab_documents_tbl_documents",
        "sourceview": "doc"
      }
    }'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (v_view,'form_feature','tab_documents','tbl_documents','lyt_document_3',1,'tableview',false,false,false,false,false,'{"saveValue": false}'::json,'{
      "functionName": "open_selected_path",
      "parameters": {
        "targetwidget": "tab_documents_tbl_documents",
        "columnfind": "path"
      }
    }'::json,'tbl_doc_x_element',false,4);
      END LOOP;
END $$;

-- FRELEM
DO $$
DECLARE
  rec record;
  v_view text;
BEGIN
  FOR rec IN SELECT val AS v_view,  elem as id FROM (VALUES ('ve_element_epump', 'EPUMP'), ('ve_element_evalve', 'EVALVE'), ('ve_element_emeter', 'EMETER')) AS t(val, elem)
  LOOP
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID:','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','state','lyt_bot_1',2,'integer','combo','State:','State:',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','state_type','lyt_bot_1',3,'integer','combo','State type:','State type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','code','lyt_data_1',2,'string','text','Code:','Code:',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','num_elements','lyt_data_1',3,'integer','text','Element number:','Element number',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','comment','lyt_data_1',4,'string','text','Comment:','Comment',false,false,true,false,'{"setMultiline":true}'::json,true);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','function_type','lyt_data_1',5,'string','combo','Function type:','Function type',false,false,true,false,concat('SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''',rec.id,''' = ANY(featurecat_id::text[])'),true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','category_type','lyt_data_1',6,'string','combo','Category type:','Category type',false,false,true,false,concat('SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''',rec.id,''' = ANY(featurecat_id::text[])'),true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','location_type','lyt_data_1',7,'string','combo','Location type:','Location type',false,false,true,false,concat('SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''',rec.id,''' = ANY(featurecat_id::text[])'),true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','workcat_id','lyt_data_1',8,'string','typeahead','Workcat:','Workcat',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','workcat_id_end','lyt_data_1',9,'string','typeahead','Workcat ID end:','Workcat ID end','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','builtdate','lyt_data_1',10,'date','datetime','Builtdate:','Builtdate:',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','enddate','lyt_data_1',11,'date','datetime','Enddate:','Enddate',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','ownercat_id','lyt_data_1',12,'string','combo','Owner:','ownercat_id - Related to the catalog of owners (cat_owner)',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
      VALUES (rec.v_view,'form_feature','tab_data','brand_id','lyt_data_1',13,'text','combo','Brand:','brand_id',false,false,true,false,concat('SELECT id, id as idval FROM cat_brand WHERE ''',rec.id,''' = ANY(featurecat_id::text[])'));
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
      VALUES (rec.v_view,'form_feature','tab_data','model_id','lyt_data_1',14,'text','combo','Model:','model_id',false,false,true,false,concat('SELECT id, id as idval FROM cat_brand_model WHERE ''',rec.id,''' = ANY(featurecat_id::text[])'));
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','rotation','lyt_data_1',15,'double','text','Rotation:','Rotation:',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','top_elev','lyt_data_1',16,'double','text','Top elevation:','top_elev - Elevation of the node in ft or m.',false,false,true,false,'{"setMultiline":false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','flwreg_length','lyt_data_2',1,'double','text','Flwreg length:','flwreg_length',true,false,true,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','node_id','lyt_data_1',1,'integer','text','Node id:','node_id',false,false,false,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','to_arc','lyt_data_2',2,'integer','text','To arc:','to_arc',true,false,true,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','expl_id','lyt_data_2',3,'integer','combo','Exploitation:','Exploitation',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality id:','muni_id - Identifier of the municipality',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','observ','lyt_data_3',2,'string','text','Observation:','Observation',false,false,true,false,'{"setMultiline":true}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_data','elementcat_id','lyt_top_1',1,'string','combo','Catalog:','Catalog',true,false,true,false,concat('SELECT id, id as idval FROM cat_element WHERE element_type = ''',rec.id,''''),true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
        VALUES (rec.v_view,'form_feature','tab_data','epa_type','lyt_top_1',3,'string','combo','EPA Type:','EPA Type',false,false,true,true,'SELECT id, id as idval FROM sys_feature_epa_type WHERE active AND feature_type = ''ELEMENT''','{"setMultiline": false, "labelPosition": "top"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (rec.v_view,'form_feature','tab_documents','date_from','lyt_document_1',1,'date','datetime','Date from:','Date from:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":">="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,1);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (rec.v_view,'form_feature','tab_documents','date_to','lyt_document_1',2,'date','datetime','Date to:','Date to:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":"<="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,2);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_isnullvalue,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (rec.v_view,'form_feature','tab_documents','doc_type','lyt_document_1',3,'string','combo','Doc type:','Doc type:',false,false,true,false,true,'SELECT id as id, idval as idval FROM edit_typevalue WHERE typevalue = ''doc_type''',true,'{"labelPosition": "top"}'::json,'{"functionName": "filter_table", "parameters":{}}'::json,'tbl_doc_x_element',false,3);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,widgetfunction,hidden)
      VALUES (rec.v_view,'form_feature','tab_documents','doc_name','lyt_document_2',0,'string','typeahead','Doc id:','Doc id:',false,false,true,false,false,'SELECT name as id, name as idval FROM doc WHERE name IS NOT NULL','{"saveValue": false, "filterSign":"ILIKE"}'::json,'{"functionName": "filter_table"}'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_documents','btn_doc_insert','lyt_document_2',2,'button','Insert document',false,false,true,false,false,'{"icon":"113"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
      "functionName": "add_object",
      "parameters": {
        "sourcewidget": "tab_documents_doc_name",
        "targetwidget": "tab_documents_tbl_documents",
        "sourceview": "doc"
      }
    }'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_documents','btn_doc_delete','lyt_document_2',3,'button','Delete document',false,false,true,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Delete document"}'::json,'{"functionName": "delete_object", "parameters": {"columnfind": "doc_id", "targetwidget": "tab_documents_tbl_documents", "sourceview": "doc"}}'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_documents','btn_doc_new','lyt_document_2',4,'button','New document',false,false,true,false,false,'{"icon":"143"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
      "functionName": "manage_document",
      "parameters": {
        "sourcewidget": "tab_documents_doc_name",
        "targetwidget": "tab_documents_tbl_documents",
        "sourceview": "doc"
      }
    }'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,hidden)
      VALUES (rec.v_view,'form_feature','tab_documents','hspacer_document_1','lyt_document_2',10,'hspacer',false,false,true,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_documents','open_doc','lyt_document_2',11,'button','Open document',false,false,true,false,false,'{"icon":"147"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Open document"}'::json,'{
      "functionName": "open_selected_path",
      "parameters": {
        "columnfind": "path",
        "targetwidget": "tab_documents_tbl_documents",
        "sourceview": "doc"
      }
    }'::json,'tbl_doc_x_element',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
      VALUES (rec.v_view,'form_feature','tab_documents','tbl_documents','lyt_document_3',1,'tableview',false,false,false,false,false,'{"saveValue": false}'::json,'{
      "functionName": "open_selected_path",
      "parameters": {
        "targetwidget": "tab_documents_tbl_documents",
        "columnfind": "path"
      }
    }'::json,'tbl_doc_x_element',false,4);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
      "icon": "111"
    }'::json,'{
      "saveValue": false
    }'::json,'{
      "functionName": "insert_feature",
      "parameters": {
        "targetwidget": "tab_features_feature_id"
      }
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
      "icon": "112"
    }'::json,'{
      "saveValue": false
    }'::json,'{
      "functionName": "delete_object",
      "parameters": {
        "columnfind": "element_id",
        "targetwidget": "tab_features_tbl_element",
        "sourceview": "element"
      }
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
      "icon": "137"
    }'::json,'{
      "saveValue": false
    }'::json,'{
      "functionName": "selection_init"
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
      "icon": "178"
    }'::json,'{
      "saveValue": false
    }'::json,false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview',':','',false,false,false,false,false,'{
      "saveValue": false,
      "tableUpsert": "v_ui_element_x_arc",
      "featureType": "arc"
    }'::json,'tbl_element_x_arc',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview',':','',false,false,false,false,false,'{
      "saveValue": false,
      "tableUpsert": "v_ui_element_x_connec",
      "featureType": "connec"
    }'::json,'tbl_element_x_connec',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview',':','',false,false,false,false,false,'{
      "saveValue": false,
      "tableUpsert": "v_ui_element_x_link",
      "featureType": "link"
    }'::json,'tbl_element_x_link',false);
    INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
      VALUES (rec.v_view,'form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview',':','',false,false,false,false,false,'{
      "saveValue": false,
      "tableUpsert": "v_ui_element_x_node",
      "featureType": "node"
    }'::json,'tbl_element_x_node',false);
      END LOOP;
END $$;

DELETE FROM cat_element WHERE id = 'EMETER-01' AND element_type = 'EMETER';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4342, 'Node not valid because it has more than 2 arcs', 'Select a valid node', 1, true, 'utils', 'core', 'UI');

UPDATE sys_function SET project_type = 'utils' WHERE id =3302;

UPDATE sys_fprocess set query_text = 'SELECT node_id, nodecat_id, expl_id, the_geom FROM temp_t_pgr_go2epa_node WHERE dma_id = 0 and sector_id > 0'
WHERE fid = 233;


UPDATE sys_fprocess set fprocess_name = 'Node orphan', except_level = 2, info_msg ='No nodes orphan found', except_msg ='nodes orphan with is_arcdivide in true', except_table='anl_node', function_name ='[gw_fct_om_check_data]',
query_text = 'SELECT n.node_id, n.nodecat_id, n.the_geom, n.expl_id FROM t_node n JOIN cat_feature_node on node_type = id 
WHERE NOT EXISTS (SELECT 1 FROM t_arc a WHERE a.node_1 = n.node_id) AND NOT EXISTS (SELECT 1 FROM t_arc a WHERE a.node_2 = n.node_id) AND isarcdivide'
WHERE fid = 107;

UPDATE sys_fprocess set fprocess_name = 'Node orphan (EPA)', except_level = 2, info_msg ='No nodes orphan found',  except_msg ='nodes orphan ready-to-export ', except_table='anl_node', function_name ='[gw_fct_pg2epa_check_result]',
query_text = 'SELECT n.node_id, n.nodecat_id, n.the_geom, n.expl_id FROM t_node n WHERE NOT EXISTS (SELECT 1 FROM t_arc a WHERE a.node_1 = n.node_id) AND NOT EXISTS (SELECT 1 FROM t_arc a WHERE a.node_2 = n.node_id)
AND epa_type !=''UNDEFINED'' AND sector_id IN (SELECT sector_id FROM selector_sector WHERE cur_user = current_user) AND is_operative'
WHERE fid = 228;

update sys_fprocess set active =false WHERE fid = 460;

UPDATE config_param_system set isenabled =true where parameter = 'basic_search_hydrometer';

UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_pump' WHERE formname='ve_epa_frpump' AND formtype='form_feature' AND columnname='hspacer_epa_1' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_pump' WHERE formname='ve_epa_frpump' AND formtype='form_feature' AND columnname='remove_from_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_pump' WHERE formname='ve_epa_frpump' AND formtype='form_feature' AND columnname='add_to_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_pump' WHERE formname='ve_epa_frpump' AND formtype='form_feature' AND columnname='edit_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_pump' WHERE formname='ve_epa_frpump' AND formtype='form_feature' AND columnname='tbl_inp_pump' AND tabname='tab_epa';

INSERT INTO config_form_tabs (formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device) VALUES('ve_link', 'tab_epa', 'EPA', 'List of Result EPA values', 'role_basic', NULL, '[{"actionName":"actionEdit", "disabled":false},
{"actionName":"actionZoom", "disabled":false},
{"actionName":"actionCentered", "disabled":false},
{"actionName":"actionZoomOut", "disabled":false},
{"actionName":"actionCatalog", "disabled":false},
{"actionName":"actionWorkcat", "disabled":false},
{"actionName":"actionCopyPaste","disabled":false},
{"actionName":"actionSection", "disabled":false},
{"actionName":"actionGetParentId", "disabled":false},
{"actionName":"actionLink",  "disabled":false}]'::json, 1, '{4,5}');


INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'custom_roughness', 'lyt_epa_data_1', 1, 'string', 'text', 'Custom roughness:', 'Custom roughness', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'custom_length', 'lyt_epa_data_1', 2, 'string', 'text', 'Custom length:', 'Custom length', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'matcat_id', 'lyt_epa_data_1', 3, 'string', 'text', 'Matcat ID:', 'Matcat ID:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'cat_roughness', 'lyt_epa_data_1', 4, 'string', 'text', 'Roughness:', 'Roughness:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'dint', 'lyt_epa_data_1', 5, 'string', 'text', 'Dint:', 'Dint:', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'result_id', 'lyt_epa_data_2', 6, 'string', 'text', 'Result ID:', 'Result ID:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'flow_max', 'lyt_epa_data_2', 7, 'string', 'text', 'Flow max:', 'Flow max:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'flow_min', 'lyt_epa_data_2', 8, 'string', 'text', 'Flow min:', 'Flow min:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'flow_avg', 'lyt_epa_data_2', 9, 'string', 'text', 'Flow avg:', 'Flow avg:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'vel_max', 'lyt_epa_data_2', 10, 'string', 'text', 'Vel max:', 'Vel max:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'vel_min', 'lyt_epa_data_2', 11, 'string', 'text', 'Vel min:', 'Vel min:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'vel_avg', 'lyt_epa_data_2', 12, 'string', 'text', 'Vel avg:', 'Vel avg:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'headloss_max', 'lyt_epa_data_2', 13, 'string', 'text', 'Headloss max:', 'Headloss max:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'headloss_min', 'lyt_epa_data_2', 14, 'string', 'text', 'Headloss min:', 'Headloss min:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'setting_max', 'lyt_epa_data_2', 15, 'string', 'text', 'Setting max:', 'Setting max:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'seetting_min', 'lyt_epa_data_2', 16, 'string', 'text', 'Setting min:', 'Setting min:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'reaction_max', 'lyt_epa_data_2', 17, 'string', 'text', 'Reaction max:', 'Reaction max:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'reaction_min', 'lyt_epa_data_2', 18, 'string', 'text', 'Reaction min:', 'Reaction min:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'ffactor_max', 'lyt_epa_data_2', 19, 'string', 'text', 'Ffactor max:', 'Ffactor max:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'ffactor_min', 'lyt_epa_data_2', 20, 'string', 'text', 'Ffactor min:', 'Ffactor min:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'total_headloss_max', 'lyt_epa_data_2', 21, 'string', 'text', 'Total headloss max:', 'Total headloss max:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'total_headloss_min', 'lyt_epa_data_2', 22, 'string', 'text', 'Total headloss min:', 'Total headloss min:', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'custom_dint', 'lyt_epa_data_1', 23, 'string', 'text', 'Custom dint:', 'Custom dint:', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'minorloss', 'lyt_epa_data_1', 24, 'string', 'text', 'Minor loss:', 'Minor loss', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('ve_epa_link', 'form_feature', 'tab_epa', 'status', 'lyt_epa_data_1', 25, 'string', 'combo', 'Status:', 'Status', NULL, false, false, true, false, false, 'SELECT id, idval FROM inp_typevalue WHERE typevalue=''inp_value_status_pipe''', true, true, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);


DELETE FROM config_form_fields WHERE formname='ve_epa_connec' AND formtype='form_feature' AND columnname='custom_dint' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_connec' AND formtype='form_feature' AND columnname='custom_length' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_connec' AND formtype='form_feature' AND columnname='custom_roughness' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_connec' AND formtype='form_feature' AND columnname='minorloss' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_connec' AND formtype='form_feature' AND columnname='status' AND tabname='tab_epa';


INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('sys_table_context', '{"levels": ["INVENTORY", "NETWORK", "FRELEMENT"]}', NULL, NULL, '{
  "orderBy": 9
}'::json);
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":30}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["OM", "ANALYTICS"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":29}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["BASEMAP", "CARTO"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":28}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["BASEMAP", "ADDRESS"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":27}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["MASTERPLAN", "NETSCENARIO"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":26}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["MASTERPLAN", "TRACEABILITY"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":25}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["MASTERPLAN", "PRICES"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":24}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["MASTERPLAN", "PSECTOR"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":23}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["EPA", "COMPARE"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":22}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["EPA", "RESULTS"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":21}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["EPA", "DSCENARIO"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":20}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["EPA", "FLOWREG"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":19}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["EPA", "HYDRAULICS"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":18}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["EPA", "HYDROLOGY"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":17}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["EPA", "CATALOGS"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":16}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["OM", "VISIT"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":15}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["OM", "FLOWTRACE"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":14}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["OM", "MINCUT"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":13}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "VALUE DOMAIN"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":12}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "AUXILIAR"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 11}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "OTHER"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 5}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "NETWORK", "POLYGON"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 4}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "NETWORK", "ELEMENT"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 3}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "NETWORK", "FRELEMENT"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 3}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "NETWORK", "LINK"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 3}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "NETWORK", "NODE"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 3}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "NETWORK", "ARC"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy": 3}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "NETWORK", "CONNEC"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":2}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "MAP ZONES"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":1}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["INVENTORY", "CATALOGS"]}';
UPDATE config_typevalue SET idval=NULL, camelstyle=NULL, addparam='{"orderBy":0}'::json WHERE typevalue='sys_table_context' AND id='{"levels": ["HIDDEN"]}';

UPDATE sys_table SET project_template = NULL, context = '{"levels": ["INVENTORY", "NETWORK", "FRELEMENT"]}' WHERE id = 've_man_frelem';

UPDATE sys_table SET project_template = NULL WHERE id = 've_man_genelem';

UPDATE sys_table SET project_template = '{"template": [1], "visibility": false, "levels_to_read": 2}'::jsonb WHERE id = 've_element';

UPDATE sys_table SET orderby=1 WHERE id='ve_node';
UPDATE sys_table SET orderby=2, alias = 'FRegulator' WHERE id='ve_man_frelem';
UPDATE sys_table SET orderby=6, alias = 'Element' WHERE id='ve_element';
UPDATE sys_table SET orderby=3 WHERE id='ve_arc';
UPDATE sys_table SET orderby=4 WHERE id='ve_connec';
UPDATE sys_table SET orderby=5 WHERE id='ve_link';

INSERT INTO config_param_system ("parameter", value, descript, "label", dv_querytext, dv_filterbyfield, isenabled, layoutorder,
project_type, dv_isparent, isautoupdate, "datatype", widgettype, ismandatory, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet,
widgetcontrols, placeholder, standardvalue, layoutname)
VALUES('epa_export_hybrid_dma', 'false', 'If True, hybrid DMAs are exported when network mode is TRANSMISSION NETWORK',
'EPA Export Hybrid DMA:', NULL, NULL, true, 8, 'ws', NULL, NULL, 'boolean', 'check', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
'lyt_admin_other');

update sys_table set alias = 'FRpump Dscenario' where id = 've_inp_dscenario_frpump';
update sys_table set alias = 'FRvalve Dscenario' where id = 've_inp_dscenario_frvalve';
update sys_table set alias = 'FRshortpipe Dscenario' where id = 've_inp_dscenario_frshortpipe';

update sys_table set alias = 'FRpump' where id = 've_inp_frpump';
update sys_table set alias = 'FRvalve' where id = 've_inp_frvalve';
update sys_table set alias = 'FRshortpipe' where id = 've_inp_frshortpipe';


UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_air_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_check_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_fl_contr_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_gen_purp_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_green_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_outfall_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_pr_break_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_pr_reduc_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_pr_susta_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_shutoff_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';
UPDATE config_form_fields SET ismandatory=true WHERE formname='ve_node_throttle_valve' AND formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';

DELETE FROM config_param_system WHERE "parameter"='basic_selector_tab_hydro_state';

DELETE FROM sys_table WHERE id='ve_inp_dscenario_pump_additional';
DELETE FROM sys_table WHERE id='ve_inp_pump_additional';


UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_valve' WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='add_to_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_valve' WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='edit_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_valve' WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='hspacer_epa_1' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_valve' WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='remove_from_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_valve' WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='tbl_inp_valve' AND tabname='tab_epa';

UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_shortpipe' WHERE formname='ve_epa_frshortpipe' AND formtype='form_feature' AND columnname='add_to_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_shortpipe' WHERE formname='ve_epa_frshortpipe' AND formtype='form_feature' AND columnname='edit_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_shortpipe' WHERE formname='ve_epa_frshortpipe' AND formtype='form_feature' AND columnname='hspacer_epa_1' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_shortpipe' WHERE formname='ve_epa_frshortpipe' AND formtype='form_feature' AND columnname='remove_from_dscenario' AND tabname='tab_epa';
UPDATE config_form_fields SET linkedobject='tbl_frelem_dsc_shortpipe' WHERE formname='ve_epa_frshortpipe' AND formtype='form_feature' AND columnname='tbl_inp_shortpipe' AND tabname='tab_epa';

DELETE FROM config_form_fields WHERE columnname = 'nodarc_id' and formname ilike 've_epa_fr%';

UPDATE config_form_fields SET widgettype = 'combo', dv_querytext = 'SELECT id, idval FROM inp_typevalue WHERE typevalue=''inp_typevalue_valve'''
WHERE formname = 've_epa_frvalve' AND columnname = 'valve_type';

UPDATE config_form_fields SET iseditable = TRUE, widgettype = 'combo',
dv_querytext = 'SELECT DISTINCT (id) AS id,  idval  AS idval FROM inp_typevalue WHERE id IS NOT NULL AND typevalue=''inp_value_status_valve'''
WHERE formname = 've_epa_frvalve' AND columnname = 'status';

UPDATE config_form_fields SET iseditable = TRUE, widgettype = 'combo',
dv_querytext = 'SELECT DISTINCT (id) AS id,  idval  AS idval FROM inp_typevalue WHERE typevalue=''inp_value_status_shortpipe_dscen'''
WHERE formname = 've_epa_frshortpipe' AND columnname = 'status';

DELETE FROM config_form_fields WHERE tabname = 'tab_epa' AND columnname = 'to_arc';

UPDATE config_form_fields SET label = 'Bulk coefficient:', tooltip = 'Bulk coefficient' WHERE formtype = 'form_feature' AND columnname = 'bulk_coeff';

-- ve_dma
DELETE FROM config_form_fields where formname in ('v_ui_dma', 've_dma');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','sector_id','lyt_data_1',9,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','dma_id','lyt_data_1',1,'integer','text','Dma id:','dma_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_dma", "activated": true, "keyColumn": "dma_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','dma_type','lyt_data_1',6,'string','combo','Dma type:','dma_type',false,false,true,false,'SELECT id, idval FROM edit_typevalue WHERE typevalue=''dma_type''',true,true,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','macrodma_id','lyt_data_1',7,'string','combo','Macrodma id:','macrodma_id',false,false,true,false,'SELECT macrodma_id as id, name as idval FROM macrodma WHERE macrodma_id IS NOT NULL',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','expl_id','lyt_data_1',8,'text','text','Expl id:','expl_id','Ex: {1,2}',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','muni_id','lyt_data_1',10,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_dma','form_feature','tab_none','avg_press','lyt_data_1',11,'numeric','text','Average pressure:','avg_press',false,false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','pattern_id','lyt_data_1',12,'string','combo','Pattern id:','pattern_id',false,false,true,false,false,'SELECT DISTINCT (pattern_id) AS id,  pattern_id  AS idval FROM inp_pattern WHERE pattern_id IS NOT NULL',true,true,'{"setMultiline": false, "valueRelation":{"nullValue":true, "layer": "ve_inp_pattern", "activated": true, "keyColumn": "pattern_id", "valueColumn": "pattern_id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','effc','lyt_data_1',13,'string','text','Effc:','effc',false,false,true,false,false,'SELECT DISTINCT (pattern_id) AS id,  pattern_id  AS idval FROM inp_pattern WHERE pattern_id IS NOT NULL',true,true,'{"setMultiline": false, "valueRelation":{"nullValue":true, "layer": "ve_inp_pattern", "activated": true, "keyColumn": "pattern_id", "valueColumn": "pattern_id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','graphconfig','lyt_data_1',14,'string','text','Graphconfig:','graphconfig',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','stylesheet','lyt_data_1',15,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','lock_level','lyt_data_1',16,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','link','lyt_data_1',17,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','addparam','lyt_data_1',18,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','created_at','lyt_data_1',19,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','created_by','lyt_data_1',20,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','updated_at','lyt_data_1',21,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dma','form_feature','tab_none','updated_by','lyt_data_1',22,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_dqa
DELETE FROM config_form_fields WHERE formname IN ('ve_dqa', 'v_ui_dqa');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','sector_id','lyt_data_1',9,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','dqa_id','lyt_data_1',1,'integer','text','Dqa id:','dqa_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_dqa", "activated": true, "keyColumn": "dqa_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','dqa_type','lyt_data_1',6,'string','combo','Dqa type:','dma_type',false,false,true,false,'SELECT id, idval FROM edit_typevalue WHERE typevalue=''dqa_type''',true,true,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','macrodqa_id','lyt_data_1',7,'string','combo','Macrodqa:','macrodqa_id',false,false,true,false,'SELECT macrodqa_id as id, name as idval FROM macrodqa WHERE macrodqa_id IS NOT NULL',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','expl_id','lyt_data_1',8,'text','text','Expl id:','expl_id','Ex: {1,2}',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','muni_id','lyt_data_1',10,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','avg_press','lyt_data_1',11,'numeric','text','Average pressure:','avg_press',false,false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','pattern_id','lyt_data_1',12,'string','combo','Pattern id:','pattern_id',false,false,true,false,false,'SELECT DISTINCT (pattern_id) AS id,  pattern_id  AS idval FROM inp_pattern WHERE pattern_id IS NOT NULL',true,true,'{"setMultiline": false, "valueRelation":{"nullValue":true, "layer": "ve_inp_pattern", "activated": true, "keyColumn": "pattern_id", "valueColumn": "pattern_id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','graphconfig','lyt_data_1',13,'string','text','Graphconfig:','graphconfig',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','stylesheet','lyt_data_1',14,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','lock_level','lyt_data_1',15,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','link','lyt_data_1',16,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','addparam','lyt_data_1',17,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','created_at','lyt_data_1',18,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','created_by','lyt_data_1',19,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','updated_at','lyt_data_1',20,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_dqa','form_feature','tab_none','updated_by','lyt_data_1',21,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_presszone
DELETE FROM config_form_fields WHERE formname IN ('ve_presszone', 'v_ui_presszone');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','sector_id','lyt_data_1',9,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','presszone_id','lyt_data_1',1,'integer','text','Presszone id:','presszone_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_presszone", "activated": true, "keyColumn": "presszone_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','presszone_type','lyt_data_1',6,'string','combo','Presszone type:','presszone_type',false,false,true,false,'SELECT id, idval FROM edit_typevalue WHERE typevalue=''presszone_type''',true,true,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','expl_id','lyt_data_1',8,'text','text','Expl id:','expl_id','Ex: {1,2}',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','muni_id','lyt_data_1',10,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','avg_press','lyt_data_1',11,'numeric','text','Average pressure:','avg_press',false,false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','head','lyt_data_1',12,'numeric','text','Head:','head',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','graphconfig','lyt_data_1',13,'string','text','Graphconfig:','graphconfig',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','stylesheet','lyt_data_1',14,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','lock_level','lyt_data_1',15,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','link','lyt_data_1',16,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','addparam','lyt_data_1',17,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','created_at','lyt_data_1',18,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','created_by','lyt_data_1',19,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','updated_at','lyt_data_1',20,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_presszone','form_feature','tab_none','updated_by','lyt_data_1',21,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);


-- ve_supplyzone
DELETE FROM config_form_fields WHERE formname IN ('ve_supplyzone', 'v_ui_supplyzone');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",placeholder,tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','sector_id','lyt_data_1',8,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','supplyzone_id','lyt_data_1',1,'integer','text','Supplyzone id:','supplyzone_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_supplyzone", "activated": true, "keyColumn": "supplyzone_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','supplyzone_type','lyt_data_1',6,'string','combo','Supply type:','supplyzone_type',false,false,true,false,'SELECT id, idval FROM edit_typevalue WHERE typevalue=''supplyzone_type''',true,true,'{"setMultiline":false}'::json,true);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','expl_id','lyt_data_1',7,'text','text','Expl id:','expl_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','muni_id','lyt_data_1',9,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','avg_press','lyt_data_1',10,'numeric','text','Average pressure:','avg_press',false,false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','pattern_id','lyt_data_1',11,'string','combo','Pattern id:','pattern_id',false,false,true,false,false,'SELECT DISTINCT (pattern_id) AS id,  pattern_id  AS idval FROM inp_pattern WHERE pattern_id IS NOT NULL',true,true,'{"setMultiline": false, "valueRelation":{"nullValue":true, "layer": "ve_inp_pattern", "activated": true, "keyColumn": "pattern_id", "valueColumn": "pattern_id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','graphconfig','lyt_data_1',12,'string','text','Graphconfig:','graphconfig',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','stylesheet','lyt_data_1',13,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','lock_level','lyt_data_1',14,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','link','lyt_data_1',15,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','addparam','lyt_data_1',16,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','created_at','lyt_data_1',17,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','created_by','lyt_data_1',18,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','updated_at','lyt_data_1',19,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_supplyzone','form_feature','tab_none','updated_by','lyt_data_1',20,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_omzone
DELETE FROM config_form_fields WHERE formname IN ('ve_omzone', 'v_ui_omzone');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','sector_id','lyt_data_1',9,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','omzone_id','lyt_data_1',1,'integer','text','Omzone id:','omzone_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_omzone", "activated": true, "keyColumn": "omzone_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','omzone_type','lyt_data_1',6,'string','combo','Omzone type:','omzone_type',false,false,true,false,'SELECT id, idval FROM edit_typevalue WHERE typevalue=''omzone_type''',true,true,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','macroomzone_id','lyt_data_1',7,'string','combo','Macroomzone:','macroomzone_id',false,false,true,false,'SELECT macroomzone_id as id, name as idval FROM macroomzone WHERE macroomzone_id IS NOT NULL',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','expl_id','lyt_data_1',8,'text','text','Expl id:','expl_id','Ex: {1,2}',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','muni_id','lyt_data_1',10,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','graphconfig','lyt_data_1',11,'string','text','Graphconfig:','graphconfig',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','stylesheet','lyt_data_1',12,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','lock_level','lyt_data_1',13,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','link','lyt_data_1',14,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','addparam','lyt_data_1',15,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','created_at','lyt_data_1',16,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','created_by','lyt_data_1',17,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','updated_at','lyt_data_1',18,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_omzone','form_feature','tab_none','updated_by','lyt_data_1',19,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_macroomzone
DELETE FROM config_form_fields WHERE formname IN ('ve_macroomzone', 'v_ui_macroomzone');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','sector_id','lyt_data_1',7,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','macroomzone_id','lyt_data_1',1,'integer','text','Macroomzone id:','macroomzone_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_macroomzone", "activated": true, "keyColumn": "macroomzone_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','expl_id','lyt_data_1',6,'text','text','Expl id:','expl_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','muni_id','lyt_data_1',8,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','stylesheet','lyt_data_1',9,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','lock_level','lyt_data_1',10,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','link','lyt_data_1',11,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','addparam','lyt_data_1',12,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','created_at','lyt_data_1',13,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','created_by','lyt_data_1',14,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','updated_at','lyt_data_1',15,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macroomzone','form_feature','tab_none','updated_by','lyt_data_1',16,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_macrodqa
DELETE FROM config_form_fields WHERE formname IN ('ve_macrodqa', 'v_ui_macrodqa');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','sector_id','lyt_data_1',7,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','macrodqa_id','lyt_data_1',1,'integer','text','Macrodqa id:','macrodqa_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_macrodqa", "activated": true, "keyColumn": "macrodqa_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','expl_id','lyt_data_1',6,'text','text','Expl id:','expl_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','muni_id','lyt_data_1',8,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','stylesheet','lyt_data_1',9,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','lock_level','lyt_data_1',10,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','link','lyt_data_1',11,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','addparam','lyt_data_1',12,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','created_at','lyt_data_1',13,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','created_by','lyt_data_1',14,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','updated_at','lyt_data_1',15,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodqa','form_feature','tab_none','updated_by','lyt_data_1',16,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_macrodma
DELETE FROM config_form_fields WHERE formname IN ('ve_macrodma', 'v_ui_macrodma');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','sector_id','lyt_data_1',7,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','macrodma_id','lyt_data_1',1,'integer','text','Macrodma id:','macrodma_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_macrodma", "activated": true, "keyColumn": "macrodma_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','expl_id','lyt_data_1',6,'text','text','Expl id:','expl_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','muni_id','lyt_data_1',8,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','stylesheet','lyt_data_1',9,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','lock_level','lyt_data_1',10,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','link','lyt_data_1',11,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','addparam','lyt_data_1',12,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','created_at','lyt_data_1',13,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','created_by','lyt_data_1',14,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','updated_at','lyt_data_1',15,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrodma','form_feature','tab_none','updated_by','lyt_data_1',16,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_macrosector
DELETE FROM config_form_fields WHERE formname IN ('ve_macrosector', 'v_ui_macrosector');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','sector_id','lyt_data_1',7,'integer','text','Sector id:','sector_id','Ex: {1,2}',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','macrosector_id','lyt_data_1',1,'integer','text','Macrosector id:','macrosector_id',false,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_macrosector", "activated": true, "keyColumn": "macrosector_id", "valueColumn": "name", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','expl_id','lyt_data_1',6,'text','text','Expl id:','expl_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','muni_id','lyt_data_1',8,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','stylesheet','lyt_data_1',9,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','lock_level','lyt_data_1',10,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','link','lyt_data_1',11,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','addparam','lyt_data_1',12,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','created_at','lyt_data_1',13,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','created_by','lyt_data_1',14,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','updated_at','lyt_data_1',15,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_macrosector','form_feature','tab_none','updated_by','lyt_data_1',16,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- ve_sector
DELETE FROM config_form_fields WHERE formname IN ('v_ui_sector','ve_sector');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','sector_id','lyt_data_1',1,'integer','text','Sector id:','sector_id',true,false,false,false,'{"label":"color:red; font-weight:bold"}'::json,'{"setMultiline": false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','code','lyt_data_1',2,'string','text','Code:','code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','name','lyt_data_1',3,'string','text','Name:','name',true,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','descript','lyt_data_1',4,'string','text','Descript:','descript',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','active','lyt_data_1',5,'boolean','check','Active:','active',false,false,true,false,false,false,'{"vdefault_value": true}',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','sector_type','lyt_data_1',6,'string','combo','Sector type:','sector_type',false,false,true,false,'SELECT id, idval FROM edit_typevalue WHERE typevalue=''sector_type''',true,true,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','macrosector_id','lyt_data_1',7,'string','combo','Macrosector id:','macrosector_id',false,false,true,false,'SELECT macrosector_id as id, name as idval FROM macrosector WHERE macrosector_id IS NOT NULL',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','expl_id','lyt_data_1',8,'text','text','Expl id:','expl_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','muni_id','lyt_data_1',9,'text','text','Muni id:','muni_id','Ex: {1,2}',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_sector','form_feature','tab_none','avg_press','lyt_data_1',10,'numeric','text','Average pressure:','avg_press',false,false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','pattern_id','lyt_data_1',11,'string','combo','Pattern id:','pattern_id',false,false,true,false,false,'SELECT DISTINCT (pattern_id) AS id,  pattern_id  AS idval FROM inp_pattern WHERE pattern_id IS NOT NULL',true,true,'{"setMultiline": false, "valueRelation":{"nullValue":true, "layer": "ve_inp_pattern", "activated": true, "keyColumn": "pattern_id", "valueColumn": "pattern_id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','graphconfig','lyt_data_1',12,'string','text','Graphconfig:','graphconfig',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','stylesheet','lyt_data_1',13,'string','text','Stylesheet:','stylesheet',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','lock_level','lyt_data_1',14,'text','text','Lock level:','lock_level',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','link','lyt_data_1',15,'text','text','Link:','link',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','addparam','lyt_data_1',16,'text','text','Addparam:','addparam',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','created_at','lyt_data_1',17,'datetime','datetime','Created at:','created_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','created_by','lyt_data_1',18,'string','text','Created by:','created_by',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','updated_at','lyt_data_1',19,'datetime','datetime','Updated at:','updated_at',false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_sector','form_feature','tab_none','updated_by','lyt_data_1',20,'string','text','Updated by:','updated_by',false,false,false,false,'{"setMultiline":false}'::json,false);

-- Mapzone types
ALTER TABLE edit_typevalue DISABLE TRIGGER USER;
INSERT INTO edit_typevalue (typevalue,id,idval)
	VALUES ('sector_type','TRANSMISSION','TRANSMISSION');
UPDATE edit_typevalue
	SET id='HYBRID',idval='HYBRID'
	WHERE typevalue='sector_type' AND id='SOURCE';
INSERT INTO edit_typevalue (typevalue,id,idval)
	VALUES ('dqa_type','TANK','TANK');
INSERT INTO edit_typevalue (typevalue,id,idval)
	VALUES ('dqa_type','RECLORINATOR','RECLORINATOR');
INSERT INTO edit_typevalue (typevalue,id,idval)
	VALUES ('dqa_type','UNDEFINED','INDEFINIDO');
UPDATE edit_typevalue
	SET id='WATERWELL',idval='WATERWELL'
	WHERE typevalue='presszone_type' AND id='PSV';
ALTER TABLE edit_typevalue ENABLE TRIGGER USER;


INSERT INTO config_typevalue (typevalue,id,idval) VALUES ('widgettype_typevalue','list','list');
UPDATE config_form_fields SET widgettype='list' WHERE formname IN('ve_dma', 've_dqa', 've_sector', 've_supplyzone', 've_macrodma', 've_macrodqa', 've_macrosector', 've_omzone', 've_macroomzone', 've_presszone') AND columnname IN('expl_id', 'sector_id', 'muni_id');


UPDATE config_toolbox SET alias='Macromapzones analysis', functionparams='{"featureType":[]}'::json, inputparams='[{"widgetname": "graphClass", "label": "Graph class:", "widgettype": "combo", "datatype": "text", "tooltip": "Graphanalytics method used", "layoutname": "grl_option_parameters", "layoutorder": 1, "comboIds": ["MACROSECTOR", "MACROOMZONE"], "comboNames": ["MACROSECTOR", "MACROOMZONE"], "selectedId": null}, {"widgetname": "exploitation", "label": "Exploitation:", "widgettype": "combo", "datatype": "text", "tooltip": "Choose exploitation to work with", "layoutname": "grl_option_parameters", "layoutorder": 2, "dvQueryText": "SELECT id, idval FROM ( SELECT -901 AS id, ''User selected expl'' AS idval, ''a'' AS sort_order UNION SELECT -902 AS id, ''All exploitations'' AS idval, ''b'' AS sort_order UNION SELECT expl_id AS id, name AS idval, ''c'' AS sort_order FROM exploitation WHERE active IS NOT FALSE ) a ORDER BY sort_order ASC, idval ASC", "selectedId": null}, {"widgetname": "commitChanges", "label": "Commit changes:", "widgettype": "check", "datatype": "boolean", "tooltip": "If True, changes will be applied to DB. If False, algorithm results will be saved in anl tables", "layoutname": "grl_option_parameters", "layoutorder": 8, "value": null}]'::json WHERE id=3482;


update sys_table set project_template = null WHERE id IN ('ve_macrosector', 've_dqa','ve_supplyzone','ve_macrodma');
UPDATE config_form_fields SET iseditable=true WHERE formname IN('ve_dma', 've_dqa', 've_sector', 've_supplyzone', 've_macrodma', 've_macrodqa', 've_macrosector', 've_omzone', 've_macroomzone', 've_presszone') AND columnname = 'graphconfig';
UPDATE config_form_fields SET widgettype='text' WHERE formname IN('ve_dma', 've_dqa', 've_sector', 've_supplyzone', 've_macrodma', 've_macrodqa', 've_macrosector', 've_omzone', 've_macroomzone', 've_presszone') AND columnname IN('created_at', 'updated_at');

UPDATE macrodma SET expl_id = NULL;

DELETE FROM edit_typevalue WHERE typevalue='presszone_type' AND id='WATERWELL';

UPDATE config_form_fields SET placeholder=NULL WHERE formname IN('ve_dma', 've_dqa', 've_sector', 've_supplyzone', 've_macrodma', 've_macrodqa', 've_macrosector', 've_omzone', 've_macroomzone', 've_presszone') AND columnname IN('expl_id', 'sector_id', 'muni_id') AND iseditable=false;

UPDATE sys_style
SET styletype='qml', stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis simplifyLocal="1" version="3.40.8-Bratislava" styleCategories="Symbology|Rendering" minScale="10000" hasScaleBasedVisibilityFlag="1" simplifyDrawingHints="1" maxScale="0" autoRefreshMode="Disabled" autoRefreshTime="0" simplifyDrawingTol="1" simplifyAlgorithm="0" symbologyReferenceScale="-1" simplifyMaxScale="1">
  <renderer-v2 type="categorizedSymbol" forceraster="0" symbollevels="0" enableorderby="0" referencescale="-1" attr="epa_type">
    <categories>
      <category type="string" symbol="0" value="FRPUMP" label="FRPUMP" uuid="{334c11cb-4926-49bd-8dce-752949f3ca31}" render="true"/>
      <category type="string" symbol="1" value="FRSHORTPIPE" label="FRSHORTPIPE" uuid="{faa0cff4-c4ce-4266-9be1-77c44cc9e75b}" render="true"/>
      <category type="string" symbol="2" value="FRVALVE" label="FRVALVE" uuid="{cf089325-831f-4177-b8a3-833f284c13eb}" render="true"/>
    </categories>
    <symbols>
      <symbol is_animated="0" frame_rate="10" type="line" alpha="1" name="0" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{631f82b0-276e-4662-85eb-be419db4b4e9}" class="SimpleLine" locked="0" pass="0" enabled="1">
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
            <Option type="QString" value="31,120,180,191,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,0.74999618524452583" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="1.5" name="line_width"/>
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
        <layer id="{7816f0be-870c-47fe-a08e-10a62ca91390}" class="MarkerLine" locked="0" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="4" name="average_angle_length"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale"/>
            <Option type="QString" value="MM" name="average_angle_unit"/>
            <Option type="QString" value="3" name="interval"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="interval_map_unit_scale"/>
            <Option type="QString" value="MM" name="interval_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="0" name="offset_along_line"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_along_line_unit"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="bool" value="true" name="place_on_every_part"/>
            <Option type="QString" value="CentralPoint" name="placements"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="1" name="rotate"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" frame_rate="10" type="marker" alpha="1" name="@0@1" clip_to_extent="1" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer id="{86de7408-bf31-40d0-8edc-247561c36306}" class="SimpleMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="227,26,28,255,rgb:0.8901960784313725,0.10196078431372549,0.10980392156862745,1" name="color"/>
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
                <Option type="QString" value="3.8" name="size"/>
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
            <layer id="{dd2e066d-0fc6-464b-b193-506ce4a8d3f7}" class="FontMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="P" name="chr"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="Arial" name="font"/>
                <Option type="QString" value="Normal" name="font_style"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="2.2619" name="size"/>
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
        </layer>
        <layer id="{f4662f4d-c4dd-44f5-a04d-5d25aead883f}" class="MarkerLine" locked="0" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="4" name="average_angle_length"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale"/>
            <Option type="QString" value="MM" name="average_angle_unit"/>
            <Option type="QString" value="3" name="interval"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="interval_map_unit_scale"/>
            <Option type="QString" value="MM" name="interval_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="0" name="offset_along_line"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_along_line_unit"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="bool" value="true" name="place_on_every_part"/>
            <Option type="QString" value="CentralPoint" name="placements"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="1" name="rotate"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" frame_rate="10" type="marker" alpha="1" name="@0@2" clip_to_extent="1" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer id="{f56d93aa-ffdf-48fd-a172-71fe85d328fd}" class="SimpleMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="filled_arrowhead" name="name"/>
                <Option type="QString" value="-1.33333333333333304,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="solid" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="diameter" name="scale_method"/>
                <Option type="QString" value="3" name="size"/>
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
        </layer>
      </symbol>
      <symbol is_animated="0" frame_rate="10" type="line" alpha="1" name="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{631f82b0-276e-4662-85eb-be419db4b4e9}" class="SimpleLine" locked="0" pass="0" enabled="1">
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
            <Option type="QString" value="31,120,180,191,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,0.74999618524452583" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="1.5" name="line_width"/>
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
        <layer id="{7816f0be-870c-47fe-a08e-10a62ca91390}" class="MarkerLine" locked="0" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="4" name="average_angle_length"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale"/>
            <Option type="QString" value="MM" name="average_angle_unit"/>
            <Option type="QString" value="3" name="interval"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="interval_map_unit_scale"/>
            <Option type="QString" value="MM" name="interval_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="0" name="offset_along_line"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_along_line_unit"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="bool" value="true" name="place_on_every_part"/>
            <Option type="QString" value="CentralPoint" name="placements"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="1" name="rotate"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" frame_rate="10" type="marker" alpha="1" name="@1@1" clip_to_extent="1" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer id="{86de7408-bf31-40d0-8edc-247561c36306}" class="SimpleMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="227,26,28,255,rgb:0.8901960784313725,0.10196078431372549,0.10980392156862745,1" name="color"/>
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
                <Option type="QString" value="3.8" name="size"/>
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
            <layer id="{dd2e066d-0fc6-464b-b193-506ce4a8d3f7}" class="FontMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="S" name="chr"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="Arial" name="font"/>
                <Option type="QString" value="Normal" name="font_style"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="2.2619" name="size"/>
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
        </layer>
        <layer id="{f4662f4d-c4dd-44f5-a04d-5d25aead883f}" class="MarkerLine" locked="0" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="4" name="average_angle_length"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale"/>
            <Option type="QString" value="MM" name="average_angle_unit"/>
            <Option type="QString" value="3" name="interval"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="interval_map_unit_scale"/>
            <Option type="QString" value="MM" name="interval_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="0" name="offset_along_line"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_along_line_unit"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="bool" value="true" name="place_on_every_part"/>
            <Option type="QString" value="CentralPoint" name="placements"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="1" name="rotate"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" frame_rate="10" type="marker" alpha="1" name="@1@2" clip_to_extent="1" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer id="{f56d93aa-ffdf-48fd-a172-71fe85d328fd}" class="SimpleMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="filled_arrowhead" name="name"/>
                <Option type="QString" value="-1.33333333333333304,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="solid" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="diameter" name="scale_method"/>
                <Option type="QString" value="3" name="size"/>
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
        </layer>
      </symbol>
      <symbol is_animated="0" frame_rate="10" type="line" alpha="1" name="2" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{631f82b0-276e-4662-85eb-be419db4b4e9}" class="SimpleLine" locked="0" pass="0" enabled="1">
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
            <Option type="QString" value="31,120,180,191,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,0.74999618524452583" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="1.5" name="line_width"/>
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
        <layer id="{7816f0be-870c-47fe-a08e-10a62ca91390}" class="MarkerLine" locked="0" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="4" name="average_angle_length"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale"/>
            <Option type="QString" value="MM" name="average_angle_unit"/>
            <Option type="QString" value="3" name="interval"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="interval_map_unit_scale"/>
            <Option type="QString" value="MM" name="interval_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="0" name="offset_along_line"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_along_line_unit"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="bool" value="true" name="place_on_every_part"/>
            <Option type="QString" value="CentralPoint" name="placements"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="1" name="rotate"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" frame_rate="10" type="marker" alpha="1" name="@2@1" clip_to_extent="1" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer id="{86de7408-bf31-40d0-8edc-247561c36306}" class="SimpleMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="227,26,28,255,rgb:0.8901960784313725,0.10196078431372549,0.10980392156862745,1" name="color"/>
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
                <Option type="QString" value="3.8" name="size"/>
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
            <layer id="{dd2e066d-0fc6-464b-b193-506ce4a8d3f7}" class="FontMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="V" name="chr"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="Arial" name="font"/>
                <Option type="QString" value="Normal" name="font_style"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="2.2619" name="size"/>
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
        </layer>
        <layer id="{f4662f4d-c4dd-44f5-a04d-5d25aead883f}" class="MarkerLine" locked="0" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="4" name="average_angle_length"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale"/>
            <Option type="QString" value="MM" name="average_angle_unit"/>
            <Option type="QString" value="3" name="interval"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="interval_map_unit_scale"/>
            <Option type="QString" value="MM" name="interval_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="0" name="offset_along_line"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_along_line_unit"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="bool" value="true" name="place_on_every_part"/>
            <Option type="QString" value="CentralPoint" name="placements"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="1" name="rotate"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" frame_rate="10" type="marker" alpha="1" name="@2@2" clip_to_extent="1" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer id="{f56d93aa-ffdf-48fd-a172-71fe85d328fd}" class="SimpleMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="filled_arrowhead" name="name"/>
                <Option type="QString" value="-1.33333333333333304,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="solid" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="diameter" name="scale_method"/>
                <Option type="QString" value="3" name="size"/>
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
        </layer>
      </symbol>
    </symbols>
    <source-symbol>
      <symbol is_animated="0" frame_rate="10" type="line" alpha="1" name="0" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b8cb4755-1b6a-435f-9c40-1265931ff47f}" class="SimpleLine" locked="0" pass="0" enabled="1">
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
            <Option type="QString" value="5,163,242,255,rgb:0.0196078431372549,0.63921568627450975,0.94901960784313721,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.535714" name="line_width"/>
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
        <layer id="{c45bd096-5843-45af-a206-aa15db22021f}" class="MarkerLine" locked="0" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="4" name="average_angle_length"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale"/>
            <Option type="QString" value="MM" name="average_angle_unit"/>
            <Option type="QString" value="3" name="interval"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="interval_map_unit_scale"/>
            <Option type="QString" value="MM" name="interval_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="0" name="offset_along_line"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_along_line_unit"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="bool" value="true" name="place_on_every_part"/>
            <Option type="QString" value="CentralPoint" name="placements"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="1" name="rotate"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" frame_rate="10" type="marker" alpha="1" name="@0@1" clip_to_extent="1" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer id="{b2d7dccb-ba7a-43a2-904e-07af11b742c4}" class="SimpleMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="0,106,253,255,rgb:0,0.41568627450980394,0.99215686274509807,1" name="color"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="circle" name="name"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="0,0,0,255,rgb:0,0,0,1" name="outline_color"/>
                <Option type="QString" value="solid" name="outline_style"/>
                <Option type="QString" value="0.2" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="diameter" name="scale_method"/>
                <Option type="QString" value="3" name="size"/>
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
            <layer id="{33cb60bd-bd9f-4d97-8436-1c985e76c38d}" class="FontMarker" locked="0" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="P" name="chr"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="Arial" name="font"/>
                <Option type="QString" value="Normal" name="font_style"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="2.5" name="size"/>
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
        </layer>
      </symbol>
    </source-symbol>
    <rotation/>
    <sizescale/>
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
      <symbol is_animated="0" frame_rate="10" type="line" alpha="1" name="" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{1d2e8bf4-e65c-4a65-9a06-bee67a7ae689}" class="SimpleLine" locked="0" pass="0" enabled="1">
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
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerOpacity>1</layerOpacity>
  <layerGeometryType>1</layerGeometryType>
</qgis>', active=true
WHERE layername='ve_man_frelem' AND styleconfig_id=101;

ALTER TABLE rpt_cat_result DROP CONSTRAINT IF EXISTS rpt_cat_result_network_dma_corporate;
ALTER TABLE rpt_cat_result ADD CONSTRAINT rpt_cat_result_network_dma_corporate CHECK (NOT (iscorporate = TRUE AND network_type = '5'));


CREATE RULE omzone_conflict AS
    ON UPDATE TO omzone
   WHERE ((new.omzone_id = '-1'::integer) OR (old.omzone_id = '-1'::integer)) DO INSTEAD NOTHING;

CREATE RULE omzone_undefined AS
    ON UPDATE TO omzone
   WHERE ((new.omzone_id = 0) OR (old.omzone_id = 0)) DO INSTEAD NOTHING;

CREATE RULE dma_conflict AS
    ON UPDATE TO dma
   WHERE ((new.dma_id = '-1'::integer) OR (old.dma_id = '-1'::integer)) DO INSTEAD NOTHING;

CREATE RULE dma_undefined AS
    ON UPDATE TO dma
   WHERE ((new.dma_id = 0) OR (old.dma_id = 0)) DO INSTEAD NOTHING;

CREATE RULE presszone_conflict AS
    ON UPDATE TO presszone
   WHERE ((new.presszone_id = '-1'::integer) OR (old.presszone_id = '-1'::integer)) DO INSTEAD NOTHING;

CREATE RULE presszone_undefined AS
    ON UPDATE TO presszone
   WHERE ((new.presszone_id = 0) OR (old.presszone_id = 0)) DO INSTEAD NOTHING;
   
CREATE RULE dqa_conflict AS
    ON UPDATE TO dqa
   WHERE ((new.dqa_id = '-1'::integer) OR (old.dqa_id = '-1'::integer)) DO INSTEAD NOTHING;

CREATE RULE dqa_undefined AS
    ON UPDATE TO dqa
   WHERE ((new.dqa_id = 0) OR (old.dqa_id = 0)) DO INSTEAD NOTHING;

-- expl_id is not void
CREATE RULE dqa_expl AS
    ON UPDATE TO dqa
   WHERE ((new.expl_id = '{}'::integer[]) OR (old.expl_id = '{}'::integer[])) DO INSTEAD NOTHING;

CREATE RULE presszone_expl AS
    ON UPDATE TO presszone
   WHERE ((new.expl_id = '{}'::integer[]) OR (old.expl_id = '{}'::integer[])) DO INSTEAD NOTHING;

CREATE RULE dma_expl AS
    ON UPDATE TO dma
   WHERE ((new.expl_id = '{}'::integer[]) OR (old.expl_id = '{}'::integer[])) DO INSTEAD NOTHING;

CREATE RULE omzone_expl AS
    ON UPDATE TO omzone
   WHERE ((new.expl_id = '{}'::integer[]) OR (old.expl_id = '{}'::integer[])) DO INSTEAD NOTHING;

DROP TRIGGER IF EXISTS gw_trg_ui_rpt_cat_result ON v_ui_rpt_cat_result;
CREATE TRIGGER gw_trg_ui_rpt_cat_result INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_rpt_cat_result
FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_rpt_cat_result();

CREATE TRIGGER gw_trg_edit_ve_epa_link INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('link');

CREATE TRIGGER gw_trg_edit_ve_epa_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('connec');


CREATE TRIGGER gw_trg_v_edit_sector INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_sector
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_sector('EDIT');

CREATE TRIGGER gw_trg_v_edit_presszone INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_presszone
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_presszone('EDIT');

CREATE TRIGGER gw_trg_v_edit_dma INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_dma
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dma('EDIT');

CREATE TRIGGER gw_trg_v_edit_dqa INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_dqa
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dqa('EDIT');

CREATE TRIGGER gw_trg_v_edit_supplyzone INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_supplyzone
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_supplyzone('EDIT');

CREATE TRIGGER gw_trg_v_edit_omzone INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_omzone
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_omzone('EDIT');

CREATE TRIGGER gw_trg_v_edit_macroomzone INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_macroomzone
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macroomzone('EDIT');

CREATE TRIGGER gw_trg_v_edit_macrosector INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_macrosector
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrosector('EDIT');

CREATE TRIGGER gw_trg_v_edit_macrodqa INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_macrodqa
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrodqa('EDIT');

CREATE TRIGGER gw_trg_v_edit_macrodma INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_macrodma
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrodma('EDIT');

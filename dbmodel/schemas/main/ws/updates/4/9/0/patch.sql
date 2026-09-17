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
	tscode text NULL,
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
	id serial4 NOT NULL,
	dscenario_id int4 NOT NULL,
	pattern_id varchar(16) NOT NULL,
	factor_1 numeric(12, 4) DEFAULT 1 NULL,
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
	CONSTRAINT inp_dscenario_pattern_value_pkey PRIMARY KEY (id)
);

ALTER TABLE inp_dscenario_pattern_value ADD CONSTRAINT inp_dscenario_pattern_value_dscenario_id_pattern_id_fkey 
FOREIGN KEY (dscenario_id, pattern_id) REFERENCES inp_dscenario_pattern(dscenario_id, pattern_id) 
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE inp_dscenario_pattern_value ADD CONSTRAINT inp_dscenario_pattern_value_unique UNIQUE (id,dscenario_id);


DROP VIEW IF EXISTS ve_inp_dscenario_demand;
ALTER TABLE inp_dscenario_demand RENAME TO _inp_dscenario_demand_;
ALTER TABLE _inp_dscenario_demand_ DROP CONSTRAINT inp_dscenario_demand_pkey;
ALTER TABLE _inp_dscenario_demand_ DROP CONSTRAINT inp_demand_dscenario_id_fkey;
ALTER TABLE _inp_dscenario_demand_ DROP CONSTRAINT inp_dscenario_demand_feature_type_fkey;
ALTER TABLE _inp_dscenario_demand_ DROP CONSTRAINT inp_dscenario_demand_pattern_id_fkey;

DROP INDEX IF EXISTS idx_inp_dscenario_demand_dscenario_id;
DROP INDEX IF EXISTS idx_inp_dscenario_demand_source;

ALTER TABLE _inp_dscenario_demand_ ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS SCHEMA_NAME.inp_dscenario_demand_id_seq1;
ALTER SEQUENCE SCHEMA_NAME.inp_dscenario_demand_id_seq RENAME TO inp_dscenario_demand_id_seq1;

CREATE TABLE inp_dscenario_demand (
	id serial4 NOT NULL PRIMARY KEY,
	dscenario_id int4 NOT NULL,
	feature_id int4 NOT NULL,
	feature_type varchar(16) NULL,
	demand numeric(12, 6) NULL,
	pattern_id varchar(16) NULL,
	demand_type varchar(18) NULL,
	"source" text NULL,
	CONSTRAINT inp_demand_dscenario_id_fkey FOREIGN KEY (dscenario_id) REFERENCES cat_dscenario(dscenario_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT inp_demand_pattern_id_fkey FOREIGN KEY (pattern_id) REFERENCES inp_pattern(pattern_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT inp_dscenario_demand_feature_type_fkey FOREIGN KEY (feature_type) REFERENCES sys_feature_type(id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT inp_dscenario_demand_pattern_id_fkey FOREIGN KEY (pattern_id) REFERENCES inp_pattern(pattern_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_inp_dscenario_demand_dscenario_id ON inp_dscenario_demand USING btree (dscenario_id);
CREATE INDEX idx_inp_dscenario_demand_source ON inp_dscenario_demand USING btree (source);

SELECT setval('SCHEMA_NAME.inp_dscenario_demand_id_seq', (SELECT last_value FROM inp_dscenario_demand_id_seq1));


DROP INDEX IF EXISTS arc_dma;
DROP INDEX IF EXISTS connec_dma;
DROP INDEX IF EXISTS node_dma;
DROP INDEX IF EXISTS anl_node_fid;
DROP INDEX IF EXISTS anl_node_fprocesscat_id_index;
CREATE INDEX IF NOT EXISTS anl_node_fid_idx ON anl_node USING btree (fid);
DROP INDEX IF EXISTS archived_psector_link_exit_id;
DROP INDEX IF EXISTS link_exit_id;
CREATE INDEX IF NOT EXISTS link_exit_id_idx ON link USING btree (exit_id);
DROP INDEX IF EXISTS idx_plan_psector_expl_id;
DROP INDEX IF EXISTS plan_psector_expl_id;
CREATE INDEX IF NOT EXISTS plan_psector_expl_id_idx ON plan_psector USING btree (expl_id);
ALTER TABLE selector_rpt_main_tstep DROP CONSTRAINT IF EXISTS time_cur_user_unique;


DROP VIEW IF EXISTS ve_plan_netscenario_dma;
DROP VIEW IF EXISTS ve_plan_netscenario_presszone;

ALTER TABLE plan_netscenario_presszone RENAME COLUMN presszone_name TO "name";
ALTER TABLE plan_netscenario_presszone ALTER COLUMN "name" TYPE varchar(100) USING "name"::varchar(100);
ALTER TABLE plan_netscenario_presszone ADD code varchar(100) NULL;
ALTER TABLE plan_netscenario_presszone ADD descript varchar(255) NULL;

ALTER TABLE plan_netscenario_dma RENAME COLUMN dma_name TO "name";
ALTER TABLE plan_netscenario_dma ALTER COLUMN "name" TYPE varchar(100) USING "name"::varchar(100);
ALTER TABLE plan_netscenario_dma ADD code varchar(100) NULL;
ALTER TABLE plan_netscenario_dma ADD descript varchar(255) NULL;

ALTER TABLE crmzone RENAME COLUMN id TO crmzone_id;
ALTER TABLE crmzone ADD code varchar(100) NULL;
ALTER TABLE crmzone ALTER COLUMN "name" TYPE varchar(100) USING "name"::varchar(100);
ALTER TABLE crmzone ALTER COLUMN "descript" TYPE varchar(255) USING "descript"::varchar(255);
ALTER TABLE crmzone ADD expl_id int4[] NULL;
ALTER TABLE crmzone ADD sector_id int4[] NULL;
ALTER TABLE crmzone ADD muni_id int4[] NULL;


ALTER TABLE macrodma DISABLE TRIGGER USER;
ALTER TABLE dqa DISABLE TRIGGER USER;
ALTER TABLE macrodqa DISABLE TRIGGER USER;
ALTER TABLE presszone DISABLE TRIGGER USER;
ALTER TABLE supplyzone DISABLE TRIGGER USER;
ALTER TABLE crmzone DISABLE TRIGGER USER;
ALTER TABLE plan_netscenario_dma DISABLE TRIGGER USER;
ALTER TABLE plan_netscenario_presszone DISABLE TRIGGER USER;

UPDATE macrodma SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE macrodma SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE macrodma SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE macrodma ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE macrodma ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE macrodma ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE macrodma ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE macrodma ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE macrodma ALTER COLUMN muni_id SET NOT NULL;

UPDATE dqa SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE dqa SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE dqa SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE dqa ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE dqa ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE dqa ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE dqa ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE dqa ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE dqa ALTER COLUMN muni_id SET NOT NULL;

UPDATE macrodqa SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE macrodqa SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE macrodqa SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE macrodqa ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE macrodqa ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE macrodqa ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE macrodqa ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE macrodqa ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE macrodqa ALTER COLUMN muni_id SET NOT NULL;

UPDATE presszone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE presszone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE presszone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE presszone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE presszone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE presszone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE presszone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE presszone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE presszone ALTER COLUMN muni_id SET NOT NULL;

UPDATE supplyzone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE supplyzone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE supplyzone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE supplyzone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE supplyzone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE supplyzone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE supplyzone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE supplyzone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE supplyzone ALTER COLUMN muni_id SET NOT NULL;

UPDATE crmzone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE crmzone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE crmzone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE crmzone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE crmzone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE crmzone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE crmzone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE crmzone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE crmzone ALTER COLUMN muni_id SET NOT NULL;

UPDATE plan_netscenario_dma SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE plan_netscenario_dma SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE plan_netscenario_dma SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE plan_netscenario_dma ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE plan_netscenario_dma ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE plan_netscenario_dma ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE plan_netscenario_dma ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE plan_netscenario_dma ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE plan_netscenario_dma ALTER COLUMN muni_id SET NOT NULL;

UPDATE plan_netscenario_presszone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE plan_netscenario_presszone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE plan_netscenario_presszone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE plan_netscenario_presszone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE plan_netscenario_presszone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE plan_netscenario_presszone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE plan_netscenario_presszone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE plan_netscenario_presszone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE plan_netscenario_presszone ALTER COLUMN muni_id SET NOT NULL;

ALTER TABLE macrodma ENABLE TRIGGER USER;
ALTER TABLE dqa ENABLE TRIGGER USER;
ALTER TABLE macrodqa ENABLE TRIGGER USER;
ALTER TABLE presszone ENABLE TRIGGER USER;
ALTER TABLE supplyzone ENABLE TRIGGER USER;
ALTER TABLE crmzone ENABLE TRIGGER USER;
ALTER TABLE plan_netscenario_dma ENABLE TRIGGER USER;
ALTER TABLE plan_netscenario_presszone ENABLE TRIGGER USER;


DROP RULE IF EXISTS presszone_expl ON presszone;
DROP RULE IF EXISTS dqa_expl ON dqa;


SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"plan_netscenario_dma", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"plan_netscenario_presszone", "column":"addparam", "dataType":"json", "isUtils":"False"}}$$);



DROP TABLE IF EXISTS presszone_graph;

CREATE TABLE IF NOT EXISTS plan_netscenario_mapzone_graph (
    node_id int4 NOT NULL,
    netscenario_id int4 NOT NULL,
    mapzone_id int4 NOT NULL,
    mapzone_type text NOT NULL,
    flow_sign int2 NULL,
    CONSTRAINT plan_netscenario_mapzone_graph_pkey PRIMARY KEY (node_id, mapzone_id)
);

CREATE INDEX IF NOT EXISTS plan_netscenario_mapzone_graph_mapzone_id_idx ON plan_netscenario_mapzone_graph USING btree (mapzone_id);
CREATE INDEX IF NOT EXISTS plan_netscenario_mapzone_graph_netscenario_id_idx ON plan_netscenario_mapzone_graph USING btree (netscenario_id);
CREATE INDEX IF NOT EXISTS plan_netscenario_mapzone_graph_node_id_idx ON plan_netscenario_mapzone_graph USING btree (node_id);


ALTER TABLE man_netsamplepoint ADD COLUMN place_name varchar(254) NULL;
ALTER TABLE man_netsamplepoint ADD COLUMN cabinet varchar(150) NULL;

CREATE OR REPLACE VIEW vf_link AS
 SELECT l.link_id, COALESCE(pp.state, l.state) AS p_state
   FROM link l
     LEFT JOIN LATERAL ( SELECT pp1.connec_id,
            pp1.psector_id
           FROM plan_psector_x_connec pp1
          WHERE (pp1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER)) AND pp1.connec_id = l.feature_id
          ORDER BY pp1.psector_id DESC
         LIMIT 1) last_ps ON true
     LEFT JOIN LATERAL ( SELECT pp2.state
           FROM plan_psector_x_connec pp2
          WHERE pp2.link_id = l.link_id AND pp2.psector_id = last_ps.psector_id
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
    p.tscode,
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
AS SELECT DISTINCT pv.id,
	p.dscenario_id,
    p.pattern_id,
    p.observ,
    p.tscode,
    p.tsparameters::text AS tsparameters,
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
    pv.factor_18
FROM inp_dscenario_pattern p
JOIN inp_dscenario_pattern_value pv USING (pattern_id)
WHERE EXISTS (
	SELECT 1
	FROM selector_inp_dscenario s
	WHERE s.dscenario_id = p.dscenario_id
	AND s.cur_user = CURRENT_USER
) ORDER BY pv.id;


CREATE OR REPLACE VIEW ve_inp_dscenario_demand
AS SELECT
    idd.id,
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
    n.the_geom
FROM inp_dscenario_demand idd
JOIN node n ON n.node_id = idd.feature_id
WHERE EXISTS (
	SELECT 1
	FROM selector_inp_dscenario s
	WHERE s.dscenario_id = idd.dscenario_id
	AND s.cur_user = CURRENT_USER
) AND EXISTS (
	SELECT 1
	FROM selector_sector s
	WHERE s.sector_id = n.sector_id
	AND s.cur_user = CURRENT_USER
)
UNION
SELECT
    idd.id,
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
    c.the_geom
FROM inp_dscenario_demand idd
JOIN connec c ON c.connec_id = idd.feature_id
WHERE EXISTS (
	SELECT 1
	FROM selector_inp_dscenario s
	WHERE s.dscenario_id = idd.dscenario_id
	AND s.cur_user = CURRENT_USER
) AND EXISTS (
	SELECT 1
	FROM selector_sector s
	WHERE s.sector_id = c.sector_id
	AND s.cur_user = CURRENT_USER
);

CREATE OR REPLACE VIEW ve_epa_valve
AS SELECT inp_valve.node_id,
    inp_valve.valve_type,
    cat_node.dint,
    inp_valve.custom_dint,
    inp_valve.setting,
    inp_valve.curve_id,
    inp_valve.minorloss,
    v.to_arc,
        CASE
            WHEN v.closed IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN v.broken IS FALSE AND (v.to_arc IS NOT null or inp_valve.valve_type = 'TCV') THEN 'ACTIVE'::character varying(12)
            ELSE 'OPEN'::character varying(12)
        END AS status,
    inp_valve.add_settings,
    inp_valve.init_quality,
    inp_valve.head,
    inp_valve.pattern_id,
    inp_valve.demand,
    inp_valve.demand_pattern_id,
    inp_valve.emitter_coeff,
    v_rpt_arc_stats.result_id,
    v_rpt_arc_stats.flow_max AS flowmax,
    v_rpt_arc_stats.flow_min AS flowmin,
    v_rpt_arc_stats.flow_avg AS flowavg,
    v_rpt_arc_stats.vel_max AS velmax,
    v_rpt_arc_stats.vel_min AS velmin,
    v_rpt_arc_stats.vel_avg AS velavg,
    v_rpt_arc_stats.headloss_max,
    v_rpt_arc_stats.headloss_min,
    v_rpt_arc_stats.setting_max,
    v_rpt_arc_stats.setting_min,
    v_rpt_arc_stats.reaction_max,
    v_rpt_arc_stats.reaction_min,
    v_rpt_arc_stats.ffactor_max,
    v_rpt_arc_stats.ffactor_min
   FROM node
     JOIN inp_valve USING (node_id)
     LEFT JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
     LEFT JOIN v_rpt_arc_stats ON concat(inp_valve.node_id, '_n2a') = v_rpt_arc_stats.arc_id
     LEFT JOIN man_valve v ON v.node_id = inp_valve.node_id;



CREATE OR REPLACE VIEW ve_node
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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), dma_table AS (
         SELECT dma.dma_id,
            dma.macrodma_id,
            dma.stylesheet,
            t.id::character varying(16) AS dma_type
           FROM dma
             LEFT JOIN typevalue t ON t.id::text = dma.dma_type::text AND t.typevalue::text = 'dma_type'::text
        ), presszone_table AS (
         SELECT presszone.presszone_id,
            presszone.head AS presszone_head,
            presszone.stylesheet,
            t.id::character varying(16) AS presszone_type
           FROM presszone
             LEFT JOIN typevalue t ON t.id::text = presszone.presszone_type AND t.typevalue::text = 'presszone_type'::text
        ), dqa_table AS (
         SELECT dqa.dqa_id,
            dqa.stylesheet,
            t.id::character varying(16) AS dqa_type,
            dqa.macrodqa_id
           FROM dqa
             LEFT JOIN typevalue t ON t.id::text = dqa.dqa_type::text AND t.typevalue::text = 'dqa_type'::text
        ), supplyzone_table AS (
         SELECT supplyzone.supplyzone_id,
            supplyzone.stylesheet,
            t.id::character varying(16) AS supplyzone_type
           FROM supplyzone
             LEFT JOIN typevalue t ON t.id::text = supplyzone.supplyzone_type::text AND t.typevalue::text = 'supplyzone_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            t.id::character varying(16) AS omzone_type,
            omzone.macroomzone_id
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
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
    n.depth,
    cat_node.node_type,
    cat_feature.feature_class AS sys_type,
    n.nodecat_id,
    cat_node.matcat_id AS cat_matcat_id,
    cat_node.pnom AS cat_pnom,
    cat_node.dnom AS cat_dnom,
    cat_node.dint AS cat_dint,
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
    n.supplyzone_id,
    supplyzone_table.supplyzone_type,
    n.presszone_id,
    presszone_table.presszone_type,
    presszone_table.presszone_head,
    n.dma_id,
    dma_table.macrodma_id,
    dma_table.dma_type,
    n.dqa_id,
    dqa_table.macrodqa_id,
    dqa_table.dqa_type,
    n.omzone_id,
    omzone_table.macroomzone_id,
    omzone_table.omzone_type,
    n.minsector_id,
    n.pavcat_id,
    n.soilcat_id,
    n.function_type,
    n.category_type,
    n.location_type,
    n.fluid_type,
    n.staticpressure,
    n.annotation,
    n.observ,
    n.comment,
    n.descript,
    concat(cat_feature.link_path, n.link) AS link,
    n.num_value,
    n.district_id,
    n.streetaxis_id,
    n.postcode,
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
    n.accessibility,
    n.om_state,
    n.conserv_state,
    n.access_type,
    n.placement_type,
    COALESCE(n.brand_id, cat_node.brand_id) AS brand_id,
    COALESCE(n.model_id, cat_node.model_id) AS model_id,
    n.serial_number,
    n.asset_id,
    n.adate,
    n.adescript,
    n.verified,
    n.datasource,
    n.hemisphere,
    cat_node.label,
    n.label_x,
    n.label_y,
    n.label_rotation,
    n.rotation,
    n.label_quadrant,
    cat_node.svg,
    n.inventory,
    n.publish,
    vst.is_operative,
    n.is_scadamap,
        CASE
            WHEN n.sector_id > 0 AND vst.is_operative = true AND n.epa_type::text <> 'UNDEFINED'::text THEN n.epa_type::text
            ELSE NULL::text
        END AS inp_type,
    node_add.demand_max,
    node_add.demand_min,
    node_add.demand_avg,
    node_add.press_max,
    node_add.press_min,
    node_add.press_avg,
    node_add.head_max,
    node_add.head_min,
    node_add.head_avg,
    node_add.quality_max,
    node_add.quality_min,
    node_add.quality_avg,
    node_add.result_id,
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    dma_table.stylesheet ->> 'featureColor'::text AS dma_style,
    presszone_table.stylesheet ->> 'featureColor'::text AS presszone_style,
    dqa_table.stylesheet ->> 'featureColor'::text AS dqa_style,
    supplyzone_table.stylesheet ->> 'featureColor'::text AS supplyzone_style,
    n.lock_level,
    n.expl_visibility,
    ( SELECT st_x(n.the_geom) AS st_x) AS xcoord,
    ( SELECT st_y(n.the_geom) AS st_y) AS ycoord,
    ( SELECT st_y(st_transform(n.the_geom, 4326)) AS st_y) AS lat,
    ( SELECT st_x(st_transform(n.the_geom, 4326)) AS st_x) AS long,
    m.closed AS closed_valve,
    m.broken AS broken_valve,
    date_trunc('second'::text, n.created_at) AS created_at,
    n.created_by,
    date_trunc('second'::text, n.updated_at) AS updated_at,
    n.updated_by,
    n.the_geom,
    COALESCE(vf.p_state, n.state) AS p_state,
    n.uuid,
    n.uncertain,
    n.xyz_date,
    m.to_arc,
    sva.sector_visibility,
    mva.muni_visibility
  FROM node n
  JOIN vf_node vf on vf.node_id = n.node_id
  JOIN cat_node ON cat_node.id::text = n.nodecat_id::text
  JOIN cat_feature ON cat_feature.id::text = cat_node.node_type::text
  JOIN value_state_type vst ON vst.id = n.state_type
  JOIN exploitation ON n.expl_id = exploitation.expl_id
  JOIN v_municipality vm ON n.muni_id = vm.muni_id
  JOIN sector_table ON sector_table.sector_id = n.sector_id
  LEFT JOIN presszone_table ON presszone_table.presszone_id = n.presszone_id
  LEFT JOIN dma_table ON dma_table.dma_id = n.dma_id
  LEFT JOIN dqa_table ON dqa_table.dqa_id = n.dqa_id
  LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = n.supplyzone_id
  LEFT JOIN omzone_table ON omzone_table.omzone_id = n.omzone_id
  LEFT JOIN node_add ON node_add.node_id = n.node_id
  LEFT JOIN man_valve m ON m.node_id = n.node_id
  LEFT JOIN sector_visibility_agg sva ON sva.node_id = n.node_id
  LEFT JOIN muni_visibility_agg mva ON mva.node_id = n.node_id;

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
    inp_valve.valve_type,
    inp_valve.setting,
    inp_valve.curve_id,
    inp_valve.minorloss,
    n.to_arc,
		CASE
            WHEN n.closed_valve IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN n.broken_valve IS FALSE AND (n.to_arc IS NOT NULL OR inp_valve.valve_type::text = 'TCV'::text) THEN 'ACTIVE'::character varying(12)
            ELSE 'OPEN'::character varying(12)
        END AS status,
    n.cat_dint,
    inp_valve.custom_dint,
    inp_valve.add_settings,
    inp_valve.init_quality,
    inp_valve.head,
    inp_valve.pattern_id,
    inp_valve.demand,
    inp_valve.demand_pattern_id,
    inp_valve.emitter_coeff,
    n.the_geom
   FROM ve_node n
     JOIN inp_valve USING (node_id)
  WHERE n.is_operative IS TRUE;



CREATE OR REPLACE VIEW ve_arc AS
WITH typevalue AS (
         SELECT edit_typevalue.typevalue,
            edit_typevalue.id,
            edit_typevalue.idval
           FROM edit_typevalue
          WHERE edit_typevalue.typevalue::text = ANY (ARRAY['sector_type'::text, 'presszone_type'::text, 'dma_type'::text, 'dqa_type'::text, 'supplyzone_type'::text, 'omzone_type'::text])
        ), sector_table AS (
         SELECT sector.sector_id,
            sector.macrosector_id,
            sector.stylesheet,
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), dma_table AS (
         SELECT dma.dma_id,
            dma.macrodma_id,
            dma.stylesheet,
            t.id::character varying(16) AS dma_type
           FROM dma
             LEFT JOIN typevalue t ON t.id::text = dma.dma_type::text AND t.typevalue::text = 'dma_type'::text
        ), presszone_table AS (
         SELECT presszone.presszone_id,
            presszone.head AS presszone_head,
            presszone.stylesheet,
            t.id::character varying(16) AS presszone_type
           FROM presszone
             LEFT JOIN typevalue t ON t.id::text = presszone.presszone_type AND t.typevalue::text = 'presszone_type'::text
        ), dqa_table AS (
         SELECT dqa.dqa_id,
            dqa.stylesheet,
            t.id::character varying(16) AS dqa_type,
            dqa.macrodqa_id
           FROM dqa
             LEFT JOIN typevalue t ON t.id::text = dqa.dqa_type::text AND t.typevalue::text = 'dqa_type'::text
        ), supplyzone_table AS (
         SELECT supplyzone.supplyzone_id,
            supplyzone.stylesheet,
            t.id::character varying(16) AS supplyzone_type
           FROM supplyzone
             LEFT JOIN typevalue t ON t.id::text = supplyzone.supplyzone_type::text AND t.typevalue::text = 'supplyzone_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            t.id::character varying(16) AS omzone_type,
            omzone.macroomzone_id
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        )
 SELECT a.arc_id,
    a.code,
    a.sys_code,
    a.node_1,
    a.nodetype_1,
    a.elevation1,
    a.depth1,
    a.staticpressure1,
    a.node_2,
    a.nodetype_2,
    a.staticpressure2,
    a.elevation2,
    a.depth2,
    ((COALESCE(a.depth1) + COALESCE(a.depth2)) / 2::numeric)::numeric(12,2) AS depth,
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
    a.uncertain
  FROM arc a
  JOIN vf_arc vf on vf.arc_id = a.arc_id
  JOIN cat_arc ON cat_arc.id::text = a.arccat_id::text
  JOIN cat_feature ON cat_feature.id::text = cat_arc.arc_type::text
  JOIN exploitation ON a.expl_id = exploitation.expl_id
  JOIN v_municipality vm ON a.muni_id = vm.muni_id
  JOIN sector_table ON sector_table.sector_id = a.sector_id
  LEFT JOIN presszone_table ON presszone_table.presszone_id = a.presszone_id
  LEFT JOIN dma_table ON dma_table.dma_id = a.dma_id
  LEFT JOIN dqa_table ON dqa_table.dqa_id = a.dqa_id
  LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = a.supplyzone_id
  LEFT JOIN omzone_table ON omzone_table.omzone_id = a.omzone_id
  LEFT JOIN arc_add ON arc_add.arc_id = a.arc_id
  LEFT JOIN value_state_type vst ON vst.id = a.state_type;


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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), dma_table AS (
         SELECT dma.dma_id,
            dma.macrodma_id,
            dma.stylesheet,
            t.id::character varying(16) AS dma_type
           FROM dma
             LEFT JOIN typevalue t ON t.id::text = dma.dma_type::text AND t.typevalue::text = 'dma_type'::text
        ), presszone_table AS (
         SELECT presszone.presszone_id,
            presszone.head AS presszone_head,
            presszone.stylesheet,
            t.id::character varying(16) AS presszone_type
           FROM presszone
             LEFT JOIN typevalue t ON t.id::text = presszone.presszone_type AND t.typevalue::text = 'presszone_type'::text
        ), dqa_table AS (
         SELECT dqa.dqa_id,
            dqa.stylesheet,
            t.id::character varying(16) AS dqa_type,
            dqa.macrodqa_id
           FROM dqa
             LEFT JOIN typevalue t ON t.id::text = dqa.dqa_type::text AND t.typevalue::text = 'dqa_type'::text
        ), supplyzone_table AS (
         SELECT supplyzone.supplyzone_id,
            supplyzone.stylesheet,
            t.id::character varying(16) AS supplyzone_type
           FROM supplyzone
             LEFT JOIN typevalue t ON t.id::text = supplyzone.supplyzone_type::text AND t.typevalue::text = 'supplyzone_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            t.id::character varying(16) AS omzone_type,
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
    vf.arc_id,
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
    dma_table.dma_type::character varying AS dma_type,
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
    vf.pjoint_id,
    vf.pjoint_type,
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
    c.xyz_date
  FROM connec c
  JOIN vf_connec vf on vf.connec_id = c.connec_id
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


CREATE OR REPLACE VIEW v_rtc_hydrometer_x_node
AS WITH sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        )
 SELECT ext_rtc_hydrometer.hydrometer_id,
    ext_rtc_hydrometer.code AS hydrometer_customer_code,
    COALESCE(node.node_id, NULL::integer) AS node_id,
    COALESCE(ext_rtc_hydrometer.customer_code::character varying, 'XXXX'::character varying) AS node_customer_code,
    ext_rtc_hydrometer_state.name AS state,
    v_municipality.name AS muni_name,
    node.expl_id,
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
     JOIN man_netwjoin ON man_netwjoin.customer_code::text = ext_rtc_hydrometer.customer_code::text
     JOIN node ON node.node_id = man_netwjoin.node_id
     LEFT JOIN v_municipality ON v_municipality.muni_id = node.muni_id
     LEFT JOIN exploitation ON exploitation.expl_id = node.expl_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = node.expl_id));



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
        END AS hydrometer_link,
    ext_rtc_hydrometer_state.is_operative,
    ext_rtc_hydrometer.shutdown_date
   FROM ext_rtc_hydrometer
     JOIN ext_rtc_hydrometer_state ON ext_rtc_hydrometer_state.id = ext_rtc_hydrometer.state_id
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     LEFT JOIN v_municipality ON v_municipality.muni_id = connec.muni_id
     LEFT JOIN exploitation ON exploitation.expl_id = connec.expl_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = connec.expl_id));



CREATE OR REPLACE VIEW v_rtc_hydrometer
AS WITH sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        ), node_data AS (
         SELECT ext_rtc_hydrometer.hydrometer_id,
            node.node_id,
            node.expl_id,
            exploitation.name AS expl_name,
            v_municipality.name AS muni_name
           FROM ext_rtc_hydrometer
             JOIN man_netwjoin ON man_netwjoin.customer_code::text = ext_rtc_hydrometer.customer_code::text
             JOIN node ON node.node_id = man_netwjoin.node_id
             LEFT JOIN v_municipality ON v_municipality.muni_id = node.muni_id
             LEFT JOIN exploitation ON exploitation.expl_id = node.expl_id
        ), connec_data AS (
         SELECT ext_rtc_hydrometer.hydrometer_id,
            connec.connec_id,
            connec.expl_id,
            exploitation.name AS expl_name,
            v_municipality.name AS muni_name
           FROM ext_rtc_hydrometer
             JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
             LEFT JOIN v_municipality ON v_municipality.muni_id = connec.muni_id
             LEFT JOIN exploitation ON exploitation.expl_id = connec.expl_id
        ), feature_data AS (
         SELECT connec_data.hydrometer_id,
            connec_data.connec_id AS feature_id,
            'CONNEC'::text AS feature_type,
            connec_data.expl_name,
            connec_data.muni_name,
            connec_data.expl_id
           FROM connec_data
        UNION
         SELECT node_data.hydrometer_id,
            node_data.node_id AS feature_id,
            'NODE'::text AS feature_type,
            node_data.expl_name,
            node_data.muni_name,
            node_data.expl_id
           FROM node_data
        )
 SELECT ext_rtc_hydrometer.hydrometer_id,
    ext_rtc_hydrometer.code AS hydrometer_customer_code,
    d.feature_id,
    d.feature_type,
    COALESCE(ext_rtc_hydrometer.customer_code, 'XXXX'::character varying(30)) AS customer_code,
    ext_rtc_hydrometer_state.name AS state,
    d.muni_name,
    d.expl_id,
    d.expl_name,
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
   FROM feature_data d
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer.hydrometer_id = d.hydrometer_id
     JOIN ext_rtc_hydrometer_state ON ext_rtc_hydrometer_state.id = ext_rtc_hydrometer.state_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = d.expl_id));



CREATE OR REPLACE VIEW v_ui_hydrometer
AS SELECT v_rtc_hydrometer.hydrometer_id,
    v_rtc_hydrometer.feature_id,
    v_rtc_hydrometer.hydrometer_customer_code,
    v_rtc_hydrometer.customer_code AS feature_customer_code,
    v_rtc_hydrometer.state,
    v_rtc_hydrometer.expl_name,
    v_rtc_hydrometer.hydrometer_link
   FROM v_rtc_hydrometer;


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
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer_x_data.hydrometer_id = ext_rtc_hydrometer.hydrometer_id
     LEFT JOIN ext_cat_hydrometer ON ext_cat_hydrometer.id::text = ext_rtc_hydrometer.catalog_id::text
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     LEFT JOIN crm_typevalue crmtype ON ext_rtc_hydrometer_x_data.value_type = crmtype.id::integer AND crmtype.typevalue::text = 'crm_value_type'::text
     LEFT JOIN crm_typevalue crmstatus ON ext_rtc_hydrometer_x_data.value_status = crmstatus.id::integer AND crmstatus.typevalue::text = 'crm_value_status'::text
     LEFT JOIN crm_typevalue crmstate ON ext_rtc_hydrometer_x_data.value_state = crmstate.id::integer AND crmstate.typevalue::text = 'crm_value_state'::text
  ORDER BY ext_rtc_hydrometer_x_data.id;


CREATE OR REPLACE VIEW v_ui_hydroval
AS SELECT ext_rtc_hydrometer_x_data.id,
    node.node_id AS feature_id,
    node.arc_id,
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
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer_x_data.hydrometer_id = ext_rtc_hydrometer.hydrometer_id
     LEFT JOIN ext_cat_hydrometer ON ext_cat_hydrometer.id::text = ext_rtc_hydrometer.catalog_id::text
     JOIN man_netwjoin ON man_netwjoin.customer_code::text = ext_rtc_hydrometer.customer_code::text
     JOIN node ON node.node_id = man_netwjoin.node_id
     LEFT JOIN crm_typevalue crmtype ON ext_rtc_hydrometer_x_data.value_type = crmtype.id::integer AND crmtype.typevalue::text = 'crm_value_type'::text
     LEFT JOIN crm_typevalue crmstatus ON ext_rtc_hydrometer_x_data.value_status = crmstatus.id::integer AND crmstatus.typevalue::text = 'crm_value_status'::text
     LEFT JOIN crm_typevalue crmstate ON ext_rtc_hydrometer_x_data.value_state = crmstate.id::integer AND crmstate.typevalue::text = 'crm_value_state'::text
UNION
 SELECT ext_rtc_hydrometer_x_data.id,
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
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer_x_data.hydrometer_id = ext_rtc_hydrometer.hydrometer_id
     LEFT JOIN ext_cat_hydrometer ON ext_cat_hydrometer.id::text = ext_rtc_hydrometer.catalog_id::text
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     LEFT JOIN crm_typevalue crmtype ON ext_rtc_hydrometer_x_data.value_type = crmtype.id::integer AND crmtype.typevalue::text = 'crm_value_type'::text
     LEFT JOIN crm_typevalue crmstatus ON ext_rtc_hydrometer_x_data.value_status = crmstatus.id::integer AND crmstatus.typevalue::text = 'crm_value_status'::text
     LEFT JOIN crm_typevalue crmstate ON ext_rtc_hydrometer_x_data.value_state = crmstate.id::integer AND crmstate.typevalue::text = 'crm_value_state'::text;


CREATE OR REPLACE VIEW v_om_mincut
AS WITH sel_mincut_result AS (
         SELECT selector_mincut_result.result_id
           FROM selector_mincut_result
          WHERE selector_mincut_result.cur_user = CURRENT_USER
        )
 SELECT om_mincut.id,
    om_mincut.work_order,
    a.idval AS state,
    b.idval AS class,
    om_mincut.mincut_type,
    om_mincut.received_date,
    om_mincut.expl_id,
    exploitation.name AS expl_name,
    macroexploitation.name AS macroexpl_name,
    om_mincut.macroexpl_id,
    om_mincut.muni_id,
    v_municipality.name AS muni_name,
    om_mincut.postcode,
    om_mincut.streetaxis_id,
    v_streetaxis.name AS street_name,
    om_mincut.postnumber,
    c.idval AS anl_cause,
    om_mincut.anl_tstamp,
    om_mincut.anl_user,
    om_mincut.anl_descript,
    om_mincut.anl_feature_id,
    om_mincut.anl_feature_type,
    om_mincut.anl_the_geom,
    om_mincut.forecast_start,
    om_mincut.forecast_end,
    om_mincut.assigned_to,
    om_mincut.exec_start,
    om_mincut.exec_end,
    om_mincut.exec_user,
    om_mincut.exec_descript,
    om_mincut.exec_the_geom,
    om_mincut.exec_from_plot,
    om_mincut.exec_depth,
    om_mincut.exec_appropiate,
    om_mincut.chlorine,
    om_mincut.turbidity,
    om_mincut.notified,
    om_mincut.output,
    om_mincut.reagent_lot,
    om_mincut.equipment_code,
    om_mincut.shutoff_required
   FROM om_mincut
     LEFT JOIN om_typevalue a ON a.id::integer = om_mincut.mincut_state AND a.typevalue = 'mincut_state'::text
     LEFT JOIN om_typevalue b ON b.id::integer = om_mincut.mincut_class AND b.typevalue = 'mincut_class'::text
     LEFT JOIN om_typevalue c ON c.id::integer = om_mincut.anl_cause::integer AND c.typevalue = 'mincut_cause'::text
     LEFT JOIN exploitation ON om_mincut.expl_id = exploitation.expl_id
     LEFT JOIN v_streetaxis ON om_mincut.streetaxis_id::text = v_streetaxis.id::text
     LEFT JOIN macroexploitation ON om_mincut.macroexpl_id = macroexploitation.macroexpl_id
     LEFT JOIN v_municipality ON om_mincut.muni_id = v_municipality.muni_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_mincut_result
          WHERE sel_mincut_result.result_id = om_mincut.id)) AND om_mincut.id > 0;


CREATE OR REPLACE VIEW v_om_mincut_initpoint
AS WITH sel_mincut_result AS (
         SELECT selector_mincut_result.result_id,
            selector_mincut_result.result_type
           FROM selector_mincut_result
          WHERE selector_mincut_result.cur_user = CURRENT_USER
        )
 SELECT om.id,
    om.work_order,
    a.idval AS state,
    b.idval AS class,
    om.mincut_type,
    om.received_date,
    om.expl_id,
    exploitation.name AS expl_name,
    macroexploitation.name AS macroexpl_name,
    om.macroexpl_id,
    om.muni_id,
    v_municipality.name AS muni_name,
    om.postcode,
    om.streetaxis_id,
    v_streetaxis.name AS street_name,
    om.postnumber,
    c.idval AS anl_cause,
    om.anl_tstamp,
    om.anl_user,
    om.anl_descript,
    om.anl_feature_id,
    om.anl_feature_type,
    om.anl_the_geom,
    om.forecast_start,
    om.forecast_end,
    om.assigned_to,
    om.exec_start,
    om.exec_end,
    om.exec_user,
    om.exec_descript,
    om.exec_from_plot,
    om.exec_depth,
    om.exec_appropiate,
    om.notified,
    om.output,
    sm.result_type,
    om.shutoff_required
   FROM om_mincut om
     LEFT JOIN om_typevalue a ON a.id::integer = om.mincut_state AND a.typevalue = 'mincut_state'::text
     LEFT JOIN om_typevalue b ON b.id::integer = om.mincut_class AND b.typevalue = 'mincut_class'::text
     LEFT JOIN om_typevalue c ON c.id::integer = om.anl_cause::integer AND c.typevalue = 'mincut_cause'::text
     LEFT JOIN exploitation ON om.expl_id = exploitation.expl_id
     LEFT JOIN v_streetaxis ON om.streetaxis_id::text = v_streetaxis.id::text
     LEFT JOIN macroexploitation ON om.macroexpl_id = macroexploitation.macroexpl_id
     LEFT JOIN v_municipality ON om.muni_id = v_municipality.muni_id
     LEFT JOIN sel_mincut_result sm ON sm.result_id = om.id AND om.id > 0;



CREATE OR REPLACE VIEW v_om_mincut_polygon
AS WITH sel_mincut_result AS (
         SELECT selector_mincut_result.result_id
           FROM selector_mincut_result
          WHERE selector_mincut_result.cur_user = CURRENT_USER
        )
 SELECT om_mincut.id,
    om_mincut.work_order,
    a.idval AS state,
    b.idval AS class,
    om_mincut.mincut_type,
    om_mincut.received_date,
    om_mincut.expl_id,
    exploitation.name AS expl_name,
    macroexploitation.name AS macroexpl_name,
    om_mincut.macroexpl_id,
    om_mincut.muni_id,
    v_municipality.name AS muni_name,
    om_mincut.postcode,
    om_mincut.streetaxis_id,
    v_streetaxis.name AS street_name,
    om_mincut.postnumber,
    c.idval AS anl_cause,
    om_mincut.anl_tstamp,
    om_mincut.anl_user,
    om_mincut.anl_descript,
    om_mincut.anl_feature_id,
    om_mincut.anl_feature_type,
    om_mincut.anl_the_geom,
    om_mincut.forecast_start,
    om_mincut.forecast_end,
    om_mincut.assigned_to,
    om_mincut.exec_start,
    om_mincut.exec_end,
    om_mincut.exec_user,
    om_mincut.exec_descript,
    om_mincut.exec_the_geom,
    om_mincut.exec_from_plot,
    om_mincut.exec_depth,
    om_mincut.exec_appropiate,
    om_mincut.chlorine,
    om_mincut.turbidity,
    om_mincut.notified,
    om_mincut.output,
    om_mincut.reagent_lot,
    om_mincut.equipment_code,
    om_mincut.polygon_the_geom,
    om_mincut.shutoff_required
   FROM om_mincut
     LEFT JOIN om_typevalue a ON a.id::integer = om_mincut.mincut_state AND a.typevalue = 'mincut_state'::text
     LEFT JOIN om_typevalue b ON b.id::integer = om_mincut.mincut_class AND b.typevalue = 'mincut_class'::text
     LEFT JOIN om_typevalue c ON c.id::integer = om_mincut.anl_cause::integer AND c.typevalue = 'mincut_cause'::text
     LEFT JOIN exploitation ON om_mincut.expl_id = exploitation.expl_id
     LEFT JOIN v_streetaxis ON om_mincut.streetaxis_id::text = v_streetaxis.id::text
     LEFT JOIN macroexploitation ON om_mincut.macroexpl_id = macroexploitation.macroexpl_id
     LEFT JOIN v_municipality ON om_mincut.muni_id = v_municipality.muni_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_mincut_result
          WHERE sel_mincut_result.result_id = om_mincut.id)) AND om_mincut.id > 0;


CREATE OR REPLACE VIEW v_ui_mincut
AS SELECT om_mincut.id,
    om_mincut.work_order,
    a.idval AS state,
    b.idval AS class,
    om_mincut.mincut_type,
    om_mincut.received_date,
    exploitation.name AS exploitation,
    v_municipality.name AS municipality,
    om_mincut.postcode,
    v_streetaxis.name AS streetaxis,
    om_mincut.postnumber,
    c.idval AS anl_cause,
    om_mincut.anl_tstamp,
    om_mincut.anl_user,
    om_mincut.anl_descript,
    om_mincut.anl_feature_id,
    om_mincut.anl_feature_type,
    om_mincut.forecast_start,
    om_mincut.forecast_end,
    cat_users.name AS assigned_to,
    om_mincut.exec_start,
    om_mincut.exec_end,
    om_mincut.exec_user,
    om_mincut.exec_descript,
    om_mincut.exec_from_plot,
    om_mincut.exec_depth,
    om_mincut.exec_appropiate,
    om_mincut.chlorine,
    om_mincut.turbidity,
    om_mincut.notified,
    om_mincut.output,
    om_mincut.reagent_lot,
    om_mincut.equipment_code,
    om_mincut.shutoff_required
   FROM om_mincut
     LEFT JOIN om_typevalue a ON a.id::integer = om_mincut.mincut_state AND a.typevalue = 'mincut_state'::text
     LEFT JOIN om_typevalue b ON b.id::integer = om_mincut.mincut_class AND b.typevalue = 'mincut_class'::text
     LEFT JOIN om_typevalue c ON c.id::integer = om_mincut.anl_cause::integer AND c.typevalue = 'mincut_cause'::text
     LEFT JOIN exploitation ON exploitation.expl_id = om_mincut.expl_id
     LEFT JOIN macroexploitation ON macroexploitation.macroexpl_id = om_mincut.macroexpl_id
     LEFT JOIN v_municipality ON v_municipality.muni_id = om_mincut.muni_id
     LEFT JOIN v_streetaxis ON v_streetaxis.id::text = om_mincut.streetaxis_id::text
     LEFT JOIN cat_users ON cat_users.id::text = om_mincut.assigned_to::text
  WHERE om_mincut.id > 0;


SELECT gw_fct_admin_manage_child_views($${"data":{"action":"MULTI-DELETE"}, "feature":{"parentLayer":"ve_link"}}$$);
DROP VIEW IF EXISTS ve_link;

CREATE OR REPLACE VIEW ve_link
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
            t.id::character varying(16) AS sector_type
           FROM sector
             LEFT JOIN typevalue t ON t.id::text = sector.sector_type::text AND t.typevalue::text = 'sector_type'::text
        ), dma_table AS (
         SELECT dma.dma_id,
            dma.macrodma_id,
            dma.stylesheet,
            t.id::character varying(16) AS dma_type
           FROM dma
             LEFT JOIN typevalue t ON t.id::text = dma.dma_type::text AND t.typevalue::text = 'dma_type'::text
        ), presszone_table AS (
         SELECT presszone.presszone_id,
            presszone.head AS presszone_head,
            presszone.stylesheet,
            t.id::character varying(16) AS presszone_type
           FROM presszone
             LEFT JOIN typevalue t ON t.id::text = presszone.presszone_type AND t.typevalue::text = 'presszone_type'::text
        ), dqa_table AS (
         SELECT dqa.dqa_id,
            dqa.stylesheet,
            t.id::character varying(16) AS dqa_type,
            dqa.macrodqa_id
           FROM dqa
             LEFT JOIN typevalue t ON t.id::text = dqa.dqa_type::text AND t.typevalue::text = 'dqa_type'::text
        ), supplyzone_table AS (
         SELECT supplyzone.supplyzone_id,
            supplyzone.stylesheet,
            t.id::character varying(16) AS supplyzone_type
           FROM supplyzone
             LEFT JOIN typevalue t ON t.id::text = supplyzone.supplyzone_type::text AND t.typevalue::text = 'supplyzone_type'::text
        ), omzone_table AS (
         SELECT omzone.omzone_id,
            t.id::character varying(16) AS omzone_type,
            omzone.macroomzone_id,
            omzone.stylesheet
           FROM omzone
             LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type::text AND t.typevalue::text = 'omzone_type'::text
        ), inp_network_mode AS (
         SELECT config_param_user.value
           FROM config_param_user
          WHERE config_param_user.parameter::text = 'inp_options_networkmode'::text AND config_param_user.cur_user::text = CURRENT_USER
        )
 SELECT l.link_id,
    l.code,
    l.sys_code,
    l.top_elev1,
    l.depth1,
        CASE
            WHEN l.top_elev1 IS NULL OR l.depth1 IS NULL THEN NULL::double precision
            ELSE l.top_elev1 - l.depth1::double precision
        END AS elevation1,
    l.exit_id,
    l.exit_type,
    l.top_elev2,
    l.depth2,
        CASE
            WHEN l.top_elev2 IS NULL OR l.depth2 IS NULL THEN NULL::double precision
            ELSE l.top_elev2 - l.depth2::double precision
        END AS elevation2,
    l.feature_type,
    l.feature_id,
    cat_link.link_type,
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
    l.supplyzone_id,
    supplyzone_table.supplyzone_type,
    l.presszone_id,
    presszone_table.presszone_type,
    presszone_table.presszone_head,
    l.dma_id,
    dma_table.macrodma_id,
    dma_table.dma_type,
    l.dqa_id,
    dqa_table.macrodqa_id,
    dqa_table.dqa_type,
    l.omzone_id,
    omzone_table.macroomzone_id,
    omzone_table.omzone_type,
    l.minsector_id,
    l.location_type,
    l.fluid_type,
    l.custom_length,
    st_length(l.the_geom)::numeric(12,3) AS gis_length,
    l.staticpressure1,
    l.staticpressure2,
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
    l.verified,
    l.uncertain,
    l.userdefined_geom,
    l.datasource,
    l.is_operative,
    sector_table.stylesheet ->> 'featureColor'::text AS sector_style,
    omzone_table.stylesheet ->> 'featureColor'::text AS omzone_style,
    dma_table.stylesheet ->> 'featureColor'::text AS dma_style,
    presszone_table.stylesheet ->> 'featureColor'::text AS presszone_style,
    dqa_table.stylesheet ->> 'featureColor'::text AS dqa_style,
    supplyzone_table.stylesheet ->> 'featureColor'::text AS supplyzone_style,
        CASE
            WHEN l.sector_id > 0 AND l.is_operative = true AND c.epa_type = 'JUNCTION'::text AND inp_network_mode.value = '4'::text THEN c.epa_type
            ELSE NULL::text
        END AS inp_type,
    l.lock_level,
    l.expl_visibility,
    l.created_at,
    l.created_by,
    l.updated_at,
    l.updated_by,
    l.the_geom,
    vf.p_state,
    l.uuid
  FROM link l
  JOIN vf_link vf on vf.link_id = l.link_id
  LEFT JOIN connec c ON c.connec_id = l.feature_id
  JOIN sector_table ON sector_table.sector_id = l.sector_id
  JOIN cat_link ON cat_link.id::text = l.linkcat_id::text
  JOIN cat_feature ON cat_feature.id::text = cat_link.link_type::text
  JOIN exploitation ON l.expl_id = exploitation.expl_id
  LEFT JOIN presszone_table ON presszone_table.presszone_id = l.presszone_id
  LEFT JOIN dma_table ON dma_table.dma_id = l.dma_id
  LEFT JOIN dqa_table ON dqa_table.dqa_id = l.dqa_id
  LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = l.supplyzone_id
  LEFT JOIN omzone_table ON omzone_table.omzone_id = l.omzone_id
  LEFT JOIN inp_network_mode ON true;


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
  WHERE element.state = 0;







CREATE OR REPLACE VIEW ve_inp_connec
AS SELECT ve_connec.connec_id,
    ve_connec.top_elev,
    ve_connec.depth,
    ve_connec.conneccat_id,
    ve_connec.arc_id,
    ve_connec.expl_id,
    ve_connec.sector_id,
    ve_connec.dma_id,
    ve_connec.state,
    ve_connec.state_type,
    ve_connec.pjoint_type,
    ve_connec.pjoint_id,
    ve_connec.annotation,
    inp_connec.demand,
    inp_connec.pattern_id,
    inp_connec.peak_factor,
    inp_connec.status,
    inp_connec.minorloss,
    inp_connec.custom_roughness,
    inp_connec.custom_length,
    inp_connec.custom_dint,
    inp_connec.emitter_coeff,
    inp_connec.init_quality,
    inp_connec.source_type,
    inp_connec.source_quality,
    inp_connec.source_pattern_id,
    ve_connec.the_geom
   FROM ve_connec
     JOIN inp_connec USING (connec_id)
  WHERE ve_connec.is_operative IS TRUE;



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
    connec.the_geom
   FROM ve_inp_connec connec
     JOIN inp_dscenario_connec c USING (connec_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE (EXISTS ( SELECT 1
           FROM selector_inp_dscenario s
          WHERE s.dscenario_id = c.dscenario_id AND s.cur_user = CURRENT_USER));



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


CREATE OR REPLACE VIEW v_plan_arc
AS SELECT arc_id,
    node_1,
    node_2,
    arc_type,
    arccat_id,
    epa_type,
    state,
    sector_id,
    expl_id,
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
    total_budget,
    the_geom
   FROM ( WITH v_plan_aux_arc_cost AS (
                 WITH v_plan_aux_arc_ml AS (
                         SELECT ve_arc.arc_id,
                            ve_arc.depth1,
                            ve_arc.depth2,
                                CASE
                                    WHEN (ve_arc.depth1 * ve_arc.depth2) = 0::numeric OR (ve_arc.depth1 * ve_arc.depth2) IS NULL THEN v_price_x_catarc.estimated_depth
                                    ELSE ((ve_arc.depth1 + ve_arc.depth2) / 2::numeric)::numeric(12,2)
                                END AS mean_depth,
                            ve_arc.arccat_id,
                            COALESCE(v_price_x_catarc.dint / 1000::numeric, 0::numeric)::numeric(12,4) AS dint,
                            COALESCE(v_price_x_catarc.z1, 0::numeric)::numeric(12,2) AS z1,
                            COALESCE(v_price_x_catarc.z2, 0::numeric)::numeric(12,2) AS z2,
                            COALESCE(v_price_x_catarc.area, 0::numeric)::numeric(12,4) AS area,
                            COALESCE(v_price_x_catarc.width, 0::numeric)::numeric(12,2) AS width,
                            COALESCE(v_price_x_catarc.thickness / 1000::numeric, 0::numeric)::numeric(12,4) AS bulk,
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
                    v_plan_aux_arc_ml.depth1,
                    v_plan_aux_arc_ml.depth2,
                    v_plan_aux_arc_ml.mean_depth,
                    v_plan_aux_arc_ml.arccat_id,
                    v_plan_aux_arc_ml.dint,
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
                    (2::numeric * ((v_plan_aux_arc_ml.mean_depth + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric)::numeric(12,3) AS m2mlpavement,
                    (2::numeric * v_plan_aux_arc_ml.b + v_plan_aux_arc_ml.width)::numeric(12,3) AS m2mlbase,
                    (v_plan_aux_arc_ml.mean_depth + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness)::numeric(12,3) AS calculed_depth,
                    (v_plan_aux_arc_ml.trenchlining * 2::numeric * (v_plan_aux_arc_ml.mean_depth + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness))::numeric(12,3) AS m2mltrenchl,
                    ((v_plan_aux_arc_ml.mean_depth + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) * (2::numeric * ((v_plan_aux_arc_ml.mean_depth + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width) / 2::numeric)::numeric(12,3) AS m3mlexc,
                    ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.dint + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) * ((2::numeric * ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.dint + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + (v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width)) / 2::numeric) - v_plan_aux_arc_ml.area)::numeric(12,3) AS m3mlprotec,
                    ((v_plan_aux_arc_ml.mean_depth + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) * (2::numeric * ((v_plan_aux_arc_ml.mean_depth + v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.bulk - v_plan_aux_arc_ml.thickness) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width) / 2::numeric - (v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.dint + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) * ((2::numeric * ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.dint + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + (v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width)) / 2::numeric))::numeric(12,3) AS m3mlfill,
                    ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.dint + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) * ((2::numeric * ((v_plan_aux_arc_ml.z1 + v_plan_aux_arc_ml.dint + v_plan_aux_arc_ml.bulk * 2::numeric + v_plan_aux_arc_ml.z2) / v_plan_aux_arc_ml.y_param) + v_plan_aux_arc_ml.width + v_plan_aux_arc_ml.b * 2::numeric + (v_plan_aux_arc_ml.b * 2::numeric + v_plan_aux_arc_ml.width)) / 2::numeric))::numeric(12,3) AS m3mlexcess,
                    v_plan_aux_arc_ml.the_geom
                   FROM v_plan_aux_arc_ml
                  WHERE v_plan_aux_arc_ml.arc_id IS NOT NULL
                )
         SELECT v_plan_aux_arc_cost.arc_id,
            arc.node_1,
            arc.node_2,
            v_plan_aux_arc_cost.arccat_id AS arc_type,
            v_plan_aux_arc_cost.arccat_id,
            arc.epa_type,
            v_plan_aux_arc_cost.state,
            arc.sector_id,
            v_plan_aux_arc_cost.expl_id,
            arc.annotation,
            v_plan_aux_arc_cost.soilcat_id,
            v_plan_aux_arc_cost.depth1 AS y1,
            v_plan_aux_arc_cost.depth2 AS y2,
            v_plan_aux_arc_cost.mean_depth AS mean_y,
            v_plan_aux_arc_cost.z1,
            v_plan_aux_arc_cost.z2,
            v_plan_aux_arc_cost.thickness,
            v_plan_aux_arc_cost.width,
            v_plan_aux_arc_cost.b,
            v_plan_aux_arc_cost.bulk,
            v_plan_aux_arc_cost.dint AS geom1,
            v_plan_aux_arc_cost.area,
            v_plan_aux_arc_cost.y_param,
            (v_plan_aux_arc_cost.calculed_depth + v_plan_aux_arc_cost.thickness)::numeric(12,2) AS total_y,
            (v_plan_aux_arc_cost.calculed_depth - 2::numeric * v_plan_aux_arc_cost.bulk - v_plan_aux_arc_cost.z1 - v_plan_aux_arc_cost.z2 - v_plan_aux_arc_cost.dint)::numeric(12,2) AS rec_y,
            (v_plan_aux_arc_cost.dint + 2::numeric * v_plan_aux_arc_cost.bulk)::numeric(12,2) AS geom1_ext,
            v_plan_aux_arc_cost.calculed_depth AS calculed_y,
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
            v_plan_aux_arc_connec.connec_total_cost AS other_budget,
                CASE
                    WHEN v_plan_aux_arc_cost.cost_unit::text = 'u'::text THEN v_plan_aux_arc_cost.arc_cost +
                    CASE
                        WHEN v_plan_aux_arc_connec.connec_total_cost IS NULL THEN 0::numeric
                        ELSE v_plan_aux_arc_connec.connec_total_cost
                    END
                    ELSE st_length2d(v_plan_aux_arc_cost.the_geom)::numeric(12,2) * (v_plan_aux_arc_cost.m3mlexc * v_plan_aux_arc_cost.m3exc_cost + v_plan_aux_arc_cost.m2mlbase * v_plan_aux_arc_cost.m2bottom_cost + v_plan_aux_arc_cost.m2mltrenchl * v_plan_aux_arc_cost.m2trenchl_cost + v_plan_aux_arc_cost.m3mlprotec * v_plan_aux_arc_cost.m3protec_cost + v_plan_aux_arc_cost.m3mlfill * v_plan_aux_arc_cost.m3fill_cost + v_plan_aux_arc_cost.m3mlexcess * v_plan_aux_arc_cost.m3excess_cost + v_plan_aux_arc_cost.m2mlpavement * v_plan_aux_arc_cost.m2pav_cost + v_plan_aux_arc_cost.arc_cost)::numeric(14,2) +
                    CASE
                        WHEN v_plan_aux_arc_connec.connec_total_cost IS NULL THEN 0::numeric
                        ELSE v_plan_aux_arc_connec.connec_total_cost
                    END
                END::numeric(14,2) AS total_budget,
            v_plan_aux_arc_cost.the_geom
           FROM v_plan_aux_arc_cost
             JOIN arc ON arc.arc_id = v_plan_aux_arc_cost.arc_id
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
                 SELECT (v_price_compost.price * count(*)::numeric)::numeric(12,2) AS connec_total_cost
                   FROM vf_connec_arc
                     JOIN arc arc_1 ON arc_1.arc_id = vf_connec_arc.arc_id
                     JOIN cat_arc ON cat_arc.id::text = arc_1.arccat_id::text
                     LEFT JOIN v_price_compost ON cat_arc.connect_cost = v_price_compost.id::text
                  WHERE vf_connec_arc.arc_id = v_plan_aux_arc_cost.arc_id
                  GROUP BY v_price_compost.price) v_plan_aux_arc_connec ON true) d
  WHERE arc_id IS NOT NULL;


CREATE OR REPLACE VIEW v_ui_plan_arc_cost
AS WITH p AS (
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
            a.id,
            a.arc_type,
            a.matcat_id,
            a.pnom,
            a.dnom,
            a.dint,
            a.dext,
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
            a.shape,
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, arc_type_1, matcat_id, pnom, dnom, dint, dext, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
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
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, sector_id, expl_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, act_type, matcat_id, pnom, dnom, dint, dext, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, shape, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN ve_connec USING (arc_id)
     JOIN v_price_compost v ON p.cat_connect_cost = v.id::text
  GROUP BY p.arc_id
  ORDER BY 1, 2;


CREATE OR REPLACE VIEW v_plan_result_arc
AS SELECT plan_rec_result_arc.arc_id,
    plan_rec_result_arc.node_1,
    plan_rec_result_arc.node_2,
    plan_rec_result_arc.arc_type,
    plan_rec_result_arc.arccat_id,
    plan_rec_result_arc.epa_type,
    plan_rec_result_arc.sector_id,
    plan_rec_result_arc.expl_id,
    plan_rec_result_arc.state,
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
  WHERE plan_rec_result_arc.result_id::text = selector_plan_result.result_id::text AND selector_plan_result.cur_user = CURRENT_USER AND plan_rec_result_arc.state = 1
UNION
 SELECT v_plan_arc.arc_id,
    v_plan_arc.node_1,
    v_plan_arc.node_2,
    v_plan_arc.arc_type,
    v_plan_arc.arccat_id,
    v_plan_arc.epa_type,
    v_plan_arc.sector_id,
    v_plan_arc.expl_id,
    v_plan_arc.state,
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
  WHERE config_param_user.cur_user::text = CURRENT_USER AND config_param_user.parameter::text = 'plan_psector_current'::text AND config_param_user.value::integer = plan_psector.psector_id;


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


-- v_plan_psector_all source
CREATE OR REPLACE VIEW v_plan_psector_all
AS WITH sel_psector AS (
         SELECT selector_psector.psector_id
           FROM selector_psector
          WHERE selector_psector.cur_user = CURRENT_USER
        )
 SELECT plan_psector.psector_id,
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
   FROM plan_psector
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
  WHERE (EXISTS ( SELECT 1
           FROM sel_psector
          WHERE sel_psector.psector_id = plan_psector.psector_id));


CREATE OR REPLACE VIEW v_edit_connec
AS WITH sel_state AS (
      	SELECT selector_state.state_id FROM selector_state WHERE selector_state.cur_user = CURRENT_USER
    ),
    sel_sector AS (
		SELECT selector_sector.sector_id FROM selector_sector WHERE selector_sector.cur_user = CURRENT_USER
    ),
    sel_expl AS (
      	SELECT selector_expl.expl_id FROM selector_expl WHERE selector_expl.cur_user = CURRENT_USER
    ),
    sel_muni AS (
      	SELECT selector_municipality.muni_id FROM selector_municipality WHERE selector_municipality.cur_user = CURRENT_USER
    ),
    sel_ps AS (
      	SELECT selector_psector.psector_id FROM selector_psector WHERE selector_psector.cur_user = CURRENT_USER
    ),
    typevalue AS (
		SELECT edit_typevalue.typevalue, edit_typevalue.id, edit_typevalue.idval
		FROM edit_typevalue
		WHERE edit_typevalue.typevalue::text = ANY (ARRAY['sector_type'::text, 'presszone_type'::text, 'dma_type'::text, 'dqa_type'::text, 'supplyzone_type'::text, 'omzone_type'::text])
	),
    sector_table AS (
        SELECT sector_id, macrosector_id, stylesheet, id::varchar(16) AS sector_type
        FROM sector
        LEFT JOIN typevalue t ON t.id::text = sector.sector_type AND t.typevalue::text = 'sector_type'::text
	),
    dma_table AS (
        SELECT dma_id, macrodma_id, stylesheet, id::varchar(16) AS dma_type
        FROM dma
        LEFT JOIN typevalue t ON t.id::text = dma.dma_type AND t.typevalue::text = 'dma_type'::text
	),
    presszone_table AS (
        SELECT presszone_id, head AS presszone_head, stylesheet, id::varchar(16) AS presszone_type
        FROM presszone
        LEFT JOIN typevalue t ON t.id::text = presszone.presszone_type AND t.typevalue::text = 'presszone_type'::text
	),
    dqa_table AS (
        SELECT dqa_id, stylesheet, id::varchar(16) AS dqa_type, macrodqa_id
        FROM dqa
        LEFT JOIN typevalue t ON t.id::text = dqa.dqa_type AND t.typevalue::text = 'dqa_type'::text
	),
    supplyzone_table AS (
        SELECT supplyzone_id, stylesheet, id::varchar(16) AS supplyzone_type
        FROM supplyzone
        LEFT JOIN typevalue t ON t.id::text = supplyzone.supplyzone_type AND t.typevalue::text = 'supplyzone_type'::text
      ),
    omzone_table AS (
        SELECT omzone_id, id::varchar(16) AS omzone_type, macroomzone_id
        FROM omzone
        LEFT JOIN typevalue t ON t.id::text = omzone.omzone_type AND t.typevalue::text = 'omzone_type'::text
	),
    inp_network_mode AS (
        SELECT value FROM config_param_user WHERE parameter::text = 'inp_options_networkmode'::text AND config_param_user.cur_user::text = CURRENT_USER
	),
    link_planned as (
        SELECT link_id, feature_id, feature_type, exit_id, exit_type, l.expl_id, macroexpl_id, l.sector_id, sector_type, macrosector_id,
        l.dma_id, dma_type, l.omzone_id, omzone_type, macrodma_id, l.presszone_id, presszone_type, presszone_head, l.dqa_id, dqa_type, dqa_table.macrodqa_id,
        l.supplyzone_id, supplyzone_type, fluid_type,
        minsector_id, staticpressure1 AS staticpressure
        FROM link l
        JOIN exploitation USING (expl_id)
        JOIN sector_table ON sector_table.sector_id = l.sector_id
        LEFT JOIN presszone_table ON presszone_table.presszone_id = l.presszone_id
        LEFT JOIN dma_table ON dma_table.dma_id = l.dma_id
        LEFT JOIN dqa_table ON dqa_table.dqa_id = l.dqa_id
        LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = l.supplyzone_id
        LEFT JOIN omzone_table ON omzone_table.omzone_id = l.omzone_id
        WHERE l.state = 2
	),
    connec_psector AS (
        SELECT DISTINCT ON (pp.connec_id, pp.state) pp.connec_id, pp.state AS p_state, pp.psector_id, pp.arc_id, pp.link_id
        FROM plan_psector_x_connec pp
        JOIN selector_psector sp ON sp.cur_user = current_user AND sp.psector_id = pp.psector_id
        ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST
	),
    connec_selector AS (
        SELECT c.connec_id, c.arc_id, NULL::integer AS link_id
        FROM connec c
		WHERE EXISTS ((SELECT 1 FROM sel_state s WHERE s.state_id = c.state))
		AND EXISTS ((SELECT 1 FROM sel_sector s WHERE s.sector_id = c.sector_id))
		AND EXISTS ((SELECT 1 FROM sel_expl s WHERE s.expl_id = ANY (array_append(expl_visibility, c.expl_id))))
		AND EXISTS ((SELECT 1 FROM sel_muni s WHERE s.muni_id = c.muni_id))
		AND NOT (
			EXISTS (
				SELECT 1
				FROM connec_psector cp
				WHERE cp.connec_id = c.connec_id AND cp.p_state = 0
			)
		)
		UNION ALL
		SELECT cp.connec_id, cp.arc_id, cp.link_id
		FROM connec_psector cp
		WHERE cp.p_state = 1
	),
    connec_selected AS (
        SELECT
			connec.connec_id,
			connec.code,
			connec.sys_code,
			connec.top_elev,
			connec.depth,
			cat_connec.connec_type,
			cat_feature.feature_class AS sys_type,
			connec.conneccat_id,
			cat_connec.matcat_id AS cat_matcat_id,
			cat_connec.pnom AS cat_pnom,
			cat_connec.dnom AS cat_dnom,
			cat_connec.dint AS cat_dint,
			connec.customer_code,
			connec.connec_length,
			connec.epa_type,
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
			CASE
			WHEN link_planned.sector_type IS NULL THEN sector_table.sector_type
			ELSE link_planned.sector_type
			END AS sector_type,
			CASE
			WHEN link_planned.supplyzone_id IS NULL THEN supplyzone_table.supplyzone_id
			ELSE link_planned.supplyzone_id
			END AS supplyzone_id,
			CASE
			WHEN link_planned.supplyzone_type IS NULL THEN supplyzone_table.supplyzone_type
			ELSE link_planned.supplyzone_type
			END AS supplyzone_type,
			CASE
			WHEN link_planned.presszone_id IS NULL THEN presszone_table.presszone_id
			ELSE link_planned.presszone_id
			END AS presszone_id,
			CASE
			WHEN link_planned.presszone_type IS NULL THEN presszone_table.presszone_type
			ELSE link_planned.presszone_type
			END AS presszone_type,
			CASE
			WHEN link_planned.presszone_head IS NULL THEN presszone_table.presszone_head
			ELSE link_planned.presszone_head
			END AS presszone_head,
			CASE
			WHEN link_planned.dma_id IS NULL THEN dma_table.dma_id
			ELSE link_planned.dma_id
			END AS dma_id,
			CASE
			WHEN link_planned.macrodma_id IS NULL THEN dma_table.macrodma_id
			ELSE link_planned.macrodma_id
			END AS macrodma_id,
			CASE
			WHEN link_planned.dma_type IS NULL then dma_table.dma_type
			ELSE link_planned.dma_type::varchar
			END AS dma_type,
			CASE
			WHEN link_planned.dqa_id IS NULL THEN dqa_table.dqa_id
			ELSE link_planned.dqa_id
			END AS dqa_id,
			CASE
			WHEN link_planned.macrodqa_id IS NULL THEN dqa_table.macrodqa_id
			ELSE link_planned.macrodqa_id
			END AS macrodqa_id,
			CASE
			WHEN link_planned.dqa_type IS NULL THEN dqa_table.dqa_type
			ELSE link_planned.dqa_type
			END AS dqa_type,
			CASE
			WHEN link_planned.omzone_id IS NULL THEN omzone_table.omzone_id
			ELSE link_planned.omzone_id
			END AS omzone_id,
			CASE
			WHEN link_planned.omzone_type IS NULL THEN omzone_table.omzone_type
			ELSE link_planned.omzone_type
			END AS omzone_type,
			connec.crmzone_id,
			crmzone.macrocrmzone_id,
			crmzone.name AS crmzone_name,
			CASE
			WHEN link_planned.minsector_id IS NULL THEN connec.minsector_id
			ELSE link_planned.minsector_id
			END AS minsector_id,
			connec.soilcat_id,
			connec.function_type,
			connec.category_type,
			connec.location_type,
			CASE
			WHEN link_planned.fluid_type IS NULL THEN connec.fluid_type
			ELSE link_planned.fluid_type::character varying(50)
			END AS fluid_type,
			connec.n_hydrometer,
			connec.n_inhabitants,
			CASE
			WHEN link_planned.staticpressure IS NULL THEN connec.staticpressure
			ELSE link_planned.staticpressure
			END AS staticpressure,
			connec.descript,
			connec.annotation,
			connec.observ,
			connec.comment,
			concat(cat_feature.link_path, connec.link) AS link,
			connec.num_value,
			connec.district_id,
			connec.postcode,
			streetaxis_id,
			connec.postnumber,
			connec.postcomplement,
			streetaxis2_id,
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
			CASE
			WHEN link_planned.link_id IS NULL THEN connec.pjoint_id
			ELSE link_planned.exit_id
			END AS pjoint_id,
			CASE
			WHEN link_planned.link_id IS NULL THEN connec.pjoint_type
			ELSE link_planned.exit_type
			END AS pjoint_type,
			connec.om_state,
			connec.conserv_state,
			connec.accessibility,
			connec.access_type,
			connec.placement_type,
			connec.priority,
			CASE
			WHEN connec.brand_id IS NULL THEN cat_connec.brand_id
			ELSE connec.brand_id
			END AS brand_id,
			CASE
			WHEN connec.model_id IS NULL THEN cat_connec.model_id
			ELSE connec.model_id
			END AS model_id,
			connec.serial_number,
			connec.asset_id,
			connec.adate,
			connec.adescript,
			connec.verified,
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
			CASE
			WHEN connec.sector_id > 0 AND vst.is_operative = true AND connec.epa_type = 'JUNCTION'::text AND inp_network_mode.value = '4'::text THEN connec.epa_type::character varying
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
			connec.lock_level,
			connec.expl_visibility,
			(SELECT ST_X(connec.the_geom)) AS xcoord,
			(SELECT ST_Y(connec.the_geom)) AS ycoord,
			(SELECT ST_Y(ST_Transform(connec.the_geom, 4326))) AS lat,
			(SELECT ST_X(ST_Transform(connec.the_geom, 4326))) AS long,
			date_trunc('second'::text, connec.created_at) AS created_at,
			connec.created_by,
			date_trunc('second'::text, connec.updated_at) AS updated_at,
			connec.updated_by,
			connec.the_geom
		FROM connec_selector
		JOIN connec ON connec.connec_id = connec_selector.connec_id
		JOIN cat_connec ON cat_connec.id::text = connec.conneccat_id::text
		JOIN cat_feature ON cat_feature.id::text = cat_connec.connec_type::text
		JOIN exploitation ON connec.expl_id = exploitation.expl_id
		JOIN ext_municipality mu ON connec.muni_id = mu.muni_id
		JOIN sector_table ON sector_table.sector_id = connec.sector_id
		LEFT JOIN presszone_table ON presszone_table.presszone_id = connec.presszone_id
		LEFT JOIN dma_table ON dma_table.dma_id = connec.dma_id
		LEFT JOIN dqa_table ON dqa_table.dqa_id = connec.dqa_id
		LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = connec.supplyzone_id
		LEFT JOIN omzone_table ON omzone_table.omzone_id = connec.omzone_id
		LEFT JOIN crmzone ON crmzone.crmzone_id = connec.crmzone_id
		LEFT JOIN link_planned USING (link_id)
		LEFT JOIN connec_add ON connec_add.connec_id = connec.connec_id
		LEFT JOIN value_state_type vst ON vst.id = connec.state_type
		LEFT JOIN inp_network_mode ON true
	)
    SELECT c.*
    FROM connec_selected c;


CREATE OR REPLACE VIEW ve_plan_netscenario_dma
AS WITH plan_netscenario_current AS (
         SELECT config_param_user.value::integer AS netscenario_id
           FROM config_param_user
          WHERE config_param_user.cur_user::text = CURRENT_USER AND config_param_user.parameter::text = 'plan_netscenario_current'::text
         LIMIT 1
        ), sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        )
 SELECT n.netscenario_id,
    p.name AS netscenario_name,
    n.dma_id,
    n.name,
    n.code,
    n.descript,
    n.pattern_id,
    n.graphconfig,
    n.the_geom,
    n.active,
    n.stylesheet::text AS stylesheet,
    n.expl_id,
    n.muni_id,
    n.sector_id,
    n.addparam
   FROM plan_netscenario_dma n
     JOIN plan_netscenario p USING (netscenario_id)
     JOIN plan_netscenario_current pnc ON n.netscenario_id = pnc.netscenario_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = p.expl_id));


CREATE OR REPLACE VIEW v_ui_mincut_hydrometer
AS SELECT om_mincut_hydrometer.id,
    om_mincut_hydrometer.hydrometer_id,
    connec.connec_id,
    om_mincut_hydrometer.result_id,
    om_mincut.work_order,
    om_mincut.mincut_state,
    om_mincut.mincut_class,
    om_mincut.mincut_type,
    om_mincut.received_date,
    om_mincut.anl_cause,
    om_mincut.anl_tstamp,
    om_mincut.anl_user,
    om_mincut.anl_descript,
    om_mincut.forecast_start,
    om_mincut.forecast_end,
    om_mincut.exec_start,
    om_mincut.exec_end,
    om_mincut.exec_user,
    om_mincut.exec_descript,
    om_mincut.exec_appropiate,
        CASE
            WHEN om_mincut.mincut_state = 0 THEN om_mincut.forecast_start::timestamp with time zone
            WHEN om_mincut.mincut_state = 1 THEN now()
            WHEN om_mincut.mincut_state = 2 THEN om_mincut.exec_start::timestamp with time zone
            ELSE NULL::timestamp with time zone
        END AS start_date,
        CASE
            WHEN om_mincut.mincut_state = 0 THEN om_mincut.forecast_end::timestamp with time zone
            WHEN om_mincut.mincut_state = 1 THEN now()
            WHEN om_mincut.mincut_state = 2 THEN om_mincut.exec_end::timestamp with time zone
            ELSE NULL::timestamp with time zone
        END AS end_date,
    om_mincut.shutoff_required
   FROM om_mincut_hydrometer
     JOIN om_mincut ON om_mincut_hydrometer.result_id = om_mincut.id
     JOIN ext_rtc_hydrometer ON ext_rtc_hydrometer.hydrometer_id::text = om_mincut_hydrometer.hydrometer_id::text
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text;


CREATE OR REPLACE VIEW v_om_mincut_hydrometer
AS SELECT om_mincut_hydrometer.id,
    om_mincut_hydrometer.result_id,
    om_mincut.work_order,
    om_mincut_hydrometer.hydrometer_id,
    ext_rtc_hydrometer.code AS hydrometer_customer_code,
    connec.connec_id,
    connec.code AS connec_code
   FROM selector_mincut_result,
    om_mincut_hydrometer
     JOIN ext_rtc_hydrometer ON om_mincut_hydrometer.hydrometer_id = ext_rtc_hydrometer.hydrometer_id
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     JOIN om_mincut ON om_mincut_hydrometer.result_id = om_mincut.id
  WHERE selector_mincut_result.result_id::text = om_mincut_hydrometer.result_id::text AND selector_mincut_result.cur_user = CURRENT_USER;


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


CREATE OR REPLACE VIEW v_om_mincut_current_hydrometer
AS SELECT om_mincut_hydrometer.id,
    om_mincut_hydrometer.result_id,
    om_mincut.work_order,
    om_mincut_hydrometer.hydrometer_id,
    ext_rtc_hydrometer.code AS hydrometer_customer_code,
    connec.connec_id,
    connec.code AS connec_code
   FROM om_mincut_hydrometer
     JOIN ext_rtc_hydrometer ON om_mincut_hydrometer.hydrometer_id = ext_rtc_hydrometer.hydrometer_id
     JOIN connec ON connec.customer_code::text = ext_rtc_hydrometer.customer_code::text
     JOIN om_mincut ON om_mincut_hydrometer.result_id = om_mincut.id
  WHERE om_mincut.mincut_state = 1;

CREATE OR REPLACE VIEW ve_plan_netscenario_presszone
AS WITH plan_netscenario_current AS (
         SELECT config_param_user.value::integer AS netscenario_id
           FROM config_param_user
          WHERE config_param_user.cur_user::text = CURRENT_USER AND config_param_user.parameter::text = 'plan_netscenario_current'::text
         LIMIT 1
        ), sel_expl AS (
         SELECT selector_expl.expl_id
           FROM selector_expl
          WHERE selector_expl.cur_user = CURRENT_USER
        )
 SELECT n.netscenario_id,
    p.name AS netscenario_name,
    n.presszone_id,
    n.name,
    n.code,
    n.descript,
    n.head,
    n.graphconfig,
    n.the_geom,
    n.active,
    n.presszone_type,
    n.stylesheet::text AS stylesheet,
    n.expl_id,
    n.muni_id,
    n.sector_id,
    n.addparam
   FROM plan_netscenario_presszone n
     JOIN plan_netscenario p USING (netscenario_id)
     JOIN plan_netscenario_current pnc ON n.netscenario_id = pnc.netscenario_id
  WHERE (EXISTS ( SELECT 1
           FROM sel_expl
          WHERE sel_expl.expl_id = p.expl_id));

-- NOTE: ve_epa_valve
CREATE OR REPLACE VIEW ve_epa_valve
AS SELECT inp_valve.node_id,
    inp_valve.valve_type,
    cat_node.dint,
    inp_valve.custom_dint,
    inp_valve.setting,
    inp_valve.curve_id,
    inp_valve.minorloss,
    v.to_arc,
        CASE
            WHEN v.closed IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN v.broken IS FALSE AND (v.to_arc IS NOT NULL OR inp_valve.valve_type::text = 'TCV'::text) THEN 'ACTIVE'::character varying(12)
            ELSE 'OPEN'::character varying(12)
        END AS status,
    inp_valve.add_settings,
    inp_valve.init_quality,
    inp_valve.head,
    inp_valve.pattern_id,
    inp_valve.demand,
    inp_valve.demand_pattern_id,
    inp_valve.emitter_coeff,
    v_rpt_arc_stats.result_id,
    v_rpt_arc_stats.flow_max AS flowmax,
    v_rpt_arc_stats.flow_min AS flowmin,
    v_rpt_arc_stats.flow_avg AS flowavg,
    v_rpt_arc_stats.vel_max AS velmax,
    v_rpt_arc_stats.vel_min AS velmin,
    v_rpt_arc_stats.vel_avg AS velavg,
    v_rpt_arc_stats.headloss_max,
    v_rpt_arc_stats.headloss_min,
    v_rpt_arc_stats.setting_max,
    v_rpt_arc_stats.setting_min,
    v_rpt_arc_stats.reaction_max,
    v_rpt_arc_stats.reaction_min,
    v_rpt_arc_stats.ffactor_max,
    v_rpt_arc_stats.ffactor_min,
    v_rpt_arc_stats.arc_id as nodarc_id
   FROM node
     JOIN inp_valve USING (node_id)
     LEFT JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
     LEFT JOIN v_rpt_arc_stats ON concat(inp_valve.node_id, '_n2a') = v_rpt_arc_stats.arc_id::text
     LEFT JOIN man_valve v ON v.node_id = inp_valve.node_id;

-- NOTE: ve_epa_pump
CREATE OR REPLACE VIEW ve_epa_pump
AS SELECT inp_pump.node_id,
    inp_pump.power,
    inp_pump.curve_id,
    inp_pump.speed,
    inp_pump.pattern_id,
    inp_pump.status,
    p.to_arc,
    inp_pump.energyparam,
    inp_pump.energyvalue,
    inp_pump.pump_type,
    inp_pump.effic_curve_id,
    inp_pump.energy_price,
    inp_pump.energy_pattern_id,
    v_rpt_arc_stats.result_id,
    v_rpt_arc_stats.flow_max AS flowmax,
    v_rpt_arc_stats.flow_min AS flowmin,
    v_rpt_arc_stats.flow_avg AS flowavg,
    v_rpt_arc_stats.vel_max AS velmax,
    v_rpt_arc_stats.vel_min AS velmin,
    v_rpt_arc_stats.vel_avg AS velavg,
    v_rpt_arc_stats.headloss_max,
    v_rpt_arc_stats.headloss_min,
    v_rpt_arc_stats.setting_max,
    v_rpt_arc_stats.setting_min,
    v_rpt_arc_stats.reaction_max,
    v_rpt_arc_stats.reaction_min,
    v_rpt_arc_stats.ffactor_max,
    v_rpt_arc_stats.ffactor_min,
    v_rpt_arc_stats.arc_id as nodarc_id
   FROM inp_pump
     LEFT JOIN v_rpt_arc_stats ON concat(inp_pump.node_id, '_n2a') = v_rpt_arc_stats.arc_id::text
     LEFT JOIN man_pump p ON p.node_id = inp_pump.node_id;

-- NOTE: ve_epa_pump_additional
CREATE OR REPLACE VIEW ve_epa_pump_additional
AS SELECT inp_pump_additional.id,
    inp_pump_additional.node_id,
    inp_pump_additional.order_id,
    inp_pump_additional.power,
    inp_pump_additional.curve_id,
    inp_pump_additional.speed,
    inp_pump_additional.pattern_id,
    inp_pump_additional.status,
    inp_pump_additional.energyparam,
    inp_pump_additional.energyvalue,
    inp_pump_additional.effic_curve_id,
    inp_pump_additional.energy_price,
    inp_pump_additional.energy_pattern_id,
    v_rpt_arc_stats.result_id,
    v_rpt_arc_stats.flow_max AS flowmax,
    v_rpt_arc_stats.flow_min AS flowmin,
    v_rpt_arc_stats.flow_avg AS flowavg,
    v_rpt_arc_stats.vel_max AS velmax,
    v_rpt_arc_stats.vel_min AS velmin,
    v_rpt_arc_stats.vel_avg AS velavg,
    v_rpt_arc_stats.headloss_max,
    v_rpt_arc_stats.headloss_min,
    v_rpt_arc_stats.setting_max,
    v_rpt_arc_stats.setting_min,
    v_rpt_arc_stats.reaction_max,
    v_rpt_arc_stats.reaction_min,
    v_rpt_arc_stats.ffactor_max,
    v_rpt_arc_stats.ffactor_min,
    v_rpt_arc_stats.arc_id as nodarc_id
    FROM inp_pump_additional
     LEFT JOIN v_rpt_arc_stats ON concat(inp_pump_additional.node_id, '_n2a', inp_pump_additional.order_id) = v_rpt_arc_stats.arc_id::text;

-- NOTE: ve_epa_shortpipe
CREATE OR REPLACE VIEW ve_epa_shortpipe
AS SELECT inp_shortpipe.node_id,
    inp_shortpipe.minorloss,
    cat_node.dint,
    inp_shortpipe.custom_dint,
    v.to_arc,
        CASE
            WHEN v.closed IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN v.broken IS FALSE AND v.to_arc IS NOT NULL THEN 'CV'::character varying(12)
            ELSE 'OPEN'::character varying(12)
        END AS status,
    inp_shortpipe.bulk_coeff,
    inp_shortpipe.wall_coeff,
    inp_shortpipe.head,
    inp_shortpipe.pattern_id,
    inp_shortpipe.demand,
    inp_shortpipe.demand_pattern_id,
    inp_shortpipe.emitter_coeff,
    v_rpt_arc_stats.result_id,
    v_rpt_arc_stats.flow_max AS flowmax,
    v_rpt_arc_stats.flow_min AS flowmin,
    v_rpt_arc_stats.flow_avg AS flowavg,
    v_rpt_arc_stats.vel_max AS velmax,
    v_rpt_arc_stats.vel_min AS velmin,
    v_rpt_arc_stats.vel_avg AS velavg,
    v_rpt_arc_stats.headloss_max,
    v_rpt_arc_stats.headloss_min,
    v_rpt_arc_stats.setting_max,
    v_rpt_arc_stats.setting_min,
    v_rpt_arc_stats.reaction_max,
    v_rpt_arc_stats.reaction_min,
    v_rpt_arc_stats.ffactor_max,
    v_rpt_arc_stats.ffactor_min,
    v_rpt_arc_stats.arc_id as nodarc_id
   FROM node
     LEFT JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
     JOIN inp_shortpipe USING (node_id)
     LEFT JOIN v_rpt_arc_stats ON concat(inp_shortpipe.node_id, '_n2a') = v_rpt_arc_stats.arc_id::text
     LEFT JOIN man_valve v ON v.node_id = inp_shortpipe.node_id;


CREATE OR REPLACE VIEW v_ui_crmzone
AS SELECT DISTINCT ON (c.crmzone_id) c.crmzone_id,
    c.code,
    c.name,
    c.descript,
    c.active,
    mc.name AS macrocrmzone,
    c.expl_id,
    c.sector_id,
    c.muni_id,
    c.created_at,
    c.created_by,
    c.updated_at,
    c.updated_by
FROM crmzone c
LEFT JOIN macrocrmzone mc USING (macrocrmzone_id)
WHERE c.crmzone_id > 0
ORDER BY c.crmzone_id;


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
    COALESCE(n1.result_id, n2.result_id) AS result_id,
    COALESCE(n1.demand_max, n2.demand_max) AS demandmax,
    COALESCE(n1.demand_min, n2.demand_min) AS demandmin,
    COALESCE(n1.demand_avg, n2.demand_avg) AS demandavg,
    COALESCE(n1.head_max, n2.head_max) AS headmax,
    COALESCE(n1.head_min, n2.head_min) AS headmin,
    COALESCE(n1.head_avg, n2.head_avg) AS headavg,
    COALESCE(n1.press_max, n2.press_max) AS pressmax,
    COALESCE(n1.press_min, n2.press_min) AS pressmin,
    COALESCE(n1.press_avg, n2.press_avg) AS pressavg,
    COALESCE(n1.quality_max, n2.quality_max) AS qualmax,
    COALESCE(n1.quality_min, n2.quality_min) AS qualmin,
    COALESCE(n1.quality_avg, n2.quality_avg) AS qualavg
   FROM (((inp_connec
     LEFT JOIN v_rpt_node_stats n1 ON (((inp_connec.connec_id)::text = (n1.node_id)::text)))
     LEFT JOIN link ON ((link.feature_id = inp_connec.connec_id)))
     LEFT JOIN v_rpt_node_stats n2 ON (((n2.node_id)::text = concat('VN', link.link_id))));

UPDATE config_toolbox
	SET inputparams='[
  {
    "label": "Copy from:",
    "value": null,
    "signal": "manage_duplicate_dscenario_copyfrom",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "copyFrom",
    "widgettype": "combo",
    "dvQueryText": "SELECT dscenario_id as id, name as idval FROM cat_dscenario WHERE active IS TRUE",
    "layoutorder": 1
  },
  {
    "label": "Name: (*)",
    "value": null,
    "tooltip": "Name for dscenario (mandatory)",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "name",
    "widgettype": "linetext",
    "isMandatory": true,
    "layoutorder": 2,
    "placeholder": null
  },
  {
    "label": "Descript:",
    "value": null,
    "tooltip": "Descript for dscenario",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "descript",
    "widgettype": "linetext",
    "isMandatory": false,
    "layoutorder": 3,
    "placeholder": null
  },
  {
    "label": "Type:",
    "value": null,
    "tooltip": "Dscenario type",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "type",
    "widgettype": "combo",
    "dvQueryText": "SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_dscenario''",
    "isMandatory": true,
    "layoutorder": 5
  },
  {
    "label": "Active:",
    "value": null,
    "tooltip": "If true, active",
    "datatype": "boolean",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "active",
    "widgettype": "check",
    "layoutorder": 6
  },
  {
    "label": "Exploitation:",
    "value": null,
    "tooltip": "Dscenario type",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "expl",
    "widgettype": "combo",
    "dvQueryText": "SELECT expl_id AS id, name as idval FROM ve_exploitation WHERE expl_id > 0",
    "isNullValue": "true",
    "isMandatory": true,
    "layoutorder": 7
  }
]'::json
	WHERE id=3156;
UPDATE config_toolbox
	SET inputparams='[
  {
    "label": "Name: (*)",
    "value": null,
    "tooltip": "Name for dscenario (mandatory)",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "name",
    "widgettype": "linetext",
    "isMandatory": true,
    "layoutorder": 1,
    "placeholder": ""
  },
  {
    "label": "Descript:",
    "value": null,
    "tooltip": "Descript for dscenario",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "descript",
    "widgettype": "linetext",
    "isMandatory": false,
    "layoutorder": 2,
    "placeholder": ""
  },
  {
    "label": "Parent:",
    "value": null,
    "tooltip": "Parent for dscenario",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "parent",
    "widgettype": "combo",
    "dvQueryText": "SELECT dscenario_id as id,name as idval FROM cat_dscenario WHERE dscenario_id IS NOT NULL AND active IS TRUE",
    "isNullValue": "true",
    "isMandatory": false,
    "layoutorder": 3,
    "placeholder": ""
  },
  {
    "label": "Type:",
    "value": null,
    "tooltip": "Dscenario type",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "type",
    "widgettype": "combo",
    "dvQueryText": "SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_dscenario''",
    "isMandatory": true,
    "layoutorder": 4
  },
  {
    "label": "Active:",
    "value": null,
    "tooltip": "If true, active",
    "datatype": "boolean",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "active",
    "widgettype": "check",
    "layoutorder": 5
  },
  {
    "label": "Exploitation:",
    "value": null,
    "tooltip": "Dscenario type",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "expl",
    "widgettype": "combo",
    "dvQueryText": "SELECT expl_id AS id, name as idval FROM ve_exploitation WHERE expl_id > 0",
    "isNullValue": "true",
    "isMandatory": true,
    "layoutorder": 6
  }
]'::json
	WHERE id=3134;

INSERT INTO inp_dscenario_demand (id, dscenario_id, feature_id, feature_type, demand, pattern_id, demand_type, source)
SELECT id, dscenario_id, feature_id, feature_type, demand, pattern_id, demand_type, source
FROM _inp_dscenario_demand_;


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
      "MACROOMZONE",
      "MACRODMA",
      "MACRODQA"
    ],
    "comboNames": [
      "MACROSECTOR",
      "MACROOMZONE",
       "MACRODMA",
       "MACRODQA"
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




UPDATE sys_fprocess
SET query_text='SELECT node_id, nodecat_id, n.the_geom, n.expl_id FROM man_valve mv JOIN t_node n USING (node_id) JOIN t_arc v ON v.arc_id = mv.to_arc WHERE node_id NOT IN (node_1, node_2)'
WHERE fid=170;
UPDATE sys_fprocess
SET query_text='SELECT node_id, nodecat_id, n.the_geom, n.expl_id FROM man_pump mp JOIN t_node n USING (node_id) JOIN t_arc v ON v.arc_id = mp.to_arc WHERE node_id NOT IN (node_1, node_2)'
WHERE fid=171;


UPDATE config_form_fields
SET dv_querytext='SELECT expl_id as id, name as idval FROM ve_exploitation WHERE expl_id > 0'
WHERE formname='ve_cat_dscenario' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_none';


UPDATE config_form_fields SET columnname='name' WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='presszone_name' AND tabname='tab_none';

DELETE FROM config_form_fields WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='lastupdate' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='lastupdate_user' AND tabname='tab_none';

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,isparent,iseditable,isautoupdate,isfilter,hidden)
VALUES ('plan_netscenario_presszone','form_feature','tab_none','code','lyt_data_1',3,'string','text','Code:','Code:',false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,isparent,iseditable,isautoupdate,isfilter,hidden)
VALUES ('plan_netscenario_presszone','form_feature','tab_none','descript','lyt_data_1',5,'string','text','Descript','Descript',false,true,false,false,false);

UPDATE config_form_fields SET layoutorder=2,ismandatory=true WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='presszone_id' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=6 WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='head' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=7 WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='graphconfig' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=8 WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='active' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=9 WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=10 WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=11 WHERE formname='plan_netscenario_presszone' AND formtype='form_feature' AND columnname='muni_id' AND tabname='tab_none';

UPDATE config_form_fields SET columnname='name' WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='dma_name' AND tabname='tab_none';

DELETE FROM config_form_fields WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='lastupdate' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='lastupdate_user' AND tabname='tab_none';

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,isparent,iseditable,isautoupdate,isfilter,hidden)
VALUES ('plan_netscenario_dma','form_feature','tab_none','code','lyt_data_1',3,'string','text','Code:','Code:',false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,isparent,iseditable,isautoupdate,isfilter,hidden)
VALUES ('plan_netscenario_dma','form_feature','tab_none','descript','lyt_data_1',5,'string','text','Descript','Descript',false,true,false,false,false);

UPDATE config_form_fields SET layoutorder=2,ismandatory=true WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='dma_id' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=6 WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='pattern_id' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=7 WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='graphconfig' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=8 WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='active' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=9 WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=10 WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_none';
UPDATE config_form_fields SET layoutorder=11 WHERE formname='plan_netscenario_dma' AND formtype='form_feature' AND columnname='muni_id' AND tabname='tab_none';

UPDATE config_form_fields SET dv_querytext='SELECT fluid_type AS id, fluid_type AS idval FROM man_type_fluid WHERE active AND (featurecat_id IS NULL AND ''ARC''=ANY(feature_type))' WHERE formname='ve_arc' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT fluid_type AS id, fluid_type AS idval FROM man_type_fluid WHERE active AND (featurecat_id IS NULL AND ''CONNEC''=ANY(feature_type))' WHERE formname='ve_connec' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT fluid_type AS id, fluid_type AS idval FROM man_type_fluid WHERE active AND (featurecat_id IS NULL AND ''ELEMENT''=ANY(feature_type))' WHERE formname='ve_element' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT fluid_type AS id, fluid_type AS idval FROM man_type_fluid WHERE active AND (featurecat_id IS NULL AND ''NODE''=ANY(feature_type))' WHERE formname='ve_node' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';

DELETE FROM config_param_user WHERE "parameter"='inp_options_selecteddma' AND cur_user='postgres';
DELETE FROM config_param_user WHERE "parameter"='inp_options_demand_weight_factor' AND cur_user='postgres';
DELETE FROM config_param_user WHERE "parameter"='edit_municipality_vdefault';
DELETE FROM sys_param_user WHERE id = 'inp_options_demand_weight_factor';

INSERT INTO sys_param_user (id,formname,descript,sys_role,"label",isenabled,layoutorder,project_type,isparent,isautoupdate,"datatype",widgettype,ismandatory,vdefault,layoutname,iseditable,"source")
	VALUES ('epa_dscenario_percent_hydro_threshold','epaoptions','Dscenario percent hydro threshold','role_epa','Percent hydro threshold:',true,9,'ws',false,false,'integer','text',true,'10','lyt_general_2',true,'core');

UPDATE config_form_fields
SET dv_querytext='SELECT crmzone_id AS id, name AS idval FROM crmzone WHERE crmzone_id IS NOT NULL AND active'
WHERE formname ILIKE 've_connec%' AND formtype='form_feature' AND columnname='crmzone_id' AND tabname='tab_data';

INSERT INTO sys_table (id,descript,sys_role,"source")
VALUES ('dma_graph_meter','Table to manage graph for dma','role_edit','core');
INSERT INTO sys_table (id,descript,sys_role,"source")
VALUES ('dma_graph_object','Table to manage graph for dma','role_edit','core');


WITH connec_customer AS (
    SELECT rxc.hydrometer_id,
        MIN(c.customer_code) AS customer_code
    FROM rtc_hydrometer_x_connec rxc
    JOIN connec c ON c.connec_id = rxc.connec_id
    WHERE c.customer_code IS NOT NULL
    GROUP BY rxc.hydrometer_id
), node_customer AS (
    SELECT rxn.hydrometer_id,
        MIN(mn.customer_code) AS customer_code
    FROM rtc_hydrometer_x_node rxn
    JOIN man_netwjoin mn ON mn.node_id = rxn.node_id
    WHERE mn.customer_code IS NOT NULL
    GROUP BY rxn.hydrometer_id
)
UPDATE ext_rtc_hydrometer h
SET customer_code = COALESCE(cc.customer_code, nc.customer_code)
FROM connec_customer cc
FULL OUTER JOIN node_customer nc ON nc.hydrometer_id = cc.hydrometer_id
WHERE h.hydrometer_id = COALESCE(cc.hydrometer_id, nc.hydrometer_id);

DROP TABLE IF EXISTS rtc_hydrometer_x_node;
DROP TABLE IF EXISTS rtc_hydrometer_x_connec;


UPDATE config_form_fields SET layoutorder = layoutorder+1 WHERE layoutname = 'lyt_epa_data_2' AND formname IN ('ve_epa_valve', 've_epa_shortpipe', 've_epa_pump', 've_epa_pump_additional');

INSERT INTO config_form_fields(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, iseditable) VALUES('ve_epa_pump', 'form_feature', 'tab_epa', 'nodarc_id', 'lyt_epa_data_2', 1, 'string', 'text', 'Nodarc id:', 'Nodarc id', false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, iseditable) VALUES('ve_epa_pump_additional', 'form_feature', 'tab_epa', 'nodarc_id', 'lyt_epa_data_2', 1, 'string', 'text', 'Nodarc id:', 'Nodarc id', false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, iseditable) VALUES('ve_epa_shortpipe', 'form_feature', 'tab_epa', 'nodarc_id', 'lyt_epa_data_2', 1, 'string', 'text', 'Nodarc id:', 'Nodarc id', false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, iseditable) VALUES('ve_epa_valve', 'form_feature', 'tab_epa', 'nodarc_id', 'lyt_epa_data_2', 1, 'string', 'text', 'Nodarc id:', 'Nodarc id', false) ON CONFLICT DO NOTHING;


INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_presszone', 'tab_presszone', 'tabRelations', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_macrodma', 'tab_macrodma', 'tabRelations', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_macrodqa', 'tab_macrodqa', 'tabRelations', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_dqa', 'tab_dqa', 'tabRelations', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_supplyzone', 'tab_supplyzone', 'tabRelations', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_crmzone', 'tab_crmzone', 'tabRelations', NULL);

INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_presszone', 'Presszone', 'Presszone', 'role_basic', NULL, NULL, 5, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_macrodma', 'Macrodma', 'Macrodma', 'role_basic', NULL, NULL, 6, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_macrodqa', 'Macrodqa', 'Macrodqa', 'role_basic', NULL, NULL, 7, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_dqa', 'Dqa', 'Dqa', 'role_basic', NULL, NULL, 8, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_supplyzone', 'Supplyzone', 'Supplyzone', 'role_basic', NULL, NULL, 9, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_crmzone', 'Crmzone', 'Crmzone', 'role_basic', NULL, NULL, 10, '{4}');

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'tab_main', 'lyt_mapzone_mng_2', 1, NULL, 'tabwidget', NULL, NULL, NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "tabs": [
    "tab_macrosector",
	"tab_sector",
	"tab_presszone",
	"tab_macrodma",
	"tab_dma",
	"tab_macrodqa",
	"tab_dqa",
	"tab_macroomzone",
	"tab_supplyzone",
	"tab_crmzone"
  ]
}'::json, NULL, NULL, false, 10);

UPDATE config_toolbox SET id = 2212 WHERE id = 2302;
DELETE FROM sys_function WHERE id = 2302 AND function_name = 'gw_fct_anl_node_topological_consistency';


INSERT INTO sys_table (id,descript,sys_role,"source")
VALUES ('plan_netscenario_mapzone_graph','Table to manage graph for plan_netscenario_mapzone','role_edit','core');


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


UPDATE sys_style SET stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis layerType="Vector" styleCategories="Symbology" version="4.0.1-Norrköping">
  <renderer-v2 enableorderby="0" forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer">
    <rules key="{cd75f41e-3b1d-443c-8148-fbc4436aa9cb}">
      <rule filter=" &quot;sys_type&quot; = ''GREENTAP''" key="{24b63ac0-a836-4203-bd64-161a0112ee9a}" label="Greentap" scalemaxdenom="1500" scalemindenom="1" symbol="0"/>
      <rule filter=" &quot;sys_type&quot; =''WJOIN''" key="{abcdb374-fe6a-4d04-a466-31fdd93144e8}" label="Wjoin" scalemaxdenom="1500" scalemindenom="1" symbol="1"/>
      <rule filter=" &quot;sys_type&quot; =''TAP''" key="{7dc90f4d-d098-491a-b817-e7ea68fc2fd6}" label="Tap" scalemaxdenom="1500" scalemindenom="1" symbol="2"/>
      <rule filter=" &quot;sys_type&quot; =''FOUNTAIN''" key="{39e4856f-0fc3-4498-8d4b-44d2851b421f}" label="Fountain" scalemaxdenom="1500" scalemindenom="1" symbol="3"/>
      <rule filter="&quot;sys_type&quot; = ''SAMPLEPOINT''" key="{8b2b31bb-dc82-4ab4-ba79-c74d3c700d88}" label="Samplepoint" scalemaxdenom="1500" scalemindenom="1" symbol="4"/>
      <rule filter="ELSE" key="{60014a37-16d8-4086-a5f3-248ffeeeefa3}" label="Wjoin" scalemaxdenom="1500" scalemindenom="1" symbol="5"/>
    </rules>
    <symbols>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="0" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{12cc35f6-2de1-4246-b4e0-8a183935eeae}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="201,246,158,255,rgb:0.7882353,0.9647059,0.6196079,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.6"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.57"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="2"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="1" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{362f8968-f888-433b-90e4-e5098d869499}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="49,180,227,255,rgb:0.1921569,0.7058824,0.8901961,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="49,180,227,255,rgb:0.1921569,0.7058824,0.8901961,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" enabled="1" id="{67948e1f-e6bb-4593-b5ad-8bb9fcf49d7d}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="cross"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="2"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="2" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{9be7c088-b096-4952-9c7a-3fe50ee2852a}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="31,120,180,255,rgb:0.1215686,0.4705882,0.7058824,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="1.5"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="3" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{d8e73060-669b-4565-9660-e859c06a83fd}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,83,rgb:0.172549,0.2627451,0.8117647,0.3254902"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="triangle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="22,0,148,255,rgb:0.0862745,0,0.5803922,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="4.2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="2.5"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="FontMarker" enabled="1" id="{b07449ae-bcc9-48eb-8ebd-ae0ffa344f84}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="chr" type="QString" value="F"/>
            <Option name="color" type="QString" value="22,0,148,255,rgb:0.0862745,0,0.5803922,1"/>
            <Option name="font" type="QString" value="Arial"/>
            <Option name="font_style" type="QString" value=""/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0.20000000000000001,0.20000000000000001"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="offset" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="tostring(0.047619*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0)))|| '','' || tostring(0.047619*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0)))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.714286*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="4" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{cafe2365-bf84-40bc-b4fd-71716f972139}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,100,200,255,rgb:0,0.3921569,0.7843137,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="0.7"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="FontMarker" enabled="1" id="{219fcf31-f2fe-4d0d-9707-a0eb69de422a}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="chr" type="QString" value="S"/>
            <Option name="color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
            <Option name="font" type="QString" value="Arial"/>
            <Option name="font_style" type="QString" value=""/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="offset" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="''0''|| '','' || tostring(-0.0666667*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 4.5, 0.7, 0.52), 0)))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.833333*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 4.5, 0.7, 0.52), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="5" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{362f8968-f888-433b-90e4-e5098d869499}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="121,208,255,255,rgb:0.4745098,0.8156863,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="121,208,255,255,rgb:0.4745098,0.8156863,1,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" enabled="1" id="{67948e1f-e6bb-4593-b5ad-8bb9fcf49d7d}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="cross"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="2"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" type="QString" value=""/>
        <Option name="properties"/>
        <Option name="type" type="QString" value="collection"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{593cbcfc-245e-4774-ad13-56169b965bf5}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>
' WHERE layername='ve_connec' AND styleconfig_id=101;

UPDATE sys_style
	SET stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis labelsEnabled="1" layerType="Vector" styleCategories="Symbology|Labeling" version="4.0.1-Norrköping">
  <renderer-v2 enableorderby="0" forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer">
    <rules key="{cd75f41e-3b1d-443c-8148-fbc4436aa9cb}">
      <rule filter="state = 1 and (p_state &lt;> 0 or p_state is null) AND &quot;sys_type&quot; = ''GREENTAP''" key="{24b63ac0-a836-4203-bd64-161a0112ee9a}" label="Greentap" scalemaxdenom="1500" symbol="0"/>
      <rule filter="state = 1 and (p_state &lt;> 0 or p_state is null) AND &quot;sys_type&quot; =''WJOIN''" key="{abcdb374-fe6a-4d04-a466-31fdd93144e8}" label="Wjoin" scalemaxdenom="1500" symbol="1"/>
      <rule filter="state = 1 and (p_state &lt;> 0 or p_state is null) AND &quot;sys_type&quot; =''TAP''" key="{7dc90f4d-d098-491a-b817-e7ea68fc2fd6}" label="Tap" scalemaxdenom="1500" symbol="2"/>
      <rule filter="state = 1 and (p_state &lt;> 0 or p_state is null) AND &quot;sys_type&quot; =''FOUNTAIN''" key="{39e4856f-0fc3-4498-8d4b-44d2851b421f}" label="Fountain" scalemaxdenom="1500" symbol="3"/>
      <rule filter="state = 1 and (p_state &lt;> 0 or p_state is null) AND &quot;sys_type&quot; = ''SAMPLEPOINT''" key="{5106e4ea-0314-4c87-9a29-99c33ab1149d}" label="Samplepoint" scalemaxdenom="1500" symbol="4"/>
      <rule filter="state=0" key="{5ed6d5c8-0054-42c1-a268-53e042760284}" label="OBSOLETE" scalemaxdenom="1500" symbol="5"/>
      <rule filter="state=2" key="{deedf78b-1b14-4314-b775-536678965a4f}" label="PLANIFIED" scalemaxdenom="1500" symbol="6"/>
      <rule filter="state=1 AND p_state=0" key="{b0e34206-b0d8-424d-a80a-21fec3287f94}" label="PHASE-OUT" scalemaxdenom="1500" symbol="7"/>
      <rule filter="ELSE" key="{fcb93b3a-1412-448e-b95f-627bfe328230}" label="(drawing)" symbol="8"/>
    </rules>
    <symbols>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="0" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{12cc35f6-2de1-4246-b4e0-8a183935eeae}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="201,246,158,255,rgb:0.7882353,0.9647059,0.6196079,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.6"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.57"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="2"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="1" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{362f8968-f888-433b-90e4-e5098d869499}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="49,180,227,255,rgb:0.1921569,0.7058824,0.8901961,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="49,180,227,255,rgb:0.1921569,0.7058824,0.8901961,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" enabled="1" id="{67948e1f-e6bb-4593-b5ad-8bb9fcf49d7d}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="cross"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="2"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="2" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{9be7c088-b096-4952-9c7a-3fe50ee2852a}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="31,120,180,255,rgb:0.1215686,0.4705882,0.7058824,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="1.5"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="3" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{d8e73060-669b-4565-9660-e859c06a83fd}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,83,rgb:0.172549,0.2627451,0.8117647,0.3254902"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="triangle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="22,0,148,255,rgb:0.0862745,0,0.5803922,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="4.2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="2.5"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="FontMarker" enabled="1" id="{b07449ae-bcc9-48eb-8ebd-ae0ffa344f84}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="chr" type="QString" value="F"/>
            <Option name="color" type="QString" value="22,0,148,255,rgb:0.0862745,0,0.5803922,1"/>
            <Option name="font" type="QString" value="Arial"/>
            <Option name="font_style" type="QString" value=""/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0.20000000000000001,0.20000000000000001"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="offset" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="tostring(0.047619*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0)))|| '','' || tostring(0.047619*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0)))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.714286*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="4" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{cafe2365-bf84-40bc-b4fd-71716f972139}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,100,200,255,rgb:0,0.3921569,0.7843137,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="0.7"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="FontMarker" enabled="1" id="{219fcf31-f2fe-4d0d-9707-a0eb69de422a}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="chr" type="QString" value="S"/>
            <Option name="color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
            <Option name="font" type="QString" value="Arial"/>
            <Option name="font_style" type="QString" value=""/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="offset" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="''0''|| '','' || tostring(-0.0666667*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 4.5, 0.7, 0.52), 0)))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.833333*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 4.5, 0.7, 0.52), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="5" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="120,120,120,153,hsv:0.56711113452911377,0,0.46909284591674805,0.60000002384185791"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="120,120,120,153,hsv:0.56711113452911377,0,0.46909284591674805,0.60000002384185791"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="6" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="245,128,26,255,rgb:0.9607843,0.5019608,0.1019608,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="208,100,6,255,hsv:0.0776388868689537,0.97120624780654907,0.81702905893325806,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="7" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="121,208,255,255,rgb:0.4745098,0.8156863,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="61,180,244,255,hsv:0.55844444036483765,0.74923324584960938,0.95664912462234497,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="8" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{08733df3-bc13-4eac-bf5c-58b353a68ba7}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="85,95,105,255,hsv:0.58761113882064819,0.19267566502094269,0.41322958469390869,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.6"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" type="QString" value=""/>
        <Option name="properties"/>
        <Option name="type" type="QString" value="collection"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" id="{593cbcfc-245e-4774-ad13-56169b965bf5}" locked="0" pass="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style allowHtml="0" blendMode="0" capitalization="0" fieldName="arc_id" fontFamily="Open Sans" fontItalic="0" fontKerning="1" fontLetterSpacing="0" fontSize="10" fontSizeMapUnitScale="3x:0,0,0,0,0,0" fontSizeUnit="Point" fontStrikeout="0" fontUnderline="0" fontWeight="400" fontWordSpacing="0" forcedBold="0" forcedItalic="0" isExpression="0" legendString="Aa" multilineHeight="1" multilineHeightUnit="Percentage" namedStyle="Regular" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" stretchFactor="100" tabStopDistance="80" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" tabStopDistanceUnit="Point" textColor="50,50,50,255,rgb:0.1960784,0.1960784,0.1960784,1" textOpacity="1" textOrientation="horizontal" useSubstitutions="0">
        <families/>
        <text-buffer bufferBlendMode="0" bufferColor="250,250,250,255,rgb:0.9803922,0.9803922,0.9803922,1" bufferDraw="0" bufferJoinStyle="128" bufferNoFill="1" bufferOpacity="1" bufferSize="1" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferSizeUnits="MM"/>
        <text-mask maskEnabled="0" maskJoinStyle="128" maskOpacity="1" maskSize="1.5" maskSize2="1.5" maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskSizeUnits="MM" maskType="0" maskedSymbolLayers=""/>
        <background shapeBlendMode="0" shapeBorderColor="128,128,128,255,rgb:0.5019608,0.5019608,0.5019608,1" shapeBorderWidth="0" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidthUnit="Point" shapeDraw="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeJoinStyle="64" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeOffsetUnit="Point" shapeOffsetX="0" shapeOffsetY="0" shapeOpacity="1" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeRadiiUnit="Point" shapeRadiiX="0" shapeRadiiY="0" shapeRotation="0" shapeRotationType="0" shapeSVGFile="" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeSizeType="0" shapeSizeUnit="Point" shapeSizeX="0" shapeSizeY="0" shapeType="0">
          <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="markerSymbol" type="marker">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer class="SimpleMarker" enabled="1" id="" locked="0" pass="0">
              <Option type="Map">
                <Option name="angle" type="QString" value="0"/>
                <Option name="cap_style" type="QString" value="square"/>
                <Option name="color" type="QString" value="213,180,60,255,rgb:0.8352941,0.7058824,0.2352941,1"/>
                <Option name="horizontal_anchor_point" type="QString" value="1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="name" type="QString" value="circle"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1"/>
                <Option name="outline_style" type="QString" value="solid"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="outline_width_unit" type="QString" value="MM"/>
                <Option name="scale_method" type="QString" value="diameter"/>
                <Option name="size" type="QString" value="2"/>
                <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="size_unit" type="QString" value="MM"/>
                <Option name="vertical_anchor_point" type="QString" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties"/>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
          <symbol alpha="1" clip_to_extent="1" force_rhr="0" frame_rate="10" is_animated="0" name="fillSymbol" type="fill">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer class="SimpleFill" enabled="1" id="" locked="0" pass="0">
              <Option type="Map">
                <Option name="border_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="128,128,128,255,rgb:0.5019608,0.5019608,0.5019608,1"/>
                <Option name="outline_style" type="QString" value="no"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_unit" type="QString" value="Point"/>
                <Option name="style" type="QString" value="solid"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties"/>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </background>
        <shadow shadowBlendMode="6" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowDraw="0" shadowOffsetAngle="135" shadowOffsetDist="1" shadowOffsetGlobal="1" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowOffsetUnit="MM" shadowOpacity="0.69999999999999996" shadowRadius="1.5" shadowRadiusAlphaOnly="0" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowRadiusUnit="MM" shadowScale="100" shadowUnder="0"/>
        <dd_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format addDirectionSymbol="0" autoWrapLength="0" decimals="3" formatNumbers="0" leftDirectionSymbol="&lt;" multilineAlign="3" placeDirectionSymbol="0" plussign="0" reverseDirectionSymbol="0" rightDirectionSymbol=">" useMaxLineLengthForAutoWrap="1" wrapChar=""/>
      <placement allowDegraded="0" centroidInside="0" centroidWhole="0" dist="0" distMapUnitScale="3x:0,0,0,0,0,0" distUnits="MM" fitInPolygonOnly="0" geometryGenerator="" geometryGeneratorEnabled="0" geometryGeneratorType="PointGeometry" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" layerType="PointGeometry" lineAnchorClipping="0" lineAnchorPercent="0.5" lineAnchorTextPoint="FollowPlacement" lineAnchorType="0" maxCurvedCharAngleIn="25" maxCurvedCharAngleOut="-25" maximumDistance="0" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" maximumDistanceUnit="MM" multipartBehavior="LabelLargestPartOnly" offsetType="1" offsetUnits="MM" overlapHandling="PreventOverlap" overrunDistance="0" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" overrunDistanceUnit="MM" placement="6" placementFlags="10" polygonPlacementFlags="2" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" preserveRotation="1" prioritization="PreferCloser" priority="5" quadOffset="4" repeatDistance="0" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" repeatDistanceUnits="MM" rotationAngle="0" rotationUnit="AngleDegrees" xOffset="0" yOffset="0"/>
      <rendering drawLabels="1" fontLimitPixelSize="0" fontMaxPixelSize="10000" fontMinPixelSize="3" limitNumLabels="0" maxNumLabels="2000" mergeLines="0" minFeatureSize="0" obstacle="1" obstacleFactor="1" obstacleType="1" scaleMax="500" scaleMin="0" scaleVisibility="1" unplacedVisibility="0" upsidedownLabels="0" zIndex="0"/>
      <dd_properties>
        <Option type="Map">
          <Option name="name" type="QString" value=""/>
          <Option name="properties"/>
          <Option name="type" type="QString" value="collection"/>
        </Option>
      </dd_properties>
      <callout type="simple">
        <Option type="Map">
          <Option name="anchorPoint" type="QString" value="pole_of_inaccessibility"/>
          <Option name="blendMode" type="int" value="0"/>
          <Option name="ddProperties" type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
          <Option name="drawToAllParts" type="bool" value="false"/>
          <Option name="enabled" type="QString" value="0"/>
          <Option name="labelAnchorPoint" type="QString" value="point_on_exterior"/>
          <Option name="lineSymbol" type="QString" value="&lt;symbol alpha=&quot;1&quot; clip_to_extent=&quot;1&quot; force_rhr=&quot;0&quot; frame_rate=&quot;10&quot; is_animated=&quot;0&quot; name=&quot;symbol&quot; type=&quot;line&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;name&quot; type=&quot;QString&quot; value=&quot;&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option name=&quot;type&quot; type=&quot;QString&quot; value=&quot;collection&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer class=&quot;SimpleLine&quot; enabled=&quot;1&quot; id=&quot;{8b192846-a06f-4f5a-bc59-5574a887e5a5}&quot; locked=&quot;0&quot; pass=&quot;0&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;align_dash_pattern&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;capstyle&quot; type=&quot;QString&quot; value=&quot;square&quot;/>&lt;Option name=&quot;customdash&quot; type=&quot;QString&quot; value=&quot;5;2&quot;/>&lt;Option name=&quot;customdash_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;customdash_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;dash_pattern_offset&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;dash_pattern_offset_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;dash_pattern_offset_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;draw_inside_polygon&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;joinstyle&quot; type=&quot;QString&quot; value=&quot;bevel&quot;/>&lt;Option name=&quot;line_color&quot; type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.2352941,0.2352941,0.2352941,1&quot;/>&lt;Option name=&quot;line_style&quot; type=&quot;QString&quot; value=&quot;solid&quot;/>&lt;Option name=&quot;line_width&quot; type=&quot;QString&quot; value=&quot;0.3&quot;/>&lt;Option name=&quot;line_width_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;offset&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;offset_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;offset_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;ring_filter&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_end&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_end_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;trim_distance_end_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;trim_distance_start&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_start_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;trim_distance_start_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;tweak_dash_pattern_on_corners&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;use_custom_dash&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;width_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;name&quot; type=&quot;QString&quot; value=&quot;&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option name=&quot;type&quot; type=&quot;QString&quot; value=&quot;collection&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>"/>
          <Option name="minLength" type="double" value="0"/>
          <Option name="minLengthMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="minLengthUnit" type="QString" value="MM"/>
          <Option name="offsetFromAnchor" type="double" value="0"/>
          <Option name="offsetFromAnchorMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="offsetFromAnchorUnit" type="QString" value="MM"/>
          <Option name="offsetFromLabel" type="double" value="0"/>
          <Option name="offsetFromLabelMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="offsetFromLabelUnit" type="QString" value="MM"/>
        </Option>
      </callout>
    </settings>
  </labeling>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>
'
WHERE layername='ve_connec' AND styleconfig_id=110;


UPDATE config_toolbox
SET "inputparams"='[{"label":"Graph class:","tooltip":"Graphanalytics method used","comboIds":["PRESSZONE","DQA","DMA","SECTOR"],"datatype":"text","comboNames":["Pressure Zonification (PRESSZONE)","District Quality Areas (DQA)","District Metering Areas (DMA)","Inlet Sectorization (SECTOR-HIGH / SECTOR-LOW)"],"layoutname":"grl_option_parameters","selectedId":null,"widgetname":"graphClass","widgettype":"combo","layoutorder":1},{"label":"Exploitation:","tooltip":"Choose exploitation to work with","datatype":"text","layoutname":"grl_option_parameters","selectedId":null,"widgetname":"exploitation","widgettype":"combo","dvQueryText":"SELECT id, idval FROM ( SELECT -901 AS id, ''User selected expl'' AS idval, ''a'' AS sort_order UNION SELECT -902 AS id, ''All exploitations'' AS idval, ''b'' AS sort_order UNION SELECT expl_id AS id, name AS idval, ''c'' AS sort_order FROM exploitation WHERE active IS NOT FALSE ) a ORDER BY sort_order ASC, idval ASC","layoutorder":2},{"label":"Force open nodes: (*)","value":null,"tooltip":"Optative node id(s) to temporary open closed node(s) in order to force algorithm to continue there","datatype":"text","layoutname":"grl_option_parameters","widgetname":"forceOpen","widgettype":"linetext","isMandatory":false,"layoutorder":5,"placeholder":"1015,2231,3123"},{"label":"Force closed nodes: (*)","value":null,"tooltip":"Optative node id(s) to temporary close open node(s) to force algorithm to stop there","datatype":"text","layoutname":"grl_option_parameters","widgetname":"forceClosed","widgettype":"text","isMandatory":false,"layoutorder":6,"placeholder":"1015,2231,3123"},{"label":"Use selected psectors:","value":null,"tooltip":"If true, use selected psectors. If false ignore selected psectors and only works with on-service network","datatype":"boolean","layoutname":"grl_option_parameters","widgetname":"usePlanPsector","widgettype":"check","layoutorder":7},{"label":"Commit changes:","value":null,"tooltip":"If true, changes will be applied to DB. If false, algorithm results will be saved in anl tables","datatype":"boolean","layoutname":"grl_option_parameters","widgetname":"commitChanges","widgettype":"check","layoutorder":8},{"label":"Mapzone constructor method:","comboIds":[0,1,2,3,4],"datatype":"integer","comboNames":["NONE","CONCAVE POLYGON","PIPE BUFFER","PLOT & PIPE BUFFER","LINK & PIPE BUFFER"],"layoutname":"grl_option_parameters","selectedId":null,"widgetname":"updateMapZone","widgettype":"combo","layoutorder":10},{"label":"Pipe buffer","value":null,"tooltip":"Buffer from arcs to create mapzone geometry using [PIPE BUFFER] options. Normal values maybe between 3-20 mts.","datatype":"float","layoutname":"grl_option_parameters","widgetname":"geomParamUpdate","widgettype":"text","isMandatory":false,"layoutorder":11,"placeholder":"5-30"},{"label":"Mapzones from zero:","value":null,"tooltip":"If true, mapzones are calculated automatically from zero","datatype":"boolean","layoutname":"grl_option_parameters","widgetname":"fromZero","widgettype":"check","layoutorder":12}]'::json
WHERE id = 2768;

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_plan_address', 'lyt_plan_address', 'lytPlanAddress', NULL);

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mincut', 'form_mincut', 'tab_mincut', 'municipality', 'lyt_plan_address', 1, 'string', 'combo', 'Municipality:', 'Municipality', NULL, false, false, true, false, false, 'SELECT muni_id, name FROM v_municipality WHERE active is True and muni_id > 0 ', true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 1);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mincut', 'form_mincut', 'tab_mincut', 'street', 'lyt_plan_address', 2, 'string', 'text', 'Street:', 'Street', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 2);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mincut', 'form_mincut', 'tab_mincut', 'number', 'lyt_plan_address', 3, 'string', 'text', 'Number:', 'Number', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 3);

CREATE INDEX IF NOT EXISTS man_netwjoin_customer_code_idx ON man_netwjoin USING btree (customer_code);


ALTER TABLE sys_feature_class ADD CONSTRAINT sys_feature_cat_check CHECK (id::text = ANY (
    ARRAY['EXPANSIONTANK'::text, 'FILTER'::text, 'FLEXUNION'::text, 'FOUNTAIN'::text, 'GREENTAP'::text, 'HYDRANT'::text, 'JUNCTION'::text, 'MANHOLE'::text, 'METER'::text,
    'NETELEMENT'::text, 'NETSAMPLEPOINT'::text, 'NETWJOIN'::text, 'PIPE'::text, 'PUMP'::text, 'REDUCTION'::text, 'REGISTER'::text, 'SOURCE'::text, 'TANK'::text, 'TAP'::text, 'VALVE'::text,
    'VARC'::text, 'WATERWELL'::text, 'WJOIN'::text, 'WTP'::text, 'PIPELINK'::text, 'VLINK'::text, 'VCONNEC'::text, 'ELEMENT'::text, 'GENELEM'::text, 'FRELEM'::text, 'SAMPLEPOINT'::text]));


ALTER TABLE connec DROP CONSTRAINT IF EXISTS connec_brand_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE connec DROP CONSTRAINT IF EXISTS connec_model_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE link DROP CONSTRAINT IF EXISTS link_minsector_id_fkey;
ALTER TABLE link ADD CONSTRAINT link_minsector_id_fkey FOREIGN KEY (minsector_id) REFERENCES minsector(minsector_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE link DROP CONSTRAINT IF EXISTS link_sector_id;
ALTER TABLE link ADD CONSTRAINT link_sector_id FOREIGN KEY (sector_id) REFERENCES sector(sector_id) ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE TRIGGER gw_trg_edit_inp_dscenario_pattern INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_pattern 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('PATTERN');

CREATE TRIGGER gw_trg_edit_inp_dscenario_pattern_value INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_pattern_value 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('PATTERN_VALUE');

CREATE TRIGGER gw_trg_edit_inp_dscenario_demand INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_demand 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario_demand();

CREATE TRIGGER gw_trg_dscenario_demand_feature AFTER INSERT ON inp_dscenario_demand
FOR EACH ROW EXECUTE FUNCTION gw_trg_dscenario_demand_feature();
CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_demand
FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_demand');

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_link 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link('LINK');

CREATE TRIGGER gw_trg_edit_inp_dscenario_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_connec 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('CONNEC');

CREATE TRIGGER gw_trg_edit_inp_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_connec 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_connec();

CREATE TRIGGER gw_trg_edit_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_connec 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');


CREATE TRIGGER gw_trg_edit_plan_netscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_plan_netscenario_dma 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plan_netscenario('DMA');

CREATE TRIGGER gw_trg_edit_plan_netscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_plan_netscenario_presszone 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plan_netscenario('PRESSZONE');


DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON supplyzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON supplyzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON macrodma;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON macrodqa;


DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macrodma 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON dqa 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macrodqa 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON presszone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON supplyzone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON crmzone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON plan_netscenario_dma 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON plan_netscenario_presszone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
    ELSE
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macrodma 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON dqa 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macrodqa 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON presszone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON supplyzone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON crmzone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON plan_netscenario_dma 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
		CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON plan_netscenario_presszone 
		FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
    END IF;

	CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON macrodma 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON macrodma 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

	CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON dqa 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON dqa 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON macrodqa 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON macrodqa 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON presszone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON presszone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON supplyzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON supplyzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON crmzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON crmzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON plan_netscenario_dma 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON plan_netscenario_dma 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON plan_netscenario_presszone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON plan_netscenario_presszone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');
END; $$;

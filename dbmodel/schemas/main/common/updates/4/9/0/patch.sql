/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;


drop view if exists v_ext_raster_dem;
drop view if exists v_ext_municipality;
drop view if exists v_ext_streetaxis;
drop view if exists v_ext_address;
drop view if exists v_ext_plot;


drop view if exists v_plan_result_arc;
drop view if exists v_plan_psector;
drop view if exists v_plan_current_psector;
drop view if exists v_plan_psector_budget;
drop view if exists v_plan_psector_budget_arc;
drop view if exists v_plan_psector_budget_detail;
drop view if exists v_plan_psector_all;
drop view if exists v_ui_plan_arc_cost;
drop view if exists v_plan_arc;
drop view if exists v_ui_arc_x_relations;
drop view if exists ve_inp_dscenario_connec;
drop view if exists ve_inp_connec;
drop view if exists v_ui_workcat_x_feature_end;
drop view if exists v_ui_node_x_connection_upstream;

SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"data":{"action":"MULTI-DELETE"}, "feature":{"parentLayer":"ve_connec"}}$$);
drop view if exists v_edit_connec;
drop view if exists ve_connec;

SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP", "table":"ext_municipality", "column":"expl_id", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP", "table":"ext_municipality", "column":"sector_id", "isUtils":true}}$$);

DO $$
DECLARE
    v_utils boolean;
BEGIN
    SELECT COALESCE(value::boolean, false) INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';
    IF v_utils IS TRUE THEN
		ALTER TABLE utils.address DROP COLUMN IF EXISTS ws_expl_id;
		ALTER TABLE utils.address DROP COLUMN IF EXISTS ud_expl_id;

		ALTER TABLE utils.streetaxis DROP COLUMN IF EXISTS ws_expl_id;
		ALTER TABLE utils.streetaxis DROP COLUMN IF EXISTS ud_expl_id;

		ALTER TABLE utils.plot DROP COLUMN IF EXISTS ws_expl_id;
		ALTER TABLE utils.plot DROP COLUMN IF EXISTS ud_expl_id;
	ELSE
		ALTER TABLE ext_address DROP COLUMN IF EXISTS expl_id;
		ALTER TABLE ext_streetaxis DROP COLUMN IF EXISTS expl_id;
		ALTER TABLE ext_plot DROP COLUMN IF EXISTS expl_id;
    END IF;
END $$;

SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_address", "column":"ext_code", "newName":"code", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_municipality", "column":"ext_code", "newName":"code", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_district", "column":"ext_code", "newName":"code", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_plot", "column":"plot_code", "newName":"code", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_province", "column":"ext_code", "newName":"code", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_region", "column":"ext_code", "newName":"code", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"connec", "column":"plot_code", "newName":"plot_id"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"ext_address", "column":"code", "dataType":"varchar(100)", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"ext_streetaxis", "column":"code", "dataType":"varchar(100)", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"ext_district", "column":"code", "dataType":"varchar(100)", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"ext_plot", "column":"code", "dataType":"varchar(100)", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"ext_municipality", "column":"code", "dataType":"varchar(100)", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"ext_province", "column":"code", "dataType":"varchar(100)", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"ext_region", "column":"code", "dataType":"varchar(100)", "isUtils":true}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"connec", "column":"plot_id", "dataType":"varchar(100)"}}$$);


DO $$
DECLARE
    v_utils boolean;
BEGIN

    SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

    IF v_utils IS true THEN
  ELSE
    CREATE SEQUENCE ext_plot_id_seq
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 2147483647
      START 1
      CACHE 1
      NO CYCLE;

    ALTER TABLE ext_plot ALTER COLUMN id SET DEFAULT nextval('ext_plot_id_seq');
    ALTER TABLE ext_streetaxis ALTER COLUMN id SET DEFAULT nextval('ext_streetaxis_id_seq');
    ALTER TABLE ext_address ALTER COLUMN id SET DEFAULT nextval('ext_address_id_seq');
  END IF;
END $$;


SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"ext_rtc_hydrometer", "column":"customer_code", "dataType":"varchar(30)"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"anl_arc", "column":"state_type", "dataType":"int2"}}$$);

-- trgs at this point are broken, they recreate after in [ud|ws]/trg.sql
-- we disable them to avoid errors
ALTER TABLE exploitation DISABLE TRIGGER USER;
ALTER TABLE sector DISABLE TRIGGER USER;
ALTER TABLE macrosector DISABLE TRIGGER USER;
ALTER TABLE dma DISABLE TRIGGER USER;
ALTER TABLE omzone DISABLE TRIGGER USER;
ALTER TABLE macroomzone DISABLE TRIGGER USER;

UPDATE exploitation SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
UPDATE exploitation SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
ALTER TABLE exploitation ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE exploitation ALTER COLUMN muni_id SET NOT NULL;
ALTER TABLE exploitation ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE exploitation ALTER COLUMN sector_id SET NOT NULL;

UPDATE sector SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE sector SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE sector ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE sector ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE sector ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE sector ALTER COLUMN muni_id SET NOT NULL;

UPDATE macrosector SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE macrosector SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE macrosector ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE macrosector ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE macrosector ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE macrosector ALTER COLUMN muni_id SET NOT NULL;

UPDATE dma SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE dma SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE dma SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE dma ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE dma ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE dma ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE dma ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE dma ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE dma ALTER COLUMN muni_id SET NOT NULL;

UPDATE omzone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE omzone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE omzone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE omzone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE omzone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE omzone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
--ALTER TABLE omzone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE omzone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
--ALTER TABLE omzone ALTER COLUMN muni_id SET NOT NULL;

UPDATE macroomzone SET expl_id = ARRAY[0] WHERE expl_id IS NULL;
UPDATE macroomzone SET sector_id = ARRAY[0] WHERE sector_id IS NULL;
UPDATE macroomzone SET muni_id = ARRAY[0] WHERE muni_id IS NULL;
ALTER TABLE macroomzone ALTER COLUMN expl_id SET DEFAULT ARRAY[0];
ALTER TABLE macroomzone ALTER COLUMN expl_id SET NOT NULL;
ALTER TABLE macroomzone ALTER COLUMN sector_id SET DEFAULT ARRAY[0];
ALTER TABLE macroomzone ALTER COLUMN sector_id SET NOT NULL;
ALTER TABLE macroomzone ALTER COLUMN muni_id SET DEFAULT ARRAY[0];
ALTER TABLE macroomzone ALTER COLUMN muni_id SET NOT NULL;

ALTER TABLE exploitation ENABLE TRIGGER USER;
ALTER TABLE sector ENABLE TRIGGER USER;
ALTER TABLE macrosector ENABLE TRIGGER USER;
ALTER TABLE dma ENABLE TRIGGER USER;
ALTER TABLE omzone ENABLE TRIGGER USER;
ALTER TABLE macroomzone ENABLE TRIGGER USER;

DROP RULE IF EXISTS dma_expl ON dma;

ALTER TABLE om_visit
    ADD COLUMN address text,
    ADD COLUMN process_rejection_date timestamp,
    ADD COLUMN reassignment varchar(50),
    ADD COLUMN "comment" text,
    ADD COLUMN comment_extra text,
    ADD CONSTRAINT om_visit_reassignment_fkey FOREIGN KEY (reassignment) REFERENCES cat_users(id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE cat_users
    ADD COLUMN mail text NULL;

CREATE INDEX IF NOT EXISTS idx_connec_arc_id ON connec USING btree (arc_id);

DROP TABLE IF EXISTS sector_graph;
DROP TABLE IF EXISTS dma_graph;

CREATE TABLE IF NOT EXISTS mapzone_graph (
    node_id int4 NOT NULL,
    mapzone_id int4 NOT NULL,
    mapzone_type text NOT NULL,
    flow_sign int2 NULL,
    CONSTRAINT mapzone_graph_pkey PRIMARY KEY (node_id, mapzone_id)
);

CREATE INDEX IF NOT EXISTS mapzone_graph_mapzone_id_idx ON mapzone_graph USING btree (mapzone_id);
CREATE INDEX IF NOT EXISTS mapzone_graph_node_id_idx ON mapzone_graph USING btree (node_id);

ALTER TABLE samplepoint DROP CONSTRAINT man_samplepoint_pkey;
ALTER TABLE samplepoint ADD CONSTRAINT samplepoint_pkey PRIMARY KEY (sample_id);

CREATE TABLE IF NOT EXISTS man_samplepoint (
    connec_id int4 NOT NULL,
    lab_code varchar(30) NULL,
    place_name varchar(254) NULL,
	cabinet varchar(150) NULL,
    CONSTRAINT man_samplepoint_pkey PRIMARY KEY (connec_id),
    CONSTRAINT man_samplepoint_connec_id_fkey FOREIGN KEY (connec_id) REFERENCES connec(connec_id) ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE sys_feature_class DROP CONSTRAINT sys_feature_cat_check;

DROP VIEW IF EXISTS ve_samplepoint;
ALTER TABLE samplepoint RENAME TO _samplepoint_;

DROP INDEX IF EXISTS connec_plot_code;
CREATE INDEX IF NOT EXISTS idx_connec_plot_id ON connec USING btree (plot_id);

ALTER TABLE config_param_system ADD device _int4 NULL;

CREATE TABLE IF NOT EXISTS node_x_sector_visibility (
    node_id int4 NOT NULL,
    sector_id int4 NOT NULL,
    CONSTRAINT node_x_sector_visibility_pkey PRIMARY KEY (node_id, sector_id),
    CONSTRAINT node_x_sector_visibility_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT node_x_sector_visibility_sector_id_fkey FOREIGN KEY (sector_id) REFERENCES sector(sector_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS node_x_municipality_visibility (
    node_id int4 NOT NULL,
    muni_id int4 NOT NULL,
    CONSTRAINT node_x_municipality_visibility_pkey PRIMARY KEY (node_id, muni_id),
    CONSTRAINT node_x_municipality_visibility_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE
);

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS TRUE THEN
        ALTER TABLE node_x_municipality_visibility
        ADD CONSTRAINT node_x_municipality_visibility_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON DELETE CASCADE ON UPDATE CASCADE;
    ELSE
        ALTER TABLE node_x_municipality_visibility
        ADD CONSTRAINT node_x_municipality_visibility_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES ext_municipality(muni_id) ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS element_x_sector_visibility (
    element_id int4 NOT NULL,
    sector_id int4 NOT NULL,
    CONSTRAINT element_x_sector_visibility_pkey PRIMARY KEY (element_id, sector_id),
    CONSTRAINT element_x_sector_visibility_element_id_fkey FOREIGN KEY (element_id) REFERENCES element(element_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT element_x_sector_visibility_sector_id_fkey FOREIGN KEY (sector_id) REFERENCES sector(sector_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS element_x_municipality_visibility (
    element_id int4 NOT NULL,
    muni_id int4 NOT NULL,
    CONSTRAINT element_x_municipality_visibility_pkey PRIMARY KEY (element_id, muni_id),
    CONSTRAINT element_x_municipality_visibility_element_id_fkey FOREIGN KEY (element_id) REFERENCES element(element_id) ON DELETE CASCADE ON UPDATE CASCADE
);

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS TRUE THEN
        ALTER TABLE element_x_municipality_visibility
        ADD CONSTRAINT element_x_municipality_visibility_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON DELETE CASCADE ON UPDATE CASCADE;
    ELSE
        ALTER TABLE element_x_municipality_visibility
        ADD CONSTRAINT element_x_municipality_visibility_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES ext_municipality(muni_id) ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

ALTER TABLE sys_table ADD COLUMN IF NOT EXISTS provider_config jsonb NULL;

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS TRUE THEN
		CREATE OR REPLACE VIEW v_municipality AS
		SELECT * FROM utils.municipality;

		CREATE OR REPLACE VIEW v_streetaxis AS
		SELECT * FROM utils.streetaxis;

		CREATE OR REPLACE VIEW v_address AS
		SELECT * FROM utils.address;

		CREATE OR REPLACE VIEW v_plot AS
		SELECT * FROM utils.plot;

		CREATE OR REPLACE VIEW v_raster_dem AS
		SELECT * FROM utils.raster_dem;

		CREATE OR REPLACE VIEW v_district AS
		SELECT * FROM utils.district;

		CREATE OR REPLACE VIEW v_region AS
		SELECT * FROM utils.region;

		CREATE OR REPLACE VIEW v_province AS
		SELECT * FROM utils.province;

		CREATE OR REPLACE VIEW v_type_street AS
		SELECT * FROM utils.type_street;
	ELSE
		CREATE OR REPLACE VIEW v_municipality AS
		SELECT * FROM ext_municipality;

		CREATE OR REPLACE VIEW v_streetaxis AS
		SELECT * FROM ext_streetaxis;

		CREATE OR REPLACE VIEW v_address AS
		SELECT * FROM ext_address;

		CREATE OR REPLACE VIEW v_plot AS
		SELECT * FROM ext_plot;

		CREATE OR REPLACE VIEW v_raster_dem AS
		SELECT * FROM ext_raster_dem;

		CREATE OR REPLACE VIEW v_district AS
		SELECT * FROM ext_district;

		CREATE OR REPLACE VIEW v_region AS
		SELECT * FROM ext_region;

		CREATE OR REPLACE VIEW v_province AS
		SELECT * FROM ext_province;

		CREATE OR REPLACE VIEW v_type_street AS
		SELECT * FROM ext_type_street;
	END IF;
END $$;

CREATE OR REPLACE VIEW ve_municipality
AS SELECT DISTINCT s.muni_id,
	m.name,
	m.active,
	m.the_geom
FROM v_municipality m,
	selector_municipality s
WHERE m.muni_id = s.muni_id AND s.cur_user = "current_user"()::text;

CREATE OR REPLACE VIEW ve_streetaxis
AS SELECT v_streetaxis.id,
	v_streetaxis.code,
	v_streetaxis.type,
	v_streetaxis.name,
	v_streetaxis.text,
	v_streetaxis.the_geom,
	v_streetaxis.muni_id,
		CASE
			WHEN v_streetaxis.type IS NULL THEN v_streetaxis.name::text
			WHEN v_streetaxis.text IS NULL THEN ((v_streetaxis.name::text || ', '::text) || v_streetaxis.type::text) || '.'::text
			WHEN v_streetaxis.type IS NULL AND v_streetaxis.text IS NULL THEN v_streetaxis.name::text
			ELSE (((v_streetaxis.name::text || ', '::text) || v_streetaxis.type::text) || '. '::text) || v_streetaxis.text
		END AS descript,
	v_streetaxis.source
FROM selector_municipality,
	v_streetaxis
WHERE v_streetaxis.muni_id = selector_municipality.muni_id AND selector_municipality.cur_user = "current_user"()::text;

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS TRUE THEN
		CREATE OR REPLACE VIEW ve_raster_dem
		AS SELECT DISTINCT ON (r.id) r.id,
			c.code,
			c.alias,
			c.raster_type,
			c.descript,
			c.source,
			c.provider,
			c.year,
			r.rast,
			r.rastercat_id,
			r.envelope
		FROM ve_municipality a,
			v_raster_dem r
			JOIN utils.cat_raster c ON c.id = r.rastercat_id
		WHERE st_dwithin(r.envelope, a.the_geom, 0::double precision);
	ELSE
		CREATE OR REPLACE VIEW ve_raster_dem
		AS SELECT DISTINCT ON (r.id) r.id,
			c.code,
			c.alias,
			c.raster_type,
			c.descript,
			c.source,
			c.provider,
			c.year,
			r.rast,
			r.rastercat_id,
			r.envelope
		FROM ve_municipality a,
			v_raster_dem r
			JOIN ext_cat_raster c ON c.id = r.rastercat_id
		WHERE st_dwithin(r.envelope, a.the_geom, 0::double precision);
	END IF;
END $$;

CREATE OR REPLACE VIEW ve_address
AS SELECT v_address.id,
	v_address.muni_id,
	v_address.postcode,
	v_address.streetaxis_id,
	v_address.postnumber,
	v_address.plot_id,
	v_streetaxis.name,
	v_address.the_geom,
	v_address.postcomplement,
	v_address.code,
	v_address.source
FROM selector_municipality s,
	v_address
	LEFT JOIN v_streetaxis ON v_streetaxis.id::text = v_address.streetaxis_id::text
WHERE v_address.muni_id = s.muni_id AND s.cur_user = "current_user"()::text;

CREATE OR REPLACE VIEW ve_plot
AS SELECT v_plot.id,
	v_plot.code,
	v_plot.muni_id,
	v_plot.postcode,
	v_plot.streetaxis_id,
	v_plot.postnumber,
	v_plot.complement,
	v_plot.placement,
	v_plot.square,
	v_plot.observ,
	v_plot.text,
	v_plot.the_geom
FROM selector_municipality s,
	v_plot
WHERE v_plot.muni_id = s.muni_id AND s.cur_user = "current_user"()::text;

CREATE OR REPLACE VIEW ve_district
AS SELECT v_district.*
FROM selector_municipality s,
	v_district
WHERE v_district.muni_id = s.muni_id AND s.cur_user = "current_user"()::text;


CREATE OR REPLACE VIEW vf_arc AS
 SELECT a.arc_id, COALESCE(pp.state, a.state) AS p_state
   FROM arc a
     LEFT JOIN LATERAL ( SELECT pp_1.state
           FROM plan_psector_x_arc pp_1
          WHERE pp_1.arc_id = a.arc_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC
         LIMIT 1) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.state_id = COALESCE(pp.state, a.state) AND ss.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_sector ssec
          WHERE ssec.sector_id = a.sector_id AND ssec.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_municipality sm
          WHERE sm.muni_id = a.muni_id AND sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE (se.expl_id = ANY (array_append(a.expl_visibility::integer[], a.expl_id))) AND se.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW vf_node AS
 SELECT n.node_id, COALESCE(pp.state, n.state) AS p_state
   FROM node n
     LEFT JOIN LATERAL ( SELECT pp_1.state
           FROM plan_psector_x_node pp_1
          WHERE pp_1.node_id = n.node_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC
         LIMIT 1) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.state_id = COALESCE(pp.state, n.state) AND ss.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_sector ssec
          WHERE (ssec.sector_id = n.sector_id OR EXISTS (SELECT 1 FROM node_x_sector_visibility sv WHERE sv.node_id = n.node_id AND sv.sector_id = ssec.sector_id))
            AND ssec.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_municipality sm
          WHERE (sm.muni_id = n.muni_id OR EXISTS (SELECT 1 FROM node_x_municipality_visibility mv WHERE mv.node_id = n.node_id AND mv.muni_id = sm.muni_id))
            AND sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE (se.expl_id = ANY (array_append(n.expl_visibility::integer[], n.expl_id))) AND se.cur_user = CURRENT_USER));

CREATE OR REPLACE VIEW vf_connec AS
SELECT
  c.connec_id,
  COALESCE(pp.state, c.state) AS p_state,
  COALESCE(pp.arc_id, c.arc_id) AS arc_id,
  COALESCE(pp.exit_id, c.pjoint_id) AS pjoint_id,
  COALESCE(pp.exit_type, c.pjoint_type) AS pjoint_type
FROM connec c
LEFT JOIN LATERAL (SELECT pp_1.state,
            pp_1.arc_id,
            l.exit_id,
            l.exit_type
           FROM plan_psector_x_connec pp_1
            LEFT JOIN link l ON l.link_id = pp_1.link_id AND l.state = 2
          WHERE pp_1.connec_id = c.connec_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC, pp_1.state DESC
         LIMIT 1) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.state_id = COALESCE(pp.state, c.state) AND ss.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_sector ssec
          WHERE ssec.sector_id = c.sector_id AND ssec.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_municipality sm
          WHERE sm.muni_id = c.muni_id AND sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE (se.expl_id = ANY (array_append(c.expl_visibility::integer[], c.expl_id))) AND se.cur_user = CURRENT_USER));

 CREATE OR REPLACE VIEW vf_element AS
 SELECT e.element_id
   FROM element e
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.state_id = e.state AND ss.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
            FROM selector_sector ssec
            WHERE (ssec.sector_id = e.sector_id OR EXISTS (SELECT 1 FROM element_x_sector_visibility sv WHERE sv.element_id = e.element_id AND sv.sector_id = ssec.sector_id))
            AND ssec.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
            FROM selector_municipality sm
            WHERE (sm.muni_id = e.muni_id OR EXISTS (SELECT 1 FROM element_x_municipality_visibility mv WHERE mv.element_id = e.element_id AND mv.muni_id = sm.muni_id))
            AND sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE (se.expl_id = ANY (array_append(e.expl_visibility::integer[], e.expl_id))) AND se.cur_user = CURRENT_USER));


CREATE OR REPLACE VIEW ve_element
AS WITH sector_visibility_agg AS (
    SELECT element_id, array_agg(sector_id ORDER BY sector_id) AS sector_visibility
    FROM element_x_sector_visibility
    GROUP BY element_id
),
muni_visibility_agg AS (
    SELECT element_id, array_agg(muni_id ORDER BY muni_id) AS muni_visibility
    FROM element_x_municipality_visibility
    GROUP BY element_id
)
SELECT
  e.element_id,
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
  e.uuid,
  sva.sector_visibility,
  mva.muni_visibility
FROM element e
JOIN vf_element vf ON vf.element_id = e.element_id
JOIN cat_element ON e.elementcat_id::text = cat_element.id::text
LEFT JOIN sector_visibility_agg sva ON sva.element_id = e.element_id
LEFT JOIN muni_visibility_agg mva ON mva.element_id = e.element_id;

DROP VIEW IF EXISTS ve_om_visit;
CREATE OR REPLACE VIEW ve_om_visit
AS SELECT om_visit.id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.status,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.the_geom,
    om_visit.webclient_id,
    om_visit.expl_id
   FROM selector_expl,
    om_visit
  WHERE om_visit.expl_id = selector_expl.expl_id AND selector_expl.cur_user = "current_user"();

INSERT INTO inp_typevalue (typevalue, id, idval, descript, addparam)
VALUES('inp_typevalue_dscenario', 'PATTERN', 'PATTERN', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO config_function (id, function_name, "style", layermanager, actions) VALUES(3536, 'gw_fct_getmincutminsector', '{
  "style": {
    "Valves": {
      "style": "categorized",
      "field": "closed",
      "width": 2,
      "transparency": 0.5
    },
    "Arcs": {
      "style": "categorized",
      "field": "minsector_id",
      "width": 2,
      "transparency": 0.5
    },
    "Connecs": {
      "style": "categorized",
      "field": "minsector_id",
      "width": 2,
      "transparency": 0.5
    }
  }
}'::json, NULL, NULL);

UPDATE sys_function SET function_alias = 'MACROMAPZONES DYNAMIC SECTORITZATION' WHERE id = 3482;


INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_municipality', 'View of town cities and villages', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_streetaxis', 'View of streetaxis', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_address', 'View of entrance numbers', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_plot', 'View of urban properties', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_raster_dem', 'View to store raster DEM', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_district', 'View of districts', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_region', 'View of regions', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_province', 'View of provinces', 'role_edit', 'core');

INSERT INTO sys_table (id, descript, sys_role, "source")
VALUES('v_type_street', 'View of type of street', 'role_edit', 'core');

INSERT INTO inp_typevalue (typevalue, id, idval, descript, addparam)
VALUES('inp_typevalue_dscenario', 'CALIBRATION', 'CALIBRATION', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;


UPDATE config_form_fields SET dv_querytext = 'SELECT id, id as idval FROM cat_element WHERE active IS true'
WHERE formname = 've_element' AND columnname = 'elementcat_id';

UPDATE config_form_tabs SET tooltip='State' WHERE formname='selector_basic' AND tabname='tab_network_state';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4610, 'Mincut has overlapping conflicts', NULL, 1, true, 'ws', 'core', 'UI') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4612, 'Mincut to cancel not found', NULL, 1, true, 'ws', 'core', 'UI') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4614, 'Mincut to delete not found', NULL, 1, true, 'ws', 'core', 'UI') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4616, 'Mincut deleted', NULL, 0, true, 'ws', 'core', 'UI') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4618, 'Node not operative not found', NULL, 2, true, 'ws', 'core', 'UI') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4620, 'You MUST execute the minsector analysis before executing the mincut analysis with 6.1 version.', NULL, 3, true, 'ws', 'core', 'UI') ON CONFLICT DO NOTHING;

UPDATE config_form_fields SET dv_querytext='SELECT function_type AS id, function_type AS idval FROM man_type_function WHERE active AND (featurecat_id IS NULL AND ''ELEMENT''=ANY(feature_type))' WHERE formname='ve_element' AND formtype='form_feature' AND columnname='function_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT function_type AS id, function_type AS idval FROM man_type_function WHERE active AND (featurecat_id IS NULL AND ''CONNEC''=ANY(feature_type))' WHERE formname='ve_connec' AND formtype='form_feature' AND columnname='function_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT function_type AS id, function_type AS idval FROM man_type_function WHERE active AND (featurecat_id IS NULL AND ''NODE''=ANY(feature_type))' WHERE formname='ve_node' AND formtype='form_feature' AND columnname='function_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT function_type AS id, function_type AS idval FROM man_type_function WHERE active AND (featurecat_id IS NULL AND ''ARC''=ANY(feature_type))' WHERE formname='ve_arc' AND formtype='form_feature' AND columnname='function_type' AND tabname='tab_data';

UPDATE config_form_fields SET dv_querytext='SELECT category_type AS id, category_type AS idval FROM man_type_category WHERE active AND (featurecat_id IS NULL AND ''ARC''=ANY(feature_type))' WHERE formname='ve_arc' AND formtype='form_feature' AND columnname='category_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT category_type AS id, category_type AS idval FROM man_type_category WHERE active AND (featurecat_id IS NULL AND ''CONNEC''=ANY(feature_type))' WHERE formname='ve_connec' AND formtype='form_feature' AND columnname='category_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT category_type AS id, category_type AS idval FROM man_type_category WHERE active AND (featurecat_id IS NULL AND ''ELEMENT''=ANY(feature_type))' WHERE formname='ve_element' AND formtype='form_feature' AND columnname='category_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT category_type AS id, category_type AS idval FROM man_type_category WHERE active AND (featurecat_id IS NULL AND ''NODE''=ANY(feature_type))' WHERE formname='ve_node' AND formtype='form_feature' AND columnname='category_type' AND tabname='tab_data';

UPDATE config_form_fields SET dv_querytext='SELECT location_type AS id, location_type AS idval FROM man_type_location WHERE active AND (featurecat_id IS NULL AND ''ARC''=ANY(feature_type))' WHERE formname='ve_arc' AND formtype='form_feature' AND columnname='location_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT location_type AS id, location_type AS idval FROM man_type_location WHERE active AND (featurecat_id IS NULL AND ''CONNEC''=ANY(feature_type))' WHERE formname='ve_connec' AND formtype='form_feature' AND columnname='location_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT location_type AS id, location_type AS idval FROM man_type_location WHERE active AND (featurecat_id IS NULL AND ''ELEMENT''=ANY(feature_type))' WHERE formname='ve_element' AND formtype='form_feature' AND columnname='location_type' AND tabname='tab_data';
UPDATE config_form_fields SET dv_querytext='SELECT location_type AS id, location_type AS idval FROM man_type_location WHERE active AND (featurecat_id IS NULL AND ''NODE''=ANY(feature_type))' WHERE formname='ve_node' AND formtype='form_feature' AND columnname='location_type' AND tabname='tab_data';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4622, 'You MUST select “current_psector” to perform this action', NULL, 2, true, 'utils', 'core', 'UI') ON CONFLICT DO NOTHING;

INSERT INTO sys_message
(id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4624, 'There are values not allowed in the field ''%alias%'' (%column%) of the table ''%table%''', NULL, 0, true, 'utils', 'core', 'AUDIT') ON CONFLICT DO NOTHING;

DELETE FROM config_form_tabs WHERE formname='selector_basic' AND tabname='tab_hydro_state';
DELETE FROM config_typevalue WHERE typevalue='tabname_typevalue' AND id='tab_hydro_state';
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('connec', 'form_feature', 'tab_hydrometer', 'cmb_hydrometer_state', 'lyt_hydrometer_1', 2, 'string', 'combo', 'State:', 'State:', NULL, false, false, true, false, true, 'SELECT name as id, name as idval FROM ext_rtc_hydrometer_state WHERE id IS NOT NULL', NULL, true, NULL, NULL, NULL, '{"saveValue": false, "filterSign":"="}'::json, '{
  "functionName": "filter_table",
  "parameters": {
    "columnfind": "state",
    "field_id": "feature_id"
  }
}'::json, 'v_ui_hydrometer', false, 2);


UPDATE sys_table SET id='ve_municipality' WHERE id='v_ext_municipality';
UPDATE sys_table SET id='ve_streetaxis' WHERE id='v_ext_streetaxis';
UPDATE sys_table SET id='ve_address' WHERE id='v_ext_address';
UPDATE sys_table SET id='ve_plot' WHERE id='v_ext_plot';
UPDATE sys_table SET id='ve_raster_dem' WHERE id='v_ext_raster_dem';
INSERT INTO sys_table (id, descript, sys_role, source) VALUES('ve_district', 'Filtered view of districts', 'role_edit', 'core');

UPDATE sys_style SET layername='ve_municipality' WHERE layername='v_ext_municipality';
UPDATE sys_style SET layername='ve_streetaxis' WHERE layername='v_ext_streetaxis';
UPDATE sys_style SET layername='ve_address' WHERE layername='v_ext_address';
UPDATE sys_style SET layername='ve_plot' WHERE layername='v_ext_plot';

ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_config_control;
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'v_ext_municipality', 've_municipality') WHERE dv_querytext LIKE '%v_ext_municipality%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'v_ext_streetaxis', 've_streetaxis') WHERE dv_querytext LIKE '%v_ext_streetaxis%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'ext_municipality', 'v_municipality') WHERE dv_querytext LIKE '%ext_municipality%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'ext_streetaxis', 'v_streetaxis') WHERE dv_querytext LIKE '%ext_streetaxis%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'ext_address', 'v_address') WHERE dv_querytext LIKE '%ext_address%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'ext_region', 'v_region') WHERE dv_querytext LIKE '%ext_region%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'ext_province', 'v_province') WHERE dv_querytext LIKE '%ext_province%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'ext_district', 'v_district') WHERE dv_querytext LIKE '%ext_district%';
UPDATE config_form_fields SET dv_querytext = replace(dv_querytext, 'ext_type_street', 'v_type_street') WHERE dv_querytext LIKE '%ext_type_street%';

UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'v_ext_municipality', 've_municipality')::json WHERE widgetcontrols::text LIKE '%v_ext_municipality%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'v_ext_streetaxis', 've_streetaxis')::json WHERE widgetcontrols::text LIKE '%v_ext_streetaxis%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'ext_municipality', 'v_municipality')::json WHERE widgetcontrols::text LIKE '%ext_municipality%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'ext_streetaxis', 'v_streetaxis')::json WHERE widgetcontrols::text LIKE '%ext_streetaxis%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'ext_address', 'v_address')::json WHERE widgetcontrols::text LIKE '%ext_address%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'ext_region', 'v_region')::json WHERE widgetcontrols::text LIKE '%ext_region%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'ext_province', 'v_province')::json WHERE widgetcontrols::text LIKE '%ext_province%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'ext_district', 'v_district')::json WHERE widgetcontrols::text LIKE '%ext_district%';
UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'ext_type_street', 'v_type_street')::json WHERE widgetcontrols::text LIKE '%ext_type_street%';

UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'v_ext_municipality', 've_municipality') WHERE dv_querytext LIKE '%v_ext_municipality%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'v_ext_streetaxis', 've_streetaxis') WHERE dv_querytext LIKE '%v_ext_streetaxis%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'ext_municipality', 'v_municipality') WHERE dv_querytext LIKE '%ext_municipality%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'ext_streetaxis', 'v_streetaxis') WHERE dv_querytext LIKE '%ext_streetaxis%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'ext_address', 'v_address') WHERE dv_querytext LIKE '%ext_address%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'ext_region', 'v_region') WHERE dv_querytext LIKE '%ext_region%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'ext_province', 'v_province') WHERE dv_querytext LIKE '%ext_province%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'ext_district', 'v_district') WHERE dv_querytext LIKE '%ext_district%';
UPDATE sys_param_user SET dv_querytext = replace(dv_querytext, 'ext_type_street', 'v_type_street') WHERE dv_querytext LIKE '%ext_type_street%';

UPDATE config_param_system SET value = replace(value, 'v_ext_municipality', 've_municipality') WHERE value LIKE '%v_ext_municipality%';
UPDATE config_param_system SET value = replace(value, 'v_ext_streetaxis', 've_streetaxis') WHERE value LIKE '%v_ext_streetaxis%';
UPDATE config_param_system SET value = replace(value, 'ext_municipality', 'v_municipality') WHERE value LIKE '%ext_municipality%';
UPDATE config_param_system SET value = replace(value, 'ext_streetaxis', 'v_streetaxis') WHERE value LIKE '%ext_streetaxis%';
UPDATE config_param_system SET value = replace(value, 'v_ext_address', 've_address') WHERE value LIKE '%v_ext_address%';
UPDATE config_param_system SET value = replace(value, 'ext_region', 'v_region') WHERE value LIKE '%ext_region%';
UPDATE config_param_system SET value = replace(value, 'ext_province', 'v_province') WHERE value LIKE '%ext_province%';
UPDATE config_param_system SET value = replace(value, 'ext_district', 'v_district') WHERE value LIKE '%ext_district%';
UPDATE config_param_system SET value = replace(value, 'ext_type_street', 'v_type_street') WHERE value LIKE '%ext_type_street%';

UPDATE config_form_fields SET formname='ve_streetaxis' WHERE formname = 'v_ext_streetaxis';
DELETE FROM config_form_fields WHERE formname='ve_streetaxis' AND columnname='expl_id';

UPDATE config_form_fields SET formname='ve_municipality' WHERE formname in ('v_ext_municipality', 'ext_municipality');
DELETE FROM config_form_fields WHERE formname='ve_municipality' AND columnname in ('expl_id', 'sector_id');

UPDATE config_form_fields SET formname='ve_address' WHERE formname = 'v_ext_address';
DELETE FROM config_form_fields WHERE formname='ve_address' AND columnname = 'expl_id';

UPDATE config_form_fields SET formname='ve_plot' WHERE formname = 'v_ext_plot';
DELETE FROM config_form_fields WHERE formname='ve_plot' AND columnname = 'expl_id';
UPDATE config_form_fields SET columnname='code', label='Code:', tooltip='Code' WHERE formname = 've_plot' AND columnname = 'plot_code';
ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_config_control;

DELETE FROM config_param_user WHERE "parameter"='edit_arc_automatic_link2netowrk';

INSERT INTO sys_param_user (id,formname,descript,sys_role,"label",isenabled,layoutorder,project_type,isparent,isautoupdate,"datatype",widgettype,ismandatory,vdefault,layoutname,iseditable,"source")
VALUES ('edit_arc_automatic_link2network','config','Automatic connection of closest connecs to the arc','role_edit','Automatic connection of closest connecs to the arc:',true,9,'utils',false,false,'json','text',true,'{"active":"false", "buffer":"10"}','lyt_other',true,'core');

INSERT INTO sys_table (id,descript,sys_role,"source")
VALUES ('inp_family','Defines inp families contained in the network','role_edit','core');

INSERT INTO sys_table (id,descript,sys_role,"source")
VALUES ('inp_dscenario_pattern','Table to manage dscenario for pattern','role_epa','core');
INSERT INTO sys_table (id,descript,sys_role,"source")
VALUES ('inp_dscenario_pattern_value','Table to manage dscenario for pattern value','role_epa','core');

UPDATE config_param_system SET isenabled = true WHERE "parameter" ILIKE 'basic_search_v2_tab_%';

UPDATE config_form_fields
SET dv_querytext='SELECT ''ALL'' as id, ''ALL'' as idval
UNION
SELECT id, id as idval
FROM sys_feature_type
WHERE classlevel = 1 OR classlevel = 2 OR classlevel = 4'
WHERE formname='config_visit_parameter' AND formtype='form_feature' AND columnname='feature_type' AND tabname='tab_none';

UPDATE config_form_fields SET widgettype='typeahead' WHERE formname='generic' AND formtype='psector' AND columnname='workcat_id_plan' AND tabname='tab_general';
UPDATE config_form_fields SET widgettype='typeahead' WHERE formname='generic' AND formtype='psector' AND columnname='workcat_id' AND tabname='tab_general';


INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('vf_node', 'Filtered nodes', 'role_basic', 'core') ON CONFLICT DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('vf_arc', 'Filtered arcs', 'role_basic', 'core') ON CONFLICT DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('vf_connec', 'Filtered connecs', 'role_basic', 'core') ON CONFLICT DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('vf_element', 'Filtered elements', 'role_basic', 'core') ON CONFLICT DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('vf_gully', 'Filtered gullys', 'role_basic', 'core') ON CONFLICT DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('vf_link', 'Filtered gullys', 'role_basic', 'core') ON CONFLICT DO NOTHING;


INSERT INTO sys_param_user (id,formname,descript,sys_role,"label",isenabled,layoutorder,project_type,isparent,isautoupdate,"datatype",widgettype,ismandatory,layoutname,iseditable,"source",vdefault)
VALUES ('edit_insert_show_elevation_from_dem','config','If true, the elevation will be showed from the DEM raster when inserting a new feature','role_edit','Show elevation from DEM:',true,28,'utils',false,false,'boolean','check',true,'lyt_other',true,'core', 'TRUE') ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4626, 'The following catalogs have invalid dnom: %invalid_dnom%', 'Check the catalogs and correct dnom values', 2, true, 'ws', 'core', 'UI') ON CONFLICT DO NOTHING;

DELETE FROM sys_table WHERE id='rtc_hydrometer';
DELETE FROM sys_table WHERE id='rtc_hydrometer_x_connec';
DELETE FROM sys_table WHERE id='rtc_hydrometer_x_node';

INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active)
VALUES(712, 'Supply Zonification', 'ws', NULL, 'core', true, 'Function process', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true) ON CONFLICT (fid) DO NOTHING;

UPDATE config_param_system
SET value = (
  COALESCE(value::jsonb, '{}'::jsonb)
  || jsonb_build_object(
    'SECTOR', true,
    'DMA', true,
    'DQA', true,
    'PRESSZONE', true,
    'DWFZONE', true,
    'SUPPLYZONE', true,
    'MACROSECTOR', true,
    'MACRODMA', true,
    'MACRODQA', true,
    'MACROOMZONE', true,
    'OMZONE', false,
    'DRAINZONE', false
  )
)::json
WHERE parameter = 'utils_graphanalytics_status';

UPDATE config_param_system SET parameter= 'basic_search_v2_tab_psector', value = '{"sys_display_name":"concat(name,'' ('',text2,'')'')","sys_tablename":"ve_plan_psector","sys_pk":"psector_id","sys_fct":"gw_fct_getinfofromid","sys_filter":"","sys_geom":"the_geom"}'
WHERE parameter = 'basic_search_v2_tab_psector ';

INSERT INTO config_param_system ("parameter", value, descript, "label", dv_querytext, dv_filterbyfield, isenabled, layoutorder, project_type, dv_isparent, isautoupdate, "datatype", widgettype, ismandatory, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, widgetcontrols, placeholder, standardvalue, layoutname)
VALUES('qgis_mapzone_inundation_from_arc', 'false', 'If true, graph inundation starts by selecting an arc', 'Inundation from arc:', NULL, NULL, true, 18, 'utils', NULL, NULL, 'boolean', 'check', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'lyt_admin_other') ON CONFLICT DO NOTHING;


UPDATE config_function
	SET "style"='{
  "style": {
    "point": {
      "style": "categorized",
      "field": "descript",
      "transparency": 0.5,
      "width": 2.5,
      "values": [
        {
          "id": "Disconnected",
          "color": [
            255,
            124,
            64
          ]
        },
        {
          "id": "Conflict",
          "color": [
            14,
            206,
            253
          ]
        }
      ]
    },
    "line": {
      "style": "categorized",
      "field": "descript",
      "transparency": 0.5,
      "width": 2.5,
      "values": [
        {
          "id": "Disconnected",
          "color": [
            255,
            124,
            64
          ]
        },
        {
          "id": "Conflict",
          "color": [
            14,
            206,
            253
          ]
        }
      ]
    },
    "polygon": {
      "style": "categorized",
      "field": "descript",
      "transparency": 0.5
    },
    "Graphconfig": {
      "style": "qml",
      "id": "103"
    }
  }
}'::json
	WHERE id=3508;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4628, 'MAPZONES COULD NOT BE CALCULATED DUE TO ERRORS ON GRAPHCONFIG - CHECK ERRORS PARAGRAPH FOR MORE INFO', NULL, 0, true, 'ws', 'core', 'AUDIT');

UPDATE sys_fprocess SET except_table='anl_node' WHERE fprocess_type = 'Check epa-data' and except_msg is not null and isaudit = TRUE;
UPDATE sys_fprocess SET except_table=NULL WHERE fid IN (482, 272);
UPDATE sys_fprocess SET except_table='anl_arc' WHERE fid IN (169, 284);

UPDATE sys_fprocess SET except_table='anl_arc', query_text='SELECT 295, a.arc_id, a.arccat_id, concat(epa_type, '' using inp_pump table'') AS epa_table, a.expl_id, a.the_geom FROM t_inp_pump JOIN arc a USING (arc_id) WHERE epa_type !=''PUMP''
UNION
SELECT 295, a.arc_id, a.arccat_id, concat(epa_type, '' using inp_conduit table'') AS epa_table, a.expl_id, a.the_geom FROM t_inp_conduit JOIN arc a USING (arc_id) WHERE epa_type !=''CONDUIT''
UNION
SELECT 295, a.arc_id, a.arccat_id, concat(epa_type, '' using inp_outlet table'') AS epa_table, a.expl_id, a.the_geom FROM t_inp_outlet JOIN arc a USING (arc_id) WHERE epa_type !=''OUTLET''
UNION
SELECT 295, a.arc_id, a.arccat_id, concat(epa_type, '' using inp_orifice table'') AS epa_table, a.expl_id, a.the_geom FROM t_inp_orifice JOIN arc a USING (arc_id) WHERE epa_type !=''ORIFICE''
UNION
SELECT 295, a.arc_id, a.arccat_id, concat(epa_type, '' using inp_weir table'') AS epa_table, a.expl_id, a.the_geom FROM t_inp_weir JOIN arc a USING (arc_id) WHERE epa_type !=''WEIR''
UNION
SELECT 295, a.arc_id, a.arccat_id, concat(epa_type, '' using inp_virtual table'') AS epa_table, a.expl_id, a.the_geom FROM t_inp_virtual JOIN arc a USING (arc_id) WHERE epa_type !=''VIRTUAL'''
WHERE fid=295;

UPDATE sys_fprocess SET except_table='anl_arc', query_text='SELECT  a.arc_id,  b.arccat_id, b.expl_id, b.the_geom from t_inp_weir a
JOIN arc b USING (arc_id)
where weir_type is null or cd is null or geom1 is null or geom2 is null or offsetval is NULL'
WHERE fid=529;

UPDATE sys_fprocess SET except_table='anl_arc', query_text='SELECT a.arc_id, b.arccat_id, b.expl_id, b.the_geom from t_inp_orifice a
JOIN arc b USING (arc_id)
where ori_type is null or geom1 is null or offsetval is null'
WHERE fid=530;

UPDATE sys_fprocess SET except_table='anl_node', query_text='SELECT rg_id AS node_id, null as nodecat_id, expl_id, the_geom FROM t_raingage where (form_type is null) OR (intvl is null) OR (rgage_type is null) OR (scf is null)'
WHERE fid=285;

UPDATE sys_fprocess SET except_table='anl_node', query_text='SELECT rg_id as node_id, null as nodecat_id, expl_id, the_geom FROM t_raingage where rgage_type=''TIMESERIES'' AND timser_id IS NULL'
WHERE fid=286;

UPDATE sys_fprocess SET except_table='anl_node', query_text='SELECT rg_id as node_id, null as nodecat_id, expl_id, the_geom FROM t_raingage where rgage_type=''FILE'' AND (fname IS NULL or sta IS NULL or units IS NULL)'
WHERE fid=287;

UPDATE sys_style SET stylevalue = replace(stylevalue, 'MS Shell Dlg 2', 'Arial') WHERE stylevalue LIKE '%MS Shell Dlg 2%';
UPDATE sys_style SET stylevalue = replace(stylevalue, 'Calibri Light', 'Arial') WHERE stylevalue LIKE '%Calibri Light%';

UPDATE sys_function SET function_alias='CHECK DATA ACCORDING TO EPA RULES' WHERE function_name='gw_fct_pg2epa_check_data';
UPDATE cat_feature_node SET graph_delimiter = '{NONE}' WHERE graph_delimiter IS NULL;

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_mapzone_mng_1', 'lyt_mapzone_mng_1', 'layoutMapzoneManager1', '{"lytOrientation":"horizontal"}'::json);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_mapzone_mng_2', 'lyt_mapzone_mng_2', 'layoutMapzoneManager2', '{"lytOrientation":"horizontal"}'::json);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('formtype_typevalue', 'form_mapzone', 'form_mapzone', 'formMapzone', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_dma', 'tab_dma', 'tabRelations', NULL);
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('tabname_typevalue', 'tab_macroomzone', 'tab_macroomzone', 'tabRelations', NULL);

INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_macrosector', 'Macrosector', 'Macrosector', 'role_basic', NULL, NULL, 1, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_sector', 'Sector', 'Sector', 'role_basic', NULL, NULL, 2, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_dma', 'Dma', 'Dma', 'role_basic', NULL, NULL, 3, '{4}');
INSERT INTO config_form_tabs
(formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device)
VALUES('form_mapzone', 'tab_macroomzone', 'Macroomzone', 'Macroomzone', 'role_basic', NULL, NULL, 4, '{4}');

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'hspacer_lyt_bot_3', 'lyt_buttons', 1, NULL, 'hspacer', NULL, NULL, NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_cancel', 'lyt_buttons', 2, 'string', 'button', NULL, 'Close dialog', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Close", "saveValue": false}'::json, '{"functionName": "close_manager",  "parameters":{}}'::json, NULL, false, 1);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'txt_name', 'lyt_mapzone_mng_1', 1, 'string', 'text', 'Filter by: name, id OR code:', 'Word filtered by', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"functionName": "_txt_name_changed", "parameters":{"columnfind":"name, id, code"}}'::json, 'tbl_mapzone_manager', false, NULL);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'chk_active', 'lyt_mapzone_mng_1', 2, 'boolean', 'check', 'Show inactive', 'Show inactive mapzones', NULL, false, false, true, false, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 2);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_flood', 'lyt_mapzone_mng_1', 3, 'string', 'button', NULL, 'Flood action', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon":"174"}'::json, '{"saveValue":false}'::json, '{"functionName": "_handle_flood_analysis_click", "module":"mapzone_manager", "parameters":{}}'::json, 'tbl_mapzone_manager', false, 4);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_execute', 'lyt_mapzone_mng_1', 4, 'string', 'button', NULL, 'Execute action', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon":"169"}'::json, '{"saveValue":false}'::json, '{"functionName": "_open_mapzones_analysis", "module":"mapzone_manager", "parameters":{}}'::json, 'tbl_mapzone_manager', false, 3);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_config', 'lyt_mapzone_mng_1', 5, 'string', 'button', NULL, 'Open configuration', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Config", "saveValue": false, "onContextMenu": "Config"}'::json, '{"functionName": "manage_config", "module":"mapzone_manager", "parameters":{}}'::json, 'tbl_mapzone_manager', false, 5);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_toggle_active', 'lyt_mapzone_mng_1', 6, 'string', 'button', NULL, 'Toggle active status', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Toggle active", "saveValue": false, "onContextMenu": "Toggle active"}'::json, '{"functionName": "_manage_toggle_active", "module":"mapzone_manager", "parameters":{}}'::json, 'tbl_mapzone_manager', false, 6);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_create', 'lyt_mapzone_mng_1', 7, 'string', 'button', NULL, 'Create mapzone', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Create", "saveValue": false, "onContextMenu": "Create"}'::json, '{"functionName": "manage_create", "module":"mapzone_manager", "parameters":{}}'::json, 'tbl_mapzone_manager', false, 7);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_update', 'lyt_mapzone_mng_1', 8, 'string', 'button', NULL, 'Update mapzone', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Update", "saveValue": false, "onContextMenu": "Update"}'::json, '{"functionName": "manage_update", "module":"mapzone_manager", "parameters":{}}'::json, 'tbl_mapzone_manager', false, 8);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('mapzone_manager', 'form_mapzone', 'tab_none', 'btn_delete', 'lyt_mapzone_mng_1', 9, 'string', 'button', NULL, 'Delete mapzone', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Delete", "saveValue": false, "onContextMenu": "Delete"}'::json, '{"functionName": "_manage_delete", "module":"mapzone_manager", "parameters":{}}'::json, 'tbl_mapzone_manager', false, 9);

DELETE FROM sys_message WHERE id = 4018;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4018, 'Use psectors: %v_usepsector%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message
(id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4632, 'Hydraulic performance for this result: %(100*v_performance)::numeric(12,2)% %', NULL, 0, true, 'ud', 'core', 'AUDIT');

INSERT INTO sys_table (id,descript,sys_role,"source")
VALUES ('mapzone_graph','Table to manage graph for mapzones','role_edit','core');

INSERT INTO mapzone_graph (node_id, mapzone_id, mapzone_type, flow_sign)
SELECT node_id, dma_id, 'DMA', flow_sign
FROM om_waterbalance_dma_graph
ON CONFLICT (node_id, mapzone_id) DO NOTHING;

DROP TABLE IF EXISTS om_waterbalance_dma_graph;
DELETE FROM sys_table WHERE id = 'om_waterbalance_dma_graph';

INSERT INTO sys_feature_class (id, type, epa_default, man_table) VALUES ('SAMPLEPOINT', 'CONNEC', 'UNDEFINED', 'man_samplepoint');

INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('man_samplepoint', 'Additional information for samplepoint management', 'role_edit', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;

DELETE FROM sys_table WHERE id = 'samplepoint';
DELETE FROM sys_table WHERE id = 've_samplepoint';
DELETE FROM sys_function WHERE id = 1122; -- gw_trg_edit_samplepoint
DROP FUNCTION IF EXISTS gw_trg_edit_samplepoint;

INSERT INTO config_param_system ("parameter", value, descript, "label", dv_querytext, dv_filterbyfield, isenabled, layoutorder, project_type, dv_isparent, isautoupdate, "datatype", widgettype, ismandatory, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, widgetcontrols, placeholder, standardvalue, layoutname)
VALUES('edit_sys_code_autofill', '{"node":false, "arc":true, "connec":false, "gully":false}',
'Allow activate automatic update of sys_code for features. In case of true, the field will be filled with an UUID',
'Auto sys_code:', NULL, NULL, true, 15, 'utils', false, false, 'json', 'linetext', true, true, NULL, NULL, NULL, NULL, NULL, NULL, 'lyt_system');

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3540, 'gw_trg_update_element_mapzones', 'utils', 'trigger', NULL, NULL, 'Trigger function that update automatically the mapzones columns from feature', 'role_basic', NULL, 'core', NULL);

INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('node_x_sector_visibility', 'Table to manage visibility of nodes in sectors', 'role_edit', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('node_x_municipality_visibility', 'Table to manage visibility of nodes in municipalities', 'role_edit', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('element_x_sector_visibility', 'Table to manage visibility of elements in sectors', 'role_edit', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam)
VALUES('element_x_municipality_visibility', 'Table to manage visibility of elements in municipalities', 'role_edit', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;

UPDATE config_param_system
SET value = jsonb_set(
    value::jsonb,
    '{sys_fct_tablename}',
    '"ve_arc"'
)
WHERE parameter = 'basic_search_v2_tab_network_arc';

UPDATE config_param_system
SET value = jsonb_set(
    value::jsonb,
    '{sys_fct_tablename}',
    '"ve_node"'
)
WHERE parameter = 'basic_search_v2_tab_network_node';

UPDATE config_param_system
SET value = jsonb_set(
    value::jsonb,
    '{sys_fct_tablename}',
    '"ve_connec"'
)
WHERE parameter = 'basic_search_v2_tab_network_connec';

UPDATE sys_table SET provider_config = jsonb_set(provider_config, '{provider_key}', '"postgres"') WHERE provider_config IS NULL;


UPDATE sys_fprocess SET query_text='SELECT DISTINCT t1.arc_id, t1.arccat_id, t1.state as state1, t2.arc_id as arc_id_aux, t1.node_1, t1.node_2, t1.expl_id, t1.the_geom 
 FROM ve_arc AS t1 JOIN ve_arc AS t2 USING(the_geom)
 WHERE t1.arc_id != t2.arc_id AND t1.state > 0 AND t2.state>0' 
WHERE fid=479;
 
UPDATE sys_fprocess SET query_text='SELECT node_id, nodecat_id, the_geom, n.expl_id FROM t_node n JOIN value_state_type s ON id=state_type WHERE n.state > 0 AND s.is_operative IS FALSE AND verified <> 2'
WHERE fid=187;

UPDATE sys_fprocess SET query_text='SELECT a.arc_id, arccat_id, a.the_geom, expl_id FROM t_arc a WHERE slope < 0 AND state > 0 AND inverted_slope IS FALSE'
WHERE fid=251;

UPDATE sys_fprocess SET query_text='SELECT c.connec_id, c.conneccat_id, c.the_geom, c.expl_id, l.feature_type, link_id FROM t_arc a, t_link l 
JOIN t_connec c ON l.feature_id = c.connec_id WHERE st_dwithin(a.the_geom, st_endpoint(l.the_geom), 0.01) AND exit_type = ''ARC'' 
AND (a.arc_id <> c.arc_id or c.arc_id is null)   AND l.feature_type = ''CONNEC'' AND a.state=1 and c.state = 1 and l.state=1 EXCEPT 
SELECT c.connec_id, c.conneccat_id, c.the_geom, c.expl_id, l.feature_type, link_id  FROM t_node n, t_link l JOIN t_connec c ON l.feature_id = c.connec_id 
WHERE st_dwithin(n.the_geom, st_endpoint(l.the_geom), 0.01) AND exit_type IN (''NODE'', ''ARC'')  AND l.feature_type = ''CONNEC'' AND n.state=1 and c.state = 1 
and l.state=1 ORDER BY feature_type, link_id'
WHERE fid=257;

UPDATE sys_fprocess SET query_text='with a as (SELECT arc_id, node_1, node_2, arccat_id, expl_id, state, the_geom FROM t_arc WHERE state = 1),
n1 as (SELECT arc.arc_id, node.node_id, min(ST_Distance(node.the_geom, ST_startpoint(arc.the_geom))) as d FROM t_node node, t_arc arc
WHERE arc.state = 1 and node.state = 1 and ST_DWithin(ST_startpoint(arc.the_geom), node.the_geom, 0.02) group by 1,2 ORDER BY 1 DESC,3 DESC
), 
n2 as (	SELECT arc.arc_id, node.node_id, min(ST_Distance(node.the_geom, ST_endpoint(arc.the_geom))) as d FROM t_node node, t_arc arc
WHERE arc.state = 1 and node.state = 1 and ST_DWithin(ST_endpoint(arc.the_geom), node.the_geom, 0.02) group by 1,2 ORDER BY 1 DESC,3 DESC
)
select a.* from a 
left join n1 on a.arc_id = n1.arc_id
left join n2 on a.arc_id = n2.arc_id 
where (a.node_1 != n1.node_id) or (a.node_2 != n2.node_id)'
WHERE fid=372;

UPDATE sys_fprocess SET query_text='SELECT  * FROM t_node a JOIN cat_node nc ON nodecat_id=id JOIN cat_feature_node nt ON nt.id=nc.node_type WHERE a.state>0 AND isarcdivide=false AND arc_id IS NULL'
WHERE fid=443;

UPDATE sys_fprocess SET query_text='SELECT connec_id, conneccat_id, the_geom, expl_id FROM t_connec WHERE state > 0 
AND (sector_id=0 OR sector_id=-1)'
WHERE fid=478;

UPDATE sys_fprocess SET query_text='SELECT connec_id, conneccat_id, the_geom, expl_id FROM t_connec WHERE connec_id IN 
(SELECT feature_id FROM link WHERE state=1 GROUP BY feature_id HAVING count(*) > 1)'
WHERE fid=480;

INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES('visitmanager_form', 'utils', 'tbl_visit_manager', 'id', 0, true, NULL, NULL, NULL, '{
  "header": "visit_id",
  "accessorKey": "id"
}'::json);

DELETE FROM config_param_system
	WHERE "parameter"='basic_search_v2_tab_hydrometer';

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
		ALTER TABLE connec ADD CONSTRAINT connec_plot_id_fkey FOREIGN KEY (plot_id) REFERENCES utils.plot(id) ON UPDATE CASCADE ON DELETE RESTRICT;
	ELSE
		ALTER TABLE connec ADD CONSTRAINT connec_plot_id_fkey FOREIGN KEY (plot_id) REFERENCES ext_plot(id) ON UPDATE CASCADE ON DELETE RESTRICT;
	END IF;
END $$;

CREATE INDEX connec_plot_code ON connec USING btree (code);


ALTER TABLE cat_feature_node ALTER COLUMN graph_delimiter SET DEFAULT '{NONE}';

CREATE INDEX IF NOT EXISTS connec_customer_code_idx ON connec USING btree (customer_code);
CREATE INDEX IF NOT EXISTS ext_rtc_hydrometer_customer_code_idx ON ext_rtc_hydrometer USING btree (customer_code);

ALTER TABLE element DROP CONSTRAINT IF EXISTS element_expl_id_fkey;
ALTER TABLE element ADD CONSTRAINT element_expl_id_fkey FOREIGN KEY (expl_id) REFERENCES exploitation(expl_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE element DROP CONSTRAINT IF EXISTS element_sector_id;
ALTER TABLE element ADD CONSTRAINT element_sector_id_fkey FOREIGN KEY (sector_id) REFERENCES sector(sector_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE element DROP CONSTRAINT IF EXISTS element_brand_id;
ALTER TABLE element DROP CONSTRAINT IF EXISTS element_brand_id_fkey;
ALTER TABLE element ADD CONSTRAINT element_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE element DROP CONSTRAINT IF EXISTS element_model_id;
ALTER TABLE element DROP CONSTRAINT IF EXISTS element_model_id_fkey;
ALTER TABLE element ADD CONSTRAINT element_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE arc DROP CONSTRAINT IF EXISTS arc_brand_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE arc DROP CONSTRAINT IF EXISTS arc_minsector_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_minsector_id_fkey FOREIGN KEY (minsector_id) REFERENCES minsector(minsector_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE arc DROP CONSTRAINT IF EXISTS arc_model_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE connec DROP CONSTRAINT IF EXISTS connec_minsector_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_minsector_id_fkey FOREIGN KEY (minsector_id) REFERENCES minsector(minsector_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE node DROP CONSTRAINT IF EXISTS node_brand_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE node DROP CONSTRAINT IF EXISTS node_minsector_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_minsector_id_fkey FOREIGN KEY (minsector_id) REFERENCES minsector(minsector_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE node DROP CONSTRAINT IF EXISTS node_model_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id) ON UPDATE CASCADE ON DELETE RESTRICT;

DROP TRIGGER IF EXISTS gw_trg_edit_controls ON node;
DROP TRIGGER IF EXISTS gw_trg_edit_controls ON arc;
DROP TRIGGER IF EXISTS gw_trg_edit_controls ON connec;
DROP TRIGGER IF EXISTS gw_trg_edit_controls ON link;

CREATE TRIGGER gw_trg_edit_controls BEFORE DELETE OR UPDATE
ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_controls('node_id');

CREATE TRIGGER gw_trg_edit_controls BEFORE DELETE OR UPDATE
ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_controls('arc_id');

CREATE TRIGGER gw_trg_edit_controls BEFORE DELETE OR UPDATE
ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_controls('connec_id');

CREATE TRIGGER gw_trg_edit_controls BEFORE DELETE OR UPDATE
ON link FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_controls('link_id');

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
		DROP TRIGGER gw_trg_fk_array_array_table_expl ON utils.municipality;
		DROP TRIGGER gw_trg_fk_array_array_table_sector ON utils.municipality;
	ELSE
		DROP TRIGGER gw_trg_fk_array_array_table_expl ON ext_municipality;
		DROP TRIGGER gw_trg_fk_array_array_table_sector ON ext_municipality;
	END IF;
END $$;

create trigger gw_trg_edit_address instead of insert or delete or update on ve_address for each row execute function gw_trg_edit_address();
create trigger gw_trg_edit_municipality instead of insert or delete or update on ve_municipality for each row execute function gw_trg_edit_municipality();
create trigger gw_trg_edit_plot instead of insert or delete or update on ve_plot for each row execute function gw_trg_edit_plot();
create trigger gw_trg_edit_streetaxis instead of insert or delete or update on ve_streetaxis for each row execute function gw_trg_edit_streetaxis();

CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_visibility ON node
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_visibility', 'exploitation', 'expl_id');

CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_visibility ON arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_visibility', 'exploitation', 'expl_id');

CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_visibility ON connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_visibility', 'exploitation', 'expl_id');

CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_visibility ON link
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_visibility', 'exploitation', 'expl_id');

CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_visibility ON element
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_visibility', 'exploitation', 'expl_id');

DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_sector ON exploitation;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON exploitation;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON sector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON sector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON macroomzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_expl ON omzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON sector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON exploitation;

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON exploitation 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON sector 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macrosector 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON dma 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON omzone 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macroomzone 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE OF sector_id ON sector
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('sector_id','{"utils.municipality":"sector_id", "exploitation":"sector_id"}');
        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE OF expl_id ON exploitation
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('expl_id','{"supplyzone":"expl_id", "macrodma":"expl_id", "macrodqa":"expl_id", "macroomzone":"expl_id", "utils.municipality":"expl_id"}');

        DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON utils.municipality;
        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE OF muni_id ON utils.municipality
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('muni_id','{"supplyzone":"muni_id", "exploitation":"muni_id"}');
    ELSE
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON exploitation 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON sector 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macrosector 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON dma 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON omzone 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE OF muni_id ON macroomzone 
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE OF sector_id ON sector
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('sector_id','{"ext_municipality":"sector_id", "exploitation":"sector_id"}');
        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE OF expl_id ON exploitation
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('expl_id','{"supplyzone":"expl_id", "macrodma":"expl_id", "macrodqa":"expl_id", "macroomzone":"expl_id", "ext_municipality":"expl_id"}');

        DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON ext_municipality;
        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE OF muni_id ON ext_municipality
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('muni_id','{"supplyzone":"muni_id", "exploitation":"muni_id"}');
    END IF;

    CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON exploitation 
    FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON sector 
    FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON macrosector 
    FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON dma 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON dma 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON omzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON omzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');

    CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE OF expl_id ON macroomzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
	CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE OF sector_id ON macroomzone 
	FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');
END; $$;

CREATE TRIGGER gw_trg_edit_om_visit INSTEAD OF INSERT OR DELETE OR UPDATE
ON ve_om_visit FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_om_visit('om_visit');

CREATE TRIGGER gw_trg_edit_element INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_element
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_element('parent');

CREATE TRIGGER gw_trg_update_element_mapzones AFTER INSERT ON element_x_node
FOR EACH ROW EXECUTE FUNCTION gw_trg_update_element_mapzones('element_x_node');

CREATE TRIGGER gw_trg_update_element_mapzones AFTER INSERT ON element_x_arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_update_element_mapzones('element_x_arc');

CREATE TRIGGER gw_trg_update_element_mapzones AFTER INSERT ON element_x_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_update_element_mapzones('element_x_connec');

CREATE TRIGGER gw_trg_update_element_mapzones AFTER INSERT ON element_x_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_update_element_mapzones('element_x_link');

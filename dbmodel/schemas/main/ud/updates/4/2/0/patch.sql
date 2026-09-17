/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

ALTER TABLE man_wwtp ALTER COLUMN wwtp_type SET DEFAULT 0;
ALTER TABLE man_wwtp ALTER COLUMN treatment_type SET DEFAULT 0;



SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"dwfzone", "column":"drainzone_id", "dataType":"int4"}}$$);

DROP VIEW IF EXISTS v_ui_plan_arc_cost;
DROP VIEW IF EXISTS v_plan_result_arc;
DROP VIEW IF EXISTS v_plan_psector;
DROP VIEW IF EXISTS v_plan_current_psector;
DROP VIEW IF EXISTS v_plan_psector_all;
DROP VIEW IF EXISTS v_plan_psector_budget;
DROP VIEW IF EXISTS v_plan_psector_budget_arc;
DROP VIEW IF EXISTS v_plan_psector_budget_detail;
DROP VIEW IF EXISTS v_edit_inp_dscenario_conduit;
DROP VIEW IF EXISTS v_ui_node_x_connection_downstream;
DROP VIEW IF EXISTS v_ui_node_x_connection_upstream;
DROP VIEW IF EXISTS v_plan_arc;
DROP VIEW IF EXISTS v_plan_aux_arc_pavement;
DROP VIEW IF EXISTS v_edit_inp_conduit;
DROP VIEW IF EXISTS v_edit_inp_orifice;
DROP VIEW IF EXISTS v_edit_inp_outlet;
DROP VIEW IF EXISTS v_edit_inp_pump;
DROP VIEW IF EXISTS v_edit_inp_virtual;
DROP VIEW IF EXISTS v_edit_inp_weir;
DROP VIEW IF EXISTS v_ui_workcat_x_feature_end;
DROP VIEW IF EXISTS v_edit_arc;
DROP VIEW IF EXISTS ve_pol_storage;
DROP VIEW IF EXISTS ve_pol_wwtp;
DROP VIEW IF EXISTS ve_pol_chamber;
DROP VIEW IF EXISTS ve_pol_netgully;
DROP VIEW IF EXISTS v_ui_plan_node_cost;
DROP VIEW IF EXISTS v_plan_result_node;
DROP VIEW IF EXISTS v_plan_psector_budget_node;
DROP VIEW IF EXISTS v_plan_node;
DROP VIEW IF EXISTS v_edit_inp_dscenario_outfall;
DROP VIEW IF EXISTS v_edit_inp_outfall;
DROP VIEW IF EXISTS v_edit_inp_dscenario_storage;
DROP VIEW IF EXISTS v_edit_inp_storage;
DROP VIEW IF EXISTS v_edit_inp_netgully;
DROP VIEW IF EXISTS v_edit_inp_divider;
DROP VIEW IF EXISTS v_edit_inp_dscenario_inflows;
DROP VIEW IF EXISTS v_edit_inp_dscenario_inflows_poll;
DROP VIEW IF EXISTS v_edit_inp_dscenario_junction;
DROP VIEW IF EXISTS v_edit_inp_dscenario_treatment;
DROP VIEW IF EXISTS v_edit_inp_dwf;
DROP VIEW IF EXISTS v_edit_inp_inflows;
DROP VIEW IF EXISTS v_edit_inp_inflows_poll;
DROP VIEW IF EXISTS v_edit_inp_treatment;
DROP VIEW IF EXISTS v_edit_inp_junction;
DROP VIEW IF EXISTS v_edit_node;
DROP VIEW IF EXISTS v_ui_arc_x_relations;
DROP VIEW IF EXISTS v_ui_workcat_x_feature_end;
DROP VIEW IF EXISTS v_ui_node_x_connection_upstream;
DROP VIEW IF EXISTS v_ui_plan_arc_cost;
DROP VIEW IF EXISTS ve_connec_cjoin;
DROP VIEW IF EXISTS ve_connec_vconnec;
DROP VIEW IF EXISTS v_edit_connec;
DROP VIEW IF EXISTS v_edit_inp_gully;
DROP VIEW IF EXISTS ve_gully_ginlet;
DROP VIEW IF EXISTS ve_gully_pgully;
DROP VIEW IF EXISTS ve_gully_vgully;
DROP VIEW IF EXISTS v_edit_gully;
DROP VIEW IF EXISTS v_edit_link_connec;
DROP VIEW IF EXISTS v_edit_link_gully;
DROP VIEW IF EXISTS ve_link_link;
DROP VIEW IF EXISTS v_edit_link;

-- TODO: Check if this is needed
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"arc", "column":"drainzone_id", "newName":"dma_id"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"node", "column":"drainzone_id", "newName":"dma_id"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"connec", "column":"drainzone_id", "newName":"dma_id"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"gully", "column":"drainzone_id", "newName":"dma_id"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"link", "column":"drainzone_id", "newName":"dma_id"}}$$);

CREATE TABLE IF NOT EXISTS dma (
    dma_id SERIAL,
    name TEXT,
    descript TEXT,
    muni_id INT4[],
    expl_id INT4[],
    sector_id INT4[],
    graphconfig JSON,
    active BOOLEAN DEFAULT TRUE,
    the_geom GEOMETRY(POLYGON, SRID_VALUE),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT DEFAULT current_user,
    updated_at TIMESTAMP,
    updated_by TEXT,
    CONSTRAINT dma_pk PRIMARY KEY (dma_id)
);

ALTER TABLE dwfzone ADD CONSTRAINT dwfzone_drainzone_fk FOREIGN KEY (drainzone_id) REFERENCES drainzone(drainzone_id);


DELETE FROM sys_foreignkey WHERE target_table = 'dma';

DROP TABLE IF EXISTS inp_inlet;
CREATE TABLE inp_inlet (
	node_id integer NOT NULL,
	y0 numeric(12, 4) NULL,
	ysur numeric(12, 4) NULL,
	apond numeric(12, 4) NULL,
	inlet_type varchar(30) NULL,
	outlet_type varchar(30) NULL,
	gully_method varchar(30) NULL,
	custom_top_elev float8 NULL,
	custom_depth float8 NULL,
	inlet_length float8 NULL,
	inlet_width float8 NULL,
	cd1 float8 NULL,
	cd2 float8 NULL,
	efficiency float8 NULL,
    CONSTRAINT inp_inlet_pkey PRIMARY KEY (node_id),
	CONSTRAINT inp_inlet_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE inp_dscenario_inlet (
	dscenario_id int4 NOT NULL,
	node_id integer NOT NULL,
	elev float8 NULL,
	ymax float8 NULL,
	y0 numeric(12, 4) NULL,
	ysur numeric(12, 4) NULL,
	apond numeric(12, 4) NULL,
	inlet_type varchar(30) NULL,
	outlet_type varchar(30) NULL,
	gully_method varchar(30) NULL,
	custom_top_elev float8 NULL,
	custom_depth float8 NULL,
	inlet_length float8 NULL,
	inlet_width float8 NULL,
	cd1 float8 NULL,
	cd2 float8 NULL,
	efficiency float8 NULL,
	CONSTRAINT inp_dscenario_inlet_pkey PRIMARY KEY (dscenario_id, node_id),
	CONSTRAINT inp_dscenario_inlet_dscenario_id_fkey FOREIGN KEY (dscenario_id) REFERENCES cat_dscenario(dscenario_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT inp_dscenario_inlet_node_id_fkey FOREIGN KEY (node_id) REFERENCES inp_inlet(node_id) ON DELETE CASCADE ON UPDATE CASCADE
);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"temp_gully", "column":"gully_id", "dataType":"varchar(30)"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"inp_gully", "column":"method", "newName":"gully_method"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"inp_netgully", "column":"method", "newName":"gully_method"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ve_epa_netgully", "column":"method", "newName":"gully_method"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ve_epa_gully", "column":"method", "newName":"gully_method"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"temp_arc_flowregulator", "column":"arc_id", "dataType":"varchar(30)"}}$$);


DROP TABLE IF EXISTS macrominisector;

/*
-- Add expl_id and muni_id to sector
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"sector", "column":"expl_id", "dataType":"INT4[]", "isUtils":"True"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"sector", "column":"muni_id", "dataType":"INT4[]", "isUtils":"True"}}$$);

-- Add sector_id and muni_id to explotation
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"exploitation", "column":"sector_id", "dataType":"INT4[]", "isUtils":"True"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"exploitation", "column":"muni_id", "dataType":"INT4[]", "isUtils":"True"}}$$);

-- Add expl_id and sector_id to ext_municipality
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"ext_municipality", "column":"expl_id", "dataType":"INT4[]", "isUtils":"True"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"ext_municipality", "column":"sector_id", "dataType":"INT4[]", "isUtils":"True"}}$$);


-- Add muni_id and sector_id to drainzone
DROP VIEW IF EXISTS v_edit_drainzone;
DROP VIEW IF EXISTS v_ui_drainzone;
ALTER TABLE drainzone ALTER COLUMN expl_id TYPE INT4[] USING ARRAY[expl_id];
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"drainzone", "column":"muni_id", "dataType":"INT4[]", "isUtils":"True"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"drainzone", "column":"sector_id", "dataType":"INT4[]", "isUtils":"True"}}$$);

-- Add muni_id and sector_id to dwfzone
DROP VIEW IF EXISTS v_edit_dwfzone;
DROP VIEW IF EXISTS v_ui_dwfzone;
ALTER TABLE dwfzone ALTER COLUMN expl_id TYPE INT4[] USING ARRAY[expl_id];
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"dwfzone", "column":"muni_id", "dataType":"INT4[]", "isUtils":"True"}}$$);
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"dwfzone", "column":"sector_id", "dataType":"INT4[]", "isUtils":"True"}}$$);

-- Change expl_id type to INT4[] in Macroomzone
DROP VIEW IF EXISTS v_edit_macroomzone;
DROP VIEW IF EXISTS v_ui_macroomzone;
ALTER TABLE macroomzone DROP CONSTRAINT IF EXISTS macroomzone_expl_id_fkey;
ALTER TABLE macroomzone ALTER COLUMN expl_id TYPE INT4[] USING ARRAY[expl_id];

*/


SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME", "table":"man_outfall", "column":"discharge_medium", "newName":"outfall_medium", "isUtils":"False"}}$$);
DELETE FROM sys_foreignkey WHERE typevalue_name='discharge_medium_typevalue';
UPDATE edit_typevalue SET typevalue='outfall_medium_typevalue' WHERE typevalue='discharge_medium_typevalue';
INSERT INTO sys_foreignkey (typevalue_table, typevalue_name, target_table, target_field, parameter_id, active) VALUES('edit_typevalue', 'outfall_medium_typevalue', 'man_outfall', 'outfall_medium', NULL, true);
UPDATE config_form_fields SET "label"='outfall_medium', tooltip='outfall_medium', dv_querytext='SELECT id, idval FROM edit_typevalue WHERE typevalue = ''outfall_medium_typevalue''' WHERE formname='ve_node_outfall' AND formtype='form_feature' AND columnname='discharge_medium' AND tabname='tab_data';

SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD", "table":"man_netinit", "column":"inlet_medium", "dataType":"int4", "isUtils":"False"}}$$);
INSERT INTO edit_typevalue (typevalue, id, idval, descript, addparam) VALUES('inlet_medium_typevalue', '0', 'Undefined', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_foreignkey (typevalue_table, typevalue_name, target_table, target_field, parameter_id, active) VALUES('edit_typevalue', 'inlet_medium_typevalue', 'man_netinit', 'inlet_medium', NULL, true) ON CONFLICT (typevalue_table, typevalue_name, target_table, target_field) DO NOTHING;
UPDATE config_form_fields SET layoutname='lyt_data_1', widgettype='combo', dv_querytext='SELECT id, idval FROM edit_typevalue WHERE typevalue = ''inlet_medium_typevalue''', dv_isnullvalue=TRUE WHERE columnname='inlet_medium' AND formname ILIKE '%netinit%';


SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP", "table":"inp_dscenario_frpump", "column":"pump_type", "isUtils":"False"}}$$);
ALTER TABLE inp_dscenario_froutlet ALTER COLUMN outlet_type DROP NOT NULL;
ALTER TABLE inp_dscenario_frorifice ALTER COLUMN orifice_type DROP NOT NULL;
ALTER TABLE inp_dscenario_frweir ALTER COLUMN weir_type DROP NOT NULL;
ALTER TABLE inp_froutlet ALTER COLUMN outlet_type DROP NOT NULL;
ALTER TABLE inp_frorifice ALTER COLUMN orifice_type DROP NOT NULL;
ALTER TABLE inp_frweir ALTER COLUMN weir_type DROP NOT NULL;

ALTER TABLE archived_psector_gully_traceability RENAME COLUMN tstamp TO created_at;
ALTER TABLE archived_psector_gully_traceability RENAME COLUMN insert_user TO created_by;
ALTER TABLE archived_psector_gully_traceability RENAME COLUMN lastupdate TO updated_at;
ALTER TABLE archived_psector_gully_traceability RENAME COLUMN lastupdate_user TO updated_by;

ALTER TABLE archived_psector_gully_traceability RENAME to archived_psector_gully;
ALTER SEQUENCE archived_psector_gully_traceability_id_seq RENAME TO archived_psector_gully_id_seq;
ALTER TABLE archived_psector_gully RENAME CONSTRAINT audit_psector_gully_traceability_pkey TO archived_psector_gully_pkey;

ALTER TABLE archived_psector_gully drop column streetname;
ALTER TABLE archived_psector_gully drop column streetname2;

UPDATE sys_foreignkey SET target_table='archived_psector_gully' WHERE typevalue_table='om_typevalue' AND typevalue_name='fluid_type' AND target_table='archived_psector_gully_traceability' AND target_field='fluid_type';
UPDATE sys_table SET descript='archived_psector_gully', id='archived_psector_gully' WHERE id='archived_psector_gully_traceability';


DO $function$
DECLARE
    v_crm boolean;
BEGIN

    SELECT value::boolean INTO v_crm FROM config_param_system WHERE parameter='admin_crm_schema';

    PERFORM gw_fct_admin_manage_fields(format($${"data":{"action":"RENAME", "table":"ext_cat_hydrometer", "column":"voltman_flow", "newName":"type", "isCrm":%s}}$$, v_crm::text)::json);
    PERFORM gw_fct_admin_manage_fields(format($${"data":{"action":"RENAME", "table":"ext_cat_hydrometer", "column":"multi_jet_flow", "newName":"flownom", "isCrm":%s}}$$, v_crm::text)::json);

END $function$;


CREATE TABLE om_waterbalance_dma_graph (
    node_id int4 NOT NULL,
    dma_id int4 NOT NULL,
    flow_sign int2 NULL,
    CONSTRAINT om_waterbalance_dma_graph_unique UNIQUE (dma_id, node_id),
    CONSTRAINT om_waterbalance_dma_graph_pkey PRIMARY KEY (node_id, dma_id),
    CONSTRAINT om_waterbalance_dma_graph_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT om_waterbalance_dma_graph_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE man_cjoin (
	connec_id int4 NOT NULL,
	CONSTRAINT man_cjoin_pkey PRIMARY KEY (connec_id),
	CONSTRAINT man_cjoin_connec_id_fkey FOREIGN KEY (connec_id) REFERENCES connec(connec_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE man_ginlet (
	gully_id int4 NOT NULL,
	CONSTRAINT man_ginlet_pkey PRIMARY KEY (gully_id),
	CONSTRAINT man_ginlet_gully_id_fkey FOREIGN KEY (gully_id) REFERENCES gully(gully_id) ON DELETE CASCADE ON UPDATE CASCADE
);


DROP VIEW IF EXISTS v_edit_inp_dscenario_frorifice;
DROP VIEW IF EXISTS v_edit_inp_frorifice;
DROP VIEW IF EXISTS v_edit_inp_dscenario_frpump;
DROP VIEW IF EXISTS v_edit_inp_frpump;
DROP VIEW IF EXISTS v_edit_inp_dscenario_frweir;
DROP VIEW IF EXISTS v_edit_inp_frweir;
DROP VIEW IF EXISTS v_edit_inp_dscenario_froutlet;
DROP VIEW IF EXISTS v_edit_inp_froutlet;
DROP VIEW IF EXISTS ve_epa_frorifice;
DROP VIEW IF EXISTS ve_epa_frweir;
DROP VIEW IF EXISTS ve_epa_froutlet;
DROP VIEW IF EXISTS ve_epa_frpump;
DROP VIEW IF EXISTS ve_element_eorifice;
DROP VIEW IF EXISTS ve_element_eweir;
DROP VIEW IF EXISTS ve_element_eoutlet;
DROP VIEW IF EXISTS ve_element_epump;
DROP VIEW IF EXISTS ve_man_frelem;
DROP VIEW IF EXISTS ve_frelem CASCADE;
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"man_frelem", "column":"order_id"}}$$);

DROP VIEW IF EXISTS v_edit_dwfzone;
DROP VIEW IF EXISTS v_ui_dwfzone;
DROP VIEW IF EXISTS v_state_samplepoint;
DROP VIEW IF EXISTS v_expl_gully;
DROP VIEW IF EXISTS v_man_gully;
DROP VIEW IF EXISTS v_state_link_connec;
DROP VIEW IF EXISTS v_state_link_gully;
DROP VIEW IF EXISTS v_state_gully;
DROP VIEW IF EXISTS vi_pollutants;
DROP VIEW IF EXISTS v_state_element;



CREATE OR REPLACE VIEW v_edit_dwfzone
AS SELECT d.dwfzone_id,
    d.code,
    d.name,
    et.idval AS dwfzone_type,
    d.descript,
    d.graphconfig::text AS graphconfig,
    d.stylesheet::text AS stylesheet,
    d.link,
    d.muni_id,
    d.expl_id,
    d.sector_id,
    d.lock_level,
    d.drainzone_id,
    d.the_geom,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by
   FROM selector_expl e,
    dwfzone d
     LEFT JOIN edit_typevalue et ON et.id::text = d.dwfzone_type::text AND et.typevalue::text = 'dwfzone_type'::text
  WHERE e.expl_id = ANY(d.expl_id) AND e.cur_user = "current_user"()::text;


CREATE OR REPLACE VIEW v_ui_dwfzone
AS SELECT DISTINCT ON (d.dwfzone_id) d.dwfzone_id,
    d.code,
    d.name,
    et.idval AS dwfzone_type,
    d.descript,
    d.graphconfig,
    d.stylesheet,
    d.link,
    d.muni_id,
    d.expl_id,
    d.sector_id,
    d.lock_level,
    d.drainzone_id,
    d.active,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by
   FROM dwfzone d
     LEFT JOIN edit_typevalue et ON et.id::text = d.dwfzone_type::text AND et.typevalue::text = 'dwfzone_type'::text
  WHERE d.dwfzone_id > 0
  ORDER BY d.dwfzone_id;

CREATE OR REPLACE VIEW v_edit_arc
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
        ), arc_psector AS (
         SELECT pp.arc_id,
            pp.state AS p_state
           FROM plan_psector_x_arc pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
        ), arc_selector AS (
         SELECT arc.arc_id
           FROM arc
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND arc.state = s.state_id
             LEFT JOIN ( SELECT arc_psector.arc_id
                   FROM arc_psector
                  WHERE arc_psector.p_state = 0) a USING (arc_id)
          WHERE a.arc_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(arc.expl_visibility::integer[], arc.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = arc.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = arc.muni_id))
        UNION ALL
         SELECT arc_psector.arc_id
           FROM arc_psector
          WHERE arc_psector.p_state = 1
        ), arc_selected AS (
         SELECT arc.arc_id,
            arc.code,
            arc.sys_code,
            arc.node_1,
            arc.nodetype_1,
            arc.elev1,
            arc.custom_elev1,
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END AS sys_elev1,
            arc.y1,
            arc.custom_y1,
                CASE
                    WHEN
                    CASE
                        WHEN arc.custom_y1 IS NULL THEN arc.y1
                        ELSE arc.custom_y1
                    END IS NULL THEN arc.node_sys_top_elev_1 - arc.sys_elev1
                    ELSE
                    CASE
                        WHEN arc.custom_y1 IS NULL THEN arc.y1
                        ELSE arc.custom_y1
                    END
                END AS sys_y1,
            arc.node_sys_top_elev_1 -
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END - cat_arc.geom1 AS r1,
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END - arc.node_sys_elev_1 AS z1,
            arc.node_2,
            arc.nodetype_2,
            arc.elev2,
            arc.custom_elev2,
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END AS sys_elev2,
            arc.y2,
            arc.custom_y2,
                CASE
                    WHEN
                    CASE
                        WHEN arc.custom_y2 IS NULL THEN arc.y2
                        ELSE arc.custom_y2
                    END IS NULL THEN arc.node_sys_top_elev_2 - arc.sys_elev2
                    ELSE
                    CASE
                        WHEN arc.custom_y2 IS NULL THEN arc.y2
                        ELSE arc.custom_y2
                    END
                END AS sys_y2,
            arc.node_sys_top_elev_2 -
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END - cat_arc.geom1 AS r2,
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END - arc.node_sys_elev_2 AS z2,
            cat_feature.feature_class AS sys_type,
            arc.arc_type::text AS arc_type,
            arc.arccat_id,
                CASE
                    WHEN arc.matcat_id IS NULL THEN cat_arc.matcat_id
                    ELSE arc.matcat_id
                END AS matcat_id,
            cat_arc.shape AS cat_shape,
            cat_arc.geom1 AS cat_geom1,
            cat_arc.geom2 AS cat_geom2,
            cat_arc.width AS cat_width,
            cat_arc.area AS cat_area,
            arc.epa_type,
            arc.state,
            arc.state_type,
            arc.parent_id,
            arc.expl_id,
            e.macroexpl_id,
            arc.muni_id,
            arc.sector_id,
            sector_table.macrosector_id,
            sector_table.sector_type,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            arc.drainzone_outfall,
            arc.dwfzone_id,
            dwfzone_table.dwfzone_type,
            arc.dwfzone_outfall,
            arc.omzone_id,
            omzone_table.macroomzone_id,
            omzone_table.omzone_type,
            arc.dma_id,
            arc.omunit_id,
            arc.minsector_id,
            arc.pavcat_id,
            arc.soilcat_id,
            arc.function_type,
            arc.category_type,
            arc.location_type,
            arc.fluid_type,
            arc.custom_length,
            st_length(arc.the_geom)::numeric(12,2) AS gis_length,
            arc.sys_slope AS slope,
            arc.descript,
            arc.annotation,
            arc.observ,
            arc.comment,
            concat(cat_feature.link_path, arc.link) AS link,
            arc.num_value,
            arc.district_id,
            arc.postcode,
            arc.streetaxis_id,
            arc.postnumber,
            arc.postcomplement,
            arc.streetaxis2_id,
            arc.postnumber2,
            arc.postcomplement2,
            mu.region_id,
            mu.province_id,
            arc.workcat_id,
            arc.workcat_id_end,
            arc.workcat_id_plan,
            arc.builtdate,
            arc.registration_date,
            arc.enddate,
            arc.ownercat_id,
            arc.last_visitdate,
            arc.visitability,
            arc.om_state,
            arc.conserv_state,
            arc.brand_id,
            arc.model_id,
            arc.serial_number,
            arc.asset_id,
            arc.adate,
            arc.adescript,
            arc.verified,
            arc.uncertain,
            arc.datasource,
            cat_arc.label,
            arc.label_x,
            arc.label_y,
            arc.label_rotation,
            arc.label_quadrant,
            arc.inventory,
            arc.publish,
            vst.is_operative,
            arc.is_scadamap,
                CASE
                    WHEN arc.sector_id > 0 AND vst.is_operative = true AND arc.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN arc.epa_type
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
            arc.lock_level,
            arc.initoverflowpath,
            arc.inverted_slope,
            arc.negative_offset,
            arc.expl_visibility,
            date_trunc('second'::text, arc.created_at) AS created_at,
            arc.created_by,
            date_trunc('second'::text, arc.updated_at) AS updated_at,
            arc.updated_by,
            arc.the_geom,
            arc.meandering
           FROM arc_selector
             JOIN arc USING (arc_id)
             JOIN cat_arc ON arc.arccat_id::text = cat_arc.id::text
             JOIN cat_feature ON arc.arc_type::text = cat_feature.id::text
             JOIN exploitation e ON e.expl_id = arc.expl_id
             JOIN ext_municipality mu ON arc.muni_id = mu.muni_id
             JOIN value_state_type vst ON vst.id = arc.state_type
             JOIN sector_table ON sector_table.sector_id = arc.sector_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = arc.omzone_id
             LEFT JOIN drainzone_table ON arc.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON arc.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN arc_add ON arc_add.arc_id = arc.arc_id
        )
 SELECT arc_id,
    code,
    sys_code,
    node_1,
    nodetype_1,
    elev1,
    custom_elev1,
    sys_elev1,
    y1,
    custom_y1,
    sys_y1,
    r1,
    z1,
    node_2,
    nodetype_2,
    elev2,
    custom_elev2,
    sys_elev2,
    y2,
    custom_y2,
    sys_y2,
    r2,
    z2,
    sys_type,
    arc_type,
    arccat_id,
    matcat_id,
    cat_shape,
    cat_geom1,
    cat_geom2,
    cat_width,
    cat_area,
    epa_type,
    state,
    state_type,
    parent_id,
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
    omzone_type,
    omunit_id,
    minsector_id,
    pavcat_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
    custom_length,
    gis_length,
    slope,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    registration_date,
    enddate,
    ownercat_id,
    last_visitdate,
    visitability,
    om_state,
    conserv_state,
    brand_id,
    model_id,
    serial_number,
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
    label_quadrant,
    inventory,
    publish,
    is_operative,
    is_scadamap,
    inp_type,
    result_id,
    max_flow,
    max_veloc,
    mfull_flow,
    mfull_depth,
    manning_veloc,
    manning_flow,
    dwf_minflow,
    dwf_maxflow,
    dwf_minvel,
    dwf_maxvel,
    conduit_capacity,
    sector_style,
    drainzone_style,
    dwfzone_style,
    omzone_style,
    lock_level,
    initoverflowpath,
    inverted_slope,
    negative_offset,
    expl_visibility,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom,
    meandering
   FROM arc_selected;

CREATE OR REPLACE VIEW v_edit_node
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
        ), node_psector AS (
         SELECT pp.node_id,
            pp.state AS p_state
           FROM plan_psector_x_node pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
        ), node_selector AS (
         SELECT node.node_id
           FROM node
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND node.state = s.state_id
             LEFT JOIN ( SELECT node_psector.node_id
                   FROM node_psector
                  WHERE node_psector.p_state = 0) a USING (node_id)
          WHERE a.node_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(node.expl_visibility::integer[], node.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = node.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = node.muni_id))
        UNION ALL
         SELECT node_psector.node_id
           FROM node_psector
          WHERE node_psector.p_state = 1
        ), node_selected AS (
         SELECT node.node_id,
            node.code,
            node.sys_code,
            node.top_elev,
            node.custom_top_elev,
                CASE
                    WHEN node.custom_top_elev IS NOT NULL THEN node.custom_top_elev
                    ELSE node.top_elev
                END AS sys_top_elev,
            node.ymax,
            node.custom_ymax,
                CASE
                    WHEN node.custom_ymax IS NOT NULL THEN node.custom_ymax
                    ELSE node.ymax
                END AS sys_ymax,
            node.elev,
            node.custom_elev,
                CASE
                    WHEN node.elev IS NOT NULL AND node.custom_elev IS NULL THEN node.elev
                    WHEN node.custom_elev IS NOT NULL THEN node.custom_elev
                    ELSE NULL::numeric(12,3)
                END AS sys_elev,
            cat_feature.feature_class AS sys_type,
            node.node_type::text AS node_type,
                CASE
                    WHEN node.matcat_id IS NULL THEN cat_node.matcat_id
                    ELSE node.matcat_id
                END AS matcat_id,
            node.nodecat_id,
            node.epa_type,
            node.state,
            node.state_type,
            node.arc_id,
            node.parent_id,
            node.expl_id,
            exploitation.macroexpl_id,
            node.muni_id,
            node.sector_id,
            sector_table.macrosector_id,
            sector_table.sector_type,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            node.drainzone_outfall,
            node.dwfzone_id,
            dwfzone_table.dwfzone_type,
            node.dwfzone_outfall,
            node.omzone_id,
            omzone_table.macroomzone_id,
            node.dma_id,
            node.omunit_id,
            node.minsector_id,
            node.pavcat_id,
            node.soilcat_id,
            node.function_type,
            node.category_type,
            node.location_type,
            node.fluid_type,
            node.annotation,
            node.observ,
            node.comment,
            node.descript,
            concat(cat_feature.link_path, node.link) AS link,
            node.num_value,
            node.district_id,
            node.postcode,
            node.streetaxis_id,
            node.postnumber,
            node.postcomplement,
            node.streetaxis2_id,
            node.postnumber2,
            node.postcomplement2,
            mu.region_id,
            mu.province_id,
            node.workcat_id,
            node.workcat_id_end,
            node.workcat_id_plan,
            node.builtdate,
            node.enddate,
            node.ownercat_id,
            node.conserv_state,
            node.om_state,
            node.access_type,
            node.placement_type,
            node.brand_id,
            node.model_id,
            node.serial_number,
            node.asset_id,
            node.adate,
            node.adescript,
            node.verified,
            node.xyz_date,
            node.uncertain,
            node.datasource,
            node.unconnected,
            cat_node.label,
            node.label_x,
            node.label_y,
            node.label_rotation,
            node.rotation,
            node.label_quadrant,
            node.hemisphere,
            cat_node.svg,
            node.inventory,
            node.publish,
            vst.is_operative,
            node.is_scadamap,
                CASE
                    WHEN node.sector_id > 0 AND vst.is_operative = true AND node.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN node.epa_type
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
            node.lock_level,
            node.expl_visibility,
            ( SELECT st_x(node.the_geom) AS st_x) AS xcoord,
            ( SELECT st_y(node.the_geom) AS st_y) AS ycoord,
            ( SELECT st_y(st_transform(node.the_geom, 4326)) AS st_y) AS lat,
            ( SELECT st_x(st_transform(node.the_geom, 4326)) AS st_x) AS long,
            date_trunc('second'::text, node.created_at) AS created_at,
            node.created_by,
            date_trunc('second'::text, node.updated_at) AS updated_at,
            node.updated_by,
            node.the_geom
           FROM node_selector
             JOIN node USING (node_id)
             JOIN cat_node ON node.nodecat_id::text = cat_node.id::text
             JOIN cat_feature ON cat_feature.id::text = node.node_type::text
             JOIN exploitation ON node.expl_id = exploitation.expl_id
             JOIN ext_municipality mu ON node.muni_id = mu.muni_id
             JOIN value_state_type vst ON vst.id = node.state_type
             JOIN sector_table ON sector_table.sector_id = node.sector_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = node.omzone_id
             LEFT JOIN drainzone_table ON node.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON node.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN node_add ON node_add.node_id = node.node_id
        ), node_base AS (
         SELECT node_selected.node_id,
            node_selected.code,
            node_selected.sys_code,
            node_selected.top_elev,
            node_selected.custom_top_elev,
            node_selected.sys_top_elev,
            node_selected.ymax,
            node_selected.custom_ymax,
                CASE
                    WHEN node_selected.sys_ymax IS NOT NULL THEN node_selected.sys_ymax
                    ELSE (node_selected.sys_top_elev - node_selected.sys_elev)::numeric(12,3)
                END AS sys_ymax,
            node_selected.elev,
            node_selected.custom_elev,
                CASE
                    WHEN node_selected.elev IS NOT NULL AND node_selected.custom_elev IS NULL THEN node_selected.elev
                    WHEN node_selected.custom_elev IS NOT NULL THEN node_selected.custom_elev
                    ELSE (node_selected.sys_top_elev - node_selected.sys_ymax)::numeric(12,3)
                END AS sys_elev,
            node_selected.node_type,
            node_selected.sys_type,
            node_selected.matcat_id,
            node_selected.nodecat_id,
            node_selected.epa_type,
            node_selected.state,
            node_selected.state_type,
            node_selected.arc_id,
            node_selected.parent_id,
            node_selected.expl_id,
            node_selected.macroexpl_id,
            node_selected.muni_id,
            node_selected.sector_id,
            node_selected.macrosector_id,
            node_selected.sector_type,
            node_selected.drainzone_id,
            node_selected.drainzone_type,
            node_selected.drainzone_outfall,
            node_selected.dwfzone_id,
            node_selected.dwfzone_type,
            node_selected.dwfzone_outfall,
            node_selected.omzone_id,
            node_selected.macroomzone_id,
            node_selected.dma_id,
            node_selected.omunit_id,
            node_selected.minsector_id,
            node_selected.pavcat_id,
            node_selected.soilcat_id,
            node_selected.function_type,
            node_selected.category_type,
            node_selected.location_type,
            node_selected.fluid_type,
            node_selected.annotation,
            node_selected.observ,
            node_selected.comment,
            node_selected.descript,
            node_selected.link,
            node_selected.num_value,
            node_selected.district_id,
            node_selected.postcode,
            node_selected.streetaxis_id,
            node_selected.postnumber,
            node_selected.postcomplement,
            node_selected.streetaxis2_id,
            node_selected.postnumber2,
            node_selected.postcomplement2,
            node_selected.region_id,
            node_selected.province_id,
            node_selected.workcat_id,
            node_selected.workcat_id_end,
            node_selected.workcat_id_plan,
            node_selected.builtdate,
            node_selected.enddate,
            node_selected.ownercat_id,
            node_selected.conserv_state,
            node_selected.om_state,
            node_selected.access_type,
            node_selected.placement_type,
            node_selected.brand_id,
            node_selected.model_id,
            node_selected.serial_number,
            node_selected.asset_id,
            node_selected.adate,
            node_selected.adescript,
            node_selected.verified,
            node_selected.xyz_date,
            node_selected.uncertain,
            node_selected.datasource,
            node_selected.unconnected,
            node_selected.label,
            node_selected.label_x,
            node_selected.label_y,
            node_selected.label_rotation,
            node_selected.rotation,
            node_selected.label_quadrant,
            node_selected.hemisphere,
            node_selected.svg,
            node_selected.inventory,
            node_selected.publish,
            node_selected.is_operative,
            node_selected.is_scadamap,
            node_selected.inp_type,
            node_selected.result_id,
            node_selected.max_depth,
            node_selected.max_height,
            node_selected.flooding_rate,
            node_selected.flooding_vol,
            node_selected.sector_style,
            node_selected.omzone_style,
            node_selected.drainzone_style,
            node_selected.dwfzone_style,
            node_selected.lock_level,
            node_selected.expl_visibility,
            node_selected.xcoord,
            node_selected.ycoord,
            node_selected.lat,
            node_selected.long,
            node_selected.created_at,
            node_selected.created_by,
            node_selected.updated_at,
            node_selected.updated_by,
            node_selected.the_geom
           FROM node_selected
        )
 SELECT node_id,
    code,
    sys_code,
    top_elev,
    custom_top_elev,
    sys_top_elev,
    ymax,
    custom_ymax,
    sys_ymax,
    elev,
    custom_elev,
    sys_elev,
    node_type,
    sys_type,
    matcat_id,
    nodecat_id,
    epa_type,
    state,
    state_type,
    arc_id,
    parent_id,
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
    omunit_id,
    minsector_id,
    pavcat_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
    annotation,
    observ,
    comment,
    descript,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    enddate,
    ownercat_id,
    conserv_state,
    om_state,
    access_type,
    placement_type,
    brand_id,
    model_id,
    serial_number,
    asset_id,
    adate,
    adescript,
    verified,
    xyz_date,
    uncertain,
    datasource,
    unconnected,
    label,
    label_x,
    label_y,
    label_rotation,
    rotation,
    label_quadrant,
    hemisphere,
    svg,
    inventory,
    publish,
    is_operative,
    is_scadamap,
    inp_type,
    result_id,
    max_depth,
    max_height,
    flooding_rate,
    flooding_vol,
    sector_style,
    omzone_style,
    drainzone_style,
    dwfzone_style,
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
    the_geom
   FROM node_base;

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
            connec.plot_code,
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
    plot_code,
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

CREATE OR REPLACE VIEW v_edit_link
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
        ), link_psector AS (
        ( SELECT DISTINCT ON (pp.connec_id, pp.state) 'CONNEC'::text AS feature_type,
            pp.connec_id AS feature_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.link_id
           FROM plan_psector_x_connec pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST)
        UNION ALL
        ( SELECT DISTINCT ON (pp.gully_id, pp.state) 'GULLY'::text AS feature_type,
            pp.gully_id AS feature_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.link_id
           FROM plan_psector_x_gully pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.gully_id, pp.state, pp.link_id DESC NULLS LAST)
        ), link_selector AS (
         SELECT l.link_id
           FROM link l
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND l.state = s.state_id
             LEFT JOIN ( SELECT link_psector.link_id
                   FROM link_psector
                  WHERE link_psector.p_state = 0) a ON a.link_id = l.link_id
          WHERE a.link_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(l.expl_visibility::integer[], l.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = l.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = l.muni_id))
        UNION ALL
         SELECT link_psector.link_id
           FROM link_psector
          WHERE link_psector.p_state = 1
        ), link_selected AS (
         SELECT DISTINCT ON (l.link_id) l.link_id,
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
            l.the_geom
           FROM link_selector
             JOIN link l USING (link_id)
             JOIN exploitation ON l.expl_id = exploitation.expl_id
             JOIN ext_municipality mu ON l.muni_id = mu.muni_id
             JOIN sector_table ON l.sector_id = sector_table.sector_id
             JOIN cat_link ON cat_link.id::text = l.linkcat_id::text
             JOIN cat_feature ON cat_feature.id::text = l.link_type::text
             LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
             LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN inp_network_mode ON true
        )
 SELECT link_id,
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
   FROM link_selected;

CREATE OR REPLACE VIEW v_edit_link_gully
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
   FROM v_edit_link
  WHERE feature_type::text = 'GULLY'::text;


CREATE OR REPLACE VIEW v_edit_link_connec
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
   FROM v_edit_link
  WHERE feature_type::text = 'CONNEC'::text;

CREATE OR REPLACE VIEW v_edit_gully
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
            l.expl_id,
            exploitation.macroexpl_id,
            l.sector_id,
            sector_table.sector_type,
            sector_table.macrosector_id,
            l.omzone_id,
            omzone_table.omzone_type,
            omzone_table.macroomzone_id,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            l.dwfzone_id,
            dwfzone_table.dwfzone_type,
            l.fluid_type,
            l.dma_id
           FROM link l
             JOIN exploitation USING (expl_id)
             JOIN sector_table ON l.sector_id = sector_table.sector_id
             LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
             LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
          WHERE l.state = 2
        ), gully_psector AS (
         SELECT DISTINCT ON (pp.gully_id, pp.state) pp.gully_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.arc_id,
            pp.link_id
           FROM plan_psector_x_gully pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.gully_id, pp.state, pp.link_id DESC NULLS LAST
        ), gully_selector AS (
         SELECT gully.gully_id,
            gully.arc_id,
            NULL::integer AS link_id
           FROM gully
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND gully.state = s.state_id
             LEFT JOIN ( SELECT gully_psector.gully_id
                   FROM gully_psector
                  WHERE gully_psector.p_state = 0) a USING (gully_id)
          WHERE a.gully_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(gully.expl_visibility::integer[], gully.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = gully.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = gully.muni_id))
        UNION ALL
         SELECT gully_psector.gully_id,
            gully_psector.arc_id,
            gully_psector.link_id
           FROM gully_psector
          WHERE gully_psector.p_state = 1
        ), gully_selected AS (
         SELECT gully.gully_id,
            gully.code,
            gully.sys_code,
            gully.top_elev,
                CASE
                    WHEN gully.width IS NULL THEN cat_gully.width
                    ELSE gully.width
                END AS width,
                CASE
                    WHEN gully.length IS NULL THEN cat_gully.length
                    ELSE gully.length
                END AS length,
                CASE
                    WHEN gully.ymax IS NULL THEN cat_gully.ymax
                    ELSE gully.ymax
                END AS ymax,
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
                CASE
                    WHEN ((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric) IS NOT NULL THEN ((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric)::numeric(12,3)
                    ELSE gully.connec_depth
                END AS connec_depth,
                CASE
                    WHEN gully._connec_matcat_id IS NULL THEN cc.matcat_id::text
                    ELSE gully._connec_matcat_id
                END AS connec_matcat_id,
            gully.top_elev - gully.ymax + gully.sandbox AS connec_y1,
            gully.connec_y2,
            gully.arc_id,
            gully.epa_type,
            gully.state,
            gully.state_type,
            gully.expl_id,
            exploitation.macroexpl_id,
            gully.muni_id,
                CASE
                    WHEN link_planned.sector_id IS NULL THEN sector_table.sector_id
                    ELSE link_planned.sector_id
                END AS sector_id,
                CASE
                    WHEN link_planned.macrosector_id IS NULL THEN sector_table.macrosector_id
                    ELSE link_planned.macrosector_id
                END AS macrosector_id,
                CASE
                    WHEN link_planned.sector_id IS NULL THEN sector_table.sector_type
                    ELSE link_planned.sector_type
                END AS sector_type,
                CASE
                    WHEN link_planned.drainzone_id IS NULL THEN dwfzone_table.drainzone_id
                    ELSE link_planned.drainzone_id
                END AS drainzone_id,
                CASE
                    WHEN link_planned.drainzone_type IS NULL THEN drainzone_table.drainzone_type
                    ELSE link_planned.drainzone_type
                END AS drainzone_type,
            gully.drainzone_outfall,
                CASE
                    WHEN link_planned.dwfzone_id IS NULL THEN dwfzone_table.dwfzone_id
                    ELSE link_planned.dwfzone_id
                END AS dwfzone_id,
                CASE
                    WHEN link_planned.dwfzone_type IS NULL THEN dwfzone_table.dwfzone_type
                    ELSE link_planned.dwfzone_type
                END AS dwfzone_type,
            gully.dwfzone_outfall,
                CASE
                    WHEN link_planned.omzone_id IS NULL THEN omzone_table.omzone_id
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
                    WHEN link_planned.dma_id IS NULL THEN gully.dma_id
                    ELSE link_planned.dma_id
                END AS dma_id,
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
                CASE
                    WHEN link_planned.exit_id IS NULL THEN gully.pjoint_id
                    ELSE link_planned.exit_id
                END AS pjoint_id,
                CASE
                    WHEN link_planned.exit_type IS NULL THEN gully.pjoint_type
                    ELSE link_planned.exit_type
                END AS pjoint_type,
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
            gully.the_geom
           FROM gully_selector
             JOIN gully USING (gully_id)
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
             LEFT JOIN inp_network_mode ON true
        )
 SELECT gully_id,
    code,
    sys_code,
    top_elev,
    width,
    length,
    ymax,
    sandbox,
    matcat_id,
    gully_type,
    sys_type,
    gullycat_id,
    cat_gully_matcat,
    units,
    units_placement,
    groove,
    groove_height,
    groove_length,
    siphon,
    siphon_type,
    odorflap,
    connec_arccat_id,
    connec_length,
    connec_depth,
    connec_matcat_id,
    connec_y1,
    connec_y2,
    arc_id,
    epa_type,
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
    omzone_type,
    omunit_id,
    minsector_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    enddate,
    ownercat_id,
    om_state,
    pjoint_id,
    pjoint_type,
    placement_type,
    access_type,
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
    inp_type,
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
   FROM gully_selected;


CREATE OR REPLACE VIEW v_edit_inp_gully AS  SELECT g.gully_id,
    g.code,
    g.top_elev,
    g.gully_type,
    g.gullycat_id,
    (g.width / 100::numeric)::numeric(12,2) AS grate_width,
    (g.length / 100::numeric)::numeric(12,2) AS grate_length,
    g.arc_id,
    g.sector_id,
    g.expl_id,
    g.state,
    g.state_type,
    g.the_geom,
    g.units,
    g.units_placement,
    g.groove,
    g.groove_height,
    g.groove_length,
    g.pjoint_id,
    g.pjoint_type,
        CASE
            WHEN g.units_placement::text = 'LENGTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.width / 100::numeric)::numeric(12,3)
            WHEN g.units_placement::text = 'WIDTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.length / 100::numeric)::numeric(12,3)
            ELSE (cat_gully.width / 100::numeric)::numeric(12,3)
        END AS total_width,
        CASE
            WHEN g.units_placement::text = 'LENGTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.width / 100::numeric)::numeric(12,3)
            WHEN g.units_placement::text = 'WIDTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.length / 100::numeric)::numeric(12,3)
            ELSE (cat_gully.length / 100::numeric)::numeric(12,3)
        END AS total_length,
    g.ymax - COALESCE(g.sandbox, 0::numeric) AS depth,
    g.annotation,
    i.outlet_type,
    i.custom_top_elev,
    i.custom_width,
    i.custom_length,
    i.custom_depth,
    i.gully_method,
    i.weir_cd,
    i.orifice_cd,
    i.custom_a_param,
    i.custom_b_param,
    i.efficiency
   FROM v_edit_gully g
     JOIN inp_gully i USING (gully_id)
     JOIN cat_gully ON g.gullycat_id::text = cat_gully.id::text
  WHERE g.is_operative IS TRUE;

CREATE OR REPLACE VIEW v_plan_aux_arc_pavement AS  SELECT plan_arc_x_pavement.arc_id,
    sum(v_price_x_catpavement.thickness * plan_arc_x_pavement.percent)::numeric(12,2) AS thickness,
    sum(v_price_x_catpavement.m2pav_cost * plan_arc_x_pavement.percent)::numeric(12,2) AS m2pav_cost,
    'Various pavements'::character varying AS pavcat_id,
    1 AS percent,
    'VARIOUS'::character varying AS price_id
   FROM plan_arc_x_pavement
     JOIN v_price_x_catpavement USING (pavcat_id)
  GROUP BY plan_arc_x_pavement.arc_id
UNION
 SELECT v_edit_arc.arc_id,
    c.thickness,
    v_price_x_catpavement.m2pav_cost,
    v_edit_arc.pavcat_id,
    1 AS percent,
    p.id AS price_id
   FROM v_edit_arc
     JOIN cat_pavement c ON c.id::text = v_edit_arc.pavcat_id::text
     JOIN v_price_x_catpavement USING (pavcat_id)
     LEFT JOIN v_price_compost p ON c.m2_cost::text = p.id::text
     LEFT JOIN ( SELECT plan_arc_x_pavement.arc_id
           FROM plan_arc_x_pavement) a USING (arc_id)
  WHERE a.arc_id IS NULL;

CREATE OR REPLACE VIEW v_plan_arc AS  SELECT arc_id,
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
                         SELECT v_edit_arc.arc_id,
                            v_edit_arc.y1,
                            v_edit_arc.y2,
                                CASE
                                    WHEN (v_edit_arc.y1 * v_edit_arc.y2) = 0::numeric OR (v_edit_arc.y1 * v_edit_arc.y2) IS NULL THEN v_price_x_catarc.estimated_depth
                                    ELSE ((v_edit_arc.y1 + v_edit_arc.y2) / 2::numeric)::numeric(12,2)
                                END AS mean_y,
                            v_edit_arc.arccat_id,
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
                            v_edit_arc.state,
                            v_edit_arc.expl_id,
                            v_edit_arc.the_geom
                           FROM v_edit_arc
                             LEFT JOIN v_price_x_catarc ON v_edit_arc.arccat_id::text = v_price_x_catarc.id::text
                             LEFT JOIN v_price_x_catsoil ON v_edit_arc.soilcat_id::text = v_price_x_catsoil.id::text
                             LEFT JOIN v_plan_aux_arc_pavement ON v_plan_aux_arc_pavement.arc_id = v_edit_arc.arc_id
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
             LEFT JOIN ( SELECT DISTINCT ON (c.arc_id) c.arc_id,
                    (min(p.price) * count(*)::numeric)::numeric(12,2) AS connec_total_cost
                   FROM v_edit_connec c
                     JOIN arc arc_1 USING (arc_id)
                     JOIN cat_arc ON cat_arc.id::text = arc_1.arccat_id::text
                     LEFT JOIN v_price_compost p ON cat_arc.connect_cost = p.id::text
                  WHERE c.arc_id IS NOT NULL
                  GROUP BY c.arc_id) v_plan_aux_arc_connec ON v_plan_aux_arc_connec.arc_id = v_plan_aux_arc_cost.arc_id
             LEFT JOIN ( SELECT DISTINCT ON (c.arc_id) c.arc_id,
                    (min(p.price) * count(*)::numeric)::numeric(12,2) AS gully_total_cost
                   FROM v_edit_gully c
                     JOIN arc arc_1 USING (arc_id)
                     JOIN cat_arc ON cat_arc.id::text = arc_1.arccat_id::text
                     LEFT JOIN v_price_compost p ON cat_arc.connect_cost = p.id::text
                  WHERE c.arc_id IS NOT NULL
                  GROUP BY c.arc_id) v_plan_aux_arc_gully ON v_plan_aux_arc_gully.arc_id = v_plan_aux_arc_cost.arc_id) d;

CREATE OR REPLACE VIEW v_ui_plan_arc_cost AS  WITH p AS (
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
    1 AS measurement,
    a.m2pav_cost AS total_cost,
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
    count(v_edit_connec.connec_id) AS measurement,
    (min(v.price) * count(v_edit_connec.connec_id)::numeric / COALESCE(min(p.length), 1::numeric))::numeric(12,2) AS total_cost,
    min(p.length)::numeric(12,2) AS length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_edit_connec USING (arc_id)
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
    count(v_edit_gully.gully_id) AS measurement,
    (min(v.price) * count(v_edit_gully.gully_id)::numeric / COALESCE(min(p.length), 1::numeric))::numeric(12,2) AS total_cost,
    min(p.length)::numeric(12,2) AS length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_edit_gully USING (arc_id)
     JOIN v_price_compost v ON p.cat_connect_cost = v.id::text
  GROUP BY p.arc_id
  ORDER BY 1, 2;
CREATE OR REPLACE VIEW v_ui_node_x_connection_upstream AS  SELECT row_number() OVER (ORDER BY v_edit_arc.node_2) + 1000000 AS rid,
    v_edit_arc.node_2 AS node_id,
    v_edit_arc.arc_id AS feature_id,
    v_edit_arc.code AS feature_code,
    v_edit_arc.arc_type AS featurecat_id,
    v_edit_arc.arccat_id,
    v_edit_arc.y1 AS depth,
    st_length2d(v_edit_arc.the_geom)::numeric(12,2) AS length,
    node.node_id AS upstream_id,
    node.code AS upstream_code,
    node.node_type AS upstream_type,
    v_edit_arc.y2 AS upstream_depth,
    v_edit_arc.sys_type,
    st_x(st_lineinterpolatepoint(v_edit_arc.the_geom, 0.5::double precision)) AS x,
    st_y(st_lineinterpolatepoint(v_edit_arc.the_geom, 0.5::double precision)) AS y,
    cat_arc.descript,
    value_state.name AS state,
    'v_edit_arc'::text AS sys_table_id
   FROM v_edit_arc
     JOIN node ON v_edit_arc.node_1 = node.node_id
     LEFT JOIN cat_arc ON v_edit_arc.arccat_id::text = cat_arc.id::text
     JOIN value_state ON v_edit_arc.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_connec.connec_id) row_number() OVER (ORDER BY node.node_id) + 2000000 AS rid,
    node.node_id,
    v_edit_connec.connec_id AS feature_id,
    v_edit_connec.code AS feature_code,
    v_edit_connec.connec_type AS featurecat_id,
    v_edit_connec.conneccat_id AS arccat_id,
    v_edit_connec.y1 AS depth,
    st_length2d(link.the_geom)::numeric(12,2) AS length,
    v_edit_connec.connec_id AS upstream_id,
    v_edit_connec.code AS upstream_code,
    v_edit_connec.connec_type AS upstream_type,
    v_edit_connec.y2 AS upstream_depth,
    v_edit_connec.sys_type,
    st_x(v_edit_connec.the_geom) AS x,
    st_y(v_edit_connec.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_connec'::text AS sys_table_id
   FROM v_edit_connec
     JOIN link ON link.feature_id = v_edit_connec.connec_id AND link.feature_type::text = 'CONNEC'::text
     JOIN node ON v_edit_connec.pjoint_id = node.node_id AND v_edit_connec.pjoint_type::text = 'NODE'::text
     LEFT JOIN cat_connec ON v_edit_connec.conneccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_connec.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_connec.connec_id) row_number() OVER (ORDER BY node.node_id) + 3000000 AS rid,
    node.node_id,
    v_edit_connec.connec_id AS feature_id,
    v_edit_connec.code AS feature_code,
    v_edit_connec.connec_type AS featurecat_id,
    v_edit_connec.conneccat_id AS arccat_id,
    v_edit_connec.y1 AS depth,
    st_length2d(link.the_geom)::numeric(12,2) AS length,
    v_edit_connec.connec_id AS upstream_id,
    v_edit_connec.code AS upstream_code,
    v_edit_connec.connec_type AS upstream_type,
    v_edit_connec.y2 AS upstream_depth,
    v_edit_connec.sys_type,
    st_x(v_edit_connec.the_geom) AS x,
    st_y(v_edit_connec.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_connec'::text AS sys_table_id
   FROM v_edit_connec
     JOIN link ON link.feature_id = v_edit_connec.connec_id AND link.feature_type::text = 'CONNEC'::text AND link.exit_type::text = 'CONNEC'::text
     JOIN connec ON connec.connec_id = link.exit_id AND connec.pjoint_type::text = 'NODE'::text
     JOIN node ON connec.pjoint_id = node.node_id
     LEFT JOIN cat_connec ON v_edit_connec.conneccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_connec.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_gully.gully_id) row_number() OVER (ORDER BY node.node_id) + 4000000 AS rid,
    node.node_id,
    v_edit_gully.gully_id AS feature_id,
    v_edit_gully.code AS feature_code,
    v_edit_gully.gully_type AS featurecat_id,
    v_edit_gully.connec_arccat_id AS arccat_id,
    v_edit_gully.ymax - v_edit_gully.sandbox AS depth,
    v_edit_gully.connec_length AS length,
    v_edit_gully.gully_id AS upstream_id,
    v_edit_gully.code AS upstream_code,
    v_edit_gully.gully_type AS upstream_type,
    v_edit_gully.connec_depth AS upstream_depth,
    v_edit_gully.sys_type,
    st_x(v_edit_gully.the_geom) AS x,
    st_y(v_edit_gully.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_gully'::text AS sys_table_id
   FROM v_edit_gully
     JOIN link ON link.feature_id = v_edit_gully.gully_id AND link.feature_type::text = 'GULLY'::text
     JOIN node ON v_edit_gully.pjoint_id = node.node_id AND v_edit_gully.pjoint_type::text = 'NODE'::text
     LEFT JOIN cat_connec ON v_edit_gully.connec_arccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_gully.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_gully.gully_id) row_number() OVER (ORDER BY node.node_id) + 5000000 AS rid,
    node.node_id,
    v_edit_gully.gully_id AS feature_id,
    v_edit_gully.code AS feature_code,
    v_edit_gully.gully_type AS featurecat_id,
    v_edit_gully.connec_arccat_id AS arccat_id,
    v_edit_gully.ymax - v_edit_gully.sandbox AS depth,
    v_edit_gully.connec_length AS length,
    v_edit_gully.gully_id AS upstream_id,
    v_edit_gully.code AS upstream_code,
    v_edit_gully.gully_type AS upstream_type,
    v_edit_gully.connec_depth AS upstream_depth,
    v_edit_gully.sys_type,
    st_x(v_edit_gully.the_geom) AS x,
    st_y(v_edit_gully.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_gully'::text AS sys_table_id
   FROM v_edit_gully
     JOIN link ON link.feature_id = v_edit_gully.gully_id AND link.feature_type::text = 'GULLY'::text AND link.exit_type::text = 'GULLY'::text
     JOIN gully ON gully.gully_id = link.exit_id AND gully.pjoint_type::text = 'NODE'::text
     JOIN node ON gully.pjoint_id = node.node_id
     LEFT JOIN cat_connec ON v_edit_gully.connec_arccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_gully.state = value_state.id;
CREATE OR REPLACE VIEW v_ui_workcat_x_feature_end AS  SELECT row_number() OVER (ORDER BY v_edit_arc.arc_id) + 1000000 AS rid,
    'ARC'::character varying AS feature_type,
    v_edit_arc.arccat_id AS featurecat_id,
    v_edit_arc.arc_id AS feature_id,
    v_edit_arc.code,
    exploitation.name AS expl_name,
    v_edit_arc.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_arc
     JOIN exploitation ON exploitation.expl_id = v_edit_arc.expl_id
  WHERE v_edit_arc.state = 0
UNION
 SELECT row_number() OVER (ORDER BY v_edit_node.node_id) + 2000000 AS rid,
    'NODE'::character varying AS feature_type,
    v_edit_node.nodecat_id AS featurecat_id,
    v_edit_node.node_id AS feature_id,
    v_edit_node.code,
    exploitation.name AS expl_name,
    v_edit_node.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_node
     JOIN exploitation ON exploitation.expl_id = v_edit_node.expl_id
  WHERE v_edit_node.state = 0
UNION
 SELECT row_number() OVER (ORDER BY v_edit_connec.connec_id) + 3000000 AS rid,
    'CONNEC'::character varying AS feature_type,
    v_edit_connec.conneccat_id AS featurecat_id,
    v_edit_connec.connec_id AS feature_id,
    v_edit_connec.code,
    exploitation.name AS expl_name,
    v_edit_connec.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_connec
     JOIN exploitation ON exploitation.expl_id = v_edit_connec.expl_id
  WHERE v_edit_connec.state = 0
UNION
 SELECT row_number() OVER (ORDER BY element.element_id) + 4000000 AS rid,
    'ELEMENT'::character varying AS feature_type,
    element.elementcat_id AS featurecat_id,
    element.element_id AS feature_id,
    element.code,
    exploitation.name AS expl_name,
    element.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM element
     JOIN exploitation ON exploitation.expl_id = element.expl_id
  WHERE element.state = 0
UNION
 SELECT row_number() OVER (ORDER BY v_edit_gully.gully_id) + 4000000 AS rid,
    'GULLY'::character varying AS feature_type,
    v_edit_gully.gullycat_id AS featurecat_id,
    v_edit_gully.gully_id AS feature_id,
    v_edit_gully.code,
    exploitation.name AS expl_name,
    v_edit_gully.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_gully
     JOIN exploitation ON exploitation.expl_id = v_edit_gully.expl_id
  WHERE v_edit_gully.state = 0;
CREATE OR REPLACE VIEW v_ui_arc_x_relations AS  WITH links_node AS (
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
    v_edit_connec.arc_id,
    v_edit_connec.connec_type AS featurecat_id,
    v_edit_connec.conneccat_id AS catalog,
    v_edit_connec.connec_id AS feature_id,
    v_edit_connec.code AS feature_code,
    v_edit_connec.sys_type,
    a.state AS arc_state,
    v_edit_connec.state AS feature_state,
    st_x(v_edit_connec.the_geom) AS x,
    st_y(v_edit_connec.the_geom) AS y,
    l.exit_type AS proceed_from,
    l.exit_id AS proceed_from_id,
    'v_edit_connec'::text AS sys_table_id
   FROM v_edit_connec
     JOIN link l ON v_edit_connec.connec_id = l.feature_id
     JOIN arc a ON a.arc_id = v_edit_connec.arc_id
  WHERE v_edit_connec.arc_id IS NOT NULL AND l.exit_type::text <> 'NODE'::text AND l.state = 1 AND l.state = 1 AND a.state = 1
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
    'v_edit_connec'::text AS sys_table_id
   FROM arc a
     JOIN links_node n ON a.node_1 = n.node_id
     JOIN v_edit_connec c ON c.connec_id = n.feature_id
UNION
 SELECT row_number() OVER () + 3000000 AS rid,
    v_edit_gully.arc_id,
    v_edit_gully.gully_type AS featurecat_id,
    v_edit_gully.gullycat_id AS catalog,
    v_edit_gully.gully_id AS feature_id,
    v_edit_gully.code AS feature_code,
    v_edit_gully.sys_type,
    a.state AS arc_state,
    v_edit_gully.state AS feature_state,
    st_x(v_edit_gully.the_geom) AS x,
    st_y(v_edit_gully.the_geom) AS y,
    l.exit_type AS proceed_from,
    l.exit_id AS proceed_from_id,
    'v_edit_gully'::text AS sys_table_id
   FROM v_edit_gully
     JOIN link l ON v_edit_gully.gully_id = l.feature_id
     JOIN arc a ON a.arc_id = v_edit_gully.arc_id
  WHERE v_edit_gully.arc_id IS NOT NULL AND l.exit_type::text <> 'NODE'::text AND l.state = 1 AND a.state = 1
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
    'v_edit_gully'::text AS sys_table_id
   FROM arc a
     JOIN links_node n ON a.node_1 = n.node_id
     JOIN v_edit_gully g ON g.gully_id = n.feature_id;
CREATE OR REPLACE VIEW ve_pol_storage AS  SELECT polygon.pol_id,
    polygon.feature_id AS node_id,
    polygon.the_geom
   FROM polygon
     JOIN v_edit_node ON polygon.feature_id = v_edit_node.node_id
  WHERE polygon.sys_type::text = 'STORAGE'::text;
CREATE OR REPLACE VIEW ve_pol_wwtp AS  SELECT polygon.pol_id,
    polygon.feature_id AS node_id,
    polygon.the_geom
   FROM polygon
     JOIN v_edit_node ON polygon.feature_id = v_edit_node.node_id
  WHERE polygon.sys_type::text = 'WWTP'::text;
CREATE OR REPLACE VIEW ve_pol_chamber AS  SELECT polygon.pol_id,
    polygon.feature_id AS node_id,
    polygon.the_geom
   FROM polygon
     JOIN v_edit_node ON polygon.feature_id = v_edit_node.node_id
  WHERE polygon.sys_type::text = 'CHAMBER'::text;
CREATE OR REPLACE VIEW ve_pol_netgully AS  SELECT polygon.pol_id,
    polygon.feature_id AS node_id,
    polygon.the_geom
   FROM polygon
     JOIN v_edit_node ON polygon.feature_id = v_edit_node.node_id
  WHERE polygon.sys_type::text = 'NETGULLY'::text;

CREATE OR REPLACE VIEW v_plan_node AS  SELECT node_id,
    nodecat_id,
    node_type::text AS node_type,
    top_elev,
    elev,
    epa_type,
    state,
    sector_id,
    expl_id,
    annotation,
    cost_unit,
    descript,
    cost,
    measurement,
    budget,
    the_geom
   FROM ( SELECT v_edit_node.node_id,
            v_edit_node.nodecat_id,
            v_edit_node.sys_type AS node_type,
            v_edit_node.top_elev,
            v_edit_node.elev,
            v_edit_node.epa_type,
            v_edit_node.state,
            v_edit_node.sector_id,
            v_edit_node.expl_id,
            v_edit_node.annotation,
            v_price_x_catnode.cost_unit,
            v_price_compost.descript,
            v_price_compost.price AS cost,
                CASE
                    WHEN v_price_x_catnode.cost_unit::text = 'u'::text THEN 1::numeric
                    WHEN v_price_x_catnode.cost_unit::text = 'm3'::text THEN
                    CASE
                        WHEN v_edit_node.sys_type::text = 'STORAGE'::text THEN man_storage.max_volume
                        WHEN v_edit_node.sys_type::text = 'CHAMBER'::text THEN man_chamber.max_volume
                        ELSE NULL::numeric
                    END
                    WHEN v_price_x_catnode.cost_unit::text = 'm'::text THEN
                    CASE
                        WHEN v_edit_node.ymax = 0::numeric THEN v_price_x_catnode.estimated_y
                        WHEN v_edit_node.ymax IS NULL THEN v_price_x_catnode.estimated_y
                        ELSE v_edit_node.ymax
                    END
                    ELSE NULL::numeric
                END::numeric(12,2) AS measurement,
                CASE
                    WHEN v_price_x_catnode.cost_unit::text = 'u'::text THEN v_price_x_catnode.cost
                    WHEN v_price_x_catnode.cost_unit::text = 'm3'::text THEN
                    CASE
                        WHEN v_edit_node.sys_type::text = 'STORAGE'::text THEN man_storage.max_volume * v_price_x_catnode.cost
                        WHEN v_edit_node.sys_type::text = 'CHAMBER'::text THEN man_chamber.max_volume * v_price_x_catnode.cost
                        ELSE NULL::numeric
                    END
                    WHEN v_price_x_catnode.cost_unit::text = 'm'::text THEN
                    CASE
                        WHEN v_edit_node.ymax = 0::numeric THEN v_price_x_catnode.estimated_y * v_price_x_catnode.cost
                        WHEN v_edit_node.ymax IS NULL THEN v_price_x_catnode.estimated_y * v_price_x_catnode.cost
                        ELSE v_edit_node.ymax * v_price_x_catnode.cost
                    END
                    ELSE NULL::numeric
                END::numeric(12,2) AS budget,
            v_edit_node.the_geom
           FROM v_edit_node
             LEFT JOIN v_price_x_catnode ON v_edit_node.nodecat_id::text = v_price_x_catnode.id::text
             LEFT JOIN man_chamber ON man_chamber.node_id = v_edit_node.node_id
             LEFT JOIN man_storage ON man_storage.node_id = v_edit_node.node_id
             LEFT JOIN cat_node ON cat_node.id::text = v_edit_node.nodecat_id::text
             LEFT JOIN v_price_compost ON v_price_compost.id::text = cat_node.cost::text) a;

CREATE OR REPLACE VIEW v_ui_plan_node_cost AS  SELECT node.node_id,
    1 AS orderby,
    'element'::text AS identif,
    cat_node.id AS catalog_id,
    v_price_compost.id AS price_id,
    v_price_compost.unit,
    v_price_compost.descript,
    v_price_compost.price AS cost,
    1 AS measurement,
    1::numeric * v_price_compost.price AS total_cost,
    NULL::double precision AS length
   FROM node
     JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
     JOIN v_price_compost ON cat_node.cost::text = v_price_compost.id::text
     JOIN v_plan_node ON node.node_id = v_plan_node.node_id;
CREATE OR REPLACE VIEW v_plan_result_node AS  SELECT plan_rec_result_node.node_id,
    plan_rec_result_node.nodecat_id,
    plan_rec_result_node.node_type::text AS node_type,
    plan_rec_result_node.top_elev,
    plan_rec_result_node.elev,
    plan_rec_result_node.epa_type,
    plan_rec_result_node.state,
    plan_rec_result_node.sector_id,
    plan_rec_result_node.expl_id,
    plan_rec_result_node.cost_unit,
    plan_rec_result_node.descript,
    plan_rec_result_node.measurement,
    plan_rec_result_node.cost,
    plan_rec_result_node.budget,
    plan_rec_result_node.the_geom,
    plan_rec_result_node.builtcost,
    plan_rec_result_node.builtdate,
    plan_rec_result_node.age,
    plan_rec_result_node.acoeff,
    plan_rec_result_node.aperiod,
    plan_rec_result_node.arate,
    plan_rec_result_node.amortized,
    plan_rec_result_node.pending
   FROM selector_expl,
    selector_plan_result,
    plan_rec_result_node
  WHERE plan_rec_result_node.expl_id = selector_expl.expl_id AND selector_expl.cur_user = "current_user"()::text AND plan_rec_result_node.result_id::text = selector_plan_result.result_id::text AND selector_plan_result.cur_user = "current_user"()::text AND plan_rec_result_node.state = 1
UNION
 SELECT v_plan_node.node_id,
    v_plan_node.nodecat_id,
    v_plan_node.node_type,
    v_plan_node.top_elev,
    v_plan_node.elev,
    v_plan_node.epa_type,
    v_plan_node.state,
    v_plan_node.sector_id,
    v_plan_node.expl_id,
    v_plan_node.cost_unit,
    v_plan_node.descript,
    v_plan_node.measurement,
    v_plan_node.cost,
    v_plan_node.budget,
    v_plan_node.the_geom,
    NULL::double precision AS builtcost,
    NULL::timestamp without time zone AS builtdate,
    NULL::double precision AS age,
    NULL::double precision AS acoeff,
    NULL::text AS aperiod,
    NULL::double precision AS arate,
    NULL::double precision AS amortized,
    NULL::double precision AS pending
   FROM v_plan_node
  WHERE v_plan_node.state = 2;
CREATE OR REPLACE VIEW v_plan_psector_budget_node AS  SELECT row_number() OVER (ORDER BY v_plan_node.node_id) AS rid,
    plan_psector_x_node.psector_id,
    plan_psector.psector_type,
    v_plan_node.node_id,
    v_plan_node.nodecat_id,
    v_plan_node.cost::numeric(12,2) AS cost,
    v_plan_node.measurement,
    v_plan_node.budget AS total_budget,
    v_plan_node.state,
    v_plan_node.expl_id,
    plan_psector.atlas_id,
    plan_psector_x_node.doable,
    plan_psector.priority,
    v_plan_node.the_geom
   FROM v_plan_node
     JOIN plan_psector_x_node ON plan_psector_x_node.node_id = v_plan_node.node_id
     JOIN plan_psector ON plan_psector.psector_id = plan_psector_x_node.psector_id
  WHERE plan_psector_x_node.doable = true
  ORDER BY plan_psector_x_node.psector_id;

CREATE OR REPLACE VIEW v_edit_inp_outfall AS  SELECT v_edit_node.node_id,
    v_edit_node.top_elev,
    v_edit_node.custom_top_elev,
    v_edit_node.ymax,
    v_edit_node.custom_ymax,
    v_edit_node.elev,
    v_edit_node.custom_elev,
    v_edit_node.sys_elev,
    v_edit_node.nodecat_id,
    v_edit_node.sector_id,
    v_edit_node.macrosector_id,
    v_edit_node.state,
    v_edit_node.state_type,
    v_edit_node.annotation,
    v_edit_node.expl_id,
    inp_outfall.outfall_type,
    inp_outfall.stage,
    inp_outfall.curve_id,
    inp_outfall.timser_id,
    inp_outfall.gate,
    inp_outfall.route_to,
    v_edit_node.the_geom
   FROM v_edit_node
     JOIN inp_outfall USING (node_id)
  WHERE v_edit_node.is_operative IS TRUE;

CREATE OR REPLACE VIEW v_edit_inp_dscenario_outfall AS  SELECT s.dscenario_id,
    f.node_id,
    f.elev,
    f.ymax,
    f.outfall_type,
    f.stage,
    f.curve_id,
    f.timser_id,
    f.gate,
    f.route_to,
    v_edit_inp_outfall.the_geom
   FROM selector_inp_dscenario s,
    inp_dscenario_outfall f
     JOIN v_edit_inp_outfall USING (node_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW v_edit_inp_storage AS  SELECT v_edit_node.node_id,
    v_edit_node.top_elev,
    v_edit_node.custom_top_elev,
    v_edit_node.ymax,
    v_edit_node.custom_ymax,
    v_edit_node.elev,
    v_edit_node.custom_elev,
    v_edit_node.sys_elev,
    v_edit_node.nodecat_id,
    v_edit_node.sector_id,
    v_edit_node.macrosector_id,
    v_edit_node.state,
    v_edit_node.state_type,
    v_edit_node.annotation,
    v_edit_node.expl_id,
    inp_storage.storage_type,
    inp_storage.curve_id,
    inp_storage.a1,
    inp_storage.a2,
    inp_storage.a0,
    inp_storage.fevap,
    inp_storage.sh,
    inp_storage.hc,
    inp_storage.imd,
    inp_storage.y0,
    inp_storage.ysur,
    v_edit_node.the_geom
   FROM v_edit_node
     JOIN inp_storage USING (node_id)
  WHERE v_edit_node.is_operative IS TRUE;

CREATE OR REPLACE VIEW v_edit_inp_dscenario_storage AS  SELECT s.dscenario_id,
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
    v_edit_inp_storage.the_geom
   FROM selector_inp_dscenario s,
    inp_dscenario_storage f
     JOIN v_edit_inp_storage USING (node_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW v_edit_inp_netgully AS  SELECT n.node_id,
    n.code,
    n.top_elev,
    n.custom_top_elev,
    n.ymax,
    n.custom_ymax,
    n.elev,
    n.custom_elev,
    n.sys_elev,
    n.node_type,
    n.nodecat_id,
    man_netgully.gullycat_id,
    (cat_gully.width / 100::numeric)::numeric(12,3) AS grate_width,
    (cat_gully.length / 100::numeric)::numeric(12,3) AS grate_length,
    n.sector_id,
    n.macrosector_id,
    n.expl_id,
    n.state,
    n.state_type,
    n.the_geom,
    man_netgully.units,
    man_netgully.units_placement,
    man_netgully.groove,
    man_netgully.groove_height,
    man_netgully.groove_length,
        CASE
            WHEN man_netgully.units_placement::text = 'LENGTH-SIDE'::text THEN (COALESCE(man_netgully.units::integer, 1)::numeric * cat_gully.width / 100::numeric)::numeric(12,3)
            WHEN man_netgully.units_placement::text = 'WIDTH-SIDE'::text THEN (COALESCE(man_netgully.units::integer, 1)::numeric * cat_gully.length / 100::numeric)::numeric(12,3)
            ELSE (cat_gully.width / 100::numeric)::numeric(12,3)
        END AS total_width,
        CASE
            WHEN man_netgully.units_placement::text = 'LENGTH-SIDE'::text THEN (COALESCE(man_netgully.units::integer, 1)::numeric * cat_gully.width / 100::numeric)::numeric(12,3)
            WHEN man_netgully.units_placement::text = 'WIDTH-SIDE'::text THEN (COALESCE(man_netgully.units::integer, 1)::numeric * cat_gully.length / 100::numeric)::numeric(12,3)
            ELSE (cat_gully.length / 100::numeric)::numeric(12,3)
        END AS total_length,
    n.ymax - COALESCE(man_netgully.sander_depth, 0::numeric) AS depth,
    n.annotation,
    i.y0,
    i.ysur,
    i.apond,
    i.outlet_type,
    i.custom_width,
    i.custom_length,
    i.custom_depth,
    i.gully_method,
    i.weir_cd,
    i.orifice_cd,
    i.custom_a_param,
    i.custom_b_param,
    i.efficiency
   FROM v_edit_node n
     JOIN inp_netgully i USING (node_id)
     LEFT JOIN man_netgully USING (node_id)
     LEFT JOIN cat_gully ON man_netgully.gullycat_id::text = cat_gully.id::text
  WHERE n.is_operative IS TRUE;
CREATE OR REPLACE VIEW v_edit_inp_divider AS  SELECT v_edit_node.node_id,
    v_edit_node.top_elev,
    v_edit_node.custom_top_elev,
    v_edit_node.ymax,
    v_edit_node.custom_ymax,
    v_edit_node.elev,
    v_edit_node.custom_elev,
    v_edit_node.sys_elev,
    v_edit_node.nodecat_id,
    v_edit_node.sector_id,
    v_edit_node.macrosector_id,
    v_edit_node.state,
    v_edit_node.state_type,
    v_edit_node.annotation,
    v_edit_node.expl_id,
    inp_divider.divider_type,
    inp_divider.arc_id,
    inp_divider.curve_id,
    inp_divider.qmin,
    inp_divider.ht,
    inp_divider.cd,
    inp_divider.y0,
    inp_divider.ysur,
    inp_divider.apond,
    v_edit_node.the_geom
   FROM v_edit_node
     JOIN inp_divider ON v_edit_node.node_id = inp_divider.node_id
  WHERE v_edit_node.is_operative = true;

CREATE OR REPLACE VIEW v_edit_inp_junction AS  SELECT n.node_id,
    n.top_elev,
    n.custom_top_elev,
    n.ymax,
    n.custom_ymax,
    n.elev,
    n.custom_elev,
    n.sys_elev,
    n.nodecat_id,
    n.sector_id,
    n.macrosector_id,
    n.state,
    n.state_type,
    n.annotation,
    n.expl_id,
    inp_junction.y0,
    inp_junction.ysur,
    inp_junction.apond,
    inp_junction.outfallparam::text AS outfallparam,
    n.the_geom
   FROM v_edit_node n
     JOIN inp_junction USING (node_id)
  WHERE n.is_operative IS TRUE;

CREATE OR REPLACE VIEW v_edit_inp_dscenario_inflows AS  SELECT s.dscenario_id,
    f.node_id,
    f.order_id,
    f.timser_id,
    f.sfactor,
    f.base,
    f.pattern_id
   FROM selector_inp_dscenario s,
    inp_dscenario_inflows f
     JOIN v_edit_inp_junction USING (node_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;
CREATE OR REPLACE VIEW v_edit_inp_dscenario_inflows_poll AS  SELECT s.dscenario_id,
    f.node_id,
    f.poll_id,
    f.timser_id,
    f.form_type,
    f.mfactor,
    f.sfactor,
    f.base,
    f.pattern_id
   FROM selector_inp_dscenario s,
    inp_dscenario_inflows_poll f
     JOIN v_edit_inp_junction USING (node_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;
CREATE OR REPLACE VIEW v_edit_inp_dscenario_junction AS  SELECT f.dscenario_id,
    f.node_id,
    f.elev,
    f.ymax,
    f.y0,
    f.ysur,
    f.apond,
    f.outfallparam,
    v_edit_inp_junction.the_geom
   FROM selector_inp_dscenario s,
    inp_dscenario_junction f
     JOIN v_edit_inp_junction USING (node_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;
CREATE OR REPLACE VIEW v_edit_inp_dscenario_treatment AS  SELECT s.dscenario_id,
    f.node_id,
    f.poll_id,
    f.function
   FROM selector_inp_dscenario s,
    inp_dscenario_treatment f
     JOIN v_edit_inp_junction USING (node_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;
CREATE OR REPLACE VIEW v_edit_inp_dwf AS  SELECT i.dwfscenario_id,
    i.node_id,
    i.value,
    i.pat1,
    i.pat2,
    i.pat3,
    i.pat4
   FROM config_param_user c,
    inp_dwf i
     JOIN v_edit_inp_junction USING (node_id)
  WHERE c.cur_user::name = CURRENT_USER AND c.parameter::text = 'inp_options_dwfscenario'::text AND c.value::integer = i.dwfscenario_id;
CREATE OR REPLACE VIEW v_edit_inp_inflows AS  SELECT inp_inflows.node_id,
    inp_inflows.order_id,
    inp_inflows.timser_id,
    inp_inflows.sfactor,
    inp_inflows.base,
    inp_inflows.pattern_id
   FROM inp_inflows
     JOIN v_edit_inp_junction USING (node_id);
CREATE OR REPLACE VIEW v_edit_inp_inflows_poll AS  SELECT inp_inflows_poll.node_id,
    inp_inflows_poll.poll_id,
    inp_inflows_poll.timser_id,
    inp_inflows_poll.form_type,
    inp_inflows_poll.mfactor,
    inp_inflows_poll.sfactor,
    inp_inflows_poll.base,
    inp_inflows_poll.pattern_id
   FROM inp_inflows_poll
     JOIN v_edit_inp_junction USING (node_id);
CREATE OR REPLACE VIEW v_edit_inp_treatment AS  SELECT inp_treatment.node_id,
    inp_treatment.poll_id,
    inp_treatment.function
   FROM inp_treatment
     JOIN v_edit_inp_junction USING (node_id);

CREATE OR REPLACE VIEW v_ui_plan_arc_cost AS  WITH p AS (
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
    1 AS measurement,
    a.m2pav_cost AS total_cost,
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
    count(v_edit_connec.connec_id) AS measurement,
    (min(v.price) * count(v_edit_connec.connec_id)::numeric / COALESCE(min(p.length), 1::numeric))::numeric(12,2) AS total_cost,
    min(p.length)::numeric(12,2) AS length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_edit_connec USING (arc_id)
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
    count(v_edit_gully.gully_id) AS measurement,
    (min(v.price) * count(v_edit_gully.gully_id)::numeric / COALESCE(min(p.length), 1::numeric))::numeric(12,2) AS total_cost,
    min(p.length)::numeric(12,2) AS length
   FROM p p(arc_id, node_1, node_2, arc_type, arccat_id, epa_type, state, expl_id, sector_id, annotation, soilcat_id, y1, y2, mean_y, z1, z2, thickness, width, b, bulk, geom1, area, y_param, total_y, rec_y, geom1_ext, calculed_y, m3mlexc, m2mltrenchl, m2mlbottom, m2mlpav, m3mlprotec, m3mlfill, m3mlexcess, m3exc_cost, m2trenchl_cost, m2bottom_cost, m2pav_cost, m3protec_cost, m3fill_cost, m3excess_cost, cost_unit, pav_cost, exc_cost, trenchl_cost, base_cost, protec_cost, fill_cost, excess_cost, arc_cost, cost, length, budget, other_budget, total_budget, the_geom, id, matcat_id, shape, geom1_1, geom2, geom3, geom4, geom5, geom6, geom7, geom8, geom_r, descript, link, brand_id, model_id, svg, z1_1, z2_1, width_1, area_1, estimated_depth, thickness_1, cost_unit_1, cost_1, m2bottom_cost_1, m3protec_cost_1, active, label, tsect_id, curve_id, arc_type_1, acoeff, connect_cost, id_1, descript_1, link_1, y_param_1, b_1, trenchlining, m3exc_cost_1, m3fill_cost_1, m3excess_cost_1, m2trenchl_cost_1, active_1, cat_cost, cat_m2bottom_cost, cat_connect_cost, cat_m3_protec_cost, cat_m3exc_cost, cat_m3fill_cost, cat_m3excess_cost, cat_m2trenchl_cost)
     JOIN v_edit_gully USING (arc_id)
     JOIN v_price_compost v ON p.cat_connect_cost = v.id::text
  GROUP BY p.arc_id
  ORDER BY 1, 2;
CREATE OR REPLACE VIEW v_plan_result_arc AS  SELECT plan_rec_result_arc.arc_id,
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
CREATE OR REPLACE VIEW v_plan_psector AS  SELECT plan_psector.psector_id,
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
    (((100::numeric + plan_psector.gexpenses) / 100::numeric * ((100::numeric + plan_psector.vat) / 100::numeric) * ((100::numeric + plan_psector.other) / 100::numeric))::numeric(14,2)::double precision * (
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
                  WHERE plan_psector_x_arc.doable IS TRUE
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
                  WHERE plan_psector_x_node.doable IS TRUE
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
  WHERE plan_psector.psector_id = selector_psector.psector_id AND selector_psector.cur_user = "current_user"()::text;
CREATE OR REPLACE VIEW v_plan_current_psector AS  SELECT plan_psector.psector_id,
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
CREATE OR REPLACE VIEW v_plan_psector_all AS  SELECT plan_psector.psector_id,
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
CREATE OR REPLACE VIEW v_plan_psector_budget AS  SELECT row_number() OVER (ORDER BY v_plan_arc.arc_id) AS rid,
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
 SELECT row_number() OVER (ORDER BY v_edit_plan_psector_x_other.id) + 19999 AS rid,
    v_edit_plan_psector_x_other.psector_id,
    'other'::text AS feature_type,
    v_edit_plan_psector_x_other.price_id AS featurecat_id,
    NULL::integer AS feature_id,
    v_edit_plan_psector_x_other.measurement AS length,
    v_edit_plan_psector_x_other.price AS unitary_cost,
    v_edit_plan_psector_x_other.total_budget
   FROM v_edit_plan_psector_x_other
  ORDER BY 1, 2, 4;
CREATE OR REPLACE VIEW v_plan_psector_budget_arc AS  SELECT row_number() OVER (ORDER BY v_plan_arc.arc_id) AS rid,
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
CREATE OR REPLACE VIEW v_plan_psector_budget_detail AS  SELECT v_plan_arc.arc_id,
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

CREATE OR REPLACE VIEW v_edit_inp_conduit AS  SELECT v_edit_arc.arc_id,
    v_edit_arc.node_1,
    v_edit_arc.node_2,
    v_edit_arc.y1,
    v_edit_arc.custom_y1,
    v_edit_arc.elev1,
    v_edit_arc.custom_elev1,
    v_edit_arc.sys_elev1,
    v_edit_arc.y2,
    v_edit_arc.custom_y2,
    v_edit_arc.elev2,
    v_edit_arc.custom_elev2,
    v_edit_arc.sys_elev2,
    v_edit_arc.arccat_id,
    v_edit_arc.matcat_id,
    v_edit_arc.cat_shape,
    v_edit_arc.cat_geom1,
    v_edit_arc.gis_length,
    v_edit_arc.sector_id,
    v_edit_arc.macrosector_id,
    v_edit_arc.state,
    v_edit_arc.state_type,
    v_edit_arc.annotation,
    v_edit_arc.inverted_slope,
    v_edit_arc.custom_length,
    v_edit_arc.expl_id,
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
    v_edit_arc.the_geom
   FROM v_edit_arc
     JOIN inp_conduit USING (arc_id)
  WHERE v_edit_arc.is_operative IS TRUE;

CREATE OR REPLACE VIEW v_edit_inp_dscenario_conduit AS  SELECT f.dscenario_id,
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
    v_edit_inp_conduit.the_geom
   FROM selector_inp_dscenario s,
    inp_dscenario_conduit f
     JOIN v_edit_inp_conduit USING (arc_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;
CREATE OR REPLACE VIEW v_ui_node_x_connection_downstream AS  SELECT row_number() OVER (ORDER BY v_edit_arc.node_1) + 1000000 AS rid,
    v_edit_arc.node_1 AS node_id,
    v_edit_arc.arc_id AS feature_id,
    v_edit_arc.code AS feature_code,
    v_edit_arc.arc_type AS featurecat_id,
    v_edit_arc.arccat_id,
    v_edit_arc.y2 AS depth,
    st_length2d(v_edit_arc.the_geom)::numeric(12,2) AS length,
    node.node_id AS downstream_id,
    node.code AS downstream_code,
    node.node_type::text AS downstream_type,
    v_edit_arc.y1 AS downstream_depth,
    v_edit_arc.sys_type,
    st_x(st_lineinterpolatepoint(v_edit_arc.the_geom, 0.5::double precision)) AS x,
    st_y(st_lineinterpolatepoint(v_edit_arc.the_geom, 0.5::double precision)) AS y,
    cat_arc.descript,
    value_state.name AS state,
    'v_edit_arc'::text AS sys_table_id
   FROM v_edit_arc
     JOIN node ON v_edit_arc.node_2 = node.node_id
     LEFT JOIN cat_arc ON v_edit_arc.arccat_id::text = cat_arc.id::text
     JOIN value_state ON v_edit_arc.state = value_state.id;
CREATE OR REPLACE VIEW v_ui_node_x_connection_upstream AS  SELECT row_number() OVER (ORDER BY v_edit_arc.node_2) + 1000000 AS rid,
    v_edit_arc.node_2 AS node_id,
    v_edit_arc.arc_id AS feature_id,
    v_edit_arc.code AS feature_code,
    v_edit_arc.arc_type AS featurecat_id,
    v_edit_arc.arccat_id,
    v_edit_arc.y1 AS depth,
    st_length2d(v_edit_arc.the_geom)::numeric(12,2) AS length,
    node.node_id AS upstream_id,
    node.code AS upstream_code,
    node.node_type AS upstream_type,
    v_edit_arc.y2 AS upstream_depth,
    v_edit_arc.sys_type,
    st_x(st_lineinterpolatepoint(v_edit_arc.the_geom, 0.5::double precision)) AS x,
    st_y(st_lineinterpolatepoint(v_edit_arc.the_geom, 0.5::double precision)) AS y,
    cat_arc.descript,
    value_state.name AS state,
    'v_edit_arc'::text AS sys_table_id
   FROM v_edit_arc
     JOIN node ON v_edit_arc.node_1 = node.node_id
     LEFT JOIN cat_arc ON v_edit_arc.arccat_id::text = cat_arc.id::text
     JOIN value_state ON v_edit_arc.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_connec.connec_id) row_number() OVER (ORDER BY node.node_id) + 2000000 AS rid,
    node.node_id,
    v_edit_connec.connec_id AS feature_id,
    v_edit_connec.code AS feature_code,
    v_edit_connec.connec_type AS featurecat_id,
    v_edit_connec.conneccat_id AS arccat_id,
    v_edit_connec.y1 AS depth,
    st_length2d(link.the_geom)::numeric(12,2) AS length,
    v_edit_connec.connec_id AS upstream_id,
    v_edit_connec.code AS upstream_code,
    v_edit_connec.connec_type AS upstream_type,
    v_edit_connec.y2 AS upstream_depth,
    v_edit_connec.sys_type,
    st_x(v_edit_connec.the_geom) AS x,
    st_y(v_edit_connec.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_connec'::text AS sys_table_id
   FROM v_edit_connec
     JOIN link ON link.feature_id = v_edit_connec.connec_id AND link.feature_type::text = 'CONNEC'::text
     JOIN node ON v_edit_connec.pjoint_id = node.node_id AND v_edit_connec.pjoint_type::text = 'NODE'::text
     LEFT JOIN cat_connec ON v_edit_connec.conneccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_connec.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_connec.connec_id) row_number() OVER (ORDER BY node.node_id) + 3000000 AS rid,
    node.node_id,
    v_edit_connec.connec_id AS feature_id,
    v_edit_connec.code AS feature_code,
    v_edit_connec.connec_type AS featurecat_id,
    v_edit_connec.conneccat_id AS arccat_id,
    v_edit_connec.y1 AS depth,
    st_length2d(link.the_geom)::numeric(12,2) AS length,
    v_edit_connec.connec_id AS upstream_id,
    v_edit_connec.code AS upstream_code,
    v_edit_connec.connec_type AS upstream_type,
    v_edit_connec.y2 AS upstream_depth,
    v_edit_connec.sys_type,
    st_x(v_edit_connec.the_geom) AS x,
    st_y(v_edit_connec.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_connec'::text AS sys_table_id
   FROM v_edit_connec
     JOIN link ON link.feature_id = v_edit_connec.connec_id AND link.feature_type::text = 'CONNEC'::text AND link.exit_type::text = 'CONNEC'::text
     JOIN connec ON connec.connec_id = link.exit_id AND connec.pjoint_type::text = 'NODE'::text
     JOIN node ON connec.pjoint_id = node.node_id
     LEFT JOIN cat_connec ON v_edit_connec.conneccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_connec.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_gully.gully_id) row_number() OVER (ORDER BY node.node_id) + 4000000 AS rid,
    node.node_id,
    v_edit_gully.gully_id AS feature_id,
    v_edit_gully.code AS feature_code,
    v_edit_gully.gully_type AS featurecat_id,
    v_edit_gully.connec_arccat_id AS arccat_id,
    v_edit_gully.ymax - v_edit_gully.sandbox AS depth,
    v_edit_gully.connec_length AS length,
    v_edit_gully.gully_id AS upstream_id,
    v_edit_gully.code AS upstream_code,
    v_edit_gully.gully_type AS upstream_type,
    v_edit_gully.connec_depth AS upstream_depth,
    v_edit_gully.sys_type,
    st_x(v_edit_gully.the_geom) AS x,
    st_y(v_edit_gully.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_gully'::text AS sys_table_id
   FROM v_edit_gully
     JOIN link ON link.feature_id = v_edit_gully.gully_id AND link.feature_type::text = 'GULLY'::text
     JOIN node ON v_edit_gully.pjoint_id = node.node_id AND v_edit_gully.pjoint_type::text = 'NODE'::text
     LEFT JOIN cat_connec ON v_edit_gully.connec_arccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_gully.state = value_state.id
UNION
 SELECT DISTINCT ON (v_edit_gully.gully_id) row_number() OVER (ORDER BY node.node_id) + 5000000 AS rid,
    node.node_id,
    v_edit_gully.gully_id AS feature_id,
    v_edit_gully.code AS feature_code,
    v_edit_gully.gully_type AS featurecat_id,
    v_edit_gully.connec_arccat_id AS arccat_id,
    v_edit_gully.ymax - v_edit_gully.sandbox AS depth,
    v_edit_gully.connec_length AS length,
    v_edit_gully.gully_id AS upstream_id,
    v_edit_gully.code AS upstream_code,
    v_edit_gully.gully_type AS upstream_type,
    v_edit_gully.connec_depth AS upstream_depth,
    v_edit_gully.sys_type,
    st_x(v_edit_gully.the_geom) AS x,
    st_y(v_edit_gully.the_geom) AS y,
    cat_connec.descript,
    value_state.name AS state,
    'v_edit_gully'::text AS sys_table_id
   FROM v_edit_gully
     JOIN link ON link.feature_id = v_edit_gully.gully_id AND link.feature_type::text = 'GULLY'::text AND link.exit_type::text = 'GULLY'::text
     JOIN gully ON gully.gully_id = link.exit_id AND gully.pjoint_type::text = 'NODE'::text
     JOIN node ON gully.pjoint_id = node.node_id
     LEFT JOIN cat_connec ON v_edit_gully.connec_arccat_id::text = cat_connec.id::text
     JOIN value_state ON v_edit_gully.state = value_state.id;


CREATE OR REPLACE VIEW v_edit_inp_orifice AS  SELECT v_edit_arc.arc_id,
    v_edit_arc.node_1,
    v_edit_arc.node_2,
    v_edit_arc.y1,
    v_edit_arc.custom_y1,
    v_edit_arc.elev1,
    v_edit_arc.custom_elev1,
    v_edit_arc.sys_elev1,
    v_edit_arc.y2,
    v_edit_arc.custom_y2,
    v_edit_arc.elev2,
    v_edit_arc.custom_elev2,
    v_edit_arc.sys_elev2,
    v_edit_arc.arccat_id,
    v_edit_arc.gis_length,
    v_edit_arc.sector_id,
    v_edit_arc.macrosector_id,
    v_edit_arc.state,
    v_edit_arc.state_type,
    v_edit_arc.annotation,
    v_edit_arc.inverted_slope,
    v_edit_arc.custom_length,
    v_edit_arc.expl_id,
    inp_orifice.ori_type,
    inp_orifice.offsetval,
    inp_orifice.cd,
    inp_orifice.orate,
    inp_orifice.flap,
    inp_orifice.shape,
    inp_orifice.geom1,
    inp_orifice.geom2,
    inp_orifice.geom3,
    inp_orifice.geom4,
    v_edit_arc.the_geom
   FROM v_edit_arc
     JOIN inp_orifice USING (arc_id)
  WHERE v_edit_arc.is_operative IS TRUE;
CREATE OR REPLACE VIEW v_edit_inp_outlet AS  SELECT v_edit_arc.arc_id,
    v_edit_arc.node_1,
    v_edit_arc.node_2,
    v_edit_arc.y1,
    v_edit_arc.custom_y1,
    v_edit_arc.elev1,
    v_edit_arc.custom_elev1,
    v_edit_arc.sys_elev1,
    v_edit_arc.y2,
    v_edit_arc.custom_y2,
    v_edit_arc.elev2,
    v_edit_arc.custom_elev2,
    v_edit_arc.sys_elev2,
    v_edit_arc.arccat_id,
    v_edit_arc.gis_length,
    v_edit_arc.sector_id,
    v_edit_arc.macrosector_id,
    v_edit_arc.state,
    v_edit_arc.state_type,
    v_edit_arc.annotation,
    v_edit_arc.inverted_slope,
    v_edit_arc.custom_length,
    v_edit_arc.expl_id,
    inp_outlet.outlet_type,
    inp_outlet.offsetval,
    inp_outlet.curve_id,
    inp_outlet.cd1,
    inp_outlet.cd2,
    inp_outlet.flap,
    v_edit_arc.the_geom
   FROM v_edit_arc
     JOIN inp_outlet USING (arc_id)
  WHERE v_edit_arc.is_operative IS TRUE;
CREATE OR REPLACE VIEW v_edit_inp_pump AS  SELECT v_edit_arc.arc_id,
    v_edit_arc.node_1,
    v_edit_arc.node_2,
    v_edit_arc.y1,
    v_edit_arc.custom_y1,
    v_edit_arc.elev1,
    v_edit_arc.custom_elev1,
    v_edit_arc.sys_elev1,
    v_edit_arc.y2,
    v_edit_arc.custom_y2,
    v_edit_arc.elev2,
    v_edit_arc.custom_elev2,
    v_edit_arc.sys_elev2,
    v_edit_arc.arccat_id,
    v_edit_arc.gis_length,
    v_edit_arc.sector_id,
    v_edit_arc.macrosector_id,
    v_edit_arc.state,
    v_edit_arc.state_type,
    v_edit_arc.annotation,
    v_edit_arc.inverted_slope,
    v_edit_arc.custom_length,
    v_edit_arc.expl_id,
    inp_pump.curve_id,
    inp_pump.status,
    inp_pump.startup,
    inp_pump.shutoff,
    v_edit_arc.the_geom
   FROM v_edit_arc
     JOIN inp_pump USING (arc_id)
  WHERE v_edit_arc.is_operative IS TRUE;
CREATE OR REPLACE VIEW v_edit_inp_virtual AS  SELECT v_edit_arc.arc_id,
    v_edit_arc.node_1,
    v_edit_arc.node_2,
    v_edit_arc.arccat_id,
    v_edit_arc.gis_length,
    v_edit_arc.sector_id,
    v_edit_arc.macrosector_id,
    v_edit_arc.state,
    v_edit_arc.state_type,
    v_edit_arc.expl_id,
    inp_virtual.fusion_node,
    inp_virtual.add_length,
    v_edit_arc.the_geom
   FROM v_edit_arc
     JOIN inp_virtual ON v_edit_arc.arc_id::text = inp_virtual.arc_id::text
  WHERE v_edit_arc.is_operative IS TRUE;
CREATE OR REPLACE VIEW v_edit_inp_weir AS  SELECT v_edit_arc.arc_id,
    v_edit_arc.node_1,
    v_edit_arc.node_2,
    v_edit_arc.y1,
    v_edit_arc.custom_y1,
    v_edit_arc.elev1,
    v_edit_arc.custom_elev1,
    v_edit_arc.sys_elev1,
    v_edit_arc.y2,
    v_edit_arc.custom_y2,
    v_edit_arc.elev2,
    v_edit_arc.custom_elev2,
    v_edit_arc.sys_elev2,
    v_edit_arc.arccat_id,
    v_edit_arc.gis_length,
    v_edit_arc.sector_id,
    v_edit_arc.macrosector_id,
    v_edit_arc.state,
    v_edit_arc.state_type,
    v_edit_arc.annotation,
    v_edit_arc.inverted_slope,
    v_edit_arc.custom_length,
    v_edit_arc.expl_id,
    inp_weir.weir_type,
    inp_weir.offsetval,
    inp_weir.cd,
    inp_weir.ec,
    inp_weir.cd2,
    inp_weir.flap,
    inp_weir.geom1,
    inp_weir.geom2,
    inp_weir.geom3,
    inp_weir.geom4,
    inp_weir.surcharge,
    v_edit_arc.the_geom,
    inp_weir.road_width,
    inp_weir.road_surf,
    inp_weir.coef_curve
   FROM v_edit_arc
     JOIN inp_weir USING (arc_id)
  WHERE v_edit_arc.is_operative IS TRUE;
CREATE OR REPLACE VIEW v_ui_workcat_x_feature_end AS  SELECT row_number() OVER (ORDER BY v_edit_arc.arc_id) + 1000000 AS rid,
    'ARC'::character varying AS feature_type,
    v_edit_arc.arccat_id AS featurecat_id,
    v_edit_arc.arc_id AS feature_id,
    v_edit_arc.code,
    exploitation.name AS expl_name,
    v_edit_arc.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_arc
     JOIN exploitation ON exploitation.expl_id = v_edit_arc.expl_id
  WHERE v_edit_arc.state = 0
UNION
 SELECT row_number() OVER (ORDER BY v_edit_node.node_id) + 2000000 AS rid,
    'NODE'::character varying AS feature_type,
    v_edit_node.nodecat_id AS featurecat_id,
    v_edit_node.node_id AS feature_id,
    v_edit_node.code,
    exploitation.name AS expl_name,
    v_edit_node.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_node
     JOIN exploitation ON exploitation.expl_id = v_edit_node.expl_id
  WHERE v_edit_node.state = 0
UNION
 SELECT row_number() OVER (ORDER BY v_edit_connec.connec_id) + 3000000 AS rid,
    'CONNEC'::character varying AS feature_type,
    v_edit_connec.conneccat_id AS featurecat_id,
    v_edit_connec.connec_id AS feature_id,
    v_edit_connec.code,
    exploitation.name AS expl_name,
    v_edit_connec.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_connec
     JOIN exploitation ON exploitation.expl_id = v_edit_connec.expl_id
  WHERE v_edit_connec.state = 0
UNION
 SELECT row_number() OVER (ORDER BY element.element_id) + 4000000 AS rid,
    'ELEMENT'::character varying AS feature_type,
    element.elementcat_id AS featurecat_id,
    element.element_id AS feature_id,
    element.code,
    exploitation.name AS expl_name,
    element.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM element
     JOIN exploitation ON exploitation.expl_id = element.expl_id
  WHERE element.state = 0
UNION
 SELECT row_number() OVER (ORDER BY v_edit_gully.gully_id) + 4000000 AS rid,
    'GULLY'::character varying AS feature_type,
    v_edit_gully.gullycat_id AS featurecat_id,
    v_edit_gully.gully_id AS feature_id,
    v_edit_gully.code,
    exploitation.name AS expl_name,
    v_edit_gully.workcat_id_end AS workcat_id,
    exploitation.expl_id
   FROM v_edit_gully
     JOIN exploitation ON exploitation.expl_id = v_edit_gully.expl_id
  WHERE v_edit_gully.state = 0;

DROP VIEW IF EXISTS v_edit_dma;
DROP VIEW IF EXISTS v_ui_dma;

CREATE OR REPLACE VIEW v_edit_dma
AS SELECT d.dma_id,
    d.name,
    d.expl_id,
    d.muni_id,
    d.sector_id,
    d.graphconfig,
    d.the_geom
FROM dma d;

CREATE OR REPLACE VIEW v_ui_dma
AS SELECT d.dma_id,
    d.name,
    d.expl_id,
    d.muni_id,
    d.sector_id,
    d.graphconfig,
    d.active
FROM dma d;

CREATE OR REPLACE VIEW v_edit_inp_inlet
AS SELECT v_edit_node.node_id,
    v_edit_node.node_type,
    v_edit_node.top_elev,
    v_edit_node.ymax,
    v_edit_node.custom_ymax,
    v_edit_node.elev,
    v_edit_node.custom_elev,
    v_edit_node.sys_elev,
    v_edit_node.nodecat_id,
    v_edit_node.sector_id,
    v_edit_node.macrosector_id,
    v_edit_node.state,
    v_edit_node.state_type,
    v_edit_node.annotation,
    v_edit_node.expl_id,
    v_edit_node.the_geom,
    v_edit_node.ymax - COALESCE(v_edit_node.elev, 0::numeric) AS depth,
    inp_inlet.y0,
    inp_inlet.ysur,
    inp_inlet.apond,
    inp_inlet.inlet_type,
    inp_inlet.outlet_type,
    inp_inlet.gully_method,
    inp_inlet.custom_top_elev,
    inp_inlet.custom_depth,
    inp_inlet.inlet_length,
    inp_inlet.inlet_width,
    inp_inlet.cd1,
    inp_inlet.cd2,
    inp_inlet.efficiency
    FROM v_edit_node
        JOIN inp_inlet USING (node_id)
    WHERE v_edit_node.is_operative IS TRUE;

CREATE OR REPLACE VIEW v_edit_inp_dscenario_inlet
AS SELECT s.dscenario_id,
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
    v_edit_inp_inlet.the_geom
    FROM selector_inp_dscenario s, inp_dscenario_inlet f
    JOIN v_edit_inp_inlet USING (node_id)
	WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW ve_epa_inlet
AS SELECT inp_inlet.node_id,
	inp_inlet.y0,
	inp_inlet.ysur,
	inp_inlet.apond,
	inp_inlet.inlet_type,
	inp_inlet.outlet_type,
	inp_inlet.gully_method,
	inp_inlet.custom_top_elev,
	inp_inlet.custom_depth,
	inp_inlet.inlet_length,
	inp_inlet.inlet_width,
	inp_inlet.cd1,
	inp_inlet.cd2,
	inp_inlet.efficiency,
    d.aver_depth AS depth_average,
    d.max_depth AS depth_max,
    d.time_days AS depth_max_day,
    d.time_hour AS depth_max_hour,
    s.hour_surch AS surcharge_hour,
    s.max_height AS surgarge_max_height,
    f.hour_flood AS flood_hour,
    f.max_rate AS flood_max_rate,
    f.time_days AS time_day,
    f.time_hour,
    f.tot_flood AS flood_total,
    f.max_ponded AS flood_max_ponded
   FROM inp_inlet
     LEFT JOIN v_rpt_nodedepth_sum d ON inp_inlet.node_id::text = d.node_id::text
     LEFT JOIN v_rpt_nodesurcharge_sum s ON d.node_id::text = s.node_id::text
     LEFT JOIN v_rpt_nodeflooding_sum f ON s.node_id::text = f.node_id::text;


-- CREATE PARENT VIEWS WITH NEW NAMES
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"data":{"action":"MULTI-DELETE" }}$$);

ALTER VIEW v_edit_arc RENAME TO ve_arc;
ALTER VIEW v_edit_connec RENAME TO ve_connec;
ALTER VIEW v_edit_node RENAME TO ve_node;
ALTER VIEW v_edit_link RENAME TO ve_link;
ALTER VIEW v_edit_gully RENAME TO ve_gully;
ALTER VIEW v_edit_link_connec RENAME TO ve_link_connec;
ALTER VIEW v_edit_link_gully RENAME TO ve_link_gully;
--
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
        ), arc_psector AS (
         SELECT pp.arc_id,
            pp.state AS p_state
           FROM plan_psector_x_arc pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
        ), arc_selector AS (
         SELECT arc.arc_id
           FROM arc
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND arc.state = s.state_id
             LEFT JOIN ( SELECT arc_psector.arc_id
                   FROM arc_psector
                  WHERE arc_psector.p_state = 0) a USING (arc_id)
          WHERE a.arc_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(arc.expl_visibility::integer[], arc.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = arc.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = arc.muni_id))
        UNION ALL
         SELECT arc_psector.arc_id
           FROM arc_psector
          WHERE arc_psector.p_state = 1
        ), arc_selected AS (
         SELECT arc.arc_id,
            arc.code,
            arc.sys_code,
            arc.node_1,
            arc.nodetype_1,
            arc.elev1,
            arc.custom_elev1,
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END AS sys_elev1,
            arc.y1,
            arc.custom_y1,
                CASE
                    WHEN
                    CASE
                        WHEN arc.custom_y1 IS NULL THEN arc.y1
                        ELSE arc.custom_y1
                    END IS NULL THEN arc.node_sys_top_elev_1 - arc.sys_elev1
                    ELSE
                    CASE
                        WHEN arc.custom_y1 IS NULL THEN arc.y1
                        ELSE arc.custom_y1
                    END
                END AS sys_y1,
            arc.node_sys_top_elev_1 -
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END - cat_arc.geom1 AS r1,
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END - arc.node_sys_elev_1 AS z1,
            arc.node_2,
            arc.nodetype_2,
            arc.elev2,
            arc.custom_elev2,
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END AS sys_elev2,
            arc.y2,
            arc.custom_y2,
                CASE
                    WHEN
                    CASE
                        WHEN arc.custom_y2 IS NULL THEN arc.y2
                        ELSE arc.custom_y2
                    END IS NULL THEN arc.node_sys_top_elev_2 - arc.sys_elev2
                    ELSE
                    CASE
                        WHEN arc.custom_y2 IS NULL THEN arc.y2
                        ELSE arc.custom_y2
                    END
                END AS sys_y2,
            arc.node_sys_top_elev_2 -
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END - cat_arc.geom1 AS r2,
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END - arc.node_sys_elev_2 AS z2,
            cat_feature.feature_class AS sys_type,
            arc.arc_type::text AS arc_type,
            arc.arccat_id,
                CASE
                    WHEN arc.matcat_id IS NULL THEN cat_arc.matcat_id
                    ELSE arc.matcat_id
                END AS matcat_id,
            cat_arc.shape AS cat_shape,
            cat_arc.geom1 AS cat_geom1,
            cat_arc.geom2 AS cat_geom2,
            cat_arc.width AS cat_width,
            cat_arc.area AS cat_area,
            arc.epa_type,
            arc.state,
            arc.state_type,
            arc.parent_id,
            arc.expl_id,
            e.macroexpl_id,
            arc.muni_id,
            arc.sector_id,
            sector_table.macrosector_id,
            sector_table.sector_type,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            arc.drainzone_outfall,
            arc.dwfzone_id,
            dwfzone_table.dwfzone_type,
            arc.dwfzone_outfall,
            arc.omzone_id,
            omzone_table.macroomzone_id,
            omzone_table.omzone_type,
            arc.dma_id,
            arc.omunit_id,
            arc.minsector_id,
            arc.pavcat_id,
            arc.soilcat_id,
            arc.function_type,
            arc.category_type,
            arc.location_type,
            arc.fluid_type,
            arc.custom_length,
            st_length(arc.the_geom)::numeric(12,2) AS gis_length,
            arc.sys_slope AS slope,
            arc.descript,
            arc.annotation,
            arc.observ,
            arc.comment,
            concat(cat_feature.link_path, arc.link) AS link,
            arc.num_value,
            arc.district_id,
            arc.postcode,
            arc.streetaxis_id,
            arc.postnumber,
            arc.postcomplement,
            arc.streetaxis2_id,
            arc.postnumber2,
            arc.postcomplement2,
            mu.region_id,
            mu.province_id,
            arc.workcat_id,
            arc.workcat_id_end,
            arc.workcat_id_plan,
            arc.builtdate,
            arc.registration_date,
            arc.enddate,
            arc.ownercat_id,
            arc.last_visitdate,
            arc.visitability,
            arc.om_state,
            arc.conserv_state,
            arc.brand_id,
            arc.model_id,
            arc.serial_number,
            arc.asset_id,
            arc.adate,
            arc.adescript,
            arc.verified,
            arc.uncertain,
            arc.datasource,
            cat_arc.label,
            arc.label_x,
            arc.label_y,
            arc.label_rotation,
            arc.label_quadrant,
            arc.inventory,
            arc.publish,
            vst.is_operative,
            arc.is_scadamap,
                CASE
                    WHEN arc.sector_id > 0 AND vst.is_operative = true AND arc.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN arc.epa_type
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
            arc.lock_level,
            arc.initoverflowpath,
            arc.inverted_slope,
            arc.negative_offset,
            arc.expl_visibility,
            date_trunc('second'::text, arc.created_at) AS created_at,
            arc.created_by,
            date_trunc('second'::text, arc.updated_at) AS updated_at,
            arc.updated_by,
            arc.the_geom,
            arc.meandering
           FROM arc_selector
             JOIN arc USING (arc_id)
             JOIN cat_arc ON arc.arccat_id::text = cat_arc.id::text
             JOIN cat_feature ON arc.arc_type::text = cat_feature.id::text
             JOIN exploitation e ON e.expl_id = arc.expl_id
             JOIN ext_municipality mu ON arc.muni_id = mu.muni_id
             JOIN value_state_type vst ON vst.id = arc.state_type
             JOIN sector_table ON sector_table.sector_id = arc.sector_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = arc.omzone_id
             LEFT JOIN drainzone_table ON arc.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON arc.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN arc_add ON arc_add.arc_id = arc.arc_id
        )
 SELECT arc_id,
    code,
    sys_code,
    node_1,
    nodetype_1,
    elev1,
    custom_elev1,
    sys_elev1,
    y1,
    custom_y1,
    sys_y1,
    r1,
    z1,
    node_2,
    nodetype_2,
    elev2,
    custom_elev2,
    sys_elev2,
    y2,
    custom_y2,
    sys_y2,
    r2,
    z2,
    sys_type,
    arc_type,
    arccat_id,
    matcat_id,
    cat_shape,
    cat_geom1,
    cat_geom2,
    cat_width,
    cat_area,
    epa_type,
    state,
    state_type,
    parent_id,
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
    omzone_type,
    omunit_id,
    minsector_id,
    pavcat_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
    custom_length,
    gis_length,
    slope,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    registration_date,
    enddate,
    ownercat_id,
    last_visitdate,
    visitability,
    om_state,
    conserv_state,
    brand_id,
    model_id,
    serial_number,
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
    label_quadrant,
    inventory,
    publish,
    is_operative,
    is_scadamap,
    inp_type,
    result_id,
    max_flow,
    max_veloc,
    mfull_flow,
    mfull_depth,
    manning_veloc,
    manning_flow,
    dwf_minflow,
    dwf_maxflow,
    dwf_minvel,
    dwf_maxvel,
    conduit_capacity,
    sector_style,
    drainzone_style,
    dwfzone_style,
    omzone_style,
    lock_level,
    initoverflowpath,
    inverted_slope,
    negative_offset,
    expl_visibility,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom,
    meandering
   FROM arc_selected;

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
        ), node_psector AS (
         SELECT pp.node_id,
            pp.state AS p_state
           FROM plan_psector_x_node pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
        ), node_selector AS (
         SELECT node.node_id
           FROM node
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND node.state = s.state_id
             LEFT JOIN ( SELECT node_psector.node_id
                   FROM node_psector
                  WHERE node_psector.p_state = 0) a USING (node_id)
          WHERE a.node_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(node.expl_visibility::integer[], node.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = node.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = node.muni_id))
        UNION ALL
         SELECT node_psector.node_id
           FROM node_psector
          WHERE node_psector.p_state = 1
        ), node_selected AS (
         SELECT node.node_id,
            node.code,
            node.sys_code,
            node.top_elev,
            node.custom_top_elev,
                CASE
                    WHEN node.custom_top_elev IS NOT NULL THEN node.custom_top_elev
                    ELSE node.top_elev
                END AS sys_top_elev,
            node.ymax,
            node.custom_ymax,
                CASE
                    WHEN node.custom_ymax IS NOT NULL THEN node.custom_ymax
                    ELSE node.ymax
                END AS sys_ymax,
            node.elev,
            node.custom_elev,
                CASE
                    WHEN node.elev IS NOT NULL AND node.custom_elev IS NULL THEN node.elev
                    WHEN node.custom_elev IS NOT NULL THEN node.custom_elev
                    ELSE NULL::numeric(12,3)
                END AS sys_elev,
            cat_feature.feature_class AS sys_type,
            node.node_type::text AS node_type,
                CASE
                    WHEN node.matcat_id IS NULL THEN cat_node.matcat_id
                    ELSE node.matcat_id
                END AS matcat_id,
            node.nodecat_id,
            node.epa_type,
            node.state,
            node.state_type,
            node.arc_id,
            node.parent_id,
            node.expl_id,
            exploitation.macroexpl_id,
            node.muni_id,
            node.sector_id,
            sector_table.macrosector_id,
            sector_table.sector_type,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            node.drainzone_outfall,
            node.dwfzone_id,
            dwfzone_table.dwfzone_type,
            node.dwfzone_outfall,
            node.omzone_id,
            omzone_table.macroomzone_id,
            node.dma_id,
            node.omunit_id,
            node.minsector_id,
            node.pavcat_id,
            node.soilcat_id,
            node.function_type,
            node.category_type,
            node.location_type,
            node.fluid_type,
            node.annotation,
            node.observ,
            node.comment,
            node.descript,
            concat(cat_feature.link_path, node.link) AS link,
            node.num_value,
            node.district_id,
            node.postcode,
            node.streetaxis_id,
            node.postnumber,
            node.postcomplement,
            node.streetaxis2_id,
            node.postnumber2,
            node.postcomplement2,
            mu.region_id,
            mu.province_id,
            node.workcat_id,
            node.workcat_id_end,
            node.workcat_id_plan,
            node.builtdate,
            node.enddate,
            node.ownercat_id,
            node.conserv_state,
            node.om_state,
            node.access_type,
            node.placement_type,
            node.brand_id,
            node.model_id,
            node.serial_number,
            node.asset_id,
            node.adate,
            node.adescript,
            node.verified,
            node.xyz_date,
            node.uncertain,
            node.datasource,
            node.unconnected,
            cat_node.label,
            node.label_x,
            node.label_y,
            node.label_rotation,
            node.rotation,
            node.label_quadrant,
            node.hemisphere,
            cat_node.svg,
            node.inventory,
            node.publish,
            vst.is_operative,
            node.is_scadamap,
                CASE
                    WHEN node.sector_id > 0 AND vst.is_operative = true AND node.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN node.epa_type
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
            node.lock_level,
            node.expl_visibility,
            ( SELECT st_x(node.the_geom) AS st_x) AS xcoord,
            ( SELECT st_y(node.the_geom) AS st_y) AS ycoord,
            ( SELECT st_y(st_transform(node.the_geom, 4326)) AS st_y) AS lat,
            ( SELECT st_x(st_transform(node.the_geom, 4326)) AS st_x) AS long,
            date_trunc('second'::text, node.created_at) AS created_at,
            node.created_by,
            date_trunc('second'::text, node.updated_at) AS updated_at,
            node.updated_by,
            node.the_geom
           FROM node_selector
             JOIN node USING (node_id)
             JOIN cat_node ON node.nodecat_id::text = cat_node.id::text
             JOIN cat_feature ON cat_feature.id::text = node.node_type::text
             JOIN exploitation ON node.expl_id = exploitation.expl_id
             JOIN ext_municipality mu ON node.muni_id = mu.muni_id
             JOIN value_state_type vst ON vst.id = node.state_type
             JOIN sector_table ON sector_table.sector_id = node.sector_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = node.omzone_id
             LEFT JOIN drainzone_table ON node.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON node.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN node_add ON node_add.node_id = node.node_id
        ), node_base AS (
         SELECT node_selected.node_id,
            node_selected.code,
            node_selected.sys_code,
            node_selected.top_elev,
            node_selected.custom_top_elev,
            node_selected.sys_top_elev,
            node_selected.ymax,
            node_selected.custom_ymax,
                CASE
                    WHEN node_selected.sys_ymax IS NOT NULL THEN node_selected.sys_ymax
                    ELSE (node_selected.sys_top_elev - node_selected.sys_elev)::numeric(12,3)
                END AS sys_ymax,
            node_selected.elev,
            node_selected.custom_elev,
                CASE
                    WHEN node_selected.elev IS NOT NULL AND node_selected.custom_elev IS NULL THEN node_selected.elev
                    WHEN node_selected.custom_elev IS NOT NULL THEN node_selected.custom_elev
                    ELSE (node_selected.sys_top_elev - node_selected.sys_ymax)::numeric(12,3)
                END AS sys_elev,
            node_selected.node_type,
            node_selected.sys_type,
            node_selected.matcat_id,
            node_selected.nodecat_id,
            node_selected.epa_type,
            node_selected.state,
            node_selected.state_type,
            node_selected.arc_id,
            node_selected.parent_id,
            node_selected.expl_id,
            node_selected.macroexpl_id,
            node_selected.muni_id,
            node_selected.sector_id,
            node_selected.macrosector_id,
            node_selected.sector_type,
            node_selected.drainzone_id,
            node_selected.drainzone_type,
            node_selected.drainzone_outfall,
            node_selected.dwfzone_id,
            node_selected.dwfzone_type,
            node_selected.dwfzone_outfall,
            node_selected.omzone_id,
            node_selected.macroomzone_id,
            node_selected.dma_id,
            node_selected.omunit_id,
            node_selected.minsector_id,
            node_selected.pavcat_id,
            node_selected.soilcat_id,
            node_selected.function_type,
            node_selected.category_type,
            node_selected.location_type,
            node_selected.fluid_type,
            node_selected.annotation,
            node_selected.observ,
            node_selected.comment,
            node_selected.descript,
            node_selected.link,
            node_selected.num_value,
            node_selected.district_id,
            node_selected.postcode,
            node_selected.streetaxis_id,
            node_selected.postnumber,
            node_selected.postcomplement,
            node_selected.streetaxis2_id,
            node_selected.postnumber2,
            node_selected.postcomplement2,
            node_selected.region_id,
            node_selected.province_id,
            node_selected.workcat_id,
            node_selected.workcat_id_end,
            node_selected.workcat_id_plan,
            node_selected.builtdate,
            node_selected.enddate,
            node_selected.ownercat_id,
            node_selected.conserv_state,
            node_selected.om_state,
            node_selected.access_type,
            node_selected.placement_type,
            node_selected.brand_id,
            node_selected.model_id,
            node_selected.serial_number,
            node_selected.asset_id,
            node_selected.adate,
            node_selected.adescript,
            node_selected.verified,
            node_selected.xyz_date,
            node_selected.uncertain,
            node_selected.datasource,
            node_selected.unconnected,
            node_selected.label,
            node_selected.label_x,
            node_selected.label_y,
            node_selected.label_rotation,
            node_selected.rotation,
            node_selected.label_quadrant,
            node_selected.hemisphere,
            node_selected.svg,
            node_selected.inventory,
            node_selected.publish,
            node_selected.is_operative,
            node_selected.is_scadamap,
            node_selected.inp_type,
            node_selected.result_id,
            node_selected.max_depth,
            node_selected.max_height,
            node_selected.flooding_rate,
            node_selected.flooding_vol,
            node_selected.sector_style,
            node_selected.omzone_style,
            node_selected.drainzone_style,
            node_selected.dwfzone_style,
            node_selected.lock_level,
            node_selected.expl_visibility,
            node_selected.xcoord,
            node_selected.ycoord,
            node_selected.lat,
            node_selected.long,
            node_selected.created_at,
            node_selected.created_by,
            node_selected.updated_at,
            node_selected.updated_by,
            node_selected.the_geom
           FROM node_selected
        )
 SELECT node_id,
    code,
    sys_code,
    top_elev,
    custom_top_elev,
    sys_top_elev,
    ymax,
    custom_ymax,
    sys_ymax,
    elev,
    custom_elev,
    sys_elev,
    node_type,
    sys_type,
    matcat_id,
    nodecat_id,
    epa_type,
    state,
    state_type,
    arc_id,
    parent_id,
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
    omunit_id,
    minsector_id,
    pavcat_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
    annotation,
    observ,
    comment,
    descript,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    enddate,
    ownercat_id,
    conserv_state,
    om_state,
    access_type,
    placement_type,
    brand_id,
    model_id,
    serial_number,
    asset_id,
    adate,
    adescript,
    verified,
    xyz_date,
    uncertain,
    datasource,
    unconnected,
    label,
    label_x,
    label_y,
    label_rotation,
    rotation,
    label_quadrant,
    hemisphere,
    svg,
    inventory,
    publish,
    is_operative,
    is_scadamap,
    inp_type,
    result_id,
    max_depth,
    max_height,
    flooding_rate,
    flooding_vol,
    sector_style,
    omzone_style,
    drainzone_style,
    dwfzone_style,
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
    the_geom
   FROM node_base;

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
            connec.plot_code,
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
    plot_code,
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
        ), link_psector AS (
        ( SELECT DISTINCT ON (pp.connec_id, pp.state) 'CONNEC'::text AS feature_type,
            pp.connec_id AS feature_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.link_id
           FROM plan_psector_x_connec pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST)
        UNION ALL
        ( SELECT DISTINCT ON (pp.gully_id, pp.state) 'GULLY'::text AS feature_type,
            pp.gully_id AS feature_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.link_id
           FROM plan_psector_x_gully pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.gully_id, pp.state, pp.link_id DESC NULLS LAST)
        ), link_selector AS (
         SELECT l.link_id
           FROM link l
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND l.state = s.state_id
             LEFT JOIN ( SELECT link_psector.link_id
                   FROM link_psector
                  WHERE link_psector.p_state = 0) a ON a.link_id = l.link_id
          WHERE a.link_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(l.expl_visibility::integer[], l.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = l.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = l.muni_id))
        UNION ALL
         SELECT link_psector.link_id
           FROM link_psector
          WHERE link_psector.p_state = 1
        ), link_selected AS (
         SELECT DISTINCT ON (l.link_id) l.link_id,
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
            l.the_geom
           FROM link_selector
             JOIN link l USING (link_id)
             JOIN exploitation ON l.expl_id = exploitation.expl_id
             JOIN ext_municipality mu ON l.muni_id = mu.muni_id
             JOIN sector_table ON l.sector_id = sector_table.sector_id
             JOIN cat_link ON cat_link.id::text = l.linkcat_id::text
             JOIN cat_feature ON cat_feature.id::text = l.link_type::text
             LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
             LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN inp_network_mode ON true
        )
 SELECT link_id,
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
   FROM link_selected;

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
            l.expl_id,
            exploitation.macroexpl_id,
            l.sector_id,
            sector_table.sector_type,
            sector_table.macrosector_id,
            l.omzone_id,
            omzone_table.omzone_type,
            omzone_table.macroomzone_id,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            l.dwfzone_id,
            dwfzone_table.dwfzone_type,
            l.fluid_type,
            l.dma_id
           FROM link l
             JOIN exploitation USING (expl_id)
             JOIN sector_table ON l.sector_id = sector_table.sector_id
             LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
             LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
          WHERE l.state = 2
        ), gully_psector AS (
         SELECT DISTINCT ON (pp.gully_id, pp.state) pp.gully_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.arc_id,
            pp.link_id
           FROM plan_psector_x_gully pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.gully_id, pp.state, pp.link_id DESC NULLS LAST
        ), gully_selector AS (
         SELECT gully.gully_id,
            gully.arc_id,
            NULL::integer AS link_id
           FROM gully
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND gully.state = s.state_id
             LEFT JOIN ( SELECT gully_psector.gully_id
                   FROM gully_psector
                  WHERE gully_psector.p_state = 0) a USING (gully_id)
          WHERE a.gully_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(gully.expl_visibility::integer[], gully.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = gully.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = gully.muni_id))
        UNION ALL
         SELECT gully_psector.gully_id,
            gully_psector.arc_id,
            gully_psector.link_id
           FROM gully_psector
          WHERE gully_psector.p_state = 1
        ), gully_selected AS (
         SELECT gully.gully_id,
            gully.code,
            gully.sys_code,
            gully.top_elev,
                CASE
                    WHEN gully.width IS NULL THEN cat_gully.width
                    ELSE gully.width
                END AS width,
                CASE
                    WHEN gully.length IS NULL THEN cat_gully.length
                    ELSE gully.length
                END AS length,
                CASE
                    WHEN gully.ymax IS NULL THEN cat_gully.ymax
                    ELSE gully.ymax
                END AS ymax,
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
                CASE
                    WHEN ((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric) IS NOT NULL THEN ((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric)::numeric(12,3)
                    ELSE gully.connec_depth
                END AS connec_depth,
                CASE
                    WHEN gully._connec_matcat_id IS NULL THEN cc.matcat_id::text
                    ELSE gully._connec_matcat_id
                END AS connec_matcat_id,
            gully.top_elev - gully.ymax + gully.sandbox AS connec_y1,
            gully.connec_y2,
            gully.arc_id,
            gully.epa_type,
            gully.state,
            gully.state_type,
            gully.expl_id,
            exploitation.macroexpl_id,
            gully.muni_id,
                CASE
                    WHEN link_planned.sector_id IS NULL THEN sector_table.sector_id
                    ELSE link_planned.sector_id
                END AS sector_id,
                CASE
                    WHEN link_planned.macrosector_id IS NULL THEN sector_table.macrosector_id
                    ELSE link_planned.macrosector_id
                END AS macrosector_id,
                CASE
                    WHEN link_planned.sector_id IS NULL THEN sector_table.sector_type
                    ELSE link_planned.sector_type
                END AS sector_type,
                CASE
                    WHEN link_planned.drainzone_id IS NULL THEN dwfzone_table.drainzone_id
                    ELSE link_planned.drainzone_id
                END AS drainzone_id,
                CASE
                    WHEN link_planned.drainzone_type IS NULL THEN drainzone_table.drainzone_type
                    ELSE link_planned.drainzone_type
                END AS drainzone_type,
            gully.drainzone_outfall,
                CASE
                    WHEN link_planned.dwfzone_id IS NULL THEN dwfzone_table.dwfzone_id
                    ELSE link_planned.dwfzone_id
                END AS dwfzone_id,
                CASE
                    WHEN link_planned.dwfzone_type IS NULL THEN dwfzone_table.dwfzone_type
                    ELSE link_planned.dwfzone_type
                END AS dwfzone_type,
            gully.dwfzone_outfall,
                CASE
                    WHEN link_planned.omzone_id IS NULL THEN omzone_table.omzone_id
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
                    WHEN link_planned.dma_id IS NULL THEN gully.dma_id
                    ELSE link_planned.dma_id
                END AS dma_id,
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
                CASE
                    WHEN link_planned.exit_id IS NULL THEN gully.pjoint_id
                    ELSE link_planned.exit_id
                END AS pjoint_id,
                CASE
                    WHEN link_planned.exit_type IS NULL THEN gully.pjoint_type
                    ELSE link_planned.exit_type
                END AS pjoint_type,
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
            gully.the_geom
           FROM gully_selector
             JOIN gully USING (gully_id)
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
             LEFT JOIN inp_network_mode ON true
        )
 SELECT gully_id,
    code,
    sys_code,
    top_elev,
    width,
    length,
    ymax,
    sandbox,
    matcat_id,
    gully_type,
    sys_type,
    gullycat_id,
    cat_gully_matcat,
    units,
    units_placement,
    groove,
    groove_height,
    groove_length,
    siphon,
    siphon_type,
    odorflap,
    connec_arccat_id,
    connec_length,
    connec_depth,
    connec_matcat_id,
    connec_y1,
    connec_y2,
    arc_id,
    epa_type,
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
    omzone_type,
    omunit_id,
    minsector_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    enddate,
    ownercat_id,
    om_state,
    pjoint_id,
    pjoint_type,
    placement_type,
    access_type,
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
    inp_type,
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
   FROM gully_selected;

-- old v_edit parent tables:
CREATE OR REPLACE VIEW v_edit_arc
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
        ), arc_psector AS (
         SELECT pp.arc_id,
            pp.state AS p_state
           FROM plan_psector_x_arc pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
        ), arc_selector AS (
         SELECT arc.arc_id
           FROM arc
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND arc.state = s.state_id
             LEFT JOIN ( SELECT arc_psector.arc_id
                   FROM arc_psector
                  WHERE arc_psector.p_state = 0) a USING (arc_id)
          WHERE a.arc_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(arc.expl_visibility::integer[], arc.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = arc.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = arc.muni_id))
        UNION ALL
         SELECT arc_psector.arc_id
           FROM arc_psector
          WHERE arc_psector.p_state = 1
        ), arc_selected AS (
         SELECT arc.arc_id,
            arc.code,
            arc.sys_code,
            arc.node_1,
            arc.nodetype_1,
            arc.elev1,
            arc.custom_elev1,
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END AS sys_elev1,
            arc.y1,
            arc.custom_y1,
                CASE
                    WHEN
                    CASE
                        WHEN arc.custom_y1 IS NULL THEN arc.y1
                        ELSE arc.custom_y1
                    END IS NULL THEN arc.node_sys_top_elev_1 - arc.sys_elev1
                    ELSE
                    CASE
                        WHEN arc.custom_y1 IS NULL THEN arc.y1
                        ELSE arc.custom_y1
                    END
                END AS sys_y1,
            arc.node_sys_top_elev_1 -
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END - cat_arc.geom1 AS r1,
                CASE
                    WHEN arc.sys_elev1 IS NULL THEN arc.node_sys_elev_1
                    ELSE arc.sys_elev1
                END - arc.node_sys_elev_1 AS z1,
            arc.node_2,
            arc.nodetype_2,
            arc.elev2,
            arc.custom_elev2,
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END AS sys_elev2,
            arc.y2,
            arc.custom_y2,
                CASE
                    WHEN
                    CASE
                        WHEN arc.custom_y2 IS NULL THEN arc.y2
                        ELSE arc.custom_y2
                    END IS NULL THEN arc.node_sys_top_elev_2 - arc.sys_elev2
                    ELSE
                    CASE
                        WHEN arc.custom_y2 IS NULL THEN arc.y2
                        ELSE arc.custom_y2
                    END
                END AS sys_y2,
            arc.node_sys_top_elev_2 -
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END - cat_arc.geom1 AS r2,
                CASE
                    WHEN arc.sys_elev2 IS NULL THEN arc.node_sys_elev_2
                    ELSE arc.sys_elev2
                END - arc.node_sys_elev_2 AS z2,
            cat_feature.feature_class AS sys_type,
            arc.arc_type::text AS arc_type,
            arc.arccat_id,
                CASE
                    WHEN arc.matcat_id IS NULL THEN cat_arc.matcat_id
                    ELSE arc.matcat_id
                END AS matcat_id,
            cat_arc.shape AS cat_shape,
            cat_arc.geom1 AS cat_geom1,
            cat_arc.geom2 AS cat_geom2,
            cat_arc.width AS cat_width,
            cat_arc.area AS cat_area,
            arc.epa_type,
            arc.state,
            arc.state_type,
            arc.parent_id,
            arc.expl_id,
            e.macroexpl_id,
            arc.muni_id,
            arc.sector_id,
            sector_table.macrosector_id,
            sector_table.sector_type,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            arc.drainzone_outfall,
            arc.dwfzone_id,
            dwfzone_table.dwfzone_type,
            arc.dwfzone_outfall,
            arc.omzone_id,
            omzone_table.macroomzone_id,
            omzone_table.omzone_type,
            arc.dma_id,
            arc.omunit_id,
            arc.minsector_id,
            arc.pavcat_id,
            arc.soilcat_id,
            arc.function_type,
            arc.category_type,
            arc.location_type,
            arc.fluid_type,
            arc.custom_length,
            st_length(arc.the_geom)::numeric(12,2) AS gis_length,
            arc.sys_slope AS slope,
            arc.descript,
            arc.annotation,
            arc.observ,
            arc.comment,
            concat(cat_feature.link_path, arc.link) AS link,
            arc.num_value,
            arc.district_id,
            arc.postcode,
            arc.streetaxis_id,
            arc.postnumber,
            arc.postcomplement,
            arc.streetaxis2_id,
            arc.postnumber2,
            arc.postcomplement2,
            mu.region_id,
            mu.province_id,
            arc.workcat_id,
            arc.workcat_id_end,
            arc.workcat_id_plan,
            arc.builtdate,
            arc.registration_date,
            arc.enddate,
            arc.ownercat_id,
            arc.last_visitdate,
            arc.visitability,
            arc.om_state,
            arc.conserv_state,
            arc.brand_id,
            arc.model_id,
            arc.serial_number,
            arc.asset_id,
            arc.adate,
            arc.adescript,
            arc.verified,
            arc.uncertain,
            arc.datasource,
            cat_arc.label,
            arc.label_x,
            arc.label_y,
            arc.label_rotation,
            arc.label_quadrant,
            arc.inventory,
            arc.publish,
            vst.is_operative,
            arc.is_scadamap,
                CASE
                    WHEN arc.sector_id > 0 AND vst.is_operative = true AND arc.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN arc.epa_type
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
            arc.lock_level,
            arc.initoverflowpath,
            arc.inverted_slope,
            arc.negative_offset,
            arc.expl_visibility,
            date_trunc('second'::text, arc.created_at) AS created_at,
            arc.created_by,
            date_trunc('second'::text, arc.updated_at) AS updated_at,
            arc.updated_by,
            arc.the_geom,
            arc.meandering
           FROM arc_selector
             JOIN arc USING (arc_id)
             JOIN cat_arc ON arc.arccat_id::text = cat_arc.id::text
             JOIN cat_feature ON arc.arc_type::text = cat_feature.id::text
             JOIN exploitation e ON e.expl_id = arc.expl_id
             JOIN ext_municipality mu ON arc.muni_id = mu.muni_id
             JOIN value_state_type vst ON vst.id = arc.state_type
             JOIN sector_table ON sector_table.sector_id = arc.sector_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = arc.omzone_id
             LEFT JOIN drainzone_table ON arc.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON arc.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN arc_add ON arc_add.arc_id = arc.arc_id
        )
 SELECT arc_id,
    code,
    sys_code,
    node_1,
    nodetype_1,
    elev1,
    custom_elev1,
    sys_elev1,
    y1,
    custom_y1,
    sys_y1,
    r1,
    z1,
    node_2,
    nodetype_2,
    elev2,
    custom_elev2,
    sys_elev2,
    y2,
    custom_y2,
    sys_y2,
    r2,
    z2,
    sys_type,
    arc_type,
    arccat_id,
    matcat_id,
    cat_shape,
    cat_geom1,
    cat_geom2,
    cat_width,
    cat_area,
    epa_type,
    state,
    state_type,
    parent_id,
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
    omzone_type,
    omunit_id,
    minsector_id,
    pavcat_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
    custom_length,
    gis_length,
    slope,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    registration_date,
    enddate,
    ownercat_id,
    last_visitdate,
    visitability,
    om_state,
    conserv_state,
    brand_id,
    model_id,
    serial_number,
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
    label_quadrant,
    inventory,
    publish,
    is_operative,
    is_scadamap,
    inp_type,
    result_id,
    max_flow,
    max_veloc,
    mfull_flow,
    mfull_depth,
    manning_veloc,
    manning_flow,
    dwf_minflow,
    dwf_maxflow,
    dwf_minvel,
    dwf_maxvel,
    conduit_capacity,
    sector_style,
    drainzone_style,
    dwfzone_style,
    omzone_style,
    lock_level,
    initoverflowpath,
    inverted_slope,
    negative_offset,
    expl_visibility,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom,
    meandering
   FROM arc_selected;

CREATE OR REPLACE VIEW v_edit_node
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
        ), node_psector AS (
         SELECT pp.node_id,
            pp.state AS p_state
           FROM plan_psector_x_node pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
        ), node_selector AS (
         SELECT node.node_id
           FROM node
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND node.state = s.state_id
             LEFT JOIN ( SELECT node_psector.node_id
                   FROM node_psector
                  WHERE node_psector.p_state = 0) a USING (node_id)
          WHERE a.node_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(node.expl_visibility::integer[], node.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = node.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = node.muni_id))
        UNION ALL
         SELECT node_psector.node_id
           FROM node_psector
          WHERE node_psector.p_state = 1
        ), node_selected AS (
         SELECT node.node_id,
            node.code,
            node.sys_code,
            node.top_elev,
            node.custom_top_elev,
                CASE
                    WHEN node.custom_top_elev IS NOT NULL THEN node.custom_top_elev
                    ELSE node.top_elev
                END AS sys_top_elev,
            node.ymax,
            node.custom_ymax,
                CASE
                    WHEN node.custom_ymax IS NOT NULL THEN node.custom_ymax
                    ELSE node.ymax
                END AS sys_ymax,
            node.elev,
            node.custom_elev,
                CASE
                    WHEN node.elev IS NOT NULL AND node.custom_elev IS NULL THEN node.elev
                    WHEN node.custom_elev IS NOT NULL THEN node.custom_elev
                    ELSE NULL::numeric(12,3)
                END AS sys_elev,
            cat_feature.feature_class AS sys_type,
            node.node_type::text AS node_type,
                CASE
                    WHEN node.matcat_id IS NULL THEN cat_node.matcat_id
                    ELSE node.matcat_id
                END AS matcat_id,
            node.nodecat_id,
            node.epa_type,
            node.state,
            node.state_type,
            node.arc_id,
            node.parent_id,
            node.expl_id,
            exploitation.macroexpl_id,
            node.muni_id,
            node.sector_id,
            sector_table.macrosector_id,
            sector_table.sector_type,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            node.drainzone_outfall,
            node.dwfzone_id,
            dwfzone_table.dwfzone_type,
            node.dwfzone_outfall,
            node.omzone_id,
            omzone_table.macroomzone_id,
            node.dma_id,
            node.omunit_id,
            node.minsector_id,
            node.pavcat_id,
            node.soilcat_id,
            node.function_type,
            node.category_type,
            node.location_type,
            node.fluid_type,
            node.annotation,
            node.observ,
            node.comment,
            node.descript,
            concat(cat_feature.link_path, node.link) AS link,
            node.num_value,
            node.district_id,
            node.postcode,
            node.streetaxis_id,
            node.postnumber,
            node.postcomplement,
            node.streetaxis2_id,
            node.postnumber2,
            node.postcomplement2,
            mu.region_id,
            mu.province_id,
            node.workcat_id,
            node.workcat_id_end,
            node.workcat_id_plan,
            node.builtdate,
            node.enddate,
            node.ownercat_id,
            node.conserv_state,
            node.om_state,
            node.access_type,
            node.placement_type,
            node.brand_id,
            node.model_id,
            node.serial_number,
            node.asset_id,
            node.adate,
            node.adescript,
            node.verified,
            node.xyz_date,
            node.uncertain,
            node.datasource,
            node.unconnected,
            cat_node.label,
            node.label_x,
            node.label_y,
            node.label_rotation,
            node.rotation,
            node.label_quadrant,
            node.hemisphere,
            cat_node.svg,
            node.inventory,
            node.publish,
            vst.is_operative,
            node.is_scadamap,
                CASE
                    WHEN node.sector_id > 0 AND vst.is_operative = true AND node.epa_type::text <> 'UNDEFINED'::character varying(16)::text THEN node.epa_type
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
            node.lock_level,
            node.expl_visibility,
            ( SELECT st_x(node.the_geom) AS st_x) AS xcoord,
            ( SELECT st_y(node.the_geom) AS st_y) AS ycoord,
            ( SELECT st_y(st_transform(node.the_geom, 4326)) AS st_y) AS lat,
            ( SELECT st_x(st_transform(node.the_geom, 4326)) AS st_x) AS long,
            date_trunc('second'::text, node.created_at) AS created_at,
            node.created_by,
            date_trunc('second'::text, node.updated_at) AS updated_at,
            node.updated_by,
            node.the_geom
           FROM node_selector
             JOIN node USING (node_id)
             JOIN cat_node ON node.nodecat_id::text = cat_node.id::text
             JOIN cat_feature ON cat_feature.id::text = node.node_type::text
             JOIN exploitation ON node.expl_id = exploitation.expl_id
             JOIN ext_municipality mu ON node.muni_id = mu.muni_id
             JOIN value_state_type vst ON vst.id = node.state_type
             JOIN sector_table ON sector_table.sector_id = node.sector_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = node.omzone_id
             LEFT JOIN drainzone_table ON node.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON node.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN node_add ON node_add.node_id = node.node_id
        ), node_base AS (
         SELECT node_selected.node_id,
            node_selected.code,
            node_selected.sys_code,
            node_selected.top_elev,
            node_selected.custom_top_elev,
            node_selected.sys_top_elev,
            node_selected.ymax,
            node_selected.custom_ymax,
                CASE
                    WHEN node_selected.sys_ymax IS NOT NULL THEN node_selected.sys_ymax
                    ELSE (node_selected.sys_top_elev - node_selected.sys_elev)::numeric(12,3)
                END AS sys_ymax,
            node_selected.elev,
            node_selected.custom_elev,
                CASE
                    WHEN node_selected.elev IS NOT NULL AND node_selected.custom_elev IS NULL THEN node_selected.elev
                    WHEN node_selected.custom_elev IS NOT NULL THEN node_selected.custom_elev
                    ELSE (node_selected.sys_top_elev - node_selected.sys_ymax)::numeric(12,3)
                END AS sys_elev,
            node_selected.node_type,
            node_selected.sys_type,
            node_selected.matcat_id,
            node_selected.nodecat_id,
            node_selected.epa_type,
            node_selected.state,
            node_selected.state_type,
            node_selected.arc_id,
            node_selected.parent_id,
            node_selected.expl_id,
            node_selected.macroexpl_id,
            node_selected.muni_id,
            node_selected.sector_id,
            node_selected.macrosector_id,
            node_selected.sector_type,
            node_selected.drainzone_id,
            node_selected.drainzone_type,
            node_selected.drainzone_outfall,
            node_selected.dwfzone_id,
            node_selected.dwfzone_type,
            node_selected.dwfzone_outfall,
            node_selected.omzone_id,
            node_selected.macroomzone_id,
            node_selected.dma_id,
            node_selected.omunit_id,
            node_selected.minsector_id,
            node_selected.pavcat_id,
            node_selected.soilcat_id,
            node_selected.function_type,
            node_selected.category_type,
            node_selected.location_type,
            node_selected.fluid_type,
            node_selected.annotation,
            node_selected.observ,
            node_selected.comment,
            node_selected.descript,
            node_selected.link,
            node_selected.num_value,
            node_selected.district_id,
            node_selected.postcode,
            node_selected.streetaxis_id,
            node_selected.postnumber,
            node_selected.postcomplement,
            node_selected.streetaxis2_id,
            node_selected.postnumber2,
            node_selected.postcomplement2,
            node_selected.region_id,
            node_selected.province_id,
            node_selected.workcat_id,
            node_selected.workcat_id_end,
            node_selected.workcat_id_plan,
            node_selected.builtdate,
            node_selected.enddate,
            node_selected.ownercat_id,
            node_selected.conserv_state,
            node_selected.om_state,
            node_selected.access_type,
            node_selected.placement_type,
            node_selected.brand_id,
            node_selected.model_id,
            node_selected.serial_number,
            node_selected.asset_id,
            node_selected.adate,
            node_selected.adescript,
            node_selected.verified,
            node_selected.xyz_date,
            node_selected.uncertain,
            node_selected.datasource,
            node_selected.unconnected,
            node_selected.label,
            node_selected.label_x,
            node_selected.label_y,
            node_selected.label_rotation,
            node_selected.rotation,
            node_selected.label_quadrant,
            node_selected.hemisphere,
            node_selected.svg,
            node_selected.inventory,
            node_selected.publish,
            node_selected.is_operative,
            node_selected.is_scadamap,
            node_selected.inp_type,
            node_selected.result_id,
            node_selected.max_depth,
            node_selected.max_height,
            node_selected.flooding_rate,
            node_selected.flooding_vol,
            node_selected.sector_style,
            node_selected.omzone_style,
            node_selected.drainzone_style,
            node_selected.dwfzone_style,
            node_selected.lock_level,
            node_selected.expl_visibility,
            node_selected.xcoord,
            node_selected.ycoord,
            node_selected.lat,
            node_selected.long,
            node_selected.created_at,
            node_selected.created_by,
            node_selected.updated_at,
            node_selected.updated_by,
            node_selected.the_geom
           FROM node_selected
        )
 SELECT node_id,
    code,
    sys_code,
    top_elev,
    custom_top_elev,
    sys_top_elev,
    ymax,
    custom_ymax,
    sys_ymax,
    elev,
    custom_elev,
    sys_elev,
    node_type,
    sys_type,
    matcat_id,
    nodecat_id,
    epa_type,
    state,
    state_type,
    arc_id,
    parent_id,
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
    omunit_id,
    minsector_id,
    pavcat_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
    annotation,
    observ,
    comment,
    descript,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    enddate,
    ownercat_id,
    conserv_state,
    om_state,
    access_type,
    placement_type,
    brand_id,
    model_id,
    serial_number,
    asset_id,
    adate,
    adescript,
    verified,
    xyz_date,
    uncertain,
    datasource,
    unconnected,
    label,
    label_x,
    label_y,
    label_rotation,
    rotation,
    label_quadrant,
    hemisphere,
    svg,
    inventory,
    publish,
    is_operative,
    is_scadamap,
    inp_type,
    result_id,
    max_depth,
    max_height,
    flooding_rate,
    flooding_vol,
    sector_style,
    omzone_style,
    drainzone_style,
    dwfzone_style,
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
    the_geom
   FROM node_base;

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
            connec.plot_code,
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
    plot_code,
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

CREATE OR REPLACE VIEW v_edit_link
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
        ), link_psector AS (
        ( SELECT DISTINCT ON (pp.connec_id, pp.state) 'CONNEC'::text AS feature_type,
            pp.connec_id AS feature_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.link_id
           FROM plan_psector_x_connec pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST)
        UNION ALL
        ( SELECT DISTINCT ON (pp.gully_id, pp.state) 'GULLY'::text AS feature_type,
            pp.gully_id AS feature_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.link_id
           FROM plan_psector_x_gully pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.gully_id, pp.state, pp.link_id DESC NULLS LAST)
        ), link_selector AS (
         SELECT l.link_id
           FROM link l
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND l.state = s.state_id
             LEFT JOIN ( SELECT link_psector.link_id
                   FROM link_psector
                  WHERE link_psector.p_state = 0) a ON a.link_id = l.link_id
          WHERE a.link_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(l.expl_visibility::integer[], l.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = l.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = l.muni_id))
        UNION ALL
         SELECT link_psector.link_id
           FROM link_psector
          WHERE link_psector.p_state = 1
        ), link_selected AS (
         SELECT DISTINCT ON (l.link_id) l.link_id,
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
            l.the_geom
           FROM link_selector
             JOIN link l USING (link_id)
             JOIN exploitation ON l.expl_id = exploitation.expl_id
             JOIN ext_municipality mu ON l.muni_id = mu.muni_id
             JOIN sector_table ON l.sector_id = sector_table.sector_id
             JOIN cat_link ON cat_link.id::text = l.linkcat_id::text
             JOIN cat_feature ON cat_feature.id::text = l.link_type::text
             LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
             LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
             LEFT JOIN inp_network_mode ON true
        )
 SELECT link_id,
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
   FROM link_selected;

CREATE OR REPLACE VIEW v_edit_gully
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
            l.expl_id,
            exploitation.macroexpl_id,
            l.sector_id,
            sector_table.sector_type,
            sector_table.macrosector_id,
            l.omzone_id,
            omzone_table.omzone_type,
            omzone_table.macroomzone_id,
            dwfzone_table.drainzone_id,
            drainzone_table.drainzone_type,
            l.dwfzone_id,
            dwfzone_table.dwfzone_type,
            l.fluid_type,
            l.dma_id
           FROM link l
             JOIN exploitation USING (expl_id)
             JOIN sector_table ON l.sector_id = sector_table.sector_id
             LEFT JOIN omzone_table ON l.omzone_id = omzone_table.omzone_id
             LEFT JOIN drainzone_table ON l.omzone_id = drainzone_table.drainzone_id
             LEFT JOIN dwfzone_table ON l.dwfzone_id = dwfzone_table.dwfzone_id
          WHERE l.state = 2
        ), gully_psector AS (
         SELECT DISTINCT ON (pp.gully_id, pp.state) pp.gully_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.arc_id,
            pp.link_id
           FROM plan_psector_x_gully pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.gully_id, pp.state, pp.link_id DESC NULLS LAST
        ), gully_selector AS (
         SELECT gully.gully_id,
            gully.arc_id,
            NULL::integer AS link_id
           FROM gully
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND gully.state = s.state_id
             LEFT JOIN ( SELECT gully_psector.gully_id
                   FROM gully_psector
                  WHERE gully_psector.p_state = 0) a USING (gully_id)
          WHERE a.gully_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(gully.expl_visibility::integer[], gully.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = gully.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = gully.muni_id))
        UNION ALL
         SELECT gully_psector.gully_id,
            gully_psector.arc_id,
            gully_psector.link_id
           FROM gully_psector
          WHERE gully_psector.p_state = 1
        ), gully_selected AS (
         SELECT gully.gully_id,
            gully.code,
            gully.sys_code,
            gully.top_elev,
                CASE
                    WHEN gully.width IS NULL THEN cat_gully.width
                    ELSE gully.width
                END AS width,
                CASE
                    WHEN gully.length IS NULL THEN cat_gully.length
                    ELSE gully.length
                END AS length,
                CASE
                    WHEN gully.ymax IS NULL THEN cat_gully.ymax
                    ELSE gully.ymax
                END AS ymax,
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
                CASE
                    WHEN ((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric) IS NOT NULL THEN ((gully.top_elev - gully.ymax + gully.sandbox + gully.connec_y2) / 2::numeric)::numeric(12,3)
                    ELSE gully.connec_depth
                END AS connec_depth,
                CASE
                    WHEN gully._connec_matcat_id IS NULL THEN cc.matcat_id::text
                    ELSE gully._connec_matcat_id
                END AS connec_matcat_id,
            gully.top_elev - gully.ymax + gully.sandbox AS connec_y1,
            gully.connec_y2,
            gully.arc_id,
            gully.epa_type,
            gully.state,
            gully.state_type,
            gully.expl_id,
            exploitation.macroexpl_id,
            gully.muni_id,
                CASE
                    WHEN link_planned.sector_id IS NULL THEN sector_table.sector_id
                    ELSE link_planned.sector_id
                END AS sector_id,
                CASE
                    WHEN link_planned.macrosector_id IS NULL THEN sector_table.macrosector_id
                    ELSE link_planned.macrosector_id
                END AS macrosector_id,
                CASE
                    WHEN link_planned.sector_id IS NULL THEN sector_table.sector_type
                    ELSE link_planned.sector_type
                END AS sector_type,
                CASE
                    WHEN link_planned.drainzone_id IS NULL THEN dwfzone_table.drainzone_id
                    ELSE link_planned.drainzone_id
                END AS drainzone_id,
                CASE
                    WHEN link_planned.drainzone_type IS NULL THEN drainzone_table.drainzone_type
                    ELSE link_planned.drainzone_type
                END AS drainzone_type,
            gully.drainzone_outfall,
                CASE
                    WHEN link_planned.dwfzone_id IS NULL THEN dwfzone_table.dwfzone_id
                    ELSE link_planned.dwfzone_id
                END AS dwfzone_id,
                CASE
                    WHEN link_planned.dwfzone_type IS NULL THEN dwfzone_table.dwfzone_type
                    ELSE link_planned.dwfzone_type
                END AS dwfzone_type,
            gully.dwfzone_outfall,
                CASE
                    WHEN link_planned.omzone_id IS NULL THEN omzone_table.omzone_id
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
                    WHEN link_planned.dma_id IS NULL THEN gully.dma_id
                    ELSE link_planned.dma_id
                END AS dma_id,
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
                CASE
                    WHEN link_planned.exit_id IS NULL THEN gully.pjoint_id
                    ELSE link_planned.exit_id
                END AS pjoint_id,
                CASE
                    WHEN link_planned.exit_type IS NULL THEN gully.pjoint_type
                    ELSE link_planned.exit_type
                END AS pjoint_type,
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
            gully.the_geom
           FROM gully_selector
             JOIN gully USING (gully_id)
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
             LEFT JOIN inp_network_mode ON true
        )
 SELECT gully_id,
    code,
    sys_code,
    top_elev,
    width,
    length,
    ymax,
    sandbox,
    matcat_id,
    gully_type,
    sys_type,
    gullycat_id,
    cat_gully_matcat,
    units,
    units_placement,
    groove,
    groove_height,
    groove_length,
    siphon,
    siphon_type,
    odorflap,
    connec_arccat_id,
    connec_length,
    connec_depth,
    connec_matcat_id,
    connec_y1,
    connec_y2,
    arc_id,
    epa_type,
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
    omzone_type,
    omunit_id,
    minsector_id,
    soilcat_id,
    function_type,
    category_type,
    location_type,
    fluid_type,
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
    workcat_id,
    workcat_id_end,
    workcat_id_plan,
    builtdate,
    enddate,
    ownercat_id,
    om_state,
    pjoint_id,
    pjoint_type,
    placement_type,
    access_type,
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
    inp_type,
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
   FROM gully_selected;
-- ===============================


ALTER VIEW v_edit_cad_auxcircle RENAME TO ve_cad_auxcircle;
ALTER VIEW v_edit_cad_auxline RENAME TO ve_cad_auxline;
ALTER VIEW v_edit_cad_auxpoint RENAME TO ve_cad_auxpoint;
ALTER VIEW v_edit_cat_dscenario RENAME TO ve_cat_dscenario;
ALTER VIEW v_edit_cat_dwf RENAME TO ve_cat_dwf;
ALTER VIEW v_edit_cat_feature_arc RENAME TO ve_cat_feature_arc;
ALTER VIEW v_edit_cat_feature_connec RENAME TO ve_cat_feature_connec;
ALTER VIEW v_edit_cat_feature_element RENAME TO ve_cat_feature_element;
ALTER VIEW v_edit_cat_feature_gully RENAME TO ve_cat_feature_gully;
ALTER VIEW v_edit_cat_feature_link RENAME TO ve_cat_feature_link;
ALTER VIEW v_edit_cat_feature_node RENAME TO ve_cat_feature_node;
ALTER VIEW v_edit_cat_hydrology RENAME TO ve_cat_hydrology;
ALTER VIEW v_edit_dimensions RENAME TO ve_dimensions;
ALTER VIEW v_edit_dma RENAME TO ve_dma;
ALTER VIEW v_edit_drainzone RENAME TO ve_drainzone;
ALTER VIEW v_edit_dwfzone RENAME TO ve_dwfzone;
ALTER VIEW v_edit_exploitation RENAME TO ve_exploitation;
ALTER VIEW v_edit_inp_conduit RENAME TO ve_inp_conduit;
ALTER VIEW v_edit_inp_controls RENAME TO ve_inp_controls;
ALTER VIEW v_edit_inp_coverage RENAME TO ve_inp_coverage;
ALTER VIEW v_edit_inp_curve RENAME TO ve_inp_curve;
ALTER VIEW v_edit_inp_curve_value RENAME TO ve_inp_curve_value;
ALTER VIEW v_edit_inp_divider RENAME TO ve_inp_divider;
ALTER VIEW v_edit_inp_dscenario_conduit RENAME TO ve_inp_dscenario_conduit;
ALTER VIEW v_edit_inp_dscenario_controls RENAME TO ve_inp_dscenario_controls;
ALTER VIEW v_edit_inp_dscenario_inflows RENAME TO ve_inp_dscenario_inflows;
ALTER VIEW v_edit_inp_dscenario_inflows_poll RENAME TO ve_inp_dscenario_inflows_poll;
ALTER VIEW v_edit_inp_dscenario_inlet RENAME TO ve_inp_dscenario_inlet;
ALTER VIEW v_edit_inp_dscenario_junction RENAME TO ve_inp_dscenario_junction;
ALTER VIEW v_edit_inp_dscenario_lids RENAME TO ve_inp_dscenario_lids;
ALTER VIEW v_edit_inp_dscenario_outfall RENAME TO ve_inp_dscenario_outfall;
ALTER VIEW v_edit_inp_dscenario_raingage RENAME TO ve_inp_dscenario_raingage;
ALTER VIEW v_edit_inp_dscenario_storage RENAME TO ve_inp_dscenario_storage;
ALTER VIEW v_edit_inp_dscenario_treatment RENAME TO ve_inp_dscenario_treatment;
ALTER VIEW v_edit_inp_dwf RENAME TO ve_inp_dwf;
ALTER VIEW v_edit_inp_gully RENAME TO ve_inp_gully;
ALTER VIEW v_edit_inp_inflows RENAME TO ve_inp_inflows;
ALTER VIEW v_edit_inp_inflows_poll RENAME TO ve_inp_inflows_poll;
ALTER VIEW v_edit_inp_inlet RENAME TO ve_inp_inlet;
ALTER VIEW v_edit_inp_junction RENAME TO ve_inp_junction;
ALTER VIEW v_edit_inp_netgully RENAME TO ve_inp_netgully;
ALTER VIEW v_edit_inp_orifice RENAME TO ve_inp_orifice;
ALTER VIEW v_edit_inp_outfall RENAME TO ve_inp_outfall;
ALTER VIEW v_edit_inp_outlet RENAME TO ve_inp_outlet;
ALTER VIEW v_edit_inp_pattern RENAME TO ve_inp_pattern;
ALTER VIEW v_edit_inp_pattern_value RENAME TO ve_inp_pattern_value;
ALTER VIEW v_edit_inp_pump RENAME TO ve_inp_pump;
ALTER VIEW v_edit_inp_storage RENAME TO ve_inp_storage;
ALTER VIEW v_edit_inp_subc2outlet RENAME TO ve_inp_subc2outlet;
ALTER VIEW v_edit_inp_subcatchment RENAME TO ve_inp_subcatchment;
ALTER VIEW v_edit_inp_timeseries RENAME TO ve_inp_timeseries;
ALTER VIEW v_edit_inp_timeseries_value RENAME TO ve_inp_timeseries_value;
ALTER VIEW v_edit_inp_transects RENAME TO ve_inp_transects;
ALTER VIEW v_edit_inp_treatment RENAME TO ve_inp_treatment;
ALTER VIEW v_edit_inp_virtual RENAME TO ve_inp_virtual;
ALTER VIEW v_edit_inp_weir RENAME TO ve_inp_weir;
ALTER VIEW v_edit_macroomzone RENAME TO ve_macroomzone;
ALTER VIEW v_edit_macrosector RENAME TO ve_macrosector;
ALTER VIEW v_edit_om_visit RENAME TO ve_om_visit;
ALTER VIEW v_edit_omzone RENAME TO ve_omzone;
ALTER VIEW v_edit_plan_psector_x_gully RENAME TO ve_plan_psector_x_gully;
ALTER VIEW v_edit_plan_psector_x_other RENAME TO ve_plan_psector_x_other;
ALTER VIEW v_edit_review_arc RENAME TO ve_review_arc;
ALTER VIEW v_edit_review_audit_arc RENAME TO ve_review_audit_arc;
ALTER VIEW v_edit_review_audit_connec RENAME TO ve_review_audit_connec;
ALTER VIEW v_edit_review_audit_gully RENAME TO ve_review_audit_gully;
ALTER VIEW v_edit_review_audit_node RENAME TO ve_review_audit_node;
ALTER VIEW v_edit_review_connec RENAME TO ve_review_connec;
ALTER VIEW v_edit_review_gully RENAME TO ve_review_gully;
ALTER VIEW v_edit_review_node RENAME TO ve_review_node;
ALTER VIEW v_edit_rtc_hydro_data_x_connec RENAME TO ve_rtc_hydro_data_x_connec;
ALTER VIEW v_edit_samplepoint RENAME TO ve_samplepoint;
ALTER VIEW v_edit_sector RENAME TO ve_sector;

CREATE OR REPLACE VIEW ve_inp_dscenario_raingage
AS SELECT p.dscenario_id,
    p.rg_id,
    p.form_type,
    p.intvl,
    p.scf,
    p.rgage_type,
    p.timser_id,
    p.fname,
    p.sta,
    p.units,
    ve_raingage.the_geom
   FROM selector_inp_dscenario,
    ve_raingage
     JOIN inp_dscenario_raingage p USING (rg_id)
     JOIN cat_dscenario d USING (dscenario_id)
  WHERE p.dscenario_id = selector_inp_dscenario.dscenario_id AND selector_inp_dscenario.cur_user = "current_user"()::text;


DROP VIEW IF EXISTS v_edit_raingage;

CREATE OR REPLACE VIEW ve_raingage
AS SELECT raingage.rg_id,
    raingage.form_type,
    raingage.intvl,
    raingage.scf,
    raingage.rgage_type,
    raingage.timser_id,
    raingage.fname,
    raingage.sta,
    raingage.units,
    raingage.the_geom,
    raingage.expl_id,
    raingage.muni_id
   FROM selector_expl,
    raingage
     LEFT JOIN selector_municipality m USING (muni_id)
  WHERE raingage.expl_id = selector_expl.expl_id AND selector_expl.cur_user = "current_user"()::text AND (m.cur_user = CURRENT_USER OR raingage.muni_id IS NULL);

CREATE OR REPLACE VIEW ve_inp_pgully
AS SELECT g.gully_id,
    g.code,
    g.top_elev,
    g.gully_type,
    g.gullycat_id,
    (g.width / 100::numeric)::numeric(12,2) AS grate_width,
    (g.length / 100::numeric)::numeric(12,2) AS grate_length,
    g.arc_id,
    g.sector_id,
    g.expl_id,
    g.state,
    g.state_type,
    polygon.the_geom,
    g.units,
    g.units_placement,
    g.groove,
    g.groove_height,
    g.groove_length,
    g.pjoint_id,
    g.pjoint_type,
        CASE
            WHEN g.units_placement::text = 'LENGTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.width / 100::numeric)::numeric(12,3)
            WHEN g.units_placement::text = 'WIDTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.length / 100::numeric)::numeric(12,3)
            ELSE (cat_gully.width / 100::numeric)::numeric(12,3)
        END AS total_width,
        CASE
            WHEN g.units_placement::text = 'LENGTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.width / 100::numeric)::numeric(12,3)
            WHEN g.units_placement::text = 'WIDTH-SIDE'::text THEN (COALESCE(g.units::integer, 1)::numeric * g.length / 100::numeric)::numeric(12,3)
            ELSE (cat_gully.length / 100::numeric)::numeric(12,3)
        END AS total_length,
    g.ymax - COALESCE(g.sandbox, 0::numeric) AS depth,
    g.annotation,
    i.outlet_type,
    i.custom_top_elev,
    i.custom_width,
    i.custom_length,
    i.custom_depth,
    i.gully_method,
    i.weir_cd,
    i.orifice_cd,
    i.custom_a_param,
    i.custom_b_param,
    i.efficiency
   FROM ve_gully g
     JOIN inp_gully i ON i.gully_id = g.gully_id
     JOIN cat_gully ON g.gullycat_id::text = cat_gully.id::text
     JOIN polygon ON polygon.feature_id = g.gully_id
  WHERE g.is_operative IS TRUE AND g.epa_type = 'PGULLY';

CREATE OR REPLACE VIEW ve_epa_pgully
AS SELECT gully_id,
    outlet_type,
    custom_top_elev,
    custom_width,
    custom_length,
    custom_depth,
    gully_method,
    weir_cd,
    orifice_cd,
    custom_a_param,
    custom_b_param,
    efficiency
   FROM inp_gully;


-- PSECTOR
DROP VIEW IF EXISTS v_plan_psector_gully;
CREATE OR REPLACE VIEW v_plan_psector_gully
AS WITH sel_psector AS (
    SELECT selector_psector.psector_id FROM selector_psector WHERE selector_psector.cur_user = CURRENT_USER
)
SELECT row_number() OVER () AS rid,
    gully.gully_id,
    plan_psector_x_gully.psector_id,
    gully.code,
    gully.gullycat_id,
    gully.gully_type,
    cat_feature.feature_class,
    gully.state AS original_state,
    gully.state_type AS original_state_type,
    plan_psector_x_gully.state AS plan_state,
    plan_psector_x_gully.doable,
    plan_psector.priority AS psector_priority,
    gully.the_geom
FROM gully
JOIN plan_psector_x_gully USING (gully_id)
JOIN plan_psector USING (psector_id)
JOIN cat_gully ON cat_gully.id::text = gully.gullycat_id::text
JOIN cat_feature ON cat_feature.id::text = gully.gully_type::text
WHERE EXISTS (SELECT 1 FROM sel_psector WHERE sel_psector.psector_id = plan_psector_x_gully.psector_id);

CREATE OR REPLACE VIEW ve_dimensions
AS
WITH v_state_dimensions AS (SELECT dimensions.id
   FROM selector_state,
    dimensions
  WHERE dimensions.state = selector_state.state_id AND selector_state.cur_user = CURRENT_USER)
SELECT dimensions.id,
    dimensions.distance,
    dimensions.depth,
    dimensions.the_geom,
    dimensions.x_label,
    dimensions.y_label,
    dimensions.rotation_label,
    dimensions.offset_label,
    dimensions.direction_arrow,
    dimensions.x_symbol,
    dimensions.y_symbol,
    dimensions.feature_id,
    dimensions.feature_type,
    dimensions.state,
    dimensions.expl_id,
    dimensions.observ,
    dimensions.comment,
    dimensions.sector_id,
    dimensions.muni_id
   FROM selector_expl,
    dimensions
     JOIN v_state_dimensions ON dimensions.id = v_state_dimensions.id
     LEFT JOIN selector_municipality m USING (muni_id)
     JOIN selector_sector s USING (sector_id)
  WHERE (m.cur_user = CURRENT_USER::text OR dimensions.muni_id IS NULL) AND s.cur_user = CURRENT_USER::text AND dimensions.expl_id = selector_expl.expl_id AND selector_expl.cur_user = "current_user"()::text;

DROP VIEW IF EXISTS v_state_dimensions;
DROP VIEW IF EXISTS v_state_gully;

CREATE OR REPLACE VIEW ve_plan_psector_x_connec
AS SELECT plan_psector_x_connec.id,
    plan_psector_x_connec.connec_id,
    plan_psector_x_connec.arc_id,
    plan_psector_x_connec.psector_id,
    plan_psector_x_connec.state,
    plan_psector_x_connec.doable,
    plan_psector_x_connec.descript,
    plan_psector_x_connec.link_id,
    plan_psector_x_connec.insert_tstamp,
    plan_psector_x_connec.insert_user,
    link.exit_type
   FROM plan_psector_x_connec
     LEFT JOIN link USING (link_id);


DROP VIEW IF EXISTS ve_plan_psector_x_gully;
CREATE OR REPLACE VIEW ve_plan_psector_x_gully
AS SELECT plan_psector_x_gully.id,
    plan_psector_x_gully.gully_id,
    plan_psector_x_gully.arc_id,
    plan_psector_x_gully.psector_id,
    plan_psector_x_gully.state,
    plan_psector_x_gully.doable,
    plan_psector_x_gully.descript,
    plan_psector_x_gully.link_id,
    plan_psector_x_gully.insert_tstamp,
    plan_psector_x_gully.insert_user,
    link.exit_type
   FROM plan_psector_x_gully
     LEFT JOIN link USING (link_id);

-- remove order_id and nodarc_id from flowregulators
CREATE OR REPLACE VIEW ve_man_frelem AS
  SELECT ve_element.element_id,
    ve_element.code,
    ve_element.sys_code,
    ve_element.top_elev,
    ve_element.element_type,
    ve_element.elementcat_id,
    ve_element.num_elements,
    ve_element.epa_type,
    ve_element.state,
    ve_element.state_type,
    ve_element.expl_id,
    ve_element.muni_id,
    ve_element.sector_id,
    ve_element.omzone_id,
    ve_element.function_type,
    ve_element.category_type,
    ve_element.location_type,
    ve_element.observ,
    ve_element.comment,
    ve_element.link,
    ve_element.workcat_id,
    ve_element.workcat_id_end,
    ve_element.builtdate,
    ve_element.enddate,
    ve_element.ownercat_id,
    ve_element.brand_id,
    ve_element.model_id,
    ve_element.serial_number,
    ve_element.asset_id,
    ve_element.verified,
    ve_element.datasource,
    ve_element.label_x,
    ve_element.label_y,
    ve_element.label_rotation,
    ve_element.rotation,
    ve_element.inventory,
    ve_element.publish,
    ve_element.trace_featuregeom,
    ve_element.lock_level,
    ve_element.expl_visibility,
    man_frelem.node_id,
    man_frelem.to_arc,
    man_frelem.flwreg_length,
    ve_element.created_at,
    ve_element.created_by,
    ve_element.updated_at,
    ve_element.updated_by,
        CASE
            WHEN man_frelem.node_id = a.node_1 THEN st_setsrid(st_makeline(node.the_geom, st_lineinterpolatepoint(a.the_geom, man_frelem.flwreg_length::double precision / st_length(a.the_geom))), SRID_VALUE)::geometry(LineString,SRID_VALUE)
            WHEN man_frelem.node_id = a.node_2 THEN st_setsrid(st_makeline(node.the_geom, st_lineinterpolatepoint(a.the_geom, 1::double precision - man_frelem.flwreg_length::double precision / st_length(a.the_geom))), SRID_VALUE)::geometry(LineString,SRID_VALUE)
            ELSE NULL::geometry(LineString,SRID_VALUE)
        END AS the_geom
   FROM ve_element
     JOIN man_frelem ON ve_element.element_id = man_frelem.element_id
     JOIN arc a ON a.arc_id = man_frelem.to_arc
     JOIN node USING (node_id);

CREATE OR REPLACE VIEW ve_epa_frpump
AS SELECT inp_frpump.element_id,
	man_frelem.node_id,
    inp_frpump.curve_id,
    inp_frpump.status,
    inp_frpump.startup,
    inp_frpump.shutoff,
    v_rpt_pumping_sum.percent,
    v_rpt_pumping_sum.num_startup,
    v_rpt_pumping_sum.min_flow,
    v_rpt_pumping_sum.avg_flow,
    v_rpt_pumping_sum.max_flow,
    v_rpt_pumping_sum.vol_ltr,
    v_rpt_pumping_sum.powus_kwh,
    v_rpt_pumping_sum.timoff_min,
    v_rpt_pumping_sum.timoff_max
   FROM inp_frpump
     LEFT JOIN man_frelem USING (element_id)
     LEFT JOIN v_rpt_pumping_sum ON v_rpt_pumping_sum.arc_id::text = man_frelem.element_id::text;

CREATE OR REPLACE VIEW ve_epa_frweir
AS SELECT inp_frweir.element_id,
	man_frelem.node_id,
    inp_frweir.weir_type,
    inp_frweir.offsetval,
    inp_frweir.cd,
    inp_frweir.ec,
    inp_frweir.cd2,
    inp_frweir.flap,
    inp_frweir.geom1,
    inp_frweir.geom2,
    inp_frweir.geom3,
    inp_frweir.geom4,
    inp_frweir.surcharge,
    inp_frweir.road_width,
    inp_frweir.road_surf,
    inp_frweir.coef_curve,
    rpt_arcflow_sum.max_flow,
    rpt_arcflow_sum.time_days,
    rpt_arcflow_sum.time_hour,
    rpt_arcflow_sum.max_veloc,
    rpt_arcflow_sum.mfull_flow,
    rpt_arcflow_sum.mfull_depth AS mfull_dept,
    rpt_arcflow_sum.max_shear,
    rpt_arcflow_sum.max_hr,
    rpt_arcflow_sum.max_slope,
    rpt_arcflow_sum.day_max,
    rpt_arcflow_sum.time_max,
    rpt_arcflow_sum.min_shear,
    rpt_arcflow_sum.day_min,
    rpt_arcflow_sum.time_min
   FROM inp_frweir
     LEFT JOIN man_frelem USING (element_id)
     LEFT JOIN rpt_arcflow_sum ON rpt_arcflow_sum.arc_id::text = man_frelem.element_id::text;

CREATE OR REPLACE VIEW ve_epa_frorifice
AS SELECT inp_frorifice.element_id,
	man_frelem.node_id,
    inp_frorifice.orifice_type,
    inp_frorifice.offsetval,
    inp_frorifice.cd,
    inp_frorifice.orate,
    inp_frorifice.flap,
    inp_frorifice.shape,
    inp_frorifice.geom1,
    inp_frorifice.geom2,
    inp_frorifice.geom3,
    inp_frorifice.geom4,
    rpt_arcflow_sum.max_flow,
    rpt_arcflow_sum.time_days,
    rpt_arcflow_sum.time_hour,
    rpt_arcflow_sum.max_veloc,
    rpt_arcflow_sum.mfull_flow,
    rpt_arcflow_sum.mfull_depth,
    rpt_arcflow_sum.max_shear,
    rpt_arcflow_sum.max_hr,
    rpt_arcflow_sum.max_slope,
    rpt_arcflow_sum.day_max,
    rpt_arcflow_sum.time_max,
    rpt_arcflow_sum.min_shear,
    rpt_arcflow_sum.day_min,
    rpt_arcflow_sum.time_min
   FROM inp_frorifice
     LEFT JOIN man_frelem USING (element_id)
     LEFT JOIN rpt_arcflow_sum ON rpt_arcflow_sum.arc_id::text = man_frelem.element_id::text;

CREATE OR REPLACE VIEW ve_epa_froutlet
AS SELECT inp_froutlet.element_id,
	man_frelem.node_id,
    inp_froutlet.outlet_type,
	inp_froutlet.offsetval,
    inp_froutlet.curve_id,
    inp_froutlet.cd1,
    inp_froutlet.cd2,
    inp_froutlet.flap,
    rpt_arcflow_sum.max_flow,
    rpt_arcflow_sum.time_days,
    rpt_arcflow_sum.time_hour,
    rpt_arcflow_sum.max_veloc,
    rpt_arcflow_sum.mfull_flow,
    rpt_arcflow_sum.mfull_depth AS mfull_dept,
    rpt_arcflow_sum.max_shear,
    rpt_arcflow_sum.max_hr,
    rpt_arcflow_sum.max_slope,
    rpt_arcflow_sum.day_max,
    rpt_arcflow_sum.time_max,
    rpt_arcflow_sum.min_shear,
    rpt_arcflow_sum.day_min,
    rpt_arcflow_sum.time_min
   FROM inp_froutlet
     LEFT JOIN man_frelem USING (element_id)
     LEFT JOIN rpt_arcflow_sum ON rpt_arcflow_sum.arc_id::text = man_frelem.element_id::text;

CREATE OR REPLACE VIEW ve_inp_froutlet
AS SELECT
    f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    ou.outlet_type,
    ou.offsetval,
    ou.curve_id,
    ou.cd1,
    ou.cd2,
    ou.flap,
    f.the_geom
    FROM ve_man_frelem f
    JOIN inp_froutlet ou USING (element_id);

CREATE OR REPLACE VIEW ve_inp_frweir
AS SELECT
    f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    w.weir_type,
    w.offsetval,
    w.cd,
    w.ec,
    w.cd2,
    w.flap,
    w.geom1,
    w.geom2,
    w.geom3,
    w.geom4,
    w.surcharge,
    w.road_width,
    w.road_surf,
    w.coef_curve,
    f.the_geom
    FROM ve_man_frelem f
    JOIN inp_frweir w USING (element_id);


CREATE OR REPLACE VIEW ve_inp_frpump
AS SELECT
    f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    p.curve_id,
    p.status,
    p.startup,
    p.shutoff,
    f.the_geom
    FROM ve_man_frelem f
    JOIN inp_frpump p USING (element_id);

CREATE OR REPLACE VIEW ve_inp_frorifice
AS SELECT
    f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    ori.orifice_type,
    ori.offsetval,
    ori.cd,
    ori.orate,
    ori.flap,
    ori.shape,
    ori.geom1,
    ori.geom2,
    ori.geom3,
    ori.geom4,
    f.the_geom
    FROM ve_man_frelem f
    JOIN inp_frorifice ori USING (element_id);

CREATE OR REPLACE VIEW ve_inp_dscenario_frpump
AS SELECT s.dscenario_id,
    f.element_id,
    f.curve_id,
    f.status,
    f.startup,
    f.shutoff,
    n.the_geom
    FROM selector_inp_dscenario s, inp_dscenario_frpump f
    JOIN ve_inp_frpump n USING (element_id)
    WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_froutlet
AS SELECT
    s.dscenario_id,
    f.element_id,
    n.node_id,
    f.outlet_type,
    f.offsetval,
    f.curve_id,
    f.cd1,
    f.cd2,
    f.flap,
    n.the_geom
    FROM selector_inp_dscenario s, inp_dscenario_froutlet f
    JOIN ve_inp_froutlet n USING (element_id)
	WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_frweir
AS SELECT
    s.dscenario_id,
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
    n.the_geom
    FROM selector_inp_dscenario s, inp_dscenario_frweir f
    JOIN ve_inp_frweir n USING (element_id)
	WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_frorifice
AS SELECT
    s.dscenario_id,
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
    n.the_geom
    FROM selector_inp_dscenario s, inp_dscenario_frorifice f
    JOIN ve_inp_frorifice n USING (element_id)
    WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER::text;

UPDATE sys_function SET function_alias = 'CREATE EMPTY HYDROLOGY SCENARIO' WHERE function_name = 'gw_fct_create_hydrology_scenario_empty';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4020, 'Infiltration: %v_infiltration%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4022, 'Text: %v_text%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4024, 'The hydrology scenario ( %v_scenarioid% ) already exists with proposed name %v_name%. Please try another one.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4026, 'This new hydrology scenario is now your current scenario.', null, 0, true, 'utils', 'core', 'AUDIT');

UPDATE sys_function SET function_alias = 'CREATE EMPTY DSCENARIO' WHERE function_name = 'gw_fct_create_dwf_scenario_empty';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3880, 'ERROR: The dwf scenario already exists with proposed name (%v_idval%). Please try another one.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3882, 'Id_val: %v_idval%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3884, 'Descript: %v_startdate%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3886, 'Parent: %v_enddate%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3888, 'Type: %v_observ%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3890, 'active: %v_active%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3892, 'Expl_id: %v_expl_id%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3894, 'The new dscenario (%v_scenarioid%) have been created sucessfully', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3896, 'The new dscenario is now your current DWF scenario', null, 0, true, 'utils', 'core', 'AUDIT');


UPDATE sys_function SET function_alias = 'DUPLICATE DWF SCENARIO' WHERE function_name = 'gw_fct_duplicate_dwf_scenario';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3898, 'Dwf scenario named "%v_idval%" created with values from Dwf scenario ( %v_copyfrom% ).', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (3900, 'Copied values from Dwf scenario ( %v_copyfrom% ) to new Dwf scenario ( %v_scenarioid% ).', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4302, 'This DWF scenario is now your current scenario.', null, 0, true, 'utils', 'core', 'AUDIT');



UPDATE sys_function SET function_alias = 'MANAGE DWF VALUES' WHERE function_name = 'gw_fct_manage_dwf_values';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4028, 'Sector: %v_sector_name%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4030, '%v_count% row(s) have been keep from inp_%object_rec% table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4032, 'No rows have been inserted on inp_%object_rec% table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4034, '%v_count2% row(s) have been inserted on inp_%object_rec% table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4036, '%v_count% row(s) have been removed from inp_%object_rec% table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4038, '%v_count% row(s) have been inserted into inp_dwf table from v_edit_inp_junction table.', null, 0, true, 'utils', 'core', 'AUDIT');

UPDATE sys_function SET function_alias = 'MANAGE HYDROLOGY VALUES' WHERE function_name = 'gw_fct_manage_hydrology_values';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4040, 'Infiltration method for (%v_source_name%) and (%v_target_name%) are not the same.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4042, '%v_count% row(s) have been removed from inp_subcathment table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4044, '%v_count% row(s) have been removed from inp_loadings table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4046, '%v_count% row(s) have been removed from inp_groundwater table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4048, '%v_count% row(s) have been removed from inp_coverage table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4050, 'Target and source have same infiltration method.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4052, 'No rows have been inserted for sector %v_sector% on inp_%object_rec% table.', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4054, '%v_count2% row(s) have been inserted for sector %v_sector% on inp_%object_rec% table.', null, 0, true, 'utils', 'core', 'AUDIT');


UPDATE sys_function SET function_alias = 'SET JUNCTIONS OUTLET' WHERE function_name = 'gw_fct_epa_setjunctionsoutlet';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4306, 'Minimun distance used: %v_mindistance%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4308, 'Initial junctions: %v_count%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4310, 'Total junctions after process: %v_count%', null, 0, true, 'utils', 'core', 'AUDIT');


UPDATE sys_function SET function_alias = 'DUPLICATE HYDROLOGY SCENARIO' WHERE function_name = 'gw_fct_duplicate_hydrology_scenario';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4312, 'Source scenario: %v_sourcename%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4314, 'New scenario: %v_name%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4316, 'Hydrology scenario named (%v_name%) have been created with values from hydrology scenario (%v_sourcename%).', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4318, 'The new hydrology scenario (%v_name%) is now your current scenario.', null, 0, true, 'utils', 'core', 'AUDIT');



UPDATE sys_function SET function_alias = 'SET OPTIMUM OUTLET' WHERE function_name = 'gw_fct_epa_setoptimumoutlet';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4202, 'SECTOR ID: %v_sector%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4204, 'HYDROLOGY SCENARIO: %v_name%', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4206, '%v_count2-v_count1% subcatchments have been updated with outlet values', null, 0, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4208, '0 subcatchments have been updated with outlet values', null, 0, true, 'utils', 'core', 'AUDIT');

UPDATE sys_function SET function_alias = 'FLUID TYPE CALCULATION' WHERE function_name = 'gw_fct_graphanalytics_fluid_type';

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4210, 'Fluid type calculation done succesfully', null, 0, true, 'utils', 'core', 'UI');



UPDATE config_toolbox SET inputparams='[
  {
    "widgetname": "graphClass",
    "label": "Graph class:",
    "widgettype": "combo",
    "datatype": "text",
    "tooltip": "Graphanalytics method used",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "comboIds": [
      "DWFZONE",
      "SECTOR",
      "DMA"
    ],
    "comboNames": [
      "Drainage area (DRAINZONE + DWFZONE)",
      "SECTOR",
      "DMA"
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
    "widgetname": "forceOpen",
    "label": "Force open arcs: (*)",
    "widgettype": "linetext",
    "datatype": "text",
    "isMandatory": false,
    "tooltip": "Optative arc id(s) to temporary open closed arc(s) in order to force algorithm to continue there",
    "placeholder": "1015,2231,3123",
    "layoutname": "grl_option_parameters",
    "layoutorder": 5,
    "value": null
  },
  {
    "widgetname": "forceClosed",
    "label": "Force closed arcs: (*)",
    "widgettype": "text",
    "datatype": "text",
    "isMandatory": false,
    "tooltip": "Optative arc id(s) to temporary close open arc(s) to force algorithm to stop there",
    "placeholder": "1015,2231,3123",
    "layoutname": "grl_option_parameters",
    "layoutorder": 6,
    "value": null
  },
  {
    "widgetname": "usePlanPsector",
    "label": "Use selected psectors:",
    "widgettype": "check",
    "datatype": "boolean",
    "tooltip": "If true, use selected psectors. If false ignore selected psectors and only works with on-service network",
    "layoutname": "grl_option_parameters",
    "layoutorder": 7,
    "value": null
  },
  {
    "widgetname": "commitChanges",
    "label": "Commit changes:",
    "widgettype": "check",
    "datatype": "boolean",
    "tooltip": "If true, changes will be applied to DB. If false, algorithm results will be saved in anl tables",
    "layoutname": "grl_option_parameters",
    "layoutorder": 8,
    "value": null
  },
  {
    "widgetname": "updateMapZone",
    "label": "Mapzone constructor method:",
    "widgettype": "combo",
    "datatype": "integer",
    "layoutname": "grl_option_parameters",
    "layoutorder": 10,
    "comboIds": [
      0,
      1,
      2,
      6
    ],
    "comboNames": [
      "NONE",
      "CONCAVE POLYGON",
      "PIPE BUFFER",
      "EPA SUBCATCH"
    ],
    "selectedId": null
  },
  {
    "widgetname": "geomParamUpdate",
    "label": "Pipe buffer",
    "widgettype": "text",
    "datatype": "float",
    "tooltip": "Buffer from arcs to create mapzone geometry using [PIPE BUFFER] options. Normal values maybe between 3-20 mts.",
    "layoutname": "grl_option_parameters",
    "layoutorder": 11,
    "isMandatory": false,
    "placeholder": "5-30",
    "value": null
  }
]'::json WHERE id=2768;

INSERT INTO config_toolbox (id, alias, functionparams, inputparams, observ, active, device) VALUES(3482, 'Macromapzones analysis', '{"featureType":[]}'::json, '[
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
    "tooltip": "If true, changes will be applied to DB. If false, algorithm results will be saved in anl tables",
    "layoutname": "grl_option_parameters",
    "layoutorder": 8,
    "value": null
  }
]'::json, NULL, true, '{4}');

INSERT INTO inp_typevalue (typevalue, id, idval, descript, addparam) VALUES('inp_typevalue_inlet_type', 'GULLY', 'GULLY', NULL, NULL);
INSERT INTO inp_typevalue (typevalue, id, idval, descript, addparam) VALUES('_inp_typevalue_inlet_type', 'CULVERT', 'CULVERT', NULL, NULL);
INSERT INTO inp_typevalue (typevalue, id, idval, descript, addparam) VALUES('inp_typevalue_dscenario', 'INLET', 'INLET', NULL, NULL);
INSERT INTO sys_feature_epa_type (id,feature_type,epa_table,active)	VALUES ('INLET','NODE','inp_inlet',true);

INSERT INTO config_form_tabs (formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device) VALUES('ve_epa_inlet', 'tab_epa', 'EPA', NULL, 'role_basic', NULL, '[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionOrifice","actionTooltip": "Orifice","disabled": false},{"actionName": "actionOutlet","actionTooltip": "Outlet","disabled": false},{"actionName": "actionPump","actionTooltip": "Pump","disabled": false},{"actionName": "actionWeir","actionTooltip": "Weir","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json, 1, '{4}');

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'y0', 'lyt_epa_data_1', 1, 'numeric', 'text', 'y0:', 'y0', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL,
'{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'ysur', 'lyt_epa_data_1', 2, 'numeric', 'text', 'ysur:', 'ysur', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL,
NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'apond', 'lyt_epa_data_1', 3, 'numeric', 'text', 'apond:', 'apond', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL,
NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'inlet_type', 'lyt_epa_data_1', 4, 'string', 'combo', 'inlet_type:', 'inlet_type', NULL, false, false, true, false, false,
'SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_inlet_type''', NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'outlet_type', 'lyt_epa_data_1', 5, 'string', 'combo', 'outlet_type:', 'outlet_type', NULL, false, false, true, false, false,
'SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_gully_type''', NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'gully_method', 'lyt_epa_data_1', 6, 'string', 'combo', 'gully_method:', 'gully_method', NULL, false, false, true, false, false,
'SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_gully_method''', NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'custom_top_elev', 'lyt_epa_data_1', 7, 'double', 'text', 'custom_top_elev:', 'custom_top_elev', NULL, false, false, true, false,
false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'custom_depth', 'lyt_epa_data_1', 8, 'double', 'text', 'custom_depth:', 'custom_depth', NULL, false, false, true, false, false, NULL,
NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'inlet_length', 'lyt_epa_data_1', 9, 'double', 'text', 'inlet_length:', 'inlet_length', NULL, false, false, true, false, false, NULL,
NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'inlet_width', 'lyt_epa_data_1', 10, 'double', 'text', 'inlet_width:', 'inlet_width', NULL, false, false, true, false, false, NULL, NULL,
NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'cd1', 'lyt_epa_data_1', 11, 'double', 'text', 'cd1:', 'cd1', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL,
NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'cd2', 'lyt_epa_data_1', 12, 'double', 'text', 'cd2:', 'cd2', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL,
NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'efficiency', 'lyt_epa_data_1', 13, 'double', 'text', 'efficiency:', 'efficiency', NULL, false, false, true, false, false, NULL, NULL,
NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'depth_average', 'lyt_epa_data_2', 1, 'string', 'text', 'Average depth:', 'Average depth', NULL, false, false, false, false, false,
NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'depth_max', 'lyt_epa_data_2', 2, 'string', 'text', 'Max depth:', 'Max depth', NULL, false, false, false, false, false, NULL, NULL,
NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'depth_max_day', 'lyt_epa_data_2', 3, 'string', 'text', 'Max depth/day:', 'Max depth per day', NULL, false, false, false, false, false,
NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'depth_max_hour', 'lyt_epa_data_2', 4, 'string', 'text', 'Max depth/hour:', 'Max depth per hour', NULL, false, false, false, false,
false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'flood_hour', 'lyt_epa_data_2', 7, 'string', 'text', 'Flood hour:', 'Flood hour', NULL, false, false, false, false, false, NULL, NULL,
NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'flood_max_ponded', 'lyt_epa_data_2', 12, 'string', 'text', 'Max ponded flood :', 'Max ponded flood', NULL, false, false, false,
false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'flood_max_rate', 'lyt_epa_data_2', 8, 'string', 'text', 'Maximum food rate:', 'Maximum food rate', NULL, false, false, false,
false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'flood_total', 'lyt_epa_data_2', 11, 'string', 'text', 'Total flood:', 'Total flood', NULL, false, false, false, false, false, NULL,
NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'surcharge_hour', 'lyt_epa_data_2', 5, 'string', 'text', 'Surcharge/hour:', 'Surcharge per hour', NULL, false, false, false, false,
false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'surgarge_max_height', 'lyt_epa_data_2', 6, 'string', 'text', 'max height of surgarge:', 'Max height of surgarge', NULL, false, false,
false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'time_day', 'lyt_epa_data_2', 9, 'string', 'text', 'Day:', 'Day', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL,
NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent,
iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject,
hidden, web_layoutorder)
VALUES('ve_epa_inlet', 'form_feature', 'tab_epa', 'time_hour', 'lyt_epa_data_2', 10, 'string', 'text', 'Hour:', 'Hour', NULL, false, false, false, false, false, NULL, NULL, NULL, NULL,
NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_none', 'dscenario_id', 'lyt_epa_data_1', 1, 'integer', 'combo', 'Dscenario ID', 'Dscenario ID', NULL, true, false, true, false, false, 'SELECT dscenario_id as id, name as idval FROM cat_dscenario WHERE dscenario_id IS NOT NULL', true, false, NULL, NULL, NULL, '{"valueRelation":{"nullValue":false, "layer": "v_edit_cat_dscenario", "activated": true, "keyColumn": "dscenario_id", "valueColumn": "name", "filterExpression": null}}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'y0', 'lyt_epa_data_1', 3, 'numeric', 'text', 'y0:', 'y0', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'ysur', 'lyt_epa_data_1', 4, 'numeric', 'text', 'ysur:', 'ysur', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'apond', 'lyt_epa_data_1', 5, 'numeric', 'text', 'apond:', 'apond', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'inlet_type', 'lyt_epa_data_1', 6, 'string', 'combo', 'inlet_type:', 'inlet_type', NULL, false, false, true, false, false, 'SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_inlet_type''', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'outlet_type', 'lyt_epa_data_1', 7, 'string', 'combo', 'outlet_type:', 'outlet_type', NULL, false, false, true, false, false, 'SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_gully_type''', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'gully_method', 'lyt_epa_data_1', 8, 'string', 'combo', 'gully_method:', 'gully_method', NULL, false, false, true, false, false, 'SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_gully_method''', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'custom_top_elev', 'lyt_epa_data_1', 9, 'double', 'text', 'custom_top_elev:', 'custom_top_elev', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'custom_depth', 'lyt_epa_data_1', 10, 'double', 'text', 'custom_depth:', 'custom_depth', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'inlet_length', 'lyt_epa_data_1', 11, 'double', 'text', 'inlet_length:', 'inlet_length', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'inlet_width', 'lyt_epa_data_1', 12, 'double', 'text', 'inlet_width:', 'inlet_width', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'cd1', 'lyt_epa_data_1', 13, 'double', 'text', 'cd1:', 'cd1', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'cd2', 'lyt_epa_data_1', 14, 'double', 'text', 'cd2:', 'cd2', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_epa', 'efficiency', 'lyt_epa_data_1', 15, 'double', 'text', 'efficiency:', 'efficiency', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('inp_dscenario_inlet', 'form_feature', 'tab_none', 'node_id', NULL, 2, 'string', 'text', 'Node id:', 'Node id:', NULL, true, false, false, false, false, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);


UPDATE config_form_fields SET iseditable=false WHERE formname='v_edit_drainzone' AND formtype='form_feature' AND columnname='graphconfig' AND tabname='tab_none';
UPDATE config_form_fields SET iseditable=false WHERE formname='v_ui_drainzone' AND formtype='form_feature' AND columnname='graphconfig' AND tabname='tab_none';

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,hidden)
	VALUES ('v_ui_dwfzone','form_feature','tab_none','drainzone_id','lyt_data_1',11,'text','combo','drainzone_id','drainzone_id',false,false,true,false,false,'SELECT drainzone_id id, name idval FROM ve_drainzone','{"setMultiline":false}'::json,false);


-- UPDATE config_form_fields SET layoutname = 'lyt_bot_1' WHERE formtype='form_feature' AND tab_name='tab_data' AND columnname in ('sector_id', 'omzone_id', 'state_type', 'state');
-- formname = 've_node_highpoint' and (columnname ilike 'omzone%' or columnname ilike 'sector_id%' or columnname ilike 'state%')

-- UPDATE config_form_fields SET layoutorder = 44, widgetcontrols = '{"setMultiline":false}'::json WHERE formname = 've_node_highpoint' AND columnname = 'verified' AND tab_name = 'tab_data' AND formtype = 'form_feature';


INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES
    (3410, 'gw_trg_array_fk_array_table', 'utils', 'function', NULL, NULL, NULL, NULL, NULL, 'core', NULL),
    (3412, 'gw_trg_array_fk_id_table', 'utils', 'function', NULL, NULL, NULL, NULL, NULL, 'core', NULL)
ON CONFLICT (id) DO UPDATE SET project_type = 'utils';

INSERT INTO dma (dma_id, name) VALUES (0, 'UNDEFINED');


UPDATE sys_foreignkey SET target_field='gully_method'
WHERE typevalue_table='inp_typevalue' AND typevalue_name='inp_typevalue_gully_method' AND target_table='inp_gully' AND target_field='method';
UPDATE sys_foreignkey SET target_field='gully_method'
WHERE typevalue_table='inp_typevalue' AND typevalue_name='inp_typevalue_gully_method' AND target_table='inp_netgully' AND target_field='method';

UPDATE sys_param_user SET layoutorder = 25 WHERE id = 'utils_psector_strategy';

UPDATE config_form_fields SET formname='v_edit_inp_gully', formtype='form_feature', columnname='gully_method', tabname='tab_data' WHERE formname='v_edit_inp_gully' AND formtype='form_feature' AND columnname='gully_method' AND tabname='tab_data';
UPDATE config_form_fields SET formname='v_edit_inp_netgully', formtype='form_feature', columnname='gully_method', tabname='tab_data' WHERE formname='v_edit_inp_netgully' AND formtype='form_feature' AND columnname='gully_method' AND tabname='tab_data';
UPDATE config_form_fields SET formname='ve_epa_gully', formtype='form_feature', columnname='gully_method', tabname='tab_epa' WHERE formname='ve_epa_gully' AND formtype='form_feature' AND columnname='gully_method' AND tabname='tab_epa';
UPDATE config_form_fields SET formname='ve_epa_netgully', formtype='form_feature', columnname='gully_method', tabname='tab_epa' WHERE formname='ve_epa_netgully' AND formtype='form_feature' AND columnname='gully_method' AND tabname='tab_epa';

UPDATE sys_message SET error_message = 'The table chosen does not fit with any epa dscenario. Please try another one.' WHERE id = 3698;

INSERT INTO sys_feature_epa_type (id, feature_type, epa_table, descript, active) VALUES('PGULLY', 'GULLY', 'inp_gully', NULL, true);

UPDATE inp_typevalue SET typevalue='_inp_typevalue_gully_method' WHERE typevalue='inp_typevalue_gully_method' AND id='UPC';
UPDATE inp_typevalue SET typevalue='_inp_typevalue_gully_type' WHERE typevalue='inp_typevalue_gully_type' AND id='Sink';

UPDATE config_param_system SET value='{"sys_display_name":"concat(gully_id, '' : '', gullycat_id)","sys_tablename":"v_edit_gully","sys_pk":"gully_id","sys_fct":"gw_fct_getinfofromid","sys_filter":"","sys_geom":"the_geom"}' WHERE "parameter"='basic_search_v2_tab_network_gully';
UPDATE config_param_system SET value='{"sys_display_name":"concat(connec_id, '' : '', conneccat_id)","sys_tablename":"v_edit_connec","sys_pk":"connec_id","sys_fct":"gw_fct_getinfofromid","sys_filter":"","sys_geom":"the_geom"}' WHERE "parameter"='basic_search_v2_tab_network_connec';


INSERT INTO config_form_tabs (formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device) VALUES('v_edit_raingage', 'tab_data', 'Data', 'Data', 'role_edit', NULL, '[
  {
    "actionName": "actionEdit",
    "disabled": false
  },
  {
    "actionName": "actionZoom",
    "disabled": false
  },
  {
    "actionName": "actionCentered",
    "disabled": false
  },
  {
    "actionName": "actionZoomOut",
    "disabled": false
  },
  {
    "actionName": "actionHelp",
    "disabled": false
  }
]'::json, 0, '{4,5}');

UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='rg_id' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='form_type' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='intvl' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='scf' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='rgage_type' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='timser_id' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='fname' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='sta' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='units' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='muni_id' AND tabname='tab_none';
UPDATE config_form_fields SET tabname='tab_data' WHERE formname='v_edit_raingage' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_none';

UPDATE config_info_layer SET formtemplate='info_feature' WHERE layer_id='v_edit_raingage';

INSERT INTO sys_function (id,function_name,project_type,function_type,return_type,descript,"source")
VALUES (3494,'gw_fct_pg2iber_pgully','ud','function','json','Function to get GeoJson from v_edit_inp_pgully','core');

INSERT INTO config_form_tabs (formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device) VALUES('ve_epa_pgully', 'tab_epa', 'EPA', NULL, 'role_basic', NULL, '[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionOrifice","actionTooltip": "Orifice","disabled": false},{"actionName": "actionOutlet","actionTooltip": "Outlet","disabled": false},{"actionName": "actionPump","actionTooltip": "Pump","disabled": false},{"actionName": "actionWeir","actionTooltip": "Weir","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json, 1, '{4}');

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','custom_top_elev','lyt_epa_data_1',3,'double','text','custom_top_elev','custom_top_elev',false,false,true,true,'{"autoupdateReloadFields":["sys_top_elev", "sys_ymax", "sys_elev"]}'::json,false,10);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_isnullvalue,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','custom_width','lyt_epa_data_1',5,'string','text','Custom width','Custom width',false,false,true,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_isnullvalue,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','custom_depth','lyt_epa_data_1',7,'string','text','Custom depth','Custom depth',false,false,true,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_isnullvalue,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','method','lyt_epa_data_1',8,'string','combo','Method','Method',false,false,true,false,'SELECT id, idval FROM inp_typevalue WHERE id IS NOT NULL AND typevalue = ''inp_typevalue_gully_method''',true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_isnullvalue,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','weir_cd','lyt_epa_data_1',9,'numeric','text','Weir cd','Weir cd',false,false,true,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_isnullvalue,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','orifice_cd','lyt_epa_data_1',10,'numeric','text','Orifice cd','Orifice cd',false,false,true,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','custom_a_param','lyt_epa_data_1',11,'double','text','Custom a parameter','Custom a parameter',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','custom_b_param','lyt_epa_data_1',12,'double','text','Custom b parameter','Custom b parameter',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','efficiency','lyt_epa_data_1',13,'double','text','Efficiency','Efficiency',false,false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_isnullvalue,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','outlet_type','lyt_epa_data_1',2,'string','combo','Outlet type','Outlet type',false,false,true,false,'SELECT id, idval FROM inp_typevalue WHERE id IS NOT NULL AND typevalue = ''inp_typevalue_gully_type''',true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_epa_pgully','form_feature','tab_epa','custom_length','lyt_epa_data_1',6,'double','text','Custom length:','Custom length:',false,false,true,false,false,true);

UPDATE config_form_list
SET query_text='SELECT dscenario_id, node_id, elev, ymax, storage_type, curve_id, a1, a2, a0, fevap, sh, hc, imd, y0, ysur FROM ve_inp_dscenario_storage WHERE node_id IS NOT NULL'
WHERE listname='tbl_inp_storage' AND device=4;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3492, 'gw_fct_graphanalytics_omunit', 'ud', 'function', 'json', 'json', 'Dynamic analisys to sectorize network using the flow traceability function and establish omunits.', 'role_plan', NULL, 'core', 'OMUNIT DYNAMIC SECTORITZATION');
INSERT INTO config_toolbox (id, alias, functionparams, inputparams, observ, active, device) VALUES(3492, 'Omunit analysis', '{"featureType":[]}'::json, '[{"widgetname": "exploitation", "label": "Exploitation:", "widgettype": "combo", "datatype": "text", "tooltip": "Choose exploitation to work with", "layoutname": "grl_option_parameters", "layoutorder": 2, "dvQueryText": "SELECT id, idval FROM ( SELECT -901 AS id, ''User selected expl'' AS idval, ''a'' AS sort_order UNION SELECT -902 AS id, ''All exploitations'' AS idval, ''b'' AS sort_order UNION SELECT expl_id AS id, name AS idval, ''c'' AS sort_order FROM exploitation WHERE active IS NOT FALSE ) a ORDER BY sort_order ASC, idval ASC", "selectedId": ""}, {"widgetname": "usePlanPsector", "label": "Use masterplan psectors:", "widgettype": "check", "datatype": "boolean", "layoutname": "grl_option_parameters", "layoutorder": 6, "value": ""}, {"widgetname": "commitChanges", "label": "Commit changes:", "widgettype": "check", "datatype": "boolean", "layoutname": "grl_option_parameters", "layoutorder": 7, "value": ""}, {"widgetname": "updateMapZone", "label": "Update mapzone geometry method:", "widgettype": "combo", "datatype": "integer", "layoutname": "grl_option_parameters", "layoutorder": 8, "comboIds": [0, 1, 2, 3], "comboNames": ["NONE", "CONCAVE POLYGON", "PIPE BUFFER", "PLOT & PIPE BUFFER"], "selectedId": ""}, {"widgetname": "geomParamUpdate", "label": "Geometry parameter:", "widgettype": "text", "datatype": "float", "layoutname": "grl_option_parameters", "layoutorder": 10, "isMandatory": false, "placeholder": "5-30", "value": ""}]'::json, NULL, true, '{4}');


INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('arc', 'form_feature', 'tab_data', 'initoverflowpath', 'lyt_data_1',
(SELECT max(layoutorder) + 1 FROM config_form_fields WHERE formname  = 'arc' AND tabname = 'tab_data' AND layoutname = 'lyt_data_1' GROUP BY formname, tabname, layoutname),
'boolean', 'check', 'Init Over Flow Path', 'initoverflowpath', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, TRUE, NULL)
ON CONFLICT DO NOTHING;

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_arc', 'form_feature', 'tab_data', 'initoverflowpath', 'lyt_data_1',
(SELECT max(layoutorder) + 1 FROM config_form_fields WHERE formname  = 've_arc' AND tabname = 'tab_data' AND layoutname = 'lyt_data_1' GROUP BY formname, tabname, layoutname),
'boolean', 'check', 'Init Over Flow Path', 'initoverflowpath', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, TRUE, NULL)
ON CONFLICT DO NOTHING;

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('v_edit_arc', 'form_feature', 'tab_data', 'initoverflowpath', 'lyt_data_1',
(SELECT max(layoutorder) + 1 FROM config_form_fields WHERE formname  = 'v_edit_arc' AND tabname = 'tab_data' AND layoutname = 'lyt_data_1' GROUP BY formname, tabname, layoutname),
'boolean', 'check', 'Init Over Flow Path', 'initoverflowpath', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, TRUE, NULL)
ON CONFLICT DO NOTHING;


DELETE FROM config_form_fields  WHERE formname = 've_arc';
DELETE FROM config_form_fields  WHERE formname = 've_connec';
DELETE FROM config_form_fields  WHERE formname = 've_node';
DELETE FROM config_form_fields  WHERE formname = 've_gully';
ALTER TABLE config_form_fields DISABLE TRIGGER USER;
UPDATE config_form_fields SET formname = REPLACE(formname, 'v_edit_', 've_') WHERE formname LIKE 'v_edit_%';
ALTER TABLE config_form_fields ENABLE TRIGGER USER;


UPDATE sys_param_user SET formname = 'hidden' WHERE id = 'inp_options_networkmode';


UPDATE config_form_fields SET columnname='gully_method' WHERE formname='ve_epa_pgully' AND formtype='form_feature' AND columnname='method' AND tabname='tab_epa';
UPDATE config_form_fields SET columnname='gully_method' WHERE formname='ve_epa_gully' AND formtype='form_feature' AND columnname='method' AND tabname='tab_epa';
UPDATE config_form_fields SET columnname='gully_method' WHERE formname='ve_epa_netgully' AND formtype='form_feature' AND columnname='method' AND tabname='tab_epa';

-- Tabactions
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json WHERE formname='ve_epa_inlet' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json WHERE formname='ve_epa_pgully' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json WHERE formname='ve_epa_junction' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false}]'::json WHERE formname='ve_epa_storage' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_documents';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_features';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false},{"actionName": "actionSetToArc","disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_data';

-- Correct expl_id
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_genelem_ehydrant_plate' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_genelem_emanhole' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_genelem_eprotect_band' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_genelem_eregister' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_genelem_ecover' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"setMultiline": false}'::json
	WHERE formname='ve_genelem_estep' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';

-- Order epump
UPDATE config_form_fields
	SET layoutorder=4,layoutname='lyt_data_2'
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='order_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET layoutorder=3,layoutname='lyt_data_2'
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='flwreg_length' AND tabname='tab_data';
UPDATE config_form_fields
	SET layoutorder=2,layoutname='lyt_data_2'
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';
UPDATE config_form_fields
	SET layoutorder=5
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';



-- Correct sourcetable
UPDATE config_form_fields
	SET widgetfunction='{
  "functionName": "manage_element_menu",
  "parameters": {
    "sourcetable": "v_ui_element_x_node",
    "targetwidget": "tab_elements_tbl_elements",
    "field_object_id": "element_id",
    "sourceview": "element",
    "linked_feature": true
  }
}'::json
	WHERE formname='node' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';
UPDATE config_form_fields
	SET widgetfunction='{
  "functionName": "manage_element_menu",
  "parameters": {
    "sourcetable": "v_ui_element_x_connec",
    "targetwidget": "tab_elements_tbl_elements",
    "field_object_id": "element_id",
    "sourceview": "element",
    "linked_feature": true
  }
}'::json
	WHERE formname='connec' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';
UPDATE config_form_fields
	SET widgetfunction='{
  "functionName": "manage_element_menu",
  "parameters": {
    "sourcetable": "v_ui_element_x_gully",
    "targetwidget": "tab_elements_tbl_elements",
    "field_object_id": "element_id",
    "sourceview": "element",
    "linked_feature": true
  }
}'::json
	WHERE formname='gully' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';
UPDATE config_form_fields
	SET widgetfunction='{
  "functionName": "manage_element_menu",
  "parameters": {
    "sourcetable": "v_ui_element_x_link",
    "targetwidget": "tab_elements_tbl_elements",
    "field_object_id": "element_id",
    "sourceview": "element",
    "linked_feature": true
  }
}'::json
	WHERE formname='ve_link' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';
UPDATE config_form_fields
	SET widgetfunction='{
  "functionName": "manage_element_menu",
  "parameters": {
    "sourcetable": "v_ui_element_x_link",
    "targetwidget": "tab_elements_tbl_elements",
    "field_object_id": "element_id",
    "sourceview": "element",
    "linked_feature": true
  }
}'::json
	WHERE formname='ve_link_conduitlink' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';
UPDATE config_form_fields
	SET widgetfunction='{
  "functionName": "manage_element_menu",
  "parameters": {
    "sourcetable": "v_ui_element_x_link",
    "targetwidget": "tab_elements_tbl_elements",
    "field_object_id": "element_id",
    "sourceview": "element",
    "linked_feature": true
  }
}'::json
	WHERE formname='ve_link_link' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';
UPDATE config_form_fields
	SET widgetfunction='{
  "functionName": "manage_element_menu",
  "parameters": {
    "sourcetable": "v_ui_element_x_link",
    "targetwidget": "tab_elements_tbl_elements",
    "field_object_id": "element_id",
    "sourceview": "element",
    "linked_feature": true
  }
}'::json
	WHERE formname='ve_link_vlink' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';


DELETE FROM config_form_fields WHERE (formname ILIKE '%frelem%' OR formname ILIKE '%genelem%') AND tabname = 'tab_none';
DELETE FROM config_form_fields WHERE formname ILIKE '%frelem%' AND columnname = 'nodarc_id';

-- setToArc action
UPDATE config_form_tabs
	SET tabactions='[
  {
    "actionName": "actionEdit",
    "disabled": false
  },
  {
    "actionName": "actionSetToArc",
    "disabled": false
  }
]'::json
	WHERE formname='ve_frelem' AND tabname='tab_data';


INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('v_ui_dwfzone', 'form_feature', 'tab_none', 'sector_id', 'lyt_data_1', 11, 'text', 'text', 'sector_id', 'sector_id', 'Ex: 1,2', false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('v_ui_dwfzone', 'form_feature', 'tab_none', 'muni_id', 'lyt_data_1', 12, 'text', 'text', 'muni_id', 'muni_id', 'Ex: 1,2', false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL);

UPDATE config_form_fields SET layoutorder=13 WHERE formname = 'v_ui_dwfzone' AND formtype = 'form_feature' AND columnname = 'drainzone_id' AND tabname = 'tab_none';

-- new layouts
INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_element_dscenario_1', 'lyt_element_dscenario_3', 'layoutElemDscenario1', '{"lytOrientation": "horizontal"}'::json);

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_element_dscenario_2', 'lyt_element_dscenario_3', 'layoutElemDscenario2', '{"lytOrientation": "vertical"}'::json);

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_element_dscenario_3', 'lyt_element_dscenario_3', 'layoutElemDscenario3', '{"lytOrientation": "horizontal"}'::json);

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_elem_dsc_orifice', 'lyt_elem_dsc_orifice', 'layoutElemDscOrifice', '{"lytOrientation": "vertical"}'::json);

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_elem_dsc_outlet', 'lyt_elem_dsc_outlet', 'layoutElemDscOutlet', '{"lytOrientation": "vertical"}'::json);

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_elem_dsc_pump', 'lyt_elem_dsc_pump', 'layoutElemDscPump', '{"lytOrientation": "vertical"}'::json);

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_elem_dsc_weir', 'lyt_elem_dsc_weir', 'layoutElemDscWeir', '{"lytOrientation": "vertical"}'::json);

-- buttons
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'insert_frelem_dscenario', 'lyt_element_dscenario_1', 1, NULL, 'button', NULL, 'Insert frelem into dscenario', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon":"113"}'::json, '{
  "saveValue": false,
  "filterSign": "=",
  "onContextMenu": "Insert into dscenario"
}'::json, '{
  "functionName": "add_frelem_to_dscenario",
  "module": "info",
  "parameters": {
    "columnfind": "element_id",
    "sourcewidget": "tab_elements_tbl_elements"
  }
}'::json, NULL, false, NULL);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'delete_from_dscenario', 'lyt_element_dscenario_1', 2, NULL, 'button', NULL, 'Remove frelem from dscenario', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon":"114"}'::json, '{
  "saveValue": false,
  "filterSign": "=",
  "onContextMenu": "Remove from dscenario"
}'::json, '{
  "functionName": "remove_frelem_from_dscenario",
  "module": "info",
  "parameters": {
    "columnfind": ["element_id", "dscenario_id", "node_id"]
  }
}'::json, NULL, false, NULL);
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'hspacer_lyt_dsc_1', 'lyt_element_dscenario_1', 10, NULL, 'hspacer', NULL, NULL, NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

-- frelem dscenario tableviews
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'tbl_frelem_dsc_orifice', 'lyt_elem_dsc_orifice', 1, NULL, 'tableview', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"saveValue": false}'::json, NULL, 'tbl_frelem_dsc_orifice', false, NULL);

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'tbl_frelem_dsc_outlet', 'lyt_elem_dsc_outlet', 1, NULL, 'tableview', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"saveValue": false}'::json, NULL, 'tbl_frelem_dsc_outlet', false, NULL);

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'tbl_frelem_dsc_pump', 'lyt_elem_dsc_pump', 1, NULL, 'tableview', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"saveValue": false}'::json, NULL, 'tbl_frelem_dsc_pump', false, NULL);

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'tbl_frelem_dsc_weir', 'lyt_elem_dsc_weir', 1, NULL, 'tableview', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"saveValue": false}'::json, NULL, 'tbl_frelem_dsc_weir', false, NULL);


-- tables
INSERT INTO config_form_list
(listname, query_text, device, listtype, listclass, vdefault, addparam)
VALUES('tbl_frelem_dsc_orifice', 'SELECT * FROM ve_inp_dscenario_frorifice WHERE element_id IS NOT NULL', 4, 'tab', 'list', NULL, NULL);

INSERT INTO config_form_list
(listname, query_text, device, listtype, listclass, vdefault, addparam)
VALUES('tbl_frelem_dsc_outlet', 'SELECT * FROM ve_inp_dscenario_froutlet WHERE element_id IS NOT NULL', 4, 'tab', 'list', NULL, NULL);

INSERT INTO config_form_list
(listname, query_text, device, listtype, listclass, vdefault, addparam)
VALUES('tbl_frelem_dsc_pump', 'SELECT * FROM ve_inp_dscenario_frpump WHERE element_id IS NOT NULL', 4, 'tab', 'list', NULL, NULL);

INSERT INTO config_form_list
(listname, query_text, device, listtype, listclass, vdefault, addparam)
VALUES('tbl_frelem_dsc_weir', 'SELECT * FROM ve_inp_dscenario_frweir WHERE element_id IS NOT NULL', 4, 'tab', 'list', NULL, NULL);


-- config_from_tableview
INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'dscenario_id', 1, true, NULL, 'Dscenario id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'element_id', 2, true, NULL, 'Element id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'node_id', 3, true, NULL, 'Node id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'orifice_type', 4, true, NULL, 'Orifice type', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'offsetval', 5, true, NULL, 'Offsetval', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'cd', 6, true, NULL, 'Cd', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'orate', 7, true, NULL, 'Orate', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'flap', 8, true, NULL, 'Flap', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'shape', 9, true, NULL, 'Shape', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'geom1', 10, true, NULL, 'Geom1', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'geom2', 11, true, NULL, 'Geom2', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'geom3', 12, true, NULL, 'Geom3', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'geom4', 13, true, NULL, 'Geom4', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_orifice', 'the_geom', 17, false, NULL, 'the_geom', NULL, NULL);

INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'dscenario_id', 1, true, NULL, 'Dscenario id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'element_id', 2, true, NULL, 'Element id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'node_id', 3, true, NULL, 'Node id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'outlet_type', 4, true, NULL, 'Outlet type', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'offsetval', 5, true, NULL, 'Offsetval', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'curve_id', 6, true, NULL, 'Curve id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'cd1', 7, true, NULL, 'Cd1', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'cd2', 8, true, NULL, 'Cd2', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'flap', 9, true, NULL, 'Flap', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_outlet', 'the_geom', 17, false, NULL, 'the_geom', NULL, NULL);

INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'dscenario_id', 1, true, NULL, 'Dscenario id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'element_id', 2, true, NULL, 'Element id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'node_id', 3, true, NULL, 'Node id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'curve_id', 4, true, NULL, 'Curve id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'status', 5, true, NULL, 'Status', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'startup', 6, true, NULL, 'Startup', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'shutoff', 7, true, NULL, 'Shutoff', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_pump', 'the_geom', 17, false, NULL, 'the_geom', NULL, NULL);

-- config_from_tableview
INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'dscenario_id', 1, true, NULL, 'Dscenario id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'element_id', 2, true, NULL, 'Element id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'node_id', 3, true, NULL, 'Node id', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'weir_type', 4, true, NULL, 'Weir type', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'offsetval', 5, true, NULL, 'Offsetval', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'cd', 6, true, NULL, 'Cd', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'ec', 7, true, NULL, 'Ec', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'cd2', 8, true, NULL, 'Cd2', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'flap', 9, true, NULL, 'Flap', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'geom1', 10, true, NULL, 'Geom1', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'geom2', 11, true, NULL, 'Geom2', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'geom3', 12, true, NULL, 'Geom3', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'geom4', 13, true, NULL, 'Geom4', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'surcharge', 14, true, NULL, 'Surcharge', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'road_width', 15, true, NULL, 'Road width', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'road_surf', 16, true, NULL, 'Road surf', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'coef_curve', 17, true, NULL, 'Coef curve', NULL, NULL),
('feature form', 'ud', 'tbl_frelem_dsc_weir', 'the_geom', 17, false, NULL, 'the_geom', NULL, NULL);



-- Add brand and model to ve_node, ve_arc, ve_connec, ve_element, ve_frelem, ve_genelem
  -- Existing ones
    -- Brand_id
UPDATE config_form_fields SET dv_querytext = NULL, label = 'Brand', isparent = false, isautoupdate = false, widgetcontrols = '{"setMultiline":false}'::json
WHERE columnname = 'brand_id' AND formtype = 'form_feature' AND tabname = 'tab_data';

DO $$
DECLARE
  v_dv_querytext text;
  v_layoutorder integer;
  rec record;
BEGIN
  FOR rec IN SELECT * FROM config_form_fields WHERE formtype='form_feature' AND columnname='brand_id' AND tabname='tab_data' AND formname ilike any(array['ve_node_%', 've_arc_%', 've_connec_%', 've_gully_%'])
  LOOP
    v_dv_querytext := format('SELECT id, id as idval FROM cat_brand WHERE %L = ANY(featurecat_id::text[])', upper(regexp_replace(rec.formname, '^ve_(node|arc|connec|gully)_', '', 'i')));
    v_layoutorder := (SELECT MAX(layoutorder) + 1 FROM config_form_fields WHERE formname = rec.formname AND formtype = rec.formtype AND tabname = rec.tabname AND layoutname = 'lyt_data_2');
	UPDATE config_form_fields SET dv_querytext = v_dv_querytext, widgettype = 'combo', layoutname = 'lyt_data_2', layoutorder = v_layoutorder WHERE formname = rec.formname AND formtype = rec.formtype AND columnname = rec.columnname AND tabname = rec.tabname;
  END LOOP;
END $$;

    -- Model_id
UPDATE config_form_fields SET dv_querytext = NULL, label = 'Model', isparent = false, isautoupdate = false, widgetcontrols = '{"setMultiline":false}'::json
WHERE columnname = 'model_id' AND formtype = 'form_feature' AND tabname = 'tab_data';

DO $$
DECLARE
  v_dv_querytext text;
  v_layoutorder integer;
  rec record;
BEGIN
  FOR rec IN SELECT * FROM config_form_fields WHERE formtype='form_feature' AND columnname='model_id' AND tabname='tab_data' AND formname ilike any(array['ve_node_%', 've_arc_%', 've_connec_%', 've_gully_%'])
  LOOP
    v_dv_querytext := format('SELECT id, id as idval FROM cat_brand_model WHERE %L = ANY(featurecat_id::text[])', upper(regexp_replace(rec.formname, '^ve_(node|arc|connec|gully)_', '', 'i')));
    v_layoutorder := (SELECT MAX(layoutorder) + 1 FROM config_form_fields WHERE formname = rec.formname AND formtype = rec.formtype AND tabname = rec.tabname AND layoutname = 'lyt_data_2');
	UPDATE config_form_fields SET dv_querytext = v_dv_querytext, widgettype = 'combo', layoutname = 'lyt_data_2', layoutorder = v_layoutorder WHERE formname = rec.formname AND formtype = rec.formtype AND columnname = rec.columnname AND tabname = rec.tabname;
  END LOOP;
END $$;

  -- New ones
    -- brand_id
DO $$
DECLARE
  v_dv_querytext text;
  v_layoutorder integer;
  rec record;
BEGIN
  FOR rec IN SELECT DISTINCT formname, formtype, tabname FROM config_form_fields cff WHERE formname ILIKE ANY (ARRAY['ve_node_%', 've_arc_%', 've_connec_%', 've_gully_%'])
      AND tabname = 'tab_data' AND formtype = 'form_feature' AND NOT EXISTS (SELECT 1 FROM config_form_fields cff2 WHERE cff2.formname = cff.formname AND cff2.formtype = cff.formtype
      AND cff2.tabname = cff.tabname AND cff2.columnname = 'brand_id')
  LOOP
    v_dv_querytext := format('SELECT id, id as idval FROM cat_brand WHERE %L = ANY(featurecat_id::text[])', upper(regexp_replace(rec.formname, '^ve_(node|arc|connec|gully)_', '', 'i')));
    v_layoutorder := (SELECT MAX(layoutorder) + 1 FROM config_form_fields WHERE formname = rec.formname AND formtype = rec.formtype AND tabname = rec.tabname AND layoutname = 'lyt_data_2');

    INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, label, tooltip, ismandatory, isparent, iseditable, isautoupdate, dv_querytext, hidden) VALUES
    (rec.formname, rec.formtype, rec.tabname, 'brand_id', 'lyt_data_2', v_layoutorder, 'text', 'combo', 'Brand id', 'brand_id', false, false, true, false, v_dv_querytext, false);
  END LOOP;
END $$;

    -- model_id
DO $$
DECLARE
  v_dv_querytext text;
  v_layoutorder integer;
  rec record;
BEGIN
  FOR rec IN SELECT DISTINCT formname, formtype, tabname FROM config_form_fields cff WHERE formname ILIKE ANY (ARRAY['ve_node_%', 've_arc_%', 've_connec_%', 've_gully_%'])
      AND tabname = 'tab_data' AND formtype = 'form_feature' AND NOT EXISTS (SELECT 1 FROM config_form_fields cff2 WHERE cff2.formname = cff.formname AND cff2.formtype = cff.formtype
      AND cff2.tabname = cff.tabname AND cff2.columnname = 'model_id')
  LOOP
    v_dv_querytext := format('SELECT id, id as idval FROM cat_brand_model WHERE %L = ANY(featurecat_id::text[])', upper(regexp_replace(rec.formname, '^ve_(node|arc|connec|gully)_', '', 'i')));
    v_layoutorder := (SELECT MAX(layoutorder) + 1 FROM config_form_fields WHERE formname = rec.formname AND formtype = rec.formtype AND tabname = rec.tabname AND layoutname = 'lyt_data_2');

    INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, label, tooltip, ismandatory, isparent, iseditable, isautoupdate, dv_querytext, hidden) VALUES
    (rec.formname, rec.formtype, rec.tabname, 'model_id', 'lyt_data_2', v_layoutorder, 'text', 'combo', 'Model id', 'model_id', false, false, true, false, v_dv_querytext, false);
  END LOOP;
END $$;

    -- ve_connec
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,dv_querytext,hidden)
	VALUES ('ve_connec','form_feature','tab_data','brand_id','lyt_data_2',23,'text','text','Brand','brand_id',false,true,NULL,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,dv_querytext,hidden)
	VALUES ('ve_connec','form_feature','tab_data','model_id','lyt_data_2',24,'text','text','Model','model_id',false,true,NULL,false);

    -- ve_gully
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,dv_querytext,hidden)
	VALUES ('ve_gully','form_feature','tab_data','brand_id','lyt_data_2',23,'text','text','Brand','brand_id',false,true,NULL,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,dv_querytext,hidden)
	VALUES ('ve_gully','form_feature','tab_data','model_id','lyt_data_2',24,'text','text','Model','model_id',false,true,NULL,false);

  -- Elements
    -- ve_frelem
      -- eorifice
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eorifice','form_feature','tab_data','brand_id','lyt_data_1',13,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EORIFICE'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eorifice','form_feature','tab_data','model_id','lyt_data_1',14,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EORIFICE'' = ANY(featurecat_id::text[])');

    -- eoutlet
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
    VALUES ('ve_frelem_eoutlet','form_feature','tab_data','brand_id','lyt_data_1',13,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EOUTLET'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eoutlet','form_feature','tab_data','model_id','lyt_data_1',14,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EOUTLET'' = ANY(featurecat_id::text[])');

    -- epump
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_epump','form_feature','tab_data','brand_id','lyt_data_1',13,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EPUMP'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_epump','form_feature','tab_data','model_id','lyt_data_1',14,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EPUMP'' = ANY(featurecat_id::text[])');

    -- eweir
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eweir','form_feature','tab_data','brand_id','lyt_data_1',13,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EWEIR'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eweir','form_feature','tab_data','model_id','lyt_data_1',14,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EWEIR'' = ANY(featurecat_id::text[])');

UPDATE config_form_fields SET layoutorder=15 WHERE formname ILIKE 've_frelem_%' AND formtype='form_feature' AND columnname='rotation' AND tabname='tab_data';
UPDATE config_form_fields SET layoutorder=16 WHERE formname ILIKE 've_frelem_%' AND formtype='form_feature' AND columnname='top_elev' AND tabname='tab_data';

    -- ve_genelem
      -- ecover
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_ecover','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''ECOVER'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_ecover','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''ECOVER'' = ANY(featurecat_id::text[])');

    -- egate
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
    VALUES ('ve_genelem_egate','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EGATE'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_egate','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EGATE'' = ANY(featurecat_id::text[])');

    -- eiot_sensor
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_eiot_sensor','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EIOT_SENSOR'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_eiot_sensor','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EIOT_SENSOR'' = ANY(featurecat_id::text[])');

    -- eprotector
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_eprotector','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EPROTECTOR'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_eprotector','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EPROTECTOR'' = ANY(featurecat_id::text[])');

    -- estep
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_estep','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''ESTEP'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_genelem_estep','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''ESTEP'' = ANY(featurecat_id::text[])');

UPDATE config_form_fields SET layoutorder=14 WHERE formname ILIKE 've_genelem_%' AND formtype='form_feature' AND columnname='rotation' AND tabname='tab_data';
UPDATE config_form_fields SET layoutorder=15 WHERE formname ILIKE 've_genelem_%' AND formtype='form_feature' AND columnname='top_elev' AND tabname='tab_data';

-- Generate base element
DELETE FROM config_form_fields WHERE formname = 've_element';

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','state','lyt_bot_1',2,'integer','combo','State','State',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','state_type','lyt_bot_1',3,'integer','combo','State Type','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','code','lyt_data_1',1,'string','text','Code','Code',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','num_elements','lyt_data_1',2,'integer','text','Number of Elements','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','comment','lyt_data_1',3,'string','text','Comments','Comments',false,false,true,false,'{"setMultiline":true}'::json,true);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','function_type','lyt_data_1',4,'string','combo','Function Type','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','category_type','lyt_data_1',5,'string','combo','Category Type','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','location_type','lyt_data_1',6,'string','combo','Location Type','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_element','form_feature','tab_data','workcat_id','lyt_data_1',7,'string','typeahead','Workcat ID','Workcat ID',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','workcat_id_end','lyt_data_1',8,'string','typeahead','Workcat ID End','Workcat ID End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','builtdate','lyt_data_1',9,'date','datetime','Built Date','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','enddate','lyt_data_1',10,'date','datetime','End Date','End Date',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','ownercat_id','lyt_data_1',11,'string','combo','Owner Catalog','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,hidden)
	VALUES ('ve_element','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''GENELEM'' = ANY(featurecat_id::text[])', false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,hidden)
	VALUES ('ve_element','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''GENELEM'' = ANY(featurecat_id::text[])',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','rotation','lyt_data_1',14,'double','text','Rotation','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','top_elev','lyt_data_1',15,'double','text','Top Elevation','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','expl_id','lyt_data_2',1,'integer','combo','Exploitation ID','Exploitation ID',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
	VALUES ('ve_element','form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality id:','muni_id - Identifier of the municipality',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','observ','lyt_data_3',2,'string','text','Observations','Observations',false,false,true,false,'{"setMultiline":true}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','elementcat_id','lyt_top_1',1,'string','combo','Element Catalog','Element Catalog',true,false,true,false,'SELECT id, id as idval FROM cat_element WHERE element_type = ''ECOVER''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_data','element_id','lyt_top_1',2,'string','text','Element ID','Element ID',false,false,false,false,'{"saveValue":false,"setMultiline": false, "labelPosition": "top"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_element','form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_element','form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
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
	VALUES ('ve_element','form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
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
	VALUES ('ve_element','form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
  "icon": "137"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "selection_init"
}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_element','form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
  "icon": "178"
}'::json,'{
  "saveValue": false
}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_element','form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_arc",
  "featureType": "arc"
}'::json,'tbl_element_x_arc',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_element','form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_connec",
  "featureType": "connec"
}'::json,'tbl_element_x_connec',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_element','form_feature','tab_features','tbl_element_x_gully','lyt_features_2_gully',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_gully",
  "featureType": "gully"
}'::json,'tbl_element_x_gully',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_element','form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_link",
  "featureType": "link"
}'::json,'tbl_element_x_link',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_element','form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_node",
  "featureType": "node"
}'::json,'tbl_element_x_node',false);


UPDATE config_form_fields SET widgetcontrols='{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "filterExpression": null}}'::json WHERE formname ILIKE '%ve_link%' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';

UPDATE config_form_fields SET "datatype"='string', widgettype='combo', ismandatory=true, iseditable=true, dv_querytext='SELECT id, idval FROM om_typevalue WHERE typevalue = ''fluid_type''', dv_isnullvalue=true WHERE formname ILIKE '%ve_link%' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';

DELETE FROM config_form_fields WHERE formname ILIKE '%ve_link%' AND formtype='form_feature' AND columnname='n_hydrometer' AND tabname='tab_none';

DELETE FROM config_form_fields WHERE formname ILIKE '%ve_gully%' AND formtype='form_feature' AND columnname IN ('connec_y1', 'connec_y2') AND tabname='tab_none';

UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'v_edit_', 've_')::json WHERE widgetcontrols::text ilike '%v_edit_%';

SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"plan_psector_x_connec", "column":"active", "dataType":"boolean"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"plan_psector_x_gully", "column":"active", "dataType":"boolean"}}$$);

update sys_param_user set dv_querytext= 'SELECT cat_link.id, cat_link.id AS idval FROM cat_link' where id ='edit_linkcat_vdefault';
delete from sys_param_user where id = 'edit_gully_linkcat_vdefault';
update sys_param_user set id = 'edit_gully_linkcat_vdefault' where id = 'edit_linkcat_vdefault';



DELETE FROM config_form_fields WHERE formname ILIKE '%elem%' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb WHERE id='cat_element';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb WHERE id='cat_feature_element';

-- Config_form_fields
DO $$
DECLARE
  rec record;
BEGIN
-- frelem
  FOR rec IN (SELECT * FROM config_form_fields WHERE formname ILIKE '%frelem_%')
  LOOP
    UPDATE config_form_fields SET formname = replace(rec.formname, 'frelem', 'element') WHERE formname = rec.formname AND formtype = rec.formtype AND tabname = rec.tabname AND columnname = rec.columnname;
  END LOOP;
  -- genelem
  FOR rec IN (SELECT * FROM config_form_fields WHERE formname ILIKE '%genelem_%')
  LOOP
    UPDATE config_form_fields SET formname = replace(rec.formname, 'genelem', 'element') WHERE formname = rec.formname AND formtype = rec.formtype AND tabname = rec.tabname AND columnname = rec.columnname;
  END LOOP;
END $$;

-- cat_feature
UPDATE cat_feature SET parent_layer = 've_element' WHERE feature_type = 'ELEMENT';
DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN (SELECT * FROM cat_feature WHERE feature_type = 'ELEMENT')
  LOOP
    UPDATE cat_feature SET child_layer = 've_element_' || lower(rec.id) WHERE id = rec.id;
  END LOOP;
END $$;

-- config_form_tabs
UPDATE config_form_tabs SET formname = 've_element' WHERE formname = 've_frelem' AND tabname = 'tab_documents';
DELETE FROM config_form_tabs WHERE (formname = 've_genelem' AND (tabname = 'tab_epa' OR tabname = 'tab_documents')) OR (formname = 've_frelem' AND (tabname = 'tab_documents' OR tabname = 'tab_features'));

DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN (SELECT * FROM config_form_tabs WHERE formname = 've_frelem')
  LOOP
    UPDATE config_form_tabs SET formname = replace(rec.formname, 'frelem', 'man_frelem') WHERE formname = rec.formname AND tabname = rec.tabname;
  END LOOP;
  FOR rec IN (SELECT * FROM config_form_tabs WHERE formname = 've_genelem')
  LOOP
    UPDATE config_form_tabs SET formname = replace(rec.formname, 'genelem', 'man_genelem') WHERE formname = rec.formname AND tabname = rec.tabname;
  END LOOP;
END $$;

UPDATE config_form_tabs
	SET tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json
	WHERE formname='ve_element' AND tabname='tab_documents';
UPDATE config_form_tabs
	SET tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json
	WHERE formname='ve_man_frelem' AND tabname='tab_epa';

-- Editable, datatype and mandatory fields for frelemnts
UPDATE config_form_fields
	SET ismandatory=true,iseditable=true
	WHERE formname='ve_element_epump' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';
UPDATE config_form_fields
	SET iseditable=true,"datatype"='integer'
	WHERE formname='ve_element_eorifice' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';
UPDATE config_form_fields
	SET iseditable=true,"datatype"='integer'
	WHERE formname='ve_element_eoutlet' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';
UPDATE config_form_fields
	SET iseditable=true,"datatype"='integer'
	WHERE formname='ve_element_eweir' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';

-- Update element_id in config_form_fields
UPDATE config_form_fields
	SET widgetfunction='{"functionName":"open_selected_manager_item", "parameters":{"columnfind":"element_id", "elem_manager": true, "sourcetable": "v_ui_element"}}'::json
	WHERE formname='element_manager' AND formtype='form_element' AND columnname='tbl_element' AND tabname='tab_none';


DELETE FROM config_form_fields WHERE formname ILIKE '%element%' AND formtype='form_feature' AND columnname='order_id' AND tabname='tab_data';
UPDATE config_form_fields SET layoutorder=4 WHERE formname ILIKE '%element%' AND formtype='form_feature'AND tabname='tab_data' AND columnname='expl_id' AND layoutorder=5;
UPDATE config_form_fields
	SET layoutorder=3
	WHERE formname='ve_element_epump' AND formtype='form_feature' AND columnname='flwreg_length' AND tabname='tab_data';
UPDATE config_form_fields
	SET layoutorder=2
	WHERE formname='ve_element_epump' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';

DELETE FROM config_form_fields WHERE formname ILIKE 've_element%' AND formtype='form_feature' AND columnname='tbl_element_x_gully' AND tabname='tab_features';

-- last update
-- Normalize "label": replace underscores with spaces, trim, ensure only the first letter is uppercase,
-- and append a colon if missing. Only updates rows needing changes.
ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_config_control;
UPDATE config_form_fields
SET "label" =
    UPPER(LEFT(cleaned, 1)) ||
    SUBSTRING(cleaned FROM 2) ||
    CASE WHEN RIGHT(cleaned, 1) = ':' THEN '' ELSE ':' END
FROM (
    SELECT
        formname, formtype, columnname, tabname,
        TRIM(
            regexp_replace(
                regexp_replace(replace("label", '_', ' '), '\s+', ' ', 'g'),
                '\s+$', '', 'g'
            )
        ) AS cleaned
    FROM config_form_fields
) AS sub
WHERE config_form_fields.formname   = sub.formname
  AND config_form_fields.formtype   = sub.formtype
  AND config_form_fields.columnname = sub.columnname
  AND config_form_fields.tabname    = sub.tabname
  AND "label" IS NOT NULL
  AND (
        LEFT("label", 1) <> UPPER(LEFT("label", 1))
     OR RIGHT(sub.cleaned, 1) <> ':'
  );
ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_config_control;

-- Normalize "label": replace underscores with spaces, trim, ensure only the first letter is uppercase,
-- and append a colon if missing. Only updates rows needing changes.

UPDATE config_param_system
SET "label" =
    UPPER(LEFT(cleaned, 1)) ||
    SUBSTRING(cleaned FROM 2) ||
    CASE WHEN RIGHT(cleaned, 1) = ':' THEN '' ELSE ':' END
FROM (
    SELECT
        "parameter",
        TRIM(
            regexp_replace(
                regexp_replace(replace("label", '_', ' '), '\s+', ' ', 'g'),
                '\s+$', '', 'g'
            )
        ) AS cleaned
    FROM config_param_system
) AS sub
WHERE config_param_system."parameter" = sub."parameter"
  AND "label" IS NOT NULL
  AND (
        LEFT("label", 1) <> UPPER(LEFT("label", 1))
     OR RIGHT(sub.cleaned, 1) <> ':'
  );


UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=1, alias='Node features' WHERE id='ve_cat_feature_node';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=2, alias='Arc features' WHERE id='ve_cat_feature_arc';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=3, alias='Connec features' WHERE id='ve_cat_feature_connec';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=4, alias='Gully features' WHERE id='ve_cat_feature_gully';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=5, alias='Link features' WHERE id='ve_cat_feature_link';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=6, alias='Element features' WHERE id='ve_cat_feature_element';

UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=7, alias='Node catalog' WHERE id='cat_node';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=8, alias='Arc catalog' WHERE id='cat_arc';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=9, alias='Connec catalog' WHERE id='cat_connec';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=10, alias='Gully catalog' WHERE id='cat_gully';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=11, alias='Link catalog' WHERE id='cat_link';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=12, alias='Element catalog' WHERE id='cat_element';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=13, alias='Material catalog' WHERE id='cat_material';

DO $$
DECLARE
	rec record;
BEGIN

	FOR rec IN (SELECT * FROM connec WHERE connec_type = 'CJOIN') LOOP
		INSERT INTO man_cjoin (connec_id) VALUES (rec.connec_id);
	END LOOP;

	FOR rec IN (SELECT * FROM gully WHERE gully_type = 'GINLET') LOOP
		INSERT INTO man_ginlet (gully_id) VALUES (rec.gully_id);
	END LOOP;

	FOR rec IN (SELECT * FROM gully WHERE gully_type = 'VGINLET') LOOP
		INSERT INTO man_vgully (gully_id) VALUES (rec.gully_id);
	END LOOP;

	FOR rec IN (SELECT * FROM gully WHERE gully_type = 'VGULLY') LOOP
		INSERT INTO man_vgully (gully_id) VALUES (rec.gully_id);
	END LOOP;

END $$;

ALTER TABLE arc ADD CONSTRAINT arc_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id);
ALTER TABLE connec ADD CONSTRAINT connec_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id);
ALTER TABLE gully ADD CONSTRAINT gully_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id);
ALTER TABLE link ADD CONSTRAINT link_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id);
ALTER TABLE node ADD CONSTRAINT node_dma_id_fkey FOREIGN KEY (dma_id) REFERENCES dma(dma_id);

ALTER TABLE inp_inlet
ADD CONSTRAINT inp_inlet_inlet_type CHECK (inlet_type IN ('GULLY'));

ALTER TABLE inp_inlet
ADD CONSTRAINT inp_inlet_gully_type CHECK (outlet_type IN ('To_network'));

ALTER TABLE inp_inlet
ADD CONSTRAINT inp_inlet_gully_method CHECK (gully_method IN ('W_O'));

ALTER TABLE node DROP CONSTRAINT node_epa_type_check;
ALTER TABLE node ADD CONSTRAINT node_epa_type_check CHECK (epa_type IN ('JUNCTION', 'DIVIDER', 'OUTFALL', 'STORAGE', 'NETGULLY', 'INLET', 'UNDEFINED'));


ALTER TABLE connec DROP CONSTRAINT IF EXISTS connec_drainzone_id_fkey;
ALTER TABLE arc DROP CONSTRAINT IF EXISTS arc_drainzone_id_fkey;
ALTER TABLE gully DROP CONSTRAINT IF EXISTS gully_drainzone_id_fkey;
ALTER TABLE node DROP CONSTRAINT IF EXISTS node_drainzone_id_fkey;


ALTER TABLE element DROP CONSTRAINT IF EXISTS element_epa_type_check;
ALTER TABLE "element" ADD CONSTRAINT element_epa_type_check CHECK ((epa_type = ANY (ARRAY['FRPUMP'::text, 'FRWEIR'::text, 'FRORIFICE'::text, 'FROUTLET'::text, 'UNDEFINED'::text])));
ALTER TABLE "element" ADD CONSTRAINT element_expl_id_fkey FOREIGN KEY (expl_id) REFERENCES exploitation(expl_id);
ALTER TABLE man_frelem ADD CONSTRAINT man_frelem_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id);


ALTER TABLE arc ADD CONSTRAINT arc_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id);
ALTER TABLE node ADD CONSTRAINT node_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id);
ALTER TABLE "element" ADD CONSTRAINT element_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id);

ALTER TABLE arc ADD CONSTRAINT arc_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id);
ALTER TABLE node ADD CONSTRAINT node_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id);
ALTER TABLE "element" ADD CONSTRAINT element_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id);


ALTER TABLE inp_froutlet ADD CONSTRAINT inp_froutlet_element_id_fkey FOREIGN KEY (element_id) REFERENCES element(element_id) ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TRIGGER gw_trg_typevalue_fk_insert AFTER INSERT ON inp_gully
FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_gully');

CREATE TRIGGER gw_trg_typevalue_fk_update AFTER UPDATE ON inp_gully
FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_gully');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_inlet
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('INLET');

CREATE TRIGGER gw_trg_edit_ve_epa_inlet INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_inlet
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('inlet');

CREATE TRIGGER gw_trg_edit_inp_node_inlet INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_inlet
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_inlet');

CREATE TRIGGER gw_trg_edit_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_gully('parent');

CREATE TRIGGER gw_trg_edit_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');

CREATE TRIGGER gw_trg_edit_node INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_node('parent');

CREATE TRIGGER gw_trg_edit_inp_node_junction INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_junction FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_junction');

CREATE TRIGGER gw_trg_edit_inp_treatment INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_treatment FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_treatment();

CREATE TRIGGER gw_trg_edit_inp_inflows INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_inflows_poll FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_inflows('INFLOWS-POLL');

CREATE TRIGGER gw_trg_edit_inp_inflows INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_inflows FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_inflows('INFLOWS');

CREATE TRIGGER gw_trg_edit_inp_dwf INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dwf FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dwf();

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_treatment FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('TREATMENT');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_junction FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('JUNCTION');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_inflows_poll FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('INFLOWS-POLL');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_inflows FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('INFLOWS');

CREATE TRIGGER gw_trg_edit_inp_node_storage INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_storage');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('STORAGE');

CREATE TRIGGER gw_trg_edit_inp_node_junction INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_outfall FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_outfall');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_outfall FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('OUTFALL');

CREATE TRIGGER gw_trg_edit_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_arc('parent');

CREATE TRIGGER gw_trg_edit_inp_arc_weir INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_weir');

CREATE TRIGGER gw_trg_edit_inp_arc_virtual INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_virtual FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_virtual');

CREATE TRIGGER gw_trg_edit_inp_arc_pump INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_pump');

CREATE TRIGGER gw_trg_edit_inp_arc_outlet INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_outlet');

CREATE TRIGGER gw_trg_edit_inp_arc_orifice INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_orifice FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_orifice');

CREATE TRIGGER gw_trg_edit_inp_arc_conduit INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_conduit FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_conduit');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_conduit FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('CONDUIT');

CREATE TRIGGER gw_trg_ve_dwfzone INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_dwfzone FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dwfzone('EDIT');

CREATE TRIGGER gw_trg_v_ui_dwfzone INSTEAD OF INSERT OR DELETE OR UPDATE ON
v_ui_dwfzone FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dwfzone('UI');


-- view
CREATE TRIGGER gw_trg_edit_dma INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_dma FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dma();

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_link FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link('LINK');


CREATE TRIGGER gw_trg_v_ui_macroomzone INSTEAD OF DELETE OR UPDATE
ON v_ui_macroomzone FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macroomzone('UI');

-- Expl_id
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table ON exploitation;
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON exploitation;
CREATE TRIGGER gw_trg_fk_array_id_table BEFORE DELETE ON exploitation
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('expl_id', '{"dma":"expl_id", "macroomzone":"expl_id", "dwfzone":"expl_id", "drainzone":"expl_id", "sector":"expl_id", "ext_municipality":"expl_id"}');

CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE ON exploitation
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('expl_id', '{"dma":"expl_id", "macroomzone":"expl_id", "dwfzone":"expl_id", "drainzone":"expl_id", "sector":"expl_id", "ext_municipality":"expl_id"}');

CREATE TRIGGER gw_trg_fk_array_array_table_expl AFTER INSERT OR UPDATE ON dma
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('expl_id', 'exploitation', 'expl_id');
-- The others are already created

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
        -- Muni_id
        DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table ON utils.municipality;
        DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON utils.municipality;
        CREATE TRIGGER gw_trg_fk_array_id_table BEFORE DELETE ON utils.municipality
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('muni_id', '{"dma":"muni_id", "dwfzone":"muni_id", "drainzone":"muni_id", "exploitation":"muni_id", "sector":"muni_id"}');

        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE ON utils.municipality
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('muni_id', '{"dma":"muni_id", "dwfzone":"muni_id", "drainzone":"muni_id", "exploitation":"muni_id", "sector":"muni_id"}');

        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE ON dma
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
    ELSE
        -- Muni_id
        DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table ON ext_municipality;
        DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON ext_municipality;
        CREATE TRIGGER gw_trg_fk_array_id_table BEFORE DELETE ON ext_municipality
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('muni_id', '{"dma":"muni_id", "dwfzone":"muni_id", "drainzone":"muni_id", "exploitation":"muni_id", "sector":"muni_id"}');

        CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE ON ext_municipality
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('muni_id', '{"dma":"muni_id", "dwfzone":"muni_id", "drainzone":"muni_id", "exploitation":"muni_id", "sector":"muni_id"}');

        CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT OR UPDATE ON dma
        FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'ext_municipality', 'muni_id');
    END IF;


END $$;

-- The others are already created

-- Sector_id
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table ON sector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON sector;
CREATE TRIGGER gw_trg_fk_array_id_table BEFORE DELETE ON sector
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('sector_id', '{"dma":"sector_id", "dwfzone":"sector_id", "drainzone":"sector_id", "exploitation":"sector_id", "ext_municipality":"sector_id"}');

CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE ON sector
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('sector_id', '{"dma":"sector_id", "dwfzone":"sector_id", "drainzone":"sector_id", "exploitation":"sector_id", "ext_municipality":"sector_id"}');

CREATE TRIGGER gw_trg_fk_array_array_table_sector AFTER INSERT OR UPDATE ON dma
FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('sector_id', 'sector', 'sector_id');
-- The others are already created

-- old v_edit parent tables:
CREATE TRIGGER gw_trg_edit_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_arc('parent');

CREATE TRIGGER gw_trg_edit_node INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_node
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_node('parent');

CREATE TRIGGER gw_trg_edit_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');

CREATE TRIGGER gw_trg_edit_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_gully
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_gully('parent');

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR UPDATE OR DELETE ON v_edit_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link('parent');
-- ================================

CREATE TRIGGER gw_trg_edit_ve_epa_frpump INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_epa_frpump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frpump');

CREATE TRIGGER gw_trg_edit_ve_epa_frorifice INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_epa_frorifice FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frorifice');

CREATE TRIGGER gw_trg_edit_ve_epa_froutlet INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_epa_froutlet FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('froutlet');

CREATE TRIGGER gw_trg_edit_ve_epa_frweir INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_epa_frweir FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frweir');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_inp_dscenario_frpump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-PUMP');


CREATE TRIGGER gw_trg_plan_psector_after_gully AFTER INSERT ON gully
FOR EACH ROW
WHEN (NEW.state = 2)
EXECUTE FUNCTION gw_trg_insert_psector_x_feature('gully');

CREATE TRIGGER gw_trg_edit_plan_psector_connec INSTEAD OF INSERT OR DELETE OR UPDATE
ON ve_plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plan_psector_x_connect('plan_psector_x_connec');

CREATE TRIGGER gw_trg_edit_plan_psector_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON
ve_plan_psector_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plan_psector_x_connect('plan_psector_x_gully');

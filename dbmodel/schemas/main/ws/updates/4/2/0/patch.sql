/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;


SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"man_valve", "column":"pression_exit", "newName":"pressure_exit"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"man_valve", "column":"pression_entry", "newName":"pressure_entry"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"man_pump", "column":"pressure", "newName":"pressure_exit"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"arc", "column":"staticpress1", "newName":"staticpressure1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"arc", "column":"staticpress2", "newName":"staticpressure2"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"link", "column":"staticpressure", "newName":"staticpressure1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"archived_psector_arc", "column":"staticpress1", "newName":"staticpressure1"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"archived_psector_arc", "column":"staticpress2", "newName":"staticpressure2"}}$$);


SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"arc_add", "column":"mincut_impact", "newName":"mincut_impact_topo"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"arc_add", "column":"mincut_affectation", "newName":"mincut_impact_hydro"}}$$);


/*
-- Change expl_id type to INT4[] in macrodma
DROP VIEW IF EXISTS v_edit_macrodma;
DROP VIEW IF EXISTS v_ui_macrodma;
ALTER TABLE macrodma DROP CONSTRAINT IF EXISTS macrodma_expl_id_fkey;
ALTER TABLE macrodma ALTER COLUMN expl_id TYPE INT4[] USING ARRAY[expl_id];

-- Change expl_id type to INT4[] in macrodqa
DROP VIEW IF EXISTS v_edit_macrodqa;
DROP VIEW IF EXISTS v_ui_macrodqa;
ALTER TABLE macrodqa DROP CONSTRAINT IF EXISTS macrodqa_expl_id_fkey;
ALTER TABLE macrodqa ALTER COLUMN expl_id TYPE INT4[] USING ARRAY[expl_id];

-- Change expl_id type to INT4[] in macroomzone
DROP VIEW IF EXISTS v_edit_macroomzone;
DROP VIEW IF EXISTS v_ui_macroomzone;
ALTER TABLE macroomzone DROP CONSTRAINT IF EXISTS macroomzone_expl_id_fkey;
ALTER TABLE macroomzone ALTER COLUMN expl_id TYPE INT4[] USING ARRAY[expl_id];
*/


ALTER TABLE om_waterbalance_dma_graph ALTER COLUMN node_id TYPE int4 USING node_id::int4;

SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"man_meter", "column":"meter_type", "dataType":"int4"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"man_meter", "column":"name", "dataType":"text"}}$$);


CREATE TABLE IF NOT EXISTS minsector_mincut_valve (
    minsector_id INT4,
    node_id INT4,
    proposed BOOLEAN,
    CONSTRAINT minsector_mincut_valve_pkey PRIMARY KEY (minsector_id, node_id),
    CONSTRAINT minsector_mincut_valve_minsector_id_fkey FOREIGN KEY (minsector_id) REFERENCES minsector(minsector_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT minsector_mincut_valve_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_minsector_mincut_valve_minsector_id ON minsector_mincut_valve (minsector_id);
CREATE INDEX IF NOT EXISTS idx_minsector_mincut_valve_node_id ON minsector_mincut_valve (node_id);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_cat_hydrometer", "column":"voltman_flow", "newName":"type"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"ext_cat_hydrometer", "column":"multi_jet_flow", "newName":"flownom"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"rpt_cat_result", "column":"dma_id", "dataType":"integer[]"}}$$);



DROP VIEW IF EXISTS v_edit_inp_dscenario_frpump;
DROP VIEW IF EXISTS ve_epa_frpump;
DROP VIEW IF EXISTS v_edit_inp_frpump;
DROP TABLE IF EXISTS inp_frpump;
CREATE TABLE inp_frpump (
    element_id int4 NOT NULL,
	power varchar NULL,
	curve_id varchar NULL,
	speed numeric(12, 6) NULL,
	pattern_id varchar NULL,
	status varchar(12) NULL,
	energyparam varchar(30) NULL,
	energyvalue varchar(30) NULL,
	pump_type varchar(16) DEFAULT 'POWERPUMP'::character varying NULL,
	effic_curve_id varchar(18) NULL,
	energy_price float8 NULL,
	energy_pattern_id varchar(18) NULL,
	CONSTRAINT inp_frpump_pk PRIMARY KEY (element_id),
	CONSTRAINT inp_frpump_status_check CHECK (((status)::text = ANY (ARRAY[('CLOSED'::character varying)::text, ('OPEN'::character varying)::text]))),
	CONSTRAINT inp_frpump_curve_id_fkey FOREIGN KEY (curve_id) REFERENCES inp_curve(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT inp_frpump_energy_pattern_id_fkey FOREIGN KEY (energy_pattern_id) REFERENCES inp_pattern(pattern_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT inp_frpump_element_id_fkey FOREIGN KEY (element_id) REFERENCES element(element_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT inp_frpump_pattern_id_fkey FOREIGN KEY (pattern_id) REFERENCES inp_pattern(pattern_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

DROP TABLE IF EXISTS inp_dscenario_frpump;
CREATE TABLE inp_dscenario_frpump (
	dscenario_id int4 NOT NULL,
	element_id int4 NOT NULL,
	power varchar NULL,
	curve_id varchar NULL,
	speed numeric(12, 6) NULL,
	pattern_id varchar NULL,
	status varchar(12) NULL,
	effic_curve_id varchar(18) NULL,
	energy_price float8 NULL,
	energy_pattern_id varchar(18) NULL,
    CONSTRAINT inp_dscenario_frpump_pk PRIMARY KEY (element_id, dscenario_id),
	CONSTRAINT inp_dscenario_frpump_status_check CHECK (((status)::text = ANY (ARRAY[('CLOSED'::character varying)::text, ('OPEN'::character varying)::text]))),
	CONSTRAINT inp_dscenario_frpump_fk_curve_id FOREIGN KEY (curve_id) REFERENCES inp_curve(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT inp_dscenario_frpump_dscenario_id_fkey FOREIGN KEY (dscenario_id) REFERENCES cat_dscenario(dscenario_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT inp_dscenario_frpump_energy_pattern_id_fkey FOREIGN KEY (energy_pattern_id) REFERENCES inp_pattern(pattern_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT inp_dscenario_frpump_element_id_fkey FOREIGN KEY (element_id) REFERENCES inp_frpump(element_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT inp_dscenario_frpump_pattern_id_fkey FOREIGN KEY (pattern_id) REFERENCES inp_pattern(pattern_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"rpt_cat_result", "column":"flow_units", "dataType":"text"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"rpt_cat_result", "column":"quality_units", "dataType":"text"}}$$);


SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"node_add", "column":"flow_max", "dataType":"numeric(12,2)"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"node_add", "column":"flow_min", "dataType":"numeric(12,2)"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"node_add", "column":"flow_avg", "dataType":"numeric(12,2)"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"node_add", "column":"vel_max", "dataType":"numeric(12,2)"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"node_add", "column":"vel_min", "dataType":"numeric(12,2)"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"node_add", "column":"vel_avg", "dataType":"numeric(12,2)"}}$$);


CREATE TABLE element_add(
	element_id int4 NOT NULL,
	result_id text NULL,
	flow_max numeric(12, 2) NULL,
	flow_min numeric(12, 2) NULL,
	flow_avg numeric(12, 2) NULL,
	vel_max numeric(12, 2) NULL,
	vel_min numeric(12, 2) NULL,
	vel_avg numeric(12, 2) NULL,
	tot_headloss_max numeric(12, 2) NULL,
	tot_headloss_min numeric(12, 2) NULL,
	mincut_connecs int4 NULL,
	mincut_hydrometers int4 NULL,
	mincut_length numeric(12, 3) NULL,
	mincut_watervol numeric(12, 3) NULL,
	mincut_criticality numeric(12, 3) NULL,
	hydraulic_criticality numeric(12, 3) NULL,
	pipe_capacity float8 NULL,
	mincut_impact_topo json NULL,
	mincut_impact_hydro json NULL,
	CONSTRAINT element_add_pkey PRIMARY KEY(element_id),
	CONSTRAINT element_add_element_id_fkey FOREIGN KEY (element_id) REFERENCES element(element_id) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS inp_frshortpipe;
CREATE TABLE inp_frshortpipe (
    element_id int4 NOT NULL,
	minorloss numeric(12, 6) DEFAULT 0 NULL,
	status varchar(12) NULL,
	bulk_coeff float8 NULL,
	wall_coeff float8 NULL,
	custom_dint int4 NULL,
	CONSTRAINT inp_frshortpipe_pk PRIMARY KEY (element_id),
	CONSTRAINT inp_frshortpipe_status_check CHECK (((status)::text = ANY (ARRAY[('CLOSED'::character varying)::text, ('CV'::character varying)::text, ('OPEN'::character varying)::text]))),
	CONSTRAINT inp_frshortpipe_fk_element_id FOREIGN KEY (element_id) REFERENCES element(element_id)
);

DROP TABLE IF EXISTS inp_dscenario_frshortpipe;
CREATE TABLE inp_dscenario_frshortpipe (
	dscenario_id int4 NOT NULL,
	element_id int4 NOT NULL,
	minorloss numeric(12, 6) NULL,
	status varchar(12) NULL,
	custom_dint int4 NULL,
	bulk_coeff float8 NULL,
	wall_coeff float8 NULL,
    CONSTRAINT inp_dscenario_frshortpipe_pk PRIMARY KEY (element_id, dscenario_id),
    CONSTRAINT inp_dscenario_frshortpipe_dscenario_id_fkey FOREIGN KEY (dscenario_id) REFERENCES cat_dscenario(dscenario_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT inp_dscenario_frshortpipe_status_check CHECK (((status)::text = ANY (ARRAY[('CLOSED'::character varying)::text, ('CV'::character varying)::text, ('OPEN'::character varying)::text]))),
	CONSTRAINT inp_dscenario_frshortpipe_element_id_fkey FOREIGN KEY (element_id) REFERENCES inp_frshortpipe(element_id) ON DELETE CASCADE ON UPDATE CASCADE
);


DO $function$
DECLARE
    v_crm boolean;
BEGIN

	SELECT value::boolean INTO v_crm FROM config_param_system WHERE parameter='admin_crm_schema';

	PERFORM gw_fct_admin_manage_fields(format($${"data":{"action":"RENAME", "table":"ext_cat_hydrometer", "column":"voltman_flow", "newName":"type", "isCrm":%s}}$$, v_crm::text)::json);
	PERFORM gw_fct_admin_manage_fields(format($${"data":{"action":"RENAME", "table":"ext_cat_hydrometer", "column":"multi_jet_flow", "newName":"flownom", "isCrm":%s}}$$, v_crm::text)::json);

END $function$;


SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"man_pump", "column":"pump_type", "dataType":"int4"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"man_pump", "column":"engine_type", "dataType":"int4"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"man_meter", "column":"nominal_flowrate", "dataType":"numeric(12,3)"}}$$);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"man_wtp", "column":"chemcond", "newName":"chemical"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"man_wtp", "column":"chemtreatment"}}$$);


DROP VIEW IF EXISTS v_edit_inp_dscenario_frvalve;
DROP VIEW IF EXISTS v_edit_inp_frvalve;
DROP VIEW IF EXISTS ve_epa_frvalve;
DROP VIEW IF EXISTS ve_element_epump;
DROP VIEW IF EXISTS ve_element_evalve;
DROP VIEW IF EXISTS ve_man_frelem;
DROP VIEW IF EXISTS ve_frelem;
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"man_frelem", "column":"order_id"}}$$);

DROP VIEW IF EXISTS ve_link_link;
DROP VIEW IF EXISTS v_edit_link;
DROP VIEW IF EXISTS v_inp_pjointpattern;
DROP VIEW IF EXISTS v_minsector_graph;
DROP VIEW IF EXISTS v_state_element;
DROP VIEW IF EXISTS vu_element_x_arc;
DROP VIEW IF EXISTS vu_element_x_node;
DROP VIEW IF EXISTS vu_element_x_connec;
DROP VIEW IF EXISTS vu_element_x_link;
DROP VIEW IF EXISTS vcv_demands;
DROP VIEW IF EXISTS vcv_patterns;
DROP VIEW IF EXISTS v_rtc_period_hydrometer;


ALTER VIEW v_edit_arc RENAME COLUMN staticpress1 TO staticpressure1;
ALTER VIEW v_edit_arc RENAME COLUMN staticpress2 TO staticpressure2;
ALTER VIEW v_edit_arc RENAME COLUMN mincut_impact TO mincut_impact_topo;
ALTER VIEW v_edit_arc RENAME COLUMN mincut_affectation TO mincut_impact_hydro;

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
            WHEN man_frelem.node_id = a.node_1 THEN st_setsrid(ST_LineSubstring(a.the_geom, 0, man_frelem.flwreg_length::double precision / st_length(a.the_geom)), SRID_VALUE)::geometry(LineString,SRID_VALUE)
            WHEN man_frelem.node_id = a.node_2 THEN st_setsrid(ST_LineSubstring(a.the_geom, 1::double precision - man_frelem.flwreg_length::double precision / st_length(a.the_geom),1), SRID_VALUE)::geometry(LineString,SRID_VALUE)
            ELSE NULL::geometry(LineString,SRID_VALUE)
        END AS the_geom
   FROM ve_element
     JOIN man_frelem ON ve_element.element_id = man_frelem.element_id
     JOIN arc a ON a.arc_id = man_frelem.to_arc
     JOIN node USING (node_id);

CREATE OR REPLACE VIEW v_edit_inp_frvalve
as select f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
    v.valve_type,
    custom_dint,
    setting,
    curve_id,
    minorloss,
    add_settings,
    init_quality,
    f.the_geom
    FROM ve_man_frelem f
    JOIN inp_frvalve v ON f.element_id = v.element_id;

CREATE OR REPLACE VIEW v_edit_inp_dscenario_frvalve
AS SELECT s.dscenario_id,
    element_id,
	  v.valve_type,
    v.custom_dint,
    v.setting,
    v.curve_id,
    v.minorloss,
    v.add_settings,
    v.init_quality,
    n.the_geom
    FROM selector_inp_dscenario s, inp_dscenario_frvalve v
    JOIN v_edit_inp_frvalve n USING (element_id)
    WHERE s.dscenario_id = v.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_element_epump
AS SELECT ve_element.element_id,
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
    ve_element.created_at,
    ve_element.created_by,
    ve_element.updated_at,
    ve_element.updated_by,
    ve_element.the_geom,
    man_frelem.node_id,
    man_frelem.to_arc,
    man_frelem.flwreg_length
   FROM ve_element
     JOIN man_frelem USING (element_id)
  WHERE ve_element.element_type::text = 'EPUMP'::text;

CREATE OR REPLACE VIEW ve_element_evalve
AS SELECT ve_element.element_id,
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
    ve_element.created_at,
    ve_element.created_by,
    ve_element.updated_at,
    ve_element.updated_by,
    ve_element.the_geom,
    man_frelem.node_id,
    man_frelem.to_arc,
    man_frelem.flwreg_length
   FROM ve_element
     JOIN man_frelem USING (element_id)
  WHERE ve_element.element_type::text = 'EVALVE'::text;

CREATE OR REPLACE VIEW v_edit_link
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
        ), link_psector AS (
         SELECT DISTINCT ON (pp.connec_id, pp.state) 'CONNEC'::text AS feature_type,
            pp.connec_id AS feature_id,
            pp.state AS p_state,
            pp.psector_id,
            pp.link_id
           FROM plan_psector_x_connec pp
             JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
          ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST
        ), link_selector AS (
         SELECT l_1.link_id
           FROM link l_1
             JOIN selector_state s ON s.cur_user = CURRENT_USER AND l_1.state = s.state_id
             LEFT JOIN ( SELECT link_psector.link_id
                   FROM link_psector
                  WHERE link_psector.p_state = 0) a ON a.link_id = l_1.link_id
          WHERE a.link_id IS NULL AND (EXISTS ( SELECT 1
                   FROM selector_expl se
                  WHERE s.cur_user = CURRENT_USER AND (se.expl_id = ANY (array_append(l_1.expl_visibility::integer[], l_1.expl_id))))) AND (EXISTS ( SELECT 1
                   FROM selector_sector sc
                  WHERE sc.cur_user = CURRENT_USER AND sc.sector_id = l_1.sector_id)) AND (EXISTS ( SELECT 1
                   FROM selector_municipality sm
                  WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = l_1.muni_id))
        UNION ALL
         SELECT link_psector.link_id
           FROM link_psector
          WHERE link_psector.p_state = 1
        ), link_selected AS (
         SELECT l_1.link_id,
            l_1.code,
            l_1.sys_code,
            l_1.top_elev1,
            l_1.depth1,
                CASE
                    WHEN l_1.top_elev1 IS NULL OR l_1.depth1 IS NULL THEN NULL::double precision
                    ELSE l_1.top_elev1 - l_1.depth1::double precision
                END AS elevation1,
            l_1.exit_id,
            l_1.exit_type,
            l_1.top_elev2,
            l_1.depth2,
                CASE
                    WHEN l_1.top_elev2 IS NULL OR l_1.depth2 IS NULL THEN NULL::double precision
                    ELSE l_1.top_elev2 - l_1.depth2::double precision
                END AS elevation2,
            l_1.feature_type,
            l_1.feature_id,
            cat_link.link_type,
            cat_feature.feature_class AS sys_type,
            l_1.linkcat_id,
            l_1.state,
            l_1.state_type,
            l_1.expl_id,
            exploitation.macroexpl_id,
            l_1.muni_id,
            l_1.sector_id,
            sector_table.macrosector_id,
            sector_table.sector_type,
            l_1.supplyzone_id,
            supplyzone_table.supplyzone_type,
            l_1.presszone_id,
            presszone_table.presszone_type,
            presszone_table.presszone_head,
            l_1.dma_id,
            dma_table.macrodma_id,
            dma_table.dma_type,
            l_1.dqa_id,
            dqa_table.macrodqa_id,
            dqa_table.dqa_type,
            l_1.omzone_id,
            omzone_table.macroomzone_id,
            omzone_table.omzone_type,
            l_1.minsector_id,
            l_1.location_type,
            l_1.fluid_type,
            l_1.custom_length,
            st_length(l_1.the_geom)::numeric(12,3) AS gis_length,
            l_1.staticpressure1,
            l_1.staticpressure2,
            l_1.annotation,
            l_1.observ,
            l_1.comment,
            l_1.descript,
            l_1.link,
            l_1.num_value,
            l_1.workcat_id,
            l_1.workcat_id_end,
            l_1.builtdate,
            l_1.enddate,
			l_1.brand_id,
			l_1.model_id,
            l_1.verified,
            l_1.uncertain,
            l_1.userdefined_geom,
            l_1.datasource,
            l_1.is_operative,
                CASE
                    WHEN l_1.sector_id > 0 AND l_1.is_operative = true AND c.epa_type::text = 'JUNCTION'::text AND inp_network_mode.value = '4'::text THEN c.epa_type::text
                    ELSE NULL::text
                END AS inp_type,
            l_1.lock_level,
            l_1.expl_visibility,
            l_1.created_at,
            l_1.created_by,
            l_1.updated_at,
            l_1.updated_by,
            l_1.the_geom
           FROM link_selector
             JOIN link l_1 ON l_1.link_id = link_selector.link_id
             LEFT JOIN connec c ON c.connec_id = l_1.feature_id
             JOIN sector_table ON sector_table.sector_id = l_1.sector_id
             JOIN cat_link ON cat_link.id::text = l_1.linkcat_id::text
             JOIN cat_feature ON cat_feature.id::text = cat_link.link_type::text
             JOIN exploitation ON l_1.expl_id = exploitation.expl_id
             LEFT JOIN presszone_table ON presszone_table.presszone_id = l_1.presszone_id
             LEFT JOIN dma_table ON dma_table.dma_id = l_1.dma_id
             LEFT JOIN dqa_table ON dqa_table.dqa_id = l_1.dqa_id
             LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = l_1.supplyzone_id
             LEFT JOIN omzone_table ON omzone_table.omzone_id = l_1.omzone_id
             LEFT JOIN inp_network_mode ON true
        )
 SELECT link_id,
    code,
    sys_code,
    top_elev1,
    depth1,
    elevation1,
    exit_id,
    exit_type,
    top_elev2,
    depth2,
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
    supplyzone_id,
    supplyzone_type,
    presszone_id,
    presszone_type,
    presszone_head,
    dma_id,
    macrodma_id,
    dma_type,
    dqa_id,
    macrodqa_id,
    dqa_type,
    omzone_id,
    macroomzone_id,
    omzone_type,
    minsector_id,
    location_type,
    fluid_type,
    custom_length,
    gis_length,
    staticpressure1,
    staticpressure2,
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
    verified,
    uncertain,
    userdefined_geom,
    datasource,
    is_operative,
    inp_type,
    lock_level,
    expl_visibility,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom
   FROM link_selected l;

-- CREATE PARENT VIEWS WITH NEW NAMES
SELECT SCHEMA_NAME.gw_fct_admin_manage_child_views($${"data":{"action":"MULTI-DELETE" }}$$);

ALTER VIEW v_edit_arc RENAME TO ve_arc;
ALTER VIEW v_edit_connec RENAME TO ve_connec;
ALTER VIEW v_edit_link RENAME TO ve_link;
ALTER VIEW v_edit_node RENAME TO ve_node;

CREATE OR REPLACE VIEW ve_arc
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
	arc_psector AS (
		SELECT pp.arc_id, pp.state AS p_state
		FROM plan_psector_x_arc pp
		JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
	),
	arc_selector AS (
		SELECT a.arc_id
		FROM arc a
		WHERE EXISTS ((SELECT 1 FROM sel_state s WHERE s.state_id = a.state))
		AND EXISTS ((SELECT 1 FROM sel_sector s WHERE s.sector_id = a.sector_id))
		AND EXISTS ((SELECT 1 FROM sel_expl s WHERE s.expl_id = ANY (array_append(expl_visibility, a.expl_id))))
		AND EXISTS ((SELECT 1 FROM sel_muni s WHERE s.muni_id = a.muni_id))
		AND NOT (
			EXISTS (
				SELECT 1
				FROM arc_psector ap
				WHERE ap.arc_id = a.arc_id AND ap.p_state = 0
			)
		)
		UNION ALL
		SELECT ap.arc_id
		FROM arc_psector ap
		WHERE ap.p_state = 1
	),
  	arc_selected AS (
		SELECT
			arc.arc_id,
			arc.code,
			arc.sys_code,
			arc.node_1,
			arc.nodetype_1,
			arc.elevation1,
			arc.depth1,
			arc.staticpressure1,
			arc.node_2,
			arc.nodetype_2,
			arc.staticpressure2,
			arc.elevation2,
			arc.depth2,
			((COALESCE(arc.depth1) + COALESCE(arc.depth2)) / 2::numeric)::numeric(12,2) AS depth,
			cat_arc.arc_type,
			arc.arccat_id,
			cat_feature.feature_class AS sys_type,
			cat_arc.matcat_id AS cat_matcat_id,
			cat_arc.pnom AS cat_pnom,
			cat_arc.dnom AS cat_dnom,
			cat_arc.dint AS cat_dint,
			cat_arc.dr AS cat_dr,
			arc.epa_type,
			arc.state,
			arc.state_type,
			arc.parent_id,
			arc.expl_id,
			exploitation.macroexpl_id,
			arc.muni_id,
			arc.sector_id,
			sector_table.macrosector_id,
			sector_table.sector_type,
			arc.supplyzone_id,
			supplyzone_table.supplyzone_type,
			arc.presszone_id,
			presszone_table.presszone_type,
			presszone_table.presszone_head,
			arc.dma_id,
			dma_table.macrodma_id,
			dma_table.dma_type,
			arc.dqa_id,
			dqa_table.macrodqa_id,
			dqa_table.dqa_type,
			arc.omzone_id,
			omzone_table.macroomzone_id,
			omzone_table.omzone_type,
			arc.minsector_id,
			arc.pavcat_id,
			arc.soilcat_id,
			arc.function_type,
			arc.category_type,
			arc.location_type,
			arc.fluid_type,
			arc.descript,
			st_length2d(arc.the_geom)::numeric(12,2) AS gis_length,
			arc.custom_length,
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
			arc.enddate,
			arc.ownercat_id,
			arc.om_state,
			arc.conserv_state,
			CASE
				WHEN arc.brand_id IS NULL THEN cat_arc.brand_id
				ELSE arc.brand_id
			END AS brand_id,
			CASE
				WHEN arc.model_id IS NULL THEN cat_arc.model_id
				ELSE arc.model_id
			END AS model_id,
			arc.serial_number,
			arc.asset_id,
			arc.adate,
			arc.adescript,
			arc.verified,
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
				WHEN arc.sector_id > 0 AND vst.is_operative = true AND arc.epa_type::text <> 'UNDEFINED'::text THEN arc.epa_type
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
			arc.lock_level,
			arc.expl_visibility,
			date_trunc('second'::text, arc.created_at) AS created_at,
			arc.created_by,
			date_trunc('second'::text, arc.updated_at) AS updated_at,
			arc.updated_by,
			arc.the_geom
			FROM arc_selector
			JOIN arc ON arc.arc_id = arc_selector.arc_id
			JOIN cat_arc ON cat_arc.id::text = arc.arccat_id::text
			JOIN cat_feature ON cat_feature.id::text = cat_arc.arc_type::text
			JOIN exploitation ON arc.expl_id = exploitation.expl_id
			JOIN ext_municipality mu ON arc.muni_id = mu.muni_id
			JOIN sector_table ON sector_table.sector_id = arc.sector_id
			LEFT JOIN presszone_table ON presszone_table.presszone_id = arc.presszone_id
			LEFT JOIN dma_table ON dma_table.dma_id = arc.dma_id
			LEFT JOIN dqa_table ON dqa_table.dqa_id = arc.dqa_id
			LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = arc.supplyzone_id
			LEFT JOIN omzone_table ON omzone_table.omzone_id = arc.omzone_id
			LEFT JOIN arc_add ON arc_add.arc_id = arc.arc_id
			LEFT JOIN value_state_type vst ON vst.id = arc.state_type
    )
	SELECT arc_selected.*
	FROM arc_selected;

CREATE OR REPLACE VIEW ve_node
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
    node_psector AS (
      	SELECT pp.node_id, pp.state AS p_state
      	FROM plan_psector_x_node pp
      	JOIN selector_psector sp ON sp.cur_user = current_user AND sp.psector_id = pp.psector_id
    ),
    node_selector AS (
		SELECT n.node_id
		FROM node n
		WHERE EXISTS ((SELECT 1 FROM sel_state s WHERE s.state_id = n.state))
		AND EXISTS ((SELECT 1 FROM sel_sector s WHERE s.sector_id = n.sector_id))
		AND EXISTS ((SELECT 1 FROM sel_expl s WHERE s.expl_id = ANY (array_append(expl_visibility, n.expl_id))))
		AND EXISTS ((SELECT 1 FROM sel_muni s WHERE s.muni_id = n.muni_id))
		AND NOT (
			EXISTS (
				SELECT 1
				FROM node_psector np
				WHERE np.node_id = n.node_id AND np.p_state = 0
			)
		)
		UNION ALL
		SELECT np.node_id
		FROM node_psector np
		WHERE np.p_state = 1
    ),
    node_selected AS (
		SELECT
			node.node_id,
			node.code,
			node.sys_code,
			node.top_elev,
			node.custom_top_elev,
			CASE
				WHEN node.custom_top_elev IS NOT NULL THEN node.custom_top_elev
				ELSE node.top_elev
			END AS sys_top_elev,
			node.depth,
			cat_node.node_type,
			cat_feature.feature_class AS sys_type,
			node.nodecat_id,
			cat_node.matcat_id AS cat_matcat_id,
			cat_node.pnom AS cat_pnom,
			cat_node.dnom AS cat_dnom,
			cat_node.dint AS cat_dint,
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
			node.supplyzone_id,
			supplyzone_table.supplyzone_type,
			node.presszone_id,
			presszone_table.presszone_type,
			presszone_table.presszone_head,
			node.dma_id,
			dma_table.macrodma_id,
			dma_table.dma_type,
			node.dqa_id,
			dqa_table.macrodqa_id,
			dqa_table.dqa_type,
			node.omzone_id,
			omzone_table.macroomzone_id,
			omzone_table.omzone_type,
			node.minsector_id,
			node.pavcat_id,
			node.soilcat_id,
			node.function_type,
			node.category_type,
			node.location_type,
			node.fluid_type,
			node.staticpressure,
			node.annotation,
			node.observ,
			node.comment,
			node.descript,
			concat(cat_feature.link_path, node.link) AS link,
			node.num_value,
			node.district_id,
			streetaxis_id,
			node.postcode,
			node.postnumber,
			node.postcomplement,
			streetaxis2_id,
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
			node.accessibility,
			node.om_state,
			node.conserv_state,
			node.access_type,
			node.placement_type,
			CASE
			WHEN node.brand_id IS NULL THEN cat_node.brand_id
			ELSE node.brand_id
			END AS brand_id,
			CASE
			WHEN node.model_id IS NULL THEN cat_node.model_id
			ELSE node.model_id
			END AS model_id,
			node.serial_number,
			node.asset_id,
			node.adate,
			node.adescript,
			node.verified,
			node.datasource,
			node.hemisphere,
			cat_node.label,
			node.label_x,
			node.label_y,
			node.label_rotation,
			node.rotation,
			node.label_quadrant,
			cat_node.svg,
			node.inventory,
			node.publish,
			vst.is_operative,
			node.is_scadamap,
			CASE
			WHEN node.sector_id > 0 AND vst.is_operative = true AND node.epa_type::text <> 'UNDEFINED'::text THEN node.epa_type
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
			node.lock_level,
			node.expl_visibility,
			(SELECT ST_X(node.the_geom)) AS xcoord,
			(SELECT ST_Y(node.the_geom)) AS ycoord,
			(SELECT ST_Y(ST_Transform(node.the_geom, 4326))) AS lat,
			(SELECT ST_X(ST_Transform(node.the_geom, 4326))) AS long,
			m.closed as closed_valve,
			m.broken as broken_valve,
			date_trunc('second'::text, node.created_at) AS created_at,
			node.created_by,
			date_trunc('second'::text, node.updated_at) AS updated_at,
			node.updated_by,
			node.the_geom
			FROM node_selector
			JOIN node ON node.node_id = node_selector.node_id
			JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
			JOIN cat_feature ON cat_feature.id::text = cat_node.node_type::text
			JOIN value_state_type vst ON vst.id = node.state_type
			JOIN exploitation ON node.expl_id = exploitation.expl_id
			JOIN ext_municipality mu ON node.muni_id = mu.muni_id
			JOIN sector_table ON sector_table.sector_id = node.sector_id
			LEFT JOIN presszone_table ON presszone_table.presszone_id = node.presszone_id
			LEFT JOIN dma_table ON dma_table.dma_id = node.dma_id
			LEFT JOIN dqa_table ON dqa_table.dqa_id = node.dqa_id
			LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = node.supplyzone_id
			LEFT JOIN omzone_table ON omzone_table.omzone_id = node.omzone_id
			LEFT JOIN node_add ON node_add.node_id = node.node_id
			LEFT JOIN man_valve m ON m.node_id = node.node_id
	)
    SELECT n.*
    FROM node_selected n;

CREATE OR REPLACE VIEW ve_link
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
    link_psector AS (
        SELECT DISTINCT ON (pp.connec_id, pp.state) 'CONNEC' AS feature_type, pp.connec_id AS feature_id, pp.state AS p_state, pp.psector_id, pp.link_id
        FROM plan_psector_x_connec pp
        JOIN selector_psector sp ON sp.cur_user = current_user AND sp.psector_id = pp.psector_id
        ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST
	),
    link_selector AS (
        SELECT l.link_id
        FROM link l
		WHERE EXISTS ((SELECT 1 FROM sel_state s WHERE s.state_id = l.state))
		AND EXISTS ((SELECT 1 FROM sel_sector s WHERE s.sector_id = l.sector_id))
		AND EXISTS ((SELECT 1 FROM sel_expl s WHERE s.expl_id = ANY (array_append(expl_visibility, l.expl_id))))
		AND EXISTS ((SELECT 1 FROM sel_muni s WHERE s.muni_id = l.muni_id))
		AND NOT (
			EXISTS (
				SELECT 1
				FROM link_psector lp
				WHERE lp.link_id = l.link_id AND lp.p_state = 0
			)
		)
		UNION ALL
		SELECT lp.link_id
		FROM link_psector lp
		WHERE lp.p_state = 1
    ),
    link_selected AS (
        SELECT
			l.link_id,
			l.code,
			l.sys_code,
			l.top_elev1,
			l.depth1,
			CASE
			WHEN l.top_elev1 IS NULL OR l.depth1 IS NULL THEN NULL
			ELSE (l.top_elev1 - l.depth1)
			END AS elevation1,
			l.exit_id,
			l.exit_type,
			l.top_elev2,
			l.depth2,
			CASE
			WHEN l.top_elev2 IS NULL OR l.depth2 IS NULL THEN NULL
			ELSE (l.top_elev2 - l.depth2)
			END AS elevation2,
			l.feature_type,
			l.feature_id,
			cat_link.link_type,
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
			CASE
			WHEN l.sector_id > 0 AND l.is_operative = true AND c.epa_type = 'JUNCTION'::text AND inp_network_mode.value = '4'::text
			THEN c.epa_type::text
			ELSE NULL::text
			END AS inp_type,
			l.lock_level,
			l.expl_visibility,
			l.created_at,
			l.created_by,
			l.updated_at,
			l.updated_by,
			l.the_geom
			FROM link_selector
			JOIN link l ON l.link_id = link_selector.link_id
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
			LEFT JOIN inp_network_mode ON true
	)
    SELECT l.*
    FROM link_selected l;

CREATE OR REPLACE VIEW ve_connec
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
			connec.plot_code,
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
		LEFT JOIN crmzone ON crmzone.id::text = connec.crmzone_id::text
		LEFT JOIN link_planned USING (link_id)
		LEFT JOIN connec_add ON connec_add.connec_id = connec.connec_id
		LEFT JOIN value_state_type vst ON vst.id = connec.state_type
		LEFT JOIN inp_network_mode ON true
	)
    SELECT c.*
    FROM connec_selected c;

-- old v_edit parent tables:
CREATE OR REPLACE VIEW v_edit_arc
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
	arc_psector AS (
		SELECT pp.arc_id, pp.state AS p_state
		FROM plan_psector_x_arc pp
		JOIN selector_psector sp ON sp.cur_user = CURRENT_USER AND sp.psector_id = pp.psector_id
	),
	arc_selector AS (
		SELECT a.arc_id
		FROM arc a
		WHERE EXISTS ((SELECT 1 FROM sel_state s WHERE s.state_id = a.state))
		AND EXISTS ((SELECT 1 FROM sel_sector s WHERE s.sector_id = a.sector_id))
		AND EXISTS ((SELECT 1 FROM sel_expl s WHERE s.expl_id = ANY (array_append(expl_visibility, a.expl_id))))
		AND EXISTS ((SELECT 1 FROM sel_muni s WHERE s.muni_id = a.muni_id))
		AND NOT (
			EXISTS (
				SELECT 1
				FROM arc_psector ap
				WHERE ap.arc_id = a.arc_id AND ap.p_state = 0
			)
		)
		UNION ALL
		SELECT ap.arc_id
		FROM arc_psector ap
		WHERE ap.p_state = 1
	),
  	arc_selected AS (
		SELECT
			arc.arc_id,
			arc.code,
			arc.sys_code,
			arc.node_1,
			arc.nodetype_1,
			arc.elevation1,
			arc.depth1,
			arc.staticpressure1,
			arc.node_2,
			arc.nodetype_2,
			arc.staticpressure2,
			arc.elevation2,
			arc.depth2,
			((COALESCE(arc.depth1) + COALESCE(arc.depth2)) / 2::numeric)::numeric(12,2) AS depth,
			cat_arc.arc_type,
			arc.arccat_id,
			cat_feature.feature_class AS sys_type,
			cat_arc.matcat_id AS cat_matcat_id,
			cat_arc.pnom AS cat_pnom,
			cat_arc.dnom AS cat_dnom,
			cat_arc.dint AS cat_dint,
			cat_arc.dr AS cat_dr,
			arc.epa_type,
			arc.state,
			arc.state_type,
			arc.parent_id,
			arc.expl_id,
			exploitation.macroexpl_id,
			arc.muni_id,
			arc.sector_id,
			sector_table.macrosector_id,
			sector_table.sector_type,
			arc.supplyzone_id,
			supplyzone_table.supplyzone_type,
			arc.presszone_id,
			presszone_table.presszone_type,
			presszone_table.presszone_head,
			arc.dma_id,
			dma_table.macrodma_id,
			dma_table.dma_type,
			arc.dqa_id,
			dqa_table.macrodqa_id,
			dqa_table.dqa_type,
			arc.omzone_id,
			omzone_table.macroomzone_id,
			omzone_table.omzone_type,
			arc.minsector_id,
			arc.pavcat_id,
			arc.soilcat_id,
			arc.function_type,
			arc.category_type,
			arc.location_type,
			arc.fluid_type,
			arc.descript,
			st_length2d(arc.the_geom)::numeric(12,2) AS gis_length,
			arc.custom_length,
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
			arc.enddate,
			arc.ownercat_id,
			arc.om_state,
			arc.conserv_state,
			CASE
				WHEN arc.brand_id IS NULL THEN cat_arc.brand_id
				ELSE arc.brand_id
			END AS brand_id,
			CASE
				WHEN arc.model_id IS NULL THEN cat_arc.model_id
				ELSE arc.model_id
			END AS model_id,
			arc.serial_number,
			arc.asset_id,
			arc.adate,
			arc.adescript,
			arc.verified,
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
				WHEN arc.sector_id > 0 AND vst.is_operative = true AND arc.epa_type::text <> 'UNDEFINED'::text THEN arc.epa_type
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
			arc.lock_level,
			arc.expl_visibility,
			date_trunc('second'::text, arc.created_at) AS created_at,
			arc.created_by,
			date_trunc('second'::text, arc.updated_at) AS updated_at,
			arc.updated_by,
			arc.the_geom
			FROM arc_selector
			JOIN arc ON arc.arc_id = arc_selector.arc_id
			JOIN cat_arc ON cat_arc.id::text = arc.arccat_id::text
			JOIN cat_feature ON cat_feature.id::text = cat_arc.arc_type::text
			JOIN exploitation ON arc.expl_id = exploitation.expl_id
			JOIN ext_municipality mu ON arc.muni_id = mu.muni_id
			JOIN sector_table ON sector_table.sector_id = arc.sector_id
			LEFT JOIN presszone_table ON presszone_table.presszone_id = arc.presszone_id
			LEFT JOIN dma_table ON dma_table.dma_id = arc.dma_id
			LEFT JOIN dqa_table ON dqa_table.dqa_id = arc.dqa_id
			LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = arc.supplyzone_id
			LEFT JOIN omzone_table ON omzone_table.omzone_id = arc.omzone_id
			LEFT JOIN arc_add ON arc_add.arc_id = arc.arc_id
			LEFT JOIN value_state_type vst ON vst.id = arc.state_type
    )
	SELECT arc_selected.*
	FROM arc_selected;

CREATE OR REPLACE VIEW v_edit_node
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
    node_psector AS (
      	SELECT pp.node_id, pp.state AS p_state
      	FROM plan_psector_x_node pp
      	JOIN selector_psector sp ON sp.cur_user = current_user AND sp.psector_id = pp.psector_id
    ),
    node_selector AS (
		SELECT n.node_id
		FROM node n
		WHERE EXISTS ((SELECT 1 FROM sel_state s WHERE s.state_id = n.state))
		AND EXISTS ((SELECT 1 FROM sel_sector s WHERE s.sector_id = n.sector_id))
		AND EXISTS ((SELECT 1 FROM sel_expl s WHERE s.expl_id = ANY (array_append(expl_visibility, n.expl_id))))
		AND EXISTS ((SELECT 1 FROM sel_muni s WHERE s.muni_id = n.muni_id))
		AND NOT (
			EXISTS (
				SELECT 1
				FROM node_psector np
				WHERE np.node_id = n.node_id AND np.p_state = 0
			)
		)
		UNION ALL
		SELECT np.node_id
		FROM node_psector np
		WHERE np.p_state = 1
    ),
    node_selected AS (
		SELECT
			node.node_id,
			node.code,
			node.sys_code,
			node.top_elev,
			node.custom_top_elev,
			CASE
				WHEN node.custom_top_elev IS NOT NULL THEN node.custom_top_elev
				ELSE node.top_elev
			END AS sys_top_elev,
			node.depth,
			cat_node.node_type,
			cat_feature.feature_class AS sys_type,
			node.nodecat_id,
			cat_node.matcat_id AS cat_matcat_id,
			cat_node.pnom AS cat_pnom,
			cat_node.dnom AS cat_dnom,
			cat_node.dint AS cat_dint,
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
			node.supplyzone_id,
			supplyzone_table.supplyzone_type,
			node.presszone_id,
			presszone_table.presszone_type,
			presszone_table.presszone_head,
			node.dma_id,
			dma_table.macrodma_id,
			dma_table.dma_type,
			node.dqa_id,
			dqa_table.macrodqa_id,
			dqa_table.dqa_type,
			node.omzone_id,
			omzone_table.macroomzone_id,
			omzone_table.omzone_type,
			node.minsector_id,
			node.pavcat_id,
			node.soilcat_id,
			node.function_type,
			node.category_type,
			node.location_type,
			node.fluid_type,
			node.staticpressure,
			node.annotation,
			node.observ,
			node.comment,
			node.descript,
			concat(cat_feature.link_path, node.link) AS link,
			node.num_value,
			node.district_id,
			streetaxis_id,
			node.postcode,
			node.postnumber,
			node.postcomplement,
			streetaxis2_id,
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
			node.accessibility,
			node.om_state,
			node.conserv_state,
			node.access_type,
			node.placement_type,
			CASE
			WHEN node.brand_id IS NULL THEN cat_node.brand_id
			ELSE node.brand_id
			END AS brand_id,
			CASE
			WHEN node.model_id IS NULL THEN cat_node.model_id
			ELSE node.model_id
			END AS model_id,
			node.serial_number,
			node.asset_id,
			node.adate,
			node.adescript,
			node.verified,
			node.datasource,
			node.hemisphere,
			cat_node.label,
			node.label_x,
			node.label_y,
			node.label_rotation,
			node.rotation,
			node.label_quadrant,
			cat_node.svg,
			node.inventory,
			node.publish,
			vst.is_operative,
			node.is_scadamap,
			CASE
			WHEN node.sector_id > 0 AND vst.is_operative = true AND node.epa_type::text <> 'UNDEFINED'::text THEN node.epa_type
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
			node.lock_level,
			node.expl_visibility,
			(SELECT ST_X(node.the_geom)) AS xcoord,
			(SELECT ST_Y(node.the_geom)) AS ycoord,
			(SELECT ST_Y(ST_Transform(node.the_geom, 4326))) AS lat,
			(SELECT ST_X(ST_Transform(node.the_geom, 4326))) AS long,
			m.closed as closed_valve,
			m.broken as broken_valve,
			date_trunc('second'::text, node.created_at) AS created_at,
			node.created_by,
			date_trunc('second'::text, node.updated_at) AS updated_at,
			node.updated_by,
			node.the_geom
			FROM node_selector
			JOIN node ON node.node_id = node_selector.node_id
			JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
			JOIN cat_feature ON cat_feature.id::text = cat_node.node_type::text
			JOIN value_state_type vst ON vst.id = node.state_type
			JOIN exploitation ON node.expl_id = exploitation.expl_id
			JOIN ext_municipality mu ON node.muni_id = mu.muni_id
			JOIN sector_table ON sector_table.sector_id = node.sector_id
			LEFT JOIN presszone_table ON presszone_table.presszone_id = node.presszone_id
			LEFT JOIN dma_table ON dma_table.dma_id = node.dma_id
			LEFT JOIN dqa_table ON dqa_table.dqa_id = node.dqa_id
			LEFT JOIN supplyzone_table ON supplyzone_table.supplyzone_id = node.supplyzone_id
			LEFT JOIN omzone_table ON omzone_table.omzone_id = node.omzone_id
			LEFT JOIN node_add ON node_add.node_id = node.node_id
			LEFT JOIN man_valve m ON m.node_id = node.node_id
	)
    SELECT n.*
    FROM node_selected n;

CREATE OR REPLACE VIEW v_edit_link
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
    link_psector AS (
        SELECT DISTINCT ON (pp.connec_id, pp.state) 'CONNEC' AS feature_type, pp.connec_id AS feature_id, pp.state AS p_state, pp.psector_id, pp.link_id
        FROM plan_psector_x_connec pp
        JOIN selector_psector sp ON sp.cur_user = current_user AND sp.psector_id = pp.psector_id
        ORDER BY pp.connec_id, pp.state, pp.link_id DESC NULLS LAST
	),
    link_selector AS (
        SELECT l.link_id
        FROM link l
		WHERE EXISTS ((SELECT 1 FROM sel_state s WHERE s.state_id = l.state))
		AND EXISTS ((SELECT 1 FROM sel_sector s WHERE s.sector_id = l.sector_id))
		AND EXISTS ((SELECT 1 FROM sel_expl s WHERE s.expl_id = ANY (array_append(expl_visibility, l.expl_id))))
		AND EXISTS ((SELECT 1 FROM sel_muni s WHERE s.muni_id = l.muni_id))
		AND NOT (
			EXISTS (
				SELECT 1
				FROM link_psector lp
				WHERE lp.link_id = l.link_id AND lp.p_state = 0
			)
		)
		UNION ALL
		SELECT lp.link_id
		FROM link_psector lp
		WHERE lp.p_state = 1
    ),
    link_selected AS (
        SELECT
			l.link_id,
			l.code,
			l.sys_code,
			l.top_elev1,
			l.depth1,
			CASE
			WHEN l.top_elev1 IS NULL OR l.depth1 IS NULL THEN NULL
			ELSE (l.top_elev1 - l.depth1)
			END AS elevation1,
			l.exit_id,
			l.exit_type,
			l.top_elev2,
			l.depth2,
			CASE
			WHEN l.top_elev2 IS NULL OR l.depth2 IS NULL THEN NULL
			ELSE (l.top_elev2 - l.depth2)
			END AS elevation2,
			l.feature_type,
			l.feature_id,
			cat_link.link_type,
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
			l.verified,
			l.uncertain,
			l.userdefined_geom,
			l.datasource,
			l.is_operative,
			CASE
			WHEN l.sector_id > 0 AND l.is_operative = true AND c.epa_type = 'JUNCTION'::text AND inp_network_mode.value = '4'::text
			THEN c.epa_type::text
			ELSE NULL::text
			END AS inp_type,
			l.lock_level,
			l.expl_visibility,
			l.created_at,
			l.created_by,
			l.updated_at,
			l.updated_by,
			l.the_geom
			FROM link_selector
			JOIN link l ON l.link_id = link_selector.link_id
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
			LEFT JOIN inp_network_mode ON true
	)
    SELECT l.*
    FROM link_selected l;

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
			connec.plot_code,
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
		LEFT JOIN crmzone ON crmzone.id::text = connec.crmzone_id::text
		LEFT JOIN link_planned USING (link_id)
		LEFT JOIN connec_add ON connec_add.connec_id = connec.connec_id
		LEFT JOIN value_state_type vst ON vst.id = connec.state_type
		LEFT JOIN inp_network_mode ON true
	)
    SELECT c.*
    FROM connec_selected c;
-- ===============================

ALTER VIEW v_edit_anl_hydrant RENAME TO ve_anl_hydrant;
ALTER VIEW v_edit_cad_auxcircle RENAME TO ve_cad_auxcircle;
ALTER VIEW v_edit_cad_auxline RENAME TO ve_cad_auxline;
ALTER VIEW v_edit_cad_auxpoint RENAME TO ve_cad_auxpoint;
ALTER VIEW v_edit_cat_dscenario RENAME TO ve_cat_dscenario;
ALTER VIEW v_edit_cat_feature_arc RENAME TO ve_cat_feature_arc;
ALTER VIEW v_edit_cat_feature_connec RENAME TO ve_cat_feature_connec;
ALTER VIEW v_edit_cat_feature_element RENAME TO ve_cat_feature_element;
ALTER VIEW v_edit_cat_feature_link RENAME TO ve_cat_feature_link;
ALTER VIEW v_edit_cat_feature_node RENAME TO ve_cat_feature_node;
ALTER VIEW v_edit_dimensions RENAME TO ve_dimensions;
ALTER VIEW v_edit_dma RENAME TO ve_dma;
ALTER VIEW v_edit_dqa RENAME TO ve_dqa;
ALTER VIEW v_edit_exploitation RENAME TO ve_exploitation;
ALTER VIEW v_edit_inp_connec RENAME TO ve_inp_connec;
ALTER VIEW v_edit_inp_controls RENAME TO ve_inp_controls;
ALTER VIEW v_edit_inp_curve RENAME TO ve_inp_curve;
ALTER VIEW v_edit_inp_curve_value RENAME TO ve_inp_curve_value;
ALTER VIEW v_edit_inp_dscenario_connec RENAME TO ve_inp_dscenario_connec;
ALTER VIEW v_edit_inp_dscenario_controls RENAME TO ve_inp_dscenario_controls;
ALTER VIEW v_edit_inp_dscenario_demand RENAME TO ve_inp_dscenario_demand;
ALTER VIEW v_edit_inp_dscenario_frvalve RENAME TO ve_inp_dscenario_frvalve;
ALTER VIEW v_edit_inp_dscenario_inlet RENAME TO ve_inp_dscenario_inlet;
ALTER VIEW v_edit_inp_dscenario_junction RENAME TO ve_inp_dscenario_junction;
ALTER VIEW v_edit_inp_dscenario_pipe RENAME TO ve_inp_dscenario_pipe;
ALTER VIEW v_edit_inp_dscenario_pump RENAME TO ve_inp_dscenario_pump;
ALTER VIEW v_edit_inp_dscenario_pump_additional RENAME TO ve_inp_dscenario_pump_additional;
ALTER VIEW v_edit_inp_dscenario_reservoir RENAME TO ve_inp_dscenario_reservoir;
ALTER VIEW v_edit_inp_dscenario_rules RENAME TO ve_inp_dscenario_rules;
ALTER VIEW v_edit_inp_dscenario_shortpipe RENAME TO ve_inp_dscenario_shortpipe;
ALTER VIEW v_edit_inp_dscenario_tank RENAME TO ve_inp_dscenario_tank;
ALTER VIEW v_edit_inp_dscenario_valve RENAME TO ve_inp_dscenario_valve;
ALTER VIEW v_edit_inp_dscenario_virtualpump RENAME TO ve_inp_dscenario_virtualpump;
ALTER VIEW v_edit_inp_dscenario_virtualvalve RENAME TO ve_inp_dscenario_virtualvalve;
ALTER VIEW v_edit_inp_frvalve RENAME TO ve_inp_frvalve;
ALTER VIEW v_edit_inp_inlet RENAME TO ve_inp_inlet;
ALTER VIEW v_edit_inp_junction RENAME TO ve_inp_junction;
ALTER VIEW v_edit_inp_pattern RENAME TO ve_inp_pattern;
ALTER VIEW v_edit_inp_pattern_value RENAME TO ve_inp_pattern_value;
ALTER VIEW v_edit_inp_pipe RENAME TO ve_inp_pipe;
ALTER VIEW v_edit_inp_pump RENAME TO ve_inp_pump;
ALTER VIEW v_edit_inp_pump_additional RENAME TO ve_inp_pump_additional;
ALTER VIEW v_edit_inp_reservoir RENAME TO ve_inp_reservoir;
ALTER VIEW v_edit_inp_rules RENAME TO ve_inp_rules;
ALTER VIEW v_edit_inp_shortpipe RENAME TO ve_inp_shortpipe;
ALTER VIEW v_edit_inp_tank RENAME TO ve_inp_tank;
ALTER VIEW v_edit_inp_valve RENAME TO ve_inp_valve;
ALTER VIEW v_edit_inp_virtualpump RENAME TO ve_inp_virtualpump;
ALTER VIEW v_edit_inp_virtualvalve RENAME TO ve_inp_virtualvalve;
ALTER VIEW v_edit_macrodma RENAME TO ve_macrodma;
ALTER VIEW v_edit_macrodqa RENAME TO ve_macrodqa;
ALTER VIEW v_edit_macroexploitation RENAME TO ve_macroexploitation;
ALTER VIEW v_edit_macroomzone RENAME TO ve_macroomzone;
ALTER VIEW v_edit_macrosector RENAME TO ve_macrosector;
ALTER VIEW v_edit_minsector RENAME TO ve_minsector;
ALTER VIEW v_edit_minsector_mincut RENAME TO ve_minsector_mincut;
ALTER VIEW v_edit_om_visit RENAME TO ve_om_visit;
ALTER VIEW v_edit_omzone RENAME TO ve_omzone;
ALTER VIEW v_edit_plan_netscenario_dma RENAME TO ve_plan_netscenario_dma;
ALTER VIEW v_edit_plan_netscenario_presszone RENAME TO ve_plan_netscenario_presszone;
ALTER VIEW v_edit_plan_netscenario_valve RENAME TO ve_plan_netscenario_valve;
ALTER VIEW v_edit_plan_psector_x_connec RENAME TO ve_plan_psector_x_connec;
ALTER VIEW v_edit_plan_psector_x_other RENAME TO ve_plan_psector_x_other;
ALTER VIEW v_edit_presszone RENAME TO ve_presszone;
ALTER VIEW v_edit_review_arc RENAME TO ve_review_arc;
ALTER VIEW v_edit_review_audit_arc RENAME TO ve_review_audit_arc;
ALTER VIEW v_edit_review_audit_connec RENAME TO ve_review_audit_connec;
ALTER VIEW v_edit_review_audit_node RENAME TO ve_review_audit_node;
ALTER VIEW v_edit_review_connec RENAME TO ve_review_connec;
ALTER VIEW v_edit_review_node RENAME TO ve_review_node;
ALTER VIEW v_edit_rtc_hydro_data_x_connec RENAME TO ve_rtc_hydro_data_x_connec;
ALTER VIEW v_edit_samplepoint RENAME TO ve_samplepoint;
ALTER VIEW v_edit_sector RENAME TO ve_sector;
ALTER VIEW v_edit_supplyzone RENAME TO ve_supplyzone;

DROP VIEW IF EXISTS ve_plan_psector_x_connec;
DROP VIEW IF EXISTS v_value_cat_connec;
DROP VIEW IF EXISTS v_value_cat_node;

DROP VIEW IF EXISTS vcp_pipes;
DROP VIEW IF EXISTS vcv_dma;
DROP VIEW IF EXISTS vcv_dma_log;
DROP VIEW IF EXISTS vcv_emitters_log;
DROP VIEW IF EXISTS vcv_junction;

CREATE OR REPLACE VIEW ve_inp_frpump
AS SELECT f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
	p.power,
    p.curve_id,
	p.speed,
	p.pattern_id,
	p.pump_type,
	p.effic_curve_id,
	p.energy_price,
	p.energy_pattern_id,
    p.status,
    f.the_geom
   FROM ve_man_frelem f
     JOIN inp_frpump p ON f.element_id = p.element_id;

CREATE OR REPLACE VIEW ve_inp_frshortpipe
AS SELECT f.element_id,
    f.node_id,
    f.to_arc,
    f.flwreg_length,
	p.minorloss,
    p.bulk_coeff,
	p.wall_coeff,
	p.custom_dint,
	p.status,
    f.the_geom
   FROM ve_man_frelem f
     JOIN inp_frshortpipe p ON f.element_id = p.element_id;


CREATE OR REPLACE VIEW ve_epa_frpump
AS SELECT p.element_id,
    man_frelem.node_id,
    man_frelem.to_arc,
	p.power,
    p.curve_id,
	p.speed,
	p.pattern_id,
	p.pump_type,
	p.energyparam,
	p.energyvalue,
	p.effic_curve_id,
	p.energy_price,
	p.energy_pattern_id,
    p.status,
	r.result_id,
    r.flow_max as flowmax,
    r.flow_min as flowmin,
    r.flow_avg as flowavg,
    r.vel_max as velmax,
    r.vel_min as velmin,
    r.vel_avg as velavg,
    r.headloss_max,
    r.headloss_min,
    r.setting_max,
    r.setting_min,
    r.reaction_max,
    r.reaction_min,
    r.ffactor_max,
    r.ffactor_min
   FROM inp_frpump p
     LEFT JOIN man_frelem USING (element_id)
     LEFT JOIN v_rpt_arc_stats r ON r.arc_id::text = man_frelem.element_id::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_frpump
AS SELECT s.dscenario_id,
    f.element_id,
	n.node_id,
	f.power,
    f.curve_id,
	f.speed,
	f.pattern_id,
	f.effic_curve_id,
	f.energy_price,
	f.energy_pattern_id,
    f.status,
    n.the_geom
   FROM selector_inp_dscenario s,
    inp_dscenario_frpump f
     JOIN ve_inp_frpump n USING (element_id)
  WHERE s.dscenario_id = f.dscenario_id AND s.cur_user = CURRENT_USER::text;

DROP VIEW IF EXISTS ve_inp_dscenario_frvalve;
CREATE OR REPLACE VIEW ve_inp_dscenario_frvalve
AS SELECT s.dscenario_id,
    v.element_id,
    n.node_id,
    v.valve_type,
    v.custom_dint,
    v.setting,
    v.curve_id,
    v.minorloss,
    v.add_settings,
    v.init_quality,
    n.the_geom
   FROM selector_inp_dscenario s,
    inp_dscenario_frvalve v
     JOIN ve_inp_frvalve n ON n.element_id = v.element_id
  WHERE s.dscenario_id = v.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_inp_dscenario_frshortpipe
AS SELECT s.dscenario_id,
    p.element_id,
	n.node_id,
    p.minorloss,
    p.bulk_coeff,
    p.wall_coeff,
    p.custom_dint,
    p.status,
    n.the_geom
   FROM selector_inp_dscenario s,
    inp_dscenario_frshortpipe p
     JOIN ve_inp_frshortpipe n ON n.element_id = p.element_id
  WHERE s.dscenario_id = p.dscenario_id AND s.cur_user = CURRENT_USER::text;

CREATE OR REPLACE VIEW ve_samplepoint
AS SELECT sm.sample_id,
    sm.code,
    sm.lab_code,
    sm.feature_id,
    sm.featurecat_id,
    sm.dma_id,
    sm.macrodma_id,
    sm.presszone_id,
    sm.state,
    sm.builtdate,
    sm.enddate,
    sm.workcat_id,
    sm.workcat_id_end,
    sm.rotation,
    sm.muni_id,
    sm.streetaxis_id,
    sm.postnumber,
    sm.postcode,
    sm.district_id,
    sm.streetaxis2_id,
    sm.postnumber2,
    sm.postcomplement,
    sm.postcomplement2,
    sm.place_name,
    sm.cabinet,
    sm.observations,
    sm.verified,
    sm.the_geom,
    sm.expl_id,
    sm.link,
    sm.sector_id
   FROM ( SELECT samplepoint.sample_id,
            samplepoint.code,
            samplepoint.lab_code,
            samplepoint.feature_id,
            samplepoint.featurecat_id,
            samplepoint.dma_id,
            dma.macrodma_id,
            samplepoint.presszone_id,
            samplepoint.state,
            samplepoint.builtdate,
            samplepoint.enddate,
            samplepoint.workcat_id,
            samplepoint.workcat_id_end,
            samplepoint.rotation,
            samplepoint.muni_id,
            samplepoint.streetaxis_id,
            samplepoint.postnumber,
            samplepoint.postcode,
            samplepoint.district_id,
            samplepoint.streetaxis2_id,
            samplepoint.postnumber2,
            samplepoint.postcomplement,
            samplepoint.postcomplement2,
            samplepoint.place_name,
            samplepoint.cabinet,
            samplepoint.observations,
            samplepoint.verified,
            samplepoint.the_geom,
            samplepoint.expl_id,
            samplepoint.link,
            samplepoint.sector_id
             FROM selector_expl,
            samplepoint
             LEFT JOIN dma ON dma.dma_id = samplepoint.dma_id
          WHERE samplepoint.expl_id = selector_expl.expl_id AND selector_expl.cur_user = "current_user"()::text) sm
     JOIN selector_sector s USING (sector_id)
     LEFT JOIN selector_municipality m USING (muni_id)
  WHERE s.cur_user = CURRENT_USER AND (m.cur_user = CURRENT_USER OR sm.muni_id IS NULL);



  CREATE OR REPLACE VIEW ve_dimensions AS
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
DROP VIEW IF EXISTS v_state_samplepoint;
DROP VIEW IF EXISTS v_rpt_arc;
DROP VIEW IF EXISTS v_rpt_arc_hourly;

DROP VIEW IF EXISTS ve_epa_pump;
DROP VIEW IF EXISTS ve_epa_pump_additional;
DROP VIEW IF EXISTS ve_epa_valve;
DROP VIEW IF EXISTS ve_epa_shortpipe;
DROP VIEW IF EXISTS ve_epa_pipe;
DROP VIEW IF EXISTS ve_epa_virtualvalve;
DROP VIEW IF EXISTS ve_epa_virtualpump;
DROP VIEW IF EXISTS ve_epa_frpump;
DROP VIEW IF EXISTS v_rpt_arc_stats;

DROP VIEW IF EXISTS v_rpt_node;
DROP VIEW IF EXISTS v_rpt_node_hourly;

DROP VIEW IF EXISTS ve_epa_junction;
DROP VIEW IF EXISTS ve_epa_tank;
DROP VIEW IF EXISTS ve_epa_reservoir;
DROP VIEW IF EXISTS ve_epa_connec;
DROP VIEW IF EXISTS ve_epa_inlet;
DROP VIEW IF EXISTS v_rpt_node_stats;


CREATE OR REPLACE VIEW v_rpt_arc
AS SELECT rpt_arc.id,
    arc.arc_id,
    selector_rpt_main.result_id,
    rpt_cat_result.flow_units,
    rpt_cat_result.quality_units,
    arc.arc_type,
    arc.sector_id,
    arc.arccat_id,
    rpt_arc.flow,
    rpt_arc.vel,
    rpt_arc.headloss,
    rpt_arc.setting,
    rpt_arc.ffactor,
    now()::date + rpt_arc."time"::interval AS "time",
    rpt_arc.length,
    rpt_arc.headloss * rpt_arc.length / 1000::numeric AS tot_headloss,
	arc.diameter,
    arc.the_geom
   FROM selector_rpt_main
	 JOIN rpt_inp_arc arc ON arc.result_id::text = selector_rpt_main.result_id::text
     JOIN rpt_arc ON rpt_arc.arc_id::text = arc.arc_id::TEXT AND rpt_arc.result_id::text = selector_rpt_main.result_id::text
     JOIN rpt_cat_result ON rpt_cat_result.result_id::text = selector_rpt_main.result_id::text
  WHERE selector_rpt_main.cur_user = CURRENT_USER
  ORDER BY rpt_arc.setting, arc.arc_id;


CREATE OR REPLACE VIEW v_rpt_arc_hourly
AS SELECT rpt_arc.id,
    arc.arc_id,
    arc.sector_id,
    selector_rpt_main.result_id,
	rpt_cat_result.flow_units,
	rpt_cat_result.quality_units,
    rpt_arc.flow,
    rpt_arc.vel,
    rpt_arc.headloss,
    rpt_arc.setting,
    rpt_arc.ffactor,
    rpt_arc."time",
	arc.diameter,
    arc.the_geom
   FROM selector_rpt_main
     JOIN rpt_inp_arc arc ON arc.result_id::text = selector_rpt_main.result_id::text
     JOIN rpt_arc ON rpt_arc.arc_id::text = arc.arc_id::text AND rpt_arc.result_id::text = selector_rpt_main.result_id::text
	 JOIN selector_rpt_main_tstep ON selector_rpt_main_tstep.timestep::text = rpt_arc."time"::text
	 JOIN rpt_cat_result ON rpt_cat_result.result_id::text = selector_rpt_main.result_id::text
  WHERE selector_rpt_main.cur_user = CURRENT_USER AND selector_rpt_main_tstep.cur_user = CURRENT_USER
  ORDER BY rpt_arc."time", arc.arc_id;


CREATE OR REPLACE VIEW v_rpt_arc_stats
AS SELECT r.arc_id,
    r.result_id,
	rpt_cat_result.flow_units,
	rpt_cat_result.quality_units,
    r.arc_type,
    r.sector_id,
    r.arccat_id,
    r.flow_max,
    r.flow_min,
    r.flow_avg,
    r.vel_max,
    r.vel_min,
    r.vel_avg,
    r.headloss_max,
    r.headloss_min,
    r.setting_max,
    r.setting_min,
    r.reaction_max,
    r.reaction_min,
    r.ffactor_max,
    r.ffactor_min,
    r.length,
    r.tot_headloss_max,
    r.tot_headloss_min,
	arc.diameter,
    r.the_geom
   FROM rpt_arc_stats r
    JOIN selector_rpt_main s ON s.result_id::text = r.result_id::text
	JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text
	JOIN rpt_cat_result ON rpt_cat_result.result_id::text = s.result_id::text
  WHERE s.cur_user = CURRENT_USER;


CREATE OR REPLACE VIEW v_rpt_node
AS SELECT rpt_node.id,
    node.node_id,
    node.node_type,
    node.sector_id,
    node.nodecat_id,
    selector_rpt_main.result_id,
	rpt_cat_result.flow_units,
    rpt_node.top_elev,
    rpt_node.demand,
    rpt_node.head,
    rpt_node.press,
	rpt_cat_result.quality_units,
    rpt_node.quality,
    '2001-01-01'::date + rpt_node."time"::interval AS "time",
    node.the_geom
   FROM selector_rpt_main
     JOIN rpt_inp_node node ON node.result_id::text = selector_rpt_main.result_id::text
     JOIN rpt_node ON rpt_node.node_id::text = node.node_id::text AND rpt_node.result_id::text = selector_rpt_main.result_id::text
	 JOIN rpt_cat_result ON rpt_cat_result.result_id::text = selector_rpt_main.result_id::text
  WHERE selector_rpt_main.cur_user = CURRENT_USER
  ORDER BY rpt_node.press, node.node_id;


CREATE OR REPLACE VIEW v_rpt_node_hourly
AS SELECT rpt_node.id,
    node.node_id,
    node.sector_id,
    selector_rpt_main.result_id,
	rpt_cat_result.flow_units,
    rpt_node.top_elev AS elevation,
    rpt_node.demand,
    rpt_node.head,
    rpt_node.press,
	rpt_cat_result.quality_units,
    rpt_node.quality,
    rpt_node."time",
    node.the_geom
   FROM selector_rpt_main
     JOIN rpt_inp_node node ON node.result_id::text = selector_rpt_main.result_id::text
	 JOIN rpt_node ON rpt_node.node_id::text = node.node_id::text AND rpt_node.result_id::text = selector_rpt_main.result_id::text
     JOIN selector_rpt_main_tstep ON selector_rpt_main_tstep.timestep::text = rpt_node."time"::text
	 JOIN rpt_cat_result ON rpt_cat_result.result_id::text = selector_rpt_main.result_id::text
  WHERE selector_rpt_main.cur_user = CURRENT_USER AND selector_rpt_main_tstep.cur_user = CURRENT_USER
  ORDER BY rpt_node."time", node.node_id;



CREATE OR REPLACE VIEW v_rpt_node_stats
AS SELECT r.node_id,
    r.result_id,
	rpt_cat_result.flow_units,
    r.node_type,
    r.sector_id,
    r.nodecat_id,
    r.top_elev,
    r.demand_max,
    r.demand_min,
    r.demand_avg,
    r.head_max,
    r.head_min,
    r.head_avg,
    r.press_max,
    r.press_min,
    r.press_avg,
	rpt_cat_result.quality_units,
    r.quality_max,
    r.quality_min,
    r.quality_avg,
    r.the_geom
   FROM rpt_node_stats r
    JOIN selector_rpt_main s ON s.result_id::text = r.result_id::text
	JOIN rpt_cat_result ON rpt_cat_result.result_id::text = s.result_id::text
  WHERE s.cur_user = CURRENT_USER;


DROP VIEW IF EXISTS v_rpt_comp_arc;
CREATE OR REPLACE VIEW v_rpt_comp_arc
AS WITH main AS (
         SELECT r.arc_id,
            r.result_id,
            r.arc_type,
            r.sector_id,
            r.arccat_id,
            r.flow_max,
            r.flow_min,
            r.flow_avg,
            r.vel_max,
            r.vel_min,
            r.vel_avg,
            r.headloss_max,
            r.headloss_min,
            r.setting_max,
            r.setting_min,
            r.reaction_max,
            r.reaction_min,
            r.ffactor_max,
            r.ffactor_min,
			arc.diameter,
            r.the_geom
           FROM rpt_arc_stats r
		    JOIN selector_rpt_main s ON s.result_id::text = r.result_id::text
			JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text
          WHERE s.cur_user = CURRENT_USER
        ), compare AS (
         SELECT r.arc_id,
            r.result_id,
            r.arc_type,
            r.sector_id,
            r.arccat_id,
            r.flow_max,
            r.flow_min,
            r.flow_avg,
            r.vel_max,
            r.vel_min,
            r.vel_avg,
            r.headloss_max,
            r.headloss_min,
            r.setting_max,
            r.setting_min,
            r.reaction_max,
            r.reaction_min,
            r.ffactor_max,
            r.ffactor_min,
			arc.diameter,
            r.the_geom
           FROM rpt_arc_stats r
		    JOIN selector_rpt_compare s ON s.result_id::text = r.result_id::text
			JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text
          WHERE s.cur_user = CURRENT_USER
        )
 SELECT main.arc_id,
    main.arc_type,
    main.sector_id,
    main.arccat_id,
    main.result_id AS main_result,
    compare.result_id AS compare_result,
    main.flow_max AS flow_max_main,
    compare.flow_max AS flow_max_compare,
    main.flow_max - compare.flow_max AS flow_max_diff,
    main.flow_min AS flow_min_main,
    compare.flow_min AS flow_min_compare,
    main.flow_min - compare.flow_min AS flow_min_diff,
    main.flow_avg AS flow_avg_main,
    compare.flow_avg AS flow_avg_compare,
    main.flow_avg - compare.flow_avg AS flow_avg_diff,
    main.vel_max AS vel_max_main,
    compare.vel_max AS vel_max_compare,
    main.vel_max - compare.vel_max AS vel_max_diff,
    main.vel_min AS vel_min_main,
    compare.vel_min AS vel_min_compare,
    main.vel_min - compare.vel_min AS vel_min_diff,
    main.vel_avg AS vel_avg_main,
    compare.vel_avg AS vel_avg_compare,
    main.vel_avg - compare.vel_avg AS vel_avg_diff,
    main.headloss_max AS headloss_max_main,
    compare.headloss_max AS headloss_max_compare,
    main.headloss_max - compare.headloss_max AS headloss_max_diff,
    main.headloss_min AS headloss_min_main,
    compare.headloss_min AS headloss_min_compare,
    main.headloss_min - compare.headloss_min AS headloss_min_diff,
    main.setting_max AS setting_max_main,
    compare.setting_max AS setting_max_compare,
    main.setting_max - compare.setting_max AS setting_max_diff,
    main.setting_min AS setting_min_main,
    compare.setting_min AS setting_min_compare,
    main.setting_min - compare.setting_min AS setting_min_diff,
    main.reaction_max AS reaction_max_main,
    compare.reaction_max AS reaction_max_compare,
    main.reaction_max - compare.reaction_max AS reaction_max_diff,
    main.reaction_min AS reaction_min_main,
    compare.reaction_min AS reaction_min_compare,
    main.reaction_min - compare.reaction_min AS reaction_min_diff,
    main.ffactor_max AS ffactor_max_main,
    compare.ffactor_max AS ffactor_max_compare,
    main.ffactor_max - compare.ffactor_max AS ffactor_max_diff,
    main.ffactor_min AS ffactor_min_main,
    compare.ffactor_min AS ffactor_min_compare,
    main.ffactor_min - compare.ffactor_min AS ffactor_min_diff,
	main.diameter AS diameter_main,
	compare.diameter AS diameter_compare,
	main.diameter - compare.diameter AS diameter_diff,
    main.the_geom
   FROM main
     JOIN compare ON main.arc_id::text = compare.arc_id::text;


DROP VIEW IF EXISTS v_rpt_comp_arc_hourly;
CREATE OR REPLACE VIEW v_rpt_comp_arc_hourly
AS WITH main AS (
         SELECT rpt_arc.id,
            arc.arc_id,
            arc.sector_id,
            selector_rpt_main.result_id,
            rpt_arc.flow,
            rpt_arc.vel,
            rpt_arc.headloss,
            rpt_arc.setting,
            rpt_arc.ffactor,
            rpt_arc."time",
			arc.diameter,
            arc.the_geom
           FROM selector_rpt_main
		     JOIN rpt_inp_arc arc ON arc.result_id::text = selector_rpt_main.result_id::text
             JOIN rpt_arc ON rpt_arc.arc_id::text = arc.arc_id::text AND rpt_arc.result_id::text = selector_rpt_main.result_id::text
			 JOIN selector_rpt_main_tstep ON selector_rpt_main_tstep.timestep::text = rpt_arc."time"::text
          WHERE selector_rpt_main.cur_user = CURRENT_USER AND selector_rpt_main_tstep.cur_user = CURRENT_USER
        ), compare AS (
         SELECT rpt_arc.id,
            arc.arc_id,
            arc.sector_id,
            selector_rpt_compare.result_id,
            rpt_arc.flow,
            rpt_arc.vel,
            rpt_arc.headloss,
            rpt_arc.setting,
            rpt_arc.ffactor,
            rpt_arc."time",
			arc.diameter,
            arc.the_geom
           FROM selector_rpt_compare
		     JOIN rpt_inp_arc arc ON arc.result_id::text = selector_rpt_compare.result_id::text
             JOIN rpt_arc ON rpt_arc.arc_id::text = arc.arc_id::text AND rpt_arc.result_id::text = selector_rpt_compare.result_id::text
			 JOIN selector_rpt_compare_tstep ON selector_rpt_compare_tstep.timestep::text = rpt_arc."time"::text
          WHERE selector_rpt_compare.cur_user = CURRENT_USER AND selector_rpt_compare_tstep.cur_user = CURRENT_USER
        )
 SELECT main.arc_id,
    main.sector_id,
    main.result_id AS result_id_main,
    compare.result_id AS result_id_compare,
    main."time" AS time_main,
    compare."time" AS time_compare,
    main.flow AS flow_main,
    compare.flow AS flow_compare,
    main.flow - compare.flow AS flow_diff,
    main.vel AS vel_main,
    compare.vel AS vel_compare,
    main.vel - compare.vel AS vel_diff,
    main.headloss AS headloss_main,
    compare.headloss AS headloss_compare,
    main.headloss - compare.headloss AS headloss_diff,
    main.setting AS setting_main,
    compare.setting AS setting_compare,
    main.setting - compare.setting AS setting_diff,
    main.ffactor AS ffactor_main,
    compare.ffactor AS ffactor_compare,
    main.ffactor - compare.ffactor AS ffactor_diff,
	main.diameter AS diameter_main,
	compare.diameter AS diameter_compare,
	main.diameter - compare.diameter AS diameter_diff,
    main.the_geom
   FROM main
     JOIN compare ON main.arc_id::text = compare.arc_id::text;




DROP VIEW IF EXISTS v_rpt_comp_arc_stats;
CREATE OR REPLACE VIEW v_rpt_comp_arc_stats
AS WITH main AS (
		SELECT r.arc_id,
			r.result_id,
			r.arc_type,
			r.sector_id,
			r.arccat_id,
			r.flow_max,
			r.flow_min,
			r.flow_avg,
			r.vel_max,
			r.vel_min,
			r.vel_avg,
			r.headloss_max,
			r.headloss_min,
			r.setting_max,
			r.setting_min,
			r.reaction_max,
			r.reaction_min,
			r.ffactor_max,
			r.ffactor_min,
			r.length,
			r.tot_headloss_max,
			r.tot_headloss_min,
			arc.diameter,
			r.the_geom
		FROM rpt_arc_stats r
			JOIN selector_rpt_main s ON s.result_id::text = r.result_id::text
			JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text
		WHERE s.cur_user = CURRENT_USER
        ), compare AS (
         SELECT r.arc_id,
			r.result_id,
			r.arc_type,
			r.sector_id,
			r.arccat_id,
			r.flow_max,
			r.flow_min,
			r.flow_avg,
			r.vel_max,
			r.vel_min,
			r.vel_avg,
			r.headloss_max,
			r.headloss_min,
			r.setting_max,
			r.setting_min,
			r.reaction_max,
			r.reaction_min,
			r.ffactor_max,
			r.ffactor_min,
			r.length,
			r.tot_headloss_max,
			r.tot_headloss_min,
			arc.diameter,
			r.the_geom
		FROM rpt_arc_stats r
			JOIN selector_rpt_compare s ON s.result_id::text = r.result_id::text
			JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text
		WHERE s.cur_user = CURRENT_USER
        )
 SELECT main.arc_id,
	main.arc_type,
    main.sector_id,
	main.arccat_id,
    main.result_id AS result_id_main,
    compare.result_id AS result_id_compare,
    main.flow_max AS flow_max_main,
    compare.flow_max AS flow_max_compare,
    main.flow_max - compare.flow_max AS flow_max_diff,
    main.flow_min AS flow_min_main,
    compare.flow_min AS flow_min_compare,
    main.flow_min - compare.flow_min AS flow_min_diff,
    main.flow_avg AS flow_avg_main,
    compare.flow_avg AS flow_avg_compare,
    main.flow_avg - compare.flow_avg AS flow_avg_diff,
    main.vel_max AS vel_max_main,
    compare.vel_max AS vel_max_compare,
    main.vel_max - compare.vel_max AS vel_max_diff,
    main.vel_min AS vel_min_main,
    compare.vel_min AS vel_min_compare,
    main.vel_min - compare.vel_min AS vel_min_diff,
    main.vel_avg AS vel_avg_main,
    compare.vel_avg AS vel_avg_compare,
    main.vel_avg - compare.vel_avg AS vel_avg_diff,
    main.headloss_max AS headloss_max_main,
    compare.headloss_max AS headloss_max_compare,
    main.headloss_max - compare.headloss_max AS headloss_max_diff,
    main.headloss_min AS headloss_min_main,
    compare.headloss_min AS headloss_min_compare,
    main.headloss_min - compare.headloss_min AS headloss_min_diff,
    main.setting_max AS setting_max_main,
    compare.setting_max AS setting_max_compare,
    main.setting_max - compare.setting_max AS setting_max_diff,
    main.setting_min AS setting_min_main,
    compare.setting_min AS setting_min_compare,
    main.setting_min - compare.setting_min AS setting_min_diff,
    main.reaction_max AS reaction_max_main,
    compare.reaction_max AS reaction_max_compare,
    main.reaction_max - compare.reaction_max AS reaction_max_diff,
    main.reaction_min AS reaction_min_main,
    compare.reaction_min AS reaction_min_compare,
    main.reaction_min - compare.reaction_min AS reaction_min_diff,
    main.ffactor_max AS ffactor_max_main,
    compare.ffactor_max AS ffactor_max_compare,
    main.ffactor_max - compare.ffactor_max AS ffactor_max_diff,
	main.ffactor_min AS ffactor_min_main,
    compare.ffactor_min AS ffactor_min_compare,
    main.ffactor_min - compare.ffactor_min AS ffactor_min_diff,
	main.length AS length_main,
	compare.length AS length_compare,
	main.length - compare.length AS length_diff,
	main.tot_headloss_max AS tot_headloss_max_main,
	compare.tot_headloss_max AS tot_headloss_max_compare,
	main.tot_headloss_max - compare.tot_headloss_max AS tot_headloss_max_diff,
	main.tot_headloss_min AS tot_headloss_min_main,
	compare.tot_headloss_min AS tot_headloss_min_compare,
	main.tot_headloss_min - compare.tot_headloss_min AS tot_headloss_min_diff,
	main.diameter AS diameter_main,
	compare.diameter AS diameter_compare,
	main.diameter - compare.diameter AS diameter_diff,
    main.the_geom
   FROM main
     JOIN compare ON main.arc_id::text = compare.arc_id::text;


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
    v_rpt_arc_stats.ffactor_min
   FROM inp_pump
     LEFT JOIN v_rpt_arc_stats ON concat(inp_pump.node_id, '_n2a') = v_rpt_arc_stats.arc_id::text
     LEFT JOIN man_pump p ON p.node_id = inp_pump.node_id;


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
    v_rpt_arc_stats.ffactor_min
   FROM inp_pump_additional
     LEFT JOIN v_rpt_arc_stats ON concat(inp_pump_additional.node_id, '_n2a', inp_pump_additional.order_id) = v_rpt_arc_stats.arc_id::text;


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
            WHEN v.to_arc IS NOT NULL AND v.closed IS FALSE THEN 'ACTIVE'::character varying(12)
            WHEN v.closed IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN v.closed IS FALSE THEN 'OPEN'::character varying(12)
            ELSE NULL::character varying(12)
        END AS status,
    inp_valve.add_settings,
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
     LEFT JOIN v_rpt_arc_stats ON concat(inp_valve.node_id, '_n2a') = v_rpt_arc_stats.arc_id::text
     LEFT JOIN man_valve v ON v.node_id = inp_valve.node_id;

CREATE OR REPLACE VIEW ve_epa_frvalve
AS SELECT v.element_id,
    man_frelem.node_id,
    man_frelem.to_arc,
    v.valve_type,
    v.custom_dint,
    v.setting,
    v.curve_id,
    v.minorloss AS status,
    v.add_settings,
    v.init_quality,
    r.flow_max,
    r.flow_min,
    r.flow_avg,
    r.vel_max,
    r.vel_min,
    r.vel_avg,
    r.headloss_max,
    r.headloss_min,
    r.setting_max,
    r.setting_min,
    r.reaction_max,
    r.reaction_min,
    r.ffactor_max,
    r.ffactor_min
   FROM inp_frvalve v
     LEFT JOIN man_frelem USING (element_id)
     LEFT JOIN v_rpt_arc_stats r ON r.arc_id::text = man_frelem.element_id::text;


CREATE OR REPLACE VIEW ve_epa_shortpipe
AS SELECT inp_shortpipe.node_id,
    inp_shortpipe.minorloss,
    cat_node.dint,
    inp_shortpipe.custom_dint,
    v.to_arc,
        CASE
            WHEN v.to_arc IS NOT NULL AND v.closed IS FALSE THEN 'CV'::character varying(12)
            WHEN v.closed IS TRUE THEN 'CLOSED'::character varying(12)
            WHEN v.closed IS FALSE THEN 'OPEN'::character varying(12)
            ELSE NULL::character varying(12)
        END AS status,
    inp_shortpipe.bulk_coeff,
    inp_shortpipe.wall_coeff,
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
     LEFT JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
     JOIN inp_shortpipe USING (node_id)
     LEFT JOIN v_rpt_arc_stats ON concat(inp_shortpipe.node_id, '_n2a') = v_rpt_arc_stats.arc_id::text
     LEFT JOIN man_valve v ON v.node_id = inp_shortpipe.node_id;


CREATE OR REPLACE VIEW ve_epa_pipe
AS SELECT inp_pipe.arc_id,
    inp_pipe.minorloss,
    inp_pipe.status,
    cat_arc.matcat_id,
    a.builtdate,
    r.roughness AS cat_roughness,
    inp_pipe.custom_roughness,
    cat_arc.dint,
    inp_pipe.custom_dint,
    inp_pipe.reactionparam,
    inp_pipe.reactionvalue,
    inp_pipe.bulk_coeff,
    inp_pipe.wall_coeff,
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
   FROM arc a
     LEFT JOIN cat_arc ON cat_arc.id::text = a.arccat_id::text
     JOIN inp_pipe USING (arc_id)
     LEFT JOIN v_rpt_arc_stats ON split_part(v_rpt_arc_stats.arc_id::text, 'P'::text, 1) = inp_pipe.arc_id::text
     LEFT JOIN cat_mat_roughness r ON cat_arc.matcat_id::text = r.matcat_id::text
  WHERE ((now()::date -
        CASE
            WHEN a.builtdate IS NULL THEN '1900-01-01'::date
            ELSE a.builtdate
        END) / 365) >= r.init_age AND ((now()::date -
        CASE
            WHEN a.builtdate IS NULL THEN '1900-01-01'::date
            ELSE a.builtdate
        END) / 365) < r.end_age AND r.active IS TRUE;


CREATE OR REPLACE VIEW ve_epa_virtualvalve
AS SELECT inp_virtualvalve.arc_id,
    inp_virtualvalve.valve_type,
    inp_virtualvalve.diameter,
    inp_virtualvalve.setting,
    inp_virtualvalve.curve_id,
    inp_virtualvalve.minorloss,
    inp_virtualvalve.status,
    inp_virtualvalve.init_quality,
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
   FROM inp_virtualvalve
     LEFT JOIN v_rpt_arc_stats ON inp_virtualvalve.arc_id::text = v_rpt_arc_stats.arc_id::text;


CREATE OR REPLACE VIEW ve_epa_virtualpump
AS SELECT p.arc_id,
    p.power,
    p.curve_id,
    p.speed,
    p.pattern_id,
    p.status,
    p.pump_type,
    p.effic_curve_id,
    p.energy_price,
    p.energy_pattern_id,
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
   FROM inp_virtualpump p
     LEFT JOIN v_rpt_arc_stats ON p.arc_id::text = v_rpt_arc_stats.arc_id::text;


CREATE OR REPLACE VIEW ve_epa_frshortpipe
AS SELECT inp_frshortpipe.element_id,
	ve_man_frelem.node_id,
	ve_man_frelem.to_arc,
    inp_frshortpipe.minorloss,
    inp_frshortpipe.custom_dint,
    inp_frshortpipe.status,
    inp_frshortpipe.bulk_coeff,
    inp_frshortpipe.wall_coeff,
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
   FROM inp_frshortpipe
	 JOIN ve_man_frelem USING (element_id)
     LEFT JOIN v_rpt_arc_stats ON inp_frshortpipe.element_id::text = v_rpt_arc_stats.arc_id::text;


CREATE OR REPLACE VIEW ve_epa_frpump
AS SELECT p.element_id,
    man_frelem.node_id,
    man_frelem.to_arc,
    p.power,
    p.curve_id,
    p.speed,
    p.pattern_id,
    p.pump_type,
    p.energyparam,
    p.energyvalue,
    p.effic_curve_id,
    p.energy_price,
    p.energy_pattern_id,
    p.status,
    r.result_id,
    r.flow_max AS flowmax,
    r.flow_min AS flowmin,
    r.flow_avg AS flowavg,
    r.vel_max AS velmax,
    r.vel_min AS velmin,
    r.vel_avg AS velavg,
    r.headloss_max,
    r.headloss_min,
    r.setting_max,
    r.setting_min,
    r.reaction_max,
    r.reaction_min,
    r.ffactor_max,
    r.ffactor_min
   FROM inp_frpump p
     LEFT JOIN man_frelem USING (element_id)
     LEFT JOIN v_rpt_arc_stats r ON r.arc_id::text = man_frelem.element_id::text;


CREATE OR REPLACE VIEW ve_epa_junction
AS SELECT inp_junction.node_id,
    inp_junction.demand,
    inp_junction.pattern_id,
    inp_junction.peak_factor,
    inp_junction.emitter_coeff,
    inp_junction.init_quality,
    inp_junction.source_type,
    inp_junction.source_quality,
    inp_junction.source_pattern_id,
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
   FROM inp_junction
     LEFT JOIN v_rpt_node_stats ON inp_junction.node_id::text = v_rpt_node_stats.node_id::text;


CREATE OR REPLACE VIEW ve_epa_tank
AS SELECT inp_tank.node_id,
    inp_tank.initlevel,
    inp_tank.minlevel,
    inp_tank.maxlevel,
    inp_tank.diameter,
    inp_tank.minvol,
    inp_tank.curve_id,
    inp_tank.overflow,
    inp_tank.mixing_model,
    inp_tank.mixing_fraction,
    inp_tank.reaction_coeff,
    inp_tank.init_quality,
    inp_tank.source_type,
    inp_tank.source_quality,
    inp_tank.source_pattern_id,
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
   FROM inp_tank
     LEFT JOIN v_rpt_node_stats ON inp_tank.node_id::text = v_rpt_node_stats.node_id::text;


CREATE OR REPLACE VIEW ve_epa_reservoir
AS SELECT inp_reservoir.node_id,
    inp_reservoir.pattern_id,
    inp_reservoir.head,
    inp_reservoir.init_quality,
    inp_reservoir.source_type,
    inp_reservoir.source_quality,
    inp_reservoir.source_pattern_id,
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
   FROM inp_reservoir
     LEFT JOIN v_rpt_node_stats ON inp_reservoir.node_id::text = v_rpt_node_stats.node_id::text;


CREATE OR REPLACE VIEW ve_epa_connec
AS SELECT inp_connec.connec_id,
    inp_connec.demand,
    inp_connec.pattern_id,
    inp_connec.peak_factor,
    inp_connec.custom_roughness,
    inp_connec.custom_length,
    inp_connec.custom_dint,
    inp_connec.status,
    inp_connec.minorloss,
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


CREATE OR REPLACE VIEW ve_epa_inlet
AS SELECT inp_inlet.node_id,
    inp_inlet.initlevel,
    inp_inlet.minlevel,
    inp_inlet.maxlevel,
    inp_inlet.diameter,
    inp_inlet.minvol,
    inp_inlet.curve_id,
    inp_inlet.pattern_id,
    inp_inlet.overflow,
    inp_inlet.head,
    inp_inlet.mixing_model,
    inp_inlet.mixing_fraction,
    inp_inlet.reaction_coeff,
    inp_inlet.init_quality,
    inp_inlet.source_type,
    inp_inlet.source_quality,
    inp_inlet.source_pattern_id,
    inp_inlet.demand,
    inp_inlet.demand_pattern_id,
    inp_inlet.emitter_coeff,
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
   FROM inp_inlet
     LEFT JOIN v_rpt_node_stats ON inp_inlet.node_id::text = v_rpt_node_stats.node_id::text;

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
      "PRESSZONE",
      "DQA",
      "DMA",
      "SECTOR"
    ],
    "comboNames": [
      "Pressure Zonification (PRESSZONE)",
      "District Quality Areas (DQA) ",
      "District Metering Areas (DMA)",
      "Inlet Sectorization (SECTOR-HIGH / SECTOR-LOW)"
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
    "label": "Force open nodes: (*)",
    "widgettype": "linetext",
    "datatype": "text",
    "isMandatory": false,
    "tooltip": "Optative node id(s) to temporary open closed node(s) in order to force algorithm to continue there",
    "placeholder": "1015,2231,3123",
    "layoutname": "grl_option_parameters",
    "layoutorder": 5,
    "value": null
  },
  {
    "widgetname": "forceClosed",
    "label": "Force closed nodes: (*)",
    "widgettype": "text",
    "datatype": "text",
    "isMandatory": false,
    "tooltip": "Optative node id(s) to temporary close open node(s) to force algorithm to stop there",
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
      3,
      4
    ],
    "comboNames": [
      "NONE",
      "CONCAVE POLYGON",
      "PIPE BUFFER",
      "PLOT & PIPE BUFFER",
      "LINK & PIPE BUFFER"
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
      "MACRODMA",
      "MACRODQA",
      "MACROOMZONE"
    ],
    "comboNames": [
      "MACROSECTOR",
      "MACRODMA",
      "MACRODQA",
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
      3,
      4
    ],
    "comboNames": [
      "NONE",
      "CONCAVE POLYGON",
      "PIPE BUFFER",
      "PLOT & PIPE BUFFER",
      "LINK & PIPE BUFFER"
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
]'::json, NULL, true, '{4}');


UPDATE config_param_system
	SET value='{"status":false, "values":[
{"sourceTable":"inp_tank", "query":"UPDATE man_tank t SET hmax=maxlevel FROM inp_tank s "},
{"sourceTable":"inp_valve", "query":"UPDATE man_valve t SET pressure_exit=pressure FROM inp_valve s "}]}'
	WHERE "parameter"='epa_automatic_inp2man_values';

UPDATE config_form_fields SET columnname='staticpressure1' WHERE formname ILIKE '%arc%' AND columnname='staticpress1';
UPDATE config_form_fields SET columnname='staticpressure2' WHERE formname ILIKE '%arc%' AND columnname='staticpress2';
UPDATE config_form_fields SET columnname='pressure_exit' WHERE formname ILIKE '%valve%' AND columnname='pression_exit';
UPDATE config_form_fields SET columnname='pressure_entry' WHERE formname ILIKE '%valve%' AND columnname='pression_entry';
UPDATE config_form_fields SET columnname='pressure_exit' WHERE formname ILIKE '%pump%' AND columnname='pressure';
UPDATE config_form_fields SET columnname='staticpressure1' WHERE formname ILIKE '%link%' AND columnname='staticpressure';

INSERT INTO sys_param_user (id, formname, descript, sys_role, idval, "label", dv_querytext, dv_parent_id, isenabled, layoutorder, project_type, isparent, dv_querytext_filterc, feature_field_id, feature_dv_parent_value, isautoupdate, "datatype", widgettype, ismandatory, widgetcontrols, vdefault, layoutname, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, placeholder, "source") VALUES('edit_nodetype_vdefault', 'config', 'Default type for node when parent layer (v_edit_node) is used', 'role_edit', NULL, 'Default type for node (parent layer):', 'SELECT id AS id, id AS idval FROM cat_feature_node JOIN cat_feature USING (id) WHERE id IS NOT NULL AND cat_feature.active IS TRUE', NULL, true, 1, 'ws', false, NULL, 'node_type', NULL, false, 'string', 'combo', false, NULL, NULL, 'lyt_node', true, NULL, NULL, NULL, NULL, 'core');


UPDATE sys_table SET alias='Catalog for elements' WHERE id='v_edit_cat_feature_element';
UPDATE sys_table SET alias='Catalog of arc shapes'  WHERE id='cat_arc_shape';

UPDATE config_toolbox SET inputparams='[
  {
    "widgetname": "exploitation",
    "label": "Exploitation:",
    "widgettype": "combo",
    "datatype": "text",
    "isMandatory": true,
    "tooltip": "Dscenario type",
    "dvQueryText": "WITH aux AS (SELECT ''-9'' as id, ''ALL'' as idval, 0 AS rowid UNION SELECT expl_id::text as id, name as idval, row_number() over()+1 AS  rowid FROM exploitation where expl_id>0) SELECT id, idval FROM aux ORDER BY rowid ASC",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "value": ""
  },
  {
    "widgetname": "method",
    "label": "Method:",
    "widgettype": "combo",
    "datatype": "text",
    "isMandatory": true,
    "tooltip": "Water balance method",
    "dvQueryText": "SELECT id, idval FROM om_typevalue WHERE typevalue = ''waterbalance_method''",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "value": ""
  },
  {
    "widgetname": "period",
    "label": "Period:",
    "widgettype": "combo",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "layoutorder": 4,
    "dvQueryText": "SELECT id, code as idval FROM ext_cat_period ORDER BY id desc",
    "selectedId": ""
  },
  {
    "widgetname": "initDate",
    "label": "Period (init date):",
    "widgettype": "datetime",
    "datatype": "text",
    "isMandatory": true,
    "tooltip": "Start date",
    "layoutname": "grl_option_parameters",
    "layoutorder": 5,
    "value": null
  },
  {
    "widgetname": "endDate",
    "label": "Period (end date):",
    "widgettype": "datetime",
    "datatype": "text",
    "isMandatory": true,
    "tooltip": "End date",
    "layoutname": "grl_option_parameters",
    "layoutorder": 6,
    "value": "9999-12-12"
  },
  {
    "widgetname": "executeGraphDma",
    "label": "Execute DMA:",
    "widgettype": "check",
    "datatype": "boolean",
    "isMandatory": true,
    "tooltip": "Execute DMA",
    "layoutname": "grl_option_parameters",
    "layoutorder": 7,
    "value": ""
  }
]'::json
WHERE id=3142;

UPDATE sys_function SET descript='Function to calculate water balance according stardards of IWA. 
You must select a period already created or manually select the date of the interval. One at a time. Before that:  
1) tables ext_cat_period, ext_rtc_hydrometer_x_data, ext_rtc_scada_x_data need to be filled. 
2) DMA graph need to be executed.  
>End Date proposal for 1% of hydrometers which consum is out of the period: 2015-07-31 00:00:00' WHERE id=3142;

DELETE FROM config_form_fields  WHERE formname = 've_arc';
DELETE FROM config_form_fields  WHERE formname = 've_connec';
DELETE FROM config_form_fields  WHERE formname = 've_node';
ALTER TABLE config_form_fields DISABLE TRIGGER USER;
UPDATE config_form_fields SET formname = REPLACE(formname, 'v_edit_', 've_') WHERE formname LIKE 'v_edit_%';
ALTER TABLE config_form_fields ENABLE TRIGGER USER;

INSERT INTO edit_typevalue (typevalue, id, idval, descript, addparam) VALUES('man_meter_metertype', '0', 'UNKNOWN', NULL, NULL)
ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO edit_typevalue (typevalue, id, idval, descript)
SELECT DISTINCT 'man_meter_metertype', ROW_NUMBER() OVER(), meter_type, NULL FROM man_meter ORDER BY 2 ASC LIMIT 3 ON CONFLICT DO NOTHING;

INSERT INTO cat_brand (id)
SELECT DISTINCT brand_id FROM node WHERE brand_id IS NOT NULL ON CONFLICT DO NOTHING;

INSERT INTO cat_brand_model (catbrand_id, id)
SELECT DISTINCT brand_id, model_id FROM node WHERE model_id IS NOT NULL ON CONFLICT DO NOTHING;

INSERT INTO sys_foreignkey (typevalue_table, typevalue_name, target_table, target_field, parameter_id, active)
VALUES('edit_typevalue', 'man_meter_metertype', 'man_meter', 'meter_type', NULL, true)
ON CONFLICT (typevalue_table, typevalue_name, target_table, target_field) DO NOTHING;

UPDATE config_param_system SET 
value='{"sys_table_id":"ve_connec","sys_id_field":"connec_id","sys_search_field":"connec_id","alias":"Connecs","cat_field":"conneccat_id","orderby":"3","search_type":"connec"}' 
WHERE "parameter"='basic_search_network_connec';

DELETE FROM config_toolbox WHERE id=2712;

INSERT INTO config_toolbox (id, alias, functionparams, inputparams, observ, active, device) VALUES(2706, 'Minsector analysis', '{"featureType":[]}'::json, '[
  {
    "widgetname": "exploitation",
    "label": "Exploitation:",
    "widgettype": "combo",
    "datatype": "text",
    "tooltip": "Choose exploitation to work with",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT id, idval FROM ( SELECT -901 AS id, ''User selected expl'' AS idval, ''a'' AS sort_order UNION SELECT -902 AS id, ''All exploitations'' AS idval, ''b'' AS sort_order UNION SELECT expl_id AS id, name AS idval, ''c'' AS sort_order FROM exploitation WHERE active IS NOT FALSE ) a ORDER BY sort_order ASC, idval ASC",
    "selectedId": ""
  },
  {
    "widgetname": "usePlanPsector",
    "label": "Use masterplan psectors:",
    "widgettype": "check",
    "datatype": "boolean",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "value": ""
  },
  {
    "widgetname": "commitChanges",
    "label": "Commit changes:",
    "widgettype": "check",
    "datatype": "boolean",
    "layoutname": "grl_option_parameters",
    "layoutorder": 3,
    "value": ""
  },
  {
    "widgetname": "updateMapZone",
    "label": "Update mapzone geometry method:",
    "widgettype": "combo",
    "datatype": "integer",
    "layoutname": "grl_option_parameters",
    "layoutorder": 4,
    "comboIds": [
      0,
      1,
      2,
      3
    ],
    "comboNames": [
      "NONE",
      "CONCAVE POLYGON",
      "PIPE BUFFER",
      "PLOT & PIPE BUFFER"
    ],
    "selectedId": ""
  },
  {
    "widgetname": "geomParamUpdate",
    "label": "Geometry parameter:",
    "widgettype": "text",
    "datatype": "float",
    "layoutname": "grl_option_parameters",
    "layoutorder": 5,
    "isMandatory": false,
    "placeholder": "5-30",
    "value": ""
  },
  {
    "widgetname": "executeMassiveMincut",
    "label": "Execute Massive Mincut:",
    "widgettype": "check",
    "datatype": "boolean",
    "layoutname": "grl_option_parameters",
    "layoutorder": 6,
    "value": ""
  }
]'::json, NULL, true, '{4}')
ON CONFLICT (id) DO UPDATE SET inputparams=EXCLUDED.inputparams;



-- EHYDRANT PLATE
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','code','lyt_data_1',2,'string','text','Code','Code',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','top_elev','lyt_data_1',21,'double','text','Top Elevation','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','rotation','lyt_data_1',18,'double','text','Rotation','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','ownercat_id','lyt_data_1',17,'string','combo','Owner Catalog','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','enddate','lyt_data_1',16,'date','datetime','End Date','End Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','builtdate','lyt_data_1',15,'date','datetime','Built Date','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','workcat_id','lyt_data_1',13,'string','typeahead','Workcat ID','Workcat ID',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','comment','lyt_data_1',8,'string','text','Comments','Comments',false,false,true,false,'{"setMultiline":true}'::json,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','observ','lyt_data_3',15,'string','text','Observations','Observations',false,false,true,false,'{"setMultiline":true}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','category_type','lyt_data_1',10,'string','combo','Category Type','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','function_type','lyt_data_1',9,'string','combo','Function Type','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','num_elements','lyt_data_1',6,'integer','text','Number of Elements','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','location_type','lyt_data_1',11,'string','combo','Location Type','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
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
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
  "icon": "178"
}'::json,'{
  "saveValue": false
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
  "icon": "137"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "selection_init"
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_arc",
  "featureType": "arc"
}'::json,'tbl_element_x_arc',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_connec",
  "featureType": "connec"
}'::json,'tbl_element_x_connec',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','tbl_element_x_gully','lyt_features_2_gully',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_gully",
  "featureType": "gully"
}'::json,'tbl_element_x_gully',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_link",
  "featureType": "link"
}'::json,'tbl_element_x_link',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_node",
  "featureType": "node"
}'::json,'tbl_element_x_node',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
  "icon": "111"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "insert_feature",
  "parameters": {
    "targetwidget": "tab_features_feature_id"
  }
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','workcat_id_end','lyt_data_1',14,'string','typeahead','Workcat ID End','Workcat ID End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','state','lyt_bot_1',3,'integer','combo','State','State',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','elementcat_id','lyt_top_1',0,'string','combo','Element Catalog','Element Catalog',true,false,true,false,'SELECT id, id as idval FROM cat_element WHERE element_type = ''EHYDRANT_PLATE''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','element_id','lyt_top_1',1,'string','text','Element ID','Element ID',false,false,false,false,'{"saveValue":false,"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','state_type','lyt_bot_1',4,'integer','combo','State Type','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','expl_id','lyt_data_2',33,'integer','combo','Exploitation ID','Exploitation ID',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
	VALUES ('ve_genelem_ehydrant_plate','form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality id:','muni_id - Identifier of the municipality',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false) ON CONFLICT DO NOTHING;

-- EMANHOLE
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','code','lyt_data_1',2,'string','text','Code','Code',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','top_elev','lyt_data_1',21,'double','text','Top Elevation','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','rotation','lyt_data_1',18,'double','text','Rotation','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','ownercat_id','lyt_data_1',17,'string','combo','Owner Catalog','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','enddate','lyt_data_1',16,'date','datetime','End Date','End Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','builtdate','lyt_data_1',15,'date','datetime','Built Date','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','workcat_id','lyt_data_1',13,'string','typeahead','Workcat ID','Workcat ID',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','comment','lyt_data_1',8,'string','text','Comments','Comments',false,false,true,false,'{"setMultiline":true}'::json,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','observ','lyt_data_3',15,'string','text','Observations','Observations',false,false,true,false,'{"setMultiline":true}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','category_type','lyt_data_1',10,'string','combo','Category Type','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','function_type','lyt_data_1',9,'string','combo','Function Type','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','num_elements','lyt_data_1',6,'integer','text','Number of Elements','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','location_type','lyt_data_1',11,'string','combo','Location Type','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
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
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
  "icon": "178"
}'::json,'{
  "saveValue": false
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
  "icon": "137"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "selection_init"
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_arc",
  "featureType": "arc"
}'::json,'tbl_element_x_arc',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_connec",
  "featureType": "connec"
}'::json,'tbl_element_x_connec',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','tbl_element_x_gully','lyt_features_2_gully',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_gully",
  "featureType": "gully"
}'::json,'tbl_element_x_gully',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_link",
  "featureType": "link"
}'::json,'tbl_element_x_link',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_node",
  "featureType": "node"
}'::json,'tbl_element_x_node',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
  "icon": "111"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "insert_feature",
  "parameters": {
    "targetwidget": "tab_features_feature_id"
  }
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','workcat_id_end','lyt_data_1',14,'string','typeahead','Workcat ID End','Workcat ID End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','state','lyt_bot_1',3,'integer','combo','State','State',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','elementcat_id','lyt_top_1',0,'string','combo','Element Catalog','Element Catalog',true,false,true,false,'SELECT id, id as idval FROM cat_element WHERE element_type = ''EMANHOLE''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','element_id','lyt_top_1',1,'string','text','Element ID','Element ID',false,false,false,false,'{"saveValue":false,"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','state_type','lyt_bot_1',4,'integer','combo','State Type','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','expl_id','lyt_data_2',33,'integer','combo','Exploitation ID','Exploitation ID',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
	VALUES ('ve_genelem_emanhole','form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality id:','muni_id - Identifier of the municipality',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false) ON CONFLICT DO NOTHING;


-- EPROTECT_BAND
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','code','lyt_data_1',2,'string','text','Code','Code',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','top_elev','lyt_data_1',21,'double','text','Top Elevation','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','rotation','lyt_data_1',18,'double','text','Rotation','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','ownercat_id','lyt_data_1',17,'string','combo','Owner Catalog','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','enddate','lyt_data_1',16,'date','datetime','End Date','End Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','builtdate','lyt_data_1',15,'date','datetime','Built Date','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','workcat_id','lyt_data_1',13,'string','typeahead','Workcat ID','Workcat ID',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','comment','lyt_data_1',8,'string','text','Comments','Comments',false,false,true,false,'{"setMultiline":true}'::json,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','observ','lyt_data_3',15,'string','text','Observations','Observations',false,false,true,false,'{"setMultiline":true}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','category_type','lyt_data_1',10,'string','combo','Category Type','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','function_type','lyt_data_1',9,'string','combo','Function Type','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','num_elements','lyt_data_1',6,'integer','text','Number of Elements','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','location_type','lyt_data_1',11,'string','combo','Location Type','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
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
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
  "icon": "178"
}'::json,'{
  "saveValue": false
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
  "icon": "137"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "selection_init"
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_arc",
  "featureType": "arc"
}'::json,'tbl_element_x_arc',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_connec",
  "featureType": "connec"
}'::json,'tbl_element_x_connec',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','tbl_element_x_gully','lyt_features_2_gully',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_gully",
  "featureType": "gully"
}'::json,'tbl_element_x_gully',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_link",
  "featureType": "link"
}'::json,'tbl_element_x_link',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_node",
  "featureType": "node"
}'::json,'tbl_element_x_node',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
  "icon": "111"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "insert_feature",
  "parameters": {
    "targetwidget": "tab_features_feature_id"
  }
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','workcat_id_end','lyt_data_1',14,'string','typeahead','Workcat ID End','Workcat ID End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','state','lyt_bot_1',3,'integer','combo','State','State',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','elementcat_id','lyt_top_1',0,'string','combo','Element Catalog','Element Catalog',true,false,true,false,'SELECT id, id as idval FROM cat_element WHERE element_type = ''EPROTECT_BAND''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','element_id','lyt_top_1',1,'string','text','Element ID','Element ID',false,false,false,false,'{"saveValue":false,"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','state_type','lyt_bot_1',4,'integer','combo','State Type','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','expl_id','lyt_data_2',33,'integer','combo','Exploitation ID','Exploitation ID',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
	VALUES ('ve_genelem_eprotect_band','form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality id:','muni_id - Identifier of the municipality',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false) ON CONFLICT DO NOTHING;


-- EREGISTER
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','code','lyt_data_1',2,'string','text','Code','Code',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','top_elev','lyt_data_1',21,'double','text','Top Elevation','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','rotation','lyt_data_1',18,'double','text','Rotation','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','ownercat_id','lyt_data_1',17,'string','combo','Owner Catalog','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','enddate','lyt_data_1',16,'date','datetime','End Date','End Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','builtdate','lyt_data_1',15,'date','datetime','Built Date','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','workcat_id','lyt_data_1',13,'string','typeahead','Workcat ID','Workcat ID',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','comment','lyt_data_1',8,'string','text','Comments','Comments',false,false,true,false,'{"setMultiline":true}'::json,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','observ','lyt_data_3',15,'string','text','Observations','Observations',false,false,true,false,'{"setMultiline":true}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','category_type','lyt_data_1',10,'string','combo','Category Type','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','function_type','lyt_data_1',9,'string','combo','Function Type','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','num_elements','lyt_data_1',6,'integer','text','Number of Elements','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','location_type','lyt_data_1',11,'string','combo','Location Type','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
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
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
  "icon": "178"
}'::json,'{
  "saveValue": false
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
  "icon": "137"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "selection_init"
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_arc",
  "featureType": "arc"
}'::json,'tbl_element_x_arc',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_connec",
  "featureType": "connec"
}'::json,'tbl_element_x_connec',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','tbl_element_x_gully','lyt_features_2_gully',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_gully",
  "featureType": "gully"
}'::json,'tbl_element_x_gully',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_link",
  "featureType": "link"
}'::json,'tbl_element_x_link',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_node",
  "featureType": "node"
}'::json,'tbl_element_x_node',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
  "icon": "111"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "insert_feature",
  "parameters": {
    "targetwidget": "tab_features_feature_id"
  }
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','workcat_id_end','lyt_data_1',14,'string','typeahead','Workcat ID End','Workcat ID End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','state','lyt_bot_1',3,'integer','combo','State','State',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','elementcat_id','lyt_top_1',0,'string','combo','Element Catalog','Element Catalog',true,false,true,false,'SELECT id, id as idval FROM cat_element WHERE element_type = ''EREGISTER''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','element_id','lyt_top_1',1,'string','text','Element ID','Element ID',false,false,false,false,'{"saveValue":false,"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','state_type','lyt_bot_1',4,'integer','combo','State Type','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','expl_id','lyt_data_2',33,'integer','combo','Exploitation ID','Exploitation ID',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
	VALUES ('ve_genelem_eregister','form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality id:','muni_id - Identifier of the municipality',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false) ON CONFLICT DO NOTHING;




-- ECOVER documents
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','date_from','lyt_document_1',1,'date','datetime','Date from:','Date from:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":">="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,1) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','date_to','lyt_document_1',2,'date','datetime','Date to:','Date to:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":"<="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,2) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_isnullvalue,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','doc_type','lyt_document_1',3,'string','combo','Doc type:','Doc type:',false,false,true,false,true,'SELECT id as id, idval as idval FROM edit_typevalue WHERE typevalue = ''doc_type''',true,'{"labelPosition": "top"}'::json,'{"functionName": "filter_table", "parameters":{}}'::json,'tbl_doc_x_element',false,3) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','doc_name','lyt_document_2',0,'string','typeahead','Doc id:','Doc id:',false,false,true,false,false,'SELECT name as id, name as idval FROM doc WHERE name IS NOT NULL','{"saveValue": false, "filterSign":"ILIKE"}'::json,'{"functionName": "filter_table"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','btn_doc_insert','lyt_document_2',2,'button','Insert document',false,false,true,false,false,'{"icon":"113"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "add_object",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','btn_doc_delete','lyt_document_2',3,'button','Delete document',false,false,true,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Delete document"}'::json,'{"functionName": "delete_object", "parameters": {"columnfind": "doc_id", "targetwidget": "tab_documents_tbl_documents", "sourceview": "doc"}}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','btn_doc_new','lyt_document_2',4,'button','New document',false,false,true,false,false,'{"icon":"143"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "manage_document",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','hspacer_document_1','lyt_document_2',10,'hspacer',false,false,true,false,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','open_doc','lyt_document_2',11,'button','Open document',false,false,true,false,false,'{"icon":"147"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Open document"}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "columnfind": "path",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_genelem_ecover','form_feature','tab_documents','tbl_documents','lyt_document_3',1,'tableview',false,false,false,false,false,'{"saveValue": false}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "targetwidget": "tab_documents_tbl_documents",
    "columnfind": "path"
  }
}'::json,'tbl_doc_x_element',false,4) ON CONFLICT DO NOTHING;

-- EVALVE
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','comment','lyt_data_1',8,'string','text','Comments','Comments',false,false,true,false,'{"setMultiline":true}'::json,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','code','lyt_data_1',2,'string','text','Code','Code',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','num_elements','lyt_data_1',6,'integer','text','Number of Elements','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','workcat_id','lyt_data_1',13,'string','typeahead','Workcat ID','Workcat ID',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','builtdate','lyt_data_1',15,'date','datetime','Built Date','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','enddate','lyt_data_1',16,'date','datetime','End Date','End Date',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','ownercat_id','lyt_data_1',17,'string','combo','Owner Catalog','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','rotation','lyt_data_1',18,'double','text','Rotation','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','top_elev','lyt_data_1',21,'double','text','Top Elevation','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','nodarc_id','lyt_data_2',0,'string','text','nodarc_id','nodarc_id',false,false,true,false,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','function_type','lyt_data_1',9,'string','combo','Function Type','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE feature_type = ''ELEMENT'' OR ''EVALVE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','category_type','lyt_data_1',10,'string','combo','Category Type','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE feature_type = ''ELEMENT'' OR ''EVALVE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','location_type','lyt_data_1',11,'string','combo','Location Type','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE feature_type = ''ELEMENT'' OR ''EVALVE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','btn_delete','lyt_features_1',2,'button',false,false,true,false,false,'{
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
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','btn_expr_select','lyt_features_1',4,'button',false,false,true,false,false,'{
  "icon": "178"
}'::json,'{
  "saveValue": false
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','observ','lyt_data_3',15,'string','text','Observations','Observations',false,false,true,false,'{"setMultiline":true}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','feature_id','lyt_features_1',0,'text','text',false,false,true,false,false,true) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','btn_snapping','lyt_features_1',3,'button',false,false,true,false,false,'{
  "icon": "137"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "selection_init"
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','tbl_element_x_arc','lyt_features_2_arc',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_arc",
  "featureType": "arc"
}'::json,'tbl_element_x_arc',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','tbl_element_x_connec','lyt_features_2_connec',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_connec",
  "featureType": "connec"
}'::json,'tbl_element_x_connec',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','tbl_element_x_gully','lyt_features_2_gully',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_gully",
  "featureType": "gully"
}'::json,'tbl_element_x_gully',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','tbl_element_x_link','lyt_features_2_link',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_link",
  "featureType": "link"
}'::json,'tbl_element_x_link',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','tbl_element_x_node','lyt_features_2_node',0,'tableview','','',false,false,false,false,false,'{
  "saveValue": false,
  "tableUpsert": "v_ui_element_x_node",
  "featureType": "node"
}'::json,'tbl_element_x_node',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_features','btn_insert','lyt_features_1',1,'button',false,false,true,false,false,'{
  "icon": "111"
}'::json,'{
  "saveValue": false
}'::json,'{
  "functionName": "insert_feature",
  "parameters": {
    "targetwidget": "tab_features_feature_id"
  }
}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','workcat_id_end','lyt_data_1',14,'string','typeahead','Workcat ID End','Workcat ID End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','elementcat_id','lyt_top_1',0,'string','combo','Element Catalog','Element Catalog',true,false,true,false,'SELECT id, id as idval FROM cat_element WHERE element_type = ''EVALVE''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','element_id','lyt_top_1',1,'string','text','Element ID','Element ID',false,false,false,false,'{"saveValue":false,"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','epa_type','lyt_top_1',2,'string','combo','EPA Type','EPA Type',false,false,true,false,'SELECT id, id as idval FROM sys_feature_epa_type WHERE active AND feature_type = ''ELEMENT''','{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','state','lyt_bot_1',3,'integer','combo','State','State',false,false,true,false,'SELECT id, name as idval FROM value_state WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','state_type','lyt_bot_1',4,'integer','combo','State Type','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','expl_id','lyt_data_2',33,'integer','combo','Exploitation ID','Exploitation ID',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector ID','Sector ID',false,false,true,false,'SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','muni_id','lyt_data_3',1,'integer','combo','municipality','muni_id',false,false,true,false,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,'{"setMultiline":false}'::json,false,56) ON CONFLICT DO NOTHING;

UPDATE config_form_fields SET layoutname='lyt_data_2', layoutorder=3, "datatype"='double', widgettype='text', "label"='flwreg_length', tooltip='flwreg_length', placeholder=NULL, ismandatory=false, isparent=false, iseditable=true, isautoupdate=false, isfilter=NULL, dv_querytext=NULL, dv_orderby_id=NULL, dv_isnullvalue=NULL, dv_parent_id=NULL, dv_querytext_filterc=NULL, stylesheet=NULL, widgetcontrols=NULL, widgetfunction=NULL, linkedobject=NULL, hidden=false, web_layoutorder=NULL WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='flwreg_length' AND tabname='tab_data';
UPDATE config_form_fields SET layoutname='lyt_data_2', layoutorder=4, "datatype"='integer', widgettype='text', "label"='node_id', tooltip='node_id', placeholder=NULL, ismandatory=false, isparent=false, iseditable=true, isautoupdate=false, isfilter=NULL, dv_querytext=NULL, dv_orderby_id=NULL, dv_isnullvalue=NULL, dv_parent_id=NULL, dv_querytext_filterc=NULL, stylesheet=NULL, widgetcontrols=NULL, widgetfunction=NULL, linkedobject=NULL, hidden=false, web_layoutorder=NULL WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='node_id' AND tabname='tab_data';
UPDATE config_form_fields SET layoutname='lyt_data_2', layoutorder=5, "datatype"='double', widgettype='text', "label"='order_id', tooltip='order_id', placeholder=NULL, ismandatory=false, isparent=false, iseditable=true, isautoupdate=false, isfilter=NULL, dv_querytext=NULL, dv_orderby_id=NULL, dv_isnullvalue=NULL, dv_parent_id=NULL, dv_querytext_filterc=NULL, stylesheet=NULL, widgetcontrols=NULL, widgetfunction=NULL, linkedobject=NULL, hidden=false, web_layoutorder=NULL WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='order_id' AND tabname='tab_data';

UPDATE config_form_fields SET widgetcontrols = '{"setMultiline": false}'::json WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='expl_id' AND tabname='tab_data';
UPDATE config_form_fields SET widgetcontrols = '{"saveValue":false,"setMultiline": false, "labelPosition": "top"}'::json WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';

-- EPUMP documents
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','btn_doc_new','lyt_document_2',4,'button','New document',false,false,true,false,false,'{"icon":"143"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "manage_document",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','open_doc','lyt_document_2',11,'button','Open document',false,false,true,false,false,'{"icon":"147"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Open document"}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "columnfind": "path",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','btn_doc_delete','lyt_document_2',3,'button','Delete document',false,false,true,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Delete document"}'::json,'{"functionName": "delete_object", "parameters": {"columnfind": "doc_id", "targetwidget": "tab_documents_tbl_documents", "sourceview": "doc"}}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','tbl_documents','lyt_document_3',1,'tableview',false,false,false,false,false,'{"saveValue": false}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "targetwidget": "tab_documents_tbl_documents",
    "columnfind": "path"
  }
}'::json,'tbl_doc_x_element',false,4) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','btn_doc_insert','lyt_document_2',2,'button','Insert document',false,false,true,false,false,'{"icon":"113"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "add_object",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','hspacer_document_1','lyt_document_2',10,'hspacer',false,false,true,false,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','doc_name','lyt_document_2',0,'string','typeahead','Doc id:','Doc id:',false,false,true,false,false,'SELECT name as id, name as idval FROM doc WHERE name IS NOT NULL','{"saveValue": false, "filterSign":"ILIKE"}'::json,'{"functionName": "filter_table"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','date_from','lyt_document_1',1,'date','datetime','Date from:','Date from:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":">="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,1) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_isnullvalue,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','doc_type','lyt_document_1',3,'string','combo','Doc type:','Doc type:',false,false,true,false,true,'SELECT id as id, idval as idval FROM edit_typevalue WHERE typevalue = ''doc_type''',true,'{"labelPosition": "top"}'::json,'{"functionName": "filter_table", "parameters":{}}'::json,'tbl_doc_x_element',false,3) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_epump','form_feature','tab_documents','date_to','lyt_document_1',2,'date','datetime','Date to:','Date to:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":"<="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,2) ON CONFLICT DO NOTHING;

-- EVALVE documents
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','btn_doc_new','lyt_document_2',4,'button','New document',false,false,true,false,false,'{"icon":"143"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "manage_document",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','open_doc','lyt_document_2',11,'button','Open document',false,false,true,false,false,'{"icon":"147"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Open document"}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "columnfind": "path",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','btn_doc_delete','lyt_document_2',3,'button','Delete document',false,false,true,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Delete document"}'::json,'{"functionName": "delete_object", "parameters": {"columnfind": "doc_id", "targetwidget": "tab_documents_tbl_documents", "sourceview": "doc"}}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','tbl_documents','lyt_document_3',1,'tableview',false,false,false,false,false,'{"saveValue": false}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "targetwidget": "tab_documents_tbl_documents",
    "columnfind": "path"
  }
}'::json,'tbl_doc_x_element',false,4) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','btn_doc_insert','lyt_document_2',2,'button','Insert document',false,false,true,false,false,'{"icon":"113"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "add_object",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','hspacer_document_1','lyt_document_2',10,'hspacer',false,false,true,false,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','doc_name','lyt_document_2',0,'string','typeahead','Doc id:','Doc id:',false,false,true,false,false,'SELECT name as id, name as idval FROM doc WHERE name IS NOT NULL','{"saveValue": false, "filterSign":"ILIKE"}'::json,'{"functionName": "filter_table"}'::json,false) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','date_from','lyt_document_1',1,'date','datetime','Date from:','Date from:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":">="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,1) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_isnullvalue,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','doc_type','lyt_document_1',3,'string','combo','Doc type:','Doc type:',false,false,true,false,true,'SELECT id as id, idval as idval FROM edit_typevalue WHERE typevalue = ''doc_type''',true,'{"labelPosition": "top"}'::json,'{"functionName": "filter_table", "parameters":{}}'::json,'tbl_doc_x_element',false,3) ON CONFLICT DO NOTHING;
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_frelem_evalve','form_feature','tab_documents','date_to','lyt_document_1',2,'date','datetime','Date to:','Date to:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":"<="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,2) ON CONFLICT DO NOTHING;


-- Tabactions
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json WHERE formname='ve_epa_inlet' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json WHERE formname='ve_epa_pgully' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false},{"actionName": "actionDemand","actionTooltip": "DWF","disabled": false}]'::json WHERE formname='ve_epa_junction' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabactions='[{"actionName": "actionEdit","actionTooltip": "Edit","disabled": false},{"actionName": "actionZoom","actionTooltip": "Zoom In","disabled": false},{"actionName": "actionCentered","actionTooltip": "Center","disabled": false},{"actionName": "actionZoomOut","actionTooltip": "Zoom Out","disabled": false},{"actionName": "actionCatalog","actionTooltip": "Change Catalog","disabled": false},{"actionName": "actionWorkcat","actionTooltip": "Add Workcat","disabled": false},{"actionName": "actionCopyPaste","actionTooltip": "Copy Paste","disabled": false},{"actionName": "actionInterpolate","actionTooltip": "Interpolate","disabled": false},{"actionName": "actionLink","actionTooltip": "Open Link","disabled": false},{"actionName": "actionHelp","actionTooltip": "Help","disabled": false},{"actionName": "actionGetArcId","actionTooltip": "Set arc_id","disabled": false}]'::json WHERE formname='ve_epa_storage' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_epa';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_documents';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_features';
UPDATE config_form_tabs SET tabfunction=NULL, tabactions='[{"actionName": "actionEdit", "disabled": false},{"actionName": "actionSetToArc","disabled": false}]'::json WHERE formname='ve_frelem' AND tabname='tab_data';


-- ELEMENT_ID
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline":false}'::json
	WHERE formname='v_edit_element' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_none';
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline": false, "labelPosition": "top"}'::json
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline": false, "labelPosition": "top"}'::json
	WHERE formname='ve_genelem_ecover' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline": false, "labelPosition": "top"}'::json
	WHERE formname='ve_genelem_ehydrant_plate' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline": false, "labelPosition": "top"}'::json
	WHERE formname='ve_genelem_emanhole' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline": false, "labelPosition": "top"}'::json
	WHERE formname='ve_genelem_eprotect_band' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline": false, "labelPosition": "top"}'::json
	WHERE formname='ve_genelem_eregister' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET widgetcontrols='{"saveValue": false,"setMultiline": false, "labelPosition": "top"}'::json
	WHERE formname='ve_genelem_estep' AND formtype='form_feature' AND columnname='element_id' AND tabname='tab_data';

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

-- Config_form_tabs
INSERT INTO config_form_tabs (formname,tabname,"label",tooltip,sys_role,tabactions,orderby,device)
	VALUES ('ve_frelem','tab_epa','EPA','Epa','role_basic','[
  {"actionName": "actionEdit", "disabled": false}
]'::json,1,'{4}');
INSERT INTO config_form_tabs (formname,tabname,"label",tooltip,sys_role,tabactions,orderby,device)
	VALUES ('ve_frelem','tab_documents','Documents','List of documents','role_basic','[
  {"actionName": "actionEdit", "disabled": false}
]'::json,2,'{4}');
INSERT INTO config_form_tabs (formname,tabname,"label",tooltip,sys_role,tabactions,orderby,device)
	VALUES ('ve_frelem','tab_features','Features','Manage features','role_basic','[
  {"actionName": "actionEdit", "disabled": false}
]'::json,3,'{4}');
INSERT INTO config_form_tabs (formname,tabname,"label",tooltip,sys_role,tabactions,orderby,device)
	VALUES ('ve_frelem','tab_data','Data','Data','role_basic','[
  {
    "actionName": "actionEdit",
    "disabled": false
  },
  {
    "actionName": "actionSetGeom",
    "disabled": false
  }
]'::json,0,'{4}');


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
UPDATE config_form_fields
	SET iseditable=true
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';

-- Order evalve
UPDATE config_form_fields
	SET layoutorder=0,layoutname='lyt_data_1'
	WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='node_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET iseditable=false
	WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='node_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET iseditable=true
	WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';

-- Sector_id
UPDATE config_form_fields
	SET dv_querytext='SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL and sector_id >= 0'
	WHERE formname='ve_genelem_ehydrant_plate' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET dv_querytext='SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL and sector_id >= 0'
	WHERE formname='ve_genelem_emanhole' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET dv_querytext='SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL and sector_id >= 0'
	WHERE formname='ve_genelem_eprotect_band' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET dv_querytext='SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL and sector_id >= 0'
	WHERE formname='ve_genelem_eregister' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET dv_querytext='SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL and sector_id >= 0'
	WHERE formname='ve_genelem_ecover' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET dv_querytext='SELECT sector_id as id, name as idval FROM sector WHERE sector_id IS NOT NULL and sector_id >= 0'
	WHERE formname='ve_genelem_estep' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_data';

-- is mandatory frelem
UPDATE config_form_fields
	SET ismandatory=true
	WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='flwreg_length' AND tabname='tab_data';
UPDATE config_form_fields
	SET ismandatory=true
	WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='order_id' AND tabname='tab_data';
UPDATE config_form_fields
	SET ismandatory=true
	WHERE formname='ve_frelem_evalve' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';
UPDATE config_form_fields
	SET ismandatory=true
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='to_arc' AND tabname='tab_data';
UPDATE config_form_fields
	SET ismandatory=true
	WHERE formname='ve_frelem_epump' AND formtype='form_feature' AND columnname='flwreg_length' AND tabname='tab_data';



INSERT INTO edit_typevalue (typevalue,id,idval) VALUES ('dma_type','TRANSMISSION','TRANSMISSION');
INSERT INTO edit_typevalue (typevalue,id,idval) VALUES ('dma_type','DISTRIBUTION','DISTRIBUTION');
INSERT INTO edit_typevalue (typevalue,id,idval) VALUES ('dma_type','HYBRID','HYBRID');

INSERT INTO inp_typevalue (typevalue,id,idval) VALUES ('inp_options_networkmode','1','TRANSMISSION NETWORK');
INSERT INTO inp_typevalue (typevalue,id,idval) VALUES ('inp_options_networkmode','5','NETWORK DMA');


INSERT INTO sys_param_user (id, formname, descript, sys_role, idval, "label", dv_querytext, dv_parent_id, isenabled, layoutorder, project_type, isparent, dv_querytext_filterc,
feature_field_id, feature_dv_parent_value, isautoupdate, "datatype", widgettype, ismandatory, widgetcontrols, vdefault, layoutname, iseditable, dv_orderby_id, dv_isnullvalue,
stylesheet, placeholder, "source")
VALUES('inp_options_selecteddma', 'epaoptions', 'Wich DMA will be exportad if networkmode is NETWORK DMA', 'role_epa', NULL, 'Dma (NETWORK DMA):',
'SELECT dma_id as id, name as idval FROM dma WHERE dma_id is not null and dma_id > 0', NULL, true, 2, 'ws', false, NULL, NULL, NULL, false, 'integer', 'combo', true, NULL, NULL,
'lyt_general_1', true, true, NULL, NULL, NULL, 'core');

INSERT INTO config_param_user ("parameter", value, cur_user) VALUES('inp_options_selecteddma', '3', 'postgres') ON CONFLICT DO NOTHING;


UPDATE config_toolbox SET inputparams = '[
  {
    "label": "Exploitation:",
    "value": null,
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "expl",
    "widgettype": "combo",
    "dvQueryText": "SELECT expl_id as id, name as idval FROM ve_exploitation",
    "layoutorder": 1
  },
  {
    "label": "Material:",
    "value": null,
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "material",
    "widgettype": "combo",
    "dvQueryText": "SELECT id, descript as idval FROM cat_material WHERE ''ARC'' = ANY(feature_type) AND id IS NOT NULL",
    "layoutorder": 2
  },
  {
    "label": "Price:",
    "value": null,
    "tooltip": "Code of removal material price",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "price",
    "widgettype": "linetext",
    "isMandatory": true,
    "layoutorder": 3,
    "placeholder": ""
  },
  {
    "label": "Observ:",
    "value": null,
    "tooltip": "Descriptive text for removal (it apears on psector_x_other observ)",
    "datatype": "text",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "observ",
    "widgettype": "linetext",
    "isMandatory": true,
    "layoutorder": 4,
    "placeholder": ""
  }
]'::json WHERE id = 3322;



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

-- Correct sourcetable in widgetfunction
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
	WHERE formname='ve_link_pipelink' AND formtype='form_feature' AND columnname='new_element' AND tabname='tab_elements';
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

-- FRVALVE
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','reaction_min','lyt_epa_data_2',15,'string','text','Min reaction:','Min reaction',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','ffactor_max','lyt_epa_data_2',16,'string','text','Max Ffactor:','Max Ffactor',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','ffactor_min','lyt_epa_data_2',17,'string','text','Min Ffactor:','Min Ffactor',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','tbl_inp_valve','lyt_epa_dsc_3',1,'tableview',false,false,false,false,false,'{"saveValue": false, "tableUpsert":"v_edit_inp_dscenario_valve"}'::json,'tbl_inp_dscenario_valve',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','hspacer_epa_1','lyt_epa_dsc_1',4,'hspacer',false,false,false,false,false,'{"saveValue": false}'::json,'tbl_inp_dscenario_valve',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','cat_dint','lyt_epa_data_1',13,'string','text','Cat dint:','Cat dint',false,false,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','custom_dint','lyt_epa_data_1',14,'string','text','Custom dint:','Custom dint',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','status','lyt_epa_data_1',9,'string','text','Status:','Status',false,false,false,false,false,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','valve_type','lyt_epa_data_1',2,'string','text','Valve type:','Valve type',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','nodarc_id','lyt_epa_data_1',1,'string','text','Nodarc id:','Nodarc id',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','pressure','lyt_epa_data_1',3,'string','text','Pressure:','Pressure',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','flow','lyt_epa_data_1',5,'string','text','Flow:','Flow',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','coef_loss','lyt_epa_data_1',6,'string','text','Coefficient loss:','Coefficient loss',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','minorloss','lyt_epa_data_1',8,'string','text','Minorloss:','Minorloss',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','add_settings','lyt_epa_data_1',11,'string','text','Add settings:','Add settings',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','init_quality','lyt_epa_data_1',12,'string','text','Initial quality:','Initial quality',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','result_id','lyt_epa_data_2',1,'string','text','Result id:','Result id',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','headloss_max','lyt_epa_data_2',8,'string','text','Max headloss:','Max headloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','headloss_min','lyt_epa_data_2',9,'string','text','Min headloss:','Min headloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','uheadloss_max','lyt_epa_data_2',10,'string','text','Max uheadloss:','Max uheadloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','uheadloss_min','lyt_epa_data_2',11,'string','text','Min uheadloss:','Min uheadloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','setting_max','lyt_epa_data_2',12,'string','text','Max setting:','Max setting',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','setting_min','lyt_epa_data_2',13,'string','text','Min setting:','Min setting',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','reaction_max','lyt_epa_data_2',14,'string','text','Max reaction:','Max reaction',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','curve_id','lyt_epa_data_1',7,'string','combo','Curve id:','Curve id',false,false,true,false,false,'SELECT id, id AS idval FROM inp_curve WHERE id IS NOT NULL',true,true,'{"valueRelation":{"nullValue":false, "layer": "v_edit_inp_curve", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','flow_max','lyt_epa_data_2',2,'string','text','Max flow:','Max Flow',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','flow_min','lyt_epa_data_2',3,'string','text','Min flow:','Min Flow',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','vel_max','lyt_epa_data_2',5,'string','text','Max velocity:','Max velocity',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','vel_min','lyt_epa_data_2',6,'string','text','Min velocity:','Min velocity',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','add_to_dscenario','lyt_epa_dsc_1',1,'button',false,false,false,false,false,'{"icon":"113"}'::json,'{"saveValue": false}'::json,'{
  "functionName": "add_to_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_valve",
    "tablename": "v_edit_inp_dscenario_valve",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_valve", "view": "v_edit_inp_dscenario_valve", "add_view": "v_edit_inp_dscenario_valve", "pk": ["dscenario_id", "node_id"]}
   ]
, "add_dlg_title":"Valve"   }
}'::json,'tbl_inp_dscenario_valve',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','edit_dscenario','lyt_epa_dsc_1',3,'button',false,false,true,false,false,'{"icon":"101"}'::json,'{"saveValue":false, "onContextMenu":"Edit dscenario"}'::json,'{
  "functionName": "edit_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_valve",
    "tablename": "v_edit_inp_dscenario_valve",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_valve", "view": "v_edit_inp_dscenario_valve", "add_view": "v_edit_inp_dscenario_valve", "pk": ["dscenario_id", "node_id"]}
   ]
, "add_dlg_title":"Valve"   }
}'::json,'tbl_inp_dscenario_valve',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frvalve','form_feature','tab_epa','remove_from_dscenario','lyt_epa_dsc_1',2,'button',false,false,false,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "onContextMenu":"Delete dscenario"}'::json,'{
  "functionName": "remove_from_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_valve",
    "tablename": "v_edit_inp_dscenario_valve",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_valve", "view": "v_edit_inp_dscenario_valve", "add_view": "v_edit_inp_dscenario_valve", "pk": ["dscenario_id", "node_id"]}
   ]
  }
}'::json,'tbl_inp_dscenario_valve',false);

-- FRPUMP
DELETE FROM config_form_fields WHERE formname = 've_epa_frpump';

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','power','lyt_epa_data_1',1,'string','text','Power:','Power',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','speed','lyt_epa_data_1',3,'string','text','Speed:','Speed',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','energy_price','lyt_epa_data_1',9,'string','text','Energy price:','Energy price',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','result_id','lyt_epa_data_2',1,'string','text','Result id:','Result id',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','headloss_max','lyt_epa_data_2',6,'string','text','Max headloss:','Max headloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','headloss_min','lyt_epa_data_2',7,'string','text','Min headloss:','Min headloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','quality','lyt_epa_data_2',8,'string','text','Quality:','Quality',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','usage_fact','lyt_epa_data_2',9,'string','text','Usage factor:','Usage factor',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','kwhr_mgal','lyt_epa_data_2',11,'string','text','KWh mgal:','KWh mgal',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','avg_kw','lyt_epa_data_2',12,'string','text','Average KW:','Average KW',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','peak_kw','lyt_epa_data_2',13,'string','text','Peak KW:','Peak KW',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','cost_day','lyt_epa_data_2',14,'string','text','Cost day:','Cost day',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','status','lyt_epa_data_1',5,'string','combo','Status:','Status',false,false,true,false,false,'SELECT DISTINCT (id) AS id,  idval  AS idval FROM inp_typevalue WHERE id IS NOT NULL AND typevalue=''inp_value_status_pump''',true,true,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','pump_type','lyt_epa_data_1',8,'string','combo','Pump type:','Pump type',false,false,true,false,false,'SELECT id, idval FROM inp_typevalue WHERE typevalue = ''inp_typevalue_pumptype''',true,true,'{"setMultiline":false}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','avg_effic','lyt_epa_data_2',10,'string','text','Average efficiency:','Average efficiency',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','tbl_inp_pump','lyt_epa_dsc_3',1,'tableview',false,false,false,false,false,'{"saveValue": false, "tableUpsert":"v_edit_inp_dscenario_pump"}'::json,'tbl_inp_dscenario_pump',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','hspacer_epa_1','lyt_epa_dsc_1',4,'hspacer',false,false,false,false,false,'{"saveValue": false}'::json,'tbl_inp_dscenario_pump',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','remove_from_dscenario','lyt_epa_dsc_1',2,'button',false,false,false,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "onContextMenu":"Delete dscenario"}'::json,'{
  "functionName": "remove_from_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_pump",
    "tablename": "v_edit_inp_dscenario_pump",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_pump", "view": "v_edit_inp_dscenario_pump", "add_view": "v_edit_inp_dscenario_pump", "pk": ["dscenario_id", "node_id"]}
   ]
  }
}'::json,'tbl_inp_dscenario_pump',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','effic_curve_id','lyt_epa_data_1',11,'string','combo','Eff. curve','Eff. curve',false,false,true,false,false,'SELECT id as id, id as idval FROM ve_inp_curve WHERE curve_type = ''EFFICIENCY''',true,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','energy_pattern_id','lyt_epa_data_1',10,'string','combo','Price pattern:','Price pattern',false,false,true,false,false,'SELECT pattern_id as id, pattern_id as idval FROM ve_inp_pattern WHERE pattern_id is not null','{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','pattern_id','lyt_epa_data_1',4,'string','combo','Pattern:','Pattern',false,false,true,false,false,'SELECT DISTINCT (pattern_id) AS id,  pattern_id  AS idval FROM inp_pattern WHERE pattern_id IS NOT NULL',true,true,'{"setMultiline": false, "valueRelation":{"nullValue":true, "layer": "v_edit_inp_pattern", "activated": true, "keyColumn": "pattern_id", "valueColumn": "pattern_id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','flow_max','lyt_epa_data_2',2,'string','text','Max flow:','Max Flow',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','flow_min','lyt_epa_data_2',3,'string','text','Min flow:','Min Flow',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','vel_max','lyt_epa_data_2',4,'string','text','Max velocity:','Max velocity',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','vel_min','lyt_epa_data_2',5,'string','text','Min velocity:','Min velocity',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','add_to_dscenario','lyt_epa_dsc_1',1,'button',false,false,false,false,false,'{"icon":"113"}'::json,'{"saveValue": false}'::json,'{
  "functionName": "add_to_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_pump",
    "tablename": "v_edit_inp_dscenario_pump",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_pump", "view": "v_edit_inp_dscenario_pump", "add_view": "v_edit_inp_dscenario_pump", "pk": ["dscenario_id", "node_id"]}
   ]
 , "add_dlg_title":"Pump" }
}'::json,'tbl_inp_dscenario_pump',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','edit_dscenario','lyt_epa_dsc_1',3,'button',false,false,true,false,false,'{"icon":"101"}'::json,'{"saveValue":false, "onContextMenu":"Edit dscenario"}'::json,'{
  "functionName": "edit_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_pump",
    "tablename": "v_edit_inp_dscenario_pump",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_pump", "view": "v_edit_inp_dscenario_pump", "add_view": "v_edit_inp_dscenario_pump", "pk": ["dscenario_id", "node_id"]}
   ]
 , "add_dlg_title":"Pump" }
}'::json,'tbl_inp_dscenario_pump',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','curve_id','lyt_epa_data_1',2,'string','combo','Curve id:','Curve id',false,false,true,false,false,'SELECT id, id AS idval FROM inp_curve WHERE id IS NOT NULL AND curve_type IN (''PUMP'', ''PUMP1'', ''PUMP2'', ''PUMP3'', ''PUMP4'')',true,true,'{"valueRelation":{"nullValue":false, "layer": "v_edit_inp_curve", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frpump','form_feature','tab_epa','to_arc','lyt_epa_data_1',6,'string','text','To arc:','To arc',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);


UPDATE config_form_list SET query_text='SELECT dscenario_id, valve_type, diameter, setting, curve_id, minorloss, status, init_quality FROM ve_inp_dscenario_virtualvalve WHERE arc_id IS NOT NULL' WHERE listname='tbl_inp_dscenario_virtualvalve' AND device=4;
UPDATE config_form_list SET query_text='SELECT dscenario_id AS id, arc_id, valve_type, diameter, setting, curve_id, minorloss, status FROM inp_dscenario_virtualvalve where dscenario_id is not null' WHERE listname='dscenario_virtualvalve' AND device=5;
UPDATE config_form_list SET query_text='SELECT dscenario_id AS id, node_id, valve_type, setting, curve_id, minorloss, status, add_settings, init_quality FROM inp_dscenario_valve where dscenario_id is not null' WHERE listname='dscenario_valve' AND device=5;
UPDATE config_form_list SET query_text='SELECT dscenario_id, node_id, nodarc_id, valve_type, setting, curve_id, minorloss, status, add_settings, init_quality FROM ve_inp_dscenario_valve WHERE node_id IS NOT NULL' WHERE listname='tbl_inp_dscenario_valve' AND device=4;

DELETE FROM config_form_fields WHERE formname='inp_dscenario_valve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='inp_dscenario_valve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='inp_dscenario_valve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='inp_dscenario_virtualvalve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='inp_dscenario_virtualvalve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='inp_dscenario_virtualvalve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_frvalve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_valve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_virtualvalve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_virtualvalve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_epa_virtualvalve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_epa';
DELETE FROM config_form_fields WHERE formname='ve_inp_dscenario_valve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_dscenario_valve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_dscenario_valve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_dscenario_virtualvalve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_dscenario_virtualvalve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_dscenario_virtualvalve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_valve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_valve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_valve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_virtualvalve' AND formtype='form_feature' AND columnname='flow' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_virtualvalve' AND formtype='form_feature' AND columnname='coef_loss' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_inp_virtualvalve' AND formtype='form_feature' AND columnname='pressure' AND tabname='tab_none';


INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_inp_virtualvalve', 'form_feature', 'tab_none', 'setting', 'lyt_data_1', 16, 'double', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_inp_valve', 'form_feature', 'tab_none', 'setting', 'lyt_data_1', 14, 'double', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_inp_dscenario_virtualvalve', 'form_feature', 'tab_none', 'setting', 'lyt_data_1', 6, 'double', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_inp_dscenario_valve', 'form_feature', 'tab_none', 'setting', NULL, 5, 'double', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, false, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_epa_virtualvalve', 'form_feature', 'tab_epa', 'setting', 'lyt_epa_data_1', 3, 'string', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_epa_valve', 'form_feature', 'tab_epa', 'setting', 'lyt_epa_data_1', 3, 'string', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_epa_frvalve', 'form_feature', 'tab_epa', 'setting', 'lyt_epa_data_1', 3, 'string', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('inp_dscenario_virtualvalve', 'form_feature', 'tab_none', 'setting', 'lyt_data_1', 6, 'double', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('inp_dscenario_valve', 'form_feature', 'tab_none', 'setting', NULL, 5, 'double', 'text', 'Setting:', 'Setting:', NULL, false, false, true, false, false, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

UPDATE config_form_fields SET ismandatory=true WHERE  formtype='form_feature' AND columnname='connection_type' AND tabname='tab_data';

UPDATE config_param_system SET value='{"status":true, "values":[
{"sourceTable":"ve_node_tank", "query":"UPDATE inp_inlet t SET maxlevel = hmax, diameter=sqrt(4*area/3.14159) FROM ve_node_tank s "},
{"sourceTable":"ve_node_pr_reduc_valve", "query":"UPDATE inp_valve t SET setting = pressure_exit FROM ve_node_pr_reduc_valve s "}]}'
WHERE parameter = 'epa_automatic_man2inp_values';

UPDATE config_param_system SET value='{"status":true, "values":[
{"sourceTable":"ve_node_pr_reduc_valve", "query":"UPDATE presszone t SET head=top_elev + pressure_exit FROM ve_node_pr_reduc_valve s "},
{"sourceTable":"ve_node_tank", "query":"UPDATE presszone t SET head=top_elev + hmax/2  FROM ve_node_tank s "}]}'
WHERE parameter = 'epa_automatic_man2graph_values';



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

  -- Elements
    -- ve_frelem
      -- evalve
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','brand_id','lyt_data_1',13,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EVALVE'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_evalve','form_feature','tab_data','model_id','lyt_data_1',14,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EVALVE'' = ANY(featurecat_id::text[])');

      -- epump
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_epump','form_feature','tab_data','brand_id','lyt_data_1',13,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EPUMP'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_epump','form_feature','tab_data','model_id','lyt_data_1',14,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EPUMP'' = ANY(featurecat_id::text[])');


UPDATE config_form_fields SET layoutorder=15 WHERE formname ILIKE 've_frelem_%' AND formtype='form_feature' AND columnname='rotation' AND tabname='tab_data';
UPDATE config_form_fields SET layoutorder=16 WHERE formname ILIKE 've_frelem_%' AND formtype='form_feature' AND columnname='top_elev' AND tabname='tab_data';

    -- ve_genelem
      -- ecover
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_ecover','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''COVER'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_ecover','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''COVER'' = ANY(featurecat_id::text[])');

      -- ehydrant_plate
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
    VALUES ('ve_frelem_ehydrant_plate','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''HYDRANT_PLATE'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_ehydrant_plate','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''HYDRANT_PLATE'' = ANY(featurecat_id::text[])');

      -- emanhole
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_emanhole','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''MANHOLE'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_emanhole','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''MANHOLE'' = ANY(featurecat_id::text[])');

      -- eprotect_band
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eprotect_band','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EPROTECT_BAND'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eprotect_band','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EPROTECT_BAND'' = ANY(featurecat_id::text[])');

      -- eregister
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eregister','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''EREGISTER'' = ANY(featurecat_id::text[])');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_eregister','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''EREGISTER'' = ANY(featurecat_id::text[])');

      -- estep
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_estep','form_feature','tab_data','brand_id','lyt_data_1',12,'text','combo','Brand','brand_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand WHERE ''ESTEP'' = ANY(featurecat_id::text[]) ');
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext)
	VALUES ('ve_frelem_estep','form_feature','tab_data','model_id','lyt_data_1',13,'text','combo','Model','model_id',false,false,true,false,'SELECT id, id as idval FROM cat_brand_model WHERE ''ESTEP'' = ANY(featurecat_id::text[])');

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



-- last update
-- Normalize "label": replace underscores with spaces, trim, ensure only the first letter is uppercase,
-- and append a colon if missing. Only updates rows needing changes.
ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_config_control;
ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_typevalue_fk;
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
ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_typevalue_fk;

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

UPDATE sys_fprocess SET except_msg='values of roughness out of range acording headloss formula used' WHERE fid=377;

UPDATE config_form_fields SET "datatype"='string', widgettype='combo', ismandatory=false, iseditable=false, dv_querytext='SELECT fluid_type as id, fluid_type as idval FROM man_type_fluid WHERE ((featurecat_id is null AND feature_type=''NODE'') ) AND active IS TRUE  OR ''WATER_CONNECTION'' = ANY(featurecat_id::text[])', dv_isnullvalue=true WHERE formname ILIKE '%ve_link%' AND formtype='form_feature' AND columnname='fluid_type' AND tabname='tab_data';

DELETE FROM config_form_fields WHERE formname ILIKE '%ve_link%' AND formtype='form_feature' AND columnname='n_hydrometer' AND tabname='tab_none';


INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4338, 'Water balance is not allowed having surpassed the threshold day limiter (parameter om_waterbalance_threshold_days)', null, 0, true, 'utils', 'core', 'AUDIT');


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

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_elem_dsc_valve', 'lyt_elem_dsc_valve', 'layoutElemDscValve', '{"lytOrientation": "vertical"}'::json);

INSERT INTO config_typevalue
(typevalue, id, idval, camelstyle, addparam)
VALUES('layout_name_typevalue', 'lyt_elem_dsc_shortpipe', 'lyt_elem_dsc_shortpipe', 'layoutElemDscShortpipe', '{"lytOrientation": "vertical"}'::json);

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
VALUES('node', 'form_feature', 'tab_elements', 'tbl_frelem_dsc_pump', 'lyt_elem_dsc_pump', 1, NULL, 'tableview', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"saveValue": false}'::json, NULL, 'tbl_frelem_dsc_pump', false, NULL);

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'tbl_frelem_dsc_valve', 'lyt_elem_dsc_valve', 1, NULL, 'tableview', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"saveValue": false}'::json, NULL, 'tbl_frelem_dsc_valve', false, NULL);

INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('node', 'form_feature', 'tab_elements', 'tbl_frelem_dsc_shortpipe', 'lyt_elem_dsc_shortpipe', 1, NULL, 'tableview', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"saveValue": false}'::json, NULL, 'tbl_frelem_dsc_shortpipe', false, NULL);


-- tables
INSERT INTO config_form_list
(listname, query_text, device, listtype, listclass, vdefault, addparam)
VALUES('tbl_frelem_dsc_pump', 'SELECT * FROM ve_inp_dscenario_frpump WHERE element_id IS NOT NULL', 4, 'tab', 'list', NULL, NULL);

INSERT INTO config_form_list
(listname, query_text, device, listtype, listclass, vdefault, addparam)
VALUES('tbl_frelem_dsc_valve', 'SELECT * FROM ve_inp_dscenario_frvalve WHERE element_id IS NOT NULL', 4, 'tab', 'list', NULL, NULL);


INSERT INTO config_form_list
(listname, query_text, device, listtype, listclass, vdefault, addparam)
VALUES('tbl_frelem_dsc_shortpipe','SELECT * FROM ve_inp_dscenario_frshortpipe WHERE element_id IS NOT NULL',4,'tab','list',NULL,NULL);


-- config_from_tableview
INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'dscenario_id', 1, true, NULL, 'Dscenario id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'element_id', 2, true, NULL, 'Element id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'node_id', 3, true, NULL, 'Node id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'power', 4, true, NULL, 'Power', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'curve_id', 5, true, NULL, 'Curve id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'speed', 6, true, NULL, 'Speed', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'pattern_id', 7, true, NULL, 'Pattern id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'effic_curve_id', 8, true, NULL, 'Effic curve id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'energy_price', 9, true, NULL, 'Energy price', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'energy_pattern_id', 10, true, NULL, 'Energy pattern id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'status', 11, true, NULL, 'Status', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_pump', 'the_geom', 12, false, NULL, 'the_geom', NULL, NULL);

-- config_from_tableview
INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'dscenario_id', 1, true, NULL, 'Dscenario id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'element_id', 2, true, NULL, 'Element id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'node_id', 3, true, NULL, 'Node id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'valve_type', 4, true, NULL, 'Valve type', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'custom_dint', 5, true, NULL, 'Custom dint', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'setting', 6, true, NULL, 'Setting', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'curve_id', 7, true, NULL, 'Curve id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'minorloss', 8, true, NULL, 'Minorloss', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'add_settings', 9, true, NULL, 'Add settings', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'init_quality', 10, true, NULL, 'Init quality', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_valve', 'the_geom', 11, false, NULL, 'the_geom', NULL, NULL);

INSERT INTO config_form_tableview
(location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
VALUES
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'dscenario_id', 1, true, NULL, 'Dscenario id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'element_id', 2, true, NULL, 'Element id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'node_id', 3, true, NULL, 'Node id', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'minorloss', 4, true, NULL, 'Minorloss', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'bulk_coeff', 5, true, NULL, 'Bulk coeff', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'wall_coeff', 6, true, NULL, 'Wall coeff', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'custom_dint', 7, true, NULL, 'Custom dint', NULL, NULL),
('feature form', 'ws', 'tbl_frelem_dsc_shortpipe', 'the_geom', 8, false, NULL, 'the_geom', NULL, NULL);


INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_link_vlink', 'form_feature', 'tab_data', 'linkcat_id', 'lyt_top_1', 2, 'string', 'typeahead', 'Linkcat ID:', 'linkcat_id - To be selected from the catalog of arcs. It is independent of the type of arch', NULL, true, false, true, false, NULL, 'SELECT id, id as idval FROM cat_link WHERE id IS NOT NULL AND active IS TRUE ', NULL, NULL, 'link_type', ' AND cat_link.link_type IS NULL OR cat_link.link_type', NULL, '{"setMultiline": false, "labelPosition": "top", "valueRelation": {"layer": "cat_link", "activated": true, "keyColumn": "id", "nullValue": false, "valueColumn": "id", "filterExpression": null}}'::json, NULL, NULL, false, 3);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_link_vlink', 'form_feature', 'tab_data', 'link_type', 'lyt_top_1', 1, 'string', 'combo', 'Link Type:', 'Type of link. It is auto-populated based on the linkcat_id', NULL, true, true, false, false, NULL, 'SELECT id, id as idval FROM cat_feature_link WHERE id IS NOT NULL', true, false, NULL, NULL, NULL, '{"setMultiline": false, "labelPosition": "top", "valueRelation": {"layer": "ve_cat_feature_link", "activated": true, "keyColumn": "id", "nullValue": false, "valueColumn": "id", "filterExpression": null}}'::json, NULL, NULL, false, 2);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_link_pipelink', 'form_feature', 'tab_data', 'linkcat_id', 'lyt_top_1', 2, 'string', 'typeahead', 'Linkcat ID:', 'linkcat_id - To be selected from the catalog of arcs. It is independent of the type of arch', NULL, true, false, true, false, NULL, 'SELECT id, id as idval FROM cat_link WHERE id IS NOT NULL AND active IS TRUE ', NULL, NULL, 'link_type', ' AND cat_link.link_type IS NULL OR cat_link.link_type', NULL, '{"setMultiline": false, "labelPosition": "top", "valueRelation": {"layer": "cat_link", "activated": true, "keyColumn": "id", "nullValue": false, "valueColumn": "id", "filterExpression": null}}'::json, NULL, NULL, false, 3);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES('ve_link_pipelink', 'form_feature', 'tab_data', 'link_type', 'lyt_top_1', 1, 'string', 'combo', 'Link Type:', 'Type of link. It is auto-populated based on the linkcat_id', NULL, true, true, false, false, NULL, 'SELECT id, id as idval FROM cat_feature_link WHERE id IS NOT NULL', true, false, NULL, NULL, NULL, '{"setMultiline": false, "labelPosition": "top", "valueRelation": {"layer": "ve_cat_feature_link", "activated": true, "keyColumn": "id", "nullValue": false, "valueColumn": "id", "filterExpression": null}}'::json, NULL, NULL, false, 2);

UPDATE config_form_fields SET widgetcontrols = replace(widgetcontrols::text, 'v_edit_', 've_')::json WHERE widgetcontrols::text ilike '%v_edit_%';

SELECT gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"plan_psector_x_connec", "column":"active", "dataType":"boolean"}}$$);

DELETE FROM sys_table WHERE id = 'v_value_cat_connec';
DELETE FROM sys_table WHERE id = 'v_value_cat_node';

-- config_form_fields inp_dscenario_frpump
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'dscenario_id', 'lyt_main_1', 1, 'integer', 'text', 'Dscenario id:', 'Dscenario id', NULL, true, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'element_id', 'lyt_main_1', 2, 'integer', 'text', 'Element id:', 'Element id', NULL, true, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'power', 'lyt_main_1', 3, 'string', 'text', 'Power:', 'Power', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'curve_id', 'lyt_main_1', 4, 'string', 'combo', 'Curve id:', 'Curve id', NULL, false, NULL, true, NULL, false, 'SELECT id as id, id as idval FROM inp_curve WHERE id IS NOT NULL AND curve_type IN (''PUMP'', ''PUMP1'', ''PUMP2'', ''PUMP3'', ''PUMP4'')', true, true, NULL, NULL, NULL, '{"valueRelation":{"nullValue":false, "layer": "v_edit_inp_curve", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": null}}'::json, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'speed', 'lyt_main_1', 5, 'numeric', 'text', 'Speed:', 'Speed', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'pattern_id', 'lyt_main_1', 6, 'string', 'combo', 'Pattern id:', 'Pattern id', NULL, false, NULL, true, NULL, false, 'SELECT pattern_id as id, pattern_id as idval FROM inp_pattern WHERE pattern_id IS NOT NULL', true, true, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'status', 'lyt_main_1', 7, 'string', 'combo', 'Status:', 'Status', NULL, false, NULL, true, NULL, false, 'SELECT DISTINCT id AS id, idval AS idval FROM inp_typevalue WHERE id IS NOT NULL AND typevalue = ''inp_value_status_pump''', true, true, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'effic_curve_id', 'lyt_main_1', 8, 'string', 'combo', 'Eff. curve:', 'Eff. curve', NULL, false, NULL, true, NULL, false, 'SELECT id as id, id as idval FROM inp_curve WHERE id IS NOT NULL AND curve_type = ''EFFICIENCY''', true, true, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'energy_price', 'lyt_main_1', 9, 'double', 'text', 'Energy price:', 'Energy price', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frpump', 'form_feature', 'tab_none', 'energy_pattern_id', 'lyt_main_1', 10, 'string', 'combo', 'Price pattern:', 'Price pattern', NULL, false, NULL, true, NULL, false, 'SELECT pattern_id as id, pattern_id as idval FROM inp_pattern WHERE pattern_id IS NOT NULL', true, true, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, false, NULL);

-- config_form_fields inp_dscenario_frvalve
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'dscenario_id', 'lyt_main_1', 1, 'integer', 'text', 'Dscenario id:', 'Dscenario id', NULL, true, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'element_id', 'lyt_main_1', 2, 'integer', 'text', 'Element id:', 'Element id', NULL, true, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'valve_type', 'lyt_main_1', 3, 'string', 'combo', 'Valve type:', 'Valve type', NULL, false, NULL, true, NULL, false, 'SELECT DISTINCT id AS id, idval AS idval FROM inp_typevalue WHERE id IS NOT NULL AND typevalue = ''inp_typevalue_valve''', true, true, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'custom_dint', 'lyt_main_1', 4, 'numeric', 'text', 'Custom dint:', 'Custom dint', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'setting', 'lyt_main_1', 5, 'numeric', 'text', 'Setting:', 'Setting', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'curve_id', 'lyt_main_1', 6, 'string', 'combo', 'Curve id:', 'Curve id', NULL, false, NULL, true, NULL, false, 'SELECT id as id, id as idval FROM inp_curve WHERE id IS NOT NULL', true, true, NULL, NULL, NULL, '{"valueRelation":{"nullValue":false, "layer": "v_edit_inp_curve", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": null}}'::json, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'minorloss', 'lyt_main_1', 7, 'numeric', 'text', 'Minorloss:', 'Minorloss', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'add_settings', 'lyt_main_1', 8, 'double', 'text', 'Add settings:', 'Add settings', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frvalve', 'form_feature', 'tab_none', 'init_quality', 'lyt_main_1', 9, 'double', 'text', 'Init quality:', 'Init quality', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL);

-- config_form_fields inp_dscenario_frshortpipe
INSERT INTO config_form_fields
(formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
VALUES
('inp_dscenario_frshortpipe', 'form_feature', 'tab_none', 'dscenario_id', 'lyt_main_1', 1, 'integer', 'text', 'Dscenario id:', 'Dscenario id', NULL, true, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frshortpipe', 'form_feature', 'tab_none', 'element_id', 'lyt_main_1', 2, 'integer', 'text', 'Element id:', 'Element id', NULL, true, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frshortpipe', 'form_feature', 'tab_none', 'minorloss', 'lyt_main_1', 4, 'numeric', 'text', 'Minorloss:', 'Minorloss', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frshortpipe', 'form_feature', 'tab_none', 'status', 'lyt_main_1', 7, 'string', 'combo', 'Status:', 'Status', NULL, false, NULL, true, NULL, false, 'SELECT DISTINCT id AS id, idval AS idval FROM inp_typevalue WHERE id IS NOT NULL AND typevalue = ''inp_value_status_shortpipe_dscen''', true, true, NULL, NULL, NULL, '{"setMultiline":false}'::json, NULL, NULL, false, NULL),
('inp_dscenario_frshortpipe', 'form_feature', 'tab_none', 'bulk_coeff', 'lyt_main_1', 5, 'numeric', 'text', 'Bulk coeff:', 'Bulk coeff', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL),
('inp_dscenario_frshortpipe', 'form_feature', 'tab_none', 'wall_coeff', 'lyt_main_1', 5, 'numeric', 'text', 'Wall coeff:', 'Wall coeff', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"filterSign":"ILIKE"}'::json, NULL, NULL, NULL, false, NULL);

UPDATE sys_table
	SET addparam='{"pkey": "dscenario_id, element_id"}'::json
	WHERE id IN ('inp_dscenario_frpump', 'inp_dscenario_frvalve', 've_inp_dscenario_frpump', 've_inp_dscenario_frvalve');


update sys_param_user set dv_querytext= 'SELECT cat_link.id, cat_link.id AS idval FROM cat_link' where id ='edit_linkcat_vdefault';
delete from sys_param_user where id = 'edit_connec_linkcat_vdefault';
update sys_param_user set id = 'edit_connec_linkcat_vdefault' where id = 'edit_linkcat_vdefault';

INSERT INTO sys_feature_epa_type (id, feature_type, epa_table, descript, active) VALUES('FRSHORTPIPE', 'ELEMENT', 'inp_frshortpipe', NULL, true);

INSERT INTO cat_feature (id,feature_class,feature_type,parent_layer,child_layer,code_autofill,active) VALUES ('EMETER','FRELEM','ELEMENT','ve_element','ve_element_emeter',true,true);
INSERT INTO cat_feature_element (id, epa_default) VALUES ('EMETER', 'UNDEFINED') ON CONFLICT (id) DO NOTHING;

-- FRSHORTPIPE
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','to_arc','lyt_epa_data_1',3,'string','text','To arc:','To arc',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','add_to_dscenario','lyt_epa_dsc_1',1,'button',false,false,false,false,false,'{"icon":"113"}'::json,'{"saveValue": false}'::json,'{
  "functionName": "add_to_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_frshortpipe",
    "tablename": "ve_inp_dscenario_frshortpipe",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_frshortpipe", "view": "ve_inp_dscenario_frshortpipe", "add_view": "ve_inp_dscenario_frshortpipe", "pk": ["dscenario_id", "node_id"]}
   ]
, "add_dlg_title":"Shortpipe"   }
}'::json,'tbl_inp_dscenario_frshortpipe',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','edit_dscenario','lyt_epa_dsc_1',3,'button',false,false,true,false,false,'{"icon":"101"}'::json,'{"saveValue":false, "onContextMenu":"Edit dscenario"}'::json,'{
  "functionName": "edit_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_frshortpipe",
    "tablename": "ve_inp_dscenario_frshortpipe",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_frshortpipe", "view": "ve_inp_dscenario_frshortpipe", "add_view": "ve_inp_dscenario_frshortpipe", "pk": ["dscenario_id", "node_id"]}
   ]
, "add_dlg_title":"Shortpipe"   }
}'::json,'tbl_inp_dscenario_frshortpipe',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','remove_from_dscenario','lyt_epa_dsc_1',2,'button',false,false,false,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "onContextMenu":"Delete dscenario"}'::json,'{
  "functionName": "remove_from_dscenario",
  "module": "info",
  "parameters": {
    "targetwidget": "tab_epa_tbl_inp_frshortpipe",
    "tablename": "ve_inp_dscenario_frshortpipe",
    "pkey": [
      "dscenario_id",
      "node_id"
    ],
    "tableviews": [
		{"tbl": "tab_epa_tbl_inp_frshortpipe", "view": "ve_inp_dscenario_frshortpipe", "add_view": "ve_inp_dscenario_frshortpipe", "pk": ["dscenario_id", "node_id"]}
   ]
  }
}'::json,'tbl_inp_dscenario_frshortpipe',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','tbl_inp_shortpipe','lyt_epa_dsc_3',1,'tableview',false,false,false,false,false,'{"saveValue": false, "tableUpsert":"ve_inp_dscenario_frshortpipe"}'::json,'tbl_inp_dscenario_frshortpipe',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','nodarc_id','lyt_epa_data_1',1,'string','text','Nodarc id:','Nodarc id',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','minorloss','lyt_epa_data_1',2,'string','text','Minorloss:','Minorloss',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','wall_coeff','lyt_epa_data_1',6,'string','text','Wall coefficient:','Wall coefficient',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','result_id','lyt_epa_data_2',1,'string','text','Result id:','Result id',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','headloss_max','lyt_epa_data_2',8,'string','text','Max headloss:','Max headloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','headloss_min','lyt_epa_data_2',9,'string','text','Min uheadloss:','Max uheadloss',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','setting_max','lyt_epa_data_2',12,'string','text','Max setting:','Max setting',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','setting_min','lyt_epa_data_2',13,'string','text','Min setting:','Min setting',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','reaction_max','lyt_epa_data_2',14,'string','text','Max reaction:','Max reaction',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','reaction_min','lyt_epa_data_2',15,'string','text','Min reaction:','Min reaction',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','ffactor_max','lyt_epa_data_2',16,'string','text','Max Ffactor:','Max Ffactor',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','ffactor_min','lyt_epa_data_2',17,'string','text','Min Ffactor:','Min Ffactor',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','bulk_coeff','lyt_epa_data_1',5,'string','text','Buk coefficient:','Buk coefficient',false,false,true,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,linkedobject,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','hspacer_epa_1','lyt_epa_dsc_1',4,'hspacer',false,false,false,false,false,'{"saveValue": false}'::json,'tbl_inp_dscenario_frshortpipe',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','cat_dint','lyt_epa_data_1',7,'string','text','Cat dint:','Cat dint',false,false,false,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','custom_dint','lyt_epa_data_1',8,'string','text','Custom dint:','Custom dint',false,false,true,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','flow_max','lyt_epa_data_2',2,'string','text','Max flow:','Max Flow',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','flow_min','lyt_epa_data_2',3,'string','text','Min flow:','Min Flow',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','vel_max','lyt_epa_data_2',5,'string','text','Max velocity:','Max velocity',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','vel_min','lyt_epa_data_2',6,'string','text','Min velocity:','Min velocity',false,false,false,false,false,'{"filterSign":"ILIKE"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,hidden)
	VALUES ('ve_epa_frshortpipe','form_feature','tab_epa','status','lyt_epa_data_1',4,'string','text','Status:','Status',false,false,false,false,false,'{"setMultiline":false}'::json,false);


INSERT INTO cat_element (id,element_type,active) VALUES ('EMETER-01','EMETER',true);

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


INSERT INTO edit_typevalue (typevalue, id, idval, descript, addparam) VALUES
  ('man_pump_pump_type', '0', 'UNKNOWN', NULL, NULL),
  ('man_pump_pump_type', '1', 'SUBMERSIBLE', NULL, NULL),
  ('man_pump_pump_type', '2', 'SURFACE', NULL, NULL),
  ('man_pump_pump_type', '3', 'DRY WELL', NULL, NULL),
  ('man_pump_engine_type', '0', 'UNKNOWN', NULL, NULL),
  ('man_pump_engine_type', '1', 'ELECTRIC', NULL, NULL),
  ('man_pump_engine_type', '2', 'COMBUSTION', NULL, NULL),
  ('man_pump_engine_type', '3', 'COMBINED', NULL, NULL)
ON CONFLICT (typevalue, id) DO NOTHING;


INSERT INTO sys_foreignkey (typevalue_table, typevalue_name, target_table, target_field, parameter_id, active)
VALUES('edit_typevalue', 'man_pump_pump_type', 'man_pump', 'pump_type', NULL, true)
ON CONFLICT (typevalue_table, typevalue_name, target_table, target_field) DO NOTHING;

INSERT INTO sys_foreignkey (typevalue_table, typevalue_name, target_table, target_field, parameter_id, active)
VALUES('edit_typevalue', 'man_pump_engine_type', 'man_pump', 'engine_type', NULL, true)
ON CONFLICT (typevalue_table, typevalue_name, target_table, target_field) DO NOTHING;

DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN (SELECT child_layer FROM cat_feature WHERE feature_class = 'PUMP')
  LOOP
    INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder,
    "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter,
    dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc,
    stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
    VALUES(rec.child_layer, 'form_feature', 'tab_data', 'pump_type', 'lyt_data_2', (SELECT max(layoutorder) + 1 AS layoutorder FROM config_form_fields WHERE formname = rec.child_layer AND tabname = 'tab_data' AND layoutname = 'lyt_data_2'),
    'integer', 'combo', 'Pump Type:', 'Pump Type', NULL, false, false, true, false, NULL,
    'SELECT id, idval FROM edit_typevalue WHERE typevalue = ''man_pump_pump_type''', true, false, NULL, NULL,
    NULL, NULL, NULL, NULL, true, NULL)
    ON CONFLICT (formname, formtype, tabname, columnname) DO UPDATE SET
    layoutorder = EXCLUDED.layoutorder,
    datatype = EXCLUDED.datatype,
    widgettype = EXCLUDED.widgettype,
    label = EXCLUDED.label,
    dv_querytext = EXCLUDED.dv_querytext,
    dv_orderby_id = EXCLUDED.dv_orderby_id,
    dv_isnullvalue = EXCLUDED.dv_isnullvalue,
    dv_parent_id = EXCLUDED.dv_parent_id,
    dv_querytext_filterc = EXCLUDED.dv_querytext_filterc,
    hidden = EXCLUDED.hidden;


    INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder,
    "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter,
    dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc,
    stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
    VALUES(rec.child_layer, 'form_feature', 'tab_data', 'engine_type', 'lyt_data_2', (SELECT max(layoutorder) + 1 AS layoutorder FROM config_form_fields WHERE formname = rec.child_layer AND tabname = 'tab_data' AND layoutname = 'lyt_data_2'),
    'integer', 'combo', 'Engine Type:', 'Engine Type', NULL, false, false, true, false, NULL,
    'SELECT id, idval FROM edit_typevalue WHERE typevalue = ''man_pump_engine_type''', true, false, NULL, NULL,
    NULL, NULL, NULL, NULL, true, NULL)
    ON CONFLICT (formname, formtype, tabname, columnname) DO UPDATE SET
    layoutorder = EXCLUDED.layoutorder,
    datatype = EXCLUDED.datatype,
    widgettype = EXCLUDED.widgettype,
    label = EXCLUDED.label,
    dv_querytext = EXCLUDED.dv_querytext,
    dv_orderby_id = EXCLUDED.dv_orderby_id,
    dv_isnullvalue = EXCLUDED.dv_isnullvalue,
    dv_parent_id = EXCLUDED.dv_parent_id,
    dv_querytext_filterc = EXCLUDED.dv_querytext_filterc,
    hidden = EXCLUDED.hidden;
  END LOOP;
END $$;

DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN (SELECT child_layer FROM cat_feature WHERE feature_class = 'METER')
  LOOP
    INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder,
    "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter,
    dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc,
    stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder)
    VALUES(rec.child_layer, 'form_feature', 'tab_data', 'nominal_flowrate', 'lyt_data_2', (SELECT max(layoutorder) + 1 AS layoutorder FROM config_form_fields WHERE formname = rec.child_layer AND tabname = 'tab_data' AND layoutname = 'lyt_data_2'),
    'numeric', 'text', 'Nominal Flowrate:', 'Nominal Flowrate:', NULL, false, false, true, false, NULL,
    NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, true, NULL)
    ON CONFLICT (formname, formtype, tabname, columnname) DO UPDATE SET
    layoutorder = EXCLUDED.layoutorder,
    datatype = EXCLUDED.datatype,
    widgettype = EXCLUDED.widgettype,
    label = EXCLUDED.label,
    dv_querytext = EXCLUDED.dv_querytext,
    dv_orderby_id = EXCLUDED.dv_orderby_id,
    dv_isnullvalue = EXCLUDED.dv_isnullvalue,
    dv_parent_id = EXCLUDED.dv_parent_id,
    dv_querytext_filterc = EXCLUDED.dv_querytext_filterc,
    hidden = EXCLUDED.hidden;
  END LOOP;
END $$;

DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN (SELECT child_layer FROM cat_feature WHERE feature_class = 'WTP')
  LOOP
    UPDATE config_form_fields SET columnname = 'chemical' WHERE formname = rec.child_layer AND columnname = 'chemcond';
    DELETE FROM config_form_fields WHERE formname = rec.child_layer AND columnname = 'chemtreatment';
  END LOOP;
END $$;
UPDATE config_info_layer
	SET orderby=6
	WHERE layer_id='ve_dimensions';
UPDATE config_info_layer
	SET orderby=5
	WHERE layer_id='ve_arc';

DELETE FROM config_form_fields WHERE formname ILIKE 've_element%' AND formtype='form_feature' AND columnname='tbl_element_x_gully' AND tabname='tab_features';

-- Add tab_documents for emeter
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_element_emeter','form_feature','tab_documents','btn_doc_delete','lyt_document_2',3,'button','Delete document',false,false,true,false,false,'{"icon":"114"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Delete document"}'::json,'{"functionName": "delete_object", "parameters": {"columnfind": "doc_id", "targetwidget": "tab_documents_tbl_documents", "sourceview": "doc"}}'::json,'tbl_doc_x_element',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_element_emeter','form_feature','tab_documents','btn_doc_insert','lyt_document_2',2,'button','Insert document',false,false,true,false,false,'{"icon":"113"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "add_object",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_element_emeter','form_feature','tab_documents','btn_doc_new','lyt_document_2',4,'button','New document',false,false,true,false,false,'{"icon":"143"}'::json,'{"saveValue":false, "filterSign":"="}'::json,'{
  "functionName": "manage_document",
  "parameters": {
    "sourcewidget": "tab_documents_doc_name",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_element_emeter','form_feature','tab_documents','date_from','lyt_document_1',1,'date','datetime','Date from:','Date from:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":">="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,1);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_element_emeter','form_feature','tab_documents','date_to','lyt_document_1',2,'date','datetime','Date to:','Date to:',false,false,true,false,true,'{"labelPosition": "top", "filterSign":"<="}'::json,'{"functionName": "filter_table", "parameters":{"columnfind": "date"}}'::json,'tbl_doc_x_element',false,2);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,widgetcontrols,widgetfunction,hidden)
	VALUES ('ve_element_emeter','form_feature','tab_documents','doc_name','lyt_document_2',0,'string','typeahead','Doc id:','Doc id:',false,false,true,false,false,'SELECT name as id, name as idval FROM doc WHERE name IS NOT NULL','{"saveValue": false, "filterSign":"ILIKE"}'::json,'{"functionName": "filter_table"}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,dv_querytext,dv_isnullvalue,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_element_emeter','form_feature','tab_documents','doc_type','lyt_document_1',3,'string','combo','Doc type:','Doc type:',false,false,true,false,true,'SELECT id as id, idval as idval FROM edit_typevalue WHERE typevalue = ''doc_type''',true,'{"labelPosition": "top"}'::json,'{"functionName": "filter_table", "parameters":{}}'::json,'tbl_doc_x_element',false,3);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('ve_element_emeter','form_feature','tab_documents','hspacer_document_1','lyt_document_2',10,'hspacer',false,false,true,false,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,tooltip,ismandatory,isparent,iseditable,isautoupdate,isfilter,stylesheet,widgetcontrols,widgetfunction,linkedobject,hidden)
	VALUES ('ve_element_emeter','form_feature','tab_documents','open_doc','lyt_document_2',11,'button','Open document',false,false,true,false,false,'{"icon":"147"}'::json,'{"saveValue":false, "filterSign":"=", "onContextMenu":"Open document"}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "columnfind": "path",
    "targetwidget": "tab_documents_tbl_documents",
    "sourceview": "doc"
  }
}'::json,'tbl_doc_x_element',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,widgettype,ismandatory,isparent,iseditable,isautoupdate,isfilter,widgetcontrols,widgetfunction,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_element_emeter','form_feature','tab_documents','tbl_documents','lyt_document_3',1,'tableview',false,false,false,false,false,'{"saveValue": false}'::json,'{
  "functionName": "open_selected_path",
  "parameters": {
    "targetwidget": "tab_documents_tbl_documents",
    "columnfind": "path"
  }
}'::json,'tbl_doc_x_element',false,4);

UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=1, alias='Node features' WHERE id='ve_cat_feature_node';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=2, alias='Arc features' WHERE id='ve_cat_feature_arc';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=3, alias='Connec features' WHERE id='ve_cat_feature_connec';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=4, alias='Link features' WHERE id='ve_cat_feature_link';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=5, alias='Element features' WHERE id='ve_cat_feature_element';

UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=6, alias='Node catalog' WHERE id='cat_node';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=7, alias='Arc catalog' WHERE id='cat_arc';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=8, alias='Connec catalog' WHERE id='cat_connec';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=9, alias='Link catalog' WHERE id='cat_link';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=10, alias='Element catalog' WHERE id='cat_element';
UPDATE sys_table SET project_template='{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, context='{"levels": ["INVENTORY", "CATALOGS"]}', orderby=11, alias='Material catalog' WHERE id='cat_material';


INSERT INTO sys_label (id, idval, label_type) 
VALUES(3013, 'To check CRITICAL ERRORS or WARNINGS, execute a query FROM anl_table WHERE fid=error number AND current_user. For example:

SELECT * FROM MySchema.anl_arc WHERE fid = Myfid AND cur_user=current_user;

Only the errors with anl_table next to the number can be checked this way. Using Giswater Toolbox it''s also posible to check these errors.', 'header');

UPDATE sys_style
SET styletype='qml', stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis labelsEnabled="1" version="3.40.8-Bratislava" styleCategories="Symbology|Labeling">
  <renderer-v2 type="categorizedSymbol" forceraster="0" referencescale="-1" attr="state" symbollevels="0" enableorderby="0">
    <categories>
      <category type="long" uuid="{fafb3932-336b-408a-b613-7564fa603517}" value="0" symbol="0" render="true" label="OBSOLETE"/>
      <category type="string" uuid="{2e0bc629-0440-42a8-bf37-83a5302de991}" value="1" symbol="1" render="true" label="OPERATIVE"/>
      <category type="long" uuid="{a6c3dc9a-d6c8-41f1-b37d-f9bdb0a71f65}" value="2" symbol="2" render="true" label="PLANIFIED"/>
    </categories>
    <symbols>
      <symbol clip_to_extent="1" alpha="1" type="line" is_animated="0" force_rhr="0" frame_rate="10" name="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{7495e564-1f2e-4c4e-adf2-96c2a06cbe10}" class="SimpleLine" pass="0" enabled="1">
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
            <Option type="QString" value="227,26,28,255,rgb:0.8901960784313725,0.10196078431372549,0.10980392156862745,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.5" name="line_width"/>
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
              <Option type="Map" name="properties">
                <Option type="Map" name="outlineWidth">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="case when cat_dnom is not null then&#xd;&#xa;-4.862 + 0.977 * ln(&quot;cat_dnom&quot; + 159.243)&#xd;&#xa;else 0.25 end" name="expression"/>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" alpha="1" type="line" is_animated="0" force_rhr="0" frame_rate="10" name="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{b64bb163-e03e-4b0d-843e-76c497204421}" class="SimpleLine" pass="0" enabled="1">
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
            <Option type="QString" value="31,120,180,255,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.5" name="line_width"/>
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
              <Option type="Map" name="properties">
                <Option type="Map" name="outlineWidth">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="case when cat_dnom is not null then&#xd;&#xa;-4.862 + 0.977 * ln(&quot;cat_dnom&quot; + 159.243)&#xd;&#xa;else 0.25 end" name="expression"/>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" alpha="1" type="line" is_animated="0" force_rhr="0" frame_rate="10" name="2">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{8e6baa60-d3ad-4440-baf0-f5e293ac693f}" class="SimpleLine" pass="0" enabled="1">
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
            <Option type="QString" value="230,186,68,255,rgb:0.90196078431372551,0.72941176470588232,0.26666666666666666,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.5" name="line_width"/>
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
              <Option type="Map" name="properties">
                <Option type="Map" name="outlineWidth">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="case when cat_dnom is not null then&#xd;&#xa;-4.862 + 0.977 * ln(&quot;cat_dnom&quot; + 159.243)&#xd;&#xa;else 0.25 end" name="expression"/>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <source-symbol>
      <symbol clip_to_extent="1" alpha="1" type="line" is_animated="0" force_rhr="0" frame_rate="10" name="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{38fef836-dca4-44ce-94cc-d00396fe66f2}" class="SimpleLine" pass="0" enabled="1">
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
            <Option type="QString" value="227,61,39,255,rgb:0.8901960784313725,0.23921568627450981,0.15294117647058825,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.5" name="line_width"/>
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
      <symbol clip_to_extent="1" alpha="1" type="line" is_animated="0" force_rhr="0" frame_rate="10" name="">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{f0817fea-ea6c-4aa3-912a-22eceb8fe77a}" class="SimpleLine" pass="0" enabled="1">
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
      <text-style fontWeight="50" legendString="Aa" fontItalic="0" allowHtml="0" fontSizeMapUnitScale="3x:0,0,0,0,0,0" fontStrikeout="0" fontSizeUnit="Point" fieldName="arccat_id" forcedBold="0" blendMode="0" tabStopDistance="80" capitalization="0" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" isExpression="0" fontUnderline="0" useSubstitutions="0" textColor="0,0,0,255,rgb:0,0,0,1" fontKerning="1" stretchFactor="100" tabStopDistanceUnit="Point" fontSize="8" multilineHeight="1" multilineHeightUnit="Percentage" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" fontFamily="Arial" fontWordSpacing="0" namedStyle="Normal" textOpacity="1" forcedItalic="0" textOrientation="horizontal" fontLetterSpacing="0">
        <families/>
        <text-buffer bufferNoFill="1" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferColor="255,255,255,255,rgb:1,1,1,1" bufferJoinStyle="128" bufferOpacity="1" bufferBlendMode="0" bufferSize="1" bufferDraw="0" bufferSizeUnits="MM"/>
        <text-mask maskSizeUnits="MM" maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskEnabled="0" maskSize="1.5" maskJoinStyle="128" maskOpacity="1" maskType="0" maskSize2="1.5" maskedSymbolLayers=""/>
        <background shapeOpacity="1" shapeOffsetY="0" shapeRotation="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeBorderColor="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidth="0" shapeSizeX="0" shapeOffsetUnit="MM" shapeType="0" shapeSizeY="0" shapeSizeUnit="MM" shapeRadiiUnit="MM" shapeBlendMode="0" shapeRotationType="0" shapeJoinStyle="64" shapeDraw="0" shapeRadiiX="0" shapeRadiiY="0" shapeOffsetX="0" shapeSVGFile="" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeSizeType="0" shapeBorderWidthUnit="MM">
          <symbol clip_to_extent="1" alpha="1" type="marker" is_animated="0" force_rhr="0" frame_rate="10" name="markerSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="243,166,178,255,rgb:0.95294117647058818,0.65098039215686276,0.69803921568627447,1" name="color"/>
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
          <symbol clip_to_extent="1" alpha="1" type="fill" is_animated="0" force_rhr="0" frame_rate="10" name="fillSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleFill" pass="0" enabled="1">
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
        <shadow shadowOpacity="0.69999999999999996" shadowRadius="1.5" shadowRadiusUnit="MM" shadowUnder="0" shadowOffsetAngle="135" shadowDraw="0" shadowRadiusAlphaOnly="0" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowBlendMode="6" shadowOffsetDist="1" shadowScale="100" shadowOffsetUnit="MM" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowOffsetGlobal="1"/>
        <dd_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format useMaxLineLengthForAutoWrap="1" placeDirectionSymbol="0" autoWrapLength="0" reverseDirectionSymbol="0" leftDirectionSymbol="&lt;" addDirectionSymbol="0" plussign="0" decimals="3" formatNumbers="0" rightDirectionSymbol=">" wrapChar="" multilineAlign="0"/>
      <placement dist="0" geometryGenerator="" allowDegraded="0" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" priority="5" placement="2" maxCurvedCharAngleIn="25" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" rotationAngle="0" geometryGeneratorType="PointGeometry" maximumDistance="0" polygonPlacementFlags="2" prioritization="PreferCloser" distMapUnitScale="3x:0,0,0,0,0,0" repeatDistanceUnits="MM" offsetType="0" lineAnchorPercent="0.5" fitInPolygonOnly="0" lineAnchorClipping="0" maximumDistanceUnit="MM" xOffset="0" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" repeatDistance="0" yOffset="0" maxCurvedCharAngleOut="-25" offsetUnits="MM" centroidWhole="0" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" preserveRotation="1" placementFlags="10" layerType="LineGeometry" lineAnchorTextPoint="CenterOfText" overrunDistance="0" rotationUnit="AngleDegrees" overrunDistanceUnit="MM" distUnits="MM" lineAnchorType="0" overlapHandling="PreventOverlap" centroidInside="0" geometryGeneratorEnabled="0" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" quadOffset="4"/>
      <rendering fontMinPixelSize="3" scaleMin="0" upsidedownLabels="0" obstacleFactor="1" mergeLines="0" scaleMax="1000" limitNumLabels="0" unplacedVisibility="0" zIndex="0" labelPerPart="0" drawLabels="1" fontLimitPixelSize="0" fontMaxPixelSize="10000" maxNumLabels="2000" scaleVisibility="1" obstacleType="0" obstacle="1" minFeatureSize="0"/>
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
          <Option type="QString" value="&lt;symbol clip_to_extent=&quot;1&quot; alpha=&quot;1&quot; type=&quot;line&quot; is_animated=&quot;0&quot; force_rhr=&quot;0&quot; frame_rate=&quot;10&quot; name=&quot;symbol&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer locked=&quot;0&quot; id=&quot;{689903dd-a85a-463f-bb88-ed300bdbb196}&quot; class=&quot;SimpleLine&quot; pass=&quot;0&quot; enabled=&quot;1&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;align_dash_pattern&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;square&quot; name=&quot;capstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;5;2&quot; name=&quot;customdash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;customdash_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;customdash_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;dash_pattern_offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;dash_pattern_offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;dash_pattern_offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;draw_inside_polygon&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;bevel&quot; name=&quot;joinstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.23529411764705882,0.23529411764705882,0.23529411764705882,1&quot; name=&quot;line_color&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;solid&quot; name=&quot;line_style&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0.3&quot; name=&quot;line_width&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;line_width_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;ring_filter&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_end&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_end_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_end_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_start&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_start_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_start_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;tweak_dash_pattern_on_corners&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;use_custom_dash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;width_map_unit_scale&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>" name="lineSymbol"/>
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
</qgis>
', active=true
WHERE layername='ve_arc' AND styleconfig_id=101;



UPDATE sys_style
SET styletype='qml', stylevalue='<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis labelsEnabled="1" version="3.40.8-Bratislava" styleCategories="Symbology|Labeling">
  <renderer-v2 type="RuleRenderer" forceraster="0" referencescale="-1" symbollevels="0" enableorderby="0">
    <rules key="{cd75f41e-3b1d-443c-8148-fbc4436aa9cb}">
      <rule filter=" &quot;sys_type&quot; = ''GREENTAP''" key="{24b63ac0-a836-4203-bd64-161a0112ee9a}" symbol="0" scalemaxdenom="1500" label="Greentap" scalemindenom="1"/>
      <rule filter=" &quot;sys_type&quot; =''WJOIN''" key="{abcdb374-fe6a-4d04-a466-31fdd93144e8}" symbol="1" scalemaxdenom="1500" label="Wjoin" scalemindenom="1"/>
      <rule filter=" &quot;sys_type&quot; =''TAP''" key="{7dc90f4d-d098-491a-b817-e7ea68fc2fd6}" symbol="2" scalemaxdenom="1500" label="Tap" scalemindenom="1"/>
      <rule filter=" &quot;sys_type&quot; =''FOUNTAIN''" key="{39e4856f-0fc3-4498-8d4b-44d2851b421f}" symbol="3" scalemaxdenom="1500" label="Fountain" scalemindenom="1"/>
    </rules>
    <symbols>
      <symbol clip_to_extent="1" alpha="1" type="marker" is_animated="0" force_rhr="0" frame_rate="10" name="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{12cc35f6-2de1-4246-b4e0-8a183935eeae}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="201,246,158,255,rgb:0.78823529411764703,0.96470588235294119,0.61960784313725492,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0,0,0,255,rgb:0,0,0,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="1.6" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option type="Map" name="properties">
                <Option type="Map" name="size">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="var(''map_scale'')" name="expression"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" value="0.57" name="exponent"/>
                      <Option type="double" value="1" name="maxSize"/>
                      <Option type="double" value="1500" name="maxValue"/>
                      <Option type="double" value="3.5" name="minSize"/>
                      <Option type="double" value="0" name="minValue"/>
                      <Option type="double" value="0" name="nullSize"/>
                      <Option type="int" value="2" name="scaleType"/>
                    </Option>
                    <Option type="int" value="1" name="t"/>
                  </Option>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" alpha="1" type="marker" is_animated="0" force_rhr="0" frame_rate="10" name="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{362f8968-f888-433b-90e4-e5098d869499}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="49,180,227,255,rgb:0.19215686274509805,0.70588235294117652,0.8901960784313725,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="49,180,227,255,rgb:0.19215686274509805,0.70588235294117652,0.8901960784313725,1" name="outline_color"/>
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
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="rotation" name="field"/>
                  <Option type="int" value="2" name="type"/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))" name="expression"/>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{67948e1f-e6bb-4593-b5ad-8bb9fcf49d7d}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="255,0,0,255,rgb:1,0,0,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="cross" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0,0,0,255,rgb:0,0,0,1" name="outline_color"/>
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
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="rotation" name="field"/>
                  <Option type="int" value="2" name="type"/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="var(''map_scale'')" name="expression"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" value="0.37" name="exponent"/>
                      <Option type="double" value="2" name="maxSize"/>
                      <Option type="double" value="1500" name="maxValue"/>
                      <Option type="double" value="3.5" name="minSize"/>
                      <Option type="double" value="0" name="minValue"/>
                      <Option type="double" value="0" name="nullSize"/>
                      <Option type="int" value="3" name="scaleType"/>
                    </Option>
                    <Option type="int" value="1" name="t"/>
                  </Option>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" alpha="1" type="marker" is_animated="0" force_rhr="0" frame_rate="10" name="2">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{9be7c088-b096-4952-9c7a-3fe50ee2852a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="31,120,180,255,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="square" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0,0,0,255,rgb:0,0,0,1" name="outline_color"/>
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
              <Option type="Map" name="properties">
                <Option type="Map" name="size">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="var(''map_scale'')" name="expression"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" value="0.37" name="exponent"/>
                      <Option type="double" value="1.5" name="maxSize"/>
                      <Option type="double" value="1500" name="maxValue"/>
                      <Option type="double" value="3.5" name="minSize"/>
                      <Option type="double" value="0" name="minValue"/>
                      <Option type="double" value="0" name="nullSize"/>
                      <Option type="int" value="3" name="scaleType"/>
                    </Option>
                    <Option type="int" value="1" name="t"/>
                  </Option>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" alpha="1" type="marker" is_animated="0" force_rhr="0" frame_rate="10" name="3">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{d8e73060-669b-4565-9660-e859c06a83fd}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="44,67,207,83,rgb:0.17254901960784313,0.2627450980392157,0.81176470588235294,0.32549019607843138" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="triangle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="22,0,148,255,rgb:0.08627450980392157,0,0.58039215686274515,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="4.2" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option type="Map" name="properties">
                <Option type="Map" name="size">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="var(''map_scale'')" name="expression"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" value="0.37" name="exponent"/>
                      <Option type="double" value="2.5" name="maxSize"/>
                      <Option type="double" value="1500" name="maxValue"/>
                      <Option type="double" value="5" name="minSize"/>
                      <Option type="double" value="0" name="minValue"/>
                      <Option type="double" value="0" name="nullSize"/>
                      <Option type="int" value="3" name="scaleType"/>
                    </Option>
                    <Option type="int" value="1" name="t"/>
                  </Option>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{b07449ae-bcc9-48eb-8ebd-ae0ffa344f84}" class="FontMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="F" name="chr"/>
            <Option type="QString" value="22,0,148,255,rgb:0.08627450980392157,0,0.58039215686274515,1" name="color"/>
            <Option type="QString" value="Arial" name="font"/>
            <Option type="QString" value="" name="font_style"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="0.20000000000000001,0.20000000000000001" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0,0,0,255,rgb:0,0,0,1" name="outline_color"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="3" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option type="Map" name="properties">
                <Option type="Map" name="offset">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="tostring(0.047619*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0)))|| '','' || tostring(0.047619*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0)))" name="expression"/>
                  <Option type="int" value="3" name="type"/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" value="true" name="active"/>
                  <Option type="QString" value="0.714286*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 5, 2.5, 0.37), 0))" name="expression"/>
                  <Option type="int" value="3" name="type"/>
                </Option>
              </Option>
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
      <symbol clip_to_extent="1" alpha="1" type="marker" is_animated="0" force_rhr="0" frame_rate="10" name="">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{593cbcfc-245e-4774-ad13-56169b965bf5}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="255,0,0,255,rgb:1,0,0,1" name="color"/>
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
    </selectionSymbol>
  </selection>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style fontWeight="50" legendString="Aa" fontItalic="0" allowHtml="0" fontSizeMapUnitScale="3x:0,0,0,0,0,0" fontStrikeout="0" fontSizeUnit="Point" fieldName="arc_id" forcedBold="0" blendMode="0" tabStopDistance="80" capitalization="0" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" isExpression="0" fontUnderline="0" useSubstitutions="0" textColor="50,50,50,255,rgb:0.19607843137254902,0.19607843137254902,0.19607843137254902,1" fontKerning="1" stretchFactor="100" tabStopDistanceUnit="Point" fontSize="8" multilineHeight="1" multilineHeightUnit="Percentage" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" fontFamily="Arial" fontWordSpacing="0" namedStyle="Normal" textOpacity="1" forcedItalic="0" textOrientation="horizontal" fontLetterSpacing="0">
        <families/>
        <text-buffer bufferNoFill="1" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferColor="250,250,250,255,rgb:0.98039215686274506,0.98039215686274506,0.98039215686274506,1" bufferJoinStyle="128" bufferOpacity="1" bufferBlendMode="0" bufferSize="1" bufferDraw="0" bufferSizeUnits="MM"/>
        <text-mask maskSizeUnits="MM" maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskEnabled="0" maskSize="1.5" maskJoinStyle="128" maskOpacity="1" maskType="0" maskSize2="1.5" maskedSymbolLayers=""/>
        <background shapeOpacity="1" shapeOffsetY="0" shapeRotation="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeBorderColor="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidth="0" shapeSizeX="0" shapeOffsetUnit="Point" shapeType="0" shapeSizeY="0" shapeSizeUnit="Point" shapeRadiiUnit="Point" shapeBlendMode="0" shapeRotationType="0" shapeJoinStyle="64" shapeDraw="0" shapeRadiiX="0" shapeRadiiY="0" shapeOffsetX="0" shapeSVGFile="" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeSizeType="0" shapeBorderWidthUnit="Point">
          <symbol clip_to_extent="1" alpha="1" type="marker" is_animated="0" force_rhr="0" frame_rate="10" name="markerSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="145,82,45,255,rgb:0.56862745098039214,0.32156862745098042,0.17647058823529413,1" name="color"/>
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
          <symbol clip_to_extent="1" alpha="1" type="fill" is_animated="0" force_rhr="0" frame_rate="10" name="fillSymbol">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleFill" pass="0" enabled="1">
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
                <Option type="QString" value="Point" name="outline_width_unit"/>
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
        <shadow shadowOpacity="0.69999999999999996" shadowRadius="1.5" shadowRadiusUnit="MM" shadowUnder="0" shadowOffsetAngle="135" shadowDraw="0" shadowRadiusAlphaOnly="0" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowBlendMode="6" shadowOffsetDist="1" shadowScale="100" shadowOffsetUnit="MM" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowOffsetGlobal="1"/>
        <dd_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format useMaxLineLengthForAutoWrap="1" placeDirectionSymbol="0" autoWrapLength="0" reverseDirectionSymbol="0" leftDirectionSymbol="&lt;" addDirectionSymbol="0" plussign="0" decimals="3" formatNumbers="0" rightDirectionSymbol=">" wrapChar="" multilineAlign="3"/>
      <placement dist="0" geometryGenerator="" allowDegraded="0" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" priority="5" placement="6" maxCurvedCharAngleIn="25" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" rotationAngle="0" geometryGeneratorType="PointGeometry" maximumDistance="0" polygonPlacementFlags="2" prioritization="PreferCloser" distMapUnitScale="3x:0,0,0,0,0,0" repeatDistanceUnits="MM" offsetType="1" lineAnchorPercent="0.5" fitInPolygonOnly="0" lineAnchorClipping="0" maximumDistanceUnit="MM" xOffset="0" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" repeatDistance="0" yOffset="0" maxCurvedCharAngleOut="-25" offsetUnits="MM" centroidWhole="0" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" preserveRotation="1" placementFlags="10" layerType="PointGeometry" lineAnchorTextPoint="FollowPlacement" overrunDistance="0" rotationUnit="AngleDegrees" overrunDistanceUnit="MM" distUnits="MM" lineAnchorType="0" overlapHandling="PreventOverlap" centroidInside="0" geometryGeneratorEnabled="0" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" quadOffset="4"/>
      <rendering fontMinPixelSize="3" scaleMin="0" upsidedownLabels="0" obstacleFactor="1" mergeLines="0" scaleMax="1000" limitNumLabels="0" unplacedVisibility="0" zIndex="0" labelPerPart="0" drawLabels="1" fontLimitPixelSize="0" fontMaxPixelSize="10000" maxNumLabels="2000" scaleVisibility="1" obstacleType="1" obstacle="1" minFeatureSize="0"/>
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
          <Option type="QString" value="&lt;symbol clip_to_extent=&quot;1&quot; alpha=&quot;1&quot; type=&quot;line&quot; is_animated=&quot;0&quot; force_rhr=&quot;0&quot; frame_rate=&quot;10&quot; name=&quot;symbol&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer locked=&quot;0&quot; id=&quot;{34ea86e0-1d64-4ca5-82de-01027fcdd763}&quot; class=&quot;SimpleLine&quot; pass=&quot;0&quot; enabled=&quot;1&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;align_dash_pattern&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;square&quot; name=&quot;capstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;5;2&quot; name=&quot;customdash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;customdash_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;customdash_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;dash_pattern_offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;dash_pattern_offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;dash_pattern_offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;draw_inside_polygon&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;bevel&quot; name=&quot;joinstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.23529411764705882,0.23529411764705882,0.23529411764705882,1&quot; name=&quot;line_color&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;solid&quot; name=&quot;line_style&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0.3&quot; name=&quot;line_width&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;line_width_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;ring_filter&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_end&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_end_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_end_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_start&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_start_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_start_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;tweak_dash_pattern_on_corners&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;use_custom_dash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;width_map_unit_scale&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>" name="lineSymbol"/>
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
  <layerGeometryType>0</layerGeometryType>
</qgis>
', active=true
WHERE layername='ve_connec' AND styleconfig_id=101;

ALTER TABLE element DROP CONSTRAINT IF EXISTS element_epa_type_check;
ALTER TABLE "element" ADD CONSTRAINT element_epa_type_check CHECK (((epa_type)::text = ANY (ARRAY['FRPUMP'::text, 'FRVALVE'::text, 'UNDEFINED'::text, 'FRSHORTPIPE'::text])));


ALTER TABLE "element" ADD CONSTRAINT element_expl_id_fkey FOREIGN KEY (expl_id) REFERENCES exploitation(expl_id);
ALTER TABLE man_frelem ADD CONSTRAINT man_frelem_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id);

ALTER TABLE rpt_arc_stats ADD CONSTRAINT rpt_arc_stats_result_id_fkey FOREIGN KEY (result_id) REFERENCES rpt_cat_result(result_id) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE om_waterbalance_dma_graph ADD CONSTRAINT om_waterbalance_dma_graph_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(node_id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE arc ADD CONSTRAINT arc_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id);
ALTER TABLE connec ADD CONSTRAINT connec_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id);
ALTER TABLE node ADD CONSTRAINT node_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id);
ALTER TABLE "element" ADD CONSTRAINT element_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES cat_brand(id);

ALTER TABLE arc ADD CONSTRAINT arc_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id);
ALTER TABLE connec ADD CONSTRAINT connec_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id);
ALTER TABLE node ADD CONSTRAINT node_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id);
ALTER TABLE "element" ADD CONSTRAINT element_model_id_fkey FOREIGN KEY (model_id) REFERENCES cat_brand_model(id);

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link('LINK');

-- old v_edit parent tables:
CREATE TRIGGER gw_trg_edit_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_arc('parent');

CREATE TRIGGER gw_trg_edit_node INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_node
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_node('parent');

CREATE TRIGGER gw_trg_edit_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR UPDATE OR DELETE ON v_edit_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link('parent');
-- ================================
CREATE TRIGGER gw_trg_edit_ve_epa_frpump INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_frpump
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frpump');

CREATE TRIGGER gw_trg_edit_ve_epa_frvalve INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_frvalve
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frvalve');

CREATE TRIGGER gw_trg_edit_ve_epa_frshortpipe INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_frshortpipe
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frshortpipe');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_frvalve
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-VALVE');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_frpump
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-PUMP');

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_inp_dscenario_frshortpipe
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-SHORTPIPE');

CREATE TRIGGER gw_trg_edit_ve_epa_valve INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_valve
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('valve');

CREATE TRIGGER gw_trg_edit_ve_epa_pipe INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_pipe 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('pipe');

CREATE TRIGGER gw_trg_edit_ve_epa_shortpipe INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_shortpipe 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('shortpipe');

CREATE TRIGGER gw_trg_edit_ve_epa_virtualvalve INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_virtualvalve 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('virtualvalve');

CREATE TRIGGER gw_trg_edit_ve_epa_virtualpump INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_virtualpump 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('virtualpump');

CREATE TRIGGER gw_trg_edit_ve_epa_pump INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_pump 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('pump');

CREATE TRIGGER gw_trg_edit_ve_epa_pump_additional INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_pump_additional 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('pump_additional');

CREATE TRIGGER gw_trg_edit_ve_epa_junction INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_junction 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('junction');

CREATE TRIGGER gw_trg_edit_ve_epa_tank INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_tank 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('tank');

CREATE TRIGGER gw_trg_edit_ve_epa_reservoir INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_reservoir 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('reservoir');

CREATE TRIGGER gw_trg_edit_ve_epa_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_connec 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('connec');

CREATE TRIGGER gw_trg_edit_ve_epa_inlet INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_inlet 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('inlet');

CREATE TRIGGER gw_trg_edit_plan_psector_connec INSTEAD OF INSERT OR DELETE OR UPDATE
ON ve_plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plan_psector_x_connect('plan_psector_x_connec');


DROP TRIGGER IF EXISTS gw_trg_edit_element_epump ON ve_element_epump;
DROP TRIGGER IF EXISTS gw_trg_edit_element_evalve ON ve_element_evalve;

CREATE TRIGGER gw_trg_edit_element_epump INSTEAD OF INSERT OR DELETE OR UPDATE 
ON ve_element_epump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_element('EPUMP');

CREATE TRIGGER gw_trg_edit_element_evalve INSTEAD OF INSERT OR DELETE OR UPDATE 
ON ve_element_evalve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_element('EVALVE');

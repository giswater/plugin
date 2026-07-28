/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;


INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES
('scada_graph', 'scada_graph', 'tab_none', 'object_1', 'lyt_scada_node_1', 0, 'integer', 'text', 'Node 1:', 'object_1', NULL, true, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('scada_graph', 'scada_graph', 'tab_none', 'btn_pick_object_1', 'lyt_scada_node_1', 1, NULL, 'button', NULL, 'Pick node 1', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon": "137"}'::json, NULL, '{"functionName": "pick_node", "module": "scada_graph", "parameters": {"target": "object_1"}}'::json, NULL, false, 0),
('scada_graph', 'scada_graph', 'tab_none', 'object_2', 'lyt_scada_node_2', 0, 'integer', 'text', 'Node 2:', 'object_2', NULL, true, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 0),
('scada_graph', 'scada_graph', 'tab_none', 'btn_pick_object_2', 'lyt_scada_node_2', 1, NULL, 'button', NULL, 'Pick node 2', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, '{"icon": "137"}'::json, NULL, '{"functionName": "pick_node", "module": "scada_graph", "parameters": {"target": "object_2"}}'::json, NULL, false, 0),
('scada_graph', 'scada_graph', 'tab_none', 'btn_accept', 'lyt_buttons', 1, NULL, 'button', NULL, 'Accept', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Accept"}'::json, '{"functionName": "accept", "module": "scada_graph"}'::json, NULL, false, 0),
('scada_graph', 'scada_graph', 'tab_none', 'btn_close', 'lyt_buttons', 2, NULL, 'button', NULL, 'Close', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"text": "Close"}'::json, '{"functionName": "close", "module": "scada_graph"}'::json, NULL, false, 0);


CREATE OR REPLACE VIEW vf_link AS
SELECT l.link_id, COALESCE(pp.state, l.state) AS p_state
FROM link l
LEFT JOIN LATERAL (
	SELECT x.connec_id, x.psector_id
	FROM (SELECT 1 WHERE EXISTS (
			SELECT 1 FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
		)) gate
	CROSS JOIN LATERAL (
		SELECT pp1.connec_id, pp1.psector_id
		FROM plan_psector_x_connec pp1
		WHERE pp1.connec_id = l.feature_id
			AND pp1.psector_id IN (
				SELECT sp.psector_id FROM selector_psector sp WHERE sp.cur_user = CURRENT_USER
			)
		ORDER BY pp1.psector_id DESC
		LIMIT 1
	) x
) last_ps ON true
LEFT JOIN LATERAL (
	SELECT x.state
	FROM (SELECT 1 WHERE last_ps.psector_id IS NOT NULL) gate
	CROSS JOIN LATERAL (
		SELECT pp2.state
		FROM plan_psector_x_connec pp2
		WHERE pp2.link_id = l.link_id AND pp2.psector_id = last_ps.psector_id
		LIMIT 1
	) x
) pp ON true
WHERE EXISTS (
		SELECT 1 FROM selector_state ss
		WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, l.state)
	)
	AND l.sector_id IN (SELECT ssec.sector_id FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER)
	AND l.muni_id IN (SELECT sm.muni_id FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER)
	AND EXISTS (
		SELECT 1 FROM selector_expl se
		WHERE se.cur_user = CURRENT_USER
			AND (se.expl_id = l.expl_id OR se.expl_id = ANY (l.expl_visibility))
	);

INSERT INTO sys_param_user (id, formname, descript, sys_role, label, isenabled, layoutorder, project_type, isparent, "datatype", widgettype, ismandatory, vdefault, layoutname, iseditable, "source")
VALUES ('inp_report_onlymaxmin_values', 'epaoptions', 'If true, only max/min values will be stored after a Go2Epa process executed with hydraulic engine', 'role_epa', 'Report only max/min values', true, 13, 'ws', false, 'boolean', 'check', true, 'false', 'lyt_general_1', true, 'core');

-- Drop view triggers
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_pump ON ve_epa_pump;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_pump_additional ON ve_epa_pump_additional;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_valve ON ve_epa_valve;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_shortpipe ON ve_epa_shortpipe;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_pipe ON ve_epa_pipe;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_virtualvalve ON ve_epa_virtualvalve;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_virtualpump ON ve_epa_virtualpump;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_frpump ON ve_epa_frpump;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_frvalve ON ve_epa_frvalve;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_frshortpipe ON ve_epa_frshortpipe;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_link ON ve_epa_link;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_junction ON ve_epa_junction;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_tank ON ve_epa_tank;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_reservoir ON ve_epa_reservoir;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_connec ON ve_epa_connec;
DROP TRIGGER IF EXISTS gw_trg_edit_ve_epa_inlet ON ve_epa_inlet;

-- Drop dependent views (children first)
DROP VIEW IF EXISTS ve_epa_pump;
DROP VIEW IF EXISTS ve_epa_pump_additional;
DROP VIEW IF EXISTS ve_epa_valve;
DROP VIEW IF EXISTS ve_epa_shortpipe;
DROP VIEW IF EXISTS ve_epa_pipe;
DROP VIEW IF EXISTS ve_epa_virtualvalve;
DROP VIEW IF EXISTS ve_epa_virtualpump;
DROP VIEW IF EXISTS ve_epa_frpump;
DROP VIEW IF EXISTS ve_epa_frvalve;
DROP VIEW IF EXISTS ve_epa_frshortpipe;
DROP VIEW IF EXISTS ve_epa_link;
DROP VIEW IF EXISTS ve_epa_junction;
DROP VIEW IF EXISTS ve_epa_tank;
DROP VIEW IF EXISTS ve_epa_reservoir;
DROP VIEW IF EXISTS ve_epa_connec;
DROP VIEW IF EXISTS ve_epa_inlet;
DROP VIEW IF EXISTS v_rpt_comp_arc_stats;
DROP VIEW IF EXISTS v_rpt_comp_node_stats;
DROP VIEW IF EXISTS v_rpt_arc_stats;
DROP VIEW IF EXISTS v_rpt_node_stats;
DROP VIEW IF EXISTS v_rpt_comp_arc;
DROP VIEW IF EXISTS v_rpt_comp_node;

DROP VIEW IF EXISTS v_rpt_compare_arc;

-- Drop indexes
DROP INDEX IF EXISTS rpt_arc_stats_flow_avg;
DROP INDEX IF EXISTS rpt_arc_stats_flow_max;
DROP INDEX IF EXISTS rpt_arc_stats_flow_min;
DROP INDEX IF EXISTS rpt_arc_stats_geom;
DROP INDEX IF EXISTS rpt_arc_stats_vel_avg;
DROP INDEX IF EXISTS rpt_arc_stats_vel_max;
DROP INDEX IF EXISTS rpt_arc_stats_vel_min;
DROP INDEX IF EXISTS rpt_node_stats_demand_avg;
DROP INDEX IF EXISTS rpt_node_stats_demand_max;
DROP INDEX IF EXISTS rpt_node_stats_demand_min;
DROP INDEX IF EXISTS rpt_node_stats_geom;
DROP INDEX IF EXISTS rpt_node_stats_head_avg;
DROP INDEX IF EXISTS rpt_node_stats_head_max;
DROP INDEX IF EXISTS rpt_node_stats_head_min;
DROP INDEX IF EXISTS rpt_node_stats_press_avg;
DROP INDEX IF EXISTS rpt_node_stats_press_max;
DROP INDEX IF EXISTS rpt_node_stats_press_min;
DROP INDEX IF EXISTS rpt_node_stats_quality_avg;
DROP INDEX IF EXISTS rpt_node_stats_quality_max;
DROP INDEX IF EXISTS rpt_node_stats_quality_min;

-- Create temporal tables to store current values

CREATE TABLE rpt_arc_stats_current (
	arc_id varchar(16) NOT NULL,
	result_id varchar(30) NOT NULL,
	arc_type varchar(30) NULL,
	sector_id int4 NULL,
	arccat_id varchar(30) NULL,
	flow_max numeric NULL,
	flow_min numeric NULL,
	flow_avg numeric(12, 2) NULL,
	vel_max numeric NULL,
	vel_min numeric NULL,
	vel_avg numeric(12, 2) NULL,
	headloss_max numeric NULL,
	headloss_min numeric NULL,
	setting_max numeric NULL,
	setting_min numeric NULL,
	reaction_max numeric NULL,
	reaction_min numeric NULL,
	ffactor_max numeric NULL,
	ffactor_min numeric NULL,
	length numeric NULL,
	tot_headloss_max numeric(12, 2) NULL,
	tot_headloss_min numeric(12, 2) NULL,
	the_geom public.geometry(linestring, SRID_VALUE) NULL,
	CONSTRAINT rpt_arc_stats_current_pkey PRIMARY KEY (arc_id, result_id),
	CONSTRAINT rpt_arc_stats_current_result_id_fkey FOREIGN KEY (result_id) REFERENCES rpt_cat_result(result_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE rpt_node_stats_current (
	node_id varchar(16) NOT NULL,
	result_id varchar(30) NOT NULL,
	node_type varchar(30) NULL,
	sector_id int4 NULL,
	nodecat_id varchar(30) NULL,
	top_elev numeric NULL,
	demand_max numeric NULL,
	demand_min numeric NULL,
	demand_avg numeric(12, 2) NULL,
	head_max numeric NULL,
	head_min numeric NULL,
	head_avg numeric(12, 2) NULL,
	press_max numeric NULL,
	press_min numeric NULL,
	press_avg numeric(12, 2) NULL,
	quality_max numeric NULL,
	quality_min numeric NULL,
	quality_avg numeric(12, 2) NULL,
	the_geom public.geometry(point, SRID_VALUE) NULL,
	CONSTRAINT rpt_node_stats_current_pkey PRIMARY KEY (node_id, result_id),
	CONSTRAINT rpt_node_stats_current_result_id_fkey FOREIGN KEY (result_id) REFERENCES rpt_cat_result(result_id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO rpt_arc_stats_current SELECT * FROM rpt_arc_stats;
INSERT INTO rpt_node_stats_current SELECT * FROM rpt_node_stats;

DROP TABLE IF EXISTS rpt_arc_stats;
DROP TABLE IF EXISTS rpt_node_stats;

CREATE TABLE rpt_arc_stats (
	arc_id varchar(16) NOT NULL,
	result_id varchar(30) NOT NULL,
	arc_type varchar(30) NULL,
	sector_id int4 NULL,
	arccat_id varchar(30) NULL,
	flow_max numeric NULL,
	t_flow_max varchar(100) NULL,
	flow_min numeric NULL,
	t_flow_min varchar(100) NULL,
	flow_avg numeric(12, 2) NULL,
	vel_max numeric NULL,
	t_vel_max varchar(100) NULL,
	vel_min numeric NULL,
	t_vel_min varchar(100) NULL,
	vel_avg numeric(12, 2) NULL,
	headloss_max numeric NULL,
	t_headloss_max varchar(100) NULL,
	headloss_min numeric NULL,
	t_headloss_min varchar(100) NULL,
	setting_max numeric NULL,
	t_setting_max varchar(100) NULL,
	setting_min numeric NULL,
	t_setting_min varchar(100) NULL,
	reaction_max numeric NULL,
	t_reaction_max varchar(100) NULL,
	reaction_min numeric NULL,
	t_reaction_min varchar(100) NULL,
	ffactor_max numeric NULL,
	t_ffactor_max varchar(100) NULL,
	ffactor_min numeric NULL,
	t_ffactor_min varchar(100) NULL,
	length numeric NULL,
	tot_headloss_max numeric(12, 2) NULL,
	tot_headloss_min numeric(12, 2) NULL,
	the_geom public.geometry(linestring, SRID_VALUE) NULL,
	CONSTRAINT rpt_arc_stats_pkey PRIMARY KEY (arc_id, result_id),
	CONSTRAINT rpt_arc_stats_result_id_fkey FOREIGN KEY (result_id) REFERENCES rpt_cat_result(result_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX rpt_arc_stats_flow_avg ON rpt_arc_stats USING btree (flow_avg);
CREATE INDEX rpt_arc_stats_flow_max ON rpt_arc_stats USING btree (flow_max);
CREATE INDEX rpt_arc_stats_flow_min ON rpt_arc_stats USING btree (flow_min);
CREATE INDEX rpt_arc_stats_geom ON rpt_arc_stats USING gist (the_geom);
CREATE INDEX rpt_arc_stats_vel_avg ON rpt_arc_stats USING btree (vel_avg);
CREATE INDEX rpt_arc_stats_vel_max ON rpt_arc_stats USING btree (vel_max);
CREATE INDEX rpt_arc_stats_vel_min ON rpt_arc_stats USING btree (vel_min);

CREATE TABLE rpt_node_stats (
	node_id varchar(16) NOT NULL,
	result_id varchar(30) NOT NULL,
	node_type varchar(30) NULL,
	sector_id int4 NULL,
	nodecat_id varchar(30) NULL,
	top_elev numeric NULL,
	demand_max numeric NULL,
	t_demand_max varchar(100) NULL,
	demand_min numeric NULL,
	t_demand_min varchar(100) NULL,
	demand_avg numeric(12, 2) NULL,
	head_max numeric NULL,
	t_head_max varchar(100) NULL,
	head_min numeric NULL,
	t_head_min varchar(100) NULL,
	head_avg numeric(12, 2) NULL,
	press_max numeric NULL,
	t_press_max varchar(100) NULL,
	press_min numeric NULL,
	t_press_min varchar(100) NULL,
	press_avg numeric(12, 2) NULL,
	quality_max numeric NULL,
	t_quality_max varchar(100) NULL,
	quality_min numeric NULL,
	t_quality_min varchar(100) NULL,
	quality_avg numeric(12, 2) NULL,
	the_geom public.geometry(point, SRID_VALUE) NULL,
	CONSTRAINT rpt_node_stats_pkey PRIMARY KEY (node_id, result_id),
	CONSTRAINT rpt_node_stats_result_id_fkey FOREIGN KEY (result_id) REFERENCES rpt_cat_result(result_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX rpt_node_stats_demand_avg ON rpt_node_stats USING btree (demand_avg);
CREATE INDEX rpt_node_stats_demand_max ON rpt_node_stats USING btree (demand_max);
CREATE INDEX rpt_node_stats_demand_min ON rpt_node_stats USING btree (demand_min);
CREATE INDEX rpt_node_stats_geom ON rpt_node_stats USING gist (the_geom);
CREATE INDEX rpt_node_stats_head_avg ON rpt_node_stats USING btree (head_avg);
CREATE INDEX rpt_node_stats_head_max ON rpt_node_stats USING btree (head_max);
CREATE INDEX rpt_node_stats_head_min ON rpt_node_stats USING btree (head_min);
CREATE INDEX rpt_node_stats_press_avg ON rpt_node_stats USING btree (press_avg);
CREATE INDEX rpt_node_stats_press_max ON rpt_node_stats USING btree (press_max);
CREATE INDEX rpt_node_stats_press_min ON rpt_node_stats USING btree (press_min);
CREATE INDEX rpt_node_stats_quality_avg ON rpt_node_stats USING btree (quality_avg);
CREATE INDEX rpt_node_stats_quality_max ON rpt_node_stats USING btree (quality_max);
CREATE INDEX rpt_node_stats_quality_min ON rpt_node_stats USING btree (quality_min);

INSERT INTO rpt_arc_stats (
	arc_id, result_id, arc_type, sector_id, arccat_id, flow_max, flow_min, flow_avg,
	vel_max, vel_min, vel_avg, headloss_max, headloss_min, setting_max, setting_min,
	reaction_max, reaction_min, ffactor_max, ffactor_min, length, tot_headloss_max,
	tot_headloss_min, the_geom
)
SELECT
	arc_id, result_id, arc_type, sector_id, arccat_id, flow_max, flow_min, flow_avg,
	vel_max, vel_min, vel_avg, headloss_max, headloss_min, setting_max, setting_min,
	reaction_max, reaction_min, ffactor_max, ffactor_min, length, tot_headloss_max,
	tot_headloss_min, the_geom
FROM rpt_arc_stats_current;

INSERT INTO rpt_node_stats (
	node_id, result_id, node_type, sector_id, nodecat_id, top_elev, demand_max,
	demand_min, demand_avg, head_max, head_min, head_avg, press_max, press_min,
	press_avg, quality_max, quality_min, quality_avg, the_geom
)
SELECT
	node_id, result_id, node_type, sector_id, nodecat_id, top_elev, demand_max,
	demand_min, demand_avg, head_max, head_min, head_avg, press_max, press_min,
	press_avg, quality_max, quality_min, quality_avg, the_geom
FROM rpt_node_stats_current;

-- Recreate stats views

CREATE OR REPLACE VIEW v_rpt_arc_stats
AS SELECT r.arc_id,
    r.result_id,
    rpt_cat_result.flow_units,
    rpt_cat_result.quality_units,
    r.arc_type,
    r.sector_id,
    r.arccat_id,
    r.flow_max,
    r.t_flow_max,
    r.flow_min,
    r.t_flow_min,
    r.flow_avg,
    r.vel_max,
    r.t_vel_max,
    r.vel_min,
    r.t_vel_min,
    r.vel_avg,
    r.headloss_max,
    r.t_headloss_max,
    r.headloss_min,
    r.t_headloss_min,
    r.setting_max,
    r.t_setting_max,
    r.setting_min,
    r.t_setting_min,
    r.reaction_max,
    r.t_reaction_max,
    r.reaction_min,
    r.t_reaction_min,
    r.ffactor_max,
    r.t_ffactor_max,
    r.ffactor_min,
    r.t_ffactor_min,
    r.length,
    r.tot_headloss_max,
    r.tot_headloss_min,
    arc.diameter,
    r.the_geom
   FROM rpt_arc_stats r
     JOIN selector_rpt_main s ON s.result_id::text = r.result_id::text
     JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text AND arc.arc_id::text = r.arc_id::text
     JOIN rpt_cat_result ON rpt_cat_result.result_id::text = s.result_id::text
  WHERE s.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW v_rpt_node_stats
AS SELECT r.node_id,
    r.result_id,
    rpt_cat_result.flow_units,
    r.node_type,
    r.sector_id,
    r.nodecat_id,
    r.top_elev,
    r.demand_max,
    r.t_demand_max,
    r.demand_min,
    r.t_demand_min,
    r.demand_avg,
    r.head_max,
    r.t_head_max,
    r.head_min,
    r.t_head_min,
    r.head_avg,
    r.press_max,
    r.t_press_max,
    r.press_min,
    r.t_press_min,
    r.press_avg,
    rpt_cat_result.quality_units,
    r.quality_max,
    r.t_quality_max,
    r.quality_min,
    r.t_quality_min,
    r.quality_avg,
    r.the_geom
   FROM rpt_node_stats r
     JOIN selector_rpt_main s ON s.result_id::text = r.result_id::text
     JOIN rpt_cat_result ON rpt_cat_result.result_id::text = s.result_id::text
  WHERE s.cur_user = CURRENT_USER;

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
             LEFT JOIN rpt_inp_arc arc ON arc.arc_id::text = r.arc_id::text AND arc.result_id::text = s.result_id::text
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
             LEFT JOIN rpt_inp_arc arc ON arc.arc_id::text = r.arc_id::text AND arc.result_id::text = s.result_id::text
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

CREATE OR REPLACE VIEW v_rpt_comp_node
AS WITH main AS (
         SELECT r.node_id,
            r.result_id,
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
            r.quality_max,
            r.quality_min,
            r.quality_avg,
            r.the_geom
           FROM rpt_node_stats r,
            selector_rpt_main s
          WHERE r.result_id::text = s.result_id::text AND s.cur_user = CURRENT_USER
        ), compare AS (
         SELECT r.node_id,
            r.result_id,
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
            r.quality_max,
            r.quality_min,
            r.quality_avg,
            r.the_geom
           FROM rpt_node_stats r,
            selector_rpt_compare s
          WHERE r.result_id::text = s.result_id::text AND s.cur_user = CURRENT_USER
        )
 SELECT main.node_id,
    main.node_type,
    main.sector_id,
    main.nodecat_id,
    main.result_id AS result_id_main,
    compare.result_id AS result_id_compare,
    main.top_elev,
    main.demand_max AS demand_max_main,
    compare.demand_max AS demand_max_compare,
    main.demand_max - compare.demand_max AS demand_max_diff,
    main.demand_min AS demand_min_main,
    compare.demand_min AS demand_min_compare,
    main.demand_min - compare.demand_min AS demand_min_diff,
    main.demand_avg AS demand_avg_main,
    compare.demand_avg AS demand_avg_compare,
    main.demand_avg - compare.demand_avg AS demand_avg_diff,
    main.head_max AS head_max_main,
    compare.head_max AS head_max_compare,
    main.head_max - compare.head_max AS head_max_diff,
    main.head_min AS head_min_main,
    compare.head_min AS head_min_compare,
    main.head_min - compare.head_min AS head_min_diff,
    main.head_avg AS head_avg_main,
    compare.head_avg AS head_avg_compare,
    main.head_avg - compare.head_avg AS head_avg_diff,
    main.press_max AS press_max_main,
    compare.press_max AS press_max_compare,
    main.press_max - compare.press_max AS press_max_diff,
    main.press_min AS press_min_main,
    compare.press_min AS press_min_compare,
    main.press_min - compare.press_min AS press_min_diff,
    main.press_avg AS press_avg_main,
    compare.press_avg AS press_avg_compare,
    main.press_avg - compare.press_avg AS press_avg_diff,
    main.quality_max AS quality_max_main,
    compare.quality_max AS quality_max_compare,
    main.quality_max - compare.quality_max AS quality_max_diff,
    main.quality_min AS quality_min_main,
    compare.quality_min AS quality_min_compare,
    main.quality_min - compare.quality_min AS quality_min_diff,
    main.quality_avg AS quality_avg_main,
    compare.quality_avg AS quality_avg_compare,
    main.quality_avg - compare.quality_avg AS quality_avg_diff,
    main.the_geom
   FROM main
     JOIN compare ON main.node_id::text = compare.node_id::text;

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
             JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text AND arc.arc_id::text = r.arc_id::text
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
             JOIN rpt_inp_arc arc ON arc.result_id::text = s.result_id::text AND arc.arc_id::text = r.arc_id::text
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

CREATE OR REPLACE VIEW v_rpt_comp_node_stats
AS SELECT r.node_id,
    r.result_id,
    r.node_type,
    r.sector_id,
    r.nodecat_id,
    r.top_elev AS elevation,
    r.demand_max,
    r.demand_min,
    r.demand_avg,
    r.head_max,
    r.head_min,
    r.head_avg,
    r.press_max,
    r.press_min,
    r.press_avg,
    r.quality_max,
    r.quality_min,
    r.quality_avg,
    r.the_geom
   FROM rpt_node_stats r,
    selector_rpt_compare s
     JOIN selector_rpt_compare USING (result_id);

-- Recreate ve_epa views

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
   FROM inp_connec
     LEFT JOIN v_rpt_node_stats n1 ON inp_connec.connec_id::text = n1.node_id::text
     LEFT JOIN link ON link.feature_id = inp_connec.connec_id
     LEFT JOIN v_rpt_node_stats n2 ON n2.node_id::text = concat('VN', link.link_id);

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
    v_rpt_arc_stats.arc_id AS nodarc_id
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
    v_rpt_arc_stats.ffactor_min,
    v_rpt_arc_stats.arc_id AS nodarc_id
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
    v_rpt_arc_stats.arc_id AS nodarc_id
   FROM node
     JOIN inp_valve USING (node_id)
     LEFT JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
     LEFT JOIN v_rpt_arc_stats ON concat(inp_valve.node_id, '_n2a') = v_rpt_arc_stats.arc_id::text
     LEFT JOIN man_valve v ON v.node_id = inp_valve.node_id;

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
    v_rpt_arc_stats.arc_id AS nodarc_id
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

CREATE OR REPLACE VIEW ve_epa_frvalve
AS SELECT v.element_id,
    man_frelem.node_id,
    man_frelem.to_arc,
    v.valve_type,
    v.custom_dint,
    v.setting,
    v.curve_id,
    v.minorloss,
    v.add_settings,
    v.init_quality,
    v.status,
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
     LEFT JOIN cat_link ON cat_link.id::text = link.linkcat_id::text
     LEFT JOIN cat_mat_roughness r ON cat_link.matcat_id::text = r.matcat_id::text;

CREATE OR REPLACE VIEW v_rpt_compare_arc
AS SELECT r.arc_id,
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
    r.the_geom
   FROM rpt_arc_stats r,
    selector_rpt_compare s
  WHERE r.result_id::text = s.result_id::text AND s.cur_user = "current_user"()::text;

-- View triggers

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

CREATE TRIGGER gw_trg_edit_ve_epa_pump INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_pump
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('pump');

CREATE TRIGGER gw_trg_edit_ve_epa_pump_additional INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_pump_additional
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('pump_additional');

CREATE TRIGGER gw_trg_edit_ve_epa_valve INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_valve
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('valve');

CREATE TRIGGER gw_trg_edit_ve_epa_shortpipe INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_shortpipe
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('shortpipe');

CREATE TRIGGER gw_trg_edit_ve_epa_pipe INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_pipe
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('pipe');

CREATE TRIGGER gw_trg_edit_ve_epa_virtualvalve INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_virtualvalve
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('virtualvalve');

CREATE TRIGGER gw_trg_edit_ve_epa_virtualpump INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_virtualpump
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('virtualpump');

CREATE TRIGGER gw_trg_edit_ve_epa_frshortpipe INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_frshortpipe
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frshortpipe');

CREATE TRIGGER gw_trg_edit_ve_epa_frpump INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_frpump
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frpump');

CREATE TRIGGER gw_trg_edit_ve_epa_frvalve INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_frvalve
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('frvalve');

CREATE TRIGGER gw_trg_edit_ve_epa_link INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_epa_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_ve_epa('link');

DROP TABLE IF EXISTS rpt_arc_stats_current;
DROP TABLE IF EXISTS rpt_node_stats_current;

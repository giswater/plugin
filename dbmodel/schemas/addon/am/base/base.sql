/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
SET search_path = am, public;

--
-- TABLES:
--

CREATE TABLE sys_version (
	id serial4 NOT NULL,
	giswater varchar(16) NOT NULL,
	project_type varchar(16) NOT NULL,
	postgres varchar(512) NOT NULL,
	postgis varchar(512) NOT NULL,
	"date" timestamp(6) DEFAULT now() NOT NULL,
	"language" varchar(50) NOT NULL,
	epsg int4 NOT NULL,
	addparam jsonb NULL,
	CONSTRAINT sys_version_pkey PRIMARY KEY (id)
);

CREATE TABLE leaks (
    id serial,
    material character varying(100),
    diameter integer,
    "date" date,
    the_geom public.geometry(MultiPoint,SCHEMA_SRID),
    CONSTRAINT leaks_pkey PRIMARY KEY (id)
);

CREATE TABLE dma_nrw (
    dma_id integer,
    nrw numeric(12,3),
    "days" integer,
    CONSTRAINT dma_nrw_pkey PRIMARY KEY (dma_id)
);

CREATE TABLE arc_input (
    arc_id int4 NOT NULL,
    longevity numeric(12,3),
    rleak numeric(12,3),
    flow numeric(12,3),
    nrw numeric(12,3),
    strategic boolean,
    mandatory boolean,
    compliance integer,
    mincut_customers integer,
    mincut_criticity numeric(4,2),
    data_quality integer,
    data_quality_obs varchar[],
    CONSTRAINT arc_input_pkey PRIMARY KEY (arc_id)
);

CREATE TABLE cat_result (
    result_id serial,
    result_name text UNIQUE,
    result_type character varying(50),
    descript text,
    report text,
    expl_id integer,
    budget numeric(12,2),
    target_year smallint,
    tstamp timestamp without time zone,
    cur_user text,
    status character varying(50),
    presszone_id character varying(30),
    material_id character varying(30),
    features character varying[],
    dnom numeric(12,3),
    nodecat_id character varying(30),
    node_type text,
    iscorporate boolean,
    asset_type varchar(10) DEFAULT 'ARC',
    linked_arc_result_id integer,
    CONSTRAINT cat_result_pkey PRIMARY KEY (result_id),
    CONSTRAINT cat_result_result_type_check CHECK (result_type = ANY (ARRAY['GLOBAL', 'SELECTION'])),
    CONSTRAINT cat_result_status_check CHECK (status = ANY (ARRAY['CANCELED', 'ON PLANNING', 'FINISHED'])),
    CONSTRAINT cat_result_linked_arc_result_id_fkey
        FOREIGN KEY (linked_arc_result_id) REFERENCES cat_result (result_id) ON DELETE SET NULL
);

CREATE TABLE value_result_type (
    id character varying(50) PRIMARY KEY,
    idval character varying(50)
);

CREATE TABLE value_status (
    id character varying(50) PRIMARY KEY,
    idval character varying(50)
);

CREATE TABLE config_catalog_def (
    id serial PRIMARY KEY,
    arccat_id varchar(30),
    dnom numeric(12,2),
    cost_constr numeric(12,2),
    cost_repmain numeric(12,2),
    compliance integer,
    CONSTRAINT config_catalog_def_arccat_id_or_dnom
        CHECK (arccat_id IS NOT NULL OR dnom IS NOT NULL)
);

CREATE TABLE config_catalog (
    arccat_id varchar(30),
    dnom numeric(12,2),
    cost_constr numeric(12,2),
    cost_repmain numeric(12,2),
    compliance integer,
    result_id integer NOT NULL,
    CONSTRAINT config_catalog_arccat_id_or_dnom
        CHECK (arccat_id IS NOT NULL OR dnom IS NOT NULL)
);

CREATE TABLE config_nodecatalog_def (
    id serial PRIMARY KEY,
    nodecat_id varchar(30) NOT NULL,
    dnom numeric(12,2),
    cost_constr numeric(12,2),
    cost_repmain numeric(12,2),
    compliance integer,
    CONSTRAINT config_nodecatalog_def_nodecat_id UNIQUE (nodecat_id)
);

CREATE TABLE config_nodecatalog (
    nodecat_id varchar(30) NOT NULL,
    dnom numeric(12,2),
    cost_constr numeric(12,2),
    cost_repmain numeric(12,2),
    compliance integer,
    result_id integer NOT NULL,
    CONSTRAINT config_nodecatalog_pkey PRIMARY KEY (nodecat_id, result_id)
);

CREATE TABLE config_material_def (
    material character varying(50) NOT NULL,
    pleak numeric(12,2),
    age_max smallint,
    age_med smallint,
    age_min smallint,
    builtdate_vdef smallint,
    compliance integer,
    CONSTRAINT config_material_def_pkey PRIMARY KEY (material)
);

CREATE TABLE config_material (
    material character varying(50) NOT NULL,
    pleak numeric(12,2),
    age_max smallint,
    age_med smallint,
    age_min smallint,
    builtdate_vdef smallint,
    compliance integer,
    result_id integer NOT NULL,
    CONSTRAINT config_material_pkey PRIMARY KEY (material, result_id)
);

CREATE TABLE config_engine_def (
    parameter character varying(50) NOT NULL,
    value text,
    method character varying(30),
    round smallint,
    descript text,
    active boolean,
    layoutname character varying(50),
    layoutorder integer,
    label character varying(200),
    datatype character varying(50),
    widgettype character varying(50),
    dv_querytext text,
    dv_controls json,
    ismandatory boolean,
    iseditable boolean,
    stylesheet json,
    widgetcontrols json,
    placeholder text,
    standardvalue text,
    asset_type varchar(10) NOT NULL DEFAULT 'ARC',
    CONSTRAINT config_engine_def_pkey PRIMARY KEY (parameter, method, asset_type),
    CONSTRAINT config_engine_def_asset_type_check CHECK (asset_type = ANY (ARRAY['ARC', 'NODE']))
);

CREATE TABLE config_engine (
    parameter character varying(50) NOT NULL,
    value text,
    method character varying(30),
    round smallint,
    descript text,
    active boolean,
    layoutname character varying(50),
    layoutorder integer,
    label character varying(200),
    datatype character varying(50),
    widgettype character varying(50),
    dv_querytext text,
    dv_controls json,
    ismandatory boolean,
    iseditable boolean,
    stylesheet json,
    widgetcontrols json,
    placeholder text,
    standardvalue text,
    result_id integer NOT NULL,
    asset_type varchar(10) NOT NULL DEFAULT 'ARC',
    CONSTRAINT config_engine_pkey PRIMARY KEY (parameter, result_id),
    CONSTRAINT config_engine_asset_type_check CHECK (asset_type = ANY (ARRAY['ARC', 'NODE']))
);

CREATE TABLE arc_engine_sh (
    arc_id int4 NOT NULL,
    result_id integer NOT NULL,
    cost_repmain numeric(12,2),
    cost_constr numeric(12,2),
    bratemain numeric(12,3),
    brateserv numeric(12,3),
    year integer,
    year_order double precision,
    strategic integer,
    compliance integer,
    val double precision,
    CONSTRAINT arc_engine_sh_pkey PRIMARY KEY (arc_id, result_id)
);

CREATE TABLE arc_engine_wm (
    arc_id int4 NOT NULL,
    result_id integer NOT NULL,
    rleak integer,
    longevity integer,
    pressure integer,
    flow integer,
    nrw integer,
    strategic integer,
    compliance integer,
    mincut_customers integer,
    mincut_criticity numeric(4,2),
    val_first double precision,
    val double precision,
    CONSTRAINT arc_engine_wm_pkey PRIMARY KEY (arc_id, result_id)
);

CREATE TABLE arc_output (
    arc_id int4 NOT NULL,
    result_id integer NOT NULL,
    sector_id integer,
    macrosector_id integer,
    presszone_id character varying(30),
    builtdate date,
    arccat_id character varying(30),
    dnom character varying(16),
    matcat_id character varying(30),
    pavcat_id character varying(30),
    function_type character varying(50),
    the_geom  public.geometry(multilinestring,SCHEMA_SRID),
    code character varying(50),
    expl_id integer,
    dma_id integer,
    press1 numeric(12,2),
    press2 numeric(12,2),
    flow_avg numeric(12,2),
    longevity numeric(12,3),
    rleak numeric(12,3),
    nrw numeric(12,3),
    strategic boolean,
    mandatory boolean,
    compliance integer,
    mincut_customers integer,
    mincut_criticity numeric(4,2),
    val double precision,
    orderby integer,
    expected_year integer,
    replacement_year integer,
    budget numeric(12,2),
    total numeric(12,2),
    length numeric(12,3),
    cum_length numeric(12,3),
    CONSTRAINT arc_output_pkey PRIMARY KEY (arc_id, result_id)
);

-- Stage 2: NODE Weighted Method tables

CREATE TABLE node_input (
    node_id int4 NOT NULL,
    age numeric(12,3),
    incident_count numeric(12,3),
    structural_raw numeric(12,3),
    operational_raw numeric(12,3),
    nrw_raw numeric(12,3),
    affected_users_raw numeric(12,3),
    strategic boolean,
    compliance boolean,
    mandatory boolean DEFAULT false,
    data_quality integer,
    data_quality_obs varchar[],
    estimated_cost numeric(12,2),
    CONSTRAINT node_input_pkey PRIMARY KEY (node_id)
);

CREATE TABLE node_engine_wm (
    node_id int4 NOT NULL,
    result_id integer NOT NULL,
    longevity numeric(5,2),
    incident_history numeric(5,2),
    structural_condition numeric(5,2),
    operational_condition numeric(5,2),
    nrw numeric(5,2),
    affected_users numeric(5,2),
    strategic numeric(5,2),
    compliance numeric(5,2),
    val_first double precision,
    val double precision,
    orderby integer,
    CONSTRAINT node_engine_wm_pkey PRIMARY KEY (node_id, result_id)
);

CREATE TABLE node_output (
    node_id int4 NOT NULL,
    result_id integer NOT NULL,
    sector_id integer,
    macrosector_id integer,
    presszone_id character varying(30),
    builtdate date,
    nodecat_id character varying(30),
    node_type character varying(30),
    the_geom public.geometry(point,SCHEMA_SRID),
    code character varying(50),
    expl_id integer,
    dma_id integer,
    longevity numeric(12,3),
    incident_history numeric(12,3),
    structural_condition numeric(12,3),
    operational_condition numeric(12,3),
    nrw numeric(12,3),
    affected_users numeric(12,3),
    strategic boolean,
    mandatory boolean,
    compliance boolean,
    val double precision,
    orderby integer,
    selected boolean DEFAULT false,
    expected_year integer,
    replacement_year integer,
    budget numeric(12,2),
    total numeric(12,2),
    estimated_cost numeric(12,2),
    comments text,
    data_quality_class varchar(20),
    CONSTRAINT node_output_pkey PRIMARY KEY (node_id, result_id)
);

CREATE TABLE selector_result_main (
    result_id integer NOT NULL,
    cur_user text DEFAULT "current_user"() NOT NULL,
    CONSTRAINT selector_result_main_pkey PRIMARY KEY (cur_user, result_id)
);

CREATE TABLE selector_result_compare (
    result_id integer NOT NULL,
    cur_user text DEFAULT "current_user"() NOT NULL,
    CONSTRAINT selector_result_compare_pkey PRIMARY KEY (cur_user, result_id)
);

CREATE TABLE config_form_tableview (
    location_type character varying(50) NOT NULL,
    project_type character varying(50) NOT NULL,
    objectname character varying(50) NOT NULL,
    columnname character varying(50) NOT NULL,
    columnindex smallint,
    visible boolean,
    width integer,
    alias character varying(50),
    style json,
    CONSTRAINT config_form_tableview_pkey PRIMARY KEY (objectname, columnname)
);

--
-- VIEWS:
--

CREATE VIEW v_asset_arc_output AS
 SELECT arc_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    arccat_id,
    dnom,
    matcat_id,
    pavcat_id,
    function_type,
    code,
    expl_id,
    dma_id,
    press1,
    press2,
    flow_avg,
    longevity,
    rleak,
    nrw,
    strategic,
    mandatory,
    compliance,
    mincut_customers,
    mincut_criticity,
    val,
    orderby,
    expected_year,
    replacement_year,
    budget,
    total,
    length,
    cum_length,
    the_geom
   FROM arc_output o
     JOIN selector_result_main s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE VIEW v_asset_arc_output_compare AS
 SELECT arc_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    arccat_id,
    dnom,
    matcat_id,
    pavcat_id,
    function_type,
    code,
    expl_id,
    dma_id,
    press1,
    press2,
    flow_avg,
    longevity,
    rleak,
    nrw,
    strategic,
    mandatory,
    compliance,
    mincut_customers,
    mincut_criticity,
    val,
    orderby,
    expected_year,
    replacement_year,
    budget,
    total,
    length,
    cum_length,
    the_geom
   FROM arc_output o
     JOIN selector_result_compare s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW v_asset_arc_corporate
AS SELECT o.arc_id,
    o.result_id,
    o.sector_id,
    o.macrosector_id,
    o.presszone_id,
    o.builtdate,
    o.arccat_id,
    o.dnom,
    o.matcat_id,
    o.pavcat_id,
    o.function_type,
    o.code,
    o.expl_id,
    o.dma_id,
    o.press1,
    o.press2,
    o.flow_avg,
    o.longevity,
    o.rleak,
    o.nrw,
    o.strategic,
    o.mandatory,
    o.compliance,
    o.mincut_customers,
    o.mincut_criticity,
    o.val,
    o.orderby,
    o.expected_year,
    o.replacement_year,
    o.budget,
    o.total,
    o.length,
    o.cum_length,
    o.the_geom
   FROM arc_output o
     JOIN cat_result r ON r.result_id = o.result_id
  WHERE r.iscorporate = TRUE;

CREATE VIEW v_asset_node_output AS
 SELECT node_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    nodecat_id,
    node_type,
    code,
    expl_id,
    dma_id,
    longevity,
    incident_history,
    structural_condition,
    operational_condition,
    nrw,
    affected_users,
    strategic,
    mandatory,
    compliance,
    val,
    orderby,
    selected,
    expected_year,
    replacement_year,
    budget,
    total,
    estimated_cost,
    comments,
    data_quality_class,
    the_geom
   FROM node_output o
     JOIN selector_result_main s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE VIEW v_asset_node_output_compare AS
 SELECT node_id,
    o.result_id,
    sector_id,
    macrosector_id,
    presszone_id,
    builtdate,
    nodecat_id,
    node_type,
    code,
    expl_id,
    dma_id,
    longevity,
    incident_history,
    structural_condition,
    operational_condition,
    nrw,
    affected_users,
    strategic,
    mandatory,
    compliance,
    val,
    orderby,
    selected,
    expected_year,
    replacement_year,
    budget,
    total,
    estimated_cost,
    comments,
    data_quality_class,
    the_geom
   FROM node_output o
     JOIN selector_result_compare s ON (s.result_id = o.result_id)
  WHERE (s.cur_user = (CURRENT_USER)::text);

CREATE OR REPLACE VIEW v_asset_node_corporate
AS SELECT o.node_id,
    o.result_id,
    o.sector_id,
    o.macrosector_id,
    o.presszone_id,
    o.builtdate,
    o.nodecat_id,
    o.node_type,
    o.code,
    o.expl_id,
    o.dma_id,
    o.longevity,
    o.incident_history,
    o.structural_condition,
    o.operational_condition,
    o.nrw,
    o.affected_users,
    o.strategic,
    o.mandatory,
    o.compliance,
    o.val,
    o.orderby,
    o.selected,
    o.expected_year,
    o.replacement_year,
    o.budget,
    o.total,
    o.estimated_cost,
    o.comments,
    o.data_quality_class,
    o.the_geom
   FROM node_output o
     JOIN cat_result r ON r.result_id = o.result_id
  WHERE r.iscorporate = TRUE;

--
-- Default values
--
SET search_path = am, public;

INSERT INTO config_engine_def VALUES ('bratemain0', '0.05', 'SH', NULL, NULL, true, 'lyt_engine_1', 1, 'Break rate coefficient', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('drate', '0.05', 'SH', NULL, NULL, true, 'lyt_engine_1', 2, 'Discount rate (%)', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('rleak_1', '0.2', 'WM', NULL, NULL, true, 'lyt_engine_1', 3, 'Real breaks', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('mleak_1', '0.1', 'WM', NULL, NULL, true, 'lyt_engine_1', 4, 'Probability of failure', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('longevity_1', '0.7', 'WM', NULL, NULL, true, 'lyt_engine_1', 5, 'Longevity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('flow_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 6, 'Circulating flow', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('nrw_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 7, 'ANC', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('strategic_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 8, 'Strategic', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('compliance_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 9, 'Compliance', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('mincut_criticity_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 10, 'Mincut criticity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('expected_year', '0.7', 'SH', NULL, NULL, true, 'lyt_engine_2', 1, 'Weight expected year', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('compliance', '0.1', 'SH', NULL, NULL, true, 'lyt_engine_2', 2, 'Weight compliance', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('strategic', '0.2', 'SH', NULL, NULL, true, 'lyt_engine_2', 3, 'Weight strategic', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('rleak_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 4, 'Real breaks', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('mleak_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 5, 'Probability of failure', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('longevity_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 6, 'Longevity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('flow_2', '0.5', 'WM', NULL, NULL, true, 'lyt_engine_2', 7, 'Circulating flow', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('nrw_2', '0.2', 'WM', NULL, NULL, true, 'lyt_engine_2', 8, 'ANC', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('strategic_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 9, 'Strategic', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('compliance_2', '0.3', 'WM', NULL, NULL, true, 'lyt_engine_2', 10, 'Compliance', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');
INSERT INTO config_engine_def VALUES ('mincut_criticity_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 11, 'Mincut criticity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ARC');

--
-- Stage 2: NODE Weighted Method default weights
--
INSERT INTO config_engine_def (
    parameter, value, method, round, descript, active, layoutname, layoutorder,
    label, datatype, widgettype, dv_querytext, dv_controls, ismandatory, iseditable,
    stylesheet, widgetcontrols, placeholder, standardvalue, asset_type
) VALUES
    ('longevity_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 1, 'Longevity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('incident_history_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 2, 'Incident history', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('structural_condition_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 3, 'Structural condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('operational_condition_1', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_1', 4, 'Operational condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('nrw_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 5, 'ANC', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('affected_users_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 6, 'Affected users', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('strategic_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 7, 'Strategic', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('compliance_1', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_1', 8, 'Compliance', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('longevity_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 1, 'Longevity', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('incident_history_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 2, 'Incident history', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('structural_condition_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 3, 'Structural condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('operational_condition_2', '0.0', 'WM', NULL, NULL, true, 'lyt_engine_2', 4, 'Operational condition', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('nrw_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 5, 'ANC', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('affected_users_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 6, 'Affected users', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('strategic_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 7, 'Strategic', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE'),
    ('compliance_2', '0.25', 'WM', NULL, NULL, true, 'lyt_engine_2', 8, 'Compliance', 'float', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NODE');

--
-- config_form_tableview
--

INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_catalog_def', 'dnom', 0, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_catalog_def', 'cost_constr', 1, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_catalog_def', 'cost_repmain', 2, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_catalog_def', 'compliance', 3, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'dnom', 0, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'cost_constr', 1, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'cost_repmain', 2, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_nodecatalog_def', 'compliance', 3, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_material_def', 'material', 0, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_material_def', 'pleak', 1, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_material_def', 'age_max', 2, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_material_def', 'age_med', 3, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_material_def', 'age_min', 4, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_material_def', 'builtdate_vdef', 5, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_material_def', 'compliance', 6, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'parameter', 0, true, NULL, NULL, NULL);
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'value', 1, true, NULL, NULL, NULL);
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'method', 2, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'round', 3, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'descript', 4, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'active', 5, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'layoutname', 6, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'layoutorder', 7, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'label', 8, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'datatype', 9, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'widgettype', 10, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'dv_querytext', 11, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'dv_controls', 12, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'ismandatory', 13, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'iseditable', 14, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'stylesheet', 15, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'widgetcontrols', 16, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'planceholder', 17, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_config', 'utils', 'config_engine_def', 'standardvalue', 18, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'result_id', 0, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'result_name', 1, true, NULL, NULL, NULL);
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'result_type', 2, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'descript', 3, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'report', 4, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'expl_id', 5, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'budget', 6, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'target_year', 7, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'tstamp', 8, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'cur_user', 9, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'status', 10, true, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'presszone_id', 11, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'material_id', 12, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'features', 13, false, NULL, NULL, '{"stretch": true}');
INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'dnom', 14, false, NULL, NULL, '{"stretch": true}');


INSERT INTO value_status VALUES ('CANCELED', 'CANCELED');
INSERT INTO value_status VALUES ('ON PLANNING', 'ON PLANNING');
INSERT INTO value_status VALUES ('FINISHED', 'FINISHED');

INSERT INTO value_result_type VALUES ('GLOBAL', 'GLOBAL');
INSERT INTO value_result_type VALUES ('SELECTION', 'SELECTION');

INSERT INTO config_form_tableview VALUES ('priority_manager', 'utils', 'cat_result', 'iscorporate', 15, true, NULL, NULL, '{"stretch": true}');

ALTER TABLE config_catalog_def ADD CONSTRAINT config_catalog_def_arccat_id UNIQUE (arccat_id);

UPDATE config_form_tableview SET alias = 'Result Id' WHERE objectname = 'cat_result' AND columnname = 'result_id';
UPDATE config_form_tableview SET alias = 'Result Name' WHERE objectname = 'cat_result' AND columnname = 'result_name';
UPDATE config_form_tableview SET alias = 'Type' WHERE objectname = 'cat_result' AND columnname = 'result_type';
UPDATE config_form_tableview SET alias = 'Descript' WHERE objectname = 'cat_result' AND columnname = 'descript';
UPDATE config_form_tableview SET alias = 'Report' WHERE objectname = 'cat_result' AND columnname = 'report';
UPDATE config_form_tableview SET alias = 'Expl Id' WHERE objectname = 'cat_result' AND columnname = 'expl_id';
UPDATE config_form_tableview SET alias = 'Budget' WHERE objectname = 'cat_result' AND columnname = 'budget';
UPDATE config_form_tableview SET alias = 'Horizon Year' WHERE objectname = 'cat_result' AND columnname = 'target_year';
UPDATE config_form_tableview SET alias = 'Timestamp' WHERE objectname = 'cat_result' AND columnname = 'tstamp';
UPDATE config_form_tableview SET alias = 'Current User' WHERE objectname = 'cat_result' AND columnname = 'cur_user';
UPDATE config_form_tableview SET alias = 'Status' WHERE objectname = 'cat_result' AND columnname = 'status';
UPDATE config_form_tableview SET alias = 'Corporate' WHERE objectname = 'cat_result' AND columnname = 'iscorporate';
UPDATE config_form_tableview SET alias = 'Features' WHERE objectname = 'cat_result' AND columnname = 'features';
UPDATE config_form_tableview SET alias = 'DNOM' WHERE objectname = 'cat_result' AND columnname = 'dnom';
UPDATE config_form_tableview SET alias = 'Presszone' WHERE objectname = 'cat_result' AND columnname = 'presszone_id';
UPDATE config_form_tableview SET alias = 'Material' WHERE objectname = 'cat_result' AND columnname = 'material_id';


GRANT ALL ON TABLE arc_engine_sh TO role_basic;
GRANT ALL ON TABLE arc_engine_wm TO role_basic;
GRANT ALL ON TABLE arc_input TO role_basic;
GRANT ALL ON TABLE arc_output TO role_basic;
GRANT ALL ON TABLE cat_result TO role_basic;
GRANT ALL ON TABLE config_catalog TO role_basic;
GRANT ALL ON TABLE config_catalog_def TO role_basic;
GRANT ALL ON TABLE config_nodecatalog TO role_basic;
GRANT ALL ON TABLE config_nodecatalog_def TO role_basic;
GRANT ALL ON TABLE config_engine TO role_basic;
GRANT ALL ON TABLE config_engine_def TO role_basic;
GRANT ALL ON TABLE config_form_tableview TO role_basic;
GRANT ALL ON TABLE config_material TO role_basic;
GRANT ALL ON TABLE config_material_def TO role_basic;
GRANT ALL ON TABLE dma_nrw TO role_basic;
GRANT ALL ON TABLE leaks TO role_basic;
GRANT ALL ON TABLE selector_result_compare TO role_basic;
GRANT ALL ON TABLE selector_result_main TO role_basic;
GRANT ALL ON TABLE value_result_type TO role_basic;
GRANT ALL ON TABLE value_status TO role_basic;
GRANT ALL ON TABLE node_input TO role_basic;
GRANT ALL ON TABLE node_engine_wm TO role_basic;
GRANT ALL ON TABLE node_output TO role_basic;
GRANT ALL ON TABLE v_asset_node_output TO role_basic;
GRANT ALL ON TABLE v_asset_node_output_compare TO role_basic;
GRANT ALL ON TABLE v_asset_node_corporate TO role_basic;

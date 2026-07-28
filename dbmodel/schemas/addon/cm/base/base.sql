/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cm, public, pg_catalog;

-- system roles
DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'role_cm_admin'
   ) THEN
      CREATE role role_cm_admin WITH NOSUPERUSER NOCREATEDB NOCREATEROLE inherit NOREPLICATION NOBYPASSRLS;
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'role_cm_manager'
   ) THEN
      CREATE role role_cm_manager WITH NOSUPERUSER NOCREATEDB NOCREATEROLE inherit NOREPLICATION NOBYPASSRLS;
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'role_cm_field'
   ) THEN
      CREATE role role_cm_field WITH NOSUPERUSER NOCREATEDB NOCREATEROLE inherit NOREPLICATION NOBYPASSRLS;
   END IF;
END
$$;

DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'role_cm_edit'
   ) THEN
      CREATE role role_cm_edit WITH NOSUPERUSER NOCREATEDB NOCREATEROLE inherit NOREPLICATION NOBYPASSRLS;
   END IF;
END
$$;


-- system tables
CREATE TABLE sys_table (
	id text NOT NULL,
	descript text NULL,
	sys_role varchar(30) NULL,
	project_template jsonb NULL,
	context varchar(500) NULL,
	orderby int2 NULL,
	alias text NULL,
	notify_action json NULL,
	isaudit bool NULL,
	keepauditdays int4 NULL,
	"source" text NULL,
	addparam json NULL,
	CONSTRAINT sys_table_pkey PRIMARY KEY (id)
);

CREATE TABLE sys_version (
	id serial4 NOT NULL,
	giswater varchar(16) NOT NULL,
	project_type varchar(16) NOT NULL,
	postgres varchar(512) NOT NULL,
	postgis varchar(512) NOT NULL,
	"date" timestamp(6) NOT NULL DEFAULT now(),
	"language" varchar(50) NOT NULL,
	epsg int4 NOT NULL,
	addparam jsonb NULL,
	CONSTRAINT sys_version_pkey PRIMARY KEY (id)
);

CREATE TABLE sys_param_user (
	id text NOT NULL,
	formname text NULL,
	descript text NULL,
	sys_role varchar(30) NULL,
	idval text NULL,
	"label" text NULL,
	dv_querytext text NULL,
	dv_parent_id text NULL,
	isenabled bool NULL,
	layoutorder int4 NULL,
	project_type varchar NULL,
	isparent bool NULL,
	dv_querytext_filterc text NULL,
	feature_field_id text NULL,
	feature_dv_parent_value text NULL,
	isautoupdate bool NULL,
	"datatype" varchar(30) NULL,
	widgettype varchar(30) NULL,
	ismandatory bool NULL,
	widgetcontrols json NULL,
	vdefault text NULL,
	layoutname text NULL,
	iseditable bool NULL,
	dv_orderby_id bool NULL,
	dv_isnullvalue bool NULL,
	stylesheet json NULL,
	placeholder text NULL,
	"source" text NULL,
	CONSTRAINT sys_param_user_pkey PRIMARY KEY (id)
);

CREATE TABLE config_form_fields (
	formname varchar(50) NOT NULL,
	formtype varchar(50) NOT NULL,
	tabname varchar(30) NOT NULL,
	columnname varchar(30) NOT NULL,
	layoutname text NULL,
	layoutorder int4 NULL,
	"datatype" varchar(30) NULL,
	widgettype varchar(30) NULL,
	"label" text NULL,
	tooltip text NULL,
	placeholder text NULL,
	ismandatory bool NULL,
	isparent bool NULL,
	iseditable bool NULL,
	isautoupdate bool NULL,
	isfilter bool NULL,
	dv_querytext text NULL,
	dv_orderby_id bool NULL,
	dv_isnullvalue bool NULL,
	dv_parent_id text NULL,
	dv_querytext_filterc text NULL,
	stylesheet json NULL,
	widgetcontrols json NULL,
	widgetfunction json NULL,
	linkedobject text NULL,
	hidden bool DEFAULT false NOT NULL,
	web_layoutorder int4 NULL,
	field_layoutorder int4 NULL,
	CONSTRAINT config_form_fields_pkey PRIMARY KEY (formname, formtype, columnname, tabname)
);

CREATE TABLE config_form_tabs (
	formname varchar(50) NOT NULL,
	tabname text NOT NULL,
	"label" text NULL,
	tooltip text NULL,
	sys_role text NULL,
	tabfunction json NULL,
	tabactions json NULL,
	orderby int4 NULL,
	device _int4 NULL,
	CONSTRAINT config_form_tabs_pkey PRIMARY KEY (formname, tabname)
);

CREATE TABLE cm_form_config (
    id serial PRIMARY KEY,
    campaign_ids integer[] NOT NULL,
    layer_name varchar(255) NOT NULL,
    field_name varchar(255) NOT NULL,
    field_order integer,
    is_hidden boolean DEFAULT false
);

CREATE TABLE config_param_system (
	"parameter" varchar(50) NOT NULL,
	value text NULL,
	descript text NULL,
	"label" text NULL,
	dv_querytext text NULL,
	dv_filterbyfield text NULL,
	isenabled bool NULL,
	layoutorder int4 NULL,
	project_type varchar NULL,
	dv_isparent bool NULL,
	isautoupdate bool NULL,
	"datatype" varchar NULL,
	widgettype varchar NULL,
	ismandatory bool NULL,
	iseditable bool NULL,
	dv_orderby_id bool NULL,
	dv_isnullvalue bool NULL,
	stylesheet json NULL,
	widgetcontrols json NULL,
	placeholder text NULL,
	standardvalue text NULL,
	layoutname text NULL,
	CONSTRAINT config_param_system_pkey PRIMARY KEY (parameter)
);

CREATE TABLE config_param_user (
	"parameter" varchar(50) NOT NULL,
	value text NULL,
	cur_user varchar(50) NOT NULL,
	CONSTRAINT config_param_user_pkey PRIMARY KEY (parameter, cur_user)
);

CREATE INDEX IF NOT EXISTS config_param_user_cur_user ON config_param_user USING btree (cur_user);
CREATE INDEX IF NOT EXISTS config_param_user_value ON config_param_user USING btree (value);

CREATE TABLE sys_typevalue (
	typevalue text NOT NULL,
	id varchar(30) NOT NULL,
	idval text NULL,
	descript text NULL,
	addparam json NULL,
	CONSTRAINT sys_typevalue_pkey PRIMARY KEY (typevalue, id)
);

CREATE TABLE cat_pschema (
  pschema_id serial2,
  name text,
  observ text,
  CONSTRAINT cat_pschema_pkey PRIMARY KEY (pschema_id)
);



-- catalogs
CREATE TABLE cat_role (
	role_id text PRIMARY KEY,
	descript text
);


CREATE TABLE cat_organization (
	organization_id serial4,
	code text NULL,
	orgname text NULL,
	descript text NULL,
	expl_id int[],
	sector_id int[],
	active bool NULL DEFAULT true,
	CONSTRAINT cat_organization_unique UNIQUE (orgname),
	CONSTRAINT cat_organization_pkey PRIMARY KEY (organization_id)
);


CREATE TABLE cat_team (
	team_id serial4,
	code text NULL,
	teamname text not NULL,
	organization_id int4 NOT NULL,
	descript text NULL,
	role_id TEXT NULL DEFAULT 'role_cm_field',
	active bool NULL DEFAULT true,
	CONSTRAINT cat_team_pkey PRIMARY KEY (team_id),
	CONSTRAINT cat_team_unique UNIQUE (teamname, organization_id),
	CONSTRAINT cat_team_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES cat_organization(organization_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE cat_user (
  user_id serial4 PRIMARY KEY,
  username text not NULL,
  team_id int4,
  roles text[],
  active boolean DEFAULT TRUE,
  CONSTRAINT cat_user_unique UNIQUE (username),
  CONSTRAINT cat_user_team_id_fkey FOREIGN KEY (team_id) REFERENCES cat_team(team_id)
);

---- workorder
CREATE TABLE workorder_type (
  id character varying(50) NOT NULL,
  idval character varying(50),
  CONSTRAINT ext_workorder_type_pkey PRIMARY KEY (id)
);

CREATE TABLE workorder_class (
  id character varying(50) NOT NULL,
  idval character varying(50),
  CONSTRAINT ext_workorder_class_pkey PRIMARY KEY (id)
);

CREATE TABLE workorder (
  workorder_id serial4 NOT NULL,
  workorder_name character varying(50),
  workorder_type character varying(50),
  workorder_class character varying(200),
  exercise integer,
  serie character varying(10),
  startdate date,
  address character varying(50),
  observ text,
  cost numeric,
  CONSTRAINT workorder_pkey PRIMARY KEY (workorder_id),
  CONSTRAINT ext_workorder_workorder_type_fkey FOREIGN KEY (workorder_type) REFERENCES workorder_type (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT workorder_workorder_class_fkey FOREIGN KEY (workorder_class) REFERENCES workorder_class (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);



CREATE TABLE om_reviewclass (
  id serial NOT NULL,
  idval text,
  pschema_id text,
  descript text,
  active boolean DEFAULT true,
  CONSTRAINT om_reviewclass_pkey PRIMARY KEY (id)
);

CREATE TABLE om_reviewclass_x_object (
  reviewclass_id integer NOT NULL,
  object_id text NOT NULL,
  orderby int2,
  active boolean DEFAULT true,
  CONSTRAINT om_reviewclass_x_object_pkey PRIMARY KEY (reviewclass_id, object_id)
);

CREATE TABLE om_inventoryclass (
  id serial NOT NULL,
  idval text,
  pschema_id text,
  descript text,
  active boolean DEFAULT true,
  CONSTRAINT om_inventoryclass_pkey PRIMARY KEY (id)
);

CREATE TABLE om_inventory_x_object (
  inventoryclass_id integer NOT NULL,
  object_id text NOT NULL,
  orderby int2,
  active boolean DEFAULT true,
  CONSTRAINT om_inventory_x_object_pkey PRIMARY KEY (inventoryclass_id, object_id)
);

CREATE TABLE om_visitclass (
  id serial NOT NULL,
  idval text,
  pschema_id text,
  descript text,
  feature_type text,
  active boolean DEFAULT true,
  CONSTRAINT om_visitclass_pkey PRIMARY KEY (id)
);


-- campaign
CREATE TABLE om_campaign (
  campaign_id serial NOT NULL,
  name text not null,
  startdate date DEFAULT now(),
  enddate date,
  real_startdate date,
  real_enddate date,
  campaign_type integer not null,
  descript text,
  active boolean DEFAULT true,
  organization_id integer,
  status integer not NULL,
  expl_id integer,
  sector_id integer,
  qindex1 numeric(12, 3) NULL,
  qindex2 numeric(12, 3) NULL,
  rating int2 NULL,
  workcat_id text NULL,
  the_geom geometry(MultiPolygon,SRID_VALUE),
  CONSTRAINT om_campaign_pkey PRIMARY KEY (campaign_id),
  CONSTRAINT om_campaign_check_type check (campaign_type in (1,2,3)),
  CONSTRAINT om_campaign_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES cat_organization(organization_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE om_campaign_visit (
  campaign_id integer NOT NULL,
  visitclass_id integer,
  CONSTRAINT om_campaign_visit_pkey PRIMARY KEY (campaign_id),
  CONSTRAINT om_campaign_visit_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT om_team_x_user_visitclass_id_fkey FOREIGN KEY (visitclass_id) REFERENCES om_visitclass (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE om_campaign_review (
  campaign_id integer NOT NULL,
  reviewclass_id integer,
  CONSTRAINT om_campaign_review_pkey PRIMARY KEY (campaign_id),
  CONSTRAINT om_campaign_review_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT om_campaign_review_reviewclass_id_fkey FOREIGN KEY (reviewclass_id) REFERENCES om_reviewclass (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE om_campaign_inventory (
  campaign_id integer NOT NULL,
  inventoryclass_id integer,
  CONSTRAINT om_campaign_inventory_pkey PRIMARY KEY (campaign_id),
  CONSTRAINT om_campaign_inventory_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT om_campaign_inventory_inventoryclass_id_fkey FOREIGN KEY (inventoryclass_id) REFERENCES om_inventoryclass (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE om_campaign_inventory_x_arc (
  id serial4 NOT NULL,
  campaign_id integer NOT NULL,
  arc_id int4 NOT NULL,
  code character varying(30),
  status int2,
  admin_observ text,
  org_observ text,
  CONSTRAINT om_campaign_inventory_x_arc_pkey PRIMARY KEY (id),
  CONSTRAINT om_campaign_inventory_x_arc_un UNIQUE (campaign_id, arc_id),
  CONSTRAINT om_campaign_inventory_x_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES cm.om_campaign_inventory (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE om_campaign_inventory_x_node (
  id serial4 NOT NULL,
  campaign_id integer NOT NULL,
  node_id int4 NOT NULL,
  code character varying(30),
  status int2,
  admin_observ text,
  org_observ text,
  CONSTRAINT om_campaign_inventory_x_node_pkey PRIMARY KEY (id),
  CONSTRAINT om_campaign_inventory_x_node_un UNIQUE (campaign_id, node_id),
  CONSTRAINT om_campaign_inventory_x_node_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES cm.om_campaign_inventory (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE om_campaign_inventory_x_connec (
  id serial4 NOT NULL,
  campaign_id integer NOT NULL,
  connec_id int4 NOT NULL,
  code character varying(30),
  status int2,
  admin_observ text,
  org_observ text,
  CONSTRAINT om_campaign_inventory_x_connec_pkey PRIMARY KEY (id),
  CONSTRAINT om_campaign_inventory_x_connec_un UNIQUE (campaign_id, connec_id),
  CONSTRAINT om_campaign_inventory_x_connec_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES cm.om_campaign_inventory (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE om_campaign_inventory_x_link (
  id serial4 NOT NULL,
  campaign_id integer NOT NULL,
  link_id int4 NOT NULL,
  code character varying(30),
  status int2,
  admin_observ text,
  org_observ text,
  CONSTRAINT om_campaign_inventory_x_link_pkey PRIMARY KEY (id),
  CONSTRAINT om_campaign_inventory_x_link_un UNIQUE (campaign_id, link_id),
  CONSTRAINT om_campaign_inventory_x_link_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES cm.om_campaign_inventory (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE om_campaign_x_arc (
	id serial4 NOT NULL,
	campaign_id int4 NOT NULL,
	arc_id int4 NOT NULL,
	node_1 int4 NULL,
	node_2 int4 NULL,
	code varchar(30) NULL,
	status int2 NULL,
	admin_observ text NULL,
	org_observ text NULL,
	arccat_id text NULL,
	arc_type text NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	the_geom geometry(linestring, SRID_VALUE) NULL,
	CONSTRAINT om_campaign_x_arc_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_x_arc_un UNIQUE (campaign_id, arc_id),
	CONSTRAINT om_campaign_x_arc_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign(campaign_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE om_campaign_x_connec (
	id serial4 NOT NULL,
	campaign_id int4 NOT NULL,
	connec_id int4 NOT NULL,
	code varchar(30) NULL,
	status int2 NULL,
	admin_observ text NULL,
	org_observ text NULL,
	conneccat_id text NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	the_geom geometry(point, SRID_VALUE) NULL,
	CONSTRAINT om_campaign_x_connec_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_x_connec_un UNIQUE (campaign_id, connec_id),
	CONSTRAINT om_campaign_x_connec_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign(campaign_id) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE om_campaign_x_link (
	id serial4 NOT NULL,
	campaign_id int4 NOT NULL,
	link_id int4 NOT NULL,
	code varchar(30) NULL,
	status int2 NULL,
	admin_observ text NULL,
	org_observ text NULL,
	linkcat_id text NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	the_geom geometry(linestring, SRID_VALUE) NULL,
	CONSTRAINT om_campaign_x_link_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_x_link_un UNIQUE (campaign_id, link_id),
	CONSTRAINT om_campaign_x_link_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign(campaign_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE om_campaign_x_node (
	id serial4 NOT NULL,
	campaign_id int4 NOT NULL,
	node_id int4 NOT NULL,
	code varchar(30) NULL,
	status int2 NULL,
	admin_observ text NULL,
	org_observ text NULL,
	nodecat_id text NULL,
	node_type text NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	the_geom geometry(point, SRID_VALUE) NULL,
	CONSTRAINT om_campaign_x_node_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_x_node_un UNIQUE (campaign_id, node_id),
	CONSTRAINT om_campaign_x_node_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign(campaign_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE om_campaign_x_gully (
	id serial4 NOT NULL,
	campaign_id integer NOT NULL,
	gully_id int4 NOT NULL,
	code character varying(30),
	status int2,
	admin_observ text,
	org_observ text,
	gullycat_id text,
	gully_type text,
	the_geom public.geometry(point, SRID_VALUE) NULL,
	CONSTRAINT om_campaign_x_gully_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_x_gully_un UNIQUE (campaign_id, gully_id),
	CONSTRAINT om_campaign_x_gully_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE om_campaign_lot (
  lot_id serial NOT NULL,
  name text not null, -- must add constraint unique
  startdate date DEFAULT now(),
  enddate date,
  real_startdate date,
  real_enddate date,
  campaign_id integer not NULL, -- fk om_campaign
  workorder_id integer, -- fk workorder
  descript text,
  active boolean DEFAULT true,
  team_id integer, -- fk cat_team
  status int2 not NULL,
  expl_id integer,
  sector_id integer,
  qindex1 numeric(12, 3) NULL,
  qindex2 numeric(12, 3) NULL,
  rating int2 NULL,
  the_geom geometry(MULTIPOLYGON,SRID_VALUE),
  CONSTRAINT om_campaign_lot_pkey PRIMARY KEY (lot_id),
  CONSTRAINT om_campaign_lot_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT om_campaign_lot_workorder_id_fkey FOREIGN KEY (workorder_id) REFERENCES workorder (workorder_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT om_campaign_lot_team_id_fkey FOREIGN KEY (team_id) REFERENCES cat_team (team_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE om_campaign_lot_x_arc (
	id serial4 NOT NULL,
	lot_id int4 NOT NULL,
	arc_id int4 NOT NULL,
	node_1 int4 NULL,
	node_2 int4 NULL,
	code varchar(30) NULL,
	status int2 NULL,
	org_observ text NULL,
	team_observ text NULL,
	update_count int4 NULL,
	update_log jsonb NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	action int2 NULL,
	CONSTRAINT om_campaign_lot_x_arc_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_lot_x_arc_un UNIQUE (lot_id, arc_id),
	CONSTRAINT om_campaign_lot_x_arc_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES om_campaign_lot(lot_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE om_campaign_lot_x_connec (
	id serial4 NOT NULL,
	lot_id int4 NOT NULL,
	connec_id int4 NOT NULL,
	code varchar(30) NULL,
	status int2 NULL,
	org_observ text NULL,
	team_observ text NULL,
	update_count int4 NULL,
	update_log jsonb NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	action int2 NULL,
	CONSTRAINT om_campaign_lot_x_connec_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_lot_x_connec_un UNIQUE (lot_id, connec_id),
	CONSTRAINT om_campaign_lot_x_connec_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES om_campaign_lot(lot_id) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE om_campaign_lot_x_link (
	id serial4 NOT NULL,
	lot_id int4 NOT NULL,
	link_id int4 NOT NULL,
	code varchar(30) NULL,
	status int2 NULL,
	org_observ text NULL,
	team_observ text NULL,
	update_count int4 NULL,
	update_log jsonb NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	action int2 NULL,
	CONSTRAINT om_campaign_lot_x_link_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_lot_x_link_un UNIQUE (lot_id, link_id),
	CONSTRAINT om_campaign_lot_x_link_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES om_campaign_lot(lot_id) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE om_campaign_lot_x_node (
	id serial4 NOT NULL,
	lot_id int4 NOT NULL,
	node_id int4 NOT NULL,
	code varchar(30) NULL,
	status int2 NULL,
	org_observ text NULL,
	team_observ text NULL,
	update_count int4 NULL,
	update_log jsonb NULL,
	qindex1 numeric(12, 3) NULL,
	qindex2 numeric(12, 3) NULL,
	action int2 NULL,
	CONSTRAINT om_campaign_lot_x_node_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_lot_x_node_un UNIQUE (lot_id, node_id),
	CONSTRAINT om_campaign_lot_x_node_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES om_campaign_lot(lot_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE om_campaign_lot_x_gully (
	id serial4 NOT NULL,
	lot_id integer NOT NULL,
	gully_id int4 NOT NULL,
	code character varying(30),
	status int2,
	org_observ text,
	team_observ text,
	update_count integer,
	update_log jsonb,
	qindex1 numeric(12,3),
	qindex2 numeric(12,3),
	action int2,
	the_geom geometry(POINT, SRID_VALUE),
	CONSTRAINT om_campaign_lot_x_gully_pkey PRIMARY KEY (id),
	CONSTRAINT om_campaign_lot_x_gully_un UNIQUE (lot_id, gully_id),
	CONSTRAINT om_campaign_lot_x_gully_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES om_campaign_lot (lot_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE config_outlayers (
	feature_type text[] NOT NULL,
	column_name text NOT NULL,
	min_value text,
	max_value text,
	except_error boolean,
	except_message text,
	CONSTRAINT config_outlayers_pkey PRIMARY KEY (feature_type, column_name)
);

-- New rating configuration tables
CREATE TABLE config_qindex_rating (
  id serial4 PRIMARY KEY,
  minval numeric(12,3),
  maxval numeric(12,3),
  rating text
);

CREATE TABLE config_qindex_keyparam (
  layer text[] NOT NULL,
  column_name text NOT NULL,
  active boolean DEFAULT true,
  CONSTRAINT config_qindex_keyparam_pkey PRIMARY KEY (layer, column_name)
);

CREATE TABLE selector_campaign (
  campaign_id integer, -- fk om_campaign
  cur_user text DEFAULT "current_user"(),
  CONSTRAINT selector_campaign_pkey PRIMARY KEY (campaign_id, cur_user),
  CONSTRAINT selector_campaign_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES om_campaign (campaign_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE selector_lot (
  lot_id integer, -- fk om_campaign_lot
  cur_user text DEFAULT "current_user"(),
  CONSTRAINT selector_lot_pkey PRIMARY KEY (lot_id, cur_user),
  CONSTRAINT selector_lot_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES om_campaign_lot (lot_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT selector_lot_lot_id_cur_user_unique UNIQUE (lot_id, cur_user)
);

CREATE TABLE sys_fprocess (
	fid int4 NOT NULL,
	fprocess_name varchar(100) NULL,
	project_type varchar(6) NULL,
	parameters json NULL,
	"source" text NULL,
	isaudit bool NULL,
	fprocess_type text NULL,
	addparam json NULL,
	except_level int4 NULL,
	except_msg text NULL,
	except_table text NULL,
	except_table_msg text NULL,
	query_text text NULL,
	info_msg text NULL,
	function_name text NULL,
	active bool NULL,
	CONSTRAINT sys_fprocess_pkey PRIMARY KEY (fid)
);

CREATE TABLE config_form_tableview (
	location_type varchar(50) NOT NULL,
	project_type varchar(50) NOT NULL,
	objectname varchar(50) NOT NULL,
	columnname varchar(50) NOT NULL,
	columnindex int2 NULL,
	visible bool NULL,
	width int4 NULL,
	alias varchar(50) NULL,
	"style" json NULL,
	addparam json NULL,
	CONSTRAINT config_form_tableview_pkey PRIMARY KEY (objectname, columnname)
);

CREATE TABLE audit_check_data (
	id serial4 NOT NULL,
	fid int2 NULL,
	result_id varchar(50) NULL,
	table_id text NULL,
	column_id text NULL,
	criticity int2 NULL,
	enabled bool NULL,
	error_message text NULL,
	tstamp timestamp NULL DEFAULT now(),
	cur_user text NULL DEFAULT "current_user"(),
	feature_type text NULL,
	feature_id text NULL,
	addparam json NULL,
	fcount int4 NULL,
	CONSTRAINT audit_check_data_pkey PRIMARY KEY (id)
);

CREATE SEQUENCE cm.cm_urn_id_seq
    INCREMENT BY -1
    MAXVALUE 1
    MINVALUE -9223372036854775807
    START -1
    CACHE 1
    NO CYCLE;

-- CM AUDIT TABLES (audit schema is created in init.sql as installer)
CREATE TABLE IF NOT EXISTS audit.sys_version (
	id serial4 NOT NULL,
	giswater varchar(16) NOT NULL,
	project_type varchar(16) NOT NULL,
	postgres varchar(512) NOT NULL,
	postgis varchar(512) NOT NULL,
	"date" timestamp(6) DEFAULT now() NOT NULL,
	"language" varchar(50) NOT NULL,
	epsg int4 NOT NULL,
	CONSTRAINT sys_version_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS audit.cm_log (
	table_name text NOT NULL,
  mission_type text NOT NULL,
	mission_id int4 NOT NULL,
	feature_id int4 NOT NULL,
	feature_type text NULL,
	"action" text NULL,
	sql varchar(100) NULL,
	old_value json NULL,
	new_value json NULL,
	insert_by TEXT NULL,
	insert_at timestamptz NOT NULL,
	CONSTRAINT audit_cm_log_pkey PRIMARY KEY (table_name, mission_type, mission_id, feature_id, insert_at)
);

CREATE INDEX IF NOT EXISTS audit_cm_log_insert_at ON audit.cm_log USING btree (insert_at);
CREATE INDEX IF NOT EXISTS audit_cm_log_mission_type ON audit.cm_log USING btree (mission_type);
CREATE INDEX IF NOT EXISTS audit_cm_log_action_insert_at ON audit.cm_log USING btree ("action", insert_at);

CREATE TABLE IF NOT EXISTS audit.cm_log_error (
  id serial4 NOT NULL,
  context text NOT NULL,
  error_code text NOT NULL,
  error_message text NOT NULL,
  insert_by TEXT NULL,
  insert_at timestamptz NOT NULL,
  CONSTRAINT audit_cm_log_error_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS audit_cm_log_error_insert_at ON audit.cm_log_error USING btree (insert_at);
CREATE INDEX IF NOT EXISTS audit_cm_log_error_error_code ON audit.cm_log_error USING btree (error_code);

CREATE TABLE cm.doc (
	id serial NOT NULL,
	name text NULL,
	doc_type varchar(30) NULL,
	"path" text NULL,
	observ varchar(512) NULL,
	"date" timestamp(6) DEFAULT now() NULL,
	user_name varchar(50) DEFAULT USER NULL,
	tstamp timestamp DEFAULT now() NULL,
	the_geom public.geometry(point, 8908) NULL,
	hash text NULL,
	lat numeric NULL,
	long numeric NULL,
	CONSTRAINT doc_pkey PRIMARY KEY (id),
	CONSTRAINT name_chk UNIQUE (name)
);

--drop table cm.doc_x_node;
CREATE TABLE cm.doc_x_node (
	doc_id int4 NOT NULL,
	node_id int4 NULL,
	node_uuid uuid NOT NULL,
	featurecat_id varchar(30),
	CONSTRAINT doc_x_node_pkey PRIMARY KEY (doc_id, node_uuid)
);

ALTER TABLE cm.doc_x_node ADD CONSTRAINT doc_x_node_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES cm.doc(id) ON DELETE CASCADE ON UPDATE CASCADE;

--drop table cm.doc_x_arc;
CREATE TABLE cm.doc_x_arc (
	doc_id int4 NOT NULL,
	arc_id int4 NULL,
	arc_uuid uuid NOT NULL,
	featurecat_id varchar(30),
	CONSTRAINT doc_x_arc_pkey PRIMARY KEY (doc_id, arc_uuid)
);

ALTER TABLE cm.doc_x_arc ADD CONSTRAINT doc_x_arc_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES cm.doc(id) ON DELETE CASCADE ON UPDATE CASCADE;

--drop table cm.doc_x_connec;
CREATE TABLE cm.doc_x_connec (
	doc_id int4 NOT NULL,
	connec_id int4 NULL,
	connec_uuid uuid NOT NULL,
	CONSTRAINT doc_x_connec_pkey PRIMARY KEY (doc_id, connec_uuid)
);

ALTER TABLE cm.doc_x_connec ADD CONSTRAINT doc_x_connec_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES cm.doc(id) ON DELETE CASCADE ON UPDATE CASCADE;

--drop table cm.doc_x_link;
CREATE TABLE cm.doc_x_link (
	doc_id int4 NOT NULL,
	link_id int4 NULL,
	link_uuid uuid NOT NULL,
	CONSTRAINT doc_x_link_pkey PRIMARY KEY (doc_id, link_uuid)
);

ALTER TABLE cm.doc_x_link ADD CONSTRAINT doc_x_link_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES cm.doc(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE cm.doc_x_gully (
	doc_id int4 NOT NULL,
	gully_id int4 NULL,
	gully_uuid uuid NOT NULL,
	CONSTRAINT doc_x_gully_pkey PRIMARY KEY (doc_id, gully_uuid)
);

ALTER TABLE cm.doc_x_gully ADD CONSTRAINT doc_x_gully_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES cm.doc(id) ON DELETE CASCADE ON UPDATE CASCADE;


CREATE TABLE cm.config_qindex_suspicious (
	param_name text NOT NULL,
	threshold numeric NULL,
	weight numeric NULL,
	tooltip text NULL,
	addparam json NULL,
	cur_user text DEFAULT CURRENT_USER NOT NULL,
	CONSTRAINT config_qindex_suspicious_pkey PRIMARY KEY (param_name, cur_user)
);


CREATE OR REPLACE VIEW v_ui_campaign AS
WITH campaign_reviewvisit AS (SELECT ocr.campaign_id, omr.idval FROM om_campaign_review ocr
	LEFT JOIN om_reviewclass omr ON ocr.reviewclass_id = omr.id
	UNION
	SELECT ocr.campaign_id, omr.idval FROM om_campaign_visit ocr
	LEFT JOIN om_reviewclass omr ON ocr.visitclass_id = omr.id)
	SELECT
	c.campaign_id,
	c."name",
	c.startdate,
	c.enddate,
	c.real_startdate,
	c.real_enddate,
	st.idval AS campaign_type,
	crv.idval AS campaign_class,
	c.descript,
	c.active,
	c.organization_id,
	c.workcat_id,
	c.status,
	c.the_geom
	FROM om_campaign c
	LEFT JOIN campaign_reviewvisit crv USING (campaign_id)
	LEFT JOIN sys_typevalue st ON st.id = c.campaign_type::TEXT	AND st.typevalue = 'campaign_type';

CREATE OR REPLACE VIEW v_ui_campaign_lot AS
	SELECT
	l.lot_id,
	l.name,
	l.startdate,
	l.enddate,
	l.real_startdate,
	l.real_enddate,
	c.name AS campaign_name,
	wo.workorder_name,
	l.descript,
	l.active,
	t.teamname as team_name,
	st.idval as status,
	l.expl_id,
	l.sector_id,
	l.the_geom
	FROM om_campaign_lot l
	LEFT JOIN om_campaign c ON l.campaign_id = c.campaign_id
	LEFT JOIN workorder wo ON l.workorder_id = wo.workorder_id
	LEFT JOIN cat_team t ON l.team_id = t.team_id
	LEFT JOIN sys_typevalue st ON st.id = l.status::text AND st.typevalue = 'lot_status';

CREATE OR REPLACE VIEW v_selector_lot
AS SELECT row_number() OVER () AS id,
    selector_lot.lot_id,
    om_campaign_lot.name,
    selector_lot.cur_user
   FROM selector_lot
     JOIN om_campaign_lot USING (lot_id)
  WHERE status in (3,4) AND selector_lot.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW v_filter_lot AS 
 SELECT ocl.lot_id, name, status, campaign_id, the_geom 
   FROM selector_lot sl 
     JOIN om_campaign_lot ocl ON ocl.lot_id = sl.lot_id
  WHERE sl.cur_user = "current_user"()::text;

CREATE OR REPLACE VIEW v_filter_campaign AS 
 SELECT oc.campaign_id, name, status, the_geom 
   FROM selector_campaign sc
     JOIN om_campaign oc ON oc.campaign_id = sc.campaign_id
  WHERE sc.cur_user = "current_user"()::text;

-- Permissions for v_selector_lot
GRANT SELECT ON TABLE cm.v_selector_lot TO role_cm_field;
GRANT SELECT ON TABLE cm.v_filter_lot TO role_cm_field;


CREATE OR REPLACE VIEW cm.ve_config_qindex_suspicious
AS SELECT param_name,
    threshold,
    weight,
    tooltip,
    addparam
   FROM cm.config_qindex_suspicious
  WHERE cur_user = CURRENT_USER;

-- View Triggers
CREATE TRIGGER gw_trg_cm_edit_qindex INSTEAD OF INSERT OR DELETE OR UPDATE ON cm.ve_config_qindex_suspicious 
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_edit_qindex();

-- Seed rating config
INSERT INTO config_qindex_rating(id, minval, maxval, rating) VALUES
  (1, NULL, 0.999, 'EXCELENTE'),
  (2, 1.000, 1.999, 'BUENO'),
  (3, 2.000, 2.999, 'ACEPTABLE'),
  (4, 3.000, 3.999, 'REGULAR'),
  (5, 4.000, 999.000, 'INACEPTABLE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_role VALUES ('role_cm_admin');
INSERT INTO cat_role VALUES ('role_cm_org');
INSERT INTO cat_role VALUES ('role_cm_field');
INSERT INTO cat_role VALUES ('role_cm_edit');
INSERT INTO cat_role VALUES ('role_cm_manager');

-- Per-user switch to disable topocontrol in CM
INSERT INTO sys_param_user (
  id, formname, descript, sys_role, idval, "label",
  dv_querytext, dv_parent_id, isenabled, layoutorder, project_type, isparent,
  dv_querytext_filterc, feature_field_id, feature_dv_parent_value, isautoupdate,
  "datatype", widgettype, ismandatory, widgetcontrols, vdefault, layoutname,
  iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, placeholder, "source"
) VALUES (
  'edit_disable_topocontrol', 'hidden', 'If true, CM topocontrol and feature proximity checks are disabled to allow data migration', 'role_cm_manager',
  NULL, NULL,
  NULL, NULL, TRUE, NULL, 'utils', NULL,
  NULL, NULL, NULL, FALSE,
  'boolean', 'check', TRUE, NULL, 'false', NULL,
  TRUE, NULL, NULL, NULL, NULL, 'core'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO config_param_system VALUES ('basic_selector_tab_lot',
'{"table":"temp_om_campaign_lot","selector":"selector_lot","table_id":"lot_id","selector_id":"lot_id","label":"lot_id, '' - '', name","orderBy":"lot_id","manageAll":true,"typeaheadFilter":" AND lower(concat(lot_id, '' - '', name))","query_filter":"AND active is true ","typeaheadForced":true,"selectionMode":"keepPreviousUsingShift"}',
'Variable to configura all options related to search for the specificic tab','Selector variables',null, null, true, null, 'utils', null, null, 'json','text');


INSERT INTO config_param_system VALUES ('basic_selector_tab_campaign',
'{"table":"temp_om_campaign","selector":"selector_campaign","table_id":"campaign_id","selector_id":"campaign_id","label":"campaign_id, '' - '', name","orderBy":"campaign_id","manageAll":true,"query_filter":"","typeaheadFilter":" AND lower(concat(id'' - '', name))","selectionMode":"keepPreviousUsingShift", "orderbyCheck":false}',
'Variable to configura all options related to search for the specificic tab','Selector variables',null, null, true, null, 'utils', null, null, 'json','text');

INSERT INTO config_param_system ("parameter", value, descript, "label", dv_querytext, dv_filterbyfield, isenabled, layoutorder, project_type, dv_isparent, isautoupdate, "datatype", widgettype, ismandatory, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, widgetcontrols, placeholder, standardvalue, layoutname)
VALUES('admin_campaign_type', '{"campaignReview":"true","campaignVisit":"false"}', 'Variable to specify wich type of campaign we whant to see when create', NULL, NULL, NULL, true, NULL, 'utils', NULL, NULL, 'json', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO config_form_tabs VALUES ('selector_campaign','tab_campaign','Campaign','Campaign','role_basic',null, null, 1, '{4}');
INSERT INTO config_form_tabs VALUES ('selector_campaign','tab_lot','Lot','Lot','role_basic', null, null, 2,'{4}');

INSERT INTO sys_typevalue (typevalue, id, idval, addparam) VALUES('layout_name_typevalue', 'lyt_buttons', 'lyt_buttons', '{"lytOrientation": "horizontal"}'::json) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO sys_typevalue VALUES ('campaign_type', 1, 'REVIEW', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_type', 2, 'VISIT', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_type', 3, 'INVENTORY', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO sys_typevalue VALUES ('campaign_status', 1, 'PLANIFYING', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 2, 'PLANIFIED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 3, 'ASSIGNED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 4, 'ON GOING', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 5, 'STAND-BY', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 6, 'EXECUTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 7, 'REJECTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 8, 'READY-TO-ACCEPT', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 9, 'ACCEPTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_status', 10, 'CANCELED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO sys_typevalue VALUES ('lot_status', 1, 'PLANIFYING', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 2, 'PLANIFIED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 3, 'ASSIGNED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 4, 'ON GOING', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 5, 'STAND-BY', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 6, 'EXECUTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 7, 'REJECTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 8, 'READY-TO-ACCEPT', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 9, 'ACCEPTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_status', 10, 'CANCELED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO sys_typevalue VALUES ('campaign_feature_status', 1, 'PLANIFIED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_feature_status', 2, 'NOT VISITED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_feature_status', 3, 'VISITED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_feature_status', 4, 'VISom_visitclassT AGAIN', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_feature_status', 5, 'ACCEPTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('campaign_feature_status', 6, 'CANCELED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO sys_typevalue VALUES ('lot_feature_status', 1, 'PLANIFIED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_feature_status', 2, 'NOT VISITED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_feature_status', 3, 'VISITED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_feature_status', 4, 'VISIT AGAIN', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_feature_status', 5, 'ACCEPTED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('lot_feature_status', 6, 'CANCELED', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO sys_typevalue VALUES ('sys_table_context', 0, '["CM", "CAMPAIGN"]', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;
INSERT INTO sys_typevalue VALUES ('sys_table_context', 1, '["CM", "LOT"]', NULL, NULL) ON CONFLICT (typevalue, id) DO NOTHING;

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'campaign_id', 'lyt_data_1', 1, 'integer', 'text', 'Campaign Id:', 'Id', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'name', 'lyt_data_1', 2, 'string', 'text', 'Name:', 'Name', NULL, true, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'startdate', 'lyt_data_1', 3, 'date', 'datetime', 'Planified start:', 'Planified start', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'enddate', 'lyt_data_1', 4, 'date', 'datetime', 'Planified end:', 'Planified end', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'real_startdate', 'lyt_data_1', 5, 'date', 'datetime', 'Real start:', 'Real start', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'real_enddate', 'lyt_data_1', 6, 'date', 'datetime', 'Real end:', 'Real end', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'reviewclass_id', 'lyt_data_1', 7, 'string', 'combo', 'Reviewclass:', 'Reviewclass', NULL, false, false, true, false, NULL, 'SELECT id, idval FROM cm.om_reviewclass WHERE active = true', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'active', 'lyt_data_1', 8, 'boolean', 'check', 'Active:', 'Active', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"vdefault_value":"True"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'organization_id', 'lyt_data_1', 9, 'string', 'combo', 'Organization:', 'Organization', NULL, false, false, true, false, NULL, 'SELECT organization_id as id, orgname as idval FROM cm.cat_organization WHERE active = true', NULL, NULL, NULL, NULL, NULL, NULL, '{
  "functionName": "update_expl_sector_combos",
  "module": "campaign"
}'::json, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'expl_id', 'lyt_data_1', 10, 'string', 'combo', 'Expl Id:', 'Expl Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'sector_id', 'lyt_data_1', 11, 'string', 'combo', 'Sector Id:', 'Sector Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'status', 'lyt_data_1', 13, 'string', 'combo', 'Status:', 'Status', NULL, false, false, true, false, NULL, 'SELECT id, idval FROM sys_typevalue WHERE typevalue=''campaign_status''', true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, ismandatory, isparent, iseditable, isautoupdate, hidden) VALUES ('campaign_review','form_feature','tab_data','workcat_id','lyt_data_1',14,'string','text','Workcat:','workcat',false,false,false,false,false);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_review', 'form_feature', 'tab_data', 'descript', 'lyt_data_1', 15, 'string', 'textarea', 'Description:', 'Description', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'campaign_id', 'lyt_data_1', 1, 'integer', 'text', 'Lot Id:', 'Id', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'name', 'lyt_data_1', 2, 'string', 'text', 'Name:', 'Name', NULL, true, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'startdate', 'lyt_data_1', 3, 'date', 'datetime', 'Planified start:', 'Planified start', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'enddate', 'lyt_data_1', 4, 'date', 'datetime', 'Planified end:', 'Planified end', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'real_startdate', 'lyt_data_1', 5, 'date', 'datetime', 'Real start:', 'Real start', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'real_enddate', 'lyt_data_1', 6, 'date', 'datetime', 'Real end:', 'Real end', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'visitclass_id', 'lyt_data_1', 7, 'string', 'combo', 'Visitclass:', 'Visitclass', NULL, false, false, true, false, NULL, 'SELECT id, idval FROM cm.om_visitclass WHERE active = true', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'active', 'lyt_data_1', 8, 'boolean', 'check', 'Active:', 'Active', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"vdefault_value":"True"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'organization_id', 'lyt_data_1', 9, 'string', 'combo', 'Organization:', 'Organization', NULL, false, false, true, false, NULL, 'SELECT organization_id as id, orgname as idval FROM cm.cat_organization WHERE active = true', NULL, NULL, NULL, NULL, NULL, NULL, '{
  "functionName": "update_expl_sector_combos",
  "module": "campaign"
}'::json, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'expl_id', 'lyt_data_1', 10, 'string', 'combo', 'Expl Id:', 'Expl Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'sector_id', 'lyt_data_1', 11, 'string', 'combo', 'Sector Id:', 'Sector Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'status', 'lyt_data_1', 13, 'string', 'combo', 'Status:', 'Status', NULL, false, false, true, false, NULL, 'SELECT id, idval FROM sys_typevalue WHERE typevalue=''campaign_status''', true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden) VALUES ('campaign_visit','form_feature','tab_data','workcat_id','lyt_data_1',14,'string','text','Workcat:','workcat',false,false,false,false,false);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_visit', 'form_feature', 'tab_data', 'descript', 'lyt_data_1', 15, 'string', 'textarea', 'Description:', 'Description', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

INSERT INTO config_param_user ("parameter", value, cur_user) VALUES('utils_formlabel_show_columname', 'false', 'postgres');
INSERT INTO config_param_user ("parameter", value, cur_user) VALUES('edit_municipality_vdefault', NULL, 'postgres');
INSERT INTO config_param_user ("parameter", value, cur_user) VALUES('utils_debug_mode', 'false', 'postgres');

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'lot_id', 'lyt_data_2', 1, 'string', 'text', 'Lot ID:', 'Id', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'name', 'lyt_data_2', 2, 'string', 'text', 'Name:', 'Name', NULL, true, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'startdate', 'lyt_data_2', 3, 'date', 'datetime', 'Planified start:', 'Planified start', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'enddate', 'lyt_data_2', 4, 'date', 'datetime', 'Planified end:', 'Planified end', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'real_startdate', 'lyt_data_2', 5, 'date', 'datetime', 'Real start:', 'Real start', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'real_enddate', 'lyt_data_2', 6, 'date', 'datetime', 'Real end:', 'Real end', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'campaign_id', 'lyt_data_2', 7, 'text', 'combo', 'Campaign id:', 'Campaign id', NULL, false, false, true, false, NULL, 'WITH isadmin AS (SELECT true AS val FROM pg_user u JOIN pg_auth_members m ON (m.member = u.usesysid) JOIN pg_roles r ON (r.oid = m.roleid)
WHERE u.usename = current_user AND r.rolname=''role_cm_admin'')
SELECT DISTINCT c.campaign_id AS id, c.name AS idval FROM cm.om_campaign c WHERE EXISTS (SELECT 1 FROM isadmin) and c.status > 2
union 
SELECT distinct c.campaign_id AS id, c.name AS idval FROM cm.om_campaign c
JOIN cm.cat_team t ON t.organization_id = c.organization_id JOIN cm.cat_user u ON u.team_id = t.team_id
WHERE c.active IS true  AND u.active IS TRUE AND u.username = current_user and c.status > 2', true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'workorder_id', 'lyt_data_2', 8, 'text', 'combo', 'Workorder id:', 'Workorder id', NULL, false, false, true, false, NULL, 'SELECT workorder_id as id, workorder_name as idval FROM workorder', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'active', 'lyt_data_2', 9, 'boolean', 'check', 'Active:', 'Active', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"vdefault_value":"True"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'organization_assigned', 'lyt_data_2', 10, 'string', 'text', 'Organization Assigned:', 'Organization Assigned', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'team_id', 'lyt_data_2', 11, 'string', 'combo', 'Team:', 'Team', NULL, false, false, true, false, NULL, 'SELECT DISTINCT(cat_team.team_id) as id, teamname as idval FROM cat_team WHERE active is TRUE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'expl_id', 'lyt_data_2', 12, 'string', 'combo', 'Expl Id:', 'Expl Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'sector_id', 'lyt_data_2', 13, 'string', 'combo', 'Sector Id:', 'Sector Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'status', 'lyt_data_2', 14, 'string', 'combo', 'Status:', 'Status', NULL, false, false, true, false, NULL, 'SELECT id, idval FROM sys_typevalue WHERE typevalue = ''lot_status''', true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('lot', 'form_feature', 'tab_data', 'descript', 'lyt_data_2', 15, 'string', 'textarea', 'Description:', 'Description', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'check_project_cm', 'tab_log', 'txt_infolog', 'lyt_log_1', 0, NULL, 'textarea', NULL, '', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'check_project_cm', 'tab_data', 'txt_info', 'lyt_data_1', 0, NULL, 'textarea', NULL, '', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "vdefault_value": "This text must be done in the config_form_fields widgetcontrols. ASK WHAT SHOULD GO."
}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'check_project_cm', 'tab_data', 'campaign', 'lyt_data_2', 0, 'text', 'combo', 'Campaign:', 'Campaign', NULL, true, true, true, false, NULL, 'WITH user_org AS ( 
	SELECT co.orgname, co.organization_id
	FROM cm.cat_user cu
	JOIN cm.cat_team ct ON ct.team_id = cu.team_id
	JOIN cm.cat_organization co ON co.organization_id = ct.organization_id
	WHERE cu.username = current_user
)
SELECT campaign_id AS id, name AS idval
FROM cm.om_campaign c
WHERE (
	EXISTS (SELECT 1 FROM user_org WHERE orgname = ''OWNER'') OR c.organization_id IN (SELECT organization_id FROM user_org)
)', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'check_project_cm', 'tab_data', 'lot', 'lyt_data_2', 1, 'text', 'combo', 'Lot:', 'Lot', NULL, false, false, true, false, NULL, 'Select lot_id as id, name as idval from om_campaign_lot WHERE lot_id IS NOT NULL', NULL, NULL, 'campaign_id', 'AND campaign_id', NULL, NULL, NULL, NULL, false, NULL);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'workorder_id', 'lyt_data_1', 1, 'string', 'text', 'Workorder Id:', 'Workorder Id', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'workorder_name', 'lyt_data_1', 2, 'string', 'text', 'Workorder name:', 'Workorder name', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'workorder_type', 'lyt_data_1', 3, 'string', 'combo', 'Workorder type:', 'Workorder type', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'workorder_class', 'lyt_data_1', 4, 'string', 'combo', 'Workorder class:', 'Workorder class', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'serie', 'lyt_data_1', 6, 'string', 'text', 'Serie:', 'Serie', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'exercise', 'lyt_data_1', 5, 'string', 'text', 'Exercise:', 'Exercise', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'startdate', 'lyt_data_1', 7, 'date', 'datetime', 'Startdate:', 'Startdate', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'address', 'lyt_data_1', 8, 'string', 'text', 'Address:', 'Address', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'observ', 'lyt_data_1', 9, 'string', 'text', 'Observ:', 'Observ', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('workorder', 'form_feature', 'tab_data', 'cost', 'lyt_data_1', 10, 'string', 'text', 'Cost:', 'Cost', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_camp_arc', 've_PARENT_SCHEMA_camp_arc', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '0', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_camp_connec', 've_PARENT_SCHEMA_camp_connec', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '0', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_camp_link', 've_PARENT_SCHEMA_camp_link', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '0', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_camp_node', 've_PARENT_SCHEMA_camp_node', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '0', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_lot_arc', 've_PARENT_SCHEMA_lot_arc', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '1', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_lot_connec', 've_PARENT_SCHEMA_lot_connec', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '1', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_lot_link', 've_PARENT_SCHEMA_lot_link', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '1', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO sys_table (id, descript, sys_role, project_template, context, orderby, alias, notify_action, isaudit, keepauditdays, "source", addparam) VALUES('ve_PARENT_SCHEMA_lot_node', 've_PARENT_SCHEMA_lot_node', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}'::jsonb, '1', NULL, NULL, NULL, NULL, NULL, NULL, NULL);

GRANT ALL PRIVILEGES ON DATABASE BD_NAME TO role_cm_field;
GRANT ALL PRIVILEGES ON DATABASE BD_NAME TO role_cm_manager;
GRANT ALL PRIVILEGES ON DATABASE BD_NAME TO role_cm_admin;
GRANT ALL PRIVILEGES ON DATABASE BD_NAME TO role_cm_edit;

GRANT SELECT ON ALL TABLES IN SCHEMA cm TO role_basic;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA cm TO role_basic;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA cm TO role_basic;

GRANT ALL ON SCHEMA cm TO role_cm_field;
GRANT ALL ON SCHEMA PARENT_SCHEMA TO role_cm_field;
GRANT ALL ON TABLE selector_lot TO role_cm_field;
GRANT ALL ON TABLE audit.cm_log TO role_cm_field;
GRANT ALL ON FUNCTION cm.gw_trg_ui_doc() TO role_cm_field;

GRANT ALL ON SCHEMA cm TO role_cm_manager;
GRANT ALL ON SCHEMA PARENT_SCHEMA TO role_cm_manager;
GRANT ALL ON SCHEMA cm TO role_cm_manager;
GRANT ALL ON ALL TABLES IN SCHEMA cm TO role_cm_manager;
GRANT ALL ON FUNCTION cm.gw_trg_ui_doc() TO role_cm_manager;

GRANT ALL ON SCHEMA cm TO role_cm_admin;
GRANT ALL ON SCHEMA PARENT_SCHEMA TO role_cm_admin;
GRANT ALL ON SCHEMA cm TO role_cm_admin;
GRANT ALL ON ALL TABLES IN SCHEMA cm TO role_cm_admin;

GRANT ALL ON SCHEMA cm TO role_cm_edit;
GRANT ALL ON SCHEMA PARENT_SCHEMA TO role_cm_edit;
GRANT ALL ON ALL TABLES IN SCHEMA cm TO role_cm_edit;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA cm TO role_cm_edit;
RESET ROLE;
GRANT role_edit TO role_cm_edit;
SET ROLE role_system;

UPDATE config_form_fields SET
widgetcontrols = '{"vdefault_value": 
"Esta función tiene por objetivo pasar el control de calidad de una campaña, pudiendo escoger de forma concreta un lote especifico.<br><br>Se analizan diferentes aspectos siendo lo más destacado que se configura para que los datos esten operativos en el conjunto de una campaña para que el modelo hidraulico funcione."}'
WHERE formtype ='check_project_cm' and columnname ='txt_info';


INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active) VALUES(100, 'Check nulls consistence', 'cm', NULL, 'core', true, 'Check cm', NULL, 3, 'null value on the column %check_column% of %table_name%', NULL, NULL, 'SELECT * FROM %table_name% WHERE %feature_column% = ANY(ARRAY[%feature_ids%]) AND %check_column% IS NULL ', 'The %check_column% on %table_name% have correct values.', '[gw_fct_cm_check_dynamic]', true);
INSERT INTO sys_fprocess
(fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active)
VALUES(102, 'Check repeated arcs on different lots', 'cm', NULL, 'core', false, 'Check project', NULL, 3, 'arcs repeated on different lots', NULL, NULL, 'SELECT lot_id, arc_id, count(*) FROM cm.om_campaign_lot_x_arc l GROUP BY lot_id, arc_id HAVING count(*) > 1', 'No arcs are repeated on different lots', '[gw_fct_cm_check_project]', true);
INSERT INTO sys_fprocess
(fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active)
VALUES(103, 'Check repeated nodes on different lots', 'cm', NULL, 'core', false, 'Check project', NULL, 2, 'nodes repeated on different lots', NULL, NULL, 'SELECT lot_id, node_id, count(*) FROM cm.om_campaign_lot_x_node l GROUP BY lot_id, node_id HAVING count(*) > 1', 'No nodes are repeated on different lots', '[gw_fct_cm_check_project]', true);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'campaign_id', 'lyt_data_1', 1, 'integer', 'text', 'Campaign Id:', 'Id', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'name', 'lyt_data_1', 2, 'string', 'text', 'Name:', 'Name', NULL, true, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'startdate', 'lyt_data_1', 3, 'date', 'datetime', 'Planified start:', 'Planified start', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'enddate', 'lyt_data_1', 4, 'date', 'datetime', 'Planified end:', 'Planified end', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'real_startdate', 'lyt_data_1', 5, 'date', 'datetime', 'Real start:', 'Real start', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'real_enddate', 'lyt_data_1', 6, 'date', 'datetime', 'Real end:', 'Real end', NULL, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'inventoryclass_id', 'lyt_data_1', 7, 'string', 'combo', 'Inventory Class:', 'Inventory Class', NULL, false, false, true, false, NULL, 'SELECT id as id, idval as idval FROM cm.om_inventoryclass WHERE active = true', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'active', 'lyt_data_1', 8, 'boolean', 'check', 'Active:', 'Active', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"vdefault_value":"True"}'::json, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'organization_id', 'lyt_data_1', 9, 'string', 'combo', 'Organization:', 'Organization', NULL, false, false, true, false, NULL, 'SELECT organization_id as id, orgname as idval FROM cm.cat_organization WHERE active = true', NULL, NULL, NULL, NULL, NULL, NULL, '{
  "functionName": "update_expl_sector_combos",
  "module": "campaign"
}'::json, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'expl_id', 'lyt_data_1', 10, 'string', 'combo', 'Expl Id:', 'Expl Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'sector_id', 'lyt_data_1', 11, 'string', 'combo', 'Sector Id:', 'Sector Id', NULL, false, false, true, false, NULL, 'Select '''' as id, '''' as idval', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'status', 'lyt_data_1', 13, 'string', 'combo', 'Status:', 'Status', NULL, false, false, true, false, NULL, 'SELECT id, idval FROM sys_typevalue WHERE typevalue=''campaign_status''', true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden) VALUES ('campaign_inventory','form_feature','tab_data','workcat_id','lyt_data_1',14,'string','text','Workcat:','workcat',false,false,false,false,false);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('campaign_inventory', 'form_feature', 'tab_data', 'descript', 'lyt_data_1', 15, 'string', 'textarea', 'Description:', 'Description', NULL, false, false, true, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL);

-- Form field configurations for team_create dialogs
-- These configurations enable dynamic dialog creation for team management

-- Create Team form configuration
INSERT INTO config_form_fields VALUES ('generic', 'team_create', 'tab_none', 'name', 'lyt_data_2', 1, 'text', 'text', 'Name:', NULL, NULL, true, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}', NULL, NULL, false) ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields VALUES ('generic', 'team_create', 'tab_none', 'code', 'lyt_data_2', 2, 'text', 'text', 'Code:', NULL, NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}', NULL, NULL, false) ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields VALUES ('generic', 'team_create', 'tab_none', 'descript', 'lyt_data_2', 3, 'text', 'textarea', 'Description:', NULL, NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":true}', NULL, NULL, false) ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
INSERT INTO config_form_fields VALUES ('generic', 'team_create', 'tab_none', 'active', 'lyt_data_2', 4, 'boolean', 'check', 'Active:', NULL, NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"setMultiline":false}', '{"vdefault_value":"true"}', NULL, false) ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

-- Fill config_form_tableview
DO $$
DECLARE
  v_location_type text;
  v_table text;
  v_column text;
  v_alias text;
  v_index int;
  v_tables text[][];
  i int;
BEGIN
  v_tables := ARRAY[['campaign_form', 'v_ui_campaign'], ['lot_form', 'v_ui_campaign_lot'], ['workorder_form', 'workorder'], ['resources_form', 'cat_organization'], ['resources_form', 'cat_team'], ['resources_form', 'cat_user'], ['campaign_relations', 'om_campaign_x_arc'], ['campaign_relations', 'om_campaign_x_node'], ['campaign_relations', 'om_campaign_x_connec'], ['campaign_relations', 'om_campaign_x_link'], ['campaign_relations', 'om_campaign_x_gully'], ['lot_relations', 'om_campaign_lot_x_arc'], ['lot_relations', 'om_campaign_lot_x_node'], ['lot_relations', 'om_campaign_lot_x_connec'], ['lot_relations', 'om_campaign_lot_x_link'], ['lot_relations', 'om_campaign_lot_x_gully']];
  
  FOR i IN 1..array_length(v_tables, 1) LOOP
    v_location_type := v_tables[i][1];
    v_table := v_tables[i][2];
    v_index := 1;
    
    FOR v_column IN SELECT column_name FROM information_schema.columns WHERE table_schema = 'cm' AND table_name = v_table LOOP
      v_alias := upper(left(v_column, 1)) || substr(v_column, 2);
      v_alias := replace(v_alias, '_', ' ');
      INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, style, addparam) 
      VALUES (v_location_type, 'cm', v_table, v_column, v_index, true, NULL, v_alias, NULL, NULL);
      v_index := v_index + 1;
    END LOOP;
  END LOOP;
END $$;

-- Rewrite some aliases
UPDATE config_form_tableview
	SET alias='End date'
	WHERE objectname='v_ui_campaign' AND columnname='enddate';
UPDATE config_form_tableview
	SET alias='End date'
	WHERE objectname='v_ui_campaign_lot' AND columnname='enddate';
UPDATE config_form_tableview
	SET alias='Real end date'
	WHERE objectname='v_ui_campaign' AND columnname='real_enddate';
UPDATE config_form_tableview
	SET alias='Real end date'
	WHERE objectname='v_ui_campaign_lot' AND columnname='real_enddate';
UPDATE config_form_tableview
	SET alias='Real start date'
	WHERE objectname='v_ui_campaign_lot' AND columnname='real_startdate';
UPDATE config_form_tableview
	SET alias='Real start date'
	WHERE objectname='v_ui_campaign' AND columnname='real_startdate';
UPDATE config_form_tableview
	SET alias='Team name'
	WHERE objectname='cat_team' AND columnname='teamname';
UPDATE config_form_tableview
	SET alias='User name'
	WHERE objectname='cat_user' AND columnname='username';
UPDATE config_form_tableview
	SET alias='Org. name'
	WHERE objectname='cat_organization' AND columnname='orgname';
UPDATE config_form_tableview
	SET alias='Start date'
	WHERE objectname='workorder' AND columnname='startdate';


-- Insert missing aliases
INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('resources_form','cm','cat_team','orgname',3,true,'Org. name');
INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('resources_form','cm','cat_user','code',2,true,'Code');
INSERT INTO config_form_tableview (location_type,project_type,objectname,columnname,columnindex,visible,alias)
	VALUES ('resources_form','cm','cat_user','teamname',3,true,'Team name');

-- Delete extra aliases
DELETE FROM config_form_tableview
	WHERE objectname='cat_organization' AND columnname='expl_id';
DELETE FROM config_form_tableview
	WHERE objectname='cat_organization' AND columnname='sector_id';
DELETE FROM config_form_tableview
	WHERE objectname='cat_team' AND columnname='organization_id';
DELETE FROM config_form_tableview
	WHERE objectname='cat_user' AND columnname='team_id';
DELETE FROM config_form_tableview
	WHERE objectname='cat_user' AND columnname='roles';

-- Reorder columnindex
UPDATE config_form_tableview
	SET columnindex=5
	WHERE objectname='cat_user' AND columnname='username';
UPDATE config_form_tableview
	SET columnindex=6
	WHERE objectname='cat_organization' AND columnname='active';
UPDATE config_form_tableview
	SET columnindex=4
	WHERE objectname='cat_team' AND columnname='orgname';
UPDATE config_form_tableview
	SET columnindex=3
	WHERE objectname='cat_user' AND columnname='code';
UPDATE config_form_tableview
	SET columnindex=4
	WHERE objectname='cat_user' AND columnname='active';

UPDATE config_form_tableview
	SET objectname='v_ui_lot'
	WHERE objectname='v_ui_campaign_lot';

INSERT INTO config_param_system ("parameter", value, descript, "label", dv_querytext, dv_filterbyfield, isenabled, layoutorder, project_type, dv_isparent, isautoupdate, "datatype", widgettype, ismandatory, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, widgetcontrols, placeholder, standardvalue, layoutname) 
VALUES('edit_campaign_lot_geom', '{"buffer_campaign":40, "buffer_lot":10}', 'Variable para configurar el buffer de campañas y lotes', 'Buffer de lotes y campañas', NULL, NULL, true, NULL, 'utils', NULL, NULL, 'json', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


INSERT INTO config_qindex_suspicious (param_name, threshold, weight, addparam, cur_user, tooltip) VALUES('om_state_mpicture', 0, 0.2, NULL, CURRENT_USER, NULL) ON CONFLICT DO NOTHING;
INSERT INTO config_qindex_suspicious (param_name, threshold, weight, addparam, cur_user, tooltip) VALUES('node_proximity', 0.1, 0.2, NULL, CURRENT_USER, 'Sus unidades son metros y expresa el valor máximo que consideramemos nodos cercanos. El valor mínimo es de sistema (0.1). Por debajo de esta medida se considera nodos duplicados. A más distancia menos qindex.') ON CONFLICT DO NOTHING;
INSERT INTO config_qindex_suspicious (param_name, threshold, weight, addparam, cur_user, tooltip) VALUES('arc_diam_jump', 50, 0.2, NULL, CURRENT_USER, 'Sus unidades son milimetros y expresa la diferencia los diametres de las dos tuberías que le llegan al nodo. A más diferencia más qindex') ON CONFLICT DO NOTHING;
INSERT INTO config_qindex_suspicious (param_name, threshold, weight, addparam, cur_user, tooltip) VALUES('valve_dn_wrong', 30, 0.2, NULL, CURRENT_USER, 'Sus unidades son milimetros y expresa la diferencia de los diametros de las tuberias que le llegan en comparación de la propia de la valvula. A más diferencia más qindex') ON CONFLICT DO NOTHING;
INSERT INTO config_qindex_suspicious (param_name, threshold, weight, addparam, cur_user, tooltip) VALUES('elev_inconsistency', 50, 0.2, NULL, CURRENT_USER, 'Se expresa en metros y el umbral expresa la diferencia entre la cota gps y la cota dem a partir de la cual es sospechoso. A más diferencia más qindex') ON CONFLICT DO NOTHING;

INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active) 
VALUES(104, 'Comprobar topología de nodarcos', 'cm', '{"replaceParams": {"table_name": "om_campaign_lot_x_node"}}'::json, 'core', false, 'Check project', NULL, 2, 'nodarcos con más de 2 tramos conectados', 'cm_{geom_type}', NULL, 
'WITH opts AS (
SELECT arc_id, node_1 AS node_id FROM cm.om_campaign_x_arc UNION
SELECT arc_id, node_2 AS node_id FROM cm.om_campaign_x_arc
)
SELECT a.node_id, b.campaign_id, c.lot_id, b.the_geom FROM opts a
LEFT JOIN cm.om_campaign_x_node b USING (node_id)
LEFT JOIN cm.om_campaign_lot_x_node c USING (node_id)
WHERE b.node_type IN (SELECT id FROM ap.cat_feature WHERE feature_class IN (''PUMP'', ''VALVE''))
GROUP BY a.node_id,  b.campaign_id, c.lot_id, b.the_geom, b.node_type HAVING count(*)>2', 
'No hay nodarcos con inconsistencia topológica', '[gw_fct_cm_check_project]', true)
ON CONFLICT DO NOTHING;


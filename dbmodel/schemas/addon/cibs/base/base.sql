/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "cibs", public, pg_catalog;

CREATE TABLE cibs.sys_version (
	id serial4 NOT NULL,
	giswater varchar(16) NOT NULL,
	project_type varchar(16) NOT NULL,
	postgres varchar(512) NOT NULL,
	postgis varchar(512) NOT NULL,
	"date" timestamp(6) DEFAULT now() NOT NULL,
	"language" varchar(50) NOT NULL,
	epsg int4 NOT NULL,
    addparam jsonb,
	CONSTRAINT sys_version_pkey PRIMARY KEY (id)
);

CREATE SEQUENCE cibs.cat_hydrometer_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE cibs.hydrometer_hydrometer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE cibs.hydrometer_period_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE cibs.cat_hydrometer (
    id character varying(16) NOT NULL,
    hydrometer_type character varying(100),
    madeby character varying(100),
    class character varying(100),
    ulmc character varying(100),
    type character varying(100),
    flownom character varying(100),
    dnom character varying(100),
    link character varying(512),
    url character varying(512),
    picture character varying(512),
    svg character varying(50),
    code text,
    observ text,
    CONSTRAINT cat_hydrometer_pkey PRIMARY KEY (id)
);

CREATE TABLE cibs.cat_hydrometer_priority (
    id integer NOT NULL,
    code text NOT NULL,
    observ character varying(100),
    CONSTRAINT cat_hydrometer_priority_pkey PRIMARY KEY (id)
);

CREATE TABLE cibs.cat_hydrometer_type (
    id integer NOT NULL,
    code text NOT NULL,
    observ character varying(100),
    CONSTRAINT cat_hydrometer_type_pkey PRIMARY KEY (id)
);

CREATE TABLE cibs.cat_hydrometer_category (
    id int4 NOT NULL,
    observ character varying(100),
    code text,
    pattern_id character varying(16),
    CONSTRAINT cat_hydrometer_category_pkey PRIMARY KEY (id)
);

CREATE TABLE cibs.cat_hydrometer_state (
    id integer NOT NULL DEFAULT nextval('cibs.cat_hydrometer_state_id_seq'::regclass),
    name text NOT NULL,
    observ text,
    is_operative boolean DEFAULT true,
    CONSTRAINT cat_hydrometer_state_pkey PRIMARY KEY (id)
);

CREATE TABLE cibs.hydrometer (
    hydrometer_id integer NOT NULL DEFAULT nextval('cibs.hydrometer_hydrometer_id_seq'::regclass),
    code text,
    hydro_customer_code text,
    id_number text,
    hydro_number text,
    feature_customer_code character varying(30),
    customer_name text,
    contract_id text,
    identif text,
    state_id smallint,
    expl_id integer,
    priority_id integer,
    catalog_id integer,
    category_id integer,
    crmzone_id integer,
    crmzone_order integer,
    wmeter_number text,
    wmeter_builtdate date,
    wmeter_instaldate date,
    plot_code character varying(100),
    muni_id integer,
    start_date date,
    update_date date,
    shutdown_date date,
    end_date date,
    address1_1 text,
    address1_2 text,
    address1_3 text,
    address2_1 text,
    address2_2 text,
    address2_3 text,
    assessed_volume double precision,
    is_waterbal boolean DEFAULT true,
    link text,
    wmeter_state text,
    wmeter_brand text,
	brand_id varchar(50) NULL,
	model_id varchar(50) NULL,
    CONSTRAINT hydrometer_pkey PRIMARY KEY (hydrometer_id),
    CONSTRAINT hydrometer_code_unique UNIQUE (code),
	CONSTRAINT hydrometer_cat_hydrometer_priority_fk FOREIGN KEY (priority_id) REFERENCES cat_hydrometer_priority(id),
	CONSTRAINT hydrometer_cat_hydrometer_state_fk FOREIGN KEY (state_id) REFERENCES cat_hydrometer_state(id)
);

CREATE TABLE cat_period_type (
	id serial4 NOT NULL,
	idval varchar(16) NOT NULL,
	descript text NULL,
	CONSTRAINT cat_period_type_pkey PRIMARY KEY (id)
);


CREATE TABLE cat_period (
	id varchar(16) NOT NULL,
	start_date timestamp(6) NULL,
	end_date timestamp(6) NULL,
	period_seconds int4 NULL,
	"comment" varchar(100) NULL,
	code text NULL,
	period_type int4 NULL,
	period_year int4 NULL,
	period_name varchar(16) NULL,
	expl_id _int4 NULL,
	CONSTRAINT cat_period_pkey PRIMARY KEY (id),
	CONSTRAINT cat_period_period_type_fkey FOREIGN KEY (period_type) REFERENCES cat_period_type(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cibs.hydrometer_period (
    id bigint NOT NULL DEFAULT nextval('cibs.hydrometer_period_id_seq'::regclass),
    hydrometer_id integer,
    wmeter_number text,
    cat_period_id character varying(16),
    billed_volume double precision,
    value_date date,
    value_type integer,
    value_status integer,
    value_state integer,
    fraud_type integer,
    fraud_status integer,
    fraud_probability numeric(12,2),
    submetering_value double precision,
    CONSTRAINT hydrometer_period_pkey PRIMARY KEY (id),
    CONSTRAINT hydrometer_period_hydrometer_id_cat_period_id_unique UNIQUE (hydrometer_id, cat_period_id),
	CONSTRAINT hydrometer_period_hydrometer_id_fkey FOREIGN KEY (hydrometer_id) REFERENCES hydrometer(hydrometer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT hydrometer_period_cat_period_id_fkey FOREIGN KEY (cat_period_id) REFERENCES cat_period(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

ALTER SEQUENCE cibs.cat_hydrometer_state_id_seq OWNED BY cibs.cat_hydrometer_state.id;
ALTER SEQUENCE cibs.hydrometer_hydrometer_id_seq OWNED BY cibs.hydrometer.hydrometer_id;
ALTER SEQUENCE cibs.hydrometer_period_id_seq OWNED BY cibs.hydrometer_period.id;

CREATE INDEX hydrometer_customer_code_idx ON cibs.hydrometer USING btree (feature_customer_code);
CREATE INDEX hydrometer_period_index_cat_period_id ON cibs.hydrometer_period USING btree (cat_period_id);
CREATE INDEX hydrometer_period_index_hydrometer_id ON cibs.hydrometer_period USING btree (hydrometer_id);

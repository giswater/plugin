/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

DROP VIEW IF EXISTS ve_rtc_hydro_data_x_connec;
DROP VIEW IF EXISTS v_ui_hydroval_x_connec;
DROP VIEW IF EXISTS v_ui_hydroval;
DROP VIEW IF EXISTS v_ui_hydrometer;
DROP VIEW IF EXISTS v_rtc_hydrometer_x_connec;
DROP VIEW IF EXISTS v_rtc_hydrometer_x_node;
DROP VIEW IF EXISTS v_rtc_hydrometer;
DROP VIEW IF EXISTS vf_hydrometer;
DROP VIEW IF EXISTS ve_hydrometer_period;
DROP VIEW IF EXISTS v_hydrometer_period;
DROP VIEW IF EXISTS v_hydrometer;
DROP VIEW IF EXISTS v_cat_hydrometer_state;
DROP VIEW IF EXISTS v_cat_hydrometer_category;
DROP VIEW IF EXISTS v_cat_hydrometer_priority;
DROP VIEW IF EXISTS v_cat_hydrometer_type;
DROP VIEW IF EXISTS v_cat_hydrometer_category_x_pattern;

ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_config_control;

INSERT INTO config_param_system VALUES ('admin_cibs_schema', 'FALSE', 'Variable to check if cibs schema exists', 'cibs schema:', NULL, NULL, true, 11, 'utils', NULL, NULL, 'boolean', 'check', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'lyt_system');

ALTER TABLE IF EXISTS ext_rtc_hydrometer_x_data DROP CONSTRAINT IF EXISTS ext_rtc_hydrometer_x_data_hydrometer_id_fkey;
ALTER TABLE IF EXISTS om_mincut_hydrometer DROP CONSTRAINT IF EXISTS om_mincut_hydrometer_hydrometer_id_fkey;

ALTER TABLE IF EXISTS ext_hydrometer_category RENAME TO ext_cat_hydrometer_category;

DO $$
BEGIN
    ALTER TABLE ext_cat_hydrometer_category ALTER COLUMN id TYPE integer USING id::integer;
EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE EXCEPTION 'All ids on ext_hydrometer_category table must be integers';
END $$;


ALTER TABLE IF EXISTS ext_rtc_hydrometer_state RENAME TO ext_cat_hydrometer_state;

ALTER SEQUENCE IF EXISTS ext_rtc_hydrometer_hydrometer_id_seq RENAME TO ext_hydrometer_hydrometer_id_seq;
ALTER SEQUENCE IF EXISTS ext_rtc_hydrometer_x_data_seq RENAME TO ext_hydrometer_period_id_seq;



CREATE TABLE ext_hydrometer (
    hydrometer_id integer NOT NULL DEFAULT nextval('SCHEMA_NAME.ext_hydrometer_hydrometer_id_seq'::regclass),
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
    wmeter_number integer,
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
    CONSTRAINT ext_hydrometer_pkey PRIMARY KEY (hydrometer_id),
	CONSTRAINT ext_hydrometer_cat_hydrometer_priority_fk FOREIGN KEY (priority_id) REFERENCES ext_cat_hydrometer_priority(id),
	CONSTRAINT ext_hydrometer_cat_hydrometer_state_fk FOREIGN KEY (state_id) REFERENCES ext_cat_hydrometer_state(id)
);


INSERT INTO ext_hydrometer (hydrometer_id, code, hydro_customer_code, id_number, hydro_number, feature_customer_code, customer_name, contract_id, identif, state_id, expl_id, priority_id, catalog_id,
category_id, crmzone_id, crmzone_order, wmeter_number, wmeter_builtdate, wmeter_instaldate, plot_code, muni_id, start_date, update_date, shutdown_date, end_date,
address1_1, address1_2, address1_3, address2_1, address2_2, address2_3, assessed_volume, is_waterbal, link)
SELECT hydrometer_id, code, hydrometer_customer_code, id_number, hydro_number, customer_code, customer_name, NULL, identif, state_id, expl_id, priority_id, catalog_id, category_id, NULL, NULL,
crm_number, hydro_man_date, NULL, plot_code, muni_id, start_date, update_date, shutdown_date, end_date, address1, address2, address3, address2_1, address2_2,
address2_3, m3_volume, NULL, link
FROM ext_rtc_hydrometer;

ALTER TABLE IF EXISTS ext_rtc_hydrometer RENAME TO _ext_rtc_hydrometer;


UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_rtc_hydrometer', 'v_hydrometer') WHERE dv_querytext ILIKE '% ext_rtc_hydrometer %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_hydrometer_state', 'v_cat_hydrometer_state') WHERE dv_querytext ILIKE '% ext_hydrometer_state %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_hydrometer_category', 'v_cat_hydrometer_category') WHERE dv_querytext ILIKE '% ext_hydrometer_category %';

UPDATE config_form_fields SET columnname = 'hydro_customer_code' WHERE columnname = 'hydrometer_customer_code';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, '"hydrometer_customer_code"', '"hydro_customer_code"')::json WHERE widgetfunction::text ILIKE '%hydrometer_customer_code%';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, '"hydrometer_customer_code"', '"hydro_customer_code"')::json WHERE widgetcontrols::text ILIKE '%hydrometer_customer_code%';

UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'v_rtc_hydrometer', 'vf_hydrometer') WHERE query_text ILIKE '% v_rtc_hydrometer %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_cat_period_type', 'v_cat_period_type') WHERE query_text ILIKE '% ext_cat_period_type %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_cat_period', 'v_cat_period') WHERE query_text ILIKE '% ext_cat_period %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_cat_hydrometer', 'v_cat_hydrometer') WHERE query_text ILIKE '% ext_cat_hydrometer %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_cat_hydrometer_type', 'v_cat_hydrometer_type') WHERE query_text ILIKE '% ext_cat_hydrometer_type %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_hydrometer_category', 'v_cat_hydrometer_category') WHERE query_text ILIKE '% ext_hydrometer_category %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_cat_hydrometer_priority', 'v_cat_hydrometer_priority') WHERE query_text ILIKE '% ext_cat_hydrometer_priority %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_rtc_hydrometer_state', 'v_cat_hydrometer_state') WHERE query_text ILIKE '% ext_rtc_hydrometer_state %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_rtc_hydrometer', 'v_hydrometer') WHERE query_text ILIKE '% ext_rtc_hydrometer %';
UPDATE sys_fprocess SET query_text = REPLACE(query_text, 'ext_rtc_hydrometer_data', 'v_hydrometer_period') WHERE query_text ILIKE '% ext_rtc_hydrometer_data %';

UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_cat_period_type', 'v_cat_period_type') WHERE dv_querytext ILIKE '% ext_cat_period_type %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_cat_period', 'v_cat_period') WHERE dv_querytext ILIKE '% ext_cat_period %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_cat_hydrometer', 'v_cat_hydrometer') WHERE dv_querytext ILIKE '% ext_cat_hydrometer %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_cat_hydrometer_type', 'v_cat_hydrometer_type') WHERE dv_querytext ILIKE '% ext_cat_hydrometer_type %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_hydrometer_category', 'v_cat_hydrometer_category') WHERE dv_querytext ILIKE '% ext_hydrometer_category %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_cat_hydrometer_priority', 'v_cat_hydrometer_priority') WHERE dv_querytext ILIKE '% ext_cat_hydrometer_priority %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_rtc_hydrometer_state', 'v_cat_hydrometer_state') WHERE dv_querytext ILIKE '% ext_rtc_hydrometer_state %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_rtc_hydrometer', 'v_hydrometer') WHERE dv_querytext ILIKE '% ext_rtc_hydrometer %';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'ext_rtc_hydrometer_data', 'v_hydrometer_period') WHERE dv_querytext ILIKE '% ext_rtc_hydrometer_data %';

UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_cat_period_type', 'v_cat_period_type')::json WHERE widgetfunction::text ILIKE '% ext_cat_period_type %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_cat_period', 'v_cat_period')::json WHERE widgetfunction::text ILIKE '% ext_cat_period %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_cat_hydrometer', 'v_cat_hydrometer')::json WHERE widgetfunction::text ILIKE '% ext_cat_hydrometer %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_cat_hydrometer_type', 'v_cat_hydrometer_type')::json WHERE widgetfunction::text ILIKE '% ext_cat_hydrometer_type %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_hydrometer_category', 'v_cat_hydrometer_category')::json WHERE widgetfunction::text ILIKE '% ext_hydrometer_category %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_cat_hydrometer_priority', 'v_cat_hydrometer_priority')::json WHERE widgetfunction::text ILIKE '% ext_cat_hydrometer_priority %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_rtc_hydrometer_state', 'v_cat_hydrometer_state')::json WHERE widgetfunction::text ILIKE '% ext_rtc_hydrometer_state %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_rtc_hydrometer', 'v_hydrometer')::json WHERE widgetfunction::text ILIKE '% ext_rtc_hydrometer %';
UPDATE config_form_fields SET widgetfunction = REPLACE(widgetfunction::text, 'ext_rtc_hydrometer_data', 'v_hydrometer_period')::json WHERE widgetfunction::text ILIKE '% ext_rtc_hydrometer_data %';

UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_cat_period_type', 'v_cat_period_type')::json WHERE widgetcontrols::text ILIKE '% ext_cat_period_type %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_cat_period', 'v_cat_period')::json WHERE widgetcontrols::text ILIKE '% ext_cat_period %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_cat_hydrometer', 'v_cat_hydrometer')::json WHERE widgetcontrols::text ILIKE '% ext_cat_hydrometer %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_cat_hydrometer_type', 'v_cat_hydrometer_type')::json WHERE widgetcontrols::text ILIKE '% ext_cat_hydrometer_type %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_hydrometer_category', 'v_cat_hydrometer_category')::json WHERE widgetcontrols::text ILIKE '% ext_hydrometer_category %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_cat_hydrometer_priority', 'v_cat_hydrometer_priority')::json WHERE widgetcontrols::text ILIKE '% ext_cat_hydrometer_priority %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_rtc_hydrometer_state', 'v_cat_hydrometer_state')::json WHERE widgetcontrols::text ILIKE '% ext_rtc_hydrometer_state %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_rtc_hydrometer', 'v_hydrometer')::json WHERE widgetcontrols::text ILIKE '% ext_rtc_hydrometer %';
UPDATE config_form_fields SET widgetcontrols = REPLACE(widgetcontrols::text, 'ext_rtc_hydrometer_data', 'v_hydrometer_period')::json WHERE widgetcontrols::text ILIKE '% ext_rtc_hydrometer_data %';

CREATE TABLE ext_hydrometer_period (
    id bigint NOT NULL DEFAULT nextval('SCHEMA_NAME.ext_hydrometer_period_id_seq'::regclass),
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
    CONSTRAINT ext_hydrometer_period_pkey PRIMARY KEY (id),
    CONSTRAINT ext_hydrometer_period_hydrometer_id_cat_period_id_unique UNIQUE (hydrometer_id, cat_period_id),
    CONSTRAINT cat_period_id_fkey FOREIGN KEY (cat_period_id) REFERENCES ext_cat_period(id) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT ext_hydrometer_period_hydrometer_id_fkey FOREIGN KEY (hydrometer_id) REFERENCES ext_hydrometer(hydrometer_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


INSERT INTO ext_hydrometer_period (id, hydrometer_id, wmeter_number, cat_period_id, billed_volume, value_date, value_type, value_status, value_state, fraud_type, fraud_status,
fraud_probability, submetering_value)
SELECT id, hydrometer_id, crm_number, cat_period_id, sum, value_date, value_type, value_status, value_state, NULL, NULL, NULL, NULL
FROM ext_rtc_hydrometer_x_data;

ALTER TABLE IF EXISTS ext_rtc_hydrometer_x_data RENAME TO _ext_rtc_hydrometer_x_data;

ALTER TABLE IF EXISTS ext_rtc_dma_period RENAME TO _ext_rtc_dma_period;
ALTER TABLE IF EXISTS ext_hydrometer_category_x_pattern RENAME TO _ext_hydrometer_category_x_pattern;


DELETE FROM sys_table WHERE id IN
('v_rtc_hydrometer', 'v_rtc_hydrometer_x_connec', 'v_rtc_hydrometer_x_node', 'v_ui_hydroval', 'v_ui_hydroval_x_connec', 'v_ui_hydrometer', 've_rtc_hydro_data_x_connec',
'ext_rtc_hydrometer', 'ext_rtc_hydrometer_x_data', 'ext_rtc_hydrometer_state', 'ext_hydrometer_category', 'ext_hydrometer_category_x_pattern');

INSERT INTO sys_table (id, descript, sys_role, source)
VALUES
    ('ext_hydrometer', 'Hydrometer table.', 'role_basic', 'core'),
    ('ext_hydrometer_period', 'Hydrometer data table.', 'role_basic', 'core'),
    ('ext_cat_hydrometer_state', 'Hydrometer state catalog table.', 'role_basic', 'core'),
    ('ext_cat_hydrometer_category', 'Hydrometer category catalog table.', 'role_basic', 'core'),
    ('ext_cat_hydrometer_priority', 'Hydrometer priority catalog table.', 'role_basic', 'core'),
    ('ext_cat_hydrometer_type', 'Hydrometer type catalog table.', 'role_basic', 'core'),
    ('vf_hydrometer', 'Hydrometers filtered by exploitation selector.', 'role_basic', 'core'),
    ('ve_hydrometer_period', 'Editable hydrometer period data without connec join.', 'role_basic', 'core'),
    ('v_hydrometer', 'Hydrometer base view.', 'role_basic', 'core'),
    ('v_hydrometer_period', 'Hydrometer period data base view.', 'role_basic', 'core'),
    ('v_cat_hydrometer', 'Hydrometer catalog base view.', 'role_basic', 'core'),
    ('v_cat_hydrometer_state', 'Hydrometer state base view.', 'role_basic', 'core'),
    ('v_cat_hydrometer_category', 'Hydrometer category base view.', 'role_basic', 'core'),
    ('v_cat_hydrometer_priority', 'Hydrometer priority base view.', 'role_basic', 'core'),
    ('v_cat_hydrometer_type', 'Hydrometer type base view.', 'role_basic', 'core'),
    ('v_cat_period', 'Period catalog base view.', 'role_basic', 'core'),
    ('v_cat_period_type', 'Period type catalog base view.', 'role_basic', 'core')
ON CONFLICT (id) DO UPDATE SET descript = EXCLUDED.descript;

ALTER TABLE ext_hydrometer ADD CONSTRAINT ext_hydrometer_ext_cat_hydrometer_state_fk FOREIGN KEY (state_id) REFERENCES ext_cat_hydrometer_state(id);
ALTER TABLE ext_hydrometer ADD CONSTRAINT ext_hydrometer_ext_cat_hydrometer_priority_fk FOREIGN KEY (priority_id) REFERENCES ext_cat_hydrometer_priority(id);

ALTER TABLE IF EXISTS sys_version ADD COLUMN IF NOT EXISTS addparam jsonb;

-- Add column is_twin
ALTER TABLE rpt_cat_result ADD COLUMN IF NOT EXISTS is_twin boolean DEFAULT false;

ALTER TABLE rpt_cat_result ADD COLUMN IF NOT EXISTS parent_id varchar(16);

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = publi, public;

CREATE TABLE IF NOT EXISTS config_publi_table (
	id serial4 NOT NULL,
	source_schema text NOT NULL,
	source_relation text NOT NULL,
	source_sql text NULL,
	source_formname text NULL,
	target_name text NOT NULL,
	object_type text NOT NULL,
	pk_columns text[] NOT NULL,
	alias_custom text NULL,
	selector_config jsonb NULL,
	where_clause text NULL,
	decode_columns bool NOT NULL DEFAULT true,
	rls_mode text NOT NULL DEFAULT 'expl',
	rls_column text NULL,
	sync_frequency text NOT NULL DEFAULT 'daily',
	orderby int4 NULL,
	active bool NOT NULL DEFAULT true,
	CONSTRAINT config_publi_table_pkey PRIMARY KEY (id),
	CONSTRAINT config_publi_table_target_name_unique UNIQUE (target_name),
	CONSTRAINT config_publi_table_object_type_check CHECK (object_type IN ('parent', 'child', 'epa', 'mapzone', 'catalog', 'doc', 'result', 'other')),
	CONSTRAINT config_publi_table_rls_mode_check CHECK (rls_mode IN ('expl', 'sector', 'none')),
	CONSTRAINT config_publi_table_sync_frequency_check CHECK (sync_frequency IN ('daily', 'frequent')),
	CONSTRAINT config_publi_table_pk_columns_check CHECK (cardinality(pk_columns) > 0)
);

CREATE TABLE IF NOT EXISTS sys_metadata (
	target_name text NOT NULL,
	column_name text NOT NULL DEFAULT '',
	alias text NULL,
	description text NULL,
	"source" text NULL,
	CONSTRAINT sys_metadata_pkey PRIMARY KEY (target_name, column_name)
);

CREATE TABLE IF NOT EXISTS sys_domain (
	target_name text NOT NULL,
	column_name text NOT NULL,
	id text NOT NULL,
	idval text NULL,
	CONSTRAINT sys_domain_pkey PRIMARY KEY (target_name, column_name, id)
);

CREATE TABLE IF NOT EXISTS sync_log (
	id bigserial NOT NULL,
	target_name text NULL,
	"mode" text NULL,
	rows_inserted int4 NULL,
	rows_updated int4 NULL,
	rows_deleted int4 NULL,
	structure_changed bool NULL,
	details jsonb NULL,
	tstamp_start timestamp NOT NULL DEFAULT now(),
	tstamp_end timestamp NULL,
	error text NULL,
	CONSTRAINT sync_log_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS sync_log_target_tstamp_idx ON sync_log (target_name, tstamp_start DESC);

DO $role$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_addon_publi_read') THEN
		CREATE ROLE role_addon_publi_read NOLOGIN;
	END IF;
	EXECUTE 'GRANT USAGE ON SCHEMA publi TO role_addon_publi_read';
EXCEPTION WHEN insufficient_privilege THEN
	RAISE WARNING 'role_addon_publi_read not created (insufficient privilege); create it manually and grant USAGE on schema publi';
END
$role$;

COMMENT ON TABLE config_materialized_views IS 'DEPRECATED: replaced by config_publi_table';
COMMENT ON FUNCTION gw_fct_refresh_materialized_views() IS 'DEPRECATED: replaced by gw_fct_publi_sync';

-- views read current_user(); the publication must not inherit the QGIS login's selectors
ALTER FUNCTION gw_fct_publi_sync(json) OWNER TO role_system;
ALTER FUNCTION gw_fct_publi_sync(json) SECURITY DEFINER;
ALTER FUNCTION gw_fct_publi_sync(json) SET search_path = publi, public;
REVOKE ALL ON FUNCTION gw_fct_publi_sync(json) FROM PUBLIC;
DO $grant$
BEGIN
	IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_admin') THEN
		GRANT EXECUTE ON FUNCTION gw_fct_publi_sync(json) TO role_admin;
	END IF;
	GRANT EXECUTE ON FUNCTION gw_fct_publi_sync(json) TO role_system;
END
$grant$;

INSERT INTO config_process (function_name, description, selector_config, active)
VALUES ('gw_fct_publi_sync', 'Synchronize publi tables from their Giswater sources', NULL, true)
ON CONFLICT (function_name) DO NOTHING;

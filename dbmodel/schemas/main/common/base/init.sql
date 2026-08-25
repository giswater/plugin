/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

RESET ROLE;

--
-- TOC entry 10 (class 2615 OID 151924)
-- Name: SCHEMA_NAME; Type: SCHEMA; Schema: -; Owner: -
--

-- The postgis extension is checked when connection is stablished. In case of does not exists, it tries to create. In case of failure, message is reported

DO $$
DECLARE
	v_is_super boolean;
	v_role_exists boolean;
	v_rolename text;
BEGIN
	v_is_super := COALESCE((SELECT rolsuper FROM pg_roles WHERE rolname = current_user), FALSE);

	IF v_is_super THEN
		EXECUTE 'CREATE EXTENSION IF NOT EXISTS tablefunc';
		EXECUTE 'CREATE EXTENSION IF NOT EXISTS pgrouting';
		EXECUTE 'CREATE EXTENSION IF NOT EXISTS unaccent';
	ELSIF NOT (
		EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'tablefunc')
		AND EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgrouting')
		AND EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'unaccent')
	) THEN
		RAISE EXCEPTION 'Required extensions missing; run gw db init as a superuser';
	END IF;

	-- Create roles if missing; (re)apply hierarchy grants when privileged
	FOREACH v_rolename IN ARRAY ARRAY[
		'role_basic', 'role_om', 'role_edit', 'role_epa',
		'role_plan', 'role_admin', 'role_system', 'role_crm'
	]
	LOOP
		SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = v_rolename) INTO v_role_exists;
		IF NOT v_role_exists THEN
			IF v_is_super THEN
				EXECUTE format(
					'CREATE ROLE %I NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION',
					v_rolename
				);
			ELSE
				RAISE EXCEPTION
					'Giswater role % does not exist; run gw db init as a superuser',
					v_rolename;
			END IF;
		END IF;
	END LOOP;

	BEGIN
		GRANT role_basic TO role_om;
		GRANT role_om TO role_edit;
		GRANT role_edit TO role_epa;
		GRANT role_epa TO role_plan;
		GRANT role_plan TO role_admin;
		GRANT role_admin TO role_system;
	EXCEPTION WHEN insufficient_privilege THEN
		NULL;
	END;

	-- Assign role_system to current superuser installer
	IF v_is_super
		AND NOT pg_has_role(current_user, 'role_system', 'member') THEN
		EXECUTE 'GRANT role_system TO ' || quote_ident(current_user);
	END IF;

	-- Schema create needs CREATE ON DATABASE; CONNECT for role_basic is bootstrap-only
	IF v_is_super THEN
		EXECUTE format('GRANT CREATE ON DATABASE %I TO role_system', current_database());
		EXECUTE format(
			'GRANT CONNECT, TEMPORARY ON DATABASE %I TO role_basic',
			current_database()
		);
	END IF;
END$$;

-- Schema must be created by a role with CREATE ON DATABASE (installer or role_system).
CREATE SCHEMA "SCHEMA_NAME" AUTHORIZATION role_system;


SET ROLE role_system;

ALTER DEFAULT PRIVILEGES IN SCHEMA SCHEMA_NAME GRANT SELECT ON TABLES TO role_basic;

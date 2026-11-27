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

DO $$
DECLARE
  v_rolename text;
BEGIN
  FOREACH v_rolename IN ARRAY ARRAY['role_cm', 'role_audit']
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_rolename) THEN
      IF EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = current_user AND (rolsuper OR rolcreaterole)
      ) THEN
        EXECUTE format(
          'CREATE ROLE %I NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION',
          v_rolename
        );
      ELSE
        RAISE EXCEPTION
          'role % does not exist and % cannot CREATE ROLE. Run "gw db init" as a superuser first.',
          v_rolename, current_user;
      END IF;
    END IF;

    IF NOT pg_has_role('role_system', v_rolename, 'member') THEN
      EXECUTE format('GRANT %I TO role_system', v_rolename);
    END IF;
  END LOOP;
END
$$;

-- Schemas must be created by the installer (needs CREATE on database).
CREATE SCHEMA IF NOT EXISTS cm AUTHORIZATION role_system;
CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION role_system;

SET ROLE role_system;

GRANT ALL ON SCHEMA cm TO role_system;
GRANT ALL ON SCHEMA cm TO role_basic;
GRANT ALL ON SCHEMA cm TO role_cm;
ALTER DEFAULT PRIVILEGES IN SCHEMA cm GRANT SELECT ON TABLES TO role_basic;

GRANT ALL ON SCHEMA audit TO role_system;
GRANT ALL ON SCHEMA audit TO role_basic;
GRANT ALL ON SCHEMA audit TO role_audit;

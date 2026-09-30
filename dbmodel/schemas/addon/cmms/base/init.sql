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

-- role_cmms is the writer for the external CMMS backend. Creation needs
-- CREATEROLE; gw db init creates it first so a role_system member can build.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_cmms') THEN
    IF EXISTS (
      SELECT 1 FROM pg_roles
      WHERE rolname = current_user AND (rolsuper OR rolcreaterole)
    ) THEN
      CREATE ROLE role_cmms NOLOGIN NOINHERIT;
    ELSE
      RAISE EXCEPTION
        'role_cmms does not exist and % cannot CREATE ROLE. Run "gw db init" as a superuser first.',
        current_user;
    END IF;
  END IF;

  IF NOT pg_has_role('role_cmms', 'role_basic', 'MEMBER') THEN
    BEGIN
      GRANT role_basic TO role_cmms;
    EXCEPTION
      WHEN insufficient_privilege THEN
        RAISE NOTICE 'could not GRANT role_basic TO role_cmms as %', current_user;
    END;
  END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS cmms AUTHORIZATION role_system;

SET ROLE role_system;

GRANT ALL ON SCHEMA cmms TO role_system;
GRANT ALL ON SCHEMA cmms TO role_basic;
GRANT USAGE ON SCHEMA cmms TO role_cmms;
ALTER DEFAULT PRIVILEGES IN SCHEMA cmms GRANT SELECT ON TABLES TO role_basic;
ALTER DEFAULT PRIVILEGES IN SCHEMA cmms GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_cmms;
ALTER DEFAULT PRIVILEGES IN SCHEMA cmms GRANT USAGE, SELECT ON SEQUENCES TO role_cmms;
ALTER DEFAULT PRIVILEGES IN SCHEMA cmms GRANT EXECUTE ON FUNCTIONS TO role_cmms;

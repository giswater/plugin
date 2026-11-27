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
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_multilang') THEN
    IF EXISTS (
      SELECT 1 FROM pg_roles
      WHERE rolname = current_user AND (rolsuper OR rolcreaterole)
    ) THEN
      CREATE ROLE role_multilang NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    ELSE
      RAISE EXCEPTION
        'role_multilang does not exist and % cannot CREATE ROLE. Run "gw db init" as a superuser first.',
        current_user;
    END IF;
  END IF;

  IF NOT pg_has_role('role_system', 'role_multilang', 'member') THEN
    GRANT role_multilang TO role_system;
  END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS multilang AUTHORIZATION role_system;

SET ROLE role_system;

GRANT ALL ON SCHEMA multilang TO role_system;
GRANT ALL ON SCHEMA multilang TO role_basic;
GRANT ALL ON SCHEMA multilang TO role_multilang;
ALTER DEFAULT PRIVILEGES IN SCHEMA multilang GRANT SELECT ON TABLES TO role_basic;

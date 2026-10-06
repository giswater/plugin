/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Objects created by a non-superuser installer after RESET ROLE are not
-- covered by role_system default privileges. Grant + reassign.
DO $priv$
DECLARE
  r record;
  sch text := 'SCHEMA_NAME';
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_basic') THEN
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO role_basic', sch);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO role_basic', sch);
    EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA %I TO role_basic', sch);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_system') THEN
    RETURN;
  END IF;
  FOR r IN
    SELECT c.relname, c.relkind
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_roles o ON o.oid = c.relowner
    WHERE n.nspname = sch
      AND c.relkind IN ('r', 'p', 'v', 'm', 'S')
      AND o.rolname IS DISTINCT FROM 'role_system'
  LOOP
    IF r.relkind = 'S' THEN
      EXECUTE format('ALTER SEQUENCE %I.%I OWNER TO role_system', sch, r.relname);
    ELSIF r.relkind = 'v' THEN
      EXECUTE format('ALTER VIEW %I.%I OWNER TO role_system', sch, r.relname);
    ELSIF r.relkind = 'm' THEN
      EXECUTE format('ALTER MATERIALIZED VIEW %I.%I OWNER TO role_system', sch, r.relname);
    ELSE
      EXECUTE format('ALTER TABLE %I.%I OWNER TO role_system', sch, r.relname);
    END IF;
  END LOOP;
  FOR r IN
    SELECT p.oid::regprocedure::text AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_roles o ON o.oid = p.proowner
    WHERE n.nspname = sch
      AND o.rolname IS DISTINCT FROM 'role_system'
  LOOP
    EXECUTE format('ALTER FUNCTION %s OWNER TO role_system', r.sig);
  END LOOP;
END
$priv$;

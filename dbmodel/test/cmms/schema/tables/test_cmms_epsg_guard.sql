/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT * FROM no_plan();

CREATE SCHEMA cmms_epsg_parent;

CREATE TABLE cmms_epsg_parent.sys_version (
    id serial PRIMARY KEY,
    giswater varchar(16) NOT NULL,
    project_type varchar(16) NOT NULL,
    postgres varchar(512) NOT NULL,
    postgis varchar(512) NOT NULL,
    "date" timestamp DEFAULT now() NOT NULL,
    "language" varchar(50) NOT NULL,
    epsg int4 NOT NULL,
    addparam jsonb
);

INSERT INTO cmms_epsg_parent.sys_version (giswater, project_type, postgres, postgis, language, epsg)
VALUES ('4.18.0', 'WS', version(), postgis_version(), 'en_US', 999999);

SELECT throws_ok(
    $fn$
      DO $cmms_epsg$
      DECLARE
        v_parent integer;
        v_cmms integer;
      BEGIN
        SELECT epsg INTO v_parent FROM cmms_epsg_parent.sys_version ORDER BY id DESC LIMIT 1;
        SELECT epsg INTO v_cmms FROM cmms.sys_version ORDER BY id DESC LIMIT 1;
        IF v_parent IS DISTINCT FROM v_cmms THEN
          RAISE EXCEPTION 'cmms EPSG % does not match parent schema % EPSG %',
            v_cmms, 'cmms_epsg_parent', v_parent;
        END IF;
      END
      $cmms_epsg$;
    $fn$,
    'P0001'::char(5),
    NULL,
    'integrate rejects a parent EPSG that differs from cmms'
);

UPDATE cmms_epsg_parent.sys_version
SET epsg = (SELECT epsg FROM cmms.sys_version ORDER BY id DESC LIMIT 1);

SELECT lives_ok(
    $fn$
      DO $cmms_epsg$
      DECLARE
        v_parent integer;
        v_cmms integer;
      BEGIN
        SELECT epsg INTO v_parent FROM cmms_epsg_parent.sys_version ORDER BY id DESC LIMIT 1;
        SELECT epsg INTO v_cmms FROM cmms.sys_version ORDER BY id DESC LIMIT 1;
        IF v_parent IS DISTINCT FROM v_cmms THEN
          RAISE EXCEPTION 'cmms EPSG % does not match parent schema % EPSG %',
            v_cmms, 'cmms_epsg_parent', v_parent;
        END IF;
      END
      $cmms_epsg$;
    $fn$,
    'integrate accepts a parent with the same EPSG'
);

SELECT * FROM finish();

ROLLBACK;

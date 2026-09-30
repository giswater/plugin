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

SELECT ok(
    EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_cmms'),
    'role_cmms exists'
);

SELECT is(
    (SELECT rolcanlogin FROM pg_roles WHERE rolname = 'role_cmms'),
    false,
    'role_cmms is NOLOGIN'
);

SELECT is(
    (SELECT rolinherit FROM pg_roles WHERE rolname = 'role_cmms'),
    false,
    'role_cmms is NOINHERIT'
);

SELECT ok(
    pg_has_role('role_cmms', 'role_basic', 'MEMBER'),
    'role_cmms is a member of role_basic'
);

SELECT ok(
    (
        SELECT bool_and(pg_get_userbyid(c.relowner) = 'role_system')
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'SCHEMA_NAME'
          AND c.relkind IN ('r', 'p', 'S')
    ),
    'cmms relations and sequences are owned by role_system'
);

SELECT ok(
    (
        SELECT bool_and(pg_get_userbyid(p.proowner) = 'role_system')
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'SCHEMA_NAME'
    ),
    'cmms functions are owned by role_system'
);

SET ROLE role_cmms;

SELECT lives_ok(
    $$INSERT INTO visit (type, status) VALUES ('inspection', 'open')$$,
    'role_cmms can insert visit'
);

SELECT lives_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-1', 1, 'NODE', 'ws_demo')$$,
    'role_cmms can insert asset_feature_map (uses the sequence)'
);

SELECT lives_ok(
    $$UPDATE visit SET status = 'done' WHERE type = 'inspection'$$,
    'role_cmms can update visit'
);

SELECT lives_ok(
    $$DELETE FROM asset_feature_map WHERE ext_feature_id = 'ext-1'$$,
    'role_cmms can delete asset_feature_map'
);

SELECT throws_ok(
    $fn$CREATE TABLE SCHEMA_NAME.role_cmms_should_fail (id int)$fn$,
    '42501'::char(5),
    'permission denied for schema SCHEMA_NAME',
    'role_cmms cannot create tables'
);

RESET ROLE;

SELECT * FROM finish();

ROLLBACK;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(25);

-- role_<schema> is created by init.sql and granted to role_system only.
SELECT ok(
    EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_SCHEMA_NAME'),
    'role_SCHEMA_NAME exists'
);
SELECT is(
    (SELECT rolcanlogin FROM pg_roles WHERE rolname = 'role_SCHEMA_NAME'),
    false,
    'role_SCHEMA_NAME is NOLOGIN'
);
SELECT is(
    (SELECT rolsuper FROM pg_roles WHERE rolname = 'role_SCHEMA_NAME'),
    false,
    'role_SCHEMA_NAME is not a superuser'
);
SELECT ok(
    pg_has_role('role_system', 'role_SCHEMA_NAME', 'member'),
    'role_system is a member of role_SCHEMA_NAME'
);
SELECT ok(
    NOT pg_has_role('role_basic', 'role_SCHEMA_NAME', 'member'),
    'role_basic is not a member of role_SCHEMA_NAME'
);
SELECT ok(
    NOT pg_has_role('role_admin', 'role_SCHEMA_NAME', 'member'),
    'role_admin is not a member of role_SCHEMA_NAME'
);

-- Logins with no superuser bit. ROLLBACK drops them.
CREATE USER gw_nonsuper_basic;
GRANT role_basic TO gw_nonsuper_basic;

CREATE USER gw_nonsuper_sys;
GRANT role_system TO gw_nonsuper_sys;

SET ROLE gw_nonsuper_basic;

SELECT is(current_user, 'gw_nonsuper_basic', 'session is gw_nonsuper_basic');
SELECT is(
    (SELECT rolsuper FROM pg_roles WHERE rolname = current_user),
    false,
    'gw_nonsuper_basic is not a superuser'
);
SELECT ok(
    NOT pg_has_role(current_user, 'role_SCHEMA_NAME', 'member'),
    'gw_nonsuper_basic does not inherit role_SCHEMA_NAME'
);
SELECT ok(
    has_schema_privilege(current_user, 'SCHEMA_NAME', 'USAGE'),
    'gw_nonsuper_basic has USAGE on the schema via role_basic'
);
SELECT ok(
    NOT has_schema_privilege(current_user, 'SCHEMA_NAME', 'CREATE'),
    'gw_nonsuper_basic has no CREATE on the schema'
);
SELECT throws_ok(
    'CREATE ROLE gw_nonsuper_should_fail NOLOGIN',
    '42501',
    NULL,
    'gw_nonsuper_basic cannot CREATE ROLE'
);
SELECT ok(
    NOT pg_has_role(current_user, 'role_SCHEMA_NAME', 'SET'),
    'gw_nonsuper_basic cannot SET ROLE role_SCHEMA_NAME'
);

RESET ROLE;
SET ROLE gw_nonsuper_sys;

SELECT is(current_user, 'gw_nonsuper_sys', 'session is gw_nonsuper_sys');
SELECT is(
    (SELECT rolsuper FROM pg_roles WHERE rolname = current_user),
    false,
    'gw_nonsuper_sys is not a superuser'
);
SELECT ok(
    pg_has_role(current_user, 'role_system', 'member'),
    'gw_nonsuper_sys is a member of role_system'
);
SELECT ok(
    pg_has_role(current_user, 'role_SCHEMA_NAME', 'member'),
    'gw_nonsuper_sys inherits role_SCHEMA_NAME through role_system'
);
SELECT ok(
    has_schema_privilege(current_user, 'SCHEMA_NAME', 'CREATE'),
    'gw_nonsuper_sys has CREATE on the schema'
);
SELECT lives_ok(
    'SELECT 1 FROM node LIMIT 1',
    'gw_nonsuper_sys can SELECT from node'
);
SELECT throws_ok(
    'CREATE ROLE gw_nonsuper_should_fail NOLOGIN',
    '42501',
    NULL,
    'a role_system member without CREATEROLE cannot CREATE ROLE'
);

SELECT ok(
    pg_has_role(current_user, 'role_SCHEMA_NAME', 'SET'),
    'gw_nonsuper_sys can SET ROLE role_SCHEMA_NAME'
);

-- session_user stays the superuser that runs pg_prove, so SET ROLE here
-- becomes the schema role itself. The login's right to do that is the check above.
RESET ROLE;
SET ROLE role_SCHEMA_NAME;

SELECT is(current_user, 'role_SCHEMA_NAME', 'session is role_SCHEMA_NAME');
SELECT ok(
    has_schema_privilege(current_user, 'SCHEMA_NAME', 'CREATE'),
    'role_SCHEMA_NAME has CREATE on its schema'
);
SELECT throws_ok(
    'SELECT 1 FROM node LIMIT 1',
    '42501',
    NULL,
    'role_SCHEMA_NAME has no table privileges'
);
SELECT lives_ok(
    'CREATE TABLE t_schema_role_probe (id int)',
    'role_SCHEMA_NAME can create a table in its schema'
);

SELECT * FROM finish();
ROLLBACK;

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

-- ===========================
-- PREPARE DATA: minimal source schema
-- ===========================
CREATE SCHEMA publi_tsrc;
CREATE TABLE publi_tsrc.exploitation (expl_id integer PRIMARY KEY, name text);
CREATE TABLE publi_tsrc.sector (sector_id integer PRIMARY KEY, expl_id integer[]);
CREATE TABLE publi_tsrc.value_state (id integer PRIMARY KEY, name text);
CREATE TABLE publi_tsrc.config_param_system (parameter text PRIMARY KEY, value text);
CREATE TABLE publi_tsrc.cat_manager (id serial PRIMARY KEY, idval text, expl_id integer[], rolename text[], active boolean DEFAULT true);
CREATE TABLE publi_tsrc.config_form_fields (
    formname text, formtype text, tabname text, columnname text, widgettype text,
    label text, tooltip text, dv_querytext text
);
CREATE TABLE publi_tsrc.src_pipe (
    obj_id integer PRIMARY KEY, expl_id integer, state integer, descript text, the_geom geometry(Point, 25831)
);

INSERT INTO publi_tsrc.exploitation VALUES (1, 'Expl one'), (2, 'Expl two');
INSERT INTO publi_tsrc.sector VALUES (10, '{1}'), (20, '{2}');
INSERT INTO publi_tsrc.value_state VALUES (0, 'Obsolete'), (1, 'On service'), (2, 'Planified');
INSERT INTO publi_tsrc.config_param_system VALUES ('admin_exploitation_x_user', 'true');
INSERT INTO publi_tsrc.config_form_fields VALUES
    ('src_pipe', 'form_feature', 'tab_data', 'state', 'combo', 'State:', 'state', 'SELECT id, name AS idval FROM value_state'),
    ('src_pipe', 'form_feature', 'tab_data', 'expl_id', 'combo', 'Exploitation', 'Exploitation of the pipe', 'SELECT expl_id AS id, name AS idval FROM exploitation'),
    ('src_pipe', 'form_feature', 'tab_data', 'descript', 'text', 'Description', NULL, NULL);
INSERT INTO publi_tsrc.src_pipe VALUES
    (1, 1, 1, 'a', ST_SetSRID(ST_MakePoint(0, 0), 25831)),
    (2, 1, 1, 'b', ST_SetSRID(ST_MakePoint(1, 0), 25831)),
    (3, 2, 2, 'c', ST_SetSRID(ST_MakePoint(2, 0), 25831));

INSERT INTO publi.config_publi_table (source_schema, source_relation, target_name, object_type, pk_columns, rls_mode)
VALUES ('publi_tsrc', 'src_pipe', 'tst_pipe', 'other', '{obj_id}', 'expl');

CREATE TEMP TABLE tst_res (step text, res json);

-- ===========================
-- CREATE
-- ===========================
INSERT INTO tst_res SELECT 'create', publi.gw_fct_publi_sync('{"data":{"targets":["tst_pipe"],"resetSelectors":false}}');

SELECT is((SELECT res ->> 'status' FROM tst_res WHERE step = 'create'), 'Accepted', 'create: status Accepted');
SELECT is((SELECT (res -> 'body' -> 'data' ->> 'ok')::int FROM tst_res WHERE step = 'create'), 1, 'create: one table ok');
SELECT has_table('publi'::name, 'tst_pipe'::name, 'create: publi.tst_pipe exists');
SELECT col_is_pk('publi', 'tst_pipe', 'obj_id', 'create: obj_id is the primary key');
SELECT ok(EXISTS (
    SELECT 1 FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_am am ON am.oid = ic.relam
    WHERE i.indrelid = 'publi.tst_pipe'::regclass AND am.amname = 'gist'), 'create: GIST index on the_geom');
SELECT is((SELECT count(*)::int FROM publi.tst_pipe), 3, 'create: 3 rows copied');
SELECT is((SELECT mode FROM publi.sync_log WHERE target_name = 'tst_pipe' ORDER BY id DESC LIMIT 1), 'create', 'create: sync_log mode create');

-- double columns: <col>_name right after <col>, decoded through dv_querytext
SELECT has_column('publi', 'tst_pipe', 'state_name', 'decode: state_name exists');
SELECT has_column('publi', 'tst_pipe', 'expl_name', 'decode: expl_name exists');
SELECT is(
    (SELECT attnum::int FROM pg_attribute WHERE attrelid = 'publi.tst_pipe'::regclass AND attname = 'expl_name'),
    (SELECT attnum + 1 FROM pg_attribute WHERE attrelid = 'publi.tst_pipe'::regclass AND attname = 'expl_id'),
    'decode: expl_name follows expl_id');
SELECT is((SELECT state_name FROM publi.tst_pipe WHERE obj_id = 3), 'Planified', 'decode: state 2 -> Planified');
SELECT is((SELECT expl_name FROM publi.tst_pipe WHERE obj_id = 1), 'Expl one', 'decode: expl 1 -> Expl one');

-- metadata
SELECT is((SELECT alias FROM publi.sys_metadata WHERE target_name = 'tst_pipe' AND column_name = 'state'), 'State', 'metadata: trailing colon stripped from label');
SELECT is((SELECT alias FROM publi.sys_metadata WHERE target_name = 'tst_pipe' AND column_name = 'state_name'), 'State', 'metadata: name column inherits the label');
SELECT is((SELECT count(*)::int FROM publi.sys_domain WHERE target_name = 'tst_pipe' AND column_name = 'state'), 3, 'metadata: sys_domain holds the state domain');
SELECT isnt(col_description('publi.tst_pipe'::regclass, (SELECT attnum FROM pg_attribute WHERE attrelid = 'publi.tst_pipe'::regclass AND attname = 'expl_name')), NULL, 'metadata: COMMENT ON COLUMN written');

-- security
SELECT ok((SELECT relrowsecurity AND relforcerowsecurity FROM pg_class WHERE oid = 'publi.tst_pipe'::regclass), 'security: RLS enabled and forced');
SELECT set_eq(
    $$SELECT policyname::text FROM pg_policies WHERE schemaname = 'publi' AND tablename = 'tst_pipe'$$,
    ARRAY['publi_rls', 'publi_owner'], 'security: publi_rls and publi_owner policies');

-- ===========================
-- IDEMPOTENT
-- ===========================
INSERT INTO tst_res SELECT 'same', publi.gw_fct_publi_sync('{"data":{"targets":["tst_pipe"],"resetSelectors":false}}');
SELECT results_eq(
    $$SELECT mode, rows_inserted, rows_updated, rows_deleted FROM publi.sync_log WHERE target_name = 'tst_pipe' ORDER BY id DESC LIMIT 1$$,
    $$VALUES ('none'::text, 0, 0, 0)$$, 'same source: mode none, no row touched');

-- ===========================
-- DATA DIFF
-- ===========================
UPDATE publi_tsrc.src_pipe SET descript = 'a2', state = 2 WHERE obj_id = 1;
INSERT INTO publi_tsrc.src_pipe VALUES (4, 1, 1, 'd', ST_SetSRID(ST_MakePoint(3, 0), 25831));
DELETE FROM publi_tsrc.src_pipe WHERE obj_id = 3;

INSERT INTO tst_res SELECT 'diff', publi.gw_fct_publi_sync('{"data":{"targets":["tst_pipe"],"resetSelectors":false}}');
SELECT results_eq(
    $$SELECT mode, rows_inserted, rows_updated, rows_deleted FROM publi.sync_log WHERE target_name = 'tst_pipe' ORDER BY id DESC LIMIT 1$$,
    $$VALUES ('none'::text, 1, 1, 1)$$, 'diff: one insert, one update, one delete');
SELECT results_eq(
    $$SELECT obj_id, descript, state_name FROM publi.tst_pipe ORDER BY obj_id$$,
    $$VALUES (1, 'a2'::text, 'Planified'::text), (2, 'b', 'On service'), (4, 'd', 'On service')$$,
    'diff: live table matches the source, names refreshed');

-- ===========================
-- STRUCTURE: ADD COLUMN via ALTER
-- ===========================
ALTER TABLE publi_tsrc.src_pipe ADD COLUMN material text DEFAULT 'PVC';
INSERT INTO tst_res SELECT 'add', publi.gw_fct_publi_sync('{"data":{"targets":["tst_pipe"],"resetSelectors":false}}');
SELECT is((SELECT mode FROM publi.sync_log WHERE target_name = 'tst_pipe' ORDER BY id DESC LIMIT 1), 'alter', 'add column: mode alter, no swap');
SELECT is((SELECT count(*)::int FROM publi.tst_pipe WHERE material = 'PVC'), 3, 'add column: values filled');
SELECT col_is_pk('publi', 'tst_pipe', 'obj_id', 'add column: primary key kept');

-- ===========================
-- RLS as a reader
-- ===========================
CREATE ROLE publi_tst_grp NOLOGIN;
CREATE ROLE publi_tst_user LOGIN IN ROLE publi_tst_grp;
GRANT USAGE ON SCHEMA publi TO publi_tst_user;
GRANT SELECT ON publi.tst_pipe TO publi_tst_user;
INSERT INTO publi_tsrc.cat_manager (idval, expl_id, rolename) VALUES ('test', '{1}', '{publi_tst_grp}');

-- the SECURITY DEFINER helper reads the source schema with its owner's rights
DO $$
DECLARE v_owner text := (SELECT pg_get_userbyid(proowner) FROM pg_proc WHERE oid = 'publi.gw_fct_publi_user_ids(text, text, name)'::regprocedure);
BEGIN
    EXECUTE format('GRANT USAGE ON SCHEMA publi_tsrc TO %I', v_owner);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA publi_tsrc TO %I', v_owner);
END $$;

SET ROLE publi_tst_user;
SELECT is((SELECT count(*)::int FROM publi.tst_pipe), 3, 'rls: reader of expl 1 sees its 3 rows');
SELECT is((SELECT array_agg(DISTINCT expl_id) FROM publi.tst_pipe), '{1}'::integer[], 'rls: reader sees only expl 1');
RESET ROLE;

UPDATE publi_tsrc.cat_manager SET expl_id = '{2}' WHERE idval = 'test';
SET ROLE publi_tst_user;
SELECT is((SELECT count(*)::int FROM publi.tst_pipe), 0, 'rls: reader moved to expl 2 sees nothing (no expl 2 rows left)');
RESET ROLE;

SELECT is(publi.gw_fct_publi_user_ids('publi_tsrc', 'sector_id', 'publi_tst_user'), '{20}'::integer[], 'rls: sectors derived from the user exploitations');

UPDATE publi_tsrc.config_param_system SET value = 'false' WHERE parameter = 'admin_exploitation_x_user';
SELECT is(publi.gw_fct_publi_user_ids('publi_tsrc', 'expl_id', 'publi_tst_user'), '{1,2}'::integer[], 'rls: admin_exploitation_x_user false opens every exploitation');

-- ===========================
-- FAILURE ISOLATION
-- ===========================
INSERT INTO publi.config_publi_table (source_schema, source_relation, target_name, object_type, pk_columns, rls_mode)
VALUES ('publi_tsrc', 'missing_relation', 'tst_broken', 'other', '{obj_id}', 'none');
INSERT INTO tst_res SELECT 'broken', publi.gw_fct_publi_sync('{"data":{"targets":["tst_pipe","tst_broken"],"resetSelectors":false}}');
SELECT is((SELECT (res -> 'body' -> 'data' ->> 'ok')::int FROM tst_res WHERE step = 'broken'), 1, 'isolation: good table still synced');
SELECT is((SELECT (res -> 'body' -> 'data' ->> 'failed')::int FROM tst_res WHERE step = 'broken'), 1, 'isolation: broken table reported');
SELECT isnt((SELECT error FROM publi.sync_log WHERE target_name = 'tst_broken' ORDER BY id DESC LIMIT 1), NULL, 'isolation: error logged in sync_log');
SELECT hasnt_table('publi'::name, 'tst_broken'::name, 'isolation: nothing created for the broken table');

-- ===========================
-- PK VIOLATION in source
-- ===========================
UPDATE publi.config_publi_table SET pk_columns = '{expl_id}' WHERE target_name = 'tst_pipe';
INSERT INTO tst_res SELECT 'dup', publi.gw_fct_publi_sync('{"data":{"targets":["tst_pipe"],"resetSelectors":false}}');
SELECT matches((SELECT error FROM publi.sync_log WHERE target_name = 'tst_pipe' ORDER BY id DESC LIMIT 1), 'duplicated pk', 'pk: duplicated keys rejected before touching the live table');
SELECT is((SELECT count(*)::int FROM publi.tst_pipe), 3, 'pk: live table untouched');

SELECT * FROM finish();

ROLLBACK;

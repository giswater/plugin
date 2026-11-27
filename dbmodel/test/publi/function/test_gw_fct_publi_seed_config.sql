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
-- PREPARE DATA: ve_node parent, ve_node_tank child, ve_node_junction with no extra columns
-- ===========================
CREATE SCHEMA publi_wn;
ALTER DEFAULT PRIVILEGES IN SCHEMA publi_wn GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_system;
GRANT USAGE ON SCHEMA publi_wn TO role_system;

CREATE TABLE publi_wn.exploitation (expl_id integer PRIMARY KEY, name text);
CREATE TABLE publi_wn.value_state (id integer PRIMARY KEY, name text);
CREATE TABLE publi_wn.node (
    node_id integer PRIMARY KEY,
    expl_id integer,
    state integer,
    descript text,
    the_geom geometry(Point, 25831)
);
CREATE TABLE publi_wn.man_tank (node_id integer PRIMARY KEY, vmax numeric);
CREATE TABLE publi_wn.cat_feature (
    id text PRIMARY KEY,
    feature_class text,
    feature_type text,
    active boolean,
    parent_layer text,
    child_layer text,
    descript text
);
CREATE TABLE publi_wn.config_form_fields (
    formname text, formtype text, tabname text, columnname text, widgettype text,
    label text, tooltip text, dv_querytext text
);

CREATE VIEW publi_wn.ve_node AS
SELECT node_id, expl_id, state, descript, the_geom FROM publi_wn.node;

CREATE VIEW publi_wn.ve_node_tank AS
SELECT n.node_id, n.expl_id, n.state, n.descript, n.the_geom, t.vmax
FROM publi_wn.node n
JOIN publi_wn.man_tank t USING (node_id);

CREATE VIEW publi_wn.ve_node_junction AS
SELECT node_id, expl_id, state, descript, the_geom FROM publi_wn.node;

GRANT SELECT ON ALL TABLES IN SCHEMA publi_wn TO role_system;

INSERT INTO publi_wn.exploitation VALUES (1, 'Expl one'), (2, 'Expl two');
INSERT INTO publi_wn.value_state VALUES (0, 'Obsolete'), (1, 'On service'), (2, 'Planified');
INSERT INTO publi_wn.cat_feature VALUES
    ('TANK', 'TANK', 'NODE', true, 've_node', 've_node_tank'),
    ('JUNCTION', 'JUNCTION', 'NODE', true, 've_node', 've_node_junction');
INSERT INTO publi_wn.config_form_fields VALUES
    ('ve_node', 'form_feature', 'tab_data', 'state', 'combo', 'State:', 'state', 'SELECT id, name AS idval FROM value_state'),
    ('ve_node', 'form_feature', 'tab_data', 'expl_id', 'combo', 'Exploitation', NULL, 'SELECT expl_id AS id, name AS idval FROM exploitation'),
    ('ve_node_tank', 'form_feature', 'tab_data', 'state', 'combo', 'State:', 'state', 'SELECT id, name AS idval FROM value_state');
INSERT INTO publi_wn.node VALUES
    (1, 1, 1, 'junction', ST_SetSRID(ST_MakePoint(0, 0), 25831)),
    (2, 1, 1, 'tank a', ST_SetSRID(ST_MakePoint(1, 0), 25831)),
    (3, 2, 2, 'tank b', ST_SetSRID(ST_MakePoint(2, 0), 25831));
INSERT INTO publi_wn.man_tank VALUES (2, 100), (3, 40);

CREATE TEMP TABLE tst_res (step text, res json);

-- ===========================
-- SEED
-- ===========================
INSERT INTO tst_res
SELECT 'seed', publi.gw_fct_publi_seed_config('{"data":{"sourceSchema":"publi_wn","prefix":"wn","replace":false}}');

SELECT is((SELECT res ->> 'status' FROM tst_res WHERE step = 'seed'), 'Accepted', 'seed: status Accepted');
SELECT ok(
    (SELECT res -> 'body' -> 'data' -> 'skipped' FROM tst_res WHERE step = 'seed')::jsonb
        @> '[{"source":"ve_node_junction","reason":"no columns over parent"}]'::jsonb,
    'seed: junction adds no columns and is skipped'
);
SELECT results_eq(
    $$SELECT target_name, object_type, source_relation, pk_columns, rls_mode
      FROM publi.config_publi_table WHERE source_schema = 'publi_wn' ORDER BY target_name$$,
    $$VALUES
        ('wn_cat_feature', 'catalog', 'cat_feature', '{id}'::text[], 'none'),
        ('wn_exploitation', 'mapzone', 'exploitation', '{expl_id}', 'expl'),
        ('wn_node', 'parent', 've_node', '{node_id}', 'expl'),
        ('wn_node_tank', 'child', 've_node_tank', '{node_id}', 'expl')$$,
    'seed: parent, tank child, exploitation and cat_feature'
);
SELECT is(
    (SELECT count(*)::int FROM publi.config_publi_table WHERE source_relation = 've_node_junction'),
    0, 'seed: ve_node_junction is not configured'
);

-- ===========================
-- SYNC
-- ===========================
INSERT INTO tst_res
SELECT 'sync', publi.gw_fct_publi_sync('{"data":{"sourceSchema":"publi_wn","resetSelectors":false}}');

SELECT is((SELECT res ->> 'status' FROM tst_res WHERE step = 'sync'), 'Accepted', 'sync: status Accepted');
SELECT is((SELECT (res -> 'body' -> 'data' ->> 'ok')::int FROM tst_res WHERE step = 'sync'), 4, 'sync: four tables ok');
SELECT is((SELECT (res -> 'body' -> 'data' ->> 'failed')::int FROM tst_res WHERE step = 'sync'), 0, 'sync: none failed');
SELECT is(
    (SELECT coalesce(string_agg(target_name || ': ' || error, '; ' ORDER BY target_name), '')
     FROM publi.sync_log WHERE target_name LIKE 'wn_%' AND error IS NOT NULL),
    '',
    'sync: sync_log has no errors'
);

SELECT has_table('publi'::name, 'wn_node'::name, 'sync: publi.wn_node exists');
SELECT has_table('publi'::name, 'wn_node_tank'::name, 'sync: publi.wn_node_tank exists');
SELECT hasnt_table('publi'::name, 'wn_node_junction'::name, 'sync: junction was not published');
SELECT col_is_pk('publi', 'wn_node', 'node_id', 'sync: node_id is the primary key of the parent');
SELECT col_is_pk('publi', 'wn_node_tank', 'node_id', 'sync: node_id is the primary key of the child');
SELECT has_column('publi', 'wn_node_tank', 'vmax', 'sync: tank keeps the column it adds over ve_node');
SELECT hasnt_column('publi', 'wn_node', 'vmax', 'sync: parent does not gain the child column');
SELECT has_column('publi', 'wn_node', 'state_name', 'sync: state is decoded on the parent');
SELECT has_column('publi', 'wn_node_tank', 'state_name', 'sync: state is decoded on the child');
SELECT ok(EXISTS (
    SELECT 1 FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_am am ON am.oid = ic.relam
    WHERE i.indrelid = to_regclass('publi.wn_node') AND am.amname = 'gist'),
    'sync: GIST index on ve_node.the_geom');

SELECT results_eq(
    $$SELECT target_name, mode, rows_inserted, rows_updated, rows_deleted
      FROM publi.sync_log WHERE target_name LIKE 'wn_%' ORDER BY target_name$$,
    $$VALUES
        ('wn_cat_feature', 'create', 2, 0, 0),
        ('wn_exploitation', 'create', 2, 0, 0),
        ('wn_node', 'create', 3, 0, 0),
        ('wn_node_tank', 'create', 2, 0, 0)$$,
    'sync: create mode and row counts'
);
SELECT results_eq(
    $$SELECT node_id, descript, state_name, expl_name FROM publi.wn_node ORDER BY node_id$$,
    $$VALUES
        (1, 'junction'::text, 'On service'::text, 'Expl one'::text),
        (2, 'tank a', 'On service', 'Expl one'),
        (3, 'tank b', 'Planified', 'Expl two')$$,
    'sync: parent rows match ve_node'
);
SELECT results_eq(
    $$SELECT node_id, descript, vmax, state_name FROM publi.wn_node_tank ORDER BY node_id$$,
    $$VALUES
        (2, 'tank a'::text, 100::numeric, 'On service'::text),
        (3, 'tank b', 40, 'Planified')$$,
    'sync: child rows match ve_node_tank'
);

-- ===========================
-- IDEMPOTENT, THEN A DATA CHANGE ON THE PARENT AND THE CHILD
-- ===========================
INSERT INTO tst_res
SELECT 'same', publi.gw_fct_publi_sync('{"data":{"sourceSchema":"publi_wn","resetSelectors":false}}');
SELECT results_eq(
    $$SELECT DISTINCT ON (target_name) target_name, mode, rows_inserted, rows_updated, rows_deleted
      FROM publi.sync_log WHERE target_name LIKE 'wn_%' ORDER BY target_name, id DESC$$,
    $$VALUES
        ('wn_cat_feature', 'none', 0, 0, 0),
        ('wn_exploitation', 'none', 0, 0, 0),
        ('wn_node', 'none', 0, 0, 0),
        ('wn_node_tank', 'none', 0, 0, 0)$$,
    'same source: nothing touched'
);

UPDATE publi_wn.node SET descript = 'tank a2' WHERE node_id = 2;
UPDATE publi_wn.man_tank SET vmax = 125 WHERE node_id = 2;
INSERT INTO tst_res
SELECT 'diff', publi.gw_fct_publi_sync('{"data":{"targets":["wn_node","wn_node_tank"],"resetSelectors":false}}');
SELECT results_eq(
    $$SELECT DISTINCT ON (target_name) target_name, mode, rows_inserted, rows_updated, rows_deleted
      FROM publi.sync_log WHERE target_name IN ('wn_node', 'wn_node_tank') ORDER BY target_name, id DESC$$,
    $$VALUES
        ('wn_node', 'none', 0, 1, 0),
        ('wn_node_tank', 'none', 0, 1, 0)$$,
    'diff: parent descript and child vmax each update one row'
);
SELECT is((SELECT descript FROM publi.wn_node WHERE node_id = 2), 'tank a2', 'diff: parent descript refreshed');
SELECT is((SELECT vmax FROM publi.wn_node_tank WHERE node_id = 2), 125::numeric, 'diff: child vmax refreshed');
SELECT is((SELECT descript FROM publi.wn_node_tank WHERE node_id = 2), 'tank a2', 'diff: child picks up the parent descript');

SELECT * FROM finish();

ROLLBACK;

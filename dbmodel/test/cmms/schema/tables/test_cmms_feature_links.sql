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

CREATE SCHEMA ws_fake AUTHORIZATION role_system;

SET ROLE role_system;
CREATE TABLE ws_fake.node (node_id int4 PRIMARY KEY);
CREATE TABLE ws_fake.element (element_id int4 PRIMARY KEY);
INSERT INTO ws_fake.node (node_id) VALUES (1), (2), (3);
INSERT INTO ws_fake.element (element_id) VALUES (7);
RESET ROLE;

DO $cmms_feature_sync$
DECLARE
    v_parent constant text := 'ws_fake';
    v_table text;
    v_id_column text;
BEGIN
    FOREACH v_table IN ARRAY ARRAY['node', 'arc', 'connec', 'link', 'gully', 'element']
    LOOP
        IF to_regclass(format('%I.%I', v_parent, v_table)) IS NULL THEN
            CONTINUE;
        END IF;
        v_id_column := v_table || '_id';
        EXECUTE format(
            'DROP TRIGGER IF EXISTS gw_trg_cmms_feature_sync_delete ON %I.%I',
            v_parent, v_table
        );
        EXECUTE format(
            'DROP TRIGGER IF EXISTS gw_trg_cmms_feature_sync_id ON %I.%I',
            v_parent, v_table
        );
        EXECUTE format(
            'CREATE TRIGGER gw_trg_cmms_feature_sync_delete '
            'AFTER DELETE ON %I.%I '
            'FOR EACH ROW EXECUTE PROCEDURE cmms.gw_trg_cmms_feature_sync(%L)',
            v_parent, v_table, v_id_column
        );
        EXECUTE format(
            'CREATE TRIGGER gw_trg_cmms_feature_sync_id '
            'AFTER UPDATE OF %I ON %I.%I '
            'FOR EACH ROW WHEN (OLD.%I IS DISTINCT FROM NEW.%I) '
            'EXECUTE PROCEDURE cmms.gw_trg_cmms_feature_sync(%L)',
            v_id_column, v_parent, v_table, v_id_column, v_id_column, v_id_column
        );
    END LOOP;
END
$cmms_feature_sync$;

SELECT lives_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-node-1', 1, 'NODE', 'ws_fake')$$,
    'a live mapping to an existing node is accepted'
);

SELECT throws_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-missing', 999, 'NODE', 'ws_fake')$$,
    '23503'::char(5),
    NULL,
    'a mapping to a missing feature is rejected'
);

SELECT throws_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-noschema', 1, 'NODE', 'no_such_parent')$$,
    '23503'::char(5),
    NULL,
    'a mapping to a missing schema is rejected'
);

SELECT throws_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-gully', 1, 'GULLY', 'ws_fake')$$,
    '23503'::char(5),
    NULL,
    'GULLY is rejected when the parent has no gully table'
);

SELECT lives_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-element', 7, 'ELEMENT', 'ws_fake')$$,
    'ELEMENT is a valid feature type'
);

SELECT throws_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-node-1-dup', 1, 'NODE', 'ws_fake')$$,
    '23505'::char(5),
    NULL,
    'a second live mapping of the same feature is rejected'
);

INSERT INTO visit (id, type, status)
VALUES ('00000000-0000-0000-0000-000000000011', 'inspection', 'open');

INSERT INTO visit_x_feature (visit_id, asset_feature_map_id)
SELECT '00000000-0000-0000-0000-000000000011', id
FROM asset_feature_map
WHERE ext_feature_id = 'ext-node-1';

DELETE FROM ws_fake.node WHERE node_id = 1;

SELECT ok(
    (SELECT feature_deleted_at IS NOT NULL
     FROM asset_feature_map
     WHERE ext_feature_id = 'ext-node-1'),
    'deleting the feature orphans the mapping'
);

SELECT is(
    (SELECT count(*)::int
     FROM visit_x_feature v
     JOIN asset_feature_map m ON m.id = v.asset_feature_map_id
     WHERE m.ext_feature_id = 'ext-node-1'),
    1,
    'the visit link survives the feature delete'
);

INSERT INTO ws_fake.node (node_id) VALUES (1);

SELECT lives_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-node-1b', 1, 'NODE', 'ws_fake')$$,
    'a new live mapping is allowed once the previous one is orphaned'
);

INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
VALUES ('ext-node-2', 2, 'NODE', 'ws_fake');

UPDATE ws_fake.node SET node_id = 20 WHERE node_id = 2;

SELECT is(
    (SELECT feature_id FROM asset_feature_map WHERE ext_feature_id = 'ext-node-2'),
    20,
    'changing the feature id rewrites feature_id'
);

SET ROLE role_cmms;
SELECT lives_ok(
    $$INSERT INTO asset_feature_map (ext_feature_id, feature_id, feature_type, schema_name)
      VALUES ('ext-from-cmms', 3, 'NODE', 'ws_fake')$$,
    'role_cmms can map a feature it cannot select'
);
RESET ROLE;

CREATE ROLE cmms_link_tester NOLOGIN;
GRANT USAGE ON SCHEMA ws_fake TO cmms_link_tester;
GRANT SELECT, DELETE ON ws_fake.node TO cmms_link_tester;
-- USAGE only: the table resolves, and the write is a privilege error.
GRANT USAGE ON SCHEMA cmms TO cmms_link_tester;

SET ROLE cmms_link_tester;
SELECT lives_ok(
    $$DELETE FROM ws_fake.node WHERE node_id = 3$$,
    'a role without cmms grants can delete the parent feature'
);
SELECT throws_ok(
    $$UPDATE asset_feature_map SET properties = '{}'::jsonb WHERE ext_feature_id = 'ext-from-cmms'$$,
    '42501'::char(5),
    NULL,
    'that role cannot write asset_feature_map itself'
);
RESET ROLE;

SELECT ok(
    (SELECT feature_deleted_at IS NOT NULL
     FROM asset_feature_map
     WHERE ext_feature_id = 'ext-from-cmms'),
    'the delete still orphans the mapping'
);

SELECT has_trigger(
    'ws_fake',
    'node',
    'gw_trg_cmms_feature_sync_delete',
    'the parent node carries the cmms delete trigger'
);

SELECT is(
    (SELECT gw_fct_cmms_unlink_parent('ws_fake')::jsonb ->> 'status'),
    'Accepted',
    'unlink of a still-present parent is accepted'
);

SELECT hasnt_trigger(
    'ws_fake',
    'node',
    'gw_trg_cmms_feature_sync_delete',
    'unlink drops the parent delete trigger'
);

SELECT hasnt_trigger(
    'ws_fake',
    'node',
    'gw_trg_cmms_feature_sync_id',
    'unlink drops the parent id trigger'
);

SELECT * FROM finish();

ROLLBACK;

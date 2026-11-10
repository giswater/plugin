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
CREATE TABLE ws_fake.node (
    node_id character varying(16) PRIMARY KEY,
    sys_code text
);
INSERT INTO ws_fake.node (node_id, sys_code) VALUES
    ('1', 'SC-1'),
    ('2', 'SC-1'),
    ('3', 'SC-3');
RESET ROLE;

SELECT lives_ok(
    $$SELECT gw_fct_cmms_create_parent_views('ws_fake')$$,
    'parent views are built from the feature tables'
);

INSERT INTO visit (id, type, status)
VALUES ('00000000-0000-0000-0000-000000000011', 'inspection', 'open');

INSERT INTO visit_x_feature (visit_id, sys_code)
VALUES ('00000000-0000-0000-0000-000000000011', 'SC-1');

INSERT INTO attachment (id, name, path)
VALUES
    ('00000000-0000-0000-0000-000000000021', 'visit-photo', '/tmp/visit-photo.jpg'),
    ('00000000-0000-0000-0000-000000000022', 'direct-photo', '/tmp/direct-photo.jpg');

INSERT INTO attachment_x_visit (attachment_id, visit_id)
VALUES ('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000011');

INSERT INTO attachment_x_feature (attachment_id, sys_code)
VALUES ('00000000-0000-0000-0000-000000000022', 'SC-1');

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_visit WHERE feature_id = '1'),
    1,
    'the feature with that sys_code has one cmms visit'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_visit WHERE feature_id = '2'),
    1,
    'a second feature with the same sys_code shows the same visit'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_visit WHERE feature_id = '3'),
    0,
    'a feature with another sys_code has no visit'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_attachment WHERE feature_id = '1'),
    2,
    'direct and visit attachments both show'
);

SELECT ok(
    (SELECT visit_id IS NULL FROM ws_fake.v_ui_cmms_attachment
     WHERE feature_id = '1' AND name = 'direct-photo'),
    'a direct attachment has no visit_id'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_cmms_visit),
    1,
    'two features with the same sys_code are one visit'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_visit),
    2,
    'the feature tab still has one row per feature'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_cmms_attachment),
    2,
    'direct and visit files are two attachments'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_attachment),
    4,
    'the feature tab repeats each attachment per feature'
);

INSERT INTO attachment (id, name)
VALUES ('00000000-0000-0000-0000-000000000023', 'both-photo');

INSERT INTO attachment_x_feature (attachment_id, sys_code)
VALUES ('00000000-0000-0000-0000-000000000023', 'SC-1');

INSERT INTO attachment_x_visit (attachment_id, visit_id)
VALUES ('00000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000011');

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_cmms_attachment
     WHERE id = '00000000-0000-0000-0000-000000000023'),
    1,
    'an attachment linked directly and through the visit is one row'
);

INSERT INTO visit (id, type, status)
VALUES ('00000000-0000-0000-0000-000000000012', 'inspection', 'open');

INSERT INTO visit_x_feature (visit_id, sys_code)
VALUES ('00000000-0000-0000-0000-000000000012', 'SC-NONE');

INSERT INTO attachment (id, name)
VALUES ('00000000-0000-0000-0000-000000000024', 'orphan-photo');

INSERT INTO attachment_x_feature (attachment_id, sys_code)
VALUES ('00000000-0000-0000-0000-000000000024', 'SC-NONE');

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_cmms_visit
     WHERE id = '00000000-0000-0000-0000-000000000012'),
    0,
    'a visit whose sys_code matches nothing is absent'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_cmms_attachment
     WHERE id = '00000000-0000-0000-0000-000000000024'),
    0,
    'an attachment whose sys_code matches nothing is absent'
);

UPDATE ws_fake.node SET node_id = '20' WHERE node_id = '1';

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_visit WHERE feature_id = '20'),
    1,
    'changing the feature id keeps the visit on the new id'
);

SELECT is(
    (SELECT count(*)::int FROM visit_x_feature WHERE sys_code = 'SC-1'),
    1,
    'changing the feature id does not rewrite cmms'
);

DELETE FROM ws_fake.node WHERE sys_code = 'SC-1';

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_ui_cmms_visit),
    0,
    'deleting the features hides the visit'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_cmms_visit),
    0,
    'deleting the features hides the schema visit list'
);

SELECT is(
    (SELECT count(*)::int FROM ws_fake.v_cmms_attachment),
    0,
    'deleting the features hides the schema attachment list'
);

SELECT is(
    (SELECT count(*)::int FROM visit_x_feature WHERE sys_code = 'SC-1'),
    1,
    'deleting the features keeps the cmms link'
);

SELECT is(
    (SELECT count(*)::int FROM attachment_x_feature WHERE sys_code = 'SC-1'),
    2,
    'deleting the features keeps the attachment links'
);

SELECT * FROM finish();

ROLLBACK;

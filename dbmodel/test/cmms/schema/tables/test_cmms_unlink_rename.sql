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

SELECT has_function(
    'gw_fct_cmms_unlink_parent',
    ARRAY['text'],
    'gw_fct_cmms_unlink_parent(text) should exist'
);
SELECT has_function(
    'gw_fct_cmms_rename_parent',
    ARRAY['text', 'text'],
    'gw_fct_cmms_rename_parent(text, text) should exist'
);

UPDATE sys_version
SET addparam = jsonb_set(
    COALESCE(addparam, '{}'::jsonb),
    '{parent_schemas}',
    '["ws_old", "ud_keep"]'::jsonb,
    true
)
WHERE id = (SELECT id FROM sys_version ORDER BY id DESC LIMIT 1);

INSERT INTO visit (id, type, status)
VALUES ('00000000-0000-0000-0000-000000000001', 'inspection', 'open');

INSERT INTO attachment (id, name)
VALUES ('00000000-0000-0000-0000-000000000002', 'photo');

INSERT INTO visit_x_feature (visit_id, sys_code)
VALUES ('00000000-0000-0000-0000-000000000001', 'SC-OLD');

INSERT INTO attachment_x_feature (attachment_id, sys_code)
VALUES ('00000000-0000-0000-0000-000000000002', 'SC-OLD');

CREATE SCHEMA ws_old AUTHORIZATION role_system;

SET ROLE role_system;
CREATE TABLE ws_old.node (
    node_id character varying(16) PRIMARY KEY,
    sys_code text
);
INSERT INTO ws_old.node (node_id, sys_code) VALUES ('1', 'SC-OLD');
CREATE TABLE ws_old.config_form_tabs (formname text, tabname text);
CREATE TABLE ws_old.config_form_fields (formname text, tabname text);
CREATE TABLE ws_old.config_form_tableview (objectname text);
CREATE TABLE ws_old.sys_table (id text);
INSERT INTO ws_old.config_form_tabs VALUES ('ve_node', 'tab_cmms'), ('ve_arc', 'tab_event');
INSERT INTO ws_old.config_form_fields VALUES ('node', 'tab_cmms'), ('node', 'tab_data');
INSERT INTO ws_old.config_form_tableview VALUES ('v_ui_cmms_visit'), ('v_ui_cmms_attachment'), ('keep_me');
INSERT INTO ws_old.sys_table VALUES
    ('v_ui_cmms_visit'), ('v_ui_cmms_attachment'), ('v_cmms_visit'), ('v_cmms_attachment'), ('node');
RESET ROLE;

SELECT lives_ok(
    $$SELECT gw_fct_cmms_create_parent_views('ws_old')$$,
    'the parent gets the cmms views'
);

SELECT is(
    (SELECT gw_fct_cmms_unlink_parent('ws_old')::jsonb ->> 'status'),
    'Accepted',
    'unlink of a still-present parent is accepted'
);

SELECT hasnt_view('ws_old', 'v_ui_cmms_visit', 'unlink drops the visit view');
SELECT hasnt_view('ws_old', 'v_ui_cmms_attachment', 'unlink drops the attachment view');
SELECT hasnt_view('ws_old', 'v_cmms_visit', 'unlink drops the schema visit list');
SELECT hasnt_view('ws_old', 'v_cmms_attachment', 'unlink drops the schema attachment list');

SELECT is(
    (SELECT count(*)::int FROM ws_old.config_form_tabs WHERE tabname = 'tab_cmms'),
    0,
    'unlink removes the tab_cmms rows'
);
SELECT is(
    (SELECT count(*)::int FROM ws_old.config_form_tabs WHERE tabname = 'tab_event'),
    1,
    'unlink leaves the other tabs'
);
SELECT is(
    (SELECT count(*)::int FROM ws_old.config_form_fields WHERE tabname = 'tab_cmms'),
    0,
    'unlink removes the tab_cmms fields'
);
SELECT is(
    (SELECT count(*)::int FROM ws_old.config_form_fields WHERE tabname = 'tab_data'),
    1,
    'unlink leaves the other fields'
);
SELECT is(
    (SELECT count(*)::int FROM ws_old.config_form_tableview
     WHERE objectname IN ('v_ui_cmms_visit', 'v_ui_cmms_attachment')),
    0,
    'unlink removes the cmms tableview config'
);
SELECT is(
    (SELECT count(*)::int FROM ws_old.config_form_tableview WHERE objectname = 'keep_me'),
    1,
    'unlink leaves the other tableview rows'
);
SELECT is(
    (SELECT count(*)::int FROM ws_old.sys_table
     WHERE id IN ('v_ui_cmms_visit', 'v_ui_cmms_attachment', 'v_cmms_visit', 'v_cmms_attachment')),
    0,
    'unlink removes the cmms sys_table rows'
);
SELECT is(
    (SELECT count(*)::int FROM ws_old.sys_table WHERE id = 'node'),
    1,
    'unlink leaves the other sys_table rows'
);

SELECT is(
    (SELECT count(*)::int FROM visit_x_feature WHERE sys_code = 'SC-OLD'),
    1,
    'unlink keeps the visit link'
);
SELECT is(
    (SELECT count(*)::int FROM attachment_x_feature WHERE sys_code = 'SC-OLD'),
    1,
    'unlink keeps the attachment link'
);

SELECT ok(
    NOT COALESCE(
        (SELECT addparam -> 'parent_schemas' FROM sys_version ORDER BY id DESC LIMIT 1) ? 'ws_old',
        false
    ),
    'parent_schemas no longer lists the unlinked parent'
);

SELECT ok(
    COALESCE(
        (SELECT addparam -> 'parent_schemas' FROM sys_version ORDER BY id DESC LIMIT 1) ? 'ud_keep',
        false
    ),
    'parent_schemas still lists the other parent'
);

SELECT is(
    (SELECT gw_fct_cmms_rename_parent('ud_keep', 'ud_new')::jsonb ->> 'status'),
    'Accepted',
    'rename is accepted'
);

SELECT is(
    (SELECT count(*)::int FROM visit_x_feature WHERE sys_code = 'SC-OLD'),
    1,
    'rename does not touch the visit link'
);

SELECT ok(
    COALESCE(
        (SELECT addparam -> 'parent_schemas' FROM sys_version ORDER BY id DESC LIMIT 1) ? 'ud_new',
        false
    )
    AND NOT COALESCE(
        (SELECT addparam -> 'parent_schemas' FROM sys_version ORDER BY id DESC LIMIT 1) ? 'ud_keep',
        false
    ),
    'parent_schemas uses the new parent name'
);

SELECT * FROM finish();

ROLLBACK;

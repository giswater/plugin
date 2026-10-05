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

-- feature_deleted_at skips the parent-existence check. These schemas are not loaded.
INSERT INTO asset_feature_map (id, ext_feature_id, feature_id, feature_type, schema_name, feature_deleted_at)
VALUES
    (91001, 'ext-old', 1, 'NODE', 'ws_old', now()),
    (91002, 'ext-keep', 2, 'ARC', 'ud_keep', now());

INSERT INTO visit_x_feature (visit_id, asset_feature_map_id)
VALUES ('00000000-0000-0000-0000-000000000001', 91001);

INSERT INTO attachment_x_feature (attachment_id, asset_feature_map_id)
VALUES ('00000000-0000-0000-0000-000000000002', 91001);

SELECT is(
    (SELECT gw_fct_cmms_unlink_parent('ws_old')::jsonb ->> 'asset_feature_map')::int,
    1,
    'unlink removes the parent asset_feature_map row'
);

SELECT is(
    (SELECT count(*)::int FROM asset_feature_map WHERE schema_name = 'ws_old'),
    0,
    'no asset_feature_map rows left for the unlinked parent'
);

SELECT is(
    (SELECT count(*)::int FROM visit_x_feature),
    0,
    'visit_x_feature rows for the unlinked parent are gone'
);

SELECT is(
    (SELECT count(*)::int FROM attachment_x_feature),
    0,
    'attachment_x_feature rows for the unlinked parent are gone'
);

SELECT is(
    (SELECT count(*)::int FROM asset_feature_map WHERE schema_name = 'ud_keep'),
    1,
    'other parents stay mapped'
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
    (SELECT gw_fct_cmms_rename_parent('ud_keep', 'ud_new')::jsonb ->> 'asset_feature_map')::int,
    1,
    'rename rewrites one asset_feature_map row'
);

SELECT is(
    (SELECT schema_name FROM asset_feature_map WHERE id = 91002),
    'ud_new',
    'asset_feature_map.schema_name follows the rename'
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

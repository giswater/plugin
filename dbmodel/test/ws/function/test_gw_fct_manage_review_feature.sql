/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(10);

CREATE TEMP TABLE _rev (accept_id bigint, reject_id bigint, node_id int, old_observ text);

WITH n AS (
    SELECT node_id, observ
    FROM ve_node
    WHERE node_id IS NOT NULL
    LIMIT 1
), ins AS (
    INSERT INTO review_feature (table_name, table_id, field_changes, field_annotation)
    SELECT 'node', node_id, jsonb_build_object('observ', 'review-proposed'), 'from the field'
    FROM n
    RETURNING id, table_id
)
INSERT INTO _rev (accept_id, node_id, old_observ)
SELECT ins.id, ins.table_id, n.observ
FROM ins
JOIN n ON n.node_id = ins.table_id;

WITH ins AS (
    INSERT INTO review_feature (table_name, table_id, field_changes)
    SELECT 'node', node_id, jsonb_build_object('observ', 'review-rejected')
    FROM _rev
    RETURNING id
)
UPDATE _rev SET reject_id = (SELECT id FROM ins);

SELECT is(
    (gw_fct_manage_review_feature(json_build_object(
        'client', json_build_object('device', 4, 'lang', 'en_US', 'infoType', 1),
        'data', json_build_object('action', 'GET', 'id', (SELECT accept_id FROM _rev))
    ))::json)->>'status',
    'Accepted',
    'GET returns Accepted'
);

SELECT is(
    (
        SELECT f->>'value'
        FROM jsonb_array_elements(
            (gw_fct_manage_review_feature(json_build_object(
                'client', json_build_object('device', 4, 'lang', 'en_US', 'infoType', 1),
                'data', json_build_object('action', 'GET', 'id', (SELECT accept_id FROM _rev))
            ))::jsonb)->'body'->'data'->'fields'
        ) f
        WHERE f->>'columnname' = 'observ'
    ),
    'review-proposed',
    'GET returns the proposed observ'
);

SELECT is(
    (
        SELECT f->>'currentValue'
        FROM jsonb_array_elements(
            (gw_fct_manage_review_feature(json_build_object(
                'client', json_build_object('device', 4, 'lang', 'en_US', 'infoType', 1),
                'data', json_build_object('action', 'GET', 'id', (SELECT accept_id FROM _rev))
            ))::jsonb)->'body'->'data'->'fields'
        ) f
        WHERE f->>'columnname' = 'observ'
    ),
    COALESCE((SELECT old_observ FROM _rev), ''),
    'GET returns the current observ'
);

SELECT is(
    (gw_fct_manage_review_feature(json_build_object(
        'client', json_build_object('device', 4, 'lang', 'en_US', 'infoType', 1),
        'data', json_build_object(
            'action', 'ACCEPT',
            'id', (SELECT accept_id FROM _rev),
            'annotation', 'ok',
            'fields', json_build_object('observ', 'review-edited')
        )
    ))::json)->>'status',
    'Accepted',
    'ACCEPT returns Accepted'
);

SELECT is(
    (SELECT observ FROM ve_node WHERE node_id = (SELECT node_id FROM _rev)),
    'review-edited',
    'ACCEPT writes the edited value through the child view'
);

SELECT is(
    (SELECT status::int FROM review_feature WHERE id = (SELECT accept_id FROM _rev)),
    1,
    'ACCEPT sets status 1'
);

SELECT is(
    (gw_fct_manage_review_feature(json_build_object(
        'client', json_build_object('device', 4, 'lang', 'en_US', 'infoType', 1),
        'data', json_build_object('action', 'ACCEPT', 'id', (SELECT accept_id FROM _rev))
    ))::json)->>'status',
    'Failed',
    'A second ACCEPT on the same review fails'
);

SELECT is(
    (gw_fct_manage_review_feature(json_build_object(
        'client', json_build_object('device', 4, 'lang', 'en_US', 'infoType', 1),
        'data', json_build_object(
            'action', 'REJECT',
            'id', (SELECT reject_id FROM _rev),
            'annotation', 'no'
        )
    ))::json)->>'status',
    'Accepted',
    'REJECT returns Accepted'
);

SELECT is(
    (SELECT observ FROM ve_node WHERE node_id = (SELECT node_id FROM _rev)),
    'review-edited',
    'REJECT leaves the feature untouched'
);

SELECT is(
    (SELECT status::int FROM review_feature WHERE id = (SELECT reject_id FROM _rev)),
    2,
    'REJECT sets status 2'
);

SELECT finish();

ROLLBACK;

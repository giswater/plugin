/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(24);

CREATE TEMP TABLE _rev (node_id integer, accept_id bigint, reject_id bigint, blank_id bigint, wrapper_id bigint);
CREATE TEMP TABLE _call (j json);

INSERT INTO _rev (node_id)
SELECT node_id FROM ve_node WHERE node_id IS NOT NULL LIMIT 1;

UPDATE node SET observ = 'review-current' WHERE node_id = (SELECT node_id FROM _rev);

UPDATE _rev SET accept_id = gw_fct_core_feature_edit_request_create(
	'node',
	(SELECT node_id FROM _rev),
	'{"observ": "review-proposed", "num_value": "1.5"}'::jsonb,
	'from the field');

SELECT ok((SELECT accept_id FROM _rev) IS NOT NULL, 'create returns an id');

SELECT throws_matching(
	$$SELECT gw_fct_core_feature_edit_request_create('node', (SELECT node_id FROM _rev), '{"no_such_column": "x"}'::jsonb, NULL)$$,
	'IS NOT A COLUMN OF THIS FEATURE',
	'create rejects an unknown column');

SELECT throws_matching(
	$$SELECT gw_fct_core_feature_edit_request_create('node', (SELECT node_id FROM _rev), '{}'::jsonb, NULL)$$,
	'THE CHANGE SET IS EMPTY',
	'create rejects an empty change set');

SELECT throws_matching(
	$$SELECT gw_fct_core_feature_edit_request_create('node', -999, '{"observ": "x"}'::jsonb, NULL)$$,
	'THE FEATURE FOR THIS REVIEW WAS NOT FOUND',
	'create rejects a feature that is not visible');

UPDATE _rev SET blank_id = gw_fct_core_feature_edit_request_create(
	'node', (SELECT node_id FROM _rev), '{"observ": ""}'::jsonb, NULL);

SELECT is(
	(SELECT field_changes -> 'observ' FROM feature_edit_request WHERE id = (SELECT blank_id FROM _rev)),
	'null'::jsonb,
	'empty string is stored as null');

SELECT is(
	(SELECT current_values ->> 'observ' FROM gw_fct_core_feature_edit_request_get((SELECT accept_id FROM _rev))),
	'review-current',
	'get returns the current observ');

SELECT is(
	(SELECT field_changes ->> 'observ' FROM gw_fct_core_feature_edit_request_get((SELECT accept_id FROM _rev))),
	'review-proposed',
	'get returns the proposed observ');

SELECT ok(
	EXISTS (
		SELECT 1 FROM gw_fct_core_feature_edit_request_get_list()
		WHERE id = (SELECT accept_id FROM _rev)),
	'get_list returns the request');

UPDATE _rev SET reject_id = gw_fct_core_feature_edit_request_create(
	'node', (SELECT node_id FROM _rev), '{"observ": "review-rejected"}'::jsonb, NULL);

SELECT is(
	gw_fct_core_feature_edit_request_reject((SELECT reject_id FROM _rev), 'no'),
	true,
	'reject returns true');

SELECT is(
	(SELECT status::int FROM feature_edit_request WHERE id = (SELECT reject_id FROM _rev)),
	2,
	'reject sets status 2');

SELECT is(
	(SELECT observ FROM node WHERE node_id = (SELECT node_id FROM _rev)),
	'review-current',
	'reject leaves the feature untouched');

SELECT throws_matching(
	$$SELECT gw_fct_core_feature_edit_request_accept((SELECT accept_id FROM _rev), NULL, '{"comment": "nope"}'::jsonb)$$,
	'IS NOT PART OF THIS PROPOSAL',
	'accept rejects an override key that was not proposed');

SELECT ok(
	gw_fct_core_feature_edit_request_accept((SELECT accept_id FROM _rev), 'ok', '{"observ": "review-edited"}'::jsonb),
	'accept returns true');

SELECT is(
	(SELECT observ FROM node WHERE node_id = (SELECT node_id FROM _rev)),
	'review-edited',
	'accept merges the override and writes it');

SELECT is(
	(SELECT num_value::numeric FROM node WHERE node_id = (SELECT node_id FROM _rev)),
	1.5::numeric,
	'accept writes the typed num_value from the proposal');

SELECT is(
	(SELECT review_changes FROM feature_edit_request WHERE id = (SELECT accept_id FROM _rev)),
	jsonb_build_object('observ', 'review-edited', 'num_value', '1.5'),
	'accept stores the applied set');

SELECT throws_matching(
	$$SELECT gw_fct_core_feature_edit_request_accept((SELECT accept_id FROM _rev), NULL, NULL)$$,
	'NO LONGER PENDING',
	'a second accept on the same review fails');

INSERT INTO _call
SELECT gw_fct_manage_feature_edit_request(json_build_object(
	'client', json_build_object('device', 4, 'lang', 'en_US'),
	'data', json_build_object(
		'action', 'CREATE',
		'tableName', 'node',
		'tableId', (SELECT node_id FROM _rev),
		'annotation', 'wrap',
		'fields', json_build_object('observ', 'wrapper-proposed'))
))::json;

SELECT is((SELECT j->>'status' FROM _call), 'Accepted', 'wrapper CREATE returns Accepted');

UPDATE _rev SET wrapper_id = (SELECT (j -> 'body' -> 'data' ->> 'id')::bigint FROM _call);

DELETE FROM _call;

INSERT INTO _call
SELECT gw_fct_manage_feature_edit_request(json_build_object(
	'client', json_build_object('device', 4, 'lang', 'en_US'),
	'data', json_build_object('action', 'GET', 'id', (SELECT wrapper_id FROM _rev))
))::json;

SELECT is(
	(
		SELECT f->>'value'
		FROM _call, jsonb_array_elements((j::jsonb) -> 'body' -> 'data' -> 'fields') f
		WHERE f->>'columnname' = 'observ'
	),
	'wrapper-proposed',
	'wrapper GET returns the proposed value');

SELECT is(
	(
		SELECT f->>'currentValue'
		FROM _call, jsonb_array_elements((j::jsonb) -> 'body' -> 'data' -> 'fields') f
		WHERE f->>'columnname' = 'observ'
	),
	'review-edited',
	'wrapper GET returns the current value');

SELECT is(
	(
		SELECT f->>'appliedValue'
		FROM _call, jsonb_array_elements((j::jsonb) -> 'body' -> 'data' -> 'fields') f
		WHERE f->>'columnname' = 'observ'
	),
	'',
	'wrapper GET returns an empty applied value while pending');

DELETE FROM _call;

INSERT INTO _call
SELECT gw_fct_manage_feature_edit_request(json_build_object(
	'client', json_build_object('device', 4, 'lang', 'en_US'),
	'data', json_build_object(
		'action', 'ACCEPT',
		'id', (SELECT wrapper_id FROM _rev),
		'annotation', 'ok',
		'fields', json_build_object('observ', 'wrapper-accepted'))
))::json;

SELECT is((SELECT j->>'status' FROM _call), 'Accepted', 'wrapper ACCEPT returns Accepted');

DELETE FROM _call;

INSERT INTO _call
SELECT gw_fct_manage_feature_edit_request(json_build_object(
	'client', json_build_object('device', 4, 'lang', 'en_US'),
	'data', json_build_object('action', 'GET', 'id', (SELECT wrapper_id FROM _rev))
))::json;

SELECT is(
	(
		SELECT f->>'appliedValue'
		FROM _call, jsonb_array_elements((j::jsonb) -> 'body' -> 'data' -> 'fields') f
		WHERE f->>'columnname' = 'observ'
	),
	'wrapper-accepted',
	'wrapper GET returns the applied value after accept');

DELETE FROM _call;

INSERT INTO _call
SELECT gw_fct_manage_feature_edit_request(json_build_object(
	'client', json_build_object('device', 4, 'lang', 'en_US'),
	'data', json_build_object('action', 'ACCEPT', 'id', (SELECT wrapper_id FROM _rev))
))::json;

SELECT is((SELECT j->>'status' FROM _call), 'Failed', 'wrapper turns a second accept into Failed');

SELECT finish();

ROLLBACK;

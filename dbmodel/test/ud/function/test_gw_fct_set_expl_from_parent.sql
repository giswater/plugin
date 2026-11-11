/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(7);

SELECT has_function(
	'gw_fct_set_expl_from_parent'::name,
	ARRAY['integer', 'integer[]'],
	'Function gw_fct_set_expl_from_parent(integer, integer[]) should exist'
);

-- Sample has expl_id 1 and 2. Mark 2 as child of 1 for this transaction.
UPDATE exploitation SET parent_id = 1 WHERE expl_id = 2;

SELECT ok(
	EXISTS (SELECT 1 FROM vf_exploitation WHERE expl_id IN (1, 2)),
	'fixture: sample exploitations 1 and 2 are allowed in vf_exploitation'
);

SELECT is(
	(SELECT o_expl_id FROM gw_fct_set_expl_from_parent(1, NULL)),
	1,
	'parent exploitation keeps expl_id'
);

SELECT is(
	(SELECT o_expl_visibility FROM gw_fct_set_expl_from_parent(1, NULL)),
	NULL::integer[],
	'parent exploitation keeps null expl_visibility'
);

SELECT is(
	(SELECT o_expl_id FROM gw_fct_set_expl_from_parent(2, NULL)),
	1,
	'child exploitation remaps expl_id to parent_id'
);

SELECT is(
	(SELECT o_expl_visibility FROM gw_fct_set_expl_from_parent(2, NULL)),
	ARRAY[2]::integer[],
	'child exploitation is appended to expl_visibility'
);

SELECT is(
	(SELECT o_expl_visibility FROM gw_fct_set_expl_from_parent(2, ARRAY[2]::integer[])),
	ARRAY[2]::integer[],
	'child exploitation is not duplicated in expl_visibility'
);

SELECT throws_matching(
	$$SELECT gw_fct_set_expl_from_parent(99999, NULL)$$,
	'(?i)not allowed|4762|exploitation',
	'expl_id outside vf_exploitation raises permission error'
);

SELECT finish();
ROLLBACK;

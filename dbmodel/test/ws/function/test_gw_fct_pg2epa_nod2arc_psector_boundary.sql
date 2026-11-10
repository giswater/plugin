/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

-- Suppress NOTICE messages
SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(4);

-- Endpoint cleanup query used by gw_fct_pg2epa_nod2arc.
-- Must key off t_numarcs (temp_t_arc / psector-aware), not ve_inp_pipe.

CREATE TEMP TABLE t_numarcs (
	node_id text PRIMARY KEY,
	numarcs integer
);

-- Prefer a real SHORTPIPE from sample; fall back to any SHORTPIPE/VALVE node id
CREATE TEMP TABLE t_fixture_node AS
SELECT n.node_id, n.epa_type
FROM node n
WHERE n.epa_type IN ('SHORTPIPE', 'VALVE')
ORDER BY n.node_id
LIMIT 1;

SELECT ok(
	EXISTS (SELECT 1 FROM t_fixture_node),
	'Fixture: sample has at least one SHORTPIPE/VALVE node'
);

-- Degree 2 in EPA temp model (psector boundary: operative + planned) → keep nodarc
INSERT INTO t_numarcs (node_id, numarcs)
SELECT node_id::text, 2 FROM t_fixture_node;

CREATE TEMP TABLE t_endpoint_deg2 AS
SELECT n.node_id
FROM node n
JOIN t_numarcs t ON t.node_id = n.node_id::text
WHERE t.numarcs = 1
AND n.epa_type IN ('SHORTPIPE', 'VALVE');

SELECT is(
	(SELECT count(*) FROM t_endpoint_deg2),
	0::bigint,
	'Endpoint cleanup keeps nodarc when t_numarcs.numarcs = 2'
);

-- True dead-end (degree 1) → still eligible for nodarc drop
DELETE FROM t_numarcs;
INSERT INTO t_numarcs (node_id, numarcs)
SELECT node_id::text, 1 FROM t_fixture_node;

CREATE TEMP TABLE t_endpoint_deg1 AS
SELECT n.node_id
FROM node n
JOIN t_numarcs t ON t.node_id = n.node_id::text
WHERE t.numarcs = 1
AND n.epa_type IN ('SHORTPIPE', 'VALVE');

SELECT is(
	(SELECT count(*) FROM t_endpoint_deg1),
	1::bigint,
	'Endpoint cleanup still drops nodarc when t_numarcs.numarcs = 1'
);

SELECT is(
	(SELECT node_id FROM t_endpoint_deg1),
	(SELECT node_id FROM t_fixture_node),
	'Endpoint cleanup targets the degree-1 SHORTPIPE/VALVE node'
);

SELECT finish();

ROLLBACK;

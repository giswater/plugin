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

SELECT plan(9);

DROP TABLE IF EXISTS temp_om_scada_graph;
DROP TABLE IF EXISTS temp_om_scada_vertice;

SELECT is(
    (gw_fct_scada_graph_export($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE},
    "form":{}, "feature":{}, "data":{}}$$)::JSON)->>'status',
    'Failed',
    'gw_fct_scada_graph_export without temp_om_scada_graph returns Failed'
);

CREATE TEMP TABLE temp_om_scada_graph (LIKE om_scada_graph INCLUDING ALL);
CREATE TEMP TABLE temp_om_scada_vertice (
    node_id integer,
    group_id integer,
    row_id integer,
    column_id integer,
    column_aux integer
);

INSERT INTO temp_om_scada_graph (node_1, node_2, group_id, order_id, expl_id, active, the_geom)
VALUES
    (
        -901, -902, 10, 1, ARRAY[1], true,
        ST_Multi(ST_GeomFromText('LINESTRING(0 0, 1 1)', SRID_VALUE))
    ),
    (
        -903, -904, 20, 1, ARRAY[2], true,
        ST_Multi(ST_GeomFromText('LINESTRING(2 2, 3 3)', SRID_VALUE))
    );

INSERT INTO temp_om_scada_vertice (node_id, group_id, row_id, column_id, column_aux)
VALUES
    (-901, 10, 1, 1, 1),
    (-902, 10, 1, 2, 2),
    (-903, 20, 1, 1, 1),
    (-904, 20, 1, 2, 2);

-- Export deletes JSON rows whose group_id is gone from om_scada_graph.
ALTER TABLE om_scada_graph DISABLE TRIGGER USER;
INSERT INTO om_scada_graph (node_1, node_2, group_id, order_id, expl_id, active)
VALUES
    (-901, -902, 10, 1, ARRAY[1], true),
    (-903, -904, 20, 1, ARRAY[2], true);
ALTER TABLE om_scada_graph ENABLE TRIGGER USER;

TRUNCATE om_scada_graph_json;
INSERT INTO om_scada_graph_json (group_id, expl_id, om_scada_graph_json)
VALUES (-999, ARRAY[1], '{}'::json);

SELECT is(
    j->>'status',
    'Accepted',
    coalesce(j->'message'->>'text', 'gw_fct_scada_graph_export with temp graph returns Accepted')
)
FROM (SELECT gw_fct_scada_graph_export($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE},
    "form":{}, "feature":{}, "data":{}}$$)::JSON AS j) s;

SELECT is(
    (SELECT count(*)::int FROM om_scada_graph_json),
    2,
    'export writes one JSON row per distinct group_id'
);

SELECT is(
    (SELECT count(*)::int FROM om_scada_graph_json WHERE group_id = -999),
    0,
    'export drops JSON rows whose group_id is gone from om_scada_graph'
);

SELECT ok(
    EXISTS (SELECT 1 FROM om_scada_graph_json WHERE group_id = 10),
    'export wrote group_id 10'
);

SELECT ok(
    EXISTS (SELECT 1 FROM om_scada_graph_json WHERE group_id = 20),
    'export wrote group_id 20'
);

SELECT is(
    (SELECT expl_id FROM om_scada_graph_json WHERE group_id = 10),
    ARRAY[1]::int4[],
    'JSON row expl_id is the union of exploitations of that group'
);

SELECT is(
    (SELECT om_scada_graph_json->'links'->0->>'orderId' FROM om_scada_graph_json WHERE group_id = 10),
    NULL,
    'link JSON does not include orderId'
);

SELECT is(
    (SELECT om_scada_graph_json->'vertices'->0->>'rowId' FROM om_scada_graph_json WHERE group_id = 10),
    '1',
    'vertex JSON includes rowId'
);

SELECT * FROM finish();

ROLLBACK;

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

CREATE USER plan_user;
GRANT role_plan to plan_user;

CREATE USER epa_user;
GRANT role_epa to epa_user;

CREATE USER edit_user;
GRANT role_edit to edit_user;

CREATE USER om_user;
GRANT role_om to om_user;

CREATE USER basic_user;
GRANT role_basic to basic_user;

SELECT is(
    (gw_fct_scada_graph_build($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831},
    "form":{}, "feature":{}, "data":{"parameters":{"object_1":1109}}}$$)::JSON)->>'status',
    'Failed',
    'Check if gw_fct_scada_graph_build without object_2 returns status "Failed"'
);

SELECT is(
    (gw_fct_scada_graph_build($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831},
    "form":{}, "feature":{}, "data":{"parameters":{"object_1":1109, "object_2":1109}}}$$)::JSON)->>'status',
    'Failed',
    'Check if gw_fct_scada_graph_build with equal object_1/object_2 returns status "Failed"'
);

SELECT col_is_pk(
    'om_scada_graph',
    ARRAY['node_1', 'node_2'],
    'Table om_scada_graph should have primary key on node_1, node_2'
);

INSERT INTO om_scada_graph (node_1, node_2, expl_id, attrib)
VALUES (-999, -998, ARRAY[1, 1], '{"keep":"first"}');

SELECT throws_matching(
    $$INSERT INTO om_scada_graph (node_1, node_2) VALUES (-999, -998)$$,
    'duplicate key',
    'Check if om_scada_graph rejects duplicate node_1/node_2'
);

SELECT finish();

ROLLBACK;

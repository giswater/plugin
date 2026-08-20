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

SELECT plan(5);

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

SELECT has_index(
    'om_scada_graph',
    'om_scada_graph_object_1_object_2_uidx',
    'Table om_scada_graph should have unique index on object_1, object_2'
);

ALTER TABLE om_scada_graph DISABLE TRIGGER USER;

INSERT INTO om_scada_graph (object_1, object_2, attrib, expl_1, expl_2)
VALUES (-999, -998, '{"keep":"first"}', 1, 1);

ALTER TABLE om_scada_graph ENABLE TRIGGER USER;

SELECT is(
    (gw_fct_scada_graph_build($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831},
    "form":{}, "feature":{}, "data":{"parameters":{"object_1":-999, "object_2":-998}}}$$)::JSON)->>'status',
    'Failed',
    'Check if gw_fct_scada_graph_build rejects duplicate object_1/object_2'
);

SELECT throws_matching(
    $$INSERT INTO om_scada_graph (object_1, object_2) VALUES (-999, -998)$$,
    'already exists',
    'Check if om_scada_graph trigger rejects duplicate object_1/object_2'
);

SELECT finish();

ROLLBACK;

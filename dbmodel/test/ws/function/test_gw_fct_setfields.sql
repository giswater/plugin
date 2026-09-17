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

-- Plan for 7 tests
SELECT plan(7);

-- Create roles for testing
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

-- Extract and test the "status" field from the function's JSON response
SELECT is(
    (gw_fct_setfields($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":"132", "tableName":"ve_arc_pipe", "featureType":"arc" }, "data":{"filterFields":{},
    "pageInfo":{}, "fields":{"code": "134"}, "reload":"", "afterInsert":"False"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_arc_pipe" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setfields($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":"PUMP_01", "tableName":"ve_inp_curve" }, "data":{"filterFields":{}, "pageInfo":{},
    "fields":{"curve_type": "PUMP", "descript": "null", "expl_id": null}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_inp_curve" returns status "Accepted"'
);

-- man2inp must not null EPA tank fields when man hmax/area are NULL
UPDATE config_param_system SET value =
'{"status":true, "values":[
{"sourceTable":"ve_node_tank", "query":"UPDATE inp_inlet t SET maxlevel = CASE WHEN s.hmax IS NOT NULL THEN s.hmax ELSE t.maxlevel END, diameter = CASE WHEN s.area IS NOT NULL THEN sqrt(4 * s.area / 3.14159) ELSE t.diameter END FROM ve_node_tank s "},
{"sourceTable":"ve_node_pr_reduc_valve", "query":"UPDATE inp_valve t SET setting = CASE WHEN s.pressure_exit IS NOT NULL THEN s.pressure_exit ELSE t.setting END FROM ve_node_pr_reduc_valve s "}]}'
WHERE parameter = 'epa_automatic_man2inp_values';

UPDATE man_tank SET hmax = NULL, area = NULL WHERE node_id = 113766;
UPDATE inp_inlet SET maxlevel = 3.5, diameter = 12 WHERE node_id = 113766;

SELECT is(
    (gw_fct_setfields($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":"113766", "tableName":"ve_node_tank", "featureType":"node"},
    "data":{"filterFields":{}, "pageInfo":{}, "fields":{"top_elev": "68.24"}, "reload":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_node_tank" returns status "Accepted"'
);

SELECT is(
    (SELECT maxlevel FROM inp_inlet WHERE node_id = 113766),
    3.5::numeric,
    'setfields top_elev on ve_node_tank keeps inp_inlet.maxlevel when man hmax is NULL'
);

SELECT is(
    (SELECT diameter FROM inp_inlet WHERE node_id = 113766),
    12::numeric,
    'setfields top_elev on ve_node_tank keeps inp_inlet.diameter when man area is NULL'
);

UPDATE man_tank SET hmax = 9 WHERE node_id = 113766;

SELECT is(
    (gw_fct_setfields($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":"113766", "tableName":"ve_node_tank", "featureType":"node"},
    "data":{"filterFields":{}, "pageInfo":{}, "fields":{"top_elev": "68.24"}, "reload":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_node_tank" with hmax set returns status "Accepted"'
);

SELECT is(
    (SELECT maxlevel FROM inp_inlet WHERE node_id = 113766),
    9::numeric,
    'setfields top_elev on ve_node_tank copies man hmax to inp_inlet.maxlevel when hmax is set'
);

-- Finish the test
SELECT finish();

ROLLBACK;

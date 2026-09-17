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
SELECT is (
    (gw_fct_config_mapzones($${"client":{"device":4, "lang":"NULL", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
    "parameters": {"action": "UPDATE", "configZone": "drainzone", "mapzoneId": "-1",
    "config": {"use":[{"nodeParent":""}], "ignore":[], "forceClosed":[]}}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_config_mapzones with action "UPDATE" returns status "Accepted"'
);

SELECT is (
    (gw_fct_config_mapzones($${"client":{"device":4, "lang":"NULL", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
    "parameters": {"action": "ADD", "configZone": "drainzone", "mapzoneId": "-1", "nodeParent": "82", "toArc": [], "config": {"use":[{"nodeParent":""}], "ignore":[],
    "forceClosed":[]}}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_config_mapzones with action "ADD" and 4th parameter is "nodeParent" returns status "Accepted"'
);

SELECT is (
    (gw_fct_config_mapzones($${"client":{"device":4, "lang":"NULL", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
    "parameters": {"action": "ADD", "configZone": "drainzone", "mapzoneId": "-1", "forceClosed": ["82"], "config": {"use": [{"nodeParent": "82"}], "ignore": [],
    "forceClosed": []}}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_config_mapzones with action "ADD" and 4th parameter is "forceClosed" returns status "Accepted"'
);

SELECT is (
    ((gw_fct_config_mapzones($${"client":{"device":4, "lang":"NULL", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
    "parameters": {"action": "ADD", "configZone": "drainzone", "mapzoneId": "-1", "forceClosed": ["82"], "config": {"use": [{"nodeParent": "82"}], "ignore": [],
    "forceClosed": []}}}}$$)::json)->'body'->'data'->'preview'->'forceClosed')::text,
    '["82"]',
    'ADD forceClosed puts id 82 into preview.forceClosed'
);

SELECT is (
    (gw_fct_config_mapzones($${"client":{"device":4, "lang":"NULL", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
    "parameters": {"action": "REMOVE", "configZone": "drainzone", "mapzoneId": "-1", "nodeParent": "82", "config": {"use": [{"nodeParent": "82"}], "ignore": [],
    "forceClosed": []}}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_config_mapzones with action "REMOVE" and 4th parameter is "nodeParent" returns status "Accepted"'
);

SELECT is (
    (gw_fct_config_mapzones($${"client":{"device":4, "lang":"NULL", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
    "parameters": {"action": "REMOVE", "configZone": "drainzone", "mapzoneId": "-1", "forceClosed": ["82"],
    "config": {"use": [{"nodeParent": "82"}], "ignore": [], "forceClosed": [82]}}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_config_mapzones with action "REMOVE" and 4th parameter is "forceClosed" returns status "Accepted"'
);

SELECT is (
    ((gw_fct_config_mapzones($${"client":{"device":4, "lang":"NULL", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{},
    "parameters": {"action": "REMOVE", "configZone": "drainzone", "mapzoneId": "-1", "forceClosed": ["82"],
    "config": {"use": [{"nodeParent": "82"}], "ignore": [], "forceClosed": [82]}}}}$$)::json)->'body'->'data'->'preview'->'forceClosed')::text,
    '[]',
    'REMOVE forceClosed drops id 82 from preview.forceClosed'
);

-- Finish the test
SELECT finish();

ROLLBACK;

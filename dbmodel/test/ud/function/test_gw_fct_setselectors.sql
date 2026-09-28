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

-- Plan for 8 test
SELECT plan(8);

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
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_exploitation", "id":"1",
    "isAlone":"True", "disableParent":"False", "value":"True", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_exploitation" && "value":"True" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_exploitation", "id":"1",
    "isAlone":"True", "disableParent":"False", "value":"False", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_exploitation" && "value":"False" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_sector", "id":"$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$", "isAlone":"False",
    "disableParent":"False", "value":"True", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_sector" && "value":"True" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_sector", "id":"$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$",
    "isAlone":"False", "disableParent":"False", "value":"False", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_sector" && "value":"False" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_network_state", "id":"1",
    "isAlone":"False", "disableParent":"False", "value":"True", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_network_state" && "value":"True" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_network_state", "id":"1",
    "isAlone":"False", "disableParent":"False", "value":"False", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_network_state" && "value":"False" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_psector", "id":"1", "isAlone":"False",
    "disableParent":"False", "value":"True", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_psector" && "value":"True" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setselectors($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "tabName":"tab_psector", "id":"1", "isAlone":"False",
    "disableParent":"False", "value":"False", "addSchema":"NULL"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setselectors --> "tabName":"tab_psector" && "value":"False" returns status "Accepted"'
);

-- Finish the test
SELECT finish();

ROLLBACK;
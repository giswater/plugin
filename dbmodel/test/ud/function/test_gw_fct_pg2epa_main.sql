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
SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 1}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=1 returns status "Accepted"'
);

SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 2}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=2 returns status "Accepted"'
);

SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 3}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=3 returns status "Accepted"'
);

SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 4}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=4 returns status "Accepted"'
);

SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 5}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=5 returns status "Accepted"'
);

SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 6}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=6 returns status "Accepted"'
);

SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 7}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=7 returns status "Accepted"'
);

-- BASIC NETWORK WITH INVALID CRS

UPDATE config_param_user SET value = '2' WHERE parameter = 'inp_options_networkmode' AND cur_user = current_user;

-- Extract and test the "status" field from the function's JSON response
SELECT is(
    (gw_fct_pg2epa_main($${"client":{"device":4, "lang":"", "infoType":1, "epsg":4326}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "resultId":"testing", "dumpSubcatch":"False", "step": 1}}$$)::JSON)->>'status',
    'Failed',
    'Check if gw_fct_pg2epa_main: dumpSubcatch=False | step=1 returns status "Failed" with invalid CRS'
);


-- Finish the test
SELECT finish();

ROLLBACK;

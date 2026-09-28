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

SELECT plan(16);

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
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '2' AND sector_id > 0) || $$", "action":"INSERT-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 2 and action > INSERT-ONLY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '2' AND sector_id > 0) || $$", "action":"DELETE-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 2 and action > DELETE-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '2' AND sector_id > 0) || $$", "action":"KEEP-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 2 and action > KEEP-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '2' AND sector_id > 0) || $$", "action":"DELETE-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 2 and action > DELETE-ONLY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$", "action":"INSERT-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 1 and action > INSERT-ONLY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$", "action":"DELETE-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 1 and action > DELETE-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$", "action":"KEEP-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 1 and action > KEEP-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector": "$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$", "action":"DELETE-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 1 and action > DELETE-ONLY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"0", "action":"INSERT-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 0 and action > INSERT-ONLY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"0", "action":"DELETE-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 0 and action > DELETE-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"0", "action":"KEEP-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 0 and action > KEEP-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"0", "action":"DELETE-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > 0 and action > DELETE-ONLY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"-999", "action":"INSERT-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > -999 and action > INSERT-ONLY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"-999", "action":"DELETE-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > -999 and action > DELETE-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"-999", "action":"KEEP-COPY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > -999 and action > KEEP-COPY returns status "Accepted"'
);

SELECT is(
    (gw_fct_manage_dwf_values($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"target":"1", 
    "sector":"-999", "action":"DELETE-ONLY", "copyFrom":"1"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_manage_dwf_values with sector > -999 and action > DELETE-ONLY returns status "Accepted"'
);

-- Finish the test
SELECT finish();

ROLLBACK;

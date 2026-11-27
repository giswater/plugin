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

-- Plan for 6 tests
SELECT plan(6);

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

UPDATE cat_feature
SET code_autofill = false, custom_code_autofill = false
WHERE id = 'REDUCTION';

UPDATE node SET code = 'KEEPME' WHERE node_id = '1111';

-- Extract and test the "status" field from the function's JSON response
SELECT is (
    (gw_fct_setchangefeaturetype($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"type":"node"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_id":"1111", "feature_type_new":"REDUCTION",
    "featurecat_id":"REDUC_110-63 PN16"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setchangefeaturetype returns status "Accepted"'
);

SELECT is (
    (SELECT code FROM node WHERE node_id = '1111'),
    'KEEPME',
    'Code stays when custom_code_autofill and code_autofill are false'
);

UPDATE cat_feature
SET code_autofill = true, custom_code_autofill = false
WHERE id = 'HYDRANT';

UPDATE node SET code = 'KEEPME' WHERE node_id = '1111';

SELECT is (
    (gw_fct_setchangefeaturetype($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"type":"node"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_id":"1111", "feature_type_new":"HYDRANT",
    "featurecat_id":"HYDRANT 1X110"}}$$)::JSON)->>'status',
    'Accepted',
    'Change feature type is accepted when only code_autofill is true'
);

SELECT is (
    (SELECT code FROM node WHERE node_id = '1111'),
    '1111',
    'Code copies the feature id when code_autofill is true and custom_code_autofill is false'
);

UPDATE cat_feature
SET custom_code_autofill = true, abbreviation = 'HYD'
WHERE id = 'HYDRANT';

UPDATE node SET code = 'KEEPME' WHERE node_id = '1111';

SELECT is (
    (gw_fct_setchangefeaturetype($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"type":"node"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_id":"1111", "feature_type_new":"HYDRANT",
    "featurecat_id":"HYDRANT 1X110"}}$$)::JSON)->>'status',
    'Accepted',
    'Change feature type is accepted when custom_code_autofill is true'
);

SELECT matches (
    (SELECT code FROM node WHERE node_id = '1111'),
    '^HYD_[0-9]{8}$',
    'Code is cleared and regenerated when cat_feature.custom_code_autofill is true'
);

-- Finish the test
SELECT finish();

ROLLBACK;
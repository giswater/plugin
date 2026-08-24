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

-- Plan for 3 tests
SELECT plan(3);

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
    (gw_fct_setfeaturereplace($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{"type":"arc"},
    "data":{"filterFields":{}, "pageInfo":{}, "old_feature_id":"154", "feature_type_new":"WACCEL", "featurecat_id":"WACCEL-CC020",
    "workcat_id_end":"work1", "enddate":"2024-08-27", "keep_elements":"False", "keep_epa_values":"True", "keep_asset_id":"True"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfeaturereplace returns status "Accepted"'
);

-- Column itself NULL (the real bug): disable/restore must not rewrite invalid JSON.
-- UD connec replace cannot be used here: ve_connec has no epa_type.
UPDATE config_param_system SET value = NULL WHERE parameter = 'edit_gully_proximity';

SELECT is(
    (gw_fct_setfeaturereplace($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{"type":"gully"},
    "data":{"filterFields":{}, "pageInfo":{}, "old_feature_id":"30080", "feature_type_new":"GINLET", "featurecat_id":"SGRT3",
    "workcat_id_end":"work1", "enddate":"2024-08-27", "keep_elements":"False", "keep_epa_values":"False"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfeaturereplace gully returns status "Accepted" when edit_gully_proximity is NULL'
);

SELECT ok(
    (SELECT value FROM config_param_system WHERE parameter = 'edit_gully_proximity') IS NULL,
    'gw_fct_setfeaturereplace restores edit_gully_proximity when the column is NULL'
);

-- Finish the test
SELECT finish();

ROLLBACK;

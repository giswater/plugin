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

-- Plan for 2 tests
SELECT plan(2);

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

UPDATE config_param_system SET value = NULL WHERE parameter = 'edit_arc_searchnodes';

-- Extract and test the "status" field from the function's JSON response
SELECT is(
    (gw_fct_setfeaturereplace($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{}, "feature":{"type":"arc"},
    "data":{"filterFields":{}, "pageInfo":{}, "old_feature_id":"113854", "feature_type_new":"PIPE", "featurecat_id":"FD150",
    "workcat_id_end":"work1", "enddate":"2017-12-06", "keep_elements":"False", "keep_epa_values":"False"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfeaturereplace returns status "Accepted"'
);

SELECT isnull(
    (SELECT value FROM config_param_system WHERE parameter = 'edit_arc_searchnodes'),
    'gw_fct_setfeaturereplace restores edit_arc_searchnodes when the column is NULL'
);

-- Finish the test
SELECT finish();

ROLLBACK;

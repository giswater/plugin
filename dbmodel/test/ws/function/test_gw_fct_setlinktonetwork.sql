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

-- Plan for 5 tests
SELECT plan(5);

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
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{"id":"[3099, 3098, 3101]"},
    "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setlinktonetwork returns status "Accepted"'
);

CREATE TEMP TABLE _t_connec_3099 AS
SELECT arc_id FROM connec WHERE connec_id = 3099;

UPDATE arc SET fluid_type = NULL WHERE arc_id = (SELECT arc_id FROM _t_connec_3099);
UPDATE arc SET fluid_type = 'St. Fluid'
WHERE arc_id = (
    SELECT a.arc_id FROM arc a
    JOIN connec c ON c.connec_id = 3099
    WHERE a.state > 0 AND a.arc_id IS DISTINCT FROM c.arc_id
    ORDER BY ST_Distance(a.the_geom, c.the_geom)
    LIMIT 1
);

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["3099"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC",
    "extraFilters":{"fluid_type":"St. Fluid"}}}$$)::JSON)->>'status',
    'Accepted',
    'CONNEC extraFilters without forceReconnect returns status Accepted'
);

SELECT is (
    (SELECT arc_id FROM connec WHERE connec_id = 3099),
    (SELECT arc_id FROM _t_connec_3099),
    'CONNEC extraFilters without forceReconnect does not move an existing link'
);

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["3099"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC",
    "forceReconnect":true, "extraFilters":{"fluid_type":"St. Fluid"}}}$$)::JSON)->>'status',
    'Accepted',
    'CONNEC extraFilters.fluid_type returns status Accepted'
);

SELECT is (
    (SELECT a.fluid_type FROM connec c JOIN arc a ON a.arc_id = c.arc_id WHERE c.connec_id = 3099),
    'St. Fluid',
    'CONNEC extraFilters.fluid_type links to an arc with matching fluid_type'
);

-- Finish the test
SELECT finish();

ROLLBACK;
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

SELECT plan(12);

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
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":"[3095, 3094, 3091, 3090]"}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setlinktonetwork returns status "Accepted"'
);

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["3095"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC", "forceNode":true}}$$)::JSON)->>'status',
    'Accepted',
    'CONNEC forceNode returns status Accepted'
);

SELECT is (
    (SELECT exit_type FROM link WHERE feature_id = 3095 AND feature_type = 'CONNEC' AND state > 0 ORDER BY link_id DESC LIMIT 1),
    'NODE',
    'CONNEC forceNode creates link with exit_type NODE'
);

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["3094"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC", "forcedNodes":["84"]}}$$)::JSON)->>'status',
    'Accepted',
    'CONNEC forcedNodes returns status Accepted'
);

SELECT is (
    (SELECT exit_type FROM link WHERE feature_id = 3094 AND feature_type = 'CONNEC' AND state > 0 ORDER BY link_id DESC LIMIT 1),
    'NODE',
    'CONNEC forcedNodes creates link with exit_type NODE'
);

SELECT is (
    (SELECT exit_id::text FROM link WHERE feature_id = 3094 AND feature_type = 'CONNEC' AND state > 0 ORDER BY link_id DESC LIMIT 1),
    '84',
    'CONNEC forcedNodes sets exit_id to the forced node'
);

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["30014"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"GULLY", "forceNode":true}}$$)::JSON)->>'status',
    'Accepted',
    'GULLY forceNode returns status Accepted'
);

SELECT is (
    (SELECT exit_type FROM link WHERE feature_id = 30014 AND feature_type = 'GULLY' AND state > 0 ORDER BY link_id DESC LIMIT 1),
    'NODE',
    'GULLY forceNode creates link with exit_type NODE'
);

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["30014"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"GULLY", "forcedNodes":["49"]}}$$)::JSON)->>'status',
    'Accepted',
    'GULLY forcedNodes returns status Accepted'
);

SELECT is (
    (SELECT exit_type FROM link WHERE feature_id = 30014 AND feature_type = 'GULLY' AND state > 0 ORDER BY link_id DESC LIMIT 1),
    'NODE',
    'GULLY forcedNodes creates link with exit_type NODE'
);

SELECT is (
    (SELECT exit_id::text FROM link WHERE feature_id = 30014 AND feature_type = 'GULLY' AND state > 0 ORDER BY link_id DESC LIMIT 1),
    '49',
    'GULLY forcedNodes sets exit_id to the forced node'
);

SELECT isnt (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["3091"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC",
    "forcedNodes":["84"], "forcedArcs":["210"]}}$$)::JSON)->>'status',
    'Accepted',
    'forcedNodes + forcedArcs does not return Accepted'
);

SELECT finish();

ROLLBACK;

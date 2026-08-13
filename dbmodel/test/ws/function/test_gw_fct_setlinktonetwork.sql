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

-- Extract and test the "status" field from the function's JSON response
SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{}, "feature":{"id":"[3099, 3098, 3101]"},
    "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setlinktonetwork returns status "Accepted"'
);

UPDATE link SET userdefined_geom = TRUE
WHERE feature_id = 3099 AND feature_type = 'CONNEC' AND state > 0;

CREATE TEMP TABLE _t_arc_3099 AS
SELECT arc_id FROM connec WHERE connec_id = 3099;

CREATE TEMP TABLE _t_link_3099 AS
SELECT exit_id, the_geom FROM link
WHERE feature_id = 3099 AND feature_type = 'CONNEC' AND state > 0
LIMIT 1;

CREATE TEMP TABLE _t_other_arc_3099 AS
SELECT a.arc_id::text AS arc_id
FROM ve_arc a
JOIN connec c ON c.connec_id = 3099
WHERE a.state > 0
  AND a.arc_id IS DISTINCT FROM c.arc_id
ORDER BY ST_Distance(a.the_geom, c.the_geom)
LIMIT 1;

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["3099"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC",
    "forceReconnect":true}}$$)::JSON)->>'status',
    'Accepted',
    'forceReconnect with userdefined_geom TRUE returns Accepted'
);

SELECT is (
    (SELECT arc_id FROM connec WHERE connec_id = 3099),
    (SELECT arc_id FROM _t_arc_3099),
    'forceReconnect does not move a link with userdefined_geom TRUE'
);

SELECT is (
    (gw_fct_setlinktonetwork(format(
        $${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
        "feature":{"id":["3099"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC",
        "forcedArcs":["%s"], "forceReconnect":true}}$$,
        (SELECT arc_id FROM _t_other_arc_3099)
    ))::JSON)->>'status',
    'Accepted',
    'forcedArcs with userdefined_geom TRUE returns Accepted'
);

SELECT ok (
    (SELECT l.exit_id IS NOT DISTINCT FROM s.exit_id AND ST_Equals(l.the_geom, s.the_geom)
     FROM link l, _t_link_3099 s
     WHERE l.feature_id = 3099 AND l.feature_type = 'CONNEC' AND l.state > 0
     LIMIT 1),
    'forcedArcs does not change a link with userdefined_geom TRUE'
);

UPDATE link SET userdefined_geom = FALSE
WHERE feature_id = 3099 AND feature_type = 'CONNEC' AND state > 0;

SELECT is (
    (gw_fct_setlinktonetwork($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":["3099"]}, "data":{"filterFields":{}, "pageInfo":{}, "feature_type":"CONNEC",
    "forceReconnect":true}}$$)::JSON)->>'status',
    'Accepted',
    'forceReconnect with userdefined_geom FALSE returns Accepted'
);

-- TODO
-- gw_fct_setlinktonetwork
-- SELECT gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
-- "feature":{"id":["3201","3200"]},"data":{"feature_type":"CONNEC", "forcedArcs":["2001","2002"]}}$$);

-- SELECT gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
-- "feature":{"id":["100013"]},"data":{"feature_type":"CONNEC"}}$$);

-- SELECT gw_fct_setlinktonetwork($${"client":{"device":4, "infoType":1, "lang":"ES"},
-- "feature":{"id":["100014"]},"data":{"feature_type":"GULLY"}}$$);



-- Finish the test
SELECT finish();

ROLLBACK;
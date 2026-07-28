/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(2);

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

UPDATE presszone
SET graphconfig = '{"use":[{"nodeParent":"1106", "toArc":[2095]}], "ignore":[], "forceClosed":[]}'::json
WHERE presszone_id = '4';

SELECT gw_fct_settoarc($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
"feature":{"featureType":"PR_REDUC_VALVE", "id":"1083"}, "data":{"filterFields":{}, "pageInfo":{},
"arcId":"2089", "dmaId":"2", "presszoneId":"4", "sectorId":"3", "dqaId":"1"}}$$);

SELECT ok(
    NOT EXISTS (
        SELECT 1
        FROM presszone p
        CROSS JOIN json_array_elements((p.graphconfig->>'use')::json) elem
        WHERE p.presszone_id = '4'
          AND (elem->>'nodeParent')::int4 = 1083
    ),
    'gw_fct_settoarc does not append nodeParent to presszone graphconfig when absent'
);

UPDATE presszone
SET graphconfig = '{"use":[{"nodeParent":"1083", "toArc":[2095]}], "ignore":[], "forceClosed":[]}'::json
WHERE presszone_id = '4';

SELECT gw_fct_settoarc($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
"feature":{"featureType":"PR_REDUC_VALVE", "id":"1083"}, "data":{"filterFields":{}, "pageInfo":{},
"arcId":"2089", "dmaId":"2", "presszoneId":"4", "sectorId":"3", "dqaId":"1"}}$$);

SELECT is (
    (SELECT json_array_elements_text((elem->>'toArc')::json)
     FROM presszone p
     CROSS JOIN json_array_elements((p.graphconfig->>'use')::json) elem
     WHERE p.presszone_id = '4'
       AND (elem->>'nodeParent')::int4 = 1083
     LIMIT 1),
    '2089',
    'gw_fct_settoarc updates toArc in presszone graphconfig when nodeParent already exists'
);

SELECT finish();

ROLLBACK;

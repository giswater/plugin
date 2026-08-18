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

-- Plan for 14 test
SELECT plan(14);

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
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_node", "id":"89"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_node returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_connec", "id":"3149"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_connec returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_gully", "id":"30087"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_gully returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_arc", "id":"204"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_arc returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_link", "id":"550"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_link returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_drainzone", "id": "0"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_drainzone with id returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_drainzone"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_drainzone returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"inp_dscenario_outfall", "id": "1, 18888"},
    "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> inp_dscenario_outfall returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_cat_dscenario", "id":"1"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_cat_dscenario returns status "Accepted"'
);

-- Mapzone manager CREATE form: PK empty / not editable; array fields default to Undefined (0)
SELECT is(
    (SELECT f->>'value'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_drainzone"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'drainzone_id'),
    '',
    've_drainzone INSERT drainzone_id value is empty'
);

SELECT is(
    (SELECT f->>'ismandatory'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_drainzone"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'drainzone_id'),
    'false',
    've_drainzone INSERT drainzone_id is not mandatory'
);

SELECT is(
    (SELECT f->>'iseditable'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_drainzone"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'drainzone_id'),
    'false',
    've_drainzone INSERT drainzone_id is not editable'
);

SELECT ok(
    COALESCE((
        SELECT bool_and(
            (f->>'ismandatory') = 'false'
            AND f->>'selectedId' = '0'
            AND EXISTS (SELECT 1 FROM json_array_elements_text(f->'comboIds') x WHERE x = '0')
        )
        FROM json_array_elements((
            gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
            "feature":{"tableName":"ve_drainzone"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
        )->'body'->'data'->'fields') f
        WHERE f->>'columnname' IN ('expl_id', 'sector_id', 'muni_id')
          AND f->>'widgettype' = 'multiple_option'
    ), false),
    've_drainzone INSERT array fields default to Undefined (0) and are not mandatory'
);

SELECT is(
    (SELECT f->>'value'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_sector"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'sector_id'),
    '',
    've_sector INSERT sector_id value is empty'
);

-- Finish the test
SELECT * FROM finish();

ROLLBACK;

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

-- Plan for 20 test
SELECT plan(20);

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
    "feature":{"tableName":"ve_node", "id":"1051"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_connec", "id":"3156"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_arc", "id":"2028"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_link", "id":"413"}, "data":{"filterFields":{}, "pageInfo":{}, "addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"plan_netscenario_dma", "id": "1, 2"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"plan_netscenario_dma" returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_plan_netscenario_presszone", "isLayer":true},
    "data":{"filterFields":{}, "pageInfo":{}, "infoType":"full"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_plan_netscenario_presszone" returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_sector"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_sector" returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_sector", "id": "2"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_sector" with id returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_dma"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_dma" returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_dma", "id": "2"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_dma" with id returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_dqa"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_dqa" returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_dqa", "id": "2"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_dqa" with id returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"inp_dscenario_demand", "id": "1, 113959"},
    "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"inp_dscenario_demand" with id returns status "Accepted"'
);

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"tableName":"ve_cat_dscenario", "id":"1"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid --> "tableName":"ve_cat_dscenario" with id returns status "Accepted"'
);

-- Mapzone manager CREATE form: PK empty / not editable; array fields default to Undefined (0)
SELECT is(
    (SELECT f->>'value'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_dma"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'dma_id'),
    '',
    've_dma INSERT dma_id value is empty'
);

SELECT is(
    (SELECT f->>'ismandatory'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_dma"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'dma_id'),
    'false',
    've_dma INSERT dma_id is not mandatory'
);

SELECT is(
    (SELECT f->>'iseditable'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_dma"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'dma_id'),
    'false',
    've_dma INSERT dma_id is not editable'
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
            "feature":{"tableName":"ve_dma"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
        )->'body'->'data'->'fields') f
        WHERE f->>'columnname' IN ('expl_id', 'sector_id', 'muni_id')
          AND f->>'widgettype' = 'multiple_option'
    ), false),
    've_dma INSERT array fields default to Undefined (0) and are not mandatory'
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

SELECT is(
    (SELECT f->>'iseditable'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_sector"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'sector_id'),
    'false',
    've_sector INSERT sector_id is not editable'
);

-- Finish the test
SELECT finish();

ROLLBACK;

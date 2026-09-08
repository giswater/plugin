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

-- Plan for 24 test
SELECT plan(24);

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

-- GENELEM identified from parent ve_element must get Set Geom, not Set To Arc
CREATE TEMP TABLE _genelem_info ON COMMIT DROP AS
SELECT gw_fct_getinfofromid(json_build_object(
    'client', json_build_object('device', 4, 'lang', 'es_ES', 'infoType', 1, 'epsg', 25831),
    'form', json_build_object(),
    'feature', json_build_object('tableName', 've_element', 'id', s.gid),
    'data', json_build_object()
))::json AS j
FROM (
    SELECT e.element_id::text AS gid
    FROM element e
    JOIN cat_element ce ON ce.id::text = e.elementcat_id::text
    JOIN cat_feature cf ON cf.id::text = ce.element_type::text
    WHERE upper(cf.feature_class) = 'GENELEM'
    LIMIT 1
) s;

SELECT ok(
    EXISTS (SELECT 1 FROM _genelem_info)
    AND EXISTS (
        SELECT 1
        FROM _genelem_info,
             json_array_elements(
                 CASE WHEN json_typeof(j->'body'->'form'->'visibleTabs') = 'array'
                      THEN j->'body'->'form'->'visibleTabs' ELSE '[]'::json END
             ) t
        LEFT JOIN LATERAL json_array_elements(
            CASE WHEN json_typeof(t->'tabactions') = 'array' THEN t->'tabactions' ELSE '[]'::json END
        ) a ON true
        WHERE t->>'tabName' = 'tab_data'
          AND a->>'actionName' = 'actionSetGeom'
    ),
    'GENELEM info from ve_element parent includes actionSetGeom'
);

SELECT ok(
    EXISTS (SELECT 1 FROM _genelem_info)
    AND NOT EXISTS (
        SELECT 1
        FROM _genelem_info,
             json_array_elements(
                 CASE WHEN json_typeof(j->'body'->'form'->'visibleTabs') = 'array'
                      THEN j->'body'->'form'->'visibleTabs' ELSE '[]'::json END
             ) t
        LEFT JOIN LATERAL json_array_elements(
            CASE WHEN json_typeof(t->'tabactions') = 'array' THEN t->'tabactions' ELSE '[]'::json END
        ) a ON true
        WHERE t->>'tabName' = 'tab_data'
          AND a->>'actionName' = 'actionSetToArc'
    ),
    'GENELEM info from ve_element parent does not include actionSetToArc'
);

-- ELEMENT INSERT: ownercat_id from exploitation.owner_vdefault (same as node/arc/connec)
UPDATE exploitation SET owner_vdefault = 'owner1' WHERE expl_id = 1;
INSERT INTO config_param_user (parameter, value, cur_user)
VALUES ('edit_exploitation_vdefault', '1', current_user)
ON CONFLICT (parameter, cur_user) DO UPDATE SET value = '1';

SELECT is(
    (SELECT f->>'selectedId'
     FROM json_array_elements((
         gw_fct_getinfofromid($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
         "feature":{"tableName":"ve_element_ecover"}, "data":{"filterFields":{}, "pageInfo":{}}}$$)::json
     )->'body'->'data'->'fields') f
     WHERE f->>'columnname' = 'ownercat_id'),
    'owner1',
    've_element_ecover INSERT ownercat_id defaults from exploitation.owner_vdefault'
);

INSERT INTO ve_element_ecover (elementcat_id, expl_id, code, the_geom)
SELECT 'COVER40X40', 1, 'OWNERCAT_VDEFAULT_TEST', n.the_geom
FROM node n
WHERE n.expl_id = 1 AND n.the_geom IS NOT NULL
LIMIT 1;

SELECT is(
    (SELECT e.ownercat_id FROM element e WHERE e.code = 'OWNERCAT_VDEFAULT_TEST'),
    'owner1',
    've_element_ecover trigger fills ownercat_id from exploitation.owner_vdefault'
);

-- Finish the test
SELECT finish();

ROLLBACK;

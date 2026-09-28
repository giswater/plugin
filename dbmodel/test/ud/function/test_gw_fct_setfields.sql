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

-- Plan for 4 test
SELECT plan(4);

-- Extract and test the "status" field from the function's JSON response
SELECT is(
    (gw_fct_setfields($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":"100019", "tableName":"ve_node_jump", "featureType":"node" },
    "data":{"filterFields":{}, "pageInfo":{}, "fields":{"nodecat_id": "JUMP-01",
    "workcat_id": "work2", "expl_id": 1, "muni_id": 1}, "reload":"", "afterInsert":"False"}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_node_jump" returns status "Accepted"'
);

SELECT is (
    (gw_fct_setfields($${"client":{"device":4, "lang":"", "infoType":1, "epsg":25831}, "form":{},
    "feature":{"id":"T10-5m", "tableName":"ve_inp_timeseries" }, "data":{"filterFields":{}, "pageInfo":{},
    "fields":{"expl_id": 1, "timser_type": "Rainfall", "times_type": "RELATIVE", "descript":
    "null", "fname": "null"}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_inp_timeseries" returns status "Accepted"'
);

-- PSECTOR TESTS
UPDATE config_param_user SET value = NULL WHERE "parameter" = 'plan_psector_current' AND cur_user = current_user;

-- setfields with psector active (replace node)
INSERT INTO ve_plan_psector ( "name", descript, priority, text1, text2, observ, rotation, "scale", atlas_id, gexpenses, vat, other, the_geom, expl_id, psector_type, active, ext_code, status, text3, text4, text5, text6, num_value, workcat_id, parent_id)
VALUES('-901', 'Test psector for setfields', '2', NULL, NULL, 'Test psector for setfields', 0.0000, 750.00, '01', 19.00, 21.00, 0.00, 'SRID=25831;MULTIPOLYGON (((419209.60503196524 4576553.424854076, 419209.60503196524 4576503.357122214, 419089.7020131364 4576503.357122214, 419089.7020131364 4576553.424854076, 419209.60503196524 4576553.424854076)))'::public.geometry, 1, 1, true, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

DELETE FROM selector_psector WHERE cur_user = current_user;
UPDATE config_param_user SET value = (SELECT psector_id::text FROM ve_plan_psector WHERE name = '-901')
WHERE "parameter" = 'plan_psector_current' AND cur_user = current_user;
INSERT INTO selector_psector (psector_id, cur_user) VALUES ((SELECT psector_id FROM ve_plan_psector WHERE name = '-901'), current_user);

SELECT is (
    (gw_fct_setfields($${"client":{"device":4, "lang":"en_US", "version":"4.8.1", "infoType":1, "epsg":25831}, "form":{}, 
    "feature":{"id":"100055", "tableName":"ve_node_junction", "featureType":"node" }, "data":{"filterFields":{}, "pageInfo":{}, 
    "fields":{"sector_id": "$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$", "dwfzone_id": "$$ || (SELECT dwfzone_id::text FROM dwfzone WHERE code = '1' AND dwfzone_id > 0) || $$", "state": "2", "state_type": "3", "code": "100055", "workcat_id": "work1", 
    "builtdate": "2026/04/07", "unconnected": "False", "soilcat_id": "soil1", "expl_id": "1", "brand_id": "brand3", "model_id": "model4", 
    "muni_id": "1", "node_type": "JUNCTION", "epa_type": "JUNCTION", "nodecat_id": "JUNCTION-01",
    "the_geom": "Point (419100.72600000002421439 4576521.49000000022351742)"}, "reload":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_node_junction" (Active psector) returns status "Accepted"'
);

-- setfields with psector active (add new node and setarcdivide)
INSERT INTO ve_plan_psector ( "name", descript, priority, text1, text2, observ, rotation, "scale", atlas_id, gexpenses, vat, other, the_geom, expl_id, psector_type, active, ext_code, status, text3, text4, text5, text6, num_value, workcat_id, parent_id)
VALUES('-902', 'Test psector for setfields with arcdivide', '2', NULL, NULL, 'Test psector for setfields', 0.0000, 750.00, '01', 19.00, 21.00, 0.00, 'SRID=25831;MULTIPOLYGON (((419209.60503196524 4576553.424854076, 419209.60503196524 4576503.357122214, 419089.7020131364 4576503.357122214, 419089.7020131364 4576553.424854076, 419209.60503196524 4576553.424854076)))'::public.geometry, 1, 1, true, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

UPDATE config_param_user SET value = NULL WHERE "parameter" = 'plan_psector_current' AND cur_user = current_user;
DELETE FROM selector_psector WHERE cur_user = current_user;
UPDATE config_param_user SET value = (SELECT psector_id::text FROM ve_plan_psector WHERE name = '-902')
WHERE "parameter" = 'plan_psector_current' AND cur_user = current_user;
INSERT INTO selector_psector (psector_id, cur_user) VALUES ((SELECT psector_id FROM ve_plan_psector WHERE name = '-902'), current_user);

SELECT is (
    (gw_fct_setfields($${"client":{"device":4, "lang":"en_US", "version":"4.8.1", "infoType":1, "epsg":25831}, "form":{}, 
    "feature":{"id":"100058", "tableName":"ve_node_junction", "featureType":"node" }, "data":{"filterFields":{}, "pageInfo":{}, 
    "fields":{"sector_id": "$$ || (SELECT sector_id::text FROM sector WHERE code = '1' AND sector_id > 0) || $$", "dwfzone_id": "$$ || (SELECT dwfzone_id::text FROM dwfzone WHERE code = '1' AND dwfzone_id > 0) || $$", "state": "2", "state_type": "3", "code": "100058", "workcat_id": "work1", 
    "builtdate": "2026/04/07", "unconnected": "False", "soilcat_id": "soil1", "expl_id": "1", "brand_id": "brand3", "model_id": "model4", 
    "muni_id": "1", "node_type": "JUNCTION", "epa_type": "JUNCTION", "nodecat_id": "JUNCTION-01", 
    "the_geom": "Point (419105.49698512122267857 4576544.63723930902779102)"}, "reload":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_setfields --> "tableName":"ve_node_junction" (Active psector) returns status "Accepted"'
);


-- Finish the test
SELECT finish();

ROLLBACK;

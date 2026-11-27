/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(7);

INSERT INTO selector_state (state_id, cur_user)
SELECT s.id, current_user FROM value_state s
ON CONFLICT (state_id, cur_user) DO NOTHING;

INSERT INTO selector_expl (expl_id, cur_user)
SELECT e.expl_id, current_user FROM exploitation e
ON CONFLICT (expl_id, cur_user) DO NOTHING;

INSERT INTO selector_sector (sector_id, cur_user)
SELECT s.sector_id, current_user FROM sector s
ON CONFLICT (sector_id, cur_user) DO NOTHING;

UPDATE config_param_system
SET value = '{"catfeatureId":["SHUTOFF_VALVE"], "vdefault":{"valve_type":"TCV", "setting":0, "custom_dint":0.001, "minorloss":0.001, "status":"OPEN"}}'
WHERE parameter = 'epa_valve_vdefault_tcv';

INSERT INTO ve_node_shutoff_valve (code, nodecat_id, epa_type, state, state_type, expl_id, sector_id, the_geom, closed, broken)
VALUES ('-9901', 'SHTFF-VALVE160-PN16', 'VALVE', 1, 2, 2,
    (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0),
    'SRID=25831;POINT (418467.84 4577973.48)'::public.geometry,
    false, false);

SELECT is((SELECT valve_type FROM inp_valve WHERE node_id = (SELECT node_id FROM node WHERE code = '-9901')),
    'TCV', 'insert VALVE copies valve_type from epa_valve_vdefault_tcv');
SELECT ok((SELECT setting = 0 FROM inp_valve WHERE node_id = (SELECT node_id FROM node WHERE code = '-9901')),
    'insert VALVE copies setting');
SELECT ok((SELECT custom_dint = 0.001 FROM inp_valve WHERE node_id = (SELECT node_id FROM node WHERE code = '-9901')),
    'custom_dint is copied from the vdefault key of the same name');
SELECT ok((SELECT minorloss = 0.001 FROM inp_valve WHERE node_id = (SELECT node_id FROM node WHERE code = '-9901')),
    'minorloss is copied');
SELECT is((SELECT status FROM ve_inp_valve WHERE node_id = (SELECT node_id FROM node WHERE code = '-9901')),
    'ACTIVE', 'status stays computed: closed false, broken false, TCV -> ACTIVE');

UPDATE config_param_system
SET value = '{"catfeatureId":["SHUTOFF_VALVE"], "vdefault":{"valve_type":"TCV", "setting":0}}'
WHERE parameter = 'epa_valve_vdefault_tcv';

INSERT INTO ve_node_shutoff_valve (code, nodecat_id, epa_type, state, state_type, expl_id, sector_id, the_geom, closed, broken)
VALUES ('-9903', 'SHTFF-VALVE160-PN16', 'SHORTPIPE', 1, 2, 2,
    (SELECT sector_id FROM sector WHERE code = '5' AND sector_id > 0),
    'SRID=25831;POINT (418469.84 4577973.48)'::public.geometry,
    false, false);

UPDATE ve_node_shutoff_valve SET epa_type = 'VALVE' WHERE code = '-9903';

SELECT is((SELECT valve_type FROM inp_valve WHERE node_id = (SELECT node_id FROM node WHERE code = '-9903')),
    'TCV', 'changing epa_type to VALVE applies valve_type');
SELECT ok((SELECT setting = 0 FROM inp_valve WHERE node_id = (SELECT node_id FROM node WHERE code = '-9903')),
    'changing epa_type to VALVE applies setting');

SELECT finish();

ROLLBACK;

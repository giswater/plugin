/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = cm, public, pg_catalog;

grant role_addon_cm_admin to current_user;

INSERT INTO cat_organization (organization_id, code, orgname, descript, active) VALUES(1, '123123', 'OWNER', 'OWNER ORGANIZATION', true);
INSERT INTO cat_organization (organization_id, code, orgname, descript, active) VALUES(2, '123123', 'ORG1', 'EXTERNAL ORGANIZATION', true);
INSERT INTO cat_organization (organization_id, code, orgname, descript, active) VALUES(3, '123123', 'ORG2', 'EXTERNAL ORGANIZATION', true);

INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(1, '1234512345', 'ADMIN', 1, 'admin team', 'role_addon_cm_admin', true);
INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(2, '1234512345', 'o1_manager', 2, 'manager team of org 1', 'role_addon_cm_manager', true);
INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(3, '1234512345', 'o2_manager', 3, 'manager team of org 2', 'role_addon_cm_manager', true);
INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(4, '1234512345', 'o1_field1', 2, 'field team of org1', 'role_addon_cm_field', true);
INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(5, '1234512345', 'o1_field2', 2, 'field team of org1', 'role_addon_cm_field', true);
INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(6, '1234512345', 'o2_field1', 3, 'field team of org2', 'role_addon_cm_field', true);
INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(7, '1234512345', 'o2_field2', 3, 'field team of org2', 'role_addon_cm_field', true);
INSERT INTO cat_team (team_id, code, teamname, organization_id, descript, role_id, active) VALUES(8, '1234512345', 'team_edit', 1, 'team edit', 'role_addon_cm_edit', true);


-- Team administrator
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(1, 'agarcia', 1, true),
(2, 'ssanchez', 1, true);

-- Team: Manager o1
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(3, 'jperis', 2, true),
(4, 'msierra', 2, true),
(5, 'o1_manager', 2, true);

-- Team: Manager o2
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(6, 'atorres', 3, true),
(7, 'cfuentes', 3, true),
(8, 'o2_manager', 3, true);

-- Team: o1 field 1
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(9, 'lblanco', 4, true),
(10, 'dferrer', 4, true),
(11, 'o1_field1', 4, true);

-- Team: o1 field 2
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(12, 'ngallart', 5, true),
(13, 'omartin', 5, true),
(14, 'o1_field2', 5, true);

-- Team: o2 field 1
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(15, 'iramos', 6, true),
(16, 'pablo', 6, true),
(17, 'o2_field1', 6, true);

-- Team: o2 field 2
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(18, 'cgil', 7, true),
(19, 'rbueno', 7, true),
(20, 'o2_field2', 7, true);

-- Easy user for test in local
INSERT INTO cat_user (user_id, username, team_id, active) VALUES
(21, 'postgres', 1, true),
(22, 'bgeoadmin', 1, true);

-- Reset sequences
SELECT setval('cat_organization_organization_id_seq', (SELECT MAX(organization_id) FROM cat_organization), true);
SELECT setval('cat_team_team_id_seq', (SELECT MAX(team_id) FROM cat_team), true);
SELECT setval('cat_user_user_id_seq', (SELECT MAX(user_id) FROM cat_user), true);

INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active) VALUES(200, 'Check users consistence', 'cm', NULL, 'core', true, 'Check cm', NULL, 3, 'There are some users with no team assigned.', NULL, NULL, 'SELECT * FROM cat_user WHERE team_id IS NULL', 'All users have a team assigned.', '[gw_fct_cm_check_project]', true) ON CONFLICT DO NOTHING;
INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active) VALUES(201, 'Check teams consistence', 'cm', NULL, 'core', true, 'Check cm', NULL, 3, 'teams with no users assigned.', NULL, NULL, 'SELECT * FROM cat_team ct WHERE NOT EXISTS (SELECT 1 FROM cat_user cu WHERE ct.team_id = cu.team_id)', 'All teams have users assigned.', '[gw_fct_cm_check_project]', true) ON CONFLICT DO NOTHING;
INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active) VALUES(202, 'Check orphan nodes', 'cm', NULL, 'core', true, 'Check cm', NULL, 3, 'There are some orphan nodes', 'cm_node', NULL, 'SELECT a.node_id, a.nodecat_id, a.expl_id, a.the_geom FROM PARENT_SCHEMA.ve_node a JOIN PARENT_SCHEMA.cat_node nc ON nodecat_id=id JOIN PARENT_SCHEMA.cat_feature_node nt ON nt.id=nc.node_type JOIN PARENT_SCHEMA.node ON node.node_id = a.node_id WHERE a.state > 0 AND isarcdivide = ''false'' AND node.arc_id IS null', 'There aren''t orphan nodes.', '[gw_fct_cm_check_project]', true) ON CONFLICT DO NOTHING;
INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active) VALUES(203, 'Check duplicated nodes', 'cm', NULL, 'core', true, 'Check cm', NULL, 3, 'nodes duplicated with state 1.', 'cm_node', NULL, 'SELECT * FROM  (SELECT DISTINCT t1.node_id, t1.nodecat_id, t1.state AS state1, t2.node_id AS node_2, t2.nodecat_id AS nodecat_2, t2.state as state2, t1.expl_id, 106, t1.the_geom FROM PARENT_SCHEMA.node AS t1 JOIN PARENT_SCHEMA.node AS t2 ON ST_Dwithin(t1.the_geom, t2.the_geom, 0.01) WHERE t1.node_id != t2.node_id ORDER BY t1.node_id ) a where a.state1 = 1 AND a.state2 = 1', 'There are no nodes duplicated with state 1', '[gw_fct_cm_check_project]', true) ON CONFLICT DO NOTHING;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = 'SCHEMA_NAME', public, pg_catalog;

INSERT INTO sys_function VALUES (2888, 'gw_fct_fill_om_tables','ws','function','void','void','Create example visits (used on sample creation)','role_admin',false);
INSERT INTO sys_function VALUES (2918, 'gw_fct_fill_doc_tables','ws','function','void','void','Create example documents (used on sample creation)','role_admin',false);
UPDATE sys_function SET input_params ='void', return_type ='void' WHERE id =2888;
UPDATE sys_function SET input_params ='void', return_type ='void' WHERE id =2918;

INSERT INTO cat_users VALUES ('user1','user1');
INSERT INTO cat_users VALUES ('user2','user2');
INSERT INTO cat_users VALUES ('user3','user3');
INSERT INTO cat_users VALUES ('user4','user4');

INSERT INTO config_graph_mincut VALUES (113766);
INSERT INTO config_graph_mincut VALUES (113952);

INSERT INTO plan_psector_x_node VALUES (2, '1076', 1, 0, false, NULL, NULL);

INSERT INTO plan_psector_x_connec (connec_id, arc_id, psector_id, state, doable, link_id) VALUES ('3103', '2087', 1, 0, false, 480);
INSERT INTO plan_psector_x_connec (connec_id, arc_id, psector_id, state, doable, link_id) VALUES ('3104', '2078', 1, 0, false, 479);

INSERT INTO plan_psector_x_connec (connec_id, arc_id, psector_id, state, doable, link_id) VALUES ('3014', '2065', 2, 0, false, 473);

UPDATE plan_psector_x_arc SET psector_id = 2 WHERE arc_id = '20651';

INSERT INTO plan_psector_x_arc VALUES (7, '2065', 2, 0, false, NULL, NULL);
INSERT INTO plan_psector_x_arc VALUES (8, '2085', 1, 0, false, NULL, NULL);
INSERT INTO plan_psector_x_arc VALUES (9, '2086', 1, 0, false, NULL, NULL);

INSERT INTO doc (code, "name", doc_type, "path", observ, "date", user_name, tstamp, the_geom) VALUES('Demo document 1', 'Demo document 1', 'OTHER', 'https://github.com/giswater/docs/blob/master/user/manual_usuario_giswater3.doc', NULL, '2018-03-11 19:40:20.449', current_user, '2018-03-11 19:40:20.449', NULL);
INSERT INTO doc (code, "name", doc_type, "path", observ, "date", user_name, tstamp, the_geom) VALUES('Demo document 3', 'Demo document 2', 'OTHER', 'https://github.com/giswater/giswater/blob/master-2.1/legal/Licensing.txt', NULL, '2018-03-14 17:09:59.762', current_user, '2018-03-14 17:09:59.762', NULL);
INSERT INTO doc (code, "name", doc_type, "path", observ, "date", user_name, tstamp, the_geom) VALUES('Demo document 2', 'Demo document 3', 'OTHER', 'https://github.com/giswater/giswater/blob/master-2.1/legal/Readme.txt', NULL, '2018-03-14 17:09:19.852', current_user, '2018-03-14 17:09:19.852', NULL);

ALTER TABLE om_visit DISABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_arc DISABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_node DISABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_connec DISABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_link DISABLE TRIGGER gw_trg_om_visit;

SELECT gw_fct_fill_doc_tables();
SELECT gw_fct_fill_om_tables();

ALTER TABLE om_visit ENABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_arc ENABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_node ENABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_connec ENABLE TRIGGER gw_trg_om_visit;
ALTER TABLE om_visit_x_link ENABLE TRIGGER gw_trg_om_visit;

UPDATE om_visit set "status"="status";

INSERT INTO doc_x_visit (doc_id, visit_id)
SELECT
doc.id,
om_visit.id
FROM doc, om_visit;

INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('hydrant_param_1','combo1','combo1');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('hydrant_param_1','combo2','combo2');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('hydrant_param_1','combo3','combo3');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('hydrant_param_1','combo4','combo4');

INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('pressmeter_param_1','1','combo1');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('pressmeter_param_1','2','combo2');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('pressmeter_param_1','3','combo3');

INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('shtvalve_param_1','1','combo1');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('shtvalve_param_1','2','combo2');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('shtvalve_param_1','3','combo3');
INSERT INTO edit_typevalue(typevalue, id, idval) VALUES('shtvalve_param_1','4','combo4');

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"OUTFALL_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"outfallvalve_param_1", "datatype":"text",
"widgettype":"text", "label":"Outvalve param_1","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"OUTFALL_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"outfallvalve_param_2", "datatype":"boolean",
"widgettype":"check", "label":"Outvalve param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"SHUTOFF_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"shtvalve_param_1", "datatype":"text",
"widgettype":"combo", "label":"Shtvalve param_1","ismandatory":"False",
"active":"True", "iseditable":"True", "dv_isnullvalue":"True","layoutname":"lyt_data_1",
"dv_querytext":"SELECT id as id, idval as idval  FROM edit_typevalue WHERE typevalue='shtvalve_param_1'"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"SHUTOFF_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"shtvalve_param_2", "datatype":"text",
"widgettype":"text", "label":"Shtvalve param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"GREEN_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"greenvalve_param_1", "datatype":"boolean",
"widgettype":"check", "label":"Gvalve param_1","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"GREEN_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"greenvalve_param_2", "datatype":"text",
"widgettype":"text", "label":"Gvalve param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"AIR_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"airvalve_param_1", "datatype":"text",
"widgettype":"text", "label":"Airvalve param_1","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"AIR_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"airvalve_param_2", "datatype":"integer",
"widgettype":"text", "label":"Airvalve param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"CHECK_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"checkvalve_param_1", "datatype":"integer",
"widgettype":"text", "label":"Check param_1","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"CHECK_VALVE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"checkvalve_param_2", "datatype":"text",
"widgettype":"text", "label":"Check param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"PIPE"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"pipe_param_1", "datatype":"text",
"widgettype":"text", "label":"Pipe param_1","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"PRESSURE_METER"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"pressmeter_param_1", "datatype":"text",
"widgettype":"combo", "label":"Pressmeter param_1","ismandatory":"False",
"active":"True", "iseditable":"True", "dv_isnullvalue":"True","layoutname":"lyt_data_1",
"dv_querytext":"SELECT id as id, idval as idval  FROM edit_typevalue WHERE typevalue='pressmeter_param_1'"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"PRESSURE_METER"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"pressmeter_param_2", "datatype":"date",
"widgettype":"datetime", "label":"Pressmeter param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"FILTER"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"filter_param_1", "datatype":"integer",
"widgettype":"text", "label":"Filter param_1","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"FILTER"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"filter_param_2", "datatype":"text",
"widgettype":"text", "label":"Filter param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"TANK"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"tank_param_1", "datatype":"integer",
"widgettype":"text", "label":"Tank param_1","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"TANK"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"tank_param_2", "datatype":"date",
"widgettype":"datetime", "label":"Tank param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"HYDRANT"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"hydrant_param_1", "datatype":"text",
"widgettype":"combo", "label":"Hydrant param_1","ismandatory":"False",
"active":"True", "iseditable":"True", "dv_isnullvalue":"True","layoutname":"lyt_data_1",
"dv_querytext":"SELECT id as id, idval as idval  FROM edit_typevalue WHERE typevalue='hydrant_param_1'"}}}$$);

SELECT gw_fct_admin_manage_addfields($${"client":{"lang":"ES"}, "feature":{"catFeature":"HYDRANT"},
"data":{"action":"CREATE", "multiCreate":"false", "parameters":{"columnname":"hydrant_param_2", "datatype":"integer",
"widgettype":"text", "label":"Hydrant param_2","ismandatory":"False",
"active":"True", "iseditable":"True","layoutname":"lyt_data_1"}}}$$);

INSERT INTO sys_foreignkey(typevalue_table, typevalue_name, target_table, target_field) VALUES ('edit_typevalue','hydrant_param_1','man_node_hydrant','hydrant_param_1');
INSERT INTO sys_foreignkey(typevalue_table, typevalue_name, target_table, target_field) VALUES ('edit_typevalue','shtvalve_param_1','man_node_shutoff_valve','shtvalve_param_1');
INSERT INTO sys_foreignkey(typevalue_table, typevalue_name, target_table, target_field) VALUES ('edit_typevalue','pressmeter_param_1','man_node_pressure_meter','pressmeter_param_1');

-- rotate vnodes and connec labels
INSERT INTO config_param_user (parameter, value, cur_user) VALUES ('edit_link_connecrotation_update', TRUE, current_user) ON CONFLICT (parameter, cur_user) DO NOTHING;

SELECT gw_fct_admin_manage_triggers('fk','ALL');

UPDATE config_param_user SET value = 'TRUE' WHERE parameter = 'audit_project_user_control';

UPDATE config_param_system SET value = '{"SECTOR":true, "DMA":true, "PRESSZONE":true, "DQA":true, "MINSECTOR":true}'
WHERE parameter = 'om_dynamicmapzones_status';

UPDATE element SET code = concat ('E',element_id);

UPDATE config_graph_mincut SET parameters = '{"inletArc":["113907", "113905"]}'
WHERE node_id = '113766';

UPDATE config_graph_mincut SET parameters = '{"inletArc":["114145"]}'
WHERE node_id = '113952';

-- refactor of type's
UPDATE man_type_fluid SET fluid_type = replace (fluid_type, 'Standard', 'St.');
UPDATE man_type_category SET category_type = replace (category_type, 'Standard', 'St.');
UPDATE man_type_location SET location_type = replace (location_type, 'Standard', 'St.');
UPDATE man_type_function SET function_type = replace (function_type, 'Standard', 'St.');

UPDATE ve_node SET nodecat_id = 'CHK-VALVE100-PN16' WHERE node_id = '1092';
UPDATE man_valve SET to_arc=2037 WHERE node_id=1092;

UPDATE ve_arc SET arccat_id = 'VIRTUAL' WHERE arc_type = 'VARC';

UPDATE cat_mat_roughness set roughness  = 0.003;
DELETE FROM cat_arc WHERE arc_type = 'VARC' AND id !='VIRTUAL';

UPDATE config_param_system SET value='TRUE' WHERE parameter='sys_raster_dem';

INSERT INTO config_param_user (parameter, value, cur_user) VALUES ('edit_insert_elevation_from_dem', 'true', current_user)
ON CONFLICT (parameter, cur_user) DO NOTHING;

INSERT INTO config_param_user (parameter, value, cur_user) VALUES ('edit_update_elevation_from_dem', 'true', current_user)
ON CONFLICT (parameter, cur_user) DO NOTHING;

UPDATE config_param_user SET value = 'TRUE' WHERE parameter = 'qgis_form_docker' AND cur_user = current_user;

UPDATE sys_param_user SET dv_querytext = replace (dv_querytext, ' arc_type', ' cat_feature_arc') WHERE dv_querytext like'% arc_type%';
UPDATE sys_param_user SET dv_querytext = replace (dv_querytext, ' node_type', ' cat_feature_node') WHERE dv_querytext like'% node_type%';
UPDATE sys_param_user SET dv_querytext = replace (dv_querytext, ' connec_type', ' cat_feature_connec') WHERE dv_querytext like'% connec_type%';
UPDATE sys_param_user SET dv_querytext = replace (dv_querytext, ' gully_type', ' cat_feature_gully') WHERE dv_querytext like'% gully_type%';

-- 2020/12/07
UPDATE sys_param_user SET vdefault ='{"reservoir":{"switch2Junction":["WTP", "WATERWELL", "SOURCE"]},
"tank":{"distVirtualReservoir":0.01},
"pressGroup":{"status":"ACTIVE", "forceStatus":"ACTIVE", "defaultCurve":"GP30"},
"pumpStation":{"status":"CLOSED", "forceStatus":"CLOSED", "defaultCurve":"IM00"},
"PRV":{"status":"ACTIVE", "forceStatus":"ACTIVE", "pressure":"30"},
"PSV":{"status":"ACTIVE", "forceStatus":"ACTIVE", "pressure":"30"}
}'
WHERE id = 'inp_options_buildup_supply';


UPDATE config_param_system SET value = 'false' WHERE parameter = 'admin_utils_schema';

UPDATE config_info_layer SET addparam = '{"forceWhenActive":true}' WHERE layer_id IN ('v_edit_dimensions','v_edit_om_visit');

UPDATE config_param_system SET value = '{"activated" : "TRUE", "updateField" : "top_elev"}' WHERE parameter  = 'admin_raster_dem';

INSERT INTO config_param_user (parameter, value, cur_user) VALUES ('om_visit_status_vdefault', '4', current_user) ON CONFLICT (parameter, cur_user) DO NOTHING;

-- fill missed data for connecs
UPDATE ve_connec SET epa_type = 'JUNCTION';
UPDATE connec SET epa_type = 'UNDEFINED' where epa_type is null;
ALTER TABLE connec ALTER COLUMN epa_type SET NOT NULL;

UPDATE cat_mat_roughness SET roughness = 0.0025 WHERE matcat_id IN ('PVC', 'PE-HD', 'PE-LD');
UPDATE cat_mat_roughness SET roughness = 0.025 WHERE matcat_id IN ('FC');

SELECT setval('SCHEMA_NAME.urn_id_seq', gw_fct_setvalurn(),true);

INSERT INTO config_param_user VALUES ('edit_pavement_vdefault','Asphalt',current_user);

INSERT INTO plan_arc_x_pavement (arc_id, pavcat_id, percent) VALUES ('2001', 'Slab', 0.5);
INSERT INTO plan_arc_x_pavement (arc_id, pavcat_id, percent) VALUES ('2001', 'Concrete', 0.5);

SELECT gw_fct_admin_schema_lastprocess($${"client":{"lang":"ES"},
"data":{"isNewProject":"FALSE", "projectType":"WS", "epsg":25831, "isSample":"TRUE"}}$$);

INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('1', '10240C', NULL, 'Calle de la Mare de Deu de Montserrat', NULL, '0105000020E7640000010000000102000000140000001B100C6B6A991941DFEB69D952755141E2F80131EA981941D1D777B5497551414AF890C3B898194130F24C4346755141AE94C41E9F9819413053B08B44755141F03517FF84981941D99C90DB42755141E2C0688540981941021414F13E755141820FFC619D97194157F27B0136755141A726769C7297194106F1BEA9337551419CB6B622489719415088454D317551416B2475C13E971941AE0BA4CF30755141387077EB349719418E27F259307551418FBBEEA82A9719414B50C3EC2F75514107DD2A07209719414EFAAA882F7551410787751215971941AA372C2E2F755141FB6B18D709971941FF55A9DD2E75514191626362FE96194157DE63972E7551414E9CD147EF961941C817DF4C2E75514124CC840ED7961941A2C128182E7551418CAFC115BB961941A79349F82D755141A6CB3FA438961941D8E10D682E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('2', '10222C', NULL, 'Calle de Menorca', NULL, '0105000020E7640000010000000102000000020000005D078893C89219412E2FCA23A17551413CAC9708CB9119411C0093E588755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('3', '9120C', NULL, 'Calle de Narcis Monturiol', NULL, '0105000020E764000001000000010200000002000000800E100D9D921941217BA4DD677551414C31EF5247921941982B5D944D755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('4', '10120C', NULL, 'Calle de Galicia', NULL, '0105000020E76400000100000001020000000200000010EEF0EDDB9419419ABAFD8060755141BCE65DF967941941DA65B2893D755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('5', '10110C', NULL, 'Calle de Federico Garcia Lorca', NULL, '0105000020E7640000010000000102000000140000002CE506F7F39419415A28873A3E7551413F1567D4D494194137F48E0434755141ABAFC137D39419413D280F8733755141654E216AD1941941EA825E0A33755141441BE06BCF94194178D28A8E327551411940583DCD94194113E5A11332755141BFE6E3DECA941941F188B199317551410E39DD50C8941941458CC72031755141D9609E93C594194147BDF1A830755141F78781A7C29419411DEA3D323075514142D8E08CBF94194106E1B9BC2F7551418E7B1644BC9419412E7073482F755141B39B7CCDB8941941C96578D52E75514187626D29B59419410B90D6632E755141E3F94258B194194127BD9BF32D7551419A8B575AAD94194150BBD5842D75514184410530A9941941B75892172D7551417945A6D9A49419419063DFAB2C755141C145A6D9A49419418D63DFAB2C755141EA8DCDC4D2931941273B8CF318755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('6', '9110C', NULL, 'Calle de Josep Trueta', NULL, '0105000020E764000001000000010200000002000000BF04B100CB9219412566A62A487551413468CCBDBF9119417157E5072F755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('7', '11011C', NULL, 'Calle de Salvador Seguí', NULL, '0105000020E76400000100000001020000000300000090AA14799F961941F6BB84D4777551414219E1DA5F96194151BDE6C25E755141F60D831258961941ECDBCDB15B755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('8', '11011C', NULL, 'Calle de Salvador Seguí', NULL, '0105000020E764000001000000010200000003000000F60D831258961941ECDBCDB15B75514119F927FB55961941343BC69758755141B33E760F44961941F92064033E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('9', '11011C', NULL, 'Calle de Salvador Seguí', NULL, '0105000020E764000001000000010200000003000000B33E760F44961941F92064033E75514149DD61FC419619412624B4EF3A755141A6CB3FA438961941D8E10D682E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('10', '11011C', NULL, 'Calle de Salvador Seguí', NULL, '0105000020E764000001000000010200000002000000A6CB3FA438961941D8E10D682E755141286A6F7E12961941473470D5F7745141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('11', '10000C', NULL, 'Ronda de Sant Ramon', NULL, '0105000020E76400000100000001020000002300000062E62BFDBC911941523E6A1AAF755141CCE42BFDBC911941423E6A1AAF755141D4493088BF91194125A5C2D6AE755141AB038821C29119411CECB793AE755141601A14C9C49119413F234C51AE755141FE95B57EC7911941A85A810FAE755141917E4D42CA91194173A259CEAD75514120DCBC13CD911941B20AD78DAD755141BCB6E4F2CF91194183A3FB4DAD7551416C16A6DFD2911941FC7CC90EAD7551413C03E2D9D59119413AA742D0AC755141368579E1D89119414D326992AC75514169A44DF6DB911941532E3F55AC755141DA683F18DF91194168ABC618AC7551419BDA2F47E2911941A0B901DDAB755141B2010083E59119411469F2A1AB7551412CE690CBE8911941DEC99A67AB7551411590C320EC91194116ECFC2DAB75514174077982EF911941D4DF1AF5AA7551415A5492F0F291194132B5F6BCAA755141D07EF06AF6911941497C9285AA755141E08E74F1F99119413045F04EAA755141958CFF83FD91194100201219AA755141FB7F722201921941D21CFAE3A97551411B71AECC04921941BF4BAAAFA97551410268948208921941E0BC247CA9755141BC6C05440C9219414A806B49A97551415387E210109219411FA68017A9755141D3BF0CE9139219416E3E66E6A8755141441E65CC1792194152591EB6A8755141B6AACCBA1B921941E506AB86A8755141316D24B41F92194143570E58A8755141C06D4DB8239219417D5A4A2AA875514170B428C727921941B12061FDA77551415D078893C89219412E2FCA23A1755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('12', '10000C', NULL, 'Ronda de Sant Ramon', NULL, '0105000020E764000001000000010200000003000000E09D7E3A2B941941D9A68927927551419619A4F4899519415ED072658375514190AA14799F961941F6BB84D477755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('13', '10000C', NULL, 'Ronda de Sant Ramon', NULL, '0105000020E76400000100000001020000000400000090AA14799F961941F6BB84D4777551419F37A4F7489719418D1ECB84707551410DEDAD31D0971941E3C34E6F69755141E6D9A197879819418D3FA3515F755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('14', '10000C', NULL, 'Ronda de Sant Ramon', NULL, '0105000020E764000001000000010200000002000000E6D9A197879819418D3FA3515F7551411B100C6B6A991941DFEB69D952755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('15', '10000C', NULL, 'Ronda de Sant Ramon', NULL, '0105000020E7640000010000000102000000050000001B100C6B6A991941DFEB69D952755141FFED9533AE991941CDB6D44A4F755141CA5F099EC099194143BF686B4E755141941BDC47029A1941679266854B755141D0665324279B1941EF8568543F755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('16', '10000C', NULL, 'Ronda de Sant Ramon', NULL, '0105000020E7640000010000000102000000020000005D078893C89219412E2FCA23A1755141E09D7E3A2B941941D9A6892792755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('17', '9150C', NULL, 'Avenida de la Torre de la Vila', NULL, '0105000020E764000001000000010200000007000000D0665324279B1941EF8568543F755141DE2CF73C6B9A194180F66EFD34755141A1618D4689991941F9F95F8328755141CD79AB21DB981941A9AADCF41E755141A4060C86F19719418B40D836127551411A5C5476BB961941CC8CE52B01755141286A6F7E12961941473470D5F7745141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('18', '9150C', NULL, 'Avenida de la Torre de la Vila', NULL, '0105000020E764000001000000010200000002000000286A6F7E12961941473470D5F77451416C9A075CC99519415751C7CAF3745141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('19', '10100C', NULL, 'Calle Legalitat', NULL, '0105000020E764000001000000010200000005000000B7370B5483901941F2C101E75E755141CD9EAC72A7901941F07410645E7551419166F054B79019416C97B6075E7551414EF2115CC6901941AC2896875D7551414C31EF5247921941982B5D944D755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('20', '10100C', NULL, 'Calle Legalitat', NULL, '0105000020E7640000010000000102000000020000004C31EF5247921941982B5D944D755141BF04B100CB9219412566A62A48755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('21', '10100C', NULL, 'Calle Legalitat', NULL, '0105000020E764000001000000010200000006000000BF04B100CB9219412566A62A487551416C1029506F931941BE13389A417551412DE90DA3839319413B2F010141755141B8FFF922A3931941F8ACAB4240755141D23DC4A93B9419418168090A3E755141BCE65DF967941941DA65B2893D755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('22', '10100C', NULL, 'Calle Legalitat', NULL, '0105000020E764000001000000010200000002000000BCE65DF967941941DA65B2893D7551412CE506F7F39419415A28873A3E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('23', '10100C', NULL, 'Calle Legalitat', NULL, '0105000020E7640000010000000102000000030000002CE506F7F39419415A28873A3E7551413C8DCAEF4995194129C91FA73E755141B33E760F44961941F92064033E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('24', '11000C', NULL, 'Avenida del General Prim', NULL, '0105000020E764000001000000010200000003000000E6D9A197879819418D3FA3515F7551415A87A044B196194108E22BE85B755141F60D831258961941ECDBCDB15B755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('25', '11000C', NULL, 'Avenida del General Prim', NULL, '0105000020E764000001000000010200000002000000F60D831258961941ECDBCDB15B75514110EEF0EDDB9419419ABAFD8060755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('26', '11000C', NULL, 'Avenida del General Prim', NULL, '0105000020E76400000100000001020000000200000010EEF0EDDB9419419ABAFD8060755141309A57A831931941977E6CF965755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('27', '11000C', NULL, 'Avenida del General Prim', NULL, '0105000020E764000001000000010200000002000000309A57A831931941977E6CF965755141800E100D9D921941217BA4DD67755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('28', '11000C', NULL, 'Avenida del General Prim', NULL, '0105000020E764000001000000010200000002000000800E100D9D921941217BA4DD677551418DA0BB7289901941FAACF9B96E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('29', '10230C', NULL, 'Calle de Francesc Layret', NULL, '0105000020E764000001000000010200000004000000E09D7E3A2B941941D9A6892792755141903A2D02959319416344324884755141F62A94128E9319413487A7738375514178CDD6728C931941E4C12A3483755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('30', '10230C', NULL, 'Calle de Francesc Layret', NULL, '0105000020E76400000100000001020000000400000078CDD6728C931941E4C12A3483755141F23B2DD688931941BC3E04938275514100AD85648593194118A9A8AB81755141309A57A831931941977E6CF965755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('31', '10220C', NULL, 'Calle de Salvador Espriu', NULL, '0105000020E76400000100000001020000000300000078CDD6728C931941E4C12A3483755141FCFC6E08CB911941101E8FE5887551418D9F5708CB9119412A6A8FE588755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('32', '10220C', NULL, 'Calle de Salvador Espriu', NULL, '0105000020E7640000010000000102000000020000008D9F5708CB9119412A6A8FE588755141296CDFA595901941385F3AD58C755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('33', '9100C', NULL, 'Avenida de Aragó', NULL, '0105000020E76400000100000001020000000F00000062E62BFDBC911941523E6A1AAF755141305BD9D090911941F29C07B9AD7551416EA023D66E91194151CDBEFAAC755141B898EE6435911941D1200EC9AB755141366233181A9119418DA4681DAB755141CFD48F4F00911941872D693DAA755141D0E0659BE8901941C320A12EA97551418ECC1FE4DF9019411ADD07A5A875514130059D7FCB9019411B8CEE24A77551418BC6CFD2BA901941292C1A95A57551414B630485AF90194148B0E138A4755141B3D14439A59019411F43992CA275514140DFBD4C9F901941E44D0D0DA075514190B30758999019416CCECB6396755141296CDFA595901941385F3AD58C755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('34', '9100C', NULL, 'Avenida de Aragó', NULL, '0105000020E764000001000000010200000002000000296CDFA595901941385F3AD58C7551418DA0BB7289901941FAACF9B96E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('35', '9100C', NULL, 'Avenida de Aragó', NULL, '0105000020E7640000010000000102000000020000008DA0BB7289901941FAACF9B96E755141B7370B5483901941F2C101E75E755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('36', '9100C', NULL, 'Avenida de Aragó', NULL, '0105000020E764000001000000010200000016000000B7370B5483901941F2C101E75E755141A3A2A9167890194122FF4CC03F75514111A5946879901941CEE8D0703E755141C8E497697E901941192E92433D75514180B2A04083901941E0BDC7C93C7551413C7B998E84901941071FADA73C755141321F5FEB85901941860539863C755141EB10AD56879019411ED76F653C755141C44B40D088901941C1FA55453C75514117CBD5578A90194158D7EF253C755141418A2AED8B901941D9D341073C7551419D84FB8F8D9019412F5750E93B75514187B505408F90194150C81FCC3B7551415A1806FD90901941228EB4AF3B75514173A8B9C692901941A10F13943B7551412D61DD9C94901941B0B33F793B755141E03D2E7F9690194146E13E5F3B755141ED39696D9890194150FF14463B755141AD504B679A901941BD74C62D3B755141797D916C9C9019417FA857163B755141B2BBF87C9E9019418201CDFF3A7551419567CCBDBF9119415357E5072F755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('37', '9100C', NULL, 'Avenida de Aragó', NULL, '0105000020E7640000010000000102000000040000009567CCBDBF9119415357E5072F7551415F7A4D5CB993194108B25F3F1A7551410CD8EAF7C6931941F53ABA9B197551414B8DCDC4D2931941093B8CF318755141', 1, 1);
INSERT INTO om_streetaxis (id, code, type, name, text, the_geom, expl_id, muni_id) VALUES ('38', '9100C', NULL, 'Avenida de Aragó', NULL, '0105000020E7640000010000000102000000250000004B8DCDC4D2931941093B8CF318755141BE8443B3D99319419C401D84187551414D5C32DCE4931941C325D8B5177551410A478F655095194146A2C822FA745141FC87F663969519416987A796F4745141D7441A8D97951941F7331980F47451417F0EF3C2989519417CE77F6AF47451414547F2049A9519416CDCDD55F4745141755189529B951941444D3542F47451415F8F29AB9C9519417574882FF47451414D63440E9E951941758CD91DF4745141922F4B7B9F951941BFCF2A0DF47451417B56AFF1A0951941C6787EFDF3745141533AE270A295194102C2D6EEF37451416A3D55F8A3951941ECE535E1F37451410CC27987A5951941F31E9ED4F3745141892AC11DA795194196A711C9F374514130D99CBAA895194149BA92BEF37451414B307E5DAA951941809123B5F37451412992D605AC951941B267C6ACF37451411C6117B3AD9519415C777DA5F37451416DFFB164AF951941EBFA4A9FF37451416DCF171AB1951941DE2C319AF37451416933BAD2B2951941A5473296F3745141AD8D0A8EB4951941BF855093F374514189407A4BB695194198218E91F37451414BAE7A0AB8951941AE55ED90F374514140397DCAB9951941795C7091F3745141B743F38ABB95194167701993F3745141FF2F4E4BBD951941F5CBEA95F37451416160FF0ABF9519419AA9E699F3745141313778C9C0951941CA430F9FF3745141B9162A86C295194100D566A5F374514147618640C4951941AB97EFACF37451412C79FEF7C59519414BC6ABB5F3745141B1C003ACC79519414C9B9DBFF37451416C8E045CC9951941063DC7CAF3745141', 1, 1);


UPDATE config_csv SET active = true WHERE fid in (469,470);

UPDATE config_param_system SET value = '{"usePsectors":false, "ignoreGraphanalytics":false, "ignoreEpa":false, "ignorePlan":false}'
WHERE parameter = 'admin_checkproject';

UPDATE config_param_system SET value = (replace(value, 'Disable', 'Random')) WHERE parameter='utils_graphanalytics_style';

UPDATE man_hydrant set customer_code = concat('cc', node_id);

INSERT INTO sys_style (layername, styleconfig_id, styletype) VALUES ('ve_arc', 106, 'qml') ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO sys_style (layername, styleconfig_id, styletype) VALUES ('ve_arc', 107, 'qml') ON CONFLICT (layername, styleconfig_id) DO NOTHING;
INSERT INTO sys_style (layername, styleconfig_id, styletype) VALUES ('ve_arc', 108, 'qml') ON CONFLICT (layername, styleconfig_id) DO NOTHING;


update node set verified=2 where node_id in ('1084', '113957', '114227', '114230', '42');

-- 15/04/2025
INSERT INTO man_pipelink (link_id) SELECT link_id FROM link l;

-- 01/10/2025
UPDATE config_param_system SET value = '{"version": 6, "usePgrouting": true, "bufferType": 2, "geomParamUpdate":10}'
WHERE parameter = 'om_mincut_config';

-- 08/05/2026
UPDATE config_param_system
SET value='{"sys_pk": "arc_id", "sys_fct": "gw_fct_getinfofromid", "sys_geom": "the_geom", "sys_filter": "", "sys_tablename": "arc join vf_arc using (arc_id)", "sys_display_name": "concat(arc_id, '' : '', arccat_id)", "sys_fct_tablename": "ve_arc"}'
WHERE "parameter"='basic_search_v2_tab_network_arc';
UPDATE config_param_system
SET value='{"sys_pk": "connec_id", "sys_fct": "gw_fct_getinfofromid", "sys_geom": "the_geom", "sys_filter": "", "sys_tablename": "connec join vf_connec vf using (connec_id)", "sys_search_name": "concat(connec_id, '' '', code)", "sys_display_name": "concat(connec_id, '' : finca-> '', code,'' (expl: '',expl_id,'')'')", "sys_fct_tablename": "ve_connec"}'
WHERE "parameter"='basic_search_v2_tab_network_connec';
UPDATE config_param_system
SET value='{"sys_pk": "node_id", "sys_fct": "gw_fct_getinfofromid", "sys_geom": "the_geom", "sys_filter": "", "sys_tablename": "node join vf_node vf using (node_id)", "sys_search_name": "concat(node_id,'' '',code, '' '', nodecat_id,'' '',descript)", "sys_display_name": "concat(node_id,'' ('',code, ''  expl: '',expl_id, '') : '', nodecat_id,'' '',descript)", "sys_fct_tablename": "ve_node"}'
WHERE "parameter"='basic_search_v2_tab_network_node';

-- 18/05/2026
INSERT INTO sys_table
(id, descript, sys_role, project_template, context, orderby, alias, "source", provider_config)
VALUES('xyz_openstreetmap', 'Open Street Map', 'role_basic', '{"template": [1], "visibility": true, "levels_to_read": 2}', '1', 2, 'Open Street Map', 'core', '{"source": {"url": "https://tile.openstreetmap.org/{z}/{x}/{y}.png"}, "provider": "wms", "layer_type": "raster", "uri_params": {"type": "xyz", "zmax": 19, "zmin": 0, "tilePixelRatio": 1}}'::jsonb);

INSERT INTO sys_style (layername, styleconfig_id, styletype, stylevalue)
VALUES ('xyz_openstreetmap', 101, 'qml', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.40.12-Bratislava" styleCategories="Rendering" hasScaleBasedVisibilityFlag="0" autoRefreshTime="0" maxScale="0" minScale="1e+08" autoRefreshMode="Disabled">
  <pipe-data-defined-properties>
    <Option type="Map">
      <Option type="QString" name="name" value=""/>
      <Option name="properties"/>
      <Option type="QString" name="type" value="collection"/>
    </Option>
  </pipe-data-defined-properties>
  <pipe>
    <provider>
      <resampling zoomedOutResamplingMethod="nearestNeighbour" maxOversampling="2" enabled="false" zoomedInResamplingMethod="nearestNeighbour"/>
    </provider>
    <rasterrenderer type="singlebandcolordata" opacity="0.4" alphaBand="-1" nodataColor="" band="1">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
    </rasterrenderer>
    <brightnesscontrast contrast="0" gamma="1" brightness="0"/>
    <huesaturation grayscaleMode="0" saturation="0" colorizeBlue="128" colorizeGreen="128" colorizeRed="255" colorizeStrength="100" invertColors="0" colorizeOn="0"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
') ON CONFLICT (layername, styleconfig_id) DO NOTHING;

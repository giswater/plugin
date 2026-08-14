/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "SCHEMA_NAME", public, pg_catalog;

INSERT INTO om_visit_cat VALUES (1, 'Test', '2024-02-21', '2024-02-21', NULL, true, NULL, NULL, NULL, 'Test');

INSERT INTO om_typevalue VALUES ('visit_cleaned', '1', 'Yes', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_cleaned', '2', 'No', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_cleaned', '3', 'Half', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_defect', '1', 'Good state', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_defect', '2', 'Some defects', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_defect', '3', 'Bad state', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_sediments', '1', 'No sediments', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_sediments', '2', 'Presence of sediments', NULL, NULL);
INSERT INTO om_typevalue VALUES ('incident_type', '1', 'Broken cover', NULL, NULL);
INSERT INTO om_typevalue VALUES ('incident_type', '2', 'Water on the street', NULL, NULL);
INSERT INTO om_typevalue VALUES ('incident_type', '3', 'Smells', NULL, NULL);
INSERT INTO om_typevalue VALUES ('incident_type', '4', 'Noisy cover', NULL, NULL);
INSERT INTO om_typevalue VALUES ('incident_type', '5', 'Others', NULL, NULL);
INSERT INTO om_typevalue VALUES ('incident_type', '6', 'Minor leak', NULL, NULL);
INSERT INTO om_typevalue VALUES ('incident_type', '7', 'Full of leaves', NULL, NULL);
INSERT INTO om_typevalue VALUES ('visit_param_type', 'INCIDENCE', 'INCIDENCE', NULL, NULL);
INSERT INTO om_typevalue (typevalue, id, idval, descript, addparam) VALUES('visit_form_type', 'event_ud_link_standard', 'event_ud_link_standard', NULL, NULL);


INSERT INTO config_visit_class VALUES (1, 'Inspection and clean arc', NULL, true, false, true, 'ARC', 'role_om', 1, NULL, 'visit_arc_insp', 've_visit_arc_insp', 'v_ui_visit_arc_insp', NULL, NULL);
INSERT INTO config_visit_class VALUES (2, 'Inspection and clean node', NULL, true, false, true, 'NODE', 'role_om', 1, NULL, 'visit_node_insp', 've_visit_node_insp', 'v_ui_visit_node_insp', NULL, NULL);
INSERT INTO config_visit_class VALUES (3, 'Inspection and clean connec', NULL, true, false, true, 'CONNEC', 'role_om', 1, NULL, 'visit_connec_insp', 've_visit_connec_insp', 'v_ui_visit_connec_insp', NULL, NULL);
INSERT INTO config_visit_class VALUES (4, 'Inspection and clean gully', NULL, true, false, true, 'GULLY', 'role_om', 1, NULL, 'visit_gully_insp', 've_visit_gully_insp', 'v_ui_visit_gully_insp', NULL, NULL);
INSERT INTO config_visit_class VALUES (5, 'Incident arc', NULL, true, false, true, 'ARC', 'role_om', 2, NULL, 'incident_arc', 've_visit_incid_arc', 'v_ui_visit_incid_arc', NULL, NULL);
INSERT INTO config_visit_class VALUES (6, 'Incident node', NULL, true, false, true, 'NODE', 'role_om', 2, NULL, 'incident_node', 've_visit_incid_node', 'v_ui_visit_incid_node', NULL, NULL);
INSERT INTO config_visit_class VALUES (7, 'Incident connec', NULL, true, false, true, 'CONNEC', 'role_om', 2, NULL, 'incident_connec', 've_visit_incid_connec', 'v_ui_visit_incid_connec', NULL, NULL);
INSERT INTO config_visit_class VALUES (8, 'Incident gully', NULL, true, false, true, 'GULLY', 'role_om', 2, NULL, 'incident_gully', 've_visit_incid_gully', 'v_ui_visit_incid_gully', NULL, NULL);
INSERT INTO config_visit_class (id, idval, descript, active, ismultifeature, ismultievent, feature_type, sys_role, visit_type, param_options, formname, tablename, ui_tablename, parent_id, inherit_values) VALUES(9, 'Inspection and clean link', NULL, true, false, true, 'LINK', 'role_om', 1, NULL, 'visit_link_insp', 've_visit_link_insp', 'v_ui_visit_link_insp', NULL, NULL);
INSERT INTO config_visit_class (id, idval, descript, active, ismultifeature, ismultievent, feature_type, sys_role, visit_type, param_options, formname, tablename, ui_tablename, parent_id, inherit_values) VALUES(10, 'Incident link', NULL, true, false, true, 'LINK', 'role_om', 2, NULL, 'incident_link', 've_visit_incid_link', 'v_ui_visit_incid_link', NULL, NULL);


INSERT INTO config_visit_parameter VALUES ('sediments_arc', NULL, 'INSPECTION', 'ARC', 'text', NULL, 'Sediments in arc', 'event_ud_arc_standard', 'defaultvalue', false, 'arc_insp_sed', true);
INSERT INTO config_visit_parameter VALUES ('clean_arc', NULL, 'INSPECTION', 'ARC', 'text', NULL, 'Clean of arc', 'event_ud_arc_standard', 'defaultvalue', false, 'arc_cln_exec', true);
INSERT INTO config_visit_parameter VALUES ('defect_arc', NULL, 'INSPECTION', 'ARC', 'text', NULL, 'Defects of arc', 'event_ud_arc_standard', 'defaultvalue', false, 'arc_defect', true);
INSERT INTO config_visit_parameter VALUES ('sediments_node', NULL, 'INSPECTION', 'NODE', 'text', NULL, 'Sediments in node', 'event_standard', 'defaultvalue', false, 'node_insp_sed', true);
INSERT INTO config_visit_parameter VALUES ('clean_node', NULL, 'INSPECTION', 'NODE', 'text', NULL, 'Clean of node', 'event_standard', 'defaultvalue', false, 'node_cln_exec', true);
INSERT INTO config_visit_parameter VALUES ('defect_node', NULL, 'INSPECTION', 'NODE', 'text', NULL, 'Defects of node', 'event_standard', 'defaultvalue', false, 'node_defect', true);
INSERT INTO config_visit_parameter VALUES ('sediments_connec', NULL, 'INSPECTION', 'CONNEC', 'text', NULL, 'Sediments in connec', 'event_standard', 'defaultvalue', false, 'con_insp_sed', true);
INSERT INTO config_visit_parameter VALUES ('clean_connec', NULL, 'INSPECTION', 'CONNEC', 'text', NULL, 'Clean of connec', 'event_standard', 'defaultvalue', false, 'con_cln_exec', true);
INSERT INTO config_visit_parameter VALUES ('defect_connec', NULL, 'INSPECTION', 'CONNEC', 'text', NULL, 'Defects of connec', 'event_standard', 'defaultvalue', false, 'con_defect', true);
INSERT INTO config_visit_parameter VALUES ('sediments_gully', NULL, 'INSPECTION', 'GULLY', 'text', NULL, 'Sediments in gully', 'event_standard', 'defaultvalue', false, 'gully_insp_sed', true);
INSERT INTO config_visit_parameter VALUES ('clean_gully', NULL, 'INSPECTION', 'GULLY', 'text', NULL, 'Clean of gully', 'event_standard', 'defaultvalue', false, 'gully_cln_exec', true);
INSERT INTO config_visit_parameter VALUES ('defect_gully', NULL, 'INSPECTION', 'GULLY', 'text', NULL, 'Defects of gully', 'event_standard', 'defaultvalue', false, 'gully_defect', true);
INSERT INTO config_visit_parameter VALUES ('smells_gully', NULL, 'INSPECTION', 'GULLY', 'boolean', NULL, 'Smells of gully', 'event_standard', 'defaultvalue', false, 'gully_smells', true);
INSERT INTO config_visit_parameter VALUES ('incident_comment', NULL, 'INCIDENCE', 'ALL', 'text', NULL, 'incident_comment', 'event_standard', 'defaultvalue', false, 'incident_comment', true);
INSERT INTO config_visit_parameter VALUES ('incident_type', NULL, 'INCIDENCE', 'ALL', 'text', NULL, 'incident type', 'event_standard', 'defaultvalue', false, 'incident_type', true);
INSERT INTO config_visit_parameter VALUES ('insp_observ', NULL, 'INSPECTION', 'ALL', 'text', NULL, 'Inspection observations', 'event_standard', 'defaultvalue', false, 'insp_observ', true);
INSERT INTO config_visit_parameter VALUES ('photo', NULL, 'INSPECTION', 'ALL', 'boolean', NULL, 'Photography', 'event_standard', 'defaultvalue', false, 'photo', true);
INSERT INTO config_visit_parameter (id, code, parameter_type, feature_type, data_type, criticity, descript, form_type, vdefault, ismultifeature, short_descript, active) VALUES('sediments_link', NULL, 'INSPECTION', 'LINK', 'text', NULL, 'Sediments in link', 'event_ud_link_standard', 'defaultvalue', false, 'link_insp_sed', true);
INSERT INTO config_visit_parameter (id, code, parameter_type, feature_type, data_type, criticity, descript, form_type, vdefault, ismultifeature, short_descript, active) VALUES('clean_link', NULL, 'INSPECTION', 'LINK', 'text', NULL, 'Clean of link', 'event_ud_link_standard', 'defaultvalue', false, 'link_cln_exec', true);
INSERT INTO config_visit_parameter (id, code, parameter_type, feature_type, data_type, criticity, descript, form_type, vdefault, ismultifeature, short_descript, active) VALUES('defect_link', NULL, 'INSPECTION', 'LINK', 'text', NULL, 'Defects of link', 'event_ud_link_standard', 'defaultvalue', false, 'link_defect', true);


INSERT INTO config_visit_class_x_parameter VALUES (1, 'sediments_arc', true);
INSERT INTO config_visit_class_x_parameter VALUES (1, 'clean_arc', true);
INSERT INTO config_visit_class_x_parameter VALUES (1, 'defect_arc', true);
INSERT INTO config_visit_class_x_parameter VALUES (1, 'insp_observ', true);
INSERT INTO config_visit_class_x_parameter VALUES (1, 'photo', true);
INSERT INTO config_visit_class_x_parameter VALUES (2, 'sediments_node', true);
INSERT INTO config_visit_class_x_parameter VALUES (2, 'clean_node', true);
INSERT INTO config_visit_class_x_parameter VALUES (2, 'defect_node', true);
INSERT INTO config_visit_class_x_parameter VALUES (2, 'insp_observ', true);
INSERT INTO config_visit_class_x_parameter VALUES (2, 'photo', true);
INSERT INTO config_visit_class_x_parameter VALUES (3, 'sediments_connec', true);
INSERT INTO config_visit_class_x_parameter VALUES (3, 'clean_connec', true);
INSERT INTO config_visit_class_x_parameter VALUES (3, 'defect_connec', true);
INSERT INTO config_visit_class_x_parameter VALUES (3, 'insp_observ', true);
INSERT INTO config_visit_class_x_parameter VALUES (3, 'photo', true);
INSERT INTO config_visit_class_x_parameter VALUES (4, 'sediments_gully', true);
INSERT INTO config_visit_class_x_parameter VALUES (4, 'clean_gully', true);
INSERT INTO config_visit_class_x_parameter VALUES (4, 'defect_gully', true);
INSERT INTO config_visit_class_x_parameter VALUES (4, 'smells_gully', true);
INSERT INTO config_visit_class_x_parameter VALUES (4, 'insp_observ', true);
INSERT INTO config_visit_class_x_parameter VALUES (4, 'photo', true);
INSERT INTO config_visit_class_x_parameter VALUES (5, 'incident_type', true);
INSERT INTO config_visit_class_x_parameter VALUES (5, 'incident_comment', true);
INSERT INTO config_visit_class_x_parameter VALUES (5, 'photo', true);
INSERT INTO config_visit_class_x_parameter VALUES (6, 'incident_type', true);
INSERT INTO config_visit_class_x_parameter VALUES (6, 'incident_comment', true);
INSERT INTO config_visit_class_x_parameter VALUES (6, 'photo', true);
INSERT INTO config_visit_class_x_parameter VALUES (7, 'incident_type', true);
INSERT INTO config_visit_class_x_parameter VALUES (7, 'incident_comment', true);
INSERT INTO config_visit_class_x_parameter VALUES (7, 'photo', true);
INSERT INTO config_visit_class_x_parameter VALUES (8, 'incident_type', true);
INSERT INTO config_visit_class_x_parameter VALUES (8, 'incident_comment', true);
INSERT INTO config_visit_class_x_parameter VALUES (8, 'photo', true);
INSERT INTO config_visit_class_x_parameter (class_id, parameter_id, active) VALUES(9, 'sediments_link', true);
INSERT INTO config_visit_class_x_parameter (class_id, parameter_id, active) VALUES(9, 'clean_link', true);
INSERT INTO config_visit_class_x_parameter (class_id, parameter_id, active) VALUES(9, 'defect_link', true);
INSERT INTO config_visit_class_x_parameter (class_id, parameter_id, active) VALUES(10, 'incident_type', true);
INSERT INTO config_visit_class_x_parameter (class_id, parameter_id, active) VALUES(10, 'incident_comment', true);
INSERT INTO config_visit_class_x_parameter (class_id, parameter_id, active) VALUES(10, 'photo', true);

-- editable views with trigger
DROP VIEW IF EXISTS ve_visit_arc_insp;
CREATE OR REPLACE VIEW ve_visit_arc_insp AS
 SELECT om_visit_x_arc.id,
    om_visit_x_arc.visit_id,
    om_visit_x_arc.arc_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    arc.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS sediments_arc,
    a.param_2 AS defect_arc,
    a.param_3 AS clean_arc,
    a.param_4 AS insp_observ,
    a.param_5 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_arc ON om_visit.id = om_visit_x_arc.visit_id
     JOIN arc USING (arc_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3,
            ct.param_4,
            ct.param_5
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 1 ORDER  BY 1,2'::text,
      ' VALUES (''sediments_arc''),(''defect_arc''),(''clean_arc''),(''insp_observ''),(''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 text, param_4 text, param_5 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 1;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_arc_insp
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('1');



DROP VIEW IF EXISTS ve_visit_node_insp;
CREATE OR REPLACE VIEW ve_visit_node_insp AS
 SELECT om_visit_x_node.id,
    om_visit_x_node.visit_id,
    om_visit_x_node.node_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    node.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS sediments_node,
    a.param_2 AS defect_node,
    a.param_3 AS clean_node,
    a.param_4 AS insp_observ,
    a.param_5 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_node ON om_visit.id = om_visit_x_node.visit_id
     JOIN node USING (node_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3,
            ct.param_4,
            ct.param_5
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 2 ORDER  BY 1,2'::text,
      ' VALUES (''sediments_node''),(''defect_node''),(''clean_node''),(''insp_observ''),(''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 text, param_4 text, param_5 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 2;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_node_insp
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('2');



DROP VIEW IF EXISTS ve_visit_connec_insp;
CREATE OR REPLACE VIEW ve_visit_connec_insp AS
 SELECT om_visit_x_connec.id,
    om_visit_x_connec.visit_id,
    om_visit_x_connec.connec_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    connec.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS sediments_connec,
    a.param_2 AS defect_connec,
    a.param_3 AS clean_connec,
    a.param_4 AS insp_observ,
    a.param_5 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_connec ON om_visit.id = om_visit_x_connec.visit_id
     JOIN connec USING (connec_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3,
            ct.param_4,
            ct.param_5
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 3 ORDER  BY 1,2'::text,
      ' VALUES (''sediments_connec''),(''defect_connec''),(''clean_connec''),(''insp_observ''),(''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 text, param_4 text, param_5 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 3;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_connec_insp
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('3');



DROP VIEW IF EXISTS ve_visit_gully_insp;
CREATE OR REPLACE VIEW ve_visit_gully_insp AS
 SELECT om_visit_x_gully.id,
    om_visit_x_gully.visit_id,
    om_visit_x_gully.gully_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    gully.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS sediments_gully,
    a.param_2 AS defect_gully,
    a.param_3 AS clean_gully,
    a.param_4 AS smells_gully,
    a.param_5 AS insp_observ,
    a.param_6 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_gully ON om_visit.id = om_visit_x_gully.visit_id
     JOIN gully USING (gully_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3,
            ct.param_4,
            ct.param_5,
            ct.param_6
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 4 ORDER  BY 1,2'::text,
      ' VALUES (''sediments_gully''),(''defect_gully''),(''clean_gully''),(''smells_gully''),(''insp_observ''),(''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 text, param_4 boolean, param_5 text, param_6 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 4;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_gully_insp
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('4');




DROP VIEW IF EXISTS ve_visit_incid_arc;
CREATE OR REPLACE VIEW ve_visit_incid_arc AS
 SELECT om_visit_x_arc.id,
    om_visit_x_arc.visit_id,
    om_visit_x_arc.arc_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    arc.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS incident_type,
    a.param_2 AS incident_comment,
    a.param_3 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_arc ON om_visit.id = om_visit_x_arc.visit_id
     JOIN arc USING (arc_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 5 ORDER  BY 1,2'::text,
      ' VALUES (''incident_type''), (''incident_comment''), (''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 5;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_incid_arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('5');



DROP VIEW IF EXISTS ve_visit_incid_node;
CREATE OR REPLACE VIEW ve_visit_incid_node AS
 SELECT om_visit_x_node.id,
    om_visit_x_node.visit_id,
    om_visit_x_node.node_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    node.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS incident_type,
    a.param_2 AS incident_comment,
    a.param_3 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_node ON om_visit.id = om_visit_x_node.visit_id
     JOIN node USING (node_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 6 ORDER  BY 1,2'::text,
      ' VALUES (''incident_type''), (''incident_comment''), (''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 6;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_incid_node
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('6');



DROP VIEW IF EXISTS ve_visit_incid_connec;
CREATE OR REPLACE VIEW ve_visit_incid_connec AS
 SELECT om_visit_x_connec.id,
    om_visit_x_connec.visit_id,
    om_visit_x_connec.connec_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    connec.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS incident_type,
    a.param_2 AS incident_comment,
    a.param_3 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_connec ON om_visit.id = om_visit_x_connec.visit_id
     JOIN connec USING (connec_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 7 ORDER  BY 1,2'::text,
      ' VALUES (''incident_type''), (''incident_comment''), (''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 7;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_incid_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('7');



DROP VIEW IF EXISTS ve_visit_incid_gully;
CREATE OR REPLACE VIEW ve_visit_incid_gully AS
 SELECT om_visit_x_gully.id,
    om_visit_x_gully.visit_id,
    om_visit_x_gully.gully_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    gully.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS incident_type,
    a.param_2 AS incident_comment,
    a.param_3 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_gully ON om_visit.id = om_visit_x_gully.visit_id
     JOIN gully USING (gully_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM SCHEMA_NAME.om_visit JOIN SCHEMA_NAME.om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN SCHEMA_NAME.config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 8 ORDER  BY 1,2'::text,
      ' VALUES (''incident_type''), (''incident_comment''), (''photo'')'::text)
      ct(visit_id integer, param_1 text, param_2 text, param_3 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 8;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_incid_gully
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('8');

CREATE OR REPLACE VIEW ve_visit_link_insp
AS SELECT om_visit_x_link.id,
    om_visit_x_link.visit_id,
    om_visit_x_link.link_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    link.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS sediments_link,
    a.param_2 AS defect_link,
    a.param_3 AS clean_link,
    a.param_4 AS insp_observ,
    a.param_5 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_link ON om_visit.id = om_visit_x_link.visit_id
     JOIN link USING (link_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3,
            ct.param_4,
            ct.param_5
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM om_visit JOIN om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 9 ORDER  BY 1,2'::text, ' VALUES (''sediments_link''),(''defect_link''),(''clean_link''),(''insp_observ''),(''photo'')'::text) ct(visit_id integer, param_1 text, param_2 text, param_3 text, param_4 text, param_5 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 9;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_link_insp
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('9'); -- 9: insp link

CREATE OR REPLACE VIEW ve_visit_incid_link
AS SELECT om_visit_x_link.id,
    om_visit_x_link.visit_id,
    om_visit_x_link.link_id,
    om_visit.visitcat_id,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    om_visit.expl_id,
    link.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.class_id,
    om_visit.status,
    a.param_1 AS incident_type,
    a.param_2 AS incident_comment,
    a.param_3 AS photo
   FROM om_visit
     JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
     JOIN om_visit_x_link ON om_visit.id = om_visit_x_link.visit_id
     JOIN link USING (link_id)
     LEFT JOIN ( SELECT ct.visit_id,
            ct.param_1,
            ct.param_2,
            ct.param_3
           FROM crosstab('SELECT visit_id, om_visit_event.parameter_id, value
      FROM om_visit JOIN om_visit_event ON om_visit.id= om_visit_event.visit_id
      LEFT JOIN config_visit_class on config_visit_class.id=om_visit.class_id
      where config_visit_class.ismultievent = TRUE and om_visit.class_id = 10 ORDER  BY 1,2'::text, ' VALUES (''incident_type''), (''incident_comment''), (''photo'')'::text) ct(visit_id integer, param_1 text, param_2 text, param_3 boolean)) a ON a.visit_id = om_visit.id
  WHERE config_visit_class.ismultievent = true AND config_visit_class.id = 10;

CREATE TRIGGER gw_trg_om_visit_multievent INSTEAD OF
INSERT OR DELETE OR UPDATE ON ve_visit_incid_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_multievent('10'); -- 10: incid link


-- UI views
CREATE OR REPLACE VIEW v_ui_visit_arc_insp
AS SELECT ve_visit_arc_insp.visit_id,
    ve_visit_arc_insp.arc_id,
    ve_visit_arc_insp.startdate AS "Start date",
    ve_visit_arc_insp.enddate AS "End date",
    ve_visit_arc_insp.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    z.idval AS "Sediments",
    u.idval AS "Defects",
    y.idval AS "Cleaned",
    ve_visit_arc_insp.insp_observ AS "Observation",
    ve_visit_arc_insp.photo AS "Photo"
   FROM ve_visit_arc_insp
     JOIN config_visit_class c ON c.id = ve_visit_arc_insp.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_arc_insp.status AND t.typevalue = 'visit_status'::text
     LEFT JOIN om_typevalue y ON y.id::integer = ve_visit_arc_insp.clean_arc::integer AND y.typevalue = 'visit_cleaned'::text
     LEFT JOIN om_typevalue u ON u.id::integer = ve_visit_arc_insp.defect_arc::integer AND u.typevalue = 'visit_defect'::text
     LEFT JOIN om_typevalue z ON z.id::integer = ve_visit_arc_insp.sediments_arc::integer AND z.typevalue = 'visit_sediments'::text;



CREATE OR REPLACE VIEW v_ui_visit_node_insp
AS SELECT ve_visit_node_insp.visit_id,
    ve_visit_node_insp.node_id,
    ve_visit_node_insp.startdate AS "Start date",
    ve_visit_node_insp.enddate AS "End date",
    ve_visit_node_insp.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    z.idval AS "Sediments",
    u.idval AS "Defects",
    y.idval AS "Cleaned",
    ve_visit_node_insp.insp_observ AS "Observation",
    ve_visit_node_insp.photo AS "Photo"
   FROM ve_visit_node_insp
     JOIN config_visit_class c ON c.id = ve_visit_node_insp.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_node_insp.status AND t.typevalue = 'visit_status'::text
     LEFT JOIN om_typevalue y ON y.id::integer = ve_visit_node_insp.clean_node::integer AND y.typevalue = 'visit_cleaned'::text
     LEFT JOIN om_typevalue u ON u.id::integer = ve_visit_node_insp.defect_node::integer AND u.typevalue = 'visit_defect'::text
     LEFT JOIN om_typevalue z ON z.id::integer = ve_visit_node_insp.sediments_node::integer AND z.typevalue = 'visit_sediments'::text;



CREATE OR REPLACE VIEW v_ui_visit_connec_insp
AS SELECT ve_visit_connec_insp.visit_id,
    ve_visit_connec_insp.connec_id,
    ve_visit_connec_insp.startdate AS "Start date",
    ve_visit_connec_insp.enddate AS "End date",
    ve_visit_connec_insp.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    z.idval AS "Sediments",
    u.idval AS "Defects",
    y.idval AS "Cleaned",
    ve_visit_connec_insp.insp_observ AS "Observation",
    ve_visit_connec_insp.photo AS "Photo"
   FROM ve_visit_connec_insp
     JOIN config_visit_class c ON c.id = ve_visit_connec_insp.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_connec_insp.status AND t.typevalue = 'visit_status'::text
     LEFT JOIN om_typevalue y ON y.id::integer = ve_visit_connec_insp.clean_connec::integer AND y.typevalue = 'visit_cleaned'::text
     LEFT JOIN om_typevalue u ON u.id::integer = ve_visit_connec_insp.defect_connec::integer AND u.typevalue = 'visit_defect'::text
     LEFT JOIN om_typevalue z ON u.id::integer = ve_visit_connec_insp.sediments_connec::integer AND z.typevalue = 'visit_sediments'::text;



CREATE OR REPLACE VIEW v_ui_visit_gully_insp
AS SELECT ve_visit_gully_insp.visit_id,
    ve_visit_gully_insp.gully_id,
    ve_visit_gully_insp.startdate AS "Start date",
    ve_visit_gully_insp.enddate AS "End date",
    ve_visit_gully_insp.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    z.idval AS "Sediments",
    u.idval AS "Defects",
    y.idval AS "Cleaned",
    ve_visit_gully_insp.smells_gully AS "Smells",
    ve_visit_gully_insp.insp_observ AS "Observation",
    ve_visit_gully_insp.photo AS "Photo"
   FROM ve_visit_gully_insp
     JOIN config_visit_class c ON c.id = ve_visit_gully_insp.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_gully_insp.status AND t.typevalue = 'visit_status'::text
     LEFT JOIN om_typevalue y ON y.id::integer = ve_visit_gully_insp.clean_gully::integer AND y.typevalue = 'visit_cleaned'::text
     LEFT JOIN om_typevalue u ON u.id::integer = ve_visit_gully_insp.defect_gully::integer AND u.typevalue = 'visit_defect'::text
     LEFT JOIN om_typevalue z ON u.id::integer = ve_visit_gully_insp.sediments_gully::integer AND z.typevalue = 'visit_sediments'::text;



CREATE OR REPLACE VIEW v_ui_visit_incid_arc
AS SELECT ve_visit_incid_arc.visit_id,
    ve_visit_incid_arc.arc_id,
    ve_visit_incid_arc.startdate AS "Start date",
    ve_visit_incid_arc.enddate AS "End date",
    ve_visit_incid_arc.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    y.idval AS "Incident type",
    ve_visit_incid_arc.incident_comment AS "Comment",
    ve_visit_incid_arc.photo AS "Photo"
   FROM ve_visit_incid_arc
     JOIN config_visit_class c ON c.id = ve_visit_incid_arc.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_incid_arc.status AND t.typevalue = 'visit_status'::text
     JOIN om_typevalue y ON y.id::integer = ve_visit_incid_arc.incident_type::integer AND y.typevalue = 'incident_type'::text;



CREATE OR REPLACE VIEW v_ui_visit_incid_node
AS SELECT ve_visit_incid_node.visit_id,
    ve_visit_incid_node.node_id,
    ve_visit_incid_node.startdate AS "Start date",
    ve_visit_incid_node.enddate AS "End date",
    ve_visit_incid_node.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    y.idval AS "Incident type",
    ve_visit_incid_node.incident_comment AS "Comment",
    ve_visit_incid_node.photo AS "Photo"
   FROM ve_visit_incid_node
     JOIN config_visit_class c ON c.id = ve_visit_incid_node.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_incid_node.status AND t.typevalue = 'visit_status'::text
     JOIN om_typevalue y ON y.id::integer = ve_visit_incid_node.incident_type::integer AND y.typevalue = 'incident_type'::text;



CREATE OR REPLACE VIEW v_ui_visit_incid_connec
AS SELECT ve_visit_incid_connec.visit_id,
    ve_visit_incid_connec.connec_id,
    ve_visit_incid_connec.startdate AS "Start date",
    ve_visit_incid_connec.enddate AS "End date",
    ve_visit_incid_connec.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    y.idval AS "Incident type",
    ve_visit_incid_connec.incident_comment AS "Comment",
    ve_visit_incid_connec.photo AS "Photo",
    ve_visit_incid_connec.the_geom
   FROM ve_visit_incid_connec
     JOIN config_visit_class c ON c.id = ve_visit_incid_connec.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_incid_connec.status AND t.typevalue = 'visit_status'::text
     JOIN om_typevalue y ON y.id::integer = ve_visit_incid_connec.incident_type::integer AND y.typevalue = 'incident_type'::text;



CREATE OR REPLACE VIEW v_ui_visit_incid_gully
AS SELECT ve_visit_incid_gully.visit_id,
    ve_visit_incid_gully.gully_id,
    ve_visit_incid_gully.startdate AS "Start date",
    ve_visit_incid_gully.enddate AS "End date",
    ve_visit_incid_gully.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    y.idval AS "Incident type",
    ve_visit_incid_gully.incident_comment AS "Comment",
    ve_visit_incid_gully.photo AS "Photo",
    ve_visit_incid_gully.the_geom
   FROM ve_visit_incid_gully
     JOIN config_visit_class c ON c.id = ve_visit_incid_gully.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_incid_gully.status AND t.typevalue = 'visit_status'::text
     JOIN om_typevalue y ON y.id::integer = ve_visit_incid_gully.incident_type::integer AND y.typevalue = 'incident_type'::text;

CREATE OR REPLACE VIEW v_ui_visit_link_insp
AS SELECT ve_visit_link_insp.visit_id,
    ve_visit_link_insp.link_id,
    ve_visit_link_insp.startdate AS "Start date",
    ve_visit_link_insp.enddate AS "End date",
    ve_visit_link_insp.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    z.idval AS "Sediments",
    u.idval AS "Defects",
    y.idval AS "Cleaned",
    ve_visit_link_insp.insp_observ AS "Observation",
    ve_visit_link_insp.photo AS "Photo"
   FROM ve_visit_link_insp
     JOIN config_visit_class c ON c.id = ve_visit_link_insp.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_link_insp.status AND t.typevalue = 'visit_status'::text
     LEFT JOIN om_typevalue y ON y.id::integer = ve_visit_link_insp.clean_link::integer AND y.typevalue = 'visit_cleaned'::text
     LEFT JOIN om_typevalue u ON u.id::integer = ve_visit_link_insp.defect_link::integer AND u.typevalue = 'visit_defect'::text
     LEFT JOIN om_typevalue z ON z.id::integer = ve_visit_link_insp.sediments_link::integer AND z.typevalue = 'visit_sediments'::text;

CREATE OR REPLACE VIEW v_ui_visit_incid_link
AS SELECT ve_visit_incid_link.visit_id,
    ve_visit_incid_link.link_id,
    ve_visit_incid_link.startdate AS "Start date",
    ve_visit_incid_link.enddate AS "End date",
    ve_visit_incid_link.user_name AS "User",
    c.idval AS "Visit class",
    t.idval AS "Status",
    y.idval AS "Incident type",
    ve_visit_incid_link.incident_comment AS "Comment",
    ve_visit_incid_link.photo AS "Photo"
   FROM ve_visit_incid_link
     JOIN config_visit_class c ON c.id = ve_visit_incid_link.class_id
     JOIN om_typevalue t ON t.id::integer = ve_visit_incid_link.status AND t.typevalue = 'visit_status'::text
     JOIN om_typevalue y ON y.id::integer = ve_visit_incid_link.incident_type::integer AND y.typevalue = 'incident_type'::text;


INSERT INTO config_form_tabs VALUES ('visit_arc_insp', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_arc_insp', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_leak_insp', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_leak_insp', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_node_insp', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_node_insp', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_connec_insp', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_connec_insp', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_gully_insp', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('visit_gully_insp', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');

INSERT INTO config_form_tabs VALUES ('incident_arc', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_arc', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_link', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_link', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_node', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_node', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_connec', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_connec', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_gully', 'tab_data', 'Data', 'Data', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":true}, "tabFiles":{"active":false}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false}]', 1, '{5}');
INSERT INTO config_form_tabs VALUES ('incident_gully', 'tab_file', 'Files', 'Files', 'role_om', '{"name":"gwGetVisit", "parameters":{"form":{"tabData":{"active":false},"tabFiles":{"active":true, "feature":{"tableName":"om_visit_event_photo"}}}}}', '[{"actionName":"actionAddFile", "actionFunction":"gwSetFileInsert", "actionTooltip":"Add file", "disabled":false},{"actionName":"actionDeleteFile", "actionFunction":"gwSetDelete", "actionTooltip":"Delete file", "disabled":false}]', 2, '{5}');


INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_arc_insp', 've_visit_arc_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_connec_insp', 've_visit_connec_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_node_insp', 've_visit_node_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_gully_insp', 've_visit_gully_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_link_insp', 've_visit_link_insp', 'role_om');

INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_incid_arc', 've_visit_incid_arc', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_incid_node', 've_visit_incid_node', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_incid_connec', 've_visit_incid_connec', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_incid_gully', 've_visit_incid_gully', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('ve_visit_incid_link', 've_visit_incid_link', 'role_om');

INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_arc_insp', 'v_ui_visit_arc_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_connec_insp', 'v_ui_visit_connec_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_node_insp', 'v_ui_visit_node_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_gully_insp', 'v_ui_visit_gully_insp', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_link_insp', 'v_ui_visit_link_insp', 'role_om');

INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_incid_arc', 'v_ui_visit_incid_arc', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_incid_node', 'v_ui_visit_incid_node', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_incid_connec', 'v_ui_visit_incid_connec', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_incid_gully', 'v_ui_visit_incid_gully', 'role_om');
INSERT INTO sys_table (id, descript, sys_role) VALUES ('v_ui_visit_incid_link', 'v_ui_visit_incid_link', 'role_om');

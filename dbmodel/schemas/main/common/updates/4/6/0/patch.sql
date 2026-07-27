/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

DROP VIEW IF EXISTS ve_exploitation;
DROP VIEW IF EXISTS v_ui_om_visit;
DROP VIEW IF EXISTS v_ui_workcat_x_feature;
DROP VIEW IF EXISTS v_ui_workcat_x_feature_end;
DROP VIEW IF EXISTS v_ui_mincut;
DROP VIEW IF EXISTS v_anl_arc;
DROP VIEW IF EXISTS v_anl_arc_point;
DROP VIEW IF EXISTS v_anl_arc_x_node;
DROP VIEW IF EXISTS v_anl_arc_x_node_point;
DROP VIEW IF EXISTS v_anl_connec;
DROP VIEW IF EXISTS v_anl_node;
DROP VIEW IF EXISTS v_om_mincut;
DROP VIEW IF EXISTS v_om_waterbalance;
DROP VIEW IF EXISTS v_om_waterbalance_report;
DROP VIEW IF EXISTS v_ui_hydrometer;
DROP VIEW IF EXISTS v_rtc_hydrometer_x_connec;
DROP VIEW IF EXISTS v_rtc_hydrometer_x_node;
DROP VIEW IF EXISTS v_rtc_hydrometer;
DROP VIEW IF EXISTS v_om_mincut_initpoint;
DROP VIEW IF EXISTS ve_macroexploitation;
DROP VIEW IF EXISTS v_ui_sector;
DROP VIEW IF EXISTS ve_sector;
DROP VIEW IF EXISTS v_ui_macrosector;
DROP VIEW IF EXISTS ve_macrosector;
DROP VIEW IF EXISTS v_ui_omzone;
DROP VIEW IF EXISTS ve_omzone;
DROP VIEW IF EXISTS v_ui_macroomzone;
DROP VIEW IF EXISTS ve_macroomzone;
DROP VIEW IF EXISTS v_ui_dma;
DROP VIEW IF EXISTS ve_dma;

ALTER TABLE exploitation ALTER COLUMN code TYPE varchar(100);
ALTER TABLE exploitation ALTER COLUMN name TYPE varchar(100);
ALTER TABLE exploitation ALTER COLUMN descript TYPE varchar(255);

ALTER TABLE macroexploitation ALTER COLUMN code TYPE varchar(100);
ALTER TABLE macroexploitation ALTER COLUMN name TYPE varchar(100);
ALTER TABLE macroexploitation ALTER COLUMN descript TYPE varchar(255);

ALTER TABLE sector ALTER COLUMN code TYPE varchar(100);
ALTER TABLE sector ALTER COLUMN name TYPE varchar(100);
ALTER TABLE sector ALTER COLUMN descript TYPE varchar(255);

ALTER TABLE macrosector ALTER COLUMN code TYPE varchar(100);
ALTER TABLE macrosector ALTER COLUMN name TYPE varchar(100);
ALTER TABLE macrosector ALTER COLUMN descript TYPE varchar(255);

ALTER TABLE omzone ALTER COLUMN code TYPE varchar(100);
ALTER TABLE omzone ALTER COLUMN name TYPE varchar(100);
ALTER TABLE omzone ALTER COLUMN descript TYPE varchar(255);

ALTER TABLE macroomzone ALTER COLUMN code TYPE varchar(100);
ALTER TABLE macroomzone ALTER COLUMN name TYPE varchar(100);
ALTER TABLE macroomzone ALTER COLUMN descript TYPE varchar(255);

ALTER TABLE dma ALTER COLUMN code TYPE varchar(100);
ALTER TABLE dma ALTER COLUMN name TYPE varchar(100);
ALTER TABLE dma ALTER COLUMN descript TYPE varchar(255);

SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"cat_arc", "column":"code", "dataType":"text", "isUtils":"False"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"cat_node", "column":"code", "dataType":"text", "isUtils":"False"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"cat_connec", "column":"code", "dataType":"text", "isUtils":"False"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"cat_link", "column":"code", "dataType":"text", "isUtils":"False"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"cat_element", "column":"code", "dataType":"text", "isUtils":"False"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"cat_pavement", "column":"code", "dataType":"text", "isUtils":"False"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"cat_soil", "column":"code", "dataType":"text", "isUtils":"False"}}$$);

CREATE OR REPLACE VIEW ve_exploitation
AS SELECT e.expl_id,
    e.code,
    e.name,
    e.macroexpl_id,
    e.sector_id,
    e.muni_id,
    e.owner_vdefault,
    e.descript,
    e.lock_level,
    e.active,
    e.the_geom,
    e.created_at,
    e.created_by,
    e.updated_at,
    e.updated_by
   FROM selector_expl se,
    exploitation e
  WHERE e.expl_id = se.expl_id AND se.cur_user = CURRENT_USER AND e.active IS TRUE;

CREATE OR REPLACE VIEW v_ui_om_visit
AS SELECT om_visit.id,
    om_visit_cat.name AS visit_catalog,
    om_visit.ext_code,
    om_visit.startdate,
    om_visit.enddate,
    om_visit.user_name,
    om_visit.webclient_id,
    exploitation.name AS exploitation,
    om_visit.the_geom,
    om_visit.descript,
    om_visit.is_done,
    om_visit.visit_type
   FROM om_visit
     LEFT JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
     LEFT JOIN exploitation ON exploitation.expl_id = om_visit.expl_id;


-- improve performance of v_anl_* with a CTE instead of a cross join
CREATE OR REPLACE VIEW v_anl_arc
AS WITH sel_audit AS (
    SELECT selector_audit.fid
    FROM selector_audit
    WHERE selector_audit.cur_user = CURRENT_USER
)
SELECT anl_arc.id,
    anl_arc.arc_id,
    anl_arc.arccat_id AS arc_type,
    anl_arc.state,
    anl_arc.arc_id_aux,
    anl_arc.fid AS fprocesscat_id,
    exploitation.name AS expl_name,
    anl_arc.the_geom,
    anl_arc.result_id,
    anl_arc.descript
FROM anl_arc
JOIN exploitation ON anl_arc.expl_id = exploitation.expl_id
WHERE EXISTS (
    SELECT 1
    FROM sel_audit
    WHERE sel_audit.fid = anl_arc.fid
)
AND anl_arc.cur_user = CURRENT_USER;


CREATE OR REPLACE VIEW v_anl_arc_point
AS WITH sel_audit AS (
    SELECT selector_audit.fid
    FROM selector_audit
    WHERE selector_audit.cur_user = CURRENT_USER
)
SELECT anl_arc.id,
    anl_arc.arc_id,
    anl_arc.arccat_id AS arc_type,
    anl_arc.state,
    anl_arc.arc_id_aux,
    anl_arc.fid AS fprocesscat_id,
    exploitation.name AS expl_name,
    anl_arc.the_geom_p
FROM anl_arc
JOIN sys_fprocess ON anl_arc.fid = sys_fprocess.fid
JOIN exploitation ON anl_arc.expl_id = exploitation.expl_id
WHERE EXISTS (
    SELECT 1
    FROM sel_audit
    WHERE sel_audit.fid = anl_arc.fid
)
AND anl_arc.cur_user = CURRENT_USER;


CREATE OR REPLACE VIEW v_anl_arc_x_node
AS WITH sel_audit AS (
    SELECT selector_audit.fid
    FROM selector_audit
    WHERE selector_audit.cur_user = CURRENT_USER
)
SELECT anl_arc_x_node.id,
    anl_arc_x_node.arc_id,
    anl_arc_x_node.arccat_id AS arc_type,
    anl_arc_x_node.state,
    anl_arc_x_node.node_id,
    anl_arc_x_node.fid AS fprocesscat_id,
    exploitation.name AS expl_name,
    anl_arc_x_node.the_geom
FROM anl_arc_x_node
JOIN exploitation ON anl_arc_x_node.expl_id = exploitation.expl_id
WHERE EXISTS (
    SELECT 1
    FROM sel_audit
    WHERE anl_arc_x_node.fid = sel_audit.fid
)
AND anl_arc_x_node.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW v_anl_arc_x_node_point
AS WITH sel_audit AS (
    SELECT selector_audit.fid
    FROM selector_audit
    WHERE selector_audit.cur_user = CURRENT_USER
)
SELECT anl_arc_x_node.id,
    anl_arc_x_node.arc_id,
    anl_arc_x_node.arccat_id AS arc_type,
    anl_arc_x_node.node_id,
    anl_arc_x_node.fid AS fprocesscat_id,
    exploitation.name AS expl_name,
    anl_arc_x_node.the_geom_p
FROM anl_arc_x_node
JOIN exploitation ON anl_arc_x_node.expl_id = exploitation.expl_id
WHERE EXISTS (
    SELECT 1
    FROM sel_audit
    WHERE anl_arc_x_node.fid = sel_audit.fid
)
AND anl_arc_x_node.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW v_anl_connec
AS WITH sel_audit AS (
    SELECT selector_audit.fid
    FROM selector_audit
    WHERE selector_audit.cur_user = CURRENT_USER
)
SELECT anl_connec.id,
    anl_connec.connec_id,
    anl_connec.conneccat_id AS connecat_id,
    anl_connec.state,
    anl_connec.connec_id_aux,
    anl_connec.connecat_id_aux AS state_aux,
    anl_connec.fid AS fprocesscat_id,
    exploitation.name AS expl_name,
    anl_connec.the_geom,
    anl_connec.result_id,
    anl_connec.descript
FROM anl_connec
    JOIN exploitation ON anl_connec.expl_id = exploitation.expl_id
WHERE EXISTS (
    SELECT 1
    FROM sel_audit
    WHERE anl_connec.fid = sel_audit.fid
)
AND anl_connec.cur_user = CURRENT_USER;


CREATE OR REPLACE VIEW v_anl_node
AS WITH sel_audit AS (
    SELECT selector_audit.fid
    FROM selector_audit
    WHERE selector_audit.cur_user = CURRENT_USER
)
SELECT anl_node.id,
    anl_node.node_id,
    anl_node.nodecat_id,
    anl_node.state,
    anl_node.node_id_aux,
    anl_node.nodecat_id_aux AS state_aux,
    anl_node.num_arcs,
    anl_node.fid AS fprocesscat_id,
    exploitation.name AS expl_name,
    anl_node.the_geom,
    anl_node.result_id,
    anl_node.descript
FROM anl_node
JOIN exploitation ON anl_node.expl_id = exploitation.expl_id
WHERE EXISTS (
    SELECT 1
    FROM sel_audit
    WHERE anl_node.fid = sel_audit.fid
)
AND anl_node.cur_user = CURRENT_USER;

CREATE OR REPLACE VIEW v_ui_macrosector
AS SELECT DISTINCT ON (macrosector_id) macrosector_id,
    code,
    name,
    descript,
    active,
    expl_id,
    muni_id,
    stylesheet::text AS stylesheet,
    lock_level,
    link,
    addparam::text AS addparam,
    created_at,
    created_by,
    updated_at,
    updated_by
FROM macrosector
WHERE macrosector_id > 0
ORDER BY macrosector_id;

CREATE OR REPLACE VIEW ve_macrosector
AS SELECT DISTINCT ON (macrosector_id) macrosector_id,
    code,
    name,
    descript,
    active,
    expl_id,
    muni_id,
    stylesheet::text AS stylesheet,
    lock_level,
    link,
    the_geom,
    addparam::text AS addparam,
    created_at,
    created_by,
    updated_at,
    updated_by
FROM macrosector m
WHERE macrosector_id > 0
ORDER BY macrosector_id;


CREATE OR REPLACE VIEW v_ui_macroomzone
AS SELECT DISTINCT ON (macroomzone_id) macroomzone_id,
    code,
    name,
    descript,
    active,
    expl_id,
    sector_id,
    muni_id,
    stylesheet::text AS stylesheet,
    lock_level,
    link,
    addparam::text AS addparam,
    created_at,
    created_by,
    updated_at,
    updated_by
FROM macroomzone m
WHERE macroomzone_id > 0
ORDER BY macroomzone_id;

CREATE OR REPLACE VIEW ve_macroomzone
AS SELECT DISTINCT ON (macroomzone_id) macroomzone_id,
    code,
    name,
    descript,
    active,
    expl_id,
    sector_id,
    muni_id,
    stylesheet::text AS stylesheet,
    lock_level,
    link,
    addparam::text AS addparam,
    created_at,
    created_by,
    updated_at,
    updated_by,
    the_geom
FROM macroomzone m
WHERE macroomzone_id > 0
ORDER BY macroomzone_id;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4434, 'Trying to connect %feature_type% with id %connect_id% to the closest arc.', NULL, 0, true, 'generic', 'core', 'AUDIT');
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4436, 'Trying to connect %feature_type% with id %connect_id% to the closest arc at a maximum distance of %max_distance% meters.', NULL, 0, true, 'generic', 'core', 'AUDIT');
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4438, 'Trying to connect %feature_type% with id %connect_id% to the closest arc with a diameter smaller than %check_arcdnom%.', NULL, 0, true, 'generic', 'core', 'AUDIT');
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4440, 'Trying to connect %feature_type% with id %connect_id% to the closest arc with a diameter smaller than %check_arcdnom% meters and at a maximum distance of %max_distance% meters.', NULL, 0, true, 'generic', 'core', 'AUDIT');

-- gw_fct_set_hydrometers (3520)
INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3520, 'gw_fct_set_hydrometers', 'utils', 'function', 'json', 'json', 'Function to set hydrometers in the database.', NULL, NULL, 'core', NULL);
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4448, 'Invalid action: %action%. Must be INSERT, UPDATE, DELETE or REPLACE.', 'Check the action parameter in your request.', 2, true, 'utils', 'core', 'UI');
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4450, 'No hydrometers provided in the request.', 'The hydrometers array cannot be empty. Provide at least one hydrometer.', 2, true, 'utils', 'core', 'UI');
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4452, 'Code is required for hydrometer #%hydrometer% when using INSERT or REPLACE action.', 'Provide a valid code for each hydrometer.', 1, true, 'utils', 'core', 'UI');
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(4454, 'Hydrometer with code %code% not found for UPDATE operation.', 'Verify that the hydrometer exists in the database.', 2, true, 'utils', 'core', 'UI');

-- move there is and there are messages to -2 and -3, TEMPORARY SOLUTION
UPDATE sys_message
SET id=-3
WHERE id=5002;
UPDATE sys_message
SET id=-2
WHERE id=5000;

UPDATE sys_message
SET id=4456
WHERE id=5008;
UPDATE sys_message
SET id=4458
WHERE id=5010;

INSERT INTO sys_message (id,error_message,log_level,show_user,project_type,"source",message_type)
VALUES (4460,'Used plan psectors: %v_psectors%',0,true,'ud','core','UI');

INSERT INTO sys_message (id,error_message,log_level,show_user,project_type,"source",message_type)
VALUES (4462,'Commit changes: %v_commit_changes%',0,true,'ud','core','UI');

UPDATE config_form_fields SET label = 'Sys elev 2:' WHERE label = 'Elevation of the selected node 2:';

-- When updating y1, elev1, or custom_elev1, also refresh node_2 fields
UPDATE config_form_fields
SET widgetcontrols = '{"autoupdateReloadFields":["node_1", "y1", "custom_elev1", "sys_y1", "sys_elev1", "z1", "r1", "node_2", "y2", "custom_elev2", "sys_y2", "sys_elev2", "z2", "r2", "slope"]}'::json
WHERE columnname IN ('y1', 'elev1', 'custom_elev1')
AND formname LIKE 've_arc_%'
AND formtype = 'form_feature'
AND widgetcontrols::text LIKE '%autoupdateReloadFields%';

-- When updating y2, elev2, or custom_elev2, also refresh node_1 fields
UPDATE config_form_fields
SET widgetcontrols = '{"autoupdateReloadFields":["node_1", "y1", "custom_elev1", "sys_y1", "sys_elev1", "z1", "r1", "node_2", "y2", "custom_elev2", "sys_y2", "sys_elev2", "z2", "r2", "slope"]}'::json
WHERE columnname IN ('y2', 'elev2', 'custom_elev2')
AND formname LIKE 've_arc_%'
AND formtype = 'form_feature'
AND widgetcontrols::text LIKE '%autoupdateReloadFields%';

DO
$$
DECLARE
    v_rec record;
BEGIN
    FOR v_rec IN SELECT fid, except_msg FROM sys_fprocess LOOP
        IF right(v_rec.except_msg, 1) <> '.' AND right(v_rec.except_msg, 1) <> '!' AND right(v_rec.except_msg, 1) <> '?' THEN
            UPDATE sys_fprocess
            SET except_msg = v_rec.except_msg || '.'
            WHERE fid = v_rec.fid;
        END IF;
    END LOOP;
END;
$$;


UPDATE sys_fprocess SET query_text='SELECT a.node_id, a.nodecat_id, a.expl_id, a.the_geom FROM t_node a
JOIN cat_node b ON a.nodecat_id = b.id
JOIN cat_feature_node c ON c.id = b.node_type
JOIN dma d ON d.dma_id = a.dma_id
WHERE d.active IS FALSE
AND ''DMA'' = ANY(c.graph_delimiter)' WHERE fid=636;

UPDATE sys_fprocess SET query_text='SELECT a.node_id, a.nodecat_id, a.expl_id, a.the_geom FROM node a
JOIN cat_node b ON a.nodecat_id = b.id
JOIN cat_feature_node c ON c.id = b.node_type
JOIN presszone d ON d.presszone_id = a.presszone_id
WHERE d.active IS FALSE
AND ''PRESSZONE'' = ANY(c.graph_delimiter)' WHERE fid=182;

UPDATE sys_fprocess SET except_msg = 'arcs with length shorter than value set as node proximity. Please, check your data before continue.',
query_text='SELECT arc_id,arccat_id,st_length(the_geom), the_geom, expl_id
FROM t_arc, config_param_system where parameter = ''edit_node_proximity''
and  st_length(the_geom) < json_extract_path_text(value::json,''value'')::numeric ' WHERE fid=391;

UPDATE config_param_system
	SET value='{"id":"EUR", "descript":"EURO", "symbol":"€", "separator":".", "decimals":true}'
	WHERE "parameter"='admin_currency';

INSERT INTO sys_function (id,function_name,project_type,function_type,input_params,return_type,descript,"source")
	VALUES (3524,'gw_fct_set_currency_config','utils','function','num','num','Function to transform nuemric values of price to user configuration from admin_currency in config_param_system','core');

UPDATE sys_table SET id = 'v_rtc_hydrometer_x_connec' WHERE id = 'v_hydrometer_x_connec';

do $$
DECLARE
    column_name TEXT;
    v_admin_control_trigger BOOLEAN;
    table_name CONSTANT TEXT := 'config_form_fields';
    table_records RECORD;
BEGIN
    -- Store and disable the config control trigger
    SELECT value::boolean INTO v_admin_control_trigger
    FROM config_param_system
    WHERE parameter = 'admin_config_control_trigger';

    UPDATE config_param_system
    SET value = 'FALSE'
    WHERE parameter = 'admin_config_control_trigger';

    -- Perform the replacements
    FOR table_records IN SELECT formname, formtype, columnname, tabname, label, tooltip FROM config_form_fields WHERE label LIKE '%ID%' OR tooltip LIKE '%ID%' LOOP
        UPDATE config_form_fields
            SET label = regexp_replace(table_records.label, '\mID\M', 'Id', 'g'),
                tooltip = regexp_replace(table_records.tooltip, '\mID\M', 'Id', 'g')
            WHERE formname = table_records.formname
                AND formtype = table_records.formtype
                AND columnname = table_records.columnname
                AND tabname = table_records.tabname;

        -- Step 2: Capitalize only the first letter of each entry
        UPDATE config_form_fields
            SET label = UPPER(LEFT(label, 1)) || SUBSTRING(label FROM 2),
                tooltip = UPPER(LEFT(tooltip, 1)) || SUBSTRING(tooltip FROM 2)
            WHERE formname = table_records.formname
                AND formtype = table_records.formtype
                AND columnname = table_records.columnname
                AND tabname = table_records.tabname;
    END LOOP;

    -- Restore the original trigger setting
    IF v_admin_control_trigger IS NOT NULL THEN
        UPDATE config_param_system
        SET value = v_admin_control_trigger::text
        WHERE parameter = 'admin_config_control_trigger';
    END IF;
END;
$$;

UPDATE sys_fprocess SET except_msg = 'registers on arc''s catalog with null values on dint column.' WHERE fid=283;
UPDATE sys_message SET error_message = 'No node was found at these coordinates' WHERE id=3694;

UPDATE config_form_fields SET dv_querytext='SELECT sector_id as id,name as idval FROM sector WHERE sector_id IS NOT NULL AND active IS TRUE '
WHERE formname ilike 've_%' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_data';

UPDATE config_form_fields
SET iseditable=false
WHERE formname='ve_dimensions' AND formtype='form_feature' AND columnname='feature_type' AND tabname='tab_none';

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','id','string','text','Id:','id',true,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','code','string','text','Code:','code',true,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','parameter_type','string','text','Parameter type:','parameter_type',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,dv_querytext,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','feature_type','string','combo','Feature type:','feature_type',false,true,'SELECT DISTINCT feature_type as id, feature_type as idval FROM cat_feature',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','data_type','string','text','Data type:','data_type',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','critcity','integer','text','Critcity:','critcity',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','descript','string','text','Descript:','descript',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','form_type','string','text','Form type:','form_type',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','vdefault','string','text','Default:','vdefault',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','ismultifeature','boolean','check','Is multifeature:','ismultifeature',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','short_descript','string','text','Short descript:','short_descript',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('config_visit_parameter','form_feature','tab_none','active','boolean','check','Active:','active',false,true,false);

-- Om_visit_type
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','id','string','text','Id:','id',true,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','name','string','text','Name:','name',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','startdate','datetime','text','Start date:','startdate',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','enddate','datetime','text','End date:','enddate',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','descript','string','text','Descript:','descript',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','active','boolean','check','Active:','active',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','extusercat_id','integer','text','Extsuercat id:','extusercat_id',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','duration','string','text','Duration:','duration',false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,dv_querytext,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','feature_type','string','combo','Feature Type:','feature_type',false,true,'SELECT DISTINCT feature_type as id, feature_type as idval FROM cat_feature',false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,iseditable,hidden)
	VALUES ('om_visit_cat','form_feature','tab_none','alias','string','text','Alias:','alias',false,true,false);

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source")
VALUES (4464, 'The selected catalog is not available for the feature type selected', 'Select another catalog', 2, true, 'utils', 'core');

ALTER TABLE sys_fprocess
ALTER COLUMN fprocess_name TYPE VARCHAR(250);

DO $$
DECLARE
    v_utils boolean;
BEGIN

	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS true THEN
        -- ve_exploitation
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('ve_exploitation','form_feature','tab_none','sector_id','string','multiple_option','Secotr id:','sector_id - Sector id',false,false,true,false,'select sector_id AS id, name AS idval from ve_sector where sector_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('ve_exploitation','form_feature','tab_none','muni_id','string','multiple_option','Municipality id','muni_id -Municipality id',false,false,true,false,'select muni_id AS id, name AS idval from utils.municipality where muni_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "utils.ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);

        -- utils.municipality
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('ext_municipality','form_feature','tab_none','sector_id','string','multiple_option','Secotr id:','sector_id - Sector id',false,false,true,false,'select sector_id AS id, name AS idval from ve_sector where sector_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('ext_municipality','form_feature','tab_none','expl_id','string','multiple_option','Exploitation id:','expl_id - Exploitation id',false,false,true,false,'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);

        -- ve_sector
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_sector' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from utils.ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "utils.ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_sector' AND columnname = 'muni_id';

        -- ve_dma
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dma' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from utils.ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "utils.ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dma' AND columnname = 'muni_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select sector_id AS id, name AS idval from ve_sector where sector_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dma' AND columnname = 'sector_id';

        -- ve_presszone
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_presszone' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from utils.ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "utils.ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_presszone' AND columnname = 'muni_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select sector_id AS id, name AS idval from ve_sector where sector_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_presszone' AND columnname = 'sector_id';

        -- ve_dqa
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dqa' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from utils.ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "utils.ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dqa' AND columnname = 'muni_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select sector_id AS id, name AS idval from ve_sector where sector_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dqa' AND columnname = 'sector_id';

    ELSE
        -- ve_exploitation
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('ve_exploitation','form_feature','tab_none','sector_id','string','multiple_option','Secotr id:','sector_id - Sector id',false,false,true,false,'select sector_id AS id, name AS idval from ve_sector where sector_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('ve_exploitation','form_feature','tab_none','muni_id','string','multiple_option','Municipality id','muni_id -Municipality id',false,false,true,false,'select muni_id AS id, name AS idval from v_ext_municipality where muni_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "v_ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);

        -- v_ext_municipality
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('v_ext_municipality','form_feature','tab_none','sector_id','string','multiple_option','Secotr id:','sector_id - Sector id',false,false,true,false,'select sector_id AS id, name AS idval from ve_sector where sector_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);
        INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden)
            VALUES ('v_ext_municipality','form_feature','tab_none','expl_id','string','multiple_option','Exploitation id:','expl_id - Exploitation id',false,false,true,false,'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0','{"setMultiline": false, "valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::json,false);

        -- ve_sector
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_sector' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from v_ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "v_ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_sector' AND columnname = 'muni_id';

        -- ve_dma
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dma' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from v_ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "v_ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dma' AND columnname = 'muni_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select sector_id AS id, name AS idval from ve_sector where sector_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dma' AND columnname = 'sector_id';

        -- ve_presszone
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_presszone' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from v_ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "v_ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_presszone' AND columnname = 'muni_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select sector_id AS id, name AS idval from ve_sector where sector_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_presszone' AND columnname = 'sector_id';

        -- ve_dqa
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select expl_id AS id, name AS idval from ve_exploitation where expl_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_exploitation", "activated": true, "keyColumn": "expl_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dqa' AND columnname = 'expl_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select muni_id AS id, name AS idval from v_ext_municipality where muni_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "v_ext_municipality", "activated": true, "keyColumn": "muni_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dqa' AND columnname = 'muni_id';
        UPDATE config_form_fields SET widgettype = 'multiple_option', dv_querytext = 'select sector_id AS id, name AS idval from ve_sector where sector_id > 0', widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"valueRelation":{"nullValue":false, "layer": "ve_sector", "activated": true, "keyColumn": "sector_id", "valueColumn": "name", "nofColumns": 2, "filterExpression": null, "allowMulti": true}}'::jsonb)::json WHERE formname = 've_dqa' AND columnname = 'sector_id';

    END IF;
END;
$$;

-- cat_material
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('cat_material','form_feature','tab_none','feature_type','string','multiple_option','Feature type','feature_type - Feature Type',false,false,true,false,'select id, id as idval from sys_feature_type',true,false,'{"valueRelation":{"nullValue":false, "allowMulti": true, "layer": "sys_feature_type", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": null}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden)
	VALUES ('cat_material','form_feature','tab_none','featurecat_id','string','multiple_option','Featurecat id','featurecat_id',false,false,true,false,'select id, id as idval from cat_feature',true,false,'{"valueRelation":{"nullValue":false, "allowMulti": true, "layer": "cat_feature", "activated": true, "keyColumn": "id", "valueColumn": "id", "filterExpression": null, "nofColumns": 3}}'::json,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate)
	VALUES ('cat_material','form_feature','tab_none','id','string','text','Id','id - Id',true,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate)
	VALUES ('cat_material','form_feature','tab_none','descript','string','text','Descript','id - Id',false,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate)
	VALUES ('cat_material','form_feature','tab_none','n','string','text','N','id - Id',false,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate)
	VALUES ('cat_material','form_feature','tab_none','link','string','text','Link','id - Id',false,false,true,false);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,hidden)
	VALUES ('cat_material','form_feature','tab_none','active','boolean','check','Active','id - Id',false,false,true,false,false);


-- Config_form_fields
UPDATE config_form_fields
	SET "label"='Sys elev2:'
	WHERE label = 'Elevation of the selected node 2:';

UPDATE config_form_tableview
    SET alias = 'roughness'
    WHERE objectname = 'cat_mat_roughness' AND columnname = 'roughness';

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector id:','Sector id',false,false,true,false,'SELECT sector_id as id,name as idval FROM sector WHERE sector_id IS NOT NULL AND active IS TRUE ',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false,2);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','state','lyt_bot_1',2,'integer','combo','State:','State',false,false,true,false,'WITH psector_value AS (
  		SELECT value::integer AS psector_value
  		FROM config_param_user
  		WHERE parameter = ''plan_psector_current'' AND cur_user = current_user),
	 tg_op_value AS (
  		SELECT value::text AS tg_op_value
  		FROM config_param_user
  		WHERE parameter = ''utils_transaction_mode'' AND cur_user = current_user)
SELECT id::integer as id, name as idval
FROM value_state
WHERE id IS NOT NULL
AND CASE
  WHEN (SELECT tg_op_value FROM tg_op_value)!=''INSERT'' THEN id IN (0,1,2)
  WHEN (SELECT tg_op_value FROM tg_op_value) =''INSERT'' AND (SELECT psector_value FROM psector_value) IS NOT NULL THEN id = 2
  ELSE id < 2
END',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false,3);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','state_type','lyt_bot_1',3,'integer','combo','State Type:','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false,4);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','code','lyt_data_1',1,'string','text','Code:','Code',false,false,true,false,'{"setMultiline":false}'::json,false,5);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','num_elements','lyt_data_1',2,'integer','text','Number of Elements:','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false,6);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','comment','lyt_data_1',3,'string','text','Comments:','Comments',false,false,true,false,'{"setMultiline":true}'::json,true,7);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','function_type','lyt_data_1',4,'string','combo','Function Type:','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE ''ELEMENT''=ANY(feature_type) OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false,8);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','category_type','lyt_data_1',5,'string','combo','Category Type:','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE ''ELEMENT''=ANY(feature_type) OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false,9);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','location_type','lyt_data_1',6,'string','combo','Location Type:','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE ''ELEMENT''=ANY(feature_type) OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false,10);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','workcat_id','lyt_data_1',7,'string','typeahead','Workcat id:','Workcat id',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false,11);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','workcat_id_end','lyt_data_1',8,'string','typeahead','Workcat id End:','Workcat id End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false,12);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','builtdate','lyt_data_1',9,'date','datetime','Built Date:','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false,13);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','enddate','lyt_data_1',10,'date','datetime','End Date:','End Date',false,false,true,false,'{"setMultiline":false}'::json,false,14);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','ownercat_id','lyt_data_1',11,'string','combo','Owner Catalog:','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false,15);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','rotation','lyt_data_1',12,'double','text','Rotation:','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false,16);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','top_elev','lyt_data_1',13,'double','text','Top Elevation:','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false,18);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','expl_id','lyt_data_2',1,'integer','combo','Exploitation id:','Exploitation id',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false,20);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality:','Muni_id - Municipality to which the element belongs. If the configuration is not modified, the program automatically selects it based on the geometry',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false,21);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','observ','lyt_data_3',2,'string','text','Observations:','Observations',false,false,true,false,'{"setMultiline":true}'::json,false,22);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_frelem','form_feature','tab_data','elementcat_id','lyt_top_1',1,'string','combo','Element Catalog:','Element Catalog',true,false,true,false,'SELECT ce.id, ce.id as idval FROM cat_element ce
JOIN cat_feature_element cfe ON ce.element_type = cfe.id
JOIN cat_feature cf ON cf.id = cfe.id
WHERE feature_class = ''FRELEM''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false,1);

INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','sector_id','lyt_bot_1',1,'integer','combo','Sector id:','Sector id',false,false,true,false,'SELECT sector_id as id,name as idval FROM sector WHERE sector_id IS NOT NULL AND active IS TRUE ',true,false,'{"label":"color:blue; font-weight:bold;"}'::json,'{"setMultiline": false, "labelPosition": "top"}'::json,false,2);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','state','lyt_bot_1',2,'integer','combo','State:','State',false,false,true,false,'WITH psector_value AS (
  		SELECT value::integer AS psector_value
  		FROM config_param_user
  		WHERE parameter = ''plan_psector_current'' AND cur_user = current_user),
	 tg_op_value AS (
  		SELECT value::text AS tg_op_value
  		FROM config_param_user
  		WHERE parameter = ''utils_transaction_mode'' AND cur_user = current_user)
SELECT id::integer as id, name as idval
FROM value_state
WHERE id IS NOT NULL
AND CASE
  WHEN (SELECT tg_op_value FROM tg_op_value)!=''INSERT'' THEN id IN (0,1,2)
  WHEN (SELECT tg_op_value FROM tg_op_value) =''INSERT'' AND (SELECT psector_value FROM psector_value) IS NOT NULL THEN id = 2
  ELSE id < 2
END',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false,3);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','state_type','lyt_bot_1',3,'integer','combo','State Type:','State Type',false,false,true,false,'SELECT id, name as idval FROM value_state_type WHERE id IS NOT NULL',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false,4);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','code','lyt_data_1',1,'string','text','Code:','Code',false,false,true,false,'{"setMultiline":false}'::json,false,5);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','num_elements','lyt_data_1',2,'integer','text','Number of Elements:','Number of Elements',false,false,true,false,'{"setMultiline":false}'::json,false,6);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','comment','lyt_data_1',3,'string','text','Comments:','Comments',false,false,true,false,'{"setMultiline":true}'::json,true,7);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','function_type','lyt_data_1',4,'string','combo','Function Type:','Function Type',false,false,true,false,'SELECT function_type as id, function_type as idval FROM man_type_function WHERE ''ELEMENT''=ANY(feature_type) OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false,8);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','category_type','lyt_data_1',5,'string','combo','Category Type:','Category Type',false,false,true,false,'SELECT category_type as id, category_type as idval FROM man_type_category WHERE ''ELEMENT''=ANY(feature_type) OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false,9);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','location_type','lyt_data_1',6,'string','combo','Location Type:','Location Type',false,false,true,false,'SELECT location_type as id, location_type as idval FROM man_type_location WHERE ''ELEMENT''=ANY(feature_type) OR ''EORIFICE'' = ANY(featurecat_id::text[])',true,false,'{"setMultiline":false}'::json,false,10);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,linkedobject,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','workcat_id','lyt_data_1',7,'string','typeahead','Workcat id:','Workcat id',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,'action_workcat',false,11);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,placeholder,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','workcat_id_end','lyt_data_1',8,'string','typeahead','Workcat id End:','Workcat id End','Only when state is obsolete',false,false,true,false,'SELECT id, id as idval FROM cat_work WHERE id IS NOT NULL AND active IS TRUE','{"setMultiline":false}'::json,false,12);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','builtdate','lyt_data_1',9,'date','datetime','Built Date:','Built Date',false,false,true,false,'{"setMultiline":false}'::json,false,13);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','enddate','lyt_data_1',10,'date','datetime','End Date:','End Date',false,false,true,false,'{"setMultiline":false}'::json,false,14);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','ownercat_id','lyt_data_1',11,'string','combo','Owner Catalog:','Owner Catalog',false,false,true,false,'SELECT id, id as idval FROM cat_owner WHERE id IS NOT NULL AND active IS TRUE',true,false,'{"setMultiline":false}'::json,false,15);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','rotation','lyt_data_1',12,'double','text','Rotation:','Rotation',false,false,true,false,'{"setMultiline":false}'::json,false,16);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','top_elev','lyt_data_1',13,'double','text','Top Elevation:','Top Elevation',false,false,true,false,'{"setMultiline":false}'::json,false,18);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','expl_id','lyt_data_2',1,'integer','combo','Exploitation id:','Exploitation id',false,false,true,false,'SELECT expl_id as id, name as idval FROM exploitation WHERE expl_id IS NOT NULL',true,false,'{"label":"color:green; font-weight:bold;"}'::json,'{"setMultiline": false}'::json,false,20);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,dv_querytext,dv_orderby_id,dv_isnullvalue,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','muni_id','lyt_data_3',1,'string','combo','Municipality:','Muni_id - Municipality to which the element belongs. If the configuration is not modified, the program automatically selects it based on the geometry',false,false,true,'SELECT muni_id as id, name as idval from v_ext_municipality WHERE muni_id IS NOT NULL',true,false,false,21);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','observ','lyt_data_3',2,'string','text','Observations:','Observations',false,false,true,false,'{"setMultiline":true}'::json,false,22);
INSERT INTO config_form_fields (formname,formtype,tabname,columnname,layoutname,layoutorder,"datatype",widgettype,"label",tooltip,ismandatory,isparent,iseditable,isautoupdate,dv_querytext,dv_orderby_id,dv_isnullvalue,widgetcontrols,hidden,web_layoutorder)
	VALUES ('ve_man_genelem','form_feature','tab_data','elementcat_id','lyt_top_1',1,'string','combo','Element Catalog:','Element Catalog',true,false,true,false,'SELECT ce.id, ce.id as idval FROM cat_element ce
JOIN cat_feature_element cfe ON ce.element_type = cfe.id
JOIN cat_feature cf ON cf.id = cfe.id
WHERE feature_class = ''GENELEM''',true,false,'{"setMultiline": false, "labelPosition": "top"}'::json,false,1);


--WEB SECTION
-- insert search configuration parameters for psectors
INSERT INTO config_param_system ("parameter", value, descript, "label", dv_querytext, dv_filterbyfield, isenabled, layoutorder, project_type, dv_isparent, isautoupdate, "datatype", widgettype, ismandatory, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, widgetcontrols, placeholder, standardvalue, layoutname) VALUES('basic_search_v2_tab_psector ', '{"sys_display_name":"concat(name,'' ('',text2,'')'')","sys_tablename":"v_edit_plan_psector","sys_pk":"psector_id","sys_fct":"gw_fct_getinfofromid","sys_filter":"","sys_geom":"the_geom"}', 'Search configuration parameteres', 'Psector:', NULL, NULL, true, NULL, 'utils', NULL, NULL, 'string', 'text', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- insert tabs for go2epa
INSERT INTO config_form_tabs (formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device) VALUES('go2epa', 'tab_data', 'Data', NULL, 'role_basic', NULL, NULL, 0, '{5}');
INSERT INTO config_form_tabs (formname, tabname, "label", tooltip, sys_role, tabfunction, tabactions, orderby, device) VALUES('go2epa', 'tab_log', 'Log', NULL, 'role_basic', NULL, NULL, 1, '{5}');

-- insert typevalues for go2epa
INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('formtype_typevalue', 'go2epa', 'go2epa', 'go2Epa', NULL);
INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('layout_name_typevalue', 'lyt_go2epa_1', 'lyt_go2epa_1', 'lytGo2epa1', '{"lytOrientation":"horizontal"}'::json);
INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('layout_name_typevalue', 'lyt_go2epa_data_1', 'lyt_go2epa_data_1', 'lytGo2epaData1', '{"lytOrientation":"horizontal"}'::json);
INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('layout_name_typevalue', 'lyt_go2epa_data_2', 'lyt_go2epa_data_2', 'lytGo2epaData2', '{"lytOrientation":"horizontal"}'::json);
INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('layout_name_typevalue', 'lyt_go2epa_log', 'lyt_go2epa_log', 'lytGo2epaLog', '{
  "lytOrientation": "vertical"
}'::json);
INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('layout_name_typevalue', 'lyt_go2epa_log_btns', 'lyt_go2epa_log_btns', 'lytGo2epaLogBtns', '{
  "lytOrientation": "horizontal"
}'::json);
INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam) VALUES('layout_name_typevalue', 'lyt_go2epa_data_3', 'lyt_go2epa_data_3', 'lytGo2epaData3', '{"lytOrientation":"vertical"}'::json);

-- DLG GO2EPA
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_none', 'tab_main', 'lyt_go2epa_1', 0, NULL, 'tabwidget', NULL, NULL, NULL, false, false, false, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{"tabs":["tab_data", "tab_log"]}'::json, NULL, NULL, false, 0);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_none', 'btn_close', 'lyt_buttons', 1, 'string', 'button', NULL, 'Close dialog', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "text": "Close"
}'::json, NULL, NULL, false, 2);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_log', 'gridLayout_log', 'lyt_go2epa_log', 0, 'string', 'textarea', NULL, NULL, NULL, false, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 1);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_log', 'btn_download_inp', 'lyt_go2epa_log_btns', 1, 'string', 'button', NULL, 'Download INP file', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "text": "INP File"
}'::json, '{
  "functionName": "downloadInp"
}'::json, NULL, false, 2);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_data', 'vspacer_go2epa_1', 'lyt_go2epa_data_3', 1, 'string', 'vspacer', NULL, NULL, NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 3);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_log', 'btn_download_rpt', 'lyt_go2epa_log_btns', 2, 'string', 'button', NULL, 'Download RPT file', NULL, false, false, true, false, false, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "text": "RPT File"
}'::json, '{
  "functionName": "downloadRpt"
}'::json, NULL, false, 3);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_data', 'btn_selector', 'lyt_go2epa_data_1', 1, 'string', 'button', NULL, 'Open selector dialog', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "text": "Selector"
}'::json, '{"functionName": "openSelector"}'::json, NULL, false, 2);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_data', 'resultId', 'lyt_go2epa_data_2', 1, 'string', 'text', 'Result Name:', 'Name for the EPA result', 'Enter result name...', true, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 3);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_data', 'btn_options', 'lyt_go2epa_data_1', 2, 'string', 'button', NULL, 'Configure EPA options', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "text": "Options"
}'::json, '{"functionName": "openOptions"}'::json, NULL, false, 1);
INSERT INTO config_form_fields (formname, formtype, tabname, columnname, layoutname, layoutorder, "datatype", widgettype, "label", tooltip, placeholder, ismandatory, isparent, iseditable, isautoupdate, isfilter, dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id, dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction, linkedobject, hidden, web_layoutorder) VALUES('generic', 'go2epa', 'tab_none', 'btn_execute_epa', 'lyt_buttons', 0, 'string', 'button', NULL, 'Execute EPA logic', NULL, false, NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{
  "text": "Execute"
}'::json, '{
  "functionName": "executeEpa"
}'::json, NULL, false, 1);

-- change to show file name instead of date in files
UPDATE config_form_list
	SET addparam='{
  "displayField": "text"
}'::json,query_text='SELECT id, value as url, tstamp, COALESCE(NULLIF(text, ''''''''), tstamp::text) as text FROM om_visit_event_photo WHERE id IS NOT NULL'
	WHERE listname='om_visit_event_photo' AND device=5;

INSERT INTO sys_param_user (id,formname,descript,sys_role,"label",isenabled,layoutorder,project_type,isparent,isautoupdate,"datatype",widgettype,ismandatory,vdefault,layoutname,"source")
	VALUES ('custom_order_by','config','Configuration to order result of getselectors by columname','role_edit','Configuration to order result of getselectors by columname:',true,27,'utils',false,false,'json','text',true,'{
  "tab_exploitation": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_exploitation_add": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_macroexploitation": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_macrosector": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_municipality": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_network": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_network_state": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_period": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_psector": {
    "order_by_column": "value",
    "is_checked": false
  },
  "tab_sector": {
    "order_by_column": "value",
    "is_checked": false
  }
}','lyt_other','core');

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3526, 'gw_fct_set_selector_tab_custom_order_by_value', 'utils', 'function', 'json', 'json', 'Function to set custom order by value for selectors.', NULL, NULL, 'core', NULL);

UPDATE config_param_system
    SET value = jsonb_set(value::jsonb, '{hasCustomOrderBy}', 'true'::jsonb, true)
    WHERE "parameter" = 'basic_selector_tab_psector';

-- ALTER TABLE node ADD CONSTRAINT node_sys_code_unique UNIQUE (sys_code);
-- ALTER TABLE arc ADD CONSTRAINT arc_sys_code_unique UNIQUE (sys_code);
-- ALTER TABLE connec ADD CONSTRAINT connec_sys_code_unique UNIQUE (sys_code);
-- ALTER TABLE "element" ADD CONSTRAINT element_sys_code_unique UNIQUE (sys_code);
-- ALTER TABLE link ADD CONSTRAINT link_sys_code_unique UNIQUE (sys_code);

CREATE TRIGGER gw_trg_edit_exploitation INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_exploitation
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_exploitation();

CREATE TRIGGER gw_trg_ui_visit INSTEAD OF DELETE ON v_ui_om_visit
FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_visit();

CREATE TRIGGER gw_trg_v_edit_macrosector INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_macrosector
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrosector('EDIT');

CREATE TRIGGER gw_trg_v_edit_macroomzone INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_macroomzone
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macroomzone('EDIT');

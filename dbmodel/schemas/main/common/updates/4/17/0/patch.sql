/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- common
ALTER TABLE inp_dscenario_controls ADD observ text NULL;
ALTER TABLE inp_dscenario_inlet ADD observ text NULL;
ALTER TABLE inp_dscenario_junction ADD observ text NULL;
ALTER TABLE inp_dscenario_frpump ADD observ text NULL;


DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT formname, COALESCE(MAX(layoutorder), 0) AS max_layoutorder
        FROM config_form_fields
        WHERE formname LIKE 'inp_dscenario_%'
        GROUP BY formname
    LOOP
        INSERT INTO config_form_fields (
            formname, formtype, tabname, columnname, layoutname, layoutorder,
            "datatype", widgettype, "label", tooltip, placeholder,
            ismandatory, isparent, iseditable, isautoupdate, isfilter,
            dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id,
            dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction,
            linkedobject, hidden, web_layoutorder
        ) VALUES (
            r.formname, 'form_feature', 'tab_none', 'observ', NULL, r.max_layoutorder + 1,
            'string', 'textarea', 'Observ', 'observ', NULL,
            false, false, true, false, NULL,
            NULL, NULL, NULL, NULL,
            NULL, NULL, NULL, NULL,
            NULL, false, NULL
        );
    END LOOP;
END $$;

INSERT INTO sys_param_user (
    id, formname, descript, sys_role, "label", dv_querytext, isenabled, layoutorder,
    project_type, isparent, isautoupdate, "datatype", widgettype, ismandatory,
    layoutname, iseditable, "source", dv_isnullvalue
)
VALUES (
    'multilang_language', 'config',
    'UI language for database messages when multilang schema is enabled',
    'role_basic', 'UI language',
    'SELECT ''default'' AS id, ''Default'' AS idval UNION ALL SELECT id, idval FROM multilang.cat_language',
    false, 6, 'utils', false, false, 'string', 'combo', false,
    'lyt_basic', true, 'core', false
)
ON CONFLICT (id) DO UPDATE SET
    dv_querytext = EXCLUDED.dv_querytext,
    dv_isnullvalue = false,
    isenabled = CASE
        WHEN to_regclass('multilang.cat_language') IS NULL THEN false
        ELSE sys_param_user.isenabled
    END;


INSERT INTO config_param_user (parameter, value, cur_user)
SELECT
    'multilang_language',
    lower(replace(value::json->>'lang', '-', '_')),
    cur_user
FROM config_param_user
WHERE parameter = 'utils_language_ui'
  AND value IS NOT NULL
  AND btrim(value) <> ''
  AND value::json->>'lang' IS NOT NULL
  AND btrim(value::json->>'lang') <> ''
ON CONFLICT (parameter, cur_user) DO UPDATE SET value = EXCLUDED.value;


DELETE FROM config_param_user WHERE parameter = 'utils_language_ui';
DELETE FROM sys_param_user WHERE id = 'utils_language_ui';


UPDATE sys_param_user
SET
    dv_querytext = 'SELECT ''default'' AS id, ''Default'' AS idval UNION ALL SELECT id, idval FROM multilang.cat_language',
    dv_isnullvalue = false,
    isenabled = CASE
        WHEN to_regclass('multilang.cat_language') IS NULL THEN false
        ELSE isenabled
    END
WHERE id = 'multilang_language';

DO $BODY$
DECLARE
    v_schema text := current_schema();
    v_tables text[] := ARRAY[
        'config_form_fields',
        'config_form_tabs',
        'config_param_system',
        'sys_param_user',
        'sys_message',
        'sys_function',
        'sys_fprocess',
        'sys_table'
    ];
    v_table text;
BEGIN
    IF to_regnamespace('multilang') IS NOT NULL
       AND to_regprocedure('multilang.gw_fct_admin_manage_multilang_views(boolean, text)') IS NOT NULL
    THEN
        PERFORM multilang.gw_fct_admin_manage_multilang_views(true, v_schema);
    ELSE
        FOREACH v_table IN ARRAY v_tables
        LOOP
            IF to_regclass(format('%I.%I', v_schema, v_table)) IS NOT NULL THEN
                EXECUTE format(
                    'CREATE OR REPLACE VIEW %I.%I AS SELECT * FROM %I.%I',
                    v_schema, 'v_' || v_table, v_schema, v_table
                );
            END IF;
        END LOOP;
    END IF;
END
$BODY$;

INSERT INTO sys_table (id, descript, sys_role, "source") VALUES
('v_config_form_fields', 'Configuration form fields (allows multilingual and integration with network schemas)', 'role_basic', 'core'),
('v_config_form_tabs', 'Configuration form tabs (allows multilingual and integration with network schemas)', 'role_basic', 'core'),
('v_config_param_system', 'Configuration system parameters (allows multilingual and integration with network schemas)', 'role_basic', 'core'),
('v_sys_param_user', 'System user parameters (allows multilingual and integration with network schemas)', 'role_basic', 'core'),
('v_sys_message', 'System messages (allows multilingual and integration with network schemas)', 'role_basic', 'core'),
('v_sys_function', 'System functions (allows multilingual and integration with network schemas)', 'role_basic', 'core'),
('v_sys_fprocess', 'System processes (allows multilingual and integration with network schemas)', 'role_basic', 'core'),
('v_sys_table', 'System tables (allows multilingual and integration with network schemas)', 'role_basic', 'core')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE cat_feature ADD custom_code_autofill bool DEFAULT false NULL;
ALTER TABLE config_mapzones ADD custom_code_autofill bool DEFAULT false NULL;

UPDATE sys_message SET error_message = 'The volume water inserted is %volume%, which it means that lossed water percentatge due leak of data have been %percentage% %.'
WHERE id = 4640 AND error_message = 'The volume water inserted is %volume%, wich it means that lossed water percentatge due leak of data have been %percentage% %.';

UPDATE config_param_system
	SET "label"='Cibs schema:'
	WHERE "parameter"='admin_cibs_schema' AND "label"='cibs schema:';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column rg_id.', except_msg='subcatchment(s) with null values on mandatory column rg_id.' 
WHERE fid=704 AND fprocess_name='Check subcatchment(s) with null values on mandatory column rg_id column.';
    
UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column area.', except_msg='subcatchment(s) with null values on mandatory column area.' 
WHERE fid=702 AND fprocess_name='Check subcatchment(s) with null values on mandatory column area column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column width.', except_msg='subcatchment(s) with null values on mandatory column width.' 
WHERE fid=700 AND fprocess_name='Check subcatchment(s) with null values on mandatory column width column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column slope.', except_msg='subcatchment(s) with null values on mandatory column slope.' WHERE fid=698;
UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column clength.', except_msg='subcatchment(s) with null values on mandatory column clength.' 
WHERE fid=696 AND fprocess_name='Check subcatchment(s) with null values on mandatory column clength column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column nimp.', except_msg='subcatchment(s) with null values on mandatory column nimp.' 
WHERE fid=694 AND fprocess_name='Check subcatchment(s) with null values on mandatory column nimp column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column nperv.', except_msg='subcatchment(s) with null values on mandatory column nperv.' 
WHERE fid=692 AND fprocess_name='Check subcatchment(s) with null values on mandatory column nperv column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column simp.', except_msg='subcatchment(s) with null values on mandatory column simp.' 
WHERE fid=690 AND fprocess_name='Check subcatchment(s) with null values on mandatory column simp column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column sperv.', except_msg='subcatchment(s) with null values on mandatory column sperv.' 
WHERE fid=688 AND fprocess_name='Check subcatchment(s) with null values on mandatory column sperv column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column zero.', except_msg='subcatchment(s) with null values on mandatory column zero.' 
WHERE fid=686 AND fprocess_name='Check subcatchment(s) with null values on mandatory column zero column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column routeto.', except_msg='subcatchment(s) with null values on mandatory column routeto.' 
WHERE fid=684 AND fprocess_name='Check subcatchment(s) with null values on mandatory column routeto column.';

UPDATE sys_fprocess SET fprocess_name='Check subcatchment(s) with null values on mandatory column rted.', except_msg='subcatchment(s) with null values on mandatory column rted.' 
WHERE fid=682 AND fprocess_name='Check subcatchment(s) with null values on mandatory column rted column.';

UPDATE config_param_system 
SET "label" = "label" || ':' 
WHERE "parameter" = 'help_domain' 
  AND "label" IS NOT NULL 
  AND "label" LIKE '%:';

DO $$
BEGIN
  IF lower((SELECT "language" FROM sys_version LIMIT 1)) NOT ILIKE 'es_%' OR (SELECT "language" FROM sys_version LIMIT 1) IS NULL THEN
    UPDATE sys_fprocess SET 
    except_msg = 'raingages with null values at least in the mandatory columns for the rain type (form_type, intvl, scf, rgage_type).',
    info_msg = 'The mandatory columns for the rain type (form_type, intvl, scf, rgage_type) have been checked and no values are missing.'
    WHERE fid = 285 AND except_msg = 'raingages con valores nulos al menos en las columnas obligatorias para el tipo de lluvia (form_type, intvl, scf, rgage_type).';
  END IF;
END $$;

UPDATE config_form_fields
  SET tooltip = LEFT(tooltip, LENGTH(tooltip) - 1)
  WHERE tooltip LIKE '%:';

UPDATE config_form_fields
  SET tooltip = replace(tooltip, '- id', '- Id')
  WHERE tooltip LIKE '%- id%';

UPDATE config_form_fields
	SET "label"='Data quality'
	WHERE formtype='form_feature' AND tabname='tab_data' AND columnname='dataquality' AND "label"='Dataquality';

UPDATE config_form_fields
	SET "label"='Data quality obs.'
	WHERE formtype='form_feature' AND tabname='tab_data' AND columnname='dataquality_obs' AND "label"='Dataquality_obs';

UPDATE config_form_fields
	SET "label"='Cabinet:'
	WHERE formname='ve_connec_samplepoint' AND formtype='form_feature' AND tabname='tab_data' AND columnname='cabinet' AND "label"='cabinet';

UPDATE config_form_fields
	SET "label"='Place name:'
	WHERE formname='ve_connec_samplepoint' AND formtype='form_feature' AND tabname='tab_data' AND columnname='place_name' AND "label"='place_name';

UPDATE config_form_fields
	SET tooltip='Date to'
	WHERE (tooltip='' OR tooltip IS NULL) AND columnname = 'date_to';

CREATE OR REPLACE VIEW ve_om_visit AS
SELECT
	om_visit.id,
	om_visit.visitcat_id,
	om_visit.ext_code,
	om_visit.status,
	om_visit.startdate,
	om_visit.enddate,
	om_visit.user_name,
	om_visit.the_geom,
	om_visit.webclient_id,
	om_visit.expl_id
FROM om_visit
WHERE 
    EXISTS ( SELECT 1 FROM selector_sector ssec WHERE ssec.cur_user = CURRENT_USER AND ssec.sector_id = om_visit.sector_id)
    AND EXISTS ( SELECT 1 FROM selector_municipality sm WHERE sm.cur_user = CURRENT_USER AND sm.muni_id = om_visit.muni_id)
    AND EXISTS ( SELECT 1 FROM selector_expl se WHERE se.cur_user = CURRENT_USER AND se.expl_id = om_visit.expl_id);

CREATE OR REPLACE VIEW v_ui_om_visit
AS 
SELECT 
    om_visit.id,
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

-- Fix sys_table_context 27/28/29 when 4.5.0 renumbered with a non-C
-- collation (Linux ICU): OM ANALYTICS siblings were assigned the wrong
-- numeric id vs the C-collation / i18n baseline.
-- Reattach each row's payload (idval, addparam, ...) to the canonical id
-- using addparam.orderBy so translated idval text is preserved.
-- Canonical: orderBy 31→27, 32→28, 30→29. Only WS (has orderBy 31 and 32).
UPDATE config_typevalue AS t
SET idval = s.idval,
	camelstyle = s.camelstyle,
	addparam = s.addparam
FROM (
	SELECT
		idval,
		camelstyle,
		addparam,
		CASE (addparam->>'orderBy')::integer
			WHEN 31 THEN '27'
			WHEN 32 THEN '28'
			WHEN 30 THEN '29'
		END AS target_id
	FROM config_typevalue
	WHERE typevalue = 'sys_table_context'
		AND (addparam->>'orderBy')::integer IN (30, 31, 32)
) AS s
WHERE t.typevalue = 'sys_table_context'
	AND t.id = s.target_id
    AND EXISTS (
		SELECT 1 FROM config_typevalue
		WHERE typevalue = 'sys_table_context' AND (addparam->>'orderBy')::integer = 30
	)
	AND EXISTS (
		SELECT 1 FROM config_typevalue
		WHERE typevalue = 'sys_table_context' AND (addparam->>'orderBy')::integer = 31
	)
	AND EXISTS (
		SELECT 1 FROM config_typevalue
		WHERE typevalue = 'sys_table_context' AND (addparam->>'orderBy')::integer = 32
	);

UPDATE sys_fprocess SET query_text='SELECT node_id, nodecat_id, the_geom, a.active, t_node.expl_id FROM t_node JOIN cat_node c ON id=nodecat_id JOIN cat_feature_node n ON n.id=c.node_type
LEFT JOIN (SELECT node_id, a.active FROM t_node JOIN (SELECT NULLIF(((json_array_elements_text((graphconfig::json->>''use'')::json))::json->>''nodeParent''), '''')::integer AS node_id, 
active FROM dma WHERE graphconfig IS NOT NULL )a USING (node_id)) a USING (node_id) WHERE ''DMA'' = ANY(graph_delimiter) AND (a.node_id IS NULL
OR node_id NOT IN (SELECT NULLIF(json_array_elements_text((graphconfig::json->>''ignore'')::json), '''')::integer FROM dma WHERE active IS TRUE)) AND t_node.state > 0 and verified <> 2 and a.active is false' WHERE fid=180;


UPDATE sys_fprocess SET query_text='WITH a AS (
  SELECT arc_id, node_1, node_2, arccat_id, expl_id, state, the_geom
  FROM t_arc
  WHERE state = 1
),
n1 AS (
  SELECT a.arc_id, nearest.node_id
  FROM a
  CROSS JOIN LATERAL (
    SELECT node.node_id
    FROM t_node node
    WHERE node.state = 1
      AND ST_DWithin(node.the_geom, ST_StartPoint(a.the_geom), 0.02)
    ORDER BY node.the_geom <-> ST_StartPoint(a.the_geom)
    LIMIT 1
  ) nearest
),
n2 AS (
  SELECT a.arc_id, nearest.node_id
  FROM a
  CROSS JOIN LATERAL (
    SELECT node.node_id
    FROM t_node node
    WHERE node.state = 1
      AND ST_DWithin(node.the_geom, ST_EndPoint(a.the_geom), 0.02)
    ORDER BY node.the_geom <-> ST_EndPoint(a.the_geom)
    LIMIT 1
  ) nearest
)
SELECT a.*
FROM a
LEFT JOIN n1 ON a.arc_id = n1.arc_id
LEFT JOIN n2 ON a.arc_id = n2.arc_id
WHERE a.node_1 IS DISTINCT FROM n1.node_id
   OR a.node_2 IS DISTINCT FROM n2.node_id' WHERE fid=372;
UPDATE sys_fprocess SET query_text='with
mec as ( -- links with startpoint close to connec
SELECT l.link_id as arc_id, c.conneccat_id as arccat_id, l.the_geom, l.expl_id FROM connec c, link l
WHERE l.state = 1 and c.state = 1 and ST_DWithin(ST_startpoint(l.the_geom), c.the_geom, 0.01) group by 1,2 ORDER BY 1 DESC
), 
moc as ( -- links connected to connec
SELECT link_id, feature_id, ''417'', l.state, l.the_geom 
FROM link l JOIN connec c ON feature_id = connec_id WHERE l.state = 1 and l.feature_type = ''CONNEC'') 
select * from mec where arc_id not in (select link_id from moc)' WHERE fid=417;
UPDATE sys_fprocess SET query_text='with q_arc as (
WITH v_state_arc AS (
SELECT arc_id FROM selector_state, arc
WHERE arc.state = selector_state.state_id AND selector_state.cur_user = CURRENT_USER
)
select * from arc JOIN v_state_arc USING (arc_id))
SELECT b.* FROM (
WITH v_state_node AS (SELECT node_id FROM selector_state, node
WHERE node.state = selector_state.state_id AND selector_state.cur_user = CURRENT_USER)
SELECT n1.node_id, n1.nodecat_id, n1.sector_id, n1.expl_id, n1.state, n1.the_geom  FROM q_arc, 
(select * from node JOIN v_state_node USING (node_id)) n1 
JOIN (SELECT node_1 node_id from q_arc UNION 
select node_2 FROM q_arc) b USING (node_id) 
WHERE st_dwithin(q_arc.the_geom, n1.the_geom,0.01) AND n1.node_id NOT IN 
(node_1, node_2)
)b, selector_expl e 
where e.expl_id= b.expl_id AND cur_user=current_user' WHERE fid=432;
UPDATE sys_fprocess SET query_text='WITH dup AS (
    SELECT arc_id, arccat_id, state, node_1, node_2, expl_id, the_geom,
           md5(ST_AsBinary(the_geom)) AS geom_hash
    FROM ve_arc
    WHERE state > 0
)
SELECT a.arc_id, a.arccat_id, a.state AS state1,
       b.arc_id AS arc_id_aux,
       a.node_1, a.node_2, a.expl_id, a.the_geom
FROM dup a
JOIN dup b ON a.geom_hash = b.geom_hash
WHERE a.arc_id != b.arc_id' WHERE fid=479;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4680, 'Cannot force connection to a node while arcs are selected.', 'Clear the selected arcs and try again.', 2, true, 'ud', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4682, 'The %feature_type% with id %connec_id% has been successfully connected to the node with id %node_id%', NULL, 0, true, 'ud', 'core', 'AUDIT')
ON CONFLICT (id) DO NOTHING;

INSERT INTO config_typevalue (typevalue, id, idval, camelstyle, addparam)
VALUES
('layout_name_typevalue', 'lyt_link_configuration', 'lyt_link_configuration', 'lytLinkConfiguration', '{"lytOrientation": "vertical"}'::json),
('layout_name_typevalue', 'lyt_feature_selection', 'lyt_feature_selection', 'lytFeatureSelection', '{"lytOrientation": "horizontal"}'::json),
('layout_name_typevalue', 'lyt_arc_selection', 'lyt_arc_selection', 'lytArcSelection', '{"lytOrientation": "horizontal"}'::json),
('layout_name_typevalue', 'lyt_node_selection', 'lyt_node_selection', 'lytNodeSelection', '{"lytOrientation": "horizontal"}'::json),
('layout_name_typevalue', 'lyt_extra_filters', 'lyt_extra_filters', 'lytExtraFilters', '{"lytOrientation": "vertical"}'::json)
ON CONFLICT (typevalue, id) DO NOTHING;

UPDATE config_form_fields SET layoutname = 'lyt_link_configuration'
WHERE formname = 'generic' AND formtype IN ('link_to_connec', 'link_to_gully') AND layoutname = 'lyt_connect_link_1';

UPDATE config_form_fields SET layoutname = 'lyt_feature_selection'
WHERE formname = 'generic' AND formtype IN ('link_to_connec', 'link_to_gully') AND layoutname = 'lyt_connect_link_2';

UPDATE config_form_fields SET layoutname = 'lyt_connect_link_3'
WHERE formname = 'generic' AND formtype IN ('link_to_connec', 'link_to_gully') AND columnname = 'tbl_ids';

UPDATE config_form_fields SET layoutname = 'lyt_arc_selection'
WHERE formname = 'generic' AND formtype IN ('link_to_connec', 'link_to_gully') AND layoutname = 'lyt_connect_link_4';

UPDATE config_form_fields SET layoutname = 'lyt_node_selection'
WHERE formname = 'generic' AND formtype IN ('link_to_connec', 'link_to_gully') AND layoutname = 'lyt_connect_link_5';

UPDATE config_form_fields SET layoutname = 'lyt_extra_filters'
WHERE formname = 'generic' AND formtype IN ('link_to_connec', 'link_to_gully') AND layoutname = 'lyt_connect_link_6';

DELETE FROM config_typevalue
WHERE typevalue = 'layout_name_typevalue'
AND id IN ('lyt_connect_link_1', 'lyt_connect_link_2', 'lyt_connect_link_4', 'lyt_connect_link_5', 'lyt_connect_link_6');

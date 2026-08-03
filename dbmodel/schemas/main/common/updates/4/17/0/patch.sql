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

INSERT INTO config_param_user (parameter, value, cur_user)
VALUES ('utils_language_ui', '{"status":true, "lang":"en_US"}', current_user)
ON CONFLICT (parameter, cur_user) DO NOTHING;

DO $patch$
BEGIN
    IF to_regprocedure('gw_fct_get_utils_language_ui()') IS NOT NULL THEN
        ALTER FUNCTION gw_fct_get_utils_language_ui() VOLATILE;
    END IF;
END $patch$;



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



CREATE OR REPLACE VIEW vf_node
AS SELECT n.node_id,
    pp.state AS p_state
   FROM node n
     LEFT JOIN LATERAL ( SELECT x.state
           FROM ( SELECT 1
                  WHERE (EXISTS ( SELECT 1
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))) gate
             CROSS JOIN LATERAL ( SELECT pp_1.state
                   FROM plan_psector_x_node pp_1
                  WHERE pp_1.node_id = n.node_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))
                  ORDER BY pp_1.psector_id DESC
                 LIMIT 1) x) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, n.state))) AND ((n.sector_id IN ( SELECT ssec.sector_id
           FROM selector_sector ssec
          WHERE ssec.cur_user = CURRENT_USER)) OR (EXISTS ( SELECT 1
           FROM node_x_sector_visibility sv
             JOIN selector_sector ssec ON ssec.sector_id = sv.sector_id AND ssec.cur_user = CURRENT_USER
          WHERE sv.node_id = n.node_id))) AND ((n.muni_id IN ( SELECT sm.muni_id
           FROM selector_municipality sm
          WHERE sm.cur_user = CURRENT_USER)) OR (EXISTS ( SELECT 1
           FROM node_x_municipality_visibility mv
             JOIN selector_municipality sm ON sm.muni_id = mv.muni_id AND sm.cur_user = CURRENT_USER
          WHERE mv.node_id = n.node_id))) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE se.cur_user = CURRENT_USER AND (se.expl_id = n.expl_id OR (se.expl_id = ANY (n.expl_visibility)))));

CREATE OR REPLACE VIEW vf_arc
AS SELECT a.arc_id,
    pp.state AS p_state
   FROM arc a
     LEFT JOIN LATERAL ( SELECT x.state
           FROM ( SELECT 1
                  WHERE (EXISTS ( SELECT 1
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))) gate
             CROSS JOIN LATERAL ( SELECT pp_1.state
                   FROM plan_psector_x_arc pp_1
                  WHERE pp_1.arc_id = a.arc_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))
                  ORDER BY pp_1.psector_id DESC
                 LIMIT 1) x) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, a.state))) AND (a.sector_id IN ( SELECT ssec.sector_id
           FROM selector_sector ssec
          WHERE ssec.cur_user = CURRENT_USER)) AND (a.muni_id IN ( SELECT sm.muni_id
           FROM selector_municipality sm
          WHERE sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE se.cur_user = CURRENT_USER AND (se.expl_id = a.expl_id OR (se.expl_id = ANY (a.expl_visibility)))));

CREATE OR REPLACE VIEW vf_connec
AS SELECT c.connec_id,
    pp.state AS p_state,
    pp.arc_id AS arc_id,
    pp.exit_id AS pjoint_id,
    pp.exit_type AS pjoint_type
   FROM connec c
     LEFT JOIN LATERAL ( SELECT x.state,
            x.arc_id,
            x.exit_id,
            x.exit_type
           FROM ( SELECT 1
                  WHERE (EXISTS ( SELECT 1
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))) gate
             CROSS JOIN LATERAL ( SELECT pp_1.state,
                    pp_1.arc_id,
                    l.exit_id,
                    l.exit_type
                   FROM plan_psector_x_connec pp_1
                     LEFT JOIN link l ON l.link_id = pp_1.link_id AND l.state = 2
                  WHERE pp_1.connec_id = c.connec_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))
                  ORDER BY pp_1.psector_id DESC, pp_1.state DESC
                 LIMIT 1) x) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, c.state))) AND (c.sector_id IN ( SELECT ssec.sector_id
           FROM selector_sector ssec
          WHERE ssec.cur_user = CURRENT_USER)) AND (c.muni_id IN ( SELECT sm.muni_id
           FROM selector_municipality sm
          WHERE sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE se.cur_user = CURRENT_USER AND (se.expl_id = c.expl_id OR (se.expl_id = ANY (c.expl_visibility)))));

CREATE OR REPLACE VIEW vf_element
AS SELECT e.element_id,
    pp.state AS p_state
   FROM element e
     LEFT JOIN man_frelem mf ON e.element_id = mf.element_id
     LEFT JOIN LATERAL ( SELECT pp_1.state
           FROM plan_psector_x_node pp_1
          WHERE pp_1.node_id = mf.node_id AND (pp_1.psector_id IN ( SELECT sp.psector_id
                   FROM selector_psector sp
                  WHERE sp.cur_user = CURRENT_USER))
          ORDER BY pp_1.psector_id DESC
         LIMIT 1) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, e.state))) AND ((e.sector_id IN ( SELECT ssec.sector_id
           FROM selector_sector ssec
          WHERE ssec.cur_user = CURRENT_USER)) OR (EXISTS ( SELECT 1
           FROM element_x_sector_visibility sv
             JOIN selector_sector ssec ON ssec.sector_id = sv.sector_id AND ssec.cur_user = CURRENT_USER
          WHERE sv.element_id = e.element_id))) AND ((e.muni_id IN ( SELECT sm.muni_id
           FROM selector_municipality sm
          WHERE sm.cur_user = CURRENT_USER)) OR (EXISTS ( SELECT 1
           FROM element_x_municipality_visibility mv
             JOIN selector_municipality sm ON sm.muni_id = mv.muni_id AND sm.cur_user = CURRENT_USER
          WHERE mv.element_id = e.element_id))) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE se.cur_user = CURRENT_USER AND (se.expl_id = e.expl_id OR (se.expl_id = ANY (e.expl_visibility)))));

CREATE OR REPLACE VIEW vf_link
AS SELECT l.link_id,
    pp.state AS p_state
   FROM link l
     LEFT JOIN LATERAL ( SELECT x.connec_id,
            x.psector_id
           FROM ( SELECT 1
                  WHERE (EXISTS ( SELECT 1
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))) gate
             CROSS JOIN LATERAL ( SELECT pp1.connec_id,
                    pp1.psector_id
                   FROM plan_psector_x_connec pp1
                  WHERE pp1.connec_id = l.feature_id AND (pp1.psector_id IN ( SELECT sp.psector_id
                           FROM selector_psector sp
                          WHERE sp.cur_user = CURRENT_USER))
                  ORDER BY pp1.psector_id DESC
                 LIMIT 1) x) last_ps ON true
     LEFT JOIN LATERAL ( SELECT x.state
           FROM ( SELECT 1
                  WHERE last_ps.psector_id IS NOT NULL) gate
             CROSS JOIN LATERAL ( SELECT pp2.state
                   FROM plan_psector_x_connec pp2
                  WHERE pp2.link_id = l.link_id AND pp2.psector_id = last_ps.psector_id
                 LIMIT 1) x) pp ON true
  WHERE (EXISTS ( SELECT 1
           FROM selector_state ss
          WHERE ss.cur_user = CURRENT_USER AND ss.state_id = COALESCE(pp.state, l.state))) AND (l.sector_id IN ( SELECT ssec.sector_id
           FROM selector_sector ssec
          WHERE ssec.cur_user = CURRENT_USER)) AND (l.muni_id IN ( SELECT sm.muni_id
           FROM selector_municipality sm
          WHERE sm.cur_user = CURRENT_USER)) AND (EXISTS ( SELECT 1
           FROM selector_expl se
          WHERE se.cur_user = CURRENT_USER AND (se.expl_id = l.expl_id OR (se.expl_id = ANY (l.expl_visibility)))));


SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["ve_element"], "batchId":2}}$$);

CREATE OR REPLACE VIEW ve_element
AS WITH sector_visibility_agg AS (
         SELECT element_x_sector_visibility.element_id,
            array_agg(element_x_sector_visibility.sector_id ORDER BY element_x_sector_visibility.sector_id) AS sector_visibility
           FROM element_x_sector_visibility
          GROUP BY element_x_sector_visibility.element_id
        ), muni_visibility_agg AS (
         SELECT element_x_municipality_visibility.element_id,
            array_agg(element_x_municipality_visibility.muni_id ORDER BY element_x_municipality_visibility.muni_id) AS muni_visibility
           FROM element_x_municipality_visibility
          GROUP BY element_x_municipality_visibility.element_id
        )
 SELECT e.element_id,
    e.code,
    e.sys_code,
    e.top_elev,
    cat_element.element_type,
    e.elementcat_id,
    e.num_elements,
    e.epa_type,
    e.state,
    e.state_type,
    e.expl_id,
    e.muni_id,
    e.sector_id,
    e.omzone_id,
    e.function_type,
    e.category_type,
    e.location_type,
    e.observ,
    e.comment,
    cat_element.link,
    e.workcat_id,
    e.workcat_id_end,
    e.builtdate,
    e.enddate,
    e.ownercat_id,
    e.brand_id,
    e.model_id,
    e.serial_number,
    e.asset_id,
    e.verified,
    e.datasource,
    e.label_x,
    e.label_y,
    e.label_rotation,
    e.rotation,
    e.inventory,
    e.publish,
    e.trace_featuregeom,
    e.lock_level,
    e.expl_visibility,
    e.created_at,
    e.created_by,
    e.updated_at,
    e.updated_by,
    e.the_geom,
    vf.p_state,
    e.uuid,
    sva.sector_visibility,
    mva.muni_visibility,
    e.dataquality,
    e.dataquality_obs,
    vst.is_operative
   FROM element e
     JOIN vf_element vf ON vf.element_id = e.element_id
     JOIN cat_element ON e.elementcat_id::text = cat_element.id::text
     LEFT JOIN sector_visibility_agg sva ON sva.element_id = e.element_id
     LEFT JOIN muni_visibility_agg mva ON mva.element_id = e.element_id
    LEFT JOIN value_state_type vst ON vst.id = e.state_type;

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":2}}$$);

UPDATE sys_fprocess
	SET query_text='SELECT * FROM t_gully WHERE arc_id IS NULL'
	WHERE fid=455;

UPDATE sys_fprocess
	SET query_text='SELECT * FROM temp_t_node WHERE top_elev = 0'
	WHERE fid=165;

UPDATE sys_fprocess
	SET query_text='SELECT * FROM temp_t_node WHERE top_elev IS NULL'
	WHERE fid=164;

UPDATE sys_fprocess
	SET query_text='SELECT * FROM t_arc WHERE sys_elev1 = NULL OR sys_elev2 = NULL'
	WHERE fid=284;

UPDATE sys_fprocess
	SET query_text='SELECT *
FROM t_arc a
JOIN cat_arc c ON c.id = a.matcat_id  
WHERE a.matcat_id IS null
AND sys_type !=''VARC'''
	WHERE fid=569;

UPDATE sys_fprocess
	SET query_text='SELECT * FROM t_node WHERE epa_type !=''UNDEFINED'' AND sys_elev IS NULL'
	WHERE fid=584;

UPDATE sys_fprocess
	SET query_text='SELECT *
FROM t_arc a
JOIN cat_arc c ON c.id = a.cat_matcat_id  
WHERE a.cat_matcat_id IS null
AND sys_type !=''VARC'''
	WHERE fid=430;

UPDATE sys_fprocess
	SET query_text='SELECT n.node_id, nodecat_id, the_geom, n.expl_id
FROM (
	SELECT node_1 node_id, sector_id
	FROM t_arc
	WHERE epa_type !=''UNDEFINED''
	UNION 
	SELECT node_2, sector_id
	FROM t_arc
	WHERE epa_type !=''UNDEFINED''
)a
JOIN (
	SELECT node_id, nodecat_id, the_geom, expl_id
	FROM t_node
	WHERE epa_type = ''UNDEFINED''
) n USING (node_id) 
WHERE n.node_id IS NOT NULL'
	WHERE fid=379;

UPDATE sys_fprocess
	SET query_text='SELECT node_id, nodecat_id, expl_id, t_node.the_geom, ''Node sink'' FROM t_node WHERE epa_type !=''UNDEFINED'' AND node_id IN
	(SELECT node_1 FROM (SELECT arc_id, node_1, node_2 FROM t_arc JOIN cat_arc c ON c.id = arccat_id 
	JOIN cat_arc_shape s ON c.shape = s.id WHERE slope < 0 AND s.epa != ''FORCE_MAIN'')a
	EXCEPT 
	SELECT node_1 FROM (SELECT arc_id, node_1, node_2 FROM t_arc JOIN cat_arc c ON c.id = arccat_id 
	JOIN cat_arc_shape s ON c.shape = s.id WHERE slope > 0)a)'
	WHERE fid=113;

UPDATE sys_fprocess
	SET query_text='
SELECT * FROM (
SELECT node_id, nodecat_id, n.the_geom, n.expl_id FROM t_node n  
JOIN t_arc a1 ON node_id=a1.node_1  AND n.epa_type IN (''SHORTPIPE'', ''VALVE'', ''PUMP'')
UNION ALL 
SELECT node_id, nodecat_id, n.the_geom, n.expl_id FROM t_node n  
JOIN t_arc a1 ON node_id=a1.node_2  AND n.epa_type IN (''SHORTPIPE'', ''VALVE'', ''PUMP''))a 
GROUP by node_id, nodecat_id, the_geom, expl_id HAVING count(*) > 2'
	WHERE fid=166;

UPDATE sys_fprocess
	SET query_text='SELECT *FROM (
SELECT node_id, nodecat_id, t_node.the_geom, t_node.expl_id FROM t_node 
JOIN t_arc a1 ON node_id=a1.node_1 WHERE t_node.epa_type IN (''VALVE'', ''PUMP'') UNION ALL
SELECT node_id, nodecat_id, t_node.the_geom, t_node.expl_id FROM t_node 
JOIN t_arc a1 ON node_id=a1.node_1 WHERE t_node.epa_type IN (''VALVE'', ''PUMP''))a 
GROUP by node_id, nodecat_id, the_geom, expl_id HAVING count(*) < 2'
	WHERE fid=167;

UPDATE sys_fprocess
	SET query_text='SELECT n.node_id, n.nodecat_id, n.the_geom, n.expl_id FROM t_node n WHERE NOT EXISTS (SELECT 1 FROM t_arc a WHERE a.node_1 = n.node_id) AND NOT EXISTS (SELECT 1 FROM t_arc a WHERE a.node_2 = n.node_id)
AND epa_type !=''UNDEFINED'' AND is_operative'
	WHERE fid=228;

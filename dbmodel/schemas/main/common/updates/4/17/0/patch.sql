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

WITH numbered AS (
    SELECT id,
        typevalue,
        (ROW_NUMBER() OVER (ORDER BY id COLLATE "C")) - 1 AS new_id
    FROM config_typevalue
    WHERE typevalue = 'sys_table_context'
)
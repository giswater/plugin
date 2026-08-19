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

UPDATE sys_function
   SET descript = 'Function for getting features filtering by sys_type, featureType or config_form_list tableName'
 WHERE id = 3484;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4680, 'GeoJSON output requires a the_geom column in the resolved query for tableName %tableName%', 'Include the_geom in config_form_list.query_text', 2, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3566, 'gw_fct_build_filters_sql', 'utils', 'function', 'json, text', 'text', 'Build SQL AND clauses from filterFields json for list and feature queries', NULL, NULL, 'core', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3568, 'gw_fct_resolve_list_query', 'utils', 'function', 'text, integer', 'json', 'Resolve config_form_list query_text and metadata for a listname', NULL, NULL, 'core', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3570, 'gw_fct_build_canvas_filter_sql', 'utils', 'function', 'text, double precision, double precision, double precision, double precision, integer', 'text', 'Build SQL canvas extend filter for a geometry expression', NULL, NULL, 'core', NULL)
ON CONFLICT (id) DO NOTHING;

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

DO $$
DECLARE
	v_rel text;
BEGIN
	IF EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_schema = current_schema()
		  AND table_name = 'cat_feature'
		  AND column_name = 'abrevation'
	) THEN
		ALTER TABLE cat_feature RENAME COLUMN abrevation TO abbreviation;
	END IF;

	IF EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_schema = current_schema()
		  AND table_name = 'config_mapzones'
		  AND column_name = 'abrevation'
	) THEN
		ALTER TABLE config_mapzones RENAME COLUMN abrevation TO abbreviation;
	END IF;

	FOREACH v_rel IN ARRAY ARRAY[
		've_cat_feature_arc',
		've_cat_feature_connec',
		've_cat_feature_element',
		've_cat_feature_link',
		've_cat_feature_node',
		've_cat_feature_gully'
	]
	LOOP
		IF EXISTS (
			SELECT 1 FROM information_schema.columns
			WHERE table_schema = current_schema()
			  AND table_name = v_rel
			  AND column_name = 'abrevation'
		) THEN
			EXECUTE format('ALTER TABLE %I RENAME COLUMN abrevation TO abbreviation', v_rel);
		END IF;
	END LOOP;
END $$;

UPDATE config_code_parts
SET part = 'abbreviation',
    source_expr = replace(source_expr, 'abrevation', 'abbreviation'),
    descript = replace(descript, 'abrevation', 'abbreviation')
WHERE part = 'abrevation';


-- Graph inundation materialization (avoid large GeoJSON temporal layers in QGIS)
CREATE TABLE IF NOT EXISTS anl_graphinundation (
	id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	fid integer NOT NULL DEFAULT 710,
	cur_user character varying(30) DEFAULT CURRENT_USER::text NOT NULL,
	mapzone text,
	arc_id character varying(16) NOT NULL,
	start_vid bigint,
	node_1 character varying(16),
	node_2 character varying(16),
	arc_type character varying(30),
	arccat_id character varying(30),
	state integer,
	state_type integer,
	is_operative boolean,
	mapzone_id text,
	old_mapzone_id text,
	descript text,
	timestep timestamp without time zone,
	the_geom public.geometry(LineString, SRID_VALUE)
);

CREATE INDEX IF NOT EXISTS anl_graphinundation_cur_user_fid_idx
	ON anl_graphinundation USING btree (cur_user, fid);
CREATE INDEX IF NOT EXISTS anl_graphinundation_cur_user_timestep_idx
	ON anl_graphinundation USING btree (cur_user, timestep);
CREATE INDEX IF NOT EXISTS anl_graphinundation_the_geom_idx
	ON anl_graphinundation USING gist (the_geom);

CREATE OR REPLACE VIEW v_anl_graphinundation AS
SELECT
	id,
	fid,
	cur_user,
	mapzone,
	arc_id,
	start_vid,
	node_1,
	node_2,
	arc_type,
	arccat_id,
	state,
	state_type,
	is_operative,
	mapzone_id,
	old_mapzone_id,
	descript,
	timestep,
	the_geom
FROM anl_graphinundation
WHERE cur_user = CURRENT_USER::text;

INSERT INTO sys_table (id, descript, sys_role, alias, "source")
VALUES
	('anl_graphinundation', 'Table with graph inundation temporal analysis arcs', 'role_om', NULL, 'core'),
	('v_anl_graphinundation', 'View with graph inundation temporal analysis arcs for current user', 'role_edit', 'Graphanalytics tstep process', 'core')
ON CONFLICT (id) DO NOTHING;

INSERT INTO config_table (id, style, group_layer)
VALUES ('v_anl_graphinundation', 0, 'GW Temporal Layers')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_fprocess (fid, fprocess_name, project_type, "source", fprocess_type, function_name, active)
VALUES (710, 'Graph inundation temporal analysis', 'utils', 'core', 'Function process', '[gw_fct_getgraphinundation]', true)
ON CONFLICT (fid) DO NOTHING;

UPDATE sys_function
SET descript = 'Materializes graph inundation temporal arcs into anl_graphinundation and returns the layer metadata for QGIS'
WHERE id = 3338;

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

CREATE OR REPLACE VIEW vf_node AS
SELECT
  n.node_id,
  pp.state AS p_state
FROM
  node n
  LEFT JOIN LATERAL (
    SELECT
      x.state
    FROM
      (
        SELECT
          1
        WHERE
          (
            EXISTS (
              SELECT
                1
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
      ) gate
      CROSS JOIN LATERAL (
        SELECT
          pp_1.state
        FROM
          plan_psector_x_node pp_1
        WHERE
          pp_1.node_id = n.node_id
          AND (
            pp_1.psector_id IN (
              SELECT
                sp.psector_id
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
        ORDER BY
          pp_1.psector_id DESC
        LIMIT
          1
      ) x
  ) pp ON TRUE
WHERE
  (
    EXISTS (
      SELECT
        1
      FROM
        selector_state ss
      WHERE
        ss.cur_user = CURRENT_USER
        AND ss.state_id = COALESCE(pp.state, n.state)
    )
  )
  AND (
    (
      n.sector_id IN (
        SELECT
          ssec.sector_id
        FROM
          selector_sector ssec
        WHERE
          ssec.cur_user = CURRENT_USER
      )
    )
    OR (
      EXISTS (
        SELECT
          1
        FROM
          node_x_sector_visibility sv
          JOIN selector_sector ssec ON ssec.sector_id = sv.sector_id
          AND ssec.cur_user = CURRENT_USER
        WHERE
          sv.node_id = n.node_id
      )
    )
    OR pp.state IS NOT NULL
  )
  AND (
    (
      n.muni_id IN (
        SELECT
          sm.muni_id
        FROM
          selector_municipality sm
        WHERE
          sm.cur_user = CURRENT_USER
      )
    )
    OR (
      EXISTS (
        SELECT
          1
        FROM
          node_x_municipality_visibility mv
          JOIN selector_municipality sm ON sm.muni_id = mv.muni_id
          AND sm.cur_user = CURRENT_USER
        WHERE
          mv.node_id = n.node_id
      )
    )
  )
  AND (
    EXISTS (
      SELECT
        1
      FROM
        selector_expl se
      WHERE
        se.cur_user = CURRENT_USER
        AND (
          se.expl_id = n.expl_id
          OR (se.expl_id = ANY (n.expl_visibility))
        )
    )
  );

CREATE OR REPLACE VIEW vf_arc AS
SELECT
  a.arc_id,
  pp.state AS p_state
FROM
  arc a
  LEFT JOIN LATERAL (
    SELECT
      x.state
    FROM
      (
        SELECT
          1
        WHERE
          (
            EXISTS (
              SELECT
                1
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
      ) gate
      CROSS JOIN LATERAL (
        SELECT
          pp_1.state
        FROM
          plan_psector_x_arc pp_1
        WHERE
          pp_1.arc_id = a.arc_id
          AND (
            pp_1.psector_id IN (
              SELECT
                sp.psector_id
              FROM
                selector_psector sp
              WHERE
                sp.cur_user = CURRENT_USER
            )
          )
        ORDER BY
          pp_1.psector_id DESC
        LIMIT
          1
      ) x
  ) pp ON TRUE
WHERE
  (
    EXISTS (
      SELECT
        1
      FROM
        selector_state ss
      WHERE
        ss.cur_user = CURRENT_USER
        AND ss.state_id = COALESCE(pp.state, a.state)
    )
  )
  AND (
    (
      a.sector_id IN (
        SELECT
          ssec.sector_id
        FROM
          selector_sector ssec
        WHERE
          ssec.cur_user = CURRENT_USER
      )
    )
    OR pp.state IS NOT NULL
  )
  AND (
    a.muni_id IN (
      SELECT
        sm.muni_id
      FROM
        selector_municipality sm
      WHERE
        sm.cur_user = CURRENT_USER
    )
  )
  AND (
    EXISTS (
      SELECT
        1
      FROM
        selector_expl se
      WHERE
        se.cur_user = CURRENT_USER
        AND (
          se.expl_id = a.expl_id
          OR (se.expl_id = ANY (a.expl_visibility))
        )
    )
  );

CREATE OR REPLACE VIEW vf_element AS
SELECT
  e.element_id,
  pp.state AS p_state
FROM
  element e
  LEFT JOIN man_frelem mf ON e.element_id = mf.element_id
  LEFT JOIN LATERAL (
    SELECT
      pp_1.state
    FROM
      plan_psector_x_node pp_1
    WHERE
      pp_1.node_id = mf.node_id
      AND (
        pp_1.psector_id IN (
          SELECT
            sp.psector_id
          FROM
            selector_psector sp
          WHERE
            sp.cur_user = CURRENT_USER
        )
      )
    ORDER BY
      pp_1.psector_id DESC
    LIMIT
      1
  ) pp ON TRUE
WHERE
  (
    EXISTS (
      SELECT
        1
      FROM
        selector_state ss
      WHERE
        ss.cur_user = CURRENT_USER
        AND ss.state_id = COALESCE(pp.state, e.state)
    )
  )
  AND (
    (
      e.sector_id IN (
        SELECT
          ssec.sector_id
        FROM
          selector_sector ssec
        WHERE
          ssec.cur_user = CURRENT_USER
      )
    )
    OR (
      EXISTS (
        SELECT
          1
        FROM
          element_x_sector_visibility sv
          JOIN selector_sector ssec ON ssec.sector_id = sv.sector_id
          AND ssec.cur_user = CURRENT_USER
        WHERE
          sv.element_id = e.element_id
      )
    )
    OR pp.state IS NOT NULL
  )
  AND (
    (
      e.muni_id IN (
        SELECT
          sm.muni_id
        FROM
          selector_municipality sm
        WHERE
          sm.cur_user = CURRENT_USER
      )
    )
    OR (
      EXISTS (
        SELECT
          1
        FROM
          element_x_municipality_visibility mv
          JOIN selector_municipality sm ON sm.muni_id = mv.muni_id
          AND sm.cur_user = CURRENT_USER
        WHERE
          mv.element_id = e.element_id
      )
    )
  )
  AND (
    EXISTS (
      SELECT
        1
      FROM
        selector_expl se
      WHERE
        se.cur_user = CURRENT_USER
        AND (
          se.expl_id = e.expl_id
          OR (se.expl_id = ANY (e.expl_visibility))
        )
    )
  );

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

UPDATE sys_fprocess SET
fprocess_name = 'Check roughness configuration'
WHERE fid = 377;
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

-- Add userdefined_geom checkbox to link info forms when missing
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT
            f.formname,
            COALESCE((
                SELECT MAX(c.layoutorder)
                FROM config_form_fields c
                WHERE c.formname = f.formname
                  AND c.formtype = 'form_feature'
                  AND c.tabname = 'tab_data'
                  AND c.layoutname = 'lyt_data_1'
            ), 0) AS max_layoutorder,
            COALESCE((
                SELECT MAX(c.web_layoutorder)
                FROM config_form_fields c
                WHERE c.formname = f.formname
                  AND c.formtype = 'form_feature'
                  AND c.tabname = 'tab_data'
            ), 0) AS max_web_layoutorder
        FROM config_form_fields f
        WHERE f.formname LIKE 've_link%'
          AND f.formtype = 'form_feature'
          AND f.tabname = 'tab_data'
        GROUP BY f.formname
    LOOP
        INSERT INTO config_form_fields (
            formname, formtype, tabname, columnname, layoutname, layoutorder,
            "datatype", widgettype, "label", tooltip, placeholder,
            ismandatory, isparent, iseditable, isautoupdate, isfilter,
            dv_querytext, dv_orderby_id, dv_isnullvalue, dv_parent_id,
            dv_querytext_filterc, stylesheet, widgetcontrols, widgetfunction,
            linkedobject, hidden, web_layoutorder
        ) VALUES (
            r.formname, 'form_feature', 'tab_data', 'userdefined_geom', 'lyt_data_1', r.max_layoutorder + 1,
            'boolean', 'check', 'User defined:', 'When checked, connect to network ignores this link', NULL,
            false, false, true, false, NULL,
            NULL, NULL, NULL, NULL,
            NULL, NULL, '{"setMultiline":false}'::json, NULL,
            NULL, false, r.max_web_layoutorder + 1
        )
        ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;
    END LOOP;
END $$;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4682, 'Cannot force connection to a node while arcs are selected.', 'Clear the selected arcs and try again.', 2, true, 'ud', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4684, 'The %feature_type% with id %connec_id% has been successfully connected to the node with id %node_id%', NULL, 0, true, 'ud', 'core', 'AUDIT')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4686, 'No network feature found for %feature_type% with id %connect_id% matching the current filters.',
 'Relax extra filters, max distance or pipe diameter and try again.', 1, true, 'utils', 'core', 'AUDIT')
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

-- Add isvalidated to EPA results
ALTER TABLE rpt_cat_result ADD COLUMN IF NOT EXISTS isvalidated boolean DEFAULT false;
UPDATE rpt_cat_result SET isvalidated = false WHERE isvalidated IS NULL;
ALTER TABLE rpt_cat_result ALTER COLUMN isvalidated SET DEFAULT false;
ALTER TABLE rpt_cat_result ALTER COLUMN isvalidated SET NOT NULL;

-- Remove DEPRECATED status (legacy; never assigned by Go2Epa UI/API)
UPDATE rpt_cat_result SET status = 3 WHERE status = 0;  -- ARCHIVED
DELETE FROM inp_typevalue WHERE typevalue = 'inp_result_status' AND id = '0';
ALTER TABLE rpt_cat_result DROP CONSTRAINT IF EXISTS rpt_cat_result_status_check;
ALTER TABLE rpt_cat_result ADD CONSTRAINT rpt_cat_result_status_check
  CHECK (status = ANY (ARRAY[1, 2, 3, 4]));

INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
SELECT
    'epa_toolbar', 'utils', 'v_ui_rpt_cat_result', 'isvalidated',
    (SELECT COALESCE(MAX(columnindex), 0) + 1 FROM config_form_tableview
     WHERE location_type = 'epa_toolbar' AND project_type = 'utils' AND objectname = 'v_ui_rpt_cat_result'),
    true, NULL, 'Isvalidated', NULL, NULL
WHERE NOT EXISTS (
    SELECT 1 FROM config_form_tableview
    WHERE location_type = 'epa_toolbar' AND project_type = 'utils'
      AND objectname = 'v_ui_rpt_cat_result' AND columnname = 'isvalidated'
);

-- Mapzone manager create/update forms: array fields are optional with default Undefined (0)
UPDATE config_form_fields SET
    ismandatory = false,
    dv_querytext = 'SELECT expl_id AS id, name AS idval FROM exploitation WHERE expl_id = 0 UNION ALL SELECT expl_id AS id, name AS idval FROM vf_exploitation',
    widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"vdefault_value": "0"}'::jsonb)::json
WHERE formtype = 'form_feature' AND tabname = 'tab_none'
  AND widgettype = 'multiple_option' AND columnname = 'expl_id';

UPDATE config_form_fields SET
    ismandatory = false,
    dv_querytext = 'SELECT sector_id AS id, name AS idval FROM sector WHERE sector_id >= 0',
    widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"vdefault_value": "0"}'::jsonb)::json
WHERE formtype = 'form_feature' AND tabname = 'tab_none'
  AND widgettype = 'multiple_option' AND columnname = 'sector_id';

UPDATE config_form_fields SET
    ismandatory = false,
    dv_querytext = 'SELECT muni_id AS id, name AS idval FROM v_municipality WHERE muni_id >= 0',
    widgetcontrols = (COALESCE(widgetcontrols::jsonb, '{}'::jsonb) || '{"vdefault_value": "0"}'::jsonb)::json
WHERE formtype = 'form_feature' AND tabname = 'tab_none'
  AND widgettype = 'multiple_option' AND columnname = 'muni_id';

-- Mapzone PK is assigned by urn_id_seq; user must not fill it
-- widgettype text: UD 4.2.1 also flipped ve_sector.sector_id to list via columnname IN (expl_id, sector_id, muni_id)
UPDATE config_form_fields SET
    ismandatory = false,
    iseditable = false,
    widgettype = 'text'
WHERE formtype = 'form_feature' AND tabname = 'tab_none'
  AND formname IN (
      've_sector', 've_dma', 've_dqa', 've_presszone', 've_supplyzone',
      've_macrodma', 've_macrodqa', 've_macrosector', 've_omzone',
      've_macroomzone', 've_drainzone', 've_dwfzone'
  )
  AND columnname = replace(formname, 've_', '') || '_id';

-- Undefined (0) catalog rows required so ARRAY[0] passes trigger @> checks
INSERT INTO macroexploitation (macroexpl_id, code, "name", active)
VALUES (0, '0', 'Undefined', true)
ON CONFLICT (macroexpl_id) DO NOTHING;

INSERT INTO exploitation (expl_id, code, "name", macroexpl_id, active)
VALUES (0, '0', 'Undefined', 0, true)
ON CONFLICT (expl_id) DO NOTHING;

INSERT INTO macrosector (macrosector_id, code, "name", active)
VALUES (0, '0', 'Undefined', true)
ON CONFLICT (macrosector_id) DO NOTHING;

INSERT INTO sector (sector_id, code, "name", macrosector_id, active)
VALUES (0, '0', 'Undefined', 0, true)
ON CONFLICT (sector_id) DO NOTHING;

-- Lookup tables for native QGIS ValueRelation.
-- sys_table.context is the numeric config_typevalue.id (since 4.5.0), not the JSON.
-- sys_feature_type stays HIDDEN (system catalog, not in Add Layers).
-- macroexploitation: context MAP ZONES for Add Layers; no project_template so VR loads it into HIDDEN if missing.
UPDATE sys_table
SET project_template = '{"template": [1], "visibility": false, "levels_to_read": 1}'::json,
    context = (
        SELECT id FROM config_typevalue
        WHERE typevalue = 'sys_table_context'
          AND (idval = '["HIDDEN"]' OR addparam->>'orderBy' = '999')
        LIMIT 1
    ),
    alias = COALESCE(alias, 'Feature type')
WHERE id = 'sys_feature_type';

UPDATE sys_table
SET project_template = NULL,
    context = (
        SELECT id FROM config_typevalue
        WHERE typevalue = 'sys_table_context'
          AND idval = '["INVENTORY", "MAP ZONES"]'
        LIMIT 1
    ),
    alias = COALESCE(alias, 'Macroexploitation'),
    addparam = (COALESCE(addparam::jsonb, '{}'::jsonb) || '{"pkey": "macroexpl_id"}'::jsonb)::json
WHERE id = 'macroexploitation';

-- Native form: catalog table, not selector-filtered ve_macroexploitation
UPDATE config_form_fields
SET dv_querytext = 'SELECT macroexpl_id AS id, name AS idval FROM macroexploitation WHERE active IS TRUE',
    widgetcontrols = (
        COALESCE(widgetcontrols::jsonb, '{}'::jsonb)
        || '{"valueRelation":{"nullValue":false, "layer": "macroexploitation", "activated": true, "keyColumn": "macroexpl_id", "valueColumn": "name", "filterExpression": "\"active\" = true"}}'::jsonb
    )::json
WHERE columnname = 'macroexpl_id'
  AND formname IN ('ve_exploitation', 'exploitation');

-- PK text/list fields must not be ValueRelation (leftover self-VR from ~4.2 on expl_id/dma_id/...)
-- widgettype list: UD 4.2.1 also flipped ve_sector.sector_id via columnname IN (expl_id, sector_id, muni_id)
UPDATE config_form_fields
SET widgetcontrols = (widgetcontrols::jsonb - 'valueRelation')::json
WHERE widgettype IN ('text', 'list')
  AND widgetcontrols::jsonb ? 'valueRelation'
  AND widgetcontrols::jsonb -> 'valueRelation' ->> 'keyColumn' = columnname
  AND widgetcontrols::jsonb -> 'valueRelation' ->> 'layer' IN (
      formname,
      've_' || formname,
      replace(formname, 've_', '')
  );

DELETE FROM config_param_system WHERE parameter = 'edit_feature_auto_builtdate';

-- Mapzone combos are no longer children of expl_id (mapzone.expl_id is integer[]).
UPDATE config_form_fields
SET dv_parent_id = NULL, dv_querytext_filterc = NULL
WHERE columnname IN ('dma_id', 'presszone_id', 'dwfzone_id')
  AND (
      dv_parent_id = 'expl_id'
      OR dv_querytext_filterc ILIKE '%expl_id%'
  );

UPDATE config_form_fields c
SET isparent = false
WHERE columnname = 'expl_id'
  AND isparent IS TRUE
  AND NOT EXISTS (
    SELECT 1 FROM config_form_fields x
    WHERE x.formname = c.formname
      AND x.formtype = c.formtype
      AND x.tabname = c.tabname
      AND x.dv_parent_id = 'expl_id'
  );


CREATE OR REPLACE VIEW ve_municipality
AS SELECT DISTINCT m.muni_id,
    m.name,
    m.active,
    m.the_geom
   FROM v_municipality m
   WHERE EXISTS (SELECT 1 FROM selector_municipality s WHERE s.muni_id = m.muni_id AND s.cur_user = CURRENT_USER);

UPDATE config_form_fields
SET widgetcontrols = (
    COALESCE(widgetcontrols::jsonb, '{}'::jsonb)
    || '{"valueRelation": {"layer": "ve_municipality", "activated": true, "keyColumn": "muni_id", "nullValue": false, "valueColumn": "name", "filterExpression": null}}'::jsonb
)::json
WHERE columnname = 'muni_id'
  AND formtype = 'form_feature'
  AND tabname = 'tab_data'
  AND widgettype = 'combo';

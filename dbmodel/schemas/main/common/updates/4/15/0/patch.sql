/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

DO $patch$
BEGIN
    IF (SELECT value::boolean FROM config_param_system WHERE parameter = 'admin_cibs_schema') IS NOT TRUE THEN
        PERFORM gw_fct_admin_manage_view_dependencies(
            json_build_object(
                'data', json_build_object(
                    'action', 'SAVE-DROP',
                    'rootViews', json_build_array('v_hydrometer'),
                    'batchId', 1
                )
            )
        );
        ALTER TABLE ext_hydrometer ALTER COLUMN wmeter_number TYPE text USING wmeter_number::text;
        CREATE OR REPLACE VIEW v_hydrometer AS SELECT * FROM ext_hydrometer;
        PERFORM gw_fct_admin_manage_view_dependencies(
            json_build_object(
                'data', json_build_object(
                    'action', 'RESTORE',
                    'rootViews', json_build_array('v_hydrometer'),
                    'batchId', 1
                )
            )
        );
    END IF;
END $patch$;

CREATE UNIQUE INDEX link_feature_id_state1_unique
ON link (feature_id, feature_type)
WHERE state = 1 AND feature_id IS NOT NULL;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4370, 'Invalid or missing QGIS project CRS (EPSG). Please configure a valid projected coordinate system.', NULL, 0, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4371, 'QGIS project CRS is geographic (lat/long). INP export requires a projected CRS (e.g. EPSG:8908 CRTM05 for Costa Rica). Change the project CRS in QGIS and retry.', NULL, 0, true, 'utils', 'core', 'UI')
ON CONFLICT (id) DO NOTHING;

CREATE SEQUENCE seq_feature_code
    START 1
    INCREMENT 1
    MAXVALUE 99999999;  -- maximum 8 digits

CREATE SEQUENCE seq_mapzone_code
    START 1
    INCREMENT 1
    MAXVALUE 99999;  -- maximum 5 digits

CREATE TABLE IF NOT EXISTS config_mapzones (
    id varchar(30) PRIMARY KEY, -- name
    abrevation varchar(30),
    descript text,
    fid integer,
    code_autofill bool,
    active bool,
    is_dynamic bool
);

INSERT INTO config_mapzones (id, abrevation, descript, fid, code_autofill, active, is_dynamic) VALUES
('MACROSECTOR', 'MAC', 'Macrosector', NULL, true, true, true),
('MACRODMA', 'MAC', 'Macrodma', NULL, true, true, true),
('MACROOMZONE', 'MAC', 'Macroomzone', NULL, true, true, true),
('SECTOR', 'SEC', 'Sector', 130, true, true, true),
('DMA', 'DMA', 'Distribution Management Area', 145, true, true, true),
('OMZONE', 'OM', 'Omzone', NULL, true, true, true)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE cat_feature ADD COLUMN abrevation varchar(30);

UPDATE cat_feature
SET abrevation = addparam::jsonb->>'code_prefix'
WHERE addparam::jsonb ? 'code_prefix';

UPDATE cat_feature
SET addparam = addparam::jsonb - 'code_prefix'
WHERE addparam::jsonb ? 'code_prefix';

CREATE TABLE config_code_parts (
    id serial PRIMARY KEY,
    context varchar(10) NOT NULL CHECK (context IN ('feature', 'mapzone')),
    entity varchar(30),
    part varchar(30) NOT NULL,
    source_expr text NOT NULL,
    concat_order int NOT NULL,
    descript text,
    active bool DEFAULT true
);

CREATE UNIQUE INDEX config_code_parts_context_entity_part_uidx
ON config_code_parts (context, entity, part) NULLS NOT DISTINCT;

CREATE UNIQUE INDEX config_code_parts_context_entity_order_uidx
ON config_code_parts (context, entity, concat_order) NULLS NOT DISTINCT;

INSERT INTO config_code_parts (context, entity, part, source_expr, concat_order, descript, active) VALUES
('feature', NULL, 'separator', $$'_'::text$$, 2, 'Underscore separator', true),
('feature', NULL, 'sequence', $$lpad(nextval('seq_feature_code')::text, 8, '0')$$, 3, 'Global feature sequence suffix', true),
('feature', 'NODE', 'abrevation', '(SELECT abrevation FROM cat_feature WHERE id = ($1::json->>''node_type''))', 1, 'Catalog abrevation for nodes', true),
('feature', 'ARC', 'abrevation', '(SELECT abrevation FROM cat_feature WHERE id = ($1::json->>''arc_type''))', 1, 'Catalog abrevation for arcs', true),
('feature', 'CONNEC', 'abrevation', '(SELECT abrevation FROM cat_feature WHERE id = ($1::json->>''connec_type''))', 1, 'Catalog abrevation for connecs', true),
('feature', 'GULLY', 'abrevation', '(SELECT abrevation FROM cat_feature WHERE id = ($1::json->>''gully_type''))', 1, 'Catalog abrevation for gullies', true),
('feature', 'ELEMENT', 'abrevation', '(SELECT abrevation FROM cat_feature WHERE id = ($1::json->>''elementcat_id''))', 1, 'Catalog abrevation for elements', true),
('feature', 'LINK', 'abrevation', '(SELECT abrevation FROM cat_feature WHERE id = ($1::json->>''feature_type''))', 1, 'Catalog abrevation for links', true),
('mapzone', NULL, 'abrevation', '(SELECT abrevation FROM config_mapzones WHERE id = $2)', 1, 'Mapzone abrevation prefix', true),
('mapzone', NULL, 'separator', $$'_'::text$$, 2, 'Underscore separator', true),
('mapzone', NULL, 'sequence', $$lpad(nextval('seq_mapzone_code')::text, 5, '0')$$, 3, 'Global mapzone sequence suffix', true)
ON CONFLICT (context, entity, part) DO UPDATE SET
  source_expr = EXCLUDED.source_expr,
  concat_order = EXCLUDED.concat_order,
  descript = EXCLUDED.descript,
  active = EXCLUDED.active;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3542, 'gw_fct_generate_code', 'utils', 'function', 'text, text, json', 'text',
'Generate autofill code for features or mapzones using configurable SQL templates',
'role_basic', NULL, 'core', NULL)
ON CONFLICT (id) DO UPDATE SET
  input_params = EXCLUDED.input_params,
  descript = EXCLUDED.descript;


CREATE SEQUENCE IF NOT EXISTS om_scada_graph_seq;

CREATE TABLE om_scada_graph (
	graph_class text NOT NULL DEFAULT 'NETWORK'::text,
	edge_id int4 NOT NULL DEFAULT nextval('om_scada_graph_seq'::regclass),
	object_1 int4 NOT NULL,
	object_2 int4 NOT NULL,
	order_id int4 NULL,
	active bool NULL,
	the_geom public.geometry(multilinestring, SRID_VALUE) NULL,
	objecttype_1 text NULL,
	objecttype_2 text NULL,
	attrib text NULL,
	dma_id_1 int4 NULL,
	dma_name_1 text NULL,
	dma_id_2 int4 NULL,
	dma_name_2 text NULL,
	expl_1 int4 NULL,
	expl_2 int4 NULL,
	expl_add text NULL,
	object_name_1 text NULL,
	object_name_2 text NULL,
	sist_com_1 text NULL,
	sist_com_2 text NULL,
	CONSTRAINT om_scada_graph_pkey PRIMARY KEY (edge_id)
);
CREATE INDEX object_1_idx ON om_scada_graph USING btree (object_1);
CREATE INDEX object_2_idx ON om_scada_graph USING btree (object_2);

CREATE TABLE om_scada_graph_json (
	expl_id int PRIMARY KEY,
	om_scada_graph_json json,
	insert_tstamp timestamp default now(),
	update_tstamp timestamp default null
);

-- Table Triggers
CREATE TRIGGER gw_trg_scada_graph_builder_before BEFORE INSERT OR UPDATE OF object_1, object_2 ON om_scada_graph FOR EACH ROW EXECUTE FUNCTION gw_trg_scada_graph_builder();
CREATE TRIGGER gw_trg_scada_graph_builder_after AFTER INSERT OR UPDATE OF object_1, object_2 ON om_scada_graph FOR EACH ROW EXECUTE FUNCTION gw_trg_scada_graph_builder();

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3544, 'gw_trg_scada_graph_builder', 'utils', 'trigger', 'json', 'json', 'Builds a scada graph using node_1 and node_2 as input values.', 'role_om', NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3546, 'gw_fct_scada_graph_export', 'utils', 'function', 'json', 'json', 'Exports the scada graph created into a JSON by using graph builder.', 'role_om', NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3548, 'gw_fct_scada_graph_check', 'utils', 'function', 'json', 'json', 'Checks the consistency of de attributes of the scada graph', 'role_om', NULL, 'core', NULL) ON CONFLICT (id) DO NOTHING;

INSERT INTO sys_param_user (id, formname, descript, sys_role, idval, "label", dv_querytext, dv_parent_id, isenabled, layoutorder, project_type, isparent, dv_querytext_filterc, feature_field_id, feature_dv_parent_value, isautoupdate, "datatype", widgettype, ismandatory, widgetcontrols, vdefault, layoutname, iseditable, dv_orderby_id, dv_isnullvalue, stylesheet, placeholder, "source")
VALUES ('utils_language_ui', 'hidden', 'UI language for database messages when multilang schema is enabled', 'role_basic', NULL, 'UI language', NULL, NULL, false, NULL, 'utils', false, NULL, NULL, NULL, false, 'json', 'linetext', false, NULL, '{"lang":"en_US"}', NULL, false, NULL, NULL, NULL, NULL, 'core')
ON CONFLICT (id) DO NOTHING;

INSERT INTO config_param_user (parameter, value, cur_user)
VALUES ('utils_language_ui', '{"status":true, "lang":"en_US"}', current_user)
ON CONFLICT (parameter, cur_user) DO NOTHING;

DO $patch$
BEGIN
    IF to_regprocedure('gw_fct_get_utils_language_ui()') IS NOT NULL THEN
        ALTER FUNCTION gw_fct_get_utils_language_ui() VOLATILE;
    END IF;
END $patch$;

DO $patch$
DECLARE
	v_utils boolean; 
BEGIN
	SELECT value::boolean INTO v_utils FROM config_param_system WHERE parameter='admin_utils_schema';

	IF v_utils IS FALSE THEN
		DO $$
		BEGIN
			IF EXISTS (
				SELECT 1
				FROM pg_attribute a
				JOIN pg_class c ON a.attrelid = c.oid
				JOIN pg_namespace n ON c.relnamespace = n.oid
				WHERE c.relname = 'ext_plot'
				AND n.nspname = current_schema()
				AND a.attname = 'streetaxis_id'
				AND a.attnotnull = true
			) THEN
				EXECUTE 'ALTER TABLE ext_plot ALTER COLUMN streetaxis_id DROP NOT NULL';
			END IF;
		END $$;
	END IF;
END $patch$;
 

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4676, 'The demand is OK: demand values sum to 1 per DMA because they are weight factors.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4640, 'The volume water inserted is %volume%, wich it means that lossed water percentatge due leak of data have been %percentage% %.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4642, 'The water loss could be motivated by current connecs with state = 0 which they was operative for that period with some hydrometer linked', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4644, 'New scenario: %v_name% ( %v_scenarioid% )', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4646, 'Copy from CRM period: %v_crm_name%', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4648, 'Source pattern: %v_pattern%', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4650, 'Demand units: %v_demandunits%', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4652, 'Period seconds: %v_periodseconds%', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4654, 'WARNING: The period has not data on period_seconds columns. The system default value have been used ( %v_periodseconds% ) ', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4656, 'There are %v_total_hydro% hydrometers with data for this period and this exploitation.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4658, 'The total volume (m3) for all the hydrometers is %v_total_vol%.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4660, '%v_count2% rows have been update with pattern value.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4662, '%v_count% rows have not been updated. This may be for missed data from source pattern table.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4664, 'SECTOR DEFAULT: sector table.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4666, 'DMA DEFAULT: dma table.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4668, 'DMA PERIOD: ext_rtc_dma_period table.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4670, 'HYDROMETER CATEGORY: hydrometer_category table.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4672, 'FEATURE PATTERN: inp_junction & inp_connec tables.', NULL, 1, true, 'utils', 'core', 'AUDIT');

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4674, 'INFO: There are %v_hydro_no_llegits% non-read hydrometers from %v_hydro_total% hydrometers in total (%v_percentage%% of the hydrometers)', NULL, 1, true, 'utils', 'core', 'AUDIT');

UPDATE sys_function SET function_alias = 'CREATE DSCENARIO FROM CRM' WHERE id = 3110;

UPDATE config_param_system
	SET value = jsonb_set(value::jsonb, '{sys_query_text_add}', '"SELECT distinct(concat(s.name, '', '', m.name, '', '', a.postnumber)) as \"value\", (concat(s.name, '', '', m.name, '', '', a.postnumber)) as \"displayName\" FROM ve_streetaxis s join v_municipality m using(muni_id) left join ve_address a on s.id = a.streetaxis_id WHERE concat(s.name, '', '', m.name, '', '', a.postnumber) ILIKE "')
	WHERE parameter='basic_search_v2_tab_address';

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["ve_arc","ve_node","ve_connec","ve_link","ve_element"], "saveRoots":true, "batchId":1}}$$);

ALTER TABLE arc ALTER COLUMN dataquality_obs TYPE text[] USING (dataquality_obs::text)::text[];
ALTER TABLE node ALTER COLUMN dataquality_obs TYPE text[] USING (dataquality_obs::text)::text[];
ALTER TABLE connec ALTER COLUMN dataquality_obs TYPE text[] USING (dataquality_obs::text)::text[];
ALTER TABLE link ALTER COLUMN dataquality_obs TYPE text[] USING (dataquality_obs::text)::text[];
ALTER TABLE element ALTER COLUMN dataquality_obs TYPE text[] USING (dataquality_obs::text)::text[];

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":1}}$$);

UPDATE config_param_system
SET value = (
        SELECT json_object_agg(key,
            CASE
                WHEN val::text = 'true' THEN 'uuid'
                WHEN val::text = 'false' THEN 'none'
                ELSE trim(both '"' from val::text)
            END
        )::text
        FROM json_each(value::json) AS e(key, val)
    ),
    descript = 'Auto-fill sys_code on insert per feature type: uuid (random UUID), code (copy from code), none (disabled). Legacy true/false values are still supported.'
WHERE parameter = 'edit_sys_code_autofill';

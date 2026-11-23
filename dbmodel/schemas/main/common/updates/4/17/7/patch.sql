/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- gw_fct_workspacemanager (#974) lives in base/fct.
-- update / update_step run reload_fct_ftrg before this folder, so the body
-- is not duplicated here.

-- Drop sector 0 from saved selector_sector arrays. Replace only that array
-- so the rest of config::text stays as stored and CHECK still matches.
UPDATE cat_workspace AS cw
SET
	config = regexp_replace(
		cw.config::text,
		'("selector_sector"\s*:\s*)\[[0-9,[:space:]-]*\]',
		'\1' || CASE WHEN cleaned.ids IS NULL THEN 'null' ELSE '[' || cleaned.ids || ']' END
	)::json,
	lastupdate_timestamp = now(),
	lastupdate_user = CURRENT_USER
FROM (
	SELECT
		c.id,
		(
			SELECT string_agg(v::text, ', ' ORDER BY ord)
			FROM jsonb_array_elements(elem.sector_ids) WITH ORDINALITY AS t(v, ord)
			WHERE v <> '0'::jsonb
		) AS ids
	FROM cat_workspace c
	CROSS JOIN LATERAL (
		SELECT e->'selector_sector' AS sector_ids
		FROM jsonb_array_elements(c.config::jsonb->'selectors') AS e
		WHERE e ? 'selector_sector'
		LIMIT 1
	) AS elem
	WHERE elem.sector_ids @> '[0]'::jsonb
) AS cleaned
WHERE cw.id = cleaned.id;

UPDATE sys_fprocess SET query_text = '
SELECT * FROM (WITH
	rgh as (SELECT min(roughness), max(roughness) FROM cat_mat_roughness),
	hdl as (SELECT value FROM config_param_user WHERE cur_user=current_user AND parameter=''inp_options_headloss'')
	SELECT
		case when value = ''D-W'' and (min < 0.001 or max > 0.9) then 1
				when value = ''H-W'' and (min < 110 or max > 150) then 1
				when value = ''C-M'' and (min < 0.011 or max > 0.017) then 1
				else 0 END roughness
		from rgh, hdl) a WHERE roughness = 1' WHERE fid = 377;

INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam) VALUES('info_epa', 'ud', 'inp_dwf', 'dwfscenario_id', 0, true, NULL, 'dwfscenario_id', NULL, NULL);
INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam) VALUES('info_epa', 'ud', 'inp_dwf', 'node_id', 1, true, NULL, 'Node id', NULL, NULL);
INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam) VALUES('info_epa', 'ud', 'inp_dwf', 'value', 2, true, NULL, 'Value', NULL, NULL);
INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam) VALUES('info_epa', 'ud', 'inp_dwf', 'pat1', 3, true, NULL, 'Pattern 1', NULL, NULL);
INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam) VALUES('info_epa', 'ud', 'inp_dwf', 'pat2', 4, true, NULL, 'Pattern 2', NULL, NULL);
INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam) VALUES('info_epa', 'ud', 'inp_dwf', 'pat3', 5, true, NULL, 'Pattern 3', NULL, NULL);
INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam) VALUES('info_epa', 'ud', 'inp_dwf', 'pat4', 6, true, NULL, 'Pattern 4', NULL, NULL);

-- parent_id must match result_id (varchar(50)) before the self-FK can be created.
ALTER TABLE rpt_cat_result ALTER COLUMN parent_id TYPE varchar(50);

-- Clear orphans so ADD CONSTRAINT cannot fail on upgraded databases.
UPDATE rpt_cat_result r
SET parent_id = NULL
WHERE parent_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM rpt_cat_result p WHERE p.result_id = r.parent_id
  );

ALTER TABLE rpt_cat_result DROP CONSTRAINT IF EXISTS rpt_cat_result_parent_id_fkey;
ALTER TABLE rpt_cat_result ADD CONSTRAINT rpt_cat_result_parent_id_fkey
  FOREIGN KEY (parent_id) REFERENCES rpt_cat_result(result_id)
  ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_rpt_cat_result_parent_id
  ON rpt_cat_result USING btree (parent_id);

-- Hidden by default.
INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
SELECT
    'epa_toolbar', 'utils', 'v_ui_rpt_cat_result', 'parent_id',
    (SELECT COALESCE(MAX(columnindex), 0) + 1 FROM config_form_tableview
     WHERE location_type = 'epa_toolbar' AND project_type = 'utils' AND objectname = 'v_ui_rpt_cat_result'),
    false, NULL, 'Parent id', NULL, NULL
WHERE NOT EXISTS (
    SELECT 1 FROM config_form_tableview
    WHERE location_type = 'epa_toolbar' AND project_type = 'utils'
      AND objectname = 'v_ui_rpt_cat_result' AND columnname = 'parent_id'
);

-- go2epa Close button: widgetfunction for web / dynamic clients
UPDATE config_form_fields
SET widgetfunction = '{"functionName": "closeDlg"}'::json
WHERE formname = 'generic'
  AND formtype = 'go2epa'
  AND columnname = 'btn_close'
  AND tabname = 'tab_none';

-- ve_element leaves Add Layers and the generated project.
-- GenElement and FlowRegulator take its place: loaded, unchecked, same template as ve_element had.
-- context is the numeric config_typevalue.id (since 4.5.0); FRELEMENT's id differs on ws and ud.
UPDATE sys_table
SET project_template = NULL,
    context = (
        SELECT id FROM config_typevalue
        WHERE typevalue = 'sys_table_context'
          AND idval = '["HIDDEN"]'
        LIMIT 1
    )
WHERE id = 've_element';

UPDATE sys_table
SET project_template = '{"template": [1], "visibility": false, "levels_to_read": 2}'::jsonb,
    context = (
        SELECT id FROM config_typevalue
        WHERE typevalue = 'sys_table_context'
          AND idval = '["INVENTORY", "NETWORK", "ELEMENT"]'
        LIMIT 1
    )
WHERE id IN ('ve_man_genelem', 've_man_frelem');

-- epa_results (device 5): expose isvalidated and add Toggle validated toolbar action
UPDATE config_form_list
SET query_text = REPLACE(query_text, 'iscorporate::text', 'iscorporate::text, isvalidated::text')
WHERE listname = 'epa_results'
  AND device = 5
  AND query_text ILIKE '%iscorporate::text%'
  AND query_text NOT ILIKE '%isvalidated%';

INSERT INTO config_form_tableview (location_type, project_type, objectname, columnname, columnindex, visible, width, alias, "style", addparam)
SELECT
	'epamanager_form', 'utils', 'epa_results', 'isvalidated',
	(SELECT COALESCE(MAX(columnindex), 0) + 1 FROM config_form_tableview
	 WHERE location_type = 'epamanager_form' AND project_type = 'utils' AND objectname = 'epa_results'),
	true, NULL, 'Isvalidated', NULL, '{
  "accessorKey": "isvalidated",
  "header": "isvalidated",
  "filterVariant": "text",
  "enableSorting": true,
  "enableColumnOrdering": true,
  "enableColumnFilter": true,
  "enableClickToCopy": false
}'::json
WHERE NOT EXISTS (
	SELECT 1 FROM config_form_tableview
	WHERE location_type = 'epamanager_form' AND project_type = 'utils'
	  AND objectname = 'epa_results' AND columnname = 'isvalidated'
);

UPDATE config_form_list AS cfl
SET addparam = jsonb_set(
	cfl.addparam::jsonb,
	'{renderTopToolbarCustomActions}',
	(
		SELECT COALESCE(jsonb_agg(elem ORDER BY ord), '[]'::jsonb)
		FROM (
			SELECT e AS elem, ord::numeric AS ord
			FROM jsonb_array_elements(cfl.addparam::jsonb->'renderTopToolbarCustomActions')
				WITH ORDINALITY AS t(e, ord)
			UNION ALL
			SELECT '{
				"name": "btn_toggle_validated",
				"widgetfunction": {
					"functionName": "toggleValidated",
					"params": {}
				},
				"color": "default",
				"text": "Toggle validated",
				"disableOnSelect": true,
				"moreThanOneDisable": true
			}'::jsonb,
			COALESCE(
				(
					SELECT ord::numeric + 0.5
					FROM jsonb_array_elements(cfl.addparam::jsonb->'renderTopToolbarCustomActions')
						WITH ORDINALITY AS t(e, ord)
					WHERE e->>'name' = 'btn_toggle_corporate'
					LIMIT 1
				),
				(
					SELECT ord::numeric - 0.5
					FROM jsonb_array_elements(cfl.addparam::jsonb->'renderTopToolbarCustomActions')
						WITH ORDINALITY AS t(e, ord)
					WHERE e->>'name' = 'btn_delete'
					LIMIT 1
				),
				999
			)
		) AS actions(elem, ord)
	)
)::json
WHERE cfl.listname = 'epa_results'
  AND cfl.device = 5
  AND NOT (
	COALESCE(cfl.addparam::jsonb->'renderTopToolbarCustomActions', '[]'::jsonb)
	@> '[{"name": "btn_toggle_validated"}]'::jsonb
  );

-- Create Demand Dscenario from CRM: DATE_INTERVAL log message (#989)
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4760, 'Copy from CRM date interval: %v_crm_name%', NULL, 1, true, 'utils', 'core', 'AUDIT')
ON CONFLICT (id) DO NOTHING;

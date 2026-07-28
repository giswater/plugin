/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cm, public, pg_catalog;

-- Create tables and views related with cat_feature
DO $$

DECLARE

  parent_s CONSTANT text := 'PARENT_SCHEMA';
  new_s CONSTANT text := 'cm';
  rec RECORD;
  tbl_name text;
  view_name text;
  feature_col text;
  constraint_name text;
  v_cols text;
  v_cols_no_lot text;

BEGIN

  -- Create one empty table per feature, cloning structure of the view/table
    FOR rec IN
      SELECT id, child_layer, feature_type FROM PARENT_SCHEMA.cat_feature
    LOOP

      tbl_name := format('%I_%s', parent_s, lower(rec.id));
      feature_col := lower(rec.feature_type) || '_id';
      constraint_name := tbl_name || '_uq';

      EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %s (
            id serial4 primary key,
            lot_id integer,
            LIKE %I.%I);',
      tbl_name,
      parent_s, rec.child_layer
      );

      EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %I UNIQUE (lot_id,%I);', tbl_name, constraint_name, feature_col);

      EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (lot_id) REFERENCES om_campaign_lot (lot_id) ON UPDATE CASCADE ON DELETE CASCADE;',
        tbl_name,
        tbl_name || '_lot_id_fkey'
      );

      EXECUTE format('GRANT ALL ON TABLE %s TO role_cm_field', tbl_name);

    END LOOP;

  -- Create corresponding empty views named ve_<PARENT>_lot_<feature_id>
    FOR rec IN
      SELECT id, feature_type FROM PARENT_SCHEMA.cat_feature WHERE feature_type <> 'ELEMENT'
    LOOP

      view_name := format('ve_%s_lot_%s', parent_s, lower(rec.id));
      tbl_name := format('%I_%s', parent_s, lower(rec.id));

      -- Get columns for dynamic view creation (excluding id, lot_id and the_geom)
      SELECT array_to_string(array_agg('a.' || column_name ORDER BY ordinal_position), ', ')
      INTO v_cols_no_lot
      FROM information_schema.columns
      WHERE table_schema = 'cm'
        AND table_name = lower(tbl_name)
        AND column_name NOT IN ('id','lot_id','the_geom');

      EXECUTE format(
        'CREATE OR REPLACE VIEW %s AS
          WITH sel_lot AS (
              SELECT selector_lot.lot_id FROM selector_lot
              WHERE selector_lot.cur_user = current_user
          )
          SELECT a.id, c.campaign_id, a.lot_id, %s b.status, c.the_geom
          FROM %s a
          LEFT JOIN om_campaign_lot ocl ON a.lot_id = ocl.lot_id
          LEFT JOIN om_campaign_lot_x_%s b ON a.lot_id = b.lot_id AND a.%s_id = b.%s_id
          LEFT JOIN om_campaign_x_%s c ON ocl.campaign_id = c.campaign_id AND a.%s_id = c.%s_id
          WHERE EXISTS (
            SELECT 1 
            FROM sel_lot 
            WHERE sel_lot.lot_id = a.lot_id
        );',
      view_name,
      CASE WHEN v_cols_no_lot IS NULL THEN '' ELSE v_cols_no_lot || ', ' END,
      tbl_name,
      lower(rec.feature_type),
      lower(rec.feature_type),
      lower(rec.feature_type),
      lower(rec.feature_type),
      lower(rec.feature_type),
      lower(rec.feature_type)
      );

      EXECUTE format('GRANT ALL ON TABLE %s TO role_cm_field', view_name);
      EXECUTE format('GRANT ALL ON TABLE %s TO role_cm_manager', view_name);

    END LOOP;

END
$$;


-- CAMPAIGN x FEATURE
CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_camp_node as
SELECT
ocn.id,
oc.campaign_id,
ocn.node_id,
ocn.code,
ocn.node_type,
ocn.nodecat_id,
ocn.status,
ocn.admin_observ,
ocn.org_observ,
ocn.the_geom
FROM selector_campaign sc
JOIN om_campaign oc ON oc.campaign_id = sc.campaign_id
JOIN om_campaign_x_node ocn ON ocn.campaign_id = oc.campaign_id
WHERE sc.cur_user = "current_user"()::text;


CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_camp_arc as
SELECT
oca.id,
oc.campaign_id,
oca.arc_id,
oca.code,
oca.arc_type,
oca.arccat_id,
oca.status,
oca.admin_observ,
oca.org_observ,
oca.the_geom
FROM selector_campaign sc
JOIN om_campaign oc ON oc.campaign_id = sc.campaign_id
JOIN om_campaign_x_arc oca ON oca.campaign_id = oc.campaign_id
WHERE sc.cur_user = "current_user"()::text;


CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_camp_connec as
SELECT
occ.id,
oc.campaign_id,
occ.connec_id,
occ.code,
occ.conneccat_id,
occ.status,
occ.admin_observ,
occ.org_observ,
occ.the_geom
FROM selector_campaign sc
JOIN om_campaign oc ON oc.campaign_id = sc.campaign_id
JOIN om_campaign_x_connec occ ON occ.campaign_id = oc.campaign_id
WHERE sc.cur_user = "current_user"()::text;


CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_camp_link AS
SELECT
ocl.id,
oc.campaign_id,
ocl.link_id,
ocl.code,
ocl.linkcat_id,
ocl.status,
ocl.admin_observ,
ocl.org_observ,
ocl.the_geom
FROM selector_campaign sc
JOIN om_campaign oc ON oc.campaign_id = sc.campaign_id
JOIN om_campaign_x_link ocl ON ocl.campaign_id = oc.campaign_id
WHERE sc.cur_user = "current_user"()::text;


-- LOT X FEATURE
CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_lot_node as
SELECT
ocln.id,
ocl.lot_id,
ocln.node_id,
ocln.code,
ocln.status,
ocln.org_observ,
ocln.team_observ,
ocln.update_count,
ocln.update_log,
ocln.qindex1,
ocln.qindex2,
ocln.action,
ocn.the_geom
FROM selector_lot sl
JOIN om_campaign_lot ocl ON ocl.lot_id = sl.lot_id
JOIN om_campaign_lot_x_node ocln ON ocln.lot_id = ocl.lot_id
JOIN om_campaign_x_node ocn ON ocn.campaign_id = ocl.campaign_id AND ocn.node_id = ocln.node_id
WHERE sl.cur_user = "current_user"()::text;


CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_lot_arc as
SELECT
ocla.id,
ocl.lot_id,
ocla.arc_id,
ocla.code,
ocla.status,
ocla.org_observ,
ocla.team_observ,
ocla.update_count,
ocla.update_log,
ocla.qindex1,
ocla.qindex2,
ocla.action,
oca.the_geom
FROM selector_lot sl
JOIN om_campaign_lot ocl ON ocl.lot_id = sl.lot_id
JOIN om_campaign_lot_x_arc ocla ON ocla.lot_id = ocl.lot_id
JOIN om_campaign_x_arc oca ON oca.campaign_id = ocl.campaign_id AND oca.arc_id = ocla.arc_id
WHERE sl.cur_user = "current_user"()::text;


CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_lot_connec as
SELECT
oclc.id,
ocl.lot_id,
oclc.connec_id,
oclc.code,
oclc.status,
oclc.org_observ,
oclc.team_observ,
oclc.update_count,
oclc.update_log,
oclc.qindex1,
oclc.qindex2,
oclc.action,
occ.the_geom
FROM selector_lot sl
JOIN om_campaign_lot ocl ON ocl.lot_id = sl.lot_id
JOIN om_campaign_lot_x_connec oclc ON oclc.lot_id = ocl.lot_id
JOIN om_campaign_x_connec occ ON occ.campaign_id = ocl.campaign_id AND occ.connec_id = oclc.connec_id
WHERE sl.cur_user = "current_user"()::text;



CREATE OR REPLACE VIEW ve_PARENT_SCHEMA_lot_link AS
SELECT
ocll.id,
ocl.lot_id,
ocll.link_id,
ocll.code,
ocll.status,
ocll.org_observ,
ocll.team_observ,
ocll.update_count,
ocll.update_log,
ocll.qindex1,
ocll.qindex2,
ocll.action,
oclink.the_geom
FROM selector_lot sl
JOIN om_campaign_lot ocl ON ocl.lot_id = sl.lot_id
JOIN om_campaign_lot_x_link ocll ON ocll.lot_id = ocl.lot_id
JOIN om_campaign_x_link oclink ON oclink.campaign_id = ocl.campaign_id AND oclink.link_id = ocll.link_id
WHERE sl.cur_user = "current_user"()::text;

-- Views UI documents per feature (generated dynamically)

DO $$
DECLARE
  parent_s text := 'PARENT_SCHEMA';
  rec RECORD;
  view_name text;
  doc_table text;
  feature_uuid_col text;
  feature_id_col text;
  trigger_name text;
  v_count int := 0;
  v_query text;
BEGIN
  -- Create doc views per feature based on cat_feature
  -- Only node and arc features have featurecat_id in doc_x_node/doc_x_arc
  -- Use dynamic SQL to query cat_feature from parent schema
  v_query := format('SELECT id, feature_type FROM %I.cat_feature WHERE feature_type IN (''NODE'', ''ARC'')', parent_s);
  
  FOR rec IN EXECUTE v_query
  LOOP
    v_count := v_count + 1;
    view_name := format('v_ui_doc_x_%s', lower(rec.id));
    feature_uuid_col := format('%s_uuid', lower(rec.feature_type));
    feature_id_col := format('%s_id', lower(rec.feature_type));
    
    -- Create view filtering by featurecat_id
    IF rec.feature_type = 'NODE' THEN
      EXECUTE format(
        'CREATE OR REPLACE VIEW cm.%I AS
         SELECT dxn.doc_id,
                dxn.%I,
                d.name,
                d.doc_type,
                d.path,
                d.observ,
                d.date,
                d.user_name,
                dxn.%I,
                dxn.featurecat_id
         FROM cm.doc_x_node dxn
         JOIN cm.doc d ON d.id::text = dxn.doc_id::text
         WHERE dxn.featurecat_id = %L',
        view_name, feature_id_col, feature_uuid_col, rec.id
      );
    ELSIF rec.feature_type = 'ARC' THEN
      EXECUTE format(
        'CREATE OR REPLACE VIEW cm.%I AS
         SELECT dxa.doc_id,
                dxa.%I,
                d.name,
                d.doc_type,
                d.path,
                d.observ,
                d.date,
                d.user_name,
                dxa.%I,
                dxa.featurecat_id
         FROM cm.doc_x_arc dxa
         JOIN cm.doc d ON d.id::text = dxa.doc_id::text
         WHERE dxa.featurecat_id = %L',
        view_name, feature_id_col, feature_uuid_col, rec.id
      );
    END IF;
    
    -- Grant permissions
    EXECUTE format('GRANT ALL ON TABLE cm.%I TO role_cm_manager', view_name);
    EXECUTE format('GRANT ALL ON TABLE cm.%I TO role_cm_field', view_name);
    
    -- Create trigger (passes feature_type and featurecat_id as TG_ARGV[0] and TG_ARGV[1])
    trigger_name := format('gw_trg_ui_doc_x_%s', lower(rec.id));
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON cm.%I', trigger_name, view_name);
    EXECUTE format(
      'CREATE TRIGGER %I
       INSTEAD OF INSERT OR DELETE OR UPDATE
       ON cm.%I
       FOR EACH ROW
       EXECUTE FUNCTION cm.gw_trg_ui_doc(%L, %L)',
      trigger_name, view_name, lower(rec.feature_type), rec.id
    );
  END LOOP;
  
  -- Raise notice if no views were created
  IF v_count = 0 THEN
    RAISE NOTICE 'No doc views created: No features found in %.cat_feature with feature_type IN (''NODE'', ''ARC'')', parent_s;
  ELSE
    RAISE NOTICE 'Created % doc views (v_ui_doc_x_*)', v_count;
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'Error creating doc views in schema %: %', parent_s, SQLERRM;
END
$$;


INSERT INTO config_param_system (parameter, value, descript, isenabled, project_type, datatype) VALUES
('plugin_campaign', '{"campaignManage":"TRUE"}', 'External plugin to use functionality of planified campaign/lots review/visits', FALSE, 'utils', 'json') ON CONFLICT (parameter) DO NOTHING;

INSERT INTO cm.cat_pschema (name) VALUES ('PARENT_SCHEMA') ON CONFLICT DO NOTHING;

UPDATE PARENT_SCHEMA.config_param_system
   SET value = '{"schemaName":"cm"}'
 WHERE parameter = 'admin_schema_cm';

-- topological trace
INSERT INTO sys_message
(id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES(4576, 'There is no topology from the selected node.', 'The node is isolated or it does not exist in the selected lot_id.', 0, true, 'utils', 'core', 'AUDIT') ON CONFLICT DO NOTHING;

-- setarcdivide_massive Set mode audit messages (fid 2114)
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4578, 'Node %node_id% has been moved to arc %arc_id%.', NULL, 0, true, 'utils', 'core', 'AUDIT') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4580, 'Arc %arc_id% has been divided.', NULL, 0, true, 'utils', 'core', 'AUDIT') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4582, 'Arcs %arc_id1% and %arc_id2% have been created (replacing arc %arc_id%).', NULL, 0, true, 'utils', 'core', 'AUDIT') ON CONFLICT DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type)
VALUES (4584, 'There are %v_count% orphan nodes.', NULL, 0, true, 'utils', 'core', 'AUDIT') ON CONFLICT DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) 
VALUES(3542, 'gw_fct_cm_topological_trace', 'ws', 'function', 'json', 'json', 'Function to visualize the topology of the lot from a SELECTED NODE.

The available lots for the analysis are the ones that take part into de SELECTED CAMPAIGN.', 'role_om', NULL, 'cm', NULL) ON CONFLICT DO NOTHING;

INSERT INTO sys_function
(id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3540, 'gw_fct_cm_build_topology', 'ws', 'function', 'json', 'json', 'Function to build or update the topology of a Lot. 


Only available for those Lots that have state ASSIGNED, IN PROGRESS or EXECUTED.', 'role_om', NULL, 'cm', NULL) ON CONFLICT DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3544, 'gw_fct_cm_check_node_orphan', 'ws', 'function', 'json', 'json', 'Function to show orphan nodes of the selected lot. That is: the nodes that are neither node_1 nor node_2 or any arc.', 'role_om', NULL, 'cm', NULL) ON CONFLICT DO NOTHING;


INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3546, 'gw_fct_cm_check_node_duplicated', 'ws', 'function', 'json', 'json', 'Funcion to show duplicated nodes of the selected lot 3.

The tolerance from which nodes are detected is 10 cm.', 'role_om', NULL, 'cm', NULL) ON CONFLICT DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3548, 'gw_fct_cm_check_arc_duplicated', 'ws', 'function', 'json', 'json', 'Function to show duplicated arcs in the lot.', 'role_om', NULL, 'cm', NULL) ON CONFLICT DO NOTHING;
INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) VALUES(3550, 'gw_fct_cm_check_node_document', 'ws', 'function', 'json', 'json', 'Function to show the nodes that do not have related documents. 

Specific node type can be excluded from the search.', 'role_om', NULL, 'cm', NULL) ON CONFLICT DO NOTHING;

INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(-3, 'There are ', NULL, 0, true, 'utils', 'core', 'UI') ON CONFLICT (id) DO NOTHING;
INSERT INTO sys_message (id, error_message, hint_message, log_level, show_user, project_type, "source", message_type) VALUES(-2, 'There is ', NULL, 0, true, 'utils', 'core', 'UI') ON CONFLICT (id) DO NOTHING;


INSERT INTO sys_function
(id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3552, 'gw_fct_cm_setarcdivide_massive', 'ws', 'function', 'json', 'json', 'Function to set the arc divide of a node. 


Only available for those Lots that have state ASSIGNED, IN PROGRESS or EXECUTED.', 'role_om', NULL, 'cm', 'SETARCDIVIDE_MASSIVE') ON CONFLICT DO NOTHING;

INSERT INTO config_function
(id, function_name, "style", layermanager, actions)
VALUES(3552, 'gw_fct_cm_setarcdivide_massive', '{
  "style": {
    "point": {
      "style": "categorized",
      "field": "descript",
      "transparency": 0.5,
      "width": 2.5,
      "values": [
        {
          "id": "Node T candidate",
          "color": [
            0,
            250,
            255
          ]
        },
        {
          "id": "Orphan node",
          "color": [
            0,
            95,
            253
          ]
        }
      ]
    }
  }
}'::json, NULL, NULL) ON CONFLICT DO NOTHING;

INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3552, '6- [CM] Massive arc divide', '{"featureType":[]}'::json, '[{
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname =  ''OWNER'') AS is_admin FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_admin) WHERE exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  },
  {
    "widgetname": "mode",
    "label": "Mode:",
    "widgettype": "combo",
    "datatype": "text",
    "tooltip": "Choose the mode of the process execution",
    "layoutname": "grl_option_parameters",
    "layoutorder": 3,
    "dvQueryText": "SELECT ''CHECK'' AS id, ''CHECK'' AS idval UNION ALL SELECT ''SET'' AS id, ''SET'' AS idval",
    "selectedId": "1"
  }
]'::json, NULL, true, '{4}') ON CONFLICT DO NOTHING;
INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3550, '0- [CM] Verificar nodos sin documento de un lote', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname =  ''OWNER'') AS is_admin FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_admin) WHERE exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  },
  {
    "widgetname": "excludeNodecatId",
    "widgettype": "text",
    "datatype": "numeric",
    "label": "Excluded node types:",
    "layoutname": "grl_option_parameters",
    "placeholder": "JUNCTION, HYDRANT",
    "isMandatory": false,
    "layoutorder": 5
  }
]'::json, NULL, true, '{4}') ON CONFLICT DO NOTHING;
INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3548, '[CM] Check duplicated arcs of a lot', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname =  ''OWNER'') AS is_admin FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_admin) WHERE exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  }
]'::json, NULL, false, '{4}') ON CONFLICT DO NOTHING;
INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3546, '1- [CM] Check duplicated nodes of a lot', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname =  ''OWNER'') AS is_admin FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_admin) WHERE exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  },
  {
    "widgetname": "searchTolerance",
    "widgettype": "text",
    "datatype": "numeric",
    "label": "Search tolerance (in meters):",
    "layoutname": "grl_option_parameters",
    "isMandatory": true,
    "layoutorder": 5
  }
]'::json, NULL, true, '{4}') ON CONFLICT DO NOTHING;
INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3544, '5- [CM] Check orphan nodes of a lot', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname =  ''OWNER'') AS is_admin FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_admin) WHERE exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  }
]'::json, NULL, true, '{4}') ON CONFLICT DO NOTHING;
INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3542, '4- [CM] Visualize lot topology', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname =  ''OWNER'') AS is_admin FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_admin) WHERE exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  },
  {
    "widgetname": "nodeId",
    "widgettype": "text",
    "datatype": "integer",
    "label": "Node id:",
    "layoutname": "grl_option_parameters",
    "isMandatory": true,
    "layoutorder": 5
  }
]'::json, NULL, true, '{4}') ON CONFLICT DO NOTHING;
INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3540, '3- [CM] Reconnect lot topology', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname =  ''OWNER'') AS is_admin FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_admin) WHERE exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  },
  {
    "widgetname": "updateType",
    "widgettype": "combo",
    "label": "Reconnection type:",
    "comboIds": [
      1,
      2
    ],
    "datatype": "text",
    "comboNames": [
      "Update topology (all arcs)",
      "Build topology (arcs without topology)"
    ],
    "layoutname": "grl_option_parameters",
    "isMandatory": true,
    "layoutorder": 5
  }
]'::json, NULL, true, '{4}') ON CONFLICT DO NOTHING;


INSERT INTO sys_function
(id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3554, 'gw_fct_cm_check_progress', 'ws', 'function', 'json', 'json', 'Función que muestra el porcentaje de progreso de una campaña.
Se muestra en longitud de red.
Para calcular las tuberías hechas se toman aquellas que hayan sido insertadas, modificadas o elimnadas de la campaña.
Para calcular las tuberías iniciales se toman aquellas que existían en el momento de generar la campaña.', 'role_admin', NULL, 'cm', 'PROGRESO DE CAMPAÑA');

INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3554, '[CM] Progreso de campañas', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Id Campaña:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Escoja la campaña",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname = ''Org AyA'') AS is_aya FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_aya) where exists (select 1 from cm.om_campaign_lot l where status in (3,4,6,7,8,9) and l.campaign_id = c.campaign_id)"
  }
]'::json, NULL, true, '{4}');

INSERT INTO sys_function
(id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3564, 'gw_fct_cm_hydraulic_trace', 'ws', 'function', 'json', 'json', 'Function to visualize the hydraulic topology of the SELECTED LOT based on a selected node_id.

The available lots for the analysis are the ones that take part into de SELECTED CAMPAIGN.', 'role_om', NULL, 'cm', 'VISUALIZE HYDRAULIC TOPOLOGY');

INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3564, '4.2- [CM] Visualize hydraulic topology of a lot', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname = ''Org AyA'') AS is_aya FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_aya) where exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "isNullValue": true,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  },
  {
    "widgetname": "nodeId",
    "widgettype": "text",
    "datatype": "integer",
    "label": "Node Id:",
    "layoutname": "grl_option_parameters",
    "isMandatory": true,
    "layoutorder": 5
  }
]'::json, NULL, true, '{4}');

-- 30/03/2026

INSERT INTO sys_function
(id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES(3562, 'gw_fct_cm_verify_catalogs', 'ws', 'function', NULL, NULL, 'Function to check values outside of catalog.', 'role_om', NULL, 'cm', 'CHECK_CATALOG') ON CONFLICT DO NOTHING;

INSERT INTO config_toolbox
(id, alias, functionparams, inputparams, observ, active, device)
VALUES(3562, 'Check catalogs values', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Campaign Id:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Choose a campaign",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname = ''Org AyA'') AS is_aya FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_aya) where exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Lot Id:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Choose a lot",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = ''{parent_value}''"
  }
]'::json, NULL, true, '{4}') ON CONFLICT DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) 
VALUES(3556, 'gw_fct_cm_check_data_context', 'ws', 'function', 'json', 'json', 'Función para verificar el contexto del dato
Se analizan los siguientes parámetros:
- Comparación entre la cota del objeto y el valor en el MDE
- Objetos con estado operacional o de conservación pero sin foto
- Nodos muy próximos
- Cambios de diámetro sin razón aparente
- Diámetros en válvulas sin relación con sus tramos

En caso de no marcar ''Rellenar tablas de revisión'', solamente devolverá un Log y tablas temporales para ver los resultados.
En caso de marcar ''Rellenar tablas de revisión'', se llenan las tablas de control de calidad, dónde se establece un índice según los problemas de cada objeto.
Sobre todos los objetos de la campaña, se marcan como candidatos a sospechoso un % variable a escojer, siempre ordenando de peor a mejor índice.', 'role_admin', NULL, 'cm', 'REPORTE DE CALIDAD DEL DATO')
ON CONFLICT DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) 
VALUES(3558, 'gw_fct_cm_update_geom', 'ws', 'function', 'json', 'json', 'Función para actualizar la geometría de lotes y campañas', 'role_om', NULL, 'cm', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias) 
VALUES(3560, 'gw_fct_create_dscenario_losses', 'ws', 'function', 'json', 'json', 'Function to create losses dscenario', 'role_epa', NULL, 'core', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO config_toolbox (id, alias, functionparams, inputparams, observ, active, device) 
VALUES(3558, '0- [CM] Actualizar geometría de lotes y campañas', '{"featureType":[]}'::json, '[
  {
    "widgetname": "campaignId",
    "label": "Id Campaña:",
    "widgettype": "combo",
    "isparent": "true",
    "datatype": "text",
    "tooltip": "Escoja la campaña",
    "layoutname": "grl_option_parameters",
    "layoutorder": 1,
    "dvQueryText": "SELECT c.campaign_id as id, name as idval FROM cm.om_campaign c JOIN (SELECT t.organization_id, bool_or(o.orgname = ''Org AyA'') AS is_aya FROM cm.cat_user u JOIN cm.cat_team t ON t.team_id = u.team_id JOIN cm.cat_organization o ON o.organization_id = t.organization_id WHERE u.username = current_user GROUP BY t.organization_id) ctx ON (c.organization_id = ctx.organization_id OR ctx.is_aya) where exists (select 1 from cm.om_campaign_lot l where status in (3,4,6) and l.campaign_id = c.campaign_id)"
  },
  {
    "widgetname": "lotId",
    "label": "Id Lote:",
    "widgettype": "combo",
    "parentname": "campaignId",
    "datatype": "text",
    "tooltip": "Escoja el lote",
    "layoutname": "grl_option_parameters",
    "layoutorder": 2,
    "isNullValue": true,
    "dvQueryText": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6)",
    "filterquery": "select null as id, '''' as idval union all select lot_id as id, concat(a.name, '' - '', b.idval, '''') AS idval FROM cm.om_campaign_lot a JOIN cm.sys_typevalue b ON a.status = b.id::int WHERE b.typevalue = ''lot_status'' and status in (3,4,6) and a.campaign_id = {parent_value}"
  },
  {
    "label": "Búfer [m]:",
    "value": null,
    "datatype": "float",
    "layoutname": "grl_option_parameters",
    "selectedId": null,
    "widgetname": "buffer",
    "widgettype": "text",
    "isMandatory": true,
    "layoutorder": 3
  }
]'::json, NULL, true, '{4}')
ON CONFLICT DO NOTHING;


DROP TRIGGER IF EXISTS trg_validate_campaign_x_arc_feature ON cm.om_campaign_x_arc;
CREATE TRIGGER trg_validate_campaign_x_arc_feature BEFORE INSERT ON cm.om_campaign_x_arc
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('arc');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_node_feature ON cm.om_campaign_x_node;
CREATE TRIGGER trg_validate_campaign_x_node_feature BEFORE INSERT ON cm.om_campaign_x_node
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('node');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_connec_feature ON cm.om_campaign_x_connec;
CREATE TRIGGER trg_validate_campaign_x_connec_feature BEFORE INSERT ON cm.om_campaign_x_connec
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('connec');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_link_feature ON cm.om_campaign_x_link;
CREATE TRIGGER trg_validate_campaign_x_link_feature BEFORE INSERT ON cm.om_campaign_x_link
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('link');


DROP TRIGGER IF EXISTS trg_validate_campaign_x_arc_feature_delete ON cm.om_campaign_x_arc;
CREATE TRIGGER trg_validate_campaign_x_arc_feature_delete AFTER DELETE ON cm.om_campaign_x_arc
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('arc');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_node_feature_delete ON cm.om_campaign_x_node;
CREATE TRIGGER trg_validate_campaign_x_node_feature_delete AFTER DELETE ON cm.om_campaign_x_node
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('node');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_connec_feature_delete ON cm.om_campaign_x_connec;
CREATE TRIGGER trg_validate_campaign_x_connec_feature_delete AFTER DELETE ON cm.om_campaign_x_connec
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('connec');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_link_feature_delete ON cm.om_campaign_x_link;
CREATE TRIGGER trg_validate_campaign_x_link_feature_delete AFTER DELETE ON cm.om_campaign_x_link
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('link');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_arc_feature_after ON cm.om_campaign_x_arc;
CREATE TRIGGER trg_validate_campaign_x_arc_feature_after AFTER INSERT ON cm.om_campaign_x_arc
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('arc');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_node_feature_after ON cm.om_campaign_x_node;
CREATE TRIGGER trg_validate_campaign_x_node_feature_after AFTER INSERT ON cm.om_campaign_x_node
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('node');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_connec_feature_after ON cm.om_campaign_x_connec;
CREATE TRIGGER trg_validate_campaign_x_connec_feature_after AFTER INSERT ON cm.om_campaign_x_connec
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('connec');

DROP TRIGGER IF EXISTS trg_validate_campaign_x_link_feature_after ON cm.om_campaign_x_link;
CREATE TRIGGER trg_validate_campaign_x_link_feature_after AFTER INSERT ON cm.om_campaign_x_link
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type('link');

-- Doc view triggers are now created dynamically per-feature in parent_schema/utils/ddlview.sql

DROP TRIGGER IF EXISTS doc_path_prefix ON cm.doc;
CREATE TRIGGER doc_path_prefix
AFTER INSERT ON cm.doc
FOR EACH ROW
EXECUTE FUNCTION doc_path_prefix();

DROP TRIGGER IF EXISTS trg_edit_view_campaign_node ON ve_PARENT_SCHEMA_camp_node;
CREATE TRIGGER trg_edit_view_campaign_node INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_camp_node
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign('node');

DROP TRIGGER IF EXISTS trg_edit_view_campaign_arc ON ve_PARENT_SCHEMA_camp_arc;
CREATE TRIGGER trg_edit_view_campaign_arc INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_camp_arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign('arc');

DROP TRIGGER IF EXISTS trg_edit_view_campaign_connec ON ve_PARENT_SCHEMA_camp_connec;
CREATE TRIGGER trg_edit_view_campaign_connec INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_camp_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign('connec');

DROP TRIGGER IF EXISTS trg_edit_view_campaign_link ON ve_PARENT_SCHEMA_camp_link;
CREATE TRIGGER trg_edit_view_campaign_link INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_camp_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign('link');

DROP TRIGGER IF EXISTS trg_edit_view_lot_node ON ve_PARENT_SCHEMA_lot_node;
CREATE TRIGGER trg_edit_view_lot_node INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_lot_node
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign_lot('node');

DROP TRIGGER IF EXISTS trg_edit_view_lot_arc ON ve_PARENT_SCHEMA_lot_arc;
CREATE TRIGGER trg_edit_view_lot_arc INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_lot_arc
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign_lot('arc');

DROP TRIGGER IF EXISTS trg_edit_view_lot_connec ON ve_PARENT_SCHEMA_lot_connec;
CREATE TRIGGER trg_edit_view_lot_connec INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_lot_connec
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign_lot('connec');

DROP TRIGGER IF EXISTS trg_edit_view_lot_link ON ve_PARENT_SCHEMA_lot_link;
CREATE TRIGGER trg_edit_view_lot_link INSTEAD OF INSERT OR UPDATE ON ve_PARENT_SCHEMA_lot_link
FOR EACH ROW EXECUTE FUNCTION gw_trg_cm_edit_view_campaign_lot('link');

DROP TRIGGER IF EXISTS trg_lot_x_node_feature ON cm.om_campaign_lot_x_node;
DROP TRIGGER IF EXISTS trg_lot_x_node_feature_before ON cm.om_campaign_lot_x_node;
DROP TRIGGER IF EXISTS trg_lot_x_node_feature_after ON cm.om_campaign_lot_x_node;

CREATE TRIGGER trg_lot_x_node_feature_before BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_node
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('node');

CREATE TRIGGER trg_lot_x_node_feature_after AFTER INSERT OR DELETE ON cm.om_campaign_lot_x_node
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('node');

DROP TRIGGER IF EXISTS trg_lot_x_arc_feature ON cm.om_campaign_lot_x_arc;
DROP TRIGGER IF EXISTS trg_lot_x_arc_feature_before ON cm.om_campaign_lot_x_arc;
DROP TRIGGER IF EXISTS trg_lot_x_arc_feature_after ON cm.om_campaign_lot_x_arc;

CREATE TRIGGER trg_lot_x_arc_feature_before BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_arc
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('arc');

CREATE TRIGGER trg_lot_x_arc_feature_after AFTER INSERT OR DELETE ON cm.om_campaign_lot_x_arc
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('arc');

DROP TRIGGER IF EXISTS trg_lot_x_connec_feature ON cm.om_campaign_lot_x_connec;
DROP TRIGGER IF EXISTS trg_lot_x_connec_feature_before ON cm.om_campaign_lot_x_connec;
DROP TRIGGER IF EXISTS trg_lot_x_connec_feature_after ON cm.om_campaign_lot_x_connec;

CREATE TRIGGER trg_lot_x_connec_feature_before BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_connec
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('connec');

CREATE TRIGGER trg_lot_x_connec_feature_after AFTER INSERT OR DELETE ON cm.om_campaign_lot_x_connec
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('connec');

DROP TRIGGER IF EXISTS trg_lot_x_link_feature ON cm.om_campaign_lot_x_link;
DROP TRIGGER IF EXISTS trg_lot_x_link_feature_before ON cm.om_campaign_lot_x_link;
DROP TRIGGER IF EXISTS trg_lot_x_link_feature_after ON cm.om_campaign_lot_x_link;

CREATE TRIGGER trg_lot_x_link_feature_before BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_link
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('link');

CREATE TRIGGER trg_lot_x_link_feature_after AFTER INSERT OR DELETE ON cm.om_campaign_lot_x_link
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('link');

DROP TRIGGER IF EXISTS trg_validate_lot_x_arc_feature ON cm.om_campaign_lot_x_arc;
CREATE TRIGGER trg_validate_lot_x_arc_feature BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_arc
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature_check_campaign('arc');

DROP TRIGGER IF EXISTS trg_validate_lot_x_node_feature ON cm.om_campaign_lot_x_node;
CREATE TRIGGER trg_validate_lot_x_node_feature BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_node
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature_check_campaign('node');

DROP TRIGGER IF EXISTS trg_validate_lot_x_connec_feature ON cm.om_campaign_lot_x_connec;
CREATE TRIGGER trg_validate_lot_x_connec_feature BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_connec
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature_check_campaign('connec');

DROP TRIGGER IF EXISTS trg_validate_lot_x_link_feature ON cm.om_campaign_lot_x_link;
CREATE TRIGGER trg_validate_lot_x_link_feature BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_link
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature_check_campaign('link');

-- Topocontrol triggers
DROP TRIGGER IF EXISTS trg_cm_topocontrol_arc ON cm.om_campaign_x_arc;
CREATE TRIGGER trg_cm_topocontrol_arc BEFORE INSERT OR UPDATE OF the_geom ON cm.om_campaign_x_arc
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_topocontrol_arc();

DROP TRIGGER IF EXISTS trg_cm_topocontrol_node ON cm.om_campaign_x_node;
CREATE TRIGGER trg_cm_topocontrol_node BEFORE INSERT OR UPDATE OF the_geom ON cm.om_campaign_x_node
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_topocontrol_node();

DO $$
DECLARE
    v_rec record;
    v_view_name text;
    v_trigger_name text;
    v_feature_id text;
    v_feature_type text;
BEGIN
    FOR v_rec IN
        SELECT id, feature_type FROM PARENT_SCHEMA.cat_feature WHERE feature_type NOT IN ('ELEMENT', 'GULLY')
    LOOP
        v_feature_id := lower(v_rec.id);
        v_feature_type := lower(v_rec.feature_type);
        -- Construct the view name exactly as in ddl.sql
        v_view_name := 've_' || 'PARENT_SCHEMA' || '_lot_' || v_feature_id;
        v_trigger_name := 'trg_PARENT_SCHEMA_edit_lot_' || v_feature_id;

        EXECUTE
        'CREATE OR REPLACE TRIGGER ' || v_trigger_name || ' INSTEAD OF
        INSERT OR DELETE OR UPDATE
        ON cm.' || v_view_name ||' FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_edit_feature(' || quote_literal(v_feature_type) || ')';

        EXECUTE
        'CREATE OR REPLACE TRIGGER ' || v_trigger_name || '_geom INSTEAD OF
        INSERT OR UPDATE
        ON cm.' || v_view_name ||' FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_feature_geom(' || quote_literal(v_feature_type) || ')';
    END LOOP;
END
$$;

-- Create triggers for log in the tables
DO $$
DECLARE
    rec record;
    trigger_name text;
    feature_type text;
    mission_type text;
    mission_id_column text;
    has_lot_id boolean;
    has_campaign_id boolean;
BEGIN
    -- Triggers for parent schema tables (e.g., junio06_ws_adaptation)
    FOR rec IN
        SELECT
            t.table_name,
            cf.feature_type
        FROM
            information_schema.tables t
        JOIN
            PARENT_SCHEMA.cat_feature cf ON t.table_name = 'PARENT_SCHEMA' || '_' || lower(cf.id)
        WHERE
            t.table_schema = 'cm'
    LOOP
        -- Check for lot_id column
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'cm' AND table_name = rec.table_name AND column_name = 'lot_id'
        ) INTO has_lot_id;

        -- Check for campaign_id column
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'cm' AND table_name = rec.table_name AND column_name = 'campaign_id'
        ) INTO has_campaign_id;

        feature_type := lower(rec.feature_type);
        trigger_name := 'trg_log_' || rec.table_name;
        mission_type := NULL;
        mission_id_column := NULL;

        IF has_lot_id THEN
            mission_type := 'lot';
            mission_id_column := 'lot_id';
        ELSIF has_campaign_id THEN
            mission_type := 'campaign';
            mission_id_column := 'campaign_id';
        END IF;

        IF mission_type IS NOT NULL THEN
            EXECUTE format(
                'CREATE OR REPLACE TRIGGER %I ' ||
                'AFTER INSERT OR UPDATE OR DELETE ON cm.%I ' ||
                'FOR EACH ROW EXECUTE PROCEDURE audit.gw_trg_cm_log(%L, %L, %L)',
                trigger_name, rec.table_name, feature_type, mission_type, mission_id_column
            );
        END IF;
    END LOOP;

    -- Triggers for om_campaign_x_ tables
    FOR rec IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'cm' AND table_name LIKE 'om_campaign_x_%'
    LOOP
        feature_type := split_part(rec.table_name, '_x_', 2);
        trigger_name := 'trg_log_' || rec.table_name;
        mission_type := 'campaign';
        mission_id_column := 'campaign_id';

        EXECUTE format(
            'CREATE OR REPLACE TRIGGER %I ' ||
            'AFTER INSERT OR UPDATE OR DELETE ON cm.%I ' ||
            'FOR EACH ROW EXECUTE PROCEDURE audit.gw_trg_cm_log(%L, %L, %L)',
            trigger_name, rec.table_name, feature_type, mission_type, mission_id_column
        );
    END LOOP;

    -- Triggers for om_campaign_lot_x_ tables
    FOR rec IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'cm' AND table_name LIKE 'om_campaign_lot_x_%'
    LOOP
        feature_type := split_part(rec.table_name, '_x_', 2);
        trigger_name := 'trg_log_' || rec.table_name;
        mission_type := 'lot';
        mission_id_column := 'lot_id';

        EXECUTE format(
            'CREATE OR REPLACE TRIGGER %I ' ||
            'AFTER INSERT OR UPDATE OR DELETE ON cm.%I ' ||
            'FOR EACH ROW EXECUTE PROCEDURE audit.gw_trg_cm_log(%L, %L, %L)',
            trigger_name, rec.table_name, feature_type, mission_type, mission_id_column
        );
    END LOOP;

    -- Trigger for om_campaign
    EXECUTE format(
        'CREATE OR REPLACE TRIGGER trg_log_om_campaign ' ||
        'AFTER INSERT OR UPDATE OR DELETE ON cm.om_campaign ' ||
        'FOR EACH ROW EXECUTE PROCEDURE audit.gw_trg_cm_log(%L, %L, %L)',
        'campaign', 'campaign', 'campaign_id'
    );

    -- Trigger for om_campaign_lot
    EXECUTE format(
        'CREATE OR REPLACE TRIGGER trg_log_om_campaign_lot ' ||
        'AFTER INSERT OR UPDATE OR DELETE ON cm.om_campaign_lot ' ||
        'FOR EACH ROW EXECUTE PROCEDURE audit.gw_trg_cm_log(%L, %L, %L)',
        'lot', 'lot', 'lot_id'
    );
END
$$;

GRANT SELECT ON ALL TABLES IN SCHEMA cm TO role_basic;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA cm TO role_basic;

SELECT cm.gw_fct_admin_sys_version_register(json_build_object(
	'data', json_build_object(
		'parentSchema', 'PARENT_SCHEMA'
	)
)::json);
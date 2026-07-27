/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3426

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_integrate_production(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT cm.gw_fct_cm_integrate_production($${"data":{"parameters":{"campaignId":9}}}$$)
*/

DECLARE

v_campaign integer;
v_result json;
v_result_info json;
v_result_point json;
v_version text;
v_project_type text;
v_catfeature record;
v_cmschema text;
v_parentschema text;
v_querytext text;
v_querytext_review text;
v_column_list text;
v_column_list_values text;
v_update_list text;
v_ins integer := 0;
v_upd integer := 0;
v_del integer := 0;
v_tot_ins integer := 0;
v_tot_upd integer := 0;
v_tot_del integer := 0;
v_cat_result json;
v_cat_log text;
v_catalogs_created integer := 0;
v_prev_search_path text;
v_disable_params text[] := ARRAY[
	'edit_disable_typevalue_fk',
	'edit_disable_arctopocontrol',
	'edit_disable_planpsector_arc',
	'edit_disable_arc_fkarray',
	'edit_disable_editcontrols',
	'edit_disable_noderotation',
	'edit_disable_noderotation_complete',
	'edit_disable_topocontrol',
	'edit_disable_topocontrol_complete',
	'edit_disable_statetopocontrol',
	'edit_disable_planpsector_node',
	'edit_disable_arc_divide',
	'edit_disable_planpsector_connec'
];
v_restore_param record;
v_workcat_id text;
v_arc_childs text[];
v_node_childs text[];
v_data json;
v_arc_nodes_set text;
v_arc_nodes_check text;
v_old_variable_update_nodes text;
v_error_context text;

BEGIN

	-- Save current search_path and switch to parent schema (transaction-local)
	v_prev_search_path := current_setting('search_path');
	PERFORM set_config('search_path', 'PARENT_SCHEMA,public', true);
	v_cmschema = 'cm';
	v_parentschema = 'PARENT_SCHEMA';

	-- SELECT giswater and project type
	SELECT giswater, project_type INTO v_version, v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	SELECT "value" INTO v_old_variable_update_nodes FROM config_param_system WHERE "parameter"='edit_arc_enable nodes_update';
	UPDATE config_param_system SET "value" = 'TRUE' WHERE "parameter"='edit_arc_enable nodes_update';
	
-- getting input data
	v_campaign :=  (((p_data ->>'data')::json->>'parameters')::json->>'campaignId')::integer;

	v_data :=
	jsonb_build_object(
		'data',
		jsonb_build_object(
			'parameters',
			jsonb_build_object(
				'campaignId', v_campaign::text,
				'lotId', null
			)
		)
	);
	SELECT cm.gw_fct_cm_verify_catalogs(v_data) INTO v_cat_result;

	IF v_cat_result->>'status' = 'Accepted' THEN
		IF (v_cat_result->'body'->'data'->'info'->'values' IS NOT NULL AND (v_cat_result->'body'->'data'->'info'->'values')::jsonb != '{}'::jsonb) THEN
			RETURN v_cat_result;
		END IF;
	ELSE
		RETURN v_cat_result;
	END IF;

	-- Temporarily disable selected edit triggers for performance (mandatory user params only)
	CREATE TEMP TABLE tmp_cm_integrate_trigger_params (
		parameter text PRIMARY KEY,
		prev_value text,
		existed boolean
	) ON COMMIT DROP;

	INSERT INTO tmp_cm_integrate_trigger_params (parameter, prev_value, existed)
	SELECT p.parameter, cpu.value, (cpu.parameter IS NOT NULL)
	FROM (SELECT DISTINCT unnest(v_disable_params) AS parameter) p
	JOIN sys_param_user spu ON spu.id = p.parameter
	LEFT JOIN config_param_user cpu ON cpu.parameter = p.parameter AND cpu.cur_user = current_user;

	INSERT INTO config_param_user (parameter, value, cur_user)
	SELECT parameter, 'true', current_user
	FROM tmp_cm_integrate_trigger_params
	ON CONFLICT (parameter, cur_user) DO UPDATE
	SET value = 'true';

	-- Save and disable edit_arc_division_dsbl (restored with other params at end)
	INSERT INTO tmp_cm_integrate_trigger_params (parameter, prev_value, existed)
	SELECT 'edit_arc_division_dsbl', cpu.value, (cpu.parameter IS NOT NULL)
	FROM (SELECT 'edit_arc_division_dsbl'::text AS parameter) p
	LEFT JOIN config_param_user cpu ON cpu.parameter = p.parameter AND cpu.cur_user = current_user
	ON CONFLICT (parameter) DO NOTHING;

	INSERT INTO config_param_user (parameter, value, cur_user)
	VALUES ('edit_arc_division_dsbl', 'TRUE', current_user)
	ON CONFLICT (parameter, cur_user) DO UPDATE SET value = 'TRUE';

	--Create workcat
	SELECT name INTO v_workcat_id FROM cm.om_campaign WHERE campaign_id = v_campaign;
	INSERT INTO PARENT_SCHEMA.cat_work (id, descript, active)
	VALUES (v_workcat_id, concat('Generado al integrar la campaña ', v_workcat_id), true) ON CONFLICT (id) DO NOTHING;

	SELECT array_agg(lower(concat('PARENT_SCHEMA_', lower(id)))) INTO v_arc_childs
	FROM PARENT_SCHEMA.cat_feature
	WHERE lower(feature_type) = 'arc';

	SELECT array_agg(lower(concat('PARENT_SCHEMA_', lower(id)))) INTO v_node_childs
	FROM PARENT_SCHEMA.cat_feature
	WHERE lower(feature_type) = 'node';

	FOR v_catfeature IN SELECT unnest(ARRAY['arc', 'node', 'connec', 'link', 'gully']) AS id
	LOOP
		EXECUTE format('UPDATE cm.om_campaign_lot_x_%s SET integrated_id = %s_id WHERE %s_id > 0 AND lot_id IN (SELECT lot_id FROM cm.om_campaign_lot WHERE campaign_id = %s)',
		v_catfeature.id, v_catfeature.id, v_catfeature.id, v_campaign);
	END LOOP;

	v_querytext_review :=
		format('SELECT * FROM (SELECT object_id, feature_type, 
		child_layer as target_layer, 
		lower(concat('''||v_parentschema||'_'',object_id)) as source_layer,
		lower(concat(''om_campaign_lot_x_'',feature_type)) as campaign_layer,
		lower(concat(feature_type,''_id'')) as column_id,
		CASE
			WHEN lower(concat('''||v_parentschema||'_'',object_id)) IN (''%s'') THEN 0
			ELSE 1
		END AS orderby
		from '||v_cmschema||'.om_reviewclass_x_object 
		join '||v_parentschema||'.cat_feature on id = object_id 
		join '||v_cmschema||'.om_campaign_review using (reviewclass_id)
		join '||v_cmschema||'.om_campaign using (campaign_id) 
		WHERE campaign_id = '||v_campaign||') sub ORDER BY sub.orderby', array_to_string(v_arc_childs, ','));


	EXECUTE
		'UPDATE connec SET arc_id = NULL ' ||
		'WHERE arc_id IN (' ||
			'SELECT DISTINCT COALESCE(' ||
				'(SELECT a.arc_id FROM arc a WHERE a.arc_id = s.arc_id LIMIT 1), ' ||
				'(SELECT a.arc_id FROM arc a WHERE a.code = s.arc_id::text LIMIT 1)' ||
			') ' ||
			'FROM ' || v_cmschema || '.om_campaign_lot_x_arc s ' ||
			'WHERE s.action = 3 ' ||
			'AND s.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ') ' ||
			'AND COALESCE(' ||
				'(SELECT a.arc_id FROM arc a WHERE a.arc_id = s.arc_id LIMIT 1), ' ||
				'(SELECT a.arc_id FROM arc a WHERE a.code = s.arc_id::text LIMIT 1)' ||
			') IS NOT NULL' ||
		')';

	-- DELETE ARCS
	FOR v_catfeature IN execute v_querytext_review
	LOOP

		IF lower(v_catfeature.source_layer) <> ANY(v_arc_childs) THEN
			CONTINUE;
		END IF;

		v_querytext :=
		'UPDATE ' || v_catfeature.target_layer ||
		' SET state = 0 WHERE ' || v_catfeature.column_id || ' IN (' ||
			'SELECT DISTINCT ' || v_catfeature.column_id ||
			' FROM ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' s ' ||
			' WHERE s.action = 3 AND s.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ')' ||
		');';

		EXECUTE v_querytext;
		GET DIAGNOSTICS v_del = ROW_COUNT;
		v_tot_del := v_tot_del + v_del;

	END LOOP;


	-- INSERT NODES
	FOR v_catfeature IN execute concat(v_querytext_review, ' desc')
	LOOP
		IF lower(v_catfeature.source_layer) = ANY(v_arc_childs) THEN
			CONTINUE;
		END IF;

		-- insert (action = 1);
		-- get columns excluding those are not used
		SELECT string_agg(quote_ident(column_name), ', ')
		INTO v_column_list_values
		FROM information_schema.columns
		WHERE table_name = v_catfeature.source_layer
		AND table_schema = v_cmschema
		AND column_name not IN ('id','lot_id', 'node_1', 'node_2', 'code', 'workcat_id', 'photo_path', 'node_type', 'nodecat_id') and column_name not ilike 'foto_%';

		SELECT string_agg('s.' || quote_ident(column_name), ', ')
		INTO v_column_list
		FROM information_schema.columns
		WHERE table_name = v_catfeature.source_layer
		AND table_schema = v_cmschema
		AND column_name not IN ('id','lot_id', 'node_1', 'node_2', 'code', 'workcat_id', 'photo_path', 'node_type', 'nodecat_id') and column_name not ilike 'foto_%';

		IF v_column_list IS NULL OR v_column_list_values IS NULL THEN
			CONTINUE;
		END IF;

		IF NOT EXISTS(SELECT 1 FROM PARENT_SCHEMA.cat_feature WHERE UPPER(id) = UPPER(v_catfeature.object_id)) THEN
			INSERT INTO PARENT_SCHEMA.cat_node (id, node_type, descript, cost_unit, active, ischange)
			VALUES (UPPER(v_catfeature.object_id), UPPER(v_catfeature.object_id), 'MATERIAL Y DIAMETRO DESCONOCIDO', 'u', TRUE, 2);
		END IF;

	-- insert into production
		v_querytext :=
		'INSERT INTO ' || v_catfeature.target_layer || ' ' ||
			' ( '|| v_column_list_values || ', workcat_id, node_type, nodecat_id) ' ||
		'SELECT ' || v_column_list || ', '||quote_literal(v_workcat_id)||', '|| quote_literal(upper(v_catfeature.object_id)) ||', CASE WHEN EXISTS(SELECT 1 FROM PARENT_SCHEMA.cat_node WHERE node_type = '|| quote_literal(UPPER(v_catfeature.object_id)) ||' and id = s.nodecat_id) THEN s.nodecat_id ELSE '|| quote_literal(upper(v_catfeature.object_id)) ||' END FROM (' ||
			'SELECT DISTINCT ON (s.' || v_catfeature.column_id || ') s.* ' ||
			'FROM ' || v_cmschema ||'.'|| v_catfeature.source_layer || ' s ' ||
			'JOIN ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' l ' ||
				'ON l.lot_id = s.lot_id AND l.' || v_catfeature.column_id || ' = s.' || v_catfeature.column_id || ' ' ||
			'WHERE l.action = 1 AND l.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ') ' ||
			'ORDER BY s.' || v_catfeature.column_id || ', s.lot_id' ||
		') s;';

		EXECUTE v_querytext;
		GET DIAGNOSTICS v_ins = ROW_COUNT;
		v_tot_ins := v_tot_ins + v_ins;

		-- back-fill integrated_id via uuid (copied on insert)
		v_querytext :=
		'UPDATE ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' ocl ' ||
		'SET integrated_id = t.' || v_catfeature.column_id || ' ' ||
		'FROM ' || v_cmschema || '.' || v_catfeature.source_layer || ' s ' ||
		'JOIN ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' l ' ||
			'ON l.lot_id = s.lot_id AND l.' || v_catfeature.column_id || ' = s.' || v_catfeature.column_id || ' ' ||
		'JOIN ' || v_catfeature.target_layer || ' t ON t.uuid = s.uuid AND t.workcat_id = ' || quote_literal(v_workcat_id) || ' ' ||
		'WHERE ocl.id = l.id ' ||
		'AND l.action = 1 ' ||
		'AND l.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ');';

		EXECUTE v_querytext;

	END LOOP;



	-- UPDATES
	FOR v_catfeature IN execute concat(v_querytext_review, ' desc')
	LOOP

		-- update (action = 2)
		-- get columns excluding those are not used
		SELECT string_agg(format('%I = s.%I', column_name, column_name), ', ')
		INTO v_update_list
		FROM information_schema.columns
		WHERE table_name = v_catfeature.source_layer
		AND table_schema = v_cmschema
		AND column_name not IN ('id','lot_id','code', 'workcat_id', 'node_1', 'node_2', 'photo_path') and column_name not ilike 'foto_%'
		AND column_name <> v_catfeature.column_id;

		v_arc_nodes_set := '';
		IF lower(v_catfeature.source_layer) = ANY(v_arc_childs) THEN
			v_arc_nodes_set :=
				', node_1 = CASE WHEN s.node_1 > 0 THEN s.node_1 ' ||
					'ELSE (SELECT ln.integrated_id FROM ' || v_cmschema || '.om_campaign_lot_x_node ln ' ||
					'WHERE ln.node_id = s.node_1 AND ln.integrated_id IS NOT NULL ' ||
					'AND ln.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ') LIMIT 1) END' ||
				', node_2 = CASE WHEN s.node_2 > 0 THEN s.node_2 ' ||
					'ELSE (SELECT ln.integrated_id FROM ' || v_cmschema || '.om_campaign_lot_x_node ln ' ||
					'WHERE ln.node_id = s.node_2 AND ln.integrated_id IS NOT NULL ' ||
					'AND ln.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ') LIMIT 1) END';
		END IF;

		IF v_update_list IS NULL AND v_arc_nodes_set = '' THEN
			CONTINUE;
		END IF;

		v_querytext :=
			'UPDATE ' || v_catfeature.target_layer || ' t SET ' ||
			COALESCE(v_update_list, '') || v_arc_nodes_set ||
			CASE WHEN v_update_list IS NOT NULL OR v_arc_nodes_set <> '' THEN ', ' ELSE '' END ||
			'workcat_id = '||quote_literal(v_workcat_id)||
			' FROM (' ||
			'SELECT DISTINCT ON (s.' || v_catfeature.column_id || ') s.* ' ||
			'FROM ' || v_cmschema ||'.'|| v_catfeature.source_layer || ' s ' ||
			'JOIN ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' l ' ||
			'ON l.lot_id = s.lot_id AND l.' || v_catfeature.column_id || ' = s.' || v_catfeature.column_id || ' ' ||
			'WHERE l.action = 2 AND l.lot_id IN (' ||
			'SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign ||
			') ORDER BY s.' || v_catfeature.column_id || ', s.lot_id' ||
			') s ' ||
			'WHERE t.' || v_catfeature.column_id || ' = s.' || v_catfeature.column_id || ';';

		EXECUTE v_querytext;
		GET DIAGNOSTICS v_upd = ROW_COUNT;
		v_tot_upd := v_tot_upd + v_upd;

	END LOOP;


	-- INSERT ARCS
	FOR v_catfeature IN execute concat(v_querytext_review, ' desc')
	LOOP
		IF lower(v_catfeature.source_layer) <> ALL(v_arc_childs) THEN
			CONTINUE;
		END IF;

		-- insert (action = 1);
		-- get columns excluding those are not used
		SELECT string_agg(quote_ident(column_name), ', ')
		INTO v_column_list_values
		FROM information_schema.columns
		WHERE table_name = v_catfeature.source_layer
		AND table_schema = v_cmschema
		AND column_name not IN ('id','lot_id', 'node_1', 'node_2', 'code', 'workcat_id', 'photo_path') and column_name not ilike 'foto_%';

		SELECT string_agg('s.' || quote_ident(column_name), ', ')
		INTO v_column_list
		FROM information_schema.columns
		WHERE table_name = v_catfeature.source_layer
		AND table_schema = v_cmschema
		AND column_name not IN ('id','lot_id', 'node_1', 'node_2', 'code', 'workcat_id', 'photo_path') and column_name not ilike 'foto_%';

		IF v_column_list IS NULL OR v_column_list_values IS NULL THEN
			CONTINUE;
		END IF;

	-- insert into production
		v_querytext :=
	'INSERT INTO ' || v_catfeature.target_layer || ' ' ||
		' ( '|| v_column_list_values || ', node_1, node_2, workcat_id) ' ||
	'SELECT ' || v_column_list || ', ' ||
		'CASE WHEN s.node_1 > 0 THEN s.node_1 ELSE (SELECT ln.integrated_id FROM ' || v_cmschema || '.om_campaign_lot_x_node ln WHERE ln.node_id = s.node_1 AND ln.integrated_id IS NOT NULL AND ln.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ') LIMIT 1) END, ' ||
		'CASE WHEN s.node_2 > 0 THEN s.node_2 ELSE (SELECT ln.integrated_id FROM ' || v_cmschema || '.om_campaign_lot_x_node ln WHERE ln.node_id = s.node_2 AND ln.integrated_id IS NOT NULL AND ln.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ') LIMIT 1) END, ' ||
		quote_literal(v_workcat_id)||' FROM (' ||
			'SELECT DISTINCT ON (s.' || v_catfeature.column_id || ') s.* ' ||
			'FROM ' || v_cmschema ||'.'|| v_catfeature.source_layer || ' s ' ||
			'JOIN ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' l ' ||
				'ON l.lot_id = s.lot_id AND l.' || v_catfeature.column_id || ' = s.' || v_catfeature.column_id || ' ' ||
			'WHERE l.action = 1 AND l.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ') ' ||
			'ORDER BY s.' || v_catfeature.column_id || ', s.lot_id' ||
		') s;';

		EXECUTE v_querytext;
		GET DIAGNOSTICS v_ins = ROW_COUNT;
		v_tot_ins := v_tot_ins + v_ins;

		-- back-fill integrated_id via uuid (copied on insert)
		v_querytext :=
		'UPDATE ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' ocl ' ||
		'SET integrated_id = t.' || v_catfeature.column_id || ' ' ||
		'FROM ' || v_cmschema || '.' || v_catfeature.source_layer || ' s ' ||
		'JOIN ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' l ' ||
			'ON l.lot_id = s.lot_id AND l.' || v_catfeature.column_id || ' = s.' || v_catfeature.column_id || ' ' ||
		'JOIN ' || v_catfeature.target_layer || ' t ON t.uuid = s.uuid AND t.workcat_id = ' || quote_literal(v_workcat_id) || ' ' ||
		'WHERE ocl.id = l.id ' ||
		'AND l.action = 1 ' ||
		'AND l.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ');';

		EXECUTE v_querytext;

	END LOOP;

	-- DELETE NODES
	FOR v_catfeature IN EXECUTE v_querytext_review
	LOOP
		IF lower(v_catfeature.source_layer) = ANY(v_arc_childs) THEN
			CONTINUE;
		END IF;

		v_querytext :=
		'UPDATE ' || v_catfeature.target_layer ||
		' SET state = 0 WHERE ' || v_catfeature.column_id || ' IN (' ||
			'SELECT DISTINCT ' || v_catfeature.column_id ||
			' FROM ' || v_cmschema || '.' || v_catfeature.campaign_layer || ' s ' ||
			' WHERE s.action = 3 AND s.lot_id IN (SELECT lot_id FROM ' || v_cmschema || '.om_campaign_lot WHERE campaign_id = ' || v_campaign || ')' ||
		');';

		EXECUTE v_querytext;
		GET DIAGNOSTICS v_del = ROW_COUNT;
		v_tot_del := v_tot_del + v_del;
	END LOOP;



	-- INSERT DOCS
	FOR v_catfeature IN execute concat(v_querytext_review, ' desc')
	LOOP
		IF to_regclass(format('%I.%I', v_cmschema, 'doc_x_' || lower(v_catfeature.feature_type::text))) IS NULL
			OR to_regclass(format('%I.%I', v_parentschema, 'doc_x_' || lower(v_catfeature.feature_type::text))) IS NULL THEN
			CONTINUE;
		END IF;

		-- doc rows (cm doc.id serial -> production doc.id varchar)
		v_querytext:= format(
			$q$
				INSERT INTO %I.doc (code, "name", doc_type, "path", observ, "date", user_name, tstamp, the_geom)
				SELECT concat('CM', s.id::text), s.name, COALESCE(s.doc_type, 'CM_DOCUMENT'), s.path, s.observ, s.date, s.user_name, s.tstamp, s.the_geom
				FROM (
					SELECT DISTINCT d.id, d.name, d.doc_type, d.path, d.observ, d.date, d.user_name, d.tstamp, d.the_geom
					FROM cm.%I d
					JOIN cm.%I dx ON dx.doc_id = d.id
					JOIN cm.%I ch ON ch.uuid = dx.%I
					JOIN cm.%I ocl ON ocl.%I = ch.%I AND ocl.lot_id = ch.lot_id
					WHERE (ocl.action IS NULL OR ocl.action <> 3)
					AND ocl.lot_id IN (SELECT lot_id FROM cm.om_campaign_lot WHERE campaign_id = $1)
				) s
			$q$,
			v_parentschema,
			'doc',
			'doc_x_' || lower(v_catfeature.feature_type::text),
			v_catfeature.source_layer,
			concat(lower(v_catfeature.feature_type), '_uuid'),
			v_catfeature.campaign_layer,
			v_catfeature.column_id,
			v_catfeature.column_id
		);
		EXECUTE v_querytext USING v_campaign;

		-- INSERT doc relations
		v_querytext:= format(
			$q$
				INSERT INTO %I.%I (doc_id, %I)
				SELECT DISTINCT
					(SELECT id FROM %I.doc WHERE code = concat('CM', d.id::text)),
					(
					SELECT
						CASE
							WHEN ch.%I > 0 THEN ch.%I
							ELSE (SELECT ln.integrated_id FROM %I.%I ln JOIN %I.%I child ON child.%I = ln.%I AND child.lot_id = ln.lot_id WHERE child.uuid = ch.uuid AND ln.integrated_id IS NOT NULL
							AND ln.lot_id IN (SELECT lot_id FROM %I.om_campaign_lot WHERE campaign_id = $1) LIMIT 1)
						END as feature_id
					)
				FROM %I.%I d
				JOIN %I.%I dx ON dx.doc_id = d.id
				JOIN %I.%I ch ON ch.uuid = dx.%I
				JOIN %I.%I ocl ON ocl.%I = ch.%I AND ocl.lot_id = ch.lot_id
				WHERE (ocl.action IS NULL OR ocl.action <> 3)
				AND ocl.lot_id IN (SELECT lot_id FROM %I.om_campaign_lot WHERE campaign_id = $1)
			$q$,
			v_parentschema, 'doc_x_' || lower(v_catfeature.feature_type::text), v_catfeature.column_id,
			v_parentschema,
			v_catfeature.column_id, v_catfeature.column_id,
			v_cmschema, v_catfeature.campaign_layer, v_cmschema, v_catfeature.source_layer, v_catfeature.column_id, v_catfeature.column_id,
			v_cmschema,
			v_cmschema, 'doc',
			v_cmschema, 'doc_x_' || lower(v_catfeature.feature_type::text),
			v_cmschema, v_catfeature.source_layer, concat(lower(v_catfeature.feature_type), '_uuid'),
			v_cmschema, v_catfeature.campaign_layer, v_catfeature.column_id, v_catfeature.column_id,
			v_cmschema
		);
		EXECUTE v_querytext USING v_campaign;
	END LOOP;

	-- UPDATE campaign workcat
	UPDATE cm.om_campaign SET workcat_id = v_workcat_id WHERE campaign_id = v_campaign;

	-- Unlock production features locked during campaign (lock_level=3 set on om_campaign_x_* insert)
	UPDATE PARENT_SCHEMA.node SET lock_level = NULL WHERE
		node_id IN (SELECT node_id FROM cm.om_campaign_x_node WHERE campaign_id = v_campaign AND node_id > 0);

	UPDATE PARENT_SCHEMA.arc SET lock_level = NULL WHERE
		arc_id IN (SELECT arc_id FROM cm.om_campaign_x_arc WHERE campaign_id = v_campaign AND arc_id > 0);

	UPDATE PARENT_SCHEMA.connec SET lock_level = NULL WHERE
		connec_id IN (SELECT connec_id FROM cm.om_campaign_x_connec WHERE campaign_id = v_campaign AND connec_id > 0);

	UPDATE PARENT_SCHEMA.link SET lock_level = NULL WHERE
		link_id IN (SELECT link_id FROM cm.om_campaign_x_link WHERE campaign_id = v_campaign AND link_id > 0);

	-- Check and create missing catalog entries
	SELECT cm.gw_fct_cm_check_catalogs(json_build_object('data', json_build_object(
		'projectType', v_project_type,
		'version', v_version,
		'fromProduction', true,
		'campaign_id', v_campaign::text,
		'lot_id', null
	))) INTO v_cat_result;
	v_cat_log := COALESCE(v_cat_result->'body'->>'log', '');
	IF v_cat_log IS NOT NULL THEN
		SELECT COUNT(*) INTO v_catalogs_created FROM regexp_matches(v_cat_log, 'Created new catalog entry', 'g');
		v_catalogs_created := COALESCE(v_catalogs_created, 0);
	END IF;
	
	-- manage campaing status value (INTEGRATED) and clean selectors
	UPDATE cm.om_campaign SET status = 3 WHERE campaign_id = v_campaign; -- we need to set the campaign status to Assigned to update lot status to Accepted.
	UPDATE cm.om_campaign_lot SET status=9 WHERE campaign_id=v_campaign;
	UPDATE cm.om_campaign SET status=9 WHERE campaign_id=v_campaign;
	DELETE FROM cm.selector_lot where lot_id in (select lot_id from cm.om_campaign_lot where campaign_id=v_campaign);
	DELETE FROM cm.selector_campaign where campaign_id = v_campaign;

	-- managing results
	v_result := COALESCE(v_result, '{}');

	-- Build info messages with operation totals and catalog summary
	v_result_info := json_build_object(
		'values', json_build_array(
			json_build_object('message', format('Inserted: %s', v_tot_ins)),
			json_build_object('message', format('Updated: %s', v_tot_upd)),
			json_build_object('message', format('Deleted: %s', v_tot_del)),
			json_build_object('message', format('Catalogs created: %s', COALESCE(v_catalogs_created, 0)))
		)
	);
	v_result_point := COALESCE(v_result_point, '{}');

	--  Build return and restore search_path
	v_result := PARENT_SCHEMA.gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
			',"body":{"form":{}'||
			',"data":{ "info":'||v_result_info||','||
				'"point":'||v_result_point||
			'}}'||
		'}')::json, 3426, null, null, null);

	-- Restore trigger params to their previous values
	FOR v_restore_param IN
		SELECT parameter, prev_value, existed
		FROM tmp_cm_integrate_trigger_params
	LOOP
		IF v_restore_param.existed IS TRUE THEN
			UPDATE config_param_user
			SET value = v_restore_param.prev_value
			WHERE parameter = v_restore_param.parameter
			AND cur_user = current_user;
		ELSE
			DELETE FROM config_param_user
			WHERE parameter = v_restore_param.parameter
			AND cur_user = current_user;
		END IF;
	END LOOP;
	
	UPDATE config_param_system SET "value" = v_old_variable_update_nodes WHERE "parameter"='edit_arc_enable nodes_update';

	PERFORM set_config('search_path', v_prev_search_path, true);
	RETURN v_result;

EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	-- Restore trigger params even on error
	IF to_regclass('pg_temp.tmp_cm_integrate_trigger_params') IS NOT NULL THEN
		FOR v_restore_param IN
			SELECT parameter, prev_value, existed
			FROM tmp_cm_integrate_trigger_params
		LOOP
			IF v_restore_param.existed IS TRUE THEN
				UPDATE config_param_user
				SET value = v_restore_param.prev_value
				WHERE parameter = v_restore_param.parameter
				AND cur_user = current_user;
			ELSE
				DELETE FROM config_param_user
				WHERE parameter = v_restore_param.parameter
				AND cur_user = current_user;
			END IF;
		END LOOP;
	END IF;
	UPDATE config_param_system SET "value" = v_old_variable_update_nodes WHERE "parameter"='edit_arc_enable nodes_update';

	-- Ensure restoration on error
	PERFORM set_config('search_path', v_prev_search_path, true);
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

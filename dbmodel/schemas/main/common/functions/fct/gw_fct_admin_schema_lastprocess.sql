/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2650

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_schema_lastprocess(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE

SELECT SCHEMA_NAME.gw_fct_admin_schema_lastprocess($${
"client":{"lang":"ES"},
"data":{"isNewProject":"TRUE", "gwVersion":"3.1.105", "projectType":"WS",
		"epsg":"SRID_VALUE", "title":"test project", "author":"test", "date":"01/01/2000", "superUsers":["postgres", "giswater"]}}$$)


SELECT SCHEMA_NAME.gw_fct_admin_schema_lastprocess($${
"client":{"lang":"ES"},
"data":{"isNewProject":"FALSE", "gwVersion":"3.3.031", "projectType":"UD", "epsg":SRID_VALUE}}$$)


-- fid: 133

*/

DECLARE

v_dbnname varchar;
v_projecttype text;
v_message text;
v_version record;
v_gwversion text;
v_language text;
v_epsg integer;
v_isnew boolean;
v_issample boolean;
v_descript text;
v_name text;
v_author text;
v_date text;
v_schema_info json;
v_superusers text;
v_creation_profile text;
v_tablename record;
v_schemaname text;
v_oldversion text;
v_error_context text;
v_priority integer = 1;
v_fid integer = 133;
v_result text;
v_result_info text;
v_status text;
v_rectable record;
v_max_seq_id integer;
v_querytext text;
v_definition text;
rec_viewname text;
rec_feature record;

rec_mapzone text;
v_mapzone_arr text[];

BEGIN
	-- search path
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	-- get input parameters
	v_gwversion := (p_data ->> 'data')::json->> 'gwVersion';
	v_language := (p_data ->> 'client')::json->> 'lang';
	v_projecttype := (p_data ->> 'data')::json->> 'projectType';
	v_epsg := (p_data ->> 'data')::json->> 'epsg';
	v_isnew := (p_data ->> 'data')::json->> 'isNewProject';
	v_issample := (p_data ->> 'data')::json->> 'isSample';
	v_descript := (p_data ->> 'data')::json->> 'descript';
	v_name := (p_data ->> 'data')::json->> 'name';
	v_author := (p_data ->> 'data')::json->> 'author';
	v_date := (p_data ->> 'data')::json->> 'date';
	v_superusers := (p_data ->> 'data')::json->> 'superUsers';
	v_creation_profile := (p_data ->> 'data')::json->> 'creationProfile';

	--reset sequences for a new project or for a sample
	IF  v_issample IS TRUE THEN
		FOR v_rectable IN (
		    SELECT c.table_name as table_name, c.column_name as column_name, s.sequence_name as sequence_name FROM information_schema.columns c
            JOIN ( SELECT table_schema, table_name, column_name, substring(column_default from '''(.*)''') AS sequence_name
                   FROM information_schema.columns
                   WHERE table_schema = 'SCHEMA_NAME' AND column_default ILIKE 'nextval%'
            ) AS s ON c.table_schema = s.table_schema
                    AND c.table_name = s.table_name
                    AND c.column_name = s.column_name
            WHERE
                c.table_schema = 'SCHEMA_NAME'
                AND s.sequence_name IS NOT NULL
                AND s.sequence_name != 'urn_id_seq'
                AND s.sequence_name != 'doc_seq'
                AND s.sequence_name != 'raingage_rg_id_seq'
				AND s.sequence_name != 'ext_plot_id_seq'
				AND s.sequence_name != 'ext_streetaxis_id_seq'
				AND s.sequence_name != 'ext_address_id_seq'
            ORDER BY
                s.sequence_name
        )
		LOOP
		    v_querytext:= 'SELECT max('||v_rectable.column_name||') FROM '||v_rectable.table_name||';' ;
		    EXECUTE v_querytext INTO v_max_seq_id;

		    IF v_max_seq_id IS NOT NULL AND v_max_seq_id > 0 THEN
			EXECUTE 'SELECT setval(''SCHEMA_NAME.'||v_rectable.sequence_name||' '','||v_max_seq_id||', true)';
		    END IF;
		END LOOP;

		v_message='Sequeneces set correctly';
	ELSE
		-- enable triggers on typevalue tables
		ALTER TABLE om_typevalue ENABLE TRIGGER gw_trg_typevalue_config_fk;
		ALTER TABLE edit_typevalue ENABLE TRIGGER gw_trg_typevalue_config_fk;
		ALTER TABLE inp_typevalue ENABLE TRIGGER gw_trg_typevalue_config_fk;
		ALTER TABLE plan_typevalue ENABLE TRIGGER gw_trg_typevalue_config_fk;
		ALTER TABLE sys_typevalue ENABLE TRIGGER gw_trg_typevalue_config_fk;
		ALTER TABLE config_typevalue ENABLE TRIGGER gw_trg_typevalue_config_fk;
		ALTER TABLE sys_foreignkey ENABLE TRIGGER gw_trg_typevalue_config_fk;

		-- create triggers for the oposite tables against typevalues
		PERFORM gw_fct_admin_manage_triggers('fk','ALL');

		-- create notifications triggers
		PERFORM gw_fct_admin_manage_triggers('notify',null);

		-- update cat feature triggering default values and others
		UPDATE cat_feature SET id=id;

		-- last proccess
		IF v_isnew IS TRUE THEN

			-- inserting version table
			PERFORM gw_fct_admin_sys_version_register(json_build_object(
				'client', json_build_object('lang', v_language),
				'data', json_build_object(
					'gwVersion', v_gwversion,
					'projectType', v_projecttype,
					'epsg', v_epsg,
					'isNewProject', 'TRUE',
					'creationProfile', COALESCE(v_creation_profile, 'empty')
				)
			)::json);

			-- create json info_schema
			v_descript := COALESCE(v_descript, '');
			v_name := COALESCE(v_name, '');
			v_author := COALESCE(v_author, '');
			v_date := COALESCE(v_date, '');

			v_schema_info = '{"name":"'||v_name||'","descript":"'||v_descript||'","author":"'||v_author||'","date":"'||v_date||'"}';

			-- drop deprecated tables
			FOR v_tablename IN SELECT table_name FROM information_schema.tables WHERE table_schema=v_schemaname and substring(table_name,1 , 1) = '_'
			LOOP
				EXECUTE 'DROP TABLE IF EXISTS '||v_tablename.table_name||' CASCADE';
			END LOOP;

			-- enable triggers
			ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_config_control;
			ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_typevalue_fk_insert;
			ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_typevalue_fk_update;

			-- set mapzones symbology
            UPDATE config_param_system SET value = (replace(value, 'Random', 'Disable')) WHERE parameter='utils_graphanalytics_style';
            UPDATE config_param_system SET value = (replace(value, 'Stylesheet', 'Disable')) WHERE parameter='utils_graphanalytics_style';

			-- reset sequences
			IF v_projecttype = 'UD' THEN
				ALTER SEQUENCE SCHEMA_NAME.cat_dwf_id_seq MINVALUE 0;
				ALTER SEQUENCE SCHEMA_NAME.cat_hydrology_hydrology_id_seq MINVALUE 0;
				PERFORM setval('SCHEMA_NAME.cat_dwf_id_seq',0);
				PERFORM setval('SCHEMA_NAME.cat_hydrology_hydrology_id_seq',0);
			END IF;

			-- drop deprecated views
			IF v_projecttype = 'WS' THEN
				DROP VIEW IF EXISTS ve_man_varc;
				DROP VIEW IF EXISTS ve_man_pipe;
				DROP VIEW IF EXISTS ve_man_expansiontank;
				DROP VIEW IF EXISTS ve_man_filter;
				DROP VIEW IF EXISTS ve_man_flexunion;
				DROP VIEW IF EXISTS ve_man_hydrant;
				DROP VIEW IF EXISTS ve_man_junction;
				DROP VIEW IF EXISTS ve_man_meter;
				DROP VIEW IF EXISTS ve_man_netsamplepoint;
				DROP VIEW IF EXISTS ve_man_netwjoin;
				DROP VIEW IF EXISTS ve_man_pump;
				DROP VIEW IF EXISTS ve_man_reduction;
				DROP VIEW IF EXISTS ve_man_register;
				DROP VIEW IF EXISTS ve_man_source;
				DROP VIEW IF EXISTS ve_man_tank;
				DROP VIEW IF EXISTS ve_man_valve;
				DROP VIEW IF EXISTS ve_man_waterwell;
				DROP VIEW IF EXISTS ve_man_manhole;
				DROP VIEW IF EXISTS ve_man_wtp;
				DROP VIEW IF EXISTS ve_man_fountain;
				DROP VIEW IF EXISTS ve_man_tap;
				DROP VIEW IF EXISTS ve_man_greentap;
				DROP VIEW IF EXISTS ve_man_wjoin;
				DROP VIEW IF EXISTS ve_man_fountain_pol;
				DROP VIEW IF EXISTS ve_man_register_pol;
				DROP VIEW IF EXISTS ve_man_tank_pol;
				DROP VIEW IF EXISTS v_anl_mincut_planified_arc;
				DROP VIEW IF EXISTS v_anl_mincut_planified_valve;
				DROP VIEW IF EXISTS v_anl_mincut_result_arc;
				DROP VIEW IF EXISTS v_anl_mincut_result_audit;
				DROP VIEW IF EXISTS v_anl_mincut_result_conflict_arc;
				DROP VIEW IF EXISTS v_anl_mincut_result_conflict_valve;
				DROP VIEW IF EXISTS v_anl_mincut_result_connec;
				DROP VIEW IF EXISTS v_anl_mincut_result_hydrometer;
				DROP VIEW IF EXISTS v_anl_mincut_result_node;
				DROP VIEW IF EXISTS v_anl_mincut_result_polygon;
				DROP VIEW IF EXISTS v_anl_mincut_result_valve;
			ELSIF v_projecttype = 'UD' THEN
				DROP VIEW IF EXISTS ve_man_chamber;
				DROP VIEW IF EXISTS ve_man_chamber_pol;
				DROP VIEW IF EXISTS ve_man_conduit;
				DROP VIEW IF EXISTS ve_man_connec;
				DROP VIEW IF EXISTS ve_man_gully;
				DROP VIEW IF EXISTS ve_man_gully_pol;
				DROP VIEW IF EXISTS ve_man_junction;
				DROP VIEW IF EXISTS ve_man_manhole;
				DROP VIEW IF EXISTS ve_man_netgully;
				DROP VIEW IF EXISTS ve_man_netgully_pol;
				DROP VIEW IF EXISTS ve_man_netinit;
				DROP VIEW IF EXISTS ve_man_outfall;
				DROP VIEW IF EXISTS ve_man_siphon;
				DROP VIEW IF EXISTS ve_man_storage;
				DROP VIEW IF EXISTS ve_man_storage_pol;
				DROP VIEW IF EXISTS ve_man_valve;
				DROP VIEW IF EXISTS ve_man_varc;
				DROP VIEW IF EXISTS ve_man_waccel;
				DROP VIEW IF EXISTS ve_man_wjump;
				DROP VIEW IF EXISTS ve_man_wwtp;
				DROP VIEW IF EXISTS ve_man_wwtp_pol;
			END IF;

			-- drop deprecated columns
			IF v_projecttype = 'WS' THEN
				ALTER TABLE inp_pattern_value DROP COLUMN IF EXISTS _factor_19;
				ALTER TABLE inp_pattern_value DROP COLUMN IF EXISTS _factor_20;
				ALTER TABLE inp_pattern_value DROP COLUMN IF EXISTS _factor_21;
				ALTER TABLE inp_pattern_value DROP COLUMN IF EXISTS _factor_22;
				ALTER TABLE inp_pattern_value DROP COLUMN IF EXISTS _factor_23;
				ALTER TABLE inp_pattern_value DROP COLUMN IF EXISTS _factor_24;
				ALTER TABLE config_graph_mincut DROP COLUMN IF EXISTS _to_arc;
				ALTER TABLE ext_hydrometer DROP COLUMN IF EXISTS hydrometer_category;
				ALTER TABLE ext_hydrometer DROP COLUMN IF EXISTS cat_hydrometer_id;
				ALTER TABLE connec DROP COLUMN IF EXISTS _valve_type;
				ALTER TABLE connec DROP COLUMN IF EXISTS _shutoff_valve;
			ELSE
				ALTER TABLE cat_arc_shape DROP COLUMN IF EXISTS _tsect_id;
				ALTER TABLE cat_arc_shape DROP COLUMN IF EXISTS _curve_id;
				ALTER TABLE man_conduit DROP COLUMN IF EXISTS _inlet_offset;
				ALTER TABLE node DROP COLUMN IF EXISTS _sys_elev;
			END IF;

			ALTER TABLE sys_foreignkey DROP COLUMN IF EXISTS _id;
			ALTER TABLE cat_feature_arc DROP COLUMN IF EXISTS _type;
			ALTER TABLE cat_feature_node DROP COLUMN IF EXISTS _type;
			ALTER TABLE cat_feature_connec DROP COLUMN IF EXISTS _type;
			ALTER TABLE arc DROP COLUMN IF EXISTS _sys_length;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _default_value_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _form_label_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _widgettype_id_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _dv_table_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _dv_key_column_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _sql_text_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _field_length_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _num_decimals_;
			ALTER TABLE sys_addfields DROP COLUMN IF EXISTS _dv_value_column_;

			-- drop NOT NULL restrictions
			ALTER TABLE arc ALTER COLUMN verified DROP NOT NULL;
			ALTER TABLE node ALTER COLUMN verified DROP NOT NULL;
			ALTER TABLE connec ALTER COLUMN verified DROP NOT NULL;
			ALTER TABLE element ALTER COLUMN verified DROP NOT NULL;

			ALTER TABLE arc ALTER COLUMN workcat_id DROP NOT NULL;
			ALTER TABLE node ALTER COLUMN workcat_id DROP NOT NULL;
			ALTER TABLE connec ALTER COLUMN workcat_id DROP NOT NULL;
			ALTER TABLE element ALTER COLUMN workcat_id DROP NOT NULL;

			IF v_projecttype = 'UD' THEN
				ALTER TABLE cat_feature_gully DROP COLUMN IF EXISTS _type;
				ALTER TABLE gully ALTER COLUMN verified DROP NOT NULL;
				ALTER TABLE gully ALTER COLUMN workcat_id DROP NOT NULL;
				ALTER TABLE gully DROP COLUMN IF EXISTS _gratecat2_id;
				ALTER TABLE link DROP COLUMN IF EXISTS _expl_id2;
			END IF;

			-- inserting on config_param_system table
			INSERT INTO config_param_system (parameter, value, datatype, descript, project_type, label)
			VALUES ('admin_schema_info', v_schema_info,'json', 'Basic information about schema','utils', 'Schema manager:')
			ON CONFLICT (parameter) DO UPDATE SET value = EXCLUDED.value;

			--update value of rename_view_x_id parameter
			UPDATE config_param_system SET value='{"rename_view_x_id":true}' WHERE parameter='admin_manage_cat_feature';

			-- remove deprecated parameters on config_param_system
			DELETE FROM config_param_system WHERE parameter = 'om_mincut_enable_alerts';

			-- fk for ext tables or utils schema
			PERFORM gw_fct_admin_schema_utils_fk();

			--change widgettype for matcat_id when new empty data project (UD)
			IF v_projecttype = 'UD' THEN
				UPDATE config_form_fields SET iseditable=TRUE, widgettype='combo', dv_isnullvalue=TRUE, dv_querytext='SELECT id, id AS idval FROM cat_material WHERE ''NODE'' = ANY(feature_type)'
				WHERE columnname='matcat_id' AND formname LIKE 've_node%';

				UPDATE config_form_fields SET iseditable=TRUE, widgettype='combo', dv_isnullvalue=TRUE, dv_querytext='SELECT id, id AS idval FROM cat_material WHERE ''ARC'' = ANY(feature_type)'
				WHERE columnname='matcat_id' AND formname LIKE 've_connec%';

				UPDATE config_form_fields SET iseditable=TRUE, widgettype='combo', dv_isnullvalue=TRUE, dv_querytext='SELECT id, id AS idval FROM cat_material WHERE ''ARC'' = ANY(feature_type)'
				WHERE columnname='matcat_id' AND formname LIKE 've_arc%';

				UPDATE config_form_fields SET iseditable=TRUE, widgettype='combo', dv_isnullvalue=TRUE, dv_querytext='SELECT id, id AS idval FROM cat_material WHERE ''NODE'' = ANY(feature_type)'
				WHERE columnname='matcat_id' AND formname IN ('ve_node');

				UPDATE config_form_fields SET iseditable=TRUE, widgettype='combo', dv_isnullvalue=TRUE, dv_querytext='SELECT id, id AS idval FROM cat_material WHERE ''ARC'' = ANY(feature_type)'
				WHERE columnname='matcat_id' AND formname IN ('ve_arc', 've_connec');

			END IF;

			-- forcing user variables in order to enhance usability for new projects
			UPDATE sys_param_user SET vdefault = '1', ismandatory =  true WHERE id ='edit_state_vdefault';
			UPDATE sys_param_user SET vdefault = 'false', ismandatory = true WHERE id ='qgis_info_docker';
			UPDATE sys_param_user SET vdefault = 'true', ismandatory = true WHERE id ='qgis_form_docker';

			-- force all cat feature not active in order to increase step-by-step
			-- Skip for empty projects: locale catalogs define active on purpose.
			IF COALESCE(NULLIF(v_creation_profile, ''), 'empty') <> 'empty' THEN
				IF v_projecttype = 'WS' THEN
					UPDATE cat_feature SET active = false WHERE feature_class NOT IN ('VALVE', 'WJOIN', 'JUNCTION', 'TANK', 'PIPE', 'FRELEM', 'VLINK', 'PIPELINK'); -- ws projects
				ELSE
					UPDATE cat_feature SET active = false WHERE feature_class NOT IN ('CONDUIT', 'JUNCTION', 'CJOIN', 'GINLET', 'OUTFALL', 'FRELEM', 'VLINK', 'CONDUITLINK'); -- ud projects
				END IF;
			END IF;

			-- hidden lastupdate and lastupdate_user columns
			update config_form_fields SET hidden = true WHERE columnname IN ('updated_at', 'updated_by', 'lastupdate', 'lastupdate_user', 'publish', 'uncertain');

			-- disable edit_disable_noderotation
			UPDATE sys_param_user SET ismandatory = true, vdefault ='TRUE' WHERE id = 'edit_disable_noderotation';

			v_message='Project sucessfully created';

			-- automatize graph analytics config for ws
			UPDATE config_param_system SET value = 'TRUE' where parameter = 'utils_graphanalytics_automatic_config';

			-- UPDATE edit_check_redundance_y_topelev_elev
			UPDATE config_param_system SET value = 'TRUE' WHERE parameter = 'edit_check_redundance_y_topelev_elev';

			-- Make visible fields on feature forms
			IF v_projecttype = 'WS' THEN
				UPDATE config_form_fields SET hidden = false where (columnname IN ('press_max', 'press_min', 'press_avg') OR columnname IN ('head_max', 'head_min', 'head_avg') OR columnname IN ('demand_max', 'demand_min', 'demand_avg') OR
				columnname IN ('om_state', 'conserv_state', 'access_type', 'placement_type', 'hydrant_type', 'valve_type'))
				AND formname ilike 've_node%';

				UPDATE config_form_fields SET hidden = false where (columnname IN ('flow_max', 'flow_min', 'flow_avg') OR columnname IN ('vel_max', 'vel_min', 'vel_avg') OR
				columnname IN ('om_state', 'conserv_state'))
				AND formname ilike 've_arc%';

				UPDATE config_form_fields SET hidden = false where (columnname IN ('demand_max', 'demand_min', 'demand_avg') OR columnname IN ('press_max', 'press_min', 'press_avg') OR
				columnname IN ('om_state', 'conserv_state', 'priority', 'valve_location', 'valve_type', 'shutoff_valve', 'access_type', 'placement_type', 'crmzone_id'))
				AND formname ilike 've_connec%';

				UPDATE config_form_fields SET hidden=true WHERE formname = 've_arc' AND columnname='parent_id';
				UPDATE config_form_fields SET hidden=true WHERE formname like 've_arc%' AND columnname='parent_id';
				UPDATE config_form_fields SET hidden=true WHERE formname = 've_arc' AND columnname='observ';
				UPDATE config_form_fields SET hidden=true WHERE formname like 've_arc%' AND columnname='observ';

			ELSIF v_projecttype = 'UD' THEN
				UPDATE config_form_fields SET layoutorder=30 WHERE formname = 've_arc' AND columnname='pavcat_id';
				UPDATE config_form_fields SET layoutorder=30 WHERE formname like 've_arc%' AND columnname='pavcat_id';
			END IF;

			-- setting search where search_field is arc_id, node_id, connec_id, gully_id
			UPDATE config_param_system SET value =
			'{"sys_table_id":"ve_arc","sys_id_field":"arc_id","sys_search_field":"arc_id","alias":"Arcs","cat_field":"arccat_id","orderby":"1","search_type":"arc"}'
			WHERE parameter = 'basic_search_network_arc';

			UPDATE config_param_system SET value =
			'{"sys_table_id":"ve_connec","sys_id_field":"connec_id","sys_search_field":"connec_id","alias":"Connecs","cat_field":"conneccat_id","orderby":"3","search_type":"connec"}'
			WHERE parameter = 'basic_search_network_connec';

			UPDATE config_param_system SET value =
			'{"sys_table_id":"ve_element","sys_id_field":"element_id","sys_search_field":"element_id","alias":"Elements","cat_field":"elementcat_id","orderby":"5","search_type":"element"}'
			WHERE parameter = 'basic_search_network_element';

			UPDATE config_param_system SET value =
			'{"sys_table_id":"ve_node","sys_id_field":"node_id","sys_search_field":"node_id","alias":"Nodes","cat_field":"nodecat_id","orderby":"2","search_type":"node"}'
			WHERE  parameter = 'basic_search_network_node';

			UPDATE config_param_system SET value =
			'{"sys_table_id":"ve_gully","sys_id_field":"gully_id","sys_search_field":"gully_id","alias":"Gullies","cat_field":"gullycat_id","orderby":"3","search_type":"gully"}'
			WHERE  parameter = 'basic_search_network_gully';

		ELSIF v_isnew IS FALSE THEN

			-- fix i18n
			IF v_gwversion = '3.6.009' AND v_oldversion IN ('3.6.008', '3.6.008.1', '3.6.008.2') THEN
				PERFORM gw_fct_admin_manage_fix_i18n_36008();
			END IF;

			DROP FUNCTION IF EXISTS gw_fct_admin_manage_fix_i18n_36008();


			SELECT project_type INTO v_projecttype FROM sys_version ORDER BY 1 DESC LIMIT 1;

			-- profilactic delete to avoid conflicts with sequences and to clean gdb
			DELETE FROM audit_check_project;
			DELETE FROM audit_check_data;
			DELETE FROM temp_arc;
			DELETE FROM temp_anlgraph;
			DELETE FROM temp_csv;
			DELETE FROM temp_data;
			DELETE FROM temp_node;
			DELETE FROM temp_go2epa;
			DELETE FROM temp_table;

			DELETE FROM anl_arc;
			DELETE FROM anl_arc_x_node;
			DELETE FROM anl_node;
			DELETE FROM anl_polygon;

			IF v_projecttype = 'WS' THEN

				DELETE FROM temp_mincut;
				DELETE FROM temp_demand;
			ELSE
				DELETE FROM temp_arc_flowregulator;
				DELETE FROM temp_gully;
				DELETE FROM temp_lid_usage;
			END IF;

			INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (v_fid, 4, 'UPDATE PROJECT SCHEMA');
			INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (v_fid, 4, '---------------------');
			INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (v_fid, 3, '');

			INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (v_fid, 2, 'INFO');     -- Info is 2 because we are inserting previously (updat sql) some info message for user using 1
			INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (v_fid, 2, '----');

			v_oldversion = (SELECT giswater FROM sys_version ORDER BY id DESC LIMIT 1);

			-- inserting version table
			PERFORM gw_fct_admin_sys_version_register(json_build_object(
				'client', json_build_object('lang', v_language),
				'data', json_build_object(
					'gwVersion', v_gwversion,
					'projectType', v_projecttype,
					'epsg', v_epsg,
					'isNewProject', 'FALSE'
				)
			)::json);

			INSERT INTO audit_check_data (fid, criticity, error_message) VALUES (v_fid, 4, concat('Project have been sucessfully updated from ',v_oldversion,' version to ',v_gwversion, ' version'));
			v_message='Project sucessfully updated';

			IF v_oldversion IN ('3.6.007', '3.6.008', '3.6.008.1', '3.6.008.2') THEN

				FOR rec_feature IN SELECT * FROM cat_feature
				LOOP
					INSERT INTO sys_table (id, descript, sys_role, context, alias)
					VALUES (rec_feature.child_layer, concat('Custom edit view for ', rec_feature.child_layer), 'role_edit', concat('["INVENTORY","NETWORK","',
					upper(rec_feature.feature_type),'"]'), rec_feature.id)
					ON CONFLICT (id)
					DO update set context = concat('["INVENTORY","NETWORK","', upper(rec_feature.feature_type),'"]');
				END LOOP;
			END IF;

			PERFORM setval('SCHEMA_NAME.urn_id_seq', gw_fct_setvalurn(),true); --into v_next_val;

		END IF;

        -- delete all functions not related to project type
        IF v_projecttype = 'WS' THEN
            DELETE FROM sys_function WHERE lower(project_type) = 'ud';
        ELSE
            DELETE FROM sys_function WHERE lower(project_type) = 'ws';
        END IF;

		--reset sequences and id of anl, temp and audit tables
		PERFORM gw_fct_admin_reset_sequences();

		-- last process
		PERFORM gw_fct_admin_role_permissions();
		PERFORM gw_fct_setowner($${"data":{"owner":"role_system"}}$$);

		--build return with log table
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM audit_check_data
		WHERE cur_user="current_user"() AND fid=v_fid ORDER BY criticity desc, id asc) row;

	END IF;


	-- set urn_id_seq to mapzones
	IF v_projecttype = 'WS' THEN
		v_mapzone_arr := ARRAY['omzone', 'dma', 'sector', 'presszone',  'dqa', 'supplyzone', 'crmzone']; 
	ELSIF v_projecttype = 'UD' THEN
		v_mapzone_arr := ARRAY['omzone', 'dma', 'sector', 'dwfzone'];
	END IF;

	FOREACH rec_mapzone IN ARRAY v_mapzone_arr
	LOOP
		RAISE NOTICE '%', rec_mapzone;
	
		EXECUTE format('
		ALTER TABLE %I ALTER COLUMN %s SET DEFAULT nextval(''urn_id_seq''::regclass)
		', 
		rec_mapzone,
		rec_mapzone || '_id',
		'mapzone_id_seq'
		);

	END LOOP;

	IF v_projecttype = 'WS' THEN
	
		EXECUTE 'ALTER TABLE plan_netscenario_dma ALTER COLUMN dma_id SET DEFAULT nextval(''urn_id_seq''::regclass)';
		EXECUTE 'ALTER TABLE plan_netscenario_presszone ALTER COLUMN presszone_id SET DEFAULT nextval(''urn_id_seq''::regclass)';

	END IF;


    -- recreate views
    PERFORM gw_fct_admin_manage_child_views($${"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{},
    "data":{"filterFields":{}, "pageInfo":{}, "action":"MULTI-CREATE" }}$$);

    -- set to_arc no editable for valves
    UPDATE config_form_fields SET iseditable=false WHERE columnname='to_arc';

	v_result_info := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result_info, '}');

	-- Return
	RETURN ('{"status":"Accepted", "message":{"level":"'||v_priority||'", "text":"'||v_message||'"}'||
		',"body":{"form":{}'||
			',"data":{ "info":'||v_result_info||
			'}}}');

    -- Exception handling
    --EXCEPTION WHEN OTHERS THEN
    --GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    --RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
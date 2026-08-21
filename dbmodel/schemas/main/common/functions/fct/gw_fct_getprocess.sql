/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3210

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getprocess(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE:



SELECT SCHEMA_NAME.gw_fct_getprocess($${"client":{"device":4, "lang":"CA", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "functionId":2522}}$$);


*/

DECLARE

v_version text;
v_projectype text;
v_filter text;
v_fields json;
rec record;
v_querytext text;
v_querytext_mod text;
v_queryresult text;
v_expl text;
v_state text;
v_inp_result text;
v_rpt_result text;
v_return json;
v_nodetype text;
v_nodecat text;
v_arrayresult text[];
v_selectedid text;
v_rec_replace json;
v_errcontext text;
v_querystring text;
v_debug_vars json;
v_debug json;
v_msgerr json;
v_value text;
v_inp_hydrology text;
v_inp_dwf text;
v_inp_dscenario text;
v_sector text;
v_process json;
v_mincut integer;
v_device integer;
v_function_id integer;

v_value_element text;
v_value_array text[];
v_value_json json;
v_response_array text[];
v_fields_aux json;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get project type
	SELECT lower(project_type) INTO v_projectype FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get input parameter
	v_filter := (p_data ->> 'data')::json->> 'filterText';
	v_device := (p_data ->> 'client')::json->> 'device';
	v_function_id := (p_data ->> 'data')::json->> 'functionId';

	-- get variables
	v_expl  = (SELECT expl_id FROM selector_expl WHERE cur_user = current_user limit 1);
	v_state  = (SELECT expl_id FROM selector_expl WHERE cur_user = current_user limit 1);
	v_inp_result = (SELECT result_id FROM selector_inp_result WHERE cur_user = current_user limit 1);
	v_rpt_result = (SELECT result_id FROM selector_rpt_main WHERE cur_user = current_user limit 1);
	v_inp_hydrology = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_hydrology_scenario' AND cur_user = current_user limit 1);
	v_inp_dwf = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_dwfscenario' AND cur_user = current_user limit 1);
	v_inp_dscenario = (SELECT dscenario_id FROM selector_inp_dscenario WHERE cur_user = current_user limit 1);
	v_sector = (SELECT sector_id FROM selector_sector WHERE cur_user = current_user AND sector_id > 0 limit 1 );

	DROP TABLE IF EXISTS temp_sys_function;
	DROP TABLE IF EXISTS temp_config_toolbox;

	CREATE TEMP TABLE IF NOT EXISTS temp_sys_function AS SELECT * FROM v_sys_function;
	CREATE TEMP TABLE IF NOT EXISTS temp_config_toolbox AS SELECT*FROM config_toolbox;

	IF v_projectype = 'ws' then

		v_mincut = (SELECT result_id FROM selector_mincut_result WHERE cur_user = current_user limit 1 );

		if v_function_id in (3142, 3110) then
			-- get enddate proposal for demand dscenarios
			PERFORM gw_fct_create_dscenario_from_crm($${"client":{"device":4, "lang":"ca_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"step":1, "exploitation":"1"}}}$$);
			PERFORM gw_fct_waterbalance($${"client":{"device":4, "infoType":1, "lang":"ES"},"form":{}, "data":{"parameters":{"step":"1"}}}$$)::text;
		end if;

	END IF;

	v_nodetype = (SELECT value FROM config_param_user WHERE cur_user = current_user AND parameter = 'edit_nodetype_vdefault');
	IF v_nodetype IS NULL OR (SELECT id FROM cat_node WHERE node_type = v_nodetype OR node_type IS NULL limit 1) IS NULL THEN
		v_nodetype = (SELECT id  FROM cat_feature_node JOIN cat_feature USING  (id) WHERE active IS TRUE limit 1);
	END IF;

	v_nodecat = (SELECT value FROM config_param_user WHERE cur_user = current_user AND parameter = 'edit_nodecat_vdefault');

	IF v_nodecat IS NULL THEN
		IF v_projectype = 'ws' THEN
			v_nodecat = (SELECT id FROM cat_node WHERE active IS true AND node_type = v_nodetype limit 1);
		ELSIF  v_projectype = 'ud' THEN
			v_nodecat = (SELECT id FROM cat_node WHERE active IS true AND node_type = v_nodetype limit 1);
		END IF;

		IF v_nodecat IS NULL and v_projectype = 'ud' THEN
			v_nodecat = (SELECT id FROM cat_node WHERE active IS true limit 1);
		END IF;

	END IF;

	-- get process parameters
    v_querystring = concat('SELECT row_to_json(a) FROM (
                 SELECT id, alias, descript, functionparams, inputparams AS fields, observ AS isnotparammsg, sys_role, function_name as functionname, source
                 FROM temp_sys_function
                 JOIN temp_config_toolbox USING (id)
                 WHERE id = '||v_function_id||') a');
	v_debug_vars := json_build_object('v_filter', v_filter, 'v_projectype', v_projectype);
	v_debug := json_build_object('querystring', v_querystring, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 10);
	SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;
	RAISE NOTICE 'v_querystring: %', v_querystring;
	EXECUTE v_querystring INTO v_fields;

	-- refactor dvquerytext
	FOR rec IN SELECT json_array_elements(inputparams::json) as inputparams, functionparams
	FROM temp_sys_function JOIN temp_config_toolbox USING (id)
	WHERE id = v_function_id  AND temp_config_toolbox.active IS TRUE AND (project_type=v_projectype OR project_type='utils')
	loop
		v_querytext = rec.inputparams::json->>'dvQueryText';

		v_value =  rec.inputparams::json->>'value';

		IF v_querytext IS NOT NULL THEN

			IF v_querytext ilike '%$userNodetype%' THEN
				v_querytext_mod = REPLACE (v_querytext::text, '$userNodetype', quote_literal(v_nodetype));
			ELSE
				v_querytext_mod = v_querytext;
			END IF;

			v_selectedid = rec.inputparams::json->>'selectedId';

			v_querytext = concat('SELECT array_agg(id::text) FROM (',v_querytext_mod,')a');
			v_debug_vars := json_build_object('v_querytext_mod', v_querytext_mod);
			v_debug := json_build_object('querystring', v_querytext, 'vars', v_debug_vars, 'funcname', 'gw_fct_gettoolbox', 'flag', 60);
			SELECT gw_fct_debugsql(v_debug) INTO v_msgerr;

			EXECUTE v_querytext INTO v_arrayresult;
			RAISE NOTICE 'v_arrayresult: %', v_arrayresult;
			RAISE NOTICE 'inputparams: %', rec.inputparams;
			IF (rec.inputparams::json->>'isNullValue')::boolean IS TRUE THEN
				RAISE NOTICE 'isNullValue: %', rec.inputparams::json->>'isNullValue';
				v_arrayresult = array_prepend('',v_arrayresult);
			END IF;
			RAISE NOTICE 'v_arrayresult: %', v_arrayresult;
			IF v_selectedid ~ '^[0-9]+$'THEN

				v_selectedid = concat('{"selectedId":"',v_arrayresult[v_selectedid::integer],'"}');

			ELSIF v_selectedid ilike '$user%' then

				IF v_selectedid = '$userExploitation' THEN
					v_selectedid = concat('{"selectedId":"',v_expl,'"}');
				ELSIF v_selectedid = '$userMincut' THEN
					v_selectedid = concat('{"selectedId":"',v_mincut,'"}');
				ELSIF v_selectedid = '$userState' THEN
					v_selectedid = concat('{"selectedId":"',v_state,'"}');
				ELSIF v_selectedid = '$userSector' THEN
					v_selectedid = concat('{"selectedId":"',v_sector,'"}');
				ELSIF v_selectedid = '$userHydrology' THEN
					v_selectedid = concat('{"selectedId":"',v_inp_hydrology,'"}');
				ELSIF v_selectedid = '$userDwf' THEN
					v_selectedid = concat('{"selectedId":"',v_inp_dwf,'"}');
				ELSIF v_selectedid = '$userDscenario' THEN
					v_selectedid = concat('{"selectedId":"',v_inp_dscenario,'"}');
				ELSIF v_selectedid = '$userInpResult' THEN
					v_selectedid = concat('{"selectedId":"',v_inp_result,'"}');
				ELSIF v_selectedid = '$userRptResult' THEN
					v_selectedid = concat('{"selectedId":"',v_rpt_result,'"}');
				ELSIF v_selectedid = '$userNodetype' THEN
					v_selectedid = concat('{"selectedId":"',v_nodetype,'"}');
				ELSIF v_selectedid = '$userNodecat' THEN
					IF v_nodecat = any(v_arrayresult) THEN
						v_selectedid = concat('{"selectedId":"',v_nodecat,'"}');
					ELSE
						v_selectedid = concat('{"selectedId":"',v_arrayresult[1],'"}');
					END IF;
				END IF;
			END IF;

			IF v_selectedid IS NULL OR  v_selectedid = '' THEN v_selectedid = '{"selectedId":""}';END IF;

			v_rec_replace := ((rec.inputparams::jsonb) #- '{selectedId}') || (v_selectedid::jsonb);

			v_fields = (REPLACE(v_fields::text::text,  rec.inputparams::text , v_rec_replace::text))::json;

			EXECUTE v_querytext INTO v_queryresult;

			IF v_queryresult IS NOT NULL THEN
				v_querytext = concat(
					'SELECT json_build_object(',
					'''comboIds'', array_agg(id::text), ',
					'''comboNames'', array_agg(idval::text)',
					') FROM (', v_querytext_mod, ')a'
				);
				EXECUTE v_querytext INTO v_queryresult;
			ELSE
				v_queryresult = '{"comboIds":[], "comboNames":[]}';
			END IF;

			-- Remove dvQueryText and merge with v_queryresult
			rec.inputparams := ((rec.inputparams::jsonb) #- '{selectedId}') || (v_selectedid::jsonb);
			v_rec_replace := ((rec.inputparams::jsonb) #- '{dvQueryText}') || (v_queryresult::jsonb);
			v_fields = (REPLACE(v_fields::text::text,  rec.inputparams::text , v_rec_replace::text))::json;

		ELSIF v_value ilike '$user%' THEN
			IF v_value = '$userExploitation' THEN
				v_value = concat('"value":"',v_expl,'"');
			ELSIF v_value = '$userState' THEN
				v_value = concat('"value":"',v_state,'"');
			ELSIF v_value = '$userInpResult' THEN
				v_value = concat('"value":"',v_inp_result,'"');
			END IF;

			v_rec_replace = (REPLACE(rec.inputparams::text, concat('"value":"', rec.inputparams::json->>'value','"'), v_value))::json;
			v_fields = (REPLACE(v_fields::text::text,  rec.inputparams::text , v_rec_replace::text))::json;
		    v_rec_replace := v_rec_replace::jsonb || concat('{',v_queryresult,'}')::jsonb;

		END IF;

	END LOOP;

	if json_typeof(((v_fields->>'functionparams')::json->>'featureType')::json) = 'array' and (v_fields->>'functionparams')::json->>'featureType' != '[]' then

			v_value_array := ARRAY(SELECT json_array_elements(((v_fields->>'functionparams')::json->>'featureType')::json));
			FOREACH v_value_element IN ARRAY v_value_array loop
				select array_agg(tablename) from (SELECT tablename, type FROM
				(SELECT DISTINCT(parent_layer) AS tablename, feature_type as type, 0 as c, active FROM cat_feature
   				UNION SELECT child_layer, feature_type, 2 as c, active FROM cat_feature
    			UNION
   				SELECT concat('ve_',epa_table), feature_type as type, 4 as c, active FROM sys_feature_epa_type
   				WHERE epa_table IS NOT NULL AND epa_table NOT IN ('inp_virtualvalve', 'inp_inlet')
			    UNION SELECT 've_inp_subcatchment', 'SUBCATCHMENT', 6, true as active
			    UNION SELECT 've_raingage', 'RAINGAGE', 8, true as active
				UNION SELECT 've_inp_inflows', 'NODE', 8, true as active ) t
			    WHERE type = UPPER(replace(v_value_element, '"', '')) AND active IS TRUE
				ORDER BY c, tablename) a into v_response_array;
				v_value_json = gw_fct_json_object_set_key(v_value_json, replace(v_value_element, '"', ''), v_response_array);
			end loop;
			v_fields_aux = gw_fct_json_object_set_key(((v_fields->>'functionparams')::json), 'featureType', v_value_json);
			v_fields = gw_fct_json_object_set_key(v_fields, 'functionparams', v_fields_aux);
	end if;

	v_process := COALESCE(v_process, '[]');

	-- make return
	v_return ='{"status":"Accepted", "message":{"level":1, "text":"Process done successfully"}, "version":"'||v_version||'","body":{"form":{}'||
		     ',"feature":{}'||
		     ',"data":'|| v_fields ||'}}';

	RETURN v_return;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_errcontext = pg_exception_context;
	RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM,  'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'version', v_version, 'SQLSTATE', SQLSTATE, 'MSGERR', (v_msgerr::json ->> 'MSGERR'))::json;

END;
$function$
;

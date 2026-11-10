/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2748

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_manage_visit_view(p_data json)
  RETURNS void AS
$BODY$


DECLARE

v_schemaname text;
v_project_type text;
v_feature_class text;
v_class_id integer;
v_om_visit_x_feature_fields text;
v_om_visit_fields text;
v_new_parameters record;
v_viewname text;
v_definition text;
v_old_a_param text;
v_old_ct_param text;
v_old_id_param text;
v_old_datatype text;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

 	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get input parameters
	v_schemaname = (p_data ->> 'schema');
	v_class_id = ((p_data ->> 'body')::json->>'class_id')::text;
	v_old_a_param = ((p_data ->> 'body')::json->>'old_a_param')::text;
	v_old_ct_param = ((p_data ->> 'body')::json->>'old_ct_param')::text;
	v_old_id_param = ((p_data ->> 'body')::json->>'old_id_param')::text;
	v_old_datatype = ((p_data ->> 'body')::json->>'old_datatype')::text;
	v_feature_class = ((p_data ->> 'body')::json->>'feature_class')::text;
	v_viewname = ((p_data ->> 'body')::json->>'viewname')::text;

	v_old_a_param = replace (v_old_a_param,',',E',\n    ');
	v_old_ct_param = replace (v_old_ct_param,',',E',\n            ');

	--capture new parameters related to the class
	SELECT string_agg(concat('a.',config_visit_parameter.id),E',\n    ' order by config_visit_parameter.id) as a_param,
	string_agg(concat('ct.',config_visit_parameter.id),E',\n            ' order by config_visit_parameter.id) as ct_param,
	string_agg(concat('(''''',config_visit_parameter.id,''''')'),',' order by config_visit_parameter.id) as id_param,
	string_agg(concat(config_visit_parameter.id,' ', lower(config_visit_parameter.data_type)),', ' order by config_visit_parameter.id) as datatype
	INTO v_new_parameters
	FROM config_visit_parameter JOIN config_visit_class_x_parameter ON config_visit_parameter.id=config_visit_class_x_parameter.parameter_id
	WHERE class_id=v_class_id AND config_visit_parameter.active IS TRUE AND config_visit_class_x_parameter.active IS TRUE;

	IF (SELECT EXISTS ( SELECT 1 FROM information_schema.tables WHERE  table_schema = v_schemaname AND table_name = v_viewname)) IS FALSE THEN
		-- create a new view if doesn't exist
	EXECUTE 'SELECT DISTINCT string_agg(concat(''om_visit_x_'||v_feature_class||'.'',column_name)::text,'', '')
		FROM information_schema.columns where table_name=''om_visit_x_'||v_feature_class||''' and table_schema='''||v_schemaname||''' 
		and column_name NOT IN (''is_last'', ''id'')'
		INTO v_om_visit_x_feature_fields;

		EXECUTE 'SELECT DISTINCT string_agg(concat(''om_visit.'',column_name)::text,'', '')
		FROM information_schema.columns where table_name=''om_visit'' and table_schema='''||v_schemaname||''' and column_name!=''publish'' and column_name NOT IN (''id'', ''vehicle_id'', ''unit_id'', ''visit_type'')'
		INTO v_om_visit_fields;

		EXECUTE 'CREATE OR REPLACE VIEW '||v_schemaname||'.'||lower(v_viewname)||' AS
			SELECT '||v_om_visit_x_feature_fields||',
            '||v_feature_class||'.code,
			'||v_om_visit_fields||',
			'||v_new_parameters.a_param||'
			FROM om_visit
			JOIN config_visit_class ON config_visit_class.id = om_visit.class_id
			JOIN om_visit_x_'||v_feature_class||' ON om_visit.id = om_visit_x_'||v_feature_class||'.visit_id
			JOIN '||v_feature_class||' ON '||v_feature_class||'.'||v_feature_class||'_id::text = om_visit_x_'||v_feature_class||'.'||v_feature_class||'_id::text
			LEFT JOIN ( SELECT ct.visit_id,
		    '||v_new_parameters.ct_param||'
			    FROM crosstab(''SELECT visit_id, om_visit_event.parameter_id, value 
			    FROM '||v_schemaname||'.om_visit JOIN '||v_schemaname||'.om_visit_event ON om_visit.id=om_visit_event.visit_id 
			    LEFT JOIN '||v_schemaname||'.config_visit_class on config_visit_class.id=om_visit.class_id
			    WHERE config_visit_class.ismultievent = TRUE AND config_visit_class.id='||v_class_id||'
			    ORDER  BY 1,2''::text, '' VALUES '||v_new_parameters.id_param||'''::text) 
			    ct(visit_id integer, '||v_new_parameters.datatype||')) a ON a.visit_id = om_visit.id
				WHERE config_visit_class.ismultievent = true AND config_visit_class.id='||v_class_id||';';

	ELSE
		-- replace values of an existing view

		--capture the definition of the view
		EXECUTE'SELECT pg_get_viewdef('''||v_schemaname||'.'||v_viewname||''', true);'
		INTO v_definition;

		--replace old parameters in the view definition with the new ones
		v_definition = replace(v_definition,v_old_ct_param,v_new_parameters.ct_param);
		v_definition = replace(v_definition,v_old_a_param,v_new_parameters.a_param);
		v_definition = replace(v_definition,v_old_id_param,v_new_parameters.id_param);
		v_definition = replace(v_definition,v_old_datatype,v_new_parameters.datatype);

		--replace the existing view and create the trigger

		EXECUTE 'DROP VIEW '||v_schemaname||'.'||v_viewname||';';
		EXECUTE 'CREATE OR REPLACE VIEW '||v_schemaname||'.'||v_viewname||' AS '||v_definition||';';

	END IF;

	--create trigger on view
	EXECUTE 'DROP TRIGGER IF EXISTS gw_trg_om_visit_multievent ON '||v_schemaname||'.'||v_viewname||';';

	EXECUTE 'CREATE TRIGGER gw_trg_om_visit_multievent
	INSTEAD OF INSERT OR UPDATE OR DELETE ON '||v_schemaname||'.'||v_viewname||'
	FOR EACH ROW EXECUTE PROCEDURE '||v_schemaname||'.gw_trg_om_visit_multievent('||v_class_id||');';

	RETURN;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
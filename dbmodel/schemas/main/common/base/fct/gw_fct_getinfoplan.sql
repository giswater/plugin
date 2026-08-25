/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2586

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getinfoplan(p_data json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getinfoplan(p_data json)
  RETURNS json AS
$BODY$
/* EXAMPLE
SELECT SCHEMA_NAME.gw_fct_getinfoplan($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{"tabName":"plan"},
"feature":{"featureType":"arc", "tableName":"ve_arc_pipe", "idName":"arc_id", "id":"113854"},
"data":{}}$$)

SELECT SCHEMA_NAME.gw_fct_getinfoplan($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{"formName":"", "tabName":"plan"},
"feature":{"featureType":"node", "tableName":"ve_node_junction", "idName":"node_id", "id":"1001"},
"data":{}}$$)
*/

DECLARE

fields_array json[];
formTabs text;
combo_json json;
v_version text;
aux_json json;
fields json;
count integer := 1;
v_cost text;
v_dim text;
v_currency varchar;
v_tabname varchar = 'plan';
v_tablename varchar;
v_device integer;
v_totalcost text;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	--  get system currency
	v_currency :=(SELECT value::json->>'symbol' FROM v_config_param_system WHERE parameter='admin_currency');

	-- Create tabs array
	formTabs := '[';

	-- Info plan
	-- get tablename
	IF ((p_data ->>'feature')::json->>'featureType')::text='arc' THEN
	      v_tablename := 'v_ui_plan_arc_cost';
	ELSIF ((p_data ->>'feature')::json->>'featureType')::text='node' THEN
		v_tablename := 'v_ui_plan_node_cost';
	END IF;

	-- get parameters
	 v_device := ((p_data ->>'client')::json->>'device')::integer;

	-- get fields
	SELECT gw_fct_getformfields('infoplan', 'form_generic', v_tabname, v_tablename, ((p_data ->>'feature')::json->>'idName'), ((p_data ->>'feature')::json->>'id'), null, null,null, v_device, null)
		INTO fields_array;

	-- Add resumen values
	FOREACH aux_json IN ARRAY fields_array
	LOOP
		IF (aux_json->>'columnname')  = 'initial_cost' THEN

			IF ((p_data ->>'feature')::json->>'featureType')::text='arc' THEN
			      v_cost := (SELECT concat(gw_fct_set_currency_config(sum(total_cost)::numeric(12,2)), '/ml') 
				FROM v_ui_plan_arc_cost WHERE arc_id = ((p_data ->>'feature')::json->>'id')::integer);
			ELSIF ((p_data ->>'feature')::json->>'featureType')::text='node' THEN
				v_cost := (SELECT concat(gw_fct_set_currency_config(sum(total_cost)::numeric(12,2)), '/ut') 
				FROM v_ui_plan_node_cost WHERE node_id = ((p_data ->>'feature')::json->>'id')::integer);
			END IF;

			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'value', v_cost::TEXT);

		ELSIF (aux_json->>'columnname')  = 'length' THEN

			IF ((p_data ->>'feature')::json->>'featureType')::text='arc' THEN
			      v_dim := (SELECT concat(st_length(the_geom)::numeric(12,2),' ml') FROM arc WHERE arc_id = ((p_data ->>'feature')::json->>'id')::integer);
			ELSIF ((p_data ->>'feature')::json->>'featureType')::text='node' THEN
				v_dim := '1.00 ut';
			END IF;

			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'label', 'Units'::TEXT);
			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'value', v_dim::TEXT);

		ELSIF (aux_json->>'columnname')  = 'total_cost' THEN

			IF ((p_data ->>'feature')::json->>'featureType')::text='arc' THEN
			      v_totalcost := (SELECT gw_fct_set_currency_config(sum(total_cost*st_length(the_geom))::numeric(12,2))
				FROM v_ui_plan_arc_cost JOIN arc USING (arc_id) WHERE arc_id = ((p_data ->>'feature')::json->>'id')::integer);
			ELSIF ((p_data ->>'feature')::json->>'featureType')::text='node' THEN
				v_totalcost := (SELECT gw_fct_set_currency_config(sum(total_cost)::numeric(12,2))
				FROM v_ui_plan_node_cost WHERE node_id = ((p_data ->>'feature')::json->>'id')::integer);
			END IF;

			fields_array[(aux_json->>'orderby')::INT] := gw_fct_json_object_set_key(fields_array[(aux_json->>'orderby')::INT], 'value', v_totalcost::TEXT);

		END IF;

	END LOOP;

	-- Convert to json
	fields := array_to_json(fields_array);

	--fields := ('{"fields":' || fields || '}')::json;
	formTabs := formTabs || fields::text;

	-- Finish the construction of formtabs
	formTabs := formtabs ||']';

	--  Check null
	formTabs := COALESCE(formTabs, '[]');

	-- Return
    RETURN ('{"status":"Accepted", "version":"'||v_version||'"'||
             ',"body":{"message":{}'||
			',"form":'||(p_data ->>'form')||
			',"feature":'||(p_data ->>'feature')||
			',"data":{"fields":' || fields ||
				'}}'||
	    '}')::json;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE)::json;


END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

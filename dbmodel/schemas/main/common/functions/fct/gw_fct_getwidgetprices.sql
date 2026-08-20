/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


-- Function code: 3128

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getwidgetprices(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_getwidgetprices($${"client":{}, "form":{}, "feature":{},"data":{"tableName":"ve_plan_psector_x_other", "psectorId":8}}$$)::text

*/

DECLARE

v_schemaname text;
v_version text;
v_definition text;
v_columns json;
v_columns_array json[];
v_fields json;
v_fields_array json[];
v_tablename text;
v_psector_id text;
v_currency text;
v_error_context text;
v_total_other text;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	-- Get API version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Getting variables
	v_tablename = (p_data->>'data')::json->>'tableName';
	v_psector_id = (p_data->>'data')::json->>'psectorId';
	v_currency :=(SELECT value::json->>'symbol' FROM v_config_param_system WHERE parameter='admin_currency');

	-- Get table columns
	EXECUTE 'SELECT array_agg(row_to_json(a)) FROM (SELECT column_name FROM information_schema.columns 
	WHERE table_schema = $1 AND table_name = $2 AND column_name NOT IN (''atlas_id'', ''id'', ''psector_id''))a '
	INTO v_columns_array
	USING v_schemaname, v_tablename;

	-- Get table rows with formatted currency
	EXECUTE 'SELECT array_agg(row_to_json(a)) FROM (
		SELECT id, price_id, unit, price_descript, 
		gw_fct_set_currency_config(price::numeric(12,2)) as price,
		measurement, observ, 
		gw_fct_set_currency_config(total_budget::numeric(12,2)) as total 
		FROM '||v_tablename||' WHERE psector_id = '||v_psector_id||'
	)a '
	INTO v_fields_array;

	EXECUTE 'SELECT to_json(gw_fct_set_currency_config(SUM(total_budget))) as total_other
		FROM '||v_tablename||' WHERE psector_id = '||v_psector_id
	INTO v_total_other;

	v_columns := array_to_json(v_columns_array);
	v_fields := array_to_json(v_fields_array);

	-- Control nulls
	v_version := COALESCE(v_version, '');
	v_columns := COALESCE(v_columns, '{}');
	v_fields := COALESCE(v_fields, '{}');
	v_total_other := COALESCE(v_total_other, concat('"0 ', v_currency, '"'));

	-- Return
	RETURN ('{"status":"Accepted"' ||', "version":"'|| v_version ||'"'||
		/*', "columns":' || v_columns ||*/
		/*', "layoutname":"price_layout"'||||*/
		', "fields":' || v_fields ||
		', "total_other":' || v_total_other ||
		'}')::json;

	-- Exception handling
    EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
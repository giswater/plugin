/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2700

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_manage_fields();
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_manage_fields(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_manage_fields(p_data json) RETURNS text AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"arc", "column":"addvalue", "dataType":"varchar(16)", "isUtils":"True"}}$$)
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"arc", "column":"active", "dataType":"bool", "defaultValue":"true"}}$$)
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"RENAME","table":"arc", "column":"addvalue", "newName":"_addvalue_"}}$$)
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"DROP","table":"arc", "column":"addvalue"}}$$)
SELECT SCHEMA_NAME.gw_fct_admin_manage_fields($${"data":{"action":"CHANGETYPE","table":"arc", "column":"addvalue", "dataType":"varchar(16)}}$$)

*/

DECLARE

	v_schemaname varchar = 'SCHEMA_NAME';
	v_target_schemaname varchar;
	v_table text;
	v_target_table text;
	v_action text;

	v_column text;
	v_datatype text;
	v_defaultvalue text;
	v_isutils boolean;
	v_iscibs boolean;
	v_newname text;
	v_querytext text;


BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;

	v_action = (p_data->>'data')::json->>'action';
	v_table = (p_data->>'data')::json->>'table';
	v_column = (p_data->>'data')::json->>'column';
	v_datatype = (p_data->>'data')::json->>'dataType';
	v_defaultvalue = (p_data->>'data')::json->>'defaultValue';
	v_isutils = (p_data->>'data')::json->>'isUtils';
	v_iscibs = (p_data->>'data')::json->>'iscibs';
	v_newname = (p_data->>'data')::json->>'newName';



	-- Determine the target schema and table
	IF v_isutils IS TRUE AND (SELECT value::boolean FROM config_param_system WHERE parameter='admin_utils_schema') IS TRUE THEN
		v_target_schemaname := 'utils';
		v_target_table := replace(v_table, 'ext_', '');
	ELSIF v_iscibs IS TRUE AND (SELECT value::boolean FROM config_param_system WHERE parameter='admin_cibs_schema') IS TRUE THEN
		v_target_schemaname := 'cibs';
		v_target_table := replace(v_table, 'ext_', '');
	ELSE
		v_target_schemaname := v_schemaname;
		v_target_table := v_table;
	END IF;

	-- Check if the column does not exist in the target schema and table
	IF v_action = 'ADD' AND NOT EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_schema = v_target_schemaname
		AND table_name = v_target_table
		AND column_name = v_column
	) THEN
		v_querytext := 'ALTER TABLE ' || quote_ident(v_target_schemaname) || '.' || quote_ident(v_target_table)
					 || ' ADD COLUMN ' || quote_ident(v_column) || ' ' || v_datatype
					 || CASE WHEN v_defaultvalue IS NOT NULL THEN ' DEFAULT ' || quote_literal(v_defaultvalue) ELSE '' END;
		EXECUTE v_querytext;

	ELSIF v_action='RENAME' AND (SELECT column_name FROM information_schema.columns WHERE table_schema=v_target_schemaname and table_name = v_target_table AND column_name = v_column) IS NOT NULL
				AND (SELECT column_name FROM information_schema.columns WHERE table_schema=v_target_schemaname and table_name = v_target_table AND column_name = v_newname) IS NULL THEN

		v_querytext = 'ALTER TABLE '|| quote_ident(v_target_schemaname) || '.' || quote_ident(v_target_table) ||' RENAME COLUMN '||quote_ident(v_column)||' TO '||quote_ident(v_newname);
		EXECUTE v_querytext;

	ELSIF v_action='DROP' AND (SELECT column_name FROM information_schema.columns WHERE table_schema=v_target_schemaname and table_name = v_target_table AND column_name = v_column) IS NOT NULL THEN

		v_querytext = 'ALTER TABLE '|| quote_ident(v_target_schemaname) || '.' || quote_ident(v_target_table) ||' DROP COLUMN '||quote_ident(v_column);
		EXECUTE v_querytext;

	ELSIF v_action='CHANGETYPE' AND (SELECT column_name FROM information_schema.columns
		WHERE table_schema=v_target_schemaname and table_name = v_target_table AND column_name = v_column AND data_type!=v_datatype) IS NOT NULL THEN

		IF v_datatype ILIKE '%int4[]%' OR v_datatype ILIKE '%integer[]%'  OR v_datatype ILIKE '%int8[]%' OR v_datatype ILIKE '%bigint[]%'THEN
			v_querytext = 'ALTER TABLE '|| quote_ident(v_target_schemaname) || '.' || quote_ident(v_target_table) ||' ALTER COLUMN '||quote_ident(v_column)||' TYPE '||v_datatype||' USING ARRAY['||quote_ident(v_column)||']';
		ELSE
			v_querytext = 'ALTER TABLE '|| quote_ident(v_target_schemaname) || '.' || quote_ident(v_target_table) ||' ALTER COLUMN '||quote_ident(v_column)||' TYPE '||v_datatype||' USING '||quote_ident(v_column)||'::'||v_datatype;
		END IF;

		EXECUTE v_querytext;

	ELSE
		v_querytext = 'Process not executed. Table has already been modified.';
	END IF;


	RETURN v_querytext;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

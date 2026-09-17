/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2558

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getfeatureinfo(character varying, character varying, integer, integer, boolean);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getfeatureinfo(character varying, character varying, integer, integer, boolean, text, text, text);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getfeatureinfo(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getfeatureinfo(p_data json)
  RETURNS json AS
$BODY$

/* EXAMPLE

SELECT SCHEMA_NAME.gw_fct_getfeatureinfo($${
	"data":{
		"parameters":{
			"table_id":"ve_arc_pipe",
			"id":"2001",
			"device":3,
			"info_type":100,
			"configtable":false
		}
	}
}$$);

*/

DECLARE

-- parameters
v_table_id text;
v_id text;
v_device integer;
v_infotype integer;
v_configtable boolean;
v_idname text;
v_columntype text;
v_tgop text;

fields json;
fields_array json[];
aux_json json;
schemas_array name[];
array_index integer DEFAULT 0;
field_value character varying;
v_version text;
v_values_array json;
v_formtype text;
v_tabname text = 'tab_data';
v_errcontext text;
v_querystring text;
v_msgerr json;

vdefault_querytext text;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Get schema name
	schemas_array := current_schemas(FALSE);

	-- parameters
	v_table_id = (((p_data->>'data')::json->>'parameters')::json->>'table_id');
	v_id = (((p_data->>'data')::json->>'parameters')::json->>'id');
	v_device = (((p_data->>'data')::json->>'parameters')::json->>'device');
	v_infotype = (((p_data->>'data')::json->>'parameters')::json->>'info_type');
	v_configtable = (((p_data->>'data')::json->>'parameters')::json->>'configtable');
	v_idname = (((p_data->>'data')::json->>'parameters')::json->>'idname');
	v_columntype = (((p_data->>'data')::json->>'parameters')::json->>'columntype');
	v_tgop = (((p_data->>'data')::json->>'parameters')::json->>'tgop');

	-- getting values from feature
	if v_id is not null then
        v_querystring = concat('SELECT (row_to_json(a)) FROM (SELECT * FROM ',quote_ident(v_table_id),' WHERE ',quote_ident(v_idname),' = CAST(',quote_nullable(v_id),' AS ',(v_columntype),'))a');
        EXECUTE v_querystring INTO v_values_array;
    end if;
	IF  v_configtable THEN

		raise notice 'Configuration fields are defined on config_info_layer_field, calling gw_fct_getformfields with formname: % tablename: % id %', v_table_id, v_table_id, v_id;

		-- Call the function of feature fields generation
		v_formtype = 'form_feature';
		SELECT gw_fct_getformfields( v_table_id, v_formtype, 'tab_data', v_table_id, v_idname, v_id, null, 'SELECT',null, v_device, v_values_array) INTO fields_array;
	ELSE
		raise notice 'Configuration fields are NOT defined on config_info_layer_field. System values will be used';

		IF v_id IS NULL THEN
			RETURN '{}'; -- returning null for those layers are not configured and id is null (first call on load project)

		ELSE
			-- Get fields
			v_querystring = concat('SELECT array_agg(row_to_json(a)) FROM 
				(SELECT a.attname as label, 
				concat(',quote_literal(v_tabname),',''_'',a.attname) AS widgetname,
				',quote_literal(v_tabname),' AS tabname,
				a.attname AS columnname,			   
				(case when a.atttypid=16 then ''check'' else ''text'' end ) as widgettype, 
				(case when a.atttypid=16 then ''boolean'' else ''string'' end ) as "datatype", 
				false AS iseditable,
				row_number()over() AS orderby, 
				null as stylesheet, 
				row_number()over() AS layoutorder,
				row_number()over() AS web_layoutorder,
				FALSE AS isparent, 
				null AS widgetfunction, 
				null AS linkedaction, 
				FALSE AS isautoupdate,
				''lyt_data_1'' AS layoutname, 
				null as widgetcontrols,
				FALSE as hidden
				FROM pg_attribute a
				JOIN pg_class t on a.attrelid = t.oid
				JOIN pg_namespace s on t.relnamespace = s.oid
				WHERE a.attnum > 0 
				AND NOT a.attisdropped
				AND t.relname = ',quote_nullable(v_table_id),' 
				AND s.nspname = ',quote_nullable(schemas_array[1]),'
				AND a.attname !=''the_geom''
				AND a.attname !=''geom''
				ORDER BY a.attnum) a');

			EXECUTE v_querystring INTO fields_array;
		END IF;
	END IF;

	IF v_tgop !='LAYER' THEN

		-- Fill every value
		FOREACH aux_json IN ARRAY fields_array
		LOOP
			array_index := array_index + 1;
			field_value := (v_values_array->>(aux_json->>'columnname'));
			field_value := COALESCE(field_value, '');

			-- Update array
			IF (aux_json->>'widgettype')='combo' OR (aux_json->>'widgettype')='multiple_checkbox' THEN

				-- Set default value if exist when inserting and feild_value is null
				IF p_tg_op ='INSERT' AND (field_value IS NULL OR field_value = '') THEN
					IF (aux_json->>'widgetcontrols') IS NOT NULL THEN
						IF ((aux_json->>'widgetcontrols')::jsonb ? 'vdefault_value') THEN
							IF (aux_json->>'widgetcontrols')::json->>'vdefault_value'::text in  (select a from json_array_elements_text(json_extract_path(v_fields_array[array_index],'comboIds'))a) THEN
								field_value = (aux_json->>'widgetcontrols')::json->>'vdefault_value';
							END IF;
						ELSEIF ((aux_json->>'widgetcontrols')::jsonb ? 'vdefault_querytext') THEN
							EXECUTE aux_json->>'widgetcontrols'::json->'vdefault_querytext'::text INTO vdefault_querytext;
							IF vdefault_querytext in  (select a from json_array_elements_text(json_extract_path(v_fields_array[array_index],'comboIds'))a) THEN
								field_value = vdefault_querytext;
							END iF;
						END IF;
					END IF;
				END IF;
				fields_array[array_index] := gw_fct_json_object_set_key(fields_array[array_index], 'selectedId', field_value);
			ELSIF (aux_json->>'widgettype') !='button' THEN

				-- Set default value if exist when inserting and feild_value is null
				IF p_tg_op ='INSERT' AND (field_value IS NULL OR field_value='') THEN
					IF (aux_json->>'widgetcontrols') IS NOT NULL THEN
						IF ((aux_json->>'widgetcontrols')::jsonb ? 'vdefault_value') THEN
							field_value = (aux_json->>'widgetcontrols')::json->>'vdefault_value';
						ELSEIF ((aux_json->>'widgetcontrols')::jsonb ? 'vdefault_querytext') THEN
							EXECUTE (aux_json->>'widgetcontrols')::json->>'vdefault_querytext' INTO field_value;
						END IF;
					END IF;
				END IF;
				fields_array[array_index] := gw_fct_json_object_set_key(fields_array[array_index], 'value', field_value);
			END IF;
		END LOOP;

	END IF;

	-- Convert to json
	fields := array_to_json(fields_array);

	-- Control NULL's
	fields := COALESCE(fields, '[]');

	-- Return
	RETURN  fields;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
--FUNCTION CODE: 3220


-- DROP FUNCTION SCHEMA_NAME.gw_fct_getstyle(json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getstyle(p_data json)
  RETURNS json AS
$BODY$

/*

	SELECT SCHEMA_NAME.gw_fct_getstyle($${"data":{"layername":"ve_arc"}}$$);
	SELECT SCHEMA_NAME.gw_fct_getstyle($${"data":{"layername":"point", "style_id":"103"}}$$);

*/

DECLARE
v_return json;
v_layername text;
v_style_id text;
v_styles json;
v_version text;
v_error_context text;
v_style_vdef int;


BEGIN

	-- Search path
	SET search_path = 'SCHEMA_NAME', public;

	-- Get input variables
	v_layername = (p_data -> 'data' ->> 'layername')::text;
	v_style_id = (p_data -> 'data' ->> 'style_id')::text;

	-- Get version
	SELECT giswater FROM sys_version ORDER BY id DESC LIMIT 1 INTO v_version;

	-- Get systemvalues
	SELECT ((value::json)->>'styleconfig_vdef') INTO v_style_vdef FROM config_param_system WHERE parameter='qgis_layers_symbology';

	-- Determine the style to use
	IF v_style_id IS NOT NULL THEN
		-- If style_id is provided, use it to get the style
		v_styles := jsonb_object_agg(idval::text, stylevalue) FROM (
			SELECT c.idval, stylevalue
			FROM v_sys_style s
			JOIN config_style c ON s.styleconfig_id = c.id
			WHERE s.layername = v_layername
			  AND c.id = v_style_id::int
			  AND s.active IS TRUE
		) sub;
	ELSE
		-- If no style_id, use the default style
		v_styles := jsonb_object_agg(idval::text, stylevalue) FROM (
			SELECT c.idval, stylevalue
			FROM v_sys_style s
			JOIN config_style c ON s.styleconfig_id = c.id
			WHERE s.layername = v_layername
			  AND c.id = v_style_vdef
			  AND s.active IS TRUE
		) sub;
	END IF;

	-- If the default style doesn't match, get the 101 (GwBasic)
	IF v_styles IS NULL THEN
		v_styles := jsonb_object_agg(idval::text, stylevalue) FROM (
			SELECT c.idval, stylevalue
			FROM v_sys_style s
			JOIN config_style c ON s.styleconfig_id = c.id
			WHERE s.layername = v_layername AND c.id=101 AND s.active IS TRUE
		) sub;
	END IF;

	-- If still null, return an empty JSON object
	IF v_styles IS NULL THEN
		v_styles := '{}'::jsonb;
	END IF;

	-- Ensure version and return JSON are initialized
	v_version := COALESCE(v_version, '');
	v_styles := COALESCE(v_styles, '{}');

	-- Return the final JSON structure
	v_return = ('{"status":"Accepted", "message":{"level":1, "text":"Executed successfully"}, "version":"'||v_version||'"'||
		',"body":{"form":{}'||
		',"data":{}'||
		',"styles":'||v_styles||''||
	'}}')::json;
	RETURN v_return;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
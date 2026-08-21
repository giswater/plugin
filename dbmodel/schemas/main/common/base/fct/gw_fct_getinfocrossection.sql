/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2578

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_getinfocrossection(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getinfocrossection(p_data json)
  RETURNS json AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_getinfocrossection($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"feature":{"id":"2001"}}$$)
*/

DECLARE

v_id integer;
v_version text;
v_fields json;
v_currency_symbol varchar;
v_shape varchar;
v_record record;
v_array json[];

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- getting input data
	v_id :=  ((p_data ->>'feature')::json->>'id')::integer;

	--  get system currency
	v_currency_symbol :=((SELECT value FROM v_config_param_system WHERE parameter='admin_currency')::json->>'symbol');

	-- get image
   	SELECT image FROM cat_arc_shape JOIN cat_arc ON cat_arc.shape=cat_arc_shape.id	JOIN arc ON cat_arc.id=arccat_id WHERE arc_id=v_id
		INTO v_shape;

	-- get values from arc
	SELECT * INTO v_record FROM v_plan_arc WHERE arc_id = v_id;

	-- building the widgets array
    v_array[0] := json_build_object('label', 'm2mlpav', 'columnname', 'm2mlpav', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.m2mlpav);
    v_array[1] := json_build_object('label', 'thickness', 'columnname', 'thickness', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.thickness);
    v_array[2] := json_build_object('label', 'bulk', 'columnname', 'bulk', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.bulk);
	v_array[3] := json_build_object('label', 'y_param', 'columnname', 'y_param', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.y_param);
	v_array[4] := json_build_object('label', 'Crossection area:', 'columnname', 'area', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.area);
	v_array[5] := json_build_object('label', 'm3/ml Excav', 'columnname', 'm3mlexc', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.m3mlexc);
	v_array[6] := json_build_object('label', 'm3/ml Filling', 'columnname', 'm3mlfill', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.m3mlfill);
	v_array[7] := json_build_object('label', 'm3/ml Excess', 'columnname', 'm3mlexcess', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.m3mlexcess);
	v_array[8] := json_build_object('label', '% Trenchlining', 'columnname', 'm2mltrenchl', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.m2mltrenchl);
	v_array[9] := json_build_object('columnname', 'b2', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.b);
	v_array[10] := json_build_object('columnname', 'm2mlbottom', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.m2mlbottom);
	v_array[11] := json_build_object('columnname', 'width', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.width);
	v_array[12] := json_build_object('columnname', 'b1', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.b);
	v_array[13] := json_build_object('columnname', 'm2mlpav', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.m2mlpav);
	v_array[14] := json_build_object('columnname', 'z1', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.z1);
	v_array[15] := json_build_object('columnname', 'geom1', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.geom1);
	v_array[16] := json_build_object('columnname', 'z2', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.z2);
	v_array[17] := json_build_object('columnname', 'total_y', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.total_y);
	v_array[18] := json_build_object('columnname', 'rec_y', 'widgettype', 'text', 'datatype', 'string', 'iseditable', FALSE, 'layoutorder', 1, 'value', v_record.rec_y);

	v_fields = array_to_json(v_array[0:18]);

	-- Check null
	v_shape := COALESCE(v_shape, '[]');
	v_fields := COALESCE(v_fields, '[]');

	-- Return
	RETURN ('{"status":"Accepted", "message":{}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
		     ',"feature":{}'||
		     ',"data":{"shapepng":"' || v_shape ||'"'||
			     ',"fields":' || v_fields || '}}'||
	    '}')::json;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('status', 'Failed','NOSQLERR', SQLERRM, 'version', v_version, 'SQLSTATE', SQLSTATE)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
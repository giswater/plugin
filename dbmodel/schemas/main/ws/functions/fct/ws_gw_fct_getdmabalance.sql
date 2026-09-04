/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
--FUNCTION CODE: 3196

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_getdmabalance(p_data json) RETURNS json AS 
$BODY$
/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_getdmabalance($${"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"feature":{"tableName":"ve_dma", "id":"1"}, 
"data":{"filterFields":{}, "pageInfo":{}, "selectionMode":"wholeSelection",
"parameters":{},"coordinates":{"xcoord":419254.77166562714,"ycoord":4576827.482150269, "zoomRatio":449.27899973010625}}}$$)::JSON


*/

DECLARE

v_result json;
v_result_info json;
v_result_line json;
v_version text;
v_error_context text;
v_dmaid integer;
v_dmaname text;
v_explname text;
v_period_list text;

v_point public.geometry;
v_xcoord double precision;
v_ycoord double precision;
v_epsg integer;
v_zoomratio double precision; 
v_client_epsg integer;


BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- SELECT giswater
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;
		
	-- getting input data 	
	v_dmaid :=  ((p_data ->>'feature')::json->>'id')::json;
	v_xcoord := ((p_data ->> 'data')::json->> 'coordinates')::json->>'xcoord';
	v_ycoord := ((p_data ->> 'data')::json->> 'coordinates')::json->>'ycoord';
	v_epsg := (SELECT epsg FROM sys_version ORDER BY id DESC LIMIT 1);
	v_zoomratio := ((p_data ->> 'data')::json->> 'coordinates')::json->>'zoomRatio';
	v_client_epsg := (p_data ->> 'client')::json->> 'epsg';

	IF v_client_epsg IS NULL THEN v_client_epsg = v_epsg; END IF;
	-- Make point
	SELECT ST_Transform(ST_SetSRID(ST_MakePoint(v_xcoord,v_ycoord),v_client_epsg),v_epsg) INTO v_point;

	select dma_id, name INTO v_dmaid, v_dmaname FROM dma WHERE ST_Dwithin(dma.the_geom, v_point, 0.1)  LIMIT 1;
	select e.name INTO v_explname FROM dma JOIN exploitation e USING (expl_id) WHERE dma_id = v_dmaid;

	EXECUTE 'SELECT string_agg(quote_literal(period), '','') FROM 
	(select distinct period, start_date from v_om_waterbalance where dma = '||quote_literal(v_dmaname)||' order by start_date desc limit 4)a'
	INTO v_period_list;

	EXECUTE  'WITH balance AS (SELECT jsonb_build_object('||quote_literal(v_dmaname)||', json_agg(jsonb_build_object(period, jsonb_build_object(start_date::date, dma_rw_eff::numeric(12,3))))) as chart_dma
	FROM v_om_waterbalance_report WHERE dma = '||quote_literal(v_dmaname)||' AND period IN  ('||v_period_list||') ),
	balance_expl AS (SELECT jsonb_build_object('||quote_literal(v_explname)||', json_agg(jsonb_build_object(period, jsonb_build_object(a.start_date::date,expl_rw_eff)))) as chart_expl from
	(SELECT DISTINCT  start_date::date, period, expl_rw_eff 
	FROM v_om_waterbalance_report WHERE exploitation = '||quote_literal(v_explname)||' AND  period IN  ('||v_period_list||') )a)
	SELECT jsonb_build_object(
	''info'', to_jsonb(row) ,
	''chart'', (chart_dma::jsonb ||chart_expl::jsonb ))
	FROM balance, balance_expl,
	(SELECT DISTINCT 
	exploitation, 
	dma,
	period, 
	start_date,
	concat(start_date::date,'' - '',end_date::date) as period_dates,
	meters_in,
	meters_out,
	n_connec,
	n_hydro,
	arc_length,
	link_length,
	total_in, 
	total_out, 
	total, 
	auth, 
	nrw, 
	dma_rw_eff, 
	dma_nrw_eff, 
	dma_ili, 
	dma_nightvol, 
	dma_m4day, 
	expl_rw_eff, 
	expl_nrw_eff,
	expl_nightvol, 
	expl_ili, 
	expl_m4day
	FROM v_om_waterbalance_report
	join dma using(dma_id) 
	WHERE dma_id = '||v_dmaid||' order by start_date desc limit 1) row'
	INTO v_result;

	-- info
	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"values":',v_result, '}');
		
	--    Control nulls
	v_result_info := COALESCE(v_result_info, '{}'); 
	v_result_line := COALESCE(v_result_line, '{}'); 

	--  Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
	             ',"body":{"form":{}'||
			     ',"data":{ "info":'||v_result_info||','||
					'"line":'||v_result_line||
				'}}'||
		    '}')::json, 3196, null, null, null);

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
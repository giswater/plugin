-- DROP FUNCTION SCHEMA_NAME.gw_fct_create_thyssen_subcatchments(json);

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_create_thyssen_subcatchments(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
/*

id: 3360
SELECT gw_fct_create_thyssen_subcatchments($${"client":{"device":4, "lang":"", "version":"4.4.0", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"clipLayer":"sector", "deletePrevious":"true"}, "aux_params":null}}$$);

*/

DECLARE
  v_clip text;
  v_delete_previous boolean;
  v_hyd integer;
  v_version text;
  v_srid integer;
  v_result_info text;
  v_result json;
  v_fid integer := 640;
  v_sql text;
  v_fprocessname TEXT;
  v_clip_table TEXT;
  v_error_context text;
BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- get input variables
	SELECT giswater, epsg INTO v_version, v_srid FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT "value" INTO v_hyd FROM config_param_user WHERE "parameter" = 'inp_options_hydrology_current';

	IF v_hyd IS NULL OR v_hyd NOT IN (SELECT hydrology_id FROM cat_hydrology WHERE active IS TRUE) THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4694", "function":"3360", "fid":"'||v_fid||'","criticity":"3", "parameters":{"hydrology_id":"'||v_hyd||'"}}}$$)';-- CRITICAL ERRORS
	END IF;

	v_clip := (p_data->'data'->'parameters'->>'clipLayer')::text;
	v_delete_previous := (p_data->'data'->'parameters'->>'deletePrevious')::boolean;
	v_fprocessname = (SELECT UPPER(fprocess_name) FROM sys_fprocess where fid = v_fid);

	-- Reset previous logs
	DELETE FROM anl_node WHERE cur_user="current_user"() AND fid=v_fid;
	DELETE FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid;

	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":"'||v_fid||'", "project_type":"UD", "action":"CREATE", "group":"LOG"}}}$$)';

    INSERT INTO t_audit_check_data (fid, cur_user, criticity, error_message) VALUES (v_fid, current_user, 4, v_fprocessname);
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4338", "function":"3360", "fid":"'||v_fid||'","criticity":"3", "tempTable":"t_", "cur_user":"current_user", "is_process":true, "is_header":true, "label_id":"1004"}}$$)';-- CRITICAL ERRORS
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4338", "function":"3360", "fid":"'||v_fid||'","criticity":"2", "tempTable":"t_", "cur_user":"current_user", "is_process":true, "is_header":true, "label_id":"3002"}}$$)';-- WARNINGS
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4338", "function":"3360", "fid":"'||v_fid||'","criticity":"1", "tempTable":"t_", "cur_user":"current_user", "is_process":true, "is_header":true, "label_id":"3001"}}$$)';-- INFO
	INSERT INTO t_audit_check_data (fid, cur_user, criticity, error_message) VALUES (v_fid, current_user, 4, '-------------------------------');
	INSERT INTO t_audit_check_data (fid, cur_user, criticity, error_message) VALUES (v_fid, current_user, 4, ''); 

	-- Optional cleanup
	IF v_delete_previous IS TRUE THEN
		DELETE FROM inp_subcatchment
		WHERE sector_id IN (SELECT DISTINCT sector_id FROM ve_sector);
	END IF;
	
	raise notice 'fast subc';

	IF v_clip IS NOT NULL then

		IF v_clip = 'muni' THEN
			v_clip_table = 've_municipality';
		ELSE
			v_clip_table = 've_' || lower(v_clip);
		END IF;
	
	ELSE
	
		v_clip = 'muni';
		v_clip_table = 've_municipality';
		
	END IF;

	/* ----------------------------------------------------------------------------
		FAST SUBCATCHMENTS:
		- Voronoi per municipality (smaller point sets)
		- Clip integrated via ST_VoronoiPolygons(..., extend_to := m.the_geom)
		- Avoid repeated ST_Intersection
		- Semi-join to ve_node using the chosen clip layer (no giant IN lists)
		- Assign cells to nodes with && + ST_Contains (index-friendly)
		---------------------------------------------------------------------------*/
	
		execute  '
		INSERT INTO inp_subcatchment (subc_id, outlet_id, sector_id, muni_id, hydrology_id, descript, the_geom)
		WITH mec AS MATERIALIZED (
			SELECT (st_dump(st_voronoipolygons(ST_Collect(the_geom)))).geom AS the_geom
			FROM node WHERE epa_type = ''JUNCTION'' AND state = 1
		)
		SELECT concat(''S'', b.node_id), b.node_id, b.sector_id, b.muni_id, '||v_hyd||', ''flag_create_subcatchments'', st_intersection(a.the_geom, m.the_geom) FROM mec a 
		JOIN node b ON st_intersects(a.the_geom, b.the_geom)
		JOIN '||v_clip_table||' m USING ('||lower(v_clip)||'_id)
		WHERE b.epa_type = ''JUNCTION''
		AND state = 1
		ON CONFLICT DO NOTHING';

		

	UPDATE inp_subcatchment SET descript = 'flag_create_subcatchments';


	/* ATTRIBUTES */

	raise notice 'attributes';

	execute  '
	UPDATE inp_subcatchment t
	SET slope = z.slope FROM (
		WITH ext_raster_slope AS MATERIALIZED (
			SELECT ST_Clip(r.rast, g.the_geom, NULL::double precision, true) as rast
			FROM (
				SELECT ST_Slope(rast, 1, ''32BF'', ''PERCENT'') AS rast FROM v_raster_dem
			) r
			JOIN '||v_clip_table||' g
			ON ST_Intersects(r.rast, g.the_geom)
		)
			SELECT subc_id, 
			(ST_SummaryStatsAgg(ST_Clip(r.rast, s.the_geom), 1, TRUE)).mean AS slope 
			FROM ext_raster_slope r JOIN inp_subcatchment s ON st_intersects(r.rast, s.the_geom) 
			GROUP BY s.subc_id
		) z	WHERE t.subc_id = z.subc_id';     
                   
 
	RAISE NOTICE 'atrributes - 2';
	-- Clean empty geometries
	DELETE FROM inp_subcatchment
	WHERE ST_IsEmpty(the_geom) OR ST_Area(the_geom) < 1.0;

	delete from ve_inp_subcatchment where subc_id in 
	(select subc_id from ve_inp_subcatchment s join node n on node_id::text = outlet_id where n.sector_id <>s.sector_id);

	-- Area (planar units)
	UPDATE inp_subcatchment
	SET area = ST_Area(the_geom) --slope = 2, 
	WHERE descript = 'flag_create_subcatchments';

	-- Characteristic length: use LongestLine (no per-row quadratic point pairs)
	UPDATE inp_subcatchment
	SET clength = ST_Length(ST_LongestLine(the_geom, the_geom))
	WHERE descript = 'flag_create_subcatchments';

	-- Width (avoid divide by zero)
	UPDATE inp_subcatchment
	SET width = CASE WHEN clength > 0 THEN area / clength ELSE NULL END
	WHERE descript = 'flag_create_subcatchments';

	-- SCS Curve Number "simp" (same formula)
	UPDATE inp_subcatchment
	SET simp = 0.7696 * slope ^ (-0.49)
	WHERE descript = 'flag_create_subcatchments';

	-- Clean creation flag
	UPDATE inp_subcatchment
	SET descript = NULL
	WHERE descript = 'flag_create_subcatchments';
	
	raise notice 'return';


	/* RETURN */

	INSERT INTO t_audit_check_data (fid, error_message, cur_user, criticity)
	SELECT v_fid, error_message, current_user, log_level FROM sys_message WHERE id = 3700;

	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (
		SELECT id, error_message AS message
		FROM t_audit_check_data
		WHERE cur_user="current_user"() AND fid=v_fid
		ORDER BY criticity DESC, id ASC
	) row;

	v_result := COALESCE(v_result, '[]'::json);
	v_result_info := concat('{"values":', v_result, '}');
	v_version := COALESCE(v_version,'{}');
	v_result_info := COALESCE(v_result_info,'{}');

	EXECUTE 'SELECT gw_fct_manage_temp_tables($${"data":{"parameters":{"fid":"'||v_fid||'", "project_type":"UD", "action":"DROP", "group":"LOG"}}}$$)';


	RETURN gw_fct_json_create_return((
		'{"status":"Accepted","message":{"level":1,"text":"Analysis done successfully"},"version":"'
		|| v_version || '","body":{"form":{},"data":{"info":' || v_result_info || '}}}'
	)::json, 3360, NULL, NULL, NULL);

	EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN gw_fct_exception_others('Failed', SQLERRM, SQLSTATE, SQLERRM, v_error_context);

END;
$function$
;

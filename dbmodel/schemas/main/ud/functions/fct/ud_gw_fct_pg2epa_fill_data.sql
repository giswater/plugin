/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2234

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_pg2epa_fill_data(varchar);
CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_pg2epa_fill_data(result_id_var varchar)
RETURNS integer AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES","epsg":SRID_VALUE}, "data":{"resultId":"test1", "dumpSubcatch":"true","step":"0"}}$$) -- FULL PROCESS
INSERT INTO SCHEMA_NAME.rpt_cat_result VALUES ('r1');
SELECT "SCHEMA_NAME".gw_fct_pg2epa_fill_data ('r1');

select * from temp_t_arc
	select * from temp_t_node where epa_type = 'DIVIDER'


*/

-- fid: 113

DECLARE

v_rainfall text;
v_isoperative boolean;
v_statetype text;
v_networkmode integer;
v_timeseries record;
v_query_arc text;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- Delete previous results on temp_t_node & arc tables
	TRUNCATE temp_t_node;
	TRUNCATE temp_t_node_other;
	TRUNCATE temp_t_arc;
	TRUNCATE temp_t_arc_flowregulator;
	TRUNCATE temp_t_gully;
	TRUNCATE t_rpt_inp_raingage;
	DELETE FROM rpt_inp_raingage WHERE result_id = result_id_var;
	TRUNCATE temp_t_lid_usage;

	ALTER TABLE temp_t_lid_usage DROP constraint if exists  temp_t_lid_usage_subc_lidco;
	ALTER TABLE temp_t_lid_usage ADD CONSTRAINT temp_t_lid_usage_subc_lidco unique (subc_id, lidco_id);

	-- set all timeseries of raingage using user's value
	v_rainfall:= (SELECT value FROM config_param_user WHERE parameter='inp_options_setallraingages' AND cur_user=current_user);

	v_isoperative = (SELECT value::json->>'onlyIsOperative' FROM config_param_user WHERE parameter='inp_options_debug' AND cur_user=current_user)::boolean;

	v_networkmode = (SELECT value FROM config_param_user WHERE parameter='inp_options_networkmode' AND cur_user=current_user);

	--Use state_type only is operative true or not
	IF v_isoperative THEN
		v_statetype = ' AND value_state_type.is_operative = TRUE ';
	ELSE
		v_statetype = ' AND (value_state_type.is_operative = TRUE OR value_state_type.is_operative = FALSE)';
	END IF;

	-- to do: implement isoperative strategy

	-- Insert on node rpt_inp table
	-- the strategy of selector_sector is not used for nodes. The reason is to enable the posibility to export the sector=-1. In addition using this it's impossible to export orphan nodes
	EXECUTE 'INSERT INTO temp_t_node (result_id, node_id, top_elev, ymax, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, expl_id, the_geom, age)
	WITH arcs AS (
		SELECT node_1 AS node_id FROM selector_sector s, ve_arc a JOIN value_state_type ON id=state_type WHERE a.sector_id > 0 AND a.sector_id = s.sector_id and current_user = cur_user AND epa_type !=''UNDEFINED'' '||
		v_statetype ||' UNION 
		SELECT node_2 FROM selector_sector s, ve_arc a JOIN value_state_type ON id=state_type WHERE a.sector_id > 0 AND a.sector_id = s.sector_id and current_user = cur_user AND epa_type !=''UNDEFINED'' '||
		v_statetype ||'
	)
	SELECT '||quote_literal(result_id_var)||',
	node.node_id, sys_top_elev, sys_ymax, ve_node.sys_elev, node.node_type, node.nodecat_id, node.epa_type, node.sector_id, node.state, node.state_type,
	node.annotation, node.expl_id, node.the_geom, (now()::date-node.builtdate)/30
	FROM node
	LEFT JOIN ve_node USING (node_id)
	JOIN arcs a ON node.node_id=a.node_id';

	UPDATE temp_t_node SET y0=i.y0, ysur=i.ysur, apond=i.apond FROM inp_junction i WHERE temp_t_node.node_id::int=i.node_id;

	UPDATE temp_t_node SET y0=i.y0, ysur=i.ysur, apond=i.apond FROM inp_divider i WHERE temp_t_node.node_id::int=i.node_id;

	UPDATE temp_t_node SET y0=i.y0, ysur=i.ysur FROM inp_storage i WHERE temp_t_node.node_id::int=i.node_id;

	UPDATE temp_t_node SET y0=i.y0, ysur=i.ysur, apond=i.apond FROM inp_netgully i WHERE temp_t_node.node_id::int=i.node_id;

	UPDATE temp_t_node SET y0=i.y0, ysur=i.ysur, apond=i.apond FROM inp_inlet i WHERE temp_t_node.node_id::int=i.node_id;


	-- node on the fly transformation of junctions to outfalls (when outfallparam is fill and junction is node sink)
	-- PERFORM gw_fct_anl_node_sink($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{"tableName":"ve_node"},"data":{"parameters":{"saveOnDatabase":true}}}$$);

	-- update child param for divider
	UPDATE temp_t_node SET addparam=concat('{"divider_type":"',divider_type,'", "arc_id":"',arc_id,'", "curve_id":"',curve_id,'", "qmin":"',
	qmin,'", "ht":"',ht,'", "cd":"',cd,'"}')
	FROM inp_divider WHERE temp_t_node.node_id=inp_divider.node_id::text;

	-- update child param for storage
	UPDATE temp_t_node SET addparam=concat('{"storage_type":"',storage_type,'", "curve_id":"',curve_id,'", "a1":"',a1,'", "a2":"',a2,'", "a0":"',a0,'", "fevap":"',fevap,'", "sh":"',sh,'", "hc":"',hc,'", 
	"imd":"',imd,'"}')
	FROM inp_storage WHERE temp_t_node.node_id=inp_storage.node_id::text;

	-- update child param for outfall
	UPDATE temp_t_node SET addparam=concat('{"outfall_type":"',outfall_type,'", "state":"',state,'", "curve_id":"',curve_id,'", "timser_id":"',timser_id,'", "gate":"',gate,'"}')
	FROM inp_outfall WHERE temp_t_node.node_id=inp_outfall.node_id::text;

	-- update child param for outfall from node sink
	UPDATE temp_t_node SET epa_type='OUTFALL' FROM t_anl_node a JOIN inp_junction ON a.node_id = inp_junction.node_id::text
	WHERE outfallparam IS NOT NULL AND fid = 113 AND cur_user=current_user
	AND temp_t_node.node_id=a.node_id::text;

	INSERT INTO temp_t_node_other (node_id, type, timser_id, other, mfactor, sfactor, base, pattern_id, active)
	SELECT node_id, 'FLOW', timser_id, 'FLOW', 1, sfactor, base, pattern_id, true FROM ve_inp_inflows;

	INSERT INTO temp_t_node_other (node_id, type, timser_id, poll_id, other, mfactor, sfactor, base, pattern_id, active)
	SELECT node_id, 'POLLUTANT', timser_id, poll_id, form_type, mfactor, sfactor, base, pattern_id, true FROM ve_inp_inflows_poll;

	INSERT INTO temp_t_node_other (node_id, type, poll_id, other)
	SELECT node_id, 'TREATMENT', poll_id, function FROM ve_inp_treatment;

	-- Insert on arc rpt_inp table
	v_query_arc := 'INSERT INTO temp_t_arc 
	(result_id, arc_id, node_1, node_2, elevmax1, elevmax2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, length, n, expl_id, the_geom, q0, qmax, barrels, slope,
	culvert, kentry, kexit, kavg, flap, seepage, age)
	SELECT '||quote_literal(result_id_var)||',
	a.arc_id, node_1, node_2, a.sys_elev1, a.sys_elev2, a.arc_type, arccat_id, epa_type, a.sector_id, a.state, 
	a.state_type, a.annotation, 
	CASE
		WHEN custom_length IS NOT NULL THEN custom_length
		ELSE st_length2d(a.the_geom)
	END AS length,
	CASE
		WHEN custom_n IS NOT NULL THEN custom_n
		ELSE n
	END AS n,
	a.expl_id, 
	a.the_geom,
	q0,
	qmax,
	barrels,
	slope,
	culvert, kentry, kexit, kavg, flap, seepage, (now()::date-a.builtdate)/30
	FROM selector_sector, ve_arc a
		LEFT JOIN value_state_type ON id=state_type
		LEFT JOIN cat_material ON matcat_id = cat_material.id
		LEFT JOIN inp_conduit ON a.arc_id = inp_conduit.arc_id
		WHERE epa_type !=''UNDEFINED'' '||v_statetype||'
		AND (''ARC'' = ANY (cat_material.feature_type) OR cat_material.feature_type IS NULL)
		AND a.sector_id > 0
		AND a.sector_id=selector_sector.sector_id AND selector_sector.cur_user=current_user';
	RAISE NOTICE 'v_query_arc: %', v_query_arc;
	EXECUTE v_query_arc;

	-- update child param for outfall from node when is the last (border of sector)
	-- need to be here after inserting temp_t_arc
	UPDATE temp_t_node SET epa_type='OUTFALL', addparam=outfallparam
	FROM inp_junction i JOIN  
	(select * from (SELECT node_2 as node_id from temp_t_arc group by node_2 having count(*) = 1)a 
	except 
	select * from (SELECT node_1 from temp_t_arc group by node_1 having count(*) > 0)b) c ON i.node_id::text = c.node_id
	WHERE outfallparam is not null and temp_t_node.node_id = i.node_id::text;

	-- fill temp_t_gully in order to work with 1D/2D
	IF v_networkmode = 2 or v_networkmode = 3 THEN

		-- netgully
		EXECUTE 'INSERT INTO temp_t_gully 
		SELECT 
		concat(''NG'',node_id), g.node_type, gullycat_id, null, g.node_id, g.sector_id, g.state, g.state_type, 
		case when custom_top_elev is null then top_elev else custom_top_elev end, 
		units, units_placement, outlet_type,
		case when custom_width is null then total_width else custom_width end, 
		case when custom_length is null then total_length else custom_length end,
		case when custom_depth is null then depth else custom_depth end,
		gully_method, weir_cd, orifice_cd, custom_a_param, custom_b_param, efficiency, the_geom
		FROM selector_sector s, ve_inp_netgully g 
		LEFT JOIN value_state_type ON id=g.state_type
		WHERE g.sector_id > 0 '||v_statetype||' AND s.cur_user = current_user and s.sector_id = g.sector_id;';

		-- gully
		EXECUTE 'INSERT INTO temp_t_gully 
		SELECT 
		gully_id, g.gully_type, gullycat_id, g.arc_id, 
		case when pjoint_type = ''NODE'' then pjoint_id else a.node_2 END AS node_id, 
		g.sector_id, g.state, g.state_type, 
		case when custom_top_elev is null then top_elev else custom_top_elev end, 
		units, units_placement, outlet_type,
		case when custom_width is null then total_width else custom_width end, 
		case when g.custom_length is null then total_length else g.custom_length end,
		case when custom_depth is null then depth else custom_depth end,
		gully_method, weir_cd, orifice_cd, custom_a_param, custom_b_param, efficiency, g.the_geom
		FROM selector_sector s, ve_inp_gully g
		LEFT JOIN arc a USING (arc_id)
		LEFT JOIN value_state_type ON id=g.state_type
		WHERE arc_id IS NOT NULL AND g.sector_id > 0 '||v_statetype||' AND s.cur_user = current_user and s.sector_id = g.sector_id;';


		EXECUTE 'INSERT INTO temp_t_gully 
		SELECT 
		concat(''IN'',node_id), g.node_type, null, null, g.node_id, g.sector_id, g.state, g.state_type,
		case when custom_top_elev is null then top_elev else custom_top_elev end, 
		null, null, outlet_type, inlet_width, inlet_length, null, gully_method, cd1, cd2, null, null, efficiency, the_geom
		FROM selector_sector s, ve_inp_inlet g 
		LEFT JOIN value_state_type ON id=g.state_type
		WHERE g.sector_id > 0 '||v_statetype||' AND s.cur_user = current_user and s.sector_id = g.sector_id;';
 -- TO FIX: INLET
	END IF;

	-- orifice
	INSERT INTO temp_t_arc_flowregulator (arc_id, type, ori_type, offsetval, cd, orate, flap, shape, geom1, geom2, geom3, geom4)
	SELECT arc_id, 'ORIFICE', ori_type, offsetval, cd, orate, flap, shape, geom1, geom2, 0, 0
	FROM ve_inp_orifice;

	-- outlet
	INSERT INTO temp_t_arc_flowregulator (arc_id, type, outlet_type, offsetval, curve_id, cd1, cd2, flap)
	SELECT arc_id, 'OUTLET', outlet_type, offsetval, curve_id, cd1, cd2, flap
	FROM ve_inp_outlet;


	-- pump
	INSERT INTO temp_t_arc_flowregulator (arc_id, type, curve_id, status, startup, shutoff)
	SELECT arc_id, 'PUMP', curve_id, status, startup, shutoff
	FROM ve_inp_pump;

	-- weir
	INSERT INTO temp_t_arc_flowregulator (arc_id, type, weir_type, offsetval, cd, ec, cd2, flap, shape, geom1, geom2, geom3, geom4, road_width,
	road_surf, coef_curve, surcharge)
	SELECT arc_id, 'WEIR', weir_type, offsetval, cd, ec, cd2, flap, inp_typevalue.descript, geom1, geom2, geom3, geom4, road_width,
	road_surf, coef_curve, surcharge
	FROM ve_inp_weir
	LEFT JOIN inp_typevalue ON inp_typevalue.id::text = ve_inp_weir.weir_type::text
	WHERE inp_typevalue.typevalue::text = 'inp_typevalue_weir';

	-- filling empty values
	UPDATE temp_t_node SET y0=0 where y0 IS NULL;
	UPDATE temp_t_node SET ysur=0 where ysur IS NULL;

	UPDATE temp_t_arc SET q0=0 where q0 IS NULL;

	-- rpt_inp_raingage
	INSERT INTO t_rpt_inp_raingage
	SELECT result_id_var, * FROM ve_raingage;

	-- setting same rainfall for all raingage
	IF v_rainfall IS NOT NULL THEN
		UPDATE t_rpt_inp_raingage SET timser_id=v_rainfall, rgage_type='TIMESERIES';
	END IF;

	-- setting for date-time parameters if rainfall has addparam values)
	select * into v_timeseries from inp_timeseries where id = v_rainfall;

	IF jsonb_extract_path_text(v_timeseries.addparam,'start_date') IS NOT NULL AND jsonb_extract_path_text(v_timeseries.addparam,'start_date') != '' THEN
		update config_param_user set value = jsonb_extract_path_text(v_timeseries.addparam,'start_date')
		where cur_user = current_user and parameter = 'inp_options_start_date';
		update config_param_user set value = jsonb_extract_path_text(v_timeseries.addparam,'start_time')
		where cur_user = current_user and parameter = 'inp_options_start_time';
		update config_param_user set value = jsonb_extract_path_text(v_timeseries.addparam,'end_date')
		where cur_user = current_user and parameter = 'inp_options_end_date';
		update config_param_user set value = jsonb_extract_path_text(v_timeseries.addparam,'end_time')
		where cur_user = current_user and parameter = 'inp_options_end_time';
		update config_param_user set value = jsonb_extract_path_text(v_timeseries.addparam,'start_date')
		where cur_user = current_user and parameter = 'inp_options_report_start_date';
		update config_param_user set value = jsonb_extract_path_text(v_timeseries.addparam,'start_time')
		where cur_user = current_user and parameter = 'inp_options_report_start_time';

	END IF;


	RETURN 1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
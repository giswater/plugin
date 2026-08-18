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
v_statetype text;
v_networkmode integer;
v_timeseries record;
v_query_arc text;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- set all timeseries of raingage using user's value
	v_rainfall:= (SELECT value FROM config_param_user WHERE parameter='inp_options_setallraingages' AND cur_user=current_user);
	v_networkmode = (SELECT value FROM config_param_user WHERE parameter='inp_options_networkmode' AND cur_user=current_user);

	-- Insert on arc temp_t_arc table
	INSERT INTO temp_t_arc (
		result_id, arc_id, node_1, node_2, elevmax1, elevmax2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, length, n, expl_id, the_geom, q0,
		qmax, barrels, slope, culvert, kentry, kexit, kavg, flap, seepage, age
	)
	SELECT
		quote_literal(result_id_var) AS result_id,
		a.arc_id,
		a.node_1,
		a.node_2,
		COALESCE(a.custom_elev1, a.elev1, a.node_custom_elev_1, a.node_elev_1) AS elevmax1,
		COALESCE(a.custom_elev2, a.elev2, a.node_custom_elev_2, a.node_elev_2) AS elevmax2,
		a.arc_type,
		a.arccat_id,
		a.epa_type,
		a.sector_id,
		a.state,
		a.state_type,
		a.annotation,
		COALESCE(a.custom_length, st_length2d(a.the_geom)) AS length,
		COALESCE(ic.custom_n, cm.n) AS n,
		a.expl_id,
		a.the_geom,
		ic.q0,
		ic.qmax,
		ic.barrels,
		CASE
            WHEN a.sys_slope IS NULL THEN ((COALESCE(a.node_custom_elev_1, a.node_elev_1, a.elev1, a.node_top_elev_1 - a.y1, a.node_elev_1) - COALESCE(a.node_custom_elev_2, a.node_elev_2, a.elev2, a.node_top_elev_2 - a.y2, a.node_elev_2))::double precision / st_length(a.the_geom))::numeric(12,4)
            ELSE a.sys_slope
        END AS slope,
		ic.culvert,
		ic.kentry,
		ic.kexit,
		ic.kavg,
		ic.flap,
		ic.seepage,
		((now()::date - a.builtdate) / 30) AS age
	FROM arc a
		JOIN vf_arc vf ON vf.arc_id = a.arc_id
		LEFT JOIN value_state_type vst ON vst.id = a.state_type
		LEFT JOIN cat_material cm ON a.matcat_id = cm.id
		LEFT JOIN inp_conduit ic ON a.arc_id = ic.arc_id
	WHERE (
		'ARC' = ANY (cm.feature_type)
		OR cm.feature_type IS NULL
	)
	AND a.sector_id > 0;


	-- Insert on node temp_t_node table
	-- the strategy of selector_sector is not used for nodes. The reason is to enable the posibility to export the sector=-1. In addition using this it's impossible to export orphan nodes
	INSERT INTO temp_t_node (result_id, node_id, top_elev, ymax, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, expl_id, the_geom, age)
	SELECT 
		quote_literal(result_id_var),
		n.node_id, 
		COALESCE(n.custom_top_elev, n.top_elev), 
		COALESCE(
			COALESCE(n.custom_top_elev, n.top_elev) - COALESCE(n.custom_elev, n.elev), 
			n.ymax
		), 
		COALESCE(n.custom_elev, n.elev), 
		n.node_type,
		n.nodecat_id, 
		n.epa_type, 
		n.sector_id, 
		n.state, 
		n.state_type, 
		n.annotation, 
		n.expl_id, 
		n.the_geom, 
		(now()::date - n.builtdate) / 30
	FROM node n
		JOIN vf_node vf ON vf.node_id = n.node_id
	WHERE EXISTS (
		SELECT 1
		FROM temp_t_arc a
		WHERE a.node_1 = n.node_id::text
		   OR a.node_2 = n.node_id::text
	);

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
	

	-- update child param for outfall from node when is the last (border of sector)
	-- need to be here after inserting temp_t_arc
	UPDATE temp_t_node n
	SET epa_type = 'OUTFALL',
		addparam = i.outfallparam
	FROM inp_junction i
	WHERE n.node_id = i.node_id::text
		AND i.outfallparam IS NOT NULL
		AND EXISTS (
			SELECT 1
			FROM temp_t_arc a
			WHERE a.node_2 = n.node_id
			HAVING count(*) = 1
		)
		AND NOT EXISTS (
			SELECT 1
			FROM temp_t_arc a
			WHERE a.node_1 = n.node_id
		);

	-- fill temp_t_gully in order to work with 1D/2D
	IF v_networkmode = 2 or v_networkmode = 3 THEN

		-- netgully
		INSERT INTO temp_t_gully (
			gully_id, gully_type, gullycat_id, arc_id, node_id, sector_id, state, state_type, top_elev, units, units_placement, outlet_type,
			total_width, total_length, depth, gully_method, weir_cd, orifice_cd, custom_a_param, custom_b_param, efficiency, the_geom
		)
		SELECT 
			concat('NG', g.node_id), 
			g.node_type, 
			g.gullycat_id, 
			NULL, 
			g.node_id, 
			g.sector_id, 
			g.state, 
			g.state_type,
			COALESCE(g.custom_top_elev, g.top_elev), 
			g.units, 
			g.units_placement, 
			g.outlet_type, 
			COALESCE(g.custom_width, g.total_width), 
			COALESCE(g.custom_length, g.total_length), 
			COALESCE(g.custom_depth, g.depth), 
			g.gully_method, 
			g.weir_cd, 
			g.orifice_cd, 
			g.custom_a_param, 
			g.custom_b_param, 
			g.efficiency, 
			g.the_geom
		FROM ve_inp_netgully g
		WHERE g.sector_id > 0;

		-- gully
		INSERT INTO temp_t_gully (
			gully_id, gully_type, gullycat_id, arc_id, node_id, sector_id, state, state_type, 
			top_elev, units, units_placement, outlet_type, total_width, total_length, depth, 
			gully_method, weir_cd, orifice_cd, custom_a_param, custom_b_param, efficiency, the_geom
		)
		SELECT 
			g.gully_id,
			g.gully_type,
			g.gullycat_id,
			g.arc_id,
			CASE 
				WHEN g.pjoint_type = 'NODE' THEN g.pjoint_id 
				ELSE a.node_2 
			END AS node_id,
			g.sector_id,
			g.state,
			g.state_type,
			COALESCE(g.custom_top_elev, g.top_elev),
			g.units,
			g.units_placement,
			g.outlet_type,
			COALESCE(g.custom_width, g.total_width),
			COALESCE(g.custom_length, g.total_length),
			COALESCE(g.custom_depth, g.depth),
			g.gully_method,
			g.weir_cd,
			g.orifice_cd,
			g.custom_a_param,
			g.custom_b_param,
			g.efficiency,
			g.the_geom
		FROM ve_inp_gully g
		LEFT JOIN arc a ON a.arc_id = g.arc_id
		WHERE g.arc_id IS NOT NULL AND g.sector_id > 0;


		INSERT INTO temp_t_gully (
			gully_id, gully_type, gullycat_id, arc_id, node_id, sector_id, state, state_type,
			top_elev, units, units_placement, outlet_type, total_width, total_length, depth,
			gully_method, weir_cd, orifice_cd, custom_a_param, custom_b_param, efficiency, the_geom
		)
		SELECT 
			concat('IN', g.node_id),
			g.node_type,
			null,
			null,
			g.node_id,
			g.sector_id,
			g.state,
			g.state_type,
			COALESCE(g.custom_top_elev, g.top_elev),
			null,
			null,
			g.outlet_type,
			g.inlet_width,
			g.inlet_length,
			null,
			g.gully_method,
			g.cd1,
			g.cd2,
			null,
			null,
			g.efficiency,
			g.the_geom
		FROM ve_inp_inlet g
		WHERE g.sector_id > 0;
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
	UPDATE temp_t_node SET y0=0 WHERE y0 IS NULL;

	UPDATE temp_t_node SET ysur=0 WHERE ysur IS NULL;

	UPDATE temp_t_arc SET q0=0 WHERE q0 IS NULL;

	-- rpt_inp_raingage
	INSERT INTO t_rpt_inp_raingage
	SELECT result_id_var, * FROM ve_raingage;

	-- setting same rainfall for all raingage
	IF v_rainfall IS NOT NULL THEN
		UPDATE t_rpt_inp_raingage SET timser_id=v_rainfall, rgage_type='TIMESERIES';
	END IF;

	-- setting for date-time parameters if rainfall has addparam values)
	SELECT * INTO v_timeseries FROM inp_timeseries WHERE id = v_rainfall;

	IF jsonb_extract_path_text(v_timeseries.addparam,'start_date') IS NOT NULL AND jsonb_extract_path_text(v_timeseries.addparam,'start_date') != '' THEN
		UPDATE config_param_user SET value = jsonb_extract_path_text(v_timeseries.addparam,'start_date')
		WHERE cur_user = current_user AND parameter = 'inp_options_start_date';
		UPDATE config_param_user SET value = jsonb_extract_path_text(v_timeseries.addparam,'start_time')
		WHERE cur_user = current_user AND parameter = 'inp_options_start_time';
		UPDATE config_param_user SET value = jsonb_extract_path_text(v_timeseries.addparam,'end_date')
		WHERE cur_user = current_user AND parameter = 'inp_options_end_date';
		UPDATE config_param_user SET value = jsonb_extract_path_text(v_timeseries.addparam,'end_time')
		WHERE cur_user = current_user AND parameter = 'inp_options_end_time';
		UPDATE config_param_user SET value = jsonb_extract_path_text(v_timeseries.addparam,'start_date')
		WHERE cur_user = current_user AND parameter = 'inp_options_report_start_date';
		UPDATE config_param_user SET value = jsonb_extract_path_text(v_timeseries.addparam,'start_time')
		WHERE cur_user = current_user AND parameter = 'inp_options_report_start_time';

	END IF;


	RETURN 1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
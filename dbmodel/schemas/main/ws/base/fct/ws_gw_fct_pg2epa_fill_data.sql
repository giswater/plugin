/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2328

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_pg2epa_fill_data(varchar);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_fill_data(result_id_var varchar)  RETURNS integer AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "useNetworkGeom":"false"}}$$)
*/

DECLARE

v_usedmapattern boolean;
v_buildupmode integer;
v_isoperative boolean;
v_networkmode integer;
v_minlength float;
v_forcereservoirsoninlets boolean;
v_forcetanksoninlets boolean;
v_count integer;
v_querytext text;
v_querystatetype text;
v_exporthybriddma boolean;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;


	--  Get system & user variables
	v_usedmapattern = (SELECT value FROM config_param_user WHERE parameter='inp_options_use_dma_pattern' AND cur_user=current_user);
	v_buildupmode = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_buildup_mode' AND cur_user=current_user);
	v_networkmode = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_networkmode' AND cur_user=current_user);
	v_minlength := (SELECT value FROM config_param_system WHERE parameter = 'epa_arc_minlength');
	v_forcereservoirsoninlets := (SELECT value::json->>'forceReservoirsOnInlets' FROM config_param_user WHERE parameter = 'inp_options_debug' AND cur_user=current_user);
	v_forcetanksoninlets := (SELECT value::json->>'forceTanksOnInlets' FROM config_param_user WHERE parameter = 'inp_options_debug' AND cur_user=current_user);
	v_exporthybriddma := (SELECT value::boolean FROM config_param_system WHERE parameter = 'epa_export_hybrid_dma');

	-- get debug parameters
	v_isoperative = (SELECT value::json->>'onlyIsOperative' FROM config_param_user WHERE parameter='inp_options_debug' AND cur_user=current_user)::boolean;

	raise notice 'Delete previous values from same result';

	--Use state_type only is operative true or not
	IF v_isoperative THEN
		v_querystatetype = ' AND value_state_type.is_operative = TRUE ';
	ELSE
		v_querystatetype = ' AND (value_state_type.is_operative = TRUE OR value_state_type.is_operative = FALSE)';
	END IF;

	raise notice 'inserting arcs on temp_t_arc table';

	v_querytext = 'INSERT INTO temp_t_arc (arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, roughness, 
		length, diameter, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, age, family, builtdate)
		SELECT DISTINCT ON (arc_id)
		ve_arc.arc_id, node_1, node_2, ve_arc.arc_type, arccat_id, epa_type, ve_arc.sector_id, COALESCE(ve_arc.p_state, ve_arc.state), ve_arc.state_type, ve_arc.annotation,
		CASE WHEN custom_roughness IS NOT NULL THEN custom_roughness ELSE roughness END AS roughness,
		(CASE WHEN ve_arc.custom_length IS NOT NULL THEN custom_length ELSE gis_length END), 
		(CASE WHEN inp_pipe.custom_dint IS NOT NULL THEN custom_dint ELSE dint END),  -- diameter is child value but in order to make simple the query getting values from ve_arc (dint)...
		ve_arc.the_geom,
		ve_arc.expl_id, ve_arc.dma_id, presszone_id, dqa_id, minsector_id,
		(case when ve_arc.builtdate is not null then (now()::date-ve_arc.builtdate)/30 else 0 end),
		cat_material."family",
		ve_arc.builtdate
		FROM ve_arc
			JOIN cat_arc ON ve_arc.arccat_id = cat_arc.id
			JOIN cat_material ON cat_arc.matcat_id = cat_material.id
			JOIN cat_mat_roughness ON cat_mat_roughness.matcat_id = cat_material.id';

	v_querytext = v_querytext || ' WHERE (current_date - (CASE WHEN builtdate IS NULL THEN ''1900-01-01''::date ELSE builtdate END))/365.25 >= cat_mat_roughness.init_age
			AND (current_date - (CASE WHEN builtdate IS NULL THEN ''1900-01-01''::date ELSE builtdate END))/365.25 <= cat_mat_roughness.end_age '
			||v_querystatetype||' 
			AND epa_type != ''UNDEFINED''
			AND COALESCE(ve_arc.p_state, ve_arc.state) = 1 AND COALESCE(ve_arc.p_state, ve_arc.sector_id) > 0
			AND st_length(ve_arc.the_geom) >= '||v_minlength;

	IF v_networkmode = 1 THEN
		IF v_exporthybriddma THEN
			v_querytext = v_querytext || ' AND ve_arc.dma_type IN (SELECT id FROM edit_typevalue WHERE typevalue = ''dma_type'' AND (idval = ''TRANSMISSION'' OR idval = ''HYBRID''))';
		ELSE
			v_querytext = v_querytext || ' AND ve_arc.dma_type = (SELECT id FROM edit_typevalue WHERE typevalue = ''dma_type'' AND idval = ''TRANSMISSION'')';
		END IF;
	END IF;

	IF v_networkmode = 5 THEN
		v_querytext = v_querytext || ' AND ve_arc.dma_id = (SELECT value::integer FROM config_param_user WHERE parameter = ''inp_options_selecteddma'' AND cur_user = current_user)';
	END IF;

	EXECUTE v_querytext;

	IF v_networkmode =  4 THEN

		-- this need to be solved here in spite of fill_data functions because some kind of incosnstency done on this function on previous lines
		EXECUTE 'INSERT INTO temp_t_arc (arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, roughness, length, diameter, the_geom,
			expl_id, dma_id, presszone_id, dqa_id, minsector_id, status, minorloss, age, family, builtdate)
			SELECT concat(''CO'',c.connec_id), c.connec_id as node_1, 
			CASE 	WHEN t.exit_type = ''ARC'' THEN concat(''VN'',t.link_id)
				WHEN t.exit_type IN (''NODE'', ''CONNEC'') THEN t.exit_id::text 
				ELSE vf_connec.pjoint_id::text end AS node_2, 
			''LINK'', conneccat_id, ''PIPE'', t.sector_id, t.state, t.state_type, t.annotation, 
			(CASE WHEN custom_roughness IS NOT NULL THEN custom_roughness ELSE roughness END) AS roughness,
			(CASE WHEN t.custom_length IS NOT NULL THEN t.custom_length ELSE st_length(t.the_geom) END), 
			(CASE WHEN custom_dint IS NOT NULL THEN custom_dint ELSE dint END),  -- diameter is child value but in order to make simple the query getting values from ve_arc (dint)...
			t.the_geom,
			c.expl_id, c.dma_id, c.presszone_id, c.dqa_id, c.minsector_id, inp_connec.status, inp_connec.minorloss,
			(case when c.builtdate is not null then (now()::date-c.builtdate)/30 else 0 end),
			cat_material."family",
			c.builtdate
			FROM selector_sector, link t
			JOIN connec c ON c.connec_id = t.feature_id
			JOIN vf_connec ON c.connec_id = vf_connec.connec_id
			JOIN value_state_type ON value_state_type.id = c.state_type
			JOIN cat_connec ON cat_connec.id = conneccat_id
			JOIN inp_connec ON c.connec_id = inp_connec.connec_id
			LEFT JOIN cat_mat_roughness ON cat_mat_roughness.matcat_id = cat_connec.matcat_id
			LEFT JOIN cat_material ON cat_material.id = cat_connec.matcat_id
				WHERE (current_date - (CASE WHEN c.builtdate IS NULL THEN ''1900-01-01''::date ELSE c.builtdate END))/365.25 >= cat_mat_roughness.init_age
				AND (current_date - (CASE WHEN c.builtdate IS NULL THEN ''1900-01-01''::date ELSE c.builtdate END))/365.25 <= cat_mat_roughness.end_age '
				||v_querystatetype||' AND c.sector_id=selector_sector.sector_id AND selector_sector.cur_user=current_user
				AND epa_type = ''JUNCTION''
				AND COALESCE(vf_connec.p_state, c.sector_id) > 0 AND COALESCE(vf_connec.p_state, c.state) > 0
				AND vf_connec.pjoint_id IS NOT NULL AND vf_connec.pjoint_type IS NOT NULL';
	END IF;

	raise notice 'Inserting nodes on temp_t_node table';

	-- the strategy of selector_sector is not used for nodes. The reason is to enable the posibility to export the sector=-1. In addition using this it's impossible to export orphan nodes
	v_querytext = ' INSERT INTO temp_t_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, age, builtdate)
		WITH b AS (
			SELECT arc.arc_id, arc.node_1, arc.node_2, arc.sector_id
			FROM arc
			JOIN vf_arc on arc.arc_id = vf_arc.arc_id
			JOIN value_state_type ON arc.state_type = value_state_type.id
			WHERE epa_type <> ''UNDEFINED'' AND EXISTS (
				SELECT 1 FROM selector_sector ss WHERE ss.sector_id = arc.sector_id AND ss.cur_user = current_user
			)
			AND COALESCE(vf_arc.p_state, arc.sector_id) > 0
			AND COALESCE(vf_arc.p_state, arc.state) > 0'
			||v_querystatetype||'
		)
		SELECT DISTINCT ON (n.node_id)
		n.node_id, top_elev, top_elev-depth as elev, node_type, nodecat_id, epa_type, a.sector_id, COALESCE(vf_node.p_state, n.state), n.state_type, n.annotation, n.the_geom, n.expl_id, n.dma_id, presszone_id, dqa_id, minsector_id,
		(case when n.builtdate is not null then (now()::date-n.builtdate)/30 else 0 end),
		n.builtdate
		FROM node n 
		JOIN (
			SELECT node_1 AS node_id, sector_id
			FROM b
			UNION
			SELECT node_2, sector_id
			FROM b
		)a USING (node_id)
		JOIN cat_node c ON c.id=nodecat_id
		JOIN vf_node ON n.node_id = vf_node.node_id
		WHERE COALESCE(vf_node.p_state, n.sector_id) > 0';

	EXECUTE v_querytext;

	-- create link exit
	IF v_networkmode in (3,4) THEN
		PERFORM gw_fct_linkexitgenerator(1);
	END IF;

	IF v_networkmode = 4 THEN

		EXECUTE ' INSERT INTO temp_t_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, the_geom, expl_id, 
			dma_id, presszone_id, dqa_id, minsector_id, age, builtdate)
			SELECT
			c.connec_id, top_elev, top_elev-depth as elev, ''CONNEC'', conneccat_id, epa_type, c.sector_id, COALESCE(vf_connec.p_state, c.state), c.state_type, c.annotation, c.the_geom, c.expl_id, 
			c.dma_id, c.presszone_id, c.dqa_id, c.minsector_id,
			(case when c.builtdate is not null then (now()::date-c.builtdate)/30 else 0 end),
			c.builtdate
			FROM connec c
			JOIN vf_connec on c.connec_id = vf_connec.connec_id
			JOIN value_state_type ON id = state_type
			WHERE EXISTS (
				select 1
				from selector_sector ss
				where ss.sector_id = c.sector_id
				and ss.cur_user = current_user
			)
			AND COALESCE(vf_connec.p_state, c.sector_id) > 0
			AND COALESCE(vf_connec.p_state, c.state) > 0 
			AND COALESCE(vf_connec.pjoint_id, c.pjoint_id) IS NOT NULL
			AND COALESCE(vf_connec.pjoint_type, c.pjoint_type) IS NOT NULL
			AND epa_type = ''JUNCTION'' '
			||v_querystatetype;
	END IF;

	UPDATE temp_t_node SET "family" = q."family"
	FROM (
		SELECT n.node_id, cm."family" 
		FROM node n
		JOIN cat_node c ON c.id = n.nodecat_id 
		JOIN cat_material cm ON cm.id = c.matcat_id 
	) q
	WHERE temp_t_node.node_id = q.node_id::text;
	
	-- set bottom elevation as elev for tanks in case invert_level is not null
	UPDATE temp_t_node SET elev = invert_level FROM man_tank WHERE invert_level IS NOT NULL AND temp_t_node.node_id = man_tank.node_id::text
	AND epa_type IN ('INLET', 'TANK');
	
	-- update child param for inp_reservoir
	UPDATE temp_t_node SET pattern_id=inp_reservoir.pattern_id FROM inp_reservoir WHERE temp_t_node.node_id=inp_reservoir.node_id::text;

	-- update head for those reservoirs head is not null
	UPDATE temp_t_node SET top_elev = head, elev = head FROM inp_reservoir WHERE temp_t_node.node_id=inp_reservoir.node_id::text AND head is not null;

	-- update head for those inlet acting as reservoir with head not null
	UPDATE temp_t_node SET top_elev = head, elev = head FROM inp_inlet WHERE temp_t_node.node_id=inp_inlet.node_id::text AND head is not null AND epa_type = 'RESERVOIR';

	-- update child param for inp_tank
	UPDATE temp_t_node SET addparam=concat('{"initlevel":"',initlevel,'", "minlevel":"',minlevel,'", "maxlevel":"',maxlevel,'", "diameter":"'
	,diameter,'", "minvol":"',minvol,'", "curve_id":"',curve_id,'", "overflow":"',overflow,'"}')
	FROM inp_tank WHERE temp_t_node.node_id=inp_tank.node_id::text;

	-- update child param for inp_inlet
	UPDATE temp_t_node SET
	addparam=concat('{"pattern_id":"',i.pattern_id,'", "initlevel":"',initlevel,'", "minlevel":"',minlevel,'", "maxlevel":"',maxlevel,'", "diameter":"'
	,diameter,'", "minvol":"',minvol,'", "curve_id":"',curve_id,'", "overflow":"',overflow,'", "mixing_model":"',mixing_model,'", "mixing_fraction":"',mixing_fraction,'", "reaction_coeff":"',reaction_coeff,'", 
	"init_quality":"',init_quality,'", "source_type":"',source_type,'", "source_quality":"',source_quality,'", "source_pattern_id":"',source_pattern_id,'",
	"demand":"',i.demand,'", "demand_pattern_id":"',demand_pattern_id,'","emitter_coeff":"',emitter_coeff,'"}')
	FROM inp_inlet i WHERE temp_t_node.node_id=i.node_id::text;

	-- update child param for inp_junction
	UPDATE temp_t_node SET demand=(inp_junction.demand*COALESCE(peak_factor, 1)), pattern_id=inp_junction.pattern_id, addparam=concat('{"emitter_coeff":"',emitter_coeff,'"}')
	FROM inp_junction WHERE temp_t_node.node_id=inp_junction.node_id::text;

	UPDATE temp_t_node SET demand=(inp_connec.demand*COALESCE(peak_factor, 1)), pattern_id=inp_connec.pattern_id, addparam=concat('{"emitter_coeff":"',emitter_coeff,'"}')
	FROM inp_connec WHERE temp_t_node.node_id=inp_connec.connec_id::text;

	-- update addparam for inp_pump
	UPDATE temp_t_node SET addparam=concat('{"power":"',power,'", "curve_id":"',curve_id,'", "speed":"',speed,'", "pattern":"',p.pattern_id,'", "status":"',status,'", "to_arc":"',to_arc,
	'", "energy_price":"',energy_price,'", "energy_pattern_id":"',energy_pattern_id,'", "pump_type":"',pump_type,'"}')
	FROM ve_inp_pump p WHERE temp_t_node.node_id=p.node_id::text;

	-- insert numarcs for nodes
	INSERT INTO t_numarcs (node_id, numarcs)
	SELECT n.node_id, count(*) as numarcs
	FROM temp_t_node n
	JOIN (
		SELECT node_1 as node_id
		FROM temp_t_arc 
		UNION ALL
		SELECT node_2
		FROM temp_t_arc
	) a ON n.node_id=a.node_id
	group by n.node_id;


	-- update child param for inp_valve
	UPDATE temp_t_node SET addparam=concat('{"valve_type":"',valve_type,'", "setting":"',setting,'", "diameter":"',custom_dint,
	'", "curve_id":"',curve_id,'", "minorloss":"',minorloss,'", "status":"',status,
	'", "to_arc":"',to_arc,'", "add_settings":"',add_settings,'"}')
	FROM ve_inp_valve v WHERE temp_t_node.node_id=v.node_id::text 
	AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=v.node_id::text AND t_numarcs.numarcs > 1);

	-- convert to reservoir the valves with numarcs = 1 and to_arc is not null
	UPDATE temp_t_node SET
	epa_type = 'RESERVOIR', top_elev = v.head, elev = v.head, pattern_id=v.pattern_id
	FROM ve_inp_valve v
	WHERE temp_t_node.node_id=v.node_id::text 
	AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=v.node_id::text AND t_numarcs.numarcs = 1) AND v.to_arc IS NOT NULL;

	-- convert to junction the valves with numarcs = 1 and to_arc is null
	UPDATE temp_t_node SET
	epa_type = 'JUNCTION',
	demand=(v.demand*1), pattern_id=v.demand_pattern_id, addparam=concat('{"emitter_coeff":"',emitter_coeff,'"}')
	FROM ve_inp_valve v
	WHERE temp_t_node.node_id=v.node_id::text 
	AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=v.node_id::text AND t_numarcs.numarcs = 1) AND v.to_arc IS NULL;


	-- update child param for inp_pipe
	UPDATE temp_t_arc SET
	minorloss = inp_pipe.minorloss,
	status = (CASE WHEN inp_pipe.status IS NULL THEN 'OPEN' ELSE inp_pipe.status END),
	addparam=concat('{"reactionparam":"',inp_pipe.reactionparam, '","reactionvalue":"',inp_pipe.reactionvalue,'"}')
	FROM inp_pipe WHERE temp_t_arc.arc_id=inp_pipe.arc_id::text;

	-- update child param for inp_virtualvalve
	UPDATE temp_t_arc SET
	minorloss = inp_virtualvalve.minorloss,
	diameter = inp_virtualvalve.diameter,
	status = inp_virtualvalve.status,
	addparam=concat('{"valve_type":"',valve_type,'", "setting":"',setting,'", "curve_id":"',curve_id,'"}')
	FROM inp_virtualvalve WHERE temp_t_arc.arc_id=inp_virtualvalve.arc_id::text;

	-- update addparam for inp_virtualpump
	UPDATE temp_t_arc SET addparam=concat('{"power":"',power,'", "curve_id":"',curve_id,'", "speed":"',speed,'", "pattern_id":"',p.pattern_id,'", "status":"',p.status,'",
	"effic_curve_id":"', effic_curve_id,'", "energy_price":"',energy_price,'", "energy_pattern_id":"',energy_pattern_id,'", "pump_type":"POWERPUMP"}')
	FROM inp_virtualpump p WHERE temp_t_arc.arc_id=p.arc_id::text;

	-- update addparam for inp_shortpipe (step 1)
	UPDATE temp_t_node SET addparam=concat('{"minorloss":"',minorloss,'", "to_arc":"',to_arc,'", "status":"',status,'", "diameter":"", "roughness":"',a.roughness,'"}')
	FROM ve_epa_shortpipe
	JOIN (SELECT node_1 as node_id, diameter, roughness FROM temp_t_arc) a ON a.node_id = ve_epa_shortpipe.node_id::text
	WHERE temp_t_node.node_id=ve_epa_shortpipe.node_id::text AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=ve_epa_shortpipe.node_id::text AND t_numarcs.numarcs > 1);

	-- update addparam for inp_shortpipe (step 2)
	UPDATE temp_t_node SET addparam=concat('{"minorloss":"',minorloss,'", "to_arc":"',to_arc,'", "status":"',status,'", "diameter":"", "roughness":"',a.roughness,'"}')
	FROM ve_epa_shortpipe
	JOIN (SELECT node_2 as node_id, diameter, roughness FROM temp_t_arc) a ON a.node_id = ve_epa_shortpipe.node_id::text
	WHERE temp_t_node.node_id=ve_epa_shortpipe.node_id::text 
	AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=ve_epa_shortpipe.node_id::text AND t_numarcs.numarcs > 1);

	-- convert to reservoir the shortpipes with numarcs = 1 and to_arc is not null
	UPDATE temp_t_node SET
	epa_type = 'RESERVOIR',
	top_elev = v.head, elev = v.head, pattern_id=v.pattern_id
	FROM ve_epa_shortpipe v
	WHERE temp_t_node.node_id=v.node_id::text AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=v.node_id::text 
    AND t_numarcs.numarcs = 1)
	AND v.to_arc IS NOT NULL;

	-- convert to junction the shortpipes with numarcs = 1 and to_arc is null
	UPDATE temp_t_node SET
	epa_type = 'JUNCTION',
	demand=(v.demand*1), pattern_id=v.demand_pattern_id, addparam=concat('{"emitter_coeff":"',emitter_coeff,'"}')
	FROM ve_epa_shortpipe v
	WHERE temp_t_node.node_id=v.node_id::text AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=v.node_id::text
	AND t_numarcs.numarcs = 1)
	AND v.to_arc IS NULL;

	RETURN 1;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
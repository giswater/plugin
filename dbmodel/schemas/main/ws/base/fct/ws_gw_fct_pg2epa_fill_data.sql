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
v_statetype text;
v_isoperative boolean;
v_networkmode integer;
v_minlength float;
v_forcereservoirsoninlets boolean;
v_forcetanksoninlets boolean;
v_count integer;
v_querytext text;
v_exporthybriddma boolean;
v_selecteddma integer;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;


	--  Get system & user variables
	v_usedmapattern = (SELECT value FROM config_param_user WHERE parameter='inp_options_use_dma_pattern' AND cur_user=current_user); -- TODO: check if this is needed
	v_buildupmode = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_buildup_mode' AND cur_user=current_user); -- TODO: check if this is needed
	v_networkmode = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_networkmode' AND cur_user=current_user);
	v_minlength := (SELECT value FROM config_param_system WHERE parameter = 'epa_arc_minlength');
	v_forcereservoirsoninlets := (SELECT value::json->>'forceReservoirsOnInlets' FROM config_param_user WHERE parameter = 'inp_options_debug' AND cur_user=current_user); -- TODO: check if this is needed
	v_forcetanksoninlets := (SELECT value::json->>'forceTanksOnInlets' FROM config_param_user WHERE parameter = 'inp_options_debug' AND cur_user=current_user); -- TODO: check if this is needed
	v_exporthybriddma := (SELECT value::boolean FROM config_param_system WHERE parameter = 'epa_export_hybrid_dma');
	v_selecteddma := (SELECT value::integer FROM config_param_user WHERE parameter = 'inp_options_selecteddma' AND cur_user=current_user);

	raise notice 'Delete previous values from same result';

	v_querytext = 'INSERT INTO temp_t_arc (arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, roughness, 
		length, diameter, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, age, family, builtdate)
		SELECT
			a.arc_id,
			node_1,
			node_2,
			cat_arc.arc_type,
			arccat_id,
			epa_type,
			a.sector_id,
			COALESCE(vf.p_state, a.state),
			a.state_type,
			a.annotation,
			COALESCE(inp_pipe.custom_roughness, cat_mat_roughness.roughness) as roughness,
			COALESCE(a.custom_length, st_length2d(a.the_geom)) as length,
			COALESCE(inp_pipe.custom_dint, cat_arc.dint) as dint,
			a.the_geom,
			a.expl_id,
			a.dma_id,
			presszone_id,
			dqa_id,
			minsector_id,
			(CASE WHEN a.builtdate IS NOT NULL THEN (now()::date - a.builtdate)/30 ELSE 0 END),
			cat_material."family",
			a.builtdate
		FROM arc a
			JOIN vf_arc vf ON vf.arc_id = a.arc_id 
			JOIN cat_arc ON a.arccat_id = cat_arc.id
			LEFT JOIN cat_material ON cat_arc.matcat_id = cat_material.id
			LEFT JOIN inp_pipe ON a.arc_id = inp_pipe.arc_id
			LEFT JOIN cat_mat_roughness ON cat_mat_roughness.matcat_id = cat_material.id
		';

	IF v_networkmode = 1 OR v_selecteddma IS NOT NULL THEN
		v_querytext = v_querytext || ' JOIN dma ON dma.dma_id = a.dma_id';
	END IF;

	v_querytext := v_querytext ||
		' WHERE (now()::date - (CASE WHEN builtdate IS NULL THEN ''1900-01-01''::date ELSE builtdate END))/365 >= cat_mat_roughness.init_age
		AND (now()::date - (CASE WHEN builtdate IS NULL THEN ''1900-01-01''::date ELSE builtdate END))/365 <= cat_mat_roughness.end_age
		AND sector_id > 0
		AND st_length(a.the_geom) >= '||v_minlength;

	IF v_networkmode = 1 THEN
		IF v_exporthybriddma THEN
			v_querytext = v_querytext || ' AND dma.dma_type IN (SELECT id FROM edit_typevalue WHERE typevalue = ''dma_type'' AND (idval = ''TRANSMISSION'' OR idval = ''HYBRID''))';
		ELSE
			v_querytext = v_querytext || ' AND dma.dma_type = (SELECT id FROM edit_typevalue WHERE typevalue = ''dma_type'' AND idval = ''TRANSMISSION'')';
		END IF;
	END IF;

	IF v_selecteddma IS NOT NULL THEN
		v_querytext = v_querytext || ' AND dma.dma_id = '||v_selecteddma;
	END IF;

	EXECUTE v_querytext;


	raise notice 'Inserting nodes on temp_t_node table';

	-- the strategy of selector_sector is not used for nodes. The reason is to enable the posibility to export the sector=-1. In addition using this it's impossible to export orphan nodes
	INSERT INTO temp_t_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, the_geom, expl_id, dma_id, presszone_id, dqa_id, minsector_id, age, builtdate)
		SELECT
			n.node_id,
			top_elev,
			top_elev - depth AS elev,
			node_type,
			nodecat_id,
			epa_type,
			n.sector_id,
			COALESCE(vf_node.p_state, n.state) AS state,
			n.state_type,
			n.annotation,
			n.the_geom,
			n.expl_id,
			n.dma_id,
			presszone_id,
			dqa_id,
			minsector_id,
			(CASE
				WHEN n.builtdate IS NOT NULL THEN (now()::date - n.builtdate) / 30
				ELSE 0
			END) AS age,
			n.builtdate
		FROM node n
			JOIN vf_node ON n.node_id = vf_node.node_id
			JOIN cat_node c ON c.id = nodecat_id
		WHERE EXISTS (
			SELECT 1
			FROM temp_t_arc a
			WHERE
				a.node_1 = n.node_id::text
				OR a.node_2 = n.node_id::text
		);

	-- create link exit
	IF v_networkmode in (3,4) THEN
		PERFORM gw_fct_linkexitgenerator(1);
	END IF;

	IF v_networkmode = 4 THEN

		INSERT INTO temp_t_node (node_id, top_elev, elev, node_type, nodecat_id, epa_type, sector_id, state, state_type, annotation, the_geom, expl_id, 
			dma_id, presszone_id, dqa_id, minsector_id, age, builtdate)
			SELECT
				c.connec_id,
				top_elev,
				top_elev - depth AS elev,
				'CONNEC',
				conneccat_id,
				epa_type,
				c.sector_id,
				COALESCE(vf_connec.p_state, c.state),
				c.state_type,
				c.annotation,
				c.the_geom,
				c.expl_id,
				c.dma_id,
				c.presszone_id,
				c.dqa_id,
				c.minsector_id,
				CASE
					WHEN c.builtdate IS NOT NULL THEN (now()::date - c.builtdate) / 30
					ELSE 0
				END AS age,
				c.builtdate
			FROM connec c
				JOIN vf_connec ON c.connec_id = vf_connec.connec_id
			WHERE EXISTS (
				SELECT 1
				FROM temp_t_arc a
				WHERE a.arc_id = c.arc_id::text
			);
	END IF;

	raise notice 'Inserting links on temp_t_arc table';
	IF v_networkmode =  4 THEN
		-- TODO: check if pjoint filter is needed and check JOINS
		-- this need to be solved here in spite of fill_data functions because some kind of incosnstency done on this function on previous lines
		INSERT INTO temp_t_arc (arc_id, node_1, node_2, arc_type, arccat_id, epa_type, sector_id, state, state_type, annotation, roughness, length, diameter, the_geom,
			expl_id, dma_id, presszone_id, dqa_id, minsector_id, status, minorloss, age, family, builtdate)
			SELECT
				concat('CO', c.connec_id) AS arc_id,
				c.connec_id AS node_1,
				CASE
					WHEN l.exit_type = 'ARC' THEN concat('VN', l.link_id)
					WHEN l.exit_type IN ('NODE', 'CONNEC') THEN l.exit_id::text
					ELSE COALESCE(vfc.p_pjoint_id, c.pjoint_id)::text
				END AS node_2,
				'LINK' AS arc_type,
				conneccat_id,
				'PIPE' AS epa_type,
				l.sector_id,
				l.state,
				l.state_type,
				l.annotation,
				COALESCE(custom_roughness, roughness) AS roughness,
				COALESCE(l.custom_length, st_length(l.the_geom)) AS length,
				COALESCE(custom_dint, dint) AS diameter,
				l.the_geom,
				c.expl_id,
				c.dma_id,
				c.presszone_id,
				c.dqa_id,
				c.minsector_id,
				inp_connec.status,
				inp_connec.minorloss,
				(CASE WHEN c.builtdate IS NOT NULL THEN (now()::date - c.builtdate) / 30 ELSE 0 END) AS age,
				cat_material."family",
				c.builtdate
			FROM link l
				JOIN vf_link vfl ON l.link_id = vfl.link_id
				JOIN connec c ON c.connec_id = l.feature_id
				JOIN vf_connec vfc ON vfc.connec_id = c.connec_id
				JOIN inp_connec ON l.feature_id = inp_connec.connec_id
				JOIN cat_link ON cat_link.id = l.linkcat_id
				LEFT JOIN cat_mat_roughness ON cat_mat_roughness.matcat_id = cat_link.matcat_id
				LEFT JOIN cat_material ON cat_material.id = cat_link.matcat_id
			WHERE
				(now()::date - (CASE WHEN c.builtdate IS NULL THEN '1900-01-01'::date ELSE c.builtdate END)) / 365 >= cat_mat_roughness.init_age
				AND (now()::date - (CASE WHEN c.builtdate IS NULL THEN '1900-01-01'::date ELSE c.builtdate END)) / 365 <= cat_mat_roughness.end_age
				AND COALESCE(vfc.p_pjoint_id, c.pjoint_id) IS NOT NULL
				AND COALESCE(vfc.p_pjoint_type, c.pjoint_type) IS NOT NULL;
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
	GROUP BY n.node_id;

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

	IF v_selecteddma IS NOT NULL THEN
		WITH to_update AS (
			select
				elem->>'nodeParent' AS node_parent,
				jsonb_array_length(elem->'toArc') > 0 AS has_to_arc
			FROM dma d
			CROSS JOIN LATERAL jsonb_array_elements((d.graphconfig->'use')::jsonb) AS elem
			where dma_id = v_selecteddma
		)
		UPDATE temp_t_node
		SET epa_type = 'RESERVOIR',
		top_elev = s.head, elev = s.head, pattern_id=s.pattern_id
		FROM to_update v
		JOIN ve_epa_shortpipe s ON s.node_id::text = v.node_parent
		WHERE temp_t_node.node_id=s.node_id::text AND EXISTS (SELECT 1 FROM t_numarcs WHERE t_numarcs.node_id=s.node_id::text
		AND t_numarcs.numarcs = 1)
		AND v.has_to_arc IS TRUE;
	END IF;

	RETURN 1;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
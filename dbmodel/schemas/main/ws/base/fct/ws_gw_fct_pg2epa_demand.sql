/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2330

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_demand(result_id_var character varying)  RETURNS integer AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_pg2epa_demand('v45')
*/

DECLARE

v_rec record;
v_demand double precision;
v_epaunits double precision;
v_units	text;
v_sql text;
v_patternmethod integer;
v_queryfrom text;
v_networkmode integer;
v_deafultpattern text;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get user values
	v_units =  (SELECT value FROM config_param_user WHERE parameter='inp_options_units' AND cur_user=current_user);
	v_patternmethod = (SELECT value FROM config_param_user WHERE parameter='inp_options_patternmethod' AND cur_user=current_user);
	v_networkmode = (SELECT value FROM config_param_user WHERE parameter='inp_options_networkmode' AND cur_user=current_user);
	v_deafultpattern = Coalesce((SELECT value FROM config_param_user WHERE parameter='inp_options_pattern' AND cur_user=current_user),'');


	EXECUTE 'SELECT (value::json->>'||quote_literal(v_units)||')::float FROM config_param_system WHERE parameter=''epa_units_factor'''
		INTO v_epaunits;

	-- Reset values
	UPDATE temp_t_node t SET demand = 0 FROM node n WHERE n.node_id::text = t.node_id AND n.epa_type != 'INLET';
	UPDATE temp_t_node t SET pattern_id = null FROM node n WHERE n.node_id::text = t.node_id AND n.epa_type != 'INLET';

	IF v_networkmode = 2 OR v_networkmode = 1 THEN-- NETWORK

		-- update patterns for nodes
		UPDATE temp_t_node SET pattern_id=a.pattern_id FROM ve_inp_junction a WHERE temp_t_node.node_id=a.node_id::text;

		-- demand on nodes
		UPDATE temp_t_node SET demand=inp_junction.demand FROM inp_junction WHERE temp_t_node.node_id=inp_junction.node_id::text;

		-- demand on valves converted to junction
		UPDATE temp_t_node SET pattern_id = v.demand_pattern_id, demand = v.demand FROM ve_inp_valve v WHERE temp_t_node.node_id = v.node_id::text AND temp_t_node.epa_type = 'JUNCTION';

		-- pattern
		IF v_patternmethod = 11 THEN -- GLOBAL PATTERN
			UPDATE temp_t_node SET pattern_id=v_deafultpattern WHERE pattern_id IS NULL AND epa_type ='JUNCTION';

		ELSIF v_patternmethod = 12 THEN -- SECTOR PATTERN (NODE)
			UPDATE temp_t_node SET pattern_id=sector.pattern_id FROM node JOIN sector ON sector.sector_id=node.sector_id
			WHERE temp_t_node.node_id=node.node_id::text AND temp_t_node.pattern_id IS NULL AND temp_t_node.epa_type ='JUNCTION';

		ELSIF v_patternmethod = 13 THEN -- DMA PATTERN (NODE)
			UPDATE temp_t_node SET pattern_id=dma.pattern_id FROM node JOIN dma ON dma.dma_id=node.dma_id
			WHERE temp_t_node.node_id=node.node_id::text AND temp_t_node.pattern_id IS NULL AND temp_t_node.epa_type ='JUNCTION';

		ELSIF v_patternmethod = 14 THEN -- FEATURE PATTERN (NODE)
			-- do nothing
		END IF;

	ELSIF v_networkmode = 3 THEN -- TRIMED NETWORK

		INSERT INTO temp_t_link (link_id, feature_id, feature_type, state, expl_id, the_geom, linkcat_id, state_type)
		SELECT link_id, feature_id, feature_type, state, expl_id, the_geom, linkcat_id, state_type from ve_link;


		-- insertar all connecs
		-- Use the merged vnode mapping if available, otherwise use the original vnode id
		INSERT INTO temp_t_demand (dscenario_id, feature_id, demand, pattern_id, source)
		select 0 ,
			COALESCE(m.merged_vnode_id, concat('VN',link_id)) as feature_id,
			demand,
			pattern_id,
			concat('CONNEC ', connec_id)
		from temp_t_link l
		join inp_connec on connec_id = l.feature_id
		LEFT JOIN temp_vnode_mapping m ON m.original_vnode_id = concat('VN',link_id)
		WHERE demand IS NOT NULL AND demand <> 0;

		-- update those connecs that is other link_id
		FOR v_rec in select * from temp_t_demand where feature_id not in (select node_id from temp_t_node)
		LOOP
			UPDATE temp_t_demand SET feature_id = f.feature_id
			FROM
			(SELECT concat('VN',c2.link_id) as feature_id FROM temp_t_link c1, temp_t_link c2 where st_dwithin(c1.the_geom, c2.the_geom, 100) and c1.link_id <> c2.link_id
			and concat('VN',c1.link_id) = v_rec.feature_id and concat('VN',c2.link_id) in (SELECT feature_id FROM temp_t_demand)
			order by st_distance ( c1.the_geom, c2.the_geom) asc LIMIT 1) f
			WHERE temp_t_demand.feature_id = v_rec.feature_id;
		END LOOP;

	ELSIF v_networkmode = 4 THEN

		-- update patterns for connecs with associated link
		UPDATE temp_t_node SET pattern_id=c.pattern_id FROM ve_inp_connec c WHERE connec_id::text = node_id  AND temp_t_node.epa_type ='JUNCTION';

		-- update patterns for pattern on connecs over arc
		UPDATE temp_t_node SET pattern_id=c.pattern_id FROM ve_inp_connec c WHERE concat('VC',connec_id) = node_id  AND temp_t_node.epa_type ='JUNCTION';

		-- demand on connecs with associated link
		UPDATE temp_t_node SET demand=v.demand FROM ve_inp_connec v WHERE connec_id::text = node_id  AND temp_t_node.epa_type ='JUNCTION';

		-- demand on connecs over arc
		UPDATE temp_t_node SET demand=v.demand FROM ve_inp_connec v WHERE concat('VC',connec_id) = node_id  AND temp_t_node.epa_type ='JUNCTION';

		-- pattern
		IF v_patternmethod = 11 THEN -- GLOBAL PATTERN
			UPDATE temp_t_node SET pattern_id=v_deafultpattern WHERE temp_t_node.pattern_id IS NULL AND temp_t_node.epa_type ='JUNCTION';

		ELSIF v_patternmethod  = 12 THEN -- SECTOR PATTERN (CONNEC)

			-- pattern on connecs with associated link
			UPDATE temp_t_node SET pattern_id=sector.pattern_id
			FROM ve_inp_connec JOIN sector USING (sector_id) WHERE connec_id = node_id  AND temp_t_node.pattern_id IS NULL AND temp_t_node.epa_type ='JUNCTION';

			-- pattern on connecs over arc
			UPDATE temp_t_node SET pattern_id=sector.pattern_id
			FROM ve_inp_connec JOIN sector USING (sector_id) WHERE concat('VC',connec_id) = node_id  AND temp_t_node.pattern_id IS NULL AND temp_t_node.epa_type ='JUNCTION';

		ELSIF v_patternmethod  = 13 THEN -- DMA PATTERN (CONNEC)

			-- pattern on connecs with associated link
			UPDATE temp_t_node SET pattern_id=dma.pattern_id
			FROM ve_inp_connec JOIN dma USING (dma_id) WHERE connec_id = node_id  AND temp_t_node.pattern_id IS NULL AND temp_t_node.epa_type ='JUNCTION';

			-- pattern on connecs over arc
			UPDATE temp_t_node SET pattern_id=dma.pattern_id
			FROM ve_inp_connec JOIN dma USING (dma_id) WHERE concat('VC',connec_id) = node_id AND temp_t_node.pattern_id IS NULL AND temp_t_node.epa_type ='JUNCTION';

		ELSIF v_patternmethod = 14 THEN -- FEATURE PATTERN (CONNEC)

			-- do nothing
		END IF;
	END IF;

	UPDATE temp_t_node SET demand = 0 WHERE demand is null;

RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
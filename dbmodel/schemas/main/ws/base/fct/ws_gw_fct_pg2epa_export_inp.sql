/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2526

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_utils_csv2pg_export_epanet_inp(character varying, text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_export_inp(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "useNetworkGeom":"false"}}$$)
SELECT gw_fct_pg2epa_export_inp($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1"}}$$)

-- fid:141

*/

DECLARE

rec_table record;

column_number integer;
id_last integer;
num_col_rec record;
num_column text;
v_result varchar;
title_aux varchar;
v_fid integer=141;
v_patternmethod	integer;
v_networkmode integer;
v_valvemode integer;
v_patternmethodval text;
v_valvemodeval text;
v_networkmodeval text;
v_return json;
v_client_epsg integer;
v_message text;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get input parameters
	v_result = (p_data->>'data')::json->>'resultId';
	v_client_epsg = (p_data->>'client')::json->>'epsg';

	-- validate QGIS project CRS for INP export (projected CRS required)
	IF v_client_epsg IS NULL OR NOT EXISTS (SELECT 1 FROM spatial_ref_sys WHERE srid = v_client_epsg) THEN
		SELECT error_message INTO v_message FROM sys_message WHERE id = 4370;
		RETURN ('{"status":"Failed","message":{"level":1, "text":"'||v_message||'"}}')::json;
	END IF;

	IF gw_fct_is_geographic_srid(v_client_epsg) IS TRUE THEN
		SELECT error_message INTO v_message FROM sys_message WHERE id = 4371;
		RETURN ('{"status":"Failed","message":{"level":1, "text":"'||v_message||'"}}')::json;
	END IF;

	CREATE OR REPLACE TEMP VIEW vi_t_controls AS
	 SELECT c.text
	   FROM ( SELECT inp_controls.id,
		    inp_controls.text
		   FROM selector_sector, inp_controls
		  WHERE selector_sector.sector_id = inp_controls.sector_id AND selector_sector.cur_user = "current_user"()::text AND inp_controls.active IS NOT FALSE
		UNION
		 SELECT d.id,
		    d.text
		   FROM selector_sector s, ve_inp_dscenario_controls d
		  WHERE s.sector_id = d.sector_id AND s.cur_user = "current_user"()::text AND d.active IS NOT FALSE
	  ORDER BY 1) c  ORDER BY c.id;

	CREATE OR REPLACE TEMP VIEW vi_t_coordinates AS
		SELECT node_id,
		NULL::numeric(16,3) AS xcoord,
		NULL::numeric(16,3) AS ycoord,
		the_geom
		FROM temp_t_node;

	CREATE OR REPLACE TEMP VIEW vi_t_curves AS
		SELECT
		CASE
		    WHEN a.x_value IS NULL THEN a.curve_type::character varying(16)
		    ELSE a.curve_id
		END AS curve_id,
		a.x_value::numeric(12,4) AS x_value,
		a.y_value::numeric(12,4) AS y_value,
		NULL::text AS other
		FROM ( SELECT row_number() OVER (ORDER BY a_1.id) AS rid,
		    a_1.id,
		    a_1.curve_id,
		    a_1.curve_type,
		    a_1.x_value,
		    a_1.y_value
		   FROM ( SELECT DISTINCT ON (inp_curve_value.curve_id) ( SELECT min(sub.id) AS min
				   FROM inp_curve_value sub
				  WHERE sub.curve_id::text = inp_curve_value.curve_id::text) AS id,
			    inp_curve_value.curve_id,
			    concat(';', inp_curve.curve_type, ':', inp_curve.descript) AS curve_type,
			    NULL::numeric AS x_value,
			    NULL::numeric AS y_value
			   FROM inp_curve
			     JOIN inp_curve_value ON inp_curve_value.curve_id::text = inp_curve.id::text
			UNION
			 SELECT inp_curve_value.id,
			    inp_curve_value.curve_id,
			    inp_curve.curve_type,
			    inp_curve_value.x_value,
			    inp_curve_value.y_value
			   FROM inp_curve_value
			     JOIN inp_curve ON inp_curve_value.curve_id::text = inp_curve.id::text
		  ORDER BY 1, 4 DESC) a_1) a
		WHERE (a.curve_id::text IN ( SELECT temp_t_node.addparam::json ->> 'curve_id'::text
		   FROM temp_t_node UNION SELECT temp_t_arc.addparam::json ->> 'curve_id'::text  FROM temp_t_arc)) ORDER BY a.rid, NULL::text;

	
	CREATE OR REPLACE TEMP VIEW vi_t_demands AS
		SELECT temp_t_demand.feature_id,
		temp_t_demand.demand,
		temp_t_demand.pattern_id,
		concat(';', temp_t_demand.dscenario_id, ' ', temp_t_demand.source, ' ', temp_t_demand.demand_type) AS other
		FROM temp_t_demand
		JOIN temp_t_node ON temp_t_demand.feature_id = temp_t_node.node_id
		where temp_t_demand.demand is not null
		ORDER BY temp_t_demand.feature_id, (concat(';', temp_t_demand.dscenario_id, ' ', temp_t_demand.source, ' ', temp_t_demand.demand_type));


	CREATE OR REPLACE TEMP VIEW vi_t_emitters AS
	SELECT node_id, addparam::json->>'emitter_coeff' as emitter_coeff FROM temp_t_node
	WHERE (addparam::json->>'emitter_coeff')::numeric > 0;


	CREATE OR REPLACE TEMP VIEW vi_t_energy AS
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'EFFIC'::text AS idval,  p.effic_curve_id AS energyvalue FROM inp_pump p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.effic_curve_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PRICE'::text, inp_pump.energy_price::text FROM inp_pump LEFT JOIN temp_arc ON concat(inp_pump.node_id, '_n2a') = temp_arc.arc_id::text WHERE inp_pump.energy_price IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PATTERN'::text, inp_pump.energy_pattern_id FROM inp_pump LEFT JOIN temp_arc ON concat(inp_pump.node_id, '_n2a') = temp_arc.arc_id::text WHERE inp_pump.energy_pattern_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'EFFIC'::text,p.effic_curve_id FROM inp_pump_additional p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.effic_curve_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PRICE'::text, p.energy_price::text FROM inp_pump_additional p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.energy_price IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PATTERN'::text, p.energy_pattern_id FROM inp_pump_additional p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.energy_pattern_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'EFFIC'::text,p.effic_curve_id FROM inp_virtualpump p LEFT JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id::text WHERE p.effic_curve_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PRICE'::text, p.energy_price::text FROM inp_virtualpump p LEFT JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id::text WHERE p.energy_price IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PATTERN'::text, p.energy_pattern_id FROM inp_virtualpump p LEFT JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id WHERE p.energy_pattern_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'EFFIC'::text, p.effic_curve_id FROM inp_dscenario_pump p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.effic_curve_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PRICE'::text, p.energy_price::text FROM inp_dscenario_pump p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.energy_price IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PATTERN'::text, p.energy_pattern_id FROM inp_dscenario_pump p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.energy_pattern_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'EFFIC'::text, p.effic_curve_id FROM inp_dscenario_pump_additional p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.effic_curve_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PRICE'::text, p.energy_price::text  FROM inp_dscenario_pump_additional p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a') = temp_arc.arc_id::text WHERE p.energy_price IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PATTERN'::text, p.energy_pattern_id  FROM inp_dscenario_pump_additional p LEFT JOIN temp_arc ON concat(p.node_id, '_n2a')::text = temp_arc.arc_id WHERE p.energy_pattern_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'EFFIC'::text, p.effic_curve_id FROM inp_dscenario_virtualpump p LEFT JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id::text WHERE p.effic_curve_id IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PRICE'::text, p.energy_price::text  FROM inp_dscenario_virtualpump p LEFT JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id WHERE p.energy_price IS NOT NULL
	UNION
	 SELECT concat('PUMP ', temp_arc.arc_id) AS pump_id,'PATTERN'::text, p.energy_pattern_id  FROM inp_dscenario_virtualpump p LEFT JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id WHERE p.energy_pattern_id IS NOT NULL
	UNION
	 SELECT sys_param_user.idval AS pump_id, config_param_user.value, NULL::text  FROM config_param_user JOIN sys_param_user ON sys_param_user.id = config_param_user.parameter::text
	 WHERE (config_param_user.parameter::text = 'inp_energy_price'::text OR config_param_user.parameter::text = 'inp_energy_pump_effic'::text OR config_param_user.parameter::text = 'inp_energy_price_pattern'::text)
	 AND config_param_user.value IS NOT NULL AND config_param_user.cur_user::name = CURRENT_USER ORDER BY 1;


	CREATE OR REPLACE TEMP VIEW vi_t_junctions AS
	SELECT temp_t_node.node_id,
		CASE
			WHEN temp_t_node.elev IS NOT NULL THEN temp_t_node.elev
			ELSE temp_t_node.top_elev
		END AS elevation,
		temp_t_node.demand,
		temp_t_node.pattern_id,
		concat(';', temp_t_node.sector_id, ' ', COALESCE(temp_t_node.presszone_id, 0), ' ', COALESCE(temp_t_node.dma_id, 0), ' ', COALESCE(temp_t_node.dqa_id, 0), ' ', COALESCE(temp_t_node.minsector_id, 0), ' ', temp_t_node.node_type) AS other
	FROM temp_t_node
	WHERE temp_t_node.epa_type::text <> ALL (ARRAY['RESERVOIR'::character varying::text, 'TANK'::character varying::text])
	ORDER BY temp_t_node.node_id;


	CREATE OR REPLACE TEMP VIEW vi_t_labels AS
	 SELECT inp_label.xcoord, inp_label.ycoord, inp_label.label, inp_label.node_id FROM inp_label;


	CREATE OR REPLACE TEMP VIEW vi_t_mixing AS
     SELECT inp_tank.node_id,
        inp_tank.mixing_model,
        inp_tank.mixing_fraction
       FROM inp_tank
         LEFT JOIN temp_t_node ON inp_tank.node_id::text = temp_t_node.node_id
      WHERE inp_tank.mixing_model IS NOT NULL OR inp_tank.mixing_fraction IS NOT NULL
    UNION
     SELECT inp_dscenario_tank.node_id,
        inp_dscenario_tank.mixing_model,
        inp_dscenario_tank.mixing_fraction
       FROM inp_dscenario_tank
         LEFT JOIN temp_t_node ON inp_dscenario_tank.node_id::text = temp_t_node.node_id
      WHERE inp_dscenario_tank.mixing_model IS NOT NULL OR inp_dscenario_tank.mixing_fraction IS NOT NULL
    UNION
     SELECT inp_inlet.node_id,
        inp_inlet.mixing_model,
        inp_inlet.mixing_fraction
       FROM inp_inlet
         LEFT JOIN temp_t_node ON inp_inlet.node_id::text = temp_t_node.node_id
      WHERE (inp_inlet.mixing_model IS NOT NULL OR inp_inlet.mixing_fraction IS NOT NULL) AND temp_t_node.epa_type::text = 'TANK'::text
    UNION
     SELECT inp_dscenario_inlet.node_id,
        inp_dscenario_inlet.mixing_model,
        inp_dscenario_inlet.mixing_fraction
       FROM inp_dscenario_inlet
         LEFT JOIN temp_t_node ON inp_dscenario_inlet.node_id::text = temp_t_node.node_id
      WHERE (inp_dscenario_inlet.mixing_model IS NOT NULL OR inp_dscenario_inlet.mixing_fraction IS NOT NULL) AND temp_t_node.epa_type::text = 'TANK'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_options AS
	 SELECT a.parameter,
	    a.value
	   FROM ( SELECT a_1.parameter,
		    a_1.value,
			CASE
			    WHEN a_1.parameter = 'UNITS'::text THEN 1
			    ELSE 2
			END AS t
		   FROM ( SELECT a_1_1.idval AS parameter,
				CASE
				    WHEN a_1_1.idval = 'UNBALANCED'::text AND b.value = 'CONTINUE'::text THEN concat(b.value, ' ', ( SELECT config_param_user.value
				       FROM config_param_user
				      WHERE config_param_user.parameter::text = 'inp_options_unbalanced_n'::text AND config_param_user.cur_user::name = "current_user"()))
				    WHEN a_1_1.idval = 'QUALITY'::text AND b.value = 'TRACE'::text THEN concat(b.value, ' ', ( SELECT config_param_user.value
				       FROM config_param_user
				      WHERE config_param_user.parameter::text = 'inp_options_node_id'::text AND config_param_user.cur_user::name = "current_user"()))
				    WHEN a_1_1.idval = 'HYDRAULICS'::text AND (b.value = 'USE'::text OR b.value = 'SAVE'::text) THEN concat(b.value, ' ', ( SELECT config_param_user.value
				       FROM config_param_user
				      WHERE config_param_user.parameter::text = 'inp_options_hydraulics_fname'::text AND config_param_user.cur_user::name = "current_user"()))
				    WHEN a_1_1.idval = 'HYDRAULICS'::text AND b.value = 'NONE'::text THEN NULL::text
				    ELSE b.value
				END AS value
			   FROM sys_param_user a_1_1
			     JOIN config_param_user b ON a_1_1.id = b.parameter::text
			  WHERE (a_1_1.layoutname = ANY (ARRAY['lyt_general_1'::text, 'lyt_general_2'::text, 'lyt_hydraulics_1'::text, 'lyt_hydraulics_2'::text]))
			   AND (a_1_1.idval <> ALL (ARRAY['UNBALANCED_N'::text, 'NODE_ID'::text, 'HYDRAULICS_FNAME'::text])) AND b.cur_user::name = "current_user"()
			   AND b.value IS NOT NULL AND a_1_1.idval <> 'VALVE_MODE_MINCUT_RESULT'::text AND b.parameter::text <> 'PATTERN'::text AND b.value <> 'NULLVALUE'::text) a_1
		  WHERE a_1.parameter <> 'HYDRAULICS'::text OR a_1.parameter = 'HYDRAULICS'::text AND a_1.value IS NOT NULL) a
	  ORDER BY a.t;


	CREATE OR REPLACE TEMP VIEW vi_t_patterns AS
		SELECT a.pattern_id, a.factor_1, a.factor_2, a.factor_3, a.factor_4,  a.factor_5, a.factor_6, a.factor_7, a.factor_8, a.factor_9,
		a.factor_10,  a.factor_11, a.factor_12, a.factor_13, a.factor_14, a.factor_15, a.factor_16, a.factor_17, a.factor_18
		FROM t_rpt_inp_pattern_value a ORDER BY a.id;


	CREATE OR REPLACE TEMP VIEW vi_t_pipes AS
	 SELECT arc_id, node_1, node_2, length, diameter, roughness, minorloss, status::character varying(30) AS status,
	 concat(';', sector_id, ' ', COALESCE(presszone_id, 0), ' ', COALESCE(dma_id, 0), ' ', COALESCE(dqa_id, 0), ' ', COALESCE(minsector_id, 0), ' ', arccat_id) AS other
	 FROM temp_t_arc  WHERE epa_type::text = ANY (ARRAY['PIPE'::character varying::text, 'SHORTPIPE'::character varying::text, 'NODE2NODE'::character varying::text, 'FRSHORTPIPE'::character varying::text]);



	CREATE OR REPLACE TEMP VIEW vi_t_valves AS
	 SELECT DISTINCT ON (a.arc_id) a.arc_id,
	    a.node_1,
	    a.node_2,
	    a.diameter,
	    a.valve_type,
	    a.setting,
	    a.minorloss,
	    concat(';', a.sector_id, ' ', COALESCE(a.presszone_id, 0), ' ', COALESCE(a.dma_id, 0), ' ', COALESCE(a.dqa_id, 0), ' ', COALESCE(a.minsector_id, 0), ' ', a.arccat_id) AS other
	   FROM (SELECT arc_id,
		    node_1,
		    node_2,
		    diameter,
		    addparam::json ->> 'valve_type'::text AS valve_type,
		    addparam::json ->> 'setting'::text AS setting,
		    minorloss,
		    sector_id,
		    dma_id,
		    presszone_id,
		    dqa_id,
		    minsector_id,
		    arccat_id
		   FROM temp_t_arc WHERE addparam::json ->> 'valve_type'::text IN ('PRV', 'PSV', 'PBV', 'FCV', 'TCV', 'GPV')
		UNION
		 SELECT arc_id,
		    node_1,
		    node_2,
		    diameter,
		    'PRV'::character varying(18) AS valve_type,
		    addparam::json ->> 'setting'::text AS setting,
		    minorloss,
		    sector_id,
		    dma_id,
		    presszone_id,
		    dqa_id,
		    minsector_id,
		    arccat_id
		   FROM temp_t_arc t JOIN inp_pump ON arc_id::text = concat(inp_pump.node_id, '_n2a_4')
		UNION
		 SELECT arc_id,
		    node_1,
		    node_2,
		    diameter,
		    'PRV'::character varying(18) AS valve_type,
		    addparam::json ->> 'setting'::text AS setting,
		    minorloss,
		    sector_id,
		    dma_id,
		    presszone_id,
		    dqa_id,
		    minsector_id,
		    arccat_id
		   FROM temp_t_arc t JOIN inp_frpump ON arc_id::text = concat(inp_frpump.element_id::text, '_n2a_1')) a;



	CREATE OR REPLACE TEMP VIEW vi_t_pumps AS
	 SELECT arc_id, node_1, node_2,
		CASE
		    WHEN (addparam::json ->> 'power'::text) <> ''::text THEN ('POWER'::text || ' '::text) || (addparam::json ->> 'power'::text)
		    ELSE NULL::text
		END AS power,
		CASE
		    WHEN (addparam::json ->> 'curve_id'::text) <> ''::text THEN ('HEAD'::text || ' '::text) || (addparam::json ->> 'curve_id'::text)
		    ELSE NULL::text
		END AS head,
		CASE
		    WHEN (addparam::json ->> 'speed'::text) <> ''::text THEN ('SPEED'::text || ' '::text) || (addparam::json ->> 'speed'::text)
		    ELSE NULL::text
		END AS speed,
		CASE
		    WHEN (addparam::json ->> 'pattern'::text) <> ''::text THEN ('PATTERN'::text || ' '::text) || (addparam::json ->> 'pattern'::text)
		    ELSE NULL::text
		END AS pattern_id,
	    concat(';', sector_id, ' ', dma_id, ' ', presszone_id, ' ', dqa_id, ' ', minsector_id, ' ', arccat_id) AS other
	   FROM temp_t_arc
	  WHERE (epa_type::text = ANY (ARRAY['PUMP'::text, 'VIRTUALPUMP'::text])) AND NOT (arc_id::text IN ( SELECT arc_id FROM vi_t_valves))
	  UNION
	  SELECT arc_id, node_1, node_2,
	  	CASE
		    WHEN (addparam::json ->> 'power'::text) <> ''::text THEN ('POWER'::text || ' '::text) || (addparam::json ->> 'power'::text)
		    ELSE NULL::text
		END AS power,
		CASE
		    WHEN (addparam::json ->> 'curve_id'::text) <> ''::text THEN ('HEAD'::text || ' '::text) || (addparam::json ->> 'curve_id'::text)
		    ELSE NULL::text
		END AS head,
		CASE
		    WHEN (addparam::json ->> 'speed'::text) <> ''::text THEN ('SPEED'::text || ' '::text) || (addparam::json ->> 'speed'::text)
		    ELSE NULL::text
		END AS speed,
		CASE
		    WHEN (addparam::json ->> 'pattern'::text) <> ''::text THEN ('PATTERN'::text || ' '::text) || (addparam::json ->> 'pattern'::text)
		    ELSE NULL::text
		END AS pattern_id,
	    concat(';', sector_id, ' ', dma_id, ' ', presszone_id, ' ', dqa_id, ' ', minsector_id, ' ', arccat_id) AS other
	   FROM ve_inp_frpump w
			JOIN man_frelem m ON m.element_id = w.element_id
			JOIN temp_t_arc a ON a.arc_id = w.element_id::text
		WHERE (a.arc_type::text = 'NODE2ARC' AND a.epa_type::text = 'FRPUMP'::text) OR (a.arc_type::text = 'DOUBLE-NOD2ARC(PUMP)' AND a.epa_type::text = 'PUMP'::text)
	  ORDER BY arc_id;


	CREATE OR REPLACE TEMP VIEW vi_t_quality AS
	 SELECT inp_junction.node_id,inp_junction.init_quality FROM inp_junction JOIN temp_t_node ON inp_junction.node_id::text = temp_t_node.node_id WHERE inp_junction.init_quality IS NOT NULL
	UNION
	 SELECT inp_dscenario_junction.node_id,inp_dscenario_junction.init_quality FROM inp_dscenario_junction JOIN temp_t_node ON inp_dscenario_junction.node_id::text = temp_t_node.node_id WHERE inp_dscenario_junction.init_quality IS NOT NULL
	UNION
	 SELECT inp_inlet.node_id, inp_inlet.init_quality FROM inp_inlet JOIN temp_t_node ON inp_inlet.node_id::text = temp_t_node.node_id WHERE inp_inlet.init_quality IS NOT NULL
	 UNION
	  SELECT inp_dscenario_inlet.node_id, inp_dscenario_inlet.init_quality FROM inp_dscenario_inlet JOIN temp_t_node ON inp_dscenario_inlet.node_id::text = temp_t_node.node_id WHERE inp_dscenario_inlet.init_quality IS NOT NULL
	UNION
	 SELECT inp_tank.node_id, inp_tank.init_quality FROM inp_tank JOIN temp_t_node ON inp_tank.node_id::text = temp_t_node.node_id WHERE inp_tank.init_quality IS NOT NULL
	 UNION
	 SELECT inp_dscenario_tank.node_id,inp_dscenario_tank.init_quality FROM inp_dscenario_tank JOIN temp_t_node ON inp_dscenario_tank.node_id::text = temp_t_node.node_id WHERE inp_dscenario_tank.init_quality IS NOT NULL
	UNION
	 SELECT inp_reservoir.node_id,inp_reservoir.init_quality FROM inp_reservoir JOIN temp_t_node ON inp_reservoir.node_id::text = temp_t_node.node_id WHERE inp_reservoir.init_quality IS NOT NULL
	 UNION
	 SELECT inp_dscenario_reservoir.node_id, inp_dscenario_reservoir.init_quality FROM inp_dscenario_reservoir JOIN temp_t_node ON inp_dscenario_reservoir.node_id::text = temp_t_node.node_id WHERE inp_dscenario_reservoir.init_quality IS NOT NULL
	UNION
	 SELECT inp_virtualvalve.arc_id AS node_id, inp_virtualvalve.init_quality FROM inp_virtualvalve JOIN temp_t_arc ON inp_virtualvalve.arc_id::text = temp_t_arc.arc_id WHERE inp_virtualvalve.init_quality IS NOT NULL
	 UNION
	  SELECT inp_dscenario_virtualvalve.arc_id AS node_id, inp_dscenario_virtualvalve.init_quality FROM inp_dscenario_virtualvalve JOIN temp_t_arc ON inp_dscenario_virtualvalve.arc_id::text = temp_t_arc.arc_id WHERE inp_dscenario_virtualvalve.init_quality IS NOT NULL;


	CREATE OR REPLACE TEMP VIEW vi_t_reactions AS
	 SELECT 'BULK'::text AS param, inp_pipe.arc_id::text, inp_pipe.bulk_coeff::text AS coeff FROM inp_pipe JOIN temp_arc ON inp_pipe.arc_id::text = temp_arc.arc_id::text WHERE inp_pipe.bulk_coeff IS NOT NULL
	UNION
	 SELECT 'WALL'::text AS param, inp_pipe.arc_id::text, inp_pipe.wall_coeff::text AS coeff FROM inp_pipe JOIN temp_arc ON inp_pipe.arc_id::text = temp_arc.arc_id::text WHERE inp_pipe.wall_coeff IS NOT NULL
	UNION
	 SELECT 'BULK'::text AS param, p.arc_id::text, p.bulk_coeff::text AS coeff  FROM inp_dscenario_pipe p JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id::text WHERE p.bulk_coeff IS NOT NULL
	 UNION
	 SELECT 'WALL'::text AS param, p.arc_id::text, p.wall_coeff::text AS coeff  FROM inp_dscenario_pipe p JOIN temp_arc ON p.arc_id::text = temp_arc.arc_id::text WHERE p.wall_coeff IS NOT NULL
	UNION
	 SELECT 'BULK'::text AS param, p.element_id::text, p.bulk_coeff::text AS coeff  FROM inp_frshortpipe p JOIN temp_arc ON p.element_id::text = temp_arc.arc_id::text WHERE p.bulk_coeff IS NOT NULL
	 UNION
	 SELECT 'WALL'::text AS param, p.element_id::text, p.wall_coeff::text AS coeff  FROM inp_frshortpipe p JOIN temp_arc ON p.element_id::text = temp_arc.arc_id::text WHERE p.wall_coeff IS NOT NULL
	UNION
	 SELECT sys_param_user.idval AS param, NULL::character varying AS arc_id, config_param_user.value::character varying AS coeff FROM config_param_user
	  JOIN sys_param_user ON sys_param_user.id = config_param_user.parameter::text
	  WHERE (config_param_user.parameter::text = 'inp_reactions_bulk_order'::text OR config_param_user.parameter::text = 'inp_reactions_wall_order'::text OR config_param_user.parameter::text = 'inp_reactions_global_bulk'::text OR
	  config_param_user.parameter::text = 'inp_reactions_global_wall'::text OR config_param_user.parameter::text = 'inp_reactions_limit_concentration'::text OR config_param_user.parameter::text = 'inp_reactions_wall_coeff_correlation'::text)
	  AND config_param_user.value IS NOT NULL AND config_param_user.cur_user::name = CURRENT_USER
	  ORDER BY 1;

	CREATE OR REPLACE TEMP VIEW vi_t_report AS
	 SELECT a.idval AS parameter,  b.value  FROM sys_param_user a
	 JOIN config_param_user b ON a.id = b.parameter::text
	 WHERE (a.layoutname = ANY (ARRAY['lyt_reports_1'::text, 'lyt_reports_2'::text])) AND b.cur_user::name = "current_user"() AND b.value IS NOT NULL;

	CREATE OR REPLACE TEMP VIEW vi_t_reservoirs AS
	 SELECT node_id,
		CASE
		    WHEN elev IS NOT NULL THEN elev
		    ELSE top_elev
		END AS head,
	    pattern_id,
	    concat(';', sector_id, ' ', dma_id, ' ', presszone_id, ' ', dqa_id, ' ', minsector_id, ' ', node_type) AS other
	   FROM temp_t_node
	  WHERE epa_type::text = 'RESERVOIR'::text
	  ORDER BY node_id;


	CREATE OR REPLACE TEMP VIEW vi_t_rules AS
	 SELECT c.text FROM ( SELECT inp_rules.id, inp_rules.text FROM selector_sector s, inp_rules  WHERE s.sector_id = inp_rules.sector_id AND s.cur_user = "current_user"()::text AND inp_rules.active IS NOT FALSE
	UNION
	 SELECT d.id, d.text FROM selector_sector s, ve_inp_dscenario_rules d WHERE s.sector_id = d.sector_id AND s.cur_user = "current_user"()::text AND d.active IS NOT FALSE
	  ORDER BY 1) c
	  ORDER BY c.id;


	CREATE OR REPLACE TEMP VIEW vi_t_sources AS
	 SELECT inp_junction.node_id,
	    inp_junction.source_type,
	    inp_junction.source_quality,
	    inp_junction.source_pattern_id
	   FROM inp_junction
	     LEFT JOIN temp_t_node ON inp_junction.node_id::text = temp_t_node.node_id
	  WHERE inp_junction.source_type IS NOT NULL OR inp_junction.source_quality IS NOT NULL OR inp_junction.source_pattern_id IS NOT NULL
	UNION
	 SELECT inp_dscenario_junction.node_id,
	    inp_dscenario_junction.source_type,
	    inp_dscenario_junction.source_quality,
	    inp_dscenario_junction.source_pattern_id
	   FROM inp_dscenario_junction
	     LEFT JOIN temp_t_node ON inp_dscenario_junction.node_id::text = temp_t_node.node_id
	  WHERE inp_dscenario_junction.source_type IS NOT NULL OR inp_dscenario_junction.source_quality IS NOT NULL OR inp_dscenario_junction.source_pattern_id IS NOT NULL
	UNION
	 SELECT inp_tank.node_id,
	    inp_tank.source_type,
	    inp_tank.source_quality,
	    inp_tank.source_pattern_id
	   FROM inp_tank
	     LEFT JOIN temp_t_node ON inp_tank.node_id::text = temp_t_node.node_id
	  WHERE inp_tank.source_type IS NOT NULL OR inp_tank.source_quality IS NOT NULL OR inp_tank.source_pattern_id IS NOT NULL
	UNION
	 SELECT inp_dscenario_tank.node_id,
	    inp_dscenario_tank.source_type,
	    inp_dscenario_tank.source_quality,
	    inp_dscenario_tank.source_pattern_id
	   FROM inp_dscenario_tank
	     LEFT JOIN temp_t_node ON inp_dscenario_tank.node_id::text = temp_t_node.node_id
	  WHERE inp_dscenario_tank.source_type IS NOT NULL OR inp_dscenario_tank.source_quality IS NOT NULL OR inp_dscenario_tank.source_pattern_id IS NOT NULL
	UNION
	 SELECT inp_reservoir.node_id,
	    inp_reservoir.source_type,
	    inp_reservoir.source_quality,
	    inp_reservoir.source_pattern_id
	   FROM inp_reservoir
	     LEFT JOIN temp_t_node ON inp_reservoir.node_id::text = temp_t_node.node_id
	  WHERE inp_reservoir.source_type IS NOT NULL OR inp_reservoir.source_quality IS NOT NULL OR inp_reservoir.source_pattern_id IS NOT NULL
	UNION
	 SELECT inp_dscenario_reservoir.node_id,
	    inp_dscenario_reservoir.source_type,
	    inp_dscenario_reservoir.source_quality,
	    inp_dscenario_reservoir.source_pattern_id
	   FROM inp_dscenario_reservoir
	     LEFT JOIN temp_t_node ON inp_dscenario_reservoir.node_id::text = temp_t_node.node_id
	  WHERE inp_dscenario_reservoir.source_type IS NOT NULL OR inp_dscenario_reservoir.source_quality IS NOT NULL OR inp_dscenario_reservoir.source_pattern_id IS NOT NULL
	UNION
	 SELECT inp_inlet.node_id,
	    inp_inlet.source_type,
	    inp_inlet.source_quality,
	    inp_inlet.source_pattern_id
	   FROM inp_inlet
	     LEFT JOIN temp_t_node ON inp_inlet.node_id::text = temp_t_node.node_id
	  WHERE inp_inlet.source_type IS NOT NULL OR inp_inlet.source_quality IS NOT NULL OR inp_inlet.source_pattern_id IS NOT NULL
	UNION
	 SELECT inp_dscenario_inlet.node_id,
	    inp_dscenario_inlet.source_type,
	    inp_dscenario_inlet.source_quality,
	    inp_dscenario_inlet.source_pattern_id
	   FROM inp_dscenario_inlet
	     LEFT JOIN temp_t_node ON inp_dscenario_inlet.node_id::text = temp_t_node.node_id
	  WHERE inp_dscenario_inlet.source_type IS NOT NULL OR inp_dscenario_inlet.source_quality IS NOT NULL OR inp_dscenario_inlet.source_pattern_id IS NOT NULL;


	CREATE OR REPLACE TEMP VIEW vi_t_status AS
	 SELECT arc_id, status FROM temp_t_arc WHERE (status::text = 'CLOSED'::text OR status::text = 'OPEN'::text) AND epa_type::text = 'VALVE'::text
	UNION
	 SELECT arc_id, status FROM temp_t_arc WHERE status::text = 'CLOSED'::text AND epa_type::text = 'PUMP'::text
	UNION
	 SELECT arc_id, status FROM temp_t_arc WHERE (status::text = 'CLOSED'::text OR status::text = 'OPEN'::text) AND epa_type::text = 'FRVALVE'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_tags AS
	 SELECT inp_tags.feature_type,  inp_tags.feature_id, inp_tags.tag FROM inp_tags ORDER BY inp_tags.feature_type;


	CREATE OR REPLACE TEMP VIEW vi_t_tanks AS
	 SELECT node_id,
		CASE
		    WHEN elev IS NOT NULL THEN elev
		    ELSE top_elev
		END AS elevation,
	    (addparam::json ->> 'initlevel'::text)::numeric AS initlevel,
	    (addparam::json ->> 'minlevel'::text)::numeric AS minlevel,
	    (addparam::json ->> 'maxlevel'::text)::numeric AS maxlevel,
	    (addparam::json ->> 'diameter'::text)::numeric AS diameter,
	    (addparam::json ->> 'minvol'::text)::numeric AS minvol,
		CASE
		    WHEN (addparam::json ->> 'curve_id'::text) IS NULL THEN '*'::text
		    ELSE addparam::json ->> 'curve_id'::text
		END AS curve_id,
	    addparam::json ->> 'overflow'::text AS overflow,
	    concat(';', sector_id, ' ', dma_id, ' ', presszone_id, ' ', dqa_id, ' ', minsector_id, ' ', node_type) AS other
	   FROM temp_t_node WHERE epa_type::text = 'TANK'::text ORDER BY node_id;


	CREATE OR REPLACE TEMP VIEW vi_t_times AS
	 SELECT a.idval AS parameter, b.value FROM sys_param_user a JOIN config_param_user b ON a.id = b.parameter::text
	  WHERE (a.layoutname = ANY (ARRAY['lyt_date_1'::text, 'lyt_date_2'::text])) AND b.cur_user::name = "current_user"() AND b.value IS NOT NULL;


	CREATE OR REPLACE TEMP VIEW vi_t_title AS
		SELECT inp_project_id.title, inp_project_id.date FROM inp_project_id ORDER BY inp_project_id.title;


	CREATE OR REPLACE TEMP VIEW vi_t_vertices AS
	 SELECT arc_id,
	    NULL::numeric(16,3) AS xcoord,
	    NULL::numeric(16,3) AS ycoord,
	    point AS the_geom
	   FROM ( SELECT (st_dumppoints(the_geom)).geom AS point,
		    st_startpoint(the_geom) AS startpoint,
		    st_endpoint(the_geom) AS endpoint,
		    sector_id,
		    arc_id
		   FROM temp_t_arc) arc
	  WHERE (point < startpoint OR point > startpoint) AND (point < endpoint OR point > endpoint);



	-- get parameters to put on header
	SELECT title INTO title_aux FROM inp_project_id where author=current_user;
	SELECT value INTO v_patternmethod FROM config_param_user WHERE parameter = 'inp_options_patternmethod' AND cur_user=current_user;
	SELECT value INTO v_valvemode FROM config_param_user WHERE parameter = 'inp_options_valve_mode' AND cur_user=current_user;
	SELECT value INTO v_networkmode FROM config_param_user WHERE parameter = 'inp_options_networkmode' AND cur_user=current_user;
	SELECT idval INTO v_patternmethodval FROM inp_typevalue WHERE id=v_patternmethod::text AND typevalue ='inp_value_patternmethod';
	SELECT idval INTO v_valvemodeval FROM inp_typevalue WHERE id=v_valvemode::text AND typevalue ='inp_value_opti_valvemode';
	SELECT idval INTO v_networkmodeval FROM inp_typevalue WHERE id=v_networkmode::text AND typevalue ='inp_options_networkmode';

	--writing the header
	INSERT INTO temp_t_csv (source, csv1,fid) VALUES ('header','[TITLE]',v_fid);
	INSERT INTO temp_t_csv (source, csv1,fid) VALUES ('header',concat(';Created by Giswater'),v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Giswater version: ',(SELECT giswater FROM sys_version ORDER BY id DESC LIMIT 1), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Project name: ',title_aux, v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Result name: ',v_result,v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Export mode: ', v_networkmodeval, v_fid );
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Pattern method: ', v_patternmethodval, v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Valve mode: ', v_valvemodeval, v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Default values: ',
	(SELECT value::json->>'status' FROM config_param_user WHERE parameter = 'inp_options_vdefault' AND cur_user = current_user), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Advanced settings: ',
	(SELECT value::json->>'status' FROM config_param_user WHERE parameter = 'inp_options_advancedsettings' AND cur_user = current_user), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Datetime: ',left((date_trunc('second'::text, now()))::text, 19),v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';User: ',current_user, v_fid);

	--node
	FOR rec_table IN SELECT * FROM config_fprocess WHERE fid=v_fid order by orderby
	LOOP
		-- insert header
		INSERT INTO temp_t_csv (csv1,fid) VALUES (NULL,v_fid);
		EXECUTE 'INSERT INTO temp_t_csv(fid,csv1) VALUES ('||v_fid||','''|| rec_table.target||''');';

		-- insert fieldnames
		IF rec_table.tablename = 'vi_t_patterns' THEN
			INSERT INTO temp_t_csv (fid,csv1,csv2) VALUES (141, ';ID', 'Multipliers');
			num_column = 2;
		ELSE
			INSERT INTO temp_t_csv (fid,csv1,csv2,csv3,csv4,csv5,csv6,csv7,csv8,csv9,csv10,csv11,csv12,csv13)
			SELECT v_fid,rpad(concat(';',c1),22),rpad(c2,22),rpad(c3,22),rpad(c4,22),rpad(c5,22),rpad(c6,22),rpad(c7,22),rpad(c8,22),rpad(c9,22),rpad(c10,22),
			rpad(c11,22),rpad(c12,22),rpad(c13,22)
			FROM crosstab('SELECT table_name::text,  data_type::text, column_name::text FROM information_schema.columns WHERE column_name!=''the_geom'' and table_name='''||
			rec_table.tablename||'''::text order by ordinal_position')
			AS rpt(table_name text, c1 text, c2 text, c3 text, c4 text, c5 text, c6 text, c7 text, c8 text, c9 text, c10 text, c11 text, c12 text, c13 text);


			SELECT count(*)::text INTO num_column from information_schema.columns where table_name=rec_table.tablename AND column_name!='the_geom';
		END IF;

		INSERT INTO temp_t_csv (fid) VALUES (141) RETURNING id INTO id_last;

		--add underlines
		FOR num_col_rec IN 1..num_column
		LOOP
			IF num_col_rec=1 then
				EXECUTE 'UPDATE temp_t_csv set csv1=rpad('';----------'',22) WHERE id='||id_last||';';
			ELSE
				EXECUTE 'UPDATE temp_t_csv SET csv'||num_col_rec||'=rpad(''----------'',22) WHERE id='||id_last||';';
			END IF;
		END LOOP;

		-- set legend for other
		UPDATE temp_t_csv SET csv5 = 'sec prz dma dqa mins' where csv5 like '%other%';
		UPDATE temp_t_csv SET csv9 = 'sec prz dma dqa mins' where csv9 like '%other%';
		UPDATE temp_t_csv SET csv8 = 'sec prz dma dqa mins' where csv8 like '%other%';
		UPDATE temp_t_csv SET csv4 = 'dscenario source' where csv4 like '%other%' and csv1 like '%feature_id%';

		-- insert values
		CASE WHEN rec_table.tablename='vi_t_options' and (SELECT value FROM vi_t_options WHERE parameter='hydraulics') is null THEN
			EXECUTE 'INSERT INTO temp_t_csv SELECT nextval(''temp_csv_id_seq''::regclass),'||v_fid||',current_user,'''||rec_table.tablename::text||''',*  FROM '||
			rec_table.tablename||' WHERE parameter!=''hydraulics'';';

		WHEN rec_table.tablename = 'vi_t_coordinates' THEN
			-- on the fly transformation of epsg
			INSERT INTO temp_t_csv SELECT nextval('temp_csv_id_seq'::regclass), v_fid, current_user,'vi_t_coordinates',
			node_id, ROUND(ST_x(ST_transform(the_geom, v_client_epsg))::numeric, 3), ROUND(ST_y(ST_transform(the_geom, v_client_epsg))::numeric, 3)  FROM vi_t_coordinates;

		WHEN rec_table.tablename = 'vi_t_vertices' THEN
			-- on the fly transformation of epsg
			INSERT INTO temp_t_csv SELECT nextval('temp_csv_id_seq'::regclass), v_fid, current_user,'vi_t_vertices',
			arc_id, ROUND(ST_x(ST_transform(the_geom, v_client_epsg))::numeric, 3), ROUND(ST_y(ST_transform(the_geom, v_client_epsg))::numeric, 3)  FROM vi_t_vertices;
		ELSE
			EXECUTE 'INSERT INTO temp_t_csv SELECT nextval(''temp_csv_id_seq''::regclass),'||v_fid||',current_user,'''||rec_table.tablename::text||''',*  FROM '||
			rec_table.tablename||';';
		END CASE;

	END LOOP;

	-- drop views
	DROP VIEW IF EXISTS vi_t_controls;
	DROP VIEW IF EXISTS vi_t_coordinates;
	DROP VIEW IF EXISTS vi_t_curves;
	DROP VIEW IF EXISTS vi_t_demands;
	DROP VIEW IF EXISTS vi_t_emitters;
	DROP VIEW IF EXISTS vi_t_energy;
	DROP VIEW IF EXISTS vi_t_junctions;
	DROP VIEW IF EXISTS vi_t_labels;
	DROP VIEW IF EXISTS vi_t_mixing;
	DROP VIEW IF EXISTS vi_t_options;
	DROP VIEW IF EXISTS vi_t_patterns;
	DROP VIEW IF EXISTS vi_t_pipes;
	DROP VIEW IF EXISTS vi_t_pumps;
	DROP VIEW IF EXISTS vi_t_quality;
	DROP VIEW IF EXISTS vi_t_reactions;
	DROP VIEW IF EXISTS vi_t_report;
	DROP VIEW IF EXISTS vi_t_reservoirs;
	DROP VIEW IF EXISTS vi_t_rules;
	DROP VIEW IF EXISTS vi_t_sources;
	DROP VIEW IF EXISTS vi_t_status;
	DROP VIEW IF EXISTS vi_t_tags;
	DROP VIEW IF EXISTS vi_t_tanks;
	DROP VIEW IF EXISTS vi_t_times;
	DROP VIEW IF EXISTS vi_t_title;
	DROP VIEW IF EXISTS vi_t_valves;
	DROP VIEW IF EXISTS vi_t_vertices;


	-- build return
	select (array_to_json(array_agg(row_to_json(row))))::json
	into v_return
		from ( select text from (
			select id, concat(rpad(csv1,20), ' ', rpad(csv2,20), ' ', rpad(csv3,20), ' ', rpad(csv4,20), ' ', rpad(csv5,20), ' ', rpad(csv6,20), ' ', rpad(csv7,20), ' ',
			rpad(csv8,20), ' ' , rpad(csv9,20), ' ', rpad(csv10,20), ' ', rpad(csv11,20), ' ', rpad(csv12,20))
			as text from temp_t_csv where fid = 141 and cur_user = current_user and source is null
		union
			select id, concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_reactions')
		union
			select id, concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),500))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_junctions')
		union
			select id, concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),500))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_demands')
		union
			select id, concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),500))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_reservoirs')
		union
			select id, concat(rpad(csv1,21),rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),20),
			' ',rpad(coalesce(csv6,''),20),' ', rpad(coalesce(csv7,''),20),' ',rpad(coalesce(csv8,''),20),' ',rpad(coalesce(csv9,''),500))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_tanks')
		union
			select id, concat(rpad(csv1,21),rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),20),
			' ',rpad(coalesce(csv6,''),20),' ', rpad(coalesce(csv7,''),20),' ',rpad(coalesce(csv8,''),20),' ',rpad(coalesce(csv9,''),500))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_pipes')
		union
			select id, concat(rpad(csv1,21),rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),22),' ',rpad(coalesce(csv5,''),22),
			' ',rpad(coalesce(csv6,''),22),' ', rpad(coalesce(csv7,''),22),' ',rpad(coalesce(csv8,''),500))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_pumps')
		union
			select id, concat(rpad(csv1,21),rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),20),
			' ',rpad(coalesce(csv6,''),20),' ', rpad(coalesce(csv7,''),20),' ',rpad(coalesce(csv8,''),500))
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_valves')
		union
			select id, concat(rpad(csv1,22), ' ', csv2)as text from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('header')
		union
			select id, csv1 as text from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_controls','vi_t_rules')
		union
			-- spacer-19 it's used because a rare bug reading epanet when spacer=20 on target [PATTERNS]????
			select id, concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),19),' ', rpad(coalesce(csv3,''),19),' ',rpad(coalesce(csv4,''),19),' ',rpad(coalesce(csv5,''),19),
			' ',rpad(coalesce(csv6,''),19),	' ',rpad(coalesce(csv7,''),19),' ',rpad(coalesce(csv8,''),19),' ',rpad(coalesce(csv9,''),19),' ',rpad(coalesce(csv10,''),19),
			' ',rpad(coalesce(csv11,''),19),' ',rpad(coalesce(csv12,''),19),' ',rpad(csv13,19),' ',rpad(csv14,19),' ',rpad(csv15,19),' ',rpad(csv16,19),' ',rpad(csv17,19)
			,' ',rpad(csv18,19),' ',rpad(csv19,19),' ',rpad(csv20,19)) as text
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_patterns')
		union
			select id, concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),20),
			' ',rpad(coalesce(csv6,''),20),	' ',rpad(coalesce(csv7,''),20),' ',rpad(coalesce(csv8,''),20),' ',rpad(coalesce(csv9,''),20),' ',rpad(coalesce(csv10,''),20),
			' ',rpad(coalesce(csv11,''),20),' ',rpad(coalesce(csv12,''),20),' ',rpad(csv13,20),' ',rpad(csv14,20),' ',rpad(csv15,20),' ', rpad(csv15,20),' ',
			rpad(csv16,20),	' ',rpad(csv17,20),' ', rpad(csv20,20), ' ', rpad(csv19,20),' ',rpad(csv20,20)) as text
			from temp_t_csv where source not in ('header','vi_t_controls','vi_t_rules','vi_t_patterns', 'vi_t_reactions','vi_t_junctions', 'vi_t_tanks',
			'vi_t_valves','vi_t_reservoirs','vi_t_pipes','vi_t_pumps', 'vi_t_demands')
		order by id)a )row;

	RETURN v_return;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



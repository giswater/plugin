/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2322

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_rpt2pg(character varying );
DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_rpt2pg(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_rpt2pg_main(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT gw_fct_rpt2pg_main('{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{}, "data":{"step":"1", "resultId":"r1", "file":[{"target": "null", "col40": "null", "col1":"Page", "col2":"1", "col3":"Tue", "col4":"Jun", "col5":"02", "col6":"22:20:38", "col7":"2020"}, {"source": "null", "col40": "null", "col1":"*", "col2":"E", "col3":"P", "col4":"A", "col5":"N", "col6":"E", "col7":"T", "col8":"*"}, {"source": "null", "col40": "null", "col1":"*", "col2":"Hydraulic", "col3":"and", "col4":"Water", "col5":"Quality", "col6":"*"}, {"source": "null", "col40": "null", "col1":"*", "col2":"Analysis", "col3":"for", "col4":"Pipe", "col5":"Networks", "col6":"*"}, {"source": "null", "col40": "null", "col1":"*", "col2":"Version", "col3":"*"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Input", "col2":"Data", "col3":"File", "col4":"...................", "col5":"C:/Temp/a20.inp"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Number", "col2":"of", "col3":"Junctions................", "col4":"232"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Number", "col2":"of", "col3":"Reservoirs...............", "col4":"5"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Number", "col2":"of", "col3":"Tanks", "col4":"...................", "col5":"0"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Number", "col2":"of", "col3":"Pipes", "col4":"...................", "col5":"261"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Number", "col2":"of", "col3":"Pumps", "col4":"...................", "col5":"3"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Number", "col2":"of", "col3":"Valves", "col4":"..................", "col5":"2"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Headloss", "col2":"Formula", "col3":"..................", "col4":"Darcy-Weisbach"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Hydraulic", "col2":"Timestep", "col3":"................", "col4":"0.50", "col5":"hrs"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Hydraulic", "col2":"Accuracy", "col3":"................", "col4":"0.001000"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Status", "col2":"Check", "col3":"Frequency", "col4":"............", "col5":"2"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Maximum", "col2":"Trials", "col3":"Checked", "col4":"............", "col5":"10"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Damping", "col2":"Limit", "col3":"Threshold", "col4":"...........", "col5":"0.000000"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Maximum", "col2":"Trials", "col3":"....................", "col4":"40"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Quality", "col2":"Analysis", "col3":"..................", "col4":"None"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Specific", "col2":"Gravity", "col3":"..................", "col4":"1.00"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Relative", "col2":"Kinematic", "col3":"Viscosity", "col4":"......", "col5":"1.00"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Relative", "col2":"Chemical", "col3":"Diffusivity", "col4":".....", "col5":"1.00"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Demand", "col2":"Multiplier", "col3":".................", "col4":"1.00"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Total", "col2":"Duration", "col3":"....................", "col4":"20.00", "col5":"hrs"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Reporting", "col2":"Criteria:"}, {"source": "rpt_cat_result", "col40": "null", "col1":"All", "col2":"Nodes"}, {"source": "rpt_cat_result", "col40": "null", "col1":"All", "col2":"Links"}, {"source": "rpt_cat_result", "col40": "null", "col1":"Analysis", "col2":"begun", "col3":"Tue", "col4":"Jun", "col5":"02", "col6":"22:20:38", "col7":"2020"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"Hydraulic", "col2":"Status:"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"0:00:00:", "col2":"Balanced", "col3":"after", "col4":"10", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"0:00:00:", "col2":"Reservoir", "col3":"113766", "col4":"is", "col5":"filling"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"0:00:00:", "col2":"Reservoir", "col3":"113952", "col4":"is", "col5":"filling"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"0:00:00:", "col2":"Reservoir", "col3":"1101", "col4":"is", "col5":"closed"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"0:00:00:", "col2":"Reservoir", "col3":"1097", "col4":"is", "col5":"emptying"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"0:00:00:", "col2":"Reservoir", "col3":"111111", "col4":"is", "col5":"emptying"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"0:30:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"1:00:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"1:30:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"2:00:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"2:30:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"3:00:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"3:30:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}, {"source": "rpt_hydraulic_status", "col40": "null", "col1":"4:00:00:", "col2":"Balanced", "col3":"after", "col4":"1", "col5":"trials"}]}}'::json);

SELECT gw_fct_rpt2pg_main('{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{}, "data":{"step":"2", "resultId":"r1"}}')


*/

DECLARE
v_result text;
v_file json;
v_import json;
v_return json;
v_step integer = 0;
v_error_context text;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get parameters
	v_result  = (p_data ->>'data')::json->>'resultId';
	v_file  = (p_data ->>'data')::json->>'file';
	v_step = (p_data->>'data')::json->>'step';

	--
	IF v_step = 1 THEN

		RAISE NOTICE 'Starting rpt2pg process.';
		CREATE TEMP TABLE temp_t_csv (LIKE SCHEMA_NAME.temp_csv INCLUDING ALL);
		CREATE TEMP TABLE temp_audit_check_data (LIKE SCHEMA_NAME.audit_check_data INCLUDING ALL);

		-- inserting file into temp table
		INSERT INTO temp_t_csv (fid, cur_user, source, csv1, csv2, csv3, csv4, csv5, csv6, csv7, csv8, csv9, csv10, csv11, csv12, csv13, csv14, csv15, csv16, csv17, csv18, csv19, csv20, csv40)
		SELECT 140 , current_user, replace(a::json->>'target','''',''), a::json->>'col1', a::json->>'col2',a::json->>'col3',a::json->>'col4',a::json->>'col5',a::json->>'col6',a::json->>'col7',
		a::json->>'col8', a::json->>'col9',a::json->>'col10', a::json->>'col11',a::json->>'col12',a::json->>'col13',a::json->>'col14',a::json->>'col15',a::json->>'col16',a::json->>'col17',a::json->>'col18'
		,a::json->>'col19',a::json->>'col20', replace(a::json->>'col40','''', '')
		FROM json_array_elements(v_file) AS a;

		v_return = '{"status": "Accepted", "message":{"level":1, "text":"Import RPT file 1/2:Import data...... done succesfully"}}'::json;
		RETURN v_return;

	ELSIF v_step = 2 THEN

		-- reordening data from temp table to rpt tables
		p_data = concat('{"client":{"device":4, "infoType":1, "lang":"ES"}, "form":{}, "feature":{}, "data":{"resultId":"'||v_result||'"}}');
		SELECT gw_fct_rpt2pg_import_rpt(p_data) INTO v_import;

		-- Reverse geometries where flow is negative and updating flow values with absolute value
		UPDATE rpt_inp_arc SET the_geom=st_reverse(the_geom) FROM rpt_arc WHERE rpt_arc.arc_id::text=rpt_inp_arc.arc_id AND flow<0 AND rpt_inp_arc.result_id=v_result;
		UPDATE rpt_arc SET flow=(-1)*flow WHERE flow<0 and result_id=v_result;

		-- set result on result selector
		-- NOTE: In spite of there are four selectors tables () only it's setted one
		DELETE FROM selector_rpt_main WHERE cur_user=current_user;
		INSERT INTO selector_rpt_main (result_id, cur_user) VALUES (v_result, current_user);

		-- update rpt_cat_result
		UPDATE rpt_cat_result SET exec_date = now(), cur_user = current_user , status = 2 WHERE result_id = v_result;

		-- delete wrong VALUES
		UPDATE rpt_node SET time='0:00' where time ='null' and result_id = v_result;
		UPDATE rpt_arc SET time='0:00' where time ='null' and result_id = v_result;

		-- insert into values in table of stats values to enhance performance for big systems
		INSERT INTO rpt_arc_stats (
			arc_id, result_id, arc_type, sector_id, arccat_id,
			flow_max, flow_min, flow_avg,
			vel_max, vel_min, vel_avg,
			headloss_max, headloss_min,
			setting_max, setting_min,
			reaction_max, reaction_min,
			ffactor_max, ffactor_min,
			length, tot_headloss_max, tot_headloss_min, the_geom
		)
		SELECT arc.arc_id,
			selector_rpt_main.result_id,
			arc.arc_type,
			arc.sector_id,
			arc.arccat_id,
			max(rpt_arc.flow) AS flow_max,
			min(rpt_arc.flow) AS flow_min,
			avg(rpt_arc.flow)::numeric(12,2) AS flow_avg,
			max(rpt_arc.vel) AS vel_max,
			min(rpt_arc.vel) AS vel_min,
			avg(rpt_arc.vel)::numeric(12,2) AS vel_avg,
			max(rpt_arc.headloss) AS headloss_max,
			min(rpt_arc.headloss) AS headloss_min,
			max(rpt_arc.setting) AS setting_max,
			min(rpt_arc.setting) AS setting_min,
			max(rpt_arc.reaction) AS reaction_max,
			min(rpt_arc.reaction) AS reaction_min,
			max(rpt_arc.ffactor) AS ffactor_max,
			min(rpt_arc.ffactor) AS ffactor_min,
			rpt_arc.length,
			max(rpt_arc.headloss * rpt_arc.length / 1000)::numeric(12, 2) AS tot_headloss_max,
			min(rpt_arc.headloss * rpt_arc.length / 1000)::numeric(12, 2) AS tot_headloss_min,
			arc.the_geom
		FROM selector_rpt_main,
			rpt_inp_arc arc
			JOIN rpt_arc ON rpt_arc.arc_id::text = arc.arc_id::text
		WHERE rpt_arc.result_id::text = selector_rpt_main.result_id::text AND selector_rpt_main.cur_user = "current_user"()::text AND arc.result_id::text = selector_rpt_main.result_id::text
		GROUP BY arc.arc_id, arc.arc_type, arc.sector_id, arc.arccat_id, selector_rpt_main.result_id, arc.the_geom, rpt_arc.length
		ORDER BY arc.arc_id;

		INSERT INTO rpt_node_stats (
			node_id, result_id, node_type, sector_id, nodecat_id, top_elev,
			demand_max, demand_min, demand_avg,
			head_max, head_min, head_avg,
			press_max, press_min, press_avg,
			quality_max, quality_min, quality_avg,
			the_geom
		)
		SELECT node.node_id,
			selector_rpt_main.result_id,
			node.node_type,
			node.sector_id,
			node.nodecat_id,
			max(rpt_node.top_elev) AS top_elev,
			max(rpt_node.demand) AS demand_max,
			min(rpt_node.demand) AS demand_min,
			avg(rpt_node.demand)::numeric(12,2) AS demand_avg,
			max(rpt_node.head) AS head_max,
			min(rpt_node.head) AS head_min,
			avg(rpt_node.head)::numeric(12,2) AS head_avg,
			max(rpt_node.press) AS press_max,
			min(rpt_node.press) AS press_min,
			avg(rpt_node.press)::numeric(12,2) AS press_avg,
			max(rpt_node.quality) AS quality_max,
			min(rpt_node.quality) AS quality_min,
			avg(rpt_node.quality)::numeric(12,2) AS quality_avg,
			node.the_geom
		FROM selector_rpt_main, rpt_inp_node node
			JOIN rpt_node ON rpt_node.node_id::text = node.node_id::text
		WHERE rpt_node.result_id::text = selector_rpt_main.result_id::text AND selector_rpt_main.cur_user = "current_user"()::text AND node.result_id::text = selector_rpt_main.result_id::text
		GROUP BY node.node_id, node.node_type, node.sector_id, node.nodecat_id, selector_rpt_main.result_id, node.the_geom
		ORDER BY node.node_id;

		-- create log message
		RETURN gw_fct_rpt2pg_log(v_result, v_import);

	END IF;

    -- Exception handling
    EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'message', json_build_object('level', right(SQLSTATE, 1), 'text', SQLERRM), 'SQLSTATE', SQLSTATE, 'SQLCONTEXT', v_error_context)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
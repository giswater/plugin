/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3262

drop function if exists SCHEMA_NAME.gw_fct_mincut_minsector(character varying, integer);
drop function if exists SCHEMA_NAME.gw_fct_mincut_minsector(integer, integer, boolean);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_mincut_minsector(p_arc_id integer, p_mincut_id integer, p_usepsectors boolean)
RETURNS json AS
$BODY$

/*EXAMPLE
INSERT INTO SCHEMA_NAME.om_mincut VALUES (-1);
SELECT SCHEMA_NAME.gw_fct_mincut_minsector('2061', -1, FALSE)

--fid: 199

*/

DECLARE

v_expl integer;
v_muni integer;
v_macroexpl integer;
v_minsector integer;
v_state integer;
v_isoperative boolean;

v_mincutdetails	json;

v_result text;
v_result_info text;
v_error_context text;
v_error_message text;
v_level integer;
v_status text;
v_message text;
v_version text;

v_numarcs integer;
v_length double precision;
v_numconnecs integer;
v_numhydrometer integer;
v_numvalveproposed integer;
v_numvalveclosed integer;
v_volume float;
v_priority json;

v_geometry text;
v_querystring text;
v_debug_vars json;
v_debug_sql json;
v_msgerr json;
v_count integer = 0;
v_check record;
v_minsector_check integer;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- Get project version
	SELECT giswater INTO  v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	DROP VIEW IF EXISTS v_t_anl_graph;
	DROP TABLE IF EXISTS temp_t_anlgraph;
	DROP TABLE IF EXISTS temp_t_node;
	DROP TABLE IF EXISTS temp_t_table;
	DROP TABLE IF EXISTS temp_t_data;
	DROP TABLE IF EXISTS temp_om_mincut;
	DROP TABLE IF EXISTS temp_om_mincut_node;
	DROP TABLE IF EXISTS temp_om_mincut_arc;
	DROP TABLE IF EXISTS temp_om_mincut_connec;
	DROP TABLE IF EXISTS temp_om_mincut_hydrometer;
	DROP TABLE IF EXISTS temp_om_mincut_valve;
	DROP TABLE IF EXISTS temp_t_mincut;

	-- Create temp tables and setting selectors';
	CREATE TEMP TABLE temp_t_anlgraph (LIKE SCHEMA_NAME.temp_anlgraph INCLUDING ALL);
	CREATE TEMP TABLE temp_t_node (LIKE SCHEMA_NAME.temp_node INCLUDING ALL);
	CREATE TEMP TABLE temp_t_table (LIKE SCHEMA_NAME.temp_table INCLUDING ALL);
	CREATE TEMP TABLE temp_t_data (LIKE SCHEMA_NAME.temp_data INCLUDING ALL);
	CREATE TEMP TABLE temp_om_mincut (LIKE SCHEMA_NAME.om_mincut INCLUDING ALL);
	CREATE TEMP TABLE temp_om_mincut_node (LIKE SCHEMA_NAME.om_mincut_node INCLUDING ALL);
	CREATE TEMP TABLE temp_om_mincut_arc (LIKE SCHEMA_NAME.om_mincut_arc INCLUDING ALL);
	CREATE TEMP TABLE temp_om_mincut_connec (LIKE SCHEMA_NAME.om_mincut_connec INCLUDING ALL);
	CREATE TEMP TABLE temp_om_mincut_hydrometer (LIKE SCHEMA_NAME.om_mincut_hydrometer INCLUDING ALL);
	CREATE TEMP TABLE temp_om_mincut_valve (LIKE SCHEMA_NAME.om_mincut_valve INCLUDING ALL);
	CREATE TEMP TABLE temp_t_mincut (LIKE SCHEMA_NAME.temp_mincut INCLUDING ALL);

	CREATE OR REPLACE TEMP VIEW v_t_anl_graph AS
		 SELECT t.arc_id,
		        t.node_1,
		        t.node_2,
			t.trace,
			t.flag,
			t.water
		   FROM temp_t_anlgraph t
		     JOIN ( SELECT arc_id, node_1, node_2, water, flag FROM temp_t_anlgraph WHERE water = 1) a ON t.node_1::text = a.node_2::text
		     WHERE t.flag < 2 AND t.water = 0 AND a.flag = 0;

	-- Getting values from arc
	SELECT expl_id, state, is_operative, muni_id, macroexpl_id, minsector_id INTO v_expl, v_state, v_isoperative, v_muni, v_macroexpl, v_minsector FROM ve_arc WHERE arc_id=p_arc_id;

	-- Delaing with temp_om_mincut
	INSERT INTO temp_om_mincut SELECT * FROM om_mincut WHERE id=p_mincut_id;
	UPDATE temp_om_mincut SET mincut_state=4, muni_id=v_muni, expl_id=v_expl, macroexpl_id=v_macroexpl, minsector_id = v_minsector WHERE id=p_mincut_id;

	-- Getting arc id in case of exists
	IF p_arc_id IS NULL THEN SELECT anl_feature_id INTO p_arc_id FROM om_mincut WHERE id = p_mincut_id;END IF;

	--- controling exceptions
	SELECT COUNT(*) INTO v_count FROM ve_arc WHERE arc_id = p_arc_id;
	IF v_count = 0 THEN RAISE EXCEPTION 'Arc does not exists'; END IF;
	IF v_state = 0 THEN RAISE EXCEPTION 'Arc with state 0'; END IF;
	IF v_isoperative = FALSE THEN RAISE EXCEPTION 'Arc with is operative false'; END IF;

	-- insert network features into mincut tables
	INSERT INTO temp_om_mincut_arc (result_id, arc_id, the_geom, minsector_id) SELECT p_mincut_id, arc_id, the_geom, minsector_id FROM ve_arc WHERE minsector_id = v_minsector;
	INSERT INTO temp_om_mincut_node (result_id, node_id, the_geom, minsector_id) SELECT p_mincut_id, node_id, the_geom, minsector_id FROM ve_node WHERE minsector_id = v_minsector;

	INSERT INTO temp_om_mincut_valve (result_id, node_id, unaccess, closed, broken, the_geom)
	SELECT p_mincut_id, node.node_id, false, closed, broken, node.the_geom
	FROM node
	JOIN exploitation ON node.expl_id=exploitation.expl_id
	JOIN cat_node c ON nodecat_id = c.id
	JOIN cat_feature_node f ON node_type = f.id
	JOIN man_valve USING (node_id)
	WHERE 'MINSECTOR' = ANY(graph_delimiter) AND  macroexpl_id=v_macroexpl;

	UPDATE temp_om_mincut_valve SET unaccess = TRUE where node_id IN (SELECT node_id FROM om_mincut_valve_unaccess WHERE result_id = p_mincut_id);

	UPDATE temp_om_mincut_valve SET proposed = TRUE FROM
	(SELECT DISTINCT ON (a.node_id) p_mincut_id, a.node_id FROM (SELECT node_1 node_id, arc_id from temp_om_mincut_arc JOIN arc USING (arc_id)
			UNION ALL
			SELECT node_2, arc_id from temp_om_mincut_arc JOIN arc USING (arc_id) ) a
			LEFT JOIN temp_om_mincut_node m USING (node_id)
			JOIN node n ON n.node_id = a.node_id
			WHERE m.node_id is null) a WHERE a.node_id = temp_om_mincut_valve.node_id;

	FOR v_check IN SELECT node_id, minsector_id from config_graph_checkvalve JOIN arc on to_arc = arc_id JOIN temp_om_mincut_valve USING (node_id) WHERE active
	LOOP
		IF v_check.minsector_id  = v_minsector THEN
			SELECT minsector_id INTO v_minsector_check FROM (SELECT minsector_id FROM arc WHERE node_1 = v_check.node_id
			UNION SELECT minsector_id FROM arc WHERE node_2 = v_check.node_id) a WHERE minsector_id <> v_minsector;

			-- insert network features into mincut tables
			INSERT INTO temp_om_mincut_arc (result_id, arc_id, the_geom, minsector_id) SELECT p_mincut_id, arc_id, the_geom, minsector_id
			FROM ve_arc WHERE minsector_id = v_minsector_check;
			INSERT INTO temp_om_mincut_node (result_id, node_id, the_geom, minsector_id) SELECT p_mincut_id, node_id, the_geom, minsector_id
			FROM ve_node WHERE minsector_id = v_minsector_check;
		END IF;
	END LOOP;

	-- step 1, looking for unoperative (broken or unaccess) valves
	PERFORM gw_fct_mincut_minsector_inverted(p_mincut_id, 1);

	-- step 2, looking for path to inlets
	PERFORM gw_fct_mincut_minsector_inverted(p_mincut_id, 2);

	-- cleaning results
	DELETE FROM temp_om_mincut_valve WHERE node_id NOT IN (
		SELECT node_1 FROM arc JOIN temp_om_mincut_arc USING (arc_id)
		UNION
		SELECT node_2 FROM arc JOIN temp_om_mincut_arc USING (arc_id));

	-- set proposed = false for broken, unaccess and closed valves
	UPDATE temp_om_mincut_valve SET proposed=FALSE WHERE broken = TRUE OR unaccess = TRUE OR closed = TRUE;

	-- set proposed = false for check valves (as they act as automatic mode)
	UPDATE temp_om_mincut_valve v SET proposed=FALSE FROM (SELECT node_id FROM config_graph_checkvalve WHERE active IS TRUE ) a WHERE a.node_id = v.node_id;

	-- insert connec table
	INSERT INTO temp_om_mincut_connec (result_id, connec_id, the_geom, customer_code)
	SELECT p_mincut_id, connec_id, connec.the_geom, customer_code FROM connec JOIN temp_om_mincut_arc ON connec.arc_id=temp_om_mincut_arc.arc_id WHERE state = 1;

	-- insert hydrometer from connec
	INSERT INTO temp_om_mincut_hydrometer (result_id, hydrometer_id)
	SELECT p_mincut_id, erh.hydrometer_id
	FROM v_hydrometer erh
	JOIN connec c ON erh.feature_customer_code = c.customer_code
	JOIN temp_om_mincut_connec ON c.connec_id=temp_om_mincut_connec.connec_id
	JOIN value_state_type v ON state_type = v.id
	WHERE result_id=p_mincut_id AND v.is_operative=TRUE AND c.connec_id=temp_om_mincut_connec.connec_id;

	-- insert hydrometer from node
	INSERT INTO temp_om_mincut_hydrometer (result_id, hydrometer_id)
	SELECT p_mincut_id,erh.hydrometer_id
	FROM v_hydrometer erh
	JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code
	JOIN node n ON n.node_id = mn.node_id
	JOIN temp_om_mincut_node ON n.node_id=temp_om_mincut_node.node_id
	JOIN value_state_type v ON state_type = v.id
	WHERE result_id=p_mincut_id AND v.is_operative=TRUE AND n.node_id=temp_om_mincut_node.node_id;

	-- getting mincut details
	-- count arcs
	SELECT count(arc_id), sum(st_length(arc.the_geom))::numeric(12,2) INTO v_numarcs, v_length
	FROM temp_om_mincut_arc JOIN arc USING (arc_id);

	SELECT sum(pi()*(dint*dint/4000000)*st_length(arc.the_geom))::numeric(12,2) INTO v_volume
	FROM temp_om_mincut_arc JOIN arc USING (arc_id) JOIN cat_arc ON arccat_id=cat_arc.id ;

	-- count valves
	SELECT count(node_id) INTO v_numvalveproposed FROM temp_om_mincut_valve WHERE proposed IS TRUE;
	SELECT count(node_id) INTO v_numvalveclosed FROM temp_om_mincut_valve WHERE closed IS TRUE;

	-- count connec
	SELECT count(connec_id) INTO v_numconnecs FROM temp_om_mincut_connec WHERE result_id=p_mincut_id;

	-- count hydrometers
	SELECT count (*) INTO v_numhydrometer FROM temp_om_mincut_hydrometer WHERE result_id=p_mincut_id;

	-- setting boundary of mincut
	SELECT st_astext(st_envelope(st_extent(st_buffer(the_geom,20)))) INTO v_geometry
	FROM (SELECT the_geom FROM temp_om_mincut_arc UNION SELECT the_geom FROM temp_om_mincut_valve) a;

	-- priority hydrometers
	v_priority = 	(SELECT (array_to_json(array_agg((b)))) FROM
	(SELECT concat('{"category":"',hc.observ,'","number":"', count(omh.hydrometer_id), '"}')::json as b
			FROM temp_om_mincut_hydrometer omh
			JOIN vf_hydrometer h ON h.hydrometer_id = omh.hydrometer_id
			LEFT JOIN v_cat_hydrometer_category hc ON hc.id::text = h.category_id::text
			WHERE omh.result_id = p_mincut_id
			GROUP BY hc.observ ORDER BY hc.observ)a);

	IF v_priority IS NULL THEN v_priority='{}'; END IF;

	v_mincutdetails = (concat('{"minsector_id":"',v_minsector,'","psectors":{"used":"',p_usepsectors,'", "unselected":',v_count,'}, "arcs":{"number":"',v_numarcs,'", "length":"',v_length,'", "volume":"',
	v_volume, '"}, "connecs":{"number":"',v_numconnecs,'","hydrometers":{"total":"',v_numhydrometer,'","classified":',v_priority,'}}, "valve":{"proposed":"'
	,v_numvalveproposed,'","closed":"',v_numvalveclosed,'"}}'));

	-- start of single transactional part
	INSERT INTO om_mincut (id) VALUES (p_mincut_id) ON CONFLICT DO NOTHING;

	-- Update selector_mincut_result
	DELETE FROM selector_mincut_result WHERE result_id = p_mincut_id AND cur_user = current_user;
	INSERT INTO selector_mincut_result(cur_user, result_id) VALUES (current_user, p_mincut_id);

	-- update mincut values
	UPDATE om_mincut SET mincut_state=4, anl_feature_id = p_arc_id, muni_id=v_muni, expl_id=v_expl, macroexpl_id=v_macroexpl, output = v_mincutdetails
	WHERE id=p_mincut_id;

	DELETE FROM om_mincut_node WHERE result_id = p_mincut_id;
	DELETE FROM om_mincut_arc WHERE result_id = p_mincut_id;
	DELETE FROM om_mincut_valve WHERE result_id = p_mincut_id;
	DELETE FROM om_mincut_connec WHERE result_id = p_mincut_id;
	DELETE FROM om_mincut_hydrometer WHERE result_id = p_mincut_id;

	INSERT INTO om_mincut_node SELECT * FROM temp_om_mincut_node;
	INSERT INTO om_mincut_arc SELECT * FROM temp_om_mincut_arc;
	INSERT INTO om_mincut_valve SELECT * FROM temp_om_mincut_valve;
	INSERT INTO om_mincut_connec SELECT * FROM temp_om_mincut_connec;
	INSERT INTO om_mincut_hydrometer SELECT * FROM temp_om_mincut_hydrometer;

	-- returning
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');
	v_version := COALESCE(v_version, '');
	v_geometry := COALESCE(v_geometry, '{}');
	v_mincutdetails := COALESCE(v_mincutdetails, '{}');
	v_geometry := COALESCE(v_geometry, '{}');

	-- building the response
	IF (SELECT addparam::text FROM temp_data WHERE fid=199 AND cur_user=current_user) != v_mincutdetails::text THEN
		v_status = 'Accepted';
		v_level = 3;
		v_message = 'There were diferences between previously executed mincut and current version of the process. Mincut has been updated.';
	ELSIF v_error_message is null THEN
		v_status = 'Accepted';
		v_level = 3;
		v_message = 'Mincut done successfully';
	ELSE
		v_status = ((((v_error_message::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text;
		v_level = ((((v_error_message::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer;
		v_message = ((((v_error_message::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text;
	END IF;

	RETURN ('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
	',"body":{"form":{}'||
			',"data":{ '||
			'  "info":'||v_result_info||
			', "geometry":"'||v_geometry||'"'||
			', "mincutDetails":'||v_mincutdetails||'}'||
			'}'
	'}')::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
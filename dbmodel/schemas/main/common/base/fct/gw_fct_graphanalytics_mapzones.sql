/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
-- The code of this have been received helpfull assistance from Enric Amat (FISERSA) and Claudia Dragoste (Aigües de Girona SA)

--FUNCTION CODE: 3404

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_grafanalytics_mapzones(json);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_graphanalytics_mapzones(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_graphanalytics_mapzones(p_data json)
RETURNS json AS
$BODY$

/*

------------
TO CONFIGURE
------------

set graph_delimiter field on node_type table (below an example). It's not mandatory but provides more consistency to the analyzed data

UPDATE node_type
SET graph_delimiter='NONE';
SET graph_delimiter='SECTOR' WHERE type IN ('SOURCE','WATERWELL', 'ETAP' 'TANK');

UPDATE sector SET graphconfig='[{"nodeParent":"1", "toArc":[2,3,4]}, {"nodeParent":"5", "toArc":[6,7,8]}]';
UPDATE dma SET graphconfig='[{"nodeParent":"11", "toArc":[12,13,14]}, {"nodeParent":"5", "toArc":[16,17,18]}]';
UPDATE dqa SET graphconfig='[{"nodeParent":"21", "toArc":[22,23,24]}, {"nodeParent":"5", "toArc":[26,27,28]}]';
UPDATE cat_preszone SET graphconfig='[{"nodeParent":"31", "toArc":[32,33,34]}, {"nodeParent":"35", "toArc":[36,37,38]}]';

update arc set sector_id=0, dma_id=0, dqa_id=0, presszone_id=0;
update node set sector_id=0, dma_id=0, dqa_id=0,  presszone_id=0;
update connec set sector_id=0, dma_id=0, dqa_id=0, presszone_id=0


----------------
-- QUERY SAMPLE
SELECT gw_fct_graphanalytics_mapzones('{"data":{"parameters":{"graphClass":"DRAINZONE", "exploitation":[1], "macroExploitation":[1], "commitChanges":true, "updateMapZone":2, "geomParamUpdate":15, "usePlanPsector":false, "forceOpen":[1,2,3], "forceClosed":[2,3,4]}}}');

SELECT gw_fct_graphanalytics_mapzones('{"data":{"parameters":{"graphClass":"PRESSZONE", "exploitation":[1,2], "commitChanges":true, "updateMapZone":2, "geomParamUpdate":15, "usePlanPsector":false}}}');


SELECT SCHEMA_NAME.gw_fct_graphanalytics_mapzones_advanced($${"client":{"device":4, "lang":"es_ES", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"graphClass":"PRESSZONE", "exploitation":"1", "floodOnlyMapzone":null, "forceOpen":null, "forceClosed":null, "usePlanPsector":"false", "valueForDisconnected":"0", "updateMapZone":"5", "geomParamUpdate":"100"}}}$$);

if exploitation not exists > macroexploitation

---------------------------------
TO CHECK PROBLEMS, RUN MODE DEBUG
---------------------------------

1) CONTEXT
SET search_path='SCHEMA_NAME', public;
UPDATE arc SET dma_id=0 where expl_id IN (1,2)


2) RUN
SELECT gw_fct_graphanalytics_mapzones('{"data":{"parameters":{"graphClass":"DQA", "exploitation": "[1]",  "updateMapZone":2,""geomParamUpdate":15}}}');
SELECT SCHEMA_NAME.gw_fct_graphanalytics_mapzones($${"data":{"parameters":{"graphClass":"DMA", "exploitation": "[1]","updateMapZone":2,"geomParamUpdate":15, "valueForDisconnected":"9"}}}$$);

INSTRUCTIONS
flag: 0 open, 1 closed
water: 0 dry, 1 wet

3) ANALYZE:

Look graph flooders (flag=0 and graphdelimiter node)
SELECT node_1 AS node_id, arc_id AS to_arc FROM temp_anlgraph WHERE flag=0 AND node_1 IN (
SELECT DISTINCT node_id::integer FROM node a JOIN cat_node b ON nodecat_id=b.id JOIN node_type c ON c.id=b.node_type JOIN temp_anlgraph e ON a.node_id::integer=e.node_1::integer WHERE graph_delimiter IN ('DQA', 'SECTOR'))

SELECT node_1 AS node_id, arc_id AS to_arc FROM temp_anlgraph WHERE flag=0 AND node_1 IN (
SELECT DISTINCT node_id::integer FROM node a JOIN cat_node b ON nodecat_id=b.id JOIN node_type c ON c.id=b.node_type JOIN temp_anlgraph e ON a.node_id::integer=e.node_1::integer WHERE graph_delimiter IN ('DMA', 'SECTOR'))

Look for the graph stoppers (flag=1)
SELECT arc_id, node_1 FROM temp_anlgraph where flag=1 order by node_1

-- fid: 147, 125, 146, 145, 144, 130

*/

DECLARE

v_affectrow numeric;
v_cont1 integer default 0;
v_class text;
v_feature record;
v_expl_id text;
v_macroexpl json;
v_data json;
v_fid integer;
v_featureid integer;
v_text text;
v_querytext text;
v_result_info json;
v_result_point json;
v_result_line json;
v_result_polygon json;
v_result text;
v_count integer = 0;
v_version text;
v_table text;
v_field text;
v_fieldmp text;
v_srid integer;
v_input json;
v_count1 integer;
v_count2 integer;
v_count3 integer;
v_geomparamupdate float;
v_updatemapzgeom integer = 0;
v_geomparamupdate_divide float;
v_visible_layer text;
v_concavehull float = 0.9;
v_error_context text;
v_audit_result text;
v_level integer;
v_status text;
v_message text;
v_checkdata text;  -- FULL / PARTIAL / NONE
v_mapzonename text;
v_parameters json;
v_usepsector boolean;
v_error boolean = false;
v_nodemapzone text;
rec_conflict record;
v_valuefordisconnected integer;
v_floodonlymapzone text;
v_islastupdate boolean;
v_commitchanges boolean;
v_project_type text;
v_query_arc text;
v_query_node text;
v_query_connec text;
v_query_gully text;
v_query_link text;
v_query_link_gully text;
v_dscenario_valve text;
v_netscenario text;
v_has_conflicts boolean = false;
rec record;

-- LOCK LEVEL LOGIC
v_original_disable_locklevel json;

BEGIN
	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- select system values
	SELECT giswater, epsg, upper(project_type) INTO v_version, v_srid, v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;
	SELECT value::boolean INTO v_islastupdate FROM config_param_system WHERE parameter='edit_mapzones_set_lastupdate';

	-- get dialog variables
	v_class = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'graphClass');
	v_expl_id = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'exploitation');
	v_macroexpl = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'macroExploitation');
	v_floodonlymapzone = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'floodOnlyMapzone');
	v_valuefordisconnected = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'valueForDisconnected');
	v_updatemapzgeom = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'updateMapZone');
	v_geomparamupdate = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'geomParamUpdate');
	v_usepsector = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'usePlanPsector');
	v_parameters = (SELECT ((p_data::json->>'data')::json->>'parameters'));
	v_commitchanges = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'commitChanges');
	v_checkdata = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'checkData');
	v_dscenario_valve = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'dscenario_valve');
	v_netscenario = (SELECT ((p_data::json->>'data')::json->>'parameters')::json->>'netscenario');

	-- profilactic controls
	IF v_dscenario_valve = '' THEN v_dscenario_valve = NULL; END IF;
	IF v_netscenario = '' THEN v_netscenario = NULL; END IF;
	IF v_floodonlymapzone = '' THEN v_floodonlymapzone = NULL; END IF;
	v_floodonlymapzone = REPLACE(REPLACE (v_floodonlymapzone,'[','') ,']','');

	-- Get user variable for disabling lock level
    SELECT value::json INTO v_original_disable_locklevel FROM config_param_user
    WHERE parameter = 'edit_disable_locklevel' AND cur_user = current_user;
    -- Set disable lock level to true for this operation
    UPDATE config_param_user SET value = '{"update":true, "delete":true}'
    WHERE parameter = 'edit_disable_locklevel' AND cur_user = current_user;

	-- set fid:
	IF v_class = 'PRESSZONE' THEN
		v_fid=146;
		v_table  = 'presszone';
		v_field = 'presszone_id';
		v_fieldmp = 'presszone_id';
		v_visible_layer ='"ve_presszone"';
		IF v_netscenario is not null then
			v_mapzonename = 'presszone_name';
		else
			v_mapzonename = 'name';
		end if;

	ELSIF v_class = 'DMA' THEN
		v_fid=145;
		v_table = 'dma';
		v_field = 'dma_id';
		v_fieldmp = 'dma_id';
		v_visible_layer ='"ve_dma"';
		IF v_netscenario is not null then
			v_mapzonename = 'dma_name';
		else
			v_mapzonename = 'name';
		end if;

	ELSIF v_class = 'DQA' THEN
		v_fid=144;
		v_table = 'dqa';
		v_field = 'dqa_id';
		v_fieldmp = 'dqa_id';
		v_visible_layer ='"ve_dqa"';
		v_mapzonename = 'name';

	ELSIF v_class = 'SECTOR' THEN
		v_fid=130;
		v_table = 'sector';
		v_field = 'sector_id';
		v_fieldmp = 'sector_id';
		v_visible_layer ='"ve_sector"';
		v_mapzonename = 'name';

	-- ELSIF v_class = 'DRAINZONE' THEN
	--	v_fid=481;
	--	v_table = 'drainzone';
	--	v_field = 'drainzone_id';
	--	v_fieldmp = 'drainzone_id';
	--	v_visible_layer ='"ve_drainzone"';
	--	v_mapzonename = 'name';
	ELSE
		RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Process done sucessfully"}, "version":"'||v_version||'", 
		"body":{"form":{},"data":{"info":""}}}')::json, 2710, NULL, NULL, NULL);
	END IF;


	---create temp tables necessaries for quality check
	CREATE TEMP TABLE IF NOT EXISTS temp_audit_check_data (LIKE SCHEMA_NAME.audit_check_data INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_anl_arc (LIKE SCHEMA_NAME.anl_arc INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_anl_node (LIKE SCHEMA_NAME.anl_node INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_anl_connec (LIKE SCHEMA_NAME.anl_connec INCLUDING ALL);

	-- data quality analysis
	IF v_checkdata = 'FULL' THEN

		-- om data quality analysis
		v_input = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{ "fid":',v_fid,',"parameters":{"selectionMode":"userSelectors"}}}')::json;
		PERFORM gw_fct_om_check_data(v_input);
		SELECT count(*) INTO v_count1 FROM audit_check_data WHERE cur_user="current_user"() AND fid=v_fid AND criticity=3 AND result_id IS NOT NULL;

		DELETE FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=v_fid AND error_message ='' AND criticity=1;

		-- graph quality analysis
		v_input = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"parameters":{ "fid":',v_fid,',"selectionMode":"userSelectors", "graphClass":',quote_ident(v_class),'}}}')::json;
		PERFORM gw_fct_graphanalytics_check_data(v_input);
		SELECT count(*) INTO v_count2 FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=v_fid AND criticity=3 AND result_id IS NOT NULL;

		DELETE FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=v_fid AND result_id IS NULL;

	ELSIF v_checkdata = 'PARTIAL' THEN

		-- graph quality analysis
		v_input = concat('{"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"parameters":{ "fid":',v_fid,',"selectionMode":"userSelectors", "graphClass":',quote_ident(v_class),'}}}')::json;
		PERFORM gw_fct_graphanalytics_check_data(v_input);
		SELECT count(*) INTO v_count2 FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=v_fid AND criticity=3 AND result_id IS NOT NULL;
	END IF;

	IF v_expl_id = '' THEN
		v_expl_id = -1;
		INSERT INTO temp_audit_check_data (fid, criticity, error_message) VALUES (v_fid, 2, concat('ERROR: No exploitations have been selected. Please, select at least 1 exploitation in Selector'));
	END IF;

	v_count = coalesce(v_count1,0) + coalesce(v_count2,0);

	-- check criticity of data in order to continue or not
	IF v_count > 0 THEN
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=v_fid AND criticity > 1 order by criticity desc, id asc) row;

		v_result := COALESCE(v_result, '{}');
		v_result_info = concat ('{"values":',v_result, '}');

		-- Control nulls
		v_result_info := COALESCE(v_result_info, '{}');

		--  Return
		RETURN ('{"status":"Accepted", "message":{"level":3, "text":"Mapzones dynamic analysis canceled. Data is not ready to work with"}, "version":"'||v_version||'"'||
		',"body":{"form":{}, "data":{ "info":'||v_result_info||'}}}')::json;

	END IF;


	IF v_audit_result IS NOT NULL OR (SELECT (value::json->>(v_class))::boolean FROM config_param_system WHERE parameter='utils_graphanalytics_status') IS FALSE THEN

		INSERT INTO temp_audit_check_data (fid, criticity, error_message)
		VALUES (v_fid, 3, concat('ERROR-',v_fid,': Dynamic analysis for ',v_class,'''s is not configured on database. Please update system variable ''utils_graphanalytics_status'' to enable it '));

		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=v_fid AND criticity > 1 order by criticity desc, id asc) row;

		v_result := COALESCE(v_result, '{}');
		v_result_info = concat ('{"values":',v_result, '}');

		-- Control nulls
		v_result_info := COALESCE(v_result_info, '{}');

		--  Return
		RETURN ('{"status":"Accepted", "message":{"level":3, "text":"Mapzones dynamic analysis canceled. Configuration is not set corerctly to start the process"}, "version":"'||v_version||'"'||
		',"body":{"form":{}, "data":{ "info":'||v_result_info||'}}}')::json;

	ELSE
		--create temporal tables

		CREATE TEMP TABLE IF NOT EXISTS temp_t_anlgraph (LIKE SCHEMA_NAME.temp_anlgraph INCLUDING ALL);
		CREATE TEMP TABLE IF NOT EXISTS temp_t_data (LIKE SCHEMA_NAME.temp_data INCLUDING ALL);
		CREATE TEMP TABLE IF NOT EXISTS temp_t_arc (LIKE SCHEMA_NAME.arc INCLUDING ALL);
		CREATE TEMP TABLE IF NOT EXISTS temp_t_node (LIKE SCHEMA_NAME.node INCLUDING ALL);
		CREATE TEMP TABLE IF NOT EXISTS temp_t_connec (LIKE SCHEMA_NAME.connec INCLUDING ALL);
		CREATE TEMP TABLE IF NOT EXISTS temp_t_link (LIKE SCHEMA_NAME.link INCLUDING ALL);

		IF v_project_type = 'UD' THEN
			CREATE TEMP TABLE IF NOT EXISTS temp_t_gully (LIKE SCHEMA_NAME.gully INCLUDING ALL);
			CREATE TEMP TABLE IF NOT EXISTS temp_drainzone (LIKE SCHEMA_NAME.drainzone INCLUDING ALL);
		ELSE
			CREATE TEMP TABLE IF NOT EXISTS temp_om_waterbalance_dma_graph (LIKE SCHEMA_NAME.om_waterbalance_dma_graph INCLUDING ALL);
			CREATE TEMP TABLE IF NOT EXISTS temp_sector (LIKE SCHEMA_NAME.sector INCLUDING ALL);
			CREATE TEMP TABLE IF NOT EXISTS temp_dqa (LIKE SCHEMA_NAME.dqa INCLUDING ALL);
			IF v_netscenario IS NOT NULL THEN
				CREATE TEMP TABLE IF NOT EXISTS temp_dma (LIKE SCHEMA_NAME.plan_netscenario_dma INCLUDING ALL);
				CREATE TEMP TABLE IF NOT EXISTS temp_presszone (LIKE SCHEMA_NAME.plan_netscenario_presszone INCLUDING ALL);
			ELSE
				CREATE TEMP TABLE IF NOT EXISTS temp_dma (LIKE SCHEMA_NAME.dma INCLUDING ALL);
				CREATE TEMP TABLE IF NOT EXISTS temp_presszone (LIKE SCHEMA_NAME.presszone INCLUDING ALL);
			END IF;
		END IF;

		--create temporal view
		CREATE OR REPLACE TEMP VIEW v_temp_anlgraph AS
		 SELECT temp_t_anlgraph.arc_id,
		    temp_t_anlgraph.node_1,
		    temp_t_anlgraph.node_2,
		    temp_t_anlgraph.flag,
		    a2.flag AS flagi,
		    a2.value,
		    a2.trace
		   FROM temp_t_anlgraph
		     JOIN ( SELECT temp_t_anlgraph_1.arc_id,
			    temp_t_anlgraph_1.node_1,
			    temp_t_anlgraph_1.node_2,
			    temp_t_anlgraph_1.water,
			    temp_t_anlgraph_1.flag,
			    temp_t_anlgraph_1.checkf,
			    temp_t_anlgraph_1.value,
			    temp_t_anlgraph_1.trace
			   FROM temp_t_anlgraph temp_t_anlgraph_1
			  WHERE temp_t_anlgraph_1.water = 1) a2 ON temp_t_anlgraph.node_1::text = a2.node_2::text
			  WHERE temp_t_anlgraph.flag < 2 AND temp_t_anlgraph.water = 0 AND a2.flag = 0;

		-- start build log message
		INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('MAPZONES DYNAMIC SECTORITZATION - ', upper(v_class)));
		IF upper(v_class) ='PRESSZONE' THEN
			INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('------------------------------------------------------------------'));
		ELSE
			INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('----------------------------------------------------------'));
		END IF;

		INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('Use psectors: ', upper(v_usepsector::text)));
		INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('Mapzone constructor method: ', upper(v_updatemapzgeom::text)));
		INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('Update feature mapzone attributes: ', upper(v_commitchanges::text)));
		INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('Previous data quality control: ', v_checkdata));

		IF v_floodonlymapzone IS NOT NULL THEN
			INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat('Flood only mapzone have been ACTIVATED, ',v_field, ':',v_floodonlymapzone,'.'));
		END IF;

		INSERT INTO temp_audit_check_data (fid, error_message) VALUES (v_fid, concat(''));
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 3, 'ERRORS');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 3, '-----------');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 2, '');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 2, 'WARNINGS');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 2, '--------------');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 1, 'INFO');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 1, '-------');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 0, 'DETAILS');
		INSERT INTO temp_audit_check_data (fid, result_id, criticity, error_message) VALUES (v_fid, NULL, 0, '----------');

		-- message for updatefeature false
		IF v_commitchanges IS FALSE THEN
			INSERT INTO temp_audit_check_data (fid, criticity, error_message)
			VALUES (v_fid, 1, concat('INFO: Mapzone attribute on arc/node/connec features keeps same value previous function. Nothing have been updated by this process'));
		END IF;

		-- fill temporal tables
		IF v_usepsector IS  TRUE THEN
			v_query_arc = 'SELECT a.* FROM arc a JOIN ve_arc USING (arc_id) WHERE a.expl_id IN ('||v_expl_id||')';
			v_query_node = 'SELECT n.* FROM node n JOIN ve_node USING (node_id) WHERE n.expl_id IN ('||v_expl_id||')';
			v_query_connec = 'SELECT c.* FROM connec c JOIN ve_connec USING (connec_id) WHERE c.expl_id IN ('||v_expl_id||')';
			v_query_link = 'SELECT l.* FROM link l JOIN ve_link USING (link_id) WHERE l.feature_type = ''CONNEC'' AND l.expl_id IN ('||v_expl_id||')';
			IF v_project_type='UD' THEN
				v_query_gully = 'SELECT g.* FROM gully g JOIN ve_gully USING (gully_id) WHERE g.expl_id IN ('||v_expl_id||')';
				v_query_link_gully = 'SELECT l.* FROM link l JOIN gully g ON g.gully_id = l.feature_id WHERE l.feature_type = ''GULLY'' AND l.expl_id IN ('||v_expl_id||')';
			END IF;
		ELSE
			v_query_arc = 'SELECT * FROM arc WHERE state=1 AND expl_id IN ('||v_expl_id||')';
			v_query_node = 'SELECT * FROM node WHERE state=1 AND expl_id IN ('||v_expl_id||')';
			v_query_connec = 'SELECT c.* FROM connec c JOIN arc a ON a.arc_id = c.arc_id WHERE c.state=1 AND a.state = 1 AND c.expl_id IN ('||v_expl_id||')';
			v_query_link = 'SELECT l.* FROM link l join connec c ON c.connec_id = l.feature_id WHERE c.state=1 AND l.state =1 AND l.feature_type = ''CONNEC'' AND l.expl_id IN ('||v_expl_id||')';
			IF v_project_type='UD' THEN
				v_query_gully = 'SELECT g.* FROM gully g JOIN arc a ON a.arc_id = g.arc_id WHERE g.state=1 AND a.state = 1 AND g.expl_id IN ('||v_expl_id||')';
				v_query_link_gully = 'SELECT l.* FROM link l join gully g ON g.gully_id = l.feature_id WHERE g.state=1 AND l.state =1 AND l.feature_type = ''GULLY'' AND l.expl_id IN ('||v_expl_id||')';
			END IF;
		END IF;

		EXECUTE 'INSERT INTO temp_t_arc '||v_query_arc;
		EXECUTE 'INSERT INTO temp_t_node '||v_query_node;
		EXECUTE 'INSERT INTO temp_t_connec '||v_query_connec;
		EXECUTE 'INSERT INTO temp_t_link '||v_query_link;

		IF v_project_type = 'UD' THEN
			EXECUTE 'INSERT INTO temp_t_gully '||v_query_gully;
			EXECUTE 'INSERT INTO temp_t_link '||v_query_link_gully;
		END IF;

		-- update temp_t_connec in order to get correct arc_id (for planified features, arc_id from parent layer is NULL)
		UPDATE temp_t_connec t SET arc_id=c.arc_id FROM ve_connec c WHERE t.connec_id=c.connec_id;

		IF v_class = 'SECTOR' THEN
			EXECUTE 'INSERT INTO temp_'||v_table||' SELECT * FROM '||v_table||' WHERE active is true AND sector_id IN (SELECT distinct '||v_field||' FROM temp_t_arc)';
		ELSE
			IF v_netscenario IS NOT NULL THEN
				EXECUTE 'INSERT INTO temp_'||v_table||' SELECT * FROM plan_netscenario_'||v_table||' WHERE active is true AND netscenario_id = '||v_netscenario;
			ELSE
				IF v_table IN ('dma', 'presszone', 'dqa') THEN
					EXECUTE 'INSERT INTO temp_'||v_table||' SELECT * FROM '||v_table||' WHERE active is true AND expl_id && string_to_array(''' || v_expl_id || ''', '','')::int[]';
				ELSE
					EXECUTE 'INSERT INTO temp_'||v_table||' SELECT * FROM '||v_table||' WHERE active is true AND expl_id IN ('||v_expl_id||')';
				END IF;
			END IF;
		END IF;

		EXECUTE 'UPDATE temp_'||v_table||' SET the_geom = null';

		-- reset elements to 0
		IF v_floodonlymapzone IS NULL THEN
			v_querytext = 'UPDATE temp_t_arc a SET '||quote_ident(v_field)||' = 0 WHERE a.expl_id IN('||v_expl_id||')';
			EXECUTE v_querytext;
			v_querytext = 'UPDATE temp_t_node a SET '||quote_ident(v_field)||' = 0 WHERE a.expl_id IN('||v_expl_id||')';
			EXECUTE v_querytext;
			v_querytext = 'UPDATE temp_t_connec a SET '||quote_ident(v_field)||' = 0 WHERE a.expl_id IN('||v_expl_id||')';
			EXECUTE v_querytext;

			IF v_project_type='UD' THEN
				v_querytext = 'UPDATE temp_t_gully a SET '||quote_ident(v_field)||' = 0 WHERE a.expl_id IN('||v_expl_id||')';
				EXECUTE v_querytext;
			END IF;
		ELSE
			v_querytext = 'UPDATE temp_t_arc SET '||quote_ident(v_field)||' = 0 WHERE '||quote_ident(v_field)||'::integer IN ('||v_floodonlymapzone||')';
			EXECUTE v_querytext;
			v_querytext = 'UPDATE temp_t_node SET '||quote_ident(v_field)||' = 0 WHERE '||quote_ident(v_field)||'::integer IN ('||v_floodonlymapzone||')';
			EXECUTE v_querytext;
			v_querytext = 'UPDATE temp_t_connec SET '||quote_ident(v_field)||' = 0 WHERE '||quote_ident(v_field)||'::integer IN ('||v_floodonlymapzone||')';
			EXECUTE v_querytext;

			IF v_project_type='UD' THEN
				v_querytext = 'UPDATE temp_t_gully SET '||quote_ident(v_field)||' = 0 WHERE '||quote_ident(v_field)||'::integer IN ('||v_floodonlymapzone||')';
				EXECUTE v_querytext;
			END IF;
		END IF;

		-- fill the graph table
		IF v_class = 'DRAINZONE' THEN
			EXECUTE 'INSERT INTO temp_t_anlgraph (arc_id, node_1, node_2, water, flag, checkf)
			SELECT arc_id::integer, node_2::integer, node_1::integer, 0, 0, 0 FROM temp_t_arc a JOIN value_state_type ON state_type=id 
			WHERE node_1 IS NOT NULL AND node_2 IS NOT NULL AND value_state_type.is_operative=TRUE';
		ELSE
			EXECUTE 'INSERT INTO temp_t_anlgraph (arc_id, node_1, node_2, water, flag, checkf)
			SELECT arc_id::integer, node_1::integer, node_2::integer, 0, 0, 0 FROM temp_t_arc a JOIN value_state_type ON state_type=id 
			WHERE node_1 IS NOT NULL AND node_2 IS NOT NULL AND value_state_type.is_operative=TRUE
			UNION
			SELECT arc_id::integer, node_2::integer, node_1::integer, 0, 0, 0 FROM temp_t_arc a JOIN value_state_type ON state_type=id 
			WHERE node_1 IS NOT NULL AND node_2 IS NOT NULL AND value_state_type.is_operative=TRUE';
		END IF;

		IF v_netscenario IS NOT NULL THEN
			-- close custom nodes acording config parameters
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_1 IN (SELECT (json_array_elements_text((graphconfig->>''forceClosed'')::json))::integer FROM plan_netscenario_'
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE AND netscenario_id = '||v_netscenario||')';
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_2 IN (SELECT (json_array_elements_text((graphconfig->>''forceClosed'')::json))::integer FROM plan_netscenario_'
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE AND netscenario_id = '||v_netscenario||')';

			-- set header node for mapzones
			v_text = 'SELECT node_id FROM ( SELECT ((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')::integer AS node_id 
			FROM plan_netscenario_'||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE AND netscenario_id = '||v_netscenario||')a';
		ELSE
			-- close custom nodes acording config parameters
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_1 IN (SELECT (json_array_elements_text((graphconfig->>''forceClosed'')::json))::integer FROM '
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE)';
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_2 IN (SELECT (json_array_elements_text((graphconfig->>''forceClosed'')::json))::integer FROM '
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE)';

			-- set header node for mapzones
			v_text = 'SELECT ((elem)::json->>''nodeParent'')::integer AS node_id FROM '||quote_ident(v_table)||', LATERAL json_array_elements_text((graphconfig->>''use'')::json) AS elem WHERE graphconfig IS NOT NULL AND active IS TRUE AND trim((elem)::json->>''nodeParent'') ~ ''^\d+$''';
		END IF;

		-- close boundary conditions acording closed column (flag=1)
		IF v_class !='DRAINZONE' THEN
			v_querytext  = 'UPDATE temp_t_anlgraph SET flag=1 WHERE 
				node_1::integer IN (
				SELECT a.node_id::integer FROM temp_t_node a JOIN cat_node b ON nodecat_id=b.id JOIN cat_feature_node c ON c.id=b.node_type 
				LEFT JOIN man_valve d ON a.node_id::integer=d.node_id::integer 
				JOIN temp_t_anlgraph e ON a.node_id::integer=e.node_1::integer 
				WHERE closed=TRUE)';
			EXECUTE v_querytext;

			v_querytext  = 'UPDATE temp_t_anlgraph SET flag=1 WHERE 
				node_2::integer IN (
				SELECT (a.node_id::integer) FROM temp_t_node a JOIN cat_node b ON nodecat_id=b.id JOIN cat_feature_node c ON c.id=b.node_type 
				LEFT JOIN man_valve d ON a.node_id::integer=d.node_id::integer 
				JOIN temp_t_anlgraph e ON a.node_id::integer=e.node_1::integer 
				WHERE closed=TRUE)';
			EXECUTE v_querytext;

			IF v_netscenario IS NOT NULL THEN
			--close valve
				v_querytext  = 'UPDATE temp_t_anlgraph SET flag=1 WHERE 
				node_1::integer IN (
				SELECT a.node_id::integer 
				FROM plan_netscenario_valve a 
				WHERE closed IS TRUE
				AND netscenario_id = '||v_netscenario||'::integer) 
				OR node_2::integer IN (
				SELECT a.node_id::integer 
				FROM plan_netscenario_valve a 
				WHERE closed IS TRUE
				AND netscenario_id = '||v_netscenario||'::integer)';
			EXECUTE v_querytext;

			--òpen valve
			v_querytext  = 'UPDATE temp_t_anlgraph SET flag=0 WHERE 
				node_1::integer IN (
				SELECT a.node_id::integer 
				FROM plan_netscenario_valve a 
				WHERE closed IS FALSE
				AND netscenario_id = '||v_netscenario||'::integer) 
				OR node_2::integer IN (
				SELECT a.node_id::integer 
				FROM plan_netscenario_valve a 
				WHERE closed IS FALSE
				AND netscenario_id = '||v_netscenario||'::integer)';
			EXECUTE v_querytext;
			END IF;
		END IF;

		IF v_netscenario IS NOT NULL THEN
			-- open custom nodes acording config parameters
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 0 WHERE node_1 IN (SELECT (json_array_elements_text((graphconfig->>''forceOpen'')::json))::integer FROM plan_netscenario_'
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE AND netscenario_id = '||v_netscenario||') ';
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 0 WHERE node_2 IN (SELECT (json_array_elements_text((graphconfig->>''forceOpen'')::json))::integer FROM plan_netscenario_'
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE AND netscenario_id = '||v_netscenario||')';

			-- close customized stoppers acording on graphconfig column on mapzone table
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_1 IN (SELECT (json_array_elements_text((graphconfig->>''stopper'')::json))::integer AS node_id FROM plan_netscenario_'||quote_ident(v_table)||' WHERE netscenario_id = '||v_netscenario||')';
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_2 IN (SELECT (json_array_elements_text((graphconfig->>''stopper'')::json))::integer AS node_id FROM plan_netscenario_'||quote_ident(v_table)||' WHERE netscenario_id = '||v_netscenario||')';
		ELSE
			-- open custom nodes acording config parameters
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 0 WHERE node_1 IN (SELECT (json_array_elements_text((graphconfig->>''forceOpen'')::json))::integer FROM '
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE)';
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 0 WHERE node_2 IN (SELECT (json_array_elements_text((graphconfig->>''forceOpen'')::json))::integer FROM '
			||quote_ident(v_table)||' WHERE graphconfig IS NOT NULL AND active IS TRUE)';

			-- close customized stoppers acording on graphconfig column on mapzone table
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_1 IN (SELECT (json_array_elements_text((graphconfig->>''stopper'')::json))::integer AS node_id FROM '||quote_ident(v_table)||')';
			EXECUTE 'UPDATE temp_t_anlgraph SET flag = 1 WHERE node_2 IN (SELECT (json_array_elements_text((graphconfig->>''stopper'')::json))::integer AS node_id FROM '||quote_ident(v_table)||')';
		END IF;

		-- close checkvalves on the opposite sense where they are working
		IF v_class !='DRAINZONE' THEN
			UPDATE temp_t_anlgraph SET flag=1 WHERE id IN (
			SELECT id FROM temp_t_anlgraph JOIN (
			SELECT node_id, to_arc from config_graph_checkvalve order by 1,2) a
			ON to_arc::integer=arc_id::integer WHERE node_id::integer=node_2::integer);
		END IF;

		-- close custom nodes acording init parameters
		UPDATE temp_t_anlgraph SET flag = 1 WHERE node_1 IN (SELECT (json_array_elements_text((v_parameters->>'forceClosed')::json))::integer);
		UPDATE temp_t_anlgraph SET flag = 1 WHERE node_2 IN (SELECT (json_array_elements_text((v_parameters->>'forceClosed')::json))::integer);

		-- open custom nodes acording init parameters
		UPDATE temp_t_anlgraph SET flag = 0 WHERE node_1 IN (SELECT (json_array_elements_text((v_parameters->>'forceOpen')::json))::integer);
		UPDATE temp_t_anlgraph SET flag = 0 WHERE node_2 IN (SELECT (json_array_elements_text((v_parameters->>'forceOpen')::json))::integer);

		-- Close mapzone headers
		v_querytext  = 'UPDATE temp_t_anlgraph SET flag=1 WHERE node_1::integer IN ('||v_text||')';
		EXECUTE v_querytext;
		v_querytext  = 'UPDATE temp_t_anlgraph SET flag=1 WHERE node_2::integer IN ('||v_text||')';
		EXECUTE v_querytext;

		--moved after Close mapzone headers
		v_text =  concat ('SELECT * FROM (',v_text,')a JOIN temp_t_anlgraph e ON a.node_id::integer=e.node_1::integer');

		-- Open mapzone headers BUT ONLY ENABLING the right sense (to_arc)
		IF v_class = 'SECTOR' THEN
			-- sector (sector.graphconfig)
			UPDATE temp_t_anlgraph SET flag=0, isheader = true WHERE id IN (
			SELECT id FROM temp_t_anlgraph JOIN (
			SELECT ((json_array_elements_text((graphconfig->>'use')::json))::json->>'nodeParent')::integer AS node_id,
			json_array_elements_text(((json_array_elements_text((graphconfig->>'use')::json))::json->>'toArc')::json)::integer
			as to_arc from sector
			where graphconfig is not null and active is true order by 1,2) a
			ON to_arc::integer=arc_id::integer WHERE node_id::integer=node_1::integer);

		ELSIF v_class = 'DMA' THEN
			IF v_netscenario IS NOT NULL THEN
				-- dma (dma.graphconfig)
				EXECUTE 'UPDATE temp_t_anlgraph SET flag=0, isheader = true WHERE id IN (
				SELECT id FROM temp_t_anlgraph JOIN (
				SELECT ((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')::integer AS node_id, 
				json_array_elements_text(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''toArc'')::json)::integer
				as to_arc from plan_netscenario_dma 
				where graphconfig is not null and active is true AND netscenario_id = '||v_netscenario::integer||' order by 1,2) a
				ON to_arc::integer=arc_id::integer WHERE node_id::integer=node_1::integer);';
			ELSE
				-- dma (dma.graphconfig)
				UPDATE temp_t_anlgraph SET flag=0, isheader = true WHERE id IN (
				SELECT id FROM temp_t_anlgraph JOIN (
				SELECT ((json_array_elements_text((graphconfig->>'use')::json))::json->>'nodeParent')::integer AS node_id,
				json_array_elements_text(((json_array_elements_text((graphconfig->>'use')::json))::json->>'toArc')::json)::integer
				as to_arc from dma
				where graphconfig is not null and active is true order by 1,2) a
				ON to_arc::integer=arc_id::integer WHERE node_id::integer=node_1::integer);
			END IF;

		ELSIF v_class = 'DQA' THEN
			-- dqa (dqa.graphconfig)
			UPDATE temp_t_anlgraph SET flag=0, isheader = true WHERE id IN (
			SELECT id FROM temp_t_anlgraph JOIN (
			SELECT ((json_array_elements_text((graphconfig->>'use')::json))::json->>'nodeParent')::integer AS node_id,
			json_array_elements_text(((json_array_elements_text((graphconfig->>'use')::json))::json->>'toArc')::json)::integer
			as to_arc from dqa
			where graphconfig is not null and active is true order by 1,2) a
			ON to_arc::integer=arc_id::integer WHERE node_id::integer=node_1::integer);

		ELSIF v_class = 'PRESSZONE' THEN
			IF v_netscenario IS NOT NULL THEN
				-- presszone (presszone.graphconfig)
				EXECUTE 'UPDATE temp_t_anlgraph SET flag=0, isheader = true WHERE id IN (
				SELECT id FROM temp_t_anlgraph JOIN (
				SELECT ((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')::integer AS node_id, 
				json_array_elements_text(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''toArc'')::json)::integer
				as to_arc from plan_netscenario_presszone
				where graphconfig is not null and active is true AND netscenario_id = '||v_netscenario::integer||' order by 1,2) a
				ON to_arc::integer=arc_id::integer WHERE node_id::integer=node_1::integer);';
			ELSE
				-- presszone (presszone.graphconfig)
				UPDATE temp_t_anlgraph SET flag=0, isheader = true WHERE id IN (
				SELECT id FROM temp_t_anlgraph JOIN (
				SELECT ((json_array_elements_text((graphconfig->>'use')::json))::json->>'nodeParent')::integer AS node_id,
				json_array_elements_text(((json_array_elements_text((graphconfig->>'use')::json))::json->>'toArc')::json)::integer
				as to_arc from presszone
				where graphconfig is not null and active is true order by 1,2) a
				ON to_arc::integer=arc_id::integer WHERE node_id::integer=node_1::integer);
			END IF;
		END IF;

		IF v_class != 'DRAINZONE' THEN

			-- set the starting element (water)
			IF v_netscenario IS NOT NULL THEN
				IF v_floodonlymapzone IS NULL THEN
					v_querytext = 'UPDATE temp_t_anlgraph SET water=1, trace = '||v_fieldmp||'::integer 
					FROM plan_netscenario_'||v_table||' 
					WHERE graphconfig is not null 
						AND active is true 
						AND flag=0 
						AND netscenario_id = '||v_netscenario||' 
						AND node_1 IN (
							SELECT node_id FROM (
								SELECT nullif(trim(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')), '''')::integer as node_id
								FROM plan_netscenario_'||v_table||'
								WHERE graphconfig is not null and active is true AND netscenario_id = '||v_netscenario||'
							) t WHERE node_id IS NOT NULL
						)';
					EXECUTE v_querytext;
				ELSE
					v_querytext = 'UPDATE temp_t_anlgraph SET water=1, trace = '||v_fieldmp||'::integer 
					FROM plan_netscenario_'||v_table||' 
					WHERE graphconfig is not null 
						AND active is true 
						AND '||v_fieldmp||'::integer IN ('||v_floodonlymapzone||') 
						AND flag=0 
						AND netscenario_id = '||v_netscenario||'
						AND node_1 IN (
							SELECT node_id FROM (
								SELECT nullif(trim(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')), '''')::integer as node_id
								FROM plan_netscenario_'||v_table||'
								WHERE graphconfig is not null and active is true AND netscenario_id = '||v_netscenario||'
							) t WHERE node_id IS NOT NULL
						)';
					EXECUTE v_querytext;
				END IF;
			ELSE

				IF v_floodonlymapzone IS NULL THEN
					v_querytext = 'UPDATE temp_t_anlgraph SET water=1, trace = '||v_fieldmp||'::integer 
					FROM '||v_table||' WHERE graphconfig is not null and active is true AND flag=0 
					AND node_1 IN (
						SELECT node_id FROM (
							SELECT nullif(trim(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')), '''')::integer as node_id
							FROM '||v_table||'
							WHERE graphconfig is not null and active is true
						) t WHERE node_id IS NOT NULL
					)';
					EXECUTE v_querytext;
				ELSE
					v_querytext = 'UPDATE temp_t_anlgraph SET water=1, trace = '||v_fieldmp||'::integer 
					FROM '||v_table||' WHERE graphconfig is not null and active is true AND '||v_fieldmp||'::integer IN ('||v_floodonlymapzone||') AND flag=0 
					AND node_1 IN (
						SELECT node_id FROM (
							SELECT nullif(trim(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')), '''')::integer as node_id
							FROM '||v_table||'
							WHERE graphconfig is not null and active is true
						) t WHERE node_id IS NOT NULL
					)';
					EXECUTE v_querytext;
				END IF;
			END IF;
		ELSE

			IF v_floodonlymapzone IS NULL THEN
				v_querytext = 'UPDATE temp_t_anlgraph SET water=1, flag=0, trace = '||v_fieldmp||'::integer 
				FROM '||v_table||' WHERE graphconfig is not null and active is true
				AND node_1 IN (
					SELECT node_id FROM (
						SELECT nullif(trim(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')), '''')::integer as node_id
						FROM '||v_table||'
						WHERE graphconfig is not null and active is true
					) t WHERE node_id IS NOT NULL
				)';
				EXECUTE v_querytext;
			ELSE
				v_querytext = 'UPDATE temp_t_anlgraph SET water=1, flag=0, trace = '||v_fieldmp||'::integer 
				FROM '||v_table||' WHERE graphconfig is not null and active is true AND '||v_fieldmp||'::integer IN ('||v_floodonlymapzone||')
				AND node_1 IN (
					SELECT node_id FROM (
						SELECT nullif(trim(((json_array_elements_text((graphconfig->>''use'')::json))::json->>''nodeParent'')), '''')::integer as node_id
						FROM '||v_table||'
						WHERE graphconfig is not null and active is true
					) t WHERE node_id IS NOT NULL
				)';
				EXECUTE v_querytext;
			END IF;
		END IF;

		-- inundation process
		LOOP
			v_count = v_count+1;
			UPDATE temp_t_anlgraph n SET water=1, trace = a.trace, checkf = v_count FROM v_temp_anlgraph a where n.node_1::integer = a.node_1::integer AND n.arc_id = a.arc_id;
			GET DIAGNOSTICS v_affectrow = row_count;
			EXIT WHEN v_affectrow = 0;
			EXIT WHEN v_count = 5000;
		END LOOP;

		RAISE NOTICE 'Finish engine....';

		RAISE NOTICE ' Update temporal table of arcs';
		v_querytext = 'UPDATE temp_t_arc SET '||quote_ident(v_field)||' = trace FROM temp_t_anlgraph t WHERE temp_t_arc.arc_id = t.arc_id AND water = 1 AND trace is not null';
		EXECUTE v_querytext;

		RAISE NOTICE ' Update temporal table of nodes';
		-- update disconnected nodes from parent arcs
		v_querytext = 'UPDATE temp_t_node SET '||quote_ident(v_field)||' = a.'||quote_ident(v_field)||' FROM temp_t_arc a WHERE a.arc_id=temp_t_node.arc_id';
		EXECUTE v_querytext;

		-- update whole nodes
		EXECUTE 'UPDATE temp_t_node SET '||quote_ident(v_field)||' = trace FROM (
		SELECT distinct on(node) node, trace FROM(
		select node, count(*) c, trace FROM(
		select id, node, arc_id, trace, flag from(
		select id, node_1 node, arc_id, trace, flag from temp_t_anlgraph where trace > 0 and flag = 0
		union all
		select id, node_2, arc_id, trace, flag from temp_t_anlgraph where trace > 0 and flag = 0)a
		order by node
		)b group by node, trace order by 1, 2 desc
		)c order by node, c desc)a
		WHERE node = node_id';

		RAISE NOTICE ' Update temporal tables of connects and links';

		-- used connec using ve_arc because the exploitation filter (same before)
		v_querytext = 'UPDATE temp_t_connec SET '||quote_ident(v_field)||' = a.'||quote_ident(v_field)||' FROM temp_t_arc a WHERE a.arc_id=temp_t_connec.arc_id';
		EXECUTE v_querytext;

		v_querytext = 'UPDATE temp_t_connec SET '||quote_ident(v_field)||' = a.'||quote_ident(v_field)||' FROM temp_t_node a WHERE temp_t_connec.arc_id IS NULL AND a.node_id=temp_t_connec.pjoint_id';
		EXECUTE v_querytext;

		-- update link table
		EXECUTE 'UPDATE temp_t_link SET '||quote_ident(v_field)||' = c.'||quote_ident(v_field)||' FROM temp_t_connec c WHERE c.connec_id=feature_id';

		IF v_project_type='UD' THEN

			v_querytext = 'UPDATE temp_t_gully SET '||quote_ident(v_field)||' = a.'||quote_ident(v_field)||' FROM temp_t_arc a WHERE a.arc_id=temp_t_gully.arc_id';
			EXECUTE v_querytext;

			-- update link table
			EXECUTE 'UPDATE temp_t_link SET '||quote_ident(v_field)||' = g.'||quote_ident(v_field)||' FROM temp_t_gully g WHERE g.gully_id=feature_id';
		END IF;

		IF v_islastupdate IS TRUE THEN

			v_querytext = 'UPDATE temp_t_arc SET updated_at = now(), updated_by=current_user FROM temp_t_anlgraph t WHERE temp_t_arc.arc_id = t.arc_id AND water = 1';
			EXECUTE v_querytext;

			v_querytext = 'UPDATE temp_t_node SET updated_at = now(), updated_by=current_user FROM temp_t_arc a WHERE a.arc_id=temp_t_node.arc_id';
			EXECUTE v_querytext;

			EXECUTE 'UPDATE temp_t_node SET updated_at = now(), updated_by=current_user  FROM (
			SELECT distinct on(node) node, trace FROM(

			select node, count(*) c, trace FROM(
			select id, node, arc_id, trace, flag from(
			select id, node_1 node, arc_id, trace, flag from temp_t_anlgraph where trace > 0 and flag = 0
			union all
			select id, node_2, arc_id, trace, flag from temp_t_anlgraph where trace > 0 and flag = 0)a
			order by node
			)b group by node, trace order by 1, 2 desc
			
			)c order by node, c desc)a
			WHERE node = node_id';

			v_querytext = 'UPDATE temp_t_connec SET updated_at = now(), updated_by=current_user FROM temp_t_arc a WHERE a.arc_id=temp_t_connec.arc_id';
			EXECUTE v_querytext;

			-- update link table
			EXECUTE 'UPDATE temp_t_link SET updated_at = now(), updated_by=current_user;';

			IF v_project_type='UD' THEN
				v_querytext = 'UPDATE temp_t_gully SET updated_at = now(), updated_by=current_user FROM temp_t_arc a WHERE a.arc_id=temp_t_gully.arc_id';
				EXECUTE v_querytext;
			END IF;
		END IF;

		-- recalculate staticpressure (fid=147)
		IF v_fid=146 THEN

			RAISE NOTICE ' Update staticpressure';

			INSERT INTO temp_t_data (fid, feature_type, feature_id, log_message)
			SELECT 147, 'node', n.node_id,
			concat('{"staticpressure":',case when (pz.head - n.top_elev::float + (case when n.depth is null then 0 else n.depth end)::float) is null
			then 0 ELSE (pz.head - n.top_elev::float + (case when n.depth is null then 0 else n.depth end)) END, '}')
			FROM temp_t_node n
			JOIN
				(SELECT distinct on(node) node as node_id, trace as presszone_id FROM(
				select node, count(*) c, trace FROM(
				select id, node, arc_id, trace, flag from(
				select id, node_1 node, arc_id, trace, flag from temp_t_anlgraph where trace > 0 and flag = 0
				union all
				select id, node_2, arc_id, trace, flag from temp_t_anlgraph where trace > 0 and flag = 0)a
				order by node
				)b group by node, trace order by 1, 2 desc
				)c order by node, c desc) t USING (node_id)
			JOIN temp_presszone pz ON pz.presszone_id = t.presszone_id;

			-- update on node table those elements connected on graph
			UPDATE temp_t_node SET staticpressure=(log_message::json->>'staticpressure')::float FROM temp_t_data a WHERE a.feature_id=node_id
			AND fid=147 AND cur_user=current_user;

			/*
			-- update on node table those elements disconnected from graph
			IF v_usepsector is false then
				EXECUTE 'UPDATE temp_t_node SET staticpressure=(staticpressure1-(staticpressure1-staticpressure2)*st_linelocatepoint(temp_t_arc.the_geom, n.the_geom))::numeric(12,3)
				FROM temp_t_arc, temp_t_node n
				WHERE st_dwithin(temp_t_arc.the_geom, n.the_geom, 0.05::double precision) AND temp_t_arc.state = 1 AND n.state =1
				and n.arc_id IS NOT NULL AND temp_t_node.node_id=n.node_id and n.expl_id='||v_expl_id||';';
			END IF;
			*/

			-- update connec table
			EXECUTE 'UPDATE temp_t_connec SET staticpressure =(b.head - b.top_elev + (case when b.depth is null then 0 else b.depth end)::float) FROM 
				(SELECT connec_id, head, top_elev, depth FROM temp_t_connec c JOIN temp_t_link ON feature_id = connec_id
				JOIN temp_presszone p ON c.presszone_id = p.presszone_id) b
				WHERE temp_t_connec.connec_id=b.connec_id;';

			-- update link table
			EXECUTE 'UPDATE temp_t_link SET staticpressure1 =(b.head - b.top_elev + (case when b.depth is null then 0 else b.depth end)::float) FROM 
				(SELECT link_id, head, top_elev, depth FROM temp_t_connec c JOIN temp_t_link ON feature_id = connec_id
				JOIN temp_presszone p ON c.presszone_id = p.presszone_id) b
				WHERE temp_t_link.link_id=b.link_id;';

		END IF;

		IF v_updatemapzgeom > 0 THEN
			-- message
			INSERT INTO temp_audit_check_data (fid, criticity, error_message)
			VALUES (v_fid, 1, concat('INFO: ',v_class,' values for features and geometry of the mapzone has been modified by this process'));
		END IF;

		IF v_floodonlymapzone IS NULL THEN

			RAISE NOTICE 'Check for conflicts';

			IF v_class != 'DRAINZONE' THEN

				-- manage conflicts (nodes no headers and no stoppers with different mapzones)
				FOR rec_conflict IN EXECUTE'
					SELECT DISTINCT concat(quote_literal(m1),'','', quote_literal(m2)) as mapzone from 
					(SELECT n.'||v_field||' m1, a.'||v_field||' m2 FROM temp_t_node n JOIN temp_t_arc a ON node_id = node_1 WHERE node_id not in
					(select node_1 from temp_t_anlgraph WHERE flag = 1 UNION select node_2 from temp_t_anlgraph WHERE flag = 1)
					UNION
					SELECT n.'||v_field||' m1, a.'||v_field||' m2 FROM temp_t_node n JOIN temp_t_arc a ON node_id = node_2 WHERE node_id not in
					(select node_1 from temp_t_anlgraph WHERE flag = 1 UNION select node_2 from temp_t_anlgraph WHERE flag = 1)) a
					WHERE m1::text != m2::text AND m1::text !=''0'' AND m2::text !=''0'''

				LOOP
					RAISE NOTICE 'Managing conflicts -> %', rec_conflict;

					-- update & count features
					--arc
					EXECUTE 'UPDATE temp_t_arc t SET '||v_field||' = -1  WHERE '||v_field||'::text IN ('||rec_conflict.mapzone||')';
					GET DIAGNOSTICS v_count1 = row_count;
					raise notice 'Updated % conflict rows on arc', v_count1;

					-- node
					EXECUTE 'UPDATE temp_t_node t SET '||v_field||' = -1  WHERE '||v_field||'::text IN ('||rec_conflict.mapzone||')';
					raise notice 'Updated % conflict rows on node', v_count1;

					-- connec
					EXECUTE 'UPDATE temp_t_connec t SET '||v_field||' = -1  WHERE '||v_field||'::text IN ('||rec_conflict.mapzone||')';
					GET DIAGNOSTICS v_count = row_count;
					raise notice 'Updated % conflict rows on connec', v_count;

					-- log
					IF v_count1 > 0 or v_count > 0 THEN
						INSERT INTO temp_audit_check_data (fid,  criticity, error_message)
						VALUES (v_fid, 2, concat('WARNING-395: There is a conflict against ',upper(v_table),'''s (',rec_conflict.mapzone,') with ',v_count1,' arc(s) and ',v_count,' connec(s) affected.'));
					END IF;

					-- update mapzone geometry
					IF v_netscenario IS NOT NULL THEN
						EXECUTE 'UPDATE plan_netscenario_'||v_table||' SET the_geom = null WHERE '||v_fieldmp||'::text IN ('||rec_conflict.mapzone||') AND netscenario_id = '||v_netscenario||';';
					ELSE
						EXECUTE 'UPDATE '||v_table||' SET the_geom = null WHERE '||v_fieldmp||'::text IN ('||rec_conflict.mapzone||')';
					END IF;

					-- setting the graph for conflict
					EXECUTE 'UPDATE temp_t_anlgraph t SET water = -1 FROM temp_t_arc v WHERE t.arc_id = v.arc_id AND v.'||v_field||'::integer = -1';
				END LOOP;
			END IF;

			-- create log
			IF v_project_type='UD' THEN

				v_querytext = ' INSERT INTO temp_audit_check_data (fid, criticity, error_message)
				SELECT '||v_fid||', 0, concat('||v_mapzonename||','' with '', arcs, '' Arcs, '',nodes, '' Nodes, '', case when connecs is null then 0 else connecs end, '' Connecs and '',
				 case when gullies is null then 0 else gullies end, '' Gullies'')
				FROM (SELECT '||(v_field)||', count(*) as arcs FROM temp_t_arc a WHERE '||(v_field)||'::integer > 0 '
				' GROUP BY '||(v_field)||')e
				LEFT JOIN (SELECT '||(v_field)||', count(*) as nodes FROM temp_t_node n WHERE '||(v_field)||'::integer > 0 '
				' GROUP BY '||(v_field)||')b USING ('||(v_field)||')
				LEFT JOIN (SELECT '||(v_field)||', count(*) as connecs FROM temp_t_connec c WHERE '||(v_field)||'::integer > 0 '
				' GROUP BY '||(v_field)||')c USING ('||(v_field)||')
				LEFT JOIN (SELECT '||(v_field)||', count(*) as gullies FROM temp_t_gully g WHERE '||(v_field)||'::integer > 0 '
				' GROUP BY '||(v_field)||')d USING ('||(v_field)||')
				JOIN '||(v_table)||' p ON e.'||(v_field)||' = p.'||(v_field);
				EXECUTE v_querytext;
			ELSE
				IF v_netscenario IS NOT NULL THEN
					v_querytext = ' INSERT INTO temp_audit_check_data (fid, criticity, error_message)
					SELECT '||v_fid||', 0, concat('||v_mapzonename||','' with '', arcs, '' Arcs, '',nodes, '' Nodes and '', case when connecs is null then 0 else connecs end, '' Connecs'')
					FROM (SELECT '||(v_field)||', count(*) as arcs FROM temp_t_arc a WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')e
					LEFT JOIN (SELECT '||(v_field)||', count(*) as nodes FROM temp_t_node n WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')b USING ('||(v_field)||')
					LEFT JOIN (SELECT '||(v_field)||', count(*) as connecs FROM temp_t_connec c WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')c USING ('||(v_field)||')
					JOIN plan_netscenario_'||(v_table)||' p ON e.'||(v_field)||' = p.'||(v_field);
				ELSE
					v_querytext = ' INSERT INTO temp_audit_check_data (fid, criticity, error_message)
					SELECT '||v_fid||', 0, concat('||v_mapzonename||','' with '', arcs, '' Arcs, '',nodes, '' Nodes and '', case when connecs is null then 0 else connecs end, '' Connecs'')
					FROM (SELECT '||(v_field)||', count(*) as arcs FROM temp_t_arc a WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')e
					LEFT JOIN (SELECT '||(v_field)||', count(*) as nodes FROM temp_t_node n WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')b USING ('||(v_field)||')
					LEFT JOIN (SELECT '||(v_field)||', count(*) as connecs FROM temp_t_connec c WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')c USING ('||(v_field)||')
					JOIN '||(v_table)||' p ON e.'||(v_field)||' = p.'||(v_field);
				END IF;

				EXECUTE v_querytext;
			END IF;

		ELSE
			IF v_project_type='UD' THEN
				v_querytext = ' INSERT INTO temp_audit_check_data (fid, criticity, error_message)
				SELECT '||v_fid||', 0, concat('||v_mapzonename||','' with '', arcs, '' Arcs, '',nodes, '' Nodes, '', case when connecs is null then 0 else connecs end, '' Connecs and '',
				 case when gullies is null then 0 else gullies end, '' Gullies'')
				FROM (SELECT '||(v_field)||', count(*) as arcs FROM temp_t_arc a  WHERE '||(v_field)||'::integer > 0  GROUP BY '||(v_field)||')e
				LEFT JOIN (SELECT '||(v_field)||', count(*) as nodes FROM temp_t_node n WHERE '||(v_field)||'::integer > 0  GROUP BY '||(v_field)||')b USING ('||(v_field)||')
				LEFT JOIN (SELECT '||(v_field)||', count(*) as connecs FROM temp_t_connec c WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')c USING ('||(v_field)||')
				LEFT JOIN (SELECT '||(v_field)||', count(*) as gullies FROM temp_t_gully g WHERE '||(v_field)||'::integer > 0  GROUP BY '||(v_field)||')d USING ('||(v_field)||')
				JOIN '||(v_table)||' p ON e.'||(v_field)||' = p.'||(v_field)||'
				WHERE e.'||(v_field)||'::text = '||quote_literal(v_floodonlymapzone);
				EXECUTE v_querytext;
			ELSE
				IF v_netscenario IS NOT NULL THEN
					v_querytext = ' INSERT INTO temp_audit_check_data (fid, criticity, error_message)
					SELECT '||v_fid||', 0, concat('||v_mapzonename||','' with '', arcs, '' Arcs, '',nodes, '' Nodes and '', case when connecs is null then 0 else connecs end, '' Connecs'')
					FROM (SELECT '||(v_field)||', count(*) as arcs FROM temp_t_arc a WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')e
					LEFT JOIN (SELECT '||(v_field)||', count(*) as nodes FROM temp_t_node n WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')b USING ('||(v_field)||')
					LEFT JOIN (SELECT '||(v_field)||', count(*) as connecs FROM temp_t_connec c WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')c USING ('||(v_field)||')
					JOIN plan_netscenario_'||(v_table)||' p ON e.'||(v_field)||' = p.'||(v_field)||'
					WHERE p.'||(v_field)||'::text = '||quote_literal(v_floodonlymapzone)||'::text';
				ELSE
					v_querytext = ' INSERT INTO temp_audit_check_data (fid, criticity, error_message)
					SELECT '||v_fid||', 0, concat('||v_mapzonename||','' with '', arcs, '' Arcs, '',nodes, '' Nodes and '', case when connecs is null then 0 else connecs end, '' Connecs'')
					FROM (SELECT '||(v_field)||', count(*) as arcs FROM temp_t_arc a WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')e
					LEFT JOIN (SELECT '||(v_field)||', count(*) as nodes FROM temp_t_node n WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')b USING ('||(v_field)||')
					LEFT JOIN (SELECT '||(v_field)||', count(*) as connecs FROM temp_t_connec c WHERE '||(v_field)||'::integer > 0 GROUP BY '||(v_field)||')c USING ('||(v_field)||')
					JOIN '||(v_table)||' p ON e.'||(v_field)||' = p.'||(v_field)||'
					WHERE p.'||(v_field)||'::text = '||quote_literal(v_floodonlymapzone)||'::text';
				END IF;
				EXECUTE v_querytext;
			END IF;
		END IF;

		IF v_floodonlymapzone IS NULL THEN

			RAISE NOTICE 'Disconnected arcs';
			select count(*) INTO v_count FROM
			(SELECT DISTINCT arc_id FROM temp_t_arc JOIN temp_t_anlgraph USING (arc_id) WHERE water = 0 group by (arc_id) having count(arc_id)=2)a;
			IF v_count > 0 THEN
				INSERT INTO temp_audit_check_data (fid, criticity, error_message)
				VALUES (v_fid, 2, concat('WARNING-',v_fid,': ', v_count ,' arc''s have been disconnected'));
			ELSE
				INSERT INTO temp_audit_check_data (fid, criticity, error_message)
				VALUES (v_fid, 1, concat('INFO: 0 arc''s have been disconnected'));
			END IF;

			RAISE NOTICE 'Disconnected connecs';
			IF v_count > 0 THEN
				select count(*) INTO v_count FROM
				(SELECT DISTINCT connec_id FROM temp_t_connec JOIN temp_t_anlgraph USING (arc_id) WHERE water = 0 group by (arc_id, connec_id) having count(arc_id)=2 )a;
				IF v_count > 0 THEN
					INSERT INTO temp_audit_check_data (fid, criticity, error_message)
					VALUES (v_fid, 2, concat('WARNING-',v_fid,': ', v_count ,' connec''s have been disconnected'));
				ELSE
					INSERT INTO temp_audit_check_data (fid, criticity, error_message)
					VALUES (v_fid, 1, concat('INFO: 0 connec''s have been disconnected'));
				END IF;
			ELSE
				INSERT INTO temp_audit_check_data (fid, criticity, error_message)
				VALUES (v_fid, 1, concat('INFO: 0 connec''s have been disconnected'));
			END IF;

			IF v_project_type='UD' THEN

				RAISE NOTICE 'Disconnected gullies';

				IF v_count > 0 THEN
					select count(*) INTO v_count FROM
					(SELECT DISTINCT gully_id FROM temp_t_gully JOIN temp_t_arc USING (arc_id) WHERE water = 0 group by (arc_id, gully_id) having count(arc_id)=2 )a;
					IF v_count > 0 THEN
						INSERT INTO temp_audit_check_data (fid, criticity, error_message)
						VALUES (v_fid, 2, concat('WARNING-',v_fid,': ', v_count ,' gullies have been disconnected'));
					ELSE
						INSERT INTO temp_audit_check_data (fid, criticity, error_message)
						VALUES (v_fid, 1, concat('INFO: 0 gullies have been disconnected'));
					END IF;
				ELSE
					INSERT INTO temp_audit_check_data (fid, criticity, error_message)
					VALUES (v_fid, 1, concat('INFO: 0 gullies have been disconnected'));
				END IF;
			END IF;
		END IF;

		--update of fields 'updated_at' and 'updated_by'
		v_querytext = 'UPDATE temp_'||quote_ident(v_table)||' set updated_at=now(), updated_by=current_user 
		where '||quote_ident(v_field)||' IN (SELECT distinct '||quote_ident(v_field)||' FROM temp_t_arc JOIN temp_t_anlgraph USING (arc_id))';
		EXECUTE v_querytext;

		-- insert spacer for warning and info
		INSERT INTO temp_audit_check_data (fid,  criticity, error_message) VALUES (v_fid,  3, '');
		INSERT INTO temp_audit_check_data (fid,  criticity, error_message) VALUES (v_fid,  2, '');
		INSERT INTO temp_audit_check_data (fid,  criticity, error_message) VALUES (v_fid,  1, '');
		INSERT INTO temp_audit_check_data (fid,  criticity, error_message) VALUES (v_fid,  0, '');
	END IF;

	RAISE NOTICE 'Creating geometry of mapzones';

	-- update geometry of mapzones
	IF v_updatemapzgeom = 0 THEN
		-- do nothing

	ELSIF  v_updatemapzgeom = 1 THEN

		-- concave polygon
		v_querytext = '	UPDATE temp_'||(v_table)||' set the_geom = st_multi(a.the_geom) 
			FROM (with polygon AS (SELECT st_collect (the_geom) as g, '||quote_ident(v_field)||' FROM temp_t_arc a  
			JOIN temp_t_anlgraph USING (arc_id) 
			WHERE state > 0  AND water = 1 and expl_id IN('||v_expl_id||')   group by '||quote_ident(v_field)||') 
			SELECT '||quote_ident(v_field)||
			', CASE WHEN st_geometrytype(st_concavehull(g, '||v_concavehull||')) = ''ST_Polygon''::text THEN st_buffer(st_concavehull(g, '||
			v_concavehull||'), 2)::geometry(Polygon,'||(v_srid)||')
			ELSE st_expand(st_buffer(g, 3::double precision), 1::double precision)::geometry(Polygon,'||(v_srid)||') END AS the_geom FROM polygon
			)a WHERE a.'||quote_ident(v_field)||'= temp_'||(v_table)||'.'||quote_ident(v_fieldmp)||' AND temp_'||(v_table)||'.'||
			quote_ident(v_fieldmp)||' NOT IN (''0'', ''-1'')';

		EXECUTE v_querytext;

	ELSIF  v_updatemapzgeom = 2 THEN

		-- pipe buffer
		v_querytext = '	UPDATE temp_'||(v_table)||' set the_geom = geom FROM
			(SELECT '||quote_ident(v_field)||', st_multi(st_buffer(st_collect(the_geom),'||v_geomparamupdate||')) as geom from temp_t_arc a 
			JOIN temp_t_anlgraph USING (arc_id) 
			where a.state > 0 AND water = 1 AND '||quote_ident(v_field)||'::integer > 0 and expl_id IN('||v_expl_id||')  group by '||quote_ident(v_field)||')a 
			WHERE a.'||quote_ident(v_field)||'= temp_'||(v_table)||'.'||quote_ident(v_fieldmp);

			/*
			UPDATE drainzone set the_geom = geom FROM (
				SELECT drainzone_id, st_multi(st_buffer(st_collect(the_geom),10)) as geom from arc
				 where arc.state = 1 AND drainzone_id::integer > 0 GROUP BY drainzone_id
			)a WHERE a.drainzone_id=drainzone.drainzone_id;
			*/

		EXECUTE v_querytext;

	ELSIF  v_updatemapzgeom = 3 THEN

		-- use plot and pipe buffer
		v_querytext = '	UPDATE temp_'||(v_table)||' set the_geom = geom FROM
			(SELECT '||quote_ident(v_field)||', st_multi(st_buffer(st_collect(geom),0.01)) as geom FROM
			(SELECT '||quote_ident(v_field)||', st_buffer(st_collect(the_geom), '||v_geomparamupdate||') as geom from temp_t_arc a
			JOIN temp_t_anlgraph USING (arc_id) 
			where a.state > 0 AND water = 1 AND  '||quote_ident(v_field)||'::integer > 0 and expl_id IN('||v_expl_id||') group by '||quote_ident(v_field)||'
			UNION
			SELECT '||quote_ident(v_field)||', st_collect(ext_plot.the_geom) as geom FROM  ext_plot, temp_t_connec a
			JOIN temp_t_anlgraph USING (arc_id) 
			WHERE a.state > 0 and a.expl_id IN('||v_expl_id||')
			AND '||quote_ident(v_field)||'::integer > 0  AND water = 1
			AND st_dwithin(a.the_geom, ext_plot.the_geom, 0.001)
			group by '||quote_ident(v_field)||'	
			)a group by '||quote_ident(v_field)||')b 
			WHERE b.'||quote_ident(v_field)||'= temp_'||(v_table)||'.'||quote_ident(v_fieldmp);

			/*
			UPDATE dma set the_geom = geom FROM(
			SELECT dma_id, st_multi(st_buffer(st_collect(geom),0.01)) as geom FROM
			(SELECT dma_id, st_buffer(st_collect(the_geom), 10) as geom from ve_arc
			JOIN temp_t_anlgraph USING (arc_id)
			where dma_id::integer > 0 group by dma_id
			UNION
			SELECT dma_id, st_collect(ext_plot.the_geom) as geom FROM ve_connec, ext_plot
			WHERE dma_id::integer > 0
			AND ve_connec.dma_id IN
			(SELECT DISTINCT dma_id FROM ve_arc JOIN anl_arc USING (arc_id) WHERE fid = 145 and cur_user = current_user)
			AND st_dwithin(ve_connec.the_geom, ext_plot.the_geom, 0.001)
			group by dma_id
			)a group by dma_id
			)b WHERE b.dma_id=dma.dma_id;
			*/

		EXECUTE v_querytext;

	ELSIF  v_updatemapzgeom = 4 THEN

		v_geomparamupdate_divide = v_geomparamupdate/2;

		-- use link and pipe buffer
		v_querytext = '	UPDATE temp_'||(v_table)||' set the_geom = geom FROM
			(SELECT '||quote_ident(v_field)||', st_multi(st_buffer(st_collect(geom),0.01)) as geom FROM
			(SELECT '||quote_ident(v_field)||', st_buffer(st_collect(the_geom), '||v_geomparamupdate||') as geom from temp_t_arc a JOIN temp_t_anlgraph USING (arc_id) 
			where a.state > 0  AND water = 1 AND a.'||quote_ident(v_field)||'::integer > 0 and a.expl_id IN('||v_expl_id||') group by '||quote_ident(v_field)||'
			UNION
			SELECT a.'||quote_ident(v_field)||', (st_buffer(st_collect(temp_t_link.the_geom),'||v_geomparamupdate_divide||',''endcap=flat join=round'')) 
			as geom FROM temp_t_link, temp_t_connec a
			JOIN temp_t_anlgraph USING (arc_id) 
			WHERE a.'||quote_ident(v_field)||'::integer > 0  AND water = 1
			AND a.state > 0 AND temp_t_link.feature_id = connec_id and temp_t_link.feature_type = ''CONNEC'' and a.expl_id IN('||v_expl_id||')
			group by a.'||quote_ident(v_field)||'
			UNION
			SELECT a.'||quote_ident(v_field)||', (st_buffer(st_collect(temp_t_link.the_geom),'||v_geomparamupdate_divide||',''endcap=flat join=round'')) 
			as geom FROM temp_t_link, temp_t_connec a
			JOIN temp_t_node n ON a.arc_id IS NULL AND n.node_id=a.pjoint_id
			WHERE a.'||quote_ident(v_field)||'::integer > 0
			AND a.state > 0 AND temp_t_link.feature_id = connec_id and temp_t_link.feature_type = ''CONNEC'' and a.expl_id IN('||v_expl_id||')
			group by a.'||quote_ident(v_field)||'
			)c group by '||quote_ident(v_field)||')b
			WHERE b.'||quote_ident(v_field)||'= temp_'||(v_table)||'.'||quote_ident(v_fieldmp);

			/*
			UPDATE dma set the_geom = geom FROM
			(
			SELECT dma_id, st_multi(st_buffer(st_collect(geom),0.01)) as geom FROM
			(SELECT dma_id, st_buffer(st_collect(the_geom), 5) as geom from temp_t_arc
			where dma_id::integer > 0  group by dma_id
			UNION
			SELECT c.dma_id, (st_buffer(st_collect(link.the_geom),5/2, ,'endcap=flat join=round'))
			as geom FROM ve_link link, connec c
			WHERE c.dma_id:::integer > 0
			AND link.feature_id = connec_id and link.feature_type = 'CONNEC'
			group by c.dma_id
			)a group by dma_id
			)b
			WHERE b.dma_id=dma.dma_id
			*/

		EXECUTE v_querytext;

	ELSIF v_updatemapzgeom = 5 THEN

		v_geomparamupdate_divide = v_geomparamupdate/2;

		/* example of querytext that could be implemented on config_param_system
		UPDATE v_table set the_geom = geom FROM
		(SELECT v_field, st_multi(st_buffer(st_collect(geom),0.01)) as geom FROM
		(SELECT v_field, st_buffer(st_collect(the_geom), v_geomparamupdate) as geom
		FROM ve_arc arc
		JOIN temp_t_anlgraph USING (arc_id)
		where arc.state = 1 AND water = 1 AND v_field::INTEGER> 0 group by v_field
		UNION
		SELECT v_field, st_collect(z.geom) as geom FROM v_crm_zone z
		join ve_node using (node_id)
		JOIN temp_t_anlgraph ON  node_id = node_1
		WHERE ve_node.state = 1 AND water = 1 AND v_field::INTEGER> 0
		group by v_field
		)a group by v_field)b
		WHERE b.v_field=v_table.v_fieldmp
		*/

		SELECT value into v_querytext FROM config_param_system WHERE parameter='utils_graphanalytics_custom_geometry_constructor';
		EXECUTE 'SELECT replace(replace(replace(replace(replace('||quote_literal(v_querytext)||',''v_table'', '||quote_literal(v_table)||'),
		''v_fieldmp'', '||quote_literal(v_fieldmp)||'), ''v_field'', '||quote_literal(v_field)||'), ''v_fid'', '||quote_literal(v_fid)||'),
		 ''v_geomparamupdate'', '||quote_literal(v_geomparamupdate)||')'
		INTO v_querytext;

		EXECUTE v_querytext;

	ELSIF v_updatemapzgeom = 6 THEN --EPA SUBCATCH

	END IF;


	RAISE NOTICE 'Getting results';

	-- info
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
	FROM (SELECT id, error_message as message FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid IN (v_fid) order by criticity desc, id asc) row;
	v_result := COALESCE(v_result, '{}');
	v_result_info = concat ('{"values":',v_result, '}');

	IF v_floodonlymapzone IS NULL THEN

		v_result = null;
		IF v_commitchanges IS TRUE THEN
		-- disconnected arcs
		SELECT jsonb_build_object(
		    'type', 'FeatureCollection',
		    'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
		) INTO v_result
		FROM (
		SELECT jsonb_build_object(
		     'type',       'Feature',
		    'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
		    'properties', to_jsonb(row) - 'the_geom'
		) AS feature
		FROM
		(SELECT DISTINCT ON (arc_id) arc_id, arccat_id, state, expl_id, 'Disconnected'::text as descript, ST_Transform(the_geom, 4326) as the_geom FROM temp_t_arc JOIN temp_t_anlgraph USING (arc_id) WHERE water = 0
		group by (arc_id, arccat_id, state, expl_id, the_geom) having count(arc_id)=2
		UNION
		SELECT DISTINCT ON (arc_id) arc_id, arccat_id, state, expl_id, 'Conflict'::text as descript, ST_Transform(the_geom, 4326) as the_geom FROM temp_t_arc JOIN temp_t_anlgraph USING (arc_id) WHERE water = -1
		group by (arc_id, arccat_id, state, expl_id, the_geom) having count(arc_id)=2
		) row) features;

		-- Execute the query and check if it returns any rows
		SELECT EXISTS (
			SELECT 1
			FROM (
				SELECT DISTINCT ON (arc_id) arc_id, arccat_id, state, expl_id, 'Conflict'::text as descript, the_geom
				FROM temp_t_arc
				JOIN temp_t_anlgraph USING (arc_id)
				WHERE water = -1
				GROUP BY (arc_id, arccat_id, state, expl_id, the_geom)
				HAVING COUNT(arc_id) = 2
			) sub_query
		) INTO v_has_conflicts;

		v_result_line = v_result;
		END IF;

	-- disconnected connecs
	v_result = null;

	SELECT jsonb_build_object(
	    'type', 'FeatureCollection',
	    'features', COALESCE(jsonb_agg(features.feature), '[]'::jsonb)
	) INTO v_result
	FROM (
	SELECT jsonb_build_object(
	     'type',       'Feature',
	    'geometry',   ST_AsGeoJSON(the_geom)::jsonb,
	    'properties', to_jsonb(row) - 'the_geom'
	) AS feature
	FROM (SELECT DISTINCT ON (connec_id) connec_id, conneccat_id, c.state, c.expl_id, 'Disconnected'::text as descript, ST_Transform(c.the_geom, 4326) as the_geom FROM temp_t_connec c JOIN temp_t_anlgraph USING (arc_id) WHERE water = 0
	group by (arc_id, connec_id, conneccat_id, state, expl_id, the_geom) having count(arc_id)=2
	UNION
	SELECT DISTINCT ON (connec_id) connec_id, conneccat_id, state, expl_id, 'Conflict'::text as descript, ST_Transform(the_geom, 4326) as the_geom FROM temp_t_connec c JOIN temp_t_anlgraph USING (arc_id) WHERE water = -1
	group by (arc_id, connec_id, conneccat_id, state, expl_id, the_geom) having count(arc_id)=2
	UNION
	(SELECT DISTINCT ON (connec_id) connec_id, conneccat_id, state, expl_id, 'Orphan'::text as descript, ST_Transform(the_geom, 4326) as the_geom FROM temp_t_connec c WHERE arc_id IS NULL
	EXCEPT
	SELECT DISTINCT ON (connec_id) connec_id, conneccat_id, c.state, c.expl_id, 'Orphan'::text as descript, ST_Transform(c.the_geom, 4326) as the_geom FROM temp_t_connec c
	JOIN temp_t_node a ON a.node_id=c.pjoint_id
	WHERE c.pjoint_type = 'NODE')
	) row) features;

	v_result_point = v_result;
	END IF;

	IF v_audit_result is null THEN
		v_status = 'Accepted';
		v_level = 3;
		v_message = 'Mapzones dynamic analysis done succesfull';
	ELSE
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'status')::text INTO v_status;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'level')::integer INTO v_level;
		SELECT ((((v_audit_result::json ->> 'body')::json ->> 'data')::json ->> 'info')::json ->> 'message')::text INTO v_message;
	END IF;

	-- value4disconnected
	IF v_valuefordisconnected IS NOT NULL OR v_valuefordisconnected <> 0 THEN
		EXECUTE 'UPDATE temp_t_arc t SET '||v_field||' = '||v_valuefordisconnected||' WHERE t.'||v_field||'::text IN (''0'',''-1'')';
		EXECUTE 'UPDATE temp_t_node t SET '||v_field||' = '||v_valuefordisconnected||' WHERE t.'||v_field||'::text  IN (''0'',''-1'')';
		EXECUTE 'UPDATE temp_t_connec t SET '||v_field||'  = '||v_valuefordisconnected||' WHERE t.'||v_field||'::text  IN (''0'',''-1'')';
	END IF;

	------ end of multi-transactional event
	IF v_commitchanges IS FALSE THEN  -- all features in order to make a more complex log

		-- arc elements
		IF v_floodonlymapzone IS NULL THEN
			EXECUTE 'SELECT jsonb_build_object(
			        ''type'', ''FeatureCollection'',
			        ''features'', COALESCE(jsonb_agg(features.feature), ''[]''::jsonb)
			    )
			FROM (
			SELECT jsonb_build_object(
			    ''type'',       ''Feature'',
			    ''geometry'',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
			    ''properties'', to_jsonb(row) - ''the_geom''
			) AS feature
			FROM 
			(SELECT * FROM 
			(SELECT DISTINCT ON (arc_id) arc_id, arccat_id, state, expl_id, ''0'' as mapzone_id, the_geom, ''Disconnected''::text as descript  FROM temp_t_arc JOIN temp_t_anlgraph USING (arc_id) WHERE water = 0 
			group by (arc_id, arccat_id, state, expl_id, the_geom) having count(arc_id)=2
			UNION
			SELECT DISTINCT ON (arc_id) arc_id, arccat_id, state, expl_id, NULL as mapzone_id, the_geom, ''Conflict''::text as descript FROM temp_t_arc JOIN temp_t_anlgraph USING (arc_id) WHERE water = -1 
			group by (arc_id, arccat_id, state, expl_id, the_geom) having count(arc_id)=2
			) a 
			UNION
			SELECT DISTINCT ON (arc_id) arc_id, arccat_id, t.state, t.expl_id, t.'||v_field||'::TEXT as mapzone_id, t.the_geom, m.name as descript FROM temp_t_arc t 
			JOIN '||v_table||' m USING ('||v_field||') WHERE '||v_field||'::integer >0
			) row ) features'
			INTO v_result;
		ELSE
			EXECUTE 'SELECT jsonb_build_object(
			        ''type'', ''FeatureCollection'',
			        ''features'', COALESCE(jsonb_agg(features.feature), ''[]''::jsonb)
			    )
			FROM (
			SELECT jsonb_build_object(
			    ''type'',       ''Feature'',
			    ''geometry'',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
			    ''properties'', to_jsonb(row) - ''the_geom''
			) AS feature
			FROM 
			(SELECT * FROM 
			(SELECT DISTINCT ON (arc_id) arc_id, arccat_id, t.state, t.expl_id, t.'||v_field||'::TEXT as mapzone_id, t.the_geom, m.name as descript FROM temp_t_arc t 
			JOIN '||v_table||' m USING ('||v_field||') WHERE '||v_field||'::integer IN ('||v_floodonlymapzone||')
			)a) row ) features'
			INTO v_result;
		END IF;


		v_result_line = v_result;

		v_result = null;

	-- polygons
	EXECUTE 'SELECT jsonb_build_object(
	        ''type'', ''FeatureCollection'',
	        ''features'', COALESCE(jsonb_agg(features.feature), ''[]''::jsonb)
	    )
	FROM (
  	SELECT jsonb_build_object(
    ''type'',       ''Feature'',
    ''geometry'',   ST_AsGeoJSON(ST_Transform(the_geom, 4326))::jsonb,
    ''properties'', to_jsonb(row) - ''the_geom''
  	) AS feature
  	FROM (SELECT  t.'||v_field||' as mapzone_id, m.name  as descript, '||v_fid||' as fid, t.expl_id, t.the_geom FROM temp_'||v_table||' t JOIN '||v_table||' m USING ('||v_field||')) row) features'
	INTO v_result;

	v_result_polygon = v_result;

		-- moving to anl tables
		DELETE FROM anl_arc WHERE fid=v_fid AND cur_user=current_user;
		EXECUTE 'INSERT INTO anl_arc (arc_id, expl_id, fid, cur_user, the_geom, '||v_field||') SELECT arc_id, expl_id, '||v_fid||', current_user, the_geom, '||v_field||' FROM temp_t_arc';

		v_visible_layer = NULL;
	ELSIF v_commitchanges IS TRUE and v_netscenario is null THEN

		-- setting variables in order to enhace performance
		UPDATE config_param_user SET value = 'TRUE' WHERE parameter = 'edit_disable_typevalue_fk' AND cur_user = current_user;
		UPDATE config_param_user SET value = 'TRUE' WHERE parameter = 'edit_node2arc_update_disable' AND cur_user = current_user;
		UPDATE config_param_system SET value = 'TRUE' WHERE parameter = 'admin_skip_audit';

		-- specific values for different graphclass
		IF v_class = 'DMA' THEN

			RAISE NOTICE 'Filling om_waterbalance_dma_graph ';

			v_querytext = 'INSERT INTO temp_om_waterbalance_dma_graph (node_id, '||quote_ident(v_field)||', flow_sign)
			(SELECT DISTINCT n.node_id, a.'||quote_ident(v_field)||',
			CASE 
			WHEN n.'||quote_ident(v_field)||' =a.'||quote_ident(v_field)||' then 1
			ELSE -1
			END AS flow_sign
			FROM temp_t_node n
			JOIN value_state_type sn ON sn.state =n.state AND sn.id=n.state_type
			JOIN temp_t_arc a  ON a.node_1 =n.node_id or a.node_2 =n.node_id 
			JOIN value_state_type sa ON sa.state =a.state AND sa.id=a.state_type
			WHERE sn.is_operative =true AND sa.is_operative =true AND 
			n.node_id IN
			(SELECT (json_array_elements(graphconfig->''use'')->>''nodeParent'')::integer as nodeparent
			FROM '||quote_ident(v_table)||' WHERE active=true)
			AND a.'||quote_ident(v_field)||' IN
			(SELECT '||quote_ident(v_field)||'
			FROM '||quote_ident(v_table)||' WHERE active=true
			)
			) ON CONFLICT (node_id, dma_id) DO NOTHING';
			EXECUTE v_querytext;

			delete from om_waterbalance_dma_graph where dma_id in (select distinct dma_id from temp_om_waterbalance_dma_graph);
			INSERT INTO om_waterbalance_dma_graph SELECT * FROM temp_om_waterbalance_dma_graph ON CONFLICT (dma_id, node_id) DO NOTHING;

		ELSIF v_class = 'SECTOR' THEN

		END IF;

		-- mapzone
		IF v_floodonlymapzone IS NULL THEN
			v_querytext = 'UPDATE '||v_table||' SET the_geom = t.the_geom, updated_at = now(), updated_by = current_user FROM temp_'||v_table||' t WHERE t.'||v_field||' = '||v_table||'.'||v_field;
		ELSE
			v_querytext = 'UPDATE '||v_table||' m SET the_geom = t.the_geom, updated_at = now(), updated_by = current_user FROM temp_'||v_table||' t WHERE t.'||v_field||' = m.'||v_field||' AND m.'||quote_ident(v_field)||'::integer IN ('||v_floodonlymapzone||')';
		END IF;

		EXECUTE v_querytext;

		-- arcs
		v_querytext = 'UPDATE arc SET '||quote_ident(v_field)||' = a.'||quote_ident(v_field)||', updated_by = a.updated_by, updated_at = a.updated_at 
		FROM temp_t_arc a WHERE a.arc_id=arc.arc_id';
		EXECUTE v_querytext;

		-- node
		v_querytext = 'UPDATE node SET '||quote_ident(v_field)||' = n.'||quote_ident(v_field)||', updated_by = n.updated_by, updated_at = n.updated_at 
		FROM temp_t_node n WHERE n.node_id=node.node_id';
		EXECUTE v_querytext;
		IF v_class = 'PRESSZONE' THEN
			UPDATE node SET staticpressure = n.staticpressure FROM temp_t_node n WHERE n.node_id=node.node_id;
		END IF;

		-- connec state = 1
		v_querytext = 'UPDATE connec SET '||quote_ident(v_field)||' = c.'||quote_ident(v_field)||', updated_by = c.updated_by, updated_at = c.updated_at 
		FROM temp_t_connec c WHERE c.connec_id=connec.connec_id';
		EXECUTE v_querytext;
		IF v_class = 'PRESSZONE' THEN
			UPDATE connec SET staticpressure = c.staticpressure FROM temp_t_connec c WHERE c.connec_id=connec.connec_id;
		END IF;

		--link
		IF v_class = 'PRESSZONE' THEN
			UPDATE link SET staticpressure1 = l.staticpressure1 FROM temp_t_link l WHERE l.link_id=link.link_id;
		END IF;

		v_querytext = 'UPDATE link SET '||quote_ident(v_field)||' = l.'||quote_ident(v_field)||', updated_by = l.updated_by, updated_at = l.updated_at 
		FROM temp_t_link l WHERE link.link_id = l.link_id';
		EXECUTE v_querytext;

		IF v_project_type = 'UD' THEN

			-- gully
			v_querytext = 'UPDATE gully SET '||quote_ident(v_field)||' = g.'||quote_ident(v_field)||', updated_by = g.updated_by, updated_at = g.updated_at 
			FROM temp_t_gully g WHERE g.gully_id=gully.gully_id';
			EXECUTE v_querytext;
		END IF;

		-- restore values for temporal variables
		UPDATE config_param_user SET value = 'FALSE' WHERE parameter = 'edit_disable_typevalue_fk' AND cur_user = current_user;
		UPDATE config_param_user SET value = 'FALSE' WHERE parameter = 'edit_node2arc_update_disable' AND cur_user = current_user;
		UPDATE config_param_system SET value = 'FALSE' WHERE parameter = 'admin_skip_audit';

	ELSIF v_netscenario IS NOT NULL THEN

		v_querytext = 'UPDATE plan_netscenario_'||v_table||' SET the_geom = t.the_geom, updated_at = now(), updated_by=current_user FROM temp_'||v_table||
		' t WHERE t.'||v_field||' = plan_netscenario_'||v_table||'.'||v_field||' 
		AND plan_netscenario_'||v_table||'.netscenario_id = '||v_netscenario||'';
		EXECUTE v_querytext;

		DELETE FROM plan_netscenario_arc WHERE netscenario_id = v_netscenario::integer;
		DELETE FROM plan_netscenario_node WHERE netscenario_id = v_netscenario::integer;
		DELETE FROM plan_netscenario_connec WHERE netscenario_id = v_netscenario::integer;

		EXECUTE 'INSERT INTO plan_netscenario_arc(netscenario_id, arc_id, '||quote_ident(v_field)||', the_geom)
		SELECT '|| v_netscenario||', arc_id, '||quote_ident(v_field)||', a.the_geom FROM temp_t_arc a
		JOIN plan_netscenario_'||v_table||' USING ('||quote_ident(v_field)||') WHERE netscenario_id =  '|| v_netscenario||'';

		EXECUTE 'INSERT INTO plan_netscenario_node(netscenario_id, node_id, '||quote_ident(v_field)||', the_geom)
		SELECT '|| v_netscenario||', node_id, '||quote_ident(v_field)||', n.the_geom FROM temp_t_node n
		JOIN plan_netscenario_'||v_table||' USING ('||quote_ident(v_field)||') WHERE netscenario_id =  '|| v_netscenario||'';

		EXECUTE 'INSERT INTO plan_netscenario_connec(netscenario_id, connec_id, '||quote_ident(v_field)||', the_geom)
		SELECT '|| v_netscenario||', connec_id, '||quote_ident(v_field)||', c.the_geom FROM temp_t_connec c
		JOIN plan_netscenario_'||v_table||' USING ('||quote_ident(v_field)||') WHERE netscenario_id =  '|| v_netscenario||'';


		IF v_class = 'PRESSZONE' THEN
			v_visible_layer ='"ve_plan_netscenario_presszone"';
			UPDATE plan_netscenario_node SET staticpressure = t.staticpressure FROM temp_t_node t WHERE plan_netscenario_node.node_id=t.node_id;
			UPDATE plan_netscenario_connec SET staticpressure = t.staticpressure FROM temp_t_connec t WHERE plan_netscenario_connec.connec_id=t.connec_id;
		ELSIF v_class = 'DMA' THEN
			v_visible_layer ='"ve_plan_netscenario_dma"';
			UPDATE plan_netscenario_node SET pattern_id = t.pattern_id FROM temp_dma t WHERE plan_netscenario_node.dma_id=t.dma_id;
			UPDATE plan_netscenario_connec SET pattern_id = t.pattern_id FROM temp_dma t WHERE plan_netscenario_connec.dma_id=t.dma_id;
		END IF;

		DELETE FROM selector_inp_dscenario WHERE cur_user = current_user;

		IF v_dscenario_valve IS NOT NULL THEN
			v_visible_layer = concat(v_visible_layer, ', ', '"ve_inp_dscenario_shortpipe"');

			INSERT INTO selector_inp_dscenario (dscenario_id) VALUES (v_dscenario_valve::integer);
		END IF;

		UPDATE config_param_user SET value = v_netscenario::text WHERE parameter = 'plan_netscenario_current' AND cur_user = current_user;

	END IF;

	IF v_class = 'DMA' THEN -- Execute DMA graph
	
		FOR rec IN SELECT DISTINCT expl_id FROM temp_t_node
		LOOP
			
			EXECUTE 'SELECT gw_fct_getdmagraph($${"client":{"device":4, "infoType":1, "lang":"ES"},
			"feature":{},"data":{"parameters":{"explId":"'||rec.expl_id||'", "searchDistRouting":999}}}$$)';
			
		END LOOP;
	
	END IF;

	-- Control nulls
	v_result_info := COALESCE(v_result_info, '{}');
	v_result_point := COALESCE(v_result_point, '{}');
	v_result_line := COALESCE(v_result_line, '{}');
	v_result_polygon := COALESCE(v_result_polygon, '{}');
	v_level := COALESCE(v_level, 0);
	v_message := COALESCE(v_message, '');
	v_version := COALESCE(v_version, '');
	v_netscenario := COALESCE(v_netscenario, '');

	-- moving data on temp_anlgraph to be used for replay of the movie
	DELETE FROM temp_anlgraph;
	INSERT INTO temp_anlgraph SELECT * FROM temp_t_anlgraph;

	-- drop temporal tables
	DROP VIEW IF EXISTS v_temp_anlgraph;
	DROP TABLE IF EXISTS temp_t_anlgraph;
	DROP TABLE IF EXISTS temp_t_data;
	DROP TABLE IF EXISTS temp_audit_check_data;
	DROP TABLE IF EXISTS temp_anl_arc;
	DROP TABLE IF EXISTS temp_anl_node;
	DROP TABLE IF EXISTS temp_anl_connec;
	DROP TABLE IF EXISTS temp_t_arc;
	DROP TABLE IF EXISTS temp_t_node;
	DROP TABLE IF EXISTS temp_t_connec;
	DROP TABLE IF EXISTS temp_t_link;

	IF v_project_type = 'UD' THEN
		DROP TABLE IF EXISTS temp_t_gully;
		DROP TABLE IF EXISTS temp_drainzone;
	ELSE
		DROP TABLE IF EXISTS temp_om_waterbalance_dma_graph;
		DROP TABLE IF EXISTS temp_sector;
		DROP TABLE IF EXISTS temp_presszone;
		DROP TABLE IF EXISTS temp_dma;
		DROP TABLE IF EXISTS temp_dqa;
	END IF;

	-- Restore original disable lock level
    UPDATE config_param_user SET value = v_original_disable_locklevel WHERE parameter = 'edit_disable_locklevel' AND cur_user = current_user;

	--  Return
	RETURN  gw_fct_json_create_return(('{"status":"'||v_status||'", "message":{"level":'||v_level||', "text":"'||v_message||'"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}, "data":{"graphClass": "'||v_class||'", "netscenarioId": "'||v_netscenario||'", "hasConflicts": '||v_has_conflicts||', "info":'||v_result_info||','||
					  '"point":'||v_result_point||','||
					  '"line":'||v_result_line||','||
					  '"polygon":'||v_result_polygon||'}'||'}}')::json, 2710, null, ('{"visible": ['||v_visible_layer||']}')::json, null)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

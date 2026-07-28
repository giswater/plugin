-- DROP FUNCTION gw_fct_cm_build_topology(json);

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_build_topology(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/* EXAMPLE:


-- From Giswater Toolbox
SELECT gw_fct_cm_build_topology($${"client":{"device":4, "lang":"", "version":"4.7.0", "infoType":1, "epsg":8908}, "form":{}, 
"feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"lotId":"25", "updateType":"1"}, "aux_params":null}}$$);


-- From Database using SQL: updateType is ignored and arcId will be taken into account)
SELECT gw_fct_cm_build_topology(concat('{
"client":{"device":4, "lang":"", "version":"4.7.0", "infoType":1, "epsg":8908}, 
"form":{}, 
"feature":{}, 
"data":{"filterFields":{}, "pageInfo":{}, "parameters":{"lotId":"22", "updateType":"1", "arcId":"', arc_id, '"}, "aux_params":null}}')::json) from 
om_campaign_lot_x_arc where lot_id = 25 and arc_id = -146;


*/

DECLARE
	-- Init params
	v_version text;
	v_schemaname text := 'SCHEMA_NAME';
	v_project_type text;

	-- Input params
	v_lot_id integer;
	v_arc_id integer;
	v_campaign_id integer;
	
	v_update_type integer;

	-- vars
	v_sql_arcs text;
	v_sql_nodes text;
	v_filter_arc text;
	rec_table text;
	v_sql_topology text;
	v_node text;
	v_exists bool;
	v_lot_id_array integer[];

	-- Custom for campaign types
	v_prev_search_path text;
	v_forminfo json := '{}'::json;
	v_featureinfo JSON;

	--Return
	v_count integer = 0;

	v_result json;
	v_result_info json;
	v_fid integer = 999;
	v_message json;
	v_return json;

	
BEGIN
	-- Set search path transaction-locally
	--v_prev_search_path := current_setting('search_path');
	--PERFORM set_config('search_path', 'cm, PARENT_SCHEMA, public', true);

	SET search_path = "cm","PARENT_SCHEMA", public; 

	-- Get version
	SELECT giswater, project_type into v_version, v_project_type from cm.sys_version order by id limit 1;


	-- Input params
	v_lot_id := (p_data -> 'data' -> 'parameters' ->> 'lotId')::int;
	v_update_type := (p_data -> 'data' -> 'parameters' ->> 'updateType')::int;
	v_arc_id := (p_data -> 'data' -> 'parameters' ->> 'arcId')::int;
	v_campaign_id := (p_data -> 'data' -> 'parameters' ->> 'campaignId')::int;

	
	-- Choose which arcs are going to be updated
	IF v_lot_id IS NULL THEN
		SELECT array_agg(lot_id) INTO v_lot_id_array FROM cm.om_campaign_lot WHERE status IN (3,4,6) AND campaign_id = v_campaign_id GROUP BY campaign_id;
	ELSE
		v_lot_id_array := array[v_lot_id];
	END IF;

	if v_update_type is not null then

		if v_update_type = 1 then -- all the arcs of the lot
			v_filter_arc = '';

		elsif v_update_type = 2 then -- only the arcs that have node_1 = null or node_2 = null
			v_filter_arc = ' AND (b.node_1 is null or b.node_2 is null)';
		end if;

	else

	end if;

	-- OPTIONAL: execute function by SQL to update the arcs of the resulting query (only possible via SQL, not toolbox)
	if v_arc_id is not null then
		v_filter_arc = ' AND arc_id = '||v_arc_id||'';
	end if;

	-- Available nodes to build topology of arcs
	v_sql_nodes = format('
		select a.node_id, b.the_geom as node_geom 	
		from cm.om_campaign_lot_x_node a 	
		join cm.om_campaign_x_node b using (node_id) 	
		where lot_id in (%s) and b.the_geom is not null', array_to_string(v_lot_id_array, ','));


	-- Arcs that are going to be updated
	v_sql_arcs = format('
	select a.arc_id, b.the_geom as arc_geom 	
			 from cm.om_campaign_lot_x_arc a 	
			 join cm.om_campaign_x_arc b using (arc_id)  	
			 where lot_id in (%s) and b.the_geom is not null %s and st_isvalid(b.the_geom) is true', array_to_string(v_lot_id_array, ','), v_filter_arc);

	-- Query of new topology
	v_sql_topology = '
		select a.arc_id, b.node_id as node_1, c.node_id as node_2
		FROM ('||v_sql_arcs||') a 
		left join ('||v_sql_nodes||') b on st_dwithin (ST_Startpoint(a.arc_geom), b.node_geom, 0.01)
		left join ('||v_sql_nodes||') c on st_dwithin (ST_Endpoint(a.arc_geom), c.node_geom, 0.01)
		';



	-- Know if there is any arc to be updated (for later manage the process)
	execute 'SELECT EXISTS (SELECT 1 FROM ('||v_sql_arcs||'))' into v_exists;



	if v_exists then -- Start process
			
		
		FOREACH rec_table IN ARRAY ARRAY['cm.om_campaign_lot_x_arc', 'cm.PARENT_SCHEMA_pipe', 'cm.om_campaign_x_arc']
		LOOP
		
		raise notice '%', rec_table;

		execute '
		update '||rec_table||' t
		set node_1 = a.node_1, node_2 = a.node_2 from ('||v_sql_topology||')a
		where t.arc_id = a.arc_id';

		end loop;

	end if;


	execute 'select count(*) from ('||v_sql_arcs||')' into v_count;

	-- get diagnostics and return
	CREATE TEMP TABLE IF NOT EXISTS t_audit_check_data (LIKE audit_check_data INCLUDING ALL);


	-- Total udpated rows
	INSERT INTO t_audit_check_data (fid, result_id, criticity, error_message)
	SELECT v_fid, 999, 0, concat('Se han actualizado ', v_count, ' arcos del lote '||array_to_string(v_lot_id_array, ',')||'');

	-- Build return	
	SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result 
	FROM (SELECT id, error_message as message FROM t_audit_check_data order by criticity desc, id asc) row;

	
	v_result := COALESCE(v_result, '{}'); 
	v_result_info = concat ('{"geometryType":"", "values":',v_result, '}');

	
	select json_build_object('level', log_level, 'text', error_message) into v_message 
	from PARENT_SCHEMA.sys_message where id = 3700;

    DROP TABLE IF EXISTS t_audit_check_data;

	-- control null values
	v_message = coalesce(v_message, '{}');
	v_version = coalesce(v_version, '');
	v_result_info = coalesce(v_result_info, '{}');

    -- Create return
	-- Return
	v_return = ('{"status":"Accepted", "message":'||v_message||', "version":"'||v_version||'",
	"body":{"form":{},"data":{"info":'||v_result_info||'}}}')::json;
	
	
	return v_return;

	

END;
$function$
;

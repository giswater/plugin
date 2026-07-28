/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2244

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_mincut_result_overlap(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_mincut_result_overlap(p_data json)
  RETURNS json AS
$BODY$

/*
SELECT SCHEMA_NAME.gw_fct_mincut_result_overlap($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},"data":{"status":"check", "mincutId":5}}$$)

SELECT SCHEMA_NAME.gw_fct_mincut_result_overlap($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{}, "data":{"status":"continue", "mincutId":333}}$$)

-- fid: 131,216

*/


DECLARE
v_mincutrec record;
v_rec record;
v_conflict_id integer = -2;
v_overlap_macroexpl integer;
v_overlaps boolean = false;
v_overlap_comp boolean;
v_conflictmsg text;
v_count	integer;
v_count2 integer;
v_message text = null;
v_conflictarray integer[];
v_id integer;
v_querytext text;
v_addaffconnecs integer;
v_status text;
v_mincutid integer;
v_result json;
v_result_info json;
v_result_point json;
v_result_line json;
v_result_pol json;
v_error_context text;
v_signal text;
v_geometry text;
v_mincutdetails text;
v_numarcs int4;
v_length  float;
v_volume float;
v_numconnecs int4;
v_numhydrometer int4;
v_priority json;
v_output json;
v_version record;
v_selected text;
v_usepsectors boolean;
v_mincut_version integer;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get input data
	v_status :=  ((p_data ->>'data')::json->>'status')::text;
	v_mincutid :=  ((p_data ->>'data')::json->>'mincutId')::integer;
	v_output := (SELECT output->>'psectors' FROM om_mincut WHERE id = v_mincutid);
	v_usepsectors := (SELECT v_output->>'used');
	v_count := (v_output->>'psectors')::json->>'unselected';
	v_mincut_version := (SELECT value::json->>'version' FROM config_param_system WHERE parameter = 'om_mincut_config');

	SELECT * INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	CREATE TEMP TABLE IF NOT EXISTS temp_audit_check_data (LIKE SCHEMA_NAME.audit_check_data INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_anl_arc (LIKE SCHEMA_NAME.anl_arc INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_anl_connec (LIKE SCHEMA_NAME.anl_connec INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_anl_node (LIKE SCHEMA_NAME.anl_node INCLUDING ALL);
	CREATE TEMP TABLE IF NOT EXISTS temp_anl_polygon (LIKE SCHEMA_NAME.anl_polygon INCLUDING ALL);

	-- Starting process
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4376", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
	EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4378", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';


	IF v_usepsectors THEN

		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4380", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

	ELSE
		IF v_count > 0 THEN
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4382", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "parameters":{"count":"'||v_count||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		ELSE
			EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4384", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		END IF;
	END IF;

	-- log for hydrometer's state
	SELECT count(*) INTO v_count FROM v_cat_hydrometer_state WHERE is_operative IS TRUE;
	SELECT array_agg(a.c) INTO v_selected FROM (SELECT concat(id,'-',name) as c
	FROM v_cat_hydrometer_state WHERE is_operative IS TRUE order by id) a;

	IF v_count = 0 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4386", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
	ELSIF v_count = 1 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4388", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"selected":"'||v_selected||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
	ELSIF v_count > 1 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4390", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"selected":"'||v_selected||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
	END IF;

	SELECT m.*, t.virtual INTO v_mincutrec FROM om_mincut m JOIN om_mincut_cat_type t ON mincut_type = t.id WHERE m.id = v_mincutid;

	IF v_status  = 'check' 	THEN

		IF v_mincutrec.virtual IS FALSE THEN

			-- it's not possible to up this deletion because this values are used in case of step = 'continue'
			DELETE FROM temp_anl_arc WHERE fid=131 and cur_user=current_user;
			DELETE FROM temp_anl_connec WHERE fid=131 and cur_user=current_user;
			DELETE FROM temp_anl_node WHERE fid=131 and cur_user=current_user;

			SELECT count(*) INTO v_count FROM om_mincut_arc WHERE result_id = v_mincutid;

			-- timedate overlap control
			FOR v_rec IN SELECT m.* FROM om_mincut m JOIN om_mincut_cat_type t ON mincut_type = t.id WHERE mincut_class=1 AND mincut_state IN (0,1) AND virtual IS FALSE AND v_count > 0
			AND (forecast_start, forecast_end) OVERLAPS (v_mincutrec.forecast_start, v_mincutrec.forecast_end) AND m.id != v_mincutid
			LOOP
				-- if exist timedate overlap
				IF v_rec.id IS NOT NULL THEN

					-- macroexploitation overlap control
					SELECT macroexpl_id INTO v_overlap_macroexpl FROM exploitation WHERE expl_id=v_rec.expl_id;

					-- if exists macroexpl overlap
					IF v_overlap_macroexpl=v_mincutrec.macroexpl_id THEN

						-- if it's first time - Inserting mincut values for the original one
						IF v_overlaps IS FALSE THEN

							-- create temp result for joined analysis
							INSERT INTO om_mincut (id, work_order, mincut_state, mincut_class, expl_id, macroexpl_id)
							VALUES (-2, 'Conflict Mincut (system)', 2, 1, v_mincutrec.expl_id, v_mincutrec.macroexpl_id)
							ON conflict (id) DO NOTHING;

							-- copying proposed valves and afected arcs from original mincut result to temp result into om_mincut_valve
							INSERT INTO om_mincut_valve (result_id, node_id,  closed,  broken, unaccess, proposed, the_geom)
							SELECT -2, node_id,  true,  broken, unaccess, proposed, the_geom
							FROM om_mincut_valve WHERE result_id= v_mincutid AND proposed=TRUE
							ON conflict (result_id, node_id) DO NOTHING;

							INSERT INTO om_mincut_arc ( result_id, arc_id, the_geom)
							SELECT -2, arc_id, the_geom FROM om_mincut_arc WHERE result_id=v_mincutid
							ON conflict (result_id, arc_id) DO NOTHING;

							--identifing overlap
							v_overlaps:= TRUE;
						END IF;

						-- copying proposed valves and afected arcs from overlaped mincut result
						INSERT INTO om_mincut_valve ( result_id, node_id,  closed,  broken, unaccess, proposed, the_geom)
						SELECT -2, node_id,  true, broken, unaccess, proposed, the_geom
						FROM om_mincut_valve WHERE result_id=v_rec.id AND proposed=TRUE ON conflict (result_id, node_id) DO NOTHING;

						INSERT INTO om_mincut_arc ( result_id, arc_id, the_geom)
						SELECT -2, arc_id, the_geom FROM om_mincut_arc WHERE result_id=v_rec.id ON conflict (result_id, arc_id) DO NOTHING;

						-- count arc_id afected on the overlaped mincut result
						v_count:=v_count+(SELECT count(*) FROM om_mincut_arc WHERE result_id=v_rec.id);

						-- Storing information about possible conflict
						IF v_conflictmsg IS NULL THEN
							v_conflictarray = array_append(v_conflictarray::integer[], v_rec.id::integer);
							v_conflictmsg:=concat('Mincut id-', v_rec.id, ' at ',left(v_rec.forecast_start::time::text, 5),'H-',left(v_rec.forecast_end::time::text, 5),'H with ',
							(v_rec.output->>'connecs')::json->>'number', ' affected connecs.');
						ELSE
							v_conflictarray = array_append(v_conflictarray, v_rec.id);
							v_conflictmsg:=concat(v_conflictmsg,' Mincut id-', v_rec.id, ' at ',left(v_rec.forecast_start::time::text, 5),'H-',left(v_rec.forecast_end::time::text, 5),'H with ',
							(v_rec.output->>'connecs')::json->>'number', ' affected connecs.');
						END IF;
					END IF;
				END IF;
			END LOOP;

			IF v_overlaps THEN

				-- call mincut_flowtrace function
				IF v_mincut_version = 5 THEN
					PERFORM gw_fct_mincut_minsector_inverted (-2, 3);
				ELSE
					PERFORM gw_fct_mincut_inverted_flowtrace (-2);
				END IF;

				v_count2:=(SELECT count(*) FROM om_mincut_arc WHERE result_id=v_conflict_id) ;

				IF v_count < v_count2 THEN -- check for overlaps with additional affectations

					v_signal ='Conflict';

					v_querytext = replace(replace(v_conflictarray::text,'{',''),'}','');

					-- insert conflict mincuts (result_id = all mincuts intersected with current mincut)
					INSERT INTO temp_anl_arc (arc_id, fid, expl_id, cur_user, the_geom, result_id, descript)
					SELECT DISTINCT ON (arc_id) arc_id, 131, expl_id, current_user, a.the_geom, result_id, 'Opposite mincuts'
					FROM om_mincut_arc JOIN arc a USING (arc_id) WHERE result_id = -2;

					-- getting the number of connecs with additional affectation
					SELECT count(*) FROM ve_connec JOIN temp_anl_arc USING (arc_id) WHERE fid = 131 AND result_id::integer = -2::integer INTO v_addaffconnecs;

					IF v_addaffconnecs > 0 THEN -- there is a overlap (temporal & spatial intersection) with additional connecs affected

						v_message = concat ('"level":2, "Text":"Mincut ', v_mincutid,
						' overlaps with other mincuts and has conflicts at least with one. Additional pipes are involved and there are more connecs affected'
						,v_conflictmsg,'"');

					-- info
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4392", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "parameters":{"conflictmsg":"'||v_conflictmsg||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4394", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "parameters":{"addaffconnecs":"'||v_addaffconnecs||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';


					ELSE -- there is a overlap (temporal & spatial intersection) with additional network but without connecs affected

						v_message = concat ('"level":2, "Text":"Mincut ', v_mincutid,
						' overlaps with other mincuts and has conflicts at least with one. Additional pipes are involved but no more connecs affected'
						,v_conflictmsg,'"');

					-- info
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4392", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "parameters":{"conflictmsg":"'||v_conflictmsg||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4396", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4398", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

					END IF;

					-- line: the opposite mincuts
					INSERT INTO temp_anl_arc (fid, arc_id, descript, the_geom)
					SELECT 216, arc_id, concat('Arcs from other mincut(s) with conflict for current mincut ',v_mincutid),
					the_geom FROM om_mincut_arc WHERE result_id = -2
					EXCEPT
					SELECT 216, arc_id, concat('Arcs from other mincut(s) with conflict for current mincut ',v_mincutid),
					the_geom FROM om_mincut_arc WHERE result_id = v_mincutid;

					-- point: connecs affected
					INSERT INTO temp_anl_connec (fid, connec_id, descript, the_geom)
					SELECT 216, connec_id, concat('Additional affected connecs for mincut ',v_mincutid, ' when has conflict against other mincuts'),
					connec.the_geom FROM temp_anl_arc JOIN connec USING (arc_id) WHERE fid = 216;

					-- polygon: buffer over affected pipes
					INSERT INTO anl_polygon (fid, pol_id, descript, the_geom)
					SELECT 216, v_mincutid,  concat('Additional network area affected for current mincut ',v_mincutid,' when when has conflict against other mincuts.'),
					st_multi(st_buffer(st_collect(the_geom),5)) FROM temp_anl_arc WHERE result_id = '-2' AND fid = 131 AND cur_user = current_user;


				ELSE  -- when the number of affected arcs is the same, may exists a real overlap (intersect one against other) without additional network affectations

					FOREACH v_id IN ARRAY v_conflictarray
					LOOP
						-- insert conflict arcs
						v_querytext =  'INSERT INTO temp_anl_arc (arc_id, fid, expl_id, cur_user, the_geom, result_id)
							SELECT DISTINCT ON (arc_id) arc_id, 131, expl_id, current_user, a.the_geom, '||v_id||' 
							FROM om_mincut_arc JOIN arc a USING (arc_id)  WHERE result_id = '||v_mincutid||' AND a.arc_id IN 
							(SELECT arc_id FROM om_mincut_arc WHERE result_id = '||v_id||')';

						EXECUTE v_querytext;
					END LOOP;

					SELECT count(*) INTO v_count FROM temp_anl_arc WHERE fid=131 AND cur_user=current_user;

					IF v_count = 0 THEN  -- There is a temporal overlap without spatial intersection on the same macroexploitation

						v_signal = 'Ok';

					--info
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4400", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"conflictmsg":"'||v_conflictmsg||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4402", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

					ELSE -- There is a temporal overlap with spatial intersection on the same macroexploitation without additional network affected

						v_signal ='Conflict';

						v_message = concat ('"level":2, "Text":"Mincut ', v_mincutid,
						' overlaps with other mincuts and has conflicts at least with one but no additional pipes are involved and no more connecs are affected.'
						,v_conflictmsg,'"');

					--info
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4392", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "parameters":{"conflictmsg":"'||v_conflictmsg||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
					EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4402", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

						-- line: the oposite mincuts
						INSERT INTO temp_anl_arc (fid, arc_id, descript, the_geom)
						SELECT 216, arc_id, descript, the_geom FROM temp_anl_arc WHERE fid = 131 AND cur_user=current_user AND result_id NOT IN (v_mincutid::text, '-2');
					END IF;
				END IF;

				--DELETE FROM om_mincut WHERE id = -2;
				PERFORM setval('SCHEMA_NAME.om_mincut_seq', (select max(id) from om_mincut) , true);

			ELSE -- There is no temporal overlap on same exploitaiton

				v_signal = 'Ok';

				-- info
				EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4404", "prefix_id": "1001", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
			END IF;
		END IF;

		-- mincut details
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2000", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4362", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

		-- Stats
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'arcs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"'||COALESCE((v_mincutrec.output->'arcs'->>'length'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"'||COALESCE((v_mincutrec.output->'arcs'->>'volume'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'connecs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincutrec.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincutrec.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

		-- get results
		-- info
		v_result = null;
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=216 order by id) row;
		v_result := COALESCE(v_result, '{}');
		v_result_info = concat ('{"values":',v_result, '}');

		-- points
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
	FROM (SELECT connec_id, descript, ST_Transform(the_geom, 4326) as the_geom
	FROM  temp_anl_connec WHERE cur_user="current_user"() AND fid=216) row) features;
	v_result_point = v_result;

	-- lines
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
	FROM (SELECT arc_id, descript, ST_Transform(the_geom, 4326) as the_geom
	FROM  temp_anl_arc WHERE cur_user="current_user"() AND fid=216) row) features;
	v_result_line = v_result;

	-- polygon
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
	FROM (SELECT pol_id, descript, ST_Transform(the_geom, 4326) as the_geom
	FROM  temp_anl_polygon WHERE cur_user="current_user"() AND fid=216) row) features;
	v_result_pol = v_result;

		-- geometry (the boundary of mincut using arcs and valves)
		EXECUTE ' SELECT st_astext(st_envelope(st_extent(st_buffer(the_geom,20)))) FROM (SELECT the_geom FROM om_mincut_arc WHERE result_id='||v_mincutid||
		' UNION SELECT the_geom FROM om_mincut_valve WHERE result_id='||v_mincutid||') a'
		INTO v_geometry;

		-- Control nulls
		v_result_info := COALESCE(v_result_info, '{}');
		v_result_point := COALESCE(v_result_point, '{}');
		v_result_line := COALESCE(v_result_line, '{}');
		v_result_pol := COALESCE(v_result_pol, '{}');
		v_geometry := COALESCE(v_geometry, '{}');
		v_message := COALESCE(v_message, '');
		v_signal := COALESCE(v_signal, 'Ok');

		DROP TABLE temp_audit_check_data;
		DROP TABLE temp_anl_arc ;
		DROP TABLE temp_anl_connec;
		DROP TABLE temp_anl_node;
		DROP TABLE temp_anl_polygon;

		--  Return
		RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{'||v_message||'}, "version":"'||v_version.version||'"'||
			',"body":{"form":{}'||
			',"data":{ "info":'||v_result_info||','||
				'"geometry":"'||v_geometry||'",'||
				'"point":'||v_result_point||','||
				'"line":'||v_result_line||','||
				'"polygon":'||v_result_pol||'}'||
			', "overlapStatus":"' || v_signal || '"}}')::json, 2244, null, null, null);

	ELSIF v_status  = 'continue' THEN

		-- update mincut details
		INSERT INTO om_mincut_arc (arc_id, result_id, the_geom)
		SELECT arc_id::int4, v_mincutid, the_geom FROM temp_anl_arc WHERE fid = 131 AND cur_user = current_user AND result_id = '-2'
		ON CONFLICT (arc_id, result_id) DO NOTHING;

		INSERT INTO om_mincut_connec (connec_id, result_id, the_geom)
		SELECT connec_id::int4, v_mincutid, the_geom FROM temp_anl_connec WHERE fid = 131 AND cur_user = current_user AND result_id = '-2'
		ON CONFLICT (connec_id, result_id) DO NOTHING;

		INSERT INTO om_mincut_hydrometer (result_id, hydrometer_id)
		SELECT v_mincutid, erh.hydrometer_id
		FROM v_hydrometer erh
		JOIN ve_connec c ON erh.feature_customer_code=c.customer_code
		JOIN om_mincut_connec omc ON c.connec_id=omc.connec_id
		LEFT JOIN vf_hydrometer ON vf_hydrometer.hydrometer_id=erh.hydrometer_id
		WHERE omc.result_id=v_mincutid AND c.is_operative=TRUE
		ON CONFLICT (hydrometer_id, result_id) DO NOTHING;

		INSERT INTO om_mincut_hydrometer (result_id, hydrometer_id)
		SELECT v_mincutid,erh.hydrometer_id
		FROM v_hydrometer erh
		JOIN man_netwjoin mn ON mn.customer_code = erh.feature_customer_code
		JOIN node n ON n.node_id = mn.node_id
		JOIN om_mincut_node omn ON n.node_id=omn.node_id
		LEFT JOIN vf_hydrometer ON vf_hydrometer.hydrometer_id=erh.hydrometer_id
		WHERE omn.result_id=v_mincutid
		ON CONFLICT (hydrometer_id, result_id) DO NOTHING;

		-- count arcs
		SELECT count(arc_id), sum(st_length(arc.the_geom))::numeric(12,2) INTO v_numarcs, v_length FROM om_mincut_arc JOIN arc USING (arc_id) WHERE result_id=v_mincutid group by result_id;
		SELECT sum(area*st_length(arc.the_geom))::numeric(12,2) INTO v_volume FROM om_mincut_arc JOIN arc USING (arc_id) JOIN cat_arc ON arccat_id=cat_arc.id WHERE result_id=v_mincutid group by result_id, arccat_id;

		-- count connec
		SELECT count(connec_id) INTO v_numconnecs FROM connec JOIN om_mincut_arc ON connec.arc_id=om_mincut_arc.arc_id WHERE result_id=v_mincutid AND state=1;

		-- count hydrometers
		SELECT count (*) INTO v_numhydrometer FROM
		(SELECT omc.connec_id
				FROM vf_hydrometer
				JOIN om_mincut_connec omc ON vf_hydrometer.feature_id=omc.connec_id
				WHERE omc.result_id=v_mincutid
			UNION SELECT omn.node_id
				FROM vf_hydrometer
				JOIN om_mincut_node omn ON vf_hydrometer.feature_id=omn.node_id
				WHERE omn.result_id=v_mincutid)a	;

		-- priority hydrometers
		v_priority = 	(SELECT (array_to_json(array_agg((b)))) FROM (SELECT concat('{"category":"',category_id,'","number":"', count(hydrometer_id), '"}')::json as b FROM
				(SELECT h.hydrometer_id, h.category_id
				FROM vf_hydrometer h
				JOIN om_mincut_connec omc ON h.feature_id=omc.connec_id
				WHERE omc.result_id=v_mincutid
				union
				SELECT h.hydrometer_id, h.category_id
				FROM vf_hydrometer h
				JOIN om_mincut_node omn ON h.feature_id=omn.node_id
				WHERE omn.result_id=v_mincutid)a
				GROUP BY category_id ORDER BY category_id)a)b;


		IF v_priority IS NULL THEN v_priority='{}'; END IF;

		v_mincutdetails = (concat('"arcs":{"number":"',v_numarcs,'", "length":"',v_length,'", "volume":"',
		v_volume, '"}, "connecs":{"number":"',v_numconnecs,'","hydrometers":{"total":"',v_numhydrometer,'","classified":',v_priority,'}}'));

		v_output = concat ('{', v_mincutdetails , '}');

		--update output results and gettin it
		UPDATE om_mincut SET output = v_output WHERE id = v_mincutid;
		SELECT * INTO v_mincutrec FROM om_mincut WHERE id=v_mincutid;

		-- creating log
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4406", "prefix_id": "1002", "function":"2244", "fid":"216", "criticity":"2", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

		-- mincut details
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2000", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4362", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"separator_id": "2030", "function":"2244", "fid":"216", "criticity":"3", "is_process":true, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

		-- Stats
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4364", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'arcs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4366", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"length":"'||COALESCE((v_mincutrec.output->'arcs'->>'length'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4368", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"volume":"'||COALESCE((v_mincutrec.output->'arcs'->>'volume'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4370", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"number":"'||COALESCE((v_mincutrec.output->'connecs'->>'number'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4372", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"total":"'||COALESCE((v_mincutrec.output->'connecs'->'hydrometers'->>'total'), '0')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';
		EXECUTE 'SELECT gw_fct_getmessage($${"data":{"message":"4374", "function":"2244", "fid":"216", "criticity":"1", "is_process":true, "parameters":{"classified":"'||COALESCE(replace((v_mincutrec.output->'connecs'->'hydrometers'->>'classified'), '"', '\"'), '[]')||'"}, "tempTable":"temp_", "cur_user":"current_user"}}$$)';

		-- get results
		-- info
		v_result = null;
		SELECT array_to_json(array_agg(row_to_json(row))) INTO v_result
		FROM (SELECT id, error_message as message FROM temp_audit_check_data WHERE cur_user="current_user"() AND fid=216 order by id) row;
		v_result := COALESCE(v_result, '{}');
		v_result_info = concat ('{"values":',v_result, '}');

		-- geometry (the boundary of mincut using arcs and valves)
		EXECUTE ' SELECT st_astext(st_envelope(st_extent(st_buffer(the_geom,20)))) FROM (SELECT the_geom FROM om_mincut_arc WHERE result_id='||v_mincutid||
		' UNION SELECT the_geom FROM om_mincut_valve WHERE result_id='||v_mincutid||') a'
	        INTO v_geometry;

		DROP TABLE temp_audit_check_data;
		DROP TABLE temp_anl_arc ;
		DROP TABLE temp_anl_connec;
		DROP TABLE temp_anl_node;
		DROP TABLE temp_anl_polygon;

		-- deleting conflict mincut;
		DELETE FROM om_mincut WHERE id = -2;

		-- Control nulls
		v_result_info := COALESCE(v_result_info, '{}');
		v_geometry := COALESCE(v_geometry, '{}');

		-- return
		RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version.version||'"'||
			',"body":{"form":{}'||
			',"data":{ "info":'||v_result_info||','||
				  '"geometry":"'||v_geometry||'"'||
			'}}'||
			'}')::json, 2244,null,null,null);
	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3528

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_get_epa_result_families(v_result_id text)
RETURNS json AS
$BODY$
DECLARE

v_version text;
v_features json;
v_families json;
v_mapzones json;
v_patterns json;


rec TEXT;
sql TEXT;
result jsonb := '{}'::jsonb;
zone_json jsonb;

BEGIN

	SET search_path = "SCHEMA_NAME", public;

	-- SELECT giswater
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Create temp table with features
	CREATE TEMP TABLE temp_features AS
	WITH arc_link_weight AS (
		SELECT
		a.arc_id,
		a.node_1,
		a.node_2,
		ST_Length(a.the_geom) + COALESCE(ls.link_len, 0) AS total_len
		FROM arc a
		LEFT JOIN (
			SELECT l.exit_id, SUM(ST_Length(l.the_geom)) AS link_len
			FROM link l
			WHERE l.state = 1
			GROUP BY l.exit_id
		) ls ON ls.exit_id = a.arc_id
		WHERE a.state = 1
	),
	losses_weight AS (
		SELECT node_id, SUM(arc_len) AS losses_weight
		FROM (
			SELECT node_1::text AS node_id, total_len AS arc_len FROM arc_link_weight
			UNION ALL
			SELECT node_2::text AS node_id, total_len AS arc_len FROM arc_link_weight
		) s
		GROUP BY node_id
	),
	arcs AS (
		SELECT
		arc_id AS feature_id,
		CASE
			WHEN epa_type IN ('VALVE', 'VIRTUALVALVE') THEN 'VALVE'
			WHEN epa_type IN ('PUMP', 'VIRTUALPUMP') THEN 'PUMP'
			ELSE 'PIPE'
		END AS feature_epa_type,
		epa_type AS feature_giswater_epa_type,
		arccat_id AS feature_catalog,
		CASE
			WHEN epa_type IN ('VALVE', 'VIRTUALVALVE') THEN addparam::json->>'valve_type'
			WHEN epa_type IN ('PUMP', 'VIRTUALPUMP') THEN 'PUMP'
			ELSE family
		END AS family,
		builtdate,
		dma_id,
		presszone_id,
		sector_id,
		NULL::numeric AS losses_weight,
		node_1,
		node_2
		FROM rpt_inp_arc
		WHERE result_id = v_result_id
	),
	nodes AS (
		SELECT
		n.node_id AS feature_id,
		CASE
			WHEN n.epa_type IN ('TANK', 'RESERVOIR') THEN n.epa_type
			ELSE 'JUNCTION'
		END AS feature_epa_type,
		n.epa_type AS feature_giswater_epa_type,
		n.nodecat_id AS feature_catalog,
		CASE
			WHEN n.epa_type IN ('TANK', 'RESERVOIR') THEN n.epa_type
			ELSE 'JUNCTION'
		END AS family,
		n.builtdate,
		n.dma_id,
		n.presszone_id,
		n.sector_id,
		lw.losses_weight,
		NULL::text AS node_1,
		NULL::text AS node_2
		FROM rpt_inp_node n
		LEFT JOIN losses_weight lw ON lw.node_id = n.node_id::text
		WHERE n.result_id = v_result_id
	),
	features AS (
		SELECT * FROM arcs
		UNION ALL
		SELECT * FROM nodes
	)
	SELECT
	f.feature_id,
	f.feature_epa_type,
	f.feature_giswater_epa_type,
	f.feature_catalog,
	CASE
		WHEN fam.family_id IS NULL THEN NULL
		WHEN fam.age IS NULL THEN concat(f.family, '_OLD')
		WHEN f.builtdate > CURRENT_DATE - make_interval(years => fam.age) THEN concat(f.family, '_NEW')
		ELSE concat(f.family, '_OLD')
	END AS cal_family,
	f.dma_id,
	f.presszone_id,
	f.sector_id,
	f.losses_weight,
	f.node_1,
	f.node_2
	FROM features f
	LEFT JOIN inp_family fam ON f.family = fam.family_id;

	-- JSON with features: id = first digit run (e.g. 3924522P0 -> 3924522, VN3925355 -> 3925355)
	SELECT COALESCE(json_agg(
		CASE
			WHEN feature_epa_type = 'JUNCTION' THEN
				json_build_object(
					'id', NULLIF(substring(feature_id from '[0-9]+'), '')::bigint,
					'epaId', feature_id,
					'epaType', feature_epa_type,
					'gwEpaType', feature_giswater_epa_type,
					'catalog', feature_catalog,
					'family', cal_family,
					'zones', json_build_object(
						'dma', dma_id,
						'presszone', presszone_id,
						'sector', sector_id
					),
					'lossesWeight', losses_weight
				)
			WHEN feature_epa_type in ('PIPE', 'PUMP', 'VALVE') THEN
				json_build_object(
					'id', NULLIF(substring(feature_id from '[0-9]+'), '')::bigint,
					'epaId', feature_id,
					'epaType', feature_epa_type,
					'gwEpaType', feature_giswater_epa_type,
					'catalog', feature_catalog,
					'family', cal_family,
					'zones', json_build_object(
						'dma', dma_id,
						'presszone', presszone_id,
						'sector', sector_id
					),
					'node1', node_1,
					'node2', node_2
				)
			ELSE
				json_build_object(
					'id', NULLIF(substring(feature_id from '[0-9]+'), '')::bigint,
					'epaId', feature_id,
					'epaType', feature_epa_type,
					'gwEpaType', feature_giswater_epa_type,
					'catalog', feature_catalog,
					'family', cal_family,
					'zones', json_build_object(
						'dma', dma_id,
						'presszone', presszone_id,
						'sector', sector_id
					)
				)
		END
	), '[]'::json) INTO v_features
	FROM temp_features;

	-- JSON with all families that are in features
	WITH existing_families AS (
		SELECT DISTINCT cal_family
		FROM temp_features
		WHERE cal_family IS NOT NULL
	),
	families AS (
		SELECT DISTINCT
			ef.cal_family AS family_id,
			COALESCE(
				if_new.descript,
				if_old.descript,
				if_base.descript,
				ef.cal_family
			) AS descript
		FROM existing_families ef
		LEFT JOIN inp_family if_base ON ef.cal_family = if_base.family_id AND if_base.age IS NULL
		LEFT JOIN inp_family if_new ON ef.cal_family = concat(if_new.family_id, '_NEW') AND if_new.age IS NOT NULL
		LEFT JOIN inp_family if_old ON ef.cal_family = concat(if_old.family_id, '_OLD') AND if_old.age IS NOT NULL
	)
	SELECT COALESCE(json_agg(
		json_build_object(
			'name', family_id,
			'description', descript,
			'active', true
		)
	), '[]'::json) INTO v_families
	FROM families;

	-- JSON with all mapzones that are in features
	FOR rec IN SELECT unnest(ARRAY['dma', 'presszone', 'sector'])
    LOOP
        -- Build dynamic SQL to get JSON for this table (dma includes pattern_id)
        IF rec = 'dma' THEN
            sql := format($f$
                SELECT json_build_object(
                    concat('%s', 's'),
                    COALESCE(json_agg(json_build_object(
                        'mapzone_id', %I,
                        'name', name,
                        'pattern_id', pattern_id,
                        'geometry', ST_AsGeoJSON(the_geom, 4326)::json
                    )), '[]'::json)
                )
                FROM %I t
                WHERE EXISTS (
                    SELECT 1 FROM temp_features r WHERE r.%I = t.%I
                )
            $f$,
            rec,
            rec || '_id',
            rec,
            rec || '_id',
            rec || '_id'
            );
        ELSE
            sql := format($f$
                SELECT json_build_object(
                    concat('%s', 's'),
                    COALESCE(json_agg(json_build_object(
                        'mapzone_id', %I,
                        'name', name,
                        'geometry', ST_AsGeoJSON(the_geom, 4326)::json
                    )), '[]'::json)
                )
                FROM %I t
                WHERE EXISTS (
                    SELECT 1 FROM temp_features r WHERE r.%I = t.%I
                )
            $f$,
            rec,
            rec || '_id',
            rec,
            rec || '_id',
            rec || '_id'
            );
        END IF;

        -- Execute SQL and store JSON for this table
        EXECUTE sql INTO zone_json;

        -- Append to cumulative result
        IF zone_json IS NOT NULL THEN
            result := result || zone_json;
        END IF;
    END LOOP;

	v_mapzones := COALESCE(result, '{}'::jsonb);

	-- JSON with patterns (flattened factor_1..factor_18 per pattern_id, ordered by idrow, id)
	WITH pattern_ids AS (
		SELECT DISTINCT d.pattern_id
		FROM rpt_inp_arc ria
		JOIN dma d ON d.dma_id = ria.dma_id
		WHERE ria.result_id = v_result_id
		UNION
		SELECT DISTINCT pattern_id
		FROM rpt_inp_pattern_value
		WHERE result_id = v_result_id
	)
	SELECT COALESCE(json_agg(json_build_object('id', pattern_id, 'values', values_arr)), '[]'::json) INTO v_patterns
	FROM (
		SELECT pattern_id,
			array_agg(factor_val ORDER BY COALESCE(idrow, 0), id, factor_idx) AS values_arr
		FROM (
			SELECT p.id, p.pattern_id, p.idrow,
				unnest(ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]) AS factor_idx,
				unnest(ARRAY[
					p.factor_1, p.factor_2, p.factor_3, p.factor_4, p.factor_5, p.factor_6,
					p.factor_7, p.factor_8, p.factor_9, p.factor_10, p.factor_11, p.factor_12,
					p.factor_13, p.factor_14, p.factor_15, p.factor_16, p.factor_17, p.factor_18
				]) AS factor_val
			FROM rpt_inp_pattern_value p
			WHERE result_id = v_result_id
			AND p.pattern_id IN (SELECT pattern_id FROM pattern_ids)
			UNION ALL
			SELECT p.id, p.pattern_id, NULL::integer AS idrow,
				unnest(ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]) AS factor_idx,
				unnest(ARRAY[
					p.factor_1, p.factor_2, p.factor_3, p.factor_4, p.factor_5, p.factor_6,
					p.factor_7, p.factor_8, p.factor_9, p.factor_10, p.factor_11, p.factor_12,
					p.factor_13, p.factor_14, p.factor_15, p.factor_16, p.factor_17, p.factor_18
				]) AS factor_val
			FROM inp_pattern_value p
			WHERE p.pattern_id IN (SELECT pattern_id FROM pattern_ids)
			AND p.pattern_id NOT IN (
				SELECT DISTINCT pattern_id
				FROM rpt_inp_pattern_value
				WHERE result_id = v_result_id
			)
		) unnested
		WHERE factor_val IS NOT NULL
		GROUP BY pattern_id
	) sub;

	-- Drop temp table
	DROP TABLE IF EXISTS temp_features;

	-- Return
	RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Analysis done successfully"}, "version":"'||v_version||'"'||
			',"body":{"form":{}'||
			',"data":{"result_id": "'||v_result_id||'", "patterns":'||COALESCE(v_patterns::text, '[]')||', "families":'||COALESCE(v_families::text, '[]')||', "mapzones":'||COALESCE(v_mapzones::text, '{}')||', "features":'||COALESCE(v_features::text, '[]')||
		'}}'||
	'}')::json, 2302, null, null, null);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;